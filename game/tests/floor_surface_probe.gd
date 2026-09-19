extends SceneTree

## Rendered floors must have one owner at every point, while the collision
## solids keep the overlap Recast needs. Measure both from emitted nodes so a
## fix that only changes the builder's accounting cannot pass.
func _initialize() -> void:
	var modules: Array[RoomModule] = RoomCatalogue.all()
	var calamities: Array[CalamityResource] = CalamityCatalogue.all()
	var kinds := PackedStringArray()
	for module: RoomModule in modules:
		if not module.prize_kind.is_empty() and not kinds.has(module.prize_kind):
			kinds.append(module.prize_kind)
	var overlaps: int = 0
	var floors: int = 0
	var broken_laps: int = 0
	var solids: Array = []
	for run_seed: int in [31337, 31346, 78901, 42, 12345, 8675309, 1, 999]:
		for depth: int in 3:
			var graph: MissionGraph = MissionGraph.build(run_seed, depth)
			var lore: ExpeditionHistory = ExpeditionHistory.roll(run_seed, calamities, kinds)
			var plan: FloorPlan = FloorPlan.build(graph, run_seed, depth, modules, lore)
			if not plan.problems().is_empty():
				push_error("[surfaces] invalid plan: %s" % plan.problems())
				quit(1)
				return
			var shell := Node3D.new()
			var census: Dictionary = FloorBuilder.build(plan, graph, run_seed, depth, shell)
			solids.append(census["occluders"])
			var surfaces: Array[AABB] = []
			for child: Node in shell.get_children():
				# A floor root holds the trim that belongs to no slab as
				# well as the slabs themselves (ADR-263).
				var slab := child as MeshInstance3D
				if slab == null:
					continue
				if not slab.visible or not String(slab.name).begins_with("floor_"):
					continue
				var bounds: AABB = slab.transform * slab.mesh.get_aabb()
				var collision := slab.get_child(0).get_child(0) as CollisionShape3D
				var solid := collision.shape as BoxShape3D
				var expected: Vector3 = slab.mesh.get_aabb().size \
					+ Vector3(FloorBuilder.FLOOR_LAP * 2.0, 0.0, FloorBuilder.FLOOR_LAP * 2.0)
				if not solid.size.is_equal_approx(expected):
					broken_laps += 1
				for other: AABB in surfaces:
					if absf(bounds.end.y - other.end.y) < 0.0001 \
							and minf(bounds.end.x, other.end.x) - maxf(bounds.position.x, other.position.x) > 0.0001 \
							and minf(bounds.end.z, other.end.z) - maxf(bounds.position.z, other.position.z) > 0.0001:
						overlaps += 1
						print("[surfaces] overlap seed=%d depth=%d %s / %s" % [run_seed, depth, bounds, other])
				surfaces.append(bounds)
				floors += 1
			shell.free()
	print("[surfaces] %d flat floors across 24 layouts; %d coplanar overlaps" % [floors, overlaps])
	print("[surfaces] collision fingerprint %s" % var_to_bytes(solids).hex_encode().sha256_text())
	print("[surfaces] %d broken collider laps" % broken_laps)
	if overlaps > 0 or floors == 0 or broken_laps > 0:
		push_error("[surfaces] FAIL visible overlap, broken collider lap, or empty corpus")
		quit(1)
	else:
		print("[surfaces] PASS")
		quit()
