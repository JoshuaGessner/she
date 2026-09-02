class_name AuthoredFloor
extends FloorSource
## The Deep, as a `FloorSource` (`M4-T01`).
##
## Every answer here is one of `RoomSet`'s hand-placed constants, unchanged and
## still documented where it is declared — the reasoning for *why the west
## branch is empty* or *why the Waystone is a fixture* belongs beside the data,
## not beside the accessor that hands it over.
##
## This exists so the generated floor has something to be the other half of.
## `RoomSet` reads the floor under it through a `FloorSource` now, and this is
## what it reads when nobody has given it anything else — so the Deep, and the
## thirty probes that measure it, behave exactly as they did.

## Where the geometry is raised, handed over by `build`.
var _into: Node3D = null


func spawns() -> Array[Vector3]:
	return RoomSet.SPAWNS


func enemy_posts() -> Array[Vector3]:
	return RoomSet.ENEMY_POSTS


func guardian() -> Vector3:
	return RoomSet.GUARDIAN_POST


func shaft() -> Vector3:
	return RoomSet.SHAFT_AT


func hunter() -> Vector3:
	return RoomSet.HUNTER_POST


func fixtures() -> Array:
	return RoomSet.FIXTURES


func filler() -> Array:
	return RoomSet.FILLER


func field() -> AABB:
	return AABB(RoomSet.FIELD_FROM, RoomSet.FIELD_TO - RoomSet.FIELD_FROM)


## Every doorway is listed twice in `DOORS` — once per room it joins — so this
## lights both approaches without knowing which side you are on. That
## duplication was already there to cut the hole from both rooms; it turns out
## to be exactly what "visible from either side" needs.
func door_lights() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for door: Array in RoomSet.DOORS:
		var rect: Array = RoomSet.ROOMS[door[0] as String]
		var offset: float = float(door[2])
		# Inside the room by a little more than the wall is thick, so the lamp
		# is in the room it belongs to rather than buried in the masonry.
		var inset: float = RoomSet.WALL_THICK * 1.5
		var high: float = RoomSet.DOOR_LIGHT_HEIGHT
		match door[1] as String:
			"n": out.append(Vector3(offset, high, float(rect[2]) + inset))
			"s": out.append(Vector3(offset, high, float(rect[3]) - inset))
			"w": out.append(Vector3(float(rect[0]) + inset, high, offset))
			"e": out.append(Vector3(float(rect[1]) - inset, high, offset))
	return out


# ── the Deep's geometry ───────────────────────────────────────────────────
#
# Moved here from `room_set.gd` whole (ADR-183). It was only ever called by
# `_ready`, and it is the half of a floor a `FloorSource` has to be able to
# raise if a generated one is to stand anywhere.


## Raise the Deep: six rooms, their walls cut around their doorways, and one
## silhouette per room so they can be told apart and talked about.
func build(into: Node3D) -> void:
	_into = into
	for name: String in RoomSet.ROOMS:
		_build_room(name)
		_build_landmark(name)




func _slab(size: Vector3, centre: Vector3, colour: Color, yaw: float = 0.0) -> void:
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


## Doorway centres on one side of one room, so a wall can be built around them.
func _gaps(room: String, side: String) -> Array[float]:
	var found: Array[float] = []
	for door: Array in RoomSet.DOORS:
		if door[0] == room and door[1] == side:
			found.append(float(door[2]))
	return found


## One wall run, split around its doorways. Returns nothing; builds in place.
##
## `along` is the axis the wall runs on (x for n/s walls, z for e/w walls), so
## the gap arithmetic is the same for both and only the final vector differs.
func _wall(room: String, side: String, fixed: float, from: float, to: float,
		horizontal: bool) -> void:
	var gaps: Array[float] = _gaps(room, side)
	gaps.sort()
	var cursor: float = from
	var segments: Array = []
	for gap: float in gaps:
		var opening_from: float = gap - RoomSet.DOOR_WIDTH * 0.5
		var opening_to: float = gap + RoomSet.DOOR_WIDTH * 0.5
		if opening_from > cursor:
			segments.append([cursor, opening_from])
		cursor = maxf(cursor, opening_to)
	if cursor < to:
		segments.append([cursor, to])

	for segment: Array in segments:
		var length: float = float(segment[1]) - float(segment[0])
		if length <= 0.01:
			continue
		var middle: float = (float(segment[0]) + float(segment[1])) * 0.5
		var size: Vector3 = (Vector3(length, RoomSet.WALL_HEIGHT, RoomSet.WALL_THICK) if horizontal
			else Vector3(RoomSet.WALL_THICK, RoomSet.WALL_HEIGHT, length))
		var centre: Vector3 = (Vector3(middle, RoomSet.WALL_HEIGHT * 0.5, fixed) if horizontal
			else Vector3(fixed, RoomSet.WALL_HEIGHT * 0.5, middle))
		_slab(size, centre, RoomSet.WALL_COLOUR)


