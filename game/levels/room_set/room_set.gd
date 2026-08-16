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

## The network boundary (`M1-T05`). Levels ask it for actors and never
## instantiate one themselves, which is what keeps `TEC-004`'s "the boundary
## already exists" true rather than aspirational. A solo launch runs the same
## path on Godot's offline peer.
const SESSION_SCENE: PackedScene = preload("res://systems/net/coop_session.tscn")

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

## Where the party starts — one point per player, a stride apart across the
## entrance. A single shared point would have two people begin the run standing
## inside each other, which reads as a replication bug on the first frame
## anyone sees.
const SPAWNS: Array[Vector3] = [
	Vector3(-1.2, 0.1, 8.0), Vector3(1.2, 0.1, 8.0),
	Vector3(-3.6, 0.1, 8.0), Vector3(3.6, 0.1, 8.0),
]

## Heavy enough that the walk out is genuinely worse ⟨tune⟩ — 40% of capacity,
## which is where `DES-005` Layer 1's speed penalty starts to bite. If taking
## the prize does not change how you get home, the Guardian room is decoration.
const PRIZE_KILOGRAMS: float = 16.0
const PRIZE_CLAMOR: float = 6.0
const PRIZE_REACH: float = 2.2

## Latency slack on the host's reach check. A client presses `interact` from
## where it believes it is standing; the host tests against a transform that
## arrived up to a replication interval ago. At walk speed that is about
## 0.2 m, so half a metre is generous without letting anyone reach the Prize
## from outside the room.
const REACH_SLACK: float = 0.5

## Godot's host is always peer 1, offline peer included.
const HOST_PEER: int = 1

var _prize: MeshInstance3D = null
var _session: CoopSession = null

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
		elif arg.begins_with("--coop-probe="):
			_coop_probe(arg.split("=", true, 1)[1])


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
	var player: Player = _session.local_player()
	player.teleport(PRIZE_AT + Vector3(0, 0.1, 2.0), 0.0)
	for i: int in range(4):
		await get_tree().physics_frame

	var before_speed: float = await _walk_speed(player)
	var before_heard: float = player.clamor.audible_radius()
	# Through the same host-validated path a real pickup takes, not around it:
	# a probe that reached past the authority check would stop measuring the
	# thing that ships.
	_grant_prize(HOST_PEER)
	var after_speed: float = await _walk_speed(player)
	var after_heard: float = player.clamor.audible_radius()

	print("[set] walk speed   %5.2f → %5.2f m/s   (%+.0f%%)" % [
		before_speed, after_speed,
		(after_speed / before_speed - 1.0) * 100.0 if before_speed > 0.0 else 0.0])
	print("[set] heard from   %5.1f → %5.1f m      at the moment of lifting it" % [
		before_heard, after_heard])
	print("[set] carrying     %5.1f kg (%.0f%% laden)" % [
		player.carried.kilograms, player.carried.encumbrance() * 100.0])
	get_tree().quit(0 if after_speed < before_speed else 1)


# ── the co-op guarantee, measured rather than eyeballed ──────────────────


## Seconds of each phase, and where the client stands to do it. The strike
## point is 1.5 m from the first post, *behind* the enemy — Godot's forward is
## -Z and the posts face -Z, so approaching from +Z keeps it unaware and
## standing still, which is what makes "one swing, 25 damage" a fixed number
## rather than a race against a body walking out of the arc.
const PROBE_WALK_FROM: Vector3 = Vector3(0.0, 0.1, 6.0)
const PROBE_STRIKE_FROM: Vector3 = Vector3(9.0, 0.1, -3.5)

## Far enough down the same corridor that the struck enemy has to *run* to
## reach it, and does not arrive before the probe samples.
##
## This exists because of a check that did not fire. The first version left the
## client standing next to the enemy, where an alerted enemy stops and attacks
## — velocity zero. So "enemies are host-simulated" passed happily with the
## host gate deleted and the client simulating its own copy, because a
## stationary enemy looks identical either way. A check that cannot fail is not
## a check.
const PROBE_RETREAT_TO: Vector3 = Vector3(9.0, 0.1, -16.0)
const PROBE_TIMEOUT_MSEC: int = 15000

