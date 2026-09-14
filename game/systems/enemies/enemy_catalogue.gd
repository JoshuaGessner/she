class_name EnemyCatalogue
extends RefCounted

## Every authored enemy, by its stable id (`M4-T02`, `TEC-006`, ADR-231).
##
## `ItemCatalogue`'s shape, including why the extensions are three: an exported
## build re-serialises `.tres` and leaves `.remap` beside it, and a scan that
## matched `.tres` alone would find no enemies in a shipped build (ADR-086).

const ENEMIES_ROOT: String = "res://data/enemies"
const PACKED_EXTENSIONS: Array[String] = ["tres", "res", "remap"]

## What a spawn that names no archetype builds: the Wretch, the slice's
## attrition body (ADR-230), which is what every enemy was before there were
## others.
const DEFAULT: StringName = &"enm_wretch"

## Keyed by `String` (`ItemCatalogue`'s note: `StringName` keys miss).
static var _by_id: Dictionary = {}
static var _ids: Array[String] = []
static var _scanned: bool = false


static func all() -> Array[EnemyResource]:
	_scan()
	var found: Array[EnemyResource] = []
	for id: String in _ids:
		found.append(_by_id[id] as EnemyResource)
	return found


## The archetype behind an id, or `null` if nothing owns it.
static func by_id(id: StringName) -> EnemyResource:
	_scan()
	return _by_id.get(String(id)) as EnemyResource


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	var dir: DirAccess = DirAccess.open(ENEMIES_ROOT)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.get_extension() in PACKED_EXTENSIONS:
			_absorb("%s/%s" % [ENEMIES_ROOT, entry.trim_suffix(".remap")])
		entry = dir.get_next()
	dir.list_dir_end()
	_ids.sort()


static func _absorb(path: String) -> void:
	var kind := load(path) as EnemyResource
	if kind == null:
		return
	var key: String = String(kind.id)
	if _by_id.has(key):
		return
	_by_id[key] = kind
	_ids.append(key)
