"""Build Gullsjúkr, the Gold-Sick hero asset, on SHE's permanent humanoid rig.

The silhouette is a weary Bound whose original body is still readable beneath
the hoard.  Its deliberately one-sided plate-and-coin burden is attached to
the chest and right shoulder so the shared 28-bone rig remains animation-ready.

Run: Blender --background --python-exit-code 1 --python build_gullsjukr.py
"""

from __future__ import annotations

import json
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
OUT = ROOT / "game" / "art" / "heroes"
NAME = "gullsjukr"
sys.path.insert(0, str(SRC.parent / "characters"))
import build_worn_armour as armour


# Gold is the only saturated colour.  The exhausted human beneath it stays
# almost paper-grey, allowing the pile to carry the whole threat read.
armour.PALETTE.update({
    "gold": ((0.92, 0.47, 0.055, 1.0), 1.0),
    "old_gold": ((0.57, 0.255, 0.028, 1.0), 1.0),
    "dvergar_plate": ((0.235, 0.225, 0.19, 1.0), 0.4),
    "iron_dark": ((0.095, 0.09, 0.075, 1.0), 0.4),
    "bound_cloth": ((0.21, 0.205, 0.18, 1.0), 0.6),
    "worn_leather": ((0.155, 0.12, 0.08, 1.0), 0.6),
    "skin_ashen": ((0.38, 0.345, 0.29, 1.0), 0.8),
})


def _weights_for_torso(point: Vector) -> dict[str, float]:
    return armour.torso_weights(point)


def _pelvis_or_torso(point: Vector) -> dict[str, float]:
    if point.z < 1.03:
        amount = max(0.0, min(0.78, (1.03 - point.z) * 2.0))
        return {"pelvis": amount, "spine_01": 1.0 - amount}
    return _weights_for_torso(point)


def ellipsoid(name: str, centre, radii, kind: str, weights, around: int = 24, rows: int = 12,
              smooth: bool = True):
    """Low-poly rounded anatomy, with enough contour to survive flat ink."""
    cx, cy, cz = centre
    rx, ry, rz = radii
    verts = [(cx, cy, cz + rz), (cx, cy, cz - rz)]
    for row in range(1, rows):
        theta = math.pi * row / rows
        for step in range(around):
            angle = math.tau * step / around
            verts.append((cx + rx * math.sin(theta) * math.cos(angle),
                          cy + ry * math.sin(theta) * math.sin(angle),
                          cz + rz * math.cos(theta)))
    faces = []
    for step in range(around):
        faces.append((0, 2 + step, 2 + (step + 1) % around))
    for row in range(rows - 2):
        first = 2 + row * around
        next_row = first + around
        for step in range(around):
            following = (step + 1) % around
            faces.append((first + step, first + following, next_row + following, next_row + step))
    last = 2 + (rows - 2) * around
    for step in range(around):
        faces.append((last + (step + 1) % around, last + step, 1))
    return armour.skin_mesh(name, verts, faces, kind, weights, smooth=smooth)


def ring(cx: float, cy: float, z: float, rx: float, ry: float, count: int = 28, wobble: float = 0.0):
    return [(cx + rx * math.cos(a) * (1.0 + wobble * math.sin(3.0 * a)),
             cy + ry * math.sin(a) * (1.0 + wobble * math.cos(5.0 * a)), z)
            for a in (i * math.tau / count for i in range(count))]


def lozenge_panel(name: str, outline, front: float, back: float, kind: str, weights):
    """A thick, chamfered hand-worked plate instead of an undeforming cube."""
    count = len(outline)
    verts = [(x, front, z) for x, z in outline] + [(x, back, z) for x, z in outline]
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count) for i in range(count)]
    return armour.skin_mesh(name, verts, faces, kind, weights, smooth=False)


def tube(name: str, points: list[Vector], radius: float, kind: str, weights,
         sides: int = 10, closed: bool = False, smooth: bool = True):
    """A skinned rope/chain tube with rings perpendicular to its authored path."""
    if closed:
        path = points + [points[0]]
    else:
        path = points
    rings = []
    for index, point in enumerate(path):
        before = path[index - 1] if index else (path[-2] if closed else path[0])
        after = path[(index + 1) % len(path)] if (closed or index + 1 < len(path)) else path[-1]
        axis = (after - before).normalized()
        helper = Vector((0.0, 0.0, 1.0)) if abs(axis.z) < .9 else Vector((0.0, 1.0, 0.0))
        across = axis.cross(helper).normalized()
        up = across.cross(axis).normalized()
        rings.append([point + radius * (math.cos(a) * across + math.sin(a) * up)
                      for a in (i * math.tau / sides for i in range(sides))])
    return armour.loft(name, rings, kind, weights, closed=False, smooth=smooth)


