"""Build the game's recorded foley from CC0 field recordings (ADR-326).

Run with:
    Blender --background --factory-startup --python-exit-code 1 --python build_foley.py

**Why Blender.** It ships `aud`, which reads and writes Ogg Vorbis, and every
other tool in this pipeline is already Blender; nothing new to install.

**What it makes.** Several takes of each recorded sound in
`game/audio/foley/<sound>_<nn>.ogg`, which `Foley` plays in turn so that the
same action twice is never the same sound twice. Each take is:

- **mono**, because every world sound is positional and a stereo recording
  through `AudioStreamPlayer3D` pans its two channels rather than its source;
- **trimmed** to the length the cue needs, with a short fade so a cut never
  clicks;
- **level-matched to the synthesised cue it replaces.** Every `volume_db` in
  gameplay code was tuned by ear against those cues (`DES-018`'s mix), so a
  take is set to the same loudness over its loudest 100 ms rather than to some
  other standard — the recordings change what the game sounds like, not how
  loud anything is relative to anything else.

**Where they come from.** `cc0/kenney/`: Kenney Vleugels's *RPG Audio*,
*Impact Sounds* and *Interface Sounds*, all Creative Commons Zero — public
domain, no attribution required (credited anyway in `cc0/README.md`). Only the
takes used are vendored, with their licence.
"""
from __future__ import annotations

import math
import os
from pathlib import Path

import aud
import numpy as np

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
CC0 = SRC / "cc0" / "kenney"
OUT = Path(os.environ.get("FOLEY_OUT", str(ROOT / "game/audio/foley")))
RATE = 44100
## The synthesised cues' own rate (`Foley.RATE`), for measuring them.
SYNTH_RATE = 22050


def takes(pack: str, stem: str, numbers) -> list[Path]:
    return [CC0 / pack / f"{stem}{n}.ogg" for n in numbers]


## Sound -> (takes, seconds kept). The name is `Foley.Sound`'s, lowercased.
RECORDED = {
    # Boot on dressed stone.
    "step": (takes("impact", "footstep_concrete_", ("000", "001", "002", "003", "004")), 0.16),
    # Coin, handled — *the sound of your own greed* (`ART-002`).
    "clink": (takes("rpg", "handleCoins", ("", "2")), 0.60),
    # Something set down: leather, and soft weight onto stone.
    "thump": ([CC0 / "rpg" / "dropLeather.ogg"]
              + takes("impact", "impactSoft_medium_", ("000", "001", "002", "003")), 0.30),
    # A hard knock — a blade off stone, a snare springing, a thing landing:
    # a pick into rock, which is what this place is made of.
    "hit": (takes("impact", "impactMining_", ("000", "001", "002", "003", "004")), 0.45),
    # A blow landing on you.
    "hurt": (takes("impact", "impactPunch_heavy_", ("000", "001", "002", "003", "004")), 0.50),
    # Interface.
    "click": (takes("interface", "click_", ("001", "002", "003", "004", "005")), 0.10),
    # A word for the party: plucked, small, clearly not the world.
    "ping": (takes("interface", "pluck_", ("001", "002")), 0.30),
    # A blow on mail or plate (ADR-279).
    "clang": (takes("impact", "impactPlate_heavy_", ("000", "001", "002", "003", "004")), 0.55),
    # A blow into a body (ADR-279).
    "crunch": (takes("impact", "impactPunch_medium_", ("000", "001", "002", "003", "004")), 0.45),
    # A weapon through air: the heavier swishes of a pack recorded for a
    # sword-and-staff RPG.
    "swing": ([SRC / "cc0" / "opengameart" / "swishes" / f"swish-{n}.wav" for n in (3, 4, 7, 8, 9)], 0.30),
    # A barrow's slab dragged open (ADR-242): a stone door, and two scrapes
    # across block played slow, so cinder block is a grave-slab's weight.
    # `(path, from second, speed)`.
    "grind": ([(SRC / "cc0" / "opengameart" / "stone_door_bonebrah.ogg", 0.0, 1.0),
               (SRC / "cc0" / "opengameart" / "scrapes" / "scrape-1.ogg", 0.0, 0.58),
               (SRC / "cc0" / "opengameart" / "scrapes" / "scrape-2.ogg", 0.0, 0.58)], 1.6),
    # Coin shifting in the bag at every step (`ART-002`): short handfuls cut
    # from one long take, `(path, from second)`.
    "coin": ([(CC0 / "rpg" / "handleCoins.ogg", s) for s in (0.0, 0.19, 0.43)]
             + [(CC0 / "rpg" / "handleCoins2.ogg", 0.0)], 0.24),
}
## Loops: a presence rather than an event. Sound -> (source, seconds kept,
## seconds crossfaded tail into head so the loop has no seam).
LOOPS = {
    # The camp's fire: wood burning in a hearth, popping (ADR-326).
    "crackle": (SRC / "cc0" / "opengameart" / "fireplace_loop_pagdev_excerpt.wav", 12.0, 1.0),
}

