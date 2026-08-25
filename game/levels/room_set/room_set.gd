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

# ── the lighting language (`M2-T13`, ADR-105) ─────────────────────────────
#
# One rule, and nothing in the Deep may break it:
#
#   > **Pale light is the way through. Gold light is what it will cost you.**
#
# This is wayfinding done as level design rather than as UI, which is what
# `DES-019` requires: orientation is a thing you *equip*, never a thing the HUD
# hands you, so a quest marker or a minimap is not available to us and should
# not be. The player follows pale light to move and reads gold light as greed.
#
# **`ART-005` chose the palette, not this file.** Gold is the only saturated
# hue in the game and it is spent on treasure, the ember and her fire — so the
# way out must *not* be warm, however natural that feels. Warm belongs to the
# Threshold, which `ART-002` and `ART-005` both make the only resolved, safe,
# finished place. A gold exit would say "safety" in the vocabulary the game
# uses for "this will kill you", and the two readings are not compatible.
#
# The floor previously had **one directional sun and flat 0.85 ambient**, which
# is the exact inverse of the accepted direction (*"darkness is the paper"*) and
# is why six rooms were indistinguishable: with everything lit equally, placed
# light carries no information at all.
#
# **The lantern is what finishes this** and it is not built — see `M4-T13`.
# Until it exists the ambient floor stays navigable rather than truly dark,
# because a dark level with no light source is not a mechanic, it is a bug.
# That floor is the one number here expected to fall.
## Groups rather than counted children, so `--sight-probe` asserts the rule
## against the built world instead of against the constants it was built from.
## A probe that reads `DOORS.size()` would pass with every light missing.
const DOOR_LIGHT_GROUP: StringName = &"door_light"
const LANDMARK_GROUP: StringName = &"landmark"

## How much redder than bluer a light has to be before `--sight-probe` calls it
## warm. Generous: `PALE` is very slightly blue and the treasure gold is far
## past this, so the margin only has to separate two things that are nowhere
## near each other — a tight threshold here would be a false alarm waiting for
## the first time somebody nudges a colour.
const GOLD_MARGIN: float = 0.08

const PALE: Color = Color(0.82, 0.85, 0.90)
const AMBIENT: Color = Color(0.30, 0.31, 0.36)
const AMBIENT_ENERGY: float = 0.34  # ⟨tune⟩ — drops when the lantern lands
const PAPER: Color = Color(0.04, 0.04, 0.05)

## Doorways carry the pale light, so a room shows you its exits from inside it.
## This is the single largest wayfinding win available here: the rooms did not
## need to become more distinct nearly as much as the *ways out of them* did.
const DOOR_LIGHT_ENERGY: float = 1.5  # ⟨tune⟩
const DOOR_LIGHT_RANGE: float = 7.0   # ⟨tune⟩
const DOOR_LIGHT_HEIGHT: float = 2.6

## One silhouette per room, so "the room with the well" is a sentence a player
## can say to a teammate. `DES-015`'s legibility rule — *readable within 30
## seconds of arriving* — written for authored biomes at `M4`, applied here at
## blockout scale because the gate needs it now.
##
## Shape only, no colour: `ART-005` gives the Deep bone-white ink on black, and
## a landmark that announced itself with hue would be spending the treasure
## budget on scenery.
## These are **solid**, so where they stand matters as much as what they look
## like: the first draft put the guardian room's altar squarely on top of the
## Waystone, and the symptom appeared three probes away as *"dropping the
## heaviest item did not make the player faster"* — true, about a player standing
## inside a block of stone. `--sight-probe` now drops a body-sized sphere at
## every authored position and fails if anything is in the way.
const LANDMARKS: Dictionary = {
	"entrance": ["arch", Vector3(0.0, 0.0, 4.0)],
	"west": ["barricade", Vector3(-9.0, 0.0, -10.0)],
	"east": ["pillar", Vector3(9.0, 0.0, -13.0)],
	# Off the exit line on purpose. Dead centre is the most memorable place to
	# put the landmark and the worst place to put an obstacle: the junction's
	# north door is at x = 0, so a well there sits square in everybody's path
	# out. Four and a half metres west keeps it the first thing you see on
	# entering and stops it being the thing you walk into while leaving.
	# Far enough west to clear the Raw Gemstone at x = -2. At -4.5 the well's
	# outer kerb and a body's width overlapped it by 20 cm, which would have
	# made one piece of authored loot unpickupable — invisible in every
	# screenshot, and exactly what the sphere check is for.
	"junction": ["well", Vector3(-6.5, 0.0, -22.0)],
	# Well clear of the prize cluster (x ≥ 17.6) and off the door line at
	# z = -21. The guardian room needs a landmark least of anywhere — it already
	# has the only gold thing in the game standing in it — so it gives way.
	"guardian": ["altar", Vector3(14.2, 0.0, -24.4)],
	# **Not a stair.** The exit room is 6 m square with the way out in the middle
	# of it: a three-step stair needs 2.4 m and there are 2.2 m between the
	# Shaft and the north wall, so every placement either clipped the Shaft or
	# buried a step in masonry. Two pillars flanking it instead — they frame the
	# way out without standing on it, they fit, and they rhyme with the arch at
	# the entrance, so the two ends of a run are marked the same way.
	"exit": ["gate", Vector3(0.0, 0.0, -29.0)],
}

## A player capsule is 0.35 across; a little more than that is what "somewhere
## you could stand" means. Used by `--sight-probe` and nothing else — the real
## body's radius lives on its own collision shape and is not this constant.
const BODY_RADIUS: float = 0.45

## Where a standing player's eyes are, for sightline checks. The camera's real
## height lives on the player scene; this is the probe's approximation of it and
## is deliberately a little low, so a beacon that only just passes here is
## comfortably visible in play rather than marginally so.
const EYE_HEIGHT: float = 1.6

## Navigation bake settings (`M2-T14`). The radius matches `Enemy.NAV_RADIUS`:
## baking a mesh narrower than the agents that walk it produces paths they
## cannot follow, which looks exactly like no pathfinding at all.
const NAV_AGENT_RADIUS: float = 0.45
const NAV_AGENT_HEIGHT: float = 1.8
const NAV_SOURCE_GROUP: StringName = &"navigation_source"

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

## Metres between an authored post and the extra bodies a larger party brings.
## Comfortably more than two body radii (0.35 each), because two capsules
## spawned inside each other shove each other apart and the shove is
## host-side — which reads on a client as the two peers disagreeing about
## where an enemy nobody has touched is standing.
const SPREAD: float = 1.6

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
## **The two things that are not loot** (`M2-T17`, ADR-110).
##
## Both of the floor's decisions live in the guarded half, and both used to sit
## at the end of `LOOT`, which is scaled by party size by taking a **prefix**.
## Solo takes four of nine, so neither of these has ever existed in a solo run —
## the only way anybody currently plays. Measured: `a way out other than the
## Shaft: NO`, `anything in the Guardian's room: NO`.
##
## They are not quantity. The Prize is ADR-032's greed decision — one entrance,
## no way out but back past the Guardian — and without it that room is a dead
## end with a monster in it, and the Gullsjúkr starts the run guarding nothing.
## The Waystone is half of `DES-005`'s way out, and `DES-005` calls its rarity
## *"the strongest single lever in the game"*: a lever that is deterministically
## off at party size 1 is not a lever. The HUD advertises `v waystone` and
## prints `waystone none`, which is a verb offered and never grantable.
##
## So they are **fixtures**: always present, at every party size, like the Shaft.
## Only `FILLER` below is divided among the party, which is what keeps
## `DES-012`'s per-capita curve — the thing `M2-T07` is about — untouched.
const FIXTURES: Array = [
	# the Guardian's room — one entrance, no way out but back past it
	["glt_altar_plate", PRIZE_AT],
	# One Waystone, in the guarded half. **Hand-placed, and its rarity is not
	# tuned here** — a drop *rate* needs the loot tables `M4-T01` builds. What
	# this floor can answer is the question underneath it: is a way out worth
	# two squares and a walk past the Guardian?
	["con_waystone", Vector3(17.6, 0.1, -21.0)],
]

## Everything that is quantity rather than a decision, divided by party size.
const FILLER: Array = [
	# west — the bypass route (ADR-032), and it pays for the walk in materials
	["mat_bog_iron", Vector3(-9.4, 0.1, -6.0)],
	["wpn_seax", Vector3(-10.2, 0.1, -14.5)],
	# junction — weightless, valuable, and loud. The purest "is this worth it?"
	["glt_raw_gemstone", Vector3(-2.0, 0.1, -22.0)],
	# east — the held corridor. Short, guarded, and where the glitter is
	["glt_hoard_coin", Vector3(9.4, 0.1, -8.0)],
	["glt_gilded_torc", Vector3(10.8, 0.1, -13.5)],
	["rlc_regin_blade", Vector3(19.2, 0.1, -23.4)],
	["arm_mail_byrnie", Vector3(19.4, 0.1, -18.8)],
]

## Everything authored on this floor, fixtures first so anything that still
## reads the whole table sees them.
const LOOT: Array = FIXTURES + FILLER

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
var _navigation: NavigationRegion3D = null
var _descent: int = 1
## True while a probe is driving this level. Probes measure the floor and must
## not be dropped into the Lair halfway through a measurement.
var _probing: bool = false
## True while a wipe is counting down, so four bodies going out together start
## one run-end rather than four (`M2-T16`).
var _ending: bool = false
## A peer id for the second body the wipe probe needs. Not a real peer and never
## on a wire: with the offline peer the host is the only process there is, so a
## spawn addressed to a stranger simply builds a body nobody drives.
const TEAMMATE_PEER: int = 9001

## Someone left the floor alive, and what they took. `M2-T07` instruments
## per-capita extracted value off this; `M2-T06` will hang the Lair on it.
signal extracted(player: Player, tribute: int)

## Somebody's ember reached the exit in somebody else's bag — **the M2 co-op
## gate, as an event** (`DES-012`). `M3-T05`'s Legacy screen is what will read
## it; today it is reported and probed.
signal rescued(saved_peer: int, by: Player)

@onready var _world: Node3D = $World


