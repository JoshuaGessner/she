class_name PactScreen
extends Control

## The dragon's Aspects, and what you can afford of them (`M3-T01`, `DES-004`).
##
## `ClassScreen` is the shape this follows, down to the layout preset and the
## `press()` hook, because it is the same kind of screen: a small number of
## irreversible commitments, each stated with its cost before it is taken.
##
## `set_anchors_and_offsets_preset`, not `set_anchors_preset`. A `Control`
## parented to a `CanvasLayer` gets no layout, so the preset that sets anchors
## alone leaves it 0 x 0 and every click misses (ADR-111). That cost the whole
## of `M2-T18` to find once and `M3-T02` nearly repeated it.
##
## ## It draws what exists, and nothing else
##
## `DES-004` names five Aspects and one is authored. The other four are
## **absent, not greyed out** (ADR-064) — a padlock on a path nobody has written
## is a promise the build cannot keep, and a playtester who clicks it learns
## nothing except that the menu lies. `AspectCatalogue.authored()` is the whole
## of what appears here.
##
## ## Refusals say why
##
## Every node that cannot be taken shows the sentence `GameState.why_not`
## returns. A tree that greys something out and will not say why is
## `PRO-005` §5's unexplainable loss moved from the floor into a menu, and the
## reasons here are all things a player can act on: earn more, take the node
## before it, or reach the rank.
##
## ## A tree, a page, and one button (ADR-331)
##
## Each path is its own page — the Aspects your class may enter, then your
## Rite — drawn by `AspectTree` as the tree it is. **Looking is not buying**:
## moving onto a card shows it in the plate underneath, and only the plate's
## one button takes it or gives it back. The old screen put a *take* and a
## *give it back* on every row, so thirty buttons stood a mis-click from a
## purchase; now the commitment is a second, deliberate press on a button that
## names the price.
##
## Hover does not select. A pointer crossing the tree on its way to that button
## would otherwise change what the button buys.

## The page's edge. The default window is 1152 x 648 and Hoard is six rows
## deep, so every pixel of this is spent on purpose.
const MARGIN: float = 18.0
## Room the plate under the tree keeps for four lines and a button.
const DETAIL_HEIGHT: float = 104.0
const ACT_WIDTH: float = 300.0
## The page that is your class's own branch rather than one of her Aspects.
const RITE: StringName = &"rite"

## **Open to be read, not to be spent** (`M4-T05`, TEC-009 §5.3, ADR-198).
##
## The tree had exactly one way in: stand within `PLACE_REACH` of the hoard and
## press `interact`. No panel, no button, no menu — and ADR-164 already recorded
## a playtester's words for it, *"no UI pop up or cue for talking with the
## dragon"*. A prompt was added to the reticle; **the tree still had no door.**
##
## The door is the pause menu, because that is where a player looks for *who am
## I* and it costs nothing on screen during play (`DES-019` rule 1).
##
## But a door into the Deep cannot be a shop. `DES-003` couples the Aspects to
## the Tithe by making you buy them **where you give** — the gesture at the pile
## is what pays for them — so a mid-run purchase would decouple the two and turn
## a pact into a skill menu. Hence read-only: the same screen, the same data,
## every button refusing with the reason.
##
## Not a stub (ADR-064). It shows real state and answers the real question —
## *what have I taken, and what is left* — which is the whole thing a player
## could not find out during a run.
var viewing: bool = false

var _page: VBoxContainer = null
var _path: StringName = &""
var _selected: AspectNode = null
var _tree: AspectTree = null
var _detail: VBoxContainer = null
var _act: Button = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop: Control = MenuStyle.backdrop()
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, int(MARGIN))
	add_child(margin)
	_page = VBoxContainer.new()
	_page.add_theme_constant_override("separation", 8)
	margin.add_child(_page)

	var paths: Array[StringName] = paths_shown()
	if not paths.is_empty():
		_path = paths[0]
		_selected = _first_worth_reading(_nodes_of(_path))
	_redraw()
	# The tree is bought with a pad as well as a mouse (ADR-141, ADR-075), and
	# the first thing focused is the card being described, not the first tab.
	_focus_selected.call_deferred()


## The pages this class has: each Aspect it may enter that has nodes, then its
## Rite. **Only the three your class may enter** (ADR-009) — a path you can see
## and can never take is a padlock, and `DES-011` makes the lockout an identity
## rather than a restriction.
func paths_shown() -> Array[StringName]:
	var shown: Array[StringName] = []
	var body: ClassResource = ClassCatalogue.by_id(GameState.class_id)
	if body == null:
		return shown
	for aspect: StringName in body.aspects:
		if AspectCatalogue.authored().has(aspect):
			shown.append(aspect)
	if not AspectCatalogue.rite_of(body.id).is_empty():
		shown.append(RITE)
	return shown


