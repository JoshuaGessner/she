"""Bake shared-rig enemy performances; combat clips use normalized phase time.

The engine owns displacement and hit timing. These clips never move the actor
through the world: walk/run are distance-driven, events are sampled by the
authoritative gameplay phase. All six exports retain the permanent bind pose.
Run in Blender after build_enemies.py, which builds all six.
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
CLIPS = {'idle': 6, 'search': 3, 'walk': 1, 'run': 1, 'strafe': 1, 'telegraph': 1,
         'attack': 1, 'recovery': 1, 'stagger': 1, 'death': 1,
         'call': 1, 'collect': 1, 'take': 1, 'shrug': 1}
LOOPS = {'idle', 'search', 'walk', 'run', 'strafe', 'collect'}
PHASES = ('telegraph', 'attack', 'recovery')
# **A second blow per archetype** (ADR-391): each is a family of three clips,
# `<family>_telegraph`, `<family>_attack` and `<family>_recovery`, named by the
# blow's `AttackResource.clip`, so a lunge never plays as a swipe.
FAMILIES = {'wretch': ('lunge',), 'bellringer': ('lunge',),
            'hall_warden': ('shove',), 'hoard_keeper': ('sweep',)}


def clips_for(kind):
    names = (('idle', 'search', 'walk', 'run', 'collect', 'take', 'shrug')
             if kind == 'gullsjukr' else
             ('idle', 'search', 'walk', 'run', 'strafe', 'telegraph', 'attack', 'recovery', 'stagger', 'death'))
    if kind == 'bellringer':
        names += ('call',)
    clips = {name: CLIPS[name] for name in names}
    for family in FAMILIES.get(kind, ()):
        for phase in PHASES:
            clips[family + '_' + phase] = 1
    return clips


def family_blow(family):
    """Wind-up and strike poses for a second blow, in the same world-axis
    offsets as the swing: x leans or raises forward, z twists the trunk."""
    if family == 'lunge':
        # Coiled low with the weight back, then the whole body thrown forward:
        # the front leg reaches, the back leg drives, the knife arm leads.
        wind = {'spine_01': (-.10, 0, 0), 'chest': (-.18, 0, -.30),
                'upper_arm_r': (-.95, -.30, -.35), 'forearm_r': (1.25, 0, 0),
                'upper_arm_l': (.25, .30, .20), 'thigh_l': (-.35, 0, 0),
                'calf_l': (.55, 0, 0), 'thigh_r': (-.30, 0, 0), 'calf_r': (.65, 0, 0)}
        hit = {'spine_01': (.30, 0, 0), 'chest': (.40, 0, .20),
               'upper_arm_r': (.95, .05, .15), 'forearm_r': (.10, 0, 0),
               'upper_arm_l': (-.55, .20, -.10), 'thigh_l': (-.75, 0, 0),
               'calf_l': (.35, 0, 0), 'thigh_r': (.45, 0, 0), 'calf_r': (.20, 0, 0)}
        return wind, hit, -.10
    if family == 'shove':
        # Dead armour lowering its shoulder, then both arms driving forward:
        # a blocker making room for the overhead.
        wind = {'chest': (-.10, 0, .35), 'upper_arm_l': (-.35, .40, .30),
                'forearm_l': (1.10, 0, 0), 'upper_arm_r': (-.25, -.35, -.10),
                'forearm_r': (1.00, 0, 0), 'thigh_r': (-.25, 0, 0), 'calf_r': (.40, 0, 0)}
        hit = {'chest': (.35, 0, -.10), 'upper_arm_l': (-1.30, .10, .05),
               'forearm_l': (.15, 0, 0), 'upper_arm_r': (-1.25, -.10, -.05),
               'forearm_r': (.15, 0, 0), 'thigh_l': (-.40, 0, 0), 'calf_l': (.25, 0, 0)}
        return wind, hit, -.04
    # 'sweep': the haft drawn far round to the right, then a flat arc across.
    wind = {'chest': (-.05, 0, -.75), 'spine_01': (0, 0, -.25),
            'upper_arm_r': (-.55, -.85, -.40), 'forearm_r': (.55, 0, 0),
            'upper_arm_l': (-.45, .25, -.40), 'forearm_l': (.70, 0, 0)}
    hit = {'chest': (.10, 0, .80), 'spine_01': (0, 0, .30),
           'upper_arm_r': (-.80, .85, .45), 'forearm_r': (.15, 0, 0),
           'upper_arm_l': (-.60, -.30, .45), 'forearm_l': (.30, 0, 0)}
    return wind, hit, -.08


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
    if clip == 'idle':
        idle(kind, t, add)
    elif clip == 'search':
        breath = math.sin(t*math.tau)
        add('chest', .016*breath)
        add('head', -.012*breath, 0, .30*math.sin(t*math.tau))
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
    elif clip == 'strafe':
        # **A side-step** (ADR-391), for a body holding its ring: facing its
        # target and moving to its own left across it. One cycle is the left
        # foot stepping out and the right brought in beside it — never crossed
        # — with the planted foot sliding under the body at the speed the body
        # travels, so it stays put on the floor. Played reversed, the right
        # foot leads and the body goes right. The same two-bone IK as the walk,
        # solved in the sideways plane: a thigh's +Y swings its foot to the
        # body's right, measured on the baked rig.
        side_step = .30  # each foot's travel per step; a cycle covers twice this
        open_ = .5 - .5 * math.cos(t * math.tau)
        root.z = -.065 - .025 * open_
        for side, offset, sign in (('l', 0, 1), ('r', .5, -1)):
            phase = (t + offset) % 1
            if phase < .5:
                u = phase * 2
                reach = ease(u)
                lift = .075 * math.sin(u * math.pi) ** 2
            else:
                reach = 1 - (phase - .5) * 2
                lift = 0
            # Out from the hip toward the body's left, the leading foot reaching
            # .26 and the trailing one closing to within .04 of the leader.
            if side == 'l':
                out = -.04 + side_step * reach
            else:
                out = -.26 + side_step * reach
            down = .82 + root.z - lift
            span = math.hypot(out, down)
            knee = -math.acos(max(-1, min(1, (span**2 - .39**2 - .43**2) / (2 * .39 * .43))))
            hip = -math.atan2(.43 * math.sin(knee), .39 + .43 * math.cos(knee))
            add('thigh_' + side, hip, -math.atan2(out, down), 0)
            add('calf_' + side, knee)
            add('foot_' + side, -hip - knee)
            add('upper_arm_' + side, -.22, .06 * sign, 0)
            add('forearm_' + side, .38)
        # Weight rides over the planted foot.
        add('pelvis', 0, .04 * math.sin(t * math.tau), 0)
        add('chest', .10, -.03 * math.sin(t * math.tau), 0)
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
    elif '_' in clip and clip.split('_', 1)[1] in PHASES:
        family, phase = clip.split('_', 1)
        wind, hit, drop = family_blow(family)
        blend = ease(t)
        for bone in set(wind) | set(hit):
            a, b = wind.get(bone, (0, 0, 0)), hit.get(bone, (0, 0, 0))
            row = [v*blend for v in a] if phase == 'telegraph' else (
                [a[i]*(1-blend)+b[i]*blend for i in range(3)] if phase == 'attack'
                else [v*(1-blend) for v in b])
            add(bone, *row)
        # The body sinks into the wind-up and rises out of the recovery, so
        # the coil reads from across a room as well as up close.
        sink = blend if phase == 'telegraph' else (1.0 if phase == 'attack' else 1-blend)
        root.z = drop*sink
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


def idle(kind, t, add):
    """**A body standing still is not still** (ADR-302). Six seconds, three
    breaths, one shift of weight from foot to foot, a glance each way — and a
    habit of its own per kind, so a room of them reads as several creatures
    rather than one pose copied. Every term is periodic in `t` with a whole
    number of cycles, so the loop has no seam.

    Axes are the world's, as `pose` uses them: x pitches forward, y rolls
    about the facing, z turns."""
    w = math.tau
    breath = math.sin(3*w*t)
    shift = math.sin(w*t)
    # A glance that lingers at each end: the turn eases rather than swings.
    glance = math.sin(w*t) + .35*math.sin(3*w*t)
    # Weight onto one hip: the pelvis rolls, the far knee eases, the chest
    # counters so the head stays over the feet.
    add('pelvis', 0, .045*shift, 0)
    add('spine_01', 0, -.03*shift, 0)
    add('chest', .018*breath, -.02*shift, 0)
    add('thigh_l', -.03*max(0.0, shift))
    add('calf_l', .07*max(0.0, shift))
    add('thigh_r', -.03*max(0.0, -shift))
    add('calf_r', .07*max(0.0, -shift))
    add('upper_arm_l', .02*breath)
    add('upper_arm_r', -.015*breath)
    if kind in ('wretch', 'sling_wretch'):
        # Twitchy: quick small turns of the head, a shoulder that hitches,
        # fingers that will not settle.
        add('head', -.02*breath, .10*math.sin(2*w*t)**3, .22*glance)
        add('upper_arm_r', -.08*max(0.0, math.sin(4*w*t))**4)
        add('forearm_l', .10*math.sin(5*w*t))
        add('forearm_r', .06*math.sin(4*w*t + 1.0))
    elif kind == 'bellringer':
        # Fretful with the bell: it rocks the hand that holds it.
        add('head', -.02*breath, .05*math.sin(2*w*t), .18*glance)
        add('forearm_l', .14*math.sin(2*w*t))
        add('hand_l', .20*math.sin(2*w*t + .6))
    elif kind == 'hall_warden':
        # Stoic: a slow heavy breath, a guard that does not move, and a scan
        # across the hall rather than a glance.
        add('chest', .022*breath)
        add('head', -.015*breath, 0, .12*math.sin(w*t))
    elif kind == 'hoard_keeper':
        # Hunched over what it carries, one hand patting at it.
        add('spine_01', .06)
        add('chest', .05)
        add('head', -.03*breath, 0, .14*glance)
        add('forearm_l', .16*max(0.0, math.sin(3*w*t))**2)
    elif kind == 'gullsjukr':
        # Weary under the gold: the shoulders sag and lift on a long breath,
        # and the head hangs and comes up.
        heave = math.sin(w*t)
        add('chest', .06*heave)
        add('head', .10 + .08*heave, 0, .10*glance)
        add('upper_arm_l', 0, -.05*heave, 0)
        add('upper_arm_r', 0, .05*heave, 0)


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
