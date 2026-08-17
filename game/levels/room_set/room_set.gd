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

## Where the party starts — one point per player, a stride apart across the
## entrance. A single shared point would have two people begin the run standing
## inside each other, which reads as a replication bug on the first frame
## anyone sees.
const SPAWNS: Array[Vector3] = [
	Vector3(-1.2, 0.1, 8.0), Vector3(1.2, 0.1, 8.0),
	Vector3(-3.6, 0.1, 8.0), Vector3(3.6, 0.1, 8.0),
]

## `DES-015`'s Machine is *"a post on a prize, in a room with a single
## entrance"*, so the prize has to be somewhere specific. Named once and used
## by the loot table below as well as by `--prize-probe`: a coordinate written
## in two places is a coordinate that will eventually disagree with itself.
const PRIZE_AT: Vector3 = Vector3(20.3, 0.1, -21.0)

## The authored loot (`M2-T01`). Hand-placed, like the enemy posts: `DES-008`'s
## loot tables need somewhere to place things and the generator is `M4-T01`, so
## `LootTableResource` is **absent rather than approximated** (ADR-064).
##
## The placement is the argument, not decoration. `DES-015` claims the two
## halves of a cycle should *mean different things*, and ADR-032 already made
## west the long safe branch and east the short held one. Loot finishes that
## sentence: **the safe route pays badly.** West carries a lump of bog iron and
## a working knife; east carries coin and gold; the Guardian room carries the
## three things worth the fight.
##
## And you cannot have it all. Everything here totals **42.0 kg across 34
## cells**, against a 6x5 grid — four cells more than the bag has, deliberately,
## and by a margin you notice rather than one you have to measure. Taking the
## altar-plate costs you the byrnie; `--bag-probe` measures that it does, and
## fails if a sweep of the floor ever comes back with everything in the bag.
##
## Weight is not a second gate and is not meant to be: **space decides what you
## can carry, weight decides what it costs you** (`--bag-probe` again, and the
## note there). The greedy sweep ends at 31.0 kg — 78% laden, walking at 2.21
## rather than 3.40 m/s and audible from 27.7 m. Nothing stopped the player
## reaching that state; that is `DES-008`'s tug-of-war arriving as a fact about
## a floor rather than a paragraph about an economy.
const LOOT: Array = [
	# west — the bypass route (ADR-032), and it pays for the walk in materials
	["mat_bog_iron", Vector3(-9.4, 0.1, -6.0)],
	["wpn_seax", Vector3(-10.2, 0.1, -14.5)],
	# junction — weightless, valuable, and loud. The purest "is this worth it?"
	["glt_raw_gemstone", Vector3(-2.0, 0.1, -22.0)],
	# east — the held corridor. Short, guarded, and where the glitter is
	["glt_hoard_coin", Vector3(9.4, 0.1, -8.0)],
	["glt_gilded_torc", Vector3(10.8, 0.1, -13.5)],
	# the Guardian's room — one entrance, no way out but back past it
	["glt_altar_plate", PRIZE_AT],
	["rlc_regin_blade", Vector3(19.2, 0.1, -23.4)],
	["arm_mail_byrnie", Vector3(19.4, 0.1, -18.8)],
	# One Waystone, in the guarded half. **Hand-placed, and its rarity is not
	# tuned here** — `DES-005` calls the drop rate *"the strongest single lever
	# in the game"*, and a drop *rate* needs the loot tables `M4-T01` builds.
	# What this floor can answer is the question underneath it: is a way out
	# worth two squares and a walk past the Guardian?
	["con_waystone", Vector3(17.6, 0.1, -21.0)],
]

## Godot's host is always peer 1, offline peer included.
const HOST_PEER: int = 1

## Where the Gullsjúkr starts (`M2-T02`). The far end of the guardian wing,
## behind the Prize — so it begins between you and nothing, and the first time
## you meet it is on the walk *out* with a full bag, which is `DES-017`'s
## *"make the extraction walk the tensest part of the run"*.
##
## `DES-017` puts it on floor 2 and later, absent from floor 1 to protect the
## quiet opening. There is one floor, so it is here — and that is a scoping
## consequence recorded in ADR-089, not a design change.
const HUNTER_POST: Vector3 = Vector3(21.0, 0.1, -25.0)

## The field's footprint, a little wider than the room bounds so a doorway on
## the outer wall still has a cell on both sides of it.
const FIELD_FROM: Vector3 = Vector3(-16.0, 0.0, -36.0)
const FIELD_TO: Vector3 = Vector3(26.0, 0.0, 14.0)

## The Shaft, in the room the layout has called "exit" since `M1-T03` — which
## `--route-probe` already proves is reachable without crossing an encounter
## (ADR-032). `DES-005` requires the Shaft's location to be *known*, and a
## fixed point in a hand-built level is as known as it gets.
const SHAFT_AT: Vector3 = Vector3(0.0, 0.05, -29.0)

