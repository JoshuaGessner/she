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

## ## Forged (ADR-341)
##
## Reported from play: *"our UI looks too basic — it needs to be more Diablo-esque
## menus and UI elements."* The carved plate above is a hairline and a band on a
## flat fill, and at a glance it is a debug box with good manners.
##
## What makes Diablo II's and IV's frames, Grim Dawn's and Path of Exile's read
## as *made* is not their gothic — it is four properties, every one of which a
## plate can have without borrowing a single shape:
##
## - **The border has a material.** A bevel — lit on two sides, shadowed on two
##   — says *metal* before anything else is read. Ours is iron.
## - **An inlay inside it.** A fine gilt line, one step in from the metal, is
##   what turns a border into a frame. That is the existing `band`, recoloured.
## - **The corners are heavier than the edges.** Here as iron corner plates with
##   a gilt boss, and a pair of interlaced arcs — the knot every Norse mount from
##   Borre to Urnes ends in — instead of Diablo's spikes.
## - **The ground has a surface and falls into shadow at its edges**, so the
##   panel sits *under* the frame rather than beside it: hammered grain, and an
##   inner vignette.
##
## All of it stays geometry (the argument above for not being a nine-patch), and
## every part is off at its default, so a panel that wants the old plate keeps
## it. Only the theme opts in.

## Width of the forged iron border, outside the band. 0 draws none.
@export var bevel: float = 0.0
## The iron. Its lit and shadowed faces are derived from it, so one colour per
## plate is all a theme sets.
@export var metal: Color = Color(0.24, 0.21, 0.18, 1.0)
## Pressed in rather than raised: the light falls on the bottom and right. For
## sockets and wells — a slot is a hole in the plate, not a plate on it.
@export var sunken: bool = false
## How far the ground darkens toward the frame, 0–1.
@export var vignette: float = 0.0
## Hammered grain over the ground. Its alpha is the strength; transparent is none.
@export var grain: Color = Color(0.0, 0.0, 0.0, 0.0)
## Corner plates, their size in pixels. 0 draws none.
@export var plates: float = 0.0
## The gilt of the bosses, the knot and the crest.
@export var gilt: Color = Color(0.78, 0.58, 0.3, 1.0)
## A crest on the top and bottom edges, its half-width. 0 draws none.
@export var crest: float = 0.0

## ## The forged kit (ADR-386)
##
## Reported again from play: *"the simple little frames aren't doing it for
## me — a little more to them, and take reference from Diablo."* The drawn
## border above is a bevel of two flat colours, and light is what says metal:
## Diablo IV's and Grim Dawn's frames read as made because their iron catches
## light on one edge and falls into shadow on the other, their studs are
## round, their corners stand in relief. So the iron is modelled and lit once
## (`source_art/ui/build_frame_kit.py`) and rendered to a few small pieces —
## an edge strip for each side, a corner bracket for each corner, a crest —
## and this lays them. The layout stays geometry, so every panel size still
## works; only the material is a picture.
##
## Empty draws the forged or carved plate as before.
@export var kit: StringName = &""
## The crest at the top edge's middle. The large kit only.
@export var kit_crest: bool = false
## A shadow cast past the frame onto whatever is behind it, in pixels; the
## panel then sits *on* the screen rather than being printed into it.
@export var shadow: float = 0.0
## How far in from the style's rect the kit is laid, in pixels. A frame that
## fills the screen, or a button stacked against the next, has nowhere for a
## corner's outset to stand; laid this far in, the boss reaches the edge and
## no further.
@export var kit_inset: float = 0.0
## The kit's corner pieces. Off for a socket: on a slot under fifty pixels
## two brackets would bury every edge, and a well wants only its iron rim.
@export var kit_corners: bool = true

## Rendered at this many pixels per interface pixel (`build_frame_kit.py`'s
## `PX`), so a piece is drawn at half its texture's size.
const KIT_PX: float = 2.0
const KIT_PATH: String = "res://art/ui/frame/%s_%s.png"
## Band and corner, interface pixels, by kit — `frame_kit.json`'s numbers.
## `outset` is how far a corner's boss stands out past the frame: it sits on
## the corner, over it, as the reference's ornaments do.
const KIT_SIZES: Dictionary = {
	&"large": {"band": 14.0, "corner": 52.0, "outset": 9.0},
	&"small": {"band": 7.0, "corner": 20.0, "outset": 4.0},
}
static var _kit_textures: Dictionary = {}

