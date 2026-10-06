class_name CarvedBox
extends Texture2D

## A tick box cut the way `CarvedFrame` cuts a panel (`M4-T05`, ADR-331).
##
## ## Why the settings' boxes could not be seen
##
## `MenuToggle` set a font and two colours and no icons, so every check box in
## the game drew the engine's own: a dark grey square on a dark ground, at
## about 1.3:1. *Invert vertical look* and *Fullscreen* read as two lines of
## text with a smudge beside them, and a box you cannot see is a setting you
## cannot tell is on.
##
## ## Geometry, not a picture of it
##
## `CarvedFrame`'s argument applies unchanged: a hard band, ground, and a mark
## inside it are three rects, so they are drawn rather than authored as a PNG
## nobody has to keep in step with the palette. The mark is a filled square,
## not a tick — a woodcut has no stroke that curves — and **on and off differ in
## shape** (a filled centre or none), never only in colour (`DES-018`).

@export var side: int = 18
@export var ground: Color = Color(0.065, 0.06, 0.055, 1.0)
@export var ink: Color = Color(0.62, 0.57, 0.5, 1.0)
@export var band: float = 2.0
## The filled centre that says *on*. Transparent draws an empty box.
@export var mark: Color = Color(0.0, 0.0, 0.0, 0.0)
## Ground left between the band and the mark.
@export var inset: float = 3.0


func _get_width() -> int:
	return side


func _get_height() -> int:
	return side


func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, _transpose: bool) -> void:
	_draw_rect(to_canvas_item, Rect2(pos, Vector2(side, side)), false, modulate, false)


func _draw_rect(to_canvas_item: RID, rect: Rect2, _tile: bool, modulate: Color,
		_transpose: bool) -> void:
	RenderingServer.canvas_item_add_rect(to_canvas_item, rect, ground * modulate)
	var tint: Color = ink * modulate
	var thick: float = minf(band, rect.size.x * 0.5)
	RenderingServer.canvas_item_add_rect(to_canvas_item,
		Rect2(rect.position, Vector2(rect.size.x, thick)), tint)
	RenderingServer.canvas_item_add_rect(to_canvas_item,
		Rect2(Vector2(rect.position.x, rect.end.y - thick), Vector2(rect.size.x, thick)), tint)
	RenderingServer.canvas_item_add_rect(to_canvas_item,
		Rect2(rect.position, Vector2(thick, rect.size.y)), tint)
	RenderingServer.canvas_item_add_rect(to_canvas_item,
		Rect2(Vector2(rect.end.x - thick, rect.position.y), Vector2(thick, rect.size.y)), tint)
	if mark.a > 0.0:
		var inner: Rect2 = rect.grow(-(thick + inset))
		if inner.size.x > 0.0 and inner.size.y > 0.0:
			RenderingServer.canvas_item_add_rect(to_canvas_item, inner, mark * modulate)


func _draw_rect_region(to_canvas_item: RID, rect: Rect2, _src_rect: Rect2,
		modulate: Color, transpose: bool, _clip_uv: bool) -> void:
	_draw_rect(to_canvas_item, rect, false, modulate, transpose)
