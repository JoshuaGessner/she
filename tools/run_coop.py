#!/usr/bin/env python3
"""M1-T05 — run two players over localhost, host-authoritative (TEC-004).

Usage:
    python3 tools/run_coop.py                # two windows, keyboard + gamepad
    python3 tools/run_coop.py --both-devices # no device restriction on either
    python3 tools/run_coop.py --clients 3    # a full four-player party
    python3 tools/run_coop.py --smoke        # headless, and judge it
    python3 tools/run_coop.py --late         # headless: a knock mid-run, judged

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
    each peer's ping reached the other  a mark is said to every peer, at the
                                        place its sender put it (ADR-244)

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

import own_user_dir

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
SCENE = "res://levels/room_set/room_set.tscn"

# Tolerances, in metres. Chosen to be far below the divergence a broken link
# produces — a body whose position never arrives sits at its spawn point, tens
# of metres from where it actually is — and far above 20 Hz of replication lag
# at walking speed (~0.17 m).
# Generous against a cold shader cache, and far short of "nobody is watching".
SMOKE_TIMEOUT = 180
POSITION_TOLERANCE = 0.35
ENEMY_TOLERANCE = 0.60
# The client walks for a second at ⟨tune⟩ 3.4 m/s from a standstill.
#
# Positions arrive at 20 Hz and physics runs at 60, so an interpolated body
# spends about three frames covering each packet's gap and a body written
# straight onto the transform spends exactly one. Two is the midpoint, and it
# is a ratio rather than a share of still frames on purpose (ADR-252): a client
# that stalls under load sends fewer packets, so the host's copy arrives and
# sits — which the old "still on 25% of frames" bound read as broken
# interpolation and failed one run in six on a busy machine.
MIN_GLIDE_STEPS = 2.0
# **Is a remote body handed to the gait at all** (ADR-254, ADR-351). This was a
# 0.45 m bound on how far a foot reaches — `--body-probe`'s question, whether
# the hips swing, asked again across a connection. Across a connection the
# reach depends on how fast the starved copy is seen to walk, and a loaded
# machine measured 0.42 m with nothing wrong. The wiring question is load-free:
# the gait advances by distance walked, so a body handed to it has taken
# strides and one in a rest pose has taken none. The reach keeps a floor a
# rest pose cannot meet (its feet sit under the hips).
# A body cut from the gait takes exactly none; a quarter of one is any motion.
MIN_STRIDES = 0.25
MIN_STRIDE_METRES = 0.25
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


# Where somebody who missed the descent is standing (`DES-014`): the fire.
THRESHOLD = "levels/lair/threshold.tscn"
# The expedition the late-join mode runs on. A named seed rather than a rolled
# one: the joiner has to arrive on *the party's* floor, and two processes that
# both rolled zero would agree for the wrong reason.
LATE_SEED = 31346


def launch(godot: str, role_args: list[str], args: argparse.Namespace,
           slot: int, scene: str = "") -> subprocess.Popen:
    command = [godot, "--path", str(GAME)]
    if args.smoke or args.late:
        command += ["--headless"]
    else:
        # Side by side, so a solo developer can drive both without hunting for
        # the other window. Godot counts --position from the primary display.
        command += ["--resolution", f"{WINDOW[0]}x{WINDOW[1]}",
                    "--position", f"{40 + slot * (WINDOW[0] + 20)},80"]
    command += [scene or SCENE, "--"] + role_args
    # **One `user://` per slot** (ADR-155). Two processes of one project
    # resolve `user://profile.save` and `user://run.active` to the same bytes,
    # so a claim about what *this* peer saved is a claim about whichever peer
    # wrote last. Nothing here loads a profile today — the smoke boots a level
    # directly, so `load_profile()` never runs — and the separation is the rule
    # rather than the current reachability, because the day a scenario does
    # reach the front door is not the day to remember this.
    return subprocess.Popen(
        command,
        stdout=subprocess.PIPE if (args.smoke or args.late) else None,
        stderr=subprocess.STDOUT if (args.smoke or args.late) else None,
        text=True,
        env=own_user_dir.env_for("host" if slot == 0 else f"client{slot - 1}"),
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


# How close to the Shaft a late arrival has to land, and how closely the two
# machines have to agree about where it is standing. Metres.
ARRIVAL_METRES = 4.0
AGREE_METRES = 1.0


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

    # The floor the host actually built, sampled while the second player was
    # standing on it. This is the only check that can see M2-T07 working: the
    # --scaling-probe measures the arithmetic in one process, and the
    # arithmetic was always right. What was wrong for one commit is that the
    # game never called it with a party above one — the host lays its floor in
    # the frame it creates the session, and every other body arrives later. A
    # solo-sized floor under two players is the whole failure, and it is silent.
    floor = host["floor"]
    grew = (floor["enemies"] > floor["solo_enemies"]
            and floor["loot"] > floor["solo_loot"])
    rows.append(check(
        "the floor scaled to the party on it",
        floor["party"] == expected_players and grew,
        f"{floor['party']} players: {floor['enemies']} enemies "
        f"(solo {floor['solo_enemies']}), {floor['loot']} loot "
        f"(solo {floor['solo_loot']})"))

    # **The floor is built to the highest rank present** (ADR-010, ADR-122).
    #
    # The client declared rank 8; the host is rank 1. A floor that never heard
    # the client reads as rank 1 here — the outcome ADR-010 rejected outright,
    # arriving in the exact case ADR-010 exists for. No single-process probe
    # can see it: the declaration is an RPC that lands after the host has
    # already finished building the level in its own `_ready`.
    # **This row proves the declaration crossed the wire**, and only that.
    # Planted by silencing the client, it reads rank 1; planted by disconnecting
    # the floor's listener, it still reads 8 — because the number arrived and
    # nothing used it. The row below is the one that proves it was *used*, and
    # keeping them apart is what makes a failure say which half broke.
    rows.append(check(
        "the floor is the party's highest rank",
        int(floor.get("floor_rank", 1)) == 8,
        f"rank {floor.get('floor_rank', 1)}, host declared 1"))
    # And the Hunt was aged for it. Density recovers by re-spawning whether or
    # not anything listened, so enemy count alone cannot prove the floor
    # *reacted* — the Hunt's clock is set once, and only a deliberate
    # re-application moves it.
    # `> 0` is **not** the test, and the first draft of this row used it: the
    # Hunt's clock ticks on its own, so it reported 2 s and passed while the
    # floor was demonstrably rank 1. Rank 8 is worth 140 s of head start, and
    # the probe itself runs for seconds — so three figures is the rank and
    # nothing else could have put it there.
    rows.append(check(
        "the Hunt was aged for that rank",
        float(floor.get("hunt_age", 0.0)) >= 100.0,
        f"{floor.get('hunt_age', 0.0):.0f} s old at report"))

    # Jitter, as a number rather than an impression (ADR-102). A remote body
    # that is walking should be moving on every frame. Writing 20 Hz positions
    # straight onto the transform left it frozen on two frames in three, which
    # is what a tester reports as "a little jittery" and what no probe in the
    # sweep could see. Interpolated, it lands near zero.
    glide = host["glide"]
    # A teammate is a rigged body, not a capsule, and it is being posed
    # (ADR-254). Asked on the host about the body it is *not* playing, because
    # that is the only peer where the wiring exists to break: `--body-probe`
    # proves the gait moves the legs, and this proves a remote body is handed
    # to it. Without this row the teammate slides across the floor in a rest
    # pose and every other assertion here still passes.
    rows.append(check(
        "and it is walking, not sliding",
        glide.get("strides", 0.0) >= MIN_STRIDES
        and glide.get("stride", 0.0) >= MIN_STRIDE_METRES,
        f"{glide.get('strides', 0.0):.1f} stride(s), "
        f"foot reached {glide.get('stride', 0.0):.2f} m from the hips"))
    rows.append(check(
        "a walking teammate glides between packets",
        glide["packets"] > 0 and glide["steps"] >= MIN_GLIDE_STEPS,
        f"{glide['steps']:.1f} frame(s) per packet, "
        f"{glide['moved']}/{glide['frames']} moved, {glide['packets']} packet(s)"))

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

    # **A replicated body moves; it does not step** (ADR-199, ADR-102).
    #
    # ADR-102 measured this fault for players and fixed it there: a transform
    # written straight from the wire holds a remote body still for three
    # rendered frames and then jumps, twenty times a second. Enemies were left
    # on the raw transform until ADR-199, and this row is what says so.
    #
    # **Only the client's number carries the finding**, and not for the reason
    # it first looked like. The host does not score near 1.0 — it scores 0.43,
    # in both the healthy build and the planted one, because a body moves in
    # `_physics_process` at 60 Hz while this samples every *rendered* frame and
    # headless runs the main loop faster than physics. That ratio is a fact
    # about the sampling rate and says nothing about the wire, which is exactly
    # what makes it the wrong number to assert on.
    #
    # The client's is the wire. Easing happens in `_process`, so a fixed build
    # moves on every rendered frame; a raw-transform build moves only when a
    # packet lands, at `REPLICATION_HZ` against that same faster loop.
    #
    # Measured, both ways: **0.99 fixed, 0.13 planted**, host 0.43 either way.
    # 0.80 sits far from both rather than splitting them finely.
    motion = client.get("wire_motion", {})
    fraction = float(motion.get("fraction", 0.0))
    rows.append(check(
        "a replicated body moves rather than stepping",
        fraction >= 0.80,
        f"client {motion.get('moved', 0)}/{motion.get('frames', 0)} "
        f"rendered frames moved ({fraction:.2f}); "
        f"host {float(host.get('wire_motion', {}).get('fraction', 0.0)):.2f}"))

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

    # The strike phase's handshake, asserted on both peers before anything
    # about the swing is (ADR-252). The host reports whether it saw the client
    # reach the strike post; the client reports whether the enemy reached it.
    # Without this row a starved peer fails three rows further down and the
    # report reads as a broken authority split, which is where a day went.
    for report, who, what in (
            (host, "host", "saw the client reach the post"),
            (client, "client", "saw the enemy arrive")):
        rows.append(check(
            f"the {who} {what}",
            bool(report.get("in_place", False)),
            "yes" if report.get("in_place", False) else
            "timed out — the machine may be too loaded to measure this"))

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
    # A blow the host decided, felt by the client it landed on (ADR-310): the
    # message arrived, it carried where the blow came from, and the client's
    # own screen drew it on the left, which is where the host stood.
    struck = client.get("struck", {})
    events = struck.get("events", [])
    bearing = struck.get("bearing", {})
    rows.append(check(
        "the client felt a blow the host decided",
        len(events) == 1 and events[0].get("taken", 0.0) > 0.0
        and events[0].get("placed", False),
        f"{len(events)} blow(s) arrived"
        + (f", {events[0].get('taken', 0.0):.0f} taken" if events else "")))
    rows.append(check(
        "and its screen drew it on the side it came from",
        bool(bearing.get("placed")) and bearing.get("x", 0.0) < -0.25
        and not bearing.get("behind", True),
        f"bearing x {bearing.get('x', 0.0):+.2f}, "
        f"{'behind' if bearing.get('behind') else 'ahead'}"))
    # A guard is paid from the client's own breath (ADR-313). The host decides
    # the guard; the client's bar is what pays for it, or stamina is two pools.
    guard = client.get("guard", {})
    rows.append(check(
        "a client's guard took the blow",
        guard.get("guarded", 0.0) > 0.0, f"{guard.get('guarded', 0.0):.1f} turned"))
    rows.append(check(
        "and the client paid for it from its own breath",
        guard.get("paid", 0.0) >= guard.get("cost", 1.0) * 0.8,
        f"{guard.get('paid', 0.0):.1f} of {guard.get('cost', 0.0):.0f} paid"))

    # The fury is the host's (ADR-368): what the host wrote on the client's body
    # is what both sides hold, and the client's own zero did not overwrite it.
    fury_host = host.get("fury", {})
    fury_client = client.get("fury", {})
    rows.append(check(
        "the host's fury reaches the client and holds",
        fury_client.get("fury", 0.0) > 0.0 and fury_client.get("owed", 0.0) >= 7.0
        and fury_host.get("fury", 0.0) > 0.0 and fury_host.get("owed", 0.0) >= 7.0,
        f"client sees fury {fury_client.get('fury', 0.0):.1f} owed {fury_client.get('owed', 0.0):.0f}; "
        f"host still {fury_host.get('fury', 0.0):.1f} owed {fury_host.get('owed', 0.0):.0f}"))

    # A client's reading is the host's (ADR-379): the client held its own key,
    # the host ran the trance and said what was seen, and both peers hold the
    # same marks — the loot and the way out at least, and the sight spent.
    seidr_host = host.get("seidr", {})
    seidr_client = client.get("seidr", {})
    seen_client = seidr_client.get("kinds", [])
    rows.append(check(
        "a client's reading reaches both peers",
        "loot" in seen_client and "way" in seen_client
        and seen_client == seidr_host.get("kinds", [])
        and seidr_client.get("trance", 0.0) > 0.0
        and seidr_host.get("spent", 0.0) > 0.0,
        f"client {','.join(seen_client) or 'nothing'} (trance {seidr_client.get('trance', 0.0):.2f}); "
        f"host {','.join(seidr_host.get('kinds', [])) or 'nothing'}"))

    # A client's door is the host's to open (ADR-381): refused without the
    # key, opened with it, and standing open on both peers.
    door_host = host.get("door", {})
    door_client = client.get("door", {})
    rows.append(check(
        "a client's door opens on the host's word",
        door_host.get("refused", False) and door_host.get("open", False)
        and door_client.get("found", False) and door_client.get("open", False),
        f"host refused {door_host.get('refused', False)}, open {door_host.get('open', False)}; "
        f"client found {door_client.get('found', False)}, open {door_client.get('open', False)}"))

    # A client's Haugbrot is the host's to finish (ADR-382): the client held
    # its key, the host's clock broke the door, and both peers see it open.
    haug_host = host.get("haug", {})
    haug_client = client.get("haug", {})
    rows.append(check(
        "a client breaks a door on the host's clock",
        haug_host.get("open", False) and haug_client.get("open", False)
        and haug_client.get("breaking", 0.0) > 0.0,
        f"host open {haug_host.get('open', False)}; client open "
        f"{haug_client.get('open', False)}, breaking reached {haug_client.get('breaking', 0.0):.2f}"))

    # A client's Galdr is the host's to land (ADR-387): the client sang on its
    # own key, the host's clock turned both enemies, the host told the singer
    # how many, and the client sees the marks on its own copies.
    galdr_host = host.get("galdr", {})
    galdr_client = client.get("galdr", {})
    host_moods = galdr_host.get("moods", [])
    seen = galdr_client.get("seen", [])
    rows.append(check(
        "a client's verse turns the dungeon on the host's clock",
        len(host_moods) == 2 and "NONE" not in host_moods
        and galdr_client.get("singing", 0.0) > 0.0 and galdr_client.get("told", -1) == 2
        and len(seen) == 2 and "NONE" not in seen,
        f"host turned {host_moods}; client sang to {galdr_client.get('singing', 0.0):.2f}, "
        f"was told {galdr_client.get('told', -1)}, sees {seen}"))
    rallied_host = host.get("rallied", {})
    rallied_client = client.get("rallied", {})
    rows.append(check(
        "a host's Bjarkamál stands the fallen client",
        rallied_host.get("stood", False) and rallied_client.get("fell", False)
        and rallied_client.get("stood", False),
        f"host saw it stand {rallied_host.get('stood', False)}; client fell "
        f"{rallied_client.get('fell', False)}, stood {rallied_client.get('stood', False)}"))
    rows.append(check(
        "and a client's tap sings one stanza at the nearest",
        galdr_host.get("stanza", -1) == 1 and galdr_client.get("stanza_told", -1) == 1,
        f"host turned {galdr_host.get('stanza', -1)}; client was told {galdr_client.get('stanza_told', -1)}"))

    # What the client heard (ADR-311). The host decides a pickup and a blow,
    # and played their sounds where it decided them — so a client never heard
    # its own loot go into the bag, nor itself hurt.
    sounds = client.get("heard", {})
    rows.append(check(
        "the client heard its own pickup",
        sounds.get("CLINK", 0) >= 1, f"{sounds.get('CLINK', 0)} clink(s)"))
    rows.append(check(
        "and heard itself hurt",
        sounds.get("HURT", 0) >= 1, f"{sounds.get('HURT', 0)} hurt"))
    rows.append(check(
        "the host heard the client walk",
        heard > 0.0, f"peak {heard:.2f}"))
    rows.append(check(
        "that clamor came back to the client",
        echoed > 0.0, f"peak {echoed:.2f}"))

    # The client picked something up (`M2-T01`). Two claims travelling in
    # opposite directions, and neither peer can satisfy the other's half:
    #
    #   * the *host* holding the right kilograms for a body it does not play
    #     is `CarriedWeight` replicating host→peer;
    #   * the *client* holding the right item count is the host's bag push
    #     arriving, since a client never adds to its own inventory.
    #
    # A client that helpfully filled its own bag would still leave a host that
    # never heard of the item, and vice versa — which is why both rows exist
    # rather than one.
    host_bag = host["bags"].get(client_body, {})
    client_bag = client["bags"].get(client_body, {})
    rows.append(check(
        "the host granted the client's pickup",
        host_bag.get("items", 0) == 1 and host_bag.get("kilograms", 0.0) > 0.0,
        f"host sees {host_bag.get('items', 0)} item(s), "
        f"{host_bag.get('kilograms', 0.0):.1f} kg"))
    rows.append(check(
        "the bag reached the client that owns it",
        client_bag.get("items", 0) == host_bag.get("items", 0)
        and abs(client_bag.get("kilograms", 0.0)
                - host_bag.get("kilograms", 0.0)) < 0.01,
        f"client sees {client_bag.get('items', 0)} item(s), "
        f"{client_bag.get('kilograms', 0.0):.1f} kg"))

    # The rescue (`M2-T05`, `DES-012`). The client was put on the floor and the
    # host walked over and picked them up — the one claim in the whole design
    # that genuinely cannot be tested in a single process, because it is two
    # people, and the mechanism under the M2 co-op gate.
    #
    # Both peers are asked, because both halves have to hold: the client has to
    # *see* itself go down (the window is replicated, which is what makes going
    # back for someone a decision rather than a guess), and the host's hand has
    # to reach across the wire and work.
    for report, who in ((host, "host"), (client, "client")):
        fell = report["downed"].get(client_body, {})
        rows.append(check(
            f"the client went down, on the {who}",
            fell.get("downed", False) and fell.get("bleeding", 0.0) > 0.0,
            f"bleeding {fell.get('bleeding', 0.0):.0f}s"))

    for report, who in ((host, "host"), (client, "client")):
        up = report["revived"].get(client_body, {})
        rows.append(check(
            f"a hand got them back up, on the {who}",
            not up.get("downed", True) and up.get("health", 0.0) > 0.0,
            f"{up.get('health', 0.0):.0f} hp"))

    # At most what a revive returns, or going down cost nothing and `DES-012`'s
    # revive is free. Against the *fraction* rather than against "less than
    # full": an enemy that lands a hit after the rescue would satisfy the
    # weaker test for a reason that has nothing to do with the revive, and it
    # did — the client stood up at 40 and was promptly hit down to 6.
    revived_hp = host["revived"].get(client_body, {}).get("health", 0.0)
    # **Against that body's own maximum**, not the profile's. A Húskarl is
    # 1.25x (`M3-T02`), so a revive returns 50 of 125 rather than 40 of 100 —
    # and this read the profile until `M3-T07` made the class actually reach a
    # client's body. It failed the moment that started working, which is the
    # right way round: the harness was describing a body nobody was playing.
    ceiling = (float(host["revived"].get(client_body, {}).get("maximum",
        host["player_max_health"])) * float(host["revive_health_fraction"]))
    rows.append(check(
        "and no better than a revive gives",
        0.0 < revived_hp <= ceiling + 0.01,
        f"{revived_hp:.0f}, revive gives {ceiling:.0f}"))

    # A client ties a binding (`M4-T32`, ADR-221). The use is a request and the
    # countdown is the host's, so this is the only place the wire under it is
    # asked: the client pressed, the host counted, and both saw it happen.
    for report, who in ((host, "host"), (client, "client")):
        mid = report["binding_mid"].get(client_body, {})
        rows.append(check(
            f"a client's binding was being tied, on the {who}",
            0.0 < mid.get("mending", 0.0) < 1.0,
            f"{mid.get('mending', 0.0):.2f} through"))
    before = host["binding_mid"].get(client_body, {})
    after = host["binding_done"].get(client_body, {})
    restored = after.get("health", 0.0) - before.get("health", 0.0)
    wanted = (float(after.get("maximum", host["player_max_health"]))
              * float(host["binding_restores"]))
    rows.append(check(
        "and it closed the wound, and was spent",
        abs(restored - wanted) < 0.5 and before.get("bindings", 0) == 1
        and after.get("bindings", 1) == 0,
        f"+{restored:.1f} of {wanted:.1f}, "
        f"bindings {before.get('bindings', 0)} → {after.get('bindings', 0)}"))
    seen = client["binding_done"].get(client_body, {})
    rows.append(check(
        "and the client sees the health and the bag the host left",
        abs(seen.get("health", 0.0) - after.get("health", 0.0)) < 0.01
        and seen.get("bindings", 1) == 0,
        f"client {seen.get('health', 0.0):.1f} hp, "
        f"{seen.get('bindings', 1)} binding(s)"))

    # Pings (`M4-T05`, ADR-244). A mark changes nothing in the world, so the
    # only question is whether it reached the other peer: the client's spot on
    # the host, the host's gesture on the client, and each at the same place.
    host_body = f"player_{host['peer']}"
    aimed = host.get("ping_at", [0.0, 0.0, 0.0])
    for report, who, body, kind in ((host, "host", client_body, "spot"),
                                    (client, "client", host_body, "danger")):
        mark = report.get("pings", {}).get(body, {})
        where = mark.get("at", [math.inf, math.inf, math.inf])
        if kind == "spot":
            off = distance(where, aimed)
        else:
            off = distance(where, report["positions"].get(body, where))
        rows.append(check(
            f"the other peer's ping reached the {who}",
            mark.get("kind") == kind and off <= POSITION_TOLERANCE,
            f"{mark.get('kind', 'nothing')} {off:.2f} m off"))

    return rows


def wait_for(procs: list[tuple[str, subprocess.Popen]]) -> dict[str, str]:
    """Bounded, for the smoke's reason: a probe that hangs is a job that hangs."""
    logs: dict[str, str] = {}
    for name, proc in procs:
        try:
            logs[name] = (proc.communicate(timeout=SMOKE_TIMEOUT)[0] or "").strip()
        except subprocess.TimeoutExpired:
            proc.kill()
            logs[name] = (proc.communicate()[0] or "").strip()
            print(f"\n{name} did not finish within {SMOKE_TIMEOUT}s — killed",
                  file=sys.stderr)
    return logs


