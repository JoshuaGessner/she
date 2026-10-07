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
## The widest a card is drawn, and the gap between the two columns.
const ROW_WIDTH: float = 540.0
const COLUMN_GAP: float = 32.0
## **Fitted to the window it is laid out for** (ADR-359). Two 540 px columns,
## the gap, the margins and the scrollbar came to 1,204 px in a 1,152 px window,
## so the board scrolled sideways and a favour's name ran off its card — worse
## once the forged plates' margins grew (ADR-341). The card is now as wide as
## half the smallest window allows, and what is inside it is measured from the
## plate's own stylebox rather than from a padding remembered here.
const SCREEN_WIDTH: float = 1152.0
const SCROLLBAR: float = 16.0

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
		ContractBoard.TAKEN_MAX], MenuStyle.BODY_WARM))
	_column.add_child(MenuStyle.line(
		"Take what you can carry back. We'd rather see you again.", MenuStyle.CAPTION_DIM))
	if lodge == null:
		return

	# **The board and what the Lodge will give, side by side** (ADR-291): work
	# on the left as notices pinned to it, favours on the right, each a card —
	# Darkest Dungeon's stagecoach and its hamlet buildings read a choice the
	# same way, as things laid out to compare, not a list to scroll.
	var halves := HBoxContainer.new()
	halves.alignment = BoxContainer.ALIGNMENT_CENTER
	halves.add_theme_constant_override("separation", int(COLUMN_GAP))
	_column.add_child(halves)
	var work := VBoxContainer.new()
	work.add_theme_constant_override("separation", 12)
	halves.add_child(work)
	var board_head: Label = MenuStyle.line("The Board", MenuStyle.DISPLAY_WARM)
	board_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	work.add_child(board_head)
	for offer: Contract in GameState.board():
		work.add_child(_offer_row(offer, lodge))
	var gifts := VBoxContainer.new()
	gifts.add_theme_constant_override("separation", 12)
	halves.add_child(gifts)
	var gift_head: Label = MenuStyle.line("Favours", MenuStyle.DISPLAY_WARM)
	gift_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	gifts.add_child(gift_head)
	gifts.add_child(MenuStyle.line(
		"Given at your next descent, one of each.", MenuStyle.CAPTION_DIM))
	for offered: FavourResource in lodge.favours:
		gifts.add_child(_favour_row(offered))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("bag"):
		get_viewport().set_input_as_handled()
		queue_free()


func _offer_label(offer: Contract, lodge: FactionResource) -> String:
	return "%s — %s · trust %d, favour %d" % [offer.title(),
		Contract.FLOORS[offer.floor_index], lodge.trust_for(offer.grade),
		lodge.favour_for(offer.grade)]


## **How wide the board needs to be**, measured from what was built (ADR-359):
## the two columns' combined minimum, the margins and the scrollbar. For
## `--board-probe`, which compares it with the window the board is laid out for.
func width_needed() -> float:
	for child: Node in _column.get_children():
		var halves := child as HBoxContainer
		if halves != null:
			return halves.get_combined_minimum_size().x + MARGIN * 2.0 + SCROLLBAR
	return 0.0


## How wide a card is, and how wide what is inside it may be (ADR-359).
func row_width() -> float:
	return minf(ROW_WIDTH, floorf((SCREEN_WIDTH - MARGIN * 2.0 - COLUMN_GAP - SCROLLBAR) * 0.5))


func inner_width() -> float:
	var plate: StyleBox = get_theme_stylebox(&"panel", MenuStyle.SLATE)
	var pad: float = plate.get_margin(SIDE_LEFT) + plate.get_margin(SIDE_RIGHT) \
		if plate != null else 0.0
	return row_width() - pad


## A notice pinned to the board (ADR-291): its title is the choice, then where
## and what it pays, then what they said, then where you stand with it.
func _card() -> Array:
	var plate := PanelContainer.new()
	plate.theme_type_variation = MenuStyle.SLATE
	plate.custom_minimum_size = Vector2(row_width(), 0.0)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	plate.add_child(row)
	return [plate, row]


func _offer_row(offer: Contract, lodge: FactionResource) -> Control:
	var made: Array = _card()
	var row: VBoxContainer = made[1]
	var held: bool = GameState.has_contract(offer)
	var refused: String = "" if held else GameState.why_not_contract(offer)
	var take: Button = MenuStyle.button(("Put it back — " if held else "") + offer.title())
	take.set_meta(&"lodge_offer", _offer_label(offer, lodge))
	take.alignment = HORIZONTAL_ALIGNMENT_LEFT
	take.custom_minimum_size = Vector2(inner_width(), 38.0)
	# A long title wraps rather than widening the card past its column.
	take.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	take.disabled = refused != ""
	take.pressed.connect(func() -> void: _toggle(offer))
	row.add_child(take)
	var terms: Label = MenuStyle.line("%s · trust %d, favour %d" % [
		Contract.FLOORS[offer.floor_index], lodge.trust_for(offer.grade),
		lodge.favour_for(offer.grade)], MenuStyle.CAPTION_WARM)
	terms.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(terms)
	var said: Label = MenuStyle.line(offer.brief(), MenuStyle.BODY_TEXT)
	said.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	said.custom_minimum_size = Vector2(inner_width(), 0.0)
	row.add_child(said)
	if held:
		var taken: Label = MenuStyle.line("taken — failing it costs %d trust" % lodge.trust_lost,
			MenuStyle.SUB_WARM)
		taken.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(taken)
	elif refused != "":
		var why: Label = MenuStyle.line(refused, MenuStyle.CAPTION_DIM)
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(why)
	return made[0]


func _favour_row(offered: FavourResource) -> Control:
	var made: Array = _card()
	var row: VBoxContainer = made[1]
	var refused: String = GameState.why_not_favour(offered)
	var ask: Button = MenuStyle.button(_favour_label(offered))
	ask.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ask.custom_minimum_size = Vector2(inner_width(), 34.0)
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask.disabled = refused != ""
	ask.pressed.connect(func() -> void: _ask(offered))
	row.add_child(ask)
	if refused != "":
		var why: Label = MenuStyle.line(refused, MenuStyle.CAPTION_DIM)
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(why)
	return made[0]


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
		if take == null or String(take.get_meta(&"lodge_offer", "")) != label or take.disabled \
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
