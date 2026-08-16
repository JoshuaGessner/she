---
id: ART-005
title: The Ink Shader — Visual Direction
status: accepted
owner: art
tags: [art, shader, rendering, style, godot, legibility]
updated: 2026-08-15
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

> **VALIDATED at `M1-T09` (ADR-070) — GO.** Reproduce with `python3 tools/run_ink_spike.py`. Measured pass cost **~0.15–0.23 ms at 1152×648**, ≈0.4–0.6 ms at 1080p — about 3% of a 60 fps frame.

**Screen-space edge detection** on the depth and normal buffers (Sobel or Roberts cross), run as a full-screen pass.

> **The depth threshold must scale with N·V, or the technique does not work.** A fixed threshold renders every floor and ceiling as solid scribble: depth changes enormously from pixel to pixel on any surface seen edge-on, *even when that surface is perfectly flat*. Widening the tolerance as the surface turns away is what distinguishes a genuine discontinuity from foreshortening. This is not a tuning preference — the first spike build was unusable without it (ADR-070).

Chosen over inverted-hull because it catches **interior creases** — folds, corners, and detail *inside* a silhouette, which is what makes a drawing read as drawn rather than as an object with a border. One pass for the whole scene rather than per-object cost.

Godot 4 exposes depth and normal-roughness textures to spatial shaders; Godot 4.3+ `CompositorEffect` is the clean home for this.

### 2. The hand-drawn quality — **this is the whole thing**

A clean Sobel edge looks like a *technical* drawing. Three treatments turn it into a hand-drawn one, and they matter more than everything else on this page:

- **Line wobble.** Offset edge sampling by a noise texture so lines waver like a drawn stroke instead of following geometry exactly. **Amplitude belongs near one pixel** ⟨tune⟩ — measured at `M1-T09`, a stroke that wanders further than its own width stops reading as a line and becomes a smudge.
- **Boil.** **Update that jitter at 8–12 fps, not 60.** This is *the* trick. Hand-drawn animation shimmers because each frame was redrawn; quantising the wobble to a low framerate reproduces that instantly. Without boil the look is sterile; with it, it reads as animation. Cheapest, highest-impact line in this document.
- **Variable weight.** Line thickness driven by depth discontinuity and a noise term, so strokes thicken and thin like a real nib.

### 3. Fill — hatching, not gradients

Value comes from **hatching**, not smooth shading. Lighting is quantised to a few hard bands; darker bands get denser hatch. This is what makes it printmaking rather than cel shading, and it is dead-on for the Norse woodcut register.

**Which space the hatching lives in is the most consequential technical decision in this document.** It has a formal answer — see below.

---

## The hatching problem, and the answer

### The named trade-off

Bénard, Bousseau & Thollot's *State-of-the-Art Report on Temporal Coherence for Stylized Animations* (2011) identifies **three goals that any stylised animation wants, and proves they are mutually contradictory** — you cannot have all three, and every technique is a trade-off between them:

| Goal | Meaning | Fails as |
|---|---|---|
| **Flatness** | Marks look like ink on a flat page | Lost when strokes bend around 3D form |
| **Motion coherence** | Marks follow the object's motion | Lost as the **"shower door effect"** — the world slides beneath a pattern stuck to your screen |
| **Temporal continuity** | Marks don't flicker or pop between frames | Lost as swimming, popping, boiling |

Screen-space tiling *perfectly preserves the pattern* but slides under animation. Object-space *perfectly attaches to surfaces* but distorts and scales under perspective.

**Praun, Hoppe, Webb & Finkelstein's "Real-Time Hatching"** (SIGGRAPH 2001) is the canonical solution and it **chose object-space coherence** — building **Tonal Art Maps**: mipmapped hatch images per tone, with strokes scaled to hold correct density at every resolution and *nested* so they stay coherent across scales and tones.

### The answer for this game: each layer takes a different corner

> **Don't pick one space. Split the three layers, and let each one sacrifice a different goal.**

| Layer | Space | Wins | Sacrifices |
|---|---|---|---|
| **Paper & grain** | **Screen-space** | Flatness — it *is* the page, and a page genuinely is fixed in front of you | Motion coherence, correctly |
| **Hatching** | **World-space (triplanar)** | Motion coherence + temporal continuity | Some flatness |
| **Outlines** | **Screen-space + boil** | Flatness + the hand-drawn read | Temporal continuity — **deliberately** |

That last row is the elegant part: **the boil is the artefact, embraced.** Hand-drawn animation flickers because every frame was redrawn. We are not fighting temporal discontinuity in the outlines — we are *authoring* it.

