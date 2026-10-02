class_name MenuTableau
extends SubViewportContainer

## **The first thing the game shows is her** (ADR-288). The menu was a column of
## boxed buttons on a flat dark ground — an app's settings page. Hunt:
## Showdown, Darkest Dungeon and the Souls games all open on a living scene
## with the menu laid over one side of it, and the reason is the same in each:
## the title screen is the promise of what the game feels like, and a list on a
## colour promises nothing.
##
## So: her head and neck rising out of the dark over the hoard, two braziers
## lighting her from below, drawn through the same ink pass as the Deep, and a
## camera that breathes very slowly. It is a picture, not a level — nothing in
## it is solid, nothing replicates, and it costs one small viewport.

var _camera: Camera3D = null
var _time: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view := SubViewport.new()
	view.own_world_3d = true
	view.handle_input_locally = false
	add_child(view)
	var world := Node3D.new()
	view.add_child(world)

	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color(0.02, 0.02, 0.025)
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(0.12, 0.11, 0.12)
	sky.ambient_light_energy = 0.35
	sky.fog_enabled = true
	sky.fog_light_color = Color(0.03, 0.03, 0.035)
	sky.fog_density = 0.035
	environment.environment = sky
	world.add_child(environment)

	var her := (load("res://art/heroes/her.glb") as PackedScene).instantiate() as Node3D
	var scales := StandardMaterial3D.new()
	scales.albedo_color = Chamber.her_colour(0)
	scales.roughness = 0.9
	for node: Node in her.find_children("*", "MeshInstance3D", true, false):
		var piece := node as MeshInstance3D
		for surface: int in piece.mesh.get_surface_count():
			var was: Material = piece.mesh.surface_get_material(surface)
			if was == null or was.resource_name != "eye":
				piece.set_surface_override_material(surface, scales)
	world.add_child(her)

	var gold := StandardMaterial3D.new()
	gold.albedo_color = Chamber.GOLD
	gold.metallic = 0.85
	gold.roughness = 0.3
	gold.emission_enabled = true
	gold.emission = Chamber.GOLD * 0.4
	InkPass.stamp(gold, InkPass.Class.GOLD)
	var heap := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = 1.5
	dome.height = 3.0
	dome.is_hemisphere = true
	heap.mesh = dome
	heap.material_override = gold
	heap.scale = Vector3(1.0, 0.22, 1.0)
	heap.position = Vector3(0.0, 0.0, -0.4)
	world.add_child(heap)

	for flank: float in [-1.0, 1.0]:
		Hearth.brazier(world, Vector3(flank * 3.2, 0.0, 2.0))

	# Firelight on her face from below and in front: the braziers light her
	# body, and this is what makes her look down at you.
	var face := OmniLight3D.new()
	face.light_color = Color(1.0, 0.6, 0.28)
	face.light_energy = 2.2
	face.omni_range = 6.0
	face.position = Vector3(0.4, 2.2, 1.6)
	world.add_child(face)

	_camera = Camera3D.new()
	_camera.fov = 52.0
	world.add_child(_camera)
	var ink := InkPass.new()
	_camera.add_child(ink)
	_camera.make_current()
	_place_camera()


func _process(delta: float) -> void:
	_time += delta
	_place_camera()


## A slow drift, never a pan: the eye should not feel it moving, only that the
## picture is alive.
func _place_camera() -> void:
	if _camera == null:
		return
	var sway: float = sin(_time * 0.11) * 0.6
	var bob: float = sin(_time * 0.17) * 0.15
	_camera.position = Vector3(-1.2 + sway, 1.2 + bob, 6.4)
	_camera.look_at(Vector3(1.9 + sway * 0.3, 3.3, -0.6), Vector3.UP)
