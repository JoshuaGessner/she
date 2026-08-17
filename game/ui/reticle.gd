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

var _body: Player = null
var _grown: float = 0.0
var _name: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_name = MenuStyle.line("", 15, MenuStyle.TEXT)
	_name.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)


func _process(delta: float) -> void:
	if _body == null or not is_instance_valid(_body):
		_body = _local_body()
	var reaching: WorldItem = null
	var hidden: bool = true
	if _body != null and is_instance_valid(_body):
		reaching = _body.reaching_for()
		# Gone while the bag is open: you are looking into a satchel, not down
		# a corridor, and `DES-019` wants that to feel like a different posture.
		hidden = _body.bag_is_open() or _body.is_incapacitated()

	var wanted: float = 1.0 if reaching != null else 0.0
	_grown = move_toward(_grown, wanted, delta * 6.0)
	visible = not hidden
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


func _local_body() -> Player:
	for node: Node in get_tree().get_nodes_in_group("player"):
		var body := node as Player
		if body != null and body.is_multiplayer_authority():
			return body
	return null
