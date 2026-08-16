class_name Player
extends CharacterBody3D

## `M1-T01` — the first-person controller. Walk, sprint, crouch, stamina, and
## weight felt in the hands (DES-009 Movement, DES-005 Layer 1).
##
## **Unjuiced on purpose.** Swink's ordering is a production rule here, not a
## theory: real-time control, then a predictable simulated space, then polish
## that *amplifies* what already works. There is no head bob, no landing
## shake, no camera kick and no footstep audio in this file, and there must not
## be until the controller is judged decent without them — juice cannot rescue
## bad control, it can only hide it long enough to build a game on top.
##
## Deliberately absent, not stubbed (ADR-064): mantling and ledge-hanging
## (unscheduled), fall damage (unscheduled), footstep Clamor (`M1-T04`).
##
## `M1-T02` added the weapon, health and a hurtbox. Still absent, and still on
## purpose: the heavy attack, block, shove and throw (DES-009's remaining
## verbs), and every juice layer in its M1 protocol.

const DEBUG_WEIGHT_STEP: float = 4.0

var _yaw: float = 0.0
var _pitch: float = 0.0
var _crouching: bool = false
var _crouch_latched: bool = false
var _crouch_blend: float = 0.0

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _collider: CollisionShape3D = $CollisionShape3D
@onready var _capsule: CapsuleShape3D = _collider.shape as CapsuleShape3D
@onready var stamina: Stamina = $Stamina
@onready var carried: CarriedWeight = $CarriedWeight
@onready var health: Health = $Health
@onready var weapon: MeleeWeapon = $Head/Weapon
@onready var clamor: ClamorSource = $ClamorSource
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _ink: InkPass = $Head/Camera3D/InkPass

var _step_accumulator: float = 0.0
var _was_on_floor: bool = true


func _ready() -> void:
	add_to_group("player")
	var tuning: TuningProfile = Config.tuning
	_capsule.radius = tuning.body_radius
	_camera.fov = tuning.field_of_view
	_apply_height(tuning.stand_height)
	health.maximum = tuning.player_health
	health.restore()
	_hurtbox.hit.connect(_on_hurt)
	weapon.swing_started.connect(_on_swing_started)
	weapon.connected.connect(_on_swing_connected)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_swing_started() -> void:
	clamor.add(Config.tuning.clamor_swing)


func _on_swing_connected(_hurtbox_hit: Hurtbox) -> void:
	# DES-009: blunt weapons are loudest, and connecting is the loud part. This
	# is the main combat-to-pressure coupling — a whiff is cheap, a fight is not.
	clamor.add(Config.tuning.clamor_hit)


func _on_hurt(amount: float, from: Node) -> void:
	health.apply_damage(amount, from)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var tuning: TuningProfile = Config.tuning
		var limit: float = deg_to_rad(tuning.pitch_limit_degrees)
		_yaw -= motion.relative.x * tuning.mouse_sensitivity
		_pitch = clampf(_pitch - motion.relative.y * tuning.mouse_sensitivity, -limit, limit)
		rotation.y = _yaw
		_head.rotation.x = _pitch
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Weight has no gameplay source until inventory lands at `M2-T01`.
	elif event.is_action_pressed("debug_weight_up"):
		carried.kilograms += DEBUG_WEIGHT_STEP
	elif event.is_action_pressed("debug_weight_down"):
		carried.kilograms -= DEBUG_WEIGHT_STEP
	elif event.is_action_pressed("debug_ink"):
		show_ink(not _ink.visible)


## The ink pass is a clip-space quad, so it fills whatever camera draws it —
## including cameras that are not this player's. A debug or spectator camera
## must be able to switch it off, or it composites over their view as well.
func show_ink(on: bool) -> void:
	_ink.visible = on


## Stick and arrow-key look (ADR-075).
##
## Rate-based, not delta-based: a mouse reports how far it moved, a stick
## reports how far it is *held*, and treating the second like the first gives
## the sluggish, floaty aim that makes people call controller support "added
## but unusable". Full deflection turns at a fixed rate in radians per second.
##
## The response curve matters as much as the rate. A linear stick is precise
## nowhere — too twitchy for fine aim, too slow for turning round — so small
## deflections are compressed and large ones are not.
func _apply_stick_look(delta: float, tuning: TuningProfile) -> void:
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look.length_squared() <= 0.0:
		return
	var magnitude: float = minf(look.length(), 1.0)
	var shaped: Vector2 = look.normalized() * pow(magnitude, tuning.stick_look_curve)
	var limit: float = deg_to_rad(tuning.pitch_limit_degrees)
	_yaw -= shaped.x * tuning.stick_look_rate * delta
	_pitch = clampf(_pitch - shaped.y * tuning.stick_look_rate * delta, -limit, limit)
	rotation.y = _yaw
	_head.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	var tuning: TuningProfile = Config.tuning

	# Attacking does not root the player. DES-009 makes defence positional —
	# spacing, cover, doorways, retreat — with no dodge-roll and no i-frames,
	# so being unable to move during a swing would delete the only defence the
	# design gives. The swing itself commits; your feet do not.
	if Input.is_action_just_pressed("attack"):
		weapon.request_swing(stamina)
	weapon.advance(delta, stamina)

	if not is_on_floor():
		velocity.y -= tuning.gravity * delta

	_apply_stick_look(delta, tuning)
	_update_stance(delta, tuning)

	var wish: Vector3 = _wish_direction()
	var sprinting: bool = _resolve_sprint(wish, delta, tuning)
	var speed: float = _target_speed(sprinting, tuning)
	var accel: float = _acceleration(tuning)

	# Horizontal movement only; gravity owns Y. Accelerating toward a target
	# velocity rather than assigning it is what gives the controller mass, and
	# it is the single knob DES-009's "grounded and physical" lives in.
	var target: Vector3 = wish * speed
	var planar: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = accel if wish != Vector3.ZERO else tuning.ground_friction
	if not is_on_floor():
		rate = tuning.air_acceleration
	planar = planar.move_toward(target, rate * delta)
	velocity.x = planar.x
	velocity.z = planar.z

	_emit_movement_clamor(planar.length() * delta, sprinting, tuning)

	if Input.is_action_just_pressed("jump") and is_on_floor() and not _crouching:
		velocity.y = tuning.jump_velocity * carried.scale_by_load(tuning.jump_at_capacity)

	move_and_slide()