func _ready() -> void:
	# **First, before anything reads it.** Any probe at all means this process
	# is measuring the floor rather than playing the loop — extraction must not
	# change scene out from under it, and the arrival brief must not fade three
	# labels across a screenshot. This used to be decided *after* `_build_hud`,
	# so a HUD element asking `_probing` would silently always see `false`.
	for arg: String in OS.get_cmdline_user_args():
		if arg.contains("probe") or arg.contains("shot") or arg.contains("capture"):
			_probing = true
	AudioDirector.enter("deep")
	_build_lighting()
	for name: String in ROOMS:
		_build_room(name)
		_build_landmark(name)
	_spawn_actors()
	# What you emit and what they perceive, on the floor (ADR-078). This set has
	# corners and doorways, which is the only place occlusion has anything to
	# show — the gym it came from is mostly open ground.
	# Before the actors, so the first enemy to think has a map to think on.
	_build_navigation()
	_build_hunt()
	_build_shaft()
	var overlays := DebugOverlays.new()
	_world.add_child(overlays)
	overlays.show_field(_field)
	_build_hud()
	add_child(PauseMenu.new())
	# After `_probing` is known and never before it. A probe that inherited a
	# loadout would be measuring a bag it did not pack — and the reason this is
	# a real hazard rather than a hypothetical one is that it reads correct
	# today only because a fresh process starts with an empty stash. The gate
	# is here rather than inside, so `--exit-probe` can still call it directly
	# and assert what it does.
	if not _probing:
		_carry_the_stash_down()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-top="):
			_capture_top(arg.split("=", true, 1)[1])
		elif arg == "--route-probe":
			_route_probe()
		elif arg == "--sight-probe":
			_sight_probe()
		elif arg == "--nav-probe":
			_nav_probe()
		elif arg.begins_with("--sight-shot="):
			_sight_shot(arg.split("=", true, 1)[1])
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
		elif arg == "--wipe-probe":
			_wipe_probe()
		elif arg == "--bagui-probe":
			_bagui_probe()
		elif arg == "--toll-probe":
			_toll_probe()
		elif arg == "--extraction":
			_extraction()
		elif arg == "--fallen-probe":
			_fallen_probe()
		elif arg == "--ember-probe":
			_ember_probe()
		elif arg == "--scaling-probe":
			_scaling_probe()
		elif arg.begins_with("--ember-shot="):
			_ember_shot(arg.split("=", true, 1)[1])
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

	# **Silence is the default** (`ART-002`, `M2-T09`). The check above proves
	# the score answers a loud player; this proves it says nothing to a quiet
	# one, and only the pair is worth anything. `ART-002` asks for Floor 1 at
	# low clamor to be *near-silent* — *"if the music always plays, the layers
	# have nowhere to go"* — and a score that never rests loses the escalation
	# it exists to provide, quietly and without ever failing anything.
	#
	# **Only the layers that read your own noise.** The first draft of this
	# check asserted the whole score falls silent, and it failed immediately on
	# the Hunter's note — correctly. The heartbeat is the room having heard
	# something and the Hunter's note is the Hunter being on this floor;
	# neither is untrue because you have since stopped moving, and a score that
	# went quiet when a Gullsjúkr was thirty metres away would be lying to you
	# about the most important fact available. The rule is *your* silence gets
	# quiet, not that the world does.
	player.clamor.silence()
	await _hold(AudioDirector.CROSSFADE + 1.2)
	var resting: Dictionary = AudioDirector.layer_levels()
	print("[ear] at rest      %s" % _levels_line(resting))
	for named: String in ["drone", "pulse"]:
		if float(resting[named]) > AudioDirector.SILENCE_DB + 0.5:
			problems.append(("the %s is still playing to a silent player — "
				+ "ART-002 makes the first drone an *event*, and a score with "
				+ "nowhere left to escalate to is one that has stopped saying "
				+ "anything") % named)
	if float(resting["bed"]) <= AudioDirector.SILENCE_DB + 0.5:
		problems.append("the ambient bed stopped as well — silence is the "
			+ "score resting, not the room disappearing")

	# The score has to answer it too, or the visual is the only channel and the
	# twin has failed from the other side.
	player.clamor.add(Config.tuning.clamor_maximum)
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
## The eye's half of `--sight-probe` (`M2-T13`, ADR-105).
##
## The probe counts lights, checks colours and casts one ray. **None of that is
## the question.** The question is whether a person standing at the spawn can
## tell where to go, and the only way to answer it is to look — which is the
## same lesson `--ear-shot` earned the hard way when it found the Ear rendering
## entirely off-screen while every headless check passed.
##
## Four places on the route out, each photographed from standing height:
## the spawn, the fork where the loop splits, the junction every route crosses,
## and the guardian's doorway — the one committal choice on the floor.
func _sight_shot(path: String) -> void:
	var player: Player = _session.local_player()
	# Ink off, for the same reason `_capture_top` turns it off: `ART-005`'s pass
	# is a treatment on top of the lighting and would be judged here instead of
	# it. What is being looked at is where the light is.
	player.show_ink(false)
	# Yaw 0 is -Z, which is *into* the level: the rooms run north from the
	# entrance at +Z. Facing 180 photographs the wall behind the spawn, which
	# is the first thing this shot did and the reason it is worth stating.
	var views: Array = [
		["spawn", Vector3(0.0, 0.1, 8.0), 0.0],
		["fork", Vector3(0.0, 0.1, 1.0), 0.0],
		["junction", Vector3(0.0, 0.1, -22.0), 0.0],
		["guardian", Vector3(11.0, 0.1, -21.0), -90.0],
	]
	for view: Array in views:
		player.teleport(view[1] as Vector3, deg_to_rad(float(view[2])))
		await _hold(0.3)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot: String = "%s_%s.png" % [path.trim_suffix(".png"), view[0]]
		get_viewport().get_texture().get_image().save_png(shot)
		print("[sight] %-9s → %s" % [view[0], shot.get_file()])
	get_tree().quit()


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

	# ─ and back down again ─
	#
	# The other end of the same loop. `DES-014` puts the loadout in the Chamber
	# and the Descent is the doorway, so what you kept has to arrive in the bag
	# on the next floor — and for two milestones it did not, because nothing
	# ever called `GameState.withdraw()` and the stash was write-only (ADR-098).
	#
	# **This tests the last hop only**, and says so rather than implying more:
	# the full claim spans Chamber → Threshold → floor, and a probe living in
	# one scene can honestly assert that a stash present at generation ends up
	# in the body. That is the hop that was missing.
	player.inventory.clear()
	GameState.stash.clear()
	GameState.keep(ItemInstance.of(ItemCatalogue.by_id(&"glt_hoard_coin"), 1))
	_carry_the_stash_down()
	print("[exit] and down     bag %d item(s), stash %d left" % [
		player.inventory.count(), GameState.stash.size()])
	if player.inventory.count() != 1:
		problems.append("what was kept in the Chamber did not come back down — "
			+ "DES-014 makes the stash a loadout, and a stash you can only put "
			+ "things into is a hole")
	if not GameState.stash.is_empty():
		problems.append("an item came down and stayed in the stash as well — it "
			+ "has to move, or keeping something duplicates it every descent")
	GameState.stash.clear()
	player.inventory.clear()

	for problem: String in problems:
		printerr("[exit] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


var _extracted_tribute: int = -1
var _rescued_peer: int = -1


func _on_probe_extracted(_player: Player, tribute: int) -> void:
	_extracted_tribute = tribute


func _on_probe_rescued(saved_peer: int, _by: Player) -> void:
	_rescued_peer = saved_peer


## Going down, bleeding out, and being carried home (`M2-T05`, `DES-012`).
##
## The M2 co-op gate is *"someone carries a friend's ember out and it is the
## best moment of the session"*. Whether it is the best moment is a playtest
## question; whether it is **possible** is this.
##
## Six assertions:
##
## 1. **Zero health is down, not dead.** `DES-012`'s whole mitigation rests on
##    the two being different events.
## 2. **Down is not out.** You crawl — slower than walking, faster than
##    nothing — and you cannot swing.
## 3. **The window shortens on its own**, whatever anyone does (ADR-050).
## 4. **Solo's one self-recovery gets you up**, below full health, and only
##    once (ADR-050). A *teammate's* hand cannot be tested here — there is one
##    player — and is asserted in the two-process co-op smoke instead.
## 5. **Bleeding out drops an ember bound to you**, and it is heavy and loud.
## 6. **Carrying it out saves that life**, and the ember costs the rescuer real
##    kilograms and real quiet on the way — without which the rescue is a
##    formality rather than the sacrifice `DES-012` asks for.
func _ember_probe() -> void:
	var player: Player = _session.local_player()
	var problems: PackedStringArray = PackedStringArray()
	player.inventory.clear()
	player.teleport(Vector3(0.0, 0.1, 4.0), 0.0)
	await _hold(0.3)

	# ─ 1. zero health is down ─
	player.health.apply_damage(player.health.maximum * 2.0)
	await _hold(0.2)
	print("[ember] on zero     downed %s, spent %s, window %.1f s" % [
		player.is_downed(), player.spent, player.bleeding])
	if not player.is_downed():
		problems.append("zero health did not put the player down — DES-012's whole "
			+ "mitigation is that down and dead are different events")
	if player.spent:
		problems.append("zero health killed the player outright, skipping the window")

	# ─ 2. crawling, and unable to fight ─
	var crawl: float = await _walk_speed(player)
	print("[ember] crawling    %.2f m/s against %.2f walking" % [
		crawl, Config.tuning.walk_speed])
	if crawl <= 0.0 or crawl >= Config.tuning.walk_speed:
		problems.append("a downed player is not crawling (%.2f m/s) — DES-012 wants "
			% crawl + "them moving and going nowhere")

	# ─ 3. the window shortens by itself ─
	var before_window: float = player.bleeding
	await _hold(1.0)
	var after_window: float = player.bleeding
	print("[ember] the window  %.1f s → %.1f s with nobody helping" % [
		before_window, after_window])
	if after_window >= before_window:
		problems.append("the bleed-out window did not shorten — ADR-050 makes the "
			+ "shortening itself the decision")

	# ─ 4. solo's one self-recovery ─
	#
	# ADR-050: *"once per run, costly, and never better than having a friend."*
	# Both halves are checked — that it works, and that it is gone afterwards.
	var had_recovery: bool = player.has_self_recovery()
	player.ask_to_self_recover()
	await _hold(0.3)
	var recovered_up: bool = not player.is_downed()
	var recovered_health: float = player.health.fraction()
	print("[ember] self-rescue up %s at %.0f%% health, another available: %s" % [
		recovered_up, recovered_health * 100.0, player.has_self_recovery()])
	if not had_recovery or not recovered_up:
		problems.append("solo's self-recovery did not get the player up — DES-012 "
			+ "needs a solo analogue or downing is strictly worse alone")
	if recovered_health >= 1.0:
		problems.append("self-recovery returned full health — it has to cost "
			+ "something, and stay worse than a friend's hand")
	if player.has_self_recovery():
		problems.append("self-recovery is still available after being used — "
			+ "ADR-050 allows it once per run")

	# Back down again, to test the death that follows an unanswered window.
	player.health.apply_damage(player.health.maximum * 2.0)
	await _hold(0.2)

	# ─ 5. bleeding out drops a bound ember ─
	#
	# Solo, so there is nobody to be rescued *by*; the ember is picked up by
	# the same player on their next descent, which is exactly what the probe
	# needs and is not a thing that happens in a real run.
	#
	# **This is now the only body in the level, so bleeding out starts a wipe**
	# (`M2-T16`, ADR-108). Step 6 stands the player back up well inside
	# `party_wipe_seconds` and that calls it off — which is a real dependency on
	# a ⟨tune⟩ number, so it is asserted below rather than relied on quietly. A
	# window tuned shorter than this probe's own pacing would otherwise end the
	# run underneath the rescue and fail step 6 for a reason nothing named.
	var floor_before_death: int = _descent
	var fell_at: Vector3 = player.global_position
	player.bleeding = 0.02
	await _hold(0.5)
	# **Checked here, before anything reads the floor.** A wipe resets the floor,
	# which frees every world item — including the ember step 5 is about to look
	# for. Left to be discovered below, that reads as *"bleeding out dropped no
	# ember"*, which is a true sentence about a false cause and would send
	# somebody hunting through `_on_died_here` for a bug that is a tuning value.
	if _descent != floor_before_death:
		problems.append(("the run ended before the ember could be measured — "
			+ "this is the only body in the level, so bleeding out starts a "
			+ "wipe, and `party_wipe_seconds` (%.1f s) is shorter than the "
			+ "time this probe takes to stand the player back up. The rescue "
			+ "below is unmeasurable, not broken")
			% Config.tuning.party_wipe_seconds)
		_report(problems, "ember")
		return
	var ember: WorldItem = null
	for node: Node in get_tree().get_nodes_in_group(WorldItem.GROUP):
		var found := node as WorldItem
		if found != null and found.bound() != 0:
			ember = found
	print("[ember] the drop    %s, bound to %d, %.1f kg / %.1f clamor" % [
		"found" if ember != null else "MISSING",
		ember.bound() if ember != null else 0,
		ember.definition().weight if ember != null else 0.0,
		ember.definition().clamor if ember != null else 0.0])
	if ember == null:
		problems.append("bleeding out dropped no ember — there is nothing for a "
			+ "friend to carry and the M2 co-op gate cannot happen")
		# **Report and stop.** Everything below needs an ember to carry, and a
		# GDScript runtime error aborts the function it happens in — so a null
		# dereference here would never reach the reporting at the bottom and
		# the run would hang until `--quit-after` killed it, printing nothing.
		# Found by planting a frozen bleed-out window: the probe crashed
		# silently instead of failing, which is the one thing a check must
		# never do.
		_report(problems, "ember")
		return
	else:
		if ember.bound() != player.get_multiplayer_authority():
			problems.append("the ember is not bound to whoever died — a rescue "
				+ "cannot know whose life it saved")
		if ember.global_position.distance_to(fell_at) > 2.0:
			problems.append("the ember did not drop where they fell")
		if ember.definition().weight <= 0.0 or ember.definition().clamor <= 0.0:
			problems.append("the ember is not heavy and loud — DES-012 makes the "
				+ "weight and noise the reason rescue is a sacrifice")

	# ─ 6. carrying it out saves that life, and costs the carrier ─
	var owner_peer: int = player.get_multiplayer_authority()
	player.restore_for_descent()
	await _hold(0.2)
	var clean_speed: float = await _walk_speed(player)
	var clean_quiet: float = _standing_radius(player)
	player.teleport(ember.global_position + Vector3(0.0, 0.1, 1.0), 0.0)
	await _hold(0.4)
	player.reach_for(ember)
	await _hold(0.3)
	var burdened_speed: float = await _walk_speed(player)
	var burdened_quiet: float = _standing_radius(player)
	print("[ember] the burden  %.2f → %.2f m/s, heard %.1f → %.1f m standing still" % [
		clean_speed, burdened_speed, clean_quiet, burdened_quiet])
	if burdened_speed >= clean_speed or burdened_quiet <= clean_quiet:
		problems.append("carrying an ember costs the rescuer nothing — DES-012 makes "
			+ "the sacrifice the entire reason the rescue is a decision")

	_rescued_peer = -1
	if not rescued.is_connected(_on_probe_rescued):
		rescued.connect(_on_probe_rescued)
	player.teleport(SHAFT_AT, 0.0)
	await _hold(0.4)
	player.reach_for_shaft_now()
	await _hold(_shaft.channel_seconds() + 1.5)
	print("[ember] the rescue  reported saved peer %d (expected %d)" % [
		_rescued_peer, owner_peer])
	if _rescued_peer != owner_peer:
		problems.append("carrying the ember to the exit did not save that life — "
			+ "which is the whole of the M2 co-op gate")

	# ─ 7. an ember saves the person it names, and nobody else ─
	#
	# **The tag is the identity** (ADR-094). Embers all look alike on purpose —
	# a piece of *her* fire, not a team marker — so the thing that has to be
	# unambiguous is what the ember *does*, and that is checkable in a way an
	# appearance never was.
	#
	# Carrying one out saves its `bound_to` and only that. An ember bound to
	# somebody else in your bag is inert cargo: it will not save you, it will
	# not save the person whose ember you *should* have picked up, and it will
	# not stand in for one. That is the guarantee this asserts, and it is what
	# stops a rescue from becoming a lottery under pressure.
	var stranger: int = owner_peer + 1
	var mine: ItemResource = ItemCatalogue.by_id(&"con_ember")
	player.inventory.clear()
	var wrong: ItemInstance = player.inventory.add(mine)
	wrong.bound_to = stranger
	var saved: Array[int] = player.inventory.embers()
	print("[ember] the tag     carrying an ember bound to %d saves %s" % [
		stranger, str(saved)])
	if saved.size() != 1 or saved[0] != stranger:
		problems.append(("an ember bound to %d reports saving %s — the tag is "
			+ "the only thing that says whose life this is, and carrying "
			+ "somebody else's must never stand in for your own")
			% [stranger, str(saved)])
	player.inventory.clear()

	_report(problems, "ember")


## Per-capita yield and noise by party size (`M2-T07`, `DES-012`).
##
## `DES-012` asks for exactly this, from the first playable build: *"per-capita
## extracted value by party size, tracked from the first playable build"* —
## because it is the number that tells you whether one way of playing has
## quietly become the correct one, and by the time that is obvious in play it
## is a year of balance debt.
##
## **What is measured and what is not.** Actual extracted value needs real
## players making real choices, and no probe can produce that; it is a playtest
## metric and stays one. What a probe *can* do is measure the thing that value
## is drawn from — how much is on the floor per person, and how loud each
## person's noise makes the party — and refuse the shapes that would break the
## relationship:
##
## 1. **Per-capita loot falls** as the party grows. If it rises or holds, a
##    four-stack is the optimal farm and solo is a handicap.
## 2. **Per-capita clamor rises.** If it falls, a big party is *quieter* per
##    person and the pressure system rewards bringing friends.
## 3. **Enemies scale up**, or four people trivialise a floor built for one.
## 4. **The pool is not exhausted below the top of the range.** A floor that
##    runs out of authored loot at two players is one whose numbers stop
##    meaning what they say — the curve would read as flat when it is only
##    clipped.
func _scaling_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	# **Every size, not the three headline ones.** `DES-012` writes the
	# relationship as 1/2/4 because those are the numbers people quote, and the
	# first version of this probe sampled exactly those — which left the sizes
	# in between asserted by nothing. Three players is a real party and it has
	# to land *between* two and four on all three curves, not merely exist.
	#
	# Derived from `Player.MAX_PARTY` rather than written out, so raising the
	# cap extends the check instead of quietly leaving the new sizes untested.
	var sizes: Array[int] = []
	for party: int in range(1, Player.MAX_PARTY + 1):
		sizes.append(party)
	var per_head_loot: Array[float] = []
	var per_head_clamor: Array[float] = []
	var counts: Array[int] = []
	# The divided pool, not the whole table: the fixtures are handed to every
	# party size regardless and are asserted separately below (`M2-T17`).
	var pool: int = FILLER.size()

	print("[party] pool %d authored item(s), %d authored post(s)" % [
		pool, ENEMY_POSTS.size()])
	for party: int in sizes:
		var wanted: int = PartyScaling.loot(_solo_loot(), party)
		var present: int = mini(pool, wanted)
		var enemies: int = PartyScaling.enemies(ENEMY_POSTS.size(), party)
		var noise: float = PartyScaling.clamor(party)
		per_head_loot.append(float(present) / float(party))
		per_head_clamor.append(noise / float(party))
		counts.append(enemies)
		print(("[party] %d player(s): %d loot (%.2f each), %d enemies, "
			+ "clamor x%.2f (%.2f each)%s") % [
			party, present, per_head_loot[-1], enemies, noise,
			per_head_clamor[-1],
			"" if wanted <= pool else "  — POOL EXHAUSTED, wanted %d" % wanted])

	for index: int in range(1, sizes.size()):
		if per_head_loot[index] >= per_head_loot[index - 1]:
			problems.append(("per-capita loot does not fall from %d to %d players "
				+ "(%.2f → %.2f) — DES-012 needs a bigger party to be individually "
				+ "poorer, or four-player becomes the optimal farm")
				% [sizes[index - 1], sizes[index], per_head_loot[index - 1],
				per_head_loot[index]])
		if per_head_clamor[index] <= per_head_clamor[index - 1]:
			problems.append(("per-capita clamor does not rise from %d to %d players "
				+ "(%.2f → %.2f) — four bodies must be far more than twice as loud "
				+ "as two, or bringing friends makes you quieter")
				% [sizes[index - 1], sizes[index], per_head_clamor[index - 1],
				per_head_clamor[index]])
		if counts[index] <= counts[index - 1]:
			problems.append("enemies do not grow from %d to %d players — combat has "
				% [sizes[index - 1], sizes[index]]
				+ "to stay meaningful with more swords in the room")

	# The authored ceiling. Clipping *at* the top of the range is by design;
	# clipping below it makes the curve unmeasurable rather than merely bounded.
	var clipped_at: int = 0
	for party: int in sizes:
		if PartyScaling.loot(_solo_loot(), party) > pool and clipped_at == 0:
			clipped_at = party
	if clipped_at != 0 and clipped_at < sizes[-1]:
		problems.append(("the loot pool runs out at %d players, below the top of "
			+ "the range — the curve reads as flat when it is only clipped, and "
			+ "the per-capita metric stops meaning what it says") % clipped_at)

	# ─ the floor's two decisions are on it, at every size ─
	#
	# **Asserted against the built world, not against the table.** The arithmetic
	# above was right the whole time this was broken: scaling took a *prefix* of
	# one list that held the filler and the fixtures together, so at party size 1
	# it laid four of nine and neither of the two things worth deciding about was
	# among them. A probe that counted rows would have passed, which is why this
	# reads the group the spawner actually filled (`M2-T17`, ADR-110).
	var on_the_floor: Array[StringName] = []
	for node: Node in get_tree().get_nodes_in_group(WorldItem.GROUP):
		var item := node as WorldItem
		if item != null and item.definition() != null:
			on_the_floor.append(item.definition().id)
	for row: Array in FIXTURES:
		var id := StringName(row[0])
		print("[party] fixture %-16s %s at party size %d" % [
			id, "present" if on_the_floor.has(id) else "MISSING",
			PartyScaling.size_of(self)])
		if not on_the_floor.has(id):
			problems.append(("%s is not on the floor at party size %d — it is one "
				+ "of this floor's two decisions and it is scaled away. Without "
				+ "the Prize the Guardian's room is a dead end with a monster in "
				+ "it; without the Waystone the only way out is the Shaft, while "
				+ "the HUD goes on offering `v waystone`") % [
				id, PartyScaling.size_of(self)])

	_assert_the_multiplier_is_on_behaviour(sizes, problems)
	_report(problems, "party")


## **The party multiplier is on what people do, not on what they hold.**
##
## `ClamorSource` has two ways to be loud and only one of them scales. Every
## transient deposit — a footstep, a swing, a rummage, a Waystone channel —
## goes through `add()` and is multiplied. `carried_floor` is assigned straight
## from the bag and is not.
##
## That was where the multiplication happened to land rather than a decision,
## so it is a decision now, and this is the check that holds it:
##
## * **What you do** gets sloppier with company. Four people cannot move
##   through a room with the coordination of one, and that is the fiction the
##   super-linear exponent is charging for.
## * **What you hold** does not. Ten kilos of coin clinks exactly the same
##   whether or not you brought friends, and nothing about the party changes
##   the object in the bag.
##
## And the practical half, which is why the line is in the right place:
## `carried_floor` is a *floor*, a minimum audible radius that never decays
## away. Scaling it would put a four-stack permanently above the threshold and
## delete *"hide and let it pass"* — which `DES-005` lists among the things
## that must work — for every party except a solo one. Per-capita clamor still
## rises, which is the property `DES-012` actually asks for.
func _assert_the_multiplier_is_on_behaviour(sizes: Array[int],
		problems: PackedStringArray) -> void:
	var player: Player = _session.local_player()
	if player == null:
		problems.append("no local body to measure clamor on")
		return
	var coin: ItemResource = ItemCatalogue.by_id(&"glt_hoard_coin")
	if coin == null:
		problems.append("glt_hoard_coin is missing from the catalogue")
		return

	# Stand-ins are *counted*, never simulated: group membership is the entire
	# input party scaling has, so a marker in the group is indistinguishable
	# from a body for this measurement. Spawning three networked players
	# headless to observe one multiplication would be theatre.
	var stand_ins: Array[Node] = []
	var held: Array[float] = []
	var done: Array[float] = []
	for party: int in sizes:
		while stand_ins.size() < party - 1:
			var extra := Node.new()
			extra.add_to_group("player")
			add_child(extra)
			stand_ins.append(extra)

		player.inventory.clear()
		player.inventory.add(coin)
		held.append(player.clamor.carried_floor)

		player.inventory.clear()
		player.clamor.silence()
		player.clamor.add(1.0)
		done.append(player.clamor.level)

		print("[party] %d player(s): one coin held %.2f, one unit done %.2f"
			% [party, held[-1], done[-1]])

	for extra: Node in stand_ins:
		extra.queue_free()
	player.inventory.clear()
	player.clamor.silence()

	for index: int in range(1, sizes.size()):
		if not is_equal_approx(held[index], held[0]):
			problems.append(("the same coin is louder at %d players than at 1 "
				+ "(%.2f vs %.2f) — the party multiplier has reached what the "
				+ "bag holds, and a carried floor that scales puts every party "
				+ "above the hearing threshold permanently")
				% [sizes[index], held[index], held[0]])
		if done[index] <= done[index - 1]:
			problems.append(("the same action is no louder at %d players than "
				+ "at %d (%.2f vs %.2f) — transient noise is the half that has "
				+ "to scale")
				% [sizes[index], sizes[index - 1], done[index], done[index - 1]])


## Four embers in a row, photographed (`M2-T05`).
##
## Its job changed with ADR-094 and it is worth keeping either way. It was
## *"prove the four seats are distinguishable"*; now that they are deliberately
## identical it is **"prove an ember reads as an ember"** — a piece of her fire
## on the floor rather than a dropped item. That is still a claim about seeing,
## and still the half no headless check can make.
##
## It has already earned itself twice on this one object: it caught every ember
## rendering as seat 0 (the binding was applied after `spawn`, too late for
## `_ready`), and it caught emission at 1.4x flattening them into featureless
## discs.
func _ember_shot(path: String) -> void:
	var player: Player = _session.local_player()
	var at := Vector3(0.0, 0.1, 0.0)
	for seat: int in range(Player.MAX_PARTY):
		# Spawned with a peer id that maps to this seat, so what is drawn is what
		# a real fourth player's ember would look like rather than a swatch.
		_session.spawn_world_item(&"con_ember",
			at + Vector3(float(seat) * 1.6 - 2.4, 0.0, 0.0), 0.0, Vector3.ZERO,
			true, Player.MAX_PARTY * 4 + seat)
	player.teleport(at + Vector3(0.0, 0.0, 4.6), 0.0)
	await _hold(0.8)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[ember] four seats drawn — %s" % path.get_file())
	get_tree().quit()


## Print every problem and quit with the right code.
##
## One place, because a probe that ends by hand ends differently each time it
## is copied — and because an early return needs the same ending as the normal
## one or bailing out becomes a silent pass.
## **What happens to a player the run is finished with** (`M2-T16`, ADR-108).
##
## `--ember-probe` measures the whole down → bleed → ember → rescue chain and
## proves every link of it. It also calls `restore_for_descent()` itself the
## moment the ember has dropped, so every assertion this project makes about
## death is made about a player the measurement stood back up. Nobody had ever
## left one lying there, and lying there was the bug: `_end_the_run` was
## reachable from `_on_extracted` and nowhere else, so a solo player who died
## was clamped to 0.00 m/s on a floor that kept running, with self-recovery
## refusing because it asks `is_downed()` and `spent` is not downed.
##
## Both directions, because the rule is not "death ends the run" — ADR-102
## decided the opposite and that decision stands:
##
## 1. **One player down with a teammate standing does not end anything.** Your
##    ember lies there to be carried out; a run that stopped when you went out
##    would delete the M2 co-op gate.
## 2. **Nobody left standing does.** In a party that is the wipe; solo it is
##    every failed run, which is most of them.
## 3. **A revive inside the window calls it off**, so two players going down a
##    second apart is survivable by the second one getting up.
func _wipe_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var mine: Player = _session.local_player()
	# A second body, so the party can be down without being gone. Spawned
	# through the session like any other, which is the only way to get one.
	var friend: Player = _session.spawn_player(TEAMMATE_PEER)
	await _hold(0.5)
	if friend == null:
		_report(PackedStringArray(["could not spawn a second body, so nothing "
			+ "here can tell a party apart from a wipe"]), "wipe")
		return
	mine.teleport(SPAWNS[0] + Vector3(0.0, 0.1, 0.0), 0.0)
	# The teammate is left where the session put it. `teleport` asks the owning
	# peer to move itself, and this one's owner is a number rather than a
	# process — so there is nobody to ask, and nothing here depends on where it
	# stands. What it has to be is *alive*, which is the only thing that tells a
	# party apart from a wipe.
	await _hold(0.3)

	# ─ 1. one down, one standing: the run goes on ─
	var scene_before: String = get_tree().current_scene.scene_file_path
	var floor_before: int = _descent
	mine.health.apply_damage(mine.health.maximum * 2.0)
	await _hold(0.2)
	mine.bleeding = 0.02
	await _hold(Config.tuning.party_wipe_seconds + 1.0)
	print("[wipe] one of two    mine spent=%s, friend spent=%s, floor %d → %d" % [
		mine.spent, friend.spent, floor_before, _descent])
	if not mine.spent:
		problems.append("bleeding out did not spend the body, so the rest of "
			+ "this proves nothing about what a wipe is")
	if _descent != floor_before or get_tree().current_scene.scene_file_path \
			!= scene_before:
		problems.append("the run ended with a teammate still standing — "
			+ "ADR-102 leaves your ember on the floor for them to carry out, "
			+ "and a run that stops when one player goes out deletes the M2 "
			+ "co-op gate")

	# ─ 2. the last one goes out: the run ends ─
	GameState.stash.append(ItemInstance.of(
		ItemCatalogue.by_id(&"glt_hoard_coin"), 1))
	friend.health.apply_damage(friend.health.maximum * 2.0)
	await _hold(0.2)
	friend.bleeding = 0.02
	await _hold(Config.tuning.party_wipe_seconds + 1.5)
	# `_probing` keeps the floor from walking out from under a measurement, so
	# what a run ending looks like from in here is the floor reset and the
	# great reset having happened — not a scene change.
	print("[wipe] nobody left   floor %d → %d, stash %d, carried %d" % [
		floor_before, _descent, GameState.stash.size(),
		GameState.carried.size()])
	if _descent == floor_before:
		problems.append(("the run did not end with every body spent — a solo "
			+ "player is frozen at 0.00 m/s on a floor that keeps running, "
			+ "with no self-recovery (it asks `is_downed()`) and nothing on "
			+ "screen but a developer readout"))
	if GameState.stash.size() > 0:
		problems.append("a wipe did not take the stash — `DES-008`'s great "
			+ "reset is what stops an economy inflating across a lineage")

	# ─ 3. getting up inside the window calls it off ─
	#
	# Planted the other way round from the two above: the wipe is *started* and
	# then interrupted, which is the case a party actually meets when two
	# people go down a second apart.
	for body: Player in _session.players():
		body.restore_for_descent()
	await _hold(0.4)
	var floor_at_third: int = _descent
	mine.health.apply_damage(mine.health.maximum * 2.0)
	friend.health.apply_damage(friend.health.maximum * 2.0)
	await _hold(0.2)
	mine.bleeding = 0.02
	friend.bleeding = 0.02
	await _hold(0.6)
	# Inside the window, a hand on the shoulder.
	mine.restore_for_descent()
	await _hold(Config.tuning.party_wipe_seconds + 1.0)
	print("[wipe] got back up   within %.1f s: floor %d → %d, mine spent=%s" % [
		Config.tuning.party_wipe_seconds, floor_at_third, _descent, mine.spent])
	if _descent != floor_at_third:
		problems.append(("the run ended anyway after somebody got up inside "
			+ "the %.1f s window — the rule has to be that nobody has been "
			+ "standing for a while, not that nobody was standing on one "
			+ "particular frame") % Config.tuning.party_wipe_seconds)

	_report(problems, "wipe")


func _report(problems: PackedStringArray, tag: String) -> void:
	for problem: String in problems:
		printerr("[%s] FAIL %s" % [tag, problem])
	get_tree().quit(1 if problems.size() > 0 else 0)


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
## Where the probe puts the one enemy it needs — the authored first post, spelt
## out rather than read from `ENEMY_POSTS[0]` because indexing an array is not
## a constant expression. Spawned by the phase that swings at it, so no amount
## of party-scaled clamor can have walked it away first.
const PROBE_STRIKE_AT: Vector3 = Vector3(9.0, 0.1, -5.0)

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
## The entrance, which holds no enemy post by construction. The rescue phase
## happens here so it measures the revive rather than the fight around it.
const PROBE_RESCUE_AT: Vector3 = PROBE_WALK_FROM
const PROBE_TIMEOUT_MSEC: int = 15000

## Where the loop goes when it ends badly. Extraction goes to the Chamber to
## sort a haul; death has no haul to sort, so it lands at the fire.
const THRESHOLD_SCENE: String = "res://levels/lair/threshold.tscn"


## **The Ear, on screen at last, and a reticle** (`DES-018`).
##
## The Ear has existed since `M2-T03` and **nothing ever instantiated it.**
## `--ear-probe` compares `HuntMix.CHANNELS` against `Ear.RENDERED` and both
## are constants, so the parity check passed for two milestones while the
## visual channel was never drawn at all — the ADR-097 fault again, in the one
## place `DES-018` cannot tolerate it: *"from M2, the build must be completable
## with sound muted."* It was not, and nothing said so.
##
## The reticle is the other half of the same complaint. `Player._reaching_for`
## has known what you would pick up since `M2-T01`; a player had no way to see
## it, so every "the pickup feels unreliable" report was really about this.
func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	# Vignette first, so it sits *behind* the Ear and the Reticle rather than
	# darkening them. It is the only full-screen element here and the two
	# readouts have to stay legible while you are being hit — which is exactly
	# the moment they matter most.
	layer.add_child(WoundVignette.new())
	layer.add_child(Ear.new())
	layer.add_child(Reticle.new())
	# Not while a probe is measuring the floor: it would be three labels
	# fading over a screenshot, and `--ear-shot` in particular photographs
	# exactly the frames this covers.
	if not _probing:
		layer.add_child(ArrivalBrief.new())

## How much floor has already been laid, so an arriving player tops it up
## rather than doubling it. See `_on_party_changed`.
var _enemies_placed: int = 0
var _loot_placed: int = 0
## The Prize and the Waystone are laid once and never scaled, so they need a
## flag of their own rather than a count (`M2-T17`).
var _fixtures_placed: bool = false

var _probe_floor: Dictionary = {}
var _probe_stillness: float = -1.0
var _probe_enemies_seen: int = 0
var _probe_enemy_hp: Dictionary = {}
var _probe_enemy_at: Dictionary = {}
var _probe_clamor_peak: Dictionary = {}
var _probe_walk_clamor: Dictionary = {}
var _probe_walked: Dictionary = {}
var _probe_heights: Dictionary = {}
var _probe_bags: Dictionary = {}
var _probe_downed: Dictionary = {}
var _probe_speeds: Dictionary = {}
var _probe_revived: Dictionary = {}
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

	# **Empty the floor.** This probe measures the authority split, not the
	# floor's contents, and `M2-T07` made the contents depend on how many people
	# are standing on it: a party of two gets six enemies and **2.55× clamor**,
	# so by the time the strike phase swung, every enemy had heard the walk
	# phase and left its post. Three assertions then failed for reasons with
	# nothing to do with replication — including two that fail *quietly*, by
	# hitting a different body than they meant to.
	#
	# So the probe stops inheriting a floor and builds one. Each phase spawns
	# exactly the enemy it needs, immediately before it needs it, and a body
	# that has existed for half a second cannot have wandered off. That holds at
	# any party size and any clamor multiplier, which is the point: party
	# scaling has `--scaling-probe` and does not need re-measuring through this.
	#
	# **Sampled before it is emptied**, because this is the only place the two
	# halves of `M2-T07` meet. `--scaling-probe` proves the arithmetic; only a
	# second real process proves the game ever calls it with a number above
	# one — and for one commit it did not, because the host builds its floor in
	# the frame it creates the session and every other body arrives after that.
	_probe_floor = {
		"party": PartyScaling.size_of(self),
		"enemies": _enemies_placed,
		# **Both sides count the same things** (`M2-T17`). `_loot_placed` tracks
		# the filler only, since the fixtures are laid once and never scaled —
		# so reporting it raw here compared filler-at-this-party against
		# fixtures-plus-filler-at-one, and a two-player floor read as no bigger
		# than a solo one. Totals on both sides, or the row is not a comparison.
		"loot": FIXTURES.size() + _loot_placed,
		"solo_enemies": PartyScaling.enemies(ENEMY_POSTS.size(), 1),
		"solo_loot": FIXTURES.size() + mini(FILLER.size(),
			PartyScaling.loot(_solo_loot(), 1)),
	}
	if host:
		_session.clear_enemies()
	await _hold(0.6)

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
	if host:
		# Watched from the host, on the body it is not driving. See
		# `_stillness_of` — this is the jitter measurement.
		_probe_stillness = await _stillness_of(1.0)
	else:
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

	# 3. **One enemy, spawned now**, and the client swings once at it. The
	#    client's own hitbox is inert; if the enemy loses exactly one swing of
	#    health on both peers, the host resolved it, resolved it once, and told
	#    the client.
	if host:
		_session.spawn_enemy(PROBE_STRIKE_AT)
	if not host:
		mine.teleport(PROBE_STRIKE_FROM, 0.0)
	await _hold(0.6)

	# Count damage *events on this peer*, which is the only thing that can tell
	# host-authoritative damage from damage that merely agrees.
	#
	# Comparing hit points cannot do it: a client that resolved the swing
	# itself would arrive at the same 35 as the host and the replicated value
	# would overwrite it with itself. `Health.damaged` fires only from
	# `apply_damage`, and replication assigns `current` directly — so a client
	# that has correctly refused to resolve anything counts **zero**, and a
	# client that resolved its own copy counts one. That is the assertion.
	#
	# Connected here rather than at the top, because the body it listens to did
	# not exist until three lines ago.
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).health.damaged.connect(_on_probe_damage)

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
	# The **peak** speed across the chase, not a reading at the end of it.
	#
	# Two rounds of this. Reading it at report time broke when the rescue phase
	# was added six seconds later: the enemy had arrived and stopped, and a
	# stopped enemy reads exactly like a client correctly refusing to simulate.
	# Sampling mid-phase fixed that instant and left the *fragility* — any
	# future phase, any slower enemy, any unlucky frame where it is turning
	# rather than running, and the check fails for a reason that has nothing to
	# do with authority.
	#
	# A peak cannot be unlucky. It is the same shape `_probe_clamor_peak`
	# already uses, and for the same reason: **the claim is "did this ever
	# move", so the measurement has to be "the most it ever moved".**
	_probe_speeds = await _peak_enemy_speeds(1.5)
	# Health and position are sampled *here*, with the chase, for the same
	# reason the speeds are: they are claims about the swing and about where
	# two peers think a running enemy is, and reading them at report time reads
	# a different moment entirely — one the rescue phase below deliberately
	# clears the floor for.
	_probe_enemy_hp = _probe_enemy_health()
	_probe_enemy_at = _probe_enemy_positions()
	_probe_enemies_seen = get_tree().get_nodes_in_group("enemies").size()

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

	# 6. **The rescue** (`M2-T05`). The client is put on the floor and the host
	#    walks over and picks them up — which is the one claim in `DES-012` that
	#    genuinely cannot be tested in one process, because it is two people.
	#
	#    The host holds `interact`; nothing else about the two bodies changes.
	#    If the client comes back up, then the downed state replicated *and* the
	#    host's hand reached across the wire, and the M2 co-op gate has a
	#    mechanism under it.
	#
	#    The floor is cleared first and both bodies move to the empty entrance.
	#    That is not making the test easy: this phase is a claim about a hand
	#    reaching across the wire, and `M2-T07` made the floor genuinely more
	#    dangerous enough that the *host* was being beaten down before it could
	#    offer one — a rescuer that is itself incapacitated cannot revive
	#    anybody, and the check failed for a reason with nothing to do with
	#    replication. Every enemy claim above has already been sampled by here.
	if not host:
		mine.teleport(PROBE_RESCUE_AT + Vector3(1.4, 0.0, 0.0), 0.0)
	if host:
		_session.clear_enemies()
		mine.restore_for_descent()
		mine.teleport(PROBE_RESCUE_AT, 0.0)
	await _hold(0.6)
	if host:
		var fallen: Player = _client_body()
		if fallen != null:
			fallen.health.apply_damage(fallen.health.maximum * 2.0)
	await _hold(0.5)
	_probe_downed = _probe_down_state()
	if host:
		var fallen: Player = _client_body()
		if fallen != null:
			mine.teleport(fallen.global_position + Vector3(1.0, 0.0, 0.0), 0.0)
			await _hold(0.4)
			Input.action_press("interact")
	await _hold(Config.tuning.revive_seconds + 1.2)
	if host:
		Input.action_release("interact")
	_probe_revived = _probe_down_state()

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


