class_name RangedTrait
extends ItemTrait

## A thing you draw and loose (`M3-T11`, `DES-011`, ADR-123).
##
## **The first ranged weapon in a game whose combat doc does not mention one.**
## `DES-009` names five verbs — attack, heavy, block, shove, throw — and every
## one is melee or a physics launch; `throw` exists and does no damage, because
## it is for baiting the Gullsjúkr. The bow appears in exactly one place in the
## corpus: `DES-011`'s line for the Veiðimaðr. ADR-123 is what puts it in
## `DES-009` properly rather than letting a class kit smuggle in a whole damage
## delivery system.
##
## ## It obeys the rules `DES-009` already set
##
## - **Committal.** A draw takes `draw_seconds` and cannot be cancelled into
##   anything. Same argument as the swing: *"attacks commit."*
## - **No precision requirement.** `DES-009` refuses hit-scan precision and
##   forgiving melee volumes; an arrow is a travelling body with a real radius,
##   not a ray. It can be led, and it can be dodged by walking, which is the
##   positional defence the whole model is built on.
## - **Every shot has a Clamor value**, which is `DES-009`'s main combat↔pressure
##   coupling. A bow is *quieter* than a swing, and that is the Veiðimaðr's
##   entire loop relationship — *"gets out by never having been noticed"* — not
##   a damage advantage. It is a sidegrade with a pronounced identity
##   (`DES-008`), never a better number.
##
## ## What is absent
##
## **Ammunition.** `DES-008`'s economy question, and giving a bow a consumable
## before there is an economy to consume from would be inventing scarcity to
## balance a weapon rather than because the design asks for it. **Aim-down-
## sights, damage falloff and headshots** are absent for the reason `DES-009`
## gives about move lists: depth is situational here, not in the input.

## Seconds to draw before it will loose. Long enough to be a decision you
## commit to rather than a click (principle 3), and it is a telegraph an enemy
## can react to — ADR-053's 250 ms floor applies to a drawn bow for the same
## reason it applies to a raised axe.
@export var draw_seconds: float = 0.55
## Seconds after loosing before you can draw again.
@export var recovery: float = 0.35

@export var damage: float = 32.0
@export var damage_type: Enums.DamageType = Enums.DamageType.PIERCE

## Metres per second the arrow travels. **Fast, not instant**: it can be led
## and it can be walked out of, which is what keeps `DES-009`'s "defense is
## positional" true of a weapon fired from across a room.
@export var arrow_speed: float = 34.0
## Metres before an arrow gives up and frees itself. A cap rather than gravity:
## an arc is a precision mechanic and `DES-009` refuses precision requirements.
@export var arrow_range: float = 26.0

## Stamina to draw. Drawing is holding a bow bent, and `DES-009` puts it on the
## same pool as swinging, blocking, sprinting and climbing.
@export var stamina_cost: float = 14.0

## Noise on loosing ⟨tune⟩. Deliberately below `clamor_swing`: the bow's whole
## identity is that it is the quiet answer, and the Stalker's advantage is
## measured in Clamor rather than in damage.
@export var clamor_loose: float = 0.4
## Noise where an arrow lands. **Higher than loosing**, and that is the tactic:
## the noise happens *over there*, which is the same misdirection `DES-005`
## already sells thrown loot on.
@export var clamor_hit: float = 3.2


func kind() -> String:
	return "ranged"


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if draw_seconds < 0.25:
		problems.append(("draw_seconds is %.2f s, below ADR-053's 250 ms floor — "
			+ "a drawn bow is a telegraph and an enemy has to be able to read it")
			% draw_seconds)
	if recovery <= 0.0:
		problems.append("recovery must be positive; it is what makes a shot commit")
	if damage <= 0.0:
		problems.append("damage must be positive")
	if arrow_speed <= 0.0:
		problems.append("arrow_speed must be positive or nothing ever arrives")
	if arrow_range <= 0.0:
		problems.append("arrow_range must be positive or the arrow dies where it is made")
	if stamina_cost < 0.0:
		problems.append("stamina_cost cannot be negative")
	if clamor_loose < 0.0 or clamor_hit < 0.0:
		problems.append("clamor cannot be negative — a silent shot is `0.0`, not less")
	return problems
