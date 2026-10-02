class_name LairPassage
extends RefCounted

## **A way out is a door you walk through, not a pad you stand on** (ADR-282).
##
## The Lair's three ways between places — the camp's Descent, the camp's door to
## your Chamber, and the Chamber's door back — were each a coloured slab on the
## floor, which read as a debug marker rather than a place. Each is now an
## opening cut in a wall, framed by the same doorway the Delvings use, with a
## short passage behind it that you walk into. The trigger stands **inside** the
## passage, so leaving is something you do with your feet rather than a square
## you happen to step on.
##
## The passage is closed at its far end: the camp's edge check casts eighty
## bearings and every one must still meet a wall (ADR-255), and a door into
## the dark is not an edge into nothing.

## Half the opening — the Delvings doorway's own gap — its height, and how far
## the passage runs behind the wall ⟨tune⟩.
const HALF: float = 1.2
const HIGH: float = 3.4
const DEEP: float = 4.2


## Cut an opening in the wall that runs along x at `wall_z`, `thick` deep and
## `high` tall across `span` metres, and build the passage behind it, running
## away from the room in `outward` (+1 or -1 along z). `slab` is the room's own
## box builder — `(size, centre, colour, clad)` — so the wall it replaces and
## the wall it builds are made the same way.
##
## Returns the point inside the passage where the way through is taken.
static func cut(into: Node3D, slab: Callable, wall_z: float, outward: float,
		span: float, high: float, thick: float, stone: Color, dark: Color,
		glow: Color, glow_energy: float) -> Vector3:
	var side: float = span * 0.5 - HALF
	for flank: float in [-1.0, 1.0]:
		slab.call(Vector3(side, high, thick),
			Vector3(flank * (HALF + side * 0.5), high * 0.5, wall_z), stone,
			DelvingsKit.WALL)
	var over: float = high - HIGH
	slab.call(Vector3(HALF * 2.0, over, thick),
		Vector3(0.0, HIGH + over * 0.5, wall_z), stone, DelvingsKit.WALL)
	DelvingsKit.doorway(into, Vector3(0.0, 0.0, wall_z - outward * thick * 0.5),
		0.0 if outward < 0.0 else PI)

	var start: float = wall_z + outward * thick * 0.5
	var middle: float = start + outward * DEEP * 0.5
	var wall: float = 0.4
	# **The floor runs back through the wall** (ADR-293). It began at the
	# wall's outer face while the room's floor ends at its inner one, so the
	# opening stood over a strip the wall's own thickness wide with nothing
	# under it — and a player walking through it fell out of the world. It now
	# starts a hand's breadth inside the room, under the threshold itself.
	var sill: float = thick + 0.2
	slab.call(Vector3(HALF * 2.0 + wall * 2.0, 0.4, DEEP + sill),
		Vector3(0.0, -0.2, middle - outward * sill * 0.5), dark, DelvingsKit.FLOOR)
	for flank: float in [-1.0, 1.0]:
		slab.call(Vector3(wall, HIGH, DEEP),
			Vector3(flank * (HALF + wall * 0.5), HIGH * 0.5, middle), dark,
			DelvingsKit.WALL)
	slab.call(Vector3(HALF * 2.0 + wall * 2.0, wall, DEEP),
		Vector3(0.0, HIGH + wall * 0.5, middle), dark, DelvingsKit.CEILING)
	slab.call(Vector3(HALF * 2.0, HIGH, wall),
		Vector3(0.0, HIGH * 0.5, start + outward * (DEEP + wall * 0.5)), dark)

	# What is through there, said with light: a warm glow from her hall, or a
	# cold one from the way down. Low and deep in the passage, so the door reads
	# as leading somewhere rather than as a lit cupboard.
	if glow_energy > 0.0:
		var light := FlickerLight.new()
		light.light_color = glow
		light.light_energy = glow_energy
		light.omni_range = DEEP + 2.5
		light.swing = 0.08
		light.rate = 0.6
		light.position = Vector3(0.0, 1.2, start + outward * (DEEP - 0.6))
		into.add_child(light)
	return Vector3(0.0, 0.0, start + outward * DEEP * 0.55)


## **How many places across a passage's threshold have no floor under them**
## (ADR-293), from a hand's breadth inside the room to the passage's far end,
## at its middle and both sides. A player who falls through a door cannot say
## why, so the probes ask rather than the playtest.
static func floor_gaps(into: Node3D, wall_z: float, outward: float, thick: float) -> int:
	var space: PhysicsDirectSpaceState3D = into.get_world_3d().direct_space_state
	var inner: float = wall_z - outward * thick * 0.5
	var gaps: int = 0
	for step: int in range(-5, int((thick + DEEP) / 0.1)):
		var z: float = inner + outward * float(step) * 0.1
		for x: float in [-HALF + 0.3, 0.0, HALF - 0.3]:
			var ray := PhysicsRayQueryParameters3D.create(
				into.to_global(Vector3(x, 0.5, z)), into.to_global(Vector3(x, -0.5, z)),
				CollisionLayers.WORLD)
			if space.intersect_ray(ray).is_empty():
				gaps += 1
	return gaps


## Whether `at` stands inside a passage cut by `cut` in the wall at `wall_z`.
static func holds(at: Vector3, wall_z: float, outward: float, thick: float) -> bool:
	var start: float = wall_z - outward * thick * 0.5
	var into: float = (at.z - start) * outward
	return absf(at.x) <= HALF and into >= 0.0 and into <= DEEP + thick
