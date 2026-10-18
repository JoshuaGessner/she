class_name Verb
extends Node

## **What every class verb's component shares** (B178): the body it serves,
## whether that body is sworn to the verb's class, and whether a request came
## from the peer that owns the body.
##
## Six components (`Seidr`, `Haugbrot`, `Galdr`, `WolfFury`, `SnareVerb`,
## `HoldVerb`) each wrote these three, and the sender rule two ways: a
## `call_remote` request compared the sender with the body's authority, a
## `call_local` one first read a local call's sender 0 as this peer. One rule
## now, which is the second, because it is the first plus the host's own calls.

var _body: Player = null


## Called by the body that owns it, once, before anything asks.
func serve(body: Player) -> void:
	_body = body


## Whether the body is sworn to the class whose verb is `verb` (`DES-011`:
## identity comes from the verb, and only its class has it).
func _owns(verb: StringName) -> bool:
	var sworn: ClassResource = ClassCatalogue.by_id(_body.sworn)
	return sworn != null and sworn.verb == verb


## Whether an RPC — or the host calling on itself, which reports sender 0 —
## came from the peer that owns this body, on the host (`TEC-004`).
func _from_owner() -> bool:
	if not multiplayer.is_server():
		return false
	var from: int = multiplayer.get_remote_sender_id()
	if from == 0:
		from = multiplayer.get_unique_id()
	return from == _body.get_multiplayer_authority()
