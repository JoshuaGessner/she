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
## **Floors stay flat.** Stepping them is in `TEC-008` and deliberately not here:
## a step over the 0.49 m jump apex is a wall, and shipping a floor that cannot
## be crossed to find out is the wrong order. Ledges, alcoves and corridor
## dog-legs are the same — named in `TEC-008` §3.3, built next.


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
	}


## Where a cell's near corner sits in metres.
static func at(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL, 0.0, cell.y * CELL)


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

	# One wall per side, cut where a corridor arrives and nowhere else.
	var doors: Array[Vector2i] = plan.doors_of(node)
	_wall_x(rect, doors, height, true)
	_wall_x(rect, doors, height, false)
	_wall_z(rect, doors, height, true)
	_wall_z(rect, doors, height, false)

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


## A wall running along X, on the near (`low`) or far side in Z.
func _wall_x(rect: Rect2i, doors: Array[Vector2i], height: float,
		low: bool) -> void:
	var z: int = rect.position.y - 1 if low else rect.end.y
	var gaps: Array[float] = []
	for cell: Vector2i in doors:
		if cell.y == z:
			gaps.append(cell.x * CELL + CELL * 0.5)
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
func _wall_z(rect: Rect2i, doors: Array[Vector2i], height: float,
		low: bool) -> void:
	var x: int = rect.position.x - 1 if low else rect.end.x
	var gaps: Array[float] = []
	for cell: Vector2i in doors:
		if cell.x == x:
			gaps.append(cell.y * CELL + CELL * 0.5)
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


## Emit wall segments from `start` to `stop`, leaving a `DOOR_WIDTH` hole at
## each gap. A gap wider than the wall it sits in simply removes the wall.
func _run(start: float, stop: float, gaps: Array[float], height: float,
		emit: Callable) -> void:
	var at_pos: float = start
	for gap: float in gaps:
		var opening: float = gap - DOOR_WIDTH * 0.5
		if opening > at_pos:
			emit.call(at_pos, opening)
		at_pos = maxf(at_pos, gap + DOOR_WIDTH * 0.5)
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
		var nearest: int = path.size()
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
		var axis: Vector3 = Vector3.UP.cross(along).normalized()
		var ramp := MeshInstance3D.new()
		var span: float = CELL / cos(pitch) + WALL_THICK + FLOOR_LAP * 2.0
		var size := Vector3(span, WALL_THICK, CELL + FLOOR_LAP * 2.0) \
			if absf(along.x) > 0.5 \
			else Vector3(CELL + FLOOR_LAP * 2.0, WALL_THICK, span)
		_slab(size, mid + Vector3(0.0, height - WALL_THICK * 0.5, 0.0),
			RUBBLE[_depth], 0.0, "ramp", Basis(axis, pitch))
		ramp.free()
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
