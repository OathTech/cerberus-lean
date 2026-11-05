# Worker charter: program termination flushes the streams and runs the `atexit` handlers (tray 24, 25)

Date 2026-11-05. Orchestrator [AGENT]. Branch `fix/stdio-exit-flush`, worktree
`worktrees/cerberus-lean-fix/stdio-exit-flush`, base = mainline `mdd/cerberus-lean` `fc3961dc5`
(merge-base upstream `c3ff8c53f`, Lean 4.35.0, lem `e6d8db5`).

## Provenance

- Tray drafts `docs/upstream-tray/24-stdio-buffer-not-flushed-at-exit.md` and
  `docs/upstream-tray/25-atexit-not-run-on-main-return.md` (both TRUE BUG, both Draft, never filed). The
  true-bug audit of 2026-11-04 (orchestrator's scratch `/home/dev/projects/cerberus-lean-proj/.tmp/truebug-audit/`,
  read-only: its rows 24 and 25, its sibling finding on stdio in §4, and Appendix A/B's verbatim runs and probes)
  ranked them second after the rank fix, with an impact upgrade: `__stdout_write` switches stdout to full
  buffering after the first write and nothing flushes at termination, so `puts("a"); puts("b");` prints only
  `a` on the fork's two engines and on pristine; every program with more than one stdout write loses output,
  invisible to the differential lanes because both engines agree.
- [USER 2026-11-04] agreed the fix pass in the audited order; the bar for fork fixes (container
  working-practices doc): only where the standard's intent is very clear or a consumer is blocked, no invented
  semantics; the vicinity rule: fix the mechanism, probe its neighbours, refuse or file what is a judgement call.
  Here the standard is explicit: C17 5.1.2.2.3#1 (reaching the end of `main` or returning from it is equivalent
  to calling `exit` with the returned value), 7.22.4.4#2-#4 (`exit` calls the `atexit` handlers in reverse order,
  then flushes every open stream with unwritten buffered data and closes them), 7.21.3#5 (streams are flushed
  at normal program termination).

## The defect (verified 2026-11-04 on the landed mainline; gcc 13 the referee)

- The shipped libc's `exit` (`runtime/libc/src/stdlib.c:223-227`) runs `__funcs_on_exit()` and then `_Exit`;
  musl's own `exit` calls `__stdio_exit()` between them, and the fork's copy has no such call. `fflush(NULL)`
  (`runtime/libc/src/stdio.c:513-520`) already walks every open `FILE` through `ofl_head`.
- `__stdout_write` (`stdio.c:238-243`) sets `lbf = -1` (full buffering) after the first write unless `F_SVB`:
  musl's behaviour for a non-terminal stdout, correct in itself; it is the missing flush at termination that
  loses the data.
- The return from `main` never reaches `exit`: the driver's `Step_done2 cval` arm (`frontend/model/driver.lem`,
  `process_core_step2`, the terminal arms around `:1336-1360`, `prepare_exit :1314-1322`) takes the value and
  terminates; the Core `exit` builtin (`runtime/libcore/std.core:350-354`, handled at
  `core_reduction.lem:1029`) is reached only by an explicit `exit()` call, which then runs the handlers but,
  per the first bullet, flushes nothing either.
- Measured: `puts("a"); puts("b");` prints `a\n` (gcc `a\nb\n`); `fputs("out", stdout)` prints nothing; an
  `atexit` handler registered in `main` does not run on `return`, runs on `exit()` (audit row 25: `m` where gcc
  prints `m21`). Pristine at the cut behaves the same; upstream's tip carries the same text.

## M1: the fix, both engines by generation and one libc change

- **The driver** (shared Lem, both engines): a return from `main` is equivalent to `exit(ret)`. In libc mode
  (a linked `exit` procedure exists in the Core file; `--nolibc` runs have none and keep today's behaviour,
  stated), the main thread's `Step_done2 cval` on the startup function's return is turned into a call of the
  libc's `exit` with `cval` instead of a termination; the eventual `_Exit` builtin terminates as today with that
  value. Read how the startup function is installed (`driver.lem` around `:1744-1775`, `prepare_main_args`) and
  how `Step_done2` distinguishes the main thread; implement it in the least invasive place that keeps the
  oracle and the Lean engine on one text (the Lem), never in hand-written Lean alone; if the cleanest form is a
  startup wrapper emitted in Core (`exit(main(argc, argv))`), say why and keep the `--nolibc` path unchanged.
  Measure that the exit status, the final `Defined {value: …}` and `stdout` are what gcc gives for every witness.
