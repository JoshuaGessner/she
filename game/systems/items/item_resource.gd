class_name ItemResource
extends Resource

## One item, as data (`TEC-006`, DES-008).
##
## `CLAUDE.md`: *a designer must be able to add an item without touching code.*
## That is the whole test this file has to pass, and it is why there is no
## `Sword` class anywhere in the project.
##
## ## The four axes exist so they can disagree
##
## DES-008 puts every item in a three-way tug-of-war — **use it, tribute it,
## keep it** — and says plainly that if any one of the three is obviously
## correct, the economy has failed. The exported axes are what make that
## argument concrete rather than aspirational:
##
## | Axis | The cost it imposes |
## |---|---|
## | `weight` | movement and stamina — the physical cost of greed (DES-005) |
## | `clamor` | aggro radius and Hunt escalation — the audible cost |
## | `traits` | what it does if you use it |
## | `tribute_value` | what she pays for it, from rarity and provenance |
##
## The interesting items are the ones where those disagree loudly. A coin hoard
## is enormous tribute at ruinous weight and clamor. A good blade is high
## utility and poor tribute, so it stays yours — ***she wants what glitters,
## not what works***, which is the valve that stops the tribute system
## stripping the player naked every run.
##
## ## What is deliberately not here
##
## No rarity tier, no level requirement, no stat multiplier. DES-008 rejects
## the green→blue→purple ladder outright: better gear is *more options and
## better condition*, never bigger numbers. There is nowhere in this schema to
## put a `+12%`, and that is the point.
##
## Per-instance state — a lantern's fuel, a blade's condition — is **not** here
## and must not be. Godot shares a `Resource` between every holder of it, so
## two lanterns would share one fuel value. That is Q103, still open, and it is
## forced by the first stateful item rather than by this file. The first ten
## items are deliberately stateless so that answering it can wait for a real
## case instead of a guess.

## Every prefix `TEC-006` assigns to items. Checked, because a convention that
## is written down and not enforced is a convention that drifts — and these are
## how a reader tells a weapon from a relic in a save file or a log line.
## A typed `Array`, not a `PackedStringArray`: the packed form is built by a
## constructor call, and GDScript will not accept a call as a constant.
const PREFIXES: Array[String] = ["wpn_", "arm_", "con_", "glt_", "rlc_", "mat_"]

## Stable, unique, permanent. Saves reference this string and never a resource
## path, so moving or renaming a file can never break a save (`TEC-003`,
## `TEC-006` principle 3). Changing an `id` after it ships is a save migration,
## not an edit.
@export var id: StringName = &""

@export_group("Text")
## **Translation keys, not English** (ADR-084, closing Q104). The English lives
## in `data/locale/en.csv`, which Godot loads as a translation, so `display()`
## returns real text today *and* the retrofit that Q104 warned about never
## happens. Keys cost nothing at ten items and are painful at a thousand.
@export var name_key: StringName = &""
@export var description_key: StringName = &""

@export_group("The four axes")
## Kilograms. Feeds `CarriedWeight`, and through it movement, stamina and jump.
@export var weight: float = 0.0
## Noise made by carrying and handling it, on `TuningProfile`'s clamor scale.
## The Gullsjúkr senses wealth (`DES-017`), so glitter is loud even when light.
@export var clamor: float = 0.0
## Inventory footprint in grid cells (`DES-019`). Bulk and weight are separate
## constraints on purpose: a bolt of cloth is bulky and light, a bag of coin is
## tiny and ruinous, and they pose different problems.
@export var grid_size: Vector2i = Vector2i.ONE
## Boon if given to her (`DES-004`). Driven by rarity and *provenance*, not by
## quantity — which is why a named relic outvalues its weight in coin.
@export var tribute_value: int = 0

@export_group("Composition")
## What it can do. Empty is the common and correct case: glitter and materials
## have no utility at all, which is exactly what makes them a pure greed
## decision.
@export var traits: Array[ItemTrait] = []
## Free-form classifiers systems react to — `"glitter"`, `"dvergar"`,
## `"metal"`, `"grave_good"`. DES-008's five loot categories live here rather
## than as an enum, because an item is routinely more than one of them.
@export var tags: Array[StringName] = []


## The item's name in the player's language. `tr()` falls through to the key
## itself if no translation is loaded, so a missing row is visible rather than
## blank.
func display() -> String:
	return tr(name_key)


func described() -> String:
	return tr(description_key)


## True if any trait of the given class is present — the composition question
## every consuming system actually asks.
func has_trait(type: Script) -> bool:
	for item_trait: ItemTrait in traits:
		if is_instance_of(item_trait, type):
			return true
	return false


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if String(id).is_empty():
		problems.append("id is empty; every item needs a stable permanent id")
	elif not _prefixed(String(id)):
		problems.append("id '%s' does not start with one of %s (TEC-006)"
			% [id, ", ".join(PREFIXES)])
	if String(name_key).is_empty():
		problems.append("name_key is empty")
	if String(description_key).is_empty():
		problems.append("description_key is empty")

	if weight < 0.0:
		problems.append("weight cannot be negative")
	if clamor < 0.0:
		problems.append("clamor cannot be negative")
	if tribute_value < 0:
		problems.append("tribute_value cannot be negative")
	if grid_size.x < 1 or grid_size.y < 1:
		problems.append("grid_size %s occupies no cells" % grid_size)

	# **Free money, always a bug** (`TEC-006`). An item worth tributing that
	# costs nothing to carry and nothing to be near breaks the loop the whole
	# game is built on: DES-005 makes greed felt in your legs and heard through
	# walls, and this is an item that opts out of both.
	#
	# DES-008's own example — "a raw gemstone (high tribute, no weight, no
	# use)" — reads like a violation and is not: *no weight* is literal, and
	# the gem's cost is that it is loud, because the Gullsjúkr senses wealth
	# (`DES-017`). This rule is what forces that reading rather than letting a
	# costless gem through.
	if tribute_value > 0 and is_zero_approx(weight) and is_zero_approx(clamor):
		problems.append(("tribute_value %d with no weight and no clamor — free money; "
			+ "give it a physical or an audible cost") % tribute_value)

	for index: int in range(traits.size()):
		var item_trait: ItemTrait = traits[index]
		if item_trait == null:
			problems.append("traits[%d] is null" % index)
			continue
		for problem: String in item_trait.validate():
			problems.append("%s trait: %s" % [item_trait.kind(), problem])
	return problems


func _prefixed(text: String) -> bool:
	for prefix: String in PREFIXES:
		if text.begins_with(prefix):
			return true
	return false
