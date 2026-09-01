class_name FloorPlan
extends RefCounted
## `M4-T01` step 4 — the graph becomes a space (`DES-015`, ADR-170).
##
## `MissionGraph` says what a floor *means*: a held arm, a bypass round it, a
## Prize inside and a way out. This turns that into rectangles and corridors on
## an integer grid, and its entire job is to do so **without losing any of the
## graph's guarantees.** A placer that quietly joins two rooms the graph never
## connected has destroyed the ADR-032 bypass, and every assertion the topology
## passed would still pass while the floor lied about it.
##
## ## Lattice, then rooms, then corridors
##
## Nodes are first assigned cells in a coarse **lattice** — one node per cell,
## grown outward from the entrance. Each room's rectangle is then placed inside
## its own lattice cell with a margin, so two rooms **cannot** overlap or touch:
## the lattice makes it impossible rather than checking for it afterwards.
##
## The margins form a connected network of **gutters**, and every graph edge is
## routed through them as a corridor. Corridors never *merge* — a shared cell
## that joined four rooms where the graph joined two would be exactly the bypass
## ADR-032 did not authorise — but they may **cross**, one bridging square over
## the other. A link comes from a corridor's two doors, and a bridge cell has
## none, so crossing changes the floor's shape without changing its meaning.
## `DES-015` asks for this anyway: *"shafts and chasms you can look down into
## and see the next floor, while traversal still happens via stairs."*
##
## Crossings are not decoration. Forbidding them costs **458 re-rolls per 360
## floors instead of 4**, and leaves floors that cannot be laid out at all.
##
## The lattice is a generation substrate, never a visible constraint
## (`DES-015`): rooms vary in footprint inside their cells, corridors bend
## through the gutters, and nothing about the finished floor is on a grid the
## player can feel. It is here because "no two rooms touch" and "every corridor
## is disjoint" are the two properties the whole approach rests on, and both are
## cheaper to *guarantee* than to *detect* — the Spelunky lesson `TEC-007` §2.5
## takes: guarantee by construction, then assert anyway.
##
## ## Determinism
##
## Stage 4 draws from its own stream, seeded from the run seed, floor index and
## stage number, so it cannot consume stage 3's numbers or be shifted by a
## change to how many values stage 3 drew (`DES-015`, `TEC-004`).
##
## Every candidate list is built in a fixed order and drawn from by index —
## `TEC-007` §1: never let a decision depend on the order a collection happened
## to be built in. The lattice walks the four directions in `STEPS` order, room
## candidates walk `modules` in catalogue order (which `RoomCatalogue` sorts by
## id), and corridors are routed in sorted edge order.
##
## Failure re-rolls with a derived sub-seed, up to `MAX_ROLLS`, and then **fails
## loudly** — `problems()` says so and the floor is not offered. There is
## deliberately no simpler generator to fall back to (ADR-064): a second path
## would be one nobody tests, and both would have to stay deterministic.


const STAGE: int = 4
## The four orthogonal steps, north, east, south, west. The order is fixed
## because every candidate list built from it is drawn from by index, and a
## reordering here would silently renumber every floor ever generated.
const STEPS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
]
## Fine cells per lattice cell. Must exceed the largest authored footprint by
## enough that the gutters can carry several disjoint corridors past each
## other — at `MAX_FOOTPRINT` this leaves a four-cell channel between any two
## neighbouring rooms ⟨tune⟩.
const LATTICE: int = 12
## Largest footprint a module may declare. Asserted, so an over-large `.tres`
## fails the build instead of silently overlapping its neighbour.
const MAX_FOOTPRINT: int = 5
## How many times an on-theme module is entered in the candidate list against
## a neutral one's single entry (`DES-015` step 5) ⟨tune⟩.
##
## Weighted rather than filtered, deliberately. Restricting a floor to modules
## that match the Calamity would make every room of an expedition say the same
## thing, and `DES-015` Layer 2's payoff is a floor you can *read*, not one that
## shouts. Neutral rooms are the quiet between the evidence.
const THEME_WEIGHT: int = 4

