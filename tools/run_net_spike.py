#!/usr/bin/env python3
"""M1-T06 — run the networking spike and print a go/no-go verdict.

Usage:
    python3 tools/run_net_spike.py                     # 150 entities, 4 peers
    python3 tools/run_net_spike.py --entities 300      # find where it breaks
    GODOT=/path/to/godot python3 tools/run_net_spike.py

Launches one host and N client processes headless on loopback, each writing a
JSON report, then judges them against the budgets already written down:

    ≤64 kbps up per client          TEC-004 "Budgets"      ⟨tune⟩
    ≥90% of the requested sync rate  the gate's real question
    ≤16.6 ms host frame time         TEC-001 "60 fps"       ⟨tune⟩

The thresholds are quoted from the docs rather than chosen here on purpose: a
spike that gets to pick its own pass mark cannot fail.

Loopback removes latency and packet loss from the measurement. That is the
right call for this question — it isolates whether the *replication layer*
scales to the object count, which is what TEC-004's risk register asks. It is
not a substitute for a real-network test, and this harness does not claim to be
one.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
SCENE = "res://tests/net_spike/net_spike.tscn"

# Quoted from the docs. Changing one of these is a design decision, not a knob.
KBPS_UP_PER_CLIENT = 64.0     # TEC-004 Budgets
FRAME_MS_BUDGET = 16.6        # TEC-001 performance targets, 60 fps
SYNC_RATE_TOLERANCE = 0.90    # delivered/requested update rate

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


def launch(godot: str, out: Path, role: str, args: argparse.Namespace,
           seconds: float) -> subprocess.Popen:
    return subprocess.Popen(
        [godot, "--headless", "--path", str(GAME), SCENE, "--",
         f"--role={role}",
         f"--entities={args.entities}",
         f"--peers={args.peers}",
         f"--seconds={seconds}",
         f"--rate={args.rate}",
         f"--active={args.active}",
         f"--compress={1 if args.compress else 0}",
         f"--out={out}"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    )


def row(label: str, value: float, budget: float | None, unit: str,
        worse_is_higher: bool = True) -> tuple[str, bool]:
    if budget is None:
        return f"  {label:<34}{value:>9.1f} {unit}", True
    ok = value <= budget if worse_is_higher else value >= budget
    mark = "ok " if ok else "OVER" if worse_is_higher else "UNDER"
    comparator = "≤" if worse_is_higher else "≥"
    return (f"  {label:<34}{value:>9.1f} {unit}"
            f"   {comparator}{budget:g} {mark}"), ok


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--entities", type=int, default=150,
                        help="synchronised entities (TEC-001 budget: 150)")
    parser.add_argument("--peers", type=int, default=3,
                        help="clients; 3 + host = a 4-player party")
    parser.add_argument("--seconds", type=float, default=25.0)
    parser.add_argument("--rate", type=float, default=20.0,
                        help="synchroniser Hz")
    parser.add_argument("--active", type=int, default=-1,
                        help="moving entities; -1 = all. TEC-001 specifies ~20 "
                             "fully simulated of 150, the rest on a cheap LOD brain")
    parser.add_argument("--compress", action="store_true",
                        help="ENet range coder on the transport")
    parser.add_argument("--keep", action="store_true", help="keep raw JSON reports")
    parser.add_argument("--smoke", action="store_true",
                        help="short 2-client connectivity check for CI; asserts "
                             "replication still works, not that a given entity "
                             "count fits the bandwidth budget")
    args = parser.parse_args()

    # TEC-004's risk register asks for "automated 2-client smoke tests in CI
    # from M1". This is that: small, fast, and deliberately NOT budget-checked.
    # Bandwidth at a given entity count is a design question answered by ADR-068
    # and re-opened only on purpose; what CI must catch is replication silently
    # breaking, which is a regression.
    if args.smoke:
        args.entities, args.active, args.peers = 30, 10, 2
        args.seconds, args.compress = 8.0, True

    godot = find_godot()
    workdir = Path(tempfile.mkdtemp(prefix="net_spike_"))

    active = args.entities if args.active < 0 else args.active
    print(f"host + {args.peers} client(s) · {args.entities} entities "
          f"({active} moving) · {args.rate:g} Hz · {args.seconds:g}s"
          f"{' · range coder' if args.compress else ''}")

    host_out = workdir / "host.json"
    procs = [("host", launch(godot, host_out, "host", args, args.seconds))]
    time.sleep(2.0)  # let the server bind before clients dial in
    client_outs = []
    for i in range(args.peers):
        out = workdir / f"client_{i}.json"
        client_outs.append(out)
        # Clients outlive the host so the host's exit ends them cleanly via
        # server_disconnected, rather than each racing its own deadline.
        procs.append((f"client{i}", launch(godot, out, "client", args,
                                           args.seconds + 15.0)))

    logs: dict[str, str] = {}
    for name, proc in procs:
        logs[name] = (proc.communicate()[0] or "").strip()

    def load(path: Path) -> dict | None:
        try:
            return json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            return None

    host = load(host_out)
    clients = [c for c in (load(p) for p in client_outs) if c]

    # A run that sampled nothing must fail loudly. Zeroes read as "well within
    # budget" to anyone skimming, which is the worst possible failure mode for
    # a measurement whose whole job is to be believed at a go/no-go gate.
    empty = [r for r in ([host] if host else []) + clients
             if not r.get("steady_samples")]
    if not host or len(clients) < args.peers or empty:
        reason = ("no reports" if not host or not clients
                  else f"{len(clients)}/{args.peers} clients reported"
                  if len(clients) < args.peers
                  else f"{len(empty)} process(es) recorded zero samples")
        print(f"\nspike produced no usable measurement ({reason}) — "
              "engine output follows:", file=sys.stderr)
        for name, text in logs.items():
            print(f"\n--- {name} ---\n{text}", file=sys.stderr)
        return 1

    up_total = host["kbps_up_mean"]
    up_per_client = up_total / max(len(clients), 1)
    delivered = sum(c["updates_hz_mean"] for c in clients) / len(clients)
    worst_delivered = min(c["updates_hz_worst"] for c in clients)

    print(f"\nGodot {host['godot']} · {len(clients)}/{args.peers} client(s) reported "
          f"· {host['steady_samples']} steady samples\n")

    # Smoke mode judges only that replication still works. Bandwidth-at-count is
    # a design answer (ADR-068), and worst-case frame time on a shared CI runner
    # is noise — enforcing either would produce flakes, and a flaky gate gets
    # ignored, which is worse than not having one.
    kbps_budget = None if args.smoke else KBPS_UP_PER_CLIENT
    worst_frame_budget = None if args.smoke else FRAME_MS_BUDGET

    lines = [
        row("host upstream, total", up_total, None, "kbps"),
        row("host upstream, per client", up_per_client, kbps_budget, "kbps"),
        row("client downstream", clients[0]["kbps_down_mean"], None, "kbps"),
        row("delivered update rate, mean", delivered,
            args.rate * SYNC_RATE_TOLERANCE, "Hz/entity", worse_is_higher=False),
        row("delivered update rate, worst s", worst_delivered,
            args.rate * SYNC_RATE_TOLERANCE, "Hz/entity", worse_is_higher=False),
        row("host physics frame", host["physics_ms_mean"], FRAME_MS_BUDGET, "ms"),
        row("host physics frame, worst", host["physics_ms_worst"],
            worst_frame_budget, "ms"),
        row("spawn burst", float(host["spawn_msec"]), None, "ms"),
    ]
    for text, _ in lines:
        print(text)

    passed = all(ok for _, ok in lines)
    if args.smoke:
        verdict = ("replication healthy — 2 clients connected and in sync"
                   if passed else
                   "SMOKE FAILED — replication regressed; ADR-068 no longer holds")
    else:
        verdict = ("GO — within every documented budget" if passed else
                   "NO-GO — at least one budget breached; see TEC-004 risk register")
    print("\n" + verdict)

    if args.keep:
        print(f"\nraw reports: {workdir}")
    else:
        shutil.rmtree(workdir, ignore_errors=True)
    return 0 if passed else 2


if __name__ == "__main__":
    raise SystemExit(main())
