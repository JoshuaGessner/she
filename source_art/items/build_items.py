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
    "stone": ((0.38, 0.38, 0.38, 1.0), 0.0),
    "timber": ((0.29, 0.29, 0.29, 1.0), 0.2),
    "metal": ((0.23, 0.23, 0.23, 1.0), 0.4),
    "cloth": ((0.58, 0.58, 0.58, 1.0), 0.6),
    "organic": ((0.33, 0.33, 0.33, 1.0), 0.8),
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
        mod.width, mod.segments = bevel, 2
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
    bpy.ops.object.select_all(action="DESELECT")
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth, curve.resolution_v = radius, 0
    curve.bevel_resolution = 0
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

def mesh_form(name, vertices, faces, kind, thickness=0):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces); mesh.update()
    obj = bpy.data.objects.new(name, mesh); bpy.context.collection.objects.link(obj)
    if thickness:
        bpy.context.view_layer.objects.active=obj
        mod=obj.modifiers.new('material thickness','SOLIDIFY'); mod.thickness=thickness
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(obj,name,kind)

def loft(name, rings, kind, close=True, thickness=0):
    n=len(rings[0]); vertices=[p for ring in rings for p in ring]; faces=[]
    for j in range(len(rings)-1):
        for k in range(n if close else n-1):
            q=(k+1)%n; faces.append((j*n+k,j*n+q,(j+1)*n+q,(j+1)*n+k))
    return mesh_form(name,vertices,faces,kind,thickness)

def lathe(name, profile, kind, n=24, center=(0,0,0)):
    return loft(name,[[(center[0]+r*math.cos(i*2*math.pi/n),center[1]+y,center[2]+r*math.sin(i*2*math.pi/n)) for i in range(n)] for r,y in profile],kind)

def ribbon(name, points, width, kind, across=(1,0,0), thickness=.005):
    d=Vector(across)*width/2
    return loft(name,[[tuple(Vector(p)-d),tuple(Vector(p)+d)] for p in points],kind,False,thickness)

def coin():
    # Broad, overlapping stack: struck rims are reserved for exposed top coins.
    for i in range(39):
        ring=i//8; a=i*2.39996; r=.019*ring+.007*(i%3)
        obj=cyl('struck_coin_%02d'%i,(r*math.cos(a),.004+.006*(i%7),r*math.sin(a)),.023,.006,'gold',12)
        obj.rotation_euler.x+=.04*math.sin(i); obj.rotation_euler.z=.07*math.cos(i)
    for i in range(5):
        a=i*1.25; x=.055*math.cos(a); z=.055*math.sin(a)
        cyl('coin_stack',(x,.025,z),.023,.040,'gold',12)
        cyl('exposed_coin',(x,.046,z),.023,.006,'gold',12)
        lathe('raised_coin_rim',[(.019,.049),(.020,.050),(.021,.049)],'gold',12,(x,0,z))
        rod('struck_stave',(x-.01,.051,z),(x+.01,.051,z),.0015,'gold',4)
    collision((-.13,.13,0,.06,-.13,.13))

def chest():
    # Separate boards follow a barrel-vault lid; bands follow that same surface.
    for i in range(7):
        x=-.306+i*.102
        for z in (-.21,.21): cube('chest_wall_plank',(x,.23,z),(.099,.40,.035),'timber',.007)
    for x in (-.358,.358):
        cube('chest_end',(x,.23,0),(.035,.40,.42),'timber',.009)
    cube('chest_floor',(0,.035,0),(.73,.05,.43),'timber',.008)
    for i in range(10):
        a0=math.pi*i/10+.008; a1=math.pi*(i+1)/10-.008
        ring=[]
        for x in (-.371,.371): ring.append([(x,.43+.215*math.sin(a),.215*math.cos(a)) for a in (a0,(a0+a1)/2,a1)])
        loft('vaulted_lid_board',ring,'timber',False,.018)
    for x in (-.27,.27):
        ribbon('curved_iron_binding',[(x,.065,-.236),(x,.43,-.236)]+[(x,.43+.229*math.sin(a),-.229*math.cos(a)) for a in [i*math.pi/16 for i in range(17)]]+[(x,.065,.236)],.038,'metal')
        for y in (.12,.34):
            for z in (-.24,.24): ico('band_rivet',(x,y,z),.010,'metal',subdiv=1)
    cube('hasp',(0,.355,-.244),(.044,.17,.016),'metal',.006)
    torus('lock_ring',(0,.26,-.261),.031,.008,'gold',16,4,rot=(0,0,0))
    collision((-.39,.39,0,.67,-.25,.25))

