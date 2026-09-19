#!/usr/bin/env python3
"""Build ART-006 §5.2 item props.

Run with Blender 4.x: Blender.app/Contents/MacOS/Blender --background --python
source_art/items/build_items.py.  Each asset is built from readable, flat-shaded
forms, saved as its own editable .blend, and exported with its simple collision.
"""
import bpy
import math
import os
from mathutils import Vector, Matrix

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
OUT = os.path.join(ROOT, "game", "art", "props")
SRC = os.path.join(ROOT, "source_art", "items")
RENDER = os.path.join(SRC, "item_review_sheet.png")

# ART-006 §2.3: B is the fixed engine material ID, never an arbitrary tint.
PALETTE = {
    "stone": ((0.27, 0.29, 0.28, 1.0), 0.0),
    "timber": ((0.24, 0.20, 0.15, 1.0), 0.2),
    "metal": ((0.18, 0.20, 0.20, 1.0), 0.4),
    "cloth": ((0.56, 0.52, 0.43, 1.0), 0.6),
    "organic": ((0.30, 0.26, 0.20, 1.0), 0.8),
    "gold": ((0.72, 0.43, 0.10, 1.0), 1.0),
}
MATS = {}

def reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        if datablocks is not bpy.data.materials:
            continue

def material(kind):
    if kind in MATS:
        return MATS[kind]
    color, ink_id = PALETTE[kind]
    m = bpy.data.materials.new("mat_" + kind)
    m.diffuse_color = color
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = 0.82
    bsdf.inputs["Metallic"].default_value = 0.72 if kind in ("metal", "gold") else 0.0
    MATS[kind] = m
    return m

def vertex_colors(obj, kind):
    """Give every rendered or collision mesh the required RGBA vertex layer."""
    mesh = obj.data
    attr = mesh.color_attributes.get("ink") or mesh.color_attributes.new("ink", "FLOAT_COLOR", "CORNER")
    ink_id = PALETTE[kind][1]
    for element in attr.data:
        element.color = (1.0, 0.5, ink_id, 1.0)

def finish(obj, name, kind):
    obj.name = name
    if obj.type == "MESH":
        obj.data.materials.append(material(kind))
        vertex_colors(obj, kind)
        for poly in obj.data.polygons:
            poly.use_smooth = False
    return obj

def cube(name, loc, scale, kind, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = bpy.context.object
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("small honest edge chamfer", "BEVEL")
        mod.width, mod.segments = bevel, 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(obj, name, kind)

def cyl(name, loc, radius, depth, kind, verts=10, rot=None, r2=None):
    # Blender creates cones along Z; item coordinates intentionally follow the
    # exported game convention, Y-up and -Z forward.
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=(radius if r2 is None else r2), depth=depth, location=loc, rotation=rot if rot is not None else (math.pi/2, 0, 0))
    return finish(bpy.context.object, name, kind)

def ico(name, loc, radius, kind, scale=(1, 1, 1), subdiv=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=radius, location=loc)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, kind)

def torus(name, loc, major, minor, kind, major_segments=10, minor_segments=4, rot=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=major_segments, minor_segments=minor_segments, location=loc, rotation=rot if rot is not None else (math.pi/2, 0, 0))
    return finish(bpy.context.object, name, kind)

def rod(name, a, b, radius, kind, verts=8):
    a, b = Vector(a), Vector(b)
    delta = b - a
    obj = cyl(name, (a + b) / 2, radius, delta.length, kind, verts)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(delta.normalized())
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=False)
    return obj

def arc(name, points, radius, kind):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth, curve.resolution_v = radius, 0
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for p, co in zip(spline.points, points):
        p.co = (co[0], co[1], co[2], 1.0)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return finish(bpy.context.object, name, kind)

def collision(bounds):
    # Collision is deliberately primitive: ART-006 forbids render-mesh colliders.
    minx, maxx, miny, maxy, minz, maxz = bounds
    return cube("collision-colonly", ((minx+maxx)/2, (miny+maxy)/2, (minz+maxz)/2), (maxx-minx, maxy-miny, maxz-minz), "stone")

