---
id: ART-004
title: Asset Pipeline & Production Schedule
status: accepted
owner: art
tags: [art, assets, pipeline, blender, godot, production, specs]
updated: 2026-08-14
related: [ART-001, PRO-001, TEC-001, TEC-002, DES-013, DES-017]
---

# Asset Pipeline & Production Schedule

**This document answers two questions: what art is needed, and when.** It is the standing reference for asset requests — if something is needed and isn't listed here, this document is wrong and should be updated.

---

## The three phases (ADR-046)

| Phase | What it is | Purpose | When |
|---|---|---|---|
| **1 — Blockout** | Grey/proxy geometry. Correct scale, correct silhouette, no detail. | Prove the game **plays**. Feel, spacing, sightlines, readability. | M1–M2 |
| **2 — Pass** | Real models, not final. Correct forms, placeholder materials. | Prove the game **reads**. Silhouettes, colour blocking, environmental storytelling. | M3 |
| **3 — Final** | Shipping models and materials. | Prove the game **looks right**. | M4 |

**The rule that makes this work: blockout must be honest about scale and silhouette.** A proxy that is the wrong size or the wrong shape makes the feel test lie, and the feel test is the only thing M1 is for. Grey is fine. Wrong proportions are not.

## The shader is critical path, not polish

The custom shader carries most of the art direction (ADR-046). That has a consequence worth stating plainly:

> **One shader improves every asset at once. Per-asset polish scales linearly with content.**

For a solo project this is the highest-leverage art decision available, and it means the shader should be **prototyped early — during Phase 1** — not treated as a finishing pass. Models can then be built knowing what the shader needs from them.

> **See `ART-005`.** The shader is **hand-inked printmaking** — screen-space edge detection with hand-drawn wobble, hatching instead of gradients, pale ink on black in the Deep and black ink on white in the Threshold.

**Proposed vertex-colour channels (Q94):**

| Channel | Drives |
|---|---|
| **R** | Outline weight — 0 suppresses outlines entirely, 1 heavy |
| **G** | Hatch density bias |
| **B** | Ink / material ID (stone, metal, cloth, flesh, gold) |

Cheap to author, requires no texture work in Phases 1–2 — but **every model must carry vertex colours from the start.** Retrofitting them across a finished library is miserable, which is why this is the one art decision that cannot wait.

---

## Technical specifications

**These apply to every asset, in every phase.** Getting them right in blockout means Phase 2 and 3 are swaps rather than rework.

### Format & transform

| | |
|---|---|
| **Export format** | **glTF 2.0 binary (`.glb`)** — Godot's preferred path |
| **Units** | **1 unit = 1 metre** |
| **Orientation** | **Y-up, −Z forward** (Godot convention; set this on export from Blender) |
| **Scale** | Apply all transforms before export. No inherited scale. |
| **Pivots** | Props: **base centre**. Characters: **between the feet**. Doors: **on the hinge**. |
| **Naming** | `env_delvings_pillar_a.glb`, `chr_huskarl.glb`, `prp_coinpile_03.glb`, `wpn_hammer.glb` |

### Poly budgets ⟨tune⟩

Stylised low-poly, and these are generous rather than tight — the target is *readable*, not *cheap*:

| Category | Triangles |
|---|---|
| Small props | 100 – 800 |
| Large props / architecture | 500 – 3,000 |
| Standard enemies | 2,000 – 6,000 |
| Player classes | 4,000 – 10,000 |
| **Hero assets** (the Gullsjúkr, She) | 15,000 – 40,000 |

Godot 4 **auto-generates LODs on import**, so authoring LODs by hand is unnecessary unless something specific breaks.

### Collision

Godot builds collision from glTF node-name suffixes on import — use them and collision is free:

- `-col` — convex collision, mesh still visible
- `-colonly` — collision only, mesh not rendered
- `-convcolonly` — convex collision only

**Author simplified collision proxies for anything complex.** Never use a 20k-triangle hero mesh as collision.

### Characters — the single most important rule

> **All humanoid characters share one skeleton.**

Six player classes, the Bound, humanoid enemies — **one rig**. This is the difference between authoring **one** locomotion set and **six**. It is the largest single animation saving available and it is free if decided now and expensive to retrofit later.

- Standard humanoid bone hierarchy and naming (Mixamo-compatible is a pragmatic default — it makes purchased and generated animation directly usable)
- Class differences come from **proportion, silhouette, and gear**, not from bone structure
- **First-person arms are a separate mesh** — first person everywhere (ADR-047) means the player sees their own hands constantly and everyone else's full body

### Materials

- **Phase 1:** a single flat grey material. Nothing else.
- **Phase 2:** flat colour blocking only — no textures, no detail.
- **Phase 3:** final, authored to the shader's requirements.
- **No baked lighting or baked ambient occlusion in textures.** Lighting is dynamic and the shader owns it (`ART-001` — darkness is a mechanic).

---

## What the ink shader changes about authoring (`ART-005`)

Three consequences, and the first is a large saving.

### ✅ Environment assets do not need UVs

Hatching is **triplanar-projected in world space**, so surfaces are textured without an unwrap. **No UV authoring for architecture, props, or set dressing.**

This is a direct windfall for a pipeline built on purchased kits and Meshy output, where UVs are typically unusable — an entire authoring stage disappears. *(Characters and anything needing an authored decal or insignia still want UVs.)*

### ⚠️ Hard edges are now art-critical

The outline pass reads the **normal buffer**. A model exported with everything smooth-shaded produces **weak or missing interior lines** — the shader has nothing to detect.

