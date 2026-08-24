class_name Reticle
extends Control

## A dot, and the name of what you could take.
##
## The player already knew all of this — `Player._reaching_for` has held the
## item you would pick up since `M2-T01` — and nothing drew it. So a tester
## walks over a floor covered in loot with no way to tell what is reachable
## except pressing the key and seeing whether anything happened, and every
## report about "the pickup feels unreliable" is really a report about this.
##
## ## Deliberately almost nothing
##
## `ART-002` and `DES-018` both want the interface minimal — there are no
## stingers, no damage numbers, no floating markers over things. A first-person
## game still needs a centre, because a melee arc and a reach both start from
## where you are looking, and *"I swung and it did not connect"* is unanswerable
## without one.
##
## So: a dot that grows a little when something is in reach, and one line of
## text naming it. Nothing else. It is deliberately not a highlight on the
## object itself — `ART-005` reserves saturated colour for treasure, and an
## outline shader that made everything glow would spend the game's one loud
## colour on interface.

const DOT: float = 2.0
const REACH_DOT: float = 3.4
const GROW: float = 12.0

## Radius of the channel ring, outside the reach ticks so the two never sit on
## top of each other.
const RING: float = 26.0
const RING_SEGMENTS: int = 48

var _body: Player = null
var _shaft: Shaft = null
var _grown: float = 0.0
var _name: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_name = MenuStyle.line("", 15, MenuStyle.TEXT)
	_name.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)


## **A body that has left the tree is not a body to read** (`M2-T16`, ADR-108).
##
## The guard here was `is_instance_valid`, which keeps answering true for a node
## that has been removed from the tree and not yet freed — the state a despawn
## passes through. Walking into your Chamber as a client despawns your camp
## body, and for that frame this asked it for `global_position` and then handed
## it to `Shaft.nearest`, which calls `get_tree()` on it: two engine errors and
## a `SCRIPT ERROR`, inside a check that was passing.
##
## `is_inside_tree()` is the question that was actually meant. It implies
## validity, so it replaces the test rather than joining it.
func _body_to_read() -> Player:
	if _body != null and is_instance_valid(_body) and _body.is_inside_tree():
		return _body
	_body = _local_body()
	return _body


func _process(delta: float) -> void:
	_body = _body_to_read()
	var reaching: WorldItem = null
	var hidden: bool = true
	_shaft = null
	if _body != null:
		reaching = _body.reaching_for()
		_shaft = _body.shaft_underfoot()
		# Gone while the bag is open: you are looking into a satchel, not down
		# a corridor, and `DES-019` wants that to feel like a different posture.
		hidden = _body.bag_is_open() or _body.is_incapacitated()

	var wanted: float = 1.0 if reaching != null or _shaft != null else 0.0
	_grown = move_toward(_grown, wanted, delta * 6.0)
	visible = not hidden
	# **The way out speaks first.** Standing in the Shaft while looking at a
	# coin, the thing worth saying is that you are standing in the way out —
	# and `DES-005` makes leaving the decision the whole floor is about.
	if _shaft != null:
		_name.text = ("climbing out — hold still" if _shaft.is_channelling()
			else "hold E — climb out")
	else:
		_name.text = "" if reaching == null or reaching.definition() == null \
			else reaching.definition().display()
	# Below the dot rather than beside it, so a long item name does not drag
	# the eye off centre.
	_name.position = Vector2(
		get_viewport_rect().size.x * 0.5 - _name.size.x * 0.5,
		get_viewport_rect().size.y * 0.5 + 22.0)
	queue_redraw()


func _draw() -> void:
	# `get_viewport_rect()`, not `size`: a `Control` under a `CanvasLayer` gets
	# no laid-out size from anchors, and reading `size` puts this off-screen —
	# the exact bug `Ear` was shipped with and photographed to find.
	var middle: Vector2 = get_viewport_rect().size * 0.5
	var radius: float = lerpf(DOT, REACH_DOT, _grown)
	var tint: Color = MenuStyle.TEXT.lerp(MenuStyle.WARM, _grown)
	tint.a = lerpf(0.5, 0.95, _grown)
	draw_circle(middle, radius, tint)
	if _grown <= 0.01:
		return
	# Four ticks, opening outward as the thing comes into reach. Motion rather
	# than a new symbol, so the change is readable in peripheral vision while
	# the player is looking at the object itself.
	var gap: float = radius + 3.0 + GROW * _grown
	for step: int in range(4):
		var angle: float = TAU * float(step) / 4.0 + PI * 0.25
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(middle + direction * gap,
			middle + direction * (gap + 5.0), tint, 1.5)
	_draw_channel(middle)


## The climb, as a ring filling clockwise from the top.
##
## A hold with no progress indicator is the one thing every reference on
## hold-to-interact agrees you must not ship: the hold is *chosen over a press*
## precisely so the player can see it happening and back out. This one had a
## four-second hold, a cost in noise the whole time, and nothing on screen —
## which is why the exit read as broken rather than as slow.
##
## At the crosshair rather than as a bar somewhere else, because that is where
## the player is already looking and because the Shaft is used by standing
## still: there is nothing else to watch.
func _draw_channel(middle: Vector2) -> void:
	# **Both ways out draw the same ring** (ADR-015 gives them different costs,
	# not different grammars). The Waystone had the identical fault: a timed
	# channel, host-side, with nothing on screen — you pressed the key that ends
	# your run and the game appeared to ignore you.
	var progress: float = 0.0
	var waiting: bool = false
	if _shaft != null and is_instance_valid(_shaft):
		progress = _shaft.progress()
		waiting = true
	elif _body != null and is_instance_valid(_body) and _body.leaving > 0.0:
		progress = _body.leaving
		waiting = true
	if not waiting:
		return
	# The empty track is drawn whenever you are in reach, so the ring is not a
	# thing that appears from nowhere the instant you press the key — you can
	# see what is about to fill before you commit to filling it.
	var track: Color = MenuStyle.TEXT
	track.a = 0.22
	_arc(middle, RING, 0.0, 1.0, track, 1.5)
	if progress <= 0.0:
		return
	var done: Color = MenuStyle.WARM
	done.a = 0.95
	_arc(middle, RING, 0.0, progress, done, 2.5)


## An arc from `start` to `finish`, both 0–1 of a full turn, beginning at the
## top and running clockwise — the direction every clock and every progress
## ring in the medium already reads as "time passing".
func _arc(middle: Vector2, radius: float, start: float, finish: float,
		colour: Color, width: float) -> void:
	var steps: int = maxi(2, int(ceil(float(RING_SEGMENTS) * (finish - start))))
	var points := PackedVector2Array()
	for step: int in range(steps + 1):
		var through: float = start + (finish - start) * float(step) / float(steps)
		var angle: float = -PI * 0.5 + TAU * through
		points.append(middle + Vector2(cos(angle), sin(angle)) * radius)
	draw_polyline(points, colour, width)


func _local_body() -> Player:
	for node: Node in get_tree().get_nodes_in_group("player"):
		var body := node as Player
		# `is_inside_tree` for the same reason as `_body_to_read`: a node on its
		# way out of the world is still in its groups, and rebinding to one is
		# how a stale reference gets replaced by an equally stale one.
		if body != null and body.is_inside_tree() \
				and body.is_multiplayer_authority():
			return body
	return null
