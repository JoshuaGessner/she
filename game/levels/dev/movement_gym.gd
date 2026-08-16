extends Node3D

## A grey-box gym for judging `M1-T01`. Not a level: `M1-T03` builds the first
## real room set. This exists so the controller can be felt against slopes,
## steps, gaps and a low overhang — the four things that expose a bad
## first-person controller immediately.
##
## Carried the ink pass from ADR-076 onward, and deliberately not before it.
## DES-009 puts control ahead of polish: the grey box had to feel decent with no
## juice at all first, because a shader is exactly the kind of thing that makes
## a controller *look* better while telling you nothing about how it plays.
## Press `i`/Y to strip it back off and check that judgement still holds.

const GREY: Color = Color(0.60, 0.59, 0.58)
const ACCENT: Color = Color(0.38, 0.37, 0.36)

const ENEMY_SCENE: PackedScene = preload("res://actors/enemies/enemy.tscn")
const SPAWN: Vector3 = Vector3(0, 0.1, 10)

## Where the enemies stand. Spread out and away from spawn on purpose: the M1
## gate question is whether a tester *chooses* to swing at something they could
## have walked past, and an enemy standing on the spawn point answers it for
## them.
const ENEMY_POSTS: Array[Vector3] = [
	Vector3(-3, 0.1, -2), Vector3(3.5, 0.1, -9), Vector3(-7, 0.1, -14),
]

@onready var _world: Node3D = $World

var _player: Player = null


func _ready() -> void:
	_build()
	_player = preload("res://actors/player/player.tscn").instantiate() as Player
	_player.position = SPAWN
	add_child(_player)
	_player.health.died.connect(_on_player_died)
	# The ring and the vision cones now live in a component, so the room set
	# gets them too (ADR-078). It finds the player and the enemies by group.
	_world.add_child(DebugOverlays.new())
	_spawn_enemies()
	# Once, at startup. This loop briefly ended up inside _process() during a
	# refactor and re-entered the probe every frame — 84,000 lines of header and
	# no measurements, which is a good argument for reading the whole function
	# after moving anything into the middle of one.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture(arg.split("=", true, 1)[1])
		elif arg == "--probe":
			_probe(_player)
		elif arg == "--combat-probe":
			_combat_probe(_player)
		elif arg == "--clamor-probe":
			_clamor_probe(_player)
		elif arg.begins_with("--capture-top="):
			_capture_top(arg.split("=", true, 1)[1])
		elif arg == "--lifecycle-probe":
			_lifecycle_probe()


## Reset the gym repeatedly and let the per-frame overlays run over the wreckage.
##
## Reported from play as a wall of "Trying to assign invalid previously freed
## instance". Nothing caught it because every probe measures numbers and then
## quits, and the only thing that frees an enemy is `_reset()` — which a probe
## never reached. The measurement probes and the render path had no overlap at
## all, so the whole lifecycle of a debug overlay was untested.
##
## This deliberately proves nothing about gameplay. It exists so CI drives the
## code that runs every frame, on objects that have just been destroyed, and
## the runner fails on any SCRIPT ERROR it produces.
func _lifecycle_probe() -> void:
	for cycle: int in range(3):
		_reset()
		# Long enough for queue_free to actually take effect: it lands at the
		# end of the frame, so the *next* frames are the ones that walk over
		# the freed instances.
		for i: int in range(8):
			await get_tree().process_frame
	print("[gym] lifecycle probe survived %d resets" % 3)
	get_tree().quit()


## Overhead capture. The audible footprint is a shape on the ground plane, and
## a first-person shot at eye level cannot show a shape on the ground plane.
func _capture_top(path: String) -> void:
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 34.0
	camera.position = Vector3(0, 30, 2)
	camera.rotation_degrees = Vector3(-90, 0, 0)
	add_child(camera)
	camera.make_current()
	# The ink pass belongs to the player's camera but draws in clip space, so it
	# fills this one too and composites over the debug overlays. An overhead
	# diagnostic wants the raw simulation, not the style.
	_player.show_ink(false)
	# North of the interior wall, and loud enough to reach past it but not so
	# loud the footprint leaves the room — at maximum clamor the outline is
	# wider than the gym and the doorway notch is off-screen.
	_player.position = Vector3(0, 0.1, 9)
	_player.clamor.add(14.0 / Config.tuning.clamor_metres_per_unit)
	for i: int in range(4):
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


