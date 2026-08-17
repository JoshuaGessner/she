class_name Gullsjukr
extends CharacterBody3D

## The Gold-Sick (`M2-T02`, `DES-017`).
##
## **A Bound who never left.** Someone who took the pact, went down, and stayed
## too long; their Tithe outran them. Still carrying their hoard, still trying
## to make a payment that can no longer be made. It hunts you because you have
## gold and it needs gold, and the game never explains that.
##
## You are looking at your own future, and it is never said out loud (ADR-020).
##
## ## Not an `Enemy`, deliberately
##
## `Enemy` is `DES-013`'s awareness ladder — UNAWARE → SUSPICIOUS → ALERTED —
## driven by a sight cone and a hearing radius, and it can be killed. This has
## a **different ladder** (`DES-017`: Distant, Coursing, Sighted, Collecting,
## Lost), a **different sensory model**, and cannot be killed at all yet.
## Inheriting to override every one of those would leave a base class whose
## every assumption is wrong for its only subclass.
##
## ## The three senses, and why they are not one
##
## | Range | What it senses | Reads |
## |---|---|---|
## | Far | Clamor — the commotion of you existing loudly | `ClamorField`, by gradient |
## | Near | **Carried tribute value, through walls** | `Inventory.total_tribute()` |
## | Contact | Sight, normally | a ray |
##
## The middle row is the whole design. *"A silent Veiðimaðr with a bag full of
## Dvergar regalia is a lantern to this thing."* **Going quiet is not enough** —
## to become uninteresting you have to actually give something up, which is the
## entire game expressed as an enemy's sensory model.
##
## ## It does not know where you are
##
## Coursing follows the **clamor gradient**, never a player transform
## (`TEC-001`). It walks up the noise and arrives where the noise was, which is
## why dropping quiet and moving is a real escape rather than a scripted one.
## `--hunt-probe` asserts exactly this: make noise, move away silently, and the
## Hunter must go to the noise and not to you. That check fails if anyone ever
## "helpfully" gives it the player's position.
##
## ## What is absent, not stubbed (ADR-064)
##
## **Killing it.** `DES-017` makes it killable only at high Pact Rank, and Pact
## Rank is `M3-T04`. So it takes no damage at all — a health bar that never
## empties would be a lie told to a playtester.
##
## **Its audio.** *"You hear it before you see it, always"* is `M2-T03`, which
## owns the reserved instrument and the adaptive mix. Every tell it has today is
## visual, which satisfies `DES-018`'s mute-completable rule trivially and owes
## the other half.
##
## **A second one joining, and the cross-floor Hunt.** Both need floors, and
## there is one hand-built floor until `M4-T01`.
##
## **The Sealing.** Moved to `M2-T04` by ADR-089 — it seals Shafts, and Shafts
## are what `M2-T04` builds. Sealing an exit that does not exist is not a thing
## that can be built or checked.

enum State { DISTANT, COURSING, SIGHTED, COLLECTING, LOST }

## `DES-017` says the silhouette must read at any distance, and `ART-005`
## spends saturated colour on treasure. It is *made* of treasure, so it is the
## one actor that is allowed to glitter — and it reads wrong on purpose:
## lopsided, too big, gold where a person should be.
const TINTS: Dictionary = {
	State.DISTANT: Color(0.36, 0.30, 0.16),
	State.COURSING: Color(0.58, 0.45, 0.18),
	State.SIGHTED: Color(0.92, 0.72, 0.24),
	State.COLLECTING: Color(0.45, 0.52, 0.40),
	State.LOST: Color(0.44, 0.37, 0.22),
}

const REPLICATION_HZ: float = 20.0
const REPLICATED_PROPERTIES: Dictionary = {
	".:position": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	".:rotation:y": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	".:state_index": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
}

signal state_changed(to: State)

## Replicated as an int, because `MultiplayerSynchronizer` carries properties
## and an enum is one. Clients need it to tint their copy — `DES-018` requires
## every state change to be legible, and a teammate's screen has to show the
## same thing yours does.
var state_index: int = State.DISTANT:
	set(value):
		if state_index == value:
			return
		state_index = value
		if is_node_ready():
			_apply_tint()
		state_changed.emit(state_index as State)

