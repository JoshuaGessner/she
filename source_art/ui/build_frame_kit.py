"""The forged frame kit (ADR-386): the iron that every panel in the interface
is framed with, modelled and lit once and rendered to small textures that
`CarvedFrame` lays along a panel's edges.

Why rendered pieces and not more drawn lines: the drawn plate (ADR-341) gave
the frame a bevel made of two flat colours, and at a glance it is still a
line around a box. What makes Diablo IV's and Grim Dawn's frames read as
*made* is material: a forged band that catches light on its upper edge and
falls into shadow on its lower one, studs that are round, a corner piece with
real relief. Light is what says metal, and light needs a surface to fall on.
So the surface is modelled here, lit from the upper left as every interface
in the genre is lit, and rendered once.

The shapes are ours: a strap-hinge band with a raised spine and a gilt bead
toward the panel; corner brackets ending in lozenge terminals, after the
strap-hinges on the Mästermyr chest and the Urnes door; a gilt boss ringed by
an interlaced pair, the knot every Norse mount ends in.

Run (from the repo root):
    Blender --background --python source_art/ui/build_frame_kit.py
Writes game/art/ui/frame/*.png. 1 Blender unit is 1 interface pixel; each
piece is rendered at `PX` pixels per unit and drawn at 1.
"""
from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Euler, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game" / "art" / "ui" / "frame"
PX = 2

# Band and corner sizes, in interface pixels. `CarvedFrame` reads the same
# numbers from `frame_kit.json`, written beside the textures, so the drawing
# and the art cannot disagree.
SIZES = {
    # `corner` is how far a bracket runs in along each edge; `outset` how far
    # it stands out past the frame's outer edge — the boss sits on the corner,
    # over it, as the reference's ornaments do, not tucked inside it.
    "large": {"band": 14.0, "corner": 52.0, "outset": 9.0, "tile": 64.0, "crest": (96.0, 34.0)},
    "small": {"band": 7.0, "corner": 20.0, "outset": 4.0, "tile": 32.0, "crest": (0.0, 0.0)},
}


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.render.resolution_percentage = 100
    world = bpy.data.worlds.new("World")
    world.color = (0.035, 0.032, 0.03)
    scene.world = world


def iron() -> bpy.types.Material:
    """Dark forged iron: lit enough on its bevels to read as metal, hammered
    so a long band is never one flat colour."""
    mat = bpy.data.materials.get("iron")
    if mat is not None:
        return mat
    mat = bpy.data.materials.new("iron")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.075, 0.068, 0.062, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.75
    bsdf.inputs["Roughness"].default_value = 0.38
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 0.35
    noise.inputs["Detail"].default_value = 4.0
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.25
    mat.node_tree.links.new(noise.outputs["Fac"], bump.inputs["Height"])
    mat.node_tree.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def gilt() -> bpy.types.Material:
    mat = bpy.data.materials.get("gilt")
    if mat is not None:
        return mat
    mat = bpy.data.materials.new("gilt")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.72, 0.50, 0.22, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.85
    bsdf.inputs["Roughness"].default_value = 0.34
    return mat


def box(lo: tuple, hi: tuple, mat, bevel: float = 0.6, angle: float = 0.0,
        ) -> bpy.types.Object:
    """An axis-aligned block from `lo` to `hi`, bevelled, optionally turned
    about Z by `angle` around its centre (a lozenge is a square turned 45°)."""
    lo, hi = Vector(lo), Vector(hi)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(lo + hi) / 2.0)
    obj = bpy.context.object
    obj.scale = hi - lo
    # Scale alone: its defaults apply location too, and a lozenge then turns
    # about the world origin rather than its own centre.
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.rotation_euler.z = angle
    if bevel > 0.0:
        mod = obj.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        mod.limit_method = "ANGLE"
    obj.data.materials.append(mat)
    return obj


def stud(at: tuple, radius: float, mat, flat: float = 0.55) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=at, segments=24, ring_count=12)
    obj = bpy.context.object
    obj.scale.z = flat
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(mat)
    return obj


def ring(at: tuple, major: float, minor: float, mat, tilt: float = 0.0) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(location=at, major_radius=major, minor_radius=minor,
                                     major_segments=48, minor_segments=12)
    obj = bpy.context.object
    obj.rotation_euler.x = tilt
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(mat)
    return obj


def bead(y: float, z: float, length: float, radius: float, mat) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=length, location=(0.0, y, z),
                                        rotation=(0.0, math.pi / 2.0, 0.0), vertices=16)
    obj = bpy.context.object
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(mat)
    return obj


def lights() -> None:
    """Key from the upper left, as every interface in the genre is lit, and a
    low fill from the lower right so the shadowed faces keep their shape."""
    for direction, energy, size in (((-1.0, 1.2, 1.6), 3.2, 0.0), ((1.0, -1.0, 0.6), 0.6, 0.0)):
        bpy.ops.object.light_add(type="SUN")
        sun = bpy.context.object
        sun.data.energy = energy
        sun.rotation_euler = Vector(direction).to_track_quat("Z", "Y").to_euler()


