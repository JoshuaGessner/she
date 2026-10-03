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

var _breath: float = 0.0
var _stride: float = 0.0
var _gait: float = 0.0


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
	var amount: float = clampf(scale, 0.0, 1.0)
	return Transform3D(Basis.IDENTITY.slerp(turn, amount), offset * amount)
