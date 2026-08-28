---
id: TEC-004
title: Networking Architecture
status: accepted
owner: tech
tags: [networking, multiplayer, godot, co-op, architecture, risk]
updated: 2026-08-28
related: [DES-012, TEC-001, TEC-003, PRO-001]
---

# Networking Architecture

> **DECIDED (ADR-008):** Co-op is core. 1–4 players. This document exists because retrofitting multiplayer is a rewrite, and we are explicitly refusing to take that risk.

## The single most important consequence

**Networking is not a milestone. It is a constraint on every milestone.**

The M1 feel prototype ships with **two players connected over localhost**, even though it's a grey box with one enemy. Not because co-op matters at M1, but because every system written after that point gets written against a network boundary that already exists. The cost of this is roughly a week at M1; the cost of deferring it is measured in months at M4.

## Model

**Host-authoritative peer-to-peer.** One player hosts and simulates; clients send input and render.

> **The split, stated exactly (ADR-082):** **the owning peer is authoritative over its own body's transform; the host is authoritative over every consequence.**
>
> This paragraph used to say "client-side prediction for local movement" one line above "do not build rollback or lag compensation", which cannot both be satisfied — prediction with no reconciliation is not prediction, it is authority. The exclusion list below was always the real specification, and movement was never on it.

- **No dedicated servers.** Not defensible for a premium PvE game with no PvP integrity requirements.
- **No client authority** over damage, loot acquisition, extraction, or progression. Not for anti-cheat — this is co-op, and cheating mostly harms the cheater — but because a single authority is dramatically simpler to reason about and debug.
- **A client simulates its own legs and nothing else.** Melee combat in a PvE game tolerates ~80ms latency well; do **not** build rollback or lag compensation. That complexity buys nothing here, and under the split above nothing needs correcting, so no reconciliation path exists to build.

## Transport

**Godot 4 high-level multiplayer** (`ENetMultiplayerPeer`, `MultiplayerSpawner`, `MultiplayerSynchronizer`, `@rpc`) as the baseline.

**Steam networking (GodotSteam / Steam Datagram Relay) for shipping.** This matters more than it looks: raw ENet peer-to-peer requires NAT traversal that will fail for a meaningful share of players, and "my friend can't connect" is a review-score problem. Steam's relay solves NAT punchthrough, lobbies, invites, and friend lists in one dependency.

> Architect the transport behind a thin interface from day one so ENet (dev, fast iteration) and Steam (ship) are swappable. Do not scatter Steam API calls through gameplay code.

## Where the boundary lives (`M1-T05`)

"Networking is a constraint on every milestone" is only true if the boundary is somewhere findable. It is `game/systems/net/coop_session.gd` — **the only place a peer is created, and the only place an actor is spawned.** Levels hand it their spawn points and ask it for enemies; they never instantiate a player.

**Single-player is a host with zero peers, and it costs nothing.** Measured on 4.7: with no peer ever assigned Godot installs an `OfflineMultiplayerPeer`, `get_unique_id()` is 1, `is_server()` is true, and `MultiplayerSpawner.spawn()` works. So solo runs the same code as a host nobody has joined, and there is no offline path to drift out of sync with the real one (ADR-064). **`has_multiplayer_peer()` returns `true` with no peer**, so it can never mean "am I networked" — ask `multiplayer.get_peers()` who is there and `is_server()` who decides.

**Damage becomes host-authoritative in exactly one line**, in `Hitbox`: no peer but the host resolves an overlap. One gate rather than a guard at every call site.

```bash
python3 tools/run_coop.py            # two windows, host on keyboard, client on pad
python3 tools/run_coop.py --smoke    # headless, two processes, judged
```

**The probe builds its floor; it never inherits one (`M2-T07`, ADR-096).** It empties the level on connect and spawns exactly the enemy each phase needs, immediately before that phase needs it — then clears the floor again for the rescue. This is not making the test easy. Party scaling broke the smoke in five places at once and **none of them were replication faults**: extra bodies shoved each other apart, 2.55× clamor walked every enemy off its post before the strike phase swung at it, and the floor got dangerous enough that the *host* was beaten down before it could offer a hand. Two of those failed **quietly**, by hitting a different body than they meant to.

