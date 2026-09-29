"""Author DES-020's wearable mail and bracers on the permanent shared rig.

Blender --background --python-exit-code 1 --python this_file.py
The loose pickup models remain separate: their base-centred pivots cannot also
be the bind-space origin of a garment. Never rebuild or rescale the shared rig.
"""
import bpy
import bmesh
import json
import math
from pathlib import Path
from mathutils import Vector

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
OUT = ROOT / 'game/art/characters'
PALETTE = {
    'mail': ((.27, .28, .29, 1), .4),
    'iron': ((.19, .20, .21, 1), .4),
    'linen': ((.43, .41, .36, 1), .6),
    'leather': ((.20, .17, .13, 1), .8),
}
RIG = None
PARTS = []
MATERIALS = {}


def begin():
    global RIG, PARTS, MATERIALS
    bpy.ops.wm.open_mainfile(filepath=str(SRC / 'humanoid_rig.blend'))
    bpy.context.preferences.filepaths.save_version = 0
    RIG = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
    for obj in list(bpy.context.scene.objects):
        if obj != RIG:
            bpy.data.objects.remove(obj, do_unlink=True)
    RIG.data.pose_position = 'POSE'
    for bone in RIG.pose.bones:
        bone.matrix_basis.identity()
    PARTS, MATERIALS = [], {}
    assert len(RIG.data.bones) == 28


def mat(kind):
    if kind not in MATERIALS:
        color, _ = PALETTE[kind]
        m = bpy.data.materials.new(kind)
        m.diffuse_color = color
        m.use_nodes = True
        p = m.node_tree.nodes.get('Principled BSDF')
        p.inputs['Base Color'].default_value = color
        p.inputs['Roughness'].default_value = .78
        p.inputs['Metallic'].default_value = .6 if kind in ('mail', 'iron') else 0
        MATERIALS[kind] = m
    return MATERIALS[kind]


