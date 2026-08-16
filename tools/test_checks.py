#!/usr/bin/env python3
"""Prove that `status.py --check` actually fails on the things it claims to catch.

Usage:
    python3 tools/test_checks.py

A check that has never fired is not known to work — and these particular checks
guard decisions (ADR-064, ADR-065, ADR-066) rather than code, so nothing else
would notice if one silently stopped matching. Each trial plants one violation
in a real doc, asserts `--check` reports that specific issue code, and restores
the file.

Writes to `docs/` and restores in a `finally`, so an interrupted run still
leaves the tree clean. Run it on a clean working tree anyway.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from typing import NamedTuple

ROOT = Path(__file__).resolve().parent.parent
ROADMAP = ROOT / "docs" / "process" / "PRO-001-roadmap-and-milestones.md"
TEC005 = ROOT / "docs" / "tech" / "TEC-005-audio-technology.md"
TEC002 = ROOT / "docs" / "tech" / "TEC-002-project-structure.md"

# Every file this script can disturb, including the generated views, which
# `status.py --write` re-stamps with today's date. Restoring these verbatim is
# not optional: regenerating them instead leaves the tree dirty whenever the
# run crosses UTC midnight relative to the commit — which is precisely how CI
# caught this, since `--check` deliberately ignores the date stamp but
# `git diff` does not.
TOUCHED = [ROADMAP, TEC005, TEC002,
           ROOT / "docs" / "STATUS.md", ROOT / "docs" / "status.html"]


class Trial(NamedTuple):
    code: str       # the Issue code --check must report
    why: str        # the decision this check enforces
    path: Path
    old: str
    new: str


TRIALS = [
    Trial(
        "unpaired-placeholder", "ADR-064 — stub language needs a paired removal task",
        ROADMAP,
        "- [ ] `M1-T03` One hand-built room set, no generation",
        "- [ ] `M1-T03` One hand-built room set, placeholder doors for now",
    ),
    Trial(
        "milestone-ungated", "ADR-065 — a milestone with tasks needs an exit gate",
        ROADMAP,
        "> **GATE M5 EXIT** `pending`",
        "> **GATE-DISABLED M5 EXIT** `pending`",
    ),
    Trial(
        # TEC-006 is referenced by exactly one task, so dropping that reference
        # genuinely orphans it. A doc with two references would not.
        "doc-unscheduled", "ADR-065 — an accepted doc must be scheduled or parked",
        ROADMAP,
        "not the first thousand → TEC-006",
        "not the first thousand → TEC-001",
    ),
    Trial(
        "doc-parked-and-scheduled", "ADR-065 — parked and scheduled are exclusive",
        TEC005,
        "owner: tech",
        "owner: tech\nparked: exercising the exclusive-state check",
    ),
    Trial(
        # TEC-002 is implemented by exactly one task, M1-T08, which is done —
        # so it is the only doc that can be *fully* built today, and therefore
        # the only one able to exercise this check at all (ADR-071).
        "untuned", "ADR-071 — a fully built doc should not still hold ⟨tune⟩",
        TEC002,
        "## Build & release",
        "## Build & release ⟨tune⟩",
    ),
    Trial(
        # The shape that slipped past every other check: a heading meaning
        # "after the thing we are building", inside a doc that is scheduled.
        "deferred-unanchored", "ADR-077 — a section meaning 'later' names which later",
        TEC002,
        "## Build & release",
        "## Build & release, and future tooling beyond the core loop",
    ),
]


def run_check() -> str:
    proc = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "status.py"), "--check"],
        capture_output=True, text=True, cwd=ROOT,
    )
    return proc.stdout + proc.stderr


def run_trials() -> int:
    # Regenerate first, so the only failure a trial can produce is its own.
    subprocess.run([sys.executable, str(ROOT / "tools" / "status.py"), "--write"],
                   capture_output=True, text=True, cwd=ROOT, check=True)

    failures = 0
    for trial in TRIALS:
        original = trial.path.read_text(encoding="utf-8")
        if trial.old not in original:
            print(f"BROKEN  {trial.code}: anchor text not found in "
                  f"{trial.path.name} — update this trial", file=sys.stderr)
            failures += 1
            continue
        try:
            trial.path.write_text(original.replace(trial.old, trial.new, 1), encoding="utf-8")
            output = run_check()
        finally:
            trial.path.write_text(original, encoding="utf-8")

        if trial.code in output:
            print(f"ok      {trial.code:<26} {trial.why}")
        else:
            print(f"SILENT  {trial.code:<26} {trial.why}", file=sys.stderr)
            print("        planting the violation did not trigger it:", file=sys.stderr)
            print("\n".join("        " + line for line in output.splitlines()), file=sys.stderr)
            failures += 1
    return failures


def main() -> int:
    snapshot = {path: path.read_text(encoding="utf-8") for path in TOUCHED if path.exists()}
    try:
        failures = run_trials()
    finally:
        # Byte-for-byte, so the working tree is exactly as it was found.
        for path, text in snapshot.items():
            if path.read_text(encoding="utf-8") != text:
                path.write_text(text, encoding="utf-8")

    if failures:
        print(f"\n{failures} of {len(TRIALS)} check(s) did not fire", file=sys.stderr)
        return 1
    print(f"\n{len(TRIALS)} check(s) fire as specified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
