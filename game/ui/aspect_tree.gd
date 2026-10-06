class_name AspectTree
extends Control

## One path of the Pact, drawn as the tree it is (`M4-T05`, ADR-331).
##
## ## A list could not say "needs"
##
## `PactScreen` drew every node as a row in one scrolling column, Aspect after
## Aspect, with *"needs Sure Grip first"* written under the ones that stood on
## another. Wing is seven deep — Soft Boots to Swift Seal — and the only way to
## see that was to read thirteen captions and assemble the tree in your head.
## The shape of a tree **is** its information: what opens what, how far the
## keystone is, which two branches it joins. A list throws that away and then
## writes it back as prose.
##
## The reference is Darkest Dungeon's hamlet upgrade pages: tiers laid left to
## right, each one joined to the one it needs, the cost on the cell and the
## words in a panel underneath. Hades' Mirror is the same idea with the tree
## folded flat, which works for a mirror of twelve pairs and would not for a
## tree with joins in it.
##
## ## Columns are depth, rows are branches
##
## A node's column is the longest chain of requirements under it, so a keystone
## standing on two branches sits past both. Rows come from walking the tree
## depth-first: a node shares its first child's row and each further branch
## opens a new one, so every row reads left to right as one chain. A node with
## two parents is placed under the first and joined to the second by a line.
##
## ## What a card says without being read
##
## - **Taken**: stamped — an amber ground under pale lettering, and a filled
##   seal on its left edge. Not a warm frame, because a warm frame is what focus
##   draws, and the first photograph could not tell *taken* from *looking at*.
## - **Open to you**: a hollow seal.
## - **Not yet**: no seal and dim lettering. Its reason is in the panel below,
##   because a card cannot hold a sentence and the sentence is the point
##   (`PRO-005` §5).
##
## Seal and ground carry the state as well as colour (`DES-018`). The pips
## hanging under a card are its cost in boon — under it rather than on it,
## because on it they ran into the long names.
##
## Signals up (`TEC-002`): the screen decides what a look or a press means.

signal looked_at(node: AspectNode)
signal chosen(node: AspectNode)

const CHIP = &"AspectChip"
const CHIP_TAKEN = &"AspectChipTaken"
const CHIP_LOCKED = &"AspectChipLocked"

## Horizontal room between two cards, where the joining lines turn.
const COLUMN_GAP: float = 34.0
## Widest a card grows when the path is short. ⟨tune⟩
const CHIP_MAX: float = 200.0
## A card is one or two lines tall when the plate is crowded, and grows to three
## when a short tree leaves the room — Wing's seven columns leave a card about
## 120 px wide, and *Never Where She Struck* needs three lines at that width.
const CHIP_HEIGHT: float = 38.0
const CHIP_TALLEST: float = 66.0
## Space between rows, which the cost pips hang in.
const ROW_GAP: float = 11.0
const SEAL: float = 6.0
const PIP: float = 4.0

var _nodes: Array[AspectNode] = []
## Node id → (column, row).
var _at: Dictionary = {}
var _chips: Dictionary = {}
var _columns: int = 1
var _rows: int = 1
## Drawn over the cards, which a parent's own `_draw` cannot be.
var _over: Control = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_place)


## Lay out one path. The cards are rebuilt, because ownership is read once
## per draw and a card kept across a purchase would hold a stale frame.
func show_nodes(nodes: Array[AspectNode]) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_nodes = nodes
	_chips.clear()
	_lay_out()
	for node: AspectNode in _nodes:
		var chip := Button.new()
		chip.text = node.display()
		chip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		chip.alignment = HORIZONTAL_ALIGNMENT_LEFT
		chip.clip_text = true
		chip.set_meta(&"aspect_node", node.id)
		var taken: bool = GameState.has_taken(node.id)
		if taken:
			chip.theme_type_variation = CHIP_TAKEN
		elif GameState.why_not(node.id) != "":
			chip.theme_type_variation = CHIP_LOCKED
		else:
			chip.theme_type_variation = CHIP
		chip.focus_entered.connect(func() -> void: looked_at.emit(node))
		chip.pressed.connect(func() -> void:
			Foley.flat(chip, Foley.Sound.CLICK)
			chosen.emit(node))
		add_child(chip)
		_chips[node.id] = chip
	_over = Control.new()
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_over.draw.connect(_draw_seals)
	add_child(_over)
	custom_minimum_size = Vector2(0.0, _rows * (CHIP_HEIGHT + ROW_GAP))
	_place()


func chip_of(id: StringName) -> Button:
	return _chips.get(id, null) as Button


func _requires_here(node: AspectNode) -> Array[StringName]:
	var here: Array[StringName] = []
	for other: StringName in node.requires:
		for candidate: AspectNode in _nodes:
			if candidate.id == other:
				here.append(other)
	return here


