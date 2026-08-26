class_name Chamber
extends Node3D

## Your Chamber (`M2-T06`, `DES-014`, ADR-021). Her, the hoard, and the stash.
##
## **Private, local, always yours.** `DES-012` makes every pact individual, and
## ADR-021 splits the Lair in two rather than trying to make one hub serve four
## people with four different ranks. No other player ever enters this scene.
##
## That is not a networking convenience, it is the design's reasoning running
## the right way round: tribute, her voice, and choosing what she keeps of you
## are **solitary by design**, and four people watching you decide is actively
## wrong — it is the most intimate moment in the game. The technical property
## (progression never touches the wire, `TEC-004`) falls out of the fiction
## rather than the fiction being bent to fit it.
##
## **So there is no `CoopSession` here at all**, and that absence is the
## enforcement. A body is instantiated directly. Nothing can replicate out of a
## scene with no session in it, however carelessly anyone wires it later.
##
## ## The Settle beat
##
## `DES-019` names the extraction screen one of the two that carry
## disproportionate weight, because every run ends on it. What it asks for is
## the keep-or-give decision **made physically at the hoard** — not a
## confirmation dialog, not a list with two buttons.
##
## So it is exactly the gesture you already know: **open the bag and drag
## something out.** Where you are standing decides what that means. At the
## hoard it is tribute; at the stash it is kept; anywhere else it just lands on
## the floor, which is also an answer.
##
## ## What is absent, not stubbed (ADR-064)
##
## **Boon.** Tribute converts to nothing yet — `M3-T01` builds the tree it buys.
## The pile grows and is counted, which is what `DES-014` says the hoard is for
## on its own: *"a permanent physical monument to every life you have lost."*
##
## **The Legacy screen** — `M3-T05`. The Tithe and Pact Rank arrived at
## `M3-T04` and are on the readout; what a rank *buys* is still `M3-T01`.
## **Saving any of it to disk** — `M3-T06`, and `TEC-003` wants a versioned
## format with a migration path rather than whatever is convenient today.

const ROOM: Vector2 = Vector2(16.0, 14.0)
const WALL_HEIGHT: float = 6.0

const STONE: Color = Color(0.17, 0.16, 0.17)
const FLOOR_COLOUR: Color = Color(0.22, 0.21, 0.20)
## Gold is the only saturated colour in the game (`ART-005`). The hoard is the
## largest concentration of it anywhere, which is the point.
const GOLD: Color = Color(0.86, 0.67, 0.22)
## She is barely distinguishable from the rock, and gets less so — ADR-050:
## *"further fused into the stone with each lineage."*
const HER: Color = Color(0.20, 0.19, 0.18)
const STASH_COLOUR: Color = Color(0.38, 0.33, 0.26)

## Raised when you walk back out. The Threshold opened this room and is the
## thing that puts you back in the world.
signal left()

const HOARD_AT: Vector3 = Vector3(0.0, 0.0, -4.0)
const STASH_AT: Vector3 = Vector3(-5.0, 0.0, 1.0)
const DOOR_AT: Vector3 = Vector3(0.0, 0.0, 6.0)
const SPAWN_AT: Vector3 = Vector3(0.0, 0.1, 4.0)

## How close you have to be for a thing you put down to mean something.
const PLACE_REACH: float = 2.6

## One coin-mesh per this much tribute ⟨tune⟩, so the pile grows visibly
## without becoming a mesh budget. `DES-014` costs it at *"a growing-pile-of-
## meshes system and nothing else"*, and this is the number that keeps it that.
const VALUE_PER_LUMP: int = 25
const MAX_LUMPS: int = 400

var _player: Player = null
## The Settle beat's banner, while it is up (`M3-T08`).
var _deeds_banner: DeedsBanner = null
var _hoard_root: Node3D = null
var _readout: Label = null
## The Aspects, while they are open. Non-null is what stops the room reopening
## them every frame the player holds the key at the pile.
var _pact: PactScreen = null


func _ready() -> void:
	# Her room, and its own piece (`M2-T09`, `ART-002`) — vast air and
	# something slow underneath it. Before `M2-T09` this scene inherited
	# whatever the Deep had left playing, which scored the quietest place in
	# the game with the Hunt.
	AudioDirector.enter("chamber")
	# Seeded **before** anything is built, so the probe exercises the real
	# arrival path rather than reaching past it. Launched on its own this scene
	# has nothing to sort, because nobody extracted into it.
	if OS.get_cmdline_user_args().has("--lair-probe"):
		_seed_a_haul()
	for arg: String in OS.get_cmdline_user_args():
		# A hoard worth looking at. The pile is `DES-014`'s *"permanent physical
		# monument"*, and a monument photographed at zero is a photograph of a
		# floor — the thing this shot exists to judge is whether many lives'
		# worth of gold reads as a mountain you can walk on.
		if arg.begins_with("--chamber-shot="):
			GameState.hoard_value = 2400
	_build_room()
	_build_her()
	_build_hoard()
	_build_stash()
	_build_door()
	_spawn_body()
	_build_readout()
	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	hud.add_child(Reticle.new())
	add_child(PauseMenu.new())
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--lair-probe":
			_lair_probe()
		elif arg == "--chamber-probe":
			_leave_soon()
		elif arg.begins_with("--chamber-shot="):
			_chamber_shot(arg.split("=", true, 1)[1])
		elif arg == "--tithe-probe":
			_tithe_probe()
		elif arg == "--respec-probe":
			_respec_probe()
		elif arg == "--deeds-probe":
			_deeds_probe()
		elif arg == "--legacy-probe":
			_legacy_probe()
		elif arg == "--pact-probe":
			_pact_probe()


## A body, instantiated rather than spawned. See the class note: the absence of
## a session is what makes "never networked" structural instead of remembered.
func _spawn_body() -> void:
	_player = preload("res://actors/player/player.tscn").instantiate() as Player
	_player.name = "chamber_body"
	# **Yours, whoever you are** (ADR-102). Authority defaults to peer 1, so on
	# a client this body reported `is_multiplayer_authority()` false and
	# `Player._ready` took the remote branch: no camera made current, no input,
	# no bag. `chamber.tscn` holds no camera of its own, so the second player
	# walked into their own hoard room and got a viewport with nothing in it.
	#
	# Nothing here is replicated: this body carries no synchronisers, because
	# `configure_replication` builds those and only `CoopSession` calls it.
	# ADR-021 holds — the room is private by construction, not by care.
	_player.set_multiplayer_authority(multiplayer.get_unique_id())
	_player.position = SPAWN_AT
	add_child(_player)
	_player.dropped.connect(_on_put_down)
	# What you walked out with is in your hands when you arrive. `DES-019`
	# wants the Settle beat to open on *what you brought*, and the most direct
	# way to say that is for it to still be in the bag.
	for item: ItemInstance in GameState.carried:
		_player.inventory.add(item.definition)


## Putting something down, and the place decides what it means.
##
## The same drag-out-of-the-bag gesture that abandons loot on a dungeon floor.
## `DES-019` refuses a confirmation dialog for tribute and asks for the
## decision to be physical; this is what physical costs — a walk to one side of
## the room or the other.
func _on_put_down(item: ItemInstance, at: Vector3, _yaw: float,
		_launch: Vector3) -> void:
	if at.distance_to(global_position + HOARD_AT) <= PLACE_REACH:
		GameState.tribute(item)
		_rebuild_hoard()
		print("[lair] gave %s — the hoard is worth %d" % [
			item.definition.display(), GameState.hoard_value])
		_settle()
		return
	if at.distance_to(global_position + STASH_AT) <= PLACE_REACH:
		GameState.keep(item)
		print("[lair] kept %s — the stash holds %d" % [
			item.definition.display(), GameState.stash.size()])
		_settle()
		return
	# Neither. It is on the floor of your own Chamber, which is a perfectly
	# good place for a thing to be and needs no handling at all.
	print("[lair] put %s down on the floor" % item.definition.display())


