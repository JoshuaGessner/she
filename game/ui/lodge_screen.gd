class_name LodgeScreen
extends Control

## **The Lodge's board, and what it owes you** (`M4-T04`, ADR-241, `DES-007`,
## `DES-014`'s *contract board*).
##
## `PactScreen`'s shape, because it is the same kind of screen: a few offers,
## each with what it pays and why it cannot be had, over the room rather than
## instead of it, and gone on escape.
##
## ## The Lodge's voice, and never a scold
##
## `DES-007`: *warm, competent, and quietly sad about you. A good Lodge NPC
## greets you by name, gives you something useful, and doesn't mention the
## dragon at all.* So the screen says what the work is and what it pays, and
## the only line in the Lodge's own voice is about coming back.
##
## ## Two lanes, stated where they are spent
##
## Trust is what opens deeper work and falls when work is failed; favour is
## what the counter below takes. Both are on the first line, because a player
## deciding whether to take a third contract they cannot finish is deciding
## about the first number.

const MARGIN: float = 40.0
const ROW_WIDTH: float = 620.0

var _column: VBoxContainer = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	MenuStyle.focus_first.call_deferred(self)
	var backdrop: Control = MenuStyle.backdrop()
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


## Rebuilt from `GameState` after every choice, on `PactScreen`'s argument: a
## board that edits itself is a second model of what you took.
func _redraw() -> void:
	for child: Node in _column.get_children():
		child.queue_free()
	var lodge: FactionResource = GameState.lodge()
	_column.add_child(MenuStyle.title(
		tr(String(lodge.name_key)).to_upper() if lodge != null else "THE LODGE"))
	_column.add_child(MenuStyle.line("trust %d · favour %d · work taken %d of %d" % [
		GameState.lodge_trust, GameState.lodge_favour, GameState.contracts.size(),
		ContractBoard.TAKEN_MAX], MenuStyle.LARGE_WARM))
	_column.add_child(MenuStyle.line(
		"Take what you can carry back. We'd rather see you again.", MenuStyle.SMALL_DIM))
	if lodge == null:
		return

	_column.add_child(MenuStyle.line("THE BOARD", MenuStyle.SUB_DIM))
	for offer: Contract in GameState.board():
		_column.add_child(_offer_row(offer, lodge))

	_column.add_child(MenuStyle.line("FAVOURS", MenuStyle.SUB_DIM))
	_column.add_child(MenuStyle.line(
		"Given at your next descent, one of each.", MenuStyle.SMALL_DIM))
	for offered: FavourResource in lodge.favours:
		_column.add_child(_favour_row(offered))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("bag"):
		get_viewport().set_input_as_handled()
		queue_free()


func _offer_label(offer: Contract, lodge: FactionResource) -> String:
	return "%s — %s · trust %d, favour %d" % [offer.title(),
		Contract.FLOORS[offer.floor_index], lodge.trust_for(offer.grade),
		lodge.favour_for(offer.grade)]


func _offer_row(offer: Contract, lodge: FactionResource) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.custom_minimum_size = Vector2(ROW_WIDTH, 0.0)
	var held: bool = GameState.has_contract(offer)
	var refused: String = "" if held else GameState.why_not_contract(offer)
	var take: Button = MenuStyle.button(("put it back — " if held else "")
		+ _offer_label(offer, lodge))
	take.custom_minimum_size = Vector2(ROW_WIDTH, 38.0)
	take.disabled = refused != ""
	take.pressed.connect(func() -> void: _toggle(offer))
	row.add_child(take)
	row.add_child(MenuStyle.line(offer.brief(), MenuStyle.SMALL_DIM))
	if held:
		row.add_child(MenuStyle.line("taken — failing it costs %d trust" % lodge.trust_lost,
			MenuStyle.CAPTION_WARM))
	elif refused != "":
		row.add_child(MenuStyle.line(refused, MenuStyle.CAPTION_DIM))
	return row


func _favour_row(offered: FavourResource) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.custom_minimum_size = Vector2(ROW_WIDTH, 0.0)
	var refused: String = GameState.why_not_favour(offered)
	var ask: Button = MenuStyle.button(_favour_label(offered))
	ask.custom_minimum_size = Vector2(ROW_WIDTH, 34.0)
	ask.disabled = refused != ""
	ask.pressed.connect(func() -> void: _ask(offered))
	row.add_child(ask)
	if refused != "":
		row.add_child(MenuStyle.line(refused, MenuStyle.CAPTION_DIM))
	return row


func _favour_label(offered: FavourResource) -> String:
	return "%s — %d favour" % [tr(String(offered.name_key)), offered.cost]


func _toggle(offer: Contract) -> void:
	if GameState.has_contract(offer):
		GameState.drop_contract(offer)
	else:
		GameState.take_contract(offer)
	_redraw()


func _ask(offered: FavourResource) -> void:
	if GameState.buy_favour(offered):
		_redraw()


## Used by `--board-probe`: press an offer's button without a mouse, so the
## check takes the path a click does (`PactScreen.press`'s rule). Returns
## whether an enabled button answered.
func press_offer(offer: Contract) -> bool:
	var lodge: FactionResource = GameState.lodge()
	var label: String = _offer_label(offer, lodge)
	for child: Node in find_children("*", "Button", true, false):
		var take := child as Button
		if take == null or not take.text.ends_with(label) or take.disabled \
				or take.is_queued_for_deletion():
			continue
		take.pressed.emit()
		return true
	return false


func press_favour(offered: FavourResource) -> bool:
	var label: String = _favour_label(offered)
	for child: Node in find_children("*", "Button", true, false):
		var ask := child as Button
		if ask == null or ask.text != label or ask.disabled or ask.is_queued_for_deletion():
			continue
		ask.pressed.emit()
		return true
	return false
