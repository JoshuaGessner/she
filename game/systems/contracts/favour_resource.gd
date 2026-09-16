class_name FavourResource
extends Resource

## **One thing a faction's standing buys at the fire** (`M4-T04`, ADR-241).
##
## ADR-050's second lane: trust decides what work you are offered, and favour
## is spent. The Lodge's favours are `DES-007`'s *"real, useful, unglamorous
## things — safehouses, map intel, extraction tools. Never power"*, so a favour
## is an item that already exists or the floor's plan, and never a number.
##
## **Owed, not handed over.** A favour bought at the fire is delivered at the
## next descent, one of each: a Waystone that sat in the stash could be bought
## twice and carried down twice, which is ADR-015's one-per-party cap undone at
## a counter.

enum Kind {
	ITEM,  ## Existing items, into the bag at the descent.
	PLAN,  ## Where each floor's Prize and Shaft lie, said on arrival.
}

## Stable and permanent, like every id a save holds (`TEC-006`).
@export var id: StringName = &""
@export var name_key: StringName = &""
## Favour it costs ⟨tune⟩.
@export var cost: int = 1
@export var kind: Kind = Kind.ITEM
## The item an `ITEM` favour delivers, and how many.
@export var item: StringName = &""
@export var count: int = 1


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if not String(id).begins_with("fav_"):
		problems.append("favour id '%s' does not start with fav_ (TEC-006)" % id)
	if String(name_key).is_empty():
		problems.append("%s has no name_key" % id)
	if cost < 1:
		problems.append("%s costs %d — a favour that costs nothing is not a lane, it is a gift" % [id, cost])
	if kind == Kind.ITEM and (String(item).is_empty() or count < 1):
		problems.append("%s delivers an item and names none, or none of it" % id)
	if kind == Kind.PLAN and not String(item).is_empty():
		problems.append("%s is a plan and names an item nothing will deliver" % id)
	return problems
