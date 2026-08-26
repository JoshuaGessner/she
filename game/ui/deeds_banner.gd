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

const MARGIN: float = 64.0


func show_these(ids: Array[String]) -> void:
	# ADR-111: `_and_offsets_`, or a `Control` under a `CanvasLayer` has no rect.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.color = Color(MenuStyle.INK, 0.86)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 12)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.offset_left = MARGIN
	column.offset_right = -MARGIN
	add_child(column)

	var heading := Label.new()
	heading.text = tr("deeds.title")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	column.add_child(heading)

	for id: String in ids:
		var mark: DeedResource = DeedCatalogue.by_id(StringName(id))
		if mark == null:
			continue
		var name_label := Label.new()
		name_label.text = mark.display()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 20)
		column.add_child(name_label)

		var told := Label.new()
		# **The name goes in the text** (ADR-050): *"rescue deeds record who you
		# carried out."* `%s` in a description that has no name to fill is left
		# alone rather than formatted, because a stray blank reads as a bug and
		# a deed about nobody should not pretend otherwise.
		var who: String = String(GameState.deeds.get(id, ""))
		var body: String = tr(String(mark.description_key))
		told.text = (body % who) if (who != "" and body.contains("%s")) else body
		told.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		told.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(told)

	var away := Button.new()
	away.text = tr("deeds.dismiss")
	away.pressed.connect(func() -> void:
		dismissed.emit()
		queue_free())
	column.add_child(away)
