"""Author the six ART-006 weapon assets and their review sheet in Blender.

Weapons live in Blender coordinates with their grip at the origin, a blade or
aiming direction along +Y, and the hand-facing-up direction along +Z. Blender's
glTF exporter converts that to the project's Y-up, -Z-forward convention.
"""

from __future__ import annotations

import math
import os
import shutil

import bpy
from mathutils import Vector


ROOT = os.path.dirname(os.path.abspath(__file__))
EXPORT_DIR = os.path.normpath(os.path.join(ROOT, "../../game/art/weapons"))
BLEND_PATH = os.path.join(ROOT, "weapons.blend")
REVIEW_PATH = os.path.join(ROOT, "weapons_review_sheet.png")

# ART-006 §2.3: outline R, hatch G, ink/material B.
INK = {
    "wood": (1.0, 0.5, 0.2, 1.0),
    "metal": (1.0, 0.5, 0.4, 1.0),
    "leather": (1.0, 0.5, 0.6, 1.0),
}
MATERIAL_COLOURS = {
    "wood": (0.29, 0.285, 0.265, 1.0),
    "metal": (0.34, 0.37, 0.39, 1.0),
    "leather": (0.19, 0.185, 0.175, 1.0),
}


def material(name: str) -> bpy.types.Material:
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.diffuse_color = MATERIAL_COLOURS[name]
        mat.use_nodes = True
        principled = mat.node_tree.nodes.get("Principled BSDF")
        principled.inputs["Base Color"].default_value = MATERIAL_COLOURS[name]
        principled.inputs["Roughness"].default_value = 0.82
        principled.inputs["Metallic"].default_value = 0.72 if name == "metal" else 0.0
    return mat


