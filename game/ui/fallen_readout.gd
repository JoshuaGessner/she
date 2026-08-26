class_name FallenReadout
extends Control

## **What is happening to you, while it happens** (`M3-T14`, `DES-012`).
##
## `GATE M3 COOP` has carried this as a precondition since ADR-115 — *"the
## downed player can tell what is happening to them while down"* — and no build
## has ever had an answer. A player taken to zero got a frozen camera, a number
## nowhere, and no way to know whether anyone was coming.
##
## That is `PRO-005` §5's unexplainable event applied to the worst moment in the
## game, and it is also a **social** failure: `DES-012`'s whole rescue design
## assumes the downed player is deciding whether to hold on, and you cannot
## decide anything you cannot see.
##
## ## Three states, and each one answers a different question
##
## | | The question it answers |
## |---|---|
## | **Down** | *How long have I got, and is anyone coming?* |
## | **A hand on you** | *Is it working, and how far along?* |
## | **Vörðr** | *What am I now, and what happens next?* |
##
## ## Not a health bar
##
## `DES-019`'s Burden layer is `M4-T05` and this is not a provisional one. It
## reads the two values `DES-012` already replicates for exactly this purpose —
## `bleeding` and `revival` — and draws nothing that is not one of them. The
## test `WoundVignette` sets: remove it and *"how long have I got"* becomes
## unanswerable, which is a fact rather than a feeling.
##
## Monochrome-safe (`DES-018`): the bleed-out is a **shortening bar** and the
## revive is a **filling** one, so direction carries the meaning and hue only
## agrees with it. With the sound muted and no colour at all, a shrinking bar
## and a growing bar still read as opposite things.

## Bottom-centre, above where the bag opens. Deliberately not the corner the Ear
## holds: this is the most important thing on screen while it is on screen, and
## it should be where the eyes already are rather than where a status effect
## would conventionally sit.
const BAR: Vector2 = Vector2(360.0, 10.0)
const FROM_BOTTOM: float = 140.0

const DOWN_COLOUR: Color = Color(0.86, 0.28, 0.24)
const HAND_COLOUR: Color = Color(0.42, 0.78, 0.46)
const VORDR_COLOUR: Color = Color(0.62, 0.74, 0.90)

var _body: Player = null


func _ready() -> void:
	# `Control` under a `CanvasLayer` gets no layout of its own (ADR-111), and
	# at 0 x 0 nothing is drawn and nothing is clicked. The full-rect preset is
	# what makes `size` mean the screen.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_delta: float) -> void:
	# Found by group rather than by scene order, and bound to `local_player`
	# because this is the readout for **the person holding the camera** — a
	# teammate's numbers on your screen would be the wrong answer to every
	# question above.
	if _body == null or not is_instance_valid(_body):
		_body = get_tree().get_first_node_in_group("local_player") as Player
	queue_redraw()


func _draw() -> void:
	if _body == null or not is_instance_valid(_body):
		return
	if not _body.is_incapacitated():
		return
	var screen: Vector2 = size
	var origin := Vector2((screen.x - BAR.x) * 0.5, screen.y - FROM_BOTTOM)
	var font: Font = ThemeDB.fallback_font
	var label: String = ""
	var fill: float = 0.0
	var tint: Color = DOWN_COLOUR

	if _body.spent:
		# **A Vörðr, and it says so.** No bar: there is no clock on this state
		# and drawing an empty one would imply a deadline that does not exist.
		# What it needs to say is what you *are*, because a translucent body
		# that walks through walls is otherwise a bug rather than a state.
		label = tr("fallen.vordr")
		tint = VORDR_COLOUR
	elif _body.revival > 0.0:
		# **A hand on you.** Fills toward one, and it is the only bar here that
		# grows — which is the whole reason direction carries the meaning.
		label = tr("fallen.hand")
		fill = clampf(_body.revival, 0.0, 1.0)
		tint = HAND_COLOUR
	else:
		# **Down.** Shortens, because ADR-050 makes the shortening itself the
		# decision: *"your ember is going out whether you choose or not."*
		var whole: float = maxf(Config.tuning.bleed_out_seconds, 0.001)
		fill = clampf(_body.bleeding / whole, 0.0, 1.0)
		label = tr("fallen.down") % int(ceil(_body.bleeding))
		tint = DOWN_COLOUR

	if not _body.spent:
		draw_rect(Rect2(origin, BAR), Color(0.06, 0.05, 0.05, 0.72))
		draw_rect(Rect2(origin, Vector2(BAR.x * fill, BAR.y)), tint)
		draw_rect(Rect2(origin, BAR), Color(0.0, 0.0, 0.0, 0.5), false, 1.0)

	var text_at := Vector2(origin.x, origin.y - 12.0)
	draw_string(font, text_at + Vector2(1.0, 1.0), label,
		HORIZONTAL_ALIGNMENT_CENTER, BAR.x, 15, Color(0.0, 0.0, 0.0, 0.7))
	draw_string(font, text_at, label,
		HORIZONTAL_ALIGNMENT_CENTER, BAR.x, 15, tint)