## Seconds since it entered the floor. Escalation reads this: `DES-017` says it
## gets faster and reads you more accurately the longer you stay.
var age: float = 0.0

var _field: ClamorField = null
var _target: Player = null
var _bait: WorldItem = null
var _collect_left: float = 0.0
var _patience_left: float = 0.0
var _goal: Vector3 = Vector3.ZERO
var _has_goal: bool = false
var _material: StandardMaterial3D = null
var _mesh: MeshInstance3D = null


func configure_replication() -> void:
	var config := SceneReplicationConfig.new()
	for path: String in REPLICATED_PROPERTIES:
		var property := NodePath(path)
		config.add_property(property)
		config.property_set_spawn(property, true)
		config.property_set_replication_mode(property,
			int(REPLICATED_PROPERTIES[path]))
	var sync := MultiplayerSynchronizer.new()
	sync.name = "HunterSync"
	sync.replication_config = config
	sync.replication_interval = 1.0 / REPLICATION_HZ
	sync.delta_interval = 1.0 / REPLICATION_HZ
	add_child(sync)


## The level hands it the field it hunts by. Calls down: it never goes looking
## for a system in the tree above it.
func hunt_with(field: ClamorField) -> void:
	_field = field


func _ready() -> void:
	add_to_group(&"hunters")
	# **Not the WORLD layer**, which is what a `CharacterBody3D` defaults to.
	#
	# Built in code rather than from a `.tscn`, this inherited layer 1 and was
	# therefore *architecture*: it blocked the player like a wall, it blocked
	# `ClamorSource.reach()` so standing behind it muffled you, and — the
	# genuinely absurd one — it blocked `ClamorField._open_between`, so the
	# Hunter was a moving obstruction in the noise field it navigates by, able
	# to wall off the trail it was following.
	#
	# Caught by `--bag-probe`, which measures the cost of weight and suddenly
	# reported that dropping 14 kg made the player *slower*: the Hunter had
	# walked into them and was pushing. A check written for one thing failing
	# on another is the argument for keeping it in the sweep.
	collision_layer = CollisionLayers.ENEMY_BODY
	collision_mask = CollisionLayers.WORLD
	_build_body()
	_apply_tint()
	# Every decision it makes is host-side (`TEC-004`: consequences have one
	# owner). A client's copy is a body that receives a transform and a colour.
	set_physics_process(multiplayer.is_server())


func state() -> State:
	return state_index as State


func target() -> Player:
	return _target


## What it is currently walking at, for the debug overlay. The overlay draws
## this rather than deriving its own, so a view that disagrees with the
## simulation is not possible (the ADR-073 rule).
func goal() -> Vector3:
	return _goal


func has_goal() -> bool:
	return _has_goal


# ── senses ────────────────────────────────────────────────────────────────


## Metres it currently feels wealth from. Grows with time on the floor, which
## is most of what "escalation" means here — staying does not summon more of
## them yet, it makes the one you have better at finding you.
func wealth_range() -> float:
	var tuning: TuningProfile = Config.tuning
	return tuning.hunter_wealth_range + tuning.hunter_range_per_minute * (age / 60.0)


func speed_for(pursuing: bool) -> float:
	var tuning: TuningProfile = Config.tuning
	var base: float = tuning.hunter_pursue_speed if pursuing else tuning.hunter_walk_speed
	return base + tuning.hunter_speed_per_minute * (age / 60.0)


## The richest player inside wealth range, or `null`.
##
## **Through walls, and through silence.** `DES-017`: co-op makes this pick the
## brightest of four readings, which produces the social pressure the design
## wants — *"it's coming for you, you're carrying too much."* With one player it
## is simply the question of whether you are worth crossing a room for.
func _richest_in_range() -> Player:
	var tuning: TuningProfile = Config.tuning
	var reach: float = wealth_range()
	var best: Player = null
	var best_value: int = tuning.hunter_wealth_floor - 1
	for node: Node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if player == null:
			continue
		if global_position.distance_to(player.global_position) > reach:
			continue
		var value: int = player.inventory.total_tribute()
		if value > best_value:
			best_value = value
			best = player
	return best


