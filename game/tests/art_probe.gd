extends SceneTree

## **Every delivered asset, measured against `ART-004`** (`M4-T10`).
##
## `ART-004` is five pages of specification — units, orientation, pivots, poly
## budgets, collision suffixes, vertex colours *"mandatory from Phase 1"*, hard
## edges *"art-critical"*, and a scale rule `ART-005` calls **"a visual bug
## rather than a tidiness issue"**. Until this file, **nothing in the build read
## a single line of it.** The whole spec was a document that assets were
## supposed to have been authored against, verified by looking.
##
## That was survivable while the library was one asset authored by hand against
## the spec. It stops being survivable the moment a **purchased kit** arrives,
## because a kit fails most of these silently: no vertex colours, everything
## smooth-shaded, transforms unapplied, and a module width that does not tile.
## None of those look wrong in isolation. All of them are expensive to find
## later and cheap to find here.
##
## ## Why a ceiling rather than a range
##
## `ART-004`'s poly table reads as a range, and it says in the same breath that
## the numbers are *"generous rather than tight — the target is readable, not
## cheap"*. So the ceiling is the rule and the floor is not: `humanoid_rig.glb`
## is 2,224 triangles against a 4,000–10,000 "player classes" row, and failing
## it for being *economical* would be a check nobody trusts by its third run.
##
## ## What this does not check
##
## The rig's own sockets, height and eye line are `rig_probe.gd`'s, and stay
## there — two validators for one rig is the duplicate ADR-064 bans, and they
## would disagree the first time either moved. This asks only what is true of
## **every** asset.

## The category is the folder, not a filename prefix.
##
## `ART-004` says both — a `chr_huskarl.glb` naming row and a *"drop .glb files
## into `game/art/<category>/`"* delivery line — and the one asset that exists
## followed the second. One of them had to go, and the folder is the one the
## engine, `check_project.py` and `TEC-002` already agree on.
const CATEGORIES: Dictionary = {
	"characters": 10000, "enemies": 6000, "heroes": 40000,
	"environment": 3000, "props": 3000, "weapons": 800,
}

## Categories whose forms are cut rather than grown, and which therefore owe
## the outline pass some hard edges (`ART-005`).
const CUT: Array[String] = ["environment", "props", "weapons"]

## Categories that are placed in a room and stood on.
const PLACED: Array[String] = ["environment", "props"]

## ADR-054's modular grid. A wall that is not a multiple of this does not tile,
## and no amount of work in Blender makes it tile cheaply.
const GRID: float = 2.0
const GRID_TOLERANCE: float = 0.02

## A metre is a metre. These bracket the two import errors that actually
## happen — centimetres read as metres (100x) and inches read as metres
## (39x) — without having an opinion about any particular asset's size.
const SMALLEST: float = 0.02
const LARGEST: float = 120.0

## How far a placed asset's base may sit off its own origin. `ART-004` puts
## prop pivots at **base centre**; an asset pivoted at its middle sinks halfway
## into the floor wherever the generator puts it.
const PIVOT_TOLERANCE: float = 0.02

var _failures: int = 0


func _check(ok: bool, label: String, detail: String = "") -> void:
	print("  %s %s%s" % ["ok  " if ok else "FAIL", label,
		"   " + detail if detail != "" else ""])
	if not ok:
		_failures += 1


