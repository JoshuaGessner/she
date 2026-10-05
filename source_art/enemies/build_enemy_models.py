"""The shared humanoid rig, its palette, and the hard-surface pieces built on it.

This was the five enemy kinds' builder (ADR-305). They are sculpted now
(ADR-316, `build_enemies.py`); what remains here is what a sculpt cannot be:

- **The rig and the scene** — `begin`, `mesh`, `loft`, `validate`, `review` —
  which every humanoid builder shares, so a delver and a Wretch stay one people.
- **Hard-surface parts** a signed distance field would mesh to mush at an
  enemy's voxel: helm plates, lamellae, chain links, bells, weapons. Each is
  weighted rigidly to its bone, as forged things are.

The delvers' body and worn pieces are sculpted too (ADR-318), and the lofted
anatomy they were built from is gone with them.
"""
from __future__ import annotations

import math
from pathlib import Path
from typing import Callable

import bpy
from mathutils import Vector

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
CHARACTERS = ROOT / "source_art" / "characters"
RIG: bpy.types.Object | None = None
PARTS: list[bpy.types.Object] = []
MATERIALS: dict[str, bpy.types.Material] = {}

# Blue is the material-family selector consumed by the ink shader.  The dull
# colours are only useful in Blender review renders; no texture is exported.
PALETTE = {
    "flesh": ((0.40, 0.38, 0.34, 1.0), 0.80, 0.0),
    "cloth": ((0.10, 0.105, 0.11, 1.0), 0.60, 0.0),
    "rag": ((0.15, 0.145, 0.13, 1.0), 0.60, 0.0),
    "leather": ((0.16, 0.12, 0.08, 1.0), 0.60, 0.0),
    "iron": ((0.16, 0.18, 0.19, 1.0), 0.40, 0.72),
    "mail": ((0.22, 0.24, 0.25, 1.0), 0.40, 0.66),
    "wood": ((0.19, 0.13, 0.08, 1.0), 0.20, 0.0),
    "stone": ((0.24, 0.23, 0.20, 1.0), 0.00, 0.0),
    "dark": ((0.045, 0.043, 0.040, 1.0), 0.80, 0.0),
    "gold_chain": ((0.57, 0.255, 0.028, 1.0), 1.00, 0.9),
}


def begin() -> bpy.types.Object:
    """Open the untouched shared rig and clear every non-rig object."""
    global RIG, PARTS, MATERIALS
    bpy.ops.wm.open_mainfile(filepath=str(CHARACTERS / "humanoid_rig.blend"))
    bpy.context.preferences.filepaths.save_version = 0
    RIG = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    for obj in list(bpy.context.scene.objects):
        if obj != RIG:
            bpy.data.objects.remove(obj, do_unlink=True)
    RIG.data.pose_position = "POSE"
    for bone in RIG.pose.bones:
        bone.matrix_basis.identity()
    assert len(RIG.data.bones) == 28
    assert {"sock_head", "sock_hand_r", "sock_hand_l", "sock_back", "sock_hip_r", "sock_hip_l", "sock_shoulders"} <= set(RIG.data.bones.keys())
    PARTS, MATERIALS = [], {}
    return RIG


def material(kind: str) -> bpy.types.Material:
    if kind not in MATERIALS:
        colour, _ink, metal = PALETTE[kind]
        result = bpy.data.materials.new(f"enemy_{kind}")
        result.diffuse_color = colour
        result.use_nodes = True
        bsdf = result.node_tree.nodes.get("Principled BSDF")
        assert bsdf is not None
        bsdf.inputs["Base Color"].default_value = colour
        bsdf.inputs["Roughness"].default_value = 0.72 if metal else 0.86
        bsdf.inputs["Metallic"].default_value = metal
        MATERIALS[kind] = result
    return MATERIALS[kind]


Weights = dict[str, float] | Callable[[Vector], dict[str, float]]


