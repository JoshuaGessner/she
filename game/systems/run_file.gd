class_name RunFile
extends Object

## **A run you cannot walk away from** (`M3-T15`, ADR-050, `TEC-003`).
##
## `TEC-003`: *"Mid-run state lives in a separate `user://run.active` file so a
## crash or quit mid-run can be resumed rather than silently converted into a
## death."* ADR-050 settled which of those it is — **suspend with forced
## resume**, and *"dropping out of a co-op run leaves you a Vörðr, so
## disconnecting is never an escape from a bad run."*
##
## That sentence is the whole feature. Everything here exists to make quitting
## cost exactly what staying would have cost.
##
## ## Separate from the profile, deliberately
##
## `SaveFile` holds who you are across runs; this holds where you are inside
## one. Keeping them apart is what makes `TEC-003`'s death operation stay a
## one-liner — *delete the LIFE block, keep LINEAGE* — with no mid-run
## bookkeeping tangled into it. It also means a corrupt run file costs you a
## run and never a lineage.
##
## ## What it does not restore, and why that is a decision
##
## Not the floor's *state*. Which enemies are dead and which rooms are cleared
## are not in here, and `Q43` already says the Hunt repopulates cleared space —
## so a resumed floor is a populated one.
##
## It does restore **which floor**, and that is `M4-T01` (ADR-184). `floor` is
## how deep into this expedition you are, 0 to 2; `seed` is which expedition it
## is. Both, and not just the first: `stripped` says *you have already been
## through here*, and "here" is only a place if the seed that built it comes
## back with the index. A resumed run that re-rolled its seed would strip a
## floor nobody had ever walked — the same farming exploit `stripped` exists to
## close, wearing the opposite face.
##
## **The loot is the exception, and it has to be**, because a resume that hands
## back a full floor turns quit-and-relaunch into farming the same rooms twice.
## `stripped` is set the moment a floor lays its loot, and a resumed floor lays
## none: you have already been through here. One flag rather than a ledger of
## what was taken, because the true sentence is about the floor rather than
## about the items — and a ledger is `M4-T01`'s to keep, when a seed makes
## "this floor" mean something across processes.

## **Static vars, so a check can be pointed somewhere else** (ADR-152, on
## ADR-145's precedent). `--run-probe` arms itself because this file is its
## subject — and then wrote, and deleted, the **player's** open run on every
## sweep. ADR-138 is the record of what that costs; it fixed the probes that
## touched this file by accident and left the one that touches it on purpose.
##
## The rule ADR-145 wrote down is general: a check that writes to `user://`
## must name the file it writes to, and it must not be the one the game uses.
static var PATH: String = "user://run.active"
static var TMP: String = "user://run.active.tmp"

## Bumped to 2 by `M4-T01` (ADR-184), which added `floor` and `seed`.
##
## No migration, and that is this file's standing policy rather than a shortcut:
## `read()` drops a run file it cannot read, because keeping one blocks every
## future descent and dropping one costs a single run. `SaveFile` takes the
## opposite decision for the opposite reason — a lineage is not replaceable.
const VERSION: int = 2

## The deepest floor of an expedition, zero-based — `DES-015` and ADR-015 are
## three floors, the Aftermath, the Retreat and the Cause.
##
## Here rather than in the generator because this file is what *clamps* the
## index, and `room_set` had the same `0, 2` written inline: two places saying
## how long an expedition is, one of which would have been found by a player.
## The generator takes a depth and does not care how many there are.
const LAST_FLOOR: int = 2

## No wound is being carried — the body arrives at its own maximum.
##
## Negative rather than zero, because zero is a *dead* body and a run file that
## said so would resurrect nobody on resume. Same shape as `CoopSession.NO_PLACE`:
## a named value outside the legal range, never a magic number at a call site.
const UNHURT: float = -1.0

## **Only a process that came in through the menu may touch a run file**
## (ADR-138). `SaveFile` has had this rule since `M3-T06` — *nothing is written
## back to a file that was never read* — and this file did not, which is how a
## sweep broke a play session.
##
## Probes boot levels directly. Every one that exercised the run file wrote to
## the **player's** `user://`, and one that exited between `begin()` and
## `clear()` left a run open. The next launch found it, took ADR-050 at its word
## — *there is no fresh descent while a run is open* — skipped class select, and
## put a body on the floor with no class, no kit and nothing in its hand.
##
## An unarmed process sees no run file at all, which is stronger than refusing
## to write one: it cannot resume somebody else's run, cannot clear it, and
## cannot be confused by it. `--run-probe` arms itself, because its subject is
## this file.
static var _live: bool = false

