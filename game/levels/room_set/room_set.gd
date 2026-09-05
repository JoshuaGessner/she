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
## Where `FloorBuilder`'s output is parsed from when the generated
## floor bakes its own navmesh, kept apart from the hand-built level's
## source group so the two never bake each other.
const GENERATED_NAV_GROUP: StringName = &"generated_nav_source"
## How far a room centre may sit from the mesh before the room counts as
## off it. One body-width plus slack ⟨tune⟩.
const NAV_REACH: float = 1.5
const NAV_AGENT_RADIUS: float = 0.45
const NAV_AGENT_HEIGHT: float = 1.8

## How many physics frames the build probe will wait for the navigation map to
## rebuild after a bake before calling it a failure.
##
## Godot 4.4 made map synchronisation asynchronous by default
## (`navigation/world/map_use_async_iterations`), so the rebuild lands on a
## worker thread some frames after `bake_navigation_mesh()` returns, and
## `map_force_update()` does not wait for it. A *fixed* wait is therefore an
## assumption about how fast the machine is: six frames was ample on this desk
## and not enough on a two-core CI runner, where every room reported "no mesh
## under it" and the row blamed the geometry for a question asked too early
## (ADR-177).
##
## A budget for a poll, not a delay to sit out. Generous on purpose: it costs
## nothing when the map is ready on the first pass, which is the normal case.
const NAV_SYNC_FRAMES: int = 240

## The floor `--build-probe` bakes a navmesh for.
##
## **Chosen for having crossings on it**, which is the whole point: a bridge
## carried over another corridor is the only geometry on a floor that is not
## flat, and the probe baked floor 0 of seed 31337 — which has none — for four
## commits, so an inverted ramp survived every run (ADR-178). This floor carries
## **five crossings and seven great rooms**, so both kinds of ramp — the bridge
## and the ledge — are under every assertion below it.
##
## Re-picked when `LATTICE` tightened (ADR-180): the previous seed was chosen
## for its crossings at the old lattice and had none at the new one. The row
## asserts the count rather than trusting this comment, which is how that was
## noticed within one run instead of four commits later.
const BAKE_SEED: int = 31346

## How much of the planned floor's footprint the baked navmesh must span before
## the build probe will ask it anything. Measured, not guessed — see the row it
## prints. The mesh is inset by the agent radius and skips crawls, so it is
## always somewhat smaller than the plan's hull; this is the margin below which
## "the map holds a fragment" is the better explanation. ⟨tune⟩
const NAV_SPAN_SHARE: float = 0.8
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

## Two ends of the entrance room, for `--stalker-probe` (`M3-T11`). Named
## constants rather than offsets from wherever the player happens to be
## standing, because the first draft used offsets and put every target it
## spawned outside `ROOMS.entrance` — which does not error, it just drops
## things out of the world, and a probe measuring a falling body reports
## confident nonsense. 12 m apart along X keeps both well inside the walls at
## ±8 X and −2/+10 Z, and six `ClamorField` cells apart, so *"the noise landed
## over there"* is a question about two different cells.
## How much of its free travel a **held** body is allowed to cover, in
## `--stalker-probe`. Not zero — a body settles against the floor and drifts a
## few centimetres — and deliberately not *"less than it managed free"*, which
## is the form the first draft used and which a plant walked straight through:
## a Gullsjúkr let loose to walk 2.00 m while snared still read as a pass
## against 4.08 m free, because a body released into a fresh repath covers
## ground unevenly. A quarter is the difference between slowed and held.
const ROOTED_SHARE: float = 0.25

const ARCHER_POST: Vector3 = Vector3(-6.0, 0.1, 4.0)
const BUTT_POST: Vector3 = Vector3(6.0, 0.1, 4.0)

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

## What each floor of an expedition is, in `DES-015` Layer 2's own words:
## *"moving inward is reading the disaster backward."* Floor 0 is what was left,
## floor 1 is where they fought and lost, floor 2 is the thing itself.
##
## Shown on arrival, because a floor the player cannot name is a floor they
## cannot tell from the last one — and three depths that read the same is the
## sameness `DES-015` was written against.
const FLOOR_NAMES: Array[String] = [
	"THE AFTERMATH", "THE RETREAT", "THE CAUSE",
]

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
## The floor's own `Environment`, kept so `--light-shot` can sweep the ambient
## energy without rebuilding the level between exposures (`M4-T13`).
var _environment: Environment = null
var _descent: int = 1
## How deep into this expedition this floor is, 0 to `RunFile.LAST_FLOOR`
## (`M4-T01`, ADR-184). Distinct from `_descent`, which counts *runs* a probe
## has driven — two different numbers that a single name would have conflated.
var _floor_index: int = 0
## True once a descent has been committed, so a Shaft finishing its channel
## twice in the frames before the scene changes takes the party down once.
var _going_down: bool = false
## True while a probe is driving this level. Probes measure the floor and must
## not be dropped into the Lair halfway through a measurement.
var _probing: bool = false
## Seconds of Hunt a missed Tithe bought her on this floor, kept so the arrival
## brief can say so (ADR-124). Zero on a settled cycle.
var _she_sent_it_early: float = 0.0
## True while a wipe is counting down, so four bodies going out together start
## one run-end rather than four (`M2-T16`).
var _ending: bool = false
## Peers whose ember reached an exit in somebody's bag (`M3-T33`, `DES-012`).
## Per floor, and cleared with it: a rescue is about this run and nothing else.
var _borne_out: Dictionary = {}
## Set when somebody presses TO THE FIRE, which ends the wipe window early
## (ADR-151). The wait is a floor rather than a fixed price.
var _skip_the_wait: bool = false
## The screen that says the run is over, or null. Held so a second body going
## out does not build a second one, and so a cancelled wipe can take it away.
var _run_over: CanvasLayer = null
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

## The floor under this level (`M4-T01`, ADR-182).
##
## Every hand-placed position `_ready` and its builders used to read inline is
## read through here instead, so the same machinery serves a generated floor by
## being handed a different source. Defaults to the Deep, which is what keeps
## this level and the thirty probes that measure it behaving exactly as before.
var _floor: FloorSource = AuthoredFloor.new()


func _ready() -> void:
	# **First, before anything reads it.** Any probe at all means this process
	# is measuring the floor rather than playing the loop — extraction must not
	# change scene out from under it, and the arrival brief must not fade three
	# labels across a screenshot. This used to be decided *after* `_build_hud`,
	# so a HUD element asking `_probing` would silently always see `false`.
	for arg: String in OS.get_cmdline_user_args():
		if arg.contains("probe") or arg.contains("shot") or arg.contains("capture"):
			_probing = true
		# **Sworn before the body is built** (`M3-T11`). A class reaches a body
		# through the spawn payload and nowhere else (`M3-T02`, ADR-121), so a
		# probe that swore after `_spawn_actors` would be measuring a body it
		# had reached in and edited rather than one the host built — which is
		# the difference the whole class path was written to preserve.
		# **A probe body is a sworn body** (`M3-T07`). Slots mean the class kit
		# is what puts a weapon in your hand, and a classless body has empty
		# hands — correct in the game, where you always have a class, and wrong
		# for a measurement that is supposed to resemble play.
		#
		# Only under a probe flag. The two-process smoke gets there through
		# `--as-class=`, because it is not a probe and a level quietly handing
		# out a class would hide the day the menu stops doing it.
		if arg.contains("probe") and GameState.class_id == &"":
			GameState.class_id = &"huskarl"
		if arg == "--stalker-probe":
			GameState.class_id = &"veidimadr"
		# **A cycle that closed short, set up before the floor exists**
		# (ADR-124). The whole question is what the *floor* does about it, and
		# a debt arranged after `_ready` would be a reconstruction of the order
		# rather than the order — which is exactly how the bug this probe
		# exists for survived: every part was checked and the sequence was not.
		if arg == "--creditor-probe":
			GameState.pact_rank = 1
			# **Part-paid, not unpaid.** The first draft set this to 0, which
			# made *"the slate cleared"* unable to fail: it asserted the total
			# was 0 afterwards, and it had been 0 the whole time. Short of the
			# rank-1 Tithe of 40, so she is still owed and both halves of this
			# probe still have something to measure.
			GameState.tithe_paid = 10
			GameState.cycle_runs = Config.tuning.tithe_cycle_runs
	# **Read the seed before acting on anything** (ADR-169). It used to be parsed
	# in the same pass that dispatches the probes, which hashed the floor for seed
	# 0 every time — and the flag below chooses a *floor* from it, so the same
	# ordering fault would now put the party in a different Delvings than the one
	# asked for.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			_run_seed = int(arg.split("=", true, 1)[1])

	# **Which floor is under this level** (`M4-T01`, ADR-183).
	#
	# `--delvings` and `--seed=N` hand it a generated one; without them it is
	# the Deep, which is what every probe in this file measures and what
	# `AuthoredFloor` exists to keep unchanged. One flag, read before anything
	# is built, because the floor decides where the lights hang and where the
	# party lands.
	#
	# A floor that would not plan is **refused rather than half-built**: the
	# generator re-rolls up to `MAX_ROLLS` times and has never failed a corpus,
	# so arriving here with problems means something is wrong that walking
	# around in it would only obscure.
	# **Depth and seed come from the open run** (`M4-T01`, ADR-184).
	#
	# Never from `GameState.descents`, which counts every descent a *lineage*
	# has ever made: reading it would look right and quietly roll floor 47 on
	# somebody's forty-eighth run. What this wants is how deep into *this
	# expedition* the party is, 0 to `LAST_FLOOR`, and that is what a run file
	# is for — `TEC-003` has named *floor transition* an autosave point since
	# before there were floors to transition between.
	#
	# **The flags are the unarmed process's door, on the `--as-rank=` precedent**
	# (ADR-119), and this is not the parallel fallback ADR-064 bans. A probe
	# booting this level directly is not on an expedition — `RunFile` shows it
	# no run at all, deliberately — so there is no second *game* path here to
	# drift: the run is the only source when there is one, and `--floor=`/
	# `--seed=` are how a measurement asks for a floor to look at.
	var asked_for: PackedStringArray = OS.get_cmdline_user_args()
	var seed_was_named: bool = false
	for arg: String in asked_for:
		if arg.begins_with("--seed="):
			seed_was_named = true
	var depth: int = 0
	if RunFile.exists():
		depth = RunFile.floor_index()
		# **`--seed=` still wins, and that is the replay path** (ADR-187).
		#
		# `TEC-001` requires a run seed to be loggable and replayable off a bug
		# report, and `Threshold._descend` prints one at every descent. Without
		# this the printed number would be unusable the moment the descent
		# started opening onto the Delvings: a real run always has a run file,
		# so the file's seed would always win and *"launch with the seed from
		# the report"* would silently build a different floor.
		if not seed_was_named:
			_run_seed = RunFile.seed_of()
	else:
		for arg: String in asked_for:
			if arg.begins_with("--floor="):
				depth = clampi(int(arg.split("=", true, 1)[1]),
					0, RunFile.LAST_FLOOR)
	_floor_index = depth
	# **A run is played in the Delvings** (`M4-T01`, ADR-187).
	#
	# This used to be *"the Delvings if somebody typed `--delvings`"* — and a
	# played game has no command line, so the flag was unreachable by playing
	# and the descent always opened onto the Deep. `M4-T01` says the Delvings
	# replaces it, and an open run is what says a person is playing.
	#
	# **The Deep is not a fallback, it is the test stage.** An unarmed process
	# is a probe (ADR-138), and `AuthoredFloor` is the fixed, deterministic
	# floor thirty of them measure — six rooms and twelve doors that
	# `--sight-probe` and `--route-probe` are written around. `--build-probe`,
	# `--plan-probe` and `--delvings-probe` are what measure the generated one.
	# Two floors, one played and one measured against, rather than two paths a
	# player could be on (ADR-064).
	var generated: bool = RunFile.exists()
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--delvings" or arg == "--delvings-probe":
			generated = true
	if generated:
		var rolled := DelvingsFloor.of(_run_seed, depth)
		if not rolled.problems().is_empty():
			push_error("the Delvings would not plan: %s"
				% " · ".join(rolled.problems()))
			return
		_floor = rolled
		print("[delvings] seed %d, floor %d" % [_run_seed, depth])
	AudioDirector.enter("deep")
	_build_lighting()
	_floor.build(_world)
	_spawn_actors()
	# What you emit and what they perceive, on the floor (ADR-078). This set has
	# corners and doorways, which is the only place occlusion has anything to
	# show — the gym it came from is mostly open ground.
	# Before the actors, so the first enemy to think has a map to think on.
	_build_navigation()
	# **She settles at the door, and the door is here** (`M3-T04`, ADR-124).
	#
	# ADR-118 put this *"before the stash goes down, because a short cycle
	# changes what is waiting for you on this floor and not what you brought to
	# it"* — and then placed the call below `_build_hud`, seventeen lines after
	# the Hunt it was supposed to change. The rationale was right and the code
	# did the opposite; `_build_hunt` reads the head start, so the settle has to
	# precede it.
	#
	# **Not gated on `_probing`.** It was, alongside `_carry_the_stash_down`,
	# and only the second one needs it — a probe inheriting a loadout is
	# measuring a bag it did not pack. Nothing here can touch a player's file:
	# `GameState._live` is false until `load_profile()` succeeds and `MainMenu`
	# is its only caller (ADR-117), so `_persist()` in a probe writes nowhere.
	# Ungating it is what lets `--creditor-probe` drive the real order instead
	# of a reconstruction of it.
	GameState.settle_cycle()
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
		elif arg == "--walk-probe":
			_walk_probe()
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
		elif arg == "--ground-probe":
			_ground_probe()
		elif arg.begins_with("--delvings-shot="):
			_delvings_shot(arg.split("=", true, 1)[1])
		elif arg.begins_with("--light-shot="):
			_light_shot(arg.split("=", true, 1)[1])
		elif arg == "--lantern-probe":
			_lantern_probe()
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
		elif arg == "--abandoned":
			_abandoned()
		elif arg == "--again":
			_again()
		elif arg == "--fallen-probe":
			_fallen_probe()
		elif arg == "--ember-probe":
			_ember_probe()
		elif arg == "--wing-probe":
			_wing_probe()
		elif arg == "--run-probe":
			_run_file_probe()
		elif arg == "--descent-probe":
			_descent_probe()
		elif arg == "--vordr-probe":
			_vordr_probe()
		elif arg == "--stalker-probe":
			_stalker_probe()
		elif arg == "--creditor-probe":
			_creditor_probe()
		elif arg == "--gear-probe":
			_gear_probe()
		elif arg == "--rank-probe":
			_rank_probe()
		elif arg == "--scaling-probe":
			_scaling_probe()
		elif arg.begins_with("--ember-shot="):
			_ember_shot(arg.split("=", true, 1)[1])
		elif arg == "--hash":
			_print_hash()
		elif arg == "--graph-probe":
			_graph_probe()
		elif arg == "--plan-probe":
			_plan_probe()
		elif arg == "--build-probe":
			_build_probe()
		elif arg == "--delvings-probe":
			_delvings_probe()
		elif arg == "--machine-probe":
			_machine_probe()
		elif arg == "--hud-probe":
			_hud_probe()
		elif arg.begins_with("--machine-shot="):
			_machine_shot(arg.split("=", true, 1)[1])
		elif arg.begins_with("--coop-probe="):
			_coop_probe(arg.split("=", true, 1)[1])


## **The mission graph, before it has any geometry** (`M4-T01`, `DES-015`).
##
## Six claims, and the third is the one that could not have existed before
## today.
##
## `check_determinism.py` has passed `--seed=` since `M1-T07` and **nothing in
## this project has ever read it.** The layout is six literal `AABB`s, so every
## seed produces an identical hash and the harness has been asserting that a
## constant is constant. That is not a criticism of the harness — `WorldHash`
## says so in its own header, and being written before the generator is what
## makes it a specification rather than a description. But it means the harness
## can catch *"the engine introduced variance"* and cannot catch the failure a
## generator actually has: **ignoring its seed.** A generator that returned the
## same floor every time would pass `check_determinism.py` perfectly.
##
## So determinism is asserted in both directions here. Same seed, same graph —
## and *different seed, different graph*, which is the half that has been
## missing and the half a stubbed generator fails.
##
## Run over many seeds rather than one, because `problems()` is a claim about
## every floor the generator can emit and a single sample proves nothing about
## a random process. Cheap: no scene, no navmesh, no meshes — the whole point
## of building topology first.
## `DES-015` step 4 — the graph became a space, and is still the graph.
##
## The row no other check can make: **connectivity is read back off the grid**,
## not taken from the graph that asked for it. `MissionGraph.problems()` proves
## the topology poses a decision; this proves the floor built from it still
## does. A corridor that clipped a third room, or two rooms that ended up
## flush, would leave every graph assertion passing about a floor that no
## longer matches — the ADR-032 bypass in particular, which is a claim about
## routes and therefore about geometry the moment geometry exists.
## Every kind of Prize the corpus can actually build. The roll draws from
## this rather than a written-down list, so a history can never promise a Prize
## no floor could hold.
func _prize_kinds(modules: Array[RoomModule]) -> PackedStringArray:
	var kinds: PackedStringArray = PackedStringArray()
	for module: RoomModule in modules:
		if module.prize_kind != &"" and not kinds.has(String(module.prize_kind)):
			kinds.append(String(module.prize_kind))
	kinds.sort()
	return kinds


## `TEC-008` — the plan became a place, and it is still the plan.
##
## `--plan-probe` proves the floor is the mission as *integers*. This proves the
## metres agree with the integers: a room the builder never raised, a wall it
## sealed where a corridor arrives, or a ceiling under the standing body would
## all leave every earlier row passing about a floor nobody can walk.
##
## Geometry is asserted by measurement, not by counting nodes. A builder that
## emitted the right number of boxes in the wrong places would pass a census.
func _build_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var modules: Array[RoomModule] = RoomCatalogue.all()
	var calamities: Array[CalamityResource] = CalamityCatalogue.all()
	var kinds: PackedStringArray = _prize_kinds(modules)

	# ─ 1. a floor of every depth builds at all ─
	var built: int = 0
	var raised: Array[Node3D] = []
	var alcoves: int = 0
	var ledges: int = 0
	for depth: int in 3:
		var graph: MissionGraph = MissionGraph.build(31337, depth)
		var lore := ExpeditionHistory.roll(31337, calamities, kinds)
		var plan: FloorPlan = FloorPlan.build(graph, 31337, depth, modules, lore)
		if not plan.problems().is_empty():
			problems.append("floor %d did not plan, so geometry has nothing to "
				% depth + "build from")
			continue
		var root := Node3D.new()
		add_child(root)
		raised.append(root)
		var census: Dictionary = FloorBuilder.build(plan, graph, 31337, depth, root)
		built += 1
		alcoves += int(census["alcoves"])
		ledges += int(census["ledges"])
		print("[build] floor %d     %d room(s), %d corridor cell(s), %d slab(s), "
			% [depth, census["rooms"], census["corridor"], census["slabs"]]
			+ "roughness %.1f" % census["roughness"])
		if int(census["rooms"]) != graph.size():
			problems.append("floor %d raised %d of %d rooms"
				% [depth, census["rooms"], graph.size()])
		if int(census["slabs"]) < graph.size() * 4:
			problems.append(("floor %d emitted %d slabs for %d rooms — a room "
				+ "needs a floor, a ceiling and walls before it is a room")
				% [depth, census["slabs"], graph.size()])
	if built != 3:
		_report(problems, "build")
		return

	# ─ 1a. the devices that buy Lynch's missing three ─
	#
	# `TEC-008` §2.2's finding was that the floors had **paths** and **nodes** and
	# no **edges**, **districts** or **landmarks** — the three a player builds a
	# mental map out of. The gradient below is the districts; alcoves are the
	# edges; ledges are the landmarks and the vista rule's delivery mechanism.
	#
	# Counted, because each one is emitted only where the floor permits it — an
	# alcove needs a pocket of rock, a ledge needs a great room with a door-free
	# wall — and a condition that quietly stopped being met would leave every
	# other row here passing about a floor that had gone back to boxes and
	# corridors. That is `TEC-007` §1's population rule, and this row is what it
	# looks like when it is applied before the fact rather than after.
	print("[build] devices     %d alcove(s), %d ledge(s) across 3 floors"
		% [alcoves, ledges])
	if alcoves == 0:
		problems.append("no room on any of three floors was given an alcove — "
			+ "every large room is a rectangle again, which is the wall line "
			+ "`TEC-008` §3.3.3 exists to break")
	if ledges == 0:
		problems.append("no great room on any of three floors was given a ledge "
			+ "— `DES-015`'s vista rule has no delivery mechanism without one")

	# ─ 2. the worked stone gives way to the seam ─
	#
	# Floor 1 is orthogonal Dvergar working and floor 3 is what they dug into,
	# and one number drives it (`TEC-008` §3.1). If the gradient ever flattens,
	# three floors go back to being three sizes — which is the exact failure the
	# floor sheet exposed and ADR-175 exists to fix.
	var chamfers: PackedInt32Array = PackedInt32Array()
	for root: Node3D in raised:
		var cut: int = 0
		for child: Node in root.get_children():
			if absf((child as Node3D).rotation.y) > 0.01:
				cut += 1
		chamfers.append(cut)
	print("[build] gradient    cut corners by depth: %d, %d, %d"
		% [chamfers[0], chamfers[1], chamfers[2]])
	if chamfers[0] != 0:
		problems.append(("floor 1 cut %d corners — the top of the Delvings is "
			+ "Dvergar working and should read as built") % chamfers[0])
	if chamfers[2] <= chamfers[1] or chamfers[1] == 0:
		problems.append(("corners cut per depth run %d, %d, %d — the gradient "
			+ "from worked stone to raw cave is what makes three floors three "
			+ "places rather than three sizes")
			% [chamfers[0], chamfers[1], chamfers[2]])

	# ─ 3. nothing the player must stand in refuses the standing body ─
	#
	# Measured off the raised geometry rather than the module table, because the
	# ceiling a room ends up with is nominal height plus a drift the builder
	# rolled, and it is the sum that a head hits.
	var squashed: int = 0
	var lowest: float = 999.0
	for root: Node3D in raised:
		for child: Node in root.get_children():
			var node := child as MeshInstance3D
			var box := node.mesh as BoxMesh
			# **Asked by name, not by shape.** The first version called any thin
			# slab above half a metre a ceiling, which was true until corridors
			# began to ramp — and then a *raised floor* answered as a ceiling
			# 0.6 m off the ground and the row failed on healthy geometry.
			if box == null or not String(node.name).contains("ceiling"):
				continue
			var clear: float = node.position.y - FloorBuilder.WALL_THICK * 0.5
			lowest = minf(lowest, clear)
			if clear < FloorBuilder.CEILINGS[0] - 0.01:
				squashed += 1
	print("[build] headroom    lowest ceiling %.2f m, %d below the crawl floor"
		% [lowest, squashed])
	if squashed > 0:
		problems.append(("%d ceiling(s) sit under %.2f m — below the crawl "
			+ "height nothing can pass at all, and a room the player cannot "
			+ "enter is a soft-lock geometry made")
			% [squashed, FloorBuilder.CEILINGS[0]])

	# ─ 4. every door the plan authorised is a hole, and no other ─
	#
	# The row no other check can make. `--plan-probe` proves connectivity as
	# integers; this proves the walls agree. A sealed doorway is a soft-lock the
	# topology cannot see, and a hole with no door behind it is a route ADR-032
	# never authorised, arriving as geometry instead of as a corridor.
	var graph: MissionGraph = MissionGraph.build(31337, 0)
	var lore2 := ExpeditionHistory.roll(31337, calamities, kinds)
	var plan: FloorPlan = FloorPlan.build(graph, 31337, 0, modules, lore2)
	# **Measured through the wall, not read off the plan.** The first version of
	# this row counted `doors_of()` and compared it to the edge list — the plan
	# against itself. Building every wall solid, with no doorway cut at all,
	# left it passing. An assertion made from a convenient existing value
	# measures that value, not the property; this is the fifth time in `M4-T01`.
	var shell := Node3D.new()
	# Stood well clear of everything else in the world, because the question
	# below is asked of the *physics space* and this scene already holds three
	# other generated floors built at the origin, on top of each other, plus
	# the authored level. A query that cannot say which floor answered it is
	# not a measurement.
	shell.position = Vector3(5000.0, 0.0, 5000.0)
	add_child(shell)
	FloorBuilder.build(plan, graph, 31337, 0, shell)

	# **Asked of the collider, not of an axis-aligned box.** The first version
	# built an AABB per slab from its position and skipped anything yawed — but
	# a ledge ramp is *pitched*, its yaw is zero, and the box of a tilted plate
	# is not its shape. It reported a doorway walled shut by a ramp that is at
	# floor level where the doorway is, and 2.5 m away from it a few metres on.
	# ADR-176 fixed exactly this in the join check and left it here.
	#
	# The collider is also what the player will actually walk into, so the row
	# now measures the thing it has always claimed to.
	await get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var point := PhysicsPointQueryParameters3D.new()
	point.collision_mask = CollisionLayers.WORLD
	point.collide_with_areas = false

	var blocked: int = 0
	var doors: int = 0
	var sealed: int = 0
	var culprits: PackedStringArray = PackedStringArray()
	for node: int in graph.size():
		var want: Array[Vector2i] = plan.doors_of(node)
		if want.is_empty():
			sealed += 1
		var rect: Rect2i = plan.rect_of(node)
		for cell: Vector2i in want:
			doors += 1
			# The wall plane sits halfway between the corridor cell and the
			# room cell it opens into, so that midpoint is exactly what a
			# solid wall would occupy and a doorway would not.
			var inside := Vector2i(clampi(cell.x, rect.position.x, rect.end.x - 1),
				clampi(cell.y, rect.position.y, rect.end.y - 1))
			var a: Vector3 = FloorBuilder.at(cell) + Vector3(
				FloorBuilder.CELL * 0.5, 1.0, FloorBuilder.CELL * 0.5)
			var b: Vector3 = FloorBuilder.at(inside) + Vector3(
				FloorBuilder.CELL * 0.5, 1.0, FloorBuilder.CELL * 0.5)
			point.position = (a + b) * 0.5 + shell.position
			var hit: Array[Dictionary] = space.intersect_point(point, 1)
			if not hit.is_empty():
				blocked += 1
				# Name the slab standing in the doorway. "A doorway is sealed"
				# sends you looking at the wall builder; "a ledge ramp is
				# sealing it" sends you to the right file in one step.
				var by: Node3D = (hit[0]["collider"] as Node).get_parent() as Node3D
				var what: String = "%s at %s over door %s of room %d (%s)" % [
					by.name, by.position.round(), cell, node,
					plan.module_of(node)]
				if not culprits.has(what):
					culprits.append(what)
	print("[build] doorways    %d door(s) across %d room(s), %d walled shut"
		% [doors, graph.size(), blocked])
	if sealed > 0:
		problems.append("%d room(s) have no doorway at all" % sealed)
	if doors != graph._edges.size() * 2:
		problems.append(("%d doorways for %d corridors — every corridor opens at "
			+ "both ends or one of its rooms is sealed")
			% [doors, graph._edges.size()])
	if blocked > 0:
		problems.append(("%d of %d doorways are walled shut by %s — the plan "
			+ "opened them and the geometry did not, which is a soft-lock no "
			+ "topology check can see")
			% [blocked, doors, ", ".join(culprits)])

	# ─ 5. same seed, same metres ─
	var again := Node3D.new()
	add_child(again)
	var twice: Dictionary = FloorBuilder.build(plan, graph, 31337, 0, again)
	# Parented, and freed below. The first draft built this floor into a bare
	# `Node3D.new()` written inline — never added to the tree, so nothing ever
	# freed it, and its 472 static bodies were still allocated at exit. Godot
	# reports that as seven `ERROR: ... leaked at exit` lines, `check_scripts.sh`
	# greps for `^ERROR:`, and the row therefore failed while every assertion
	# inside it passed. Nodes in the tree are released by teardown; an orphan is
	# the one thing that has to free itself.
	var apart := Node3D.new()
	add_child(apart)
	var first: Dictionary = FloorBuilder.build(plan, graph, 31337, 0, apart)
	print("[build] same seed   %s" % ("identical"
		if twice["slabs"] == first["slabs"] else "DIVERGED"))
	if twice["slabs"] != first["slabs"]:
		problems.append("one plan raised two different floors — `TEC-004` needs "
			+ "geometry bit-exact or two players disagree about a wall")
	again.free()
	apart.free()

	# ─ 6. the floor bakes a navmesh, and the AI can use most of it ─
	#
	# `DES-015` step 8 asks for "navmesh sane". ADR-172 split that off as a
	# **build-time assertion** rather than a runtime re-roll, because Recast is
	# threaded and platform-dependent and a bake-triggered re-roll on one
	# machine and not another is the desync the determinism clause forbids. So
	# it fails the build here and never runs as a gameplay decision.
	#
	# **A crawl with no navmesh is correct, not broken.** The agent stands
	# 1.8 m and a crawl is 1.4 m, so the Hunt cannot follow you in there. That
	# is `DES-009`'s crouch verb given teeth — the player ducks through and
	# what is chasing them has to go round — and asserting "every room is
	# navigable" would have quietly deleted it.
	# ─ 6a. no floor slab meets another edge to edge ─
	#
	# **The cheap check for the expensive bug.** A room's floor ended exactly
	# where a corridor's began; Recast voxelizes at 0.15 m, those seams do not
	# land on voxel boundaries, and a butt joint can rasterise into a hairline
	# gap that splits a room's mesh from the corridor serving it. The symptom
	# was a room a route entered and stopped inside — and it was *intermittent*,
	# because it depends where each edge falls against the grid.
	#
	# Baking a corpus to catch that is slow and fragile. The joint itself is
	# neither: every floor slab must overlap something, and that is checkable
	# over many floors in milliseconds.
	var corpus: Array[Vector2i] = [
		Vector2i(31337, 0), Vector2i(31337, 1), Vector2i(31337, 2),
		Vector2i(8801, 1), Vector2i(4242, 0), Vector2i(909, 2),
		Vector2i(1000, 0), Vector2i(1005, 2),
	]
	var butted: int = 0
	var checked: int = 0
	for pick: Vector2i in corpus:
		var g: MissionGraph = MissionGraph.build(pick.x, pick.y)
		var lore: ExpeditionHistory = ExpeditionHistory.roll(
			pick.x, calamities, kinds)
		var p: FloorPlan = FloorPlan.build(g, pick.x, pick.y, modules, lore)
		if not p.problems().is_empty():
			continue
		var shelf := Node3D.new()
		add_child(shelf)
		FloorBuilder.build(p, g, pick.x, pick.y, shelf)
		var floors: Array[AABB] = []
		for child: Node in shelf.get_children():
			var n := child as MeshInstance3D
			var b := n.mesh as BoxMesh
			var role: String = String(n.name)
			if b == null or not (role.contains("floor") or role.contains("ramp")):
				continue
			# Through the node's transform: a ramp is tilted, and its
			# axis-aligned bounds are not its box.
			floors.append(n.transform * AABB(-b.size * 0.5, b.size))
		for i: int in floors.size():
			checked += 1
			var laps: bool = false
			for j: int in floors.size():
				if i != j and floors[i].intersects(floors[j]):
					laps = true
					break
			if not laps and floors.size() > 1:
				butted += 1
		shelf.free()
	print("[build] joins       %d floor slab(s) across %d floors, %d isolated"
		% [checked, corpus.size(), butted])
	if butted > 0:
		problems.append(("%d floor slab(s) touch nothing they overlap — a butt "
			+ "joint between coplanar slabs can voxelize into a seam and cut a "
			+ "room off the navmesh") % butted)

	# ─ 6b. one floor, baked, walked end to end ─
	#
	# `DES-015` step 8's "navmesh sane", as a build-time assertion rather than a
	# runtime re-roll (ADR-172): Recast is threaded and platform-dependent, so a
	# bake-triggered re-roll on one machine and not another is the desync the
	# determinism clause forbids. It fails the build and never runs in play.
	#
	# **A crawl with no navmesh is correct, not broken.** The agent stands
	# 1.8 m and a crawl is 1.4 m, so the Hunt cannot follow you in there — that
	# is `DES-009`'s crouch verb given teeth, and asserting "every room is
	# navigable" would quietly delete it.
	#
	# **The floor baked here is chosen for having a crossing on it**, and that
	# is not a detail. Every row below ran against floor 0 for four commits, and
	# floor 0 has no crossing — so the ramped bridge ADR-176 exists to build had
	# never once been asked whether anything could walk up it. It could not: the
	# tilt was inverted, every ramp in the file sloped the wrong way, and the
	# check that would have said so was baking the one floor with no ramps on
	# it. `BAKE_SEED` carries four; the row asserts that rather than trusting
	# it, because a corpus change could quietly take them away again (ADR-178).
	var bake: MissionGraph = MissionGraph.build(BAKE_SEED, 0)
	var bake_lore := ExpeditionHistory.roll(BAKE_SEED, calamities, kinds)
	var bake_plan: FloorPlan = FloorPlan.build(
		bake, BAKE_SEED, 0, modules, bake_lore)
	var crossings: int = 0
	for route: int in bake_plan.routes():
		crossings += bake_plan.over_of(route).size()
	print("[build] bake floor  seed %d, %d room(s), %d crossing cell(s)"
		% [BAKE_SEED, bake.size(), crossings])
	if crossings == 0:
		problems.append("the floor this bakes has no crossing on it, so every "
			+ "row below is silent about the one piece of geometry on a floor "
			+ "that is not flat — which is how an inverted ramp survived")
		_report(problems, "build")
		return

	var navroot := Node3D.new()
	add_child(navroot)
	FloorBuilder.build(bake_plan, bake, BAKE_SEED, 0, navroot)
	navroot.add_to_group(GENERATED_NAV_GROUP)

	var navmesh := NavigationMesh.new()
	navmesh.agent_radius = NAV_AGENT_RADIUS
	navmesh.agent_height = NAV_AGENT_HEIGHT
	navmesh.agent_max_climb = 0.3
	navmesh.agent_max_slope = 45.0
	navmesh.cell_size = 0.15
	navmesh.cell_height = 0.15
	navmesh.geometry_parsed_geometry_type = \
		NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navmesh.geometry_source_geometry_mode = \
		NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	navmesh.geometry_source_group_name = GENERATED_NAV_GROUP
	var region := NavigationRegion3D.new()
	region.navigation_mesh = navmesh
	add_child(region)
	region.bake_navigation_mesh(false)

	var vertices: int = navmesh.get_vertices().size()
	print("[build] navmesh     %d vertices baked" % vertices)
	if vertices == 0:
		problems.append("the generated floor baked no navmesh at all — "
			+ "nothing that hunts the player can move on it")
		_report(problems, "build")
		return

	# ─ 6c. the map has actually rebuilt before anything asks it a question ─
	#
	# A baked resource and a navigable map are different claims, and the gap
	# between them is asynchronous. Waiting a fixed six frames measured this
	# desk: CI baked the *same 260 vertices* and then reported all eight
	# standing rooms off the mesh, because the map had not swapped the rebuild
	# in yet and `map_get_closest_point` answers honestly about an empty map.
	#
	# **`region_get_bounds()` is not the sentinel**, and finding that out is
	# what reproduced CI here. The region reports its full 77 x 81 m one frame
	# after the bake — while the *map* it belongs to still answers nothing, for
	# several frames more. A poll that waited on the region's own extent turned
	# this desk red in exactly CI's words. The region receiving its data and
	# the map merging it are two events, and only the second can be asked a
	# question.
	#
	# So poll the map for the population it is about to be measured on
	# (`TEC-007` §1) — every room that ought to be walkable — and stop as soon
	# as they are all there. A genuinely stranded room spends the whole budget
	# and is then reported by the rows below, which is the right trade: four
	# seconds on a floor that is already failing.
	var map: RID = get_world_3d().navigation_map
	var entrance: int = bake.node_with(MissionGraph.Role.ENTRANCE)
	var start_at: Vector3 = _plan_centre(bake_plan, entrance)

	# A crawl is 1.4 m and the agent stands 1.8 m, so a crawl with no mesh is
	# correct — and must not hold the poll open for the whole budget.
	var standing: Array[int] = []
	var crawls: int = 0
	for node: int in bake.size():
		var module: RoomModule = RoomCatalogue.by_id(bake_plan.module_of(node))
		if module != null and module.volume == RoomModule.Volume.CRAWL:
			crawls += 1
			continue
		standing.append(node)

	var synced: int = -1
	var on_mesh: int = 0
	for frame: int in NAV_SYNC_FRAMES:
		NavigationServer3D.map_force_update(map)
		# Asking before the server's first synchronization is an engine error,
		# not merely an empty answer — Godot prints "navigation map query
		# failed because it was made before first map synchronization", and an
		# `ERROR:` line fails the sweep however green the rows below read.
		# `map_get_iteration_id` is the honest signal that a map exists to ask.
		if NavigationServer3D.map_get_iteration_id(map) > 0:
			on_mesh = 0
			for node: int in standing:
				var centre: Vector3 = _plan_centre(bake_plan, node)
				if NavigationServer3D.map_get_closest_point(map, centre) \
						.distance_to(centre) <= NAV_REACH:
					on_mesh += 1
			if on_mesh == standing.size():
				synced = frame
				break
		await get_tree().physics_frame

	var bounds: AABB = NavigationServer3D.region_get_bounds(region.get_rid())
	var hull: Rect2i = bake_plan.rect_of(0)
	for node: int in bake.size():
		hull = hull.merge(bake_plan.rect_of(node))
	var want: Vector2 = Vector2(hull.size) * FloorBuilder.CELL
	print("[build] nav sync    %d/%d room(s) on a %.0f x %.0f m mesh of the "
		% [on_mesh, standing.size(), bounds.size.x, bounds.size.z]
		+ "plan's %.0f x %.0f, after %d frame(s)"
		% [want.x, want.y, synced if synced >= 0 else NAV_SYNC_FRAMES])
	if on_mesh == 0:
		# Two different failures reach this line, and the region's bounds tell
		# them apart: if the server is holding a mesh, the rooms are simply not
		# on it, and blaming synchronisation would send the next reader to the
		# wrong place entirely.
		problems.append((("the map holds a %.0f x %.0f m mesh and not one of "
			+ "%d rooms could reach it in %d frames — the mesh is somewhere "
			+ "the rooms are not")
			% [bounds.size.x, bounds.size.z, standing.size(), NAV_SYNC_FRAMES])
			if bounds.get_volume() > 0.0 else
			(("the navigation map never rebuilt in %d frames — the mesh baked "
			+ "%d vertices and the server is still holding nothing, so every "
			+ "route question below would answer about an empty map")
			% [NAV_SYNC_FRAMES, vertices]))
		_report(problems, "build")
		return
	if bounds.size.x < want.x * NAV_SPAN_SHARE \
			or bounds.size.z < want.y * NAV_SPAN_SHARE:
		problems.append(("the navmesh spans %.0f x %.0f m of a %.0f x %.0f m "
			+ "floor — the map holds a fragment, and a fragment answers every "
			+ "question below about the part of the floor it happens to cover")
			% [bounds.size.x, bounds.size.z, want.x, want.y])
		_report(problems, "build")
		return

	var stranded: PackedStringArray = PackedStringArray()
	for node: int in standing:
		if node == entrance:
			continue
		var centre: Vector3 = _plan_centre(bake_plan, node)
		var route: PackedVector3Array = NavigationServer3D.map_get_path(
			map, start_at, centre, true)
		if not route.is_empty() \
				and route[route.size() - 1].distance_to(centre) <= NAV_REACH:
			continue
		var near: Vector3 = NavigationServer3D.map_get_closest_point(map, centre)
		var why: String = "no mesh under it" \
			if near.distance_to(centre) > NAV_REACH else "an island, walled in"
		stranded.append("%d (%s, %s, route ends %.2f m short)"
			% [node, bake_plan.module_of(node), why,
				route[route.size() - 1].distance_to(centre)
				if not route.is_empty() else -1.0])
	print("[build] coverage    %d room(s) off the mesh, %d crawl(s) excluded "
		% [stranded.size(), crawls] + "on purpose")
	if not stranded.is_empty():
		problems.append(("%d standing room(s) have no navmesh route: %s — a "
			+ "room the Hunt cannot enter is a safe room the design never "
			+ "agreed to") % [stranded.size(), ", ".join(stranded)])

	# ─ 6d. a ledge is a vantage, not a safe room ─
	#
	# `TEC-008` §3.3.1 puts the ramp at 32° precisely so the navmesh will bake
	# it and the Hunt can follow you up. If a deck ever ends up an island, the
	# player has been handed somewhere to stand where nothing can reach them —
	# and `DES-005`'s pressure is the whole product, so that is a design
	# failure, not a cosmetic one. It is also exactly what a crawl *is allowed*
	# to be, which is why the two are asserted in opposite directions.
	var decks: Array[Node3D] = []
	for child: Node in navroot.get_children():
		if child.name.begins_with("ledge_floor"):
			decks.append(child as Node3D)
	var marooned: PackedStringArray = PackedStringArray()
	for deck: Node3D in decks:
		var stand: Vector3 = deck.position + Vector3(0.0, 0.4, 0.0)
		var climb: PackedVector3Array = NavigationServer3D.map_get_path(
			map, start_at, stand, true)
		if not climb.is_empty() \
				and climb[climb.size() - 1].distance_to(stand) <= NAV_REACH:
			continue
		# The deck's own size is reported, because the two ways this fails look
		# identical from a route that did not arrive: a deck too small for
		# Recast to keep as a region, and a deck the ramp never joined.
		var box := (deck.mesh as BoxMesh).size
		var near: Vector3 = NavigationServer3D.map_get_closest_point(map, stand)
		marooned.append("%.1f x %.1f m deck, nearest mesh %.2f m away"
			% [box.x, box.z, near.distance_to(stand)])
	print("[build] ledges      %d of %d reachable from the entrance"
		% [decks.size() - marooned.size(), decks.size()])
	if not marooned.is_empty():
		problems.append(("%d of %d ledge(s) cannot be walked to (%s) — a "
			+ "vantage nothing can climb is a safe room, and the Delvings do "
			+ "not have safe rooms")
			% [marooned.size(), decks.size(), "; ".join(marooned)])

	# ─ 6e. everything the level will place stands somewhere it can be placed ─
	#
	# `FloorAnchors` turns the mission into positions: where the party arrives,
	# where the Shaft is, where the Hunt begins, where a post goes, where the
	# coin is. Every one is a point a body or an item gets spawned at, and a
	# point inside masonry **does not error** — it drops the thing out of the
	# world or wedges it, and whatever measures that thing afterwards then
	# reports confident nonsense. `--walk-probe` spent a run blaming the level
	# for a body it had itself dropped inside a barricade (ADR-144), and the
	# authored floor had twelve hand-checked coordinates; a generated one has
	# as many as the graph has rooms.
	#
	# Asked of the **navmesh**, not of the geometry: "inside a room" is not the
	# claim, "somewhere a body can stand and walk away from" is.
	var anchors: FloorAnchors = FloorAnchors.of(bake_plan, bake, BAKE_SEED, 0)
	var placed: Array[Vector3] = anchors.spawns(4)
	placed.append(anchors.shaft())
	placed.append(anchors.prize())
	placed.append(anchors.hunter())
	placed.append_array(anchors.posts())
	for spot: Dictionary in anchors.loot():
		placed.append(spot["at"])
	var adrift: int = 0
	var worst_at: float = 0.0
	for at: Vector3 in placed:
		var off: float = NavigationServer3D.map_get_closest_point(
			map, at).distance_to(at)
		if off > NAV_REACH:
			adrift += 1
		worst_at = maxf(worst_at, off)
	# The three lists a level reads but does not spawn bodies at: a light per
	# doorway (`ART-005`'s pale light is the way through), a silhouette per
	# great room (Lynch's landmarks), and the bounds the Clamor field covers.
	# Each is checked against the thing it is derived from rather than against
	# itself — a light list that had quietly become empty would otherwise leave
	# a floor unlit and every row here passing.
	var doorways: Array[Vector2i] = []
	var halls: int = 0
	for node: int in bake.size():
		for cell: Vector2i in bake_plan.doors_of(node):
			if not doorways.has(cell):
				doorways.append(cell)
		var module: RoomModule = RoomCatalogue.by_id(bake_plan.module_of(node))
		if module != null and module.volume == RoomModule.Volume.GREAT:
			halls += 1
	var lit: int = anchors.door_lights().size()
	var marks: int = anchors.landmarks().size()
	var covers: AABB = anchors.field()
	var outside: int = 0
	for node: int in bake.size():
		var mid: Vector3 = anchors.centre_of(node)
		if not covers.has_point(Vector3(mid.x, covers.position.y, mid.z)):
			outside += 1
	print("[build] fittings    %d light(s) for %d doorway(s), %d landmark(s) "
		% [lit, doorways.size(), marks]
		+ "for %d great room(s), %d room(s) outside the clamor field"
		% [halls, outside])
	if lit != doorways.size():
		problems.append(("%d door light(s) for %d doorway(s) — a doorway with "
			+ "no light is a way out the room does not show, which `M2-T13` "
			+ "found is the difference between a floor you can read and six "
			+ "identically lit boxes") % [lit, doorways.size()])
	if marks != halls:
		problems.append("%d landmark(s) for %d great room(s)" % [marks, halls])
	if outside > 0:
		problems.append(("%d room(s) sit outside the clamor field — noise made "
			+ "in them lands nowhere and the Ear reports silence") % outside)

	print("[build] anchors     %d placement(s), %d off the mesh, worst %.2f m"
		% [placed.size(), adrift, worst_at])
	if adrift > 0:
		problems.append(("%d of %d placements are off the navmesh (worst "
			+ "%.2f m) — a spawn point inside masonry drops what it spawns out "
			+ "of the world and every measurement of it afterwards is fiction")
			% [adrift, placed.size(), worst_at])

	var to_at: Vector3 = _plan_centre(bake_plan, bake.node_with(
		MissionGraph.Role.SHAFT))
	var route: PackedVector3Array = NavigationServer3D.map_get_path(
		map, start_at, to_at, true)
	var arrives: bool = route.size() > 0 \
		and route[route.size() - 1].distance_to(to_at) < NAV_REACH
	print("[build] the walk    entrance to Shaft: %s"
		% ("%d hop(s)" % route.size() if arrives else "NO ROUTE"))
	if not arrives:
		problems.append("nothing that walks can get from the entrance to the "
			+ "Shaft on the generated floor")

	_report(problems, "build")


