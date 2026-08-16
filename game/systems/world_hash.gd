class_name WorldHash
extends RefCounted

## `M1-T07` — a canonical fingerprint of a built level (`TEC-001`, `TEC-004`).
##
## `TEC-004` makes generation determinism **bit-exact across machines**, not
## merely reproducible locally, because the host sends a seed and every client
## builds the floor from it rather than receiving geometry. A desync here is
## invisible until two players disagree about where a wall is, which is the
## most expensive class of bug this project can have.
##
## **Built before the generator exists, deliberately.** `TEC-004` says to build
## it at M1 and run it in CI, and the reason is ordering: a determinism check
## written *after* a generator is a check written against whatever that
## generator already does, including its bugs. Written first, it is a
## specification the generator has to satisfy.
##
## What it currently proves is real but modest — the hand-authored room set is
## deterministic by construction, so a mismatch today means the *engine* or the
## traversal introduced variance, not the layout. That is worth catching on its
## own: `Dictionary` iteration order, float accumulation and node ordering are
## exactly the things `TEC-004` warns about, and they are already in play.
## Coverage grows the day `M4-T01` lands, with no new harness needed.
##
## **Canonical means order-independent.** Node traversal order is not a promised
## invariant, so every entry is stringified and the set is sorted before
## hashing. Two processes that build the same world in a different order must
## agree; two that build a different world must not.

## Quantisation. Floats are compared as fixed-point millimetres so that a
## difference no player could perceive cannot fail the build, while a genuine
## layout divergence — which is always far larger — still does.
const PRECISION: float = 1000.0


static func _q(value: float) -> int:
	return int(round(value * PRECISION))


static func _vector(v: Vector3) -> String:
	return "%d,%d,%d" % [_q(v.x), _q(v.y), _q(v.z)]


## Every mesh and body under `root`, as a sorted, quantised description.
static func entries(root: Node) -> PackedStringArray:
	var rows: Array[String] = []
	_walk(root, rows)
	rows.sort()
	var out := PackedStringArray()
	for row: String in rows:
		out.append(row)
	return out


static func _walk(node: Node, rows: Array[String]) -> void:
	# Layout only. The first version hashed the whole tree and reported two
	# different digests from one seed with an identical entry count — the
	# variance was live simulation state, not geometry: debug overlays rebuild
	# their meshes from the player's exact position every frame, and actors
	# settle under gravity to sub-millimetre-different resting positions.
	#
	# Neither belongs in this hash. TEC-004's guarantee is about *the floor the
	# clients build from the seed*; where an enemy has drifted to by frame 8 is
	# replicated state, not generated state, and folding it in would make the
	# check fail for reasons that are not desyncs.
	if node is DebugOverlays or node is CharacterBody3D:
		return
	var spatial := node as Node3D
	if spatial != null:
		var mesh := node as MeshInstance3D
		if mesh != null and mesh.mesh != null:
			# The class name and AABB rather than the vertices: it identifies
			# the shape at a fraction of the cost, and a generator that placed
			# a different box would change both.
			var box: AABB = mesh.mesh.get_aabb()
			rows.append("mesh %s %s %s %s" % [
				mesh.mesh.get_class(), _vector(spatial.global_position),
				_vector(box.position), _vector(box.size),
			])
		var body := node as CollisionObject3D
		if body != null:
			rows.append("body %s %s %d" % [
				body.get_class(), _vector(spatial.global_position),
				body.collision_layer,
			])
	for child: Node in node.get_children():
		_walk(child, rows)


## A stable hex digest of the world under `root`.
static func digest(root: Node) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	for row: String in entries(root):
		context.update(row.to_utf8_buffer())
		context.update("\n".to_utf8_buffer())
	return context.finish().hex_encode()
