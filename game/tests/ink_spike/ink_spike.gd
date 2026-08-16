class_name InkSpike
extends Node3D

## `M1-T09` — the ink shader spike (`ART-005`, ADR-062). Go/no-go.
##
## Scope is deliberately narrow: **outlines and boil only**, on grey boxes.
## No hatching, no Threshold/Deep inversion. ADR-062 made those separable later
## additions precisely so this gate could be reached in a weekend rather than
## becoming the months-long effect `PRO-007` names as the project's second
## most likely cause of death.
##
## The gate is "~70% convincing", which is a *feel* question, so this builds to
## the point where a human can look and call it. Two things it must therefore
## produce: stills that isolate each treatment, and motion — because boil is a
## temporal effect and is completely invisible in a still image.
##
## Interactive:  godot --path game res://tests/ink_spike/ink_spike.tscn
##   WASD + mouse   fly around        1-4   raw / clean / wobble / ink
##   P              paper (white) ground    Esc   release mouse, quit
##
## Capture:      python3 tools/run_ink_spike.py

const MOVE_SPEED: float = 6.0
const MOUSE_SENSITIVITY: float = 0.0022
const GREY: Color = Color(0.62, 0.61, 0.60)

## The four treatments the gate compares. The point of separating them is that
## "does the edge detection work" and "does it read as drawn by a hand" are
## different questions, and only the second one is what ADR-062 is asking.
enum Mode { RAW, CLEAN, WOBBLE, INK }

const MODE_NAMES: Dictionary = {
	Mode.RAW: "raw",        # no post at all — the grey box as the engine draws it
	Mode.CLEAN: "clean",    # edges, no hand treatment: the technical drawing
	Mode.WOBBLE: "wobble",  # wobble at full framerate: sterile shimmer
	Mode.INK: "ink",        # wobble held to 10 fps: the actual proposal
}

var _material: ShaderMaterial
var _camera: Camera3D
var _mode: Mode = Mode.INK
var _paper: bool = false
var _mouse_captured: bool = false
var _pitch: float = 0.0
var _yaw: float = 0.0

var _capture_dir: String = ""
var _capture_frames: int = 48
var _capture_fps: float = 12.0
var _bench: bool = false
var _amplify_copies: int = 0
var _amplified: Array[MeshInstance3D] = []

@onready var _world: Node3D = $World
@onready var _post: MeshInstance3D = $PostQuad


func _ready() -> void:
	_parse_args()
	_build_room()
	_build_camera()
	_build_post_process()
	_apply_mode(_mode)

	if _bench:
		_run_bench()
	elif _capture_dir.is_empty():
		_capture_mouse(true)
	else:
		_run_capture()


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--") or not arg.contains("="):
			continue
		var pair: PackedStringArray = arg.substr(2).split("=", true, 1)
		match pair[0]:
			"capture":
				_capture_dir = pair[1]
			"frames":
				_capture_frames = int(pair[1])
			"fps":
				_capture_fps = float(pair[1])
			"bench":
				_bench = int(pair[1]) != 0
			"amplify":
				_amplify_copies = int(pair[1])


# ── the grey box ──────────────────────────────────────────────────────────


