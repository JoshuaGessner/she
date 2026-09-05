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

## The network boundary (`M1-T05`). The gym is a solo feel harness and will
## almost always run with nobody connected — which on Godot's offline peer is
## a host with zero peers, the same code path. It goes through the session
## anyway, because two ways to put a player in a level is the parallel path
## ADR-064 bans, and the one nobody exercises is the one that rots.
const SESSION_SCENE: PackedScene = preload("res://systems/net/coop_session.tscn")

## Godot's host is always peer 1, offline peer included.
const HOST_PEER: int = 1

const SPAWNS: Array[Vector3] = [
	Vector3(-1.2, 0.1, 10), Vector3(1.2, 0.1, 10),
	Vector3(-3.6, 0.1, 10), Vector3(3.6, 0.1, 10),
]

## Where the enemies stand. Spread out and away from spawn on purpose: the M1
## gate question is whether a tester *chooses* to swing at something they could
## have walked past, and an enemy standing on the spawn point answers it for
## them.
const ENEMY_POSTS: Array[Vector3] = [
	Vector3(-3, 0.1, -2), Vector3(3.5, 0.1, -9), Vector3(-7, 0.1, -14),
]

@onready var _world: Node3D = $World

var _session: CoopSession = null


func _ready() -> void:
	_build()
	_session = SESSION_SCENE.instantiate() as CoopSession
	_session.spawn_points = SPAWNS
	_session.player_spawned.connect(_on_player_spawned)
	add_child(_session)
	# The ring and the vision cones now live in a component, so the room set
	# gets them too (ADR-078). It finds the player and the enemies by group.
	_world.add_child(DebugOverlays.new())
	_spawn_enemies()
	var player: Player = _session.local_player()
	# Once, at startup. This loop briefly ended up inside _process() during a
	# refactor and re-entered the probe every frame — 84,000 lines of header and
	# no measurements, which is a good argument for reading the whole function
	# after moving anything into the middle of one.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture(player, arg.split("=", true, 1)[1])
		elif arg == "--probe":
			_probe(player)
		elif arg == "--combat-probe":
			_combat_probe(player)
		elif arg == "--clamor-probe":
			_clamor_probe(player)
		elif arg == "--fight-probe":
			_fight_probe(player)
		elif arg == "--swarm-probe":
			_swarm_probe(player)
		elif arg.begins_with("--capture-top="):
			_capture_top(player, arg.split("=", true, 1)[1])
		elif arg == "--lifecycle-probe":
			_lifecycle_probe()


