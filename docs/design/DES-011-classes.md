---
id: DES-011
title: Classes — The Sworn
status: accepted
owner: design
tags: [classes, builds, skill-tree, identity, co-op, progression]
updated: 2026-10-10
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
> **Read since ADR-224:** the Húskarl bears 52 kg ⟨tune⟩ to the Veiðimaðr's 30, and a stamina bar a tenth longer. Both numbers were authored at `M3-T02` and read by nothing, and the byrnie weighed nothing worn — so the Húskarl carried exactly what the Veiðimaðr did, and the heavy armour cost nothing to wear. In their kit they now start a quarter laden.
> **The shield is in their hand (ADR-238)**, and the lantern in their bag: seax, round shield and byrnie are 18.1 kg worn of 52, about a third laden. Raised, the shield takes the guard's share off a Hall-Warden's overhead and a Sling-Wretch's stone, which a blade takes nothing off — from the front only. So a Húskarl who wants to see must take the shield off to hold the lamp, through the bag.
**Unique verb — Hold:** plant and become an immovable object. Nothing pushes past you. Allies can retreat through you.
**Rite themes:** shield mastery, doorway control, carrying wounded allies, taking hits meant for others.

> **The slice's Rite (ADR-273), four nodes, opening at Pact Rank 3:** **Shield Wall** — while you Hold, a raised shield stops blows from the sides too · **Shove** — letting go throws what is in front back a step and staggers it, loudly · **Take the Blow** *(after Shield Wall)* — while you Hold, a blow aimed at a friend behind you lands on you · **Last Door** *(after Shove)* — hold on with no breath left, paid in health. Carrying the wounded waits for `M5-T01`.
> **Hold can be seen (ADR-272):** a lunge with the shield raised square, a thump when it lands, and your own eye dropping behind the shield.
> **A Hold is not shoved (ADR-394).** The Hall-Warden's shove (ADR-391) throws any other body 1.5 m. A planted Húskarl takes the blow and stays where it is, so Hold is the one answer to the Warden at its own doorway.
**Cost:** loud, slow, and the Hunt finds them easily.

### 2. Völva — *Seeress*
**Aspects:** Maw · Wing · Cinder
**Fantasy:** knowing what the floor is about to do.
**How they get out:** by leaving before it goes wrong. Reads Hunt escalation early, senses value through stone, feels which route is bad.
**Unique verb — Seiðr:** enter a brief trance to read the floor — Hunter position, unlooted value, safest exit. Costs time and makes you helpless while it lasts.
**Rite themes:** foresight, curses, marking prey, warding a room for a short time.
**Cost:** physically frail, and every reading is time she isn't walking toward the door.

*Note: divination is an unusually strong fit here — an extraction game's core resource is **information**, and a class that trades safety for information is a genuinely novel role.*

