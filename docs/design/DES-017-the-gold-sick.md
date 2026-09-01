---
id: DES-017
title: The Gold-Sick — the Hunter
status: accepted
owner: design
tags: [hunter, pressure, ai, theme, clamor, extraction]
updated: 2026-09-01
related: [DES-005, DES-013, DES-008, DES-014, DES-018]
---

# The Gold-Sick — the Hunter

**Gullsjúkr** *(Old Norse: gold-sick)*. Players will call it the Gilded, or just *it*.

---

## What it is

> **A Bound who never left.**

Someone who took the pact, went down, and stayed too long. Their Tithe outran them. They didn't die and they didn't get out — they are still down there, **still carrying their hoard, still trying to make a payment that can no longer be made.**

It is enormous with it. Coin fused into what used to be armour. It moves badly because of the weight and it will not put any of it down.

**It hunts you because you have gold, and it needs gold.** That's the whole motivation, and it never gets explained.

### Why this instead of "the dragon's rivals"

The previous version was a generic pursuer imported from other games. This one **is the theme, walking around**:

- It's doing exactly what you're doing. It just did it for longer.
- **You are looking at your own future**, and the game never says so (ADR-020, rule 1).
- It explains its own mechanics — why it tracks wealth, why it can be bought off, why it can't stop.
- It connects to the NPC Bound (ADR-027): **a Gullsjúkr can be someone you knew.** Their stave is at camp. Their fire went out three sessions ago. There is something in the Delvings wearing their coat.

That last one costs almost nothing — both systems already exist — and it is the single most upsetting thing this design can do.

## Its job in the game

The Hunter exists to do five things a timer cannot:

1. **Turn abstract pressure into a thing with a face** you can hear, hide from, and tell stories about.
2. **Give Clamor teeth.** Noise needs a consequence that arrives and looks at you.
3. **Produce the leave-or-commit beat** the whole game is built around (`DES-002` step 4).
4. **Be counter-playable**, so pressure is gameplay rather than tax (`DES-005` requirement 3).
5. **Make the extraction walk the tensest part of the run**, not an epilogue.

## Perception — it hunts wealth, not just noise

This is the mechanical core and the thing that distinguishes it.

| Range | What it senses |
|---|---|
| **Far** | Clamor. The general commotion of you existing loudly (`DES-005`) |
| **Near** | **Carried tribute value.** It can feel gold through a wall. |
| **Contact** | Sight and sound, normally |

**Built at `M2-T02`**, and the far sense is built the hard way on purpose: it navigates `TEC-001`'s **clamor field by gradient**, never a player transform. It walks up the noise and arrives where the noise *was*. `--hunt-probe` asserts exactly that — make a sound, move away silently, and the Hunter must go to the sound — and the check was verified by handing it the player's position and watching it fail. That is the shortcut this design cannot survive, because players test it directly.

The middle sense is what makes going quiet insufficient, and it is now literal: a silent player carrying 316 tribute is found through walls; the same player, having put it all down, is not.

**Going quiet is not enough.** A silent Veiðimaðr with a bag full of Dvergar regalia is a lantern to this thing. To become uninteresting you have to *actually give something up* — which is the entire game, expressed as an enemy's sensory model.

## The verbs — how you deal with it

**You cannot kill it with damage.** ⟨tune⟩ Not at low Pact Rank, and possibly never by force alone.

**Bait it with gold.** ← *the important one*
Throw a purse of coin down a side corridor and **it will stop and pick it up.** Every time. It cannot help itself.

> **DECIDED (ADR-089): only gold a player has *disturbed* baits it.** Treasure that has lain on a plinth since before it arrived is scenery — it has been down here for years and never took the altar-plate. What draws it is **someone handling wealth**: gold that has been picked up, gold that is going somewhere, gold about to become a Tithe that is not its own.
>
> This was forced by the build. Implemented literally — all gold is bait — the Gullsjúkr spent an entire run walking between authored treasures and never hunted anybody. A pursuer doing a shopping round is not a pursuer. The rule also makes the counter-play mean what the rest of the design means: **baiting works because you gave something up**, not because gold happened to be nearby.
>
> The threshold has an absolute floor beside ADR-039's proportional one — proportional to a player carrying nothing is zero. The floor is the same value that decides whether *you* are worth crossing a room for: it does not want gold, it wants *enough* gold.

This is the best interaction in the design and it costs very little to build:
- It's a real counter-play with a real price — you're buying seconds with treasure.
- It's the game's core decision (abandon loot to survive) made into a physical act against an enemy who *demonstrates why you should*.
- On a second playthrough it stops being a tactic and becomes horrifying.