def read_report(path: Path) -> dict | None:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return None


def judge_late(host: dict, client: dict, party: int = 2) -> list[tuple[str, bool]]:
    """A join that happened is two machines agreeing that it did.

    Every row is a claim one process alone would report happily while the
    other saw nothing — which is the whole reason this harness exists
    (ADR-107), and is exactly what ADR-157 refused to build a half of.
    """
    rows: list[tuple[str, bool]] = []
    rows.append(check(
        "the host was under way when the knock came",
        bool(host.get("under_way")),
        "the descent had already begun" if host.get("under_way")
        else "the door was still open, so this was an ordinary join"))
    seen = (host.get("players_seen", 0), client.get("players_seen", 0))
    rows.append(check(
        "both peers see the whole party",
        seen == (party, party), f"host {seen[0]}, joiner {seen[1]} of {party}"))
    rows.append(check(
        "the joiner built the same floor",
        host.get("seed") == client.get("seed") == LATE_SEED
        and host.get("floor") == client.get("floor"),
        f"host seed {host.get('seed')} floor {host.get('floor')}, "
        f"joiner seed {client.get('seed')} floor {client.get('floor')}"))
    # Where the joiner is standing, as each machine has it, against the Shaft
    # that machine derived for itself.
    mine = client.get("mine", "")
    at_host = host.get("positions", {}).get(mine)
    at_client = client.get("positions", {}).get(mine)
    shaft = host.get("shaft", [])
    if at_host and at_client and shaft:
        near_host = distance(at_host, shaft)
        near_client = distance(at_client, shaft)
        apart = distance(at_host, at_client)
        rows.append(check(
            "the joiner came in at the Shaft",
            near_host <= ARRIVAL_METRES and near_client <= ARRIVAL_METRES,
            f"{near_host:.1f} m from it on the host, {near_client:.1f} m on its own"))
        rows.append(check(
            "and both peers put it in the same place",
            apart <= AGREE_METRES, f"{apart:.2f} m apart"))
    else:
        rows.append(check("the joiner came in at the Shaft", False,
                          "no body for the joiner in one of the reports"))
    carried = client.get("carrying", {}).get(mine, -1)
    rows.append(check(
        "and brought nothing from a run it was not on",
        carried == 0, f"carrying {carried} item(s)"))
    # What TEC-004's delta table is really asking: not *did we send a list of
    # touched IDs*, but *is the arrival standing on the floor as it is now*.
    taken = host.get("taken", "")
    host_items = set(host.get("items", []))
    joiner_items = set(client.get("items", []))
    rows.append(check(
        "the joiner sees the floor as it stands",
        host_items == joiner_items and bool(host_items),
        f"{len(joiner_items)} item(s) against the host's {len(host_items)}"))
    rows.append(check(
        "including the absence of what was taken before it came",
        bool(taken) and taken not in joiner_items,
        f"{taken or 'nothing'} was taken and is gone from both"
        if taken and taken not in joiner_items
        else f"{taken or 'nothing taken'} — joiner still has it"))
    rows.append(check(
        "and the bodies already on it",
        host.get("bodies") == client.get("bodies"),
        f"{len(client.get('bodies', []))} against the host's "
        f"{len(host.get('bodies', []))}"))
    rows.append(check(
        "the floor heard it arrive",
        float(host.get("arrival_clamor", 0.0)) > 0.0,
        f"clamor {float(host.get('arrival_clamor', 0.0)):.1f} where it came down"))
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
    parser.add_argument("--late", action="store_true",
                        help="headless: a peer knocks after the descent began, "
                             "is called down, and both reports are judged")
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

    if args.late:
        # **The two processes start in different places, which is the point.**
        # The host is on a floor with the descent declared under way; the
        # joiner starts at the fire, exactly where a player who missed the
        # descent is standing, and has to be called down. Launching it into
        # the floor directly would skip the handshake this mode exists for.
        # A generated floor on a named seed, because the call down carries
        # both numbers and a harness on the hand-built Deep would carry zeros.
        host_args = ["--host", f"--port={args.port}", "--under-way",
                     f"--as-run={LATE_SEED}", "--as-class=huskarl",
                     f"--late-party={args.clients + 1}",
                     f"--late-probe={host_out}"]
        procs.append(("host", launch(godot, host_args, args, 0)))
        time.sleep(2.0)
        for slot, output in enumerate(client_outs, 1):
            joiner_args = ["--join=127.0.0.1", f"--port={args.port}",
                           "--own-run", "--as-class=huskarl", "--as-rank=8",
                           f"--late-party={args.clients + 1}",
                           f"--late-probe={output}"]
            procs.append((f"joiner{slot}", launch(godot, joiner_args, args, slot, THRESHOLD)))
            if slot < args.clients:
                # The next knock arrives while an existing client owns a
                # MotionSync, exercising relay admission as well as the host.
                time.sleep(3.0)
        logs = wait_for(procs)
        host = read_report(host_out)
        joiners = [read_report(output) for output in client_outs]
        if not host or not all(joiners):
            print("\nthe late-join probe produced no usable report — engine "
                  "output follows:", file=sys.stderr)
            for name, out in logs.items():
                print(f"\n--- {name} ---\n{out}", file=sys.stderr)
            return 1
        print(f"\nGodot {host['godot']} · a knock after the descent began\n")
        rows = [row for joiner in joiners
                for row in judge_late(host, joiner, args.clients + 1)]
        # A final matching world cannot excuse packets addressed to a scene
        # that did not exist during admission (ADR-271).
        errors = [line for output in logs.values() for line in output.splitlines()
                  if line.startswith(("ERROR:", "SCRIPT ERROR:"))]
        rows.append(check("admission sent no invalid scene packets", not errors,
                          f"{len(errors)} engine error(s)"))
        rows.append(check("both processes exited cleanly",
                          all(proc.returncode == 0 for _, proc in procs),
                          ", ".join(f"{name}: {proc.returncode}" for name, proc in procs)))
        for row, _ in rows:
            print(row)
        passed = all(ok for _, ok in rows)
        print("\n" + ("a late arrival comes down to the party at the Shaft — "
                      "verified" if passed else
                      "LATE JOIN FAILED — ADR-157's refusal is what this replaced"))
        if not passed:
            for name, out in logs.items():
                print(f"\n--- {name} ---\n{out}", file=sys.stderr)
        if args.keep:
            for name, output in logs.items():
                (workdir / f"{name}.log").write_text(output)
            print(f"\nraw reports: {workdir}")
        else:
            shutil.rmtree(workdir, ignore_errors=True)
        return 0 if passed else 2

    host_args = ["--host", f"--port={args.port}"] + device_for(0, args)
    if args.smoke:
        host_args.append(f"--coop-probe={host_out}")
        # **Both bodies have to be dressed** (`M3-T07`). Slots make the class
        # kit what puts a weapon in your hand, and a headless process has never
        # seen the class select — so without this the smoke swings with empty
        # hands and reports it as damage that failed to replicate, which is a
        # true reading of an unarmed player and a wrong story about the wire.
        host_args.append("--as-class=huskarl")
    procs.append(("host", launch(godot, host_args, args, 0)))

    # The client's create_client fails outright if nothing is listening yet, so
    # the host gets a head start. Deliberately not a retry loop: a connection
    # that needs retries on loopback is a fault worth seeing, not smoothing.
    time.sleep(2.0)

    for i in range(args.clients):
        client_args = [f"--join=127.0.0.1", f"--port={args.port}"] + device_for(i + 1, args)
        if args.smoke:
            client_args.append(f"--coop-probe={client_outs[i]}")
            # **A mixed-rank party, which is the only kind ADR-010 is about**
            # (ADR-122). Two processes on one machine share a `user://` and so
            # cannot hold two profiles, and nothing raises a rank until
            # `M3-T01` — so without this the only co-op party the sweep can
            # assemble is two rank-1 players, the one composition that cannot
            # tell a working ADR-010 from a broken one.
            client_args.append("--as-rank=8")
            # **A Húskarl, deliberately, and not the Veiðimaðr.** A mixed-class
            # party is a better party and it is the wrong thing to put here:
            # the swing row below is about *melee damage being resolved once,
            # by the host*, and a Stalker carries a bow — so the first draft of
            # this line left the client with nothing to swing and the harness
            # reported it as damage that failed to replicate. A true reading of
            # an unarmed player and a wrong story about the wire.
            #
            # Mixed classes are `GATE M3 COOP`'s question, with real people.
            client_args.append("--as-class=huskarl")
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

    # **Bounded.** A probe that hangs is a CI job that hangs, and this one did:
    # a client that navigated away from the probe scene never wrote a report
    # and never quit, so the harness waited half an hour instead of failing in
    # sixty seconds. A timeout turns "something is wrong" into a red build
    # rather than a queue nobody is watching.
    logs: dict[str, str] = {}
    for name, proc in procs:
        try:
            logs[name] = (proc.communicate(timeout=SMOKE_TIMEOUT)[0] or "").strip()
        except subprocess.TimeoutExpired:
            proc.kill()
            logs[name] = (proc.communicate()[0] or "").strip()
            print(f"\n{name} did not finish within {SMOKE_TIMEOUT}s — killed",
                  file=sys.stderr)

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
