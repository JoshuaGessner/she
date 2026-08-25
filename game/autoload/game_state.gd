extends Node

## What outlives a run (`M2-T06`, `DES-014`, `DES-003`).
##
## The third of `TEC-001`'s six autoloads, registered now because it finally
## has work (ADR-066): until `M2-T04` closed the loop there was nothing that
## survived leaving the floor, and until `M2-T06` there was nowhere to put it.
##
## ## Three tiers, and they are not the same thing
##
## `DES-003` and `DES-014` are precise about what survives what, and the whole
## emotional architecture rests on the difference:
##
## | | Survives a run | Survives death |
## |---|---|---|
## | **What you carried** | only if you extracted | no |
## | **The stash** | yes | **no** — the great reset (`DES-008`) |
## | **The hoard** | yes | **yes, always** (LINEAGE tier) |
##
## The hoard is the one that matters most and costs least. `DES-014`: *"a
## permanent physical monument to every life you have lost, which turns
## ADR-004's harshness into something you can walk on"* — visible progress with
## **zero balance impact**, which makes it the safest retention mechanism in
## the design.
##
## ## Saved to disk since `M3-T06`
##
## `SaveFile` owns the format, the versioning and the migrations; this owns what
## goes in it. The split is `TEC-003`'s: *what* persists is a design question
## and *how* is not, and the one-function death operation — clear LIFE, keep
## LINEAGE — is already how `die()` below is written.
##
## **Writing only happens once a profile has been opened.** `_live` is false
## until `load_profile()` succeeds, which means a process that never opened one
## never writes one: a probe booting a level directly mutates this in memory and
## leaves the player's profile alone, and a build that *refused* a profile it
## could not read cannot then overwrite it. That is not a probe accommodation —
## a save is a thing you write *back*, and there is nothing to write back to
## until something was read.
##
## ## Never networked
##
## `DES-012` makes every pact individual and `TEC-004` keeps progression off
## the wire entirely. This is local state on every peer, describing only the
## person sitting at that machine. ADR-021 makes that structural rather than
## careful: the Chamber where it all lives is a scene no other player enters.

## What you walked out of the Deep with, waiting to be sorted. Emptied by the
## Chamber once you have decided what she keeps.
var carried: Array[ItemInstance] = []

## Kept for next time. **Wiped by death** (`DES-008`'s great reset) — which is
## what stops an economy inflating across a lineage and is why this design
## needs no late-game nerfs.
var stash: Array[ItemInstance] = []

## Given to her. **Never wiped, ever.** Stored as ids and values rather than
## instances because nothing ever comes back off the pile — she is lying on it.
var hoard: Array[StringName] = []
var hoard_value: int = 0

## Runs completed this session, for the readouts. Not progression; `DES-003`'s
## Pact Rank is `M3-T04` and is a different number with different rules.
##
## **Deliberately not saved.** Its own name is "this session", and `TEC-003`'s
## LIFE-tier `run_count` is a different number that counts against a Tithe
## cycle. It arrives with `M3-T04`, which is the first build in which there is
## a cycle to count against.
var descents: int = 1

## Whether a profile has been opened. See the header: nothing is written back
## to a file that was never read.
var _live: bool = false


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--save-probe"):
		_save_probe()


## Carried out alive. The Chamber sorts it from here.
func bring_home(items: Array[ItemInstance]) -> void:
	carried = items.duplicate()
	_persist()


## Put on the pile. One-way, by construction: there is no method that takes
## anything off a hoard, because `DES-014` gives her everything you ever gave
## her and never gives any of it back.
func tribute(item: ItemInstance) -> void:
	hoard.append(item.definition.id)
	hoard_value += item.definition.tribute_value
	carried.erase(item)
	stash.erase(item)
	_persist()


## Kept for next time.
func keep(item: ItemInstance) -> void:
	if not stash.has(item):
		stash.append(item)
	carried.erase(item)
	_persist()


