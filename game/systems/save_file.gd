class_name SaveFile
extends Object

## The profile on disk (`M3-T06`, `TEC-003`, ADR-116).
##
## `GameState` decides *what* survives. This decides how it reaches a file and
## how it comes back from one written by an older build. `TEC-003` calls
## retrofitting migration *"genuinely one of the worst jobs in game
## development"*, which is why ADR-109 moved this task to the front of `M3`
## ahead of every system whose state it will end up carrying.
##
## ## The schema is only as wide as the state that exists (ADR-116)
##
## `TEC-003` draws a save with `pact_rank`, `tithe_state`, `boon`, `skill_tree`,
## `scars`, `bestiary`, `cartography` and `legacy_slots_unlocked` in it. **None
## of those exist yet.** Writing them now as empty fields is exactly the stub
## ADR-064 bans: present, empty, and lying about what the game does.
##
## So v1 carried what `GameState` actually held, and **every task after this
## one that adds persistent state ships `SAVE_VERSION + 1`, its migration, and
## a fixture of the format it replaces.** `M3-T04` was the first, and the policy held: one field group, one migration, one bump. By `GATE M3 EXIT` the path below will
## have run for real seven times against saves that genuinely existed — which
## is a far stronger claim than one speculative v1 nobody ever migrates from.
##
## ```
## user://profile.save
## ├── meta     { save_version, engine, created, updated }
## ├── lineage  { hoard, hoard_value }          ← survives death, always
## └── life     { stash, pact_rank, tithe_paid, cycle_runs, hunt_head_start }
## ```
##
## `legacy` is **absent rather than empty**: there are no Legacy slots until
## `M3-T05`, and a section for a system that does not exist is a stub wearing
## structure's clothes. It arrives with the thing that needs it, as a migration.
##
## The two sections that *are* here earn their place: `GameState.die()` is
## already implemented as `TEC-003`'s one-function operation — clear LIFE, keep
## LINEAGE — so the split is not decoration, it is the shape death already has.
##
## ## Why this is not an autoload
##
## `TEC-001` names `SaveSystem` in its budget of six. It stays a `class_name`
## with static state anyway, for the reason `Settings` gives three files over:
## an autoload is for something with a node's life, and this has none. It reads
## and writes when told. `GameState` is the autoload, it owns the state, and it
## is the only caller — a second autoload whose whole body is *"hand this dict
## to a file"* is a habit rather than a budget (ADR-066).

## Bumped by **any** change to the shape written below, with a migration added
## in the same commit. Never edit a shipped migration; never delete one.
const SAVE_VERSION: int = 2

const PATH: String = "user://profile.save"
## Written first, then renamed over `PATH`. A rename is atomic on every
## filesystem we ship to, so a process killed mid-write leaves a stale `.tmp`
## and an intact profile — never a half-written one. `TEC-003` calls the death
## write the critical path, and this is the whole of what makes it survivable.
const TMP: String = "user://profile.save.tmp"

## Ordered forward migrations: `N` names the function taking a version-`N` dict
## and returning a version-`N+1` one.
##
## **Never edit one of these and never delete one.** A player loads from
## whatever version they last quit on, so a migration is a permanent public
## contract with a file that already exists on somebody's disk.
##
## A function rather than a `const` because a constant cannot hold a `Callable`
## to a method of the class still being defined.
static func migrations() -> Dictionary:
	return {
		1: _migrate_1_to_2,
	}


## **v1 → v2: `M3-T04` put the pact on the profile** (ADR-118).
##
## v1 had no rank, no cycle and no Tithe, because none of them existed. So a v1
## profile *is* a life at rank 1 that has never owed anything — which is exactly
## what a new life is. These defaults are not a guess at missing data; they are
## the state that save was genuinely in.
static func _migrate_1_to_2(old: Dictionary) -> Dictionary:
	var out: Dictionary = old.duplicate(true)
	var life: Dictionary = out.get("life", {}) as Dictionary
	life["pact_rank"] = 1
	life["tithe_paid"] = 0
	life["cycle_runs"] = 0
	life["hunt_head_start"] = 0.0
	out["life"] = life
	return out


## Everything `GameState` handed us, plus the stamps that make it loadable.
static func write(payload: Dictionary) -> bool:
	var body: Dictionary = payload.duplicate(true)
	var before: Dictionary = _meta_of(read_raw())
	body["meta"] = {
		"save_version": SAVE_VERSION,
		"engine": String(Engine.get_version_info()["string"]),
		# Preserved across writes so a profile can say how old it is. A missing
		# one means this is the first write, not that the field is optional.
		"created": before.get("created", Time.get_datetime_string_from_system(true)),
		"updated": Time.get_datetime_string_from_system(true),
	}

	var scratch := FileAccess.open(TMP, FileAccess.WRITE)
	if scratch == null:
		push_error("SaveFile: cannot open %s (%d)" % [TMP, FileAccess.get_open_error()])
		return false
	# Uncompressed and indented, deliberately (`TEC-003`): a save you can read
	# in a text editor makes balance and bug work dramatically faster, and the
	# file is a few hundred bytes. Compression is a near-release question.
	scratch.store_string(JSON.stringify(body, "\t"))
	scratch.close()

	var moved: int = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TMP),
		ProjectSettings.globalize_path(PATH))
	if moved != OK:
		push_error("SaveFile: cannot replace %s (%d)" % [PATH, moved])
		return false
	return true


