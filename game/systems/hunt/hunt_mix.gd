class_name HuntMix
extends RefCounted

## What the game is currently telling you about trouble (`M2-T03`, `DES-018`).
##
## **One computation, two renderers.** This is the mechanism behind ADR-036's
## rule that *every channel has a twin*: `AudioDirector` computes this object
## once per frame, then the score reads it and the **Ear** reads the same
## object. They cannot disagree, because there is nothing for them to disagree
## about — a mix state that exists in the audio and not on screen would have to
## be a field nobody renders, and `--ear-probe` fails on exactly that.
##
## `DES-018` is blunt about why this had to be structural rather than a habit:
##
## > *"A visual language for Clamor cannot be bolted on at the end, because by
## > then every system will assume the mix is carrying the information and
## > there will be nowhere for it to attach."*
##
## ## The channels, and why these four
##
## Each is a **continuous** scalar rather than a threshold, because `DES-018`
## requires the readout to show gradations matching the mix — and because
## `DES-005` requires pressure to degrade your options continuously rather than
## firing at a line.
##
## | Channel | Is | Audio | The Ear |
## |---|---|---|---|
## | `clamor` | how loud **you** are | drone tightening, pulse entering | the **core** |
## | `alert` | how much the **world** has noticed | heartbeat under the pulse | the **ring's character** |
## | `hunter` | how present the Gullsjúkr is | the reserved instrument | the **heavy mark** |
## | `bearing` | **where** attention is coming from | stereo position | the lit **arc** |
##
## `DES-019` splits these the same way and for the same reason: *cause on the
## inside, effect on the outside.* `clamor` is the only one that is about you,
## and it is the only one drawn in the middle.
##
## **The ambient bed is deliberately not a channel.** Air, distant water, stone
## settling — `ART-002` makes silence the default and the bed carries no state,
## so it has nothing to twin. ADR-036 governs what the audio *tells you*; a
## constant is not telling you anything. That exemption is narrow and written
## down so it cannot quietly widen.

## Every field the Ear is required to render. `--ear-probe` compares this
## against what the Ear declares it draws, in both directions, so adding a mix
## channel without a visual twin fails the build rather than shipping a run
## that is only playable with headphones on.
const CHANNELS: Array[String] = ["clamor", "alert", "hunter", "bearing"]

## 0..1, how loud you are right now — `ClamorSource.level` against the ceiling.
## **The single most important readout in the game** (`DES-018`), and the one
## that makes greed legible.
var clamor: float = 0.0

## 0..1, the loudest awareness any nearby actor currently has of anything.
## `DES-013`'s ladder, flattened to a scalar so it can be shown continuously —
## the discrete state is still what drives it, but a readout that jumped in
## four steps would be a threshold signal, which ADR-035 rejects.
var alert: float = 0.0

## 0..1, how present the Gullsjúkr is. Zero when it is not on the floor at all.
## This is the one channel permitted to make the whole element gain weight
## (`DES-019` rule 5).
var hunter: float = 0.0

## Radians in world space, or `NAN` when **nothing is attending to you**.
##
## NAN rather than zero, because zero is a direction. `DES-019`'s guardrail is
## that the Ear *"only shows attention that exists"* — an unaware room produces
## a blank ring however many enemies are standing in it — and a sentinel that
## is also a legal value is how that guarantee gets quietly lost.
var bearing: float = NAN

## True while the Gullsjúkr is stooped over thrown gold. `DES-018` makes this a
## **designed beat**: everything drops away, and the silence is the relief and
## the window. It is a modifier on the others rather than a channel of its own —
## what it does is *remove* signal.
var collecting: bool = false


func has_bearing() -> bool:
	return not is_nan(bearing)


## The heaviest thing currently happening, 0..1. Drives how much the whole Ear
## grows and how loud the score gets overall, so *"one element carries urgency"*
## (`DES-019` rule 5) is one number rather than three competing ones.
func pressure() -> float:
	return maxf(hunter, maxf(clamor, alert))
