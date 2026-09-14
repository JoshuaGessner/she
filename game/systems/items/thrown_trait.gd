class_name ThrownTrait
extends ItemTrait

## **The one thrown thing that wounds** (`M4-T31`, `DES-023`, ADR-227).
##
## `DES-009` makes throw a verb for everything: a coin is bait, a plate is a
## panic dump, and neither hurts what it lands on. This trait is what makes a
## throw a blow as well. Only `wpn_bearded_axe` carries it, and the price is the
## weapon — it lies where it landed, and it rings when it hits, so the throw
## tells the floor where you just were and leaves your hand empty.
##
## The reference is the francisca, and *Kingdom Come: Deliverance*'s thrown
## weapons: a real answer at range that costs you the thing in your hand. What
## differs here is the ring — `DES-005` makes every consequence audible, and an
## axe into wood or a body is not a quiet thing.
##
## Values only, like every trait: `WorldItem` flies it, `Hurtbox` resolves it.

## What it lands as, before armour ⟨tune⟩. Above its swing: a throw commits the
## whole weapon, and a blow that cost the axe and hit softer than keeping it
## would be a verb nobody should use.
@export var damage: float = 26.0

## A thrown axe is a cut, and meets `DES-009`'s triangle like any other.
@export var damage_type: Enums.DamageType = Enums.DamageType.CUT

## Metres a second from the hand, along the aim ⟨tune⟩. Faster than a dropped
## purse's 11, slower than an arrow's 34: it arcs, it can be walked out of, and
## it is not a second bow.
@export var speed: float = 16.0

## Clamor where it strikes or lands ⟨tune⟩, on `TuningProfile`'s scale. Beside
## an arrow's 3.2: the ring is heard where the axe is, not where you are.
@export var clamor_hit: float = 3.4


func kind() -> String:
	return "thrown"


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if damage <= 0.0:
		problems.append(("damage must be above zero — a thrown weapon that wounds "
			+ "nothing is a dropped one, and every item can already be dropped"))
	if speed <= 0.0:
		problems.append("speed must be above zero")
	if clamor_hit <= 0.0:
		problems.append(("clamor_hit must be above zero — `DES-023` prices the "
			+ "throw with the ring, and a silent one is free"))
	return problems
