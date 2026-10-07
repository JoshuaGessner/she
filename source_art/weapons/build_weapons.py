"""Author the six ART-006 weapon assets and their review sheet in Blender.

Weapons live in Blender coordinates with their grip at the origin, a blade or
aiming direction along +Y, and the hand-facing-up direction along +Z. Blender's
glTF exporter converts that to the project's Y-up, -Z-forward convention.
"""

from __future__ import annotations

import math
import os
import sys


import bpy
import bmesh
from mathutils import Vector, Matrix


ROOT = os.path.dirname(os.path.abspath(__file__))
EXPORT_DIR = os.path.normpath(os.path.join(ROOT, "../../game/art/weapons"))
BLEND_PATH = os.path.join(ROOT, "weapons.blend")
REVIEW_PATH = os.path.join(ROOT, "weapons_review_sheet.png")
SCALE_PATH = os.path.join(ROOT, "weapons_scale_sheet.png")

# **How long each weapon is, in metres** — ART-006 §5.2 (ADR-266).
#
# Stated here and asserted below, because the first delivered set was 1.6x to
# 2.2x life size -- a 3.75 m spear, a 2.69 m bow, a 2.15 m sword -- and nothing
# anywhere said how long a weapon was. ART-006 gave the pivot and the facing;
# art_probe.gd deliberately declined to have an opinion about any one asset's
# size, because it was written to bracket the 100x and 39x *import* errors. A
# 2x *authoring* error is what a hand-built mesh actually suffers, and it went
# through both.
#
# The builder refuses to export a weapon that disagrees with its own entry, so
# the error is caught where it is made rather than after it has shipped.
STATED_LENGTH = {
    "seax": 0.50, "bearded_axe": 0.80, "ash_spear": 2.00,
    "yew_bow": 1.65, "dvergar_hammer": 0.85, "regin_blade": 1.25,
    "volr": 0.94,
}
LENGTH_TOLERANCE = 0.08

