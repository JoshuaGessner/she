class_name DelvingsKit
extends RefCounted
## `M4-T10` — the delivered architecture, laid over the boxes we already build
## (ADR-263, `ART-006`).
##
## ## The surface is clad; the solid is untouched
##
## Every wall, floor and ceiling in this game is a box with a `BoxShape3D` in
## it, and **the navmesh bakes from those shapes, not from anything rendered**.
## So this file never makes a collider and never changes one. It hangs kit
## modules on the outside of boxes that already exist, and a floor that baked
## before it bakes identically after.
##
## That is not timidity, it is the cheaper *and* better answer. Tiling 2 m
## modules as collision would replace one room-length solid with ten, putting a
## butt joint every two metres into the exact rasteriser that `FLOOR_LAP` exists
## to keep joints out of — and this project has lost a floor to Recast three
## times already (ADR-180, ADR-200, ADR-213). Fewer, longer colliders are a
## *better* navmesh input than a grid of small ones. The kit is what you see;
## the slab is what you stand on.
##
## ## Modules are scaled to fit, and that costs nothing here
##
## A kit normally forbids scaling because it stretches the texture. **These
## modules have no texture and no UVs at all** (`export_texcoords=False` in
## `build_delvings.py`): surface detail arrives from the ink pass in world space
## (ADR-259), so it does not stretch when a module does. All that changes is the
## modelled course height — and courses varying from room to room is something
## a mason does, not a bug.
##
## That is what lets three panel heights clad a generator whose ceilings drift
## continuously (`FloorBuilder.CEILING_DRIFT`), and it is why the Lair's 9 m
## camp wall needs no design decision: it is the 7 m panel at 1.29, with the
## bigger courses a 9 m wall ought to have.
##
## ## What it will not do
##
## A panel squeezed past `SQUEEZE_MIN` stops reading as masonry and starts
## reading as vertical slivers, so it is not laid at all and the box's own stone
## is the surface. The only runs that short the builder makes are the returns
## either side of an alcove mouth, where plain cut stone is the right answer
## anyway.

## The four things this kit knows how to cover. A caller names one of these for
## a box it has already built; everything else about the box is read off it.
const FLOOR: StringName = &"floor"
const CEILING: StringName = &"ceiling"
const WALL: StringName = &"wall"
const CHAMFER: StringName = &"chamfer"


## Where the modules live. One folder, one naming convention, checked by
## `art_probe.gd`.
const SHELF: String = "res://art/environment/%s.glb"

## ADR-054's grid. Every module in the kit is this wide, and `FloorBuilder.CELL`
## is the same number for the same reason.
const TILE: float = 2.0
## How thick a wall panel is modelled. Matches `FloorBuilder.WALL_THICK`
## exactly, which is not a coincidence — `ART-006` was written from it.
const PANEL_DEEP: float = 0.3
## Flagstones over their bed.
const FLAG_DEEP: float = 0.06
## Slab, planks and crossbeams together.
const BEAM_DEEP: float = 0.38
## The doorway module, which is **two cells wide**: a 2.4 m opening cannot be
## jambed inside one 2 m cell, so the kit spends a cell either side on it.
const FRAME_WIDE: float = 4.0
const FRAME_HIGH: float = 4.0

## How far cladding stands out from the box it is laid on.
##
## Coplanar faces z-fight, and every module in this kit is exactly as thick as
## the slab it covers — so one of the two has to move. A centimetre is under a
## tenth of a navmesh voxel and a fiftieth of the step height, which is to say
## it is nothing to walk on and everything to look at.
const PROUD: float = 0.01

## The narrowest a 2 m panel may be squeezed and still read as coursed stone.
##
## Below this the blocks are thinner than they are tall and the wall reads as
## palings. The number is set at the run it has to exclude: an alcove mouth
## leaves 0.25 m returns either side, and two alcoves side by side leave 0.5 m
## between them — 0.125 and 0.25 squeeze, both out; a 0.6 m chamfer face is 0.3,
## in ⟨tune⟩.
const SQUEEZE_MIN: float = 0.3