def coin():
    # 9.5 kg reads as an intentionally dense mound of small struck coins,
    # never seven dinner-plate tokens.  The low-sided pieces stay legible.
    for i in range(42):
        ring = i // 9
        angle = i * 2.39996
        radius = .025 * ring + .008 * (i % 3)
        x, z = radius * math.cos(angle), radius * math.sin(angle)
        y = .003 + .006 * (i % 7) + .002 * ring
        cyl("coin_%02d" % i, (x,y,z), .022, .006, "gold", 10)
    collision((-.16,.16,0,.075,-.16,.16))

def chest():
    cube("chest_body", (0,.23,0), (.72,.42,.45), "timber", .025)
    # A visibly rounded, banded lid instead of a plain crate.
    cyl("chest_lid", (0,.46,0), .24, .72, "timber", 10, rot=(0,math.pi/2,0))
    cube("lid_cut", (0,.33,0), (.78,.30,.55), "timber")
    for x in (-.28,.28): rod("iron_band", (x,.05,-.25),(x,.63,-.25),.022,"metal")
    cube("lock_plate", (0,.26,-.236), (.12,.15,.025), "gold", .01)
    collision((-.39,.39,0,.70,-.29,.29))

def plate():
    cyl("altar_plate", (0,.045,0), .38, .09, "gold", 12)
    torus("plate_rim", (0,.105,0), .31, .040, "gold", 12, 4)
    cyl("plate_well", (0,.087,0), .25, .018, "gold", 12)
    rod("plate_inlay_a",(-.20,.125,-.20),(.20,.125,.20),.012,"metal")
    rod("plate_inlay_b",(-.20,.125,.20),(.20,.125,-.20),.012,"metal")
    collision((-.4,.4,0,.14,-.4,.4))

def torc():
    # Open spiral neck-ring, packed as a low, readable crescent.
    pts=[]
    for i in range(15):
        a=math.radians(35+i*20)
        pts.append((.105*math.cos(a), .045+.028*math.sin(a), .105*math.sin(a)))
    arc("torc_ring", pts, .014, "gold")
    for p in (pts[0],pts[-1]): ico("torc_terminal",p,.030,"gold",(1,.65,1),1)
    collision((-.14,.14,0,.10,-.14,.14))

def bead():
    ico("gilt_bead",(0,.018,0),.020,"gold",(1,.8,1),2)
    collision((-.023,.023,0,.036,-.023,.023))

def gemstone():
    ico("raw_gemstone",(0,.018,0),.017,"stone",(.8,1.1,.72),1)
    collision((-.020,.020,0,.038,-.020,.020))

def byrnie():
    # Broad shoulders, a neck hole, sleeve stubs and a front split establish
    # clothing before the mail courses are added.
    cyl("byrnie_tunic",(0,.38,0),.29,.70,"metal",8,r2=.36)
    torus("byrnie_neck",(0,.74,0),.135,.030,"metal",8,3)
    for x in (-.34,.34):
        cyl("byrnie_sleeve",(x,.55,0),.12,.25,"metal",8,rot=(0,0,math.radians(12 if x < 0 else -12)),r2=.14)
    rod("byrnie_split",(0,.05,-.285),(0,.27,-.285),.015,"cloth")
    # Real ring courses give mail its own form rather than a noisy texture.
    for row in range(4):
        for col in range(5):
            x=(col-2)*.115 + (row%2)*.055
            torus("mail_ring",(x,.22+row*.13,-.285),.040,.009,"metal",7,3,rot=(math.pi/2,0,0))
    collision((-.42,.42,0,.90,-.32,.32))

def helm():
    ico("helm_bowl",(0,.33,0),.31,"metal",(1,1,.92),2)
    cube("helm_cut",(0,.14,0),(.7,.30,.7),"metal")
    for rot in (0,math.pi/2): torus("helm_band",(0,.37,0),.28,.018,"metal",10,3,rot=(rot,0,0))
    rod("nose_guard",(0,.17,-.29),(0,.43,-.29),.035,"metal")
    collision((-.33,.33,0,.64,-.33,.33))