## The profile, migrated forward to `SAVE_VERSION`, or `{}` when there is none
## and when there is one we must not touch.
##
## **A save from a newer build is refused, not repaired.** It cannot be migrated
## — the migrations that would do it have not been written — and loading it
## partially then writing it back would silently destroy whatever the newer
## build knew. `M4-T06` is where that becomes something a player is told.
static func read() -> Dictionary:
	var raw: Dictionary = read_raw()
	if raw.is_empty():
		return {}

	var meta: Dictionary = _meta_of(raw)
	var version: int = int(meta.get("save_version", 0))
	if version < 1:
		push_error("SaveFile: %s has no usable save_version; refusing to load" % PATH)
		return {}
	if version > SAVE_VERSION:
		push_error(("SaveFile: %s is version %d and this build reads %d — "
			+ "refusing to load rather than writing over a newer profile")
			% [PATH, version, SAVE_VERSION])
		return {}
	if version == SAVE_VERSION:
		return raw

	# Cheap insurance, and `TEC-003` asks for it by name: the pre-migration file
	# is kept under the version it was written at, so a migration that turns out
	# to be wrong costs a rename rather than a lineage.
	var backup: String = "%s.bak.%d" % [PATH, version]
	DirAccess.copy_absolute(
		ProjectSettings.globalize_path(PATH),
		ProjectSettings.globalize_path(backup))
	return walk(raw, migrations(), version, SAVE_VERSION)


## Run migrations forward, one version at a time, in order.
##
## Takes its table as an argument rather than reading `migrations()` directly so
## that `--save-probe` can drive it with a synthetic one. That mattered most at
## v1, when the real table was empty and a probe using it would have proved only
## that a loop with no work does nothing — ADR-097's shape. It still earns its
## keep: the real table only ever tests the versions that happen to exist, and
## the synthetic one tests ordering, refusal and re-stamping at any length.
##
## **The whole route is checked before a single step runs.** A gap means the
## file is a shape no build ever wrote, and guessing at it corrupts a profile
## quietly — but refusing *part-way* is barely better, because it leaves the
## caller holding a dict half-way between two formats that it must then decide
## what to do with. Checking first means a gap costs nothing at all.
##
## It also makes the refusal visible, which the obvious version was not: with a
## per-step check, deleting it changed nothing observable, because GDScript's
## own missing-key access aborts the function and hands back an empty dictionary
## anyway. Planting that violation is what showed the guard was decorative —
## the outcome was identical either way, so the check proved nothing about
## itself. Checked up front, a gap runs **zero** migrations instead of some.
static func walk(data: Dictionary, table: Dictionary, from: int, to: int) -> Dictionary:
	for step_from: int in range(from, to):
		if not table.has(step_from):
			push_error(("SaveFile: no migration from version %d — refusing to "
				+ "guess at a shape no build ever wrote") % step_from)
			return {}

	var moving: Dictionary = data
	var at: int = from
	while at < to:
		var step: Callable = table[at] as Callable
		moving = step.call(moving) as Dictionary
		if moving == null or moving.is_empty():
			push_error("SaveFile: migration %d -> %d returned nothing" % [at, at + 1])
			return {}
		at += 1
		moving["meta"] = _meta_of(moving)
		moving["meta"]["save_version"] = at
	return moving


## Is there a profile at all?
##
## **A filesystem question, deliberately, and not a parsing one.** `read_raw`
## returns `{}` both for "no file" and for "a file that is not a save", and
## `GameState.load_profile` originally asked *it* — so a corrupt profile read as
## no profile, went live, and was **overwritten by the next tribute.** The
## protection built for a save from a newer build did not cover the case it was
## most needed in, and only planting a violation showed it: the probe asserted
## that garbage does not load, which was true, and never that garbage survives.
static func exists() -> bool:
	return FileAccess.file_exists(PATH)


## The file exactly as written, with no version handling at all. Public because
## `write()` needs the previous `created` stamp and `--save-probe` needs to look
## at what actually landed on disk.
static func read_raw() -> Dictionary:
	if not exists():
		return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("SaveFile: cannot read %s (%d)" % [PATH, FileAccess.get_open_error()])
		return {}
	var text: String = file.get_as_text()
	file.close()

	# `TEC-003`: validate on load so a malformed save fails cleanly instead of
	# half-loading into a corrupted state. Anything that is not a dictionary is
	# not a profile, however well-formed its JSON.
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveFile: %s is not a save file; refusing to load" % PATH)
		return {}
	return parsed as Dictionary


## Gone, along with its backups. Only `--save-probe` calls this today; deleting
## a profile is `M4-T06`'s to put in front of a player.
static func wipe() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	for name: String in dir.get_files():
		if name.begins_with("profile.save"):
			dir.remove(name)


static func _meta_of(data: Dictionary) -> Dictionary:
	var meta: Variant = data.get("meta", {})
	return meta as Dictionary if typeof(meta) == TYPE_DICTIONARY else {}
