class_name ClassResource
extends Resource

## One of the Sworn (`M3-T02`, `DES-011`), as data rather than as code.
##
## `CLAUDE.md`'s rule: *"a designer must be able to add an item without touching
## code"*, and a class is the same kind of thing — `ItemResource` is the shape
## this follows deliberately, down to the id prefix and the `validate()` that
## runs at boot.
##
## ## What a class is, and which parts exist yet
##
## `DES-011` defines four:
##
## | | |
## |---|---|
## | Starting kit, body profile, one unique verb | **here** |
## | **Rite** — a class-only branch, ~7 nodes | `M3-T01` |
## | Aspect access — which 3 of the 5 this class may enter | declared here, enforced at `M3-T01` |
##
## The Rite is skill-tree work and unlocks at Pact Rank 3 (ADR-060), which
## nothing can reach until the tree exists. **`aspects` is declared now anyway**,
## and that is not a stub: ADR-009 makes class-gates-Aspect the reason `M3-T02`
## precedes `M3-T01` at all (ADR-116 §2), so the tree is built against a rule
## that is already written down rather than having one retrofitted onto it.
##
## A class is complete here **as a body you play** (ADR-120). What it lacks is
## progression, and progression is absent for everybody until the tree lands —
## the same shape as the hoard, which has grown since `M2-T06` and buys nothing.

## `DES-011`'s six, and no more: a class id that is not one of these is a typo
## or an invention, and both should fail at boot rather than at the select
## screen. Being *listed* is not being *built* — five of these have no resource.
const SWORN: Array[StringName] = [
	&"huskarl", &"volva", &"skald", &"ulfhedinn", &"veidimadr", &"haugbrjotr",
]

## `DES-004`'s five. A class may enter three (ADR-009).
const ASPECTS: Array[StringName] = [
	&"scale", &"cinder", &"hoard", &"wing", &"maw",
]

@export var id: StringName = &""

@export_group("Text")
@export var name_key: StringName = &""
@export var description_key: StringName = &""
## *"How do they get out?"* — `DES-011` defines every class by its answer to
## that question first, before any stat. The select screen leads with it.
@export var exit_key: StringName = &""

@export_group("Identity")
## Which three of `DES-004`'s five this class may enter (ADR-009).
@export var aspects: Array[StringName] = []
## The unique verb's id. One per class, and `DES-011`'s rule is that identity
## comes from the verb rather than the stat line — *"a player should recognize
## each class from 10 seconds of watching."*
@export var verb: StringName = &""

@export_group("Body")
## Multipliers on the shared profile, **not** a stat block. `DES-009` Q22
## refused a third build axis; these exist so a Húskarl walks like a Húskarl,
## and every one of them is ⟨tune⟩.
@export var health_scale: float = 1.0
@export var stamina_scale: float = 1.0
@export var speed_scale: float = 1.0
## What carrying costs this body. Above 1.0 means weight lands *lighter* on
## them, which is the Húskarl's *"keep moving under weight that would pin
## anyone else"* expressed without a new system.
@export var carry_scale: float = 1.0

@export_group("Kit")
## Item ids this class descends with on a fresh life. Real definitions from the
## catalogue — an id nothing knows fails `validate()` rather than silently
## arming somebody with nothing.
@export var kit: Array[StringName] = []


func display() -> String:
	return tr(String(name_key)) if name_key != &"" else String(id)


## Checked at boot by `ClassCatalogue`, in the shape `ItemResource.validate()`
## established: a malformed class should stop the build, not reach a player as
## a character that cannot be played.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if id == &"":
		problems.append("a class with no id cannot be chosen or saved")
	elif not SWORN.has(id):
		problems.append(("'%s' is not one of DES-011's six — a seventh class is "
			+ "either a typo or a design change needing an ADR") % id)
	if verb == &"":
		problems.append(("%s has no unique verb — DES-011 makes the verb the "
			+ "class identity, and a class without one differs only in numbers")
			% id)
	# ADR-009: three of five, exactly. Fewer closes off a build the design
	# promises; more dissolves the gating that makes classes structural rather
	# than cosmetic, and 36 base identities depend on the number being 3.
	if aspects.size() != 3:
		problems.append(("%s allows %d Aspect(s); ADR-009 says exactly 3 of 5, "
			+ "which is what makes 6 classes into 36 base identities")
			% [id, aspects.size()])
	for aspect: StringName in aspects:
		if not ASPECTS.has(aspect):
			problems.append("%s allows '%s', which is not one of DES-004's five"
				% [id, aspect])
	if health_scale <= 0.0 or stamina_scale <= 0.0 or speed_scale <= 0.0:
		problems.append("%s has a non-positive body scale; a class has to be playable"
			% id)
	if carry_scale <= 0.0:
		problems.append("%s has a non-positive carry_scale, which makes encumbrance undefined"
			% id)
	return problems
