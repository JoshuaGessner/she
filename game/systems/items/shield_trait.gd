class_name ShieldTrait
extends ItemTrait

## **Stops what a weapon's guard cannot** (`M4-T03`, ADR-238, `DES-023` §3).
##
## A raised weapon takes a share off an ordinary blow and nothing off a heavy
## blow or anything in the air (ADR-232, ADR-235). A raised shield takes the same
## share off all three, from the front: the Hall-Warden's overhead and the
## Sling-Wretch's stone are what it is for. `DES-011`: *"a shield that blocks what
## others must avoid."*
##
## **The same share, not a bigger one**, by the developer's call over stopping
## them outright. `DES-009`'s guard reduces and never negates, and `TuningProfile`
## refuses a guard that stops a whole blow; a shield that did would make a full
## stamina bar briefly immune to the Warden, which is the holding contest
## `M3-T02` designed out. The capability is what it can guard, not how much.
##
## Its price is where it lives: the off hand, which the lantern wants, so a body
## with a shield up is a body in the dark (`DES-020`). Swapping one for the other
## goes through the bag, which is slow and interruptible (ADR-057).
##
## No fields. What a shield does is that it is one; a number here would be a
## better shield, which is `DES-008`'s stat ladder.


func kind() -> String:
	return "shield"


func validate() -> PackedStringArray:
	return PackedStringArray()
