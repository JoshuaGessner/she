class_name InkPass
extends MeshInstance3D

## The ink outline pass, as a component any camera can carry (ART-005 §1–2).
##
## Promoted out of the `M1-T09` spike after ADR-070 passed the gate at
## ≈0.4–0.6 ms per frame at 1080p. The spike measured it; this renders it in
## the actual game. There is exactly one copy of the shader and one copy of
## this setup — the spike scene uses this component too, because a spike-local
## duplicate would be the parallel path ADR-064 bans, and the two would drift
## apart the first time either was tuned.
##
## World-space hatching is reconstructed from depth so the same treatment
## reaches every opaque asset, including generated architecture.
##
## ## Two pages, and four kinds of line (`M4-T08`, ADR-269)
##
## **The page** is which world the camera is in: the Deep draws pale ink on
## black, and only where there is light to draw with; the Threshold and the
## Chamber are a finished print, black on white. A level declares the print by
## carrying the `PRINTED` group on its root, so the camera reads it on arrival
## and it cannot be left set by a level that has gone (`M2-T15`'s fault).
##
## **The class** is what a pixel belongs to, which a full-screen pass cannot see
## — per-object data is in none of the buffers it reads (ADR-258). So the
## objects write it into the stencil buffer, and the pass is run once per class
## behind a stencil test. The test rejects a pixel before its fragment runs, so
## four passes cost about one. What each class draws is `CLASSES`, below.
##
## Add it as a child of the camera. It draws a full-screen quad in clip space,
## so it needs no positioning and must never be frustum-culled.

const STYLE: ShaderMaterial = preload("res://data/tuning/ink_style.tres")

## The group a level's root carries to be drawn as a print.
const PRINTED: StringName = &"printed"

enum Page { DEEP, PRINT }

## What a pixel belongs to. The value is the stencil reference, so the order is
## load-bearing: 0 is what an unmarked surface already holds.
enum Class {
	WORLD,   ## Stone, kit, everything nothing else claims.
	THREAT,  ## An enemy or a thing worth taking.
	FAINT,   ## Set dressing authored with a light line, 0 < R < 0.5.
	BARE,    ## Set dressing authored with no line at all, R = 0.
	GOLD,    ## Gold that is not loot — the hoard, her fire. Keeps its colour.
}

## One shader per class, identical but for the stencil value it answers to.
const SHADERS: Array[Shader] = [
	preload("res://art/shaders/ink_outline.gdshader"),
	preload("res://art/shaders/ink_threat.gdshader"),
	preload("res://art/shaders/ink_faint.gdshader"),
	preload("res://art/shaders/ink_bare.gdshader"),
	preload("res://art/shaders/ink_gold.gdshader"),
]

## **What each class's contour is** ⟨tune⟩.
##
## `ART-005` §"The readability risk" names four mandatory controls and this
## table is three of them. *Distance falloff*: the world fades, a threat never
## does. *Outline suppression on unimportant props via the R channel*: the
## modeller's R, quantised to three steps because a stencil carries a class and
## not a number — 0 is no line, anything under a half is a light one, the rest
## is full. *Enemies and loot always outline, at full weight, regardless of
## distance*: and regardless of light, which is the half ADR-203 found missing
## — a body in an unlit corridor drew a dark line on a dark page and was not
## there. In the Deep a threat is a pale line wherever it stands.
##
## The fourth is `ART-005`'s *"gold is the only colour"*, and the page is never
## laid over it. Loot and the Gullsjúkr are threats and keep any strong colour
## by `gold_chroma`; the hoard and her fire are not threats, so they say so.
const CLASSES: Array[Dictionary] = [
	{"edge_weight": 1.0, "edge_width": 1.0, "edge_needs_light": 1.0,
		"edge_fades": 1.0, "keep_colour": 0.0, "gold_chroma": 0.4},
	{"edge_weight": 1.0, "edge_width": 1.6, "edge_needs_light": 0.0,
		"edge_fades": 0.0, "keep_colour": 0.0, "gold_chroma": 0.12},
	{"edge_weight": 0.35, "edge_width": 0.8, "edge_needs_light": 1.0,
		"edge_fades": 1.0, "keep_colour": 0.0, "gold_chroma": 0.4},
	{"edge_weight": 0.0, "edge_width": 1.0, "edge_needs_light": 1.0,
		"edge_fades": 1.0, "keep_colour": 0.0, "gold_chroma": 0.4},
	{"edge_weight": 1.0, "edge_width": 1.2, "edge_needs_light": 1.0,
		"edge_fades": 1.0, "keep_colour": 1.0, "gold_chroma": 0.4},
]

