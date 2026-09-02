class_name FloorBuilder
extends RefCounted
## `M4-T01` — the plan becomes a place you can stand in (`TEC-008`, ADR-175).
##
## `FloorPlan` decides a floor as integers: which module stands where, which
## cells are corridor, where each corridor opens. This is the half that turns
## those integers into metres, and it **decides nothing** — every position here
## is read from the plan. If this file ever draws a room the plan did not place
## or opens a wall the plan did not door, the guarantees `problems()` makes
## about the topology stop being about the floor the player walks.
##
## ## Why geometry was researched before it was written
##
## Ten generated floors were drawn as plans and looked at first. They were
## legible as diagrams and indistinguishable as places — ten scatters of
## rectangles joined by identical corridors. Against Lynch's five elements
## (*The Image of the City*, 1960) the diagnosis was exact: the floors had
## **paths** and **nodes** and no **edges**, **districts** or **landmarks**, and
## those are the three a player builds a mental map out of. `TEC-008` is that
## review; this is what it asks for.
##
## ## Everything is a multiple of the body
##
## One plan cell is **2.0 m**, derived rather than picked (`TEC-008` §1.1): it
## makes a one-cell corridor 2.9 body-widths across, lands the authored corpus
## on the hand-built rooms' scale, and keeps the largest module a 10 m hall
## rather than a plaza. Wall height, thickness and door width are the values
## `room_set.gd` already ships, because generated and hand-built rooms sharing a
## level and not sharing a scale is the fastest way to make both look wrong.
##
## ## Worked stone to raw cave
##
## `DES-015` reads the disaster backward as you descend and ADR-018 says the
## Dvergar *"kept mining"*. So one parameter — **roughness**, 0 on floor 1 and 1
## on floor 3 — drives corner chamfer and ceiling variance. Floor 1 is
## orthogonal working; floor 3 is what they dug into. That is Lynch's
## **districts** for the price of a lerp, and it is why three floors of an
## expedition are three places rather than three sizes.
##
## ## The three elements the floors were missing
##
## Lynch's diagnosis is answered by four devices (`TEC-008` §3.3), three of which
## are here:
##
## - **Ledges** over great rooms buy **prospect and refuge** (Appleton, 1975) and
##   are the vista rule's delivery mechanism: you see the hall, and what is on
##   it, before you are standing in it.
## - **Alcoves** buy **refuge** and an **edge** — Alexander's *Alcoves*, and the
##   reason a large room stops reading as a box.
## - **Depth as district** is the roughness gradient above.
##
## The fourth, corridor dog-legs for **mystery** (Kaplan & Kaplan, 1989), is a
## routing decision rather than a geometric one and belongs to `FloorPlan`.
##
## **Floors stay flat.** Stepping them is in `TEC-008` and deliberately not here:
## a step over the 0.49 m jump apex is a wall, and shipping a floor that cannot
## be crossed to find out is the wrong order.