## Take something back out of the stash for a descent.
func withdraw(item: ItemInstance) -> void:
	stash.erase(item)
	_persist()


## **The great reset** (`DES-008`, ADR-004). Everything you were carrying and
## everything you had put aside, gone. The hoard is untouched and that is the
## entire point: the pile is what you have to show for the lives it cost.
func die() -> void:
	carried.clear()
	stash.clear()
	# `TEC-003` calls this the critical path: a hard kill during the death
	# sequence must never produce a half-wiped profile. It cannot, because
	# `SaveFile.write` renames a complete file over the old one — either the
	# life ended or it did not, and there is no third state on disk.
	_persist()


func stash_value() -> int:
	var sum: int = 0
	for item: ItemInstance in stash:
		sum += item.definition.tribute_value
	return sum


# ── the file ──────────────────────────────────────────────────────────────


## Open the profile. Called when a session starts — `MainMenu` on the way to the
## Threshold — because that is when a player has one, and it is the only path
## into the game.
##
## Returns whether this process may now write. **A profile that exists and could
## not be read leaves us not-live**, which is the whole of the protection: a
## build that refuses a save from a newer version must not then overwrite it
## with what it managed to understand.
func load_profile() -> bool:
	if SaveFile.exists():
		var data: Dictionary = SaveFile.read()
		if data.is_empty():
			_live = false
			return false
		from_dict(data)
	_live = true
	return true


## Whether this process will write what it is told. False before a profile has
## been opened, and false again if one was found and refused.
func saving() -> bool:
	return _live


## The two tiers that exist, in `TEC-003`'s sections. `carried` is absent on
## purpose: it is what you are holding *during* a run, and `M3-T09` is where a
## suspended run gets a file of its own (ADR-116).
func to_dict() -> Dictionary:
	var pile: Array[String] = []
	for id: StringName in hoard:
		pile.append(String(id))
	# **Ids only.** `_carry_the_stash_down()` re-mints a fresh `ItemInstance`
	# from the definition and discards the stashed one, so a cell, a rotation
	# and an instance id would all be written and then thrown away on load. The
	# moment anything persists a *placed* item — a bag across a suspend — those
	# come with it, and that is `M3-T09`.
	var kept: Array[String] = []
	for item: ItemInstance in stash:
		kept.append(String(item.definition.id))
	return {
		"lineage": {"hoard": pile, "hoard_value": hoard_value},
		"life": {"stash": kept},
	}


## Rebuild from a profile already migrated to the current version.
##
## An id the catalogue does not know is **skipped with a warning, not fatal**:
## that is what a save from a build with an item this one lacks looks like, and
## `ItemInstance.from_wire` documents the same rule for the same reason.
func from_dict(data: Dictionary) -> void:
	var lineage: Dictionary = _section(data, "lineage")
	hoard.clear()
	for raw: Variant in lineage.get("hoard", []) as Array:
		hoard.append(StringName(raw))
	hoard_value = int(lineage.get("hoard_value", 0))

	var life: Dictionary = _section(data, "life")
	stash.clear()
	for raw: Variant in life.get("stash", []) as Array:
		var known: ItemResource = ItemCatalogue.by_id(StringName(raw))
		if known == null:
			push_warning("GameState: stashed '%s' is not in this build" % raw)
			continue
		# Instance id `0`: an `Inventory` mints from 1, so nothing in a bag can
		# collide with something merely sitting in the stash.
		stash.append(ItemInstance.of(known, 0))
	carried.clear()


func _persist() -> void:
	if not _live:
		return
	SaveFile.write(to_dict())


func _section(data: Dictionary, name: String) -> Dictionary:
	var part: Variant = data.get(name, {})
	return part as Dictionary if typeof(part) == TYPE_DICTIONARY else {}


# ── the check ─────────────────────────────────────────────────────────────


