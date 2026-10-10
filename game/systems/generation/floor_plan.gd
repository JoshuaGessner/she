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
## other — at `MAX_FOOTPRINT` this leaves a three-cell channel between any two
## neighbouring rooms ⟨tune⟩.
##
## **This is how much of a floor is corridor**, and it was 12 until it was
## measured (ADR-180). Swept over 180 floors per value:
##
## | `LATTICE` | valid | corridor share | median corridor | re-rolls |
## |---|---|---|---|---|
## | 6 | **7/180** | 33% | 4 m | 78 |
## | 7 | 180/180 | 35% | 8 m | 104 |
## | **8** | 180/180 | **41%** | **10 m** | **57** |
## | 10 | 180/180 | 50% | 18 m | 80 |
## | 12 | 180/180 | 56% | 24 m | 87 |
##
## At 12 **more than half the walkable floor was connective tissue**. Eight is
## chosen over seven for margin rather than for its numbers: seven plans every
## floor too, but its re-roll count nearly doubles, which is the placer straining
## next to a cliff — six collapses to seven valid floors in a hundred and eighty.
## Eight has the lowest re-roll count of any value swept, and generates twice as
## fast as twelve.
const LATTICE: int = 8
## Largest footprint a module may declare. Asserted, so an over-large `.tres`
## fails the build instead of silently overlapping its neighbour.
const MAX_FOOTPRINT: int = 5
## Largest footprint a **hub** module may declare (ADR-306). A hub claims a
## two-by-two block of lattice cells, and keeps the same gutter to its
## neighbours as any room keeps in one cell.
const HUB_FOOTPRINT: int = 2 * LATTICE - (LATTICE - MAX_FOOTPRINT)
## The hub's pillars: one every `PILLAR_STEP` cells, symmetric about its middle,
## none nearer a wall than `PILLAR_WALL` cells and none on the middle itself,
## where the room's centre, spawns and rings are measured from ⟨tune⟩.
const PILLAR_STEP: int = 3
const PILLAR_WALL: int = 2
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
## Cells of straight run a crossing needs on each side before it may be used.
##
## Geometry climbs to a bridge over a ramp, and a ramp needs somewhere to be.
## A crossing one cell from a doorway leaves the threshold tilted or stepped —
## and a step is a wall to anything that walks. Routing refuses those crossings
## so the builder never has to paper over one ⟨tune⟩.
##
## **Straight** cells, and it took until ADR-213 for that word to be checked: a
## turn on the approach is a landing and does not count toward the climb (see
## `deck_rises`).
##
## **Four, because three made the ramp too steep to bake** (ADR-180).
## The ramp is this minus one full cells and a half, so three gave 4.0 m of run for
## `BRIDGE_LIFT`'s 3.3 m — 39.5°, under the navmesh's stated 45° and *over* what
## it will actually accept. Every bridge on a floor was an unwalkable hump, and
## nothing said so, because a crossing sits on a cycle by construction and the
## route simply went the other way round. Four cells give 6.0 m of run and
## 28.8°, which bakes.
const BRIDGE_CLEARANCE: int = 4
## How high a bridge deck stands, in **half-risers** (`M4-T29`, ADR-213).
##
## A straight ramp cell climbs two half-risers and the deck sits one half-riser
## under the full lift, so `BRIDGE_CLEARANCE` straight cells bring a deck back to
## the floor exactly — three whole cells and one half. Integers because this file
## decides in integers and `FloorBuilder` only multiplies: see `deck_rises`.
const DECK_RISERS: int = 2 * BRIDGE_CLEARANCE - 1

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

## Longest straight run a corridor may hold before it is made to jog, in cells
## ⟨tune⟩.
##
## `TEC-008` §3.3.2 asks for this for Kaplan & Kaplan's **mystery** — a passage
## bending out of sight promises more if you move deeper, and a straight tunnel
## between two rectangles shows you the entire proposition from the doorway.
##
## The measurement is worse than the document assumed. Across 4780 routes,
## **65% ran dead straight end to end**, the median longest straight run was
## **9 cells — 18 metres** — and the tail reached 75 cells. At four, no sightline
## down a corridor is longer than 10 m.
const DOGLEG_RUN: int = 4

var _graph: MissionGraph = null
var _history: ExpeditionHistory = null
var _floor_index: int = 0
## Per node: the module standing in for it, `null` until seated.
var _mods: Array[RoomModule] = []
## Per node: lattice cell.
var _slot: Array[Vector2i] = []
## The graph's hub (ADR-306), which takes a two-by-two block of the lattice
## whose top-left cell is its `_slot`. -1 if the graph has none.
var _hub: int = -1
## Per node: fine-grid rectangle.
var _rect: Array[Rect2i] = []
## Fine cell → node, for room interiors. Lookup only, never iterated to decide.
var _cells: Dictionary = {}
## Room cells left as rock, and each room's corner blocks — see `_carve`.
var _rock: Dictionary = {}
var _notches: Dictionary = {}
## Fine cell → the routes crossing it, as indices into the sorted edge list.
## Two entries is a bridge: one corridor over the other, never joined.
var _corridor: Dictionary = {}
## Fine cell → the axis its first route runs along, or -1 where that route
## turns or ends. Only a cell with an axis can be bridged square-on.
var _axis: Dictionary = {}
## Where a corridor opens into a room, as `Vector4i(cell.x, cell.y, node,
## route)`. Every other corridor cell is walled from whatever it runs past.
var _doors: Array[Vector4i] = []
## Each laid route's floor heights, `deck_rises` of its final path — kept so a
## later route can ask whether a cell it would bridge is on the floor.
var _rises: Dictionary = {}
## Route index → its cells in walking order, door to door. Kept because
## geometry needs to know which way a corridor *runs*, not only which cells it
## occupies: a crossing has to be ramped up to and down from, and a ramp is a
## property of the path rather than of any one cell.
var _paths: Dictionary = {}
## Route index → the cells where it passes **over** another. The route that was
## laid second is the one that goes up.
var _over: Dictionary = {}
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
	plan._hub = graph.hub()
	for attempt: int in MAX_ROLLS:
		plan._reset()
		plan._rolls = attempt
		var rng := RandomNumberGenerator.new()
		rng.seed = _sub_seed(run_seed, floor_index, attempt)
		if plan._attempt(rng, modules):
			plan._carve(run_seed, floor_index)
			return plan
	plan._exhausted = true
	return plan


