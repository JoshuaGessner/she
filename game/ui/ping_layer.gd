class_name PingLayer
extends Control

## **Where the party's marks are, drawn** (`M4-T05`, ADR-244, `DES-012`).
##
## One mark a player, over the thing it marks, and when that thing is behind you
## or off the screen, an arrow at the edge pointing the way — by the developer's
## call, because a mark you cannot see is a word nobody heard. Gone after
## `ping_seconds`, fading for the last of them.
##
## **Shape says what it is, never hue alone** (`DES-018`): a ring is a spot, a
## diamond is loot, a downward wedge is an enemy, a raised chevron is the way,
## and the four gestures are an arrow, a bar, a warning triangle and a ring of
## dots. Colour only reinforces — the two that mean *look out* are warm.
##
## Draws what every `Pinger` on this peer holds; it owns nothing and decides
## nothing, so it is the same on every peer by construction.

## Half the size of a mark, in pixels ⟨tune⟩.
const SIZE: float = 10.0
## How far inside the screen an edge arrow stands.
const EDGE: float = HudFrame.MARGIN + 18.0
## The gesture wheel's radius.
const WHEEL_RADIUS: float = 78.0
## Seconds over which a mark fades out at the end of its life.
const FADE_SECONDS: float = 1.5
## Metres in front of the eye below which a point is not projected.
const NEAR: float = 0.1
const WHEEL_WORDS: Dictionary = {
	Pinger.Kind.GO: "go", Pinger.Kind.DANGER: "danger",
	Pinger.Kind.STOP: "stop", Pinger.Kind.REGROUP: "regroup",
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var eye: Camera3D = get_viewport().get_camera_3d()
	var screen: Vector2 = get_viewport_rect().size
	if eye != null:
		for node: Node in get_tree().get_nodes_in_group(Pinger.GROUP):
			var pinger := node as Pinger
			if pinger == null or pinger.mark.is_empty():
				continue
			# Your own gesture stands over your own head: it is for the others,
			# and the wheel already showed you what you said.
			if int(pinger.mark["kind"]) >= Pinger.Kind.GO and _who(pinger) == "":
				continue
			var placed: Dictionary = place(eye, pinger.mark_position(), screen)
			var fade: float = clampf(float(pinger.mark["left"]) / FADE_SECONDS, 0.0, 1.0)
			var kind: int = int(pinger.mark["kind"])
			var ink: Color = _ink(kind)
			ink.a = fade
			var at: Vector2 = placed["at"]
			_shape(kind, at, SIZE, ink)
			if bool(placed["edge"]):
				var way: Vector2 = placed["toward"]
				var tip: Vector2 = at + way * (SIZE + 10.0)
				var side: Vector2 = way.orthogonal() * 5.0
				draw_colored_polygon(PackedVector2Array([
					tip, tip - way * 8.0 + side, tip - way * 8.0 - side]), ink)
			var who: String = _who(pinger)
			if who != "":
				# Under the mark — or, at the edge, on the side away from the
				# arrow, which would otherwise draw through the name.
				var below: Vector2 = Vector2(0.0, SIZE + 14.0)
				if bool(placed["edge"]) and (placed["toward"] as Vector2).y > 0.5:
					below = Vector2(0.0, -SIZE - 6.0)
				var font: Font = get_theme_default_font()
				draw_string(font, at + below + Vector2(-40.0, 0.0), who,
					HORIZONTAL_ALIGNMENT_CENTER, 80.0, 11, ink)
	var local := _local_pinger()
	if local != null and local.wheel_open:
		_wheel(screen * 0.5, local.aimed())


## **Where a mark goes on this screen**: `at`, whether it is pinned to the edge,
## and which way it points from the centre. Public, and static, for the probe
## that asks whether a mark behind you points behind you.
static func place(eye: Camera3D, world: Vector3, screen: Vector2) -> Dictionary:
	var centre: Vector2 = screen * 0.5
	var basis: Basis = eye.global_transform.basis
	var offset: Vector3 = world - eye.global_position
	# Never a negative size — a headless viewport is 73 px wide, and `HudFrame`
	# learned this first.
	var inner := Rect2(Vector2(EDGE, EDGE),
		(screen - Vector2(EDGE, EDGE) * 2.0).max(Vector2.ZERO))
	# **In front by a margin, or not projected at all.** A point on the camera's
	# own plane — a gesture over your own head — has no projection, and asking
	# for one fails every frame; a point behind has a mirrored one. Both are
	# pointed at along the camera's own right and up instead.
	var toward := Vector2(offset.dot(basis.x), -offset.dot(basis.y))
	if offset.dot(-basis.z) > NEAR:
		# Projected into the camera's own viewport, then carried to `screen` —
		# the same size when drawing, a declared one when a probe asks headless.
		var view: Vector2 = eye.get_viewport().get_visible_rect().size
		var point: Vector2 = eye.unproject_position(world) * (screen / view.max(Vector2.ONE))
		if inner.has_point(point):
			return {"at": point, "edge": false, "toward": Vector2.ZERO}
		toward = point - centre
	if toward.length() < 0.001:
		toward = Vector2.DOWN
	toward = toward.normalized()
	# Out along the direction until the first inner edge is met.
	var half: Vector2 = inner.size * 0.5
	var reach: float = minf(
		half.x / maxf(absf(toward.x), 0.0001),
		half.y / maxf(absf(toward.y), 0.0001))
	return {"at": centre + toward * reach, "edge": true, "toward": toward}


## The shape for a kind, at a point.
func _shape(kind: int, at: Vector2, r: float, ink: Color) -> void:
	var dark := Color(0.05, 0.05, 0.05, ink.a * 0.8)
	match kind:
		Pinger.Kind.SPOT:
			draw_arc(at, r, 0.0, TAU, 20, dark, 4.0)
			draw_arc(at, r, 0.0, TAU, 20, ink, 2.0)
			draw_circle(at, 2.5, ink)
		Pinger.Kind.LOOT:
			var diamond := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0),
				at + Vector2(0, r), at + Vector2(-r, 0)])
			draw_colored_polygon(diamond, dark)
			draw_polyline(_closed(diamond), ink, 2.0)
		Pinger.Kind.ENEMY:
			var wedge := PackedVector2Array([at + Vector2(-r, -r * 0.7),
				at + Vector2(r, -r * 0.7), at + Vector2(0, r)])
			draw_colored_polygon(wedge, ink)
			draw_polyline(_closed(wedge), dark, 1.5)
		Pinger.Kind.WAY:
			for step: int in 2:
				var y: float = r * 0.4 - float(step) * r * 0.8
				draw_polyline(PackedVector2Array([at + Vector2(-r, y + r * 0.5),
					at + Vector2(0, y - r * 0.3), at + Vector2(r, y + r * 0.5)]), ink, 3.0)
		Pinger.Kind.GO:
			var arrow := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0),
				at + Vector2(r * 0.35, 0), at + Vector2(r * 0.35, r),
				at + Vector2(-r * 0.35, r), at + Vector2(-r * 0.35, 0), at + Vector2(-r, 0)])
			draw_colored_polygon(arrow, ink)
		Pinger.Kind.STOP:
			draw_rect(Rect2(at - Vector2(r, r * 0.4), Vector2(r * 2.0, r * 0.8)), ink)
			draw_rect(Rect2(at - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), ink, false, 2.0)
		Pinger.Kind.DANGER:
			var warn := PackedVector2Array([at + Vector2(0, -r * 1.1),
				at + Vector2(r * 1.1, r * 0.9), at + Vector2(-r * 1.1, r * 0.9)])
			draw_colored_polygon(warn, dark)
			draw_polyline(_closed(warn), ink, 2.0)
			draw_line(at + Vector2(0, -r * 0.45), at + Vector2(0, r * 0.2), ink, 2.0)
			draw_circle(at + Vector2(0, r * 0.55), 1.5, ink)
		Pinger.Kind.REGROUP:
			for dot: int in 4:
				var angle: float = TAU * float(dot) / 4.0 + PI * 0.25
				draw_circle(at + Vector2(cos(angle), sin(angle)) * r * 0.8, r * 0.3, ink)


