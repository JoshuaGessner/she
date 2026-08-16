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
##
## ## `M1-T05`: which peer decides what (ADR-082, `TEC-004`)
##
## **The owning peer is authoritative over this body's transform. The host is
## authoritative over every consequence.** `TEC-004` asks for client-side
## prediction of local movement while banning rollback and lag compensation —
## and prediction with no reconciliation is not prediction, it is authority. So
## the split is stated rather than implied, and it is visible in the node tree:
##
## | Synchroniser | Authority | Carries |
## |---|---|---|
## | `MotionSync` | the peer playing this body | position, yaw, pitch, stance, grounded |
## | `StateSync` | the host | health, carried weight, clamor |
##
## Everything with a consequence — damage, loot, noise — travels host→peer.
## Nothing a client says about those is believed, because it is never asked.
##
## A remote copy runs no input and no `move_and_slide`: its transform arrives.
## What it *does* run is the weapon phase machine, so a swing is visible on
## every screen and — on the host — arms a hitbox that can actually hurt
## something.

const DEBUG_WEIGHT_STEP: float = 4.0

## Godot's host is always peer 1, including the offline peer a solo launch
## gets, which is why none of this needs a single-player branch.
const HOST_PEER: int = 1

## Replication rate for a player body. `TEC-004`'s budget was measured at 20 Hz
## (ADR-068) and the ceiling is ~29 continuously-moving entities, so a party of
## four costs a rounding error of it.
const REPLICATION_HZ: float = 20.0

## What the owning peer sends, and how.
##
## `ALWAYS` for the three values that move continuously. ADR-068 measured
## `ON_CHANGE` costing **more** than `ALWAYS` for those (711 vs 528 kbps),
## because delta encoding adds overhead and never gets to elide anything — a
## body that is walking changes its position every single frame.
const MOTION_PROPERTIES: Dictionary = {
	".:position": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	".:rotation:y": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	"Head:rotation:x": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	# These two genuinely idle — you are standing or crouched, on the floor or
	# not — which is the case `ON_CHANGE` is actually for.
	".:stance": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	".:grounded": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
}

## What the host sends. All three are consequences, and all three idle: health
## only moves when something hits you, weight only when you pick something up,
## clamor only while you are making noise.
const STATE_PROPERTIES: Dictionary = {
	"Health:current": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	"CarriedWeight:kilograms": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	"ClamorSource:level": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
}

## 0 standing, 1 fully crouched. Replicated, because a crouched teammate must
## be crouched on every screen *and* present a shorter capsule to the host's
## hit detection — a body whose collider disagrees with its silhouette is the
## unexplainable death `PRO-005` §5 forbids.
var stance: float = 0.0:
	set(value):
		stance = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply_stance()

## Replicated so the host can tell a landing from a step for *any* body, not
## just the one it is playing. Deriving it from position would mean inferring
## contact from a curve that arrives at 20 Hz.
var grounded: bool = true

var _yaw: float = 0.0
var _pitch: float = 0.0
var _crouching: bool = false
var _crouch_latched: bool = false
var _is_local: bool = false

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _collider: CollisionShape3D = $CollisionShape3D
@onready var _capsule: CapsuleShape3D = _collider.shape as CapsuleShape3D
@onready var _body: MeshInstance3D = $Body
@onready var _body_mesh: CapsuleMesh = _body.mesh as CapsuleMesh
@onready var stamina: Stamina = $Stamina
@onready var carried: CarriedWeight = $CarriedWeight
@onready var health: Health = $Health
@onready var weapon: MeleeWeapon = $Head/Weapon
@onready var clamor: ClamorSource = $ClamorSource
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _ink: InkPass = $Head/Camera3D/InkPass

var _step_accumulator: float = 0.0
var _was_grounded: bool = true
var _last_position: Vector3 = Vector3.ZERO


## Build this body's two synchronisers and hand it to a peer.
##
## Called by `CoopSession` **before** the node enters the tree, so `_ready`
## already knows whose body it is. Deciding afterwards costs one frame of a
## teammate's body holding the camera and capturing the mouse, which is exactly
## as bad as it sounds.
##
## The order matters: `set_multiplayer_authority` is recursive by default, so
## it has to run before the host-owned synchroniser exists, or it would hand
## the host's half of the split to the client as well.
func configure_replication(owning_peer: int) -> void:
	set_multiplayer_authority(owning_peer)
	add_child(_build_sync("MotionSync", owning_peer, MOTION_PROPERTIES))
	add_child(_build_sync("StateSync", HOST_PEER, STATE_PROPERTIES))