- **Author explicit hard edges / split normals** on anything with a defined form: masonry, plate, timber, blades, cut stone.
- Smooth only what is genuinely smooth: cloth, flesh, organic growth.
- **Check every model with flat shading before export.** If it looks correct flat-shaded, it will ink correctly.

This replaces texture detail as the main authoring effort. **Silhouette and edge flow are the art now.**

### ⚠️ Scale accuracy is now art-critical

Triplanar projection is **world-space at a fixed density**. A model exported at the wrong scale gets **wrong hatch density** — it will read as the wrong size even if it looks right in isolation.

**Apply transforms, verify against a 1.8m reference figure before export.** This was already a spec; it is now a visual bug rather than a tidiness issue.

### Vertex colours are mandatory from Phase 1

| Channel | Drives |
|---|---|
| **R** | Outline weight — 0 suppresses outlines entirely, 1 heavy |
| **G** | Hatch density bias |
| **B** | Ink / material ID (stone, metal, cloth, flesh, gold) |

Blockout can ship flat `RGB(1, 0.5, 0)` — full outline, neutral hatch, default ink — and be refined later. But **the channels must exist from the start**; retrofitting vertex colours across a finished library is miserable.

---

## Asset schedule — what's needed, when

### M1 — The Feel Prototype · *Phase 1 blockout only*

Almost nothing. **Resist making anything nice.**

- One grey **test room set** — a corridor, a large room, a doorway, stairs, a ledge. Correct scale.
- One **weapon** proxy + first-person arms proxy
- One **enemy** proxy — correct height and silhouette
- One **player capsule** with correct collider dimensions

> If M1 looks good, time was spent in the wrong place. Its only job is answering whether moving and fighting is fun.

### M2 — The Loop Prototype · *Phase 1*

- **Loot proxies** at three size classes — small/light (gems), medium, large/heavy (coin chest). Distinct silhouettes; the player must tell them apart instantly.
- **The Gullsjúkr — first real asset request.** Even in blockout it needs a correct, unmistakable silhouette: huge, lopsided, weighed down. This is the hero asset (`DES-017`) and its shape carries the whole threat read.
- **Waystone / Shaft / Deep Gate** proxies — extraction points must be readable from distance.
- **Threshold blockout** — fire, four campsite plots, Descent, board, forge.
- **Chamber blockout** — her mass, the hoard volume.

### M3 — The Pact · *Phase 2 begins*

- **Two player classes**, full — model, rig, locomotion set (Húskarl and Veiðimaðr per `PRO-001`)
- **Hoard system geometry** — the growing pile (`DES-014`). Modular, instanced, scalable.
- **Skill tree and Legacy screen** UI art
- **The Ear** — final art, since it is the most-looked-at element in the game (`DES-019`, ADR-042)
- Delvings **modular kit**, Phase 2 quality

### M4 — Vertical Slice · *Phase 3*

- **All six classes**, final
- ~6 enemy archetypes, final
- **The Gullsjúkr, final** — most animation and most attention of any asset
- **She** — final. The largest single art asset in the game.
- Full Delvings kit, hazards, props, trophies, campsite customisation parts
- Complete UI

---

## Working with generated and purchased assets

**Meshy and similar tools** are a legitimate accelerator, with a known pipeline:

1. Generate → **import into Blender** → retopologise or decimate → fix normals and UVs → apply transforms → export `.glb`
2. Expect **bad topology, dense meshes, and strange UVs**. Treat output as a *sculpt reference*, not a finished asset.
3. Works best for **organic props and one-off set dressing**. Poor for anything that needs to deform, tile, or hit an exact silhouette.

**Purchased kits:** fine for volume environment work. Retexture and treat them through the shader so they stop reading as the kit they came from.

> **Legal note (`PRO-004`):** purely AI-generated output has **unsettled and in some jurisdictions absent copyright protection** — the US Copyright Office has held that works without human authorship are not registrable. Meaningful human modification adds protectable authorship. **The Blender-cleanup step is therefore doing legal work as well as technical work**, which is a good reason never to ship raw generated output. Keep records of what was modified. Not legal advice; flag it at the pre-release IP review.

---

## How to request and deliver assets

**Requests are made from this schedule**, in this form:

```
ASSET REQUEST
  name:        prp_coinpile_03
  category:    prop / small
  phase:       1 (blockout)
  needed for:  M2 loot readability test
  silhouette:  must read as "heavy money" at 15m, distinct from gems
  budget:      ~400 tris
  collision:   -convcolonly proxy
  notes:       three variants eventually; one is enough for blockout
```

**Delivery:** drop `.glb` files into `game/assets/<category>/`. Godot imports on focus. If something imports wrong, the fix is almost always transform, scale, or orientation — check those three before anything else.

**Standing rule:** if an asset is needed that isn't on the schedule above, **the schedule is wrong and gets updated** in this document. The schedule is the source of truth for what production owes the design.

## Open questions

> **OPEN (Q94):** What does the custom shader read — vertex colours, mask texture, palette atlas, or material IDs? **Decide before Phase 2**; it changes how every model is authored and is painful to retrofit.

> **DECIDED (ADR-054):** **2m grid.** Divides cleanly into first-person corridor and room widths while staying fine enough for interesting silhouettes; a 4m grid would force coarser spaces. Makes modules interchangeable across biomes. ~~Original:~~ Is there a shared **modular kit grid** (e.g. 2m or 4m) for architecture? Cell-based generation (ADR-014) strongly favours one, and it makes environment assets interchangeable across biomes.

> **OPEN (Q96):** First-person arms — one universal pair, or per-class? Per-class is far better for identity (a Húskarl's gauntlets versus a Völva's bare hands) and multiplies the most-viewed asset in the game by six.