## Where the R channel's bands fall. Authored values in the library are 0,
## 0.32 and 1.0 (`ART-004`'s table), so both cuts sit well clear of all three.
const BARE_BELOW: float = 0.05
const FAINT_BELOW: float = 0.5
## B is the material ID, and gold is its top step (1.0 on every coin and torc
## in the library).
const GOLD_FROM: float = 0.9

## The overlay a threat wears to put its class in the stencil. Adds black, so it
## changes no colour; it exists only for the stencil write.
const MARK: Shader = preload("res://art/shaders/ink_mark.gdshader")
static var _mark: ShaderMaterial = null

## ART-005: "Update that jitter at 8-12 fps, not 60. This is *the* trick."
const BOIL_FPS: float = 10.0
const WOBBLE_AMOUNT: float = 1.1
const WEIGHT_VARIATION: float = 0.55

## **Where the linework stops, in metres** (`ART-005` §"The readability risk").
##
## Promoted out of the shader's uniform defaults at `M4-T26` (ADR-203), and the
## reason is `floor_fog_end`. Depth fog dissolves the *fill*; this falloff
## dissolves the *lines*; they are two halves of one distance and the failure
## mode is them disagreeing — fog that finishes first leaves outlines drawn over
## ground that is no longer there, which is a scribble hanging in the dark and
## looks exactly like a broken shader.
##
## A number that only exists as a shader default is a number no check can read.
## These are set on the material below rather than left implicit, so the shader
## and `TuningProfile._validate()` are looking at the same two values ⟨tune⟩.
const FALLOFF_START: float = 14.0
const FALLOFF_END: float = 34.0

## The first pass. Every other class hangs off it as a `next_pass`, so one
## material still describes the whole treatment.
var material: ShaderMaterial

var _passes: Array[ShaderMaterial] = []
var _page: Page = Page.DEEP


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	mesh = quad
	# The quad lives in clip space, so its real-world AABB is meaningless and
	# the culler would otherwise throw it away the moment the camera turned.
	custom_aabb = AABB(Vector3(-1e5, -1e5, -1e5), Vector3(2e5, 2e5, 2e5))

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.03
	var noise_texture := NoiseTexture2D.new()
	noise_texture.noise = noise
	noise_texture.seamless = true
	noise_texture.width = 256
	noise_texture.height = 256

	# Each camera owns its settings; toggling one player's boil must not change
	# another view. Art values live in the shared tuning resource, and every
	# class reads them from there — a class is a stencil value and a row of
	# `CLASSES`, never a second style.
	var previous: ShaderMaterial = null
	for ink_class: int in Class.size():
		var pass_material := STYLE.duplicate() as ShaderMaterial
		pass_material.shader = SHADERS[ink_class]
		for parameter: String in _style_parameters():
			pass_material.set_shader_parameter(parameter,
				STYLE.get_shader_parameter(parameter))
		for parameter: String in CLASSES[ink_class]:
			pass_material.set_shader_parameter(parameter,
				CLASSES[ink_class][parameter])
		# Drawn after everything else, since it reads the finished colour
		# buffer — and after the threat marks, which are transparent.
		pass_material.render_priority = 100 + ink_class
		if previous == null:
			material = pass_material
		else:
			previous.next_pass = pass_material
		previous = pass_material
		_passes.append(pass_material)
	material_override = material
	set_parameter("noise_tex", noise_texture)
	set_parameter("falloff_start", FALLOFF_START)
	set_parameter("falloff_end", FALLOFF_END)

	set_boil(true)
	set_page(Page.PRINT if is_printed(self) else Page.DEEP)


## Whether the level `node` stands in is drawn as a print.
static func is_printed(node: Node) -> bool:
	return node.is_inside_tree() \
		and node.get_tree().get_first_node_in_group(PRINTED) != null


## Set one shader parameter on every class, so no class can drift from another.
func set_parameter(parameter: StringName, value: Variant) -> void:
	for pass_material: ShaderMaterial in _passes:
		pass_material.set_shader_parameter(parameter, value)


## Which world this camera draws. A hard cut (ADR-167): nothing blends it.
func set_page(which: Page) -> void:
	_page = which
	set_parameter("page", 1.0 if which == Page.PRINT else 0.0)


