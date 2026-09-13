class_name FloorVista
extends RefCounted
## `M4-T28` — every generated floor offers the moment `DES-015` asks for, and
## offers it by construction (ADR-215).
##
## `DES-015`'s vista rule: *"each floor should contain at least one moment where
## the player can see something valuable and distant that they must route
## toward."* ADR-207 made it measurable — walk from the arrival point to the
## Shaft and ask what is in view — and ADR-210 found why floors fail it: floor 0
## could hold nothing that glitters at all, and a deep floor could hold several
## with no line from the walk to any of them. The generator's own floors prove
## the view is reachable, so the fault is variance, and the fix is a guarantee
## rather than a redesign.
##
## ## What it decides, and from what
##
## **Where a glint can be seen from the walk**, answered from the plan and from
## the slabs the builder lays — never from the navmesh or the physics engine.
## Loot placement is a stage of a seeded pipeline (`TEC-007`), and a Recast bake
## is threaded and platform-dependent (ADR-172): two machines handed one seed
## must pick one spot, and a bug report has to replay on a different one.
##
## - **The walk** is the shortest door-to-door line from the arrival point to
##   the Shaft through the plan's rooms and corridors — the navmesh route at the
##   resolution of rooms — sampled every `STRIDE` at eye height, each sample
##   carrying the way the body is facing.
## - **A sight** is a segment from an eye on the walk to a point at glint
##   height, tested against every box `FloorBuilder.occluders` returns: the same
##   slabs at the same transforms, as data.
## - **A vista** is a sight that looks **forward** — nobody walking to the Shaft
##   is looking over their shoulder — from **outside the room** the glint lies
##   in, because a thing seen only from inside its own room is neither distant
##   nor something to route toward, and at least `NEAR` long.


## The shortest sight that counts as distant, in metres ⟨tune⟩.
##
## **Inside the fog, and past a corridor.** Fog begins at `floor_fog_begin`,
## 10 m, so a vista at 8 m arrives before anything has dissolved it; and
## `FloorPlan.DOGLEG_RUN` caps a straight corridor at four cells, 8 m, so a
## sight this long either runs the whole of a straight hall or crosses a room to
## get there. ADR-210's good floors put their glitter in view at 9.3–24.1 m.
const NEAR: float = 8.0
## Beyond this a longer sight is not a better one ⟨tune⟩.
##
## Fog is 42% of the way to black at 20 m, and a glint that has to be looked for
## is not a moment. Capping the score here lets the spot seen from **more of the
## walk** win among spots that are all far enough, which is also what survives a
## navmesh route cutting a corner the plan's walk did not.
const FAR: float = 20.0
## How many samples of the walk a sight must hold for, one per `STRIDE` ⟨tune⟩.
##
## **A moment lasts.** Four metres is over a second at walking pace (3.4 m s⁻¹),
## long enough to be noticed rather than glimpsed — and it is also what survives
## the navmesh route disagreeing with this walk by a corner. Measured without it:
## seed 66666 floor 1 counted its Prize as the floor's vista on the strength of
## **one** sample, laid no bead, and the navmesh walk never saw the Prize at all.
const SEEN_LEAST: int = 4
## Eye height on the walk, and the one `--vista-probe` measures from.
const EYE: float = 1.6
## Where a glint is looked for: an item sits `FloorAnchors.CLEARANCE` off the
## floor and its mesh stands about a quarter-metre tall.
const GLINT: float = 0.35
## Metres between samples of the walk.
const STRIDE: float = 1.0
## Metres between candidate spots in a room. Coarse on purpose: the score is
## seen-from-the-walk, which does not change much across half a cell, and the
## search runs on every floor a host lays.
const STEP: float = 2.0
## Clear space a spot needs above it. A glint tucked under the high end of a
## ledge ramp can be in sight and still be somewhere nobody can stand to take it.
const HEADROOM: float = 2.0

var _plan: FloorPlan = null
var _graph: MissionGraph = null
var _anchors: FloorAnchors = null
## Per sample: eye position, facing (unit, flat), and the room it stands in or -1.
var _eyes: Array[Vector3] = []
var _facing: Array[Vector3] = []
var _inside: PackedInt32Array = PackedInt32Array()
## Per occluder: the inverse of its transform, its half-size, and its bounds.
var _inverse: Array[Transform3D] = []
var _half: Array[Vector3] = []
var _bounds: Array[AABB] = []
## Plan cell → the occluders whose bounds reach into it.
var _grid: Dictionary = {}
var _stamp: PackedInt32Array = PackedInt32Array()
var _pass: int = 0


