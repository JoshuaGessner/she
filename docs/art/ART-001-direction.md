---
id: ART-001
title: Art & Audio Direction
status: draft
owner: art
tags: [art, audio, style, budget, readability]
updated: 2026-08-12
related: [DES-001, DES-005, DES-006]
---

# Art & Audio Direction

*Stub — expanded at M4 (`PRO-001`). Recorded now because style decisions constrain the engine work in `TEC-001`.*

## Visual target

**Stylized low-poly with strong silhouettes and hand-controlled lighting.** Chosen because it is the cheapest style that still reads as deliberate rather than unfinished, and because it serves Principle 6 (legibility beats realism).

- **Silhouette first.** Every enemy must be identifiable as a black shape at 20m. This is a survival requirement in a first-person game where things approach from the dark.
- **Darkness is a mechanic, not an effect.** Light sources are a resource the player manages (`DES-008` — the lantern occupies a weapon slot). Lighting design is gameplay design here, so it can't be handed off as polish.
- **Elegiac palette:** desaturated stone, cold blues, with **gold as the only truly saturated colour in the world.** Treasure should be visually magnetic. Greed should be a *visual* pull before it's a mechanical one.
- **Material grubbiness.** Wear, damage, dust. The world is a corpse being looted.

## Audio target

Audio does disproportionate work in this design and should be resourced accordingly:

- **Clamor must be audible.** The player has to *hear* their own greed — coins shifting, plate clanking, footfalls getting heavier. This is the primary feedback channel for the game's core mechanic.
- **The Hunt takes over the mix.** When it begins, music drops out; ambience narrows to breath, distant impacts, and the Hunter's signature sound. `AudioDirector` (`TEC-001`) owns this transition and it needs to be excellent.
- **The Hunter needs an unmistakable audio identity** — the single most important sound in the game. Reference: the Alien's ceiling movement in *Alien: Isolation*, Mr. X's footsteps in *RE2*.
- **She has a voice.** Not words — a felt presence. Low, slow, enormous, and *close*, since she speaks into the mind of the Bound.

## Budget notes

- No facial animation, no lip sync, no voice acting (`DES-001`).
- Enemy variety comes from **recolour + modifier + behaviour swap** on a small base set (Principle 5).
- Room modules are the art unit — a strong module library is worth more than any individual asset.

> **OPEN:** Bought asset packs vs. bespoke? A coherent purchased base kit is a legitimate accelerator, but mixing packs is the classic way an indie game ends up looking like an asset flip. If buying, **buy one kit and stay inside it.**
