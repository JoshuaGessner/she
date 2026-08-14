---
id: DES-003
title: Persistence & Meta-Progression
status: proposed
owner: design
tags: [persistence, meta, balance, death, skill-tree, economy]
updated: 2026-08-12
related: [DES-002, DES-004, DES-008, TEC-003]
---

# Persistence & Meta-Progression

**This is the highest-risk design area in the project.** Extraction roguelites die in exactly one of two ways: persistence so weak that death makes players quit, or persistence so strong that runs stop being dangerous by hour 20. The whole design below exists to thread that needle.

## The core problem, stated precisely

The user's brief: *skills persist across runs until you die and reset; power comes from tributing gear to the dragon.* Two failure modes follow directly:

- **Failure mode A — the trivialization curve.** By pact rank 8, a player walks through content that killed them at rank 1. The run stops being a decision-making exercise. This is what happens to most roguelite meta-trees without a counter-pressure.
- **Failure mode B — the wipe cliff.** If death erases 15 hours of skill tree, a meaningful share of players quit *at that moment*. The sunk cost is the whole relationship with the game.

Everything below is aimed at these two.

---

## The proposed model: three tiers of persistence

### Tier 1 — LINEAGE (survives death, always, forever)

Pure **knowledge and world state**. Zero or near-zero direct combat power. This is what makes death feel like a chapter break rather than a wipe.

| Persists | Detail | Balance risk |
|---|---|---|
| **Bestiary** | Recorded weaknesses, attack tells, resistances, loot tables of enemies you've studied | Low — it's information the player was going to learn anyway; we're just letting the *character* know it too |
| **Cartography** | Known landmarks, shortcut locations, extraction points, rumoured vault positions | Low–moderate — speeds routing. Tune by keeping layouts procedural, so knowledge is *topological*, not literal |
| **Recipes & lore** | Identified item properties, alchemy formulas, rune translations, faction etiquette | Low — removes tedium, keeps discovery |
| **Contacts** | NPCs who remember your bloodline; unlocked contract types and vendors | Low — unlocks *options*, not numbers |
| **World scars** | Permanent world changes: a bridge you built, a gate you opened, a boss permanently slain, a district permanently flooded because you did that | Moderate — these are content unlocks and should sometimes make the world *worse* as well as better |
| **Dragon's memory** | Her dialogue, attitude, and the story tier she's at. She has known your whole lineage. | None — pure narrative payload, and the emotional engine of the meta-game |

**Design intent:** a lineage-50 player who just died starts a new life *fast and informed* — they know where things are, what things do, and which NPCs will talk to them. They are not *strong*. That's the point: **persistence removes friction, not danger.**

### Tier 2 — LIFE (persists between runs, lost at death)

The pact itself. This is what the user described.

