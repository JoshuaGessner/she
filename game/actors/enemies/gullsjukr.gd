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

## What it just tore out of somebody's bag, and where it landed. **Signals up,
## calls down** (`TEC-002`): the Hunter decides what it takes, and `CoopSession`
## — which owns every spawn there is — decides what a thing on the floor is.
## Same shape as `Player.dropped`, which the session already listens to.
signal took(item: ItemInstance, at: Vector3)

## Hit, and unbothered by it (`M3-T04`). Raised so the audio director has
## something to listen for when `M2-T03`'s reserved instrument arrives, and so
## a probe can assert the refusal happened rather than inferring it from a
## colour.
signal shrugged()

## How an ember ranks against gold when both are on the floor (`M2-T21`).
## A **priority, not a value** — it outranks any hoard because it is the thing
## every hoard was being gathered *for*, and it is deliberately not a
## `tribute_value` on the resource, which would make somebody's life bankable.
const EMBER_WORTH: int = 1_000_000

## How long a refused blow shows on it, and in what colour (`M3-T04`) ⟨tune⟩.
## Not in the `TuningProfile`: this is a readability constant like the tints
## beside it, not a balance number anyone would sweep.
const SHRUG_SECONDS: float = 0.18
const SHRUG_TINT: Color = Color(0.72, 0.68, 0.52)

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

## Seconds since it entered the floor. Escalation reads this: `DES-017` says it
## gets faster and reads you more accurately the longer you stay.
var age: float = 0.0

## Seconds of shrug left to draw (`M3-T04`). Short, because it is an
## acknowledgement rather than a stagger — nothing about its behaviour changes.
var _shrug_left: float = 0.0

var _field: ClamorField = null
var _target: Player = null
var _bait: WorldItem = null
var _collect_left: float = 0.0
var _patience_left: float = 0.0
var _goal: Vector3 = Vector3.ZERO
var _has_goal: bool = false
## Seconds spent stooping over the player so far. Cleared whenever it stops
## being in reach, so backing away really does cancel it.
var _taking: float = 0.0
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
	if multiplayer.is_server():
		# **What a missed Tithe buys her** (`M3-T04`, ADR-118). It starts the
		# run already this old, so `_wealth_range` opens wider from the first
		# second rather than a new rule appearing in a system the player has
		# already learned. Host-side because `GameState` is never networked and
		# the floor has one owner — whose Tithe heats a *shared* floor is the
		# same question ADR-010 asks about whose rank scales it, and `M3-T10`
		# answers both or neither.
		age = GameState.take_hunt_head_start()
		if age > 0.0:
			print("[hunt] she sent it early — the floor opens at %.0f s old" % age)


## **Can this thing be killed at all?** (`M3-T04`, `DES-017`.)
##
## *"At high Pact Rank it becomes killable. You get its entire hoard, which is
## enormous, and a deed. It is also a person, and the game will not mention that
## either."* `M2-T02` left this absent rather than stubbed, because there was no
## rank to compare against; there is one now, and the number it compares to is
## `⟨tune⟩` in the `TuningProfile` like every other.
##
## **It answers `false` in every build that exists today** — nothing can raise a
## rank until `M3-T01`. That is deliberately not the same as being unwritten:
## the comparison runs, on the real path, every time anything asks. What is
## still absent is the *fight* — its health, its hoard drop, its deed — and
## those arrive with `M3-T01`, when reaching the rank becomes possible and a
## playtester could be shown something other than a health bar that never moves.
func killable() -> bool:
	return GameState.pact_rank >= Config.tuning.gullsjukr_killable_rank


func state() -> State:
	return state_index as State


func target() -> Player:
	return _target