func _initialize() -> void:
	var found := PackedStringArray()
	_walk("res://art", found)
	print("[art] %d model(s) under res://art" % found.size())

	# **An empty census is not a passing census** (ADR-099). Every export
	# between ADR-095 and `M2-T09` verified nothing at all because the thing
	# doing the verifying had been stranded, and reported success throughout.
	_check(found.size() > 0, "there is at least one model to check")

	for path: String in found:
		print("\n[art] ── %s" % path)
		_measure(path)

	print("\n%d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _measure(path: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	_check(packed != null, "loads as a scene")
	if packed == null:
		return
	var root: Node = packed.instantiate()

	# ── where it lives says what it is ────────────────────────────────────
	var category: String = path.get_base_dir().get_file()
	_check(CATEGORIES.has(category),
		"sits in a category folder", "found '%s', expected one of %s"
			% [category, ", ".join(CATEGORIES.keys())])
	if not CATEGORIES.has(category):
		root.free()
		return

	# ── transforms applied ────────────────────────────────────────────────
	#
	# The one failure a purchased kit brings in every time, and the one
	# `ART-005` upgraded from tidiness to a visual bug: hatching is projected
	# triplanar in **world space at a fixed density**, so a mesh carrying a
	# scale on its node gets the wrong hatch density and reads as the wrong
	# size even when its bounds are right.
	var scaled := PackedStringArray()
	for node: Node in root.find_children("*", "Node3D", true, false):
		var spatial := node as Node3D
		var size: Vector3 = spatial.transform.basis.get_scale()
		if absf(size.x - 1.0) > 0.001 or absf(size.y - 1.0) > 0.001 \
				or absf(size.z - 1.0) > 0.001:
			scaled.append("%s %.3v" % [spatial.name, size])
	_check(scaled.is_empty(), "transforms applied, no inherited scale",
		", ".join(scaled))

	# ── the geometry itself ───────────────────────────────────────────────
	var bounds := AABB()
	var started: bool = false
	var tris: int = 0
	var uncoloured: int = 0
	var surfaces: int = 0
	var split: bool = false
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		if mesh == null:
			continue
		var box: AABB = _world_of(instance, root) * mesh.get_aabb()
		bounds = box if not started else bounds.merge(box)
		started = true
		for surface: int in range(mesh.get_surface_count()):
			surfaces += 1
			var arrays: Array = mesh.surface_get_arrays(surface)
			var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			tris += (index.size() / 3) if index.size() > 0 else (verts.size() / 3)
			if arrays[Mesh.ARRAY_COLOR] == null:
				uncoloured += 1
			split = split or _has_split_normals(arrays)

	_check(started, "contains at least one mesh")
	if not started:
		root.free()
		return

	print("  .... %d surface(s), %d triangle(s), %.3f x %.3f x %.3f m"
		% [surfaces, tris, bounds.size.x, bounds.size.y, bounds.size.z])

	# ── scale ─────────────────────────────────────────────────────────────
	var longest: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	_check(longest >= SMALLEST and longest <= LARGEST,
		"1 unit is 1 metre", "longest side %.3f m" % longest)

	# ── poly ceiling ──────────────────────────────────────────────────────
	var ceiling: int = int(CATEGORIES[category])
	_check(tris <= ceiling, "within the %s budget of %d triangles"
		% [category, ceiling], "%d" % tris)

	# ── vertex colours ────────────────────────────────────────────────────
	#
	# ADR-051 settled what they carry: R outline weight, G hatch density bias,
	# B ink ID. Blockout may ship the flat default and refine later, but the
	# channels have to **exist** — `ART-004` is explicit that retrofitting them
	# across a finished library is miserable, and it is right.
	_check(uncoloured == 0, "every surface carries vertex colours",
		"%d of %d without" % [uncoloured, surfaces])

	# ── hard edges ────────────────────────────────────────────────────────
	if CUT.has(category):
		_check(split, "has split normals for the outline pass to find",
			"every surface is smooth-shaded, so interior lines will be weak "
				+ "or missing")

	# ── the grid, and standing on the floor ───────────────────────────────
	if PLACED.has(category):
		var base: float = bounds.position.y
		_check(absf(base) <= PIVOT_TOLERANCE, "pivoted at its base",
			"base sits %.3f m off the origin" % base)
		var shapes: Array[Node] = root.find_children(
			"*", "CollisionShape3D", true, false)
		_check(not shapes.is_empty(), "carries collision",
			"no -col / -colonly / -convcolonly node survived import")

	if category == "environment":
		for axis: String in ["x", "z"]:
			var span: float = bounds.size.x if axis == "x" else bounds.size.z
			_check(_tiles(span), "tiles on the %.0f m grid in %s"
				% [GRID, axis], "%.3f m" % span)

	root.free()


## On the grid, or small enough not to be a tiling piece at all. A 2 m wall and
## a 4 m floor tile; a 0.6 m pillar is placed rather than tiled and has no
## business being padded out to 2 m to satisfy a check.
static func _tiles(span: float) -> bool:
	if span < GRID - GRID_TOLERANCE:
		return true
	var steps: float = span / GRID
	return absf(steps - roundf(steps)) * GRID <= GRID_TOLERANCE


## Whether any one position carries more than one normal, which is what a hard
## edge is once it has been through glTF.
static func _has_split_normals(arrays: Array) -> bool:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	if normals.size() != verts.size() or verts.is_empty():
		return false
	var seen: Dictionary = {}
	for v: int in range(verts.size()):
		var key := Vector3i(roundi(verts[v].x * 1000.0),
			roundi(verts[v].y * 1000.0), roundi(verts[v].z * 1000.0))
		if seen.has(key):
			if (seen[key] as Vector3).distance_to(normals[v]) > 0.01:
				return true
		else:
			seen[key] = normals[v]
	return false


func _walk(dir: String, out: PackedStringArray) -> void:
	var at := DirAccess.open(dir)
	if at == null:
		return
	for name: String in at.get_directories():
		_walk(dir.path_join(name), out)
	for name: String in at.get_files():
		if name.get_extension().to_lower() in ["glb", "gltf"]:
			out.append(dir.path_join(name))


## Transform of `node` relative to `root`, accumulated by hand — the same trap
## `rig_probe.gd` carries a note about. `global_transform` asserts the node is
## in the tree, and during `_initialize()` it is not: it returns identity and
## logs an error, and the measurement can come out right anyway, which is the
## worst kind of passing test.
static func _world_of(node: Node3D, root: Node) -> Transform3D:
	var accumulated := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		var spatial := current as Node3D
		if spatial != null:
			accumulated = spatial.transform * accumulated
		current = current.get_parent()
	return accumulated