var _probe_clamor_peak: Dictionary = {}
var _probe_walk_clamor: Dictionary = {}
var _probe_walked: Dictionary = {}
var _probe_heights: Dictionary = {}
var _probe_connect_seconds: float = 0.0
var _probe_ending: bool = false
var _probe_damage_events: int = 0


## `M1-T05`: does the host own the world, and does the client see it?
##
## Runs in **both** processes; each writes what it can see, and
## `tools/run_coop.py` compares the two files. That shape is the whole point —
## every claim about replication is a claim that two processes agree, and a
## probe that interrogated only one of them would pass with the cable pulled.
##
## Only the client acts. The host drives nothing and presses nothing, so every
## number it reports about the client's body arrived over the wire.
##
## Phases are wall-clock from the moment this process can see both bodies. On
## loopback the two get there within a frame of each other and each phase is
## most of a second, so no shared clock is needed and none is faked.
## **The client says when it is over, and the host samples on that word.**
##
## Sampling on its own clock cost a full debugging round: the two processes
## finish within milliseconds of each other, the client quits first, the host
## frees the departed body — and the host's report then shows a party of one.
## A clean *disconnect*, reported as a replication failure. The client writes
## its own file, tells the host to write its own while it is demonstrably still
## connected, and only then drops.
func _coop_probe(out: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var host: bool = multiplayer.is_server()
	_probe_connect_seconds = await _await_party()
	var mine: Player = _session.local_player()

	# Count damage *events on this peer*, which is the only thing that can tell
	# host-authoritative damage from damage that merely agrees.
	#
	# Comparing hit points cannot do it: a client that resolved the swing
	# itself would arrive at the same 35 as the host and the replicated value
	# would overwrite it with itself. `Health.damaged` fires only from
	# `apply_damage`, and replication assigns `current` directly — so a client
	# that has correctly refused to resolve anything counts **zero**, and a
	# client that resolved its own copy counts one. That is the assertion.
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).health.damaged.connect(_on_probe_damage)

	# 1. The client walks. Nothing else in the level moves, so the host's view
	#    of this body is replication and nothing but.
	if not host:
		mine.teleport(PROBE_WALK_FROM, 0.0)
	await _hold(0.5)
	var before: Dictionary = _probe_positions()
	# Clamor sampled from here, so the walk-phase peak contains footsteps and
	# nothing else. It has to be isolated: with the whole run's peak, a swing
	# alone satisfies "the host heard the client", and the check passed even
	# with the host deriving movement noise for its own body only — which is
	# the exact failure it exists to catch.
	_probe_clamor_peak = {}
	if not host:
		Input.action_press("move_forward")
	await _hold(1.0)
	if not host:
		Input.action_release("move_forward")
	await _hold(0.4)
	_probe_walked = _probe_drift(before, _probe_positions())
	_probe_walk_clamor = _probe_clamor_peak.duplicate()

	# 2. The client crouches. Two things at once, and both need to hold: the
	#    stance has to replicate, *and* the two bodies have to own separate
	#    collision shapes — `player.tscn`'s capsule is a scene sub-resource,
	#    which Godot shares between instances by default, so before it was
	#    marked `resource_local_to_scene` one player crouching resized the
	#    other player's collider and hurtbox on every peer.
	if not host:
		Input.action_press("crouch")
	await _hold(0.8)
	_probe_heights = _probe_capsule_heights()
	if not host:
		Input.action_release("crouch")
	await _hold(0.5)

	# 3. The client swings once at the first post. The client's own hitbox is
	#    inert; if the enemy loses exactly one swing of health on both peers,
	#    the host resolved it, resolved it once, and told the client.
	if not host:
		mine.teleport(PROBE_STRIKE_FROM, 0.0)
	await _hold(0.6)
	if not host:
		mine.weapon.request_swing(mine.stamina)
	await _hold(0.8)

	# 4. The client backs off down the corridor, and the enemy it just hit
	#    comes after it. Sampled mid-chase on purpose: a client that is
	#    correctly running no enemy AI has never integrated a velocity, so its
	#    copies read exactly zero while the host's read metres per second.
	#    That difference is what proves the simulation lives in one process.
	if not host:
		mine.teleport(PROBE_RETREAT_TO, 0.0)
	await _hold(1.5)

	if host:
		await _await_probe_end()
		_probe_write(out, _probe_report(true))
	else:
		_probe_write(out, _probe_report(false))
		_end_probe.rpc_id(HOST_PEER)
		# Long enough for the host to sample while this peer is still in its
		# party, and short enough that a stalled host does not hang CI.
		await _hold(0.5)
	get_tree().quit()


