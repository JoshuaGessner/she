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
## **A Scar is the same shape, faint and unnamed** (ADR-240). It is a fact of
## the life rather than of this fight, so it is there to be recognised and not
## read; the Chamber names it. A fresh wound on a scarred limb shows the wound.
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
const PLACES: Dictionary = {
	Enums.Wound.BROKEN_ARM: "arm",
	Enums.Wound.CONCUSSED: "head",
	Enums.Wound.GASHED_LEG: "leg",
}
## One mark's height in pixels ⟨tune⟩.
const ROW: float = 24.0
## The glyph's side ⟨tune⟩.
const GLYPH: float = 18.0
const STROKE: float = 2.0
## Seconds a newly taken wound stands out for ⟨tune⟩. A wound arrives in the
## middle of a blow, and a mark that simply appeared would be missed there.
const FRESH_SECONDS: float = 1.4
## **Breath** (ADR-314): `DES-019`'s third thing in this region, and the one
## nothing drew. A line on the region's floor that shortens as you spend, with a
## tick where a guard stops holding; below the tick it dims and beats, so *my
## guard will not hold* is on the screen before the blow rather than explained
## after it. No number. Shown while it is spent and gone a moment after it is
## whole again, so a calm screen stays empty.
const BREATH_ROW: float = 14.0
const BREATH_WIDTH: float = 120.0
const BREATH_LINGER: float = 1.0

var _body: Player = null
## The bits already seen, so a new one can be told from an old one.
var _seen: int = 0
var _fresh: Dictionary = {}
var _breath_shown: float = 0.0
var _whole_for: float = 0.0
var _beat: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## **Three rows, whatever is carried.** `PartyFrames`' argument: a region that
## resized as wounds came and went would move the marks at the moment somebody
## is reading them, and `settle` grows a control but never shrinks one.
func _get_minimum_size() -> Vector2:
	return Vector2(0.0, ROW * float(ORDER.size()) + BREATH_ROW)


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
	_beat += delta
	if _body != null and _breath() < 0.999:
		_whole_for = 0.0
		_breath_shown = move_toward(_breath_shown, 1.0, delta * 6.0)
	else:
		_whole_for += delta
		if _whole_for > BREATH_LINGER:
			_breath_shown = move_toward(_breath_shown, 0.0, delta * 2.0)
	queue_redraw()


## The local body's breath as a share of its whole, or whole if there is none.
func _breath() -> float:
	if _body == null or not is_instance_valid(_body):
		return 1.0
	return clampf(_body.stamina.current / maxf(_body.stamina.maximum(), 0.001), 0.0, 1.0)


## How much of the breath line is drawn, 0 to 1 — for `--party-shot`.
func breath_shown() -> float:
	return _breath_shown


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


## The Scars the local body's life carries and no wound covers, in `ORDER`.
func scars_shown() -> Array[Enums.Wound]:
	var marks: Array[Enums.Wound] = []
	if _body == null or not is_instance_valid(_body):
		return marks
	for kind: Enums.Wound in ORDER:
		if _body.has_scar(kind) and not _body.has_wound(kind):
			marks.append(kind)
	return marks


func _draw() -> void:
	var marks: Array[Enums.Wound] = shown()
	var old: Array[Enums.Wound] = scars_shown()
	var ink: Color = MenuStyle.tone(self, MenuStyle.TEXT)
	var faint: Color = MenuStyle.tone(self, MenuStyle.DIM)
	_draw_breath(ink, faint)
	if marks.is_empty() and old.is_empty():
		return
	var font: Font = get_theme_default_font()
	# Bottom-anchored, like the region: the last mark sits on the breath line,
	# which sits on the floor of it.
	var top: float = size.y - BREATH_ROW - ROW * float(marks.size() + old.size())
	for kind: Enums.Wound in ORDER:
		if old.has(kind):
			draw_glyph(self, kind, Rect2(0.0, top + (ROW - GLYPH) * 0.5, GLYPH, GLYPH),
				faint, STROKE * 0.75)
			top += ROW
			continue
		if not marks.has(kind):
			continue
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


## The breath line (ADR-314): the whole, faint; what is left, inked; a tick at
## the guard's minimum; and below it, the line dims and beats.
func _draw_breath(ink: Color, faint: Color) -> void:
	if _breath_shown <= 0.01 or _body == null or not is_instance_valid(_body):
		return
	var share: float = _breath()
	var whole: float = maxf(_body.stamina.maximum(), 0.001)
	var short: bool = _body.stamina.current < Config.tuning.block_stamina_minimum
	var y: float = size.y - BREATH_ROW * 0.5
	var base := Color(faint, faint.a * 0.45 * _breath_shown)
	draw_rect(Rect2(0.0, y - 1.0, BREATH_WIDTH, 2.0), base)
	var left: Color = faint if short else ink
	var beat: float = 0.55 + 0.45 * absf(sin(_beat * PI * 2.0)) if short else 1.0
	draw_rect(Rect2(0.0, y - 2.0, BREATH_WIDTH * share, 4.0),
		Color(left, left.a * beat * _breath_shown))
	var at: float = BREATH_WIDTH * clampf(Config.tuning.block_stamina_minimum / whole, 0.0, 1.0)
	draw_rect(Rect2(at - 1.0, y - 5.0, 2.0, 10.0), Color(faint, faint.a * _breath_shown))


## **Scars by where they are**, for the Chamber's row: `arm · head · leg`, or
## `none`. Places rather than wound names, because a Scar is not the wound.
static func named(bits: int) -> String:
	var places: PackedStringArray = PackedStringArray()
	for kind: Enums.Wound in ORDER:
		if (bits & (1 << kind)) != 0:
			places.append(PLACES[kind])
	return " · ".join(places) if not places.is_empty() else "none"


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