And it matches real hand-drawn practice: **contours are redrawn every frame; fills and hatching are held or shot on twos.** Outlines boiling more than hatching is not inconsistent, it is how animation actually works.

### Why object-space hatching, specifically

- **First-person, camera always moving.** Screen-space hatching would shower-door constantly and it would be *in your face* the entire run. This is the decisive argument.
- **The fiction is that the world is drawn** — not that you are looking at a drawing. Ink belongs to surfaces.
- **A real woodcut's lines describe form.** They are carved to follow the object. Object-space is truer to the reference than screen-space is.

### The cheap implementation: triplanar, not lapped textures

Full TAM requires lapped-texture parametrisation over a curvature-aligned direction field. **That is far too much for a solo project.** The 80% version:

1. Author **4–6 hatch textures**, **nested** — each darker layer contains all strokes of the lighter one, plus more. *(This nesting is the core TAM insight and it is what prevents popping when tone changes.)*
2. Project them **triplanar in world space** at a fixed world scale, so density is consistent regardless of object size.
3. Blend between adjacent layers by quantised lit tone.
4. Let **mipmaps** handle distance — the density-under-zoom problem TAMs solve is largely free here.
5. Optional: a low-amplitude tone jitter on the same 8–12 fps clock as the outline boil, so hatching feels connected to the linework without swimming.

> **The production windfall: triplanar needs no UVs.**
>
> Environment assets do not have to be unwrapped. For a pipeline built on bought kits and Meshy output — where UVs are typically garbage — this removes an entire authoring stage. See `ART-004`.

---

## Godot 4 constraints (verified)

| | |
|---|---|
| **Depth** | `uniform sampler2D depth_texture : hint_depth_texture;` — available broadly, but values are **non-linear** and must be linearised: build NDC from `SCREEN_UV` + depth, multiply by `INV_PROJECTION_MATRIX`, then **negate Z**. Vulkan NDC conventions differ from Compatibility. |
| **Normals** | `hint_normal_roughness_texture` — **Forward+ only.** Deliberately, and per the Godot issue tracker it is **not expected to be implemented** for Mobile or Compatibility due to cost. |
| **Viewport** | The depth texture can only be read **from the current viewport.** |
| **Home for the pass** | `CompositorEffect` (Godot 4.3+), `EFFECT_CALLBACK_TYPE_POST_TRANSPARENT` for full-frame work. |

> **Consequence: Forward+ is locked in — and this costs us nothing.**
>
> **"Mobile" is a Godot renderer name, not a platform.** Forward+ is the **default and correct renderer on Windows, macOS, and Linux**, which are our only targets. Full explanation in `TEC-001`.
>
> We would choose Forward+ **independently of this shader**: Mobile caps omni/spot lights at **8 per mesh**, and our lighting design — darkness as a mechanic, up to four moving player lanterns, braziers, the ember — would blow straight through that. The normal buffer comes along free.
>
> Real costs: no web export (not a target), and a hardware floor around Vulkan/D3D12/Metal-capable GPUs (2012-era and later — negligible for premium Steam).

**Known limitation:** depth+normal edge detection misses boundaries between objects that are **coplanar and similarly oriented** — two touching walls of the same material produce no line. The full fix is an object-ID buffer. The cheap mitigation is the vertex-colour ink-ID channel biasing local outline generation. Prototype before deciding whether the ID pass is worth it.

**Sources:** [Real-Time Hatching (Praun, Hoppe, Webb & Finkelstein, SIGGRAPH 2001)](https://hhoppe.com/hatching.pdf) · [State-of-the-Art Report on Temporal Coherence for Stylized Animations (Bénard, Bousseau & Thollot, 2011)](https://www.semanticscholar.org/paper/State%E2%80%90of%E2%80%90the%E2%80%90Art-Report-on-Temporal-Coherence-for-B%C3%A9nard-Bousseau/8437952b7e15b0ca8387b6be36e2002c08ae92c1) · [Godot advanced post-processing docs](https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html) · [Godot issue #78411 — normal_roughness on Mobile](https://github.com/godotengine/godot/issues/78411)

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

> **OPEN (Q101):** How many nested hatch layers — 4, 5, or 6? Fewer is less authoring and coarser tone control. Start at 4 and add only if banding is visible.

> **OPEN (Q102):** Does the object-ID buffer get built, or do we live with missing coplanar edges? Prototype the ink-ID mitigation first; only build the ID pass if it visibly fails.
>
> **Still open after `M1-T09`.** The spike staged two flush, coplanar, identically-oriented faces on purpose, but they are not legible in the captures — so nothing was learned either way. This needs a dedicated test that isolates the case, not an inference from a busy frame (ADR-070).
