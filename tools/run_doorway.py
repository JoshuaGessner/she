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

import own_user_dir

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
PORT = 47019  # not run_coop's, so the two can be run at once

GODOT = os.environ.get("GODOT", "godot")
# Long enough to connect, walk through, and settle on the far side.
SECONDS = 25
# The private door needs a visit and a return on top of a connect.
PRIVATE_SECONDS = 34


# The two doors this file walks. Extraction starts in the Deep, so it cannot
# reuse the Threshold launch the other scenarios share.
CAMP = "levels/lair/threshold.tscn"
DEEP = "levels/room_set/room_set.tscn"
# A three-player party, because that is the size the crash was reported at —
# though it reproduces at two, and asserting it at three costs one process.
EXTRACT_CLIENTS = 2
EXTRACT_SECONDS = 44   # M3-T09: every peer extracts in turn now, not just the host
# The host spends its own body at ~7 s of its own clock and then holds for
# `party_wipe_seconds` + 1.5 to prove the run has *not* ended with a teammate
# standing. The client is killed after that, so the party ends by departure
# rather than by death.
LEFT_BEHIND_KILL = 16
# Long enough for the wipe window, the run-over screen, and the walk home.
LEFT_BEHIND_SETTLE = 18


def launch(args: list[str], scene: str = CAMP,
           slot: str = "host") -> subprocess.Popen:
    """One process, with a `user://` no other process in this run can reach.

    The separation is not tidiness. Every peer opens its own run file at the
    descent and settles its own profile at the end, so a scenario sharing one
    `user://` has the host's clear standing in for the client's — and the row
    about the client passes without the client having done anything (ADR-155).
    """
    return subprocess.Popen(
        [GODOT, "--headless", "--path", str(GAME), "--quit-after", "60000",
         scene, "--"] + args,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        env=own_user_dir.env_for(slot))


def run_extraction(port: int) -> dict[str, str]:
    """**The whole party leaving the floor together** (`M2-T20`, ADR-113).

    Nothing in this project had ever extracted with a second process in the
    room. `run_coop.py` and the two scenarios above never reach an exit, and
    `--exit-probe` is solo *and* sets `_probing`, which swaps the scene change
    for `_reset_floor` — so the one check that spends a Waystone deliberately
    skips the line that was broken.

    What it was hiding: taking the host's own outcome changes scene, Godot
    detaches the outgoing scene synchronously, and the rest of `_end_the_run`
    then ran on a node with no `multiplayer`. The host was always index 0, so
    **no client had ever been sent its haul** — silently before `M2-T16`, and
    as a hard crash after it.
    """
    procs: dict[str, subprocess.Popen] = {
        "host": launch(["--host", f"--port={port}", "--extraction"], DEEP,
                       "host")}
    time.sleep(3.0)
    for index in range(EXTRACT_CLIENTS):
        procs[f"client{index}"] = launch(
            [f"--join={'127.0.0.1'}", f"--port={port}", "--extraction"], DEEP,
            f"client{index}")
        time.sleep(1.0)
    # One deadline for everybody, for the reason `run` gives above: killing them
    # in turn makes the survivors report a disconnect the product never had.
    time.sleep(EXTRACT_SECONDS)
    for process in procs.values():
        process.kill()
    return {name: (p.communicate()[0] or "") for name, p in procs.items()}


def run_left_behind(port: int) -> dict[str, str]:
    """**The last person standing leaves, and the run has to end** (`M3-T35`).

    Run resolution was reachable from a death and from an extraction and from
    nowhere else, so a party that ended because somebody *left* was never
    re-examined — the host lay spent on a floor that kept running, with no way
    out but ABANDON, which costs the life.

    **This is the one scenario that kills a process on purpose.** The comment
    on `run` above warns that stopping peers in turn makes the survivor report
    a disconnect the product never had; here the disconnect *is* the subject,
    so the client is killed first and deliberately, and the host is given a
    settle window of its own afterwards.
    """
    host = launch(["--host", f"--port={port}", "--abandoned"], DEEP, "host")
    time.sleep(3.0)
    client = launch(["--join=127.0.0.1", f"--port={port}", "--abandoned"],
                    DEEP, "client0")
    time.sleep(LEFT_BEHIND_KILL)
    client.kill()
    left = client.communicate()[0] or ""
    # Read after the kill rather than at the end, because the host runs on for
    # another window and reading them together would mean waiting to find out
    # whether the client had even reached the floor.
    time.sleep(LEFT_BEHIND_SETTLE)
    host.kill()
    return {"host": host.communicate()[0] or "", "client0": left}