## `--save-probe`: does a profile survive a round trip, refuse what it must,
## and do migrations run in order?
##
## It lives in this autoload rather than in a level because its subject is this
## autoload and `SaveFile`, and neither has a room. `Config` hosts
## `--export-probe` on the same reasoning (ADR-099): a check with no natural
## level belongs with the thing that always boots, not with whichever scene
## happens to be main this month.
func _save_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	SaveFile.wipe()

	# ── a profile that is not there ──────────────────────────────────────
	if not load_profile():
		problems.append(("opening a profile that does not exist failed — first "
			+ "launch is the most common load there is, and a build that "
			+ "cannot do it cannot be played at all"))
	if FileAccess.file_exists(SaveFile.PATH):
		problems.append(("opening a missing profile created one — a file must "
			+ "appear because something was saved, not because something looked"))
	print("[save] no profile     opened, live=%s, nothing written" % _live)

	# ── a round trip ─────────────────────────────────────────────────────
	tribute(ItemInstance.of(ItemCatalogue.by_id(&"glt_hoard_coin"), 1))
	keep(ItemInstance.of(ItemCatalogue.by_id(&"wpn_seax"), 2))
	var gave: int = hoard_value
	var pile: int = hoard.size()

	if FileAccess.file_exists(SaveFile.TMP):
		problems.append(("a scratch file survived the write — `%s` is renamed "
			+ "over the profile, and one left behind means the rename did not "
			+ "happen and the profile on disk is the previous one")
			% SaveFile.TMP)

	hoard.clear()
	hoard_value = 0
	stash.clear()
	from_dict(SaveFile.read())
	print("[save] round trip     hoard %d/%d, value %d/%d, stash %d" % [
		hoard.size(), pile, hoard_value, gave, stash.size()])
	if hoard.size() != pile or hoard_value != gave:
		problems.append(("the hoard did not survive a round trip — it is the "
			+ "one tier `DES-014` says is never wiped, ever, and a lineage that "
			+ "does not reach disk is the whole of what this file is for"))
	if stash.size() != 1 or stash[0].definition.id != &"wpn_seax":
		problems.append(("the stash did not survive a round trip — `DES-008`'s "
			+ "great reset is supposed to be what empties it, not quitting"))

	# ── a scratch file left by an earlier crash ──────────────────────────
	var litter := FileAccess.open(SaveFile.TMP, FileAccess.WRITE)
	litter.store_string("half a save, from a process that died")
	litter.close()
	keep(ItemInstance.of(ItemCatalogue.by_id(&"glt_hoard_coin"), 3))
	var after_litter: Dictionary = SaveFile.read()
	print("[save] stale scratch  ignored, profile still v%d" % int(
		(after_litter.get("meta", {}) as Dictionary).get("save_version", 0)))
	if after_litter.is_empty():
		problems.append(("a leftover scratch file broke the next load — a crash "
			+ "mid-write is exactly the case the rename exists to survive, so "
			+ "its debris must cost nothing"))

	# ── a profile this build cannot read ─────────────────────────────────
	_write_raw('{"meta": {"save_version": %d}, "lineage": {"hoard_value": 999}}'
		% (SaveFile.SAVE_VERSION + 1))
	if not SaveFile.read().is_empty():
		problems.append(("a save from a newer build was loaded — its migrations "
			+ "have not been written, so what came back is a guess"))
	if load_profile():
		problems.append(("a profile this build refused still went live — the "
			+ "next tribute would write over a newer save with whatever this "
			+ "build managed to understand of it"))
	hoard_value = 1
	_persist()
	var untouched: Dictionary = SaveFile.read_raw()
	var kept_value: int = int((untouched.get("lineage", {}) as Dictionary).get(
		"hoard_value", 0))
	print("[save] newer profile  refused, left on disk at %d" % kept_value)
	if kept_value != 999:
		problems.append(("a refused profile was overwritten anyway — refusing to "
			+ "read it is worth nothing if we then destroy it"))

	# ── a profile that is not a profile ──────────────────────────────────
	#
	# The second half of this is the one that matters, and asserting only the
	# first is how the bug in `SaveFile.exists()`'s note shipped past a green
	# probe: garbage not loading was true while garbage was being destroyed.
	_write_raw("this is not JSON and never was")
	if not SaveFile.read().is_empty():
		problems.append(("garbage loaded as a profile — `TEC-003` asks for a "
			+ "clean failure rather than half-loading into a corrupt state"))
	if load_profile():
		problems.append(("an unreadable profile still went live — a file that "
			+ "cannot be parsed is the case a player most needs protected, not "
			+ "the one where it parses and is merely too new"))
	hoard_value = 7
	_persist()
	var still_garbage: bool = FileAccess.open(
		SaveFile.PATH, FileAccess.READ).get_as_text().begins_with("this is not")
	print("[save] corrupt        refused, left on disk=%s" % still_garbage)
	if not still_garbage:
		problems.append(("an unreadable profile was overwritten — whatever is "
			+ "in that file is the only copy of somebody's lineage, and a build "
			+ "that cannot read it has no business replacing it"))

	# ── migrations, driven with a table the real one cannot supply yet ───
	# These build a **new** dictionary rather than mutating the one they are
	# given, and that is load-bearing rather than tidy. A Dictionary is a
	# reference in GDScript, so in-place migrations make `walk()` appear to work
	# even when it throws its steps' return values away — planted exactly that
	# and the probe stayed green. A migration is a function from one shape to
	# another, and testing it as one is the only way the wiring is proved.
	var order: Array[int] = []
	var first: Callable = func(step: Dictionary) -> Dictionary:
		order.append(1)
		var out: Dictionary = step.duplicate(true)
		out["stepped_one"] = true
		return out
	var second: Callable = func(step: Dictionary) -> Dictionary:
		order.append(2)
		var out: Dictionary = step.duplicate(true)
		out["stepped_two"] = true
		return out
	var walked: Dictionary = SaveFile.walk(
		{"meta": {"save_version": 1}}, {1: first, 2: second}, 1, 3)
	var landed: int = int((walked.get("meta", {}) as Dictionary).get(
		"save_version", 0))
	print("[save] migrations     ran %s, landed at v%d" % [order, landed])
	if order != [1, 2]:
		problems.append(("migrations did not run once each in order, they ran "
			+ "%s — `TEC-003` loads from arbitrary old versions and a step "
			+ "skipped or repeated corrupts a profile silently") % [order])
	if not walked.has("stepped_one") or not walked.has("stepped_two"):
		problems.append("a migration's result was discarded rather than carried forward")
	if landed != 3:
		problems.append(("a migrated profile was stamped v%d rather than the "
			+ "version it was actually migrated to, so the next load would run "
			+ "the same steps again") % landed)

	# A gap in the **middle** of the table, not an empty one. An empty table
	# fails on its first step, so anything at all that returns nothing looks
	# right; a gap after a step that succeeded is the case where skipping it
	# hands back a half-migrated profile, which is the actual danger.
	var ran_before: int = order.size()
	var gapped: Dictionary = SaveFile.walk(
		{"meta": {"save_version": 1}}, {1: first}, 1, 3)
	var ran_anyway: int = order.size() - ran_before
	print("[save] missing step   refused, %d step(s) ran, carried forward=%s"
		% [ran_anyway, not gapped.is_empty()])
	if not gapped.is_empty():
		problems.append(("a gap in the migration table was skipped rather than "
			+ "refused, and a profile half-way between two shapes came back — "
			+ "a shape no build ever wrote, saved back over the one that was"))
	if ran_anyway != 0:
		problems.append(("%d migration(s) ran before the gap was noticed — the "
			+ "route has to be checked before the first step, or a refusal "
			+ "still leaves a profile part-way between two formats")
			% ran_anyway)

	SaveFile.wipe()
	for problem: String in problems:
		print("[save] PROBLEM: %s" % problem)
	print("[save] probe complete")
	get_tree().quit(1 if problems.size() > 0 else 0)


func _write_raw(text: String) -> void:
	var file := FileAccess.open(SaveFile.PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()
