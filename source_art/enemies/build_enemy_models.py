"""Build the five Delvings enemy bodies on the permanent shared humanoid rig.

Run with Blender 4.7:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \
      --python source_art/enemies/build_enemy_models.py

The rig is deliberately never rebuilt here.  These are bind-pose models only:
animation is authored against the same 28-bone hierarchy in a later pass.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path
from typing import Callable

import bpy
from mathutils import Vector

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
CHARACTERS = ROOT / "source_art" / "characters"
OUT = ROOT / "game" / "art" / "enemies"
sys.path.insert(0, str(CHARACTERS))
# Keep the garment builder as the one source of truth for the shared-rig
# contract.  Its module has no import-time scene changes.
import build_worn_armour as shared_armour  # noqa: E402

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
    # The reusable helper is safe to import but uses module globals when called.
    shared_armour.RIG = RIG
    shared_armour.PARTS = []
    shared_armour.MATERIALS = {}
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


def along_bone(side: str, name: str, start_t: float, end_t: float) -> tuple[Vector, Vector, Vector, Vector]:
    assert RIG is not None
    bone = RIG.data.bones[f"{name}_{side}"]
    start = bone.head_local.lerp(bone.tail_local, start_t)
    end = bone.head_local.lerp(bone.tail_local, end_t)
    axis = (end - start).normalized()
    front = Vector((0, -1, 0))
    across = axis.cross(front).normalized()
    return start, end, front, across


def limb_loft(name: str, side: str, bone: str, radii: list[tuple[float, float]], kind: str,
              smooth: bool = True, length: tuple[float, float] = (0.0, 1.0),
              n: int = 10) -> bpy.types.Object:
    start, end, front, across = along_bone(side, bone, length[0], length[1])
    rows: list[list[Vector]] = []
    for t, radius in radii:
        center = start.lerp(end, t)
        rows.append([center + radius * (math.cos(math.tau * i / n) * front + math.sin(math.tau * i / n) * across)
                     for i in range(n)])
    return loft(name, rows, kind, {f"{bone}_{side}": 1.0}, smooth)


def torso_weights(point: Vector) -> dict[str, float]:
    stops = ((0.90, "pelvis"), (1.10, "spine_01"), (1.30, "spine_02"), (1.45, "chest"))
    if point.z <= stops[0][0]:
        return {"pelvis": 1.0}
    for (lo, lower), (hi, upper) in zip(stops, stops[1:]):
        if point.z <= hi:
            blend = (point.z - lo) / (hi - lo)
            return {lower: 1.0 - blend, upper: blend}
    return {"chest": 1.0}


def articulated_limb(side: str, upper: str, lower: str, kind: str, radius: float) -> None:
    """One continuous surface across the joint, with a soft two-bone blend."""
    a, b = RIG.data.bones[f'{upper}_{side}'], RIG.data.bones[f'{lower}_{side}']
    joint = b.head_local
    rows = []
    for bone, points in ((a, ((-.10,.85),(.20,1),(.62,.82),(.88,.74),(1,.70))),
                         (b, ((.12,.73),(.40,.76),(.75,.58),(1.05,.44)))):
        axis = (bone.tail_local-bone.head_local).normalized()
        front = Vector((0,-1,0))
        across = axis.cross(front).normalized()
        for t, width in points:
            center = bone.head_local.lerp(bone.tail_local,t)
            rows.append([center+radius*width*(math.cos(i*math.tau/16)*front+
                         math.sin(i*math.tau/16)*across) for i in range(16)])
    axis = (b.tail_local-joint).normalized()
    def weight(p):
        t = max(0,min(1,.5+(p-joint).dot(axis)/.13))
        return {f'{upper}_{side}':1-t,f'{lower}_{side}':t}
    loft(f'continuous_{upper}_{side}',rows,kind,weight,True)


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


def body(kind: str, stature: float = 1.0, broad: float = 1.0, mail: bool = False,
         hood: bool = False, bare_arms: bool = False) -> None:
    """A complete sculpted body: expressive head, hands, boots, and layered clothes."""
    assert RIG is not None
    cloth = "mail" if mail else kind
    # The tunic is a real shaped volume. The uneven hems keep the silhouettes
    # from becoming five versions of one smooth capsule.
    torso_rows = []
    for z, rx, ry in ((0.87, .18 * broad, .125), (.98, .205 * broad, .14), (1.16, .225 * broad, .145),
                      (1.34, .245 * broad, .15), (1.47, .205 * broad, .13), (1.53, .115 * broad, .08)):
        torso_rows.append([Vector((rx*math.cos(a)*(1+.045*math.cos(7*a)),
                    ry*math.sin(a)*(1+.06*math.cos(7*a)),z))
                    for a in [i*math.tau/24 for i in range(24)]])
    loft("shaped_torso", torso_rows, cloth, torso_weights, smooth=not mail)
    # Separate layered flap gives every wretch cloth that catches a hatch edge.
    for side in (-1, 1):
        points = [Vector((side * .05, -.155, 1.04)), Vector((side * .18 * broad, -.12, .98)),
                  Vector((side * .17 * broad, -.11, .77)), Vector((side * .035, -.14, .73))]
        mesh(f"tunic_split_flap_{side}", points, [(0, 1, 2, 3)], kind, torso_weights, False)
    # Neck, jaw, cranium, nose, brows, ears and cheek planes: these give the
    # face a human read under the black-white material treatment.
    ellipsoid("neck", Vector((0, 0, 1.54)), (.072, .068, .10), "flesh", {"chest": 1}, True, 10, 4)
    ellipsoid("head_cranium", Vector((0, .005, 1.69)), (.122 * broad, .119, .17 * stature), "flesh", {"head": 1}, True, 20, 10)
    ellipsoid("jaw", Vector((0, -.018, 1.59)), (.091 * broad, .101, .072), "flesh", {"head": 1}, True, 12, 5)
    # A broad wedge-like nose and paired brows stay readable from game distance.
    oriented_prism("nose", Vector((0, -.132, 1.70)), Vector((0, -1, 0)), .055, .040, .065, "flesh", {"head": 1}, .45)
    for side in (-1, 1):
        oriented_prism(f"brow_{side}", Vector((side * .062, -.112, 1.755)), Vector((0, -1, 0)), .028,
                        .07, .020, "flesh", {"head": 1}, .75)
        ellipsoid(f"ear_{side}", Vector((side * .14 * broad, .008, 1.69)), (.026, .018, .048), "flesh", {"head": 1}, True, 7, 4)
        ellipsoid(f"eye_socket_{side}", Vector((side*.046, -.108, 1.716)), (.024,.009,.012), "dark", {"head":1}, True, 8, 4)
        ellipsoid(f"lower_lid_{side}", Vector((side*.046, -.115, 1.704)), (.026,.009,.007), "flesh", {"head":1}, True, 8, 3)
    ellipsoid("set_mouth", Vector((0,-.115,1.617)), (.052,.012,.009), "dark", {"head":1}, True, 8, 3)
    if hood:
        hood_mesh = ellipsoid("torn_hood", Vector((0, .018, 1.70)), (.16 * broad, .15, .205), kind,
                  {"head": 1}, True, 12, 7)
        # Remove the front panels; a closed ellipsoid would hide the face.
        import bmesh
        bm = bmesh.new()
        bm.from_mesh(hood_mesh.data)
        remove = [face for face in bm.faces if face.calc_center_median().y < -.05
                  and face.calc_center_median().z < 1.82]
        bmesh.ops.delete(bm, geom=remove, context='FACES')
        bm.to_mesh(hood_mesh.data)
        bm.free()
        # Cut open face achieved with a thick brow and jaw visible forward.
        oriented_prism("hood_brow", Vector((0, -.145, 1.80)), Vector((0, -1, 0)), .04, .22, .045, kind, {"head": 1}, .9)
    for side in ("l", "r"):
        arm_kind = "flesh" if bare_arms else kind
        articulated_limb(side, 'upper_arm', 'forearm', arm_kind, .083*broad)
        hand(side)
        leg(side, kind, broad)
    if mail:
        mail_details(broad)
    belt(broad)


def hand(side: str) -> None:
    """Four curled fingers wrap the same -Y grip axis as the held equipment."""
    sign = 1 if side == "l" else -1
    grip = Vector((sign*.45, -.028, 1.09))
    ellipsoid(f"palm_{side}", grip+Vector((sign*.025,.008,.003)),
              (.029,.043,.040), "flesh", {f"hand_{side}":1}, True, 10, 5)
    for finger in range(4):
        y = -.056+finger*.017
        points = [Vector((grip.x+sign*x,y,grip.z+z)) for x,z in
                  ((.023,.018),(.032,-.005),(.021,-.027),(-.006,-.032),(-.025,-.014),(-.026,.004))]
        rows=[]
        for index,at in enumerate(points):
            tangent=(points[min(index+1,len(points)-1)]-points[max(index-1,0)]).normalized()
            u=Vector((0,1,0)); v=tangent.cross(u).normalized()
            r=.009 if index<4 else .007
            rows.append([at+r*(math.cos(i*math.tau/6)*u+math.sin(i*math.tau/6)*v) for i in range(6)])
        loft(f"finger_{side}_{finger}",rows,'flesh',{f'hand_{side}':1},True)
    ellipsoid(f'thumb_{side}',grip+Vector((-sign*.022,.026,.022)),
              (.013,.025,.020),'flesh',{f'hand_{side}':1},True,8,4)


def leg(side: str, cloth: str, broad: float) -> None:
    sign = 1 if side == "l" else -1
    articulated_limb(side, 'thigh', 'calf', cloth, .107*broad)
    # Boots taper into a long toe pointed along world -Y.
    center = Vector((sign * .09, -.067, .10))
    rows = [ring(Vector((sign*.09,-.065,z)), rx, ry, 14) for z,rx,ry in
            ((.008,.074,.137),(.035,.078,.14),(.085,.074,.134),(.14,.067,.105),(.20,.065,.081),(.25,.059,.067))]
    loft(f"worked_boot_{side}", rows, "leather", {f"foot_{side}": 1}, False)
    # Straps turn a smooth boot into worked clothing in the normal buffer.
    for i, z in enumerate((.105, .155)):
        loft(f"boot_strap_{side}_{i}", [ring(Vector((sign * .09, -.005, z)), .080, .086, 10),
                                         ring(Vector((sign * .09, -.005, z + .016)), .080, .086, 10)], "leather", {f"foot_{side}": 1}, False)


def belt(broad: float) -> None:
    loft("belt", [ring(Vector((0, 0, 1.025)), .20 * broad, .138, 14),
                  ring(Vector((0, 0, 1.062)), .198 * broad, .136, 14)], "leather", torso_weights, False)
    box("belt_buckle", Vector((0, -.145, 1.04)), (.064, .018, .052), "iron", torso_weights, .005)


def mail_details(broad: float) -> None:
    # Open linked rings across the breast read as mail in silhouette and normal
    # edges. A sparse patch avoids spending the budget on hidden shirt surfaces.
    for row,z in enumerate((1.08,1.16,1.24,1.32)):
        for col in range(5):
            x=(col-2)*.069*broad+(row%2)*.012
            verts=[]; faces=[]
            for i in range(8):
                a=i*math.tau/8
                for j in range(4):
                    b=j*math.tau/4
                    verts.append(Vector((x+(.030+.004*math.cos(b))*math.cos(a),
                                -.157+.004*math.sin(b),z+(.023+.004*math.cos(b))*math.sin(a))))
            for i in range(8):
                for j in range(4):
                    faces.append((i*4+j,((i+1)%8)*4+j,((i+1)%8)*4+(j+1)%4,i*4+(j+1)%4))
            mesh(f'mail_link_{row}_{col}',verts,faces,'mail',torso_weights,False)


def weapon_seax() -> None:
    # Right-hand grip, blade forward in the permanent rig's Blender -Y space.
    weight = {"hand_r": 1}
    center = Vector((-.45, -.07, 1.08))
    oriented_prism("seax_grip", center, Vector((0, -1, 0)), .14, .032, .032, "wood", weight, .94)
    oriented_prism("seax_blade", center + Vector((0, -.29, .01)), Vector((0, -1, 0)), .46, .058, .024, "iron", weight, .04)
    box("seax_guard", center + Vector((0, -.08, .01)), (.13, .018, .050), "iron", weight, .003)


def sling_and_pouch() -> None:
    # Held sling is a U of leather, ready to silhouette against the hand.
    weight = {"hand_r": 1}
    points = [Vector((-.49, -.07, 1.09)), Vector((-.45, -.18, 1.01)), Vector((-.40, -.24, .96)),
              Vector((-.35, -.18, 1.01)), Vector((-.31, -.07, 1.09))]
    for index, (a, b) in enumerate(zip(points, points[1:])):
        direction = b - a
        midpoint = (a + b) / 2
        ellipsoid(f"sling_cord_{index}", midpoint, (.014, direction.length / 2, .014), "leather", weight, True, 6, 3)
    ellipsoid("sling_cup", Vector((-.40, -.24, .96)), (.075, .028, .045), "leather", weight, True, 8, 4)
    ellipsoid("sling_stone", Vector((-.40, -.24, .965)), (.035, .026, .031), "stone", weight, False, 7, 4)
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


def wretch() -> bpy.types.Object:
    rig = begin()
    body("rag", stature=.96, broad=.87, hood=False, bare_arms=True)
    weapon_seax()
    # Wound-tight wrap and scavenged shoulder pad make the basic attrition unit
    # feel pitiable rather than a generic bandit.
    ellipsoid("wretch_shoulder_pad", Vector((-.20, .005, 1.43)), (.105, .09, .065), "leather", {"chest": 1}, False, 8, 4)
    # A ragged, split beard and shoulder mantle give the survivor a weathered
    # Dvergar read instead of the bare head and plain shirt of a mannequin.
    for i in range(5):
        x = (i-2)*.030
        loft(f'beard_lock_{i}', [ring(Vector((x,-.103,1.617)),.022,.018,8),
             ring(Vector((x*1.1,-.114,1.568)),.020,.016,8),
             ring(Vector((x*.85,-.100,1.508+abs(i-2)*.016)),.004,.005,8)],
             'dark',{'head':1},True)
    for side in (-1,1):
        verts=[Vector((side*x,y,z)) for x,y,z in ((.06,-.085,1.52),(.21,-.10,1.43),
               (.235,-.14,1.30),(.14,-.166,1.23),(.055,-.15,1.34))]
        mesh(f'torn_mantle_{side}',verts,[(0,1,2,3,4)],'leather',torso_weights,False)
    return rig


def sling_wretch() -> bpy.types.Object:
    rig = begin()
    body("cloth", stature=.94, broad=.82, hood=True, bare_arms=True)
    sling_and_pouch()
    return rig


def bellringer() -> bpy.types.Object:
    rig = begin()
    body("rag", stature=1.0, broad=.93, hood=True, bare_arms=False)
    bell_and_striker()
    # An iron shoulder collar makes the alarm device visually inevitable.
    loft("bellringer_collar", [ring(Vector((0, 0, 1.46)), .20, .14, 14), ring(Vector((0, 0, 1.50)), .14, .10, 14)], "iron", torso_weights, False)
    return rig


def hall_warden() -> bpy.types.Object:
    rig = begin()
    body("cloth", stature=1.03, broad=1.28, mail=False, hood=False, bare_arms=False)
    # Plate is intentionally layered in large planes. It has hard normals and
    # avoids fake micro-detail that would turn into visual scribble.
    for side in (-1, 1):
        ellipsoid(f"warden_pauldrons_{side}", Vector((side * .28, .00, 1.43)), (.17, .14, .095), "iron", {"chest": 1}, False, 10, 5)
    for index, z in enumerate((1.13, 1.23, 1.33, 1.42)):
        loft(f"warden_breast_lame_{index}", [ring(Vector((0, -.02, z)), .27, .17, 14), ring(Vector((0, -.04, z + .055)), .255, .155, 14)], "iron", torso_weights, False)
    ellipsoid("warden_helm", Vector((0, .01, 1.70)), (.18, .16, .20), "iron", {"head": 1}, False, 12, 7)
    for side in (-1, 1):
        oriented_prism(f'warden_eye_slit_{side}', Vector((side*.058,-.147,1.713)),
                       Vector((0,-1,0)), .018,.067,.014,'dark',{'head':1},.8)
    oriented_prism("warden_nasal", Vector((0, -.16, 1.69)), Vector((0, -1, 0)), .045, .045, .18, "iron", {"head": 1}, .85)
    war_hammer()
    return rig


def hoard_keeper() -> bpy.types.Object:
    rig = begin()
    body("cloth", stature=1.02, broad=.87, mail=True, hood=False, bare_arms=False)
    # Narrow cone helm and lamellar skirt distinguish the stationary guardian.
    ellipsoid("keeper_conical_helm", Vector((0, .01, 1.76)), (.145, .14, .22), "iron", {"head": 1}, False, 10, 6)
    for side in (-1, 1):
        for row, z in enumerate((.83, .89, .95)):
            box(f"keeper_lamella_{side}_{row}", Vector((side * .12, -.13, z)), (.13, .025, .075), "iron", {"pelvis": 1}, .005)
    spear()
    return rig


BUILDERS: dict[str, Callable[[], bpy.types.Object]] = {
    "wretch": wretch,
    "sling_wretch": sling_wretch,
    "bellringer": bellringer,
    "hall_warden": hall_warden,
    "hoard_keeper": hoard_keeper,
}


def build(kind: str) -> bpy.types.Object:
    """Build one named model, clearing the scene and returning its shared rig."""
    assert kind in BUILDERS, f"unknown enemy {kind!r}; expected {sorted(BUILDERS)}"
    return BUILDERS[kind]()


def triangle_count() -> int:
    return sum(sum(len(poly.vertices) - 2 for poly in obj.data.polygons) for obj in PARTS)


def validate() -> None:
    assert RIG is not None
    assert len(RIG.data.bones) == 28
    assert triangle_count() <= 6000, triangle_count()
    for obj in PARTS:
        assert obj.matrix_basis.is_identity
        assert obj.data.color_attributes.get("ink") is not None
        assert obj.data.color_attributes["ink"].data_type == "FLOAT_COLOR"
        for vertex in obj.data.vertices:
            assert abs(sum(group.weight for group in vertex.groups) - 1.0) < 1e-5


def export(kind: str) -> dict[str, object]:
    assert RIG is not None
    validate()
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    RIG.select_set(True)
    for obj in PARTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = RIG
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / f"{kind}.blend"))
    bpy.ops.export_scene.gltf(filepath=str(OUT / f"{kind}.glb"), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=False, export_skins=True, export_def_bones=False,
        export_leaf_bone=False, export_animations=False, export_morph=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True, export_extras=True)
    return {"triangles": triangle_count(), "mesh_parts": len(PARTS), "bones": len(RIG.data.bones),
            "source_rig": "humanoid_rig.blend"}


def review(kind: str) -> None:
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
    for location, energy, size in (((-3.2, -4.0, 4.8), 500, 4.0), ((3.5, -1.0, 3.0), 240, 3.0), ((1.0, 3.0, 4.0), 400, 3.0)):
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
        scene.render.filepath = str(SRC / f"{kind}_{suffix}.png")
        bpy.ops.render.render(write_still=True)
        bpy.data.objects.remove(camera, do_unlink=True)


def main() -> None:
    report_path = SRC / "enemy_model_measurements.json"
    report: dict[str, dict[str, object]] = json.loads(report_path.read_text()) if report_path.exists() else {}
    chosen = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else BUILDERS
    for kind in chosen:
        build(kind)
        report[kind] = export(kind)
        review(kind)
    (SRC / "enemy_model_measurements.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
