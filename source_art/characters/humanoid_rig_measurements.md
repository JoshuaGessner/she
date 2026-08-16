# Shared humanoid rig measurements

Measured from the rest pose in `humanoid_rig.blend` and verified after importing
`humanoid_rig.glb` into Godot 4.7 with no import-time rescale.

| Measurement | Final value |
|---|---:|
| Sole-to-crown height | 1.800 m |
| Eye height / `sock_head` height | 1.620 m |
| Shoulder width across deltoid proxies | 0.480 m |
| Blender object scales | (1.000, 1.000, 1.000) |
| Godot imported height | 1.800 m |

## Socket rest positions

Positions are the socket bone heads in metres. Blender uses X/Y/Z with Z up and
−Y as the oriented asset front. Godot uses X/Y/Z with Y up; glTF-oriented assets
face +Z, while gameplay nodes and cameras use −Z as their forward axis.

| Socket | Parent | Blender XYZ (m) | Godot imported XYZ (m) |
|---|---|---:|---:|
| `sock_head` | `head` | (0.000, -0.095, 1.620) | (0.000, 1.620, 0.095) |
| `sock_hand_r` | `hand_r` | (-0.460, -0.035, 1.065) | (-0.460, 1.065, 0.035) |
| `sock_hand_l` | `hand_l` | (0.460, -0.035, 1.065) | (0.460, 1.065, 0.035) |
| `sock_back` | `chest` | (0.000, 0.155, 1.350) | (0.000, 1.350, -0.155) |
| `sock_hip_r` | `pelvis` | (-0.190, 0.030, 0.980) | (-0.190, 0.980, -0.030) |
| `sock_hip_l` | `pelvis` | (0.190, 0.030, 0.980) | (0.190, 0.980, -0.030) |
| `sock_shoulders` | `chest` | (0.000, 0.060, 1.450) | (0.000, 1.450, -0.060) |

All seven sockets are non-deforming bones with deliberate, matching roll. Their
local −Z axis is the attached object's pointing axis and local +Y is its up axis.
`sock_shoulders` is present and unused. There are no Body or Arms sockets and no
camera, eye, or view bones.

The 1.15 m crouched collider height is intentionally not represented here: the
brief requires it to be achieved by animation, and this deliverable contains no
animations.