## The panel heights the kit was delivered at. Everything else is one of these
## scaled — see the class note.
const PANEL_HIGH: Array[float] = [2.6, 4.0, 7.0]
## Panels by height, with their variants. Only the 4 m course has two, so only
## rooms near that height get alternation; the others repeat, which is what a
## quarried wall does.
const PANELS: Array = [
	[&"delvings_wall_2x26"],
	[&"delvings_wall_2x40", &"delvings_wall_2x40_b"],
	[&"delvings_wall_2x70"],
]
const FLAGS: Array = [&"delvings_floor_2x2", &"delvings_floor_2x2_b"]
const BEAMS: StringName = &"delvings_ceiling_2x2"
const FRAME: StringName = &"delvings_doorway"

## Every module the kit ships, for `--kit-probe` to load and measure. Listed
## rather than globbed so that a module **disappearing** is a failure and not a
## smaller number nobody reads.
const DELIVERED: Array[StringName] = [
	&"delvings_wall_2x26", &"delvings_wall_2x40", &"delvings_wall_2x40_b",
	&"delvings_wall_2x70", &"delvings_doorway", &"delvings_corner_inner",
	&"delvings_corner_chamfer", &"delvings_floor_2x2", &"delvings_floor_2x2_b",
	&"delvings_ceiling_2x2", &"delvings_alcove", &"delvings_ledge_edge",
	&"delvings_ramp_2x25", &"delvings_pillar",
]

## The render mesh of each module, pulled out of its `.glb` once.
##
## **The mesh, not the scene.** Instancing the `PackedScene` would also build
## the `-colonly` proxies the kit carries, and those are the one thing this file
## must never add: they would double every solid in the floor and hand Recast a
## second, finer-grained copy of the world to disagree with itself about.
static var _shelf: Dictionary[StringName, Mesh] = {}


## The render mesh of one module, cached. Null if the module is missing, which
## `--kit-probe` turns into a failure rather than a hole in a wall.
##
## **Every surface, merged into one mesh.** Godot's glTF importer splits a
## multi-material mesh into one `MeshInstance3D` per material, so a module
## arrives as three nodes — `_dark_stone`, `_pale_stone`, `_stone` — and taking
## the first of them takes a flagstone's bed and leaves the flags behind. It is
## also what the placement wants: one node per piece rather than one per
## material, on a floor that lays nine thousand of them.
static func mesh_of(module: StringName) -> Mesh:
	if _shelf.has(module):
		return _shelf[module]
	var packed := load(SHELF % module) as PackedScene
	var found: Mesh = null
	if packed == null:
		push_error("[kit] no module `%s` in %s" % [module, SHELF % module])
	else:
		var made: Node = packed.instantiate()
		var built := ArrayMesh.new()
		for node: Node in made.find_children("*", "MeshInstance3D", true, false):
			var instance := node as MeshInstance3D
			if instance.mesh == null:
				continue
			# Merged without transforming anything, because `ART-004` requires
			# applied transforms and `art_probe` fails a module that ships
			# without them — so a node standing anywhere but its own origin is
			# a delivery fault, and quietly baking it in would hide one.
			if not instance.transform.is_equal_approx(Transform3D()):
				push_error("[kit] `%s` in `%s` has an unapplied transform"
					% [node.name, module])
				continue
			for i: int in instance.mesh.get_surface_count():
				built.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,
					instance.mesh.surface_get_arrays(i))
				built.surface_set_material(built.get_surface_count() - 1,
					instance.mesh.surface_get_material(i))
		made.free()
		if built.get_surface_count() > 0:
			found = built
		else:
			push_error("[kit] module `%s` has no render mesh" % module)
	_shelf[module] = found
	return found


## Pull a wall box back behind the masonry that stands in front of it.
##
## Its own function because a **room's** wall is clad by its caller rather than
## by `clad` — only a whole wall line knows where its doorways are — and that
## path still has to move the box. When it did not, the core and the panel were
## both 0.3 m thick on the same centre, which is the same plane twice, and every
## room wall in the Delvings shimmered.
##
## The box stays: a centimetre behind the stone it is what seals the joint where
## two runs meet, so a tiling fault can show a dark course and never a hole
## through the world.
static func recess(node: MeshInstance3D) -> void:
	var box := node.mesh as BoxMesh
	if box == null:
		return
	if box.size.x >= box.size.z:
		box.size.z -= PROUD * 2.0
	else:
		box.size.x -= PROUD * 2.0


