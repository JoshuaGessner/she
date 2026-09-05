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
## ## The first piece of mutable state, and why it is this one
##
## `bound_to` arrives at `M2-T05` with the **ember** (`DES-012`), and it is the
## exact case ADR-084 was written about: every ember loads from one `.tres`, so
## a shared `Resource` could not possibly answer *whose* it is. Two embers on
## the floor are the same definition and two different people's lives.
##
## Still deliberately absent: `condition`, `fuel`, `charges`. Those are the
## other fields ADR-084's rationale names and none of them has a system yet —
## condition is `DES-008` economy work, fuel needs `LightTrait` and a lantern.
## A field nothing reads and nothing writes is the stub ADR-064 bans. They
## arrive the way this one did: with the thing that needs them.

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

## The peer whose life this thing carries, or `0` for the overwhelming majority
## of items that are simply objects.
##
## Only the **ember** uses it (`DES-012`): *"your ember, the piece of her fire
## she gave you, drops where you fell. A teammate can carry it."* Which teammate
## carries *whose* ember is the entire content of the M2 co-op gate, and it
## cannot live on the shared definition — that is ADR-084's argument arriving as
## a real case rather than a hypothetical lantern.
var bound_to: int = 0
## **She remembered this one** (`M3-T05`, `DES-003`).
##
## *"Legacy items are Scarred: carried through death at reduced power and
## cannot be tributed. They're a head start, not a stockpile."*
##
## Per-instance rather than per-definition, which is the whole reason this class
## exists: a Scarred seax and a fresh one are the same `ItemResource` and must
## not be the same object. The tribute rule is the load-bearing half — without
## it, a Legacy slot would be a way to carry **value** across death, and
## `DES-003` puts Legacy in the tier that is power-free of *economy* as well.
var scarred: bool = false


static func of(from: ItemResource, id: int) -> ItemInstance:
	var made := ItemInstance.new()
	made.definition = from
	made.instance_id = id
	return made


## Cells occupied, accounting for rotation.
func footprint() -> Vector2i:
	var size: Vector2i = definition.grid_size
	return Vector2i(size.y, size.x) if rotated else size


## True when this is somebody's life rather than an object.
func is_ember() -> bool:
	return bound_to != 0


## What the bag calls this. For almost everything it is the item's name; for an
## **ember** it also says whose, because a rescuer with two of them needs to
## know which friend they are about to put down (`DES-012`).
##
## The mark is repeated rather than numeric — `Ember ·`, `Ember ··` — so it is
## *countable* at a glance and survives monochrome, matching the motes the same
## ember wears on the floor. `DES-018`: shape first, colour second.
func label(seat: int) -> String:
	var name: String = definition.display()
	if not is_ember() or seat < 0:
		return name
	return "%s %s" % [name, "·".repeat(seat + 1)]


func weight() -> float:
	return definition.weight


func clamor() -> float:
	return definition.clamor


## The wire and save form: the **stable string id** plus this instance's own
## state, never a resource path (`TEC-003`, `TEC-006` principle 3). Moving the
## file that defines an item must not break a save or desync a party.
## What this one is worth as tribute. **Zero if Scarred** (`DES-003`): a
## Legacy slot carries a head start across death, never value — otherwise it
## becomes a way to launder a hoard through a life you were going to lose
## anyway, which is the loophole ADR-003 closed for raw Boon arriving through
## the door marked *item*.
func tribute_worth() -> int:
	if scarred:
		return 0
	return definition.tribute_value


## **`cell` is a pair, not a `Vector2i`, so this really is a save form**
## (`M4-T01`, ADR-185).
##
## The comment above has said *"the wire **and save** form"* since `M3-T07` and
## only the first half was ever true: `JSON.stringify` turns a `Vector2i` into
## the **string** `"(3, 2)"`, and `from_wire`'s `as Vector2i` on a string is an
## invalid cast — which *throws* rather than yielding null, the same Godot
## behaviour that cost ADR-132 a run file. Measured, not assumed.
##
## Nothing had ever written an item to disk, so nothing found out. A bag
## crossing a floor is the first thing that does. A two-element array survives
## JSON and RPC alike, so there is still one form rather than a save form beside
## a wire form.
func to_wire() -> Dictionary:
	return {
		"instance": instance_id,
		"item": definition.id,
		"cell": [cell.x, cell.y],
		"rotated": rotated,
		"bound": bound_to,
		"scarred": scarred,
	}


## Rebuild from the wire form. Returns `null` when the id names nothing the
## catalogue knows, which is what a save from a build that had an item this one
## does not looks like — a migration question (`TEC-003`), not a crash.
static func from_wire(row: Dictionary) -> ItemInstance:
	# **Every field defaulted, because this reads two untrusted things**
	# (ADR-199): a save file that may have been written by an older build or
	# truncated mid-write, and a bag a *client* declared over the wire. Bare
	# `row["cell"]` on a row without one is a runtime error, and both callers
	# take it somewhere it does damage — on the host it fires inside an RPC
	# handler and abandons the rest of that peer's inventory; on load it aborts
	# a read `RunFile` expects to be able to reject cleanly.
	#
	# An unknown id is still the one hard no: an item the catalogue does not
	# have cannot be built at all, and dropping the row is what `unpack` and
	# `RunFile` are both already written to expect.
	var known: ItemResource = ItemCatalogue.by_id(row.get("item", &"") as StringName)
	if known == null:
		return null
	var made := ItemInstance.of(known, int(row.get("instance", 0)))
	# **`int()` on both, because JSON has no integers.** A round trip through a
	# run file returns every number as a float, so `Vector2i(pair[0], pair[1])`
	# on raw variants would be building a grid cell out of 3.0 and 2.0.
	var pair: Array = row.get("cell", []) as Array
	# A cell needs both halves; anything shorter is a row that lost its shape,
	# and 0,0 is where an unplaced item already sits.
	made.cell = (Vector2i(int(pair[0]), int(pair[1])) if pair.size() >= 2
		else Vector2i.ZERO)
	made.rotated = bool(row.get("rotated", false))
	made.bound_to = int(row.get("bound", 0))
	# Absent in a save written before `M3-T05`, and false is right for every one
	# of them: nothing was Scarred before there were Legacy slots to scar it.
	made.scarred = bool(row.get("scarred", false))
	return made
