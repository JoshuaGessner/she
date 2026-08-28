# Agent brief — the session-flow sweep: joining and leaving a game in progress

## 0. The job

A playtester reports: **"There is still an issue with joining and leaving games in
progress."** That is all we have. Several rounds of fixes have already landed in
this area (§3), so assume the remaining faults are the ones that only appear when
**two processes disagree about what scene they are in** or **about whose save is
whose**.

You are auditing the whole of the menu / session / save-state flow in Project SHE
(`/Users/josh/dev/she`, Godot 4.7, GDScript). Your deliverable is **a ranked list
of real, evidenced faults, then fixes for them** — not a refactor, not a feature.

**Two phases, and the gate between them is real:**

- **Phase 1 — audit only. Change no game code.** Produce the report described in
  §7 and stop for sign-off. Reading, running probes, writing throwaway scripts in
  the scratchpad and running the two-process harnesses are all fine.
- **Phase 2 — implement**, on approval, with the discipline in §8.

If Phase 1 turns up nothing beyond what §4 already names, say so plainly. "The
reported symptom is one of these three, and here is which" is a good outcome. A
list padded with theoretical concerns is not.

---

## 1. Read first

- `CLAUDE.md` — the whole thing, but especially §3 (documentation discipline),
  §4 (technical standards, when to commit, **ADR-064: no stubs, no parallel
  fallbacks**), and §8 (the two tests that settle arguments).
- `docs/technical/TEC-004` — the networking constraint. Two claims matter here:
  the host is authoritative over every consequence, and **`GameState` is never
  networked** — each peer writes its own profile and nobody else's.
- `docs/design/DES-003` (the Tithe and persistence), `DES-012` (the fallen, the
  ember, forced extraction), `DES-019` (the Settle beat).
- `docs/process/PRO-002-decision-log.md`, ADR-107 onward. Skim; then read
  ADR-138, 141, 143, 145, 146, 147, 149, 150, 151, 152 properly — they are the
  history of exactly this bug family and they tell you what has already been
  tried and why.

## 2. Working rules (non-negotiable)

- **`python3 -c` and python3 heredoc-on-stdin are blocked** by policy. Write the
  script to a file in the scratchpad, then run the file. Same for any multi-step
  edit: script it to a file with an exact-match assertion, run it, delete it.
- The native `Read` tool misreports file lengths in this repo (it reported 588
  lines for a 2405-line file). **Read with `sed -n 'A,Bp'` / `cat`** and edit with
  scripts that assert `text.count(old) == 1` before replacing.
- `untyped_declaration=2`: an untyped declaration is a **hard parse error**, not a
  warning. Every `var` and every parameter gets a type.
- **No stubs, no placeholders, no parallel fallbacks** (ADR-064). If the right fix
  is a system we have not built, the answer is *absent, with a named `PRO-001`
  task*, not a fake one. `M4-T14` (the Scar) is the recent precedent.
- **A check must never touch the player's `user://`** (ADR-145, ADR-152).
  `RunFile.use_a_scratch_run()` and `SaveFile.use_a_scratch_profile()` first;
  `RunFile.arm()` now refuses the real path inside a probe process, and that
  refusal is load-bearing — do not weaken it to make a check convenient.
- **Every new assertion must be planted before it is believed.** Break the code
  the row is about, confirm *that row by name* fails, restore. A row that could
  have passed before your change is not a check — this has bitten this project
  four separate times and twice in the last session.

## 3. Settled ground — do not re-derive, do not undo

These are accepted ADRs. If you think one is wrong, say so in the report and stop;
changing one requires a new ADR that names it.

| ADR | What it settled |
|---|---|
| 107 | A failed or lost connection returns to the **menu with a reason**, never a quit; the peer goes back to `OfflineMultiplayerPeer`, never `null` |
| 113 | Clients receive their outcome **before** the host takes its own — `change_scene_to_file` detaches synchronously |
| 138 | A run file belongs to a **life**: `resume_is_this_life()` drops an orphaned run rather than entering it |
| 141 | The class question belongs to **the fire, not the menu**, when a life has just ended — one flow, not two screens |
| 143 | A run **opens at the hole** (`Threshold._descend`), not at the menu |
| 145/152 | Checks write to scratch files, never the player's run or profile |
| 146 | The body's attention is a **named claim set** (`hold_attention` / `release_attention`), not a boolean |
| 147 | `GameState.die()` refuses a second death on a life that already ended |
| 149 | Legacy slots clear after payout |
| 150/151 | Solo death names the self-recovery; the run ends on a **press**, via `RunOverScreen`, not a silent clock |
| 152 | Abandoning from the pause menu **costs the life** (`take_what_leaving_costs`), with a confirmation |

## 4. Verified starting leads

Each of these I confirmed **by reading the code**, not by playing. Treat them as
leads to reproduce or refute, not as findings. Reproduce before fixing; a fix
for a fault nobody can trigger is churn.

