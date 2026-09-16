class_name FloorAnchors
extends RefCounted
## `M4-T01` — where things stand on a generated floor (`DES-015` steps 6 and 7).
##
## `FloorPlan` decides the shape of a floor and `FloorBuilder` raises it. Neither
## knows where the party arrives, where the Shaft is, where a Gullsjúkr posts, or
## which corner the coin is in. In the authored Deep those are twelve hand-placed
## constants in `room_set.gd`; on a generated floor they have to be **derived
## from the mission**, and this is the file that derives them.
##
## ## It decides positions, never contents
##
## What a Prize *is*, which enemy archetype posts where, and what an item does
## belong to `DES-008`, `DES-013` and `DES-023`. This answers *where*, from the
## graph's roles and the plan's rectangles, and nothing else. That split is what
## lets the loot taxonomy arrive later without touching a line of it.
##
## ## Loot follows ADR-032, because the placement is the argument
##
## `DES-015` claims the two halves of a cycle should **mean different things**,
## and ADR-032 made that concrete on the authored floor: the long safe branch
## pays badly, the short held branch pays well, and the Prize room holds the
## three things worth the fight. That is a rule about **held versus unheld
## rooms**, which the graph already knows — so it generalises to any floor
## without a single hand-placed coordinate.
##
## ## Everything sits inside the room it belongs to
##
## Every point is inset from the room's rect by the wall and a body's radius, so
## nothing is ever spawned inside masonry. The authored floor learned this the
## expensive way: `--walk-probe` spent a run blaming the level for a body it had
## dropped inside a barricade (ADR-144).


## Its own RNG stream. Not a `DES-015` pipeline step — placement is step 7's
## front half — so it takes an id outside the 1–8 range and cannot collide with
## one (`DES-015`: one stream per stage, never shared).
const STAGE: int = 10
## How far a point is kept from the walls of the room holding it: the 0.3 m wall
## plus a body radius plus slack ⟨tune⟩.
const INSET: float = 0.9
## Metres between the party's arrival points. Comfortably more than two body
## radii, because two capsules spawned inside each other shove each other apart
## and the shove is host-side — which reads on a client as two peers disagreeing
## about where somebody is (`room_set.gd`'s `SPREAD`, and its reason).
const SPREAD: float = 1.6
## How far off the floor a placed thing sits, so nothing starts intersecting it.
const CLEARANCE: float = 0.1
## Where a door light hangs, matching the authored floor's `DOOR_LIGHT_HEIGHT`
## so generated and hand-built rooms light the same way (`ART-005`).
const LIGHT_HEIGHT: float = 2.6
## Metres of padding around the floor's own extent for the Clamor field, so a
## sound made at the edge of the last room still has field to fall off in.
const FIELD_MARGIN: float = 6.0
## Rooms between a barrow and the Shaft ⟨tune⟩ (ADR-242): one is a step back,
## three is most of a floor, and two is the walk the whisper asks for.
const BARROW_HOPS: int = 2
## What each room too near the Shaft adds to a barrow room's score — more than
## any detour a floor this size can hold, so nearer is chosen only when nothing
## further exists.
const NEARER_COST: int = 10

var _graph: MissionGraph = null
var _plan: FloorPlan = null
var _rng: RandomNumberGenerator = null


## Read the anchors of `plan`. Deterministic in `run_seed` and `floor_index`,
## like every other stage.
static func of(plan: FloorPlan, graph: MissionGraph, run_seed: int,
		floor_index: int) -> FloorAnchors:
	var anchors := FloorAnchors.new()
	anchors._graph = graph
	anchors._plan = plan
	anchors._rng = RandomNumberGenerator.new()
	anchors._rng.seed = MissionGraph._mix(
		MissionGraph.stage_seed(run_seed, floor_index) + STAGE)
	return anchors


## The middle of a room, on its floor.
func centre_of(node: int) -> Vector3:
	var rect: Rect2i = _plan.rect_of(node)
	return FloorBuilder.at(rect.position) + Vector3(
		rect.size.x * FloorBuilder.CELL * 0.5, CLEARANCE,
		rect.size.y * FloorBuilder.CELL * 0.5)


