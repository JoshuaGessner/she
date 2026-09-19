extends SceneTree

## **The kit is laid, and the solids underneath it did not move** (`M4-T10`,
## ADR-263).
##
## `art_probe.gd` asks whether the delivered modules are *valid* — metres,
## pivots, poly budget, hard edges. This asks the next question, which is
## whether the game **uses** them, and whether using them cost anything.
##
## ## The row that matters most is the one about collision
##
## Cladding is a rendering change by construction: every module is hung on a box
## that already existed and no module brings a collider. That is easy to say and
## easy to break — one `PackedScene.instantiate()` instead of a `Mesh`, and
## every kit piece in the Delvings arrives with the `-colonly` proxy it was
## authored with, handing Recast a second and finer-grained copy of the world.
## The floor would still *look* right. It would bake differently, and the first
## symptom would be a room the Hunt cannot enter three sessions later.
##
## So the solids are compared against `FloorBuilder`'s own record of what it
## laid — `occluders`, which is built by the same pass with no nodes made. If
## those two ever disagree, something in the cladding has become architecture.
##
## ## What it deliberately does not check
##
## Whether the result **looks** right. `--delvings-shot`, `--light-shot` and
## `--threshold-shot` are that, for ADR-093's reason: four times now a
## screenshot has caught what no headless assertion could, and none of those
## four would have been caught by measuring harder.

## Floors to build. Three seeds at three depths, so the roughness gradient —
## and with it every cut corner — is in the corpus.
const SEEDS: Array[int] = [31346, 78901, 8675309]

## The 1.15 m crouch, which `FloorBuilder.CEILINGS[0]` is set against. A
## ceiling module hangs below the collision plane it is fixed to, so the beams
## are what a head actually meets ⟨tune⟩.
const CROUCH: float = 1.15

## How close two measurements have to be to be the same measurement, in metres.
const NEAR: float = 0.001

## One navmesh voxel of height (ADR-200). Cladding has to stand proud of the
## box it covers or the two faces z-fight, and this is how proud it may stand
## before the lip stops being invisible and starts being a step.
const VOXEL: float = 0.10


