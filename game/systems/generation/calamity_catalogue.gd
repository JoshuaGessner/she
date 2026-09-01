class_name CalamityCatalogue
extends RefCounted
## Every authored Calamity, addressable by its stable id (`TEC-006`).
##
## The `ItemCatalogue` idiom, including its extension list: the repo holds
## `.tres` and an exported build does not, because Godot re-serialises text
## resources when it packs them and leaves a `.remap` behind (ADR-086). A scan
## matching only `.tres` finds nothing in a shipped build, and a generator with
## no Calamities does not crash — it builds floors that mean nothing and passes
## every structural check there is.


const CALAMITIES_ROOT: String = "res://data/calamities"
const PACKED_EXTENSIONS: Array[String] = ["tres", "res", "remap"]

static var _by_id: Dictionary = {}
static var _sorted: Array[CalamityResource] = []
static var _scanned: bool = false


## Every Calamity, **ordered by id** so any two runs roll identically from the
## same seed. `DirAccess` returns filesystem order, which is not a promise, and
## a roll indexed into an unsorted list would be deterministic only on one
## machine's disk (`TEC-007` §1).
static func all() -> Array[CalamityResource]:
	_scan()
	return _sorted


static func by_id(id: StringName) -> CalamityResource:
	_scan()
	return _by_id.get(String(id), null)


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	var dir: DirAccess = DirAccess.open(CALAMITIES_ROOT)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.get_extension() in PACKED_EXTENSIONS:
			_absorb("%s/%s" % [CALAMITIES_ROOT, entry.trim_suffix(".remap")])
		entry = dir.get_next()
	dir.list_dir_end()
	_sorted.sort_custom(func(a: CalamityResource, b: CalamityResource) -> bool:
		return String(a.id) < String(b.id))


static func _absorb(path: String) -> void:
	var calamity: CalamityResource = load(path) as CalamityResource
	if calamity == null or calamity.id == &"":
		return
	# Keyed by `String`, never `StringName`: Godot treats the two as different
	# dictionary keys (`ItemCatalogue` paid an afternoon for this).
	var key: String = String(calamity.id)
	if _by_id.has(key):
		return
	_by_id[key] = calamity
	_sorted.append(calamity)
