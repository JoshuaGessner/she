class_name CampDressing
extends RefCounted

## **The camp, lived in** (ADR-287). `DES-014`'s target is Diablo's Rogue
## Encampment — *"tiny, dense, warm, and unforgettable"* — and its layout is
## four personal campsites ringed around the Lodge's fire. The Bound who will
## live in them are not built yet (absent, not stubbed, ADR-064), so what is
## built is what makes a place read as lived in before anyone speaks: a tent
## and a bedroll on every plot, gear left by the door of each, a banner moving
## in the wind, rock instead of brick, and boulders breaking the skyline.
##
## Every piece is built in code from boxes, quads and displaced spheres, on
## purpose: these are the shapes `ART-005`'s woodcut reads cleanest, and none
## of them is a delivered model that `ART-004` would need to measure.

const CLIFF: Shader = preload("res://art/shaders/cliff.gdshader")
const CLOTH: Shader = preload("res://art/shaders/cloth.gdshader")

## The four plots (`DES-014`): position, which way the tent opens (toward the
## fire), and its canvas. Muted dyes — ochre, rust, moss, slate — because
## `ART-005` keeps saturated colour for treasure.
const PLOTS: Array = [
	[Vector3(-6.4, 0.0, 0.2), Color(0.42, 0.33, 0.20)],
	[Vector3(6.6, 0.0, 1.4), Color(0.40, 0.22, 0.16)],
	[Vector3(-5.6, 0.0, 6.6), Color(0.26, 0.30, 0.22)],
	[Vector3(5.8, 0.0, 6.8), Color(0.24, 0.27, 0.32)],
]


static func cliff_material() -> ShaderMaterial:
	var stone := ShaderMaterial.new()
	stone.shader = CLIFF
	return stone


static func _material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 1.0
	return m


