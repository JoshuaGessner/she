class_name Health
extends Node

## Hit points, and the fact that they do not come back.
##
## DES-009 calls non-regenerating health "the most important single decision in
## this document after the thesis". Every point of damage is a permanent
## resource loss for the run, which turns damage taken into extraction pressure
## on its own — "I'm at 40% and out of bandages" is a reason to leave that needs
## no timer and no system. So there is deliberately no regeneration here, and
## adding any would need an ADR.
##
## Healing is a scarce consumable applied through `heal()` — the linen binding
## (`M4-T32`, `DES-023`), four seconds of tying that a blow or a sprint breaks.
## This header promised `heal()` from `M1` and the method was never written, so
## for three milestones the only way hit points went up was being picked up off
## the floor (ADR-221).

signal damaged(amount: float, remaining: float, from: Node)
signal died(from: Node)

@export var maximum: float = 100.0

var current: float = 0.0

var _dead: bool = false


func _ready() -> void:
	current = maximum


func is_dead() -> bool:
	return _dead


func fraction() -> float:
	return current / maximum if maximum > 0.0 else 0.0


func apply_damage(amount: float, from: Node = null) -> void:
	if _dead or amount <= 0.0:
		return
	current = maxf(0.0, current - amount)
	# Every peer plays its own from replicated state — `TEC-004` never
	# replicates sounds. The owner of the body hears it as *being hurt*;
	# everyone else hears a hit land, which is the same event from outside.
	var body := get_parent() as Node3D
	if body != null:
		Foley.at(body, Foley.Sound.HURT if body.is_multiplayer_authority()
			else Foley.Sound.HIT)
	damaged.emit(amount, current, from)
	if current <= 0.0:
		_dead = true
		died.emit(from)


## **The only way hit points go up inside a run** (`M4-T32`, `DES-009`).
##
## Refuses the dead, and that refusal is the method's whole reason for being
## separate from `revive()`: a binding that could raise the fallen would be a
## resurrection item nobody designed, and `DES-012` already prices getting up.
## Capped at `maximum` — a binding closes a wound, it does not store health.
func heal(amount: float) -> void:
	if _dead or amount <= 0.0:
		return
	current = minf(maximum, current + amount)


## Back on your feet, with `amount` hit points (`M2-T05`, `DES-012`).
##
## Separate from `heal()`, which deliberately refuses to work on the dead — and
## it has to stay refusing, because `DES-009`'s non-regenerating health is the
## document's second most important decision and a consumable that could raise
## the fallen would be a resurrection item nobody designed.
##
## This is the *revive*: a teammate's hand, or solo's one self-recovery. It
## does not undo the damage, it returns a fraction (`revive_health_fraction`) —
## `DES-012` charges a real cost for being picked up, and standing up at full
## health would make going down free.
func revive(amount: float) -> void:
	if amount <= 0.0:
		return
	_dead = false
	current = clampf(amount, 0.0, maximum)


## Dev-only, for the gym's reset. A run never does this.
func restore() -> void:
	_dead = false
	current = maximum
