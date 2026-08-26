class_name LegacyScreen
extends Control

## **She'll only remember three things. Choose.** (`M3-T05`, ADR-003, ADR-006.)
##
## `DES-003` calls this *"the anti-wipe-cliff mechanism, and the piece I feel
## strongest about"* — one screen doing enormous emotional work, and the trick
## every roguelite designer knows: **convert the wipe into a decision.** Players
## remember choices; they resent deletions.
##
## ## Three panels, and the order is the argument
##
## | | |
## |---|---|
## | **What you learned** | ADR-006: *no run can ever return zero*, and the death screen must show what was **gained**, not only what was lost. It is first because it is the answer to the question the player is actually asking. |
## | **What she keeps** | ADR-003: three slots, one item or one node each, **never raw Boon** — a fungible payload is the optimal pick every time and turns this into percentage retention with extra UI. |
## | **Who you are next** | ADR-009: death is the door to a new class. `M3-T02` built this screen; it is reused rather than rebuilt. |
##
## `PRO-001` is explicit that these are **one flow and not two screens**, and
## the reason is mechanical rather than cosmetic: a Rite node in a Legacy slot
## only applies if the next life repeats that class, so the choice and its
## payload have to be made in sight of each other.
##
## ## The life is already over
##
## This does not *decide* the death — `GameState.die()` has already run, and
## `last_life` is the record it left behind. That ordering is deliberate:
## a choice offered **instead** of the wipe is a life you could keep by not
## choosing, and quitting at the wrong moment would be the escape `M3-T15`
## exists to close. Come back later and pick; come back later and be alive, no.

signal finished

const MARGIN: float = 48.0


var _panel: int = 0
var _column: VBoxContainer = null


func _ready() -> void:
	# ADR-111: `_and_offsets_`, or a `Control` under a `CanvasLayer` has no rect
	# and takes no clicks.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.color = MenuStyle.INK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_column = VBoxContainer.new()
	_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_column.add_theme_constant_override("separation", 14)
	_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.offset_left = MARGIN
	_column.offset_right = -MARGIN
	_column.offset_top = MARGIN
	_column.offset_bottom = -MARGIN
	add_child(_column)

	_show_what_you_learned()


func _clear() -> void:
	for child: Node in _column.get_children():
		child.queue_free()


func _heading(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	_column.add_child(label)


func _line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(label)


## **Panel one — ADR-006.** *"A failed run must still visibly move a bar, and
## the player must see it move."* This is that bar, and it is first on the
## screen because the first thing a player wants after dying is a reason the
## run was not nothing.
func _show_what_you_learned() -> void:
	_panel = 0
	_clear()
	_heading(tr("legacy.learned.title"))
	_line(tr("legacy.learned.body") % GameState.lineage_progress)
	var went: Dictionary = GameState.last_life
	_line(tr("legacy.learned.life") % [
		String(went.get("class_id", "")), int(went.get("rank", 1))])
	var onward := Button.new()
	onward.text = tr("legacy.learned.next")
	onward.pressed.connect(_show_the_slots)
	_column.add_child(onward)
	MenuStyle.focus_first.call_deferred(self)


## **Panel two — ADR-003.** Everything the last life had, offered once.
func _show_the_slots() -> void:
	_panel = 1
	_clear()
	_heading(tr("legacy.keep.title") % Config.tuning.legacy_slot_count)
	_line(tr("legacy.keep.body"))
	for row: Dictionary in offers():
		var button := Button.new()
		var kind := String(row["kind"])
		var id := StringName(row["id"])
		button.text = "%s — %s" % [row["name"], tr("legacy.kind.%s" % kind)]
		button.pressed.connect(func() -> void: _take(kind, id))
		button.disabled = GameState.why_not_keep(kind, id) != ""
		_column.add_child(button)
	var onward := Button.new()
	onward.text = tr("legacy.keep.next")
	onward.pressed.connect(_show_the_next_life)
	_column.add_child(onward)
	MenuStyle.focus_first.call_deferred(self)


## What the last life can still be remembered for. Worn, stashed, and bought —
## and **not** the carried bag, which `DES-012` says dying costs you outright.
func offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var went: Dictionary = GameState.last_life
	for raw: Variant in went.get("worn", []) as Array:
		out.append(_offer("item", StringName(raw)))
	for raw: Variant in went.get("stash", []) as Array:
		out.append(_offer("item", StringName(raw)))
	for raw: Variant in went.get("taken", []) as Array:
		out.append(_offer("node", StringName(raw)))
	return out


func _offer(kind: String, id: StringName) -> Dictionary:
	var shown: String = String(id)
	if kind == "item":
		var definition: ItemResource = ItemCatalogue.by_id(id)
		if definition != null:
			shown = definition.display()
	else:
		var node: AspectNode = AspectCatalogue.by_id(id)
		if node != null:
			shown = node.display()
	return {"kind": kind, "id": id, "name": shown}


func _take(kind: String, id: StringName) -> void:
	if GameState.keep_in_legacy(kind, id):
		_show_the_slots()


## **Panel three — ADR-009.** Reused, not rebuilt: `M3-T02` already owns what a
## class choice looks like, and a second one would be the parallel path ADR-064
## bans.
func _show_the_next_life() -> void:
	_panel = 2
	_clear()
	var screen := ClassScreen.new()
	screen.chosen.connect(func(_id: StringName) -> void:
		# The slots pay out **after** the class is sworn, because a Rite node
		# only applies if the next life repeats its class (`DES-003`) — so what
		# a slot is worth is not knowable until this moment.
		GameState.draw_on_legacy()
		finished.emit())
	add_child(screen)
	MenuStyle.focus_first.call_deferred(screen)


## Which panel is up, for `--legacy-probe`. Panels rather than a scene each,
## so the flow is one object and `PRO-001`'s *"one flow, not two screens"* is
## structural instead of a note.
func panel() -> int:
	return _panel


## Drive the flow without a mouse, the way `ClassScreen.press` does.
func advance() -> void:
	match _panel:
		0:
			_show_the_slots()
		1:
			_show_the_next_life()
