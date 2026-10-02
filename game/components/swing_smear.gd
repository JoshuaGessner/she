class_name SwingSmear
extends MeshInstance3D

## **The arc a blow travelled, drawn behind the blade for an instant** (ADR-303).
##
## A strike is ⟨tune⟩ at around a fifth of a second, and a first-person blade
## crosses most of the view in it — so it reads as a jump from one pose to the
## next rather than as a swing. Every first-person melee game that reads well
## draws the smear: a ribbon from the blade's middle to its tip over the last
## few hundredths of a second, *Dark Messiah*'s and *Chivalry*'s most of all.
##
## **Opaque, and it narrows instead of fading.** The ink pass paints over
## anything blended, so the ribbon's old end tapers to the blade's middle
## rather than going transparent, and it stands on `BARE`, so no line is drawn
## round a smear. Pale, unshaded, value only (ART-005).
##
## World space (`top_level`), so it stays where the blade *was* while the blade
## moves on; that is what makes it a trail.

## How long a stretch of the arc stays drawn, seconds ⟨tune⟩.
const KEEP: float = 0.085
const COLOUR: Color = Color(0.92, 0.90, 0.84)

var _samples: Array[Array] = []   # [inner: Vector3, outer: Vector3, age: float]
var _strip := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	# A node made top-level keeps the global transform it had — the blade's —
	# and the samples are already in world space, so it must sit at the origin.
	global_transform = Transform3D.IDENTITY
	mesh = _strip
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.albedo_color = COLOUR
	InkPass.stamp(paint, InkPass.Class.BARE)
	material_override = paint


## Record where the blade's middle and tip are this frame.
##
## Drawn at once rather than at the next frame: the strike is a handful of
## physics ticks, and when a frame runs long they all arrive between two draws.
func sample(inner: Vector3, outer: Vector3) -> void:
	_samples.append([inner, outer, 0.0])
	_draw_strip()


## How many stretches of arc are drawn, for `--feel-probe`.
func drawn() -> int:
	return maxi(0, _samples.size() - 1)


func _process(delta: float) -> void:
	for row: Array in _samples:
		row[2] = float(row[2]) + delta
	while not _samples.is_empty() and float(_samples[0][2]) > KEEP:
		_samples.pop_front()
	_draw_strip()


func _draw_strip() -> void:
	# Held at the origin every draw: a parent moving does not move a top-level
	# node, but a reparent or a teleport would.
	global_transform = Transform3D.IDENTITY
	_strip.clear_surfaces()
	if _samples.size() < 2:
		return
	_strip.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for row: Array in _samples:
		# Narrowed toward the blade's middle as it ages: full width when new,
		# a sliver at the end of `KEEP`.
		var width: float = 1.0 - clampf(float(row[2]) / KEEP, 0.0, 1.0)
		var inner: Vector3 = row[0]
		var outer: Vector3 = row[1]
		var middle: Vector3 = inner.lerp(outer, 0.5)
		_strip.surface_add_vertex(middle.lerp(inner, width))
		_strip.surface_add_vertex(middle.lerp(outer, width))
	_strip.surface_end()
