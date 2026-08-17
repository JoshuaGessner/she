#!/usr/bin/env python3
"""Find code the game cannot reach.

Usage:
    python3 tools/check_dead.py            # report; exit 1 on any finding
    python3 tools/check_dead.py --list     # also print every reachable name

ADR-064 bans stubs because a thing that is present but does nothing lies to
whoever finds it. ADR-097 found the harder version of the same fault: code that
is *correct*, *tested*, and never executed. Party scaling shipped with a probe
proving its arithmetic and nothing proving the game ever called it — the answer
was always computed for a party of one, because the floor was built in the
frame before anybody had joined.

That is what this looks for. Four kinds, in rough order of how quietly they
fail:

  DEAD-FUNC     a function nothing calls
  DEAD-SIGNAL   a signal nobody connects, or one nobody ever emits
  DEAD-TUNE     a TuningProfile field nothing reads
  DEAD-CONST    a script-level const nothing reads

## What this deliberately cannot do

It is a *name* checker, not a call-graph. It cannot tell that a function is
called only from a branch that is never taken — the exact shape of the ADR-097
bug — and pretending otherwise would be worse than useless. That class stays
the job of a probe run in the situation it is claimed to work in, and the note
at the bottom of the report says so rather than letting a green run imply it.

Deliberately dependency-free, matching the other tools here.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import NamedTuple

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"

FUNC_DECL = re.compile(r"^\s*(?:static\s+)?func\s+([A-Za-z_]\w*)\s*\(")
SIGNAL_DECL = re.compile(r"^\s*signal\s+([A-Za-z_]\w*)")
CONST_DECL = re.compile(r"^\s*const\s+([A-Z][A-Z0-9_]*)")
VAR_DECL = re.compile(r"^\s*(?:@export\s+)?var\s+([a-z_]\w*)")
RPC_MARK = re.compile(r"^\s*@rpc\b")

# Godot calls these itself. A virtual nobody references is not dead, it is the
# engine's entry point — and the list is closed, so a typo'd override still
# shows up as an ordinary uncalled function rather than being waved through.
ENGINE_VIRTUALS = {
    "_ready", "_init", "_process", "_physics_process", "_input",
    "_unhandled_input", "_unhandled_key_input", "_shortcut_input", "_draw",
    "_enter_tree", "_exit_tree", "_notification", "_to_string", "_get",
    "_set", "_get_property_list", "_property_can_revert",
    "_property_get_revert", "_validate_property", "_integrate_forces",
    "_gui_input", "_can_drop_data", "_drop_data", "_get_drag_data",
    "_get_configuration_warnings", "_physics_interpolated_changed",
    # A `--script` entry point. Godot instances the script as its MainLoop and
    # calls this; there is no call site anywhere and there cannot be one.
    "_initialize", "_iteration", "_finalize",
}


class Finding(NamedTuple):
    code: str
    where: str
    name: str
    note: str


def scripts() -> list[Path]:
    return sorted(p for p in GAME.rglob("*.gd") if ".godot" not in p.parts)


def scenes_and_data() -> list[Path]:
    out: list[Path] = []
    for suffix in ("*.tscn", "*.tres", "*.godot", "*.cfg"):
        out += [p for p in GAME.rglob(suffix) if ".godot" not in p.parts]
    # The build tooling counts as a reader. `CollisionLayers` names five
    # physics layers that no *game* code looks up — the scenes set the raw
    # integers — and the thing that makes those names load-bearing is
    # `check_project.py` asserting the two agree. A constant read only by the
    # check that enforces it is doing its job, not sitting idle.
    out += sorted((ROOT / "tools").glob("*.py"))
    return sorted(out)


def strip_comments(line: str) -> str:
    """Drop a trailing comment, leaving strings alone.

    Crude on purpose: a name that appears only inside a comment is not a call,
    and treating one as a use is how a dead-code checker gets talked out of
    every finding it has.
    """
    out: list[str] = []
    quote = ""
    for index, char in enumerate(line):
        if quote:
            out.append(char)
            if char == quote and line[index - 1] != "\\":
                quote = ""
            continue
        if char in "\"'":
            quote = char
            out.append(char)
            continue
        if char == "#":
            break
        out.append(char)
    return "".join(out)


def body_text(paths: list[Path]) -> str:
    """Every line of code, with comments and doc comments removed."""
    chunks: list[str] = []
    for path in paths:
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.lstrip().startswith("##"):
                continue
            chunks.append(strip_comments(line))
    return "\n".join(chunks)


def declarations(path: Path) -> tuple[list[str], list[str], list[str], bool]:
    """Functions, signals and consts declared in one script."""
    funcs: list[str] = []
    signals: list[str] = []
    consts: list[str] = []
    is_tuning = False
    rpc_pending = False
    rpcs: list[str] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = strip_comments(raw)
        if "class_name TuningProfile" in line:
            is_tuning = True
        if RPC_MARK.match(line):
            rpc_pending = True
            continue
        match = FUNC_DECL.match(line)
        if match:
            (rpcs if rpc_pending else funcs).append(match.group(1))
            rpc_pending = False
            continue
        rpc_pending = False
        match = SIGNAL_DECL.match(line)
        if match:
            signals.append(match.group(1))
            continue
        match = CONST_DECL.match(line)
        if match:
            consts.append(match.group(1))
    # An @rpc function is reached by name from the other end of a wire. Its
    # declaration site is the contract; a call site may not exist in this
    # process at all.
    funcs += rpcs
    return funcs, signals, consts, is_tuning


def uses(name: str, haystack: str, own_decl: re.Pattern[str]) -> int:
    """How many times a name appears somewhere that is not its declaration."""
    total = 0
    for line in haystack.splitlines():
        if own_decl.match(line):
            continue
        total += len(re.findall(rf"(?<![A-Za-z0-9_]){re.escape(name)}(?![A-Za-z0-9_])", line))
    return total


def main() -> int:
    paths = scripts()
    corpus = body_text(paths) + "\n" + body_text(scenes_and_data())
    findings: list[Finding] = []

    for path in paths:
        where = str(path.relative_to(ROOT))
        funcs, signals, consts, is_tuning = declarations(path)

        for name in funcs:
            if name in ENGINE_VIRTUALS:
                continue
            decl = re.compile(rf"^\s*(?:static\s+)?func\s+{re.escape(name)}\s*\(")
            if uses(name, corpus, decl) == 0:
                findings.append(Finding(
                    "DEAD-FUNC", where, name,
                    "nothing calls it — delete it, or call it"))

        for name in signals:
            decl = re.compile(rf"^\s*signal\s+{re.escape(name)}\b")
            hits = uses(name, corpus, decl)
            if hits == 0:
                findings.append(Finding(
                    "DEAD-SIGNAL", where, name,
                    "declared, never connected and never emitted"))
                continue
            emitted = re.search(
                rf"(?<![A-Za-z0-9_]){re.escape(name)}\s*\.\s*emit\b", corpus)
            connected = re.search(
                rf"(?<![A-Za-z0-9_]){re.escape(name)}\s*\.\s*connect\b", corpus)
            # A .tscn can wire a signal without the name appearing beside
            # `.connect`, so an editor connection counts as a listener.
            if not connected:
                connected = re.search(rf'signal="{re.escape(name)}"', corpus)
            if emitted and not connected:
                findings.append(Finding(
                    "DEAD-SIGNAL", where, name,
                    "emitted, but nothing listens"))
            elif connected and not emitted:
                findings.append(Finding(
                    "DEAD-SIGNAL", where, name,
                    "listened for, but nothing emits it"))

        for name in consts:
            decl = re.compile(rf"^\s*const\s+{re.escape(name)}\b")
            if uses(name, corpus, decl) == 0:
                findings.append(Finding(
                    "DEAD-CONST", where, name,
                    "nothing reads it"))

        if is_tuning:
            for raw in path.read_text(encoding="utf-8").splitlines():
                match = VAR_DECL.match(strip_comments(raw))
                if not match:
                    continue
                name = match.group(1)
                decl = re.compile(rf"^\s*(?:@export\s+)?var\s+{re.escape(name)}\b")
                if uses(name, corpus, decl) == 0:
                    findings.append(Finding(
                        "DEAD-TUNE", where, name,
                        "a tuning number no system reads"))

    if "--list" in sys.argv:
        for path in paths:
            funcs, signals, consts, _ = declarations(path)
            print(f"{path.relative_to(ROOT)}: {len(funcs)} func, "
                  f"{len(signals)} signal, {len(consts)} const")

    for finding in sorted(findings):
        print(f"{finding.code:<12} {finding.where}: {finding.name}")
        print(f"{'':<12}   → {finding.note}")

    total = len(paths)
    if findings:
        print(f"\n{len(findings)} unreachable name(s) across {total} script(s)",
              file=sys.stderr)
        return 1

    print(f"no unreachable names in {total} script(s) "
          f"— note that this checks names, not reachability: a function called "
          f"only from a branch that never runs still reads as alive here, and "
          f"that is what ADR-097 was. Probes prove reachability; this proves "
          f"nothing is orphaned.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