## **A room is not a rectangle** (ADR-304). Every room was one, so a floor
## read as boxes on a string however its graph was wired (`TEC-008` §2.2's
## finding, and the playtest's). Corners of a plain room are left as rock,
## after routing and from a stream of their own, so the interior stands as an
## **L** (one corner), a **T** (two on one side) or a **cross** (all four) —
## and some stay rectangles, because a floor of nothing but crosses is a
## pattern too.
##
## Carved *out of* the rectangle rather than grown beyond it, so nothing a
## route, a door, the lattice or the digest reads moves: the rectangle is
## still the room's claim on the grid. What changes is which of its cells are
## floor (`holds`), and every caller that places something inside a room asks
## `notched` first.
##
## Never the entrance, the prize or the shaft — each is read by a rule that
## wants its whole interior — nor a room under three cells either way, and a
## great hall only as an L. A corner is never carved where a door or the
## room's middle is.
const SHAPE_STREAM: int = 0x5A4E
## How likely each shape is, out of the whole: rectangle, L, T, cross ⟨tune⟩.
const SHAPE_WEIGHTS: Array[int] = [3, 3, 2, 2]


func _carve(run_seed: int, floor_index: int) -> void:
	_rock = {}
	_notches = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = MissionGraph._mix(
		MissionGraph.stage_seed(run_seed, floor_index) + STAGE + SHAPE_STREAM)
	# Nor the hub (ADR-306): its shape is its pillars, and a corner of rock in
	# it would be a pillar's worth of room lost from the one room that is meant
	# to be open.
	var special: Array[int] = [_graph.node_with(MissionGraph.Role.ENTRANCE),
		_graph.node_with(MissionGraph.Role.PRIZE), _graph.node_with(MissionGraph.Role.SHAFT),
		_hub]
	var total: int = 0
	for weight: int in SHAPE_WEIGHTS:
		total += weight
	for node: int in _graph.size():
		# Drawn for every room, carved or not, so one room's eligibility cannot
		# shift another's shape.
		var roll: int = rng.randi_range(0, total - 1)
		var turn: int = rng.randi_range(0, 3)
		var module: RoomModule = _mods[node]
		var rect: Rect2i = _rect[node]
		if special.has(node) or module == null \
				or rect.size.x < 3 or rect.size.y < 3:
			continue
		var shape: int = 0
		while roll >= SHAPE_WEIGHTS[shape]:
			roll -= SHAPE_WEIGHTS[shape]
			shape += 1
		if shape == 0:
			continue
		# A great hall is only ever an L: its ledge runs a whole wall corner to
		# corner (`FloorBuilder._ledge`), and one corner of rock leaves the two
		# walls opposite it whole for one.
		if module.volume == RoomModule.Volume.GREAT:
			shape = 1
		# **How much rock, by shape.** The room's middle point — where its
		# centre, its spawns and its rings are measured from — is always left
		# on floor. An L takes half the room each way, which is what makes it
		# read as an L rather than a nicked rectangle; a T takes half across
		# and just under half along its shared side, so the stem stays open; a
		# cross takes just under half both ways.
		var half := Vector2i(rect.size.x / 2, rect.size.y / 2)
		var under := Vector2i(maxi(1, (rect.size.x - 1) / 2), maxi(1, (rect.size.y - 1) / 2))
		var corners: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]
		# The shape in the first orientation its doors allow, from `turn` on —
		# a door in the way turns the shape rather than cancelling it. A cross
		# keeps whichever corners are clear, and is a T or an L when fewer are.
		var picked: Array[Rect2i] = []
		for offset: int in 4:
			var first: int = (turn + offset) % 4
			var second: int = (first + 1) % 4
			if shape == 1:
				var block: Rect2i = _corner_block(rect, corners[first], half)
				if _can_be_rock(node, rect, module, corners[first], block):
					picked = [block]
			elif shape == 2:
				# Two corners sharing a side: under half along it, half across.
				var along_x: bool = corners[first].y == corners[second].y
				var deep := Vector2i(under.x, half.y) if along_x else Vector2i(half.x, under.y)
				var a: Rect2i = _corner_block(rect, corners[first], deep)
				var b: Rect2i = _corner_block(rect, corners[second], deep)
				if _can_be_rock(node, rect, module, corners[first], a) \
						and _can_be_rock(node, rect, module, corners[second], b):
					picked = [a, b]
			if not picked.is_empty():
				break
		if shape == 3:
			for corner: Vector2i in corners:
				var block: Rect2i = _corner_block(rect, corner, under)
				if _can_be_rock(node, rect, module, corner, block):
					picked.append(block)
		for block: Rect2i in picked:
			var held: Array = _notches.get(node, [])
			held.append(block)
			_notches[node] = held
			for x: int in range(block.position.x, block.end.x):
				for y: int in range(block.position.y, block.end.y):
					_rock[Vector2i(x, y)] = node


## The block of `rect` at `corner` (each axis 0 low, 1 high), `deep` cells.
static func _corner_block(rect: Rect2i, corner: Vector2i, deep: Vector2i) -> Rect2i:
	return Rect2i(rect.position + Vector2i(
			0 if corner.x == 0 else rect.size.x - deep.x,
			0 if corner.y == 0 else rect.size.y - deep.y), deep)


## Whether `block` may be left as rock: no door opens onto it, and a great
## hall still has a wall for its ledge.
func _can_be_rock(node: int, rect: Rect2i, module: RoomModule, corner: Vector2i,
		block: Rect2i) -> bool:
	if not _block_is_clear(block, node):
		return false
	if module.volume == RoomModule.Volume.GREAT:
		return _keeps_a_ledge_wall(node, rect, corner)
	return true


## Whether a corner block of `node` can be rock: no door opens onto any of its
## cells from outside, so every way in still arrives on floor.
func _block_is_clear(block: Rect2i, node: int) -> bool:
	for door: Vector2i in doors_of(node):
		for step: Vector2i in STEPS:
			if block.has_point(door + step):
				return false
	return true


## Whether a wall `FloorBuilder._ledge` could use is left whole once `corner`
## of `rect` is rock: long enough for a ramp and a deck, no doorway along it,
## and not one of the two walls that corner touches. The builder's own rule,
## asked early, so carving never costs a great hall its ledge.
func _keeps_a_ledge_wall(node: int, rect: Rect2i, corner: Vector2i) -> bool:
	var doors: Array[Vector2i] = doors_of(node)
	# Sides as `FloorBuilder._strip` numbers them: 0 top, 1 bottom, 2 left, 3 right.
	var touched: Array[int] = [0 if corner.y == 0 else 1, 2 if corner.x == 0 else 3]
	for side: int in 4:
		if touched.has(side):
			continue
		var cells: Array[Vector2i] = []
		var out := Vector2i.ZERO
		match side:
			0:
				out = Vector2i(0, -1)
				for x: int in range(rect.position.x, rect.end.x):
					cells.append(Vector2i(x, rect.position.y))
			1:
				out = Vector2i(0, 1)
				for x: int in range(rect.position.x, rect.end.x):
					cells.append(Vector2i(x, rect.end.y - 1))
			2:
				out = Vector2i(-1, 0)
				for y: int in range(rect.position.y, rect.end.y):
					cells.append(Vector2i(rect.position.x, y))
			_:
				out = Vector2i(1, 0)
				for y: int in range(rect.position.y, rect.end.y):
					cells.append(Vector2i(rect.end.x - 1, y))
		if cells.size() < FloorBuilder.LEDGE_RAMP_CELLS + 2:
			continue
		var whole: bool = true
		for cell: Vector2i in cells:
			if doors.has(cell + out):
				whole = false
				break
		if whole:
			return true
	return false