| Persists within a life | Lost at death |
|---|---|
| Skill tree (Boon spent into Aspects — `DES-004`) | ✅ all of it |
| Pact Rank & Tithe obligation | ✅ resets to 1 |
| Stash (banked gear, currency, materials) | ✅ except Legacy (below) |
| Scars accumulated this life | ✅ |
| Faction standing (this life's reputation) | ✅ mostly — Lineage keeps *contacts*, loses *rank* |

### Tier 3 — LEGACY (the bridge across death)

The anti-wipe-cliff mechanism, and the piece I feel strongest about.

**On death, the dragon sears a small, bounded number of things into memory.** You choose what she keeps.

> **DECIDED (ADR-003):** 3 slots. Payload is **one item or one skill node only — never raw Boon.**

- **3 Legacy slots**, expanding *very* slowly ⟨tune⟩ — one at lineage milestones, capped at 5 lifetime.
- Each slot holds **one of**: a single item, or a single skill node (not a branch). **Raw Boon is disallowed** — it would be the fungible default pick every time, collapsing the choice into percentage-retention with extra UI.
- Slots are chosen **at the moment of death**, from what you had — a genuinely dramatic screen, and a real decision. *"She'll only remember three things. Choose."*
- **Legacy items are Scarred**: carried through death at reduced power (⟨tune⟩ ~70%) and cannot be tributed. They're a head start, not a stockpile.

Why this works:
- **Power creep is bounded by design, not by tuning.** Three slots is three slots. It cannot spiral no matter how many lifetimes accrue.
- It **converts the wipe cliff into a decision**, which is the roguelite designer's oldest and best trick. Players remember choices; they resent deletions.
- It gives us a **dramatic, cheap, high-impact scene** — one UI screen doing enormous emotional work.
- It creates **build seeding**: keeping one keystone node lets you start the next life leaning toward a build you want to try, without being handed it.

---

## Every run pays something (the retention floor)

> **DECIDED (ADR-006):** No run can ever return zero.

ADR-004 (stash wipes on death) makes death severe. That severity is load-bearing for balance, but **the first death is the largest single churn moment in this genre**, and severity without compensation is how a game loses a player permanently at hour four.

The compensation is structural, not a consolation prize: **LINEAGE accrues live, during the run, and commits on death as well as on extraction.**

- Fought something new → bestiary entry, kept forever.
- Walked somewhere new → cartography, kept forever.
- Read an inscription, met an NPC, identified an item → kept forever.
- Died in a way you hadn't died before → she remembers *that* too.

Because Lineage is power-free by construction, we can be **lavish** with it without touching balance. This is the Hades insight: a failed run must still visibly move a bar, and the player must *see* it move.

**Requirement on the death screen:** it must lead with what was *gained* before it shows what was lost, then hand the player the Legacy choice. The emotional sequence is `you learned → she remembers → choose what she keeps → descend again`. Never `you lost everything`.

---

## The counter-pressure: Tithe (solving Failure Mode A)

Persistence alone always trivializes. So power must be **coupled to obligation**.

**Every point of Boon spent raises your Tithe** — the tribute value the dragon expects per run cycle. Her hunger grows with her investment in you.

```
Pact Rank 1  →  Tithe: 40 value / 3 runs ⟨tune⟩   → satisfied by surface floors
Pact Rank 5  →  Tithe: 260 value / 3 runs         → surface floors cannot cover this
Pact Rank 9  →  Tithe: 900 value / 3 runs         → requires vault raids and deep descent
```

The consequences fall out beautifully:

1. **Power pulls you deeper.** You cannot farm safe content at high rank — the math doesn't cover the Tithe. Difficulty auto-scales *because the player chose power*, not because a slider moved. (Pillar P3.)
2. **The player owns the pacing.** Don't want harder content? Don't take the nodes. That's a legitimate, supported playstyle — a low-rank player grinding shallow floors for Legacy items is *playing correctly*.
3. **Default is a soft-fail, not death.** Miss your Tithe → lose standing, take a debuff, possibly have a skill node *reclaimed* by the dragon (she takes her power back). Recoverable, and thematically perfect.
4. **It gives the dragon a personality with teeth.** She is not a shopkeeper. She is a creditor.

**This is the mechanism that lets us be generous with persistence elsewhere.** Because power self-balances against required risk, we can afford a rich skill tree without the endgame going soft.

> **DECIDED (ADR-029):** **Per 3-run cycle** ⟨tune⟩. Absorbs one disaster run so bad luck and experimentation don't default you, and matches the session shape in `DES-002`. Missing it stays a *soft* fail — standing, a debuff, possibly a reclaimed node.
>
> The cycle boundary must be unmissable in the Lair UI, and **a partial cycle at session end must never be punished** (`PRO-005 §11`).
>
> *Running-debt-with-interest was the close runner-up and is the more elegant version — she's a creditor, and node reclamation would self-stabilise the spiral. Rejected on complexity, not merit. If the 3-run boundary feels arbitrary in playtest, try this first.*

> **OPEN:** Can a player *refuse* to grow — stay at rank 2 forever and just accumulate Legacy? Currently yes, and I think that's a feature (it's a self-selected difficulty setting), but it needs a check that it isn't the *optimal* play.

---

## What deliberately does NOT persist

Stated explicitly so it doesn't drift:

- **Raw stat inflation.** No permanent "+5% damage forever" nodes anywhere in the design. Every persistent gain unlocks an *option, tool, or tradeoff*. (Principle 1.)
- **Consumables in bulk.** The stash has a hard cap ⟨tune⟩ so it can't become a war chest that makes runs risk-free. Hoarding is the dragon's job, not yours.
- **Full gear loadouts across death.** Legacy slots only.

## Alternatives considered and rejected

| Option | Why not |
|---|---|
| **Full wipe on death (pure roguelike)** | Maximum tension, but conflicts with the user's brief ("power for concurrent runs") and hits Failure Mode B hard. Rejected. |
| **Nothing lost on death (Tarkov-style insurance)** | Removes all weight from death; the extraction decision loses its teeth. Rejected. |
| **% Boon retention (keep 30% of lifetime Boon)** | Simple, smooth, no cliff — but it's a *number going up forever*, which is exactly the trivialization curve. Also emotionally flat: no decision, no scene. Rejected in favour of Legacy, though it's the obvious fallback if Legacy tests badly. |
| **Heir system (Rogue Legacy: new character, inherits traits)** | Charming, and a natural fit for "lineage." Rejected as *primary* because it fragments identity and adds character-generation systems we don't need. Some of its flavour is absorbed into the Lineage tier. |
| **Scars only (permanent penalty + permanent gift per death)** | Great texture, bad as a whole system — deaths compound into unplayable states or free power. **Adopted as a sub-system**, not the backbone. |

## Balance guardrails (test these in playtest)

1. A lineage-1 player and a lineage-40 player at the same Pact Rank should die to the *same* floor at similar rates. If the veteran is safer, Lineage has leaked power.
2. Time-to-first-death for a new player: ~⟨tune⟩ 3 runs. Time-to-first-death for a competent veteran chasing rank 9: also inevitable. **No player should stop dying.**
3. Legacy should never make run 1 of a new life feel like run 15 of the old one. If it does, cut slots or deepen the Scar penalty.
4. If >60% of players spend every Legacy slot on Boon, the slot design has failed — it means we built a percentage-retention system with extra steps.