A body half a second old cannot have wandered, and that holds at any party size. The rule this leaves behind: **an authority probe must control everything except the authority it is measuring** — and every sample must be taken at the moment its claim is made, not at report time, which is the same mistake ADR-093 caught for enemy speeds and ADR-096 found still sitting in three more fields.

**A connection outlives a scene change, and a session adopts one rather than building another (ADR-101).** The peer lives on the `SceneTree`, not on `CoopSession`, so every doorway tore down one session and built the next **on top of a live connection** — calling `create_server` on a port it already held. `Couldn't create an ENet host`, and both players left holding a connection nobody was serving. **Every doorway in the game was a disconnect while the entire sweep was green**, because `run_coop.py` never changes scene and no single-process probe has a second peer to lose. `tools/run_doorway.py` makes two processes walk through a door and asserts they are both still there.

The party also **descends together**: the hole is the host's decision, because each peer changing scene on its own left one player in the Deep and everybody else at the fire watching a world nobody was simulating. The Chamber stays per-player (ADR-021).

**A failed join returns to the menu with a reason — never a quit.** During a remote test a bad address is the most common event there is, and closing the process teaches a tester nothing. Godot's own `connection_failed` never fired at all against a dead port in fifty seconds of frames, so there is an 8-second ⟨tune⟩ deadline of our own and a line on screen while it waits.

**Two kinds of doorway, and the second one is where the bugs live (ADR-102).** A transition the *party* takes together and a transition *one player* takes are different problems, and a test covering the first will not cover the second. Everything about a private door — a Chamber — is per-peer: who despawns, who re-spawns, whose `GameState` the haul lands in, and which seat they come back wearing.

The rules that fell out of it:

* **A private room is an overlay, never a scene change.** Peers cannot stand in different levels — the host owns the world, and a client in a scene the host is not in has nothing to receive. `MultiplayerSpawner` replicates spawns as they happen and never the existing world to an already-connected peer, so a client that leaves and returns gets nothing.
* **Leaving the world is a despawn, not a hide.** An invisible body still collides, still holds a doorway, still makes noise, still holds a seat.
* **A private subtree gets its own peerless `MultiplayerAPI`.** Keeping a `CoopSession` out of it is not enough once it floats above a live connection: the body inside is local and will happily RPC the host. One multiplayer instance with no peer makes it structural for every RPC anybody writes later.
* **Seats are keyed to the peer.** A despawn/respawn must not change who you are, because `party_slot` is what tells one ember from another.

**The smoke is also the only place party count is real (ADR-097).** `_start_host()` spawns the host's own body and nothing else; every other body arrives on `peer_connected`, after the level has already built its floor. So anything derived from *how many people are playing* is computed against a party of one in every single-process test, however carefully that test is written — and party scaling shipped dead for exactly one commit because of it. A single-process probe proves a function; **only a second process proves the game calls it.** The floor row exists to catch that whole class, not just the one instance of it.

## What replicates, and what doesn't

The seeded generator (`TEC-001`) pays off enormously here.