def skin_mesh(name, verts, faces, kind, weights, smooth=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(mat(kind))
    ink = data.color_attributes.new(name='ink', type='FLOAT_COLOR', domain='CORNER')
    data.color_attributes.active_color = ink
    for c in ink.data:
        c.color = (1, .5, PALETTE[kind][1], 1)
    # Cylindrical bind-space UVs, useful for a future authored insignia. The
    # game's material grain is still triplanar and owns surface-scale detail.
    uv = data.uv_layers.new(name='UVMap')
    for poly in data.polygons:
        poly.use_smooth = smooth
        for li in poly.loop_indices:
            p = data.vertices[data.loops[li].vertex_index].co
            uv.data[li].uv = (math.atan2(p.y, p.x) / math.tau + .5, p.z / 1.8)
    for i, v in enumerate(data.vertices):
        row = weights(v.co) if callable(weights) else weights
        total = sum(row.values())
        assert total > 0
        for bone, amount in row.items():
            assert bone in RIG.data.bones and not bone.startswith('sock_')
            group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
            if amount > 0:
                group.add([i], amount / total, 'REPLACE')
    obj.parent = RIG
    modifier = obj.modifiers.new('shared_skeleton', 'ARMATURE')
    modifier.object = RIG
    PARTS.append(obj)
    return obj


def loft(name, rings, kind, weights, closed=True, smooth=False):
    n = len(rings[0])
    assert all(len(r) == n for r in rings)
    verts = [p for row in rings for p in row]
    faces = []
    for j in range(len(rings) - 1):
        for i in range(n if closed else n - 1):
            k = (i + 1) % n
            faces.append((j*n+i, j*n+k, (j+1)*n+k, (j+1)*n+i))
    return skin_mesh(name, verts, faces, kind, weights, smooth)


def torso_weights(p):
    stops = [(.91, 'pelvis'), (1.10, 'spine_01'), (1.30, 'spine_02'), (1.44, 'chest')]
    if p.z <= stops[0][0]:
        return {'pelvis': 1}
    for (lo, a), (hi, b) in zip(stops, stops[1:]):
        if p.z <= hi:
            t = (p.z-lo)/(hi-lo)
            return {a: 1-t, b: t}
    return {'chest': 1}


def ellipse(rx, ry, z, n=32, y=0, phase=0):
    return [(rx*math.cos(a), y+ry*math.sin(a), z)
            for a in [phase+i*math.tau/n for i in range(n)]]


def limb_basis(side, bone):
    b = RIG.data.bones[f'{bone}_{side}']
    start, end = b.head_local.copy(), b.tail_local.copy()
    axis = (end-start).normalized()
    front = Vector((0, -1, 0))
    across = axis.cross(front).normalized()
    return start, end, front, across


def sleeve(side):
    start, end, front, across = limb_basis(side, 'upper_arm')
    # A padded shoulder cap flows into a half sleeve and ends before the elbow.
    rings = []
    for t, r in ((-.30,.002),(-.25,.042),(-.12,.073), (.12,.079), (.40,.073), (.65,.065), (.82,.059), (.83,.053), (.73,.053)):
        c = start.lerp(end, t)
        rings.append([c + r*(math.cos(a)*front+math.sin(a)*across)
                      for a in [i*math.tau/20 for i in range(20)]])
    def weights(p):
        t = max(0, min(1, (p-start).dot(end-start)/(end-start).length_squared))
        shoulder = max(0, .35*(1-t/.35))
        return {'chest': shoulder, f'upper_arm_{side}': 1-shoulder}
    loft(f'mail_half_sleeve_{side}', rings, 'mail', weights)


def rounded_box(name, center, size, kind, weights, bevel=.008):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    mod = obj.modifiers.new('worked_edges', 'BEVEL')
    mod.width, mod.segments = bevel, 2
    bpy.ops.object.modifier_apply(modifier=mod.name)
    verts = [v.co.copy() for v in obj.data.vertices]
    faces = [tuple(p.vertices) for p in obj.data.polygons]
    bpy.data.objects.remove(obj, do_unlink=True)
    return skin_mesh(name, verts, faces, kind, weights)


def mail():
    # The skirt's front/back slit leaves room for a stride. The side panels
    # blend into their own thigh; the waist follows the spine instead.
    def skirt_weights(p):
        t = max(0, min(.75, (1.0-p.z)*3.0))
        return {'pelvis': 1-t, 'thigh_l' if p.x >= 0 else 'thigh_r': t}
    for side in (-1, 1):
        rings = []
        for z, rx, ry in ((.76,.213,.137), (.79,.214,.138), (.87,.207,.134), (.96,.185,.125), (1.03,.18,.123)):
            rings.append([(side*rx*math.cos(a), ry*math.sin(a), z+.009*math.cos(5*a))
                          for a in [-math.pi/2+.035+i*(math.pi-.07)/24 for i in range(25)]])
        if side < 0:
            rings = [list(reversed(row)) for row in rings]
        loft(f'split_mail_skirt_{side}', rings, 'mail', skirt_weights, False)
    rows = [(1.00,.181,.124),(1.08,.179,.124),(1.16,.189,.134),
            (1.24,.214,.147),(1.32,.232,.151),(1.39,.226,.147),
            (1.44,.220,.140),(1.49,.190,.125),(1.535,.12,.10),
            (1.565,.074,.068),(1.566,.065,.059),(1.54,.065,.059)]
    loft('shaped_mail_torso', [ellipse(rx, ry, z) for z,rx,ry in rows], 'mail', torso_weights)
    loft('bound_open_neck', [ellipse(rx,ry,z) for z,rx,ry in
         ((1.545,.106,.091),(1.571,.078,.071),(1.572,.067,.061),(1.55,.067,.061))],
         'leather', {'chest':1})
    # A cinched belt and the hanging tail make the shirt's waist legible in ink.
    loft('waist_belt', [ellipse(rx,ry,z) for z,rx,ry in
         ((1.025,.190,.133),(1.055,.188,.132),(1.06,.183,.128),(1.024,.184,.128))],
         'leather', torso_weights)
    rounded_box('belt_buckle', (0,-.137,1.043), (.057,.018,.041), 'iron', torso_weights, .004)
    rounded_box('belt_tongue', (.045,-.134,.981), (.027,.012,.126), 'leather', {'pelvis':1}, .004)
    for side in ('l','r'):
        sleeve(side)
        # DES-020 Body includes legs. Padded trousers stop inside the boots.
        sign = 1 if side == 'l' else -1
        def leg_weights(p, side=side):
            t = max(0,min(1,(p.z-.48)/.14))
            return {f'thigh_{side}':t, f'calf_{side}':1-t}
        rows = []
        for z, rx, ry in ((.21,.076,.078),(.25,.075,.079),(.29,.073,.076),(.41,.077,.08),(.50,.08,.083),(.58,.086,.09),(.72,.09,.092),(.88,.09,.092),(.97,.085,.086)):
            rows.append([(sign*.09+rx*math.cos(a),ry*math.sin(a),z)
                         for a in [i*math.tau/20 for i in range(20)]])
        loft(f'linen_leg_{side}', rows, 'linen', leg_weights, smooth=True)
        # Low stitched boot with a continuous shaped toe, not a cube.
        rows = []
        for z, rx, front, back in ((.005,.071,-.204,.062),(.025,.074,-.207,.066),
                                  (.075,.071,-.205,.067),(.12,.069,-.154,.068),
                                  (.16,.066,-.075,.065),(.22,.070,-.072,.07),(.23,.066,-.068,.066)):
            cy=(front+back)/2; ry=(back-front)/2
            rows.append([(sign*.09+rx*math.cos(a),cy+ry*math.sin(a),z)
                         for a in [i*math.tau/24 for i in range(24)]])
        loft(f'sewn_boot_{side}', rows, 'leather', {f'foot_{side}':1})


def bracers():
    for side in ('l','r'):
        start,end,front,across = limb_basis(side,'forearm')
        weights = {f'forearm_{side}':1}
        def ring(t,r,n=32,gap=.42):
            c=start.lerp(end,t)
            return [c+r*(math.cos(a)*front+math.sin(a)*across)
                    for a in [-math.pi+gap+i*(math.tau-2*gap)/(n-1) for i in range(n)]]
        # The opening sits on the underside, opposite the broad raised face.
        loft(f'forged_open_cuff_{side}', [ring(t,r) for t,r in
             ((.12,.064),(.16,.067),(.30,.064),(.52,.060),(.76,.056),(.86,.054),
              (.88,.050),(.83,.048),(.52,.053),(.15,.059),(.12,.060))], 'iron', weights, False)
        for t,r in ((.23,.066),(.74,.059)):
            loft(f'cuff_binding_{side}_{t}', [ring(t-.027,r,32,.0),ring(t+.027,r,32,.0),
                 ring(t+.027,r-.004,32,.0)], 'leather', weights, False)
            c=start.lerp(end,t)-front*r
            rounded_box(f'strap_buckle_{side}_{t}', c, (.022,.017,.022), 'iron', weights, .003)
        # A low central ridge gives a deliberate forged cross-section at FP scale.
        strips=[]
        for t,r in ((.22,.068),(.48,.066),(.78,.058)):
            c=start.lerp(end,t)
            strips.append([c+front*(r+.007*(1-abs(x)))+across*(x*.023) for x in (-1,0,1)])
        loft(f'cuff_spine_{side}', strips, 'iron', weights, False)


def export(name):
    bpy.ops.object.select_all(action='DESELECT')
    RIG.select_set(True)
    for obj in PARTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = RIG
    # Keep objects separate by material so Blender's exporter preserves each
    # active COLOR_0 layer, and keep bind transforms exactly those of the rig.
    triangles=sum(len(p.vertices)-2 for o in PARTS for p in o.data.polygons)
    assert triangles <= 10000, triangles
    for o in PARTS:
        assert o.matrix_basis.is_identity
        for v in o.data.vertices:
            assert abs(sum(g.weight for g in v.groups)-1) < 1e-5
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(OUT/f'{name}.glb'), export_format='GLB',
        use_selection=True, export_yup=True, export_apply=False, export_skins=True,
        export_def_bones=False, export_leaf_bone=False, export_animations=False,
        export_morph=False, export_cameras=False, export_lights=False,
        export_vertex_color='ACTIVE', export_attributes=True, export_extras=True)
    return {'triangles':triangles,'mesh_parts':len(PARTS),'bones':len(RIG.data.bones),
            'source_rig':'humanoid_rig.blend','weighted_bones':sorted({g.name for o in PARTS for g in o.vertex_groups})}


