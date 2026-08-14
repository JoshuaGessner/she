---
id: TEC-001
title: Godot Architecture
status: draft
owner: tech
tags: [godot, architecture, engine, systems]
updated: 2026-08-12
related: [TEC-002, TEC-003, DES-005]
---

# Godot Architecture

**Engine:** Godot 4.x. GDScript primary; C# only where a profiler proves need (likely candidates: procedural generation, pathfinding, large-scale physics queries).

## Autoload budget (target ≤6)

| Autoload | Owns |
|---|---|
| `GameState` | Save data, LINEAGE + LIFE tiers, settings |
| `RunManager` | Current run lifecycle: seed, floor, timer, pressure state, extraction |
| `EventBus` | Global signals (`enemy_died`, `hunt_escalated`, `item_taken`, `extraction_started`) |
| `SaveSystem` | Versioned serialization + migration (`TEC-003`) |
| `AudioDirector` | Music state machine, dynamic mixing, the Hunt's audio takeover |
| `Config` | Tunable constants loaded from `.tres` — every `⟨tune⟩` value in the docs lands here |

`Config` matters more than it looks: **every tunable number lives in a resource file**, not in code. Balance iteration on a game like this happens hundreds of times, and recompiling logic to change a timer is how projects stall.

## Composition, not inheritance

No `Actor` → `Enemy` → `MeleeEnemy` → `Skeleton` chain. Instead, a scene assembled from component nodes:

```
Skeleton (CharacterBody3D)
├── HealthComponent        (hp, damage types, death signal)
├── HitboxComponent        (what it can hit)
├── HurtboxComponent       (what can hit it)
├── ClamorSensor           (hears noise → feeds AI + the Hunt)
├── LootDropComponent      (references a LootTable .tres)
├── AIBrain                (state machine; swappable behaviour resource)
└── Model (rigged mesh + AnimationTree)
```

Adding a new enemy = a new scene + new `.tres` data, not new inheritance. This directly serves "systems over content."

## Data-driven content (`.tres` Resources)

Custom `Resource` classes, all authorable in the editor without code:

`ItemDef` · `EnemyDef` · `LootTable` · `SkillNodeDef` · `AspectDef` · `ContractTemplate` · `Complication` · `BiomeDef` · `RoomModule` · `HazardDef` · `TuningProfile`

**Rule:** if a designer would ever want to change it, it's a Resource. Content authoring must never require touching a `.gd` file.

## Procedural generation

- **Seeded and deterministic.** One `RandomNumberGenerator` per subsystem, all derived from the run seed, so layout generation and loot rolls don't desync each other.
- **The run seed is visible and shareable** — displayed on the death screen, in bug reports, and in the run log. Non-negotiable for debugging a game like this.
- Approach: **hand-authored room modules, procedurally assembled** (Spelunky/Barony model), not fully generated geometry. Better readability, better art quality, far less generator tuning agony.
- Generation is validated: every generated floor is proven traversable, with all contract objectives and at least one extraction reachable, before the player loads in. **Fail loudly in dev, reroll silently in release.**

## The Hunt (`DES-005`) — technical shape

- Clamor is a **decaying scalar field** on a coarse grid over the floor. Actions deposit clamor; it diffuses and decays. Cheap, and produces exactly the "sound travels through the level" behaviour we want.
- The Hunter navigates the clamor gradient, not the player's transform. It genuinely does not know where you are — it knows where noise was. That's what makes counter-play real rather than performative.
- Hunter AI is a small, debuggable state machine: `Patrol → Investigate → Pursue → Lose → Patrol`, with a dev overlay visualizing the clamor field. **Build that overlay early**; this system is untunable blind.

## Multiplayer posture

> **DECIDED (ADR-008):** Co-op is core, 1–4 players, present from M1. Full architecture in **`TEC-004`**.

Consequences that bind everything in this document:
- **Authoritative host.** No client-side authority over damage, loot, or extraction.
- Route all state changes through components that *could* be RPC'd; never mutate another node's state directly.
- Prefer `_physics_process` for anything that must stay in sync.
- **Generation determinism is now bit-exact across machines**, not merely reproducible locally — the host sends a seed and clients build the identical floor rather than replicating geometry. Never consume a gameplay RNG stream from code whose call order can vary between host and client.
- The **Clamor field is host-only** and never replicated; clients receive only its effects.
- **Progression is never networked** — pacts are individual (`DES-012`), so the entire meta-layer stays local to each player's save. Protect this property.

## Performance targets ⟨tune⟩

60 fps at 1080p on a mid-range 2020 GPU. Budgets: ≤150 active AI agents per floor (only ~20 fully simulated, rest on a cheap LOD brain), ≤2ms/frame for clamor propagation, floor generation under 2s, ≤64 kbps up per client at 4 players (`TEC-004`).
