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

failed=0
for script in "${scripts[@]}"; do
	output="$("$GODOT_BIN" --headless --path "$GAME" --check-only --script "$script" 2>&1)"
	if diagnostics="$(printf '%s\n' "$output" | grep -E 'SCRIPT ERROR|Parse Error|^ERROR:')"; then
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

echo "${#scripts[@]} script(s) parse clean ($("$GODOT_BIN" --version))"
