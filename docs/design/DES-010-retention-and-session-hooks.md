---
id: DES-010
title: Retention, Session Hooks & Churn Points
status: proposed
owner: design
tags: [retention, hooks, session, onboarding, churn, pacing]
updated: 2026-08-12
related: [DES-002, DES-003, DES-007, PRO-001]
---

# Retention, Session Hooks & Churn Points

Stash-wipe-on-death (ADR-004) is the right balance decision and a **retention liability**. This document is the counterweight. It exists because retention in a roguelite is not a marketing concern bolted on at the end — it is a *design* concern, and it is mostly about **where players quit and why**.

## The rule everything else serves

> **Every run pays. Every session ends mid-thought. Every death is a scene.**

## Named churn points

The professional lens: don't ask "is the game fun," ask "at which specific minute do people stop playing." For this design, there are five, and each needs a designed answer.

### C1 — The first 10 minutes (largest absolute churn)
The player doesn't yet understand extraction, tribute, Clamor, or the Hunt. Four systems is too many to meet at once.

**Answer:** the first run is a **guaranteed-survivable descent** with the Hunt disabled and a single contract. Teach *loot → weight → exit* only. Tribute, Aspects, and the Hunt are introduced across runs 2–4, one per run. She narrates, because a patron explaining her demands is diegetic tutorialization at zero UI cost.

### C2 — The first death (largest *emotional* churn)
The player loses a stash they'd been building. This is the moment we lose people permanently.

**Answer:** the death sequence is **authored content, not a fail screen.**
1. **What you learned** — bestiary, cartography, lore gained *this run*, itemized (ADR-006).
2. **She speaks** — she grieves, briefly and genuinely, and remembers your name.
3. **The Legacy choice** — three slots, a real decision from your actual stuff (ADR-003).
4. **The lineage counter ticks over.** You are the 4th of your line. That number never resets.

The first death should also be **partly scripted**: she has a specific speech the first time, which reframes death as the thing the pact was always going to cost. Turn the churn moment into the moment the story starts.

> The design test: a player's first death should make them want to see *her* again, not to see their stash again.

### C3 — The mid-life grind (runs ~10–25)
Novelty has faded, the Tithe is climbing, and runs risk becoming routine.

**Answer:** this is what **contract chains and faction arcs** are for (`DES-007`). Pacts (tier 1) give a life a through-line, so there's always a multi-run goal in flight. Also where **first-time-only** discoveries should be seeded — a new floor layout, a Rival who recurs, a locked vault you can't open yet.

### C4 — The Tithe default spiral
A player falls behind, takes a debuff, falls further behind. Death spirals are how extraction games lose their most invested players.

**Answer:** the Tithe must be **forgiving on the way down**. Missing a cycle costs standing and a debuff, never a cascade. Consider a **debt state** she offers rather than imposes — *"Go deeper for me and we'll call it even"* — which converts a spiral into a quest. **Design rule: it must always be possible to dig out in one good run.**

### C5 — The post-mastery plateau
The player has seen the biomes and beaten the systems.

**Answer:** deliberately deferred past 1.0, but the hook exists — **Pact Ranks the player cannot safely sustain**, self-imposed vows for higher Tithe, and Hunters that can finally be fought (`DES-005`). Note the shape: the endgame is *voluntary escalation of obligation*, not new numbers. Consistent with Pillar P3.

## Session hooks

**Never let a session end on a clean note.** The Settle beat (`DES-002`) resolves the run and immediately plants the next: a contract that expires in 2 runs, a Rival who took what you wanted, a vault door you now have a key for, a Whisper you had to abandon.

**The abandoned-loot hook.** Caches (`DES-005`) are the strongest natural one in the design: *my gold is still down there.* Cheap to build, enormously sticky, and thematically perfect. Worth prioritizing early for this reason alone.

**Lineage as the slow bar.** Always moving, never resets, never grants power. The thing that makes hour 40 feel different from hour 4 without making it easier.

## What we will not do

Stated now, because these get proposed later under commercial pressure:

- **No daily login rewards.** Obligation is not retention; it's how a game becomes a chore.
- **No FOMO-timed events.** Rotating *variety* is fine — a per-day dungeon modifier ("the Wyrm's Whim") is cheap and good. Rotating *rewards you permanently miss* is not.
- **No battle pass, no monetized progression.** This is a premium game.
- **No artificial grind gates.** If a player wants Pact Rank 6, the barrier is risk (`DES-003`), never repetition.
- **No "energy" or run limits.** Ever.

The retention model here is that **the loop is good and the pact is a relationship you want to continue.** If it needs psychological scaffolding to hold players, the loop is broken and scaffolding will only delay the diagnosis.

## Metrics to instrument at M2 ⟨tune⟩

Instrument early — retention questions are unanswerable from vibes:

- Deaths per session, and **run number of first death**
- **Session-end reason**: extracted / died / quit mid-run (quit-after-death is the churn signal that matters most)
- Loot voluntarily abandoned per run — *the single best proxy for whether the core tension is working*
- Tithe default rate by Pact Rank
- Legacy slot usage: item vs. node ratio (validates ADR-003)
- % of runs ending in extraction — target ⟨tune⟩ 55–70%; below 40% the game is too punishing to retain, above 80% the pressure isn't real
