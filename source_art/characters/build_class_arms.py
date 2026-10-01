"""Six DES-020 class arm pairs, sharing the permanent humanoid bind pose.

**Closed fists around the grip** (ADR-280). The shared rig has hand bones and
no finger bones, so the fingers are posed once, in the mesh, and the pose that
matters in first person is the one holding something: every item the hands
carry is hung from `sock_hand_*`, so the fist is built around that socket's
axis. The old relaxed curl left the handle running through the middle of the
palm and read, from the seat, as a claw or a cuff. The forearm and wrist still
deform with the actual shared animation skeleton. Never add a competing armature
hierarchy.
"""
import sys
import math
import json
from pathlib import Path
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_worn_armour as a

a.PALETTE.update({
    'skin': ((.57,.49,.40,1),.8),
    'scar': ((.36,.29,.24,1),.8),
    'ink': ((.11,.105,.10,1),.8),
    'bone': ((.66,.63,.53,1),.8),
    'fur': ((.24,.22,.19,1),.8),
    'nail': ((.48,.44,.36,1),.8),
})


def tube(name, points, radii, kind, weights, n=12, smooth=True):
    rows=[]
    for j,(p,r) in enumerate(zip(points,radii)):
        p=Vector(p)
        tangent=Vector(points[min(j+1,len(points)-1)])-Vector(points[max(0,j-1)])
        tangent.normalize()
        ref=Vector((0,1,0)) if abs(tangent.y)<.95 else Vector((1,0,0))
        u=tangent.cross(ref).normalized(); v=tangent.cross(u).normalized()
        rows.append([p+r*(math.cos(t)*u+math.sin(t)*v) for t in [i*math.tau/n for i in range(n)]])
    vertices=[v for row in rows for v in row]
    faces=[(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i)
           for j in range(len(rows)-1) for i in range(n)]
    # Fingers and wrist tools are solid; open tube tips read as missing skin.
    faces += [tuple(reversed(range(n))),
              tuple((len(rows)-1)*n+i for i in range(n))]
    obj=a.skin_mesh(name,vertices,faces,kind,weights,smooth=smooth)
    obj.data.polygons[-2].use_smooth=False
    obj.data.polygons[-1].use_smooth=False
    return obj


