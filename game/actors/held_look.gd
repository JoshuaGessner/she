class_name HeldLook
extends RefCounted
## **An item's model showing what is being done with it** (ADR-267).
##
## Three things in the game are *used* over time rather than in an instant, and
## each already has a number every peer can see: the lantern's shutter
## (`Player.lit`), a binding being tied (`Player.mending`) and a Waystone being
## spent (`Player.leaving`). Until now the only picture of any of them was a
## ring at the crosshair. This turns each number into what the object in the
## hand is doing, so the same state reads the same whether it is your hand in
## first person (`Hands`) or a teammate's on their body (`BodyRig`).
##
## Look only: every function here moves a model and nothing else, and none of
## them is read back by anything that decides.

## What the Waystone gives off as it is spent. `M2-T13`'s pale — the colour
## every doorway on a floor is lit with, because the lighting language says
## *this is the way out*, and a stone opening one is exactly that.
const DEPARTURE: Color = Color(0.86, 0.9, 0.95)
## How bright it gets at the moment you leave, and how far it reaches ⟨tune⟩.
## Small on purpose: it is not in `Lantern.LIGHT_GROUP`, so it lights the hand
## that holds it and gives nobody away.
const DEPARTURE_ENERGY: float = 1.6
const DEPARTURE_RANGE: float = 2.6
## The lantern's flame — pale, like its light, because `ART-005` spends gold
## on treasure and her fire and a lamp is neither ⟨tune⟩.
const FLAME: Color = Color(0.98, 0.95, 0.86)
## How far a louvre turns to stand open, degrees.
const LOUVRE_OPEN: float = 78.0
## Turns of the roll across one whole binding ⟨tune⟩ — enough to read as
## winding, few enough to count.
const BINDING_TURNS: float = 3.0
## How much of the roll is left when the knot is tied.
const BINDING_LEFT: float = 0.35


## The first item in the catalogue carrying a trait of this class, or null —
## how a peer that sees only `mending` knows what a binding looks like.
static func first_with(type: Script) -> ItemResource:
	for item: ItemResource in ItemCatalogue.all():
		if item.has_trait(type):
			return item
	return null


## Open the lantern's shutter by `open` (0 shut, 1 open) and show its flame to
## match. The louvres are found by name on the delivered model, so a lantern
## re-exported without them still hangs and simply stops showing its shutter —
## and `--hands-probe` is what says so.
static func lantern(look: Node3D, open: float) -> void:
	if look == null:
		return
	for node: Node in look.find_children("shutter_louvre*", "Node3D", true, false):
		var louvre := node as Node3D
		if not louvre.has_meta(&"rest"):
			louvre.set_meta(&"rest", louvre.transform)
		var rest: Transform3D = louvre.get_meta(&"rest")
		# About its own long axis **through its own middle**. `ART-004`
		# applies every transform, so a louvre's node sits at the model's
		# origin and its slat is somewhere else; turning about the node would
		# swing the slat across the lantern instead of standing it open.
		var middle: Vector3 = Vector3.ZERO
		var slat := louvre as MeshInstance3D
		if slat != null and slat.mesh != null:
			middle = slat.mesh.get_aabb().get_center()
		var turn := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(LOUVRE_OPEN) * open),
			Vector3.ZERO)
		louvre.transform = rest * Transform3D(Basis(), middle) * turn \
			* Transform3D(Basis(), -middle)
	var flame := look.get_node_or_null(^"flame") as MeshInstance3D
	if flame == null:
		flame = _flame_for(look)
	flame.visible = open > 0.02
	flame.scale = Vector3.ONE * lerpf(0.4, 1.0, open)


## How many louvres a lantern model shows, for the probe.
static func louvres(look: Node3D) -> int:
	if look == null:
		return 0
	return look.find_children("shutter_louvre*", "Node3D", true, false).size()


## Give a Waystone the departure's light by `spent` (0 to 1): its faces take the
## pale and a small light rises in the hand, brightest the moment you go.
static func waystone(look: Node3D, spent: float) -> void:
	if look == null:
		return
	var glow := look.get_node_or_null(^"departure") as OmniLight3D
	if glow == null:
		glow = OmniLight3D.new()
		glow.name = "departure"
		glow.light_color = DEPARTURE
		glow.omni_range = DEPARTURE_RANGE
		glow.shadow_enabled = false
		glow.position.y = _top(look) * 0.6
		look.add_child(glow)
	glow.light_energy = DEPARTURE_ENERGY * spent * spent
	var overlay: StandardMaterial3D = null
	if look.has_meta(&"overlay"):
		overlay = look.get_meta(&"overlay") as StandardMaterial3D
	if overlay == null:
		overlay = StandardMaterial3D.new()
		overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		overlay.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		look.set_meta(&"overlay", overlay)
		for node: Node in look.find_children("*", "MeshInstance3D", true, false):
			(node as MeshInstance3D).material_overlay = overlay
	overlay.albedo_color = Color(DEPARTURE, 0.55 * spent)


## Wind a binding down by `tied` (0 to 1): the roll turns as the linen comes off
## it and grows smaller, so a half-tied knot looks half-tied.
static func binding(look: Node3D, tied: float) -> void:
	if look == null:
		return
	look.rotation.x = -TAU * BINDING_TURNS * tied
	look.scale = Vector3.ONE * lerpf(1.0, BINDING_LEFT, tied)


static func _flame_for(look: Node3D) -> MeshInstance3D:
	var bulb := SphereMesh.new()
	bulb.radius = 0.035
	bulb.height = 0.09
	var lit := StandardMaterial3D.new()
	lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lit.albedo_color = FLAME
	var flame := MeshInstance3D.new()
	flame.name = "flame"
	flame.mesh = bulb
	flame.material_override = lit
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Low in the horn, where a wick would stand.
	flame.position.y = _top(look) * 0.38
	look.add_child(flame)
	return flame


## The height of a model's top above its pivot.
static func _top(look: Node3D) -> float:
	var top: float = 0.0
	for node: Node in look.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		top = maxf(top, (mesh.transform * mesh.get_aabb()).end.y)
	return top
