---
id: DES-019
title: UI & HUD
status: accepted
owner: design
tags: [ui, hud, legibility, inventory, map, cognitive-load]
updated: 2026-08-17
related: [DES-018, DES-005, DES-008, DES-009, DES-012, DES-014, DES-020, PRO-005]
---

# UI & HUD

## The problem

This game asks the player to hold more simultaneous state than most first-person games: **Clamor, weight, stamina, health and wounds, whether you still have a Waystone, the Hunter, 2–4 contracts, the map, and three teammates.** `PRO-005 §8` names heavily-interacting elements as the most expensive thing a player can be asked to learn, and this is a list of them.

So the design goal is not "show everything clearly." It is **show the fewest things, and let one of them carry all the urgency.**

## Thesis

> **The HUD is one instrument with satellites, not six equal widgets.**

The Ear (`DES-018`) is the game's signature readout and the only element permitted to **grow**. When Clamor rises or the Gullsjúkr arrives, the Ear gains visual weight; everything else stays exactly as it was. That is how attention gets directed without adding clutter — the screen has a single volume knob, and pressure turns it.

## Layers

### Layer 0 — The world tells you (always on, free)

Diegetic reinforcement costs almost nothing and does a third of the work:

- **Weight** in the walk cycle, the sag of the hands, the sound of coin shifting
- **Stamina** in breathing, and in how hard the camera settles after a sprint
- **Wounds** in gait, in a hand that won't come all the way up, in vignette
- **Clamor** in the noise your own body is making

Layer 0 is never *sufficient* (ADR-036 — everything needs an explicit twin) but it makes the explicit layer able to stay small.

### Layer 1 — The Ear (top right) — **the instrument**

> **DECIDED (ADR-040):** the Ear sits **top right**, where a minimap would conventionally live. Closes Q81.

Occupying the minimap's slot is deliberate: it is the game's answer to a minimap, and putting it there says so. Keeps the centre clear (rule 1) and sits where players already look for spatial information.

**The only element permitted to grow.**

#### What it must carry — and the two natures problem

Four things, of two fundamentally different kinds:

| | Nature | About |
|---|---|---|
| **Clamor output** | Continuous scalar | **You** |
| Room alert state | Discrete, 4 states | The world |
| Bearing of attention | Angular | The world |
| Hunter state | Discrete + angular | The world |

One is *what you are doing*. Three are *what the world is doing about it*. Cramming them into one undifferentiated widget is what makes HUD elements unreadable.

#### Skin: the ember (ADR-042)

The core is **a piece of her fire** — the same ember that drops when you die (`DES-012`). Attention arrives as **drifting sparks** from the direction that heard you.

The readout is literally the thing your friends carry out of the Deep, which is why it earns the most-looked-at position on screen.

> **The one risk, and the rule that fixes it:** a brighter flame reads as *good*. **High Clamor must look guttering and sick — never warm, never powerful.** The ember should feel blown-about and giving you away. If a playtester describes the loud state as "cool," the visual language has failed: desaturate it, destabilise it, thin it out.

#### Architecture: a core and a ring

> **BUILT AT `M2-T03` (ADR-090).** Core and ring, eight sectors, the Hunter's heavy mark, and the whole element growing under pressure. It renders the **same `HuntMix` the score is driven by**, so the two channels cannot drift apart (`DES-018`).
>
> The guttering rule held up in practice: quiet reads as a small warm dot, loud as a large pale desaturated disc that jitters and breaks at its edge. Size and fill carry it, so it survives monochrome. `--ear-shot` photographs all three states, and it earned itself immediately — the Ear was rendering entirely off-screen, which no headless check could see because `_draw` never runs there.

- **Inner core = you.** Fills, brightens, and quickens with your Clamor output. This is the readout that makes greed legible, and it is the most important pixel in the game.
- **Outer ring = the world.** Arcs light where attention is coming from. The ring's *character* — solid, broken, pulsing — encodes the `DES-013` alert ladder.
- **The Hunter** takes a distinct heavy mark on the ring, and **the whole element gains weight** (rule 5).

Cause on the inside, effect on the outside. That is the mental model the player actually needs, and it means each half can be read independently at a glance.

#### The guardrail that keeps this from becoming a radar

> **The Ear reports attention, not positions.**

