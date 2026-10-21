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
## The gold at the Shaft's foot, so `--vista-probe` can find it in the built
## world rather than counting on the constant that made it (`M4-T23`).
const UNDERLIGHT_GROUP: StringName = &"shaft_underlight"

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
## How the fog fills in between `floor_fog_begin` and `floor_fog_end` ⟨tune⟩.
##
## **A straight ramp, chosen off the sweep rather than reasoned to.** The first
## draft held the near half back at 1.6, on the theory that the room you are
## standing in should be untouched — and `--fog-shot` shows that 1.6 leaves the
## far skyline still legible as a ghost, because holding the middle distance
## back is precisely holding back the part that reads the layout. `floor_fog_begin`
## already protects the near field; the curve does not need to protect it twice.
## 0.6 also clears the skyline and moves half again as many pixels to do it, so
## 1.0 is the least that works (`M4-T26`, ADR-203).
const FOG_CURVE: float = 1.0
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

const NAV_AGENT_RADIUS: float = 0.45
const NAV_AGENT_HEIGHT: float = 1.8
## The rise every navmesh treats as walkable. Deliberately more than the 0.10 m
## the player's capsule climbs — see `nav_settings` for why, and for what holds
## it to the body instead (ADR-214).
const NAV_AGENT_CLIMB: float = 0.3

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
## **Where the Lodge's cairn stands on the Deep** (ADR-241): the west branch,
## the bypass, so a Survey here is a detour and nothing else. At the room's
## north end, clear of the barricade — it stood inside it at `(-9, -10)` until
## ADR-242 added it to the sight probe's body check.
const SURVEY_AT: Vector3 = Vector3(-8.4, 0.1, -15.6)
## **The Deep's barrow** (`M4-T04`, ADR-242): `[item, position]`. In the east
## corridor, two rooms back from the Shaft on the way the held route comes, and
## not the west, which keeps the cairn — so the walk back to it is past the
## posts. A torc, because the Deep stands in for floor one.
const BARROW: Array = [&"glt_gilded_torc", Vector3(11.0, 0.1, -3.6)]

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

var _session: CoopSession = null
var _field: ClamorField = null
var _hunter: Gullsjukr = null
var _shaft: Shaft = null
## `DES-019` Layer 3's one bit and Layer 4's frames (`M4-T20`). Held because
## `_relayout_hud` has to find them again on every resize.
var _waystone: WaystoneMark = null
var _party: PartyFrames = null
var _wound_marks: WoundMarks = null
## The Deep's one line about a profile it will not write (ADR-246), or null.
var _not_saving: Label = null
## The layer the HUD hangs off, so a contract met mid-floor can say so there.
var _hud: CanvasLayer = null
## This floor's contracts (`M4-T04`, ADR-241). Rebuilt with the floor.
var _ledger: ContractLedger = null
## This floor's barrow (`M4-T04`, ADR-242), or null on a floor that has none.
var _barrow: Barrow = null
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
## **Peers walking back in** (ADR-410): granted a Return, choosing the next life,
## not yet built again. Host-side. A returning peer is still in the run, so the
## wipe waits for them, and the entry goes when the new body stands.
var _returning: Dictionary = {}
## Peer → the Scars that peer's life takes when the run resolves (`M4-T14`,
## ADR-240), decided **at the exit** — a concussion that walked out and wore off
## while its owner waited for the party still walked out. Cleared with the floor.
var _wounds_out: Dictionary = {}
## Set when somebody presses TO THE FIRE, which ends the wipe window early
## (ADR-151). The wait is a floor rather than a fixed price.
var _skip_the_wait: bool = false
## The screen that says the run is over, or null. Held so a second body going
## out does not build a second one, and so a cancelled wipe can take it away.
var _run_over: CanvasLayer = null
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
## Seconds between asking which room the ear is in ⟨tune-free⟩: a body crosses
## a doorway in longer than this, and the reverb crossfades anyway.
const ROOM_ASKED_EVERY: float = 0.2
## How much of the Hunter has to be behind stone before its sound comes through
## a doorway instead of from where it stands ⟨tune⟩: more than half of it, so a
## Hunter framed in a doorway is still heard in that doorway rather than jumping
## to the next one along.
const HEARD_THROUGH_STONE: float = 0.5
var _room_asked: float = 0.0
## What the field read where somebody came down, for `--late-probe`.
var _probe_arrival_clamor: float = 0.0

## What `--crossing-probe` is owed on the far side of a floor transition.
##
## **Static because the node does not survive** (ADR-264). A crossing frees the
## scene that began it, so an expectation kept on `self` dies with the floor it
## was written on — which is exactly why no check had ever crossed. A static
## outlives the scene change; the arrival reads it and reports.
##
## Empty means no crossing is in flight, which is also how the arrival tells
## itself apart from the departure.
static var _crossing: Dictionary = {}


## **Whether these arguments make a run a measurement** (no brief, no scene
## change). Read off each flag's *name*, not its value (B143):
## `--walkthrough=…/shots/walk` is not a shot, and read whole it hid the
## brief the walkthrough exists to show.
static func measures(args: PackedStringArray) -> bool:
	for arg: String in args:
		var flag: String = arg.split("=", true, 1)[0]
		if flag.contains("probe") or flag.contains("shot") or flag.contains("capture"):
			return true
	return false