func _initialize() -> void:
	var problems: PackedStringArray = PackedStringArray()

	# ─ 1. every delivered module loads, and is the size the maths assumes ─
	#
	# `DelvingsKit` places by arithmetic off these numbers — a flagstone is
	# sunk by `FLAG_DEEP` so it finishes flush, a doorway is centred on an
	# opening `FRAME_WIDE` wide. A re-export that moved any of them would put
	# every piece in the game a few centimetres out and nothing would say so.
	var expected: Dictionary = _expected_bounds()
	var missing: int = 0
	var wrong: PackedStringArray = PackedStringArray()
	for module: StringName in DelvingsKit.DELIVERED:
		var shape: Mesh = DelvingsKit.mesh_of(module)
		if shape == null:
			missing += 1
			continue
		if not expected.has(module):
			continue
		var want: AABB = expected[module]
		var got: AABB = shape.get_aabb()
		if not got.position.is_equal_approx(want.position) \
				or not got.size.is_equal_approx(want.size):
			wrong.append("%s is %v..%v, not %v..%v"
				% [module, got.position, got.end, want.position, want.end])
	print("[kit] delivered   %d module(s), %d missing, %d off their stated size"
		% [DelvingsKit.DELIVERED.size(), missing, wrong.size()])
	if missing > 0:
		problems.append(("%d of %d module(s) would not load — a wall with no "
			+ "module is a wall with no surface, and nothing else in the build "
			+ "would notice")
			% [missing, DelvingsKit.DELIVERED.size()])
	if not wrong.is_empty():
		problems.append(("%d module(s) are not the size `DelvingsKit` places "
			+ "them at (%s) — every piece in the game would be out by the "
			+ "difference") % [wrong.size(), "; ".join(wrong)])

	# ─ 2. build the corpus ────────────────────────────────────────────────
	var modules: Array[RoomModule] = RoomCatalogue.all()
	var calamities: Array[CalamityResource] = CalamityCatalogue.all()
	var kinds := PackedStringArray()
	for module: RoomModule in modules:
		if not module.prize_kind.is_empty() and not kinds.has(module.prize_kind):
			kinds.append(module.prize_kind)

	var slabs: int = 0
	var pieces: int = 0
	var shapes: int = 0
	var strayed: PackedStringArray = PackedStringArray()
	var bare: PackedStringArray = PackedStringArray()
	var sunk: PackedStringArray = PackedStringArray()
	var flush: PackedStringArray = PackedStringArray()
	var ducked: float = 999.0
	var placed: Dictionary = {}
	for run_seed: int in SEEDS:
		for depth: int in 3:
			var graph: MissionGraph = MissionGraph.build(run_seed, depth)
			var lore: ExpeditionHistory = ExpeditionHistory.roll(
				run_seed, calamities, kinds)
			var plan: FloorPlan = FloorPlan.build(
				graph, run_seed, depth, modules, lore)
			if not plan.problems().is_empty():
				push_error("[kit] invalid plan: %s" % plan.problems())
				quit(1)
				return
			var shell := Node3D.new()
			var census: Dictionary = FloorBuilder.build(
				plan, graph, run_seed, depth, shell)
			slabs += int(census["slabs"])
			shapes += _shapes_under(shell, strayed)
			pieces += _pieces_under(shell, placed)
			_solids_match(shell, census["occluders"] as Array, strayed)
			ducked = minf(ducked, _clad_slabs(shell, bare, sunk, flush))
			shell.free()

	print("[kit] laid        %d piece(s) over %d slab(s) across %d floor(s)"
		% [pieces, slabs, SEEDS.size() * 3])

	# ─ 3. nothing the kit laid is a solid ─────────────────────────────────
	print("[kit] solids      %d collision shape(s) for %d slab(s), %d strayed"
		% [shapes, slabs, strayed.size()])
	if shapes != slabs:
		problems.append(("%d collision shape(s) for %d slab(s) — the cladding "
			+ "has become architecture, and the navmesh now bakes from a "
			+ "different world than the one the builder recorded")
			% [shapes, slabs])
	if not strayed.is_empty():
		problems.append(("%d solid(s) are not the ones `FloorBuilder` recorded "
			+ "laying (%s) — `occluders` and the floor have to be the same "
			+ "floor or `FloorVista` is reading a world nobody is standing in")
			% [strayed.size(), "; ".join(strayed.slice(0, 3))])

	# ─ 4. every surface that should be clad is ────────────────────────────
	print("[kit] coverage    %d bare surface(s), %d flagstone(s) off the "
		% [bare.size(), sunk.size()] + "walking plane")
	if not bare.is_empty():
		problems.append(("%d floor(s), ceiling(s) or ramp(s) were left as bare "
			+ "boxes (%s) — blockout shipping beside stone is worse than "
			+ "blockout, because it reads as a fault rather than as a phase")
			% [bare.size(), "; ".join(bare.slice(0, 3))])
	if not sunk.is_empty():
		problems.append(("%d flagstone(s) do not finish on the surface the "
			+ "collider says you walk on (%s) — a floor you stand above or "
			+ "sink into is the one visual fault a player reads as a bug")
			% [sunk.size(), "; ".join(sunk.slice(0, 3))])
	print("[kit] recessed    %d wall box(es) left flush with their masonry"
		% flush.size())
	if not flush.is_empty():
		problems.append(("%d wall box(es) are still the full thickness with "
			+ "stone in front of them (%s) — two faces on one plane, which is "
			+ "a wall that shimmers as you walk past it")
			% [flush.size(), "; ".join(flush.slice(0, 3))])

	# ─ 5. the beams clear a crouched body ─────────────────────────────────
	print("[kit] headroom    lowest beam %.2f m, against a %.2f m crouch"
		% [ducked, CROUCH])
	if ducked < CROUCH:
		problems.append(("a ceiling beam hangs at %.2f m, under the %.2f m "
			+ "crouch — the module hangs below the collision plane it is "
			+ "fixed to, so a crawl can be walled by its own roof")
			% [ducked, CROUCH])

	# ─ 6. two builds of one seed lay the same stones ──────────────────────
	#
	# Which variant of a module stands where is drawn from its **position**
	# rather than from a stream, precisely so that this holds; `TEC-004` has
	# every peer build the floor from a seed rather than receive it, and a
	# client that alternated its flagstones differently would be a desync
	# nobody could see until two players disagreed about a wall.
	#
	# Asked of the **cladding**, not of the whole floor: `--build-probe`
	# already builds one seed twice and compares the slabs, and two checks
	# asking one question is the duplicate ADR-064 bans. It would also have to
	# ask `WorldHash`, which reads `global_position` — undefined outside a
	# tree, and a `SceneTree` probe has no tree to put a floor in, so every
	# entry would come back at the origin and agree about nothing.
	var first: PackedStringArray = _fingerprint(modules, calamities, kinds)
	var again: PackedStringArray = _fingerprint(modules, calamities, kinds)
	var same: bool = first == again
	print("[kit] same seed   %d piece(s), %s"
		% [first.size(), "identical" if same else "DIVERGED"])
	if not same:
		problems.append("one seed laid two different sets of stone — the kit "
			+ "has found a source of variance the builder does not have")

	# ─ 7. which of the delivered modules the game actually stands up ──────
	#
	# Measured rather than declared. `ART-006`'s piece list was written against
	# an architecture the generator does not build — walls that stop a cell
	# short of their corners, niches 0.6 m deep, a ledge on a solid plinth —
	# and the honest place to record which pieces that left on the shelf is a
	# row that recounts it every sweep.
	var idle: PackedStringArray = PackedStringArray()
	for module: StringName in DelvingsKit.DELIVERED:
		var shape: Mesh = DelvingsKit.mesh_of(module)
		if shape != null and not placed.has(shape.get_instance_id()):
			idle.append(String(module).replace("delvings_", ""))
	print("[kit] in use      %d of %d module(s); on the shelf: %s"
		% [DelvingsKit.DELIVERED.size() - idle.size(),
			DelvingsKit.DELIVERED.size(),
			", ".join(idle) if not idle.is_empty() else "none"])

	if problems.is_empty():
		print("[kit] PASS")
		quit()
		return
	for problem: String in problems:
		push_error("[kit] FAIL %s" % problem)
	quit(1)