## The four gestures around the middle of the screen, the aimed one lit.
func _wheel(centre: Vector2, aimed: int) -> void:
	var font: Font = get_theme_default_font()
	var dim: Color = MenuStyle.tone(self, MenuStyle.DIM)
	# A dark ground under it, so the four words read over a lit floor as well
	# as a black one.
	draw_circle(centre, WHEEL_RADIUS + 40.0, Color(0.0, 0.0, 0.0, 0.45))
	draw_arc(centre, WHEEL_RADIUS, 0.0, TAU, 48, Color(dim, 0.5), 1.5)
	for slot: int in Pinger.WHEEL.size():
		var kind: int = Pinger.WHEEL[slot]
		# Up, right, down, left — the order `Pinger.gesture_for` reads.
		var angle: float = -PI * 0.5 + TAU * float(slot) / 4.0
		var at: Vector2 = centre + Vector2(cos(angle), sin(angle)) * WHEEL_RADIUS
		var chosen: bool = kind == aimed
		var ink: Color = _ink(kind) if chosen else dim
		_shape(kind, at, SIZE * (1.5 if chosen else 1.1), ink)
		draw_string(font, at + Vector2(-40.0, SIZE * 2.0 + 10.0), WHEEL_WORDS[kind],
			HORIZONTAL_ALIGNMENT_CENTER, 80.0, 13 if chosen else 11, ink)


func _ink(kind: int) -> Color:
	if kind == Pinger.Kind.ENEMY or kind == Pinger.Kind.DANGER:
		return MenuStyle.tone(self, MenuStyle.WARM)
	return MenuStyle.tone(self, MenuStyle.TEXT)


## Whose mark, for anyone's but yours.
func _who(pinger: Pinger) -> String:
	var body: Node3D = pinger.owner_body()
	if body == null or body.is_in_group(&"local_player"):
		return ""
	return String(body.name)


func _local_pinger() -> Pinger:
	var body := get_tree().get_first_node_in_group(&"local_player") as Player
	return body.pinger if body != null else null


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = points.duplicate()
	out.append(points[0])
	return out
