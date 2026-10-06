class_name CarrySway
extends RefCounted
## **What you hold is held by someone breathing** (ADR-309) — first person only.
##
## The weapon and the off hand stood in front of the camera dead still: at rest
## the frame was a photograph of a sword, and walking it glided as if on a
## rail. Every first-person game since *Thief* moves what the hands hold, and
## the reason is not decoration — a still view reads as paused, and a weapon
## that keeps time with your feet is how a body is felt from inside it.
##
## **The camera does not move.** `Player` has no head bob, on purpose (Swink's
## ordering, `DES-009`), and this does not add one: only what is carried moves,
## which is also the half of view motion that does not make people sick. It is
## scaled by `Settings.camera_motion`, the accessibility slider for every
## motion of the view (ADR-279), so at 0 the hands are still again.
##
## **Driven by distance, like the body's gait** (`BodyRig`): a step comes with
## each `STRIDE_METRES` / 2 travelled, so the dip lands on the footfall a
## teammate sees, at any speed. Standing, the hands breathe instead, at the
## rhythm the body breathes.
##
## The weapon's **model** is moved, never its node: the swing's hitbox hangs off
## that node, and a reach that changed with your breathing would be a reach
## nobody could learn.

## Breaths a second, and how far one lifts and tips what is held at rest ⟨tune⟩.
const BREATH_HZ: float = BodyRig.BREATH_HZ
const BREATH_LIFT: float = 0.004
const BREATH_PITCH: float = 0.5
## A step's dip under the footfall, its sway to that side, and its roll, at full
## walking gait — metres and degrees ⟨tune⟩.
const STEP_DIP: float = 0.011
const STEP_SWAY: float = 0.008
const STEP_ROLL: float = 1.0
## Crouched, a step is shorter and the hands are held closer ⟨tune⟩.
const CROUCH_DAMP: float = 0.5

## ## A blow goes through the arms (ADR-335)
##
## `DES-009` §2: *"in first person the hands and weapon carry the impact, not the
## camera. The arm animation absorbing a blow does more than any shake, and
## costs no comfort."* ADR-279 built the camera's half — a positional kick —
## and the arms rode along with it, so nothing in view ever **took** a blow:
## the whole frame moved, and the sword in it stayed exactly where it was
## relative to your eye. A jolt is the missing half: what is carried is
## knocked off its pose and springs back, a little under-damped, so it rings
## once like an arm catching a weight. *Dark Souls* and *Chivalry* both sell a
## blocked hit almost entirely this way — the shield driven back at you —
## with the camera barely moving.
##
## Scaled by `camera_motion` with the rest of this class. At 0 the hands are
## still, and the blow is still heard and still marks the vignette.
##
## Spring stiffness (1/s²) and damping ratio — under 1, so it overshoots once ⟨tune⟩.
const JOLT_STIFFNESS: float = 260.0
const JOLT_DAMPING: float = 0.55
## The furthest a flurry may knock what is held, metres and degrees ⟨tune⟩.
const JOLT_MAX_OFFSET: float = 0.09
const JOLT_MAX_TURN: float = 14.0

var _breath: float = 0.0
var _stride: float = 0.0
var _gait: float = 0.0
## The jolt: displacement and velocity of position, and of turn in degrees.
var _shift: Vector3 = Vector3.ZERO
var _shift_speed: Vector3 = Vector3.ZERO
var _tip: Vector3 = Vector3.ZERO
var _tip_speed: Vector3 = Vector3.ZERO


## Knock what is held so that, left alone, it swings out about `offset` metres
## and `turn` degrees before springing back. Accumulates, and is capped.
func jolt(offset: Vector3, turn: Vector3) -> void:
	# At this damping an impulse v peaks near 0.45 v / ω at the frame rate the
	# spring is stepped in (0.52 in the continuous limit), so reaching `offset`
	# takes 2.2 ω. At 1.9 a 0.020 m jolt measured 0.0172 m at 60 Hz.
	var omega: float = sqrt(JOLT_STIFFNESS)
	_shift_speed += offset * omega * 2.2
	_tip_speed += turn * omega * 2.2


## How far a jolt has knocked what is held right now — for `--feel-probe`.
func jolted() -> float:
	return _shift.length()


func _settle(delta: float) -> void:
	var damping: float = 2.0 * JOLT_DAMPING * sqrt(JOLT_STIFFNESS)
	# Small fixed steps: a hitch in the frame rate must not launch the spring.
	var left: float = minf(delta, 0.1)
	while left > 0.0:
		var dt: float = minf(left, 1.0 / 120.0)
		_shift_speed += (-JOLT_STIFFNESS * _shift - damping * _shift_speed) * dt
		_shift = (_shift + _shift_speed * dt).limit_length(JOLT_MAX_OFFSET)
		_tip_speed += (-JOLT_STIFFNESS * _tip - damping * _tip_speed) * dt
		_tip = (_tip + _tip_speed * dt).clamp(Vector3.ONE * -JOLT_MAX_TURN,
			Vector3.ONE * JOLT_MAX_TURN)
		left -= dt


## This frame's carry, from metres `travelled` since the last, the speed as a
## fraction of walking, and whether the feet are on anything.
func step(delta: float, travelled: float, of_walking: float, grounded: bool,
		crouched: float, scale: float) -> Transform3D:
	_breath = fposmod(_breath + delta * BREATH_HZ, 1.0)
	_stride = fposmod(_stride + travelled / BodyRig.STRIDE_METRES, 1.0)
	var want: float = clampf(of_walking / BodyRig.FULL_GAIT_AT, 0.0, 1.0) if grounded else 0.0
	_gait = lerpf(_gait, want, clampf(delta * BodyRig.GAIT_EASE, 0.0, 1.0))
	var walk: float = _gait * (1.0 - crouched * CROUCH_DAMP)
	var still: float = 1.0 - _gait
	var stride: float = TAU * _stride
	var breath: float = TAU * _breath
	# Two footfalls a cycle: the dip at each, the sway once to either side.
	var offset := Vector3(sin(stride) * STEP_SWAY * walk,
		-absf(sin(stride)) * STEP_DIP * walk + sin(breath) * BREATH_LIFT * still, 0.0)
	var turn := Basis.from_euler(Vector3(deg_to_rad(sin(breath) * BREATH_PITCH * still),
		0.0, deg_to_rad(sin(stride) * STEP_ROLL * walk)))
	_settle(delta)
	offset += _shift
	turn = turn * Basis.from_euler(Vector3(deg_to_rad(_tip.x), deg_to_rad(_tip.y),
		deg_to_rad(_tip.z)))
	var amount: float = clampf(scale, 0.0, 1.0)
	return Transform3D(Basis.IDENTITY.slerp(turn, amount), offset * amount)
