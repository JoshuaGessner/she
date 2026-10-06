class_name OfferingScreen
extends Control

## **At her pile: what you give, and what it buys** (ADR-337, `DES-003`, `DES-004`).
##
## ## Why there is a screen at the pile now
##
## The coupling `DES-003` is built on — *what you give pays what she is owed,
## and only what is past that becomes boon* — was true in `GameState.tribute`
## and nowhere a player could see it. Giving meant opening the bag and dragging
## an item off its edge while standing within two metres of the pile; what it
## did was one line in a corner readout, *"none yet — 60 more tribute over the
## tithe buys the first"*, which is arithmetic handed to the player. Reported
## from play: *still not apparent how to get boon accrued to buy perks.*
##
## So the pile opens a page, as Darkest Dungeon's hamlet buildings and Dead
## Cells' Collector do: what you carry, laid out with what she would make of
## each; a ledger of what you owe and what you have stored; and — before you
## give anything — **what this gift would do to both**, as pale fill ahead of
## the bars. Giving is then one press, and the bars move.
##
## ## Looking is not giving
##
## As on the Pact (ADR-331): focus selects, hover does not, and the one button
## that gives says what it gives. A gift is never taken back (`DES-014`), so it
## is never one press from a mis-aim.
##
## ## The bag's drag still gives
##
## Dragging an item out at the pile was the gesture and still is — the same
## `Chamber._give` answers both, so there is one rule with two ways to reach
## it, not two rules.

## A card was chosen to be given. The Chamber gives it and calls `refresh`.
signal offered(item: ItemInstance)
## The door to her aspects, from the page that earns what they cost.
signal asked

const MARGIN: float = 18.0
const LEDGER_WIDTH: float = 400.0
const CARD_WIDTH: float = 300.0

## The bag being offered from. Set before the screen enters the tree.
var inventory: Inventory = null

var _cards: GridContainer = null
var _selected: ItemInstance = null
var _tithe_bar: LedgerBar = null
var _tithe_line: Label = null
var _boon_bar: LedgerBar = null
var _boon_line: Label = null
var _detail: VBoxContainer = null
var _give: Button = null
var _ask: Button = null
## Set by a gift, so the next drawing runs the bars rather than jumping them.
var _eased: bool = false
var _boon_seen: int = -1


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
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	margin.add_child(page)
	page.add_child(MenuStyle.title("HER PILE", MenuStyle.SCREEN_TITLE))
	page.add_child(MenuStyle.line(
		"What you give pays what she is owed. Whatever is past that becomes boon, and boon buys her aspects.",
		MenuStyle.BODY_WARM))

	var halves := HBoxContainer.new()
	halves.add_theme_constant_override("separation", 16)
	halves.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(halves)

	var carried := PanelContainer.new()
	carried.theme_type_variation = MenuStyle.SLATE
	carried.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	halves.add_child(carried)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	carried.add_child(scroll)
	_cards = GridContainer.new()
	_cards.columns = 2
	_cards.add_theme_constant_override("h_separation", 10)
	_cards.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_cards)

	var ledger := PanelContainer.new()
	ledger.theme_type_variation = MenuStyle.SLATE
	ledger.custom_minimum_size = Vector2(LEDGER_WIDTH, 0.0)
	halves.add_child(ledger)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	ledger.add_child(column)
	column.add_child(_left(MenuStyle.heading("The Tithe")))
	_tithe_bar = LedgerBar.new()
	column.add_child(_tithe_bar)
	_tithe_line = _left(MenuStyle.line("", MenuStyle.CAPTION_TEXT))
	column.add_child(_tithe_line)
	column.add_child(_left(MenuStyle.heading("Boon")))
	_boon_bar = LedgerBar.new()
	column.add_child(_boon_bar)
	_boon_line = _left(MenuStyle.line("", MenuStyle.CAPTION_TEXT))
	column.add_child(_boon_line)
	column.add_child(MenuStyle.rule())
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 3)
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_detail)
	_give = MenuStyle.button("")
	_give.theme_type_variation = MenuStyle.PACT_ACT
	_give.custom_minimum_size = Vector2(0.0, 44.0)
	_give.pressed.connect(_commit)
	column.add_child(_give)
	_ask = MenuStyle.button("")
	_ask.custom_minimum_size = Vector2(0.0, 40.0)
	_ask.pressed.connect(func() -> void: asked.emit())
	column.add_child(_ask)

	refresh()
	_focus_selected.call_deferred()


## Rebuilt from the bag and `GameState` — after every gift, and when the
## screen opens. Keeps the selection where it can.
func refresh() -> void:
	for child: Node in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	var items: Array[ItemInstance] = _offerable()
	if _selected == null or not items.has(_selected):
		_selected = _first_she_wants(items)
	for item: ItemInstance in items:
		_cards.add_child(_card(item))
	_ask.text = "Her aspects · %d boon unspent" % GameState.boon
	_describe()


## What the bag holds, richest first: the order a player decides in.
func _offerable() -> Array[ItemInstance]:
	var items: Array[ItemInstance] = []
	if inventory != null:
		items = inventory.items().duplicate()
	items.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool:
		return a.tribute_worth() > b.tribute_worth())
	return items


func _first_she_wants(items: Array[ItemInstance]) -> ItemInstance:
	for item: ItemInstance in items:
		if GameState.why_not_tribute(item) == "":
			return item
	return items[0] if not items.is_empty() else null


