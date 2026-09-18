---
id: ART-006
title: Modelling Brief — for an Agent Building Assets
status: accepted
owner: art
tags: [art, assets, brief, modelling, specs, blender, gltf]
updated: 2026-09-18
related: [ART-001, ART-004, ART-005, TEC-008, PRO-004, DES-020]
---

# Modelling Brief

**This page is written to be handed to whoever or whatever is building the models.** It is self-contained on purpose: everything needed to produce a deliverable asset is here, so nothing has to be inferred from the rest of the documentation.

`ART-004` remains the pipeline and schedule. This is the working brief that sits under it, and `ART-005` is the reason most of the unusual rules exist.

> **Every rule in §2 is machine-checked.** `game/tests/art_probe.gd` runs on every commit and fails the build naming the file and the number that is wrong (ADR-258). You cannot deliver something that quietly violates the spec — but you also cannot find out by looking, so read §2 before modelling rather than after.

---

## 1. What the renderer does to your model, and why it changes everything

The game is rendered as **hand-inked printmaking** — a woodcut you can walk through. It is not cel shading and not PBR. A screen-space pass detects edges from the depth and normal buffers, draws them as wobbling hand-drawn lines, and fills surfaces with **hatching** instead of smooth shading.

Four consequences, and they invert normal low-poly habits:

**① Texture detail is invisible. Silhouette and edge flow are the entire art.**
There are no textures in this game. None. A surface's value comes from hatch density driven by lighting. If a form is not present in the **geometry**, it does not exist on screen. Carve it or lose it.

> **⚠️ This rule is under active review and may loosen in one specific direction.** The ink pass reads Godot's normal-roughness buffer, and a **normal map** perturbs exactly that data — so normal-mapped detail would be drawn as ink line by the edge detector *and* shift hatch density through the lighting, with no shader change. If that measures out, the rule becomes "no albedo or colour textures, no baked lighting" plus **one shared tileable triplanar normal map per material family**, coarse, not authored per asset.
>
> **Nothing in this brief changes if it lands.** Geometry still carries silhouette and form; a normal map would only add surface. Model to the rule as written and keep going.

**② Hard edges are functional, not stylistic.**
The outline pass reads the **normal buffer**. A model exported fully smooth-shaded produces weak or missing interior lines — the shader has nothing to detect, and the object reads as a blurry lump with a rim. **Split normals on everything with a defined form:** masonry, plate, timber, blades, cut stone, worked metal. Smooth only what is genuinely soft — cloth folds, flesh, organic growth, fungus.

> **Check every model flat-shaded before export. If it reads correctly flat-shaded, it will ink correctly.** This is the single most useful habit for this project.

**③ Scale accuracy is a visual bug, not a tidiness issue.**
Hatching is projected **triplanar in world space at a fixed density**. A model exported at the wrong scale gets the wrong hatch density and reads as the wrong size even when its dimensions are technically right. Verify against a 1.80 m reference figure. Apply all transforms.

**④ Environment and props need no UVs at all.**
Triplanar projection means architecture, props and set dressing are never unwrapped. Do not spend time on UVs for them. *(Characters and anything carrying an authored insignia still want UVs — but nothing in §6 does yet.)*

### Colour, in one rule

> **Gold is the only saturated hue in the game.**

Base palette is black, bone-white and greys — ink and paper. Warm gold is reserved for treasure, the player's ember, and her fire; it is the only genuinely saturated colour that exists. One cold accent per biome, used sparingly — the Delvings get a **cold mineral blue-green**. Blood is desaturated almost to black.

Materials are **flat colour only**. No textures, no gradients, and **no baked lighting or ambient occlusion** — lighting is dynamic and the shader owns it, because darkness is a game mechanic here.

---

## 2. The hard contract

Everything in this section is checked automatically. A failure blocks the build.

### 2.1 Format and transform

| | |
|---|---|
| **Format** | glTF 2.0 **binary** — `.glb`, one file per asset |
| **Units** | **1 unit = 1 metre.** Longest side of any asset must fall between 0.02 m and 120 m |
| **Orientation** | **Y-up, −Z forward** |
| **Transforms** | **Applied.** No node in the file may carry a scale — every node's scale must be exactly 1, 1, 1 (tolerance 0.001). This is the failure that arrives with almost every third-party asset |
| **Pivot — environment, props** | **Base centre.** The asset's lowest point must sit within 0.02 m of y = 0 |
| **Pivot — weapons** | **The grip**, with the weapon pointing along −Z and its "up" along +Y |
| **Pivot — characters** | Between the feet, y = 0 |

### 2.2 Where it goes

**The folder is the category.** Do not prefix filenames with the category — the folder already carries it.