func _ready() -> void:
	# **First, before anything reads it.** Any probe at all means this process
	# is measuring the floor rather than playing the loop — extraction must not
	# change scene out from under it, and the arrival brief must not fade three
	# labels across a screenshot. This used to be decided *after* `_build_hud`,
	# so a HUD element asking `_probing` would silently always see `false`.
	_probing = measures(OS.get_cmdline_user_args())
	for arg: String in OS.get_cmdline_user_args():
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
		# **A stash to carry down** (ADR-228), before the floor carries it. The
		# `--as-class=` lever for the one thing a harness process has no profile
		# to hold: two processes on one machine cannot both have banked gear, and
		# a client's stash reaching its bag is the question.
		if arg.begins_with("--as-stash="):
			for id: String in arg.split("=", true, 1)[1].split(",", false):
				var banked: ItemResource = ItemCatalogue.by_id(StringName(id))
				if banked != null:
					GameState.stash.append(ItemInstance.of(banked, GameState.stash.size() + 1))
		# **A cycle that closed short, set up before the floor exists**
		# (ADR-124). The whole question is what the *floor* does about it, and
		# a debt arranged after `_ready` would be a reconstruction of the order
		# rather than the order — which is exactly how the bug this probe
		# exists for survived: every part was checked and the sequence was not.
		# **A refused profile, before the HUD that has to say so** (ADR-246): a
		# scratch profile from a newer build, opened the way the menu opens one.
		if arg.begins_with("--as-run="):
			# **A real expedition, for a check that is about one** (`M4-T15`).
			# The call down carries a seed and a floor, and a harness with no
			# run file on either side carries zeros — a handshake nothing can
			# be wrong about, which is how the row asserting it first passed
			# with `RunFile.begin` deleted. Scratch file first, always: a check
			# may not arm the player's run (ADR-152).
			RunFile.use_a_scratch_run()
			RunFile.arm()
			RunFile.begin(GameState.class_id, 1,
				int(arg.split("=", true, 1)[1]))
		if arg == "--under-way":
			# **The descent has happened** (`M4-T15`, ADR-250). Said by the
			# harness, because `Threshold._descend` is what says it in a played
			# game and a process launched straight into the Deep never walked
			# through that door — so without this a host in a level has an open
			# door and a knock is an ordinary join rather than a late one.
			CoopSession.the_party_has_gone_down()
		if arg == "--saving-probe":
			SaveFile.plant_a_newer_one()
			GameState.load_profile()
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
	# **What a floor costs to make** (B154): planned and built, on the clock
	# `TEC-001`'s two-second budget is written against, printed for every
	# generated floor so a slow seed in a bug report names itself.
	var making: int = Time.get_ticks_usec()
	var planned: int = 0
	if generated:
		var rolled := DelvingsFloor.of(_run_seed, depth)
		planned = Time.get_ticks_usec() - making
		if not rolled.problems().is_empty():
			push_error("the Delvings would not plan: %s"
				% " · ".join(rolled.problems()))
			return
		_floor = rolled
		print("[delvings] seed %d, floor %d" % [_run_seed, depth])
	AudioDirector.enter("deep")
	Foley.warm()
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
	_build_barrow()
	var overlays := DebugOverlays.new()
	_world.add_child(overlays)
	overlays.show_field(_field)
	# **The Lodge's work on this floor** (`M4-T04`, ADR-241), before the HUD so
	# the arrival brief can say it.
	_open_the_ledger()
	_build_hud()
	add_child(PauseMenu.new())
	# **And out of it** (B174): every arrival lifts off black, the twin of the
	# fall that came before it. Not under a probe, whose first frame is a shot.
	if not _probing:
		Curtain.lift(self)
	# After `_probing` is known and never before it. A probe that inherited a
	# loadout would be measuring a bag it did not pack — and the reason this is
	# a real hazard rather than a hypothetical one is that it reads correct
	# today only because a fresh process starts with an empty stash. The gate
	# is here rather than inside, so `--exit-probe` can still call it directly
	# and assert what it does.
	# **`--crossing-probe` is the exception, and it earns it.** The gate above
	# keeps a probe from inheriting a loadout it did not pack; a crossing probe
	# packed this one itself, on the floor it just left, and whether the bag
	# survives the transition is the thing it is measuring.
	if not _probing or not _crossing.is_empty():
		_carry_the_stash_down()
	if generated:
		print("[delvings] made in %d ms (planned %d, built %d)" % [
			(Time.get_ticks_usec() - making) / 1000, planned / 1000,
			(Time.get_ticks_usec() - making - planned) / 1000])
	# **Then, and only in a measurement, the measuring** (ADR-411). The probes
	# live in `RoomSetProbed` under `tests/`, which no export carries; this
	# level is the game's, and a harness launch plays the subclass.
	_measure(OS.get_cmdline_user_args())


## Put the Deep's two placed elements back in their regions (`M4-T20`).
##
## On the viewport rather than once at build: `HudFrame`'s regions are fractions
## of the window, so a resize moves them and an element that placed itself once
## would sit where the window used to be. The Chamber learned this the same way
## and `relayout` there is this function's twin.
func _relayout_hud() -> void:
	if _waystone == null or _party == null or _wound_marks == null:
		return
	var screen: Vector2 = get_viewport().get_visible_rect().size
	HudFrame.place(_waystone, HudFrame.Region.BURDEN, screen)
	HudFrame.place(_party, HudFrame.Region.PARTY, screen)
	HudFrame.place(_wound_marks, HudFrame.Region.BODY, screen)
	# **`settle` as well as `place`, or both of these draw a line.** `place`
	# promises width and sets height to zero, which is correct for a container
	# that grows its own and wrong for a `Control` that paints into `size`. A
	# free `Control` is never grown to its minimum by anybody — the same fact
	# that made the Chamber's speech region measure 0×0 and pass (ADR-198).
	HudFrame.settle(_waystone, HudFrame.Region.BURDEN, screen)
	HudFrame.settle(_party, HudFrame.Region.PARTY, screen)
	HudFrame.settle(_wound_marks, HudFrame.Region.BODY, screen)
	if _not_saving != null:
		HudFrame.place(_not_saving, HudFrame.Region.PLACE, screen)


## What the Deep claims of the frame, for the windowed measurement (`M4-T20`).
##
## The grammar half of the overlap check runs headless in `--hud-probe` and asks
## whether the *regions* collide. This is the other half — whether what is
## actually drawn is inside the region it claimed — and it has to run windowed,
## because `_draw` never executes headless and writing it headless-first
## produced fiction once already (ADR-198).
func hud_claims() -> Dictionary:
	var claims: Dictionary = {
		"WAYSTONE": [HudFrame.Region.BURDEN, HudFrame.occupied_by(_waystone)],
		"PARTY": [HudFrame.Region.PARTY, HudFrame.occupied_by(_party)],
		"WOUNDS": [HudFrame.Region.BODY, HudFrame.occupied_by(_wound_marks)],
	}
	if _not_saving != null:
		claims["SAVING"] = [HudFrame.Region.PLACE, HudFrame.occupied_by(_not_saving)]
	return claims


## Print the world fingerprint and quit (`M1-T07`). Two processes given the
## same seed must print the same line; `tools/check_determinism.py` runs them
## and compares. Waits for physics to settle first, because a body that has not
## finished resolving its first frame reports a position that is *nearly*
## right, which is exactly the kind of near-miss this must not tolerate.
## The run seed the host would have sent (`TEC-001`: visible and shareable).
## Zero when nobody passed one, which is a real seed and not a missing value.
var _run_seed: int = 0


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
	_hud = layer
	# Vignette first, so it sits *behind* the Ear and the Reticle rather than
	# darkening them. It is the only full-screen element here and the two
	# readouts have to stay legible while you are being hit — which is exactly
	# the moment they matter most.
	layer.add_child(WoundVignette.new())
	layer.add_child(Ear.new())
	layer.add_child(Reticle.new())
	# The party's marks and the gesture wheel (`M4-T05`, ADR-244).
	layer.add_child(PingLayer.new())
	# **What is happening to you, while it happens** (`M3-T14`, `DES-012`).
	# Not gated on `_probing`, unlike the arrival brief below: it draws nothing
	# at all unless the body holding the camera is down or loose, so it cannot
	# fade over a screenshot — and a probe that downs a player deliberately
	# should be exercising it rather than hiding it.
	layer.add_child(FallenReadout.new())
	# **`DES-019` Layers 3 and 4, in the regions `HudFrame` already named for
	# them** (`M4-T20`, ADR-212). Until now the Deep's HUD placed everything by
	# literal and these two did not exist at all: *do I have a way out* was only
	# answerable by opening the bag, which `DES-019` designs as a vulnerable act,
	# and whether a teammate was up, down or a Vörðr was answerable nowhere.
	#
	# Placed rather than positioned, so `--hud-probe`'s grammar owns where they
	# are and `_relayout_hud` is the only thing that moves them.
	_waystone = WaystoneMark.new()
	layer.add_child(_waystone)
	_party = PartyFrames.new()
	layer.add_child(_party)
	# **Layer 2's wounds** (`M4-T14`, ADR-239), in the region `HudFrame` named
	# for health, stamina and wounds — the first thing ever placed in it.
	_wound_marks = WoundMarks.new()
	layer.add_child(_wound_marks)
	# **Nothing here is being kept** (`M4-T06`, ADR-246): said in the corner the
	# Deep does not use, for as long as it is true — every descent under it is
	# thrown away, and a player owed that sentence is owed it all the way down.
	if GameState.refused_a_profile():
		_not_saving = MenuStyle.line(tr("ui.not_being_saved"), MenuStyle.CAPTION_FAULT)
		_not_saving.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		layer.add_child(_not_saving)
	_relayout_hud()
	get_viewport().size_changed.connect(_relayout_hud)
	# Not while a probe is measuring the floor: it would be three labels
	# fading over a screenshot, and `--ear-shot` in particular photographs
	# exactly the frames this covers.
	if not _probing:
		var brief := ArrivalBrief.new()
		# Set before it enters the tree: `ArrivalBrief._ready` is where its
		# lines are built, and a fourth one added afterwards would arrive under
		# a label that has already been laid out.
		brief.sent_early = _she_sent_it_early
		# What the Lodge wants here, from where the party stands (ADR-241).
		if _ledger != null and not _floor.spawns().is_empty():
			brief.notes = _ledger.lines(_floor.spawns()[0])
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
		# The verb, once a run (ADR-365): the first floor's brief, and not the
		# deeper ones — `PRO-005` §8's price of a line said every time.
		if _floor_index == 0:
			brief.verb = ArrivalBrief.verb_line(GameState.class_id)
			brief.lantern = ArrivalBrief.lantern_line(GameState.class_id)
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
## Whether this floor's gates stand yet (ADR-381).
var _doors_placed: bool = false

