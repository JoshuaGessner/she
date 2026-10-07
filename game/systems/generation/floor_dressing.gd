class_name FloorDressing
extends RefCounted
## `M4-T10` — the clutter a worked-out mine was left with (ADR-265, `ART-006`
## §5.3).
##
## ADR-263 stood the Delvings up in stone and left the set dressing on the
## shelf, because the generator had nowhere to put it: *"a feature, not a
## seam."* This is that feature. Seven delivered pieces — an ore cart, fallen
## masonry, broken bracing, a rope coil, rusted fittings, guttered candles, a
## spoil heap — laid against the walls of the rooms, so a floor reads as
## somewhere people worked and then stopped, rather than as an empty box
## (`DES-015`: the disaster is read backward as you descend).
##
## ## Against a wall, and only where a wall is
##
## Every piece stands with its back to solid stone. That one rule does most of
## the work: a doorway and an alcove mouth are *gaps* in a wall line, so a
## piece that has to be backed by a wall across its whole width can never stand
## in one, and the rule is checked against the solids the builder actually
## laid (`FloorBuilder.occluders`) rather than against a second copy of where
## the builder puts its openings. The rest of the rules are the ones a party
## would state: nothing within reach of a doorway, nothing under or beside a
## ledge and its ramp, nothing on a cut corner, and nothing within a stride of
## anything the floor put there on purpose — a spawn, a post, the Shaft, a
## coin.
##
## ## Solid, because an ore cart you walk through is a lie
##
## `FloorBuilder._mark` lays the fallen as evidence with no collision, and that
## is right for a body on the floor: you step over it. An ore cart is a metre
## and a tenth of iron, and walking through one is a world that is not what it
## looks like — Principle 6's legibility, failed by a prop. So a piece keeps its `-colonly` proxy and the navmesh
## bakes around it — which is why every rule above is about **passage**: the
## rooms are laid wall-first so that a cart against one never stands between a
## door and the room it serves.
##
## The one exception is a piece lower than the body can step over. A rope coil
## is eight centimetres of hemp; as a solid it would stop a walking body dead
## on the flat, and nobody has ever been stopped by a coil of rope.
##
## ## Decided from the position, not from a stream
##
## `DelvingsKit._draw`'s rule and its reason: every peer builds the floor from
## the seed (`TEC-004`), so which piece stands where is a hash of where it
## stands, and the order rooms happen to be visited cannot reach it
## (`TEC-007` §1). It draws nothing from any stage's stream, so it moved no
## slab and no room. What it can move is a drawn point that would have landed
## on a piece — a post, a coin, the Waystone — which `FloorAnchors` now draws
## again, somewhere a body can stand.
##
## ## What it leaves undressed, on purpose
##
## **A machine's room.** `DES-015` Layer 3 stamps a situation into a room — the
## fallen, their gear, the hazard that killed them — and that room is a
## sentence. Clutter laid over it is noise over the one room on the floor that
## is saying something. And **a crawl**, which is 1.4 m of crouch and no room
## to put anything in.

## Where the pieces live, and the seven of them. Listed rather than globbed so
## that a piece disappearing is a failure and not a quieter floor.
const SHELF: String = "res://art/props/%s.glb"
const DELIVERED: Array[StringName] = [
	&"dressing_ore_cart", &"dressing_fallen_masonry",
	&"dressing_broken_bracing", &"dressing_rope_coil",
	&"dressing_rusted_fittings", &"dressing_guttered_candles",
	&"dressing_spoil_heap",
]

## What a body can step over without noticing, metres. The player's own climb
## (`RoomSet.nav_settings`: *"the player climbs about 0.10 m"*), so a piece is
## solid exactly when it is something a body would otherwise have to walk
## *through*.
const STEP_OVER: float = 0.10

