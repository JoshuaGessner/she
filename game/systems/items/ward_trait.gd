class_name WardTrait
extends ItemTrait

## **Turns away one wound** (`M4-T14`, ADR-239, `DES-023` §3).
##
## The helm and the bracers. `DES-023` gives the armour class to the body piece
## alone, because three pieces each shaving a share off every blow is the stat
## ladder `DES-008` rejects; head and arms turn away a named wound instead — a
## capability with a name, which a player can feel the absence of the first time
## a Hall-Warden's hammer comes down on a bare head.
##
## **Whole, not a chance.** A helm that stopped a concussion one blow in three
## would be a number the player could not see and a death they could not
## explain (principle 4). Worn, the wound cannot happen; unworn, it can.
##
## Nothing wards the leg. `DES-023` has no greaves, and the gash is the one wound
## the field can treat — a binding closes it — so its answer is in the bag.

## Which wound this turns away.
@export var wards: Enums.Wound = Enums.Wound.CONCUSSED


## Where a ward for `wound` is worn, or `Slot.NONE` when nothing may ward it.
##
## One table read by both sides — the item's validator refuses a helm that keeps
## an arm whole, and `Player.wound()` looks in this slot and nowhere else — so a
## ward in the wrong place is refused where it is authored rather than silently
## never read.
static func worn_on(wound: Enums.Wound) -> Enums.Slot:
	match wound:
		Enums.Wound.CONCUSSED:
			return Enums.Slot.HEAD
		Enums.Wound.BROKEN_ARM:
			return Enums.Slot.ARMS
	return Enums.Slot.NONE


func kind() -> String:
	return "ward"


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if worn_on(wards) == Enums.Slot.NONE:
		problems.append("nothing is worn where %s lands — a binding treats it, "
			% Enums.Wound.keys()[wards] + "and no piece of armour does")
	return problems