def mesh(name: str, verts: list[Vector], faces: list[tuple[int, ...]], kind: str,
         weights: Weights, smooth: bool = False) -> bpy.types.Object:
    """Create a weighted mesh with the mandatory UV and FLOAT_COLOR ink data."""
    assert RIG is not None
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(material(kind))
    ink = data.color_attributes.new(name="ink", type="FLOAT_COLOR", domain="CORNER")
    data.color_attributes.active_color = ink
    for corner in ink.data:
        corner.color = (1.0, 0.50, PALETTE[kind][1], 1.0)
    uv = data.uv_layers.new(name="UVMap")
    for polygon in data.polygons:
        polygon.use_smooth = smooth
        for loop_index in polygon.loop_indices:
            co = data.vertices[data.loops[loop_index].vertex_index].co
            uv.data[loop_index].uv = (math.atan2(co.y, co.x) / math.tau + .5, co.z / 1.8)
    for index, vertex in enumerate(data.vertices):
        row = weights(vertex.co) if callable(weights) else weights
        total = sum(row.values())
        assert total > 0.0
        for bone, value in row.items():
            assert bone in RIG.data.bones and not bone.startswith("sock_")
            if value > 0:
                group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
                group.add([index], value / total, "REPLACE")
    obj.parent = RIG
    armature = obj.modifiers.new("shared_skeleton", "ARMATURE")
    armature.object = RIG
    PARTS.append(obj)
    return obj


def ring(center: Vector, radius_x: float, radius_y: float, count: int = 12,
         phase: float = 0.0) -> list[Vector]:
    return [center + Vector((radius_x * math.cos(phase + math.tau * i / count),
                             radius_y * math.sin(phase + math.tau * i / count), 0))
            for i in range(count)]


def loft(name: str, rows: list[list[Vector]], kind: str, weights: Weights,
         smooth: bool = False, cap: bool = True) -> bpy.types.Object:
    assert len(rows) >= 2 and len(rows[0]) >= 3
    count = len(rows[0])
    assert all(len(row) == count for row in rows)
    verts = [point for row in rows for point in row]
    faces: list[tuple[int, ...]] = []
    for row in range(len(rows) - 1):
        for col in range(count):
            next_col = (col + 1) % count
            faces.append((row * count + col, row * count + next_col,
                          (row + 1) * count + next_col, (row + 1) * count + col))
    if cap:
        faces.extend((tuple(range(count - 1, -1, -1)),
                      tuple((len(rows) - 1) * count + i for i in range(count))))
    return mesh(name, verts, faces, kind, weights, smooth)


def torso_weights(point: Vector) -> dict[str, float]:
    stops = ((0.90, "pelvis"), (1.10, "spine_01"), (1.30, "spine_02"), (1.45, "chest"))
    if point.z <= stops[0][0]:
        return {"pelvis": 1.0}
    for (lo, lower), (hi, upper) in zip(stops, stops[1:]):
        if point.z <= hi:
            blend = (point.z - lo) / (hi - lo)
            return {lower: 1.0 - blend, upper: blend}
    return {"chest": 1.0}


def ellipsoid(name: str, center: Vector, radius: tuple[float, float, float], kind: str,
              weights: Weights, smooth: bool = True, slices: int = 12, stacks: int = 6) -> bpy.types.Object:
    rows: list[list[Vector]] = []
    for stack in range(stacks + 1):
        angle = -math.pi / 2 + math.pi * stack / stacks
        rows.append([center + Vector((radius[0] * math.cos(angle) * math.cos(math.tau * i / slices),
                                      radius[1] * math.cos(angle) * math.sin(math.tau * i / slices),
                                      radius[2] * math.sin(angle))) for i in range(slices)])
    return loft(name, rows, kind, weights, smooth)


