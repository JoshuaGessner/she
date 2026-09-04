class_name DelvingsFloor
extends FloorSource
## A generated floor, as something a level can stand on (`M4-T01`, ADR-183).
##
## The other half of `FloorSource`. `AuthoredFloor` hands back the Deep's
## hand-placed constants; this runs the `DES-015` pipeline — history, graph,
## plan, geometry, anchors — and hands back the same nine answers derived from
## it. `RoomSet` cannot tell the difference, which is the whole point: the
## session, the party, the Hunt, the extraction and the wipe are floor-agnostic
## already (ADR-182) and needed somewhere else to ask, not rebuilding.
##
## ## Loot is placed by rule and named by value
##
## Decision: *derive placement rules from the plan*. The rule is ADR-032's, and
## `FloorAnchors` already tags every spot `prize`, `held` or `bypass` from the
## graph. What goes in them is chosen by **`tribute_value`, which the items
## already carry** — the richest thing in the corpus goes on the Prize, the
## dearer half is dealt into the held rooms, the cheaper half into the bypass.
##
## So the long safe branch pays badly and the short guarded one pays well, on
## any floor, with no hand-placed coordinate and **no invented taxonomy**. When
## `M4-T17` gives the items a real one and `DES-008` gives them loot tables,
## this is the function that reads them instead; nothing above it changes.


## The way out that is not the Shaft (`DES-005`, ADR-110). One per floor, in the
## guarded half, because *"is a way out worth the walk past the Guardian?"* is
## the question it exists to ask.
const WAYSTONE: StringName = &"con_waystone"

## What share of the corpus's dearest end the **shallowest** floor may not
## produce ⟨tune⟩ (`M4-T01` step 7, `DES-015` Layer 4, ADR-193).
##
## `DES-015` asks for value that *"climbs steeply with depth"*, and steep is the
## word doing the work: a gentle curve is one nobody changes a decision over, and
## the decision is the product. At 0.45 against the fifteen authored items the
## best thing on floor 0 is worth 8 tribute and the best on floor 2 is worth 140
## — seventeen-fold, which is steep by any reading and is deliberately at the
## uncomfortable end of the range until a playtest says otherwise.
##
## **This is a balance number and it is not settled.** `GATE M4 GREED` is the
## measurement, and `DES-003`'s Tithe is what it lands on: a cycle payable out of
## the Aftermath is a cycle nobody descends for.
const WITHHELD: float = 0.45

## How many items the shallowest floor keeps whatever `WITHHELD` says ⟨tune⟩.
##
## A floor with nothing worth picking up has no decision on it, which is the one
## thing `DES-002`'s loop cannot survive in its first act. Also the guard that
## keeps a small corpus from cutting itself to nothing: fifteen items today,
## and `M4-T17` has not written the taxonomy yet.
const LEAVE_AT_LEAST: int = 6

var _graph: MissionGraph = null
var _plan: FloorPlan = null
var _anchors: FloorAnchors = null
var _machines: FloorMachines = null
var _history: ExpeditionHistory = null
var _seed: int = 0
var _depth: int = 0


## Roll a floor. Deterministic in `run_seed` and `floor_index` end to end, so
## two peers handed the same pair stand in the same place (`TEC-004`).
static func of(run_seed: int, floor_index: int) -> DelvingsFloor:
	var floor_at := DelvingsFloor.new()
	floor_at._seed = run_seed
	floor_at._depth = floor_index
	floor_at._graph = MissionGraph.build(run_seed, floor_index)
	var modules: Array[RoomModule] = RoomCatalogue.all()
	var kinds := PackedStringArray()
	for module: RoomModule in modules:
		if module.prize_kind != &"" and not kinds.has(String(module.prize_kind)):
			kinds.append(String(module.prize_kind))
	kinds.sort()
	# **Kept, not just passed.** It was rolled here and handed to the plan, and
	# nothing else could reach it afterwards — which is half of why the Calamity
	# was never named to a player (ADR-192). A floor knows what happened on it.
	floor_at._history = ExpeditionHistory.roll(
		run_seed, CalamityCatalogue.all(), kinds)
	floor_at._plan = FloorPlan.build(floor_at._graph, run_seed, floor_index,
		modules, floor_at._history)
	floor_at._anchors = FloorAnchors.of(
		floor_at._plan, floor_at._graph, run_seed, floor_index)
	# Step 6, after the space exists and before anything is placed in it: a
	# situation is stamped into a room, and what the room already is decides
	# which situations could be (`DES-015` Layer 3, ADR-192).
	floor_at._machines = FloorMachines.of(
		floor_at._plan, floor_at._graph, run_seed, floor_index)
	return floor_at