## **Harness scenarios that need the real scene change, so they cannot carry
## the word `probe`** (`M3-T34`, ADR-155; extended by `M3-T35`).
##
## A list is a thing that rots, and this one is written down rather than
## matched precisely because that is the point: these are the flags that opt
## *out* of the naming convention the guard above relies on. If it ever grows a
## fourth entry, the right answer is one `--scenario=NAME` argument rather than
## a longer list — noted here so the decision is made deliberately instead of
## by accretion.
const HARNESS_FLAGS: PackedStringArray = ["--extraction", "--abandoned",
	"--again"]


## This process owns its run state. Called by `MainMenu._enter()`, which is the
## only way into the game, and by the probe whose subject this is.
static func arm() -> void:
	# **A check may not arm the player's run file** (ADR-152).
	#
	# Three separate probes have now done it: `--run-probe`, whose subject this
	# is; `--edges-probe`, which reasoned correctly that it had to arm and then
	# read that as having to use the real file; and `--class-probe`, which
	# reached past this class entirely with `DirAccess` and `FileAccess` on
	# `PATH`. Every one of them destroyed a suspended run on every sweep, and
	# **none of it appeared in any output** — which is what makes a lint rule
	# the wrong answer and a refusal the right one.
	#
	# Loud rather than silent: refusing leaves `exists()` false, so the probe
	# that did it fails its own assertions by name instead of quietly working
	# on somebody's save.
	if PATH == "user://run.active" and _a_check_is_running():
		push_error("RunFile: a check tried to arm the player's run file. Call "
			+ "`use_a_scratch_run()` first — a check that writes to `user://` "
			+ "names its own file (ADR-145, ADR-152).")
		return
	_live = true


## Was this process launched as a check?
##
## Nearly the same test `Threshold` and `room_set` use to decide whether to
## hold a scene, and for the same reason: a harness argument is the one honest
## signal that nobody is playing.
##
## **The flags below are named because they are deliberately not named
## `--probe`** (`M3-T34`, ADR-155). `room_set` avoided the word so that
## `_probing` would stay false and the run could really change scene — the
## comment in `threshold.gd` says so in as many words — and that spelling walked
## straight through ADR-152's refusal, because the refusal matches on the word
## rather than on the fact. So the one harness flag that most needs a run file
## was the one flag allowed to arm the player's.
##
## Nothing had exercised the hole, which is the only reason this is a fix and
## not an incident: the extraction scenario had no run file at all until the
## check that needed one was written. A guard whose coverage depends on a
## naming convention is a guard that expires the first time somebody names a
## flag well.
static func _a_check_is_running() -> bool:
	for arg: String in OS.get_cmdline_user_args():
		if arg.contains("probe") or arg.contains("shot"):
			return true
		if HARNESS_FLAGS.has(arg):
			return true
	return false


## Point this process at a run file that is nobody's (ADR-152). Called by the
## checks whose subject is opening and closing a run, which cannot be refused
## the file the way every other probe is.
static func use_a_scratch_run() -> void:
	PATH = "user://run.probe"
	TMP = "user://run.probe.tmp"


## Is a run open? A crash leaves this behind, which is the point: the next boot
## finds it and resumes rather than offering a fresh descent.
##
## False in an unarmed process **even when the file is there**, so a probe
## booting a level directly is never looking at a player's run.
static func exists() -> bool:
	return _live and FileAccess.file_exists(PATH)


## Open a run. Called at the descent, before a floor is built.
##
## **The seed is passed in rather than rolled here** (`M4-T01`, ADR-184), and
## that is the whole co-op story. Every peer builds its own geometry — the floor
## is derived, not spawned, exactly like the Shaft — so a seed each process
## rolled for itself would put a party of four in four different Delvings, each
## solid on one machine and thin air on the other three. `Threshold._descend` is
## `@rpc("authority", "call_local")`: the host rolls once and every peer runs the
## same call with the same number, so the agreement costs no new wire.
static func begin(class_id: StringName, rank: int, seed: int) -> void:
	_write({
		"version": VERSION,
		"class_id": String(class_id),
		"rank": rank,
		# How deep into *this expedition*, 0 to 2 — never `GameState.descents`,
		# which counts what a lineage has done and would roll floor 47 on
		# somebody's forty-eighth run.
		"floor": 0,
		"seed": seed,
		"carried": [],
		"hunt_age": 0.0,
		# **`UNHURT` rather than a number** (`M4-T01`, ADR-185). A run opens on a
		# body that does not exist yet, and every class has a different pool —
		# writing a figure here would be this file deciding how much health a
		# Húskarl has. It says *nothing is carried down* and the body uses its
		# own maximum.
		"health": UNHURT,
		"stripped": false,
	})


