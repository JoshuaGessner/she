"""Bake shared-rig enemy performances; combat clips use normalized phase time.

The engine owns displacement and hit timing. These clips never move the actor
through the world: walk/run are distance-driven, events are sampled by the
authoritative gameplay phase. All six exports retain the permanent bind pose.
Run in Blender after build_enemy_models.py and build_gullsjukr.py.
"""
import math
import sys
import json
import struct
from pathlib import Path

import bpy
import bmesh
from mathutils import Quaternion, Vector

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
KINDS = ('wretch', 'sling_wretch', 'bellringer', 'hall_warden', 'hoard_keeper', 'gullsjukr')
CLIPS = {'idle': 4, 'search': 3, 'walk': 1, 'run': 1, 'telegraph': 1,
         'attack': 1, 'recovery': 1, 'stagger': 1, 'death': 1,
         'call': 1, 'collect': 1, 'take': 1, 'shrug': 1}
LOOPS = {'idle', 'search', 'walk', 'run', 'collect'}


def clips_for(kind):
    names = (('idle', 'search', 'walk', 'run', 'collect', 'take', 'shrug')
             if kind == 'gullsjukr' else
             ('idle', 'search', 'walk', 'run', 'telegraph', 'attack', 'recovery', 'stagger', 'death'))
    if kind == 'bellringer':
        names += ('call',)
    return {name: CLIPS[name] for name in names}


def ease(t):
    t = max(0, min(1, t))
    return t*t*(3-2*t)