## A bait it should stop for (ADR-039: **proportional to carried value**).
##
## A fixed toll would be ruinous on the first floor and pocket change by the
## time it matters. Proportional keeps the decision live at every wealth level:
## the richer you are, the more you have to give up to become boring, which is
## the same sentence the whole game is written in.
func _bait_worth_taking() -> WorldItem:
	var tuning: TuningProfile = Config.tuning
	var carried: int = _target.inventory.total_tribute() if _target != null else 0
	# Proportional (ADR-039) **with an absolute floor**, and the floor is the
	# half that had to be learned. Proportional alone means proportional to
	# *zero* when the player is carrying nothing, so every lump of authored
	# floor loot became an irresistible bait and the Hunter spent the whole run
	# tidying up. `--hunt-probe` caught it as a wealth-sensing failure, which is
	# what it looked like from outside: the Hunter never noticed a rich player
	# because it was already stooped over a torc.
	#
	# The floor is `hunter_wealth_floor` — the same number that decides whether
	# *you* are worth crossing a room for. One threshold for "worth having",
	# applied to a player and to a purse alike, which is also the right
	# characterisation: it does not want gold, it wants *enough* gold.
	var needed: int = maxi(tuning.hunter_wealth_floor,
		int(ceil(carried * tuning.hunter_bait_fraction)))
	var best: WorldItem = null
	var best_value: int = 0
	for node: Node in get_tree().get_nodes_in_group(WorldItem.GROUP):
		var item := node as WorldItem
		if item == null or not item.is_inside_tree() or item.in_flight():
			continue
		# Only gold a player disturbed. Treasure that has lain here since
		# before it arrived is scenery to it — see `WorldItem.disturbed`.
		if not item.disturbed:
			continue
		var definition: ItemResource = item.definition()
		if definition == null or definition.tribute_value < needed:
			continue
		if global_position.distance_to(item.global_position) > wealth_range():
			continue
		if definition.tribute_value > best_value:
			best_value = definition.tribute_value
			best = item
	return best


func _can_see(player: Player) -> bool:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = global_position + Vector3.UP * 1.5
	var to: Vector3 = player.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = CollisionLayers.WORLD
	return space.intersect_ray(query).is_empty()


# ── the brain ─────────────────────────────────────────────────────────────


func _physics_process(delta: float) -> void:
	age += delta
	_think(delta)
	_walk(delta)


func _think(delta: float) -> void:
	# Gold first, always, and before anything else can claim its attention.
	# `DES-017`: *"it will stop and pick it up. Every time. It cannot help
	# itself."* A Hunter that finished its current thought before noticing a
	# thrown purse would make baiting unreliable, and an unreliable counter-play
	# is worse than none — the player stops trusting it and stops using it.
	if state() == State.COLLECTING:
		_tick_collecting(delta)
		return
	var bait: WorldItem = _bait_worth_taking()
	if bait != null:
		_bait = bait
		_collect_left = Config.tuning.hunter_collect_seconds
		_goal = bait.global_position
		_has_goal = true
		state_index = State.COLLECTING
		return

	var rich: Player = _richest_in_range()
	if rich != null:
		_target = rich
		_patience_left = Config.tuning.hunter_patience
		_goal = rich.global_position
		_has_goal = true
		# Wealth-sensing does not need line of sight; sight only changes how it
		# *reads*, not whether it is coming.
		state_index = State.SIGHTED if _can_see(rich) else State.COURSING
		return

	# Nothing worth having in range. Fall back to the noise, which is the sense
	# that has no idea who or what made it.
	if _patience_left > 0.0:
		_patience_left -= delta
		_follow_noise(State.LOST)
		return
	_target = null
	_follow_noise(State.DISTANT)


