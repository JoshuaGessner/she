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
	# A pad has to be able to swear an oath (ADR-141, ADR-075). Deferred, since
	# a `Control` takes focus only once the cards below are in the tree.
	MenuStyle.focus_first.call_deferred(self)

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
	# **A refused oath is not a choice** (ADR-148). This ignored the answer and
	# announced one anyway, so a screen opened on a life that already had a
	# class told the Legacy flow a decision had been made — and the flow replied
	# by paying out the Legacy slots and clearing the death record, on a life
	# that had never ended. `DES-011` locks the class until death and
	# `take_the_oath` is where that lock lives; reporting past it makes the lock
	# true of the rules and false of the game.
	if not GameState.take_the_oath(entry.id):
		return
	chosen.emit(entry.id)
	queue_free()


## Press an entry the way a player does (`M3-T40`, ADR-162).
##
## `M2-T18` is why this goes through the button at all rather than calling
## `_commit`: the bag's rules were all correct and no click had ever reached
## them. **This did not go far enough**, and the gap cost two play sessions.
##
## `emit_signal("pressed")` runs the handler *inline, in the caller's frame* —
## and every probe in this project calls it from a coroutine that has already
## been resumed by `process_frame`. A real click runs the same handler during
## **input dispatch**, which is earlier in the frame than idle processing and
## therefore on the other side of the deletion-queue flush. Measured:
##
## | the oath is sworn from | the body `_rebuild` spawns |
## |---|---|
## | a coroutine resumed at `process_frame` | keeps its name; the camp works |
## | input dispatch (a real click) | **renamed; the camp goes dead** |
##
## So every class row in this project was green about a code path players do
## not take. `--threshold-probe` swears a class at the fire and asserts the
## body afterwards, and it passed throughout the fault being reported.
##
## Not a second press path beside the old one (ADR-064): the old one is gone,
## so no check can accidentally take the easy road again.
##
## **Where in the frame it happens is the whole point**, and getting that right
## took three attempts, each of which measured the last one wrong:
##
## 1. `emit_signal("pressed")` — runs the handler inline in the caller's
##    frame. Every probe calls this from a coroutine resumed by
##    `process_frame`, which is **after** the deletion queue is flushed.
## 2. `Input.parse_input_event` from the same coroutine — no better.
##    `parse_input_event` dispatches *synchronously*, so the event went
##    through the button, through focus, through `BaseButton`'s action
##    handling, and still arrived at the same place in the frame.
## 3. Awaiting the press through to the oath — hangs forever. `_commit` frees
##    this screen, and a coroutine whose `self` has been freed never resumes.
##    A function cannot watch its own destruction.
##
## What a real click actually does is arrive during **input dispatch**, which
## is before idle processing and therefore before that frame's flush. So the
## press is armed here and fired from `_process`, which is the same side of the
## flush and the earliest place a probe can stand. Measured, with the fix
## removed: pressed from a coroutine the camp survives, pressed from `_process`
## it goes dead — the same code, the same button, one frame apart.
##
## The bool still means *"there is a button for this class and it is now
## armed"*; the oath lands a frame later, and all four callers already wait.
func press(id: StringName) -> bool:
	for entry: ClassResource in ClassCatalogue.all():
		if entry.id != id:
			continue
		for node: Node in find_children("*", "Button", true, false):
			var pick := node as Button
			if pick == null or pick.text != entry.display():
				continue
			# A focused control is what `ui_accept` is delivered to, and
			# nothing here has focus by default. Immediate, unlike the press.
			pick.grab_focus()
			_armed = pick
			set_process(true)
			return true
	return false


## The button `_process` is about to press. See `press`.
var _armed: Button = null


func _process(_delta: float) -> void:
	if _armed == null:
		set_process(false)
		return
	_armed = null
	set_process(false)
	var down := InputEventAction.new()
	down.action = &"ui_accept"
	down.pressed = true
	Input.parse_input_event(down)
	# Both halves in one breath. `BaseButton` emits `pressed` on the release by
	# default, so a press with no matching lift is a button held down forever
	# and never actually clicked.
	var up := InputEventAction.new()
	up.action = &"ui_accept"
	up.pressed = false
	Input.parse_input_event(up)