def camera(centre: tuple, width: float, height: float) -> None:
    scene = bpy.context.scene
    bpy.ops.object.camera_add(location=(centre[0], centre[1], 60.0))
    cam = bpy.context.object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = max(width, height)
    cam.data.clip_end = 200.0
    scene.camera = cam
    scene.render.resolution_x = int(round(width * PX))
    scene.render.resolution_y = int(round(height * PX))


def turn(objects: list, angle: float, about: tuple) -> None:
    """Turn the whole piece about Z through `about`; the light stays put, so
    every orientation of a piece is lit from the same upper left."""
    pivot = Vector((about[0], about[1], 0.0))
    for obj in objects:
        offset = obj.location - pivot
        offset.rotate(Euler((0.0, 0.0, angle)))
        obj.location = pivot + offset
        obj.rotation_euler.z += angle


def render(name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.context.scene.render.filepath = str(OUT / f"{name}.png")
    bpy.ops.render.render(write_still=True)
    print(f"[frame_kit] {name}.png {bpy.context.scene.render.resolution_x}x"
          f"{bpy.context.scene.render.resolution_y}")


# ── the pieces ──

def edge_piece(size: str) -> list:
    """A straight run of band, the top edge's way round: the panel lies below
    (−y). Longer than the tile so its ends never show; uniform along x except
    for studs a tile's half apart, so it repeats seamlessly."""
    s = SIZES[size]
    half, run = s["band"] / 2.0, s["tile"] * 1.5
    k = s["band"] / 14.0
    parts = [
        box((-run, -half, 0.0), (run, half, 2.4 * k), iron(), bevel=0.7 * k),
        box((-run, -1.2 * k, 2.4 * k), (run, half - 1.6 * k, 4.4 * k), iron(), bevel=0.9 * k),
    ]
    # The gilt bead is the large frame's inlay. On a button it made two gilt
    # rails of every plaque and a menu a ladder; a button gilds when lit.
    if size == "large":
        parts.append(bead(-half + 2.0 * k, 2.4 * k, run * 2.0, 0.9 * k, gilt()))
        for x in (-s["tile"] / 4.0, s["tile"] / 4.0):
            parts.append(stud((x, 1.6 * k, 4.4 * k), 1.6 * k, iron(), flat=0.7))
    return parts


def corner_piece(size: str) -> list:
    """The upper-left corner bracket, its boss **on** the corner: a lozenge
    plate centred where the two bands cross, standing out past the frame by
    `outset`; two arms running in along the bands to lozenge points; and a
    spur in along the diagonal. Occupies (−outset..c, −c..outset); the panel
    lies to +x, −y, and the frame's outer corner is the origin."""
    s = SIZES[size]
    c, b, m = s["corner"], s["band"], s["outset"]
    k = b / 14.0
    arm = b * 0.78
    centre = (b / 2.0, -b / 2.0)
    parts = [
        box((b * 0.11, -b / 2.0 - arm / 2.0, 0.0), (c * 0.86, -b / 2.0 + arm / 2.0, 3.4 * k), iron(), bevel=0.8 * k),
        box((b / 2.0 - arm / 2.0, -c * 0.86, 0.0), (b / 2.0 + arm / 2.0, -b * 0.11, 3.4 * k), iron(), bevel=0.8 * k),
    ]
    tip = arm * 0.95
    for at in ((c * 0.86, -b / 2.0), (b / 2.0, -c * 0.86)):
        parts.append(box((at[0] - tip / 2.0, at[1] - tip / 2.0, 0.0), (at[0] + tip / 2.0, at[1] + tip / 2.0, 3.2 * k),
                         iron(), bevel=0.7 * k, angle=math.pi / 4.0))
    spur = c * 0.5
    mid = (b / 2.0 + spur * 0.45, -b / 2.0 - spur * 0.45)
    parts.append(box((mid[0] - spur / 2.0, mid[1] - arm * 0.2, 0.0), (mid[0] + spur / 2.0, mid[1] + arm * 0.2, 3.0 * k),
                     iron(), bevel=0.6 * k, angle=-math.pi / 4.0))
    plate = (b + m) * 1.35
    parts.append(box((centre[0] - plate / 2.0, centre[1] - plate / 2.0, 0.0),
                     (centre[0] + plate / 2.0, centre[1] + plate / 2.0, 6.0 * k),
                     iron(), bevel=1.5 * k, angle=math.pi / 4.0))
    parts.append(stud((centre[0], centre[1], 6.0 * k), plate * 0.24, gilt(), flat=0.6))
    if size == "large":
        parts.append(ring((centre[0], centre[1], 6.3 * k), plate * 0.36, 0.9 * k, gilt(), tilt=0.12))
        parts.append(ring((centre[0], centre[1], 6.3 * k), plate * 0.36, 0.9 * k, gilt(), tilt=-0.12))
        for at in ((c * 0.62, -b / 2.0), (b / 2.0, -c * 0.62)):
            parts.append(stud((at[0], at[1], 3.4 * k), 1.6 * k, gilt(), flat=0.6))
    return parts


def crest_piece() -> list:
    """The header crest, centred on the top edge: a bar with lozenge ends, and
    a raised lozenge at its middle carrying a boss in an interlaced pair."""
    w, h = SIZES["large"]["crest"]
    parts = [
        box((-w * 0.40, -h * 0.17, 0.0), (w * 0.40, h * 0.17, 3.8), iron(), bevel=0.9),
        box((-h * 0.34, -h * 0.34, 0.0), (h * 0.34, h * 0.34, 6.0), iron(), bevel=1.5, angle=math.pi / 4.0),
        stud((0.0, 0.0, 6.0), h * 0.17, gilt(), flat=0.6),
        ring((0.0, 0.0, 6.3), h * 0.25, 0.9, gilt(), tilt=0.12),
        ring((0.0, 0.0, 6.3), h * 0.25, 0.9, gilt(), tilt=-0.12),
    ]
    for x in (-w * 0.40, w * 0.40):
        parts.append(box((x - h * 0.16, -h * 0.16, 0.0), (x + h * 0.16, h * 0.16, 4.0), iron(),
                         bevel=0.8, angle=math.pi / 4.0))
        parts.append(stud((x, 0.0, 4.0), 1.7, gilt(), flat=0.6))
    for x in (-w * 0.22, w * 0.22):
        parts.append(stud((x, 0.0, 3.8), 1.4, gilt(), flat=0.6))
    return parts


SIDES = {"top": 0.0, "right": -math.pi / 2.0, "bottom": math.pi, "left": math.pi / 2.0}
CORNERS = {"tl": 0.0, "tr": -math.pi / 2.0, "br": math.pi, "bl": math.pi / 2.0}


def build() -> None:
    for size, s in SIZES.items():
        for side, angle in SIDES.items():
            reset()
            lights()
            parts = edge_piece(size)
            turn(parts, angle, (0.0, 0.0))
            wide, tall = (s["tile"], s["band"]) if side in ("top", "bottom") else (s["band"], s["tile"])
            camera((0.0, 0.0), wide, tall)
            render(f"{size}_edge_{side}")
        for corner, angle in CORNERS.items():
            reset()
            lights()
            parts = corner_piece(size)
            c, m = s["corner"], s["outset"]
            middle = ((c - m) / 2.0, -(c - m) / 2.0)
            turn(parts, angle, middle)
            camera(middle, c + m, c + m)
            render(f"{size}_corner_{corner}")
    reset()
    lights()
    crest_piece()
    w, h = SIZES["large"]["crest"]
    camera((0.0, 0.0), w, h)
    render("large_crest")
    import json
    (OUT / "frame_kit.json").write_text(json.dumps({"px": PX, "sizes": SIZES}, indent=2))
    review()
    print("[frame_kit] done")


def review(w: float = 260.0, h: float = 150.0) -> None:
    """A whole panel assembled from the pieces, larger than life, to look at:
    a piece can read well alone and wrong beside its neighbours."""
    reset()
    lights()
    s = SIZES["large"]
    c, b = s["corner"], s["band"]
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(w / 2.0, -h / 2.0, -0.5))
    ground = bpy.context.object
    ground.scale = (w, h, 1.0)
    dark = bpy.data.materials.new("ground")
    dark.use_nodes = True
    dark.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.03, 0.028, 0.026, 1.0)
    ground.data.materials.append(dark)
    for side, angle in SIDES.items():
        parts = edge_piece("large")
        for obj in parts:
            obj.scale.x *= (w if side in ("top", "bottom") else h) / (s["tile"] * 3.0)
        turn(parts, angle, (0.0, 0.0))
        at = {"top": (w / 2.0, -b / 2.0), "bottom": (w / 2.0, -h + b / 2.0),
              "left": (b / 2.0, -h / 2.0), "right": (w - b / 2.0, -h / 2.0)}[side]
        for obj in parts:
            obj.location.x += at[0]
            obj.location.y += at[1]
            obj.location.z += 0.01
    for corner, angle in CORNERS.items():
        parts = corner_piece("large")
        turn(parts, angle, ((c - s["outset"]) / 2.0, -(c - s["outset"]) / 2.0))
        at = {"tl": (0.0, 0.0), "tr": (w - c + s["outset"], 0.0), "br": (w - c + s["outset"], -h + c - s["outset"]),
              "bl": (0.0, -h + c - s["outset"])}[corner]
        for obj in parts:
            obj.location.x += at[0]
            obj.location.y += at[1]
            obj.location.z += 0.5
    crest = crest_piece()
    for obj in crest:
        obj.location.x += w / 2.0
        obj.location.y += -b / 2.0
        obj.location.z += 0.5
    camera((w / 2.0, -h / 2.0), w + 10.0, h + 10.0)
    scene = bpy.context.scene
    scene.render.resolution_x = int((w + 10.0) * 4)
    scene.render.resolution_y = int((h + 10.0) * 4)
    scene.render.filepath = str(ROOT / "source_art" / "ui" / "frame_kit_review.png")
    bpy.ops.render.render(write_still=True)
    print("[frame_kit] review")


build()
