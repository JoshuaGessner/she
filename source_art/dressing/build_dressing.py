#!/usr/bin/env python3
"""Build the ART-006 §5.3 abandoned Delvings dressing kit in Blender 5.2.

Each prop has a clear base-centre origin, a deliberately simple collision box,
flat material families, and the required `ink` vertex attribute.  Run with:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python \
    source_art/dressing/build_dressing.py
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game" / "art" / "props"
SRC = Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)

# ART-006 §2.3: B is a material identifier, not an arbitrary colour choice.
PALETTE = {
    "stone": ((0.30, 0.32, 0.31, 1.0), 0.0),
    # The Delvings palette is ink, paper, and grey: old timber is weathered
    # nearly neutral, never a warm game-asset brown.
    "timber": ((0.25, 0.245, 0.225, 1.0), 0.2),
    "metal": ((0.19, 0.21, 0.20, 1.0), 0.4),
    "rope": ((0.41, 0.36, 0.27, 1.0), 0.6),
}
MATS = {}
LOW_OUTLINE = 0.32


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for mesh in list(bpy.data.meshes):
        bpy.data.meshes.remove(mesh)
    MATS.clear()


def material(kind):
    if kind not in MATS:
        mat = bpy.data.materials.new("flat_" + kind)
        mat.diffuse_color = PALETTE[kind][0]
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = PALETTE[kind][0]
        bsdf.inputs["Roughness"].default_value = 0.88
        bsdf.inputs["Metallic"].default_value = 0.72 if kind == "metal" else 0.0
        MATS[kind] = mat
    return MATS[kind]


def finish(obj, name, kind, outline=LOW_OUTLINE):
    """Flat-shade a mesh and author the engine-facing vertex-colour layer."""
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(material(kind))
    for face in obj.data.polygons:
        face.use_smooth = False
    attr = obj.data.color_attributes.get("ink")
    if attr is None:
        attr = obj.data.color_attributes.new("ink", "FLOAT_COLOR", "CORNER")
    for corner in attr.data:
        corner.color = (outline, 0.5, PALETTE[kind][1], 1.0)
    return obj


def apply_mesh_transform(obj):
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.select_set(False)


def cube(name, loc, size, kind, bevel=0.0, outline=LOW_OUTLINE):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        modifier = obj.modifiers.new("honest_cut_edge", "BEVEL")
        modifier.width, modifier.segments = bevel, 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return finish(obj, name, kind, outline)


def cylinder(name, loc, radius, depth, kind, vertices=10, rotation=None,
             radius_top=None, outline=LOW_OUTLINE):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices, radius1=radius,
        radius2=radius if radius_top is None else radius_top, depth=depth,
        location=loc, rotation=rotation or (0.0, 0.0, 0.0))
    obj = finish(bpy.context.object, name, kind, outline)
    apply_mesh_transform(obj)
    return obj


def torus(name, loc, major, minor, kind, major_segments=12, minor_segments=4,
          rotation=None, outline=LOW_OUTLINE):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major, minor_radius=minor, major_segments=major_segments,
        minor_segments=minor_segments, location=loc,
        rotation=rotation or (0.0, 0.0, 0.0))
    return finish(bpy.context.object, name, kind, outline)


def beam_between(name, a, b, width, depth, kind="timber", outline=LOW_OUTLINE):
    """A square-sawn beam, aligned as a real timber rather than a cylinder."""
    a, b = Vector(a), Vector(b)
    delta = b - a
    obj = cube(name, (a + b) / 2.0, (width, depth, delta.length), kind, .012, outline)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(delta.normalized())
    apply_mesh_transform(obj)
    return obj


def pipe(name, points, radius, kind="rope", outline=LOW_OUTLINE):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth = radius
    curve.bevel_resolution = 0
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, co in zip(spline.points, points):
        point.co = (co[0], co[1], co[2], 1.0)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return finish(bpy.context.object, name, kind, outline)


def irregular_rock(name, loc, size, outline=LOW_OUTLINE):
    """Fixed hand-shaped spoil, avoiding procedural noise or round boulders."""
    x, y, z = size[0] / 2.0, size[1] / 2.0, size[2]
    # Six uneven feet and four offset crowns create fracture planes, rather
    # than cube-like rubble.  The vertices are fixed, never randomised.
    verts = [(-x,-.52*y,0), (-.28*x,-y,0), (.82*x,-.62*y,0),
             (x,.22*y,0), (.35*x,y,0), (-.78*x,.68*y,0),
             (-.45*x,-.28*y,.92*z), (.38*x,-.38*y,.74*z),
             (.57*x,.42*y,.58*z), (-.31*x,.53*y,.80*z)]
    faces = [(0,1,6), (1,2,7,6), (2,3,8,7), (3,4,8), (4,5,9,8),
             (5,0,6,9), (6,7,8), (6,8,9), (0,5,4,3,2,1)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = loc
    return finish(obj, name, "stone", outline)


def collision_box(bounds):
    min_x, max_x, min_y, max_y, min_z, max_z = bounds
    obj = cube("collision-colonly", ((min_x+max_x)/2, (min_y+max_y)/2,
                                      (min_z+max_z)/2),
               (max_x-min_x, max_y-min_y, max_z-min_z), "stone", 0.0, 0.0)
    obj.hide_render = True
    obj.display_type = "WIRE"
    return obj


def ore_cart():
    # A compact 1.4 m gauge cart: four obvious wheels, timber frame, and a
    # flared open ore tub.  The missing front slat makes abandonment legible.
    for x in (-.62, .62):
        for y in (-.38, .38):
            cylinder("cart_wheel", (x, y, .20), .22, .09, "metal", 10,
                     rotation=(0, math.pi/2, 0))
    for y in (-.38, .38):
        beam_between("cart_axle", (-.72,y,.20), (.72,y,.20), .06, .06, "metal")
    cube("cart_chassis", (0,0,.42), (1.35,.84,.12), "timber", .018)
    for x in (-.58,.58):
        beam_between("cart_side_rail", (x,-.46,.44), (x,.46,.44), .08,.08)
    # Broad, outward-leaning planked hopper sides give this a loose-ore volume
    # at a glance.  Thin iron seams keep the individual planks readable.
    for x, angle in ((-.64,-.20),(.64,.20)):
        side = cube("cart_hopper_planked_side", (x,0,.79), (.07,.92,.62), "timber", .01)
        side.rotation_euler[1] = angle; apply_mesh_transform(side)
        for z in (.60,.79,.98):
            seam = beam_between("cart_hopper_plank_seam", (x,-.46,z), (x,.46,z), .026,.020, "metal")
            seam.rotation_euler[1] = angle; apply_mesh_transform(seam)
    back = cube("cart_hopper_back", (0,.43,.78), (1.34,.07,.60), "timber", .01)
    back.rotation_euler[0] = -.18; apply_mesh_transform(back)
    for x in (-.38,0,.38):
        beam_between("cart_back_plank_seam", (x,.43,.51), (x,.43,1.05), .025,.02,"metal")
    beam_between("cart_back_rim", (-.71,.49,1.06), (.71,.49,1.06), .07,.07)
    for y in (-.34,.02,.30):
        beam_between("cart_floor_slats", (-.52,y,.54), (.52,y,.54), .07,.045)
    for x in (-.64,.64):
        cylinder("cart_rim_iron", (x,.44,1.06), .055, .12, "metal", 8,
                 rotation=(0,math.pi/2,0))
    collision_box((-.78,.78,-.52,.52,0,1.16))


def fallen_masonry():
    # Courses and a split lintel are actual stacked construction, not scatter.
    # Lintel end is a genuine angled fracture, not a rectangular cut with wear.
    verts=[(-.78,-.19,0),(-.78,.19,0),(.61,-.19,0),(.72,.19,0),
           (-.78,-.19,.34),(-.78,.19,.34),(.72,-.19,.21),(.61,.19,.29)]
    faces=[(0,2,6,4),(2,3,7,6),(3,1,5,7),(1,0,4,5),(4,6,7,5),(0,1,3,2)]
    mesh=bpy.data.meshes.new("fallen_lintel"); mesh.from_pydata(verts,[],faces); mesh.update()
    lintel=bpy.data.objects.new("fallen_lintel",mesh); bpy.context.collection.objects.link(lintel)
    lintel.location=(0,.02,0); finish(lintel,"fallen_lintel","stone")
    obj = cube("fallen_course_long", (-.17,-.38,.34), (1.25,.36,.28), "stone", .018)
    obj.rotation_euler[2] = math.radians(-12); apply_mesh_transform(obj)
    obj = cube("fallen_course_short", (.52,.30,.18), (.64,.44,.32), "stone", .018)
    obj.rotation_euler[2] = math.radians(17); apply_mesh_transform(obj)
    obj = cube("fallen_capstone", (-.52,.31,.53), (.78,.34,.24), "stone", .022)
    obj.rotation_euler[1] = math.radians(14); apply_mesh_transform(obj)
    irregular_rock("masonry_broken_corner", (.42,-.25,0), (.50,.42,.27))
    collision_box((-.88,.88,-.64,.58,0,.72))


def broken_bracing():
    # A collapsed A-frame: sawn timber ends and iron straps establish purpose.
    def snapped_beam(name, a, b, width, depth):
        a,b=Vector(a),Vector(b); length=(b-a).length
        w,d=width/2,depth/2
        verts=[(-w,-d,0),(w,-d,0),(w,d,0),(-w,d,0),
               (-w,-d,length), (w,-d,length-.14), (w,d,length-.05), (-w,d,length-.19)]
        faces=[(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7),(0,3,2,1)]
        mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
        obj=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(obj); obj.location=a
        obj.rotation_mode="QUATERNION"; obj.rotation_quaternion=Vector((0,0,1)).rotation_difference((b-a).normalized())
        finish(obj,name,"timber"); apply_mesh_transform(obj)
    snapped_beam("brace_fallen_main", (-.88,-.22,.08), (.78,.34,.18), .15,.13)
    snapped_beam("brace_fallen_cross", (-.70,.48,.10), (.72,-.42,.15), .13,.12)
    snapped_beam("brace_split_upright", (-.22,-.08,.10), (.28,-.02,.92), .14,.12)
    cube("brace_broken_foot", (.43,.11,.09), (.34,.22,.18), "timber", .01)
    for x,y,z in [(-.40,-.02,.15),(.02,.07,.18),(.33,-.12,.41)]:
        cube("brace_iron_strap", (x,y,z), (.09,.20,.06), "metal", .005)
    collision_box((-.98,.90,-.56,.58,0,1.02))


def rope_coil():
    # Nested, slightly offset coils and a loose tail read as rope rather than a ring.
    for i, (r,x,y) in enumerate(((.43,0,0),(.37,.015,-.01),(.31,-.01,.015),(.24,.02,.02))):
        torus("rope_coil_%02d" % i, (x,y,.045+i*.030), r, .038, "rope", 14, 4)
    pipe("rope_loose_tail", [(.43,.02,.05),(.64,.18,.05),(.70,.45,.045),
                              (.55,.61,.042),(.34,.55,.04)], .038)
    collision_box((-.49,.76,-.50,.68,0,.20))


def rusted_fittings():
    # Fallen mine pulley: a deeply legible wheel, U bracket, hook, and short chain.
    cube("pulley_mount_plate", (0,0,.06), (1.05,.30,.12), "metal", .012)
    for x in (-.42,.42):
        cylinder("pulley_rivet", (x,-.16,.13), .045, .055, "metal", 8,
                 rotation=(math.pi/2,0,0))
    beam_between("pulley_upright_l", (-.34,0,.10), (-.34,0,.74), .09,.09, "metal")
    beam_between("pulley_upright_r", (.34,0,.10), (.34,0,.74), .09,.09, "metal")
    cylinder("pulley_wheel", (0,0,.54), .27, .12, "metal", 12,
             rotation=(math.pi/2,0,0))
    cylinder("pulley_axle", (0,0,.54), .055, .84, "metal", 8,
             rotation=(math.pi/2,0,0))
    for i in range(3):
        torus("chain_link", ((i-1)*.12,.02,.18+i*.11), .075,.018,"metal",8,3,
              rotation=(math.pi/2,0,0) if i%2 else (0,math.pi/2,0))
    pipe("pulley_hook", [(.12,.02,.50),(.12,.02,.35),(.23,.02,.27),
                          (.29,.02,.35),(.22,.02,.40)], .035, "metal")
    collision_box((-.56,.56,-.22,.22,0,.86))


def guttered_candles():
    # Four uneven spent candles in an iron catch dish; no flame means abandoned.
    cylinder("candle_dish", (0,0,.045), .36, .09, "metal", 12)
    cylinder("candle_rim", (0,0,.10), .34, .04, "metal", 12, radius_top=.32)
    for i,(x,y,h,r) in enumerate(((-.13,-.08,.32,.075),(.13,-.05,.48,.080),
                                  (-.02,.14,.23,.065),(.10,.13,.36,.070))):
        cylinder("spent_candle_%02d"%i, (x,y,.12+h/2), r, h, "rope", 9,
                 radius_top=r*.92)
        cylinder("black_wick_%02d"%i, (x,y,.13+h), .012, .045, "metal", 6)
    # A fallen stub on the tray breaks the altar-like symmetry.
    cylinder("fallen_candle_stub", (-.20,.14,.16), .055, .22, "rope", 8,
             rotation=(0,math.pi/2.7,0))
    collision_box((-.40,.40,-.40,.40,0,.66))


def spoil_heap():
    # Fixed, faceted rock forms with a discarded shovel make this excavation spoil.
    # Chunks overlap into an excavation mound, with a large fractured core and
    # smaller settled pieces.  This reads as spoil at room distance, not tiles.
    for i, (x,y,z,sx,sy,sz) in enumerate(((0,0,0,.92,.78,.29),(-.28,-.16,.16,.58,.50,.28),
                                           (.28,-.15,.13,.54,.46,.25),(-.10,.27,.18,.60,.48,.30),
                                           (.36,.23,.20,.38,.35,.20),(-.42,.20,.12,.36,.34,.22))):
        irregular_rock("spoil_chunk_%02d"%i, (x,y,z), (sx,sy,sz))
    beam_between("discarded_shovel_handle", (-.57,.38,.07), (.44,.57,.14), .055,.045)
    obj = cube("discarded_shovel_blade", (.51,.59,.105), (.30,.22,.035), "metal", .01)
    obj.rotation_euler[2] = math.radians(20); apply_mesh_transform(obj)
    collision_box((-.72,.72,-.53,.72,0,.48))


ASSETS = [
    ("dressing_ore_cart", ore_cart),
    ("dressing_fallen_masonry", fallen_masonry),
    ("dressing_broken_bracing", broken_bracing),
    ("dressing_rope_coil", rope_coil),
    ("dressing_rusted_fittings", rusted_fittings),
    ("dressing_guttered_candles", guttered_candles),
    ("dressing_spoil_heap", spoil_heap),
]


def mesh_stats():
    visible = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.hide_render]
    points = [o.matrix_world @ Vector(corner) for o in visible for corner in o.bound_box]
    bounds = [[round(min(p[i] for p in points), 3), round(max(p[i] for p in points), 3)]
              for i in range(3)]
    triangles = sum(len(poly.vertices)-2 for obj in visible for poly in obj.data.polygons)
    return {"triangles": triangles, "bounds_blender_xyz_m": bounds}


def export_asset(name):
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            apply_mesh_transform(obj)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(OUT / (name + ".glb")), export_format="GLB", use_selection=True,
        export_yup=True, export_texcoords=False, export_normals=True,
        export_materials="EXPORT", export_attributes=True,
        export_all_vertex_colors=True, export_vertex_color="NAME",
        export_vertex_color_name="ink", export_cameras=False, export_lights=False)


def add_reference_figure(loc):
    # Simple 1.80 m review scale figure, excluded from every shipped export.
    cube("review_reference_body", (loc[0],loc[1],.93), (.34,.22,1.25), "metal", .02, 1.0)
    cylinder("review_reference_head", (loc[0],loc[1],1.66), .14, .25, "metal", 8, outline=1.0)
    for x in (-.10,.10):
        cube("review_reference_leg", (loc[0]+x,loc[1],.30), (.11,.14,.60), "metal", .01,1.0)


def review_label(text, loc):
    bpy.ops.object.text_add(location=loc)
    label=bpy.context.object
    label.data.body=text.replace("_", " ")
    label.data.align_x="CENTER"; label.data.align_y="CENTER"
    label.data.size=.18; label.data.extrude=.002
    label.data.materials.append(material("metal"))


def review_sheet():
    clear_scene()
    for index, (_name, builder) in enumerate(ASSETS):
        before = set(bpy.context.scene.objects)
        builder()
        dx, dy = (index % 4) * 2.7, (index // 4) * 3.0
        # Only the asset just made moves; preceding assets stay in their cell.
        for obj in set(bpy.context.scene.objects) - before:
            obj.location.x += dx
            obj.location.y += dy
        cube("review_tile", (dx,dy,-.06), (2.25,2.25,.12), "stone", 0, 0.0)
        review_label(_name, (dx,dy-1.02,.015))
    add_reference_figure((8.0,4.3))
    review_label("1.80 m", (8.0,3.75,.015))
    bpy.ops.object.light_add(type="AREA", location=(4,-4,11))
    bpy.context.object.data.energy, bpy.context.object.data.shape = 1200, "DISK"
    bpy.context.object.data.size = 6
    bpy.ops.object.light_add(type="AREA", location=(9,9,6))
    bpy.context.object.data.energy, bpy.context.object.data.size = 700, 4
    bpy.ops.object.camera_add(location=(7.5,-9.5,13.5))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((4.0,1.5,.35))-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type = "ORTHO"; camera.data.ortho_scale = 11.0
    scene = bpy.context.scene
    scene.camera = camera
    # Blender 5 exposes the EEVEE-next renderer under this stable enum name.
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = 1800, 1250
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(SRC / "dressing_review.png")
    bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "dressing_kit.blend"))


def main():
    bpy.context.scene.unit_settings.system = "METRIC"
    delivered = []
    for name, builder in ASSETS:
        clear_scene()
        builder()
        stats = mesh_stats()
        assert stats["triangles"] <= 3000, (name, stats["triangles"])
        export_asset(name)
        bpy.ops.wm.save_as_mainfile(filepath=str(SRC / (name + ".blend")))
        delivered.append({"name": name, **stats})
    (SRC / "measurements.json").write_text(json.dumps(delivered, indent=2) + "\n")
    review_sheet()
    print("DRESSING_DELIVERED", json.dumps(delivered))


if __name__ == "__main__":
    main()
