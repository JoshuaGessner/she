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

var _graph: MissionGraph = null
var _plan: FloorPlan = null
var _anchors: FloorAnchors = null
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
	floor_at._plan = FloorPlan.build(floor_at._graph, run_seed, floor_index,
		modules, ExpeditionHistory.roll(run_seed, CalamityCatalogue.all(), kinds))
	floor_at._anchors = FloorAnchors.of(
		floor_at._plan, floor_at._graph, run_seed, floor_index)
	return floor_at


## Whatever stopped this floor being buildable, or an empty list. A caller that
## gets rows here has a floor it must not descend into.
func problems() -> PackedStringArray:
	return _plan.problems()


func build(into: Node3D) -> void:
	FloorBuilder.build(_plan, _graph, _seed, _depth, into)


func spawns() -> Array[Vector3]:
	return _anchors.spawns(Player.MAX_PARTY)


func enemy_posts() -> Array[Vector3]:
	return _anchors.posts()


func guardian() -> Vector3:
	return _anchors.prize()


func shaft() -> Vector3:
	return _anchors.shaft()


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
	return pool
