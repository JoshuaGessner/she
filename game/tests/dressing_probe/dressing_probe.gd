extends Node

## **The set dressing is laid, and it is in nobody's way** (`M4-T10`, ADR-265).
##
## `FloorDressing` puts solid pieces into rooms a party has to walk, so the
## questions that matter are about passage, and each is asked here as the
## physical claim rather than as the rule that is supposed to produce it. An
## expectation computed from the placement's own constants cannot fail (ADR-263
## found a row doing exactly that); so this probe never reads `DOOR_CLEAR` or
## `_backed`, and asks instead whether a body could step through each doorway,
## whether there is stone behind each piece, whether any piece stands inside
## any solid, and whether anything the floor put down on purpose is inside a
## piece.
##
## Whether a party can still **walk** the dressed floor is `--reach-probe`'s,
## which lays the same pieces on the floors it bakes and drives a body across
## them. Whether it **looks** right is `--delvings-shot` (ADR-093).

## Floors to lay. `kit_probe`'s three seeds at every depth, and `--reach-probe`'s
## panel on top, because the traversal rows walk those and this should have
## looked at what they walk.
const SEEDS: Array[int] = [31346, 78901, 8675309, 11111, 40404, 57721, 66666,
	13579, 24680]
## A body's radius, for "is anything the floor placed inside a piece".
const BODY: float = 0.45
## How deep a threshold is: the cell of room just inside a doorway, which a
## body crosses to come in.
const THRESHOLD: float = 2.0
## And how wide: the opening and **a body either side of it**. A party comes
## through a door and spreads out, and a cart hard against the jamb is a door
## one body wide on the room side. Measured at the opening alone, this row
## passed with the doorway rule removed — the stone-behind rule keeps a piece
## out of the opening by itself — so it was asking the question nothing could
## get wrong.
const THRESHOLD_WIDE: float = FloorBuilder.DOOR_WIDTH + 4.0 * BODY
## How far behind a piece's back the stone is looked for.
const BEHIND: float = 0.15


