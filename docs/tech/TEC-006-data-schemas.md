---
id: TEC-006
title: Data Schemas
status: accepted
owner: tech
tags: [data, resources, godot, tres, schema, tooling]
updated: 2026-08-17
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
# Translation keys, not English (ADR-084 closes Q104). data/locale/en.csv holds
# the strings, so `display()` returns real text and the retrofit never happens.
@export var name_key: StringName      # "item.wpn_dvergar_hammer.name"
@export var description_key: StringName

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
| `ExtractionTrait` | Waystone behaviour — cap of one, not tributable (ADR-015). **Built at `M2-T04`**, second of the seven, and for the same reason `WieldableTrait` was: its system now exists. `Inventory` enforces the cap rather than trusting loot never to offer a second — `M4-T01`'s tables are generated, and generated things offer seconds |
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

`game/tests/data_probe.gd` runs in the pre-commit sweep (`tools/check_scripts.sh`) and fails on:

- Duplicate or missing `id`, an `id` outside the prefix set, or a file not named after its `id` — **built** (`M2-T08`)
- ~~Items with `tribute_value > 0` and no weight and no clamor — free money~~ — **deleted (ADR-089), and the deletion is the point.** ADR-088 first had to repair it: it lived on `ItemResource` as `is_zero_approx(weight)`, which compares against 0.00001, so any non-zero weight defeated it — including the 0.04 kg gemstone it was written about, proved by zeroing that gem's clamor and watching the validator pass 55 tribute for nothing. Then `M2-T02` closed the hole **in the design rather than in the validator**: the Gullsjúkr senses carried tribute through walls (`DES-017`), so every valuable item now costs something by construction — it makes you legible to the thing hunting you, whatever it weighs. The rule could no longer fail, and a check whose premise the design has made unfalsifiable is precisely the green tick the note below warns about. Removed rather than weakened into something that always passes
- A resource with no `validate()`, or whose own `validate()` reports a problem — **built**
- **Finding zero items at all** — **built**, and the most important one: every other rule is conditional on there being data, so without it a moved folder produces a clean, meaningless pass
- `telegraph_ms < 250` (ADR-053) — *not built*: `AttackResource` arrives at `M4-T02`. The floor is enforced today in `TuningProfile.validate()`, where its data actually lives
- Dangling `requires` references, and keystone nodes with no `effect_tags` (`DES-004`) — *not built*: `SkillNodeResource` arrives at `M3-T01`
- Loot entries referencing nonexistent items — *not built*: `LootTableResource` arrives with loot spawning
- An item whose `grid_size` cannot fit the inventory grid in **either** orientation — it is authored, it validates, and it can never be picked up — **built** (`M2-T01`), now that a grid exists to measure against
- **The catalogue's view of the corpus disagreeing with the walk's** — **built** (`M2-T01`). The probe walks `.tres` with `DirAccess`; `ItemCatalogue` is what the *running game* asks. Two scans of one folder is the arrangement that rots silently, so they are compared rather than trusted — and this is the rule that fires on the ADR-086 failure, where a build shipped an empty item table and launched perfectly

> **A rule arrives with its data (ADR-084).** Writing a check against an empty folder produces a green tick that cannot fail, which is worse than no check — it convinces the next reader the ground is covered. `M1-T05` shipped two such checks and only found them by planting violations.

**Rules live on the resources**, as `validate() -> PackedStringArray`, the same shape `TuningProfile` uses: only a resource knows what its own fields mean. The probe owns just the questions no single resource can answer — uniqueness, and whether the corpus exists.

> **Build this with the first ten resources, not the first thousand.** Data corpora rot silently, and every one of these checks encodes a design rule that would otherwise erode unnoticed.

## Open questions

> **CLOSED (Q103, ADR-084): a carried item is an `ItemInstance`, not an `ItemResource`.** The resource is the shared, immutable definition and is never mutated at runtime; an `ItemInstance` is one carried thing — a reference to its definition, a per-instance id, its grid position, and any mutable state. Inventories hold instances. Saves store the instance id plus the **stable string id**, never a path (`TEC-003`). Decided at `M2-T08`, **built at `M2-T01`** with the inventory that first needs it.
>
> As built it is a **`RefCounted`, not a `Resource`** — which makes the separation structural rather than a convention: there is no path to load one from, nothing caches it, and two instances of one item are two objects however they were made. It carries `instance_id`, `definition`, `cell` and `rotated`, and **no `condition` or `fuel` field**: neither has a system yet, and a field nothing reads is the stub ADR-064 bans. The class is fully justified without them, because two altar-plates in one bag are already the same definition in two different squares.

> **`ItemCatalogue` is how a stable string id becomes an `ItemResource`** (`M2-T01`). Principle 3 says saves hold `"glt_altar_plate"` and never a path, so something has to map one to the other, and this is the only place that does. It matches `.tres`, `.res` **and** `.remap`, because Godot re-serialises text resources when it packs them — a scan matching only `.tres` finds **zero items in a shipped build** while `load()` on the original path keeps working, which is what makes it silent (ADR-086).

> **CLOSED (Q104, ADR-084): keys, and they are built.** `name_key` and `description_key` are translation keys; `data/locale/en.csv` is loaded as a Godot translation, so English displays today. It cost one CSV and one project setting at ten items.
