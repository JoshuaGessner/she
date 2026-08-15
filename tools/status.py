#!/usr/bin/env python3
"""Render and validate Project SHE milestone progress, read out of docs/.

Usage:
    python3 tools/status.py             # terminal dashboard
    python3 tools/status.py --write     # regenerate docs/STATUS.md + docs/status.html
    python3 tools/status.py --check     # CI-safe: exit 1 on any error
    python3 tools/status.py --check --strict    # warnings count as errors too

Single source of truth is PRO-001: milestone comments, checkbox tasks with
permanent IDs, and gate lines (ADR-063). Nothing here writes to a design doc —
the only outputs are STATUS.md and status.html.

The point of the checks is sequencing. ADR-034 removed deadlines, which means
the exit gates are the only mechanism left that stops one milestone bleeding
into the next; PRO-007 names "M1 never ends" as the top project risk. So the
load-bearing rule is check `gate-order`: no task may start while the milestone
it depends on has an unpassed gate.

Deliberately dependency-free, and reuses reindex.py's frontmatter parser rather
than growing a second dialect of the same flat YAML subset.
"""

from __future__ import annotations

import html
import os
import re
import subprocess
import sys
from datetime import date
from pathlib import Path
from typing import NamedTuple

sys.path.insert(0, str(Path(__file__).resolve().parent))
from reindex import DOCS, ROOT, parse_frontmatter  # noqa: E402

ROADMAP = DOCS / "process" / "PRO-001-roadmap-and-milestones.md"
DECISIONS = DOCS / "process" / "PRO-002-decision-log.md"
QUESTIONS = DOCS / "OPEN-QUESTIONS.md"
STATUS_MD = DOCS / "STATUS.md"
STATUS_HTML = DOCS / "status.html"

# The line carrying the regeneration date, ignored when comparing for staleness.
STAMP = "generated-stamp"

DOC_ID = r"(?:DES|TEC|PRO|ART)-\d{3}"
LEGAL_STATUS = ("draft", "proposed", "accepted", "superseded")
LEGAL_OWNER = ("design", "tech", "art", "process")
REQUIRED_KEYS = ("id", "title", "status", "owner", "tags", "updated", "related")

TODO, DOING, DONE, CUT = " ", "~", "x", "-"

