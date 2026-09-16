class_name ContractLedger
extends Node3D

## **The Lodge's work, on the floor it points at** (`M4-T04`, ADR-241).
##
## One per process, one per floor, and **replicated to nobody**. A contract is
## this life's (`TEC-004`: progression is never networked), and every question
## a contract asks can be answered from what this peer already has: its own
## body's position for a cairn, a corpse's state — which reaches every peer as
## the value that topples it — for a cull, and its own bag at the exit for a
## retrieve. So the Lodge costs the wire nothing, and the host never learns
## what anybody was hired to do.
##
## **Met is written when it happens** (`RunFile.meet`), so a run quit on floor
## one and resumed does not forget the cairn it already stood beside. Whether a
## contract is kept is decided once, at the end of the run, by
## `GameState.settle_contracts` — met work that died with its carrier is work
## the Lodge never heard about.

signal met(held: Contract)

## How close a body must stand to have found a cairn ⟨tune⟩.
const CAIRN_REACH: float = 2.5
## Seconds between looks for a hunted body's corpse.
const LOOK_EVERY: float = 0.25

var _floor: FloorSource = null
var _floor_index: int = 0
## Contract key → the cairn it points at.
var _cairns: Dictionary = {}
## Contract key → the archetype it hunts.
var _hunted: Dictionary = {}
var _look: float = 0.0


## Read every contract that points at this floor off the life, and set its
## work out: a cairn raised, a body named, a Prize remembered.
func begin(floor_source: FloorSource, floor_index: int) -> void:
	_floor = floor_source
	_floor_index = floor_index
	var done: PackedStringArray = RunFile.met()
	for held: Contract in here():
		if done.has(held.key()):
			continue
		match held.kind():
			Enums.ContractKind.SURVEY:
				var cairn := LodgeCairn.new()
				add_child(cairn)
				cairn.global_position = floor_source.survey_point()
				_cairns[held.key()] = cairn
			Enums.ContractKind.CULL:
				_hunted[held.key()] = held.cull_target()
			Enums.ContractKind.RETRIEVE:
				RunFile.expect(held.key(), floor_source.prize_id())


## The life's contracts that point at this floor.
func here() -> Array[Contract]:
	var found: Array[Contract] = []
	for held: Contract in GameState.contracts:
		if held.floor_index == _floor_index:
			found.append(held)
	return found


## The cairn a contract raised here, or null. Public for the probe that walks
## to it.
func cairn_for(held: Contract) -> LodgeCairn:
	return _cairns.get(held.key()) as LodgeCairn


func _process(delta: float) -> void:
	var body := get_tree().get_first_node_in_group("local_player") as Player
	if body == null:
		return
	for key: String in _cairns.keys():
		var cairn := _cairns[key] as LodgeCairn
		if cairn.global_position.distance_to(body.global_position) <= CAIRN_REACH:
			cairn.stood_by()
			_cairns.erase(key)
			_meet(key)
	_look -= delta
	if _look > 0.0 or _hunted.is_empty():
		return
	_look = LOOK_EVERY
	for key: String in _hunted.keys():
		for node: Node in get_tree().get_nodes_in_group("enemies"):
			var enemy := node as Enemy
			if enemy != null and enemy.archetype == _hunted[key] \
					and enemy.state() == Enemy.State.DEAD:
				_hunted.erase(key)
				_meet(key)
				break


func _meet(key: String) -> void:
	RunFile.meet(key)
	for held: Contract in here():
		if held.key() == key:
			print("[lodge] met '%s' on floor %d" % [held.title(), _floor_index])
			met.emit(held)
			return


## **What the arrival brief says about the Lodge's work here** (ADR-241), from
## where the party stands: a line for each contract this floor holds, and the
## plans if they came down.
func lines(standing: Vector3) -> PackedStringArray:
	var out := PackedStringArray()
	var done: PackedStringArray = RunFile.met()
	for held: Contract in here():
		if done.has(held.key()):
			continue
		match held.kind():
			Enums.ContractKind.SURVEY:
				out.append("the Lodge's cairn is %s"
					% ArrivalBrief.bearing(standing, _floor.survey_point()))
			Enums.ContractKind.CULL:
				var hunted: EnemyResource = EnemyCatalogue.by_id(held.cull_target())
				out.append("the Lodge wants a %s put down" % (
					hunted.display().to_lower() if hunted != null else "thing"))
			Enums.ContractKind.RETRIEVE:
				var wanted: ItemResource = ItemCatalogue.by_id(_floor.prize_id())
				out.append("the Lodge wants the %s brought up" % (
					wanted.display().to_lower() if wanted != null else "Prize"))
	if RunFile.planned():
		out.append("the plans: the Prize is %s; the Shaft %s" % [
			ArrivalBrief.bearing(standing, _floor.prize()),
			ArrivalBrief.bearing(standing, _floor.shaft())])
	return out


## **What a finished run answered** (ADR-241): the contracts met on the way,
## and each Retrieve whose item is in the bag it came out with.
static func answered(met_keys: PackedStringArray, wanted: Dictionary,
		rows: Array) -> PackedStringArray:
	var out: PackedStringArray = met_keys.duplicate()
	for key: Variant in wanted:
		for row: Variant in rows:
			if typeof(row) != TYPE_DICTIONARY:
				continue
			var item: Dictionary = row
			if String(item.get("item", "")) == String(wanted[key]) \
					and not String(wanted[key]).is_empty() and not out.has(String(key)):
				out.append(String(key))
	return out