## A room must be this many cells across both ways to be dressed ⟨tune⟩.
##
## Three cells is 6.0 m, 5.4 m inside its walls; the deepest piece takes 1.35 m
## of that, and two on facing walls leave 2.7 m — three body-widths — between
## them. A two-cell room would be left 2.7 m by *one*, which is a corridor with
## a cart in it.
const MIN_ROOM_CELLS: int = 3
## Wall cells per piece ⟨tune⟩. `ART-006`: *"six to ten pieces is enough to
## dress a floor"* — of *kinds*; this is how thickly they are laid.
##
## **Thicker since ADR-348**: at five, a pillared hall carried three pieces
## along walls 60 m round and read as an empty stone box in every `--ink-shot`
## view — a mine nobody had worked. At three a hall carries five or six and a
## small room still one or two, which is the density a worked-out level reads
## at in Darkest Dungeon's corridors or Hunt's compounds: clutter at every
## wall, never in the walking line.
const CELLS_PER_PIECE: int = 3
## How far a piece stands off the stone behind it, metres. Enough that the two
## never share a plane.
const OFF_THE_WALL: float = 0.03
## How near a piece may come to the middle of a doorway cell ⟨tune⟩.
##
## A doorway cell is the corridor's, one metre outside the wall line; at 2.2 m
## a piece is kept out of the wall cell either side of the opening, so the
## threshold and the step into the room are always clear.
const DOOR_CLEAR: float = 2.2
## How far a piece is kept from a ledge, its ramp, a cut corner or a crossing
## ramp, metres ⟨tune⟩. A body's width and a little, so the foot of a ramp is
## always something you can walk onto from the side as well as from its end.
const RAMP_CLEAR: float = 1.0
## How far a piece is kept from anything the floor placed on purpose ⟨tune⟩ — a
## body's radius (0.45 m) and the reach to pick a thing up beside it.
const POINT_CLEAR: float = 1.0
## How far two pieces are kept apart, so two carts never read as one wreck.
const APART: float = 0.4
## Below the floor a solid may reach without counting as being in the way.
## Every floor slab's top is the walking plane at 0; the laps and the ramps'
## buried ends sit under it.
const ABOVE_FLOOR: float = 0.05
## How high the column over a piece has to be clear of a ledge's deck. The
## deck's underside is at 2.2 m; the space under it is `TEC-008` §3.3.1's
## refuge, and a cart parked in a refuge fills it.
const OVERHEAD: float = 3.0

## The slab roles that are a wall a piece may stand against, and those it must
## keep `RAMP_CLEAR` from — see `FloorBuilder.SURFACES` for what each is.
const BACKING: Array[String] = ["wall"]
const KEEP_OFF: Array[String] = ["ledge_floor", "ledge_ramp", "ramp", "chamfer"]
const UNDERFOOT: Array[String] = ["floor", "ceiling"]

## Each piece's bounds in its own frame, measured once from its render mesh.
static var _bounds: Dictionary[StringName, AABB] = {}


