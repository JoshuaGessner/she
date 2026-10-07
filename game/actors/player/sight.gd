class_name Sight
extends Node

## **What a Völva saw** (ADR-379, `DES-011` §2) — the marks a reading leaves.
##
## A `Pinger` holds one mark a body and follows what it marks. A reading is
## neither: it is several things at once, and each is where it **was** when she
## read it. Thief's map rather than Dishonored's Dark Vision — information that
## never goes stale makes the floor solved, and `DES-011`'s balance rule 2 will
## not let any class be the best at extracting. So these marks stand still and
## run out, and the Gold-Sick walks on without them.
##
## The host decides what was seen (`TEC-004`: a reading reveals what the floor
## holds, so it is never the client's to say) and tells every peer; each peer
## ages its own copy and `PingLayer` draws them in the ping's own shapes, so
## the party reads a reading without a new vocabulary.

const GROUP: StringName = &"sights"
## More than a reading can hold is a malformed one, refused rather than drawn.
const MOST: int = 24

## `[{"kind": Pinger.Kind, "at": Vector3, "left": seconds}]`, on every peer.
var marks: Array[Dictionary] = []

## **A reading that found nothing** (B55): no Gold-Sick on the floor yet,
## nothing worth anything left, no way down. Marks and a ping would say nothing
## at all, so the seer's own reticle says so. The sight is still spent: the
## trance was sat, and an empty floor is a thing worth knowing.
signal saw_nothing


func _ready() -> void:
	add_to_group(GROUP)


## The host's half: say what was seen, to every peer, this one included.
## `found` is `[[kind, at], ...]`.
func show_reading(found: Array) -> void:
	_shown.rpc(found)


@rpc("any_peer", "call_local", "reliable")
func _shown(found: Array) -> void:
	# Only the host reads the floor. A local call reports sender 0.
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != Player.HOST_PEER:
		return
	if found.size() > MOST:
		return
	var seen: Array[Dictionary] = []
	for entry: Variant in found:
		var pair := entry as Array
		if pair == null or pair.size() != 2 or not (pair[0] is int) \
				or not (pair[1] is Vector3):
			return
		var kind: int = pair[0]
		var at: Vector3 = pair[1]
		if kind < 0 or kind >= Pinger.Kind.size() or not at.is_finite():
			return
		seen.append({"kind": kind, "at": at, "left": Config.tuning.seidr_seen_seconds})
	marks = seen
	if not seen.is_empty():
		Foley.flat(self, Foley.Sound.PING, 0.7)
	else:
		# Raised on every peer; only the seer's own reticle listens.
		saw_nothing.emit()


## Where a mark is drawn: over what it marks, by the ping's own lift.
static func mark_position(mark: Dictionary) -> Vector3:
	return (mark["at"] as Vector3) + Vector3.UP * float(Pinger.LIFT[int(mark["kind"])])


func _process(delta: float) -> void:
	if marks.is_empty():
		return
	for mark: Dictionary in marks:
		mark["left"] = float(mark["left"]) - delta
	marks = marks.filter(func(mark: Dictionary) -> bool: return float(mark["left"]) > 0.0)