## Read the walk and the occluders of one floor.
##
## `arrival` is where the walk starts. Passed in rather than read off
## `FloorAnchors`, because *which* of the party's arrival points the walk leaves
## from is the level's to say, and the probes that measure this walk leave from
## the first of a full party's.
static func of(plan: FloorPlan, graph: MissionGraph, anchors: FloorAnchors,
		occluders: Array, arrival: Vector3) -> FloorVista:
	var vista := FloorVista.new()
	vista._plan = plan
	vista._graph = graph
	vista._anchors = anchors
	vista._index(occluders)
	vista._sample(vista._walk(arrival))
	return vista


## Which room a point on the floor stands in, or -1 for a corridor.
func room_at(point: Vector3) -> int:
	return room_of(_plan, _graph, point)


## The same question asked of any plan — static so `--vista-probe` judges
## *outside its room* by this definition and no copy of it.
static func room_of(plan: FloorPlan, graph: MissionGraph, point: Vector3) -> int:
	var cell := Vector2i(floori(point.x / FloorBuilder.CELL),
		floori(point.z / FloorBuilder.CELL))
	for node: int in graph.size():
		if plan.rect_of(node).has_point(cell):
			return node
	return -1


## How far the walk sees `point`, and from how many samples.
##
## `x` is the longest qualifying sight, capped at `FAR`, or 0 when there is
## none; `y` counts the samples that have one.
func view(point: Vector3) -> Vector2:
	var glint := Vector3(point.x, GLINT, point.z)
	var room: int = room_at(point)
	var furthest: float = 0.0
	var seen: int = 0
	for i: int in _eyes.size():
		if room >= 0 and _inside[i] == room:
			continue
		var eye: Vector3 = _eyes[i]
		var flat := Vector3(glint.x - eye.x, 0.0, glint.z - eye.z)
		var length: float = flat.length()
		if length < NEAR:
			continue
		if flat.dot(_facing[i]) <= 0.0:
			continue
		if not clear(eye, glint):
			continue
		seen += 1
		furthest = maxf(furthest, minf(length, FAR))
	return Vector2(furthest, seen)


## Is `point` a vista — far enough, and held for long enough?
func offers(point: Vector3) -> bool:
	var score: Vector2 = view(point)
	return score.x >= NEAR and int(score.y) >= SEEN_LEAST


## The spot on this floor the walk sees best, never within `keep` of anything in
## `avoid` — or an empty dictionary when no spot is a vista at all.
##
## Rooms in node order and points in a fixed grid, with ties kept by whichever
## came first, so the answer is a function of the plan and nothing else
## (`TEC-007` §1). Never the entrance, which the walk starts inside, and never
## a crawl, which `FloorAnchors.loot` refuses for the reason it gives.
func best(avoid: Array[Vector3], keep: float) -> Dictionary:
	var entrance: int = _graph.node_with(MissionGraph.Role.ENTRANCE)
	var found: Dictionary = {}
	var top := Vector2.ZERO
	for node: int in _graph.size():
		if node == entrance:
			continue
		var module: RoomModule = RoomCatalogue.by_id(_plan.module_of(node))
		if module != null and module.volume == RoomModule.Volume.CRAWL:
			continue
		var room: AABB = _anchors.inside_of(node)
		var x: float = room.position.x
		while x <= room.end.x + 0.001:
			var z: float = room.position.z
			while z <= room.end.z + 0.001:
				var at := Vector3(x, room.position.y, z)
				z += STEP
				if _crowded(at, avoid, keep):
					continue
				var floor_glint := Vector3(at.x, GLINT, at.z)
				if not clear(floor_glint, floor_glint + Vector3.UP * HEADROOM):
					continue
				var score: Vector2 = view(at)
				if score.x < NEAR or int(score.y) < SEEN_LEAST:
					continue
				if score.x > top.x or (is_equal_approx(score.x, top.x)
						and score.y > top.y):
					top = score
					found = {"at": at, "room": node,
						"far": score.x, "seen": int(score.y)}
			x += STEP
	return found