func page() -> Page:
	return _page


## Toggle the hand-drawn treatment without unloading the pass, so a clean Sobel
## can be compared against the boiled version in place. One implementation with
## its parameters zeroed — not a second code path.
func set_boil(on: bool) -> void:
	set_parameter("wobble_amount", WOBBLE_AMOUNT if on else 0.0)
	set_parameter("weight_variation", WEIGHT_VARIATION if on else 0.0)
	set_parameter("boil_fps", BOIL_FPS if on else 0.0)


## **Mark everything drawn under `root` as a threat** — an enemy, or a thing
## worth taking.
##
## An overlay rather than a change to its materials, because the models a
## `WorldItem` shows share their imported materials with the copy in your hand,
## and the body of an enemy is rebuilt by its own code. An overlay is per node,
## so it marks exactly this instance and nothing it shares with.
##
## Callers mark **the thing, not the node that owns it**: a `WorldItem` marks
## its model and not itself, because its glint is a billboard, and an overlay
## has no way to run the vertex stage that turns it to face you — it would mark
## a square the star is not in.
static func mark(root: Node) -> void:
	if _mark == null:
		_mark = ShaderMaterial.new()
		_mark.shader = MARK
	var found: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		found.append(root)
	for node: Node in found:
		(node as MeshInstance3D).material_overlay = _mark


## Put a material this game **owns** in a class — the hoard's lumps, her fire.
## A material the game built for itself is used by nothing else, so the class
## goes on it directly and costs no extra draw.
static func stamp(owned: BaseMaterial3D, ink_class: Class) -> void:
	owned.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
	owned.stencil_flags = BaseMaterial3D.STENCIL_FLAG_WRITE
	owned.stencil_compare = BaseMaterial3D.STENCIL_COMPARE_ALWAYS
	owned.stencil_reference = ink_class


## Read the modeller's R and B channels off every mesh under `root` and put
## each surface in its class (`ART-004`'s vertex channels, ADR-269).
##
## On the **mesh**, not the instance, because the class is a property of the
## asset: every copy of a rope coil is set dressing. So it is done once per
## mesh resource and remembered on it, and a floor laying forty coils reads
## the channel once. A surface at full weight is left exactly as it arrived.
static func classify(root: Node) -> void:
	var found: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		found.append(root)
	for node: Node in found:
		var drawn := (node as MeshInstance3D).mesh as ArrayMesh
		if drawn != null:
			classify_mesh(drawn)


## `classify` for one mesh, for callers that hold a mesh rather than a node.
static func classify_mesh(drawn: ArrayMesh) -> void:
	if drawn.has_meta(&"ink_classified"):
		return
	drawn.set_meta(&"ink_classified", true)
	for surface: int in drawn.get_surface_count():
		var ink_class: Class = class_of_surface(drawn, surface)
		if ink_class == Class.WORLD:
			continue
		var authored := drawn.surface_get_material(surface) as BaseMaterial3D
		if authored == null:
			push_error("[ink] surface %d of `%s` is authored as %s but has no "
				% [surface, drawn.resource_path, Class.keys()[ink_class]]
				+ "BaseMaterial3D to carry it")
			continue
		var classed := authored.duplicate() as BaseMaterial3D
		stamp(classed, ink_class)
		drawn.surface_set_material(surface, classed)


## The class a surface's authored channels put it in. Gold first, because a
## gold surface keeps its colour whatever its line. Otherwise the **largest** R
## on the surface decides, so a surface with any heavy line in it keeps them.
static func class_of_surface(drawn: Mesh, surface: int) -> Class:
	var colours: Variant = drawn.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
	if not (colours is PackedColorArray) or (colours as PackedColorArray).is_empty():
		return Class.WORLD
	var heaviest: float = 0.0
	var golden: bool = true
	for colour: Color in colours as PackedColorArray:
		heaviest = maxf(heaviest, colour.r)
		golden = golden and colour.b >= GOLD_FROM
	if golden:
		return Class.GOLD
	if heaviest < BARE_BELOW:
		return Class.BARE
	if heaviest < FAINT_BELOW:
		return Class.FAINT
	return Class.WORLD


func _style_parameters() -> PackedStringArray:
	var out := PackedStringArray()
	for uniform: Dictionary in STYLE.shader.get_shader_uniform_list():
		var name: String = uniform["name"]
		if STYLE.get_shader_parameter(name) != null:
			out.append(name)
	return out
