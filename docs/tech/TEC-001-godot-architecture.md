---
id: TEC-001
title: Godot Architecture
status: accepted
owner: tech
tags: [godot, architecture, engine, systems]
updated: 2026-08-14
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

## Renderer: Forward+ (ADR-052)

> **"Mobile" is the name of a Godot *renderer*, not a platform.** An earlier note in `ART-005` implied the normal-buffer limitation was a platform problem. It is not. Target platforms are **Windows, macOS, Linux on Steam**, and Forward+ is the default and correct renderer for all three.

Godot 4 offers three rendering methods. They are **choices**, not platform assignments:

| Method | APIs | Platforms | Lights per object |
|---|---|---|---|
| **Forward+** | Vulkan · Direct3D 12 · Metal | **Desktop — Windows, macOS, Linux** | **Unlimited** (clustered) |
| Mobile | Vulkan · D3D12 · Metal | Mobile *and* desktop; default on mobile | **8** omni/spot per mesh |
| Compatibility | OpenGL 3.3 / ES 3.0 / WebGL2 | Oldest hardware, and the only option for web | 8 per mesh |

**What "Forward+" means.** *Forward* rendering computes lighting while rasterising each object, rather than deferring it to a G-buffer pass. The **+** is **clustered lighting**: the view frustum is subdivided into a 3D grid of cells, each storing the lights that touch it, so a fragment only evaluates lights in its own cell. That is what lets forward rendering handle **hundreds of simultaneous lights with no per-object limit** — classic forward rendering chokes on light count, which is historically why deferred existed.

### We would choose Forward+ anyway, independent of the shader

This is the important part. Our lighting design demands it on its own:

- **Darkness is a mechanic** (`ART-001`). The world is lit almost entirely by carried light.
- **Every player carries a lantern**, and co-op is 1–4 players — that is up to four moving point lights before anything else.
- Braziers, the Threshold fire, the ember, dropped lanterns, the Gullsjúkr's glow.

**Mobile's cap of 8 omni/spot lights per mesh would actively break this.** A corridor with four players' lanterns, a brazier, and a few dropped lights would exceed it and start dropping lights per-object — visibly, and worst exactly when the scene is most dramatic.

So Forward+ is not a compromise accepted to enable the ink shader. **It is the correct renderer for this game's lighting, and the shader's normal-buffer access comes along free.**

### What locking Forward+ actually costs

- **No web export.** Compatibility is the only renderer that supports web. We are not shipping to web.
- **A hardware floor** of roughly Vulkan 1.0 / D3D12 / Metal-capable GPUs — broadly 2012-and-later hardware. Negligible for a premium Steam title.
- Forward+ has a **higher base cost** but **lower scaling cost** than Mobile — it gets relatively cheaper as scene complexity rises, which suits a dark dungeon full of small lights.

### If we ever did need normals without Forward+

Not needed, but recorded so the question stays closed:

1. **Custom normal pass** — render the scene to a second viewport with a shader outputting view-space normals. Correct, and costs an extra full scene pass. Wasteful when Forward+ provides it free.
2. **Reconstruct normals from depth** — derive them via screen-space derivatives of reconstructed view position. Works wherever depth is available, but quality is lower: it misses smooth surface variation and is noisy at silhouettes, which is precisely where our outlines live.

## Performance targets ⟨tune⟩

60 fps at 1080p on a mid-range 2020 GPU. Budgets: ≤150 active AI agents per floor (only ~20 fully simulated, rest on a cheap LOD brain), ≤2ms/frame for clamor propagation, floor generation under 2s, ≤64 kbps up per client at 4 players (`TEC-004`).
