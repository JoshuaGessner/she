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
## **Who this is, drawn** (ADR-330): the class sworn and in its own kit, as the
## game's ink draws a teammate, on the card you choose a life from. Made by
## `--portrait-shot`; absent, the card is text alone.
@export var portrait: Texture2D = null

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
## The real first-person forearms for this class (`DES-020`). They use the
## shared 28-bone topology, so an Arms item can be skinned over them without a
## class-specific armour mesh or a generated arm standing in for one.
@export var bare_arms: PackedScene
## **The Rites change the arms** (ADR-057, `M4-T46`): the same forearms carrying
## more of this class's own marks, worn from Pact Rank 3, 5 and 7 (`RITE_RANKS`)
## — the Völva's ink spreading, the wolf-skin climbing, the grave-stain on a
## mound-breaker's hands. Growth you can see on your own body, placed in the
## runs where nothing else visibly changes (`DES-022`). Empty, or one per rank.
@export var rite_arms: Array[PackedScene] = []

## The Pact Ranks at which each of `rite_arms` is first worn.
const RITE_RANKS: Array[int] = [3, 5, 7]
## **What the class wears when nothing is in its body slot** (ADR-354) — a
## look, not an item: never in the bag, never in the catalogue, weighs nothing
## and turns nothing away. The Úlfheðinn's wolf-coat is what they are named
## for, and a byrnie put on over it is worn instead.
@export var dress: PackedScene = null

## The dress as the rig wears gear: a worn model on the shared skeleton. Made
## once, and never an entry in any catalogue — a data file of its own would be
## an item with no name, no icon and no place in a bag (`TEC-006`).
var _dress_item: ItemResource = null


## The forearms a life of this class wears at `rank`: the bare arms, or the
## last Rite stage the rank has reached.
func arms_at(rank: int) -> PackedScene:
	var worn: PackedScene = bare_arms
	for stage: int in mini(rite_arms.size(), RITE_RANKS.size()):
		if rank >= RITE_RANKS[stage] and rite_arms[stage] != null:
			worn = rite_arms[stage]
	return worn


func dress_item() -> ItemResource:
	if dress == null:
		return null
	if _dress_item == null:
		_dress_item = ItemResource.new()
		_dress_item.id = StringName("%s_dress" % id)
		_dress_item.worn_model = dress
		_dress_item.slot = Enums.Slot.BODY
	return _dress_item

@export_group("Kit")
## Item ids this class descends with on a fresh life. Real definitions from the
## catalogue — an id nothing knows fails `validate()` rather than silently
## arming somebody with nothing.
@export var kit: Array[StringName] = []
## **Carried in the bag rather than worn** (ADR-238): the second thing for a slot
## the kit already fills. `DES-023` §4's Húskarl holds a shield and carries the
## lantern, and the off hand is the contest between them. Its own list, so which
## of two off-hand items is worn is said in the data rather than left to the
## order of one list — the ordering dependency `data_probe` refuses in `kit`.
@export var carried: Array[StringName] = []


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
	if bare_arms == null:
		problems.append("%s has no bare_arms mesh — DES-020 makes forearms the "
			+ "one armour a player sees on their own body")
	# ADR-057: one stage per Rite rank, every one of them real — a rank that
	# changed nothing on the arms would be the growth `DES-022` promises,
	# absent where it was said to be.
	if rite_arms.size() != RITE_RANKS.size() or rite_arms.has(null):
		problems.append("%s has %d Rite arm stage(s) for %d ranks — ADR-057's arms change at each"
			% [id, rite_arms.filter(func(s: PackedScene) -> bool: return s != null).size(),
				RITE_RANKS.size()])
	return problems
