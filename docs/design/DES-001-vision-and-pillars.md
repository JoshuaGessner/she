---
id: DES-001
title: Vision & Pillars
status: draft
owner: design
tags: [vision, pillars, scope, north-star]
updated: 2026-08-12
related: [DES-002, DES-003, PRO-001]
---

# Vision & Pillars

## The pitch

> You are one of many desperate souls who have made a pact with a dying, ancient wyrm. She cannot leave her mountain, so she sends you down into the buried places of a broken world to bring back what glitters. In return she burns a piece of her power into you. The more she gives, the more she demands — and she is always hungry.

**Genre:** first-person 3D fantasy extraction roguelite. **PvE co-op for 1–4 players**, with solo fully supported.
**Reference triangle:** *Barony* (systemic first-person dungeon crawl, physicality, jank-charm) × *Call of Duty: DMZ* (layered concurrent mission structure, exfil tension, the "one more contract" pull) × *Hades / Rogue Legacy* (patron-driven meta-progression that reframes death as narrative).

## Theme

> **DECIDED (ADR-020):** The game is about **the thing you know is killing you, that you go back to anyway.**

She knew, once, what her hoard does to everyone who touches it. She has burned that knowledge out of herself three times over and will do it again (ADR-019). Every civilization in the Deep died of the same thing (ADR-018). And **the player does it every single run** — the Tithe escalates like a tolerance, the hoard grows and never resets, death takes everything, and you descend again.

The systems already modelled this before we named it, which is the sign it's the right theme rather than a coat of paint. What naming it changes is the *writing discipline* and the *ethics*, both of which are now load-bearing:

1. **Never stated.** No character names it. No codex explains it. The player says it out loud, around run fifteen, or never — and both are fine.
2. **Never accusatory.** We do not judge the player for playing. *Spec Ops: The Line* is the cautionary reference: it indicts you for what it forced you to do. We show the shape; the conclusion is the player's.
3. **The character is trapped. The person holding the controller is not.** A game about compulsion owes it to its audience to make *stopping* easy and unpunished — see `PRO-005 §11`.

**The light you don't walk toward** is already in the design: the Ashen Lodge (`DES-007`) sit in the Lair offering a smaller, safer, poorer life, and they are correct about everything. You walk past them every run.

## Emotional target

The feeling we are chasing, in one sentence: **"I have enough. I should leave. One more room."**

Everything in the design exists to sharpen that sentence. Loot creates the *enough*. Extraction pressure creates the *should leave*. Quest layering creates the *one more room*. The dragon makes all three personal.

The secondary emotion, felt only after death: **"I built that. She remembers."** — the meta-layer should feel like a *relationship with an escalating cost*, not a progress bar.

## Pillars

### P1 — Greed is the core mechanic
Loot is not a reward for playing well, it is a *liability you chose to carry*. Weight, noise, corruption, and the dragon's attention all scale with what you're hauling. Every valuable thing you pick up should make the walk to the exit meaningfully worse. See `DES-005`, `DES-008`.

### P2 — The dungeon is a place, not a level
Barony's magic is that its dungeons behave like *rooms with physics and rules* rather than encounter arenas. Objects can be picked up, thrown, burned, and broken. Enemies fight each other. Traps are hazards for everyone. We inherit this: **systemic interactions over scripted encounters**. See `DES-007`.

### P3 — The pact escalates
The dragon's gifts are not free and never finished. Vertical power raises your obligation (Tithe), which raises required depth, which raises risk. **The game gets harder because you got stronger, by design.** See `DES-003`, `DES-004`.

### P4 — Many threads, one exit
DMZ's genius was holding 3–6 objectives at once, from different factions, with different exit implications. You are always overcommitted. We adopt layered concurrent contracts rather than a single linear objective. See `DES-006`.

### P5 — Death is a chapter break, not a wipe
Losing a run must sting; losing a *lineage* must be a story beat. The reset returns you to zero *capability* but never to zero *knowledge*. See `DES-003`.

## Scope reality check

Target: **solo or 2–3 person team**. That forces hard constraints, stated now so they can be defended later:

| Constraint | Value | Why |
|---|---|---|
| Art style | Stylized low-poly, flat/gradient textures, strong silhouettes | Cheapest style that still reads as intentional. Barony precedent. |
| Biomes at 1.0 | 3 | Each biome is ~2 months of tileset + enemy + hazard work. |
| Enemy archetypes at 1.0 | ~12, heavily recombined via modifiers | Systems over content (Principle 5). |
| **Co-op** | **1–4 players, core from M1** (ADR-008) | Primary experiences are 2p and 4p; solo fully supported. Costs ~1.5–2× overall, QA especially — accepted deliberately, because retrofitting is a rewrite and co-op is the strongest retention lever we have. See `DES-012`, `TEC-004`. |
| Run length | 15–30 min ⟨tune⟩ | Long enough for the greed arc, short enough that death is survivable emotionally. |
| Voice acting | None | Text + expressive audio only. |

> **DECIDED (ADR-033):** The game is called **SHE**. Not a placeholder. It withholds exactly what the game withholds — a creature the player never names — and the lowercase intimacy does more work than any compound fantasy name would. Trademark and handle searches still needed before store presence (`PRO-004`).

> **DECIDED (ADR-034):** **Solo development, no fixed timeline.** Milestone order and exit gates stand; calendar estimates are gone. This is explicitly an experiment in a crowded genre — the aim is to find out what a systemically honest extraction roguelite feels like, not to hit a market window. That makes the M1 feel-gate *more* important, not less.

### P6 — Together in the dark
Co-op is core (ADR-008), and it is not "the same game with more people." A party is safer moment-to-moment, far more *hunted*, and yields less each (`DES-012`). Six classes exist so a party has shape (`DES-011`), and rescuing a fallen friend — carrying their ember out — is the single most heroic act in the game.

## What this game is not

See `CLAUDE.md §2` anti-goals. Most importantly: **this is not a PvP extraction game.** The tension comes from the environment, the timer, and your own greed — not from other players stealing your kit. That choice is defended in `DES-002`.
