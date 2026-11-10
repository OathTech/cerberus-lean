# Worker charter: the reporting slice (documents only)

Date 2026-11-10. Orchestrator [AGENT]. Branch `docs/reporting`, worktree `worktrees/cerberus-lean-docs/reporting`,
base = mainline `mdd/cerberus-lean` `b66374eac`. Roadmap: `docs/2026-11-10_roadmap-maintenance-and-reporting.md`,
active item 2 ([USER 2026-11-10]). A second worker re-pins lem in `worktrees/cerberus-lean-arc/todo54-repin` and the
shared opam `lem` moves under it: do NOT regenerate (`make prelude-src`), do not run `test_unit.sh` or the pin
gates here; your built engines stay as primed. No semantic file changes in this slice: `frontend/`, `ocaml_frontend/`,
`memory/`, `runtime/`, `lean_frontend/*.lean`, the gates and baselines are read-only.

## Goal

Turn what the project found into reports upstream can use without this repository's context. Inputs: the tray
(`docs/upstream-tray/`, 70 reports, INDEX.md) and the true-bug audit of 2026-11-04 (orchestrator scratch,
`/home/dev/projects/cerberus-lean-proj/.tmp/truebug-audit/2026-11-04_true-bug-audit.md` and `probes/`, read-only; it
is deleted when this slice lands, so anything worth keeping must be in a committed file by then).

## M1: the audit into the tray

- Each of the audit's sibling findings not already in a report becomes a report (or a section of the report that owns
  the mechanism), in the tray's form: a minimal reproducer verbatim, what pristine upstream at `c3ff8c53f` prints
  (re-run it: `/home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream`, read-only, `--runtime=_build/install/default`),
  what gcc 13 prints, the C17 clause, the locus by file:line at `c3ff8c53f`. No patch is written in this slice.
- The audit's list of report texts that are wrong or stale: correct each, re-running its reproducer on pristine.
- The crash sites (wide characters, statement expressions, multi-character/UTF-8/UCN constants, the argv store
  `driver.lem` `prepare_main_args`, the GNU `?:` in integer-constant contexts, `bswap64`, `aligned_alloc(…, 0)`, the
  braced-initializer and incomplete-struct crashes) and the shipped library's false-UB items (trays 30, 31, `sscanf`),
  the nested-initializer item (08) and string-literal members (23): each has a current, re-run report. They are
  reported, not fixed.
- Every statement about pristine is one you ran today; quote outputs verbatim; a reproducer that no longer
  reproduces is said so and the report marked.

## M2: the index and the corpora

- INDEX.md gains two columns for every report: CLASS — `semantics` (a question of C's meaning any implementation of
  the model must answer: wrong value, false UB, missed UB, missing feature) / `robustness` (a crash or internal error
  on valid input) / `code` (an artifact of the present code or build: a typo, a printer, a stale path) — and STATE in
  the fork (fixed with contract number / refused with contract number / unchanged). A short header says how to read
  it. Counts stated as derived.
- `docs/upstream-tray/CORPORA.md`: one index of the witness corpora (`tests/macro_type_ranks`, `stdio_exit`,
  `printf_refusals`, `address_constants`, `half_mirrors`, and the refusal witnesses' directories): per corpus the
  number of programs, what `expected.txt`/`gcc.txt`/`pristine.txt` mean, the gcc version and flags the pins came
  from, which report each group of programs belongs to, and a plain command that runs ONE program on a Cerberus
  binary and compares the line (no ladder, no fork paths). Do not move or edit the corpora.
- `TODO.md`: a short header paragraph pointing at the roadmap and marking which sections are active and which are
  "reported, not started" (no entry deleted or renumbered).

## Process

Probes: the primed fork engines, pristine and gcc only; one process at a time; check `/proc/loadavg` (< 12) first;
long sweeps through the harness's background execution; no poller, watcher or sleep loop; never `pgrep -f`/`pkill`;
no network; `/tmp` unreadable; scratch under the worktree's `.tmp/`, deleted at the end. Never `scripts/release.py`.
Never quote the operator; provenance tags on decisions; do not speculate in any document about upstream's plans or
intentions: describe the code at `c3ff8c53f` and nothing else. Commits per milestone, docs only (verify with
`git diff --stat`: nothing outside `lean_frontend/docs/`, `lean_frontend/TODO.md`), messages end with
`Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Nothing pushed; no mainline commit. A blocker: a
committed park record and a stop.
Report: hashes, the diff stat, the INDEX counts by class and state, the list of new and corrected reports, every
reproducer that changed behaviour, what was not done.
