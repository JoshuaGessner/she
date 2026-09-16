class_name ContractCatalogue
extends RefCounted

## Every contract archetype and faction, by id (`M4-T04`, ADR-241).
##
## `EnemyCatalogue`'s shape, including its three extensions: an exported build
## re-serialises `.tres` and leaves `.remap` beside it (ADR-086).

const CONTRACTS_ROOT: String = "res://data/contracts"
const FACTIONS_ROOT: String = "res://data/factions"
## Her demands (`DES-007` tier 1, ADR-243).
const DEMANDS_ROOT: String = "res://data/demands"
const PACKED_EXTENSIONS: Array[String] = ["tres", "res", "remap"]
## The one faction the slice has (`M4-T04`, the developer's call): the Lodge,
## whose fire the Threshold already is.
const LODGE: StringName = &"fac_ashen_lodge"

static var _archetypes: Dictionary = {}
static var _factions: Dictionary = {}
static var _demands: Dictionary = {}
static var _scanned: bool = false


static func archetype(id: StringName) -> ContractArchetypeResource:
	_scan()
	return _archetypes.get(String(id)) as ContractArchetypeResource


static func faction(id: StringName) -> FactionResource:
	_scan()
	return _factions.get(String(id)) as FactionResource


## A faction's work, sorted by id so every machine and every seed read the
## same list in the same order.
static func archetypes_of(faction_id: StringName) -> Array[ContractArchetypeResource]:
	_scan()
	var ids: Array = _archetypes.keys()
	ids.sort()
	var found: Array[ContractArchetypeResource] = []
	for id: String in ids:
		var kind := _archetypes[id] as ContractArchetypeResource
		if kind.faction == faction_id:
			found.append(kind)
	return found


static func demand(id: StringName) -> DemandResource:
	_scan()
	return _demands.get(String(id)) as DemandResource


## Every demand she can make, sorted by id so one lineage names the same one on
## every machine.
static func demands() -> Array[DemandResource]:
	_scan()
	var ids: Array = _demands.keys()
	ids.sort()
	var found: Array[DemandResource] = []
	for id: String in ids:
		found.append(_demands[id] as DemandResource)
	return found


## Everything this catalogue holds, for the export census.
static func count() -> int:
	_scan()
	return _archetypes.size() + _factions.size() + _demands.size()


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	for root: String in [CONTRACTS_ROOT, FACTIONS_ROOT, DEMANDS_ROOT]:
		var dir: DirAccess = DirAccess.open(root)
		if dir == null:
			continue
		dir.list_dir_begin()
		var entry: String = dir.get_next()
		while entry != "":
			if not dir.current_is_dir() and entry.get_extension() in PACKED_EXTENSIONS:
				_absorb(load("%s/%s" % [root, entry.trim_suffix(".remap")]))
			entry = dir.get_next()
		dir.list_dir_end()


static func _absorb(resource: Resource) -> void:
	var kind := resource as ContractArchetypeResource
	if kind != null:
		_archetypes[String(kind.id)] = kind
	var group := resource as FactionResource
	if group != null:
		_factions[String(group.id)] = group
	var asked := resource as DemandResource
	if asked != null:
		_demands[String(asked.id)] = asked