## A room's walkable interior, inset from its walls.
func inside_of(node: int) -> AABB:
	var rect: Rect2i = _plan.rect_of(node)
	var corner: Vector3 = FloorBuilder.at(rect.position) \
		+ Vector3(INSET, CLEARANCE, INSET)
	var span := Vector3(
		maxf(0.0, rect.size.x * FloorBuilder.CELL - INSET * 2.0), 0.0,
		maxf(0.0, rect.size.y * FloorBuilder.CELL - INSET * 2.0))
	return AABB(corner, span)


## Where the party arrives: `count` points in the entrance, a stride apart.
##
## **A grid, not a line**, and the difference is not cosmetic. Spreading four
## players across one axis needs 4.8 m of clear interior, and the smallest
## entrance module is 3 cells — 6.0 m of room, 4.2 m once the walls and a body's
## radius are taken off. **103 floors of 360** could not have seated a four-stack
## that way, and the failure is bodies spawned inside each other, shoved apart
## host-side, which reads on a client as two peers disagreeing about where
## somebody is. A 2×2 needs 1.6 m on each axis and every entrance has it.
func spawns(count: int) -> Array[Vector3]:
	var room: AABB = inside_of(_graph.node_with(MissionGraph.Role.ENTRANCE))
	var mid: Vector3 = room.position + room.size * 0.5
	var many: int = maxi(count, 1)
	var cols: int = ceili(sqrt(float(many)))
	var rows: int = ceili(float(many) / float(cols))
	var out: Array[Vector3] = []
	for i: int in many:
		var across: float = (float(i % cols) - (cols - 1) * 0.5) * SPREAD
		var down: float = (float(i / cols) - (rows - 1) * 0.5) * SPREAD
		out.append(mid + Vector3(
			clampf(across, -room.size.x * 0.5, room.size.x * 0.5), 0.0,
			clampf(down, -room.size.z * 0.5, room.size.z * 0.5)))
	return out


## The way down and out (`DES-005`).
func shaft() -> Vector3:
	return centre_of(_graph.node_with(MissionGraph.Role.SHAFT))


## The Prize, and the room it is guarded in (`DES-015` Layer 3).
func prize() -> Vector3:
	return centre_of(_graph.node_with(MissionGraph.Role.PRIZE))


## Where the Hunt starts (`DES-017`).
##
## **Behind the Prize, measured in rooms rather than in metres.** `DES-017` wants
## the first meeting to happen on the walk *out* with a full bag, so the Hunter
## begins as far from the entrance as the floor allows — and on a graph, "far"
## means hops, not distance: a room two corridors away across a cycle is closer
## than the metres suggest.
func hunter() -> Vector3:
	return centre_of(_deepest(PackedInt32Array()))


## **The Lodge's cairn** (`M4-T04`, ADR-241): the deepest room that is none of
## the rooms a floor already sends you to — not the entrance, the Prize or the
## Shaft, and not the Hunter's, which would make the work a walk into its arms.
func survey() -> Vector3:
	var skipped := PackedInt32Array([
		_graph.node_with(MissionGraph.Role.ENTRANCE),
		_graph.node_with(MissionGraph.Role.PRIZE),
		_graph.node_with(MissionGraph.Role.SHAFT),
		_deepest(PackedInt32Array()),
	])
	return centre_of(_deepest(skipped))


