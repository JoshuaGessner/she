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

signal swing_started
signal connected(hurtbox: Hurtbox)
enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

## Blockout poses, as (position, rotation-in-degrees). Not juice: without a
## visible weapon the player cannot see wind-up, strike or recovery at all, and
## the whole point of DES-009's attack anatomy is that those phases are
## *readable*. This is the primary representation of the mechanic — the polish
## layer is the arm absorbing impact and the camera kick, both still absent.
##
## Straight lerps, no easing curves and no anticipation overshoot, for the same
## reason: an eased swing would flatter the timings being judged.
const POSE_REST: Array = [Vector3(0.42, -0.34, -0.62), Vector3(6, -12, -22)]
const POSE_RAISED: Array = [Vector3(0.52, -0.02, -0.44), Vector3(-38, 28, -58)]
const POSE_STRUCK: Array = [Vector3(-0.34, -0.30, -0.72), Vector3(14, -34, 40)]

var _phase: Phase = Phase.IDLE
var _remaining: float = 0.0
var _duration: float = 0.0
var _buffered_until: float = -1.0

@onready var _hitbox: Hitbox = $Hitbox
@onready var _model: Node3D = $Model


func _ready() -> void:
	var tuning: TuningProfile = Config.tuning
	_hitbox.damage = tuning.swing_damage
	_hitbox.struck.connect(_on_struck)
	_pose(POSE_REST, POSE_REST, 0.0)


func _pose(from: Array, to: Array, t: float) -> void:
	_model.position = (from[0] as Vector3).lerp(to[0] as Vector3, t)
	_model.rotation = Vector3(
		deg_to_rad(lerpf((from[1] as Vector3).x, (to[1] as Vector3).x, t)),
		deg_to_rad(lerpf((from[1] as Vector3).y, (to[1] as Vector3).y, t)),
		deg_to_rad(lerpf((from[1] as Vector3).z, (to[1] as Vector3).z, t))
	)


func _update_pose() -> void:
	# How far through the current phase we are, 0 at its start and 1 at its end.
	var t: float = 1.0 - clampf(_remaining / maxf(_duration, 0.0001), 0.0, 1.0)
	match _phase:
		Phase.WINDUP:
			_pose(POSE_REST, POSE_RAISED, t)
		Phase.ACTIVE:
			_pose(POSE_RAISED, POSE_STRUCK, t)
		Phase.RECOVERY:
			_pose(POSE_STRUCK, POSE_REST, t)
		Phase.IDLE:
			_pose(POSE_REST, POSE_REST, 0.0)


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
		return false
	begin_owned_swing()
	return true


## Start a swing whose cost has already been paid, on another peer's machine
## (`M1-T05`, ADR-082).
##
## Every peer runs this phase machine: the owner because they asked for the
## swing, the host because its copy's hitbox is the only one allowed to decide
## that something was hurt, and everyone else so a teammate visibly swings
## rather than gliding with a still weapon.
##
## It does not consult stamina, and that is the point rather than an oversight.
## Stamina was spent on the owner's machine; a remote copy has been drained by
## nothing, so charging it again would sometimes *refuse* — on the host — a
## swing that legitimately happened, and the symptom would be hits that
## occasionally do not land for no visible reason.
func begin_owned_swing() -> void:
	if _phase != Phase.IDLE:
		return
	_enter(Phase.WINDUP, Config.tuning.swing_windup)
	swing_started.emit()
	Foley.at(self, Foley.Sound.SWING, randf_range(0.94, 1.08))


func _enter(next: Phase, duration: float) -> void:
	_phase = next
	_remaining = duration
	_duration = duration
	if next == Phase.ACTIVE:
		_hitbox.arm()
	else:
		_hitbox.disarm()
	_update_pose()


func advance(delta: float, stamina: Stamina) -> void:
	if _phase == Phase.IDLE:
		return
	var tuning: TuningProfile = Config.tuning
	_remaining -= delta
	_update_pose()
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