## Lay the kit over one solid box, in the box's own frame.
##
## **Nothing here makes or moves a collider.** The box stays the solid; this
## decides what is drawn on it, and the most it does to the box is pull a
## rendered face in by `PROUD` so the masonry in front of it has somewhere to
## stand without z-fighting.
##
## Read off the box's own `BoxMesh` rather than off a size passed in, because
## the rendered size and the collider's are **not always the same number** — a
## flat floor's solid laps its neighbours by `FloorBuilder.FLOOR_LAP` and its
## surface deliberately does not, and paving that lap would put flagstones
## inside the next room along.
static func clad(node: MeshInstance3D, role: StringName) -> void:
	var box := node.mesh as BoxMesh
	if box == null:
		push_error("[kit] `%s` has no BoxMesh to be clad" % node.name)
		return
	var size: Vector3 = box.size
	match role:
		FLOOR:
			flagstones(node, Vector3(0.0, size.y * 0.5 + PROUD, 0.0),
				Vector2(size.x, size.z))
		CEILING:
			# **The one box that stops being drawn.** A ceiling module is
			# 0.38 m of crossbeam, plank and slab against a 0.3 m solid, so any
			# overlap at all hides the carpentry inside the box and there is no
			# offset that leaves both visible. `layers` rather than `visible`,
			# because `visible` would take the cladding down with it.
			node.layers = 0
			beams(node, Vector3(0.0, size.y * 0.5, 0.0),
				Vector2(size.x, size.z))
		WALL:
			var along_x: bool = size.x >= size.z
			var length: float = size.x if along_x else size.z
			var deep: float = size.z if along_x else size.x
			if masonry(node, Vector3(0.0, -size.y * 0.5, 0.0),
					0.0 if along_x else PI * 0.5, length, size.y, deep) == 0:
				return
			recess(node)
		CHAMFER:
			# A cut corner shows **one** diagonal face and buries the other
			# three in the rock it was cut from. The caller spends the square's
			# free yaw on making that face local +Z, so this does not have to
			# know which corner it is standing on.
			if masonry(node, Vector3(0.0, -size.y * 0.5,
					size.z * 0.5 - PANEL_DEEP * 0.5), 0.0, size.x, size.y) == 0:
				return
			recess(node)
		_:
			push_error("[kit] nothing is clad as `%s`" % role)


## Flagstones over a floor, in `into`'s own frame.
##
## `at` is the middle of the **walking surface** the flags are to finish flush
## with, and `span` is the footprint they cover. Laid in `into`'s frame rather
## than the world's, so a tilted ramp's flags tilt with it and a corridor that
## climbs is paved rather than painted.
static func flagstones(into: Node3D, at: Vector3, span: Vector2) -> void:
	if span.x <= 0.0 or span.y <= 0.0:
		return
	var across: int = maxi(1, roundi(span.x / TILE))
	var down: int = maxi(1, roundi(span.y / TILE))
	var squeeze := Vector2(span.x / (float(across) * TILE),
		span.y / (float(down) * TILE))
	for i: int in across:
		for j: int in down:
			var spot: Vector3 = at + Vector3(
				-span.x * 0.5 + (float(i) + 0.5) * span.x / float(across),
				-FLAG_DEEP,
				-span.y * 0.5 + (float(j) + 0.5) * span.y / float(down))
			# Quarter turns, because two flag patterns over a ten-metre room
			# still tile visibly and the turn is free. Ceilings deliberately do
			# not get this: a beam that changes direction every two metres is a
			# ruin, not a roof.
			var turn: int = _draw(spot, 4)
			var fit := Vector3(squeeze.x, 1.0, squeeze.y) if turn % 2 == 0 \
				else Vector3(squeeze.y, 1.0, squeeze.x)
			_piece(into, _pick(FLAGS, spot), spot, PI * 0.5 * float(turn), fit)


## A beamed ceiling whose slab finishes at `at.y`, covering `span`.
##
## The module hangs below that line rather than sitting above it, so the 8 cm of
## crossbeam that drops under the collision plane is the whole of what a head
## has to clear — which the crawl module's 1.4 m still does.
static func beams(into: Node3D, at: Vector3, span: Vector2) -> void:
	if span.x <= 0.0 or span.y <= 0.0:
		return
	var across: int = maxi(1, roundi(span.x / TILE))
	var down: int = maxi(1, roundi(span.y / TILE))
	var squeeze := Vector3(span.x / (float(across) * TILE), 1.0,
		span.y / (float(down) * TILE))
	for i: int in across:
		for j: int in down:
			var spot: Vector3 = at + Vector3(
				-span.x * 0.5 + (float(i) + 0.5) * span.x / float(across),
				-BEAM_DEEP,
				-span.y * 0.5 + (float(j) + 0.5) * span.y / float(down))
			_piece(into, BEAMS, spot, 0.0, squeeze)


