class_name ContractArchetypeResource
extends Resource

## **One kind of work, in one faction's voice** (`M4-T04`, ADR-241, `DES-007`,
## `TEC-006`).
##
## `DES-007` assembles a contract as *archetype × target × location ×
## complication × faction × reward*, so this is a part and never an instance:
## the floor it points at and its grade are chosen at the board, and its target
## is read off that floor when the party arrives. Complications are absent in
## the slice — each is a rule, and none is written yet.
##
## **Targets the floor already has.** Every kind is answered by something a
## generated floor lays whatever its seed: a Prize, a Bellringer, a Guardian, a
## deep room. A contract that could point at nothing is a failure the player
## was sold.

@export var id: StringName = &""
## The faction whose board offers it.
@export var faction: StringName = &""
@export var kind: Enums.ContractKind = Enums.ContractKind.SURVEY
@export var title_key: StringName = &""
## The brief, with `{where}` for which floor and `{target}` for what.
@export var brief_key: StringName = &""
## What a `CULL` hunts on each floor, floor 0 first ⟨tune⟩ — only archetypes
## the floor's population always places, which `data_probe` holds it to.
@export var cull: Array[StringName] = []


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if not String(id).begins_with("ctr_"):
		problems.append("contract id '%s' does not start with ctr_ (TEC-006)" % id)
	if String(faction).is_empty():
		problems.append("%s belongs to no faction, so no board offers it" % id)
	if String(title_key).is_empty() or String(brief_key).is_empty():
		problems.append("%s has no title or brief — work nobody can read" % id)
	if kind == Enums.ContractKind.CULL and cull.size() != 3:
		problems.append("%s culls on %d floor(s); the expedition has three" % [id, cull.size()])
	if kind != Enums.ContractKind.CULL and not cull.is_empty():
		problems.append("%s names cull targets nothing reads" % id)
	return problems
