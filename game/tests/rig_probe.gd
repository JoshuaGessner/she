extends SceneTree

## Verify the shared humanoid rig as Godot actually sees it (`M1-T10`).
##
## Checking the .blend is not enough. glTF export is where rigs quietly lose
## things — non-deforming leaf bones are a standard casualty, and every socket
## on this rig is a non-deforming leaf. A socket that exists in Blender and not
## in the .glb fails silently: gear attaches to nothing and the cause is three
## tools away from the symptom.

const RIG: String = "res://art/characters/humanoid_rig.glb"
## Worn models are validated here rather than in a separate validator: the
## question is still whether the exported shared rig can actually deform a mesh
## authored against it. A second skeleton test would only drift.
const WORN: Array[Dictionary] = [
	{
		"label": "Otr pelt", "item": "res://data/items/rlc_otr_pelt.tres",
		"bones": [&"chest", &"upper_arm_l", &"thigh_l"],
	},
	{
		"label": "mail byrnie", "item": "res://data/items/arm_mail_byrnie.tres",
		"bones": [&"chest", &"upper_arm_l", &"thigh_l"],
	},
	{
		"label": "iron bracers", "item": "res://data/items/arm_iron_bracers.tres",
		"bones": [&"forearm_l", &"forearm_r"],
	},
]
## Four classes are deliberately absent from the catalogue today, but their
## source meshes must still stay compatible with the one rig they will use when
## those classes are authored. The two present classes are also checked through
## their ClassResource in `data_probe`.
const BARE_ARMS: Array[String] = [
	"res://art/characters/huskarl_arms.glb",
	"res://art/characters/veidimadr_arms.glb",
	"res://art/characters/volva_arms.glb",
	"res://art/characters/skald_arms.glb",
	"res://art/characters/ulfhedinn_arms.glb",
	"res://art/characters/haugbrjotr_arms.glb",
]
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
	# SceneTree._initialize runs before the root enters the tree. Let the rig's
	# ready pass establish its rest poses before deliberately changing a bone;
	# otherwise that first ready pass resets the first garment's test pose.
	await process_frame
	await process_frame

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

	print("\nshared-topology worn gear:")
	for path: String in BARE_ARMS:
		_check(_same_skeleton(path, skeleton), "%s shares all %d rig bones"
			% [path.get_file(), skeleton.get_bone_count()])
	for entry: Dictionary in WORN:
		await _check_worn(entry, skeleton)

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


## Exact names, not bone indices. The exporter can reorder a skin without
## changing its topology, and `ItemResource.wear_on` deliberately remaps that
## case by name.
func _same_skeleton(path: String, shared: Skeleton3D) -> bool:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return false
	var imported: Node = packed.instantiate()
	var source: Skeleton3D = _find_skeleton(imported)
	if source == null or source.get_bone_count() != shared.get_bone_count():
		imported.free()
		return false
	for index: int in range(shared.get_bone_count()):
		var shared_name: StringName = shared.get_bone_name(index)
		var source_index: int = source.find_bone(shared_name)
		if source_index < 0:
			imported.free()
			return false
		var source_parent: int = source.get_bone_parent(source_index)
		var shared_parent: int = shared.get_bone_parent(index)
		var source_parent_name: StringName = source.get_bone_name(source_parent) \
			if source_parent >= 0 else &""
		var shared_parent_name: StringName = shared.get_bone_name(shared_parent) \
			if shared_parent >= 0 else &""
		if source_parent_name != shared_parent_name \
				or not source.get_bone_rest(source_index).is_equal_approx(
					shared.get_bone_rest(index)):
			imported.free()
			return false
	imported.free()
	return true


## A correctly indexed `Skin` can still be attached to the source armature and
## stay frozen while the actual body poses. This goes through the production
## `wear_on` path, verifies every resulting mesh resolves its skeleton path to
## `shared`, then evaluates a real weighted vertex under a changed bone pose.
## It therefore fails a bound-but-unmoving mesh, not merely a missing bind.
func _check_worn(entry: Dictionary, shared: Skeleton3D) -> void:
	var label: String = entry["label"] as String
	var item: ItemResource = load(entry["item"] as String) as ItemResource
	_check(item != null and item.worn_model != null,
		"%s has a skinned worn-model reference" % label)
	if item == null or item.worn_model == null:
		return
	_check(_same_skeleton(item.worn_model.resource_path, shared),
		"%s source has the shared topology" % label)
	var carrier: Node3D = item.wear_on(shared)
	_check(carrier != null, "%s joins the active Skeleton3D" % label)
	if carrier == null:
		return
	var meshes: Array[Node] = _meshes(carrier)
	var joined: bool = not meshes.is_empty()
	for node: Node in meshes:
		var mesh := node as MeshInstance3D
		joined = joined and mesh.skin != null \
			and mesh.get_node_or_null(mesh.skeleton) == shared
	_check(joined and carrier.find_children("*", "Skeleton3D", true, false).is_empty(),
		"%s leaves no duplicate moving skeleton" % label)
	var drift: float = 0.0
	for node: Node in meshes:
		drift = maxf(drift, _rest_skin_error(node as MeshInstance3D, shared))
	_check(drift < PLACEMENT_TOLERANCE, "%s bind poses preserve the authored rest shape"
		% label, "largest drift %.6f m" % drift)
	for bone: StringName in entry["bones"]:
		var moved: float = await _weighted_motion(meshes, shared, bone)
		_check(moved > 0.003, "%s weighted vertices follow a posed %s"
			% [label, bone], "measured %.4f m" % moved)
	carrier.free()