def bracers():
    for x in (-.14,.14):
        cyl("bracer",(x,.16,0),.11,.30,"metal",8,rot=(0,math.pi/2,0),r2=.095)
        cube("bracer_cut",(x,.16,.11),(.34,.28,.10),"metal")
    collision((-.32,.32,0,.32,-.15,.15))

def shield():
    cyl("shield_face",(0,.35,0),.35,.07,"timber",12,rot=(0,0,0))
    cyl("shield_boss",(0,.35,-.05),.09,.11,"metal",10,rot=(0,0,0))
    for a in range(0,360,90):
        r=math.radians(a); rod("shield_rim",(.30*math.cos(r),.35+.30*math.sin(r),-.045),(.30*math.cos(r+.10),.35+.30*math.sin(r+.10),-.045),.025,"metal")
    collision((-.38,.38,0,.72,-.10,.10))

def satchel():
    cube("satchel_body",(0,.25,0),(.46,.38,.18),"organic",.06)
    cube("satchel_flap",(0,.39,-.10),(.44,.20,.035),"organic",.02)
    arc("satchel_strap",[(-.20,.30,.08),(-.28,.70,.08),(0,.85,.08),(.28,.70,.08),(.20,.30,.08)],.022,"cloth")
    cube("satchel_clasp",(0,.34,-.125),(.07,.07,.025),"metal",.01)
    collision((-.28,.28,0,.88,-.15,.15))

def frame():
    for x in (-.25,.25): rod("frame_upright",(x,.03,0),(x,1.02,0),.035,"timber")
    for y in (.10,.48,.92): rod("frame_cross",(-.28,y,0),(.28,y,0),.035,"timber")
    cube("frame_bed",(0,.52,.055),(.40,.60,.12),"organic",.04)
    for x in (-.30,.30): arc("frame_strap",[(x,.10,-.04),(x,.55,-.17),(x,.98,-.04)],.018,"cloth")
    collision((-.34,.34,0,1.06,-.20,.18))

def lantern():
    # A field lantern: framed scraped-horn panels, bright ember, vented cap,
    # shutter and an overbuilt handle.  Each has a distinct silhouette.
    cyl("lantern_horn",(0,.33,0),.175,.40,"cloth",8,r2=.135)
    cyl("lantern_cap",(0,.55,0),.155,.060,"metal",8)
    cyl("lantern_foot",(0,.105,0),.20,.06,"metal",8)
    for x in (-.13,.13):
        for z in (-.13,.13): rod("lantern_corner_rib",(x,.13,z),(x,.56,z),.018,"metal")
    for z in (-.142,.142): rod("lantern_cross_rail",(-.14,.43,z),(.14,.43,z),.016,"metal")
    for x in (-.08,0,.08): rod("lantern_vent",(x,.59,0),(x,.67,0),.012,"metal")
    cube("lantern_shutter",(0,.34,-.180),(.12,.22,.020),"metal",.008)
    cube("lantern_glow",(0,.32,-.193),(.068,.12,.014),"gold",.004)
    pts=[(-.13,.56,0),(-.18,.78,0),(0,.92,0),(.18,.78,0),(.13,.56,0)]
    arc("lantern_handle",pts,.025,"metal")
    ico("lantern_ember",(0,.31,0),.065,"gold",(1,.7,1),1)
    collision((-.22,.22,0,.96,-.22,.22))

def waystone():
    cyl("waystone",(0,.30,0),.16,.60,"stone",6,r2=.11)
    # A single carved departure-mark, geometry not texture.
    rod("waystone_mark_a",(-.055,.28,-.115),(0,.39,-.115),.012,"metal")
    rod("waystone_mark_b",(0,.39,-.115),(.055,.28,-.115),.012,"metal")
    rod("waystone_mark_c",(0,.39,-.115),(0,.18,-.115),.012,"metal")
    collision((-.18,.18,0,.62,-.18,.18))

def ember():
    ico("ember_core",(0,.32,0),.32,"gold",(.85,1.0,.85),2)
    for a in range(0,360,60):
        r=math.radians(a); ico("ember_lobe",(.23*math.cos(r),.18,.23*math.sin(r)),.16,"gold",(1,.8,1),1)
    collision((-.35,.35,0,.55,-.35,.35))

