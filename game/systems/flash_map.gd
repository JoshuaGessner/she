class_name FlashMap
extends RefCounted

## **Where a view flashes** (ADR-297) — the same view turned a tenth of a
## degree, compared.
##
## A flicker is something seen while moving, so a still photograph never shows
## one. The camera is **turned**, not stepped: a turn this small moves every
## pixel about one place whatever its depth, so a wall a metre away does not
## light up for its parallax, while two faces fighting over one plane still
## swap whole runs of pixels — their depths are re-rasterised either way. A
## pixel counts when it differs from the turned frame at the same place *and* at
## every neighbour within two pixels, and what counts is painted red over a
## dimmed copy of the view. The caller pauses the world first, so a flame or a
## flickering lamp is not counted either.
##
## A tool rather than an assertion: the number is read alongside the map.

## How far one frame has to differ from the other, in luminance, to count.
const SWAP: float = 0.18
## How far the camera is turned about its own up, radians.
const TURN: float = 0.0017


## The share of `still` that changed past what a step explains, with the map
## of where saved to `path`.
static func measure(still: Image, stepped: Image, path: String) -> float:
	var size: Vector2i = still.get_size()
	var map := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	var flashing: int = 0
	for y: int in range(2, size.y - 2):
		for x: int in range(2, size.x - 2):
			var here: Color = still.get_pixel(x, y)
			var nearest: float = INF
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					var there: Color = stepped.get_pixel(x + dx, y + dy)
					nearest = minf(nearest, absf(here.get_luminance() - there.get_luminance()))
			var shown: Color = here.darkened(0.6)
			if nearest > SWAP:
				flashing += 1
				shown = Color(1.0, 0.1, 0.1)
			map.set_pixel(x, y, shown)
	map.save_png(path)
	return float(flashing) / float(size.x * size.y)