## Metres per plan cell. See the class note; changing it rescales every floor.
const CELL: float = 2.0
## Wall thickness. **Thinner than `room_set.gd`'s 0.6 m, and deliberately.**
##
## Generated walls are built *inside* the room's rect so they cannot stand in
## the corridor cell next door. That makes the rect the room's outer bound, so
## every wall costs interior — and at 0.6 m the narrowest module (1 cell, 2.0 m)
## would be left 0.8 m across: narrower than the 0.9 m navmesh agent, so a room
## nothing can enter. At 0.3 m it keeps 1.4 m.
##
## Door width and room scale still match the hand-built rooms, which is where
## the eye reads scale; wall thickness is not something a player sees ⟨tune⟩.
const WALL_THICK: float = 0.3
const DOOR_WIDTH: float = 2.4
## Corridors are cut low so a hall reads as a hall when you step into one.
## `TEC-008` §2.5's hierarchy of open space, at its cheapest ⟨tune⟩.
const CORRIDOR_CEILING: float = 2.6
## Indexed by `RoomModule.Volume`. `CRAWL` is set against the body: it clears
## the 1.15 m crouch and refuses the 1.80 m stand, so it is a mechanical space
## rather than a decorative one ⟨tune⟩.
const CEILINGS: Array[float] = [1.4, 2.4, 4.0, 7.0]
## Its own RNG stream. Not a `DES-015` pipeline step — geometry is the back half
## of step 4 — so it takes an id outside the 1–8 range and cannot collide with
## one (`DES-015`: one stream per stage, never shared).
const STAGE: int = 9
## How far a corner is cut back at full roughness, in metres ⟨tune⟩.
const CHAMFER: float = 1.6
## How far a ceiling may drift from its nominal height at full roughness ⟨tune⟩.
const CEILING_DRIFT: float = 1.0
## How far every floor slab is grown past its own footprint.
##
## Floors are coplanar and meet edge to edge, and Recast voxelizes at 0.15 m —
## a butt joint whose seam does not land on a voxel boundary can rasterise into
## a hairline gap, splitting a room's mesh from the corridor that serves it. The
## symptom is a room the route enters and stops inside, and it is intermittent
## because it depends where each edge falls against the grid. Overlapping the
## slabs removes the joint rather than hoping it aligns.
const FLOOR_LAP: float = 0.4
## How high a crossing corridor rides over the one beneath. Clears the lower
## tunnel's ceiling and its slab, so the two decks never intersect.
const BRIDGE_LIFT: float = CORRIDOR_CEILING + WALL_THICK + 0.4
## Cells of ramp on each approach to a crossing ⟨tune⟩.
##
## **Two, because one is a wall.** `BRIDGE_LIFT` over a single 2.0 m cell is a
## 58° climb, past the 45° the navmesh will bake and far past the 0.49 m the
## player can jump — the first version lifted the crossing cell with no ramp at
## all and left two rooms unreachable, which is what `--build-probe` caught.
## Two cells make it 4.0 m of run for 3.2 m of rise: 39°, and walkable.
const RAMP_CELLS: int = FloorPlan.BRIDGE_CLEARANCE - 1

## How high a ledge stands over the floor of a great room ⟨tune⟩.
##
## Clear of the 1.80 m standing body by enough that the hall reads as two
## levels, and low enough that stepping off is a decision rather than a
## punishment.
const LEDGE_HEIGHT: float = 2.5
## Cells of ramp climbing to a ledge ⟨tune⟩.
##
## **Three**, giving 5.0 m of run for 2.5 m of rise — 26.6°, comfortably inside
## the 45° the navmesh bakes, so the Hunt can follow you up there and a ledge is
## a vantage rather than a safe room (`DES-013`).
##
## Two was tried, to buy a cell of deck back on the shortest walls. 3.0 m of run
## is 39.8°, still under the stated limit and **it does not bake**: five of seven
## ledges went unreachable and five rooms with them, because a ramp Recast
## rejects is not a ramp, it is a slab across a third of the room. The limit
## that matters is the one measured, not the one documented ⟨tune⟩.
const LEDGE_RAMP_CELLS: int = 3
## How far from the wall the ramp's foot touches down, in metres.
##
## **The single most load-bearing number in this device.** Recast erodes the
## walkable surface by the agent radius, 0.45 m, back from every wall. A ramp
## whose foot meets the floor *at* the wall has its entire touch-down inside
## that band, so the deck and its ramp bake as an island with no way on: three
## of four ledges came out that way, with mesh running from 2.5 m down to 0.7 m
## and none at all below it. One clear metre puts the touch-down half a metre
## outside the band ⟨tune⟩.
const LEDGE_FOOT: float = 1.0
## Smallest room, in cells on its short side, that is given an alcove. Below
## this the recess is most of the wall it is cut into.
const ALCOVE_MIN_ROOM: int = 3
## The clear opening an alcove leaves in the wall it is cut into ⟨tune⟩.
##
## Narrower than the cell, so the recess keeps a return on either side and reads
## as a nook rather than as a missing wall.
const ALCOVE_MOUTH: float = 1.5
## An alcove is ducked into, not walked through ⟨tune⟩. Under the 4.0 m hall
## ceiling it is Alexander's *Hierarchy of Open Space* at its cheapest.
const ALCOVE_CEILING: float = 2.2
## Most alcoves any one room may be given ⟨tune⟩.
const ALCOVE_MAX: int = 2
## How far a ledge ramp overshoots the deck it meets, in metres.
##
## Deliberately **under one navmesh voxel** (`cell_size` 0.15): enough that the
## two solids genuinely overlap, so the join check has something to see, and too
## little for Recast to rasterise as a step. The deck must not overhang the ramp
## by any amount at all — see `_ledge`.
const LEDGE_JOIN: float = 0.1