## What each module the placement maths measures against has to be.
##
## Built from `DelvingsKit`'s own constants rather than restated, so this row
## fails when the two disagree rather than when either changes.
func _expected_bounds() -> Dictionary:
	var half: float = DelvingsKit.TILE * 0.5
	var deep: float = DelvingsKit.PANEL_DEEP * 0.5
	var bounds: Dictionary = {}
	for i: int in DelvingsKit.PANEL_HIGH.size():
		for module: StringName in DelvingsKit.PANELS[i]:
			bounds[module] = AABB(Vector3(-half, 0.0, -deep),
				Vector3(DelvingsKit.TILE, DelvingsKit.PANEL_HIGH[i],
					DelvingsKit.PANEL_DEEP))
	for module: StringName in DelvingsKit.FLAGS:
		bounds[module] = AABB(Vector3(-half, 0.0, -half),
			Vector3(DelvingsKit.TILE, DelvingsKit.FLAG_DEEP,
				DelvingsKit.TILE))
	bounds[DelvingsKit.BEAMS] = AABB(Vector3(-half, 0.0, -half),
		Vector3(DelvingsKit.TILE, DelvingsKit.BEAM_DEEP, DelvingsKit.TILE))
	bounds[DelvingsKit.FRAME] = AABB(
		Vector3(-DelvingsKit.FRAME_WIDE * 0.5, 0.0, -deep),
		Vector3(DelvingsKit.FRAME_WIDE, DelvingsKit.FRAME_HIGH,
			DelvingsKit.PANEL_DEEP))
	return bounds