# A task's doc references are the final "→ IDs" run on the line. Anchoring to
# end-of-line is what keeps prose arrows ("Tribute → Boon → Aspects") from
# being mistaken for metadata.
TASK_RE = re.compile(
    r"^- \[([ x~-])\] `(M\d+-T\d+)` (.*?)"
    rf"(?: → ({DOC_ID}(?:, ?{DOC_ID})*))?\s*$"
)
MILESTONE_RE = re.compile(
    r"^<!-- milestone id=(M\d+)(?:\s+depends=(M\d+))?(?:\s+size=(\S+))?\s*-->$"
)
GATE_RE = re.compile(r"^> \*\*GATE (M\d+) (EXIT|COOP)\*\* `([^`]+)` — (.+)$")
HEADING_RE = re.compile(r"^## (M\d+) — (.+)$")
ADR_HEAD_RE = re.compile(r"^## ADR-(\d{3}) — (.+)$", re.MULTILINE)
GATE_STATE_RE = re.compile(r"^(pending|passed|failed)(?: (\d{4}-\d{2}-\d{2}))?(?: — (.*))?$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
QSECTION_RE = re.compile(r"^##\s+.*needed.*$", re.IGNORECASE)


class Doc(NamedTuple):
    id: str
    title: str
    status: str
    owner: str
    tags: list[str]
    updated: str
    related: list[str]
    path: Path
    text: str


class Task(NamedTuple):
    id: str
    milestone: str
    state: str
    text: str
    docs: list[str]
    line: int


class Gate(NamedTuple):
    milestone: str
    kind: str          # EXIT | COOP
    state: str         # pending | passed | failed
    when: str          # ISO date, or ""
    text: str
    line: int

    @property
    def passed(self) -> bool:
        return self.state == "passed"

    def label(self) -> str:
        return f"{self.state} {self.when}".strip()


class Milestone(NamedTuple):
    id: str
    title: str
    depends: str
    size: float | None      # None == the roadmap never stated one
    tasks: list[Task]
    gates: list[Gate]
    line: int

    @property
    def exit_gate(self) -> Gate | None:
        return next((g for g in self.gates if g.kind == "EXIT"), None)

    @property
    def cleared(self) -> bool:
        """A milestone is cleared only when every gate it declares has passed.

        No gate means not cleared: M6 must not be startable while M5 has no
        defined finish.
        """
        return bool(self.gates) and all(g.passed for g in self.gates)

    def counts(self) -> dict[str, int]:
        return {s: sum(1 for t in self.tasks if t.state == s) for s in (DONE, DOING, TODO, CUT)}

    def live(self) -> list[Task]:
        """Tasks that still count toward completion (cut ones don't)."""
        return [t for t in self.tasks if t.state != CUT]


class Issue(NamedTuple):
    level: str      # error | warn
    code: str
    where: str
    message: str
    fix: str


# ── loading ───────────────────────────────────────────────────────────────


def load_docs() -> dict[str, Doc]:
    docs: dict[str, Doc] = {}
    for path in sorted(DOCS.glob("*/*.md")):
        meta = parse_frontmatter(path)
        if not meta or not meta.get("id"):
            continue
        docs[str(meta["id"])] = Doc(
            id=str(meta["id"]),
            title=str(meta.get("title", path.stem)),
            status=str(meta.get("status", "")),
            owner=str(meta.get("owner", "")),
            tags=[str(t) for t in (meta.get("tags") or [])],
            updated=str(meta.get("updated", "")),
            related=[str(r) for r in (meta.get("related") or [])],
            path=path,
            text=path.read_text(encoding="utf-8"),
        )
    return docs


def load_roadmap() -> tuple[list[Milestone], list[Issue]]:
    """Parse PRO-001 into ordered milestones. Structural complaints come back
    with them, since a milestone that failed to parse can't be checked later."""
    issues: list[Issue] = []
    lines = ROADMAP.read_text(encoding="utf-8").splitlines()

    order: list[str] = []
    titles: dict[str, str] = {}
    heads: dict[str, int] = {}
    meta: dict[str, tuple[str, str | None]] = {}
    tasks: dict[str, list[Task]] = {}
    gates: dict[str, list[Gate]] = {}
    current = ""

    for n, line in enumerate(lines, 1):
        if m := HEADING_RE.match(line):
            current = m.group(1)
            order.append(current)
            titles[current] = plain(m.group(2)).split("  ·  ")[0].strip()
            heads[current] = n
            tasks.setdefault(current, [])
            gates.setdefault(current, [])
            continue

        if m := MILESTONE_RE.match(line):
            mid, depends, raw_size = m.group(1), m.group(2) or "", m.group(3)
            size: str | None = raw_size
            if mid != current:
                issues.append(Issue(
                    "error", "milestone-misplaced", f"{rel(ROADMAP)}:{n}",
                    f"milestone comment for {mid} sits under heading {current or '(none)'}",
                    "move the comment directly under its own `## Mx — …` heading",
                ))
            meta[mid] = (depends, size)
            continue

        if m := GATE_RE.match(line):
            mid, kind, raw_state, text = m.groups()
            sm = GATE_STATE_RE.match(raw_state.strip())
            if not sm:
                issues.append(Issue(
                    "error", "gate-state", f"{rel(ROADMAP)}:{n}",
                    f"{mid} {kind} has unreadable state `{raw_state}`",
                    "use `pending`, `passed YYYY-MM-DD`, or `failed YYYY-MM-DD — reason`",
                ))
                continue
            state, when = sm.group(1), sm.group(2) or ""
            if state in ("passed", "failed") and not when:
                issues.append(Issue(
                    "error", "gate-state", f"{rel(ROADMAP)}:{n}",
                    f"{mid} {kind} is `{state}` without a date",
                    f"write `{state} YYYY-MM-DD`",
                ))
            gates.setdefault(mid, []).append(Gate(mid, kind, state, when, text.strip(), n))
            continue

        if line.startswith("- ["):
            m = TASK_RE.match(line)
            if not m:
                issues.append(Issue(
                    "error", "task-unparsed", f"{rel(ROADMAP)}:{n}",
                    "checkbox line does not match the task format",
                    "use: - [ ] `M1-T01` text → DES-009",
                ))
                continue
            state, tid, text, refs = m.groups()
            docs = [d.strip() for d in refs.split(",")] if refs else []
            owner = tid.split("-")[0]
            if owner != current:
                issues.append(Issue(
                    "error", "task-misfiled", f"{rel(ROADMAP)}:{n}",
                    f"task {tid} appears under {current}",
                    f"move it to {owner}, or renumber it (IDs are permanent — prefer moving)",
                ))
            tasks.setdefault(owner, []).append(
                Task(tid, owner, state, text.strip(), docs, n)
            )

    milestones = []
    for mid in order:
        if mid not in meta:
            issues.append(Issue(
                "error", "milestone-unmarked", f"{rel(ROADMAP)}:{heads[mid]}",
                f"{mid} has no `<!-- milestone … -->` comment",
                f"add `<!-- milestone id={mid} depends=… size=… -->` under the heading",
            ))
        depends, raw_size = meta.get(mid, ("", None))
        size: float | None = None
        if raw_size and raw_size != "unknown":
            try:
                size = float(raw_size)
            except ValueError:
                issues.append(Issue(
                    "error", "milestone-size", f"{rel(ROADMAP)}:{heads[mid]}",
                    f"{mid} has unreadable size `{raw_size}`",
                    "use a number (relative weight) or `unknown`",
                ))
        milestones.append(Milestone(
            id=mid, title=titles[mid], depends=depends, size=size,
            tasks=tasks.get(mid, []), gates=gates.get(mid, []), line=heads[mid],
        ))
    return milestones, issues


def load_adrs() -> dict[int, str]:
    text = DECISIONS.read_text(encoding="utf-8")
    return {int(m.group(1)): m.group(2) for m in ADR_HEAD_RE.finditer(text)}


def load_blocking_questions() -> dict[str, list[str]]:
    """Open questions grouped by the milestone their section names.

    Headings look like "## Needed at M2" or "## Needed at M4 / M5"; a question
    under either blocks work in every milestone named.
    """
    blocking: dict[str, list[str]] = {}
    if not QUESTIONS.exists():
        return blocking
    active: list[str] = []
    for line in QUESTIONS.read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            active = re.findall(r"\bM\d+\b", line) if QSECTION_RE.match(line) else []
            continue
        if not active or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not cells or set(cells[0]) <= set("-: ") or cells[0] in ("#", "Area"):
            continue
        label = f"{cells[0]} {cells[1]}" if len(cells) > 1 else cells[0]
        for mid in active:
            blocking.setdefault(mid, []).append(label.strip())
    return blocking


# ── checks ────────────────────────────────────────────────────────────────


def check_frontmatter(docs: dict[str, Doc]) -> list[Issue]:
    issues = []
    for doc in docs.values():
        where = rel(doc.path)
        meta = parse_frontmatter(doc.path) or {}
        for key in REQUIRED_KEYS:
            if key not in meta:
                issues.append(Issue(
                    "error", "frontmatter", where, f"missing `{key}`",
                    f"add `{key}:` to the frontmatter",
                ))
        if doc.status and doc.status not in LEGAL_STATUS:
            issues.append(Issue(
                "error", "frontmatter", where, f"status `{doc.status}` is not legal",
                f"use one of {', '.join(LEGAL_STATUS)}",
            ))
        if doc.owner and doc.owner not in LEGAL_OWNER:
            issues.append(Issue(
                "error", "frontmatter", where, f"owner `{doc.owner}` is not legal",
                f"use one of {', '.join(LEGAL_OWNER)}",
            ))
        if doc.updated and not DATE_RE.match(doc.updated):
            issues.append(Issue(
                "error", "frontmatter", where, f"updated `{doc.updated}` is not an ISO date",
                "write YYYY-MM-DD",
            ))
        for ref in doc.related:
            if ref not in docs:
                issues.append(Issue(
                    "error", "related-unresolved", where,
                    f"`related` names {ref}, which does not exist",
                    f"remove {ref} or write the doc",
                ))
    return issues


def check_references(docs: dict[str, Doc], adrs: dict[int, str]) -> list[Issue]:
    """Prose references to docs and ADRs that don't exist.

    Warnings, not errors: PRO-001 legitimately points at planned-but-unwritten
    docs (TEC-006, DES-021), and OPEN-QUESTIONS already tracks them.
    """
    issues = []
    missing_docs: dict[str, set[str]] = {}
    missing_adrs: dict[int, set[str]] = {}
    for doc in docs.values():
        body = doc.text.partition("\n---")[2]
        for ref in set(re.findall(DOC_ID, body)):
            if ref not in docs:
                missing_docs.setdefault(ref, set()).add(doc.id)
        for num in {int(x) for x in re.findall(r"ADR-(\d{3})", body)}:
            if num not in adrs:
                missing_adrs.setdefault(num, set()).add(doc.id)
    for ref, where in sorted(missing_docs.items()):
        issues.append(Issue(
            "warn", "doc-unwritten", rel(ROADMAP),
            f"{ref} is referenced by {', '.join(sorted(where))} but not written",
            f"write {ref}, or drop the reference",
        ))
    for num, where in sorted(missing_adrs.items()):
        issues.append(Issue(
            "warn", "adr-missing", rel(DECISIONS),
            f"ADR-{num:03d} is cited by {', '.join(sorted(where))} but has no entry",
            "add the entry, or fix the citation",
        ))
    return issues


def check_adr_numbering(adrs: dict[int, str]) -> list[Issue]:
    issues = []
    text = DECISIONS.read_text(encoding="utf-8")
    seen: dict[int, int] = {}
    for n, line in enumerate(text.splitlines(), 1):
        if m := ADR_HEAD_RE.match(line):
            num = int(m.group(1))
            if num in seen:
                issues.append(Issue(
                    "error", "adr-duplicate", f"{rel(DECISIONS)}:{n}",
                    f"ADR-{num:03d} is used twice (also line {seen[num]})",
                    "renumber the later entry to the next free number",
                ))
            seen[num] = n
    if adrs:
        gaps = sorted(set(range(1, max(adrs) + 1)) - set(adrs))
        if gaps:
            issues.append(Issue(
                "warn", "adr-gap", rel(DECISIONS),
                f"ADR numbers skipped: {', '.join(f'{g:03d}' for g in gaps)}",
                "usually harmless; confirm nothing was deleted rather than superseded",
            ))
    return issues


def check_milestones(milestones: list[Milestone], docs: dict[str, Doc],
                     blocking: dict[str, list[Task]]) -> list[Issue]:
    issues: list[Issue] = []
    by_id = {m.id: m for m in milestones}
    seen_tasks: dict[str, int] = {}

    for ms in milestones:
        for task in ms.tasks:
            where = f"{rel(ROADMAP)}:{task.line}"
            if task.id in seen_tasks:
                issues.append(Issue(
                    "error", "task-duplicate", where,
                    f"task id {task.id} is reused (also line {seen_tasks[task.id]})",
                    "task IDs are permanent and unique — give this one the next free number",
                ))
            seen_tasks[task.id] = task.line

            if not task.docs:
                issues.append(Issue(
                    "error", "task-undocumented", where,
                    f"{task.id} references no doc",
                    "append `→ DES-0NN`; if nothing describes it, the doc is the missing piece",
                ))
            if task.state == CUT and "cut:" not in task.text:
                issues.append(Issue(
                    "error", "cut-unexplained", where,
                    f"{task.id} is cut without a reason",
                    "append ` — cut: <why>` so the decision survives",
                ))
            if task.state != TODO:
                for ref in task.docs:
                    doc = docs.get(ref)
                    if doc and doc.status != "accepted":
                        issues.append(Issue(
                            "error", "doc-not-accepted", where,
                            f"{task.id} is underway but {ref} is `{doc.status}`",
                            f"take {ref} to `accepted` before building against it",
                        ))

        if ms.tasks and not ms.exit_gate:
            issues.append(Issue(
                "warn", "milestone-ungated", f"{rel(ROADMAP)}:{ms.line}",
                f"{ms.id} has tasks but no EXIT gate",
                f"add a GATE {ms.id} EXIT line — without one the milestone can never be "
                "cleared, and nothing may depend on it",
            ))

        started = [t for t in ms.tasks if t.state in (DOING, DONE)]
        dep = by_id.get(ms.depends)
        if started and dep and not dep.cleared:
            open_gates = ", ".join(f"{g.kind} {g.state}" for g in dep.gates) or "no gate at all"
            issues.append(Issue(
                "error", "gate-order", f"{rel(ROADMAP)}:{ms.line}",
                f"{ms.id} has {len(started)} task(s) underway but {dep.id} is not cleared "
                f"({open_gates})",
                f"clear {dep.id} first, or record the gate as passed if it genuinely is",
            ))

        for gate in ms.gates:
            if gate.passed:
                unfinished = [t for t in ms.live() if t.state != DONE]
                if unfinished:
                    issues.append(Issue(
                        "error", "gate-premature", f"{rel(ROADMAP)}:{gate.line}",
                        f"{ms.id} {gate.kind} is passed but "
                        f"{len(unfinished)} task(s) are unfinished",
                        "finish them, cut them with a reason, or reopen the gate",
                    ))
                    break

        if started and blocking.get(ms.id):
            qs = blocking[ms.id]
            issues.append(Issue(
                "error", "question-open", rel(QUESTIONS),
                f"{ms.id} is underway with {len(qs)} unresolved question(s): "
                f"{'; '.join(q.split(' ')[0] for q in qs)}",
                "resolve them into ADRs, or move them out of this milestone's section",
            ))
    return issues


def check_quality(milestones: list[Milestone], docs: dict[str, Doc]) -> list[Issue]:
    issues = []
    implemented: set[str] = set()
    for ms in milestones:
        for task in ms.tasks:
            implemented.update(task.docs)
            if task.state == DONE:
                for ref in task.docs:
                    doc = docs.get(ref)
                    if doc and "⟨tune⟩" in doc.text:
                        count = doc.text.count("⟨tune⟩")
                        issues.append(Issue(
                            "warn", "untuned", rel(doc.path),
                            f"{task.id} is done but {ref} still has {count} ⟨tune⟩ marker(s)",
                            "tune the numbers against play, or accept them as final",
                        ))

    for doc in sorted(docs.values(), key=lambda d: d.id):
        # Process docs describe how work happens, and a vision doc is the standard
        # everything is judged against — neither is something a task implements.
        if doc.owner == "process" or "vision" in doc.tags or doc.status != "accepted":
            continue
        if doc.id not in implemented:
            issues.append(Issue(
                "warn", "doc-unscheduled", rel(doc.path),
                f"{doc.id} {doc.title} is accepted but no milestone task implements it",
                "add it to a milestone, or accept that it is designed and parked",
            ))
    return issues


def run_checks(milestones: list[Milestone], docs: dict[str, Doc], adrs: dict[int, str],
               parse_issues: list[Issue]) -> list[Issue]:
    blocking = load_blocking_questions()
    issues = list(parse_issues)
    issues += check_frontmatter(docs)
    issues += check_references(docs, adrs)
    issues += check_adr_numbering(adrs)
    issues += check_milestones(milestones, docs, blocking)
    issues += check_quality(milestones, docs)
    return issues


def check_index_fresh() -> list[Issue]:
    proc = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "reindex.py"), "--check"],
        capture_output=True, text=True,
    )
    if proc.returncode != 0:
        return [Issue(
            "error", "index-stale", rel(DOCS / "INDEX.md"),
            proc.stderr.strip().splitlines()[0] if proc.stderr.strip() else "index is stale",
            "run: python3 tools/reindex.py",
        )]
    return []


