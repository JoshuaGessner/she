---
id: DES-023
title: Items — the Slice's List
status: accepted
owner: design
tags: [items, loot, gear, weapons, armour, consumables, taxonomy]
updated: 2026-09-13
related: [DES-008, DES-009, DES-020, DES-022, DES-011, DES-013, DES-017, DES-014, TEC-006, PRO-004]
---

# Items — the Slice's List

`DES-008` has the philosophy — *she wants what glitters, not what works*, sidegrades not a ladder — and `DES-009` has the feel. `DES-020` has the slots. **Nothing had the list**, and three tasks were waiting on one: `M4-T02`'s enemies need something to be armoured against, `M4-T03`'s two classes need something to carry, and every generated floor deals its loot from whatever happens to be in the item folder.

This is that list, for the vertical slice: one biome (the Delvings), two classes (Húskarl and Veiðimaðr), about six enemy archetypes. **Twenty-six items**, sixteen of which exist. Accepted by ADR-217.

> Every number here is ⟨tune⟩. What is not ⟨tune⟩ is the sentence each item is allowed to exist for.

---

## 1. The rule an item has to pass

> **Name the thing this item lets you do that no other item on the list does.**

That is ADR-058's test (*something new, or a bigger number?*) applied to a corpus. An item whose only answer is *"the same, but more"* is not on the list — including one already in the build (§6).

It is paired with `DES-008`'s four axes, which must **disagree**: weight, clamor, what it does, and what she pays for it. An item where all four agree is either obviously worth taking or obviously worth leaving, and either way nobody had to decide anything.

**What the list deliberately does not contain:** a rarity tier, a second copy of an identity at a higher number, or anything whose purpose is filling a slot. `DES-020`'s slots are six; if a slot has nothing worth wearing in it, it stays empty and the bag says so.

---

## 2. The list

### Weapons — main hand

| id | What only it does | Costs | Source |
|---|---|---|---|
| `wpn_seax` *(exists)* | The fastest blade, **and it leaves a hand free** — for a shield or a light | Short reach; four blows to break a poise a hammer breaks in one | Húskarl kit · floor 0+ |
| `wpn_bearded_axe` | **The one thrown thing that wounds.** Throw is a verb for everything (`DES-009`); only this lands as a blow — at the price of the weapon, which lies where it landed and rings when it hits | One-handed and slower than the seax; a thrown axe leaves you empty-handed | floor 1+ gear |
| `wpn_ash_spear` *(exists)* | **Hits from outside the reach of anything else that swings** | Two-handed; **useless in a corridor** — built by ADR-222: its 3.7 m glances off a wall a seax clears, on about one swing in five | floor 0+ gear |
| `wpn_dvergar_hammer` *(exists)* | **Breaks a poise in one blow, and is the only thing plate does not turn** (§3) | Two-handed, slowest, loudest swing in the game | floor 1+ gear |
| `wpn_yew_bow` *(exists)* | **Loud where it lands, not where it is loosed** — a weapon and a misdirection tool (`DES-009`) | Two-handed: no light, no shield; does not also swing | Veiðimaðr kit |

### The off hand

| id | What only it does | Costs | Source |
|---|---|---|---|
| `arm_round_shield` | **Stops what a weapon's guard cannot** — a heavy blow and a missile from the front (§3). `DES-011`'s *"a shield that blocks what others must avoid"* | Takes the hand the lantern wants, so **a player with a shield is blind in the dark** (`DES-020`); heavy; swapping it is slow (ADR-057) | Húskarl kit · floor 1+ gear |
| `tol_horn_lantern` *(exists)* | **Lets you see** — 11 m either way | **Lets you be seen first**, at 16 m against 6.7 m shuttered (ADR-188) | Húskarl kit · floor 0+ gear |

### Worn

