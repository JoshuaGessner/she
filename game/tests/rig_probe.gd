extends SceneTree

## Verify the shared humanoid rig as Godot actually sees it (`M1-T10`).
##
## Checking the .blend is not enough. glTF export is where rigs quietly lose
## things — non-deforming leaf bones are a standard casualty, and every socket
## on this rig is a non-deforming leaf. A socket that exists in Blender and not
## in the .glb fails silently: gear attaches to nothing and the cause is three
## tools away from the symptom.

const RIG: String = "res://art/characters/humanoid_rig.glb"
const SOCKETS: Array[String] = [
	"sock_head", "sock_hand_r", "sock_hand_l", "sock_back",
	"sock_hip_r", "sock_hip_l", "sock_shoulders",
]
## From ADR-080. The rig is authored to the collider, not the reverse.
const HEIGHT: float = 1.80
const EYE: float = 1.62
const TOLERANCE: float = 0.01

## Every socket's accepted rest position, Godot axes, to the millimetre.
##
## Names and parents alone would pass a rig whose sockets had drifted, and
## drift is the failure that matters: gear authored against a moved socket is
## wrong everywhere and traceable nowhere. Merged in from the rig author's own
## validator, which is now deleted — two validators for one rig is the
## duplicate ADR-064 bans, and they would disagree the first time either moved.
const POSITIONS: Dictionary = {
	"sock_head": Vector3(0.0, 1.62, 0.095),
	"sock_hand_r": Vector3(-0.46, 1.065, 0.035),
	"sock_hand_l": Vector3(0.46, 1.065, 0.035),
	"sock_back": Vector3(0.0, 1.35, -0.155),
	"sock_hip_r": Vector3(-0.19, 0.98, -0.03),
	"sock_hip_l": Vector3(0.19, 0.98, -0.03),
	"sock_shoulders": Vector3(0.0, 1.45, -0.06),
}
const PLACEMENT_TOLERANCE: float = 0.001

var _failures: int = 0


func _check(ok: bool, label: String, detail: String = "") -> void:
	print("  %s %s%s" % ["ok  " if ok else "FAIL", label,
		"   " + detail if detail != "" else ""])
	if not ok:
		_failures += 1


func _initialize() -> void:
	var packed: PackedScene = load(RIG) as PackedScene
	if packed == null:
		printerr("could not load " + RIG)
		quit(1)
		return
	var root: Node = packed.instantiate()
	get_root().add_child(root)

	var skeleton: Skeleton3D = _find_skeleton(root)
	_check(skeleton != null, "scene contains a Skeleton3D")
	if skeleton == null:
		quit(1)
		return
	print("bones: %d" % skeleton.get_bone_count())

	var names: Array[String] = []
	for i: int in range(skeleton.get_bone_count()):
		names.append(skeleton.get_bone_name(i))

	for socket: String in SOCKETS:
		_check(names.has(socket), "socket survived export: " + socket)

	for banned: String in ["camera", "eye", "view", "sock_body", "sock_arms"]:
		var hits: Array[String] = names.filter(
			func(n: String) -> bool: return n.to_lower().contains(banned)
		)
		_check(hits.is_empty(), "no bone matching '%s'" % banned, ", ".join(hits))

	var head_index: int = skeleton.find_bone("sock_head")
	if head_index >= 0:
		var y: float = skeleton.get_bone_global_rest(head_index).origin.y
		_check(absf(y - EYE) <= TOLERANCE, "sock_head at eye line %.2f m" % EYE,
			"measured %.4f m" % y)

	var extent: float = _tallest(root)
	_check(absf(extent - HEIGHT) <= TOLERANCE, "imported height %.2f m" % HEIGHT,
		"measured %.4f m" % extent)

	print("\nsocket rest positions (Godot, metres):")
	for socket: String in SOCKETS:
		var index: int = skeleton.find_bone(socket)
		if index < 0:
			continue
		var o: Vector3 = skeleton.get_bone_global_rest(index).origin
		var want: Vector3 = POSITIONS[socket]
		var drift: float = o.distance_to(want)
		_check(drift <= PLACEMENT_TOLERANCE, "%s placed" % socket,
			"(%.3f, %.3f, %.3f)  drift %.4f m" % [o.x, o.y, o.z, drift])

	print("\n%d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _find_skeleton(node: Node) -> Skeleton3D:
	var skeleton := node as Skeleton3D
	if skeleton != null:
		return skeleton
	for child: Node in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null


## Tallest point of any mesh, in world space — the height a player would measure.
func _tallest(node: Node) -> float:
	var top: float = -1e9
	var bottom: float = 1e9
	for mesh: Node in _meshes(node):
		var instance := mesh as MeshInstance3D
		var box: AABB = _world_of(instance, node) * instance.get_aabb()
		top = maxf(top, box.position.y + box.size.y)
		bottom = minf(bottom, box.position.y)
	return top - bottom if top > bottom else 0.0


## Transform of `node` relative to `root`, accumulated by hand.
##
## `global_transform` asserts the node is inside the tree, and during
## `_initialize()` it is not yet — it returns identity and logs an error. The
## measurement happened to come out right anyway, which is the worst kind of
## passing test: correct answer, broken method.
static func _world_of(node: Node3D, root: Node) -> Transform3D:
	var accumulated := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		var spatial := current as Node3D
		if spatial != null:
			accumulated = spatial.transform * accumulated
		current = current.get_parent()
	return accumulated


func _meshes(node: Node) -> Array[Node]:
	var found: Array[Node] = []
	if node is MeshInstance3D:
		found.append(node)
	for child: Node in node.get_children():
		found += _meshes(child)
	return found
