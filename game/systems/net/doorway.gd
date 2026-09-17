class_name Doorway
extends Node

## **Where a late arrival knocks** (`M4-T15`, ADR-250, `TEC-004`).
##
## ADR-016 made join-in-progress core rather than post-launch. ADR-157 refused
## it and said exactly why: a `CoopSession` is **built per level**, Godot
## addresses every RPC by **node path**, and a peer joining mid-run is in a
## different scene from the party — so the one packet that could tell it where
## to go cannot be delivered by the thing that knows. *"It broke both ends, and
## it could cost the host the run."*
##
## This is that packet's address. **One node, one name, under the tree root**:
## the same path on every peer in every scene, alive for the process rather
## than for the level, so the host in the Deep and a joiner still at the fire
## can say two sentences to each other. Two calls cross it and nothing else
## ever will — a general cross-scene RPC channel is how the node-path rule gets
## quietly abandoned, and this one is deliberately too small to become that.
##
## **Not an autoload** (`TEC-001` budgets six and names them): it is made by the
## first `CoopSession` that needs one, at a path both scenes have because it is
## under neither.

const NAME: StringName = &"Doorway"

## The party is below, and this is the expedition. Host → the peer that knocked.
signal called_down(run_seed: int, floor_index: int)
## A peer that was called down is standing on that floor now. → the host.
signal arrived(peer: int)


## The one in this process, kept here rather than looked up: the first caller
## is a session in the middle of its own `_ready`, so the node is added to the
## root **deferred** — the root is busy setting up children at that moment and
## refuses — and a lookup would not find it yet and would make a second.
static var _here: Doorway = null


static func of(tree: SceneTree) -> Doorway:
	if _here != null and is_instance_valid(_here):
		return _here
	if tree == null or tree.root == null:
		return null
	var made := Doorway.new()
	made.name = NAME
	_here = made
	tree.root.add_child.call_deferred(made)
	return made


## **Come down to us** — host to one peer, naming the expedition it would be
## joining. The joiner needs both numbers before it can build anything: every
## peer derives its own geometry from the seed (ADR-184), and a party is on a
## floor rather than in a level.
@rpc("authority", "reliable")
func the_party_is_below(run_seed: int, floor_index: int) -> void:
	called_down.emit(run_seed, floor_index)


## **I am where you are** — said by a peer once the level it is in is built.
## The host spawns no body for anyone until this arrives, which is the whole of
## ADR-157's fix: a body built for somebody who is in another scene is the
## failure, and this is the sentence that rules it out. Said from the camp as
## well as from a floor, because *which scene* is the question — a peer at the
## fire that never said it would be sent a world it cannot see.
@rpc("any_peer", "reliable")
func i_am_with_you() -> void:
	var who: int = multiplayer.get_remote_sender_id()
	arrived.emit(who if who != 0 else multiplayer.get_unique_id())