func _ready() -> void:
	var problems: PackedStringArray = PackedStringArray()

	# ─ 1. every piece loads, and a solid one has something to be solid with ─
	var broken: PackedStringArray = PackedStringArray()
	for piece: StringName in FloorDressing.DELIVERED:
		var box: AABB = FloorDressing.bounds_of(piece)
		var packed := load(FloorDressing.SHELF % piece) as PackedScene
		if packed == null or not box.has_volume():
			broken.append("%s will not load" % piece)
			continue
		var made: Node = packed.instantiate()
		var bodies: int = made.find_children("*", "PhysicsBody3D", true, false).size()
		made.free()
		if box.size.y > FloorDressing.STEP_OVER and bodies == 0:
			broken.append("%s is %.2f m tall and carries no collision"
				% [piece, box.size.y])
	print("[dressing] delivered  %d piece(s), %d broken"
		% [FloorDressing.DELIVERED.size(), broken.size()])
	if not broken.is_empty():
		problems.append("the shelf is not whole: %s" % "; ".join(broken))

	# ─ 2. lay the corpus ──────────────────────────────────────────────────
	var floors: int = 0
	var bare_floors: int = 0
	var laid: int = 0
	var used: Dictionary = {}
	var inside: PackedStringArray = PackedStringArray()
	var unbacked: PackedStringArray = PackedStringArray()
	var doorway: PackedStringArray = PackedStringArray()
	var buried: PackedStringArray = PackedStringArray()
	var noise: PackedStringArray = PackedStringArray()
	var solidity: PackedStringArray = PackedStringArray()
	for run_seed: int in SEEDS:
		for depth: int in RunFile.LAST_FLOOR + 1:
			var at: DelvingsFloor = DelvingsFloor.of(run_seed, depth)
			if not at.problems().is_empty():
				continue
			floors += 1
			var pieces: Array[Dictionary] = at.dressing()
			laid += pieces.size()
			if pieces.is_empty():
				bare_floors += 1
			var solids: Array = FloorBuilder.occluders(
				at._plan, at._graph, run_seed, depth)
			var where := "seed %d floor %d" % [run_seed, depth]
			for piece: Dictionary in pieces:
				used[piece["piece"]] = int(used.get(piece["piece"], 0)) + 1
				var box: AABB = (piece["at"] as Transform3D) \
					* FloorDressing.bounds_of(piece["piece"])
				var name := "%s %s at %v" % [where, piece["piece"],
					(piece["at"] as Transform3D).origin.snappedf(0.01)]
				var hit: String = _stands_in(box, solids)
				if not hit.is_empty():
					inside.append("%s, inside a %s" % [name, hit])
				if not _stone_behind(piece["at"] as Transform3D,
						FloorDressing.bounds_of(piece["piece"]), solids):
					unbacked.append(name)
				var room: int = int(piece["room"])
				var machine: bool = at.machines().at(room) != null
				if machine:
					noise.append("%s, in the room a machine is in" % name)
			doorway.append_array(_thresholds(at, pieces, where))
			buried.append_array(_buried(at, pieces, where))
			solidity.append_array(_solidity(at, pieces, where))

	print("[dressing] laid       %d piece(s) over %d floor(s), %d floor(s) bare"
		% [laid, floors, bare_floors])
	if laid == 0 or bare_floors * 2 > floors:
		problems.append(("%d of %d floor(s) carry no dressing at all — the rules "
			+ "have closed over the rooms they were meant to dress")
			% [bare_floors, floors])

	# ─ 3. nothing stands inside the architecture ─────────────────────────
	print("[dressing] in solids  %d piece(s)" % inside.size())
	if not inside.is_empty():
		problems.append(("%d piece(s) stand inside a wall, a ledge or a ramp (%s)")
			% [inside.size(), "; ".join(inside.slice(0, 3))])

	# ─ 4. every piece has stone behind it ────────────────────────────────
	print("[dressing] backed     %d piece(s) with no wall behind them"
		% unbacked.size())
	if not unbacked.is_empty():
		problems.append(("%d piece(s) have no stone behind them (%s) — standing "
			+ "in an opening, a doorway or an alcove's mouth")
			% [unbacked.size(), "; ".join(unbacked.slice(0, 3))])

	# ─ 5. a body can step through every doorway ──────────────────────────
	print("[dressing] doorways   %d threshold(s) with a piece in them"
		% doorway.size())
	if not doorway.is_empty():
		problems.append(("%d doorway(s) open onto a piece of dressing (%s) — "
			+ "the step into the room is the one place nothing may stand")
			% [doorway.size(), "; ".join(doorway.slice(0, 3))])

	# ─ 6. nothing the floor placed on purpose is inside a piece ───────────
	print("[dressing] buried     %d spawn(s), post(s) or find(s) inside a piece"
		% buried.size())
	if not buried.is_empty():
		problems.append(("%d thing(s) the floor put down on purpose are inside "
			+ "a piece of dressing (%s)") % [buried.size(),
				"; ".join(buried.slice(0, 3))])

	# ─ 7. a machine's room is left saying what it says ────────────────────
	print("[dressing] machines   %d piece(s) in a machine's room" % noise.size())
	if not noise.is_empty():
		problems.append(("%d piece(s) were laid in a machine's room (%s) — "
			+ "clutter over the one room on the floor that is saying something")
			% [noise.size(), "; ".join(noise.slice(0, 3))])

	# ─ 8. solid when it is something you would have to walk through ───────
	print("[dressing] solid      %d piece(s) solid or not as their height says"
		% (laid - solidity.size()) + ", %d wrong" % solidity.size())
	if not solidity.is_empty():
		problems.append(("%d piece(s) are solid when a body steps over them, "
			+ "or walked through when they stand in the way (%s)")
			% [solidity.size(), "; ".join(solidity.slice(0, 3))])

	# ─ 9. one seed lays one set of clutter ─────────────────────────────
	var once: Array[Dictionary] = DelvingsFloor.of(SEEDS[0], 1).dressing()
	var twice: Array[Dictionary] = DelvingsFloor.of(SEEDS[0], 1).dressing()
	var same: bool = once.size() == twice.size()
	for i: int in mini(once.size(), twice.size()):
		if once[i]["piece"] != twice[i]["piece"] or not \
				(once[i]["at"] as Transform3D).is_equal_approx(twice[i]["at"]):
			same = false
	print("[dressing] same seed  %d piece(s), %s"
		% [once.size(), "identical" if same else "DIVERGED"])
	if not same:
		problems.append("one seed dressed its floor two ways — `TEC-004` has "
			+ "every peer build the floor, so that is a desync in a cart")

	# ─ 10. which of the delivered pieces the floors actually stand up ─────
	var idle: PackedStringArray = PackedStringArray()
	for piece: StringName in FloorDressing.DELIVERED:
		if not used.has(piece):
			idle.append(String(piece).replace("dressing_", ""))
	print("[dressing] in use     %d of %d piece(s); on the shelf: %s"
		% [FloorDressing.DELIVERED.size() - idle.size(),
			FloorDressing.DELIVERED.size(),
			", ".join(idle) if not idle.is_empty() else "none"])
	if not idle.is_empty():
		problems.append(("%s were delivered and never laid on %d floor(s) — "
			+ "a piece the rules can never fit is a piece nobody sees")
			% [", ".join(idle), floors])

	if problems.is_empty():
		print("[dressing] PASS")
		get_tree().quit()
		return
	for problem: String in problems:
		push_error("[dressing] FAIL %s" % problem)
	get_tree().quit(1)


