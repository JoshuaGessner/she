---
id: DES-011
title: Classes — The Sworn
status: proposed
owner: design
tags: [classes, builds, skill-tree, identity, co-op, progression]
updated: 2026-08-12
related: [DES-004, DES-003, DES-012, DES-009]
---

# Classes — The Sworn

Six classes at 1.0, each drawn from Norse/Anglo-Saxon material (`PRO-004`), each with its own branch of the skill tree.

## How classes and Aspects fit together

The reference model is **Path of Exile's Ascendancy**: a large shared passive tree plus a small, unique, class-only sub-tree. It gives strong class identity without authoring six entire trees — which at our scale would be a content trap and an unbalanceable surface.

```
CLASS (chosen at the start of a LIFE, locked until death)
├── Starting kit, body profile, one unique verb
├── RITE — a class-only branch, ~7 nodes, nobody else can take these
└── Aspect access — which 3 of the 5 Aspects this class may enter

ASPECTS (shared across all classes — DES-004)
├── Primary   — full access + keystone      ┐ both chosen from the
└── Secondary — greater/lesser nodes only   ┘ 3 your class allows
```

> **This resolves Q4.** Aspect lockout is no longer an arbitrary "3 are closed" rule — **your class decides which Aspects you can enter.** Flavourful, legible, and it makes classes differ structurally rather than cosmetically.

**Combinatorics:** 6 classes × 6 ordered primary/secondary pairs from their 3 allowed Aspects = **36 base identities**, before keystones and Rite choices. Ample variety from ~42 unique nodes plus the ~65 shared ones.

## Why this is the right answer to ADR-004

The stash wipes on death. That's harsh. But **class is chosen at the start of a life**, so:

> **Death is the only door to a new class.**

Dying stops being purely subtractive. It's the gateway to the Úlfheðinn run you've been curious about for six hours. This is the strongest retention answer we have to the wipe (`DES-010` C2, and Autonomy under SDT in `PRO-005`), and it costs nothing to implement — it's a consequence of structure we already chose.

## The design rule for classes

**Classes must differ in their relationship to the loop, not just in their damage type.** In an extraction game, "melee vs. ranged" is a shallow axis. The interesting axis is *how you engage with loot, noise, pressure, and the exit* — so every class below is defined first by its answer to **"how does this class get out?"**

---

## The six

### 1. Húskarl — *Shield-Sworn*
**Aspects:** Scale · Cinder · Hoard
**Fantasy:** the last one standing in a doorway.
**How they get out:** by refusing to be stopped. Heavy armour, a shield that blocks what others must avoid, and the ability to keep moving under weight that would pin anyone else.
**Unique verb — Hold:** plant and become an immovable object. Nothing pushes past you. Allies can retreat through you.
**Rite themes:** shield mastery, doorway control, carrying wounded allies, taking hits meant for others.
**Cost:** loud, slow, and the Hunt finds them easily.

### 2. Völva — *Seeress*
**Aspects:** Maw · Wing · Cinder
**Fantasy:** knowing what the floor is about to do.
**How they get out:** by leaving before it goes wrong. Reads Hunt escalation early, senses value through stone, feels which route is bad.
**Unique verb — Seiðr:** enter a brief trance to read the floor — Hunter position, unlooted value, safest exit. Costs time and makes you helpless while it lasts.
**Rite themes:** foresight, curses, marking prey, warding a room for a short time.
**Cost:** physically frail, and every reading is time she isn't walking toward the door.

*Note: divination is an unusually strong fit here — an extraction game's core resource is **information**, and a class that trades safety for information is a genuinely novel role.*

### 3. Skald — *Song-Speaker*
**Aspects:** Cinder · Hoard · Scale
**Fantasy:** the one who changes what the room does.
**How they get out:** by making the dungeon turn on itself, and everyone else better at leaving.
**Unique verb — Verse:** sustained songs that act on **the dungeon and its inhabitants** — maddening enemies into attacking each other, drawing the Hunt, unnerving Guardians, breaking morale. Ally buffs are strong but **secondary**. **Songs are loud.** This is the class that *chooses* to generate Clamor.
**Rite themes:** enemy morale and madness, misdirection, party buffs, recording deeds (bonus Lineage), rallying downed allies.
**Cost:** inverted. Every Skald ability feeds the Hunt. **A Skald makes a run easier and hunted faster.** In a game where noise is the enemy, a class built on noise is the sharpest tension we can design — and here the noise *is* the weapon rather than a side effect.

