class_name DeedsBanner
extends Control

## **What you did, after what you kept** (`M3-T08`, `DES-016`).
##
## `DES-016` is exact about when: *"awarded at the Settle beat, shown **after**
## the tribute decision, so the run ends on evidence of what you did rather than
## on a balance sheet."*
##
## And exact about when not: **no achievement popups mid-run.** They break the
## pressure the whole game is built on, so a deed earned in the Deep waits in
## `fresh_deeds` and surfaces here.
##
## ## What it deliberately is not
##
## No completion percentage and no checklist. `DES-016`: *"a gallery of
## everything you haven't done converts the system from evidence into a chore"*
## (`PRO-005` §11). This shows what happened, once, and has no view of what
## did not.
##
## Nor does any description say how a deed was earned — ADR-050 makes deeds
## **secret**, found through Bound gossip rather than a list, so the text is
## about the act rather than about the condition.

signal dismissed

const MARGIN: float = 48.0
## A deed's card, and the measure its sentence wraps at. ⟨tune⟩
const CARD_WIDTH: float = 440.0
## More deeds than this lay out two to a row, so a run that earned all five
## still fits the 1152 x 648 the game opens at. ⟨tune⟩
const ONE_COLUMN_MAX: int = 2


## ## Each deed is a plate (ADR-334)
##
## The banner drew in the engine's own white: a title, then name-and-sentence
## pairs floating down the middle of a scrim, the same weight as a tooltip.
## It is the run's last word (`DES-016`) and it looked like a debug list. Now
## each deed is a carved card — its name in the warm tone, what you did under
## it at a readable measure — the way Darkest Dungeon lays a trinket or a quirk
## in front of you: one object at a time, framed, so it reads as *a thing you
## got* rather than as a line of output.
func show_these(ids: Array[String]) -> void:
	# ADR-111: `_and_offsets_`, or a `Control` under a `CanvasLayer` has no rect.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop: Control = MenuStyle.backdrop(MenuStyle.SCRIM)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 16)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.offset_left = MARGIN
	column.offset_right = -MARGIN
	column.offset_top = MARGIN * 0.5
	column.offset_bottom = -MARGIN * 0.5
	add_child(column)

	var heading: Label = MenuStyle.title(tr("deeds.title"), MenuStyle.DEEDS_TITLE)
	column.add_child(heading)

	var shown: Array[DeedResource] = []
	for id: String in ids:
		var mark: DeedResource = DeedCatalogue.by_id(StringName(id))
		if mark != null:
			shown.append(mark)
	var grid := GridContainer.new()
	grid.columns = 1 if shown.size() <= ONE_COLUMN_MAX else 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(grid)
	for mark: DeedResource in shown:
		grid.add_child(_card(mark))

	var away: Button = MenuStyle.button(tr("deeds.dismiss"))
	away.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	away.custom_minimum_size = Vector2(360.0, 44.0)
	away.pressed.connect(func() -> void:
		dismissed.emit()
		queue_free())
	column.add_child(away)
	# The banner is dismissed through this button on both mouse and gamepad.
	# Without a focus owner, a pad has a visible button but no way to activate it.
	MenuStyle.focus_first.call_deferred(self)


func _card(mark: DeedResource) -> Control:
	var plate := PanelContainer.new()
	plate.theme_type_variation = MenuStyle.SLATE
	plate.custom_minimum_size = Vector2(CARD_WIDTH, 0.0)
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 6)
	plate.add_child(inside)
	inside.add_child(MenuStyle.title(mark.display(), MenuStyle.DEED_NAME))

	var told: Label = MenuStyle.line("", MenuStyle.BODY_TEXT)
	# **The name goes in the text** (ADR-050): *"rescue deeds record who you
	# carried out."* A deed whose name was not kept says *someone*. It used to
	# leave the `%s` unformatted on the argument that a blank reads as a bug —
	# and printed *"%s's ember, carried the whole way"*, which reads as a worse
	# one (ADR-334).
	var who: String = String(GameState.deeds.get(String(mark.id), ""))
	if who == "":
		who = tr("deeds.someone")
	var body: String = tr(String(mark.description_key))
	told.text = (body % who) if body.contains("%s") else body
	told.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inside.add_child(told)
	return plate
