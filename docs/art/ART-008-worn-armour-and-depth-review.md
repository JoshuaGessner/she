---
id: ART-008
title: Worn Armour, Class Arms and Depth Variants — Review
status: proposed
owner: art
tags: [art, assets, modelling, review]
updated: 2026-09-28
related: [ART-004, ART-006, ART-007, DES-020, TEC-008]
---

# Worn armour, class arms and depth variants

The developer asked to continue the remaining modelling plan after the first
46-asset quality pass. This review covers the next deliverables. It does not
accept the entire `M4-T10` milestone or claim that full character and enemy
models are complete.

## Shared-rig equipment

`mail_byrnie_worn.glb` is a fitted, split-skirt mail shirt with half sleeves,
trousers and boots. Body remains one slot, including the legs, and its sleeves
stop above the elbow. `iron_bracers_worn.glb` supplies two open forged cuffs,
leather bindings and a raised central ridge. Both use the exact 28-bone rest
pose from `humanoid_rig.blend`; neither adds sockets or changes the player
collider. The loose pickup props retain their base-centred pivots.

- [Mail fit](../../source_art/characters/mail_byrnie_worn_review.png)
- [Mail under a bent pose](../../source_art/characters/mail_byrnie_worn_posed_review.png)
- [Bracer fit](../../source_art/characters/iron_bracers_worn_review.png)
- [Bracers under a bent pose](../../source_art/characters/iron_bracers_worn_posed_review.png)

The pale head and uncovered limbs in the equipment reviews are the existing
measurement body, not newly delivered character art. Covered body geometry is
hidden when wearing the mail and restored when it is removed, so a rigid base
leg cannot poke through a deforming trouser knee.

`otr_pelt_worn.glb` supplies the other Body-slot item: Ótr’s Pelt. Its fur
mantle sits over a complete tunic, trousers and boots so replacing mail does
not leave holes in the covered body. The equipment regression swaps mail for
the pelt, checks that the old garment is removed, then checks the original body
is restored on unequip. Every Body/Arms item now requires a worn-model reference
in its data validation.

- [Pelt fit](../../source_art/characters/otr_pelt_worn_review.png)
- [Pelt under a bent pose](../../source_art/characters/otr_pelt_worn_posed_review.png)

## First-person arm library

Six arm pairs use that same skeleton and bind pose. Each contains tapered
forearms, shaped palms and individually modelled fingers in a carrying curl.
The rig has hand bones rather than finger bones; the fingers do not articulate
individually. This is a modelling limitation, not a claim of authored finger
animation.

| Class | Authored distinction | Review |
|---|---|---|
| Húskarl | Healed forearm cuts | [Arms](../../source_art/characters/huskarl_arms_review.png) |
| Veiðimaðr | Draw-finger tabs and wrist tape | [Arms](../../source_art/characters/veidimadr_arms_review.png) |
| Völva | Ink marks and bone charms | [Arms](../../source_art/characters/volva_arms_review.png) |
| Skald | Stained fingers and a wrist tie | [Arms](../../source_art/characters/skald_arms_review.png) |
| Úlfheðinn | Fur wrist wraps | [Arms](../../source_art/characters/ulfhedinn_arms_review.png) |
| Haugbrjótr | Leather cuff and small wrist tools | [Arms](../../source_art/characters/haugbrjotr_arms_review.png) |

Only Húskarl and Veiðimaðr currently have class resources in the game. The other
four arm assets do not create classes or expose unfinished class choices.
Full class bodies, enemy models and authored locomotion remain separate work.

## The deeper Delvings

The Retreat and Cause each add three wall heights and one floor variant. They
keep the kit's footprints and use the generator's existing band geometry;
the visual variants do not replace its collision or navigation surfaces.

[Depth comparison](../../source_art/environment/delvings_depth_review.png)

## Reproduction

Run these with Blender in background mode and `--python-exit-code 1`:

- `source_art/characters/build_worn_armour.py`
- `source_art/characters/build_class_arms.py`
- `source_art/characters/build_worn_pelt.py`
- `source_art/environment/build_delvings_depth.py`

The measurement JSON files next to the scripts record triangle counts and
bone usage. Review both the source renders and the actual in-game views:
passing a dimension or skin-binding check does not establish visual quality.

An independent GLB inspection checks all nine character-related exports
against the original rig: identical bone names, parent hierarchy and rest
transforms; normalized skin weights; UVs; normals; and the required ink colour
attribute on every primitive. Godot's `art_probe.gd` also passes the complete
library with these exports present.

Runtime checks cover the equipment lifecycle: the byrnie masks the shared body
from 2,224 to 816 triangles, and removing it restores all 2,224. Both worn
slots resolve to the existing skeleton without a duplicate armature. Rig tests
check rest-pose drift and deformation at the chest, shoulder, thigh and both
forearms. First-person hands follow the presented weapon and off-hand grips
independently; the camera remains independent of the skeleton. The moving-grip
probe measures draw-in and swing poses after frame processing: 0.0000 m and
0.04° maximum error. Disabling the frame refresh deliberately produces a
0.0457 m / 5.78° miss and fails that check. Returning to an unsworn body also
removes the class arms cleanly.

The depth probe confirms all eight variants are used, repeatable generation at
depths one and two, unchanged collision slabs, and floor relief above the
existing floor render surface. The relief is deliberately shallow: actual
steps and slopes remain the generator's responsibility.
