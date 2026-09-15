class_name AttackResource
extends Resource

## One blow an enemy can deal (`M4-T02`, `TEC-006`, ADR-231).
##
## Values only. `Enemy` reads the phases and `Hitbox` carries the blow; nothing
## here decides when to swing. Seconds rather than `TEC-006`'s milliseconds,
## because every other phase in the project — a weapon's windup, a Waystone's
## channel — is seconds, and one unit is one thing to get wrong instead of two.
##
## **The telegraph floor lives here now** (ADR-053, `DES-009`). *No enemy attack
## telegraphs under 250 ms* was enforced on the one `TuningProfile` number while
## there was one enemy; with a roster the rule has to be asked of every attack,
## where the data actually is, or the second archetype is the one that breaks it.

## The wind-up a player reads ⟨tune⟩. Refused below `TuningProfile.TELEGRAPH_FLOOR`.
@export var telegraph: float = 0.5
## How long the blow can land ⟨tune⟩.
@export var active: float = 0.12
## The committed stretch after it, where a hit always staggers (`M4-T16`) ⟨tune⟩.
@export var recovery: float = 0.45
## What it deals before armour ⟨tune⟩.
@export var damage: float = 34.0
## What it deals it as, for `DES-009`'s triangle against a player's coat.
@export var damage_type: Enums.DamageType = Enums.DamageType.CUT
## How close a target has to be for the enemy to start it ⟨tune⟩.
@export var reach: float = 2.2
## **A heavy blow goes through a weapon's guard** (`DES-023` §3, ADR-232). A
## raised seax takes the edge off a Wretch's cut and nothing off a Hall-Warden's
## overhead; what stops a heavy blow is a shield, which is `M4-T03`'s. Carried
## to the player on the hitbox, beside the damage and its type.
@export var heavy: bool = false
## **A missile, thrown at this speed** (ADR-235), in metres per second, or `0`
## for a blow within `reach`. A missile is thrown only at a body the thrower can
## see this instant, from as far as `reach`, and flies no further than `reach`:
## straight, dodgeable, stopped by a wall and by the first body in the way.
## `DES-023` §3: it goes through a weapon's guard and stops on a shield ⟨tune⟩.
@export var missile_speed: float = 0.0


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if telegraph < TuningProfile.TELEGRAPH_FLOOR:
		problems.append(("telegraph %.3f s is below the %.2f s floor — a blow nobody "
			+ "can react to is a death nobody can explain (ADR-053, `DES-009`)")
			% [telegraph, TuningProfile.TELEGRAPH_FLOOR])
	if active <= 0.0:
		problems.append("active %.3f s lands on nothing" % active)
	if recovery < 0.0:
		problems.append("recovery cannot be negative")
	if damage <= 0.0:
		problems.append("an attack that deals %.1f is a gesture" % damage)
	if reach <= 0.0:
		problems.append("an attack with no reach can never begin")
	if missile_speed < 0.0:
		problems.append("a missile thrown at %.1f m/s flies backwards" % missile_speed)
	return problems