## The role of the first solid `box` stands inside, or empty.
##
## Exact rather than by bounds: the piece's box is tested against each solid in
## the **solid's own frame**, so a tilted ramp is its slab and not the much
## larger box around it. Floors and ceilings are what a piece stands on and
## under, and are the only solids it may touch.
func _stands_in(box: AABB, solids: Array) -> String:
	for solid: Array in solids:
		var role: String = solid[2] if solid.size() > 2 else "slab"
		if role in ["floor", "ceiling"]:
			continue
		var frame: Transform3D = solid[0]
		var size: Vector3 = solid[1]
		var body := AABB(Vector3(box.position.x, box.position.y + 0.02,
			box.position.z), box.size - Vector3(0.0, 0.02, 0.0))
		if _obb_meets(frame, size, body):
			return role
	return ""


## Does the box `size` placed at `frame` meet the axis-aligned `box`?
## Separating axes over both boxes' faces, which is exact for two boxes.
func _obb_meets(frame: Transform3D, size: Vector3, box: AABB) -> bool:
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		frame.basis.x.normalized(), frame.basis.y.normalized(),
		frame.basis.z.normalized()]
	var half: Vector3 = size * 0.5
	var corners: Array[Vector3] = []
	for i: int in 8:
		corners.append(frame * Vector3(
			half.x if i & 1 else -half.x,
			half.y if i & 2 else -half.y,
			half.z if i & 4 else -half.z))
	for axis: Vector3 in axes:
		var a_lo: float = INF
		var a_hi: float = -INF
		for c: Vector3 in corners:
			a_lo = minf(a_lo, c.dot(axis))
			a_hi = maxf(a_hi, c.dot(axis))
		var b_lo: float = INF
		var b_hi: float = -INF
		for i: int in 8:
			var p: float = box.get_endpoint(i).dot(axis)
			b_lo = minf(b_lo, p)
			b_hi = maxf(b_hi, p)
		if a_hi <= b_lo or b_hi <= a_lo:
			return false
	return true


## Is there a wall's solid just behind the piece, at both ends and the middle
## of its back, at knee height? Asked as points inside a solid's own frame.
func _stone_behind(at: Transform3D, local: AABB, solids: Array) -> bool:
	# The piece's back is whichever of its long faces is nearer a wall; try
	# both, since the flip means it may face the room or the stone.
	for side: float in [-1.0, 1.0]:
		var back_z: float = local.position.z if side < 0.0 else local.end.z
		var ok: bool = true
		for across: float in [0.1, 0.5, 0.9]:
			var x: float = lerpf(local.position.x, local.end.x, across)
			var probe: Vector3 = at * Vector3(x, 0.5, back_z + side * BEHIND)
			if not _in_wall(probe, solids):
				ok = false
				break
		if ok:
			return true
	return false


