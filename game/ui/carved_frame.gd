class_name CarvedFrame
extends StyleBox

## A panel drawn as a carved plate rather than a filled rectangle
## (`M4-T05`, `ART-005`).
##
## ## Why this is not a `StyleBoxFlat`
##
## Every panel in the game was a one-pixel border around a flat fill, which is
## the default look of any engine's UI and reads as a debug overlay left on.
## `StyleBoxFlat` cannot express what replaces it: it has **one** border, and
## the thing that makes a frame read as *made* is a second line inside the
## first with ground showing between them, plus corners heavier than the edges
## they meet at.
##
## The reference is Darkest Dungeon — heavy frames, corner furniture, grim
## ground — and it lands here without a style argument because `ART-005`
## already commits the whole game to **printmaking**. A Darkest Dungeon panel
## and a woodcut plate are the same object seen twice: a hard carved edge, no
## gradient, no radius, and register marks at the corners where the cutter
## squared the block. So this is not a skin borrowed from another game; it is
## the interface finally agreeing with the world it floats over.
##
## **Square, always.** `MenuStyle` already states the rule — *a carved line has
## no radius* — so there is no corner-radius property here to set wrongly.
##
## ## The hatch is the texture, and it is the cheapest thing on this page
##
## A flat fill is what "our UI is too basic" actually means: a panel with no
## surface. `ART-005` gets value from **hatching, not gradients**, and gives
## paper and grain to *screen space* — fixed in front of you, because a page
## genuinely is. A panel is a page, so its grain is fixed to the panel and
## drawn here rather than sampled from a texture nobody has authored yet.
##
## At `hatch.a = 0` it costs one comparison, so a panel that wants a clean
## ground simply leaves it out.
##
## ## No art was skipped to build this
##
## This is not blockout standing in for a nine-patch (ADR-046, ADR-064). A
## carved frame *is* the final treatment for a woodcut interface — `M4-T10`
## may replace the ground with an authored paper texture, and the geometry of
## the plate stays exactly this, because it is geometry rather than a picture
## of geometry. It also survives every window size for free, which an authored
## nine-patch does not.

## The surface. Alpha is load-bearing: a readout floating over a live room is
## translucent, and a screen you are working inside is not.
@export var ground: Color = Color(0.09, 0.085, 0.08, 0.93)
## The carved edge and the corner furniture.
@export var ink: Color = Color(0.44, 0.40, 0.34, 1.0)
## The second line, inside the first. Quieter than `ink` on purpose — two lines
## of equal weight read as a mistake, one heavy and one fine reads as a bevel.
@export var edge: Color = Color(0.28, 0.26, 0.24, 1.0)
## The grain over the ground. Transparent means none.
@export var hatch: Color = Color(0.0, 0.0, 0.0, 0.0)

@export var band: float = 3.0
## Ground left showing between the band and the hairline. This gap is the whole
## effect; at 0 the two lines merge into one thick border.
@export var inset: float = 3.0
@export var hairline: float = 1.0
## How far the heavy corner runs along each edge it meets. 0 draws none, which
## is right for anything small enough that four corners would meet in the
## middle — a 44 px inventory cell has no room for furniture.
@export var corner: float = 14.0
@export var corner_weight: float = 3.0
## Distance between hatch strokes, in pixels, measured perpendicular to nothing
## in particular — they run at 45°, so this is the step along the x axis.
@export var hatch_pitch: float = 9.0
@export var hatch_weight: float = 1.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	RenderingServer.canvas_item_add_rect(to_canvas_item, rect, ground)
	# Inside the band, so the grain never runs over the carved edge — a stroke
	# crossing the frame would read as a scratch on the screen rather than as
	# the surface of the panel.
	if hatch.a > 0.0:
		hatch_into(to_canvas_item, rect.grow(-band), hatch,
			hatch_pitch, hatch_weight)
	_draw_band(to_canvas_item, rect, band, ink)
	var inner: Rect2 = rect.grow(-(band + inset))
	if inner.size.x > 0.0 and inner.size.y > 0.0:
		_draw_band(to_canvas_item, inner, hairline, edge)
	_draw_corners(to_canvas_item, rect)


