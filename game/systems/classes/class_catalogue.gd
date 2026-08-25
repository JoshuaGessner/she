class_name ClassCatalogue
extends RefCounted

## Every authored class, addressable by its stable id (`M3-T02`, `DES-011`).
##
## Deliberately the same shape as `ItemCatalogue`, down to the extension list
## and the duplicate rule, because it answers the same question: a profile
## holds `"huskarl"` and something has to turn that back into a resource
## without the save ever knowing where the file lived (`TEC-006` principle 3).
##
## **Including the three-extension scan, which is not defensive padding.** The
## repo holds `.tres`; an exported build does not. Godot re-serialises text
## resources when it packs them and leaves a `.remap` behind, so a scan matching
## only `.tres` finds **nothing in a shipped build** while `load()` on the
## original path keeps working — silent, and reproduced deliberately in ADR-086.
## A class table that comes back empty in an export is a build where nobody can
## choose a class, which is a build nobody can play.
##
## ## One class exists
##
## `DES-011` lists six. `huskarl` is authored; `M3-T11` authors the Veiðimaðr
## and `M5-T01` the remaining four. They are **absent, not stubbed** (ADR-064) —
## the select screen shows what the catalogue holds, so a class that has not
## been written simply is not offered, and a playtester cannot pick a name that
## does nothing.

const CLASSES_ROOT: String = "res://data/classes"
const PACKED_EXTENSIONS: Array[String] = ["tres", "res", "remap"]

## Keyed by `String`, never `StringName` — Godot treats the two as different
## dictionary keys, which produces a lookup that fails for a value that is
## demonstrably present.
static var _by_id: Dictionary = {}
static var _ids: Array[String] = []
static var _scanned: bool = false


## Every class, ordered by id so any two runs list them identically — including
## the select screen, which must not reshuffle itself between launches.
static func all() -> Array[ClassResource]:
	_scan()
	var found: Array[ClassResource] = []
	for id: String in _ids:
		found.append(_by_id[id] as ClassResource)
	return found


static func ids() -> Array[String]:
	_scan()
	return _ids.duplicate()


## The class behind a stable id, or `null` if nothing owns it — which is what a
## profile naming a class this build does not have looks like. A migration
## question (`TEC-003`), never a crash.
static func by_id(id: StringName) -> ClassResource:
	_scan()
	return _by_id.get(String(id)) as ClassResource


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	var dir: DirAccess = DirAccess.open(CLASSES_ROOT)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.get_extension() in PACKED_EXTENSIONS:
			_absorb("%s/%s" % [CLASSES_ROOT, entry.trim_suffix(".remap")])
		entry = dir.get_next()
	dir.list_dir_end()
	_ids.sort()


static func _absorb(path: String) -> void:
	var sworn := load(path) as ClassResource
	if sworn == null:
		return
	var key: String = String(sworn.id)
	# First loaded wins. A duplicate is a corpus error and the data probe fails
	# the build over one; raising here would take down a running game for a
	# problem that cannot reach a commit.
	if _by_id.has(key):
		return
	_by_id[key] = sworn
	_ids.append(key)
