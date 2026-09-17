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
## ## Loot is placed by rule and named by the table
##
## Decision: *derive placement rules from the plan*. The rule is ADR-032's, and
## `FloorAnchors` already tags every spot `prize`, `held` or `bypass` from the
## graph. **What** goes in them is `LOOT`, the Delvings' table (ADR-220,
## `DES-023` §4): each item says the shallowest floor it lies on and whether it
## may be the Prize, a machine's gear or filler, and worth orders what is dealt
## — dearest into the held rooms, cheapest into the bypass.
##
## So the long safe branch pays badly and the short guarded one pays well, on
## any floor, with no hand-placed coordinate. Until ADR-220 this dealt from the
## whole item folder by worth alone, which dealt a bow on thirty-nine floor 0s
## in forty because a bow was the cheapest thing there.


## The way out that is not the Shaft (`DES-005`, ADR-110). One per floor, in the
## guarded half, because *"is a way out worth the walk past the Guardian?"* is
## the question it exists to ask.
const WAYSTONE: StringName = &"con_waystone"

## **What these floors may deal, and from how deep** (ADR-220, `DES-023` §4).
##
## Replaced ADR-193's worth cut, which withheld the dearest share of the whole
## folder from shallow floors. The climb it was built for is kept — `DES-015`
## asks for value that *"climbs steeply with depth"*, and `--machine-probe` still
## holds it to strictly climbing and at least threefold — but the bands are
## authored, so an item added to the folder changes no floor until a table says
## where it lies. **The bands are ⟨tune⟩**; `GATE M4 GREED` is the measurement.
const LOOT: LootTable = preload("res://data/loot/lut_delvings.tres")

## `TEC-007` step 7, population: the stage this draws its one choice from.
const STAGE: int = 7
## The barrow's draw (ADR-242), outside the pipeline's 1–8 like
## `FloorAnchors.STAGE`, so it shares no stream with any stage.
const BARROW_STAGE: int = 11

## **Who stands where** (ADR-237): the Delvings' archetypes by room and depth.
## The Deep reads the same file, as floor one.
const POPULATION: PopulationResource = preload("res://data/population/pop_delvings.tres")

## How far inside its doorway the Hall-Warden stands (ADR-237): a door cell is
## the corridor's, so this brings the post over the threshold and clear of the
## wall, where its leash holds the way in rather than the corridor outside ⟨tune⟩.
const DOOR_STEP: float = 2.2

var _graph: MissionGraph = null
var _plan: FloorPlan = null
var _anchors: FloorAnchors = null
var _machines: FloorMachines = null
var _population: FloorPopulation = null
var _history: ExpeditionHistory = null
var _seed: int = 0
var _depth: int = 0
var _vista: Array = []
var _vista_asked: bool = false
var _vista_why: String = ""


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
	# Step 7: which archetype each post carries, read off the rooms the posts
	# stand in. It draws nothing, so no stream is spent on it (ADR-237).
	floor_at._population = FloorPopulation.of(
		floor_at._plan, floor_at._graph, floor_index, POPULATION)
	return floor_at


## Who stands where on this floor (ADR-237). Public for `--population-probe`.
func population() -> FloorPopulation:
	return _population


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
	var posts: Array[Vector3] = _anchors.posts()
	# **The Warden stands in the doorway, not the room** (ADR-237). Every other
	# post is drawn inside its room; a Blocker drawn there would hold a patch of
	# floor with its leash, and `DES-013`'s Blocker *owns a corridor or door*.
	var door: int = _population.door_index()
	if door >= 0 and door < posts.size():
		posts[door] = door_post(_population.door_node())
	return posts


## Just inside the door of `node` nearest the entrance — the way into the
## guarded arm from the side a party arrives on.
func door_post(node: int) -> Vector3:
	var middle: Vector3 = _anchors.centre_of(node)
	var doors: Array[Vector2i] = _plan.doors_of(node)
	if doors.is_empty():
		return middle
	var arrival: Vector3 = _anchors.centre_of(_graph.node_with(MissionGraph.Role.ENTRANCE))
	var nearest: Vector3 = Vector3.INF
	for cell: Vector2i in doors:
		var at: Vector3 = FloorBuilder.at(cell) + Vector3(
			FloorBuilder.CELL * 0.5, middle.y, FloorBuilder.CELL * 0.5)
		if nearest == Vector3.INF or at.distance_to(arrival) < nearest.distance_to(arrival):
			nearest = at
	var inward: Vector3 = middle - nearest
	inward.y = 0.0
	if inward.length() <= DOOR_STEP:
		return middle
	return nearest + inward.normalized() * DOOR_STEP