def coin(name: str, centre, radius: float, thickness: float, rotation: tuple[float, float, float],
         kind: str, weights):
    """A struck coin: rim, recessed face and stamped centre provide ink edges."""
    sides = 20
    rings = []
    # Construct around local Z, rotate in place, then put it at the burden.
    # Build rotated geometry directly so all exported node transforms stay 1.
    from mathutils import Euler
    matrix = Euler(rotation).to_matrix().to_4x4()
    for z, scale in ((-thickness * .5, .90), (-thickness * .37, 1.0),
                     (thickness * .37, 1.0), (thickness * .5, .90)):
        rings.append([])
        for i in range(sides):
            a = i * math.tau / sides
            local = Vector((radius * scale * math.cos(a), radius * scale * math.sin(a), z))
            rings[-1].append(tuple(matrix @ local + Vector(centre)))
    # ``loft`` intentionally leaves garments open. Coins need struck faces:
    # without these caps their rim profile reads as a chain link in an ink pass.
    verts = [vertex for row in rings for vertex in row]
    faces = [tuple(reversed(range(sides))), tuple(range(3 * sides, 4 * sides))]
    for row in range(3):
        for step in range(sides):
            nxt = (step + 1) % sides
            faces.append((row * sides + step, row * sides + nxt,
                          (row + 1) * sides + nxt, (row + 1) * sides + step))
    obj = armour.skin_mesh(name, verts, faces, kind, weights, smooth=False)
    # Shallow boss on one face, visibly different from a generic disc in ink.
    boss = ellipsoid(name + "_stamp", tuple(Vector(centre) + matrix @ Vector((0, 0, thickness * .52))),
                     (radius * .23, radius * .23, thickness * .11), kind, weights, 14, 6, False)
    return obj, boss