func _build_room() -> void:
	_slab(Vector3(ROOM.x, 0.4, ROOM.y), Vector3(0.0, -0.2, 0.0), FLOOR_COLOUR)
	var half: Vector2 = ROOM * 0.5
	_slab(Vector3(ROOM.x, WALL_HEIGHT, 0.6),
		Vector3(0.0, WALL_HEIGHT * 0.5, -half.y), STONE)
	_slab(Vector3(0.6, WALL_HEIGHT, ROOM.y),
		Vector3(-half.x, WALL_HEIGHT * 0.5, 0.0), STONE)
	_slab(Vector3(0.6, WALL_HEIGHT, ROOM.y),
		Vector3(half.x, WALL_HEIGHT * 0.5, 0.0), STONE)
	_slab(Vector3(ROOM.x, WALL_HEIGHT, 0.6),
		Vector3(0.0, WALL_HEIGHT * 0.5, half.y), STONE)

	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.0, 4.2, -1.0)
	lamp.omni_range = 20.0
	# Warm and low. `ART-001` builds the whole look on darkness as a mechanic,
	# and this is the one room where the light is meant to be *hers*.
	lamp.light_color = Color(1.0, 0.82, 0.58)
	lamp.light_energy = 1.6
	add_child(lamp)

	var environment := WorldEnvironment.new()
	var world := Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.background_color = Color(0.05, 0.05, 0.06)
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color(0.24, 0.21, 0.20)
	world.ambient_light_energy = 0.6
	environment.environment = world
	add_child(environment)


## Her, at blockout (ADR-046). Enormous, low, and **barely separable from the
## rock she is fused into** — `DES-014` and ADR-050 make that fusion progress
## across a lineage, so she is the same colour as the wall on purpose. The
## shape is a long mass behind the hoard, not a creature standing in a room.
func _build_her() -> void:
	_slab(Vector3(11.0, 3.2, 3.0), HOARD_AT + Vector3(0.0, 1.6, -2.4), HER)
	_slab(Vector3(4.0, 2.0, 2.4), HOARD_AT + Vector3(-3.4, 1.0, -0.6), HER)
	_slab(Vector3(4.0, 2.0, 2.4), HOARD_AT + Vector3(3.4, 1.0, -0.6), HER)


func _build_hoard() -> void:
	_hoard_root = Node3D.new()
	_hoard_root.name = "Hoard"
	_hoard_root.position = HOARD_AT
	add_child(_hoard_root)
	_rebuild_hoard()


## The pile, rebuilt from its total. Deterministic from a fixed seed, so the
## hoard you walked past last run is the same hoard — a monument that
## rearranged itself every visit would not be one.
func _rebuild_hoard() -> void:
	for child: Node in _hoard_root.get_children():
		child.queue_free()
	var lumps: int = mini(MAX_LUMPS, GameState.hoard_value / VALUE_PER_LUMP)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5E1F
	var gold: StandardMaterial3D = _material(GOLD)
	gold.roughness = 0.35
	for index: int in range(lumps):
		var lump := MeshInstance3D.new()
		var box := BoxMesh.new()
		var size: float = rng.randf_range(0.22, 0.42)
		box.size = Vector3(size, size * 0.45, size)
		lump.mesh = box
		lump.material_override = gold
		# Piled: dense in the middle, thinning outward, and taller as it grows.
		var spread: float = 1.4 + sqrt(float(index)) * 0.22
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = sqrt(rng.randf()) * spread
		lump.position = Vector3(cos(angle) * radius,
			rng.randf_range(0.0, 0.12) + maxf(0.0, (spread - radius) * 0.22),
			sin(angle) * radius)
		lump.rotation.y = rng.randf_range(0.0, TAU)
		_hoard_root.add_child(lump)


func _build_stash() -> void:
	_slab(Vector3(1.8, 1.0, 1.2), STASH_AT + Vector3(0.0, 0.5, 0.0), STASH_COLOUR)


## The way out, to the Threshold. `DES-014`'s flow is Chamber → Threshold →
## Descent, identical solo and in company; the only difference is whether
## anybody is standing out there.
func _build_door() -> void:
	_slab(Vector3(2.6, 0.1, 2.6), DOOR_AT + Vector3(0.0, 0.02, 0.0),
		Color(0.42, 0.40, 0.36))


## **What she expects, and when** (`M3-T04`, ADR-029).
##
## ADR-029's consequence line is that *"the cycle boundary must be unmissable in
## the Lair UI"* — so the last run of a cycle says so in as many words rather
## than leaving the player to count. It reads as a debt because it is one: she
## is a creditor, not a shopkeeper (`DES-003`).
func _the_tithe() -> String:
	var owed: int = GameState.tithe_due()
	var short: int = maxi(0, owed - GameState.tithe_paid)
	var remaining: int = GameState.runs_left()
	var when: String = "she settles at your next descent" if remaining == 0 \
		else ("last run of this cycle" if remaining == 1 else "%d runs left" % remaining)
	if short == 0:
		return "the tithe   rank %d, %d of %d paid — settled · %s" % [
			GameState.pact_rank, GameState.tithe_paid, owed, when]
	return "the tithe   rank %d, %d of %d paid — %d short · %s" % [
		GameState.pact_rank, GameState.tithe_paid, owed, short, when]


func _process(_delta: float) -> void:
	if _player == null or _readout == null:
		return
	_readout.text = "\n".join([
		"THE CHAMBER    descent %d" % GameState.descents,
		"",
		"carrying   %d item(s), %d tribute" % [
			_player.inventory.count(), _player.inventory.total_tribute()],
		"stash      %d item(s), %d tribute" % [
			GameState.stash.size(), GameState.stash_value()],
		"the hoard  %d  (never wiped)" % GameState.hoard_value,
		"",
		_the_tithe(),
		"",
		"open the bag and drag an item out:",
		"  at the pile ahead   she keeps it",
		"  at the chest left   you keep it, until you die",
		"  anywhere else       it is on the floor",
		"",
		_the_offer(),
		"",
		"walk onto the pale slab behind you to reach the Threshold",
	])
	# **Buy where you give** (`M3-T01`). The Aspects open at the pile, because
	# that is the gesture `DES-003` couples them to: what you hand over is what
	# pays for them, and putting the tree behind a different door would make it
	# a shop rather than a pact.
	if (_pact == null and _player.global_position.distance_to(
			global_position + HOARD_AT) <= PLACE_REACH
			and Input.is_action_just_pressed("interact")):
		_open_the_pact()
	# Standing on the door is leaving. No prompt: `DES-019` puts nothing in the
	# centre of the screen, and a doorway you walk through needs no verb.
	if _player.global_position.distance_to(global_position + DOOR_AT) <= 1.6:
		_leave()


## What is on offer, or why nothing is. Beside the Tithe on purpose — the two
## halves of `DES-003`'s coupling read as one sentence that way.
func _the_offer() -> String:
	if GameState.boon <= 0:
		var per: int = Config.tuning.boon_per_tribute
		var short: int = per - GameState.boon_progress
		return ("her aspects   nothing yet — %d more tribute *above* the tithe "
			+ "buys the first") % short
	return "her aspects   %d boon unspent — hold %s at the pile" % [
		GameState.boon, ControlsScreen.glyphs_for("interact")]


