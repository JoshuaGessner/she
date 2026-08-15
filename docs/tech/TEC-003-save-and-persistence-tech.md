---
id: TEC-003
title: Save System & Persistence Implementation
status: accepted
owner: tech
tags: [save, persistence, serialization, migration, tech-debt]
updated: 2026-08-14
related: [DES-003, TEC-001, TEC-002]
---

# Save System & Persistence Implementation

`DES-003` defines *what* persists. This defines *how*. Building it correctly on day one is one of the highest-leverage decisions available on this project — save migration retrofitted later is genuinely one of the worst jobs in game development.

## Save file structure — mirror the design tiers

The three-tier design (`DES-003`) maps directly onto three save sections. That alignment isn't cosmetic: **death is implemented as "delete the LIFE block, keep the LINEAGE block, move Legacy across."** Nothing else. That's a one-function operation, easy to reason about, easy to test, and impossible to get subtly wrong.

```
user://profile.save
├── meta        { save_version, build_hash, created, playtime }
├── lineage     { bestiary, cartography, recipes, contacts, world_scars,
│                 dragon_memory, lifetimes_count, legacy_slots_unlocked }
├── life        { pact_rank, tithe_state, boon, skill_tree, stash,
│                 faction_standing, scars, run_count }
└── legacy      { slots: [ {type, payload, scar_modifier} × N ] }
```

## Versioning & migration (build this first)

```gdscript
const SAVE_VERSION := 1

# Ordered migrations; each takes a dict at version N and returns version N+1.
# Never delete a migration. Never mutate an old one.
const MIGRATIONS := {
    1: "_migrate_1_to_2",
}
```

Rules:
- Every save carries `save_version`. On load, run migrations forward in order.
- **Never** remove or edit a shipped migration — players load from arbitrary old versions.
- **Back up before migrating.** `profile.save.bak.<version>`. Cheap insurance.
- Unit-test every migration against a stored fixture of the previous format. These are the most valuable tests in the project (`TEC-002`).

## Format

**JSON, uncompressed, during development** — human-readable saves make balance and bug work dramatically faster. Switch to `FileAccess.open_compressed` or binary near release if size warrants.

**No `store_var`/`get_var` with objects, ever.** Serialize to plain dictionaries explicitly. Godot's built-in object serialization is brittle across engine versions and a known source of save corruption. Every persistent type gets explicit `to_dict()` / `from_dict()`.

**No anti-tamper theatre.** Single-player PvE; a player editing their save harms nobody. Don't spend effort here — but *do* validate on load so a malformed save fails gracefully instead of half-loading into a corrupted state.

## Write policy

- **Autosave on state transitions**, not on a timer: run start, floor transition, extraction, death, any Lair action.
- **Atomic writes**: write to `profile.save.tmp`, then rename. A crash mid-write must never destroy a profile.
- **Death writes are the critical path.** Test that a hard kill (task-kill the process) during the death sequence never produces a half-wiped profile — either the life ended cleanly or it didn't end.

## Run state (separate from profile)

Mid-run state lives in a separate `user://run.active` file so a crash or quit mid-run can be resumed rather than silently converted into a death.

> **DECIDED (ADR-050):** **Suspend with forced resume.** Quitting mid-run suspends; you resume into the same run. **Dropping out of a co-op run leaves you a Vörðr** (`DES-012`), so disconnecting is never an escape from a bad run.

## Caches (`DES-005`)

Player-hidden caches persisting between runs need a stable identity across procedurally regenerated floors. Store as `(biome, floor_depth, room_module_id, anchor_id)` and have the generator honour a request to place that specific module. Do this deliberately — it's a genuine constraint on the generator and needs to be in from the start, not bolted on.

> **DECIDED (ADR-050):** **No — caches are LIFE tier and die with you.** A Legacy slot may still be spent to carry *the knowledge of where they were*, which is a good use of a slot and thematically exact.