func _clamor_probe(player: Player) -> void:
	## Measure what each action costs in noise, and how far it carries.
	##
	## DES-005 Layer 1 makes two claims this checks: that weight makes you
	## louder as well as slower, and that crouching is a real stealth verb
	## rather than a speed penalty. Both are ratios, and a ratio nobody measured
	## is a ratio nobody knows.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tuning: TuningProfile = Config.tuning
	print("[clamor] %-26s %8s %8s" % ["case", "peak", "heard m"])

	for case: Dictionary in [
		{"name": "walk, empty", "kg": 0.0, "sprint": false, "crouch": false},
		{"name": "walk, full load", "kg": tuning.carry_capacity,
			"sprint": false, "crouch": false},
		{"name": "sprint, empty", "kg": 0.0, "sprint": true, "crouch": false},
		{"name": "crouch, empty", "kg": 0.0, "sprint": false, "crouch": true},
		{"name": "crouch, full load", "kg": tuning.carry_capacity,
			"sprint": false, "crouch": true},
	]:
		player.position = Vector3(0, 0.1, 18)
		player.velocity = Vector3.ZERO
		player.clamor.silence()
		player.carried.kilograms = float(case["kg"])
		player.stamina.refill()
		Input.action_press("move_forward")
		if bool(case["sprint"]):
			Input.action_press("sprint")
		if bool(case["crouch"]):
			Input.action_press("crouch")
		var peak: float = 0.0
		for i: int in range(150):
			await get_tree().physics_frame
			peak = maxf(peak, player.clamor.level)
		print("[clamor] %-26s %8.2f %8.1f" % [
			case["name"], peak, peak * tuning.clamor_metres_per_unit,
		])
		Input.action_release("move_forward")
		Input.action_release("sprint")
		Input.action_release("crouch")
		for i: int in range(20):
			await get_tree().physics_frame

	# A swing that misses versus one that lands. DES-009 makes connecting the
	# loud part, which is what makes a fight expensive and a whiff cheap.
	player.position = Vector3(0, 0.1, 18)
	player.clamor.silence()
	player.stamina.refill()
	player.weapon.request_swing(player.stamina)
	var whiff: float = 0.0
	while player.weapon.is_busy():
		await get_tree().physics_frame
		whiff = maxf(whiff, player.clamor.level)
	print("[clamor] %-26s %8.2f %8.1f" % [
		"swing, missed", whiff, whiff * tuning.clamor_metres_per_unit])

	player.clamor.silence()
	player.clamor.add(tuning.clamor_swing + tuning.clamor_hit)
	var landed: float = player.clamor.level
	print("[clamor] %-26s %8.2f %8.1f" % [
		"swing, connected", landed, landed * tuning.clamor_metres_per_unit])

	print("[clamor] decay to silence from peak  %.1f s"
		% (tuning.clamor_maximum / tuning.clamor_decay))

	# Occlusion. Two listeners the same distance away, one straight through the
	# interior wall and one on a clear line through its doorway. If these come
	# back the same, walls are doing nothing and the debug outline is a circle
	# that happens to look convincing.
	# Both listeners sit just past the interior wall at z = 2, close enough that
	# nothing else in the gym is on either line — an earlier version aimed the
	# "clear" ray straight through the 30-degree ramp and read one wall of
	# penalty as a failure of the doorway.
	#
	# The level is chosen so the open radius is about 10 m: at maximum clamor
	# the radius dwarfs the penalty and everything is audible through
	# everything, which proves nothing.
	player.position = Vector3(0, 0.1, 6)
	player.clamor.silence()
	player.clamor.add(10.0 / tuning.clamor_metres_per_unit)
	await get_tree().physics_frame
	var open_at: Vector3 = Vector3(0, 1.2, -1)
	var walled_at: Vector3 = Vector3(-7, 1.2, -1)
	var ear: Vector3 = player.global_position + Vector3.UP * 1.2
	print("[clamor] distance to each listener   %.1f m / %.1f m" % [
		ear.distance_to(open_at), ear.distance_to(walled_at)])
	print("[clamor] radius in open air          %.1f m" % player.clamor.audible_radius())
	print("[clamor] reach through doorway       %.1f m" % ClamorSource.reach(
		player.get_world_3d(), ear, (open_at - ear).normalized(),
		player.clamor.audible_radius()))
	print("[clamor] reach through wall          %.1f m" % ClamorSource.reach(
		player.get_world_3d(), ear, (walled_at - ear).normalized(),
		player.clamor.audible_radius()))
	print("[clamor] heard through doorway       %s" % player.clamor.audible_at(open_at))
	print("[clamor] heard through wall          %s" % player.clamor.audible_at(walled_at))
	get_tree().quit()