func enemy_kind(index: int) -> StringName:
	return _population.kind_at(index)


func guardian_kind() -> StringName:
	return _population.guardian()


func guardian() -> Vector3:
	return _anchors.prize()


func shaft() -> Vector3:
	return _anchors.shaft()


func prize() -> Vector3:
	return _anchors.prize()


func survey_point() -> Vector3:
	return _anchors.survey()


func barrow() -> Array:
	var find: ItemResource = barrow_item()
	if find == null:
		return []
	return [find.id, _anchors.barrow()]


## Rooms between the rooms two points stand in, or -1 — for the probe that asks
## whether the barrow lies behind you (ADR-242).
func hops_between(a: Vector3, b: Vector3) -> int:
	var from: int = room_at(a)
	var to: int = room_at(b)
	if from < 0 or to < 0:
		return -1
	return _anchors.hops(from, to)


## **What the barrow opens on** (ADR-242): a glitter of the deepest band this
## floor opens that a table lets a barrow hold, drawn by the seed like the
## Prize — so the whisper is worth what the floor is, and one seed tempts every
## machine with the same thing.
func barrow_item() -> ItemResource:
	var deepest: int = -1
	for entry: LootEntry in LOOT.entries:
		if entry.can(LootEntry.Deal.BARROW) and entry.from_floor <= _depth:
			deepest = maxi(deepest, entry.from_floor)
	var candidates: Array[ItemResource] = []
	for item: ItemResource in LOOT.items_at(_depth, LootEntry.Deal.BARROW):
		if LOOT.entry_for(item.id).from_floor == deepest:
			candidates.append(item)
	if candidates.is_empty():
		return null
	var pick: int = MissionGraph._mix(
		MissionGraph.stage_seed(_seed, _depth) + BARROW_STAGE)
	return candidates[posmod(pick, candidates.size())]


func hunter() -> Vector3:
	return _anchors.hunter()


func field() -> AABB:
	return _anchors.field()


func door_lights() -> Array[Vector3]:
	return _anchors.door_lights()


## The Prize, the Waystone in the guarded half (`M2-T17`, ADR-110), a machine's
## gear, and — when the floor needs one — the glint that makes its vista.
##
## All fixtures rather than filler for ADR-110's reason: they are decisions
## rather than quantity, and a lever that is deterministically absent at party
## size 1 is not a lever.
func fixtures() -> Array:
	var out: Array = _standing()
	var bait: Array = vista()
	if not bait.is_empty():
		out.append(bait)
	return out


## **The moment `DES-015` asks every floor for, guaranteed** (`M4-T28`,
## ADR-215): `[item id, position]`, or empty when the floor already has one.
##
## A fixture glitter the walk sees forward, from outside its room, at
## `FloorVista.NEAR` or more for `FloorVista.SEEN_LEAST` samples, is the
## vista, and nothing is added. Otherwise the
## **cheapest glitter this floor may hold** is laid where the walk sees best.
##
## **Only when needed, and only the cheapest.** A floor whose Prize is already
## in view down a hall is a floor that works, and the developer's instruction
## was to make floors deliver without changing how the good ones feel. And a
## glint that turns out to be a bead is `DES-002`'s proposition in one object —
## you saw gold, you walked for it, it was nearly nothing — at a price the
## depth curve of ADR-193 does not notice. Fixtures only, never filler, because
## filler is dealt by party size and a vista that exists only for four players
## is ADR-110's deterministically absent lever.
##
## Computed once per floor: it builds the floor as data and walks it, and a
## probe that asks for fixtures on two hundred floors should pay for that once
## each.
func vista() -> Array:
	if _vista_asked:
		return _vista
	_vista_asked = true
	var standing: Array = _standing()
	var walk: FloorVista = FloorVista.of(_plan, _graph, _anchors,
		FloorBuilder.occluders(_plan, _graph, _seed, _depth), spawns()[0])
	for row: Array in standing:
		var item: ItemResource = ItemCatalogue.by_id(row[0] as StringName)
		if item == null or not item.tags.has(&"glitter"):
			continue
		if walk.offers(row[1] as Vector3):
			_vista_why = "not needed — %s already offers the moment" % row[0]
			return _vista
	var bait: ItemResource = null
	for item: ItemResource in _by_worth():
		if item.tags.has(&"glitter"):
			bait = item
	# Nothing that glitters may lie here at all: no vista to guarantee, and
	# `--vista-probe` is what says so rather than a quiet absence.
	if bait == null:
		_vista_why = "nothing that glitters may lie on this floor"
		return _vista
	var avoid: Array[Vector3] = []
	for row: Array in standing:
		avoid.append(row[1] as Vector3)
	for spot: Dictionary in _anchors.loot():
		avoid.append(spot["at"] as Vector3)
	avoid.append_array(spawns())
	avoid.append_array(enemy_posts())
	avoid.append_array(machine_posts())
	avoid.append(hunter())
	var spot: Dictionary = walk.best(avoid, FloorAnchors.SPREAD)
	if spot.is_empty():
		_vista_why = "no spot on this floor is a vista from the walk"
		return _vista
	_vista = [bait.id, spot["at"] as Vector3]
	_vista_why = "laid where the walk sees it from %d point(s) at %.1f m" \
		% [int(spot["seen"]), float(spot["far"])]
	return _vista