## Is the segment free of every occluder?
##
## Walks the plan cells the segment crosses (Amanatides & Woo, 1987) and tests
## each box that reaches into them once, rejecting on height first: most slabs
## on a floor are floors and ceilings, and a sight between eye and glint height
## never meets either.
func clear(from: Vector3, to: Vector3) -> bool:
	var low: float = minf(from.y, to.y)
	var high: float = maxf(from.y, to.y)
	_pass += 1
	for cell: Vector2i in _cells_along(from, to):
		var here: PackedInt32Array = _grid.get(cell, PackedInt32Array())
		for index: int in here:
			if _stamp[index] == _pass:
				continue
			_stamp[index] = _pass
			var bounds: AABB = _bounds[index]
			if bounds.position.y >= high or bounds.end.y <= low:
				continue
			if _crosses(index, from, to):
				return false
	return true


func _crowded(at: Vector3, avoid: Array[Vector3], keep: float) -> bool:
	for other: Vector3 in avoid:
		if Vector2(other.x - at.x, other.z - at.z).length() < keep:
			return true
	return false


## Does the segment pass through box `index`? A slab test in the box's own frame.
func _crosses(index: int, from: Vector3, to: Vector3) -> bool:
	var local: Transform3D = _inverse[index]
	var start: Vector3 = local * from
	var run: Vector3 = local.basis * (to - from)
	var half: Vector3 = _half[index]
	var enter: float = 0.0
	var leave: float = 1.0
	for axis: int in 3:
		var p: float = start[axis]
		var d: float = run[axis]
		var h: float = half[axis]
		if absf(d) < 0.000001:
			if absf(p) > h:
				return false
			continue
		var t0: float = (-h - p) / d
		var t1: float = (h - p) / d
		if t0 > t1:
			var swap: float = t0
			t0 = t1
			t1 = swap
		enter = maxf(enter, t0)
		leave = minf(leave, t1)
		if enter > leave:
			return false
	return true


## The plan cells a segment's shadow on the floor passes through, in order.
func _cells_along(from: Vector3, to: Vector3) -> Array[Vector2i]:
	var size: float = FloorBuilder.CELL
	var a := Vector2(from.x / size, from.z / size)
	var b := Vector2(to.x / size, to.z / size)
	var cell := Vector2i(floori(a.x), floori(a.y))
	var last := Vector2i(floori(b.x), floori(b.y))
	var out: Array[Vector2i] = [cell]
	var run: Vector2 = b - a
	var step := Vector2i(int(signf(run.x)), int(signf(run.y)))
	var t_max := Vector2(INF, INF)
	var t_delta := Vector2(INF, INF)
	if not is_zero_approx(run.x):
		var edge_x: float = float(cell.x + (1 if step.x > 0 else 0))
		t_max.x = (edge_x - a.x) / run.x
		t_delta.x = absf(1.0 / run.x)
	if not is_zero_approx(run.y):
		var edge_y: float = float(cell.y + (1 if step.y > 0 else 0))
		t_max.y = (edge_y - a.y) / run.y
		t_delta.y = absf(1.0 / run.y)
	var guard: int = absi(last.x - cell.x) + absi(last.y - cell.y) + 2
	while cell != last and guard > 0:
		if t_max.x < t_max.y:
			cell.x += step.x
			t_max.x += t_delta.x
		else:
			cell.y += step.y
			t_max.y += t_delta.y
		out.append(cell)
		guard -= 1
	return out


func _index(occluders: Array) -> void:
	var size: float = FloorBuilder.CELL
	for entry: Array in occluders:
		var placed: Transform3D = entry[0]
		var extent: Vector3 = entry[1]
		var index: int = _inverse.size()
		_inverse.append(placed.affine_inverse())
		_half.append(extent * 0.5)
		var bounds: AABB = placed * AABB(-extent * 0.5, extent)
		_bounds.append(bounds)
		for cx: int in range(floori(bounds.position.x / size),
				floori(bounds.end.x / size) + 1):
			for cz: int in range(floori(bounds.position.z / size),
					floori(bounds.end.z / size) + 1):
				var key := Vector2i(cx, cz)
				var bucket: PackedInt32Array = _grid.get(key, PackedInt32Array())
				bucket.append(index)
				_grid[key] = bucket
	_stamp.resize(_inverse.size())
	_stamp.fill(0)