## Grey by depth: dressed stone, then stone going wrong, then rock. Real
## material direction is `ART-001`'s and this is blockout (ADR-046).
const STONE: Array[Color] = [
	Color(0.46, 0.45, 0.44), Color(0.40, 0.38, 0.35), Color(0.33, 0.30, 0.27),
]
const RUBBLE: Array[Color] = [
	Color(0.38, 0.37, 0.36), Color(0.33, 0.31, 0.29), Color(0.27, 0.25, 0.22),
]

var _into: Node3D = null
var _slabs: int = 0
var _roughness: float = 0.0
var _depth: int = 0
var _alcoves_cut: int = 0
var _ledges_raised: int = 0


## Build `plan` under `into`. Returns a census the probe asserts against.
static func build(plan: FloorPlan, graph: MissionGraph, run_seed: int,
		floor_index: int, into: Node3D) -> Dictionary:
	var builder := FloorBuilder.new()
	builder._into = into
	builder._depth = clampi(floor_index, 0, STONE.size() - 1)
	builder._roughness = clampf(float(floor_index) / 2.0, 0.0, 1.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = MissionGraph._mix(
		MissionGraph.stage_seed(run_seed, floor_index) + STAGE)

	var rooms: int = 0
	for node: int in graph.size():
		builder._room(plan, node, rng)
		rooms += 1
	# Corridors are cut per route rather than per cell, because a crossing is
	# a property of the *path*: it has to be ramped up to and down from, and a
	# single cell cannot know that.
	var tunnels: int = 0
	for route: int in plan.routes():
		tunnels += builder._route(plan, route)

	return {
		"rooms": rooms,
		"corridor": tunnels,
		"slabs": builder._slabs,
		"roughness": builder._roughness,
		# Counted because a device that silently stopped being emitted would
		# leave every other row here passing about a floor that had quietly gone
		# back to being boxes and corridors (`TEC-007` §1).
		"alcoves": builder._alcoves_cut,
		"ledges": builder._ledges_raised,
	}


## Where a cell's near corner sits in metres.
static func at(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL, 0.0, cell.y * CELL)


## The basis that tilts a slab so it **rises** toward `along`.
##
## One function because the sign is not obvious and was wrong. `UP.cross(along)`
## is what reads naturally and it slopes the plate the *other* way: measured, a
## 4.0 m run raised 2.5 m put the far end 1.06 m **below** the near one. Every
## ramp in this file was built that way, and nothing noticed for a simple
## reason — the floor the navmesh row bakes has no crossing on it, so the only
## ramps that existed were never asked whether anything could walk up them
## (ADR-178).
static func rise_toward(along: Vector3, rise: float, run: float) -> Basis:
	return Basis(along.cross(Vector3.UP).normalized(), atan2(rise, run))


func _room(plan: FloorPlan, node: int, rng: RandomNumberGenerator) -> void:
	var rect: Rect2i = plan.rect_of(node)
	var module: RoomModule = RoomCatalogue.by_id(plan.module_of(node))
	var nominal: float = CEILINGS[module.volume] if module != null else CEILINGS[2]
	# Drift, not jitter: the ceiling of one room is one number, so the room
	# still reads as a room. Never below the standing body unless the module
	# asked to be a crawl.
	var drift: float = rng.randf_range(-CEILING_DRIFT, CEILING_DRIFT) * _roughness
	# Clamped, not merely asserted. Unclamped, a crawl's drift reaches 0.4 m and
	# the room becomes impassable — a soft-lock geometry invented, that no
	# topology check could see. A crawl stays crouchable; everything else stays
	# standable.
	var floor_of: float = CEILINGS[0] if nominal <= CEILINGS[0] else 2.2
	var height: float = maxf(nominal + drift, floor_of)

	var origin: Vector3 = at(rect.position)
	var span := Vector3(rect.size.x * CELL, 0.0, rect.size.y * CELL)
	var mid := origin + Vector3(span.x * 0.5, 0.0, span.z * 0.5)

	_slab(Vector3(span.x + FLOOR_LAP * 2.0, WALL_THICK, span.z + FLOOR_LAP * 2.0),
		mid + Vector3(0.0, -WALL_THICK * 0.5, 0.0), STONE[_depth], 0.0, "floor")
	_slab(Vector3(span.x, WALL_THICK, span.z),
		mid + Vector3(0.0, height + WALL_THICK * 0.5, 0.0), STONE[_depth],
		0.0, "ceiling")

	# One wall per side, cut where a corridor arrives, where an alcove is
	# recessed, and nowhere else.
	var doors: Array[Vector2i] = plan.doors_of(node)
	var alcoves: Array[Vector2i] = _alcoves(plan, rect, rng)
	_wall_x(rect, doors, alcoves, height, true)
	_wall_x(rect, doors, alcoves, height, false)
	_wall_z(rect, doors, alcoves, height, true)
	_wall_z(rect, doors, alcoves, height, false)
	for cell: Vector2i in alcoves:
		_alcove(rect, cell)

	# Corners cut back as the working gives way to the seam. At roughness 0
	# this emits nothing at all, which is what makes floor 1 read as built.
	if _roughness > 0.0:
		var cut: float = CHAMFER * _roughness
		for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1),
				Vector2(1, 1)]:
			var spot := origin + Vector3(corner.x * span.x, height * 0.5,
				corner.y * span.z)
			_slab(Vector3(cut, height, cut), spot, RUBBLE[_depth],
				PI * 0.25, "chamfer")

	# A great room gets somewhere to see it from before you are in it.
	if module != null and module.volume == RoomModule.Volume.GREAT:
		_ledge(rect, doors, rng)