def core_body():
    """A narrow human body: exhausted anatomy must remain visible under the hoard."""
    torso = []
    for z, rx, ry, x in ((.91, .19, .125, .00), (1.02, .205, .135, .00),
                          (1.15, .222, .142, -.008), (1.29, .238, .150, -.016),
                          (1.40, .254, .153, -.023), (1.47, .205, .130, -.017)):
        torso.append(ring(x, .018, z, rx, ry, 32, .025))
    armour.loft("bound_hollow_torso", torso, "bound_cloth", _weights_for_torso, smooth=True)
    # A tired head, throat and prominent face.  The face is exposed and unobscured.
    armour.loft('exhausted_head', [ring(.035, cy, z, rx, ry, 24) for z,rx,ry,cy in
         ((1.50,.038,.040,-.068),(1.54,.062,.060,-.075),(1.59,.087,.078,-.074),
          (1.65,.119,.090,-.064),(1.72,.126,.099,-.065),(1.78,.109,.094,-.049),
          (1.82,.071,.070,-.030),(1.843,.004,.004,-.023))],
         'skin_ashen',{'head':1},smooth=True)
    ellipsoid("throat", (.050, -.030, 1.525), (.060, .056, .080), "skin_ashen", {"neck": 1.0}, 18, 9)
    armour.loft('hooked_nose', [ring(.035, cy, z, rx, ry, 12) for z,rx,ry,cy in
         ((1.658,.010,.012,-.166),(1.676,.024,.027,-.186),
          (1.705,.013,.020,-.170),(1.734,.008,.010,-.158))],
         'skin_ashen', {'head':1}, smooth=True)
    for side in (-1, 1):
        ellipsoid("sunken_eye_%s" % side, (.035 + side * .047, -.159, 1.716), (.022, .010, .010),
                  "iron_dark", {"head": 1.0}, 14, 7)
    lozenge_panel("furrowed_brow", [(-.078, 1.743), (-.010, 1.737), (.070, 1.736),
                                      (.142, 1.745), (.113, 1.724), (.010, 1.718)], -.168, -.183,
                  "skin_ashen", {"head": 1.0})
    tube("set_mouth", [Vector((-.015, -.151, 1.598)), Vector((.035, -.160, 1.608)),
                       Vector((.085, -.151, 1.598))], .005, "iron_dark", {"head": 1.0}, 7, False)
    # Bare upper arms and hands make the person inside the equipment unmistakable.
    for side in ("l", "r"):
        # Use the same continuous elbow surface as the standard enemies.
        sys.path.insert(0, str(SRC.parent / "enemies"))
        import build_enemy_models as enemy_mesh
        enemy_mesh.RIG = armour.RIG
        enemy_mesh.PARTS = []
        enemy_mesh.MATERIALS = {}
        enemy_mesh.PALETTE["skin_ashen"] = (armour.PALETTE["skin_ashen"][0], .8, 0)
        enemy_mesh.articulated_limb(side, 'upper_arm', 'forearm', 'skin_ashen', .078)
        armour.PARTS.extend(enemy_mesh.PARTS)
        hand = armour.RIG.data.bones["hand_" + side].head_local
        ellipsoid("working_hand_" + side, tuple(hand + Vector((0, -.012, -.015))), (.067, .056, .075),
                  "skin_ashen", {"hand_" + side: 1.0}, 18, 9)
        sign = 1 if side == 'l' else -1
        for finger in range(4):
            at = hand + Vector((sign*.035, -.035+finger*.021, -.045))
            tube('finger_%s_%s' % (side, finger), [at, at+Vector((sign*.025,0,-.043)),
                 at+Vector((sign*.020,-.014,-.078)), at+Vector((0,-.025,-.073))],
                 .011, 'skin_ashen', {'hand_'+side:1}, 8, True)
    for side in ("l", "r"):
        sign = 1 if side == "l" else -1
        leg_rings = []
        for z, rx, ry in ((.23, .087, .090), (.36, .083, .087), (.55, .094, .094), (.77, .104, .097), (.93, .107, .098)):
            leg_rings.append(ring(sign * .09, .016, z, rx, ry, 24, .02))
        def leg_weight(point, side=side):
            blend = max(0.0, min(1.0, (point.z - .48) / .16))
            return {"calf_" + side: 1.0 - blend, "thigh_" + side: blend}
        armour.loft("bound_trouser_" + side, leg_rings, "bound_cloth", leg_weight, smooth=True)
        # Low, broad boots show a dragged gait without growing the navigation radius.
        boot_rings = []
        for z, rx, front, back in ((.018, .100, -.205, .070), (.050, .108, -.220, .078),
                                  (.115, .101, -.190, .078), (.195, .087, -.095, .073), (.235, .080, -.060, .067)):
            centre_y, ry = (front + back) * .5, (back - front) * .5
            boot_rings.append([(sign * .09 + rx * math.cos(a), centre_y + ry * math.sin(a), z)
                               for a in (i * math.tau / 26 for i in range(26))])
        armour.loft("dragged_boot_" + side, boot_rings, "worn_leather", {"foot_" + side: 1.0}, smooth=False)


def dvergar_plate():
    """Worked armour plates give the asymmetric burden a readable engineered origin."""
    chest_weight = _weights_for_torso
    lozenge_panel("split_dvergar_breastplate", [(-.222, 1.44), (-.268, 1.32), (-.237, 1.15),
                                                  (-.160, 1.055), (-.042, 1.035), (.070, 1.075),
                                                  (.162, 1.18), (.187, 1.34), (.126, 1.45),
                                                  (-.030, 1.485)], -.174, -.142, "dvergar_plate", chest_weight)
    lozenge_panel("broken_breastplate", [(.094, 1.43), (.215, 1.36), (.250, 1.20), (.195, 1.10),
                                           (.115, 1.07), (.063, 1.14)], -.177, -.143, "old_gold", chest_weight)
    # Right is the negative-X shoulder on the permanent rig.  Each plate steps
    # upward and outward, creating one monumental, crushing shoulder.
    for index, (x, z, width, height, tilt) in enumerate(((-.15, 1.45, .21, .17, 0.0),
                                                          (-.25, 1.56, .23, .19, .0),
                                                          (-.34, 1.67, .21, .20, 0.0),
                                                          (-.40, 1.79, .18, .18, 0.0))):
        outline = [(x - width, z - height * .30), (x - width * .70, z + height * .46),
                   (x + width * .42, z + height * .55), (x + width, z + height * .02),
                   (x + width * .62, z - height * .48), (x - width * .38, z - height * .54)]
        lozenge_panel("shoulder_plate_%02d" % index, outline, -.055 - index * .010,
                      .082 + index * .006, "dvergar_plate" if index % 2 else "old_gold", {"chest": .72, "clavicle_r": .28})
    for index, x in enumerate((-.19, -.10, .00, .10)):
        ellipsoid("plate_rivet_%02d" % index, (x, -.187, 1.35 + .025 * (index % 2)),
                  (.020, .012, .020), "gold", chest_weight, 14, 7, False)


