class_name RunLedger
extends Object

## **What actually happened, run by run** (`DES-010`, ADR-261).
##
## `DES-010` names six metrics and says to instrument them at M2, under the
## heading *"retention questions are unanswerable from vibes."* None of them
## were ever instrumented. The document has been asking a question the build
## could not answer for two milestones, and the questions it asks are the ones
## that decide whether the loop works:
##
## - deaths per session, and the run number of the first death
## - session-end reason — **extracted / died / abandoned**
## - loot voluntarily abandoned per run, *"the single best proxy for whether
##   the core tension is working"*
## - Tithe default rate by Pact Rank
## - Legacy slot usage: item against node, which validates ADR-003
## - the share of runs ending in extraction — target ⟨tune⟩ 55–70 %
##
## Plus the one `DES-012` has been waiting on: **per-capita extracted value at
## one, two and four players.**
##
## ## This is a notebook, not telemetry
##
## **Nothing here leaves the machine it was written on.** There is no network
## call, no identifier, no upload, and no code path that could add one without
## it being obvious in this file. It is a local record a developer reads with
## `--ledger-probe` after playing, and a player who never looks at it is never
## affected by it.
##
## That is a design decision rather than an oversight. `PRO-005` makes the
## ethics of this game load-bearing rather than decorative, and a retention
## instrument that phones home is exactly the kind of thing that turns into a
## reason to make the game worse.
##
## ## One row per peer per resolved run
##
## Written from `_take_the_outcome`, which is the single point where a run
## resolves *on the machine it resolved for* — the host reports and each peer
## writes its own, the same rule `TEC-004` applies to everything else. A row
## is appended when the run ends and never edited afterwards.

const VERSION: int = 1
const PATH: String = "user://ledger.json"
const TMP: String = "user://ledger.json.new"
## **A notebook with a bound number of pages.** An append-only file grows for
## as long as somebody plays, and the questions above are all rates and recent
## trends rather than lifetime totals — so the oldest rows are the ones worth
## losing. 2,000 runs is more play than any of these questions needs.
const KEEP: int = 2000

## **Outcomes, as `DES-010` asks the question.** *Quit mid-run* is the churn
## signal the document calls the one that matters most, and it is a different
## event from dying: the run was abandoned by a person rather than resolved by
## the floor.
const EXTRACTED: StringName = &"extracted"
const DIED: StringName = &"died"
const ABANDONED: StringName = &"abandoned"

## A Legacy choice, which is not a run and shares the file.
const LEGACY: StringName = &"legacy"
## **A Tithe cycle closing**, which is also not a run. `DES-010` asks for the
## default rate *by Pact Rank*, and a tithe is owed per cycle rather than per
## descent — so recording it per run would count the same debt three times and
## call two of them defaults. Written where the verdict is actually reached.
const TITHE: StringName = &"tithe"

static var _path: String = PATH
static var _scratch: bool = false


## **A scratch notebook, for probes** (ADR-152). Same rule as
## `SaveFile.use_a_scratch_profile` and `RunFile.use_a_scratch_run`: a check
## that writes into the player's own files is a check that can cost them a
## lineage.
static func use_a_scratch_ledger() -> void:
	_scratch = true
	_path = "user://ledger_probe.json"
	clear()


## **Nothing arms this** (ADR-261), deliberately.
##
## `RunFile` has an `arm()` because a run file is *state a player is in* and a
## process that has not opened one must not resume it. A notebook is not state;
## it is a side effect of playing, and the only thing it must never do is
## record a run nobody played. So rather than five `arm()` calls to keep in
## step with five `RunFile.arm()` calls, it asks the one question that actually
## matters and asks it through `RunFile`, which already knows the answer.
##
## The failure this avoids is the one ADR-152 records: three separate probes
## reasoned their way into using the player's real file, none of it appeared in
## any output, and every sweep destroyed a suspended run. A lifecycle you have
## to remember is a lifecycle somebody forgets.
static func writing() -> bool:
	return _scratch or not RunFile.a_check_is_running()


## Append one row. `kind` is an outcome or `LEGACY`; everything else is whatever
## the caller knows, because a row is a record rather than a schema and a
## question nobody has asked yet should not be blocked on a migration.
static func record(kind: StringName, about: Dictionary) -> void:
	if not writing():
		return
	var row: Dictionary = about.duplicate()
	row["kind"] = String(kind)
	row["at"] = Time.get_datetime_string_from_system(true)
	var book: Dictionary = _read()
	var kept: Array = book.get("rows", []) as Array
	kept.append(row)
	if kept.size() > KEEP:
		kept = kept.slice(kept.size() - KEEP)
	book["rows"] = kept
	_write(book)


## Every row, oldest first.
static func rows() -> Array:
	return _read().get("rows", []) as Array


static func clear() -> void:
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))


