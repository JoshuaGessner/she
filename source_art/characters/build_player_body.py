"""Build the delvers' body: what a teammate is seen as, on the shared rig.

Run with Blender, after `build_humanoid_rig.py`:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \\
      --python source_art/characters/build_player_body.py

**Why this is not the rig's proxy** (ADR-308). `build_humanoid_rig.py` makes a
proxy of spheres, boxes and cylinders and says what it is for: *"rig placement
and measurement only; not character art"*. ADR-254 put it on every teammate
anyway, because it was what the rig had. It stays the rig's measuring stick;
this is the character, built from the same anatomy as every enemy
(`build_enemy_models.py`, ADR-305) so a delver and a Wretch are one people.

**What gear hides.** `BodyRig` hides the base body under armour by each vertex's
dominant bone — pelvis, spine, chest, legs, feet and upper arms. So what always
shows is weighted to what armour never covers: the head, the neck (weighted to
`neck` here, where the enemies' is on the chest), the forearms and the hands.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
OUT = ROOT / "game" / "art" / "characters" / "player_body.glb"
sys.path.insert(0, str(SRC.parent / "enemies"))
import build_enemy_models as anatomy  # noqa: E402

## The shared head is the enemies', drawn large for reading at range. A delver's
## is scaled about the chin to human proportion ⟨tune⟩.
HEAD_SCALE = 0.88
CHIN = Vector((0.0, 0.0, 1.52))
## The rig's collider (`build_humanoid_rig.CAPSULE_RADIUS_M`): nothing the upper
## arm owns may stand outside it.
CAPSULE = 0.35
BROAD = 0.92


def head_weight(obj: bpy.types.Object, vertex: bpy.types.MeshVertex) -> float:
    head = obj.vertex_groups.get("head")
    if head is None:
        return 0.0
    for link in vertex.groups:
        if link.group == head.index:
            return link.weight
    return 0.0


def build() -> bpy.types.Object:
    rig = anatomy.begin()
    anatomy.PALETTE["linen"] = ((0.36, 0.33, 0.27, 1.0), 0.60, 0.0)
    anatomy.body("linen", stature=1.0, broad=BROAD, flaps=False, hood=False, bare_arms=False)
    # A tunic to mid-thigh with a plain hem, leg wraps over the trousers, and
    # hair bound back: the Viking-age working dress the enemies are a ruin of.
    anatomy.tattered_hem("linen", BROAD, hang=.34, torn=0.0)
    for side in ("l", "r"):
        anatomy.bindings(side, "thigh", "calf", .107 * BROAD, (.30, .45, .60, .75), "rag")
    anatomy.bound_hair(lambda p: {"head": max(0.0, min(1.0, (p.z - 1.50) / .15)),
                                  "neck": 1.0 - max(0.0, min(1.0, (p.z - 1.50) / .15))}
                       if p.z > 1.50 else {"neck": 1.0}, BROAD)
    # Shoulders that join the arm to the body. The enemies' are hidden under
    # capes and plates; a delver in a tunic shows the deltoid standing off the
    # torso like a pad without them.
    for side, sign in (("l", 1), ("r", -1)):
        anatomy.ellipsoid(f"shoulder_{side}", Vector((sign * .165, .004, 1.468)), (.098, .090, .062),
                          "linen", {"chest": .55, f"upper_arm_{side}": .45}, True, 12, 6)
    # A collar round the neck opening, and cuffs at the wrists: the tunic's
    # edges, which are what make it read as a garment rather than a skin.
    anatomy.loft("tunic_collar", [anatomy.ring(Vector((0, .006, 1.515)), .128, .106, 14),
                                  anatomy.ring(Vector((0, .006, 1.545)), .114, .094, 14)],
                 "leather", {"chest": 1.0}, False, cap=False)
    for side in ("l", "r"):
        anatomy.bindings(side, "upper_arm", "forearm", .083 * BROAD, (.80, .86), "leather")
    # The neck is the neck's, so a byrnie does not take it off with the chest.
    for obj in anatomy.PARTS:
        if obj.name == "neck":
            obj.vertex_groups.clear()
            group = obj.vertex_groups.new(name="neck")
            group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    # The head to human size, each vertex as far as the head owns it.
    for obj in anatomy.PARTS:
        for vertex in obj.data.vertices:
            owned = head_weight(obj, vertex)
            if owned > 0.0:
                scaled = CHIN + (vertex.co - CHIN) * HEAD_SCALE
                vertex.co = vertex.co.lerp(scaled, owned)
        obj.data.update()
    return rig


def validate(rig: bpy.types.Object) -> dict[str, object]:
    anatomy.validate()
    top = max(v.co.z for obj in anatomy.PARTS for v in obj.data.vertices)
    low = min(v.co.z for obj in anatomy.PARTS for v in obj.data.vertices)
    assert abs(low) < 0.02, low
    assert 1.76 <= top <= 1.84, top
    reach = 0.0
    for obj in anatomy.PARTS:
        names = {group.index: group.name for group in obj.vertex_groups}
        for vertex in obj.data.vertices:
            if not vertex.groups:
                continue
            strongest = max(vertex.groups, key=lambda link: link.weight)
            if names[strongest.group].startswith("upper_arm"):
                reach = max(reach, abs(vertex.co.x))
    assert reach <= CAPSULE + 1e-6, reach
    return {"triangles": anatomy.triangle_count(), "height_m": round(top, 3),
            "upper_arm_reach_m": round(reach, 3), "bones": len(rig.data.bones)}


def export(rig: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in anatomy.PARTS:
        # glTF node names share a namespace with joints (see animate_enemies).
        if obj.name in rig.data.bones:
            obj.name = "mesh_" + obj.name
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(obj.data)
        bm.free()
        obj.select_set(True)
    # One skinned mesh: `BodyRig` takes the first mesh it finds as the body.
    bpy.context.view_layer.objects.active = anatomy.PARTS[0]
    bpy.ops.object.join()
    bpy.context.object.name = "player_body"
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "player_body.blend"))
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=False, export_skins=True, export_def_bones=False,
        export_leaf_bone=False, export_animations=False, export_morph=False,
        export_cameras=False, export_lights=False, export_vertex_color="ACTIVE",
        export_attributes=True, export_extras=True)


def main() -> None:
    rig = build()
    report = validate(rig)
    anatomy.SRC = SRC
    anatomy.review("player_body")
    export(rig)
    (SRC / "player_body_measurements.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
