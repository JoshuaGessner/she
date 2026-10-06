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
    "rope": ((0.48, 0.465, 0.435, 1.0), 0.6),
    "wax": ((0.73, 0.71, 0.65, 1.0), 0.6),
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


def cylinder(name, loc, radius, depth, kind, vertices=20, rotation=None,
             radius_top=None, outline=LOW_OUTLINE):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices, radius1=radius,
        radius2=radius if radius_top is None else radius_top, depth=depth,
        location=loc, rotation=rotation or (0.0, 0.0, 0.0))
    obj = finish(bpy.context.object, name, kind, outline)
    apply_mesh_transform(obj)
    return obj


def torus(name, loc, major, minor, kind, major_segments=24, minor_segments=8,
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
    curve.bevel_resolution = 2
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


def mesh_object(name, verts, faces, kind, loc=(0,0,0), bevel=0):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces); mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj); obj.location=loc
    if bevel:
        bpy.context.view_layer.objects.active=obj
        mod=obj.modifiers.new('broad_edge_chamfer','BEVEL')
        mod.width=bevel; mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(obj,name,kind)


def lathe(name, profile, kind, loc=(0,0,0), segments=24, rotation=None):
    """A radial cross-section builds rims, dished hubs and rolled lips as form."""
    verts=[(r*math.cos(2*math.pi*i/segments),r*math.sin(2*math.pi*i/segments),z)
           for r,z in profile for i in range(segments)]
    faces=[]
    for k in range(len(profile)-1):
        for i in range(segments):
            j=(i+1)%segments
            faces.append((k*segments+i,k*segments+j,(k+1)*segments+j,(k+1)*segments+i))
    faces.extend([tuple(reversed(range(segments))),tuple((len(profile)-1)*segments+i for i in range(segments))])
    obj=mesh_object(name,verts,faces,kind,loc)
    if rotation: obj.rotation_euler=rotation
    apply_mesh_transform(obj)
    return obj


def tube(name, points, radius, kind, sides=8, taper=False):
    """Continuous round-section tube: no disconnected ring stack or square rope."""
    verts=[]; faces=[]
    for i,p in enumerate(points):
        p=Vector(p)
        tangent=(Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)])).normalized()
        normal=tangent.cross(Vector((0,0,1)))
        if normal.length<.1: normal=tangent.cross(Vector((0,1,0)))
        normal.normalize(); binormal=tangent.cross(normal).normalized()
        r=radius*(1-.6*max(0,(i-(len(points)-5))/4)) if taper else radius
        for j in range(sides):
            a=2*math.pi*j/sides
            verts.append(tuple(p+r*(math.cos(a)*normal+math.sin(a)*binormal)))
        if i:
            for j in range(sides):
                n=(j+1)%sides; b=(i-1)*sides; t=i*sides
                faces.append((b+j,b+n,t+n,t+j))
    faces.extend([tuple(reversed(range(sides))),tuple((len(points)-1)*sides+i for i in range(sides))])
    return mesh_object(name,verts,faces,kind)


