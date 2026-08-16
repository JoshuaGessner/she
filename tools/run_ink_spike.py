#!/usr/bin/env python3
"""M1-T09 — capture the ink shader spike for the go/no-go call (ART-005, ADR-062).

Usage:
    python3 tools/run_ink_spike.py [--out DIR] [--frames 48] [--fps 12]

Produces, in DIR:
    still_raw.png / still_clean.png / still_wobble.png / still_ink.png
    still_ink_paper.png
    boil.gif

Why a GIF and not just stills: **the boil is a temporal effect and a still
cannot show it.** ART-005 calls it "the cheapest, highest-impact line in this
document", and the entire gate turns on whether it reads as hand-drawn — so a
judgement made from stills alone would be a judgement about edge detection,
which is not the question ADR-062 asked.

The camera is deliberately static during the sequence. If the shimmer only
reads while the camera turns, that is camera motion being mistaken for
hand-drawn quality.

Needs a real GPU context — Godot's `--headless` disables rendering entirely, so
this opens a window briefly.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
SCENE = "res://tests/ink_spike/ink_spike.tscn"

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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default=str(ROOT / "build" / "ink_spike"))
    parser.add_argument("--frames", type=int, default=48)
    parser.add_argument("--fps", type=float, default=12.0)
    parser.add_argument("--keep-frames", action="store_true",
                        help="keep the PNG sequence for frame-level inspection")
    args = parser.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for stale in out.glob("*.png"):
        stale.unlink()

    proc = subprocess.run(
        [find_godot(), "--path", str(GAME), SCENE, "--",
         f"--capture={out}", f"--frames={args.frames}", f"--fps={args.fps}"],
        capture_output=True, text=True,
    )
    output = (proc.stdout or "") + (proc.stderr or "")
    problems = [ln for ln in output.splitlines()
                if "ERROR" in ln or "SHADER ERROR" in ln or "Parse Error" in ln]
    if problems:
        print("\n".join(problems), file=sys.stderr)

    frames = sorted(out.glob("boil_*.png"))
    stills = sorted(out.glob("still_*.png"))
    if not frames or not stills:
        print("\ncapture produced nothing — engine output follows:", file=sys.stderr)
        print(output, file=sys.stderr)
        return 1

    try:
        from PIL import Image
    except ImportError:
        print(f"{len(frames)} frames in {out}; install Pillow to assemble the GIF")
        return 0

    images = [Image.open(f).convert("RGB") for f in frames]
    # Halve it: a 1152x648 GIF is enormous and the boil reads fine at this size.
    small = [im.resize((im.width // 2, im.height // 2), Image.LANCZOS) for im in images]
    gif = out / "boil.gif"
    small[0].save(
        gif, save_all=True, append_images=small[1:],
        duration=int(1000 / args.fps), loop=0, optimize=True,
    )
    if not args.keep_frames:
        for f in frames:
            f.unlink()

    print(f"stills: {len(stills)}  ·  {gif} ({gif.stat().st_size // 1024} KB, "
          f"{len(small)} frames @ {args.fps:g} fps)")
    for s in stills:
        print(f"  {s}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