## **A generated floor, stood up as a level somebody could descend into**
## (`M4-T01`, ADR-183).
##
## `--build-probe` proves the geometry is right and the navmesh covers it. This
## proves the *level* arrives: that the same `_ready` which raises the Deep
## raises the Delvings, and that everything a run needs is standing in it.
##
## Every row here is something a player would notice missing in the first ten
## seconds, and none of it is visible to any check that reads the plan — a floor
## can be perfectly generated, perfectly walkable, and arrive with no way out,
## no light and nothing on it.
func _delvings_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	# The level has spawned its actors by now; give the deferred work a frame.
	for i: int in 8:
		await get_tree().physics_frame

	if not (_floor is DelvingsFloor):
		problems.append("the level is standing on the Deep — `--delvings-probe` "
			+ "measured the authored floor and would have passed on it")
		_report(problems, "delvings")
		return

	var lights: int = get_tree().get_nodes_in_group(DOOR_LIGHT_GROUP).size()
	var raised: int = _world.get_child_count()
	print("[delvings] built      %d node(s) of geometry, %d door light(s)"
		% [raised, lights])
	if raised < 100:
		problems.append("the floor raised %d nodes — a generated floor is "
			% raised + "hundreds of slabs, so this one is barely there")
	if lights == 0:
		problems.append("no door light on a generated floor — `ART-005`'s pale "
			+ "light is how a room shows its own exits, and without it the "
			+ "floor is `M2-T13`'s six identically lit boxes again")

	# The way out, the Hunt, and something to carry: the three things that make
	# a floor a run rather than a diorama.
	var out_at: Vector3 = _floor.shaft()
	print("[delvings] fittings   shaft %s, hunter %s, %d item(s), %d enemy/ies"
		% ["yes" if _shaft != null else "MISSING",
			"yes" if _hunter != null else "MISSING",
			_loot_on_the_floor(),
			get_tree().get_nodes_in_group("enemies").size()])
	if _shaft == null or _shaft.position.distance_to(out_at) > 0.01:
		problems.append("the Shaft is not where the floor put it — `DES-005` "
			+ "says the way out's location is known, and a run with no exit is "
			+ "not a run")
	if _hunter == null:
		problems.append("no Hunter on the floor — `DES-017`'s pressure is the "
			+ "product, and a generated floor without it is a walk")
	if _loot_on_the_floor() == 0:
		problems.append("nothing to pick up — `DES-008`'s tug-of-war needs "
			+ "something on the floor to be greedy about")

	# And the party is standing on the floor rather than inside it.
	var adrift: int = 0
	for body: Player in _session.players():
		if absf(body.global_position.y) > 4.0:
			adrift += 1
	print("[delvings] the party  %d body/ies, %d off the floor"
		% [_session.players().size(), adrift])
	if _session.players().is_empty():
		problems.append("nobody spawned on the generated floor")
	if adrift > 0:
		problems.append(("%d body/ies are not on the floor — a spawn point "
			+ "inside masonry drops what it spawns out of the world") % adrift)

	_report(problems, "delvings")


## The middle of a room, in metres, on the floor.
func _plan_centre(plan: FloorPlan, node: int) -> Vector3:
	var rect: Rect2i = plan.rect_of(node)
	return FloorBuilder.at(rect.position) + Vector3(
		rect.size.x * FloorBuilder.CELL * 0.5, 0.0,
		rect.size.y * FloorBuilder.CELL * 0.5)


func _plan_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var trials: int = 120
	var modules: Array[RoomModule] = RoomCatalogue.all()
	var calamities: Array[CalamityResource] = CalamityCatalogue.all()
	var kinds: PackedStringArray = _prize_kinds(modules)

	# ─ 1. the corpus loads at all ─
	#
	# ADR-086: the repo holds `.tres` and a shipped build does not. A catalogue
	# that finds nothing does not crash — it generates floors with no rooms in
	# them and passes every other row here.
	print("[plan] corpus      %d module(s)" % modules.size())
	if modules.size() < 8:
		problems.append(("only %d room module(s) loaded — a generator with no "
			+ "vocabulary emits empty floors and passes every other check")
			% modules.size())
		_report(problems, "plan")
		return

	var ids: Dictionary = {}
	for module: RoomModule in modules:
		if ids.has(String(module.id)):
			problems.append("two modules answer to `%s`" % module.id)
		ids[String(module.id)] = true

	# ─ 1a. the history rolls, reaches the architecture, and reads its seed ─
	#
	# `DES-015` Layer 2 is only worth its "absurd return on investment" if the
	# roll actually changes what gets built. A Calamity that rolls and leaves
	# the floor identical is set dressing, which is the failure the document
	# opens by diagnosing in Dark and Darker.
	print("[plan] calamities  %d authored, %d prize kind(s)" % [
		calamities.size(), kinds.size()])
	if calamities.size() < 3 or kinds.is_empty():
		problems.append(("%d Calamity/Calamities and %d prize kind(s) — an "
			+ "expedition that always has the same history has none")
			% [calamities.size(), kinds.size()])
		_report(problems, "plan")
		return

	var rolled: Dictionary = {}
	for i: int in trials:
		rolled[ExpeditionHistory.roll(31000 + i, calamities, kinds).digest()] = true
	print("[plan] history     %d distinct history/histories from %d seeds" % [
		rolled.size(), trials])
	if rolled.size() < mini(trials / 4, calamities.size()):
		problems.append(("%d seeds rolled only %d histories — a roll that "
			+ "ignores its seed is perfectly deterministic and changes nothing")
			% [trials, rolled.size()])

	# **The row that makes Layer 2 real rather than decorative.** One graph,
	# one placer seed, every Calamity in turn: the floors must differ. If they
	# do not, the history rolled and never reached the architecture, and every
	# other row here would still pass.
	var fixed_graph: MissionGraph = MissionGraph.build(8800, 0)
	var by_calamity: Dictionary = {}
	for calamity: CalamityResource in calamities:
		var forced := ExpeditionHistory.roll(0, [calamity], kinds)
		# `module_digest()`, not `digest()`: the full digest folds in the
		# history, so five Calamities would differ by their own names alone
		# and this row could never fail. Found by planting it.
		by_calamity[FloorPlan.build(fixed_graph, 8800, 0, modules,
			forced).module_digest()] = true
	print("[plan] bias        %d distinct floor(s) from %d Calamities on one graph"
		% [by_calamity.size(), calamities.size()])
	if by_calamity.size() < calamities.size():
		problems.append(("%d Calamities produced only %d distinct floors from "
			+ "one graph — the history is not reaching the architecture, which "
			+ "is the whole of `DES-015` Layer 2") % [
				calamities.size(), by_calamity.size()])

	# Every Calamity needs rooms that answer to it, or its bias is a no-op that
	# the row above would only catch by luck.
	var thin: PackedStringArray = PackedStringArray()
	for calamity: CalamityResource in calamities:
		var forced := ExpeditionHistory.roll(0, [calamity], kinds)
		var on_theme: int = 0
		for module: RoomModule in modules:
			if forced.favours(module):
				on_theme += 1
		if on_theme < 3:
			thin.append("%s has %d" % [calamity.id, on_theme])
	if not thin.is_empty():
		problems.append(("a Calamity needs rooms that answer to it: %s"
			% ", ".join(thin)))

	# ─ 1b. the corpus covers every demand the graph can make ─
	#
	# **The row that stops this being whack-a-mole.** A node's role and its link
	# count are properties of the topology, not of the art: several arms can
	# rejoin the spine at one node, so a Shaft can be a five-way junction. Each
	# time the corpus fell short the symptom was one unplaceable floor in a
	# hundred and the diagnosis took a probe run. This asserts the *coverage*
	# instead — every (role, links, held, depth) the generator emits has a room
	# it could be — so a corpus that falls behind the generator says so directly.
	# The Prize kind is part of the demand, because the history promises one and
	# the placer will not substitute another. Leaving it out let a `vault` node
	# with three corridors pass coverage and then fail placement — the exact
	# class of failure this row exists to make loud, hiding inside this row.
	var demands: Dictionary = {}
	for i: int in trials:
		for depth: int in 3:
			var graph: MissionGraph = MissionGraph.build(74000 + i, depth)
			for node: int in graph.size():
				var role: int = graph._role[node]
				var shape: String = "%d/%d/%d/%d" % [role,
					graph.neighbours(node).size(),
					1 if graph.is_held(node) else 0, depth]
				if role == MissionGraph.Role.PRIZE:
					for kind: String in kinds:
						demands["%s/%s" % [shape, kind]] = true
				else:
					demands["%s/" % shape] = true
	var uncovered: PackedStringArray = PackedStringArray()
	var wants: Array = demands.keys()
	wants.sort()
	for want: String in wants:
		var bits: PackedStringArray = want.split("/")
		var served: bool = false
		for module: RoomModule in modules:
			if not module.fits(int(bits[0]), int(bits[1]), bits[2] == "1",
					int(bits[3])):
				continue
			if bits[4] != "" and String(module.prize_kind) != bits[4]:
				continue
			served = true
			break
		if not served:
			uncovered.append("role %s/%s link(s)%s on floor %s%s" % [
				bits[0], bits[1], ", held" if bits[2] == "1" else "", bits[3],
				", %s" % bits[4] if bits[4] != "" else ""])
	print("[plan] coverage    %d demand(s), %d unserved" % [
		wants.size(), uncovered.size()])
	if not uncovered.is_empty():
		problems.append(("the graph asks for %d room(s) the corpus cannot "
			+ "provide: %s") % [uncovered.size(), ", ".join(uncovered)])

	# ─ 2. every floor the generator can emit lays out, and stays the graph ─
	var broken: int = 0
	var first_fault: String = ""
	var rerolled: int = 0
	for i: int in trials:
		for depth: int in 3:
			var graph: MissionGraph = MissionGraph.build(41000 + i, depth)
			var plan: FloorPlan = FloorPlan.build(graph, 41000 + i, depth, modules,
				ExpeditionHistory.roll(41000 + i, calamities, kinds))
			rerolled += plan.rolls()
			var faults: PackedStringArray = plan.problems()
			if faults.is_empty():
				continue
			broken += 1
			if first_fault == "":
				first_fault = "seed %d floor %d: %s" % [
					41000 + i, depth, " · ".join(faults)]
	print("[plan] validity    %d floor(s) planned, %d invalid, %d re-roll(s)" % [
		trials * 3, broken, rerolled])
	if broken > 0:
		problems.append(("%d of %d planned floors failed `DES-015` step 8 — "
			+ "first: %s") % [broken, trials * 3, first_fault])

	# ─ 2a. the corridors bend out of sight ─
	#
	# `TEC-008` §3.3.2, for Kaplan & Kaplan's **mystery**: a passage bending out
	# of sight promises more if you move deeper, and a straight tunnel between
	# two rectangles shows the whole proposition from the doorway.
	#
	# **Bounded on the tail, not on the median, and not on whether a corridor
	# bends at all.** Both of the obvious statistics are useless here, and
	# finding that out is what ADR-180 cost:
	#
	# - *"runs dead straight end to end"* was the first bound. It reads as the
	#   right question and it is a function of corridor **length**: once the
	#   lattice tightened, corridors got short, the share went 13% → 61%, and a
	#   4-cell dead-straight corridor is 8 m and entirely fine. The row would
	#   have failed a floor that had just got better.
	# - the **median** longest run has no power at all at this lattice: 5 cells
	#   with the dog-leg and 5 without it.
	#
	# What separates them is the upper tail. The device jogs when a run passes
	# `DOGLEG_RUN`, so the longest run it permits is `DOGLEG_RUN + 1` cells;
	# anything past that is a corridor the chicane had no room to bend. Measured
	# over 4780 routes: **8% over the limit with the dog-leg, 34% without**, and
	# p95 of 9 cells against 16.
	var routes: int = 0
	var arrow: int = 0
	var bends: int = 0
	var over: int = 0
	var limit: int = FloorPlan.DOGLEG_RUN + 1
	var sight: PackedInt32Array = PackedInt32Array()
	var behind_a_crawl: int = 0
	var crawl_rooms: int = 0
	var no_held: int = 0
	var no_bypass: int = 0
	var cramped: int = 0
	for i: int in trials:
		for depth: int in 3:
			var seed_at: int = 60000 + i
			var g2: MissionGraph = MissionGraph.build(seed_at, depth)
			var p2: FloorPlan = FloorPlan.build(g2, seed_at, depth, modules,
				ExpeditionHistory.roll(seed_at, calamities, kinds))
			if not p2.problems().is_empty():
				continue

			# **No room may sit behind the crawls.** A crawl is 1.4 m and the
			# agent stands 1.8 m, so the Hunt cannot follow you through one —
			# and a standing room whose every approach is a crawl is therefore a
			# room nothing can ever reach. `DES-005` does not allow a safe room,
			# and this is the one way to build one without any geometry being
			# wrong, which is why no other row can see it.
			var crawl: Dictionary = {}
			for node: int in g2.size():
				var m2: RoomModule = RoomCatalogue.by_id(p2.module_of(node))
				if m2 != null and m2.volume == RoomModule.Volume.CRAWL:
					crawl[node] = true
			crawl_rooms += crawl.size()
			var start2: int = g2.node_with(MissionGraph.Role.ENTRANCE)
			var seen2: Dictionary = {start2: true}
			var queue2: Array[int] = [start2]
			while not queue2.is_empty():
				var at2: int = queue2.pop_front()
				for next2: int in g2.neighbours(at2):
					if seen2.has(next2) or crawl.has(next2):
						continue
					seen2[next2] = true
					queue2.append(next2)
			for node: int in g2.size():
				if not crawl.has(node) and not seen2.has(node):
					behind_a_crawl += 1

			# **Both halves of the bargain, on every floor.** ADR-032's finding is
			# that a cycle only means something if its two arms pay differently —
			# the held one short and guarded, the bypass long and poor. A floor
			# with no held room has nothing to be afraid of and a floor with no
			# unheld room has no choice to offer, and either way the cycle the
			# graph went to such trouble to build is decoration.
			var anchor := FloorAnchors.of(p2, g2, seed_at, depth)
			var held_rooms: int = 0
			var open_rooms: int = 0
			for spot: Dictionary in anchor.loot():
				if spot["tag"] == &"bypass":
					open_rooms += 1
				elif spot["tag"] == &"held":
					held_rooms += 1
			no_held += 1 if held_rooms == 0 else 0
			no_bypass += 1 if open_rooms == 0 else 0
			# And a four-stack has to fit inside its own front door. Measured on
			# the points that come **out**, not on the room they came from: the
			# room is a proxy, and the property is that no two players are spawned
			# inside one another.
			var four: Array[Vector3] = anchor.spawns(4)
			var touching: bool = false
			for a: int in four.size():
				for b: int in range(a + 1, four.size()):
					touching = touching \
						or four[a].distance_to(four[b]) < BODY_RADIUS * 2.0
			cramped += 1 if touching else 0

			for route: int in p2.routes():
				var path: Array[Vector2i] = p2.path_of(route)
				if path.size() < 2:
					continue
				routes += 1
				var turns: int = 0
				var run: int = 1
				var best: int = 1
				for k: int in range(1, path.size()):
					var step: Vector2i = path[k] - path[k - 1]
					if k >= 2 and step != path[k - 1] - path[k - 2]:
						turns += 1
						run = 1
					else:
						run += 1
					best = maxi(best, run)
				bends += turns
				arrow += 1 if turns == 0 else 0
				over += 1 if best > limit else 0
				sight.append(best)
	sight.sort()
	var p95: int = sight[int(sight.size() * 0.95)] if not sight.is_empty() else 0
	var past: float = 100.0 * over / maxi(routes, 1)
	print("[plan] sightlines  %d route(s), %.0f%% over %d cells, p95 %d cell(s) "
		% [routes, past, limit, p95]
		+ "(%d m), worst %d — %.0f%% straight, %.1f bend(s) each"
		% [p95 * 2, sight[sight.size() - 1] if not sight.is_empty() else 0,
			100.0 * arrow / maxi(routes, 1), float(bends) / maxi(routes, 1)])
	if past > 15.0:
		problems.append(("%.0f%% of corridors hold a straight run past %d cells "
			+ "(%d m) — the dog-leg is not firing, and a tunnel you can see the "
			+ "whole of from the doorway is the proposition given away")
			% [past, limit, limit * 2])
	if p95 > FloorPlan.DOGLEG_RUN * 3:
		problems.append(("one corridor in twenty shows %d cells (%d m) at once "
			+ "against a %d-cell limit — the tail is back, which is where the "
			+ "sightline problem always lived") % [p95, p95 * 2, limit])

	print("[plan] crawls      %d crawl(s) placed, %d standing room(s) behind "
		% [crawl_rooms, behind_a_crawl] + "them")
	if behind_a_crawl > 0:
		problems.append(("%d standing room(s) can only be reached through a "
			+ "crawl — the Hunt stands 1.8 m and a crawl is 1.4 m, so those are "
			+ "safe rooms, and `DES-005` does not have safe rooms")
			% behind_a_crawl)
	if crawl_rooms == 0:
		problems.append("no floor placed a crawl at all — the rule that keeps "
			+ "a crawl off the only way in has swallowed the mechanic instead "
			+ "of shaping it, and `DES-009`'s crouch verb has nowhere to matter")

	# `no_held` is **reported, not asserted**. Only two of the five cycle types
	# hold a span at all (`DANGER_DETOUR` and `LOCK_AND_KEY`, ADR-171), so a
	# foldback or a shortcut floor having nothing held is the catalogue working,
	# not a fault — and a row asserting it would be inventing a promise the
	# design never made. It is printed because it is the number that decides
	# whether posts can be derived from held rooms alone, which is `M4-T02`'s
	# question and not this file's.
	print("[plan] anchors     %d floor(s) of %d with nothing held, %d with no "
		% [no_held, trials * 3, no_bypass]
		+ "bypass, %d that would spawn a party inside itself" % cramped)
	if no_bypass > 0:
		problems.append(("%d floor(s) have no unheld room — every payoff is "
			+ "behind a guard, so the bypass ADR-032 exists to protect is not "
			+ "on the floor") % no_bypass)
	if cramped > 0:
		problems.append(("%d floor(s) would spawn two of a four-stack inside "
			+ "each other — the shove that separates them is host-side, so it "
			+ "reads on a client as two peers disagreeing about where somebody "
			+ "is") % cramped)

	# ─ 3. same seed, same space; different seed, different space ─
	#
	# Both halves, for the reason ADR-169 gives: a placer that ignored its seed
	# would satisfy the first and be useless.
	var g: MissionGraph = MissionGraph.build(4242, 1)
	var lore := ExpeditionHistory.roll(4242, calamities, kinds)
	var once: String = FloorPlan.build(g, 4242, 1, modules, lore).digest()
	var twice: String = FloorPlan.build(g, 4242, 1, modules, lore).digest()
	print("[plan] same seed   %s" % ("identical" if once == twice else "DIVERGED"))
	if once != twice:
		problems.append("one seed laid out two different floors — `TEC-004` "
			+ "needs this bit-exact or two players disagree about a wall")

	var shapes: Dictionary = {}
	for i: int in trials:
		var gg: MissionGraph = MissionGraph.build(52000 + i, 0)
		shapes[FloorPlan.build(gg, 52000 + i, 0, modules,
		ExpeditionHistory.roll(52000 + i, calamities, kinds)).digest()] = true
	print("[plan] seed matters %d distinct space(s) from %d seeds" % [
		shapes.size(), trials])
	if shapes.size() < trials / 2:
		problems.append(("%d seeds produced only %d distinct spaces — a placer "
			+ "that ignores its seed passes every determinism check there is")
			% [trials, shapes.size()])

	# ─ 3b. the *placer* reads its seed, with the graph held still ─
	#
	# **The row above cannot make this claim, and it looked like it could.**
	# `seed matters` varies the run seed and watches the finished space change —
	# but the graph changes too, so a placer whose own stream were frozen would
	# still produce 115 distinct spaces from 120 seeds and sail through. That is
	# ADR-169's finding exactly, one layer down: a stage that ignores its seed is
	# perfectly deterministic and completely useless, and only an assertion that
	# holds everything else still can see it.
	#
	# So: one graph, many seeds, and the layouts must differ.
	var fixed: MissionGraph = MissionGraph.build(777, 0)
	var layouts: Dictionary = {}
	for i: int in 60:
		layouts[FloorPlan.build(fixed, 90000 + i, 0, modules,
			ExpeditionHistory.roll(777, calamities, kinds)).digest()] = true
	print("[plan] placer seed %d distinct layout(s) of one graph from 60 seeds"
		% layouts.size())
	if layouts.size() < 30:
		problems.append(("one graph laid out only %d different ways in 60 seeds "
			+ "— the placer is not reading its own stream, which every other "
			+ "determinism row here would happily pass") % layouts.size())

	# ─ 4. the vocabulary is used, not just present ─
	#
	# A module nothing ever picks is authored content that does not exist, and
	# it reads as alive to `check_dead.py` because the `.tres` is on disk.
	var used: Dictionary = {}
	for i: int in trials:
		for depth: int in 3:
			var gg: MissionGraph = MissionGraph.build(63000 + i, depth)
			var plan: FloorPlan = FloorPlan.build(gg, 63000 + i, depth, modules,
				ExpeditionHistory.roll(63000 + i, calamities, kinds))
			for node: int in gg.size():
				used[String(plan.module_of(node))] = true
	used.erase("")
	print("[plan] vocabulary  %d of %d module(s) placed" % [
		used.size(), modules.size()])
	if used.size() != modules.size():
		var idle: PackedStringArray = PackedStringArray()
		for module: RoomModule in modules:
			if not used.has(String(module.id)):
				idle.append(String(module.id))
		problems.append(("%d module(s) were never placed in %d floors: %s — "
			+ "authored content nothing selects is content that does not exist")
			% [idle.size(), trials * 3, ", ".join(idle)])

	# ─ 5. one floor, described, so a person can read what came out ─
	var shown: MissionGraph = MissionGraph.build(31337, 1)
	var lore2 := ExpeditionHistory.roll(31337, calamities, kinds)
	var plan: FloorPlan = FloorPlan.build(shown, 31337, 1, modules, lore2)
	print("[plan] the floor   %s under %s: %d room(s), %d corridor cell(s), %d link(s)"
		% [MissionGraph.cycle_name(shown.cycle()), lore2.digest(), plan.seated(),
			plan.corridor_cells(), plan.realised_links().size()])

	_report(problems, "plan")


