class_name ArrivalBrief
extends Control

## What you are here for, said once on arrival (`M2-T14`, ADR-106).
##
## The Deep told the player nothing. Not the objective, not the verbs, not that
## there was a way out — a playtester descended, walked the floor, and reported
## that the demo *"doesn't feel very direct in what I'm supposed to do."* They
## were right, and it was not a tuning problem: **nothing anywhere in the level
## stated the goal.** Every system was built and probed; none of them introduced
## itself.
##
## ## Three lines, once, then gone
##
## `DES-019` is hostile to persistent UI and `ART-002` wants the interface
## minimal, so this is not a quest log and does not stay on screen. It is the
## opening title of a run: the place, what you are here to do, and how to leave.
## It fades on its own and never returns, which is the same contract the
## Threshold's own readout has — say it where the player is not yet under
## pressure, and then get out of the way.
##
## Deliberately **not** a tutorial. `M5-T05` owns onboarding and the first hour;
## this is the one-screen brief every mission-structured game opens with, from
## Thief's parchment to a Hunt: Showdown contract card. Teaching the verbs in
## situ is a different job with a different budget.

const HOLD_SECONDS: float = 4.5   # ⟨tune⟩
const FADE_SECONDS: float = 1.2   # ⟨tune⟩

var _lines: VBoxContainer
var _elapsed: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_lines = VBoxContainer.new()
	_lines.alignment = BoxContainer.ALIGNMENT_CENTER
	_lines.add_theme_constant_override("separation", 6)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lines)

	# The place, then the job, then the way home — in the order a person needs
	# them. "Climb out at the light" is doing the most work here: it names the
	# beacon as the exit, so the tall pale column stops being scenery the moment
	# the player first sees one.
	_line("THE DEEP", 21, MenuStyle.WARM)
	_line("take what you can carry", 15, MenuStyle.TEXT)
	_line("climb out at the light — it is loud, and it is watched", 15,
		MenuStyle.TEXT)


func _line(text: String, size: int, colour: Color) -> void:
	var label: Label = MenuStyle.line(text, size, colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines.add_child(label)


func _process(delta: float) -> void:
	_elapsed += delta
	# Positioned every frame rather than anchored: a `Control` under a
	# `CanvasLayer` gets no laid-out size from anchors, which is the bug the Ear
	# shipped with and the Reticle's comment already warns about.
	var screen: Vector2 = get_viewport_rect().size
	_lines.position = Vector2(screen.x * 0.5 - _lines.size.x * 0.5,
		screen.y * 0.34)
	if _elapsed < HOLD_SECONDS:
		return
	var fading: float = (_elapsed - HOLD_SECONDS) / FADE_SECONDS
	modulate.a = 1.0 - clampf(fading, 0.0, 1.0)
	if fading >= 1.0:
		# Freed rather than hidden. It has said its piece and will never say it
		# again this run, so leaving it in the tree is a node that exists to do
		# nothing — which is the shape ADR-098 spent a milestone removing.
		queue_free()