## A sound with no synthesised cue before it: its level against one that had.
NEW_LEVEL = {"coin": ("clink", 0.5)}


def _noise(t):
    seeded = np.sin(t * 15731.0 + 7.0) * 43758.5453
    return (seeded - np.floor(seeded)) * 2.0 - 1.0


def synth(name: str) -> np.ndarray:
    """`Foley._sample` for the cues being replaced, so each take can be set to
    the loudness the mix was tuned against. Kept in step with `foley.gd` by
    hand; it only has to agree about loudness, not to the sample."""
    seconds = {"click": 0.08, "ping": 0.3, "clang": 0.6}.get(name, 0.32)
    t = np.arange(int(SYNTH_RATE * seconds)) / SYNTH_RATE
    p = t / seconds
    tau = math.tau
    if name == "step":
        return _noise(t) * np.exp(-t * 34) * .6 + np.sin(tau * 78 * t) * np.exp(-t * 26) * .35
    if name == "clink":
        return (np.sin(tau * 2100 * t) * .5 + np.sin(tau * 3170 * t) * .3) * np.exp(-t * 19)
    if name == "thump":
        return (np.sin(tau * 140 * t) * .6 + _noise(t) * .25) * np.exp(-t * 15)
    if name == "hit":
        return (_noise(t) * .5 + np.sin(tau * 190 * t) * .45) * np.exp(-t * 22)
    if name == "hurt":
        return (np.sin(tau * 96 * t) * .55 + _noise(t) * .3) * np.exp(-t * 9)
    if name == "click":
        return _noise(t) * np.exp(-t * 90) * .3
    if name == "ping":
        note = np.where(p < .4, 880.0, 660.0)
        return np.sin(tau * note * t) * .22 * np.exp(-np.fmod(t, .12) * 18)
    if name == "clang":
        return (_noise(t * 2) * np.exp(-t * 60) * .5
                + (np.sin(tau * 1180 * t) * .28 + np.sin(tau * 1735 * t) * .2
                   + np.sin(tau * 2890 * t) * .12) * np.exp(-t * 7))
    if name in NEW_LEVEL:
        like, scale = NEW_LEVEL[name]
        return synth(like) * scale
    if name == "grind":
        seconds = 1.6
        t = np.arange(int(SYNTH_RATE * seconds)) / SYNTH_RATE
        p = t / seconds
        stutter = .6 + .4 * np.abs(np.sin(tau * 7 * t))
        return (np.sin(tau * 52 * t) * .4 + _noise(t * .5) * .45) * stutter * np.sin(np.pi * p)
    if name == "swing":
        arc = np.sin(np.pi * np.clip(p, 0.0, 1.0))
        return _noise(t * 3.0) * arc * 0.45
    if name == "stalk":
        t = np.arange(int(SYNTH_RATE * 2.4)) / SYNTH_RATE
        tread = np.abs(np.sin(tau * 0.83 * t))
        weight = tread ** 6
        coin = (_noise(t * 9.0) * .5 + np.sin(tau * 2100 * t) * .25 + np.sin(tau * 3300 * t) * .15) * tread ** 14
        return (np.sin(tau * 38 * t) * .45 + _noise(t * .35) * .25 + coin * .4) * weight
    if name == "crackle":
        t = np.arange(int(SYNTH_RATE * 2.0)) / SYNTH_RATE
        slot = np.floor(t * 37.0)
        chance = np.mod(np.sin(slot * 91.7) * 43758.5, 1.0)
        since = t - slot / 37.0
        pop = _noise(t * 4.0) * np.exp(-since * 160.0) * (chance >= .82) * (.4 + .6 * np.mod(chance * 7.0, 1.0))
        return _noise(t * .25) * .05 + pop * .7
    if name == "crunch":
        return np.sin(tau * 70 * t) * .6 * np.exp(-t * 18) + _noise(t * .7) * .45 * np.exp(-t * 30)
    raise KeyError(name)


def loudness(x: np.ndarray, rate: float) -> float:
    """RMS over the loudest 100 ms — what a one-shot reads as."""
    w = max(1, int(rate * 0.1))
    # A take shorter than the window is measured over the whole window, as
    # the ear hears it, or a 10 ms click would read ten times its size.
    if len(x) < w:
        x = np.concatenate([x, np.zeros(w - len(x), dtype=x.dtype)])
    energy = np.convolve(x ** 2, np.ones(w) / w, mode="valid")
    return float(np.sqrt(energy.max()))


def mono(path: Path) -> tuple[np.ndarray, float]:
    sound = aud.Sound(str(path)).resample(RATE, True)
    data = sound.data()
    return (data.mean(axis=1) if data.ndim == 2 else data).astype(np.float32), float(RATE)


def shape(x: np.ndarray, rate: float, seconds: float) -> np.ndarray:
    """Trim leading silence and the tail past `seconds`, fade out the cut."""
    above = np.nonzero(np.abs(x) > 0.02)[0]
    start = max(0, int(above[0]) - int(rate * 0.002)) if len(above) else 0
    x = x[start:start + int(rate * seconds)].copy()
    fade = min(len(x), int(rate * 0.04))
    x[-fade:] *= np.linspace(1.0, 0.0, fade, dtype=np.float32)
    return x