## Which cells beside `rect` become alcoves (`TEC-008` §3.3.3).
##
## Alexander's *Alcoves*: a large room needs usable edge and a rectangle has
## none. Each recess is cover that breaks a sightline, somewhere to let a patrol
## pass, and a wall line that stops the room reading as a box.
##
## **A candidate must be surrounded by rock on every side but this room's**, and
## that test is doing more work than it looks like. A cell touching a corridor,
## or a second room, would become a hole joining two spaces the graph never
## linked — ADR-172's hazard arriving dressed as decoration, and invisible to
## every topology check because the plan does not know the recess exists.
func _alcoves(plan: FloorPlan, rect: Rect2i,
		rng: RandomNumberGenerator) -> Array[Vector2i]:
	if mini(rect.size.x, rect.size.y) < ALCOVE_MIN_ROOM:
		return []
	var beside: Array[Vector2i] = []
	for x: int in range(rect.position.x, rect.end.x):
		beside.append(Vector2i(x, rect.position.y - 1))
		beside.append(Vector2i(x, rect.end.y))
	for z: int in range(rect.position.y, rect.end.y):
		beside.append(Vector2i(rect.position.x - 1, z))
		beside.append(Vector2i(rect.end.x, z))
	# Sorted before anything picks from it. The order the loops above happen to
	# append in is exactly the kind of accident `TEC-007` §1 forbids a decision
	# from depending on.
	beside.sort()

	var pocket: Array[Vector2i] = []
	for cell: Vector2i in beside:
		if plan.holds(cell):
			continue
		var sealed: bool = true
		for step: Vector2i in FloorPlan.STEPS:
			var side: Vector2i = cell + step
			if not rect.has_point(side) and plan.holds(side):
				sealed = false
				break
		if sealed:
			pocket.append(cell)
	if pocket.is_empty():
		return []

	var chosen: Array[Vector2i] = []
	for i: int in mini(rng.randi_range(1, ALCOVE_MAX), pocket.size()):
		var pick: int = rng.randi_range(0, pocket.size() - 1)
		chosen.append(pocket[pick])
		pocket.remove_at(pick)
	chosen.sort()
	_alcoves_cut += chosen.size()
	return chosen