@rpc("any_peer", "reliable")
func _end_probe() -> void:
	if multiplayer.is_server():
		_probe_ending = true


## Waits for the client's word, but not forever. On a timeout the host writes
## the report anyway, and it fails loudly with `players_seen: 1` — a silent
## pass would be far worse than a noisy failure at a gate like this.
func _await_probe_end() -> void:
	var began: int = Time.get_ticks_msec()
	while not _probe_ending and Time.get_ticks_msec() - began < PROBE_TIMEOUT_MSEC:
		await get_tree().physics_frame


func _probe_report(host: bool) -> Dictionary:
	return {
		"role": "host" if host else "client",
		"peer": multiplayer.get_unique_id(),
		"connect_seconds": _probe_connect_seconds,
		"players_seen": _session.players().size(),
		"enemies_seen": get_tree().get_nodes_in_group("enemies").size(),
		"positions": _probe_positions(),
		"walked": _probe_walked,
		"capsule_heights": _probe_heights,
		"enemy_health": _probe_enemy_health(),
		"enemy_positions": _probe_enemy_positions(),
		"enemy_speeds": _probe_enemy_speeds(),
		"clamor_peak": _probe_clamor_peak,
		"walk_clamor_peak": _probe_walk_clamor,
		"damage_events": _probe_damage_events,
		# The numbers the damage assertion is made of, carried in the report
		# rather than repeated in the harness. A ⟨tune⟩ value that CI has its
		# own copy of is a ⟨tune⟩ value nobody can change.
		"swing_damage": Config.tuning.swing_damage,
		"enemy_max_health": Config.tuning.enemy_health,
		"godot": Engine.get_version_info()["string"],
	}


## Wait until both bodies exist here. A timeout rather than a forever loop:
## a probe that hangs is a CI job that hangs, and the report it fails to write
## is indistinguishable from a crash. Timing out writes `players_seen: 1`,
## which fails loudly and says why.
func _await_party() -> float:
	var began: int = Time.get_ticks_msec()
	while _session.players().size() < 2 or _session.local_player() == null:
		await get_tree().physics_frame
		if Time.get_ticks_msec() - began > PROBE_TIMEOUT_MSEC:
			break
	return float(Time.get_ticks_msec() - began) / 1000.0


## Advance real time, sampling clamor as it goes. Peak rather than final,
## because noise decays: by the end of the run every level is back to zero and
## a final reading would prove only that time passes.
func _hold(seconds: float) -> void:
	var until: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().physics_frame
		for player: Player in _session.players():
			_probe_clamor_peak[player.name] = maxf(
				float(_probe_clamor_peak.get(player.name, 0.0)), player.clamor.level)


func _on_probe_damage(_amount: float, _remaining: float, _from: Node) -> void:
	_probe_damage_events += 1


func _probe_positions() -> Dictionary:
	var out: Dictionary = {}
	for player: Player in _session.players():
		var at: Vector3 = player.global_position
		out[player.name] = [at.x, at.y, at.z]
	return out