func _box(size: Vector3, pos: Vector3, rot_y: float = 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotate_y(rot_y)
	node.material_override = _grey_material()
	_world.add_child(node)


func _grey_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GREY
	mat.roughness = 1.0
	mat.metallic = 0.0
	return mat


func _build_room() -> void:
	# A corridor and a chamber, because ART-005 warns that "a style that only
	# works in an empty corridor is not a style" — this needs clutter, depth
	# range, curved surfaces and hard creases all in one frame.
	# A dungeon chamber at human scale — a 4.2 m ceiling, not a plaza. Room
	# proportion matters to the judgement: tall thin pillars against a dark
	# void read as a skyline, which is a different picture entirely.
	_box(Vector3(20, 0.5, 22), Vector3(0, -0.25, 0))          # floor
	_box(Vector3(20, 0.5, 22), Vector3(0, 4.45, 0))           # ceiling
	_box(Vector3(0.5, 4.2, 22), Vector3(-10, 2.1, 0))         # walls
	_box(Vector3(0.5, 4.2, 22), Vector3(10, 2.1, 0))
	_box(Vector3(20, 4.2, 0.5), Vector3(0, 2.1, -11))
	_box(Vector3(20, 4.2, 0.5), Vector3(0, 2.1, 11))

	# Pillars — clean vertical silhouettes receding into the room, to exercise
	# the mandatory distance falloff across one frame.
	for i: int in range(4):
		var z: float = -8.0 + float(i) * 4.0
		_box(Vector3(1.6, 4.2, 1.6), Vector3(-4.8, 2.1, z))
		_box(Vector3(1.6, 4.2, 1.6), Vector3(4.8, 2.1, z))

	# Stacked crates at angles — interior creases, the thing inverted-hull
	# outlining cannot produce and the reason ART-005 chose screen-space.
	_box(Vector3(1.6, 1.6, 1.6), Vector3(-1.4, 0.8, 1.4), 0.4)
	_box(Vector3(1.2, 1.2, 1.2), Vector3(-1.2, 2.2, 1.3), 0.9)
	_box(Vector3(1.4, 1.4, 1.4), Vector3(0.9, 0.7, 0.2), -0.3)
	_box(Vector3(2.0, 0.8, 1.2), Vector3(1.1, 1.8, 0.3), 0.15)

	# A stepped platform: many near-parallel creases at varying depth.
	for i: int in range(5):
		var s: float = float(i)
		_box(Vector3(4.4 - s * 0.7, 0.4, 2.2), Vector3(2.2, 0.2 + s * 0.4, -5.4 - s * 0.35))

	# Curved surfaces — smooth normals must NOT generate interior scribble.
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.75
	cyl.bottom_radius = 0.75
	cyl.height = 4.2
	var pillar := MeshInstance3D.new()
	pillar.mesh = cyl
	pillar.position = Vector3(-2.9, 2.1, -1.6)
	pillar.material_override = _grey_material()
	_world.add_child(pillar)

	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	var ball := MeshInstance3D.new()
	ball.mesh = sphere
	ball.position = Vector3(2.9, 1.0, 3.4)
	ball.material_override = _grey_material()
	_world.add_child(ball)

	# ART-005's known limitation, staged on purpose: two flush, coplanar,
	# identically-oriented faces produce no depth or normal discontinuity and
	# therefore no line. This is Q102 made visible rather than argued about.
	_box(Vector3(2.6, 2.6, 0.5), Vector3(-4.0, 1.3, -4.2))
	_box(Vector3(2.6, 2.6, 0.5), Vector3(-1.4, 1.3, -4.2))

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 28, 0)
	sun.light_energy = 1.0
	_world.add_child(sun)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 3.6, -2.0)
	fill.omni_range = 24.0
	fill.light_energy = 1.4
	_world.add_child(fill)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.20, 0.20, 0.22)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.45, 0.45, 0.5)
	environment.ambient_light_energy = 0.6
	env.environment = environment
	_world.add_child(env)


func _build_camera() -> void:
	_camera = Camera3D.new()
	# Eye height, off-axis, looking diagonally down the chamber — so one frame
	# carries near clutter, mid-ground creases and distant geometry, which is
	# what the distance falloff has to be judged against.
	_camera.position = Vector3(1.4, 1.7, 8.2)
	_camera.fov = 72.0
	add_child(_camera)
	_camera.look_at(Vector3(-0.6, 1.4, -5.0), Vector3.UP)
	# Seed the free-look state from that framing, or the first mouse move snaps.
	_pitch = _camera.rotation.x
	_yaw = _camera.rotation.y


func _build_post_process() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	_post.mesh = quad
	# Never let the full-screen quad be frustum-culled; it lives in clip space.
	_post.custom_aabb = AABB(Vector3(-1e5, -1e5, -1e5), Vector3(2e5, 2e5, 2e5))

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.03
	var noise_tex := NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.seamless = true
	noise_tex.width = 256
	noise_tex.height = 256

	_material = ShaderMaterial.new()
	_material.shader = load("res://tests/ink_spike/ink_outline.gdshader") as Shader
	_material.set_shader_parameter("noise_tex", noise_tex)
	_material.render_priority = 100
	_post.material_override = _material


# ── modes ─────────────────────────────────────────────────────────────────


func _apply_mode(mode: Mode) -> void:
	_mode = mode
	_post.visible = mode != Mode.RAW
	for extra: MeshInstance3D in _amplified:
		extra.visible = mode != Mode.RAW
	match mode:
		Mode.CLEAN:
			_material.set_shader_parameter("wobble_amount", 0.0)
			_material.set_shader_parameter("weight_variation", 0.0)
			_material.set_shader_parameter("boil_fps", 0.0)
		Mode.WOBBLE:
			_material.set_shader_parameter("wobble_amount", 1.1)
			_material.set_shader_parameter("weight_variation", 0.55)
			_material.set_shader_parameter("boil_fps", 0.0)  # 60 fps shimmer
		Mode.INK:
			_material.set_shader_parameter("wobble_amount", 1.1)
			_material.set_shader_parameter("weight_variation", 0.55)
			_material.set_shader_parameter("boil_fps", 10.0)
		Mode.RAW:
			pass
	_material.set_shader_parameter("paper_mix", 1.0 if _paper else 0.0)


func _capture_mouse(on: bool) -> void:
	_mouse_captured = on
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if not _capture_dir.is_empty():
		return
	if event is InputEventMouseMotion and _mouse_captured:
		var motion := event as InputEventMouseMotion
		_yaw -= motion.relative.x * MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - motion.relative.y * MOUSE_SENSITIVITY, -1.5, 1.5)
		_camera.rotation = Vector3(_pitch, _yaw, 0.0)
	elif event is InputEventKey and event.is_pressed():
		var key := event as InputEventKey
		match key.keycode:
			KEY_1: _apply_mode(Mode.RAW)
			KEY_2: _apply_mode(Mode.CLEAN)
			KEY_3: _apply_mode(Mode.WOBBLE)
			KEY_4: _apply_mode(Mode.INK)
			KEY_P:
				_paper = not _paper
				_apply_mode(_mode)
			KEY_ESCAPE:
				get_tree().quit()


