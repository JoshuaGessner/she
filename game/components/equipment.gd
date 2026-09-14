class_name Equipment
extends Node

## What you are holding and wearing (`M3-T07`, `DES-020`).
##
## Six slots, and `DES-020` is emphatic about why not seven: *"every slot
## multiplies against every armour set in art cost."* There are no trinkets.
##
## ## What this is not
##
## It is not a stat block. `DES-008` makes gear **sidegrades with pronounced
## identity, not a rarity ladder**, and `DES-020` states the rule this component
## has to keep true: *"better means more appropriate, better preserved, and
## better provenance — never bigger numbers."* Nothing here sums anything. A
## slot holds an item; the systems that care read the item.
##
## ## The three rules that are not just bookkeeping
##
## - **A two-handed weapon takes the off hand too.** `DES-020`: *"no lantern, no
##   shield, no map without stowing."* The off hand is the contested space and
##   that contest is the design — a shield or a light, never both.
## - **What comes off goes back to the bag**, and if the bag will not take it,
##   the swap does not happen. Equipment is not a second inventory with
##   infinite room, and an item that vanished because a slot was full would be
##   loot `DES-002` never agreed to take from you.
## - **An item belongs to exactly one place.** Equipping removes it from the
##   bag; unequipping puts it back. There is never a copy in both, which is the
##   duplicate-bow shape ADR-124 found when a kit was in two places at once.

signal changed

## Slot → `ItemInstance`. Absent means empty; there is no null-object entry, so
## `has()` and "is something there" are the same question.
var _worn: Dictionary = {}


func in_slot(slot: Enums.Slot) -> ItemInstance:
	return _worn.get(slot) as ItemInstance


func is_empty() -> bool:
	return _worn.is_empty()


func count() -> int:
	return _worn.size()


## Everything worn, in slot order so any two readouts list it identically.
func worn() -> Array[ItemInstance]:
	var found: Array[ItemInstance] = []
	for slot: Enums.Slot in [Enums.Slot.MAIN_HAND, Enums.Slot.OFF_HAND,
			Enums.Slot.ARMS, Enums.Slot.HEAD, Enums.Slot.BODY, Enums.Slot.PACK]:
		var item: ItemInstance = in_slot(slot)
		if item != null:
			found.append(item)
	return found


## The first trait of a kind among everything worn, or null. How every consumer
## asks: `MeleeWeapon` wants the main hand's `WieldableTrait` and does not care
## which slot it came from.
func trait_in(slot: Enums.Slot, type: Script) -> ItemTrait:
	var item: ItemInstance = in_slot(slot)
	if item == null:
		return null
	return item.definition.first_trait(type)


## Why this cannot be equipped, or empty if it can. A sentence rather than a
## bool, for the reason `GameState.why_not` gives: a refusal a player cannot
## read is the unexplainable loss `PRO-005` §5 rules out, moved into a menu.
func why_not(definition: ItemResource) -> String:
	if definition == null:
		return "nothing to equip"
	if definition.slot == Enums.Slot.NONE:
		return "%s is not something you wear or hold" % definition.display()
	return ""


## Put it on. Returns whatever came off — which the caller owes the bag.
##
## **The caller moves the item**, not this: `Equipment` does not know where an
## item came from and must not guess, or the one place a thing exists becomes
## two places that disagree.
func equip(item: ItemInstance) -> Array[ItemInstance]:
	var displaced: Array[ItemInstance] = []
	if item == null or why_not(item.definition) != "":
		return displaced
	var slot: Enums.Slot = item.definition.slot
	var was: ItemInstance = in_slot(slot)
	if was != null:
		displaced.append(was)
	# A two-hander clears the off hand; equipping into the off hand clears a
	# two-hander out of the main. `DES-020` makes both directions the same
	# rule, so neither is a special case of the other.
	if slot == Enums.Slot.MAIN_HAND and item.definition.two_handed:
		var other: ItemInstance = in_slot(Enums.Slot.OFF_HAND)
		if other != null:
			displaced.append(other)
			_worn.erase(Enums.Slot.OFF_HAND)
	elif slot == Enums.Slot.OFF_HAND:
		var held: ItemInstance = in_slot(Enums.Slot.MAIN_HAND)
		if held != null and held.definition.two_handed:
			displaced.append(held)
			_worn.erase(Enums.Slot.MAIN_HAND)
	_worn[slot] = item
	changed.emit()
	return displaced


## Take it off and hand it back. Null when the slot was empty.
func unequip(slot: Enums.Slot) -> ItemInstance:
	var was: ItemInstance = in_slot(slot)
	if was == null:
		return null
	_worn.erase(slot)
	changed.emit()
	return was


func clear() -> void:
	if _worn.is_empty():
		return
	_worn.clear()
	changed.emit()


## Kilograms worn and held (ADR-224). **The same weight it has in the bag**, by
## the developer's call over half weight and over none: `DES-020`'s mail is
## *"heavier, louder"*, its no-pack body *"minimal weight, near-silent"*, and
## `DES-023` charges plate and the pack frame their weight. Before this only the
## bag counted, and all of those were free on your body.
func total_weight() -> float:
	var sum: float = 0.0
	for item: ItemInstance in _worn.values():
		sum += item.weight()
	return sum


## What wearing it gives away, on the scale `Inventory.total_clamor` uses — a
## byrnie jingles on your back as it does in the bag (ADR-224).
func total_clamor() -> float:
	var sum: float = 0.0
	for item: ItemInstance in _worn.values():
		sum += item.clamor()
	return sum


## What the bag is, expressed as a grid (`DES-020`): *"the Pack slot sets your
## inventory grid size — bigger pack, more grid, more weight, more Clamor. The
## upgrade that makes you more powerful is the upgrade that makes you louder."*
##
## With no pack you get `TuningProfile.inventory_grid`, which is exactly what
## its own note has said it would become since `M2-T01`: the **no-pack** grid,
## not the only grid.
func grid_size() -> Vector2i:
	var pack: PackTrait = trait_in(Enums.Slot.PACK, PackTrait) as PackTrait
	return pack.grid if pack != null else Config.tuning.inventory_grid


## What is worn, for the save (`TEC-003`) and the spawn payload. Slot names
## rather than indices: an enum reordered later must not silently move a helm
## onto a hand. **Records, not ids** (save v10, ADR-223) — a Scarred seax worn
## through one descent came back whole, because an id cannot say it was Scarred.
##
## **Every slot, and an empty one says so with `null`** (ADR-228). An empty
## dictionary is what `Player._dress_the_body` reads as *never dressed*, and it
## dresses the class kit — so a body that had put everything away wrote exactly
## that, and a Veiðimaðr who stowed the bow before the Shaft was handed a second
## one on the next floor. Wearing nothing and never having dressed are now two
## different dictionaries.
func to_wire() -> Dictionary:
	var rows: Dictionary = {}
	for slot: Enums.Slot in [Enums.Slot.MAIN_HAND, Enums.Slot.OFF_HAND,
			Enums.Slot.ARMS, Enums.Slot.HEAD, Enums.Slot.BODY, Enums.Slot.PACK]:
		var item: ItemInstance = in_slot(slot)
		rows[Enums.Slot.keys()[slot]] = item.to_record() if item != null else null
	return rows
