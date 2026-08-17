#!/usr/bin/env python3
"""Prove a co-op connection survives walking through a door.

Usage:
    python3 tools/run_doorway.py

Two processes, a real ENet connection, and then the host changes scene. Until
ADR-101 that killed co-op outright: the peer lives on the `SceneTree` and
outlives the level, so the *new* level's `CoopSession` called `create_server`
again on a port it already owned, failed, and left both sides holding a
connection nobody was serving.

Nothing in the sweep could see it. `run_coop.py` never changes scene, and every
single-process probe has no second peer to lose. It is the same shape as
ADR-097 and ADR-100 — code that is correct until the game does something no
check does — and the only way to catch it is to make two processes walk through
a door.

The assertion is deliberately narrow: after the transition, does the host still
have a peer and does the client still have a host? Anything more belongs in
`run_coop.py`, which owns the authority split.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
PORT = 47019  # not run_coop's, so the two can be run at once

GODOT = os.environ.get("GODOT", "godot")
# Long enough to connect, walk through, and settle on the far side.
SECONDS = 25


def launch(args: list[str]) -> subprocess.Popen:
    return subprocess.Popen(
        [GODOT, "--headless", "--path", str(GAME), "--quit-after", "4000",
         "levels/lair/threshold.tscn", "--"] + args,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)


def main() -> int:
    host = launch(["--host", f"--port={PORT}", "--doorway-probe"])
    time.sleep(3.0)
    client = launch([f"--join=127.0.0.1", f"--port={PORT}"])

    logs: dict[str, str] = {}
    for name, process in (("host", host), ("client", client)):
        try:
            logs[name] = process.communicate(timeout=SECONDS)[0] or ""
        except subprocess.TimeoutExpired:
            process.kill()
            logs[name] = process.communicate()[0] or ""

    rows: list[tuple[str, bool, str]] = []

    joined = "peer" in logs["host"] and "joined" in logs["host"]
    rows.append(("the client reached the host", joined,
                 "peer joined" if joined else "never connected"))

    # The transition itself, and the failure it used to produce.
    adopted = "adopted the existing connection" in logs["host"]
    rows.append(("the host kept its connection through the door", adopted,
                 "adopted" if adopted else "built a new session"))

    refused = "Couldn't create an ENet host" in logs["host"] \
        or "create_server" in logs["host"]
    rows.append(("and did not fight itself for the port", not refused,
                 "clean" if not refused else "create_server failed"))

    followed = "adopted the existing connection" in logs["client"]
    rows.append(("the client followed it down", followed,
                 "adopted" if followed else "did not follow"))

    lost = "gave up" in logs["client"]
    rows.append(("nobody was dropped", not lost,
                 "held" if not lost else "client gave up"))

    ok = True
    print()
    for label, passed, detail in rows:
        ok = ok and passed
        print(f"  {label:<44}{detail:<26}{'ok' if passed else 'FAIL'}")

    if not ok:
        print("\nDOORWAY FAILED — a scene change breaks co-op", file=sys.stderr)
        for name in ("host", "client"):
            print(f"\n--- {name} ---", file=sys.stderr)
            for line in logs[name].splitlines():
                if re.search(r"coop|ERROR|SCRIPT", line):
                    print(f"    {line}", file=sys.stderr)
        return 1

    print("\na connection survives a doorway — verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
