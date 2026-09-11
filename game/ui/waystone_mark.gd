class_name WaystoneMark
extends Control

## **Do I still have a way out?** (`M4-T20`, `DES-019` Layer 3, ADR-212)
##
## `DES-019` gives the Burden layer one question and says it must be answerable
## in a glance: *do I still have my way out?* — binary, which only holds because
## ADR-015 caps a party at one Waystone.
##
## **ADR-186 made this the sharpest mark on the HUD.** The Shaft is the way
## *down* now, so a Waystone is the **only** extraction above the bottom floor.
## The mark stopped meaning *do I have my cheap way out* and started meaning *do
## I have a way out at all*, and unlit is a real answer with a real consequence:
## you are going to the bottom.
##
## ## Why it exists as a drawn mark rather than a line of text
##
## Until now the answer lived in two places, and neither was the HUD. It was in
## the **bag** — which `DES-019` designs as a vulnerable act, both hands in a
## satchel, so the game charged safety for an answer the design says is free —
## and in `DebugReadout`, behind a flag, as the string `waystone CARRIED`. That
## readout's own comment called itself provisional and named `M4-T05` as its
## replacement; this is that, and the debug line goes with it (ADR-064 bans the
## second path, not the first one).
##
## `GATE M4 GREED` — *a playtester voluntarily abandons loot to survive* — is a
## decision about exactly this. A player who cannot see whether they have an
## exit is not weighing greed against risk; they are guessing.
##
## ## Monochrome first (`DES-018`)
##
## The two states differ by **shape**, not by colour: carried is a **filled**
## standing stone, missing is a **hollow** one struck through. With the screen
## desaturated and the sound off, filled-versus-struck still reads, which is the
## parity `DES-018` requires from `M2` and the reason this is not a lamp that
## changes hue.
##
## No number anywhere on it (`DES-019` rule 2). There is nothing to count: the
## cap is one, so the mark is a bit and a bit has no dial.

## The stone, in units of the mark's own height, as a closed polygon: a tapered
## menhir with a rounded shoulder. Drawn rather than glyphed so it scales with
## the region and needs no font (`M4-T11` will move every size in the game).
## `static var` rather than `const`: a `PackedVector2Array` built from `Vector2`
## calls is not a constant expression, and spelling the same shape as a flat
## list of floats to satisfy that would make it unreadable for no gain.
static var STONE: PackedVector2Array = PackedVector2Array([
	Vector2(0.34, 1.00), Vector2(0.30, 0.46), Vector2(0.36, 0.22),
	Vector2(0.50, 0.12), Vector2(0.64, 0.22), Vector2(0.70, 0.46),
	Vector2(0.66, 1.00),
])
## How tall the mark stands, in pixels ⟨tune⟩. Sized against the Ear's 144 px
## square: this is the quieter of the two and should not read as an instrument.
const MARK_HEIGHT: float = 52.0
## The glyph's width as a share of its height ⟨tune⟩.
##
## The stone is drawn from its **own** proportions and not from the control's:
## `settle` gives a placed element the full width of its region, and a polygon
## scaled to that is a menhir eight times wider than it is tall.
const GLYPH_ASPECT: float = 0.72
## Line weight for the hollow state ⟨tune⟩.
const STROKE: float = 2.0


var _bag: Inventory = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## **The height the mark needs, declared rather than assigned.**
##
## `HudFrame.place` overwrites `custom_minimum_size` with the region's width and
## a height of **zero** — correct for the labels and containers it was written
## for, which grow their own height, and fatal for a drawn `Control`, whose
## `_draw` then has `size.y` of 0 and paints a line. `settle` asks
## `get_minimum_size()`, and overriding this is the one way to answer it that
## `place` cannot trample.
func _get_minimum_size() -> Vector2:
	return Vector2(MARK_HEIGHT * GLYPH_ASPECT, MARK_HEIGHT)


func _process(_delta: float) -> void:
	# By group rather than by scene order, and to `local_player` rather than to
	# any player: this is the Burden layer, and the burden is yours. The party's
	# state is Layer 4's, which is `PartyFrames`.
	if _bag == null or not is_instance_valid(_bag):
		var body := get_tree().get_first_node_in_group("local_player") as Player
		_bag = body.inventory if body != null else null
	queue_redraw()


## Whether the party's way out is in the bag.
##
## Public because the windowed shot asserts against it: a mark drawn from a
## different source than the one it claims to report would photograph correctly
## and still be a lie.
func carried() -> bool:
	return _bag != null and _bag.waystone() != null


func _draw() -> void:
	# Right-aligned inside the region, because `BURDEN` grows leftward from the
	# right edge and the mark should sit in the corner it was given rather than
	# float at the far end of a region-wide box.
	var tall: float = size.y
	var wide: float = tall * GLYPH_ASPECT
	var left: float = maxf(size.x - wide, 0.0)
	var points := PackedVector2Array()
	for unit: Vector2 in STONE:
		points.append(Vector2(left + unit.x * wide, unit.y * tall))

	if carried():
		# Filled, and in the ink of the ground it is drawn on — not gold.
		# `ART-005` spends saturated colour on treasure, and a Waystone is the
		# opposite of treasure: it is the thing that gets the treasure home.
		draw_colored_polygon(points, MenuStyle.ink())
	else:
		# Hollow and struck through. The stroke is the same stone, so the two
		# states are the same silhouette in different weights — and the bar is
		# what makes *missing* an active statement rather than a faint one.
		var outline := PackedVector2Array(points)
		outline.append(points[0])
		draw_polyline(outline, MenuStyle.dim(), STROKE)
		draw_line(Vector2(left + wide * 0.16, tall * 0.78),
			Vector2(left + wide * 0.84, tall * 0.30), MenuStyle.dim(), STROKE)