## **`DES-010`'s six questions, answered from the rows.**
##
## Computed rather than accumulated, so a row written by an older build still
## counts toward whatever this build knows how to ask — and so no counter can
## drift from the events it was supposed to be counting.
static func summary() -> Dictionary:
	var all: Array = rows()
	var runs: Array = []
	var legacies: Array = []
	var tithes: Array = []
	for entry: Variant in all:
		var row := entry as Dictionary
		match String(row.get("kind", "")):
			"legacy":
				legacies.append(row)
			"tithe":
				tithes.append(row)
			_:
				runs.append(row)

	var extracted: int = 0
	var died: int = 0
	var abandoned_runs: int = 0
	var first_death: int = 0
	var loot_left: int = 0
	var by_party: Dictionary = {}
	for entry: Variant in runs:
		var row := entry as Dictionary
		var kind: String = String(row.get("kind", ""))
		if kind == String(EXTRACTED):
			extracted += 1
		elif kind == String(DIED):
			died += 1
			if first_death == 0:
				first_death = int(row.get("descent", 0))
		elif kind == String(ABANDONED):
			abandoned_runs += 1
		loot_left += int(row.get("abandoned_value", 0))
		# Per-capita extracted value, which is the `DES-012` question: a
		# four-player run bringing home four times as much is not co-op paying
		# off, it is four bags.
		#
		# **Every run at that party size, including the ones that brought
		# nothing.** The question is whether a bigger party is worth joining,
		# and a party that hauls more per head while dying twice as often is
		# not better off — so this is expected value per head per run
		# attempted, not per run survived.
		var party: int = maxi(int(row.get("party", 1)), 1)
		var seat: Array = by_party.get(party, [0, 0]) as Array
		seat[0] = int(seat[0]) + 1
		seat[1] = int(seat[1]) + int(row.get("extracted_value", 0))
		by_party[party] = seat

	var kept_items: int = 0
	var kept_nodes: int = 0
	for entry: Variant in legacies:
		if String((entry as Dictionary).get("slot", "")) == "node":
			kept_nodes += 1
		else:
			kept_items += 1

	# **By rank, because that is the question.** A flat default rate hides the
	# thing `DES-003` is actually worried about — that the Tithe becomes
	# unpayable at some rank and the pact stops being a bargain.
	var asked_at: Dictionary = {}
	var missed_at: Dictionary = {}
	for entry: Variant in tithes:
		var row := entry as Dictionary
		var at: int = int(row.get("rank", 0))
		asked_at[at] = int(asked_at.get(at, 0)) + 1
		if not bool(row.get("met", false)):
			missed_at[at] = int(missed_at.get(at, 0)) + 1
	var default_by_rank: Dictionary = {}
	for at: int in asked_at:
		default_by_rank[at] = float(int(missed_at.get(at, 0))) \
			/ float(maxi(int(asked_at[at]), 1))

	var resolved: int = runs.size()
	var per_capita: Dictionary = {}
	for party: int in by_party:
		var seat: Array = by_party[party] as Array
		per_capita[party] = float(seat[1]) / float(maxi(int(seat[0]), 1)) \
			/ float(party)

	return {
		"runs": resolved,
		"extracted": extracted,
		"died": died,
		"abandoned": abandoned_runs,
		# `DES-010`: below 40 % the game is too punishing to retain, above
		# 80 % the pressure is not real.
		"extraction_rate": float(extracted) / float(maxi(resolved, 1)),
		"first_death_on_descent": first_death,
		"loot_left_behind": loot_left,
		"tithe_cycles": tithes.size(),
		"tithe_default_by_rank": default_by_rank,
		"legacy_items": kept_items,
		"legacy_nodes": kept_nodes,
		"per_capita_extracted": per_capita,
	}


static func _read() -> Dictionary:
	if not FileAccess.file_exists(_path):
		return {"version": VERSION, "rows": []}
	var handle: FileAccess = FileAccess.open(_path, FileAccess.READ)
	if handle == null:
		push_error("RunLedger: cannot open %s" % _path)
		return {"version": VERSION, "rows": []}
	var parsed: Variant = JSON.parse_string(handle.get_as_text())
	handle.close()
	var book := parsed as Dictionary
	if book == null:
		push_error("RunLedger: %s is not readable; starting a new one" % _path)
		return {"version": VERSION, "rows": []}
	# **A notebook is not a save file.** `SaveFile` migrates because losing a
	# profile costs a lineage; losing measurements costs a measurement, and a
	# migration path per version would be ceremony over something nobody is
	# owed. An older book is read for what this build understands and the
	# rows it cannot use are simply absent from the summary.
	if int(book.get("version", 0)) != VERSION:
		print("[ledger] %s is version %d and this build writes %d — starting "
			% [_path, int(book.get("version", 0)), VERSION]
			+ "a new one, and the old rows are not migrated")
		return {"version": VERSION, "rows": []}
	return book


static func _write(book: Dictionary) -> void:
	book["version"] = VERSION
	var handle: FileAccess = FileAccess.open(TMP, FileAccess.WRITE)
	if handle == null:
		push_error("RunLedger: cannot open %s for writing" % TMP)
		return
	handle.store_string(JSON.stringify(book, "\t"))
	handle.close()
	var here: DirAccess = DirAccess.open("user://")
	if here == null:
		push_error("RunLedger: cannot open user:// to place the ledger")
		return
	here.rename(TMP.get_file(), _path.get_file())
