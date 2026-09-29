"""Six DES-020 class arm pairs, sharing the permanent humanoid bind pose.

Fingers are authored in a relaxed carrying curl: the shared production rig has
hand bones rather than finger bones. The forearm and wrist still deform with
the actual shared animation skeleton. Never add a competing armature hierarchy.
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
        # Palm and four separated fingers curl toward the palm, with visible
        # knuckles. Their common hand weight follows the rig's grip exactly.
        h=a.RIG.data.bones[hand]
        origin=h.head_local.copy(); direction=(h.tail_local-origin).normalized()
        width=Vector((0,1,0))
        palm_normal=width.cross(direction).normalized()
        rows=[]
        for t,w,d in ((-.012,.027,.023),(.01,.032,.023),(.04,.038,.026),
                      (.065,.035,.021),(.075,.030,.014)):
            c=origin+direction*t
            rows.append([c+width*(w*math.sin(v))+palm_normal*(d*math.cos(v))
                         for v in [i*math.tau/20 for i in range(20)]])
        a.loft(f'{kind}_palm_{side}',rows,'skin',{hand:1},smooth=True)
        for j,offset in enumerate((-.027,-.009,.009,.027)):
            length=(.050,.058,.055,.043)[j]
            root=origin+direction*.060+width*offset
            points=[root,root+direction*(length*.44),root+direction*(length*.77)-palm_normal*.013,
                    root+direction*(length*.73)-palm_normal*.033,root+direction*(length*.48)-palm_normal*.039]
            tube(f'{kind}_finger_{side}_{j}',points,[.009,.010,.009,.008,.0035],
                 'ink' if kind=='skald' and j<3 else 'skin',{hand:1},10)
        root=origin+direction*.015+width*.028
        tube(f'{kind}_thumb_{side}',[root,root+width*.022+direction*.018,
             root+width*.024+direction*.043-palm_normal*.014,
             root+width*.01+direction*.052-palm_normal*.022], [.015,.013,.011,.005],'skin',{hand:1})

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
            # Finger tabs protect the draw fingers without a full glove.
            for j,off in enumerate((-.027,-.009,.009)):
                root=origin+direction*.062+width*off
                tube(f'draw_finger_wrap_{side}_{j}',[root,root+direction*.026], [.011,.0105], 'linen',{hand:1},10)
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