def box(name: str, center: Vector, dimensions: tuple[float, float, float], kind: str,
        weights: Weights, bevel: float = 0.0) -> bpy.types.Object:
    x, y, z = (value / 2 for value in dimensions)
    verts = [Vector((center.x + dx, center.y + dy, center.z + dz))
             for dx, dy, dz in ((-x, -y, -z), (x, -y, -z), (x, y, -z), (-x, y, -z),
                                (-x, -y, z), (x, -y, z), (x, y, z), (-x, y, z))]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    obj = mesh(name, verts, faces, kind, weights, False)
    if bevel:
        bevel_mod = obj.modifiers.new("worked_edge_chamfers", "BEVEL")
        bevel_mod.width, bevel_mod.segments = bevel, 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=bevel_mod.name)
    return obj


def oriented_prism(name: str, center: Vector, forward: Vector, length: float, width: float, height: float,
                   kind: str, weights: Weights, taper: float = 1.0) -> bpy.types.Object:
    """A six-sided worked-metal/wood prism, forward along Blender -Y."""
    forward = forward.normalized()
    across = Vector((forward.y, -forward.x, 0)).normalized()
    low = center - forward * (length / 2)
    high = center + forward * (length / 2)
    verts = []
    for point, scale in ((low, 1.0), (high, taper)):
        for dx, dz in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            verts.append(point + across * (dx * width * scale / 2) + Vector((0, 0, dz * height * scale / 2)))
    return mesh(name, verts, [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5),
                              (2, 3, 7, 6), (3, 0, 4, 7)], kind, weights, False)


def weapon_seax() -> None:
    # Right-hand grip, blade forward in the permanent rig's Blender -Y space.
    weight = {"hand_r": 1}
    center = Vector((-.45, -.07, 1.08))
    oriented_prism("seax_grip", center, Vector((0, -1, 0)), .14, .032, .032, "wood", weight, .94)
    oriented_prism("seax_blade", center + Vector((0, -.29, .01)), Vector((0, -1, 0)), .46, .058, .024, "iron", weight, .04)
    box("seax_guard", center + Vector((0, -.08, .01)), (.13, .018, .050), "iron", weight, .003)


def sling_and_pouch() -> None:
    """Two cords from the fist to a cup at the knee, the stone in it: a sling
    hangs long, and the length is what reads as a sling and not a club."""
    weight = {"hand_r": 1}
    for index, x in enumerate((-.462, -.438)):
        tube(f"sling_cord_{index}", [Vector((x, -.040, 1.065)), Vector((x - .006 * (1 - 2 * index), -.050, .92)),
                                     Vector((x - .016 * (1 - 2 * index), -.058, .785))],
             [.0065, .0065, .0065], "leather", weight, 5)
    ellipsoid("sling_cup", Vector((-.45, -.060, .765)), (.052, .032, .030), "leather", weight, True, 8, 4)
    ellipsoid("sling_stone", Vector((-.45, -.060, .785)), (.032, .026, .028), "stone", weight, False, 7, 4)
    ellipsoid("stone_pouch", Vector((.17, .11, 1.00)), (.105, .052, .13), "leather", {"pelvis": 1}, True, 10, 5)
    loft("pouch_lip", [ring(Vector((.17, .06, 1.09)), .087, .026, 10), ring(Vector((.17, .055, 1.105)), .078, .021, 10)], "leather", {"pelvis": 1}, False)


def bell_and_striker() -> None:
    left = {"hand_l": 1}
    # A flared bell has a mouth, crown, handle and clapper - suitable for a
    # call animation that needs to read across a room.
    rows = [ring(Vector((.44, -.07, 1.05)), .105, .105, 12), ring(Vector((.44, -.07, 1.11)), .087, .087, 12),
            ring(Vector((.44, -.07, 1.22)), .051, .051, 12), ring(Vector((.44, -.07, 1.27)), .025, .025, 12)]
    rows = [[p-Vector((0,0,.24)) for p in row] for row in rows]
    loft("alarm_bell", rows, "iron", left, False, cap=False)
    ellipsoid("bell_clapper", Vector((.44, -.07, .83)), (.025, .025, .034), "iron", left, False, 7, 4)
    oriented_prism("bell_handle", Vector((.44, -.07, 1.09)), Vector((0, -1, 0)), .09, .026, .050, "leather", left, .92)
    right = {"hand_r": 1}
    oriented_prism("bell_striker_handle", Vector((-.45, -.07, 1.09)), Vector((0, -1, 0)), .20, .027, .027, "wood", right, .90)
    ellipsoid("bell_striker_head", Vector((-.45, -.18, 1.09)), (.040, .040, .048), "iron", right, False, 8, 4)


