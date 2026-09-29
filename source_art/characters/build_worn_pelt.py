"""Author Ótr's pelt as DES-020 Body armour on the permanent shared rig.

The loose relic stays a floor prop. This garment is its own skinned scene: a
linen/leather underlayer keeps the silhouette believable, while the pelt's
mantle, head, paws and tail make the public-domain Ótr reference unmistakable.

Run: Blender --background --python-exit-code 1 --python this_file.py
"""
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_worn_armour as a


NAME = "otr_pelt_worn"
SRC = Path(__file__).resolve().parent
a.PALETTE.update({
    # Ink's B channel is a quantized material class. Keep every pelt surface
    # on the established 0.8 class rather than an in-between encoded value.
    "linen": ((0.43, 0.41, 0.36, 1.0), 0.8),
    "fur": ((0.18, 0.135, 0.080, 1.0), 0.8),
    "fur_light": ((0.34, 0.255, 0.145, 1.0), 0.8),
    "nose": ((0.045, 0.035, 0.028, 1.0), 0.8),
})


def outline_prism(name, outline, front, back, kind, weights):
    """A soft, irregular hide panel with an authored silhouette, never a box."""
    verts = [(x, front, z) for x, z in outline] + [(x, back, z) for x, z in outline]
    count = len(outline)
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count)
              for i in range(count)]
    return a.skin_mesh(name, verts, faces, kind, weights, smooth=True)


def ellipsoid(name, center, radii, kind, weights, around=16, high=7):
    """Rounded anatomy for head, paws and ears; a low-poly form stays legible."""
    cx, cy, cz = center
    rx, ry, rz = radii
    verts = [(cx, cy, cz + rz), (cx, cy, cz - rz)]
    for row in range(1, high):
        theta = math.pi * row / high
        for step in range(around):
            angle = math.tau * step / around
            verts.append((cx + rx * math.sin(theta) * math.cos(angle),
                          cy + ry * math.sin(theta) * math.sin(angle),
                          cz + rz * math.cos(theta)))
    faces = []
    for step in range(around):
        faces.append((0, 1 + (step + 1) % around, 1 + step))
    for row in range(high - 2):
        first = 1 + row * around
        next_row = first + around
        for step in range(around):
            following = (step + 1) % around
            faces.append((first + step, first + following,
                          next_row + following, next_row + step))
    last = 1 + (high - 2) * around
    for step in range(around):
        faces.append((last + step, last + (step + 1) % around, 1))
    return a.skin_mesh(name, verts, faces, kind, weights, smooth=True)


def upper_arm_weights(side):
    start, end, _front, _across = a.limb_basis(side, "upper_arm")

    def weigh(point):
        along = max(0.0, min(1.0, (point - start).dot(end - start) /
                             (end - start).length_squared))
        chest = max(0.0, 0.48 * (1.0 - along / 0.48))
        return {"chest": chest, "upper_arm_%s" % side: 1.0 - chest}
    return weigh


def fur_cowl(side):
    start, end, front, across = a.limb_basis(side, "upper_arm")
    rings = []
    for at, radius in ((-0.12, 0.060), (0.02, 0.083), (0.22, 0.089),
                       (0.46, 0.078), (0.60, 0.061)):
        centre = start.lerp(end, at)
        rings.append([centre + radius * (math.cos(angle) * front
                      + math.sin(angle) * across)
                      for angle in [i * math.tau / 18 for i in range(18)]])
    a.loft("fur_cowl_%s" % side, rings, "fur", upper_arm_weights(side), smooth=True)


def fur_tuft(name, x, y, top, bottom, radius, weights):
    """A tapered hanging clump makes the mantle's hem read as fur, not cloth."""
    rings = []
    for z, scale in ((top, 0.76), ((top + bottom) * 0.5, 1.0),
                     (bottom + 0.035, 0.56), (bottom, 0.08)):
        rings.append([(x + radius * scale * math.cos(angle),
                       y + radius * 0.55 * scale * math.sin(angle), z)
                      for angle in [i * math.tau / 12 for i in range(12)]])
    a.loft(name, rings, "fur", weights, smooth=True)


