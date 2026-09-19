extends SceneTree

## **The notebook answers `DES-010`'s six questions** (`M4-T10`, ADR-261).
##
## `DES-010` names six metrics and says to instrument them at M2 — *"retention
## questions are unanswerable from vibes"* — and none of them were ever
## instrumented. This asserts that rows written the way the game writes them
## come back out as the numbers the document asks for, and that a check can
## never write into the player's own notebook.
##
## **Arithmetic, not plumbing.** Whether the hooks fire in play is `--run-probe`
## and `--coop` territory; what this owns is that a ledger full of known runs
## produces the right rates, because a summary that is quietly wrong is worse
## than no summary — somebody would tune the game against it.

var _failures: int = 0


func _check(ok: bool, label: String, detail: String = "") -> void:
	print("  %s %s%s" % ["ok  " if ok else "FAIL", label,
		"   " + detail if detail != "" else ""])
	if not ok:
		_failures += 1


func _initialize() -> void:
	# **First, and it is the assertion that protects a player** (ADR-152).
	# Every probe in the suite runs with a `--*-probe` flag, so the ledger must
	# refuse the real file without anybody remembering to tell it to.
	_check(not RunLedger.writing(),
		"a check does not write the player's notebook by default",
		"`writing()` returned true under %s" % [OS.get_cmdline_user_args()])

	RunLedger.use_a_scratch_ledger()
	_check(RunLedger.writing(), "a scratch notebook is writable")
	_check(RunLedger.rows().is_empty(), "the scratch notebook starts empty",
		"%d row(s)" % RunLedger.rows().size())

	# Four runs: two home, one death, one abandoned. Enough that every rate
	# below has a wrong answer that differs from the right one — a fixture
	# where 1/2 and 2/4 agree would pass a summary that divided by anything.
	RunLedger.record(RunLedger.EXTRACTED, {
		"descent": 1, "rank": 1, "party": 1,
		"extracted_value": 100, "abandoned_value": 10})
	RunLedger.record(RunLedger.DIED, {
		"descent": 2, "rank": 2, "party": 1,
		"extracted_value": 0, "abandoned_value": 5})
	RunLedger.record(RunLedger.EXTRACTED, {
		"descent": 3, "rank": 2, "party": 4,
		"extracted_value": 200, "abandoned_value": 0})
	RunLedger.record(RunLedger.ABANDONED, {
		"descent": 4, "rank": 2, "party": 1,
		"extracted_value": 0, "abandoned_value": 7})
	RunLedger.record(RunLedger.TITHE, {"rank": 2, "owed": 40, "paid": 40, "met": true})
	RunLedger.record(RunLedger.TITHE, {"rank": 3, "owed": 60, "paid": 10, "met": false})
	RunLedger.record(RunLedger.TITHE, {"rank": 3, "owed": 60, "paid": 60, "met": true})
	RunLedger.record(RunLedger.LEGACY, {"slot": "item", "id": "wpn_seax"})
	RunLedger.record(RunLedger.LEGACY, {"slot": "node", "id": "asp_deep_lungs"})
	RunLedger.record(RunLedger.LEGACY, {"slot": "node", "id": "asp_sure_grip"})

	var book: Dictionary = RunLedger.summary()
	print("[ledger] %s" % book)

	_check(int(book["runs"]) == 4, "four runs counted",
		"%d" % int(book["runs"]))

	# `DES-010`: below 40 % too punishing to retain, above 80 % no real
	# pressure. Two of four came home.
	_check(is_equal_approx(float(book["extraction_rate"]), 0.5),
		"the extraction rate is the share of runs that came home",
		"%.3f" % float(book["extraction_rate"]))

	# **The churn signal the document calls the one that matters most** is its
	# own outcome, not a death and not an extraction.
	_check(int(book["abandoned"]) == 1 and int(book["died"]) == 1,
		"quitting mid-run is counted apart from dying",
		"abandoned %d, died %d" % [int(book["abandoned"]), int(book["died"])])

	_check(int(book["first_death_on_descent"]) == 2,
		"the first death is remembered by descent number",
		"%d" % int(book["first_death_on_descent"]))

	# *"The single best proxy for whether the core tension is working."*
	_check(int(book["loot_left_behind"]) == 22,
		"loot given up on purpose is summed across every run",
		"%d" % int(book["loot_left_behind"]))

	# **By rank, because a flat rate hides the thing `DES-003` fears** — that
	# the Tithe becomes unpayable somewhere up the ladder.
	var defaults: Dictionary = book["tithe_default_by_rank"]
	_check(is_equal_approx(float(defaults.get(2, -1.0)), 0.0)
			and is_equal_approx(float(defaults.get(3, -1.0)), 0.5),
		"the Tithe default rate is broken out by Pact Rank",
		"%s" % defaults)

	# ADR-003's claim is that both slots are worth spending. If one is never
	# chosen, one of them is not a choice.
	_check(int(book["legacy_items"]) == 1 and int(book["legacy_nodes"]) == 2,
		"Legacy slots are counted item against node",
		"%d item(s), %d node(s)"
			% [int(book["legacy_items"]), int(book["legacy_nodes"])])

	# **`DES-012`'s question, and the reason it is per capita**: the four-player
	# run brought home twice as much in total and half as much each.
	#
	# **Runs that brought nothing home stay in the denominator**, and that is
	# the measure rather than an accident of it. The question co-op has to
	# answer is *is a bigger party worth joining*, and a party that extracts
	# more per head while dying twice as often is not better off. So this is
	# expected value per head **per run attempted** — three solo runs carrying
	# 100 between them is 33.3 each, not 100.
	#
	# Written the other way first, asserting 100.0, and the arithmetic was
	# right and the assertion was wrong. Recorded because the wrong one is the
	# intuitive one and somebody will reach for it again.
	var per_head: Dictionary = book["per_capita_extracted"]
	_check(is_equal_approx(float(per_head.get(1, -1.0)), 100.0 / 3.0),
		"a solo haul is spread over every solo run, won or lost",
		"%s" % per_head)
	_check(is_equal_approx(float(per_head.get(4, -1.0)), 50.0),
		"a four-player haul is divided by the four that carried it",
		"%s" % per_head)

	# The notebook is bounded, or it grows for as long as somebody plays.
	_check(RunLedger.KEEP > 0 and RunLedger.KEEP <= 10000,
		"the notebook has a bound", "%d rows" % RunLedger.KEEP)

	RunLedger.clear()
	_check(RunLedger.rows().is_empty(), "the scratch notebook can be emptied")

	print("\n%d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