| Folder | Triangle ceiling | Contents |
|---|---|---|
| `game/art/environment/` | **3,000** | Architecture, kit modules, anything built |
| `game/art/props/` | **3,000** | Set dressing, carried items, armour, treasure |
| `game/art/weapons/` | **800** | Anything held and swung |
| `game/art/enemies/` | **6,000** | Standard enemies |
| `game/art/characters/` | **10,000** | Player classes |
| `game/art/heroes/` | **40,000** | The Gullsjúkr, She |

Triangle counts are **ceilings, not targets.** They are generous deliberately — the goal is readable, not cheap. Coming in well under is fine and never a failure.

Filenames are `snake_case` and descriptive: `environment/delvings_wall_2x4.glb`, `props/coin_pile_a.glb`, `weapons/bearded_axe.glb`.

### 2.3 Vertex colours — required on every surface

Every surface of every mesh must carry a vertex-colour layer. A mesh without one fails the build.

| Channel | Meaning | Default |
|---|---|---|
| **R** | **Outline weight.** 1.0 = full heavy outline. 0.0 = outlines suppressed entirely | **1.0** |
| **G** | **Hatch density bias.** 0.5 = neutral. Lower = sparser strokes, higher = denser | **0.5** |
| **B** | **Ink / material ID.** A quantised identifier, see below | by material |

**The B channel's values are fixed by this brief. Use these exactly:**

| Value | Material |
|---|---|
| **0.0** | Stone — rock, masonry, cut stone, bone |
| **0.2** | Timber — wood, haft, plank, root |
| **0.4** | Metal — iron, steel, bronze, rivets |
| **0.6** | Cloth — linen, leather, hide, rope |
| **0.8** | Flesh — skin, fur, fungus, organic growth |
| **1.0** | Gold — treasure, gilding, the ember |

**Use R below 1.0 on set dressing that should not be outlined** — small clutter, rubble, scatter, anything that would turn a busy room into scribble at distance. Use the full 1.0 on anything a player needs to see and act on: doorways, ledges, loot, hazards, enemies.

> **Honest note:** nothing reads these channels *today*. The current ink pass is a full-screen post-process and per-vertex data is not in the buffers it samples (ADR-258, Q113). Author them anyway — retrofitting vertex colours across a finished library is miserable, they cost one operation per object, and the pass that reads them is a decision away rather than a rewrite away. **Do not skip them, and do not assume they are inert forever.**

### 2.4 Collision

Godot builds collision from glTF **node-name suffixes** on import — use them and collision costs nothing:

| Suffix | Result |
|---|---|
| `-col` | Convex collision; the mesh still renders |
| `-colonly` | Collision only; mesh not rendered |
| `-convcolonly` | Convex collision only |

**Every asset in `environment/` and `props/` must carry collision.** Verified working through a full export/import round trip.

**Author simplified collision proxies for anything complex.** A hero mesh is never its own collider. A `-colonly` box or a few convex hulls is correct; a 3,000-triangle collision mesh is a performance bug.

### 2.5 The 2 metre grid — `environment/` only

Every module's **footprint** (its X and Z extents) must be either:

- an exact multiple of **2.0 m** (tolerance ±0.02 m), or
- **under 2.0 m** — a pillar or a detail piece that is placed rather than tiled.

A 2.5 m wall does not tile and no amount of work downstream makes it tile cheaply. Height is unconstrained by this rule; §4 gives the heights that matter.

---

## 3. The world's dimensions

These are measured from the shipping build, not aspirational. Model against them.

### 3.1 The body

| | |
|---|---|
| Height | **1.80 m** |
| Eye line | **1.62 m** |
| Radius / width across | 0.35 m / **0.70 m** |
| Crouched height | 1.15 m |
| **Step the body walks up** | **0.10 m** — anything taller is a wall or a jump |
| Jump apex | 0.49 m |
| Sprint jump gap | ≈ 2.9 m of air |

### 3.2 The space

| | |
|---|---|
| **Plan cell** | **2.0 m** — the grid everything derives from |
| Corridor width | **2.0 m** (one cell) |
| Corridor ceiling | **2.6 m** |
| Room ceilings by volume | **1.4 m** (crawl — crouch-only), **2.4 m**, **4.0 m**, **7.0 m** |
| Generated wall thickness | **0.3 m** |
| Hand-built wall thickness | 0.6 m |
| **Door opening width** | **2.4 m** |
| Door lintel height | 2.2 m |
| Corner chamfer | **1.6 m** cut back |
| Ledge height above floor | **2.5 m** |
| Alcove mouth / ceiling | **1.5 m** / 2.2 m |
| **Steepest ramp that works** | **~30°** — steeper and the navigation mesh refuses it |
| Navigation clearance | Nothing may leave a walkable channel narrower than **0.9 m** |

> **A ramp never turns while it climbs.** Put a flat landing at every corner.

