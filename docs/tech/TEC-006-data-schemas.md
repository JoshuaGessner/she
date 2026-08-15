---
id: TEC-006
title: Data Schemas
status: accepted
owner: tech
tags: [data, resources, godot, tres, schema, tooling]
updated: 2026-08-14
related: [TEC-001, TEC-002, TEC-003, DES-008, DES-013, DES-004, DES-007]
---

# Data Schemas

`CLAUDE.md` mandates **data over code**: enemies, items, skills, contracts and loot tables are Godot `Resource` files, not scripts. **A designer must be able to add an item without touching code.** This document specifies the shapes.

---

## Principles

1. **Data describes; code interprets.** A resource never contains behaviour. If something needs logic, the resource names a *tag* and a system reacts to it.
2. **Composition over inheritance.** A thin base plus a trait array, not a class tree.
3. **Stable string IDs, never resource paths.** Saves reference `"wpn_dvergar_hammer"`, not `res://...`. Moving a file must never break a save (`TEC-003`).
4. **Every resource is validatable.** A CI pass loads every `.tres` and checks required fields, ID uniqueness, and reference integrity.
5. **No numbers in code.** If it is tunable, it lives in a resource.

## The central decision: traits, not a class tree

An inheritance tree (`Item → Weapon → Sword`) is the obvious Godot approach and it is **wrong for this game**, because `DES-008` deliberately makes items occupy several categories at once:

- A **jewelled sword** is gear *and* tribute.
- A **grave-good** is tribute *and* cursed *and* it aggros a Draugr.
- A **lantern** is a light source occupying a weapon slot.
- A **Waystone** is an extraction device that is also loot you can lose.

An inheritance tree forces these into one bucket and then needs escape hatches everywhere. So:

> **`ItemResource` = core physical facts + an array of trait resources.**

```gdscript
class_name ItemResource extends Resource

@export var id: StringName            # "wpn_dvergar_hammer" — stable, unique, permanent
@export var display_name: String
@export var description: String

# The four axes from DES-008 — every item has all four
@export var weight: float             # movement, stamina  (DES-005)
@export var clamor: float             # aggro radius, Hunt escalation
@export var grid_size: Vector2i       # inventory footprint (DES-019)
@export var tribute_value: int        # Boon if given to her (DES-004)

@export var traits: Array[ItemTrait]  # what it can DO
@export var tags: Array[StringName]   # "dvergar", "grave_good", "metal"
```

**Traits** are small resources, each adding one capability:

| Trait | Adds |
|---|---|
| `WieldableTrait` | damage type, arc, wind-up/active/recovery timings, stamina cost, Clamor per swing |
| `WearableTrait` | slot, armour class (unarmoured / mailed / plated), encumbrance |
| `LightTrait` | radius, colour, fuel, whether it can be dropped lit |
| `ConsumableTrait` | effect tag, use time, whether usable in combat |
| `CursedTrait` | curse tag, what triggers it, whether it can be dropped |
| `ExtractionTrait` | Waystone behaviour — cap of one, not tributable (ADR-015) |
| `IdentifiableTrait` | unknown until appraised; what Lineage reveals it |

A jewelled sword is `[Wieldable]` with a high `tribute_value`. **No new class needed.** That is the whole point.

---

## Enemies

`DES-013` defines enemies by **role** and multiplies variety by **modifiers**, so the schema mirrors that exactly:

```gdscript
class_name EnemyResource extends Resource

@export var id: StringName
@export var display_name: String
@export var role: Role                # ALARM, ATTRITION, BLOCKER, TRACKER,
                                      # GUARDIAN, FAUNA, ELITE
@export var faction: StringName       # "dvergar", "draugr", "vaettir", "bound"

@export var health: float
@export var attacks: Array[AttackResource]
@export var senses: SenseProfile       # hearing radius, Clamor sensitivity,
                                       # sight cone, wealth sensing (DES-017)
@export var armour_class: ArmourClass  # feeds the cut/pierce/blunt triangle

@export var scene: PackedScene         # visual + collision only, no logic
@export var allowed_modifiers: Array[EnemyModifier]
```