def plate():
    lathe('hammered_plate',[(.0,.008),(.25,.008),(.30,.013),(.35,.036),(.38,.06),(.382,.071),(.372,.077),(.356,.066),(.30,.038),(.24,.031),(.0,.031)],'gold',32)
    lathe('rolled_plate_lip',[(.363,.068),(.37,.081),(.38,.084),(.389,.073),(.382,.063)],'gold',32)
    # A raised central boss and four broad radial marks read without texture.
    lathe('plate_boss',[(0,.047),(.045,.047),(.065,.040),(.066,.032)],'gold',16)
    for a in range(4):
        t=a*math.pi/2
        rod('plate_radial_inlay',(.10*math.cos(t),.034,.10*math.sin(t)),(.23*math.cos(t),.034,.23*math.sin(t)),.005,'metal',4)
    collision((-.39,.39,0,.084,-.39,.39))

def torc():
    points=[(.11*math.cos(a),.028+.008*math.sin(a),.11*math.sin(a)) for a in [math.radians(42+i*276/40) for i in range(41)]]
    arc('continuous_neck_ring',points,.011,'gold')
    for i,p in enumerate((points[0],points[-1])):
        ico('flared_torc_terminal',p,.024,'gold',(1,.62,1.2),2)
        a=math.radians(42 if i==0 else 318)
        torus('terminal_collar',(.105*math.cos(a),p[1],.105*math.sin(a)),.015,.003,'gold',12,4)
    collision((-.14,.14,0,.062,-.14,.14))

def bead():
    # The bore is part of a closed annular cross section, visible from either end.
    lathe('pierced_gilt_bead',[(.007,.003),(.014,.003),(.021,.01),(.024,.021),(.021,.032),(.014,.039),(.007,.039),(.006,.034),(.006,.008),(.007,.003)],'gold',20)
    for y in (.009,.031): torus('bead_rim',(0,y,0),.019,.0018,'gold',20,4)
    collision((-.025,.025,0,.04,-.025,.025))

def gemstone():
    rings=[]
    for j,(r,y) in enumerate(((.008,.0),(.018,.011),(.012,.026),(.002,.037))):
        rings.append([(r*(1+.14*math.sin(i*5))*math.cos(i*math.tau/7+j*.12),y+.002*math.sin(i*3),r*.8*math.sin(i*math.tau/7+j*.12)) for i in range(7)])
    loft('cleaved_crystal',rings,'stone')
    mesh_form('crystal_ends',rings[0]+rings[-1],[tuple(range(6,-1,-1)),tuple(range(7,14))],'stone')
    collision((-.020,.020,0,.04,-.017,.017))