## The tree, over the room rather than instead of it (ADR-102's habit): the
## Chamber stays where it is, and closing this puts the player back where they
## were standing.
func _open_the_pact() -> void:
	_pact = PactScreen.new()
	var layer := CanvasLayer.new()
	layer.layer = 8
	layer.add_child(_pact)
	add_child(layer)
	_pact.tree_exited.connect(func() -> void:
		_pact = null
		layer.queue_free())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _leave() -> void:
	set_process(false)
	# Anything still in the bag is still yours, and comes with you — you have
	# not decided about it yet, and the game does not decide for you.
	var undecided: Array[ItemInstance] = []
	for item: ItemInstance in _player.inventory.items():
		undecided.append(item)
	GameState.carried = undecided
	# Emitted, never a scene change (ADR-102). Whoever opened this room closes
	# it — the Chamber floats above a live level now, and tearing down the
	# scene from in here would take the party's world with it.
	left.emit()


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
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = centre
	node.material_override = _material(colour)
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


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	return material


## A plausible haul, for a Chamber launched without a run in front of it.
##
## Real definitions from the catalogue rather than invented ones: the probe's
## claims are about tribute values and about giving versus keeping, and both
## are only meaningful against items a designer actually authored.
func _seed_a_haul() -> void:
	var haul: Array[ItemInstance] = []
	var next: int = 1
	for id: StringName in [&"glt_altar_plate", &"glt_hoard_coin", &"mat_bog_iron"]:
		var definition: ItemResource = ItemCatalogue.by_id(id)
		if definition != null:
			haul.append(ItemInstance.of(definition, next))
			next += 1
	GameState.bring_home(haul)


## Does the Settle beat actually settle anything (`M2-T06`)?
##
## Four assertions, and the middle two are `DES-003`'s tiers made testable:
##
## 1. **What you carried out is in your hands** when you arrive.
## 2. **Tribute is one-way and permanent.** The pile only grows, and death does
##    not touch it — `DES-014` makes it the monument every lost life paid for.
## 3. **The stash survives a run and dies with you** — `DES-008`'s great reset,
##    which is what stops this economy inflating across a lineage.
## 4. **The two are different places.** Giving and keeping have to be
##    distinguishable acts or the three-way tug-of-war has only two corners.
func _lair_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	await get_tree().process_frame

	print("[lair] arrived    carrying %d item(s) worth %d" % [
		_player.inventory.count(), _player.inventory.total_tribute()])
	if _player.inventory.count() != GameState.carried.size():
		problems.append("what was carried out is not in the bag on arrival — "
			+ "DES-019 opens the Settle beat on what you brought")

	# Give one thing, keep another, from the same bag.
	var given: ItemInstance = _player.inventory.richest()
	var before_hoard: int = GameState.hoard_value
	var worth: int = given.definition.tribute_value
	_player.global_position = global_position + HOARD_AT + Vector3(0.0, 0.0, 1.5)
	_player.ask_to_drop_instance(given.instance_id)
	await get_tree().process_frame

	var kept: ItemInstance = _player.inventory.heaviest()
	_player.global_position = global_position + STASH_AT + Vector3(0.0, 0.0, 1.5)
	_player.ask_to_drop_instance(kept.instance_id)
	await get_tree().process_frame

	print("[lair] the pile   %d → %d after giving %s" % [
		before_hoard, GameState.hoard_value, given.definition.display()])
	print("[lair] the stash  %d item(s) after keeping %s" % [
		GameState.stash.size(), kept.definition.display()])
	if GameState.hoard_value != before_hoard + worth:
		problems.append("giving something at the hoard did not add it to the pile")
	if GameState.stash.is_empty():
		problems.append("keeping something at the stash did not stash it — giving "
			+ "and keeping must be distinguishable acts or DES-008's tug-of-war "
			+ "has only two corners")

	# Death. `DES-008`'s great reset, and the one thing it must not touch.
	var hoard_before_death: int = GameState.hoard_value
	GameState.die()
	print("[lair] and death  stash %d, hoard %d (was %d)" % [
		GameState.stash.size(), GameState.hoard_value, hoard_before_death])
	if not GameState.stash.is_empty():
		problems.append("death did not wipe the stash — DES-008's great reset is "
			+ "what stops this economy inflating across a lineage")
	if GameState.hoard_value != hoard_before_death:
		problems.append("death touched the hoard — DES-014 makes it LINEAGE tier "
			+ "and the monument to every life you have already lost")

	for problem: String in problems:
		printerr("[lair] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


func _chamber_shot(path: String) -> void:
	await _hold(0.6)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[lair] hoard %d, %d lump(s) — %s" % [
		GameState.hoard_value, _hoard_root.get_child_count(), path.get_file()])
	get_tree().quit()


