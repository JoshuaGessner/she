---
id: DES-005
title: Extraction Pressure — The Hunt
status: accepted
owner: design
tags: [pressure, pacing, extraction, tension, ai]
updated: 2026-09-02
related: [DES-002, DES-007, DES-008]
---

# Extraction Pressure — The Hunt

The brief: *"something that pushes you towards exit."* This is the mechanism that produces the game's target sentence — **"I have enough. I should leave. One more room."** It deserves more care than any other single system.

## Design requirements

1. **Legible.** The player must always know how much pressure exists and roughly how long they have. Invisible pressure produces frustration, not tension.
2. **Escalating, not binary.** A timer that does nothing and then kills you teaches nothing. Pressure should degrade your options continuously.
3. **Interactable.** The player should be able to *fight, delay, hide from, or exploit* the pressure. A number counting down is not gameplay.
4. **Greed-coupled.** Carrying more loot must make pressure worse. This is Pillar P1 made mechanical.
5. **Diegetic.** It should be a thing in the world, not a HUD element. In first person, a *pursuer* reads infinitely better than a clock.

## The proposal: three-layer pressure

### Layer 1 — Weight & Noise (continuous, player-caused)

Pressure you generate yourself, immediately and legibly.

- Every item has **weight** and **clamor** (loudness). Coin is heavy and loud; gems are light and silent; a suit of plate is a catastrophe of both.

> **A gemstone is silent, and it still costs you (ADR-089).** *"Light and silent"* is now literal — `glt_raw_gemstone` has no clamor at all. Its price is the one `DES-008` always named: **the Gullsjúkr feels carried tribute through walls** (`DES-017`), so a pocketful of gems is a lantern to the thing hunting you however quietly you move. That is what makes weight and clamor the *physical* costs of greed rather than the only ones.
- Weight → slower movement, shorter stamina, louder footfalls, worse dodge.
- Clamor → wider aggro radius, faster Hunt escalation.
- **You feel your greed in your legs.** The single most important feedback loop in the game.

> **DECIDED (ADR-087):** **carried clamor is a floor your noise decays *to*, not a constant it adds.** A rich player standing perfectly still is never silent — coin shifts, a gem catches every light in the dark — but they are heard from ⟨tune⟩ 3.4 m rather than 13.6 m. That distinction is load-bearing: the constant-addition version was checked and it puts a full glitter bag permanently inside enemy vision range, which deletes *"hide and let it pass"* from the counter-play list below. As a floor it does the opposite — it is precisely what makes **dropping the loot buy silence back**, in the same frame.

*Why this layer:* it means the extraction decision starts at minute one, not at the timer. Even a "safe" run is constantly asking "is this worth carrying?"

### Layer 2 — The Hunt (escalating, timed, embodied)

> **Full treatment now lives in `DES-017` (ADR-037).** The Hunter is the **Gullsjúkr** — a former Bound who stayed too long, still carrying their hoard, still trying to make a Tithe that can no longer be made. It hunts **carried wealth**, and it **stops to pick up gold you throw**. Q9 is resolved there: the Hunt persists across floors.

At ~⟨tune⟩ 12–15 minutes, or when the floor's Clamor threshold is crossed (whichever first), **the dragon's rivals notice you.** A hunter entity enters the level.

- **Announced with an unmissable diegetic beat:** horn, distant collapse, torches guttering out ahead of it, the ambient track dropping to just breathing.
- The Hunter **tracks by Clamor**, not by omniscience — so it is *playable against*. Drop loot to go quiet. Take a longer, quieter route. Bait it into a trapped room. Hide and let it pass.
- It **cannot be killed** at first, only delayed, blinded, or trapped ⟨tune⟩. Later Pact ranks may unlock the ability to fight one — a fantastic mid-game power fantasy beat, and a reason to want a rank you can't safely carry.
- **Escalation:** if you stay, a second Hunter joins, then the floor begins to close (exits sealing one by one — see Layer 3).

*Why an entity rather than a timer:* it satisfies requirements 3 and 5 completely, gives the audio/animation team a hero asset worth investing in, and produces stories. "The timer hit zero" is not a story. "It heard my coins and I dropped every gold piece I had to get out" is the game.

**Reference:** the Nemesis in *Resident Evil 3*, the Mr. X patrol loop in *RE2 Remake*, the Alien in *Alien: Isolation*, DMZ's escalating exfil pressure. Note that all three horror examples work by being *unkillable and audible* — that's the exact combination we want.

### Layer 3 — The Sealing (hard floor, prevents infinite camping)

> **REWRITTEN BY ADR-015.** Extraction is now a **resource** problem, not a routing problem.
>
> **DEFERRED TO `M2-T04` (ADR-089).** The Sealing seals Shafts, and Shafts are what `M2-T04` builds. It was listed under `M2-T02` with the rest of the Hunt; building it there would have meant inventing an extraction point inside a pressure task, ahead of the task that owns it. The Hunt itself — field, Gullsjúkr, escalation — landed at `M2-T02` without it.
>
> **BUILT AT `M2-T04`, and it resolved a contradiction in this section (ADR-091).** The table below says Shafts *seal*; the guarantee further down says the Shaft is *always reachable*. Both hold across three floors, where sealing floor 1 pushes you down and down is still a way out. On one floor a sealed Shaft is a locked door with nothing beneath it — the trapping ADR-015 forbids.
>
> So the Sealing is built as the **guarantee**, not the table:
>
> > **The Shaft never locks. It gets worse.**
>
> Escalation multiplies the channel time *and* the noise ⟨tune⟩ — measured at 4.0 s / 5.0 clamor early against **12.8 s / 16.0 late**. Leaving late means standing exposed in a known location, for longer, screaming, with the Gullsjúkr already coming. Floor-by-floor locking needs floors and arrives with them at `M4-T01`. `--exit-probe` fails if the Shaft ever becomes unusable, which is precisely what a lock-shaped Sealing would do.
>
> **And floor-by-floor locking is not what arrived (ADR-186).** The floors landed at `M4-T01` and the contradiction resolved the other way: the Shaft is the way **down** now, so "the Shafts seal, floor by floor" would seal the route to the Deep Gate and strand a party with no Waystone — the trapping ADR-015 forbids, reached by the opposite road. ADR-091's guarantee stands unchanged and is now load-bearing in a second way: **the Shaft never locks, it gets worse.** Sealing is entirely a cost curve on the descent, and `--exit-probe`'s refusal to let the Shaft become unusable is the check that keeps it one.

