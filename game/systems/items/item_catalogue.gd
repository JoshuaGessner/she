class_name ItemCatalogue
extends RefCounted

## Every authored item, addressable by the stable string id (`TEC-006`).
##
## `TEC-006` principle 3: *stable string IDs, never resource paths.* A save
## holds `"glt_altar_plate"`, and something has to turn that back into an
## `ItemResource` without the save ever having known where the file lived. This
## is that something, and it is the only place in the project that maps one to
## the other.
##
## ## Why the extension list is three entries long
##
## The repo holds `.tres`. **An exported build does not.** Godot re-serialises
## text resources when it packs them and leaves a `.remap` beside anything it
## moved, so a scan matching only `.tres` finds **zero items in a shipped
## build** — while `load()` on the original path keeps working, which is what
## makes it silent. ADR-086 records exactly that failure: a build that launched
## cleanly at full size with an empty item table, reproduced deliberately, and
## caught only by a census that ran inside the packed binary.
##
## `movement_gym.gd`'s export probe learned this first and this file inherits
## it rather than repeating it — the probe now asks the catalogue, so there is
## one scan and it is the one that ships.

const ITEMS_ROOT: String = "res://data/items"

## What one item can arrive as: authored text, packed binary, or a redirect
## Godot left behind when it moved the file. All three resolve through `load()`
## on the path with `.remap` trimmed.
const PACKED_EXTENSIONS: Array[String] = ["tres", "res", "remap"]

## Keyed by `String`, never `StringName`. Godot treats the two as *different*
## dictionary keys, so mixing them produces a lookup that fails for a value
## that is demonstrably present — an afternoon to find, once.
static var _by_id: Dictionary = {}
static var _ids: Array[String] = []
static var _scanned: bool = false


## Every item, ordered by id so any two runs list them identically.
static func all() -> Array[ItemResource]:
	_scan()
	var found: Array[ItemResource] = []
	for id: String in _ids:
		found.append(_by_id[id] as ItemResource)
	return found


static func ids() -> Array[String]:
	_scan()
	return _ids.duplicate()


## The definition behind a stable id, or `null` if nothing owns it. A save
## naming an item that no longer exists is a migration problem (`TEC-003`), and
## it must arrive as a null rather than as a crash.
static func by_id(id: StringName) -> ItemResource:
	_scan()
	return _by_id.get(String(id)) as ItemResource


## Drop the cache. Only the data validator needs this — it plants deliberately
## broken resources and has to see the corpus as it now stands.
static func forget() -> void:
	_by_id = {}
	_ids = []
	_scanned = false


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	var dir: DirAccess = DirAccess.open(ITEMS_ROOT)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.get_extension() in PACKED_EXTENSIONS:
			_absorb("%s/%s" % [ITEMS_ROOT, entry.trim_suffix(".remap")])
		entry = dir.get_next()
	dir.list_dir_end()
	_ids.sort()


static func _absorb(path: String) -> void:
	var item := load(path) as ItemResource
	if item == null:
		return
	var key: String = String(item.id)
	# Duplicate ids are a corpus error, and `tests/data_probe.gd` is what fails
	# the build over one. Here the first loaded simply wins, because a
	# catalogue that raised would take down the running game for a problem the
	# validator already refuses to let past a commit.
	if _by_id.has(key):
		return
	_by_id[key] = item
	_ids.append(key)
