class_name Contract
extends RefCounted

## **One piece of work, taken** (`M4-T04`, ADR-241): an archetype, the floor it
## points at and its grade. What it names on that floor is read when the party
## arrives there (`ContractLedger`), so a contract taken at the fire needs
## nothing from a floor that does not exist yet.

## The words for each floor, as a brief says them.
const FLOORS: Array[String] = ["the first floor", "the second floor", "the bottom"]

var archetype: StringName = &""
## Which floor of the expedition, 0 to 2.
var floor_index: int = 0
## 1 to 3, and one more than the floor: deeper work is harder and pays more.
var grade: int = 1


static func of(work_id: StringName, grade_of: int) -> Contract:
	var made := Contract.new()
	made.archetype = work_id
	made.grade = clampi(grade_of, 1, 3)
	made.floor_index = made.grade - 1
	return made


## A save's row back into a contract, or null for an archetype this build does
## not have — skipped, like an unknown item.
static func from_record(row: Variant) -> Contract:
	if typeof(row) != TYPE_DICTIONARY:
		return null
	var record: Dictionary = row
	var made: Contract = Contract.of(StringName(record.get("archetype", "")),
		int(record.get("grade", 1)))
	return made if made.definition() != null else null


func to_record() -> Dictionary:
	return {"archetype": String(archetype), "grade": grade}


## Which contract this is, for a run file to say it was met: one of each
## archetype at a time, so the archetype is enough.
func key() -> String:
	return String(archetype)


func definition() -> ContractArchetypeResource:
	return ContractCatalogue.archetype(archetype)


func kind() -> Enums.ContractKind:
	return definition().kind


## What a `CULL` hunts on its floor.
func cull_target() -> StringName:
	var cull: Array[StringName] = definition().cull
	return cull[floor_index] if floor_index < cull.size() else &""


func title() -> String:
	return TranslationServer.translate(definition().title_key)


## The brief, with its floor and target said.
func brief() -> String:
	var target: String = ""
	if kind() == Enums.ContractKind.CULL:
		var hunted: EnemyResource = EnemyCatalogue.by_id(cull_target())
		target = hunted.display() if hunted != null else ""
	return TranslationServer.translate(definition().brief_key).format({
		"where": FLOORS[clampi(floor_index, 0, FLOORS.size() - 1)],
		"target": target,
	})


func same_as(other: Contract) -> bool:
	return other != null and other.archetype == archetype and other.grade == grade
