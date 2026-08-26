class_name DeedCatalogue
extends RefCounted

## Every authored deed, addressable by its stable id (`M3-T08`, `DES-016`).
##
## The same shape as `ItemCatalogue` and `ClassCatalogue`, down to the
## three-extension scan and the duplicate rule, because it answers the same
## question: a profile holds `"ded_bore_them_home"` and something has to turn
## that back into a resource without the save knowing where the file lived
## (`TEC-006` principle 3).
##
## **The three-extension scan is not defensive padding.** The repo holds
## `.tres`; an exported build does not — Godot re-serialises text resources when
## it packs them and leaves a `.remap`, so a scan matching only `.tres` finds
## nothing in a shipped build while `load()` on the original path keeps working.
## Reproduced deliberately in ADR-086. A deed table that comes back empty in an
## export is a lineage whose whole record of itself silently stops accruing.
##
## ## Five deeds exist
##
## `DES-016` targets 40–60 at 1.0, weighted toward rescue, refusal and memorial.
## These five are the ones the run can already answer without new
## instrumentation, which is the doc's own test for whether a deed belongs.
## Memorial and Calamity need NPCs who die and expeditions with patterns — both
## `M4` — and are **absent rather than stubbed** (ADR-064).

const DEEDS_ROOT: String = "res://data/deeds"
const PACKED_EXTENSIONS: Array[String] = ["tres", "res", "remap"]

## Keyed by `String`, never `StringName` — Godot treats the two as different
## dictionary keys, which produces a lookup that fails for a value that is
## demonstrably present.
static var _by_id: Dictionary = {}
static var _ids: Array[String] = []
static var _scanned: bool = false


## Every class, ordered by id so any two runs list them identically — including
## the select screen, which must not reshuffle itself between launches.
static func all() -> Array[DeedResource]:
	_scan()
	var found: Array[DeedResource] = []
	for id: String in _ids:
		found.append(_by_id[id] as DeedResource)
	return found


static func ids() -> Array[String]:
	_scan()
	return _ids.duplicate()


## The class behind a stable id, or `null` if nothing owns it — which is what a
## profile naming a class this build does not have looks like. A migration
## question (`TEC-003`), never a crash.
static func by_id(id: StringName) -> DeedResource:
	_scan()
	return _by_id.get(String(id)) as DeedResource


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	var dir: DirAccess = DirAccess.open(DEEDS_ROOT)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.get_extension() in PACKED_EXTENSIONS:
			_absorb("%s/%s" % [DEEDS_ROOT, entry.trim_suffix(".remap")])
		entry = dir.get_next()
	dir.list_dir_end()
	_ids.sort()


static func _absorb(path: String) -> void:
	var mark := load(path) as DeedResource
	if mark == null:
		return
	var key: String = String(mark.id)
	# First loaded wins. A duplicate is a corpus error and the data probe fails
	# the build over one; raising here would take down a running game for a
	# problem that cannot reach a commit.
	if _by_id.has(key):
		return
	_by_id[key] = mark
	_ids.append(key)