## The recess itself: floor, a low ceiling, and rock on every side but the mouth.
##
## Walls stand *inside* the alcove cell for ADR-176's reason — built outward
## they would occupy whatever is beyond, and the cell was chosen precisely
## because nothing is.
func _alcove(rect: Rect2i, cell: Vector2i) -> void:
	var mid: Vector3 = at(cell) + Vector3(CELL * 0.5, 0.0, CELL * 0.5)
	_slab(Vector3(CELL + FLOOR_LAP * 2.0, WALL_THICK, CELL + FLOOR_LAP * 2.0),
		mid + Vector3(0.0, -WALL_THICK * 0.5, 0.0), STONE[_depth], 0.0, "floor")
	_slab(Vector3(CELL, WALL_THICK, CELL),
		mid + Vector3(0.0, ALCOVE_CEILING + WALL_THICK * 0.5, 0.0),
		STONE[_depth], 0.0, "ceiling")
	for step: Vector2i in FloorPlan.STEPS:
		if rect.has_point(cell + step):
			continue
		var thick := Vector3(CELL, ALCOVE_CEILING, WALL_THICK)
		if step.x != 0:
			thick = Vector3(WALL_THICK, ALCOVE_CEILING, CELL)
		var out := Vector3(step.x, 0.0, step.y) * (CELL * 0.5 - WALL_THICK * 0.5)
		_slab(thick, mid + out + Vector3(0.0, ALCOVE_CEILING * 0.5, 0.0),
			STONE[_depth], 0.0, "wall")