def byrnie():
    # Hollow elliptical shell: chest, waist, flared split skirt, sloping shoulders.
    n=24; rings=[]
    for j,(y,rx,rz) in enumerate(((.035,.255,.165),(.22,.235,.145),(.42,.245,.155),(.62,.285,.16),(.735,.125,.10))):
        ring=[]
        for i in range(n):
            a=i*math.tau/n
            split=.095*max(0,1-abs(math.cos(a))/.28) if j==0 else 0
            fold=1+.026*math.sin(6*a+j*.5)
            ring.append((rx*math.cos(a)*fold,y+split,rz*math.sin(a)*fold))
        rings.append(ring)
    loft('mail_tunic_shell',rings,'metal',True,.009)
    for side in (-1,1):
        rings=[]
        for x,r in ((.245,.115),(.34,.12),(.43,.105)):
            rings.append([(side*x,.61-.18*(x-.245)+r*math.cos(i*math.tau/16),r*.88*math.sin(i*math.tau/16)) for i in range(16)])
        loft('open_short_sleeve',rings,'metal',True,.009)
        pts=[(side*.432,.577+.107*math.cos(i*math.tau/24),.095*math.sin(i*math.tau/24)) for i in range(25)]
        arc('bound_sleeve_edge',pts,.010,'metal')
    arc('neck_binding',[(.127*math.cos(i*math.tau/28),.737,.102*math.sin(i*math.tau/28)) for i in range(29)],.010,'metal')
    # Sparse broad linked courses describe mail, leaving most of the budget to cloth form.
    for row in range(4):
        for col in range(9):
            x=(col-4)*.046+(.011 if row%2 else 0); y=.24+row*.072
            z=-.151*math.sqrt(max(.1,1-(x/.25)**2))-.003
            torus('linked_mail_course',(x,y,z),.022,.004,'metal',6,3,rot=(0,0,0))
    collision((-.45,.45,0,.76,-.18,.18))

def helm():
    # An open spangen shell, never a sphere occluded by a box.
    rings=[]
    for j in range(9):
        a=.07+j*(math.pi/2-.07)/8
        rings.append([(.162*math.sin(a)*math.cos(i*math.tau/28),.115+.20*math.cos(a),.185*math.sin(a)*math.sin(i*math.tau/28)) for i in range(28)])
    loft('open_helm_dome',rings,'metal',True,.009)
    lathe_obj=loft('brow_band',[[(.166*math.cos(i*math.tau/28),y,.19*math.sin(i*math.tau/28)) for i in range(28)] for y in (.108,.14)],'metal',True,.006)
    for k in range(4):
        t=k*math.pi/2
        pts=[(.168*math.sin(a)*math.cos(t),.115+.204*math.cos(a),.191*math.sin(a)*math.sin(t)) for a in [i*math.pi/2/16 for i in range(17)]]
        ribbon('spangen_ridge_band',pts,.022,'metal',(-math.sin(t),0,math.cos(t)),.004)
    ribbon('tapered_nasal_guard',[(0,.137,-.194),(0,.09,-.199),(0,.016,-.205),(0,0,-.20)],.024,'metal',thickness=.007)
    for i in range(12):
        a=i*math.tau/12
        ico('brow_rivet',(.17*math.cos(a),.124,.194*math.sin(a)),.0055,'metal',subdiv=1)
    ico('crown_cap',(0,.316,0),.018,'metal',(1,.4,1),2)
    collision((-.18,.18,0,.34,-.22,.20))

def bracers():
    for side in (-1,1):
        rings=[]
        for j,(y,r) in enumerate(((.01,.065),(.028,.068),(.24,.088),(.265,.085))):
            rings.append([(side*.10+r*math.cos(a),y,r*.88*math.sin(a)) for a in [math.radians(-145+i*290/24) for i in range(25)]])
        loft('open_forged_cuff',rings,'metal',False,.007)
        for y,r in ((.04,.072),(.227,.087)):
            arc('cuff_leather_binding',[(side*.10+r*math.cos(a),y,r*.88*math.sin(a)) for a in [math.radians(-145+i*290/24) for i in range(25)]],.008,'cloth')
        for y in (.04,.227): cube('cuff_buckle',(side*.10-.047,y,-.055),(.025,.025,.015),'metal',.004)
    collision((-.20,.20,0,.27,-.09,.09))

