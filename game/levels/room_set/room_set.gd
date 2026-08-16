class_name RoomSet
extends Node3D

## `M1-T03` — one hand-built room set, no generation (`DES-015`).
##
## **Hand-built means the layout is authored, not that the geometry is typed by
## hand.** Every room, doorway and post below is an explicit constant; nothing
## is rolled. `DES-015`'s generator is `M4-T01` and is absent here.
##
## The point of building this now, before the generator exists, is that it makes
## two of `DES-015`'s central claims testable a milestone early — and both are
## claims about *shape*, which does not need procedural generation to evaluate:
##
## 1. **The walk out must not be a retrace** (`DES-015` Layer 1). The set is a
##    loop: entrance, two corridors, a junction, back round. If a cycle does not
##    feel better than a dead end at this scale, it will not feel better at
##    three floors, and we would want to know that before spending the
##    ⟨~1-2 months⟩ Layer 1 costs.
## 2. **At least one route bypasses every encounter** (ADR-032, `DES-013`). The
##    west corridor is deliberately empty. That guarantee is asserted by
##    `--route-probe` rather than eyeballed, because it is the rule the whole
##    avoid-combat design rests on.
##
## It also gives the clamor occlusion from ADR-074 its first real test. The gym
## has three ramps and a stub wall; this has corners, doorways and a room you
## cannot hear into, which is what occlusion is actually for.
##
## One Machine is authored (`DES-015` Layer 3): **Guardian & Prize** — a post on
## a prize, in a room with a single entrance, that will never come to you. It is
## the purest form of the M1 gate question: *did the tester choose the fight?*

const WALL_HEIGHT: float = 4.0
const WALL_THICK: float = 0.6
const DOOR_WIDTH: float = 2.4

const FLOOR_COLOUR: Color = Color(0.58, 0.57, 0.56)
const WALL_COLOUR: Color = Color(0.44, 0.43, 0.43)
const PRIZE_COLOUR: Color = Color(0.85, 0.66, 0.22)

const ENEMY_SCENE: PackedScene = preload("res://actors/enemies/enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")

## The authored layout. Each room is (min_x, max_x, min_z, max_z), and each
## doorway names the two rooms it joins so the loop is legible as data.
##   entrance ── west ──┐
##      │               ├── junction ── guardian (single door, committal)
##      └───── east ────┘        │
##                             exit
const ROOMS: Dictionary = {
	"entrance": [-8.0, 8.0, -2.0, 10.0],
	"west": [-12.0, -6.0, -18.0, -2.0],
	"east": [6.0, 12.0, -18.0, -2.0],
	"junction": [-12.0, 12.0, -26.0, -18.0],
	"guardian": [12.0, 22.0, -26.0, -16.0],
	"exit": [-3.0, 3.0, -32.0, -26.0],
}

## (room, side, centre-offset along that side). Sides: n = -Z, s = +Z, e = +X,
## w = -X. Every doorway is cut from both rooms it joins.
const DOORS: Array = [
	["entrance", "n", -7.0], ["west", "s", -7.0],      # entrance ↔ west
	["entrance", "n", 7.0], ["east", "s", 7.0],        # entrance ↔ east
	["west", "n", -9.0], ["junction", "s", -9.0],      # west ↔ junction
	["east", "n", 9.0], ["junction", "s", 9.0],        # east ↔ junction
	["junction", "e", -21.0], ["guardian", "w", -21.0],  # junction ↔ guardian
	["junction", "n", 0.0], ["exit", "s", 0.0],        # junction ↔ exit
]

## All three sit in the east corridor; the west corridor is empty by
## construction, and that is ADR-032's bypass route. The first draft put one in the junction,
## and `--route-probe` failed immediately: every route to the exit crosses the
## junction, so an enemy there means no clean route exists and ADR-032 is
## broken. Caught on the first run of the assertion, which is the argument for
## having written it.
##
## The fix is better than the bug. With the danger confined to one branch, the
## two halves of the loop mean different things — west is long and safe, east is
## short and held — which is the payoff `DES-015` Layer 1 claims a cycle gives
## you, rather than just two ways round.
const ENEMY_POSTS: Array[Vector3] = [
	Vector3(9.0, 0.1, -5.0),
	Vector3(9.0, 0.1, -10.5),
	Vector3(9.0, 0.1, -16.0),
]
const GUARDIAN_POST: Vector3 = Vector3(18.5, 0.1, -21.0)
const PRIZE_AT: Vector3 = Vector3(20.3, 0.6, -21.0)
const SPAWN: Vector3 = Vector3(0.0, 0.1, 8.0)

## Heavy enough that the walk out is genuinely worse ⟨tune⟩ — 40% of capacity,
## which is where `DES-005` Layer 1's speed penalty starts to bite. If taking
## the prize does not change how you get home, the Guardian room is decoration.
const PRIZE_KILOGRAMS: float = 16.0
const PRIZE_CLAMOR: float = 6.0
const PRIZE_REACH: float = 2.2