## Walk up the clamor gradient. **The only thing it knows is where noise was.**
##
## `uphill_from` looks at the immediate neighbourhood, so it climbs rather than
## teleporting its attention to the loudest cell on the floor. When the whole
## neighbourhood is below the floor value it has genuinely lost the trail, and
## it goes to the loudest cell anywhere as a *starting point* — which is the one
## place a global read is honest, because it is not pursuit, it is picking a
## direction to wander in.
func _follow_noise(when_cold: State) -> void:
	if _field == null:
		_has_goal = false
		state_index = when_cold
		return
	var tuning: TuningProfile = Config.tuning
	var uphill: Vector2i = _field.uphill_from(global_position, tuning.clamor_field_floor)
	if uphill.x >= 0:
		_goal = _field.cell_centre(uphill.x, uphill.y)
		_has_goal = true
		state_index = State.COURSING
		return
	var cold: Vector2i = _field.loudest()
	if cold.x >= 0 and _field.level_in(cold) >= tuning.clamor_field_floor:
		_goal = _field.cell_centre(cold.x, cold.y)
		_has_goal = true
		# **Coursing, not `when_cold`.** `DES-017` defines Coursing as *"moving
		# toward your last Clamor spike"*, which is precisely this — the Hunter
		# is across the level from the noise and setting off toward it. Calling
		# it Distant because the neighbourhood happens to be quiet would report
		# "unaware" for a thing that is walking at you, and the state is what
		# the score and the Ear will read from at `M2-T03`.
		state_index = State.COURSING
		return
	# Nothing to go to at all. Now the distinction matters: still within
	# patience is *searching* (Lost), out of patience is genuinely unaware.
	_has_goal = false
	state_index = when_cold


func _tick_collecting(delta: float) -> void:
	if _bait == null or not is_instance_valid(_bait):
		_bait = null
		state_index = State.LOST
		return
	_goal = _bait.global_position
	_has_goal = true
	if global_position.distance_to(_bait.global_position) > Config.tuning.hunter_reach:
		return
	# Reached it. It stoops, and for these seconds you are not the most
	# interesting thing in the room. **This is the window the bait bought.**
	_collect_left -= delta
	_has_goal = false
	if _collect_left > 0.0:
		return
	# It takes the gold with it. Not despawned quietly: an item that vanished
	# would read as a bug, and `DES-017` is explicit that it is *accumulating* —
	# still carrying its hoard, still trying to pay.
	_bait.queue_free()
	_bait = null
	state_index = State.LOST


func _walk(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= Config.tuning.gravity * delta
	else:
		velocity.y = 0.0
	if not _has_goal:
		velocity.x = move_toward(velocity.x, 0.0, Config.tuning.ground_friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, Config.tuning.ground_friction * delta)
		move_and_slide()
		return
	var to_goal: Vector3 = _goal - global_position
	to_goal.y = 0.0
	if to_goal.length() < 0.25:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	var pursuing: bool = state() in [State.SIGHTED, State.COURSING, State.COLLECTING]
	var wish: Vector3 = to_goal.normalized() * speed_for(pursuing)
	velocity.x = wish.x
	velocity.z = wish.z
	# It moves badly because of the weight, and it never turns quickly. The
	# slowness is the counter-play: `DES-005` says terrain is your friend.
	var facing: float = atan2(-to_goal.x, -to_goal.z)
	rotation.y = rotate_toward(rotation.y, facing, Config.tuning.enemy_turn_rate * 8.0 * delta)
	move_and_slide()


# ── the body ──────────────────────────────────────────────────────────────


## Blockout (ADR-046). Taller and far wider than a person, because `DES-017`
## asks for a silhouette that reads at any distance and reads *wrong*: huge,
## lopsided, glittering where a person should not.
func _build_body() -> void:
	var shape := CylinderShape3D.new()
	shape.radius = 0.75
	shape.height = 2.4
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 1.2
	add_child(collider)

	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.45
	mesh.bottom_radius = 0.85
	mesh.height = 2.4
	_material = StandardMaterial3D.new()
	_material.roughness = 0.35
	_mesh = MeshInstance3D.new()
	_mesh.mesh = mesh
	_mesh.material_override = _material
	_mesh.position.y = 1.2
	add_child(_mesh)


func _apply_tint() -> void:
	if _material == null:
		return
	_material.albedo_color = TINTS[state()] as Color