## What situations this floor is carrying. Public because `--machine-probe`
## asks, and because the run log is where a bug report about a room that read
## wrong has to be able to name it.
func machines() -> FloorMachines:
	return _machines


## What happened here (`DES-015` Layer 2). The name only — see
## `CalamityResource.display`.
func calamity() -> CalamityResource:
	return _history.calamity() if _history != null else null


## Somewhere to stand in each stamped room, and what to look at from there.
##
## For `--machine-shot`. An arrangement is a claim about **seeing** — seven
## marks pointing at a door is either a sentence or seven boxes, and no headless
## check can tell which. ADR-093 made the rule explicit after `--ember-shot`:
## *anything whose correctness is a claim about seeing gets photographed.*
##
## Stands at the room's edge and looks at its middle, because that is the view a
## player walking in actually gets — photographing from the centre outward would
## judge a room nobody enters that way.
func machine_views() -> Array:
	var out: Array = []
	for node: int in _machines.nodes():
		var room: AABB = _anchors.inside_of(node)
		var middle: Vector3 = _anchors.centre_of(node)
		# The long axis, so the camera has the most room to see across.
		var edge: Vector3 = middle
		if room.size.x >= room.size.z:
			edge.x = room.position.x
		else:
			edge.z = room.position.z
		out.append({
			"id": _machines.at(node).id, "node": node,
			"at": edge, "look": middle,
		})
	return out


## Whatever stopped this floor being buildable, or an empty list. A caller that
## gets rows here has a floor it must not descend into.
##
## **The stamping is asked too.** A machine on the Shaft is not a floor you can
## fix by walking round it, and a problem that only `--machine-probe` can see is
## one a player meets first.
func problems() -> PackedStringArray:
	var out: PackedStringArray = _plan.problems()
	out.append_array(_machines.problems())
	return out


func build(into: Node3D) -> void:
	FloorBuilder.build(_plan, _graph, _seed, _depth, into, _machines)


func spawns() -> Array[Vector3]:
	return _anchors.spawns(Player.MAX_PARTY)


func enemy_posts() -> Array[Vector3]:
	return _anchors.posts()


func guardian() -> Vector3:
	return _anchors.prize()


func shaft() -> Vector3:
	return _anchors.shaft()


func prize() -> Vector3:
	return _anchors.prize()


func hunter() -> Vector3:
	return _anchors.hunter()


func field() -> AABB:
	return _anchors.field()


func door_lights() -> Array[Vector3]:
	return _anchors.door_lights()


## The Prize, and the Waystone in the guarded half (`M2-T17`, ADR-110).
##
## Both are fixtures rather than filler for ADR-110's reason: they are decisions
## rather than quantity, and a lever that is deterministically absent at party
## size 1 is not a lever.
func fixtures() -> Array:
	var out: Array = []
	var dearest: Array[ItemResource] = _by_worth()
	if dearest.is_empty():
		return out
	out.append([dearest[0].id, _anchors.prize()])
	# In a held room if the floor has one, and otherwise wherever is deepest —
	# never in the bypass, which is what would make the safe route the paying
	# one and invert ADR-032.
	for spot: Dictionary in _anchors.loot():
		if spot["tag"] == &"held":
			out.append([WAYSTONE, spot["at"] as Vector3])
			break
	# **A machine's gear is a fixture, not filler** (`DES-015` Layer 3,
	# ADR-192). *"Their gear is still on the floor. So is what killed them"* is
	# a question the player answers with an action, and ADR-110's rule is that a
	# thing which is a decision must not be deterministically absent at party
	# size 1 — a lever nobody can pull is not a lever.
	#
	# Dealt from the **top** of the pool below the Prize's item, because a
	# situation is a room somebody had to decide about: gear cheap enough to
	# walk past would make the decision for them.
	var offer: int = 1
	for node: int in _machines.nodes():
		var machine: MachineResource = _machines.at(node)
		if machine.gear <= 0:
			continue
		var spots: Array[Vector3] = _anchors.spots_in(node, machine.gear)
		for at: Vector3 in spots:
			if offer >= dearest.size():
				break
			out.append([dearest[offer].id, at])
			offer += 1
	return out


## The threat a situation owns, placed once whatever the party size.
##
## `RoomSet` spawns these beside the Guardian and on the same rule, because they
## are the same kind of thing: part of what a room *is*, rather than how much of
## the floor there is to fight.
func machine_posts() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for node: int in _machines.nodes():
		var machine: MachineResource = _machines.at(node)
		if machine.bodies <= 0:
			continue
		out.append_array(_anchors.spots_in(node, machine.bodies))
	return out