## One thing per room that is not a box, so the rooms can be told apart and
## talked about. Blockout shapes only (ADR-046) — a named production phase with
## a scheduled replacement at `M4-T05`, not a placeholder standing in for a
## system that does not exist.
##
## They are built with `_slab`, so they are **solid**, and that is deliberate
## rather than incidental: a barricade you can walk through is worse than no
## barricade, because it teaches the player that this level's furniture is
## scenery — and then the one piece of cover that does matter reads as scenery
## too. Solid also means they occlude, which is what makes them landmarks at
## all rather than decals.
func _build_landmark(room: String) -> void:
	if not RoomSet.LANDMARKS.has(room):
		return
	var row: Array = RoomSet.LANDMARKS[room]
	var kind: String = row[0]
	var at: Vector3 = row[1] as Vector3
	var marker := Node3D.new()
	marker.name = "landmark_%s" % room
	marker.position = at
	marker.add_to_group(RoomSet.LANDMARK_GROUP)
	_into.add_child(marker)
	match kind:
		"arch":
			# Behind the spawn, framing the way you came in. It exists so the
			# entrance is recognisable from inside the loop — this level is a
			# cycle, and the whole hazard of a cycle is arriving somewhere you
			# have already been without noticing (`DES-015` Layer 1).
			_pillar(at + Vector3(-2.2, 0.0, 0.0), 3.2, 0.5)
			_pillar(at + Vector3(2.2, 0.0, 0.0), 3.2, 0.5)
			_beam(at + Vector3(0.0, 3.2, 0.0), 4.9, 0.5)
		"barricade":
			# `DES-015`'s Retreat, at blockout scale: *"barricades facing the
			# wrong way"*. The safe corridor is the one where somebody already
			# tried to hold a line and failed, which is the cheapest possible
			# way to say something about this place without writing any lore.
			_beam(at + Vector3(0.0, 0.5, 0.0), 3.4, 0.42)
			_beam(at + Vector3(0.3, 1.1, 0.6), 3.0, 0.34)
		"pillar":
			_pillar(at, 3.6, 0.62)
		"well":
			# The junction is the room every route crosses, so it is the room
			# most worth being able to name.
			_ring(at, 1.5, 0.7)
		"altar":
			_slab(Vector3(2.4, 0.9, 2.4), at + Vector3(0.0, 0.45, 0.0), RoomSet.WALL_COLOUR)
		"gate":
			# The way out, framed. Taller and thinner than the entrance arch and
			# with no beam across the top, so the two read as a pair without
			# reading as the same thing — and so nothing crosses the Shaft's
			# light column, which is the one sightline in the level that has to
			# survive from the far side of the floor.
			_pillar(at + Vector3(-2.4, 0.0, 0.0), 3.8, 0.45)
			_pillar(at + Vector3(2.4, 0.0, 0.0), 3.8, 0.45)


func _pillar(at: Vector3, height: float, thick: float) -> void:
	_slab(Vector3(thick, height, thick), at + Vector3(0.0, height * 0.5, 0.0),
		RoomSet.WALL_COLOUR)


func _beam(at: Vector3, length: float, thick: float) -> void:
	_slab(Vector3(length, thick, thick), at + Vector3(0.0, thick * 0.5, 0.0),
		RoomSet.WALL_COLOUR)


## A low circular kerb, approximated with eight segments — round enough to read
## as a well from across the room, cheap enough to be blockout.
##
## Each segment is turned to lie **along** the circle. The first version left
## them axis-aligned, which puts a long box at the +X point of a circle whose
## tangent there runs along Z — so the eight segments pointed outward and the
## well was an eight-spoked asterisk. Only visible by looking at it: nothing
## about the arithmetic is wrong, the shapes were simply facing the wrong way.
func _ring(at: Vector3, radius: float, height: float) -> void:
	var segments: int = 8
	for index: int in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		var offset := Vector3(cos(angle) * radius, height * 0.5, sin(angle) * radius)
		# A little longer than the chord, so neighbours overlap at the corners
		# instead of leaving eight gaps you can see the floor through.
		var chord: float = TAU * radius / float(segments) * 1.25
		_slab(Vector3(chord, height, 0.34), at + offset, RoomSet.WALL_COLOUR, -angle)


func _build_room(name: String) -> void:
	var rect: Array = RoomSet.ROOMS[name]
	var min_x: float = float(rect[0])
	var max_x: float = float(rect[1])
	var min_z: float = float(rect[2])
	var max_z: float = float(rect[3])

	_slab(Vector3(max_x - min_x, 0.5, max_z - min_z),
		Vector3((min_x + max_x) * 0.5, -0.25, (min_z + max_z) * 0.5), RoomSet.FLOOR_COLOUR)

	_wall(name, "n", min_z, min_x, max_x, true)
	_wall(name, "s", max_z, min_x, max_x, true)
	_wall(name, "w", min_x, min_z, max_z, false)
	_wall(name, "e", max_x, min_z, max_z, false)
