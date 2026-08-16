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
## Sense lamps read as value, not hue: ART-005 reserves saturated colour for
## treasure, and a green/red pair here would compete with the one thing in the
## game allowed to be coloured.
const SENSE_ON: Color = Color(1.0, 1.0, 1.0)
const SENSE_OFF: Color = Color(0.14, 0.14, 0.15)

## Replication rate, matching the player's. ADR-068 measured the budget at
## 20 Hz and put the ceiling at ~29 continuously-moving entities; a room set
## with four enemies and two players is a rounding error of that.
const REPLICATION_HZ: float = 20.0

## Host→client. The transform moves continuously, so `ALWAYS` — ADR-068
## measured `ON_CHANGE` costing *more* for values like that. Everything else
## here genuinely idles: an enemy holds a state for seconds at a time, and an
## idle agent should cost nothing, which is the case `ON_CHANGE` exists for.
const REPLICATED_PROPERTIES: Dictionary = {
	".:position": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	".:rotation:y": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	".:_state": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	".:_attack": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	".:_sees": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	".:_hears": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	"Health:current": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
}

## The ladder state, and the single place its visible consequences happen.
##
## A setter rather than a `_set_state()` method because this value is
## replicated: the host reaches it by deciding, a client by receiving, and a
## GDScript setter fires either way. That is what stops the two diverging —
## there is one piece of code that turns a state into a tint and a corpse, and
## both peers run it.
var _state: State = State.UNAWARE:
	set(next):
		if next == _state:
			return
		_state = next
		if is_node_ready():
			_apply_state()
		state_changed.emit(next)

## Drives the telegraph tint, so it has to reach clients: DES-009 puts a 250 ms
## floor under the wind-up specifically so a player can *read* it, and a
## telegraph only the host can see is not a telegraph.
var _attack: Attack = Attack.NONE:
	set(next):
		if next == _attack:
			return
		_attack = next
		if is_node_ready():
			_apply_tint()

var _attack_timer: float = 0.0
var _stagger_timer: float = 0.0
var _patience: float = 0.0
var _last_seen: Vector3 = Vector3.ZERO
var _home: Vector3 = Vector3.ZERO
var _target: Node3D = null
var _material: StandardMaterial3D = null
var _sight_lamp: StandardMaterial3D = null
var _hearing_lamp: StandardMaterial3D = null

var _heard_for: float = 0.0
var _hearing_now: bool = false
var _heard_at: Vector3 = Vector3.ZERO

# Live contact per sense, kept separate from the ladder state on purpose.
# The ladder is DES-013's spine; sight and hearing are its two *inputs*, and
# collapsing them into one state makes it impossible to tell a room that saw
# you from one that only heard something — which is the difference between
# "you were spotted" and "you can still bluff this".
var _sees: bool = false
var _hears: bool = false

@onready var health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $Hitbox
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _eyes: Node3D = $Eyes
@onready var _ears: ClamorSensor = $Ears


## Build this enemy's synchroniser, before it enters the tree (`M1-T05`).
##
## Authority is left at peer 1 — Godot's default for a spawned node, and the
## host in every session including the offline peer a solo launch runs on. So
## there is nothing to set, which is the point: an enemy that a client could
## claim authority over would need a reason, and `TEC-004` gives none.
func configure_replication() -> void:
	var config := SceneReplicationConfig.new()
	for path: String in REPLICATED_PROPERTIES:
		var property := NodePath(path)
		config.add_property(property)
		# Spawn state as well as stream, so a client that joins after a fight
		# sees the corpses as corpses rather than watching them die again.
		config.property_set_spawn(property, true)
		config.property_set_replication_mode(property, int(REPLICATED_PROPERTIES[path]))

	var sync := MultiplayerSynchronizer.new()
	sync.name = "StateSync"
	sync.replication_config = config
	# Both intervals (ADR-068): `ON_CHANGE` properties travel the delta
	# channel, whose `delta_interval` defaults to every network frame, and
	# leaving it there costs about 4x the bandwidth for nothing.
	sync.replication_interval = 1.0 / REPLICATION_HZ
	sync.delta_interval = 1.0 / REPLICATION_HZ
	add_child(sync)


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
	_sight_lamp = _build_lamp(Vector3(-0.16, 2.1, 0))
	_hearing_lamp = _build_lamp(Vector3(0.16, 2.1, 0))
	# Applied from whatever `_state` already holds rather than assuming
	# UNAWARE. Spawn state can land either side of `_ready` depending on how
	# the spawn packet is applied, and an enemy that arrived dead must not
	# stand back up because this ran in the wrong order.
	_apply_state()
	_update_sense_markers()


