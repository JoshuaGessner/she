class_name WieldableTrait
extends ItemTrait

## A thing you can swing (`TEC-006`, DES-009).
##
## The one trait built at `M2-T08`, and it is built because **every field here
## is a number the melee system already runs on.** `M1-T02` measured the swing
## anatomy in wall-clock and it was signed off on those timings, so this is the
## shape live numbers move into — not the shape of a system that does not exist
## yet, which is what the other six traits would have been.
##
## **Nothing reads this yet, and that is the scope line.** Wiring `MeleeWeapon`
## to take its timings from an equipped item is `M2-T01`'s work. Doing it here
## would re-home numbers `M1` was signed off against inside the same change
## that invents the schema, and a feel regression would then be impossible to
## attribute (ADR-058 — archetype stats change only by ADR).
##
## Gear is **sidegrades with pronounced identity**, never a stat ladder
## (DES-008). A spear outranges everything and is useless in a corridor; a
## hammer breaks shields and doors and is slow enough to get you killed. Those
## are `reach` and the phase timings disagreeing on purpose — not one weapon
## having bigger numbers than another.

## DES-009's attack anatomy: Anticipation → Active → Recovery, in seconds.
## The Active window is the only time a swing can connect, which is what makes
## a staggered attacker's swing genuinely not land.
@export var windup: float = 0.16
@export var active: float = 0.10
@export var recovery: float = 0.30

@export var damage: float = 25.0
@export var damage_type: Enums.DamageType = Enums.DamageType.CUT

## Metres the arc reaches. This is where a weapon's identity mostly lives:
## DES-008's spear and hammer differ by this and by their timings, not by a
## damage tier.
@export var reach: float = 1.1
@export var stamina_cost: float = 18.0

## Poise this swing removes from what it hits. **`DES-009` line 47 has said
## since the design lock that stagger is a weapon property** — *"light (fast,
## low stagger, quiet-ish) vs. heavy (slow, staggers, loud)"* — and it was
## never built: `Enemy._on_hurt` staggered on every hit for a flat
## `TuningProfile.enemy_stagger`, identical for a knife and a war hammer.
##
## Measured, that inverted the rule it was meant to serve. A stagger costs the
## enemy `enemy_stagger` + `enemy_telegraph` = 850 ms before it can swing
## again, and only the hammer's 900 ms cycle is slower than that. So the
## *lightest* weapon in the game was the one that locked an enemy out
## permanently, and the heavy one — the weapon `DES-009` says is the one that
## staggers — was the only weapon that could be hit back. `--fight-probe`
## measured zero damage taken in ten seconds of seax spam, stamina included.
##
## Against `TuningProfile.enemy_poise`, so a light weapon cannot break poise
## inside an enemy's lifetime and must earn its stagger in the recovery window
## instead. That is the trade, and it is why this is not simply a damage
## number wearing another name (ADR-058).
@export var stagger: float = 30.0  # ⟨tune⟩

## Deposited on starting a swing, and again on connecting — DES-009 makes
## connecting the loud part, so a whiff is cheap and a fight is not. Units are
## `TuningProfile`'s clamor scale.
@export var clamor_swing: float = 1.2
@export var clamor_hit: float = 4.5


func kind() -> String:
	return "wieldable"


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	# A zero-length phase is not a fast weapon, it is an unreadable one —
	# DES-009's whole attack anatomy is that the three phases can be *seen*.
	if windup <= 0.0:
		problems.append("windup must be positive; a swing with no anticipation is unreadable")
	if active <= 0.0:
		problems.append("active must be positive or the swing can never connect")
	if recovery <= 0.0:
		problems.append("recovery must be positive; it is what makes a swing commit")
	if damage <= 0.0:
		problems.append("damage must be positive")
	if reach <= 0.0:
		problems.append("reach must be positive")
	if stamina_cost < 0.0:
		problems.append("stamina_cost cannot be negative")
	# Zero is meaningful (a weapon that never staggers); negative is not.
	if stagger < 0.0:
		problems.append("stagger cannot be negative — a weapon that never "
			+ "staggers is `0.0`, not less")
	if clamor_swing < 0.0 or clamor_hit < 0.0:
		problems.append("clamor cannot be negative — a silent swing is `0.0`, not less")
	return problems