## Whole-plan re-rolls before the generator gives up (`TEC-007` §5.3 rule 6).
##
## Each re-roll draws a fresh lattice embedding and a fresh routing order, so it
## is a search rather than a retry. In practice it is almost never needed: 360
## floors cost **4 re-rolls between them** once `MAX_ROUTE` was set correctly.
## The headroom is here for the dense floor-2 graphs, not for the common case
## ⟨tune⟩.
const MAX_ROLLS: int = 60
## Fine cells a single corridor may visit before routing calls it hopeless.
##
## **This constant was the whole problem, and it did not look like it.** With it
## at 4000 the router gave up mid-search on the larger floors, and the symptom
## was *"no corridor could reach 5 from 4"* — which reads as a geometry failure
## and was diagnosed as one twice: first as the lattice being too tight, then as
## the graph being non-planar. Widening the lattice made it **worse** (6 invalid
## floors became 17) because a bigger grid costs more cells to search, which is
## the tell that was missed. At 24000 the same corpus and the same generator
## plan 360 floors with **zero failures and four re-rolls total**.
##
## A search budget that is too small fails like a constraint violation. Nothing
## in the failure message says "I ran out of room to look" ⟨tune⟩.
const MAX_ROUTE: int = 24000
## How far from a settled neighbour a node may be seated when everything beside
## that neighbour is taken, in lattice cells ⟨tune⟩.
const LATTICE_REACH: int = 3

var _graph: MissionGraph = null
var _history: ExpeditionHistory = null
var _floor_index: int = 0
## Per node: the module standing in for it, `null` until seated.
var _mods: Array[RoomModule] = []
## Per node: lattice cell.
var _slot: Array[Vector2i] = []
## Per node: fine-grid rectangle.
var _rect: Array[Rect2i] = []
## Fine cell → node, for room interiors. Lookup only, never iterated to decide.
var _cells: Dictionary = {}
## Fine cell → the routes crossing it, as indices into the sorted edge list.
## Two entries is a bridge: one corridor over the other, never joined.
var _corridor: Dictionary = {}
## Fine cell → the axis its first route runs along, or -1 where that route
## turns or ends. Only a cell with an axis can be bridged square-on.
var _axis: Dictionary = {}
## Where a corridor opens into a room, as `Vector4i(cell.x, cell.y, node,
## route)`. Every other corridor cell is walled from whatever it runs past.
var _doors: Array[Vector4i] = []
var _rolls: int = 0
var _exhausted: bool = false
var _failure: String = ""


static func _sub_seed(run_seed: int, floor_index: int, attempt: int) -> int:
	return MissionGraph._mix(
		MissionGraph._mix(MissionGraph.stage_seed(run_seed, floor_index) + STAGE)
		+ attempt)


## Lay `graph` out. `modules` is normally `RoomCatalogue.all()`; it is a
## parameter so a probe can pin a corpus rather than depend on what is on disk.
static func build(graph: MissionGraph, run_seed: int, floor_index: int,
		modules: Array[RoomModule],
		history: ExpeditionHistory = null) -> FloorPlan:
	var plan := FloorPlan.new()
	plan._graph = graph
	plan._history = history
	plan._floor_index = floor_index
	for attempt: int in MAX_ROLLS:
		plan._reset()
		plan._rolls = attempt
		var rng := RandomNumberGenerator.new()
		rng.seed = _sub_seed(run_seed, floor_index, attempt)
		if plan._attempt(rng, modules):
			return plan
	plan._exhausted = true
	return plan


func _reset() -> void:
	_mods = []
	_slot = []
	_rect = []
	_cells = {}
	_corridor = {}
	_axis = {}
	_doors = []
	_failure = ""
	for i: int in _graph.size():
		_mods.append(null)
		_slot.append(Vector2i.ZERO)
		_rect.append(Rect2i())


