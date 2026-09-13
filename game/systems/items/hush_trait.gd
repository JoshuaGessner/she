class_name HushTrait
extends ItemTrait

## A circle where nothing sounds, until it cracks (`M4-T32`, `DES-023`, ADR-221).
##
## `DES-023`: *"a circle, 6 m, where nothing makes a sound for 10 s — your steps,
## your swing, an enemy's shout to its kin, a coin you drop."* It works on the
## noise system that already exists rather than beside it: `ClamorSource.add`
## and `ClamorField.deposit` are where every sound enters the world, and both ask
## `Hush.silences` first.
##
## The reference is *Thief*'s moss arrow — silence laid on the floor, so the
## question is *where* rather than *when*. Moss was free once placed; this one
## has a price, because **the stave cracks when it ends**, one loud pulse at its
## centre. A circle laid in the doorway you are leaving through calls the floor
## to the place you just were, which is a mistake you can make and a bait you can
## choose.
##
## Values only, like every trait: `Hush` is the thing on the floor.

## Metres from the centre ⟨tune⟩. Three of ADR-054's 2 m modules — a room.
@export var radius: float = 6.0

## Seconds of silence ⟨tune⟩.
@export var seconds: float = 10.0

## Clamor of the crack ⟨tune⟩, on `TuningProfile`'s scale: above the Waystone's
## 7 and below an enemy's call to the floor at 12, so it is heard across rooms
## without being the loudest thing that can happen.
@export var crack: float = 10.0


func kind() -> String:
	return "hush"


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if radius <= 0.0:
		problems.append("radius must be above zero — a hush with no circle silences nothing")
	if seconds <= 0.0:
		problems.append("seconds must be above zero")
	if crack <= 0.0:
		problems.append(("crack must be above zero — `DES-023` prices the silence "
			+ "with the crack, and a hush that ends quietly is free"))
	return problems
