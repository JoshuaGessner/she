class_name Curtain
extends CanvasLayer

## **The dark between places** (B174): black falls before a scene change and
## lifts off the next place, so the second it takes to make a floor reads as a
## passage and not as the game stopping on its last frame.
##
## A descent changes scene synchronously, and making a floor takes 0.7–1.35 s
## on the development Mac (`TEC-001`) and longer on a slower one. Before this
## the throat's last frame simply froze for that long. Dark Souls covers the
## same wait with its fog-gate fade, and Barony with a black cut on the stairs.
## The curtain belongs to the scene it is in, so it is freed with it, and
## nothing has to cross the change.

## Seconds the dark takes to fall, and to lift off the next place ⟨tune⟩.
const FALL_SECONDS: float = 0.35
const LIFT_SECONDS: float = 0.5
## Above every HUD layer, so nothing the old place said shows through.
const LAYER: int = 120

var _black: ColorRect = null


func _init() -> void:
	layer = LAYER
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_black)


## Darken `over`'s screen, and return once a wholly black frame has been drawn —
## so the frame that holds while the next scene loads is the dark.
static func fall(over: Node) -> void:
	var curtain := Curtain.new()
	curtain.name = "Curtain"
	curtain._black.modulate.a = 0.0
	over.add_child(curtain)
	var tween: Tween = curtain.create_tween()
	tween.tween_property(curtain._black, "modulate:a", 1.0, FALL_SECONDS)
	await tween.finished
	# Two frames, not `frame_post_draw`: a frame has then been drawn wholly
	# black wherever anything is drawn, and nowhere can it wait for a draw that
	# never comes (a headless run never draws, and that signal never fires).
	await over.get_tree().process_frame
	await over.get_tree().process_frame


## Start `over` in the dark and let it lift, as a place arrived at.
static func lift(over: Node) -> void:
	var curtain := Curtain.new()
	curtain.name = "Curtain"
	over.add_child(curtain)
	var tween: Tween = curtain.create_tween()
	tween.tween_property(curtain._black, "modulate:a", 0.0, LIFT_SECONDS)
	tween.tween_callback(curtain.queue_free)