## Down one floor. Returns the new index, and writes it before the scene changes
## so a crash between floors resumes onto the floor you were descending *to* —
## which is the floor whose Shaft you already paid for.
##
## Clamped rather than wrapped: `DES-015` is three floors and there is nothing
## under the third. A caller that reaches the bottom gets 2 back and has to
## decide what that means, because *"you are at the bottom"* is a fact about the
## expedition and not about this file.
static func descend() -> int:
	var run: Dictionary = read()
	if run.is_empty():
		return 0
	var next: int = clampi(int(run.get("floor", 0)) + 1, 0, LAST_FLOOR)
	note({"floor": next, "stripped": false})
	return next


## How deep this run is, 0 to 2. Zero in an unarmed process, which is every
## probe: a check booting a level directly is not on an expedition, and the flag
## that tells it which floor to build is read by the level rather than invented
## here.
static func floor_index() -> int:
	return clampi(int(read().get("floor", 0)), 0, LAST_FLOOR)


## Which expedition this is. Zero when no run is open — and zero is a legitimate
## seed, so callers ask `exists()` when they need to tell "seed 0" from "no run".
static func seed_of() -> int:
	return int(read().get("seed", 0))


## **What this peer takes down with it** (`M4-T01`, ADR-185).
##
## Written on the floor above, immediately before the scene changes, and read by
## `CoopSession` on the floor below — which then tells the **host**, because the
## host owns every body's inventory and health and a peer restoring its own would
## be writing state it does not own (`_push_bag` would overwrite it a frame
## later anyway).
##
## Per process, like `GameState` and for the same reason: your bag is yours, and
## four peers each hold one quarter of the party's answer.
static func carry_down(rows: Array, hurt: float, age: float) -> void:
	note({"carried": rows, "health": hurt, "hunt_age": age})


## The bag this run is carrying, in `Inventory.pack()` rows. Empty on a fresh
## run and in an unarmed process.
static func bag() -> Array:
	return read().get("carried", []) as Array


## The wound this run is carrying, or `UNHURT`. **`DES-009` bans regeneration
## *within* a run**, and ADR-015 makes a run three floors — so a floor
## transition that healed you would be the one thing the combat design says
## cannot happen, and quitting to the menu would become a bandage.
static func wound() -> float:
	return float(read().get("health", UNHURT))


## How old the Hunt already is. ADR-037: *"the Hunt persists across floors.
## Descending grants nothing — a staircase cannot shake it."*
static func hunt_age() -> float:
	return maxf(0.0, float(read().get("hunt_age", 0.0)))


## Update the open run. Merged rather than replaced, so a caller that knows one
## fact does not have to know all of them.
static func note(fields: Dictionary) -> void:
	if not exists():
		return
	var run: Dictionary = read()
	if run.is_empty():
		return
	for key: String in fields:
		run[key] = fields[key]
	_write(run)


static func read() -> Dictionary:
	if not exists():
		return {}
	var handle: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if handle == null:
		return {}
	var parsed: Variant = JSON.parse_string(handle.get_as_text())
	handle.close()
	# `typeof`, not `as Dictionary`. Casting a non-Dictionary Variant with `as`
	# **throws** rather than yielding null — *"Invalid cast: could not convert
	# value to 'Dictionary'"* — which aborts this function before it can drop
	# the bad file, so the very case this branch exists for left the file on
	# disk and blocked every future descent.
	if typeof(parsed) != TYPE_DICTIONARY:
		# Unreadable. Deleted rather than kept, and this is the one place that
		# is right: a run file nobody can parse would otherwise block every
		# future descent forever, and what it costs to drop is one run. The
		# profile takes the opposite decision (`M3-T06`) for the opposite
		# reason — a lineage is not replaceable.
		push_error("RunFile: %s is not a run; dropping it" % PATH)
		clear()
		return {}
	var run: Dictionary = parsed
	if int(run.get("version", 0)) != VERSION:
		push_error("RunFile: %s is version %d, this build reads %d; dropping it"
			% [PATH, int(run.get("version", 0)), VERSION])
		clear()
		return {}
	return run


## The run resolved. Called when an outcome is taken — extraction or death —
## and **only** then, because anything else is the escape ADR-050 forbids.
static func clear() -> void:
	if not _live:
		return
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## Written whole, through a scratch file and a rename, on `SaveFile`'s pattern:
## either the run moved or it did not, and there is no third state on disk.
static func _write(run: Dictionary) -> void:
	if not _live:
		# Not an error. A probe booting a level directly has no business
		# opening a run, and saying so on every one of them would bury the
		# output that matters in noise.
		return
	var handle: FileAccess = FileAccess.open(TMP, FileAccess.WRITE)
	if handle == null:
		push_error("RunFile: cannot open %s for writing" % TMP)
		return
	handle.store_string(JSON.stringify(run, "\t"))
	handle.close()
	var here: DirAccess = DirAccess.open("user://")
	if here == null:
		push_error("RunFile: cannot open user:// to place the run file")
		return
	here.rename(TMP.get_file(), PATH.get_file())