def ore_cart():
    # Flared individual planks, a repaired opening, iron hoops and dished wheels
    # describe a constructed mine cart rather than a solid primitive tub.
    for y in (-.34,.34):
        cylinder('cart_axle',(0,y,.23),.039,1.48,'metal',16,rotation=(0,math.pi/2,0))
        for x in (-.66,.66):
            lathe('cart_dished_wheel',[(.06,-.07),(.10,-.035),(.192,-.023),(.22,-.05),(.226,-.03),(.226,.03),(.22,.05),(.192,.023),(.10,.035),(.06,.07)],'metal',(x,y,.23),20,rotation=(0,math.pi/2,0))
    for x in (-.45,.45):
        beam_between('cart_underframe',(x,-.49,.38),(x,.49,.38),.095,.09)
    for y in (-.34,-.17,0,.17,.34):
        cube('cart_floor_plank',(0,y,.465),(1.16,.16,.075),'timber',.012)
    for side in (-1,1):
        for z in (.57,.765,.96):
            x=side*(.56+(z-.48)*.20)
            obj=cube('cart_flared_side_plank',(x,0,z),(.072,.99,.184),'timber',.012)
            obj.rotation_euler[1]=side*.197; apply_mesh_transform(obj)
        beam_between('cart_rounded_top_rail',(side*.681,-.54,1.071),(side*.681,.54,1.071),.083,.081)
        for y in (-.37,.37):
            beam_between('cart_iron_side_hoop',(side*.598,y,.51),(side*.710,y,1.064),.065,.018,'metal')
    for z in (.57,.765,.96):
        y=.455+(z-.48)*.17
        obj=cube('cart_back_plank',(0,y,z),(1.21+(z-.48)*.38,.068,.181),'timber',.009)
        obj.rotation_euler[0]=-.17; apply_mesh_transform(obj)
    # Low front sill and a diagonal broken plank preserve an open abandoned mouth.
    cube('cart_front_sill',(0,-.45,.57),(1.21,.068,.18),'timber',.012)
    beam_between('cart_repaired_front_brace',(-.55,-.48,.62),(.18,-.48,.95),.075,.052)
    for x in (-.58,.58):
        beam_between('cart_front_corner_post',(x,-.465,.50),(x*1.17,-.53,1.07),.074,.075)
    collision_box((-.79,.79,-.59,.60,0,1.13))


def fractured_block(name, loc, size, angle=0, skew=1):
    x,y,z=size[0]/2,size[1]/2,size[2]
    # Chamfered cut stone with a genuinely missing end wedge and broad facets.
    verts=[(-x,-y,0),(x*.72,-y,0),(x,y*.05,0),(x*.78,y,0),(-x,y,0),
           (-x,-y,z),(.53*x,-y,z*.86),(x,y*.12,z*.67),(.67*x,y,z*.85),(-x,y,z)]
    faces=[(0,4,3,2,1),(5,6,7,8,9),(0,1,6,5),(1,2,7,6),(2,3,8,7),(3,4,9,8),(4,0,5,9)]
    obj=mesh_object(name,verts,faces,'stone',loc,.016)
    obj.rotation_euler[2]=angle; apply_mesh_transform(obj)
    return obj


def fallen_masonry():
    fractured_block('fallen_split_lintel',(-.10,-.03,0),(1.58,.46,.32),-.12)
    fractured_block('fallen_course_long',(-.17,-.39,.03),(1.24,.36,.29),-.28)
    fractured_block('fallen_course_short',(.52,.29,.035),(.70,.49,.33),.36)
    obj=fractured_block('fallen_capstone',(-.36,.19,.28),(.92,.37,.27),.13)
    obj.rotation_euler[1]=.20; apply_mesh_transform(obj)
    for i,(loc,size) in enumerate([((.55,-.27,0),(.41,.35,.22)),((-.64,.52,0),(.25,.31,.18)),((.15,.51,0),(.29,.27,.12))]):
        irregular_rock('masonry_detached_shard_%02d'%i,loc,size)
    collision_box((-.96,.90,-.67,.70,0,.65))


def snapped_beam(name,a,b,width,depth):
    a,b=Vector(a),Vector(b); length=(b-a).length; w,d=width/2,depth/2
    # Eight perimeter points make two deep, recognisable longitudinal splinters.
    ring=[(-w,-d),(0,-d),(w,-d),(w,0),(w,d),(0,d),(-w,d),(-w,0)]
    heights=[length-.12,length-.27,length-.03,length-.18,length-.10,length-.32,length,length-.21]
    verts=[(x,y,0) for x,y in ring]+[(x,y,h) for (x,y),h in zip(ring,heights)]
    verts.append((0,0,length-.30))
    faces=[tuple(reversed(range(8)))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]+[(8+i,8+(i+1)%8,16) for i in range(8)]
    obj=mesh_object(name,verts,faces,'timber',a,.007)
    obj.rotation_mode='QUATERNION'; obj.rotation_quaternion=Vector((0,0,1)).rotation_difference((b-a).normalized())
    apply_mesh_transform(obj)
    return obj


