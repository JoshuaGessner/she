class_name WoundMarks
extends Control

## **What is wrong with me, by name** (`M4-T14`, ADR-239, `DES-019` Layer 2).
##
## `DES-019` puts *health, stamina, wounds* in the `BODY` region, and health is
## the vignette's (`WoundVignette`: how bad, never how many). A wound is not a
## degree of anything. It is a named fact with a named consequence — no guard,
## no two-hander; no bearing on the Ear; slower and louder — so it is drawn as a
## mark with its name beside it, and a player who cannot block can look down and
## see why rather than deciding the button is broken (principle 4).
##
## ## Shape first (`DES-018`)
##
## Each wound is its own silhouette — a snapped bar, a cracked head, three
## slashes — so the marks read with the colour gone and the words unread. The
## word is there for the first time; the shape is what gets read after that.
## `PartyFrames` draws the same shapes, smaller, so a teammate learned from the
## inside is recognised on somebody else.
##
## No number anywhere (`DES-019` rule 2). The concussion's clock is a line
## under its name that shortens — `FallenReadout`'s vocabulary for a window
## running out — because *it will pass* is a fact worth a glance and *23 s* is
## a reading task.

## Order on screen, top to bottom, and the order `PartyFrames` draws them in.
## Fixed, so a mark never moves because another arrived.
const ORDER: Array[Enums.Wound] = [
	Enums.Wound.BROKEN_ARM, Enums.Wound.CONCUSSED, Enums.Wound.GASHED_LEG]
const KEYS: Dictionary = {
	Enums.Wound.BROKEN_ARM: "wound.broken_arm",
	Enums.Wound.CONCUSSED: "wound.concussed",
	Enums.Wound.GASHED_LEG: "wound.gashed_leg",
}
## One mark's height in pixels ⟨tune⟩.
const ROW: float = 24.0
## The glyph's side ⟨tune⟩.
const GLYPH: float = 18.0
const STROKE: float = 2.0
## Seconds a newly taken wound stands out for ⟨tune⟩. A wound arrives in the
## middle of a blow, and a mark that simply appeared would be missed there.
const FRESH_SECONDS: float = 1.4

var _body: Player = null
## The bits already seen, so a new one can be told from an old one.
var _seen: int = 0
var _fresh: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## **Three rows, whatever is carried.** `PartyFrames`' argument: a region that
## resized as wounds came and went would move the marks at the moment somebody
## is reading them, and `settle` grows a control but never shrinks one.
func _get_minimum_size() -> Vector2:
	return Vector2(0.0, ROW * float(ORDER.size()))


func _process(delta: float) -> void:
	if _body == null or not is_instance_valid(_body):
		_body = get_tree().get_first_node_in_group("local_player") as Player
		_seen = _body.wounds if _body != null else 0
	var now: int = _body.wounds if _body != null else 0
	for kind: Enums.Wound in ORDER:
		var bit: int = 1 << kind
		if (now & bit) != 0 and (_seen & bit) == 0:
			_fresh[kind] = 1.0
	_seen = now
	for kind: Variant in _fresh.keys():
		_fresh[kind] = maxf(0.0, float(_fresh[kind]) - delta / FRESH_SECONDS)
	queue_redraw()


## The wounds the local body carries, in `ORDER`. Public because the probe asks
## what is drawn from the same list the drawing uses.
func shown() -> Array[Enums.Wound]:
	var marks: Array[Enums.Wound] = []
	if _body == null or not is_instance_valid(_body):
		return marks
	for kind: Enums.Wound in ORDER:
		if _body.has_wound(kind):
			marks.append(kind)
	return marks


func _draw() -> void:
	var marks: Array[Enums.Wound] = shown()
	if marks.is_empty():
		return
	var ink: Color = MenuStyle.tone(self, MenuStyle.TEXT)
	var faint: Color = MenuStyle.tone(self, MenuStyle.DIM)
	var font: Font = get_theme_default_font()
	# Bottom-anchored, like the region: the last mark sits on the floor of it.
	var top: float = size.y - ROW * float(marks.size())
	for kind: Enums.Wound in marks:
		var fresh: float = float(_fresh.get(kind, 0.0))
		var box := Rect2(0.0, top + (ROW - GLYPH) * 0.5, GLYPH, GLYPH)
		draw_glyph(self, kind, box, ink, STROKE + 2.0 * fresh)
		var name_at := Vector2(GLYPH + 8.0, top + ROW * 0.5 + 5.0)
		draw_string(font, name_at, tr(String(KEYS[kind])),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, ink if fresh > 0.0 else faint)
		if kind == Enums.Wound.CONCUSSED and _body != null:
			var whole: float = maxf(Config.tuning.concussion_seconds, 0.001)
			var share: float = clampf(_body.dazed / whole, 0.0, 1.0)
			draw_rect(Rect2(name_at.x, top + ROW - 3.0, 90.0 * share, 2.0), faint)
		top += ROW


## **One wound's silhouette, inside `box`** — shared with `PartyFrames` so the
## two can never draw different shapes for the same fact.
static func draw_glyph(canvas: CanvasItem, kind: Enums.Wound, box: Rect2,
		ink: Color, stroke: float) -> void:
	var at := func(x: float, y: float) -> Vector2:
		return box.position + Vector2(x, y) * box.size
	match kind:
		Enums.Wound.BROKEN_ARM:
			# A bar snapped in two, the halves knocked out of line.
			canvas.draw_line(at.call(0.08, 0.78), at.call(0.44, 0.52), ink, stroke)
			canvas.draw_line(at.call(0.56, 0.36), at.call(0.92, 0.18), ink, stroke)
		Enums.Wound.CONCUSSED:
			# A head, cracked.
			canvas.draw_arc(at.call(0.5, 0.5), box.size.x * 0.40, 0.0, TAU, 20,
				ink, stroke, true)
			canvas.draw_polyline(PackedVector2Array([at.call(0.50, 0.10),
				at.call(0.40, 0.36), at.call(0.60, 0.52), at.call(0.46, 0.76)]),
				ink, stroke)
		Enums.Wound.GASHED_LEG:
			# Three slashes.
			for lane: int in 3:
				var shift: float = 0.24 * float(lane)
				canvas.draw_line(at.call(0.10 + shift, 0.86),
					at.call(0.34 + shift, 0.14), ink, stroke)