func _process(delta: float) -> void:
	if not _capture_dir.is_empty() or not _mouse_captured:
		return
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir -= _camera.global_basis.z
	if Input.is_key_pressed(KEY_S): dir += _camera.global_basis.z
	if Input.is_key_pressed(KEY_A): dir -= _camera.global_basis.x
	if Input.is_key_pressed(KEY_D): dir += _camera.global_basis.x
	if Input.is_key_pressed(KEY_SHIFT): dir *= 2.5
	_camera.position += dir * MOVE_SPEED * delta


# ── capture ───────────────────────────────────────────────────────────────


func _save_frame(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(path)


func _run_capture() -> void:
	# Stills first: one per treatment, identical viewpoint, so the comparison
	# isolates the treatment and nothing else.
	for mode: Mode in [Mode.RAW, Mode.CLEAN, Mode.WOBBLE, Mode.INK]:
		_apply_mode(mode)
		await RenderingServer.frame_post_draw  # let the parameter change land
		await _save_frame("%s/still_%s.png" % [_capture_dir, MODE_NAMES[mode]])

	# The same frame on paper ground, to see the linework without grey fill
	# competing with it.
	_paper = true
	_apply_mode(Mode.INK)
	await RenderingServer.frame_post_draw
	await _save_frame("%s/still_ink_paper.png" % _capture_dir)
	_paper = false
	_apply_mode(Mode.INK)

	# Then motion, with a static camera. Boil must be visible with nothing
	# moving — if it only reads while the camera turns, it is camera motion
	# being mistaken for hand-drawn shimmer, and the gate would be judging the
	# wrong thing. `manual_time` paces the boil by frame index, so the recording
	# is correct regardless of how slowly it renders.
	for i: int in range(_capture_frames):
		_material.set_shader_parameter("manual_time", float(i) / _capture_fps)
		await _save_frame("%s/boil_%03d.png" % [_capture_dir, i])

	print("[ink_spike] captured %d frames to %s" % [_capture_frames, _capture_dir])
	get_tree().quit()


func _measure_frames(count: int) -> float:
	## Mean wall-clock ms per presented frame.
	##
	## Two earlier approaches failed and are recorded so they are not retried:
	## plain wall clock at window resolution returned 8.3333 ms both with and
	## without the pass — exactly 120 fps, i.e. vsync-clamped — and
	## `viewport_get_measured_render_time_gpu` reports 0.000 on this machine.
	##
	## So: run the pass at a resolution where its cost cannot hide under the
	## refresh period. If scene+pass sits above the vsync floor, the difference
	## is real. If both are pinned to it, the run reports "clamped" rather than
	## a flattering zero.
	var started: int = Time.get_ticks_usec()
	for i: int in range(count):
		await RenderingServer.frame_post_draw
	return float(Time.get_ticks_usec() - started) / float(count) / 1000.0


func _amplify(copies: int) -> void:
	## Stack N extra copies of the pass so its cost cannot hide under the
	## refresh period. Each copy does the same work as the real one — including
	## the backbuffer copy a screen-texture read forces — so dividing the
	## measured excess by N gives the per-pass cost. Crude, but it is the only
	## route left once the display clamps frame time and the GPU timer is dead.
	for i: int in range(copies):
		var extra := MeshInstance3D.new()
		extra.mesh = _post.mesh
		extra.custom_aabb = _post.custom_aabb
		extra.material_override = _material
		add_child(extra)
		# Tracked so RAW can hide them too. Missing this made every reading
		# come out at ~0: the copies rendered in *both* modes, so the "no pass"
		# baseline contained 400 passes.
		_amplified.append(extra)


func _run_bench() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	if _amplify_copies > 0:
		_amplify(_amplify_copies)

	# Sample kept small: macOS throttles an unfocused window, and a 780-frame
	# sample simply never returned.
	var results: Dictionary = {}
	for mode: Mode in [Mode.RAW, Mode.INK]:
		_apply_mode(mode)
		print("[ink_spike] measuring %s..." % MODE_NAMES[mode])
		await _measure_frames(20)  # warm up: shader compile, pipeline caches
		results[MODE_NAMES[mode]] = await _measure_frames(90)

	var without: float = float(results["raw"])
	var with_pass: float = float(results["ink"])
	var size: Vector2 = get_viewport().get_visible_rect().size
	var passes: int = _amplify_copies + 1
	var clamped: bool = absf(without - 8.3333) < 0.05 and absf(with_pass - 8.3333) < 0.05
	var template: String = ("[ink_spike] %dx%d x%d passes  scene %.3f ms"
		+ "  scene+passes %.3f ms  per-pass %.4f ms  %s")
	print(template % [
		int(size.x), int(size.y), passes, without, with_pass,
		(with_pass - without) / float(passes),
		"CLAMPED — measurement invalid" if clamped else "ok",
	])
	get_tree().quit()