def write(x: np.ndarray, path: Path) -> None:
    sound = aud.Sound.buffer(x.reshape(-1, 1).astype(np.float32), RATE)
    sound.write(str(path), rate=RATE, channels=aud.CHANNELS_MONO, format=aud.FORMAT_FLOAT32,
                container=aud.CONTAINER_OGG, codec=aud.CODEC_VORBIS, bitrate=112000)


def slowed(path: Path, speed: float) -> np.ndarray:
    """A take played at `speed` — lower and longer below 1, as tape does."""
    sound = aud.Sound(str(path)).pitch(speed).resample(RATE, True)
    data = sound.data()
    return (data.mean(axis=1) if data.ndim == 2 else data).astype(np.float32)


def stalk() -> np.ndarray:
    length = int(RATE * 2.4)
    out = np.zeros(length, dtype=np.float32)
    weight = slowed(CC0 / "impact" / "impactPunch_heavy_002.ogg", 0.55)
    coin = slowed(CC0 / "rpg" / "handleCoins.ogg", 0.62)
    drag = slowed(CC0 / "rpg" / "handleCoins.ogg", 0.45)
    for at, scale in ((0.10, 1.0), (1.30, 0.85)):
        start = int(RATE * at)
        for layer, gain, delay in ((weight, 1.0, 0.0), (coin, 0.55, 0.03), (drag, 0.30, 0.22)):
            begin = start + int(RATE * delay)
            n = min(len(layer), length - begin)
            out[begin:begin + n] += layer[:n] * gain * scale
    # The end runs into the start: whatever rings past the loop wraps round.
    fade = int(RATE * 0.05)
    out[-fade:] *= np.linspace(1.0, 0.0, fade, dtype=np.float32)
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.ogg"):
        old.unlink()
    report = []
    for name, (paths, seconds) in RECORDED.items():
        target = loudness(synth(name), SYNTH_RATE)
        for i, path in enumerate(paths):
            path, offset, speed = (path + (1.0,))[:3] if isinstance(path, tuple) else (path, 0.0, 1.0)
            if speed == 1.0:
                x, rate = mono(path)
            else:
                x, rate = slowed(path, speed), float(RATE)
            x = shape(x[int(offset * rate):], rate, seconds)
            gain = target / max(loudness(x, rate), 1e-6)
            x = x * gain
            # Never clip: a take that would has its loudness given up first.
            peak = float(np.abs(x).max())
            if peak > 0.98:
                x *= 0.98 / peak
            write(x, OUT / f"{name}_{i:02d}.ogg")
            report.append(f"{name}_{i:02d} {len(x) / rate:.2f}s gain {20 * math.log10(gain):+.1f} dB "
                          f"peak {float(np.abs(x).max()):.2f} from {path.parent.name}/{path.name}")
    for name, (path, seconds, overlap) in LOOPS.items():
        x, rate = mono(path)
        keep, fade = int(rate * seconds), int(rate * overlap)
        x = x[:keep + fade].copy()
        # The tail fades into the head, so the end runs into the start.
        ramp = np.linspace(0.0, 1.0, fade, dtype=np.float32)
        x[:fade] = x[:fade] * ramp + x[keep:keep + fade] * (1.0 - ramp)
        x = x[:keep]
        # A loop is matched over its whole length, not its loudest moment.
        want = float(np.sqrt(np.mean(synth(name) ** 2)))
        gain = want / max(float(np.sqrt(np.mean(x ** 2))), 1e-6)
        x = x * gain
        peak = float(np.abs(x).max())
        if peak > 0.98:
            x *= 0.98 / peak
        write(x, OUT / f"{name}_loop.ogg")
        report.append(f"{name}_loop {len(x) / rate:.2f}s gain {20 * math.log10(gain):+.1f} dB "
                      f"peak {float(np.abs(x).max()):.2f} from {path.parent.name}/{path.name}")
    # The Hunter's tread, composed (ADR-327): `DES-017`'s *"a great deal of
    # loose coin being dragged — that is its footstep"*. Two treads in 2.4 s,
    # as the synthesised loop had, so a player can still count them: each a
    # heavy soft weight set down, pitched low, under a cascade of coin pitched
    # down to sound like more of it than a hand could hold.
    x = stalk()
    want = float(np.sqrt(np.mean(synth("stalk") ** 2)))
    x *= want / max(float(np.sqrt(np.mean(x ** 2))), 1e-6)
    peak = float(np.abs(x).max())
    if peak > 0.98:
        x *= 0.98 / peak
    write(x, OUT / "stalk_loop.ogg")
    report.append(f"stalk_loop {len(x) / RATE:.2f}s composed, peak {float(np.abs(x).max()):.2f}")
    (SRC / "foley_measurements.txt").write_text("\n".join(report) + "\n")
    print("\n".join(report))
    print("FOLEY_DONE", len(report))


if __name__ == "__main__":
    main()
