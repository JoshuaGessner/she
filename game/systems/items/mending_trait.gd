class_name MendingTrait
extends ItemTrait

## Closes a wound, slowly (`M4-T32`, `DES-023`, ADR-221).
##
## `DES-009`: *"health does not regenerate; healing is scarce and slow to
## apply."* Scarce is the loot table's job. **Slow is this trait's**, and slow is
## the design rather than a delay in front of it: four seconds of standing in a
## corridor tying linen, broken by a blow or a sprint, is a decision about *where
## you are safe* — which is the question the floor keeps asking. An instant heal
## is a potion, and a potion turns *"I'm at 40% and out of bandages"* from a
## reason to leave into a key to press mid-fight.
##
## `TEC-006` sketched one `ConsumableTrait` with an effect tag. Built as two
## traits instead, one per effect, because a tag is a string a system switches
## on while the numbers for every effect share one resource — and a binding with
## a hush radius on it is the field-nothing-reads ADR-064 bans.
##
## The reference is *Escape from Tarkov*'s medical items: a timed use you can walk
## through and lose to a sprint. What differs here is that nothing tops you up
## between floors, so the binding is the only answer there is.

## Seconds of tying ⟨tune⟩. Consumed only when it finishes: a binding broken
## halfway costs the time and the danger, and stays in the bag.
@export var seconds: float = 4.0

## Share of the body's maximum health restored ⟨tune⟩. A share rather than hit
## points so a Húskarl's larger pool is mended in the same proportion, and 0.35
## is about one enemy blow on an unarmoured body — *a binding undoes a hit* is
## the sentence a player can hold.
@export var restores: float = 0.35


func kind() -> String:
	return "mending"


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if seconds <= 0.0:
		problems.append(("seconds must be above zero — `DES-009` makes healing "
			+ "slow to apply, and an instant one is a potion"))
	if restores <= 0.0 or restores > 1.0:
		problems.append("restores is %.2f; a share of maximum health sits in (0, 1]"
			% restores)
	return problems