def hush():
    cyl("hush_rune",(0,.04,0),.16,.07,"timber",8)
    # Raised stave makes the breakable rune legible in world and inventory.
    rod("hush_stave",(-.08,.085,-.02),(.08,.085,-.02),.012,"metal")
    rod("hush_notch_a",(-.02,.085,-.02),(0,.085,.06),.012,"metal")
    rod("hush_notch_b",(.03,.085,-.02),(.07,.085,.05),.012,"metal")
    collision((-.17,.17,0,.10,-.17,.17))

def linen():
    cyl("linen_roll",(0,.105,0),.12,.33,"cloth",10,rot=(0,math.pi/2,0))
    torus("linen_tie",(0,.105,0),.125,.014,"cloth",10,3,rot=(0,math.pi/2,0))
    collision((-.20,.20,0,.23,-.14,.14))

def bog_iron():
    for i,(x,y,z,s) in enumerate([(-.08,.10,0,.13),(.09,.12,.02,.15),(0,.24,-.03,.12)]): ico("bog_iron_lump",(x,y,z),s,"metal",(1.2,.8,1),1)
    collision((-.23,.23,0,.34,-.20,.20))

def pelt():
    # A deliberately cut hide outline: ears/head, shoulders, paws and tapering
    # tail make Ótr's Pelt read as a relic rather than a round stone.
    outline=[(-.08,-.48),(-.20,-.39),(-.38,-.22),(-.47,.05),(-.37,.23),(-.48,.36),(-.18,.28),(0,.62),(.18,.28),(.48,.36),(.37,.23),(.47,.05),(.38,-.22),(.20,-.39),(.08,-.48)]
    verts=[(x,.035,z) for x,z in outline]+[(x,.115,z) for x,z in outline]
    n=len(outline); faces=[tuple(range(n)),tuple(range(n,2*n))]
    for i in range(n): faces.append((i,(i+1)%n,(i+1)%n+n,i+n))
    mesh=bpy.data.meshes.new("pelt_hide_mesh"); mesh.from_pydata(verts,[],faces); mesh.update()
    obj=bpy.data.objects.new("pelt_hide",mesh); bpy.context.collection.objects.link(obj); finish(obj,"pelt_hide","organic")
    ico("pelt_head",(0,.12,-.43),.10,"organic",(.75,.45,1),1)
    for x in (-.37,.37): ico("pelt_paw",(x,.06,.25),.07,"organic",(1,.35,1),1)
    rod("pelt_tail",(0,.08,.42),(0,.07,.66),.040,"organic",6)
    collision((-.50,.50,0,.18,-.55,.70))

ASSETS = [
    ("hoard_coin", coin), ("coin_chest", chest), ("altar_plate", plate), ("gilded_torc", torc), ("gilt_bead", bead), ("raw_gemstone", gemstone),
    ("mail_byrnie", byrnie), ("spangen_helm", helm), ("iron_bracers", bracers), ("round_shield", shield), ("hide_satchel", satchel), ("pack_frame", frame), ("horn_lantern", lantern),
    ("waystone", waystone), ("ember", ember), ("hush_rune", hush), ("linen_binding", linen), ("bog_iron", bog_iron), ("otr_pelt", pelt),
]

