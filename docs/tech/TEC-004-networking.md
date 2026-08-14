---
id: TEC-004
title: Networking Architecture
status: proposed
owner: tech
tags: [networking, multiplayer, godot, co-op, architecture, risk]
updated: 2026-08-12
related: [DES-012, TEC-001, TEC-003, PRO-001]
---

# Networking Architecture

> **DECIDED (ADR-008):** Co-op is core. 1–4 players. This document exists because retrofitting multiplayer is a rewrite, and we are explicitly refusing to take that risk.

## The single most important consequence

**Networking is not a milestone. It is a constraint on every milestone.**

The M1 feel prototype ships with **two players connected over localhost**, even though it's a grey box with one enemy. Not because co-op matters at M1, but because every system written after that point gets written against a network boundary that already exists. The cost of this is roughly a week at M1; the cost of deferring it is measured in months at M4.

## Model

**Host-authoritative peer-to-peer.** One player hosts and simulates; clients send input and render.

- **No dedicated servers.** Not defensible for a premium PvE game with no PvP integrity requirements.
- **No client authority** over damage, loot acquisition, extraction, or progression. Not for anti-cheat — this is co-op, and cheating mostly harms the cheater — but because a single authority is dramatically simpler to reason about and debug.
- **Client-side prediction for local movement only.** Everything else is host-authoritative with interpolation. Melee combat in a PvE game tolerates ~80ms latency well; do **not** build rollback or lag compensation. That complexity buys nothing here.

## Transport

**Godot 4 high-level multiplayer** (`ENetMultiplayerPeer`, `MultiplayerSpawner`, `MultiplayerSynchronizer`, `@rpc`) as the baseline.

**Steam networking (GodotSteam / Steam Datagram Relay) for shipping.** This matters more than it looks: raw ENet peer-to-peer requires NAT traversal that will fail for a meaningful share of players, and "my friend can't connect" is a review-score problem. Steam's relay solves NAT punchthrough, lobbies, invites, and friend lists in one dependency.

> Architect the transport behind a thin interface from day one so ENet (dev, fast iteration) and Steam (ship) are swappable. Do not scatter Steam API calls through gameplay code.

## What replicates, and what doesn't

The seeded generator (`TEC-001`) pays off enormously here.

| Data | Approach |
|---|---|
| **Level geometry** | **Not replicated.** Host sends the seed; every client generates an identical floor. Requires bit-exact determinism in generation — already a requirement, now load-bearing. |
| Player transforms | Synchronized, interpolated, locally predicted |
| Enemy transforms & state | Host-authoritative, synchronized, interpolated |
| **Clamor field** | **Host only.** Never replicated — it's a coarse grid updated continuously and would dominate bandwidth. Clients receive only its *effects* (Hunt state, enemy alerts). |
| Hunt / Hunter state | Host-authoritative, replicated as compact state |
| Loot in world | Host-authoritative spawn, replicated; **pickup is a host-validated request** |
| Inventories | Host-authoritative; each client sees only its own in detail |
| Progression (Boon, tree, Tithe) | **Never networked.** Local to each player's own save (`DES-012` — pacts are individual). Host reports run outcomes; each client writes its own profile. |
| Contract state | Host-authoritative, replicated |

**The progression row is the important one.** Because pacts are individual (`DES-012`), the meta-layer stays almost entirely out of the network — a large, permanent reduction in complexity that falls directly out of a *design* decision. Worth protecting if the design is revisited.

## Determinism requirements

Generation must be **bit-exact across machines**, which is stricter than "reproducible on my machine":

- One `RandomNumberGenerator` per subsystem, all seeded from the run seed.
- **Never** consume RNG in code whose call order can vary (a client-only visual effect must not draw from a gameplay RNG stream).
- Avoid float accumulation in generation logic; prefer integer/grid math where layout is decided.
- **Validation harness:** generate the same seed on two processes, hash the resulting layout, assert equality. Build this at M1 and run it in CI. It is much cheaper than debugging a desync at M4.

## Save & crash behaviour

Extends `TEC-003`:
- Each client owns its own `profile.save`. The host never writes another player's progression.
- **Run outcome is host-reported, client-committed.** The host tells you that you extracted with X; your client writes it.
- **Host disconnect = forced extraction for everyone** (`DES-012`). Clients hold enough local state to commit a run outcome without the host. This must be tested by killing the host process, not by a clean quit.
- Ember rescue (`DES-012`) means **another player's death outcome depends on host state** — get the authority chain right early and test it deliberately.

