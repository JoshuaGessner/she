class_name EnemyResource
extends Resource

## One kind of enemy, as data (`M4-T02`, `TEC-006`, `DES-013`, ADR-231).
##
## `CLAUDE.md`: *a designer must be able to add an enemy without touching code.*
## Every enemy was one body with one set of `TuningProfile` numbers, so the
## slice's five archetypes (ADR-230) had nowhere to differ. This is where they do.
##
## **Only what an archetype actually varies by is here.** `TEC-006` sketches a
## role, a faction, a sense profile, a scene and a modifier list as well. Each
## arrives with the archetype that needs it — the Bellringer's role, the Hall-
## Warden's leash — and not before: a field nothing reads is the stub ADR-064
## bans, and ADR-222 and ADR-224 were each a field like that. Senses stay on
## `TuningProfile`, where every archetype shares them until one does not.

## Stable, permanent, prefixed `enm_` (`TEC-006`). A spawn names this.
@export var id: StringName = &""
@export var name_key: StringName = &""

@export_group("Body")
@export var health: float = 60.0
## What a blow has to take out of it to stagger it (`M4-T16`) ⟨tune⟩.
@export var poise: float = 100.0
## Poise back per second while not staggered ⟨tune⟩.
@export var poise_regen: float = 18.0
## Seconds a broken poise holds it (`M4-T16`) ⟨tune⟩.
@export var stagger: float = 0.35
@export var walk_speed: float = 2.0
@export var run_speed: float = 3.6
## Radians a physics tick it may turn toward where it is going ⟨tune⟩.
@export var turn_rate: float = 0.12
## What its body turns a blow with (`DES-023` §3, ADR-219).
@export var armour_class: Enums.ArmourClass = Enums.ArmourClass.UNARMOURED
## **How far from its post it will go** (ADR-232), in metres, or `0` for no
## limit. `DES-013`'s Blocker *owns a corridor or door*: it goes no further than
## this after you, so walking past its reach is a route, and standing just beyond
## it is somewhere it can see you and never touch you ⟨tune⟩.
@export var leash: float = 0.0
## Clamor added each time it is struck (ADR-232). `DES-013`'s Hall-Warden is
## *deafeningly loud when struck*: dead armour ringing, which is what makes
## fighting it a decision about the floor as well as about the fight ⟨tune⟩.
@export var clamor_struck: float = 0.0
## **How near its post a thing has to be for it to notice** (ADR-233), in metres,
## or `0` for anywhere it can see or hear. `DES-013`'s Guardian is *purely
## optional — it will never come to you*: nothing it sees or hears beyond this
## wakes it, so a Hoard-Keeper is a fight that only happens to a body that walks
## up to what it sits on ⟨tune⟩.
@export var wakes_within: float = 0.0

@export_group("Attack")
## The one blow it deals. One, not `TEC-006`'s list: no archetype in the slice
## has two, and a list that is only ever read at index zero is a field nothing reads.
@export var attack: AttackResource = null


func display() -> String:
	return tr(String(name_key)) if name_key != &"" else String(id)


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if not String(id).begins_with("enm_"):
		problems.append("enemy id '%s' does not start with enm_ (TEC-006)" % id)
	if String(name_key).is_empty():
		problems.append("%s has no name_key" % id)
	if health <= 0.0:
		problems.append("%s has no health, so it is dead on arrival" % id)
	if poise <= 0.0:
		problems.append("%s has no poise, so every touch staggers it" % id)
	if poise_regen < 0.0 or stagger <= 0.0:
		problems.append("%s needs a stagger above zero and a regen that is not negative" % id)
	if walk_speed <= 0.0 or run_speed < walk_speed:
		problems.append("%s runs %.1f and walks %.1f — it has to walk, and run no slower"
			% [id, run_speed, walk_speed])
	if turn_rate <= 0.0:
		problems.append("%s cannot turn" % id)
	if leash < 0.0 or clamor_struck < 0.0 or wakes_within < 0.0:
		problems.append("%s has a negative leash, ring or waking radius" % id)
	# Something that only wakes near its post and then chases anywhere is a
	# Guardian for the first second and a Wretch after it.
	if wakes_within > 0.0 and leash <= 0.0:
		problems.append(("%s wakes only within %.1f m of its post and has no leash — "
			+ "once woken it would follow you off the Prize") % [id, wakes_within])
	# A leash shorter than its own reach holds it somewhere it can never land a
	# blow on anything that came to it, which is a statue.
	if leash > 0.0 and attack != null and leash < attack.reach:
		problems.append("%s is leashed at %.1f m and reaches %.1f m — it could "
			% [id, leash, attack.reach] + "never reach the edge of its own post")
	if attack == null:
		problems.append("%s has no attack" % id)
	else:
		for problem: String in attack.validate():
			problems.append("%s: %s" % [id, problem])
	return problems
