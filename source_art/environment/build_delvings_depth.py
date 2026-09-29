"""ART-006 §3.3 depth-surface variants for the established Delvings kit.

The generator already owns the actual depth morphology: `FloorBuilder` cuts
corners and drifts ceilings from the same 2 m, solid-cell layout.  These
exports are deliberately the same panel and flag footprints as Band 1 so a
depth-aware shelf selection can use them without replacing that contract.

Run with Blender --background --python source_art/environment/build_delvings_depth.py.
"""
import bpy
import json
import math
from mathutils import Vector
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game/art/environment"
SRC = Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0
bpy.context.scene.unit_settings.system = "METRIC"

MATS = {}
for name, tone, ink in [
    ("stone", 0.38, 0.0),
    ("pale_stone", 0.415, 0.0),
    ("dark_stone", 0.31, 0.0),
    ("seam", 0.17, 0.0),
    # The break must survive the ink pass as a readable change of plane, not
    # just as another dark line between courses.
    ("fractured_rock", 0.52, 0.0),
]:
    material = bpy.data.materials.new(name)
    material.diffuse_color = (tone, tone, tone, 1.0)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = material.diffuse_color
    shader.inputs["Roughness"].default_value = 0.92
    MATS[name] = (material, ink)


def finish(obj, name, material="stone", bevel=0.0):
    """Apply transforms and author the mandatory flat ink vertex attribute."""
    obj.name = name
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if bevel:
        modifier = obj.modifiers.new("cut_chamfer", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    mat, ink = MATS[material]
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = False
    for uv in list(obj.data.uv_layers):
        obj.data.uv_layers.remove(uv)
    color = obj.data.color_attributes.new("ink", "FLOAT_COLOR", "CORNER")
    for corner in color.data:
        corner.color = (1.0, 0.5, ink, 1.0)
    return obj


def box(name, center, size, material="stone", bevel=0.012):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.object
    obj.scale = size
    return finish(obj, name, material, bevel)


def mesh_box(name, verts, faces, material="stone"):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return finish(obj, name, material)


def proxy(name, center, size):
    obj = box(name + "-colonly", center, size, "dark_stone", 0.0)
    obj.hide_render = True
    obj.display_type = "WIRE"
    return obj


def new_asset(name):
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    bpy.context.view_layer.active_layer_collection = \
        bpy.context.view_layer.layer_collection.children[name]
    return collection


def seam_wall(width, height, retreat, name):
    """Course a worked panel around a deliberate dark, stepped seam.

    The seam is a revealed failure line, rather than random displaced bricks:
    Retreat is still recognisably coursed; Cause opens its courses farther.
    All detail remains inside the 2.0 x 0.3 m panel envelope.
    """
    box("masonry_core", (0.0, 0.02, height * 0.5),
        (width, 0.24, height), "dark_stone", 0.0)
    # Broad courses are deliberate at depth and keep the tallest panel below
    # ART-004's 3,000-triangle architecture ceiling.
    # A failure plane is legible as a few large events, not as dozens of
    # small, equally important notches.  The earlier course density made the
    # break read as a dark zip at game distance.
    rows = max(3, round(height / (0.90 if retreat else 1.15)))
    row_height = height / rows
    seam_x = -0.09 if retreat else -0.15
    # The seam has a deliberate, non-repeating path. Retreat remains a built
    # wall split by a narrow failure; Cause is the irregular mineral void that
    # work has broken into. This is morphology, not jitter on every brick.
    offsets = [-0.04, 0.035, -0.075, 0.060, -0.020, 0.090, -0.055,
               0.025, -0.090, 0.050, -0.030]
    widths = [0.080, 0.130, 0.075, 0.110, 0.090, 0.145, 0.080,
              0.120] if retreat else \
        [0.58, 0.82, 0.44, 0.70, 0.62, 0.90, 0.50, 0.76]
    profile: list[tuple[float, float, float]] = []
    for row in range(rows + 1):
        centre = seam_x + offsets[row % len(offsets)]
        half = widths[row % len(widths)] * 0.5
        profile.append((centre - half, centre + half, row * row_height))
    for row in range(rows):
        bottom = row * row_height
        # Use the midpoint of each jagged span for the courses, while the
        # exposed seam below carries the slanted boundary across row joins.
        left_end = (profile[row][0] + profile[row + 1][0]) * 0.5
        right_start = (profile[row][1] + profile[row + 1][1]) * 0.5
        stagger = 0.18 if row % 2 else -0.12
        cuts = [-width * 0.5, min(-0.42 + stagger, left_end), left_end]
        cuts += [right_start, max(0.42 + stagger, right_start), width * 0.5]
        for start, end in zip(cuts, cuts[1:]):
            if end - start < 0.05:
                continue
            side_gap = 0.008 if start > -width * 0.5 else 0.0
            end_gap = 0.008 if end < width * 0.5 else 0.0
            tone = "pale_stone" if (row + int(start * 10)) % 5 == 0 else "stone"
            box("course_%02d" % row,
                ((start + end + side_gap - end_gap) * 0.5, 0.0,
                 bottom + row_height * 0.5),
                (end - start - side_gap - end_gap, 0.3, row_height - 0.010),
                tone, min(0.032, row_height * 0.07))
    # A single irregular recessed plane makes the exposed break read as rock,
    # rather than a stack of identical dark rectangles. Its edges zig-zag
    # across courses and remain inside the 0.3 m panel envelope.
    outline = [(left, z) for left, _right, z in profile] \
        + [(right, z) for _left, right, z in reversed(profile)]
    # Retreat's narrow dark line sits just behind the cut face. Cause leaves
    # room in front of its core for lit, sloped mineral facets.
    seam_front = -0.149 if retreat else -0.132
    seam_back = -0.085 if retreat else -0.108
    front = [(x, seam_front, z) for x, z in outline]
    back = [(x, seam_back, z) for x, z in outline]
    count = len(outline)
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count)
              for i in range(count)]
    mesh_box("revealed_seam", front + back, faces, "seam")
    if not retreat:
        # Cause exposes a small number of broad, angled mineral faces. Group
        # two courses per face so the wall reads as rock opened behind the
        # working, rather than the repeated black zipper the former one-row
        # facets produced.  Each plane faces the player-facing (-Y) side and
        # lies between the recessed crack and the coursed surface, so it takes
        # light without protruding past the established 30 cm wall envelope.
        for first in range(0, rows, 2):
            last = min(first + 2, rows)
            left_a, right_a, z_a = profile[first]
            left_b, right_b, z_b = profile[last]
            use_left = (first // 2) % 2 == 0
            edge_a = left_a if use_left else right_a
            edge_b = left_b if use_left else right_b
            other_a = right_a if use_left else left_a
            other_b = right_b if use_left else left_b
            # Carry the lit mineral plane across most of the fault, leaving a
            # crooked, narrow dark depth at its far edge.
            inner_a = edge_a + (other_a - edge_a) * 0.72
            inner_b = edge_b + (other_b - edge_b) * 0.72
            vertices = [(edge_a, -0.149, z_a), (edge_b, -0.149, z_b),
                        (inner_b, -0.105, z_b), (inner_a, -0.105, z_a)]
            face = [(0, 3, 2, 1)] if use_left else [(0, 1, 2, 3)]
            mesh_box("exposed_rock", vertices, face, "fractured_rock")
    # A surviving cap is the useful contrast: the building is failing into the
    # seam, not dissolving into decorative rubble.
    box("bearing_cap", (0.0, 0.0, height - 0.075),
        (width, 0.3, 0.15), "pale_stone", 0.018)
    proxy(name, (0.0, 0.0, height * 0.5), (width, 0.3, height))


def stepped_floor(name, cause):
    """A 2 m walkable flag panel with 8 mm of visible worn relief."""
    # `DelvingsKit` sinks every floor mesh by FLAG_DEEP below a surface that
    # stands PROUD of the collision slab.  Anything at 5 cm or below is buried
    # by that unchanged render core, so the relief lives in the visible 5.2–6
    # cm band rather than pretending a lower step can be seen or walked on.
    # The buried bed keeps the 0–6 cm module footprint the kit places; the
    # visible relief above it is what survives the runtime's render core.
    box("floor_bed", (0.0, 0.0, 0.002), (2.0, 2.0, 0.004), "dark_stone", 0.0)
    box("wear_bed", (0.0, 0.0, 0.052), (2.0, 2.0, 0.004), "dark_stone", 0.0)
    rows = 4 if cause else 3
    rise = 0.008
    for row in range(rows):
        y0 = -1.0 + row * 2.0 / rows
        y1 = -1.0 + (row + 1) * 2.0 / rows
        # The highest flag remains at the established 6 cm module top. The
        # lower courses are shallow visible wear, with the actual grade owned
        # by FloorBuilder's collision geometry.
        top = 0.052 + row * rise / (rows - 1)
        # Alternate joints; a failed floor has direction, it is not a random
        # carpet of tiny blocks.
        splits = [-1.0, 0.0, 1.0] if row % 2 == 0 else [-1.0, -0.36, 0.42, 1.0]
        for start, end in zip(splits, splits[1:]):
            inset_l = 0.008 if start > -1.0 else 0.0
            inset_r = 0.008 if end < 1.0 else 0.0
            box("step_flag", ((start + end + inset_l - inset_r) * 0.5,
                               (y0 + y1) * 0.5, top - 0.004),
                (end - start - inset_l - inset_r, y1 - y0 - 0.010, 0.008),
                "pale_stone" if (row + int(start * 3)) % 3 == 0 else "stone",
                0.007)
        if row > 0:
            box("step_face", (0.0, y0 + 0.006,
                top - rise / (rows - 1) * 0.5),
                (1.98, 0.012, rise / (rows - 1)), "dark_stone", 0.001)
    # The proxy documents the intended solid for standalone use. Runtime kit
    # cladding deliberately continues to use FloorBuilder's longer slab.
    proxy(name, (0.0, 0.0, 0.03), (2.0, 2.0, 0.06))


def sloped_floor(name):
    """Cause's 8 mm visual fall across a cell, above the unchanged slab."""
    slope = 0.008
    base = 0.052
    box("floor_bed", (0.0, 0.0, 0.002), (2.0, 2.0, 0.004), "dark_stone", 0.0)
    verts = [
        (-1.0, -1.0, base - 0.001), (1.0, -1.0, base - 0.001),
        (1.0, 1.0, base + slope - 0.001), (-1.0, 1.0, base + slope - 0.001),
        (-1.0, -1.0, base - 0.005), (1.0, -1.0, base - 0.005),
        (1.0, 1.0, base + slope - 0.005), (-1.0, 1.0, base + slope - 0.005),
    ]
    faces = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1),
             (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    mesh_box("slope_bed", verts, faces, "dark_stone")
    # Three large slabs make the incline legible while retaining a continuous,
    # intentionally shallow worn grade. The physical grade stays with
    # FloorBuilder, whose collision and navigation contract this art does not
    # replace.
    for lane in range(3):
        x0 = -1.0 + lane * 2.0 / 3.0
        x1 = -1.0 + (lane + 1) * 2.0 / 3.0
        inset = 0.008
        vs = [(x0 + inset, -1.0, base),
              (x1 - inset, -1.0, base),
              (x1 - inset, 1.0, base + slope),
              (x0 + inset, 1.0, base + slope),
              (x0 + inset, -1.0, base - 0.004),
              (x1 - inset, -1.0, base - 0.004),
              (x1 - inset, 1.0, base + slope - 0.004),
              (x0 + inset, 1.0, base + slope - 0.004)]
        mesh_box("slope_flag", vs, faces,
                 "pale_stone" if lane == 1 else "stone")
    proxy(name, (0.0, 0.0, base + slope * 0.5), (2.0, 2.0, 0.06))


ASSETS = []


def export(name, collection):
    visible = [obj for obj in collection.objects if not obj.hide_render]
    materials = sorted({obj.data.materials[0] for obj in visible}, key=lambda item: item.name)
    # Joining each material separately keeps COLOR_0 on Blender 5.2's exporter.
    for material in materials:
        # `join()` removes every object except its active one, so this must be
        # resolved from the collection each pass rather than from `visible`.
        group = [obj for obj in collection.objects if not obj.hide_render
                 and obj.data.materials[0] == material]
        if len(group) == 1:
            group[0].name = name + "_" + material.name
            continue
        bpy.ops.object.select_all(action="DESELECT")
        for obj in group:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = group[0]
        bpy.ops.object.join()
        bpy.context.object.name = name + "_" + material.name
    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection.objects:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUT / (name + ".glb")), export_format="GLB",
        use_selection=True, export_yup=True, export_texcoords=False,
        export_normals=True, export_materials="EXPORT", export_attributes=True,
        export_vertex_color="NAME", export_vertex_color_name="ink",
        export_all_vertex_colors=True, export_cameras=False, export_lights=False,
    )
    visible = [obj for obj in collection.objects if not obj.hide_render]
    points = [obj.matrix_world @ Vector(point) for obj in visible for point in obj.bound_box]
    bounds = [[min(point[i] for point in points), max(point[i] for point in points)]
              for i in range(3)]
    triangles = sum(len(poly.vertices) - 2 for obj in visible for poly in obj.data.polygons)
    assert triangles <= 3000, (name, triangles)
    ASSETS.append({"name": name, "triangles": triangles, "bounds_blender": bounds})