var _probe_ending: bool = false
## Client-side: the host has written its report (ADR-244).
var _probe_host_wrote: bool = false
@rpc("any_peer", "reliable")
func _end_probe() -> void:
	if multiplayer.is_server():
		_probe_ending = true


## The host has written its report, so a client may leave (ADR-244).
@rpc("authority", "reliable")
func _host_wrote() -> void:
	if multiplayer.get_remote_sender_id() == HOST_PEER:
		_probe_host_wrote = true


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
		# **The floor says who** (ADR-237): a Warden at the door into the held
		# arm, a slinger in a hall wide enough, a Bellringer in one ordinary body
		# in four — by index, for the same reason the ring is: body *n* is the
		# same body however many people the floor grew for.
		_session.spawn_enemy(post, 0.0, _floor.enemy_kind(index))
	if _enemies_placed == 0:
		# The Guardian faces its prize's doorway and never leaves the room.
		_session.spawn_enemy(_floor.guardian(), 0.0, _floor.guardian_kind())
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
	_spawn_doors()
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
	var mesh := nav_settings(NavigationMesh.new())
	# By group rather than by children: the geometry hangs off `_world` as a
	# flat list of slabs, and re-parenting all of it under the region purely to
	# be baked would change every node path in the level for no gain.
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


## **The floor's gates, standing** (ADR-381). Before the loot's stripped
## check, because a door is the floor and not its loot: a resumed floor has
## its doors. Host-side, once; the navmesh is baked again with them shut, and
## again each time one opens, so the Deep's dead go the long way round until
## somebody opens the short one.
func _spawn_doors() -> void:
	if _doors_placed or _session == null or not _session.is_host():
		return
	_doors_placed = true
	var placed: int = 0
	for row: Array in _floor.doors():
		var door: LockedDoor = _session.spawn_door(row[0] as Vector3, float(row[1]),
			int(row[2]) as LockedDoor.Kind, row[3] as Vector3)
		if door == null:
			continue
		door.add_to_group(NAV_SOURCE_GROUP)
		# **Out of the bake before it is baked again.** Opening only disables
		# the collider deferred, and the bake reads static colliders — so a
		# rebake in the same frame read the door as still shut, and the dead
		# kept going the long way through an open door. Leaving the group is
		# true whatever the parser makes of a disabled shape.
		door.opened.connect(func(opened: LockedDoor) -> void:
			opened.remove_from_group(NAV_SOURCE_GROUP)
			_rebake_navigation.call_deferred())
		# Wedged shut again (ADR-382): back in the bake, and baked again.
		door.shut.connect(func(closed: LockedDoor) -> void:
			closed.add_to_group(NAV_SOURCE_GROUP)
			_rebake_navigation.call_deferred())
		placed += 1
	if placed > 0:
		print("[doors] %d gate(s) stand on this floor" % placed)
		_rebake_navigation.call_deferred()


## Bake the floor again, as it stands now — **on a thread** (B54). ADR-381
## guessed "a few milliseconds"; measured, it is 19 ms on the authored floor
## and 51 ms on a generated one, three dropped frames on the host each time a
## door opens. The first bake stays synchronous (`_build_navigation`: the map
## has to exist before the first enemy asks); a rebake does not, because the
## old map stands until the new one replaces it, and for those few frames the
## dead simply still think the door is shut.
func _rebake_navigation() -> void:
	if _navigation != null and is_instance_valid(_navigation):
		_navigation.bake_navigation_mesh(true)


## What the navmesh is baked *for*, in one place.
##
## **Both bakes read this.** `_build_navigation` bakes the floor the game plays
## on and `--build-probe` bakes one to measure it, and while those were two
## lists of the same six assignments the probe could have been measuring a mesh
## the game never builds. ADR-200 had to change `cell_size` in both — the
## duplication arriving as a chore before it arrived as a bug, which is the only
## warning this kind gives.
static func nav_settings(mesh: NavigationMesh) -> NavigationMesh:
	mesh.agent_radius = NAV_AGENT_RADIUS
	mesh.agent_height = NAV_AGENT_HEIGHT
	# **0.30 m, and it is not the body's number** (ADR-214).
	#
	# The player climbs about **0.10 m** — a 0.35 m capsule rolls over
	# `r(1 − 1/√2)` and no further — so a mesh that allows 0.30 m promises rises
	# the body cannot take, and ADR-205 found four floors in nine where it did.
	# ADR-209 answered with a step-up on the body; ADR-213 found the real fault
	# was corridor ramps tilted through turns, after which the step fired **zero
	# times** on the walk panel, and ADR-214 removed it.
	#
	# **Making the mesh describe the body was measured and it breaks the floor.**
	# At a 0.10 m climb all five ledges on the reference floor went unreachable,
	# a room fell off the mesh, and the standard bake routed 19 floors of 24 —
	# so the joins this generator lays lean on Recast merging surfaces within
	# the climb, and a mesh honest about the body is a mesh of islands.
	#
	# So the mesh stays generous and **the walk is the guard**: `--reach-probe`
	# drives the real capsule along the routes this mesh promises and fails any
	# floor it cannot cross, naming the slab it stopped against (ADR-213). A
	# rise that is a surface to Recast and a wall to the body is found there,
	# not reasoned away here.
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
	#
	# **0.10, because 0.15 divided 0.45 exactly and that is a knife-edge**
	# (ADR-200). `ceil(0.45 / 0.15)` is 3.0 with nothing to spare, so whether a
	# doorway survived voxelisation came down to where its walls happened to
	# fall against the grid — which varies by seed. Measured: seed 78901 baked
	# floor 0 as two components with the party sealed in the entrance room, and
	# no change to radius, height, climb or slope touched it. A 0.10 cell erodes
	# by `ceil(0.45 / 0.10)` = 0.50 m, five centimetres *more* than the agent
	# asks for, and connects all sixteen seeds measured. The mesh costs about a
	# fifth more vertices — 712 to 838 on the reference floor — and bakes in the
	# same second. Conservatism at 5 cm is cheaper than a floor with no route.
	mesh.cell_size = 0.10
	mesh.cell_height = 0.10
	# The climb — see the note above `agent_max_slope`.
	mesh.agent_max_climb = NAV_AGENT_CLIMB
	mesh.geometry_parsed_geometry_type = \
		NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_source_geometry_mode = \
		NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	return mesh


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
	# **Its walls learned while the floor is made** (ADR-405), not on its first
	# pass a tenth of a second into play, where the ~30 ms was a dropped frame.
	# On the host, the only peer the field runs on.
	if multiplayer.is_server():
		_field.learn_walls()
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
		var learned: Dictionary = RunFile.hunt_lessons()
		_hunter.remember(learned)
		if not learned.is_empty():
			print("[hunt] it remembers %s" % str(learned))
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
	_light_what_is_under(_shaft.position)
	_shaft.claimed.connect(_on_shaft_claimed)
	for player: Player in _session.players():
		_watch(player)
	_session.player_spawned.connect(_watch)