func _probe_drift(before: Dictionary, after: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: String in after:
		if not before.has(key):
			continue
		var a: Array = before[key]
		var b: Array = after[key]
		out[key] = Vector3(a[0], a[1], a[2]).distance_to(Vector3(b[0], b[1], b[2]))
	return out


func _probe_capsule_heights() -> Dictionary:
	var out: Dictionary = {}
	for player: Player in _session.players():
		out[player.name] = player.capsule_height()
	return out


func _probe_enemy_health() -> Dictionary:
	var out: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		out[node.name] = (node as Enemy).health.current
	return out


func _probe_enemy_positions() -> Dictionary:
	var out: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var at: Vector3 = (node as Enemy).global_position
		out[node.name] = [at.x, at.y, at.z]
	return out


## Horizontal speed per enemy. Zero on a client is not a rounding artefact:
## `velocity` is never replicated and never assigned there, so a client that
## has correctly refused to simulate reports exact zeroes.
func _probe_enemy_speeds() -> Dictionary:
	var out: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var moving: Vector3 = (node as Enemy).velocity
		out[node.name] = Vector2(moving.x, moving.z).length()
	return out


func _probe_write(path: String, report: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("[coop-probe] could not write %s (%d)" % [
			path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("[coop-probe] %s saw %d player(s), %d enemy/ies" % [
		report["role"], report["players_seen"], report["enemies_seen"]])


func _walk_speed(player: Player) -> float:
	Input.action_press("move_forward")
	for i: int in range(50):
		await get_tree().physics_frame
	var speed: float = player.planar_speed()
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
	if _prize == null:
		return
	var player: Player = _session.local_player()
	if player == null:
		return
	var near: bool = player.global_position.distance_to(PRIZE_AT) <= PRIZE_REACH
	# Pulse while in reach. A prompt would need the HUD that `M4-T05` builds;
	# the object drawing attention to itself is free and needs no text.
	var pulse: float = 1.0 if not near else 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.25
	(_prize.material_override as StandardMaterial3D).albedo_color = PRIZE_COLOUR * pulse
	if near and Input.is_action_just_pressed("interact"):
		_reach_for_prize()


## Loot is host-authoritative and **pickup is a host-validated request**
## (`TEC-004`), which is what this is — not ceremony.
##
## The client says only "I am reaching for it". The host decides whether they
## were close enough, using its own copy of where they are, and it is the host
## that adds the weight and makes the noise. Two players lunging for the same
## Prize therefore cannot both get it: the second request finds `_prize` gone.
func _reach_for_prize() -> void:
	if multiplayer.is_server():
		_grant_prize(multiplayer.get_unique_id())
	else:
		_request_prize.rpc_id(HOST_PEER)


@rpc("any_peer", "reliable")
func _request_prize() -> void:
	if not multiplayer.is_server():
		return
	_grant_prize(multiplayer.get_remote_sender_id())


func _grant_prize(peer: int) -> void:
	if _prize == null:
		return
	var player: Player = _session.player_for(peer)
	if player == null:
		return
	if player.global_position.distance_to(PRIZE_AT) > PRIZE_REACH + REACH_SLACK:
		return
	player.carried.kilograms += PRIZE_KILOGRAMS
	# Lifting a hoard-piece off stone is loud. This is the moment the Guardian
	# gets its chance, which is what makes taking it a decision rather than a
	# formality.
	player.clamor.add(PRIZE_CLAMOR)
	_clear_prize.rpc()
	print("[set] prize taken by peer %d: +%.0f kg, the room heard it" % [
		peer, PRIZE_KILOGRAMS])


## The Prize is authored geometry, so every peer already built one and every
## peer has to remove its own. `call_local` so the host runs the same line.
@rpc("authority", "call_local", "reliable")
func _clear_prize() -> void:
	if _prize == null:
		return
	_prize.queue_free()
	_prize = null


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
	_session = SESSION_SCENE.instantiate() as CoopSession
	_session.spawn_points = SPAWNS
	add_child(_session)

	# Host-only, and silently so: on a client these calls do nothing and the
	# host's spawns arrive on their own. The level does not need to know which
	# process it is, which is the property that keeps every future level from
	# growing a networking branch.
	for post: Vector3 in ENEMY_POSTS:
		_session.spawn_enemy(post)
	# The Guardian faces its prize's doorway and never leaves the room.
	_session.spawn_enemy(GUARDIAN_POST)


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
	_session.local_player().show_ink(false)
	for i: int in range(4):
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
