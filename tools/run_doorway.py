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

Two doors, because there are two kinds.

**The party door** — the Descent, which everybody walks through together. That
is what the first version covered, and its assertion was deliberately narrow:
after the transition, does the host still have a peer and the client still have
a host?

**The private door** — a Chamber, which exactly one player walks through while
the others stay where they are. Nothing covered it, and ADR-102 found four
faults living in it at once: the client lost its camera, lost its body on the
way back, and both endgame transitions acted on the wrong peer. Narrowness is
how all four survived a green sweep, so this half asks the blunt questions
instead: afterwards, does everyone still have a body, and is it the same seat?
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
# The private door needs a visit and a return on top of a connect.
PRIVATE_SECONDS = 34


def launch(args: list[str]) -> subprocess.Popen:
    return subprocess.Popen(
        [GODOT, "--headless", "--path", str(GAME), "--quit-after", "9000",
         "levels/lair/threshold.tscn", "--"] + args,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)


def run(probe: str, port: int, seconds: int) -> dict[str, str]:
    """One scenario: a host, a client, and a door."""
    host = launch(["--host", f"--port={port}", probe])
    time.sleep(3.0)
    client = launch(["--join=127.0.0.1", f"--port={port}", probe])

    # Both stopped on **one** deadline, then both read. Reading them in turn
    # killed the host first, and the client — still running — dutifully
    # reported the host vanishing and gave up, which reads in the results as a
    # dropped connection the product never dropped.
    time.sleep(seconds)
    for process in (host, client):
        process.kill()
    return {"host": host.communicate()[0] or "",
            "client": client.communicate()[0] or ""}


def census(log: str, tag: str) -> dict[str, str] | None:
    """The census line a peer printed for one phase.

    First match, not last. A client that returns from its Chamber builds a
    second Threshold, and reading the last `before` would report the state of
    a process that had already lost everything — which looked like the client
    never having a body at all.
    """
    found = None
    pattern = re.compile(
        r"\[chamber\] \w+ " + tag + r" bodies=(\d+) mine=(\w+) slot=(-?\d+)")
    for line in log.splitlines():
        match = pattern.search(line)
        if match and found is None:
            found = {"bodies": match.group(1), "mine": match.group(2),
                     "slot": match.group(3)}
    return found


def main() -> int:
    logs = run("--doorway-probe", PORT, SECONDS)

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

    # ── the private door ──────────────────────────────────────────────────
    private = run("--chamber-probe", PORT + 1, PRIVATE_SECONDS)

    before = census(private["client"], "before")
    rows.append(("the client had a body to begin with",
                 before is not None and before["mine"] == "yes",
                 "slot " + before["slot"] if before else "no census"))

    # The Chamber is one player's. The host must not be moved by it, which is
    # exactly what a host-only extraction handler used to do.
    stayed = census(private["host"], "settled") is not None
    rows.append(("the host stayed where it was", stayed,
                 "still at the fire" if stayed else "left with them"))

    after = census(private["client"], "settled")
    rows.append(("the client came back with a body",
                 after is not None and after["mine"] == "yes",
                 "mine=" + after["mine"] if after else "never came back"))

    same_seat = (before is not None and after is not None
                 and before["slot"] == after["slot"])
    rows.append(("and came back as the same person", same_seat,
                 (before["slot"] + " -> " + after["slot"])
                 if before and after else "no seat to compare"))

    whole = after is not None and after["bodies"] == "2"
    rows.append(("with everyone else still there", whole,
                 after["bodies"] + " bodies" if after else "nothing to count"))

    for who in ("host", "client"):
        clean = ("Node not found" not in private[who]
                 and "Cannot call RPC" not in private[who])
        rows.append(("no packets into freed nodes, on the " + who, clean,
                     "clean" if clean else "orphaned paths"))

    # And nothing threw on the way through (`M2-T16`, ADR-108).
    #
    # This asked about packets into freed nodes and about the census, and about
    # nothing else — so a `SCRIPT ERROR` could print inside a run this reported
    # as passing, which is exactly what happened: a client walking into its
    # Chamber has its camp body despawned, and the Reticle kept reading it for
    # the frame between leaving the tree and being freed. Both doors, because a
    # thrown error is never acceptable in either.
    for label, source in (("party", logs), ("private", private)):
        for who in ("host", "client"):
            quiet = "SCRIPT ERROR" not in source[who]
            errors = sum(1 for line in source[who].splitlines()
                         if "SCRIPT ERROR" in line)
            rows.append((f"nothing threw — {label} door, {who}", quiet,
                         "quiet" if quiet else f"{errors} script error(s)"))

    ok = True
    print()
    for label, passed, detail in rows:
        ok = ok and passed
        print(f"  {label:<44}{detail:<26}{'ok' if passed else 'FAIL'}")

    if not ok:
        print("\nDOORWAY FAILED — a scene change breaks co-op", file=sys.stderr)
        for label, source in (("party door", logs), ("private door", private)):
            for name in ("host", "client"):
                print(f"\n--- {label}: {name} ---", file=sys.stderr)
                for line in source[name].splitlines():
                    if re.search(r"chamber|coop|ERROR|SCRIPT", line):
                        print(f"    {line}", file=sys.stderr)
        return 1

    print("\nboth kinds of doorway hold — verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
