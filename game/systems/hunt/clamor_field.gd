class_name ClamorField
extends Node

## Where noise was, recently (`M2-T02`, `TEC-001`).
##
## A **decaying scalar field on a coarse grid over the floor.** Actions deposit
## clamor; it diffuses outward and decays away. `TEC-001` specifies exactly
## this, and the reason is one sentence:
##
## > **The Hunter navigates the clamor gradient, not the player's transform. It
## > genuinely does not know where you are — it knows where noise was.**
##
## That is what makes `DES-005`'s counter-play real rather than performative.
## An enemy that pathed to `player.global_position` and merely *pretended* to
## lose you would behave almost identically most of the time and would be a lie
## the first time a player tested it — and players test exactly this.
##
## ## Not `ClamorSource`, and both exist in the finished game (ADR-073)
##
## | | Answers |
## |---|---|
## | `ClamorSource.audible_at()` | *"can that enemy hear me **right now**"* |
## | this | *"where in the level was noise, and how long ago"* |
##
## `M1-T04` built the first and deliberately left this absent rather than
## approximating it. The radius cannot answer the Hunter's question: it has no
## memory, and it is keyed to a source that may have gone quiet and walked away.
## A field remembers, which is the whole point of a pursuer you can shake.
##
## ## Host-only, and never replicated
##
## `TEC-001`: *"The Clamor field is host-only and never replicated; clients
## receive only its effects."* A client's copy would be a second simulation of
## a diffusing grid to feed a brain that does not run there — and the effects
## that matter (the Hunter's position, its state) already replicate as part of
## the Hunter.
##
## The debug overlay is the exception and is drawn from the host's own copy, so
## what it shows is the field the Hunter is actually reading.

## Metres per cell ⟨tune⟩. Two metres matches ADR-054's modular kit grid, so a
## cell is one architectural module and the field lines up with the walls that
## shape it rather than cutting across them at an angle.
const CELL_METRES: float = 2.0

## Diffusion and decay run on their own clock, not per frame. `TEC-001` budgets
## ≤2 ms/frame for propagation; a blur over the whole grid every frame spends
## that on a field nobody can react to faster than it changes. At 10 Hz a
## footstep still spreads across a room in well under a second.
const TICK_HZ: float = 10.0

var _cells: PackedFloat32Array = PackedFloat32Array()
var _scratch: PackedFloat32Array = PackedFloat32Array()
var _width: int = 0
var _height: int = 0
var _origin: Vector3 = Vector3.ZERO
var _accumulated: float = 0.0
var _connected: Array[ClamorSource] = []
## **Which neighbours each cell hears, learned once** (B155): eight entries a
## cell, in `_propagate`'s order, each the neighbour's index or -1 where the
## grid's edge or a wall stands between. A pass used to cast all eight rays
## for every cell, ten times a second — about 20,000 rays and 22 ms on a
## Delvings floor, a dropped frame ten times a second against a 2 ms budget.
## The walls are what a floor was built with and never move (doors stand on
## `GATE`, which noise passes), so the answer is the same every pass.
var _reach: PackedInt32Array = PackedInt32Array()
## **The cells that can hold noise** (B155), corner to corner, inclusive. A
## cell farther than one step outside is silent with silent neighbours, so a
## pass leaves it silent and need not visit it; empty when `_hi.x < _lo.x`.
var _lo: Vector2i = Vector2i.ZERO
var _hi: Vector2i = Vector2i(-1, -1)


## Lay the grid over a level's footprint. Levels call this; nothing discovers
## its own bounds, because a field sized from whatever happens to be in the
## tree would change size as actors move.
func configure(from: Vector3, to: Vector3) -> void:
	_origin = Vector3(minf(from.x, to.x), 0.0, minf(from.z, to.z))
	var span: Vector3 = (to - from).abs()
	_width = maxi(1, ceili(span.x / CELL_METRES))
	_height = maxi(1, ceili(span.z / CELL_METRES))
	_cells = PackedFloat32Array()
	_cells.resize(_width * _height)
	_scratch = PackedFloat32Array()
	_scratch.resize(_width * _height)
	_reach = PackedInt32Array()
	_lo = Vector2i.ZERO
	_hi = Vector2i(-1, -1)


func width() -> int:
	return _width


func height() -> int:
	return _height


func origin() -> Vector3:
	return _origin


