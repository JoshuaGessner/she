"""Build Project SHE's permanent shared humanoid rig in Blender.

Run with:
    Blender --background --factory-startup --python build_humanoid_rig.py

The dimensions and names in this file are production contracts. Change them only
alongside the corresponding accepted design decision.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
BLEND_PATH = SCRIPT_DIR / "humanoid_rig.blend"
GLB_PATH = REPO_ROOT / "game" / "assets" / "characters" / "humanoid_rig.glb"

TOTAL_HEIGHT_M = 1.80
EYE_HEIGHT_M = 1.62
SHOULDER_WIDTH_M = 0.48
CAPSULE_RADIUS_M = 0.35
SOCKET_LENGTH_M = 0.06

SOCKET_POSITIONS = {
    "sock_head": (0.0, -0.095, 1.62),
    "sock_hand_r": (-0.46, -0.035, 1.065),
    "sock_hand_l": (0.46, -0.035, 1.065),
    "sock_back": (0.0, 0.155, 1.35),
    "sock_hip_r": (-0.19, 0.03, 0.98),
    "sock_hip_l": (0.19, 0.03, 0.98),
    "sock_shoulders": (0.0, 0.06, 1.45),
}

SOCKET_PARENTS = {
    "sock_head": "head",
    "sock_hand_r": "hand_r",
    "sock_hand_l": "hand_l",
    "sock_back": "chest",
    "sock_hip_r": "pelvis",
    "sock_hip_l": "pelvis",
    "sock_shoulders": "chest",
}


def clear_scene() -> None:
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.armatures,
        bpy.data.meshes,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def configure_scene() -> None:
    scene = bpy.context.scene
    bpy.context.preferences.filepaths.save_version = 0
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.unit_settings.length_unit = "METERS"
    scene.render.engine = "BLENDER_EEVEE"
    scene.world.color = (0.035, 0.035, 0.035)
    scene["rig_forward_axis_blender"] = "-Y"
    scene["rig_up_axis_blender"] = "+Z"
    scene["godot_node_forward_axis"] = "-Z"
    scene["godot_oriented_asset_front_axis"] = "+Z (glTF asset convention)"
    scene["export_up_axis_godot"] = "+Y"


def add_bone(
    edit_bones,
    name: str,
    head,
    tail,
    parent=None,
    *,
    connected: bool = False,
    deform: bool = True,
    roll: float = 0.0,
):
    bone = edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    bone.parent = parent
    bone.use_connect = connected
    bone.use_deform = deform
    bone.roll = roll
    return bone


def create_armature():
    armature_data = bpy.data.armatures.new("humanoid_skeleton")
    armature = bpy.data.objects.new("humanoid_rig", armature_data)
    bpy.context.collection.objects.link(armature)
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    armature.show_in_front = True
    armature.display_type = "WIRE"
    armature_data.display_type = "BBONE"
    armature_data.show_names = True
    armature_data.axes_position = 0.0
    armature_data.pose_position = "REST"

    armature["standing_height_m"] = TOTAL_HEIGHT_M
    armature["crouched_collider_height_m"] = 1.15
    armature["body_capsule_radius_m"] = CAPSULE_RADIUS_M
    armature["eye_height_m"] = EYE_HEIGHT_M
    armature["shoulder_width_m"] = SHOULDER_WIDTH_M
    armature["socket_axis_convention"] = "-Z forward, +Y up"
    armature["camera_parenting"] = "forbidden; sock_head is equipment-only"

    bpy.ops.object.mode_set(mode="EDIT")
    eb = armature_data.edit_bones

    root = add_bone(eb, "root", (0, 0, 0), (0, 0, 0.12), deform=False)
    pelvis = add_bone(eb, "pelvis", (0, 0, 0.90), (0, 0, 1.04), root)
    spine_01 = add_bone(
        eb, "spine_01", (0, 0, 1.04), (0, 0, 1.22), pelvis, connected=True
    )
    spine_02 = add_bone(
        eb, "spine_02", (0, 0, 1.22), (0, 0, 1.38), spine_01, connected=True
    )
    chest = add_bone(
        eb, "chest", (0, 0, 1.38), (0, 0, 1.48), spine_02, connected=True
    )
    neck = add_bone(
        eb, "neck", (0, 0, 1.48), (0, 0, 1.56), chest, connected=True
    )
    head = add_bone(
        eb, "head", (0, 0, 1.56), (0, 0, 1.78), neck, connected=True
    )

    clavicle_r = add_bone(
        eb, "clavicle_r", (0, 0, 1.45), (-0.18, 0, 1.48), chest
    )
    upper_arm_r = add_bone(
        eb,
        "upper_arm_r",
        (-0.18, 0, 1.48),
        (-0.31, 0, 1.35),
        clavicle_r,
        connected=True,
    )
    forearm_r = add_bone(
        eb,
        "forearm_r",
        (-0.31, 0, 1.35),
        (-0.42, 0, 1.10),
        upper_arm_r,
        connected=True,
    )
    hand_r = add_bone(
        eb,
        "hand_r",
        (-0.42, 0, 1.10),
        (-0.50, 0, 1.03),
        forearm_r,
        connected=True,
    )

    clavicle_l = add_bone(
        eb, "clavicle_l", (0, 0, 1.45), (0.18, 0, 1.48), chest
    )
    upper_arm_l = add_bone(
        eb,
        "upper_arm_l",
        (0.18, 0, 1.48),
        (0.31, 0, 1.35),
        clavicle_l,
        connected=True,
    )
    forearm_l = add_bone(
        eb,
        "forearm_l",
        (0.31, 0, 1.35),
        (0.42, 0, 1.10),
        upper_arm_l,
        connected=True,
    )
    hand_l = add_bone(
        eb,
        "hand_l",
        (0.42, 0, 1.10),
        (0.50, 0, 1.03),
        forearm_l,
        connected=True,
    )

    thigh_r = add_bone(eb, "thigh_r", (-0.09, 0, 0.94), (-0.09, 0, 0.55), pelvis)
    calf_r = add_bone(
        eb, "calf_r", (-0.09, 0, 0.55), (-0.09, 0, 0.12), thigh_r, connected=True
    )
    add_bone(
        eb,
        "foot_r",
        (-0.09, 0, 0.12),
        (-0.09, -0.18, 0.05),
        calf_r,
        connected=True,
    )

    thigh_l = add_bone(eb, "thigh_l", (0.09, 0, 0.94), (0.09, 0, 0.55), pelvis)
    calf_l = add_bone(
        eb, "calf_l", (0.09, 0, 0.55), (0.09, 0, 0.12), thigh_l, connected=True
    )
    add_bone(
        eb,
        "foot_l",
        (0.09, 0, 0.12),
        (0.09, -0.18, 0.05),
        calf_l,
        connected=True,
    )

    # A vertical edit bone has local +Y along world +Z. A deliberate pi roll
    # makes its local -Z point along Blender -Y (character forward).
    for socket_name, position in SOCKET_POSITIONS.items():
        socket_head = Vector(position)
        add_bone(
            eb,
            socket_name,
            socket_head,
            socket_head + Vector((0, 0, SOCKET_LENGTH_M)),
            eb[SOCKET_PARENTS[socket_name]],
            deform=False,
            roll=math.pi,
        )

    bpy.ops.object.mode_set(mode="OBJECT")

    deform_collection = armature_data.collections.new("Deform")
    socket_collection = armature_data.collections.new("Sockets")
    for bone in armature_data.bones:
        if bone.name.startswith("sock_"):
            socket_collection.assign(bone)
        else:
            deform_collection.assign(bone)

    return armature


def apply_object_transforms(obj) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.select_set(False)


def weight_whole_object(obj, bone_name: str) -> None:
    group = obj.vertex_groups.new(name=bone_name)
    group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")


def add_sphere(name: str, center, scale, weight_bone: str):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=16, ring_count=8, radius=1.0, location=center
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    apply_object_transforms(obj)
    weight_whole_object(obj, weight_bone)
    return obj


def add_box(name: str, center, dimensions, weight_bone: str):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    apply_object_transforms(obj)
    weight_whole_object(obj, weight_bone)
    return obj


def add_limb(name: str, start, end, radius: float, weight_bone: str):
    start_v = Vector(start)
    end_v = Vector(end)
    direction = end_v - start_v
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=12,
        radius=radius,
        depth=direction.length,
        end_fill_type="NGON",
        location=(start_v + end_v) * 0.5,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(direction.normalized())
    apply_object_transforms(obj)
    weight_whole_object(obj, weight_bone)
    return obj


def create_proxy(armature):
    pieces = []
    pieces += [add_sphere("proxy_pelvis", (0, 0, 0.98), (0.17, 0.11, 0.14), "pelvis")]
    pieces += [add_sphere("proxy_abdomen", (0, 0, 1.17), (0.15, 0.10, 0.19), "spine_01")]
    pieces += [add_sphere("proxy_chest", (0, 0, 1.37), (0.20, 0.12, 0.18), "chest")]
    pieces += [add_sphere("proxy_deltoid_r", (0.18, 0, 1.47), (0.06, 0.07, 0.07), "upper_arm_r")]
    pieces += [add_sphere("proxy_deltoid_l", (-0.18, 0, 1.47), (0.06, 0.07, 0.07), "upper_arm_l")]
    pieces += [add_limb("proxy_neck", (0, 0, 1.47), (0, 0, 1.58), 0.055, "neck")]
    pieces += [add_sphere("proxy_head", (0, 0, 1.67), (0.10, 0.09, 0.13), "head")]
    pieces += [add_box("proxy_nose", (0, -0.10, 1.635), (0.035, 0.04, 0.045), "head")]

    # Facing Blender -Y, anatomical right is -X and left is +X.
    for side, sign in (("r", -1.0), ("l", 1.0)):
        shoulder = (0.18 * sign, 0, 1.48)
        elbow = (0.31 * sign, 0, 1.35)
        wrist = (0.42 * sign, 0, 1.10)
        palm = (0.50 * sign, 0, 1.03)
        pieces += [add_limb(f"proxy_upper_arm_{side}", shoulder, elbow, 0.045, f"upper_arm_{side}")]
        pieces += [add_limb(f"proxy_forearm_{side}", elbow, wrist, 0.043, f"forearm_{side}")]
        pieces += [add_sphere(f"proxy_hand_{side}", (0.46 * sign, -0.012, 1.065), (0.065, 0.043, 0.075), f"hand_{side}")]

        hip = (0.09 * sign, 0, 0.94)
        knee = (0.09 * sign, 0, 0.55)
        ankle = (0.09 * sign, 0, 0.12)
        pieces += [add_limb(f"proxy_thigh_{side}", hip, knee, 0.082, f"thigh_{side}")]
        pieces += [add_limb(f"proxy_calf_{side}", knee, ankle, 0.065, f"calf_{side}")]
        pieces += [add_box(f"proxy_foot_{side}", (0.09 * sign, -0.075, 0.05), (0.13, 0.25, 0.10), f"foot_{side}")]

    bpy.ops.object.select_all(action="DESELECT")
    for obj in pieces:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    bpy.ops.object.join()
    proxy = bpy.context.object
    proxy.name = "proxy_body"
    proxy.data.name = "proxy_body_mesh"

    for polygon in proxy.data.polygons:
        polygon.use_smooth = False

    color = proxy.data.color_attributes.new(
        name="Color", type="BYTE_COLOR", domain="CORNER"
    )
    for datum in color.data:
        datum.color = (1.0, 0.5, 0.0, 1.0)
    proxy.data.color_attributes.active_color = color

    material = bpy.data.materials.new("proxy_grey")
    material.diffuse_color = (0.42, 0.44, 0.47, 1.0)
    material.metallic = 0.0
    material.roughness = 1.0
    proxy.data.materials.append(material)

    modifier = proxy.modifiers.new(name="humanoid_rig", type="ARMATURE")
    modifier.object = armature
    modifier.use_vertex_groups = True
    proxy.parent = armature
    proxy.matrix_parent_inverse.identity()
    proxy["proxy_purpose"] = "rig placement and measurement only; not character art"
    proxy["vertex_color_contract"] = "R=1.0, G=0.5, B=0.0"

    bpy.context.view_layer.objects.active = proxy
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return proxy


def assert_identity_transform(obj) -> None:
    assert obj.location.length < 1e-7, f"{obj.name}: unapplied location {obj.location}"
    assert all(abs(v) < 1e-7 for v in obj.rotation_euler), (
        f"{obj.name}: unapplied rotation {obj.rotation_euler}"
    )
    assert all(abs(v - 1.0) < 1e-7 for v in obj.scale), (
        f"{obj.name}: unapplied scale {obj.scale}"
    )


def validate_in_blender(armature, proxy) -> None:
    assert_identity_transform(armature)
    assert_identity_transform(proxy)

    socket_names = sorted(
        bone.name for bone in armature.data.bones if bone.name.startswith("sock_")
    )
    assert socket_names == sorted(SOCKET_POSITIONS), socket_names
    assert not any(name in armature.data.bones for name in ("sock_body", "sock_arms"))
    banned_fragments = ("camera", "eye", "view")
    assert not any(
        fragment in bone.name.lower()
        for bone in armature.data.bones
        for fragment in banned_fragments
    )

    socket_weight_groups = [
        group.name for group in proxy.vertex_groups if group.name.startswith("sock_")
    ]
    assert socket_weight_groups == [], socket_weight_groups
    assert "sock_shoulders" not in proxy.vertex_groups

    minimum_z = min((proxy.matrix_world @ Vector(corner)).z for corner in proxy.bound_box)
    maximum_z = max((proxy.matrix_world @ Vector(corner)).z for corner in proxy.bound_box)
    measured_height = maximum_z - minimum_z
    assert abs(minimum_z) < 1e-6, minimum_z
    assert abs(measured_height - TOTAL_HEIGHT_M) <= 0.001, measured_height

    head_socket = armature.data.bones["sock_head"]
    assert abs(head_socket.head_local.z - EYE_HEIGHT_M) <= 0.001

    # The upper-arm cylinders and deltoid proxies are the only vertices assigned
    # to upper_arm_*; their rest-pose X bounds enforce the collider constraint.
    for group_name in ("upper_arm_l", "upper_arm_r"):
        group = proxy.vertex_groups[group_name]
        xs = []
        for vertex in proxy.data.vertices:
            if any(link.group == group.index and link.weight > 0 for link in vertex.groups):
                xs.append(abs(vertex.co.x))
        assert xs and max(xs) <= CAPSULE_RADIUS_M + 1e-6, (group_name, max(xs))

    expected_up = Vector((0, 0, 1))
    expected_forward = Vector((0, -1, 0))
    for socket_name, expected_position in SOCKET_POSITIONS.items():
        bone = armature.data.bones[socket_name]
        assert not bone.use_deform
        assert bone.parent.name == SOCKET_PARENTS[socket_name]
        assert (bone.head_local - Vector(expected_position)).length < 1e-6
        basis = bone.matrix_local.to_3x3()
        local_y = basis.col[1].normalized()
        local_minus_z = -basis.col[2].normalized()
        assert local_y.dot(expected_up) > 0.999999, (socket_name, local_y)
        assert local_minus_z.dot(expected_forward) > 0.999999, (
            socket_name,
            local_minus_z,
        )

    print(f"MEASURE total_height_m={measured_height:.6f}")
    print(f"MEASURE eye_height_m={head_socket.head_local.z:.6f}")
    print(f"MEASURE shoulder_width_m={SHOULDER_WIDTH_M:.6f}")
    for socket_name in SOCKET_POSITIONS:
        position = armature.data.bones[socket_name].head_local
        print(
            f"SOCKET {socket_name} blender_xyz_m="
            f"({position.x:.6f}, {position.y:.6f}, {position.z:.6f})"
        )


def save_and_export(armature, proxy) -> None:
    BLEND_PATH.parent.mkdir(parents=True, exist_ok=True)
    GLB_PATH.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH), compress=True)

    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    proxy.select_set(True)
    bpy.context.view_layer.objects.active = armature
    result = bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        check_existing=False,
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_skins=True,
        export_def_bones=False,
        export_leaf_bone=False,
        export_animations=False,
        export_morph=False,
        export_cameras=False,
        export_lights=False,
        export_extras=True,
        export_vertex_color="ACTIVE",
        export_attributes=True,
    )
    assert result == {"FINISHED"}, result
    assert BLEND_PATH.exists() and BLEND_PATH.stat().st_size > 0
    assert GLB_PATH.exists() and GLB_PATH.stat().st_size > 0
    print(f"WROTE {BLEND_PATH}")
    print(f"WROTE {GLB_PATH}")


def main() -> None:
    clear_scene()
    configure_scene()
    armature = create_armature()
    proxy = create_proxy(armature)
    validate_in_blender(armature, proxy)
    save_and_export(armature, proxy)


if __name__ == "__main__":
    main()
