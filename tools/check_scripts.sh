#!/usr/bin/env bash
#
# Parse every GDScript file with the real engine parser and fail on any error.
#
# This is the authority for static typing. `project.godot` sets
# `untyped_declaration=2`, so an untyped variable, parameter or return type is
# a hard parse error — but you only ever see that if something actually parses
# the file. Two Godot behaviours make this less obvious than it should be:
#
#   1. `--headless --import` and `--editor --quit` both report NOTHING for a
#      script that no loaded scene references. Measured on 4.7: a file with two
#      typing errors passed both cleanly.
#   2. `--check-only` prints the errors but **exits 0 anyway**. The exit code
#      is unusable, so we match the output instead.
#
# Hence: one engine invocation per script, and grep for the diagnostics.
#
# Usage:  tools/check_scripts.sh          # uses $GODOT, else looks in the usual places
#         GODOT=/path/to/godot tools/check_scripts.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME="$ROOT/game"

find_godot() {
	if [[ -n "${GODOT:-}" ]]; then printf '%s\n' "$GODOT"; return; fi
	for candidate in godot godot4 \
		/Applications/Godot.app/Contents/MacOS/Godot \
		/Applications/Godot_mono.app/Contents/MacOS/Godot; do
		if command -v "$candidate" >/dev/null 2>&1; then
			command -v "$candidate"; return
		fi
	done
	return 1
}

if ! GODOT_BIN="$(find_godot)"; then
	echo "godot not found — set GODOT=/path/to/godot" >&2
	exit 1
fi

# Not `mapfile`: macOS ships bash 3.2, which does not have it.
scripts=()
while IFS= read -r script; do
	scripts+=("$script")
done < <(cd "$GAME" && find . -name '*.gd' -not -path './.godot/*' | sed 's|^\./||' | sort)

