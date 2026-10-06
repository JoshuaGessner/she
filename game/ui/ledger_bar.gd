class_name LedgerBar
extends Control

## **A debt or a store, filling** (ADR-337): a carved track, what is there, and
## — pale, ahead of it — what the thing you are looking at would add.
##
## The ghost is the whole point. *"60 more tribute over the tithe buys the
## first"* was a sentence a player had to do arithmetic against; a bar that
## shows the fill a gift **would** cause, before it is given, is the pattern
## every game with an experience bar settled on — Monster Hunter's and
## Destiny's reward screens, Darkest Dungeon's hero levels — because a length
## is read in a glance and a number is not.
##
## `over` is how many times the store would fill and start again: a gift worth
## two boons draws the bar full with `+2` stamped at its end, rather than a bar
## that silently wraps and looks smaller than before.

## What is there, and what would be, as fractions of the track.
var filled: float = 0.0
var ghost: float = 0.0
## Times a store would fill past its end — drawn as a count, not a wrap.
var over: int = 0
## Drawn in the alarming tone, for a debt that is short (`DES-018`: the word
## beside it says so too).
var owing: bool = false

const HEIGHT: float = 14.0
## How fast a moved bar runs to where it now stands, tracks a second (ADR-338).
const RUN: float = 1.4

## Where the fill is going, when it is easing there rather than jumping.
var _target: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `eased` runs the fill to `now` instead of setting it — a gift moves the bar
## you are watching, and a jump is a number changing where a run is something
## being paid in. `refill` empties it first, for a store that has just filled
## past its end and begun again.
func show_fill(now: float, would: float, fills: int = 0, short: bool = false,
		eased: bool = false, refill: bool = false) -> void:
	_target = clampf(now, 0.0, 1.0)
	if refill:
		filled = 0.0
	if not eased:
		filled = _target
	ghost = clampf(would, _target, 1.0) if fills == 0 else 1.0
	over = fills
	owing = short
	queue_redraw()


func _process(delta: float) -> void:
	if absf(filled - _target) > 0.0005:
		filled = move_toward(filled, _target, delta * RUN)
		queue_redraw()


func _draw() -> void:
	var track := Rect2(Vector2.ZERO, Vector2(size.x, HEIGHT))
	var ground: Color = Color(0.05, 0.046, 0.042, 1.0)
	var edge: Color = MenuStyle.tone(self, MenuStyle.DIM)
	var warm: Color = MenuStyle.tone(self, MenuStyle.WARM)
	var text: Color = MenuStyle.tone(self, MenuStyle.TEXT)
	# The tone itself, not the caption role: a lookup by type does not follow
	# a variation down to its base, and `CaptionDebt` holds only a size.
	var debt: Color = get_theme_color(&"font_color", &"Debt")
	draw_rect(track, ground)
	var inner: Rect2 = track.grow(-3.0)
	var lit: Color = debt if owing else warm
	var from: float = maxf(filled, _target)
	if ghost > from:
		# Pale and hatched: something that has not happened yet.
		var ahead := Rect2(inner.position + Vector2(inner.size.x * from, 0.0),
			Vector2(inner.size.x * (ghost - from), inner.size.y))
		draw_rect(ahead, Color(text, 0.22))
		var x: float = ahead.position.x
		while x < ahead.end.x:
			var top := Vector2(x, ahead.position.y)
			var foot := Vector2(minf(x + inner.size.y, ahead.end.x), ahead.end.y)
			draw_line(top, foot, Color(text, 0.55), 1.0)
			x += 5.0
	if filled > 0.0:
		draw_rect(Rect2(inner.position, Vector2(inner.size.x * filled, inner.size.y)), lit)
	# The carved edge last, so neither fill runs over it.
	draw_rect(track, edge, false, 1.0)
	draw_rect(track.grow(-1.5), Color(edge, 0.5), false, 1.0)
	if over > 0:
		var stamp: String = "+%d" % over
		var font: Font = get_theme_font(&"font", MenuStyle.CAPTION_WARM)
		var size_px: int = get_theme_font_size(&"font_size", MenuStyle.CAPTION_WARM)
		var wide: float = font.get_string_size(stamp, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
		# On a plate of its own at the bar's end, so it reads over fill and
		# hatch alike — the count is the news, and it was the faintest thing
		# on the bar.
		var plate := Rect2(Vector2(track.end.x - wide - 12.0, track.position.y - 3.0),
			Vector2(wide + 12.0, HEIGHT + 6.0))
		draw_rect(plate, ground)
		draw_rect(plate, warm, false, 1.0)
		draw_string(font, Vector2(plate.position.x + 6.0, track.end.y - 2.0),
			stamp, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, warm)