## Footfalls and landings, the continuous half of DES-005 Layer 1.
##
## Measured in distance walked rather than elapsed time, so sprinting is louder
## for two compounding reasons — more ground per second *and* a multiplier —
## while crouch-walking is quiet in both. Weight raises it further, which is the
## coupling the whole layer exists for: your greed is audible.
func _emit_movement_clamor(distance: float, sprinting: bool, tuning: TuningProfile) -> void:
	var landed: bool = is_on_floor() and not _was_on_floor
	_was_on_floor = is_on_floor()
	if landed:
		clamor.add(tuning.clamor_landing * carried.scale_by_load(
			tuning.clamor_footstep_at_capacity
		))
		return
	if not is_on_floor():
		return

	_step_accumulator += distance
	if _step_accumulator < tuning.clamor_step_distance:
		return
	_step_accumulator = 0.0
	var amount: float = tuning.clamor_footstep
	if _crouching:
		amount *= tuning.clamor_crouch_multiplier
	elif sprinting:
		amount *= tuning.clamor_sprint_multiplier
	clamor.add(amount * carried.scale_by_load(tuning.clamor_footstep_at_capacity))


func _wish_direction() -> Vector3:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input.x, 0.0, input.y))
	direction.y = 0.0
	return direction.normalized() if direction.length_squared() > 0.0 else Vector3.ZERO


func _resolve_sprint(wish: Vector3, delta: float, tuning: TuningProfile) -> bool:
	if _crouching or wish == Vector3.ZERO or not Input.is_action_pressed("sprint"):
		return false
	# The minimum stops a one-step sprint stutter at the bottom of the bar.
	if stamina.is_empty() or (stamina.current < tuning.sprint_minimum
			and not Input.is_action_just_pressed("sprint")):
		return false
	var drain: float = tuning.sprint_drain * carried.scale_by_load(
		tuning.stamina_drain_at_capacity
	)
	return stamina.drain(drain, delta)


func _target_speed(sprinting: bool, tuning: TuningProfile) -> float:
	var base: float = tuning.walk_speed
	if _crouching:
		base = tuning.crouch_speed
	elif sprinting:
		base = tuning.sprint_speed
	return base * carried.scale_by_load(tuning.speed_at_capacity)


func _acceleration(tuning: TuningProfile) -> float:
	return tuning.ground_acceleration * carried.scale_by_load(
		tuning.acceleration_at_capacity
	)


func _update_stance(delta: float, tuning: TuningProfile) -> void:
	# Hold and toggle, both live, because they suit different hands and neither
	# is correct for everyone: hold reads better for a quick peek, toggle for
	# the long quiet approach DES-005 Layer 1 actually rewards — and holding a
	# key for a two-minute crouched crossing is a genuine accessibility cost
	# (DES-018). The toggle is the latch; hold ORs on top of it, so releasing
	# ctrl never cancels a crouch you toggled on.
	if Input.is_action_just_pressed("crouch_toggle"):
		_crouch_latched = not _crouch_latched
	var wants_crouch: bool = _crouch_latched or Input.is_action_pressed("crouch")
	if _crouching and not wants_crouch and _blocked_above(tuning):
		wants_crouch = true  # something overhead; stay down
	_crouching = wants_crouch

	var goal: float = 1.0 if _crouching else 0.0
	var step: float = delta / maxf(tuning.crouch_time, 0.001)
	_crouch_blend = move_toward(_crouch_blend, goal, step)
	_apply_height(lerpf(tuning.stand_height, tuning.crouch_height, _crouch_blend))


func _apply_height(height: float) -> void:
	_capsule.height = height
	# Godot centres a capsule on its origin, so the collider rides at half
	# height to keep the feet at y = 0.
	_collider.position.y = height * 0.5
	_head.position.y = height - Config.tuning.eye_drop


func _blocked_above(tuning: TuningProfile) -> bool:
	var rise: float = tuning.stand_height - tuning.crouch_height
	return test_move(global_transform, Vector3.UP * rise)


## Metres per second on the horizontal plane — for the debug readout.
func planar_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()