- **The libc** (`runtime/libc/src/stdlib.c`): `exit` flushes every open stream after the `atexit` handlers and
  before `_Exit` (the standard's order: handlers may write), using the shipped `fflush(NULL)` loop or musl's
  `__stdio_exit` shape, whichever the fork's libc already supports without new machinery; `_Exit`, `abort` and
  `quick_exit` keep their standard behaviour (no stream flush required: 7.22.4.5, 7.22.4.1, 7.22.4.7 — do not
  add one). The libc Core text re-pins (`tests/libc/libc.core*`, the CoreQuote libc digests, the float-literal
  register, as the rank slice did at M1), each with old/new hash and the diff summarised.
- Manifest: the libc source files are not in the manifest's layers (check); `driver.lem` is: single-row edits of
  exactly the driver rows (`[source-content]` and `[expected-semantic]`), a dated NOTE registering the
  fork-ahead delta of the first kind with the standard's clauses and the tray numbers; never `--refresh`. The
  failure-reach register, the stop-site metadata, the fuel/measure census move as the gates decide (the driver
  carries measured workers: if `driver2`'s cone changes, say so; a proof change means kernel replay).

## M2: the vicinity, the witnesses, the moved rows

- Probe the whole termination mechanism on both engines, pristine and gcc: `puts` twice and in a loop, `fputs`,
  `fwrite`, `putchar` then `puts`, `printf` without a trailing newline, `fflush` mid-way then more output,
  `setvbuf` unbuffered/line/full, output to `stderr` (unbuffered: must appear in order), a file opened with
  `fopen` and written but not closed (flushed at exit: 7.22.4.4#4 — check the fork's filesystem seam refuses
  `fopen` (contract D2) and record that path as refused, not a finding), `atexit` handlers: registered in
  `main` and in a nested function, several in reverse order, a handler that writes, a handler that calls
  `exit` (UB: 7.22.4.4#3, declare the fork's reading), `exit()` from a nested function, `_Exit` (no handlers, no
  flush), `abort` (no handlers; the fork's abort path), `quick_exit` with `at_quick_exit`, and `main` returning
  a value above 255 and a negative value (the exit status as gcc's `$?`). Every sibling wrong on conforming
  input or crashing on legal input is fixed if the standard is clear, otherwise refused or filed.
- Witness script `scripts/check_stdio_exit.sh` in ladder row 1 (the D13/rank scripts' shape): the matrix pinned
  to gcc's stdout and exit status on both engines byte for byte, pristine the negative control, plants.
- Measure every gated corpus for moved rows before and after (the libc-mode lanes especially: `tests/libc_exec`,
  the immaculate libc corpus, the libxml2 lanes, the ci sweep, the csmith corpus (its single final `printf` is
  the shape to watch), the pristine lane: a new fork-versus-pristine difference is a `shared-model-fix` register
  row with pristine's wrong stdout quoted). A moved row is upstream's mistake fixed (gcc the referee) or a
  finding; never a silent re-record. Expect many libc-mode rows whose recorded `stdout` was truncated: each is
  dispositioned by its gcc output.

## M3: documentation and the filing

- CONTRACT (D15: termination semantics; the §4.1 witness list; the `--nolibc` statement), VALIDATION (the
  witness row; the lanes whose baselines moved), SUPPORTED, LADDER row 1, TODO (24/25 DONE; the audit's stdio
  sibling closed), trays 24 and 25 merged into one filing to send (the reproducers, the clauses, the locus at
  `c3ff8c53f`, the patch against upstream's `stdlib.c` and `driver.lem`; the INDEX rows), consumer notes for
  cerberus-caesium and cerberus-sl (their recorded stdout expectations for multi-write programs will move), the
  record `docs/2026-11-05_stdio-exit-flush-record.md`.

## Gates and process

- You run the focused gates yourself (the witness with its selftest and plants, `check_fork_drift.sh` with
  `--selftest`, `check_failure_reach.sh`, `check_pin_sites.sh`, `test_stops.py`, `libc_prep.sh --check`, the
  one-file differentials, the corpus measurements, the pristine lane tier-b) and quote last lines verbatim. You
  do NOT run `release.py` and you start no poller, waiter, gate script or sleep loop; runs longer than a few
  minutes go through the harness's background execution. At each milestone commit on your focused gates and
  report; the orchestrator runs Tier A (M1, M2) and the full battery (M3), keeps the evidence and sends the
  lines; no tree edit while an orchestrator run is in flight; one heavy job at a time, 1-minute load below 12.
- Every lake/lean invocation through `scripts/capped` (`CERB_MEM_MAX=32G`); every make/dune/opam/lane command
  through `/home/dev/projects/cerberus-lean-proj/scripts/ce`. Never `pgrep -f`/`pkill`. No network. `/tmp` is
  unreadable: scratch under the worktree's `.tmp/`, deleted at slice end. Never quote the operator; provenance
  tags on every decision; machine outputs verbatim, derived tallies labelled. Never commit on a mainline; nothing
  pushed. Kernel replay is owed if a proof module changes. A blocker the charter does not resolve is a committed
  park record (`docs/2026-11-05_stdio-exit-flush-park.md`) and a stop. The grind tripwire: a single build or
  sweep approaching an hour is a stop-and-report.
- Report format at the end: commit hashes with one line each, `git diff --stat fc3961dc5..HEAD`, every gate's
  last lines verbatim, the vicinity findings table, the moved rows, and what could not be done.
