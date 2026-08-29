# 2026-08-31 — the CLAUDE.md-hygiene slice

Docs-only slice on branch `chore/claude-md-hygiene` (base
`d0c7de12f`, the semantics-first mainline), executing [USER
2026-08-31, verbatim]: "CLAUDE.md shouldn't be a log of all decisions
— we want it to be a clean working practices doc. And we want to
avoid notes in the overall container (which isn't a repo, and is
local only)." No code, no gates, no baselines touched. [AGENT]
hygiene-slice worker.

## 1. The container CLAUDE.md rewritten

- Before: 89,274 bytes / 1,417 lines — an operating manual buried
  under the full decision chronicle (arc histories 1–18, the
  reasoning-era ACTIVE STATE block, ~40 verbatim rulings).
- After: 13,329 bytes — working practices only: what the project is
  now (semantics product / park / refined-cerberus successor),
  layout, build/env, worktrees, the surviving practices (branch
  roles incl. mainline-vs-master, ff-only merges on sign-off, the
  unconditional audit ask, no-push-without-authorization, pin dance,
  validation gate, orchestrator/worker + park-ends-slice, record
  integrity + [AGENT]/[USER] provenance, fail-closed/fail-noisy,
  plant-tested trust-only gates, certification integrity, grind ban
  + tripwire, capped builds + box discipline,
  profile-before-optimizing + classical naming, mirror-OCaml,
  no-internal-trust-gaps + the non-kernel ban, design-pass scope +
  fresh-review rules), offline notes, and pins/known-issues in
  pointer form. The no-machine-global-state rule stays at top.

## 2. The chronicle preserved (committed records)

- `docs/2026-08-31_container-manual-archive.md` — the pre-hygiene
  container CLAUDE.md verbatim (fenced), with an extracted RULINGS
  section up top for the operatively-semantics-relevant rulings
  (no-global-state, grind ban, canon-first/classical naming,
  non-kernel ban, certification integrity, anti-gate-grind,
  mirror-OCaml, no-internal-trust-gaps, heartbeat smell, capped/box
  discipline, record integrity, honest-gaps). Reasoning-era rulings
  stay in the archived body — they live operatively on the park
  branch + the postmortem.
- `docs/2026-08-31_container-roadmap-archive.md` — the container
  `ROADMAP.md` verbatim. [AGENT] adjudication: not explicitly in the
  slice brief's list, but it is a container-level chronicle (its own
  header said "move into a repo if it should be versioned"); archived
  and the container copy deleted.

## 3. Container notes/ retired — the moved-content map

| Was (container) | Now |
|---|---|
| `notes/POSTMORTEM-AND-FORWARD-BRIEF.md` | `lean_frontend/docs/POSTMORTEM-AND-FORWARD-BRIEF.md` (mainline copy — the successor's brief; byte-identical to the park original at `docs/reasoning-era/`) |
| `notes/2026-08-31_semantics-forward-assessment.md` | `lean_frontend/docs/2026-08-31_semantics-forward-assessment.md` |
| `notes/upstream/` (14 drafts + INDEX) | `lean_frontend/docs/upstream-tray/` — chosen over a repo-top-level dir because all fork records live under `lean_frontend/docs/` and a new top-level tree would touch the upstream-diff surface the fork-drift manifest reviews, for no benefit. Older dated records still cite the retired `notes/upstream/` path; the container `notes/README` redirects |
| `notes/corpus2-draft/` (p16–p24, 9 .c) | SOLE-COPY CHECK RAN: not on the park branch (its draft doc cites the container path). Committed to the park FIRST: `arc/segment-ladder` @ `fcfa8934c`, `lean_frontend/docs/reasoning-era/corpus2-draft/`. The tag `park/reasoning-era-20260831` was NOT moved — the preservation commit sits above it on the branch (this record is the note of that) |
| `notes/corpus-draft/` (p01–p15 + p10alt) | DELETED — verified byte-identical, file by file, to the frozen in-repo `lean_frontend/corpus/` |
| `ROADMAP.md` (container root) | archived (§2), container copy deleted |
| container reasoning-era scratch/log dirs (`.arc17-probe-scratch`, `.arc18-c3-probe-scratch`, `.c3-logs`, `.c3b-logs`, `.c3b-probe-scratch`, `.perf-logs`, `.r1-logs`, `.r2-scratch`, `.s2b-scratch`) | DELETED per the ephemeral-only convention (reasoning-era; the park holds anything committed) |
| `.audit-logs/`, `.core-split-logs/`, `.tmp/` | KEPT for now — recent ephemerals backing the just-landed split merge's transcripts; delete at the next slice end per convention |

`notes/` now contains a single `README` pointing at the repo homes.

## 4. Repo CLAUDE.md files vs the standard

- Root `CLAUDE.md`: branch-roles section added (mainline
  `mdd/cerberus-lean`; `master` upstream-tracking, never commit;
  parked branches named as records).
- `lean_frontend/CLAUDE.md`: golden-test example rot fixed (audit
  observation (e): documented fixture `return42` does not exist; the
  real set is `001-return-literal` etc.). Sweep found no decision-log
  paragraphs beyond arc-tag provenance cites (which the standard
  keeps); the file was made practices-shaped at the C3 docs pass.
- lem-lean: NO CLAUDE.md exists (checked) — nothing to prune, no
  lem-lean branch needed.

## 5. Gate confirmation

Docs-only change set; `scripts/ce ./scripts/test_unit.sh` re-run at
slice close on this worktree with the exit code checked explicitly:
exit 0. Verbatim closing lines: `Total: 5 passed, 0 failed`;
`check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in
2 tree(s) + LemLibTest.lean)`; `check_fork_drift: OK`;
`check_fixture_freeze: OK (16 fixture files match the pinned
manifest; name set exact)` — all gate rows OK. (A first attempt
piped through `tail` silently masked a refusal — "env not loaded" —
and reported exit 0; re-run properly. The masked-pipe form is itself
the kind of fail-open instrument this project bans.)
D14 scope verified before archiving: the grep-ban scans
`lean_frontend/test`, `lean_frontend/relsemcore`, and LemLibTest.lean
— docs/ is not scanned, so the archive's mention of banned tactic
names cannot trip it (no gate weakened, no spacing tricks needed).

The record ends the slice.
