class_name LightTrait
extends ItemTrait

## An item that gives light, and gives you away (`M4-T13`, `ART-001`, `DES-008`).
##
## > *"A lantern is a weapon slot you gave up to see."* — `DES-008`
##
## `TEC-006` named this trait among the seven and `ART-001` has been explicit
## since the design lock that **darkness is a mechanic, not an effect**. Nothing
## built it, in any milestone, which left `room_set.gd`'s ambient energy propped
## up at a navigable 0.34 with a comment saying it *"drops when the lantern
## lands"* — because a dark level with no light source is a bug rather than a
## mechanic.
##
## ## Two numbers, pulling opposite ways
##
## `radius` is what you get. `glare` is what it costs. They are deliberately
## **not** the same number and the design lives in the gap between them: the
## lantern advertises you further than it lets you see (`Exposure`,
## `TuningProfile.enemy_vision_range`), so walking lit is walking into rooms
## that saw you arrive.
##
## ## What this trait does not carry, and why
##
## `TEC-006`'s row reads *"radius, colour, fuel, whether it can be dropped
## lit."* **Neither of the last two is built** — absent rather than stubbed
## (ADR-064), both argued in ADR-188:
##
## - **No fuel.** `DES-022` requires power to cost *risk*, not time, and
##   `DES-005` deliberately refuses a hard timer. A burn-down clock is a second
##   pressure running beside the Hunt, competing with it for the one channel
##   `DES-019` reserves for urgency. What stops *"lantern always on"* is the
##   shutter and the glare, not an oil meter.
## - **No dropping it lit.** A lantern left burning in a doorway is a decoy, and
##   a decoy is only interesting once something navigates light. Nothing does:
##   the Gullsjúkr reads clamor. It becomes buildable when it becomes a
##   decision, and not before.

## Metres the light reaches. Read by `Lantern` for the `OmniLight3D`, and the
## number `ART-001`'s *"silhouette at 20 m"* has to be argued against — see
## ADR-188, which lands the argument on `ART-005`'s always-outlined enemies
## rather than on making the lantern reach further than the thing hunting you.
@export var radius: float = 11.0  # ⟨tune⟩

## Brightness of the flame itself.
@export var energy: float = 1.7  # ⟨tune⟩

## **Pale bone-white, and it was gold until `--sight-probe` refused it.**
##
## The first version read `ART-005`'s *"gold / warm amber — treasure, your
## ember, her fire"* and filed a lantern under *fire*. The check caught it, and
## the check is right for a reason bigger than the letter of the rule: **a
## lantern lights the whole room.** A warm sconce tints one corner; a warm
## lantern tints *everything you can see, everywhere you go*, and gold is the
## one hue this game spends on what will get you killed. Carrying a gold light
## would say **valuable** about every wall in the Delvings and quietly cost the
## palette the only job it has.
##
## `ART-005` had already answered it in the sentence this whole item exists to
## serve — the Deep is *"pale bone-white ink, appearing only in lantern reach"*.
## The lamp is the thing doing the drawing, so it is the colour of the ink.
##
## Kept clear of `RoomSet.GOLD_MARGIN` rather than tuned up against it: warmer
## than the cold `PALE` of a doorway lamp, so a carried light still reads as a
## different kind of thing, and nowhere near the treasure budget.
@export var colour: Color = Color(0.91, 0.90, 0.89)

## How lit you are while this burns, on `Exposure`'s 0–1 scale. **1.0 means a
## lit lantern is total exposure**, which is the honest reading of `DES-009`:
## *"carrying a lantern makes you visible."* A dimmer light would be a lantern
## with a stealth discount, and the discount is what the shutter is for.
@export var glare: float = 1.0  # ⟨tune⟩

## Seconds to open or close the shutter. **Short by design, and not a swap.**
## ADR-057 made off-hand *swapping* slow and interruptible so a shield and a
## light cannot both be carried; shuttering changes what the held thing is
## doing, not which thing is held, and it buys darkness rather than a shield.
## Long enough to be a commitment, short enough to be a reflex you can regret.
@export var shutter_seconds: float = 0.25  # ⟨tune⟩


func kind() -> String:
	return "light"


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if radius <= 0.0:
		problems.append("a light with a %.1f m radius lights nothing" % radius)
	if energy <= 0.0:
		problems.append("a light with %.1f energy is an unlit lamp" % energy)
	# The gap between seeing and being seen is the mechanic. A light that cost
	# nothing would be a graphics setting, and `ART-001` calls that out by name.
	if glare <= 0.0:
		problems.append("a light with no glare is free to carry — `ART-001` "
			+ "makes light a resource you manage, and a resource with no price "
			+ "is an effect")
	if shutter_seconds < 0.0:
		problems.append("a shutter cannot take %.2f s" % shutter_seconds)
	return problems
