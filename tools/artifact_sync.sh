#!/usr/bin/env bash
# PostToolUse(Bash) hook — keep the published descent board in step with main.
#
# A shell hook cannot publish an Artifact; only the agent can call that tool.
# So this script does the deterministic half — notice the push, rebuild the
# publishable fragment — and hands the agent the instruction to republish.
#
# It fires only when BOTH hold:
#   1. the command mentioned `git push`, and
#   2. HEAD now matches its upstream — git advances the tracking ref only on a
#      push that actually landed, so a rejected push cannot be mistaken for a
#      successful one, and no network round-trip is needed to tell them apart.
#
# Silence is the default. Every failure path exits 0 without output: a stale
# link is a nuisance, a hook that blocks a push is a much worse one.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$REPO/tools/artifact.json"
TMPROOT="${TMPDIR:-/tmp}"
FRAGMENT="${TMPROOT%/}/she-descent-board.html"

payload="$(cat)"
ran="$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null)" || exit 0

# Substring, not prefix: pushes are usually the tail of `... && git push`.
case "$ran" in
  *"git push"*) ;;
  *) exit 0 ;;
esac

[ -f "$TARGET" ] || exit 0
cd "$REPO" || exit 0

head="$(git rev-parse HEAD 2>/dev/null)" || exit 0
upstream="$(git rev-parse '@{u}' 2>/dev/null)" || exit 0
[ "$head" = "$upstream" ] || exit 0

url="$(jq -r '.url // ""' "$TARGET" 2>/dev/null)"
favicon="$(jq -r '.favicon // "🐉"' "$TARGET" 2>/dev/null)"
[ -n "$url" ] || exit 0

if ! python3 tools/status.py --fragment "$FRAGMENT" >/dev/null 2>&1; then
  printf '%s\n' '{"systemMessage":"Descent board fragment failed to build — the published artifact is now stale. Run: python3 tools/status.py --check"}'
  exit 0
fi

short="${head:0:7}"

jq -n --arg f "$FRAGMENT" --arg u "$url" --arg h "$short" --arg i "$favicon" '{
  systemMessage: ("Push landed at " + $h + " — descent board rebuilt, republishing."),
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: (
      "A push to origin just landed (" + $h + "), so the published descent board is out of date. "
      + "Republish it now, before replying: call the Artifact tool with file_path \"" + $f
      + "\", url \"" + $u + "\", and favicon \"" + $i + "\". "
      + "Passing that exact url updates the existing artifact in place — omitting it creates a "
      + "second, orphaned one. The fragment is already regenerated from the current PRO-001; do "
      + "not rewrite or re-render it. Afterwards mention the refreshed board in one short line."
    )
  }
}'