func _build_sync(sync_name: String, authority: int,
		properties: Dictionary) -> MultiplayerSynchronizer:
	var config := SceneReplicationConfig.new()
	for path: String in properties:
		var property := NodePath(path)
		config.add_property(property)
		# In the spawn packet as well as the stream, so a player who joins
		# mid-session sees everyone where they are and as hurt as they are,
		# rather than at the origin at full health until the next update.
		config.property_set_spawn(property, true)
		config.property_set_replication_mode(property, int(properties[path]))

	var sync := MultiplayerSynchronizer.new()
	sync.name = sync_name
	sync.replication_config = config
	# **Both** intervals, never one (ADR-068). `ON_CHANGE` properties travel
	# the delta channel, which has its own `delta_interval` defaulting to every
	# network frame — setting only `replication_interval` leaves deltas running
	# at the physics rate and silently costs about 4x the bandwidth.
	sync.replication_interval = 1.0 / REPLICATION_HZ
	sync.delta_interval = 1.0 / REPLICATION_HZ
	sync.set_multiplayer_authority(authority)
	return sync


func _ready() -> void:
	add_to_group("player")
	_is_local = is_multiplayer_authority()
	if _is_local:
		# One group for "every player" and one for "the body this process is
		# playing". The debug views want the second; the enemies want the
		# first, and getting those the wrong way round makes a teammate
		# invisible to every enemy in the level.
		add_to_group("local_player")

	var tuning: TuningProfile = Config.tuning
	_capsule.radius = tuning.body_radius
	_body_mesh.radius = tuning.body_radius
	_camera.fov = tuning.field_of_view
	_apply_stance()
	health.maximum = tuning.player_health
	health.restore()
	_last_position = global_position

	# Damage arrives here only on the host: `Hitbox` refuses to resolve an
	# overlap anywhere else, so this connection is host-authoritative by
	# construction rather than by a second guard that could drift out of step.
	_hurtbox.hit.connect(_on_hurt)
	weapon.swing_started.connect(_on_swing_started)
	weapon.connected.connect(_on_swing_connected)

	# First person: you are inside your own body, so you never draw it, and
	# the ink pass is a clip-space quad that would composite over everyone
	# else's view if a teammate's copy kept one.
	_body.visible = not _is_local
	_ink.visible = _is_local
	set_process_unhandled_input(_is_local)
	if _is_local:
		_camera.make_current()
		if InputDevices.pointer_allowed():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		_camera.current = false


func _on_swing_started() -> void:
	# Tell the other peers to play the swing this client has already committed
	# to and paid for. `call_remote`: the swing is already running here.
	if _is_local:
		_replay_swing.rpc()
	# DES-009: the wind-up is audible. Host-only, because noise is a
	# consequence and consequences have one owner.
	if multiplayer.is_server():
		clamor.add(Config.tuning.clamor_swing)


## Play a swing another peer's client began.
##
## Stamina was spent on their machine. Charging it again here would let the
## host refuse a swing that legitimately happened — and the host's copy is the
## one whose hitbox decides whether anything was hurt.
@rpc("any_peer", "call_remote", "reliable")
func _replay_swing() -> void:
	# Only the peer playing this body may swing it. Not anti-cheat — `TEC-004`
	# is explicit that co-op cheating mostly harms the cheater — but a mis-
	# addressed RPC animating the wrong body is a bug that would take a day to
	# find and one line to reject.
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	weapon.begin_owned_swing()


func _on_swing_connected(_hurtbox_hit: Hurtbox) -> void:
	# DES-009: blunt weapons are loudest, and connecting is the loud part. This
	# is the main combat-to-pressure coupling — a whiff is cheap, a fight is not.
	# Reached only on the host, for the same reason `_on_hurt` is.
	clamor.add(Config.tuning.clamor_hit)


func _on_hurt(amount: float, from: Node) -> void:
	health.apply_damage(amount, from)


func _unhandled_input(event: InputEvent) -> void:
	# Only the owning peer processes input at all; `set_process_unhandled_input`
	# is switched off on every other copy in `_ready`.
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
		if InputDevices.pointer_allowed():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Weight has no gameplay source until inventory lands at `M2-T01`.
	elif event.is_action_pressed("debug_weight_up"):
		_ask_for_weight(DEBUG_WEIGHT_STEP)
	elif event.is_action_pressed("debug_weight_down"):
		_ask_for_weight(-DEBUG_WEIGHT_STEP)
	elif event.is_action_pressed("debug_ink"):
		show_ink(not _ink.visible)


## Carried weight is host-owned, so even the dev keys ask rather than set.
##
## Not ceremony: `CarriedWeight.kilograms` is replicated host→peer, so a client
## writing it locally would be silently overwritten a twentieth of a second
## later, and the bug would read as "the weight keys sometimes don't work".
func _ask_for_weight(kilograms: float) -> void:
	if multiplayer.is_server():
		carried.kilograms += kilograms
	else:
		_apply_weight.rpc_id(HOST_PEER, kilograms)


@rpc("any_peer", "reliable")
func _apply_weight(kilograms: float) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	carried.kilograms += kilograms


## Put this body somewhere, whoever is playing it.
##
## The transform belongs to the owning peer, so the host cannot simply assign
## it — the next synchroniser packet would drag the body back. It has to ask
## the owner, which is the shape every future teleport has: extraction, gate
## arrival (ADR-016), and the gym's reset key.
func teleport(to: Vector3, yaw: float) -> void:
	if _is_local:
		_apply_teleport(to, yaw)
	else:
		_apply_teleport.rpc_id(get_multiplayer_authority(), to, yaw)


