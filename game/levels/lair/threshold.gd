class_name Threshold
extends Node3D

## The mouth of the mountain (`M2-T06`, `DES-014`, ADR-021).
##
## **The only space that replicates.** Where the Bound camp, where the Lodge
## keeps its fire, and where the Descent begins. Your Chamber is behind you and
## nobody else has ever been in it.
##
## The split earns its keep by *removing* a system rather than adding one:
##
## ```
## SOLO:    Chamber ──► Threshold ──► Descent
## CO-OP:   Chamber ──► Threshold ──► Descent
##                      └─ friends are standing here
## ```
##
## Identical flow. No mode switch, no different UI, no "clan Lair" versus "my
## Lair" — the only difference is whether anyone else is out here when you walk
## out. And because nothing is simulated in this space, it is nearly free to
## replicate: avatars, and that is all.
##
## ## The one thing it already says without saying anything
##
## The fire is the **Ashen Lodge's** fire (`DES-007`, ADR-020) — the people
## telling you to stop. So walking from the fire to the Descent is literally
## walking away from the light, and your friends are standing around the ones
## who want you to quit. Never stated, never pointed at. It is just where the
## door is.
##
## ## Deliberately almost empty (ADR-023)
##
## *"Thematically large and physically small."* What is absent is absent, not
## sketched: the contract board (`M4-T04`), the Forge and the Quartermaster
## (`M4`/`M5`), the staves (ADR-022), the four campsites, camp momentum
## (ADR-025), and the NPC Bound who remember you and die of the same disease
## you have (ADR-027, `M5`). `DES-010`'s onboarding wants the first visit to
## show **her and the Descent only** and the camp to fill in over the first
## hour — so a Threshold that is a fire and a doorway is not a placeholder for
## a bigger one. It is the first hour.

const GROUND: float = 34.0
const FIRE_AT: Vector3 = Vector3(0.0, 0.0, 0.0)
const DESCENT_AT: Vector3 = Vector3(0.0, 0.0, -9.0)
const CHAMBER_AT: Vector3 = Vector3(0.0, 0.0, 7.5)

const NIGHT: Color = Color(0.055, 0.06, 0.075)
const ROCK: Color = Color(0.19, 0.185, 0.19)
const FIRE_COLOUR: Color = Color(1.0, 0.62, 0.24)
## The Descent is a hole. It is the only thing here that is not lit.
const DESCENT_COLOUR: Color = Color(0.04, 0.04, 0.05)
const CHAMBER_DOOR: Color = Color(0.42, 0.40, 0.36)

const SESSION_SCENE: PackedScene = preload("res://systems/net/coop_session.tscn")
const SPAWNS: Array[Vector3] = [
	Vector3(-1.6, 0.1, 3.2), Vector3(1.6, 0.1, 3.2),
	Vector3(-3.4, 0.1, 4.0), Vector3(3.4, 0.1, 4.0),
]

var _session: CoopSession = null
var _readout: Label = null


func _ready() -> void:
	_build_ground()
	_build_fire()
	_build_doors()
	_spawn_actors()
	_build_readout()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--threshold-shot="):
			_threshold_shot(arg.split("=", true, 1)[1])


func _spawn_actors() -> void:
	_session = SESSION_SCENE.instantiate() as CoopSession
	_session.spawn_points = SPAWNS
	add_child(_session)


func _process(_delta: float) -> void:
	var player: Player = _session.local_player() if _session != null else null
	if player == null:
		return
	if _readout != null:
		_readout.text = "\n".join([
			"THE THRESHOLD    descent %d" % GameState.descents,
			"",
			"stash      %d item(s), %d tribute" % [
				GameState.stash.size(), GameState.stash_value()],
			"the hoard  %d" % GameState.hoard_value,
			"",
			"the fire behind you is the Lodge's",
			"walk into the dark ahead to descend",
			"walk back onto the pale slab for your Chamber",
		])
	if player.global_position.distance_to(DESCENT_AT) <= 2.0:
		_descend()
	elif player.global_position.distance_to(CHAMBER_AT) <= 1.8:
		set_process(false)
		get_tree().change_scene_to_file("res://levels/lair/chamber.tscn")


## Down. Whatever is in the stash is what you take, because `DES-014` puts
## loadout choices in the Chamber and this is the doorway rather than a menu.
func _descend() -> void:
	set_process(false)
	GameState.descents += 1
	get_tree().change_scene_to_file("res://levels/room_set/room_set.tscn")


func _build_ground() -> void:
	_slab(Vector3(GROUND, 0.4, GROUND), Vector3(0.0, -0.2, 0.0), ROCK)
	# The mountain, closing in behind the Descent.
	_slab(Vector3(GROUND, 9.0, 0.8), Vector3(0.0, 4.5, -13.0), ROCK)
	_slab(Vector3(0.8, 9.0, 12.0), Vector3(-8.0, 4.5, -7.0), ROCK)
	_slab(Vector3(0.8, 9.0, 12.0), Vector3(8.0, 4.5, -7.0), ROCK)

	var environment := WorldEnvironment.new()
	var world := Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.background_color = NIGHT
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color(0.16, 0.17, 0.22)
	world.ambient_light_energy = 0.5
	environment.environment = world
	add_child(environment)


## The fire, and it is the only warm thing here. `DES-014`: *"the only safe
## sound in the game"* is this camp, and the light is the visual half of that
## — `M2-T09` writes the other half.
func _build_fire() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.5
	mesh.bottom_radius = 0.8
	mesh.height = 0.7
	var glow := StandardMaterial3D.new()
	glow.albedo_color = FIRE_COLOUR
	glow.emission_enabled = true
	glow.emission = FIRE_COLOUR
	glow.emission_energy_multiplier = 1.2
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = glow
	node.position = FIRE_AT + Vector3(0.0, 0.35, 0.0)
	add_child(node)

	var light := OmniLight3D.new()
	light.position = FIRE_AT + Vector3(0.0, 1.4, 0.0)
	light.omni_range = 16.0
	light.light_color = FIRE_COLOUR
	light.light_energy = 2.4
	add_child(light)


func _build_doors() -> void:
	# The Descent: unlit, and deliberately the darkest thing on screen.
	_slab(Vector3(3.6, 0.1, 3.6), DESCENT_AT + Vector3(0.0, 0.02, 0.0),
		DESCENT_COLOUR)
	_slab(Vector3(2.6, 0.1, 2.6), CHAMBER_AT + Vector3(0.0, 0.02, 0.0),
		CHAMBER_DOOR)


func _build_readout() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_readout = Label.new()
	_readout.position = Vector2(18.0, 18.0)
	_readout.add_theme_color_override("font_color", Color(0.88, 0.86, 0.80))
	layer.add_child(_readout)


func _slab(size: Vector3, centre: Vector3, colour: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = centre
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
	add_child(node)


func _threshold_shot(path: String) -> void:
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[lair] threshold — %s" % path.get_file())
	get_tree().quit()
