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
## belong to `DES-008`, `DES-013` and `M4-T17`. This answers *where*, from the
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
	var entrance: int = _graph.node_with(MissionGraph.Role.ENTRANCE)
	var far: int = entrance
	var best: int = -1
	for node: int in _graph.size():
		# **Never in a crawl.** A crawl is 1.4 m and carries no navmesh on
		# purpose, so a Hunter posted in one is a Hunter that cannot move —
		# the deepest room on a floor is exactly the kind of place a crawl
		# gets seated, so this is a live case rather than a defensive one.
		var module: RoomModule = RoomCatalogue.by_id(_plan.module_of(node))
		if module != null and module.volume == RoomModule.Volume.CRAWL:
			continue
		var hops: int = _hops(entrance, node)
		# Ties broken by node id, so the choice cannot depend on the order the
		# graph happens to return neighbours in (`TEC-007` §1).
		if hops > best:
			best = hops
			far = node
	return centre_of(far)


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
## room is *for* rather than with an item id — `M4-T17` owns the taxonomy and
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


## A drawn point inside a room, on its floor.
func _within(node: int) -> Vector3:
	var room: AABB = inside_of(node)
	return room.position + Vector3(
		_rng.randf() * room.size.x, 0.0, _rng.randf() * room.size.z)


## Hops from `from` to `to` across the graph, or -1 if unreachable.
func _hops(from: int, to: int) -> int:
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