## Why `vista` came back as it did, in words — because *empty* means three
## different things (a fixture already offers the moment, nothing may glitter
## here, or no spot is seen at all) and a probe that printed one of them for all
## three said *not needed* about a floor that had simply failed.
func vista_reason() -> String:
	vista()
	return _vista_why


## Which room a point stands in, or -1 for a corridor — `FloorVista`'s answer,
## for the probe that checks it.
## The generated floor's doorways, walked on the mission graph.
func way_of_sound(ear: Vector3, source: Vector3) -> Array:
	var here: int = room_at(ear)
	var there: int = room_at(source)
	if here < 0 or there < 0 or here == there:
		return []
	var rooms: PackedInt32Array = _rooms_between(here, there)
	if rooms.size() < 2:
		return []
	var cell: Vector2i = _plan.door_between(here, rooms[1])
	if cell == FloorPlan.NO_CELL:
		return []
	var door: Vector3 = FloorBuilder.at(cell) \
		+ Vector3(FloorBuilder.CELL * 0.5, 0.0, FloorBuilder.CELL * 0.5)
	return [door, ear.distance_to(door) + door.distance_to(source)
		- ear.distance_to(source)]


## The rooms a sound crosses, nearest first. Breadth-first on the graph rather
## than on the grid: the graph is what says two rooms are joined, and a sound
## that found its own way through the lattice would be claiming a route the
## generator never authorised (ADR-172's rule, applied to hearing).
func _rooms_between(from: int, to: int) -> PackedInt32Array:
	var came: Dictionary = {from: from}
	var queue: PackedInt32Array = PackedInt32Array([from])
	while not queue.is_empty():
		var node: int = queue[0]
		queue.remove_at(0)
		if node == to:
			break
		for next: int in _graph.neighbours(node):
			if came.has(next):
				continue
			came[next] = node
			queue.append(next)
	if not came.has(to):
		return PackedInt32Array()
	var back := PackedInt32Array([to])
	while back[back.size() - 1] != from:
		back.append(int(came[back[back.size() - 1]]))
	back.reverse()
	return back

## A generated room's footprint, or a corridor's own width (`M4-T12`).
func room_across(point: Vector3) -> float:
	var room: int = room_at(point)
	if room < 0:
		return FloorBuilder.CELL
	var rect: Rect2i = _plan.rect_of(room)
	return sqrt(float(rect.size.x * rect.size.y)) * FloorBuilder.CELL


func room_at(point: Vector3) -> int:
	return FloorVista.room_of(_plan, _graph, point)


## The fixtures that stand on every floor whatever it looks like: the Prize,
## the Waystone and a machine's gear.
func _standing() -> Array:
	var out: Array = []
	var guarded: ItemResource = prize_item()
	if guarded != null:
		out.append([guarded.id, _anchors.prize()])
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
	# Dealt from the **top** of what this depth may deal as gear, because a
	# situation is a room somebody had to decide about: gear cheap enough to
	# walk past would make the decision for them. Never glitter (`DES-023` §4) —
	# the fallen carried tools, and a machine full of gold is a treasure room.
	var gear: Array[ItemResource] = LOOT.items_at(_depth, LootEntry.Deal.GEAR)
	var offer: int = 0
	for node: int in _machines.nodes():
		var machine: MachineResource = _machines.at(node)
		if machine.gear <= 0:
			continue
		var spots: Array[Vector3] = _anchors.spots_in(node, machine.gear)
		for at: Vector3 in spots:
			if offer >= gear.size():
				break
			out.append([gear[offer].id, at])
			offer += 1
	return out