## **The Shaft frames what is under it** (`M4-T23`, `DES-015` Layer 4, ADR-204).
##
## `DES-015` asks for two things and `M4-T01` built one: value climbs steeply
## with depth — 8 → 70 → 140 (ADR-220) — *and the player must be able to see that from
## floor 1*. Nothing said it. A gradient nobody can perceive changes no
## decision, so the half that was built meant nothing on the floor a player is
## standing on.
##
## **Gold at the foot, and the column stays pale.** `M2-T13`'s vocabulary is
## that pale light is the way through and gold light is what it will cost you,
## and the Shaft is now both things at once — it is the way down *and* the thing
## worth going down for. Splitting them by colour keeps the rule intact rather
## than bending it: the beacon is `Shaft.IDLE`, unchanged, and what pools around
## its base is treasure light from a floor you cannot see yet. Light through the
## seams of a hatch, which is also the diegetic reading.
##
## **Nothing is dug.** The floor under the pad stays solid: a visible hole would
## be a fall, a navmesh cut and a `--reach-probe` row, to show a floor that does
## not exist — a party builds one floor at a time (ADR-184). What is honest here
## is the *light*, and the fog `M4-T26` added is what turns it into a glow with
## no visible origin rather than a lamp lying on the ground — Kaplan & Kaplan's
## **mystery** (`TEC-008` §2.4), which that section calls the single most
## actionable idea in the whole review.
##
## **The bottom floor gets none, and that is the load-bearing case.** There the
## Shaft `leads_out` (ADR-186), so a glow under it would promise a floor that is
## not there — and on the one floor where the Shaft is the way *home*, gold at
## its foot would say *cost* about the exit, which is precisely the sentence
## `M2-T13` spent a whole task making the palette incapable of.
func _light_what_is_under(at: Vector3) -> void:
	if _shaft == null or _shaft.leads_out:
		return
	var below: int = DelvingsFloor.best_find(_floor_index + 1)
	var deepest: int = DelvingsFloor.best_find(RunFile.LAST_FLOOR)
	if below <= 0 or deepest <= 0:
		return
	# **The same light the thing itself would pour.** A Shaft over a floor whose
	# best find is worth 140 glows like a 140 lying in front of you, because it
	# is the same claim about the same object — one number, read twice, rather
	# than a second scale to drift from the first.
	var t: float = clampf(float(below) / float(deepest), 0.0, 1.0)
	var glow := OmniLight3D.new()
	glow.add_to_group(WorldItem.TREASURE_LIGHT_GROUP)
	glow.light_color = WorldItem.TAG_COLOURS[&"glitter"]
	glow.light_energy = lerpf(
		WorldItem.GLIMMER_ENERGY.x, WorldItem.GLIMMER_ENERGY.y, t)
	glow.omni_range = lerpf(
		WorldItem.GLIMMER_RANGE.x, WorldItem.GLIMMER_RANGE.y, t)
	glow.position = at + Vector3(0.0, 0.3, 0.0)
	glow.add_to_group(UNDERLIGHT_GROUP)
	_world.add_child(glow)
	print("[shaft] floor %d stands over a best find of %d — its foot pours "
		% [_floor_index, below] + "%.1f at %.1f m"
		% [glow.light_energy, glow.omni_range])


## The Shaft is channelled here rather than driving itself, so the level owns
## the one clock that can end a run. `Shaft.advance` is host-guarded, so this
## costs a client nothing.
func _physics_process(delta: float) -> void:
	_sound_of_the_room(delta)
	if _shaft != null:
		_shaft.advance(delta)
		# **A finished channel may have taken the floor with it** (ADR-276).
		# The claim ends in `change_scene_to_file`, which detaches this node
		# before `advance` returns — and everything below asks the tree it is
		# no longer in. In the editor that is a script error; exported, the
		# null check is compiled out and it is a segfault.
		if not is_inside_tree():
			return
	# **The barrow wakes when somebody reaches the way on** (ADR-242), and the
	# level decides it because the level knows where the way on is.
	if _barrow != null and multiplayer.is_server():
		_barrow.advance(delta)
		if _barrow.is_sealed() and _someone_at_the_way_on():
			_wake_the_barrow()


## **The room the ear is standing in** (`M4-T12`, `TEC-005`), handed to the
## director a few times a second.
##
## The level asks, rather than the director reaching in: only the floor knows
## its rooms, and `AudioDirector` is an autoload that would otherwise have to
## know what a floor is (`TEC-002`: signals up, calls down).
func _sound_of_the_room(delta: float) -> void:
	_room_asked -= delta
	if _room_asked > 0.0:
		return
	_room_asked = ROOM_ASKED_EVERY
	var body: Player = _session.local_player()
	if body == null:
		return
	AudioDirector.room_is(_floor.room_across(body.global_position))
	_the_hunter_is_heard(body.global_position)


## **Where the Hunter's own weight is heard from** (`M4-T12`, ADR-249).
##
## `TEC-005` buys portal propagation for this one source and no other, because
## this is the one where *around the corner* and *through the wall* are
## different facts a player acts on. Seen, it sounds where it stands; unseen,
## its sound is put in the doorway a sound would actually reach you through,
## and what the detour cost is spent as loudness.
##
## The level does the placing because only the floor knows its doorways, and
## the body does the hearing because only the local peer has an ear (`TEC-004`).
func _the_hunter_is_heard(ear: Vector3) -> void:
	var hunter := get_tree().get_first_node_in_group(&"hunters") as Gullsjukr
	if hunter == null:
		return
	var at: Vector3 = hunter.global_position
	if Acoustics.stone_between(get_world_3d(), ear, at) < HEARD_THROUGH_STONE:
		hunter.heard_from(at, 0.0)
		return
	var way: Array = _floor.way_of_sound(ear, at)
	if way.is_empty():
		hunter.heard_from(at, 0.0)
		return
	hunter.heard_from(way[0] as Vector3, float(way[1]))


## **The barrow behind you** (`M4-T04`, ADR-242, `DES-007` tier 3).
##
## Built on every peer at one path, like the Shaft, because it is the floor's
## and never moves; what it does is the host's. A floor resumed after its barrow
## woke finds it spent, for `stripped`'s reason: quitting must not re-seal it.
func _build_barrow() -> void:
	var row: Array = _floor.barrow()
	if row.is_empty():
		return
	_barrow = Barrow.new()
	_barrow.name = "Barrow"
	_barrow.position = row[1] as Vector3
	_barrow.configure_replication()
	_world.add_child(_barrow)
	_barrow.changed.connect(_on_barrow_changed)
	_barrow.broken_in.connect(_on_barrow_broken)
	if not multiplayer.is_server():
		return
	_barrow.hear_with(_field)
	# A probe measures the floor as built, never as resumed (`M3-T15`).
	if not _probing:
		_settle_the_barrow()


