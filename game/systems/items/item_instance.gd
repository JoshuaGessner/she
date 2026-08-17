class_name ItemInstance
extends RefCounted

## One carried thing (ADR-084, closing Q103).
##
## **Not a `Resource`, and that is the whole reason this class exists.** Godot
## shares one `Resource` between every holder of it, so two lanterns loaded
## from the same `.tres` would share one fuel value and two blades one
## condition. The definition and the carried thing therefore have to be
## different objects:
##
## | | |
## |---|---|
## | `ItemResource` | the shared, immutable definition — what a Hoard-Coin *is*. Never mutated at runtime |
## | `ItemInstance` | one carried thing — a reference to its definition, a per-instance id, where it sits, and any mutable state |
##
## `RefCounted` rather than `Resource` makes that structural: there is no path
## to load one from, nothing caches it, and two instances of the same item are
## two objects however they were made.
##
## ## What is deliberately not here
##
## No `condition`, no `fuel`, no `charges`. Those are the fields ADR-084's
## rationale *names*, and none of them has a system yet — condition is
## `DES-008` economy work, fuel needs `LightTrait` and a lantern. A field
## nothing reads and nothing writes is the stub ADR-064 bans, and adding one
## here would make this class look finished while being untestable.
##
## The class is fully justified without them: `instance_id` and `cell` are
## already per-instance state a shared definition cannot hold, because two
## altar-plates in one bag are the same definition in two different squares.

## Unique within one inventory, assigned by the host. This is what an RPC and a
## save row name — never an array index, which changes the moment anything is
## removed, and never the definition's id, which two carried plates share.
var instance_id: int = 0

## The shared definition. Read, never written.
var definition: ItemResource = null

## Top-left square of this item's footprint, in grid cells (`DES-019`).
var cell: Vector2i = Vector2i.ZERO

## Turned ninety degrees. A spear is `1x4` and fits a 6-wide grid lying down
## only if it can be turned, and RE4's case — which `DES-019` names as the
## gold standard — makes rotation most of what the spatial puzzle *is*.
var rotated: bool = false


static func of(from: ItemResource, id: int) -> ItemInstance:
	var made := ItemInstance.new()
	made.definition = from
	made.instance_id = id
	return made


## Cells occupied, accounting for rotation.
func footprint() -> Vector2i:
	var size: Vector2i = definition.grid_size
	return Vector2i(size.y, size.x) if rotated else size


func weight() -> float:
	return definition.weight


func clamor() -> float:
	return definition.clamor


## The wire and save form: the **stable string id** plus this instance's own
## state, never a resource path (`TEC-003`, `TEC-006` principle 3). Moving the
## file that defines an item must not break a save or desync a party.
func to_wire() -> Dictionary:
	return {
		"instance": instance_id,
		"item": definition.id,
		"cell": cell,
		"rotated": rotated,
	}


## Rebuild from the wire form. Returns `null` when the id names nothing the
## catalogue knows, which is what a save from a build that had an item this one
## does not looks like — a migration question (`TEC-003`), not a crash.
static func from_wire(row: Dictionary) -> ItemInstance:
	var known: ItemResource = ItemCatalogue.by_id(row["item"] as StringName)
	if known == null:
		return null
	var made := ItemInstance.of(known, int(row["instance"]))
	made.cell = row["cell"] as Vector2i
	made.rotated = bool(row["rotated"])
	return made