## **The one thing the Guardian sits on** (ADR-220, `DES-023` §4).
##
## Chosen from the Prizes of the deepest band this floor opens — a floor 2 lays
## the coin-chest, Ótr's pelt, the altar-plate or Regin's blade (ADR-226), a
## floor 1 the torc, the gem or the coin —
## and **by the seed**, so two floors of one depth do not always guard the same
## object and one seed guards the same one on every machine (`TEC-007`). The
## worth cut this replaced always laid the single dearest item, so a relic
## cheaper than the altar-plate could never be a Prize at all.
func prize_item() -> ItemResource:
	var deepest: int = -1
	for entry: LootEntry in LOOT.entries:
		if entry.can(LootEntry.Deal.PRIZE) and entry.from_floor <= _depth:
			deepest = maxi(deepest, entry.from_floor)
	var candidates: Array[ItemResource] = []
	for item: ItemResource in LOOT.items_at(_depth, LootEntry.Deal.PRIZE):
		if LOOT.entry_for(item.id).from_floor == deepest:
			candidates.append(item)
	if candidates.is_empty():
		return null
	var pick: int = MissionGraph._mix(
		MissionGraph.stage_seed(_seed, _depth) + STAGE)
	return candidates[posmod(pick, candidates.size())]


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
	var pool: Array[ItemResource] = LOOT.items_at(_depth, LootEntry.Deal.FILLER)
	# The Prize's item is spoken for, and so is the bait when this floor needed
	# one — one glint laid on purpose, not a second copy of it dealt into the
	# bypass by quantity.
	var spoken: Array[StringName] = []
	var guarded: ItemResource = prize_item()
	if guarded != null:
		spoken.append(guarded.id)
	var bait: Array = vista()
	if not bait.is_empty():
		spoken.append(bait[0] as StringName)
	pool = pool.filter(func(item: ItemResource) -> bool:
		return not spoken.has(item.id))
	if pool.is_empty():
		return out
	var held: Array[Vector3] = []
	var open: Array[Vector3] = []
	for spot: Dictionary in _anchors.loot():
		if spot["tag"] == &"held":
			held.append(spot["at"] as Vector3)
		elif spot["tag"] == &"bypass":
			open.append(spot["at"] as Vector3)
	# Dearest into the guarded rooms, cheapest into the bypass, and the walk is
	# the price of the difference.
	#
	# **Round the pool, not once through it** (ADR-220). The worth cut dealt
	# each item at most once, which only worked because the folder was full of
	# things that were not filler — a floor 0 had seven rooms of bows and seaxes.
	# A table deals filler as filler, and a floor of the Aftermath has little
	# of it, so the pool comes round again: a room of bog iron beside another is
	# a floor of scrap, which is what the top of the Delvings is. The count is
	# unchanged — `RoomSet` still takes `PartyScaling.loot` rows of this.
	var count: int = pool.size()
	for index: int in held.size():
		out.append([pool[index % count].id, held[index]])
	for index: int in open.size():
		out.append([pool[count - 1 - index % count].id, open[index]])
	return out


## Everything this floor may deal, dearest first (`DES-015` Layer 4, ADR-220).
##
## **Depth has to be where the money is or nothing pulls anybody down** —
## `DES-003` couples the Tithe to what you carry home, and a Tithe payable from
## the shallowest floor is one nobody has to go deep for. ADR-193 found every
## floor drawing one identical pool and cut it by depth; the table's bands are
## that cut, authored.
func _by_worth() -> Array[ItemResource]:
	return worth_at(_depth)


## **What a floor of a given depth may hold, richest first** (ADR-193, ADR-220).
##
## Static and depth-taking since `M4-T23` (ADR-204), because the Shaft has to
## answer *what is under me* — and the floor under you does not exist yet, since
## a party builds one floor at a time (ADR-184). Nothing here reads the seed:
## the table and the depth answer it without rolling a plan.
static func worth_at(depth: int) -> Array[ItemResource]:
	return LOOT.items_at(depth)


## The best find a floor of this depth can produce, in tribute, asked of a depth
## rather than of a built floor. ADR-193 measured 6 → 55 → 140 on the worth
## cut; the table reads 8 → 70 → 140 (ADR-220).
static func best_find(depth: int) -> int:
	var pool: Array[ItemResource] = worth_at(depth)
	return pool[0].tribute_value if not pool.is_empty() else 0