# ── derived state ─────────────────────────────────────────────────────────


def current_milestone(milestones: list[Milestone]) -> Milestone | None:
    """The first milestone that hasn't cleared its gates."""
    return next((m for m in milestones if not m.cleared), None)


def totals(milestones: list[Milestone]) -> tuple[int, int]:
    done = sum(1 for m in milestones for t in m.live() if t.state == DONE)
    live = sum(len(m.live()) for m in milestones)
    return done, live


def corpus_stats(docs: dict[str, Doc], adrs: dict[int, str],
                 blocking: dict[str, list[str]]) -> dict[str, int]:
    return {
        "docs": len(docs),
        "accepted": sum(1 for d in docs.values() if d.status == "accepted"),
        "adrs": len(adrs),
        # A question filed under "Needed at M4 / M5" blocks both, but is one question.
        "questions": len({q for v in blocking.values() for q in v}),
        "tune": sum(d.text.count("⟨tune⟩") for d in docs.values()),
    }


# ── small helpers ─────────────────────────────────────────────────────────


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def plain(text: str) -> str:
    """Markdown inline syntax stripped, for terminal output."""
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"(?<!\*)\*([^*]+?)\*(?!\*)", r"\1", text)
    return text.replace("`", "")


def inline_html(text: str) -> str:
    out = html.escape(text)
    out = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", out)
    out = re.sub(r"(?<!\*)\*([^*]+?)\*(?!\*)", r"<em>\1</em>", out)
    return re.sub(r"`([^`]+?)`", r"<code>\1</code>", out)


