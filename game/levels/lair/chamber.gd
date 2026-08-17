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
## **The Tithe, Pact Rank, and the Legacy screen** — `M3-T04` and `M3-T05`.
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
var _hoard_root: Node3D = null
var _readout: Label = null


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
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--lair-probe":
			_lair_probe()
		elif arg.begins_with("--chamber-shot="):
			_chamber_shot(arg.split("=", true, 1)[1])


## A body, instantiated rather than spawned. See the class note: the absence of
## a session is what makes "never networked" structural instead of remembered.
func _spawn_body() -> void:
	_player = preload("res://actors/player/player.tscn").instantiate() as Player
	_player.name = "player_1"
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
		return
	if at.distance_to(global_position + STASH_AT) <= PLACE_REACH:
		GameState.keep(item)
		print("[lair] kept %s — the stash holds %d" % [
			item.definition.display(), GameState.stash.size()])
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
		"open the bag and drag an item out:",
		"  at the pile ahead   she keeps it",
		"  at the chest left   you keep it, until you die",
		"  anywhere else       it is on the floor",
		"",
		"walk onto the pale slab behind you to reach the Threshold",
	])
	# Standing on the door is leaving. No prompt: `DES-019` puts nothing in the
	# centre of the screen, and a doorway you walk through needs no verb.
	if _player.global_position.distance_to(global_position + DOOR_AT) <= 1.6:
		_leave()


func _leave() -> void:
	set_process(false)
	# Anything still in the bag is still yours, and comes with you — you have
	# not decided about it yet, and the game does not decide for you.
	var undecided: Array[ItemInstance] = []
	for item: ItemInstance in _player.inventory.items():
		undecided.append(item)
	GameState.carried = undecided
	get_tree().change_scene_to_file("res://levels/lair/threshold.tscn")


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
