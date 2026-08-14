---
id: PRO-001
title: Roadmap & Milestones
status: draft
owner: process
tags: [roadmap, milestones, scope, planning, production]
updated: 2026-08-12
related: [DES-001, TEC-001, TEC-003]
---

# Roadmap & Milestones

**Philosophy:** prove the *feel* before building the *systems*. This game lives or dies on one sentence — *"I have enough. I should leave. One more room."* Everything before that sentence is provably fun is speculative work.

The most common way a project like this dies is building the meta-progression first, because it's the most fun part to design. **Do not.** The meta-layer is worthless if the run isn't good.

---

## M0 — Design Lock (current)
**Goal:** a signed-off design document set.
**Exit:** `DES-001` through `DES-008` at status `accepted`; `OPEN-QUESTIONS.md` empty of blocking items.
**Deliverable:** these docs.

> **Reordered by ADR-008.** Co-op is no longer a late milestone — it is a constraint on every milestone. Networking exists from M1.

> **DECIDED (ADR-034): solo project, no fixed timeline.** Calendar estimates are removed — on a solo project they produce guilt rather than throughput, and the **exit gates were always the real mechanism.** They are pass/fail on the game being good, never on elapsed time.
>
> Sizes below are *relative effort only*. The one piece of discipline that still matters without a deadline forcing it: **clear a milestone's exit gate before starting the next one.**

## M1 — The Feel Prototype  ·  *smallest milestone*
**Goal:** answer "is moving and fighting in this space enjoyable?" — with grey boxes and zero content.
- First-person controller: walk, sprint, crouch, stamina, weight affecting movement
- One weapon, one enemy, hit reactions, death
- One hand-built room set, no generation
- Weight & Clamor as visible debug numbers
- **Two players over localhost**, host-authoritative (`TEC-004`)
- **Networking spike test — go/no-go:** 4 peers, ~150 synchronized entities. This validates or kills the whole Godot high-level-multiplayer approach, and it must happen now rather than at M4.
- **Determinism harness in CI**: same seed on two processes → identical layout hash

**Exit gate:** *two people who aren't you play for 10 minutes and ask to keep playing.*
**If this fails, nothing else matters.** Iterate here as long as needed. Do not proceed on hope.

## M2 — The Loop Prototype  ·  *~1.5× M1*
**Goal:** prove the target sentence.
- Loot with weight and clamor; inventory (prototype both models, Q23)
- The Hunt: clamor field, **the Gullsjúkr** (`DES-017` — wealth-sensing, gold-baiting, the whole point), escalation, the Sealing (`DES-005`)
- **The Ear + adaptive audio driver** (`DES-018`, ADR-035/036) — both channels together, from the first build
- **Standing test from here on: every milestone must be playable to completion with audio muted**
- Extraction: reach an exit, keep what you carried
- Death: lose it all — plus **downed state and ember rescue** (`DES-012`)
- Minimal Lair: stash and re-descend
- **Party scaling instrumented from the first build**: per-capita extracted value at 1/2/4 players

**Exit gate:** a playtester **voluntarily abandons loot to survive**, then talks about it afterwards. That's the whole game in one moment. If it doesn't happen, the pressure system is wrong, not the content.
**Co-op gate:** someone carries a friend's ember out and it is the best moment of the session.

## M3 — The Pact  ·  *~2× M1*
**Goal:** prove meta-progression makes runs *more* interesting, not easier.
- Tribute → Boon → Aspects; two Aspects fully implemented, three stubbed
- **Two classes fully implemented** (recommend Húskarl and Veiðimaðr — opposite loop relationships), four stubbed (`DES-011`)
- **Boon cap by own rank** (ADR-011) — must exist before mixed-rank parties are tested
- Tithe and Pact Rank escalation (`DES-003`)
- Death → Legacy selection screen, with the "what you learned" panel first (ADR-006)
- Save system with versioning and migration from day one (`TEC-003`)

**Exit gate:** a rank-8 player and a rank-1 player both die at similar rates for different reasons. Verify against the `DES-003` balance guardrails.
**Co-op gate:** a rank-8 player brings a rank-1 friend into a rank-8 floor (ADR-010). The newcomer is downed repeatedly and *still wants to go again*. If they don't, the ember rescue isn't doing enough work.

## M4 — Vertical Slice  ·  *largest; art and audio dominate*
**Goal:** one biome, complete and polished, representative of the final game.
- The Delvings: full generation from room modules, 3 floors
- ~6 enemy archetypes, 2 hazard types
- **All six classes playable**
- Contracts tier 1–3, one faction (`DES-007`)
- Real art pass, real audio, real UI, ping system
- Full save/load, settings, controls rebinding
- **Steam networking integration** (lobbies, invites, relay) — before any external playtest

**Exit gate:** shippable-quality 45 minutes, played solo *and* as a 4-stack. This is what a publisher, a Steam page, or a Kickstarter would see.

## M5 — Content & Breadth
Remaining biomes, factions, Aspects, enemies. Balance passes against real telemetry, at every party size.

## M6 — Ship
Store page, IP attorney review (`PRO-004`), demo, playtesting at scale, launch.

---

## Standing risks

| Risk | Severity | Mitigation |
|---|---|---|
| Meta-progression trivializes runs | **High** | Tithe counter-pressure (`DES-003`); guardrail tests at M3 |
| Scope creep via biomes/enemies | **High** | Hard caps in `DES-001`; systems over content |
| Procedural levels feel samey | Medium | Hand-authored modules, not generated geometry (`TEC-001`) |
| Save migration retrofit | Medium | Versioning from commit one (`TEC-003`) |
| Hunt is annoying rather than tense | Medium | Counter-play tools first, not last; heavy M2 playtesting |
| Solo-dev burnout | **High** | Milestone gates with real exit criteria; ship the slice before breadth |
| IP exposure | Low (if `PRO-004` followed) | Guardrails + pre-launch legal review |
| **Godot high-level multiplayer doesn't scale to our object counts** | **High** | M1 spike test is an explicit go/no-go (`TEC-004`) |
| **Co-op roughly doubles QA surface** | **High** | Automated 2-client smoke tests in CI from M1; accept slower milestones rather than skipping the tests |
| Class balance across 6 classes × 5 Aspects | Medium | Shared tree + small Rite branches (ADR-009) keeps the surface small; every class solo-viable is a hard rule |

## Estimates are lies

The ⟨week⟩ figures assume roughly one focused full-time developer and are **optimistic by the usual factor**. Treat ordering as the real content of this document; treat durations as relative weights, not commitments.