## Every collision shape under a floor, and a complaint for any that is not a
## box — the kit's own `-colonly` proxies would arrive as boxes too, so the
## count is what catches them and the class is what catches a stranger.
func _shapes_under(shell: Node3D, strayed: PackedStringArray) -> int:
	var found: int = 0
	for node: Node in shell.find_children("*", "CollisionShape3D", true, false):
		found += 1
		if (node as CollisionShape3D).shape is BoxShape3D:
			continue
		strayed.append("%s carries a %s"
			% [node.name, (node as CollisionShape3D).shape.get_class()])
	return found


## Every kit piece under a floor. A core is a `BoxMesh`; a module is not.
func _pieces_under(shell: Node3D, placed: Dictionary) -> int:
	var found: int = 0
	for node: Node in shell.find_children("*", "MeshInstance3D", true, false):
		var shape: Mesh = (node as MeshInstance3D).mesh
		if shape == null or shape is BoxMesh:
			continue
		found += 1
		placed[shape.get_instance_id()] = true
	return found


## **The solids the floor stands on are the ones the builder recorded laying.**
##
## `occluders` is the same build with no nodes made, which is what `FloorVista`
## reasons about and what this compares against. Quantised to the millimetre
## for `WorldHash`'s reason: a difference no player could perceive must not
## fail, and a layout divergence is never that small.
func _solids_match(shell: Node3D, recorded: Array,
		strayed: PackedStringArray) -> void:
	var want: Dictionary = {}
	for entry: Array in recorded:
		var key: String = _stamp(entry[0] as Transform3D, entry[1] as Vector3)
		want[key] = int(want.get(key, 0)) + 1
	for child: Node in shell.get_children():
		var slab := child as MeshInstance3D
		if slab == null:
			continue
		# **Down, never up** (`TEC-001`). A slab's solid is its first child's
		# first child — `_slab` adds the body before anything else precisely so
		# that stays true, and `--build-probe` and `--surface-probe` reach for
		# it the same way.
		var body := slab.get_child(0) as StaticBody3D
		if body == null:
			strayed.append("%s has no body" % slab.name)
			continue
		var shape := body.get_child(0) as CollisionShape3D
		if shape == null:
			strayed.append("%s has no shape" % slab.name)
			continue
		var solid := shape.shape as BoxShape3D
		if solid == null:
			continue
		var key: String = _stamp(slab.transform, solid.size)
		if int(want.get(key, 0)) <= 0:
			strayed.append("%s at %v" % [slab.name, slab.position])
			continue
		want[key] = int(want[key]) - 1


static func _stamp(at: Transform3D, size: Vector3) -> String:
	var row: PackedStringArray = PackedStringArray()
	for v: Vector3 in [at.origin, at.basis.x, at.basis.y, at.basis.z, size]:
		row.append("%d,%d,%d" % [roundi(v.x * 1000.0), roundi(v.y * 1000.0),
			roundi(v.z * 1000.0)])
	return "|".join(row)