## Budgets ⟨tune⟩

- 4 players, ~150 active AI per floor, ≤64 kbps up per client
- Enemy replication uses **relevance filtering** — don't synchronize AI in unloaded parts of the level to players who can't see it
- Target playable at 120ms RTT; comfortable at 60ms

## Risk register

| Risk | Severity | Mitigation |
|---|---|---|
| `MultiplayerSynchronizer` performance at high object counts | **High** | **Spike test at M1** — 4 peers, 150 synchronized entities, measure. This is the assumption most likely to be wrong. |
| Generation desync | High | Determinism harness in CI from M1 |
| NAT traversal failures | Medium | Steam relay before any public build |
| Host advantage / client latency feel | Medium | Predict local movement; keep melee forgiving |
| Co-op QA cost (roughly 2× everything) | **High** | Automated 2-client smoke tests in CI; budget for it in `PRO-001` |

## The hub: Chamber vs Threshold (ADR-021)

The Lair is two scenes with opposite networking postures, and getting this right is what keeps progression off the wire.

| | Chamber | Threshold |
|---|---|---|
| Scope | Per-player, private | Per-party, shared |
| Networked | **Never** | Yes |
| Contains | Her, hoard, skill tree, stash, Legacy screen | Bound camp, Lodge, contract board, forge, Descent |
| Simulation | None worth the name | None worth the name |
| Replicated | Nothing | Avatars, presence, ready-state, pings |

**Implementation notes:**
- The Chamber is a **fully local scene**. It does not exist on other peers. No spawner, no synchronizer, no RPCs.
- A player may drop from the Threshold to their Chamber and back **mid-lobby** without touching party state. Treat it as a local scene swap, not a disconnect.
- Threshold cosmetic state (camp density, NPC population) derives from **the host's lineage** — a single replicated integer, not a state sync.
- **Host disconnect in the Threshold dissolves the party back to solo Thresholds.** Nothing is at risk; there is no run state. Do not build host migration for the hub — it isn't worth it.
- Progression writes happen in the Chamber, locally, to that client's own `profile.save`. This is the property that keeps the entire meta-layer off the network; **protect it if the hub design is revisited.**

## Join-in-progress (ADR-016)

> **Reverses this document's earlier lean.** Late join is now core, not post-launch.

A player waiting in the Lair opens a gate at the party's position and steps through (`DES-005` Layer 3b). Built on the extraction mechanism run backward, which is why it's affordable — but it is still the most demanding networking feature in the project.

**Geometry is free.** The joiner has the seed and generates the identical floor (already required). What must be synchronized is the **world delta** — everything that has changed since generation:

| Delta | Notes |
|---|---|
| Looted containers & taken pickups | Largest volume; store as a compact set of touched IDs, not full item state |
| Dead / despawned enemies | Same — IDs, not entity dumps |
| Opened, broken, or barred doors | Cheap |
| Alert states & current Clamor snapshot | Coarse; joiner does not need history |
| Hunt / Hunter state | Compact, already replicated |
| Contract & objective progress | Compact |
| Sealed Shafts (`DES-005`) | Cheap |
| Destructible / collapsed geometry | **Only if Q52 lands.** This is the row that could get expensive — a mid-run mutating level makes the delta unbounded. Weigh that when deciding Q52. |

**Design constraints that also protect the implementation:**
- The joiner **brings no accumulated loot** — arrival state is trivially clean.
- **Opening a gate is a loud Clamor event**, so arrival is diegetically costly *and* gives the host a natural beat to complete the sync behind.
- Gate opening should tolerate a ⟨tune⟩ sync window — the animation covers the transfer.

**Test target:** a 4th player joins a floor-3 party ~20 minutes into a run, on a floor with ~200 looted containers and ~80 dead enemies, without a hitch on the host. Build this test at M2, not M4.

> **OPEN:** Delta growth over a long run is the risk. If the touched-ID sets grow unbounded across three floors, consider discarding deltas for floors the party has left — a joiner arriving on floor 3 does not need floor 1's state, since nobody can return there.

> **OPEN:** Godot 4's high-level multiplayer may not hold at our object counts. The M1 spike is a **go/no-go on the whole approach** — the fallback is hand-rolled state replication over ENet, which is significantly more work and needs to be known early, not discovered at M4.
