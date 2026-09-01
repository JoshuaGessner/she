#!/usr/bin/env python3
"""M1-T07 — same seed, two processes, identical layout hash (TEC-004).

Usage:
    python3 tools/check_determinism.py            # two processes, compare
    python3 tools/check_determinism.py --runs 4   # more, for flushing out flakes

TEC-004 requires generation to be bit-exact *across machines*, because the host
sends a seed and clients build the floor from it rather than receiving geometry.
Two processes on one machine cannot prove that, and this does not claim to —
what it catches is variance the engine and the traversal introduce, which is
the failure mode TEC-004 actually names: Dictionary iteration order, float
accumulation, and node ordering.

Separate PROCESSES rather than two builds inside one, deliberately. A single
process shares its RNG state, its allocator and its scene tree, so it will agree
with itself even when two machines would not.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
SCENE = "res://levels/room_set/room_set.tscn"

HASH_RE = re.compile(r"^\[hash\] ([0-9a-f]{64})$", re.MULTILINE)
COUNT_RE = re.compile(r"^\[hash\] seed -?\d+, entries (\d+), generated (\d+)$",
                      re.MULTILINE)

GODOT_CANDIDATES = [
    "godot", "godot4",
    "/Applications/Godot.app/Contents/MacOS/Godot",
    "/Applications/Godot_mono.app/Contents/MacOS/Godot",
]


def find_godot() -> str:
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    for candidate in GODOT_CANDIDATES:
        found = shutil.which(candidate)
        if found:
            return found
    print("godot not found — set GODOT=/path/to/godot", file=sys.stderr)
    raise SystemExit(1)


def build(godot: str, seed: int) -> tuple[str, str, str]:
    proc = subprocess.run(
        [godot, "--headless", "--path", str(GAME), "--quit-after", "900", SCENE,
         "--", "--hash", f"--seed={seed}"],
        capture_output=True, text=True,
    )
    output = proc.stdout + proc.stderr
    digest = HASH_RE.search(output)
    count = COUNT_RE.search(output)
    return (digest.group(1) if digest else "",
            count.group(1) if count else "?",
            output)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runs", type=int, default=2)
    parser.add_argument("--seed", type=int, default=20260816)
    args = parser.parse_args()

    godot = find_godot()
    print(f"seed {args.seed} · {args.runs} independent processes")

    digests: list[str] = []
    for i in range(args.runs):
        digest, count, output = build(godot, args.seed)
        if not digest:
            print(f"\nrun {i + 1} produced no hash — engine output follows:",
                  file=sys.stderr)
            print(output, file=sys.stderr)
            return 1
        digests.append(digest)
        print(f"  run {i + 1}   {count:>4} entries   {digest[:16]}…")

    if len(set(digests)) != 1:
        print(f"\nNON-DETERMINISTIC — {len(set(digests))} distinct hashes "
              "from one seed", file=sys.stderr)
        print("→ TEC-004: never consume a gameplay RNG stream from code whose "
              "call order can vary, and prefer integer/grid maths where layout "
              "is decided", file=sys.stderr)
        return 1

    # ── and the other direction ──────────────────────────────────────────────
    #
    # Same seed, same world is half a guarantee, and it is the half that a
    # generator ignoring its seed passes perfectly. This harness asserted only
    # that half from M1-T07 until M4-T01, over six literal AABBs — so it proved
    # the engine introduced no variance and could not prove anything about the
    # generator (ADR-169). Both directions, always, in every stage added.
    other = args.seed ^ 0x5DEECE66D
    apart, _, output = build(godot, other)
    if not apart:
        print(f"\nseed {other} produced no hash — engine output follows:",
              file=sys.stderr)
        print(output, file=sys.stderr)
        return 1
    print(f"  seed {other}   {apart[:16]}…")

    if apart == digests[0]:
        print(f"\nSEED IGNORED — seeds {args.seed} and {other} built the same "
              "world", file=sys.stderr)
        print("→ a generator that ignores its input is perfectly deterministic "
              "and completely useless; this is the half of TEC-004 that only "
              "this row can see", file=sys.stderr)
        return 1

    print("\nDETERMINISTIC — every process agreed, and a different seed "
          "built a different world")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