| id | Slot | What only it does | Costs | Source |
|---|---|---|---|---|
| `arm_mail_byrnie` *(exists)* | Body | **Mailed** — turns most of a cut (§3) | Heavy, and it jingles — **charged since ADR-224**: nothing worn weighed or sounded before, so both were free on the body | Húskarl kit · floor 0+ gear |
| `arm_dvergar_plate` | Body | **Plated** — turns a cut and most of a pierce, so a swarm's chip damage stops mattering | The heaviest thing you can wear; loud to move in; a hammer goes straight through it | floor 2 gear |
| `rlc_otr_pelt` | Body | **The Gold-Sick cannot feel through a wall what you carry while you wear it** (`DES-017`'s near sense). Ótr's skin, the one the first hoard was paid over | No protection at all — it is a pelt — and worth 180 to her ⟨tune⟩, so wearing it is refusing the richest single offer on the floor | floor 2 Prize |
| `arm_spangen_helm` | Head | **You cannot be Concussed** (`DES-009` wounds) | Weight; arrives with wounds (§5) | floor 1+ gear |
| `arm_iron_bracers` | Arms | **You cannot have an arm broken** — so a heavy hit never takes your two-hander or your guard (`DES-009` wounds) | Weight; arrives with wounds (§5) | floor 1+ gear |
| *no pack* | Pack | The quietest body in the game and the smallest grid — `DES-020`'s *"I came for one thing"* | 6 × 5 cells | Veiðimaðr default |
| `arm_hide_satchel` *(exists)* | Pack | 7 × 6 cells, silent | Weight | floor 0+ gear |
| `arm_pack_frame` | Pack | **8 × 7 cells** ⟨tune⟩ — the only pack the coin-chest and the altar-plate fit in together | Heavy, **and it creaks**: `DES-020`'s *"the upgrade that makes you more powerful is the upgrade that makes you louder"*, as an item. Visible on your back, so the party can see who is hauling | floor 1+ gear |

### Consumables

| id | What only it does | Costs | Source |
|---|---|---|---|
| `con_linen_binding` | **Heals.** The only thing on the list that does — `DES-009`: *health does not regenerate; healing is scarce and slow to apply* | Four seconds ⟨tune⟩ of binding, broken by a blow or a sprint; one cell of the bag each. **Built by ADR-221**: restores 35% ⟨tune⟩, spent only when tied, refused on a body with no wound | 2 in each class kit · filler from floor 1 (ADR-221: from floor 0 it was five a solo run) |
| `con_hush_rune` | **A circle, 6 m ⟨tune⟩, where nothing makes a sound for 10 s** — your steps, your swing, an enemy's shout to its kin, a coin you drop. It works on `ClamorSource`, the system that already exists, and it is a ring on the floor you can see (`DES-018`) | Single use, rare; **the stave cracks when it ends**, one loud pulse at its centre — a price, and a bait. **Built by ADR-221**: one storey tall, and the crack is heard by enemies as well as the Gullsjúkr | floor 1+ gear |
| `con_waystone` *(exists)* | Extraction wherever you stand (ADR-015) | Loud to channel; one per party | fixture |
| `con_ember` *(exists)* | A fallen teammate's life, carried (`DES-012`) | Heavy and loud; never loot | a downed body |

### Glitter — what she wants

| id | What its axes say | Source |
|---|---|---|
| `glt_gilt_bead` *(exists)* | Worth almost nothing, glints from far away — the vista bait (ADR-215) | floor 0+ |
| `glt_raw_gemstone` *(exists)* | Worth a lot, weighs nothing, makes no sound — the thief's find | floor 1+ |
| `glt_hoard_coin` *(exists)* | Heavy and loud for its worth | floor 1+ |
| `glt_gilded_torc` *(exists)* | Light, bright, worth carrying out | floor 1+ |
| `glt_altar_plate` *(exists)* | Heavy, loud, and a Prize | floor 2 Prize · filler |
| `glt_coin_chest` | **The find you can barely carry at all** — `DES-008`'s *Dvergar king's coin-chest*: 26 kg ⟨tune⟩ against a 30 kg Veiðimaðr, a 3 × 3 footprint, the loudest thing in a bag. Worth 220 ⟨tune⟩ | floor 2 Prize |

### Relics and materials

| id | What it is | Source |
|---|---|---|
| `rlc_regin_blade` *(exists)* | High tribute and high use — and **the one thing that comes back through death whole** (ADR-223; was the list's one failure, §6) | floor 2 Prize |
| `rlc_otr_pelt` | Listed under *Worn* | floor 2 Prize |
| `mat_bog_iron` *(exists)* | Light, cheap, and **for nothing yet**: materials are inputs to the forge, which arrives with condition (§5) | floor filler |

---

## 3. Armour, and the triangle it has always been owed

> **Built for the player by ADR-219.** The table below is `TuningProfile.armour_through`, resolved in `Hurtbox.receive`; the byrnie is mailed; a cut of 30 lands as 9.9 through it. Enemy classes arrive with `M4-T02`'s archetypes.

`DES-009` decided the damage triangle — *cut, pierce, blunt against unarmoured, mailed, plated* — and every weapon in the build has carried a `damage_type` for as long as weapons have been data. **Nothing read it.** The byrnie in the Húskarl's kit weighs 11 kg, jingles, and turns nothing. So this is not a new system being proposed; it is an accepted one that was never built, and the list above does not work without it.

**How much a blow of each type lands through each class** ⟨tune⟩:

| | Cut | Pierce | Blunt |
|---|---|---|---|
| **Unarmoured** | all | all | all |
| **Mailed** | ⅓ | ⅔ | ⅞ |
| **Plated** | ⅕ | ⅖ | all |

**The class is the body piece's, and only the body's.** Head and arms do not add to it — three pieces each shaving a share off every blow is the stat ladder `DES-008` rejects, reassembled one slot at a time. Head and arms each turn away **one wound** instead: a capability with a name, which a player can feel the absence of.

**It is symmetrical.** An enemy archetype has a class, and an enemy attack has a type (`M4-T02`'s `AttackResource`). A Wretch is unarmoured; a Hall-Warden is dead Dvergar plate, which is what earns the hammer its place.

**The shield is the other half.** A raised weapon stops part of a normal blow, as it does today; **a heavy blow and a missile from the front go through a weapon's guard and stop on a shield.** That is what makes `DES-011`'s sentence a mechanic, and it needs `M4-T02` to say which attacks are heavy.

---

## 4. Where items come from

> **Built by ADR-220** as `data/loot/lut_delvings.tres`. Three things were learned building it and are the rule now: **the Prize is chosen by the seed** among the Prizes of the deepest band a floor opens; **filler goes round its pool**, because a table deals filler as filler and a shallow floor has little of it; and **the altar-plate is floor 2 filler as well as a Prize**, or floor 2's filler is floor 1's again. Measured before and after in ADR-220.

A floor dealt its loot from **the entire item folder**, sorted by worth and cut by depth (ADR-193). That was right while nothing had the list — it named nothing — and it is wrong the moment the list exists: add plate armour worth 0 and it lands in the bypass room with the coins; add a coin-chest and every floor-2 Prize changes. **The list and the loot bands have to land together** (`M4-T31`).

| Source | What it deals | Rule |
|---|---|---|
| **Class kit** | Húskarl: seax, round shield, mail byrnie, horn lantern (in the bag — the off hand holds one), 2 bindings. Veiðimaðr: yew bow, 2 bindings, no pack | The kit is the class's answer to *how do I get out* (`DES-011`), not a loadout to optimise |
| **The Prize** | Glitter or a relic, by depth band | One, whatever the party size (ADR-110) |
| **Machine gear** | Gear and consumables by depth band — never glitter | A fixture: the decision a situation poses must exist solo (ADR-192) |
| **Vista bait** | The cheapest glitter the depth holds | ADR-215, unchanged |
| **Filler** | Glitter, bindings, bog iron | Party-scaled, dearest into the rooms that cost the most to reach (ADR-032) |
| **Never on a floor** | The Ember, a second Waystone | `DES-012`, ADR-015 |

**Depth bands**, as the *Source* column above lists them: floor 0 is light gear and the bead, so its best find stays in single figures as ADR-193 measured it; floor 1 opens the hammer, the axe, the shield, the frame, the helm, the bracers, the rune, and the coin, the gem and the torc; floor 2 holds plate, both relics, the altar-plate and the coin-chest. The climb ADR-193 measured — 6 → 55 → 140 — becomes roughly 6 → 70 → 220, and **that is an economy change `GATE M4 GREED` has to be run against**, not a number to trust from here. The bands are the greed gradient `DES-015` Layer 4 asks for, authored instead of cut — ⟨tune⟩.

> **Bindings open at floor 1, not floor 0** (ADR-221). Dealt as floor 0 filler they alternated with bog iron and came to 1.7 a solo floor — five in a solo run with the kit's two, 175% of a health bar, which is not *scarce*. From floor 1 a solo run carries about 3.4. They are the cheapest filler, so they are dealt into the bypass first: the safe route pays in linen and the guarded one in gold.

---

## 5. What the list needs built, and who builds it

| Needs | Why | Task |
|---|---|---|
| **Armour classes and the triangle**, for players and enemies | §3 — the byrnie does nothing today | `M4-T02`, with the attacks that carry types |
| **A shield that stops heavy blows and missiles** | §3 | `M4-T03`, the Húskarl's |
| **Wounds**, which the helm and bracers turn away | `DES-009`'s table; the Scar is what a wound becomes | `M4-T14` — **the helm and bracers arrive with wounds and not before**, or they are armour that turns nothing, which is the byrnie's fault repeated |
| **The kits, the loot bands** replacing the worth cut, and the items whose behaviour is its own — the axe, the pelt, the frame, the coin-chest | §2, §4 | `M4-T31` |
| **Using a thing** — the binding's slow heal and the hush rune's circle | Nothing in the build is *used*; everything is carried, worn, thrown or dropped | `M4-T32` — **built, ADR-221** |
| **The spear's cost** — arcs that hit walls | `DES-009`: *"swing a poleaxe in a corridor and you hit the wall. Space is a weapon stat."* A hitbox passes through stone today, so the spear has reach and no price | `M4-T31` — **built, ADR-222**; reach itself turned out never to have been read |
| **The axe's throw** landing as a blow | §2 | `M4-T31` |
| **The pelt hiding what you carry** | §2, `DES-017` | `M4-T31` |

> **An item lands when both the thing that makes it work and the band that places it exist, and not before** (corrected by ADR-219). Plate needs the triangle *and* `M4-T31`'s bands, the shield the Húskarl's guard and the bands, the helm and bracers wounds and the bands, the binding and the rune `M4-T32` and the bands. An item in the folder ahead of its behaviour is the byrnie again — carried, weighed, and doing nothing — and because the floor deals from the folder, it would reach a player the day it was added.

**Deliberately absent from the slice**, each with a home (ADR-064):

| Absent | Why | Home |
|---|---|---|
| **Condition and repair** — a dulled blade stops cleaving | `DES-008` wants it, and it needs the forge and a service currency, neither designed in detail. Death already wipes the stash, so nothing inflates without it. **Decided by the developer, ADR-217** | `M5-T07` |
| **Materials having a use** | They feed the forge | `M5-T07` |
| **The map and the compass** | `DES-019` makes both items you hold. A drawn map is a system in its own right, and the stranger session found its way without one | `M5-T08` |
| **Identification** (`IdentifiableTrait`) | It is the Haugbrjótr's *Appraise* and Lineage's recipes; neither class nor tier is in the slice | `M5-T01` |
| **Grave-goods and curses** (`CursedTrait`) | Barrow-Fields loot | `M5-T02` |
| **Every other rune** — light, shatter, freeze | Shatter and freeze need breakable walls and water, which arrive with the other biomes; the rune-carver is a camp service (`DES-014`). **Decided by the developer, ADR-217** | `M5-T02` |
| **A hammer breaking doors and walls, an axe hooking a shield** | Nothing on a floor is breakable, and no enemy carries a shield | `M5-T02` · `M5-T04` |

---

## 6. What the list found in the build

- **Armour turns nothing and nothing heals.** The two gaps a playtester would name first, and neither is visible from a probe that asks whether items exist.
- **`rlc_regin_blade` fails §1.** It is a seax with more damage, more stagger and more reach — a bigger number with a name. It stays because it is in saves and the Legacy flow, and because a relic's other half (120 tribute) is doing real work. **It owes a verb, or an ADR saying why a relic may be a number**, and that is `M4-T31`'s. **Answered by ADR-223, the developer's call:** it is the one thing that comes back through death whole — kept in a Legacy slot it returns at full power, and is still refused as tribute. Building it found that no Legacy item had ever kept its Scar past the first descent.
- **The bag showed head and arms slots nothing could fill**, and had since `M3`. **Fixed by ADR-218**: the bag draws the slots something in the folder can go in, so these two return with the helm and bracers (`M4-T14`).
- **Every item added to the folder changes every floor**, because the floor deals from the whole folder. That is why §4 is part of this document and not a tuning pass after it.
