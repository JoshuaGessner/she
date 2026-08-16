#!/usr/bin/env python3
"""M1-T05 — run two players over localhost, host-authoritative (TEC-004).

Usage:
    python3 tools/run_coop.py                # two windows, keyboard + gamepad
    python3 tools/run_coop.py --both-devices # no device restriction on either
    python3 tools/run_coop.py --clients 3    # a full four-player party
    python3 tools/run_coop.py --smoke        # headless, and judge it

The playtest launch puts the **host on the keyboard and the first client on the
gamepad**, which ADR-075 asks for by name: it is the cheapest possible
controller-parity check and it costs nothing extra. It is enforced rather than
trusted, because two processes on one machine both enumerate the same pad, and
"I checked the controller" with a hand resting on WASD checks nothing. Pass
--both-devices to turn it off.

--smoke is the CI shape. Both processes run the room set's `--coop-probe`, each
writing what *it* can see, and this compares the two files. That is the whole
point of the design: every claim about replication is a claim that two
processes agree, and a probe that interrogated only one of them would pass
happily with the network unplugged.

What the smoke actually asserts, and why each one is a real property:

    both peers see the whole party      the spawner reached the client at all
    both peers agree where bodies are   motion replication, in metres
    the client's body moved on both     the host's view came over the wire
    a crouch shortens one capsule only  stance replicates AND player.tscn's
                                        capsule is per-instance, not shared
    one client swing, one swing of hp   damage is host-authoritative, resolved
                                        exactly once, and reported back
    the host heard the client's body    clamor is derived host-side for a body
                                        the host is not playing

Loopback only. Latency, jitter and loss are M4-T07's question, and this harness
does not pretend otherwise.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
SCENE = "res://levels/room_set/room_set.tscn"

# Tolerances, in metres. Chosen to be far below the divergence a broken link
# produces — a body whose position never arrives sits at its spawn point, tens
# of metres from where it actually is — and far above 20 Hz of replication lag
# at walking speed (~0.17 m).
POSITION_TOLERANCE = 0.35
ENEMY_TOLERANCE = 0.60
# The client walks for a second at ⟨tune⟩ 3.4 m/s from a standstill.
MIN_WALK_METRES = 1.0
# stand 1.80 − crouch 1.15 = 0.65 m. Half of that is unambiguous while leaving
# room for the crouch blend not being quite finished.
MIN_CROUCH_DELTA = 0.30
# The struck enemy has to be visibly running when the report is taken, or
# "only the host simulates enemies" cannot distinguish anything.
MIN_CHASE_SPEED = 0.5

WINDOW = (960, 600)

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
        if Path(candidate).exists():
            return candidate
    print("godot not found — set GODOT=/path/to/godot", file=sys.stderr)
    raise SystemExit(1)


def launch(godot: str, role_args: list[str], args: argparse.Namespace,
           slot: int) -> subprocess.Popen:
    command = [godot, "--path", str(GAME)]
    if args.smoke:
        command += ["--headless"]
    else:
        # Side by side, so a solo developer can drive both without hunting for
        # the other window. Godot counts --position from the primary display.
        command += ["--resolution", f"{WINDOW[0]}x{WINDOW[1]}",
                    "--position", f"{40 + slot * (WINDOW[0] + 20)},80"]
    command += [SCENE, "--"] + role_args
    return subprocess.Popen(
        command,
        stdout=subprocess.PIPE if args.smoke else None,
        stderr=subprocess.STDOUT if args.smoke else None,
        text=True,
    )


def device_for(slot: int, args: argparse.Namespace) -> list[str]:
    """ADR-075: the host takes the keyboard, the first client takes the pad."""
    if args.both_devices or args.smoke:
        return []
    if slot == 0:
        return ["--input=keyboard"]
    if slot == 1:
        return ["--input=gamepad"]
    # There is only one pad on a desk. Beyond the second player the check has
    # already been made, so the rest are unrestricted rather than fabricated.
    return []


def distance(a: list[float], b: list[float]) -> float:
    return math.dist(a, b)


def check(label: str, ok: bool, detail: str) -> tuple[str, bool]:
    return f"  {label:<38}{detail:<30}{'ok' if ok else 'FAIL'}", ok


def judge(host: dict, client: dict, expected_players: int) -> list[tuple[str, bool]]:
    """Compare the two reports. Every row is a property, not a statistic."""
    rows: list[tuple[str, bool]] = []
    host_body = "player_1"
    client_body = f"player_{client['peer']}"

    seen = (host["players_seen"], client["players_seen"])
    rows.append(check(
        "party visible on both peers",
        seen == (expected_players, expected_players),
        f"host {seen[0]}, client {seen[1]} of {expected_players}"))

    enemies = (host["enemies_seen"], client["enemies_seen"])
    rows.append(check(
        "enemies replicated to the client",
        enemies[1] == enemies[0] and enemies[0] > 0,
        f"host {enemies[0]}, client {enemies[1]}"))

    # Positions. Missing keys must fail rather than skip: an absent body is the
    # loudest possible failure and the easiest one to accidentally ignore.
    shared = set(host["positions"]) & set(client["positions"])
    worst, worst_of = 0.0, "none"
    for name in sorted(shared):
        gap = distance(host["positions"][name], client["positions"][name])
        if gap >= worst:
            worst, worst_of = gap, name
    rows.append(check(
        "both peers agree where bodies are",
        len(shared) == expected_players and worst <= POSITION_TOLERANCE,
        f"worst {worst:.2f} m ({worst_of}) ≤{POSITION_TOLERANCE}"))

    worst_enemy, worst_enemy_of = 0.0, "none"
    for name in sorted(set(host["enemy_positions"]) & set(client["enemy_positions"])):
        gap = distance(host["enemy_positions"][name], client["enemy_positions"][name])
        if gap >= worst_enemy:
            worst_enemy, worst_enemy_of = gap, name
    rows.append(check(
        "both peers agree where enemies are",
        worst_enemy <= ENEMY_TOLERANCE,
        f"worst {worst_enemy:.2f} m ({worst_enemy_of}) ≤{ENEMY_TOLERANCE}"))

    # Sampled mid-chase, and the reason the probe stages a chase at all.
    # Position agreement cannot tell a host-simulated enemy from a client
    # simulating its own copy — a *standing* enemy looks identical either way,
    # and this check passed with the host gate deleted until the probe was
    # rewritten to make something move. `velocity` is never replicated and
    # never assigned on a client, so an honest client reports exact zero.
    host_fastest = max(host["enemy_speeds"].values(), default=0.0)
    client_fastest = max(client["enemy_speeds"].values(), default=0.0)
    rows.append(check(
        "only the host simulates enemies",
        host_fastest > MIN_CHASE_SPEED and client_fastest == 0.0,
        f"host {host_fastest:.2f}, client {client_fastest:.2f} m/s"))

    # The client drove; the host pressed nothing. If the host saw that body
    # travel, it travelled over the wire.
    on_host = host["walked"].get(client_body, 0.0)
    on_client = client["walked"].get(client_body, 0.0)
    rows.append(check(
        "the client's body moved, on both",
        min(on_host, on_client) >= MIN_WALK_METRES,
        f"host {on_host:.2f} m, client {on_client:.2f} m"))

    # One body crouched. On each peer the two capsules must now differ — which
    # needs the stance to have replicated *and* the scene's capsule to be
    # per-instance. A shared sub-resource gives both bodies one number.
    for report, who in ((host, "host"), (client, "client")):
        heights = report["capsule_heights"]
        gap = abs(heights.get(client_body, 0.0) - heights.get(host_body, 0.0))
        rows.append(check(
            f"crouch is one body's, on the {who}",
            gap >= MIN_CROUCH_DELTA,
            f"{heights.get(client_body, 0.0):.2f} vs "
            f"{heights.get(host_body, 0.0):.2f} m"))

    # The client swung once. Its own hitbox is inert, so any damage at all was
    # the host's decision — and *exactly* one swing of it means the host
    # resolved it once rather than once per peer.
    expected_hp = report_expected_hp(host)
    struck = [name for name, hp in host["enemy_health"].items()
              if hp < host["enemy_max_health"]]
    host_hp = min(host["enemy_health"].values())
    client_hp = min(client["enemy_health"].values())
    rows.append(check(
        "one client swing, one swing of hp",
        len(struck) == 1 and abs(host_hp - expected_hp) < 0.01,
        f"{host_hp:.0f} hp, expected {expected_hp:.0f}"))
    rows.append(check(
        "the damage reached the client",
        abs(client_hp - host_hp) < 0.01,
        f"client sees {client_hp:.0f} hp"))

    # The one row that can tell authority from coincidence. Hit points alone
    # cannot: a client that resolved the swing itself lands on the same 35 the
    # host does. `Health.damaged` fires only from `apply_damage`, and
    # replication assigns the value directly, so a client that correctly
    # refused to decide anything counts zero.
    rows.append(check(
        "only the host resolved the hit",
        host["damage_events"] == 1 and client["damage_events"] == 0,
        f"host {host['damage_events']}, client {client['damage_events']}"))

    # Noise is derived on the host for every body, including ones it is not
    # playing, and replicated back down.
    #
    # Taken from the *walk phase* only. The whole-run peak does not work: a
    # swing makes noise on the host through a different path, so this check
    # passed with the host deriving movement noise for its own body alone —
    # which is precisely the bug it is here to catch.
    heard = host["walk_clamor_peak"].get(client_body, 0.0)
    echoed = client["walk_clamor_peak"].get(client_body, 0.0)
    rows.append(check(
        "the host heard the client walk",
        heard > 0.0, f"peak {heard:.2f}"))
    rows.append(check(
        "that clamor came back to the client",
        echoed > 0.0, f"peak {echoed:.2f}"))

    return rows


def report_expected_hp(host: dict) -> float:
    return float(host["enemy_max_health"]) - float(host["swing_damage"])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--clients", type=int, default=1,
                        help="clients to launch; 3 + host = a four-player party")
    parser.add_argument("--port", type=int, default=47018)
    parser.add_argument("--both-devices", action="store_true",
                        help="do not restrict either instance to one device")
    parser.add_argument("--smoke", action="store_true",
                        help="headless, run the co-op probe, judge, exit")
    parser.add_argument("--keep", action="store_true",
                        help="keep the raw JSON reports")
    args = parser.parse_args()

    godot = find_godot()
    workdir = Path(tempfile.mkdtemp(prefix="she-coop-"))
    host_out = workdir / "host.json"
    client_outs = [workdir / f"client{i}.json" for i in range(args.clients)]

    procs: list[tuple[str, subprocess.Popen]] = []
    host_args = ["--host", f"--port={args.port}"] + device_for(0, args)
    if args.smoke:
        host_args.append(f"--coop-probe={host_out}")
    procs.append(("host", launch(godot, host_args, args, 0)))

    # The client's create_client fails outright if nothing is listening yet, so
    # the host gets a head start. Deliberately not a retry loop: a connection
    # that needs retries on loopback is a fault worth seeing, not smoothing.
    time.sleep(2.0)

    for i in range(args.clients):
        client_args = [f"--join=127.0.0.1", f"--port={args.port}"] + device_for(i + 1, args)
        if args.smoke:
            client_args.append(f"--coop-probe={client_outs[i]}")
        procs.append((f"client{i}", launch(godot, client_args, args, i + 1)))

    if not args.smoke:
        print(f"host + {args.clients} client(s) running on port {args.port}.")
        if not args.both_devices:
            print("host is keyboard-only, client 1 is gamepad-only "
                  "(ADR-075 parity check; --both-devices to disable)")
        print("close either window to end the session.")
        for _, proc in procs:
            proc.wait()
        shutil.rmtree(workdir, ignore_errors=True)
        return 0

    logs = {name: (proc.communicate()[0] or "").strip() for name, proc in procs}

    def load(path: Path) -> dict | None:
        try:
            return json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            return None

    host = load(host_out)
    clients = [c for c in (load(p) for p in client_outs) if c]
    if not host or len(clients) < args.clients:
        print("\nthe co-op probe produced no usable report — engine output follows:",
              file=sys.stderr)
        for name, text in logs.items():
            print(f"\n--- {name} ---\n{text}", file=sys.stderr)
        return 1

    print(f"\nGodot {host['godot']} · host + {len(clients)} client(s) "
          f"· connected in {max(host['connect_seconds'], clients[0]['connect_seconds']):.1f}s\n")
    rows = judge(host, clients[0], args.clients + 1)
    for text, _ in rows:
        print(text)

    passed = all(ok for _, ok in rows)
    print("\n" + ("two players over localhost, host-authoritative — verified"
                  if passed else
                  "COOP SMOKE FAILED — the authority split no longer holds"))
    if not passed:
        for name, text in logs.items():
            print(f"\n--- {name} ---\n{text}", file=sys.stderr)

    if args.keep:
        print(f"\nraw reports: {workdir}")
    else:
        shutil.rmtree(workdir, ignore_errors=True)
    return 0 if passed else 2


if __name__ == "__main__":
    raise SystemExit(main())