def mesh_object(
    collection: bpy.types.Collection,
    name: str,
    verts: list[tuple[float, float, float]],
    faces: list[tuple[int, ...]],
    material_name: str,
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name + "_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(material(material_name))
    mesh.update()
    for poly in mesh.polygons:
        poly.use_smooth = False
        poly.material_index = 0
    colour = mesh.color_attributes.new("ink", "FLOAT_COLOR", "POINT")
    for point in colour.data:
        point.color = INK[material_name]
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    return obj


def box(
    collection: bpy.types.Collection,
    name: str,
    x0: float, x1: float, y0: float, y1: float, z0: float, z1: float,
    material_name: str,
) -> bpy.types.Object:
    verts = [
        (x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
        (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1),
    ]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
             (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return mesh_object(collection, name, verts, faces, material_name)


def prism_yz(
    collection: bpy.types.Collection,
    name: str,
    profile: list[tuple[float, float]],
    half_width: float,
    material_name: str,
) -> bpy.types.Object:
    """Extrude a weapon side-profile in the Y/Z plane across the X axis."""
    verts = [(-half_width, y, z) for y, z in profile]
    verts += [(half_width, y, z) for y, z in profile]
    count = len(profile)
    faces: list[tuple[int, ...]] = [tuple(range(count - 1, -1, -1)), tuple(range(count, count * 2))]
    for i in range(count):
        j = (i + 1) % count
        faces.append((i, j, count + j, count + i))
    return mesh_object(collection, name, verts, faces, material_name)


def cylinder_y(
    collection: bpy.types.Collection,
    name: str,
    y0: float, y1: float, radius: float,
    material_name: str,
    sides: int = 8,
    r1: float | None = None,
) -> bpy.types.Object:
    r1 = radius if r1 is None else r1
    verts: list[tuple[float, float, float]] = []
    for y, r in ((y0, radius), (y1, r1)):
        for index in range(sides):
            angle = math.tau * index / sides
            verts.append((math.cos(angle) * r, y, math.sin(angle) * r))
    faces: list[tuple[int, ...]] = [tuple(range(sides - 1, -1, -1)), tuple(range(sides, sides * 2))]
    for index in range(sides):
        next_index = (index + 1) % sides
        faces.append((index, next_index, sides + next_index, sides + index))
    return mesh_object(collection, name, verts, faces, material_name)


def cylinder_between(
    collection: bpy.types.Collection,
    name: str,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    radius: float,
    material_name: str,
    sides: int = 6,
) -> bpy.types.Object:
    a, b = Vector(start), Vector(end)
    axis = (b - a).normalized()
    reference = Vector((1.0, 0.0, 0.0)) if abs(axis.x) < 0.9 else Vector((0.0, 1.0, 0.0))
    u = axis.cross(reference).normalized()
    v = axis.cross(u).normalized()
    verts: list[tuple[float, float, float]] = []
    for anchor in (a, b):
        for index in range(sides):
            point = anchor + radius * (math.cos(math.tau * index / sides) * u + math.sin(math.tau * index / sides) * v)
            verts.append(tuple(point))
    faces: list[tuple[int, ...]] = [tuple(range(sides - 1, -1, -1)), tuple(range(sides, sides * 2))]
    for index in range(sides):
        next_index = (index + 1) % sides
        faces.append((index, next_index, sides + next_index, sides + index))
    return mesh_object(collection, name, verts, faces, material_name)


def create_collection(name: str) -> bpy.types.Collection:
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    return collection


def seax() -> bpy.types.Collection:
    c = create_collection("seax")
    cylinder_y(c, "seax_grip", -0.08, 0.05, 0.036, "leather")
    cylinder_y(c, "seax_pommel", -0.11, -0.08, 0.046, "metal", r1=0.041)
    box(c, "seax_guard", -0.022, 0.022, 0.045, 0.070, -0.095, 0.095, "metal")
    prism_yz(c, "seax_blade", [(0.065, -0.055), (0.065, 0.062), (0.32, 0.058), (0.39, 0.0), (0.28, -0.040)], 0.014, "metal")
    prism_yz(c, "seax_spine", [(0.11, 0.063), (0.32, 0.059), (0.36, 0.018), (0.11, 0.024)], 0.019, "metal")
    return c


def bearded_axe() -> bpy.types.Collection:
    c = create_collection("bearded_axe")
    cylinder_y(c, "axe_haft", -0.11, 0.54, 0.035, "wood", r1=0.030)
    cylinder_y(c, "axe_grip", -0.11, 0.07, 0.043, "leather", r1=0.038)
    cylinder_y(c, "axe_butt", -0.15, -0.11, 0.043, "metal", r1=0.035)
    prism_yz(c, "axe_head", [(0.43, -0.06), (0.45, 0.13), (0.65, 0.20), (0.63, 0.07), (0.58, -0.22), (0.48, -0.25)], 0.048, "metal")
    box(c, "axe_eye", -0.058, 0.058, 0.45, 0.53, -0.065, 0.065, "metal")
    return c


def ash_spear() -> bpy.types.Collection:
    c = create_collection("ash_spear")
    cylinder_y(c, "spear_shaft", -0.18, 1.55, 0.026, "wood", sides=8, r1=0.020)
    cylinder_y(c, "spear_grip", -0.08, 0.23, 0.035, "leather", sides=8, r1=0.032)
    cylinder_y(c, "spear_socket", 1.48, 1.62, 0.040, "metal", sides=8, r1=0.028)
    prism_yz(c, "spear_head", [(1.55, 0.0), (1.66, 0.095), (1.82, 0.0), (1.66, -0.095)], 0.018, "metal")
    cylinder_y(c, "spear_butt_cap", -0.18, -0.12, 0.038, "metal", sides=6, r1=0.026)
    return c


def yew_bow() -> bpy.types.Collection:
    c = create_collection("yew_bow")
    # A bow is upright in the hand: grip and limbs run along Z.  The carved
    # stave bows forward (+Y); the single taut string is behind the grip (-Y).
    cylinder_between(c, "bow_grip", (0.0, 0.035, -0.115), (0.0, 0.035, 0.115), 0.036, "leather", 8)
    upper = [(0.04, 0.115), (0.15, 0.26), (0.25, 0.42),
             (0.30, 0.58), (0.24, 0.72), (-0.13, 0.80)]
    lower = [(0.04, -0.115), (0.15, -0.26), (0.25, -0.42),
             (0.30, -0.58), (0.24, -0.72), (-0.13, -0.80)]
    for label, points in (("upper", upper), ("lower", lower)):
        for index, ((y0, z0), (y1, z1)) in enumerate(zip(points, points[1:])):
            cylinder_between(c, "bow_%s_%d" % (label, index), (0.0, y0, z0), (0.0, y1, z1), 0.027 - index * 0.004, "wood")
    cylinder_between(c, "bow_string", (0.0, -0.13, -0.80), (0.0, -0.13, 0.80), 0.006, "leather", 5)
    return c


def dvergar_hammer() -> bpy.types.Collection:
    c = create_collection("dvergar_hammer")
    cylinder_y(c, "hammer_haft", -0.14, 0.46, 0.047, "wood", sides=8, r1=0.038)
    cylinder_y(c, "hammer_grip", -0.14, 0.12, 0.054, "leather", sides=8, r1=0.047)
    cylinder_y(c, "hammer_butt", -0.18, -0.14, 0.060, "metal", sides=8, r1=0.047)
    box(c, "hammer_head", -0.16, 0.16, 0.40, 0.58, -0.20, 0.20, "metal")
    prism_yz(c, "hammer_peen", [(0.57, -0.13), (0.66, -0.07), (0.67, 0.07), (0.57, 0.13)], 0.11, "metal")
    box(c, "hammer_strike_face", -0.21, 0.21, 0.34, 0.41, -0.15, 0.15, "metal")
    cylinder_y(c, "hammer_wedge", 0.46, 0.51, 0.060, "metal", sides=6, r1=0.052)
    return c


def regin_blade() -> bpy.types.Collection:
    c = create_collection("regin_blade")
    cylinder_y(c, "regin_grip", -0.09, 0.07, 0.040, "leather", sides=8)
    cylinder_y(c, "regin_pommel", -0.14, -0.08, 0.058, "metal", sides=6, r1=0.042)
    box(c, "regin_guard", -0.028, 0.028, 0.065, 0.105, -0.14, 0.14, "metal")
    # Uneven shoulders and a stepped fuller make the old, reforged relic legible.
    prism_yz(c, "regin_blade", [(0.09, -0.055), (0.19, -0.092), (0.30, -0.105),
        (0.40, -0.078), (0.49, -0.092), (0.88, -0.047), (1.11, 0.0),
        (0.88, 0.047), (0.49, 0.092), (0.40, 0.078), (0.30, 0.105),
        (0.19, 0.092)], 0.019, "metal")
    prism_yz(c, "regin_raised_ridge", [(0.20, -0.020), (0.36, -0.022),
        (0.45, -0.010), (0.92, -0.013), (1.03, 0.0), (0.92, 0.013),
        (0.45, 0.010), (0.36, 0.022), (0.20, 0.020)], 0.030, "metal")
    return c


BUILDERS = {
    "seax": seax,
    "bearded_axe": bearded_axe,
    "ash_spear": ash_spear,
    "yew_bow": yew_bow,
    "dvergar_hammer": dvergar_hammer,
    "regin_blade": regin_blade,
}


def export_collection(collection: bpy.types.Collection, filename: str) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(collection.objects))
    path = os.path.join(EXPORT_DIR, filename + ".glb")
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_normals=True,
        export_vertex_color="NAME",
        export_vertex_color_name="ink",
        export_all_vertex_colors=True,
        export_attributes=True,
        export_materials="EXPORT",
    )


def look_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def review_material(name: str, colour: tuple[float, float, float, float]) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = colour
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = colour
    shader.inputs["Roughness"].default_value = 0.95
    return mat


def review_label(
    collection: bpy.types.Collection, text: str, location: tuple[float, float, float], material_ref: bpy.types.Material,
) -> None:
    curve = bpy.data.curves.new("label_" + text, "FONT")
    curve.body = text
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.size = 0.22
    curve.extrude = 0.002
    curve.materials.append(material_ref)
    label = bpy.data.objects.new("label_" + text, curve)
    label.location = location
    # local X -> world Y, local Y -> world Z, local Z -> camera (+X).
    label.rotation_euler = (math.pi / 2.0, 0.0, math.pi / 2.0)
    collection.objects.link(label)


def build_review_sheet(collections: dict[str, bpy.types.Collection]) -> None:
    review = create_collection("REVIEW_ONLY")
    layout = {
        "seax": (-1.65, 1.15), "bearded_axe": (0.0, 1.15), "ash_spear": (1.35, 1.15),
        "yew_bow": (-1.65, -0.90), "dvergar_hammer": (0.0, -0.90), "regin_blade": (1.55, -0.90),
    }
    for name, collection in collections.items():
        for source in collection.objects:
            # Source geometry remains at its true grip-origin location; the
            # review sheet uses linked copies positioned as a contact sheet.
            source.hide_render = True
        y_offset, z_offset = layout[name]
        for source in collection.objects:
            copy = source.copy()
            copy.data = source.data
            copy.name = "review_" + source.name
            copy.location = (0.0, y_offset, z_offset)
            copy.scale = (1.0, 1.0, 1.0)
            copy.hide_render = False
            review.objects.link(copy)

    paper = review_material("review_paper", (0.52, 0.49, 0.43, 1.0))
    ink = review_material("review_ink", (0.035, 0.032, 0.028, 1.0))
    backdrop = box(review, "review_backdrop", -0.32, -0.30, -3.2, 3.3, -2.15, 2.15, "leather")
    backdrop.data.materials[0] = paper
    labels = {
        "seax": "SEAX", "bearded_axe": "BEARDED AXE", "ash_spear": "ASH SPEAR",
        "yew_bow": "YEW BOW", "dvergar_hammer": "DVERGAR HAMMER", "regin_blade": "REGIN'S BLADE",
    }
    label_height = {"seax": 1.75, "bearded_axe": 1.75, "ash_spear": 1.75,
                    "yew_bow": 0.18, "dvergar_hammer": -0.32, "regin_blade": -0.32}
    for name, (y_offset, _z_offset) in layout.items():
        review_label(review, labels[name], (0.04, y_offset, label_height[name]), ink)
    # The review-only silhouette is deliberately a measured 1.80 m reference,
    # so visual proportions cannot drift away from ART-006 §3.1.
    cylinder_between(review, "review_body", (0.0, -2.75, -1.75), (0.0, -2.75, -0.32), 0.14, "metal", 8)
    cylinder_between(review, "review_head", (0.0, -2.75, -0.27), (0.0, -2.75, 0.05), 0.17, "metal", 8)
    cylinder_between(review, "review_arm_l", (0.0, -2.75, -0.55), (0.0, -3.02, -0.99), 0.045, "metal", 6)
    cylinder_between(review, "review_arm_r", (0.0, -2.75, -0.55), (0.0, -2.48, -0.99), 0.045, "metal", 6)
    review_label(review, "1.80 M", (0.04, -2.75, 0.42), ink)
    camera_data = bpy.data.cameras.new("review_camera")
    camera = bpy.data.objects.new("review_camera", camera_data)
    review.objects.link(camera)
    camera.location = (10.0, 0.0, 0.0)
    look_at(camera, (0.0, 0.0, 0.0))
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 4.8
    bpy.context.scene.camera = camera

    light_data = bpy.data.lights.new("review_key", "AREA")
    light_data.energy = 900.0
    light_data.shape = "DISK"
    light_data.size = 7.0
    light = bpy.data.objects.new("review_key", light_data)
    review.objects.link(light)
    light.location = (4.0, -1.5, 4.0)
    look_at(light, (0.0, 0.0, 0.0))
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.render.resolution_x = 1400
    bpy.context.scene.render.resolution_y = 980
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.context.scene.render.filepath = REVIEW_PATH
    bpy.context.scene.world.color = (0.025, 0.025, 0.025)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    bpy.ops.render.render(write_still=True)


def main() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)
    os.makedirs(EXPORT_DIR, exist_ok=True)
    collections = {name: builder() for name, builder in BUILDERS.items()}
    for name, collection in collections.items():
        export_collection(collection, name)
    build_review_sheet(collections)
    print("WEAPONS_DONE", ",".join(BUILDERS.keys()))


if __name__ == "__main__":
    main()