func _spawn_enemies() -> void:
	for post: Vector3 in ENEMY_POSTS:
		var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
		enemy.position = post
		# Facing away from spawn, so approaching unseen is possible and the
		# vision cone is something a tester discovers by using it. Godot's
		# forward is -Z, and the player spawns at +Z, so the default rotation
		# already looks away — an earlier PI here turned every enemy around to
		# stare at the spawn point and made the gym start in ALERTED.
		enemy.rotation.y = 0.0
		_world.add_child(enemy)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		_reset()


func _on_player_died(_from: Node) -> void:
	# Dev convenience only. Death costing you the run is `M2-T05`; nothing here
	# should be mistaken for that system.
	_reset()


func _reset() -> void:
	_player.position = SPAWN
	_player.velocity = Vector3.ZERO
	_player.health.restore()
	_player.stamina.refill()
	_player.carried.kilograms = 0.0
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	_spawn_enemies()


func _combat_probe(player: Player) -> void:
	## Measure the attack anatomy and the awareness ladder.
	##
	## Feel is still a playtest question. What this answers is whether the
	## numbers DES-009 makes load-bearing are the numbers actually running:
	## that the telegraph clears the 250 ms floor in wall-clock time rather
	## than only in the resource, that swings commit, that a hit interrupts a
	## windup, and that the enemy can be walked past at all.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tuning: TuningProfile = Config.tuning
	var enemy: Enemy = get_tree().get_first_node_in_group("enemies") as Enemy

	# 1. Unaware is reachable and stable — combat must be avoidable (DES-013).
	for i: int in range(30):
		await get_tree().physics_frame
	print("[combat] initial enemy state       %s (want unaware)"
		% Enemy.State.keys()[enemy.state()].to_lower())

	# 2. Swing anatomy, measured in physics frames rather than trusted.
	player.position = Vector3(0, 0.1, 10)
	player.stamina.refill()
	var phases: Dictionary = {}
	var began: int = Time.get_ticks_msec()
	var seen: MeleeWeapon.Phase = player.weapon.phase()
	player.weapon.request_swing(player.stamina)
	while player.weapon.is_busy():
		await get_tree().physics_frame
		if player.weapon.phase() != seen:
			phases[str(seen)] = Time.get_ticks_msec() - began
			began = Time.get_ticks_msec()
			seen = player.weapon.phase()
	print("[combat] swing windup             %4d ms   expected %4d" % [
		int(phases.get(str(MeleeWeapon.Phase.WINDUP), 0)), int(tuning.swing_windup * 1000.0)])
	print("[combat] swing active             %4d ms   expected %4d" % [
		int(phases.get(str(MeleeWeapon.Phase.ACTIVE), 0)), int(tuning.swing_active * 1000.0)])

	# 3. The telegraph floor, measured. This is the one number DES-009 attaches
	#    a human-factors argument to, so a resource value alone is not enough.
	# In front of the enemy, inside its vision cone. Godot's forward is -Z, so
	# +Z would place the player behind it — which reads as a broken telegraph
	# rather than as a working one that was never triggered.
	player.position = enemy.global_position + Vector3(0, 0.1, -1.6)
	var telegraph_start: int = 0
	var telegraph_ms: int = 0
	for i: int in range(600):
		await get_tree().physics_frame
		var tinting: bool = enemy.is_telegraphing()
		if tinting and telegraph_start == 0:
			telegraph_start = Time.get_ticks_msec()
		elif not tinting and telegraph_start != 0:
			telegraph_ms = Time.get_ticks_msec() - telegraph_start
			break
	print("[combat] enemy telegraph          %4d ms   floor  250, expected %4d"
		% [telegraph_ms, int(tuning.enemy_telegraph * 1000.0)])

	# 4. Hits interrupt a windup — the reward for reading the telegraph.
	var interrupted: bool = false
	for i: int in range(600):
		await get_tree().physics_frame
		if enemy.is_telegraphing():
			enemy.take_test_hit(1.0)
			await get_tree().physics_frame
			interrupted = enemy.state() == Enemy.State.STAGGERED
			break
	print("[combat] hit interrupts windup    %s" % ("yes" if interrupted else "NO"))

	# 5. Lethality, in hits. DES-009's open M1 question is whether 2-3 hits from
	#    a common enemy kill a fresh player.
	print("[combat] enemy dies in            %4d swings" % [
		int(ceil(tuning.enemy_health / tuning.swing_damage))])
	print("[combat] player dies in           %4d hits" % [
		int(ceil(tuning.player_health / tuning.enemy_attack_damage))])

	# 6. An enemy closing on the player faces the way it is travelling.
	#    Nothing tested this before: every earlier check either left the enemy
	#    standing still or only cared about the telegraph, so a 180-degree
	#    error in the steering could sit there unnoticed while every other
	#    number came back correct.
	var chaser: Enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	player.position = chaser.global_position + Vector3(0, 0.1, -8)
	player.velocity = Vector3.ZERO
	var opened: float = player.global_position.distance_to(chaser.global_position)
	for i: int in range(90):
		await get_tree().physics_frame
	var toward: Vector3 = player.global_position - chaser.global_position
	toward.y = 0.0
	var alignment: float = chaser.facing().dot(toward.normalized())
	print("[combat] chaser faces its target   %+.2f  (+1 = forward, -1 = backwards)"
		% alignment)
	print("[combat] closed distance           %+.2f m" % [
		opened - player.global_position.distance_to(chaser.global_position)])

	# 7. Death resolves cleanly. This killed the run with "Function blocked
	#    during in/out signal" until Hitbox stopped toggling `monitoring` and
	#    the corpse's physics changes were deferred — death is reached from
	#    inside an area signal, which is exactly where Godot forbids both.
	enemy.take_test_hit(9999.0)
	for i: int in range(6):
		await get_tree().physics_frame
	print("[combat] death state              %s" % Enemy.State.keys()[enemy.state()].to_lower())
	get_tree().quit()


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
	##
	## Staged, and worth saying so: the shot swings first, so the frame catches
	## the weapon mid-arc and the clamor ring the swing produced. An idle frame
	## shows neither — clamor decays to nothing and the ring hides itself — and
	## would suggest both features were missing.
	_player.clamor.add(Config.tuning.clamor_swing * 2.0)
	_player.weapon.request_swing(_player.stamina)
	for i: int in range(6):
		await get_tree().physics_frame
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

	# An interior wall with a doorway, between the spawn and the enemies. This
	# is the occlusion test: sound should pour through the gap at full strength
	# and die crossing the wall, and the debug outline should show that shape
	# rather than a circle. It is also the smallest possible preview of what
	# `M1-T03` builds properly.
	_slab(Vector3(10, 4, 0.5), Vector3(-7, 2, 2))
	_slab(Vector3(10, 4, 0.5), Vector3(7, 2, 2))

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