## The cells of `rect` lying against one of its four walls, in order.
func _strip(rect: Rect2i, side: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	match side:
		0:
			for x: int in range(rect.position.x, rect.end.x):
				cells.append(Vector2i(x, rect.position.y))
		1:
			for x: int in range(rect.position.x, rect.end.x):
				cells.append(Vector2i(x, rect.end.y - 1))
		2:
			for z: int in range(rect.position.y, rect.end.y):
				cells.append(Vector2i(rect.position.x, z))
		_:
			for z: int in range(rect.position.y, rect.end.y):
				cells.append(Vector2i(rect.end.x - 1, z))
	return cells


## Which way is out through the wall `side` runs along.
func _outward(side: int) -> Vector2i:
	match side:
		0: return Vector2i(0, -1)
		1: return Vector2i(0, 1)
		2: return Vector2i(-1, 0)
		_: return Vector2i(1, 0)


## A walkable ledge along one wall of a great room, and the ramp that reaches it
## (`TEC-008` §3.3.1).
##
## This is the delivery mechanism for `DES-015`'s vista rule — *you see the Prize
## before you can reach it* — and Appleton's prospect and refuge in one piece of
## geometry: the ledge is the view out, the wall behind it is the cover. It is
## also ADR-014's *"verticality lives inside rooms"* made concrete, without
## reopening the planar-cell decision.
##
## The wall it runs along must carry **no doorway**, so a ledge can never be
## raised over the threshold a corridor arrives at.
func _ledge(rect: Rect2i, doors: Array[Vector2i],
		rng: RandomNumberGenerator) -> void:
	var sides: Array[int] = []
	for side: int in 4:
		var wall: Array[Vector2i] = _strip(rect, side)
		# Two cells of deck, not one: see `LEDGE_RAMP_CELLS`.
		if wall.size() < LEDGE_RAMP_CELLS + 2:
			continue
		var clear: bool = true
		for cell: Vector2i in wall:
			if doors.has(cell + _outward(side)):
				clear = false
				break
		if clear:
			sides.append(side)
	if sides.is_empty():
		return

	var cells: Array[Vector2i] = _strip(rect,
		sides[rng.randi_range(0, sides.size() - 1)])
	# Which end you climb from is half of what makes two ledges read differently.
	if rng.randi_range(0, 1) == 1:
		cells.reverse()
	var step: Vector2i = cells[1] - cells[0]
	var along := Vector3(step.x, 0.0, step.y)
	var flat: Vector3 = at(cells[0]) + Vector3(CELL * 0.5, 0.0, CELL * 0.5)

	# The ramp: one tilted slab, lengthened by 1/cos so it still covers its
	# cells, exactly as a crossing's approach is built.
	#
	# Distances below are along the strip, measured from the centre of its first
	# cell: the wall at that end stands at −CELL/2, and the deck begins where
	# the ramp reaches full height.
	#
	# **The ramp touches down `LEDGE_FOOT` clear of that wall**, which is the
	# whole of why a ledge is reachable — see the constant. And **the deck must
	# not overhang the ramp by any amount**: lapping it back over the ramp the
	# way flat floors lap each other is self-defeating, because while the two
	# are separate regions Recast treats the deck's leading edge as a border and
	# erodes it by the agent radius, which pushes the deck's walkable area away
	# from the ramp's and guarantees they never merge — which is what made the
	# border. So the surfaces meet flush and the *ramp* overshoots by
	# `LEDGE_JOIN`, under one voxel: the solids overlap for ADR-176's join
	# check, and the protrusion is too small for Recast to read as a step.
	# Downhill the ramp laps freely, because there it buries itself under the
	# room's own floor.
	var foot: float = LEDGE_FOOT - CELL * 0.5
	var crest: float = LEDGE_RAMP_CELLS * CELL - CELL * 0.5
	var run: float = crest - foot
	var pitch: float = atan2(LEDGE_HEIGHT, run)
	var span: float = (run + FLOOR_LAP + LEDGE_JOIN) / cos(pitch)
	var ramp_size := Vector3(span, WALL_THICK, CELL) if absf(along.x) > 0.5 \
		else Vector3(CELL, WALL_THICK, span)
	var ramp_at: float = (foot - FLOOR_LAP + crest + LEDGE_JOIN) * 0.5
	_slab(ramp_size,
		flat + along * ramp_at
			+ Vector3(0.0, LEDGE_HEIGHT * (ramp_at - foot) / run
				- WALL_THICK * 0.5, 0.0),
		RUBBLE[_depth], 0.0, "ledge_ramp",
		rise_toward(along, LEDGE_HEIGHT, run))

	# The deck begins exactly where the ramp reaches its height.
	var deck: int = cells.size() - LEDGE_RAMP_CELLS
	var reach: float = deck * CELL
	var deck_size := Vector3(reach, WALL_THICK, CELL) if absf(along.x) > 0.5 \
		else Vector3(CELL, WALL_THICK, reach)
	_slab(deck_size,
		flat + along * (crest + deck * CELL * 0.5)
			+ Vector3(0.0, LEDGE_HEIGHT - WALL_THICK * 0.5, 0.0),
		STONE[_depth], 0.0, "ledge_floor")
	_ledges_raised += 1


## A wall running along X, on the near (`low`) or far side in Z.
func _wall_x(rect: Rect2i, doors: Array[Vector2i], alcoves: Array[Vector2i],
		height: float, low: bool) -> void:
	var z: int = rect.position.y - 1 if low else rect.end.y
	var gaps: Array[Vector2] = []
	for cell: Vector2i in doors:
		if cell.y == z:
			gaps.append(Vector2(cell.x * CELL + CELL * 0.5, DOOR_WIDTH))
	for cell: Vector2i in alcoves:
		if cell.y == z:
			gaps.append(Vector2(cell.x * CELL + CELL * 0.5, ALCOVE_MOUTH))
	gaps.sort()
	var edge: float = rect.position.y * CELL if low \
		else rect.end.y * CELL
	# Inside the rect, so the wall never stands in the corridor cell beyond it.
	var centre: float = edge + WALL_THICK * 0.5 if low \
		else edge - WALL_THICK * 0.5
	_run(rect.position.x * CELL, rect.end.x * CELL, gaps, height,
		func(from: float, to: float) -> void:
			_slab(Vector3(to - from, height, WALL_THICK),
				Vector3((from + to) * 0.5, height * 0.5, centre),
				STONE[_depth], 0.0, "wall"))


## A wall running along Z, on the near (`low`) or far side in X.
func _wall_z(rect: Rect2i, doors: Array[Vector2i], alcoves: Array[Vector2i],
		height: float, low: bool) -> void:
	var x: int = rect.position.x - 1 if low else rect.end.x
	var gaps: Array[Vector2] = []
	for cell: Vector2i in doors:
		if cell.x == x:
			gaps.append(Vector2(cell.y * CELL + CELL * 0.5, DOOR_WIDTH))
	for cell: Vector2i in alcoves:
		if cell.x == x:
			gaps.append(Vector2(cell.y * CELL + CELL * 0.5, ALCOVE_MOUTH))
	gaps.sort()
	var edge: float = rect.position.x * CELL if low else rect.end.x * CELL
	# Inside the rect, so the wall never stands in the corridor cell beyond it.
	var centre: float = edge + WALL_THICK * 0.5 if low \
		else edge - WALL_THICK * 0.5
	_run(rect.position.y * CELL, rect.end.y * CELL, gaps, height,
		func(from: float, to: float) -> void:
			_slab(Vector3(WALL_THICK, height, to - from),
				Vector3(centre, height * 0.5, (from + to) * 0.5),
				STONE[_depth], 0.0, "wall"))


## Emit wall segments from `start` to `stop`, leaving a hole at each gap. Each
## gap is (centre, width): a doorway is `DOOR_WIDTH`, an alcove mouth narrower.
## A gap wider than the wall it sits in simply removes the wall.
func _run(start: float, stop: float, gaps: Array[Vector2], height: float,
		emit: Callable) -> void:
	var at_pos: float = start
	for gap: Vector2 in gaps:
		var opening: float = gap.x - gap.y * 0.5
		if opening > at_pos:
			emit.call(at_pos, opening)
		at_pos = maxf(at_pos, gap.x + gap.y * 0.5)
	if stop > at_pos:
		emit.call(at_pos, stop)


## Cut one corridor end to end, riding over anything it crosses.
##
## Returns how many cells it laid, so the census counts tunnel and not route.
func _route(plan: FloorPlan, route: int) -> int:
	var path: Array[Vector2i] = plan.path_of(route)
	if path.is_empty():
		return 0
	var over: Array[Vector2i] = plan.over_of(route)

	# Height per cell: full lift where this route crosses another, sloping away
	# over `RAMP_CELLS` on each side so the climb is walkable rather than a step.
	var lift := PackedFloat32Array()
	lift.resize(path.size())
	for i: int in path.size():
		# **Seeded with the ramp's own reach, not with the path's length.**
		# This is "no crossing is near enough to matter", and writing it as
		# `path.size()` was true only while every corridor was longer than a
		# ramp. A two-cell corridor with no bridge anywhere then measured its
		# nearest crossing as 2 and lifted *both its doorways* a third of the
		# way to bridge height — a 1.10 m step against a 0.49 m jump, at the
		# threshold, on 61 of 4780 routes. It survived because the doorway row
		# baked one floor that happened to have no two-cell corridor on it, and
		# it surfaced the moment `LATTICE` tightened and short corridors became
		# common (ADR-180).
		var nearest: int = RAMP_CELLS + 1
		for j: int in path.size():
			if over.has(path[j]):
				nearest = mini(nearest, absi(i - j))
		lift[i] = BRIDGE_LIFT * maxf(0.0,
			float(RAMP_CELLS + 1 - nearest) / float(RAMP_CELLS + 1))

	# A cell whose entry and exit heights differ is a **slope**, not a step.
	# Laying each cell as a flat box at its own height built a staircase with
	# 1.07 m risers — a wall to anything that walks, which is the same defect
	# the unramped crossing had, one iteration smaller.
	for i: int in path.size():
		var before: float = lift[maxi(i - 1, 0)]
		var after: float = lift[mini(i + 1, path.size() - 1)]
		var enters: float = (before + lift[i]) * 0.5
		var leaves: float = (lift[i] + after) * 0.5
		var travel: Vector2i = path[mini(i + 1, path.size() - 1)] \
			- path[maxi(i - 1, 0)]
		_tunnel(plan, path[i], enters, leaves, travel)
	return path.size()


## One cell of corridor, its floor running from `enters` to `leaves`.
func _tunnel(plan: FloorPlan, cell: Vector2i, enters: float, leaves: float,
		travel: Vector2i) -> void:
	var mid: Vector3 = at(cell) + Vector3(CELL * 0.5, 0.0, CELL * 0.5)
	var height: float = (enters + leaves) * 0.5
	var raised: bool = height > 0.01
	var rise: float = leaves - enters
	if absf(rise) < 0.01 or travel == Vector2i.ZERO:
		_slab(Vector3(CELL + FLOOR_LAP * 2.0, WALL_THICK, CELL + FLOOR_LAP * 2.0),
			mid + Vector3(0.0, height - WALL_THICK * 0.5, 0.0), RUBBLE[_depth],
			0.0, "floor")
	else:
		# Tilted about the axis across the direction of travel, and lengthened
		# by 1/cos so the sloped box still covers the whole cell.
		var along := Vector3(travel.x, 0.0, travel.y).normalized()
		var pitch: float = atan2(rise, CELL)
		var span: float = CELL / cos(pitch) + WALL_THICK + FLOOR_LAP * 2.0
		var size := Vector3(span, WALL_THICK, CELL + FLOOR_LAP * 2.0) \
			if absf(along.x) > 0.5 \
			else Vector3(CELL + FLOOR_LAP * 2.0, WALL_THICK, span)
		_slab(size, mid + Vector3(0.0, height - WALL_THICK * 0.5, 0.0),
			RUBBLE[_depth], 0.0, "ramp", rise_toward(along, rise, CELL))
	# A raised deck is open above — you are crossing a void, and being able to
	# see down into it is the point (`DES-015`'s visual-only vertical space).
	if not raised:
		_slab(Vector3(CELL, WALL_THICK, CELL),
			mid + Vector3(0.0, CORRIDOR_CEILING + WALL_THICK * 0.5, 0.0),
			RUBBLE[_depth], 0.0, "ceiling")

	# A side is open where the tunnel continues or a room takes over; walled
	# otherwise. The room's own wall carries the doorway, so a corridor never
	# opens a hole a door did not authorise.
	for step: Vector2i in FloorPlan.STEPS:
		if plan.holds(cell + step):
			continue
		var thick := Vector3(CELL, CORRIDOR_CEILING, WALL_THICK)
		if step.x != 0:
			thick = Vector3(WALL_THICK, CORRIDOR_CEILING, CELL)
		var out := Vector3(step.x, 0.0, step.y) * (CELL * 0.5 + WALL_THICK * 0.5)
		_slab(thick, mid + out + Vector3(0.0, height + CORRIDOR_CEILING * 0.5, 0.0),
			RUBBLE[_depth], 0.0, "wall")


## One box of world, with collision, in `room_set.gd`'s shape so generated and
## hand-built geometry sit on the same layer and take the same light.
func _slab(size: Vector3, centre: Vector3, colour: Color,
		yaw: float = 0.0, role: String = "slab",
		tilt: Basis = Basis()) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = centre
	# Named by what it is, because a probe measuring headroom has to tell a
	# ceiling from a floor — and once corridors ramp, a raised floor sits
	# exactly where the old "thin slab, up high" heuristic looked for ceilings.
	#
	# **Numbered, because Godot throws the name away on a collision.** A second
	# child called `floor` is not renamed to `floor2`; it is renamed to
	# `@MeshInstance3D@37`, losing the role entirely. Every probe filtering by
	# role was therefore reading exactly one slab per floor and reporting it as
	# the whole population.
	node.name = "%s_%d" % [role, _slabs]
	if tilt != Basis():
		node.basis = tilt
	else:
		node.rotation.y = yaw
	node.material_override = material
	var body := StaticBody3D.new()
	body.collision_layer = CollisionLayers.WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	node.add_child(body)
	_into.add_child(node)
	_slabs += 1
