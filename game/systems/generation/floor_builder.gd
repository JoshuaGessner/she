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
## The shipped conventions from `room_set.gd`, matched on purpose.
const WALL_THICK: float = 0.6
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
	var tunnels: int = 0
	for cell: Vector2i in plan.corridor_at():
		builder._corridor(plan, cell)
		tunnels += 1

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

	_slab(Vector3(span.x, WALL_THICK, span.z),
		mid + Vector3(0.0, -WALL_THICK * 0.5, 0.0), STONE[_depth])
	_slab(Vector3(span.x, WALL_THICK, span.z),
		mid + Vector3(0.0, height + WALL_THICK * 0.5, 0.0), STONE[_depth])

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
				PI * 0.25)


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
	var centre: float = edge - WALL_THICK * 0.5 if low \
		else edge + WALL_THICK * 0.5
	_run(rect.position.x * CELL, rect.end.x * CELL, gaps, height,
		func(from: float, to: float) -> void:
			_slab(Vector3(to - from, height, WALL_THICK),
				Vector3((from + to) * 0.5, height * 0.5, centre),
				STONE[_depth]))


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
	var centre: float = edge - WALL_THICK * 0.5 if low \
		else edge + WALL_THICK * 0.5
	_run(rect.position.y * CELL, rect.end.y * CELL, gaps, height,
		func(from: float, to: float) -> void:
			_slab(Vector3(WALL_THICK, height, to - from),
				Vector3(centre, height * 0.5, (from + to) * 0.5),
				STONE[_depth]))


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


func _corridor(plan: FloorPlan, cell: Vector2i) -> void:
	var origin: Vector3 = at(cell)
	var mid: Vector3 = origin + Vector3(CELL * 0.5, 0.0, CELL * 0.5)
	# A bridge carries two routes at different heights, so the crossing one
	# runs above. It is the only vertical the floor has until ledges land.
	var lift: float = CORRIDOR_CEILING if plan.is_bridge(cell) else 0.0
	_slab(Vector3(CELL, WALL_THICK, CELL),
		mid + Vector3(0.0, lift - WALL_THICK * 0.5, 0.0), RUBBLE[_depth])
	_slab(Vector3(CELL, WALL_THICK, CELL),
		mid + Vector3(0.0, lift + CORRIDOR_CEILING + WALL_THICK * 0.5, 0.0),
		RUBBLE[_depth])

	# A side is open where the tunnel continues or a room takes over; walled
	# otherwise. The room's own wall carries the doorway, so a corridor never
	# opens a hole a door did not authorise.
	for step: Vector2i in FloorPlan.STEPS:
		var next: Vector2i = cell + step
		if plan.holds(next):
			continue
		var thick := Vector3(CELL, CORRIDOR_CEILING, WALL_THICK)
		if step.x != 0:
			thick = Vector3(WALL_THICK, CORRIDOR_CEILING, CELL)
		var out := Vector3(step.x, 0.0, step.y) * (CELL * 0.5 + WALL_THICK * 0.5)
		_slab(thick, mid + out + Vector3(0.0, lift + CORRIDOR_CEILING * 0.5, 0.0),
			RUBBLE[_depth])


## One box of world, with collision, in `room_set.gd`'s shape so generated and
## hand-built geometry sit on the same layer and take the same light.
func _slab(size: Vector3, centre: Vector3, colour: Color,
		yaw: float = 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = centre
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