It answers *"something over there heard me."* It never answers *"there are three enemies at these coordinates."*

- **Coarse bearing only** — 8 sectors ⟨tune⟩, never precise angles.
- **Only shows attention that exists.** An unaware room produces a blank ring, no matter how many enemies are standing in it.
- **Never shows enemy count, health, or type.**

Without this rule the Ear becomes a wallhack, players stare at the corner instead of the room, and the entire "look at the world" premise of the lighting and audio design collapses.

### Layer 2 — Body (bottom left)

Health, stamina, wounds. Health does not regenerate (`DES-009`), so it reads as a **depleting resource**, not a bar that refills.

### Layer 3 — Burden (bottom right)

Weight, and the **Waystone indicator** — which is binary and must be answerable in a glance: *do I still have my way out?* (ADR-015, Q54's one-cap rule exists precisely so this can be a single lit or unlit mark.)

### Layer 4 — Party (left edge, co-op only)

Three compact frames: name, class, health, downed/Vörðr state, and a **small Clamor pip per player** (ADR-039, Q78) so "you're the loud one" is visible without cluttering the Ear.

### Layer 5 — Contextual (appears, then leaves)

Interaction prompts, contract updates, the ping wheel (`DES-012`), a reticle **only when a ranged weapon is drawn**.

## Rules

1. **Nothing lives in the centre.** The centre of the screen is the game.
2. **No numbers during a run.** Health is not `73/100`; weight is not `42.5kg`. Analog readouts only. Numbers invite spreadsheet optimisation; shapes invite feel, and feel is what Principle 3 is protecting. *(Exception: the inventory screen, where you are deliberately doing arithmetic.)*
3. **Readable in monochrome.** Shape and motion first, colour second, always (`DES-018`).
4. **The HUD never lies and never hides.** There is no "immersive mode" that strips information — that is a difficulty change wearing an options-menu costume, and it would silently break `DES-018`'s parity guarantee.
5. **One element carries urgency.** The Ear. Everything else is constant.
6. **Diegetic where free, explicit where necessary.**
7. **Every prompt names both devices** (ADR-075). A prompt reading *"press E"* is a keyboard-only element that has to be rebuilt rather than adjusted when a controller is plugged in, so no HUD element may be authored assuming one. Until glyph-swapping icons land at `M4-T05`, prompts carry both labels — `lmb/RT`, `ctrl/B`. **This is a rule about authoring, not about the final look:** the shipped HUD swaps to the active device's glyph, and the rule exists so that swap is a rendering change and never a redesign.

## Carried instruments — the map, the lantern, the compass

> **DECIDED (ADR-040):** the **compass is an item**, like the map and the lantern. Closes Q82.

Three tools that give you information, each of which **costs you something to carry** — a slot, weight, and often a hand. That's a coherent little economy, and it means orientation is a thing you equipped rather than a thing the HUD gave you.

- **Lantern** — you gave up a weapon slot to see (`DES-008`)
- **Map** — drawn as you go, Lineage annotates (ADR-017)
- **Compass** — bearing, which is what makes cartography annotations mean anything ("north-east of the flooded hall" is only useful if you can find north-east)

A player carrying all three is very well informed and very badly equipped for a fight. **That's the intended trade**, and it gives the Veiðimaðr and Völva builds real texture.

## The map is a thing you hold

> **No persistent minimap.**

A corner minimap would trivialise the Ear's bearing role and pull the player's eyes off the world — which is where all the information actually is.

Instead the map is **held up**, physically, occupying a hand and most of your attention. While reading it you cannot fight well, move fast, or watch the room. **Checking the map costs you safety.**

- Draws itself as you explore; Lineage adds annotation, not coverage (ADR-017)
- Vulnerable to read, which makes *when* to read it a real decision
- Fits the tone exactly — a damp paper map by lantern light
- Reference: DayZ and Tarkov's paper maps, Barony's minimap as the counter-example we're rejecting

## Inventory

> **DECIDED (ADR-040):** **Grid-based, weighted, real-time.** Closes Q23 — no longer a prototype fork.
> **DECIDED (ADR-087):** **The grid is 6×5** ⟨tune⟩, RE4's attaché case. Built at `M2-T01`.

**Grid-based, weighted, and real-time.**

Two constraints that deliberately conflict — but not in the way this section first described them:

> **Space decides what you can carry. Weight decides what it costs you.**

- **Space** — a grid, so hauling is a spatial puzzle (RE4's attaché case is the gold standard for making greed tactile). **This is the gate.** ADR-050's "modest slot cap" is these squares.
- **Weight** — which drives movement and Clamor (`DES-005`). **This is the price.** It refuses nothing; `carry_capacity` is the denominator encumbrance is measured against, and that penalty is clamped at 1.0 so a bad decision stays recoverable rather than becoming an unrecoverable one.

ADR-087 records how this was corrected: `--bag-probe` was written asserting that *both* constraints refuse a pickup, and it failed — the assertion was wrong, not the code. One gate and one price is the sharper reading, and it sharpens the M2 gate question with it: **you abandon loot not because nothing else fits, but because what you have is too expensive to walk home with.**

So a bulky-but-light bolt of cloth and a tiny-but-ruinous bag of coin pose *different* problems. Measured across the ten authored items at 6×5, that difference is real rather than aspirational: a bag of gear fills 25 of 30 cells at 24.3 kg, a bag of glitter fills all 30 at 48.8 kg. Same squares, twice the price. Kilograms-per-cell spans 59× across the corpus, and `--bag-probe` fails if it ever collapses toward 1.

**Where the dimensions live.** `DES-020` gives inventory size to the **Pack slot**, and slots arrive at `M3-T07`. Until then the grid is `TuningProfile.inventory_grid`; when the Pack lands it supplies the number and the profile value becomes the *no pack* grid Q106 already requires. One home now, one home later, never two (ADR-087).

**No pause.** Co-op makes pausing impossible anyway, so we design for it deliberately rather than inheriting it: **opening your bag is a vulnerable act.** You kneel, you rummage, and the floor keeps happening. Sorting loot while something approaches is one of the best tension generators available and it costs nothing extra to get.

> **Cost, stated honestly:** a good grid inventory is ⟨a few weeks⟩ of UI work, and it is the single largest UI item in the project. **One model is built, not two (ADR-083).** Blockout — coloured rectangles carrying name and weight, ADR-046 — landed at `M2-T01` with every function complete: see, move, turn, drop. The art arrives with the rest of the HUD at `M4-T05`. This line previously said the Q23 prototype fork still stood, twelve lines below the decision that closed it — and `PRO-001` was reading the stale half. Doubling the largest UI item in the project is not how M2 answers *"does a playtester abandon loot to survive?"*; if the grid feels wrong, that is an M4 revision against playtest data.

## The two screens that matter most

`PRO-005 §2` — retrospective judgment is dominated by the peak and the **ending**. Every run ends on one of these two, so they carry disproportionate weight in whether another run gets started.

### Extraction (the Settle beat)

The good ending. It must have **punch** — light, her voice, the weight coming off. Then: what you brought, the keep-or-give decision made physically at the hoard (`DES-014`), and **deeds surfaced here and nowhere else** (`DES-016` — never mid-run, it would wreck the pressure).

### Death

Sequence is fixed by ADR-006 and is not negotiable:

```
what you learned  →  she remembers  →  choose what she keeps  →  descend
```

**Leads with what was gained, never with what was lost.** Lineage accrues live during a run and commits on death, so this screen always has something real to open with.

## The Lair

Different rules apply. **Numbers are appropriate here** — you are comparing gear, planning a build, and doing Tithe arithmetic. This is the one place spreadsheet-brain is welcome.

- **Tribute is physical**, not a confirmation dialog — you place things on the hoard (`DES-014`)
- The skill tree needs to be readable at a glance, per `DES-004`'s "describable in one sentence" rule
- Contract board, stash, forge
- **Cycle position must be unmissable** — how many runs left in this Tithe cycle (ADR-029)

## Open questions

> **OPEN (Q86):** How does the Ear behave for a **Vörðr** (`DES-012`)? A ghost makes no Clamor, so the core has nothing to report — but scouting for the living is their job, and the ring is exactly the tool for it. Leaning **core goes dark, ring stays live**.

> **DECIDED (ADR-050):** **Quietly, on the Burden layer.** It is fundamentally a greed readout, so it belongs next to weight and the Waystone.

> **DECIDED (ADR-050):** **One system.** Cheaper to build and less for players to learn.
