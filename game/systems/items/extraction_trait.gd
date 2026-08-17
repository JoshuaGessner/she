class_name ExtractionTrait
extends ItemTrait

## A way out, carried (`M2-T04`, `TEC-006`, ADR-015).
##
## The second of `TEC-006`'s seven traits to be built, and it arrives now for
## the same reason `WieldableTrait` did: **its system exists.** `M2-T04` builds
## extraction, so a trait describing extraction behaviour finally has something
## reading it. The remaining five still describe systems that do not exist and
## stay absent rather than stubbed (ADR-064).
##
## ## Why the escape is loot
##
## ADR-015 turned extraction from a **routing** problem into a **resource**
## problem, and that is the whole design:
##
## > *"The means of escape becomes lootable — and choosing to spend it is
## > choosing to end the run early with what you have."*
##
## A Waystone in your bag is a decision you carry around. It occupies squares
## that could hold gold, which is `DES-019`'s two constraints doing exactly
## what they were built to do: **your way home competes with your reason for
## coming.**
##
## ## The cap is a UI decision as much as a balance one
##
## `DES-019` puts the Waystone indicator on the Burden layer and requires it to
## be *"binary and answerable in a glance: do I still have my way out?"* — one
## lit or unlit mark. That only works if you cannot hold two, which is why the
## cap is one (ADR-015, Q54) and why `Inventory` enforces it rather than
## trusting loot tables never to offer a second.

## How many of this item a bag may hold at once. One, for the Waystone, so the
## HUD mark can stay a single unambiguous light.
@export var carry_cap: int = 1

## Seconds of standing still to spend it ⟨tune⟩. `DES-005` calls the Waystone
## *"portable, instant, consumed"*, and instant is nearly right — but a
## momentous irreversible act on a single keypress is a misfire waiting to
## happen, so it costs a moment you can be interrupted in rather than a
## confirmation dialog `DES-019` would refuse anyway.
@export var channel_seconds: float = 1.1

## Noise made spending it. Tearing a hole home is not quiet, and it is the last
## thing you do — so it is loud enough to matter and too late to punish you
## much, which is the correct shape for a reward.
@export var clamor: float = 7.0


func kind() -> String:
	return "extraction"


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if carry_cap < 1:
		problems.append("carry_cap below 1 makes an item nobody can ever carry")
	if channel_seconds < 0.0:
		problems.append("channel_seconds cannot be negative")
	if clamor < 0.0:
		problems.append("clamor cannot be negative — a silent exit is `0.0`, not less")
	return problems