## Face `length` metres of wall, `height` tall, its base centred on `at` and
## running along local X once turned by `yaw`.
##
## `deep` is the solid's own thickness: at a panel's thickness the masonry is
## the wall, and beyond it the panel is laid against each face and the solid
## fills between — which is the Lair's 0.8 m rampart and the Chamber's 0.6 m.
##
## Returns how many panels were laid, so a caller can tell "nothing fits here"
## from "nothing was asked for".
static func masonry(into: Node3D, at: Vector3, yaw: float, length: float,
		height: float, deep: float = PANEL_DEEP) -> int:
	if length <= 0.0 or height <= 0.0:
		return 0
	var count: int = maxi(1, roundi(length / TILE))
	var squeeze: float = length / (float(count) * TILE)
	if squeeze < SQUEEZE_MIN:
		return 0
	var step: int = _nearest(height)
	var lift: float = height / PANEL_HIGH[step]
	var rows: Array[float] = [0.0]
	if deep > PANEL_DEEP + 0.05:
		rows = [-(deep - PANEL_DEEP) * 0.5, (deep - PANEL_DEEP) * 0.5]
	var turn := Basis(Vector3.UP, yaw)
	var laid: int = 0
	for i: int in count:
		var slide: float = -length * 0.5 \
			+ (float(i) + 0.5) * length / float(count)
		for row: float in rows:
			var spot: Vector3 = at + turn * Vector3(slide, 0.0, row)
			_piece(into, _pick(PANELS[step], spot), spot, yaw,
				Vector3(squeeze, lift, 1.0))
			laid += 1
	return laid


## Jambs and a lintel around an opening, its base centred on `at`.
##
## **Never scaled.** A door is a door whatever the wall around it is doing, and
## scaling this module vertically with its wall would shrink the opening with
## it — at the 2.2 m minimum room height that is a 1.2 m hole, which is to say a
## wall. Where the wall is lower than the frame, the frame's head stands above
## the ceiling and is hidden by it.
static func doorway(into: Node3D, at: Vector3, yaw: float) -> void:
	_piece(into, FRAME, at, yaw, Vector3.ONE)


## Which panel height is the least stretch for `height`.
##
## Compared as a ratio rather than a difference: 5.0 m is 1.0 m from the 4 m
## panel and 2.0 m from the 7 m one, but stretching by a quarter and squashing
## by a third are not the same insult, and the eye reads the ratio.
static func _nearest(height: float) -> int:
	var best: int = 0
	var closest: float = INF
	for i: int in PANEL_HIGH.size():
		var off: float = absf(log(maxf(height, 0.01) / PANEL_HIGH[i]))
		if off < closest:
			closest = off
			best = i
	return best


## One module, placed.
static func _piece(into: Node3D, module: StringName, at: Vector3, yaw: float,
		fit: Vector3) -> void:
	var shape: Mesh = mesh_of(module)
	if shape == null:
		return
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.transform = Transform3D(
		Basis(Vector3.UP, yaw) * Basis.from_scale(fit), at)
	into.add_child(node)


## Which of `options` stands here.
##
## **From the position, not from an RNG.** Every peer builds this floor from the
## same seed and `TEC-004` says they must agree about where a wall is; a stream
## shared with the builder would put the choice at the mercy of the order slabs
## happen to be laid in, which is exactly the accident `TEC-007` §1 forbids a
## decision from depending on.
static func _pick(options: Array, at: Vector3) -> StringName:
	if options.size() == 1:
		return options[0]
	return options[_draw(at, options.size())]


## A stable number in `0..sides-1` for a spot in the world, to a centimetre.
static func _draw(at: Vector3, sides: int) -> int:
	var mixed: int = roundi(at.x * 100.0) * 73856093 \
		^ roundi(at.y * 100.0) * 19349663 \
		^ roundi(at.z * 100.0) * 83492791
	return posmod(mixed, sides)