def alarm_chain() -> None:
    """The chain the Bellringer wears across its body from its collar: links
    alternately flat and edge-on, each rigid on the trunk."""
    # From the collar's left side across the chest to the right hip and round
    # the back again.
    track = [Vector((.11, -.10, 1.55)), Vector((.05, -.165, 1.40)), Vector((-.06, -.175, 1.25)),
             Vector((-.17, -.15, 1.10)), Vector((-.235, -.02, 1.03)), Vector((-.20, .13, 1.10)),
             Vector((-.07, .175, 1.27)), Vector((.06, .16, 1.42)), Vector((.11, .09, 1.55))]
    links = 0
    for a, b in zip(track, track[1:]):
        steps = max(1, round((b - a).length / .085))
        for step in range(steps):
            at = a.lerp(b, (step + .5) / steps)
            along = (b - a).normalized()
            outward = Vector((at.x, at.y, 0)).normalized()
            spin = along.cross(outward).normalized() if links % 2 else outward
            other = along.cross(spin).normalized()
            verts, faces = [], []
            for i in range(6):
                t = i * math.tau / 6
                for j in range(3):
                    s = j * math.tau / 3
                    radial = .036 * math.cos(t) * along + .020 * math.sin(t) * other
                    tube_dir = (math.cos(t) * along + math.sin(t) * other).normalized()
                    verts.append(at + radial + .007 * (math.cos(s) * tube_dir + math.sin(s) * spin))
            for i in range(6):
                for j in range(3):
                    faces.append((i * 3 + j, ((i + 1) % 6) * 3 + j, ((i + 1) % 6) * 3 + (j + 1) % 3, i * 3 + (j + 1) % 3))
            mesh(f"alarm_chain_{links}", verts, faces, "iron", torso_weights, False)
            links += 1


def belt_bells() -> None:
    """Two small bells at the Bellringer's belt."""
    for index, x in enumerate((.10, -.02)):
        rows = [ring(Vector((x, -.168, z)), r, r * .9, 8) for z, r in ((.93, .036), (.965, .028), (.995, .012))]
        loft(f"belt_bell_{index}", rows, "iron", {"pelvis": 1}, False, cap=False)


def drag_chain() -> None:
    """The Gold-Sick's chains: oversized links hanging down its right side, and
    a slipped chain from the crown across the chest to a hand."""
    for index in range(9):
        f = index / 8.0
        at = Vector((-.33 + .10 * math.sin(f * math.pi * 1.4), -.20 - .018 * (index % 2), 1.40 - f * .70))
        wide, tall = (.036, .066) if index % 2 else (.062, .034)
        points = [at + Vector((wide * math.cos(a), .012 * math.sin(a), tall * math.sin(a)))
                  for a in (step * math.tau / 12 for step in range(12))]
        rows = []
        for i, c in enumerate(points):
            tangent = (points[(i + 1) % 12] - points[i - 1]).normalized()
            u = Vector((0, 1, 0)).cross(tangent).normalized()
            v = tangent.cross(u).normalized()
            rows.append([c + .010 * (math.cos(k * math.tau / 6) * u + math.sin(k * math.tau / 6) * v) for k in range(6)])
        verts = [q for row in rows for q in row]
        faces = [(i * 6 + k, i * 6 + (k + 1) % 6, ((i + 1) % 12) * 6 + (k + 1) % 6, ((i + 1) % 12) * 6 + k)
                 for i in range(12) for k in range(6)]
        mesh(f"heavy_chain_link_{index}", verts, faces, "gold_chain", torso_weights, False)


