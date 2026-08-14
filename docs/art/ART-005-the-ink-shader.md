---
id: ART-005
title: The Ink Shader — Visual Direction
status: proposed
owner: art
tags: [art, shader, rendering, style, godot, legibility]
updated: 2026-08-14
related: [ART-001, ART-004, DES-006, DES-018, DES-019, TEC-001]
---

# The Ink Shader — Visual Direction

## The pitch

> **A woodcut you can walk through, and your lantern is drawing it.**

The world is rendered as hand-inked linework. Not cel shading, not toon outlines — **printmaking.** Hard contour lines, flat fills, hatching instead of gradients, and the wobble of a line drawn by a hand rather than a computer.

## The inversion, and why

The reference look — **black ink on white** — is beautiful and it cannot work here unmodified. A white-lit world has no darkness, and `ART-001` makes darkness a mechanic: the lantern costs a weapon slot, light is a managed resource, enemies must read as silhouettes at 20m.

> **So flip it. The Deep is drawn in pale ink on black. Darkness is the paper.**

Your lantern does not illuminate. **It draws.** Edges appear as strokes where your light reaches and fade to blank page where it does not. Walking into an unlit room is walking onto paper nobody has drawn on yet.

Everything falls out of this correctly:

- **Darkness is preserved as a mechanic** — it is now literally the absence of the drawing.
- **Light equals information**, which is already the game's economy: lantern, map, and compass all cost you a slot (`DES-019`).
- **It fits the setting.** Norse and Anglo-Saxon visual culture *is* incised line — runes, carved stone, woodcut. This ties the shader to `DES-006` instead of being a generic stylisation.
- **It is not a look anyone has shipped.** Sable does flat colour with black outlines in daylight; Obra Dinn does 1-bit dither. Inverted ink-on-black, drawn by a light source, is unclaimed.

## Two worlds, two treatments

The reference image's look isn't discarded — it is **the safe place.**

| | The Deep | The Threshold & Chamber |
|---|---|---|
| **Ground** | Black. Undrawn paper. | **White. Fully drawn.** |
| **Ink** | Pale bone-white, appearing only in lantern reach | Hard black, everywhere, confident |
| **Feel** | An unfinished page | A finished print |
| **Why** | Darkness is a mechanic here | There is no darkness mechanic in the hub |

**The safe place literally looks like a completed drawing.** The dangerous place is one that hasn't been drawn yet, and you are drawing it as you go, badly, with a lantern.

That contrast does the same work `ART-002` asks of audio — the Threshold as the only warm, resolved, *finished* thing in the game.

## Colour: gold is the only colour

The brief was *more colour than the reference, but not much, and dark.* The rule that delivers it:

> **Colour is value. Gold is the only saturated hue in the game.**

- **Base palette:** black, bone-white, and greys. Ink and paper.
- **Gold / warm amber** — treasure, your ember (ADR-042), her fire. **The only genuinely saturated colour that exists.**
- **One cold accent per biome**, used sparingly: Delvings a cold mineral blue-green; Barrow-Fields a sickly bone-ochre; Sunken Wood a deep viridian.
- **Blood** is desaturated almost to black.

In a game about greed, **the only thing in colour is treasure.** The player's eye is pulled to exactly the thing that will get them killed, and that is not a metaphor we have to explain — it is just how the screen looks.

**The Gullsjúkr is therefore the most saturated object in the game.** A monochrome ink world, and the thing hunting you is a mass of gold. It will be visible from across a room and it will look wrong.

---

## Technical approach (Godot 4)

Four stacked components. None is exotic; the *combination* and the hand-drawn treatment are what make it.

### 1. Outlines — screen-space, not inverted hull

**Screen-space edge detection** on the depth and normal buffers (Sobel or Roberts cross), run as a full-screen pass.

Chosen over inverted-hull because it catches **interior creases** — folds, corners, and detail *inside* a silhouette, which is what makes a drawing read as drawn rather than as an object with a border. One pass for the whole scene rather than per-object cost.

Godot 4 exposes depth and normal-roughness textures to spatial shaders; Godot 4.3+ `CompositorEffect` is the clean home for this.

### 2. The hand-drawn quality — **this is the whole thing**

A clean Sobel edge looks like a *technical* drawing. Three treatments turn it into a hand-drawn one, and they matter more than everything else on this page:

- **Line wobble.** Offset edge sampling by a noise texture so lines waver like a drawn stroke instead of following geometry exactly.
- **Boil.** **Update that jitter at 8–12 fps, not 60.** This is *the* trick. Hand-drawn animation shimmers because each frame was redrawn; quantising the wobble to a low framerate reproduces that instantly. Without boil the look is sterile; with it, it reads as animation. Cheapest, highest-impact line in this document.
- **Variable weight.** Line thickness driven by depth discontinuity and a noise term, so strokes thicken and thin like a real nib.

### 3. Fill — hatching, not gradients

Value comes from **screen-space cross-hatching**, not smooth shading. Lighting is quantised to two or three hard bands; darker bands get denser hatch.

This is what makes it printmaking rather than cel shading, and it is dead-on for the Norse woodcut register.

### 4. Paper and ink

Subtle screen-space grain. Ink is never pure black; paper is never pure white. Slight bleed at stroke ends.

---

## The rule this creates for models (answers Q94)

If lighting is quantised and value comes from screen-space hatching, **models need very little from their materials.** Proposed vertex-colour channels:

| Channel | Drives |
|---|---|
| **R** | Outline weight — 0 suppresses outlines entirely, 1 heavy |
| **G** | Hatch density bias |
| **B** | Ink / material ID (stone, metal, cloth, flesh, gold) |

Cheap to author, no texture work in Phase 1 or 2, and outline suppression is essential — see below.

## The readability risk, and the fix

**Outlining everything at 150 agents in a cluttered dungeon is visual noise**, and Principle 6 says legibility beats realism. Mandatory controls:

- **Distance falloff** on line weight — distant geometry loses its outlines rather than becoming a scribble.
- **Outline suppression on unimportant props** via the R channel. Set dressing does not get lines.
- **Enemies and loot always outline**, at full weight, regardless of distance ⟨tune⟩. If the shader ever makes a threat harder to see, the shader is wrong.
- **Test in the busiest possible room** early. A style that only works in an empty corridor is not a style.

## Production consequences

- **The shader is critical path** (ADR-046) and should be prototyped during Phase 1, on blockout geometry. It is the single largest determinant of whether this game looks like anything.
- **Blockout will look nearly final in silhouette**, because the shader supplies most of the treatment. That is the payoff of a shader-led direction for a solo project.
- Godot's renderer must be **Forward+** for the depth/normal buffer access this needs.

## Open questions

> **OPEN (Q97):** Does the ink colour shift with biome (bone-white in the Delvings, ochre in the Barrows), or stay constant so only the accent changes? Constant is more disciplined; shifting is more atmospheric.

> **OPEN (Q98):** How hard is the transition between Threshold-white and Deep-black? A hard cut at the Descent is dramatic; a gradient down the first stair is more elegant. Leaning **hard cut** — crossing that threshold should feel like stepping into a different page.

> **OPEN (Q99):** Do *player characters* get heavier outlines than the world, so teammates read instantly in a cluttered room? Almost certainly yes, and it is nearly free.

> **OPEN (Q100):** Does hatching move with the camera (screen-space, more print-like, can swim) or stick to surfaces (object-space, more stable, less like a print)? **Prototype both** — this is the classic tradeoff in hatching shaders and it is a feel question.
