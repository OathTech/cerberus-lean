# Consumer note for cerberus-caesium: program termination flushes the streams and runs the `atexit` handlers (2026-11-06)

From: the `fix/stdio-exit-flush` worker [AGENT]. Occasion: your pins of the fork carry libc-mode runs (the Core-quotation libc round trips and your refinement harnesses print through `printf`), so the three consumer-visible consequences below — more stdout, the printf-format UB location inside the library, the libc-mode address layout — reach them at the next re-pin. Record `docs/2026-11-05_stdio-exit-flush-record.md`; witness
`scripts/check_stdio_exit.sh` (ladder row 1); trays 24 and 25 (merged into one filing); contract D15.

What moved, in one paragraph: with the C library linked, a return from the startup function is the library's
`exit(status)` (C17 5.1.2.2.3 — the SHARED driver's `Step_done2` arm installs the call when the linked Core file defines
`exit`), the library's `exit` flushes every open stream after the `atexit` handlers (7.22.4.4#2-#4), each engine withholds
std.core's `printf` proxy from a libc-mode program so `printf` resolves by linking to the library's own `printf` and its
output is sequenced with the `FILE` buffer (7.21.3; `vfprintf` flushes the pending buffer before the builtin writes
through the descriptor), and `vprintf` is defined (7.21.6.10). `--nolibc` is unchanged for every program that does not itself define `exit` with external linkage (UB C17 7.1.3): the 787-program nolibc sweep moved nothing; a program-defined `exit` of the library's shape `void (signed int)` is routed like the library's and, should it return, is refused by a loud kill (never a second routing, never a verdict); a definition of another shape is not routed (the pre-merge review's P2-1).

What this means for a pin of the fork at or after this branch:

- Every libc-mode program whose last write was not newline-terminated, or that made more than one `FILE` write, or that
  registered an `atexit` handler and returned from `main`, prints MORE than before — exactly gcc's stdout (`puts("a");
  puts("b")` printed `a\n`, now `a\nb\n`; `fputs("out", stdout)` printed nothing, now `out`; the handlers run in reverse
  order on `return`). Any recorded stdout expectation of such a program moves; a program that used `exit()` already got
  its handlers and now gets its buffer flushed too.
- A printf-format UB of a libc-mode program (`UB153b_illtyped_argument_for_format`, `Invalid_format`, …) is now raised
  INSIDE the library's `vfprintf` (`stdio.c:717`, the builtin call) rather than at the program's `printf` call — as
  `fprintf`'s always was; on the Lean engine that location is `<unknown location>` (the libc Core text transport, N4).
  A recorded location for such a UB moves; the verdict and ub id do not.
- The libc-mode global LAYOUT moved: the edited library TUs' source digests order the linked globals (`merge_globs`), so
  every address a libc-mode program prints moved (program globals by up to ~1.9 KB — `012-global-alloc-order`'s `s1`
  281474976707472 → 281474976709344 —, locals by four bytes, e.g. `&j=(@70, 0xffffffffede8)` → `(@70, 0xffffffffedec)`; the
  allocation ids with them) with every value identical. Address-pinning expectations in libc mode move; nolibc
  ones do not. The pristine lane's register gained the class `address-layout` for this (both engines right).
- A `printf` call costs the library's varargs path now (010-int32-printf 1249 → 1509 driver steps, 011-decimal-sweep
  31540 → 83540, 0.32 → 0.46 s wall; a measurement, not a threshold); fuel budgets near their limit on printf-heavy
  libc-mode programs may need headroom.
- The libc dumps and their pins were re-derived twice (`tests/libc/libc.core.sha256` `fae6ce64…` → `1b66d265…` →
  `519d7c92…`; `core-quote-libc.sha256` `dc09e554…` → `a187580c…` → `0a845b19…`; the inner_arg_temps pair likewise):
  `exit` (+31 lines), `vfprintf` (+85), `proc vprintf` (+58), the glob order moved, every later symbol renumbered.
- The driver's seams: `driver.lem` gained `startup_exit_call_opt` (:1347-1368) and the arm's `Just` branch (:1395-1424);
  the generated `Driver.lean` changed in those places and in the `hack` doc comment; `process_core_step2`'s `Step_done2`
  arm now branches on `startup_exit_call_opt dr_st cval` BEFORE `prepare_exit` — a proof that unfolds that arm (the
  exemplar's `process_done` did) needs the hypothesis `startup_exit_call_opt eds tds dst v = none` (true whenever the
  file's extern map defines no `exit`, by `rfl` on a concrete file); the measured/absorbing fuel forms, the failure-reach
  register (238), the hack hypothesis (its invariant text re-cited) and every reader signature are unchanged; kernel
  replay over the Driver and exemplar modules exit 0. `Main.lean` withholds `printf` from the stdlib ailnames under
  `--libc` for the program's TUs (`loadLibc`'s twelve library TUs keep the full map).
- Declared, pinned to the fork's own line: the exit status beyond 0..255 is the C int (`Specified(300)`; the host's `$?`
  is n mod 256); `_Exit`/`quick_exit`/`abort` after buffered output print the lines the shipped library wrote through
  before turning fully buffered (7.22.4.5#2; gcc with a pipe prints nothing); a handler that calls `exit` follows the
  shipped library's (musl's) text; `fopen` is the D2 refusal; `perror`/`strerror` assert (the audit's K2 rows, unchanged).