```gdscript
class_name AttackResource extends Resource

@export var id: StringName
@export var telegraph_ms: int   # >= 250, standard 400-600 (ADR-053)
@export var active_ms: int
@export var recovery_ms: int
@export var damage: float
@export var damage_type: DamageType
@export var clamor: float
```

> **The validator enforces `telegraph_ms >= 250`.** ADR-053 makes this a hard rule from human reaction time, and a rule that isn't checked is a rule that erodes. **CI fails the build if an attack telegraphs faster than a person can react.**

**Modifiers** (`GildedModifier`, `SilentModifier`, `RousedModifier`…) are separate resources that mutate an enemy at spawn. ~8 modifiers × ~12 archetypes is where variety comes from — not from 40 hand-authored enemies.

## Skills

```gdscript
class_name SkillNodeResource extends Resource

@export var id: StringName
@export var aspect: Aspect           # HOARD, CINDER, SCALE, WING, MAW
@export var tier: Tier               # KEYSTONE, GREATER, LESSER, RITE
@export var rite_class: StringName   # RITE nodes only — which class owns it
@export var boon_cost: int
@export var tithe_increase: int      # power raises obligation (DES-003)
@export var requires: Array[StringName]
@export var effect_tags: Array[StringName]   # systems react to these
```

**`effect_tags` is where the discipline lives.** A node declares `"carry_no_limit"` and the inventory system reacts. The node never contains logic. This keeps `DES-004`'s "no node is purely numeric" rule enforceable — a node with only a numeric field and no tag is a stat stick, and reviewable as such.

## Contracts

`DES-007` generates contracts as `archetype × target × location × complication × faction × reward`, so the resources are the *parts*, not the instances:

```gdscript
class_name ContractArchetypeResource extends Resource
@export var id: StringName
@export var kind: Kind                    # RETRIEVE, CULL, ESCORT, SURVEY, DENIAL, RIVAL
@export var text_variants: Array[String]  # per-faction voice, with {slots}
@export var objective_tags: Array[StringName]

class_name ComplicationResource extends Resource
@export var id: StringName
@export var text: String
@export var applies_to: Array[Kind]
@export var effect_tags: Array[StringName]
```

**Complications get the authoring effort** — ~20 good ones generate more perceived variety than 100 hand-written quests.

## Loot tables

```gdscript
class_name LootTableResource extends Resource
@export var id: StringName
@export var entries: Array[LootEntry]     # item, weight, count range, depth bias
@export var value_curve: Curve            # value vs floor depth — the greed gradient
```

The greed gradient (`DES-008`) is a `Curve`, so it is tunable in the editor without touching code.

---

## Conventions

**File layout** (`TEC-002`):
```
game/data/items/…   enemies/…   skills/…   contracts/…   loot/…   biomes/…
```

**ID prefixes:** `wpn_` `arm_` `con_` `glt_` `rlc_` `mat_` · `enm_` `mod_` · `skl_` `rit_` · `ctr_` `cmp_` · `lut_`

**Enums live in one autoload-free `Enums.gd`** with `class_name`, so resources and systems share definitions without a dependency tangle.

**Never `@export` a raw `Resource`** where a typed subclass will do — typing is what makes the editor usable as a design tool.

## Validation (CI)

A `tools/validate_data.py`-equivalent (or a Godot headless script) runs on every commit and fails on:

- Duplicate or missing `id`
- `telegraph_ms < 250` (ADR-053)
- Dangling `requires` references in skill nodes
- Items with `tribute_value > 0` and zero `weight` *and* zero `clamor` — free money, always a bug
- Keystone nodes with no `effect_tags` — a stat stick (`DES-004`)
- Loot entries referencing nonexistent items

> **Build this with the first ten resources, not the first thousand.** Data corpora rot silently, and every one of these checks encodes a design rule that would otherwise erode unnoticed.

## Open questions

> **OPEN (Q103):** Do trait resources ever need per-instance state (a lantern's remaining fuel, a weapon's condition)? Resources are shared by default in Godot — **instance state must live in a separate runtime object keyed by item instance ID**, or two lanterns will share one fuel value. Decide the runtime-instance model before the first stateful item.

> **OPEN (Q104):** Localisation — `display_name` and `description` as raw strings, or keys into a translation table? Keys cost nothing now and are painful to retrofit. **Leaning keys from the start.**
