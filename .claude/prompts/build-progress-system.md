# Build prompt — Project SHE progress system

> Paste this into a fresh Claude Code session, or run `Read @.claude/prompts/build-progress-system.md and execute it`.
> Read `CLAUDE.md`, `docs/README.md`, and `docs/process/PRO-001-roadmap-and-milestones.md` before writing a line of code.

---

## What to build

A progress system for Project SHE that reads the **existing** documentation corpus and renders where the project actually stands — in the terminal, in a committed Markdown file, and in a single self-contained HTML dashboard. Its second job is to refuse to let work skip a step.

Three artifacts:

| Artifact | Purpose |
|---|---|
| `tools/status.py` | The engine. Parses, validates, renders. |
| `docs/STATUS.md` | Generated, committed, renders on GitHub. |
| `docs/status.html` | Generated, self-contained, no network requests. |

## Non-negotiable constraints

- **Python 3 stdlib only.** No pip installs, no YAML library. `tools/reindex.py` already parses the flat frontmatter subset by hand — match that discipline and reuse its parser rather than writing a second one.
- **Match `tools/reindex.py`'s house style**: module docstring with usage block, `from __future__ import annotations`, typed signatures, no classes where a function will do.
- **Deterministic.** Same inputs → byte-identical output, except a single regeneration-date line. `--check` must ignore that line when comparing, exactly as `reindex.py` does.
- **Never edits a design doc.** The tool reads `docs/`, writes only `docs/STATUS.md` and `docs/status.html`.
- **One source of truth.** Do not create a `milestones.yaml` or any parallel ledger. Progress state lives inside `PRO-001`, which is already the roadmap. A second file would drift from it within a month.

## Step 1 — Make PRO-001 machine-readable

`PRO-001` currently states milestone scope as prose bullets. Convert those bullets to checkbox lines with stable IDs.

**Convert only. Do not add, remove, merge, reorder, or reword any scope item.** The roadmap is `accepted`; you are changing its notation, not its content. If a bullet is ambiguous about whether it is one task or three, leave it as one and note it in the summary.

Task line format:

```markdown
- [ ] `M1-T01` First-person controller: walk, sprint, crouch, stamina, weight → DES-009
```

- States: `[ ]` not started · `[~]` in progress · `[x]` done · `[-]` cut (must be followed by ` — cut: <reason>`)
- IDs are permanent. Never renumber. A cut task keeps its ID forever.
- `→ DOC-ID` suffix lists the docs a task implements. Zero doc references is a validation error — if a task implements nothing written down, either the doc is missing or the task is invented.

Milestone header format, on the line after the `## M1 — …` heading:

```markdown
<!-- milestone id=M1 depends=M0 size=1.0 -->
```

Gate format — replace the existing `**Exit gate:**` and `**Co-op gate:**` lines with:

```markdown
> **GATE M1 EXIT** `pending` — two people who aren't you play for 10 minutes and ask to keep playing.
```

Gate states: `pending` · `passed YYYY-MM-DD` · `failed YYYY-MM-DD — <what went wrong>`. A failed gate is not an error state; per `PRO-001`, iterating at a failed gate is the correct behaviour, and the dashboard should say so rather than showing red alarm.

**Seed honestly.** As of today, no engine code exists. Every M1–M6 task starts `[ ]`. `M0` is the one milestone with real state: all 35 docs are `accepted` and `OPEN-QUESTIONS.md` has nothing blocking, so `GATE M0 EXIT` is `passed 2026-08-14`. Do not invent progress anywhere else.

Changing an `accepted` doc requires an ADR. Add one to `PRO-002` recording the notation convention (next free number — 54 ADRs exist, so ADR-055 unless the count has moved). Keep it short: what changed, why a separate ledger file was rejected.

## Step 2 — The checks

`python3 tools/status.py --check` exits non-zero on any violation. This is the part that stops things getting skipped, so it matters more than the visuals. Implement all of these; each reports file, line, and a one-sentence fix.