func _build_lamp(offset: Vector3) -> StandardMaterial3D:
	var box := BoxMesh.new()
	box.size = Vector3(0.22, 0.22, 0.22)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var lamp := MeshInstance3D.new()
	lamp.mesh = box
	lamp.material_override = material
	lamp.position = offset
	add_child(lamp)
	return material


func state() -> State:
	return _state


## Where sight is cast from. Used by the gym's vision overlay so the drawn
## wedge starts where the rays actually start.
func eye_position() -> Vector3:
	return _eyes.global_position


## The direction this enemy is facing, on the horizontal plane.
func facing() -> Vector3:
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	return forward.normalized()


## Live visual contact this frame — not "has ever seen you".
func sees_player() -> bool:
	return _sees


## Live audible contact this frame.
func hears_player() -> bool:
	return _hears


## True during the Anticipation phase — the window DES-009 puts a 250 ms floor
## under. Exposed so the combat probe can time it in wall-clock rather than
## trusting the resource value.
func is_telegraphing() -> bool:
	return _attack == Attack.TELEGRAPH


## Dev-only, for the combat probe: apply damage without needing a real hitbox
## overlap, so interruption can be tested at an exact moment.
func take_test_hit(amount: float) -> void:
	_on_hurt(amount, null)


## The sense lamps, every frame, on every peer.
##
## Moved out of `_physics_process` by `M1-T05`: that function now belongs to
## the host, and DES-013 requires every transition to be legible — a lamp that
## only lit on the host's screen would make the awareness ladder unreadable for
## exactly the player who is not hosting.
func _process(_delta: float) -> void:
	_update_sense_markers()


func _physics_process(delta: float) -> void:
	# **Enemies are host-authoritative** (`TEC-004`, ADR-082). A client running
	# this too would steer a body whose transform is overwritten twenty times a
	# second, and the two copies would disagree about where the fight is.
	# Solo is peer 1 on the offline peer, so nothing here is special-cased.
	if not multiplayer.is_server():
		return
	if _state == State.DEAD:
		return
	var tuning: TuningProfile = Config.tuning

	if not is_on_floor():
		velocity.y -= tuning.gravity * delta

	# Both senses run unconditionally so the debug readout always reports live
	# contact; what the state machine does with them is gated below.
	_listen(delta, tuning)
	_look(tuning)

	if _state == State.STAGGERED:
		_tick_stagger(delta, tuning)
	elif _attack != Attack.NONE:
		_tick_attack(delta, tuning)
	else:
		_act(delta, tuning)

	move_and_slide()


# ── senses ────────────────────────────────────────────────────────────────


## Sight runs every frame, including while attacking or staggered, so `_sees`
## always reports live contact. Only the *promotion* to ALERTED is gated.
func _look(tuning: TuningProfile) -> void:
	var player: Node3D = _nearest_visible_player(tuning)
	_sees = player != null
	if not _sees:
		return
	_target = player
	_last_seen = player.global_position
	_patience = tuning.enemy_patience
	if _state != State.ALERTED and _state != State.STAGGERED:
		_state = State.ALERTED


## The closest player this enemy can actually see.
##
## `M1-T05` replaced `get_first_node_in_group("player")` here, and the old line
## was worse than it looked: with a party, *every* enemy in the level perceived
## exactly one player and the rest walked around as ghosts — invisible,
## unattackable, and unable to fail a stealth approach. It was invisible as a
## bug for as long as there was only ever one body in the group.
##
## Nearest *visible*, not nearest: hiding has to keep working when a teammate
## is standing in the open two metres away.
func _nearest_visible_player(tuning: TuningProfile) -> Node3D:
	var best: Node3D = null
	var nearest: float = INF
	for node: Node in get_tree().get_nodes_in_group("player"):
		var candidate := node as Node3D
		if candidate == null or not _can_see(candidate, tuning):
			continue
		var distance: float = global_position.distance_to(candidate.global_position)
		if distance < nearest:
			nearest = distance
			best = candidate
	return best


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
	_hears = hearing
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
		_state = State.SUSPICIOUS


