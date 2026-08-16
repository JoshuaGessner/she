class_name ClamorSource
extends Node

## How much noise this actor is making, right now (`M1-T04`, DES-005 Layer 1).
##
## Clamor is deposited by actions and decays continuously. The level maps to an
## **audible radius**, which DES-005 Layer 1 names directly: *"Clamor → wider
## aggro radius"*. That is the mechanic here.
##
## **Not the Clamor field.** TEC-001's decaying scalar grid — the one the
## Gullsjúkr navigates by gradient — is `M2-T02`, and is absent rather than
## approximated. These are two different consumers of the same fiction and both
## exist in the finished game: this one answers "can that enemy over there hear
## me", the field answers "where in the level was noise recently". Building the
## radius now is not a cheaper stand-in for the grid.
##
## Weight feeds straight into this. DES-005 Layer 1 again: *"You feel your greed
## in your legs"* — and in how far the sound of you carries.

signal made_noise(amount: float, level: float)

var level: float = 0.0


func _process(delta: float) -> void:
	if level <= 0.0:
		return
	# Linear decay, not exponential: a decay curve with a long tail leaves a
	# faint level hanging around forever, and "am I quiet yet?" has to have a
	# definite answer the player can act on (DES-005 requirement 1).
	level = maxf(0.0, level - Config.tuning.clamor_decay * delta)


func add(amount: float) -> void:
	if amount <= 0.0:
		return
	level = minf(Config.tuning.clamor_maximum, level + amount)
	made_noise.emit(amount, level)


## Metres at which this actor can currently be heard.
func audible_radius() -> float:
	return level * Config.tuning.clamor_metres_per_unit


func silence() -> void:
	level = 0.0