func _attempt(rng: RandomNumberGenerator, modules: Array[RoomModule]) -> bool:
	var entrance: int = _graph.node_with(MissionGraph.Role.ENTRANCE)
	if entrance < 0:
		_failure = "the graph has no entrance to grow from"
		return false
	var order: PackedInt32Array = _graph.reachable(entrance)
	if order.size() != _graph.size():
		_failure = "the graph is not connected, so no plan can be"
		return false
	if not _assign_slots(rng, order):
		return false
	if not _seat_rooms(rng, order, modules):
		return false
	return _route_all(rng)


## One node per lattice cell, grown outward. The entrance takes the origin;
## every later node takes a free cell beside one already assigned.
func _assign_slots(rng: RandomNumberGenerator, order: PackedInt32Array) -> bool:
	var taken: Dictionary = {}
	var settled: PackedInt32Array = PackedInt32Array()
	settled.resize(_graph.size())
	_slot[order[0]] = Vector2i.ZERO
	taken[Vector2i.ZERO] = order[0]
	settled[order[0]] = 1
	for i: int in range(1, order.size()):
		var node: int = order[i]
		# Anchors sorted so the candidate list cannot depend on the order
		# neighbours happen to come back in.
		var anchors: PackedInt32Array = PackedInt32Array()
		for other: int in _graph.neighbours(node):
			if settled[other] == 1:
				anchors.append(other)
		anchors.sort()
		# Beside a settled neighbour if there is room, and otherwise as close as
		# there is. A node whose neighbours are all boxed in used to fail the
		# whole roll; letting it sit a cell or two out costs a longer corridor
		# and keeps the floor, which is the better trade every time — the
		# lattice is a substrate, and nothing downstream reads the distance.
		var options: Array[Vector2i] = []
		for reach: int in range(1, LATTICE_REACH + 1):
			for anchor: int in anchors:
				for dx: int in range(-reach, reach + 1):
					var dy: int = reach - absi(dx)
					for at: Vector2i in [_slot[anchor] + Vector2i(dx, dy),
							_slot[anchor] + Vector2i(dx, -dy)]:
						if not taken.has(at) and not options.has(at):
							options.append(at)
			if not options.is_empty():
				break
		if options.is_empty():
			_failure = "node %d had nowhere in the lattice to go" % node
			return false

		# Drawn freely rather than steered toward the cell touching most of the
		# node's neighbours. Preferring locality was tried and made things
		# **worse** — 82 unroutable floors became 128 — because the preference
		# is deterministic, so all eight re-rolls produced near-identical
		# embeddings and the re-roll stopped exploring. A re-roll is only worth
		# having if it can disagree with the attempt before it.
		options.sort()
		var at: Vector2i = options[rng.randi_range(0, options.size() - 1)]
		_slot[node] = at
		taken[at] = node
		settled[node] = 1
	return true


## A module for each node, centred in its lattice cell with a margin. Overlap is
## impossible — the lattice cells are disjoint and the margin keeps every
## rectangle off its own cell's border.
func _seat_rooms(rng: RandomNumberGenerator, order: PackedInt32Array,
		modules: Array[RoomModule]) -> bool:
	for node: int in order:
		var role: int = _graph._role[node]
		var links: int = _graph.neighbours(node).size()
		var held: bool = _graph.is_held(node)
		# Structural fit first, then what the history promised, then the
		# weighting that makes the Calamity legible (`DES-015` step 5).
		var wanted: StringName = &""
		if _history != null and role == MissionGraph.Role.PRIZE:
			wanted = _history.prize_kind()
		var options: Array[RoomModule] = []
		for module: RoomModule in modules:
			if not module.fits(role, links, held, _floor_index):
				continue
			if wanted != &"" and module.prize_kind != wanted:
				continue
			options.append(module)
			if _history != null and _history.favours(module):
				for extra: int in THEME_WEIGHT - 1:
					options.append(module)
		if options.is_empty():
			_failure = ("no module can serve node %d (role %d, %d link(s)%s%s)"
				% [node, role, links, ", held" if held else "",
					", %s" % wanted if wanted != &"" else ""])
			return false
		var module: RoomModule = options[rng.randi_range(0, options.size() - 1)]
		var span: Vector2i = module.footprint
		var free: Vector2i = Vector2i(LATTICE - span.x - 2, LATTICE - span.y - 2)
		var corner: Vector2i = _slot[node] * LATTICE + Vector2i.ONE \
			+ Vector2i(rng.randi_range(0, maxi(0, free.x)),
				rng.randi_range(0, maxi(0, free.y)))
		_mods[node] = module
		_rect[node] = Rect2i(corner, span)
		for x: int in span.x:
			for y: int in span.y:
				_cells[corner + Vector2i(x, y)] = node
	return true