def shield():
    # Nine planks are clipped to the circle and individually follow its shallow dome.
    r=.35
    for i in range(9):
        x0=-r+i*2*r/9+.001; x1=-r+(i+1)*2*r/9-.001
        rows=[]
        for j in range(7):
            row=[]
            for x in (x0,(x0+x1)/2,x1):
                h=math.sqrt(max(0,r*r-x*x)); y=-h+j*2*h/6
                z=-.018-.052*max(0,1-(x*x+y*y)/(r*r))
                row.append((x,y+r,z))
            rows.append(row)
        loft('domed_shield_plank',rows,'timber',False,.026)
    arc('continuous_shield_rim',[(r*math.cos(a),r+r*math.sin(a),-.018) for a in [i*math.tau/48 for i in range(49)]],.015,'metal')
    # Hemispherical boss with a broad flange, rotated onto the front face.
    obj=lathe('shield_boss',[(.0,.13),(.045,.12),(.073,.095),(.086,.06),(.087,.035),(.108,.032),(.11,.02)],'metal',24)
    obj.rotation_euler.x=-math.pi/2; obj.location=(0,.35,-.066)
    for a in range(8):
        t=a*math.tau/8; ico('boss_rivet',(.097*math.cos(t),.35+.097*math.sin(t),-.10),.006,'metal',subdiv=1)
    rod('rear_handgrip',(-.1,.35,.06),(.1,.35,.06),.017,'timber',10)
    collision((-.37,.37,0,.73,-.20,.08))

def satchel():
    # Rounded sewn gusset: cross sections swell through the load, pinch at the mouth.
    rings=[]
    for y,rx,rz in ((.035,.16,.045),(.075,.218,.085),(.19,.235,.107),(.34,.21,.085),(.40,.19,.062)):
        rings.append([(rx*math.copysign(abs(math.cos(a))**.5,math.cos(a)),y+.012*math.sin(3*a),rz*math.copysign(abs(math.sin(a))**.75,math.sin(a))) for a in [i*math.tau/24 for i in range(24)]])
    loft('loaded_leather_gusset',rings,'cloth',True,.012)
    flap=[]
    for j,(y,z,w) in enumerate(((.40,.055,.19),(.425,0,.20),(.397,-.082,.205),(.34,-.112,.19),(.27,-.12,.13))):
        flap.append([(x*w,y-.018*(1-x*x),z-.007*math.cos(x*3)) for x in (-1,-.5,0,.5,1)])
    loft('curved_satchel_flap',flap,'cloth',False,.008)
    ribbon('broad_shoulder_strap',[(-.21,.32,.015),(-.25,.55,.02),(-.19,.75,.02),(0,.83,.02),(.19,.75,.02),(.25,.55,.02),(.21,.32,.015)],.035,'cloth',thickness=.006)
    ribbon('closure_tongue',[(0,.34,-.13),(0,.23,-.123),(0,.19,-.112)],.035,'cloth')
    cube('satchel_buckle',(0,.258,-.139),(.056,.047,.012),'metal',.005)
    collision((-.27,.27,0,.86,-.15,.13))

def frame():
    for x in (-.23,.23):
        arc('bent_frame_rail',[(x,.03,.025),(x*1.05,.17,0),(x,.64,0),(x*.86,1.0,.06)],.027,'timber')
    for y in (.12,.48,.91): rod('shaped_crossbar',(-.26,y,.018),(.26,y,.018),.023,'timber',10)
    for j in range(6):
        y=.27+j*.084
        ribbon('load_webbing',[(-.23,y,.025),(-.115,y,.07),(0,y,.085),(.115,y,.07),(.23,y,.025)],.042,'cloth',(0,1,0),.007)
    for side in (-1,1):
        ribbon('padded_shoulder_loop',[(side*.16,.89,0),(side*.19,.74,-.11),(side*.20,.46,-.18),(side*.15,.21,-.07),(side*.12,.16,0)],.048,'cloth',thickness=.008)
        for y in (.12,.48,.91):
            for d in (-.012,.012): torus('frame_lashing',(side*.23,y+d,.016),.036,.005,'cloth',12,4)
    cube('pack_load_shelf',(0,.10,.13),(.48,.035,.25),'timber',.009)
    collision((-.28,.28,0,1.04,-.21,.27))