def war_hammer() -> None:
    weight = {"hand_r": 1}
    # Broad rectangular face and rear beak make the blocker class unmistakable.
    oriented_prism("hammer_haft", Vector((-.45, -.16, 1.09)), Vector((0, -1, 0)), .62, .030, .030, "wood", weight, .92)
    box("hammer_head", Vector((-.45, -.42, 1.10)), (.25, .11, .13), "iron", weight, .018)
    oriented_prism("hammer_beak", Vector((-.45, -.51, 1.10)), Vector((0, -1, 0)), .17, .08, .065, "iron", weight, .18)
    loft("hammer_iron_band", [ring(Vector((-.45, -.25, 1.09)), .044, .044, 8), ring(Vector((-.45, -.235, 1.09)), .044, .044, 8)], "iron", weight, False)


def spear() -> None:
    weight = {"hand_r": 1}
    # Shaft extends in front of the guardian and makes its narrow silhouette.
    oriented_prism("spear_shaft", Vector((-.45, -.57, 1.09)), Vector((0, -1, 0)), 1.35, .028, .028, "wood", weight, .98)
    # Two crossed flat blades create a true diamond spearhead with hard edges.
    tip = Vector((-.45, -1.29, 1.09))
    base = Vector((-.45, -1.02, 1.09))
    verts = [base + Vector((-.075, 0, 0)), base + Vector((0, 0, .065)), base + Vector((.075, 0, 0)),
             base + Vector((0, 0, -.065)), tip]
    mesh("spearhead", verts, [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (0, 3, 2, 1)], "iron", weight, False)
    loft("spear_ferrule", [ring(Vector((-.45, -1.00, 1.09)), .043, .043, 8), ring(Vector((-.45, -1.08, 1.09)), .038, .038, 8)], "iron", weight, False)


def tube(name: str, points: list[Vector], radii: list[float], kind: str, weights: Weights,
         sides: int = 8) -> bpy.types.Object:
    """A tapering round section swept along a polyline."""
    rows = []
    for index, at in enumerate(points):
        tangent = (points[min(index + 1, len(points) - 1)] - points[max(index - 1, 0)]).normalized()
        u = Vector((1, 0, 0)) if abs(tangent.x) < .9 else Vector((0, 1, 0))
        v = tangent.cross(u).normalized()
        u = v.cross(tangent).normalized()
        rows.append([at + radii[index] * (math.cos(i * math.tau / sides) * u + math.sin(i * math.tau / sides) * v)
                     for i in range(sides)])
    return loft(name, rows, kind, weights, True)


def spangenhelm() -> None:
    """A cone in four ribbed plates on a brow band, with a nasal and the
    Gjermundbu helm's spectacle guard."""
    head = {"head": 1}
    helm_rows = []
    for z, r in ((1.70, .150), (1.76, .148), (1.82, .132), (1.88, .103), (1.93, .064), (1.965, .022)):
        helm_rows.append(ring(Vector((0, .008, z)), r * 1.02, r, 16))
    loft("warden_spangenhelm", helm_rows, "iron", head, False)
    loft("warden_brow_band", [ring(Vector((0, .008, 1.695)), .158, .156, 16),
                              ring(Vector((0, .008, 1.735)), .158, .156, 16)], "iron", head, False)
    for quarter in range(4):
        a = quarter * math.tau / 4 + math.tau / 8
        base = Vector((.150 * math.cos(a), .008 + .148 * math.sin(a), 1.72))
        tip = Vector((0, .008, 1.95))
        oriented_prism(f"warden_helm_rib_{quarter}", base.lerp(tip, .5), (tip - base), (tip - base).length,
                       .022, .014, "iron", head, .4)
    oriented_prism("warden_nasal", Vector((0, -.166, 1.665)), Vector((0, 0, -1)), .13, .036, .016, "iron", head, .7)
    # Spectacle guard over the eyes, the Gjermundbu helm's mark.
    for side in (-1, 1):
        loft(f"warden_spectacle_{side}", [ring(Vector((side * .050, -.150, 1.705)), .036, .010, 10),
                                          ring(Vector((side * .050, -.168, 1.705)), .036, .010, 10)], "iron", head, False)


