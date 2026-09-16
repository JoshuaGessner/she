class_name FactionResource
extends Resource

## **Who gives the work, and what their trust is worth** (`M4-T04`, ADR-241,
## `DES-007`).
##
## Two lanes, by ADR-050: **trust** decides which grades of work are offered,
## and rises with every contract met and falls with every one failed; **favour**
## is earned beside it and spent at the fire. Keeping them apart is what keeps
## access legible while leaving a decision: spending favour never closes a
## door, and failing never takes back what you already earned to spend.
##
## Both are LIFE tier (`DES-007`: *contacts persist to Lineage; standing does
## not*). Contacts are absent: nothing yet talks to anybody.

## Stable and permanent (`TEC-006`).
@export var id: StringName = &""
@export var name_key: StringName = &""
## Trust needed to be offered work of each grade, grade 1 first ⟨tune⟩.
## Grade 1 is always open, so a new life is always given something.
@export var grade_trust: PackedInt32Array = PackedInt32Array([0, 3, 8])
## What a met contract of each grade earns ⟨tune⟩.
@export var trust_for_grade: PackedInt32Array = PackedInt32Array([1, 2, 3])
@export var favour_for_grade: PackedInt32Array = PackedInt32Array([1, 2, 3])
## Trust a failed contract costs ⟨tune⟩ — `DES-007`'s fail-forward: progress,
## never the run.
@export var trust_lost: int = 1
@export var favours: Array[FavourResource] = []


## The deepest grade of work this much trust is offered.
func top_grade(trust: int) -> int:
	var top: int = 1
	for grade: int in grade_trust.size():
		if trust >= grade_trust[grade]:
			top = grade + 1
	return top


## Trust or favour for meeting a contract of `grade`, 1-based.
func trust_for(grade: int) -> int:
	return trust_for_grade[clampi(grade, 1, trust_for_grade.size()) - 1]


func favour_for(grade: int) -> int:
	return favour_for_grade[clampi(grade, 1, favour_for_grade.size()) - 1]


func favour(favour_id: StringName) -> FavourResource:
	for offered: FavourResource in favours:
		if offered.id == favour_id:
			return offered
	return null


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if not String(id).begins_with("fac_"):
		problems.append("faction id '%s' does not start with fac_ (TEC-006)" % id)
	if String(name_key).is_empty():
		problems.append("%s has no name_key" % id)
	for table: PackedInt32Array in [grade_trust, trust_for_grade, favour_for_grade]:
		if table.size() != 3:
			problems.append("%s has %d grade(s) in a table; the slice has three" % [id, table.size()])
	if grade_trust.size() > 0 and grade_trust[0] != 0:
		problems.append("%s asks trust for its first grade — a new life would be offered nothing" % id)
	for grade: int in range(1, grade_trust.size()):
		if grade_trust[grade] <= grade_trust[grade - 1]:
			problems.append("%s opens grade %d no later than grade %d" % [id, grade + 1, grade])
	for table: PackedInt32Array in [trust_for_grade, favour_for_grade]:
		for amount: int in table:
			if amount < 1:
				problems.append("%s pays %d for a met contract — work that earns nothing is a trap" % [id, amount])
	if trust_lost < 1:
		problems.append("%s costs nothing to fail, so taking every contract is free" % id)
	if favours.is_empty():
		problems.append("%s has nothing to spend favour on" % id)
	var seen: Array[StringName] = []
	for offered: FavourResource in favours:
		if offered == null:
			problems.append("%s has an empty favour" % id)
			continue
		if seen.has(offered.id):
			problems.append("%s offers %s twice" % [id, offered.id])
		seen.append(offered.id)
		problems.append_array(offered.validate())
	return problems