## Open a page, for `--pact-shot` and for the tabs.
func show_path(path: StringName) -> void:
	if not paths_shown().has(path):
		return
	_path = path
	_selected = _first_worth_reading(_nodes_of(path))
	_redraw()


func _nodes_of(path: StringName) -> Array[AspectNode]:
	if path == RITE:
		return AspectCatalogue.rite_of(GameState.class_id)
	return AspectCatalogue.of_aspect(path)


func _path_name(path: StringName) -> String:
	if path == RITE:
		var body: ClassResource = ClassCatalogue.by_id(GameState.class_id)
		return "The %s's Rite" % body.display()
	return String(path).capitalize()


## Something you could take now, or failing that the first thing in the path —
## the page opens on a decision when there is one.
func _first_worth_reading(nodes: Array[AspectNode]) -> AspectNode:
	for node: AspectNode in nodes:
		if not GameState.has_taken(node.id) and GameState.why_not(node.id) == "":
			return node
	return nodes[0] if not nodes.is_empty() else null


## Rebuilt rather than patched after every purchase. The whole screen is a
## function of `GameState`, and a tree that edits itself in place is a second
## model of what you own that can disagree with the first — which is the
## argument that made rank derived (ADR-125), applied to a menu.
##
## Removed as well as freed, so a probe searching for buttons straight after a
## press never finds the last page's (`MainMenu._clear`'s fault).
func _redraw() -> void:
	for child: Node in _page.get_children():
		_page.remove_child(child)
		child.queue_free()
	_tree = null
	_detail = null
	_act = null

	_page.add_child(MenuStyle.title("WHAT SHE OFFERS", MenuStyle.SCREEN_TITLE))
	# The coupling said out loud, on the screen where it is chosen, and on the
	# same line as the number it moves. `DES-003`'s whole argument is that power
	# costs obligation, and a tree that showed only the power would be teaching
	# the opposite of the game.
	_page.add_child(MenuStyle.line(
		"%d boon unspent · rank %d · she expects %d a cycle, and more for everything you take"
		% [GameState.boon, GameState.pact_rank, GameState.tithe_due()],
		MenuStyle.BODY_WARM))

	var body: ClassResource = ClassCatalogue.by_id(GameState.class_id)
	if body == null:
		_page.add_child(MenuStyle.line("No life has been sworn yet."))
		return
	var paths: Array[StringName] = paths_shown()
	if paths.is_empty():
		_page.add_child(MenuStyle.line(
			"%s may not enter any Aspect this build has written." % body.display(),
			MenuStyle.BODY_WARM))
		return

	_page.add_child(_tabs(paths))

	var plate := PanelContainer.new()
	plate.theme_type_variation = MenuStyle.SLATE
	plate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_child(plate)
	_tree = AspectTree.new()
	_tree.looked_at.connect(_look)
	_tree.chosen.connect(_choose)
	plate.add_child(_tree)
	_tree.show_nodes(_nodes_of(_path))

	var under := PanelContainer.new()
	under.theme_type_variation = MenuStyle.SLATE
	under.custom_minimum_size = Vector2(0.0, DETAIL_HEIGHT)
	_page.add_child(under)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 24)
	under.add_child(split)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 2)
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(_detail)
	_act = MenuStyle.button("")
	_act.custom_minimum_size = Vector2(ACT_WIDTH, 44.0)
	_act.theme_type_variation = MenuStyle.PACT_ACT
	_act.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_act.pressed.connect(_commit)
	split.add_child(_act)
	_describe()


## One button per page, the open one framed as if pressed in. Each says how
## much of it you hold, which is the question a player opens this to answer.
func _tabs(paths: Array[StringName]) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	for path: StringName in paths:
		var nodes: Array[AspectNode] = _nodes_of(path)
		var held: int = 0
		for node: AspectNode in nodes:
			held += 1 if GameState.has_taken(node.id) else 0
		var tab: Button = MenuStyle.button("%s · %d of %d" % [_path_name(path), held, nodes.size()])
		tab.custom_minimum_size = Vector2(0.0, 38.0)
		tab.theme_type_variation = MenuStyle.PACT_TAB_OPEN if path == _path else MenuStyle.PACT_TAB
		tab.set_meta(&"pact_path", path)
		tab.pressed.connect(func() -> void:
			show_path(path)
			_focus_selected.call_deferred())
		row.add_child(tab)
	return row


func _look(node: AspectNode) -> void:
	_selected = node
	_describe()


## A card pressed: show it, and hand the focus to the button that would buy
## it, so a pad's second press is the commitment and nothing else is.
func _choose(node: AspectNode) -> void:
	_look(node)
	if _act != null and not _act.disabled:
		_act.grab_focus()