## Host: a floor whose barrow the run file says already woke keeps it spent.
func _settle_the_barrow() -> void:
	if _barrow != null and RunFile.barrow_woke():
		_barrow.spend()


## A standing body within `barrow_wake_reach` of the Shaft. A spent body lying
## there has decided nothing.
func _someone_at_the_way_on() -> bool:
	var reach: float = Config.tuning.barrow_wake_reach
	for player: Player in _session.players():
		if player.spent:
			continue
		var offset: Vector3 = player.global_position - _floor.shaft()
		offset.y = 0.0
		if offset.length() <= reach:
			return true
	return false


## Host: lay the find, open the slab, and write it down so a resumed floor
## remembers.
## **Broken back into** (ADR-382): sealed and woken again, so the same find
## lies in it and the same clock runs — the grind and all.
func _on_barrow_broken() -> void:
	if _barrow == null or not multiplayer.is_server():
		return
	_barrow.reseal(false)
	_wake_the_barrow()


func _wake_the_barrow() -> void:
	var row: Array = _floor.barrow()
	var find: WorldItem = _session.spawn_world_item(row[0] as StringName,
		row[1] as Vector3)
	_barrow.open(find)
	RunFile.note({"barrow": true})
	print("[barrow] floor %d woke — %s lies open at %.0f, %.0f for %.0f s" % [
		_floor_index, row[0], (row[1] as Vector3).x, (row[1] as Vector3).z,
		Config.tuning.barrow_open_seconds])


## Every peer says what its barrow did, from where its own body stands.
func _on_barrow_changed(now: int) -> void:
	if _probing or _hud == null or _barrow == null:
		return
	var body: Player = _session.local_player()
	if body == null:
		return
	var told: String = Barrow.said(now, body.global_position, body.rotation.y,
		_barrow.global_position)
	if told.is_empty():
		return
	var notice := ArrivalBrief.new()
	notice.notice = true
	notice.notes = PackedStringArray([told])
	_hud.add_child(notice)


func _watch(player: Player) -> void:
	player.extracted.connect(_on_extracted)
	player.died_here.connect(_on_died_here)
	# Raised only on the body's own peer, which is the one that asks (ADR-410).
	player.asked_to_return.connect(_ask_to_return)


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
	var wait: float = _wipe_seconds()
	print("[death] nobody is left standing — %.1f s and the run is over" % wait)
	# **Say so, and let it be ended** (`M3-T30`, ADR-151). ADR-108 gave reason 1
	# for this window as *"a cut to the camp on the frame you go out gives the
	# player nothing to read"* — right about the problem, and three seconds of
	# the same readout was not a solution. The wait is now a floor rather than a
	# fixed price: whoever is ready presses, and the clock is the backstop for
	# whoever is not.
	_the_run_is_over.rpc(wait)
	_skip_the_wait = false
	var until: float = Time.get_ticks_msec() + wait * 1000.0
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
func _the_run_is_over(seconds: float) -> void:
	if _run_over != null:
		return
	var screen := RunOverScreen.new()
	screen.leave_now.connect(_ask_to_end_it_now)
	# **Or walk back in** (ADR-410): offered to a body that still could, with
	# the window shortening beside it.
	var mine: Player = _session.local_player()
	screen.can_return = mine != null and mine.can_return()
	screen.window_seconds = seconds if screen.can_return else 0.0
	screen.return_now.connect(_ask_to_return)
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


## **How long a wipe waits** (ADR-410): `party_wipe_seconds` when nobody could
## still walk back in, and the ember's window when somebody could — with
## nobody left to carry it, Return or the end is the whole choice, and
## ADR-050 makes that window visible and shortening.
func _wipe_seconds() -> float:
	for body: Player in _session.players():
		if body.can_return() and not _borne_out.has(body.get_multiplayer_authority()):
			return Config.tuning.return_window_seconds
	return Config.tuning.party_wipe_seconds


# ── Return: the Vörðr's second exit (ADR-410, `DES-012`) ───────────────────
#
# A Vörðr gives up on being carried out: the ember goes out wherever it is,
# the life ends on its owner's machine, the Legacy flow opens where they
# stand, and the life they choose walks back in at the floor's entrance — the
# way she lets a soul back in, never beside the party (`DES-012` rule 2).

## The Legacy flow's claim on the body while the next life is chosen.
const RETURN_CLAIM: StringName = &"return"
## Frames to wait for the old body to leave before the new one is built
## (ADR-162: wait for gone, never count on one frame).
const RETURN_REBUILD_FRAMES: int = 30
## How long the Legacy flow stays up waiting for the new body, so a client is
## never left looking at a world with no camera in it.
const RETURN_ARRIVAL_MSEC: int = 8000


## A Vörðr asked, on its own peer: by a held key, or the run-over screen.
func _ask_to_return() -> void:
	if multiplayer.is_server():
		_grant_return(multiplayer.get_unique_id())
	else:
		_request_return.rpc_id(CoopSession.HOST_PEER)


@rpc("any_peer", "reliable")
func _request_return() -> void:
	if not multiplayer.is_server():
		return
	_grant_return(multiplayer.get_remote_sender_id())


## **The host decides a Return**, because the ember and the floor are the
## host's (`TEC-004`). Refused to a body that is not a Vörðr, whose ember
## already reached an exit, or that is already walking back in.
func _grant_return(peer: int) -> void:
	var body: Player = _session.player_for(peer)
	if body == null or not body.can_return() or _borne_out.has(peer) \
			or _returning.has(peer):
		print("[return] peer %d asked to walk back in, and cannot" % peer)
		return
	var put_out: int = _put_out_the_ember(peer)
	_returning[peer] = true
	print("[return] %s walks back in — %d ember(s) put out, and that life is over"
		% [body.name, put_out])
	if peer == multiplayer.get_unique_id():
		_begin_the_next_life()
	else:
		_return_granted.rpc_id(peer)


## **You cannot return and be rescued** (`DES-012` rule 1): every ember bound
## to `peer` goes out, lying on the floor or carried in somebody's bag.
func _put_out_the_ember(peer: int) -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(WorldItem.GROUP):
		var lying := node as WorldItem
		if lying != null and not lying.is_queued_for_deletion() \
				and lying.is_ember() and lying.bound() == peer:
			lying.queue_free()
			count += 1
	for holder: Player in _session.players():
		var carried: Array[int] = []
		for held: ItemInstance in holder.inventory.items():
			if held.bound_to == peer:
				carried.append(held.instance_id)
		for instance: int in carried:
			holder.inventory.remove(instance)
			count += 1
	return count


@rpc("authority", "reliable")
func _return_granted() -> void:
	_begin_the_next_life()