**A. A client's run file is never cleared.** `RunFile.clear()` is called in
exactly one place that matters — `room_set.gd:3299`, inside `_end_the_run()`,
which returns immediately `if not multiplayer.is_server()`. Clients get
`_take_the_outcome` and a scene change to the Threshold, and nothing clears
`user://run.active` for them. Follow the consequence chain:
`PauseMenu.leaving_ends_the_life()` is `RunFile.exists()`, so a client standing
in the Threshold **after a successful extraction** is told that leaving ends
their life, and `_leave()` calls `GameState.die()` — losing stash and rank for
walking out of camp after a run they survived. Solo is unaffected because solo
*is* the host. This is the single best candidate for the report as written.

**B. Nothing gates a late join.** `CoopSession` is instantiated per level
(`threshold.gd:54`, `room_set.gd:154`), and the ENet peer outlives scene changes.
The host never calls `refuse_new_connections`, and `_on_peer_connected`
(`coop_session.gd:556`) spawns a body immediately. So a peer that connects while
the host is in `room_set` gets a body spawned into a floor while its own process
is building a **Threshold**. Node paths then disagree across peers — the exact
shape of the `"Node not found: Threshold/CoopSession/Spawner"` failure ADR-113
documents. Decide deliberately: **either** joining in progress is refused with a
readable reason (cheap, honest, and probably right for the vertical slice),
**or** it is supported and the joiner is told which scene to load. Do not leave
it undefined. Whichever you pick, `MAX_CLIENTS` is also never enforced — check
what a fifth peer does.

**C. `_enter()` is one path for three roles.** `main_menu.gd:267` loads the
profile, arms the run file, resumes a suspended run, or opens class select —
identically for SOLO, HOST and CLIENT, before any connection exists. Ask what a
**client** with its own suspended solo run does here: `resume_is_this_life()`
sends it to the Threshold, where it connects to a host who may be anywhere. Ask
whether a joiner should be answering the Legacy screen or class select *while the
host is waiting at the hole*. There may be no bug; there is definitely no
decision on record.

**D. Losing the host leaves a life half-open.** `_give_up()`
(`coop_session.gd:380`) returns to the menu and clears nothing: the client's
`run.active` still exists, `class_id` is unchanged, and its carried loot is in a
world that is gone. Re-entering resumes a run that belongs to a session it can
never rejoin. Contrast with `PauseMenu._leave`, which closes the peer and takes
the cost deliberately. What *should* a dropped client keep? `DES-012`'s forced
extraction is `M3`; check whether it is built, and if not, say so rather than
approximating it.

**E. A peer leaving mid-run interacts with the wipe.**
`_on_peer_disconnected` (`coop_session.gd:561`) frees the body and erases the
seat. Then read `_the_party_is_gone()`, the `party_wipe_seconds` window in
`_watch_for_a_wipe`, `_borne_out`, and `_end_the_run`'s per-peer loop. Questions
to answer with evidence: does the last client rage-quitting read as a wipe for
the host? Does a peer that leaves during the run-over window ever receive an
outcome? Does `_borne_out` survive a body being freed? Does the host leaving
mid-run resolve the run for anyone?

**F. Screens across scene changes.** The attention claims — `pause`, `legacy`,
`pact`, `run_over` — and the screens that own them (`RunOverScreen`,
`LegacyScreen`, `ClassScreen`, `PauseMenu`, `ArrivalBrief`, `BagScreen`). Walk
every path that changes scene or frees a body **while a screen is up**, and
confirm the claim is released and the layer is freed. This is the family the
original report was about ("it still showed the death screen with the new run
playing behind it"), and it now has structure (ADR-146) — your job is to find the
paths that structure does not yet cover. `_put_the_screen_away()` in
`room_set.gd` is the model to compare against.

**G. One `user://` per machine.** Two processes on one machine share
`profile.json` and `run.active` — including `run_coop.py`'s two windows. Work out
whether that can corrupt a real tester's save during same-machine co-op testing,
and whether the harnesses need separating. This may be harness-only. Say which.

**H. Neither two-process harness covers this.** `run_doorway.py` walks a party
through the descent; `run_coop.py --smoke` asserts replication agreement. Neither
one has a peer **join late** or **leave early**. Whatever you fix in Phase 2 needs
a check at this level, because the fault is by definition about two processes.

## 5. The state model — write it down before you read more code

Six things can be wrong, and most of these bugs are two of them disagreeing:

| State | Lives in | Cleared by |
|---|---|---|
| Profile (v9) | `user://profile.json`, `SaveFile` | never; migrated |
| Open run | `user://run.active`, `RunFile` | `_end_the_run` — **host only**, see lead A |
| The life | `GameState.class_id`, `last_life`, stash, rank, tree | `die()` |
| Role and error | `NetPlan.role`, `NetPlan.last_error` | `_show_root`, `_give_up` |
| The peer | `multiplayer.multiplayer_peer` | `_leave`, `_give_up` |
| The body's attention | `Player._attention` claim set | each claim's owner |

For every transition in §6, state what each of the six should be **before** and
**after**, on **each peer**. Most of the findings will fall out of filling that
in; the ones that do not are the interesting ones.

## 6. The matrix to walk

Rows are transitions; walk each one as **solo**, as **host**, and as **client**.
Say explicitly where a cell is impossible, and why.

1. Menu → descend, first life ever
2. Menu → descend, life after a death (Legacy screen at the fire)
3. Menu → descend, with a suspended run open
4. Menu → descend, with a suspended run belonging to a *different* life
5. Join while the host is at the Threshold
6. **Join while the host is in the Deep** (lead B)
7. Host descends while a client is in class select / Legacy / settings
8. Extraction, all alive
9. Extraction, one member spent and borne out (`M3-T33`)
10. Party wipe, run-over screen, someone presses to end it
11. Party wipe, someone recovers inside the window
12. Solo death → run-over screen → back to the Threshold
13. **Client abandons from the pause menu mid-run** (lead A, D)
14. **Host abandons from the pause menu mid-run** — what do clients see?
15. Client's process is killed mid-run (host's view)
16. Host's process is killed mid-run (client's view)
17. Return to the Threshold, then to the menu, then descend again — twice
18. Chamber: tithe, Legacy, respec, then out — with a client present