def lamellar_shoulders() -> None:
    """Three overlapping curved plates each side, stepping down the arm."""
    # Each lame is a strip arched over the shoulder cap from the front of the
    # chest to the back, its upper edge tucked under the one above and its
    # lower edge flaring out over the arm.
    for side in (-1, 1):
        for lame in range(3):
            upper, lower = [], []
            for i in range(9):
                y = -.14 + .28 * i / 8
                arch = 1.0 - (y / .14) ** 2
                x = side * (.25 + lame * .045)
                z = 1.50 - lame * .065 + .035 * arch
                upper.append(Vector((x, y * 1.05, z)))
                lower.append(Vector((x + side * .05, y * 1.12, z - .085)))
            faces = [(i, i + 1, 10 + i, 9 + i) if side > 0 else (i, 9 + i, 10 + i, i + 1) for i in range(8)]
            weights = {"chest": .5, f"upper_arm_{'l' if side > 0 else 'r'}": .5} if lame > 0 else {"chest": 1}
            mesh(f"warden_lame_{side}_{lame}", upper + lower, faces, "iron", weights, False)


def triangle_count() -> int:
    return sum(sum(len(poly.vertices) - 2 for poly in obj.data.polygons) for obj in PARTS)


def validate(ceiling: int = 6000) -> None:
    assert RIG is not None
    assert len(RIG.data.bones) == 28
    assert triangle_count() <= ceiling, triangle_count()
    for obj in PARTS:
        assert obj.matrix_basis.is_identity
        assert obj.data.color_attributes.get("ink") is not None
        assert obj.data.color_attributes["ink"].data_type == "FLOAT_COLOR"
        for vertex in obj.data.vertices:
            assert abs(sum(group.weight for group in vertex.groups) - 1.0) < 1e-5


def review(kind: str, folder: Path = SRC) -> None:
    """Render a front three-quarter and a rear three-quarter review sheet."""
    assert RIG is not None
    scene = bpy.context.scene
    # EEVEE's engine identifier has changed across Blender releases.  Cycles
    # with CPU rendering is stable in the batch build used for source review.
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 32
    scene.render.resolution_x, scene.render.resolution_y = 1000, 1100
    scene.render.resolution_percentage = 100
    scene.world.color = (.055, .055, .055)
    scene.view_settings.look = "AgX - Medium High Contrast"
    # Lit so a material reads at its value: brighter washed linen and mail
    # alike to white, and a review could not tell them apart.
    for location, energy, size in (((-3.2, -4.0, 4.8), 240, 4.0), ((3.5, -1.0, 3.0), 110, 3.0), ((1.0, 3.0, 4.0), 200, 3.0)):
        bpy.ops.object.light_add(type="AREA", location=location)
        lamp = bpy.context.object
        lamp.data.energy, lamp.data.shape, lamp.data.size = energy, "DISK", size
        lamp.rotation_euler = (Vector((0, 0, 1.03)) - lamp.location).to_track_quat("-Z", "Y").to_euler()
    for suffix, location in (("review", (2.55, -4.1, 2.20)), ("rear_review", (-2.55, 4.1, 2.20))):
        bpy.ops.object.camera_add(location=location)
        camera = bpy.context.object
        camera.data.type, camera.data.ortho_scale = "ORTHO", 2.22
        camera.rotation_euler = (Vector((0, 0, 1.02)) - camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.camera = camera
        scene.render.filepath = str(folder / f"{kind}_{suffix}.png")
        bpy.ops.render.render(write_still=True)
        bpy.data.objects.remove(camera, do_unlink=True)