### 3.3 The depth gradient

The Delvings run through three bands as you descend. They are the same kit becoming less orderly, not three kits.

| Band | Fiction | Geometry |
|---|---|---|
| **1 — Aftermath** | Dvergar workings. Built, intact. | Orthogonal, square corners, even 4.0 m ceilings, flat floors |
| **2 — Retreat** | The workings failing into the seam | Corners chamfered, ceilings varying ±1 m, floors stepping |
| **3 — Cause** | What they dug into | Heavy chamfer, ceilings 2.4–7 m, floors stepping and sloping |

**Model Band 1 first and completely.** Bands 2 and 3 are variants of the same modules, and the kit is worth nothing until one band is whole.

---

## 4. Setting and IP safety — read before naming or designing anything

The setting is **Tolkien-adjacent, not Tolkien**. We draw from the public-domain sources Tolkien himself drew from: the Poetic and Prose Eddas, *Völsunga saga*, *Beowulf*, the *Nibelungenlied*, the *Kalevala*, and Anglo-Saxon material.

> **Fast rule: if you learned the word or the image from Tolkien, don't use it.**

Visually this means **Norse and Anglo-Saxon incised line** — runes, carved stone, interlace, woodcut. Migration-period and Viking-age metalwork and timber. Not high-fantasy elven filigree, not generic D&D dungeon.

No Tolkien-derived creature designs, no Tolkien-derived script or runic system, no architectural motifs recognisably from the films.

---

## 5. The piece list

Ordered by what unblocks the game soonest. **Deliver in order.** A complete category is worth more than three half-categories.

### 5.1 Priority 1 — The Delvings kit, Band 1 · `environment/`

This is where a player spends the most minutes, and it is the thing that currently reads as grey boxes.

**Dvergar workings: dressed stone, cut square, built by people who knew what they were doing and then left.** Tool marks, coursed masonry, iron fixings that have rusted, timber that has not been maintained. It should read as *abandoned infrastructure*, not as a cave and not as a castle.

| Piece | Footprint | Height | Notes |
|---|---|---|---|
| `delvings_wall_2x26` | 2.0 × 0.3 | 2.6 | Corridor wall panel |
| `delvings_wall_2x40` | 2.0 × 0.3 | 4.0 | Room wall panel — the workhorse |
| `delvings_wall_2x70` | 2.0 × 0.3 | 7.0 | Great-room wall panel |
| `delvings_wall_2x40_b` | 2.0 × 0.3 | 4.0 | Second variant — vary the coursing, not the outline |
| `delvings_doorway` | 4.0 × 0.3 | 4.0 | **2.4 m clear opening centred**, lintel at 2.2 m |
| `delvings_corner_inner` | 2.0 × 2.0 | 4.0 | |
| `delvings_corner_chamfer` | 2.0 × 2.0 | 4.0 | **1.6 m cut back** across the corner |
| `delvings_floor_2x2` | 2.0 × 2.0 | — | Flagged, worn. Keep it flat: a 0.10 m rise is a wall |
| `delvings_floor_2x2_b` | 2.0 × 2.0 | — | Variant |
| `delvings_ceiling_2x2` | 2.0 × 2.0 | — | Seen constantly in first person. Give it beams or vaulting |
| `delvings_alcove` | 2.0 × 0.6 | 2.2 | **1.5 m mouth**, recessed nook |
| `delvings_ledge_edge` | 2.0 × 0.6 | 2.5 | The lip of a raised deck |
| `delvings_ramp_2x25` | 2.0 × 6.0 | 2.5 rise | **~26°** — 5.0 m of run for 2.5 m of rise |
| `delvings_pillar` | 0.8 × 0.8 | 4.0 | Under 2 m, so placed rather than tiled |

### 5.2 Priority 2 — Items · `props/` and `weapons/`

**Twenty-five, all named, all already in the game.** Each has an authored ink icon in the inventory; these are the world models a player sees on the floor and in a hand.

Bag footprint is given in grid cells — **each cell is roughly a hand's width**, so it is a reliable proportion guide. Weight is the honest one: 26 kg of coin chest should look like 26 kg.

**Weapons** — `weapons/`, 800 tris, pivot at the grip, pointing −Z:

| File | Name | Bag | kg |
|---|---|---|---|
| `seax.glb` | Seax | 1×2 | 1.1 |
| `bearded_axe.glb` | Bearded Axe | 1×3 | 1.9 |
| `ash_spear.glb` | Ash Spear | 1×4 | 2.6 |
| `yew_bow.glb` | Yew Bow | 1×3 | 1.4 |
| `dvergar_hammer.glb` | Dvergar Hammer | 2×3 | 6.4 |
| `regin_blade.glb` | Regin's Blade | 1×4 | 3.2 |