## One texture for every plate in the game, built once. Grain is a surface,
## and a surface that changed per panel would read as different materials.
static var _grain_texture: ImageTexture = null
const GRAIN_SIZE: int = 256


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	if shadow > 0.0:
		_cast_shadow(to_canvas_item, rect)
	RenderingServer.canvas_item_add_rect(to_canvas_item, rect, ground)
	if grain.a > 0.0 or vignette > 0.0:
		_forged_ground(to_canvas_item, rect)
	if KIT_SIZES.has(kit):
		_lay_kit(to_canvas_item, rect)
		return
	# The carved plate sits inside the forged border, when there is one.
	var framed: Rect2 = rect.grow(-bevel)
	# Inside the band, so the grain never runs over the carved edge — a stroke
	# crossing the frame would read as a scratch on the screen rather than as
	# the surface of the panel.
	if hatch.a > 0.0:
		hatch_into(to_canvas_item, framed.grow(-band), hatch,
			hatch_pitch, hatch_weight)
	if bevel > 0.0:
		_forged_border(to_canvas_item, rect)
	_draw_band(to_canvas_item, framed, band, ink)
	var inner: Rect2 = framed.grow(-(band + inset))
	if inner.size.x > 0.0 and inner.size.y > 0.0:
		_draw_band(to_canvas_item, inner, hairline, edge)
	if plates > 0.0:
		_forged_corners(to_canvas_item, rect)
	else:
		_draw_corners(to_canvas_item, framed)
	if crest > 0.0:
		_forged_crest(to_canvas_item, rect)


## The minimum a frame can be and still be a frame: both lines, the gap between
## them, and a pixel of ground to put something on.
func _get_minimum_size() -> Vector2:
	if KIT_SIZES.has(kit):
		var least: float = float(KIT_SIZES[kit]["band"]) * 2.0 + 1.0
		return Vector2(least, least)
	var side: float = (bevel + band + inset + hairline) * 2.0 + 1.0
	return Vector2(side, side)


## The kit's piece `name` (`edge_top`, `corner_tl`, `crest`…), loaded once.
static func kit_piece(size: StringName, name: String) -> Texture2D:
	var key: String = "%s_%s" % [size, name]
	if not _kit_textures.has(key):
		_kit_textures[key] = load(KIT_PATH % [size, name]) as Texture2D
	return _kit_textures[key]


