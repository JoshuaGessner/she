"""ART-006 Band 1: dressed masonry forms, never simulated surface wear.

Run with Blender --background --python source_art/environment/build_delvings.py.
Coordinates are Blender metres (Z up); glTF exporter converts to Y up.
The exact outer bounds live on the stone, not on collision padding.
"""
import bpy
import math
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'game/art/environment'
SRC = Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.context.scene.unit_settings.system = 'METRIC'
MATS = {}
for name, tone, ink in [('stone', .38, 0), ('pale_stone', .47, 0), ('dark_stone', .29, 0), ('timber', .20, .2), ('iron', .12, .4)]:
    m = bpy.data.materials.new(name)
    m.diffuse_color = (tone, tone, tone, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = m.diffuse_color
    p.inputs['Roughness'].default_value = .9
    MATS[name] = (m, ink)

def finish(obj, name, material='stone', bevel=0):
    obj.name = name
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if bevel:
        mod = obj.modifiers.new('cut_chamfer', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    mat, ink = MATS[material]
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for p in obj.data.polygons:
        p.use_smooth = False
    for uv in list(obj.data.uv_layers):
        obj.data.uv_layers.remove(uv)
    layer = obj.data.color_attributes.new(name='ink', type='FLOAT_COLOR', domain='CORNER')
    for c in layer.data:
        c.color = (1, .5, ink, 1)
    return obj

def box(name, center, size, mat='stone', bevel=.012):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    o = bpy.context.object
    o.scale = size
    return finish(o, name, mat, bevel)

def prism(name, polygon, bottom, top, mat='stone'):
    n = len(polygon)
    verts = [(x,y,bottom) for x,y in polygon] + [(x,y,top) for x,y in polygon]
    faces = [tuple(reversed(range(n))), tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    o = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(o)
    return finish(o, name, mat)

def proxy(center, size, name='solid'):
    o = box(name+'-colonly', center, size, bevel=0)
    o.hide_render = True
    o.display_type = 'WIRE'
    return o

def wall(width, height, depth=.3, x=0, y=0, z=0, variant=0):
    # Solid recessed backing keeps seams closed, while chamfered courses ink.
    box('masonry_core', (x,y,z+height/2), (width,depth-.04,height), 'dark_stone', 0)
    rows = max(1, round(height / (.5 if variant == 0 else .4)))
    rh = height/rows
    for row in range(rows):
        spacing = .67 if variant == 0 else .8
        start = -width/2
        cuts = [start]
        cut = start + (spacing/2 if row%2 else spacing)
        while cut < width/2-.1:
            cuts.append(cut)
            cut += spacing
        cuts.append(width/2)
        for a,b in zip(cuts,cuts[1:]):
            gap_a = .006 if a != -width/2 else 0
            gap_b = .006 if b != width/2 else 0
            box('course_%02d'%row, (x+(a+b+gap_a-gap_b)/2,y,z+(row+.5)*rh),
                (b-a-gap_a-gap_b,depth,rh-.008),
                ['stone','pale_stone','stone','dark_stone'][(row+len(bpy.context.scene.objects))%4], .009)

def new_asset(name):
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[name]
    return col

ASSETS = []
def export(name, col):
    # Blender 5.2's exporter loses COLOR_0 on the second material of a joined
    # mesh. One mesh per material preserves the authored data and batches stone.
    visible = [o for o in col.objects if not o.hide_render]
    groups = [(mat, [o for o in visible if o.data.materials[0] == mat])
              for mat in sorted({o.data.materials[0] for o in visible}, key=lambda m: m.name)]
    for mat, group in groups:
        bpy.ops.object.select_all(action='DESELECT')
        for o in group:
            o.select_set(True)
        bpy.context.view_layer.objects.active = group[0]
        bpy.ops.object.join()
        bpy.context.object.name = name + '_' + mat.name
    bpy.ops.object.select_all(action='DESELECT')
    for o in col.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')), export_format='GLB',
        use_selection=True, export_yup=True, export_texcoords=False,
        export_normals=True, export_materials='EXPORT', export_attributes=True,
        export_vertex_color='NAME', export_vertex_color_name='ink',
        export_all_vertex_colors=True, export_cameras=False, export_lights=False)
    visible = [o for o in col.objects if not o.hide_render]
    points = [o.matrix_world @ Vector(c) for o in visible for c in o.bound_box]
    bounds = [[min(p[i] for p in points),max(p[i] for p in points)] for i in range(3)]
    tris = sum(len(p.vertices)-2 for o in visible for p in o.data.polygons)
    assert tris <= 3000, (name,tris)
    ASSETS.append(dict(name=name,triangles=tris,bounds_blender=bounds))

for name,h,v in [('delvings_wall_2x26',2.6,0),('delvings_wall_2x40',4,0),('delvings_wall_2x70',7,0),('delvings_wall_2x40_b',4,1)]:
    c = new_asset(name)
    wall(2,h,variant=v)
    proxy((0,0,h/2),(2,.3,h))
    export(name,c)

name='delvings_doorway'
c=new_asset(name)
for x in [-1.6,1.6]:
    wall(.8,2.2,x=x)
    proxy((x,0,1.1),(.8,.3,2.2),'jamb')
wall(4,1.4,z=2.6,variant=1)
# One structural lintel, rather than a coplanar decorative facing.
box('lintel',(0,0,2.4),(4,.3,.4),'pale_stone',.009)
proxy((0,0,3.1),(4,.3,1.8),'lintel')
export(name,c)

name='delvings_corner_inner'
c=new_asset(name)
wall(2,4,y=.85)
before=set(c.objects)
wall(1.7,4,x=0,y=0)
for o in set(c.objects)-before:
    # Baked mesh rotation and translation avoids scaled parenting.
    for v in o.data.vertices:
        x,y,z=v.co
        v.co=(-.85+y,-.15+x,z)
proxy((0,.85,2),(2,.3,4),'north')
proxy((-.85,-.15,2),(.3,1.7,4),'west')
export(name,c)

name='delvings_corner_chamfer'
c=new_asset(name)
# Square 2 m envelope; diagonal is the specified 1.6 m corner cutback.
poly=[(-1,-1),(-.7,-1),(-.7,-.6),(.6,.7),(1,.7),(1,1),(.6,1),(-1,-.6)]
for row in range(8):
    prism('diagonal_course',poly,row*.5,(row+1)*.5-(.008 if row<7 else 0),'pale_stone' if row%3==0 else 'stone')
# One low-complexity concave proxy retains the traversable side of the chamfer.
o=prism('corner-colonly',poly,0,4)
o.hide_render=True
o.display_type='WIRE'
export(name,c)

for name,var in [('delvings_floor_2x2',0),('delvings_floor_2x2_b',1)]:
    c=new_asset(name)
    box('floor_bed',(0,0,.023),(2,2,.046),'dark_stone',0)
    # 6 cm total rise, below the actual 10 cm walking step limit.
    for row in range(2 if var==0 else 3):
        rows=2 if var==0 else 3
        cuts=[-1,0,1] if (row+var)%2==0 else [-1,-.4,.45,1]
        for a,b in zip(cuts,cuts[1:]):
            left=.008 if a>-1 else 0
            right=.008 if b<1 else 0
            box('flag',((a+b+left-right)/2,-1+(row+.5)*2/rows,.047),
                (b-a-left-right,2/rows-.008,.026),'pale_stone' if row%2 else 'stone',.004)
    proxy((0,0,.03),(2,2,.06),'floor')
    export(name,c)

name='delvings_ceiling_2x2'
c=new_asset(name)
box('ceiling_slab',(0,0,.29),(2,2,.18),'stone',.012)
for y in [-.83,.83]:
    box('crossbeam',(0,y,.10),(2,.24,.20),'timber',.015)
    for x in [-.75,.75]:
        box('iron_strap',(x,y,.10),(.08,.255,.20),'iron',.004)
for x in [-.66,0,.66]:
    box('ceiling_plank',(x,0,.19),(.65,2,.07),'timber',.006)
proxy((0,0,.19),(2,2,.38),'ceiling')
export(name,c)

name='delvings_alcove'
c=new_asset(name)
for x in [-.875,.875]:
    wall(.25,2.2,.6,x=x)
    proxy((x,0,1.1),(.25,.6,2.2),'side')
box('nook_back',(0,.24,1.1),(1.5,.12,2.2),'stone',.009)
box('nook_lintel',(0,0,2.08),(1.5,.6,.24),'pale_stone',.012)
box('nook_sill',(0,0,.035),(1.5,.6,.07),'pale_stone',.007)
proxy((0,.24,1.1),(1.5,.12,2.2),'back')
proxy((0,0,2.08),(1.5,.6,.24),'lintel')
proxy((0,0,.035),(1.5,.6,.07),'sill')
export(name,c)

name='delvings_ledge_edge'
c=new_asset(name)
wall(2,2.3,.52,y=.04)
box('deck_cap',(0,0,2.4),(2,.6,.2),'pale_stone',.012)
proxy((0,0,1.25),(2,.6,2.5),'ledge')
export(name,c)

name='delvings_ramp_2x25'
c=new_asset(name)
# 5 m sloping run and a 1 m flat landing in the requested 6 m footprint.
verts=[(-1,-3,0),(1,-3,0),(-1,2,0),(1,2,0),(-1,2,2.5),(1,2,2.5),(-1,3,0),(1,3,0),(-1,3,2.5),(1,3,2.5)]
faces=[(0,1,5,4),(4,5,9,8),(0,4,8,6),(1,7,9,5),(6,8,9,7),(0,6,7,1)]
mesh=bpy.data.meshes.new('ramp');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('ramp',mesh);c.objects.link(o);finish(o,'ramp')
collision=o.copy();collision.data=o.data.copy();c.objects.link(collision);collision.name='ramp-colonly';collision.hide_render=True;collision.display_type='WIRE'
# End fascia courses are genuine stepped cuts, staying inside footprint.
for row in range(5):
    box('landing_fascia',(0,2.99,(row+.5)*.5),(1.98,.02,.48),'pale_stone' if row%2 else 'stone',.006)
export(name,c)

name='delvings_pillar'
c=new_asset(name)
box('foot',(0,0,.12),(.8,.8,.24),'pale_stone',.02)
box('plinth',(0,0,.32),(.68,.68,.16),'stone',.015)
for row in range(6):
    box('shaft_course',(0,0,.4+(row+.5)*.5),(.54,.54,.49),'stone',.018)
box('neck',(0,0,3.5),(.64,.64,.2),'dark_stone',.013)
box('capital',(0,0,3.8),(.8,.8,.4),'pale_stone',.022)
proxy((0,0,2),(.8,.8,4),'pillar')
export(name,c)

(SRC/'measurements.json').write_text(json.dumps(ASSETS,indent=2)+'\n')
# Keep all authored modules in their own collections at their export origin.
for c in bpy.data.collections:
    if c.name.startswith('delvings_'):
        c.hide_render=True
        c.hide_viewport=True
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'delvings_band_1.blend'))