> **Built at `M4-T35` (ADR-379): a reading is a snapshot bought with stillness.** The danger in this verb is a radar, and Balance rule 2 forbids any class being the best at extracting. So:
> - **Seiðr is sat.** Hold the craft key, and the trance fills the crosshair ring over 3 s ⟨tune⟩, still, guard down, the view dimmed. A step, a blow or letting go breaks it with nothing read. Þorbjörg's high seat in Eiríks saga ch. 4.
> - **A reading** shows the whole party, for 12 s ⟨tune⟩, the Gold-Sick, the best unlooted find and the way out, **where they were**. The marks don't follow. Thief's map, not Dishonored's Dark Vision. They are drawn as the ping shapes, labelled *seen*.
> - **The sight is spent for 30 s ⟨tune⟩** after a reading. Pressed while it rests, the reticle says *the sight is resting — N s*; a reading that found nothing says *the sight shows nothing here* (ADR-383).
> - **Her kit is the völr**, an iron staff caged at the head after the seeress graves at Fyrkat and Birka (*völva* is *staff-bearer*): one-handed, blunt, a sidegrade of the seax. **Her dress is Þorbjörg's**: a blue mantle, a black lambskin hood and glass beads.
> - **The Rite (pact rank 3, through Wing):** **Varðlokkur**, one blow doesn't break the trance · **Marking Prey**, a reading also marks awake enemies within 20 m · **Spá** *(after Marking Prey)*, and where the Gold-Sick is going · **Vé** *(after Varðlokkur)*, the ground she sat on stays a hush for 15 s, and cracks like one.

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
>
> **Built at `M4-T37` (ADR-387): Galdr, a verse sung loud that turns the dungeon on itself.**
> - **Galdr.** Hold the craft key to sing a 3 s verse ⟨tune⟩, walking at half pace with no guard; a blow breaks it off, and it is loud throughout. When it ends, enemies in earshot are **maddened** (they fight the nearest other enemy, and whoever they strike fights back) or, alone, **unnerved** (they give way). Guardians are only unnerved. The Hunt is called, never turned. Both states are marked and heard on every peer.
> - **The Rite (pact rank 3):** **Níðstöng**, the verse lands where he looks · **Lausavísa** *(after Níðstöng)*, a tap sings one quiet stanza at the nearest enemy · **Bjarkamál**, a finished verse wakes a downed ally in earshot · **Under Shields** *(after Bjarkamál)*, allies in earshot take the next heavy blow on the guard.
> - **Not built:** recording deeds for Lineage.
> - **Kit: the ash spear (ADR-395)** and two bindings, with the lantern carried. Óðinn, god of poetry and of galdr, is a spear-god, and a spear thrown over a host gives it to him (*Völuspá* 24; *Styrbjarnar þáttr*). The spear's reach lets the singer fight from behind the quarrel he starts, or past a Húskarl's Hold. It is a sidegrade of the Úlfheðinn's axe, not a better one: 3.7 m of reach against 2.3, bought with a slower wind-up and recovery, more breath and a louder blow.

### 4. Úlfheðinn — *Wolf-Coat*
**Aspects:** Cinder · Maw · Scale
**Fantasy:** the thing the dungeon should be afraid of.
**How they get out:** through whatever is in the way.
**Unique verb — Wolf-Fury:** enter a rage. Massive damage and damage resistance. **You cannot retreat, cannot use items, and cannot voluntarily disengage until it ends.** Commitment as a mechanic.
**Rite themes:** escalating fury, health-from-kills, terrifying enemies, fighting on past lethal damage.
**Cost:** the rage is a decision you cannot take back — the purest expression of Principle 3, and the class most likely to die with a full bag.

> **Built at `M4-T34` (ADR-345): the fury delays the blood instead of refusing it.** The line above, *"massive damage and damage resistance"*, is the stat ladder `DES-022` rules out. It is kept as fantasy and replaced as mechanism:
> - **The howl.** Holding the verb for half a second ⟨tune⟩ starts the fury. The hold fills the crosshair's ring as it builds (ADR-372). The howl is loud, and the Hunt hears it.
> - **Neither fire nor iron tells, yet.** For 8 s ⟨tune⟩ a blow that lands is **owed**, not taken. The screen's frame closes on the wound you will have.
> - **The blood is paid when the fury ends**, all of it at once. *I took more in the fury than I had* is a one-sentence death.
> - **Killed at a blow.** Every blow in the fury breaks poise and costs no breath. The weapon's damage is unchanged.
> - **The lock-in, enforced by the controller:** no step back, the bag will not open, nothing can be used or thrown, and the key cannot end the fury.
> - **No way out while it runs.** A Shaft's channel holds while any fury in the party runs (ADR-352). A Waystone is not begun in a fury, and one begun before it holds until the fury is over (ADR-370). Both say so at the reticle: the Shaft while you stand in it, and the Waystone when its key is pressed (ADR-371). The debt is always paid on the floor where it was run up.
> - **Weaker than their wont** (Egils saga ch. 27). For 6 s afterwards ⟨tune⟩: no breath, 0.8× pace and no fury.
> - **Kit:** the bearded axe and two bindings, with the lantern carried. No mail; they *"went without their mail-coats"*.
> - **Stats:** health 1.0, stamina 1.05, speed 1.04, carry 1.0 ⟨tune⟩.
> - **The wolf-coat (ADR-354):** the class's own dress, a wolf's skin worn as a hood with its skull on the crown, the hide down the back, and the forelegs knotted across the chest. It is worn whenever nothing is in the body slot, and a byrnie put on over it is worn instead. It is a look, not an item: it weighs nothing and turns nothing away.
> - **The Rite (pact rank 3):** **Blood-Price**, a kill pays down what is owed · **The Howl**, the howl staggers everything near · **Rising Fury** *(after Blood-Price)*, each blow landed adds a second, up to its length again · **Neither Fire Nor Iron** *(after the Howl)*, a heavy blow in the fury leaves no wound.

