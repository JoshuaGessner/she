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

signal died

## **The ladder, all four rungs of it** (`M4-T16`, ADR-196). `CALLING` is not
## a fifth rung — it is the *beat* `DES-013` demands before the failure state,
## made a state rather than a timer so it replicates and tints for free. A
## client has to see the wind-up too, or "one chance to prevent it" is a chance
## only the host gets.
enum State { UNAWARE, SUSPICIOUS, ALERTED, CALLING, SWARM, STAGGERED, DEAD }
enum Attack { NONE, TELEGRAPH, ACTIVE, RECOVERY }

const TINTS: Dictionary = {
	State.UNAWARE: Color(0.34, 0.34, 0.36),
	State.SUSPICIOUS: Color(0.52, 0.52, 0.54),
	State.ALERTED: Color(0.20, 0.20, 0.22),
	# The call reads as the brightest thing on the body — brighter than a
	# telegraphed swing, because it is worse news than a swing.
	State.CALLING: Color(0.98, 0.98, 0.98),
	State.SWARM: Color(0.80, 0.80, 0.82),
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

## Death, in three beats (`M2-T14`). Quick enough to read as a consequence of
## the blow that caused it, slow enough to be seen.
const FALL_SECONDS: float = 0.45     # ⟨tune⟩
const CORPSE_SECONDS: float = 12.0   # ⟨tune⟩ — how long it lies there
const SINK_SECONDS: float = 1.6      # ⟨tune⟩

## Navigation (`M2-T14`). Repathing five times a second rather than sixty is the
## standard trade and is invisible in play.
const REPATH_SECONDS: float = 0.2
## Inside this, walk straight at the target. A path node between two bodies
## already in the same room makes the approach worse, not better.
const DIRECT_RANGE: float = 2.5
## Close enough to have arrived.
const ARRIVED: float = 0.25
## A body is 0.35 across; the agent is a little wider so paths keep off walls.
const NAV_RADIUS: float = 0.45
const NAV_HEIGHT: float = 1.8

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
		var was: State = _state
		_state = next
		if is_node_ready():
			_apply_state()
			# **You were heard**, and this is the cue `DES-005` needs to exist
			# for the game to be explainable: *"the player should be able to
			# explain their death in one sentence"*, and "something noticed me
			# and I kept going" is only available to someone who was told. It
			# is deliberately not subtle — being noticed is the moment the run
			# changes, and a tasteful version of it would be a worse game.
			if next == State.ALERTED and was != State.STAGGERED:
				Foley.at(self, Foley.Sound.NOTICED)

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

## Poise remaining (`M4-T16`). **Host-only and deliberately not replicated:**
## its only output is `_state`, which already is, so putting poise on the wire
## would be sending a client a number it can do nothing with — and `TEC-004`
## costs relevance per enemy per tick.
var _poise: float = 0.0

## How long this body has held a target without losing it. Reset the moment it
## drops back to SUSPICIOUS, so a player who breaks contact genuinely resets the
## clock rather than merely pausing it — which is what makes disengaging a real
## answer rather than a delay (`DES-002`).
var _alerted_for: float = 0.0

## Counts the beat down. Host-only: the *state* is what clients read.
var _call_timer: float = 0.0

## One call per body per acquisition. Without this a SWARM enemy re-shouts every
## frame it stays alerted, and the floor never stops being called.
var _called: bool = false
var _patience: float = 0.0
var _last_seen: Vector3 = Vector3.ZERO
var _home: Vector3 = Vector3.ZERO
var _target: Node3D = null
## Held by a Snare (`M3-T11`). A component rather than a flag, because the
## Gullsjukr has to be holdable by exactly the same rule and shares no ancestor
## with this — see `Rooted`.
var rooted: Rooted = null
var _agent: NavigationAgent3D = null
var _repath_in: float = 0.0
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
## **What makes an enemy audible to other enemies.** `DES-013`'s ladder diagram
## has always had a *"(Clamor spike propagates to nearby actors)"* arrow and
## nothing behind it: every enemy carried a `ClamorSensor` and no source, so
## they heard the player and were **silent to each other**. This is the whole
## mechanism — the propagation is `M2-T02`'s hearing, already built and paid
## for, pointed at a noise an enemy makes.
@onready var clamor: ClamorSource = $Clamor


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
	rooted = Rooted.new()
	rooted.name = "Rooted"
	add_child(rooted)
	# One agent per body (`M2-T14`). Built here rather than in the scene so an
	# enemy dropped into a level with no baked region still works — it simply
	# finds no map and falls back to walking straight, which is what every
	# enemy did everywhere until now.
	_agent = NavigationAgent3D.new()
	_agent.name = "Nav"
	_agent.radius = NAV_RADIUS
	_agent.height = NAV_HEIGHT
	# Off: avoidance is a second steering system with its own tuning, and
	# `_spawn_enemies` already guarantees separation by construction (the ring
	# in `room_set.gd`). Turning it on would be two things pushing one body.
	_agent.avoidance_enabled = false
	_agent.path_desired_distance = 0.5
	_agent.target_desired_distance = ARRIVED
	add_child(_agent)
	var tuning: TuningProfile = Config.tuning
	health.maximum = tuning.enemy_health
	health.restore()
	# Full at spawn. Left at the declared 0.0 this would stagger to the first
	# touch of anything — the failure the pool exists to prevent, arriving as
	# an initialisation bug rather than as a design one.
	_poise = tuning.enemy_poise
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


## Poise remaining, 0–1. For probes and for `M4-T02`'s archetypes, which will
## want to differ by how much of this they carry.
func poise() -> float:
	return _poise / maxf(Config.tuning.enemy_poise, 0.001)


func _break_poise() -> void:
	_hitbox.disarm()
	_attack = Attack.NONE
	# **This is "one chance to prevent it"** (`DES-013`). Staggering a body
	# mid-call throws the call away — leaving CALLING is what does it, since
	# `_tick_call` runs on no other state — and `_called` stays false, so it
	# will try again. The player bought time, not immunity.
	#
	# A `_call_timer = 0.0` sat here until `--swarm-probe`'s plant walked
	# straight through it: the timer is unreadable from any state this line can
	# be reached from, so it was the mechanism in appearance only (ADR-098).
	_poise = 0.0
	_stagger_timer = Config.tuning.enemy_stagger
	_state = State.STAGGERED


## **Has this body got you?** ALERTED, CALLING and SWARM are three answers to
## one question, and every existing caller asking `state() == ALERTED` meant
## this one. Two probes compared against ALERTED directly and would have gone
## wrong in opposite directions once the ladder grew — one failing a healthy
## build, the other passing a broken one.
func is_hunting() -> bool:
	return _state in [State.ALERTED, State.CALLING, State.SWARM]


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
## Which phase of its swing, for a probe that has to hit a specific one.
## `is_telegraphing()` and `is_swinging()` answer the two a player can see;
## RECOVERY is the one only the rules can name.
func attack_phase() -> Attack:
	return _attack


## Put the swarm clock back to zero, without touching what the body knows.
##
## For probes that measure movement across a window: a body that has held the
## player for `enemy_swarm_after` stops dead to call the floor, and a window
## that lands on the call reads as a body going nowhere. `--stalker-probe`
## measures exactly that, about a snare, and its own vacuity guard caught the
## confound the day `SWARM` landed (ADR-196).
func reset_alert_clock() -> void:
	_alerted_for = 0.0
	_called = false


## Refill the pool without staggering. Used by `--fight-probe` to prove the
## recovery punish stands on its own rather than on an empty pool.
func refill_poise() -> void:
	_poise = Config.tuning.enemy_poise


## The dangerous window, as `is_telegraphing()` is the readable one. Added for
## `--fight-probe`: measuring whether an enemy *lands* a hit conflates the
## brain with the geometry, and the two failed separately.
func is_swinging() -> bool:
	return _attack == Attack.ACTIVE


func is_telegraphing() -> bool:
	return _attack == Attack.TELEGRAPH


## Dev-only, for the combat probe: apply damage without needing a real hitbox
## overlap, so interruption can be tested at an exact moment.
func take_test_hit(amount: float, from: Node = null) -> void:
	_on_hurt(amount, from)


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

	# Poise returns whenever the body is not already broken. Outside a fight
	# this is a no-op against the cap; inside one it is what stops a series of
	# light hits banking indefinitely toward a stagger that was never earned.
	if _state != State.STAGGERED:
		_poise = minf(tuning.enemy_poise, _poise + tuning.enemy_poise_regen * delta)

	# **Runs while it swings, not only between swings.** `_act` is skipped for
	# the whole of an attack cycle, and a body inside its attack range spends
	# roughly nine tenths of its time there — so a clock kept in `_act` would
	# advance about one frame per second and the call would never come during
	# the fight it is supposed to be about.
	if is_hunting():
		_alerted_for += delta

	if _state == State.STAGGERED:
		_tick_stagger(delta, tuning)
	elif _state == State.CALLING:
		_tick_call(delta, tuning)
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
	if _state not in [State.ALERTED, State.CALLING, State.SWARM, State.STAGGERED]:
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
## **A body worth fighting** (`M2-T21`, ADR-114).
##
## Down or spent is neither a threat nor damageable. `Health.apply_damage`
## returns at its first line once `_dead`, so an enemy standing over a fallen
## player deals no damage, emits no `damaged` signal and does not even play a
## Foley cue — it is animation with nothing behind it. Worse, acquisition is
## *nearest visible*, so a body on the floor was pulling enemies off a standing
## teammate to swing at something that could not be hurt.
##
## `is_incapacitated()` rather than three separate tests, because `Player`
## already owns that question (`bleeding > 0.0 or spent`) and exists so this
## kind of call site cannot drift away from it.
static func _worth_fighting(node: Node) -> bool:
	var body := node as Player
	return body != null and not body.is_incapacitated()


func _nearest_visible_player(tuning: TuningProfile) -> Node3D:
	var best: Node3D = null
	var nearest: float = INF
	for node: Node in get_tree().get_nodes_in_group("player"):
		# `Player` rather than `Node3D` since `M4-T13`: sight now reads the
		# body's own `Exposure`, so the type the loop already relies on
		# `_worth_fighting` to guarantee is stated where it is established.
		var candidate := node as Player
		if candidate == null or not _worth_fighting(candidate):
			continue
		if not _can_see(candidate, tuning):
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
	if _state in [State.ALERTED, State.CALLING, State.SWARM, State.STAGGERED]:
		return
	_heard_for += delta
	if _heard_for < tuning.enemy_hearing_patience:
		return
	_heard_for = 0.0
	_last_seen = _heard_at
	_patience = tuning.enemy_patience
	if _state != State.SUSPICIOUS:
		_state = State.SUSPICIOUS


## **Typed `Player`, not `Node3D`** (`M4-T13`). Its only caller has already run
## `_worth_fighting`, which is a cast to `Player` — so a null check here would
## be a branch that cannot run, quietly holding a copy of the pre-lantern sight
## rule for the day it did. The signature is the assertion.
func _can_see(player: Player, tuning: TuningProfile) -> bool:
	var eye: Vector3 = _eyes.global_position
	var to_player: Vector3 = player.global_position + Vector3.UP * 0.9 - eye
	# **How far you are seen from is how lit you are** (`M4-T13`, `ART-001`,
	# ADR-188). Not a constant since the lantern landed: `Exposure.seen_from()`
	# interpolates `enemy_vision_dark`→`enemy_vision_range` on the light
	# actually falling on that body, so an open shutter is a decision with a
	# price and darkness is somewhere to hide rather than a colour grade.
	#
	# Asked of the body, not of this enemy: exposure is a property of the thing
	# being looked at, computed once per body per tick, rather than a term every
	# one of 150 agents recomputes about everybody else.
	if to_player.length() > player.exposure.seen_from():
		return false
	var flat: Vector3 = Vector3(to_player.x, 0.0, to_player.z).normalized()
	if flat.dot(facing()) < cos(deg_to_rad(tuning.enemy_vision_half_angle)):
		return false
	# **Stillness** (`M3-T12`, `DES-004`). Sight alone — *ears do not*, which is
	# why the node's text says to hold your breath as well and why this sits
	# here rather than in `_listen`. `DES-013` splits the senses precisely so a
	# player can tell which one has them, and a node that blinded both would
	# collapse that back into one "aware" lamp.
	var body := player as Player
	if body != null and body.has_effect(&"unseen_while_still") \
			and body.planar_speed() < 0.05:
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
		State.ALERTED, State.SWARM:
			# **SWARM behaves as ALERTED and reads as worse.** The difference is
			# not what this body does, it is that the floor now knows — which is
			# the only thing `DES-013` claims the state means.
			_patience -= delta
			# `is_instance_valid`, not `!= null`: a player who disconnects is
			# freed out from under whichever enemy was chasing them, and a
			# stale reference here crashes the host mid-fight.
			#
			# **And a target that went down is gone too** (`M2-T21`, ADR-114).
			# Filtering acquisition alone does not stop this branch: `_target`
			# keeps its reference and goes on swinging at a fallen body for the
			# rest of `enemy_patience`.
			var live: bool = is_instance_valid(_target) and _worth_fighting(_target)
			if _patience <= 0.0 or not live:
				# Lost the player: go to where they were, not where they are —
				# which for a body on the floor is exactly where it is lying,
				# so the enemy searches the spot a rescuer has to walk into.
				_state = State.SUSPICIOUS
				_patience = tuning.enemy_patience
				_alerted_for = 0.0
				_called = false
			else:
				# **The clock that makes leaving an answer** (`M4-T16`, ADR-196).
				# Nothing on this ladder used to escalate: an enemy that had you
				# for one second and one that had you for thirty were the same
				# enemy, so "do I take this fight" had no term that got worse.
				if not _called and _alerted_for >= tuning.enemy_swarm_after:
					_begin_call(tuning)
					return
				var range_to: float = global_position.distance_to(_target.global_position)
				if range_to <= tuning.enemy_attack_range:
					_begin_attack(tuning)
				else:
					_steer_toward(_last_seen, tuning.enemy_run_speed, tuning)


## **The beat before the failure state** (`DES-013`).
##
## It stops to do this, which is the whole counter-play: a body standing still
## and shouting is a body you can reach, and `_break_poise` cancels it. So the
## hammer that breaks poise in one hit and the recovery-punish a knife earns
## (ADR-194) are both answers to this — the two halves of `M4-T16` built a week
## apart turn out to be the same decision seen twice.
func _begin_call(tuning: TuningProfile) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_hitbox.disarm()
	_attack = Attack.NONE
	_call_timer = tuning.enemy_swarm_telegraph
	_state = State.CALLING


func _tick_call(delta: float, tuning: TuningProfile) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	# **Losing you cancels it.** `PRO-005` §5 wants counters a player can name,
	# and staggering alone would give the hammer an answer the seax does not
	# have: 0.9 s is two knife swings, 30 damage against 60 hit points, so a
	# light build could neither stop the call nor kill through it. Sight is the
	# counter every build shares, and it is not cheap — `_alerted_for` keeps
	# running, so ducking behind a pillar for a beat re-calls the moment you
	# lean out. Only genuinely losing it (`_patience`, back to SUSPICIOUS)
	# clears the clock, which is what makes disengaging the real answer.
	if not _sees:
		_call_timer = 0.0
		_state = State.ALERTED
		return
	# Still facing you while it shouts — it has not lost you, it is telling
	# everyone where you are.
	if is_instance_valid(_target):
		var to_target: Vector3 = _target.global_position - global_position
		to_target.y = 0.0
		if to_target.length() > 0.01:
			_face(to_target.normalized(), tuning)
	_call_timer -= delta
	if _call_timer > 0.0:
		return
	# One shout, loud, decaying. Every `ClamorSensor` on the floor is already
	# listening for exactly this — including the player's own ears, since the
	# noise is real and not a message.
	clamor.add(tuning.enemy_swarm_clamor)
	_called = true
	_state = State.SWARM


func _settle(tuning: TuningProfile) -> void:
	if global_position.distance_to(_home) > 0.4:
		_steer_toward(_home, tuning.enemy_walk_speed, tuning)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


## Move toward a point, **around the level rather than into it** (`M2-T14`).
##
## This was a straight line: point the velocity at the target and walk. That is
## the correct technique for an open arena and the wrong one here — the room set
## is explicitly built with *"corners, doorways and a room you"* have to commit
## to enter, so a straight line spends most of its time pressed against a wall.
## A playtester's report that *"the ai needs to path better"* was not a tuning
## observation; it was the observation that there was no pathfinding at all.
##
## Standard Godot practice is a baked `NavigationRegion3D` plus a
## `NavigationAgent3D` per body, repathing a few times a second rather than
## every frame. Both are here now. **The straight line survives as the
## fallback**, and deliberately: the navigation map takes a frame or two to come
## up, an agent asked too early answers with its own position, and up close a
## path node is worse than simply walking at the thing. So — path at range,
## walk directly when near or when the map has nothing to say.
func _steer_toward(point: Vector3, speed: float, tuning: TuningProfile) -> void:
	var to_point: Vector3 = point - global_position
	to_point.y = 0.0
	# Snared (`M3-T11`). It still turns to watch you and still swings at
	# whatever is already in reach — what the Stalker bought is that nothing
	# **follows**. Rooting the steering rather than the whole brain is what
	# keeps a held enemy visibly dangerous instead of switched off.
	if rooted.held():
		velocity.x = 0.0
		velocity.z = 0.0
		if to_point.length() > 0.01:
			_face(to_point.normalized(), tuning)
		return
	if to_point.length() < ARRIVED:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var steer_to: Vector3 = point
	if _agent != null and to_point.length() > DIRECT_RANGE \
			and _agent.get_navigation_map().is_valid():
		# Throttled: recomputing a path every frame is the single most common
		# way to make navigation expensive, and nobody can see the difference
		# between 60 repaths a second and five.
		_repath_in -= get_physics_process_delta_time()
		if _repath_in <= 0.0 or not _agent.target_position.is_equal_approx(point):
			_agent.target_position = point
			_repath_in = REPATH_SECONDS
		if not _agent.is_navigation_finished():
			steer_to = _agent.get_next_path_position()

	var direction: Vector3 = steer_to - global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	direction = direction.normalized()
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
	# **A hit staggers when it is heavy, or when it is earned** (`M4-T16`,
	# ADR-194). This used to stagger on every hit, for the comment's stated
	# reason — *"the whole reward for reading a telegraph"*. Measured, it was
	# the opposite: interrupting a windup is strictly better than reading it,
	# so the reward for reading correctly was that you could have skipped it.
	# `--fight-probe` took zero damage across ten seconds of seax spam.
	#
	# Two ways through, and a light weapon only has the second:
	#
	# 1. **Break its poise.** A weapon heavy enough removes more than the pool
	#    holds — `DES-009`'s *"heavy staggers"*, now literally that.
	# 2. **Punish the recovery.** A swing that has already gone by cannot be
	#    taken back, so hitting into it always staggers. This is what makes an
	#    attack a *commitment* rather than a timer, and it is the window
	#    `DES-002` needs in order for "do I take this fight" to have an answer
	#    other than yes.
	#
	# Hits landing while already staggered do damage and nothing else — poise
	# is zero down there, so without this a second hit would re-break it and
	# rebuild the lock this whole change exists to remove.
	if _state != State.STAGGERED:
		var blow: Hitbox = from as Hitbox
		var punished: bool = _attack == Attack.RECOVERY
		if not punished:
			_poise -= blow.stagger if blow != null else 0.0
		if punished or _poise <= 0.0:
			_break_poise()
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
		# Back to full rather than to whatever regenerated while it was down:
		# a stagger is the pool's price having been paid, so charging for it
		# twice would mean the second stagger is always cheaper than the first
		# and every fight ends in a lock again by a slower route.
		_poise = tuning.enemy_poise
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


## **It falls over** (`M2-T14`, ADR-106).
##
## This used to be a tint change on a body that stayed standing, and the comment
## here said so proudly: *"No ragdoll, no death animation, no corpse fade — all
## polish, all absent."* That was a defensible ADR-064 call at `M1` and it is
## the wrong call at a playtest, for the same reason the wound vignette was:
## **"did I kill it?" is information, not polish.** A playtester reported that
## enemies needed to be *"more apparent they are dead when defeated"*, and in a
## level that is now deliberately dark, a standing capsule going from 0.28 grey
## to 0.12 grey is close to no signal at all.
##
## Still not a ragdoll — that is an animation system this project does not have
## and does not need yet. A body that **topples**, makes a sound, and sinks is
## three unambiguous cues from primitives, and it answers the question the
## player is actually asking.
func _become_a_corpse() -> void:
	_hitbox.disarm()
	# A dead thing is not being held in place by a trap; it is dead. Leaving the
	# hold running would leave a corpse whose state says something is still
	# happening to it.
	rooted.release()
	velocity = Vector3.ZERO
	# Collision is dropped so a body never becomes an invisible wall.
	#
	# Deferred because on the host this runs inside the hurtbox's own signal,
	# and Godot refuses physics-state changes from there: "Function blocked
	# during in/out signal. Use set_deferred(...)". Applying next frame is
	# correct anyway — the hit that killed it has to finish resolving first.
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	_fall_over()


## Topple, thump, and sink out of sight.
##
## Runs on **every** peer, because `_apply_state` is reached by the host
## deciding and a client receiving the replicated value — which is the same
## property that already made a corpse a corpse on every screen without a death
## message, now carrying the animation with it for free.
func _fall_over() -> void:
	var tip := create_tween()
	tip.set_parallel(true)
	# Away from whatever was in front of it. Rotation only on the body's visual
	# transform: the collision is already gone, so nothing here can wedge.
	var away: float = -1.0 if randf() < 0.5 else 1.0
	tip.tween_property(self, "rotation:z", deg_to_rad(88.0 * away),
		FALL_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tip.tween_property(self, "position:y", position.y - 0.35, FALL_SECONDS)
	Foley.at(self, Foley.Sound.THUMP, 0.55)
	# Then it goes. `DES-015` builds floors out of few, reused rooms and the
	# Hunt escalates over minutes — a floor slowly filling with permanent
	# standing corpses reads as clutter and costs draw calls for nothing. It
	# sinks rather than blinking out, so the disappearance is never the thing
	# the player notices.
	var sink := create_tween()
	sink.tween_interval(CORPSE_SECONDS)
	sink.tween_property(self, "position:y", position.y - 2.2, SINK_SECONDS)
	# **Only the host frees it.** This node is spawner-managed, so a client
	# calling `queue_free` deletes something the host still believes exists —
	# the despawn has one owner exactly as the spawn does (`TEC-004`), and the
	# spawner replicates the removal. Clients run every other beat above, so
	# the body still topples and thumps and sinks on their screen; it simply
	# leaves when told, a frame or two later, like everything else does.
	if multiplayer.is_server():
		sink.tween_callback(queue_free)


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
