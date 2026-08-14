---
id: DES-008
title: Loot, Gear & Economy
status: draft
owner: design
tags: [loot, economy, items, balance, greed, gear]
updated: 2026-08-12
related: [DES-003, DES-004, DES-005]
---

# Loot, Gear & Economy

## The central tension

Every item exists in a three-way tug-of-war, and **that tension is the game**:

```
        USE IT (equip, survive deeper)
              ▲
              │
   TRIBUTE IT ◄──► KEEP IT (stash, next run)
   (Boon, skills)
```

If any one of these is obviously correct, the economy has failed. Design rule: **the best gear should be the most tempting tribute** — so tributing genuinely hurts. A legendary blade you hand over is a legendary blade you never swing.

## Item axes

Every item carries four values, and they should conflict:

| Axis | Drives | Design note |
|---|---|---|
| **Weight** | Movement, stamina, dodge | The physical cost of greed (`DES-005`) |
| **Clamor** | Aggro radius, Hunt escalation | The audible cost of greed |
| **Utility** | What it does if you use it | |
| **Tribute value** | Boon if given to her | Driven by rarity + *provenance*, not quantity |

The interesting items are the ones where these disagree loudly: a Dvergar king's coin-chest (enormous tribute, ruinous weight and clamor), a raw gemstone (high tribute, no weight, no use), a good sword (low tribute, high utility — *and she doesn't want it, so it's yours*).

**Design heuristic:** *she wants what glitters, not what works.* This is what keeps combat gear in the player's hands and prevents the tribute system from stripping you naked each run — a critical balance valve, and it's flavour-perfect for a hoard-wyrm.

## Loot categories

- **Glitter** — coin, gems, plate, regalia. Pure tribute value, no use. Heavy and loud.
- **Gear** — weapons, armour, tools. Utility-first, poor tribute. Yours to keep.
- **Relics** — named, unique, from deep vaults. High tribute *and* high utility. **The hard choices live here.**
- **Materials** — crafting inputs for the Deep-Kin. Small, light, quietly essential.
- **Grave-goods** — from the Barrow-Fields. Enormous tribute value, but **cursed**: the Draugr they belonged to hunts you until you extract, tribute, or return it. Loot that fights back is the best loot.

## Gear philosophy

**No rarity-tier stat ladder.** No green→blue→purple→orange with +12% each. That ladder is what makes late runs trivial and early runs pointless, and it's incompatible with Principle 1 and `DES-003`'s guardrails.

Instead, gear is **sidegrades with pronounced identity** (Barony and *Noita* both do this well):
- A spear outranges everything and is useless in a corridor.
- A hammer breaks shields, doors, and walls, and is slow enough to get you killed.
- A lantern is a weapon slot you gave up to see.

Better gear = **more options and better condition**, not bigger numbers. A veteran is dangerous because they know a hammer opens that wall, not because their sword does 340 damage.

- **Durability/condition** ⟨tune⟩ exists as an economy sink — but as *degrading identity* (a dulled blade stops cleaving) rather than the item vanishing. Item breakage that deletes a fun toy is punishing without being interesting.
- **Identification**: unknown items must be tested, appraised, or risked. Lineage knowledge (`DES-003`) makes this progressively less tedious across lifetimes — a great example of persistence that removes friction without granting power.

## Faucets and sinks

| Faucets (value in) | Sinks (value out) |
|---|---|
| Dungeon loot | **Tribute** (primary sink — by far) |
| Contract rewards | Repairs & crafting |
| Vaults / rare caches | Consumables |
| Recovered caches | **Death** (stash wipe — the great reset) |
| | Tithe obligation (`DES-003`) |

Because **death wipes the stash**, this economy self-corrects in a way most extraction games can't manage — no permanent inflation spiral, no need for aggressive nerfs later. That's a strong structural argument for the LIFE-tier wipe in `DES-003`.

> **OPEN:** Is there a currency at all, or is it barter/tribute only? Barter-only is thematically strong (a ruined world with no functioning economy) and dodges a whole class of inflation problems, but complicates vendors. Leaning **barter + a single soft currency for services** (repairs, safehouse fees).

> **OPEN:** Stash cap — hard slot count, weight budget, or per-category? Needs to be tight enough that hoarding can't make runs risk-free (`DES-003`). Leaning **modest slot cap, expandable via Lineage** — an unlock that grants convenience, not power.
