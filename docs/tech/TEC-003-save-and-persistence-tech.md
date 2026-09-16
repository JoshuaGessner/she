---
id: TEC-003
title: Save System & Persistence Implementation
status: accepted
owner: tech
tags: [save, persistence, serialization, migration, tech-debt]
updated: 2026-09-16
related: [DES-003, DES-015, TEC-001, TEC-002, TEC-004]
---

# Save System & Persistence Implementation

`DES-003` defines *what* persists. This defines *how*. Building it correctly on day one is one of the highest-leverage decisions available on this project — save migration retrofitted later is genuinely one of the worst jobs in game development.

> **As built at `M3-T06`** (ADR-116, ADR-117). Everything below is the specification and it stands. Two things about *when*:
>
> - **The schema is only as wide as the state that exists**, and grows one version per `M3` task. The section diagram below is the destination, not v1 — writing its fields now, for systems that do not exist, is the stub ADR-064 bans. v1 is `meta`, `lineage` and `life`; `legacy` arrives with `M3-T05`, `pact_rank` and `run_count` with `M3-T04`. By `GATE M3 EXIT` the migration path will have run for real seven times against saves that genuinely existed.
> - **`user://run.active` is `M3-T09`, not `M3-T06`.** ADR-050's *"dropping out of a co-op run leaves you a Vörðr"* has no referent until the Vörðr exists, and building suspend/resume before `M3-T09` builds it against a run structure that task is about to change.
>
> Implemented as `SaveFile` (`class_name`, static) plus `GameState.to_dict/from_dict`. **Not an autoload**, on the `Settings` precedent and ADR-066: `TEC-001` budgets six and names `SaveSystem` among them, but an autoload is for something with a node's life and this has none.

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

## One machine, one running copy

> **DECIDED (ADR-159):** **`user://` belongs to a machine, and only one copy of the game runs on it.** Co-op is between machines. Two copies on one machine is not a supported configuration and **nothing guards against it**.

`user://` is derived from the project name, not from the process, so two copies resolve `profile.save` and `run.active` to the same bytes. Writes are atomic, so there is no torn file — but two lives writing one profile is last-writer-wins, and nothing would say so.

The alternative was a guard: a lock file, or a second instance refusing to start. That is a system built for a configuration nobody uses, and `ADR-064` calls this shape correctly — a **gate decision**, one path chosen once and the other never built, rather than a fallback to maintain.

**If the assumption is ever broken, this is what it looks like:** a profile that loses a tithe, a rank, or a stash entry with no crash and no error, because the other copy wrote last. Recognise it by that signature rather than chasing it as a save-corruption bug.

**The one place two copies do run is `tools/run_coop.py`**, whose windowed mode launches a host and a client side by side for solo playtesting. That is a harness rather than the game, and since ADR-155 every launched process gets its own `HOME` and therefore its own `user://` — so the exception exists, is named, and is already separated.

## What a player touches (`M4-T06`)

> **DECIDED (ADR-246):** **One lineage, set aside only on purpose; a profile this build will not open is said wherever a player stands.**

- **Named without being opened.** `SaveFile.standing()` reads the profile's version and its lineage totals and answers `none`, `readable`, `newer` or `unreadable` — quietly, because the menu asks every time it draws; `read()` is still the one that reports what is wrong, when a descent opens the file.
- **Abandoned by a held button**, for `TuningProfile.abandon_hold_seconds`, only for a `readable` profile. `SaveFile.abandon()` **renames** it to `profile.save.abandoned.<unix time>` and deletes nothing; `GameState.forget_the_lineage()` closes the open run with it and resets the process to a lineage nobody has lived. One slot: returning to an abandoned lineage is a rename by hand.
- **A refused profile plays unsaved and says so** — on the menu, at the camp, in the Chamber and in the Deep — in words.

## Preferences are not the save