var _player: Player = null
var _prize: MeshInstance3D = null

@onready var _world: Node3D = $World


func _ready() -> void:
	_build_lighting()
	for name: String in ROOMS:
		_build_room(name)
	_build_prize()
	_spawn_actors()
	# What you emit and what they perceive, on the floor (ADR-078). This set has
	# corners and doorways, which is the only place occlusion has anything to
	# show — the gym it came from is mostly open ground.
	_world.add_child(DebugOverlays.new())
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-top="):
			_capture_top(arg.split("=", true, 1)[1])
		elif arg == "--route-probe":
			_route_probe()
		elif arg == "--prize-probe":
			_prize_probe()
		elif arg == "--hash":
			_print_hash()


## Print the world fingerprint and quit (`M1-T07`). Two processes given the
## same seed must print the same line; `tools/check_determinism.py` runs them
## and compares. Waits for physics to settle first, because a body that has not
## finished resolving its first frame reports a position that is *nearly*
## right, which is exactly the kind of near-miss this must not tolerate.
func _print_hash() -> void:
	for i: int in range(8):
		await get_tree().physics_frame
	print("[hash] entries %d" % WorldHash.entries(self).size())
	print("[hash] %s" % WorldHash.digest(self))
	get_tree().quit()


## Does taking the prize actually cost anything?
##
## The Guardian & Prize machine only poses a question if the answer has a
## price. This measures the price rather than asserting it: speed and audible
## radius before and after, on the same player, seconds apart.
func _prize_probe() -> void:
	_player.global_position = PRIZE_AT + Vector3(0, 0.1, 2.0)
	for i: int in range(4):
		await get_tree().physics_frame

	var before_speed: float = await _walk_speed()
	var before_heard: float = _player.clamor.audible_radius()
	_take_prize()
	var after_speed: float = await _walk_speed()
	var after_heard: float = _player.clamor.audible_radius()

	print("[set] walk speed   %5.2f → %5.2f m/s   (%+.0f%%)" % [
		before_speed, after_speed,
		(after_speed / before_speed - 1.0) * 100.0 if before_speed > 0.0 else 0.0])
	print("[set] heard from   %5.1f → %5.1f m      at the moment of lifting it" % [
		before_heard, after_heard])
	print("[set] carrying     %5.1f kg (%.0f%% laden)" % [
		_player.carried.kilograms, _player.carried.encumbrance() * 100.0])
	get_tree().quit(0 if after_speed < before_speed else 1)


func _walk_speed() -> float:
	Input.action_press("move_forward")
	for i: int in range(50):
		await get_tree().physics_frame
	var speed: float = _player.planar_speed()
	Input.action_release("move_forward")
	for i: int in range(20):
		await get_tree().physics_frame
	return speed


# ── geometry ──────────────────────────────────────────────────────────────


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
	_world.add_child(node)


## Doorway centres on one side of one room, so a wall can be built around them.
func _gaps(room: String, side: String) -> Array[float]:
	var found: Array[float] = []
	for door: Array in DOORS:
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
		var opening_from: float = gap - DOOR_WIDTH * 0.5
		var opening_to: float = gap + DOOR_WIDTH * 0.5
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
		var size: Vector3 = (Vector3(length, WALL_HEIGHT, WALL_THICK) if horizontal
			else Vector3(WALL_THICK, WALL_HEIGHT, length))
		var centre: Vector3 = (Vector3(middle, WALL_HEIGHT * 0.5, fixed) if horizontal
			else Vector3(fixed, WALL_HEIGHT * 0.5, middle))
		_slab(size, centre, WALL_COLOUR)


func _build_room(name: String) -> void:
	var rect: Array = ROOMS[name]
	var min_x: float = float(rect[0])
	var max_x: float = float(rect[1])
	var min_z: float = float(rect[2])
	var max_z: float = float(rect[3])

	_slab(Vector3(max_x - min_x, 0.5, max_z - min_z),
		Vector3((min_x + max_x) * 0.5, -0.25, (min_z + max_z) * 0.5), FLOOR_COLOUR)

	_wall(name, "n", min_z, min_x, max_x, true)
	_wall(name, "s", max_z, min_x, max_x, true)
	_wall(name, "w", min_x, min_z, max_z, false)
	_wall(name, "e", max_x, min_z, max_z, false)


## The Prize. Gold is the only saturated colour in the game (`ART-005`), so the
## one thing worth dying for is also the only thing on screen with a hue.
##
## **It has to cost something or the Guardian room is scenery.** The first
## version was a gold block you could walk to, and a playtester did exactly
## that and asked what they were supposed to do — which is ADR-064's complaint
## about stubs, arriving as feedback. Taking it now makes you heavier and
## louder, which is the whole greed loop in miniature and needs no system that
## does not already exist (`DES-005` Layer 1).
##
## Not the inventory. `M2-T01` builds loot with real weight, slots and value;
## this is one object with one consequence, complete in itself.
func _build_prize() -> void:
	_prize = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.2, 1.2, 1.2)
	var material := StandardMaterial3D.new()
	material.albedo_color = PRIZE_COLOUR
	material.roughness = 0.4
	_prize.mesh = mesh
	_prize.material_override = material
	_prize.position = PRIZE_AT
	_world.add_child(_prize)


