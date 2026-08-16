class_name Stamina
extends Node

## Stamina as a component, not a field on the player (TEC-001: composition).
## DES-009 has it governing swinging, blocking, sprinting and climbing — four
## consumers across three future systems — so it belongs on its own node from
## the start rather than being extracted later.
##
## Signals up, calls down: an owner *calls* spend() and drain(); this node
## never reaches upward and only reports through signals.

signal emptied
signal replenished

var current: float = 0.0
var _since_spend: float = 0.0
var _was_empty: bool = false


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
	_check_edges()
	return true


## Continuous drain, for things held down rather than triggered. Returns false
## once there is nothing left to take.
func drain(rate: float, delta: float) -> bool:
	if current <= 0.0:
		return false
	current = maxf(0.0, current - rate * delta)
	_since_spend = 0.0
	_check_edges()
	return true


func refill() -> void:
	current = maximum()
	_check_edges()


func _process(delta: float) -> void:
	_since_spend += delta
	var tuning: TuningProfile = Config.tuning
	# The delay is what makes stamina a resource rather than a formality: with
	# instant regeneration, sprinting in short bursts costs nothing.
	if _since_spend < tuning.stamina_regen_delay or current >= tuning.stamina_max:
		return
	current = minf(tuning.stamina_max, current + tuning.stamina_regen * delta)
	_check_edges()


func _check_edges() -> void:
	var empty: bool = current <= 0.0
	if empty and not _was_empty:
		emptied.emit()
	elif not empty and _was_empty:
		replenished.emit()
	_was_empty = empty