## **How often a remote body is standing perfectly still while it walks.**
##
## Positions arrive at `REPLICATION_HZ` and used to be written straight onto
## the transform, so at 60 fps a teammate held one spot for three frames and
## then jumped to the next — moving on one frame in three and frozen on the
## other two. That is what "a little jittery" is, and it is measurable without
## anybody having to look at it: count the frames on which a body that is
## definitely walking did not move at all.
##
## Stepped motion lands near 0.67. Interpolated motion lands near zero, because
## every frame carries a little of the gap.
func _stillness_of(seconds: float) -> float:
	var body: Player = _client_body()
	if body == null:
		return 1.0
	var frames: int = 0
	var still: int = 0
	var was: Vector3 = body.global_position
	var until: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().physics_frame
		if not is_instance_valid(body):
			break
		var now: Vector3 = body.global_position
		frames += 1
		if now.distance_to(was) < 0.0005:
			still += 1
		was = now
	return float(still) / float(maxi(frames, 1))


func _probe_report(host: bool) -> Dictionary:
	return {
		"role": "host" if host else "client",
		"peer": multiplayer.get_unique_id(),
		"connect_seconds": _probe_connect_seconds,
		"players_seen": _session.players().size(),
		"enemies_seen": _probe_enemies_seen,
		"floor": _probe_floor,
		"stillness": _probe_stillness,
		"positions": _probe_positions(),
		"walked": _probe_walked,
		"capsule_heights": _probe_heights,
		"enemy_health": _probe_enemy_hp,
		"enemy_positions": _probe_enemy_at,
		"enemy_speeds": _probe_speeds,
		"clamor_peak": _probe_clamor_peak,
		"walk_clamor_peak": _probe_walk_clamor,
		"damage_events": _probe_damage_events,
		"bags": _probe_bags,
		"downed": _probe_downed,
		"revived": _probe_revived,
		# The numbers the damage assertion is made of, carried in the report
		# rather than repeated in the harness. A ⟨tune⟩ value that CI has its
		# own copy of is a ⟨tune⟩ value nobody can change.
		"swing_damage": Config.tuning.swing_damage,
		"enemy_max_health": Config.tuning.enemy_health,
		"player_max_health": Config.tuning.player_health,
		"revive_health_fraction": Config.tuning.revive_health_fraction,
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


## Who is on the floor, as each peer sees it. The bleed-out window is
## replicated (`M2-T05`), so a client watching a teammate go down sees the same
## clock the host does — which is what makes deciding to go back for them a
## decision rather than a guess.
func _probe_down_state() -> Dictionary:
	var out: Dictionary = {}
	for player: Player in _session.players():
		out[player.name] = {
			"downed": player.is_downed(),
			"bleeding": player.bleeding,
			"health": player.health.current,
			# Carried so a failed rescue says *why*: no progress at all means
			# nobody's hand was on them, partial progress means it was and
			# something interrupted it.
			"revival": player.revival,
			"spent": player.spent,
		}
	return out


## The body this process is *not* playing. With a party of two that is the
## other one, which is all the co-op probe ever needs.
func _client_body() -> Player:
	for player: Player in _session.players():
		if player != _session.local_player():
			return player
	return null


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


## The fastest each enemy was seen moving over `seconds`, sampled every physics
## frame. Zero on a client is not a rounding artefact and not bad luck: a peer
## that never integrated a velocity reports exact zeroes however long it is
## watched, which is what makes the peak a fair test of *both* halves.
func _peak_enemy_speeds(seconds: float) -> Dictionary:
	var peak: Dictionary = {}
	var until: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		var now: Dictionary = _probe_enemy_speeds()
		for name: String in now:
			peak[name] = maxf(float(peak.get(name, 0.0)), float(now[name]))
		await get_tree().physics_frame
	return peak


## Horizontal speed per enemy, right now. Zero on a client is not a rounding
## artefact: `velocity` is never replicated and never assigned there, so a
## client that has correctly refused to simulate reports exact zeroes.
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


func _slab(size: Vector3, centre: Vector3, colour: Color, yaw: float = 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = centre
	node.rotation.y = yaw
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


## One thing per room that is not a box, so the rooms can be told apart and
## talked about. Blockout shapes only (ADR-046) — a named production phase with
## a scheduled replacement at `M4-T05`, not a placeholder standing in for a
## system that does not exist.
##
## They are built with `_slab`, so they are **solid**, and that is deliberate
## rather than incidental: a barricade you can walk through is worse than no
## barricade, because it teaches the player that this level's furniture is
## scenery — and then the one piece of cover that does matter reads as scenery
## too. Solid also means they occlude, which is what makes them landmarks at
## all rather than decals.
func _build_landmark(room: String) -> void:
	if not LANDMARKS.has(room):
		return
	var row: Array = LANDMARKS[room]
	var kind: String = row[0]
	var at: Vector3 = row[1] as Vector3
	var marker := Node3D.new()
	marker.name = "landmark_%s" % room
	marker.position = at
	marker.add_to_group(LANDMARK_GROUP)
	_world.add_child(marker)
	match kind:
		"arch":
			# Behind the spawn, framing the way you came in. It exists so the
			# entrance is recognisable from inside the loop — this level is a
			# cycle, and the whole hazard of a cycle is arriving somewhere you
			# have already been without noticing (`DES-015` Layer 1).
			_pillar(at + Vector3(-2.2, 0.0, 0.0), 3.2, 0.5)
			_pillar(at + Vector3(2.2, 0.0, 0.0), 3.2, 0.5)
			_beam(at + Vector3(0.0, 3.2, 0.0), 4.9, 0.5)
		"barricade":
			# `DES-015`'s Retreat, at blockout scale: *"barricades facing the
			# wrong way"*. The safe corridor is the one where somebody already
			# tried to hold a line and failed, which is the cheapest possible
			# way to say something about this place without writing any lore.
			_beam(at + Vector3(0.0, 0.5, 0.0), 3.4, 0.42)
			_beam(at + Vector3(0.3, 1.1, 0.6), 3.0, 0.34)
		"pillar":
			_pillar(at, 3.6, 0.62)
		"well":
			# The junction is the room every route crosses, so it is the room
			# most worth being able to name.
			_ring(at, 1.5, 0.7)
		"altar":
			_slab(Vector3(2.4, 0.9, 2.4), at + Vector3(0.0, 0.45, 0.0), WALL_COLOUR)
		"gate":
			# The way out, framed. Taller and thinner than the entrance arch and
			# with no beam across the top, so the two read as a pair without
			# reading as the same thing — and so nothing crosses the Shaft's
			# light column, which is the one sightline in the level that has to
			# survive from the far side of the floor.
			_pillar(at + Vector3(-2.4, 0.0, 0.0), 3.8, 0.45)
			_pillar(at + Vector3(2.4, 0.0, 0.0), 3.8, 0.45)


func _pillar(at: Vector3, height: float, thick: float) -> void:
	_slab(Vector3(thick, height, thick), at + Vector3(0.0, height * 0.5, 0.0),
		WALL_COLOUR)


func _beam(at: Vector3, length: float, thick: float) -> void:
	_slab(Vector3(length, thick, thick), at + Vector3(0.0, thick * 0.5, 0.0),
		WALL_COLOUR)


## A low circular kerb, approximated with eight segments — round enough to read
## as a well from across the room, cheap enough to be blockout.
##
## Each segment is turned to lie **along** the circle. The first version left
## them axis-aligned, which puts a long box at the +X point of a circle whose
## tangent there runs along Z — so the eight segments pointed outward and the
## well was an eight-spoked asterisk. Only visible by looking at it: nothing
## about the arithmetic is wrong, the shapes were simply facing the wrong way.
func _ring(at: Vector3, radius: float, height: float) -> void:
	var segments: int = 8
	for index: int in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		var offset := Vector3(cos(angle) * radius, height * 0.5, sin(angle) * radius)
		# A little longer than the chord, so neighbours overlap at the corners
		# instead of leaving eight gaps you can see the floor through.
		var chord: float = TAU * radius / float(segments) * 1.25
		_slab(Vector3(chord, height, 0.34), at + offset, WALL_COLOUR, -angle)


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
## Enemies, scaled near-linearly with the party (`M2-T07`, `DES-012`).
##
## The authored posts are the shape of the floor — ADR-032's clean west branch
## depends on *which rooms* hold enemies, not how many are in them — so extra
## bodies stack around the existing posts rather than appearing anywhere new.
## The bypass route stays empty at four players, which it has to: that
## guarantee is about the layout, and party size must not quietly delete it.
##
## The Guardian is spawned once regardless. It is a Machine (`DES-015`), not
## density; four of it in one room would be a different encounter rather than a
## scaled one.
func _spawn_enemies() -> void:
	var party: int = PartyScaling.size_of(self)
	var wanted: int = PartyScaling.enemies(ENEMY_POSTS.size(), party)
	# Spread on a **ring**, not jittered.
	#
	# Random offsets put two bodies in the same place, and two capsules in the
	# same place shove each other apart — host-side, so a client's copies lag
	# the push and the two peers stop agreeing about where anything is. The
	# co-op smoke caught it the moment density scaling landed: 0.83 m of
	# disagreement on an enemy nobody had touched.
	#
	# A ring at `SPREAD` guarantees separation by construction, and being
	# deterministic it also means the same party always meets the same floor —
	# which `--scaling-probe` needs, since it compares one against another.
	#
	# The angle is a function of `index` alone and never of `wanted`, so body
	# *n* stands in the same place whether the floor was built for two people
	# or grew to four. A formula that divided by `wanted` would move every
	# enemy already standing there each time somebody joined.
	for index: int in range(_enemies_placed, wanted):
		var post: Vector3 = ENEMY_POSTS[index % ENEMY_POSTS.size()]
		var ring: int = index / ENEMY_POSTS.size()
		if ring > 0:
			var angle: float = TAU * float(index) / float(ENEMY_POSTS.size())
			post += Vector3(cos(angle), 0.0, sin(angle)) * SPREAD * float(ring)
		_session.spawn_enemy(post)
	if _enemies_placed == 0:
		# The Guardian faces its prize's doorway and never leaves the room.
		_session.spawn_enemy(GUARDIAN_POST)
	_enemies_placed = maxi(_enemies_placed, wanted)


## The authored loot, as much of it as this party gets (`M2-T07`, `DES-012`).
##
## **Sub-linear**: the list is the floor's pool and party size decides how much
## of it is lying there. So a solo run finds most of it and a four-stack finds
## all of it *between them* — which is far less each, and is the mechanism that
## stops four-player becoming the optimal farm.
##
## The pool is a hand-placed list until `M4-T01`, so the scaling is bounded by
## what a designer authored rather than by the curve. That bound is real and it
## is reported by `--scaling-probe` rather than hidden: a floor that runs out of
## loot before it runs out of curve is a floor whose numbers stop meaning what
## they say.
func _spawn_loot() -> void:
	# **The fixtures first, once, whatever the party size** (`M2-T17`, ADR-110).
	# Guarded by its own flag rather than by `_loot_placed`, because the floor is
	# topped up as players arrive and these must not be laid twice.
	if not _fixtures_placed:
		_fixtures_placed = true
		for row: Array in FIXTURES:
			_session.spawn_world_item(row[0] as StringName, row[1] as Vector3)
	var party: int = PartyScaling.size_of(self)
	var wanted: int = mini(FILLER.size(), PartyScaling.loot(_solo_loot(), party))
	for index: int in range(_loot_placed, wanted):
		var row: Array = FILLER[index]
		_session.spawn_world_item(row[0] as StringName, row[1] as Vector3)
	_loot_placed = maxi(_loot_placed, wanted)


## **The floor scales to the party as the party arrives, and never shrinks.**
##
## `M2-T07` shipped scaling that could not fire. `CoopSession._start_host()`
## spawns the host's own body and nothing else — every other body arrives later,
## on `peer_connected` — but `_spawn_actors()` built the floor in the same frame
## it created the session. So `size_of()` counted **one**, always, and enemy and
## loot scaling were dead code in every real session. The `--scaling-probe`
## measured the arithmetic and the arithmetic was right; nothing measured
## whether the game ever called it with a number above one.
##
## There is no "the party is complete" moment to wait for, and inventing one out
## of a timer would be the fragile kind of fix this project keeps refusing. So
## the floor is **topped up** instead: each arrival brings the enemy and loot
## counts to what the current party warrants, adding only the difference. Both
## curves are monotonic, so a floor grown one player at a time is identical to
## one generated for the final party.
##
## **It never shrinks when somebody leaves.** Despawning an enemy a player is
## fighting, or loot they were walking towards, is a bug they can *see*; a floor
## still populated for four after one quits is only a harder run. Between a
## visible wrong and an invisible imbalance, take the imbalance.
func _on_party_changed(_player: Player) -> void:
	if not _session.is_host():
		return
	_spawn_enemies()
	_spawn_loot()


## What a lone player finds **of the filler**. Chosen so the curve reaches the
## authored ceiling at four — the point where the pool runs out is exactly the
## top of the party range rather than somewhere in the middle of it.
##
## `FILLER` rather than `LOOT` since `M2-T17`: the fixtures are not divided
## among anybody, so counting them here would shrink every party's share to pay
## for two items everyone gets regardless.
func _solo_loot() -> int:
	return int(round(float(FILLER.size())
		/ pow(float(Player.MAX_PARTY), Config.tuning.party_loot_exponent)))


## Somewhere for the enemies to path (`M2-T14`, ADR-106).
##
## There was no navigation in this project at all. Every enemy walked in a
## straight line at whatever it was interested in, which is the right technique
## for an open arena and the wrong one for a floor whose own header boasts that
## it has *"corners, doorways and a room you"* must commit to enter. The result
## reads exactly as a playtester described it: the AI does not path.
##
## Baked from the level's own collision, so it can never disagree with the
## geometry — the walls, the landmarks and the doorway gaps are all already
## `StaticBody3D`s built by `_slab`, and parsing those means the mesh is a
## function of the level rather than a second description of it that has to be
## kept in step (the ADR-073 rule).
##
## Built on every peer even though only the host steers anything, exactly as
## `_build_hunt` is: the alternative is a networking branch inside the level,
## and `TEC-004`'s boundary is supposed to be invisible from here.
func _build_navigation() -> void:
	var mesh := NavigationMesh.new()
	mesh.agent_radius = NAV_AGENT_RADIUS
	mesh.agent_height = NAV_AGENT_HEIGHT
	# Nothing here is climbable. The well kerb and the barricade are meant to
	# be walked *around*; a generous step height would quietly turn both into
	# ramps and undo the reason they are solid.
	mesh.agent_max_climb = 0.3
	mesh.agent_max_slope = 45.0
	# **0.15, and this number closed every doorway in the level at 0.2.**
	#
	# Recast erodes the walkable surface by `ceil(agent_radius / cell_size)`
	# *cells*, not by the radius. At a 0.2 cell that rounds 0.45 m up to three
	# cells — 0.6 m a side, 1.2 m off the width of every opening — and the
	# doorways here have only about 1.4 m of true clearance, because each one is
	# flanked by the two rooms' own side walls. So the mesh baked, every room
	# had surface on it, and not one doorway connected: six navigable islands
	# and no route between them.
	#
	# It looked exactly like an agent problem and was not. Dropping the radius
	# to 0.2 "fixed" it and would have shipped agents thinner than the bodies
	# they steer; at a 0.15 cell the erosion matches the radius it is supposed
	# to represent and the full 0.45 m — wider than the 0.35 m body — connects
	# the whole floor.
	mesh.cell_size = 0.15
	mesh.cell_height = 0.15
	mesh.geometry_parsed_geometry_type = \
		NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	# By group rather than by children: the geometry hangs off `_world` as a
	# flat list of slabs, and re-parenting all of it under the region purely to
	# be baked would change every node path in the level for no gain.
	mesh.geometry_source_geometry_mode = \
		NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh.geometry_source_group_name = NAV_SOURCE_GROUP
	_world.add_to_group(NAV_SOURCE_GROUP)

	_navigation = NavigationRegion3D.new()
	_navigation.name = "Navigation"
	_navigation.navigation_mesh = mesh
	add_child(_navigation)
	var region: NavigationRegion3D = _navigation
	# Synchronous, so the map exists before the first enemy asks. Baking this
	# floor is a few milliseconds; a threaded bake would mean the first seconds
	# of every run had no navigation, which is precisely the window in which
	# the player is deciding whether the game works.
	region.bake_navigation_mesh(false)


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
	# Before it enters the tree, so the synchronizer exists at the same node
	# path on every peer. Both sides build this identically — it is authored
	# geometry rather than a spawn — so the paths match by construction.
	_shaft.configure_replication()
	_world.add_child(_shaft)
	_shaft.claimed.connect(_on_extracted)
	for player: Player in _session.players():
		_watch(player)
	_session.player_spawned.connect(_watch)


## The Shaft is channelled here rather than driving itself, so the level owns
## the one clock that can end a run. `Shaft.advance` is host-guarded, so this
## costs a client nothing.
func _physics_process(delta: float) -> void:
	if _shaft != null:
		_shaft.advance(delta)


func _watch(player: Player) -> void:
	player.extracted.connect(_on_extracted)
	player.died_here.connect(_on_died_here)


## Someone bled out (`M2-T05`, `DES-012`). **The ember drops where they fell.**
##
## Spawned as an ordinary `WorldItem` carrying `con_ember`, bound to the peer
## whose life it is — which means it is picked up, carried, weighed and heard
## exactly like loot, and costs the rescuer squares, kilograms and quiet for
## the whole walk home. `DES-012` asks for precisely that: *"the ember's weight
## and noise mean rescue is a genuine sacrifice — the rescuer's own extraction
## gets materially worse. That's a real decision, not a free revive."*
##
## Marked `disturbed`, so the Gullsjúkr will stop for it. That is not a
## special case; it is the rule from ADR-089 applied honestly, and it is a
## horrible little decision to be handed: the thing that would buy you seconds
## is your friend.
func _on_died_here(player: Player, at: Vector3) -> void:
	if not multiplayer.is_server():
		return
	# The binding rides the spawn, because an ember decides how it looks in
	# `_ready` — whose seat, which colour, how many motes.
	_session.spawn_world_item(&"con_ember", at + Vector3(0.0, 0.1, 0.0), 0.0,
		Vector3.ZERO, true, player.get_multiplayer_authority())
	print("[death] %s went out — their ember is on the floor at %.0f, %.0f" % [
		player.name, at.x, at.z])
	# **Dying does not end the run**, and it especially does not end anybody
	# else's. `DES-012` has your ember lying there for a teammate to carry
	# out — a run that stopped the moment you went out would delete the M2
	# co-op gate. You are spent on the floor until somebody leaves the floor.
	#
	# This used to call the run-ended path, but only when the body belonged to
	# the host: a client who died was simply never told, and lay there until
	# they alt-tabbed.
	#
	# **But somebody has to still be standing for that to mean anything**
	# (`M2-T16`, ADR-108). ADR-102's rule is right and it was the whole rule:
	# `_end_the_run` was reachable from `_on_extracted` and from nowhere else,
	# so a player with no teammates simply never ended. Solo, that is every
	# failed run — `spent` clamps the body to 0.00 m/s, self-recovery refuses
	# because it asks `is_downed()` and `spent` is not downed, and the floor
	# keeps running around a person who cannot move.
	_watch_for_a_wipe()


## **Nobody left standing ends the run** (`M2-T16`, ADR-108).
##
## Deliberately *not* "somebody died", which is ADR-102's decision and stays
## intact: your ember lies there for a teammate to carry out, and a run that
## stopped when you went out would delete the M2 co-op gate. What ends a run is
## the party being gone, which in a solo run is the same event and in a party is
## the wipe every extraction game ends on.
##
## **A window, not an instant**, and it is re-checked at the end of it. Two
## reasons, and the second is the load-bearing one:
##
## 1. A cut to the camp on the frame you go out gives the player nothing to
##    read. `DES-002`'s losses are meant to be ones you can explain in a
##    sentence, and the M2 exit gate asks a tester to do exactly that.
## 2. **A revive inside the window has to cancel it.** Two players going down a
##    second apart is an ordinary way for a fight to go, and the second one
##    getting up must not find the run already over. Re-checking is what makes
##    the rule "nobody has been standing for a while" rather than "nobody was
##    standing on one particular frame".
##
## `_ending` guards re-entry: four bodies going out together would otherwise
## start four timers and end the run four times.
func _watch_for_a_wipe() -> void:
	if _ending or not _the_party_is_gone():
		return
	_ending = true
	print("[death] nobody is left standing — %.1f s and the run is over"
		% Config.tuning.party_wipe_seconds)
	await get_tree().create_timer(Config.tuning.party_wipe_seconds).timeout
	_ending = false
	# Somebody got up. `_stand_up` clears `spent` on a self-recovery and a
	# teammate's hand does the same, so this is the ordinary way out of here.
	if not _the_party_is_gone():
		print("[death] somebody got back up — the run continues")
		return
	_end_the_run()


## Is there a body left that could still do something?
##
## `spent` rather than `is_incapacitated()`: a **downed** player is bleeding but
## recoverable — they can crawl, they can self-recover once, and a teammate can
## reach them — so a party with one downed member is not a party that is gone.
## Only `spent` is final.
##
## An empty party is not a wipe. A level between spawns has nobody in it, and
## reading that as a wipe would end a run that had not started.
func _the_party_is_gone() -> bool:
	var bodies: Array[Player] = _session.players()
	if bodies.is_empty():
		return false
	for body: Player in bodies:
		if not body.spent:
			return false
	return true


## **The run is over, and everybody goes home together** (ADR-102).
##
## Host-side, and it acts on *every* peer rather than on whoever happened to
## touch the exit. The old handler was guarded with `is_server()` and then
## worked on whichever body extracted — so a client reaching the Shaft ran
## `GameState.bring_home()` on the **host's** machine with the **client's**
## loot, and sent the host to the hoard room while the client stood in the
## Deep. The mirror image lost a dying client entirely.
##
## Everybody moving at once is the same rule as the Descent (ADR-101): peers
## cannot stand in different levels, because the host owns the world and a
## client in a scene the host is not in has nothing to receive.
##
## **Individual extract-and-wait is `M3-T09`**, and it needs the Vörðr —
## somewhere to *be* while the others finish. Absent rather than approximated:
## a player parked in an empty room with no way to watch or help would be worse
## than a short run that ends cleanly.
## **Everybody else first, and the host last** (`M2-T20`, ADR-113).
##
## Taking the host's own outcome runs `change_scene_to_file`, and Godot removes
## the outgoing scene from the tree **synchronously** — only the new scene's
## instantiation is deferred. Measured either side of the call:
## `in_tree=true` → `in_tree=false`. So every line of this function after that
## point ran on a detached node, where `multiplayer` is `null` and `rpc_id`
## refuses with `ERR_UNCONFIGURED`.
##
## The host is index 0 of `players()`, so it was always handled first, and
## **no client had ever received its outcome.** Before `M2-T16` that was a
## silent `ERR_UNCONFIGURED`, leaving the client standing in a Deep the host had
## left — *"Node not found: Threshold/CoopSession/Spawner"* — until the
## connection dropped. The peer guard added in `M2-T16` turned the same
## detachment into a hard `SCRIPT ERROR` on `get_peers()`, which is how it was
## finally reported: a three-player extraction that crashed the host and
## dropped everybody. Same fault, louder.
func _end_the_run() -> void:
	if not multiplayer.is_server():
		return
	var my_haul: Array = []
	var my_loss: bool = false
	var mine_found: bool = false
	for body: Player in _session.players():
		var peer: int = body.get_multiplayer_authority()
		# Spent means you went out down there. Everything you were carrying
		# stayed with your body, so there is nothing to hand back.
		var packed: Array = [] if body.spent else body.inventory.pack()
		if peer == CoopSession.HOST_PEER:
			# Held, not taken. Taking it here is what detached the node.
			my_haul = packed
			my_loss = body.spent
			mine_found = true
			continue
		# **A body outlives its peer by a frame** (`M2-T16`). `_on_peer_disconnected`
		# frees the body of somebody who drops, but a run ending inside that
		# window addresses a peer the wire no longer has — *"Attempt to call RPC
		# with unknown peer ID"*, and an outcome delivered to nobody. There is
		# nothing to tell a peer that has gone, so this is the whole handling.
		if not multiplayer.get_peers().has(peer):
			print("[exit] %s belongs to peer %d, which is no longer connected "
				% [body.name, peer] + "— nothing to hand back")
			continue
		_take_the_outcome.rpc_id(peer, packed, body.spent)
	# Last, because this is the one that takes the floor out from under us.
	if mine_found:
		_take_the_outcome(my_haul, my_loss)


## What this peer walked away with, delivered to the peer it belongs to.
##
## `GameState` is never networked (`TEC-004`), so the host cannot write another
## player's progression — it can only tell them what happened and let them
## write their own.
@rpc("any_peer", "reliable")
func _take_the_outcome(packed: Array, lost: bool) -> void:
	# Sender 0 is the host calling this on itself, which is not an RPC at all.
	var from: int = multiplayer.get_remote_sender_id()
	if from != 0 and from != CoopSession.HOST_PEER:
		return
	if lost:
		# `DES-008`'s great reset. The hoard is untouched; it always is.
		GameState.die()
		print("[death] the great reset — carried and stash gone, hoard intact "
			+ "at %d" % GameState.hoard_value)
	else:
		var brought: Array[ItemInstance] = []
		for row: Variant in packed:
			brought.append(ItemInstance.from_wire(row as Dictionary))
		GameState.bring_home(brought)
	# The probes measure this floor rather than the loop leaving it, so they
	# put it back instead of walking out of the scene they are measuring.
	if _probing:
		_reset_floor()
		return
	get_tree().change_scene_to_file(THRESHOLD_SCENE)


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

	# **Bear my ember out** (`DES-012`). Anyone whose ember reached the exit in
	# somebody's bag keeps their LIFE — tree, stash and rank intact. There is
	# no tree, stash or rank until `M3`, so this is *reported* rather than
	# enforced; what is real today is that the ember made it, which is the
	# thing the M2 co-op gate is about.
	for peer: int in player.inventory.embers():
		var saved: Player = _session.player_for(peer)
		var who: String = saved.name if saved != null else "peer %d" % peer
		print("[death] %s carried %s's ember out — their LIFE survives" % [
			player.name, who])
		rescued.emit(peer, player)

	extracted.emit(player, player.inventory.total_tribute())

	# Home — everybody, each with their own bag, on their own machine.
	_end_the_run()


## Put the floor back, for the probes that need a second descent without a
## scene change in the middle of their measurement.
func _reset_floor() -> void:
	_descent += 1
	for node: Node in get_tree().get_nodes_in_group(WorldItem.GROUP):
		node.queue_free()
	_session.clear_enemies()
	await get_tree().process_frame
	_spawn_enemies()
	_spawn_loot()
	var index: int = 0
	for player: Player in _session.players():
		player.inventory.clear()
		player.clamor.silence()
		# A new descent is a new body. `DES-012`'s *Return* — walking back in
		# with nothing, at the floor entrance, ember extinguished — is the real
		# version of this and needs the LIFE that `M3` builds; it is absent
		# rather than approximated, and what happens here is simply the next run
		# starting.
		player.restore_for_descent()
		player.teleport(SPAWNS[index % SPAWNS.size()], 0.0)
		index += 1
	if _hunter != null:
		_hunter.global_position = HUNTER_POST
		# A fresh floor is a fresh Hunt. Cross-floor persistence (ADR-037) is
		# about descending *within* a run and needs the floors `M4-T01` builds;
		# this is a new descent, which is the one case where resetting is right.
		_hunter.age = 0.0


## Darkness is the paper, and every light placed on it means something.
##
## **The sun is gone.** It was a `DirectionalLight3D` at -42° in a level that is
## underground, lighting all six rooms identically — so no room looked like
## anywhere in particular and nothing drew the eye toward anything. It was not
## a bad light; it was a light that could not carry information, which is the
## only job lighting has here (`ART-001`: *"lighting design is gameplay design,
## so it can't be handed off as polish"*).
func _build_lighting() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = PAPER
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = AMBIENT
	environment.ambient_light_energy = AMBIENT_ENERGY
	env.environment = environment
	_world.add_child(env)

	for door: Array in DOORS:
		_door_light(door[0] as String, door[1] as String, float(door[2]))


## A pale light in every doorway, on the near side of the wall it is cut from.
##
## Every doorway is listed twice in `DOORS` — once per room it joins — so this
## lights both approaches without knowing anything about which side you are on.
## That duplication was already there to cut the hole from both rooms; it turns
## out to be exactly what "visible from either side" needs.
func _door_light(room: String, side: String, offset: float) -> void:
	var rect: Array = ROOMS[room]
	var light := OmniLight3D.new()
	light.light_color = PALE
	light.light_energy = DOOR_LIGHT_ENERGY
	light.omni_range = DOOR_LIGHT_RANGE
	# Inside the room by a little more than the wall is thick, so the lamp is
	# in the room it belongs to rather than buried in the masonry.
	var inset: float = WALL_THICK * 1.5
	match side:
		"n": light.position = Vector3(offset, DOOR_LIGHT_HEIGHT, float(rect[2]) + inset)
		"s": light.position = Vector3(offset, DOOR_LIGHT_HEIGHT, float(rect[3]) - inset)
		"w": light.position = Vector3(float(rect[0]) + inset, DOOR_LIGHT_HEIGHT, offset)
		"e": light.position = Vector3(float(rect[1]) - inset, DOOR_LIGHT_HEIGHT, offset)
	light.add_to_group(DOOR_LIGHT_GROUP)
	_world.add_child(light)


func _spawn_actors() -> void:
	_session = SESSION_SCENE.instantiate() as CoopSession
	_session.spawn_points = SPAWNS
	add_child(_session)

	# Host-only, and silently so: on a client these calls do nothing and the
	# host's spawns arrive on their own. The level does not need to know which
	# process it is, which is the property that keeps every future level from
	# growing a networking branch.
	_spawn_enemies()
	_spawn_loot()
	# …and again for everyone who arrives after this frame, which is everyone
	# except the host. See `_on_party_changed`: without this, party scaling is
	# arithmetic the game never reaches.
	_session.player_spawned.connect(_on_party_changed)


## **What you put aside is what you take down** (`M2-T06`, `DES-014`).
##
## `threshold.gd` has always documented the Descent this way — *"whatever is in
## the stash is what you take, because `DES-014` puts loadout choices in the
## Chamber and this is the doorway rather than a menu"* — and it was not true.
## Nothing loaded it. `GameState.withdraw()` existed and nothing called it, and
## the dead-name audit is what surfaced it (ADR-098): **the stash was
## write-only.** You could keep things and watch them survive a run and die
## with you, and never once take one back down. `M2-T06` is called *"stash and
## re-descend"* and only the first half was built.
##
## It is host-side and local, and those are the same thing here. `GameState` is
## never networked (`TEC-004`, ADR-021) — every peer holds only its own — so
## each process loads its own stash into its own body. Solo runs as host id 1,
## so there is no second path for one player.
##
## **What does not fit stays in the stash.** `Inventory.add()` returns null when
## the grid has no room, and the honest answer to "your stash is bigger than
## your bag" is that you carry what fits and the rest waits — not that the bag
## silently grows, and not that the overflow is destroyed.
func _carry_the_stash_down() -> void:
	if GameState.stash.is_empty():
		return
	var body: Player = _session.local_player()
	if body == null:
		return
	var taken: int = 0
	for item: ItemInstance in GameState.stash.duplicate():
		if body.inventory.add(item.definition) == null:
			continue
		GameState.withdraw(item)
		taken += 1
	print("[descent] carried %d of %d stashed item(s) down, %.1f kg" % [
		taken, taken + GameState.stash.size(), body.inventory.total_weight()])


# ── the guarantee, asserted rather than eyeballed ─────────────────────────


## **Can a player find their way?** (`M2-T13`, ADR-105)
##
## `--route-probe` has always asserted that a clean *path* exists, and it always
## passed. It could not see that nobody could *find* the path: the level had one
## directional sun, flat ambient, six identically-lit box rooms and a pale disc
## on the floor of one of them. "The Shaft's location is known" (`DES-005`) was
## true of the layout and false of the experience, and no check in this project
## was asking about the experience.
##
## So this asserts the lighting language holds, in the built world rather than
## in the constants it was built from — every claim below reads the scene tree,
## because a probe that counted `DOORS` would pass with every light missing.
##
## It asserts **rules, never ⟨tune⟩ values** (the ADR-096 discipline): that the
## exit is visible from the room every route crosses, that gold is spent only on
## treasure, that every room has something to name it by. How bright any of it
## is remains a question for play.
func _sight_probe() -> void:
	var problems := PackedStringArray()

	# ─ 1. every doorway is lit, from both sides ─
	var lights: int = get_tree().get_nodes_in_group(DOOR_LIGHT_GROUP).size()
	print("[sight] doorway lights          %d of %d" % [lights, DOORS.size()])
	if lights < DOORS.size():
		problems.append("%d of %d doorways are unlit — a room that does not "
			% [DOORS.size() - lights, DOORS.size()]
			+ "show its own exits is the whole navigation problem")

	# ─ 2. every room has a landmark ─
	var landmarks: int = get_tree().get_nodes_in_group(LANDMARK_GROUP).size()
	print("[sight] rooms with a landmark   %d of %d" % [landmarks, ROOMS.size()])
	if landmarks < ROOMS.size():
		problems.append("%d room(s) have no landmark — `DES-015` wants a place "
			% (ROOMS.size() - landmarks)
			+ "readable within 30 seconds, and a bare box is not one")

	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

	# ─ 3. every authored position is somewhere a body can actually stand ─
	#
	# Landmarks are solid, so one on top of an authored position does not *look*
	# wrong — it makes something unreachable, or a body unable to move, and the
	# symptom surfaces somewhere else entirely. This exact collision cost a
	# debugging round: the altar landed on the Waystone, and `--bag-probe` duly
	# reported that dropping the heaviest item in the bag had not made the
	# player any faster. True, and nothing to do with weight — the player was
	# standing inside a block of stone at 0.00 m/s either way.
	#
	# Asked of the **built world**, not of a declared radius. The first version
	# gave each landmark a clearance number and compared distances, and it was
	# wrong twice over: it cannot describe a shape with a hole in it (the arch
	# is two pillars and open air between them, which is exactly where a player
	# walks), and a number written next to a shape is one more thing that can
	# disagree with the shape. A sphere the size of a body, dropped at every
	# authored position, asks the only question that matters — *can anything
	# stand here?* — and it asks the geometry rather than the intent.
	var occupied: Dictionary = {"the Shaft": SHAFT_AT, "the Hunter": HUNTER_POST,
		"the Guardian": GUARDIAN_POST, "the Prize": PRIZE_AT}
	for index: int in range(ENEMY_POSTS.size()):
		occupied["enemy post %d" % index] = ENEMY_POSTS[index]
	for index: int in range(SPAWNS.size()):
		occupied["spawn %d" % index] = SPAWNS[index]
	for row: Array in LOOT:
		occupied["%s" % row[0]] = row[1] as Vector3

	var body := SphereShape3D.new()
	body.radius = BODY_RADIUS
	var blocked_count: int = 0
	for what: String in occupied:
		var point: Vector3 = occupied[what] as Vector3
		var shape_query := PhysicsShapeQueryParameters3D.new()
		shape_query.shape = body
		shape_query.collision_mask = CollisionLayers.WORLD
		shape_query.transform = Transform3D(Basis.IDENTITY,
			Vector3(point.x, BODY_RADIUS + 0.05, point.z))
		if space.intersect_shape(shape_query, 1).size() > 0:
			blocked_count += 1
			problems.append(("%s is inside solid geometry at %.1f, %.1f — "
				+ "landmarks are solid, and one standing on an authored "
				+ "position makes something unreachable somewhere else")
				% [what, point.x, point.z])
	print("[sight] authored spots blocked  %d of %d" % [
		blocked_count, occupied.size()])

	# ─ 4. the way out is visible from **every** room ─
	#
	# This check used to ask about the junction alone, on the reasoning that
	# every route crosses it. It passed, and it was worth almost nothing: the
	# beacon was visible from **two rooms of six, and the room you spawn in was
	# not one of them.** A playtester walked the floor and never found the exit
	# while this reported success, because the probe was measuring the thing
	# that had been built rather than the thing a player needs.
	#
	# `DES-005` says the Shaft's location is *known*. Known means known from
	# where you are standing, not known to the layout — so the bar is every
	# room, and the beacon is sized to clear the walls rather than to satisfy
	# one sightline.
	var blind := PackedStringArray()
	for room: String in ROOMS:
		var eye: Vector3 = _room_centre(room) + Vector3(0.0, EYE_HEIGHT, 0.0)
		var aim: Vector3 = SHAFT_AT + Vector3(0.0, Shaft.BEACON_HEIGHT * 0.92, 0.0)
		var query := PhysicsRayQueryParameters3D.create(eye, aim)
		query.collision_mask = CollisionLayers.WORLD
		if not space.intersect_ray(query).is_empty():
			blind.append(room)
	print("[sight] rooms seeing the way out %d of %d%s" % [
		ROOMS.size() - blind.size(), ROOMS.size(),
		"   blind: " + ", ".join(blind) if blind.size() > 0 else ""])
	if blind.size() > 0:
		problems.append("the way out cannot be seen from %s — `DES-005` makes "
			% ", ".join(blind)
			+ "the Shaft's location *known*, and a beacon behind a wall is a "
			+ "beacon a player walks past")

	# ─ 5. gold is spent on treasure and nothing else ─
	#
	# `ART-005` gives the game exactly one saturated hue and spends it on what
	# will get you killed. The moment a wall sconce or a doorway is warm, the
	# rule stops carrying information — and it would stop silently, because
	# nothing about a nice-looking light announces that it has broken a budget.
	var warm: Array[String] = []
	for node: Node in _all_lights(self):
		var light := node as Light3D
		var colour: Color = light.light_color
		if colour.r > colour.b + GOLD_MARGIN \
				and not light.is_in_group(WorldItem.TREASURE_LIGHT_GROUP):
			warm.append(light.name)
	print("[sight] warm lights not treasure %d" % warm.size())
	if warm.size() > 0:
		problems.append("gold light on %s — `ART-005` spends the game's only "
			% ", ".join(warm)
			+ "saturated colour on treasure, her fire and the ember, so a warm "
			+ "anything-else says 'valuable' about a wall")

	_report(problems, "sight")


## Every `Light3D` under a node, wherever it was added.
func _all_lights(root: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in root.get_children():
		if child is Light3D:
			found.append(child)
		found.append_array(_all_lights(child))
	return found


## The middle of a room, for a probe that needs somewhere to stand in it.
func _room_centre(room: String) -> Vector3:
	var rect: Array = ROOMS[room]
	return Vector3((float(rect[0]) + float(rect[1])) * 0.5, 0.0,
		(float(rect[2]) + float(rect[3])) * 0.5)


## **Do the enemies actually path, or did a navmesh just get baked?**
## (`M2-T14`, ADR-106)
##
## Two different claims, and this project has now been caught confusing them
## twice — ADR-097 shipped party scaling that could not fire, and ADR-105
## shipped a beacon two rooms could see. So this asserts traversal rather than
## existence: a route across the floor must **bend**, because a straight line
## between those two points goes through three walls, and an agent that reports
## a two-point path is an agent walking through the level rather than around it.
func _nav_probe() -> void:
	var problems := PackedStringArray()
	# **The map is not queryable in the frame it is baked in.** Godot syncs
	# navigation once per physics frame, and asking before that returns
	# "query failed because it was made before first map synchronization" and
	# an empty path — which reads exactly like a bake that found no floor.
	# The game is unaffected: `Enemy._steer_toward` walks straight whenever the
	# agent has no path, so the first two frames of a run steer the old way and
	# then the mesh takes over. A probe has no such fallback and must wait.
	await _hold(0.5)
	var map: RID = get_world_3d().navigation_map

	# ─ 0. the bake produced a surface at all ─
	#
	# Reported before anything else because every other failure here looks the
	# same when the mesh is empty: closest-point answers with the world origin,
	# paths come back with no waypoints, and the whole thing reads as "the
	# agents are ignoring the mesh" when in fact there is no mesh to ignore.
	var vertices: int = 0
	if _navigation != null and _navigation.navigation_mesh != null:
		vertices = _navigation.navigation_mesh.get_vertices().size()
	print("[nav] baked mesh                 %d vertices" % vertices)
	if vertices == 0:
		problems.append("the navigation bake produced an empty mesh — nothing "
			+ "was parsed, so no agent has anywhere to walk")

	# ─ 1. there is a map, and it has surface on it ─
	var from: Vector3 = _room_centre("entrance")
	var landed: Vector3 = NavigationServer3D.map_get_closest_point(map, from)
	var drift: float = landed.distance_to(from)
	print("[nav] floor under the spawn      %.2f m from the point asked for" % drift)
	if drift > 1.5:
		problems.append(("no navigable floor near the entrance (nearest is "
			+ "%.1f m away) — the bake found nothing, so every enemy is "
			+ "walking in a straight line exactly as before") % drift)

	# ─ 2. a route across the floor bends around the walls ─
	var to: Vector3 = _room_centre("exit")
	var path: PackedVector3Array = NavigationServer3D.map_get_path(
		map, from, to, true)
	var walked: float = 0.0
	for index: int in range(1, path.size()):
		walked += path[index - 1].distance_to(path[index])
	var direct: float = from.distance_to(to)
	print("[nav] entrance → exit            %d waypoint(s), %.1f m walked vs %.1f m direct"
		% [path.size(), walked, direct])
	if path.size() < 3:
		problems.append("the entrance→exit path has %d waypoint(s) — a route "
			% path.size()
			+ "that does not bend is a route through the walls, which means "
			+ "the agents are not using the mesh")
	elif walked < direct * 1.05:
		problems.append(("the entrance→exit path is %.1f m against %.1f m "
			+ "straight — it is not going around anything") % [walked, direct])

	# ─ 3. the enemies are carrying agents bound to that map ─
	var agentless: int = 0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var agent := node.get_node_or_null("Nav") as NavigationAgent3D
		if agent == null or not agent.get_navigation_map().is_valid():
			agentless += 1
	var total: int = get_tree().get_nodes_in_group("enemies").size()
	print("[nav] enemies on the map         %d of %d" % [total - agentless, total])
	if agentless > 0:
		problems.append("%d enemy/enemies have no navigation agent on a valid "
			% agentless
			+ "map — the mesh exists and nothing is reading it, which is "
			+ "ADR-098's question rather than ADR-097's")

	_report(problems, "nav")


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


## **Can a player's hands reach the bag, and does its text fit the box?**
## (`M2-T18`, ADR-111)
##
## `--bag-probe` proves the bag's *rules* — what fits, what refuses, what
## dropping something buys back — by calling `Inventory` and `Player` directly.
## Every one of those assertions passed while the screen drawing them was a
## `Control` of size **0 x 0**: `set_anchors_preset` sets anchors and leaves
## offsets, nothing lays out a `Control` under a `CanvasLayer`, and Godot routes
## a mouse event to a control only if the point falls inside its rect. So
## `_gui_input` never fired, no item could be clicked or dragged, and the one
## gesture `DES-005` calls the primal counter-play — drag it out and go quiet —
## did not exist for anybody using a mouse.
##
## Two assertions, and both are about the screen rather than the inventory:
##
## 1. **The control covers the viewport**, so a click anywhere the panel is
##    drawn can reach it at any resolution.
## 2. **A click inside it arrives**, which is the thing a zero-sized rect makes
##    impossible and which no amount of correct inventory logic can supply.
##
## Plus the layout: every line the screen draws has to fit the box it is drawn
## in. The header ran 334 px of text through 233 px of panel at `-1` width,
## which means *do not clip*, so it spilled out over the world behind it.
##
## Headless pins the viewport to 64 x 64 whatever `--resolution` says, so the
## panel centres off-screen here and no click could land on a specific item
## wherever the code stood. The two assertions above are the ones that stay true
## at any size, which is why they are the ones asserted.
func _bagui_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var player: Player = _session.local_player()
	player.inventory.add(ItemCatalogue.by_id(&"glt_hoard_coin"))
	await _hold(0.3)

	var bag: BagScreen = null
	for node: Node in player.find_children("*", "BagScreen", true, false):
		bag = node as BagScreen
	if bag == null:
		_report(PackedStringArray(["the local body has no BagScreen at all"]),
			"bagui")
		return

	# Opened with the key a player presses, through `_unhandled_input`.
	var tap := InputEventAction.new()
	tap.action = &"bag"
	tap.pressed = true
	Input.parse_input_event(tap)
	await _hold(0.1)
	var lift := InputEventAction.new()
	lift.action = &"bag"
	lift.pressed = false
	Input.parse_input_event(lift)
	await _hold(0.8)

	var view: Rect2 = Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	print("[bagui] open=%s  control %.0f x %.0f  viewport %.0f x %.0f" % [
		bag.visible, bag.size.x, bag.size.y, view.size.x, view.size.y])
	if not bag.visible:
		problems.append("pressing the bag key did not open the bag")
	if not bag.get_global_rect().encloses(view):
		problems.append(("the bag's control is %.0f x %.0f inside a %.0f x %.0f "
			+ "viewport — it draws a panel it does not cover, and Godot only "
			+ "delivers a click to a control the point lands inside") % [
			bag.size.x, bag.size.y, view.size.x, view.size.y])

	var before: Vector2 = bag.cursor()
	var inside: Vector2 = bag.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = inside
	press.global_position = inside
	Input.parse_input_event(press)
	await _hold(0.2)
	var arrived: bool = bag.cursor() != before
	print("[bagui] click at %.0f,%.0f reached the bag: %s" % [
		inside.x, inside.y, arrived])
	if not arrived:
		problems.append("a click inside the bag never reached `_gui_input` — "
			+ "no item can be picked up, moved or dragged out with a mouse, "
			+ "which is `DES-005`'s counter-play and one of the M2 gate's four "
			+ "preconditions")

	var spilled: PackedStringArray = bag.overflowing()
	print("[bagui] text fits    %s" % [
		"yes" if spilled.is_empty() else "NO, %d line(s)" % spilled.size()])
	for line: String in spilled:
		print("[bagui]   %s" % line)
		problems.append("the bag draws text outside its own panel — " + line)

	_report(problems, "bagui")


## **What it costs to let the Gullsjúkr reach you** (`M2-T19`, ADR-112).
##
## It used to cost nothing. Measured over fourteen seconds of standing at 24 cm:
## health 100 → 100, bag untouched. `DES-017` lists five ways to deal with it —
## bait, delay, confuse, satisfy, eventually kill — and never said what happens
## if none of them work, so the encounter had no consequence to avoid and read,
## correctly, as a thing wandering past.
##
## Four assertions, and the second is the one that keeps this from being a
## damage source in a game that has ruled damage sources out:
##
## 1. **Reaching you takes the richest thing you carry**, not health.
## 2. **Health is untouched.** It cannot be killed at this Pact Rank, so a
##    Gullsjúkr that dealt damage would be an unwinnable fight you could only
##    run from — `CLAUDE.md`'s anti-goal — and it would say nothing about greed.
## 3. **The stoop is a telegraph and backing away cancels it** (ADR-053 puts a
##    250 ms floor under every attack; this is far longer, because the answer to
##    this thing is a decision rather than a reflex).
## 4. **What it takes lands on the floor**, so the loss is visible and can be
##    contested. An item deleted out of a bag is indistinguishable from a bug.
func _toll_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var player: Player = _session.local_player()
	var tuning: TuningProfile = Config.tuning
	player.inventory.clear()
	player.inventory.add(ItemCatalogue.by_id(&"glt_altar_plate"))
	player.inventory.add(ItemCatalogue.by_id(&"mat_bog_iron"))
	# On real floor: the Guardian's room, which is where it starts.
	player.teleport(PRIZE_AT + Vector3(0.0, 0.1, 2.0), 0.0)
	await _hold(0.4)

	# ─ 3. out of reach, it takes nothing however long you wait ─
	_hunter.global_position = player.global_position + Vector3(
		tuning.hunter_reach + 3.0, 0.0, 0.0)
	var carried: int = player.inventory.count()
	await _hold(tuning.hunter_take_seconds * 3.0)
	print("[toll] out of reach  %d item(s) still carried after %.1f s" % [
		player.inventory.count(), tuning.hunter_take_seconds * 3.0])
	if player.inventory.count() != carried:
		problems.append("it took something from beyond its own reach — the "
			+ "stoop has to be a thing you can back out of")

	# ─ 1, 2 and 4. in reach, it takes the richest thing ─
	var before_health: float = player.health.current
	var richest: ItemInstance = player.inventory.richest()
	var floor_items: int = get_tree().get_nodes_in_group(WorldItem.GROUP).size()
	_hunter.global_position = player.global_position + Vector3(0.5, 0.0, 0.0)
	await _hold(tuning.hunter_take_seconds + 1.2)
	var kept: Array[StringName] = []
	for item: ItemInstance in player.inventory.items():
		kept.append(item.definition.id)
	print("[toll] in reach     took %s, bag now %s, health %.0f → %.0f" % [
		richest.definition.id, str(kept), before_health, player.health.current])
	if kept.has(richest.definition.id):
		problems.append(("standing inside you it never took %s — reaching you "
			+ "has to cost the run's value, or the Hunt is a thing that "
			+ "wanders past") % richest.definition.id)
	if player.health.current != before_health:
		problems.append(("it dealt %.0f damage — `DES-017` gives it no attack "
			+ "and it cannot be killed at this rank, so damage would be an "
			+ "unwinnable fight rather than a decision about greed")
			% (before_health - player.health.current))

	var after_items: int = get_tree().get_nodes_in_group(WorldItem.GROUP).size()
	print("[toll] on the floor %d item(s) → %d" % [floor_items, after_items])
	if after_items <= floor_items:
		problems.append("what it took did not land on the floor — a loss with "
			+ "no evidence is indistinguishable from a bug, and there is "
			+ "nothing to run back in and take")

	_report(problems, "toll")


## **The whole party leaves the floor together** (`M2-T20`, ADR-113).
##
## Driven by `tools/run_doorway.py`, which reads every process's log — the
## question is about what happened to *all* of them, so no single process can
## answer it. This half only starts the extraction; the arrival is reported by
## `Threshold`, because this scene is the one that goes away.
##
## **Deliberately not named `--…-probe`.** Any argument containing "probe" sets
## `_probing`, and `_probing` swaps `change_scene_to_file` for `_reset_floor` —
## which is exactly the line that was broken. `--exit-probe` spends a Waystone
## and passes for that reason: solo, and it skips the transition. A check for a
## scene change has to be allowed to change scene.
func _extraction() -> void:
	await _hold(7.0)
	if not multiplayer.is_server():
		print("[extract] client waiting on the floor, party=%d"
			% _session.players().size())
		return
	print("[extract] host ready, party=%d" % _session.players().size())
	var me: Player = _session.local_player()
	me.inventory.add(ItemCatalogue.by_id(&"glt_hoard_coin"))
	me.inventory.add(ItemCatalogue.by_id(&"con_waystone"))
	await _hold(0.5)
	me.ask_to_spend_waystone()


## **What the floor does about a body on it** (`M2-T21`, ADR-114).
##
## Reported from play as *"the enemies are still pathing and trying to attack"*
## a player who had gone out. They were, and it achieved nothing:
## `Health.apply_damage` returns at its first line once `_dead`, so an enemy
## standing over a fallen player deals no damage, emits no `damaged` signal and
## does not even play a Foley cue. Animation with nothing behind it — while
## holding its attention off whoever is coming to help, because acquisition is
## *nearest visible* and a body on the floor is very near.
##
## In the Deep rather than the gym, and that is not a preference: the gym calls
## `_reset()` from `health.died`, so downing a player there frees and respawns
## every enemy in the level. The first draft of this check lived there and died
## on `previously freed` — a venue that deletes the thing under test.
##
## Four assertions, split between the two things that hunt you:
##
## 1. **An ordinary enemy loses a target that goes down** — it leaves ALERTED
##    rather than swinging at a body that cannot be hurt.
## 2. **And does not go home either.** SUSPICIOUS searches `_last_seen`, which
##    is where the body is lying, so a rescuer still walks into a live enemy —
##    the *"time, exposure, noise"* `DES-012` charges for a revive. Going down
##    must not be a free reset for a losing fight.
## 3. **The Gullsjúkr stops for an ember.** `DES-012` says so in as many words
##    and it was false: `con_ember` is worth 0 tribute against a floor of
##    `hunter_wealth_floor`, so the one object that sentence is about could
##    never qualify as bait.
## 4. **And cannot destroy one.** Collecting ends in `queue_free`, so an ember
##    treated like gold would be deleted on a 4.5 s timer — somebody's LIFE,
##    gone to an AI clock with no counter-play once it started.
func _fallen_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var player: Player = _session.local_player()

	# ─ 1 and 2. an ordinary enemy, and a body it just put down ─
	_session.clear_enemies()
	await _hold(0.4)
	player.restore_for_descent()
	player.inventory.clear()
	player.teleport(SPAWNS[0] + Vector3(0.0, 0.1, 0.0), 0.0)
	await _hold(0.3)
	# Yaw 0, not PI: Godot's forward is -Z, so an enemy placed at +3 Z from the
	# player already looks at them. The first draft used PI and spent the whole
	# check reporting UNAWARE at an enemy staring at a wall.
	_session.spawn_enemy(player.global_position + Vector3(0.0, 0.0, 3.0), 0.0)
	await _hold(1.2)
	var watcher: Enemy = null
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var found := node as Enemy
		if found != null and is_instance_valid(found) and found.is_inside_tree():
			watcher = found
	if watcher == null:
		problems.append("no enemy spawned, so nothing here says anything about "
			+ "what one does with a fallen body")
		_report(problems, "fallen")
		return
	# In front of it along its own facing, so the vision cone and the sight ray
	# both pass whatever the room geometry happens to be. Placing the enemy
	# relative to the player instead put it through a wall, and the check spent
	# two runs reporting UNAWARE at an enemy that genuinely could not see.
	player.teleport(watcher.global_position + watcher.facing() * 2.5
		+ Vector3(0.0, 0.1, 0.0), 0.0)
	# **Sampled, not snapshotted.** `sees_player()` is a live ray and it blinks
	# as both bodies move, so a single reading either side proves nothing: the
	# first draft happened to catch `false` *before* the player went down, which
	# would have let the after-reading pass by accident.
	var saw_alive: bool = false
	for tick: int in range(30):
		await _hold(0.05)
		saw_alive = saw_alive or watcher.sees_player()
	var noticed: int = watcher.state()
	print("[fallen] the enemy    %s before, saw the player=%s" % [
		Enemy.State.keys()[noticed].to_lower(), saw_alive])
	if noticed != Enemy.State.ALERTED or not saw_alive:
		problems.append("the enemy never noticed a standing player, so its "
			+ "losing interest afterwards proves nothing")

	player.health.apply_damage(player.health.maximum * 2.0)
	var saw_fallen: bool = false
	for tick: int in range(30):
		await _hold(0.05)
		saw_fallen = saw_fallen or watcher.sees_player()
	var after: int = watcher.state()
	print("[fallen] player down  enemy %s → %s, saw the body=%s" % [
		Enemy.State.keys()[noticed].to_lower(),
		Enemy.State.keys()[after].to_lower(), saw_fallen])
	if not player.is_incapacitated():
		problems.append("the player did not go down")
	if after == Enemy.State.ALERTED or saw_fallen:
		problems.append("the enemy is still hunting a body that cannot be "
			+ "hurt — `Health.apply_damage` refuses once dead, so it is "
			+ "swinging at nothing while a rescuer walks up behind it")
	if after == Enemy.State.UNAWARE:
		problems.append("going down sent the enemy straight back to UNAWARE — "
			+ "that makes being downed a free reset for a losing fight, which "
			+ "`DES-012` is explicit it must not be")

	# ─ 3 and 4. the Gullsjúkr, and somebody's ember ─
	_session.clear_enemies()
	player.restore_for_descent()
	await _hold(0.4)
	var ember_at: Vector3 = _hunter.global_position + Vector3(2.0, 0.1, 0.0)
	# Disturbed, exactly as a death drops it (`_on_died_here`), and bound to a
	# peer so it is somebody's life rather than a prop.
	_session.spawn_world_item(&"con_ember", ember_at, 0.0, Vector3.ZERO, true,
		TEAMMATE_PEER)
	# Well out of the Hunter's way, so its own wealth is not the draw.
	player.teleport(SPAWNS[3] + Vector3(0.0, 0.1, 0.0), 0.0)
	await _hold(Config.tuning.hunter_collect_seconds * 0.5)
	var stooped: bool = _hunter.state() == Gullsjukr.State.COLLECTING
	print("[fallen] the ember    hunter %s (want collecting)"
		% Gullsjukr.State.keys()[int(_hunter.state())].to_lower())
	if not stooped:
		problems.append(("the Gullsjúkr ignored an ember on the floor — "
			+ "`DES-012` says it stops for one, and `con_ember` is worth 0 "
			+ "tribute against a floor of %d, so the one object that sentence "
			+ "is about could never qualify as bait")
			% Config.tuning.hunter_wealth_floor)

	await _hold(Config.tuning.hunter_collect_seconds + 2.0)
	var survived: bool = false
	for node: Node in get_tree().get_nodes_in_group(WorldItem.GROUP):
		var item := node as WorldItem
		if item != null and item.is_inside_tree() and item.is_ember():
			survived = true
	print("[fallen] afterwards   ember still there=%s, hunter %s" % [
		survived, Gullsjukr.State.keys()[int(_hunter.state())].to_lower()])
	if not survived:
		problems.append(("the Gullsjúkr destroyed the ember — collecting ends "
			+ "in `queue_free`, and an ember deleted on a %.1f s timer is a "
			+ "teammate's LIFE gone to an AI clock with no counter-play")
			% Config.tuning.hunter_collect_seconds)

	_report(problems, "fallen")