func _graph_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var trials: int = 400

	# ─ 0. the seed mix is ours, and it is pinned ─
	#
	# `TEC-001` calls the run seed's shareability non-negotiable — it goes on
	# the death screen and into bug reports — so a seed has to name the same
	# floor after an engine upgrade. `hash()` was stable within a build, which
	# is all a desync needs, but it is not a contract across versions, so the
	# mix is SplitMix64 we own (`TEC-007` §5.3 rule 7, ADR-170).
	#
	# A known answer, not a property: this asserts the arithmetic still lands
	# on the number it landed on the day it was written. If GDScript ever stops
	# wrapping `int` multiplication at 64 bits, or the shift stops zero-filling,
	# every seed anybody has written down changes meaning and this row is the
	# only thing that would say so.
	const SEED_MIX_KNOWN_ANSWER: int = 4278115658868624668
	var pinned: int = MissionGraph.stage_seed(12345, 0)
	print("[graph] seed mix    stage_seed(12345, 0) = %d" % pinned)
	if pinned != SEED_MIX_KNOWN_ANSWER:
		problems.append(("the seed mix returned %d where it has always returned "
			+ "%d — every logged run seed now names a different floor")
			% [pinned, SEED_MIX_KNOWN_ANSWER])

	# ─ 1. no floor the generator can emit is invalid ─
	var broken: int = 0
	var first_fault: String = ""
	for i: int in trials:
		for depth: int in 3:
			var graph: MissionGraph = MissionGraph.build(9000 + i, depth)
			var faults: PackedStringArray = graph.problems()
			if faults.is_empty():
				continue
			broken += 1
			if first_fault == "":
				# **Every fault on that floor, not just the first.** Reporting
				# `faults[0]` hid the rest, and a floor is usually wrong in
				# more than one way at once — the fix for the loudest fault
				# then ships beside the quiet one it was masking. Found while
				# planting the key-behind-its-own-door row, which fired
				# correctly and reported a different fault's name.
				first_fault = "seed %d floor %d: %s" % [
					9000 + i, depth, " · ".join(faults)]
	print("[graph] validity     %d floor(s) built, %d invalid" % [
		trials * 3, broken])
	if broken > 0:
		problems.append(("%d of %d generated floors failed `DES-015` step 8 — "
			+ "first: %s. A generator without a validation pass ships "
			+ "soft-locks, and one whose validation fails ships them knowingly")
			% [broken, trials * 3, first_fault])

	# ─ 2. same seed, same graph ─
	var twice_a: String = MissionGraph.build(4242, 1).digest()
	var twice_b: String = MissionGraph.build(4242, 1).digest()
	print("[graph] same seed    %s" % ("identical" if twice_a == twice_b
		else "DIVERGED"))
	if twice_a != twice_b:
		problems.append("one seed built two different graphs — `TEC-004` "
			+ "makes this bit-exact across machines, and a host and client "
			+ "disagreeing about the floor is the most expensive bug here")

	# ─ 3. **different seed, different graph** ─
	#
	# The assertion `check_determinism.py` could never make, because until now
	# there was nothing that read a seed. A generator that ignores its input is
	# perfectly deterministic and completely useless, and every existing
	# determinism check in this project would pass it.
	var distinct: Dictionary = {}
	for i: int in trials:
		distinct[MissionGraph.build(70000 + i, 0).digest()] = true
	print("[graph] seed matters %d distinct graph(s) from %d seeds" % [
		distinct.size(), trials])
	if distinct.size() < trials / 4:
		problems.append(("%d seeds produced only %d distinct floors — a "
			+ "generator that ignores its seed passes every determinism check "
			+ "in this project, which is exactly why this row exists")
			% [trials, distinct.size()])

	# ─ 4. three floors of one expedition are three floors ─
	var by_depth: Dictionary = {}
	for depth: int in 3:
		by_depth[MissionGraph.build(555, depth).digest()] = true
	print("[graph] three floors %d distinct" % by_depth.size())
	if by_depth.size() != 3:
		problems.append(("one expedition produced %d distinct floors rather "
			+ "than 3 — ADR-015 wants three, and descending into the same "
			+ "room twice is the flatness `DES-015` opens by diagnosing")
			% by_depth.size())

	# ─ 4b. the catalogue is used, and no one shape dominates ─
	#
	# **The row the old variety check could not make.** `seed matters` counts
	# distinct digests, and 308 digests from 400 seeds read as healthy while
	# every one of them was the same *kind* of floor — a spine, one arm, the
	# Prize inside it — because `build()` had no branch that could emit a
	# second topology (`TEC-007` §4, ADR-170). Counting shapes instead of
	# fingerprints is what makes the catalogue assertable: a type that stops
	# being generated, or one that quietly swallows the floor space, both show
	# up here and neither shows up above.
	var shapes: Dictionary = {}
	for i: int in trials:
		for depth: int in 3:
			var kind: int = MissionGraph.build(80000 + i, depth).cycle()
			shapes[kind] = int(shapes.get(kind, 0)) + 1
	var seen_shapes: Array = shapes.keys()
	seen_shapes.sort()
	var shape_names := PackedStringArray()
	for kind: int in seen_shapes:
		shape_names.append("%s×%d" % [MissionGraph.cycle_name(kind), shapes[kind]])
	print("[graph] cycle types %d of %d: %s" % [
		seen_shapes.size(), MissionGraph.CYCLE_NAMES.size(),
		", ".join(shape_names)])
	if seen_shapes.size() != MissionGraph.CYCLE_NAMES.size():
		problems.append(("only %d of %d cycle types were generated in %d floors "
			+ "— a type nothing emits is a type that does not exist, and the "
			+ "catalogue is the whole of ADR-170")
			% [seen_shapes.size(), MissionGraph.CYCLE_NAMES.size(), trials * 3])
	var floors: int = trials * 3
	for kind: int in seen_shapes:
		if int(shapes[kind]) * 2 > floors:
			problems.append(("`%s` is %d of %d floors — one shape past half the "
				+ "floor space is the single-topology failure ADR-170 was "
				+ "written about, wearing a catalogue")
				% [MissionGraph.cycle_name(kind), shapes[kind], floors])

	# ─ 5. the cycle is real, and the bypass avoids what it claims to ─
	var sample: MissionGraph = MissionGraph.build(31337, 0)
	var entrance: int = sample.node_with(MissionGraph.Role.ENTRANCE)
	var shaft: int = sample.node_with(MissionGraph.Role.SHAFT)
	var held: PackedInt32Array = PackedInt32Array()
	for id: int in sample.size():
		if sample.is_held(id):
			held.append(id)
	var quiet: PackedInt32Array = sample.reachable(entrance, held)
	print("[graph] the loop     %d node(s), cycle=%s, bypass=%s, held=%d" % [
		sample.size(), sample.has_cycle(), sample.has_bypass(), held.size()])
	if not quiet.has(shaft):
		problems.append("the bypass does not reach the Shaft without crossing "
			+ "the held arm, so ADR-032's way round does not exist")
	for id: int in held:
		if quiet.has(id):
			problems.append(("the bypass route passes through held node %d, "
				+ "which means it is not a bypass") % id)
			break

	# ─ 6. the Prize is on the held arm, not the quiet one ─
	var prize: int = sample.node_with(MissionGraph.Role.PRIZE)
	print("[graph] the prize    node %d, held=%s" % [
		prize, sample.is_held(prize)])
	if not sample.is_held(prize):
		problems.append("the Prize sits outside the held arm, so the greedy "
			+ "line is also the safe one and the cycle costs nothing")

	_report(problems, "graph")


## Print the world fingerprint and quit (`M1-T07`). Two processes given the
## same seed must print the same line; `tools/check_determinism.py` runs them
## and compares. Waits for physics to settle first, because a body that has not
## finished resolving its first frame reports a position that is *nearly*
## right, which is exactly the kind of near-miss this must not tolerate.
## The run seed the host would have sent (`TEC-001`: visible and shareable).
## Zero when nobody passed one, which is a real seed and not a missing value.
var _run_seed: int = 0


## Every floor this seed generates, as rows for `WorldHash`.
##
## This is what makes `check_determinism.py` a **cross-process** guarantee
## rather than a check that a constant is constant. It ran against six literal
## `AABB`s from `M1-T07` until now, so it could prove the engine introduced no
## variance and could not prove anything at all about the generator.
func _generated_rows() -> PackedStringArray:
	var rows := PackedStringArray()
	var modules: Array[RoomModule] = RoomCatalogue.all()
	var history := ExpeditionHistory.roll(_run_seed, CalamityCatalogue.all(),
		_prize_kinds(modules))
	# The history is hashed as well as the floors. Two machines that disagreed
	# about what happened here would build rooms that differ before a single
	# co-ordinate did, and `DES-015` Layer 2 is what makes the expedition an
	# expedition rather than three floors.
	rows.append("history %s" % history.digest())
	for depth: int in 3:
		var graph: MissionGraph = MissionGraph.build(_run_seed, depth)
		rows.append("graph %d %s" % [depth, graph.digest()])
		rows.append("plan %d %s" % [depth,
			FloorPlan.build(graph, _run_seed, depth, modules, history).digest()])
	return rows


func _print_hash() -> void:
	for i: int in range(8):
		await get_tree().physics_frame
	var generated: PackedStringArray = _generated_rows()
	print("[hash] seed %d, entries %d, generated %d" % [
		_run_seed, WorldHash.entries(self).size(), generated.size()])
	print("[hash] %s" % WorldHash.digest(self, generated))
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
	# **Asked of the goal, not of the route** (ADR-142).
	#
	# This compared displacement against two reference directions 56° apart and
	# read the winner as evidence about what the Hunter *wants*. That inference
	# held only while it walked in straight lines. The moment it had a path, a
	# waypoint a metre off the direct line flipped the comparison — and the row
	# failed on a change that never touched goal selection at all.
	#
	# The claim `TEC-001` actually makes is about the **goal**: it walks up the
	# clamor gradient and must never read a player transform. That goal is now
	# a public fact — `NavigationAgent3D.target_position` is where it is trying
	# to get to — so it can be asserted directly instead of inferred from which
	# way the body happened to drift in two and a half seconds.
	var nav := hunter.get_node_or_null("Nav") as NavigationAgent3D
	var goal: Vector3 = nav.target_position if nav != null else Vector3.ZERO
	var to_sound: float = goal.distance_to(noise_at)
	var to_hiding: float = goal.distance_to(hide_at)
	print("[hunt] chased noise  %+.2f m travelled toward the sound; goal is %.1f m "
		% [toward_noise, to_sound] + "from it and %.1f m from the player" % to_hiding)
	if nav == null:
		problems.append("the Hunter has no agent, so where it is trying to get "
			+ "to cannot be read and the row below is about the origin")
	elif to_sound >= to_hiding:
		problems.append(("the Hunter is heading for the player rather than for "
			+ "the noise — %.1f m from the sound against %.1f m from where they "
			+ "hid. It is reading a transform, and TEC-001 says it must not")
			% [to_sound, to_hiding])
	if toward_noise <= 0.0:
		problems.append(("the Hunter did not move toward the sound at all "
			+ "(%+.2f m) — wanting the right place and never setting off is the "
			+ "same to a player as ignoring the noise") % toward_noise)

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

	# **And it reads the path it carries** (ADR-142).
	#
	# `--nav-probe` asserts the Hunter *has* an agent; deleting the block in
	# `_walk` that consults it passed everything, which is ADR-098's question
	# arriving on the fix for ADR-098's question. An agent nothing reads is the
	# straight line with extra steps.
	#
	# `target_position` starts at the origin and is only ever written by that
	# block, so a non-zero value is proof it ran — and by this point in the
	# probe the Hunter has been chasing a thrown purse for seconds.
	var agent := hunter.get_node_or_null("Nav") as NavigationAgent3D
	var asked: bool = agent != null and agent.target_position != Vector3.ZERO
	print("[hunt] the path      agent=%s, target asked for=%s" % [agent != null, asked])
	if agent == null:
		problems.append("the Hunter has no navigation agent, so it walks "
			+ "straight at its goal and grinds along whatever is between")
	elif not asked:
		problems.append(("the Hunter never asked its agent for anything — it "
			+ "carries a `NavigationAgent3D` and steers straight past it, which "
			+ "is a path with extra steps and still a body stuck in a wall"))

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


## **What a generated floor actually looks like from eye height** (`M4-T01`,
## ADR-187).
##
## `--sight-shot` photographs the Deep from four hand-picked coordinates, which
## is exactly right for a floor somebody drew and useless for one nobody did.
## This asks the floor where to stand instead.
##
## The views are chosen against `TEC-008`'s own open question — *does a 2 m
## corridor read as tight?* — because tightness is what makes the Hunt work, and
## every geometry number in the generator is still ⟨tune⟩ and unfelt. Standing
## at the entrance looking in, and standing midway looking on, is the smallest
## pair that can answer it.
func _delvings_shot(path: String) -> void:
	var player: Player = _session.local_player()
	# Ink off, on `--sight-shot`'s reasoning: `ART-005` is a treatment on top of
	# the lighting, and what is being judged here is the space.
	player.show_ink(false)
	# **Stand only where the floor put something** (ADR-187).
	#
	# The first draft stood at straight-line lerps between anchors — the midpoint
	# of spawn→Shaft, a step back from the Prize — and photographed **solid rock
	# three times out of four**, because a cyclic layout with dog-legs has no
	# straight line between any two of its anchors. That looked exactly like a
	# broken floor and was a broken measurement: `M3-T22`'s lesson, that a new
	# probe's first finding is usually about the probe.
	#
	# Every position below is an anchor the generator chose, so the camera is in
	# open space by construction, and every view aims at a **door light** —
	# which is `M2-T13`'s lighting language, and the thing worth photographing:
	# a room showing its own way out.
	var from: Vector3 = _floor.spawns()[0]
	var views: Array = [
		["entrance", from, _floor.shaft()],
		["spawn_door", from, _nearest_door_light(from)],
		["shaft", _floor.shaft(), _nearest_door_light(_floor.shaft())],
		["prize", _floor.prize(), _nearest_door_light(_floor.prize())],
	]
	for view: Array in views:
		var at: Vector3 = (view[1] as Vector3) + Vector3(0.0, 0.1, 0.0)
		var look: Vector3 = view[2] as Vector3
		var d: Vector3 = (look - at)
		d.y = 0.0
		# Godot yaws about +Y and a body's forward is -Z, so a rotation of θ
		# points at (-sin θ, 0, -cos θ). Facing `d` is therefore
		# `atan2(-d.x, -d.z)` — worth writing down, because guessing the sign
		# here photographs the wall behind you and looks like a broken floor.
		var yaw: float = atan2(-d.x, -d.z) if d.length() > 0.01 else 0.0
		player.teleport(at, yaw)
		await _hold(0.35)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot: String = "%s_%s.png" % [path.trim_suffix(".png"), view[0]]
		get_viewport().get_texture().get_image().save_png(shot)
		print("[delvings] %-9s → %s" % [view[0], shot.get_file()])
	get_tree().quit()


## **How deep this level thinks it is, and what that makes the Shaft**
## (`M4-T01`, ADR-187).
##
## One owner for the derivation, because ADR-186 is about the Shaft's verb and
## its behaviour never disagreeing — and the first version of this had two
## owners and immediately proved why. `_build_shaft` set `leads_out` once, and
## `--descent-probe` moves the level to the bottom floor mid-run to measure the
## way out: it changed `_floor_index`, the Shaft did not hear about it, and the
## bottom floor went on descending. The sweep caught it; a second derivation
## inside the probe would have hidden it instead.
func _stand_on_floor(index: int) -> void:
	_floor_index = clampi(index, 0, RunFile.LAST_FLOOR)
	if _shaft != null:
		_shaft.leads_out = _floor_index >= RunFile.LAST_FLOOR


## **How dark is dark** (`M4-T13`, `ART-001`, `DES-018`) — the one question in
## this task a number cannot answer.
##
## The ambient energy sat at 0.34 since `M2-T13` with a comment promising it
## *"drops when the lantern lands"*, and `PRO-001` names lowering it as the
## point of the task. But `DES-018` gets a vote and *"the player cannot see"* is
## the one accessibility failure a lighting task can ship, so the floor under it
## is not zero and no argument settles where it is.
##
## So: **the same view, at four ambient values, with the shutter open and shut.**
## Eight images of one real floor, which is a decision somebody can make by
## looking. Standing at the Prize — a room the generator chose, and the place a
## player has the most reason to be looking around in the dark.
func _light_shot(path: String) -> void:
	var player: Player = _session.local_player()
	# Ink off, on `--sight-shot`'s reasoning: `ART-005` is a treatment over the
	# lighting, and what is being judged here is the lighting.
	player.show_ink(false)
	var lamp: ItemResource = ItemCatalogue.by_id(&"tol_horn_lantern")
	if lamp == null:
		printerr("[light] FAIL no lantern in the catalogue to photograph")
		get_tree().quit(1)
		return
	player.equipment.equip(ItemInstance.of(lamp, 0))

	# **Standing where the lamps do not reach, looking at one.** The first draft
	# stood at the Prize, which the generator tends to put near a doorway: the
	# lamp then dominated `Exposure` and the printed distance came out
	# *non-monotonic* across a sweep of the ambient — 9.7, 12.8, 12.8, 8.9 —
	# because it was reporting how close the body was to a lamp rather than how
	# dark the floor is. The number and the picture have to be about the same
	# thing or neither can be trusted.
	#
	# The composition is also the one the decision actually needs: unlit stone
	# in the foreground, a lit doorway in the distance. That is the frame that
	# answers *can I cross this floor with the shutter shut* — which is what
	# `DES-018` gets a vote on.
	var anchor: Vector3 = _away_from_the_lamps()
	var at: Vector3 = anchor + Vector3(0.0, 0.1, 0.0)
	var look: Vector3 = _nearest_door_light(anchor)
	var d: Vector3 = look - at
	d.y = 0.0
	var yaw: float = atan2(-d.x, -d.z) if d.length() > 0.01 else 0.0

	# **Both baselines captured before anything moves.** The loop mutates
	# `exposure_ambient`, and the first version derived each step from the
	# *current* value rather than from the starting one — so the sweep
	# compounded, 0.15 became 0.43 became 0.71, and every row after the first
	# reported a floor brighter than the one it had just photographed. The
	# numbers looked plausible and were wrong, which is `TEC-007` §1's rule
	# about assertions built from convenient existing values, arriving in a
	# measurement instead of an assertion.
	var base_energy: float = Config.tuning.floor_ambient_energy
	var base_exposure: float = Config.tuning.exposure_ambient

	# 0.34 first, deliberately: the top row is what the floor looked like
	# before this task, so every image below is read against the build it
	# replaces rather than against memory.
	for ambient: float in [0.34, 0.20, 0.12, 0.06]:
		_environment.ambient_light_energy = ambient
		# **And the exposure floor moves with it.** They are one fact seen two
		# ways — what your eye gets and what an enemy gets — and sweeping the
		# first while the second stood still would photograph a floor going
		# dark beside a number saying it had not.
		Config.tuning.exposure_ambient = clampf(
			base_exposure * ambient / base_energy, 0.0, 1.0)
		for burning: bool in [false, true]:
			# **Teleported for every single frame.** The first draft placed the
			# body once and let the loop run: it drifted toward a doorway lamp
			# between exposures, so the 0.12 image came out *brighter* than the
			# 0.34 one and the sweep measured where the body wandered rather
			# than how dark the floor is. `M3-T22`'s rule again — a new probe's
			# first finding is usually about the probe.
			player.teleport(at, yaw)
			player.lit = burning
			await _hold(0.3)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var shot: String = "%s_%03d_%s.png" % [path.trim_suffix(".png"),
				roundi(ambient * 100.0), "lit" if burning else "shut"]
			get_viewport().get_texture().get_image().save_png(shot)
			print("[light] ambient %.2f  %-4s → %s  (seen from %.1f m)" % [
				ambient, "lit" if burning else "shut", shot.get_file(),
				player.exposure.seen_from()])
	Config.tuning.floor_ambient_energy = base_energy
	Config.tuning.exposure_ambient = base_exposure
	get_tree().quit()


## The doorway nearest a point, for `--delvings-shot` to aim at. Falls back to
## the Shaft, so a floor with no door lights still photographs something rather
## than aiming at the origin.
func _nearest_door_light(from: Vector3) -> Vector3:
	var best: Vector3 = _floor.shaft()
	var closest: float = INF
	for at: Vector3 in _floor.door_lights():
		var d: float = from.distance_to(at)
		if d > 1.0 and d < closest:
			closest = d
			best = at
	return best


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
## Was the delivered ember still in the rescuer's bag at the instant the rescue
## was announced (`M3-T33`)? Sampled there because it is the only moment it can
## be: `_on_extracted` consumes the token, marks the body out, and resolves the
## run in one call stack, and a probe looking afterwards is looking past
## `_reset_floor` emptying every bag. The first draft of that row did exactly
## that and could not fail.
var _token_survived: bool = false


func _on_probe_extracted(_player: Player, tribute: int) -> void:
	_extracted_tribute = tribute


func _on_probe_rescued(saved_peer: int, by: Player) -> void:
	_rescued_peer = saved_peer
	_token_survived = by.inventory.embers().has(saved_peer)


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

	# ─ 8. **and the life it saves actually survives** (`M3-T33`, ADR-154) ─
	#
	# Row 6 above has asserted since `M2` that the rescue is *reported*. It was
	# never anything else: `rescued` was connected by `_on_probe_rescued` and by
	# nothing in the game, so the signal this probe watched was the whole of the
	# feature. `_end_the_run` read `body.spent` and wiped the rescued player
	# anyway — the rescuer paid weight, noise and a worse walk home, and the
	# person they saved lost their tree, their stash and their rank regardless.
	#
	# A second body, because a rescue needs somebody to do it. `GameState` is
	# this process's and belongs to the **host** body, so the host is the one
	# who has to be saved for the row to be about a real profile.
	#
	# **Put on the Shaft through the wire, not through a transform.** `teleport`
	# asks the owning peer to move itself and this one's owner is a number
	# rather than a process, so it prints and declines. Setting `global_position`
	# does not stick either: a body nobody drives is eased toward `net_position`
	# every frame, and that starts at the origin — which is where the first
	# draft of this row found its helper standing, 29 m from the exit it was
	# supposed to be climbing.
	var helper: Player = _session.spawn_player(TEAMMATE_PEER, SHAFT_AT)
	await _hold(0.4)
	if helper != null:
		helper.net_position = SHAFT_AT
		helper.global_position = SHAFT_AT
		await _hold(0.6)
	if helper == null:
		problems.append("could not spawn a second body, so nothing can carry "
			+ "an ember out and DES-012's whole rescue is unmeasurable")
		_report(problems, "ember")
		return
	player.restore_for_descent()
	player.teleport(SHAFT_AT + Vector3(4.0, 0.1, 0.0), 0.0)
	await _hold(0.4)
	# A life worth keeping.
	GameState.class_id = &"huskarl"
	GameState.taken.clear()
	GameState.taken.append(&"hrd_ballast")
	GameState.stash.clear()
	GameState.stash.append(ItemInstance.of(
		ItemCatalogue.by_id(&"glt_hoard_coin"), 1))
	var rank_before: int = GameState.pact_rank
	var floor_before_rescue: int = _descent

	# The host goes out, so its ember is on the floor for the helper.
	player.health.apply_damage(player.health.maximum * 2.0)
	await _hold(0.2)
	player.bleeding = 0.02
	await _hold(0.6)
	var left_behind: WorldItem = null
	for node: Node in get_tree().get_nodes_in_group(WorldItem.GROUP):
		var found := node as WorldItem
		if found != null and found.bound() == owner_peer:
			left_behind = found
	print("[ember] borne out   spent=%s, ember on the floor=%s" % [
		player.spent, left_behind != null])
	if not player.spent or left_behind == null:
		problems.append("the host did not go out leaving an ember, so the "
			+ "rescue below is about nothing")
		_report(problems, "ember")
		return

	# **Into the helper's bag directly**, the way row 7 arranges its own tag.
	# Row 6 above already asserts that an ember is picked up off the floor and
	# what that costs; the subject here is what happens when a bag holding one
	# reaches an exit, and driving the pickup as well would only add a
	# proximity failure to a row that is not about proximity.
	left_behind.queue_free()
	var token: ItemInstance = helper.inventory.add(ItemCatalogue.by_id(&"con_ember"))
	if token == null:
		problems.append("no room in the helper's bag for an ember")
		_report(problems, "ember")
		return
	token.bound_to = owner_peer
	var carrying: Array[int] = helper.inventory.embers()
	await _hold(0.3)
	_token_survived = false
	var climbing: bool = helper.reach_for_shaft_now()
	print("[ember] the climb   helper %.1f m from the Shaft, channelling=%s" % [
		helper.global_position.distance_to(_shaft.global_position), climbing])
	if not climbing:
		problems.append("the helper never reached the Shaft, so no bag with an "
			+ "ember in it ever arrived at an exit")
	await _hold(_shaft.channel_seconds() + 2.0)

	print("[ember] and after   class '%s', tree %d, stash %d, rank %d → %d" % [
		GameState.class_id, GameState.taken.size(), GameState.stash.size(),
		rank_before, GameState.pact_rank])
	if carrying.size() != 1 or carrying[0] != owner_peer:
		problems.append(("the helper is carrying %s rather than the host's "
			+ "ember, so what walked out is not the thing being tested")
			% str(carrying))
	elif _descent == floor_before_rescue:
		problems.append("the run never resolved after the last body left, so "
			+ "no outcome was taken and nothing below was decided")
	elif GameState.class_id != &"huskarl" or GameState.taken.is_empty() \
			or GameState.stash.is_empty() or GameState.pact_rank != rank_before:
		problems.append(("the ember reached the exit and the life was wiped "
			+ "anyway — `DES-012` says the tree, the stash and the rank are "
			+ "**intact**, and the rescuer paid weight, noise and a worse walk "
			+ "home for it. `rescued` fired and nothing but this probe was "
			+ "listening"))
	if not GameState.last_life.is_empty():
		problems.append(("a rescued life left a death record, so the fire will "
			+ "open the Legacy screen over somebody who was carried home"))
	# **The token is spent at the exit**, sampled at the instant the rescue was
	# announced rather than afterwards — `_on_extracted` consumes it, marks the
	# body out and resolves the run in one call stack, so anything read later is
	# read past `_reset_floor` emptying every bag. The first draft of this row
	# looked afterwards, and planting the fault proved it could not fail.
	print("[ember] the token   still in the bag at the exit=%s (want no)"
		% _token_survived)
	if _token_survived:
		problems.append(("the delivered ember was still in the bag — it rides "
			+ "home in `carried`, turns up in the Chamber, and the pile takes "
			+ "anything it is given (`DES-014` never gives it back), so the "
			+ "token for a life somebody already saved becomes a thing you can "
			+ "throw away by accident"))

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

	# ─ 4. **and it ends on a press** (`M3-T30`, ADR-151) ─
	#
	# What a wipe used to be from the seat: the bar empties, the readout
	# changes, and three seconds later the scene does. No acknowledgement, no
	# agency, and solo no way to tell an ending from a hang — which is what the
	# reporter met and abandoned out of. Measured end to end, from the moment
	# the last body goes out to the floor resolving, because the claim is that
	# the wait is now a floor rather than a fixed price.
	for body: Player in _session.players():
		body.restore_for_descent()
	await _hold(0.4)
	var floor_at_fourth: int = _descent
	mine.health.apply_damage(mine.health.maximum * 2.0)
	friend.health.apply_damage(friend.health.maximum * 2.0)
	await _hold(0.2)
	var began: int = Time.get_ticks_msec()
	mine.bleeding = 0.02
	friend.bleeding = 0.02
	await _hold(0.6)
	var screen: RunOverScreen = null
	if _run_over != null:
		for child: Node in _run_over.get_children():
			var found := child as RunOverScreen
			if found != null:
				screen = found
	print("[wipe] it says so    screen=%s, the body is held=%s" % [
		screen != null, not mine.driving()])
	if screen == null:
		problems.append(("nobody was left standing and nothing said so — three "
			+ "seconds of the same readout and then a cut is what ADR-108 "
			+ "called *nothing to read*, and it is what a solo player cannot "
			+ "tell apart from a hang"))
		_report(problems, "wipe")
		return
	if mine.driving():
		problems.append(("the run-over screen is up and the body still drives "
			+ "— a Vörðr is mobile so a dead player can scout for the living, "
			+ "and this window opens only when there are none left to scout "
			+ "for (ADR-146's seam, and the reason it is a named claim)"))
	if not screen.press():
		problems.append("the run-over screen has no button to press, so the "
			+ "only way out of it is the clock it exists to replace")
	await _hold(0.6)
	var took: float = float(Time.get_ticks_msec() - began) / 1000.0
	print("[wipe] pressed       floor %d → %d in %.1f s (the wait alone is %.1f s)"
		% [floor_at_fourth, _descent, took, Config.tuning.party_wipe_seconds])
	if _descent == floor_at_fourth:
		problems.append("pressing TO THE FIRE did not end the run, so the "
			+ "button is the stub ADR-064 bans on the one screen a player "
			+ "meets at their worst moment")
	elif took >= Config.tuning.party_wipe_seconds:
		problems.append(("the run took %.1f s to end against a %.1f s wait — "
			+ "the press did not shorten anything, so the screen is a caption "
			+ "on a timer rather than a way out of one")
			% [took, Config.tuning.party_wipe_seconds])
	print("[wipe] and it leaves screen still up=%s (want no)" % (_run_over != null))
	if _run_over != null:
		problems.append(("the run-over screen outlived the run — in a real "
			+ "session the scene change takes it, which is exactly why nothing "
			+ "would notice it being left behind here"))

	_report(problems, "wipe")


## What the starting weapon hits for. A number the harness reports rather than
## keeps its own copy of — and since `M3-T07` it lives on the item, so this asks
## the item instead of the profile.
func _seax_damage() -> float:
	var seax: ItemResource = ItemCatalogue.by_id(&"wpn_seax")
	var edge := seax.first_trait(WieldableTrait) as WieldableTrait
	return edge.damage if edge != null else 0.0