## How far apart the heaviest and lightest kilograms-per-cell on this floor
## must be before `--bag-probe` accepts that space and weight are two different
## constraints (`DES-019`). Not a tuned value — a floor under "these are not
## the same instrument twice". The authored set currently spans 59x.
const DENSITY_SPREAD_FLOOR: float = 3.0

var _session: CoopSession = null
var _field: ClamorField = null
var _hunter: Gullsjukr = null
var _shaft: Shaft = null
var _descent: int = 1

## Someone left the floor alive, and what they took. `M2-T07` instruments
## per-capita extracted value off this; `M2-T06` will hang the Lair on it.
signal extracted(player: Player, tribute: int)

@onready var _world: Node3D = $World


func _ready() -> void:
	_build_lighting()
	for name: String in ROOMS:
		_build_room(name)
	_spawn_actors()
	# What you emit and what they perceive, on the floor (ADR-078). This set has
	# corners and doorways, which is the only place occlusion has anything to
	# show — the gym it came from is mostly open ground.
	_build_hunt()
	_build_shaft()
	var overlays := DebugOverlays.new()
	_world.add_child(overlays)
	overlays.show_field(_field)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-top="):
			_capture_top(arg.split("=", true, 1)[1])
		elif arg == "--route-probe":
			_route_probe()
		elif arg == "--prize-probe":
			_prize_probe()
		elif arg == "--bag-probe":
			_bag_probe()
		elif arg.begins_with("--bag-shot="):
			_bag_shot(arg.split("=", true, 1)[1])
		elif arg == "--hunt-probe":
			_hunt_probe()
		elif arg == "--ear-probe":
			_ear_probe()
		elif arg.begins_with("--ear-shot="):
			_ear_shot(arg.split("=", true, 1)[1])
		elif arg == "--exit-probe":
			_exit_probe()
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
##
## `M2-T01` changed what the Prize *is* — an `ItemResource` with a name and a
## footprint rather than 16 kg of nothing — and deliberately did **not** change
## what this measures. The item is lighter than the old constant (14.0 kg
## against 16.0), so if the assertion still holds it holds for the right
## reason: because weight bites, not because the number was generous.
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
	_take_nearest(player)
	var after_speed: float = await _walk_speed(player)
	var after_heard: float = player.clamor.audible_radius()

	print("[set] walk speed   %5.2f → %5.2f m/s   (%+.0f%%)" % [
		before_speed, after_speed,
		(after_speed / before_speed - 1.0) * 100.0 if before_speed > 0.0 else 0.0])
	print("[set] heard from   %5.1f → %5.1f m      at the moment of lifting it" % [
		before_heard, after_heard])
	print("[set] carrying     %5.1f kg (%.0f%% laden)  %s" % [
		player.carried.kilograms, player.carried.encumbrance() * 100.0,
		_carried_names(player)])
	get_tree().quit(0 if after_speed < before_speed else 1)