## Walk the clad slabs. Returns the lowest beam on this floor, and appends any
## surface left bare or any flagstone that does not finish on the walking plane.
func _clad_slabs(shell: Node3D, bare: PackedStringArray,
		sunk: PackedStringArray, flush: PackedStringArray) -> float:
	var ducked: float = 999.0
	for child: Node in shell.get_children():
		var slab := child as MeshInstance3D
		if slab == null:
			continue
		var role: String = String(slab.name).split("_")[0]
		var box := slab.mesh as BoxMesh
		if box == null:
			continue
		var laid: Array[MeshInstance3D] = []
		for node: Node in slab.get_children():
			var piece := node as MeshInstance3D
			if piece != null and not (piece.mesh is BoxMesh):
				laid.append(piece)
		if role == "ceiling":
			# The module's top is flush with the box's, so its soffit hangs
			# `BEAM_DEEP - box` below the clear height the collider promises.
			for piece: MeshInstance3D in laid:
				ducked = minf(ducked, (slab.transform * piece.transform
					* piece.mesh.get_aabb()).position.y)
			continue
		if role in ["floor", "ramp", "ledge"] and laid.is_empty():
			bare.append("%s at %v" % [slab.name, slab.position])
			continue
		if role in ["wall", "chamfer"]:
			# A wall long enough to carry masonry has masonry in front of it —
			# its own if `clad` laid it, its line's if `_face` did — and either
			# way the rendered box has to have been pulled out of that plane.
			#
			# Measured against the **collider**, which keeps the size the box
			# was built at. Comparing against a thickness constant instead
			# would only work for the one caller whose walls are that thick.
			if maxf(box.size.x, box.size.z) \
					<= DelvingsKit.SQUEEZE_MIN * DelvingsKit.TILE:
				continue
			var body := slab.get_child(0) as StaticBody3D
			var shape: CollisionShape3D = null
			if body != null:
				shape = body.get_child(0) as CollisionShape3D
			var solid: BoxShape3D = null
			if shape != null:
				solid = shape.shape as BoxShape3D
			if solid == null:
				continue
			if absf(solid.size.x - box.size.x) < NEAR \
					and absf(solid.size.z - box.size.z) < NEAR:
				flush.append("%s %.2f x %.2f m at %v" % [slab.name,
					box.size.x, box.size.z, slab.position])
			continue
		if role != "floor":
			continue
		for piece: MeshInstance3D in laid:
			# Against the collider's own top, **not** against `PROUD`. An
			# expectation computed from the number being checked cannot fail:
			# the first version of this row asserted the stones finish at
			# `top + PROUD`, which is where `PROUD` had just put them, and a
			# plant that sank every floor in the game by five centimetres
			# passed it.
			var lift: float = (piece.transform * piece.mesh.get_aabb()).end.y \
				- box.size.y * 0.5
			if lift <= 0.0 or lift > VOXEL:
				sunk.append("%s %.3f m off" % [slab.name, lift])
	return ducked


## Every kit piece on one floor, as a sorted, quantised description.
##
## Sorted for `WorldHash`'s reason: node order is not a promised invariant, so
## two processes that lay the same stones in a different order must agree and
## two that lay different stones must not.
func _fingerprint(modules: Array[RoomModule],
		calamities: Array[CalamityResource],
		kinds: PackedStringArray) -> PackedStringArray:
	var graph: MissionGraph = MissionGraph.build(SEEDS[0], 1)
	var lore: ExpeditionHistory = ExpeditionHistory.roll(
		SEEDS[0], calamities, kinds)
	var plan: FloorPlan = FloorPlan.build(graph, SEEDS[0], 1, modules, lore)
	var shell := Node3D.new()
	FloorBuilder.build(plan, graph, SEEDS[0], 1, shell)
	var rows: Array[String] = []
	_stones(shell, Transform3D(), rows)
	rows.sort()
	shell.free()
	var out := PackedStringArray()
	for row: String in rows:
		out.append(row)
	return out


## Walk the floor by hand, accumulating transforms, because nothing here is
## inside a tree to have a global one.
func _stones(node: Node, above: Transform3D, rows: Array[String]) -> void:
	var here: Transform3D = above
	var spatial := node as Node3D
	if spatial != null:
		here = above * spatial.transform
		var piece := node as MeshInstance3D
		if piece != null and piece.mesh != null and not (piece.mesh is BoxMesh):
			rows.append("%s %s" % [_stamp(here, piece.mesh.get_aabb().size),
				piece.mesh.get_instance_id()])
	for child: Node in node.get_children():
		_stones(child, here, rows)