func _lay_out() -> void:
	_at.clear()
	var depth: Dictionary = {}
	var children: Dictionary = {}
	for node: AspectNode in _nodes:
		children[node.id] = []
	for node: AspectNode in _nodes:
		for other: StringName in _requires_here(node):
			(children[other] as Array).append(node.id)
	# Longest chain beneath each node. The catalogue rejects cycles
	# (`data_probe`), so this settles in at most one pass per node.
	for _pass: int in _nodes.size():
		for node: AspectNode in _nodes:
			var deepest: int = 0
			for other: StringName in _requires_here(node):
				deepest = maxi(deepest, int(depth.get(other, 0)) + 1)
			depth[node.id] = deepest
	var row: Array[int] = [0]
	var place: Callable = func(id: StringName, recurse: Callable) -> void:
		_at[id] = Vector2i(int(depth[id]), row[0])
		var first: bool = true
		for kid: StringName in children[id]:
			if _at.has(kid):
				continue
			if not first:
				row[0] += 1
			recurse.call(kid, recurse)
			first = false
	for node: AspectNode in _nodes:
		if _requires_here(node).is_empty() and not _at.has(node.id):
			if not _at.is_empty():
				row[0] += 1
			place.call(node.id, place)
	_columns = 1
	_rows = 1
	for at: Vector2i in _at.values():
		_columns = maxi(_columns, at.x + 1)
		_rows = maxi(_rows, at.y + 1)


func _column_width() -> float:
	return minf(size.x / float(_columns), CHIP_MAX + COLUMN_GAP)


func _chip_height() -> float:
	return clampf(floorf(size.y / float(_rows)) - ROW_GAP, CHIP_HEIGHT, CHIP_TALLEST)


func _chip_rect(id: StringName) -> Rect2:
	var at: Vector2i = _at.get(id, Vector2i.ZERO)
	var column: float = _column_width()
	var tall: float = _chip_height()
	var pitch: float = tall + ROW_GAP
	var left: float = (size.x - column * _columns) * 0.5 + COLUMN_GAP * 0.5
	var top: float = (size.y - pitch * _rows) * 0.5 + ROW_GAP * 0.5
	return Rect2(Vector2(left + at.x * column, top + at.y * pitch),
		Vector2(column - COLUMN_GAP, tall))


func _place() -> void:
	for id: StringName in _chips:
		var chip: Button = _chips[id]
		var rect: Rect2 = _chip_rect(id)
		chip.position = rect.position
		chip.size = rect.size
	queue_redraw()
	if _over != null:
		_over.queue_redraw()


## The joins, under the cards: out of a card's right edge, down the gap, and
## into the next card's left edge. A join from something taken is warm and
## heavier — the path you have walked reads as one line.
func _draw() -> void:
	var dim: Color = MenuStyle.tone(self, MenuStyle.DIM)
	var warm: Color = MenuStyle.tone(self, MenuStyle.WARM)
	for node: AspectNode in _nodes:
		var to: Rect2 = _chip_rect(node.id)
		var end := Vector2(to.position.x, to.get_center().y)
		for other: StringName in _requires_here(node):
			var from: Rect2 = _chip_rect(other)
			var start := Vector2(from.end.x, from.get_center().y)
			var turn: float = end.x - COLUMN_GAP * 0.5
			var walked: bool = GameState.has_taken(other)
			var tint: Color = warm if walked else dim
			var width: float = 2.0 if walked else 1.0
			draw_polyline(PackedVector2Array([start, Vector2(turn, start.y),
				Vector2(turn, end.y), end]), tint, width)


func _draw_seals() -> void:
	var text: Color = MenuStyle.tone(self, MenuStyle.TEXT)
	var dim: Color = MenuStyle.tone(self, MenuStyle.DIM)
	var warm: Color = MenuStyle.tone(self, MenuStyle.WARM)
	var ground: Color = Color(0.065, 0.06, 0.055, 1.0)
	for node: AspectNode in _nodes:
		var rect: Rect2 = _chip_rect(node.id)
		var taken: bool = GameState.has_taken(node.id)
		var open: bool = not taken and GameState.why_not(node.id) == ""
		var centre := Vector2(rect.position.x, rect.get_center().y)
		var diamond := PackedVector2Array([centre + Vector2(0.0, -SEAL),
			centre + Vector2(SEAL, 0.0), centre + Vector2(0.0, SEAL),
			centre + Vector2(-SEAL, 0.0)])
		if taken:
			_over.draw_colored_polygon(diamond, warm)
		elif open:
			_over.draw_colored_polygon(diamond, ground)
			diamond.append(diamond[0])
			_over.draw_polyline(diamond, text, 1.5)
		var cost: int = Config.tuning.node_cost(node.tier)
		var pip_tint: Color = warm if taken else (text if open else dim)
		for i: int in cost:
			var corner := Vector2(rect.end.x - 4.0 - (i + 1) * PIP - i * 3.0,
				rect.end.y + 3.0)
			_over.draw_rect(Rect2(corner, Vector2(PIP, PIP)), pip_tint)