## Centre of a cell, in world space. The Hunter steers at these, so they have
## to be somewhere it can stand rather than on a cell corner inside a wall.
func cell_centre(x: int, y: int) -> Vector3:
	return _origin + Vector3((x + 0.5) * CELL_METRES, 0.0, (y + 0.5) * CELL_METRES)


func cell_at(point: Vector3) -> Vector2i:
	return Vector2i(
		floori((point.x - _origin.x) / CELL_METRES),
		floori((point.z - _origin.z) / CELL_METRES))


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _width and cell.y < _height


func level_in(cell: Vector2i) -> float:
	if not in_bounds(cell):
		return 0.0
	return _cells[cell.y * _width + cell.x]


func level_at(point: Vector3) -> float:
	return level_in(cell_at(point))


## Add noise at a world position. Host-only, like everything that writes here.
func deposit(at: Vector3, amount: float) -> void:
	if amount <= 0.0 or _width == 0:
		return
	# An arrow or a snare lands its noise here without a source (`Arrow._land`),
	# so a hush rune's circle is asked here too (ADR-221). Sources were already
	# refused in `ClamorSource.add`; this is the other door.
	if Hush.silences(at):
		return
	var cell: Vector2i = cell_at(at)
	if not in_bounds(cell):
		return
	var index: int = cell.y * _width + cell.x
	_cells[index] = minf(Config.tuning.clamor_field_maximum, _cells[index] + amount)
	if _hi.x < _lo.x:
		_lo = cell
		_hi = cell
	else:
		_lo = _lo.min(cell)
		_hi = _hi.max(cell)


## Whether noise passes from `from` into its neighbour `to` (B155), as the
## field has learned it — false off the grid or for cells that do not touch.
func hears_across(from: Vector2i, to: Vector2i) -> bool:
	var step: Vector2i = to - from
	if not in_bounds(from) or step == Vector2i.ZERO or absi(step.x) > 1 or absi(step.y) > 1:
		return false
	if _reach.size() != _cells.size() * 8:
		_learn_walls()
	var slot: int = (step.y + 1) * 3 + (step.x + 1)
	if slot > 4:
		slot -= 1
	return _reach[(from.y * _width + from.x) * 8 + slot] >= 0


## The loudest neighbouring cell, or `(-1, -1)` when everything nearby is
## silent. **This is the Hunter's entire idea of where to go.**
##
## Deliberately a hill-climb on the immediate neighbourhood rather than a search
## for the global maximum: the Hunter should walk *up the noise*, arriving at
## where the sound was loudest by following it, and be fooled by a louder thing
## in the wrong direction. A global argmax would be a wallhack with extra steps.
func uphill_from(point: Vector3, minimum: float) -> Vector2i:
	var here: Vector2i = cell_at(point)
	var best: Vector2i = Vector2i(-1, -1)
	var best_level: float = maxf(minimum, level_in(here))
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var neighbour := Vector2i(here.x + dx, here.y + dy)
			var level: float = level_in(neighbour)
			if level > best_level:
				best_level = level
				best = neighbour
	return best


## The loudest cell anywhere, for a Hunter that has lost the scent entirely and
## needs somewhere to start. Not used for pursuit — `uphill_from` is — because
## this one does know where the noise is, which is precisely what pursuit must
## not have.
func loudest() -> Vector2i:
	var best: Vector2i = Vector2i(-1, -1)
	var best_level: float = 0.0
	for y: int in range(_height):
		for x: int in range(_width):
			var level: float = _cells[y * _width + x]
			if level > best_level:
				best_level = level
				best = Vector2i(x, y)
	return best


func total() -> float:
	var sum: float = 0.0
	for value: float in _cells:
		sum += value
	return sum


func _ready() -> void:
	# Every deposit comes from a `ClamorSource` announcing itself. Subscribing
	# to the existing signal rather than having sources push into a global keeps
	# the dependency pointing one way: a source still knows nothing about the
	# field, and `M1-T04`'s component is untouched by this file existing.
	if multiplayer.is_server():
		set_physics_process(true)
	else:
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	_absorb_new_sources()
	_accumulated += delta
	var step: float = 1.0 / TICK_HZ
	while _accumulated >= step:
		_accumulated -= step
		_propagate(step)


