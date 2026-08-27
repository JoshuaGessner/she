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


## **What is happening to you** (ADR-150).
##
## Split out of `_draw` so `--fallen-probe` can assert the **wording** rather
## than the pixels. That probe checked the rect was the screen, that three
## states were reachable, and that the clock ran — it never asked what any of
## them *said*, and what they said was the whole fault.
func line() -> String:
	if not _showing():
		return ""
	if _body.spent:
		# **A Vörðr, and it says so.** What it needs to name is what you *are*,
		# because a translucent body that walks through walls is otherwise a
		# bug rather than a state.
		#
		# *"Scout for them"* was written for a party and shipped to everybody.
		# Solo there is no them, the state lasts `party_wipe_seconds`, and the
		# reporter read it exactly as written: **"there is never anyone to save
		# them on a solo run."** The honest sentence is about who is left.
		return tr("fallen.vordr") if _anyone_still_standing() \
			else tr("fallen.vordr.alone")
	if _body.revival > 0.0:
		return tr("fallen.hand")
	return tr("fallen.down") % int(ceil(_body.bleeding))


## **And what you can still do about it** (ADR-150).
##
## `has_self_recovery()` has existed since ADR-050 — one way up, once per run,
## costing the rest of it — and was read by **one probe and nothing else**.
## ADR-098's question exactly: it worked, and nothing used it. So a downed solo
## player got forty-five seconds of a shrinking bar and no hint that the thing
## they were waiting to be saved from was theirs to end.
##
## Built from `ControlsScreen.glyphs_for` rather than typed, because ADR-139
## made that file the only one that names a key.
func hint() -> String:
	if not _showing() or _body.spent or _body.revival > 0.0:
		return ""
	if _body.has_self_recovery():
		return tr("fallen.up") % ControlsScreen.glyphs_for("use_waystone")
	return tr("fallen.up.spent")


func _showing() -> bool:
	return _body != null and is_instance_valid(_body) and _body.is_incapacitated()


## Is anybody left who could still do something? Excludes this body, which by
## the time it is asked is a Vörðr and can do nothing for anyone.
func _anyone_still_standing() -> bool:
	for node: Node in get_tree().get_nodes_in_group("player"):
		var body := node as Player
		if body != null and body != _body and not body.is_out():
			return true
	return false


func _draw() -> void:
	if not _showing():
		return
	var screen: Vector2 = size
	var origin := Vector2((screen.x - BAR.x) * 0.5, screen.y - FROM_BOTTOM)
	var font: Font = ThemeDB.fallback_font
	var fill: float = 0.0
	var tint: Color = DOWN_COLOUR

	if _body.spent:
		# No bar: there is no clock on this state, and drawing an empty one
		# would imply a deadline that does not exist.
		tint = VORDR_COLOUR
	elif _body.revival > 0.0:
		# **A hand on you.** Fills toward one, and it is the only bar here that
		# grows — which is the whole reason direction carries the meaning.
		fill = clampf(_body.revival, 0.0, 1.0)
		tint = HAND_COLOUR
	else:
		# **Down.** Shortens, because ADR-050 makes the shortening itself the
		# decision: *"your ember is going out whether you choose or not."*
		var whole: float = maxf(Config.tuning.bleed_out_seconds, 0.001)
		fill = clampf(_body.bleeding / whole, 0.0, 1.0)

	if not _body.spent:
		draw_rect(Rect2(origin, BAR), Color(0.06, 0.05, 0.05, 0.72))
		draw_rect(Rect2(origin, Vector2(BAR.x * fill, BAR.y)), tint)
		draw_rect(Rect2(origin, BAR), Color(0.0, 0.0, 0.0, 0.5), false, 1.0)

	_say(font, Vector2(origin.x, origin.y - 12.0), line(), 15, tint)
	# **Under the bar rather than beside the state line**, so the thing you can
	# do about it is not competing with the thing that is happening to you.
	var help: String = hint()
	if help != "":
		_say(font, Vector2(origin.x, origin.y + BAR.y + 20.0), help, 13,
			MenuStyle.DIM)


func _say(font: Font, at: Vector2, text: String, size_of: int,
		tint: Color) -> void:
	draw_string(font, at + Vector2(1.0, 1.0), text,
		HORIZONTAL_ALIGNMENT_CENTER, BAR.x, size_of, Color(0.0, 0.0, 0.0, 0.7))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, BAR.x, size_of, tint)
