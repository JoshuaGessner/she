---
id: DES-005
title: Extraction Pressure — The Hunt
status: proposed
owner: design
tags: [pressure, pacing, extraction, tension, ai]
updated: 2026-08-12
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
- Weight → slower movement, shorter stamina, louder footfalls, worse dodge.
- Clamor → wider aggro radius, faster Hunt escalation.
- **You feel your greed in your legs.** The single most important feedback loop in the game.

*Why this layer:* it means the extraction decision starts at minute one, not at the timer. Even a "safe" run is constantly asking "is this worth carrying?"

### Layer 2 — The Hunt (escalating, timed, embodied)

At ~⟨tune⟩ 12–15 minutes, or when the floor's Clamor threshold is crossed (whichever first), **the dragon's rivals notice you.** A hunter entity enters the level.

- **Announced with an unmissable diegetic beat:** horn, distant collapse, torches guttering out ahead of it, the ambient track dropping to just breathing.
- The Hunter **tracks by Clamor**, not by omniscience — so it is *playable against*. Drop loot to go quiet. Take a longer, quieter route. Bait it into a trapped room. Hide and let it pass.
- It **cannot be killed** at first, only delayed, blinded, or trapped ⟨tune⟩. Later Pact ranks may unlock the ability to fight one — a fantastic mid-game power fantasy beat, and a reason to want a rank you can't safely carry.
- **Escalation:** if you stay, a second Hunter joins, then the floor begins to close (exits sealing one by one — see Layer 3).

*Why an entity rather than a timer:* it satisfies requirements 3 and 5 completely, gives the audio/animation team a hero asset worth investing in, and produces stories. "The timer hit zero" is not a story. "It heard my coins and I dropped every gold piece I had to get out" is the game.

**Reference:** the Nemesis in *Resident Evil 3*, the Mr. X patrol loop in *RE2 Remake*, the Alien in *Alien: Isolation*, DMZ's escalating exfil pressure. Note that all three horror examples work by being *unkillable and audible* — that's the exact combination we want.

### Layer 3 — The Sealing (hard floor, prevents infinite camping)

> **REWRITTEN BY ADR-015.** Extraction is now a **resource** problem, not a routing problem.

A run is all three floors (ADR-015). Leaving before the bottom is possible on every floor, but it must be *earned* — there are three ways out, and they cost different things:

| Means | Where | Cost |
|---|---|---|
| **Waystone** | Rare found item ⟨tune⟩ | Portable, instant, consumed. **Spending it is choosing to end the run now, with what you have.** |
| **The Shaft** | One fixed mechanism per floor, location known | Reliable but dangerous and loud — a real place you must reach and survive |
| **The Deep Gate** | Floor 3 only | Guaranteed. The destination. |

**The Sealing now bites differently:** as the Hunt escalates, **the Shafts seal, floor by floor.** Staying doesn't strand you — it makes your *cheap* exit disappear and pushes you toward the Deep Gate at the bottom, deeper into the thing you were trying to leave.

This is a strict improvement on the old model. It means:
- **The means of escape is loot.** A Waystone in your bag is a decision you carry around, and it competes for a slot.
- **"Can I leave?" becomes a resource question**, answerable at a glance, and it's a *different* question from "where is the exit?"
- The player is never truly trapped — the Shaft is always reachable, just increasingly expensive.
- **No hard "you die at 30:00" wall.** The player is never killed by a clock; they are killed by the consequences of one. (Principle 4.)

**Waystone drop rate is a primary tuning lever** ⟨tune⟩: too common and the pressure evaporates; too rare and players are shoved to floor 3 every run whether they wanted it or not.

### Layer 3b — Gates open both ways (ADR-016)

The same mechanism that takes you out lets someone in. A player waiting in the Lair can **open a gate at the party's current position and step through** — no menu, no teleport, they walk out of the dark next to you (`DES-012`).

**Opening a gate is a loud Clamor event.** Reinforcements announce themselves to the dungeon. That's the cost, it's diegetic, and it makes "should we call them in *here*, or push to somewhere quieter first?" a genuine tactical question.

## Counter-play & tools

Pressure must have counters, or it's a tax rather than a system:

- **Drop loot** — the primal one. Instantly reduces weight and clamor. The choice to abandon treasure to survive should happen in *every* good run.
- **Cache it** — stash loot in a hidden spot for a later run ⟨tune⟩. Hugely evocative ("my gold is still down there"), and a strong hook. Needs a persistence design (`TEC-003`).
- **Wrap it** — consumables (cloth, wax, muffling sacks) that reduce clamor at a cost.
- **Bait & misdirect** — throw a noisy item to pull the Hunter. Cheap to implement, enormous player satisfaction.
- **Wing Aspect** — a whole skill path built around beating this system (`DES-004`).

> **RESOLVED by ADR-015:** the Shaft's location is known per floor; Waystones are found. Q8 closed.

> **OPEN:** Does the Hunt persist across floors, or reset per floor? Persisting is far scarier and makes descent a real commitment; resetting is more forgiving and easier to tune. Leaning **persists, but loses you between floors if you're quiet** ⟨tune⟩. **Now more pointed under ADR-015** — a three-floor run means a persistent Hunt has a very long time to escalate.

## What we're deliberately not doing

- **No hidden timer.** Ever.
- **No instant-death storm circle.** Battle-royale closing rings are legible but non-interactive; they fail requirement 3.
- **No unavoidable damage-over-time.** Corruption/decay pressure is a *Maw Aspect* opt-in, not a baseline mechanic — baseline attrition punishes exploration, which we want to encourage in the first half of a run.
