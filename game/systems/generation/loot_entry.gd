class_name LootEntry
extends Resource

## One line of a loot table: an item, the shallowest floor it may lie on, and the
## ways a floor may deal it (ADR-220, `DES-023` §4, `TEC-006`).
##
## `TEC-006` sketched an entry as *item, weight, count range, depth bias*. Only
## the depth is here, and a role in place of the rest: nothing yet weights one
## coin against another or deals a pair, and a field nothing reads is the stub
## ADR-064 bans. The role is what was missing, because the floor dealt by worth
## alone — a bow was the cheapest thing in the folder, so floor 0 dealt a bow on
## thirty-nine floors in forty.

## How a floor may place this item. Flags, because a coin is a Prize on one
## floor and filler on the next.
enum Deal {
	PRIZE = 1,   ## The one thing the Guardian sits on. Glitter or a relic.
	GEAR = 2,    ## A machine's contents: what the fallen carried. Never glitter.
	FILLER = 4,  ## Quantity, scaled by the party. Glitter, bindings, materials.
}

## The item's stable id (`TEC-006` principle 3), never a path.
@export var item: StringName = &""

## The shallowest floor this may lie on (0 is the top). It lies on every floor
## below as well: depth opens a band, it does not close the one above.
@export var from_floor: int = 0

@export_flags("Prize", "Gear", "Filler") var deals: int = 0


## Whether a floor may deal this in the given way.
func can(role: Deal) -> bool:
	return deals & role != 0