## The plate under the tree: what it is, what it costs, what it does, and
## where you stand with it — then the one button.
func _describe() -> void:
	if _detail == null:
		return
	for child: Node in _detail.get_children():
		_detail.remove_child(child)
		child.queue_free()
	var node: AspectNode = _selected
	if node == null:
		_act.visible = false
		return
	var owned: bool = GameState.has_taken(node.id)
	var refused: String = GameState.why_not(node.id)
	var price: int = Config.tuning.node_cost(node.tier)

	_detail.add_child(_left(MenuStyle.line(node.display(), MenuStyle.DISPLAY_WARM)))
	_detail.add_child(_left(MenuStyle.line("%s · %d boon" % [
		String(AspectNode.Tier.keys()[node.tier]).to_lower(), price],
		MenuStyle.CAPTION_WARM)))
	if node.description_key != &"":
		var said: Label = _left(MenuStyle.line(tr(String(node.description_key)),
			MenuStyle.BODY_TEXT))
		said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(said)

	var standing: String = ""
	_act.visible = true
	if owned:
		# **Respec** (`M3-T13`, `DES-004`), on the node itself rather than behind
		# a mode: giving one back is the same kind of act as taking it.
		var back: String = GameState.why_not_reclaim(node.id)
		var refund: int = _refund(node)
		_act.text = "Give it back — %s" % (
			"%d boon returned" % refund if refund > 0 else "nothing returned")
		_act.set_meta(&"pact_act", &"give")
		_act.disabled = back != "" or viewing
		standing = "Taken." + ((" " + back) if back != "" else "")
	else:
		_act.text = "Take it — %d boon" % price
		_act.set_meta(&"pact_act", &"take")
		_act.disabled = refused != "" or viewing
		standing = refused
	# Said once, here, rather than on every card: `DES-003` buys these at the
	# pile, where you give, and that is the reason the button will not press.
	if viewing and standing == "":
		standing = "Bought at the pile, where you give — come back to her with tribute."
	elif viewing:
		_detail.add_child(_left(MenuStyle.line(
			"Bought at the pile, where you give.", MenuStyle.CAPTION_DIM)))
	if standing != "":
		var stood: Label = _left(MenuStyle.line(standing,
			MenuStyle.CAPTION_WARM if owned else MenuStyle.CAPTION_DIM))
		stood.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(stood)


func _left(label: Label) -> Label:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


func _refund(node: AspectNode) -> int:
	return int(floor(Config.tuning.node_cost(node.tier) * Config.tuning.respec_refund))


func _commit() -> void:
	if _selected == null or _act == null or _act.disabled:
		return
	var kept: StringName = _selected.id
	var done: bool = false
	if StringName(_act.get_meta(&"pact_act", &"")) == &"give":
		done = GameState.reclaim(kept)
	else:
		done = GameState.take_node(kept)
	if done:
		_redraw()
		_focus_selected.call_deferred()


func _focus_selected() -> void:
	if _tree == null or _selected == null:
		MenuStyle.focus_first(self)
		return
	var chip: Button = _tree.chip_of(_selected.id)
	if chip != null and chip.is_inside_tree():
		chip.grab_focus()


## Escape, or the bag key that opened nothing. No close button: `DES-019` is
## hostile to persistent UI and every other full-screen surface in this game
## leaves the same way.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("bag"):
		get_viewport().set_input_as_handled()
		queue_free()


## Show one node in the plate, opening its page if it is on another — the path
## a player takes by tab and card. False when this class cannot see it.
func select(id: StringName) -> bool:
	for path: StringName in paths_shown():
		for node: AspectNode in _nodes_of(path):
			if node.id != id:
				continue
			if path != _path:
				_path = path
				_selected = node
				_redraw()
			else:
				_look(node)
			return true
	return false


## Used by `--pact-probe`: press a node's *take* without a mouse, so the check
## exercises the same path a click does rather than calling `take_node` past
## the button. `M2-T18` is why that distinction is not pedantic — every rule in
## the bag was correct and no click had ever reached one. It goes through the
## card first, as a player must.
func press(id: StringName) -> bool:
	return _press_act(id, &"take")


## Used by `--respec-probe`: the same, for *give it back*.
func press_give_back(id: StringName) -> bool:
	return _press_act(id, &"give")


func _press_act(id: StringName, act: StringName) -> bool:
	if not select(id) or _tree == null:
		return false
	var chip: Button = _tree.chip_of(id)
	if chip == null:
		return false
	chip.pressed.emit()
	if _act == null or _act.disabled or StringName(_act.get_meta(&"pact_act", &"")) != act:
		return false
	_act.pressed.emit()
	return true