## Walk the floor, take everything, and report what it costs (`M2-T01`).
##
## This is the M2 gate question asked in numbers: *a playtester voluntarily
## abandons loot to survive.* That decision is only real if the bag can be
## filled past the point of usefulness and if abandoning something visibly
## buys back speed and quiet — so the probe fills it, records what refused to
## fit and why, then drops the heaviest thing and measures the relief.
##
## ## What the two constraints actually do, which this probe had to learn
##
## The first version asserted that space *and* weight each refuse a pickup, and
## it failed — correctly, and not the way it expected. **Weight never refuses
## anything.** ADR-050's cap is the *slot* cap, `DES-019` gives the grid the
## gating job, and `carry_capacity` is the denominator encumbrance is measured
## against rather than a wall. `CarriedWeight` even clamps its penalty at 1.0
## on purpose, so that a bad decision stays recoverable.
##
## So the two constraints are not two gates. They are:
##
## > **Space decides what you can carry. Weight decides what it costs you.**
##
## That is a sharper reading of `DES-019` than "two gates" and it makes the M2
## gate question sharper too: you abandon loot not because nothing else fits,
## but because what you already have is too expensive to walk home with.
##
## Three assertions, all of which can genuinely fail:
##
## 1. **The floor holds more than the bag can take.** Otherwise there is no
##    decision on this level at all, only a shopping trip.
## 2. **The two constraints measure different things.** Kilograms per cell has
##    to vary widely across what is on the floor, or the grid and the scales
##    are the same instrument twice and one of them is redundant — which is
##    exactly the collapse `DES-019` is guarding against when it asks for a
##    bulky-light bolt of cloth and a tiny-ruinous bag of coin.
## 3. **Dropping one item buys back speed and quiet.** `DES-005`'s primal
##    counter-play, measured rather than assumed.
func _bag_probe() -> void:
	var player: Player = _session.local_player()
	var inventory: Inventory = player.inventory
	var grid: Vector2i = inventory.grid()
	print("[bag] grid %dx%d = %d cells, capacity %.0f kg" % [
		grid.x, grid.y, grid.x * grid.y, Config.tuning.carry_capacity])

	# Kilograms per cell, over what this floor actually offers. The spread is
	# the measurement: the grid and the scales are only two instruments if the
	# same square can hold wildly different amounts of trouble.
	var lightest: float = INF
	var heaviest: float = 0.0
	var lightest_name: String = ""
	var heaviest_name: String = ""
	for row: Array in LOOT:
		var known: ItemResource = ItemCatalogue.by_id(row[0] as StringName)
		var cells: int = known.grid_size.x * known.grid_size.y
		var density: float = known.weight / float(cells)
		if density < lightest:
			lightest = density
			lightest_name = known.display()
		if density > heaviest:
			heaviest = density
			heaviest_name = known.display()
	print("[bag] kg per cell  %.2f (%s) … %.2f (%s) — a %.0fx spread" % [
		lightest, lightest_name, heaviest, heaviest_name,
		heaviest / lightest if lightest > 0.0 else INF])

	var refused_space: int = 0
	var offered: int = 0
	for row: Array in LOOT:
		offered += 1
		var at: Vector3 = row[1] as Vector3
		player.teleport(at + Vector3(0.0, 0.1, 1.0), 0.0)
		for i: int in range(4):
			await get_tree().physics_frame
		var before: int = inventory.count()
		_take_nearest(player)
		await get_tree().physics_frame
		if inventory.count() > before:
			continue
		var known: ItemResource = ItemCatalogue.by_id(row[0] as StringName)
		refused_space += 1
		print("[bag] no room for %s (%s cells, %d free)" % [
			known.display(), known.grid_size,
			grid.x * grid.y - inventory.cells_used()])

	# Captured here, not read at the end: the assertions below run *after* the
	# drop, and the first version compared a post-drop count against what was
	# offered. It therefore could not fire — planting an oversized grid proved
	# the bag taking all eight items passed silently, which is the class of
	# green-tick-that-cannot-fail ADR-084 was written about.
	var taken: int = inventory.count()
	var laden_speed: float = await _walk_speed(player)
	var laden_heard: float = player.clamor.audible_radius()
	var laden_still: float = _standing_radius(player)
	print("[bag] took %d of %d offered — %.1f kg (%.0f%% laden), %d/%d cells" % [
		taken, offered, player.carried.kilograms,
		player.carried.encumbrance() * 100.0, inventory.cells_used(),
		grid.x * grid.y])
	print("[bag] carrying     %s" % _carried_names(player))
	print("[bag] laden        %5.2f m/s   heard %4.1f m walking, %4.1f m standing still" % [
		laden_speed, laden_heard, laden_still])

	# Abandon the worst of it, exactly as a cornered player would: the panic
	# dump, through the same host-validated path.
	var dropped: ItemInstance = inventory.heaviest()
	var dropped_name: String = dropped.definition.display()
	var dropped_kilograms: float = dropped.weight()
	player.ask_to_drop_instance(dropped.instance_id)
	await get_tree().physics_frame
	player.clamor.silence()
	var freed_speed: float = await _walk_speed(player)
	var freed_still: float = _standing_radius(player)
	print("[bag] dropped      %s (%.1f kg)" % [dropped_name, dropped_kilograms])
	print("[bag] unladen      %5.2f m/s   heard %4.1f m standing still" % [
		freed_speed, freed_still])
	print("[bag] the relief   %+.0f%% speed, %+.1f m of quiet" % [
		(freed_speed / laden_speed - 1.0) * 100.0 if laden_speed > 0.0 else 0.0,
		laden_still - freed_still])

	var problems: PackedStringArray = PackedStringArray()
	if taken >= offered:
		problems.append("the floor holds %d items and the bag took all of them — "
			% offered + "there is no decision on this level, only a shopping trip")
	if refused_space == 0:
		problems.append("nothing was ever refused for space — the grid is not "
			+ "constraining anything and DES-019's spatial puzzle is decoration")
	# Three-to-one is not a tuned number, it is a floor under "these are two
	# different instruments". The authored corpus currently spans 59x.
	if lightest <= 0.0 or heaviest / lightest < DENSITY_SPREAD_FLOOR:
		problems.append(("kg-per-cell spans only %.1fx across this floor — below "
			+ "%.1fx the grid and the scales measure the same thing, and DES-019's "
			+ "two constraints have collapsed into one")
			% [heaviest / maxf(lightest, 0.0001), DENSITY_SPREAD_FLOOR])
	if freed_speed <= laden_speed:
		problems.append("dropping the heaviest item did not make the player faster")
	if freed_still >= laden_still:
		problems.append("dropping the heaviest item did not make the player quieter")
	for problem: String in problems:
		printerr("[bag] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


## Reach for whatever is nearest, through the shipping path. Deliberately not a
## direct `Inventory.add`: the thing worth measuring is the host-validated
## request, and a probe that reached past the authority check would stop
## measuring the code that ships (`TEC-004`).
func _take_nearest(player: Player) -> void:
	var item: WorldItem = WorldItem.nearest(player, player.global_position,
		Config.tuning.interact_reach)
	if item == null:
		return
	player.reach_for(item)


## Metres this player is heard from with the noise of moving fully decayed —
## the `ClamorSource` floor their bag imposes, and the number that answers
## *"can I hide with all this on me?"*
func _standing_radius(player: Player) -> float:
	player.clamor.silence()
	return player.clamor.audible_radius()


func _carried_names(player: Player) -> String:
	var names: PackedStringArray = PackedStringArray()
	for item: ItemInstance in player.inventory.items():
		names.append(item.definition.display())
	return "· ".join(names) if names.size() > 0 else "(nothing)"


## Does the Hunt work the way `DES-017` says it does (`M2-T02`)?
##
## Four claims, and every one of them is a claim a lazier implementation would
## satisfy by cheating. Each is checked in a way that **fails if the Gullsjúkr**
## **is ever given the player's transform**, which is the single most likely
## shortcut anyone will reach for here.
##
## 1. **It goes to the noise, not to you.** The load-bearing one. Make a loud
##    sound at one end of a corridor, move the player far away in silence, and
##    the Hunter must walk to *where the sound was*. `TEC-001`: *"it genuinely
##    does not know where you are — it knows where noise was."*
## 2. **A rich silent player is found anyway.** `DES-017`'s middle sense.
##    Carrying nothing and standing still must not be equivalent to carrying a
##    hoard and standing still, or *"going quiet is not enough"* is a slogan.
## 3. **Stripping down makes you uninteresting.** The same player, having put
##    the gold down, must stop registering. This is the counter-play, and it is
##    the M2 gate question wearing an enemy's sensory model.
## 4. **Gold diverts it.** A thrown purse worth enough must pull it off you and
##    hold it — `DES-017`: *"it will stop and pick it up. Every time."*
func _hunt_probe() -> void:
	var player: Player = _session.local_player()
	var hunter: Gullsjukr = _hunter
	if hunter == null:
		printerr("[hunt] FAIL no Gullsjúkr in the level")
		get_tree().quit(1)
		return
	var problems: PackedStringArray = PackedStringArray()

	# ─ 1. noise, not you ─
	#
	# The player is parked in the *west* corridor and made loud there, then
	# teleported to the far *east* corridor and silenced. If the Hunter walks
	# east it is reading a transform; if it walks west it is reading the field.
	var noise_at: Vector3 = Vector3(-9.0, 0.1, -10.0)
	var hide_at: Vector3 = Vector3(9.0, 0.1, -10.0)
	hunter.global_position = Vector3(-9.0, 0.1, -22.0)
	player.inventory.clear()
	player.teleport(noise_at, 0.0)
	await _hold(0.3)
	player.clamor.add(Config.tuning.clamor_maximum)
	print("[hunt] the deposit  %.1f in the field, %.1f in the cell it was made in" % [
		_field.total(), _field.level_at(player.global_position)])
	await _hold(0.6)
	# Gone, and silent, before the Hunter has had time to arrive.
	player.teleport(hide_at, 0.0)
	player.clamor.silence()
	var started: Vector3 = hunter.global_position
	await _hold(2.5)
	var moved: Vector3 = hunter.global_position - started
	var toward_noise: float = moved.dot((noise_at - started).normalized())
	var toward_player: float = moved.dot((hide_at - started).normalized())
	print("[hunt] chased noise  %+.2f m toward the sound, %+.2f m toward the player" % [
		toward_noise, toward_player])
	if toward_noise <= toward_player:
		problems.append("the Hunter moved toward the player rather than toward the "
			+ "noise — it is reading a transform, and TEC-001 says it must not")

	# ─ 2 and 3. wealth, through walls and through silence ─
	#
	# Same position, same silence, twice. The only thing that changes between
	# the two samples is what is in the bag, so nothing else can explain a
	# difference in what the Hunter does.
	var watch_from: Vector3 = Vector3(9.4, 0.1, -8.0)
	hunter.global_position = Vector3(9.0, 0.1, -20.0)
	player.teleport(watch_from, 0.0)
	player.inventory.clear()
	player.clamor.silence()
	await _hold(0.6)
	var poor_target: bool = hunter.target() != null
	for row: Array in LOOT:
		var definition: ItemResource = ItemCatalogue.by_id(row[0] as StringName)
		if definition != null and definition.tribute_value > 0:
			player.inventory.add(definition)
	player.clamor.silence()
	await _hold(0.6)
	var rich_target: bool = hunter.target() != null
	print("[hunt] wealth sense  carrying %d: %s   carrying nothing: %s" % [
		player.inventory.total_tribute(),
		"seen" if rich_target else "unseen",
		"seen" if poor_target else "unseen"])
	if not rich_target:
		problems.append("a silent player carrying a hoard went unnoticed — DES-017's "
			+ "middle sense is what makes going quiet insufficient")
	if poor_target:
		problems.append("a silent player carrying nothing was still hunted — then "
			+ "giving up loot buys nothing and the counter-play is decorative")

	# ─ 4. gold diverts it ─
	#
	# Thrown through the real path, so what is measured is the verb that ships.
	var before_state: int = hunter.state_index
	player.ask_to_drop_instance(player.inventory.richest().instance_id, true)
	await _hold(1.2)
	var collecting: bool = hunter.state() == Gullsjukr.State.COLLECTING
	print("[hunt] the bait      state %s → %s" % [
		Gullsjukr.State.keys()[before_state],
		Gullsjukr.State.keys()[hunter.state_index]])
	if not collecting:
		problems.append("a thrown purse did not divert the Hunter — DES-017 calls "
			+ "this the best interaction in the design and it must be reliable")

	print("[hunt] field         %d cells, %.1f total clamor, %.1f m wealth range" % [
		_field.width() * _field.height(), _field.total(), hunter.wealth_range()])
	for problem: String in problems:
		printerr("[hunt] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


## Do both channels carry the same thing (`M2-T03`, ADR-036)?
##
## `DES-018` makes this the project's most easily-lost guarantee: *"a visual
## language for Clamor cannot be bolted on at the end, because by then every
## system will assume the mix is carrying the information and there will be
## nowhere for it to attach."* The standing test is that a run is completable
## with audio muted — which no automated check can play. What it *can* do is
## refuse the way that guarantee actually breaks: **an audio channel with no
## visual twin.**
##
## Three assertions:
##
## 1. **Parity, in both directions.** Every `HuntMix` channel is drawn by the
##    Ear, and the Ear draws nothing that is not a channel. A one-way check
##    would let the score grow a fifth layer nobody renders.
## 2. **The mix actually moves.** A director that reported zeroes forever would
##    pass parity perfectly, which is the shape of a green tick that cannot
##    fail — so noise must raise `clamor`, and the Hunter must raise `hunter`.
## 3. **The bait beat exists in both channels.** `DES-018` calls the drop when
##    the Gullsjúkr is distracted a designed beat and *the player's window*. A
##    muted player who never sees it never gets the window.
func _ear_probe() -> void:
	var player: Player = _session.local_player()
	var problems: PackedStringArray = PackedStringArray()

	# 1. parity
	var channels: Array[String] = HuntMix.CHANNELS.duplicate()
	var drawn: Array[String] = Ear.RENDERED.duplicate()
	channels.sort()
	drawn.sort()
	print("[ear] channels     mix %s" % [", ".join(channels)])
	print("[ear] rendered     ear %s" % [", ".join(drawn)])
	if channels != drawn:
		problems.append(("the mix carries %s and the Ear draws %s — ADR-036 "
			+ "requires every channel to have a twin, in both directions")
			% [", ".join(channels), ", ".join(drawn)])

	# 2. the mix moves
	player.inventory.clear()
	player.clamor.silence()
	await _hold(0.4)
	var quiet: float = AudioDirector.mix.clamor
	player.clamor.add(Config.tuning.clamor_maximum)
	await _hold(0.2)
	var loud: float = AudioDirector.mix.clamor
	print("[ear] your clamor  %.2f quiet → %.2f loud" % [quiet, loud])
	if loud <= quiet:
		problems.append("making noise did not move the mix's clamor channel")

	# The score has to answer it too, or the visual is the only channel and the
	# twin has failed from the other side.
	await _hold(1.8)
	var levels: Dictionary = AudioDirector.layer_levels()
	print("[ear] score        %s" % [_levels_line(levels)])
	if float(levels["drone"]) <= AudioDirector.SILENCE_DB + 0.5:
		problems.append("a loud player did not bring the score in — the visual "
			+ "channel is carrying this alone")

	# 3. the Hunter, and the bait beat
	if _hunter != null:
		_hunter.global_position = player.global_position + Vector3(4.0, 0.0, 0.0)
		await _hold(0.4)
		var present: float = AudioDirector.mix.hunter
		print("[ear] the hunter   %.2f present, bearing %s" % [present,
			"none" if not AudioDirector.mix.has_bearing() else "%.0f deg"
				% rad_to_deg(AudioDirector.mix.bearing)])
		if present <= 0.0:
			problems.append("the Gullsjúkr is on the floor and the mix does not "
				+ "say so — DES-018 has its mark appear when its instrument does")
		if not AudioDirector.mix.has_bearing():
			problems.append("the Hunter is beside the player and the mix reports no "
				+ "bearing — DES-018 requires 'where is it' to be answerable "
				+ "without stereo hearing")

	print("[ear] pressure     %.2f" % AudioDirector.mix.pressure())
	for problem: String in problems:
		printerr("[ear] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


## Photograph the Ear at four pressures (`M2-T03`).
##
## `--ear-probe` runs headless and never draws a pixel, and `DES-018` is a
## **legibility** document — a readout that is correct and unreadable has
## failed. The four states have to be distinguishable at a glance and with the
## colour taken out, and the only way to know that is to look.
##
## Same reason `--bag-shot` exists, and it found two defects headless checks
## could not.
func _ear_shot(path: String) -> void:
	var player: Player = _session.local_player()
	var samples: Array = [
		["quiet", 0.0, false],
		["loud", Config.tuning.clamor_maximum, false],
		["hunted", Config.tuning.clamor_maximum * 0.5, true],
	]
	for sample: Array in samples:
		player.clamor.silence()
		player.teleport(Vector3(0.0, 0.1, 4.0), 0.0)
		if _hunter != null:
			# Parked far off unless this sample wants it, so "quiet" is really
			# quiet rather than quiet-with-a-Hunter-in-the-corner.
			_hunter.global_position = (player.global_position + Vector3(5.0, 0.0, 2.0)
				if bool(sample[2]) else Vector3(21.0, 0.1, -25.0))
		await _hold(0.3)
		player.clamor.add(float(sample[1]))
		await _hold(0.4)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot: String = "%s_%s.png" % [path.trim_suffix(".png"), sample[0]]
		get_viewport().get_texture().get_image().save_png(shot)
		print("[ear] %-7s clamor %.2f  alert %.2f  hunter %.2f  → %s" % [
			sample[0], AudioDirector.mix.clamor, AudioDirector.mix.alert,
			AudioDirector.mix.hunter, shot.get_file()])
	get_tree().quit()


## Can you leave, and does leaving late cost more (`M2-T04`, `DES-005`)?
##
## Five assertions, and the first is the one ADR-015 states as an absolute:
##
## 1. **You are never trapped.** *"The player is never truly trapped — the
##    Shaft is always reachable, just increasingly expensive."* Checked at full
##    escalation, which is precisely where a Sealing implemented as a lock
##    would have quietly broken it.
## 2. **The Sealing bites.** The channel and the noise both grow with the
##    Hunt's age, or staying costs nothing and `DES-005` Layer 3 is decoration.
## 3. **The Waystone caps at one** (ADR-015, Q54), or `DES-019`'s binary
##    indicator is a lie.
## 4. **Spending it consumes it**, and what leaves with you does not include it.
## 5. **Extraction reports what you carried** — the loop closing, and the thing
##    that makes `--bag-probe`'s agonising mean anything.
func _exit_probe() -> void:
	var player: Player = _session.local_player()
	var problems: PackedStringArray = PackedStringArray()
	var waystone: ItemResource = ItemCatalogue.by_id(&"con_waystone")

	# ─ 2 and 1. the price of leaving late, and that it stays payable ─
	_hunter.age = 0.0
	await get_tree().physics_frame
	var early_seconds: float = _shaft.channel_seconds()
	var early_clamor: float = _shaft.channel_clamor()
	_hunter.age = Config.tuning.shaft_seal_seconds * 2.0
	await get_tree().physics_frame
	var late_seconds: float = _shaft.channel_seconds()
	var late_clamor: float = _shaft.channel_clamor()
	print("[exit] the shaft    %.1f s / %.1f clamor early → %.1f s / %.1f late" % [
		early_seconds, early_clamor, late_seconds, late_clamor])
	if late_seconds <= early_seconds or late_clamor <= early_clamor:
		problems.append("the Shaft costs no more late than early — DES-005 Layer 3 "
			+ "is decoration if staying is free")
	if not is_finite(late_seconds) or late_seconds <= 0.0:
		problems.append(("the Shaft is unusable at full escalation (%.1f s) — ADR-015 "
			+ "guarantees the player is never truly trapped") % late_seconds)

	# ─ 3. one Waystone, never two ─
	player.inventory.clear()
	var first: ItemInstance = player.inventory.add(waystone)
	var second: ItemInstance = player.inventory.add(waystone)
	print("[exit] the cap      first %s, second %s" % [
		"taken" if first != null else "refused",
		"taken" if second != null else "refused"])
	if first == null:
		problems.append("a Waystone could not be picked up at all")
	if second != null:
		problems.append("a second Waystone was accepted — ADR-015 caps it at one so "
			+ "DES-019's indicator can stay a single lit or unlit mark")

	# ─ 4 and 5. spending it, and what leaves with you ─
	var coin: ItemResource = ItemCatalogue.by_id(&"glt_hoard_coin")
	player.inventory.add(coin)
	var before_tribute: int = player.inventory.total_tribute()
	_extracted_tribute = -1
	if not extracted.is_connected(_on_probe_extracted):
		extracted.connect(_on_probe_extracted)
	player.teleport(SHAFT_AT + Vector3(0.0, 0.1, 0.0), 0.0)
	player.ask_to_spend_waystone()
	await _hold(2.0)
	print("[exit] the waystone carried %d tribute in, reported %d out, %s left" % [
		before_tribute, _extracted_tribute,
		"a stone" if player.inventory.waystone() != null else "no stone"])
	if _extracted_tribute < 0:
		problems.append("spending a Waystone did not extract the player")
	if player.inventory.waystone() != null:
		problems.append("the Waystone survived being spent — ADR-015 consumes it")

	for problem: String in problems:
		printerr("[exit] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


var _extracted_tribute: int = -1


func _on_probe_extracted(_player: Player, tribute: int) -> void:
	_extracted_tribute = tribute


func _levels_line(levels: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for name: String in levels:
		var db: float = float(levels[name])
		parts.append("%s %s" % [name,
			"off" if db <= AudioDirector.SILENCE_DB + 0.5 else "%.0f dB" % db])
	return "  ".join(parts)


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

## Beside the hoard-coin in the east corridor, which is on the client's route
## anyway. A `glt_` item on purpose: it has weight *and* clamor, so one pickup
## exercises both host-owned consequences at once.
const PROBE_TAKE_FROM: Vector3 = Vector3(9.4, 0.1, -6.8)
const PROBE_TIMEOUT_MSEC: int = 15000

var _probe_clamor_peak: Dictionary = {}
var _probe_walk_clamor: Dictionary = {}
var _probe_walked: Dictionary = {}
var _probe_heights: Dictionary = {}
var _probe_bags: Dictionary = {}
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

	# 5. The client picks something up (`M2-T01`). Two different claims land in
	#    one gesture, and they travel in opposite directions:
	#
	#    * **weight** is host-derived and replicated host→peer, so the *host*
	#      reporting the right kilograms for a body it is not playing is
	#      replication working;
	#    * **the bag** is host-owned and pushed to its owner by RPC, so the
	#      *client* knowing what is in its own bag is that push working.
	#
	#    Neither peer can fake the other's half. A client that helpfully added
	#    the item to its own inventory would still show a host that never heard
	#    of it, and `run_coop.py` compares the two files.
	if not host:
		mine.teleport(PROBE_TAKE_FROM, 0.0)
	await _hold(0.6)
	if not host:
		_take_nearest(mine)
	await _hold(0.8)
	_probe_bags = _probe_bag_state()

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
		"bags": _probe_bags,
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


## What each body is carrying, as both peers see it. Kilograms come from the
## replicated `CarriedWeight`; the item count comes from the `Inventory` this
## process holds, which on a client is only ever what the host sent it.
func _probe_bag_state() -> Dictionary:
	var out: Dictionary = {}
	for player: Player in _session.players():
		out[player.name] = {
			"items": player.inventory.count(),
			"kilograms": player.carried.kilograms,
		}
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


## The authored loot, asked for rather than built (`M2-T01`).
##
## **Every line of pickup logic this file used to hold is gone.** The Prize was
## a gold block with a hand-rolled reach check, an RPC pair and a hardcoded
## 16 kg; it is now `glt_altar_plate` in the same spot, and the reach check, the
## RPCs and the weight all live on `Player` and `WorldItem` where every other
## item can use them. Moved, not copied (the ADR-073 rule) — a level-local
## second loot path would diverge from the real one the first time either was
## tuned, and the room set would then stop testing what ships.
##
## `_process` went with it: highlighting is `Player._update_reach`, which
## already runs per frame on the body that can actually reach something.
##
## Gold is still the only saturated colour in the game (`ART-005`), and the
## altar-plate still carries it — `WorldItem` reads that off the `glitter` tag
## rather than from a constant in this file.
func _spawn_loot() -> void:
	for row: Array in LOOT:
		_session.spawn_world_item(row[0] as StringName, row[1] as Vector3)


## The Hunt (`M2-T02`): the field, then the thing that navigates it.
##
## The field is added on every peer and simply does nothing on a client — it
## refuses to process there (`TEC-001`: host-only, never replicated). Building
## it unconditionally keeps the level free of a networking branch, which is the
## property `_spawn_actors` already relies on.
func _build_hunt() -> void:
	_field = ClamorField.new()
	_field.name = "ClamorField"
	add_child(_field)
	_field.configure(FIELD_FROM, FIELD_TO)
	_hunter = _session.spawn_hunter(HUNTER_POST)
	if _hunter != null:
		_hunter.hunt_with(_field)


## The way out (`M2-T04`). Authored geometry in the room the layout has always
## called "exit" — `DES-005` says the Shaft's *location is known*, and a fixed
## place `--route-probe` already asserts a clean path to is exactly that.
##
## Built on every peer rather than spawned: it never moves and never varies, so
## a spawn packet would be describing something both sides could already
## derive. Its **use** is a host-validated request all the same.
func _build_shaft() -> void:
	_shaft = Shaft.new()
	_shaft.name = "Shaft"
	_shaft.position = SHAFT_AT
	_world.add_child(_shaft)
	_shaft.claimed.connect(_on_extracted)
	for player: Player in _session.players():
		player.extracted.connect(_on_extracted)
	_session.player_spawned.connect(func(player: Player) -> void:
		player.extracted.connect(_on_extracted))


## The Shaft is channelled here rather than driving itself, so the level owns
## the one clock that can end a run. `Shaft.advance` is host-guarded, so this
## costs a client nothing.
func _physics_process(delta: float) -> void:
	if _shaft != null:
		_shaft.advance(delta)


## Someone got out (`M2-T04`). **This is the Settle beat, and almost none of it
## is built** — `DES-019` wants punch, the hoard, the keep-or-give decision made
## physically, and deeds surfaced here and nowhere else. Those need the Lair
## (`M2-T06`) and `DES-016`, so what happens today is: report what came out, and
## descend again.
##
## Reporting and re-descending is not a stand-in for the Settle screen. It is
## the *loop closing*, which is the thing `M2-T04` owes and the thing that makes
## `--bag-probe`'s question answerable at all: you now find out whether the loot
## you agonised over actually left with you.
func _on_extracted(player: Player) -> void:
	if not multiplayer.is_server():
		return
	var carried: Array[String] = []
	for item: ItemInstance in player.inventory.items():
		carried.append(item.definition.display())
	print("[exit] descent %d — %s left with %.1f kg, %d tribute: %s" % [
		_descent, player.name, player.carried.kilograms,
		player.inventory.total_tribute(),
		"· ".join(carried) if carried.size() > 0 else "(nothing)"])
	extracted.emit(player, player.inventory.total_tribute())
	_descend_again()


## Put the floor back and send everyone down again.
##
## The Lair belongs between these two things (`M2-T06`) and is **absent, not
## faked** — there is no fake hub, no fake stash screen. What you keep is
## printed and then gone, which is honest about there being nowhere yet to
## put it.
func _descend_again() -> void:
	_descent += 1
	for node: Node in get_tree().get_nodes_in_group(WorldItem.GROUP):
		node.queue_free()
	_session.clear_enemies()
	await get_tree().process_frame
	for post: Vector3 in ENEMY_POSTS:
		_session.spawn_enemy(post)
	_session.spawn_enemy(GUARDIAN_POST)
	_spawn_loot()
	var index: int = 0
	for player: Player in _session.players():
		player.inventory.clear()
		player.clamor.silence()
		player.teleport(SPAWNS[index % SPAWNS.size()], 0.0)
		index += 1
	if _hunter != null:
		_hunter.global_position = HUNTER_POST
		# A fresh floor is a fresh Hunt. Cross-floor persistence (ADR-037) is
		# about descending *within* a run and needs the floors `M4-T01` builds;
		# this is a new descent, which is the one case where resetting is right.
		_hunter.age = 0.0


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
	_spawn_loot()


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


## Fill a bag, open it, and photograph it (`M2-T01`).
##
## Two jobs, and the second is the one that justifies it. **`--bag-probe` runs
## headless and never draws a pixel** — `_draw`, `_process` and the whole cursor
## path are dead code to it, which is precisely the shape of the untested
## lifecycle the churn probe was written about. This runs windowed, so every
## line the bag screen owns actually executes and a runtime error in it fails
## the run rather than waiting for a playtester.
##
## The first job is that `DES-019` is a legibility document and legibility is
## judged by looking. A grid you cannot read is not a grid that works, however
## correct its packing arithmetic.
func _bag_shot(path: String) -> void:
	var player: Player = _session.local_player()
	for row: Array in LOOT:
		player.teleport((row[1] as Vector3) + Vector3(0.0, 0.1, 1.0), 0.0)
		for i: int in range(4):
			await get_tree().physics_frame
		_take_nearest(player)
	player.teleport(PRIZE_AT + Vector3(0.0, 0.1, 2.5), 0.0)
	# Through the real input path, not a back door: the bag has to open the way
	# a player opens it or the screenshot is of something nobody can reach.
	#
	# `parse_input_event` and **not** `Input.action_press`, which is what the
	# other probes use. `action_press` only sets the polled state that
	# `is_action_pressed` reads — it dispatches no event, so `_unhandled_input`
	# never sees it and an event-driven action silently does nothing. Movement
	# probes get away with it because movement is polled; this one did not, and
	# the first screenshot was of a closed bag.
	var press := InputEventAction.new()
	press.action = &"bag"
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().process_frame
	# Long enough for `bag_open_time` to run out, so this is the fully open
	# state rather than a frame of it fading in.
	for i: int in range(40):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[bag] %d item(s) drawn, %.1f kg, wrote %s" % [
		player.inventory.count(), player.carried.kilograms, path])
	get_tree().quit()


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