@rpc("any_peer", "reliable")
func _apply_teleport(to: Vector3, yaw: float) -> void:
	# Only from the host, or from this process itself (sender 0).
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != HOST_PEER:
		return
	global_position = to
	velocity = Vector3.ZERO
	_yaw = yaw
	rotation.y = yaw
	_last_position = to
	_step_accumulator = 0.0


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

	# The weapon runs on every peer. On the owner it is the swing they asked
	# for; on the host it is the swing whose hitbox decides damage; elsewhere
	# it is the reason a teammate is visibly swinging rather than gliding.
	if _is_local and Input.is_action_just_pressed("attack"):
		weapon.request_swing(stamina)
	weapon.advance(delta, stamina)

	if _is_local:
		_drive(delta, tuning)

	# Noise is a consequence, so the host derives it for *every* body from the
	# motion it can see — its own directly, a client's from the transform that
	# just arrived. One authority, so the ring you draw and the ears that hear
	# you cannot disagree.
	if multiplayer.is_server():
		_emit_movement_clamor(delta, tuning)


## Everything the owning peer simulates for itself. `TEC-004`: prediction for
## local movement, and nothing else predicted anywhere.
func _drive(delta: float, tuning: TuningProfile) -> void:
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

	# Attacking does not root the player. DES-009 makes defence positional —
	# spacing, cover, doorways, retreat — with no dodge-roll and no i-frames,
	# so being unable to move during a swing would delete the only defence the
	# design gives. The swing itself commits; your feet do not.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not _crouching:
		velocity.y = tuning.jump_velocity * carried.scale_by_load(tuning.jump_at_capacity)

	move_and_slide()
	grounded = is_on_floor()


## Footfalls and landings, the continuous half of DES-005 Layer 1.
##
## Measured in distance walked rather than elapsed time, so sprinting is louder
## for two compounding reasons — more ground per second *and* a multiplier —
## while crouch-walking is quiet in both. Weight raises it further, which is the
## coupling the whole layer exists for: your greed is audible.
##
## `M1-T05` moved this to the host and to *displacement*, from the owner and
## from `velocity`. A remote body has no velocity here — nobody integrated one
## — but it has a position that moved, and how far you actually travelled is a
## better definition of a footstep than what you intended anyway.
func _emit_movement_clamor(delta: float, tuning: TuningProfile) -> void:
	var here: Vector3 = global_position
	var moved: Vector3 = here - _last_position
	_last_position = here
	moved.y = 0.0
	var distance: float = moved.length()

	var landed: bool = grounded and not _was_grounded
	_was_grounded = grounded
	if landed:
		clamor.add(tuning.clamor_landing * carried.scale_by_load(
			tuning.clamor_footstep_at_capacity
		))
		return
	if not grounded:
		return

	_step_accumulator += distance
	if _step_accumulator < tuning.clamor_step_distance:
		return
	_step_accumulator = 0.0
	var amount: float = tuning.clamor_footstep
	if stance > 0.5:
		amount *= tuning.clamor_crouch_multiplier
	elif _is_sprinting(distance / maxf(delta, 0.0001), tuning):
		amount *= tuning.clamor_sprint_multiplier
	clamor.add(amount * carried.scale_by_load(tuning.clamor_footstep_at_capacity))


## Sprinting, as the host can see it: fast enough that walking does not explain
## it. The threshold sits midway between the two target speeds and carries the
## same load scaling they do, so a heavily laden sprint still reads as one.
func _is_sprinting(speed: float, tuning: TuningProfile) -> bool:
	var scale: float = carried.scale_by_load(tuning.speed_at_capacity)
	return speed > (tuning.walk_speed + tuning.sprint_speed) * 0.5 * scale


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
	stance = move_toward(stance, goal, step)


## Collider, silhouette and eye height, from one number.
##
## Runs on every peer, driven by the replicated `stance`, so a crouched
## teammate is short everywhere — including in the host's hit detection, which
## is the copy that decides whether a swing over their head connected.
func _apply_stance() -> void:
	var tuning: TuningProfile = Config.tuning
	var height: float = lerpf(tuning.stand_height, tuning.crouch_height, stance)
	_capsule.height = height
	_body_mesh.height = height
	# Godot centres a capsule on its origin, so the collider rides at half
	# height to keep the feet at y = 0.
	_collider.position.y = height * 0.5
	_body.position.y = height * 0.5
	_head.position.y = height - tuning.eye_drop


func _blocked_above(tuning: TuningProfile) -> bool:
	var rise: float = tuning.stand_height - tuning.crouch_height
	return test_move(global_transform, Vector3.UP * rise)


## Metres per second on the horizontal plane — for the debug readout, which
## only ever reads the body this process is playing.
func planar_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()


## The collider's current height. Read by the co-op probe, which asserts that
## two players in one process have *different* ones while one of them is
## crouched — the scene's capsule is a sub-resource, and a shared sub-resource
## would give both bodies the same number and nobody a reason to look.
func capsule_height() -> float:
	return _capsule.height