**Structural**
1. Delegate to `reindex.py --check` — fail if `docs/INDEX.md` is stale.
2. Frontmatter completeness on every doc: `id`, `title`, `status`, `owner`, `tags`, `updated`, `related` present; `status` in the four legal values; `updated` a valid ISO date; `owner` in `design|tech|art|process`.
3. Every ID in a `related:` list resolves to a real doc.
4. Every `DES-###`/`TEC-###`/`PRO-###`/`ART-###` mentioned in prose resolves to a real doc — catches references to docs that were planned and never written (`TEC-006` is currently exactly this case, and should surface as a warning, not an error, because `OPEN-QUESTIONS.md` already tracks it).
5. ADR numbers in `PRO-002` are unique and contiguous; every `ADR-###` cited anywhere exists in `PRO-002`.

**Sequencing — the discipline ADR-034 says is the real mechanism**

6. No task in a milestone may be `[~]` or `[x]` while any milestone it `depends` on has a gate that is not `passed`. This is the single most important check in the system: it is the machine version of *"clear a milestone's exit gate before starting the next one."*
7. A gate cannot be `passed` while any task in its milestone is `[ ]` or `[~]` — unless every such task is `[-]` cut.
8. Every doc a milestone's tasks reference must be `accepted` before those tasks can leave `[ ]`.
9. Any open question in `OPEN-QUESTIONS.md` under a "needed before MX" heading blocks MX tasks from leaving `[ ]`. Parse the 🔴/🟡/🟢 sections and the milestone named in the heading.

**Quality**

10. Count `⟨tune⟩` markers per doc. Any doc referenced by a task marked `[x]` that still contains `⟨tune⟩` is reported as *untuned shipped system* — a warning, not an error, since some numbers can only be tuned later.
11. When a task is `[x]`, print the definition of done from `CLAUDE.md §4` (in-editor, exported build, no new debugger errors, save/load survives it, doc updated). The tool cannot verify these — it exists to make skipping them a deliberate act rather than an oversight.

Errors block; warnings print. `--strict` promotes warnings to errors for CI.

## Step 3 — The three views

**Terminal** (default invocation, `python3 tools/status.py`). ANSI colour, degrades to plain when not a TTY or when `NO_COLOR` is set. Roughly:

- A one-line header: current milestone, its gate text, tasks done/total.
- Per-milestone bar showing `[x]`/`[~]`/`[ ]`/`[-]` proportions, weighted by the `size=` attribute so M4 doesn't look equal to M1.
- The gate line for each milestone, with state.
- **Blockers** section: everything from the sequencing checks, in priority order.
- **Next up**: the three lowest-numbered `[ ]` tasks in the current milestone, with their doc references.
- Corpus stats: 35 docs by status, ADR count, open questions by priority, `⟨tune⟩` count.

Keep it under one screen at 80×40. If it doesn't fit, cut stats before cutting blockers.

**`docs/STATUS.md`** — the same content as GitHub-renderable Markdown. Unicode progress bars, tables, and a Mermaid flowchart of the milestone chain with gate states (GitHub renders Mermaid natively). Header comment: `<!-- GENERATED BY tools/status.py — DO NOT EDIT BY HAND -->`.

**`docs/status.html`** — one self-contained file, all CSS inline, zero external requests, works opened from `file://`. This is the view meant for keeping up with progress at a glance, so it earns real design effort:

- Carry the project's own visual language rather than a generic dashboard look — `ART-001` and `ART-005` describe ink, woodcut hatching, lantern-lit contrast. Ink on parchment in light mode, ink-on-black in dark mode, via `prefers-color-scheme`.
- The milestone chain as the primary element, gates rendered as the checkpoints they are.
- Blockers prominent and specific. A blocker the eye slides past is a blocker that gets skipped.
- Responsive; readable on a phone.
- No JavaScript unless a filter genuinely needs it — this is a static report.

## Step 4 — Wiring

- `.claude/commands/status.md` — a slash command running the terminal view, so `/status` works mid-session.
- A line in `docs/README.md §Workflow` adding `python3 tools/status.py` after the `reindex.py` step.
- A line in `CLAUDE.md §6 Tooling` documenting the invocations.

## Scope guard

Stop and report after Step 1, and again after Step 2. Step 1 touches an accepted design doc and Step 2 defines the rules everything else obeys — both are cheaper to correct before the rendering work is built on top of them.

Do not build: burndown charts, velocity metrics, time estimates, or anything that implies a schedule. `ADR-034` removed calendar estimates from this project deliberately; a progress system that smuggles them back in is actively harmful. Percentages describe scope covered, never time remaining.