## The forged kit laid on `rect`: four edges tiled at their own size, an inner
## shadow where the band meets the ground, four corners over the joins, and
## the crest. Corners shrink on a panel too small for them, never overlap.
func _lay_kit(to: RID, whole: Rect2) -> void:
	var rect: Rect2 = whole.grow(-kit_inset)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var b: float = minf(float(KIT_SIZES[kit]["band"]), minf(rect.size.x, rect.size.y) * 0.5)
	var o: Vector2 = rect.position
	var e: Vector2 = rect.end
	_tile(to, Rect2(o, Vector2(rect.size.x, b)), kit_piece(kit, "edge_top"), true)
	_tile(to, Rect2(Vector2(o.x, e.y - b), Vector2(rect.size.x, b)), kit_piece(kit, "edge_bottom"), true)
	_tile(to, Rect2(o, Vector2(b, rect.size.y)), kit_piece(kit, "edge_left"), false)
	_tile(to, Rect2(Vector2(e.x - b, o.y), Vector2(b, rect.size.y)), kit_piece(kit, "edge_right"), false)
	# Where the band meets the ground the ground falls into its shadow: the
	# panel sits under the iron, not beside it.
	var inner: Rect2 = rect.grow(-b)
	if inner.size.x > 0.0 and inner.size.y > 0.0:
		var deep: float = minf(b * 0.6, minf(inner.size.x, inner.size.y) * 0.25)
		var dark := Color(0.0, 0.0, 0.0, 0.6)
		var clear := Color(0.0, 0.0, 0.0, 0.0)
		_fade(to, inner.position, Vector2(inner.end.x, inner.position.y), Vector2(0.0, deep), dark, clear)
		_fade(to, inner.position, Vector2(inner.position.x, inner.end.y), Vector2(deep, 0.0), dark, clear)
		_fade(to, Vector2(inner.position.x, inner.end.y), inner.end, Vector2(0.0, -deep * 0.5), dark, clear)
		_fade(to, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(-deep * 0.5, 0.0), dark, clear)
		# A lit state (hover, focus) says so with a gilt line inside the iron,
		# as the drawn plate's hairline did: the kit is the same in every state.
		if hairline > 0.0 and ink.a > 0.0:
			_draw_band(to, inner.grow(-1.0), hairline, ink)
	# A corner shrinks with a panel too small for it, outset and all, so two
	# never meet in the middle.
	var full: float = float(KIT_SIZES[kit]["corner"])
	var c: float = minf(full, minf(rect.size.x, rect.size.y) * 0.5)
	var m: float = float(KIT_SIZES[kit]["outset"]) * c / full
	var span := Vector2(c + m, c + m)
	for piece_at: Array in ([["corner_tl", o - Vector2(m, m)], ["corner_tr", Vector2(e.x - c, o.y - m)],
			["corner_br", e - Vector2(c, c)], ["corner_bl", Vector2(o.x - m, e.y - c)]]
			if kit_corners else []):
		var piece: Texture2D = kit_piece(kit, piece_at[0])
		if piece != null:
			RenderingServer.canvas_item_add_texture_rect(to,
				Rect2(piece_at[1] as Vector2, span), piece.get_rid())
	if kit_crest and kit == &"large":
		var crest_piece: Texture2D = kit_piece(kit, "crest")
		if crest_piece != null:
			var size: Vector2 = crest_piece.get_size() / KIT_PX
			if rect.size.x > size.x + c * 2.0:
				RenderingServer.canvas_item_add_texture_rect(to, Rect2(
					Vector2(o.x + (rect.size.x - size.x) * 0.5, o.y + b * 0.5 - size.y * 0.5),
					size), crest_piece.get_rid())


## One edge piece stamped along `rect` at its own size, the last stamp cut to
## fit: a `StyleBox` cannot set the repeat flag of the item it draws into
## (`_forged_ground` says the same of the grain).
func _tile(to: RID, rect: Rect2, piece: Texture2D, across: bool) -> void:
	if piece == null:
		return
	var step: float = (piece.get_width() if across else piece.get_height()) / KIT_PX
	var at: float = 0.0
	var length: float = rect.size.x if across else rect.size.y
	while at < length:
		var run: float = minf(step, length - at)
		var drawn: Rect2
		var source: Rect2
		if across:
			drawn = Rect2(rect.position + Vector2(at, 0.0), Vector2(run, rect.size.y))
			source = Rect2(0.0, 0.0, run * KIT_PX, piece.get_height())
		else:
			drawn = Rect2(rect.position + Vector2(0.0, at), Vector2(rect.size.x, run))
			source = Rect2(0.0, 0.0, piece.get_width(), run * KIT_PX)
		RenderingServer.canvas_item_add_texture_rect_region(to, drawn, piece.get_rid(), source)
		at += step


## A soft shadow past the frame's bottom and right, the way the light falls.
func _cast_shadow(to: RID, rect: Rect2) -> void:
	var fall := Vector2(shadow * 0.35, shadow * 0.5)
	var dark := Color(0.0, 0.0, 0.0, 0.55)
	var clear := Color(0.0, 0.0, 0.0, 0.0)
	var cast: Rect2 = Rect2(rect.position + fall, rect.size)
	_fade(to, Vector2(cast.position.x, cast.end.y), cast.end, Vector2(0.0, shadow), dark, clear)
	_fade(to, Vector2(cast.end.x, cast.position.y), cast.end, Vector2(shadow, 0.0), dark, clear)
	_fade(to, cast.position, Vector2(cast.position.x, cast.end.y), Vector2(-shadow * 0.4, 0.0), dark, clear)
	_fade(to, cast.position, Vector2(cast.end.x, cast.position.y), Vector2(0.0, -shadow * 0.4), dark, clear)


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