## **The life ends here, and the next is chosen where you stand** (ADR-410), on
## the returning player's own machine: `GameState` is never networked, so the
## host can say *granted* and only this peer can die.
func _begin_the_next_life() -> void:
	var body: Player = _session.local_player()
	RunLedger.record(RunLedger.DIED, {
		"descent": GameState.descents,
		"class": String(GameState.class_id),
		"rank": GameState.pact_rank,
		"floor": RunFile.floor_index(),
		"party": maxi(_session.players().size(), 1),
		"extracted_value": 0,
		"returned": true,
	})
	GameState.die()
	# The run goes on, and the next life carries nothing of this one down.
	RunFile.note({"carried": [], "health": RunFile.UNHURT, "wounds": 0, "dazed": 0.0})
	print("[return] this life is over — she is asked who comes next")
	_put_the_screen_away()
	var screen := LegacyScreen.new()
	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.add_child(screen)
	add_child(layer)
	# ADR-141: the screen has the player, or there is no cursor to choose with.
	if body != null:
		body.hold_attention(RETURN_CLAIM)
	screen.finished.connect(_walk_in_as_chosen.bind(layer), CONNECT_ONE_SHOT)


## **Chosen: say who this peer is now, and ask to be built at the way in.**
## The screen stays up until the new body stands, so the frame with no body in
## it is a frame nobody sees (ADR-148's reason).
func _walk_in_as_chosen(layer: CanvasLayer) -> void:
	GameState.forget_the_last_life()
	RunFile.note({"class_id": String(GameState.class_id), "rank": GameState.pact_rank})
	_session.redeclare()
	if multiplayer.is_server():
		_walk_back_in(multiplayer.get_unique_id())
	else:
		_walked_back_in.rpc_id(CoopSession.HOST_PEER)
	var began: int = Time.get_ticks_msec()
	while is_inside_tree():
		var arrived: Player = _session.local_player()
		if arrived != null and not arrived.spent:
			break
		if Time.get_ticks_msec() - began > RETURN_ARRIVAL_MSEC:
			push_warning("RoomSet: no new body arrived after a Return")
			break
		await get_tree().process_frame
	if is_instance_valid(layer):
		layer.queue_free()
	# The kit is the new life's (`DES-011`): worn on the body, and the rest
	# carried down from the stash the oath filled, as at any descent.
	_carry_the_stash_down()
	print("[return] walked back in as '%s'" % GameState.class_id)


@rpc("any_peer", "reliable")
func _walked_back_in() -> void:
	if not multiplayer.is_server():
		return
	_walk_back_in(multiplayer.get_remote_sender_id())


## **Built again where the floor lets you in** (ADR-410, `DES-012` rule 2), by
## `CoopSession`, as the camp rebuilds a body after the fire: the old body goes,
## and the new one is spawned from the declaration that peer has just made.
func _walk_back_in(peer: int) -> void:
	if not multiplayer.is_server() or not _returning.has(peer):
		return
	var old: Player = _session.player_for(peer)
	if old != null:
		_session.despawn_player(peer)
		var waited: int = 0
		while is_instance_valid(old) and waited < RETURN_REBUILD_FRAMES:
			await get_tree().process_frame
			waited += 1
	var way_in: Vector3 = _floor.spawns()[0]
	var built: Player = _session.spawn_player(peer, way_in)
	_returning.erase(peer)
	print("[return] peer %d stands at the way in as '%s'" % [peer,
		_session.sworn_of(peer) if built != null else "nobody"])
	# Nobody standing and nobody coming back is still a wipe.
	if built == null:
		_watch_for_a_wipe()


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
	# **Somebody is walking back in** (ADR-410). Their old body is spent and
	# their new one is not built yet, and they are still in the run.
	if not _returning.is_empty():
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
func _on_peer_left(peer: int) -> void:
	if not multiplayer.is_server():
		return
	# Somebody who left while choosing the next life is not walking back in
	# (ADR-410), and the wipe stops waiting for them.
	_returning.erase(peer)
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
	var my_scars: int = 0
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
		# A life that ends takes no Scar; it has nowhere to carry one.
		# **Read off the exit, never off the body now** (ADR-240): every body
		# not gone went out through `_on_extracted`, which wrote it down.
		var scarring: int = 0 if gone else int(_wounds_out.get(peer, 0))
		if peer == CoopSession.HOST_PEER:
			# Held, not taken. Taking it here is what detached the node.
			my_haul = packed
			my_loss = gone
			my_deeds = _deeds_for(body)
			my_scars = scarring
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
		_take_the_outcome.rpc_id(peer, packed, gone, _deeds_for(body), scarring)
	# Last, because this is the one that takes the floor out from under us.
	if mine_found:
		_take_the_outcome(my_haul, my_loss, my_deeds, my_scars)


## **Which Scars a life takes from how it left** (`M4-T14`, ADR-240, the
## developer's two calls). Every wound carried out becomes its Scar. A rescue
## scars the same wounds — and the head when the ember carried none, from the
## fall that put it on the floor, so `DES-012`'s *take a Scar* is always true and
## a rescuer can see what the rescue cost.
static func scars_for(wounds: int, carried_out: bool) -> int:
	if carried_out and wounds == 0:
		return 1 << Enums.Wound.CONCUSSED
	return wounds & 0b111


## **This floor's contracts, set out** (`M4-T04`, ADR-241). A floor reset is a
## new floor, so its ledger is new too.
func _open_the_ledger() -> void:
	if _ledger != null:
		_ledger.queue_free()
	_ledger = ContractLedger.new()
	_world.add_child(_ledger)
	_ledger.begin(_floor, _floor_index)
	_ledger.met.connect(_on_contract_met)


## **Said when it happens** (`DES-019` Layer 5's *contract updates*), and
## never over a probe's screenshot.
func _on_contract_met(held: Contract) -> void:
	if _probing or _hud == null:
		return
	var notice := ArrivalBrief.new()
	notice.notice = true
	notice.notes = PackedStringArray(["the Lodge's work is done: %s" % held.title()])
	_hud.add_child(notice)