func _weighted_motion(meshes: Array[Node], skeleton: Skeleton3D,
		bone_name: StringName) -> float:
	var target: int = skeleton.find_bone(bone_name)
	if target < 0:
		return 0.0
	var old: Transform3D = skeleton.get_bone_global_pose(target)
	var posed: Transform3D = old
	posed.basis = posed.basis * Basis(Quaternion(Vector3.UP, 0.55))
	skeleton.set_bone_global_pose(target, posed)
	skeleton.force_update_all_bone_transforms()
	await process_frame
	var largest: float = 0.0
	for node: Node in meshes:
		largest = maxf(largest, _mesh_weighted_motion(node as MeshInstance3D,
			skeleton, target))
	skeleton.set_bone_global_pose(target, old)
	skeleton.force_update_all_bone_transforms()
	return largest


func _mesh_weighted_motion(mesh: MeshInstance3D, skeleton: Skeleton3D,
		target: int) -> float:
	if mesh == null or mesh.mesh == null or mesh.skin == null:
		return 0.0
	for surface: int in range(mesh.mesh.get_surface_count()):
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES] as PackedInt32Array
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array
		if vertices.is_empty() or bones.is_empty() or weights.is_empty():
			continue
		var influences: int = bones.size() / vertices.size()
		var largest: float = 0.0
		for vertex: int in range(vertices.size()):
			var touches_target: bool = false
			var at_rest := Vector3.ZERO
			var posed := Vector3.ZERO
			for influence: int in range(influences):
				var offset: int = vertex * influences + influence
				var bind: int = bones[offset]
				if bind < 0 or bind >= mesh.skin.get_bind_count():
					continue
				var bone: int = _bound_bone(mesh.skin, skeleton, bind)
				if bone < 0:
					continue
				var weight: float = weights[offset]
				if weight <= 0.0:
					continue
				var inverse_bind: Transform3D = mesh.skin.get_bind_pose(bind)
				at_rest += (skeleton.get_bone_global_rest(bone) * inverse_bind
					* vertices[vertex]) * weight
				posed += (skeleton.get_bone_global_pose(bone) * inverse_bind
					* vertices[vertex]) * weight
				touches_target = touches_target or bone == target
			if touches_target:
				largest = maxf(largest, at_rest.distance_to(posed))
		if largest > 0.0:
			return largest
	return 0.0


## Prefer the bind name because glTF importers are free to omit or reorder the
## source skeleton index. `wear_on` remaps that same name onto `skeleton`.
static func _bound_bone(skin: Skin, skeleton: Skeleton3D, bind: int) -> int:
	var named: StringName = skin.get_bind_name(bind)
	if named != &"":
		return skeleton.find_bone(named)
	var bone: int = skin.get_bind_bone(bind)
	return bone if bone >= 0 and bone < skeleton.get_bone_count() else -1


## Motion alone also passes a mesh with a bad inverse bind: it moves while
## already displaced. At rest the weighted result must reproduce every vertex.
func _rest_skin_error(mesh: MeshInstance3D, skeleton: Skeleton3D) -> float:
	var largest: float = 0.0
	for surface: int in range(mesh.mesh.get_surface_count()):
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if vertices.is_empty() or bones.is_empty():
			return INF
		var influences: int = bones.size() / vertices.size()
		for vertex: int in range(vertices.size()):
			var result := Vector3.ZERO
			for influence: int in range(influences):
				var offset: int = vertex * influences + influence
				if weights[offset] <= 0.0:
					continue
				var bind: int = bones[offset]
				var bone: int = _bound_bone(mesh.skin, skeleton, bind)
				if bone < 0:
					return INF
				result += (skeleton.get_bone_global_rest(bone)
					* mesh.skin.get_bind_pose(bind) * vertices[vertex]) * weights[offset]
			largest = maxf(largest, result.distance_to(vertices[vertex]))
	return largest