static func _box(into: Node3D, size: Vector3, at: Vector3, material: Material,
		turn: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	node.mesh = box
	node.material_override = material
	node.position = at
	node.rotation = turn
	into.add_child(node)
	return node


static func _solid(into: Node3D, shape: Shape3D, at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = CollisionLayers.WORLD
	body.collision_mask = 0
	var holder := CollisionShape3D.new()
	holder.shape = shape
	body.add_child(holder)
	body.position = at
	into.add_child(body)


## A rough rock: a sphere whose every vertex is pushed in or out by a seeded
## amount, flat-shaded so its facets catch the fire.
static func boulder(rng: RandomNumberGenerator, radius: float) -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 9
	sphere.rings = 6
	var arrays: Array = sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var pushed: Dictionary = {}
	for i: int in verts.size():
		var key := Vector3i((verts[i] * 1000.0).round())
		if not pushed.has(key):
			pushed[key] = rng.randf_range(0.72, 1.18)
		verts[i] = verts[i] * float(pushed[key])
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i: int in index.size():
		tool.add_vertex(verts[index[i]])
	tool.generate_normals()
	return tool.commit()


## Boulders at the foot of the walls and along their tops, so the camp is a
## hollow in rock and the line against the sky is broken.
static func rocks(into: Node3D, half_wide: float, north: float, south: float,
		high: float, keep_clear: Array[Vector3]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xC1F7
	var stone := cliff_material()
	var spots: Array = []
	for i: int in 9:
		var z: float = lerpf(north + 3.0, south - 1.5, float(i) / 8.0)
		spots.append([Vector3(-half_wide + 0.6, 0.0, z), 0.6, 1.3, true])
		spots.append([Vector3(half_wide - 0.6, 0.0, z), 0.6, 1.3, true])
	for i: int in 7:
		var x: float = lerpf(-half_wide + 1.5, half_wide - 1.5, float(i) / 6.0)
		spots.append([Vector3(x, 0.0, south - 0.6), 0.5, 1.1, true])
	for i: int in 10:
		var z: float = lerpf(north, south, float(i) / 9.0)
		spots.append([Vector3(-half_wide - 0.3, high, z), 1.4, 2.6, false])
		spots.append([Vector3(half_wide + 0.3, high, z), 1.4, 2.6, false])
	for i: int in 8:
		var x: float = lerpf(-half_wide, half_wide, float(i) / 7.0)
		spots.append([Vector3(x, high, south + 0.3), 1.3, 2.4, false])
		spots.append([Vector3(x, high, north - 0.3), 1.3, 2.4, false])
	for spot: Array in spots:
		var at: Vector3 = spot[0]
		var blocked: bool = false
		for clear: Vector3 in keep_clear:
			if Vector2(at.x - clear.x, at.z - clear.z).length() < 2.6:
				blocked = true
		if blocked:
			continue
		var radius: float = rng.randf_range(float(spot[1]), float(spot[2]))
		var rock := MeshInstance3D.new()
		rock.mesh = boulder(rng, radius)
		rock.material_override = stone
		rock.position = at + Vector3(rng.randf_range(-0.4, 0.4), radius * 0.35,
			rng.randf_range(-0.4, 0.4))
		rock.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.0, TAU),
			rng.randf_range(-0.3, 0.3))
		rock.scale = Vector3(1.0, rng.randf_range(0.6, 0.9), 1.0)
		into.add_child(rock)
		if bool(spot[3]):
			var bulk := SphereShape3D.new()
			bulk.radius = radius * 0.8
			_solid(into, bulk, rock.position)


## **A campsite** (`DES-014`): an A-frame tent opening toward the fire, a
## bedroll inside, a pack and a pot by the door, and a banner on a pole.
static func campsite(into: Node3D, at: Vector3, canvas: Color, toward: Vector3,
		sway: float) -> void:
	var site := Node3D.new()
	site.position = at
	into.add_child(site)
	var facing: Vector3 = toward - at
	facing.y = 0.0
	site.rotation.y = atan2(facing.x, facing.z)
	var cloth := _material(canvas)
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	var wood := _material(Color(0.26, 0.19, 0.12))
	var long: float = 2.4
	var half: float = 1.0
	var high: float = 1.45
	# Two sloped sheets meeting at the ridge, and a closed back.
	for flank: float in [-1.0, 1.0]:
		var sheet := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(long, sqrt(half * half + high * high))
		sheet.mesh = quad
		sheet.material_override = cloth
		sheet.position = Vector3(flank * half * 0.5, high * 0.5, 0.0)
		sheet.rotation = Vector3(0.0, PI * 0.5, flank * -atan2(half, high))
		site.add_child(sheet)
	var back := SurfaceTool.new()
	back.begin(Mesh.PRIMITIVE_TRIANGLES)
	back.add_vertex(Vector3(-half, 0.0, -long * 0.5))
	back.add_vertex(Vector3(half, 0.0, -long * 0.5))
	back.add_vertex(Vector3(0.0, high, -long * 0.5))
	back.generate_normals()
	var gable := MeshInstance3D.new()
	gable.mesh = back.commit()
	gable.material_override = cloth
	site.add_child(gable)
	_box(site, Vector3(0.06, 0.06, long + 0.3), Vector3(0.0, high + 0.02, 0.0), wood)
	for end: float in [-1.0, 1.0]:
		_box(site, Vector3(0.06, high + 0.1, 0.06),
			Vector3(0.0, (high + 0.1) * 0.5, end * (long * 0.5 + 0.1)), wood)
	# The bedroll, the pack and the pot.
	var roll := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.16
	tube.bottom_radius = 0.16
	tube.height = 0.9
	roll.mesh = tube
	roll.material_override = _material(canvas.darkened(0.35))
	roll.position = Vector3(0.0, 0.16, -0.5)
	roll.rotation = Vector3(0.0, 0.0, PI * 0.5)
	site.add_child(roll)
	_box(site, Vector3(1.6, 0.04, 0.7), Vector3(0.0, 0.02, 0.15),
		_material(canvas.darkened(0.5)))
	_box(site, Vector3(0.42, 0.55, 0.3), Vector3(0.9, 0.28, long * 0.5 + 0.4),
		_material(Color(0.28, 0.21, 0.14)), Vector3(0.0, 0.3, 0.1))
	var pot := MeshInstance3D.new()
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.2
	bowl.bottom_radius = 0.15
	bowl.height = 0.24
	pot.mesh = bowl
	pot.material_override = _material(Color(0.12, 0.11, 0.11))
	pot.position = Vector3(-0.8, 0.12, long * 0.5 + 0.5)
	site.add_child(pot)
	var tent_body := BoxShape3D.new()
	tent_body.size = Vector3(half * 2.0, high, long)
	var solid := StaticBody3D.new()
	solid.collision_layer = CollisionLayers.WORLD
	solid.collision_mask = 0
	var holder := CollisionShape3D.new()
	holder.shape = tent_body
	holder.position = Vector3(0.0, high * 0.5, 0.0)
	solid.add_child(holder)
	site.add_child(solid)
	# The banner: a plot's mark, moving in the wind (`DES-014`'s *banners and
	# marks*, which Lineage will one day choose).
	_box(site, Vector3(0.07, 2.9, 0.07), Vector3(-1.3, 1.45, long * 0.5 + 0.2), wood)
	var flag := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.55, 1.0)
	plane.orientation = PlaneMesh.FACE_Z
	plane.subdivide_width = 6
	plane.subdivide_depth = 10
	flag.mesh = plane
	var weave := ShaderMaterial.new()
	weave.shader = CLOTH
	weave.set_shader_parameter("dye", canvas.lightened(0.15))
	weave.set_shader_parameter("seed", sway)
	flag.material_override = weave
	flag.position = Vector3(-1.3 + 0.3, 2.3, long * 0.5 + 0.2)
	site.add_child(flag)


