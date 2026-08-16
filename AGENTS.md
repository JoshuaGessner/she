# Agent brief — Project SHE

**Read this before creating any file.** It exists because assets and code have
arrived in invented locations more than once, and moving them afterwards costs
more than reading this did.

`CLAUDE.md` is the full working agreement and takes precedence over anything
here. This file is the short version, plus the things an agent working from
outside the repo would otherwise have to guess.

## What this is

A first-person 3D fantasy **extraction roguelite** in **Godot 4.7**, for 1–4
players. Solo project, no deadline. Design is locked across 39 documents in
`docs/` and 81 ADRs in `docs/process/PRO-002-decision-log.md`.

**Changing an accepted document requires an ADR.** Do not quietly implement
something different from what a doc says — say so and propose the ADR.

## Where things go

```
docs/                       all project knowledge, YAML frontmatter, stable IDs
tools/                      Python tooling and checks (plus a few shell/GDScript)
source_art/                 DCC source: .blend, authoring scripts, measurements
                            never loaded by the engine
game/                       the Godot project root (project.godot)
├── autoload/               singletons — budget of 6, enforced in CI
├── components/             reusable node components
├── actors/player/ enemies/
├── systems/                generation, hunt, contracts, economy, skills
├── data/                   .tres content: items/ enemies/ skills/ contracts/
│                           biomes/ tuning/
├── levels/                 modules/ lair/ and hand-built sets
├── ui/
├── art/                    EVERYTHING the engine loads as art
│   ├── characters/         rigs and character meshes (.glb)
│   └── shaders/            .gdshader
├── audio/
└── tests/                  probes and validators
```

**There is no `game/assets/`.** Art the engine loads lives in `game/art/`;
DCC source files live in `source_art/` at the repo root and are never
referenced by `res://` paths. A rig once landed in `game/assets/characters/`
and had to be moved — that is the mistake this file is trying to prevent.

## Conventions

- `snake_case` files, directories, functions and variables
- `PascalCase` classes and nodes; `SCREAMING_SNAKE` constants; `_private`
- **Typed GDScript everywhere.** `untyped_declaration` is set to **Error**, so
  an untyped variable, parameter or return type is a hard parse failure
- Signals up, calls down — a child never reaches into a parent
- Data over code: anything a designer would tune is a `.tres` Resource
- Every non-obvious system gets a header comment explaining **why**, not what
- Tunable numbers live in `game/data/tuning/`, never inline in logic

## The rules that get broken first

**No stubs, no placeholders, no parallel fallbacks (ADR-064).** *Absent* is
correct scoping. *Present but empty* is banned — it lies to playtesters. A
second, worse implementation maintained beside the real one is banned. If you
find yourself writing a fallback path, you are about to break this.

**Build fewer things completely rather than many things partially.**

**Never say "for now"** without a paired `PRO-001` task ID that removes it.

**Blockout must feel good unjuiced.** Real-time control, then predictable
simulated space, then polish. Do not add particles or screen shake to make
something feel better than it plays.

## Before you commit

```bash
python3 tools/reindex.py            # regenerate docs/INDEX.md
python3 tools/status.py --write     # regenerate the dashboards
python3 tools/status.py --check     # must pass
python3 tools/check_project.py      # locked settings + conventions
python3 tools/bind_gamepad.py --check
tools/check_scripts.sh              # real GDScript parser, every script
```

**A failing check is a blocked commit, not a note in the commit message.**

Generated files (`docs/INDEX.md`, `docs/STATUS.md`, `docs/status.html`) must
never be committed disagreeing with their sources — a stale dashboard is worse
than none, because it gets believed.

## Locked technical decisions

| | |
|---|---|
| Renderer | **Forward+ only** (ADR-052). Asserted in CI |
| Networking | Host-authoritative P2P, Godot high-level multiplayer (ADR-068) |
| Generation | Seeded, **bit-exact deterministic** — clients build floors from a seed |
| Input | **Every action has a gamepad binding** (ADR-075), enforced in CI |
| Enemy telegraphs | Never under 250 ms |
| Audio | Every audio channel has a visual twin |

## The shared humanoid rig

`game/art/characters/humanoid_rig.glb` — **1.80 m tall, 0.35 m radius, eye at
1.62 m.** These match a play-tested collider; the rig is built to the collider,
never the reverse (ADR-080).

Seven non-deforming socket bones, exact names, verified in CI by
`game/tests/rig_probe.gd`:

`sock_head` `sock_hand_r` `sock_hand_l` `sock_back` `sock_hip_r` `sock_hip_l`
`sock_shoulders`

Body and Arms are **skinned**, not socketed. Every socket's **−Z points the way
a held object points**, +Y is its up. **Never parent a camera to `sock_head`** —
it silently breaks a motion-sickness accessibility guarantee (ADR-081).

## IP safety

The setting is Norse/Anglo-Saxon **public domain** sources — the Eddas,
*Völsunga saga*, *Beowulf*, the *Kalevala*. **Not Tolkien**, whose work is
under copyright until at least 2043.

Fast rule: **if you learned the word from Tolkien, do not use it.** Full
allow/deny list in `docs/process/PRO-004-ip-and-legal-guardrails.md`.

## If you are unsure

Search `docs/process/PRO-002-decision-log.md` before asking. Eighty-one ADRs
record the reasoning **and the rejected alternatives**, so the answer is
usually already written down — including why the obvious approach was not
taken.
