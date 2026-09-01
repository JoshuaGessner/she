class_name RoomCatalogue
extends RefCounted
## Every authored room module, addressable by its stable id (`TEC-006`).
##
## The `ItemCatalogue` idiom, and it inherits that file's hard-won extension
## list rather than repeating the mistake: the repo holds `.tres`, **an exported
## build does not.** Godot re-serialises text resources when it packs them and
## leaves a `.remap` beside anything it moved, so a scan matching only `.tres`
## finds **zero modules in a shipped build** while `load()` on the original path
## keeps working — which is what makes it silent. ADR-086 is the record of
## exactly that shipping as an empty item table.
##
## A generator with no modules would not crash. It would emit floors with no
## rooms in them, pass every graph assertion, and look like it worked.


const ROOMS_ROOT: String = "res://data/rooms"
## Authored text, packed binary, or a redirect Godot left when it moved a file.
const PACKED_EXTENSIONS: Array[String] = ["tres", "res", "remap"]

static var _by_id: Dictionary = {}
static var _sorted: Array[RoomModule] = []
static var _scanned: bool = false


## Every module, **ordered by id** so any two runs enumerate them identically.
## `DirAccess` returns filesystem order, which is not a promise; a placer that
## iterated this unsorted would be deterministic only by luck (`TEC-007` §1).
static func all() -> Array[RoomModule]:
	_scan()
	return _sorted


## The module behind a stable id, or `null` if nothing owns it.
static func by_id(id: StringName) -> RoomModule:
	_scan()
	return _by_id.get(String(id), null)


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	var dir: DirAccess = DirAccess.open(ROOMS_ROOT)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.get_extension() in PACKED_EXTENSIONS:
			_absorb("%s/%s" % [ROOMS_ROOT, entry.trim_suffix(".remap")])
		entry = dir.get_next()
	dir.list_dir_end()
	# Sort by id, not by load order. See `all()`.
	_sorted.sort_custom(func(a: RoomModule, b: RoomModule) -> bool:
		return String(a.id) < String(b.id))


static func _absorb(path: String) -> void:
	var module: RoomModule = load(path) as RoomModule
	if module == null or module.id == &"":
		return
	# Keyed by `String`, never `StringName`: Godot treats the two as different
	# dictionary keys, so mixing them produces a lookup that fails for a value
	# that is demonstrably present. `ItemCatalogue` paid an afternoon for this.
	var key: String = String(module.id)
	if _by_id.has(key):
		# Duplicate ids are a corpus error and `--plan-probe` is what fails the
		# build over one. Here the first loaded wins, because a catalogue that
		# raised would take down a running game for a problem the validator
		# already refuses to let past a commit.
		return
	_by_id[key] = module
	_sorted.append(module)
