class_name RunOverScreen
extends Control

## **The run is over, and it says so** (`M3-T30`, ADR-151).
##
## What a wipe used to be, from the seat: the bleed bar empties, a line about
## being a Vörðr appears, and three seconds later the scene changes. No
## acknowledgement, no agency, and — solo — no way to tell an ending from a
## hang. Reported as *"they bleed out but there is never anyone to save them."*
##
## `party_wipe_seconds` exists for two reasons (ADR-108) and the first is
## *"a cut to the camp on the frame you go out gives the player nothing to
## read."* That was right about the problem and short of a solution: three
## seconds of the same readout is not something to read. This is.
##
## ## It is not a death screen
##
## `DES-003` puts the Legacy choice at the fire and ADR-133 is explicit that it
## wants a scene rather than a modal over a corpse. Nothing here chooses
## anything: it names what happened, says what it cost, and takes you to the
## fire, where the screen that *is* a decision is waiting. Two screens, one
## decision, and the transition stopped being a hard cut.
##
## The other thing the reporter asked for — *"restart a fresh delve"* — cannot
## exist here: the Legacy flow is what starts the next life, and a button that
## jumped it would delete the choice `DES-003` calls the piece it feels
## strongest about. **Return** is not that button (ADR-410): it ends the life
## here and opens the Legacy flow where you stand, and the new life walks back
## into this run rather than a fresh one.

signal leave_now
## **Or walk back in** (ADR-410). With nobody standing the choice is Return or
## the end, and both are on this screen; the level asks the host.
signal return_now

const MARGIN: float = 48.0

## Whether this peer's body could still walk back in, set before the screen
## enters the tree. False for a life already saved, or with nothing to return.
var can_return: bool = false
## **The window, shortening** (ADR-410, ADR-050): seconds until the run ends on
## its own. Shown only alongside Return — a clock with nothing to decide
## against is the timer ADR-151 replaced with a press.
var window_seconds: float = 0.0
var _ends_at: int = 0
var _window_bar: ColorRect = null
var _window_line: Label = null


func _ready() -> void:
	# ADR-111: a `Control` under a `CanvasLayer` gets no rect from anchors
	# alone, and at 0 x 0 it draws nothing and takes no clicks.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(MenuStyle.backdrop())

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.offset_left = MARGIN
	centre.offset_right = -MARGIN
	add_child(centre)

	var column: VBoxContainer = MenuStyle.column(14)
	centre.add_child(column)
	column.add_child(MenuStyle.title(tr("runover.title"), MenuStyle.SCREEN_TITLE))
	column.add_child(MenuStyle.line(
		tr("runover.body.return" if can_return else "runover.body"), MenuStyle.BODY_DIM))
	if can_return:
		# Return first, because it is the one with something to lose by waiting.
		var back: Button = MenuStyle.button(tr("runover.return"))
		back.name = "Return"
		back.pressed.connect(func() -> void: return_now.emit())
		column.add_child(back)

	var go: Button = MenuStyle.button(tr("runover.go"))
	go.name = "Leave"
	go.pressed.connect(func() -> void: leave_now.emit())
	column.add_child(go)
	if can_return and window_seconds > 0.0:
		# **A bar that shortens, and says what is shortening** (`DES-018`: the
		# direction carries it with the sound off and no colour at all).
		_ends_at = Time.get_ticks_msec() + int(window_seconds * 1000.0)
		_window_line = MenuStyle.line("", MenuStyle.CAPTION_DIM)
		column.add_child(_window_line)
		var track := ColorRect.new()
		track.color = MenuStyle.tone(self, MenuStyle.DIM)
		track.custom_minimum_size = Vector2(320.0, 6.0)
		column.add_child(track)
		_window_bar = ColorRect.new()
		_window_bar.color = MenuStyle.tone(self, MenuStyle.TEXT)
		_window_bar.size = Vector2(320.0, 6.0)
		track.add_child(_window_bar)
		_tick_window()
	# ADR-141: a screen nothing focuses is a screen a pad cannot reach.
	MenuStyle.focus_first.call_deferred(self)


func _process(_delta: float) -> void:
	if _window_bar != null:
		_tick_window()


func _tick_window() -> void:
	var left: float = maxf(0.0, float(_ends_at - Time.get_ticks_msec()) / 1000.0)
	_window_bar.size.x = 320.0 * clampf(left / maxf(window_seconds, 0.001), 0.0, 1.0)
	_window_line.text = tr("runover.window") % ceili(left)


## Press it without a mouse, the way `ClassScreen.press` does — through the
## button rather than past it, because `M2-T18` is the reason that distinction
## is not pedantic. Leaving, by default; `"Return"` for the other door.
func press(which: String = "Leave") -> bool:
	var button := find_child(which, true, false) as Button
	if button == null:
		return false
	button.emit_signal("pressed")
	return true