def broken_bracing():
    snapped_beam('brace_fallen_main',(-.87,-.24,.09),(.83,.34,.18),.17,.15)
    snapped_beam('brace_fallen_cross',(-.70,.46,.09),(.76,-.43,.16),.15,.14)
    snapped_beam('brace_split_upright',(-.23,-.08,.15),(.28,-.02,.99),.17,.14)
    snapped_beam('brace_detached_splinter',(.13,-.22,.06),(.62,.05,.10),.065,.045)
    for x,y,z in [(-.48,-.10,.13),(-.02,.04,.19)]:
        # U-shaped straps actually wrap the timber rather than floating boxes.
        tube('brace_bent_strap',[(x,y-.10,z-.07),(x,y-.10,z+.065),(x,y+.10,z+.065),(x,y+.10,z-.07)],.018,'metal',6)
        cylinder('brace_strap_pin',(x,y-.13,z+.04),.022,.065,'metal',12,rotation=(math.pi/2,0,0))
    cube('brace_broken_foot',(.42,.13,.075),(.33,.24,.15),'timber',.016)
    collision_box((-.98,.91,-.57,.59,0,1.03))


def rope_coil():
    """A hemp rope coiled down as it comes off a windlass: loops stacked on
    loops, slumping as they rise, and the end run out across the floor. The
    first version was a flat sailor's flake of a 6 cm hawser; a mine's rope is
    nearer 3 cm."""
    points=[]
    turns, per = 6, 22
    # Each loop as it fell: its own size, off the centre of the one below,
    # sagging where it crosses another — a coil thrown down, not a spring.
    sizes=[.215,.19,.225,.18,.205,.17,.195]
    shift=[(0,0),(.025,-.01),(-.015,.02),(.03,.012),(-.01,-.025),(.02,.02),(.035,0)]
    # Slumped, not stacked: the loops lie half beside, half on each other,
    # so the coil stays under a body's step (`FloorDressing.STEP_OVER`) and
    # is walked over rather than into (a stacked 19 cm coil failed `--reach`).
    lift=[0,.010,.019,.028,.036,.044,.050]
    for i in range(turns*per+1):
        t=i/(turns*per); a=2*math.pi*turns*t
        k=min(int(t*turns),turns-1); f=t*turns-k
        lerp=lambda L: L[k]+(L[k+1]-L[k])*f
        r=lerp(sizes)*(1+.05*math.sin(2*a+k))
        cx=lerp([s[0] for s in shift]); cy=lerp([s[1] for s in shift])
        z=.016+lerp(lift)+.004*math.sin(a+k*1.7)
        points.append((cx+r*math.cos(a),cy+r*math.sin(a),max(.016,z)))
    # The free end: down over the side of the coil and out across the floor.
    top=Vector(points[-1])
    controls=[top,Vector((.34,.06,.10)),Vector((.46,.30,.014)),Vector((.70,.44,.014))]
    for i in range(1,17):
        t=i/16
        q=(1-t)**3*controls[0]+3*(1-t)**2*t*controls[1]+3*(1-t)*t*t*controls[2]+t**3*controls[3]
        points.append(tuple(q))
    tube('continuous_laid_rope',points,.016,'rope',6)
    # The end whipped with twine so it does not unlay.
    end=Vector(points[-1]); back=(Vector(points[-2])-end).normalized()
    tube('whipped_end',[tuple(end+back*.045),tuple(end+back*.002)],.019,'rope',6)
    collision_box((-.26,.74,-.27,.48,0,.095))