## What this peer walked away with, delivered to the peer it belongs to.
##
## `GameState` is never networked (`TEC-004`), so the host cannot write another
## player's progression — it can only tell them what happened and let them
## write their own.
@rpc("any_peer", "reliable")
func _take_the_outcome(packed: Array, lost: bool, earned: Array = [],
		scarring: int = 0) -> void:
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
	#
	# **What the run answered for the Lodge is read first** (ADR-241): the file
	# is the only record of the work met on floors this peer has left.
	var met_on_the_way: PackedStringArray = RunFile.met()
	var wanted: Dictionary = RunFile.expected()
	# **`DES-010`'s notebook, read before the run file goes** (ADR-261). Every
	# field here is either about to be cleared or about to be changed by the
	# settlement below, so the row is gathered now and written once the outcome
	# has actually been applied.
	var left_value: int = RunFile.left_behind()
	var left_count: int = RunFile.left_count()
	var reached: int = RunFile.floor_index()
	var haul: int = 0
	for row: Variant in packed:
		# `from_wire`, matching how the same array is read below. `packed` is
		# `Inventory.pack()`'s output and `from_record` reads the other shape.
		var came_home: ItemInstance = ItemInstance.from_wire(row as Dictionary)
		if came_home != null and came_home.definition != null:
			haul += came_home.definition.tribute_value
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
		# **The Scars this life takes home** (ADR-240), written by the peer whose
		# life it is — the host decided them and cannot write them (`TEC-004`).
		if scarring != 0:
			GameState.take_scars(scarring)
			print("[death] scarred %d — the life now carries %d"
				% [scarring, GameState.scars])
		# **And the Lodge hears how it went** (ADR-241): the work met on the
		# way, and each Retrieve whose item came out in this bag. What was not
		# answered failed. A life that ended took its contracts with it above.
		if not GameState.contracts.is_empty():
			var heard: Dictionary = GameState.settle_contracts(
				ContractLedger.answered(met_on_the_way, wanted, packed))
			print("[lodge] the run answered %d contract(s) and failed %d — trust %d, favour %d"
				% [heard["met"], heard["failed"], GameState.lodge_trust, GameState.lodge_favour])
		var brought: Array[ItemInstance] = []
		for row: Variant in packed:
			brought.append(ItemInstance.from_wire(row as Dictionary))
		GameState.bring_home(brought)

	# **The notebook, written once the outcome has been applied** (`DES-010`,
	# ADR-261). Four of the six metrics `DES-010` asks for are in this one row,
	# and so is the per-capita question `DES-012` has been carrying since M3 —
	# a four-player run bringing home four times as much is not co-op paying
	# off, it is four bags.
	#
	# `lost` is the whole outcome vocabulary this path can produce. A run
	# abandoned from the pause menu resolves somewhere else and records itself
	# there, which is why the ledger has three kinds and this writes two.
	RunLedger.record(RunLedger.DIED if lost else RunLedger.EXTRACTED, {
		"descent": GameState.descents,
		"class": String(GameState.class_id),
		"rank": GameState.pact_rank,
		"floor": reached,
		"party": maxi(_session.players().size(), 1),
		"extracted_value": 0 if lost else haul,
		"abandoned_value": left_value,
		"abandoned_count": left_count,
	})

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
	# The wounds go down with the health (`M4-T14`, ADR-239), read off the same
	# replicated body: `wounds` and `dazed` both travel.
	var wounds: int = 0
	var dazed: float = 0.0
	if body != null:
		# Without the floor's key (ADR-381): it opens this floor's doors, and
		# carried down it would open the next floor's without anyone finding
		# that one's — the lock decided by a key from somewhere else.
		bag = LockedDoor.leaving_floor(body.inventory.pack())
		hurt = body.health.current
		wounds = body.wounds
		dazed = body.dazed
	# **The Hunt comes with you** (ADR-037, `DES-017` Q9): *"descending grants
	# nothing — going quiet and shedding carried value can shake it, but a
	# staircase cannot."* Read off the Gullsjúkr rather than a clock, because
	# `Shaft._escalation` reads the same `age` and the price of leaving and the
	# pressure you feel have to come from one source.
	var age: float = _hunter.age if _hunter != null else 0.0
	# And what it learned (ADR-403): the same Hunter, the same lessons.
	var lessons: Dictionary = _hunter.lessons() if _hunter != null else {}
	RunFile.carry_down(bag, hurt, age, wounds, dazed, lessons)
	var to: int = RunFile.descend()
	print("[descent] floor %d → %d, carrying %d item(s) at %.0f hp, wounds %d, "
		% [_floor_index, to, bag.size(), hurt, wounds]
		+ "the Hunt %.0f s old" % age)
	if _probing and _crossing.is_empty():
		# The descent *happened*, which is what a probe reads. Changing scene
		# would free the node holding the assertion (ADR-138).
		#
		# **Except for `--crossing-probe`** (ADR-264), which is built to be
		# freed: its expectation lives in a `static var` that outlives this
		# node, so the arrival on the next floor is what collects. Until it
		# existed, this early return meant the last step of a descent — the
		# one that frees a floor, a population and a HUD and builds another —
		# had never been executed by any check in the suite.
		return
	# **Into the dark first** (B174), as from the camp: the next floor takes a
	# second to make, and the frame that holds is black. Not under a probe —
	# `--crossing-probe` measures the crossing, and the curtain is only look.
	if not _probing:
		if body != null:
			body.hold_attention(&"descent")
		await Curtain.fall(self)
	get_tree().change_scene_to_file(RoomSet.scene())


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
	# **Every wound carried out becomes its Scar** (ADR-240, the developer's
	# call), so tying the binding or waiting out the ringing is a decision made
	# before the exit and not after it.
	_wounds_out[player.get_multiplayer_authority()] = scars_for(player.wounds, false)

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
		# Told to the body too (ADR-410): a saved life has no Return to offer.
		if saved != null:
			saved.borne_out = true
		_wounds_out[peer] = scars_for(saved.wounds if saved != null else 0, true)
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
##
## **Asked of every authored deed, by its `condition`** (ADR-229). This named
## the five deed ids in code, and `DeedResource.condition` and its `threshold`
## (but for one) were validated at boot and read by nothing — so a sixth deed
## authored on an existing condition, which is exactly what `DeedResource` says
## a designer may do without touching code, would never have been awarded.
func _deeds_for(body: Player) -> Array:
	var earned: Array = []
	if body.spent:
		# Nothing is earned by a body that did not leave. `DES-016`'s categories
		# are all about a run you came back from, and the run you did not is
		# what the Legacy screen is for.
		return earned
	for mark: DeedResource in DeedCatalogue.all():
		var id: String = String(mark.id)
		match mark.condition:
			&"got_out":
				earned.append({"id": id, "who": ""})
			&"bore_them_home":
				for peer: int in body.inventory.embers():
					var saved: Player = _session.player_for(peer)
					earned.append({"id": id,
						"who": saved.name if saved != null else "peer %d" % peer})
			&"empty_handed":
				if body.inventory.count() == 0:
					earned.append({"id": id, "who": ""})
			&"left_the_prize":
				if _the_prize_is_still_here():
					earned.append({"id": id, "who": ""})
			&"by_a_thread":
				if body.health.maximum > 0.0 \
						and body.health.current / body.health.maximum <= mark.threshold:
					earned.append({"id": id, "who": ""})
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
	_returning.clear()
	_wounds_out.clear()
	_open_the_ledger()
	if _barrow != null:
		_barrow.reseal()
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
		# A new descent is a new body, for a probe that needs a second run in
		# one scene. Not `DES-012`'s *Return*, which builds a new life where the
		# floor lets you in (ADR-410, `_walk_back_in`).
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

	# **The floor has an outside, and this is what closes it** (`M4-T26`,
	# ADR-203).
	#
	# Until now this `Environment` set a background colour and nothing else, so
	# past the last wall there was flat `PAPER` and the outside faces of every
	# room stood in it. That is not only cosmetic: `--plan-probe` bounds how much
	# corridor a player may see at once, because *"a tunnel you can see the whole
	# of from the doorway is the proposition given away"* — and an open boundary
	# hands the whole layout back over the top of the wall. A raised crossing
	# deck is **deliberately** open above (`FloorBuilder._tunnel`, `DES-015`'s
	# visual-only vertical space), so standing on one shows you the floor's
	# rooftops laid out to the horizon. Roofing them would delete the vertical
	# drama that openness exists for; dissolving the distance keeps it.
	#
	# **Depth fog, at exactly the ground colour, and that is the trick.** Unlit
	# stone at 0.12 ambient sits *darker* than `PAPER`, so the void does not read
	# as brightness — it reads as silhouettes cut out of a slightly paler page.
	# Fogging toward the background colour removes the contrast in both
	# directions at once: what is far enough away simply becomes the page again,
	# which is `ART-005`'s *"walking into an unlit room is walking onto paper
	# nobody has drawn on yet"* extended to the parts of the floor nobody was
	# ever meant to be looking at.
	#
	# **It is the lantern's visual twin, and it does not touch a threat.** The
	# ink pass reads the depth and normal buffers and composites over the
	# finished colour, so fog cannot dim an outline: `ART-005`'s promise that
	# enemies and loot outline at full weight regardless of distance is paid by
	# the pass, not by the fill, and `--fog-shot` photographs the pair rather
	# than assuming it. The envelope is bracketed by two numbers that already
	# existed — the 10 m corridor sightline the dog-leg guarantees, and
	# `InkPass.FALLOFF_END`, where the linework has already gone.
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = PAPER
	environment.fog_light_energy = 1.0
	environment.fog_density = 1.0
	environment.fog_depth_begin = Config.tuning.floor_fog_begin
	environment.fog_depth_end = Config.tuning.floor_fog_end
	environment.fog_depth_curve = FOG_CURVE
	# **`fog_sky_affect` is 1.0, and zero is the trap** (`M4-T26`, measured).
	#
	# It reads like the setting that does not apply here — there is no sky, only
	# a `BG_COLOR` clear — and at 0.0 the background renders **black** instead
	# of `PAPER`: 1,1,1 against 10,10,13. That is worse than no fog at all,
	# because unlit stone sits at 4,4,4 and a black ground puts the boundary
	# back with the silhouette *inverted* — the rooms now read lighter than the
	# nothing behind them. At 1.0 the ground stays the page, which is the only
	# way the fill can converge onto it. Found by reading pixels out of the
	# sweep, not from the property name.
	environment.fog_sky_affect = 1.0
	# No sun, and nothing to scatter off. Both left explicit, so a directional
	# light added later cannot quietly tint the fog off `PAPER`.
	environment.fog_sun_scatter = 0.0
	environment.fog_aerial_perspective = 0.0

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
	# And the lamp that gives it (ADR-291) — the light was always here; now
	# so is the thing it comes from.
	Hearth.door_lamp(_world, at, PALE, _floor.lamp_hang())


