class_name Enemy
extends CharacterBody3D

## The one enemy (`M1-T02`), running the awareness ladder from DES-013.
##
## The ladder is here rather than "aggro on sight" because the M1 gate question
## is *"does a tester voluntarily swing at something they could have walked
## past?"* — which is unanswerable if walking past is impossible. An always-
## hostile enemy would make combat compulsory and quietly turn Clamor from a
## decision into a tax (DES-013's opening thesis).
##
## **UNAWARE → SUSPICIOUS → ALERTED is built. SWARM is absent** (ADR-064):
## calling others is only meaningful once Clamor propagates between actors, and
## the Clamor field is M2. Senses here are sight only; DES-013 specifies
## hearing as O(1) Clamor-grid lookups, which needs the same field.
##
## SUSPICIOUS investigates the **last seen position, not the player's actual
## position**. PRO-005 §5 makes that a fairness requirement rather than a
## flourish: the player must always be able to explain how they were found, and
## be able to bait it.
##
## Unjuiced. The state tell is a value change on the blockout mesh — that is the
## visual channel DES-013 demands, not polish. Hue is not used: ART-005 reserves
## saturated colour for treasure, so states read as brightness.

signal state_changed(state: State)
signal died

enum State { UNAWARE, SUSPICIOUS, ALERTED, STAGGERED, DEAD }
enum Attack { NONE, TELEGRAPH, ACTIVE, RECOVERY }

const TINTS: Dictionary = {
	State.UNAWARE: Color(0.34, 0.34, 0.36),
	State.SUSPICIOUS: Color(0.52, 0.52, 0.54),
	State.ALERTED: Color(0.20, 0.20, 0.22),
	State.STAGGERED: Color(0.66, 0.66, 0.68),
	State.DEAD: Color(0.12, 0.12, 0.13),
}
const TELEGRAPH_TINT: Color = Color(0.95, 0.95, 0.95)

var _state: State = State.UNAWARE
var _attack: Attack = Attack.NONE
var _attack_timer: float = 0.0
var _stagger_timer: float = 0.0
var _patience: float = 0.0
var _last_seen: Vector3 = Vector3.ZERO
var _home: Vector3 = Vector3.ZERO
var _target: Node3D = null
var _material: StandardMaterial3D = null

var _heard_for: float = 0.0
var _hearing_now: bool = false
var _heard_at: Vector3 = Vector3.ZERO

@onready var health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $Hitbox
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _eyes: Node3D = $Eyes
@onready var _ears: ClamorSensor = $Ears


func _ready() -> void:
	add_to_group("enemies")
	_ears.heard.connect(_on_heard)
	_home = global_position
	var tuning: TuningProfile = Config.tuning
	health.maximum = tuning.enemy_health
	health.restore()
	_hitbox.damage = tuning.enemy_attack_damage
	_hurtbox.hit.connect(_on_hurt)
	health.died.connect(_on_died)
	_material = StandardMaterial3D.new()
	_mesh.material_override = _material
	_apply_tint()


func state() -> State:
	return _state


## True during the Anticipation phase — the window DES-009 puts a 250 ms floor
## under. Exposed so the combat probe can time it in wall-clock rather than
## trusting the resource value.
func is_telegraphing() -> bool:
	return _attack == Attack.TELEGRAPH


## Dev-only, for the combat probe: apply damage without needing a real hitbox
## overlap, so interruption can be tested at an exact moment.
func take_test_hit(amount: float) -> void:
	_on_hurt(amount, null)


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	var tuning: TuningProfile = Config.tuning

	if not is_on_floor():
		velocity.y -= tuning.gravity * delta

	_listen(delta, tuning)

	if _state == State.STAGGERED:
		_tick_stagger(delta, tuning)
	elif _attack != Attack.NONE:
		_tick_attack(delta, tuning)
	else:
		_sense(tuning)
		_act(delta, tuning)

	move_and_slide()


# ── senses ────────────────────────────────────────────────────────────────


func _sense(tuning: TuningProfile) -> void:
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	if _can_see(player, tuning):
		_target = player
		_last_seen = player.global_position
		_patience = tuning.enemy_patience
		if _state != State.ALERTED:
			_set_state(State.ALERTED)


## The sensor only records; the decision is made in `_listen` so that silence
## is a real input. Deciding inside the signal would mean `_heard_for` only ever
## rises, and a room once disturbed would stay disturbed for good.
func _on_heard(where: Vector3, _loudness: float) -> void:
	_hearing_now = true
	_heard_at = where


## Noise moves UNAWARE to SUSPICIOUS, never straight to ALERTED. DES-013 is
## explicit that SUSPICIOUS investigates *the last heard position*, and that
## this is what makes the system fair and baitable — the enemy genuinely does
## not know where you are, only where a sound was.
func _listen(delta: float, tuning: TuningProfile) -> void:
	var hearing: bool = _hearing_now
	_hearing_now = false
	if not hearing:
		_heard_for = maxf(0.0, _heard_for - delta)
		return
	if _state == State.ALERTED or _state == State.STAGGERED:
		return
	_heard_for += delta
	if _heard_for < tuning.enemy_hearing_patience:
		return
	_heard_for = 0.0
	_last_seen = _heard_at
	_patience = tuning.enemy_patience
	if _state != State.SUSPICIOUS:
		_set_state(State.SUSPICIOUS)