| Data | Approach |
|---|---|
| **Level geometry** | **Not replicated.** Host sends the seed; every client generates an identical floor. Requires bit-exact determinism in generation — already a requirement, now load-bearing. |
| Player transforms | Owned by the peer playing them (`MotionSync`) — position, yaw, pitch, stance, grounded |
| Player health, carried weight, clamor | Owned by the host (`StateSync`). One body, two synchronisers, two authorities — ADR-082 |
| Enemy transforms & state | Host-authoritative, synchronized, interpolated (ADR-102 — described here from the first draft and not actually built until then) |
| **Clamor field** | **Host only.** Never replicated — it's a coarse grid updated continuously and would dominate bandwidth. Clients receive only its *effects* (Hunt state, enemy alerts). **Not the same thing as a `ClamorSource`'s scalar level**, which is one float per actor, derived on the host for *every* body from the motion it can see, and replicated back down so your own audible-footprint overlay and the ears that heard you cannot disagree. |
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
- **Co-op is between machines.** One running copy per machine, because `user://` belongs to the machine and not to the process — stated once in `TEC-003`, not restated here. Unguarded by decision (ADR-159); `tools/run_coop.py`'s two-window playtest launch is the named exception and separates its own save directories.
- **Run outcome is host-reported, client-committed.** The host tells you that you extracted with X; your client writes it.
- **Host disconnect = forced extraction for everyone** (`DES-012`). Clients hold enough local state to commit a run outcome without the host. This must be tested by killing the host process, not by a clean quit.
- Ember rescue (`DES-012`) means **another player's death outcome depends on host state** — get the authority chain right early and test it deliberately.

## Budgets ⟨tune⟩

> **Measured at `M1-T06` (ADR-068).** The numbers below are no longer estimates. Godot 4.7, one host + three clients on loopback, 150 spawned entities, position at 20 Hz.

- 4 players, ~150 active AI per floor, **≤64 kbps host upstream per party member**. Clients send only input and are nowhere near any limit — the host's upstream is the constraint that decides whether four players work.
- **Relevance filtering is load-bearing, not an optimisation.** Replicating all 150 agents costs **528 kbps/client — 8× the budget.** The budget and the agent count are compatible only under `TEC-001`'s LOD split (~20 of 150 fully simulated): that measures **44 kbps/client**, with ~45% headroom. **The ceiling is ~29 moving entities** at 20 Hz.
- **ENet range coder compression is required, not optional.** One line at transport setup, and it roughly halves cost (94 → 44 kbps at 20 moving agents).
- Target playable at 120ms RTT; comfortable at 60ms. **Untested** — the M1 spike is loopback only, so latency, jitter and loss are `M4-T07`'s question.

### Replication mode is a per-property choice (ADR-068)

Two engine behaviours that are easy to get wrong and expensive when you do:

- **`ON_CHANGE` properties travel the *delta* channel**, which has its own `delta_interval`, defaulting to *every network frame*. Setting only `replication_interval` leaves deltas running at the physics rate — a silent 4× bandwidth cost.
- **For continuously-moving values, `ON_CHANGE` costs more than `ALWAYS`** (711 vs 528 kbps measured), because delta encoding adds overhead and never elides anything. Use `ON_CHANGE` for state that genuinely idles, `ALWAYS` for things that always move. Decide per property.

## Risk register

| Risk | Severity | Mitigation |
|---|---|---|
| ~~`MultiplayerSynchronizer` performance at high object counts~~ | ~~High~~ | **Closed by `M1-T06` (ADR-068).** Measured: 0.2–0.9 ms host physics for 150 synchronised entities, 91% of requested update rate delivered. **CPU was never the constraint.** The real one is bandwidth, and it is decided by relevance filtering — see Budgets. |
| Generation desync | High | Determinism harness in CI from M1 |
| NAT traversal failures | Medium | Steam relay before any public build |
| Host advantage / client latency feel | Medium | The peer simulates its own movement (ADR-082); keep melee forgiving |
| ~~Co-op QA cost (roughly 2× everything)~~ | ~~High~~ | **Mitigated at `M1-T05`.** `tools/run_coop.py --smoke` runs a host and a client as separate processes in the pre-commit sweep and compares what each *independently* saw — party membership, agreed positions, who resolved a hit, who simulated an enemy, who heard whom. The only check in the sweep that exercises a second process, which is the only way any of this is checkable. |

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

> **CLOSED — GO (ADR-068, `M1-T06`).** Godot 4's high-level multiplayer holds at our object counts. The fallback, hand-rolled state replication over ENet, is **not taken and will not be built** (ADR-064: a gate decision, not a maintained alternative). Reproduce with `python3 tools/run_net_spike.py`.