def lantern():
    # Eight individual translucent-horn coloured panels within an iron cage.
    # Opaque bone colour is intentional: runtime light owns the illumination.
    n=8
    for i in range(n):
        a0=i*math.tau/n+.04; a1=(i+1)*math.tau/n-.04
        loft('curved_horn_panel',[[(r*math.cos(a),y,r*math.sin(a)) for a in (a0,(a0+a1)/2,a1)] for y,r in ((.105,.105),(.20,.115),(.38,.10),(.41,.095))],'cloth',False,.004)
        a=i*math.tau/n
        arc('forged_cage_rib',[(r*math.cos(a),y,r*math.sin(a)) for y,r in ((.08,.112),(.20,.121),(.40,.107),(.44,.10))],.008,'metal')
    for y,r in ((.09,.11),(.405,.102)):
        lathe('cage_end_ring',[(r-.012,y-.008),(r+.008,y-.008),(r+.009,y+.008),(r-.012,y+.008)],'metal',24)
    lathe('lantern_standing_foot',[(0,.015),(.10,.015),(.125,.028),(.125,.042),(.095,.065),(.095,.09)],'metal',24)
    lathe('sloped_weather_cap',[(.125,.417),(.128,.433),(.083,.469),(.059,.479)],'metal',24)
    for i in range(8):
        a=i*math.tau/8; rod('vent_post',(.048*math.cos(a),.472,.048*math.sin(a)),(.048*math.cos(a),.515,.048*math.sin(a)),.006,'metal',6)
    lathe('vent_rain_hat',[(0,.53),(.04,.53),(.071,.518),(.071,.509)],'metal',24)
    for side in (-1,1):
        torus('handle_hinge',(side*.114,.405,0),.018,.005,'metal',12,4,rot=(0,0,0))
    arc('arched_carry_bail',[(.13*math.cos(a),.411+.25*math.sin(a),0) for a in [i*math.pi/32 for i in range(33)]],.009,'metal')
    # Moveable shutter sits on the front panel; slots expose pale horn beneath.
    for side in (-1,1): rod('shutter_rail',(side*.043,.14,-.114),(side*.043,.36,-.109),.006,'metal',6)
    for y in (.15,.21,.27,.33): cube('shutter_louvre',(0,y,-.116),(.08,.035,.01),'metal',.002)
    cube('shutter_thumb',(0,.365,-.128),(.027,.016,.022),'metal',.004)
    collision((-.145,.145,0,.68,-.135,.135))

def waystone():
    rings=[]
    for j,(r,y) in enumerate(((.072,0),(.10,.035),(.09,.25),(.062,.32))):
        rings.append([(r*(1+.07*math.sin(i*4))*math.cos(i*math.tau/9),y+.009*math.sin(i*3),r*.73*math.sin(i*math.tau/9)) for i in range(9)])
    loft('worn_waystone',rings,'stone')
    mesh_form('stone_ends',rings[0]+rings[-1],[tuple(range(8,-1,-1)),tuple(range(9,18))],'stone')
    for a,b in [((0,.08,-.069),(0,.245,-.059)),((-.035,.19,-.065),(0,.245,-.059)),((0,.245,-.059),(.035,.19,-.065))]: rod('departure_inset',a,b,.003,'metal',4)
    collision((-.11,.11,0,.34,-.085,.085))

def ember():
    # Unequal tapering masses and fracture seams make a coal rather than a gold sphere.
    ico('heavy_ember_core',(0,.17,0),.22,'gold',(1.1,.78,.85),2)
    for i,(x,y,z,s) in enumerate(((-.19,.10,-.06,.11),(.14,.12,-.11,.12),(.02,.15,.14,.14),(-.04,.31,.015,.10))):
        obj=ico('fractured_ember_lobe',(x,y,z),s,'gold',(1,.85,.9),1); obj.rotation_euler=(i*.2,i*.4,i*.6)
    # Surface fractures are broad dark cuts, never noise painted onto the gold.
    arc('coal_fracture',[(-.14,.255,-.095),(-.04,.287,-.13),(.025,.24,-.165),(.11,.23,-.145)],.005,'stone')
    collision((-.31,.28,0,.41,-.25,.28))

