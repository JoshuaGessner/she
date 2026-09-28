---
id: ART-007
title: Asset Quality Review — First Delivered Library
status: accepted
owner: art
tags: [art, assets, modelling, review]
updated: 2026-09-28
related: [ART-006, ART-004, ART-005, DES-020, PRO-002]
---

# Asset quality review

The developer requested a less blocky treatment of the 46 assets delivered under
`ART-006`. This is a visual review of that pass, not a change to the modelling
contract or acceptance of the entire `M4-T10` art milestone.

## What changed

| Collection | Count | Form improvements | Blender review |
|---|---:|---|---|
| Band 1 Delvings | 14 | Varied ashlar courses, broader cut chamfers, recessed jambs, tapered octagonal columns, ramp paving and beam fixings | [Assembled room](../../source_art/environment/delvings_room_review.png) |
| Weapons | 6 | Thin cutting edges, tapered blade sections, a recessed sword fuller, shaped hafts, forged hammer and a continuous bow stave | [Weapon closeups](../../source_art/weapons/weapons_review_sheet.png) |
| Items | 19 | Hollow helmet and cuffs, shaped garment openings, domed shield, panelled lantern, curved leather forms, constructed chest and worked treasure | [Item closeups](../../source_art/items/item_review_sheet.png) |
| Dressing | 7 | Dished cart wheels, snapped timber, fractured stone, continuous rope, forged fittings and melted candle rims | [Dressing closeups](../../source_art/dressing/dressing_review.png) |

These are geometry renders, not captures of the game's final ink treatment.
The closeup sheets enlarge small objects independently; labels and measurements,
not their relative size on the sheet, establish scale. The room render includes
the unchanged 1.80 m shared humanoid rig.

[The worn-gear capture](../../source_art/items/worn_quality.png) uses the actual
game and ink pass. That visual check caught the rebuilt helmet sitting above
the scalp despite passing the bounding-box test. Its item-data worn offset was
lowered by 0.13 m; the base-centre export pivot is unchanged.
The shorter rebuilt lantern also uses the matching off-hand grip offset
(-0.62 m on Y) so its carrying bail remains at the fist.

## Preserved contracts

Environment footprints, doorway clearance, ramp rise/run and simple collision
remain within `ART-006`. Weapon lengths are 0.50 m seax, 0.80 m axe, 2.00 m spear,
1.65 m bow, 0.85 m hammer and 1.25 m sword. Hard edges remain on worked forms;
the draped pelt uses smooth normals across its broad soft folds.

The source scripts regenerate `.blend` files and `.glb` exports in their existing
locations. No new character or enemy was authored. All assets retain their ink
vertex metadata, flat palette and category triangle ceilings. Surface grain and
pitting remain the material system's responsibility, rather than added geometry.

## Reproduction and review

Run each `source_art/{environment,weapons,items,dressing}/build_*.py` with Blender
in background mode and `--python-exit-code 1`. Then run
`source_art/environment/render_delvings_room.py` for the assembled room view.
The item builder also produces individual labelled closeups next to its sources.

Import the exports with Godot before running `game/tests/art_probe.gd`.
`kit_probe.gd` checks kit integration; `dressing_probe` checks placement;
`--body-probe` checks that wearable gear still fits the shared body. A successful
numeric check is not visual acceptance: the review images remain the basis for
the next art-direction conversation.
