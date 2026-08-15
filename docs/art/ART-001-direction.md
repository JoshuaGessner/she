---
id: ART-001
title: Art & Audio Direction
status: accepted
owner: art
tags: [art, audio, style, budget, readability]
updated: 2026-08-14
related: [DES-001, DES-005, DES-006]
---

# Art & Audio Direction

**Index doc.** The direction now lives across four documents: **`ART-002`** audio design · **`ART-003`** composer brief · **`ART-004`** asset pipeline and production schedule · **`ART-005`** the ink shader and visual direction. What remains here are the principles that govern all of them.

## Visual target

> **SUPERSEDED IN PART by `ART-005`.** The style is now **hand-inked printmaking** — *a woodcut you can walk through, drawn by your lantern.* The Deep is pale ink on black; the Threshold is hard black ink on white. **Gold is the only saturated colour in the game.** Full direction and technical approach in `ART-005`. The silhouette and darkness principles below stand and are *strengthened* by it.

**Stylized low-poly geometry with strong silhouettes and hand-controlled lighting**, treated by the ink shader. Low-poly remains correct because the shader supplies the treatment — geometry only has to be right in *shape*, which is the cheapest thing to get right and the thing Principle 6 depends on.

- **Silhouette first.** Every enemy must be identifiable as a black shape at 20m. This is a survival requirement in a first-person game where things approach from the dark.
- **Darkness is a mechanic, not an effect.** Light sources are a resource the player manages (`DES-008` — the lantern occupies a weapon slot). Lighting design is gameplay design here, so it can't be handed off as polish.
- **Elegiac palette:** desaturated stone, cold blues, with **gold as the only truly saturated colour in the world.** Treasure should be visually magnetic. Greed should be a *visual* pull before it's a mechanical one.
- **Material grubbiness.** Wear, damage, dust. The world is a corpse being looted.

## Audio target

Audio does disproportionate work in this design and should be resourced accordingly:

- **Clamor must be audible.** The player has to *hear* their own greed — coins shifting, plate clanking, footfalls getting heavier. This is the primary feedback channel for the game's core mechanic.
- **Clamor is carried by adaptive score, never by alarms** (ADR-035). One piece of music per biome, authored as **stems that enter and leave under a Clamor/Hunt driver** — vertical remixing. Alarms are threshold signals; Clamor is continuous, and layered audio expresses continuity natively. It also fatigues far less over a 25-minute run and keeps the Deep feeling like a place rather than a UI. Full state table in `DES-018`.
- **This must be architected from day one.** Stems authored together, mixed live. One-shot cues cannot be retrofitted into a vertical-remix system. **`AudioDirector` is a core system, not a budget line.**
- **The Hunter owns one reserved instrument** — a single bowed tagelharpa note that means the Gullsjúkr (`DES-017`) and *nothing else, anywhere in the game, ever*. It must never be a false alarm. Reference: the Alien's ceiling movement in *Alien: Isolation*, Mr. X's footsteps in *RE2*.
- **The Hunter sounds like money.** Its movement is a great deal of loose coin being dragged. That single sound is its footstep, its tell, and its entire characterisation.
- **Silence is a designed beat.** When the Gullsjúkr stops to collect thrown gold, the mix drops away — relief, and your window.
- **Every audio channel has a visual twin** (ADR-036). Nothing may be audio-only; see `DES-018`. The standing test is that the game is playable to completion with sound off.
- Diegetic sound (footsteps, coin, doors) stays **separate and unducked** — it is gameplay information, not atmosphere.
- **She has a voice.** Not words — a felt presence. Low, slow, enormous, and *close*, since she speaks into the mind of the Bound.

## Budget notes

- No facial animation, no lip sync, no voice acting (`DES-001`).
- Enemy variety comes from **recolour + modifier + behaviour swap** on a small base set (Principle 5).
- Room modules are the art unit — a strong module library is worth more than any individual asset.

> **DECIDED (ADR-046):** **Three-phase pipeline** — blockout → pass → final. Environment volume from an owned library plus self-authored work (Blender, ShapeLab, Meshy); **identity assets always bespoke.** The asset-flip risk is handled by the **ink shader** (`ART-005`), which treats every surface uniformly and is far more effective at unifying mixed sources than staying inside a single purchased kit would have been. Full schedule and specs in `ART-004`.