# ART-006 §2.3: outline R, hatch G, ink/material B.
INK = {
    "wood": (1.0, 0.5, 0.2, 1.0),
    "metal": (1.0, 0.5, 0.4, 1.0),
    "leather": (1.0, 0.5, 0.6, 1.0),
}
MATERIAL_COLOURS = {
    "wood": (0.27, 0.27, 0.27, 1.0),
    "metal": (0.38, 0.38, 0.38, 1.0),
    "leather": (0.14, 0.14, 0.14, 1.0),
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


def loft(collection, name, sections, material_name, sides=10):
    """Joined elliptical rings produce deliberate swelling/taper, not stacked cylinders."""
    verts, faces = [], []
    for y, x_radius, z_radius, z_center in sections:
        verts.extend((math.cos(math.tau*i/sides)*x_radius, y,
                      z_center+math.sin(math.tau*i/sides)*z_radius) for i in range(sides))
    faces.append(tuple(reversed(range(sides))))
    for k in range(len(sections)-1):
        for i in range(sides):
            j=(i+1)%sides
            faces.append((k*sides+i,k*sides+j,(k+1)*sides+j,(k+1)*sides+i))
    faces.append(tuple((len(sections)-1)*sides+i for i in range(sides)))
    return mesh_object(collection,name,verts,faces,material_name)


def blade(collection, name, sections, fuller=False, back=False):
    """Hexagonal forged cross-section: two keen edges and two broad bevels per side.

    With `back`, one edge only: a thick flat spine along `high` and a long
    bevel from it down to the edge at `low`, the wedge a seax is forged to.
    """
    verts, faces = [], []
    for y, low, high, thickness in sections:
        mid=(low+high)*.5
        if back:
            bevel=low+(high-low)*.55
            verts.extend([(-.0004,y,low),(-thickness,y,bevel),(-thickness*.85,y,high),
                          (thickness*.85,y,high),(thickness,y,bevel),(.0004,y,low)])
        elif fuller:
            # A shallow recessed channel between two shoulders is forged form.
            span=(high-low)/2
            profile=[(-.0005,low),(-thickness,mid-span*.38),
                     (-thickness*.55,mid-span*.20),(-thickness*.55,mid+span*.20),
                     (-thickness,mid+span*.38),(-.0005,high)]
            profile += [(-x,z) for x,z in reversed(profile)]
            verts.extend((x,y,z) for x,z in profile)
        else:
            verts.extend([(-.0005,y,low),(-thickness,y,mid),(-.0005,y,high),
                          (.0005,y,high),(thickness,y,mid),(.0005,y,low)])
    n=12 if fuller else 6
    faces.append(tuple(reversed(range(n))))
    for k in range(len(sections)-1):
        for i in range(n):
            j=(i+1)%n
            faces.append((n*k+i,n*k+j,n*(k+1)+j,n*(k+1)+i))
    faces.append(tuple(n*(len(sections)-1)+i for i in range(n)))
    return mesh_object(collection,name,verts,faces,"metal")


def binding(collection, name, y0, y1, radius, turns=8, per_turn=8):
    # A shallow continuous raised seam, not a stack of oversized grip rings.
    verts, faces = [], []
    steps=turns*per_turn
    for i in range(steps+1):
        t=i/steps
        angle=math.tau*turns*t
        for r,dy in ((radius, -.0012),(radius+.0015,0),(radius,.0012)):
            verts.append((r*math.cos(angle), y0+(y1-y0)*t+dy,r*math.sin(angle)))
    for i in range(steps):
        for j in range(2):
            a=3*i+j
            faces.append((a,a+1,a+4,a+3))
    return mesh_object(collection,name,verts,faces,"leather")


def plate(collection, name, outline, depth, inset, material_name):
    """An outline in the blade's plane (z across, y along), forged to `depth`
    either side with its faces chamfered in by `inset` — a pommel or a guard
    plate, cut from a sheet and filed, not lathe-turned."""
    cz=sum(z for z,_ in outline)/len(outline); cy=sum(y for _,y in outline)/len(outline)
    rings=[(-depth,1-inset),(-depth*.45,1.0),(depth*.45,1.0),(depth,1-inset)]
    n=len(outline); verts=[]; faces=[]
    for x,k in rings:
        verts.extend((x,cy+(y-cy)*k,cz+(z-cz)*k) for z,y in outline)
    faces.append(tuple(reversed(range(n))))
    for r in range(3):
        for i in range(n):
            j=(i+1)%n
            faces.append((r*n+i,r*n+j,(r+1)*n+j,(r+1)*n+i))
    faces.append(tuple(3*n+i for i in range(n)))
    return mesh_object(collection,name,verts,faces,material_name)


def seax() -> bpy.types.Collection:
    c = create_collection("seax")
    loft(c,"seax_grip",[(-.092,.014,.018,0),(-.075,.017,.020,0),
         (-.025,.018,.021,0),(.025,.017,.020,0),(.043,.014,.018,0)],"leather",12)
    loft(c,"seax_pommel",[(-.11,.012,.017,0),(-.103,.019,.025,0),
         (-.09,.019,.025,0),(-.084,.014,.018,0)],"metal",10)
    loft(c,"seax_bolster",[(.037,.014,.025,0),(.044,.020,.035,0),
         (.055,.020,.035,0),(.061,.010,.028,0)],"metal",10)
    # The broken-back seax (the Beagnoth seax, the Thames finds): a straight
    # edge, a straight thick back that breaks two-thirds along and runs down in
    # a straight clip to a point low by the edge line. One edge, a wedge.
    blade(c,"seax_broken_back",[(.055,-.020,.016,.0034),(.10,-.025,.017,.0034),
          (.25,-.026,.019,.0031),(.29,-.026,.020,.0029),(.34,-.024,.003,.0022),
          (.37,-.021,-.008,.0014),(.39,-.0165,-.0150,.0005)], back=True)
    binding(c,"seax_wrap",-.079,.029,.018,7)
    return c


def bearded_axe() -> bpy.types.Collection:
    c = create_collection("bearded_axe")
    loft(c,"axe_curved_ash",[(-.15,.016,.022,.004),(-.125,.018,.025,0),
         (-.07,.016,.020,-.006),(.04,.015,.019,-.010),(.24,.017,.022,-.010),
         (.46,.019,.026,0),(.61,.016,.023,0),(.65,.014,.020,0)],"wood",10)
    loft(c,"axe_grip",[(-.125,.018,.025,0),(-.07,.018,.022,-.006),
         (.025,.017,.021,-.010),(.065,.018,.023,-.010)],"leather",10)
    # Cross-sections run out from the wrapped eye into a long curved beard.
    # The skeggøx (Petersen's type B; the Mammen and Thames axes): a thick eye
    # with lugs gripping the haft, a narrow neck, then a thin blade whose top
    # runs straight on from the eye and whose underside sweeps down in a
    # hollow curve to the beard; the edge is convex. Stations run from the poll
    # (+z) to the edge (−z): (z, bottom, top, half-thickness).
    sections=[(.034,.576,.614,.010),(.027,.562,.628,.0175),(.010,.550,.638,.0185),
              (-.010,.550,.638,.0185),(-.027,.562,.628,.015),(-.040,.578,.625,.009),
              (-.060,.572,.626,.0065),(-.082,.558,.629,.0050),(-.104,.530,.634,.0036),
              (-.124,.490,.640,.0026),(-.142,.450,.646,.0017),(-.154,.436,.649,.0010),
              (-.161,.452,.642,.0006),(-.165,.505,.618,.0003)]
    verts,faces=[],[]
    for z,lo,hi,r in sections:
        bevel=min(.008,(hi-lo)*.12)
        verts.extend([(-r*.7,lo,z),(-r,lo+bevel,z),(-r,hi-bevel,z),(-r*.7,hi,z),
                      (r*.7,hi,z),(r,hi-bevel,z),(r,lo+bevel,z),(r*.7,lo,z)])
    faces.append(tuple(reversed(range(8))))
    for k in range(len(sections)-1):
        for i in range(8):
            j=(i+1)%8
            faces.append((8*k+i,8*k+j,8*(k+1)+j,8*(k+1)+i))
    faces.append(tuple(8*(len(sections)-1)+i for i in range(8)))
    mesh_object(c,"axe_forged_beard",verts,faces,"metal")
    return c


def ash_spear() -> bpy.types.Collection:
    c = create_collection("ash_spear")
    loft(c,"spear_ash",[(-.16,.016,.016,0),(.0,.017,.017,0),(.75,.016,.016,0),
         (1.40,.0125,.0125,0),(1.50,.011,.011,0)],"wood",12)
    loft(c,"spear_grip",[(-.07,.018,.018,0),(.0,.019,.019,0),
         (.16,.019,.019,0),(.22,.017,.017,0)],"leather",12)
    # A Viking spearhead is long — a third of a metre of blade on a socket a
    # hand long — and angular: widest low, a ridge down its middle, straight
    # flanks to the point (Petersen's types E and K).
    loft(c,"spear_socket",[(1.39,.0150,.0150,0),(1.40,.0158,.0158,0),
         (1.47,.0130,.0130,0),(1.52,.0090,.0090,0)],"metal",12)
    blade(c,"spear_leaf",[(1.50,-.010,.010,.0075),(1.56,-.030,.030,.0070),
          (1.60,-.040,.040,.0065),(1.65,-.034,.034,.0055),
          (1.74,-.019,.019,.0040),(1.82,-.0005,.0005,.0005)])
    loft(c,"spear_ferrule",[(-.18,.006,.006,0),(-.168,.017,.017,0),
         (-.135,.018,.018,0),(-.12,.016,.016,0)],"metal",10)
    return c


def yew_bow() -> bpy.types.Collection:
    c = create_collection("yew_bow")
    # One continuous stave, progressively thinner toward horn-like nocks.
    verts,faces=[],[]
    segments,sides=32,8
    for i in range(segments+1):
        z=-.825+1.65*i/segments
        t=abs(z)/.825
        y=-.185*t*t + .018*t**4
        width=.018*(1-.70*t)+.002
        depth=.015*(1-.70*t)+.001
        for j in range(sides):
            a=math.tau*j/sides
            verts.append((width*math.cos(a),y+depth*math.sin(a),z))
    faces.append(tuple(reversed(range(sides))))
    for i in range(segments):
        for j in range(sides):
            k=(j+1)%sides
            faces.append((i*sides+j,i*sides+k,(i+1)*sides+k,(i+1)*sides+j))
    faces.append(tuple(segments*sides+j for j in range(sides)))
    mesh_object(c,"bow_continuous_yew_stave",verts,faces,"wood")
    cylinder_between(c,"bow_leather_grip",(0,-.001,-.09),(0,-.001,.09),.021,"leather",12)
    cylinder_between(c,"bow_braced_string",(0,-.174,-.82),(0,-.174,.82),.0009,"leather",6)
    for sign in (-1,1):
        cylinder_between(c,"bow_nock_%s" % sign,(0,-.171,sign*.804),
                         (0,-.167,sign*.822),.007,"metal",8)
    return c


def dvergar_hammer() -> bpy.types.Collection:
    c = create_collection("dvergar_hammer")
    loft(c,"hammer_haft",[(-.18,.018,.023,0),(-.15,.020,.026,0),
         (-.10,.016,.020,0),(.02,.017,.021,-.009),(.20,.018,.024,-.012),
         (.45,.022,.029,0),(.655,.018,.024,0)],"wood",12)
    loft(c,"hammer_grip",[(-.15,.021,.027,0),(-.11,.019,.023,0),
         (.02,.020,.024,-.009),(.075,.020,.025,-.010)],"leather",12)
    # Octagonal cross-sections, square striking poll and narrowing opposing peen.
    sections=[(-.19,.048,.065),(-.181,.060,.076),(-.145,.060,.076),
              (-.123,.047,.058),(.07,.045,.055),(.13,.032,.044),(.20,.012,.024)]
    verts,faces=[],[]
    for z,rx,ry in sections:
        for x,y in [(-rx*.7,-ry),(-rx,-ry*.7),(-rx,ry*.7),(-rx*.7,ry),
                    (rx*.7,ry),(rx,ry*.7),(rx,-ry*.7),(rx*.7,-ry)]:
            verts.append((x,.594+y,z))
    faces.append(tuple(reversed(range(8))))
    for k in range(len(sections)-1):
        for i in range(8):
            j=(i+1)%8
            faces.append((8*k+i,8*k+j,8*(k+1)+j,8*(k+1)+i))
    faces.append(tuple(8*(len(sections)-1)+i for i in range(8)))
    mesh_object(c,"hammer_forged_head",verts,faces,"metal")
    loft(c,"hammer_lower_collar",[(.465,.025,.032,0),(.478,.027,.034,0),
         (.515,.026,.033,0)],"metal",10)
    return c


def regin_blade() -> bpy.types.Collection:
    c = create_collection("regin_blade")
    loft(c,"regin_grip",[(-.088,.015,.020,0),(-.055,.018,.023,0),
         (.025,.019,.024,0),(.070,.015,.020,0)],"leather",12)
    # A Viking hilt, not a knight's: a short thick guard and an upper guard
    # boxing in a grip one hand wide, and above it a lobed pommel — Petersen's
    # lobed types, older in the eye than anything with a cross. Its guard
    # curves toward the blade, as the latest of them do (type Z).
    obj=loft(c,"regin_curved_guard",[(-.068,.010,.007,.010),(-.058,.014,.009,.006),
         (-.030,.016,.011,.001),(0,.017,.012,0),(.030,.016,.011,.001),
         (.058,.014,.009,.006),(.068,.010,.007,.010)],"metal",8)
    for v in obj.data.vertices:
        y,z=v.co.y,v.co.z
        v.co.y=.079+z
        v.co.z=y
    box(c,"regin_upper_guard",-.012,.012,-.100,-.086,-.044,.044,"metal")
    lobes=[]
    for i in range(21):
        a=math.pi*i/20
        r=.034*(.80+.20*abs(math.sin(5*a)))
        lobes.append((r*math.cos(a)*1.18,-.099-r*math.sin(a)*.95))
    plate(c,"regin_lobed_pommel",lobes,.011,.18,"metal")
    blade(c,"regin_forged_blade",[(.088,-.031,.031,.0065),(.30,-.030,.030,.006),
          (.60,-.028,.028,.0055),(.85,-.025,.025,.0048),(1.00,-.019,.019,.0038),
          (1.07,-.010,.010,.0024),(1.11,-.0005,.0005,.0005)], fuller=True)
    binding(c,"regin_wrap",-.084,.066,.019,7,6)
    return c


def volr() -> bpy.types.Collection:
    """The seeress's staff (ADR-379): *völva* is "staff-bearer".

    After the iron staffs from the women's graves at Fyrkat (grave 4) and
    Birka (Bj 660, Bj 845): an iron rod about 0.9 m long, a cage of bowed
    rods swelling below the head, collared top and bottom, and a knob to
    finish it. One-handed. It strikes as a short iron club, because that is
    what an iron rod in a frightened hand is.
    """
    c = create_collection("volr")
    loft(c, "volr_rod", [(-.10, .0085, .0085, 0), (.0, .0090, .0090, 0),
         (.40, .0085, .0085, 0), (.79, .0080, .0080, 0)], "metal", 8)
    loft(c, "volr_grip", [(-.06, .0125, .0125, 0), (-.04, .0135, .0135, 0),
         (.12, .0135, .0135, 0), (.14, .0120, .0120, 0)], "leather", 8)
    loft(c, "volr_butt", [(-.13, .004, .004, 0), (-.122, .011, .011, 0),
         (-.10, .012, .012, 0), (-.09, .009, .009, 0)], "metal", 10)
    # The cage: six rods bowed out from a lower collar to an upper one, one
    # mesh — each rod a square tube following its bow.
    low, high, bulge, thick = .56, .74, .046, .0032
    verts, faces = [], []
    for k in range(6):
        angle = math.tau * k / 6.0
        out = Vector((math.cos(angle), 0.0, math.sin(angle)))
        side = Vector((-math.sin(angle), 0.0, math.cos(angle)))
        first = len(verts)
        steps = 7
        for step in range(steps):
            s = step / (steps - 1)
            r = .010 + (bulge - .010) * math.sin(math.pi * s)
            centre = out * r + Vector((0.0, low + (high - low) * s, 0.0))
            for corner in ((1, 1), (1, -1), (-1, -1), (-1, 1)):
                verts.append(tuple(centre + out * thick * corner[0]
                                   + side * thick * corner[1]))
        for step in range(steps - 1):
            a, b = first + step * 4, first + (step + 1) * 4
            for i in range(4):
                j = (i + 1) % 4
                faces.append((a + i, a + j, b + j, b + i))
        faces.append((first + 3, first + 2, first + 1, first))
        last = first + (steps - 1) * 4
        faces.append((last, last + 1, last + 2, last + 3))
    mesh_object(c, "volr_cage", verts, faces, "metal")
    loft(c, "volr_collar_low", [(.548, .0105, .0105, 0), (.556, .0150, .0150, 0),
         (.566, .0150, .0150, 0), (.574, .0105, .0105, 0)], "metal", 10)
    loft(c, "volr_collar_high", [(.726, .0105, .0105, 0), (.734, .0150, .0150, 0),
         (.744, .0150, .0150, 0), (.752, .0105, .0105, 0)], "metal", 10)
    loft(c, "volr_knob", [(.778, .008, .008, 0), (.784, .016, .016, 0),
         (.796, .019, .019, 0), (.808, .015, .015, 0), (.814, .004, .004, 0)],
         "metal", 10)
    return c


BUILDERS = {
    "seax": seax,
    "bearded_axe": bearded_axe,
    "ash_spear": ash_spear,
    "yew_bow": yew_bow,
    "dvergar_hammer": dvergar_hammer,
    "regin_blade": regin_blade,
    "volr": volr,
}


def export_collection(collection: bpy.types.Collection, filename: str) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(collection.objects))
    for obj in collection.objects:
        bm=bmesh.new(); bm.from_mesh(obj.data)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(obj.data); bm.free()
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
    curve.size = 0.13
    curve.extrude = 0.002
    curve.materials.append(material_ref)
    label = bpy.data.objects.new("label_" + text, curve)
    label.location = location
    # local X -> world Y, local Y -> world Z, local Z -> camera (+X).
    label.rotation_euler = (math.pi / 2.0, 0.0, math.pi / 2.0)
    collection.objects.link(label)