## Every graph edge becomes a corridor. Corridors may cross, and may not merge.
##
## Routed in a drawn order, because which edge goes first decides which ones
## still fit: an edge routed early takes the direct line and a later one has to
## go round. `index` stays the edge's position in the *sorted* list, so
## `digest()` does not move when the order does.
func _route_all(rng: RandomNumberGenerator) -> bool:
	var edges: Array[Vector2i] = _graph._edges.duplicate()
	edges.sort()
	var turn: PackedInt32Array = PackedInt32Array()
	for i: int in edges.size():
		turn.append(i)
	for i: int in range(turn.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = turn[i]
		turn[i] = turn[j]
		turn[j] = swap

	for index: int in turn:
		if not _route(edges[index], index):
			_failure = "no corridor could reach %d from %d" % [
				edges[index].y, edges[index].x]
			return false
	return true


## Which axis a step runs along: 0 horizontal, 1 vertical.
func _axis_of(step: int) -> int:
	return 0 if step % 2 == 1 else 1


## Breadth-first from every cell touching room `a` to any cell touching room
## `b`, through gutters. A cell already carrying a corridor may be **crossed**
## if the crossing is square and the far side is clear — one corridor bridges
## over the other. It may never be *joined*, which is the difference between a
## crossing and a link the graph never authorised.
func _route(edge: Vector2i, index: int) -> bool:
	var from: int = edge.x
	var to: int = edge.y
	var came: Dictionary = {}
	var over: Dictionary = {}
	var queue: Array[Vector2i] = []
	for seed_cell: Vector2i in _perimeter(from):
		if not _cells.has(seed_cell) and not _corridor.has(seed_cell):
			came[seed_cell] = seed_cell
			queue.append(seed_cell)
	var visited: int = 0
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		visited += 1
		if visited > MAX_ROUTE:
			return false
		if _touches(at, to):
			_lay(at, came, over, index, from, to)
			return true
		for step: int in STEPS.size():
			var next: Vector2i = at + STEPS[step]
			if _cells.has(next):
				continue
			var land: Vector2i = next
			var bridge: bool = false
			if _corridor.has(next):
				# Only a single, straight-running corridor can be bridged, and
				# only square-on. A cell where the corridor beneath turns has no
				# axis to be perpendicular to, and one already carrying two is a
				# junction nobody could build.
				var under: PackedInt32Array = _corridor[next]
				if under.size() != 1 or int(_axis.get(next, -1)) < 0:
					continue
				if int(_axis[next]) == _axis_of(step):
					continue
				land = next + STEPS[step]
				if _cells.has(land) or _corridor.has(land):
					continue
				bridge = true
			if came.has(land):
				continue
			came[land] = at
			if bridge:
				over[land] = next
			queue.append(land)
	return false


## Write a found route into the grid, and record the door at each end.
func _lay(at: Vector2i, came: Dictionary, over: Dictionary, index: int,
		from: int, to: int) -> void:
	var path: Array[Vector2i] = []
	var walk: Vector2i = at
	while true:
		path.append(walk)
		if over.has(walk):
			path.append(over[walk])
		if came[walk] == walk:
			break
		walk = came[walk]
	path.reverse()
	for i: int in path.size():
		var cell: Vector2i = path[i]
		var routes: PackedInt32Array = _corridor.get(cell, PackedInt32Array())
		var fresh: bool = routes.is_empty()
		if not routes.has(index):
			routes.append(index)
		_corridor[cell] = routes
		if fresh:
			_axis[cell] = _straight_axis(path, i)
	_doors.append(Vector4i(at.x, at.y, to, index))
	_doors.append(Vector4i(path[0].x, path[0].y, from, index))


## The axis this route runs along at `path[i]`, or -1 where it turns or ends.
## Only a cell with an axis can be bridged: there is nothing to be square to at
## a corner, and an end is a doorway.
func _straight_axis(path: Array[Vector2i], i: int) -> int:
	if i == 0 or i == path.size() - 1:
		return -1
	var before: Vector2i = path[i] - path[i - 1]
	var after: Vector2i = path[i + 1] - path[i]
	if before != after:
		return -1
	return 0 if before.y == 0 else 1


## Cells just outside a room's rectangle, in a fixed order.
##
## Corners are excluded: they sit diagonally off the rectangle and share no edge
## with it, so a route that started on one would record a door into a room it
## does not actually touch.
func _perimeter(node: int) -> Array[Vector2i]:
	var rect: Rect2i = _rect[node]
	var found: Array[Vector2i] = []
	for x: int in range(rect.position.x, rect.end.x):
		found.append(Vector2i(x, rect.position.y - 1))
		found.append(Vector2i(x, rect.end.y))
	for y: int in range(rect.position.y, rect.end.y):
		found.append(Vector2i(rect.position.x - 1, y))
		found.append(Vector2i(rect.end.x, y))
	found.sort()
	return found


func _touches(cell: Vector2i, node: int) -> bool:
	for step: Vector2i in STEPS:
		if _cells.get(cell + step, -1) == node:
			return true
	return false


func rolls() -> int:
	return _rolls


func seated() -> int:
	var count: int = 0
	for module: RoomModule in _mods:
		if module != null:
			count += 1
	return count


func module_of(node: int) -> StringName:
	return _mods[node].id if _mods[node] != null else &""


func rect_of(node: int) -> Rect2i:
	return _rect[node]


func corridor_cells() -> int:
	return _corridor.size()


## Which rooms each corridor actually joins, **read back off the grid** rather
## than taken from the graph that asked for it. That independence is the point:
## a corridor that wandered into a third room shows up here and nowhere else.
func realised_links() -> Array[Vector2i]:
	var by_route: Dictionary = {}
	var doors: Array[Vector4i] = _doors.duplicate()
	doors.sort()
	for door: Vector4i in doors:
		var cell := Vector2i(door.x, door.y)
		if not _corridor.has(cell):
			continue
		var joined: PackedInt32Array = by_route.get(door.w, PackedInt32Array())
		# A door must actually abut the room it claims to open into. If routing
		# ever records one that does not, this is where it stops being true.
		if _touches(cell, door.z) and not joined.has(door.z):
			joined.append(door.z)
		by_route[door.w] = joined
	var links: Array[Vector2i] = []
	var indices: Array = by_route.keys()
	indices.sort()
	for index: int in indices:
		var joined: PackedInt32Array = by_route[index]
		joined.sort()
		if joined.size() == 2:
			links.append(Vector2i(joined[0], joined[1]))
		else:
			# An impossible pair, so a route joining one room or three shows up
			# as a mismatch rather than being silently dropped.
			links.append(Vector2i(-1, joined.size()))
	links.sort()
	return links


## `DES-015` step 8, the placement half. Everything here is the floor failing to
## be the graph it was built from.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if _exhausted:
		found.append(("placement gave up after %d re-rolls (%s) — no fallback "
			+ "generator exists on purpose (ADR-064), so this floor is not "
			+ "offered rather than quietly made worse") % [MAX_ROLLS, _failure])
		return found
	if seated() != _graph.size():
		found.append("%d of %d rooms were never seated" % [seated(), _graph.size()])
		return found

	for node: int in _graph.size():
		var span: Vector2i = _mods[node].footprint
		if span.x > MAX_FOOTPRINT or span.y > MAX_FOOTPRINT \
				or span.x + 2 > LATTICE or span.y + 2 > LATTICE:
			found.append(("module `%s` is %d×%d, which does not fit a lattice "
				+ "cell — a room larger than its cell would reach into its "
				+ "neighbour's") % [_mods[node].id, span.x, span.y])

	# Two rooms may never touch. Guaranteed by the lattice; asserted anyway,
	# because the guarantee is what every later stage is going to assume.
	for a: int in _graph.size():
		for b: int in range(a + 1, _graph.size()):
			if rect_of(a).grow(1).intersects(rect_of(b)):
				found.append(("rooms %d and %d are flush or overlapping, so "
					+ "whether they connect stopped being the graph's "
					+ "decision") % [a, b])

	# The realised floor must be the graph exactly: every edge a corridor, every
	# corridor an edge. An extra link is a bypass ADR-032 never authorised, and
	# a missing one is a soft-lock.
	var realised: Array[Vector2i] = realised_links()
	var wanted: Array[Vector2i] = _graph._edges.duplicate()
	wanted.sort()
	if realised != wanted:
		# Naming the offending link, not just the count. Two lists of equal
		# length that differ in one entry is the interesting case and the one a
		# count cannot describe.
		var odd: String = "counts differ"
		for link: Vector2i in realised:
			if not wanted.has(link):
				odd = ("a corridor joins %d and %d, which the graph does not"
					% [link.x, link.y]) if link.x >= 0 \
					else "a corridor opens into %d room(s) rather than 2" % link.y
				break
		if odd == "counts differ":
			for link: Vector2i in wanted:
				if not realised.has(link):
					odd = "nothing joins %d and %d, which the graph requires" \
						% [link.x, link.y]
					break
		found.append(("the floor realises %d link(s) against the graph's %d: %s "
			+ "— the space stopped being the mission, and every guarantee the "
			+ "topology passed is now about a different floor")
			% [realised.size(), wanted.size(), odd])

	var stacked: int = 0
	for cell: Vector2i in _corridor.keys():
		var routes: PackedInt32Array = _corridor[cell]
		if routes.size() > 2:
			stacked += 1
	if stacked > 0:
		found.append(("%d corridor cell(s) carry three or more routes — two is "
			+ "a bridge and anything more is a junction nobody can build")
			% stacked)

	var held_wrong: int = 0
	for node: int in _graph.size():
		if _graph.is_held(node) and not _mods[node].held_capable:
			held_wrong += 1
	if held_wrong > 0:
		found.append(("%d held room(s) use a module that cannot carry danger — "
			+ "*west long and safe, east short and held* is a placement "
			+ "constraint, not a decoration") % held_wrong)
	return found


## Which module stands at each node, and nothing else.
##
## Separate from `digest()` on purpose. `digest()` folds in the history, because
## two machines must agree about what happened here before they build a room
## from it — which makes it useless for asking *whether the history changed the
## rooms*, since the label alone would make two floors differ. That question is
## the whole of `DES-015` Layer 2 and it needs a fingerprint of the architecture
## with no history written on it.
func module_digest() -> String:
	var parts := PackedStringArray()
	for node: int in _graph.size():
		parts.append("%d:%s" % [node, module_of(node)])
	return "|".join(parts)


## A stable fingerprint of the *space*, for `--plan-probe` and for the day this
## feeds `WorldHash` across processes.
func digest() -> String:
	var parts := PackedStringArray()
	if _history != null:
		parts.append("h%s" % _history.digest())
	for node: int in _graph.size():
		var rect: Rect2i = _rect[node]
		parts.append("%d:%s@%d,%d+%d,%d" % [node, module_of(node),
			rect.position.x, rect.position.y, rect.size.x, rect.size.y])
	var cells: Array = _corridor.keys()
	cells.sort()
	for cell: Vector2i in cells:
		var routes: PackedInt32Array = _corridor[cell]
		var names := PackedStringArray()
		for route: int in routes:
			names.append(str(route))
		parts.append("c%d,%d:%s" % [cell.x, cell.y, "+".join(names)])
	return "%d|%s" % [parts.size(), "|".join(parts)]
