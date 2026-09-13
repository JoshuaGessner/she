class_name LootTable
extends Resource

## **What a biome's floors may deal, and from how deep** (ADR-220, `DES-023` §4).
##
## `DelvingsFloor` dealt from the whole item folder, sorted by worth and cut by
## depth (ADR-193). That named nothing, which was right while nothing had the
## list, and it made the folder the table: every item added changed every floor,
## and the cheapest things were dealt whatever they were — a bow on floor 0 in
## thirty-nine floors of forty, Regin's blade scattered as filler on floor 2.
##
## A table rather than a field on the item, because *where* a thing is found is
## the biome's to say. The Barrow-Fields will deal grave-goods the Delvings never
## hold, and an item that carried its own depth could only belong to one of them.
##
## **An item not in any table is never on a floor.** The bow lives only in the
## Veiðimaðr's kit, the Ember is a body's own, and the Waystone is laid by rule;
## `tests/data_probe.gd` asks that every item is dealt, worn in a kit, or one of
## those, so an item nothing can ever put in a hand is caught rather than kept.

@export var id: StringName = &""
@export var entries: Array[LootEntry] = []


## The items a floor of `depth` may deal, **dearest first** and then by id so two
## of equal worth never depend on load order (`TEC-007` §1). `role` of zero asks
## for every way; otherwise only entries that may be dealt that way.
func items_at(depth: int, role: int = 0) -> Array[ItemResource]:
	var out: Array[ItemResource] = []
	for entry: LootEntry in entries:
		if entry == null or entry.from_floor > depth:
			continue
		if role != 0 and entry.deals & role == 0:
			continue
		var item: ItemResource = ItemCatalogue.by_id(entry.item)
		if item != null:
			out.append(item)
	out.sort_custom(func(a: ItemResource, b: ItemResource) -> bool:
		if a.tribute_value != b.tribute_value:
			return a.tribute_value > b.tribute_value
		return String(a.id) < String(b.id))
	return out


## The entry naming `item`, or null.
func entry_for(item: StringName) -> LootEntry:
	for entry: LootEntry in entries:
		if entry != null and entry.item == item:
			return entry
	return null


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if not String(id).begins_with("lut_"):
		problems.append("loot table id '%s' does not start with lut_ (TEC-006)" % id)
	if entries.is_empty():
		problems.append("a loot table with no entries deals nothing to any floor")
	var seen: Dictionary = {}
	for index: int in entries.size():
		var entry: LootEntry = entries[index]
		if entry == null:
			problems.append("entries[%d] is null" % index)
			continue
		if seen.has(entry.item):
			problems.append("'%s' is listed twice — which row wins would be "
				% entry.item + "array order")
		seen[entry.item] = true
		var item: ItemResource = ItemCatalogue.by_id(entry.item)
		if item == null:
			problems.append("'%s' names no item in the folder" % entry.item)
			continue
		if entry.deals == 0:
			problems.append("'%s' may be dealt no way at all" % entry.item)
		if entry.from_floor < 0 or entry.from_floor > RunFile.LAST_FLOOR:
			problems.append("'%s' starts at floor %d, and floors run 0 to %d"
				% [entry.item, entry.from_floor, RunFile.LAST_FLOOR])
		var glitters: bool = item.tags.has(&"glitter")
		# `DES-023` §4: a machine's gear is what the fallen carried, and
		# glitter there would make the situation a treasure room.
		if glitters and entry.can(LootEntry.Deal.GEAR):
			problems.append("'%s' glitters and is dealt as a machine's gear"
				% entry.item)
		# The Guardian sits on something worth the fight: glitter or a relic.
		if entry.can(LootEntry.Deal.PRIZE) and not glitters \
				and not item.tags.has(&"relic"):
			problems.append("'%s' is a Prize and neither glitters nor is a relic"
				% entry.item)
		# The body's own token and the one-per-party way out are never loot
		# (`DES-012`, ADR-015); the Waystone is laid by rule instead.
		if item.tags.has(&"bound") or item.has_trait(ExtractionTrait):
			problems.append("'%s' is never loot and is listed as loot" % entry.item)
	return problems