def clip(text: str, width: int) -> str:
    return text if len(text) <= width else text[: max(0, width - 1)].rstrip() + "…"


def strip_stamp(text: str) -> str:
    return "\n".join(l for l in text.splitlines() if STAMP not in l)


# ── terminal view ─────────────────────────────────────────────────────────

WIDTH = 78
UNIT = 10           # bar characters per 1.0 of relative size
NOMINAL = 10        # bar width for milestones the roadmap never sized

ANSI = {
    "dim": "\033[2m", "bold": "\033[1m", "gold": "\033[33m",
    "red": "\033[31m", "green": "\033[32m", "reset": "\033[0m",
}


def paint(text: str, *codes: str) -> str:
    if not sys.stdout.isatty() or os.environ.get("NO_COLOR"):
        return text
    return "".join(ANSI[c] for c in codes) + text + ANSI["reset"]


def bar(ms: Milestone) -> tuple[str, str]:
    """Returns (bar, note). Width tracks relative size so M3 reads as twice M1."""
    live = ms.live()
    width = NOMINAL if ms.size is None else max(4, round(ms.size * UNIT))
    if not live:
        return "·" * width, "no tasks"
    counts = ms.counts()
    filled = round(width * counts[DONE] / len(live))
    doing = round(width * counts[DOING] / len(live))
    track = "╌" if ms.size is None else "░"
    body = "█" * filled + "▒" * doing + track * max(0, width - filled - doing)
    note = f"{counts[DONE]}/{len(live)}"
    if ms.size is None:
        note += "  unsized"
    return body, note


