class_name Stamina
extends Node

## **Second Wind** (`M3-T12`). Set by the body each frame rather than asked for:
## this component knows nothing about who holds it, and reaching up for a
## `Player` would be the child-into-parent call `CLAUDE.md` forbids. Same shape
## as `Inventory.weightless_materials` — the owner pushes what it knows down.
var breathing: bool = false

## Stamina as a component, not a field on the player (TEC-001: composition).
## DES-009 has it governing swinging, blocking, sprinting and climbing — four
## consumers across three future systems — so it belongs on its own node from
## the start rather than being extracted later.
##
## Calls down, and nothing up yet. It carried `emptied`/`replenished` edge
## signals that nothing ever connected to, so ADR-098 removed them along with
## the `_was_empty` bookkeeping that existed only to fire them. Owners poll
## `is_empty()` and `fraction()`, which is what they were already doing.

var current: float = 0.0
var _since_spend: float = 0.0


func _ready() -> void:
	current = Config.tuning.stamina_max


func maximum() -> float:
	return Config.tuning.stamina_max


func fraction() -> float:
	var cap: float = maximum()
	return current / cap if cap > 0.0 else 0.0


func is_empty() -> bool:
	return current <= 0.0


## True if the whole amount was available and has been taken.
func spend(amount: float) -> bool:
	if amount > current:
		return false
	current -= amount
	_since_spend = 0.0
	return true


## Continuous drain, for things held down rather than triggered. Returns false
## once there is nothing left to take.
func drain(rate: float, delta: float) -> bool:
	if current <= 0.0:
		return false
	current = maxf(0.0, current - rate * delta)
	_since_spend = 0.0
	return true


func refill() -> void:
	current = maximum()


func _process(delta: float) -> void:
	_since_spend += delta
	var tuning: TuningProfile = Config.tuning
	# The delay is what makes stamina a resource rather than a formality: with
	# instant regeneration, sprinting in short bursts costs nothing.
	# **Second Wind** (`M3-T12`). The delay is what makes stamina a rhythm; this
	# removes it *while standing still*, so the node buys a place to recover
	# rather than a bigger pool — and standing still is the most exposed thing
	# the Wing can ask you to do.
	if (not breathing and _since_spend < tuning.stamina_regen_delay) \
			or current >= tuning.stamina_max:
		return
	current = minf(tuning.stamina_max, current + tuning.stamina_regen * delta)