func _forged_ground(to: RID, rect: Rect2) -> void:
	var inner: Rect2 = rect.grow(-bevel)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return
	if grain.a > 0.0:
		var texture: ImageTexture = grain_texture()
		# Stamped at its own size, tiled by hand: a `StyleBox` cannot set the
		# repeat flag of the canvas item it draws into, and stretching a grain
		# turns hammered iron into a smear.
		var y: float = inner.position.y
		while y < inner.end.y:
			var x: float = inner.position.x
			var tall: float = minf(GRAIN_SIZE, inner.end.y - y)
			while x < inner.end.x:
				var wide: float = minf(GRAIN_SIZE, inner.end.x - x)
				RenderingServer.canvas_item_add_texture_rect_region(to,
					Rect2(x, y, wide, tall), texture.get_rid(),
					Rect2(0.0, 0.0, wide, tall), grain)
				x += GRAIN_SIZE
			y += GRAIN_SIZE
	if vignette > 0.0:
		var depth: float = minf(inner.size.x, inner.size.y) * 0.22 * vignette
		var dark := Color(0.0, 0.0, 0.0, 0.55 * minf(vignette, 1.0))
		var clear := Color(0.0, 0.0, 0.0, 0.0)
		_fade(to, inner.position, Vector2(inner.end.x, inner.position.y),
			Vector2(0.0, depth), dark, clear)
		_fade(to, Vector2(inner.position.x, inner.end.y), inner.end,
			Vector2(0.0, -depth), dark, clear)
		_fade(to, inner.position, Vector2(inner.position.x, inner.end.y),
			Vector2(depth, 0.0), dark, clear)
		_fade(to, Vector2(inner.end.x, inner.position.y), inner.end,
			Vector2(-depth, 0.0), dark, clear)


## A strip from an edge inward, dark at the edge and clear at `inward`.
func _fade(to: RID, a: Vector2, b: Vector2, inward: Vector2, dark: Color,
		clear: Color) -> void:
	RenderingServer.canvas_item_add_polygon(to,
		PackedVector2Array([a, b, b + inward, a + inward]),
		PackedColorArray([dark, dark, clear, clear]))


## The iron border: a **rod**, not a ramp. Each side is two strips meeting at a
## lit ridge, dark at both edges — the profile of a round bar, which is what
## makes a frame read as forged rather than as a bevelled button. The ridge is
## brighter on the top and left, where the light falls, and pressed in
## (`sunken`) the light falls on the far side instead. A black hairline either
## side cuts the bar from the world and from the panel it holds.
func _forged_border(to: RID, rect: Rect2) -> void:
	var w: float = minf(bevel, minf(rect.size.x, rect.size.y) * 0.5)
	var rim: Color = metal.darkened(0.45)
	var lit_ridge: Color = metal.lightened(0.5)
	var dim_ridge: Color = metal.lightened(0.12)
	if sunken:
		var swap: Color = lit_ridge
		lit_ridge = dim_ridge.darkened(0.2)
		dim_ridge = swap.darkened(0.15)
	var o: Vector2 = rect.position
	var e: Vector2 = rect.end
	var corners_out: Array[Vector2] = [o, Vector2(e.x, o.y), e, Vector2(o.x, e.y)]
	var corners_mid: Array[Vector2] = [o + Vector2(w, w) * 0.5, Vector2(e.x, o.y) + Vector2(-w, w) * 0.5,
		e - Vector2(w, w) * 0.5, Vector2(o.x, e.y) + Vector2(w, -w) * 0.5]
	var corners_in: Array[Vector2] = [o + Vector2(w, w), Vector2(e.x, o.y) + Vector2(-w, w),
		e - Vector2(w, w), Vector2(o.x, e.y) + Vector2(w, -w)]
	# Top, right, bottom, left — the first and last face the light.
	var ridges: Array[Color] = [lit_ridge, dim_ridge, dim_ridge, lit_ridge.lerp(dim_ridge, 0.3)]
	for side: int in 4:
		var a: int = side
		var b: int = (side + 1) % 4
		_shade(to, corners_out[a], corners_out[b], corners_mid[b], corners_mid[a], rim, ridges[side])
		_shade(to, corners_mid[a], corners_mid[b], corners_in[b], corners_in[a], ridges[side], rim.darkened(0.3))
	_outline(to, rect, Color(0.0, 0.0, 0.0, 0.9), 1.0)
	_outline(to, rect.grow(-w), Color(0.0, 0.0, 0.0, 0.75), 1.0)