func _can_see(player: Node3D, tuning: TuningProfile) -> bool:
	var eye: Vector3 = _eyes.global_position
	var to_player: Vector3 = player.global_position + Vector3.UP * 0.9 - eye
	if to_player.length() > tuning.enemy_vision_range:
		return false
	var flat: Vector3 = Vector3(to_player.x, 0.0, to_player.z).normalized()
	if flat.dot(facing()) < cos(deg_to_rad(tuning.enemy_vision_half_angle)):
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
				_state = State.UNAWARE
			else:
				_steer_toward(_last_seen, tuning.enemy_walk_speed, tuning)
		State.ALERTED:
			_patience -= delta
			if _patience <= 0.0:
				# Lost the player: go to where they were, not where they are.
				_state = State.SUSPICIOUS
				_patience = tuning.enemy_patience
			# `is_instance_valid`, not `!= null`: a player who disconnects is
			# freed out from under whichever enemy was chasing them, and a
			# stale reference here crashes the host mid-fight.
			elif is_instance_valid(_target):
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
	# Godot's forward is **-Z**, so a Y rotation of θ points the node at
	# (-sin θ, 0, -cos θ). Solving for θ therefore negates both components:
	# atan2(direction.x, direction.z) yields the angle whose *+Z* axis is the
	# direction, which aims the body exactly backwards. The enemy then walked
	# at the player while looking away from them, and — because `_can_see`
	# uses the same forward vector — went blind the instant it started closing.
	var wanted: float = atan2(-direction.x, -direction.z)
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
	_state = State.STAGGERED
	# A hit is also information: it tells the enemy where *the attacker* is.
	# `M1-T05`: this used to look up the first player in the group, which with
	# a party sent a struck enemy after whoever happened to be first rather
	# than after whoever hit it — and PRO-005 §5 requires the player to be able
	# to explain how they were found.
	var attacker: Node3D = (from as Hitbox).actor() if from is Hitbox else null
	if attacker != null:
		_target = attacker
		_last_seen = attacker.global_position


func _tick_stagger(delta: float, tuning: TuningProfile) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_stagger_timer -= delta
	if _stagger_timer <= 0.0:
		_patience = tuning.enemy_patience
		_state = State.ALERTED


func _on_died(_from: Node) -> void:
	# Reached only on the host — `Health.died` follows damage, and damage is
	# resolved nowhere else (`Hitbox`). Assigning the state is enough: the
	# setter turns it into a corpse here *and* on every client when the value
	# arrives, which is why there is no death RPC.
	_state = State.DEAD
	died.emit()


## Everything a state means, in one place, run by whoever set it.
##
## The host reaches this by deciding and a client by receiving a replicated
## value, and both go through the same code — which is the property that keeps
## a corpse a corpse on every screen without a second death message.
func _apply_state() -> void:
	_apply_tint()
	if _state == State.DEAD:
		_become_a_corpse()


func _become_a_corpse() -> void:
	_hitbox.disarm()
	velocity = Vector3.ZERO
	# No ragdoll, no death animation, no corpse fade — all polish, all absent.
	# Collision is dropped so a body never becomes an invisible wall.
	#
	# Deferred because on the host this runs inside the hurtbox's own signal,
	# and Godot refuses physics-state changes from there: "Function blocked
	# during in/out signal. Use set_deferred(...)". Applying next frame is
	# correct anyway — the hit that killed it has to finish resolving first.
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)


func _apply_tint() -> void:
	if _material == null:
		return
	var tint: Color = TELEGRAPH_TINT if _attack == Attack.TELEGRAPH else TINTS[_state]
	_material.albedo_color = tint


## Two lamps over the head: left is sight, right is hearing. Separate marks
## rather than one "aware" light, because the whole point of splitting the
## senses is being able to see *which* one has you — sight means you are
## spotted, hearing alone means the enemy is guessing at a position.
func _update_sense_markers() -> void:
	if _sight_lamp == null:
		return
	_sight_lamp.albedo_color = SENSE_ON if _sees else SENSE_OFF
	_hearing_lamp.albedo_color = SENSE_ON if _hears else SENSE_OFF