func _spawn_actors() -> void:
	_session = SESSION_SCENE.instantiate() as CoopSession
	_session.world_scene = scene_file_path
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
	# **The way out is the way in** (`M4-T15`, ADR-250, `DES-005` Layer 3b).
	# The Shaft is where a late arrival steps through, which is a known place
	# per floor, diegetic, and deliberately inconvenient — the right price for
	# arriving after the work started.
	_session.late_arrival = _floor.shaft()
	_session.came_down_late.connect(_someone_came_down)


## **A gate opening is loud** (`M4-T15`, ADR-250).
##
## `TEC-004` prices it that way on purpose — *"arrival is diegetically costly
## and gives the host a natural beat to complete the sync behind"* — so the
## Deep hears a body arrive at the Shaft the same way it hears a barrow open:
## a deposit in the Clamor field where it happened, which the Gold-Sick walk
## toward. Host-side, because the field is (`TEC-001`).
func _someone_came_down(_peer: int, at: Vector3) -> void:
	Foley.at(_shaft if _shaft != null else self, Foley.Sound.CHANNEL, 0.7, 0.0,
		Foley.REACH * 1.5)
	if _field == null or not multiplayer.is_server():
		return
	_field.deposit(at, Config.tuning.late_join_clamor)
	_probe_arrival_clamor = _field.level_at(at)


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
## `GameState` is never networked (`TEC-004`, ADR-021) — every peer holds only
## its own — so each process sends its own stash. **The host puts it in the
## bag** (ADR-228), because the host owns every body's inventory: this added the
## stash straight into the local body, which on a client was a body that did not
## exist yet at `_ready` — the host builds it and the spawn arrives afterwards —
## so a client's stash never came down at all, and nothing said so. Solo and the
## host reach `Player.carry_down` directly; a client asks, once its body exists.
##
## **What does not fit stays in the stash.** `Inventory.bring()` returns null
## when the grid has no room, and the honest answer to "your stash is bigger
## than your bag" is that you carry what fits and the rest waits — not that the
## bag silently grows, and not that the overflow is destroyed. The host says
## which records fit, and only those leave the stash.
func _carry_the_stash_down() -> void:
	if GameState.stash.is_empty():
		return
	var sent: Array[ItemInstance] = GameState.stash.duplicate()
	var rows: Array = []
	for item: ItemInstance in sent:
		# Records, not definitions (ADR-223): the Scar travels with the item.
		rows.append(item.to_record())
	var body: Player = _session.local_player()
	if multiplayer.is_server():
		if body != null:
			_withdraw_carried(body.carry_down(rows), sent, body)
		return
	_carry_down_when_the_body_arrives(sent, rows)


## A client's half (ADR-228): wait for the body the host built, then ask.
func _carry_down_when_the_body_arrives(sent: Array[ItemInstance], rows: Array) -> void:
	var began: int = Time.get_ticks_msec()
	var body: Player = _session.local_player()
	while body == null:
		await get_tree().physics_frame
		if not is_inside_tree() or Time.get_ticks_msec() - began > PROBE_TIMEOUT_MSEC:
			push_warning("RoomSet: no body arrived to carry the stash down into")
			return
		body = _session.local_player()
	body.carried_down.connect(_withdraw_carried.bind(sent, body), CONNECT_ONE_SHOT)
	body.ask_to_carry_down(rows)


## Take out of the stash exactly what the host fit into the bag.
func _withdraw_carried(taken: PackedInt32Array, sent: Array[ItemInstance],
		body: Player) -> void:
	for index: int in taken:
		if index >= 0 and index < sent.size():
			GameState.withdraw(sent[index])
	print("[descent] carried %d of %d stashed item(s) down, %.1f kg" % [
		taken.size(), sent.size(), body.inventory.total_weight()
		if is_instance_valid(body) else 0.0])


# ── the guarantee, asserted rather than eyeballed ─────────────────────────


## **`--late-probe=PATH`** (`M4-T15`, ADR-250, `TEC-004`).
##
## What each peer can see after somebody joins a run that had already started,
## written by **both** processes: a claim about a join is a claim that two
## machines agree about it, and a probe that interrogated one of them would
## pass with the wire unplugged (`--coop-probe`'s own rule, ADR-107).
##
## The host is launched into the Deep with the descent declared under way; the
## joiner is launched at **the fire**, knocks, and has to be called down —
## which is the path a player takes and the one ADR-157 could not survive.
var _late_reports: Dictionary = {}
var _late_release: bool = false
var _late_probing: bool = false


@rpc("any_peer", "reliable")
func _late_report_ready() -> void:
	if multiplayer.is_server() and _late_probing:
		_late_reports[multiplayer.get_remote_sender_id()] = true


@rpc("authority", "reliable")
func _late_reports_finished() -> void:
	_late_release = true


## **Where a measurement starts** (ADR-411): nothing, in the level a player
## plays. `RoomSetProbed` (`tests/`, never exported) overrides it with the
## dispatch of every `--x-probe` and `--x-shot` this level answers, after the
## floor, the actors and the HUD stand, as the probes always ran.
func _measure(_args: PackedStringArray) -> void:
	pass


## **The level's scene, for whoever changes to it** (ADR-411). A process
## launched with harness arguments plays the probed subclass when it exists —
## an export never has `tests/`, and a player never passes `--` arguments —
## so a probe that walks in through the camp or a doorway finds its own code.
static func scene() -> String:
	if not OS.get_cmdline_user_args().is_empty() and ResourceLoader.exists(PROBED_SCENE):
		return PROBED_SCENE
	return SCENE


const SCENE: String = "res://levels/room_set/room_set.tscn"
const PROBED_SCENE: String = "res://tests/room_set_probed.tscn"