def otter_muzzle():
    """Taper the snout forward so the shoulder pelt reads as an otter head."""
    rings = []
    for y, rx, rz in ((-.132, .062, .042), (-.185, .050, .034),
                      (-.231, .028, .021)):
        rings.append([(-.205 + rx * math.cos(angle), y,
                      1.561 + rz * math.sin(angle))
                      for angle in [i * math.tau / 14 for i in range(14)]])
    a.loft("otter_tapered_muzzle", rings, "fur_light", {"chest": 1.0}, smooth=True)


def review():
    """Render with the same Body coverage mask the runtime applies to the proxy."""
    with bpy.data.libraries.load(str(SRC / "humanoid_rig.blend"), link=False) as (source, loaded):
        loaded.objects = [name for name in source.objects if name == "proxy_body"]
    for body in loaded.objects:
        if body is None:
            continue
        bpy.context.collection.objects.link(body)
        body.parent = a.RIG
        for modifier in body.modifiers:
            if modifier.type == "ARMATURE":
                modifier.object = a.RIG
        covered = {"pelvis", "spine_01", "spine_02", "chest", "upper_arm_l",
                   "upper_arm_r", "thigh_l", "thigh_r", "calf_l", "calf_r", "foot_l", "foot_r"}
        group_ids = {group.index for group in body.vertex_groups if group.name in covered}
        hidden = {vertex.index for vertex in body.data.vertices
                  if any(group.group in group_ids and group.weight > .5 for group in vertex.groups)}
        mesh = bmesh.new()
        mesh.from_mesh(body.data)
        mesh.verts.ensure_lookup_table()
        bmesh.ops.delete(mesh, geom=[vertex for vertex in mesh.verts if vertex.index in hidden], context="VERTS")
        mesh.to_mesh(body.data)
        mesh.free()

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.render.resolution_x = 1000
    scene.render.resolution_y = 1100
    scene.render.resolution_percentage = 100
    scene.world.color = (.28, .28, .28)
    scene.view_settings.view_transform = "AgX"
    for location, power, size in (((-3, -4, 5), 700, 4), ((3, -1, 3), 450, 3), ((1, 3, 4), 650, 3)):
        bpy.ops.object.light_add(type="AREA", location=location)
        lamp = bpy.context.object
        lamp.data.energy = power
        lamp.data.shape = "DISK"
        lamp.data.size = size
        lamp.rotation_euler = (Vector((0, 0, 1)) - lamp.location).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.camera_add(location=(2.5, -4, 2.0))
    camera = bpy.context.object
    scene.camera = camera
    camera.rotation_euler = (Vector((0, 0, 1.03)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.15
    scene.render.filepath = str(SRC / (NAME + "_review.png"))
    bpy.ops.render.render(write_still=True)
    for side in ("l", "r"):
        a.RIG.pose.bones["forearm_%s" % side].rotation_mode = "XYZ"
        a.RIG.pose.bones["forearm_%s" % side].rotation_euler.x = -.85
        a.RIG.pose.bones["thigh_%s" % side].rotation_mode = "XYZ"
        a.RIG.pose.bones["thigh_%s" % side].rotation_euler.x = .45
        a.RIG.pose.bones["calf_%s" % side].rotation_mode = "XYZ"
        a.RIG.pose.bones["calf_%s" % side].rotation_euler.x = -.6
    a.RIG.pose.bones["chest"].rotation_mode = "XYZ"
    a.RIG.pose.bones["chest"].rotation_euler.x = .15
    scene.render.filepath = str(SRC / (NAME + "_posed_review.png"))
    bpy.ops.render.render(write_still=True)


def pelt():
    # Build the proven Body coverage first. It has trousers, boots, upper arms
    # and torso already skinned to the permanent rig; mail becomes a quiet
    # linen tunic beneath the pelt rather than a second unrelated garment.
    a.mail()
    for part in a.PARTS:
        if "mail" in part.name:
            part.name = part.name.replace("mail", "linen")
            part.data.name = part.data.name.replace("mail", "linen")
            part.data.materials.clear()
            part.data.materials.append(a.mat("linen"))

    # Wide yoke, chest bib and back mantle overlap enough that a moving torso
    # reads as one hide. The asymmetric lower outline is modeled as hide, then
    # the hanging clumps make the edge visibly furred at player distance.
    a.loft("otter_fur_yoke", [a.ellipse(rx, ry, z) for z, rx, ry in
        ((1.38, .248, .160), (1.45, .276, .178), (1.53, .270, .169),
         (1.59, .210, .130))], "fur", a.torso_weights, smooth=True)
    outline_prism("otter_fur_chest", [(-.245, 1.52), (-.275, 1.40),
        (-.245, 1.24), (-.205, 1.09), (-.135, 1.02), (-.055, 1.08),
        (.035, 1.00), (.115, 1.10), (.205, 1.07), (.250, 1.22),
        (.262, 1.42), (.205, 1.54)], -.164, -.117, "fur", a.torso_weights)
    outline_prism("otter_fur_back", [(-.265, 1.57), (-.292, 1.39),
        (-.285, 1.16), (-.242, .98), (-.185, .91), (-.120, .97),
        (-.050, .89), (.025, .96), (.105, .90), (.180, .98), (.238, .93),
        (.286, 1.11), (.280, 1.40), (.226, 1.57)], .118, .174, "fur",
        a.torso_weights)
    for side in ("l", "r"):
        fur_cowl(side)

    def mantle_weights(point):
        if point.z < 1.03:
            t = max(0.0, min(0.75, (1.03 - point.z) * 1.9))
            return {"pelvis": t, "spine_01": 1.0 - t}
        return a.torso_weights(point)
    for index, (x, top, bottom) in enumerate((
            (-.245, 1.09, .89), (-.175, 1.06, .84), (-.095, 1.04, .88),
            (-.015, 1.04, .81), (.070, 1.03, .87), (.155, 1.07, .83),
            (.235, 1.10, .90))):
        fur_tuft("otter_back_tuft_%02d" % index, x, .178, top, bottom,
                 .052 if index % 2 else .061, mantle_weights)

    # Ótr's head lies across the left shoulder, with small paws hanging over
    # the bib. The long taper of the tail runs down the back and remains bound
    # to chest/pelvis rather than being a rigid prop at the spine.
    ellipsoid("otter_head", (-.205, -.030, 1.585), (.118, .135, .098),
              "fur_light", {"chest": 1.0}, 18, 8)
    otter_muzzle()
    ellipsoid("otter_nose", (-.205, -.248, 1.562), (.020, .013, .014),
              "nose", {"chest": 1.0}, 12, 5)
    for side in (-1, 1):
        ellipsoid("otter_ear_%d" % side, (-.205 + side * .067, -.028, 1.650),
                  (.022, .014, .017), "fur", {"chest": 1.0}, 12, 5)
    for side in (-1, 1):
        ellipsoid("otter_paw_%d" % side, (side * .185, -.192, 1.135),
                  (.055, .035, .092), "fur_light", a.torso_weights, 14, 7)
    tail_rings = []
    for centre, rx, ry in [((.02, .175, 1.14), .090, .062),
                            ((.04, .238, .99), .082, .057),
                            ((.09, .315, .79), .065, .047),
                            ((.14, .390, .61), .047, .035),
                            ((.19, .442, .49), .018, .015)]:
        x, y, z = centre
        tail_rings.append([(x + rx * math.cos(angle),
                            y + ry * math.sin(angle), z)
                           for angle in [i * math.tau / 16 for i in range(16)]])
    a.loft("otter_tapered_tail", tail_rings, "fur", mantle_weights, smooth=True)


def main():
    a.begin()
    pelt()
    measurement = a.export(NAME)
    review()
    (SRC / (NAME + "_measurements.json")).write_text(
        json.dumps({NAME: measurement}, indent=2) + "\n")
    print(json.dumps({NAME: measurement}, indent=2))


if __name__ == "__main__":
    main()