**Delay it.** Barricades, traps (Veiðimaðr's *Snare*), collapsing floors, hazards. It is slow and heavy; terrain is your friend.

**Confuse it.** Skald songs (ADR-031), Völva wards. It is a person, badly, and can still be lied to.

**Satisfy it.** ⟨tune⟩ Give it enough at once to settle its Tithe, and it *stops*. Sits down. Leaves the run.
Expensive, optional, and it is the **Refusal** answer to the same problem (`DES-016`) — the mercy option.

**Or kill it, eventually.** At high Pact Rank ⟨tune⟩ it becomes killable. You get its entire hoard, which is enormous, and a deed. It is also a person, and the game will not mention that either. **Two solutions expressing opposite values** — take everything it has, or give it enough to rest.

## Behaviour states

Reuses the `DES-013` awareness ladder for consistency:

| State | What it's doing | What you perceive |
|---|---|---|
| **Distant** | Somewhere on the floor, unaware | A held note in the score that means only this (ADR-035) |
| **Coursing** | Moving toward your last Clamor spike or a wealth reading | Rhythm enters the mix; the on-screen cue shows a bearing |
| **Sighted** | It has you | Full mix. It does not lose interest quickly. |
| **Collecting** | Distracted by thrown gold | Everything drops back for a few seconds — *your window* |
| **Lost** | Searching your last known position | Tension holds, then decays |

## Where it appears

Under ADR-015 a run is three floors, so escalation maps onto the Calamity structure (`DES-015`):

| Floor | Presence |
|---|---|
| **1 — The Aftermath** | **Absent**, unless you are catastrophically loud. Protects the quiet opening the run needs (`PRO-005 §9`). |
| **2 — The Retreat** | **Arrives reliably**, announced. This is where the run turns. |
| **3 — The Cause** | **Already there when you land.** No grace period. |

Escalation on a floor: it gets faster and reads you more accurately the longer you stay; eventually a second one joins; the Sealing proceeds alongside (`DES-005`).

> **RESOLVES Q9:** the Hunt **persists across floors** — descending does not reset it. Going quiet and giving up carried value can cause it to lose you, but the floor transition itself grants nothing. Descent is a commitment.

## Co-op (ADR-008)

- **It goes for the richest player.** Four bodies, four wealth readings, and it picks the brightest one. Creates the exact social pressure we want: *"it's coming for you, you're carrying too much."*
- Party Clamor is super-linear (`DES-012`), so a 4-stack meets it far sooner.
- **It splits the party's attention** — someone has to deal with it while others finish, which is where co-op runs get memorable.
- Baiting is a *team* decision: whose gold pays for the escape?

## Presentation

- **Announced diegetically**, never by a UI element: torches guttering out ahead of it, distant collapse, the ambient track thinning to breathing and coin.
- **You hear it before you see it, always.** The reserved instrument (ADR-035) means only this and is never used decoratively.
- **Silhouette reads at any distance** (Principle 6) — huge, lopsided, glittering wrong.
- **It sounds like money.** Its movement is the sound of a great deal of loose coin being dragged. That is its footstep, its tell, and its whole characterization.
- **Visual twin required** for every audio tell (ADR-036, `DES-018`).

## Scope

**One archetype at 1.0**, with per-biome dressing — a Delvings Gullsjúkr wears Dvergar plate, a Barrow-Fields one wears grave-gold. Not three separate Hunters. Systems over content (Principle 5).

It is the game's hero asset: the most animation, the most audio, the most AI attention of any single entity. Budget accordingly, and build it in M2 (`PRO-001`) — the loop cannot be evaluated without it.

## Open questions

> **DECIDED (ADR-038):** **Yes, minimally and rarely.** Reuses ADR-027's existing death record plus one boolean; the Hunter spawns wearing that Bound's class silhouette and one distinguishing token. No gear reconstruction. Rare by design — if every Hunter is a dead friend it becomes cheap melodrama.

> **DECIDED (ADR-166):** **Only when it was one of your Bound.** A stave per kill would be a kill counter wearing a memorial's clothes — staves for strangers, and the wall stops meaning anything. ADR-038 already makes the Hunter *rarely* a dead Bound wearing that person's class silhouette, and that rare case is exactly the one worth marking: the wall then reads *people I knew, and people I put down*, which is this document's thesis standing in the camp as an object. No new state — ADR-038's death record and boolean already carry it. **Closes Q75.**

> **DECIDED (ADR-039):** **Proportional to carried value.** The richer you are, the more it takes to make a thrown purse more interesting than you — so baiting stays a real decision at every wealth level instead of a fixed toll that trivialises late runs.

> **DECIDED (ADR-166):** **Human sounds, never words.** Breathing, effort, counting — confirming the lean this question already carried. It was a person, and wordless human sound is how that gets *shown*; the moment it speaks, the player is told instead, and being told is what this document spends its length avoiding. Counting earns its place twice over: it is the sound of something searching methodically, so it is information as well as dread. **`DES-018`'s parity rule applies and is not free** — every audio channel needs a visual twin, so these need one too, or a muted build loses the one cue that says *it is working through the room rather than passing through it*. **Closes Q77.**