> **Regin's Blade is a relic and the most storied object on this list** — Regin reforged the sword that killed Fáfnir. It should read as older and stranger than everything around it, and it is still under 800 triangles.

**Treasure** — `props/`, gold is the only saturated colour in the game, so these are the only things that get it:

| File | Name | Bag | kg |
|---|---|---|---|
| `hoard_coin.glb` | Hoard-Coin | 2×2 | 9.5 |
| `coin_chest.glb` | Coin-Chest | 3×3 | 26.0 |
| `altar_plate.glb` | Altar-Plate | 3×3 | 14.0 |
| `gilded_torc.glb` | Gilded Torc | 2×2 | 1.8 |
| `gilt_bead.glb` | Gilt Bead | 1×1 | 0.4 |
| `raw_gemstone.glb` | Raw Gemstone | 1×1 | 0.04 |

**Gear** — `props/`:

| File | Name | Bag | kg | Worn |
|---|---|---|---|---|
| `mail_byrnie.glb` | Mail Byrnie | 3×3 | 11.0 | Body |
| `spangen_helm.glb` | Spangen Helm | 2×2 | 2.2 | Head |
| `iron_bracers.glb` | Iron Bracers | 2×1 | 1.6 | Arms |
| `round_shield.glb` | Round Shield | 2×2 | 6.0 | Off-hand |
| `hide_satchel.glb` | Hide Satchel | 2×2 | 1.8 | Pack |
| `pack_frame.glb` | Pack Frame | 2×4 | 4.5 | Pack |
| `horn_lantern.glb` | Horn Lantern | 1×2 | 1.2 | Off-hand |

> **The Horn Lantern costs a weapon slot and it is the game's whole relationship with darkness.** It deserves the most attention of anything in this table.

**Consumables and materials** — `props/`:

| File | Name | Bag | kg |
|---|---|---|---|
| `waystone.glb` | Waystone | 1×2 | 0.9 | Grey, unremarkable, and the only way out |
| `ember.glb` | Ember | 2×3 | 12.0 | Gold. Yours. Heavy |
| `hush_rune.glb` | Hush Rune | 1×1 | 0.2 | |
| `linen_binding.glb` | Linen Binding | 1×1 | 0.1 | |
| `bog_iron.glb` | Bog Iron | 1×1 | 1.4 | |
| `otr_pelt.glb` | Ótr's Pelt | 2×3 | 3.0 | A relic. *Völsunga saga* |

### 5.3 Priority 3 — Set dressing · `props/`

The clutter that makes a worked-out mine read as abandoned rather than empty. **Use a low R channel on these** — they are exactly the noise the outline pass should not draw at distance.

Rubble piles, fallen masonry, broken timber props, rusted iron fittings, ore carts, spoil heaps, bracing beams, chain, rope coils, discarded tools, bones, guttered candles, cairns, ladders.

Six to ten pieces is enough to dress a floor if they are placed with rotation variety. **Do not build fifty.**

### 5.4 Priority 4 — Characters and enemies

**Do not start these without asking.** Every humanoid shares **one skeleton** — `game/art/characters/humanoid_rig.glb`, 28 bones, gear sockets at head, both hands, back, both hips and shoulders. Class differences come from proportion, silhouette and gear, never from bone structure. A character delivered on a different skeleton costs the entire animation library.

---

## 6. Self-check before delivering

Run through this per asset. Every line is something the build will otherwise reject.

1. **Flat-shade it and look.** Does the form read? If not, add hard edges, not detail.
2. **Stand it next to a 1.80 m figure.** Is it honestly that size?
3. **Apply all transforms.** No node carries a scale.
4. **Vertex colours present on every surface**, with the B channel set per §2.3.
5. **Pivot correct** for the category — base centre, or grip for a weapon.
6. **Collision node present and named with a suffix**, simplified, for anything in `environment/` or `props/`.
7. **Footprint on the 2 m grid**, if it is in `environment/`.
8. **Triangle count under the ceiling** for the folder.
9. **No textures, no baked lighting, no ambient occlusion.**
10. Exported as `.glb`, Y-up, −Z forward, into the right folder.

---

## 7. When this brief is wrong

It will be, somewhere. Two rules:

**If a dimension here conflicts with what the game actually does, the game wins** — say so and the brief gets corrected. Every number in §3 was measured from the shipping build, but the build moves.

**If something is needed that is not on the list in §5, the list is wrong and gets updated.** `ART-004` carries the same standing rule: the schedule is the source of truth for what production owes the design, so a gap in it is a bug in the document rather than a reason to improvise.

**Numbers marked ⟨tune⟩ anywhere in this project are placeholders until play proves them.** Nothing in §3 is marked that way — those are measured — but treat the piece list in §5 as a starting set rather than a closed one.