def build_scale_sheet(collections: dict[str, bpy.types.Collection]) -> None:
    """Every weapon at true scale beside a measured 1.80 m figure (ADR-266).

    The review sheet enlarges each weapon to fill its own panel. That is the
    right way to inspect **form**, and it destroys every clue about **size**:
    a 0.5 m knife and a 2 m spear draw exactly the same. So this is a second
    sheet rather than a change to that one -- the two answer different
    questions and neither can answer both.

    The captions carry the numbers, and a caption is not the same instrument.
    It is written beside the geometry it describes, from the same source, so a
    weapon modelled at twice life size gets a label confidently stating the
    length it was supposed to be. **The figure can disagree**: 1.80 m is a fact
    about people, fixed by ART-006 §3.1, and a weapon built twice too long
    stands twice as tall as it. That is the whole point of a reference -- it is
    independent of the subject.
    """
    sheet = create_collection("SCALE_ONLY")
    paper = review_material("scale_paper", (0.48, 0.48, 0.48, 1.0))
    ink = review_material("scale_ink", (0.025, 0.025, 0.025, 1.0))
    backdrop = box(sheet, "scale_backdrop", -.48, -.46, -4.0, 4.0, -1.6, 1.5,
                   "leather")
    backdrop.data.materials[0] = paper
    base = -1.0
    # Shortest to longest, so the eye reads the set as a scale in itself.
    order = ["seax", "bearded_axe", "dvergar_hammer", "regin_blade",
             "yew_bow", "ash_spear"]
    for i, name in enumerate(order):
        # The bow already stands along its own Z; everything else is authored
        # along +Y and is stood upright, exactly as the review sheet does it.
        turn = (Matrix.Identity(4) if name == "yew_bow"
                else Matrix.Rotation(math.pi / 2.0, 4, "X"))
        points = [turn @ v.co
                  for o in collections[name].objects for v in o.data.vertices]
        y = -1.9 + i * 1.05
        lift = base - min(p.z for p in points)
        for source in collections[name].objects:
            source.hide_render = True
            copy = source.copy()
            copy.data = source.data.copy()
            copy.name = "scale_" + source.name
            for v in copy.data.vertices:
                v.co = (turn @ v.co) + Vector((0.0, y, lift))
            copy.hide_render = False
            sheet.objects.link(copy)
        review_label(sheet, "%.2f M" % STATED_LENGTH[name],
                     (.05, y, base - 0.22), ink)

    # 1.80 m exactly, foot to crown: ART-006 §3.1's body. Jointed rather than
    # a single post, because the reference only works if it reads as a person
    # at a glance -- a column beside a spear is two columns.
    figure = -3.1
    # Proportioned off ART-006 §3.1's 1.80 m body: hip at half height,
    # shoulders at 1.47, crown at 1.80 exactly -- which is the only dimension
    # here that has to be right.
    for side in (-0.09, 0.09):
        cylinder_between(sheet, "scale_leg_%+.2f" % side,
                         (0.0, figure + side, base),
                         (0.0, figure + side, base + 0.94), 0.068, "metal", 8)
    cylinder_between(sheet, "scale_body", (0.0, figure, base + 0.86),
                     (0.0, figure, base + 1.52), 0.155, "metal", 8)
    cylinder_between(sheet, "scale_head", (0.0, figure, base + 1.53),
                     (0.0, figure, base + 1.80), 0.105, "metal", 8)
    for side in (-1.0, 1.0):
        cylinder_between(sheet, "scale_arm_%+.0f" % side,
                         (0.0, figure + side * 0.17, base + 1.47),
                         (0.0, figure + side * 0.21, base + 0.78),
                         0.048, "metal", 6)
    review_label(sheet, "1.80 M", (.05, figure, base - 0.22), ink)

    camera_data = bpy.data.cameras.new("scale_camera")
    camera = bpy.data.objects.new("scale_camera", camera_data)
    sheet.objects.link(camera)
    camera.location = (10.0, 0.0, -0.10)
    look_at(camera, (0.0, 0.0, -0.10))
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 8.2
    bpy.context.scene.camera = camera

    light_data = bpy.data.lights.new("scale_key", "AREA")
    light_data.energy = 900.0
    light_data.shape = "DISK"
    light_data.size = 7.0
    light = bpy.data.objects.new("scale_key", light_data)
    sheet.objects.link(light)
    light.location = (4.0, -1.5, 4.0)
    look_at(light, (0.0, 0.0, -0.10))
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.render.resolution_x = 2400
    bpy.context.scene.render.resolution_y = 800
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.context.scene.render.filepath = SCALE_PATH
    bpy.context.scene.world.color = (0.025, 0.025, 0.025)
    bpy.ops.render.render(write_still=True)

    # Off the stage before the review sheet builds its own, or both sets of
    # copies would stand in the same frame.
    for obj in list(sheet.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(sheet)


def build_review_sheet(collections: dict[str, bpy.types.Collection]) -> None:
    review = create_collection("REVIEW_ONLY")
    layout = {
        "seax": (-2.4, 1.2), "bearded_axe": (-0.8, 1.2), "ash_spear": (0.8, 1.2),
        "yew_bow": (2.4, 1.2), "dvergar_hammer": (-1.6, -1.2), "regin_blade": (0, -1.2),
        "volr": (1.6, -1.2),
    }
    # Composed from STATED_LENGTH rather than typed out, so the caption and
    # the assertion cannot disagree. It is still a caption and still not a
    # reference -- weapons_scale_sheet.png is where size is actually reviewed.
    names = {
        "seax": "SEAX", "bearded_axe": "BEARDED AXE",
        "ash_spear": "ASH SPEAR", "yew_bow": "YEW BOW",
        "dvergar_hammer": "DVERGAR HAMMER", "regin_blade": "REGIN'S BLADE",
        "volr": "VOLR",
    }
    labels = {key: "%s / %.2f M" % (text, STATED_LENGTH[key])
              for key, text in names.items()}
    paper = review_material("review_paper", (0.48, 0.48, 0.48, 1.0))
    ink = review_material("review_ink", (0.025, 0.025, 0.025, 1.0))
    backdrop = box(review,"review_backdrop",-.48,-.46,-3.3,3.3,-2.55,2.55,"leather")
    backdrop.data.materials[0] = paper
    for name, collection in collections.items():
        coords=[v.co for o in collection.objects for v in o.data.vertices]
        axis=2 if name=="yew_bow" else 1
        lo=min(v[axis] for v in coords); hi=max(v[axis] for v in coords)
        scale=1.85/(hi-lo)
        transform=Matrix.Rotation(.16,4,'Z') @ Matrix.Rotation(-.14,4,'Y')
        if name!="yew_bow": transform=transform @ Matrix.Rotation(math.pi/2,4,'X')
        center=Vector((0,0,(lo+hi)/2)) if axis==2 else Vector((0,(lo+hi)/2,0))
        y,z=layout[name]
        for source in collection.objects:
            source.hide_render=True
            copy=source.copy(); copy.data=source.data.copy()
            copy.name="review_"+source.name
            for v in copy.data.vertices:
                v.co=transform @ ((v.co-center)*scale)+Vector((0,y,z))
            copy.hide_render=False
            review.objects.link(copy)
        review_label(review,labels[name],(.05,y,z-1.08),ink)
    camera_data = bpy.data.cameras.new("review_camera")
    camera = bpy.data.objects.new("review_camera", camera_data)
    review.objects.link(camera)
    camera.location = (10.0, 0.0, 0.0)
    look_at(camera, (0.0, 0.0, 0.0))
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 6.9
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
    bpy.context.scene.render.resolution_x = 2400
    bpy.context.scene.render.resolution_y = 1850
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.context.scene.render.filepath = REVIEW_PATH
    bpy.context.scene.world.color = (0.025, 0.025, 0.025)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    bpy.ops.render.render(write_still=True)


def main() -> None:
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)
    os.makedirs(EXPORT_DIR, exist_ok=True)
    collections = {name: builder() for name, builder in BUILDERS.items()}

    # **Measured before anything is written** (ADR-266). The first version of
    # this asserted after the export loop, which fails the build and leaves the
    # wrong weapon sitting in game/art/weapons/ for the next importer to find.
    # A gate downstream of the thing it guards is a report, not a gate.
    wrong = []
    for name, collection in collections.items():
        points = [o.matrix_world @ v.co for o in collection.objects for v in o.data.vertices]
        stated = STATED_LENGTH[name]
        longest = max(max(p[i] for p in points) - min(p[i] for p in points)
                      for i in (0, 1, 2))
        if abs(longest - stated) > stated * LENGTH_TOLERANCE:
            wrong.append("%s is %.3f m and ART-006 §5.2 says %.2f m"
                         % (name, longest, stated))
    if wrong:
        raise SystemExit("ART-006 §5.2 length: " + "; ".join(wrong))

    # `-- --only=a,b` exports only those; the sheets and the measurements still
    # cover every weapon, so a new one never rewrites the others' files.
    only = [arg.split("=", 1)[1].split(",") for arg in sys.argv
            if arg.startswith("--only=")]
    for name, collection in collections.items():
        if only and name not in only[0]:
            continue
        export_collection(collection, name)
    # Regeneration must update the size record alongside the actual exports.
    lines = ["# Weapon delivery measurements", "",
             "Generated by `build_weapons.py` in Blender. Dimensions are metres; "
             "the grip is the origin and glTF is Y-up, −Z forward.", "",
             "| Asset | Triangles | Bounds (X × Y × Z m) |",
             "|---|---:|---:|"]
    for name, collection in collections.items():
        points = [o.matrix_world @ v.co for o in collection.objects for v in o.data.vertices]
        sizes = [max(p[i] for p in points) - min(p[i] for p in points) for i in (0, 2, 1)]
        triangles = sum(len(p.vertices) - 2 for o in collection.objects for p in o.data.polygons)
        lines.append(f"| `{name}.glb` | {triangles} | " + " × ".join(f"{v:.3f}" for v in sizes) + " |")
    lines += ["", "All surfaces carry COLOR_0: R=1, G=0.5; B=0.2 timber, "
              "0.4 metal, or 0.6 leather. No UVs or textures. All meshes have "
              "hard normals and identity transforms.", "",
              "Two sheets, because they answer different questions. "
              "`weapons_review_sheet.png` enlarges each panel independently, "
              "for **form** — and therefore says nothing about size. "
              "`weapons_scale_sheet.png` stands all six at true scale beside a "
              "measured 1.80 m figure, for **size** (ADR-266). Every length is "
              "asserted against `ART-006` §5.2 at export; the build fails "
              "rather than delivering a weapon that is not the length it "
              "claims.", ""]
    with open(os.path.join(ROOT, "weapons_measurements.md"), "w") as output:
        output.write("\n".join(lines))
    build_scale_sheet(collections)
    build_review_sheet(collections)
    print("WEAPONS_DONE", ",".join(BUILDERS.keys()))


if __name__ == "__main__":
    main()
