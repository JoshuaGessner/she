extends SceneTree

## Reproducible visual review of the production models under the production ink
## pass. Captures a silhouette lineup and event poses without running combat AI.
const MODELS: Array[String] = ["wretch", "sling_wretch", "bellringer",
	"hall_warden", "hoard_keeper", "gullsjukr"]
var _actors: Array[Node3D] = []
var _players: Array[AnimationPlayer] = []
var _labels: Array[Label3D] = []


func _initialize() -> void:
	call_deferred("_review")


func _review() -> void:
	root.size = Vector2i(1600, 900)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.82, 0.80, 0.74)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.7, 0.72, 0.74)
	environment.environment.ambient_light_energy = 0.65
	world.add_child(environment)
	var lamp := DirectionalLight3D.new()
	lamp.rotation_degrees = Vector3(-35, -25, 0)
	lamp.light_energy = 1.5
	world.add_child(lamp)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 1.6, 10)
	camera.look_at(Vector3(0, 1.0, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.4
	var post := InkPass.new()
	camera.add_child(post)
	await process_frame
	post.set_page(InkPass.Page.PRINT)
	for index: int in range(MODELS.size()):
		var kind: String = MODELS[index]
		var path: String = "res://art/%s/%s.glb" % ["heroes" if kind == "gullsjukr" else "enemies", kind]
		var actor := (load(path) as PackedScene).instantiate() as Node3D
		world.add_child(actor)
		actor.position.x = (float(index) - 2.5) * 1.5
		InkPass.classify(actor)
		InkPass.mark(actor)
		_actors.append(actor)
		var player := actor.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		_players.append(player)
		var label := Label3D.new()
		label.text = kind.replace("_", " ")
		label.font_size = 32
		label.pixel_size = 0.003
		label.position = Vector3(actor.position.x, -0.22, 0)
		world.add_child(label)
		_labels.append(label)
	for phase: String in ["idle", "walk", "telegraph", "attack", "death"]:
		for index: int in range(_players.size()):
			var clip: String = phase
			if index == 5:
				clip = "collect" if phase in ["telegraph", "attack", "death"] else phase
			var player: AnimationPlayer = _players[index]
			player.play(clip)
			player.seek(0.8 if phase != "walk" else 0.25, true)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/she_enemy_%s.png" % phase)
	post.visible = false
	environment.environment.background_color = Color(0.025, 0.026, 0.029)
	camera.size = 2.7
	for index: int in range(_actors.size()):
		for other: int in range(_actors.size()):
			_actors[other].visible = other == index
			_labels[other].visible = other == index
		camera.position = _actors[index].position + Vector3(2, 1.8, 4)
		camera.look_at(_actors[index].position + Vector3(0, 1, 0))
		_players[index].play("idle")
		_players[index].seek(0.5, true)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/she_enemy_%s_close.png" % MODELS[index])
	print("[enemy-review] five lineup captures saved to /private/tmp/she_enemy_*.png")
	quit()
