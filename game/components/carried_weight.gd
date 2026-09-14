class_name CarriedWeight
extends Node

## What the player is hauling, in kilograms, and the 0..1 encumbrance derived
## from it. DES-005 Layer 1: weight is continuous, player-caused pressure —
## your own greed, expressed as something your legs have to carry.
##
## Set by the body, on the host, from **the bag and what the body wears and
## holds** (ADR-224). Until then only the bag counted, so an 11 kg byrnie on
## your back weighed nothing, and so did a two-handed hammer in your hands.

signal changed(kilograms: float, encumbrance: float)

var kilograms: float = 0.0:
	set(value):
		var clamped: float = maxf(0.0, value)
		if is_equal_approx(clamped, kilograms):
			return
		kilograms = clamped
		changed.emit(kilograms, encumbrance())

## **The class's `carry_scale`, pushed down by the body** (ADR-224). Above 1.0
## the same kilograms land lighter: `DES-011`'s Húskarl *"keeps moving under
## weight that would pin anyone else"*. Authored at `M3-T02` and read by
## nothing, so every class hauled against the same 40 kg.
var class_scale: float = 1.0:
	set(value):
		if is_equal_approx(value, class_scale):
			return
		class_scale = value
		changed.emit(kilograms, encumbrance())


func capacity() -> float:
	return Config.tuning.carry_capacity * class_scale


## 0.0 empty-handed, 1.0 at capacity. Deliberately clamped rather than allowed
## past 1.0: DES-005 wants weight to bite hard, not to make movement impossible
## and turn a bad decision into an unrecoverable one.
func encumbrance() -> float:
	var cap: float = capacity()
	return clampf(kilograms / cap, 0.0, 1.0) if cap > 0.0 else 0.0


## Interpolate a multiplier from its unencumbered value (1.0) to its value at
## full load. One helper so every consumer scales identically — DES-009 asks
## for weight to be "one number the player can feel", which only holds if the
## effects move together.
func scale_by_load(at_capacity: float) -> float:
	return lerpf(1.0, at_capacity, encumbrance())
