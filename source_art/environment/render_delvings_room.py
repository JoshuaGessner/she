"""Assemble the authored Band 1 pieces at metre scale for visual review.

This is a Blender review scene, not a second engine implementation of the kit.
Run after build_delvings.py using Blender --background --python.
"""
import bpy
import math
from pathlib import Path
from mathutils import Vector

HERE=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(HERE/'delvings_band_1.blend'))
scene=bpy.context.scene
assembly=bpy.data.collections.new('assembled_room')
scene.collection.children.link(assembly)
bpy.context.view_layer.active_layer_collection=bpy.context.view_layer.layer_collection.children[assembly.name]

def place(name,position,angle=0):
    source=bpy.data.collections[name]
    for obj in source.objects:
        if obj.hide_render:
            continue
        copy=obj.copy()
        copy.data=obj.data
        assembly.objects.link(copy)
        copy.location=position
        copy.rotation_euler.z=angle

for x in [-3,-1,1,3]:
    for y in [-2,0,2]:
        place('delvings_floor_2x2' if (x+y)%4 else 'delvings_floor_2x2_b',(x,y,0))
place('delvings_doorway',(0,3,.06))
for x in [-3,3]:
    place('delvings_wall_2x40',(x,3,.06))
for x in [-4,4]:
    for y in [-2,0,2]:
        place('delvings_wall_2x40_b' if y==0 else 'delvings_wall_2x40',(x,y,.06),math.pi/2)
for x in [-3,-1,1,3]:
    place('delvings_ceiling_2x2',(x,2,4.06))
for x in [-3.55,3.55]:
    place('delvings_pillar',(x,2.5,.06))

# The shared project rig provides an honest 1.80 m body in the doorway.
bpy.ops.import_scene.gltf(filepath=str(HERE.parents[1]/'game/art/characters/humanoid_rig.glb'))
rig_objects=list(bpy.context.selected_objects)
for obj in rig_objects:
    if obj.parent is None:
        obj.location+=Vector((.5,2.1,.06))

scene.render.engine='CYCLES'
scene.cycles.samples=48
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.5,.5,.5,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.35
for pos,energy,size in [((0,-3,8),1800,7),((-2,1,3.7),160,2),((0,5,3),500,3)]:
    bpy.ops.object.light_add(type='AREA',location=pos)
    light=bpy.context.object
    light.data.energy=energy
    light.data.shape='DISK'
    light.data.size=size
    light.rotation_euler=(Vector((0,1,0))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(.8,-8.7,3.2))
camera=bpy.context.object
camera.rotation_euler=(Vector((0,1,1.85))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.lens=31
scene.camera=camera
scene.view_settings.exposure=-.3
scene.render.resolution_x=1600
scene.render.resolution_y=1050
scene.render.resolution_percentage=100
scene.render.filepath=str(HERE/'delvings_room_review.png')
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'delvings_room_review.blend'))
bpy.ops.render.render(write_still=True)
