#!/usr/bin/env python3
"""Export the game, and prove the exported thing actually works (ADR-086).

Usage:
    python3 tools/export_build.py                 # every platform this host can build
    python3 tools/export_build.py --platform macos
    python3 tools/export_build.py --platform windows
    python3 tools/export_build.py --keep          # leave build/ in place

`CLAUDE.md`'s Definition of Done has always included "works in an exported
build". Until ADR-086 that line had never once been checked — and could not
be: the only Godot on the development machine was the .NET build, and its
export template set contained nothing but `android_source.zip`. Eleven tasks
carried the claim.

**Exporting is not the check.** A build that boots proves the pack loads; it
does not prove the pack contains the game. Two things this project ships are
generated rather than committed — `en.en.translation` is gitignored and rebuilt
by the importer, and every `.tres` is re-serialised on export — so a build can
launch perfectly and still ship an empty item table and every name reading
`item.wpn_seax.name`. Nothing in the running game reads either yet, so nothing
would notice.

So the real check runs *inside* the exported binary: `--export-probe` reports
what the pack actually holds, and this compares it against the repo. On a host
that cannot run the target (Windows, from a Mac) the export is verified as far
as it can honestly be — it built, it is the expected size — and the probe is
skipped rather than faked.
"""

from __future__ import annotations

import argparse
import os
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
BUILD = ROOT / "build"
ITEMS = GAME / "data" / "items"

# preset name -> (output subdirectory, binary name, host that can run it)
PLATFORMS = {
    "windows": ("Windows Desktop", "SHE-windows", "SHE.exe", "Windows"),
    "macos": ("macOS", "SHE-macos", "SHE.app", "Darwin"),
}

# A template-built binary is ~100 MB. Anything far under that is a stub or a
# half-written file, and "the export produced *a* file" is not a check.
MIN_BINARY_BYTES = 20 * 1024 * 1024

GODOT_CANDIDATES = [
    "godot", "godot4",
    "/Applications/Godot.app/Contents/MacOS/Godot",
]


def find_godot() -> str:
    """The standard build, deliberately.

    ADR-086: the project is GDScript-only, CI already runs standard Godot, and
    the .NET build bundles a runtime nothing here uses. `Godot_mono.app` is
    *not* in the candidate list — falling back to it would silently produce a
    different artifact than CI does, which is the divergence this replaced.
    """
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    for candidate in GODOT_CANDIDATES:
        found = shutil.which(candidate)
        if found:
            return found
        if Path(candidate).exists():
            return candidate
    print("standard Godot 4.7 not found — install it or set GODOT=/path/to/godot",
          file=sys.stderr)
    raise SystemExit(1)


def repo_item_count() -> int:
    return len(list(ITEMS.glob("*.tres")))


def export(godot: str, preset: str, out: Path) -> tuple[bool, str]:
    # Godot fails with "The given export path doesn't exist" if the *directory*
    # is missing, which reads like a misconfigured preset and is not one.
    out.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run(
        [godot, "--headless", "--path", str(GAME),
         "--export-release", preset, str(out)],
        capture_output=True, text=True,
    )
    log = (proc.stdout or "") + (proc.stderr or "")
    failed = [l for l in log.splitlines()
              if "ERROR" in l or "Project export for preset" in l]
    return (not failed and proc.returncode == 0), "\n".join(failed)


def probe(binary: Path) -> tuple[bool, list[str]]:
    """Run the packed build's own census and judge it against the repo."""
    proc = subprocess.run(
        [str(binary), "--headless", "--quit-after", "600", "--", "--export-probe"],
        capture_output=True, text=True,
    )
    log = (proc.stdout or "") + (proc.stderr or "")
    rows: list[str] = []
    ok = True

    def say(label: str, good: bool, detail: str) -> None:
        nonlocal ok
        ok = ok and good
        rows.append(f"    {label:<30}{detail:<34}{'ok' if good else 'FAIL'}")

    if "[export] probe complete" not in log:
        say("the build ran its probe", False, "no probe output")
        rows.append("    --- engine output ---")
        rows += ["    " + line for line in log.splitlines()[:20]]
        return False, rows

    packed = re.search(r"\[export\] items packed\s+(\d+)", log)
    count = int(packed.group(1)) if packed else -1
    expected = repo_item_count()
    say("every item is in the pack", count == expected and expected > 0,
        f"{count} packed, {expected} in repo")

    say("tuning profile loaded", "tuning loaded true" in log, "Config.tuning")

    text = re.search(r"-> '([^']*)'", log)
    resolved = text.group(1) if text else ""
    say("translation table shipped", resolved not in ("", "item.wpn_seax.name"),
        f"reads '{resolved}'")

    errors = [l for l in log.splitlines() if "SCRIPT ERROR" in l or l.startswith("ERROR")]
    say("no errors in the packed build", not errors,
        f"{len(errors)} error line(s)")
    rows += ["    " + e for e in errors[:6]]
    return ok, rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--platform", choices=sorted(PLATFORMS), action="append",
                        help="repeatable; default is every platform")
    parser.add_argument("--keep", action="store_true", help="keep build/ afterwards")
    args = parser.parse_args()

    godot = find_godot()
    wanted = args.platform or sorted(PLATFORMS)
    host = platform.system()
    passed = True

    print(f"exporting with {godot}\n")
    for name in wanted:
        preset, folder, binary, runs_on = PLATFORMS[name]
        out = BUILD / folder / binary
        built, failure = export(godot, preset, out)
        if not built:
            print(f"  {name:<10} EXPORT FAILED")
            print("\n".join("    " + l for l in failure.splitlines()[:8]))
            passed = False
            continue

        size = sum(f.stat().st_size for f in out.rglob("*") if f.is_file()) \
            if out.is_dir() else out.stat().st_size
        big_enough = size >= MIN_BINARY_BYTES
        print(f"  {name:<10} exported {size / 1024 / 1024:6.1f} MB"
              f"   {'ok' if big_enough else 'SUSPICIOUSLY SMALL'}")
        passed = passed and big_enough

        if runs_on != host:
            # Stated, not skipped silently. A cross-export this harness cannot
            # run is verified as far as it honestly can be, and no further.
            print(f"    (not runnable on {host} — packed-content check is the "
                  f"{runs_on} run's job)")
            continue

        launcher = out / "Contents" / "MacOS" / "SHE" if out.is_dir() else out
        ran, rows = probe(launcher)
        print("\n".join(rows))
        passed = passed and ran

    if not args.keep:
        shutil.rmtree(BUILD, ignore_errors=True)
    else:
        print(f"\nbuilds left in {BUILD}")

    print("\n" + ("exported builds verified" if passed else
                  "EXPORT CHECK FAILED — the shipped build is not the game"))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