## A quad shaded from `outer` along its first edge to `inner` along its second.
func _shade(to: RID, a: Vector2, b: Vector2, c: Vector2, d: Vector2,
		outer: Color, inner: Color) -> void:
	RenderingServer.canvas_item_add_polygon(to, PackedVector2Array([a, b, c, d]),
		PackedColorArray([outer, outer, inner, inner]))


func _outline(to: RID, rect: Rect2, tint: Color, weight: float) -> void:
	_draw_band(to, rect, weight, tint)


## **Strap hinges at the corners.** Every iron-bound thing of the period — the
## Mästermyr tool chest, the Stillingfleet and Hedared doors — holds its corners
## with flat straps that run along both edges and end in a **scroll**, riveted
## where they cross the wood. That is this game's answer to Diablo's corner
## spikes: the same job (*the corners are heavier than the edges*) in the
## material the world is made of.
##
## Each corner gets two straps over the border, a rivet at each end, a scroll
## curling inward where each strap stops, and a gilt boss over the crossing.
func _forged_corners(to: RID, rect: Rect2) -> void:
	var reach: float = minf(plates * 2.4, minf(rect.size.x, rect.size.y) * 0.42)
	var strap: float = clampf(bevel * 1.6, 3.0, plates * 0.6)
	# A small plate — a button, a chip — keeps only the boss: straps on
	# something forty pixels tall are clutter, not furniture.
	var straps: bool = plates >= 14.0 and reach >= strap * 3.0
	for corner_at: Vector2 in [Vector2(0.0, 0.0), Vector2(1.0, 0.0),
			Vector2(0.0, 1.0), Vector2(1.0, 1.0)]:
		var inward := Vector2(1.0 - corner_at.x * 2.0, 1.0 - corner_at.y * 2.0)
		var c := Vector2(rect.position.x + rect.size.x * corner_at.x,
			rect.position.y + rect.size.y * corner_at.y)
		# Along x, then along y.
		for along: Vector2 in ([Vector2(inward.x, 0.0), Vector2(0.0, inward.y)] if straps else []):
			var across := Vector2(absf(along.y) * inward.x, absf(along.x) * inward.y)
			var a: Vector2 = c
			var b: Vector2 = c + along * reach
			var lit: bool = along.x != 0.0 and inward.y > 0.0 or along.y != 0.0 and inward.x > 0.0
			_strap(to, a, b, across * strap, lit)
			# The strap ends in a spear-point, the commonest terminal on period
			# ironwork after the scroll, and the one that stays legible small.
			_tip(to, b, along, across * strap)
			_rivet(to, c + across * strap * 0.5 + along * reach * 0.6, strap * 0.24)
		# The boss over the crossing.
		var centre: Vector2 = c + inward * strap * 0.5
		var r: float = strap * (0.8 if straps else 0.65)
		var diamond := PackedVector2Array([centre + Vector2(0.0, -r),
			centre + Vector2(r, 0.0), centre + Vector2(0.0, r), centre + Vector2(-r, 0.0)])
		RenderingServer.canvas_item_add_polygon(to, diamond, PackedColorArray([gilt.darkened(0.15)]))
		RenderingServer.canvas_item_add_polygon(to, PackedVector2Array([
			centre + Vector2(0.0, -r), centre + Vector2(r, 0.0), centre, centre + Vector2(-r, 0.0)]),
			PackedColorArray([gilt.lightened(0.25)]))
		RenderingServer.canvas_item_add_polyline(to, diamond + PackedVector2Array(
			[centre + Vector2(0.0, -r)]), PackedColorArray([Color(0.0, 0.0, 0.0, 0.85)]), 1.0)


## One flat strap from `a` to `b`, `width` thick toward the panel: lit along
## the edge that faces the light, dark along the other, outlined.
func _strap(to: RID, a: Vector2, b: Vector2, width: Vector2, lit: bool) -> void:
	# Bronzed toward the gilt, so a strap reads as laid *over* the rod rather
	# than as more of it.
	var bronze: Color = metal.lerp(gilt, 0.3)
	var near: Color = bronze.lightened(0.38 if lit else 0.08)
	var far: Color = bronze.darkened(0.3 if lit else 0.45)
	_shade(to, a, b, b + width, a + width, near, far)
	var outline := PackedVector2Array([a, b, b + width, a + width, a])
	RenderingServer.canvas_item_add_polyline(to, outline,
		PackedColorArray([Color(0.0, 0.0, 0.0, 0.85)]), 1.0)


