class_name ContractBoard
extends RefCounted

## **What the Lodge offers this descent** (`M4-T04`, ADR-241, `DES-007`).
##
## Three offers and two hands, by the developer's call: the board shows one of
## each kind of work and a life takes at most two, so the choice at the fire is
## already the overcommitment `DES-007` names as the essential part of DMZ —
## three things that want three places, and time for two of them at best.
##
## **A function of the life, not of the moment.** The offers are drawn from a
## seed of the lineage's descent count and the sworn class, so walking away
## from the board and back shows the same three, every machine in a party that
## looked would see its own life's three, and the board turns over when a run
## is taken.

## Offers on the board ⟨tune⟩.
const OFFERED: int = 3
## Contracts a life may carry into one descent ⟨tune⟩.
const TAKEN_MAX: int = 2
## Salts the board's seed apart from every generator stage that also mixes the
## descent count.
const STAGE: int = 0x10D6E


## The board for a life that has made `descents` descents as `class_id`, with
## `trust` in `faction`. Grades never exceed what the trust has opened.
static func offers(descents: int, class_id: StringName, trust: int,
		faction: FactionResource) -> Array[Contract]:
	var out: Array[Contract] = []
	if faction == null:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = MissionGraph._mix(descents * 7919 + String(class_id).hash() + STAGE)
	var kinds: Array[ContractArchetypeResource] = ContractCatalogue.archetypes_of(faction.id)
	# Fisher–Yates on the seeded generator, so the order is the seed's and not
	# the dictionary's.
	for i: int in range(kinds.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: ContractArchetypeResource = kinds[i]
		kinds[i] = kinds[j]
		kinds[j] = swap
	var top: int = faction.top_grade(trust)
	for kind: ContractArchetypeResource in kinds.slice(0, OFFERED):
		out.append(Contract.of(kind.id, rng.randi_range(1, top)))
	return out