A run is all three floors (ADR-015). Leaving before the bottom is possible on every floor, but it must be *earned*.

> **REVISED (ADR-186) — two ways out, and the Shaft is not one of them.**
>
> The table below listed **three** exits and two of them did the same job. The Shaft and the Waystone were both *leave early*, differing only in whether you walk to the exit or carry it — and `MissionGraph.Role.SHAFT` had described the Shaft as *"the way down, **and out**"* since the graph was written, with only the second half ever built.
>
> **The Shaft is now the way down.** It is how you reach floor 2 and floor 3, and on the bottom floor it is the Deep Gate's mechanism. It never extracts you from anywhere else.
>
> **The Waystone is now the only early exit**, which is what stops it being redundant. This is the resolution the obvious reading gets backwards: cutting the Waystone and keeping the Shaft as an exit would have removed the only exit a player can **give away** — and `DES-014` calls that *"the single best payoff available in this design"* (*the person you saved saves you, because you gave away your own way out six hours ago*). `DES-016` already has a deed for a Waystone you never spent.

| Means | Where | Cost |
|---|---|---|
| **Waystone** | Rare found item ⟨tune⟩ | Portable, instant, consumed. **Spending it is choosing to end the run now, with what you have.** The only way out above the bottom. |
| **The Shaft** | One fixed mechanism per floor, location known | **The way down.** Reliable but dangerous and loud — a real place you must reach and survive, and taking it commits the whole party a floor deeper. |
| **The Deep Gate** | Floor 3 only | Guaranteed. The destination, and the only exit that is *always* there. |

**The Sealing now bites differently:** as the Hunt escalates, using the Shaft gets slower and louder. Staying doesn't strand you — it makes going deeper more expensive and leaves you further from the Deep Gate at the bottom, deeper into the thing you were trying to leave.

This is a strict improvement on the old model. It means:
- **The means of escape is loot.** A Waystone in your bag is a decision you carry around, and it competes for a slot.
- **"Can I leave?" becomes a resource question**, answerable at a glance, and it's a *different* question from "where is the exit?"
- The player is never truly trapped — the way **down** is always usable, just increasingly expensive, and down is a way out because the bottom holds the Gate.
- **No hard "you die at 30:00" wall.** The player is never killed by a clock; they are killed by the consequences of one. (Principle 4.)

**Waystone drop rate is a primary tuning lever** ⟨tune⟩: too common and the pressure evaporates; too rare and players are shoved to floor 3 every run whether they wanted it or not. **ADR-186 makes this more load-bearing, not less** — it is now the *only* dial controlling how often a run can end before the bottom, and it is the single biggest risk the change carries.

### Layer 3b — Gates open both ways (ADR-016)

The same mechanism that takes you out lets someone in. A player waiting in the Lair can **open a gate at the party's current position and step through** — no menu, no teleport, they walk out of the dark next to you (`DES-012`).

**Opening a gate is a loud Clamor event.** Reinforcements announce themselves to the dungeon. That's the cost, it's diegetic, and it makes "should we call them in *here*, or push to somewhere quieter first?" a genuine tactical question.

## Counter-play & tools

Pressure must have counters, or it's a tax rather than a system:

- **Drop loot** — the primal one. Instantly reduces weight and clamor. The choice to abandon treasure to survive should happen in *every* good run. **Built at `M2-T01`, and measured:** putting down the heaviest thing you carry returns ⟨tune⟩ +24% walking speed and 1.6 m of quiet, in the frame you let go of it.
- **Cache it** — stash loot in a hidden spot for a later run ⟨tune⟩. Hugely evocative ("my gold is still down there"), and a strong hook. Needs a persistence design (`TEC-003`).
- **Wrap it** — consumables (cloth, wax, muffling sacks) that reduce clamor at a cost.
- **Bait & misdirect** — throw a noisy item to pull the Hunter. Cheap to implement, enormous player satisfaction.
- **Wing Aspect** — a whole skill path built around beating this system (`DES-004`).

> **RESOLVED by ADR-015:** the Shaft's location is known per floor; Waystones are found. Q8 closed.

> **DECIDED (ADR-037):** **The Hunt persists across floors.** Descending grants nothing — going quiet and shedding carried value can shake it, but a staircase cannot. Descent is a commitment (`DES-017`).

## What we're deliberately not doing

- **No hidden timer.** Ever.
- **No instant-death storm circle.** Battle-royale closing rings are legible but non-interactive; they fail requirement 3.
- **No unavoidable damage-over-time.** Corruption/decay pressure is a *Maw Aspect* opt-in, not a baseline mechanic — baseline attrition punishes exploration, which we want to encourage in the first half of a run.