## The corner blocks of `node` left as rock (ADR-304).
func notches_of(node: int) -> Array:
	return _notches.get(node, [])


## Whether `cell` is inside a room's rectangle but left as rock (ADR-304).
func notched(cell: Vector2i) -> bool:
	return _rock.has(cell)


func _reset() -> void:
	_mods = []
	_slot = []
	_rect = []
	_cells = {}
	_corridor = {}
	_axis = {}
	_paths = {}
	_over = {}
	_doors = []
	_rises = {}
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
## every later node takes a free cell beside one already assigned. The hub
## takes a two-by-two block (ADR-306), so its neighbours have four cells'
## worth of edge to settle against, and gather round it.
func _assign_slots(rng: RandomNumberGenerator, order: PackedInt32Array) -> bool:
	var taken: Dictionary = {}
	var settled: PackedInt32Array = PackedInt32Array()
	settled.resize(_graph.size())
	_slot[order[0]] = Vector2i.ZERO
	for cell: Vector2i in _block(order[0], Vector2i.ZERO):
		taken[cell] = order[0]
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
				for cell: Vector2i in _block(anchor, _slot[anchor]):
					for dx: int in range(-reach, reach + 1):
						var dy: int = reach - absi(dx)
						for near: Vector2i in [cell + Vector2i(dx, dy), cell + Vector2i(dx, -dy)]:
							for at: Vector2i in _seats_touching(node, near):
								if not options.has(at) and _free(node, at, taken):
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
		for cell: Vector2i in _block(node, at):
			taken[cell] = node
		settled[node] = 1
	return true


## The lattice cells `node` claims seated at `at`: one, or the hub's four.
func _block(node: int, at: Vector2i) -> Array[Vector2i]:
	if node != _hub:
		return [at]
	return [at, at + Vector2i(1, 0), at + Vector2i(0, 1), at + Vector2i(1, 1)]


## Every seat for `node` whose block covers `cell`.
func _seats_touching(node: int, cell: Vector2i) -> Array[Vector2i]:
	if node != _hub:
		return [cell]
	return [cell, cell - Vector2i(1, 0), cell - Vector2i(0, 1), cell - Vector2i(1, 1)]


func _free(node: int, at: Vector2i, taken: Dictionary) -> bool:
	for cell: Vector2i in _block(node, at):
		if taken.has(cell):
			return false
	return true


## A module for each node, centred in its lattice cell with a margin. Overlap is
## impossible — the lattice cells are disjoint and the margin keeps every
## rectangle off its own cell's border.
func _seat_rooms(rng: RandomNumberGenerator, order: PackedInt32Array,
		modules: Array[RoomModule]) -> bool:
	var crawls: Dictionary = {}
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
			if not module.fits(role, links, held, _floor_index, node == _hub):
				continue
			if wanted != &"" and module.prize_kind != wanted:
				continue
			# **A crawl may never be the only way in.** See `_may_crawl`.
			if module.volume == RoomModule.Volume.CRAWL \
					and not _may_crawl(crawls, node):
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
		if module.volume == RoomModule.Volume.CRAWL:
			crawls[node] = true
		var span: Vector2i = module.footprint
		var room: int = LATTICE * (2 if node == _hub else 1)
		var free: Vector2i = Vector2i(room - span.x - 2, room - span.y - 2)
		var corner: Vector2i = _slot[node] * LATTICE + Vector2i.ONE \
			+ Vector2i(rng.randi_range(0, maxi(0, free.x)),
				rng.randi_range(0, maxi(0, free.y)))
		_mods[node] = module
		_rect[node] = Rect2i(corner, span)
		for x: int in span.x:
			for y: int in span.y:
				_cells[corner + Vector2i(x, y)] = node
	return true


## May this node become a crawl, given the ones already seated as crawls?
##
## A crawl is 1.4 m and the agent stands 1.8 m, so **the Hunt cannot follow you
## through one** — that is `DES-009`'s crouch verb given teeth, and the navmesh
## row asserts the absence of mesh there rather than its presence. But a
## standing room whose *every* approach is a crawl is a room nothing can ever
## reach: a safe room produced by topology rather than by geometry, and
## `DES-005` says the Delvings do not have those. Measured before the rule
## existed: **482 such rooms across 360 floors** (ADR-180).
##
## **The crawls are one set, and the test is against the set as it grows.** Two
## weaker rules were tried and measured:
##
## - *"is this node a cut vertex?"* — the obvious rule, and it left 6 rooms of
##   the 482 stranded. Two crawls on two different approaches to the same room
##   strand it between them while neither is a cut vertex alone.
## - *"admit a maximal set up front, then let the seater pick any subset."* This
##   assumes removing **fewer** nodes cannot strand more, which is false: with
##   `entrance—A—B`, removing both leaves nothing stranded, and removing only A
##   strands B. One floor in 360 still had a safe room.
##
## Testing each crawl against the crawls already placed gives the invariant for
## the final set directly, because every later addition is tested against the
## larger set.
##
## The rule leaves the crawl meaning what `DES-009` wants it to mean. A node on
## a cycle always passes, so crawls seat themselves on the ways *round* — a
## shortcut you can take and the Hunt cannot, which is the whole idea, rather
## than a door it cannot open.
func _may_crawl(crawls: Dictionary, node: int) -> bool:
	var would: Dictionary = crawls.duplicate()
	would[node] = true
	return _reaches_all_but(would,
		_graph.node_with(MissionGraph.Role.ENTRANCE))