if [[ ${#scripts[@]} -eq 0 ]]; then
	echo "no .gd files yet — nothing to parse"
	exit 0
fi

# Rebuild the global class cache first. Without it, every `class_name` added
# since the last import reads as "Could not find type X in the current scope",
# which looks like a code error and is not one. Self-contained beats a
# precondition nobody remembers.
"$GODOT_BIN" --headless --path "$GAME" --import >/dev/null 2>&1 || true

# `--check-only` compiles a script in isolation, with no SceneTree and so no
# autoloads registered — every reference to one reads as "Identifier not found".
# That is an engine limitation, not a defect in the code, so those exact names
# are filtered out and the boot check below covers them properly instead.
# Filtering is by name, not by pattern: an unknown identifier that is not a
# registered autoload still fails.
autoloads="$(sed -n '/^\[autoload\]/,/^\[/p' "$GAME/project.godot" \
	| grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' | tr -d '=' | paste -sd'|' -)"
# "Failed to compile depended scripts" is the same limitation one level out: a
# script whose dependency touches an autoload cannot compile in isolation
# either. Safe to drop, because every script is also checked on its own pass —
# a genuine error in a dependency still fails there.
ignore="Failed to load script|Failed to compile depended scripts"
if [[ -n "$autoloads" ]]; then
	ignore="$ignore|Identifier not found: ($autoloads)"
fi

failed=0
for script in "${scripts[@]}"; do
	output="$("$GODOT_BIN" --headless --path "$GAME" --check-only --script "$script" 2>&1)"
	# "Failed to load script" is always a cascade of a preceding diagnostic, so
	# dropping it cannot hide anything: the real error line is still matched.
	if diagnostics="$(printf '%s\n' "$output" \
			| grep -E 'SCRIPT ERROR|Parse Error|^ERROR:' \
			| grep -vE "$ignore")"; then
		echo "FAIL game/$script" >&2
		printf '%s\n' "$diagnostics" | sed 's/^/      /' >&2
		failed=$((failed + 1))
	fi
done

if [[ $failed -gt 0 ]]; then
	echo "" >&2
	echo "$failed of ${#scripts[@]} script(s) failed to parse" >&2
	exit 1
fi

# Boot the main scene for a few frames. This is what actually exercises the
# autoloads, the scene tree and every script reached from it together — the
# per-script pass above cannot, by construction. Skipped when no main scene is
# set, which is a legitimate state before there is anything to run.
if grep -q '^run/main_scene=' "$GAME/project.godot"; then
	boot="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 5 2>&1)"
	if problems="$(printf '%s\n' "$boot" | grep -E 'SCRIPT ERROR|Parse Error|^ERROR:')"; then
		echo "FAIL booting the main scene" >&2
		printf '%s\n' "$problems" | sed 's/^/      /' >&2
		exit 1
	fi
	# Booting proves startup works. It does not prove *teardown* works, and the
	# errors that reach a player are disproportionately lifecycle errors: a
	# per-frame overlay walking over an object that was freed last frame. The
	# gym's lifecycle probe destroys and respawns everything three times, which
	# is the state no measurement probe ever reaches because they all quit
	# before anything dies.
	# `--quit-after` is a backstop, not the exit path: a GDScript runtime error
	# aborts the function it happens in, so a probe that errors never reaches
	# its own `quit()` and would otherwise hang the build forever. Measured the
	# hard way — this check ran for eight minutes before being killed.
	# The gym **explicitly**, not the main scene. `M2-T06` made the main scene
	# the Threshold so the game boots into its own loop; the lifecycle probe
	# belongs to the gym, and inheriting whatever `run/main_scene` happens to be
	# would have silently stopped running it.
	churn="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 900 \
		levels/dev/movement_gym.tscn -- --lifecycle-probe 2>&1)"
	if problems="$(printf '%s\n' "$churn" | grep -E 'SCRIPT ERROR|Parse Error|^ERROR:')"; then
		echo "FAIL destroying and respawning actors" >&2
		printf '%s\n' "$problems" | sed 's/^/      /' | sort -u >&2
		exit 1
	fi
	# The shared rig, as Godot sees it. glTF export is where rigs quietly lose
	# non-deforming leaf bones, and every socket on this rig is one — a socket
	# that exists in Blender but not in the .glb fails silently, three tools
	# away from the symptom. ADR-080/081 are only worth writing if something
	# enforces them.
	if [ -f "$GAME/art/characters/humanoid_rig.glb" ]; then
		rig="$("$GODOT_BIN" --headless --path "$GAME" --script tests/rig_probe.gd 2>&1)"
		if printf '%s\n' "$rig" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
			echo "FAIL the shared humanoid rig" >&2
			printf '%s\n' "$rig" | grep -E 'FAIL|ERROR' | sed 's/^/      /' >&2
			exit 1
		fi
	fi
	# Every authored resource, loaded and validated (`M2-T08`, TEC-006
	# principle 4). Data rots the way a rig does — silently, and three tools
	# away from the symptom — and the rules it enforces are design rules that
	# would otherwise erode without anything failing.
	#
	# `--quit-after` is the same backstop the churn check uses: a GDScript
	# runtime error aborts the function it happens in, so a probe that errors
	# never reaches its own quit() and would hang the build forever.
	data="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 900 \
		--script tests/data_probe.gd 2>&1)"
	if printf '%s\n' "$data" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the authored data" >&2
		printf '%s\n' "$data" | grep -E 'FAIL|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# Does greed cost anything, and does putting it down buy anything back
	# (`M2-T01`)? The M2 gate is "a playtester voluntarily abandons loot to
	# survive", and that decision is only real if the floor holds more than the
	# bag does and if dropping something visibly returns speed and quiet.
	#
	# It runs in the sweep rather than by hand because every number it checks
	# is one a tuning edit can silently invert: a roomier grid, a lighter item,
	# a smaller clamor fraction. None of those breaks a test that only parses
	# code.
	bag="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --bag-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$bag" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the greed loop" >&2
		printf '%s\n' "$bag" | grep -E '\[bag\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **And can a player's hands reach it** (`M2-T18`, ADR-111)? The probe above
	# proves the bag's *rules* by calling `Inventory` and `Player` directly, and
	# every one of those assertions passed while the screen drawing them was a
	# `Control` of size 0 x 0 — so no click ever reached it, no item could be
	# picked up or dragged out, and the gesture `DES-005` calls the primal
	# counter-play did not exist for anybody using a mouse. Rules and reach are
	# different questions and only the first one had a check.
	bagui="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --bagui-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$bagui" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the bag has to be reachable" >&2
		printf '%s\n' "$bagui" | grep -E '\[bagui\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **And what the floor does about a body lying on it** (`M2-T21`, ADR-114).
	# Reported from play: enemies went on pathing to and swinging at a player
	# who had gone out, which achieved nothing — `Health.apply_damage` refuses
	# once dead — while holding their attention off whoever was coming to help.
	# The other half is the Gullsjúkr, which `DES-012` says stops for an ember
	# and never did: `con_ember` is worth 0 tribute against a floor of 20.
	#
	# In the Deep rather than the gym on purpose: the gym calls `_reset()` from
	# `health.died`, so downing a player there frees every enemy in the level.
	fallen="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 40000 \
		levels/room_set/room_set.tscn -- --fallen-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$fallen" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the fallen are not a target" >&2
		printf '%s\n' "$fallen" | grep -E '\[fallen\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **The profile on disk** (`M3-T06`, `TEC-003`, ADR-116). Round trip, the
	# two refusals, and the migration runner driven with a table the real one
	# cannot supply yet — there is no format older than v1 to come from, so
	# `MIGRATIONS` is empty while `walk()` runs on every load, which is exactly
	# how an algorithm ends up shipping unexercised (ADR-097).
	#
	# Boots no scene: its subject is an autoload and `SaveFile`, and neither has
	# a room. **`^ERROR:` is deliberately not a failure signal here** — this is
	# the one probe whose job includes driving the paths that push errors, so a
	# refused profile prints one on purpose. `PROBLEM`, `SCRIPT ERROR` and the
	# exit code are the signal.
	save="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 900 \
		-- --save-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$save" | grep -qE 'PROBLEM|FAIL|SCRIPT ERROR'; then
		echo "FAIL a profile has to survive a round trip and refuse what it cannot read" >&2
		printf '%s\n' "$save" | grep -E '\[save\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **What the pact costs** (`M3-T04`, `DES-003`, ADR-118). The curve rises
	# with rank and never falls, giving her something is what pays it, a partial
	# cycle is never punished (`PRO-005 §11`), a short one sends the Hunt early
	# and exactly once, and the whole pact dies with you.
	#
	# In the Chamber because that is where a Tithe is paid — the arithmetic
	# under test is the settle, and the settle is a Lair action.
	tithe="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 900 \
		levels/lair/chamber.tscn -- --tithe-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$tithe" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the Tithe has to cost something and die with you" >&2
		printf '%s\n' "$tithe" | grep -E '\[tithe\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **Is a rank-8 floor a different floor** (`M3-T10`, ADR-010, ADR-119)?
	#
	# `DES-022` is precise about what that may and may not mean — *"more things,
	# worse things, and less time, not because a skeleton hits for 40 instead of
	# 12"* — so this asserts the shape and, crucially, that **every enemy still
	# shares one stat line**. That is the half the design would lose first and
	# the half nothing else watches.
	#
	# It also guards the top of the tree: `Shaft._escalation` clamps at 1.0, so
	# a rank whose Hunt starts past `shaft_seal_seconds` opens with the Shaft
	# already at maximum cost and `DES-005`'s leave-now-or-later decision stops
	# existing exactly where the game is meant to be hardest. The first value
	# tried did that at rank 8.
	rank="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 20000 \
		levels/room_set/room_set.tscn -- --rank-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$rank" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL a rank-8 floor has to be a different floor" >&2
		printf '%s\n' "$rank" | grep -E '\[rank\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **Can a life begin** (`M3-T02`, `DES-011`, ADR-120)? The catalogue holds
	# what is authored, the screen has a rect a mouse can reach, pressing a
	# class swears it and stocks the kit, the oath cannot be taken back until
	# death, and the class shapes the **body the host builds** rather than only
	# the one on your own screen.
	#
	# The rect assertion is ADR-111 arriving a second time: a `Control` under a
	# `CanvasLayer` gets no layout, and at 0 x 0 Godot delivers it no mouse
	# events at all. That cost the whole of `M2-T18` to find on the bag.
	class_="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 3000 \
		-- --class-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$class_" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL a life has to be able to begin" >&2
		printf '%s\n' "$class_" | grep -E '\[class\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **The pact moves** (`M3-T01`, `DES-003`, `DES-004`, ADR-125). Pact Rank
	# sat at 1 for the whole of `M3-T04` and `M3-T10`, which built a nine-row
	# Tithe table and three axes of floor scaling against a number nothing
	# could change (ADR-124 §3). This is the check that it changes — that
	# surplus tribute becomes Boon and tribute inside the Tithe does not, that
	# spending raises rank and rank raises what she expects, that the effect
	# tags `TEC-006` puts every system behind read back, and that a **click**
	# reaches all of it.
	pact="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 3000 \
		levels/lair/chamber.tscn -- --pact-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$pact" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL power has to cost obligation" >&2
		printf '%s\n' "$pact" | grep -E '\[pact\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **She settles before the floor is built** (`M3-T04`, ADR-124). The soft
	# fail shipped at `M3-T04` and never once reached the floor it was written
	# for: `settle_cycle()` ran seventeen lines *after* `_build_hunt()`, so
	# every descent consumed the previous one's debt and the four minutes she
	# had just sent for waited for the next floor. Every part had a check —
	# `--tithe-probe` drives the settle, `--rank-probe` reads a floor's Hunt
	# age — and nothing asked whether the order let one reach the other.
	creditor="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 3000 \
		levels/room_set/room_set.tscn -- --creditor-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$creditor" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL a missed Tithe has to reach the floor it was missed for" >&2
		printf '%s\n' "$creditor" | grep -E '\[creditor\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **The Stalker** (`M3-T11`, `DES-011`, ADR-123). A bow, and a trap that
	# holds — *"including against the Hunter, the only reliable way to buy time
	# during the Sealing"*, which is the one sentence `DES-011` writes about
	# this verb and the reason it exists.
	#
	# Every "it stopped" row carries a **control on the same body**: snared for
	# a window, then released and measured over an identical one. The first
	# draft compared against a freshly spawned enemy and did not notice it had
	# already closed to 2.16 m and stopped — so "it did not move" was true of a
	# body standing in attack range, and the assertion could not fail. Fifth
	# true-but-beside-the-point assertion this milestone.
	stalker="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --stalker-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$stalker" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the quiet way out" >&2
		printf '%s\n' "$stalker" | grep -E '\[stalker\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **Respec** (`M3-T13`, `DES-004`, ADR-136). Two claims from the document
	# and one consequence of ADR-126: it costs real resources, it **cannot
	# change your keystone mid-life**, and giving a node back lowers rank —
	# so it lowers the Tithe, which is the coupling running in the direction it
	# is usually read backwards.
	#
	# The row that only this task can make: a respec is the **one thing in the
	# game that changes a tree inside a life**, so it is the only place the
	# effect push can be caught not happening (`M3-T12` found it by accident).
	respec="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 3000 \
		levels/lair/chamber.tscn -- --respec-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$respec" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL a build has to be a commitment" >&2
		printf '%s\n' "$respec" | grep -E '\[respec\]|\[pact\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **The Wing** (`M3-T12`, `DES-004`, ADR-135). Thirteen nodes against
	# machinery `M3-T01` already proved, so the row that matters is the one no
	# other check can make: **every effect tag reaches a system**. A node whose
	# tag nothing reads loads, validates, appears on the screen, sells for Boon
	# and does nothing — and passes every other check in this file.
	wing="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --wing-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$wing" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL get in, get out, never fight" >&2
		printf '%s\n' "$wing" | grep -E '\[wing\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **Evidence of what you did** (`M3-T08`, `DES-016`, ADR-134). The rule the
	# doc states most firmly is the one a naive build breaks first — **no popups
	# mid-run**, because they break the pressure the whole game rests on — so a
	# deed waits and surfaces at the Settle beat, after the tribute decision.
	#
	# The corpus guard is first for the reason the item one has it: every row
	# below is conditional on there being deeds, and an export that packs none is
	# otherwise a silent pass.
	deeds="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 3000 \
		levels/lair/chamber.tscn -- --deeds-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$deeds" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL a run has to end on evidence" >&2
		printf '%s\n' "$deeds" | grep -E '\[deeds\]|\[pact\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **She'll only remember three things** (`M3-T05`, ADR-003, ADR-006).
	#
	# `DES-003` calls the Legacy screen the anti-wipe-cliff mechanism and the
	# piece it feels strongest about. The rows that matter are the ones keeping
	# it a *bounded* decision: three slots and no fourth, never raw Boon, and
	# what comes back is Scarred and worth nothing to her — without that last
	# one a slot launders a hoard through a life you were going to lose.
	legacy="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 3000 \
		levels/lair/chamber.tscn -- --legacy-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$legacy" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL a death has to be a decision" >&2
		printf '%s\n' "$legacy" | grep -E '\[legacy\]|\[pact\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **A run you cannot walk away from** (`M3-T15`, ADR-050, ADR-132).
	#
	# ADR-050: *"disconnecting is never an escape from a bad run."* The load-
	# bearing row is that a run stays open across everything except an outcome —
	# and the one underneath it closes the exploit that a generous resume would
	# open, since a re-laid floor turns quit-and-relaunch into farming.
	#
	# **No `^ERROR:` in this grep, deliberately**, on `--save-probe`'s precedent
	# above: a dropped run file prints one on purpose, and the probe plants the
	# garbage itself. `FAIL`, `SCRIPT ERROR` and the exit code are the signal.
	run="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --run-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$run" | grep -qE 'FAIL|SCRIPT ERROR'; then
		echo "FAIL quitting has to cost what staying would have" >&2
		printf '%s\n' "$run" | grep -E '\[run\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **A party crosses a floor** (`M4-T01`, ADR-185, ADR-186).
	#
	# `--run-probe` above proves the run *file* can hold a floor index; this
	# proves the **game** moves one. Claiming a Shaft above the bottom descends
	# rather than extracts, the bag, the wound and the Hunt's age are written
	# down, and arriving one floor lower puts all three back on the body —
	# `DES-009` bans regeneration within a run, and ADR-015 makes a run three
	# floors, so a descent that healed you would be the one thing combat forbids.
	#
	# The last row is the one that keeps the game finishable: take the exit off
	# every Shaft and a run can be entered and never ended, which strands
	# `run.active` open and blocks every future descent.
	descent="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --descent-probe --seed=31346 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$descent" | grep -qE 'FAIL|SCRIPT ERROR'; then
		echo "FAIL a party has to arrive on the floor below with what it left with" >&2
		printf '%s\n' "$descent" | grep -E '\[descent\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **Darkness is a mechanic** (`M4-T13`, ADR-188, `ART-001`).
	#
	# Six rows, and the second is the one that matters: an enemy standing at a
	# distance *between* the lit and dark sight ranges must see a lit body and
	# not a shuttered one. Everything else here could be satisfied by a lamp
	# emitting photons nothing reads — which is precisely the shape ADR-098
	# keeps finding, and `check_dead.py` cannot see it because the names are
	# all alive.
	#
	# Run on a generated floor rather than the Deep: the rows need a floor with
	# doorway lamps on it and somewhere genuinely dark to stand, and the Deep
	# is six hand-placed rooms.
	lantern="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --lantern-probe --delvings \
		--seed=31346 --floor=1 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$lantern" | grep -qE 'FAIL|SCRIPT ERROR'; then
		echo "FAIL carrying a light has to be a decision, and something has to read it" >&2
		printf '%s\n' "$lantern" | grep -E '\[lantern\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **A dead player is still playing** (`M3-T14`, `DES-012`, ADR-130). The
	# Vordr, and the readout `GATE M3 COOP` has named as a precondition since
	# ADR-115 with no build ever having an answer for it.
	#
	# The loot row goes down carrying something, deliberately: the first draft
	# downed a player whose bag was already empty and read `0 item(s)` whether or
	# not anything was cleared, so a plant deleting the clear walked through it.
	vordr="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --vordr-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$vordr" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL a dead player has to still be playing" >&2
		printf '%s\n' "$vordr" | grep -E '\[vordr\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **Six slots, and a weapon whose numbers are finally read** (`M3-T07`,
	# `DES-020`, ADR-127). `WieldableTrait` carried windup, active, recovery,
	# damage and reach on four authored weapons and nothing consumed any of it
	# — `MeleeWeapon` swung one profile's numbers for every weapon in the game.
	#
	# The first row is the one the two-process smoke needed and nothing had:
	# **the body arrived armed**, without this probe equipping it. Every other
	# check here equips explicitly first, so all of them would pass on a body
	# that descends with empty hands — which is exactly what every client's
	# body had been doing since `M3-T02`.
	gear="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --gear-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$gear" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL what you are holding has to matter" >&2
		printf '%s\n' "$gear" | grep -E '\[gear\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **And what it costs to let the Gullsjúkr reach you** (`M2-T19`, ADR-112).
	# It used to cost nothing at all: it walked up, stopped at 24 cm, and stood
	# inside the player indefinitely with health and bag untouched. `DES-017`
	# lists five ways to deal with it and never said what happens if none of
	# them work, so nothing had anything to assert about arriving. It takes the
	# richest thing you carry now, never health, after a stoop you can back out
	# of, and what it takes lands on the floor where you can contest it.
	toll="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 30000 \
		levels/room_set/room_set.tscn -- --toll-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$toll" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the Hunt has to cost something" >&2
		printf '%s\n' "$toll" | grep -E '\[toll\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **What the heaviest thing on the floor costs to carry** (`M2-T17`,
	# ADR-110). This probe existed and nothing ran it — the only one in
	# `room_set.gd` that was never wired in here — so it had been **exiting 1**
	# unnoticed: the Prize is in the guarded half at the end of a loot table
	# that scales by taking a *prefix*, so at party size 1 it never spawned, and
	# the probe was teleporting to an empty floor, picking up nothing, and
	# reporting a 0% change in walk speed. A check nobody runs is a check that
	# is already failing.
	prize="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --prize-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$prize" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL greed has to weigh something" >&2
		printf '%s\n' "$prize" | grep -E '\[set\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# The gym's own two, wired in for the same reason (`M2-T17`). Both pass
	# today; neither was run by anything, and `--prize-probe` above is what a
	# probe nobody runs eventually looks like. `check_dead.py` cannot see this
	# class — the functions are referenced by their own dispatch, so the names
	# are alive and only the *running* of them is absent (ADR-098's own caveat).
	# `fight` measures what `combat` does not (`M4-T16`, ADR-194): `combat`
	# reports both fighters' anatomy and lethality, all of it correct, and
	# never asks whether the enemy lands a blow. It did not, for four of the
	# five weapons in the table, and every number `combat` printed stayed true
	# throughout.
	for gym_probe in clamor combat fight swarm; do
		gym="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
			levels/dev/movement_gym.tscn -- "--$gym_probe-probe" 2>&1)"
		if [[ $? -ne 0 ]] || printf '%s\n' "$gym" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
			echo "FAIL the gym's $gym_probe probe" >&2
			printf '%s\n' "$gym" | grep -E 'FAIL|ERROR' | sed 's/^/      /' >&2
			exit 1
		fi
	done

	# Does the Hunt hunt the way `DES-017` says (`M2-T02`)? Four claims, and
	# every one of them would be satisfied by an implementation that cheated:
	# it goes to the noise rather than to you, a rich silent player is found
	# anyway, a stripped-down one is not, and thrown gold reliably diverts it.
	#
	# The first is the one that matters most. `TEC-001` requires the Hunter to
	# navigate the clamor field and *not* the player's transform, and handing
	# it a transform is the single most likely shortcut anyone will take here —
	# it would look almost identical in play and be a lie the first time a
	# player tested it. Players test exactly this.
	hunt="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --hunt-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$hunt" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the Hunt" >&2
		printf '%s\n' "$hunt" | grep -E '\[hunt\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# Do both channels carry the same thing (`M2-T03`, ADR-036)? `DES-018`
	# requires a run to be completable with audio muted, which nothing automated
	# can play — but the way that guarantee actually breaks is an audio channel
	# with no visual twin, and that is checkable. Parity is asserted in both
	# directions, and the mix is made to move so a director reporting zeroes
	# forever cannot pass by being silent.
	# **Bodies move on the floor, and they do not know where you went**
	# (`M4-T16`, ADR-197). The second half is the one nothing else asks: an
	# enemy that quietly tracked a position it was never given would break
	# `PRO-005` §5's fairness rule while every other check stayed green.
	ground="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --ground-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$ground" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL an enemy that cannot use the floor, or knows too much" >&2
		printf '%s\n' "$ground" | grep -E 'FAIL|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	ear="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --ear-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$ear" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the twin channels" >&2
		printf '%s\n' "$ear" | grep -E '\[ear\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **Down, out, and down again** (`M3-T38`, ADR-160).
	#
	# Reported from play: descend, abandon at once, start another run, answer
	# the Legacy screen at the fire — and the hole does nothing, with a log that
	# simply stops. No error, no refusal, no scene change.
	#
	# **Nothing here had ever crossed a scene boundary in one process.** Every
	# probe above boots one level directly; `--menu-probe` instantiates levels
	# side by side without entering them; `run_doorway.py` is about two
	# processes walking through one door. A player's *second* descent of a
	# session crosses four scenes and rewrites half of `M3-T34`'s state table,
	# and no check in this project had ever walked it.
	#
	# Booted with no scene argument on purpose — through `run/main_scene`, which
	# is the front door and the only thing that opens a profile (`M3-T06`). The
	# scenario quits 0 when the second run begins and 1 when it does not.
	again="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 60000 \
		-- --again 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$again" | grep -qE 'FAIL|SCRIPT ERROR'; then
		echo "FAIL you have to be able to descend a second time" >&2
		printf '%s\n' "$again" | grep -E '\[again\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **And what it descends *into*** (`M4-T01`, ADR-187).
	#
	# This scenario is the only check that walks the real route — front door,
	# class, camp, hole — so it is the only one that can say what a **player**
	# lands on. `--delvings-probe` proves a generated floor can be built; this
	# proves the game builds one, which is ADR-098's second question and the
	# whole point of the task.
	#
	# It would revert silently: the descent chooses the Delvings on `RunFile`
	# having a run open, and every probe in this file runs unarmed and so gets
	# the Deep. Nothing else here would notice the game going back to six grey
	# rooms.
	if ! printf '%s\n' "$again" | grep -q '^\[delvings\]'; then
		echo "FAIL the descent opens onto the Deep, not the Delvings" >&2
		printf '%s\n' "$again" | grep -E '\[again\]|\[descent\]|\[delvings\]' \
			| sed 's/^/      /' >&2
		exit 1
	fi

	# Do both kinds of doorway hold (ADR-101, ADR-102)? `run_coop.py` never
	# changes scene and no single-process probe has a second peer to lose, so
	# every check in this file passed while walking from the Threshold into the
	# Deep disconnected both players — the peer outlives the level, and the new
	# level's session called `create_server` on a port it already held.
	#
	# ADR-102 added the other kind: a door exactly one player walks through.
	# Four faults were living in it at once, and the reason all four survived
	# is that the first version of this test asked one narrow question about
	# one door the whole party uses.
	doorway="$(GODOT="$GODOT_BIN" python3 "$ROOT/tools/run_doorway.py" 2>&1)"
	if [[ $? -ne 0 ]]; then
		echo "FAIL a doorway breaks co-op" >&2
		printf '%s\n' "$doorway" | sed 's/^/      /' >&2
		exit 1
	fi

	# **Hosting on a port somebody already holds** (`M2-T16`, ADR-108).
	#
	# `_start_host` used to `push_error` and return, which skipped the
	# `spawn_player` on its own last line and left the level standing with no
	# body and no camera — while the `OfflineMultiplayerPeer` underneath went on
	# answering `is_server()` true, so nothing downstream suspected anything.
	# ADR-107's grey screen, from a second direction, with the only trace in a
	# console the player is not reading. `_start_client` had always handled the
	# identical failure by giving up with a sentence, on the very next function.
	#
	# Every networked check in this project picks a free port on purpose, so
	# nothing anywhere had ever hosted twice on one. That is the whole reason
	# this survived: it is invisible unless two processes want the same port.
	busy_port=47071
	"$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/lair/threshold.tscn -- --host "--port=$busy_port" \
		>/dev/null 2>&1 &
	holder=$!
	sleep 3
	taken="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 4000 \
		levels/lair/threshold.tscn -- --host "--port=$busy_port" 2>&1)"
	kill "$holder" 2>/dev/null
	wait "$holder" 2>/dev/null
	# Godot logs "Couldn't create an ENet host" itself when the bind fails, and
	# that line is the condition under test rather than a fault — so the error
	# grep here is for everything *except* it.
	if ! printf '%s\n' "$taken" | grep -q 'gave up — Could not open the Threshold'; then
		echo "FAIL hosting on a taken port" >&2
		echo "      a second host on port $busy_port did not give up with a reason" >&2
		printf '%s\n' "$taken" | grep -E '\[coop|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi
	if printf '%s\n' "$taken" | grep -q 'hosting on'; then
		echo "FAIL hosting on a taken port" >&2
		echo "      a second host on port $busy_port claimed to be hosting" >&2
		exit 1
	fi
	if printf '%s\n' "$taken" | grep -qE 'SCRIPT ERROR|Unable to get unique ID|busy adding/removing'; then
		echo "FAIL hosting on a taken port" >&2
		echo "      giving up from inside _ready threw on the way to the menu" >&2
		printf '%s\n' "$taken" | grep -E 'SCRIPT ERROR|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# Does the game have a front door and a way back out of every room? Each
	# scene already has its own probe and all of them pass while the *loop
	# between them* is broken — a mistyped scene path fails only when somebody
	# presses the button, which in a playtest means it fails in front of a
	# tester who then stops reporting anything useful.
	#
	# It also carries the **control list** (`M3-T16`, ADR-137): `GATE M3 EXIT`
	# allows a tester no coaching beyond that screen, so an action it does not
	# name is an action that does not exist as far as the session is concerned.
	# Asked in both directions, and in the same boot as the menu walk because it
	# is the same screen family — a second launch would cost three seconds to
	# re-answer a question this one is already standing in front of.
	menu="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		ui/main_menu.tscn -- --menu-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$menu" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the way in and out" >&2
		printf '%s\n' "$menu" | grep -E '\[menu\]|\[controls\]|ERROR' \
			| sed 's/^/      /' >&2
		exit 1
	fi

	# Does each place sound like itself (`M2-T09`)? `ART-002`'s three sonic
	# worlds are three pieces, and the rule worth automating is the absolute
	# one: **the Hunter's instrument is used exactly once, anywhere, ever.**
	# When a player hears it, it is true — and a rule that survives only by
	# being remembered is one that gets broken by whoever needs a nice sound
	# late one night, months after anybody reads `ART-003`.
	camp="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/lair/threshold.tscn -- --threshold-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$camp" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the camp's own music" >&2
		printf '%s\n' "$camp" | grep -E '\[camp\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **The place** (`M4-T01`, `TEC-008`, ADR-175). The plan became metres, and
	# the row no other check can make is that the walls agree with the plan:
	# every doorway the plan opened is measured *through the wall*, because a
	# doorway the geometry sealed is a soft-lock no topology check can see.
	#
	# Also holds the worked-stone-to-cave gradient, which is what stops three
	# floors of an expedition being three sizes rather than three places.
	built="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 40000 \
		levels/room_set/room_set.tscn -- --build-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$built" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the plan is a place" >&2
		printf '%s\n' "$built" | grep -E '\[build\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **And the place is a level somebody could descend into** (`M4-T01`,
	# ADR-183). Everything above measures the floor; this boots one as the game
	# would — the same `_ready` that raises the Deep, handed a `DelvingsFloor` —
	# and asserts the things a player notices missing in the first ten seconds:
	# a way out, a Hunt, something to pick up, a light in the doorway, and a
	# body standing on the floor rather than inside it. None of that is visible
	# to a check that reads the plan.
	#
	# Two depths, because the roughness gradient means floor 0 and floor 2 are
	# different geometry and only one of them was ever booted by hand.
	for depth in 0 2; do
		delved="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 3000 \
			levels/room_set/room_set.tscn -- --delvings-probe --seed=31346 \
			--floor=$depth 2>&1)"
		if [[ $? -ne 0 ]] || printf '%s\n' "$delved" \
				| grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
			echo "FAIL the Delvings is a level (floor $depth)" >&2
			printf '%s\n' "$delved" | grep -E '\[delvings\]|ERROR' \
				| sed 's/^/      /' >&2
			exit 1
		fi
	done

	# **The floor** (`M4-T01`, `DES-015` step 4, ADR-170, ADR-172). The graph
	# became a space, and the row no other check can make is that it is still
	# the same space: connectivity is read back off the grid rather than taken
	# from the graph that asked for it. A corridor that opened into a third
	# room, or two rooms that ended up flush, would leave every topology
	# assertion passing about a floor that no longer matches — and the ADR-032
	# bypass is a claim about routes, so it becomes a claim about geometry the
	# moment geometry exists.
	#
	# Also asserts what the corpus can serve, because the failure mode when it
	# falls behind the generator is one unplaceable floor in a hundred.
	plan="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 120000 \
		levels/room_set/room_set.tscn -- --plan-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$plan" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the floor is the mission" >&2
		printf '%s\n' "$plan" | grep -E '\[plan\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **The mission graph** (`M4-T01`, `M4-T19`, `DES-015` step 3, ADR-169,
	# ADR-170). The probe existed from the day the generator did and nothing
	# ran it: ADR-169 describes it as the check that asserts determinism in
	# both directions, and until now that was true only when somebody typed it
	# by hand. `check_dead.py` could not see the gap either, because
	# `room_set.gd` calls its own handler — names, not reachability (ADR-098).
	#
	# The row no other check in this file can make is the second half of the
	# determinism claim. `check_determinism.py` proves *same seed, same world*
	# and is satisfied by a generator that ignores its seed entirely, which is
	# perfectly deterministic and useless. This asserts *different seed,
	# different graph* as well, plus `DES-015` step 8 over 400 seeds: nothing
	# unreachable, the ADR-032 bypass real, and the Prize inside the held arm.
	graph="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --graph-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$graph" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the floor poses a question" >&2
		printf '%s\n' "$graph" | grep -E '\[graph\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **Do the rooms ask anything** (`M4-T01` step 6, `DES-015` Layer 3,
	# ADR-192)? Every check above is about a floor's *shape* and passes cleanly
	# against one whose rooms are space with loot dealt into it by worth — which
	# is what the generator produced until machines existed.
	#
	# Wired in the same commit as the probe, deliberately. `M4-T19` is the task
	# that existed because `--graph-probe` was written, correct, and run by
	# nothing for weeks, and a second stage shipping the same way would be the
	# same ADR-098 finding with the lesson already written down.
	#
	# The row nothing else can make is *what a machine asks for reaches the
	# floor*: the stamper can decide beautifully and place nothing, and every
	# other assertion here would still pass.
	machine="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 60000 \
		levels/room_set/room_set.tscn -- --machine-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$machine" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the rooms pose questions" >&2
		printf '%s\n' "$machine" | grep -E '\[machine\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **Is anything drawn on top of anything else** (`M4-T20`, ADR-198)?
	#
	# The one question ten existing UI probes never asked, and the reported bug
	# twice — ADR-140 inside the bag, and "overlapping text in the
	# threshold/hoard areas". Both times every row was green, because a probe
	# reads a label's `text` and proves the string exists, never that a human
	# can see it.
	#
	# Headless is fine here and **only** here: this asserts the region grammar,
	# which is arithmetic over a viewport size with no text in it.
	#
	# The rows that measure a *live* screen cannot run here at all. Godot's
	# headless text server reports different metrics from a real one — the same
	# Chamber measures `PLACE` at 323×160 windowed and 323×353 headless, from
	# identical strings at an identical declared width — so a layout assertion
	# run headless measures the dummy renderer and reports fiction. That is
	# ADR-090's wall and ADR-093's rule, so those rows live in `--chamber-shot`
	# and `--threshold-shot`, which run windowed and which the interface brief
	# requires for any screen that changes.
	hud="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 60000 \
		levels/room_set/room_set.tscn -- --hud-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$hud" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL nothing overlaps anything" >&2
		printf '%s\n' "$hud" | grep -E '\[hud\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# Can a player *find* their way (`M2-T13`)? `--route-probe` has always
	# asserted a clean route exists and has always passed — it cannot see that
	# nobody could find it, which is exactly what six identically-lit box rooms
	# and a pale disc on the floor produced. This asserts the lighting language
	# instead: doorways lit, every room nameable, the way out visible from the
	# room every route crosses, and the game's one saturated colour spent on
	# treasure and nothing else.
	sight="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 900 \
		levels/room_set/room_set.tscn -- --sight-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$sight" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL you can see where to go" >&2
		printf '%s\n' "$sight" | grep -E '\[sight\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# The three ways a run ends up somewhere it cannot come back from
	# (`M2-T15`). One playtester found all of them in one sitting by walking
	# off the edge of the camp, abandoning, and descending to a grey screen:
	# there was no recovery from falling out of any level, abandoning left the
	# process with **no multiplayer peer at all** so nothing ever spawned
	# again, and the Chamber is a sibling of its level so a scene change left
	# it parented to the root with its private API still registered.
	edges="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 2400 \
		levels/lair/threshold.tscn -- --edges-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$edges" | grep -qE 'FAIL|SCRIPT ERROR'; then
		echo "FAIL you can always get back" >&2
		printf '%s\n' "$edges" | grep -E '\[edges\]' | sed 's/^/      /' >&2
		exit 1
	fi

	# Do the enemies path, or was a navmesh merely baked (`M2-T14`)? Two
	# different claims — the mesh baked cleanly with every doorway closed, six
	# navigable islands and no route between them, because Recast erodes by
	# whole cells and a 0.2 cell rounded a 0.45 m agent up to 0.6 m a side.
	# This asserts a route across the floor that *bends*, which a straight line
	# through three walls cannot.
	nav="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 900 \
		levels/room_set/room_set.tscn -- --nav-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$nav" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the enemies path around the level" >&2
		printf '%s\n' "$nav" | grep -E '\[nav\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **And is the floor actually walked** (`M3-T22`, ADR-144)? `--nav-probe`
	# asks whether a path *exists*; this walks a body out of every room and
	# asserts none of them is held on the geometry — which is the symptom that
	# was reported, and the one a path being available does not rule out.
	#
	# It also prints how much of each journey is spent scraping a wall. That is
	# a **number, not a threshold**: ADR-142 left three tuning questions open
	# (the Hunter's radius against the bake, avoidance, the direct-line range)
	# and every one of them wants a measurement to argue from at `M4-T01`.
	#
	# Twenty seconds of simulation, because `enemy_walk_speed` is 2 m/s and the
	# far corners are forty metres apart. The first draft ran four seconds and
	# measured nothing but how far a body gets in eight metres.
	walk="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 40000 \
		levels/room_set/room_set.tscn -- --walk-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$walk" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL a body walks out of every room" >&2
		printf '%s\n' "$walk" | grep -E '\[walk\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi
	printf '%s\n' "$walk" | grep -E '^\[walk\]' | sed 's/^/      /'

	# Can you leave, and does leaving late cost more (`M2-T04`)? The assertion
	# that earns its place is ADR-015's absolute: **the player is never truly
	# trapped.** A Sealing implemented as a lock satisfies every reading of
	# `DES-005`'s table and breaks that guarantee outright — planting exactly
	# that is what this refuses.
	#
	# **On the bottom floor, because that is where leaving happens** (ADR-186).
	# The Shaft is the way *down* on floors 0 and 1 and the Deep Gate's mechanism
	# at the bottom, so a probe about the way **out** has to say which floor it is
	# standing on. The Sealing curve it measures is the same either way — it is
	# `Shaft.channel_seconds()` in both roles — but the extraction row at the end
	# only exists here.
	exits="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 9000 \
		levels/room_set/room_set.tscn -- --exit-probe --floor=2 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$exits" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the way out" >&2
		printf '%s\n' "$exits" | grep -E '\[exit\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# Going down, bleeding out, and being carried home (`M2-T05`). The M2 co-op
	# gate is *"someone carries a friend's ember out and it is the best moment of
	# the session"* — whether it is the best moment is a playtest question,
	# whether it is possible is this. The solo half runs here; the half that
	# needs two people (a teammate's hand actually reaching across the wire) is
	# asserted in the co-op smoke below.
	#
	# **`--floor=2` for the same reason as `--exit-probe`** (ADR-186): the whole
	# scenario is an ember *reaching an extraction point*, and above the bottom
	# floor the Shaft descends instead. Found by this row going red, which is the
	# check doing its job — a rescue that silently took the party one floor deeper
	# instead of saving a life is precisely the regression worth catching.
	ember="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 12000 \
		levels/room_set/room_set.tscn -- --ember-probe --floor=2 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$ember" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL bear my ember out" >&2
		printf '%s\n' "$ember" | grep -E '\[ember\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# **And what happens to the player the run is finished with** (`M2-T16`,
	# ADR-108). `--ember-probe` above proves every link of the down → bleed →
	# ember → rescue chain, and then stands the player back up itself — so
	# every assertion this project made about death was made about a body the
	# measurement revived. Nobody had left one lying there, and lying there was
	# the bug. Both directions: a teammate standing keeps ADR-102's rule alive,
	# nobody standing ends the run, and getting up inside the window calls it
	# off.
	wipe="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 40000 \
		levels/room_set/room_set.tscn -- --wipe-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$wipe" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the run has to end" >&2
		printf '%s\n' "$wipe" | grep -E '\[wipe\]|\[death\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# Does the Settle beat settle anything (`M2-T06`)? `DES-003`'s three tiers,
	# made testable: what you carried is in your hands on arrival, tribute is
	# one-way and permanent, and **death wipes the stash and never the hoard.**
	# That last pair is the economy's whole self-correction — `DES-008`'s great
	# reset is why this design needs no late-game nerfs — and it is one line away
	# from being wrong in either direction.
	lair="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 6000 \
		levels/lair/chamber.tscn -- --lair-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$lair" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL the Settle beat" >&2
		printf '%s\n' "$lair" | grep -E '\[lair\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# Does party size still trade safety for yield and pressure (`M2-T07`)?
	# `DES-012` calls this the most important balance relationship in co-op, and
	# the failure it guards against is the classic one — four-player quietly
	# becomes the optimal farm and everybody abandons solo. **Per-capita loot
	# must fall and per-capita clamor must rise**, and both are one exponent
	# away from being wrong in a way no playtest notices for months.
	party="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 600 \
		levels/room_set/room_set.tscn -- --scaling-probe 2>&1)"
	if [[ $? -ne 0 ]] || printf '%s\n' "$party" | grep -qE 'FAIL|SCRIPT ERROR|^ERROR:'; then
		echo "FAIL party scaling" >&2
		printf '%s\n' "$party" | grep -E '\[party\]|ERROR' | sed 's/^/      /' >&2
		exit 1
	fi

	# Two processes, host and client, over loopback (`M1-T05`). This is the
	# only check in the sweep that exercises a *second* process, and it is the
	# only one that can: every claim in `TEC-004` is a claim that two peers
	# agree, and one process cannot disagree with itself.
	#
	# It runs here rather than in its own harness because the failures it
	# catches are ordinary code failures — a signal wired on the wrong peer, a
	# property that stopped replicating — and a check that lives somewhere
	# separate is a check that runs on a different day from the change that
	# broke it.
	coop="$(GODOT="$GODOT_BIN" python3 "$ROOT/tools/run_coop.py" --smoke 2>&1)"
	if [[ $? -ne 0 ]]; then
		echo "FAIL two players over localhost" >&2
		printf '%s\n' "$coop" | sed 's/^/      /' >&2
		exit 1
	fi
	echo "${#scripts[@]} script(s) parse clean, boots, survives teardown, rig intact,"
	echo "greed costs and dropping it pays, the Hunt tracks noise not transforms,"
	echo "every mix channel has a visual twin, the way out is never sealed shut,"
	echo "the fallen can be carried home, the hoard outlives every death,"
	echo "a bigger party is poorer and louder per head,"
	echo "each place sounds like itself and her note is hers alone,"
	echo "there is a front door and a way back out of every room,"
	echo "all three doorways hold and the whole party leaves together,"
	echo "the way out can be seen and the gold is the only warm thing,"
	echo "the enemies walk around the walls rather than into them,"
	echo "falling out of the world puts you back and abandoning is survivable,"
	echo "your own Chamber is somewhere you can stand and walk back out of,"
	echo "a run that nobody survives actually ends, a taken port says so,"
	echo "the Prize and the Waystone are on the floor at every party size,"
	echo "the bag takes a click and keeps its text inside its own box,"
	echo "the Gullsjukr takes your gold rather than your life,"
	echo "the fallen stop being a target and an ember survives the Hunt,"
	echo "a profile survives a round trip and refuses what it cannot read,"
	echo "the Tithe rises with rank, costs something, and dies with you,"
	echo "a rank-8 floor is denser and older without a bigger number on it,"
	echo "a guard costs stamina and never negates, and a life can begin,"
	echo "an arrow is loud where it lands and a Snare holds the Hunter,"
	echo "a missed Tithe reaches the floor it was missed for,"
	echo "surplus tribute buys nodes and every node she charges for,"
	echo "what you hold decides the swing and the pack decides the bag,"
	echo "the fallen can see what is happening to them and go on playing,"
	echo "a run stays open until it resolves and quitting is not an escape,"
	echo "a party arrives one floor down with its bag, its wounds and the Hunt,"
	echo "and walking into the hole opens onto a floor nobody drew by hand,"
	echo "carrying a light is a decision and something reads it,"
	echo "she remembers three things and they come back Scarred,"
	echo "a run ends on evidence and never interrupts itself to say so,"
	echo "the Wing gets out quietly and every node it sells does something,"
	echo "a build can be reconsidered and a keystone cannot,"
	echo "every floor the generator can emit poses a question and reads its seed,"
	echo "no two pieces of interface are allowed to sit in the same place,"
	echo "and the space built from it is still that floor,"
	echo "and the walls of that floor are where the plan put them,"
echo "every verb the game has is named on a screen a tester can find,"
echo "a body walks out of every room without sticking to it,"
	echo "two players over localhost host-authoritative ($("$GODOT_BIN" --version))"
else
	echo "${#scripts[@]} script(s) parse clean, no main scene yet ($("$GODOT_BIN" --version))"
fi
