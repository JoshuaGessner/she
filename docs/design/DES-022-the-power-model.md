---
id: DES-022
title: The Power Model
status: accepted
owner: design
tags: [progression, balance, power, gear, skills, difficulty]
updated: 2026-08-15
related: [DES-003, DES-004, DES-008, DES-011, DES-013, DES-015]
---

# The Power Model

**What actually makes you able to survive deeper?** The answer was spread across four documents and stated in none, which is how a design quietly drifts back into a stat ladder. This is the single page.

---

## The short answer

> **You do not get stronger. You get harder to kill, better prepared, and better informed — and those compound into something that looks like strength from outside.**

A rank-9 player is not a rank-1 player with bigger numbers. They are someone who **knows what is down there**, has **removed whole categories of threat** from their run, and **arrived with the right tools**.

## The five sources, and roughly how much each contributes

Proportions are illustrative and tunable, not measured. They exist so we notice if one starts eating the others.

| Source | Share | What it is |
|---|---|---|
| **1. Player knowledge** | ~35% | What *you* learned. Draugr aggro on theft, not proximity. The Gullsjúkr tracks wealth. Throw gold to buy seconds. Blunt beats plate. |
| **2. Lineage knowledge** | ~15% | The mechanised version of the above (`DES-003`) — bestiary, cartography, recipes, identified items. Carries across lives, and speeds re-acquisition. |
| **3. Aspects & Rites** | ~25% | Capability changes, never numbers (`DES-004`, `DES-011`). |
| **4. Loadout & preparation** | ~15% | Having the right gear for *this* expedition, and having any at all (`DES-008`, `DES-020`). |
| **5. Consumables & condition** | ~10% | Bandages, runes, Waystones, a blade that is still sharp. |

**Roughly half your effective power is knowledge.** That is deliberate, and it is the same reason a veteran in *Hunt: Showdown* survives where a newcomer dies holding identical equipment.

---

## Why Aspects are power without being numbers

This is the part that sounds impossible until you look at the actual nodes.

- **Anvil-Born** — hazards and traps do not affect you. That is not `+armour`. It **deletes an entire category of threat**, and turns trapped rooms into shortcuts nobody else can take.
- **Never Where She Struck** — return to where you stood three seconds ago. Not `+evasion`. An escape that exists or does not.
- **Weight of Kings** — no carry limit, but everything you carry is noise. Not `+capacity`. A different game.
- **Second Stomach** — eat anything, gain its property and a stack of Corruption.

A rank-9 player holds four to six of these. **They compound into a toolkit a new player simply does not have access to**, and none of them is a bigger number. `DES-004`'s rule — *no node is purely numeric, ever* — is what protects this, and `TEC-006`'s validator enforces it by failing any keystone with no `effect_tags`.

## Why gear is preparation, not power

`DES-008` is firm: sidegrades with pronounced identity, no rarity ladder. So gear's contribution is:

- **Specialisation.** Plate against pierce. A hammer against shields and doors. A spear that outranges everything and is useless in a corridor.
- **Having any at all.** A player who keeps extracting has a stash. A player on a losing streak is descending in whatever they found. **This is a real and self-correcting power difference** — lose a run, lose the stock.
- **Condition.** A dull blade stops cleaving (`DES-008`). Access to the Deep-Kin Forge matters, and forge quality rides on camp momentum (`DES-014`).
- **Slot choices.** Lantern or shield. Map or a second weapon. Big pack or near-silence (`DES-020`).

**"Better gear" means more appropriate, better preserved, better provenance — never bigger numbers.** Visual progression is completely real; it just tracks *where you have been* rather than *how strong you are*.

---

## So what does "a rank-9 floor" mean?

The other half of the question, and it has to be answered the same way or the design is inconsistent.

> **Enemies have fixed stats per archetype. Difficulty scales by composition and pressure — never by giving the same enemy bigger numbers.**

A Wretch is always a Wretch. What changes with Pact Rank (ADR-010):

| Scales | How |
|---|---|
| **Composition** | Elites where there were Wretches. Thursar appear at all. |
| **Density** | More of everything |
| **Modifiers** | More Gilded, Roused, Silent, Warded (`DES-013`) |
| **The Hunt** | Arrives sooner, escalates faster, a second Gullsjúkr joins earlier |
| **Time** | Shafts seal faster, so cheap exits vanish sooner (`DES-005`) |
| **Layout** | Fewer bypass routes, longer walks, worse extraction placement |

**A rank-1 player dies in a rank-9 floor because there are more things, worse things, and less time — not because a skeleton hits for 40 instead of 12.**

That is also why an under-ranked player carried by a friend (ADR-010) is survivable at all: an *unaware* enemy is harmless regardless of what it would have done to them.

## The Tithe is what couples the two

`DES-003`'s Tithe rises with every point of Boon spent. So:

```
take power  →  owe more  →  must go deeper  →  meet worse composition
```

**The player chooses their own difficulty by choosing how much capability to accept.** A player who stops taking Boon stays at their current pressure level indefinitely, which is a legitimate way to play.

This is the load-bearing coupling in the whole design, and it only works because power is **capability**. If power were a stat ladder, players would out-scale the Tithe and the escalation would stop meaning anything.

---

## The honest risks

Stated plainly, because horizontal progression has known failure modes:

**1. Some players will not feel like they are progressing.** The classic complaint. Mitigations already in the design: keystones are *loud* and change how you play; Rites give unique verbs; gear progresses visibly (`DES-020`) even without numbers; the hoard grows and never resets (`DES-014`). **Watch for it in playtest — if players say "I don't feel stronger," the keystones are too quiet, not the numbers too small.**

