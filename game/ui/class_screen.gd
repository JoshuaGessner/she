class_name ClassScreen
extends Control

## Choosing who you are this life (`M3-T02`, `DES-011`, ADR-120).
##
## **The first screen with a decision on it that cannot be taken back.**
## `DES-011` locks class for a life and ADR-009 makes death the door to a new
## one, so this opens exactly twice in a lineage's worth of play: on a fresh
## profile, and after every death. `M3-T05` builds the second door — death, what
## you learned, the Legacy slots, and then this — and the two are one flow
## rather than two screens (ADR-116 §2).
##
## ## It leads with the loop, not with the stats
##
## `DES-011`'s own structure: *"every class below is defined first by its answer
## to **how does this class get out?**"* — because *"classes must differ in
## their relationship to the loop, not just in their damage type."* So the big
## text on each entry is `exit_key`, and the body numbers are not shown at all.
## There is nothing to compare, which is deliberate: a screen listing +25%
## health invites the arithmetic `DES-019` keeps out of a run and `DES-009` Q22
## refused a stat block to avoid.
##
## ## One class, and the rest genuinely absent (ADR-064)
##
## The screen renders whatever `ClassCatalogue` holds. `huskarl` is authored;
## the Veiðimaðr is `M3-T11` and the other four are `M5-T01`. They are not
## greyed out and not listed, because *"a stubbed class a playtester can pick
## and that does nothing produces worthless feedback"* — and a name behind a
## lock produces the same feedback about a promise instead of a game.
##
## `set_anchors_and_offsets_preset`, not `set_anchors_preset`. A `Control`
## parented to a `CanvasLayer` gets no layout, so the preset that sets anchors
## alone leaves it 0 x 0 and every click misses (ADR-111). That cost the whole
## of `M2-T18` to find once.

## Raised with the id the player committed to.
signal chosen(id: StringName)

const MARGIN: float = 48.0
const CARD_WIDTH: float = 520.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.color = MenuStyle.INK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.offset_left = MARGIN
	column.offset_right = -MARGIN
	column.offset_top = MARGIN
	column.offset_bottom = -MARGIN
	add_child(column)

	column.add_child(MenuStyle.title("WHO GOES DOWN"))
	# The cost stated before the choice rather than after it. `PRO-005` is
	# explicit that the harshness has to be legible in advance — a lock the
	# player discovers on their first death is a different game from the one
	# they agreed to play.
	column.add_child(MenuStyle.line(
		"Chosen once, and kept until you die.", 16, MenuStyle.WARM))

	var sworn: Array[ClassResource] = ClassCatalogue.all()
	for entry: ClassResource in sworn:
		column.add_child(_card(entry))

	if sworn.is_empty():
		# Not a friendly empty state — a loud one. An export whose class table
		# came back empty is a build nobody can play, and ADR-086 records that
		# arriving silently at full size. Saying so here is cheaper than a
		# playtester describing a menu with nothing in it.
		push_error("ClassScreen: the catalogue is empty; no life can begin")
		column.add_child(MenuStyle.line(
			"No classes are in this build. That is a packaging fault, not a choice.",
			16, MenuStyle.WARM))


## One class, led by how it gets out (`DES-011`).
func _card(entry: ClassResource) -> Control:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0.0)

	var pick: Button = MenuStyle.button(entry.display())
	pick.custom_minimum_size = Vector2(CARD_WIDTH, 44.0)
	pick.pressed.connect(func() -> void: _commit(entry))
	card.add_child(pick)

	if entry.description_key != &"":
		card.add_child(MenuStyle.line(tr(String(entry.description_key)), 15))
	if entry.exit_key != &"":
		card.add_child(MenuStyle.line(tr(String(entry.exit_key)), 14, MenuStyle.DIM))
	return card


func _commit(entry: ClassResource) -> void:
	GameState.take_the_oath(entry.id)
	chosen.emit(entry.id)
	queue_free()


## Used by `--class-probe`: press an entry without a mouse, so the check
## exercises the same path a click does rather than calling `_commit` past the
## button. `M2-T18` is the reason that distinction is not pedantic — the bag's
## rules were all correct and no click had ever reached them.
func press(id: StringName) -> bool:
	for entry: ClassResource in ClassCatalogue.all():
		if entry.id != id:
			continue
		for node: Node in find_children("*", "Button", true, false):
			var pick := node as Button
			if pick != null and pick.text == entry.display():
				pick.emit_signal("pressed")
				return true
	return false