## **The barrow** (`M4-T04`, ADR-242): a room you already walked through,
## `BARROW_HOPS` short of the Shaft. `DES-007`'s whisper fires when you have
## decided to leave, so what it offers has to lie **behind** you — on the way
## you came, and far enough back that turning round is a decision.
##
## Scored rather than searched, so every floor has one: rooms off the
## entrance-to-Shaft route pay for the detour, rooms nearer or further than
## `BARROW_HOPS` pay for the difference, and ties go to the lower node id
## (`TEC-007` §1). Never a room the floor already sends you to, and never the
## Lodge's cairn's.
func barrow() -> Vector3:
	var entrance: int = _graph.node_with(MissionGraph.Role.ENTRANCE)
	var shaft_node: int = _graph.node_with(MissionGraph.Role.SHAFT)
	var claimed := PackedInt32Array([entrance, shaft_node,
		_graph.node_with(MissionGraph.Role.PRIZE), _deepest(PackedInt32Array())])
	var cairn: int = _deepest(claimed)
	claimed.append(cairn)
	var route: int = hops(entrance, shaft_node)
	var best: int = entrance
	var best_score: int = 1 << 30
	for node: int in _graph.size():
		if claimed.has(node):
			continue
		var module: RoomModule = RoomCatalogue.by_id(_plan.module_of(node))
		if module != null and module.volume == RoomModule.Volume.CRAWL:
			continue
		var back: int = hops(node, shaft_node)
		var out: int = hops(entrance, node)
		if back < 0 or out < 0:
			continue
		var detour: int = out + back - route
		var score: int = detour + absi(back - BARROW_HOPS)
		# **Nearer is worse than aside.** A barrow one room from the Shaft is no
		# turning back at all, so a side room two back beats a route room one
		# back — measured over ninety floors, the plain score chose the
		# second six times.
		if back < BARROW_HOPS:
			score += NEARER_COST * (BARROW_HOPS - back)
		if score < best_score:
			best_score = score
			best = node
	return centre_of(best)


## The room furthest from the entrance in hops, other than `skipped`.
func _deepest(skipped: PackedInt32Array) -> int:
	var entrance: int = _graph.node_with(MissionGraph.Role.ENTRANCE)
	var far: int = entrance
	var best: int = -1
	for node: int in _graph.size():
		if skipped.has(node):
			continue
		# **Never in a crawl.** A crawl is 1.4 m and carries no navmesh on
		# purpose, so a Hunter posted in one is a Hunter that cannot move —
		# the deepest room on a floor is exactly the kind of place a crawl
		# gets seated, so this is a live case rather than a defensive one.
		var module: RoomModule = RoomCatalogue.by_id(_plan.module_of(node))
		if module != null and module.volume == RoomModule.Volume.CRAWL:
			continue
		var away: int = hops(entrance, node)
		# Ties broken by node id, so the choice cannot depend on the order the
		# graph happens to return neighbours in (`TEC-007` §1).
		if away > best:
			best = away
			far = node
	return far


## Where the floor's standing danger posts (`DES-013`, `DES-015` step 6).
##
## **Held rooms, because held is what the graph means by dangerous.** A cycle's
## held arm is the short paid route and the unheld one is ADR-032's bypass; a
## post in the bypass would delete the choice between them, which is the whole
## point of a cycle. One post per held room, drawn inside it.
func posts() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for node: int in _graph.size():
		if not _graph.is_held(node):
			continue
		out.append(_within(node))
	return out


## Every doorway on the floor, at lamp height (`ART-005`, `M2-T13`).
##
## Pale light is the way through, so every doorway carries one and the room shows
## its own exits. Sorted, because a light list that depends on dictionary order
## is a floor that lights differently on two machines.
func door_lights() -> Array[Vector3]:
	var cells: Array[Vector2i] = []
	for node: int in _graph.size():
		for cell: Vector2i in _plan.doors_of(node):
			if not cells.has(cell):
				cells.append(cell)
	cells.sort()
	var out: Array[Vector3] = []
	for cell: Vector2i in cells:
		out.append(FloorBuilder.at(cell) + Vector3(
			FloorBuilder.CELL * 0.5, LIGHT_HEIGHT, FloorBuilder.CELL * 0.5))
	return out


## The rooms big enough to carry a silhouette you can navigate by — Lynch's
## landmarks, which `TEC-008` §2.2 found the floors had none of.
func landmarks() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for node: int in _graph.size():
		var module: RoomModule = RoomCatalogue.by_id(_plan.module_of(node))
		if module == null or module.volume != RoomModule.Volume.GREAT:
			continue
		out.append(centre_of(node))
	return out


