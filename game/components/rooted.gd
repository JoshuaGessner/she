class_name Rooted
extends Node

## Held in place (`M3-T11`, `DES-011`, ADR-123).
##
## The Veiðimaðr's verb is **Snare**: *"place traps that hold, wound, or
## misdirect — including against the Hunter, the only reliable way to buy time
## during the Sealing."* Holding is the half that ships (ADR-123), and this is
## the state a held thing is in.
##
## ## Why a component rather than a flag on each body
##
## `Enemy` and `Gullsjukr` do not share a base class and never should — one is a
## brain with a navigation agent and the other navigates a noise field. But
## *"can this thing move right now"* has to mean exactly the same thing for
## both, or the Snare works on the ordinary enemies it is a convenience against
## and fails on the Hunter it is the whole point of. `CLAUDE.md` prefers a
## `Health` node over a base class for this reason; the same argument applies
## here with the extra force that there are two unrelated movers.
##
## ## The visual twin is the trap, not the body
##
## `DES-018` wants every channel to have one, and a body that simply halts is
## indistinguishable from a body that is stuck. What answers that is the
## `Snare`'s own sprung ring, which is a spawned actor and therefore visible to
## everybody — so this component carries no signals for a body to dress itself
## with. It had two, `took_hold` and `let_go`, and nothing connected either:
## names that work and that nothing reaches are exactly what ADR-098 is about.
##
## ## It roots movement, not action
##
## A held enemy still swings at whatever is already in reach. *Hold* is about
## going somewhere: what the Stalker buys is that nothing **follows**. A trap
## that also disarmed would be a stun, and a stun that costs one placement is
## the kind of no-counter-play answer `PRO-005` §5 rules out — the held thing
## is visibly still dangerous, it simply cannot come to you.
##
## ## Host-only in practice, harmless everywhere
##
## `TEC-004` gives consequences one owner, so only the host ever calls
## `hold_for`. The clock runs on every peer because a float decrement costs
## nothing and a gate on `is_server()` in a component that does not know what it
## is attached to is a branch waiting to be wrong. On a client it counts down
## from zero forever, which is the correct amount of nothing: a client's copy of
## an enemy is moved by the synchroniser, so a held one stops moving there
## because the transform it is being sent stops changing.

var _left: float = 0.0


func _physics_process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta
	if _left <= 0.0:
		_left = 0.0


## Hold for at least this long. Deliberately `maxf` rather than additive: two
## snares in a doorway should not stack into a permanent hold, which is the
## shape every "stun-lock" complaint in every game with a stun has.
func hold_for(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_left = maxf(_left, seconds)


func held() -> bool:
	return _left > 0.0


## Let go early. Called when a body dies: a corpse is not being held in place by
## a trap, it is dead, and a state that can only ever be entered is the shape of
## the bug where a dead thing is still being held by a trap that no longer
## exists.
func release() -> void:
	_left = 0.0