func _hold(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Turn around and walk back out (`run_doorway.py`).
##
## The visit itself is not what is being measured — coming back is. A player
## who reaches their Chamber and cannot return to the party has lost the run
## just as surely as one who never arrived.
func _leave_soon() -> void:
	await get_tree().create_timer(4.0).timeout
	print("[chamber] leaving the chamber")
	_leave()


## Does the pact actually cost anything (`M3-T04`, ADR-118)?
##
## Here rather than in the Deep because the Chamber is where a Tithe is paid,
## and the arithmetic under test is the settle — what she asks, what giving
## counts for, and what a short cycle sends after you.
func _tithe_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var tuning: TuningProfile = Config.tuning

	# ── what she asks rises with rank, and never falls ───────────────────
	# **The table, asked directly** (`M3-T01`). This used to assign `pact_rank`
	# and read `tithe_due()` back; rank is derived from the tree now (ADR-125)
	# and the assignments did nothing, so the anchors all read 40 and this
	# probe failed the moment the tree shipped. Asking `tithe_for` is both the
	# honest question and the one that keeps working — see its note for why a
	# manufactured rank-9 tree would be worse than useless here.
	var at_one: int = GameState.tithe_for(1)
	var at_five: int = GameState.tithe_for(5)
	var at_nine: int = GameState.tithe_for(9)
	print("[tithe] the curve    rank 1 %d, rank 5 %d, rank 9 %d" % [
		at_one, at_five, at_nine])
	if not (at_one < at_five and at_five < at_nine):
		problems.append(("the Tithe does not rise with rank (%d, %d, %d) — "
			+ "`DES-003`'s whole coupling is that power costs more, and a flat "
			+ "or falling demand makes growth free") % [at_one, at_five, at_nine])
	# `DES-003` states three anchors outright. They are ⟨tune⟩ and may move, but
	# they may not move *silently*: this is what makes changing them a decision.
	if at_one != 40 or at_five != 260 or at_nine != 900:
		problems.append(("the anchors `DES-003` writes down — 40 / 260 / 900 — "
			+ "now read %d / %d / %d; change them by ADR, not by drift")
			% [at_one, at_five, at_nine])

	# ── giving her something pays it ─────────────────────────────────────
	# Rank is whatever the tree says, and `die()` above left it empty, so this
	# is rank 1 without anybody having to assert it into place (ADR-125).
	GameState.tithe_paid = 0
	GameState.cycle_runs = 0
	GameState.hunt_head_start = 0.0
	var coin: ItemResource = ItemCatalogue.by_id(&"glt_hoard_coin")
	GameState.tribute(ItemInstance.of(coin, 1))
	print("[tithe] one coin     paid %d of %d" % [
		GameState.tithe_paid, GameState.tithe_due()])
	if GameState.tithe_paid != coin.tribute_value:
		problems.append(("giving her something did not pay the Tithe — there is "
			+ "no other way to pay it, so the obligation would be unpayable"))

	# ── a partial cycle costs nothing (`PRO-005 §11`) ────────────────────
	GameState.cycle_runs = tuning.tithe_cycle_runs - 1
	var settled_early: bool = GameState.settle_cycle()
	print("[tithe] mid-cycle    %d run(s) in, settled=%s, paid still %d" % [
		GameState.cycle_runs, settled_early, GameState.tithe_paid])
	if GameState.tithe_paid != coin.tribute_value or GameState.hunt_head_start > 0.0:
		problems.append(("she settled up mid-cycle — `PRO-005 §11` and ADR-029 "
			+ "both say a partial cycle is never punished, and a player who "
			+ "stops for the night must not come back to a penalty"))

	# ── a short cycle sends the Hunt early ───────────────────────────────
	#
	# At **rank 5**, deliberately. A Hoard-Coin is worth 40 and the rank-1 Tithe
	# is 40, so the obvious version of this — one coin, cycle closes — was not
	# short at all and reported settled. The probe was wrong rather than the
	# code, and it took the failure to notice: a case that cannot fail is one
	# more assertion that is true and beside the point (ADR-113).
	#
	# Worth recording on the way past: **one coin covers a whole rank-1 cycle.**
	# Both numbers are ⟨tune⟩ and the collision is coincidence, but a first
	# cycle discharged by a single pickup is a balance question for `M3-T10`,
	# when there is a floor whose richness answers it.
	#
	# **Short by paying less, not by ranking up.** This used to assign
	# `pact_rank = 5` so that one coin fell short of 260. Rank is derived from
	# the tree now (ADR-125) and the assignment did nothing, so the case stopped
	# being short the moment `M3-T01` shipped — a probe whose *setup* silently
	# stopped working, which is a quieter failure than a wrong assertion and
	# the reason the sweep caught this rather than a reader. Part-paying is the
	# same question with nothing borrowed from another system.
	GameState.tithe_paid = 10
	GameState.cycle_runs = tuning.tithe_cycle_runs
	var owed_now: int = GameState.tithe_due()
	var met_short: bool = GameState.settle_cycle()
	print("[tithe] short cycle  paid 10 of %d, settled=%s, head start %.0f s" % [
		owed_now, met_short, GameState.hunt_head_start])
	if met_short:
		problems.append("a cycle paid 10 of %d reported as settled" % owed_now)
	if GameState.hunt_head_start <= 0.0:
		problems.append(("missing a Tithe cost nothing — ADR-029 makes it a "
			+ "soft fail, and a soft fail with no consequence is no fail, "
			+ "which leaves the Tithe with nothing behind it"))
	if GameState.tithe_paid != 0 or GameState.cycle_runs != 0:
		problems.append(("the cycle did not reset after settling, so the next "
			+ "one starts already part-paid or already part-spent"))

	# ── and the debt does not follow you ─────────────────────────────────
	var carried_over: float = GameState.take_hunt_head_start()
	var twice: float = GameState.take_hunt_head_start()
	print("[tithe] taken once   %.0f s then %.0f s" % [carried_over, twice])
	if carried_over <= 0.0 or twice != 0.0:
		problems.append(("the Hunt's head start is not consumed once — a missed "
			+ "cycle is meant to cost the next descent, not every descent after "
			+ "it, which would be the spiral ADR-029 rejected"))

	# ── paying in full costs nothing ─────────────────────────────────────
	GameState.tithe_paid = GameState.tithe_due()
	GameState.cycle_runs = tuning.tithe_cycle_runs
	var met_full: bool = GameState.settle_cycle()
	print("[tithe] paid in full settled=%s, head start %.0f s" % [
		met_full, GameState.hunt_head_start])
	if not met_full or GameState.hunt_head_start > 0.0:
		problems.append(("paying the Tithe in full still sent the Hunt early — "
			+ "an obligation you cannot discharge is a punishment on a timer"))

	# ── and the pact dies with you (`DES-003`) ───────────────────────────
	GameState.tithe_paid = 55
	GameState.cycle_runs = 2
	GameState.hunt_head_start = 90.0
	GameState.die()
	print("[tithe] after death  rank %d, paid %d, runs %d, head start %.0f s" % [
		GameState.pact_rank, GameState.tithe_paid, GameState.cycle_runs,
		GameState.hunt_head_start])
	if GameState.pact_rank != 1 or GameState.tithe_paid != 0 \
			or GameState.cycle_runs != 0 or GameState.hunt_head_start > 0.0:
		problems.append(("the pact survived a death — `DES-003` puts rank and "
			+ "Tithe in the LIFE tier and resets both to 1, and a debt "
			+ "outliving the debtor is the running-debt model ADR-029 rejected "
			+ "arriving through the one door nobody was watching"))

	for problem: String in problems:
		printerr("[tithe] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


## **The pact moves** (`M3-T01`, `DES-003`, `DES-004`, ADR-125).
##
## Pact Rank sat at 1 for the whole of `M3-T04` and `M3-T10`, which built a
## nine-row Tithe table and three axes of floor scaling against a number nothing
## in the project could change (ADR-124 §3). This is the check that it changes,
## and that everything standing on it moves when it does.
func _pact_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var tuning: TuningProfile = Config.tuning

	GameState.die()
	GameState.take_the_oath(&"huskarl")

	# ─ 1. tribute below the Tithe buys nothing but the absence of a punishment ─
	#
	# `DES-004`: *"surplus tribute beyond your Tithe converts to Boon at full
	# rate; tribute below the Tithe converts at nothing and counts against your
	# obligation."* The first half of the coupling `DES-003` is built on.
	var owed: int = GameState.tithe_due()
	var coin: ItemResource = ItemCatalogue.by_id(&"glt_hoard_coin")
	GameState.tribute(ItemInstance.of(coin, 1))
	print("[pact] paid %d of %d owed  → boon %d, toward next %d" % [
		GameState.tithe_paid, owed, GameState.boon, GameState.boon_progress])
	if GameState.boon_progress > 0 or GameState.boon > 0:
		problems.append(("tribute inside the Tithe earned Boon — `DES-004` says "
			+ "it converts at nothing, and paying a debt that also buys power is "
			+ "the obligation `DES-003` §A exists to impose, deleted"))

	# ─ 2. …and the surplus does ─
	var plate: ItemResource = ItemCatalogue.by_id(&"glt_altar_plate")
	# **A cycle at a time**, because `M3-T03` caps how much converts per cycle
	# and a probe that piles forty plates into one is the *carried* case rather
	# than the ordinary one. The first draft of this loop predates the cap and
	# spun forever the moment it arrived — the same shape ADR-126 found in
	# `--tithe-probe`, one task later: a setup that manufactures its premise
	# through another system's rules stops working when those rules land, and
	# it does it silently.
	var runs: int = 0
	while GameState.boon < tuning.node_cost_keystone + 4 and runs < 60:
		GameState.tribute(ItemInstance.of(plate, 1))
		GameState.boon_converted = 0
		runs += 1
	print("[pact] after %d plates      boon %d" % [runs, GameState.boon])
	if GameState.boon <= 0:
		problems.append("no amount of surplus tribute produced Boon, so nothing "
			+ "a run earns can ever be spent")
		_report_pact(problems)
		return

	# ─ 3. the class gate (ADR-009) ─
	#
	# The Húskarl is Scale · Cinder · Hoard, so Hoard is open. The refusal case
	# needs an Aspect they may not enter, and the only other authored one is
	# the Hoard — so what is asserted is the *sentence*, on a node that does
	# not exist, plus the positive case below. `M3-T12` authors the Wing, which
	# the Húskarl may never enter, and is where this becomes a real refusal.
	var refusal: String = GameState.why_not(&"wng_nothing_here")
	print("[pact] unknown node        '%s'" % refusal)
	if refusal == "":
		problems.append("a node this build does not have was allowed, which "
			+ "would let a hand-edited save spend Boon on nothing")

	# ─ 4. prerequisites are a route, not a menu ─
	var gated: String = GameState.why_not(&"hrd_weight_of_kings")
	print("[pact] keystone, unprepared '%s'" % gated)
	if gated == "":
		problems.append(("the keystone was available with none of its path "
			+ "taken — `DES-004`'s model is *take its keystone, take minor "
			+ "nodes down it*, and a tree with no route is a shopping list"))

	# ─ 5. taking nodes raises rank, and rank raises what she expects ─
	var before_rank: int = GameState.pact_rank
	var before_owed: int = GameState.tithe_due()
	var purse: int = GameState.boon
	var route: Array[StringName] = [
		&"hrd_sure_grip", &"hrd_steady_step", &"hrd_ballast",
		&"hrd_long_haul", &"hrd_tally",
	]
	var took: int = 0
	for id: StringName in route:
		if GameState.take_node(id):
			took += 1
		else:
			problems.append("could not take %s: %s" % [id, GameState.why_not(id)])
	print("[pact] took %d node(s)      spent %d, rank %d → %d, tithe %d → %d" % [
		took, GameState.boon_spent(), before_rank, GameState.pact_rank,
		before_owed, GameState.tithe_due()])
	# **The purse, not the ledger.** This asked `boon_spent()`, which is summed
	# from `taken` — so it reported the right number whether or not a single
	# point had actually been deducted, and a plant that made nodes free walked
	# straight through it. Seventh true-but-beside-the-point assertion this
	# milestone, and the first one that was true *by construction*: a derived
	# value cannot witness the thing it is derived from failing to be paid for.
	var paid: int = purse - GameState.boon
	if paid != GameState.boon_spent():
		problems.append(("%d Boon left the purse for a tree that cost %d — "
			+ "`DES-004` makes tribute a real cost and a node you do not pay "
			+ "for is a stat handed out for arriving") % [paid, GameState.boon_spent()])
	if GameState.pact_rank <= before_rank:
		problems.append(("rank did not move after %d Boon spent — `DES-003` "
			+ "makes rank *Boon spent*, and three shipped systems read it: the "
			+ "Tithe table, `RankScaling`, and whether a Gullsjúkr can be "
			+ "killed at all") % GameState.boon_spent())
	if GameState.tithe_due() <= before_owed:
		problems.append(("she expects no more of a stronger player (%d then, %d "
			+ "now) — *power must cost risk* is principle 2, and the Tithe "
			+ "rising is the whole mechanism") % [before_owed, GameState.tithe_due()])

	# ─ 6. the effect seam (`TEC-006`) ─
	#
	# The node never contains logic; it names a rule and the system that owns
	# that rule reads it here. If this is false, every node in the tree is a
	# purchase that does nothing.
	print("[pact] effect reachable    weight_is_silent=%s, unheld tag=%s" % [
		GameState.has_effect(&"weight_is_silent"),
		GameState.has_effect(&"carry_no_limit")])
	if not GameState.has_effect(&"weight_is_silent"):
		problems.append(("a node was taken and its effect tag does not read back "
			+ "— `TEC-006` puts every system's view of the tree behind "
			+ "`has_effect`, so a false here is a tree nothing reacts to"))
	if GameState.has_effect(&"carry_no_limit"):
		problems.append("an effect from a node that was never taken reads true, "
			+ "so the tag lookup is not keyed to what this life actually owns")

	# ─ 7. the keystone becomes reachable once its route is walked ─
	var more: int = 0
	while GameState.boon < tuning.node_cost_keystone and more < 60:
		GameState.tribute(ItemInstance.of(plate, 1))
		GameState.boon_converted = 0
		more += 1
	var open_now: String = GameState.why_not(&"hrd_weight_of_kings")
	print("[pact] keystone, prepared   '%s' (want empty)" % open_now)
	if open_now != "":
		problems.append("the keystone is still refused with its whole path "
			+ "taken and the Boon in hand: '%s'" % open_now)
	GameState.take_node(&"hrd_weight_of_kings")
	print("[pact] primary aspect      '%s'" % GameState.primary_aspect())
	if GameState.primary_aspect() != &"hoard":
		problems.append("taking a keystone did not name the primary Aspect, "
			+ "which is what `DES-004`'s one-keystone rule is read from")

	# **Not asserted here, and deliberately named:** *one keystone at a time*
	# cannot fail while one Aspect is authored, because there is no second
	# keystone to refuse. `M3-T12` is where that rule gets a real test, and
	# claiming it now would be the true-but-beside-the-point assertion this
	# milestone has produced six of.

	# ─ 8. and a player can reach all of it with a mouse ─
	#
	# **ADR-111 arriving a third time.** A `Control` under a `CanvasLayer` gets
	# no layout unless it sets its own offsets, and at 0 x 0 Godot delivers it
	# no mouse events at all — which cost the whole of `M2-T18` on the bag and
	# was caught again on the class select. Every rule above this line can be
	# correct and leave the tree unspendable.
	var screen := PactScreen.new()
	var layer := CanvasLayer.new()
	layer.add_child(screen)
	add_child(layer)
	await get_tree().process_frame
	var rect: Vector2 = screen.size
	var buttons: int = screen.find_children("*", "Button", true, false).size()
	print("[pact] the screen         %.0f x %.0f, %d row(s)" % [
		rect.x, rect.y, buttons])
	if rect.x <= 0.0 or rect.y <= 0.0:
		problems.append(("the Aspects laid out at %.0f x %.0f — nobody could "
			+ "spend a point of Boon with a mouse (ADR-111)") % [rect.x, rect.y])
	if buttons <= 0:
		problems.append("the screen drew no rows, so the tree is unreachable "
			+ "however correct the rules behind it are")

	# **Pressed, not called past.** The rules were all exercised above by
	# calling `take_node` directly; this is the only line that proves a *click*
	# reaches them, which is the distinction `M2-T18` is a whole ADR about.
	while GameState.boon < Config.tuning.node_cost_lesser:
		GameState.tribute(ItemInstance.of(plate, 1))
	screen._redraw()
	await get_tree().process_frame
	var clicked: bool = screen.press(&"hrd_coin_sense")
	print("[pact] pressed a row       %s, taken=%s" % [
		clicked, GameState.has_taken(&"hrd_coin_sense")])
	if not clicked or not GameState.has_taken(&"hrd_coin_sense"):
		problems.append(("a row could not be pressed, or pressing it took "
			+ "nothing — every part of this can work and leave the button "
			+ "joined to nothing, which is the shape ADR-105, ADR-108, ADR-110 "
			+ "and ADR-117 all had"))
	# And a refused node is refused *at the button*, not only in the rules.
	var locked: bool = screen.press(&"hrd_her_reckoning")
	print("[pact] pressed a locked row %s (want false)" % locked)
	if locked:
		problems.append("a node needing rank 4 and a prerequisite was pressable "
			+ "— the screen is drawing rows the rules would refuse")
	layer.queue_free()

	# ─ 9. and the whole tree dies with the life (`DES-003`) ─
	var earned_rank: int = GameState.pact_rank
	GameState.die()
	print("[pact] after death         rank %d → %d, boon %d, taken %d" % [
		earned_rank, GameState.pact_rank, GameState.boon, GameState.taken.size()])
	if earned_rank <= 1:
		problems.append("rank never rose above 1, so the reset below proves "
			+ "nothing about a life that had grown")
	if GameState.pact_rank != 1 or not GameState.taken.is_empty() \
			or GameState.boon != 0 or GameState.boon_progress != 0:
		problems.append(("the tree survived a death — `DES-003`'s reset table "
			+ "gives the skill tree as *all of it*, and rank is derived from "
			+ "exactly that list so clearing it is what returns rank to 1"))


	# ─ **the cap** (`M3-T03`, ADR-011) ─
	#
	# ADR-010 lets a rank-1 player stand on a rank-9 floor and carry rank-9
	# value home. ADR-011 is the line that stops that being a rank-9 tree, and
	# these rows are the only place that claim is checked.
	GameState.hoard.clear()
	GameState.hoard_value = 0
	GameState.lineage_progress = 0
	GameState.boon = 0
	GameState.boon_progress = 0
	GameState.boon_converted = 0
	# Nothing owed, so every point below is surplus and the rows are about the
	# cap rather than about the Tithe eating the haul first.
	GameState.tithe_paid = 9999
	var cap: int = GameState.boon_cap()
	# **Through `tribute()`, not through the arithmetic underneath it.**
	#
	# The first draft called `convert_with_decay` directly and read beautifully,
	# and a plant that made `tribute` ignore the cap **entirely** walked straight
	# past it — the row was testing the calculator while the till was the thing
	# that could be wrong. One carried haul, paid in the way a run pays it.
	var plates: ItemResource = ItemCatalogue.by_id(&"glt_altar_plate")
	var before_carry: int = GameState.lineage_progress
	var carried_out: int = 0
	while carried_out < 900:   # what `DES-003` says a rank-9 cycle is worth
		GameState.tribute(ItemInstance.of(plates, 1))
		carried_out += plates.tribute_value
	var converted: int = carried_out - (GameState.lineage_progress - before_carry)
	print("[pact] rank %d cap %d — carried %d, converted %d, learned %d" % [
		GameState.pact_rank, cap, carried_out, converted, carried_out - converted])
	if cap <= 0:
		problems.append("a rank-1 player has no conversion headroom at all, so "
			+ "the tree is unreachable rather than merely slow")
	if converted >= carried_out:
		problems.append(("a rank-1 player converted %d of %d — ADR-011 says you "
			+ "may be carried but *not carried past your own ability to use "
			+ "what you are given*, and this is a rank-9 tree bought in one run")
			% [converted, carried_out])
	# The wall is soft but it **is** a wall: halving bands sum to twice the cap,
	# so no cycle converts much beyond that however much is carried out.
	if converted > cap * 2:
		problems.append(("%d converted against a cap of %d — halving bands sum "
			+ "to twice the cap, so anything above it means the decay is not "
			+ "compounding and a big enough haul still buys the whole tree")
			% [converted, cap])

	# **And the overflow is not thrown away.** ADR-011 pays the remainder into
	# LINEAGE, which `DES-003` makes power-free by construction — so the run
	# still pays generously (ADR-006) without paying in power.
	GameState.boon_converted = 0   # a fresh cycle, so the bands start over
	var before_learned: int = GameState.lineage_progress
	GameState.tribute(ItemInstance.of(plates, 700))
	var learned: int = GameState.lineage_progress - before_learned
	print("[pact] one plate           boon %d, learned %d, spent cap %d" % [
		GameState.boon, learned, GameState.boon_converted])
	if learned <= 0:
		problems.append("tribute past the cap earned no Lineage — ADR-011 pays "
			+ "the remainder out rather than discarding it, and a carried "
			+ "player is meant to advance fast in knowledge and slowly in power")

	# LINEAGE is the tier death does not touch (`DES-003`).
	var kept_learning: int = GameState.lineage_progress
	GameState.die()
	print("[pact] learning after death %d (was %d)" % [
		GameState.lineage_progress, kept_learning])
	if GameState.lineage_progress != kept_learning:
		problems.append(("what the lineage learned did not survive a death — "
			+ "`DES-003` puts it in the tier that *survives death, always, "
			+ "forever*, and it is the whole compensation for ADR-004"))
	if GameState.boon_converted != 0:
		problems.append("the cycle's conversion headroom survived a death, so "
			+ "a new life would inherit a spent cap")
	_report_pact(problems)


func _report_pact(problems: PackedStringArray) -> void:
	for problem: String in problems:
		printerr("[pact] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


## **She'll only remember three things** (`M3-T05`, ADR-003, ADR-006, ADR-133).
##
## `DES-003` calls the Legacy screen the anti-wipe-cliff mechanism and the piece
## it feels strongest about. Every row here is one of the rules that make it a
## bounded decision rather than percentage retention with extra UI.
func _legacy_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()

	# A life worth losing: gear on, something stashed, and a tree bought.
	GameState.legacy.clear()
	GameState.last_life = {}
	GameState.class_id = &"huskarl"
	# **A tree worth enough to move a rank.** The first draft kept one lesser
	# node and asserted rank rose; a lesser node costs 1 Boon and rank 2 needs
	# more, so the row failed on a claim that was never true of that life
	# rather than on anything the code did. Ballast *and* its keystone is a
	# real route (`why_not` enforces the prerequisite), and 6 Boon is a rank.
	GameState.worn = {"MAIN_HAND": "wpn_seax"}
	GameState.stash.clear()
	GameState.stash.append(ItemInstance.of(
		ItemCatalogue.by_id(&"glt_hoard_coin"), 1))
	GameState.taken.clear()
	GameState.taken.append(&"hrd_ballast")
	GameState.taken.append(&"hrd_weight_of_kings")
	var rank_before: int = GameState.pact_rank

	# ─ 1. death leaves a record, and the record is what is offered ─
	GameState.die()
	var went: Dictionary = GameState.last_life
	print("[legacy] the life that ended  class '%s', %d worn, %d stashed, %d node(s)" % [
		went.get("class_id", ""), (went.get("worn", []) as Array).size(),
		(went.get("stash", []) as Array).size(),
		(went.get("taken", []) as Array).size()])
	if went.is_empty():
		problems.append("death left no record, so there is nothing for her to "
			+ "be asked to remember and `DES-003`'s whole screen has no input")
		_report_pact(problems)
		return
	print("[legacy] and it is over        rank %d → %d, stash %d, tree %d" % [
		rank_before, GameState.pact_rank, GameState.stash.size(),
		GameState.taken.size()])
	if not GameState.stash.is_empty() or not GameState.taken.is_empty():
		problems.append("the life did not actually end — the record is meant to "
			+ "be taken *before* the wipe and the wipe still has to happen, or "
			+ "the screen becomes a life you keep by not choosing")

	# ─ 2. the screen is one flow, in ADR-006's order ─
	var screen := LegacyScreen.new()
	add_child(screen)
	await get_tree().process_frame
	print("[legacy] the screen           %.0f x %.0f, panel %d (want 0)" % [
		screen.size.x, screen.size.y, screen.panel()])
	if screen.size.x < 2.0 or screen.size.y < 2.0:
		problems.append("the Legacy screen has no rect (ADR-111)")
	if screen.panel() != 0:
		problems.append("the flow does not open on *what you learned* — ADR-006 "
			+ "puts it first because it is the answer to the question a player "
			+ "is actually asking after a death")
	var offered: Array[Dictionary] = screen.offers()
	print("[legacy] offered              %d thing(s) and lesson(s)" % offered.size())
	if offered.size() < 4:
		problems.append(("only %d thing(s) offered from a life that wore one, "
			+ "stashed one and bought two — `DES-003` chooses *from what you "
			+ "had*, and a fourth is what gives the cap something to refuse")
			% offered.size())

	# ─ 3. **never raw Boon** (ADR-003) ─
	var boon_refusal: String = GameState.why_not_keep("boon", &"boon")
	print("[legacy] asked for Boon       '%s'" % boon_refusal)
	if boon_refusal == "":
		problems.append("raw Boon could be kept — ADR-003 disallows it because "
			+ "a fungible payload is the optimal pick every time, which "
			+ "collapses this screen into percentage retention with extra UI")

	# ─ 4. three, and no more ─
	# **Named rather than looped**, so the tree that comes back is worth a rank
	# and the fourth thing is left over to be refused. Looping every offer took
	# whatever `offers()` happened to list first, which made both the cap row
	# and the rank row hostage to an ordering neither is about.
	var kept: int = 0
	for wanted: Array in [["item", &"glt_hoard_coin"], ["node", &"hrd_ballast"],
			["node", &"hrd_weight_of_kings"]]:
		if GameState.keep_in_legacy(String(wanted[0]), wanted[1] as StringName):
			kept += 1
	var over_the_cap: String = GameState.why_not_keep("item", &"wpn_seax")
	var refused: bool = not GameState.keep_in_legacy("item", &"wpn_seax")
	print("[legacy] kept                 %d of %d offered (cap %d)" % [
		kept, offered.size(), Config.tuning.legacy_slot_count])
	print("[legacy] a fourth thing       %s — '%s'" % [
		"refused" if refused else "ACCEPTED", over_the_cap])
	if not refused:
		problems.append(("a fourth thing was kept against a cap of %d — "
			+ "`DES-003` bounds power creep *by design rather than by tuning*, "
			+ "and three slots is three slots however many lifetimes accrue")
			% Config.tuning.legacy_slot_count)
	if GameState.legacy.size() > Config.tuning.legacy_slot_count:
		problems.append(("she is keeping %d things against a cap of %d — "
			+ "`DES-003` bounds power creep *by design rather than by tuning*, "
			+ "and three slots is three slots however many lifetimes accrue")
			% [GameState.legacy.size(), Config.tuning.legacy_slot_count])

	# ─ 5. **what comes back is Scarred, and worth nothing to her** ─
	GameState.stash.clear()
	GameState.taken.clear()
	GameState.draw_on_legacy()
	var scarred: int = 0
	var worth: int = 0
	for item: ItemInstance in GameState.stash:
		if item.scarred:
			scarred += 1
		worth += item.tribute_worth()
	print("[legacy] came back            %d stashed, %d Scarred, worth %d to her" % [
		GameState.stash.size(), scarred, worth])
	if GameState.stash.is_empty() and GameState.taken.is_empty():
		problems.append("the slots paid out nothing, so a Legacy slot is a "
			+ "promise with no payload")
	if scarred != GameState.stash.size():
		problems.append(("%d of %d items came back unmarked — `DES-003` says "
			+ "Legacy items are **Scarred**, and one that is not is a full-power "
			+ "item carried across a death") % [
			GameState.stash.size() - scarred, GameState.stash.size()])
	if worth != 0:
		problems.append(("what she remembered is worth %d back to her — a "
			+ "Scarred item **cannot be tributed**, or a Legacy slot launders a "
			+ "hoard through a life you were going to lose anyway, which is raw "
			+ "Boon arriving through the door marked *item*") % worth)

	# ─ 6. a kept node is already bought, and it costs what it always did ─
	print("[legacy] a kept lesson        rank %d (the last life reached %d), "
		% [GameState.pact_rank, rank_before]
		+ "tree %d node(s), tithe %d" % [
			GameState.taken.size(), GameState.tithe_due()])
	if GameState.taken.is_empty():
		problems.append("no lesson came back, so a node in a slot is a payload "
			+ "that pays nothing")
	elif GameState.pact_rank <= 1:
		problems.append(("a tree worth %d node(s) left rank at 1 — `DES-003` "
			+ "derives rank from the tree, so a life that starts with nodes "
			+ "starts **owing more**, which is the coupling working rather "
			+ "than being dodged") % GameState.taken.size())

	_report_pact(problems)


## **The Settle beat** (`M3-T08`, `DES-002`, `DES-016`).
##
## `DES-016` puts deeds *"after the tribute decision, so the run ends on
## evidence of what you did rather than on a balance sheet"* — and the tribute
## decision here is per-item, made by walking to one side of the room or the
## other, with no dialog and therefore no "done" button to hang this on.
##
## An **empty bag is the done button**. Everything you came back with has been
## given or kept, so the sorting is over. A run that came back with nothing has
## nothing to sort and settles the moment you arrive, which is correct: there
## was no decision to be after.
func _settle() -> void:
	if _player == null or _player.inventory.count() > 0:
		return
	if GameState.fresh_deeds.is_empty():
		return
	if _deeds_banner != null and is_instance_valid(_deeds_banner):
		return
	var banner := DeedsBanner.new()
	var layer := CanvasLayer.new()
	layer.layer = 7
	layer.add_child(banner)
	add_child(layer)
	_deeds_banner = banner
	banner.dismissed.connect(func() -> void: layer.queue_free())
	# **Taken, not read.** A deed shown is a deed spent, and one that surfaced
	# twice would read as having been earned twice.
	banner.show_these(GameState.take_fresh_deeds())


## Reachable without a mouse, for `--deeds-probe`.
func deeds_banner() -> DeedsBanner:
	return _deeds_banner


## **Evidence of what you did** (`M3-T08`, `DES-016`, ADR-134).
##
## `DES-016` awards deeds at the Settle beat, *after* the tribute decision, so
## the run ends on evidence rather than on a balance sheet — and **never
## mid-run**, because a popup in the Deep breaks the pressure the whole game is
## built on.
func _deeds_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()

	# ─ 1. the corpus is there, and every deed is one a run can answer ─
	var authored: Array[DeedResource] = DeedCatalogue.all()
	print("[deeds] authored             %d" % authored.size())
	if authored.is_empty():
		problems.append("no deeds authored — every row below is conditional on "
			+ "there being a corpus, which is the guard the item probe already "
			+ "has and the reason an empty export is invisible without it")
		_report_pact(problems)
		return
	for mark: DeedResource in authored:
		for problem: String in mark.validate():
			problems.append(problem)

	# ─ 2. **nothing surfaces mid-run** ─
	#
	# The rule `DES-016` states most firmly, and the one a naive implementation
	# breaks first: award on the event, show it immediately.
	GameState.deeds.clear()
	GameState.fresh_deeds.clear()
	var awarded: bool = GameState.award(&"ded_first_way_out")
	print("[deeds] awarded              %s, waiting to be shown: %d" % [
		awarded, GameState.fresh_deeds.size()])
	if not awarded:
		problems.append("a deed could not be awarded at all")
	if GameState.fresh_deeds.size() != 1:
		problems.append("an awarded deed did not queue for the Settle beat — "
			+ "`DES-016` says deeds surface there and **never in the Deep**, "
			+ "because a popup mid-run breaks the pressure the game is built on")

	# ─ 3. once, and only once ─
	var again: bool = GameState.award(&"ded_first_way_out")
	print("[deeds] the same deed twice  %s (want false)" % again)
	if again:
		problems.append("a deed was earned twice — the first time is the whole "
			+ "record, and it is what makes a camp readable as a history rather "
			+ "than a tally")

	# ─ 4. **another player's name** (ADR-050) ─
	GameState.award(&"ded_bore_them_home", "player_2")
	print("[deeds] whose ember          '%s'" % GameState.deeds.get(
		"ded_bore_them_home", ""))
	if String(GameState.deeds.get("ded_bore_them_home", "")) != "player_2":
		problems.append("a rescue deed did not record who was carried out — "
			+ "ADR-050 puts their name in your save, and it is the first time "
			+ "this profile stores anyone but you")

	# ─ 5. shown is spent ─
	var shown: Array[String] = GameState.take_fresh_deeds()
	print("[deeds] shown                %d, still waiting %d" % [
		shown.size(), GameState.fresh_deeds.size()])
	if shown.size() != 2 or not GameState.fresh_deeds.is_empty():
		problems.append(("the Settle beat took %d and left %d — a deed shown is "
			+ "a deed spent, and one that surfaced twice would read as having "
			+ "been earned twice") % [shown.size(), GameState.fresh_deeds.size()])

	# ─ 6. **it survives a death** ─
	#
	# `DES-016`: *must survive death, LINEAGE tier, always.* `DES-003` is why
	# that is safe to be generous with — power-free by construction.
	var carried: int = GameState.deeds.size()
	GameState.die()
	print("[deeds] after a death        %d (was %d)" % [
		GameState.deeds.size(), carried])
	if GameState.deeds.size() != carried:
		problems.append("deeds did not survive a death — `DES-016` puts them at "
			+ "LINEAGE tier *always*, and a record of what you did that dies "
			+ "with you is a record of nothing")

	# ─ 7. and the Settle beat is what shows them ─
	#
	# The composition. Every row above is about `GameState`; this is the one
	# that asks whether the Chamber ever opens a banner — the join, which is
	# what `check_dead.py` keeps finding by accident.
	GameState.fresh_deeds.append("ded_first_way_out")
	if _player != null:
		_player.inventory.clear()
	_settle()
	await get_tree().process_frame
	var banner: DeedsBanner = deeds_banner()
	print("[deeds] the Settle beat      banner=%s" % (banner != null))
	if banner == null:
		problems.append("the bag was empty and the fire said nothing — "
			+ "`DES-016` puts deeds *after the tribute decision*, and a banner "
			+ "nothing opens is a banner that does not exist")
	elif banner.size.x < 2.0:
		problems.append("the banner has no rect (ADR-111)")

	_report_pact(problems)


## **Respec** (`M3-T13`, `DES-004`, ADR-136).
##
## *"A respec exists but costs real resources and cannot change your keystone
## mid-life. Locking the keystone is what makes the choice matter."* Two claims,
## and the second is the one that makes a build a commitment rather than a
## loadout.
##
## Every row asserts a **state change** (ADR-134): a value read before and after
## the same act, so no row can pass on a number that was already right.
func _respec_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var tuning: TuningProfile = Config.tuning

	# A life with a route bought and its keystone taken.
	GameState.taken.clear()
	GameState.boon = 40
	GameState.legacy.clear()
	# **A life to spend it in.** `why_not` refuses every node with *no life has
	# been sworn yet* otherwise, and the Húskarl is the class that may enter the
	# Hoard — so the probe failed on its own premise rather than on the code,
	# which is the right way round and took two passes to read properly.
	GameState.class_id = &"huskarl"
	# The real route to the keystone, read off the data rather than guessed:
	# sure_grip → steady_step → ballast, long_haul, and coin_sense → quiet_hands
	# as the leaf this probe gives back. The first draft skipped two
	# prerequisites and failed on its own setup, which is the right way round —
	# `take_node` refused, exactly as it should have.
	for step: StringName in [&"hrd_sure_grip", &"hrd_steady_step",
			&"hrd_ballast", &"hrd_long_haul", &"hrd_weight_of_kings",
			&"hrd_coin_sense", &"hrd_quiet_hands"]:
		if not GameState.take_node(step):
			problems.append("could not build the route to a keystone (%s), so "
				% step + "nothing below is about a life that had one")
			_report_pact(problems)
			return
	var rank_before: int = GameState.pact_rank
	var owed_before: int = GameState.tithe_due()
	var boon_before: int = GameState.boon
	print("[respec] a built life        rank %d, owes %d, %d node(s), boon %d" % [
		rank_before, owed_before, GameState.taken.size(), boon_before])

	# ─ 1. **the keystone does not come back** ─
	var keystone_says: String = GameState.why_not_reclaim(&"hrd_weight_of_kings")
	print("[respec] the keystone        '%s'" % keystone_says)
	if keystone_says == "":
		problems.append("a keystone could be given back — `DES-004` says a "
			+ "respec **cannot change your keystone mid-life**, and locking it "
			+ "is what makes the choice matter rather than a loadout")

	# ─ 2. a node something else stands on does not come back either ─
	var footing_says: String = GameState.why_not_reclaim(&"hrd_steady_step")
	print("[respec] a node stood on     '%s'" % footing_says)
	if footing_says == "":
		problems.append("a prerequisite could be given back, which leaves a "
			+ "taken node with its route reclaimed underneath it — nothing "
			+ "refuses that afterwards, because `why_not` is asked when a node "
			+ "is taken and never again")

	# ─ 3. **a leaf does**, and it costs real resources ─
	var leaf_price: int = tuning.node_cost(
		AspectCatalogue.by_id(&"hrd_quiet_hands").tier)
	var gave_back: bool = GameState.reclaim(&"hrd_quiet_hands")
	var refunded: int = GameState.boon - boon_before
	print("[respec] gave back a leaf    %s, paid %d, got %d back" % [
		gave_back, leaf_price, refunded])
	if not gave_back:
		problems.append("nothing could be given back at all, so a respec does "
			+ "not exist")
	if refunded >= leaf_price:
		problems.append(("a respec refunded %d of %d — `DES-004` says it "
			+ "**costs real resources**, and the resource is the Boon that does "
			+ "not come back") % [refunded, leaf_price])
	if refunded <= 0:
		problems.append(("a respec refunded nothing, which deletes a node "
			+ "rather than reconsidering it"))

	# ─ 4. rank falls with the tree, and so does what she expects ─
	print("[respec] and the pact        rank %d → %d, owes %d → %d" % [
		rank_before, GameState.pact_rank, owed_before, GameState.tithe_due()])
	if GameState.pact_rank > rank_before:
		problems.append("giving a node back raised rank")
	if GameState.taken.has(&"hrd_quiet_hands"):
		problems.append("the node is still in the tree after being given back")

	# ─ 5. **the body notices** ─
	#
	# The row `M3-T12` bought. Effect tags were pushed into `Inventory` and
	# `Stamina` once, in `_ready`, and a tree that changed changed nothing —
	# which is invisible everywhere except here, because a respec is the only
	# thing in the game that changes a tree **inside a life**.
	var player: Player = _player
	if player == null:
		problems.append("no body in the Chamber, so nothing here says whether a "
			+ "respec reaches one")
	else:
		player.effects = PackedStringArray(["weightless_materials"])
		await get_tree().process_frame
		var before: bool = player.inventory.weightless_materials
		player.effects = PackedStringArray()
		await get_tree().process_frame
		var after: bool = player.inventory.weightless_materials
		print("[respec] the body notices    %s → %s" % [before, after])
		if not before:
			problems.append("the tag never reached the bag at all, so the row "
				+ "below is about two identical nothings")
		elif after:
			problems.append("the bag kept a rule the tree no longer has — a "
				+ "respec that does not reach the systems reading it changes a "
				+ "list and nothing else")

	# ─ 6. the screen offers it, and refuses the keystone on the screen too ─
	var screen := PactScreen.new()
	add_child(screen)
	await get_tree().process_frame
	# **A leaf.** The first draft pressed Ballast, which the keystone stands on —
	# so the button was correctly disabled and the row caught the probe's own
	# bad choice rather than a fault. Coin-Sense is a leaf once Quiet Hands has
	# been given back above, which is the state this screen is being shown.
	var took_back: bool = screen.press_give_back(&"hrd_coin_sense")
	var refused_keystone: bool = not screen.press_give_back(&"hrd_weight_of_kings")
	print("[respec] on the screen       gave back=%s, keystone refused=%s" % [
		took_back, refused_keystone])
	if not took_back:
		problems.append("no *give it back* on a taken node — the rules are "
			+ "correct and no click reaches them, which is `M2-T18` exactly")
	if not refused_keystone:
		problems.append("the screen offered a keystone back, so the refusal is "
			+ "in `GameState` and not in front of the player")
	screen.queue_free()

	_report_pact(problems)