def render_terminal(milestones: list[Milestone], docs: dict[str, Doc],
                    adrs: dict[int, str], issues: list[Issue]) -> str:
    cur = current_milestone(milestones)
    blocking = load_blocking_questions()
    out: list[str] = []
    rule = "━" * WIDTH

    out.append(paint(rule, "gold"))
    if cur:
        counts = cur.counts()
        head = f" {cur.id} · {cur.title}"
        gate = cur.exit_gate
        tail = f"{counts[DONE]}/{len(cur.live())} tasks   gate: {gate.label() if gate else '—'} "
        out.append(paint(head, "bold") + " " * max(1, WIDTH - len(head) - len(tail)) + tail)
        if gate:
            out.append(paint(clip(f'   "{plain(gate.text)}"', WIDTH), "dim"))
    else:
        out.append(paint(" All milestones cleared.", "bold", "green"))
    out.append("")

    for ms in milestones:
        body, note = bar(ms)
        label = f" {ms.id} {clip(ms.title, 20):<20}"
        marker = paint("  ◀ current", "gold") if cur and ms.id == cur.id else ""
        if ms.cleared:
            gate = ms.exit_gate
            when = gate.when if gate else ""
            out.append(f"{label} {paint('✔', 'green')} {paint('cleared ' + when, 'dim')}")
        else:
            pad = " " * max(1, (UNIT * 2 + 4) - len(body))
            out.append(f"{label} {body}{pad}{note}{marker}")
    out.append("")

    if cur:
        nxt = [t for t in cur.tasks if t.state == TODO][:3]
        if nxt:
            out.append(paint(" NEXT UP", "bold"))
            for task in nxt:
                text = f"{clip(plain(task.text), 44):<44}"
                out.append(f"   {task.id}  {text}  {paint(' '.join(task.docs), 'dim')}")
            out.append("")

    errors = [i for i in issues if i.level == "error"]
    warns = [i for i in issues if i.level == "warn"]

    out.append(paint(" BLOCKERS", "bold"))
    if not errors:
        out.append(paint("   none — sequencing is clean", "green"))
    for issue in errors:
        out.append(paint(f"   {issue.code:<18} {clip(issue.message, WIDTH - 22)}", "red"))
        out.append(paint(f"   {'':<18} → {clip(issue.fix, WIDTH - 24)}", "dim"))
    out.append("")

    if warns:
        out.append(paint(f" WARNINGS ({len(warns)})", "bold"))
        for issue in warns:
            out.append(f"   {paint(issue.code, 'gold'):<18} {clip(issue.message, WIDTH - 22)}")
        out.append("")

    done_tasks = [t for m in milestones for t in m.tasks if t.state == DONE]
    if done_tasks:
        out.append(paint(" DEFINITION OF DONE — unverifiable by this tool", "bold"))
        out.append(paint("   works in-editor · works in an exported build · no new debugger", "dim"))
        out.append(paint("   errors · save/load survives it · the relevant doc is updated", "dim"))
        out.append(paint(f"   applies to {len(done_tasks)} task(s) marked done", "dim"))
        out.append("")

    stats = corpus_stats(docs, adrs, blocking)
    done, live = totals(milestones)
    out.append(paint(
        f" {done}/{live} tasks · {stats['docs']} docs ({stats['accepted']} accepted) · "
        f"{stats['adrs']} ADRs · {stats['questions']} open Qs · {stats['tune']} ⟨tune⟩", "dim"))
    out.append(paint(rule, "gold"))
    return "\n".join(out)


# ── STATUS.md ─────────────────────────────────────────────────────────────


def md_bar(ms: Milestone) -> str:
    live = ms.live()
    width = 20 if ms.size is None else max(4, round(ms.size * UNIT))
    if not live:
        return "·" * width
    counts = ms.counts()
    filled = round(width * counts[DONE] / len(live))
    doing = round(width * counts[DOING] / len(live))
    return "█" * filled + "▒" * doing + "░" * max(0, width - filled - doing)


