class_name ItemTrait
extends Resource

## What an item can *do* — one capability, as a small resource (`TEC-006`).
##
## This is the schema's central decision, and it is worth restating because the
## obvious Godot approach is the wrong one here: **there is no `Item → Weapon →
## Sword` class tree.** DES-008 deliberately makes items occupy several
## categories at once — a jewelled sword is gear *and* tribute, a grave-good is
## tribute *and* cursed *and* aggros a Draugr, a lantern is a light source
## occupying a weapon slot. An inheritance tree forces each into one bucket and
## then needs escape hatches everywhere.
##
## So capability is composed instead: `ItemResource` holds the physical facts,
## and an array of these says what the thing can do. A new capability is a new
## subclass, and no item that lacks it changes at all.
##
## **Traits describe; they never act.** A trait holding behaviour would put
## logic in data, which is the rule `TEC-006` opens with. If something needs
## logic, the trait names a value or a tag and a system reacts to it.
##
## `TEC-006` names seven traits. **One is built** — `WieldableTrait`, whose
## every field is a number the melee system already runs on. The other six
## (wearable, light, consumable, cursed, extraction, identifiable) are absent
## rather than stubbed (ADR-064): each describes a system that does not exist,
## and a trait whose fields nothing reads is a schema nobody can check. They
## arrive with the systems that give them meaning — slots at `M3-T07`,
## extraction at `M2-T04`, curses with the Barrow-Fields at `M5-T02`.


## Human-readable name for validator output. Subclasses override.
func kind() -> String:
	return "trait"


## Problems with this trait's own values, one sentence each; empty means valid.
##
## Same shape as `TuningProfile.validate()`, deliberately: a resource is the
## only thing that knows what its own fields mean, so the rule lives with the
## shape it describes rather than in a validator that has to be kept in step
## with it. Cross-resource rules — ID uniqueness, dangling references — cannot
## live here and belong to `tests/data_probe.gd`.
func validate() -> PackedStringArray:
	return PackedStringArray()
