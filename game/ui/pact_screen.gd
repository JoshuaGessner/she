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

const MARGIN: float = 40.0
const ROW_WIDTH: float = 620.0

var _column: VBoxContainer = null

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


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# The tree is bought with a pad as well as a mouse (ADR-141, ADR-075).
	MenuStyle.focus_first.call_deferred(self)

	var backdrop := ColorRect.new()
	backdrop.color = MenuStyle.INK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = MARGIN
	scroll.offset_right = -MARGIN
	scroll.offset_top = MARGIN
	scroll.offset_bottom = -MARGIN
	add_child(scroll)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 10)
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_column)

	_redraw()


## Rebuilt rather than patched after every purchase. The whole screen is a
## function of `GameState`, and a tree that edits itself in place is a second
## model of what you own that can disagree with the first — which is the
## argument that made rank derived (ADR-125), applied to a menu.
func _redraw() -> void:
	for child: Node in _column.get_children():
		child.queue_free()

	_column.add_child(MenuStyle.title("WHAT SHE OFFERS"))
	_column.add_child(MenuStyle.line(
		"%d boon unspent · rank %d · she expects %d a cycle" % [
			GameState.boon, GameState.pact_rank, GameState.tithe_due()],
		16, MenuStyle.WARM))
	# The coupling said out loud, on the screen where it is chosen. `DES-003`'s
	# whole argument is that power costs obligation, and a tree that showed only
	# the power would be teaching the opposite of the game.
	_column.add_child(MenuStyle.line(
		"Everything you take raises what she expects of you.", 14, MenuStyle.DIM))
	if viewing:
		# Said once, at the top, rather than repeated under every disabled row.
		# `DES-003`'s coupling is the reason and it is worth stating as one.
		_column.add_child(MenuStyle.line(
			"You are reading this in the Deep. The Aspects are bought at the "
			+ "pile, where you give — come back to her with tribute.",
			15, MenuStyle.WARM))

	var body: ClassResource = ClassCatalogue.by_id(GameState.class_id)
	if body == null:
		_column.add_child(MenuStyle.line("No life has been sworn yet.", 15))
		return

	var shown: int = 0
	for aspect: StringName in AspectCatalogue.authored():
		# **Only the three your class may enter** (ADR-009). An Aspect this
		# class is locked out of is not drawn at all, for the same reason the
		# four unwritten ones are not: a path you can see and can never take is
		# a padlock, and `DES-011` makes the lockout an identity rather than a
		# restriction.
		if not body.aspects.has(aspect):
			continue
		shown += 1
		_column.add_child(MenuStyle.line(String(aspect).to_upper(), 18))
		for node: AspectNode in AspectCatalogue.of_aspect(aspect):
			_column.add_child(_row(node))

	if shown == 0:
		_column.add_child(MenuStyle.line(
			"%s may not enter any Aspect this build has written."
			% body.display(), 15, MenuStyle.WARM))


## Escape, or the bag key that opened nothing. No close button: `DES-019` is
## hostile to persistent UI and every other full-screen surface in this game
## leaves the same way.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("bag"):
		get_viewport().set_input_as_handled()
		queue_free()


func _row(node: AspectNode) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.custom_minimum_size = Vector2(ROW_WIDTH, 0.0)

	var owned: bool = GameState.has_taken(node.id)
	var refused: String = GameState.why_not(node.id)
	var price: int = Config.tuning.node_cost(node.tier)
	var label: String = "%s — %d boon" % [node.display(), price]

	var take: Button = MenuStyle.button(label)
	take.custom_minimum_size = Vector2(ROW_WIDTH, 38.0)
	# Read-only in the Deep: the row still says what the node is and what it
	# costs — that is the information the door was opened for — and refuses the
	# purchase, because `DES-003` buys these where you give.
	take.disabled = owned or refused != "" or viewing
	take.pressed.connect(func() -> void: _take(node))
	row.add_child(take)

	if node.description_key != &"":
		row.add_child(MenuStyle.line(tr(String(node.description_key)), 14))
	if owned:
		row.add_child(MenuStyle.line("taken", 13, MenuStyle.WARM))
		# **Respec** (`M3-T13`, `DES-004`). On the node itself rather than
		# behind a mode: giving one back is the same kind of act as taking it,
		# and a screen with a "respec mode" would make unmaking a build feel
		# like a different system from making one.
		var back: String = GameState.why_not_reclaim(node.id)
		var refund: int = int(floor(price * Config.tuning.respec_refund))
		var give: Button = MenuStyle.button("give it back — %d boon" % refund)
		give.custom_minimum_size = Vector2(ROW_WIDTH, 30.0)
		give.disabled = back != "" or viewing
		give.pressed.connect(func() -> void: _give_back(node))
		row.add_child(give)
		if back != "":
			row.add_child(MenuStyle.line(back, 13, MenuStyle.DIM))
	elif refused != "":
		row.add_child(MenuStyle.line(refused, 13, MenuStyle.DIM))
	return row


func _take(node: AspectNode) -> void:
	if GameState.take_node(node.id):
		_redraw()


func _give_back(node: AspectNode) -> void:
	if GameState.reclaim(node.id):
		_redraw()


## Used by `--respec-probe`: press a *give it back* without a mouse, on the same
## rule `press` states — the check has to exercise the path a click takes.
func press_give_back(id: StringName) -> bool:
	var node: AspectNode = AspectCatalogue.by_id(id)
	if node == null:
		return false
	var refund: int = int(floor(
		Config.tuning.node_cost(node.tier) * Config.tuning.respec_refund))
	var label: String = "give it back — %d boon" % refund
	for child: Node in find_children("*", "Button", true, false):
		var give := child as Button
		if give == null or give.text != label or give.disabled:
			continue
		give.pressed.emit()
		return true
	return false


## Used by `--pact-probe`: press a row without a mouse, so the check exercises
## the same path a click does rather than calling `take_node` past the button.
## `M2-T18` is why that distinction is not pedantic — every rule in the bag was
## correct and no click had ever reached one.
func press(id: StringName) -> bool:
	var node: AspectNode = AspectCatalogue.by_id(id)
	if node == null:
		return false
	var price: int = Config.tuning.node_cost(node.tier)
	var label: String = "%s — %d boon" % [node.display(), price]
	for child: Node in find_children("*", "Button", true, false):
		var take := child as Button
		if take == null or take.text != label or take.disabled:
			continue
		take.pressed.emit()
		return true
	return false