for band, retreat in [("retreat", True), ("cause", False)]:
    for height in [2.6, 4.0, 7.0]:
        asset = "delvings_%s_wall_2x%02d" % (band, round(height * 10))
        collection = new_asset(asset)
        seam_wall(2.0, height, retreat, asset)
        export(asset, collection)
    floor_asset = "delvings_%s_floor_step_2x2" % band if retreat \
        else "delvings_cause_floor_slope_2x2"
    collection = new_asset(floor_asset)
    if retreat:
        stepped_floor(floor_asset, False)
    else:
        sloped_floor(floor_asset)
    export(floor_asset, collection)

(SRC / "delvings_depth_measurements.json").write_text(json.dumps(ASSETS, indent=2) + "\n")

# One comparison board, with all assets at their real dimensions and a 1.8 m
# reference beside the wall families. It intentionally uses no final ink pass.
review = bpy.data.collections.new("depth_review")
bpy.context.scene.collection.children.link(review)
for index, entry in enumerate(ASSETS):
    source = bpy.data.collections[entry["name"]]
    offset = Vector(((index % 4) * 4.4, (index // 4) * 8.8, 0.0))
    for obj in source.objects:
        if obj.hide_render:
            continue
        copy = obj.copy()
        copy.data = obj.data.copy()
        review.objects.link(copy)
        copy.location += offset
    bpy.context.view_layer.active_layer_collection = \
        bpy.context.view_layer.layer_collection.children[review.name]
    bpy.ops.object.text_add(location=offset + Vector((-1.0, -2.0, 0.02)))
    label = bpy.context.object
    label.data.body = entry["name"].replace("delvings_", "")
    label.data.size = 0.20
    label.data.materials.append(MATS["seam"][0])
    # The review board owns the visible copies. The authored source collection
    # must disappear only after copying: hiding its objects first carries that
    # flag into the copies, while leaving it visible stacks every asset at the
    # origin and turns the first panel into ghost geometry.
    source.hide_render = True

box("review_ground", (6.5, 5.0, -0.13), (18.0, 23.0, 0.20), "pale_stone", 0.0)
box("reference_body", (15.2, 14.0, 0.90), (0.45, 0.25, 1.30), "seam", 0.05)
bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=4, radius=0.15,
                                     location=(15.2, 14.0, 1.65))
finish(bpy.context.object, "reference_head", "seam")

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.world.use_nodes = True
background = scene.world.node_tree.nodes["Background"]
background.inputs["Color"].default_value = (0.16, 0.16, 0.16, 1.0)
background.inputs["Strength"].default_value = 0.45
for location, energy, size in [((5.0, -9.0, 18.0), 1800, 10.0),
                               ((-8.0, -4.0, 10.0), 1000, 8.0),
                               ((12.0, 8.0, 14.0), 1200, 7.0)]:
    bpy.ops.object.light_add(type="AREA", location=location)
    light = bpy.context.object
    light.data.energy = energy
    light.data.shape = "DISK"
    light.data.size = size
    light.rotation_euler = (Vector((6.5, 7.0, 2.0)) - light.location).to_track_quat("-Z", "Y").to_euler()
bpy.ops.object.camera_add(location=(20.0, -28.0, 15.0))
camera = bpy.context.object
camera.rotation_euler = (Vector((6.5, 7.0, 2.2)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 27.0
scene.camera = camera
scene.render.resolution_x = 1800
scene.render.resolution_y = 1450
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(SRC / "delvings_depth_review.png")
bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "delvings_depth_variants.blend"))
print("DELIVERED", json.dumps(ASSETS))
