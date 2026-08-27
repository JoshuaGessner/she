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
## The button is the only one on offer because the other thing the reporter
## asked for — *"restart a fresh delve"* — cannot exist here. Your life is over;
## the Legacy flow is what starts the next one, and a button that jumped it
## would delete the choice `DES-003` calls the piece it feels strongest about.

signal leave_now

const MARGIN: float = 48.0


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
	column.add_child(MenuStyle.title(tr("runover.title"), 34))
	column.add_child(MenuStyle.line(tr("runover.body"), 16))

	var go: Button = MenuStyle.button(tr("runover.go"))
	go.pressed.connect(func() -> void: leave_now.emit())
	column.add_child(go)
	# ADR-141: a screen nothing focuses is a screen a pad cannot reach.
	MenuStyle.focus_first.call_deferred(self)


## Press it without a mouse, the way `ClassScreen.press` does — through the
## button rather than past it, because `M2-T18` is the reason that distinction
## is not pedantic.
func press() -> bool:
	for node: Node in find_children("*", "Button", true, false):
		var button := node as Button
		if button != null:
			button.emit_signal("pressed")
			return true
	return false