def run(probe: str, port: int, seconds: int) -> dict[str, str]:
    """One scenario: a host, a client, and a door."""
    host = launch(["--host", f"--port={port}", probe], CAMP, "host")
    time.sleep(3.0)
    client = launch(["--join=127.0.0.1", f"--port={port}", probe], CAMP,
                    "client0")

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

    # ── the way out ───────────────────────────────────────────────────────
    leaving = run_extraction(PORT + 2)

    for name, log in leaving.items():
        arrived = "arrived at the Threshold" in log
        rows.append((f"{name} left the floor", arrived,
                     "at the fire" if arrived else "STRANDED in the Deep"))

    # **One player leaves and the floor stays open** (`M3-T09`, ADR-131).
    #
    # The row above says everybody eventually got home, which was the whole
    # claim while extraction ended the run for the party at the first Waystone.
    # It is now the *weaker* half: a host that leaves must not take the floor
    # with it, and "everybody arrived" is equally true of a build that sends
    # them all home the instant the first one spends a stone.
    #
    # The host prints how many bodies were still in the run after the first
    # extraction resolved. Anything but a positive number means the party left
    # together, which is the behaviour this task exists to end.
    staggered = re.search(r"one out, (\d+) still on the floor", leaving["host"])
    left_behind = int(staggered.group(1)) if staggered else 0
    rows.append(("the floor stayed open after the first left",
                 left_behind > 0,
                 f"{left_behind} still down there" if staggered
                 else "the host never reported"))

    for name, log in leaving.items():
        quiet = "SCRIPT ERROR" not in log
        rows.append((f"nothing threw — extraction, {name}", quiet,
                     "quiet" if quiet else "script error"))

    # The host is the one that changes scene, so it is the one whose haul
    # proves the outcome was taken rather than lost with the level.
    kept = "carried=1" in leaving["host"]
    rows.append(("and the host kept what it carried out", kept,
                 "1 item" if kept else "haul lost in the transition"))

    # **A run that resolved is closed for everyone who was in it** (`M3-T34`,
    # ADR-155, invariant 2).
    #
    # `RunFile.clear()` lived inside `_end_the_run`, which returns on its first
    # line for anything that is not the host — so `user://run.active` survived
    # every run a client came home from *alive*, and `PauseMenu` then priced
    # walking out of camp at the whole life (ADR-152). Read per peer, because
    # the fault is per peer: a row that looked at the host alone passed against
    # the broken build, and one run against a shared `user://` would have had
    # the host's clear answering for the client.
    for name, log in leaving.items():
        said = re.search(r"\[extract\] \w+ at the fire, run still open=(\w+), "
                         r"leaving ends the life=(\w+)", log)
        rows.append((f"{name} closed its run on the way out",
                     said is not None and said.group(1) == "false",
                     "closed" if said and said.group(1) == "false"
                     else ("STILL OPEN" if said else "never reached the fire")))
        # The half a player actually meets. Kept separate from the row above so
        # a future build that clears the file without fixing the menu — or the
        # reverse — fails the half that is wrong rather than both or neither.
        rows.append((f"and {name} can leave the fire for nothing",
                     said is not None and said.group(2) == "false",
                     "TO THE MENU" if said and said.group(2) == "false"
                     else ("ABANDON THE RUN" if said else "never reported")))

    # ── somebody leaves, and the run ends ─────────────────────────────────
    behind = run_left_behind(PORT + 3)

    reached = "client standing on the floor" in behind["client0"]
    rows.append(("the client was on the floor to leave it", reached,
                 "standing" if reached else "never got there"))

    # The precondition, and it is half the assertion: a party with somebody
    # still standing must **not** end when one member goes out (ADR-102). A
    # build that ended the run on the first death would satisfy the row below
    # for entirely the wrong reason.
    held = re.search(r"\[left\] host is out, spent=(\w+), still in the Deep=(\w+)",
                     behind["host"])
    rows.append(("one out, one standing, and the floor stayed",
                 held is not None and held.group(1) == "true"
                 and held.group(2) == "true",
                 "held" if held and held.group(2) == "true"
                 else ("ended too early" if held else "host never went out")))

    # The fault itself. Nothing was watching for a party that shrinks by
    # departure, so the host lay there until `--quit-after` killed it.
    ended = "[left] nobody is left in the run" in behind["host"]
    rows.append(("and ended once the last of them left", ended,
                 "resolved" if ended else "STRANDED — nothing re-checked"))

    got_home = "arrived at the Threshold" in behind["host"]
    rows.append(("the one left behind got home", got_home,
                 "at the fire" if got_home else "still in the Deep"))

    closed = re.search(r"\[extract\] host at the fire, run still open=(\w+)",
                       behind["host"])
    rows.append(("with its run closed behind it",
                 closed is not None and closed.group(1) == "false",
                 "closed" if closed and closed.group(1) == "false"
                 else ("STILL OPEN" if closed else "never reported")))

    for name, log in behind.items():
        # The client is killed mid-frame on purpose, so its own log is allowed
        # to stop anywhere — what must be quiet is the peer that carries on.
        if name != "host":
            continue
        quiet = "SCRIPT ERROR" not in log
        rows.append((f"nothing threw — left behind, {name}", quiet,
                     "quiet" if quiet else "script error"))

    ok = True
    print()
    for label, passed, detail in rows:
        ok = ok and passed
        print(f"  {label:<44}{detail:<26}{'ok' if passed else 'FAIL'}")

    if not ok:
        print("\nDOORWAY FAILED — a scene change breaks co-op", file=sys.stderr)
        for label, source in (("party door", logs), ("private door", private),
                              ("the way out", leaving),
                              ("left behind", behind)):
            for name, log in source.items():
                print(f"\n--- {label}: {name} ---", file=sys.stderr)
                for line in log.splitlines():
                    if re.search(r"chamber|coop|extract|left|ERROR|SCRIPT",
                                 line):
                        print(f"    {line}", file=sys.stderr)
        return 1

    print("\nall three doorways hold, and a party that loses its last "
          "member ends — verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