def pose(kind, clip, t):
    """World-axis offsets, converted into each bone's rest-local frame below."""
    hunter = kind == 'gullsjukr'
    ragged = kind in ('wretch', 'sling_wretch', 'bellringer')
    p = {'spine_01': [.14 if ragged else .08, 0, 0],
         'chest': [.12 if ragged else .04, -.06 if hunter else 0, 0],
         'head': [-.13 if ragged else -.05, 0, 0],
         'upper_arm_l': [0, .28, 0], 'upper_arm_r': [0, -.28, 0],
         'forearm_l': [-.08, .06, 0], 'forearm_r': [-.08, -.06, 0]}
    root = Vector((0, 0, 0))
    def add(b, x=0, y=0, z=0):
        row = p.setdefault(b, [0, 0, 0])
        for i, v in enumerate((x, y, z)):
            row[i] += v
    # Hands hang around the modeled grips; the sternum breathes separately.
    if clip in ('idle', 'search'):
        breath = math.sin(t*math.tau)
        add('chest', .016*breath)
        add('head', -.012*breath, 0, .30*math.sin(t*math.tau) if clip == 'search' else .025*breath)
        add('upper_arm_l', .025*breath)
        add('upper_arm_r', -.018*breath)
    elif clip in ('walk', 'run'):
        # Analytic two-bone IK keeps the stance foot planted as the actor moves.
        # The actor advances this stride per cycle; runtime cadence uses distance.
        running = clip == 'run'
        stride = (1.65 if running else 1.05)*(.66 if hunter else 1)
        root.z = (-.145 if running else -.060)+.010*math.cos(t*math.tau*2)
        for side, offset in (('l', 0), ('r', .5)):
            phase = (t+offset) % 1
            swing = math.sin(phase*math.tau)
            if phase < .5:
                foot_y = -stride*.25+stride*phase
                lift = 0
            else:
                u = (phase-.5)*2
                foot_y = stride*.25-stride*.5*ease(u)
                lift = (.14 if running else .085)*math.sin(u*math.pi)**2
            down = .82+root.z-lift
            knee = -math.acos(max(-1, min(1, (foot_y**2+down**2-.39**2-.43**2)/(2*.39*.43))))
            hip = math.atan2(foot_y, down)-math.atan2(.43*math.sin(knee), .39+.43*math.cos(knee))
            add('thigh_'+side, hip)
            add('calf_'+side, knee)
            add('foot_'+side, -hip-knee)
            add('upper_arm_'+side, -.35*swing if running else -.18*swing)
            add('forearm_'+side, .15+(.10 if running else .04)*swing)
        add('pelvis', 0, .035*math.sin(t*math.tau), 0)
        add('chest', .08 if running else .025, 0, -.045*math.sin(t*math.tau))
    elif clip in ('telegraph', 'attack', 'recovery'):
        # The three clips share exact end poses: no reset between wind-up and hit.
        wind = {'upper_arm_r': (-1.30, -.20, -.20), 'forearm_r': (1.05, 0, 0),
                'chest': (-.14, 0, -.24), 'upper_arm_l': (-.30, .12, .15)}
        hit = {'upper_arm_r': (.58, .05, .25), 'forearm_r': (.18, 0, 0),
               'chest': (.22, 0, .25), 'upper_arm_l': (.12, 0, -.10)}
        if kind == 'hall_warden':
            wind.update({'upper_arm_r': (-2.1, -.15, 0), 'forearm_r': (.70, 0, 0),
                         'chest': (-.23, 0, -.10)})
            hit.update({'upper_arm_r': (.60, 0, 0), 'chest': (.38, 0, .10)})
        elif kind == 'hoard_keeper':
            wind.update({'upper_arm_r': (-.25, -.20, -.30), 'forearm_r': (1.25, 0, 0)})
            hit.update({'upper_arm_r': (-.95, 0, .10), 'forearm_r': (.05, 0, 0)})
        elif kind == 'sling_wretch':
            wind.update({'upper_arm_r': (-1.65, -.25, -.45), 'forearm_r': (.80, 0, -.15),
                         'chest': (-.08, 0, -.45)})
            hit.update({'upper_arm_r': (-.65, .10, .65), 'forearm_r': (.05, 0, 0),
                        'chest': (.20, 0, .40)})
        blend = ease(t)
        for bone in set(wind) | set(hit):
            a, b = wind.get(bone, (0, 0, 0)), hit.get(bone, (0, 0, 0))
            row = [v*blend for v in a] if clip == 'telegraph' else (
                [a[i]*(1-blend)+b[i]*blend for i in range(3)] if clip == 'attack'
                else [v*(1-blend) for v in b])
            add(bone, *row)
    elif clip in ('stagger', 'shrug'):
        jolt = math.sin(math.pi*t)*(1-t)
        add('chest', -.55*jolt if clip == 'stagger' else -.20*jolt, 0, .16*jolt)
        add('head', -.35*jolt)
        add('upper_arm_l', -.45*jolt)
        add('upper_arm_r', -.30*jolt)
        add('thigh_l', .20*jolt)
        add('calf_l', -.35*jolt)
    elif clip == 'death':
        fall = ease(t)
        add('root', -math.pi*.5*fall)
        add('chest', .18*math.sin(t*math.pi))
        add('upper_arm_l', 0, -.50*fall, -.15*fall)
        add('upper_arm_r', 0, .65*fall, .12*fall)
        add('calf_l', -.18*fall)
        add('head', .1*fall)
        root.z = .19*fall
    elif clip == 'call':
        lift = ease(min(1, t*3))
        shake = math.sin(t*math.tau*4)*.18*lift
        add('upper_arm_l', -1.35*lift)
        add('forearm_l', .45*lift+shake)
        add('hand_l', shake)
        add('upper_arm_r', -.80*lift)
        add('forearm_r', .70*lift-shake)
        add('head', -.22*lift)
        add('chest', -.10*lift)
    elif clip in ('collect', 'take'):
        # Reaching is a full-body action: knees yield as the chest folds.
        reach = .92+.07*math.sin(t*math.tau) if clip == 'collect' else ease(t)
        add('spine_01', .56*reach)
        add('chest', .60*reach)
        add('head', -.18*reach)
        for side in ('l', 'r'):
            add('thigh_'+side, .55*reach)
            add('calf_'+side, -1.0*reach)
            add('foot_'+side, .45*reach)
        add('upper_arm_r', -.80*reach)
        add('forearm_r', .35*reach)
        add('upper_arm_l', -.25*reach)
        root.z = -.15*reach
    return p, root


