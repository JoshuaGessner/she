class_name RankScaling
extends Object

## How a floor changes with the Pact Rank on it (`M3-T10`, ADR-010, `DES-022`).
##
## The sibling of `PartyScaling`, and deliberately a separate file: they are two
## independent axes that multiply, and one class taking both would read as one
## question. How many people are down here, and how far along is the deepest of
## them, are different things.
##
## ## The rule, and it is the whole of `DES-022`
##
## > **Enemies have fixed stats per archetype. Difficulty scales by composition
## > and pressure — never by giving the same enemy bigger numbers.**
##
## *"A rank-1 player dies in a rank-9 floor because there are more things, worse
## things, and less time — not because a skeleton hits for 40 instead of 12."*
##
## `DES-022` lists six axes. Three of them need content that does not exist —
## Composition wants Thursar and elites (`M4-T02`), Modifiers want the Gilded /
## Roused / Silent / Warded set (`M5-T04`), Layout wants module generation
## (`M4-T01`). Pretending at those here would be the stub ADR-064 bans.
##
## ## The three that are buildable are two levers
##
## | `DES-022` axis | What moves it |
## |---|---|
## | **Density** | `denser()` — more of everything |
## | **The Hunt** | `hunt_age()` — arrives sooner, escalates faster |
## | **Time** | `hunt_age()` — *the same call* |
##
## The last row is the good part and it is not a coincidence. `Shaft._escalation`
## reads the Gullsjúkr's `age` rather than a clock of its own, on purpose:
## *"the pressure the player feels and the price of leaving have to come from
## the same source, or the Sealing is a timer wearing the Hunt's clothes."* So a
## floor that starts its Hunt older seals its Shafts sooner **for free** — one
## number delivering two of `DES-022`'s axes, with no second system and nothing
## to keep in step.
##
## ## Whose rank
##
## The highest in the party (ADR-010) — *"boredom is worse than danger."*
## `CoopSession.floor_rank()` owns that, because it is the only thing that knows
## who is here.


## Enemies on a floor for a given rank, on top of whatever the party asked for.
##
## Density is the axis that needs no new content at all: `ENEMY_POSTS` already
## rings out when a party grows, and a rank grows it the same way.
static func denser(base: int, rank: int) -> int:
	var scaled: float = float(base) * (1.0
		+ float(maxi(rank, 1) - 1) * Config.tuning.rank_density_slope)
	return maxi(1, int(round(scaled)))


## Seconds of Hunt a floor of this rank has already had when you arrive.
##
## `DES-017`'s escalation is a function of `age`, so starting it partway along
## is the same as saying the Hunt has been down here a while — which is exactly
## what `DES-022` asks for and needs no new rule for a player to learn.
static func hunt_age(rank: int) -> float:
	return float(maxi(rank, 1) - 1) * Config.tuning.rank_hunt_seconds
