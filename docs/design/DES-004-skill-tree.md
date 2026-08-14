---
id: DES-004
title: Skill Tree — The Dragon's Aspects
status: proposed
owner: design
tags: [skill-tree, builds, meta, balance, progression]
updated: 2026-08-12
related: [DES-003, DES-007, DES-008]
---

# Skill Tree — The Dragon's Aspects

## Reference model

The brief asks for "League of Legends style" — different paths for different build purposes. The most useful reading of that is **LoL's rune system** (not the old mastery grid): *pick a primary path, take its keystone, take minor nodes down it, then splash a secondary path for a few nodes.* Its virtues, which we want:

- The **keystone defines the build** in one sentence — a player can say what they're doing.
- **Path + splash** creates real combinatorics from a small authored set (5 paths × 4 keystones × secondary ≈ hundreds of legible identities from ~60 nodes).
- **Legible at a glance.** No 1,200-node Path of Exile atlas. We are a small team; PoE-scale trees are a content trap.

Also stealing from: **Hades' Mirror of Night** (paired either/or choices — the cleanest meta-tree ever shipped) and **Dead Cells' mutations** (build identity via a handful of loud effects).

## Structure

**Five Aspects** of the wyrm. Each is a path with a distinct *purpose*, not a distinct stat.

| Aspect | Fantasy | Purpose | Keystone flavour |
|---|---|---|---|
| **Hoard** (greed) | She counts what she owns | Loot volume, weight management, appraisal, the economy game | *Carry more, sell higher, sense value through walls* |
| **Cinder** (wrath) | Her fire, given away | Direct offense, burst, area denial | *Aggressive, resource-hungry damage* |
| **Scale** (endurance) | Her armour | Survivability, hazard immunity, staying power | *Tank the floor instead of avoiding it* |
| **Wing** (cunning) | Her flight, remembered | Mobility, stealth, extraction speed, escape tools | *Get in, get out, never fight* |
| **Maw** (hunger) | What she does to those who fail | Sustain, consumption, corruption, transgressive power | *Feed on the dungeon; risk what you are* |

Five is chosen deliberately: enough for identity, few enough to actually balance and author art for.

### Node types

- **Keystone (1 per Aspect at first, 3–4 eventually).** Build-defining, loud, changes how you play. Only **one keystone active** at a time — this is the primary anti-bloat rule.
- **Greater nodes (~4 per Aspect).** Meaningful mechanical additions — a new verb, a new tool, a new tradeoff.
- **Lesser nodes (~8 per Aspect).** Small enablers, *never* flat stat sticks. Prefer "your throws stagger" over "+5% throw damage."
- **Pact nodes (locked behind Pact Rank).** Gate the loudest effects behind Tithe obligation, so top-end power always costs risk (`DES-003`).

### Path rules

> **DECIDED (ADR-009):** **Your class decides which 3 Aspects you may enter** (`DES-011`). This replaces the earlier arbitrary lockout rule and closes Q4.

- **Your class grants access to 3 of the 5 Aspects**, plus its own class-only **Rite** branch (~7 nodes).
- **One primary Aspect** from those 3: full access, its keystone available.
- **One secondary Aspect** from those 3: greater and lesser nodes only, no keystone.
- The third allowed Aspect stays available for a respec; the other two are closed to that class entirely.
- A **respec** exists but costs real resources and cannot change your keystone mid-life ⟨tune⟩. Locking the keystone is what makes the choice matter.

**Total surface:** ~65 shared Aspect nodes + 6 Rite branches × ~7 = ~107 nodes, producing 36 base class/Aspect identities before keystones. That's the ceiling; don't exceed it without cutting something.

## Sample node sketches (flavour, not balance)

**Hoard — Keystone: *Weight of Kings***
No carry limit; instead every item you carry adds noise and slows you. You *can* haul the whole vault. The dungeon will hear you do it. — *A greed build where the drawback is the fun.*

**Cinder — Keystone: *Emberdebt***
Your attacks cost Ember, drawn directly from the tribute you're carrying. Burn your loot to burn your enemies. — *Turns the loot economy into a combat resource; the ultimate "what am I here for" tension.*

**Wing — Keystone: *Never Where She Struck***
After taking damage, you may instantly return to where you stood 3 seconds ago ⟨tune⟩, once per floor. — *Escape as identity.*

**Scale — Keystone: *Anvil-Born***
You cannot dodge, sprint, or be knocked back. Hazards and traps do not affect you. — *A movement-refusal build; makes trapped rooms into shortcuts.*

**Maw — Keystone: *Second Stomach***
Eat anything: corpses, potions, cursed items, gear. Each grants its property for a time and a stack of Corruption. — *Transgressive, funny, self-destructive; the "I know what I'm doing" build.*

> Note the pattern: **every keystone has a real drawback.** That's the design rule for this tree — a keystone without a cost is a stat stick with a portrait.

## Boon: earning skill points

**Boon** is the meta-currency. Earned by **tributing extracted gear to the dragon** — the brief's mechanic, kept intact.

- Tribute value is driven by **rarity + provenance**, not raw quantity. A named blade from a deep vault is worth a room of copper.
- **Tribute is a real cost:** what you give her, you cannot use. Every run ends with "keep it or convert it," which is a genuinely good decision to make repeatedly.
- Boon is earned **only on successful extraction**. Death converts nothing.
- Surplus tribute beyond your Tithe converts to Boon at full rate; tribute *below* the Tithe converts at nothing and counts against your obligation ⟨tune⟩.

> **DECIDED (ADR-030):** **~70% tribute, remainder from contracts** ⟨tune⟩. Exploration pays **Lineage only**, never Boon.
>
> The deciding argument was contract-system viability rather than class balance: if contracts pay no progression, nobody runs them and `DES-007`'s whole three-tier structure is decoration. Tribute stays dominant so keep-or-give remains the spine of progression (Pillar P1).
>
> **Watch for:** a contract-farming strategy that skips looting entirely. If it appears, cut contract Boon before touching tribute rates.

## Anti-bloat rules

1. **≤65 total nodes at 1.0.** If a node can't be described in one sentence a player would repeat aloud, cut it.
2. **No node is purely numeric.** Ever. (This is the rule that keeps runs from trivializing.)
3. Every keystone must be **viable and non-optimal** — if one keystone has the highest win rate at every rank, it's overtuned, not popular.
4. A build should be **recognizable from watching 30 seconds of play** without seeing the tree.