## **Where every piece stands on one floor**, as data — nothing is made.
##
## Each entry is `{"piece": StringName, "at": Transform3D, "room": int,
## "footprint": Rect2, "high": float, "solid": bool}`. `occluders` is
## `FloorBuilder.occluders` for the same floor, `clear` is every
## `[point, radius]` the floor keeps free, and `skipped` the rooms left
## undressed. One path, so the probe reads exactly what the floor lays.
static func plan_for(plan: FloorPlan, graph: MissionGraph, occluders: Array,
		clear: Array, skipped: PackedInt32Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var solids: Array = _index(occluders)
	for node: int in graph.size():
		if skipped.has(node):
			continue
		var rect: Rect2i = plan.rect_of(node)
		if mini(rect.size.x, rect.size.y) < MIN_ROOM_CELLS:
			continue
		var doors: Array[Vector3] = []
		for cell: Vector2i in plan.doors_of(node):
			doors.append(FloorBuilder.at(cell)
				+ Vector3(FloorBuilder.CELL * 0.5, 0.0, FloorBuilder.CELL * 0.5))
		var spots: Array[Array] = _spots(rect)
		# Visited in the order their own hashes give, not the order the loop
		# made them: the draw is by position, so the first piece a room takes
		# is not always the one on its north wall.
		spots.sort_custom(func(a: Array, b: Array) -> bool:
			return _draw(a[0] as Vector3, 1 << 20) < _draw(b[0] as Vector3, 1 << 20))
		var wanted: int = maxi(1, (spots.size() + 4) / CELLS_PER_PIECE)
		var laid: int = 0
		for spot: Array in spots:
			if laid >= wanted:
				break
			var piece: Dictionary = _fit(spot[0] as Vector3, spot[1] as Vector3,
				solids, doors, clear, out)
			if piece.is_empty():
				continue
			piece["room"] = node
			out.append(piece)
			laid += 1
	return out


## Stand the pieces `placed` describes under `into`, in a node of their own.
##
## **A node of their own**, because a floor's root is read by probes as a flat
## list of slabs — `kit_probe`, `floor_surface_probe` and `--build-probe` all
## take its children to be architecture — and a cart among them would be a
## slab with no box.
static func raise(placed: Array[Dictionary], into: Node3D) -> Node3D:
	var shelf := Node3D.new()
	shelf.name = "dressing"
	into.add_child(shelf)
	var count: int = 0
	for entry: Dictionary in placed:
		var packed := load(SHELF % entry["piece"]) as PackedScene
		if packed == null:
			push_error("[dressing] no piece `%s`" % entry["piece"])
			continue
		var made := packed.instantiate() as Node3D
		made.name = "%s_%d" % [entry["piece"], count]
		made.transform = entry["at"]
		# Set dressing does not get lines (`ART-005`), and its modeller said
		# so in R. Read once per piece, on the mesh (ADR-269).
		InkPass.classify(made)
		for node: Node in made.find_children("*", "PhysicsBody3D", true, false):
			if not bool(entry["solid"]):
				# Freed before the tree sees it, for `ItemResource.look`'s
				# reason: a body that has entered the tree has registered.
				node.free()
				continue
			var body := node as PhysicsBody3D
			body.collision_layer = CollisionLayers.WORLD
			body.collision_mask = 0
		shelf.add_child(made)
		count += 1
	return shelf


## The solid pieces as occluders, `[Transform3D, size, "dressing"]` in
## `FloorBuilder.occluders`' shape — for `FloorVista`, which has to know a cart
## is between the walk and a glint. A box around each: coarser than the piece,
## which only ever errs towards calling a sight blocked.
static func as_occluders(placed: Array[Dictionary]) -> Array:
	var out: Array = []
	for entry: Dictionary in placed:
		if not bool(entry["solid"]):
			continue
		var local: AABB = bounds_of(entry["piece"])
		var at: Transform3D = entry["at"]
		out.append([at * Transform3D(Basis(), local.get_center()), local.size,
			"dressing"])
	return out


## A piece's bounds in its own frame, from its render mesh. Empty if missing.
static func bounds_of(piece: StringName) -> AABB:
	if _bounds.has(piece):
		return _bounds[piece]
	var found := AABB()
	var packed := load(SHELF % piece) as PackedScene
	if packed != null:
		var made: Node = packed.instantiate()
		var first: bool = true
		for node: Node in made.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh.mesh == null:
				continue
			var box: AABB = _local(mesh, made) * mesh.mesh.get_aabb()
			found = box if first else found.merge(box)
			first = false
		made.free()
	else:
		push_error("[dressing] no piece `%s` in %s" % [piece, SHELF % piece])
	_bounds[piece] = found
	return found


## One candidate per wall cell of a room: `[where the wall's inner face is, at
## the cell's middle, and which way is into the room]`.
##
## **The end cells are not candidates.** A corner cell holds the chamfer on
## rough floors and the perpendicular wall on every floor, and a piece centred
## in it would stand inside the other wall; a corner is also where the doorways
## a plan cuts nearest the end of a wall arrive.
static func _spots(rect: Rect2i) -> Array[Array]:
	var out: Array[Array] = []
	var cell: float = FloorBuilder.CELL
	var thick: float = FloorBuilder.WALL_THICK
	var low: Vector3 = FloorBuilder.at(rect.position)
	var high: Vector3 = FloorBuilder.at(rect.end)
	for x: int in range(rect.position.x + 1, rect.end.x - 1):
		var along: float = x * cell + cell * 0.5
		out.append([Vector3(along, 0.0, low.z + thick), Vector3.BACK])
		out.append([Vector3(along, 0.0, high.z - thick), Vector3.FORWARD])
	for z: int in range(rect.position.y + 1, rect.end.y - 1):
		var along: float = z * cell + cell * 0.5
		out.append([Vector3(low.x + thick, 0.0, along), Vector3.RIGHT])
		out.append([Vector3(high.x - thick, 0.0, along), Vector3.LEFT])
	return out


## The piece this spot draws, placed, if it fits there — or empty.
##
## One piece is tried per spot, and it is the one the position draws. Trying
## the others in turn until one fitted would put the smallest pieces wherever
## the large ones were refused, and a floor dressed only in candles is a floor
## whose rules are showing.
static func _fit(face: Vector3, inward: Vector3, solids: Array,
		doors: Array[Vector3], clear: Array,
		laid: Array[Dictionary]) -> Dictionary:
	var piece: StringName = DELIVERED[_draw(face, DELIVERED.size())]
	var local: AABB = bounds_of(piece)
	if not local.has_volume():
		return {}
	# Long side along the wall, and a flip drawn from the position: the same
	# cart facing the room or facing the stone is still a cart against a wall,
	# and two carts in a row both facing out is a car park.
	var yaw: float = atan2(inward.x, inward.z)
	if _draw(face + Vector3.UP, 2) == 1:
		yaw += PI
	var turned := Transform3D(Basis(Vector3.UP, yaw), Vector3.ZERO)
	var box: AABB = turned * local
	# Its back on the stone and its middle on the cell's.
	var back: float = _along(box, -inward)
	var sideways := Vector3(absf(inward.z), 0.0, absf(inward.x))
	var middle: float = (box.get_center()).dot(sideways)
	var origin: Vector3 = face + inward * (OFF_THE_WALL + back) \
		- sideways * middle
	origin.y = -local.position.y
	var at := Transform3D(turned.basis, origin)
	var placed: AABB = at * local
	var footprint := Rect2(placed.position.x, placed.position.z,
		placed.size.x, placed.size.z)

	if not _backed(placed, inward, solids):
		return {}
	var body := AABB(Vector3(placed.position.x, ABOVE_FLOOR, placed.position.z),
		Vector3(placed.size.x, maxf(placed.end.y - ABOVE_FLOOR, 0.01),
			placed.size.z))
	for solid: Array in solids:
		var role: String = solid[1]
		var bounds: AABB = solid[0]
		if UNDERFOOT.has(role):
			continue
		if KEEP_OFF.has(role):
			var column := AABB(
				Vector3(body.position.x, -0.5, body.position.z),
				Vector3(body.size.x, OVERHEAD + 0.5, body.size.z)).grow(RAMP_CLEAR)
			if column.intersects(bounds):
				return {}
			continue
		if body.intersects(bounds):
			return {}
	for door: Vector3 in doors:
		if _gap(footprint, door) < DOOR_CLEAR:
			return {}
	for keep: Array in clear:
		if _gap(footprint, keep[0] as Vector3) < float(keep[1]):
			return {}
	for other: Dictionary in laid:
		if (other["footprint"] as Rect2).grow(APART).intersects(footprint):
			return {}
	return {
		"piece": piece,
		"at": at,
		"footprint": footprint,
		"high": placed.size.y,
		"solid": local.size.y > STEP_OVER,
	}


## Is there stone behind this piece across the whole of its width?
##
## A wall line is laid as runs between its openings, so a piece in front of a
## doorway or an alcove mouth has a gap behind it, and this is what says no.
## The run has to reach past both ends of the piece and stand at least as
## high as it, within a centimetre or two of its back.
static func _backed(placed: AABB, inward: Vector3, solids: Array) -> bool:
	var sideways := Vector3(absf(inward.z), 0.0, absf(inward.x))
	var from: float = placed.position.dot(sideways)
	var to: float = placed.end.dot(sideways)
	# Both measured along `inward`: the piece's back is its least reach that
	# way, and the wall's face is its greatest.
	var back_face: float = -_along(placed, -inward)
	for solid: Array in solids:
		if not BACKING.has(solid[1] as String):
			continue
		var wall: AABB = solid[0]
		if wall.end.y < placed.end.y:
			continue
		var face: float = _along(wall, inward)
		if absf(face - back_face) > OFF_THE_WALL + 0.02:
			continue
		if wall.position.dot(sideways) <= from and wall.end.dot(sideways) >= to:
			return true
	return false


## How far a box reaches along `direction` (a unit axis), signed.
static func _along(box: AABB, direction: Vector3) -> float:
	var reach: float = -INF
	for i: int in 8:
		reach = maxf(reach, box.get_endpoint(i).dot(direction))
	return reach


## Metres across the floor from a footprint to a point, zero inside it.
static func _gap(footprint: Rect2, point: Vector3) -> float:
	var dx: float = maxf(maxf(footprint.position.x - point.x, 0.0),
		point.x - footprint.end.x)
	var dz: float = maxf(maxf(footprint.position.y - point.z, 0.0),
		point.z - footprint.end.y)
	return sqrt(dx * dx + dz * dz)


## Every occluder as `[world bounds, role]`. The bounds of a tilted slab are
## larger than the slab, which only ever errs towards leaving a spot empty.
static func _index(occluders: Array) -> Array:
	var out: Array = []
	for entry: Array in occluders:
		var size: Vector3 = entry[1]
		var bounds: AABB = (entry[0] as Transform3D) * AABB(-size * 0.5, size)
		out.append([bounds, entry[2] if entry.size() > 2 else "slab"])
	return out


## A mesh's transform relative to the scene it came in, by walking up.
static func _local(node: Node3D, root: Node) -> Transform3D:
	var at: Transform3D = node.transform
	var above: Node = node.get_parent()
	while above != null and above != root:
		var spatial := above as Node3D
		if spatial != null:
			at = spatial.transform * at
		above = above.get_parent()
	return at


## `DelvingsKit._draw`, to the centimetre, so the two agree about how a
## position becomes a choice.
static func _draw(at: Vector3, sides: int) -> int:
	return DelvingsKit._draw(at, sides)