def review(name):
    # Include the unchanged body for fit review, never in the garment export.
    with bpy.data.libraries.load(str(SRC/'humanoid_rig.blend'), link=False) as (a,b):
        b.objects=[n for n in a.objects if n=='proxy_body']
    for o in b.objects:
        if o:
            bpy.context.collection.objects.link(o)
            o.parent=RIG
            for m in o.modifiers:
                if m.type=='ARMATURE': m.object=RIG
            if name == 'mail_byrnie_worn':
                # Mirror runtime clothing coverage in the review, retaining
                # the permanent body source untouched for unequipped players.
                covered = {'pelvis','spine_01','spine_02','chest','upper_arm_l',
                    'upper_arm_r','thigh_l','thigh_r','calf_l','calf_r','foot_l','foot_r'}
                group_ids={g.index for g in o.vertex_groups if g.name in covered}
                hidden={v.index for v in o.data.vertices if any(g.group in group_ids and g.weight>.5 for g in v.groups)}
                bm=bmesh.new(); bm.from_mesh(o.data); bm.verts.ensure_lookup_table()
                bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index in hidden],context='VERTS')
                bm.to_mesh(o.data); bm.free()
    scene=bpy.context.scene
    scene.render.engine='CYCLES'
    scene.cycles.samples=32
    scene.render.resolution_x=1000; scene.render.resolution_y=1100
    scene.render.resolution_percentage=100
    scene.world.color=(.28,.28,.28)
    scene.view_settings.view_transform='AgX'
    for loc,power,size in (((-3,-4,5),700,4),((3,-1,3),450,3),((1,3,4),650,3)):
        bpy.ops.object.light_add(type='AREA',location=loc)
        lamp=bpy.context.object; lamp.data.energy=power; lamp.data.shape='DISK'; lamp.data.size=size
        lamp.rotation_euler=(Vector((0,0,1))-lamp.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add(location=(2.5,-4,2.0))
    camera=bpy.context.object; scene.camera=camera
    target=Vector((0,0,1.03))
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'; camera.data.ortho_scale=2.15
    scene.render.filepath=str(SRC/f'{name}_review.png')
    bpy.ops.render.render(write_still=True)
    # Exercise both elbow rotation and a crouching lower body in the preview.
    for side in ('l','r'):
        RIG.pose.bones[f'forearm_{side}'].rotation_mode='XYZ'
        RIG.pose.bones[f'forearm_{side}'].rotation_euler.x=-.85
        RIG.pose.bones[f'thigh_{side}'].rotation_mode='XYZ'
        RIG.pose.bones[f'thigh_{side}'].rotation_euler.x=.45
        RIG.pose.bones[f'calf_{side}'].rotation_mode='XYZ'
        RIG.pose.bones[f'calf_{side}'].rotation_euler.x=-.6
    RIG.pose.bones['chest'].rotation_mode='XYZ'
    RIG.pose.bones['chest'].rotation_euler.x=.15
    scene.render.filepath=str(SRC/f'{name}_posed_review.png')
    bpy.ops.render.render(write_still=True)


def main():
    report={}
    for name,builder in [('mail_byrnie_worn',mail),('iron_bracers_worn',bracers)]:
        begin(); builder(); report[name]=export(name); review(name)
    (SRC/'worn_armour_measurements.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))


if __name__=='__main__':
    main()