def build(kind):
    for side in ('l','r'):
        start,end,front,across=a.limb_basis(side,'forearm')
        axis=(end-start).normalized()
        bone=f'forearm_{side}'; hand=f'hand_{side}'
        # The silhouette narrows through the wrist instead of ending in a tube.
        rows=[]
        for t,rx,ry in ((-.07,.046,.040),(.05,.046,.042),(.23,.046,.040),
                       (.46,.042,.036),(.70,.035,.031),(.88,.029,.025),(1.01,.029,.024)):
            c=start.lerp(end,t)
            rows.append([c+front*(ry*math.cos(v))+across*(rx*math.sin(v))
                         for v in [i*math.tau/24 for i in range(24)]])
        def weights(p, end=end,axis=axis,bone=bone,hand=hand):
            t=max(0,min(1,((p-end).dot(axis)+.035)/.065))
            return {bone:1-t,hand:t}
        a.loft(f'{kind}_forearm_{side}',rows,'skin',weights,smooth=True)
        # **A fist around the socket** (ADR-280). `u` runs down the hand bone,
        # `w` is the grip axis (the socket's own forward, character-forward is
        # -w), and `n` is the back of the hand. `n` is mirrored per side: the
        # old curl used one cross product for both hands and closed the left
        # hand's fingers outward.
        h=a.RIG.data.bones[hand]
        origin=h.head_local.copy(); u=(h.tail_local-origin).normalized()
        w=Vector((0,1,0))
        n=w.cross(u).normalized()*(1 if side=='r' else -1)
        sock=a.RIG.data.bones[f'sock_hand_{side}'].head_local
        grip=origin+u*(sock-origin).dot(u)
        handle=.016; finger_r=.0105; wrap=handle+finger_r
        def around(theta, along):
            return grip+w*along+wrap*(math.cos(theta)*u+math.sin(theta)*n)
        # The palm: from the wrist, where it meets the forearm's own size, out
        # to the knuckles on the back of the fist, broadening as it goes.
        knuckle=around(math.radians(96),0)+n*.004
        rows=[]
        for t,hw,ht in ((0,.030,.023),(.22,.038,.022),(.5,.043,.020),(.8,.045,.019),(1.0,.044,.017)):
            c=(origin-u*.03).lerp(knuckle,t)
            rows.append([c+w*(hw*math.sin(v))+n*(ht*math.cos(v))
                         for v in [i*math.tau/22 for i in range(22)]])
        a.loft(f'{kind}_palm_{side}',rows,'skin',{hand:1},smooth=True)
        # Four fingers closed round the handle: from the knuckle over the far
        # side of the grip and tucked back under it, index at the blade end.
        ends=(-122,-116,-110,-100)
        for j,along in enumerate((-.031,-.0105,.0105,.030)):
            thetas=[math.radians(96+(ends[j]-96)*k/6) for k in range(7)]
            points=[around(t,along) for t in thetas]
            radii=[.0115,.0112,.0108,.0104,.0098,.009,.0078]
            if j==3:
                radii=[r*.9 for r in radii]
            tube(f'{kind}_finger_{side}_{j}',points,radii,
                 'ink' if kind=='skald' and j<3 else 'skin',{hand:1},10)
        # The thumb comes round the palm side from the heel of the hand and
        # locks over the first two fingers — the part of a grip you can see.
        g=grip
        tube(f'{kind}_thumb_{side}',[origin+u*.004-w*.030-n*.010,
             g-u*.020-w*.040-n*.022, g-u*.004-w*.036-n*(wrap+.006),
             g+u*.010-w*.022-n*(wrap+.008), g+u*.016-w*.006-n*(wrap+.004)],
             [.0145,.0135,.012,.0105,.008],'skin',{hand:1})

        def ring(t,r):
            c=start.lerp(end,t)
            return [c+r*(front*math.cos(v)+across*math.sin(v)) for v in [i*math.tau/28 for i in range(28)]]
        if kind=='huskarl':
            # Raised, pale healed cuts across the dorsal forearm, kept clear
            # of the bracer's silhouette rather than sculpting noisy pores.
            for t in (.35,.46):
                c=start.lerp(end,t)+front*.038
                a.skin_mesh(f'healed_cut_{side}_{t}',[c+across*x+axis*z for x,z in
                    ((-.021,-.008),(.020,.008),(.020,.011),(-.021,-.005))],[(0,1,2,3)],'scar',{bone:1})
        elif kind=='veidimadr':
            # Finger tabs protect the draw fingers without a full glove —
            # over the first joint, where the string sits.
            for j,along in enumerate((-.031,-.0105,.0105)):
                tube(f'draw_finger_wrap_{side}_{j}',[around(math.radians(92),along),
                     around(math.radians(40),along)], [.0128,.0124], 'linen',{hand:1},10)
            a.loft(f'draw_wrist_tape_{side}',[ring(.92,.032),ring(.98,.031)],'linen',weights)
        elif kind=='volva':
            a.loft(f'inked_wrist_band_{side}',[ring(.91,.032),ring(.935,.032)],'ink',weights)
            for j in range(3):
                c=end+front*.028+across*((j-1)*.020)
                tube(f'bone_charm_{side}_{j}',[c,c+axis*.03], [.006,.003],'bone',{hand:1},8,False)
            for t in (.35,.55,.70):
                c=start.lerp(end,t)+front*(.043-.018*t)
                a.skin_mesh(f'ink_mark_{side}_{t}',[c+across*x+axis*z for x,z in
                    ((-.012,-.010),(0,.010),(.012,-.01),(0,-.004))],[(0,1,2,3)],'ink',{bone:1})
        elif kind=='ulfhedinn':
            rows=[]
            for t,r in ((.91,.034),(1.08,.034)):
                c=start.lerp(end,t)
                rows.append([c+(r+.005*(i%3))*(front*math.cos(v)+across*math.sin(v))
                             +axis*(.007*(i%2)) for i,v in enumerate([i*math.tau/28 for i in range(28)])])
            a.loft(f'fur_wrist_wrap_{side}',rows,'fur',weights)
        elif kind=='haugbrjotr':
            a.loft(f'grave_worker_cuff_{side}',[ring(.90,.034),ring(1.02,.032)],'leather',weights)
            for j in (-1,1):
                c=end+across*(j*.021)+front*.027
                tube(f'wrist_pick_{side}_{j}',[c-axis*.03,c+axis*.035],[.004,.0015],'iron',{hand:1},6,False)
        elif kind=='skald':
            a.loft(f'stained_wrist_tie_{side}',[ring(.91,.032),ring(.945,.031)],'linen',weights)


def main():
    report={}
    for kind in ('huskarl','veidimadr','volva','skald','ulfhedinn','haugbrjotr'):
        a.begin(); build(kind); report[kind]=a.export(f'{kind}_arms')
        # Review bare-arm shape close enough to read the fingers and class work.
        scene=bpy.context.scene
        scene.render.engine='CYCLES'; scene.cycles.samples=24
        scene.render.resolution_x=1100; scene.render.resolution_y=700
        scene.render.resolution_percentage=100
        scene.world.color=(.35,.35,.35)
        for loc,power in (((-2,-3,4),650),((3,1,3),550)):
            bpy.ops.object.light_add(type='AREA',location=loc)
            o=bpy.context.object;o.data.energy=power;o.data.size=3
            o.rotation_euler=(Vector((0,0,1.2))-o.location).to_track_quat('-Z','Y').to_euler()
        bpy.ops.object.camera_add(location=(.9,-3,2))
        camera=bpy.context.object;scene.camera=camera
        camera.rotation_euler=(Vector((0,0,1.17))-camera.location).to_track_quat('-Z','Y').to_euler()
        camera.data.type='ORTHO';camera.data.ortho_scale=1.30
        scene.render.filepath=str(a.SRC/f'{kind}_arms_review.png')
        bpy.ops.render.render(write_still=True)
    (a.SRC/'class_arms_measurements.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':
    main()
