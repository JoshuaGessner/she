#!/usr/bin/env python3
"""One `user://` per process, for the harnesses that run more than one.

ADR-145 wrote the rule down for files: *a check that writes to `user://` must
name the file it writes to, and it must not be the one the game uses.* ADR-152
made `RunFile.arm()` refuse rather than remember it. Both are about a single
process, and neither is enough for a check with two.

`user://` is derived from the **project name**, not from the process, so two
copies of SHE on one machine resolve `user://profile.save` and
`user://run.active` to the same bytes. Godot 4.7 has no `--user-data-dir`, so
the only lever is the environment the process is launched with.

## Why this is a check's problem and not only a player's

A two-process check that asserts *"the client's run file was cleared"* against a
shared `user://` is asserting nothing: the host clears the one file, and the
client's row passes without the client having done anything at all. That is a
row that cannot fail — the failure this project has now been bitten by four
times — and it is the reason this module exists before the checks that need it.

The same sharing is a real hazard for a **player** running two builds on one
machine: both go through the front door, both load a profile, and two different
lives then write one file, last writer wins. That is a separate decision about
what the *game* should do, filed rather than assumed here.

## How the redirect works

Godot resolves the user data path from the environment, per platform:

    Linux    $XDG_DATA_HOME, else $HOME/.local/share      → godot/app_userdata/
    macOS    $HOME/Library/Application Support            → Godot/app_userdata/
    Windows  %APPDATA%

Both `HOME` and the XDG variables are set, because setting `HOME` alone does
nothing on a Linux box that already exports `XDG_DATA_HOME` — which CI may or
may not, and the difference would show up as a check that passes locally and
asserts nothing in CI. `APPDATA` is set for the same reason and costs a line.

Headless processes use the dummy renderer and keep no shader cache, so a
separated home costs them nothing. A windowed `run_coop.py` slot builds its own
cache the first time; that is a one-off per slot and the price of the rule
holding everywhere rather than only where somebody remembered it.
"""

from __future__ import annotations

import os
import shutil
import tempfile
from pathlib import Path

# Kept for the lifetime of the interpreter and removed on the way out, so a
# harness that crashes leaves its evidence behind and one that finishes does
# not litter /tmp with save files.
_ROOTS: dict[str, Path] = {}


def env_for(slot: str) -> dict[str, str]:
    """The environment for one process, with a `user://` nobody else has.

    `slot` names the process — "host", "client0" — and the same name gets the
    same directory, so a scenario that relaunches a peer can look at what the
    last one wrote.
    """
    root = _ROOTS.get(slot)
    if root is None:
        root = Path(tempfile.mkdtemp(prefix=f"she-{slot}-"))
        _ROOTS[slot] = root

    env = dict(os.environ)
    env["HOME"] = str(root)
    env["XDG_DATA_HOME"] = str(root / "data")
    env["XDG_CONFIG_HOME"] = str(root / "config")
    env["XDG_CACHE_HOME"] = str(root / "cache")
    env["APPDATA"] = str(root / "appdata")
    env["LOCALAPPDATA"] = str(root / "localappdata")
    return env


def user_dir(slot: str) -> Path | None:
    """Where that process's `user://` actually landed, or None if it never ran.

    Returns the one directory that exists, because the platform decides which
    of the three roots above Godot chose and a harness asserting about a save
    file should not have to know which platform it is on.
    """
    root = _ROOTS.get(slot)
    if root is None:
        return None
    for candidate in [
        root / "data" / "godot" / "app_userdata" / "SHE",
        root / "Library" / "Application Support" / "Godot" / "app_userdata" / "SHE",
        root / "appdata" / "Godot" / "app_userdata" / "SHE",
    ]:
        if candidate.is_dir():
            return candidate
    return None


def clear() -> None:
    """Drop every directory handed out. Called by a harness on its way out."""
    for root in _ROOTS.values():
        shutil.rmtree(root, ignore_errors=True)
    _ROOTS.clear()