def render_markdown(milestones: list[Milestone], docs: dict[str, Doc],
                    adrs: dict[int, str], issues: list[Issue]) -> str:
    cur = current_milestone(milestones)
    blocking = load_blocking_questions()
    stats = corpus_stats(docs, adrs, blocking)
    done, live = totals(milestones)
    errors = [i for i in issues if i.level == "error"]
    warns = [i for i in issues if i.level == "warn"]

    out = [
        "<!-- GENERATED BY tools/status.py — DO NOT EDIT BY HAND -->",
        "",
        "# Project SHE — Status",
        "",
        f"<!-- {STAMP} --> _Regenerated {date.today().isoformat()}_",
        "",
        f"**Current milestone: {cur.id} — {cur.title}**" if cur else "**All milestones cleared.**",
        "",
    ]
    if cur and cur.exit_gate:
        out += [f"> **Gate:** `{cur.exit_gate.label()}` — {cur.exit_gate.text}", ""]
    out += [
        f"`{done}/{live}` tasks complete across the roadmap. "
        f"Progress is **scope covered, never time remaining** (ADR-034).",
        "",
        "```mermaid",
        "flowchart LR",
    ]

    for i, ms in enumerate(milestones):
        counts = ms.counts()
        state = "passed" if ms.cleared else ("current" if cur and ms.id == cur.id else "ahead")
        label = f"{ms.id} {ms.title}<br/>{counts[DONE]}/{len(ms.live())}"
        out.append(f'  {ms.id}["{label}"]:::{state}')
        if i:
            out.append(f"  {milestones[i - 1].id} --> {ms.id}")
    out += [
        "  classDef passed fill:#2d5a3d,stroke:#4a8a5f,color:#fff",
        "  classDef current fill:#8a6a2a,stroke:#c8a04a,color:#fff",
        "  classDef ahead fill:#3a3a3a,stroke:#666,color:#ccc",
        "```",
        "",
        "## Milestones",
        "",
        "| | Milestone | Progress | Done | Gates |",
        "|---|---|---|---|---|",
    ]
    for ms in milestones:
        counts = ms.counts()
        mark = "✔" if ms.cleared else ("▶" if cur and ms.id == cur.id else "")
        gates = "<br>".join(
            f"`{g.kind}` {g.label()}" for g in ms.gates) or "_no gate_"
        cut = f" ({counts[CUT]} cut)" if counts[CUT] else ""
        if ms.tasks:
            size = "unsized" if ms.size is None else f"×{ms.size:g}"
            label = f"**{ms.id}** {ms.title}<br><sub>{size}</sub>"
            out.append(f"| {mark} | {label} | `{md_bar(ms)}` "
                       f"| {counts[DONE]}/{len(ms.live())}{cut} | {gates} |")
        elif ms.cleared:
            # M0's deliverable was the docs themselves — it never had tasks to count.
            out.append(f"| {mark} | **{ms.id}** {ms.title} | — | ✔ | {gates} |")
        else:
            label = f"**{ms.id}** {ms.title}<br><sub>not broken down</sub>"
            out.append(f"| {mark} | {label} | — | — | {gates} |")
    out.append("")

    out += ["## Blockers", ""]
    if errors:
        out += ["| Check | Problem | Fix |", "|---|---|---|"]
        out += [f"| `{i.code}` | {i.message} | {i.fix} |" for i in errors]
    else:
        out.append("_None. Sequencing is clean._")
    out.append("")

    if warns:
        out += ["## Warnings", "", "| Check | Note |", "|---|---|"]
        out += [f"| `{i.code}` | {i.message} |" for i in warns]
        out.append("")

    out += ["## Tasks", ""]
    icon = {DONE: "✔", DOING: "▶", TODO: "·", CUT: "✗"}
    for ms in milestones:
        if not ms.tasks:
            continue
        out += [f"### {ms.id} — {ms.title}", ""]
        for task in ms.tasks:
            refs = " ".join(f"`{d}`" for d in task.docs)
            out.append(f"- {icon[task.state]} `{task.id}` {task.text} {refs}".rstrip())
        out.append("")

    out += [
        "---",
        "",
        f"_{stats['docs']} docs ({stats['accepted']} accepted) · {stats['adrs']} ADRs · "
        f"{stats['questions']} open questions · {stats['tune']} ⟨tune⟩ markers._",
        "",
        "Regenerate with `python3 tools/status.py --write`. "
        "Source of truth is [PRO-001](process/PRO-001-roadmap-and-milestones.md) (ADR-063).",
        "",
    ]
    return "\n".join(out)


# ── status.html ───────────────────────────────────────────────────────────

