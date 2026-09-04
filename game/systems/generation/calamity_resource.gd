class_name CalamityResource
extends Resource
## What happened here (`DES-015` Layer 2, ADR-018, `TEC-006`).
##
## `DES-015`'s thesis is that the generator's job *"is not to produce a space. It
## is to produce a place where something specific happened, that you can read as
## you move through it."* The Calamity is that something, rolled once per
## expedition before a single room is placed, and everything the floor is made
## of leans toward it.
##
## ## Every Calamity is hers (ADR-018)
##
## These are **not** a grab-bag of unrelated disasters. Gullveig is already the
## figure who brought gold-lust into the world, so each one is a variation on a
## single story — *they came into her gold, and it unmade them.* For the
## Delvings: the Dvergar mined the seam her hoard grew from, and then they kept
## mining. What differs between Calamities is how that ended, not what caused it.
##
## **The discipline is that the pattern is discoverable and never stated.** No
## NPC explains it, no codex spells it out, and nothing in this resource is a
## line of dialogue. The evidence is the architecture and the shape of how
## people died, which is why a Calamity is expressed here as *tags a room can
## carry* rather than as text.


## Stable string id, the `ItemResource` idiom (`TEC-006` principle 3).
@export var id: StringName = &""
## Locale key for the name shown on arrival and in the run log.
@export var name_key: StringName = &""

@export_group("Expression")
## The room flavours this Calamity pulls a floor toward. A module carrying one
## of these is *on theme* and gets weighted up when the floor is built; one
## carrying none is neutral and can appear under any Calamity.
##
## This is the whole mechanism. `DES-015` costs Layer 2 at *"a weighted
## prop/room table keyed on depth"* and calls the return absurd — systemic
## environmental storytelling for the price of a lookup.
@export var tags: Array[StringName] = []


## Checked at boot, in the shape `ItemResource.validate()` established
## (`TEC-006` principle 4).
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if id == &"":
		problems.append("a Calamity with no id cannot be rolled or logged")
	if name_key == &"":
		problems.append("`%s` has no name key, so it cannot be named to a "
			% id + "player and `DES-018`'s visual twin has nothing to twin")
	if tags.is_empty():
		problems.append(("`%s` favours no room flavours, so it would roll and "
			+ "change nothing — a Calamity that does not reach the "
			+ "architecture is the set dressing `DES-015` opens by "
			+ "diagnosing") % id)
	return problems


## What this Calamity is called, for the arrival brief and the run log.
##
## **Added at ADR-192, after finding that nothing read `name_key`.** Every other
## resource in the project that carries one has a `display()` beside it —
## `ItemResource`, `DeedResource`, `AspectNode`, `ClassResource` — and this had
## the field, the validator that required it, and no reader. So a Calamity was
## rolled per expedition, weighted every room on the floor through
## `ExpeditionHistory.favours`, and **was never named to a player in any
## channel**, while `DES-015`'s thesis is a place *"where something specific
## happened, that you can read as you move through it."*
##
## `check_dead.py` could not see it: the field is mentioned by a `.tres`, which
## is the exact trap `room_module.gd` writes down and then avoids by refusing to
## declare a field before something consumes it.
##
## **The name is all it says.** `DES-015` Layer 2's discipline is that the
## pattern is discoverable and never stated — no NPC explains it, no codex
## spells it out — so this names the disaster and never accounts for it. What
## happened is read off the architecture and off `mac_witness`.
func display() -> String:
	return tr(String(name_key)) if name_key != &"" else String(id)