def burden_of_coins():
    """Fused currency is made of deliberate overlapping strikes, never blocky piles."""
    rng = random.Random(1717)
    positions = []
    # A dense shoulder crown, descending across the back and chest.  It rises to
    # 2m while the locomotion body remains inside the 0.55m nav radius.
    for layer, (z, count, spread) in enumerate(((1.43, 14, .34), (1.57, 18, .39),
                                                  (1.70, 17, .36), (1.83, 12, .28),
                                                  (1.95, 7, .18))):
        for i in range(count):
            arc = (i / max(1, count - 1) - .50)
            x = -.26 + arc * (spread * .80) + rng.uniform(-.026, .026)
            y = .025 + rng.uniform(-.12, .13)
            if layer < 2 and i % 3 == 0:
                y = -.155 + rng.uniform(-.018, .024)
            positions.append((x, y, z + rng.uniform(-.028, .028), .048 + rng.random() * .027,
                              rng.uniform(-.65, .65), rng.uniform(-.85, .85)))
    for index, (x, y, z, radius, rx, rz) in enumerate(positions):
        coin("fused_coin_%03d" % index, (x, y, z), radius, .014 + radius * .14,
             (rx, 0.35 + (index % 5) * .28, rz), "gold" if index % 4 else "old_gold",
             {"chest": .78, "clavicle_r": .22} if z > 1.54 else _weights_for_torso)
    # Three broad, half-buried medallions interrupt the coin scale with faces a
    # player can read as Dvergar work from a doorway.
    for index, (x, y, z, scale) in enumerate(((-.41, -.095, 1.66, .100), (-.24, -.176, 1.47, .098),
                                               (-.39, .105, 1.84, .085))):
        coin("hoard_medallion_%d" % index, (x, y, z), scale, .030, (.95, .0, .18 * index),
             "gold", {"chest": .74, "clavicle_r": .26})


def chains_and_sacks():
    """Hanging weight tells the player why Gullsjúkr moves badly before it moves."""
    pelvis = {"pelvis": 1.0}
    for side, x in (("r", -.205), ("l", .205)):
        ellipsoid("coin_sack_" + side, (x, .085, .805), (.126, .105, .175), "worn_leather", pelvis, 24, 12)
        # Leather contains the hoard; a few struck faces emerge at the mouth.
        # A gold sphere on the front reads as another limb rather than money.
        for index in range(4):
            coin('sack_coin_%s_%d' % (side, index),
                 (x + (index - 1.5)*.035, -.005, .925 + .009*(index%2)),
                 .031, .009, (1.1, .20*index, .18*index), 'old_gold', pelvis)
        tube('sack_tie_'+side, [Vector((x-.055,.005,.945)), Vector((x,-.020,.955)),
             Vector((x+.055,.005,.945))], .009, 'worn_leather', pelvis, 8, True)
        tube("sack_rope_" + side, [Vector((x - .12, .01, 1.08)), Vector((x, -.02, 1.02)),
                                      Vector((x + .09, .018, .96)), Vector((x, .06, .90))],
             .012, "worn_leather", _pelvis_or_torso, 9, False)
    # Eight oversized interlocked links show as distinct loops, not a texture.
    for index in range(9):
        t = index / 8.0
        x = -.33 + .10 * math.sin(t * math.pi * 1.4)
        y = -.18 - .018 * (index % 2)
        z = 1.42 - t * .70
        points = []
        for step in range(17):
            a = step * math.tau / 16
            if index % 2:
                points.append(Vector((x + .036 * math.cos(a), y + .012 * math.sin(a), z + .066 * math.sin(a))))
            else:
                points.append(Vector((x + .062 * math.cos(a), y + .014 * math.sin(a), z + .034 * math.sin(a))))
        tube("heavy_chain_link_%02d" % index, points, .010, "old_gold", _pelvis_or_torso, 8, True)
    # A slipped chain runs from the crown, crosses the chest and ends at a hand.
    tube("chest_drag_chain", [Vector((-.42, -.02, 1.89)), Vector((-.30, -.18, 1.67)),
                               Vector((-.10, -.205, 1.45)), Vector((.08, -.190, 1.22)),
                               Vector((.30, -.125, 1.06))], .014, "old_gold", _weights_for_torso, 10, False)


