---
id: DES-016
title: Deeds & Trophies
status: draft
owner: design
tags: [trophies, deeds, lineage, camp, progression, retention]
updated: 2026-08-13
related: [DES-014, DES-003, DES-012, PRO-006, PRO-005]
---

# Deeds & Trophies

Everything that adorns a campsite is **earned** (ADR-026). Nothing is purchasable. That makes a camp **unforgeable** — a readable record of what a player has actually done, which is worth more socially than anything a storefront could offer.

## The rule that makes trophies good

> **Trophies commemorate decisions, not grinds.**

"Killed 500 Draugr" is a checklist item. Nobody tells a story about it, and it rewards time rather than judgment. What we want on a plot is evidence of **moments where the player chose something**, because those are the moments they actually remember (Principle 3, and the peak-end rule in `PRO-005 §2`).

Corollaries:
- **Earnable once.** A repeatable trophy is a chore with decoration.
- **Never numeric.** No counters on display; the staves already carry tenure (ADR-022).
- **Physical and specific.** Not a badge — *the skull of the Haugbúi you killed*, *the Waystone you never spent*, *a friend's cold ember*.
- **Must survive death.** LINEAGE tier, always. Power-free by construction, so we can be generous (`DES-003`).

## Categories

### 1. First deeds
The one-time firsts of a lineage. Straightforward, gives early players a steady drip.
*First Deep Gate reached · first Haugbúi felled · first floor cleared unheard · first Hunt survived to the bottom.*

### 2. Rescue deeds — **the best category**
*Carried a friend's ember out.* *Carried two in one run.* *Went back for someone when you had a Waystone in your pocket and could have left.*

These are the strongest trophies in the design because they commemorate the single most generous thing the game lets you do (`DES-012`), and they're visible to the people you did it for. A camp full of rescue-marks says something about a player that no stat line can.

### 3. Refusal deeds
Trophies for **not** taking things. *Walked past a Guardian and left it sitting.* *Extracted with an empty bag by choice.* *Reached the Prize and did not take it.*

Thematically load-bearing (ADR-020): the game should be able to see when you chose the light, and mark it. It also quietly teaches that refusal is a legitimate way to play — which the ending question (Q56) will eventually need.

### 4. Endurance deeds
*Survived a full Hunt escalation.* *Extracted at under ⟨tune⟩ 10% health.* *Finished a three-floor run with a broken weapon.*

### 5. Memorial — **the emotional one**
A token from each NPC Bound who died while you knew them (`DES-014`). Their cup, their knife, the mark from their stave.

Over a long lineage a camp fills with the belongings of dead friends. Nobody explains it and it needs no text. It is the theme, in props, permanently — and it makes the Threshold's NPC deaths *matter mechanically* instead of being flavour.

### 6. Calamity marks
One per expedition Calamity fully uncovered (`DES-015`, ADR-018). These are the pieces of the pattern. A camp with all of them belongs to someone who has worked out what the gold does — **and the trophies never say so.**

## Integration into the loop

Trophies must be **planned into gameplay, not bolted on afterward**, which means:

- **Deed conditions are evaluated by the run systems that already exist** — extraction state, ember events, Clamor history, loot decisions. No bespoke tracking subsystems; if a deed needs new instrumentation, it's probably the wrong deed.
- **Awarded at the Settle beat** (`DES-002`), shown *after* the tribute decision, so the run ends on evidence of what you did rather than on a balance sheet.
- **Placed by the player.** You choose where on your plot a trophy sits. Small act, real ownership.
- **Visible to the party** in the Threshold. That's the whole social payload.
- **Target ~40–60 deeds at 1.0** ⟨tune⟩, weighted toward categories 2, 3, and 5.

## What we are deliberately not doing

- **No achievement popups mid-run.** They break the pressure the whole game is built on. Deeds surface at the Settle beat, never in the Deep.
- **No completion percentage, no checklist UI.** A gallery of everything you *haven't* done converts the system from evidence into a chore (`PRO-005 §11`).
- **No leaderboards, no comparison view.** Same reasoning as ADR-022 — you read a camp by looking at it.

> **OPEN (Q70):** Should undiscovered deeds be *hinted* at, or entirely unknown until earned? Hints drive intentional play but create a checklist feel; total secrecy is purer but risks players never finding the best ones. Leaning **secret, with the Bound occasionally mentioning things they've seen done** — discovery through gossip.

> **OPEN (Q71):** Do rescue deeds record *who* you carried out? Naming the friend is enormously more affecting and requires storing another player's identity in your save.

> **OPEN (Q72):** Is there a plot-space limit, forcing curation of what you display? A finite camp means choosing what you're known for, which is a good decision. An infinite one means never losing anything.