func _in_wall(point: Vector3, solids: Array) -> bool:
	for solid: Array in solids:
		if (solid[2] if solid.size() > 2 else "slab") != "wall":
			continue
		var local: Vector3 = (solid[0] as Transform3D).affine_inverse() * point
		var half: Vector3 = (solid[1] as Vector3) * 0.5
		if absf(local.x) <= half.x and absf(local.y) <= half.y \
				and absf(local.z) <= half.z:
			return true
	return false


## Each doorway's threshold — the door and a body either side, one cell in — that a
## piece's footprint reaches into.
func _thresholds(at: DelvingsFloor, pieces: Array[Dictionary],
		where: String) -> PackedStringArray:
	var out := PackedStringArray()
	var cell: float = FloorBuilder.CELL
	for piece: Dictionary in pieces:
		var node: int = int(piece["room"])
		var rect: Rect2i = at._plan.rect_of(node)
		var room := Rect2(FloorBuilder.at(rect.position).x,
			FloorBuilder.at(rect.position).z, rect.size.x * cell,
			rect.size.y * cell)
		var foot: Rect2 = piece["footprint"]
		for door: Vector2i in at._plan.doors_of(node):
			var mid := Vector2(door.x * cell + cell * 0.5,
				door.y * cell + cell * 0.5)
			# Into the room from the door, one cell deep and a door wide.
			var into := Vector2(
				signf(room.get_center().x - mid.x) if door.x < rect.position.x \
					or door.x >= rect.end.x else 0.0,
				signf(room.get_center().y - mid.y) if door.y < rect.position.y \
					or door.y >= rect.end.y else 0.0)
			var step: Vector2 = mid + into * cell
			var span := Vector2(
				THRESHOLD_WIDE if into.x == 0.0 else THRESHOLD,
				THRESHOLD_WIDE if into.y == 0.0 else THRESHOLD)
			var threshold := Rect2(step - span * 0.5, span)
			if threshold.intersects(foot):
				out.append("%s %s in the door at %v" % [where, piece["piece"],
					door])
	return out


## Every point the floor places a body or a thing at that a piece covers.
func _buried(at: DelvingsFloor, pieces: Array[Dictionary],
		where: String) -> PackedStringArray:
	var out := PackedStringArray()
	var points: Array[Vector3] = []
	points.append_array(at.spawns())
	points.append_array(at.enemy_posts())
	points.append_array(at.machine_posts())
	points.append(at.shaft())
	points.append(at.prize())
	points.append(at.hunter())
	points.append(at.survey_point())
	var dug: Array = at.barrow()
	if not dug.is_empty():
		points.append(dug[1] as Vector3)
	for row: Array in at.fixtures():
		points.append(row[1] as Vector3)
	for row: Array in at.filler():
		points.append(row[1] as Vector3)
	for piece: Dictionary in pieces:
		var foot: Rect2 = (piece["footprint"] as Rect2).grow(BODY)
		for point: Vector3 in points:
			if foot.has_point(Vector2(point.x, point.z)):
				out.append("%s %s over %v" % [where, piece["piece"],
					point.snappedf(0.1)])
	return out


## Raised for real, so the answer is the nodes a floor gets and not the flag
## the data carries.
func _solidity(at: DelvingsFloor, pieces: Array[Dictionary],
		where: String) -> PackedStringArray:
	var out := PackedStringArray()
	var shell := Node3D.new()
	var shelf: Node3D = FloorDressing.raise(pieces, shell)
	var i: int = 0
	for made: Node in shelf.get_children():
		var piece: Dictionary = pieces[i]
		i += 1
		var tall: bool = FloorDressing.bounds_of(piece["piece"]).size.y \
			> FloorDressing.STEP_OVER
		var bodies: Array[Node] = made.find_children("*", "PhysicsBody3D",
			true, false)
		var solid: bool = not bodies.is_empty()
		for body: Node in bodies:
			if (body as PhysicsBody3D).collision_layer != CollisionLayers.WORLD:
				out.append("%s %s is solid on the wrong layer"
					% [where, piece["piece"]])
		if solid != tall:
			out.append("%s %s is %s at %.2f m" % [where, piece["piece"],
				"solid" if solid else "walked through",
				FloorDressing.bounds_of(piece["piece"]).size.y])
	shell.free()
	return out