## **Photograph the arrangement** (`M4-T01` step 6, ADR-093's rule).
##
## `--machine-probe` proves a situation was stamped, that its contents reach the
## floor, and that two peers agree about it. **It cannot see whether the room
## reads.** Seven marks pointing at a door is either a sentence or it is seven
## boxes, and the difference is entirely visual — which is the gap `--bag-shot`,
## `--ear-shot` and `--ember-shot` were each built to close after a headless
## check passed over something nobody could see.
##
## Stands where a player walks in and looks across the room, on
## `--delvings-shot`'s reasoning: every position is one the generator chose, so
## the camera is in open space by construction rather than by luck.
func _machine_shot(path: String) -> void:
	var player: Player = _session.local_player()
	# Ink off, like every other shot judging space rather than treatment.
	player.show_ink(false)
	var made := _floor as DelvingsFloor
	if made == null:
		print("[machine] no generated floor to photograph")
		get_tree().quit(1)
		return
	var views: Array = made.machine_views()
	if views.is_empty():
		# **Not a silent pass.** A shot that photographs nothing and exits zero is
		# how a stamping that stopped happening stays invisible.
		print("[machine] this floor stamped nothing — nothing to photograph")
		get_tree().quit(1)
		return
	for view: Dictionary in views:
		var at: Vector3 = (view["at"] as Vector3) + Vector3(0.0, 0.1, 0.0)
		var d: Vector3 = (view["look"] as Vector3) - at
		d.y = 0.0
		# `atan2(-d.x, -d.z)`, for `_delvings_shot`'s stated reason: Godot yaws
		# about +Y and forward is -Z, so guessing the sign photographs the wall
		# behind you and looks like an empty room.
		var yaw: float = atan2(-d.x, -d.z) if d.length() > 0.01 else 0.0
		player.teleport(at, yaw)
		await _hold(0.35)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot: String = "%s_%s_%d.png" % [
			path.trim_suffix(".png"), view["id"], view["node"]]
		get_viewport().get_texture().get_image().save_png(shot)
		print("[machine] %-14s room %d → %s" % [
			view["id"], view["node"], shot.get_file()])
	get_tree().quit()


## **Situations, stamped into rooms** (`M4-T01` step 6, `DES-015` Layer 3,
## ADR-192).
##
## Nine claims. The first three are about the corpus, the next four about the
## stamping, and the last two about the two things that go wrong silently:
## a stamping that is not reproducible, and a machine whose contents never
## reach the floor.
##
## **The row that matters most is 7.** Everything before it can pass against a
## generator that decides beautifully and places nothing — which is exactly the
## state `DES-015` step 6 was in before today, and exactly the shape of ADR-098:
## a system that works, is correct, and is joined to nothing.
func _machine_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var corpus: Array[MachineResource] = MachineCatalogue.all()

	# ─ 1. there is a corpus, and every machine in it is authored correctly ─
	print("[machine] corpus     %d machine(s)" % corpus.size())
	if corpus.is_empty():
		problems.append("no machines authored — every row below is conditional "
			+ "on there being a corpus, which is the guard the item probe has "
			+ "and the reason an empty export is invisible without it")
		_report(problems, "machine")
		return
	var ids: Dictionary = {}
	for machine: MachineResource in corpus:
		for problem: String in machine.validate():
			problems.append(problem)
		if ids.has(String(machine.id)):
			problems.append("`%s` is authored twice" % machine.id)
		ids[String(machine.id)] = true

	# ─ 2. **every machine states its question** (`DES-015` Layer 3) ─
	#
	# The rule that separates this system from a second loot table, and the one
	# thing about it a validator can actually hold. Asserted here as well as in
	# `validate()` because the probe is what prints them, and a question nobody
	# ever reads is the `name_key` trap this whole task was found through.
	for machine: MachineResource in corpus:
		print("[machine] asks       %s: %s" % [
			machine.id, machine.question.strip_edges()])
		if machine.question.strip_edges() == "":
			problems.append("`%s` asks nothing, so it is a room with loot in it"
				% machine.id)

	# ─ 3. the corpus can serve the floors it claims ─
	var modules: Array[RoomModule] = RoomCatalogue.all()
	var calamities: Array[CalamityResource] = CalamityCatalogue.all()
	var kinds: PackedStringArray = _prize_kinds(modules)

	# ─ 4. a floor of every depth stamps something ─
	#
	# **Not "stamps correctly" — stamps at all.** A `SHARE` that rounded to zero,
	# a `fits` that never matched, or an eligible list that excluded everything
	# would each leave a generator that runs step 6 and produces nothing, and
	# every other row here would still pass.
	var stamped_any: int = 0
	var floors: int = 0
	for depth: int in 3:
		var graph: MissionGraph = MissionGraph.build(4242, depth)
		var lore := ExpeditionHistory.roll(4242, calamities, kinds)
		var plan: FloorPlan = FloorPlan.build(graph, 4242, depth, modules, lore)
		if not plan.problems().is_empty():
			continue
		floors += 1
		var stamping: FloorMachines = FloorMachines.of(
			plan, graph, 4242, depth, corpus)
		for problem: String in stamping.problems():
			problems.append("floor %d: %s" % [depth, problem])
		stamped_any += stamping.count()
		print("[machine] floor %d    %d of %d room(s) carry a situation%s"
			% [depth, stamping.count(), graph.size(),
				" — " + stamping.digest() if stamping.count() > 0 else ""])
	if floors == 3 and stamped_any == 0:
		problems.append("three floors were stamped and not one room carries a "
			+ "situation — step 6 runs and produces nothing, which is the state "
			+ "it was in before it existed")

	# ─ 5. **the mission's own rooms are never taken** ─
	#
	# The entrance, the Prize and the Shaft. Swept rather than spot-checked,
	# because the failure is one room on one seed in a hundred and a single
	# floor would not see it.
	var swept: int = 0
	var carried: int = 0
	var quiet: int = 0
	for seed_at: int in range(9000, 9120):
		var graph: MissionGraph = MissionGraph.build(seed_at, 0)
		var lore := ExpeditionHistory.roll(seed_at, calamities, kinds)
		var plan: FloorPlan = FloorPlan.build(graph, seed_at, 0, modules, lore)
		if not plan.problems().is_empty():
			continue
		swept += 1
		var stamping: FloorMachines = FloorMachines.of(
			plan, graph, seed_at, 0, corpus)
		for problem: String in stamping.problems():
			problems.append("seed %d: %s" % [seed_at, problem])
		if stamping.count() > 0:
			carried += 1
		else:
			quiet += 1
		# A crawl is 1.15 m of crouch with no swing. A situation in one is one
		# nobody can stand up and read.
		for node: int in stamping.nodes():
			var module: RoomModule = RoomCatalogue.by_id(plan.module_of(node))
			if module != null and module.volume == RoomModule.Volume.CRAWL:
				problems.append("seed %d stamped `%s` into a crawl"
					% [seed_at, stamping.at(node).id])
	print("[machine] sweep      %d floor(s): %d carry a situation, %d quiet"
		% [swept, carried, quiet])
	if swept > 0 and carried == 0:
		problems.append("no floor in %d carried a situation" % swept)

	# ─ 6. **quiet rooms outnumber loud ones** ─
	#
	# `FloorMachines.SHARE`'s whole argument: a floor where every room is a
	# machine has no machines, and the reading only works against quiet. This is
	# the row that fails if somebody raises `SHARE` to see more of their work.
	var loud: int = 0
	var rooms: int = 0
	for seed_at: int in range(9000, 9060):
		var graph: MissionGraph = MissionGraph.build(seed_at, 1)
		var lore := ExpeditionHistory.roll(seed_at, calamities, kinds)
		var plan: FloorPlan = FloorPlan.build(graph, seed_at, 1, modules, lore)
		if not plan.problems().is_empty():
			continue
		var stamping: FloorMachines = FloorMachines.of(
			plan, graph, seed_at, 1, corpus)
		loud += stamping.count()
		rooms += graph.size()
	var share: float = float(loud) / maxf(1.0, float(rooms))
	print("[machine] density    %d situation(s) in %d room(s) — %.0f%%"
		% [loud, rooms, share * 100.0])
	# **Against a half, not against `SHARE`.** Written the obvious way first —
	# `share > FloorMachines.SHARE` — and that is a row that **cannot fail**:
	# raising the constant raises the threshold with it, so the one edit the
	# check exists to catch is the one edit it waves through. Caught by planting
	# `SHARE = 0.95` and watching the probe pass.
	#
	# So the number here is the *claim*, stated independently: **most of a floor
	# is quiet.** A generator that ever crosses a half has stopped making
	# situations legible whatever its constant says.
	if share > 0.5:
		problems.append(("%.0f%% of rooms carry a situation — most of a floor "
			+ "has to be quiet or a situation is not one, and `SHARE` is %.0f%%")
			% [share * 100.0, FloorMachines.SHARE * 100.0])

	# ─ 7. **what a machine asks for reaches the floor** ─
	#
	# The join, and the row every other one here is conditional on. `--bag-probe`
	# and ADR-098 both taught the same thing: a system can be entirely correct
	# and reachable by nothing. So this asks the floor, not the stamper — the
	# gear a machine wants must appear in `fixtures()` and its threat in
	# `machine_posts()`, or step 6 decided something that nothing built.
	var joined: int = 0
	var checked: int = 0
	for seed_at: int in range(7000, 7080):
		var made: DelvingsFloor = DelvingsFloor.of(seed_at, 1)
		if not made.problems().is_empty():
			continue
		var stamping: FloorMachines = made.machines()
		var wants_gear: int = 0
		var wants_bodies: int = 0
		for node: int in stamping.nodes():
			wants_gear += stamping.at(node).gear
			wants_bodies += stamping.at(node).bodies
		if wants_gear == 0 and wants_bodies == 0:
			continue
		checked += 1
		var posts: int = made.machine_posts().size()
		if wants_bodies > 0 and posts == 0:
			problems.append(("seed %d wants %d machine body/ies and the floor "
				+ "posts none — the stamping decided an encounter nothing "
				+ "spawns") % [seed_at, wants_bodies])
			continue
		# Fixtures are the Prize, the Waystone and machine gear. The floor has
		# to carry more of them than the two it carries without any machine.
		if wants_gear > 0 and made.fixtures().size() <= 2:
			problems.append(("seed %d wants %d piece(s) of machine gear and the "
				+ "floor lays only the Prize and the Waystone — the gear was "
				+ "decided and never placed") % [seed_at, wants_gear])
			continue
		joined += 1
	print("[machine] reaches    %d of %d floor(s) placed what they stamped"
		% [joined, checked])
	if checked > 0 and joined == 0:
		problems.append("no floor placed anything a machine asked for")

	# ─ 8. **same seed, same situations** ─
	#
	# `TEC-004`: two peers handed one seed build one floor. A stamping that
	# agreed about geometry and disagreed about what stands in it is two floors
	# wearing one layout, and nothing in `--build-probe` would notice.
	var once: DelvingsFloor = DelvingsFloor.of(555, 1)
	var twice: DelvingsFloor = DelvingsFloor.of(555, 1)
	var same: bool = once.machines().digest() == twice.machines().digest()
	print("[machine] same seed  %s (%s)" % [
		"identical" if same else "DIFFERENT", once.machines().digest()])
	if not same:
		problems.append(("one seed stamped two different floors: `%s` then `%s`"
			+ " — a situation on a client that is not on the host is a room two "
			+ "players cannot talk about") % [
				once.machines().digest(), twice.machines().digest()])

	# ─ 9. **and the seed matters to _this stage_** ─
	#
	# The other half of row 8, and it has to hold the plan still to mean
	# anything.
	#
	# **Written the obvious way first, and it asserted the wrong thing.** Rolling
	# eighty whole floors and counting distinct stampings gives fifty-plus even
	# with this stage's RNG pinned to a constant — because the *plan* varies by
	# seed, so different graphs and different eligible rooms produce different
	# stampings from an identical stream. The row measured "the floor varies",
	# which row 8's sibling in `--plan-probe` already covers, and it passed
	# against a stamper that ignored its seed entirely. Planted and not caught.
	#
	# So: **one plan, many seeds.** Now the only thing that can vary is the
	# stream this stage draws from, which is the claim.
	var pinned_graph: MissionGraph = MissionGraph.build(6000, 1)
	var pinned_lore := ExpeditionHistory.roll(6000, calamities, kinds)
	var pinned: FloorPlan = FloorPlan.build(
		pinned_graph, 6000, 1, modules, pinned_lore)
	var seen: Dictionary = {}
	if pinned.problems().is_empty():
		for seed_at: int in range(6000, 6080):
			var stamping: FloorMachines = FloorMachines.of(
				pinned, pinned_graph, seed_at, 1, corpus)
			seen[stamping.digest()] = true
	print("[machine] seed matters %d distinct stamping(s) of one plan from 80 seeds"
		% seen.size())
	if seen.size() < 4:
		problems.append(("80 seeds stamped one plan %d distinct way(s) — a "
			+ "stage that ignores its own seed lays the same situations on "
			+ "every floor whose layout happens to match") % seen.size())

	# ─ 9a. **value climbs with depth** (`M4-T01` step 7, `DES-015` Layer 4) ─
	#
	# The load-bearing half of population, and it was flat: `_by_worth()` ignored
	# `_depth`, so the Prize on floor 0 was **the same object** as the Prize on
	# floor 2 and the only thing that worsened with descent was the Hunt.
	#
	# Measured as *what the floor actually lays*, not as what the pool contains.
	# A cut pool that nothing reads would pass a pool-shaped assertion and change
	# no run — the ADR-098 shape this probe's row 7 already exists for.
	var worth_at := PackedInt32Array()
	for depth: int in RunFile.LAST_FLOOR + 1:
		var best: int = 0
		var total: int = 0
		var floors_seen: int = 0
		for seed_at: int in range(8000, 8040):
			var made: DelvingsFloor = DelvingsFloor.of(seed_at, depth)
			if not made.problems().is_empty():
				continue
			floors_seen += 1
			for row: Array in made.fixtures() + made.filler():
				var item: ItemResource = ItemCatalogue.by_id(row[0] as StringName)
				if item == null:
					continue
				total += item.tribute_value
				best = maxi(best, item.tribute_value)
		worth_at.append(best)
		print("[machine] depth %d     best %d tribute, %d laid across %d floor(s)"
			% [depth, best, total, floors_seen])
	# **Strictly climbing, and by a lot.** `DES-015` says *steeply*, so equal
	# adjacent floors is a failure and not a rounding artefact: two floors that
	# pay the same are two floors with the same decision on them.
	for depth: int in worth_at.size() - 1:
		if worth_at[depth + 1] <= worth_at[depth]:
			problems.append(("floor %d's best is %d tribute and floor %d's is "
				+ "%d — `DES-015` Layer 4 wants value climbing steeply with "
				+ "depth, and nothing pulls a player down a floor that pays the "
				+ "same") % [depth, worth_at[depth], depth + 1, worth_at[depth + 1]])
	# And the climb is worth descending for. Two floors apart differing by a
	# few tribute is a curve nobody changes a decision over.
	if worth_at.size() >= 2 and worth_at[0] > 0 \
			and float(worth_at[worth_at.size() - 1]) / float(worth_at[0]) < 3.0:
		problems.append(("the bottom pays %.1fx the top — `DES-015` asks for "
			+ "*steeply*, and a gentle curve is one the Tithe can be paid "
			+ "against without ever going deep (`DES-003`)")
			% (float(worth_at[worth_at.size() - 1]) / float(worth_at[0])))

	# ─ 10. **every Calamity is named, and the name is a name** (ADR-192) ─
	#
	# The finding this task was opened by, and it was worse than it looked.
	# `CalamityResource.name_key` had a validator *requiring* it, five `.tres`
	# files supplying one, and no reader anywhere — so a Calamity weighted every
	# room on the floor and was told to the player in no channel at all.
	#
	# **And the keys resolved to nothing.** None of the five was in `en.csv`,
	# because nothing in the project checks that a `name_key` points at a
	# string. `tr()` returns its argument when a key is missing, so the failure
	# mode is not a crash or a blank — it is the literal key rendered on screen
	# as though it were English, which is why an unread field and an unauthored
	# string hid each other perfectly.
	#
	# The whole corpus, not one sample: five rolls of one seed would have caught
	# the drowning and missed the other four.
	var named: DelvingsFloor = DelvingsFloor.of(31337, 0)
	var what: CalamityResource = named.calamity()
	print("[machine] calamity   this floor: %s" % (
		what.display() if what != null else "NONE"))
	if what == null:
		problems.append("a generated floor has no Calamity, so `DES-015` "
			+ "Layer 2 rolled nothing")
	for disaster: CalamityResource in CalamityCatalogue.all():
		var shown: String = disaster.display()
		print("[machine] named      %s → %s" % [disaster.id, shown])
		if shown == "" or shown == String(disaster.id):
			problems.append("`%s` renders as its own id" % disaster.id)
		# **A rendered locale key is the failure this row exists for.** It
		# reaches a player looking like text, so no crash, no blank, and nothing
		# but a reader notices.
		elif shown == String(disaster.name_key) or shown.begins_with("calamity."):
			problems.append(("`%s` renders as `%s` — the locale key itself, so "
				+ "`name_key` points at a string nobody authored and a player "
				+ "reads the key") % [disaster.id, shown])

	_report(problems, "machine")


## **Nothing on screen is drawn on top of anything else** (`M4-T20`, TEC-009 §5.6).
##
## The one question ten existing UI probes do not ask. It is the reported bug —
## twice: ADR-140 inside the bag, and *"overlapping text in the threshold/hoard
## areas"* — and both times every row was green, because a probe that reads a
## label's `text` proves the string exists and never that a human can see it.
##
## Asked of the **grammar** rather than of one screen. `BagScreen.overflowing()`
## was the right idea hardcoded to a single layout, band by band, written after
## the collision; this asks the same question of every region at once, before.
func _hud_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()

	# ─ 1. the grammar is sound at every shape a window can be ─
	#
	# Several sizes, not one. The regions are fractions, so a layout that is
	# clean at 16:9 and folds at 4:3 is exactly the fault a single-resolution
	# check cannot see — and `M4-T11`'s UI scaling will move all of these.
	var shapes: Array[Vector2] = [
		Vector2(1152.0, 648.0),   # the screenshot harness
		Vector2(1920.0, 1080.0),  # 16:9
		Vector2(1280.0, 960.0),   # 4:3
		Vector2(2560.0, 1080.0),  # ultrawide
		Vector2(1024.0, 768.0),   # the smallest window worth supporting
	]
	# **Each world's set, separately.** The Deep has a body and party frames;
	# the camp has a control card and her voice, and neither is ever on screen
	# with the other's. Checking all eight regions at once would report
	# collisions between elements that can never coexist — and, worse, would
	# push the layout into a shape that satisfies an impossible constraint.
	var worlds: Array = [HudFrame.World.DEEP, HudFrame.World.LAIR]
	for screen: Vector2 in shapes:
		for world: int in worlds:
			var label: String = HudFrame.World.keys()[world]
			var rects: Dictionary = HudFrame.all_rects(
				screen, world as HudFrame.World)
			var faults: PackedStringArray = HudFrame.collisions(rects, screen)
			print("[hud] grammar    %d×%d %-4s — %d region(s), %d fault(s)" % [
				int(screen.x), int(screen.y), label, rects.size(),
				faults.size()])
			for fault: String in faults:
				problems.append("at %d×%d in the %s: %s"
					% [int(screen.x), int(screen.y), label, fault])
			# ─ 2. and every region is actually on the screen ─
			for region_name: String in rects.keys():
				var box: Rect2 = rects[region_name]
				if box.position.x < 0.0 or box.position.y < 0.0 \
						or box.end.x > screen.x or box.end.y > screen.y:
					problems.append("at %d×%d: `%s` falls off the screen"
						% [int(screen.x), int(screen.y), region_name])
				if box.size.x <= 0.0 or box.size.y <= 0.0:
					problems.append("at %d×%d: `%s` has no area, so nothing "
						% [int(screen.x), int(screen.y), region_name]
						+ "placed in it can be seen")

	# ─ 3. **the check can fail** ─
	#
	# The plant, kept rather than performed once. `CLAUDE.md`: a row that has
	# never failed has never been tested — and this project has shipped a probe
	# that compared a measurement against the constant that produced it and so
	# could not go red. Two rects that certainly overlap, and one that certainly
	# sits in the middle of the screen, are fed in deliberately.
	var screen := Vector2(1152.0, 648.0)
	var planted: Dictionary = {
		"PLANT_A": Rect2(100.0, 100.0, 200.0, 200.0),
		"PLANT_B": Rect2(200.0, 200.0, 200.0, 200.0),
	}
	var caught: PackedStringArray = HudFrame.collisions(planted, screen)
	print("[hud] plant      overlapping pair → %d fault(s)" % caught.size())
	if caught.size() < 1:
		problems.append("`collisions()` passed two rects that overlap by "
			+ "100×100 px, so every green row above means nothing")
	var centred: Dictionary = {
		"PLANT_C": HudFrame.keepout(screen),
	}
	var centre_caught: PackedStringArray = HudFrame.collisions(centred, screen)
	print("[hud] plant      element in the centre → %d fault(s)"
		% centre_caught.size())
	if centre_caught.size() < 1:
		problems.append("`collisions()` passed an element occupying the exact "
			+ "centre keepout, so `DES-019` rule 1 is not enforced")

	# ─ 4. an absent element cannot collide ─
	#
	# The regions nothing draws in are not checked, on purpose: the question is
	# about what a person can see. A zero-area rect standing for an absent
	# element must not be reported, or every screen fails for the layers it
	# legitimately does not carry.
	var empty: Dictionary = {
		"PLANT_D": Rect2(100.0, 100.0, 0.0, 0.0),
		"PLANT_E": Rect2(100.0, 100.0, 200.0, 200.0),
	}
	if HudFrame.collisions(empty, screen).size() > 0:
		problems.append("an absent element reported a collision, so a screen "
			+ "is failed for the layers it does not carry")

	_report(problems, "hud")


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
	# **What is happening to you, while it happens** (`M3-T14`, `DES-012`).
	# Not gated on `_probing`, unlike the arrival brief below: it draws nothing
	# at all unless the body holding the camera is down or loose, so it cannot
	# fade over a screenshot — and a probe that downs a player deliberately
	# should be exercising it rather than hiding it.
	layer.add_child(FallenReadout.new())
	# Not while a probe is measuring the floor: it would be three labels
	# fading over a screenshot, and `--ear-shot` in particular photographs
	# exactly the frames this covers.
	if not _probing:
		var brief := ArrivalBrief.new()
		# Set before it enters the tree: `ArrivalBrief._ready` is where its
		# lines are built, and a fourth one added afterwards would arrive under
		# a label that has already been laid out.
		brief.sent_early = _she_sent_it_early
		# **Say where this is and what the light does** (`M4-T01`, ADR-187).
		#
		# The stages are `DES-015` Layer 2's, not invented here: *moving inward
		# is reading the disaster backward* — the Aftermath, the Retreat, the
		# Cause. Naming the floor is the cheapest half of the rule that the
		# Calamity be readable within thirty seconds, and this is the screen
		# that has thirty seconds.
		if _floor is DelvingsFloor:
			brief.place = "THE DELVINGS · %s" % FLOOR_NAMES[
				clampi(_floor_index, 0, FLOOR_NAMES.size() - 1)]
			# **And what happened here** (ADR-192). The Calamity has been rolled
			# per expedition since ADR-174, it weights every room the floor
			# seats, and until now it was named to the player in **no channel at
			# all** — `CalamityResource.name_key` had a validator requiring it
			# and no reader anywhere.
			#
			# The name only. `DES-015` Layer 2's discipline is that the pattern
			# is discoverable and never stated, so this says what the disaster
			# was called and never what it was; the room full of dead is
			# `mac_witness`'s job, and reading the two together is the whole of
			# Layer 2's payoff.
			var what: CalamityResource = (_floor as DelvingsFloor).calamity()
			if what != null:
				brief.place += " · %s" % what.display().to_upper()
		brief.way_out = _shaft == null or _shaft.leads_out
		layer.add_child(brief)

## How much floor has already been laid, so an arriving player tops it up
## rather than doubling it. See `_on_party_changed`.
var _enemies_placed: int = 0
var _loot_placed: int = 0
## What rank the Hunt has already been aged for (ADR-122). Tracked rather than
## recomputed, because the age is *added to* a clock that is also ticking — so
## re-applying a rank has to add the difference, never the whole of it.
var _rank_in_the_hunt: int = 1
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
	# And until everyone has said what rank they are (ADR-122). `_await_party`
	# waits for bodies, and a body is not a declaration — sampling the floor on
	# the first read a floor that was still assembling, and failed one run in two.
	var settling: int = Time.get_ticks_msec()
	while not _session.everyone_declared():
		await get_tree().physics_frame
		if Time.get_ticks_msec() - settling > PROBE_TIMEOUT_MSEC:
			break
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
		# ADR-122: what rank the host actually built this floor for, and how old
		# the Hunt is because of it. The client declares a higher rank than the
		# host, so a floor that never heard it reads as rank 1 here.
		"floor_rank": _session.floor_rank(),
		"hunt_age": _hunter.age if _hunter != null else 0.0,
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
		"swing_damage": _seax_damage(),
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
			# **This body's own ceiling** (`M3-T07`). The class scales it
			# (`M3-T02`), so a Húskarl revives to 50 of 125 where the profile
			# would say 40 of 100 — and a harness comparing against the profile
			# is describing a body nobody is playing.
			"maximum": player.health.maximum,
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


## Take every enemy off the floor, host-side (`M4-T13`, ADR-188).
##
## **For scenarios whose subject is not combat.** `run_doorway.py`'s extraction
## scenario needs three bodies to each stand still for a 1.1 s Waystone channel,
## and `DES-005` makes that channel *"a moment you can be interrupted in"* —
## being downed mid-channel silently zeroes it (`_go_down`). So the check was
## asserting three consecutive uninterrupted channels on a floor with live
## enemies on it, which the design explicitly refuses to guarantee.
##
## It passed for a year on luck. `M4-T13` changed how far a body is seen from
## and the luck ran out — an enemy reached the first client every single run.
## **The lantern did not break extraction; it perturbed a check that had a
## hidden dependency on enemy pathing**, and a check that can fail for reasons
## unrelated to its own claim is worse than no check, because the next person to
## see it red will spend a day where I spent one.
##
## Freed on the host only; the spawner takes them off every client.
func _clear_the_floor() -> void:
	if not multiplayer.is_server():
		return
	var taken: int = 0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		node.queue_free()
		taken += 1
	if _hunter != null:
		_hunter.queue_free()
		_hunter = null
		taken += 1
	print("[extract] cleared %d threat(s) — this scenario is about the "
		% taken + "doorway, not about surviving")


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
	# **Two axes, multiplied** (`M3-T10`, ADR-010). How many people are down
	# here and how far along the deepest of them is are different questions, and
	# a floor answers both: four rank-1 players and one rank-8 player are
	# different floors for different reasons.
	var posts: Array[Vector3] = _floor.enemy_posts()
	var wanted: int = RankScaling.denser(
		PartyScaling.enemies(posts.size(), party), _session.floor_rank())
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
		var post: Vector3 = posts[index % posts.size()]
		var ring: int = index / posts.size()
		if ring > 0:
			var angle: float = TAU * float(index) / float(posts.size())
			post += Vector3(cos(angle), 0.0, sin(angle)) * SPREAD * float(ring)
		_session.spawn_enemy(post)
	if _enemies_placed == 0:
		# The Guardian faces its prize's doorway and never leaves the room.
		_session.spawn_enemy(_floor.guardian())
		# **And whatever a machine brought with it** (`DES-015` Layer 3,
		# ADR-192), on the Guardian's rule and in the same branch, because it is
		# the same kind of claim: a situation's threat is part of what the room
		# *is*. Scaling it with the party would turn *"the thing that killed
		# them has not moved"* into a different encounter for a four-stack, and
		# `_spawn_enemies` is topped up on every arrival — so anything spawned
		# outside this guard is spawned once per player.
		for post: Vector3 in _floor.machine_posts():
			_session.spawn_enemy(post)
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
	# **A resumed floor has already been stripped** (`M3-T15`). Without this,
	# quitting and coming back re-lays every fixture and the run's loot doubles
	# — which turns ADR-050's suspend into the best way to farm a floor, and
	# makes a feature about *not* escaping a run into an exploit for extending
	# one.
	# **A probe measures the floor as built, never as resumed** (`M3-T15`).
	#
	# Same gate as `_carry_the_stash_down` above, and it earned itself the same
	# way: a probe that inherits `user://run.active` measures a floor somebody
	# else's run left behind. It happened immediately — planting *garbage parses
	# as a run* leaves the garbage on disk by construction, because the plant is
	# the line that drops it, and the next probe to boot found it, errored on
	# it and failed the sweep. A plant restores the source and not `user://`.
	if not _probing and bool(RunFile.read().get("stripped", false)):
		print("[run] resumed floor — its loot is already carried or lost")
		return
	if not _fixtures_placed:
		_fixtures_placed = true
		# **This floor has now given up its loot** (`M3-T15`). Recorded when it
		# is laid rather than when it is picked up, because the claim is about
		# the floor: what a player did with it afterwards is their bag's
		# business, and a resumed run keeps its bag.
		RunFile.note({"stripped": true})
		for row: Array in _floor.fixtures():
			_session.spawn_world_item(row[0] as StringName, row[1] as Vector3)
	var party: int = PartyScaling.size_of(self)
	var spread: Array = _floor.filler()
	var wanted: int = mini(spread.size(), PartyScaling.loot(_solo_loot(), party))
	for index: int in range(_loot_placed, wanted):
		var row: Array = spread[index]
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


## **A rank that turned up after the floor was built** (ADR-122).
##
## ADR-010 scales a floor to the highest Pact Rank *present*, and a client's
## declaration is an RPC: it lands frames after the host finished `_ready`. So
## the floor built itself to the host's rank alone — the one option ADR-010
## rejected outright, arriving in the exact case ADR-010 exists for.
##
## Density recovers by re-spawning, which grows the ring the same way a joining
## player does. **The Hunt needs the difference, not the whole**, because its
## `age` is a clock that has been ticking since the floor opened: adding the
## full rank age again would age it twice for the same rank.
func _on_floor_rank_changed(_was: int, now: int) -> void:
	if not _session.is_host():
		return
	_spawn_enemies()
	if _hunter != null and now != _rank_in_the_hunt:
		_hunter.age += (RankScaling.hunt_age(now)
			- RankScaling.hunt_age(_rank_in_the_hunt))
		_rank_in_the_hunt = now
	print("[hunt] the floor is rank %d now — the Hunt stands at %.0f s" % [
		now, _hunter.age if _hunter != null else 0.0])


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
	var heard: AABB = _floor.field()
	_field.configure(heard.position, heard.end)
	_hunter = _session.spawn_hunter(_floor.hunter())
	# Arrows and Snares deposit into it too (`M3-T11`), and both are built by
	# the session rather than by this level, so the session needs the same
	# handoff the Hunter gets below. One field, two listeners.
	_session.hunt_in(_field)
	if _hunter != null:
		_hunter.hunt_with(_field)
		# **The floor's rank, as time already spent** (`M3-T10`, ADR-119).
		#
		# Added here rather than inside the Gullsjúkr because the *floor* knows
		# its rank and the Hunter should not be reaching for a session to ask.
		# It adds to whatever a missed Tithe already put there (`M3-T04`): a
		# rank-8 floor you owe her on is both, and both are time.
		#
		# This is `DES-022`'s Hunt axis **and** its Time axis, because
		# `Shaft._escalation` reads this same `age` — so the Shafts on a rank-8
		# floor seal sooner without a second number existing anywhere.
		#
		# **The Tithe is taken here too** (ADR-124), and it must be taken
		# *after* `settle_cycle()` has run — which is why the settle now sits
		# immediately above the call to this function rather than below the
		# HUD. Kept for the arrival brief, because a four-minute head start
		# that nobody can account for is `PRO-005` §5's unexplainable
		# difficulty rather than a consequence.
		_she_sent_it_early = GameState.take_hunt_head_start()
		_hunter.age += _she_sent_it_early
		_rank_in_the_hunt = _session.floor_rank()
		_hunter.age += RankScaling.hunt_age(_rank_in_the_hunt)
		# **And whatever it already was, one floor up** (`M4-T01`, ADR-185).
		#
		# ADR-037 closed Q9 with *"the Hunt persists across floors. Descending
		# grants nothing — going quiet and shedding carried value can shake it,
		# but a staircase cannot. Descent is a commitment."* Until floors
		# existed there was nothing for that sentence to be true of, and
		# `_reset_floor` says so in as many words.
		#
		# Added to the rank and Tithe head starts rather than replacing them:
		# a rank-8 floor you owe her on, arriving on an already-old Hunt, is
		# all three, and all three are time.
		var carried_age: float = RunFile.hunt_age()
		_hunter.age += carried_age
		if carried_age > 0.0:
			print("[hunt] it followed you down — %.0f s of it" % carried_age)
		if _she_sent_it_early > 0.0:
			print("[hunt] she sent it early — %.0f s of it" % _she_sent_it_early)
		if _hunter.age > 0.0:
			print("[hunt] the floor is rank %d — it opens at %.0f s old" % [
				_rank_in_the_hunt, _hunter.age])


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
	_shaft.position = _floor.shaft()
	# **What this Shaft is for** (ADR-186), derived in exactly one place.
	_stand_on_floor(_floor_index)
	# Before it enters the tree, so the synchronizer exists at the same node
	# path on every peer. Both sides build this identically — it is authored
	# geometry rather than a spawn — so the paths match by construction.
	_shaft.configure_replication()
	_world.add_child(_shaft)
	_shaft.claimed.connect(_on_shaft_claimed)
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