## Everything that is quantity rather than a decision, dealt richest-first into
## the rooms that cost the most to reach.
func filler() -> Array:
	var out: Array = []
	var pool: Array[ItemResource] = _by_worth()
	if pool.size() < 2:
		return out
	# The Prize's item is spoken for; the rest are dealt from dearest down.
	pool.remove_at(0)
	var held: Array[Vector3] = []
	var open: Array[Vector3] = []
	for spot: Dictionary in _anchors.loot():
		if spot["tag"] == &"held":
			held.append(spot["at"] as Vector3)
		elif spot["tag"] == &"bypass":
			open.append(spot["at"] as Vector3)
	# Dearest into the guarded rooms, cheapest into the bypass, and the walk is
	# the price of the difference.
	var rich: int = 0
	var poor: int = pool.size() - 1
	for at: Vector3 in held:
		if rich > poor:
			break
		out.append([pool[rich].id, at])
		rich += 1
	for at: Vector3 in open:
		if poor < rich:
			break
		out.append([pool[poor].id, at])
		poor -= 1
	return out


## The corpus by what it is worth, dearest first, with the Ember excluded — it
## is a body's own token and never lies on a floor (`DES-012`).
##
## Sorted by `tribute_value` and then by id, because two items worth the same
## must not be dealt in whatever order the catalogue happened to load them in
## (`TEC-007` §1).
##
## ## **The pool is cut by depth** (`M4-T01` step 7, `DES-015` Layer 4, ADR-193)
##
## `DES-015` Layer 4 names the depth curve as the load-bearing part of
## population: *"value must climb steeply with depth, and the player must be
## able to see that from floor 1."* This function ignored `_depth` entirely, so
## every floor of an expedition drew one identical pool — **the Prize on floor 0
## was the same object as the Prize on floor 2**, and the only thing that got
## worse as you descended was the Hunt.
##
## That is the flat middle `DES-015` opens by diagnosing in other games, sitting
## inside our own generator, and it undercuts more than it looks like: `DES-003`
## couples the Tithe to what you carry home, and a Tithe payable from the
## shallowest floor is one nobody has to go deep for. **Depth has to be where
## the money is or nothing pulls anybody down.**
##
## **Every caller inherits it for free**, which is why the fix is here and not in
## three places: the Prize, the machine gear and the filler all read this one
## list, so cutting the list cuts all of them and nothing above changes.
##
## ## One cut, not three tiers
##
## Floor `d` withholds the dearest `WITHHELD` share of the corpus, closing
## linearly to nothing at `RunFile.LAST_FLOOR`. So the deepest floor can produce
## anything and the shallowest cannot produce the best of it, with the floors
## between overlapping — a gradient rather than three separate loot tables,
## which is what keeps a floor from being identifiable by its drops.
##
## **The numbers are `⟨tune⟩` and the shape is not.** `GATE M4 GREED` — *a
## playtester voluntarily abandons loot to survive* — is the measurement that
## settles how steep this should be, and it cannot be run against a flat curve
## at all. `M4-T17`'s loot tables replace the cut with authored depth bands and
## nothing above this line changes then either.
func _by_worth() -> Array[ItemResource]:
	var pool: Array[ItemResource] = []
	for item: ItemResource in ItemCatalogue.all():
		if item.id == &"con_ember" or item.id == WAYSTONE:
			continue
		pool.append(item)
	pool.sort_custom(func(a: ItemResource, b: ItemResource) -> bool:
		if a.tribute_value != b.tribute_value:
			return a.tribute_value > b.tribute_value
		return String(a.id) < String(b.id))
	return pool.slice(_withheld(pool.size()))


## How many of the dearest items this floor may not produce.
##
## Zero at the bottom, `WITHHELD` of the corpus at the top, linear between.
##
## **Never the whole pool.** A floor with nothing to find is a floor with no
## decision on it, and `LEAVE_AT_LEAST` is the floor under that — the shallowest
## expedition still has to be worth walking through, or `DES-002`'s loop has a
## dead first act.
func _withheld(size: int) -> int:
	if size <= LEAVE_AT_LEAST or RunFile.LAST_FLOOR <= 0:
		return 0
	var deepest: float = float(RunFile.LAST_FLOOR)
	var shallowness: float = clampf(
		(deepest - float(_depth)) / deepest, 0.0, 1.0)
	var cut: int = int(round(float(size) * WITHHELD * shallowness))
	return clampi(cut, 0, size - LEAVE_AT_LEAST)
