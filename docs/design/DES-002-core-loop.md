---
id: DES-002
title: Core Loop
status: accepted
owner: design
tags: [core-loop, structure, pacing, session]
updated: 2026-08-14
related: [DES-001, DES-003, DES-005, DES-006]
---

# Core Loop

## The three nested loops

```
LINEAGE  ─ many lifetimes ─────────────────────────────────────────┐
  │  knowledge, bestiary, cartography, world state persist forever │
  │                                                                │
  └─ LIFE ─ one pact, many runs ────────────────────────────┐      │
       │  skill tree, Tithe rank, stash, dragon standing    │      │
       │  ends at: DEATH                                    │      │
       │                                                    │      │
       └─ RUN ─ 15–30 min ⟨tune⟩ ─────────────────┐         │      │
            Descend → Loot → Contract → Extract   │         │      │
            ends at: EXTRACT (keep) or DEATH      │         │      │
            ──────────────────────────────────────┘         │      │
                                                   ─────────┘      │
                                            ───────────────────────┘
```

This three-tier structure is the single most important structural decision in the game, because it's what lets meta-progression exist without trivializing runs (Pillar P5, Principle 1). Full treatment in `DES-003`.

## The RUN loop (moment to moment)

**1. Prepare (Lair, ~2 min).**
Load out from your stash. Accept contracts (see `DES-006`). Pay or defer your Tithe. Choose your descent point — deeper entries mean better loot, higher Tithe satisfaction, and much higher lethality.

**2. Descend (0–5 min).**
Low pressure. Orientation, early loot, reading the floor. The game teaches you what kind of run this is: what factions are active, what hazards seeded, what the modifiers are.

**3. Commit (5–15 min).**
The meat. Contract objectives are deeper than the easy loot. This is where you decide how greedy to be. Pressure begins accumulating (`DES-005`).

**4. Break point (~15 min ⟨tune⟩).**
An event fires that makes staying materially worse — the Hunt begins, the light fails, the vaults seal. The player now has a concrete "leave or commit harder" decision with a legible cost. **This is the beat the whole game is built around.**

**5. Extract (2–5 min).**
Movement toward an exit under pressure, carrying weight. Extraction is a *journey*, not a button — the walk out must be the tensest part of the run.

**6. Settle (Lair, ~2 min).**
Tribute what you're willing to give the dragon → Boon (skill points). Bank what you keep → stash. Contracts resolve, faction standing shifts, new contracts appear. The hook for the next run is planted here.

## Why PvE-only (defending the choice)

DMZ's tension had two sources: the environment/AI and other players. We take the first and refuse the second. Reasons:

- **Cost.** PvP extraction demands netcode quality, anti-cheat, matchmaking, and population — each a project-killer at our scale.
- **Design clarity.** Pillar P1 says *your greed* is the antagonist. Player killers muddy that: deaths become "I got jumped" rather than "I stayed too long," violating Principle 4.
- **Audience.** Barony's audience is co-op/solo comfort-food crawl. Tarkov's audience is not the same audience and is well served already.

**Note (ADR-024):** dead players in your own party become **Vörðr** — Barony-style ghosts who keep playing, then choose between rescue and return (`DES-012`). That is a *live* co-op system, distinct from the asynchronous presence below.

**Adopted instead:** *asynchronous* player presence — the corpses, ghosts, warnings, and abandoned hoards of other players' failed runs appear in your dungeon as lootable, informative, occasionally hostile echoes. Souls-style messaging and Spelunky-style ghost-of-a-past-run. Gets the "other people are out here" texture at ~5% of the cost.

> **DECIDED (ADR-050):** Echoes are **local-only first** — your own past corpses, not other players'. Avoids the economy faucet and the server dependency; cross-player echoes stay a post-launch option.

## Session shape

A "sitting" is 3–6 runs (~90 min), which should be roughly one **Tithe cycle** — you emerge from a session having either advanced your pact rank or dug yourself into debt. Sessions need their own arc, not just a chain of identical runs.

## Failure states

| Outcome | Lose | Keep |
|---|---|---|
| **Extract clean** | Nothing | Everything carried + contract rewards |
| **Extract wounded** | Carried weight over your limit; a lasting Scar | The rest |
| **Death** | Run inventory + LIFE tier (stash, skill tree, rank) | LINEAGE tier + Legacy slots (`DES-003`) |
| **Tithe default** | Dragon standing, a punitive debuff, possibly a skill node reclaimed | Everything else — you're alive, just in trouble |

The **Tithe default** state is important: it's a soft-fail that keeps a bad session recoverable, so death isn't the only consequence in the game.