## The shortest door-to-door line from the arrival point to the Shaft.
##
## Points are the arrival point, the Shaft, and every corridor's two doorway
## cells. A room joins every pair of its own doorways in a straight line, which
## is how a body crosses a room; a corridor joins its two ends through its own
## cells, at the heights `FloorPlan.deck_rises` gives them. Dijkstra over that,
## with ties kept by lower index, so equal routes resolve the same way every time.
func _walk(arrival: Vector3) -> Array[Vector3]:
	var entrance: int = _graph.node_with(MissionGraph.Role.ENTRANCE)
	var shaft: int = _graph.node_with(MissionGraph.Role.SHAFT)
	var points: Array[Vector3] = [arrival, _anchors.shaft()]
	var links: Array = [[], []]
	var doorway: Dictionary = {}
	for route: int in _plan.routes():
		var path: Array[Vector2i] = _plan.path_of(route)
		if path.is_empty():
			continue
		var ends: Array[int] = []
		for cell: Vector2i in [path[0], path[path.size() - 1]]:
			if not doorway.has(cell):
				doorway[cell] = points.size()
				points.append(_centre(cell, 0.0))
				links.append([])
			ends.append(int(doorway[cell]))
		var rises: PackedInt32Array = FloorPlan.deck_rises(
			path, _plan.over_of(route))
		var line: Array[Vector3] = []
		for i: int in path.size():
			line.append(_centre(path[i],
				float(rises[i] + rises[i + 1]) * 0.5 * FloorBuilder.HALF_RISER))
		var cost: float = float(path.size() - 1) * FloorBuilder.CELL
		var back: Array[Vector3] = line.duplicate()
		back.reverse()
		(links[ends[0]] as Array).append([ends[1], cost, line])
		(links[ends[1]] as Array).append([ends[0], cost, back])
	for node: int in _graph.size():
		var members: Array[int] = []
		for cell: Vector2i in _plan.doors_of(node):
			if doorway.has(cell):
				members.append(int(doorway[cell]))
		if node == entrance:
			members.append(0)
		if node == shaft:
			members.append(1)
		for a: int in members:
			for b: int in members:
				if a == b:
					continue
				var across: Array[Vector3] = [points[a], points[b]]
				(links[a] as Array).append(
					[b, points[a].distance_to(points[b]), across])

	var cost_to := PackedFloat32Array()
	cost_to.resize(points.size())
	cost_to.fill(INF)
	cost_to[0] = 0.0
	var came: Array = []
	came.resize(points.size())
	var settled := PackedByteArray()
	settled.resize(points.size())
	settled.fill(0)
	while true:
		var next: int = -1
		for i: int in points.size():
			if settled[i] == 0 and cost_to[i] < INF \
					and (next < 0 or cost_to[i] < cost_to[next]):
				next = i
		if next < 0 or next == 1:
			break
		settled[next] = 1
		for link: Array in links[next]:
			var to: int = link[0]
			var through: float = cost_to[next] + float(link[1])
			if through < cost_to[to]:
				cost_to[to] = through
				came[to] = [next, link[2]]
	var pieces: Array = []
	var at: int = 1
	while came[at] != null:
		pieces.push_front(came[at][1])
		at = int(came[at][0])
	var out: Array[Vector3] = []
	for piece: Array[Vector3] in pieces:
		for point: Vector3 in piece:
			if out.is_empty() or out[out.size() - 1].distance_to(point) > 0.01:
				out.append(point)
	return out


func _sample(line: Array[Vector3]) -> void:
	for i: int in range(1, line.size()):
		var a: Vector3 = line[i - 1]
		var b: Vector3 = line[i]
		var facing := Vector3(b.x - a.x, 0.0, b.z - a.z)
		if facing.length_squared() < 0.0001:
			continue
		facing = facing.normalized()
		var strides: int = maxi(1, int(a.distance_to(b) / STRIDE))
		for s: int in strides:
			var foot: Vector3 = a.lerp(b, float(s) / float(strides))
			_eyes.append(foot + Vector3.UP * EYE)
			_facing.append(facing)
			_inside.append(room_at(foot))


func _centre(cell: Vector2i, height: float) -> Vector3:
	return FloorBuilder.at(cell) + Vector3(
		FloorBuilder.CELL * 0.5, height, FloorBuilder.CELL * 0.5)
