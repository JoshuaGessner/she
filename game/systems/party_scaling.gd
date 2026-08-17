class_name PartyScaling
extends Object

## How a floor changes with the number of people on it (`M2-T07`, `DES-012`).
##
## > **A 4-player run is safer moment to moment, far more hunted, and worth
## > less each. A solo run is lethal, quiet, and lucrative.**
##
## `DES-012` calls this *"the most important balance relationship in co-op"*,
## and the failure it exists to prevent is the classic one: 4-player becomes
## the optimal farm and everybody abandons solo. The fix is that party size
## **trades safety for yield and pressure** rather than simply adding people.
##
## ## Three exponents, and the signs are the design
##
## | | Direction | Because |
## |---|---|---|
## | Enemies | **near-linear** | keeps combat meaningful with more swords in the room |
## | Loot | **sub-linear** ⟨tune⟩ | per-capita yield *drops* — you are splitting a floor |
## | Clamor | **super-linear** ⟨tune⟩ | four bodies are far more than twice as loud as two |
##
## The two that matter are the ones that are not linear, and what makes them
## work is the **per-capita** arithmetic rather than the totals:
##
## ```
## loot   per person = base · N^p / N = base · N^(p-1)   → falls, since p < 1
## clamor per person = N^q / N        = N^(q-1)          → rises, since q > 1
## ```
##
## So a bigger party is individually poorer and collectively louder, without a
## single rule that says "four players get less". Nobody is punished; the floor
## is just being divided, and being divided by more people is worse for each of
## them. That is the whole mechanism, and it is two exponents.
##
## **Extraction points stay flat**, deliberately (`DES-012`): everyone
## converges on the same doors, which is where a scattered party becomes a
## crowd at the exit.
##
## ## This is a shape, not a balance pass
##
## Every number here is ⟨tune⟩ and none of them is settled. What `M2-T07` owes
## is that the *shape* is right and **measurable from the first build** —
## `DES-012` asks for per-capita extracted value tracked by party size from the
## first playable one, because it is the number that tells you whether either
## way of playing has quietly become the correct one.


## Enemies on a floor for a given party. Near-linear: `DES-012` wants combat to
## stay meaningful rather than trivial when there are four people swinging.
static func enemies(base: int, party: int) -> int:
	var scaled: float = float(base) * (1.0
		+ float(maxi(party, 1) - 1) * Config.tuning.party_enemy_slope)
	return maxi(1, int(round(scaled)))


## How many pieces of a floor's loot are present. **Sub-linear**, which is the
## half that makes a big party individually poorer.
static func loot(base: int, party: int) -> int:
	var scaled: float = float(base) * pow(float(maxi(party, 1)),
		Config.tuning.party_loot_exponent)
	return maxi(1, int(round(scaled)))


## What every clamor deposit is multiplied by. **Super-linear**, so a party is
## disproportionately loud — and since `M2-T02` the Gullsjúkr navigates that
## noise, a four-stack meets it far sooner without any rule saying so.
static func clamor(party: int) -> float:
	return pow(float(maxi(party, 1)), Config.tuning.party_clamor_exponent)


## The number that decides everything above: how many people are on the floor.
##
## Counted from the group rather than from the peer list, because a body that
## has spawned is a body making noise and pulling loot, whether or not its
## owner's connection has finished settling.
static func size_of(from: Node) -> int:
	if from.get_tree() == null:
		return 1
	return maxi(1, from.get_tree().get_nodes_in_group("player").size())