def animate(rig, kind):
    rig.animation_data_clear()
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    scene = bpy.context.scene
    scene.render.fps = 30
    rig.data.pose_position = 'POSE'
    rig.animation_data_create()
    for clip, seconds in clips_for(kind).items():
        action = bpy.data.actions.new(clip)
        rig.animation_data.action = action
        frames = int(seconds*30)
        for frame in range(frames+1):
            scene.frame_set(frame)
            offsets, translation = pose(kind, clip, frame/frames)
            for bone in rig.pose.bones:
                bone.rotation_mode = 'QUATERNION'
                bone.location = (0, 0, 0)
                angles = offsets.get(bone.name, (0, 0, 0))
                q = Quaternion((1, 0, 0), angles[0]) @ Quaternion((0, 1, 0), angles[1]) @ Quaternion((0, 0, 1), angles[2])
                rest = bone.bone.matrix_local.to_quaternion()
                bone.rotation_quaternion = rest.inverted() @ q @ rest
                if bone.name == 'root':
                    bone.location = rest.inverted() @ translation
                bone.keyframe_insert('rotation_quaternion', frame=frame, group=bone.name)
                if bone.name == 'root':
                    bone.keyframe_insert('location', frame=frame, group=bone.name)
        action['loop'] = clip in LOOPS
        action.use_fake_user = True
    rig.animation_data.action = None
    for bone in rig.pose.bones:
        bone.matrix_basis.identity()
    scene.frame_set(0)


def main():
    chosen = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else KINDS
    report_path = SRC/'animation_measurements.json'
    report = json.loads(report_path.read_text()) if report_path.exists() else {}
    for kind in chosen:
        folder = ROOT/'source_art'/('heroes' if kind == 'gullsjukr' else 'enemies')
        bpy.ops.wm.open_mainfile(filepath=str(folder/f'{kind}.blend'))
        bpy.context.preferences.filepaths.save_version = 0
        rig = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
        animate(rig, kind)
        bpy.ops.object.select_all(action='DESELECT')
        meshes = []
        release_meshes = []
        for obj in bpy.context.scene.objects:
            if obj.type == 'MESH' and any(m.type == 'ARMATURE' and m.object == rig for m in obj.modifiers):
                # glTF node names share a namespace with joints. A mesh named
                # forearm_l makes Godot rename the actual bone forearm_l_2.
                if obj.name in rig.data.bones:
                    obj.name = 'mesh_' + obj.name
                bm = bmesh.new()
                bm.from_mesh(obj.data)
                bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
                bm.to_mesh(obj.data)
                bm.free()
                if obj.name == 'sling_stone':
                    release_meshes.append(obj)
                else:
                    obj.select_set(True)
                    meshes.append(obj)
        # One skinned mesh, retaining separate material surfaces, avoids a draw
        # instance for every finger, rivet and coin in the authoring scene.
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()
        bpy.context.object.name = kind + '_body'
        for obj in release_meshes:
            obj.select_set(True)
        rig.select_set(True)
        bpy.context.view_layer.objects.active = rig
        bpy.ops.wm.save_as_mainfile(filepath=str(folder/f'{kind}.blend'))
        out = ROOT/'game/art'/('heroes' if kind == 'gullsjukr' else 'enemies')/f'{kind}.glb'
        bpy.ops.export_scene.gltf(filepath=str(out), export_format='GLB', use_selection=True,
            export_yup=True, export_apply=False, export_skins=True, export_def_bones=False,
            export_leaf_bone=False, export_animations=True, export_animation_mode='ACTIONS',
            export_frame_range=False, export_force_sampling=True,
            export_morph=False, export_cameras=False, export_lights=False,
            export_vertex_color='ACTIVE', export_attributes=True, export_extras=True)
        report[kind] = {'clips': clips_for(kind), 'loops': sorted(LOOPS & clips_for(kind).keys()), 'bones': len(rig.data.bones)}
        # Measure delivery geometry after joining; authoring part counts
        # do not describe the mesh instances imported by the engine.
        payload = out.read_bytes()
        size = struct.unpack_from('<I', payload, 12)[0]
        gltf = json.loads(payload[20:20+size])
        measurements_path = (folder/'gullsjukr_measurements.json' if kind == 'gullsjukr'
                             else SRC/'enemy_model_measurements.json')
        measurements = json.loads(measurements_path.read_text())
        row = measurements if kind == 'gullsjukr' else measurements[kind]
        row.update({
            'triangles': sum(gltf['accessors'][p['indices']]['count']//3
                for mesh in gltf['meshes'] for p in mesh['primitives']),
            'mesh_parts': len(gltf['meshes']),
            'bones': len(rig.data.bones), 'source_rig': 'humanoid_rig.blend'})
        measurements_path.write_text(json.dumps(measurements, indent=2)+'\n')
    report_path.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