func _can_see(player: Node3D, tuning: TuningProfile) -> bool:
	var eye: Vector3 = _eyes.global_position
	var to_player: Vector3 = player.global_position + Vector3.UP * 0.9 - eye
	if to_player.length() > tuning.enemy_vision_range:
		return false
	var facing: Vector3 = -global_transform.basis.z
	var flat: Vector3 = Vector3(to_player.x, 0.0, to_player.z).normalized()
	if flat.dot(facing) < cos(deg_to_rad(tuning.enemy_vision_half_angle)):
		return false
	# Line of sight against world geometry only. Bodies are on their own layer
	# so one enemy cannot block another's view — with 150 agents that would
	# produce constant, inexplicable blind spots.
	var query := PhysicsRayQueryParameters3D.create(eye, eye + to_player)
	query.collision_mask = CollisionLayers.WORLD
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


# ── behaviour ─────────────────────────────────────────────────────────────


func _act(delta: float, tuning: TuningProfile) -> void:
	match _state:
		State.UNAWARE:
			_settle(tuning)
		State.SUSPICIOUS:
			_patience -= delta
			if _patience <= 0.0:
				_set_state(State.UNAWARE)
			else:
				_steer_toward(_last_seen, tuning.enemy_walk_speed, tuning)
		State.ALERTED:
			_patience -= delta
			if _patience <= 0.0:
				# Lost the player: go to where they were, not where they are.
				_set_state(State.SUSPICIOUS)
				_patience = tuning.enemy_patience
			elif _target != null:
				var range_to: float = global_position.distance_to(_target.global_position)
				if range_to <= tuning.enemy_attack_range:
					_begin_attack(tuning)
				else:
					_steer_toward(_last_seen, tuning.enemy_run_speed, tuning)


func _settle(tuning: TuningProfile) -> void:
	if global_position.distance_to(_home) > 0.4:
		_steer_toward(_home, tuning.enemy_walk_speed, tuning)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _steer_toward(point: Vector3, speed: float, tuning: TuningProfile) -> void:
	var to_point: Vector3 = point - global_position
	to_point.y = 0.0
	if to_point.length() < 0.25:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var direction: Vector3 = to_point.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	_face(direction, tuning)


func _face(direction: Vector3, tuning: TuningProfile) -> void:
	var wanted: float = atan2(direction.x, direction.z)
	rotation.y = rotate_toward(rotation.y, wanted, tuning.enemy_turn_rate)


# ── attacking ─────────────────────────────────────────────────────────────


func _begin_attack(tuning: TuningProfile) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_attack = Attack.TELEGRAPH
	# DES-009's hard floor: human visual reaction time is ~250 ms before any
	# decision or input. Anything faster produces a death the player cannot
	# explain, which PRO-005 §5 identifies as the attribution failure that
	# makes people quit rather than retry. TuningProfile enforces the floor.
	_attack_timer = tuning.enemy_telegraph
	_apply_tint()


func _tick_attack(delta: float, tuning: TuningProfile) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	match _attack:
		Attack.TELEGRAPH:
			_attack = Attack.ACTIVE
			_attack_timer = tuning.enemy_attack_active
			_hitbox.arm()
		Attack.ACTIVE:
			_attack = Attack.RECOVERY
			_attack_timer = tuning.enemy_attack_recovery
			_hitbox.disarm()
		Attack.RECOVERY:
			_attack = Attack.NONE
			_apply_tint()
		Attack.NONE:
			pass


# ── damage ────────────────────────────────────────────────────────────────


func _on_hurt(amount: float, from: Node) -> void:
	health.apply_damage(amount, from)
	if health.is_dead():
		return
	# Being hit interrupts the swing. This is the whole reward for reading a
	# telegraph correctly — without it, trading blows is always as good as
	# timing them, and DES-009's "recovery is the reward for reading" is a lie.
	_hitbox.disarm()
	_attack = Attack.NONE
	_stagger_timer = Config.tuning.enemy_stagger
	_set_state(State.STAGGERED)
	# A hit is also information: it tells the enemy where you are.
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		_target = player
		_last_seen = player.global_position


func _tick_stagger(delta: float, tuning: TuningProfile) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_stagger_timer -= delta
	if _stagger_timer <= 0.0:
		_patience = tuning.enemy_patience
		_set_state(State.ALERTED)


func _on_died(_from: Node) -> void:
	_set_state(State.DEAD)
	_hitbox.disarm()
	velocity = Vector3.ZERO
	# No ragdoll, no death animation, no corpse fade — all polish, all absent.
	# Collision is dropped so a body never becomes an invisible wall.
	#
	# Deferred because this runs inside the hurtbox's own signal, and Godot
	# refuses physics-state changes from there: "Function blocked during in/out
	# signal. Use set_deferred(...)". Applying next frame is correct anyway —
	# the hit that killed it has to finish resolving first.
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	died.emit()


func _set_state(next: State) -> void:
	if next == _state:
		return
	_state = next
	_apply_tint()
	state_changed.emit(next)


func _apply_tint() -> void:
	if _material == null:
		return
	var tint: Color = TELEGRAPH_TINT if _attack == Attack.TELEGRAPH else TINTS[_state]
	_material.albedo_color = tint
