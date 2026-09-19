# Weapon delivery measurements

Generated from `build_weapons.py` in Blender 5.2.0 LTS. Re-run with:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python source_art/weapons/build_weapons.py
```

Every production mesh is flat-shaded, transform-free, and authored with its
grip at Blender `(0, 0, 0)`. Blender +Y becomes glTF/Godot −Z during export;
the result is Y-up and points forward along −Z. The small rear pommels and
butt caps intentionally extend behind the grip.

| Asset | Triangles | Imported bounds (m, X × Y × Z) |
|---|---:|---:|
| `seax.glb` | 96 | 0.104 × 0.230 × 1.100 |
| `bearded_axe.glb` | 116 | 0.122 × 0.530 × 1.410 |
| `ash_spear.glb` | 116 | 0.084 × 0.210 × 3.750 |
| `yew_bow.glb` | 260 | 0.068 × 2.691 × 0.475 |
| `dvergar_hammer.glb` | 140 | 0.420 × 0.400 × 1.690 |
| `regin_blade.glb` | 136 | 0.136 × 0.340 × 2.150 |

The 800-triangle ceiling is met by every asset. All surfaces export `COLOR_0`:
`R = 1.0`, `G = 0.5`, and `B = 0.2` timber, `0.4` metal, or `0.6` leather,
encoded as normalized unsigned-short glTF vertex attributes. The six GLBs
contain no UVs or textures.

`weapons_review_sheet.png` is the flat-shaded presentation check. It labels
each weapon and includes a 1.80 m human reference so the real scale remains
visible in review.