## Dev convenience only. Death costing you the run is `M2-T05`; nothing here
## should be mistaken for that system. Connected per body as it spawns, since
## a body now arrives when a peer does rather than at level start.
func _on_player_spawned(player: Player) -> void:
	player.health.died.connect(_on_player_died)
	# **The gym arms what it spawns** (`M3-T07`). There is no class select in
	# here and slots mean an unsworn body holds nothing, so a swing probe would
	# be measuring empty hands. The seax is the weapon `DES-009`'s M1 protocol
	# was written against and the one the profile's old numbers described.
	if player.equipment != null and player.equipment.is_empty():
		player.equipment.equip(ItemInstance.of(
			ItemCatalogue.by_id(&"wpn_seax"), 0))


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
func _capture_top(player: Player, path: String) -> void:
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
	player.show_ink(false)
	# North of the interior wall, and loud enough to reach past it but not so
	# loud the footprint leaves the room — at maximum clamor the outline is
	# wider than the gym and the doorway notch is off-screen.
	player.teleport(Vector3(0, 0.1, 9), 0.0)
	player.clamor.add(14.0 / Config.tuning.clamor_metres_per_unit)
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
		player.teleport(Vector3(0, 0.1, 18), 0.0)
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
	player.teleport(Vector3(0, 0.1, 18), 0.0)
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
	var seax: ItemResource = ItemCatalogue.by_id(&"wpn_seax")
	var blade := seax.first_trait(WieldableTrait) as WieldableTrait
	player.clamor.add(blade.clamor_swing + blade.clamor_hit)
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
	player.teleport(Vector3(0, 0.1, 6), 0.0)
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
		# Facing away from spawn, so approaching unseen is possible and the
		# vision cone is something a tester discovers by using it. Godot's
		# forward is -Z, and the player spawns at +Z, so a yaw of zero already
		# looks away — an earlier PI here turned every enemy around to stare at
		# the spawn point and made the gym start in ALERTED.
		_session.spawn_enemy(post, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		_ask_for_reset()


## Resetting the gym respawns enemies and moves every body, and both of those
## are host decisions (`TEC-004`). A client presses the same key and asks.
func _ask_for_reset() -> void:
	if multiplayer.is_server():
		_reset()
	else:
		_request_reset.rpc_id(HOST_PEER)


@rpc("any_peer", "reliable")
func _request_reset() -> void:
	if multiplayer.is_server():
		_reset()


func _on_player_died(_from: Node) -> void:
	_reset()


func _reset() -> void:
	if not multiplayer.is_server():
		return
	var index: int = 0
	for player: Player in _session.players():
		# `teleport` rather than assigning the position: the transform belongs
		# to whoever is playing that body, so the host has to ask, or the next
		# packet drags them straight back to where they died.
		player.teleport(SPAWNS[index % SPAWNS.size()], 0.0)
		player.health.restore()
		player.stamina.refill()
		player.carried.kilograms = 0.0
		index += 1
	_session.clear_enemies()
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
	var failures: int = 0

	# 1. Unaware is reachable and stable — combat must be avoidable (DES-013).
	for i: int in range(30):
		await get_tree().physics_frame
	print("[combat] initial enemy state       %s (want unaware)"
		% Enemy.State.keys()[enemy.state()].to_lower())

	# 2. Swing anatomy, measured in physics frames rather than trusted.
	player.teleport(Vector3(0, 0.1, 10), 0.0)
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
	# **Expected from the weapon in the hand** (`M3-T07`). These read the
	# profile until slots existed; the profile no longer has an opinion about
	# how fast a knife swings, because a knife does.
	var edge: WieldableTrait = player.weapon.held()
	print("[combat] swing windup             %4d ms   expected %4d" % [
		int(phases.get(str(MeleeWeapon.Phase.WINDUP), 0)), int(edge.windup * 1000.0)])
	print("[combat] swing active             %4d ms   expected %4d" % [
		int(phases.get(str(MeleeWeapon.Phase.ACTIVE), 0)), int(edge.active * 1000.0)])

	# 3. The telegraph floor, measured. This is the one number DES-009 attaches
	#    a human-factors argument to, so a resource value alone is not enough.
	# In front of the enemy, inside its vision cone. Godot's forward is -Z, so
	# +Z would place the player behind it — which reads as a broken telegraph
	# rather than as a working one that was never triggered.
	player.teleport(enemy.global_position + Vector3(0, 0.1, -1.6), 0.0)
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

	# 4. A **light** hit does not interrupt a windup (ADR-194).
	#
	# This row asserted the opposite until poise landed, and called it *"the
	# reward for reading the telegraph"* — which measured out backwards: if a
	# hit interrupts at any point in the cycle, reading the telegraph is the
	# strictly worse alternative to swinging first. It then sat here printing
	# **NO** and asserting nothing, green, for as long as it took somebody to
	# read it. A bare print is not a check.
	#
	# `--fight-probe` owns the whole rule and plants every half of it. What is
	# kept here is the one line this probe is placed to see: a hit carrying no
	# stagger, landing mid-windup, must **not** stop the swing.
	var interrupted: bool = false
	for i: int in range(600):
		await get_tree().physics_frame
		if enemy.is_telegraphing():
			enemy.take_test_hit(1.0)
			await get_tree().physics_frame
			interrupted = enemy.state() == Enemy.State.STAGGERED
			break
	print("[combat] light hit interrupts     %s (want no — ADR-194)"
		% ("YES" if interrupted else "no"))
	if interrupted:
		print("[combat] FAIL a stagger-free hit stopped a windup — that is the "
			+ "unconditional stagger ADR-194 removed, and it makes spamming a "
			+ "light weapon strictly better than reading the telegraph")
		failures += 1

	# 5. Lethality, in hits. DES-009's open M1 question is whether 2-3 hits from
	#    a common enemy kill a fresh player.
	print("[combat] enemy dies in            %4d swings" % [
		int(ceil(tuning.enemy_health / edge.damage))])
	print("[combat] player dies in           %4d hits" % [
		int(ceil(tuning.player_health / tuning.enemy_attack_damage))])

	# 6. An enemy closing on the player faces the way it is travelling.
	#    Nothing tested this before: every earlier check either left the enemy
	#    standing still or only cared about the telegraph, so a 180-degree
	#    error in the steering could sit there unnoticed while every other
	#    number came back correct.
	var chaser: Enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	player.teleport(chaser.global_position + Vector3(0, 0.1, -8), 0.0)
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

	# 8. **The guard** (`M3-T02`, `DES-009`). Blocking reduces a blow, costs
	#    stamina, and never negates — the third clause is the one the whole
	#    combat model rests on, since a guard that made you invulnerable would
	#    replace the positional defence `DES-009` has instead of i-frames.
	#
	#    Damage is pushed through `_on_hurt`'s own funnel rather than through a
	#    hurtbox, because the question is what the *guard* does to a blow, not
	#    whether a hitbox finds a body — `--toll-probe` already asks that.
	var problems: PackedStringArray = PackedStringArray()
	player.health.restore()
	player.stamina.refill()
	player.blocking = false
	var open_health: float = player.health.current
	player._on_hurt(30.0, null)
	var unguarded: float = open_health - player.health.current

	player.health.restore()
	player.stamina.refill()
	player.blocking = true
	var guarded_stamina: float = player.stamina.current
	var guarded_health: float = player.health.current
	player._on_hurt(30.0, null)
	var guarded: float = guarded_health - player.health.current
	var spent_stamina: float = guarded_stamina - player.stamina.current
	print("[combat] blocked 30 damage       %.0f through vs %.0f open, %.0f stamina"
		% [guarded, unguarded, spent_stamina])
	if guarded >= unguarded:
		problems.append(("a raised guard stopped nothing (%.0f through vs %.0f "
			+ "open) — `DES-009` says a block reduces damage, and a shield that "
			+ "does not is a stamina cost with no purchase")
			% [guarded, unguarded])
	if guarded <= 0.0:
		problems.append(("a raised guard negated the blow entirely — `DES-009` "
			+ "says it *doesn't negate it*, and invulnerability turns every "
			+ "fight into a holding contest instead of a positional one"))
	if spent_stamina <= 0.0:
		problems.append(("blocking cost no stamina — `DES-009` puts swinging, "
			+ "blocking, sprinting and climbing on one pool precisely so a "
			+ "player who blocks everything cannot also run"))

	# An empty pool cannot hold a guard up. The button does nothing rather than
	# producing a shield that flickers, which nobody could read.
	player.stamina.spend(player.stamina.current)
	player.health.restore()
	var empty_health: float = player.health.current
	player.blocking = true
	player._on_hurt(30.0, null)
	var on_empty: float = empty_health - player.health.current
	print("[combat] guard on empty stamina  %.0f through (want %.0f)"
		% [on_empty, unguarded])
	if not is_equal_approx(on_empty, unguarded):
		problems.append(("a guard still worked at %.0f stamina — below "
			+ "`block_stamina_minimum` there is nothing to hold it up with, and "
			+ "a shield that works for free at empty is the resource cost gone")
			% player.stamina.current)

	for problem: String in problems:
		printerr("[combat] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


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
		player.teleport(Vector3(0, 0.1, 18), 0.0)
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


func _capture(player: Player, path: String) -> void:
	## Screenshot and quit. Building a gym without looking at it is how the
	## ink spike ended up with its camera standing inside a pillar.
	##
	## Staged, and worth saying so: the shot swings first, so the frame catches
	## the weapon mid-arc and the clamor ring the swing produced. An idle frame
	## shows neither — clamor decays to nothing and the ring hides itself — and
	## would suggest both features were missing.
	var loud: ItemResource = ItemCatalogue.by_id(&"wpn_seax")
	var edge := loud.first_trait(WieldableTrait) as WieldableTrait
	player.clamor.add(edge.clamor_swing * 2.0)
	player.weapon.request_swing(player.stamina)
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


## Does the enemy ever get to swing? (`M4-T16`, ADR-194)
##
## `_combat_probe` measures the *anatomy* of a fight — telegraph length, swing
## phases, how many hits each side needs — and every number it prints is
## correct. **It never measures the fight.** Its step 4 asserts *"hit interrupts
## windup"* and calls that the reward for reading a telegraph, which is the
## assumption under test rather than a result: if a hit interrupts a windup at
## any point in the cycle, reading the telegraph is not the reward, it is the
## strictly worse alternative to swinging first.
##
## Measured against the player's own health, because that is what a player
## experiences. Both fighters are held alive so the *window* is the variable
## rather than the lethality, which `_combat_probe` already owns.
##
## Two passes, because the first claim has an obvious objection:
##
## 1. **Stamina refilled** — isolates the stagger loop from the stamina economy.
## 2. **Stamina as played** — asks whether the economy already prices the loop,
##    which would make the first pass a fact about a build nobody can play.
##
## Both passes must see the enemy land a blow. Before poise neither did:
## 24 swings, zero damage taken, ten seconds.
func _fight_probe(player: Player) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tuning: TuningProfile = Config.tuning
	var enemy: Enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	var edge: WieldableTrait = player.weapon.held()
	var failures: int = 0

	var cycle: float = edge.windup + edge.active + edge.recovery
	var guard: float = tuning.enemy_stagger + tuning.enemy_telegraph
	print("[fight] weapon cycle              %4d ms  (%s)" % [
		int(cycle * 1000.0),
		player.equipment.in_slot(Enums.Slot.MAIN_HAND).definition.id])
	print("[fight] stagger + telegraph       %4d ms   the gap a stagger buys" % [
		int(guard * 1000.0)])
	print("[fight] swings to break poise     %4.1f   (%.0f poise / %.0f per hit)" % [
		tuning.enemy_poise / maxf(edge.stagger, 0.001),
		tuning.enemy_poise, edge.stagger])

	for pass_index: int in range(2):
		var refill: bool = pass_index == 0
		# **Facing the enemy.** `_combat_probe` puts the player at -Z and passes
		# yaw 0.0 — Godot's forward — so its player stands in front of the enemy
		# looking away from it. That probe only asks whether the enemy
		# telegraphs, which it does regardless, so the error is invisible there.
		player.teleport(enemy.global_position + Vector3(0, 0.1, -1.4), PI)
		player.health.restore()
		player.stamina.refill()
		enemy.health.restore()

		# **A Dictionary, not an int.** GDScript lambdas capture by value, so a
		# captured integer counter increments a copy and reads back zero
		# forever — which is exactly how this probe first reported that a
		# healthy build landed no hits either.
		var tally: Dictionary = {"taken": 0, "landed": 0}
		var on_hurt: Callable = func(_a: float, _r: float, _f: Node) -> void:
			tally["taken"] = int(tally["taken"]) + 1
		var on_land: Callable = func(_h: Hurtbox) -> void:
			tally["landed"] = int(tally["landed"]) + 1
		player.health.damaged.connect(on_hurt)
		player.weapon.connected.connect(on_land)

		var swings: int = 0
		var enemy_swings: int = 0
		var was_active: bool = false
		# Ten seconds is far longer than the fight it stands in for — four seax
		# swings kill this enemy. The length is what makes a zero mean
		# something: a 1.6 s fight could take no damage by luck.
		for i: int in range(600):
			enemy.health.restore()
			player.health.restore()
			if refill:
				player.stamina.refill()
			if not player.weapon.is_busy() \
					and player.weapon.request_swing(player.stamina):
				swings += 1
			var active: bool = enemy.is_swinging()
			if active and not was_active:
				enemy_swings += 1
			was_active = active
			await get_tree().physics_frame

		player.health.damaged.disconnect(on_hurt)
		player.weapon.connected.disconnect(on_land)
		var label: String = "stamina refilled" if refill else "stamina as played"
		print("[fight] %-20s %3d swings / %d land | enemy %d swings / %d land" % [
			label, swings, int(tally["landed"]), enemy_swings, int(tally["taken"])])
		if int(tally["landed"]) == 0:
			print("[fight] FAIL %s: the player never connected — the probe is "
				% label + "measuring nothing")
			failures += 1
		# **The assertion this probe exists for.** A player holding the attack
		# button must not be safe. `DES-002` needs "do I take this fight" to
		# have an answer other than yes, and it cannot while the answer is free.
		if int(tally["taken"]) == 0:
			print("[fight] FAIL %s: %d enemy swings landed nothing in 10 s — "
				% [label, enemy_swings]
				+ "spamming a light weapon is a stagger-lock (DES-009 line 47)")
			failures += 1

	# ── the punish window ────────────────────────────────────────────────
	# **A swing that has gone by cannot be taken back.** This is the half a
	# light weapon has, and without it poise would simply mean knives no
	# longer stagger — a subtraction, not a design. Asserted separately
	# because the pass above stays green with this deleted: spam happens to
	# land in a recovery window often enough to look like it still works.
	player.teleport(enemy.global_position + Vector3(0, 0.1, -1.4), PI)
	enemy.health.restore()
	var punished: bool = false
	for i: int in range(900):
		await get_tree().physics_frame
		if enemy.attack_phase() != Enemy.Attack.RECOVERY:
			continue
		# Full poise on purpose: if this staggers, it staggered because the
		# swing was punished and not because the pool happened to be empty.
		enemy.refill_poise()
		enemy.take_test_hit(1.0)
		await get_tree().physics_frame
		punished = enemy.state() == Enemy.State.STAGGERED
		break
	print("[fight] recovery is punishable    %s" % ("yes" if punished else "NO"))
	if not punished:
		print("[fight] FAIL a hit into a full-poise enemy's recovery did not "
			+ "stagger it — DES-002's reason to read a fight is gone")
		failures += 1

	# ── DES-009 line 47, the half that was never built ───────────────────
	# *"Light (fast, low stagger) vs. heavy (slow, staggers, loud)."* One
	# hammer blow must break a full pool; four seax blows must not.
	var hammer: WieldableTrait = null
	var knife: WieldableTrait = null
	for trait_of: ItemTrait in ItemCatalogue.by_id(&"wpn_dvergar_hammer").traits:
		hammer = trait_of as WieldableTrait
	for trait_of: ItemTrait in ItemCatalogue.by_id(&"wpn_seax").traits:
		knife = trait_of as WieldableTrait
	print("[fight] hammer breaks poise in    %4.1f hits   (want 1.0)" % [
		tuning.enemy_poise / maxf(hammer.stagger, 0.001)])
	var kills: int = int(ceil(tuning.enemy_health / knife.damage))
	print("[fight] seax breaks poise in      %4.1f hits   (want > %d, the swings that kill it)" % [
		tuning.enemy_poise / maxf(knife.stagger, 0.001), kills])
	if hammer.stagger < tuning.enemy_poise:
		print("[fight] FAIL the hammer does not stagger in one hit — "
			+ "DES-009 line 47 says heavy staggers")
		failures += 1
	if knife.stagger * float(kills) >= tuning.enemy_poise:
		print("[fight] FAIL the seax breaks poise inside the fight it wins — "
			+ "the light weapon is a stagger-lock again")
		failures += 1

	if failures > 0:
		print("[fight] FAIL %d assertion(s)" % failures)
	else:
		print("[fight] a fight costs something, and heavy is what staggers")


## `DES-013`'s fourth rung (`M4-T16`, ADR-196).
##
## The ladder has read UNAWARE → SUSPICIOUS → ALERTED → SWARM since the design
## lock and built three of the four, with the diagram's *"(Clamor spike
## propagates to nearby actors)"* arrow having nothing behind it — every enemy
## carried a `ClamorSensor` and no `ClamorSource`, so enemies heard the player
## and were silent to each other.
##
## Five questions, and the last two are the ones that matter: a call nobody can
## prevent is a punishment rather than a decision, and a call that does not
## reach anybody is a tint change.
func _swarm_probe(player: Player) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tuning: TuningProfile = Config.tuning
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var caller: Enemy = enemies[0] as Enemy
	var others: Array[Enemy] = []
	for node: Node in enemies:
		var e := node as Enemy
		if e != null and e != caller:
			others.append(e)
	var failures: int = 0

	print("[swarm] enemies on the floor      %d (1 caller, %d listeners)"
		% [enemies.size(), others.size()])
	print("[swarm] call after / beat / shout %.1f s / %.2f s / %.1f (%.1f m)" % [
		tuning.enemy_swarm_after, tuning.enemy_swarm_telegraph,
		tuning.enemy_swarm_clamor,
		tuning.enemy_swarm_clamor * tuning.clamor_metres_per_unit])

	# ── 1. it escalates at all ───────────────────────────────────────────
	# Stand in front of it and do nothing. Before this, an enemy that had you
	# for one second and one that had you for thirty were the same enemy.
	player.teleport(caller.global_position + Vector3(0, 0.1, -1.8), PI)
	player.health.restore()
	# **How long the beat lasted, not whether it happened.** The first version
	# asked only whether CALLING was ever observed — and a beat of zero seconds
	# is still CALLING for one frame, so a build that shouted with no warning
	# at all walked straight through the row. What `DES-013` asks for is a beat
	# a person can act inside, which is a duration.
	var beat_began: int = 0
	var beat_ms: int = 0
	var swarmed_at: float = -1.0
	var began: int = Time.get_ticks_msec()
	for i: int in range(int(90.0 * (tuning.enemy_swarm_after + 4.0))):
		player.health.restore()
		if caller.state() == Enemy.State.CALLING and beat_began == 0:
			beat_began = Time.get_ticks_msec()
		if caller.state() == Enemy.State.SWARM:
			swarmed_at = (Time.get_ticks_msec() - began) / 1000.0
			if beat_began != 0:
				beat_ms = Time.get_ticks_msec() - beat_began
			break
		await get_tree().physics_frame
	var floor_ms: int = int(TuningProfile.TELEGRAPH_FLOOR * 1000.0)
	print("[swarm] the beat lasted           %4d ms   floor %d, tuned %d" % [
		beat_ms, floor_ms, int(tuning.enemy_swarm_telegraph * 1000.0)])
	var saw_calling: bool = beat_ms >= floor_ms
	print("[swarm] called the floor after    %.1f s (want ~%.1f)"
		% [swarmed_at, tuning.enemy_swarm_after + tuning.enemy_swarm_telegraph])
	if not saw_calling:
		print("[swarm] FAIL the beat was %d ms against a %d ms floor — DES-013 "
			% [beat_ms, floor_ms]
			+ "asks for one chance to prevent it, and a frame is not a chance")
		failures += 1
	if swarmed_at < 0.0:
		print("[swarm] FAIL an enemy held the player and never escalated — the "
			+ "ladder's fourth rung is decoration")
		failures += 1
	# **A bound, not just a yes.** The first version of this clock lived inside
	# `_act`, which is skipped for the whole of an attack cycle — so against a
	# body standing in melee range it advanced roughly one frame per second and
	# the call came minutes late. "It escalated eventually" would have passed
	# that build. Generous, because acquisition and the walk-in are real time
	# the enemy spends before the clock starts.
	var due: float = tuning.enemy_swarm_after + tuning.enemy_swarm_telegraph
	if swarmed_at >= 0.0 and swarmed_at > due * 2.0:
		print("[swarm] FAIL the call took %.1f s against %.1f s of tuning — the "
			% [swarmed_at, due]
			+ "clock is running far slower than the clock says it does")
		failures += 1

	# ── 2. it reaches other enemies ──────────────────────────────────────
	# The whole point: `DES-013`'s propagation arrow, using `M2-T02`'s hearing.
	var roused: int = 0
	for i: int in range(120):
		await get_tree().physics_frame
	for other: Enemy in others:
		if other.state() != Enemy.State.UNAWARE:
			roused += 1
	# **Not all of them, and that is correct.** `ClamorSource.audible_at` muffles
	# through walls, so a call crosses a room and dies through enough of them —
	# `DES-013` wants a shout, not a floor-wide alarm. The assertion is that it
	# reaches *somebody*; how many is a level-geometry question and a ⟨tune⟩ one.
	print("[swarm] listeners roused          %d of %d" % [roused, others.size()])
	if others.size() > 0 and roused == 0:
		print("[swarm] FAIL nobody heard the call — an enemy with no ClamorSource "
			+ "is a shout with no sound, which is what this task found")
		failures += 1

	# ── 3. it does not hear itself ───────────────────────────────────────
	# A body whose own call is the loudest thing it can hear would investigate
	# the spot it is already standing in, forever.
	# **Tested where the guard is reachable.** Checking the caller's state right
	# after its own call proves nothing: `_listen` returns early on ALERTED,
	# CALLING, SWARM and STAGGERED, so the state machine protects it there
	# whether or not the sensor skips itself. The case that bites is a *quiet*
	# body whose own clamor is still decaying — it would investigate the spot
	# it is standing in, permanently.
	_reset()
	await get_tree().physics_frame
	var loner: Enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	player.teleport(Vector3(0, 0.1, 40), 0.0)
	for i: int in range(60):
		await get_tree().physics_frame
	var quiet: int = loner.state()
	loner.clamor.add(tuning.enemy_swarm_clamor)
	for i: int in range(int(90.0 * (tuning.enemy_hearing_patience + 1.0))):
		await get_tree().physics_frame
	print("[swarm] a body hearing itself     %s -> %s (want no change)" % [
		Enemy.State.keys()[quiet].to_lower(),
		Enemy.State.keys()[loner.state()].to_lower()])
	if loner.state() != quiet:
		print("[swarm] FAIL a body heard its own shout and went to look for "
			+ "itself — every caller would investigate where it is standing")
		failures += 1

	# ── 4. staggering it throws the call away ────────────────────────────
	# `_break_poise` is the counter a heavy weapon buys, and ADR-194's poise
	# and this task's swarm turn out to be the same decision seen twice.
	_reset()
	await get_tree().physics_frame
	var victim: Enemy = get_tree().get_first_node_in_group("enemies") as Enemy
	player.teleport(victim.global_position + Vector3(0, 0.1, -1.8), PI)
	var stopped: bool = false
	for i: int in range(int(90.0 * (tuning.enemy_swarm_after + 4.0))):
		player.health.restore()
		if victim.state() == Enemy.State.CALLING:
			# A hammer's worth of stagger, through the real path.
			victim.refill_poise()
			var blow := Hitbox.new()
			blow.stagger = tuning.enemy_poise
			victim.take_test_hit(1.0, blow)
			await get_tree().physics_frame
			stopped = victim.state() != Enemy.State.SWARM
			blow.free()
			break
		await get_tree().physics_frame
	print("[swarm] staggering stops the call %s" % ("yes" if stopped else "NO"))
	if not stopped:
		print("[swarm] FAIL a call could not be interrupted — DES-013 requires "
			+ "one chance to prevent the failure state")
		failures += 1

	# ── 5. a fight you win quickly never calls ───────────────────────────
	# The clock has to be longer than the fight, or every encounter is a swarm
	# and "do I take this fight" has one answer again.
	var kills: float = ceil(tuning.enemy_health / player.weapon.held().damage)
	var edge: WieldableTrait = player.weapon.held()
	var fight: float = kills * (edge.windup + edge.active + edge.recovery)
	print("[swarm] a won fight takes         %.1f s vs %.1f s of patience"
		% [fight, tuning.enemy_swarm_after])
	if fight >= tuning.enemy_swarm_after:
		print("[swarm] FAIL killing one enemy takes longer than the call — every "
			+ "fight would summon the floor, which is a tax rather than a choice")
		failures += 1

	if failures > 0:
		print("[swarm] FAIL %d assertion(s)" % failures)
	else:
		print("[swarm] the floor can be called, and the call can be stopped")
