"""The lofting helpers the first-person class arms are built with.

This built `DES-020`'s worn mail and bracers (ADR-308). They are sculpted now
(ADR-318, `build_worn.py`); what remains is what `build_class_arms.py` uses.
"""
import bpy
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


def limb_basis(side, bone):
    b = RIG.data.bones[f'{bone}_{side}']
    start, end = b.head_local.copy(), b.tail_local.copy()
    axis = (end-start).normalized()
    front = Vector((0, -1, 0))
    across = axis.cross(front).normalized()
    return start, end, front, across


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
