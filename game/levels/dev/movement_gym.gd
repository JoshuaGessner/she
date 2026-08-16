extends Node3D

## A grey-box gym for judging `M1-T01`. Not a level: `M1-T03` builds the first
## real room set. This exists so the controller can be felt against slopes,
## steps, gaps and a low overhang — the four things that expose a bad
## first-person controller immediately.
##
## Unlit by the ink shader on purpose. DES-009: the grey box must feel decent
## with no juice at all, and the shader is exactly the kind of thing that makes
## a controller *look* better while telling you nothing about how it plays.

const GREY: Color = Color(0.60, 0.59, 0.58)
const ACCENT: Color = Color(0.38, 0.37, 0.36)

@onready var _world: Node3D = $World


func _ready() -> void:
	_build()
	var player: Node3D = preload("res://actors/player/player.tscn").instantiate() as Node3D
	player.position = Vector3(0, 0.1, 10)
	add_child(player)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture(arg.split("=", true, 1)[1])
		elif arg == "--probe":
			_probe(player as Player)


func _probe(player: Player) -> void:
	## Drive the controller and report steady-state speeds.
	##
	## Feel is a playtest question and this does not pretend otherwise. What it
	## does answer is whether the couplings are actually wired: that sprint is
	## faster than walk, that crouch is slower, and that weight bites by the
	## amount DES-005 asks for rather than by some number nobody checked.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tuning: TuningProfile = Config.tuning
	print("[gym] %-22s %8s %8s" % ["case", "m/s", "expected"])
	for case: Dictionary in [
		{"name": "walk", "kg": 0.0, "sprint": false, "crouch": false,
			"expect": tuning.walk_speed},
		{"name": "sprint", "kg": 0.0, "sprint": true, "crouch": false,
			"expect": tuning.sprint_speed},
		{"name": "crouch", "kg": 0.0, "sprint": false, "crouch": true,
			"expect": tuning.crouch_speed},
		{"name": "walk, full load", "kg": tuning.carry_capacity, "sprint": false,
			"crouch": false, "expect": tuning.walk_speed * tuning.speed_at_capacity},
		{"name": "sprint, full load", "kg": tuning.carry_capacity, "sprint": true,
			"crouch": false, "expect": tuning.sprint_speed * tuning.speed_at_capacity},
	]:
		# Reset to the top of a clear runway each time. Without this the player
		# simply runs into the slopes partway through the run and every case
		# after the second reports 0.00 — which looks exactly like a broken
		# controller and is not one.
		player.position = Vector3(0, 0.1, 18)
		player.velocity = Vector3.ZERO
		player.carried.kilograms = float(case["kg"])
		player.stamina.refill()
		Input.action_press("move_forward")
		if bool(case["sprint"]):
			Input.action_press("sprint")
		if bool(case["crouch"]):
			Input.action_press("crouch")
		# Long enough to reach steady state, short enough that stamina does not
		# run dry mid-measurement and quietly turn a sprint into a walk.
		for i: int in range(90):
			await get_tree().physics_frame
		var measured: float = player.planar_speed()
		print("[gym] %-22s %8.2f %8.2f" % [case["name"], measured, case["expect"]])
		Input.action_release("move_forward")
		Input.action_release("sprint")
		Input.action_release("crouch")
		for i: int in range(30):
			await get_tree().physics_frame
	get_tree().quit()


func _capture(path: String) -> void:
	## Screenshot and quit. Building a gym without looking at it is how the
	## ink spike ended up with its camera standing inside a pillar.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


func _material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 1.0
	return mat


func _slab(size: Vector3, pos: Vector3, pitch: float = 0.0, colour: Color = GREY) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotate_x(pitch)

	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(colour)
	body.add_child(visual)

	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	_world.add_child(body)


func _build() -> void:
	# A long floor: sprint needs room to reach top speed and be felt.
	_slab(Vector3(24, 0.5, 44), Vector3(0, -0.25, 0))

	# Slopes at 10 / 20 / 30 degrees. Godot's default floor_max_angle is 45, so
	# all three are walkable and the question is how they *feel*, not whether
	# they work.
	for i: int in range(3):
		var degrees: float = 10.0 + float(i) * 10.0
		var radians: float = deg_to_rad(degrees)
		# Positive pitch drops the +Z end, so the ramp rises away from the
		# player's spawn. Lifting the centre by half-length x sin(theta) puts
		# that near end on the floor instead of buried in it — the first build
		# floated them and showed only their undersides.
		var half: float = 3.0
		_slab(Vector3(4, 0.4, half * 2.0),
			Vector3(-8.0 + float(i) * 4.0, half * sin(radians), -6.0),
			radians, ACCENT)

	# Steps at 0.15 / 0.25 / 0.35 m. A capsule rides small steps on its rounded
	# base; where that stops working is the thing to find out here, since the
	# Delvings are full of stairs.
	for i: int in range(3):
		var rise: float = 0.15 + float(i) * 0.10
		for step: int in range(4):
			var height: float = rise * float(step + 1)
			_slab(Vector3(3, height, 1.2),
				Vector3(6.0 + float(i) * 3.2, height * 0.5, -4.0 - float(step) * 1.2),
				0.0, ACCENT)

	# A gap to jump, and a ledge to fall off.
	_slab(Vector3(6, 0.5, 4), Vector3(-6, 1.75, 6), 0.0, ACCENT)
	_slab(Vector3(6, 0.5, 4), Vector3(-6, 1.75, 12), 0.0, ACCENT)

	# A low overhang: crouch is only a real verb if something needs it, and
	# standing up under it must be refused rather than clipping through.
	_slab(Vector3(5, 0.4, 3), Vector3(7, 1.4, 8), 0.0, ACCENT)
	_slab(Vector3(0.4, 1.4, 3), Vector3(4.7, 0.7, 8))
	_slab(Vector3(0.4, 1.4, 3), Vector3(9.3, 0.7, 8))

	# Walls, so the gym is a room rather than a plinth in a void.
	_slab(Vector3(24, 5, 0.5), Vector3(0, 2.5, -22))
	_slab(Vector3(24, 5, 0.5), Vector3(0, 2.5, 22))
	_slab(Vector3(0.5, 5, 44), Vector3(-12, 2.5, 0))
	_slab(Vector3(0.5, 5, 44), Vector3(12, 2.5, 0))

	# Flat and bright on purpose. Atmosphere is ART-001's business and the ink
	# shader's; a gym exists to make surfaces and their angles unambiguous, and
	# the first build had slopes reading as near-black, which is the opposite
	# of useful when the thing being judged is how they feel to walk up.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 25, 0)
	sun.light_energy = 1.1
	_world.add_child(sun)

	var back := DirectionalLight3D.new()
	back.rotation_degrees = Vector3(-30, -145, 0)
	back.light_energy = 0.45
	_world.add_child(back)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.30, 0.32, 0.36)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.63, 0.68)
	environment.ambient_light_energy = 1.0
	env.environment = environment
	_world.add_child(env)