def hush():
    # A carved split wooden token with a rounded oval edge.
    obj=lathe('hush_token',[(0,.0),(.083,.0),(.10,.008),(.108,.017),(.102,.028),(.086,.034),(0,.034)],'timber',24)
    obj.scale.z=.78; bpy.context.view_layer.objects.active=obj; obj.select_set(True); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for a,b in [((-.065,.035,-.015),(.065,.035,-.015)),((-.015,.035,-.015),(0,.035,.045)),((.025,.035,-.015),(.05,.035,.037))]: rod('hush_inset_stave',a,b,.004,'metal',4)
    collision((-.11,.11,0,.04,-.09,.09))

def linen():
    # An actual wound spiral on both ends, plus a loose cloth tongue.
    obj=cyl('linen_core',(0,.086,0),.086,.24,'cloth',24,rot=(0,math.pi/2,0))
    for side in (-1,1):
        pts=[]
        for i in range(90):
            a=i*math.tau*2.5/89; r=.008+.074*i/89
            pts.append((side*.122,.086+r*math.sin(a),r*math.cos(a)))
        arc('rolled_cloth_edge',pts,.0028,'cloth')
    ribbon('linen_loose_end',[(-.10,.11,-.077),(-.10,.06,-.105),(-.10,.018,-.14),(-.10,.007,-.20)],.21,'cloth',thickness=.005)
    torus('linen_tie',(0,.086,0),.09,.007,'cloth',24,4,rot=(0,math.pi/2,0))
    collision((-.13,.13,0,.18,-.21,.10))

def bog_iron():
    # Dented irregular nodules avoid identical primitive silhouettes.
    for i,(x,y,z,s) in enumerate(((-.055,.055,0,.078),(.05,.067,.016,.09),(0,.12,-.014,.065))):
        obj=ico('porous_iron_nodule',(x,y,z),s,'metal',(1.1,.77,.9),2)
        for v in obj.data.vertices:
            v.co*=1+.11*math.sin(v.index*2.718+i)
        obj.rotation_euler=(i*.3,i*.7,i*.4)
    collision((-.15,.15,0,.18,-.10,.11))

def pelt():
    # Ring-built hide surface carries broad alternating folds and a scalloped hem.
    outline=[(-.065,-.47),(-.12,-.40),(-.18,-.28),(-.36,-.30),(-.41,-.23),(-.27,-.12),(-.29,.15),(-.43,.28),(-.39,.35),(-.23,.28),(-.13,.34),(0,.45),(.13,.34),(.23,.28),(.39,.35),(.43,.28),(.29,.15),(.27,-.12),(.41,-.23),(.36,-.30),(.18,-.28),(.12,-.40),(.065,-.47)]
    rings=[]
    for j,s in enumerate((.035,.28,.55,.78,1.0)):
        rings.append([(x*s,.025+.055*(1-s*s)+.035*math.sin(i*1.9+.4)*s+.022*math.cos(z*11)*s,z*s) for i,(x,z) in enumerate(outline)])
    hide=loft('draped_otter_hide',rings,'organic',True,.012)
    for polygon in hide.data.polygons:
        polygon.use_smooth=True
    ico('otter_head',(0,.078,-.415),.105,'organic',(.70,.42,1),2)
    ico('tapered_muzzle',(0,.054,-.49),.048,'organic',(.70,.5,1.1),2)
    for side in (-1,1):
        ico('small_rounded_ear',(side*.052,.104,-.387),.026,'organic',(1,.7,.7),2)
        for z,x in ((-.26,.37),(.30,.395)):
            ico('spread_paw',(side*x,.035,z),.068,'organic',(.75,.32,1),2)
    tail=[]
    for j in range(9):
        t=j/8; r=.057*(1-t)+.007
        tail.append([(.045*math.sin(t*3)+r*math.cos(i*math.tau/10),.042+r*.45*math.sin(i*math.tau/10),.34+.34*t) for i in range(10)])
    loft('tapered_otter_tail',tail,'organic')
    collision((-.45,.45,0,.14,-.55,.70))

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
    bpy.context.preferences.filepaths.save_version = 0
    triangles = sum(len(p.vertices)-2 for o in render_meshes for p in o.data.polygons)
    print("ITEM_QA", name, "triangles", triangles, "base", min(v.co.y for o in render_meshes for v in o.data.vertices))
    assert triangles <= 3000, (name, triangles)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SRC, name + ".blend"))
    bpy.ops.object.select_all(action="SELECT")
    # Blender 5 exports this unused layer only when named explicitly.  Do not
    # attach it to material alpha: that creates a white COLOR_0 and moves ink
    # data to COLOR_1, which violates the renderer's fixed-channel contract.
    # Builders use the target coordinate contract directly: Y-up and -Z forward.
    # Do not apply Blender's native Z-up conversion a second time.
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), export_format="GLB", export_materials="EXPORT", export_yup=False, export_apply=True, export_cameras=False, export_lights=False, export_texcoords=False, export_vertex_color="NAME", export_vertex_color_name="ink", export_all_vertex_colors=True)