**2. A skilled player can out-play their rank.** With no stat gate, a very good rank-2 player could handle rank-5 pressure. **This is a feature, not a leak** — Principle 3 says decisions over reflexes, and skilled play should be rewarded. Expedition choice scales to your own rank when solo, so it self-gates without a hard wall.

**3. Enemy archetype stats can drift upward.** The likeliest way this design decays: someone nudges Thursar damage each patch until archetypes *are* a ladder. **Archetype stats are set once and changed only by ADR.**

## The one-line test

If someone proposes a change, ask:

> **Does this let the player do something new, or does it just make an existing number bigger?**

The first is always allowed. The second requires an ADR and a very good reason.

## Open questions

> **DECIDED (ADR-059):** **Yes — you may descend above your rank, voluntarily.** Richer floors, worse composition, earlier Hunt. **The Tithe is still calculated at your own rank**, so it is a risk you accept rather than a shortcut you take, and `DES-003`'s coupling holds. Unlocks mid-life ⟨tune⟩, where it doubles as a pacing valve (below).

---

# Progression pacing — does growth actually *feel* like growth?

`DES-022` above establishes that the power is real. This section asks the harder question: **is it felt, run to run, and does it hold up across a whole life?**

## The problem: the curve sags in the middle

Tracing the felt experience across a life:

| Phase | Rank | Felt growth | Why |
|---|---|---|---|
| Runs 1–3 | 1 | **Enormous** | Knowledge acquisition is fastest here; everything is new |
| Runs 4–10 | 2–3 | **High** | First keystone lands. It should change how you play. |
| **Runs 11–25** | **4–6** | **⚠ FLAT** | Lesser nodes are small. Knowledge curve flattens. Gear is sidegrades, so no upgrade rush. |
| Runs 26+ | 7–9 | **High** | Pact nodes, deep expeditions, the loudest effects |

**The middle sags**, and that is not a coincidence: `DES-010` independently names **C3 — the mid-life grind (runs ~10–25)** as a churn point. Two separate analyses landing on the same window means it is real, and it is the single largest threat to "the player feels stronger and stronger."

## Three levers aimed directly at it

**1. Cluster the *greater* nodes at ranks 4–6.** Front-load lesser nodes at ranks 1–3, where knowledge growth is already carrying the feeling. **The middle of a life must be where the interesting nodes live**, not where the filler lives. This is free — it is a question of where nodes sit on the tree, decided once.

**2. Rite thresholds land in the sag.** The class Rite branch (`DES-011`) unlocks at **Rank 3** ⟨tune⟩, not Rank 1 — a *second* identity beat, arriving exactly when the first one has worn off. And ADR-057's visible arm changes trigger at **Ranks 3, 5 and 7**: your own hands becoming more wolf, more inked, more grave-stained, **in the window where nothing else is visibly changing.**

**3. Over-rank descent unlocks mid-life** (ADR-059). At Rank 4 ⟨tune⟩ a skilled player gets a valve — a way to convert competence into reward without waiting for the tree. It is a growth outlet that costs no content.

## The eight channels, and the rule

Growth is felt through eight independent channels:

1. A node acquired
2. Gear visibly improved (`DES-020`)
3. Lineage knowledge — bestiary entries, map annotations
4. A deed earned (`DES-016`)
5. The hoard physically growing (`DES-014`)
6. Rite arm changes at thresholds
7. Camp momentum — a fuller Threshold, new services
8. New access — an expedition, a forge tier, over-rank descent

> **Rule: every run must visibly tick at least two of the eight.**

This is stronger than ADR-006's "no run returns zero," and it is the concrete guarantee behind *feeling stronger and stronger*. **If a run ticks nothing but a partial Boon bar, that run failed** — and it is checkable in telemetry rather than a matter of opinion.

## The scaling model ⟨all numbers tune⟩

**Node budget.** ~32 nodes are *accessible* in a life (primary Aspect ~13, secondary ~12, Rite ~7). A player reaching Rank 9 takes roughly **20**.

Taking about 60% of what you could reach is the target — **enough that builds genuinely diverge, and that a second life with the same class still plays differently.** If players routinely take everything accessible, the tree is too small or Boon is too generous.

**Rate.** Roughly **one node every two runs, at every rank.** Steady drip, deliberately not accelerating.

**Costs.** Lesser 1 · Greater 2 · Keystone 5 ⟨tune⟩. Modest progression — keystones are something you save for, everything else keeps the rhythm.

**Boon income should stay roughly FLAT across ranks.** This is the important one and it is counter-intuitive:

- Tribute goes to the **Tithe first**; only surplus becomes Boon.
- The Tithe rises with every node taken.
- So a rank-7 player must extract *far more value* than a rank-2 player **to earn the same Boon.**

That is the treadmill, and it is the intended one — it forces deeper play without inflating anything. **Flat income plus a steady drip means the *feeling* of growth comes from nodes being loud, not from the rate changing.** If Boon income rises with rank, the tree fills too fast and the late game empties out; if it falls, the mid-game sag becomes a cliff.

## What to measure at M3

Balance guarantees, written as tests rather than intentions:

| Check | Target |
|---|---|
| Runs per node acquired | ~2, **flat across all ranks** |
| Channels ticked per run | **≥ 2 of 8** |
| Nodes taken by Rank 9 | ~20 of ~32 accessible |
| Boon income per run | Flat ±20% across ranks 1–9 |
| Runs 11–25 self-reported "am I getting stronger?" | **No dip** — this is the one that matters |
| Two lives, same class | Play noticeably differently |

> **The mid-life question is the headline metric.** If testers at runs 11–25 say they have stopped feeling growth, no amount of late-game power fixes it — they will have already left (`DES-010` C3).