> **DECIDED (ADR-031):** songs act on the dungeon first, allies second — **which closes Q32.** Solo Skald is a *controller*, not a diminished co-op class: madden a Draugr into fighting a Wretch, pull the Hunt across the floor, walk out through the argument. It costs almost nothing to build, because `DES-013`'s mutually hostile enemy factions already simulate the interesting half.
>
> Ally-buff tuning must not make a Skald mandatory in a 4-stack.

### 4. Úlfheðinn — *Wolf-Coat*
**Aspects:** Cinder · Maw · Scale
**Fantasy:** the thing the dungeon should be afraid of.
**How they get out:** through whatever is in the way.
**Unique verb — Wolf-Fury:** enter a rage. Massive damage and damage resistance. **You cannot retreat, cannot use items, and cannot voluntarily disengage until it ends.** Commitment as a mechanic.
**Rite themes:** escalating fury, health-from-kills, terrifying enemies, fighting on past lethal damage.
**Cost:** the rage is a decision you cannot take back — the purest expression of Principle 3, and the class most likely to die with a full bag.

### 5. Veiðimaðr — *Stalker*
**Aspects:** Wing · Hoard · Maw
**Fantasy:** the professional who was never seen.
**How they get out:** by never having been noticed. Bow, traps, tracking, silence.
**Unique verb — Snare:** place traps that hold, wound, or misdirect — **including against the Hunter**, the only reliable way to buy time during the Sealing.
**Rite themes:** silent movement, trap variety, ranged precision, reading tracks (who came through here, and when).
**Cost:** poor in a straight fight; a Stalker who is cornered is usually dead.

### 6. Haugbrjótr — *Mound-Breaker*
**Aspects:** Hoard · Wing · Scale
**Fantasy:** the tomb robber. The one who's actually here for the money.
**How they get out:** rich, and by a route nobody else knew existed.
**Unique verb — Appraise:** instantly read an item's true value, curse, and tribute worth. Also opens what is locked.
**Rite themes:** carrying capacity, lockpicking, cache mastery, disarming grave-curses, finding hidden ways.
**Cost:** the greed class in a game about greed punishing you. Their strengths actively tempt them into the exact behaviour that gets people killed.

---

## Availability

> **DECIDED (ADR-012):** **All six are available from the start.** No class gating.

Variety at first contact, and it keeps the death→new-class hook at full strength *at the first death* — the exact moment `DES-010` C2 identifies as the largest churn risk. Gating three classes would have weakened the mechanism precisely where it's needed most.

**Lineage still gets class-shaped rewards — they're just *new* classes rather than withheld starting ones.** This becomes the post-1.0 content track:

- **Smiðr — *Rune-Smith*** · Scale · Hoard · Cinder. Field repairs, rune-inscription, breaking walls. Deep-Kin aligned. First in the queue; deferred from 1.0 only because its fantasy needs a crafting system we haven't designed.
- Further classes are the natural shape of post-launch content: each is a Rite branch plus a verb plus a kit, reusing the shared Aspect tree entirely. **Cheap relative to a biome, and it re-opens the whole game for a returning player.**

All six must therefore be playable and balanced by **M4, not M5** (`PRO-001`).

## Balance rules

1. **Every class must be solo-viable.** Co-op is primary (`DES-012`) but solo is supported (ADR-008). *The Skald was the hard case; resolved by ADR-031.*
2. **No class is the best at extracting.** Each has a different *route* to the exit: Húskarl endures, Völva foresees, Skald empowers, Úlfheðinn breaks through, Veiðimaðr is never seen, Haugbrjótr knows the back door.
3. **Every unique verb has a real cost.** Same rule as keystones (`DES-004`).
4. **Party composition should matter without being mandatory.** Any 4 classes must be able to complete any content; some combinations should be *notably* better at specific expeditions.
5. **Class identity comes from the verb, not the stat line.** A player should recognize each class from 10 seconds of watching.

## Legacy interaction

> Class Rite nodes **can** occupy a Legacy slot (ADR-003), but only apply if the next life is the same class. A deliberate trade: keeping a Rite node bets your next life on repeating a class, while an item or shared-Aspect node keeps your options open. Good tension on the death screen.

## Open questions

> **OPEN:** Can two players in a party be the same class? Allowing it is simpler and avoids lobby friction. Leaning **yes, allowed**.

> **OPEN:** Skald solo viability — does the class fundamentally not work alone? If songs only ever buff allies, solo Skald is unplayable. Needs a self-targeting mode that is thematically coherent.

> **OPEN:** Gender presentation. *Völva* and *úlfheðinn* were historically gendered roles. Our world is invented (ADR-007), so all classes are open to all presentations; the class names are titles, not sexes. Confirm this is the intended stance.