def review_sheet():
    """Individual equal-frame closeups keep tiny treasure as reviewable as armour."""
    import numpy as np
    columns=4; cell=560; rows=math.ceil(len(ASSETS)/columns)
    sheet=np.ones((rows*cell,columns*cell,4),dtype=np.float32)
    sheet[:,:,:3]=.72
    for index, (name, builder) in enumerate(ASSETS):
        reset(); MATS.clear(); builder()
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and 'colonly' not in o.name]
        for o in bpy.context.scene.objects:
            if 'colonly' in o.name: o.hide_render=True
        points=[o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        low=Vector(tuple(min(p[k] for p in points) for k in range(3)))
        high=Vector(tuple(max(p[k] for p in points) for k in range(3)))
        center=(low+high)/2; size=max(high-low)
        bpy.ops.object.camera_add(location=center+Vector((1.15,.85,-1.7))*size)
        cam=bpy.context.object
        forward=(center-cam.location).normalized()
        right=forward.cross(Vector((0,1,0))).normalized()
        up=right.cross(forward).normalized()
        cam.rotation_euler=Matrix((right,up,-forward)).transposed().to_euler()
        cam.data.type='ORTHO'; cam.data.ortho_scale=size*1.60; cam.data.clip_start=.0001
        scene=bpy.context.scene; scene.camera=cam
        for direction, energy in (((-1,2,-2),110),((2,1,-.3),65),((0,1,2),100)):
            bpy.ops.object.light_add(type='AREA',location=center+Vector(direction)*size)
            light=bpy.context.object; light.data.energy=energy*size*size; light.data.shape='DISK'; light.data.size=size*2
            light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
        scene.render.engine='BLENDER_EEVEE'; scene.render.resolution_x=560; scene.render.resolution_y=560; scene.render.resolution_percentage=100
        scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=True
        scene.world.color=(.3,.3,.3); scene.view_settings.view_transform='Standard'
        bpy.ops.object.text_add(location=center-up*size*.68-forward*size*.1)
        label=bpy.context.object
        label.rotation_euler=cam.rotation_euler
        label.data.body=name.replace('_',' ').upper()
        label.data.align_x='CENTER';label.data.align_y='CENTER';label.data.size=size*.048
        label.data.materials.append(material('metal'))
        scene.render.filepath=os.path.join(SRC,name+'_review.png')
        bpy.ops.render.render(write_still=True)
        rendered=bpy.data.images.load(scene.render.filepath,check_existing=False)
        pixels=np.empty(cell*cell*4,dtype=np.float32)
        rendered.pixels.foreach_get(pixels)
        pixels=pixels.reshape((cell,cell,4))
        x=(index%columns)*cell;y=(rows-1-index//columns)*cell
        alpha=pixels[:,:,3:4]
        sheet[y:y+cell,x:x+cell,:3]=pixels[:,:,:3]*alpha+.72*(1-alpha)
        bpy.data.images.remove(rendered)
    combined=bpy.data.images.new('item_review_sheet',width=columns*cell,height=rows*cell,alpha=True)
    combined.pixels.foreach_set(sheet.ravel())
    combined.filepath_raw=RENDER;combined.file_format='PNG';combined.save()

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True); os.makedirs(SRC, exist_ok=True)
    for asset in ASSETS: export_asset(*asset)
    review_sheet()
    print("Built %d ART-006 item assets" % len(ASSETS))