def make_review():
    """Two inspection renders: bind silhouette and a stress pose for weighted fit."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 32
    scene.render.resolution_x, scene.render.resolution_y = 1050, 1250
    scene.render.resolution_percentage = 100
    scene.world.color = (.018, .014, .010)
    scene.view_settings.look = "AgX - Medium High Contrast"
    for location, energy, color, size in (((-3.4, -4.5, 4.0), 1200, (1.0, .62, .25), 3.5),
                                          ((3.0, -1.0, 2.7), 800, (.48, .55, 1.0), 3.0),
                                          ((-.5, 3.5, 4.2), 1000, (1.0, .28, .06), 2.5)):
        bpy.ops.object.light_add(type="AREA", location=location)
        lamp = bpy.context.object
        lamp.data.energy, lamp.data.color, lamp.data.shape, lamp.data.size = energy, color, "DISK", size
        lamp.rotation_euler = (Vector((-.08, 0, 1.05)) - lamp.location).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.camera_add(location=(3.05, -5.0, 2.25))
    camera = bpy.context.object
    camera.data.type, camera.data.lens = "ORTHO", 50
    camera.data.ortho_scale = 2.35
    camera.rotation_euler = (Vector((-.10, 0, 1.05)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera
    scene.render.filepath = str(SRC / (NAME + "_review.png"))
    bpy.ops.render.render(write_still=True)
    for side in ("l", "r"):
        armour.RIG.pose.bones["forearm_" + side].rotation_mode = "XYZ"
        armour.RIG.pose.bones["forearm_" + side].rotation_euler.x = -.62
        armour.RIG.pose.bones["thigh_" + side].rotation_mode = "XYZ"
        armour.RIG.pose.bones["thigh_" + side].rotation_euler.x = .30 if side == "l" else -.18
    armour.RIG.pose.bones["chest"].rotation_mode = "XYZ"
    armour.RIG.pose.bones["chest"].rotation_euler.x = .10
    scene.render.filepath = str(SRC / (NAME + "_posed_review.png"))
    bpy.ops.render.render(write_still=True)


def build():
    """Return the untouched shared rig with a fully skinned Gullsjúkr bind pose."""
    armour.begin()
    core_body()
    dvergar_plate()
    burden_of_coins()
    chains_and_sacks()
    return armour.RIG


def export_and_measure():
    rig = build()
    triangles = sum(len(poly.vertices) - 2 for obj in armour.PARTS for poly in obj.data.polygons)
    assert 15000 <= triangles <= 40000, triangles
    assert len(rig.data.bones) == 28
    assert rig.scale == Vector((1, 1, 1))
    for obj in armour.PARTS:
        assert obj.matrix_basis.is_identity
        assert obj.data.color_attributes.active_color is not None
        assert obj.data.color_attributes.active_color.data_type == "FLOAT_COLOR"
        for vertex in obj.data.vertices:
            assert abs(sum(group.weight for group in vertex.groups) - 1.0) < 1e-5
    bpy.context.scene["asset"] = "Gullsjukr / Gold-Sick"
    bpy.context.scene["source_rig"] = "humanoid_rig.blend"
    bpy.context.scene["nav_radius_m"] = .55
    bpy.context.scene["nav_height_m"] = 2.0
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / (NAME + ".blend")))
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    for obj in armour.PARTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=str(OUT / (NAME + ".glb")), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=False, export_skins=True, export_def_bones=False, export_leaf_bone=False,
        export_animations=False, export_morph=False, export_cameras=False, export_lights=False,
        export_vertex_color="ACTIVE", export_attributes=True, export_extras=True)
    report = {"asset": NAME, "triangles": triangles, "mesh_parts": len(armour.PARTS),
              "bones": len(rig.data.bones), "source_rig": "humanoid_rig.blend", "units": "metres",
              "nav_radius_m": .55, "nav_height_m": 2.0, "bind_pose": True,
              "weighted_bones": sorted({group.name for obj in armour.PARTS for group in obj.vertex_groups})}
    (SRC / (NAME + "_measurements.json")).write_text(json.dumps(report, indent=2) + "\n")
    make_review()
    return report


def main():
    print(json.dumps(export_and_measure(), indent=2))


if __name__ == "__main__":
    main()
