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


## The actor this hitbox was authored under — who swung, not what swung.
##
## `owner` rather than a walk up the tree: a node instantiated from a scene has
## its scene root as `owner`, and `TEC-001`'s "signals up, calls down" forbids
## reaching into a parent. With one player it made no difference; with two, an
## enemy that cannot tell which of them hit it investigates the wrong place.
func actor() -> Node3D:
	return owner as Node3D


func _on_area_entered(area: Area3D) -> void:
	if not _armed:
		return
	# **The single place damage becomes host-authoritative** (`TEC-004`,
	# ADR-082). Every peer runs this phase machine and every peer's hitbox
	# overlaps the same things; only the host's is allowed to conclude
	# anything. One gate rather than a guard at each of the four call sites,
	# because four guards are four chances for one to be forgotten — and a
	# forgotten one means damage applied twice on the host and once on a
	# client, which reads as "enemies sometimes take double damage".
	#
	# A solo launch is peer 1 on Godot's offline peer, so this is true there
	# too and single-player is not a special case.
	if not multiplayer.is_server():
		return
	var hurtbox := area as Hurtbox
	if hurtbox == null or hurtbox in _already_hit:
		return
	_already_hit.append(hurtbox)
	hurtbox.receive(damage, self)
	struck.emit(hurtbox)