## The run-over screen's claim on the body (ADR-151, on ADR-146's seam). Named,
## so the pause menu opening over it gives back only what it took.
const RUN_OVER_CLAIM: StringName = &"run_over"


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
	# **Say so, and let it be ended** (`M3-T30`, ADR-151). ADR-108 gave reason 1
	# for this window as *"a cut to the camp on the frame you go out gives the
	# player nothing to read"* — right about the problem, and three seconds of
	# the same readout was not a solution. The wait is now a floor rather than a
	# fixed price: whoever is ready presses, and the clock is the backstop for
	# whoever is not.
	_the_run_is_over.rpc()
	_skip_the_wait = false
	var until: float = Time.get_ticks_msec() \
		+ Config.tuning.party_wipe_seconds * 1000.0
	while Time.get_ticks_msec() < until and not _skip_the_wait:
		await get_tree().process_frame
		# **Out the moment somebody is standing**, rather than at the end of the
		# wait. The re-check below is what decides the run, and it is unchanged;
		# this only takes the screen down early, which is the safe direction —
		# ADR-108's rule guards against ending a run too eagerly, never against
		# calling one off too eagerly.
		#
		# Found by `--ember-probe`, which stands its only body back up inside
		# the window and then measures what carrying an ember costs. With the
		# screen holding the body for the rest of the wait, it measured a
		# rescuer who could not move and reported the cost as nothing.
		if not _the_party_is_gone():
			break
	_ending = false
	_skip_the_wait = false
	# Somebody got up.
	#
	# **In practice nothing reachable does this**, and the comment that used to
	# stand here said otherwise: *"`_stand_up` clears `spent` on a
	# self-recovery and a teammate's hand does the same."* It does not —
	# `_stand_up` never touches `spent`, and both `revive_by` and
	# `_self_recover` refuse a body that is not `is_downed()`. What can still
	# cancel a wipe is a peer connecting inside the window, whose body arrives
	# standing. The re-check stays for that, and because a rule that reads
	# *"nobody has been standing for a while"* is the right rule whether or not
	# today's build can exercise every path into it.
	if not _the_party_is_gone():
		print("[death] somebody got back up — the run continues")
		_the_run_goes_on.rpc()
		return
	_end_the_run()


## Shown on every peer, because every peer in it has just lost the run and the
## host is the only one that knows.
@rpc("authority", "call_local", "reliable")
func _the_run_is_over() -> void:
	if _run_over != null:
		return
	var screen := RunOverScreen.new()
	screen.leave_now.connect(_ask_to_end_it_now)
	_run_over = CanvasLayer.new()
	_run_over.layer = 9
	_run_over.add_child(screen)
	add_child(_run_over)
	# The Vörðr is mobile (`M3-T14`) so a dead player can still scout for the
	# living — and this window opens only when there are none, so there is
	# nothing left to scout for and the screen takes the body.
	var body: Player = _session.local_player()
	if body != null:
		body.hold_attention(RUN_OVER_CLAIM)


@rpc("authority", "call_local", "reliable")
func _the_run_goes_on() -> void:
	_put_the_screen_away()


func _put_the_screen_away() -> void:
	if _run_over == null:
		return
	_run_over.queue_free()
	_run_over = null
	var body: Player = _session.local_player()
	if body != null:
		body.release_attention(RUN_OVER_CLAIM)


## Whoever pressed it. The outcome is already decided by the time this screen
## exists — every body is out and nothing can revive a spent one — so a press
## from any peer costs nobody anything but the wait.
func _ask_to_end_it_now() -> void:
	if multiplayer.is_server():
		_skip_the_wait = true
	else:
		_end_it_now.rpc_id(CoopSession.HOST_PEER)


@rpc("any_peer", "reliable")
func _end_it_now() -> void:
	if not multiplayer.is_server():
		return
	_skip_the_wait = true


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
		# **Out by either door** (`M3-T09`). This asked `spent` alone, which was
		# the whole truth while extraction ended the run for everybody — a party
		# can now end with one body walked out and one lying spent, and a
		# predicate that counted only the dead would keep that floor open with
		# nobody on it.
		#
		# Down is deliberately **not** out: a bleeding body is still in the run,
		# and that is the whole of what a teammate is deciding about.
		if not body.is_out():
			return false
	return true


## **A party can also end because somebody left** (`M3-T35`, ADR-156).
##
## Run resolution was reachable from exactly two places — `_on_died_here` and
## `_on_extracted` — and a peer disconnecting is neither. `_watch_for_a_wipe`
## returns immediately when somebody is still standing and leaves `_ending`
## false, so nothing re-armed it; `_the_party_is_gone()` would have answered
## correctly if anything had asked it again.
##
## What that was, from the seat: your last teammate alt-F4s while you are lying
## there spent. A `spent` body cannot move and **cannot be revived by anything
## in this build** (ADR-151 established that), so the floor keeps running around
## somebody who can do nothing, forever. The only way out is the pause menu, and
## with a run open that button is `ABANDON THE RUN` — so a friend closing their
## laptop cost you the life. Same shape if you had already extracted and were
## waiting for them (`M3-T09`).
##
## This is ADR-108's own finding — *"a player with no teammates simply never
## ended"* — arriving through the door ADR-108 did not cover: the teammate
## **leaving** rather than dying.
##
## **The departing body has to be out of the party before this can be right**,
## and that is `players()`' job rather than this one's. `queue_free` does not
## leave the tree until after the frame the signal fires in, so the first draft
## of this asked `_the_party_is_gone()` about a party that still contained the
## person who had just left — read as *somebody is standing*, and did nothing at
## all. It failed its own new row, which is the only reason it is not still
## doing that: awaiting a frame first appeared to be the fix and is a guess
## about the deletion queue rather than a statement about the party.
func _on_peer_left(_peer: int) -> void:
	if not multiplayer.is_server():
		return
	if not _the_party_is_gone():
		return
	# **Which of the two endings this is.** Both already exist and they are not
	# interchangeable: `RunOverScreen` says *"YOU WENT OUT"*, which is the truth
	# for somebody lying spent and a lie to somebody who walked out on their own
	# feet and was waiting for a friend who never came back.
	for body: Player in _session.players():
		if body.spent:
			print("[left] nobody is left in the run — the last of them went")
			_watch_for_a_wipe()
			return
	print("[left] everyone still here had already got out — settling")
	_settle_if_nobody_is_left()


## **Nobody is left in it, so settle** (`M3-T09`).
##
## No window here, unlike the wipe path. That one waits because a revive inside
## it has to cancel it — two players going down a second apart is an ordinary
## way for a fight to go. Nothing cancels an extraction: the last player walked
## out on purpose, and there is nobody left to change their mind.
func _settle_if_nobody_is_left() -> void:
	if not multiplayer.is_server():
		return
	if _the_party_is_gone():
		_end_the_run()


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
	# **The run file closes in `_take_the_outcome`, not here** (`M3-T34`,
	# ADR-155). This line used to be the clear, and it is inside a function that
	# returns on its first line for everybody who is not the host — so a run
	# resolved for the whole party and closed for exactly one of them.
	var my_haul: Array = []
	var my_loss: bool = false
	var my_deeds: Array = []
	var mine_found: bool = false
	for body: Player in _session.players():
		var peer: int = body.get_multiplayer_authority()
		# Spent means you went out down there. Everything you were carrying
		# stayed with your body, so there is nothing to hand back.
		var packed: Array = [] if body.spent else body.inventory.pack()
		# **Out is not the same as lost** (`M3-T33`, `DES-012`). A body whose
		# ember somebody carried to an exit is spent and **not** dead: it loses
		# the run and the bag that stayed with it, and keeps the tree, the
		# stash and the rank.
		var gone: bool = body.spent and not _borne_out.has(peer)
		if peer == CoopSession.HOST_PEER:
			# Held, not taken. Taking it here is what detached the node.
			my_haul = packed
			my_loss = gone
			my_deeds = _deeds_for(body)
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
		if body.spent and not gone:
			print("[death] %s went out and was carried home — the life survives"
				% body.name)
		_take_the_outcome.rpc_id(peer, packed, gone, _deeds_for(body))
	# Last, because this is the one that takes the floor out from under us.
	if mine_found:
		_take_the_outcome(my_haul, my_loss, my_deeds)


## What this peer walked away with, delivered to the peer it belongs to.
##
## `GameState` is never networked (`TEC-004`), so the host cannot write another
## player's progression — it can only tell them what happened and let them
## write their own.
@rpc("any_peer", "reliable")
func _take_the_outcome(packed: Array, lost: bool, earned: Array = []) -> void:
	# Sender 0 is the host calling this on itself, which is not an RPC at all.
	var from: int = multiplayer.get_remote_sender_id()
	if from != 0 and from != CoopSession.HOST_PEER:
		return
	# **This peer's run is over, so this peer's run file closes** (`M3-T34`,
	# ADR-155, completing `M3-T15`).
	#
	# It was in `_end_the_run`, which returns immediately on anything that is
	# not the host — so `user://run.active` survived every run a **client** came
	# home from alive. `PauseMenu.leaving_ends_the_life()` is `RunFile.exists()`
	# (ADR-152), so a client standing at the fire after a successful extraction
	# was told that leaving ends their life, and the button that says so calls
	# `GameState.die()`. There is no `TO THE MENU` on that menu while a run is
	# open, so the only way back to the front door was through the great reset.
	#
	# **It bites only on runs you survive**, which is why it lasted: a wipe
	# sends `lost = true`, `die()` clears `class_id`, and the stale file is then
	# an orphan that `resume_is_this_life()` drops on the next launch (ADR-138).
	# Every failed run cleaned up after itself and every good one did not.
	#
	# Here rather than beside the host's clear because this message already
	# *is* the per-peer sentence — *your run resolved, and here is what it came
	# to* — delivered to every peer including the host (`TEC-004`: the host
	# reports, each peer writes). One writer, on the one event, on each machine.
	RunFile.clear()
	# **Marked before anything is settled** (`M3-T08`, `DES-016`). LINEAGE tier,
	# so a death does not cost them — and awarding *before* `die()` is what makes
	# that true rather than merely intended.
	#
	# The host worked out what was earned, because it is the only peer that saw
	# the run; `GameState` is never networked (`TEC-004`), so what crosses is a
	# list of ids and each peer writes its own profile.
	# Whatever the run-over screen was saying, the run is now resolved and this
	# node is about to go away underneath it — or, in a probe, is not, which is
	# the case that would leave it standing over a live floor.
	_put_the_screen_away()
	for row: Variant in earned:
		var mark := row as Dictionary
		GameState.award(StringName(mark.get("id", "")), String(mark.get("who", "")))
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


## **The Shaft is the way down; the last floor's way out is the Deep Gate**
## (`M4-T01`, ADR-186).
##
## `DES-005` gave the run three ways out — the Waystone, the Shaft and the Deep
## Gate — and two of them did the same job. `MissionGraph.Role.SHAFT` has said
## *"the way down, **and out**"* since the graph was written, and this is the
## half that was never built: on floors 0 and 1 claiming the Shaft now takes the
## party **deeper**, and only the bottom of the expedition lets you leave.
##
## So the redundant pair resolves the other way round from the obvious one. The
## Waystone is not cut — it becomes the **only** early exit, which is what makes
## `DES-019`'s binary readout (*do I still have my out?*) the sharpest question
## on the HUD, and what keeps `DES-014`'s best payoff possible: you cannot give
## a teammate a Shaft.
##
## **The party goes together**, on `Threshold._take_the_party_down`'s precedent
## and for a harder reason than symmetry: peers cannot stand in different levels
## (ADR-102), so one body descending alone is not a thing the architecture can
## express. Extraction is a *state* for exactly that reason; a floor change is
## not, and cannot be.
func _on_shaft_claimed(player: Player) -> void:
	if not multiplayer.is_server():
		return
	# The bottom of the expedition. Nothing is under it, so the Shaft here is
	# the Deep Gate's mechanism and this is `DES-005`'s guaranteed way out.
	#
	# **Read off the Shaft, not recomputed.** The prompt the player reads comes
	# from `Shaft.leads_out`, and a second derivation here is how the pad's words
	# and the pad's behaviour drift apart.
	if _shaft != null and _shaft.leads_out:
		_on_extracted(player)
		return
	if _going_down:
		return
	_going_down = true
	print("[descent] %s took the party down from floor %d" % [
		player.name, _floor_index])
	_take_the_party_down.rpc()


## Each peer records its own body and its own Hunt, then walks into the hole.
##
## `call_local` so the host runs it in the frame it commits, and so solo takes
## the same path as a four-stack. **Each process writes its own run file** —
## `RunFile` is per-process like `GameState`, your bag is yours, and the values
## it reads are host-authoritative and replicated down (`Health:current` is
## `ON_CHANGE` on the state sync; the bag is pushed to its owner by
## `_push_bag`), so a peer recording its own body is copying the host rather
## than inventing anything.
@rpc("authority", "call_local", "reliable")
func _take_the_party_down() -> void:
	var body: Player = _session.local_player()
	var bag: Array = []
	var hurt: float = RunFile.UNHURT
	if body != null:
		bag = body.inventory.pack()
		hurt = body.health.current
	# **The Hunt comes with you** (ADR-037, `DES-017` Q9): *"descending grants
	# nothing — going quiet and shedding carried value can shake it, but a
	# staircase cannot."* Read off the Gullsjúkr rather than a clock, because
	# `Shaft._escalation` reads the same `age` and the price of leaving and the
	# pressure you feel have to come from one source.
	var age: float = _hunter.age if _hunter != null else 0.0
	RunFile.carry_down(bag, hurt, age)
	var to: int = RunFile.descend()
	print("[descent] floor %d → %d, carrying %d item(s) at %.0f hp, "
		% [_floor_index, to, bag.size(), hurt]
		+ "the Hunt %.0f s old" % age)
	if _probing:
		# The descent *happened*, which is what a probe reads. Changing scene
		# would free the node holding the assertion (ADR-138).
		return
	get_tree().change_scene_to_file("res://levels/room_set/room_set.tscn")


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
##
## **Reached from three places now** (`M4-T01`, ADR-186): a Waystone spent on any
## floor, the Deep Gate at the bottom, and — on the bottom floor only — the
## Shaft, which is the Gate's mechanism. On floors above the bottom the Shaft
## goes *down* instead and never arrives here.
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

	# **Bear my ember out** (`DES-012`, and `M3-T33` is where it became true).
	#
	# *"If your ember reaches an extraction point, your LIFE survives. You lose
	# the run, your carried loot, and take a Scar — but your skill tree, stash,
	# and Pact Rank are intact."*
	#
	# This was **a print**. The comment said so honestly — *reported rather than
	# enforced*, because there was no tree, stash or rank at `M2` — and then
	# `M3` built all three and nobody came back. `rescued` was connected by one
	# probe and by nothing else, which is ADR-098's question exactly: it fired,
	# and the only thing listening was the check that it fired.
	#
	# So a rescue cost the rescuer weight, noise and a worse extraction all the
	# way home, and bought the person it saved **nothing**: `_end_the_run` read
	# `body.spent` and wiped them anyway.
	for peer: int in player.inventory.embers():
		var saved: Player = _session.player_for(peer)
		var who: String = saved.name if saved != null else "peer %d" % peer
		print("[death] %s carried %s's ember out — their LIFE survives" % [
			player.name, who])
		_borne_out[peer] = true
		# **Delivered, so it is spent.** Left in the bag it rides home in
		# `carried`, turns up in the Chamber as a thing you can put on the pile,
		# and the pile is one-way (`DES-014`) — so the token for a life that has
		# already been saved becomes a thing you can throw away by accident.
		# Collected first: `items()` hands back the live array.
		var delivered: Array[int] = []
		for held: ItemInstance in player.inventory.items():
			if held.bound_to == peer:
				delivered.append(held.instance_id)
		for instance: int in delivered:
			player.inventory.remove(instance)
		rescued.emit(peer, player)

	extracted.emit(player, player.inventory.total_tribute())

	# **One player leaves; the run goes on** (`M3-T09`, ADR-102).
	#
	# This called `_end_the_run()` here, which is why `M2` ended the run for
	# everybody at the first extraction: peers cannot stand in different levels,
	# so the only way one player could be *out* was for the floor to stop
	# existing for all of them.
	#
	# Out is a **state** now. The body stays on the floor — safe, translucent,
	# unable to touch anything — and the run resolves when nobody is left in it.
	# Identical to before for a solo player, and materially different for a
	# party.
	player.got_out = true
	_settle_if_nobody_is_left()


## **What this body did, answered from what the run already knows** (`M3-T08`).
##
## `DES-016`'s rule for what may be a deed: *"conditions are evaluated by the run
## systems that already exist — extraction state, ember events, Clamor history,
## loot decisions. No bespoke tracking subsystems; if a deed needs new
## instrumentation, it's probably the wrong deed."*
##
## Every line below reads something the loop keeps for its own reasons. Nothing
## here added a field, and a deed that would have needed one was not written.
func _deeds_for(body: Player) -> Array:
	var earned: Array = []
	if body.spent:
		# Nothing is earned by a body that did not leave. `DES-016`'s categories
		# are all about a run you came back from, and the run you did not is
		# what the Legacy screen is for.
		return earned
	earned.append({"id": "ded_first_way_out", "who": ""})
	for peer: int in body.inventory.embers():
		var saved: Player = _session.player_for(peer)
		earned.append({"id": "ded_bore_them_home",
			"who": saved.name if saved != null else "peer %d" % peer})
	if body.inventory.count() == 0:
		earned.append({"id": "ded_empty_handed", "who": ""})
	if _the_prize_is_still_here():
		earned.append({"id": "ded_left_the_prize", "who": ""})
	var thread: DeedResource = DeedCatalogue.by_id(&"ded_by_a_thread")
	if thread != null and body.health.maximum > 0.0 \
			and body.health.current / body.health.maximum <= thread.threshold:
		earned.append({"id": "ded_by_a_thread", "who": ""})
	return earned


## Is the best thing down here still down here? Read off the floor rather than
## tracked, which is the whole of `DES-016`'s instrumentation rule: the world
## already knows, and asking it costs nothing.
func _the_prize_is_still_here() -> bool:
	for node: Node in get_tree().get_nodes_in_group("world_items"):
		var item := node as WorldItem
		if item == null or not is_instance_valid(item):
			continue
		# **Asked of the floor, not of a constant** (ADR-187). This read
		# `PRIZE_AT` — a coordinate in the hand-authored Deep — so on a generated
		# floor it measured 3 m from a place with nothing near it and answered
		# *no* every time. A deed that never fires is indistinguishable from a
		# deed nobody earned, which is why nothing would ever have reported it.
		if item.global_position.distance_to(_floor.prize()) < 3.0:
			return true
	return false


## Put the floor back, for the probes that need a second descent without a
## scene change in the middle of their measurement.
func _reset_floor() -> void:
	_descent += 1
	# A rescue belongs to the run it happened in (`M3-T33`). Carried past a
	# floor reset it would forgive a death on the next one, for free.
	_borne_out.clear()
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
		# **Off the floor, not off the Deep's constants** (ADR-187). These read
		# `SPAWNS` and `HUNTER_POST` directly, which is a body placed inside
		# whatever the generator built at those coordinates — and a body that
		# starts inside geometry does not move, which `M3-T22` spent a probe
		# learning to recognise.
		var marks: Array[Vector3] = _floor.spawns()
		player.teleport(marks[index % marks.size()], 0.0)
		index += 1
	if _hunter != null:
		_hunter.global_position = _floor.hunter()
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
	# Kept, so `--light-shot` can photograph the same floor at four ambient
	# values in one run. `floor_ambient_energy` is the number `M4-T13` exists
	# to lower and `DES-018` is the reason it cannot go to zero — that is a
	# decision to be made from images of a real floor, not from a constant that
	# looked reasonable in a diff.
	_environment = environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = PAPER
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = AMBIENT
	environment.ambient_light_energy = Config.tuning.floor_ambient_energy
	env.environment = environment
	_world.add_child(env)

	for at: Vector3 in _floor.door_lights():
		_door_light(at)


