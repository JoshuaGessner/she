class_name DeedResource
extends Resource

## One thing worth remembering you did (`M3-T08`, `DES-016`).
##
## `ItemResource` and `ClassResource` are the shape this follows, down to the id
## prefix and the `validate()` that runs at boot — `CLAUDE.md`'s rule is that a
## designer adds one without touching code, and a deed is exactly the kind of
## content that wants adding in bulk.
##
## ## The rule that decides what may be a deed
##
## `DES-016`: *"Deed conditions are evaluated by the run systems that already
## exist — extraction state, ember events, Clamor history, loot decisions. No
## bespoke tracking subsystems; **if a deed needs new instrumentation, it's
## probably the wrong deed.**"*
##
## So a deed names a `condition` the run already knows how to answer, and the
## catalogue of conditions is deliberately short. A deed nobody can evaluate
## from what the run already recorded is not a deed this design wants.
##
## ## LINEAGE tier, always
##
## `DES-016` is explicit, and `DES-003` explains why it is safe to be generous:
## Legacy and Lineage are power-free by construction. A camp full of marks says
## something about a player and gives them nothing.

## What a run can already be asked about. Every one of these is answerable from
## state the loop keeps for its own reasons — no deed here added a field.
const CONDITIONS: Array[StringName] = [
	## Left a floor alive, at all. The First-deed drip `DES-016` wants for a
	## new lineage.
	&"got_out",
	## Carried somebody's ember to the exit (`DES-012`, `M2-T05`). ADR-050 puts
	## **their name** in your save for this one, which is the first time this
	## profile stores anyone but you.
	&"bore_them_home",
	## Left with nothing in the bag. `DES-016`'s Refusal category, and ADR-020's
	## claim that the game should be able to see when you chose the light.
	&"empty_handed",
	## Left the Prize where it lay.
	&"left_the_prize",
	## Left on almost no health. `DES-016`'s Endurance category ⟨tune⟩.
	&"by_a_thread",
]

## `DES-016`'s six, and the id prefix says which. A seventh category is a design
## change rather than a typo, so `validate()` refuses one.
const CATEGORIES: Array[StringName] = [
	&"first", &"rescue", &"refusal", &"endurance", &"memorial", &"calamity",
]

@export var id: StringName = &""

@export_group("Text")
@export var name_key: StringName = &""
## What it says when it surfaces. **Never how to earn it** — `DES-016` and
## ADR-050 make deeds *secret*, discovered through Bound gossip rather than a
## checklist, and a description that reads as an objective converts evidence
## into a chore (`PRO-005` §11).
@export var description_key: StringName = &""

@export_group("Identity")
@export var category: StringName = &""
@export var condition: StringName = &""
## For the conditions that are a threshold rather than an event ⟨tune⟩.
@export var threshold: float = 0.0


func display() -> String:
	return tr(String(name_key)) if name_key != &"" else String(id)


func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if id == &"":
		problems.append("a deed with no id cannot be awarded or saved")
	elif not String(id).begins_with("ded_"):
		problems.append("deed id '%s' does not start with 'ded_' (TEC-006)" % id)
	if name_key == &"" or description_key == &"":
		problems.append("%s has no text; a deed nobody can read is a row in a save" % id)
	if not CATEGORIES.has(category):
		problems.append(("%s is category '%s', which is not one of `DES-016`'s "
			+ "six — a seventh is a design change, not a typo") % [id, category])
	if not CONDITIONS.has(condition):
		problems.append(("%s waits on '%s', which no run system answers. "
			+ "`DES-016`: *if a deed needs new instrumentation, it's probably "
			+ "the wrong deed*") % [id, condition])
	return problems