## The minimum a frame can be and still be a frame: both lines, the gap between
## them, and a pixel of ground to put something on.
func _get_minimum_size() -> Vector2:
	var side: float = (band + inset + hairline) * 2.0 + 1.0
	return Vector2(side, side)


## Four rects rather than a rect with a border, because the border has to be
## able to differ from the fill's alpha — the ground under a readout is
## see-through and its edge is not.
func _draw_band(to: RID, rect: Rect2, weight: float, tint: Color) -> void:
	if weight <= 0.0 or tint.a <= 0.0:
		return
	var thick: float = minf(weight, minf(rect.size.x, rect.size.y) * 0.5)
	RenderingServer.canvas_item_add_rect(to,
		Rect2(rect.position, Vector2(rect.size.x, thick)), tint)
	RenderingServer.canvas_item_add_rect(to,
		Rect2(Vector2(rect.position.x, rect.end.y - thick),
			Vector2(rect.size.x, thick)), tint)
	var tall: float = rect.size.y - thick * 2.0
	if tall <= 0.0:
		return
	RenderingServer.canvas_item_add_rect(to,
		Rect2(Vector2(rect.position.x, rect.position.y + thick),
			Vector2(thick, tall)), tint)
	RenderingServer.canvas_item_add_rect(to,
		Rect2(Vector2(rect.end.x - thick, rect.position.y + thick),
			Vector2(thick, tall)), tint)


## The register marks. Drawn over the band rather than beside it, so a corner
## is simply the same edge carried deeper — which is what a cut corner looks
## like, and what stops four separate lines reading as four separate lines.
func _draw_corners(to: RID, rect: Rect2) -> void:
	if corner <= 0.0 or corner_weight <= 0.0 or ink.a <= 0.0:
		return
	# Two corners meeting in the middle is not furniture, it is a filled edge.
	var run: float = minf(corner, minf(rect.size.x, rect.size.y) * 0.4)
	var thick: float = minf(corner_weight, minf(rect.size.x, rect.size.y) * 0.5)
	for along: Vector2 in [Vector2(0.0, 0.0), Vector2(1.0, 0.0),
			Vector2(0.0, 1.0), Vector2(1.0, 1.0)]:
		var at := Vector2(
			rect.position.x + (rect.size.x - run) * along.x,
			rect.position.y + (rect.size.y - thick) * along.y)
		RenderingServer.canvas_item_add_rect(to,
			Rect2(at, Vector2(run, thick)), ink)
		at = Vector2(
			rect.position.x + (rect.size.x - thick) * along.x,
			rect.position.y + (rect.size.y - run) * along.y)
		RenderingServer.canvas_item_add_rect(to,
			Rect2(at, Vector2(thick, run)), ink)


## Diagonal strokes at 45°, clipped to the rect analytically rather than by
## drawing long lines and letting something else cut them — a `StyleBox` draws
## into a canvas item it does not own and cannot set a clip on it.
##
## Anchored to a multiple of the pitch in panel space, so the grain does not
## crawl when a panel changes size by a pixel.
##
## **Static, because a panel is not the only thing with a surface.** `ART-005`
## makes hatching the way this game expresses value, so anything that wants to
## say *more than full* or *not available* says it in strokes rather than in a
## second colour — which is also what `DES-018` demands, since a hue nobody can
## distinguish is not a signal. One implementation, so a hatch drawn on a load
## bar is the same mark as the grain on the panel under it.
static func hatch_into(to: RID, rect: Rect2, tint: Color, pitch: float,
		weight: float) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0 or pitch <= 0.0 or tint.a <= 0.0:
		return
	# A stroke is the set of points where x - y is constant; every stroke that
	# touches the rect at all has that constant between these two bounds.
	var first: float = rect.position.x - rect.end.y
	var last: float = rect.end.x - rect.position.y
	var step: float = ceilf(first / pitch) * pitch
	while step < last:
		var top: float = maxf(rect.position.y, rect.position.x - step)
		var bottom: float = minf(rect.end.y, rect.end.x - step)
		if bottom > top:
			RenderingServer.canvas_item_add_line(to,
				Vector2(top + step, top), Vector2(bottom + step, bottom),
				tint, weight)
		step += pitch