def export_asset(name, builder):
    reset(); MATS.clear(); builder()
    # **Make the geometry real before measuring it.**  `visual_base` below
    # reads `obj.data.vertices`, which is the *unevaluated* mesh: it does not
    # contain an unapplied BEVEL modifier (`cube(bevel=...)`) and does not
    # exist at all for a curve with a `bevel_depth` (the bindings and cords).
    # The export applies both — `export_apply=True` — so eight props were
    # snapped against geometry that is not the geometry that ships, and came
    # out pivoted 2 to 7.5 cm off their own base.  Caught by `art_probe`,
    # which is what it is for.
    #
    # Converting first makes the measurement and the export read the same
    # vertices, and it fixes every future asset rather than these eight.
    bpy.ops.object.select_all(action="SELECT")
    exportable = [o for o in bpy.context.scene.objects
                  if o.type in {"MESH", "CURVE", "SURFACE", "FONT", "META"}]
    if exportable:
        bpy.context.view_layer.objects.active = exportable[0]
        bpy.ops.object.convert(target="MESH")
    # Bake every local placement into vertices.  Godot's imported GLB scene
    # treats a lone mesh node as its root, so leaving an object's y location
    # as a node transform makes a correct-looking Blender prop fail its
    # base-centre pivot contract in the engine.
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            obj.data.transform(obj.matrix_world)
            obj.matrix_world = Matrix.Identity(4)
            obj.data.update()
    # The render mesh, not its deliberately generous collision hull, defines
    # where a collectible visually meets the floor.  Snap that visible base to
    # zero after all primitive rotations and bevels have become real geometry.
    render_meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and "colonly" not in obj.name]
    visual_base = min(vertex.co.y for obj in render_meshes for vertex in obj.data.vertices)
    for obj in render_meshes:
        obj.data.transform(Matrix.Translation((0.0, -visual_base, 0.0)))
        obj.data.update()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SRC, name + ".blend"))
    bpy.ops.object.select_all(action="SELECT")
    # Blender 5 exports this unused layer only when named explicitly.  Do not
    # attach it to material alpha: that creates a white COLOR_0 and moves ink
    # data to COLOR_1, which violates the renderer's fixed-channel contract.
    # Builders use the target coordinate contract directly: Y-up and -Z forward.
    # Do not apply Blender's native Z-up conversion a second time.
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), export_format="GLB", export_materials="EXPORT", export_yup=False, export_apply=True, export_cameras=False, export_lights=False, export_texcoords=False, export_vertex_color="NAME", export_vertex_color_name="ink", export_all_vertex_colors=True)

def review_sheet():
    reset(); MATS.clear()
    cols=5
    for i,(name,builder) in enumerate(ASSETS):
        before = set(bpy.context.scene.objects)
        builder()
        dx=(i%cols)*1.75; dz=(i//cols)*1.75
        # Only place this asset.  Moving the whole scene here compounded every
        # prior column position and made the first sheet impossible to review.
        for obj in set(bpy.context.scene.objects) - before:
            obj.location.x += dx; obj.location.z += dz
            if "colonly" in obj.name:
                obj.hide_render = True
        # flat floor tile makes the base-centre contact visible.
        cube("review_tile",(dx,-.035,dz), (1.42,.06,1.42),"stone")
        bpy.ops.object.text_add(location=(dx-.58,.003,dz-.60), rotation=(math.pi/2,0,math.pi))
        label=bpy.context.object; label.name="review_label_"+name; label.data.body=name; label.data.align_x="LEFT"; label.data.size=.12; label.data.materials.append(material("cloth"))
    bpy.ops.object.light_add(type="AREA", location=(4,8,-5)); bpy.context.object.data.energy=2200; bpy.context.object.data.shape="DISK"; bpy.context.object.data.size=7
    bpy.ops.object.light_add(type="AREA", location=(-3,4,7)); bpy.context.object.data.energy=1400; bpy.context.object.data.size=5
    bpy.ops.object.camera_add(location=(4.0,10.5,-12.5), rotation=(math.radians(38),0,0))
    cam=bpy.context.object; bpy.context.scene.camera=cam
    # Aim at contact-sheet centre.
    target=Vector((3.5,0,2.8)); cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type="ORTHO"; cam.data.ortho_scale=11.0
    scene=bpy.context.scene; scene.render.engine="BLENDER_EEVEE"; scene.render.resolution_x=1400; scene.render.resolution_y=1100; scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"; scene.render.filepath=RENDER
    scene.world.color=(0.10,0.10,0.085); bpy.ops.render.render(write_still=True)

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True); os.makedirs(SRC, exist_ok=True)
    for asset in ASSETS: export_asset(*asset)
    review_sheet()
    print("Built %d ART-006 item assets" % len(ASSETS))
