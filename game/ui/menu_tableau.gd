class_name MenuTableau
extends SubViewportContainer

## **The first thing the game shows is her** (ADR-288). The menu was a column of
## boxed buttons on a flat dark ground — an app's settings page. Hunt:
## Showdown, Darkest Dungeon and the Souls games all open on a living scene
## with the menu laid over one side of it, and the reason is the same in each:
## the title screen is the promise of what the game feels like, and a list on a
## colour promises nothing.
##
## So: her head and neck rising out of the dark over the hoard, two braziers
## lighting her from below, drawn through the same ink pass as the Deep, and a
## camera that breathes very slowly. It is a picture, not a level — nothing in
## it is solid, nothing replicates, and it costs one small viewport.

## The least the title shows of her pile, whatever this lineage has given. It
## is a picture of what the game promises, not a readout — the Chamber is
## where the pile is exactly yours. ⟨tune⟩
const TITLE_HOARD: int = 900
const HOARD_GLOW: float = 0.9  ## ⟨tune⟩
const RIM: float = 0.7  ## ⟨tune⟩
## Dimmer than the Chamber's 1.6: the camera is closer to the fire here, and at
## full strength the braziers warm her to copper. ⟨tune⟩
const BRAZIER: float = 1.0

var _camera: Camera3D = null
var _time: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view := SubViewport.new()
	view.own_world_3d = true
	view.handle_input_locally = false
	add_child(view)
	var world := Node3D.new()
	view.add_child(world)

	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color(0.02, 0.02, 0.025)
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(0.12, 0.11, 0.12)
	sky.ambient_light_energy = 0.2
	sky.fog_enabled = true
	sky.fog_light_color = Color(0.03, 0.03, 0.035)
	sky.fog_density = 0.035
	environment.environment = sky
	world.add_child(environment)

	# **Her, as the Chamber draws her** (ADR-333): the same carving, recoloured
	# for this lineage, over the same pile. This screen once dressed her in one
	# flat material of its own and laid a smooth glowing dome in front of her —
	# orange plastic over a yolk, and the first picture of her anyone saw.
	var her := Chamber.HER_MODEL.instantiate() as Node3D
	Chamber.dress_her(her, Chamber.her_colour(GameState.descents))
	world.add_child(her)
	var pile := Node3D.new()
	world.add_child(pile)
	Chamber.pile_hoard(pile, maxi(GameState.hoard_value, TITLE_HOARD))

	for flank: float in [-1.0, 1.0]:
		Hearth.brazier(world, Vector3(flank * 3.2, 0.0, 0.6), BRAZIER)

	# **Lit as her hall is lit** (ADR-329, ADR-333): fire from below, the gold
	# glowing up under her jaw, and a cold edge from behind. The orange lamp
	# that was here lit her face from the front, flattened the carving, and
	# turned her copper — a colour she never is in the Chamber.
	var glow := OmniLight3D.new()
	glow.light_color = Chamber.GOLD
	glow.light_energy = HOARD_GLOW
	glow.omni_range = 5.0
	glow.position = Vector3(0.0, 0.6, 0.8)
	world.add_child(glow)
	# The rim is what makes a dark shape on a dark ground a silhouette — Hunt's
	# and Darkest Dungeon's title scenes are mostly black, and every one of them
	# keeps an edge of cold light on the thing you are meant to see.
	var rim := DirectionalLight3D.new()
	rim.light_color = Color(0.62, 0.7, 0.86)
	rim.light_energy = RIM
	rim.rotation = Vector3(deg_to_rad(-28.0), deg_to_rad(160.0), 0.0)
	world.add_child(rim)

	_camera = Camera3D.new()
	_camera.fov = 52.0
	world.add_child(_camera)
	var ink := InkPass.new()
	_camera.add_child(ink)
	_camera.make_current()
	_place_camera()


func _process(delta: float) -> void:
	_time += delta
	_place_camera()


## A slow drift, never a pan: the eye should not feel it moving, only that the
## picture is alive.
##
## **From her right, looking back across her** (ADR-333). Her head turns to her
## left, so a camera on that side saw her face-on and foreshortened — a snout
## and two eyes. From this side she is in profile, the head reaching out over
## the menu toward the title and the body arching away to the right edge, with
## the pile under her jaw clear of the lettering.
func _place_camera() -> void:
	if _camera == null:
		return
	var sway: float = sin(_time * 0.11) * 0.6
	var bob: float = sin(_time * 0.17) * 0.15
	_camera.position = Vector3(3.4 + sway, 1.2 + bob, 6.0)
	_camera.look_at(Vector3(-1.0 + sway * 0.3, 3.3, -0.6), Vector3.UP)
