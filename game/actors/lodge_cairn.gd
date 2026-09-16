class_name LodgeCairn
extends Node3D

## **A Lodge cairn, where a Survey contract points** (`M4-T04`, ADR-241).
##
## Three flat stones and a pale lamp: the Lodge's light in a place nobody of
## theirs came back from, so it can be found in the dark by the one thing the
## floor is otherwise short of. Found, the lamp warms and it knocks once — the
## sound and the light say the same thing (`DES-018`).
##
## **Only on the screen of the one who took the work.** A contract is a life's
## own (`TEC-004`: progression is never networked), so the cairn is built by
## that player's own `ContractLedger` and replicated to nobody; a teammate
## walking past one they did not take would be walking past a promise that is
## not theirs.

const STONE: Color = Color(0.58, 0.57, 0.54)
## The Lodge's light: the fire's ash, not its flame ⟨tune⟩.
const ASH: Color = Color(0.78, 0.80, 0.86)
const FOUND: Color = Color(1.0, 0.72, 0.42)

var _lamp: OmniLight3D = null
var found: bool = false


func _ready() -> void:
	var height: float = 0.0
	for tier: int in 3:
		var slab := MeshInstance3D.new()
		var box := BoxMesh.new()
		var width: float = 0.9 - 0.2 * float(tier)
		box.size = Vector3(width, 0.22, width * 0.85)
		slab.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = STONE
		slab.material_override = material
		slab.position = Vector3(0.0, height + 0.11, 0.0)
		slab.rotation.y = 0.35 * float(tier)
		add_child(slab)
		height += 0.22
	_lamp = OmniLight3D.new()
	_lamp.position = Vector3(0.0, height + 0.35, 0.0)
	_lamp.omni_range = 5.0
	_lamp.light_color = ASH
	_lamp.light_energy = 1.4
	add_child(_lamp)


## Stood beside, at last. Once.
func stood_by() -> void:
	if found:
		return
	found = true
	if _lamp != null:
		_lamp.light_color = FOUND
	Foley.at(self, Foley.Sound.THUMP, 1.3, -4.0)