# A review arrangement is separate from the export meshes, with a 1.8 m figure.
review=new_asset('review')
for i,entry in enumerate(ASSETS):
    original=bpy.data.collections[entry['name']]
    # Consistent scale across the entire board, so dimensions remain reviewable.
    offset=Vector(((i%5)*5.5,(i//5)*9,0))
    for src in original.objects:
        if src.hide_render:continue
        o=src.copy();o.data=src.data.copy();review.objects.link(o);o.location+=offset
    bpy.ops.object.text_add(location=offset+Vector((-1.5,-3.7,0)))
    t=bpy.context.object;t.data.body=entry['name'].replace('delvings_','');t.data.size=.23
    t.data.extrude=0;t.data.materials.append(MATS['iron'][0])
box('reference_body',(23,19,.95),(.45,.25,1.3),'iron',.06)
bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.15,location=(23,19,1.65))
finish(bpy.context.object,'reference_head','iron')
for x in [22.86,23.14]:box('reference_leg',(x,19,.3),(.16,.19,.6),'iron',.02)
bpy.ops.object.text_add(location=(21.7,17.5,0));bpy.context.object.data.body='1.80 m';bpy.context.object.data.size=.3
box('review_ground',(10,9,-.15),(32,34,.2),'pale_stone',0)
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=24
scene.world.color=(.4,.4,.4)
bpy.ops.object.light_add(type='AREA',location=(4,-7,23));bpy.context.object.data.energy=11000;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=15
bpy.ops.object.camera_add(location=(33,-34,32))
camera=bpy.context.object;camera.rotation_euler=(Vector((10,8,1.7))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO';camera.data.ortho_scale=40;scene.camera=camera
scene.render.resolution_x=2000;scene.render.resolution_y=1700;scene.render.resolution_percentage=100
scene.view_settings.exposure=.7
scene.render.filepath=str(SRC/'delvings_review.png')
bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'delvings_review.blend'))
print('DELIVERED',json.dumps(ASSETS))