### 5. Veiðimaðr — *Stalker*
**Aspects:** Wing · Hoard · Maw
**Fantasy:** the professional who was never seen.
**How they get out:** by never having been noticed. Bow, traps, tracking, silence.
**Unique verb — Snare:** place traps that hold, wound, or misdirect — **including against the Hunter**, the only reliable way to buy time during the Sealing.
> **Built at `M3-T11` as *hold* alone** (ADR-123). Wound and misdirect are **absent, not stubbed**: trap *variety* is listed under this class's Rite themes below, so it belongs to the tree (`M3-T01`). One trap, one live at a time, and placing a second removes the first — a decision about *where* rather than a resource to count, which is also why it needs no ammunition economy to exist. It is silent to set and **loud when it fires**, so a trap in the doorway you are leaving through is a mistake you can make.
**Rite themes:** silent movement, trap variety, ranged precision, reading tracks (who came through here, and when).

> **The slice's Rite (ADR-273), four nodes, opening at Pact Rank 3:** **Lure** — your snare steps until something comes · **Gag** — what it holds cannot call · **Pinning Shot** *(after Lure)* — an arrow into something unaware pins it, springing your snare · **Cover of the Snap** *(after Gag)* — silent for a few seconds after your snare fires. Reading tracks waits for `M5-T01`.
> **Setting a snare can be seen (ADR-272):** the ring grows at your feet as you kneel to it, a set snare breathes, and a sprung one snaps shut.
> **A snare frees a turn (ADR-394).** Enemies take turns on a player (ADR-391). A body snared where none of its blows reaches gives its turn up, so the snare takes a body out of the fight rather than taking a turn out of it.
**Cost:** poor in a straight fight; a Stalker who is cornered is usually dead.

### 6. Haugbrjótr — *Mound-Breaker*
**Aspects:** Hoard · Wing · Scale
**Fantasy:** the tomb robber. The one who's actually here for the money.
**How they get out:** rich, and by a route nobody else knew existed.
**Unique verb — Appraise:** instantly read an item's true value, curse, and tribute worth. Also opens what is locked.
**Rite themes:** carrying capacity, lockpicking, cache mastery, disarming grave-curses, finding hidden ways.
**Cost:** the greed class in a game about greed punishing you. Their strengths actively tempt them into the exact behaviour that gets people killed.