## What it is currently walking at, for the debug overlay. The overlay draws
## this rather than deriving its own, so a view that disagrees with the
## simulation is not possible (the ADR-073 rule).
func goal() -> Vector3:
	return _goal


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
		if definition == null:
			continue
		# **An ember is always worth stopping for** (`M2-T21`, ADR-114).
		# `DES-012` says so in as many words — *"it is disturbed gold by
		# ADR-089's rule, so the Gullsjúkr will stop for it: the thing that
		# would buy you seconds is your friend"* — and it was false in the
		# build: `con_ember` is worth **0 tribute** against a floor of
		# `hunter_wealth_floor`, so the one object that sentence is about was
		# the one object that could never qualify.
		#
		# Exempted rather than given a tribute value, because it is not tribute:
		# she will not buy it back, and a number here would make somebody's life
		# bankable. It is what gold is *for*, which is exactly why this thing
		# wants it more than gold.
		if not item.is_ember() and definition.tribute_value < needed:
			continue
		if global_position.distance_to(item.global_position) > wealth_range():
			continue
		# Ranked, not appended: an ember is worth 0 tribute, so comparing on the
		# raw value would have let it pass the test above and then lose every
		# comparison to a coin — and to the zero this starts at.
		var worth: int = EMBER_WORTH if item.is_ember() else definition.tribute_value
		if worth > best_value:
			best_value = worth
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
	if _shrug_left > 0.0:
		_shrug_left -= delta
		if _shrug_left <= 0.0:
			_apply_tint()
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
		# **Arriving has to cost you something** (`M2-T19`, ADR-112). It used to
		# walk up, stop at 24 cm, and stand inside you for as long as you let
		# it: measured over fourteen seconds, health 100 → 100 and the bag
		# untouched. `DES-017` describes five ways to deal with it and never
		# said what happens if none of them work, so the encounter had no
		# consequence to avoid.
		if global_position.distance_to(rich.global_position) \
				<= Config.tuning.hunter_reach:
			_take_from(rich, delta)
			return
		# Out of reach again — a stoop that was interrupted starts over, so
		# backing away is a real answer rather than a delay.
		_taking = 0.0
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