def rusted_fittings():
    # A dished sheave, cheeks and pin form a functional pulley lying on its side.
    lathe('pulley_grooved_sheave',[(.055,-.07),(.20,-.06),(.275,-.07),(.282,-.045),(.245,-.015),(.245,.015),(.282,.045),(.275,.07),(.20,.06),(.055,.07)],'metal',(0,0,.31),24,rotation=(math.pi/2,0,0))
    cylinder('pulley_axle',(0,0,.31),.043,.39,'metal',20,rotation=(math.pi/2,0,0))
    for y in (-.12,.12):
        # Rounded cheek bars keep the sheave clear; forge-eye at top carries chain.
        beam_between('pulley_cheek',(-.01,y,.30),(.01,y,.68),.09,.065,'metal')
        lathe('pulley_pin_cap',[(.055,-.012),(.058,0),(.05,.018)],'metal',(0,y*1.64,.31),16,rotation=(math.pi/2,0,0))
    torus('pulley_forged_eye',(0,0,.70),.083,.025,'metal',20,6,rotation=(math.pi/2,0,0))
    for i in range(3):
        torus('fallen_chain_link',(.16+i*.115,.02,.11),.070,.019,'metal',16,6,rotation=(math.pi/2,0,0) if i%2 else (0,.3,0))
    hook=[]
    for i in range(21):
        a=-math.pi*.15+math.pi*1.65*i/20
        hook.append((.43+.13*math.cos(a),.04,.19+.13*math.sin(a)))
    tube('forged_open_hook',hook,.031,'metal',8,True)
    cube('fallen_anchor_plate',(-.31,.17,.038),(.44,.22,.076),'metal',.02)
    for x in (-.45,-.19):
        cylinder('anchor_plate_rivet',(x,.17,.08),.024,.028,'metal',12)
    collision_box((-.56,.62,-.23,.33,0,.82))


def spent_candle(name,x,y,height,radius,phase):
    n=20; rings=[]
    for k in range(5):
        ring=[]
        for i in range(n):
            a=2*math.pi*i/n
            wobble=.03*math.sin(3*a+phase)+.025*math.cos(5*a-phase)
            if k==0:r,z=radius*1.15,.044
            elif k==1:r,z=radius*(1+wobble),.072
            elif k==2:r,z=radius*(.93+wobble),height+.035*math.sin(2*a+phase)+.017*math.cos(3*a)
            elif k==3:r,z=radius*.62,height-.011+.020*math.sin(2*a+phase)
            else:r,z=radius*.29,height-.04
            ring.append((x+r*math.cos(a),y+r*math.sin(a),z))
        rings+=ring
    faces=[tuple(reversed(range(n)))]+[(k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i) for k in range(4) for i in range(n)]+[tuple(4*n+i for i in range(n))]
    mesh_object(name,rings,faces,'wax')
    cylinder(name+'_charred_wick',(x,y,height-.018),.007,.053,'metal',8)
    # Two broad wax rivulets change the outline; no decorative microtexture.
    for a in (phase,phase+2.8):
        tube(name+'_melted_wax',[(x+radius*math.cos(a),y+radius*math.sin(a),height-.005),(x+radius*1.035*math.cos(a),y+radius*1.035*math.sin(a),height-.08),(x+radius*math.cos(a),y+radius*math.sin(a),height-.12)],.013,'wax',6,True)


def guttered_candles():
    lathe('candle_catch_dish',[(.02,.012),(.29,.012),(.34,.035),(.36,.080),(.359,.098),(.342,.103),(.321,.065),(.285,.044),(.02,.044)],'metal',segments=28)
    for i,(x,y,h,r) in enumerate(((-.13,-.08,.31,.071),(.13,-.045,.48,.075),(-.04,.14,.20,.061),(.115,.135,.33,.062))):
        spent_candle('spent_candle_%02d'%i,x,y,h,r,i*1.7)
    lathe('fallen_candle_stub',[(.045,-.082),(.049,-.065),(.047,.07),(.04,.08)],'wax',(-.21,.12,.11),20,rotation=(0,math.pi/2.5,.3))
    collision_box((-.38,.38,-.38,.38,0,.56))