CSS = """
:root{
  --bg:#e9e0cd; --bg2:#f2ebdc; --ink:#1c1815; --ink2:#5b5044;
  --rule:#c4b79c; --gold:#9a6f24; --gold2:#c89a3c;
  --pass:#3f6b46; --fail:#8d3524; --hatch:rgba(28,24,21,.14);
}
@media (prefers-color-scheme:dark){
  :root{
    --bg:#0e0d0b; --bg2:#17150f; --ink:#e8dfcd; --ink2:#9a9081;
    --rule:#332e24; --gold:#c8a04a; --gold2:#e0bc6a;
    --pass:#6ba36f; --fail:#c4614a; --hatch:rgba(232,223,205,.13);
  }
}
*{box-sizing:border-box}
body{margin:0;padding:clamp(1rem,4vw,3rem);background:var(--bg);color:var(--ink);
  font:16px/1.55 ui-serif,Georgia,"Iowan Old Style",serif;
  background-image:repeating-linear-gradient(45deg,var(--hatch) 0 1px,transparent 1px 7px);
  background-attachment:fixed}
main{max-width:60rem;margin:0 auto}
h1{font-size:clamp(1.6rem,5vw,2.4rem);margin:0;letter-spacing:.14em;text-transform:uppercase}
h2{font-size:1.05rem;letter-spacing:.18em;text-transform:uppercase;color:var(--ink2);
  margin:2.5rem 0 .8rem;font-weight:600}
.sub{color:var(--ink2);margin:.3rem 0 0;font-style:italic}
.card{background:var(--bg2);border:1px solid var(--rule);padding:1rem 1.15rem;margin:.7rem 0}
.now{border-left:4px solid var(--gold)}
.now h3{color:var(--gold)}
.row{display:flex;gap:.75rem;align-items:baseline;flex-wrap:wrap}
.row h3{margin:0;font-size:1.1rem}
.tag{font:600 .7rem/1 ui-monospace,SFMono-Regular,Menlo,monospace;letter-spacing:.1em;
  text-transform:uppercase;color:var(--ink2);border:1px solid var(--rule);padding:.25rem .45rem}
.count{margin-left:auto;font:600 .85rem ui-monospace,monospace;color:var(--ink2)}
.track{display:flex;height:14px;margin:.75rem 0;border:1px solid var(--rule);overflow:hidden}
.done{background:var(--gold)}
.doing{background:repeating-linear-gradient(45deg,var(--gold) 0 2px,transparent 2px 5px)}
.left{background:repeating-linear-gradient(45deg,var(--hatch) 0 1px,transparent 1px 5px)}
.gate{display:flex;gap:.6rem;align-items:flex-start;margin-top:.6rem;padding-top:.6rem;
  border-top:1px dashed var(--rule);font-size:.92rem}
.seal{font:600 .68rem/1.6 ui-monospace,monospace;letter-spacing:.08em;padding:.1rem .45rem;
  border:1px solid currentColor;white-space:nowrap}
.pending{color:var(--ink2)} .passed{color:var(--pass)} .failed{color:var(--fail)}
details{margin-top:.7rem} summary{cursor:pointer;color:var(--ink2);font-size:.9rem}
ul.tasks{list-style:none;padding:0;margin:.6rem 0 0}
ul.tasks li{padding:.3rem 0;border-bottom:1px solid var(--rule);font-size:.93rem;
  display:flex;gap:.6rem;align-items:baseline}
ul.tasks li:last-child{border-bottom:0}
.tid{font:600 .78rem ui-monospace,monospace;color:var(--ink2);white-space:nowrap}
.refs{margin-left:auto;font:.72rem ui-monospace,monospace;color:var(--ink2);white-space:nowrap}
.state{width:1.1em;text-align:center}
.s-x{color:var(--gold)} .s-doing{color:var(--gold2)} .s-cut{color:var(--fail);text-decoration:line-through}
.blocker{border-left:4px solid var(--fail)}
.blocker .code{color:var(--fail)}
/* Warnings are advisory — they must never out-shout the blockers above them. */
.warn{border-left:3px solid var(--gold2);padding:.45rem .8rem;margin:.3rem 0;font-size:.92rem}
.warn .fix{font-size:.85rem}
.code{font:600 .78rem ui-monospace,monospace;letter-spacing:.05em}
.fix{color:var(--ink2);font-style:italic;font-size:.9rem}
.clean{color:var(--pass)}
.stats{display:flex;flex-wrap:wrap;gap:1.5rem;color:var(--ink2);font-size:.88rem;
  border-top:1px solid var(--rule);margin-top:2.5rem;padding-top:1rem}
.stats b{color:var(--ink);font-weight:600}
footer{margin-top:1.2rem;color:var(--ink2);font-size:.82rem}
code{font:.88em ui-monospace,SFMono-Regular,Menlo,monospace}
"""


def html_track(ms: Milestone) -> str:
    live = ms.live()
    if not live:
        return '<div class="track"><span class="left" style="width:100%"></span></div>'
    counts = ms.counts()
    pct = lambda n: 100 * n / len(live)
    return (
        '<div class="track">'
        f'<span class="done" style="width:{pct(counts[DONE]):.1f}%"></span>'
        f'<span class="doing" style="width:{pct(counts[DOING]):.1f}%"></span>'
        f'<span class="left" style="width:{pct(counts[TODO]):.1f}%"></span>'
        "</div>"
    )