## Sources arrive and leave as players and actors spawn, so the subscription
## list is rebuilt from the group rather than wired once. Cheap: the group is
## a handful of nodes and this runs on the host only.
func _absorb_new_sources() -> void:
	for node: Node in get_tree().get_nodes_in_group("clamor_sources"):
		var source := node as ClamorSource
		if source == null or _connected.has(source):
			continue
		source.made_noise.connect(_on_noise.bind(source))
		_connected.append(source)
	# Drop the departed, or the array grows for the whole session and every
	# entry is a freed instance the next `has()` walks over.
	var live: Array[ClamorSource] = []
	for source: ClamorSource in _connected:
		if is_instance_valid(source):
			live.append(source)
	_connected = live


func _on_noise(amount: float, _level: float, from: ClamorSource) -> void:
	deposit(from.global_position, amount)


## One blur-and-fade pass.
##
## Diffusion is a plain box blur weighted toward the centre, and it is
## **blocked by walls**: a neighbouring cell only donates if noise could
## actually travel between the two. Without that the field seeps through solid
## rock and the Hunter walks confidently at a wall, which is both wrong and the
## kind of wrong a player reads as the game cheating.
func _propagate(step: float) -> void:
	if _hi.x < _lo.x:
		return
	if _reach.size() != _cells.size() * 8:
		_learn_walls()
	var spread: float = Config.tuning.clamor_field_spread
	var keep: float = 1.0 - spread
	# Noise reaches one cell farther each pass, so the box grows by one first.
	var first: Vector2i = (_lo - Vector2i.ONE).max(Vector2i.ZERO)
	var last: Vector2i = (_hi + Vector2i.ONE).min(Vector2i(_width - 1, _height - 1))
	for y: int in range(first.y, last.y + 1):
		for x: int in range(first.x, last.x + 1):
			var index: int = y * _width + x
			var here: float = _cells[index]
			var gathered: float = 0.0
			var neighbours: int = 0
			var base: int = index * 8
			for slot: int in 8:
				var neighbour: int = _reach[base + slot]
				if neighbour >= 0:
					gathered += _cells[neighbour]
					neighbours += 1
			var averaged: float = gathered / float(neighbours) if neighbours > 0 else here
			_scratch[index] = here * keep + averaged * spread

	var decay: float = Config.tuning.clamor_field_decay * step
	var lo: Vector2i = Vector2i(_width, _height)
	var hi: Vector2i = Vector2i(-1, -1)
	for y: int in range(first.y, last.y + 1):
		for x: int in range(first.x, last.x + 1):
			var index: int = y * _width + x
			var level: float = maxf(0.0, _scratch[index] - decay)
			_cells[index] = level
			if level > 0.0:
				lo = lo.min(Vector2i(x, y))
				hi = hi.max(Vector2i(x, y))
	_lo = lo
	_hi = hi


## Learn every cell's eight edges (B155), once a floor stands: a ray each, as
## `_open_between` casts it. Ray from the cell to its neighbour, never the
## reverse — a centre inside rock sees out of it, and the pass this replaced
## asked in that direction.
func _learn_walls() -> void:
	_reach = PackedInt32Array()
	_reach.resize(_cells.size() * 8)
	for y: int in range(_height):
		for x: int in range(_width):
			var slot: int = (y * _width + x) * 8
			for step_y: int in range(-1, 2):
				for step_x: int in range(-1, 2):
					if step_x == 0 and step_y == 0:
						continue
					var neighbour := Vector2i(x + step_x, y + step_y)
					var open: bool = in_bounds(neighbour) and _open_between(Vector2i(x, y), neighbour)
					_reach[slot] = neighbour.y * _width + neighbour.x if open else -1
					slot += 1


## Can noise pass between two neighbouring cells? A single ray between their
## centres, at chest height, against the world layer. Asked once per edge per
## floor, by `_learn_walls` (B155).
func _open_between(a: Vector2i, b: Vector2i) -> bool:
	var space: PhysicsDirectSpaceState3D = _space()
	if space == null:
		return true
	var lift := Vector3(0.0, 1.2, 0.0)
	var query := PhysicsRayQueryParameters3D.create(
		cell_centre(a.x, a.y) + lift, cell_centre(b.x, b.y) + lift)
	query.collision_mask = CollisionLayers.WORLD
	return space.intersect_ray(query).is_empty()


func _space() -> PhysicsDirectSpaceState3D:
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.world_3d.direct_space_state