`user://settings.cfg` (`Settings`) holds volumes, look and fullscreen, and since ADR-245 a `[bindings]` section: per action, per device (`keys`, `pad`), **only what the player changed**, each input as a small dictionary (`kind` and its code, button or axis and sign). A file from before rebinding has no section and reads as the defaults; a kept input that no longer builds is skipped rather than unbinding its verb. Not versioned, no migrations — a preference file a later build cannot read costs a player their bindings, not their lineage. Probes write `settings.probe.cfg` by name (`Settings.PROBE_PATH`).

## Run state (separate from profile)

Mid-run state lives in a separate `user://run.active` file so a crash or quit mid-run can be resumed rather than silently converted into a death.

> **DECIDED (ADR-050):** **Suspend with forced resume.** Quitting mid-run suspends; you resume into the same run. **Dropping out of a co-op run leaves you a Vörðr** (`DES-012`), so disconnecting is never an escape from a bad run.

> **`floor` and `seed` added at `M4-T01`** (ADR-184, save v2). *Autosave on state transitions* above has always listed **floor transition** as one of them, and until `M4` there were no floors to transition between. `floor` is depth into **this expedition**, 0–2 — never `GameState.descents`, which counts what a *lineage* has done and would roll floor 47 on somebody's forty-eighth run. `seed` is which expedition it is, and it is not optional decoration: `stripped` claims *you have already been through here*, and "here" is only a place if the seed that built it comes back with the index. A resume that re-rolled would strip a floor nobody had walked.
>
> **The host rolls the seed and the descent RPC carries it.** Every peer builds its own floor geometry, so the number they derive it from must be agreed; `Threshold._descend` is already `authority`/`call_local`, so this cost no new wire (ADR-184 Decision 3).
>
> **No migration path, deliberately, and this file is the exception to the rule above.** `read()` drops a run file whose version it does not know. Keeping an unreadable one blocks every future descent; dropping it costs a single run. The profile takes the opposite decision for the opposite reason — a lineage is not replaceable (ADR-117).
>
> **`wounds` and `dazed` added at `M4-T14`** (ADR-239), beside `health`, and **without a version bump**: they are read with defaults, and a run file written before wounds existed carries none, which is true of it. Dropping a live run for a field that has an honest default would cost a player the run to learn nothing.
>
> **The profile's `life.scars` added at `M4-T14`** (ADR-240, **save v11**) — a bit per wound the life carried out of the Deep. `_migrate_10_to_11` writes `0`, because no wound existed to scar when a v10 profile was written; `--save-probe` round-trips two of the three bits and loads a literal v10 fixture over a life dirtied with all three.
>
> **The profile's `life.lodge` added at `M4-T04`** (ADR-241, **save v12**): trust, favour, the contracts taken as `{archetype, grade}` rows, and the favours owed. `_migrate_11_to_12` writes an empty Lodge, because no board existed to take work from. The run file gains `met`, `retrieve` and `plan` beside the wounds, on the same default-reading rule and with the same reason: a run a contract was met in keeps the answer through a quit.
>
> **The profile's `life.demand` added at `M4-T04`** (ADR-243, **save v13**): `{id, given}` — what she named at the oath and how many of it this life has given; met is derived. `_migrate_12_to_13` writes it empty, and `GameState.from_dict` has her name one for a life already sworn, so an old life is not left with its pact nodes shut behind a question nobody asked. A demand this build lacks is dropped with a warning.
>
> **`barrow` added at `M4-T04`** (ADR-242), per floor like `stripped` and cleared by `descend()`: whether this floor's barrow has woken. A run quit after the barrow opened resumes onto a barrow that is spent — dark, silent and empty — rather than sealed and full again. Read with a default, no version bump.

## Caches (`DES-005`)

Player-hidden caches persisting between runs need a stable identity across procedurally regenerated floors. Store as `(biome, floor_depth, room_module_id, anchor_id)` and have the generator honour a request to place that specific module. Do this deliberately — it's a genuine constraint on the generator and needs to be in from the start, not bolted on.

> **DECIDED (ADR-050):** **No — caches are LIFE tier and die with you.** A Legacy slot may still be spent to carry *the knowledge of where they were*, which is a good use of a slot and thematically exact.
