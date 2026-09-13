class_name WearableTrait
extends ItemTrait

## Armour, as equipment (ADR-219, `TEC-006`, `DES-009`'s triangle).
##
## `TEC-006` names this trait for slot, armour class and encumbrance. **Only the
## class is here.** The slot was built onto `ItemResource` at `M3-T07` because
## every item that can be held or worn needs one, and encumbrance is the item's
## own `weight` — so the one thing a wearable adds that nothing else carries is
## what it turns a blow with.
##
## **Body only.** `DES-023` §3: the class is the torso's, and head and arms turn
## away a wound each instead (`M4-T14`). A class on a helm would stack with the
## coat's, and a stack of shares off every blow is the stat ladder `DES-008`
## rejects. `ItemResource.validate()` refuses it rather than trusting nobody
## authors one.

@export var armour_class: Enums.ArmourClass = Enums.ArmourClass.UNARMOURED


func kind() -> String:
	return "wearable"


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	# An unarmoured wearable is an item whose purpose is filling a slot, which
	# `DES-023` §1 keeps off the list: no armour at all is already a choice.
	if armour_class == Enums.ArmourClass.UNARMOURED:
		problems.append("an unarmoured wearable turns nothing a bare body does not")
	return problems