## A strap's spear-point: a lozenge that runs on past the strap's end and
## narrows to a point, outlined dark so it stands off the rod beneath it.
func _tip(to: RID, at: Vector2, along: Vector2, width: Vector2) -> void:
	var span: float = width.length()
	var side: Vector2 = width / maxf(span, 0.001)
	var shape := PackedVector2Array([
		at,
		at + along * span * 0.45 - side * span * 0.3,
		at + along * span * 1.6 + side * span * 0.5,
		at + along * span * 0.45 + side * span * 1.3,
		at + width])
	var bronze: Color = metal.lerp(gilt, 0.3)
	RenderingServer.canvas_item_add_polygon(to, shape, PackedColorArray([bronze.lightened(0.15)]))
	RenderingServer.canvas_item_add_polyline(to, shape + PackedVector2Array([at]),
		PackedColorArray([Color(0.0, 0.0, 0.0, 0.85)]), 1.0)


## A rivet head: gilt, with a lit point.
func _rivet(to: RID, at: Vector2, radius: float) -> void:
	var r: float = maxf(1.2, radius)
	RenderingServer.canvas_item_add_circle(to, at, r + 0.8, Color(0.0, 0.0, 0.0, 0.8))
	RenderingServer.canvas_item_add_circle(to, at, r, gilt.darkened(0.1))
	RenderingServer.canvas_item_add_circle(to, at - Vector2(r, r) * 0.3, r * 0.4, gilt.lightened(0.45))


## **A crest** at the middle of the top and bottom edges: a gilt lozenge with a
## bar to either side, where a Diablo frame puts its keystone and an Urnes
## brooch its mask. Marks a panel as a title plate rather than a well.
func _forged_crest(to: RID, rect: Rect2) -> void:
	var half: float = minf(crest, rect.size.x * 0.25)
	if half < 4.0:
		return
	for y: float in [rect.position.y + bevel * 0.5, rect.end.y - bevel * 0.5]:
		var centre := Vector2(rect.get_center().x, y)
		var r: float = maxf(bevel * 0.9, 5.0)
		var bar: float = maxf(2.0, bevel * 0.4)
		RenderingServer.canvas_item_add_rect(to,
			Rect2(centre - Vector2(half, bar * 0.5), Vector2(half * 2.0, bar)), gilt.darkened(0.25))
		var diamond := PackedVector2Array([centre + Vector2(0.0, -r),
			centre + Vector2(r * 1.4, 0.0), centre + Vector2(0.0, r), centre + Vector2(-r * 1.4, 0.0)])
		RenderingServer.canvas_item_add_polygon(to, diamond, PackedColorArray([gilt]))
		RenderingServer.canvas_item_add_polyline(to, diamond + PackedVector2Array(
			[centre + Vector2(0.0, -r)]), PackedColorArray([Color(0.0, 0.0, 0.0, 0.8)]), 1.0)


## The shared grain: two octaves of value noise, hammered rather than cloudy,
## as luminance-alpha so a theme tints it with a single colour.
static func grain_texture() -> ImageTexture:
	if _grain_texture != null:
		return _grain_texture
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.045
	noise.seed = 9
	var fine := FastNoiseLite.new()
	fine.noise_type = FastNoiseLite.TYPE_VALUE
	fine.frequency = 0.35
	fine.seed = 4
	# Seamless, because the grain is stamped in tiles and a seam every 256 px
	# would read as a joint in the metal.
	var dents: Image = noise.get_seamless_image(GRAIN_SIZE, GRAIN_SIZE, false, false, 0.2, true)
	var specks: Image = fine.get_seamless_image(GRAIN_SIZE, GRAIN_SIZE, false, false, 0.2, true)
	var image := Image.create_empty(GRAIN_SIZE, GRAIN_SIZE, false, Image.FORMAT_LA8)
	for y: int in GRAIN_SIZE:
		for x: int in GRAIN_SIZE:
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(
				dents.get_pixel(x, y).r * 0.65 + specks.get_pixel(x, y).r * 0.35, 0.0, 1.0)))
	_grain_texture = ImageTexture.create_from_image(image)
	return _grain_texture