def spoil_heap():
    """What a working throws out: a cone of fines at its angle of repose,
    broken rock of every size on and around it, and the spade left in it —
    wood shod with iron, as spades were until iron got cheap. The first
    version was ten large rocks and a steel spade."""
    import random
    rng=random.Random('spoil')
    R,H=.72,.40
    def height(x,y):
        r=math.hypot(x/R,y/(R*.84))
        return max(0.0,H*(1-min(r,1.0)**1.5))
    # The heap: a faceted cone, its rings jittered so it reads as tipped
    # loads rather than a lathe.
    rings,seg=5,15
    verts=[(0,0,H)]
    for k in range(1,rings+1):
        f=k/rings
        for s in range(seg):
            a=2*math.pi*s/seg+(.2 if k%2 else 0)
            rr=f*(1+rng.uniform(-.09,.09))
            x,y=rr*R*math.cos(a),rr*R*.84*math.sin(a)
            z=0.0 if k==rings else height(x,y)*(1+rng.uniform(-.12,.12))
            verts.append((x,y,z))
    faces=[(0,1+s,1+(s+1)%seg) for s in range(seg)]
    for k in range(rings-1):
        o0,o1=1+k*seg,1+(k+1)*seg
        for s in range(seg):
            n=(s+1)%seg
            faces.append((o0+s,o1+s,o1+n,o0+n))
    faces.append(tuple(reversed([1+(rings-1)*seg+s for s in range(seg)])))
    mesh_object('spoil_fines',verts,faces,'stone')
    # Rock on it: a few big pieces that rolled to the toe, more middling
    # pieces on the flanks, and small stuff everywhere.
    rocks=[(.30,.22),(.26,.18)]+[(rng.uniform(.13,.19),rng.uniform(.09,.13)) for _ in range(7)] \
        +[(rng.uniform(.06,.10),rng.uniform(.04,.07)) for _ in range(14)]
    for i,(w,h) in enumerate(rocks):
        big=i<2
        a=rng.uniform(0,2*math.pi)
        f=rng.uniform(.85,1.0) if big else rng.uniform(.15,1.05)
        x,y=f*R*math.cos(a),f*R*.84*math.sin(a)
        z=max(0.0,height(x,y)-h*.35)
        obj=irregular_rock('spoil_rock_%02d'%i,(x,y,z),(w,w*rng.uniform(.7,.95),h))
        obj.rotation_euler=(rng.uniform(-.25,.25),rng.uniform(-.25,.25),rng.uniform(0,6.28))
        apply_mesh_transform(obj)
    # The spade, lying up the slope where it was dropped: a straight ash haft
    # into a wooden blade, the blade's edge sheathed in an iron shoe.
    a,b=Vector((-.62,-.30,.04)),Vector((-.06,-.08,.36))
    obj=cylinder('spade_haft',(a+b)/2,.017,(b-a).length,'timber',8)
    obj.rotation_mode='QUATERNION';obj.rotation_quaternion=Vector((0,0,1)).rotation_difference((b-a).normalized());apply_mesh_transform(obj)
    along=(b-a).normalized()
    across=along.cross(Vector((0,0,1))).normalized()
    up=across.cross(along).normalized()
    def blade(name,start,length,half,thick,kind):
        c0=start; c1=start+along*length
        v=[]
        for c,w in ((c0,half*.86),(c1,half)):
            for s,u in ((-1,-1),(1,-1),(1,1),(-1,1)):
                v.append(tuple(c+across*(s*w)+up*(u*thick)))
        return mesh_object(name,v,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],kind)
    blade('spade_blade',b,.21,.085,.011,'timber')
    blade('spade_iron_shoe',b+along*.19,.06,.090,.014,'metal')
    # Every face outward: the engine draws one side only.
    import bmesh
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH':
            bm=bmesh.new(); bm.from_mesh(obj.data)
            bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
            bm.to_mesh(obj.data); bm.free()
    collision_box((-.73,.77,-.62,.66,0,.42))


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
    bpy.context.view_layer.update()
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
        dx, dy = (index % 3) * 2.7, (index // 3) * 2.7
        # Only the asset just made moves; preceding assets stay in their cell.
        for obj in set(bpy.context.scene.objects) - before:
            obj.location.x += dx
            obj.location.y += dy
        tile=cube("review_tile", (dx,dy,-.06), (2.5,2.5,.12), "stone", .015, 0.0)
        paper=bpy.data.materials.get('review_paper') or bpy.data.materials.new('review_paper')
        paper.diffuse_color=(.69,.68,.64,1);paper.use_nodes=True
        paper.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.69,.68,.64,1)
        tile.data.materials.clear();tile.data.materials.append(paper)
        review_label(_name.replace('dressing_','').upper(), (dx,dy-1.01,.015))
    add_reference_figure((5.4,5.4))
    review_label("1.80 m SCALE", (5.4,4.39,.015))
    bpy.ops.object.light_add(type="AREA", location=(4,-4,11))
    bpy.context.object.data.energy, bpy.context.object.data.shape = 2400, "DISK"
    bpy.context.object.data.size = 6
    bpy.ops.object.light_add(type="AREA", location=(9,9,6))
    bpy.context.object.data.energy, bpy.context.object.data.size = 1500, 4
    bpy.ops.object.camera_add(location=(4.2,-8.7,15.8))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((2.7,2.7,.35))-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type = "ORTHO"; camera.data.ortho_scale = 9.2
    scene = bpy.context.scene
    scene.camera = camera
    # Blender 5 exposes the EEVEE-next renderer under this stable enum name.
    scene.render.engine = "BLENDER_EEVEE"
    scene.world.color=(.5,.5,.5)
    scene.view_settings.view_transform='AgX'
    scene.render.resolution_x, scene.render.resolution_y = 2400, 2300
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(SRC / "dressing_review.png")
    bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "dressing_kit.blend"))


