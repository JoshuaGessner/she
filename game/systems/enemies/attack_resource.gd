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

@export_group("Moveset")
## **The nearest it will start this blow from** (ADR-391), in metres. A lunge
## closes distance, so it starts only from where there is distance to close;
## nearer than this, the archetype's other blows are the ones in range ⟨tune⟩.
@export var min_range: float = 0.0
## Metres the blow carries the body forward over its active phase (ADR-391):
## a lunge. `0` for a blow struck where it stands ⟨tune⟩.
@export var lunge: float = 0.0
## Metres it pushes what it strikes back from the striker (ADR-391): the
## Hall-Warden's shove, a blocker making room for its overhead ⟨tune⟩.
@export var shove: float = 0.0
## **A wide blow** (ADR-391): its reach is swept round the striker's front and
## sides, so a body circling it is caught — the Hoard-Keeper's sweep. Narrow
## blows reach straight ahead.
@export var wide: bool = false
## Seconds before this blow may be chosen again after it is struck ⟨tune⟩.
@export var cooldown: float = 0.0
## The animation family it plays (ADR-391): `lunge` plays `lunge_telegraph`,
## `lunge_attack` and `lunge_recovery`. Empty plays the archetype's swing, so a
## second blow never looks like the first.
@export var clip: StringName = &""


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
	if min_range < 0.0 or min_range >= reach:
		problems.append(("starts from %.1f m and reaches %.1f m — no distance at which it "
			+ "could begin") % [min_range, reach])
	if lunge < 0.0 or shove < 0.0 or cooldown < 0.0:
		problems.append("a negative lunge, shove or cooldown")
	if missile_speed > 0.0 and (lunge > 0.0 or shove > 0.0 or wide):
		problems.append("a missile neither lunges, shoves nor sweeps — it leaves the hand")
	# A lunge's wind-up is read across the distance it closes (ADR-391), so it
	# has to be longer than the floor that covers a blow struck in place.
	if lunge > 0.0 and telegraph < TuningProfile.TELEGRAPH_FLOOR * 2.0:
		problems.append(("a lunge of %.1f m winds up in %.2f s — a blow that closes "
			+ "distance must telegraph at least %.2f s") % [lunge, telegraph,
			TuningProfile.TELEGRAPH_FLOOR * 2.0])
	return problems