## Can every node outside `removed` still be walked to from `entrance`?
func _reaches_all_but(removed: Dictionary, entrance: int) -> bool:
	var seen: Dictionary = {entrance: true}
	var queue: Array[int] = [entrance]
	while not queue.is_empty():
		var at: int = queue.pop_front()
		for next: int in _graph.neighbours(at):
			if removed.has(next) or seen.has(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen.size() == _graph.size() - removed.size()


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
		if not _route(edges[index], index, rng):
			_failure = "no corridor could reach %d from %d" % [
				edges[index].y, edges[index].x]
			return false
	return true


## Does this cell run flush against a room it is not opening into?
##
## Room walls stand outside the room's rect, which puts them **inside** the
## corridor cell next door and takes 0.6 m off its 2.0 m width. A cell with a
## room on two sides keeps 0.8 m, and the navmesh agent is 0.9 m across, so the
## corridor seals — which is exactly how a room ends up an island with both its
## doorways cut correctly.
##
## Only this route's own two rooms may be touched, and touching them is what a
## doorway *is*.
func _hugs(cell: Vector2i, from: int, to: int) -> bool:
	for step: Vector2i in STEPS:
		var owner: int = _cells.get(cell + step, -1)
		if owner >= 0 and owner != from and owner != to:
			return true
	return false


## Which axis a step runs along: 0 horizontal, 1 vertical.
func _axis_of(step: int) -> int:
	return 0 if step % 2 == 1 else 1


## Breadth-first from every cell touching room `a` to any cell touching room
## `b`, through gutters. A cell already carrying a corridor may be **crossed**
## if the crossing is square and the far side is clear — one corridor bridges
## over the other. It may never be *joined*, which is the difference between a
## crossing and a link the graph never authorised.
func _route(edge: Vector2i, index: int, rng: RandomNumberGenerator) -> bool:
	var from: int = edge.x
	var to: int = edge.y
	var came: Dictionary = {}
	var over: Dictionary = {}
	var queue: Array[Vector2i] = []
	for seed_cell: Vector2i in _perimeter(from):
		if _cells.has(seed_cell) or _corridor.has(seed_cell):
			continue
		if _hugs(seed_cell, from, to):
			continue
		came[seed_cell] = seed_cell
		queue.append(seed_cell)
	var visited: int = 0
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		visited += 1
		if visited > MAX_ROUTE:
			return false
		if _touches(at, to):
			# A crossing too near either doorway cannot be ramped, so this
			# arrival is refused and the search carries on looking for another.
			if _climbable(at, came, over):
				_lay(at, came, over, index, from, to, rng)
				return true
			continue
		for step: int in STEPS.size():
			var next: Vector2i = at + STEPS[step]
			if _cells.has(next) or _hugs(next, from, to):
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
				# **And only where it is on the floor** (ADR-306). The corridor
				# beneath may itself be climbing to a bridge of its own, and a deck
				# laid over a cell of its ramp left half a metre between the slope
				# and the deck's underside: no navmesh there, and two rooms of a
				# held span cut off from the floor (seed 57721, floor 2).
				if not _on_the_floor(under[0], next):
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


## Could this route climb to every crossing it makes?
##
## Measured on the path rather than assumed: the ramp needs `BRIDGE_CLEARANCE`
## **straight** cells between a crossing and each doorway — see `deck_rises` for
## why a turn does not count — and a route that cannot give it that is one the
## builder would have to fake. The test is the heights themselves: both doorways
## have to come back down to the floor.
func _climbable(at: Vector2i, came: Dictionary, over: Dictionary) -> bool:
	var path: Array[Vector2i] = []
	var walk: Vector2i = at
	while true:
		path.append(walk)
		if over.has(walk):
			path.append(over[walk])
		if came[walk] == walk:
			break
		walk = came[walk]
	var crossed: Array[Vector2i] = []
	for cell: Vector2i in path:
		if _corridor.has(cell):
			crossed.append(cell)
	if crossed.is_empty():
		return true
	var rises: PackedInt32Array = deck_rises(path, crossed)
	return rises[0] == 0 and rises[rises.size() - 1] == 0


## **How high the floor stands at every cell edge along a route**, in half-risers
## (`M4-T29`, ADR-213).
##
## `size + 1` entries: edge `i` is where cell `i` is entered and edge `i + 1` is
## where it is left. `FloorBuilder` multiplies these into metres and decides
## nothing about them, which is what its header has always said it does — until
## this function existed it worked the heights out for itself.
##
## ## A ramp never climbs through a turn
##
## `BRIDGE_CLEARANCE` was documented as *"cells of straight run"* and was only
## ever checked as **distance**. So a route could climb toward a bridge and turn a
## corner on the way, and the builder tilted that corner's slab along the
## diagonal of the turn — which no slab can do. A cell entered on one edge and
## left by the edge beside it needs those two edges at different heights, and
## they **share a corner**: no plane is two heights at one point. The tilted box
## stood up to half a metre proud of both straight neighbours and poked out of
## its own cell into the corridor next door. It was on 88 of 144 floors sampled
## (361 of 1500 ramps), and it is what stopped the player body on both of the
## floors it could not cross.
##
## Buildings answer this with a **landing**, and so does this: a turn keeps the
## height it was entered at, and the climb resumes on the next straight cell.
##
## **Landings rather than refusing the turn**, because refusing it was measured
## first. Requiring dead-straight approaches removed every diagonal ramp and took
## **70% of the floor's bridges with it** (1.49 per floor down to 0.45) at five
## times the re-rolls — and `DES-015` asks for those bridges by name. A landing
## costs one cell of corridor per turn and keeps the crossing.
##
## For a route with no turn near a crossing these are the heights the builder
## used to lay, with one difference measured and kept: where two bridges on one
## corridor are close enough for their ramps to meet, the dip between them can
## bottom out a half-riser lower (4 cell edges in 144 floors). No cell is steeper
## than a straight ramp cell either way — each profile moves at most two
## half-risers a cell, and so does the highest of them.
static func deck_rises(path: Array[Vector2i],
		crossed: Array[Vector2i]) -> PackedInt32Array:
	var rises := PackedInt32Array()
	rises.resize(path.size() + 1)
	rises.fill(0)
	for i: int in path.size():
		if not crossed.has(path[i]):
			continue
		rises[i] = maxi(rises[i], DECK_RISERS)
		rises[i + 1] = maxi(rises[i + 1], DECK_RISERS)
		# Down the far side, one cell at a time.
		var height: int = DECK_RISERS
		for j: int in range(i + 1, path.size()):
			if height == 0:
				break
			if not turns(path, j):
				height = maxi(height - 2, 0)
			rises[j + 1] = maxi(rises[j + 1], height)
		# And back down the near side.
		height = DECK_RISERS
		for j: int in range(i - 1, -1, -1):
			if height == 0:
				break
			if not turns(path, j):
				height = maxi(height - 2, 0)
			rises[j] = maxi(rises[j], height)
	return rises


## Does the route change direction at `path[i]`?
##
## A doorway cell has only one neighbour on the route, so it has one direction
## and is never a turn — the builder tilts it along the corridor like any other
## straight cell.
static func turns(path: Array[Vector2i], i: int) -> bool:
	if i <= 0 or i >= path.size() - 1:
		return false
	return path[i + 1] - path[i] != path[i] - path[i - 1]


## Break a corridor's straight runs so it bends out of sight (`TEC-008` §3.3.2).
##
## Kaplan & Kaplan's **mystery**: a passage that bends promises more if you move
## deeper, and a straight tunnel between two rectangles shows you the whole
## proposition from the doorway. Measured across 4780 routes, 65% ran dead
## straight end to end and the median longest run was 18 metres.
##
## **A jog, not a re-route.** The router finds shortest paths, and between two
## rooms whose doors line up the straight line is the *only* shortest path — so
## no amount of tie-breaking inside the search can bend it, and constraining the
## search to refuse straight runs risks failing to route at all, which is the
## way `MAX_ROUTE` failed (ADR-172). This pays two cells instead: the corridor
## steps aside, runs parallel, and steps back, keeping both doorways exactly
## where the search put them. When there is no room to step aside it does
## nothing, so it can never turn a routable floor into an unroutable one.
##
## Routes that cross another corridor are left alone. A chicane shifts every
## later cell's index, and `_climbable` measured the crossing's ramp clearance
## against the old ones.
func _dogleg(path: Array[Vector2i], from: int, to: int,
		rng: RandomNumberGenerator) -> Array[Vector2i]:
	for cell: Vector2i in path:
		if _corridor.has(cell):
			return path
	var out: Array[Vector2i] = [path[0]]
	var taken: Dictionary = {path[0]: true}
	var run: int = 0
	var last := Vector2i.ZERO
	for i: int in range(1, path.size()):
		var step: Vector2i = path[i] - path[i - 1]
		run = run + 1 if step == last else 1
		last = step
		if run > DOGLEG_RUN:
			var side := Vector2i(step.y, -step.x)
			var order: Array[Vector2i] = [side, -side]
			if rng.randi_range(0, 1) == 1:
				order.reverse()
			for perp: Vector2i in order:
				var a: Vector2i = path[i - 1] + perp
				var b: Vector2i = path[i] + perp
				if not _spare(a, from, to, taken) \
						or not _spare(b, from, to, taken):
					continue
				out.append(a)
				taken[a] = true
				out.append(b)
				taken[b] = true
				run = 0
				last = Vector2i.ZERO
				break
		out.append(path[i])
		taken[path[i]] = true
	return out


## Is this cell free for a chicane to step into?
func _spare(cell: Vector2i, from: int, to: int, taken: Dictionary) -> bool:
	if _cells.has(cell) or _corridor.has(cell) or taken.has(cell):
		return false
	return not _hugs(cell, from, to)


## Write a found route into the grid, and record the door at each end.
func _lay(at: Vector2i, came: Dictionary, over: Dictionary, index: int,
		from: int, to: int, rng: RandomNumberGenerator) -> void:
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
	path = _dogleg(path, from, to, rng)
	_paths[index] = path
	var crossed: Array[Vector2i] = []
	for cell: Vector2i in path:
		if _corridor.has(cell):
			crossed.append(cell)
	_over[index] = crossed
	for i: int in path.size():
		var cell: Vector2i = path[i]
		var crossing: PackedInt32Array = _corridor.get(cell, PackedInt32Array())
		var fresh: bool = crossing.is_empty()
		if not crossing.has(index):
			crossing.append(index)
		_corridor[cell] = crossing
		if fresh:
			_axis[cell] = _straight_axis(path, i)
	_doors.append(Vector4i(at.x, at.y, to, index))
	_doors.append(Vector4i(path[0].x, path[0].y, from, index))
	_rises[index] = deck_rises(path, crossed)


## Does `route` run level at floor height through `cell`, entering and leaving?
func _on_the_floor(route: int, cell: Vector2i) -> bool:
	var path: Array[Vector2i] = _paths.get(route, [] as Array[Vector2i])
	var i: int = path.find(cell)
	if i < 0 or not _rises.has(route):
		return false
	var rises: PackedInt32Array = _rises[route]
	return rises[i] == 0 and rises[i + 1] == 0


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


## The floor's hub (ADR-306), or -1.
func hub() -> int:
	return _hub


## **Where the hub's pillars stand**, as the cell corners they are centred on
## (ADR-306). A grid every `PILLAR_STEP` cells, symmetric about the middle, kept
## `PILLAR_WALL` cells off every wall so no doorway, ledge or wall-side piece of
## dressing meets one, and never on the middle. A pure function of the hub's
## rectangle, so the builder, the anchors and the probes cannot disagree.
func pillars() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if _hub < 0 or _mods.is_empty() or _mods[_hub] == null:
		return out
	var rect: Rect2i = _rect[_hub]
	var middle: Vector2i = rect.size / 2
	var reach: int = maxi(rect.size.x, rect.size.y) / PILLAR_STEP + 1
	for i: int in range(-reach, reach + 1):
		var x: int = middle.x + i * PILLAR_STEP
		if x < PILLAR_WALL or x > rect.size.x - PILLAR_WALL:
			continue
		for j: int in range(-reach, reach + 1):
			var y: int = middle.y + j * PILLAR_STEP
			if y < PILLAR_WALL or y > rect.size.y - PILLAR_WALL or (i == 0 and j == 0):
				continue
			out.append(rect.position + Vector2i(x, y))
	return out


## **What stands inside a room** (ADR-392): its module's `interior`, laid out.
##
## Each feature is `{"rect": Rect2, "height": float, "role": String}`, the rect
## in **cells** (floats, from the floor's origin) and the height in metres.
## Like `pillars()`, a pure function of the plan — the room's rectangle, its
## doors, its rock — so the builder that lays them, the anchors that keep off
## them and the probes that measure them cannot disagree. Rubble's scatter is
## drawn from a stream keyed on the room's own cell, so nothing else on the
## floor moves when it changes.
##
## What every layout keeps, checked per feature and the feature dropped if not:
## - **a clear apron at every doorway** (`FEATURE_APRON` cells from the door);
## - **the room's middle open** (`FEATURE_MIDDLE`), where its centre, spawns,
##   rings and Prize are measured from;
## - **off its rock and off its walls** — and further off them in a great room,
##   whose ledge the builder lays along a wall of its own choosing;
## - never in the hub, the entrance (its first thirty seconds are for reading
##   it, ADR-389) or the Shaft.
func features_of(node: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if node < 0 or node >= _mods.size() or _mods[node] == null or node == _hub:
		return out
	var module: RoomModule = _mods[node]
	if module.interior == RoomModule.Interior.OPEN \
			or node == _graph.node_with(MissionGraph.Role.ENTRANCE) \
			or node == _graph.node_with(MissionGraph.Role.SHAFT):
		return out
	var rect: Rect2i = _rect[node]
	var long_x: bool = rect.size.x >= rect.size.y
	var long: int = rect.size.x if long_x else rect.size.y
	var short: int = rect.size.y if long_x else rect.size.x
	var great: bool = module.volume == RoomModule.Volume.GREAT
	# The open floor a feature may stand on: a cell off every wall.
	var inner_long: float = float(long) - FEATURE_MARGIN * 2.0
	var inner_short: float = float(short) - FEATURE_MARGIN * 2.0
	var wanted: Array[Dictionary] = []
	# Positions are given as (along, across) the room's long axis and turned
	# into cells below, so one rule serves a room either way round.
	match module.interior:
		RoomModule.Interior.COLONNADE:
			var across: Array[float] = _rows_across(short, 0.2)
			var along: float = FEATURE_MARGIN + 0.2
			while along <= float(long) - FEATURE_MARGIN - 0.2 + 0.001:
				for at: float in across:
					wanted.append(_feature(along, at, 0.4, 0.4, -1.0, "column"))
				along += 2.0
		RoomModule.Interior.PIERS:
			# Four, diagonally off the middle by as much as the room allows and
			# never under 0.6 cells, so the lanes round the middle are a body
			# wide and the room is a loop.
			var off: float = minf(1.0, minf(float(long), float(short)) * 0.5 - FEATURE_MARGIN - 0.25)
			if off >= 0.6:
				for along: float in [-off, off]:
					for at: float in [-off, off]:
						wanted.append(_feature(float(long) * 0.5 + along, float(short) * 0.5 + at,
							0.5, 0.5, -1.0, "pier"))
		RoomModule.Interior.ROWS:
			# Each row broken where the middle is, so the lanes join there and
			# the middle stays open.
			var mid: float = float(long) * 0.5
			for at: float in _rows_across(short, 0.225):
				for span: Vector2 in [Vector2(FEATURE_MARGIN, mid - 0.5),
						Vector2(mid + 0.5, float(long) - FEATURE_MARGIN)]:
					if span.y - span.x >= 0.4:
						wanted.append(_feature((span.x + span.y) * 0.5, at, span.y - span.x, 0.45,
							ROW_HEIGHT, "bier"))
		RoomModule.Interior.CARTS:
			# The rows' lines, broken at the middle the same way, filled with as
			# many carts as each half holds end to end with a gap at each
			# coupling; a half too short for one lengthwise takes one turned
			# across it. The builder turns the cart to the box's long side.
			var centre: float = float(long) * 0.5
			for at: float in _rows_across(short, CART_LONG * 0.5):
				for span: Vector2 in [Vector2(FEATURE_MARGIN, centre - FEATURE_MIDDLE - 0.02),
						Vector2(centre + FEATURE_MIDDLE + 0.02, float(long) - FEATURE_MARGIN)]:
					var room_for: float = span.y - span.x
					var count: int = floori((room_for + CART_GAP) / (CART_LONG + CART_GAP))
					if count == 0:
						if room_for >= CART_WIDE:
							wanted.append(_feature((span.x + span.y) * 0.5, at, CART_WIDE, CART_LONG,
								CART_HEIGHT, "cart"))
						continue
					var first: float = (span.x + span.y) * 0.5 \
						- float(count - 1) * (CART_LONG + CART_GAP) * 0.5
					for index: int in count:
						wanted.append(_feature(first + float(index) * (CART_LONG + CART_GAP), at,
							CART_LONG, CART_WIDE, CART_HEIGHT, "cart"))
		RoomModule.Interior.BAYS:
			# Returns stand against a wall, so never in a great room, whose ledge
			# may run along any wall.
			if not great:
				for along: int in range(1, long):
					var low: bool = along % 2 == 1
					var at: float = BAY_DEPTH * 0.5 if low else float(short) - BAY_DEPTH * 0.5
					wanted.append(_feature(float(along), at, 0.25, BAY_DEPTH, -1.0, "bay"))
		RoomModule.Interior.RUBBLE:
			if inner_long >= 1.0 and inner_short >= 1.0:
				var scatter := RandomNumberGenerator.new()
				scatter.seed = MissionGraph._mix(rect.position.x * 73856093 ^ rect.position.y * 19349663
					^ FEATURE_STREAM)
				for _fallen: int in RUBBLE_BLOCKS:
					var size: float = scatter.randf_range(0.35, 0.6)
					var wide: float = size * scatter.randf_range(0.7, 1.3)
					wanted.append(_feature(
						FEATURE_MARGIN + size * 0.5 + scatter.randf() * maxf(0.0, inner_long - size),
						FEATURE_MARGIN + wide * 0.5 + scatter.randf() * maxf(0.0, inner_short - wide),
						size, wide, scatter.randf_range(0.7, 1.4), "rubble"))
	var doors: Array[Vector2i] = doors_of(node)
	var middle := Vector2(rect.position) + Vector2(rect.size) * 0.5
	var floor_rect := Rect2(Vector2(rect.position), Vector2(rect.size))
	# The ledge's strip and a body's width beside it: its ramp fills the lane
	# the wall margin leaves everywhere else.
	var ledge_keep := Rect2()
	var ledge: int = ledge_side(node)
	if ledge >= 0:
		var strip: Array[Vector2i] = FloorBuilder._strip(rect, ledge)
		ledge_keep = Rect2(Vector2(strip[0]), Vector2.ONE).merge(
			Rect2(Vector2(strip[strip.size() - 1]), Vector2.ONE)).grow(FEATURE_ROCK_CLEAR)
	for raw: Dictionary in wanted:
		var local: Rect2 = raw["rect"]
		# (along, across) → cells.
		var placed := Rect2(
			Vector2(rect.position) + (local.position if long_x else Vector2(local.position.y, local.position.x)),
			local.size if long_x else Vector2(local.size.y, local.size.x))
		if not floor_rect.encloses(placed):
			continue
		if placed.grow(FEATURE_MIDDLE).has_point(middle):
			continue
		var clear: bool = true
		for door: Vector2i in doors:
			if _rect_gap(placed, Vector2(door) + Vector2(0.5, 0.5)) < FEATURE_APRON:
				clear = false
				break
		# **A body's width from any rock** (`--reach-probe`): a carved corner
		# juts into the one-cell lane round the walls, and a feature touching it
		# sealed the lane — four floors in the reach panel had no walkable way
		# from the entrance to the Shaft.
		if clear:
			var kept: Rect2 = placed.grow(FEATURE_ROCK_CLEAR)
			for x: int in range(floori(kept.position.x), ceili(kept.end.x)):
				for y: int in range(floori(kept.position.y), ceili(kept.end.y)):
					if notched(Vector2i(x, y)):
						clear = false
		# **A cell off every wall**, which is also why no feature can stand in
		# a ledge: the builder lays a ledge's deck and ramp in the one-cell
		# strip along whichever wall it picks. A bay is a wall's own.
		if clear and raw["role"] != "bay" \
				and not floor_rect.grow(-FEATURE_MARGIN + 0.001).encloses(placed):
			clear = false
		if clear and ledge >= 0 and ledge_keep.intersects(placed):
			clear = false
		if not clear:
			continue
		out.append({"rect": placed, "height": raw["height"], "role": raw["role"]})
	# **And the room still crosses** (`DES-015` step 8, at room scale). The
	# rules above are each local, and three floors in the reach panel had a
	# mine head's row or a stope's rubble close the way between two doorways
	# anyway — a carved corner and a ledge's ramp narrowing what the margin
	# assumed was a lane. So the room is flooded on a quarter-cell grid with
	# every wall, rock, ledge and feature grown by a body's radius, and while
	# any doorway or the middle is cut off, the last feature laid is taken up.
	var points: Array[Vector2] = [middle]
	for door: Vector2i in doors:
		var mouth := Vector2(door) + Vector2(0.5, 0.5)
		points.append(Vector2(clampf(mouth.x, floor_rect.position.x + 0.35, floor_rect.end.x - 0.35),
			clampf(mouth.y, floor_rect.position.y + 0.35, floor_rect.end.y - 0.35)))
	var ledge_strip := ledge_keep.grow(-FEATURE_ROCK_CLEAR) if ledge >= 0 else Rect2()
	# Asked against the empty room, not against an ideal: the model counts a
	# ledge's whole strip as solid, so a doorway at a ledge's end can read as
	# cut off with nothing in the room — and the room then lost every feature
	# for a fault none of them made.
	var bare: PackedInt32Array = _joined(rect, [], ledge_strip, points)
	while not out.is_empty() and not _keeps(bare, _joined(rect, out, ledge_strip, points)):
		out.pop_back()
	return out


## Does `now` still join every pair of points `bare` joined? Each is a region
## label per point, 0 for a point standing in the solid.
static func _keeps(bare: PackedInt32Array, now: PackedInt32Array) -> bool:
	for i: int in bare.size():
		for j: int in range(i + 1, bare.size()):
			if bare[i] != 0 and bare[i] == bare[j] and (now[i] == 0 or now[i] != now[j]):
				return false
	return true


## A body's radius in cells, for the crossing test: the navmesh agent's 0.45 m
## and a little.
const BODY_CELLS: float = 0.25


## The region each of `points` stands in, for a body `BODY_CELLS` wide in
## `rect` with its rock, its ledge's strip and `features` standing: two points
## with the same label can reach each other; 0 is a point in the solid.
func _joined(rect: Rect2i, features: Array[Dictionary], ledge_strip: Rect2,
		points: Array[Vector2]) -> PackedInt32Array:
	var step: float = 0.25
	var columns: int = rect.size.x * 4
	var rows: int = rect.size.y * 4
	var open := PackedByteArray()
	open.resize(columns * rows)
	var inner := Rect2(Vector2(rect.position), Vector2(rect.size)).grow(-BODY_CELLS)
	for cx: int in columns:
		for cy: int in rows:
			var at := Vector2(rect.position) + Vector2(cx + 0.5, cy + 0.5) * step
			var free: bool = inner.has_point(at)
			if free:
				for x: int in range(floori(at.x - BODY_CELLS), floori(at.x + BODY_CELLS) + 1):
					for y: int in range(floori(at.y - BODY_CELLS), floori(at.y + BODY_CELLS) + 1):
						if notched(Vector2i(x, y)) and _rect_gap(Rect2(x, y, 1, 1), at) < BODY_CELLS:
							free = false
			if free and ledge_strip.size != Vector2.ZERO \
					and _rect_gap(ledge_strip, at) < BODY_CELLS:
				free = false
			if free:
				for feature: Dictionary in features:
					if _rect_gap(feature["rect"], at) < BODY_CELLS:
						free = false
						break
			open[cx + cy * columns] = 1 if free else 0
	var index_of := func(point: Vector2) -> int:
		var local: Vector2 = (point - Vector2(rect.position)) / step
		return clampi(floori(local.x), 0, columns - 1) + clampi(floori(local.y), 0, rows - 1) * columns
	# Each open sample labelled with its region, flooded from each point in
	# turn; a point standing in the solid keeps label 0.
	var label := PackedInt32Array()
	label.resize(columns * rows)
	var regions := PackedInt32Array()
	for point: Vector2 in points:
		var start: int = index_of.call(point)
		if open[start] == 0:
			regions.append(0)
			continue
		if label[start] == 0:
			var mark: int = regions.size() + 1
			label[start] = mark
			var queue: Array[int] = [start]
			while not queue.is_empty():
				var at: int = queue.pop_back()
				var ax: int = at % columns
				var ay: int = at / columns
				for next: Vector2i in [Vector2i(ax + 1, ay), Vector2i(ax - 1, ay),
						Vector2i(ax, ay + 1), Vector2i(ax, ay - 1)]:
					if next.x < 0 or next.y < 0 or next.x >= columns or next.y >= rows:
						continue
					var index: int = next.x + next.y * columns
					if open[index] == 1 and label[index] == 0:
						label[index] = mark
						queue.append(index)
		regions.append(label[start])
	return regions


## **Which wall a great room's ledge runs along** (ADR-392, `TEC-008`
## §3.3.1), or −1 for none. The builder laid it from its own stream, so the
## room's interior could not know where it was, and a pillar beside a ledge's
## ramp sealed the lane between them (three floors of the reach panel had no
## walkable way from the entrance to the Shaft). Decided here instead, by the
## builder's own rules — two deck cells beyond the ramp, no doorway along the
## wall, no rock on it, and not a doorway at both ends (ADR-213) — and chosen
## among the walls that qualify from a stream keyed on the room's own cell.
func ledge_side(node: int) -> int:
	if node < 0 or node >= _mods.size() or _mods[node] == null \
			or _mods[node].volume != RoomModule.Volume.GREAT:
		return -1
	var rect: Rect2i = _rect[node]
	var doors: Array[Vector2i] = doors_of(node)
	var sides: Array[int] = []
	for side: int in 4:
		var wall: Array[Vector2i] = FloorBuilder._strip(rect, side)
		if wall.size() < FloorBuilder.LEDGE_RAMP_CELLS + 2:
			continue
		var clear: bool = true
		for cell: Vector2i in wall:
			if doors.has(cell + FloorBuilder._outward(side)) or notched(cell):
				clear = false
				break
		if FloorBuilder._door_at_end(wall, doors, true) \
				and FloorBuilder._door_at_end(wall, doors, false):
			clear = false
		if clear:
			sides.append(side)
	if sides.is_empty():
		return -1
	var pick: int = MissionGraph._mix(rect.position.x * 73856093 ^ rect.position.y * 19349663
		^ LEDGE_STREAM)
	return sides[posmod(pick, sides.size())]


## Its own stream, so moving a ledge moves nothing else.
const LEDGE_STREAM: int = 0x1ED6


## Cells a feature keeps from any doorway, measured from the door's middle —
## half a cell outside the wall, so this is the cell inside it and a little.
const FEATURE_APRON: float = 1.4
## Cells a feature keeps from the room's middle: room for the point every
## centre, spawn, ring and Prize is measured from.
const FEATURE_MIDDLE: float = 0.4
## Cells a feature keeps off the walls: the one-cell strip a ledge may take.
const FEATURE_MARGIN: float = 1.0
## Cells a feature keeps from rock and from a ledge's strip: only enough that
## two solids never share a face. Whether a body still gets past is the
## crossing test's question (`_crosses`), asked of the whole room at once —
## a fixed clearance here guessed at it per feature, emptied half the
## galleries, and still missed the cases the test catches.
const FEATURE_ROCK_CLEAR: float = 0.1
## Height of a waist-high row, metres: seen over, not walked through.
const ROW_HEIGHT: float = 1.0
## How far a bay's return of wall reaches into the room, cells.
const BAY_DEPTH: float = 0.7
## An ore cart's box, in cells across the floor and metres high:
## `dressing_ore_cart` measures 1.48 m by 1.15 m and 1.11 m high, and
## `--interior-probe` holds the model to these.
const CART_LONG: float = 0.74
const CART_WIDE: float = 0.575
const CART_HEIGHT: float = 1.1
## The gap at a coupling, cells: seen through, too narrow to walk.
const CART_GAP: float = 0.25
## How many blocks a room of rubble has fallen.
const RUBBLE_BLOCKS: int = 3
## Its own stream, so rubble never shifts a draw anything else makes.
const FEATURE_STREAM: int = 0x5EA7


## Where a room's rows stand across it: a cell off both walls, `half` being a
## row's own half-width, or down the middle when the room is too narrow for
## two with a lane between them.
static func _rows_across(short: int, half: float) -> Array[float]:
	var low: float = FEATURE_MARGIN + half
	var high: float = float(short) - FEATURE_MARGIN - half
	if high - low < 0.9:
		return [float(short) * 0.5]
	return [low, high]


## A feature centred at (`along`, `across`), `long_size` by `wide_size` cells,
## `height` metres or −1 for floor to ceiling.
static func _feature(along: float, across: float, long_size: float, wide_size: float,
		height: float, role: String) -> Dictionary:
	return {"rect": Rect2(along - long_size * 0.5, across - wide_size * 0.5, long_size, wide_size),
		"height": height, "role": role}


## The gap from a rectangle to a point, 0 inside.
static func _rect_gap(rect: Rect2, point: Vector2) -> float:
	var dx: float = maxf(maxf(rect.position.x - point.x, 0.0), point.x - rect.end.x)
	var dy: float = maxf(maxf(rect.position.y - point.y, 0.0), point.y - rect.end.y)
	return Vector2(dx, dy).length()


func corridor_cells() -> int:
	return _corridor.size()


## Every route index, in order.
func routes() -> PackedInt32Array:
	var found := PackedInt32Array()
	for index: int in _paths.keys():
		found.append(index)
	found.sort()
	return found


## One route's cells, door to door, in walking order.
func path_of(route: int) -> Array[Vector2i]:
	return _paths.get(route, [] as Array[Vector2i])


## The cells of `route` that cross above another corridor.
func over_of(route: int) -> Array[Vector2i]:
	return _over.get(route, [] as Array[Vector2i])


## Is this cell walkable floor of any kind — room interior or corridor?
##
## `FloorBuilder` asks so it can decide where a tunnel needs a wall. A side that
## opens onto more floor stays open; everything else is rock.
func holds(cell: Vector2i) -> bool:
	return (_cells.has(cell) and not _rock.has(cell)) or _corridor.has(cell)


## No cell at all, for a question about two rooms nothing joins.
const NO_CELL: Vector2i = Vector2i(-2147483648, -2147483648)


## **The corridor cell `a` opens into on its way to `b`** (`M4-T12`), or
## `NO_CELL`. Matched by corridor rather than by distance: two rooms can face
## each other across a corridor they do not share, and the door that matters is
## the one on the route.
func door_between(a: int, b: int) -> Vector2i:
	var corridors: Dictionary = {}
	for door: Vector4i in _doors:
		if door.z == b:
			corridors[door.w] = true
	for door: Vector4i in _doors:
		if door.z == a and corridors.has(door.w):
			return Vector2i(door.x, door.y)
	return NO_CELL

## **The route that joins `a` to `b`** (ADR-384), or -1 — the corridor
## `door_between` finds its doorway on.
func route_between(a: int, b: int) -> int:
	var corridors: Dictionary = {}
	for door: Vector4i in _doors:
		if door.z == b:
			corridors[door.w] = true
	for door: Vector4i in _doors:
		if door.z == a and corridors.has(door.w):
			return door.w
	return -1

## The corridor cells that open into `node`, sorted.
##
## A wall has to be cut where a corridor arrives and nowhere else — a room whose
## walls ignored its doors would be sealed, and one that opened on every side a
## corridor merely runs past would hand the player routes the graph never
## authorised (ADR-172 Decision 1).
func doors_of(node: int) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for door: Vector4i in _doors:
		if door.z != node:
			continue
		var cell := Vector2i(door.x, door.y)
		if not found.has(cell):
			found.append(cell)
	found.sort()
	return found


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
		var limit: int = HUB_FOOTPRINT if node == _hub else MAX_FOOTPRINT
		var room: int = LATTICE * (2 if node == _hub else 1)
		if span.x > limit or span.y > limit \
				or span.x + 2 > room or span.y + 2 > room:
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
		var crossing: PackedInt32Array = _corridor[cell]
		if crossing.size() > 2:
			stacked += 1
	if stacked > 0:
		found.append(("%d corridor cell(s) carry three or more crossing — two is "
			+ "a bridge and anything more is a junction nobody can build")
			% stacked)

	# **Asked of the realised route, not the candidate routing accepted.**
	# `_dogleg` rewrites a path after `_climbable` has passed it, and it leaves
	# crossing routes alone only because it says so — this is the row that
	# notices the day it stops.
	var stranded := PackedStringArray()
	var sloped_turns := PackedStringArray()
	for route: int in routes():
		var path: Array[Vector2i] = path_of(route)
		var rises: PackedInt32Array = deck_rises(path, over_of(route))
		if rises[0] != 0 or rises[rises.size() - 1] != 0:
			stranded.append("route %d" % route)
		for i: int in path.size():
			if turns(path, i) and rises[i] != rises[i + 1]:
				sloped_turns.append("route %d at %s" % [route, path[i]])
	if not stranded.is_empty():
		found.append(("%s climb to a bridge without room to come back down — "
			+ "the doorway stands above the floor it opens onto, and a step at a "
			+ "threshold is a wall") % ", ".join(stranded))
	if not sloped_turns.is_empty():
		found.append(("%d turn(s) are laid on a slope (%s) — a slab cannot rise "
			+ "along two edges that share a corner, so a turn has to be a landing")
			% [sloped_turns.size(), ", ".join(sloped_turns)])

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
		var crossing: PackedInt32Array = _corridor[cell]
		var names := PackedStringArray()
		for route: int in crossing:
			names.append(str(route))
		parts.append("c%d,%d:%s" % [cell.x, cell.y, "+".join(names)])
	return "%d|%s" % [parts.size(), "|".join(parts)]