def render_asset_review(name, stats):
    """Close views expose construction and silhouette at player inspection scale."""
    span=max(b-a for a,b in stats['bounds_blender_xyz_m'])
    height=stats['bounds_blender_xyz_m'][2][1]
    target=Vector((0,0,height*.45))
    bpy.ops.object.camera_add(location=target+Vector((1.6,-2.4,1.65))*span)
    camera=bpy.context.object
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO';camera.data.ortho_scale=span*1.75
    scene=bpy.context.scene;scene.camera=camera
    for location,power,size in [((1,-2,4),480,3),((-3,1,2),360,3)]:
        bpy.ops.object.light_add(type='AREA',location=Vector(location)*span)
        lamp=bpy.context.object;lamp.data.energy=power*span*span;lamp.data.size=size*span
        lamp.rotation_euler=(target-lamp.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.004))
    ground=bpy.context.object
    mat=bpy.data.materials.new('review_neutral_ground');mat.diffuse_color=(.46,.46,.44,1)
    ground.data.materials.append(mat)
    scene.world.color=(.45,.45,.45)
    scene.render.engine='BLENDER_EEVEE';scene.view_settings.view_transform='AgX'
    scene.render.resolution_x=1100;scene.render.resolution_y=900
    scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG'
    scene.render.filepath=str(SRC/(name+'_review.png'))
    bpy.ops.render.render(write_still=True)


def main():
    bpy.context.preferences.filepaths.save_version = 0
    bpy.context.scene.unit_settings.system = "METRIC"
    delivered = []
    for name, builder in ASSETS:
        clear_scene()
        builder()
        # Set base-centre from the finished visible form, not a guessed box.
        bpy.context.view_layer.update()
        visible=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render]
        pts=[o.matrix_world @ v.co for o in visible for v in o.data.vertices]
        shift=Vector(((min(p.x for p in pts)+max(p.x for p in pts))/2,
                      (min(p.y for p in pts)+max(p.y for p in pts))/2,
                      min(p.z for p in pts)))
        for obj in bpy.context.scene.objects: obj.location-=shift
        stats = mesh_stats()
        assert stats["triangles"] <= 3000, (name, stats["triangles"])
        export_asset(name)
        bpy.ops.wm.save_as_mainfile(filepath=str(SRC / (name + ".blend")))
        delivered.append({"name": name, **stats})
        render_asset_review(name, stats)
    (SRC / "measurements.json").write_text(json.dumps(delivered, indent=2) + "\n")
    review_sheet()
    print("DRESSING_DELIVERED", json.dumps(delivered))


if __name__ == "__main__":
    main()