func _process(_delta: float) -> void:
	if _prize == null or _player == null:
		return
	var near: bool = _player.global_position.distance_to(PRIZE_AT) <= PRIZE_REACH
	# Pulse while in reach. A prompt would need the HUD that `M4-T05` builds;
	# the object drawing attention to itself is free and needs no text.
	var pulse: float = 1.0 if not near else 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.25
	(_prize.material_override as StandardMaterial3D).albedo_color = PRIZE_COLOUR * pulse
	if near and Input.is_action_just_pressed("interact"):
		_take_prize()


func _take_prize() -> void:
	_player.carried.kilograms += PRIZE_KILOGRAMS
	# Lifting a hoard-piece off stone is loud. This is the moment the Guardian
	# gets its chance, which is what makes taking it a decision rather than a
	# formality.
	_player.clamor.add(PRIZE_CLAMOR)
	_prize.queue_free()
	_prize = null
	print("[set] prize taken: +%.0f kg, the room heard it" % PRIZE_KILOGRAMS)


func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 32, 0)
	sun.light_energy = 0.9
	_world.add_child(sun)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.16, 0.16, 0.18)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.55, 0.60)
	environment.ambient_light_energy = 0.85
	env.environment = environment
	_world.add_child(env)


func _spawn_actors() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	_player.position = SPAWN
	add_child(_player)

	for post: Vector3 in ENEMY_POSTS:
		var enemy := ENEMY_SCENE.instantiate() as Enemy
		enemy.position = post
		_world.add_child(enemy)

	# The Guardian faces its prize's doorway and never leaves the room.
	var guardian := ENEMY_SCENE.instantiate() as Enemy
	guardian.position = GUARDIAN_POST
	_world.add_child(guardian)


# ── the guarantee, asserted rather than eyeballed ─────────────────────────


func _route_probe() -> void:
	## ADR-032: at least one route from entrance to exit bypasses every
	## encounter on it. Checked by walking the authored room graph, not by
	## pathfinding — the claim is about the *layout*, and a navmesh query would
	## test the navmesh instead.
	var enemy_rooms: Dictionary = {}
	for post: Vector3 in ENEMY_POSTS + [GUARDIAN_POST]:
		enemy_rooms[_room_at(post)] = true

	var routes: Array = _routes("entrance", "exit", [])
	var clean: Array = []
	for route: Array in routes:
		var safe: bool = true
		for room: String in route:
			if enemy_rooms.has(room):
				safe = false
		if safe:
			clean.append(route)

	print("[set] routes entrance→exit      %d" % routes.size())
	print("[set] rooms holding enemies     %s" % ", ".join(enemy_rooms.keys()))
	for route: Array in routes:
		print("[set]   %s%s" % [" → ".join(route),
			"   (clean)" if route in clean else ""])
	print("[set] ADR-032 bypass exists     %s" % ("yes" if clean.size() > 0 else "NO"))
	# A cycle means at least two distinct routes; one route is a corridor.
	print("[set] DES-015 loop, not a tree  %s" % ("yes" if routes.size() > 1 else "NO"))
	get_tree().quit(0 if clean.size() > 0 and routes.size() > 1 else 1)


func _room_at(point: Vector3) -> String:
	for name: String in ROOMS:
		var rect: Array = ROOMS[name]
		if (point.x >= float(rect[0]) and point.x <= float(rect[1])
				and point.z >= float(rect[2]) and point.z <= float(rect[3])):
			return name
	return "(outside)"


func _neighbours(room: String) -> Array[String]:
	## Doorways are authored as two entries sharing a side offset, one per room,
	## so two rooms are joined when both name the same opening.
	var found: Array[String] = []
	for door: Array in DOORS:
		if door[0] != room:
			continue
		for other: Array in DOORS:
			if other[0] != room and is_equal_approx(float(other[2]), float(door[2])):
				if not found.has(String(other[0])):
					found.append(String(other[0]))
	return found


func _routes(from: String, to: String, visited: Array) -> Array:
	if from == to:
		return [visited + [from]]
	var found: Array = []
	for next: String in _neighbours(from):
		if visited.has(next) or next == from:
			continue
		found += _routes(next, to, visited + [from])
	return found


func _capture_top(path: String) -> void:
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 46.0
	camera.position = Vector3(4, 40, -10)
	camera.rotation_degrees = Vector3(-90, 0, 0)
	add_child(camera)
	camera.make_current()
	_player.show_ink(false)
	for i: int in range(4):
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
