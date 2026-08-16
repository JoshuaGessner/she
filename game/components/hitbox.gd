class_name Hitbox
extends Area3D

## What can hit. Disabled except during an attack's Active phase.
##
## DES-009's attack anatomy is Anticipation → Active → Recovery, and the Active
## window is the *only* time a swing can connect. Arming and disarming this box
## is how that window exists physically rather than as a timer that happens to
## deal damage — which matters because it means a staggered attacker's swing
## genuinely does not land.
##
## One hurtbox is struck at most once per swing. Without that, a slow arc
## overlapping a target for several frames would deal damage every frame, and
## the weapon's damage number would silently mean "per frame".

signal struck(hurtbox: Hurtbox)

@export var damage: float = 10.0

var _armed: bool = false
var _already_hit: Array[Hurtbox] = []


func _ready() -> void:
	# Monitoring stays on for the node's whole life; `_armed` is what opens and
	# closes the damage window. Toggling `monitoring` looked tidier and was
	# wrong twice over: Godot forbids changing it from inside an area signal
	# ("Function blocked during in/out signal"), and disarm() is reached from
	# exactly there — hit -> Health.died -> disarm. It also broke the
	# overlap scan below, since an Area3D that has never monitored does not
	# know what it overlaps.
	monitoring = true
	area_entered.connect(_on_area_entered)


## Opens the damage window and forgets the previous swing's victims.
func arm() -> void:
	_already_hit.clear()
	_armed = true
	# Anything already overlapping when the window opens must still be hit:
	# area_entered will not fire again for it, and a target standing inside the
	# arc taking no damage is the most confusing possible outcome.
	for area: Area3D in get_overlapping_areas():
		_on_area_entered(area)


func disarm() -> void:
	_armed = false


func is_armed() -> bool:
	return _armed


func _on_area_entered(area: Area3D) -> void:
	if not _armed:
		return
	var hurtbox := area as Hurtbox
	if hurtbox == null or hurtbox in _already_hit:
		return
	_already_hit.append(hurtbox)
	hurtbox.receive(damage, self)
	struck.emit(hurtbox)
