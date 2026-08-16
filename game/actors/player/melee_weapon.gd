class_name MeleeWeapon
extends Node3D

## The one weapon (`M1-T02`). Wind-up → swing → recovery, and it commits.
##
## **Unjuiced, per DES-009's M1 protocol step 1.** No hitstop, no impact sound,
## no camera kick, no particles. The protocol is explicit that those are added
## *afterwards, one at a time, measuring each* — and that if swinging does not
## feel decent without them, the fix is the control, not the feedback. Every
## one of those layers is absent rather than stubbed (ADR-064).
##
## What is here that might look like polish but is not: **input buffering**.
## DES-009 §4 lists it under Forgiveness, and is blunt about why — without it a
## committal system reads as *unresponsive* rather than *weighty*. It is part
## of the control layer, not the polish layer.
##
## Also deliberately absent: the heavy attack, block, shove and throw. One
## attack built completely answers the gate question — "does a tester
## voluntarily swing at something they could have walked past?" — and four
## verbs built partly does not.

signal phase_changed(phase: Phase)
signal swing_started
signal connected(hurtbox: Hurtbox)
signal refused(reason: String)

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

var _phase: Phase = Phase.IDLE
var _remaining: float = 0.0
var _buffered_until: float = -1.0

@onready var _hitbox: Hitbox = $Hitbox


func _ready() -> void:
	var tuning: TuningProfile = Config.tuning
	_hitbox.damage = tuning.swing_damage
	_hitbox.struck.connect(_on_struck)


func phase() -> Phase:
	return _phase


func is_busy() -> bool:
	return _phase != Phase.IDLE


## Called by the owner on input. Returns false if the swing was refused, which
## is not the same as being buffered — see `_buffered_until`.
func request_swing(stamina: Stamina) -> bool:
	var tuning: TuningProfile = Config.tuning
	if _phase == Phase.IDLE:
		return _begin(stamina, tuning)
	# A press during recovery is remembered and fires on the first legal frame.
	# Buffering during wind-up or the active frames would queue a second swing
	# before the first has resolved, which reads as the input being swallowed.
	if _phase == Phase.RECOVERY:
		_buffered_until = _remaining + tuning.swing_buffer_window
	return false


func _begin(stamina: Stamina, tuning: TuningProfile) -> bool:
	if not stamina.spend(tuning.swing_stamina_cost):
		refused.emit("stamina")
		return false
	_enter(Phase.WINDUP, tuning.swing_windup)
	swing_started.emit()
	return true


func _enter(next: Phase, duration: float) -> void:
	_phase = next
	_remaining = duration
	if next == Phase.ACTIVE:
		_hitbox.arm()
	else:
		_hitbox.disarm()
	phase_changed.emit(next)


func advance(delta: float, stamina: Stamina) -> void:
	if _phase == Phase.IDLE:
		return
	var tuning: TuningProfile = Config.tuning
	_remaining -= delta
	if _remaining > 0.0:
		return

	match _phase:
		Phase.WINDUP:
			_enter(Phase.ACTIVE, tuning.swing_active)
		Phase.ACTIVE:
			_enter(Phase.RECOVERY, tuning.swing_recovery)
		Phase.RECOVERY:
			_enter(Phase.IDLE, 0.0)
			# Spend the buffered press, if one is still live. `_remaining` is
			# now zero or negative, so the window is measured against how far
			# past the end of recovery we are.
			if _buffered_until > 0.0 and _buffered_until + _remaining > 0.0:
				_buffered_until = -1.0
				_begin(stamina, tuning)
			else:
				_buffered_until = -1.0
		Phase.IDLE:
			pass


func _on_struck(hurtbox: Hurtbox) -> void:
	connected.emit(hurtbox)