## **The Lodge's board** (ADR-287): two posts under a little gabled roof, a
## backing of planks, and notices pinned to it — the contracts it holds.
static func board(into: Node3D, at: Vector3, notices: int) -> void:
	var wood := _material(Color(0.30, 0.22, 0.14))
	var dark := _material(Color(0.20, 0.15, 0.10))
	for flank: float in [-1.0, 1.0]:
		_box(into, Vector3(0.14, 2.5, 0.14), at + Vector3(flank * 0.8, 1.25, 0.0), dark)
	for row: int in 4:
		_box(into, Vector3(1.75, 0.24, 0.06), at + Vector3(0.0, 1.05 + 0.27 * float(row), 0.04),
			wood, Vector3(0.0, 0.0, 0.01 * float(row % 2 * 2 - 1)))
	for flank: float in [-1.0, 1.0]:
		_box(into, Vector3(2.1, 0.05, 0.62), at + Vector3(0.0, 2.62, flank * 0.2),
			dark, Vector3(flank * 0.5, 0.0, 0.0))
	var paper := _material(Color(0.78, 0.74, 0.62))
	for i: int in notices:
		_box(into, Vector3(0.32, 0.4, 0.01),
			at + Vector3(-0.55 + 0.37 * float(i), 1.55 + 0.12 * float(i % 2), 0.09),
			paper, Vector3(0.0, 0.0, 0.08 * float(i % 3 - 1)))
	var plate := BoxShape3D.new()
	plate.size = Vector3(1.9, 2.6, 0.3)
	_solid(into, plate, at + Vector3(0.0, 1.3, 0.0))


## **A chest** for the stash (ADR-287): boards, a lid, iron bands and a lock.
static func chest(into: Node3D, at: Vector3, colour: Color) -> void:
	var wood := _material(colour)
	var iron := _material(Color(0.14, 0.13, 0.13))
	_box(into, Vector3(1.4, 0.62, 0.82), at + Vector3(0.0, 0.31, 0.0), wood)
	var lid := MeshInstance3D.new()
	var arch := CylinderMesh.new()
	arch.top_radius = 0.41
	arch.bottom_radius = 0.41
	arch.height = 1.4
	arch.radial_segments = 12
	lid.mesh = arch
	lid.material_override = wood
	lid.position = at + Vector3(0.0, 0.62, 0.0)
	lid.rotation = Vector3(0.0, 0.0, PI * 0.5)
	lid.scale = Vector3(0.55, 1.0, 1.0)
	into.add_child(lid)
	for x: float in [-0.5, 0.0, 0.5]:
		_box(into, Vector3(0.07, 0.66, 0.86), at + Vector3(x, 0.33, 0.0), iron)
	_box(into, Vector3(0.16, 0.2, 0.04), at + Vector3(0.0, 0.52, 0.43), iron)
	var body := BoxShape3D.new()
	body.size = Vector3(1.4, 0.9, 0.82)
	_solid(into, body, at + Vector3(0.0, 0.45, 0.0))