> **Built at `M4-T36` (ADR-382): what is shut is hers to break, and everyone hears it.** *Appraise* as written is a card every class already reads (ADR-363) plus a curse reader with no curses until the Barrow-Fields. So the verb is the class's name:
> - **Haugbrot.** Hold the craft key at what is shut — a locked door without its key, a barred door from the wrong side, the barrow once it has shut (ADR-381, ADR-242) — and the ring fills over 4 s ⟨tune⟩. A step or a blow breaks it off. **Loud** as a spent Waystone: the greed draws the Hunt. A broken door stays open.
>   - **A barrow is broken once.** Broken in, it wakes as it did when first entered: the same find and the same clock. When it shuts the second time it is spent. Otherwise a barrow could be farmed: break it, loot it, let it shut, and break it again.
>   - **A Wedge never shuts on a body.** It is refused while anyone, friend or foe, stands in the doorway, and the reticle says she can shut it only when the doorway is clear.
> - **The Rite (pact rank 3):** **Hidden Way**, every door still shut on her floor marked for her · **Grave-Sense** *(after Hidden Way)*, the barrow marked from anywhere on its floor · **Wedge**, a door she broke can be shut again behind her · **The Long Pry** *(after Wedge)*, a blow does not break off her breaking. *Appraise* was dropped at build: every card already shows the exact figure (ADR-382's amendment).
> - **Not built:** curses, until the Barrow-Fields (`M5-T02`).

---

## Availability

> **DECIDED (ADR-012):** **All six are available from the start.** No class gating.

Variety at first contact, and it keeps the death→new-class hook at full strength *at the first death* — the exact moment `DES-010` C2 identifies as the largest churn risk. Gating three classes would have weakened the mechanism precisely where it's needed most.

**Lineage still gets class-shaped rewards — they're just *new* classes rather than withheld starting ones.** This becomes the post-1.0 content track:

- **Smiðr — *Rune-Smith*** · Scale · Hoard · Cinder. Field repairs, rune-inscription, breaking walls. Deep-Kin aligned. First in the queue; deferred from 1.0 only because its fantasy needs a crafting system we haven't designed.
- Further classes are the natural shape of post-launch content: each is a Rite branch plus a verb plus a kit, reusing the shared Aspect tree entirely. **Cheap relative to a biome, and it re-opens the whole game for a returning player.**

All six must therefore be playable and balanced by **M4, not M5** (`PRO-001`).

## Rite pacing (ADR-060)

> **The Rite branch unlocks at Pact Rank 3** ⟨tune⟩, not at Rank 1.

This is deliberate pacing, not a gate for its own sake. `DES-022` identifies **runs 11–25 as the sag in felt growth** — the same window `DES-010` names as churn point C3. Holding the Rite back gives the mid-life a **second identity beat**, arriving exactly as the first keystone stops feeling new.

**Visible arm changes at Ranks 3, 5 and 7** (ADR-057) sit in the same window: the Úlfheðinn's arms becoming more wolf, the Völva's ink spreading, the Haugbrjótr's hands more grave-stained. Non-numeric progression you can see on your own body, placed where nothing else is visibly changing.

**Greater nodes cluster at Ranks 4–6; lesser nodes front-load at 1–3**, where knowledge growth already carries the feeling.

## Balance rules

1. **Every class must be solo-viable.** Co-op is primary (`DES-012`) but solo is supported (ADR-008). *The Skald was the hard case; resolved by ADR-031.*
2. **No class is the best at extracting.** Each has a different *route* to the exit: Húskarl endures, Völva foresees, Skald empowers, Úlfheðinn breaks through, Veiðimaðr is never seen, Haugbrjótr knows the back door.
3. **Every unique verb has a real cost.** Same rule as keystones (`DES-004`).
4. **Party composition should matter without being mandatory.** Any 4 classes must be able to complete any content; some combinations should be *notably* better at specific expeditions.
5. **Class identity comes from the verb, not the stat line.** A player should recognize each class from 10 seconds of watching.

## Legacy interaction

> Class Rite nodes **can** occupy a Legacy slot (ADR-003), but only apply if the next life is the same class. A deliberate trade: keeping a Rite node bets your next life on repeating a class, while an item or shared-Aspect node keeps your options open. Good tension on the death screen.

## Open questions

> **DECIDED (ADR-050):** **Yes, duplicates allowed.** Simpler, and it avoids lobby friction over who 'called' a class.

> **DECIDED (ADR-031):** Resolved by recasting the class — **songs act on the dungeon first, allies second.** Solo Skald is a controller, not a diminished co-op class.

> **DECIDED (ADR-050):** **All classes are open to all gender presentations.** The class names are titles, not sexes — and the world is invented (ADR-007), so the historical gendering of *völva* and *úlfheðinn* does not bind us.