## A pale light in a doorway. **Where** they hang is the floor's business now
## (`FloorSource.door_lights`); what they look like is `ART-005`'s and stays
## here, so a generated floor and the Deep are lit by the same lamp.
func _door_light(at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = PALE
	light.light_energy = DOOR_LIGHT_ENERGY
	light.omni_range = DOOR_LIGHT_RANGE
	light.position = at
	light.add_to_group(DOOR_LIGHT_GROUP)
	# **And a doorway lamp is something you can be seen by** (`M4-T13`,
	# ADR-188). Two groups, two questions: `DOOR_LIGHT_GROUP` is *"did this
	# floor get lit"*, which `--sight-probe` asks of the level, and
	# `LIGHT_GROUP` is *"what can give a body away"*, which `Exposure` asks of
	# the world. Joining the second is what turns these from decoration into
	# terrain — a lit doorway is now somewhere you are visible standing, so
	# moving between the lamps rather than along them is a real way to cross a
	# floor with the shutter closed.
	light.add_to_group(Lantern.LIGHT_GROUP)
	_world.add_child(light)


func _spawn_actors() -> void:
	_session = SESSION_SCENE.instantiate() as CoopSession
	_session.spawn_points = _floor.spawns()
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
	# **Deliberately not `_on_party_changed`** (`M3-T35`, ADR-156). That one
	# grows the floor, and ADR-110's rule is that it never shrinks — despawning
	# an enemy somebody is fighting is a bug they can see. What a departure
	# changes is not the size of the floor, it is whether anyone is still in
	# the run.
	_session.player_left.connect(_on_peer_left)
	_session.floor_rank_changed.connect(_on_floor_rank_changed)


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
## **How badly is this floor actually walked?** (`M3-T22`, ADR-144)
##
## ADR-142 gave the Hunter a path and left three tuning questions open, each of
## which had been argued from a reading of the code rather than from a number:
## its collider is 0.75 against a mesh baked at 0.45, `Enemy.avoidance_enabled`
## is false, and steering drops to a straight line inside `DIRECT_RANGE`, which
## is wrong whenever a wall separates two points two metres apart.
##
## So this measures instead of asserting a threshold nobody has grounds for. One
## body starts in each room and walks to the exit **through its own real
## steering** — an `Enemy` returning `_home` is `_act`'s own unaware branch, not
## a path driven from outside — and every frame in contact with the world is
## counted.
##
## **Arrival is the claim; contacts are the diagnostic.** A body that never
## reaches its goal is stuck, and that is a fact about the floor rather than a
## number needing a baseline. The contact ratio is printed so a change can be
## compared against the run before it, which is what makes the three questions
## above answerable at `M4-T01` rather than guessable now.
func _walk_probe() -> void:
	await _hold(1.0)
	var problems: PackedStringArray = PackedStringArray()
	var goal: Vector3 = _room_centre("exit")
	var tuning: TuningProfile = Config.tuning

	# **Only the bodies this probe put down.** The floor already carries the
	# authored garrison, and measuring those as well produced nine rows for five
	# labels and a report nobody could read.
	var before: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var walkers: Array[Enemy] = []
	var from: PackedStringArray = PackedStringArray()
	for room: String in ROOMS:
		if room == "exit":
			continue
		# **Snapped to the mesh, not dropped on the centre.** Three rooms keep
		# their landmark at the exact centre — `LANDMARKS["west"]` is a
		# barricade at `(-9, -10)`, which is `_room_centre("west")` — so the
		# first version spawned a body *inside* the scenery, 0.82 m off the
		# navmesh against 0.16 m everywhere else, and reported it as a body
		# stuck on the floor's geometry. It was stuck on the probe's.
		var at: Vector3 = NavigationServer3D.map_get_closest_point(
			get_world_3d().get_navigation_map(), _room_centre(room))
		_session.spawn_enemy(at + Vector3(0.0, 0.1, 0.0), 0.0)
		await get_tree().process_frame
		for node: Node in get_tree().get_nodes_in_group("enemies"):
			var walker := node as Enemy
			if walker == null or before.has(node):
				continue
			before.append(node)
			walkers.append(walker)
			from.append(room)
			# `_home` rather than a chase: the unaware branch of `_act` walks a
			# body home through the same `_steer_toward` a hunt uses, so this
			# measures the shipped steering rather than a probe's idea of it.
			walker._home = goal

	var started: Array[Vector3] = []
	var contacts: Array[int] = []
	contacts.resize(walkers.size())
	for walker: Enemy in walkers:
		started.append(walker.global_position)

	# Long enough to cross the floor: `enemy_walk_speed` is 2 m/s and the far
	# corners are ~40 m apart, so four seconds — the first draft — measured
	# nothing but how far a body gets in eight metres.
	var frames: int = 1200
	for i: int in range(frames):
		await get_tree().physics_frame
		for w: int in range(walkers.size()):
			if not is_instance_valid(walkers[w]):
				continue
			# **Walls, not the floor.** `get_slide_collision_count() > 0` is
			# true every frame for anything standing on ground, which is how the
			# first run reported every body rubbing a wall 100% of the way. A
			# contact is a wall when its normal is roughly horizontal.
			for c: int in range(walkers[w].get_slide_collision_count()):
				if absf(walkers[w].get_slide_collision(c).get_normal().y) < 0.7:
					contacts[w] += 1
					break

	var stuck := PackedStringArray()
	for w: int in range(walkers.size()):
		if not is_instance_valid(walkers[w]):
			continue
		var left: float = walkers[w].global_position.distance_to(goal)
		var went: float = walkers[w].global_position.distance_to(started[w])
		var rubbing: float = 100.0 * float(contacts[w]) / maxf(float(frames), 1.0)
		# **And whether it was ever standing on the mesh.** A body that starts
		# off-navmesh gets no path at all and falls back to the straight line,
		# which walks it into the nearest wall and holds it there — so the first
		# question to ask about a stuck body is not about its steering.
		var agent := walkers[w].get_node_or_null("Nav") as NavigationAgent3D
		var drift: float = -1.0
		if agent != null and agent.get_navigation_map().is_valid():
			drift = started[w].distance_to(NavigationServer3D.map_get_closest_point(
				agent.get_navigation_map(), started[w]))
		print("[walk] %-10s went %5.1f m, %5.1f m short, scraping %4.1f%%, "
			% [from[w] if w < from.size() else "?", went, left, rubbing]
			+ "started %.2f m off the mesh" % drift)
		# **Progress, not arrival.** How far a body gets in a fixed time is a
		# function of speed and distance and says nothing on its own; a body that
		# moved less than its own width in twenty seconds is stuck, and that is
		# true whatever the clock says.
		if went < 1.0:
			stuck.append("%s (%.1f m)" % [from[w], went])
	print("[walk] stuck       %d of %d" % [stuck.size(), walkers.size()])
	if walkers.is_empty():
		problems.append("nothing was walked, so the rows above are about an "
			+ "empty floor")
	if stuck.size() > 0:
		problems.append(("%d of %d bodies never moved at all (%s) — they are "
			+ "held on the floor's own geometry, and unlike the scrape figure "
			+ "that is a fact rather than a number wanting a baseline")
			% [stuck.size(), walkers.size(), ", ".join(stuck)])

	_report(problems, "walk")


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

	# ─ 3. everything that chases you is carrying an agent bound to that map ─
	#
	# **Both groups** (ADR-142). This asked `"enemies"` and the Gullsjúkr is in
	# `"hunters"`, so the check about pursuit excluded the one body that pursues
	# you across the entire floor — and it had no agent at all, steering straight
	# at its goal and grinding along whatever stood between. Reported from play
	# as the Hunter getting stuck in walls; it was total, not intermittent.
	#
	# A group list rather than a single group, because that is the shape of the
	# fault: the next thing that walks the floor will arrive with a name of its
	# own, and a check naming one group silently exempts it.
	var chasers: Array[Node] = []
	for group: StringName in [&"enemies", &"hunters"]:
		chasers.append_array(get_tree().get_nodes_in_group(group))
	var agentless: int = 0
	var named := PackedStringArray()
	for node: Node in chasers:
		var agent := node.get_node_or_null("Nav") as NavigationAgent3D
		if agent == null or not agent.get_navigation_map().is_valid():
			agentless += 1
			named.append(node.name)
	print("[nav] chasers on the map         %d of %d" % [
		chasers.size() - agentless, chasers.size()])
	if chasers.is_empty():
		problems.append("nothing on this floor chases anybody, so the row "
			+ "below is about an empty list")
	# **And the census still reaches past the enemies.** Narrowing the group
	# list back would shrink this check in silence — the Hunter would simply
	# stop being counted, which is precisely how it went uncovered in the first
	# place. A hunter has to be in the count for the count to mean what it says.
	if get_tree().get_nodes_in_group(&"hunters").is_empty():
		problems.append("no hunter is in the census — either this floor has "
			+ "none, or the group list narrowed back to `enemies` and the one "
			+ "body that pursues you across the whole floor is exempt again")
	if agentless > 0:
		problems.append(("%d of %d bodies that chase you have no navigation "
			+ "agent on a valid map (%s) — the mesh exists and they are not "
			+ "reading it, which is ADR-098's question rather than ADR-097's")
			% [agentless, chasers.size(), ", ".join(named)])

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

	# **Hovering, because the state that breaks is the state nobody shot**
	# (ADR-140). Every bag screenshot ever taken had nothing under the cursor,
	# so `_draw_blurb` — the one region that draws *variable-height* text — has
	# never once appeared in a photograph. It overflowed its band into the
	# prompts underneath, and the first person to hover an item saw two lines of
	# text on top of each other.
	#
	# Through a real motion event, on `--bag-shot`'s own precedent above: the
	# bag reads `_cursor` from `_gui_input`, so assigning it from outside would
	# photograph a state the mouse cannot produce.
	var bag: BagScreen = player.get_node("BagLayer/BagScreen") as BagScreen
	var over := InputEventMouseMotion.new()
	over.position = bag.first_item_middle()
	bag.get_viewport().push_input(over)
	for i: int in range(4):
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

	# ─ 5. and swinging at it says something (`M3-T04`, ADR-118) ─
	#
	# Until now it had no `Hurtbox` at all, so a swing passed straight through
	# and produced nothing — which reads as a broken hitbox rather than a rule.
	# The assertion is about the **composition**, not the handler: the player's
	# real `Hitbox`, at its real layers, has to find the thing. A handler proved
	# by calling it directly proves only that it was called.
	var shrugs: Array[int] = []
	_hunter.shrugged.connect(func() -> void: shrugs.append(1))
	_hunter.global_position = player.global_position \
		- player.global_transform.basis.z * 0.9
	player.weapon.request_swing(player.stamina)
	await _hold(0.9)
	print("[toll] struck       %d shrug(s), killable=%s at rank %d" % [
		shrugs.size(), _hunter.killable(), GameState.pact_rank])
	if shrugs.is_empty():
		problems.append(("swinging at it did nothing at all — `DES-017` says "
			+ "you cannot kill it with damage and a player will certainly try, "
			+ "so the game has to answer with a refusal rather than silence"))
	if _hunter.killable():
		problems.append(("it reports killable at rank %d — nothing can raise a "
			+ "rank until `M3-T01`, so this can only mean the threshold is "
			+ "wrong or the rank is being set by something that should not")
			% GameState.pact_rank)

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
	# **Every peer descends with a run open, because every peer really does**
	# (`M3-T34`, ADR-155). `Threshold._descend` is `call_local`, so a real
	# party opens one run file per machine — and the scenario that walks a
	# party out of the floor had none at all, which is why nothing could see
	# that only one of them ever closed.
	#
	# Its own file, never the player's (ADR-145, ADR-152). Asserted rather than
	# trusted: this flag is deliberately not named `--probe` so the scene change
	# is real, and that spelling is exactly what used to get past `arm()`.
	RunFile.use_a_scratch_run()
	RunFile.arm()
	if RunFile.PATH == "user://run.active":
		printerr("[extract] FAIL this scenario is pointed at the player's run "
			+ "file and opens one below — a sweep would leave a run open in "
			+ "somebody's `user://` and the next launch would resume it")
		get_tree().quit(1)
		return
	RunFile.begin(GameState.class_id, GameState.pact_rank, 31346)
	print("[extract] %s opened a run, still open=%s" % [
		"host" if multiplayer.is_server() else "client", RunFile.exists()])
	await _hold(7.0)
	# **And the other half of what a descent does** (`M3-T36`, ADR-157).
	#
	# This scenario boots straight into the Deep, so `Threshold._descend` never
	# ran — and it already stands in for the half of it that matters by opening
	# a run file above. The door is the same kind of claim: these peers *are* a
	# party that has gone down, and a scenario that says so about one half and
	# not the other leaves the way home asserting a default.
	#
	# **After the hold, not before.** The first version shut it in `_ready`, and
	# a host that has gone down before its own party has assembled refuses the
	# clients this scenario is made of — the same mistake, one layer in, as
	# writing the rule about scenes instead of about the descent. Seven seconds
	# is this scenario's "everybody is here".
	#
	# Found by planting the camp's reopen: the row *the fire takes arrivals
	# again* passed with it deleted, because `_party_is_assembling` starts true
	# and nothing here had ever made it false — a row reading an initial value
	# rather than a decision.
	CoopSession.the_party_has_gone_down()
	print("[extract] %s is down, run open=%s, door shut=%s" % [
		"host" if multiplayer.is_server() else "client", RunFile.exists(),
		not CoopSession.taking_arrivals()])
	if not multiplayer.is_server():
		print("[extract] client waiting on the floor, party=%d"
			% _session.players().size())
		return
	print("[extract] host ready, party=%d" % _session.players().size())

	# **One at a time, host first** (`M3-T09`). This spent one Waystone and
	# expected the whole party home, which was the truth while extraction ended
	# the run for everybody — and is now the bug it would be hiding: a host that
	# leaves while its clients are still down there must **not** take the floor
	# with it.
	#
	# Driven host-side for every body rather than from each peer, because the
	# bag is the host's to grant (`M2-T19`) and a client adding to its own would
	# be writing a bag it does not own.
	# **Nothing on this floor is allowed to interrupt the measurement.** See
	# `_clear_the_floor`: the subject here is a scene change across three peers,
	# and a Waystone channel is interruptible by design.
	_clear_the_floor()
	await _hold(0.5)

	var bodies: Array[Player] = _session.players()
	var first: bool = true
	for body: Player in bodies:
		body.inventory.add(ItemCatalogue.by_id(&"glt_hoard_coin"))
		body.inventory.add(ItemCatalogue.by_id(&"con_waystone"))
		await _hold(0.5)
		body.ask_to_spend_waystone()
		# Long enough for the Waystone to finish channelling and for the floor
		# to *not* end, which is the half of this the old scenario could not
		# ask: everybody still here after the first one leaves.
		await _hold(_waystone_seconds() + 1.5)
		if first:
			first = false
			var still_in: int = 0
			for other: Player in _session.players():
				if not other.is_out():
					still_in += 1
			print("[extract] one out, %d still on the floor" % still_in)
		# **The last one out takes the floor with them** (ADR-117's trap).
		#
		# `_end_the_run` changes scene, and Godot detaches the outgoing scene
		# **synchronously** — so the next `await get_tree().physics_frame` in
		# this loop runs on a node whose tree is already gone: *"Cannot call
		# method 'get_nodes_in_group' on a null value"*. The scenario has to
		# notice it is no longer in the world it was measuring.
		if not is_inside_tree():
			return


## **The floor's half of the second descent** (`M3-T38`, ADR-160).
##
## First arrival: abandon, through the menu's own two presses rather than past
## them — `take_what_leaving_costs` is where the cost lives and a scenario that
## called it directly would prove the rule and not the button (`M2-T18`).
## Second arrival: there is nothing left to ask, so the walk is done.
##
## **The scenario keeps its own count, and the first draft did not.** Telling
## the two arrivals apart by `last_life` looked right — `die()` leaves the
## record and the Legacy screen clears it — and it walked the loop **forever**:
## answering the screen empties the record, so the second arrival looked exactly
## like the first and abandoned again. The record is a question the *game* asks
## and answers; how far along a scenario is, is the scenario's to know. Static,
## because a level is rebuilt on every descent and this outlives them.
static var _abandoned_once: bool = false


func _again() -> void:
	await get_tree().create_timer(2.0).timeout
	if _abandoned_once:
		print("[again] down a second time — the loop closes")
		get_tree().quit(0)
		return
	_abandoned_once = true

	var pause: PauseMenu = null
	for child: Node in get_children():
		var found := child as PauseMenu
		if found != null:
			pause = found
	if pause == null:
		printerr("[again] FAIL no way out of the Deep at all")
		get_tree().quit(1)
		return
	pause.open()
	await get_tree().process_frame
	if not pause.leaving_ends_the_life():
		printerr("[again] FAIL leaving the Deep is priced at nothing — a run "
			+ "is open and ADR-050 makes quitting cost what staying would")
		get_tree().quit(1)
		return
	var asks: Button = pause.way_out()
	if asks != null:
		asks.emit_signal("pressed")
	await get_tree().process_frame
	print("[again] abandoning the first run, confirming=%s" % pause.confirming())
	var ends: Button = pause.way_out()
	if ends != null:
		ends.emit_signal("pressed")


## **The last person standing leaves, and the run has to end** (`M3-T35`,
## ADR-156).
##
## The host goes out while a client is still on the floor — correct, and not a
## wipe, because somebody is standing. `run_doorway.py` then **kills the client
## process**, which is the event nothing was watching: a party can shrink by
## departure, and run resolution only ever heard about deaths and extractions.
##
## Two processes, because that is what the fault is made of. No single-process
## probe has a second peer to lose, which is exactly why `--wipe-probe` — which
## walks a two-body party all the way to a wipe — has always passed.
##
## Named without the word `probe` for `--extraction`'s reason: `_probing` swaps
## the scene change for `_reset_floor`, and *arriving at the Threshold* is the
## whole assertion. `RunFile` names it in `HARNESS_FLAGS`, so this cannot arm
## the player's run file.
func _abandoned() -> void:
	RunFile.use_a_scratch_run()
	RunFile.arm()
	if RunFile.PATH == "user://run.active":
		printerr("[left] FAIL this scenario is pointed at the player's run "
			+ "file and opens one below")
		get_tree().quit(1)
		return
	RunFile.begin(GameState.class_id, GameState.pact_rank, 31346)
	await _hold(7.0)
	if not multiplayer.is_server():
		print("[left] client standing on the floor, party=%d"
			% _session.players().size())
		return

	var mine: Player = _session.local_player()
	if mine == null:
		printerr("[left] FAIL no host body to send out")
		get_tree().quit(1)
		return
	print("[left] host going out with %d in the party"
		% _session.players().size())
	# The same two lines `--wipe-probe` uses to spend a body: damage past the
	# pool, then a bleed short enough to run out on the next tick.
	mine.health.apply_damage(mine.health.maximum * 2.0)
	await _hold(0.2)
	mine.bleeding = 0.02
	await _hold(Config.tuning.party_wipe_seconds + 1.5)
	# **Still here, and that is correct.** A party with somebody standing is not
	# a party that is gone (ADR-102), so the run must *not* have ended yet — and
	# saying so is what stops the row below being satisfied by a build that ends
	# a run the moment anybody goes out.
	print("[left] host is out, spent=%s, still in the Deep=%s, party=%d" % [
		mine.spent, is_inside_tree(), _session.players().size()])


## What a Waystone costs in seconds, read off the item rather than from a number
## typed beside the scenario — the channel is `ExtractionTrait`'s to say, and a
## harness carrying its own copy is a second source of truth that drifts.
func _waystone_seconds() -> float:
	var stone: ItemResource = ItemCatalogue.by_id(&"con_waystone")
	if stone == null:
		return 4.0
	for item_trait: ItemTrait in stone.traits:
		var extraction := item_trait as ExtractionTrait
		if extraction != null:
			return maxf(extraction.channel_seconds, 0.01)
	return 4.0


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
	if not watcher.is_hunting() or not saw_alive:
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




## **Is a rank-8 floor actually a different floor** (`M3-T10`, ADR-119)?
##
## `DES-022` is precise about what that means and what it must not mean: *"more
## things, worse things, and less time — not because a skeleton hits for 40
## instead of 12."* So this asserts the shape rather than any number: more
## enemies, an older Hunt, a Shaft closer to sealed — and **identical enemy
## stats**, which is the half the design would quietly lose first.
func _rank_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var base: int = ENEMY_POSTS.size()

	# ── density rises with rank, and the party axis still multiplies ─────
	var solo_one: int = RankScaling.denser(PartyScaling.enemies(base, 1), 1)
	var solo_eight: int = RankScaling.denser(PartyScaling.enemies(base, 1), 8)
	var four_one: int = RankScaling.denser(PartyScaling.enemies(base, 4), 1)
	var four_eight: int = RankScaling.denser(PartyScaling.enemies(base, 4), 8)
	print("[rank] density     solo %d→%d, four %d→%d (rank 1→8)" % [
		solo_one, solo_eight, four_one, four_eight])
	if solo_eight <= solo_one:
		problems.append(("a rank-8 floor holds no more than a rank-1 floor "
			+ "(%d vs %d) — ADR-010 exists so a veteran's session is not the "
			+ "same floor they cleared at rank 1") % [solo_eight, solo_one])
	if four_eight <= four_one or four_eight <= solo_eight:
		problems.append(("rank and party stopped multiplying (solo-8 %d, "
			+ "four-1 %d, four-8 %d) — they are independent axes and a floor "
			+ "has to answer both") % [solo_eight, four_one, four_eight])

	# ── the Hunt starts older, which is also how Shafts seal sooner ──────
	var age_one: float = RankScaling.hunt_age(1)
	var age_eight: float = RankScaling.hunt_age(8)
	var seal: float = Config.tuning.shaft_seal_seconds
	print("[rank] the hunt    %.0f s → %.0f s old, %.0f%% → %.0f%% sealed" % [
		age_one, age_eight, 100.0 * age_one / seal, 100.0 * age_eight / seal])
	if age_eight <= age_one:
		problems.append(("a rank-8 floor's Hunt is no older than a rank-1 "
			+ "floor's (%.0f s vs %.0f s) — `DES-022` asks for it sooner and "
			+ "faster") % [age_eight, age_one])
	# The good half: `Shaft._escalation` divides that same age by
	# `shaft_seal_seconds`, so this needs no second number to be true. If it
	# ever stops being true, someone gave the Sealing a clock of its own.
	if age_eight / seal <= age_one / seal:
		problems.append(("the Shafts on a rank-8 floor are no closer to sealed "
			+ "— `DES-022`'s Time axis comes free from the Hunt's age, and it "
			+ "coming free is the reason there is no second timer to drift"))

	# **And there is still a decision at the top of the game.**
	#
	# `_escalation` clamps at 1.0, so a floor whose Hunt starts past
	# `shaft_seal_seconds` arrives with the Shaft *already at maximum cost* —
	# not locked (ADR-053's note is right that a locked Shaft is a trap), but
	# flat. Leaving early and leaving late cost the same, and `DES-005`'s whole
	# tension is the gap between them. That is the product (principle 1), and a
	# rank that deletes it has made the endgame simpler rather than harder.
	#
	# The first value tried, 45 s per rank, did exactly this: rank 8 opened at
	# **105% sealed**. The probe is what said so.
	var top: int = Config.tuning.tithe_by_rank.size()
	var at_top: float = RankScaling.hunt_age(top) / seal
	print("[rank] top of tree  rank %d opens %.0f%% sealed, %.0f%% of the "
		% [top, 100.0 * at_top, 100.0 * (1.0 - at_top)] + "climb left")
	if at_top >= 1.0:
		problems.append(("a rank-%d floor opens with its Shafts already at "
			+ "maximum cost (%.0f%%) — leaving early and leaving late then "
			+ "cost the same, and `DES-005`'s decision stops existing exactly "
			+ "where the game is supposed to be hardest") % [top, 100.0 * at_top])

	# ── and nothing hits harder (`DES-022`'s actual rule) ────────────────
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
	var tuning: TuningProfile = Config.tuning
	var damage_seen: Array[float] = []
	for node: Node in enemies:
		var body := node as Enemy
		if body != null and body.health != null:
			damage_seen.append(body.health.maximum)
	var spread: bool = damage_seen.size() > 0
	for value: float in damage_seen:
		if not is_equal_approx(value, damage_seen[0]):
			spread = false
	print("[rank] fixed stats %d enemy(s), health all %.0f = %s, telegraph %.2f s" % [
		damage_seen.size(), damage_seen[0] if damage_seen.size() > 0 else 0.0,
		spread, tuning.enemy_telegraph])
	if not spread:
		problems.append(("enemies on this floor do not share one stat line — "
			+ "`DES-022`'s rule is fixed stats per archetype, and a rank that "
			+ "reaches the numbers is the trivialisation treadmill `CLAUDE.md` "
			+ "names as an anti-goal"))

	# ── the highest rank present is the floor (ADR-010) ──────────────────
	_session.declare_descent(1, "", PackedStringArray(), {}, [], RunFile.UNHURT)
	var alone: int = _session.floor_rank()
	_session._ranks[9001] = 8
	var with_veteran: int = _session.floor_rank()
	_session._ranks.erase(9001)
	print("[rank] whose rank   alone %d, with a rank-8 friend %d" % [
		alone, with_veteran])
	if with_veteran != 8:
		problems.append(("a party containing a rank-8 player built a rank-%d "
			+ "floor — ADR-010 scales to the highest present because boredom "
			+ "is worse than danger, and scaling down wastes the veteran's "
			+ "session and breaks their Tithe math") % with_veteran)

	_report(problems, "rank")


## **She settles before the floor is built** (`M3-T04`, ADR-124).
##
## ADR-118 shipped the Tithe soft-fail and it never once reached the floor it
## was written for. `settle_cycle()` decides how much Hunt a missed cycle buys
## her; `_build_hunt()` is what a Gullsjúkr is made by — and the settle ran
## **seventeen lines later**, so the head start consumed on any given descent
## was the *previous* one's, and the four minutes she had just sent for waited
## for the next floor. That is a punishment landing on a cycle the player may
## well have paid, which is `PRO-005` §5's unexplainable difficulty with a
## paper trail.
##
## Every piece had a check. `--tithe-probe` drives `settle_cycle` and
## `take_hunt_head_start` in the Chamber and asserts both, correctly.
## `--rank-probe` reads `hunt_age` off a floor and asserts it, correctly. What
## nothing asked is whether the **order** in `_ready` lets one reach the other,
## and that is the sixth time this milestone that the parts were right and the
## join was not built.
##
## So this probe boots the level for real and reads what the floor did.
func _creditor_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var tuning: TuningProfile = Config.tuning
	var owed: float = tuning.tithe_missed_head_start

	print("[creditor] she was owed        %.0f s of Hunt" % owed)
	print("[creditor] the floor took      %.0f s" % _she_sent_it_early)
	if _she_sent_it_early < owed:
		problems.append(("the floor opened having taken %.0f s of a %.0f s head "
			+ "start — `settle_cycle()` has to run *before* `_build_hunt()`, or "
			+ "what a floor consumes is the previous descent's debt and the one "
			+ "she just sent for lands on the next run instead")
			% [_she_sent_it_early, owed])

	# **Nothing is still owed.** The other half of the same fault: if the
	# settle runs after the build, this reads full rather than empty, because
	# she decided and nothing was there to hear it.
	print("[creditor] still owed after    %.0f s (want 0)"
		% GameState.hunt_head_start)
	if GameState.hunt_head_start > 0.0:
		problems.append(("%.0f s of Hunt is still owed after the floor was "
			+ "built — she has settled and nothing spent it, which is the "
			+ "ordering fault seen from the other side")
			% GameState.hunt_head_start)

	# And it is really on the Hunt, not merely in a variable this level kept.
	if _hunter == null:
		problems.append("no Gullsjúkr, so nothing here is about a Hunt")
	else:
		print("[creditor] the Hunt opens at   %.0f s old" % _hunter.age)
		if _hunter.age < owed:
			problems.append(("the Gullsjúkr opened %.0f s old against %.0f s "
				+ "owed — the level read the debt and did not hand it to the "
				+ "thing it is about") % [_hunter.age, owed])

	# **The slate cleared**, so the next cycle starts from nothing (ADR-118).
	print("[creditor] cycle after settle  %d run(s) in, %d paid (10 going in)" % [
		GameState.cycle_runs, GameState.tithe_paid])
	if GameState.cycle_runs != 0 or GameState.tithe_paid != 0:
		problems.append(("the cycle did not reset (%d runs, %d paid) — unpaid "
			+ "value carrying is ADR-029's running-debt spiral, which ADR-118 "
			+ "rejected because node reclamation is `M3-T01`")
			% [GameState.cycle_runs, GameState.tithe_paid])

	_report(problems, "creditor")


## **The Stalker** (`M3-T11`, `DES-011`, ADR-123).
##
## `DES-011` defines the Veiðimaðr by two things the game did not have — a bow
## and a trap — and by one sentence that is the reason the verb exists at all:
## *"including against the Hunter, the only reliable way to buy time during the
## Sealing."* Everything below is that sentence and the claims it rests on.
##
## **Every "it stopped" assertion carries a control**, measured on the same body
## moments earlier. A held enemy that never had anywhere to go is a probe that
## cannot fail, and this milestone has already produced four of those.
func _stalker_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var player: Player = _session.local_player()
	var tuning: TuningProfile = Config.tuning

	# ─ 1. the bow is in the hand because the **kit** says so ─
	#
	# The body was built from the spawn payload with `class_id` already set
	# (see `_ready`), so this is the real route a class reaches a body by, not
	# a field this probe assigned.
	print("[stalker] sworn                    %s" % player.sworn)
	if player.sworn != &"veidimadr":
		problems.append("the body is sworn to '%s' — nothing below is about a "
			% player.sworn + "Veiðimaðr, so stop here rather than report on it")
		_report(problems, "stalker")
		return
	print("[stalker] bow in hand              %s   melee visible %s" % [
		"yes" if player.ranged != null else "NO",
		"yes" if player.weapon.visible else "no"])
	if player.ranged == null:
		problems.append("a Veiðimaðr has no bow — `ClassResource.kit` is what "
			+ "arms a class (ADR-123), and a kit that arms nobody is a list of "
			+ "ids in a file")
		_report(problems, "stalker")
		return
	if player.weapon.visible:
		problems.append("the blade is still shown on a body that cannot swing "
			+ "it — a visible weapon that does nothing is the most direct lie a "
			+ "blockout can tell a playtester (ADR-064)")
	# The other half of "the kit decides": a class with no ranged item in its
	# kit gets no bow. Asserted against the data rather than by building a
	# second body, because the claim is about the kit.
	var shield_class: ClassResource = ClassCatalogue.by_id(&"huskarl")
	var huskarl_armed: bool = false
	for id: StringName in shield_class.kit:
		var definition: ItemResource = ItemCatalogue.by_id(id)
		if definition != null and definition.has_trait(RangedTrait):
			huskarl_armed = true
	print("[stalker] huskarl kit has a bow    %s (want no)"
		% ("YES" if huskarl_armed else "no"))
	if huskarl_armed:
		problems.append("the Húskarl's kit carries a ranged weapon, so 'the kit "
			+ "decides' is untestable here — every class would have a bow")

	# ─ 2. the draw commits, and clears ADR-053's floor in wall-clock time ─
	player.restore_for_descent()
	# **Inside the entrance room, with room to shoot across it.** The first
	# draft measured from `SPAWNS[0]` and put its targets 8 and 14 m along +Z —
	# which is past the wall at z = 10. Everything it spawned fell out of the
	# world, and it reported an enemy "moving" 34 m in a second and an arrow
	# that missed. Every distance below is checked against `ROOMS.entrance`.
	player.teleport(ARCHER_POST, 0.0)
	await _hold(0.3)
	var began: int = Time.get_ticks_msec()
	player.ranged.request_draw(player.stamina)
	var refused_mid_draw: bool = not player.ranged.request_draw(player.stamina)
	var drew_ms: int = 0
	while player.ranged.phase() == RangedWeapon.Phase.DRAWING:
		await get_tree().physics_frame
		drew_ms = Time.get_ticks_msec() - began
	var bow: RangedTrait = player.ranged.kit()
	print("[stalker] draw                    %4d ms   floor  250, expected %4d"
		% [drew_ms, int(bow.draw_seconds * 1000.0)])
	if drew_ms < 250:
		problems.append(("a draw took %d ms — ADR-053's 250 ms floor is about a "
			+ "telegraph an enemy can read, and a drawn bow is one") % drew_ms)
	print("[stalker] second press mid-draw    %s (want refused)"
		% ("refused" if refused_mid_draw else "ACCEPTED"))
	if not refused_mid_draw:
		problems.append("a second press during the draw was accepted — "
			+ "`DES-009` says attacks commit, and a bow that can be re-drawn "
			+ "mid-draw commits to nothing")
	while player.ranged.is_busy():
		await get_tree().physics_frame

	# ─ 3. an arrow wounds what it meets, and never the person who loosed it ─
	_session.clear_enemies()
	await _hold(0.4)
	player.teleport(ARCHER_POST, 0.0)
	await _hold(0.3)
	var mark: Vector3 = BUTT_POST
	# Facing away, so it is standing still when the arrow arrives. It does not
	# stay that way — an arrow landing at its feet is 3.2 of Clamor and it
	# comes looking, which is the coupling working rather than a flaw here.
	_session.spawn_enemy(mark, PI)
	await _hold(1.0)
	var target: Enemy = _first_live_enemy()
	if target == null:
		problems.append("no enemy spawned, so nothing here is about what an "
			+ "arrow does when it arrives")
		_report(problems, "stalker")
		return
	var before_hp: float = target.health.current
	var shot: Vector3 = (target.global_position - player.global_position)
	shot.y = 0.0
	# Through the body's own host-side handler rather than straight at the
	# session, so what is measured is the seam a player uses: the aim is the
	# shooter's, the origin is the host's copy of them, and `clamor_loose` is
	# charged to the archer. Calling `spawn_arrow` directly would have skipped
	# the archer's own noise and made the comparison below unlosable.
	#
	# **Peaks, sampled per frame, not a reading taken afterwards.** The field
	# decays continuously, and the first draft asked it 2.6 s later and got
	# 0.00 at both ends — a true measurement of an empty field, and evidence of
	# nothing whatever.
	var archer_peak: float = 0.0
	var mark_peak: float = 0.0
	player._loose_arrow(shot.normalized())
	# **Both ends measured the same way, over a neighbourhood.** `ClamorField`
	# is a 2 m grid and an arrow stops at the *surface* of a hurtbox — here,
	# 0.17 m short of the body, and one cell over. Asking a single coordinate
	# read 0.06 where 3.2 had just been deposited next door, which is a true
	# answer about the wrong cell and cost three passes to see.
	for i: int in range(120):
		await get_tree().physics_frame
		archer_peak = maxf(archer_peak, _peak_near(ARCHER_POST))
		mark_peak = maxf(mark_peak, _peak_near(mark))
	var hurt: float = before_hp - target.health.current
	print("[stalker] arrow into an enemy     %5.1f damage  (bow says %.0f)"
		% [hurt, bow.damage])
	if hurt <= 0.0:
		problems.append("an arrow arrived and did nothing — the mask is "
			+ "`ENEMY_HURTBOX | PLAYER_HURTBOX` and deliberately not `WORLD`, so "
			+ "a miss here is a hurtbox it cannot see rather than a wall")

	# **Your own arrow is not a way to die** — tested at the guard, with a
	# control, because "0 damage" and "it never arrived" are the same reading.
	#
	# One arrow fired *at* the archer from across the room carrying their own
	# peer id, then the identical arrow carrying somebody else's. Without the
	# second, deleting the shooter-skip entirely would still read as a pass.
	# Deliberately not loosed at your own feet: the muzzle sits half a metre
	# ahead of the head, so an arrow dropped from there is past the body in two
	# physics frames and proves nothing either way.
	var from_side: Vector3 = player.global_position + Vector3(4.0, 1.2, 0.0)
	var inward: Vector3 = Vector3(-1.0, 0.0, 0.0)
	var mine: int = player.get_multiplayer_authority()
	var self_hp: float = player.health.current
	_session.spawn_arrow(from_side, inward, bow, mine)
	await _hold(0.8)
	var self_hurt: float = self_hp - player.health.current
	var stranger_hp: float = player.health.current
	_session.spawn_arrow(from_side, inward, bow, mine + 1)
	await _hold(0.8)
	var stranger_hurt: float = stranger_hp - player.health.current
	print("[stalker] arrow at you  yours %5.1f   somebody else's %5.1f"
		% [self_hurt, stranger_hurt])
	if self_hurt > 0.0:
		problems.append(("an archer took %.0f from their own arrow — that is an "
			+ "unexplainable death (`PRO-005` §5) with a very silly cause")
			% self_hurt)
	if stranger_hurt <= 0.0:
		problems.append("an arrow from another peer passed through the player "
			+ "harmlessly, so the row above says nothing — it would read 0.00 "
			+ "for an arrow that simply never arrived")

	# ─ 4. **the noise happens over there** — the whole tactic ─
	print("[stalker] clamor at the impact    %5.2f   at the archer %5.2f"
		% [mark_peak, archer_peak])
	if archer_peak <= 0.0:
		problems.append("loosing cost the archer no noise at all, so the "
			+ "comparison below is against nothing — `clamor_loose` is small on "
			+ "purpose, not absent")
	if mark_peak <= archer_peak:
		problems.append(("the shot was as loud where it was fired (%.2f) as "
			+ "where it landed (%.2f) — `clamor_hit` above `clamor_loose` is "
			+ "the entire reason a Stalker carries a bow, and it is the same "
			+ "misdirection `DES-005` sells thrown loot on")
			% [archer_peak, mark_peak])

	# ─ 5. a Snare holds an enemy that is **trying to get somewhere** ─
	#
	# The control is the same body, in the same chase, moments later. An
	# earlier draft spawned an enemy and measured it before snaring — and it
	# had already closed to 2.16 m and stopped, so "it did not move" was true
	# of a body standing in attack range. That assertion could not fail.
	# Before/after on one body cannot have that problem: the free window is
	# the proof that the held window meant something.
	_session.clear_enemies()
	await _hold(0.4)
	player.restore_for_descent()
	player.teleport(ARCHER_POST, 0.0)
	await _hold(0.3)
	_session.spawn_enemy(ARCHER_POST + Vector3(0.0, 0.0, 3.0), 0.0)
	await _hold(1.6)
	var chaser: Enemy = _first_live_enemy()
	if chaser == null:
		problems.append("no enemy to snare")
		_report(problems, "stalker")
		return
	# Give it a reason to travel: the thing it is chasing walks away.
	var trap_at: Vector3 = chaser.global_position
	var trap: Snare = _session.spawn_snare(trap_at, player.get_multiplayer_authority())
	await _hold(0.15)
	chaser.global_position = trap_at
	player.teleport(BUTT_POST, 0.0)
	await _hold(0.4)
	var window: float = minf(tuning.snare_hold_seconds * 0.5, 1.5)
	var held_from: Vector3 = chaser.global_position
	var trap_peak: float = 0.0
	var until: int = Time.get_ticks_msec() + int(window * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().physics_frame
		trap_peak = maxf(trap_peak, _peak_near(trap_at))
	var held_moved: float = held_from.distance_to(chaser.global_position)
	var caught: bool = trap.sprung
	print("[stalker] trap sprung             %s" % ("yes" if caught else "NO"))
	if not caught:
		problems.append("a body walked into the trap and it did not fire — the "
			+ "mask is `ENEMY_BODY` and both movers carry that layer")
	# Wait out the hold, then run the identical window with nothing holding it.
	# **Bounded**, not `while held()`: an unbounded wait in a probe hangs
	# instead of failing, which is worse than a wrong answer — the first draft
	# of this line ran the harness for ten minutes and reported nothing.
	var let_go: bool = await _wait_out(chaser.rooted, tuning.snare_hold_seconds * 2.0, false)
	print("[stalker] released after the hold %s" % ("yes" if let_go else "NO"))
	if not let_go:
		problems.append(("still held after %.1f s of a %.1f s hold — a root that "
			+ "does not end is a stun-lock, which is the no-counter-play answer "
			+ "`PRO-005` §5 rules out") % [tuning.snare_hold_seconds * 2.0,
			tuning.snare_hold_seconds])
	# **The control window must not land on a swarm call** (`M4-T16`, ADR-196).
	# By this point the body has held the player far longer than
	# `enemy_swarm_after`, so the first thing it does on release is stand still
	# and shout for `enemy_swarm_telegraph` — most of `window`. The control then
	# reads 0.00 m for a reason that has nothing to do with the snare, and the
	# vacuity guard below fires on a healthy build. It did, which is that guard
	# working exactly as written.
	#
	# Reset rather than waited out: waiting swapped this confound for the older
	# one recorded above, since the extra second let the body close the last of
	# the distance and start swinging. Zeroing the clock leaves the measurement
	# where it was designed — the instant of release — and only removes the one
	# variable this probe is not about.
	chaser.reset_alert_clock()
	var free_from: Vector3 = chaser.global_position
	await _hold(window)
	var free_moved: float = free_from.distance_to(chaser.global_position)
	print("[stalker] enemy over %.1f s  snared %5.2f m   then free %5.2f m"
		% [window, held_moved, free_moved])
	if free_moved < 0.5:
		problems.append(("released, it covered %.2f m in the same window, so it "
			+ "was not going anywhere either way and 'it stopped' says nothing "
			+ "— this assertion cannot fail as written") % free_moved)
	if held_moved > free_moved * ROOTED_SHARE:
		problems.append(("a snared enemy covered %.2f m against %.2f m free — "
			+ "`DES-011` sells the Snare as *hold*, and a trap that leaves a "
			+ "body moving is a slow, not a root") % [held_moved, free_moved])

	# It is loud where the trap is. The Stalker's one loud act, and it is what
	# makes setting a trap in your own doorway a mistake you can make.
	print("[stalker] clamor at the trap      %5.2f" % trap_peak)
	if trap_peak <= 0.0:
		problems.append("a Snare fired silently — `snare_clamor_trigger` is "
			+ "the Stalker's one loud act, and a trap that costs no noise is a "
			+ "free escape rather than a trade")

	# ─ 6. **and it holds the Hunter**, which is the sentence the verb is for ─
	if _hunter == null:
		problems.append("no Gullsjúkr on this floor, so the one claim `DES-011` "
			+ "makes about the Snare is untested")
	else:
		# Somewhere to be going: a pile of noise it can hear, at the far post.
		_hunter.global_position = ARCHER_POST
		_field.deposit(BUTT_POST, tuning.clamor_field_maximum)
		await _hold(0.6)
		var hunter_trap_at: Vector3 = _hunter.global_position
		var hunter_trap: Snare = _session.spawn_snare(hunter_trap_at,
			player.get_multiplayer_authority())
		await _hold(0.15)
		_hunter.global_position = hunter_trap_at
		await _hold(0.4)
		# **Read now, not later.** A sprung trap lingers `LINGER` seconds and
		# then frees itself, and the wait below outlives that — the first draft
		# asked a freed node whether it had fired.
		var hunter_caught: bool = hunter_trap.sprung
		var hunter_held_from: Vector3 = _hunter.global_position
		await _hold(window)
		var hunter_held: float = hunter_held_from.distance_to(_hunter.global_position)
		var hunter_let_go: bool = await _wait_out(_hunter.rooted,
			tuning.snare_hold_seconds * 2.0, true)
		if not hunter_let_go:
			problems.append("the Gullsjúkr was still held after twice the hold "
				+ "— a Hunter that can be parked is not a Hunter")
		var hunter_free_from: Vector3 = _hunter.global_position
		var free_until: int = Time.get_ticks_msec() + int(window * 1000.0)
		while Time.get_ticks_msec() < free_until:
			await get_tree().physics_frame
			_field.deposit(BUTT_POST, tuning.clamor_field_maximum)
		var hunter_free: float = hunter_free_from.distance_to(_hunter.global_position)
		print("[stalker] hunter over %.1f s snared %5.2f m   then free %5.2f m"
			% [window, hunter_held, hunter_free])
		if not hunter_caught:
			problems.append("the Gullsjúkr walked into a Snare and it did not "
				+ "fire — `DES-011` calls this *the only reliable way to buy "
				+ "time during the Sealing*, and it is the reason for the verb")
		if hunter_free < 0.4:
			problems.append(("released, the Gullsjúkr covered %.2f m in the same "
				+ "window — it was not hunting either way, so the comparison is "
				+ "between two kinds of standing still") % hunter_free)
		if hunter_held > hunter_free * ROOTED_SHARE:
			problems.append(("a snared Gullsjúkr covered %.2f m against %.2f m "
				+ "free — the seconds it does **not** move are the whole "
				+ "product, and a Hunter that is merely slowed has not bought "
				+ "anybody a Sealing") % [hunter_held, hunter_free])

	# ─ 7. it never catches your own party ─
	#
	# On an empty floor, deliberately: the point is what the *player* does to a
	# trap, and an enemy wandering into frame would spring it and leave this
	# reading about somebody else. The first draft skipped that and read a trap
	# that had already been sprung, lingered out and freed.
	_session.clear_enemies()
	if _hunter != null:
		_hunter.global_position = Vector3(0.0, 0.1, -22.0)
	player.teleport(ARCHER_POST, 0.0)
	await _hold(0.5)
	var friendly_at: Vector3 = player.global_position + Vector3(2.0, 0.0, 0.0)
	var friendly: Snare = _session.spawn_snare(friendly_at,
		player.get_multiplayer_authority())
	await _hold(0.6)
	player.teleport(friendly_at + Vector3(0.0, 0.1, 0.0), 0.0)
	await _hold(0.8)
	if not is_instance_valid(friendly):
		problems.append("the trap was gone before the player reached it, so "
			+ "this says nothing about who a Snare catches — something sprang "
			+ "it and it lingered out")
		_report(problems, "stalker")
		return
	print("[stalker] player stands in a trap %s (want unsprung)   mask %d"
		% ["SPRUNG" if friendly.sprung else "unsprung", friendly.collision_mask])
	if friendly.sprung:
		problems.append("a Snare caught the player who set it — the mask is "
			+ "`ENEMY_BODY` precisely so there is no 'except teammates' rule to "
			+ "get wrong, which is the argument `BULWARK` already settled")
	# **The layer is asserted, not only the outcome.** The row above passes for
	# two reasons and cannot tell them apart: adding `PLAYER_BODY` to the mask
	# leaves it unsprung anyway, because `_on_stepped_in` also bails on a body
	# with no `Rooted` and a player has none. That fallback is correct — a body
	# that grew a layer and not a component should walk through rather than
	# crash — but it is **not** what the design leans on. The layer is, and a
	# claim resting on its second line of defence is one nobody is watching.
	if (friendly.collision_mask & CollisionLayers.PLAYER_BODY) != 0:
		problems.append(("a Snare is watching `PLAYER_BODY` (mask %d). Nothing "
			+ "visible happens today because a player carries no `Rooted`, so "
			+ "the exclusion is resting on a fallback instead of on the layer — "
			+ "and the first body given one would start catching the party")
			% friendly.collision_mask)

	# ─ 8. **one live at a time** ─
	#
	# Through `_place_snare`, so this is the seam a player actually uses — the
	# body tells the host, the host tells the session, and the session is what
	# clears the old one (ADR-112).
	player._place_snare(player.global_position + Vector3(2.0, 0.0, 0.0))
	await _hold(0.4)
	player._place_snare(player.global_position + Vector3(4.0, 0.0, 0.0))
	await _hold(0.6)
	var live: int = 0
	for node: Node in get_tree().get_nodes_in_group(&"snares"):
		var one := node as Snare
		if one != null and is_instance_valid(one) and not one.is_queued_for_deletion() \
				and one.placer == player.get_multiplayer_authority() and not one.sprung:
			live += 1
	print("[stalker] live traps for one peer %4d   (want 1)" % live)
	if live != 1:
		problems.append(("%d unsprung traps belong to one peer — one live at a "
			+ "time is what makes the Snare a decision about *where* rather "
			+ "than a resource to count, and it is why it needs no ammunition "
			+ "economy to exist") % live)

	_report(problems, "stalker")


## The loudest cell within one of a point.
##
## `ClamorField` is a 2 m grid, and the things measured here land at the
## *surface* of a body rather than at its origin — routinely the neighbouring
## cell. A single-coordinate reading is a true answer about the wrong cell, and
## it reported an arrow's 3.2 as 0.06 for three passes of this probe. Both ends
## of every comparison below go through this, so the window never favours one.
func _peak_near(at: Vector3) -> float:
	var here: Vector2i = _field.cell_at(at)
	var best: float = 0.0
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			best = maxf(best, _field.level_in(here + Vector2i(dx, dy)))
	return best


## Wait for a hold to end, with a ceiling. Returns whether it did.
##
## `keep_calling` re-deposits at the far post every frame, because the thing
## being waited on has to still *want* to travel when it is let go — otherwise
## the free window that the held window is measured against is a body with
## nowhere to go, which is the failure this whole section was rewritten for.
func _wait_out(held_by: Rooted, seconds: float, keep_calling: bool) -> bool:
	var until: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().physics_frame
		if keep_calling:
			_field.deposit(BUTT_POST, Config.tuning.clamor_field_maximum)
		if not held_by.held():
			return true
	return not held_by.held()


## The first enemy that is really there. Repeated in three probes before this
## one; kept local rather than shared because the older three each also filter
## on something of their own.
func _first_live_enemy() -> Enemy:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var found := node as Enemy
		if found != null and is_instance_valid(found) and found.is_inside_tree() \
				and found.state() != Enemy.State.DEAD:
			return found
	return null


## **Six slots, and what they change** (`M3-T07`, `DES-020`).
##
## Until this task `WieldableTrait` had **no reader anywhere in the game**
## (ADR-124 §2): four weapons carried a full windup/active/recovery/damage/reach
## block and every swing came from `TuningProfile.swing_*`. Three of thirteen
## items were strictly negative objects — real weight, real squares, no
## function — and one of them, `wpn_seax`, was the reward for the west bypass
## route ADR-032 designed.
func _gear_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var player: Player = _session.local_player()
	var gear: Equipment = player.equipment

	# ─ 0. **the body arrived armed**, without anybody equipping it here ─
	#
	# The row the two-process smoke needed and nothing had: every other check
	# in this probe equips explicitly first, so all of them would pass on a
	# body that descends with empty hands.
	var arrived: ItemInstance = gear.in_slot(Enums.Slot.MAIN_HAND)
	print("[gear] descended holding  '%s' as '%s'" % [
		arrived.definition.id if arrived != null else "NOTHING", player.sworn])
	if arrived == null:
		problems.append(("a body reached the Deep with empty hands as '%s' — "
			+ "`DES-020` puts the class kit in slots, and a descent that arms "
			+ "nobody is one where the class resource is decoration")
			% player.sworn)

	# ─ 1. the kit is worn, and the hand knows it ─
	var seax: ItemResource = ItemCatalogue.by_id(&"wpn_seax")
	var blade := seax.first_trait(WieldableTrait) as WieldableTrait
	gear.clear()
	gear.equip(ItemInstance.of(seax, 0))
	await _hold(0.2)
	print("[gear] main hand          '%s', weapon holds %s" % [
		gear.in_slot(Enums.Slot.MAIN_HAND).definition.id,
		"it" if player.weapon.held() == blade else "SOMETHING ELSE"])
	if player.weapon.held() != blade:
		problems.append(("the main hand holds a seax and `MeleeWeapon` is "
			+ "swinging something else — `WieldableTrait` had no reader at all "
			+ "before this task, and this is the line that gives it one"))

	# ─ 2. **the weapon's own numbers**, not the profile's ─
	#
	# The seax is 15 damage and 0.9 m of reach; the tuning generic it replaced
	# was 25 and 2.2. Asserting they *differ* is what proves the item is being
	# read at all — equal numbers would pass whichever source won.
	player.stamina.refill()
	var began: int = Time.get_ticks_msec()
	player.weapon.request_swing(player.stamina)
	while player.weapon.phase() == MeleeWeapon.Phase.WINDUP:
		await get_tree().physics_frame
	var windup_ms: int = Time.get_ticks_msec() - began
	print("[gear] seax windup        %4d ms   the item says %4d, the profile %4d"
		% [windup_ms, int(blade.windup * 1000.0),
		int(blade.windup * 1000.0)])
	if absi(windup_ms - int(blade.windup * 1000.0)) > 60:
		problems.append(("a swing took %d ms and the weapon says %d — the hand "
			+ "is not reading the item, so every weapon in the game is the same "
			+ "weapon") % [windup_ms, int(blade.windup * 1000.0)])
	while player.weapon.is_busy():
		await get_tree().physics_frame

	# ─ 3. empty hands do not swing ─
	#
	# `DES-009` names five verbs and none of them is a punch, so there is
	# nothing to fall back to. A body that swung with nothing in its hand would
	# be an invented sixth verb (ADR-064).
	gear.clear()
	await _hold(0.2)
	player.stamina.refill()
	var swung_empty: bool = player.weapon.request_swing(player.stamina)
	print("[gear] empty hands        swing accepted=%s (want false)" % swung_empty)
	if swung_empty or player.weapon.is_busy():
		problems.append("a body with nothing in its hand swung anyway, which is "
			+ "a sixth combat verb `DES-009` does not have")

	# ─ 3b. **and it comes back off** ─
	#
	# `check_dead.py` said `ask_to_unequip` was orphaned, which is how this got
	# written at all — but it *only* checks names, and a wired name is not a
	# reached one (ADR-098's own caveat). This is the reach: a slot a player
	# cannot empty is a one-way door, and `DES-019` sells the bag as the place
	# you reorganise under pressure.
	player.inventory.clear()
	player.equipment.equip(ItemInstance.of(seax, 900))
	player.ask_to_unequip(Enums.Slot.MAIN_HAND)
	await _hold(0.2)
	var stowed: bool = player.inventory.count_of(seax) == 1
	print("[gear] taken off          back in the bag=%s, hand '%s'" % [
		stowed, player.weapon.held() != null])
	if not stowed:
		problems.append("taking a weapon out of the main hand did not put it in "
			+ "the bag — a slot a player cannot empty is a one-way door")
	if player.weapon.held() != null:
		problems.append("the hand was emptied and `MeleeWeapon` still holds a "
			+ "blade — the slot and the thing that swings have disagreed")

	# ─ 4. two hands means two hands (`DES-020`) ─
	var bow: ItemResource = ItemCatalogue.by_id(&"wpn_yew_bow")
	var torc: ItemResource = ItemCatalogue.by_id(&"glt_gilded_torc")
	gear.clear()
	gear.equip(ItemInstance.of(bow, 0))
	var pushed: Array[ItemInstance] = gear.equip(ItemInstance.of(seax, 0))
	print("[gear] two-hander swapped %d item(s) out, off hand '%s'" % [
		pushed.size(),
		"" if gear.in_slot(Enums.Slot.OFF_HAND) == null
		else gear.in_slot(Enums.Slot.OFF_HAND).definition.id])
	if pushed.size() != 1 or pushed[0].definition.id != &"wpn_yew_bow":
		problems.append(("swapping the main hand returned %d item(s) — what "
			+ "comes off has to come back, or equipping deletes gear")
			% pushed.size())

	# ─ 5. cargo is not equipment ─
	var refusal: String = gear.why_not(torc)
	print("[gear] a torc             '%s'" % refusal)
	if refusal == "":
		problems.append("a gilded torc could be equipped — `Enums.Slot.NONE` is "
			+ "what makes most of the item table cargo, and a coin in a slot is "
			+ "the trinket axis `DES-009` refused")

	# ─ 6. **the Pack is the grid** (`DES-020`) ─
	var satchel: ItemResource = ItemCatalogue.by_id(&"arm_hide_satchel")
	var pack := satchel.first_trait(PackTrait) as PackTrait
	gear.clear()
	await _hold(0.2)
	var bare: Vector2i = player.inventory.grid()
	gear.equip(ItemInstance.of(satchel, 0))
	await _hold(0.2)
	var packed: Vector2i = player.inventory.grid()
	print("[gear] grid               %s bare → %s packed (the pack says %s)" % [
		bare, packed, pack.grid])
	if bare != Config.tuning.inventory_grid:
		problems.append(("a bare body's grid is %s and the profile says %s — "
			+ "`DES-019` Q106 makes that value the *no pack* grid, and it has "
			+ "to still be what you get with no pack") % [bare, Config.tuning.inventory_grid])
	if packed != pack.grid:
		problems.append(("wearing a pack left the grid at %s — `DES-020` makes "
			+ "the Pack slot *set* the grid, which is the upgrade that makes "
			+ "you louder and is Pillar P1 as a piece of gear") % packed)

	# ─ 7. taking the pack off never eats what was in it ─
	for i: int in range(6):
		player.inventory.add(ItemCatalogue.by_id(&"glt_hoard_coin"))
	var before: int = player.inventory.count()
	gear.unequip(Enums.Slot.PACK)
	await _hold(0.3)
	var after: int = player.inventory.count()
	var floor_items: int = get_tree().get_nodes_in_group(WorldItem.GROUP).size()
	print("[gear] pack off           %d carried → %d, %d thing(s) on the floor"
		% [before, after, floor_items])
	if after > before:
		problems.append("taking a pack off created items")
	if after < before and floor_items <= 0:
		problems.append(("%d item(s) vanished when the pack came off — nothing "
			+ "may be destroyed by a slot changing, which is loot `DES-002` "
			+ "never agreed to take") % (before - after))

	_report(problems, "gear")


## **The Vörðr** (`M3-T14`, `DES-012`, ADR-130).
##
## `DES-012`: *"On death you become a Vörðr — your ward-spirit, briefly loose.
## Mobile, safe, unable to fight or carry. The point is that a dead player is
## still playing."* Every row here is one clause of that sentence, plus the
## readout `GATE M3 COOP` has named as a precondition since ADR-115.
func _vordr_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var player: Player = _session.local_player()
	_session.clear_enemies()
	await _hold(0.4)
	player.restore_for_descent()
	player.teleport(ARCHER_POST, 0.0)
	# **Something to lose.** The row below asserts a Vörðr carries nothing, and
	# the first draft downed a player whose bag was already empty — so it read
	# `0 item(s)` whether or not anything was ever cleared, and a plant that
	# deleted `inventory.clear()` outright walked straight through it. A body
	# that had nothing cannot demonstrate losing it.
	player.inventory.add(ItemCatalogue.by_id(&"glt_hoard_coin"))
	player.inventory.add(ItemCatalogue.by_id(&"glt_gilded_torc"))
	await _hold(0.3)
	var carried_in: int = player.inventory.count()
	print("[vordr] went down carrying %d item(s)" % carried_in)
	if carried_in <= 0:
		problems.append("the probe put nothing in the bag, so *unable to carry* "
			+ "below is a reading of an empty bag rather than of a loss")

	# ─ 1. **the readout answers, while it is happening** ─
	#
	# The gate asks whether a downed player can tell what is happening to them.
	# Three states, three answers, and the check is that each is *reachable and
	# distinguishable* — a readout that says the same thing in all three is a
	# readout that answers nothing.
	var readout: FallenReadout = null
	for node: Node in get_tree().get_nodes_in_group("__none__"):
		pass
	readout = _find_readout(self)
	if readout == null:
		problems.append("no `FallenReadout` on the floor — `GATE M3 COOP` has "
			+ "carried *the downed player can tell what is happening to them* "
			+ "as a precondition since ADR-115, and this is the thing that "
			+ "answers it")
		_report(problems, "vordr")
		return
	var screen_is: Vector2 = get_viewport().get_visible_rect().size
	print("[vordr] readout on screen  %.0f x %.0f (the screen is %.0f x %.0f)" % [
		readout.size.x, readout.size.y, screen_is.x, screen_is.y])
	# **Against the screen, not against zero.** ADR-111's fault is a `Control`
	# under a `CanvasLayer` getting no layout, and the first draft of this row
	# asked whether the rect was bigger than 2 x 2 — which a readout stuck at
	# Godot's 64 x 64 default passes while drawing a 360-wide bar off its own
	# edge. A rect that is not the screen is the bug, whatever size it is.
	if readout.size.x < screen_is.x - 1.0 or readout.size.y < screen_is.y - 1.0:
		problems.append(("the readout is %.0f x %.0f on a %.0f x %.0f screen — "
			+ "a `Control` under a `CanvasLayer` is laid out by nothing "
			+ "(ADR-111), and a rect smaller than the screen clips the bar it "
			+ "is drawing rather than failing outright")
			% [readout.size.x, readout.size.y, screen_is.x, screen_is.y])

	# ─ 2. down: a clock, and it is running ─
	player.health.apply_damage(player.health.maximum * 2.0)
	await _hold(0.4)
	var down_seconds: float = player.bleeding
	print("[vordr] down               bleeding %.0f s, downed=%s" % [
		down_seconds, player.is_downed()])
	if not player.is_downed() or down_seconds <= 0.0:
		problems.append("a body at zero health is not down, so nothing below "
			+ "is about being rescued")
	await _hold(0.6)
	if player.bleeding >= down_seconds:
		problems.append(("the bleed-out clock is not running (%.1f then %.1f) "
			+ "— ADR-050 makes the shortening itself the decision, and a window "
			+ "that does not shorten is a UI timer with no fiction behind it")
			% [down_seconds, player.bleeding])

	# ─ 2b. **and it names the one thing you can do about it** (ADR-150) ─
	#
	# The rows above ask whether the three states are *reachable*. None of them
	# ever asked what one said, and the down state said nothing about the one
	# way up: `has_self_recovery()` had existed since ADR-050 and was read by a
	# probe and by nothing else. Forty-five seconds of a shrinking bar, and the
	# reporter drew the only conclusion available — *"there is never anyone to
	# save them on a solo run."*
	var glyph: String = ControlsScreen.glyphs_for("use_waystone")
	var down_hint: String = readout.hint()
	print("[vordr] down says          '%s' | '%s'" % [readout.line(), down_hint])
	if not down_hint.contains(glyph):
		problems.append(("the downed readout does not name the way up (%s) — "
			+ "a solo player has exactly one, it ends the wait they are sitting "
			+ "through, and no screen in this game said so") % glyph)

	# **Spend it, and the readout has to stop offering it.** A hint that still
	# names a key which now does nothing is worse than no hint: it is a promise
	# the game breaks at the moment it is believed.
	player.ask_to_self_recover()
	await _hold(0.3)
	print("[vordr] one way up, spent  still has one=%s, standing=%s" % [
		player.has_self_recovery(), not player.is_downed()])
	if player.has_self_recovery() or player.is_downed():
		problems.append("the one self-recovery did not spend or did not stand "
			+ "the body up, so the row below is about nothing")
	player.health.apply_damage(player.health.maximum * 2.0)
	await _hold(0.4)
	var spent_hint: String = readout.hint()
	print("[vordr] down again         '%s'" % spent_hint)
	if spent_hint == "" or spent_hint == down_hint:
		problems.append(("down a second time with nothing left to spend, the "
			+ "readout says '%s' — the same thing it said when there was a way "
			+ "up. `PRO-005` §5 forbids the unexplainable, and a key that "
			+ "stopped working without saying so is exactly that")
			% spent_hint)

	# ─ 3. **and it is still a body** — down is not loose ─
	print("[vordr] down, not loose    spent=%s, on the body layer=%s" % [
		player.spent, (player.collision_layer & CollisionLayers.PLAYER_BODY) != 0])
	if (player.collision_layer & CollisionLayers.PLAYER_BODY) == 0:
		problems.append("a downed body left the body layer — it is still a "
			+ "body, and a teammate has to be able to walk up to it")

	# ─ 4. loose: mobile, and that is the whole point ─
	player.bleeding = 0.01
	await _hold(0.6)
	print("[vordr] loose              spent=%s" % player.spent)
	if not player.spent:
		problems.append("the window ran out and the body is not spent, so the "
			+ "Vörðr is unreachable")
		_report(problems, "vordr")
		return
	# **And it says the right thing about being alone** (ADR-150). Asserted
	# here rather than lower down because becoming spent is what starts
	# `_watch_for_a_wipe`, and the rows below already spend most of
	# `party_wipe_seconds`.
	var loose_says: String = readout.line()
	print("[vordr] loose says         '%s'" % loose_says)
	if loose_says == "" or loose_says == tr("fallen.vordr"):
		problems.append(("a Vörðr with nobody left standing is told to *scout "
			+ "for them* — that line was written for a party and shipped to "
			+ "everybody, and solo there is no them and three seconds left"))

	var speed_now: float = player._target_speed(false, Config.tuning)
	print("[vordr] a Vörðr moves at   %.1f m/s (walking is %.1f)" % [
		speed_now, Config.tuning.walk_speed])
	if speed_now <= 0.0:
		problems.append(("a Vörðr is frozen at %.1f m/s — `DES-012` says "
			+ "**mobile**, and a body standing still with a live camera is the "
			+ "ghost-with-nothing-to-do ADR-114 found enemies still attacking")
			% speed_now)

	# ─ 5. safe: nothing collides with it, and nothing can hit it ─
	print("[vordr] loose and safe     body layer=%s, hittable=%s" % [
		(player.collision_layer & CollisionLayers.PLAYER_BODY) != 0,
		player._hurtbox.monitorable])
	if (player.collision_layer & CollisionLayers.PLAYER_BODY) != 0:
		problems.append("a Vörðr is still on the body layer — a ghost the "
			+ "party has to walk around is the opposite of *a dead player is "
			+ "still playing*, and a corpse in a corridor becomes a hazard to "
			+ "your own team")
	if player._hurtbox.monitorable:
		problems.append(("a Vörðr can still be hit — `Enemy._worth_fighting` "
			+ "refuses to *acquire* the incapacitated (ADR-114), but that is a "
			+ "rule about attention and this is one about geometry: a swing "
			+ "already in flight would still land"))

	# ─ 6. unable to carry ─
	print("[vordr] carries            %d item(s) (went down with %d)" % [
		player.inventory.count(), carried_in])
	if player.inventory.count() != 0:
		problems.append(("a Vörðr is carrying %d item(s) — `DES-012` says "
			+ "**unable to carry**, and everything you had stays with the body "
			+ "so a teammate can decide whether it is worth coming for")
			% player.inventory.count())

	# ─ 7. and enemies leave it alone (ADR-114, still true one task later) ─
	_session.spawn_enemy(player.global_position + Vector3(0.0, 0.0, 3.0), 0.0)
	await _hold(1.6)
	var watcher: Enemy = _first_live_enemy()
	if watcher == null:
		problems.append("no enemy spawned, so nothing here says what one does "
			+ "about a Vörðr")
	else:
		print("[vordr] an enemy nearby    state %s (want not alerted)"
			% Enemy.State.keys()[watcher.state()].to_lower())
		if watcher.is_hunting():
			problems.append("an enemy alerted onto a Vörðr — ADR-114 made the "
				+ "fallen stop being a target, and being loose is more fallen "
				+ "rather than less")

	_report(problems, "vordr")


## Depth-first, because the readout lives under a `CanvasLayer` the HUD builds
## and this probe should not have to know the shape of that tree.
func _find_readout(from: Node) -> FallenReadout:
	for child: Node in from.get_children():
		var found := child as FallenReadout
		if found != null:
			return found
		var deeper: FallenReadout = _find_readout(child)
		if deeper != null:
			return deeper
	return null


## **A party crosses a floor** (`M4-T01`, ADR-185, ADR-186).
##
## `--run-probe` proves the run *file* can hold a floor index. This proves the
## **game** moves one: that claiming a Shaft above the bottom descends instead of
## extracting, that the bag, the wound and the Hunt's age are written down, and
## that arriving one floor lower puts all three back on the body.
##
## Both halves in one process, because the transition is a scene change and a
## probe cannot survive its own: `_take_the_party_down` returns before the change
## when `_probing`, so the *record* is assertable here; the *restore* is driven
## by calling `declare_descent` with what was recorded, which is exactly what
## `CoopSession._ready` does on the floor below. The functions under test are the
## real ones on both sides — only the scene change is stood in for.
## **The lantern is a decision, and something reads it** (`M4-T13`, ADR-188).
##
## `ART-001` says darkness is a mechanic; `tools/check_dead.py` cannot tell a
## mechanic from a light that emits photons nobody consults, because it checks
## **names, not reachability** (ADR-098). So every row below is about the game
## reaching this code rather than about the code existing — row 2 in particular
## drives a real `Enemy` through `_can_see` at a real distance, because *"a
## lantern that emits light nothing reads"* is the exact shape of that bug.
func _lantern_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var body: Player = _session.local_player()
	if body == null:
		problems.append("no body to hand a lantern to — every row below is "
			+ "about nothing")
		_report(problems, "lantern")
		return
	var lamp: ItemResource = ItemCatalogue.by_id(&"tol_horn_lantern")
	if lamp == null:
		problems.append("no `tol_horn_lantern` in the catalogue")
		_report(problems, "lantern")
		return
	var tuning: TuningProfile = Config.tuning
	body.equipment.equip(ItemInstance.of(lamp, 0))

	# ─ 1. the shutter changes how far away you are seen from ─
	#
	# Measured somewhere the floor's own doorway lamps cannot reach, or the row
	# would be about the room rather than about the lantern.
	var dark_spot: Vector3 = _away_from_the_lamps()
	body.teleport(dark_spot, 0.0)
	body.lit = false
	await _hold(0.3)
	var shut_at: float = body.exposure.seen_from()
	body.lit = true
	await _hold(0.3)
	var lit_at: float = body.exposure.seen_from()
	print("[lantern] seen from      %.1f m shut, %.1f m lit (dark %.1f, lit %.1f)"
		% [shut_at, lit_at, tuning.enemy_vision_dark, tuning.enemy_vision_range])
	if lit_at <= shut_at + 0.5:
		problems.append(("an open lantern is seen from %.1f m and a shut one "
			+ "from %.1f m — `ART-001` makes light a resource you manage, and "
			+ "a light that costs nothing is an effect") % [lit_at, shut_at])
	if lit_at < tuning.enemy_vision_range - 0.1:
		problems.append(("a lit lantern reaches only %.1f m of the %.1f m an "
			+ "enemy can see — `LightTrait.glare` is 1.0, so an open shutter "
			+ "is meant to be total exposure")
			% [lit_at, tuning.enemy_vision_range])
	if shut_at > tuning.enemy_vision_dark + 2.0:
		problems.append(("a shuttered lantern away from every lamp still reads "
			+ "%.1f m against a %.1f m floor — the darkness is not dark")
			% [shut_at, tuning.enemy_vision_dark])

	# ─ 1b. **and `glare` is the number that decides it** ─
	#
	# Turned down on the held instance, so the row measures the dial rather
	# than the lamp beside it. Without `Lantern.owns` the body's own light is
	# counted twice — once at its glare and once at a 0.35 m falloff worth
	# ~0.97 — and the falloff wins, so a dim light would be as damning as a
	# bright one and `LightTrait.glare` would be unturndownable.
	var held: ItemInstance = body.equipment.in_slot(Enums.Slot.OFF_HAND)
	var dial := held.definition.first_trait(LightTrait) as LightTrait
	var was_glare: float = dial.glare
	dial.glare = 0.3
	await _hold(0.3)
	var dimmed_at: float = body.exposure.seen_from()
	dial.glare = was_glare
	print("[lantern] glare 0.3      seen from %.1f m, full glare was %.1f"
		% [dimmed_at, lit_at])
	if dimmed_at >= lit_at - 0.5:
		problems.append(("turning `glare` down to 0.3 changed nothing (%.1f m "
			+ "against %.1f) — the bearer's own falloff is overruling the dial, "
			+ "so what a light costs to carry cannot be authored")
			% [dimmed_at, lit_at])

	# ─ 2. **and an enemy actually acts on it** ─
	#
	# The row that stops all of the above being satisfied by a number nothing
	# consults. Stood at a distance that is inside the lit range and outside
	# the dark one, so the *only* thing that can change the answer is light.
	var between: float = (tuning.enemy_vision_dark + tuning.enemy_vision_range) * 0.5
	var watcher: Enemy = _an_enemy(body)
	var post: Vector3 = _a_clear_spot(body, between)
	if watcher == null or post == Vector3.INF:
		problems.append(("could not stand an enemy %.1f m from the body with a "
			+ "clear line of sight — the row that proves anything *reads* the "
			+ "light did not run, so it must not report a pass") % between)
	else:
		# **The exposure settles first, and the enemy is placed second.**
		#
		# The first version placed the enemy once and then read it twice with
		# 0.4 s between. An enemy that has seen you is ALERTED and *walks*, so
		# by the second read it had left its mark — and the row failed on a
		# healthy build, blaming the lantern for the pathfinding. Wait for the
		# thing being measured, then measure it, is `TEC-007` §1's rule; this
		# is the same fault as timing a telegraph off the wrong event.
		var saw: Array[bool] = []
		for burning: bool in [false, true]:
			body.lit = burning
			await _hold(0.3)
			watcher.global_position = post
			watcher.look_at(Vector3(body.global_position.x, post.y,
				body.global_position.z), Vector3.UP)
			await get_tree().physics_frame
			await get_tree().physics_frame
			saw.append(watcher.sees_player())
		var saw_shut: bool = saw[0]
		var saw_lit: bool = saw[1]
		print("[lantern] at %.1f m       enemy sees: shut=%s lit=%s (want no, yes)"
			% [between, saw_shut, saw_lit])
		if saw_shut:
			problems.append(("an enemy saw a shuttered body at %.1f m, past the "
				+ "%.1f m it can see in the dark — nothing is reading exposure")
				% [between, tuning.enemy_vision_dark])
		if not saw_lit:
			problems.append(("an enemy did not see a lit body at %.1f m, inside "
				+ "the %.1f m it can see a lit one from — the lantern lights "
				+ "pixels and gives nothing away")
				% [between, tuning.enemy_vision_range])

	# ─ 3. the shutter cannot be strobed ─
	body.teleport(dark_spot, 0.0)
	var first: bool = body.try_shutter()
	var second: bool = body.try_shutter()
	print("[lantern] shutter twice  %s then %s (want yes, no)" % [first, second])
	if not first:
		problems.append("the shutter refused to move at all")
	if second:
		problems.append(("the shutter worked twice in one frame — a player can "
			+ "strobe the lamp for vision at no exposure, which deletes the "
			+ "trade the whole item is"))

	# ─ 4. a lantern that leaves the hand goes out ─
	body.lit = true
	body.equipment.unequip(Enums.Slot.OFF_HAND)
	await _hold(0.3)
	print("[lantern] hand emptied   lit=%s, seen from %.1f m (want false, %.1f)"
		% [body.lit, body.exposure.seen_from(), tuning.enemy_vision_dark])
	if body.lit:
		problems.append("the flag survived the lantern leaving the hand, so "
			+ "the next light picked up arrives already burning")
	if body.exposure.seen_from() > tuning.enemy_vision_dark + 2.0:
		problems.append(("a body with an empty off hand is still lit at %.1f m "
			+ "— the lamp outlived the item") % body.exposure.seen_from())

	# ─ 5. **a light you are not carrying still gives you away** ─
	#
	# This is the co-op rule and the doorway rule at once (`DES-012`,
	# `M2-T13`): a teammate's lantern and a door lamp are the same thing to
	# `Exposure`, which is what makes four lanterns a floodlight with no co-op
	# branch anywhere.
	var borrowed := OmniLight3D.new()
	borrowed.omni_range = 8.0
	borrowed.light_energy = 1.5
	borrowed.add_to_group(Lantern.LIGHT_GROUP)
	_world.add_child(borrowed)
	borrowed.global_position = body.global_position + Vector3(1.5, 1.1, 0.0)
	await _hold(0.3)
	var borrowed_at: float = body.exposure.seen_from()
	print("[lantern] a lamp nearby  seen from %.1f m, was %.1f"
		% [borrowed_at, shut_at])
	if borrowed_at <= shut_at + 0.5:
		problems.append(("standing beside a lamp somebody else is holding "
			+ "changed nothing (%.1f m) — `DES-012`'s four lanterns are not a "
			+ "floodlight, and a lit doorway is not terrain") % borrowed_at)

	# ─ 6. and light does not pass through rock ─
	var behind: Vector3 = _through_the_nearest_wall(body.global_position)
	if behind == Vector3.INF:
		problems.append("found no wall to put a lamp behind — the row that "
			+ "proves light is blocked did not run")
	else:
		borrowed.global_position = behind
		await _hold(0.3)
		var walled_at: float = body.exposure.seen_from()
		print("[lantern] lamp in rock   seen from %.1f m (want %.1f)"
			% [walled_at, shut_at])
		if walled_at > shut_at + 0.5:
			problems.append(("a lamp on the far side of a wall lit the body to "
				+ "%.1f m — light does not round a corner the way noise does, "
				+ "and a body lit through rock is the game visibly cheating")
				% walled_at)
	borrowed.queue_free()

	_report(problems, "lantern")


## The darkest place on this floor a body can actually stand.
##
## **Searched over real floor space, not over the generator's anchors.** The
## first version picked the furthest of `spawns + prize + shaft`, and every one
## of those is a room the generator chose — which is to say a room with a
## doorway lamp in it. It returned the Prize at every ambient value, the lamp
## beside it dominated `Exposure`, and the sweep's printed distance came out
## non-monotonic while claiming to measure the dark.
##
## The clamor field's grid is reused because it is already laid over exactly
## this floor's footprint at exactly the resolution this needs, and building a
## second grid to answer a question the first one is already shaped for is the
## parallel path ADR-064 rules out.
func _away_from_the_lamps() -> Vector3:
	var lamps: Array[Node] = get_tree().get_nodes_in_group(DOOR_LIGHT_GROUP)
	var best: Vector3 = _floor.prize()
	var furthest: float = -INF
	if _field == null:
		return best
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for y: int in range(_field.height()):
		for x: int in range(_field.width()):
			var centre: Vector3 = _field.cell_centre(x, y)
			# Standable: floor beneath, and open at chest height. Without the
			# second test this happily returns a point inside solid rock, which
			# is the darkest place on any floor and no use to anybody.
			var down := PhysicsRayQueryParameters3D.create(
				centre + Vector3.UP * 2.0, centre - Vector3.UP * 2.0)
			down.collision_mask = CollisionLayers.WORLD
			var ground: Dictionary = space.intersect_ray(down)
			if ground.is_empty():
				continue
			var stand: Vector3 = ground["position"] as Vector3
			var chest := PhysicsRayQueryParameters3D.create(
				stand + Vector3.UP * 0.3, stand + Vector3.UP * 1.6)
			chest.collision_mask = CollisionLayers.WORLD
			if not space.intersect_ray(chest).is_empty():
				continue
			var nearest: float = INF
			for node: Node in lamps:
				nearest = minf(nearest,
					stand.distance_to((node as Node3D).global_position))
			if nearest > furthest:
				furthest = nearest
				best = stand + Vector3.UP * 0.1
	print("[light] darkest stand  %.1f m from the nearest of %d lamp(s)"
		% [furthest, lamps.size()])
	return best


## Any enemy on the floor, or null.
func _an_enemy(_body: Player) -> Enemy:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var found := node as Enemy
		if found != null:
			return found
	return null


## Somewhere `metres` from `body` with a clear line of sight to it, or
## `Vector3.INF`. **INF rather than a best effort**: a row measuring sight
## through a wall would report the lantern failing when the geometry is what
## failed, and that is a finding-shaped wrong answer.
func _a_clear_spot(body: Player, metres: float) -> Vector3:
	var eye: Vector3 = body.global_position + Vector3.UP * 0.9
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for step: int in range(24):
		var angle: float = TAU * float(step) / 24.0
		var at: Vector3 = body.global_position + Vector3(
			cos(angle) * metres, 0.0, sin(angle) * metres)
		var query := PhysicsRayQueryParameters3D.create(eye, at + Vector3.UP * 1.4)
		query.collision_mask = CollisionLayers.WORLD
		if not space.intersect_ray(query).is_empty():
			continue
		return at
	return Vector3.INF


## A point a metre inside the nearest wall, or `Vector3.INF` if this body is
## standing somewhere with no wall within 12 m.
func _through_the_nearest_wall(from: Vector3) -> Vector3:
	var eye: Vector3 = from + Vector3.UP * 1.1
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for step: int in range(16):
		var angle: float = TAU * float(step) / 16.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var query := PhysicsRayQueryParameters3D.create(
			eye, eye + direction * 12.0)
		query.collision_mask = CollisionLayers.WORLD
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			continue
		return (hit["position"] as Vector3) + direction * 1.0
	return Vector3.INF


func _descent_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()

	# Its own run file, never the player's (ADR-145, ADR-152): this opens one.
	RunFile.use_a_scratch_run()
	RunFile.arm()
	if RunFile.PATH == "user://run.active":
		printerr("[descent] FAIL this probe is pointed at the player's run file")
		get_tree().quit(1)
		return
	RunFile.clear()
	RunFile.begin(&"huskarl", 1, 31346)

	var body: Player = _session.local_player()
	if body == null:
		problems.append("no body to take down — every row below is about "
			+ "nothing")
		_report(problems, "descent")
		return

	# ─ 1. a floor above the bottom goes down rather than out ─
	#
	# **Asserted by where it ends up, not by which function ran.** A row that
	# checked `_going_down` would pass against a build that set the flag and
	# extracted anyway.
	_stand_on_floor(0)
	var pool: Array[ItemResource] = ItemCatalogue.all()
	var put_in: int = 0
	for definition: ItemResource in pool:
		if body.inventory.add(definition) != null:
			put_in += 1
		if put_in >= 3:
			break
	body.health.current = body.health.maximum * 0.4
	if _hunter != null:
		_hunter.age = 90.0
	var hurt_before: float = body.health.current
	var scene_before: String = get_tree().current_scene.scene_file_path

	_on_shaft_claimed(body)
	await _hold(0.3)

	var went: int = RunFile.floor_index()
	print("[descent] took the party  floor 0 → %d, scene unchanged=%s "
		% [went, get_tree().current_scene.scene_file_path == scene_before]
		+ "(want 1, yes)")
	if went != 1:
		problems.append("claiming the Shaft on floor 0 did not descend — "
			+ "`MissionGraph.Role.SHAFT` is *the way down, and out*, and the "
			+ "way down is the half this task owes")
	if GameState.carried.size() > 0:
		problems.append("claiming the Shaft above the bottom brought a haul "
			+ "home — that is extraction, and floors 0 and 1 have no way out "
			+ "but a Waystone (ADR-186)")

	# ─ 2. what the run wrote down ─
	var rows: Array = RunFile.bag()
	print("[descent] carried down    %d row(s) of %d, %.0f hp of %.0f, "
		% [rows.size(), put_in, RunFile.wound(), hurt_before]
		+ "hunt %.0f s" % RunFile.hunt_age())
	if rows.size() != put_in:
		problems.append(("the bag did not go down — %d item(s) went in and %d "
			+ "were written, so a floor transition is a way to lose your haul")
			% [put_in, rows.size()])
	if absf(RunFile.wound() - hurt_before) > 0.01:
		problems.append("the wound did not go down — `DES-009` bans "
			+ "regeneration *within* a run and ADR-015 makes a run three "
			+ "floors, so a descent that heals is the one thing combat forbids")
	if RunFile.hunt_age() < 89.0:
		problems.append("the Hunt did not follow — ADR-037 closed Q9 with "
			+ "*descending grants nothing, a staircase cannot shake it*")

	# ─ 3. **and the floor below puts it back** ─
	#
	# The row that stops all of the above being satisfied by writing a file
	# nobody reads — ADR-098's question, asked of the thing that was just built.
	# Driven through `declare_descent`, because that is the call
	# `CoopSession._ready` makes on arrival and the host is what owns a bag.
	body.inventory.clear()
	body.health.current = body.health.maximum
	_session.declare_descent(1, "huskarl", PackedStringArray(), {},
		RunFile.bag(), RunFile.wound())
	await _hold(0.2)
	print("[descent] handed back     %d item(s), %.0f hp (want %d, %.0f)" % [
		body.inventory.count(), body.health.current, put_in, hurt_before])
	if body.inventory.count() != put_in:
		problems.append(("the bag was written and never read back — %d item(s) "
			+ "arrived of %d, which is a run file with a haul in it and a "
			+ "player with an empty bag") % [body.inventory.count(), put_in])
	if absf(body.health.current - hurt_before) > 0.01:
		problems.append("the body arrived healed — descending is a commitment "
			+ "(`DES-005`), and a free heal makes it a rest stop")

	# ─ 4. the bottom of the expedition lets you out ─
	#
	# The complement of row 1, and the row that stops ADR-186 from removing the
	# only way out of the game: if the Shaft never extracts anywhere, a run can
	# be entered and never resolved.
	_stand_on_floor(RunFile.LAST_FLOOR)
	_going_down = false
	var out_before: int = GameState.carried.size()
	_on_shaft_claimed(body)
	await _hold(0.3)
	# **Asserted on the run being *resolved*, not on its floor index.**
	#
	# The first draft asked whether the index had stayed at 1 and failed a
	# healthy build: extraction is an outcome, an outcome calls `RunFile.clear()`
	# (ADR-050 — the run resolved), and a cleared run reads back as floor 0. The
	# row was measuring the absence of a file and calling it a descent.
	#
	# Resolution is the better claim anyway. It is what ADR-186 most plausibly
	# breaks: take the exit off every Shaft and a run can be entered and never
	# ended, which strands `user://run.active` open forever and blocks every
	# future descent (ADR-132).
	var still_open: bool = RunFile.exists()
	print("[descent] the bottom      got_out=%s, run still open=%s "
		% [body.got_out, still_open] + "(want yes, no)")
	if not body.got_out:
		problems.append("the Shaft on the last floor did not let anybody out — "
			+ "`DES-005`'s Deep Gate is the guaranteed exit and this is its "
			+ "mechanism; without it a run has no ending but death")
	if still_open:
		problems.append("the bottom floor descended instead of resolving the "
			+ "run — there is nothing under floor %d, and a run that cannot "
			% RunFile.LAST_FLOOR
			+ "end leaves `run.active` open and blocks every future descent")
	if out_before > 0:
		problems.append("this row could not fail: something had already been "
			+ "brought home before it ran")

	RunFile.clear()
	_report(problems, "descent")


## **A run you cannot walk away from** (`M3-T15`, ADR-050, ADR-132).
##
## `TEC-003` puts mid-run state in `user://run.active` so a quit is *suspended*
## rather than silently converted into a death, and ADR-050 settles which way
## that cuts: **suspend with forced resume**, because *"disconnecting is never
## an escape from a bad run."*
##
## Driven against the file rather than through the menu, because what is being
## asserted is what the **file** makes impossible — the menu is one caller of
## it, and `--menu-probe` already presses Descend.
func _run_file_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()

	# **This probe's subject is the run file, so it arms itself** (ADR-138).
	# Every other probe stays unarmed and therefore cannot see, write or delete
	# a run — which is the point: an unarmed sweep used to leave one open in the
	# player's `user://`, and the next launch resumed it into a classless body.
	#
	# **And it gets its own file** (ADR-152). Arming was the fix for every probe
	# that touched this file *by accident*, and this is the one that touches it
	# on purpose — so it went on writing, and deleting, the player's open run on
	# every sweep. ADR-145 wrote the general rule after the same shape cost a
	# profile: a check that writes to `user://` must name the file it writes to,
	# and it must not be the one the game uses.
	RunFile.use_a_scratch_run()
	RunFile.arm()
	if RunFile.PATH == "user://run.active":
		printerr("[run] FAIL this probe is pointed at the player's run file "
			+ "and clears it below — a suspended run would be destroyed and "
			+ "nothing in the output would say so")
		get_tree().quit(1)
		return

	# A clean slate, so nothing below is reading a run left by an earlier probe.
	RunFile.clear()
	print("[run] nothing open        exists=%s (want false)" % RunFile.exists())
	if RunFile.exists():
		problems.append("a run file survived `clear()`, so every row below is "
			+ "about somebody else's run")
		_report(problems, "run")
		return

	# ─ 1. a descent opens one, and it holds who went down ─
	RunFile.begin(&"huskarl", 3, 31346)
	var opened: Dictionary = RunFile.read()
	print("[run] opened              class '%s', rank %d, stripped=%s" % [
		opened.get("class_id", ""), int(opened.get("rank", 0)),
		opened.get("stripped", true)])
	if not RunFile.exists():
		problems.append("a descent opened no run file — `TEC-003` puts mid-run "
			+ "state in one precisely so a crash is resumable")
	if String(opened.get("class_id", "")) != "huskarl" \
			or int(opened.get("rank", 0)) != 3:
		problems.append("the run file does not say who went down, so a resume "
			+ "cannot put the same person back")

	# ─ 1b. **and where they are** (`M4-T01`, ADR-184) ─
	#
	# A run opens at the top of its expedition and remembers which expedition
	# it is. Both halves asserted, because only the pair is useful: an index
	# with no seed resumes onto *a* floor 2 rather than *the* floor 2, and
	# `stripped` would then strip a floor nobody had walked.
	print("[run] the expedition      floor %d of %d, seed %d (want 0, seed 31346)"
		% [RunFile.floor_index(), RunFile.LAST_FLOOR + 1, RunFile.seed_of()])
	if RunFile.floor_index() != 0:
		problems.append("a run opened somewhere other than floor 0 — an "
			+ "expedition starts at the top, and `DES-015`'s Aftermath is the "
			+ "floor that explains the two beneath it")
	if RunFile.seed_of() != 31346:
		problems.append("the run does not remember which expedition it is — a "
			+ "resume would rebuild a different floor under the same index, and "
			+ "`stripped` would empty one nobody had ever walked")

	# ─ 1c. **descending moves the index and keeps the expedition** ─
	#
	# The whole of the multi-floor run in three assertions. `stripped` is the
	# third and least obvious: a new floor has not been looted, so `descend()`
	# clears it — without that, every floor after the first lays no loot at all
	# and the expedition is one room of treasure followed by two empty ones.
	RunFile.note({"stripped": true})
	var went_to: int = RunFile.descend()
	var deeper: Dictionary = RunFile.read()
	print("[run] descended           floor %d, seed %d, stripped=%s "
		% [went_to, RunFile.seed_of(), deeper.get("stripped", true)]
		+ "(want 1, seed 31346, false)")
	if went_to != 1 or RunFile.floor_index() != 1:
		problems.append("descending did not move the floor index, so the "
			+ "expedition would rebuild floor 0 under the party for all three "
			+ "descents and depth would be a lie")
	if RunFile.seed_of() != 31346:
		problems.append("descending re-rolled the expedition — the three floors "
			+ "of one run are three graphs from one seed (`DES-015`), and a "
			+ "fresh seed per floor makes them three unrelated places")
	if bool(deeper.get("stripped", true)):
		problems.append("the floor below arrived already stripped — every floor "
			+ "after the first would lay no loot, which is the resume exploit's "
			+ "fix eating the feature it was protecting")

	# And there is nothing under the last floor. Clamped rather than wrapped, so
	# a caller at the bottom cannot be handed floor 0 and rebuild the Aftermath.
	RunFile.note({"floor": RunFile.LAST_FLOOR})
	var past_the_bottom: int = RunFile.descend()
	print("[run] under the last      floor %d (want %d)" % [
		past_the_bottom, RunFile.LAST_FLOOR])
	if past_the_bottom != RunFile.LAST_FLOOR:
		problems.append("descending past the last floor did not stop at it — "
			+ "`DES-015` is three floors and the Deep Gate is the way out of "
			+ "the third, not a fourth")
	RunFile.note({"floor": 0})

	# ─ 2. **quitting is not an escape** ─
	#
	# The load-bearing row. A run stays open across everything except an
	# outcome, so there is no sequence of quits that ends one.
	print("[run] still open          exists=%s (want true)" % RunFile.exists())
	if not RunFile.exists():
		problems.append("the run closed without an outcome — ADR-050's whole "
			+ "sentence is that disconnecting is never an escape from a bad "
			+ "run, and a run that closes on a quit is exactly that escape")

	# ─ 3. notes merge rather than replace ─
	RunFile.note({"stripped": true})
	var noted: Dictionary = RunFile.read()
	print("[run] noted               stripped=%s, class still '%s'" % [
		noted.get("stripped", false), noted.get("class_id", "")])
	if not bool(noted.get("stripped", false)):
		problems.append("a note did not stick, so the floor cannot record that "
			+ "it has already been stripped")
	if String(noted.get("class_id", "")) != "huskarl":
		problems.append("noting one field dropped the others — a caller that "
			+ "knows one fact would have to know all of them, and the first one "
			+ "to forget erases the run")

	# ─ 4. **a resumed floor lays no loot** ─
	#
	# The exploit this closes: without it, quit-and-relaunch re-lays every
	# fixture and a run's loot doubles — a feature about not escaping a run
	# turned into the best way to extend one.
	# **As a fresh process would arrive**, not as this one already has.
	#
	# `_fixtures_placed` is already true here — this floor laid its loot at
	# build — so simply calling `_spawn_loot()` again lays nothing whatever the
	# run file says, and the row passed identically with the `stripped` check
	# deleted. Clearing it is what makes this a *resume* rather than a repeat
	# call, and it is the only way a single process can stand in for a relaunch.
	var before: int = _loot_on_the_floor()
	_fixtures_placed = false
	_loot_placed = false
	# The gate above skips the run file while `_probing`, which is right for
	# every other probe and would make this row untestable — so this one turns
	# it off across the call it is actually measuring.
	_probing = false
	_spawn_loot()
	_probing = true
	await _hold(0.4)
	var after_resume: int = _loot_on_the_floor()
	print("[run] stripped floor      %d item(s) before, %d after a re-lay" % [
		before, after_resume])
	if after_resume > before:
		problems.append(("a resumed floor laid %d more item(s) — quitting and "
			+ "coming back would double a run's loot, which makes ADR-050's "
			+ "suspend the best way to farm a floor")
			% (after_resume - before))

	# ─ 5. an outcome closes it, and only an outcome ─
	RunFile.clear()
	print("[run] after an outcome    exists=%s (want false)" % RunFile.exists())
	if RunFile.exists():
		problems.append("the run outlived its outcome, so the next descent "
			+ "would resume a run that already resolved")

	# ─ 6. **a file nobody can read costs a run, never a lineage** ─
	#
	# The opposite decision from `SaveFile` (`M3-T06`), and deliberately: an
	# unreadable profile is **kept**, because a lineage is not replaceable. An
	# unreadable run file is dropped, because keeping it would block every
	# future descent forever and what it costs is one run.
	var litter: FileAccess = FileAccess.open(RunFile.PATH, FileAccess.WRITE)
	litter.store_string("half a run, from a process that died")
	litter.close()
	var garbage: Dictionary = RunFile.read()
	print("[run] unreadable          read %d field(s), file still there=%s" % [
		garbage.size(), RunFile.exists()])
	if not garbage.is_empty():
		problems.append("garbage parsed as a run, which would resume a player "
			+ "into a floor built from nothing")
	if RunFile.exists():
		problems.append("an unreadable run file was kept — it would block every "
			+ "descent from here on, and unlike a profile it is worth one run")

	_report(problems, "run")


## What is lying on the floor, ignoring what anybody is carrying.
func _loot_on_the_floor() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group("world_items"):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			count += 1
	return count


## **The Wing** (`M3-T12`, `DES-004`, ADR-135).
##
## `DES-004`'s answer to *"get in, get out, never fight"*, and the Veiðimaðr's
## primary. Thirteen nodes against machinery `M3-T01` already proved — so what
## is checked here is **that each tag reaches a system**, which is the one thing
## a data-only task can still get wrong: a node whose effect nothing reads is a
## sentence in a `.tres` and a lie on a screen.
##
## Every row asserts a **state change** rather than a value (ADR-134's lesson):
## the same measurement taken with the node and without it, so a row cannot pass
## on a number that happened to be right already.
func _wing_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var player: Player = _session.local_player()
	var tuning: TuningProfile = Config.tuning

	# ─ 1. the Aspect is authored and coherent ─
	var wing: Array[AspectNode] = []
	for node: AspectNode in AspectCatalogue.all():
		if node.aspect == &"wing":
			wing.append(node)
	print("[wing] authored            %d node(s)" % wing.size())
	if wing.is_empty():
		problems.append("no Wing nodes — every row below is conditional on the "
			+ "Aspect existing, which is the guard the item corpus already has")
		_report(problems, "wing")
		return
	var keystones: int = 0
	for node: AspectNode in wing:
		if node.tier == AspectNode.Tier.KEYSTONE:
			keystones += 1
	print("[wing] keystones           %d (want 1)" % keystones)
	if keystones != 1:
		problems.append(("the Wing has %d keystones — `DES-004` gives an Aspect "
			+ "one, and it is what a build is *for*") % keystones)

	# ─ 2. **every tag reaches something** ─
	#
	# The row this probe exists for. A tag nothing reads is the failure a
	# data-only task produces, and it is invisible: the node loads, validates,
	# appears on the screen, is purchasable, and does nothing at all.
	var unread: Array[String] = []
	for node: AspectNode in wing:
		for tag: StringName in node.effect_tags:
			if not _tag_is_read(tag):
				unread.append("%s/%s" % [node.id, tag])
	print("[wing] tags with a reader  %d unread" % unread.size())
	if not unread.is_empty():
		problems.append(("nothing reads %s — a node whose effect no system "
			+ "consults loads, validates, sells and does nothing, which is the "
			+ "one failure a data-only task can still ship")
			% ", ".join(unread))

	# ─ 3. stealth: the two multipliers go to the value that makes it true ─
	player.restore_for_descent()
	player.teleport(ARCHER_POST, 0.0)
	await _hold(0.3)
	player.effects = PackedStringArray()
	var loud_crouch: float = await _walk_and_listen(player, true)
	player.effects = PackedStringArray(["silent_crouch"])
	var quiet_crouch: float = await _walk_and_listen(player, true)
	print("[wing] crouching           %.2f clamor → %.2f with Soft Boots" % [
		loud_crouch, quiet_crouch])
	if loud_crouch <= 0.0:
		problems.append("crouching made no noise without the node either, so "
			+ "the comparison is between two silences")
	elif quiet_crouch > 0.001:
		# **Against zero, not against the other number.** Crouched footsteps are
		# quiet to begin with — 0.33 — and the planted value lands at 0.34, so
		# `quiet >= loud` was comparing two nearly-equal noisy readings and
		# passed by luck about half the time. The design claim is stronger than
		# the row was asking: `DES-004` rule 2 wants the multiplier to go to
		# **zero**, and zero is not a close call.
		problems.append(("Soft Boots left %.2f clamor behind (a plain crouch is "
			+ "%.2f) — the multiplier goes to **zero** rather than lower, "
			+ "because rule 2 wants a node to change what is *true*")
			% [quiet_crouch, loud_crouch])

	# ─ 4. what you carry stops announcing itself ─
	player.effects = PackedStringArray()
	player.inventory.clear()
	player.inventory.add(ItemCatalogue.by_id(&"glt_altar_plate"))
	await _hold(0.4)
	var laden: float = player.clamor.carried_floor
	player.effects = PackedStringArray(["weightless_signature"])
	await _hold(0.4)
	var faint: float = player.clamor.carried_floor
	print("[wing] carried floor       %.2f → %.2f with Faint Trace" % [
		laden, faint])
	if laden <= 0.0:
		problems.append("a loaded bag had no clamor floor to begin with, so "
			+ "Faint Trace has nothing to remove")
	elif faint != 0.0:
		problems.append("Faint Trace left a signature behind")

	# ─ 5. **the weight stays**, which is what keeps it a Wing node ─
	print("[wing] and the weight      %.1f kg" % player.inventory.total_weight())
	if player.inventory.total_weight() <= 0.0:
		problems.append("Faint Trace made the load weightless as well — it is "
			+ "the *sound* of the weight it removes, or greed stops costing "
			+ "speed and `DES-005` Layer 1 collapses")

	# ─ 6. an ember stops weighing what a friend weighs, and stays as loud ─
	player.effects = PackedStringArray()
	player.inventory.clear()
	player.inventory.add(ItemCatalogue.by_id(&"con_ember"))
	await _hold(0.3)
	var heavy: float = player.inventory.total_weight()
	var loud: float = player.inventory.total_clamor()
	player.effects = PackedStringArray(["ember_is_light"])
	await _hold(0.3)
	print("[wing] an ember            %.1f kg → %.1f, clamor %.1f → %.1f" % [
		heavy, player.inventory.total_weight(), loud,
		player.inventory.total_clamor()])
	if heavy <= 0.0:
		problems.append("an ember weighed nothing to begin with")
	elif player.inventory.total_weight() >= heavy:
		problems.append("Bearer's Grace did not lighten the ember")
	if player.inventory.total_clamor() != loud:
		problems.append("Bearer's Grace changed how loud an ember is — "
			+ "`DES-012` charges the rescue in squares, weight **and** noise, "
			+ "and a node that paid off all three deletes the sacrifice the "
			+ "co-op gate is about")

	# ─ 7. the keystone: struck, and then not there ─
	player.effects = PackedStringArray(["recall_on_damage", "recall_is_loud"])
	player.restore_for_descent()
	player.teleport(ARCHER_POST, 0.0)
	await _hold(tuning.recall_seconds + 0.5)
	var was_at: Vector3 = player.global_position
	player.teleport(BUTT_POST, 0.0)
	await _hold(0.4)
	var struck_at: Vector3 = player.global_position
	var before_health: float = player.health.current
	player._on_hurt(10.0, null)
	await _hold(0.3)
	var moved: float = struck_at.distance_to(player.global_position)
	print("[wing] struck at %.0f, %.0f  → moved %.1f m, health %.0f → %.0f" % [
		struck_at.x, struck_at.z, moved, before_health, player.health.current])
	if moved < 1.0:
		problems.append(("the keystone did not move the body (%.1f m) — "
			+ "`DES-004` returns you to where you stood, and escape is the "
			+ "whole identity of this Aspect") % moved)
	if player.health.current >= before_health:
		problems.append("the blow did no damage — the recall fires **after** "
			+ "it lands, or the keystone is invulnerability once a floor, "
			+ "which is not what escape means")

	# ─ 8. once per floor, and it costs the room ─
	# **Asked of the spend, not of the distance.** A second recall lands on a
	# breadcrumb dropped since the first one, which after a moment standing
	# still is wherever you already are — so "it did not move far" is true of a
	# keystone that fired again, and the row read as a pass with the once-per-
	# floor guard deleted.
	var second_from: Vector3 = player.global_position
	var fired_again: bool = player._try_to_recall(player.global_position)
	await _hold(0.3)
	print("[wing] a second time       fired=%s, moved %.1f m (want no, 0)" % [
		fired_again, second_from.distance_to(player.global_position)])
	if fired_again:
		problems.append("the keystone fired twice on one floor — `DES-004` "
			+ "says once, and a recall you can rely on repeatedly is a rhythm "
			+ "rather than a decision")
	var roar: float = _peak_near(struck_at)
	print("[wing] the ground it left  %.2f clamor" % roar)
	if roar <= 0.0:
		problems.append("the escape was silent — every keystone in `DES-004` "
			+ "has a real drawback and the document names none for this one, "
			+ "so it is the noise: you told the floor which room the fight "
			+ "was in")

	_report(problems, "wing")


## Walk a few steps from a settled start and report the **peak** it reached.
##
## The first draft reset `clamor.level`, walked, and returned the difference —
## and the second call always read **0.00**, because the level was still
## saturated from the first walk and a `ClamorSource` decays toward its carried
## floor rather than to zero on demand. So the row reported *1.83 → 0.00* with
## the node working **and** with its reader deleted: twelfth assertion this
## milestone that passed for the wrong reason, and the only one found by a plant
## that was itself correct.
##
## Settled start, peak rather than delta, and back to the same place each time,
## so the two measurements are of the same walk.
func _walk_and_listen(player: Player, crouched: bool) -> float:
	player.teleport(ARCHER_POST, 0.0)
	# **Through the input, not by assigning `stance`.** `_update_stance` recomputes
	# it from the crouch action every frame, so a direct assignment is gone
	# before the next physics tick — and both walks were measuring a *standing*
	# body, which is why the node appeared to change nothing and, earlier, why
	# it appeared to work with its reader deleted.
	if crouched:
		Input.action_press("crouch")
	else:
		Input.action_release("crouch")
	for settle: int in range(20):
		await get_tree().physics_frame
	# Wait for the last walk to fade, or this measures that one instead.
	for settle: int in range(240):
		await get_tree().physics_frame
		if player.clamor.level <= 0.01:
			break
	var peak: float = 0.0
	for step: int in range(24):
		player.global_position += Vector3(0.28, 0.0, 0.0)
		await get_tree().physics_frame
		peak = maxf(peak, player.clamor.level)
	Input.action_release("crouch")
	return peak


## Is this tag consulted anywhere in the build? Read off the source, because the
## question is *does a system react* and no runtime check can answer that for a
## tag whose node nobody has bought.
func _tag_is_read(tag: StringName) -> bool:
	for path: String in ["res://actors/player/player.gd",
			"res://actors/enemies/enemy.gd", "res://actors/shaft.gd",
			"res://components/inventory.gd", "res://components/stamina.gd",
			"res://ui/reticle.gd", "res://actors/enemies/gullsjukr.gd"]:
		var source: FileAccess = FileAccess.open(path, FileAccess.READ)
		if source == null:
			continue
		var text: String = source.get_as_text()
		source.close()
		if text.contains('&"%s"' % tag):
			return true
	return false


## Bodies move on the floor, and they do not know where you went (`M4-T16`).
##
## `M4-T16`'s fourth item asks for enemies that *"use the floor's geometry
## rather than walking through it"*, raised from the same play session as
## *"the ai needs to path better"*. **That was already answered** — `M2-T14`
## gave every body a `NavigationAgent3D` and a baked region after finding there
## was no pathfinding at all. Three separate measurements went looking for a
## defect here and found correct behaviour each time (ADR-197). What was
## missing was not the system, it was anything that proves the system.
##
## Two claims, and the second is the one nothing has ever tested:
##
## 1. **The floor is what bodies move on.** A route the enemies' own navigation
##    map returns between two rooms with a wall between them is meaningfully
##    longer than the straight line — it goes round, because there is no
##    through.
## 2. **An enemy goes where it last *saw* you, not where you are.** `DES-013`
##    and `PRO-005` §5 make that a fairness requirement rather than a flourish:
##    the player must always be able to explain how they were found, and be
##    able to bait it. A body that closed on a player it could not see would
##    break stealth silently, and every probe in this repository would stay
##    green while it did.
func _ground_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var player: Player = _session.local_player()

	# Entrance (east side) and the west corridor. A wall divides them and the
	# only way through is a doorway 4 m off the direct line, which is what
	# makes both halves below mean something.
	var from_room: Vector3 = Vector3(4.0, 0.1, 2.0)
	var to_room: Vector3 = Vector3(-9.0, 0.1, -5.0)


	# ── 2. it goes to where it saw you, not to where you are ─────────────
	var post: Vector3 = Vector3(4.0, 0.1, 2.0)
	var bait: Vector3 = Vector3(4.0, 0.1, -0.5)
	_session.clear_enemies()
	await _hold(0.4)
	player.restore_for_descent()
	player.teleport(bait, 0.0)
	# Yaw 0 is -Z, which is where `bait` sits; `PI` faced it away and the row
	# below reported a body that had not noticed somebody 2.5 m in front of it.
	_session.spawn_enemy(post, 0.0)
	await _hold(1.2)
	var chaser: Enemy = _first_live_enemy()
	if chaser == null:
		problems.append("no enemy spawned, so nothing here is about pathing")
		_report(problems, "ground")
		return

	var acquired: bool = false
	for i: int in range(240):
		await get_tree().physics_frame
		if chaser.is_hunting():
			acquired = true
			break
	print("[ground] saw the player            %s" % ("yes" if acquired else "NO"))
	if not acquired:
		problems.append("the enemy never noticed a player standing 2.5 m in "
			+ "front of it, so what it does next is not about geometry")
		_report(problems, "ground")
		return

	# Round the corner and out of sight. It cannot see through the wall, so
	# what it does next is the whole of the fairness rule.
	player.teleport(to_room, 0.0)
	var nearest_bait: float = INF
	var nearest_player: float = INF
	for i: int in range(600):
		await get_tree().physics_frame
		nearest_bait = minf(nearest_bait, chaser.global_position.distance_to(bait))
		nearest_player = minf(
			nearest_player, chaser.global_position.distance_to(player.global_position))
	print("[ground] reached where it saw you  %5.1f m away" % nearest_bait)
	print("[ground] closest to where you are  %5.1f m (want it kept away)"
		% nearest_player)
	if nearest_bait > 2.0:
		problems.append(("it never reached the spot it last saw the player — "
			+ "closest %.1f m. `DES-013` has SUSPICIOUS investigate the last "
			+ "known position, and a body that does not go there cannot be "
			+ "baited, which is counter-play `DES-005` sells") % nearest_bait)
	# **The cheat check.** Nothing else in this repository asks it.
	if nearest_player < 6.0:
		problems.append(("it closed to %.1f m of a player it had never seen "
			+ "there — an enemy that tracks a position it was not given is "
			+ "stealth broken silently, and `PRO-005` §5 makes explaining how "
			+ "you were found a requirement") % nearest_player)
	# ── the floor is what bodies move on ─────────────────────────────────
	#
	# **Asked last, deliberately.** `_build_navigation`'s own comment records
	# that the bake completes on a worker thread some frames after
	# `bake_navigation_mesh()` returns, so a query issued on this probe's first
	# frame comes back empty from a map that is perfectly healthy — which reads
	# exactly like the failure it is not.
	var map: RID = get_world_3d().get_navigation_map()
	var route: PackedVector3Array = NavigationServer3D.map_get_path(
		map, from_room, to_room, true)
	var walked: float = 0.0
	for i: int in range(1, route.size()):
		walked += route[i - 1].distance_to(route[i])
	var straight: float = from_room.distance_to(to_room)
	# Where the route crosses the dividing wall, against the only opening in it.
	var door: Vector3 = Vector3(-7.0, 0.1, -2.0)
	var by_the_door: float = INF
	for corner: Vector3 in route:
		by_the_door = minf(by_the_door, Vector2(corner.x - door.x, corner.z - door.z).length())
	print("[ground] route corners             %d" % route.size())
	print("[ground] straight %5.1f m   by the floor %5.1f m   (%.2f x)" % [
		straight, walked, walked / maxf(straight, 0.001)])
	print("[ground] route passes the doorway  %5.1f m (straight line: 3.6 m)"
		% by_the_door)
	if route.size() < 2 or walked <= 0.0:
		problems.append("the navigation map returned no route between two "
			+ "rooms a player can walk between — bodies would fall back to "
			+ "straight lines and press into the dividing wall")
	# **Where it goes, not how far.** A ratio cannot tell this apart — the door
	# sits nearly on the direct line, so routing correctly costs 0.5 m on 14.8.
	# What separates a real route from a line through solid ground is that it
	# passes the opening: the straight line crosses the wall at about x -3.4,
	# which is 3.6 m from the door.
	elif by_the_door > 1.5:
		problems.append(("the floor route misses the doorway by %.1f m, so it "
			+ "is crossing the dividing wall rather than going through the only "
			+ "opening in it") % by_the_door)

	_report(problems, "ground")