func _card(item: ItemInstance) -> Button:
	var refused: String = GameState.why_not_tribute(item)
	var card := Button.new()
	card.theme_type_variation = MenuStyle.OFFER_CARD_REFUSED if refused != "" \
		else MenuStyle.OFFER_CARD
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.custom_minimum_size = Vector2(CARD_WIDTH, 50.0)
	card.text = "%s\n%s" % [item.definition.display(),
		"worth %d to her" % item.tribute_worth() if refused == "" else "she will not take it"]
	card.set_meta(&"offer", item.instance_id)
	card.focus_entered.connect(func() -> void: _look(item))
	card.pressed.connect(func() -> void:
		Foley.flat(card, Foley.Sound.CLICK)
		_look(item)
		if not _give.disabled:
			_give.grab_focus())
	return card


func _look(item: ItemInstance) -> void:
	_selected = item
	_describe()


## The ledger, with the selected gift's effect laid ahead of it, and the
## sentences that say the same thing in words (`DES-018`: never only a length).
func _describe() -> void:
	for child: Node in _detail.get_children():
		_detail.remove_child(child)
		child.queue_free()
	var owed: int = GameState.tithe_due()
	var paid: int = mini(GameState.tithe_paid, owed)
	var per: int = maxi(1, Config.tuning.boon_per_tribute)
	var refused: String = GameState.why_not_tribute(_selected) if _selected != null else ""
	var value: int = _selected.tribute_worth() if _selected != null and refused == "" else 0
	var sum: Dictionary = GameState.reckon(value)

	var eased: bool = _eased
	_eased = false
	var refill: bool = eased and _boon_seen >= 0 and GameState.boon > _boon_seen
	_boon_seen = GameState.boon
	_tithe_bar.show_fill(float(paid) / float(maxi(owed, 1)),
		float(mini(paid + int(sum["to_tithe"]), owed)) / float(maxi(owed, 1)),
		0, paid < owed, eased)
	var short: int = owed - paid
	_tithe_line.text = ("%d of %d paid — settled" % [paid, owed]) if short <= 0 \
		else ("%d of %d paid — %d short, %s" % [paid, owed, short, _when()])
	_boon_bar.show_fill(float(GameState.boon_progress) / float(per),
		float(int(sum["progress"])) / float(per), int(sum["boon"]), false, eased, refill)
	_boon_line.text = "%d of %d toward the next · %d unspent" % [
		GameState.boon_progress, per, GameState.boon]

	if _selected == null:
		_detail.add_child(_left(MenuStyle.line("You carry nothing.", MenuStyle.BODY_DIM)))
		_give.text = "Nothing to give"
		_give.disabled = true
		return
	_detail.add_child(_left(MenuStyle.line(_selected.definition.display(), MenuStyle.DISPLAY_WARM)))
	if refused != "":
		_detail.add_child(_wrapped(refused, MenuStyle.BODY_DIM))
		_give.text = "She will not take it"
		_give.disabled = true
		return
	_detail.add_child(_left(MenuStyle.line("worth %d to her" % value, MenuStyle.CAPTION_WARM)))
	if int(sum["to_tithe"]) > 0:
		_detail.add_child(_wrapped("%d of it pays what you owe her." % int(sum["to_tithe"]),
			MenuStyle.BODY_TEXT))
	if int(sum["surplus"]) > 0:
		var gained: int = int(sum["boon"])
		_detail.add_child(_wrapped("%d is past the Tithe: %d of it goes to boon%s." % [
			int(sum["surplus"]), int(sum["earned"]),
			(" — %d boon" % gained) if gained > 0 else ""], MenuStyle.BODY_TEXT))
	if int(sum["learned"]) > 0:
		# ADR-011's cap said out loud: she will not turn all of a cycle into
		# power, and what she turns away is not lost.
		_detail.add_child(_wrapped(("%d is more than this cycle can turn to boon; "
			+ "your lineage keeps it as a lesson.") % int(sum["learned"]), MenuStyle.CAPTION_DIM))
	_give.text = "Lay it on the pile"
	_give.disabled = false


func _when() -> String:
	var left: int = GameState.runs_left()
	if left <= 0:
		return "due at your next descent"
	return "last run of the cycle" if left == 1 else "%d runs left" % left


func _commit() -> void:
	if _selected == null or _give.disabled:
		return
	var given: ItemInstance = _selected
	_selected = null
	_eased = true
	offered.emit(given)


func _focus_selected() -> void:
	for child: Node in _cards.get_children():
		var card := child as Button
		if card != null and _selected != null \
				and int(card.get_meta(&"offer", -1)) == _selected.instance_id:
			card.grab_focus()
			return
	MenuStyle.focus_first(self)


func _left(label: Label) -> Label:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


func _wrapped(text: String, role: StringName) -> Label:
	var label: Label = _left(MenuStyle.line(text, role))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("bag"):
		get_viewport().set_input_as_handled()
		queue_free()


## For `--offering-probe`: look at one thing in the bag, as a player must.
func select(instance_id: int) -> bool:
	for item: ItemInstance in _offerable():
		if item.instance_id == instance_id:
			_look(item)
			return true
	return false


## For `--offering-probe`: give one thing through the card and the button.
func press_give(instance_id: int) -> bool:
	if not select(instance_id) or _give.disabled:
		return false
	_give.pressed.emit()
	return true


## What the ledger says right now, for the probe.
func ledger_lines() -> PackedStringArray:
	return PackedStringArray([_tithe_line.text, _boon_line.text])