## **It takes gold, never health** (`M2-T19`, ADR-112).
##
## `DES-017` gives it no attack and this does not give it one. It cannot be
## killed below `gullsjukr_killable_rank` (`M3-T04`) — see `killable()` — so a
## Gullsjúkr that dealt damage would be an
## unwinnable fight you could only run from — the numbers-treadmill `CLAUDE.md`
## rules out as an anti-goal — and it would say nothing about greed. What it
## wants is the hoard. So it reaches in and takes the single richest thing you
## are carrying, which is `DES-002`'s decision arriving as a consequence rather
## than as a prompt: *the run's value, not your life.*
##
## **Stooping first, and the stoop is a telegraph.** ADR-053 puts a 250 ms floor
## under every attack in this game because that is human reaction time;
## `hunter_take_seconds` is well past it, because the answer to this thing is a
## decision and not a reflex (principle 3). Backing out of reach cancels it, and
## so does throwing it something cheaper — `_bait_worth_taking` is checked
## before this every frame, so a purse on the floor still wins its attention.
##
## **What it takes lands at its feet rather than vanishing.** An item deleted
## out of a bag is indistinguishable from a bug, and `DES-018` wants the loss
## legible. Dropped, it is disturbed gold — so the existing bait machinery picks
## it straight back up, it stoops over it for the window a thrown purse buys,
## and in those seconds you can take it back. That is the same beat as baiting,
## turned around: it made the decision for you, and you can still contest it.
func _take_from(player: Player, delta: float) -> void:
	state_index = State.SIGHTED
	_has_goal = false
	var prize: ItemInstance = player.inventory.richest()
	if prize == null:
		# Nothing worth taking. It has no reason to be interested in you.
		_taking = 0.0
		return
	_taking += delta
	if _taking < Config.tuning.hunter_take_seconds:
		return
	_taking = 0.0
	# Through the host's own inventory, which is the only copy that decides
	# anything (`TEC-004`); `Player._on_inventory_changed` pushes it to whoever
	# is playing the body.
	var taken: ItemInstance = player.inventory.remove(prize.instance_id)
	if taken == null:
		return
	print("[hunt] the Gullsjúkr took %s from %s" % [
		taken.definition.display(), player.name])
	# At its feet, disturbed, so it is bait it will now stoop over — and so it
	# is a thing on the floor the player can run in and take back.
	took.emit(taken, global_position + Vector3(0.0, 0.2, 0.0))


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
	# **An ember it stoops over, gets nothing from, and leaves** (`M2-T21`,
	# ADR-114). It wants the thing and it cannot use the thing: her fire is not
	# a payment, and no Tithe was ever settled with one.
	#
	# The mechanical reason matters more than the fiction. Collecting ends in
	# `queue_free`, so an ember treated like gold would be **destroyed on a
	# 4.5 s timer** — deleting a teammate's LIFE with no counter-play once it
	# started, which is exactly the loss `PRO-005` forbids. `DES-012` says the
	# Hunter *stops* for it. Stopping is the whole of it.
	#
	# Clearing `disturbed` is what stops this looping: the ember drops out of
	# `_bait_worth_taking` by the rule that already exists, stays on the floor
	# for whoever is coming, and this thing has had its look. One stoop, one
	# window — which is the seconds `DES-012` says an ember buys. A player who
	# picks it up and sets it down again re-disturbs it, and pays the pickup for
	# a second window.
	if _bait.is_ember():
		print("[hunt] the Gullsjúkr stooped over an ember and left it")
		_bait.disturbed = false
	else:
		# It takes the gold with it. Not despawned quietly: an item that
		# vanished would read as a bug, and `DES-017` is explicit that it is
		# *accumulating* — still carrying its hoard, still trying to pay.
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

	# **Something to hit** (`M3-T04`). Until now it had no `Hurtbox` at all, so
	# a swing at a Gullsjúkr passed straight through and produced *nothing* —
	# no contact, no cue, no refusal. `DES-017` says you cannot kill it with
	# damage, and a player will absolutely try; a game that answers that by
	# doing nothing reads as a broken hitbox, not as a rule. Principle 4 wants
	# a death you can explain in one sentence, and *"my blade did nothing to
	# it"* only becomes a sentence once the game says so.
	#
	# It still has no `Health` — being killable is `M3-T01`, when a rank can
	# actually reach `gullsjukr_killable_rank`. This is the refusal, complete,
	# not a fight with the numbers left out.
	var hurtbox := Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = CollisionLayers.ENEMY_HURTBOX
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	var reach := CollisionShape3D.new()
	var hit_shape := CylinderShape3D.new()
	hit_shape.radius = 0.75
	hit_shape.height = 2.4
	reach.shape = hit_shape
	reach.position.y = 1.2
	hurtbox.add_child(reach)
	hurtbox.hit.connect(_on_struck)
	add_child(hurtbox)


## Struck, and it does not care (`M3-T04`, `DES-017`).
##
## Below `gullsjukr_killable_rank` the blow lands and is **refused**, visibly:
## the tint jumps to the shrug colour and settles back. Visible rather than
## audible because its audio is `M2-T03`'s reserved instrument and is absent by
## design — and `DES-018`'s rule is that every audio channel needs a visual
## twin, not that a cue must be audible first.
##
## Above that rank there is a fight to have, and it is `M3-T01`'s: health, the
## hoard it drops, and the deed. Refusing is what this build does completely.
func _on_struck(_amount: float, _from: Node) -> void:
	if killable():
		# Nothing yet, and deliberately nothing: `M3-T01` gives it the health
		# this branch needs. Reaching here at all requires a rank no build can
		# hold, so it cannot be met in play — but the comparison above runs on
		# every blow, which is what keeps the rule a rule rather than a plan.
		return
	print("[hunt] the blow lands and it does not care")
	shrugged.emit()
	_shrug_left = SHRUG_SECONDS
	_apply_tint()


func _apply_tint() -> void:
	if _material == null:
		return
	if _shrug_left > 0.0:
		_material.albedo_color = SHRUG_TINT
		return
	_material.albedo_color = TINTS[state()] as Color