## 7. Phase 1 deliverable

A written report. For each finding:

- **Symptom** in one sentence, as a player would describe it.
- **Evidence**: `file.gd:line` for every claim, plus either a probe row, a
  two-process log, or a walked reproduction. "It looks like" is not a finding.
- **Which invariant it breaks** (§9).
- **Reachable in a shipped build?** — or only in the harness. Say which.
- **Severity**, on the money: does it lose a player's stash, or is it a cosmetic
  screen that closes itself a frame later?
- **Proposed fix, and its cost** — *trivial / a weekend / a whole system*. If the
  honest fix is a system we have not built, say so and propose the `PRO-001` task
  instead of a stub.

Then: the fix order you recommend, and anything you deliberately are **not**
proposing to fix, with the reason. **Stop there for sign-off.**

## 8. Phase 2 — implementing

Per fault, or per coherent group of faults:

1. The fix, in the smallest place that can be correct — prefer removing a path
   over adding a corrective layer.
2. A check that fails without it. Prefer extending an existing probe
   (`--menu-probe`, `--class-probe`, `--threshold-probe`, `--run-probe`,
   `--wipe-probe`, `--ember-probe`) over inventing a new one; for anything about
   two processes, extend `run_coop.py --smoke` or `run_doorway.py`.
3. **Plant every new row's violation** and confirm the row fails by name.
4. An ADR in `PRO-002` and a task in `PRO-001` — the ADR says what was broken,
   what nothing caught it, and why the fix has the shape it has.
5. The full sweep, in order:
   ```
   python3 tools/reindex.py
   python3 tools/status.py --write
   python3 tools/status.py --check
   python3 tools/check_project.py
   python3 tools/check_dead.py
   GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/check_scripts.sh
   ```
   A failing check is a blocked commit, not a note in the commit message.
6. One commit per task or decision, subject carrying the ID, then push to
   `origin main`, then republish the descent board:
   ```
   python3 tools/status.py --fragment "${TMPDIR:-/tmp}/she-descent-board.html"
   ```
   and call the **Artifact** tool with that file and the `url` in
   `tools/artifact.json` — passing that exact url is what updates the board in
   place instead of orphaning it.

## 9. The invariants this sweep should be able to state as rules

By the end, each of these should be either true and asserted, or a filed task:

1. **One owner of the body at a time.** Every attention claim is released on
   every path out of the screen that took it, including the paths that change
   scene or free the body.
2. **A run file belongs to a life, and to one machine's copy of it.** Entering
   never resumes another life's run, never silently discards a live one, and a
   run that has resolved is not still open for *anyone* who was in it.
3. **Nobody writes anybody else's profile** (TEC-004). The host reports; each
   peer writes.
4. **Leaving costs what staying would have cost, exactly once** (ADR-050,
   ADR-152) — and a run that has already ended costs nothing more.
5. **No path reaches the menu with a life half-ended** — a class cleared but a
   `last_life` unanswered, or a death record with no screen to answer it.
6. **A peer that disconnects mid-run either receives its outcome or keeps a
   resumable run.** Never both, never neither.
7. **Every scene change is preceded by tearing down what must not survive it** —
   screens, claims, and the peer, deliberately, in that order.

## 10. Out of scope

Steam lobbies and relay (`M4-T07`), the Settle screen (`DES-019`), the Scar
(`M4-T14`), latency and packet loss, and any new UI that is not a fix for a fault
you evidenced. If the sweep suggests one of these, file it in `PRO-001` and move
on.