## The bounds the Clamor field covers, padded past the floor's own extent.
func field() -> AABB:
	var hull: Rect2i = _plan.rect_of(0)
	for node: int in _graph.size():
		hull = hull.merge(_plan.rect_of(node))
	var low: Vector3 = FloorBuilder.at(hull.position) \
		- Vector3(FIELD_MARGIN, 0.0, FIELD_MARGIN)
	var span := Vector3(
		hull.size.x * FloorBuilder.CELL + FIELD_MARGIN * 2.0, 0.0,
		hull.size.y * FloorBuilder.CELL + FIELD_MARGIN * 2.0)
	return AABB(low, span)


## Where loot goes, richest first (`DES-008`, ADR-032).
##
## Returns one spot per room worth putting something in, tagged with what the
## room is *for* rather than with an item id — `DES-023` owns the list and
## this owns the geography. Tags are `prize`, `held` and `bypass`.
##
## **The placement is the argument.** ADR-032's finding on the authored floor was
## that a cycle only means something if its two halves pay differently: the long
## safe branch carries a lump of bog iron and a working knife, the short held
## branch carries coin and gold, and the guarded room carries the three things
## worth the fight. Held-versus-unheld is a property of the graph, so the rule
## generalises to any floor without one hand-placed coordinate.
func loot() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var prize_node: int = _graph.node_with(MissionGraph.Role.PRIZE)
	var entrance: int = _graph.node_with(MissionGraph.Role.ENTRANCE)
	for node: int in _graph.size():
		if node == entrance:
			continue
		var module: RoomModule = RoomCatalogue.by_id(_plan.module_of(node))
		# A crawl is 1.15 m of crouch and no swing; leaving loot in one would
		# put a decision somewhere the player cannot defend it.
		if module != null and module.volume == RoomModule.Volume.CRAWL:
			continue
		var tag: StringName = &"bypass"
		if node == prize_node:
			tag = &"prize"
		elif _graph.is_held(node):
			tag = &"held"
		out.append({"at": _within(node), "tag": tag, "node": node})
	return out


## `count` points inside one room, for a machine's contents (`DES-015` step 6).
##
## Positions, never contents — the rule this whole file keeps. `FloorMachines`
## decided a situation stands in this room and `MachineResource` said how much
## of it there is; this only answers *where in the room*, which is the one
## question neither of them can.
##
## Spread on a **ring** rather than drawn independently, for `RoomSet`'s reason
## and the same failure: two things drawn at random land on top of each other
## often enough to matter, and two bodies spawned inside each other shove apart
## host-side, which reads on a client as two peers disagreeing about where
## something is. A ring separates by construction.
func spots_in(node: int, count: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if count <= 0:
		return out
	var room: AABB = inside_of(node)
	var middle: Vector3 = room.position + Vector3(
		room.size.x * 0.5, 0.0, room.size.z * 0.5)
	# Inside the room whatever its shape, and never against a wall: half the
	# smaller span, less the inset the room is already carrying.
	var reach: float = maxf(0.0,
		minf(room.size.x, room.size.z) * 0.5 - SPREAD * 0.5)
	# **One point, not `count` of them, when there is no room for a ring.** A
	# ring of radius zero is `count` things in the same place, which is the
	# exact failure the ring exists to prevent — so a room too small to separate
	# them gets one spot and the caller places less, rather than placing all of
	# it on one square metre.
	if reach <= 0.0 or count == 1:
		out.append(middle)
		return out
	for index: int in count:
		var angle: float = TAU * float(index) / float(count)
		out.append(middle + Vector3(cos(angle), 0.0, sin(angle)) * reach)
	return out


## A drawn point inside a room, on its floor.
func _within(node: int) -> Vector3:
	var room: AABB = inside_of(node)
	return room.position + Vector3(
		_rng.randf() * room.size.x, 0.0, _rng.randf() * room.size.z)


## Hops from `from` to `to` across the graph, or -1 if unreachable.
func hops(from: int, to: int) -> int:
	if from == to:
		return 0
	var seen: Dictionary = {from: 0}
	var queue: Array[int] = [from]
	while not queue.is_empty():
		var at: int = queue.pop_front()
		for next: int in _graph.neighbours(at):
			if seen.has(next):
				continue
			seen[next] = int(seen[at]) + 1
			if next == to:
				return int(seen[next])
			queue.append(next)
	return -1