def render_html(milestones: list[Milestone], docs: dict[str, Doc],
                adrs: dict[int, str], issues: list[Issue]) -> str:
    cur = current_milestone(milestones)
    blocking = load_blocking_questions()
    stats = corpus_stats(docs, adrs, blocking)
    done, live = totals(milestones)
    errors = [i for i in issues if i.level == "error"]
    warns = [i for i in issues if i.level == "warn"]
    icon = {DONE: ("✔", "s-x"), DOING: ("▶", "s-doing"), TODO: ("·", ""), CUT: ("✗", "s-cut")}

    o: list[str] = [
        "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">",
        '<meta name="viewport" content="width=device-width,initial-scale=1">',
        "<title>Project SHE — Status</title>",
        f"<style>{CSS}</style></head><body><main>",
        "<h1>Project SHE</h1>",
    ]
    if cur:
        gate = cur.exit_gate
        o.append(f'<p class="sub">{cur.id} — {inline_html(cur.title)} · '
                 f"{done}/{live} tasks across the roadmap</p>")
        if gate:
            o.append(f'<p class="sub">“{inline_html(gate.text)}”</p>')
    else:
        o.append('<p class="sub">All milestones cleared.</p>')

    o.append("<h2>Blockers</h2>")
    if errors:
        for i in errors:
            o.append(f'<div class="card blocker"><span class="code">{html.escape(i.code)}</span> '
                     f'{inline_html(i.message)}<br><span class="fix">→ {inline_html(i.fix)} '
                     f'<code>{html.escape(i.where)}</code></span></div>')
    else:
        o.append('<div class="card"><span class="clean">None. '
                 "Sequencing is clean — nothing has started ahead of its gate.</span></div>")

    o.append("<h2>Milestones</h2>")
    for ms in milestones:
        counts = ms.counts()
        klass = "card now" if cur and ms.id == cur.id else "card"
        size = "unsized" if ms.size is None else f"×{ms.size:g}"
        tag = f'<span class="tag">{size}</span>' if ms.tasks else ""
        count = f"{counts[DONE]}/{len(ms.live())}" if ms.tasks else ("✔" if ms.cleared else "—")
        o.append(f'<div class="{klass}"><div class="row">'
                 f'<h3>{ms.id} — {inline_html(ms.title)}</h3>{tag}'
                 f'<span class="count">{count}</span></div>')
        if ms.tasks:
            o.append(html_track(ms))
        elif not ms.cleared:
            o.append('<p class="fix">No tasks yet — this milestone is on the roadmap '
                     "but has not been broken down into work.</p>")
        for g in ms.gates:
            o.append(f'<div class="gate"><span class="seal {g.state}">{g.kind} '
                     f"{html.escape(g.label())}</span><span>{inline_html(g.text)}</span></div>")
        if not ms.gates and ms.tasks:
            o.append('<div class="gate"><span class="seal failed">NO GATE</span>'
                     "<span>This milestone declares no exit gate, so it can never be "
                     "cleared and nothing may depend on it.</span></div>")
        if ms.tasks:
            o.append(f"<details><summary>{len(ms.tasks)} tasks</summary><ul class=\"tasks\">")
            for t in ms.tasks:
                mark, cls = icon[t.state]
                refs = " ".join(t.docs)
                o.append(f'<li><span class="state {cls}">{mark}</span>'
                         f'<span class="tid">{t.id}</span>'
                         f"<span>{inline_html(t.text)}</span>"
                         f'<span class="refs">{html.escape(refs)}</span></li>')
            o.append("</ul></details>")
        o.append("</div>")

    if warns:
        o.append(f"<h2>Warnings ({len(warns)})</h2>")
        for i in warns:
            o.append(f'<div class="card warn"><span class="code">{html.escape(i.code)}</span> '
                     f"{inline_html(i.message)}<br>"
                     f'<span class="fix">→ {inline_html(i.fix)}</span></div>')

    o.append(f'<div class="stats"><span><b>{stats["docs"]}</b> docs</span>'
             f'<span><b>{stats["accepted"]}</b> accepted</span>'
             f'<span><b>{stats["adrs"]}</b> ADRs</span>'
             f'<span><b>{stats["questions"]}</b> open questions</span>'
             f'<span><b>{stats["tune"]}</b> ⟨tune⟩ markers</span></div>')
    o.append(f'<footer><!-- {STAMP} -->Regenerated {date.today().isoformat()} by '
             "<code>tools/status.py --write</code>. Source of truth: "
             "<code>PRO-001</code> (ADR-063). Progress is scope covered, "
             "never time remaining (ADR-034).</footer>")
    o.append("</main></body></html>")
    return "\n".join(o) + "\n"


# ── entry point ───────────────────────────────────────────────────────────


def main() -> int:
    args = sys.argv[1:]
    check = "--check" in args
    write = "--write" in args
    strict = "--strict" in args

    if not ROADMAP.exists():
        print(f"missing {rel(ROADMAP)}", file=sys.stderr)
        return 1

    docs = load_docs()
    adrs = load_adrs()
    milestones, parse_issues = load_roadmap()
    issues = run_checks(milestones, docs, adrs, parse_issues)
    if check:
        issues += check_index_fresh()

    markdown = render_markdown(milestones, docs, adrs, issues)
    page = render_html(milestones, docs, adrs, issues)

    if write:
        STATUS_MD.write_text(markdown, encoding="utf-8")
        STATUS_HTML.write_text(page, encoding="utf-8")
        print(f"wrote {rel(STATUS_MD)} and {rel(STATUS_HTML)}")

    if check:
        for name, fresh in ((STATUS_MD, markdown), (STATUS_HTML, page)):
            current = name.read_text(encoding="utf-8") if name.exists() else ""
            if strip_stamp(current) != strip_stamp(fresh):
                issues.append(Issue(
                    "error", "status-stale", rel(name), f"{rel(name)} is out of date",
                    "run: python3 tools/status.py --write",
                ))
        errors = [i for i in issues if i.level == "error"]
        warns = [i for i in issues if i.level == "warn"]
        for i in errors + warns:
            print(f"{i.level:<5} {i.code:<18} {i.where}: {i.message}", file=sys.stderr)
            print(f"{'':<5} {'':<18} → {i.fix}", file=sys.stderr)
        if errors or (strict and warns):
            print(f"\n{len(errors)} error(s), {len(warns)} warning(s)", file=sys.stderr)
            return 1
        print(f"checks pass ({len(warns)} warning(s))")
        return 0

    if not write:
        print(render_terminal(milestones, docs, adrs, issues))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
