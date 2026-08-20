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


## True once the descent is under way, so a body standing in the hole does not
## ask again every frame while the scene is still changing.
var _descending: bool = false


func _ready() -> void:
	# The only safe sound in the game (`M2-T09`, `ART-002`). Declared before
	# anything is built, so the first frame here already sounds like here.
	AudioDirector.enter("threshold")
	_build_ground()
	_build_fire()
	_build_doors()
	_spawn_actors()
	_build_readout()
	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	hud.add_child(Reticle.new())
	add_child(PauseMenu.new())
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--threshold-shot="):
			_threshold_shot(arg.split("=", true, 1)[1])
		elif arg == "--threshold-probe":
			_threshold_probe()
		elif arg == "--doorway-probe":
			_doorway_probe()
		elif arg == "--chamber-probe":
			_chamber_probe()


## Walk the party through the Descent on a timer (`run_doorway.py`).
##
## The host waits for company, then descends — which is the whole test, because
## the transition is what used to drop the connection. Nothing is asserted
## here; the harness reads both processes' logs, since the question is about
## what happened to *two* of them.
func _doorway_probe() -> void:
	await get_tree().create_timer(6.0).timeout
	if multiplayer.is_server():
		_ask_to_descend()


## The camp's own music, and the rules that hold across all three (`M2-T09`).
##
## `ART-002` and `ART-003` both single this piece out — *"the most important
## piece of music in the game"*, *"the only safe sound"* — and `TEC-005` names
## the adaptive driver the highest-risk audio tech in the project. `M2-T03`
## built the driver for the Deep. What was still unproven is that a *place* can
## have its own, which is what makes three sonic worlds three pieces rather
## than one piece with the lights dimmed.
##
## Five assertions, and two of them are rules rather than behaviours:
##
## 1. **The reserved instrument is used once.** `ART-003` states it as an
##    absolute — the Hunter's voice appears nowhere else, ever, *"not in the
##    Threshold, not as texture, not 'just once' somewhere atmospheric"* —
##    because the moment it is a false alarm it is worthless for the rest of
##    the game. A rule that depends on remembering it is a rule that will be
##    broken by whoever needs a nice sound late one night.
## 2. **Every place has its own piece**, and no two are the same table.
## 3. **Every piece has air.** Somewhere with no room tone is not a place.
## 4. **The Threshold is warm on arrival.** Safety that fades in over two
##    seconds each time you walk through the door is a worse lie than silence.
## 5. **The arrangement fills out as the camp does** (ADR-050) — the thing that
##    makes this a driver rather than a looping file.
func _threshold_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()

	# ─ 1. the reserved instrument ─
	var reserved: Array[String] = []
	for piece: String in AudioDirector.PIECES:
		var table: Dictionary = AudioDirector.PIECES[piece]
		for layer: String in table:
			var spec: Dictionary = table[layer]
			if String(spec["voice"]) == AudioDirector.RESERVED_VOICE:
				reserved.append("%s/%s" % [piece, layer])
	print("[camp] reserved     %s plays %s" % [
		AudioDirector.RESERVED_VOICE, ", ".join(reserved)])
	# Spelt out rather than compared against a literal array: `x != [y] as
	# Array[T]` binds the cast to the comparison, not the literal, and is a
	# parse error rather than the check you meant to write.
	if reserved.size() != 1 or reserved[0] != "deep/hunter":
		problems.append(("the %s voice is used by %s — ART-003 reserves it for "
			+ "the Hunter and nothing else, ever, so that hearing it is always "
			+ "true. A second user makes every first one a coin-flip")
			% [AudioDirector.RESERVED_VOICE, ", ".join(reserved)])

	# ─ 2 and 3. three places, three pieces, all of them rooms ─
	var seen: Array[String] = []
	for piece: String in AudioDirector.PIECES:
		var table: Dictionary = AudioDirector.PIECES[piece]
		var signature: String = ",".join(table.keys())
		var air: bool = false
		for layer: String in table:
			if String((table[layer] as Dictionary)["bus"]) == "ambience":
				air = true
		print("[camp] %-11s %d layer(s), %s" % [
			piece, table.size(), "has air" if air else "NO AIR"])
		if not air:
			problems.append(("%s has no ambience layer — ART-002 wants air and "
				+ "stone settling under everything, and a place with no room "
				+ "tone stops being a place the moment the score rests")
				% piece)
		if seen.has(signature):
			problems.append(("%s is scored by the same layers as another place "
				+ "— the three sonic worlds are three pieces, not one piece "
				+ "with the lights dimmed") % piece)
		seen.append(signature)

	# ─ 4. warm on arrival ─
	await _hold(AudioDirector.CROSSFADE + 0.6)
	var here: Dictionary = AudioDirector.layer_levels()
	print("[camp] on arrival  %s" % [_levels_line(here)])
	if AudioDirector.place() != "threshold":
		problems.append("standing in the Threshold and the director is playing "
			+ "'%s'" % AudioDirector.place())
	for named: String in ["hearth", "warmth", "theme"]:
		if float(here.get(named, AudioDirector.SILENCE_DB)) \
				<= AudioDirector.SILENCE_DB + 0.5:
			problems.append(("the Threshold's %s is silent on arrival — this is "
				+ "the only safe sound in the game and it is not something the "
				+ "player should have to wait out") % named)

	# ─ 5. a fuller camp, a fuller arrangement ─
	var lonely: float = float(here.get("company", AudioDirector.SILENCE_DB))
	GameState.descents += int(AudioDirector.CAMP_FULL_AT) + 1
	await _hold(AudioDirector.CROSSFADE + 0.6)
	var settled: float = float(AudioDirector.layer_levels().get(
		"company", AudioDirector.SILENCE_DB))
	print("[camp] company     %.1f dB at one descent → %.1f dB at %d" % [
		lonely, settled, GameState.descents])
	if settled <= lonely + 0.5:
		problems.append(("the arrangement did not fill out as the camp did — "
			+ "ADR-050 makes momentum audible as well as visible, and a camp "
			+ "that sounds the same on descent 1 and descent 8 is a looping "
			+ "file rather than a driver"))

	for problem: String in problems:
		printerr("[camp] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


func _levels_line(levels: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for name: String in levels:
		parts.append("%s %.0f" % [name, float(levels[name])])
	return "  ".join(parts)


func _hold(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


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
			# Who is actually here. The host presses OPEN THE THRESHOLD and then
			# has no way to tell whether anybody arrived — and descending alone
			# by accident is a wasted run and a confusing bug report.
			"party      %d of %d%s" % [
				_session.players().size(), Player.MAX_PARTY,
				"" if multiplayer.get_peers().size() > 0 or not _session.is_host()
					else "   (nobody has joined yet)"],
			"",
			"the fire behind you is the Lodge's",
			"walk into the dark ahead to descend",
			"walk back onto the pale slab for your Chamber",
			"",
			# The Deep lists these and the camp did not, so the first time a
			# tester needed them was the first time they were under pressure.
			# `M2-T13`: attack, throw and the waystone were on no list anywhere
			# in the game. A verb a tester cannot discover is worse than one
			# that does not exist — it is maintenance paid for nothing, and it
			# makes every report about the run describe a smaller game than the
			# one that was built. The throw is the Hunt's counter-play and the
			# waystone is half of `DES-005`'s way out.
			"wasd move   mouse look   shift sprint   ctrl crouch",
			"lmb attack   e take   tab bag   g drop",
			"t throw   v waystone   esc menu",
		])
	if player.global_position.distance_to(DESCENT_AT) <= 2.0:
		_ask_to_descend()
	elif (_chamber_armed
			and player.global_position.distance_to(CHAMBER_AT) <= 1.8):
		_open_the_chamber()
	elif player.global_position.distance_to(CHAMBER_AT) > 3.0:
		# Stepped clear of the slab, so the door will take you again. Without
		# this a player who came back out would be standing close enough to
		# re-enter on the very next frame, forever.
		_chamber_armed = true


## **The party descends together, or the party is not a party.**
##
## Each peer used to change scene the moment its own body reached the hole, so
## in company one player would drop into the Deep while everybody else stood at
## the fire looking at a world nobody was simulating for them. `DES-012` has
## you go down *together* — that is the whole shape of a run.
##
## So the hole is the host's decision. Anyone can walk into it; the host is
## told, and the host takes everyone.
func _ask_to_descend() -> void:
	if _descending:
		return
	_descending = true
	if multiplayer.is_server():
		_descend.rpc()
	else:
		_ask_host_to_descend.rpc_id(CoopSession.HOST_PEER)


@rpc("any_peer", "reliable")
func _ask_host_to_descend() -> void:
	if not multiplayer.is_server():
		return
	_descend.rpc()


## Down. Whatever is in the stash is what you take, because `DES-014` puts
## loadout choices in the Chamber and this is the doorway rather than a menu.
@rpc("authority", "call_local", "reliable")
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


## Send the **client** into its own Chamber and back (`run_doorway.py`).
##
## The doorway probe walks the *host* through the Descent, which is the
## transition the party takes together. This is the other kind: a doorway only
## one player goes through, while everybody else stays where they are. Nothing
## covered it, and ADR-102 found four faults living in it at once.
##
## Drives the real slab rather than a test-only entry point — the client
## teleports onto the Chamber door and whatever the game does next is what is
## being measured.
##
func _chamber_probe() -> void:
	await get_tree().create_timer(5.0).timeout
	_census("before")
	if not multiplayer.is_server():
		var mine: Player = _session.local_player()
		if mine != null:
			mine.teleport(CHAMBER_AT, 0.0)
	# Long enough to walk in, look around, and come back out.
	await get_tree().create_timer(13.0).timeout
	_census("settled")


## What this peer can see, in one line. The whole assertion surface: how many
## bodies exist, whether one of them is mine, and which seat it holds — a seat
## that changes across a Chamber visit means I came back as somebody else.
func _census(tag: String) -> void:
	var bodies: int = get_tree().get_nodes_in_group("player").size()
	var mine: Player = _session.local_player() if _session != null else null
	print("[chamber] %s %s bodies=%d mine=%s slot=%d" % [
		"host" if multiplayer.is_server() else "client", tag, bodies,
		"yes" if mine != null else "NO",
		mine.party_slot if mine != null else -1])


## **The door takes you out of the world** (ADR-102).
##
## The Chamber is yours alone (ADR-021), so this is the one doorway exactly one
## player walks through while everybody else stays at the fire. It used to be a
## `change_scene_to_file`, and that was the wrong shape three times over: the
## client lost its camera, lost its body on the way back, and left the host
## sending packets into a scene that no longer existed.
##
## So the room opens *above* the camp instead, and your body is **despawned**
## rather than hidden. Hiding was the tempting fix and it is a lie: an
## invisible body still collides, still holds a doorway, still makes noise, and
## still occupies a seat. Other players see you walk to the door and go through
## it, which is what happened.
##
## The offset is what keeps two rooms built around the origin from standing
## inside each other. Both are lit by omni lights only, so at this distance
## neither one reaches the other.
const CHAMBER_SCENE: PackedScene = preload("res://levels/lair/chamber.tscn")
const CHAMBER_OFFSET: Vector3 = Vector3(0.0, -2000.0, 0.0)
## Where you are standing when you come back out — off the slab, facing the
## camp. On it, and the door would swallow you again immediately.
const CHAMBER_STEP: Vector3 = Vector3(0.0, 0.1, 4.6)
## The room's node name, which is also the path its private multiplayer is
## keyed to. One constant, because the two must agree.
const CHAMBER_NODE: String = "Chamber"

var _chamber: Chamber = null
## False from the moment you step onto the slab until you step off it again.
var _chamber_armed: bool = true


func _open_the_chamber() -> void:
	if _chamber != null:
		return
	_chamber_armed = false
	set_process(false)
	# Out of the world first, so nobody watches a statue of you standing at the
	# door while you are inside.
	_ask_to_leave_the_world()

	_chamber = CHAMBER_SCENE.instantiate() as Chamber
	_chamber.name = CHAMBER_NODE
	_chamber.position = CHAMBER_OFFSET
	_chamber.left.connect(_close_the_chamber)
	# **The room gets its own multiplayer, with nobody on the other end.**
	#
	# ADR-021 says the Chamber is never networked and makes that structural by
	# keeping a `CoopSession` out of it. That was not enough once the room
	# started floating above a live connection: the body in here is *local*, so
	# it happily fired `_ask_for_my_bag` at the host, which answered "Node not
	# found: Chamber/chamber_body" — a private body reaching the wire, which is
	# the exact thing the ADR exists to prevent.
	#
	# Guarding the eleven RPC sites on `Player` one at a time would have worked
	# until somebody added a twelfth. A subtree with its own peerless
	# `MultiplayerAPI` cannot reach anybody by construction, whatever is written
	# inside it later. Set **before** it enters the tree, because `_ready` is
	# where the body decides whose it is.
	var island := MultiplayerAPI.create_default_interface()
	island.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().set_multiplayer(island, NodePath("/root/%s" % CHAMBER_NODE))
	# A sibling of this level rather than a child, so hiding the camp does not
	# hide the room floating above it.
	get_tree().root.add_child(_chamber)
	visible = false
	AudioDirector.enter("chamber")


func _close_the_chamber() -> void:
	if _chamber == null:
		return
	_chamber.queue_free()
	_chamber = null
	get_tree().set_multiplayer(null, NodePath("/root/%s" % CHAMBER_NODE))
	visible = true
	AudioDirector.enter("threshold")
	_ask_to_rejoin_the_world()
	set_process(true)


## Ask the host to take my body out. The host owns every spawn and despawn
## (`TEC-004`), so a client cannot simply free its own copy — it would come
## straight back on the next synchroniser packet.
func _ask_to_leave_the_world() -> void:
	if multiplayer.is_server():
		_session.despawn_player(CoopSession.HOST_PEER)
	else:
		_leave_the_world.rpc_id(CoopSession.HOST_PEER)


func _ask_to_rejoin_the_world() -> void:
	if multiplayer.is_server():
		_session.spawn_player(CoopSession.HOST_PEER, CHAMBER_STEP)
	else:
		_rejoin_the_world.rpc_id(CoopSession.HOST_PEER)


@rpc("any_peer", "reliable")
func _leave_the_world() -> void:
	if not multiplayer.is_server():
		return
	_session.despawn_player(multiplayer.get_remote_sender_id())


## Back through the door you went in by, rather than onto the next free spawn
## mark across the camp. **Beside** the slab rather than on it: landing on the
## trigger you just used sends you straight back in.
@rpc("any_peer", "reliable")
func _rejoin_the_world() -> void:
	if not multiplayer.is_server():
		return
	_session.spawn_player(multiplayer.get_remote_sender_id(), CHAMBER_STEP)
