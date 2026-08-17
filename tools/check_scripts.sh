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
	churn="$("$GODOT_BIN" --headless --path "$GAME" --quit-after 900 -- --lifecycle-probe 2>&1)"
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
	echo "two players over localhost host-authoritative ($("$GODOT_BIN" --version))"
else
	echo "${#scripts[@]} script(s) parse clean, no main scene yet ($("$GODOT_BIN" --version))"
fi
