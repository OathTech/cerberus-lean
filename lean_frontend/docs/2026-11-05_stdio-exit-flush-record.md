# Program termination runs the `atexit` handlers and flushes the streams (tray 24, 25) — slice record (2026-11-06)

Branch `fix/stdio-exit-flush`, worktree `worktrees/cerberus-lean-fix/stdio-exit-flush`, from mainline `mdd/cerberus-lean` =
`fc3961dc5` (merge-base upstream `c3ff8c53f`, Lean 4.35.0, lem `e6d8db5`); charter
`docs/2026-11-05_worker-charter-stdio-exit-flush.md` (commit `4ede5c560`). Worker: Claude Fable 5.1 (agent). Every judgement
below that no operator ruling covers is marked [AGENT]. Status: FILLED AT M3.

## 0. Rulings and standing rules

- [USER 2026-11-04] agreed the fix pass in the audited order; the bar for fork fixes: only where the standard's intent is very
  clear or a consumer is blocked, no invented semantics; the vicinity rule: fix the mechanism, probe its neighbours, refuse or
  file what is a judgement call. The clauses here: C17 5.1.2.2.3, 7.22.4.4#2-#4, 7.21.3#5 (the charter's provenance).
- [AGENT 2026-11-06, orchestrator] rulings on the worker's design report, all as proposed: (a) the `Step_done2` arm in
  driver.lem — the startup return recognised by the initial thread's empty stack and `current_proc_opt = Just _`, `exit`
  resolved through the extern map (libc mode), today's path by construction otherwise, the status object under the calling
  convention's shape, impossible shapes ND kills, no Core startup wrapper; the never-killed status temp stated with its reason;
  (b) `exit`: handlers, `fflush(NULL)`, `_Exit`; `_Exit`/`abort`/`quick_exit` untouched; (c) the hack hypothesis text amended,
  the exemplar's `process_done` discharged on the new branch, kernel replay over the Driver and exemplar modules, the driver2
  axiom leg re-run; (e)1 the implementation-defined rows pinned to the fork's own line with 7.22.4.5#2 cited and gcc's line
  beside; the handler-calls-exit case pinned to the shipped library's (musl's) text; (e)2 the exit status through
  `Specified(n)`, `$?` derived; (e)3 the vfprintf flush in M1 (a stream's writes are ordered, 7.21.3); (e)5 041's header
  rewritten, every moved row dispositioned by gcc.
- [AGENT 2026-11-06, orchestrator] ruling on the M1 finding (the elaborator's proxy substitution for `printf` in libc mode):
  option (ii) — `stdio.h` routes a libc-mode `printf(...)` to `fprintf(stdout, __VA_ARGS__)` under `CERB_WITH_LIB` (7.1.4#1);
  recorded reasons: it keeps upstream's shipped buffering exactly (unbuffered stdout would decide an implementation-defined
  aspect, 7.21.3#7, differently from upstream's library) and undoes only the proxy shortcut for the one builtin that bypasses a
  buffered stream; the residual (`(printf)(...)`, `&printf`) declared with a witness and a line in the filing; the per-call
  cost measured and recorded (a measurement, not a threshold).
- [AGENT 2026-11-06, orchestrator] REVISED ruling on the proxy finding (M1c, after Tier A on the M1b tip): the LOAD-TIME rule
  replaces the header macro — each engine withholds the `printf` proxy name at its std.core prelude under its own libc mode
  (`backend/driver/main.ml` `prelude`: `Pmap.remove "printf"` under `not nolibc`; `lean_frontend/Main.lean` mirrors it at
  its stdlib load with the cite, `fmapDeleteBy defaultCompare "printf"` under `--libc`, the library's own twelve TUs keeping
  the full map as the oracle builds libc.co under `--nolibc`). Reasons: (1) a preprocessor define whose source of truth is
  the EXPORT invocation cannot be made consistent across the two engines' input paths — `CERB_WITH_LIB` is `-D`'d exactly
  when the cpp invocation lacks `--nolibc` (main.ml:41), and the lanes export the Lean engine's Cabs JSON with the opposite
  flag to the Lean run's mode: the nolibc lanes without `--nolibc` (test_exec.sh:449, the rank witness), the inner_arg_temps
  lane with `--nolibc` for every row (inner_arg_temps_lane.py:232); (2) the decision belongs to each engine's own linking
  mode, where the Cabs JSON carries no trace of it and both engines consume one translation unit. The measurement that
  showed it (Tier A on `0d4932940`, orchestrator-run, evidence `.tmp/release/stdio-fast-m1b-20261106T010525Z`, verbatim):
  `fast: failed; 15/20 selected commands completed successfully.`; A3 (coverage, nolibc) 41 rows `FAIL fmt-00N-…: unresolved
  symbol: __stdout at …/tests/coverage/fmt/fmt-001-f-default-precision.c:7:26-43`; A1's `check_macro_type_ranks: FAIL —
  dense_enumU_pos: …` (the dense programs print through printf); A15 `FAIL libc/034-stdio-puts-family: DIFF: oracle=… stdout:
  "p\ncf\nwx\n1 99 1 10 3 1\n" … lean=… stdout: "p\n1 99 1 10 3 1\ncf\nwx\n"` — an engine divergence, never baselined. The
  M1b claim that the define reached only libc-mode user TUs was true of the oracle's own invocations and false of the lanes'
  export path, which the worker had not measured [AGENT 2026-11-06, worker]. Measured consequence of the revision: the two
  M1b residuals (`(printf)(...)`, a call through `&printf`) disappear — every form of the identifier resolves to the
  library's `printf` (both engines `bc\n` = gcc); the per-call cost under the library path: 010-int32-printf 1249 → 1509,
  011-decimal-sweep 31540 → 83540 (0.32 → 0.46 s wall), lib_printf_int_formats 3491 → 4271 driver steps (a measurement,
  not a threshold); the header is byte-identical to pristine again and the quotation digests return to M1's values.
- [AGENT 2026-11-06, orchestrator] ruling on `vprintf`: defined in the shipped library as the standard's one line
  (`vfprintf(stdout, fmt, ap)`, 7.21.6.10) — a declared function the library left undefined is the same clear-standard class
  as the exit flush; witnessed, the dumps re-pinned, noted in the filing. `perror`/`strerror` stay the audit's K2 items.

## 1. The defect, as it stood (both engines; pristine `c3ff8c53f` agrees)

Three producers of the driver's `Step_done2 cval` (core_reduction.lem): the startup function's return (`step_ctx`, a value
in the arena with an empty stack and no parent thread: PROGRAM-DONE), every global initialiser of the globals phase (the same
shape, `driver_globals`), and the Core builtin `exit` (`process_impl_proc`'s `"exit"` arm, reached from the library's `_Exit`
through std.core's `exit_proxy`). All three landed in `process_core_step2`'s one arm, `prepare_exit`: keep the initial thread,
arena := the value, stack := empty, `driver2` returns, `finalize` reads the value. The library's `exit` (stdlib.c:223-227) ran
`__funcs_on_exit()` and `_Exit(code)` — musl calls `__stdio_exit()` between them; the copy flushed nothing. `__stdout_write`
(stdio.c:238-243) turns stdout fully buffered after its first write (musl's `lbf = -1` without the ioctl the model has no
device for), so after the first newline-terminated write nothing reached the record until an explicit `fflush`. And every
call of the identifier `printf` was the std.core proxy (`[ailname = "printf"]`, translation.lem
`translate_function_designator`), which writes straight into the driver's stdout record, past the FILE buffer: the library's
own `printf`/`vfprintf` (stdio.c:658, :708) were dead code in libc mode. Measured on the landed mainline (both engines
identical, pristine the same, gcc 13.3.0 `-std=c11 -w -O0` the referee), verbatim batch lines:

```text
tests/noodle-probes/lib/lib_stdio_unflushed_lost.c       Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}            gcc: out
tests/noodle-probes/lib/lib_stdio_exit_unflushed_lost.c  Defined {value: "Specified(0)", stdout: " 5\n", stderr: "", blocked: "false"}        gcc: out 5\n
tests/noodle-probes/lib/lib_stdio_puts_after_putchar.c   Defined {value: "Specified(0)", stdout: "\n", stderr: "", blocked: "false"}          gcc: \nxy\n
tests/noodle-probes/lib/lib_atexit_order.c               Defined {value: "Specified(4)", stdout: "m", stderr: "", blocked: "false"}           gcc: m21, $?=4
audit K2 k2_puts3.c                                      Defined {value: "Specified(0)", stdout: "a\n", stderr: "", blocked: "false"}         gcc: a\nb\nc\n
tests/libc_exec/041-atexit-return.c                      Defined {value: "Specified(7)", stdout: "main\n", stderr: "", blocked: "false"}      gcc: main\nbye\n, $?=7
tests/libc_exec/034-stdio-puts-family.c                  Defined {value: "Specified(14)", stdout: "p\n1 99 1 10 3 1\n", stderr: "err\n", blocked: "false"}   gcc: p\ncf\nwx\n1 99 1 10 3 1\n
```

The audit's stderr rows (`k2_stderr_*`) were a runner artefact (gcc captured `2>&1`; the engines' `stderr:` field carried the
text, stderr being unbuffered: `buf_size = 0`) — not findings. In `--nolibc` mode `atexit`/`exit` are unknown procedures and
`__stdout` is unresolved on all three engines (no library): that path is upstream's and is unchanged by this slice.

## 2. Design

### 2.1 The driver (`frontend/model/driver.lem`: `startup_exit_call_opt` :1347-1368, the `Step_done2` arm :1383-1425; both engines by generation)

`startup_exit_call_opt dr_st cval` is `Just (exit_sym, tid0, th_st, status)` exactly when the return must be routed:
(i) the linked Core file DEFINES `exit` — `Map.lookup (Identifier Loc.unknown "exit") file.extern` is `LK_normal exit_sym`
(the identifier map compares strings only, symbol.lem:4-25, on both targets; the Lean libc transport rebuilds `extern` from
the twelve metadata TUs and checks every resolved target against the dump, Main.lean:1136-1154) AND (M3b, the review's P2-1)
its funinfo type is the library's shape `void (signed int)`, not variadic, AND no routing has happened yet in this run
(`driver_state.exit_routed`); a `--nolibc` run only declares it (`LK_none`) unless the program defines `exit` itself with
external linkage (UB 7.1.3): the library's shape is then routed like the library's and, should it return — a `Step_done2`
of the initial thread with an empty stack after the routing —, the arm's `Nothing` branch is a loud ND kill (`Driver: the
C library's \`exit' returned to the startup thread … refused`), never a second routing, never a `Unit` verdict; another
shape is not routed (the mainline's answer); (ii) the initial thread (parent `Nothing`) has `Stack_empty` and `current_proc_opt = Just _` — the
startup function's return (`drive` installs `current_proc_opt = Just main_sym`; `CerbCall` the same shape for `--call`); the
globals phase has `current_proc_opt = Nothing` and the builtin `exit` fires inside the `_Exit` frame (stack non-empty) — that
one terminates the routed call; (iii) `memValueFromValue signed_int cval` is `Just` (a loaded integer; `void main` is UB004a at
desugar; a `--call` of a non-int function keeps the direct termination). Then, under `Normal_callconv`, a `signed int` object
is allocated and stored (`allocate_object tid0 (PrefOther "exit status") … signed_int`, `store` — the `prepare_main_args`
shape; the elaborated caller side of a C call does the same with `create`/`store` and then `kill`s the object after
the call, which the arm cannot since the call does not return), the arena becomes `Expr [] (Eproc empty_annotation (Sym exit_sym) [ptr])`; under
`Inner_arg_callconv` the loaded value is passed; `driver2` continues. The status object is never killed: `exit` is
`_Noreturn` — its `_Exit` reaches the Core builtin whose `Step_done2` takes the arm's `Nothing` branch (`prepare_exit`), so no
code runs after the call that could observe or free it [AGENT 2026-11-06, ruled]. Impossible shapes are `Nothing` (no
`error`: the failure-reach register keeps its 238 rows). Measured on `--call f` in libc mode: `fh\n`, `Specified(3)` (routed).

### 2.2 The library (`runtime/libc/src/stdlib.c` `exit`; `stdio.c` `vfprintf`, `vprintf`) and the proxy rule (main.ml, Main.lean)

- `exit`: `__funcs_on_exit(); fflush(NULL); _Exit(code);` (7.22.4.4#2-#4; `fflush(NULL)` is the shipped loop over
  `__stdout_used`, `__stderr_used` and `ofl_head`, stdio.c:513-522). `_Exit`, `quick_exit`, `abort` unchanged (7.22.4.5#2,
  7.22.4.7#3, 7.22.4.1#2: implementation-defined).
- `vfprintf`: `if (f->wpos != f->wbase) fflush(f);` before `__builtin_vprintf(fd, …)` (7.21.3: one stream, ordered writes;
  the builtin writes through the descriptor past the FILE buffer). Reached by `fprintf`, `vfprintf` and now `printf`.
- `vprintf`: `return vfprintf(stdout, fmt, ap);` (7.21.6.10) — declared by `<stdio.h>`, defined nowhere before (M2 ruling).
- The proxy rule (M1c, the revised ruling of §0): `backend/driver/main.ml` `prelude` removes `"printf"` from the std.core
  ailnames under `not nolibc`; `lean_frontend/Main.lean` mirrors it at its stdlib load under `--libc` for the program's TUs
  (`loadLibc`'s twelve library TUs keep the full map, as the oracle builds libc.co under `--nolibc`). The stdio paths in libc
  mode after it: `printf` → the library's `printf` (stdio.c:658) → `vfprintf` (flush) → builtin; `fprintf`/`vfprintf`/`vprintf`
  the same; `puts`/`putchar`/`fputs`/`fputc`/`putc`/`fwrite` the FILE buffer; `snprintf`/`sprintf` no stream; `write(1, …)` the
  descriptor proxy, past the buffer as on a real OS (`wbc\n` = gcc); `(printf)(…)` and a call through `&printf` resolve to the
  library too. Per-call cost of the library path (oracle, `-d2 --exec` driver steps, M1c): 010-int32-printf 1249 → 1509,
  011-decimal-sweep 31540 → 83540 (0.32 → 0.46 s wall), lib_printf_int_formats 3491 → 4271 — a measurement, not a threshold.

### 2.3 The generated delta, the proofs, the replay

Generated: `ocaml_frontend/generated/driver.ml` (89 changed lines, 3 hunks; an already-differing `[expected-semantic]` file,
hash `0dd83414…` → `a97b332d…`) and `lean_frontend/generated/Driver.lean` (129 lines, 3 hunks: the helper, the arm, the hack
doc comment) — nothing else, checked against the mainline primary checkout's generated trees. The `hack` hypothesis
(`scripts/fuel_hypotheses.txt`, `CerbCoreShape.lean`, the driver.lem declare comment) re-cited: `driver2`'s only exits are
still the two `prepare_exit` arms — the `Step_done2` arm's `Just` branch re-enters `driver2`, and the routed call ends in its
`Nothing` branch. One proof changed: `test/Unit/FuelExemplar.lean` `process_done`/`driver2_done` take `hexit :
startup_exit_call_opt eds tds dst v = none`, discharged by `rfl` on the exemplar file (`extern = fmapEmpty`). Kernel replay:
`lake env leanchecker Driver Driver_auxiliary Driver_lemMeasureProofs CerbCoreShape Unit.FuelExemplar` → `leanchecker exit=0`
(silent on success; the control `Unit.NoSuchModuleXYZ` → `uncaught exception: Could not find any oleans for: …`, exit 1);
`fuel-exemplar-test` exit 0; the axiom census's driver2 leg `check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom
declarations anywhere; entry cones ⊆ the standard three)`.

## 3. The vicinity

### 3.1 The matrix (the instrument `.tmp/stdio/matrix.sh` + `run.sh`, deleted at slice end)

33 termination probes (`puts` twice / three / in a loop, `fputs` with and without a newline, `fwrite` twice, `putchar` then
`puts` and many, `printf` without a trailing newline, `fputs` then `printf`/`fprintf`, `puts`/`printf`/`puts`, `fflush`
mid-way, `setvbuf` unbuffered/line/full, `stderr` (unbuffered, interleaved with stdout), `fopen` + `fwrite` unclosed, `atexit`
in `main` / in a callee / three in reverse / a handler that writes / a handler that calls `exit` / `exit` from a nested call,
`_Exit`, `abort`, `quick_exit` with `at_quick_exit`, `return 300`/`-1`/`256`, `main` without `return`, `exit` from `main` with
buffered output, two controls) and 12 stdio-path probes (`vprintf` through a user varargs wrapper, `(printf)(…)`, a call through
`&printf`, `write(1, …)`, `printf` then `puts`/`putchar`, `fputc`/`putc`/`fwrite` then `printf`, `snprintf` then `fputs`,
`perror` after `fputs(stderr)`, `fprintf(stderr)` ordering, `printf`/`fflush`/`puts`, `printf`'s return value), each on the
fork oracle, the Lean engine (libc mode: the pinned dump + the twelve metadata TUs, `--first`), pristine `c3ff8c53f` and gcc
13.3.0 (`-std=c11 -w -O0`, the streams captured separately); the whole set also under `--nolibc` on the three engines.

### 3.2 Results (derived from the matrix files; the M2 tree)

- Lean = oracle byte for byte on every libc-mode row; in nolibc mode 45/45 fork oracle = pristine and Lean = oracle up to
  symbol numbers (the `--nolibc` path is unchanged).
- Every termination, ordered-stream and atexit row = gcc on both engines (pristine the negative control on 32 of them).
- Not gcc's line by design, pinned to the fork's own: `_Exit`/`quick_exit`/`abort` after `puts("a"); fputs("b")` print `a\n`
  (the shipped library wrote the first newline-terminated line through before turning fully buffered; gcc with a pipe prints
  nothing: 7.22.4.5#2 / 7.22.4.7#3 / 7.22.4.1#2; on a TERMINAL glibc line-buffers stdout, so `_Exit`/`abort` print `a\n` =
  the fork's line and `quick_exit` prints `a\n` only — the handlers' `printf` appends `q2q1` to glibc's buffer, which `_Exit`
  drops, where the fork's library `printf` writes through: `a\nbq2q1` — by reasoning: the sandbox has no pty (`script:
  failed to create pseudo-terminal: Permission denied`), the operator can measure; the review's P3-5); `return 300`/`-1`/`256` report `Specified(300)`/`(-1)`/`(256)` (gcc's `$?`
  44/255/0, the host's truncation, derived); `abort` is `Specified(127)` with `SIGABRT\n` on stderr (the shipped `abort`:
  `raise(SIGABRT); _Exit(127)`; gcc 134).
- `fopen`: the oracle's in-memory filesystem opens the file (`Specified(0)`, the unclosed stream's data unobservable); the Lean
  engine REFUSES (`cerberus-lean stop ["1","REFUSAL","fs","open",…]`, contract D2) — a gap control, not an agreement.
- A handler that calls `exit` (UB, 7.22.4.4#3): `m321`, status 9 on both engines = gcc/glibc — the shipped library's (musl's)
  text (the nested `exit` continues with the remaining handlers, then `_Exit(9)`), declared as such, not a fork reading.

### 3.3 Findings

- `vprintf` declared by `<stdio.h>` but defined nowhere in the shipped library: `Error {msg: "ill-formed program: \`calling an
  unknown procedure: … SD_Id("vprintf")"}` on fork and pristine — FIXED in M2 (§2.2, ruled: the same clear-standard class as the
  exit flush), witnessed (`order_fputs_then_vprintf`).
- The proxy bypass for `printf` (tray 24 item 3): FIXED by the M1c rule (§0, §2.2); M1b's two residuals disappeared with it.
- `perror`/`strerror`: `Error {msg: "assert() failure"}` on fork and pristine — the audit's K2 rows, not this mechanism (ruled).
- No other sibling wrong on conforming input in the matrix.

### 3.4 The witness (`scripts/check_stdio_exit.sh`, row 1 via `test_unit.sh`; `tests/stdio_exit/`, 46 programs)

Every program carries its clause and gcc's line in its header. `expected.txt` pins ONE line per program that both engines'
`--batch` output must equal byte for byte with equal exit codes: 34 rows gcc 13's line (`gcc.txt`, derived 2026-11-06 with
OCaml `String.escaped` escaping), 6 rows the fork's declared line (`status_*`, `impl_*`; gcc's beside them in `gcc.txt`; a pin
that is neither gcc's line nor declared is a FAIL, so a silent re-pin cannot pass), the `gap_fopen_unclosed` control (the
oracle's line + the Lean D2 refusal text), five `nolibc_*` controls (both engines with `--nolibc`, the `Symbol(_, ` projection of
row 6b, equal exit codes: the two tray reproducers on upstream's path and — M3b, the review's P2-1 — the three programs that
define `exit` themselves: `void exit(int)` returning pins the loud kill's text, `void exit(void)` and `int exit(int)` pin the
mainline's `Specified(4)`, `m\n`). The total (46) and the class counts (34/6/1/5) are pinned (M3b, P3-3). `pristine.txt`
carries pristine's lines (33 rows differ: the negative control). Five plants on a 9-program subset,
counts derived in the script: `pristine-pair` 13, `lean-pristine` 7, `lean-fixed` 8, `oracle-rc` 15, `expect-tamper` 3 (the
plant stubs delegate every non-`--exec` invocation — `libc_prep.sh`'s `--pp=core`/`--cabs-json` honour the override — to the
real oracle). Cost, measured standalone on the M3b tree: 69 s for the run, ≈ 110 s with the self-test (the ≈ 4 min 20 s
of the first measurement was taken beside a concurrent CoreQuote build). Verbatim (the M3b run):

```text
check_stdio_exit: selftest plant 'pristine-pair' caught: 13 failing check(s) (= expected 13; incl. the required programs)
check_stdio_exit: selftest plant 'lean-pristine' caught: 7 failing check(s) (= expected 7; incl. the required programs)
check_stdio_exit: selftest plant 'lean-fixed' caught: 8 failing check(s) (= expected 8; incl. the required programs)
check_stdio_exit: selftest plant 'oracle-rc' caught: 15 failing check(s) (= expected 15; incl. the required programs)
check_stdio_exit: selftest plant 'expect-tamper' caught: 3 failing check(s) (= expected 3; incl. the required programs)
check_stdio_exit: OK (46 programs in libc mode: 34 batch lines of both engines = gcc 13's pinned line, exit codes equal — …; 6 pinned to the fork's declared lines with gcc's beside them in gcc.txt (the status beyond 0..255, _Exit/quick_exit/abort after buffered output); 1 gap control (fopen refused on the Lean engine, contract D2); 5 nolibc controls (the two tray reproducers on upstream's path; a program-defined exit of the library's shape routed and refused when it returns, two other shapes not routed; both engines); 33 rows moved from pristine c3ff8c53f's lines)
```

## 4. Moved rows and pins (gcc the referee)

### 4.1 The libc Core and the pins it carries

M1 (`exit` + `vfprintf`): `tests/libc/libc.core` `fae6ce64…` → `1b66d265…` (88739 → 88855 lines), `libc_inner_arg_temps.core`
`45eaac23…` → `c1034ee3…` (86435 → 86536); the only changed procedure bodies `exit` (+31 / +22 lines) and `vfprintf` (+85 /
+78), one line wrap in the inner_arg_temps `fopen`. M2 (`vprintf`): `1b66d265…` → `519d7c92…` (88855 → 88917), `c1034ee3…` →
`dcd0499f…` (86536 → 86585); `proc vprintf` added (+58 / +47), line wraps in `fflush`/`fopen`. Each time the two edited
TUs' SOURCE digests changed, so `merge_globs` (core_linking.lem, the min-(digest, number) order) reordered the globals and
every later symbol was renumbered (8450 raw hunks at M1): the libc-mode global LAYOUT moved — the mechanism behind every
address row of §4.3. The float-literal register: the 24 literals relocated (+11443 lines at M1, −20016 at M2), multiset and
order identical both times (`check_libc_float_literals: OK (24 … = the register exactly; 1 LOSSY-N3)`). CoreQuote libc
digests: `dc09e554…` → `a187580c…` → (M1b `be7ba1ee…`, withdrawn) → `0a845b19…`; inner_arg_temps `4c9f5e69…` → `d81b2620…` →
(`fc084e0a…`, withdrawn) → `addb1648…` (`test_unit.sh --core-quote-libc`: `Total: 2 passed, 0 failed`, every leanchecker leg
exit 0, at M1, M1c and M2). The header (`include/stdio.h`) is byte-identical to pristine.

### 4.2 The manifest

`scripts/fork_drift_manifest.txt`: `[files]` + `[source-content]` ENTER `runtime/libc/src/stdio.c` and `stdlib.c` (layer 1
lists every file differing from pristine; they were byte-identical before); `[source-content]` `driver.lem` `94859892…` →
`a21c5833…`, `backend/driver/main.ml` re-pinned (M1c), `stdio.c` re-pinned (M2); `[expected-semantic]` `driver.ml`
`0dd83414…` → `a97b332d…`; a dated NOTE (M1, M1c, M2 paragraphs); never `--refresh`. Gate: `check_fork_drift: OK — layer 1:
95 oracle-surface files = manifest (…); layer 2: 33 differing generated files, all hash-pinned (…)`, `SELFTEST OK (31
plants …)`, `check_pin_sites: OK`.

### 4.3 The table (both engines agree before and after on every row; pristine `c3ff8c53f` prints the before-lines)

| row | lanes | before | after | gcc 13 | disposition |
|---|---|---|---|---|---|
| `tests/libc_exec/034-stdio-puts-family.c` | A5 (class `MATCH` unchanged), A15 (hash `475549e7bc6e` → `a49e3bd549fc`, both engines), B10 (new difference) | `stdout: "p\n1 99 1 10 3 1\n"` | `"p\ncf\nwx\n1 99 1 10 3 1\n"` | the same, rc 14 | **the fix**: the buffered `c`, `f\n`, `wx\n` were lost at termination and the printf proxy wrote past them; register row with pristine's truncated stdout quoted; witnessed by `tests/stdio_exit/order_*` |
| `tests/libc_exec/041-atexit-return.c` | A5 (`MATCH`), A15 (`b5119a186908` → new), B10 (new difference) | `stdout: "main\n"` | `"main\nbye\n"` | the same, $?=7 | **the fix** (tray 25); its header rewritten (it had pinned the wrong behaviour as a mirrored upstream candidate); register row; witnessed by `atexit_on_return` |
| `tests/libc_exec/012-global-alloc-order.c` | A15 (`e767eda327c1` → new), B10 (new difference) | `s1=281474976707472 … optind=281474976707052\nloc=281474976705936` | `s1=281474976709344 … optind=281474976706068\nloc=281474976705940` | gcc rejects the program (`optind`) | **address layout**: the two edited libc TUs' source digests order the linked globals (merge_globs), so every libc-mode address moved; every non-address value identical; register row stating so |
| `tests/immaculate/libc/zd-z28-{addr-layout-b, pointer_from_integer_2g, provenance_equality_uintptr_t_global_yx, provenance_lost_escape_1}` | B5 (`MATCH \| L=VAL` pins the value: 4 DEVIATION rows), B10 (4 new differences) | e.g. `j=5 &j=(@70, 0xffffffffede8)`; `p=(@17, 0xfffffffff4cc)` | `j=5 &j=(@70, 0xffffffffedec)`; `p=(@14, 0xfffffffffc1c)` | gcc's own addresses | **address layout** (and the allocation ids, issued in the globals' order); the baseline hand-edited on the four rows with a dated note (the lane's recorder drops the file's curated comments — restored); four register rows |
| the nine `litmus/*` rows of A14.2 (`pointer_from_integer_2g`, `pointer_offset_from_int_subtraction_{auto,global}_xy`, `provenance_equality_{auto,global_fn,global,uintptr_t_auto,uintptr_t_global}_yx`, `provenance_lost_escape_1`) | A14.2 (oracle-side hash moved, e.g. `89d59452b533` → `b95613b0467e`) | `j=5 &j=(@70, 0xffffffffede8)`; `&x=281474976705976 &y=281474976705972 offset=18446744073709551612` | `j=5 &j=(@70, 0xffffffffedec)`; `&x=281474976705980 &y=281474976705976 offset=18446744073709551612` | gcc's own addresses | **address layout**, four bytes, every value identical (`j=5`, the offset, `(p==q)`); the lane's `--record-baseline` |
| `tests/cheri-ci/0332-rvalue-temporary-lifetime-pointer-zap.c` | ci sweep scoreboard (C4, `VAL` token = the value only: unchanged) | `(@72, 0xffffffffede4)` | `(@72, 0xffffffffedec)` | gcc's own address | **address layout** |
| `tests/tcc/17_enum.c` | ci sweep scoreboard (`UB_MATCH UB:UB153b…`, unchanged) | `Undefined {ub: "UB153b_illtyped_argument_for_format", … loc: "<63:4--63:24>"}` | `… loc: "<717:10--717:40>"` | gcc prints (`%d` of an enum) | **declared consequence of the proxy rule**: a printf-format UB is now raised inside the library's `vfprintf` (stdio.c:717, the builtin call), where the proxy raised it at the program's call — as `fprintf`'s always was; on the Lean engine the location inside the library is `<unknown location>` (N4), so such programs are a `LOC_ONLY` pair in libc mode (none in a gated libc-mode baseline today) |
| `tests/libc_exec/exhaustive/001-unseq-order-libc.c` | A5 (exhaustive: `PLANT … 80 verdicts`, `MATCH`) | the sweep's single-trace sample `3-1`/31 | `3-2`/32 | `3-2`, 32 (one of the two orders) | **not a moved row**: the two oracles' exhaustive sets are equal (80 verdicts, 40 `3-1` + 40 `3-2`); the default-mode sample picked the other trace (the ND order follows the renumbered symbols) |
| the uri lane's `LEAN_NOLIBC` row (`Symbol(968, SD_Id("memset"))` → `988` under M1b) | A10 | — | — | — | **not a moved row**: M1b's header macro (withdrawn in M1c); green on the M1c and M2 trees (`16/16`) |

### 4.4 The sweeps (the instrument `.tmp/stdio/sweep.sh`, deleted at slice end)

The oracle of the mainline primary checkout (`fc3961dc5`) against this tree's, batch lines compared byte for byte: libc mode
over every `.c` of the libc-mode corpora (`tests/libc_exec` + `exhaustive`, `immaculate/libc`, `pnvi_testsuite`, and the ci
sweep's libc suites `tcc`, `suite`, `examples`, `freebsd`, `hacl-star`, `cheri-ci`, the two `gcc-torture/breakdown` classes):
447 programs, 17 changed (§4.3, every one dispositioned); nolibc mode over the nolibc corpora (`minimal`, `coverage`, `debug`,
`float`, `bytes`, `immaculate/nolibc`, `macro_type_ranks`, `ci`, `pnvi_refusals`, `address_space`, `verify`,
`lean_frontend/corpus`): 787 programs, 0 changed — the `--nolibc` path is unchanged for every program that does not
define `exit` itself with external linkage (the reviewer's three such programs are pinned nolibc controls of the
witness, §3.4). The csmith corpus is a nolibc lane (`test_exec.sh`), unaffected.

### 4.5 The lanes run on the M2 tree (verbatim last lines)

```text
SUMMARY: match=42 loc_only=1 diff=0                                                                         (test_libc_exec.sh, A5; rc 0)
BASELINE OK (inner_arg_temps: 187 rows; classes and both distinct-observation/status hashes exact)           (test_inner_arg_temps.sh --gate, A15, after --record-baseline: exactly 012/034/041)
pnvi_lane: BASELINE OK (164 rows = the baseline, classes, oracle hashes and BOTH_FAIL/RESOURCE lean hashes exact)   (test_pnvi.sh, A14.2, after --record-baseline: exactly the nine litmus rows)
GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)                                   (test_libxml2_uri.sh, A10)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 … R7 … — VALIDATION.md 'ISO-fix register')   (test_immaculate.sh, B5, after the hand-edit of the four zd-z28 rows)
Independent oracle scope: tier-b; 1000 rows in 185.7s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 945, 'reviewed_difference': 23, 'matching_failure': 30, 'interface_agreement': 2}   (test_upstream_oracle.py, B10; the run before the seven rows: `failed; {… 'difference': 7 …}`, exactly the seven)
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}            (--plant)
Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK                                              (test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage, A3, on the M1c tree)
check_macro_type_ranks: OK (106 programs: 103 batch lines of both engines = gcc 13's pinned line, …)          (A1's row, on the M1c tree)
```

The libc_exec lane's baseline pins classes only (034 and 041 stay `MATCH`, both engines agreeing before and after); the
immaculate lane's recorder rewrites its file without the curated comment history (69 lines) — restored, the four rows
hand-edited from the lane's DEVIATION lines with a dated note, as that file's own precedents; the pristine lane's
register loader refuses an untracked citation, so the record joins the seven rows' citations at M3.

## 5. Register entries

- **Fork-drift manifest:** §4.2. **Pristine-difference register** (`scripts/upstream_oracle_differences.json`): seven
  `shared-model-fix` rows, 16 → 23 — `libc_exec/034-stdio-puts-family.c` and `libc_exec/041-atexit-return.c` (the fix;
  pristine's truncated stdout quoted verbatim), `libc_exec/012-global-alloc-order.c` and the four `immaculate/libc/zd-z28-*`
  rows (the address-layout shift, stated as such: not a wrong answer on either side; the register has no layout class, so
  the class is the fix's — [AGENT 2026-11-06], for the orchestrator's confirmation); signatures from the lane's own report
  (`report.json` rows: status, stdout_sha256, the diagnostic projection's sha).
- **Failure-reach register:** no new row (238 = 238; the driver's new helper has no pure failure site, the arm's impossible
  shapes are `Nothing`). **Fuel forms:** unchanged (88 workers); **fuel-parametricity pins:** unchanged (17); **fuel
  hypotheses:** the `hack` row's invariant text re-cited (§2.3), the hypothesis itself unchanged.
- **Pins:** §4.1. **Baselines:** `tests/inner_arg_temps/baseline.json` (012, 034, 041: the lane's `--record-baseline`, exactly
  those three rows), `tests/pnvi_lane/baseline.txt` (the nine litmus rows, `--record-baseline`, a dated header note),
  `tests/immaculate/baseline.txt` (the four zd-z28 rows hand-edited with a dated note: the lane's recorder rewrites the
  file without its curated comments), `tests/libc_exec/baseline.txt` and `dispositions.txt` unchanged (classes only; A5
  `match=42 loc_only=1 diff=0`), `tests/libxml2/uri_baseline.txt` unchanged (16/16 after M1c).
- `CONTRACT.md` (D15), `VALIDATION.md`, `SUPPORTED.md`, `scripts/LADDER.md` row 1, `TODO.md`, trays 24 and 25 (merged into
  one filing), the INDEX rows, the consumer notes for cerberus-caesium and cerberus-sl: M3.

## 6. Gates

### 6.1 M1 (`b5d2148ed`), M1b (`0d4932940`, withdrawn by M1c), M1c (`531506640`): the focused gates (verbatim, the M1c tree)

```text
check_fork_drift: OK — layer 1: 95 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 33 differing generated files, all hash-pinned (merge-base c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: …; unplanted gate green)
check_pin_sites: OK — lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_exec_purity: CLEAN (11 modules)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lakefile_roots: OK (228 roots = 228 generated modules + the exe root Main; 86 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
check_sorry_token: OK (353 files scanned comment-stripped — generated 229, hand-written+test 89, LemLib 35; 0 sorry tokens)
gen_fuel_parametricity: OK (17 ambient fuel wrappers in the generated tree = the 17 pins of TotalityProofTest.lean Part 1, both directions)
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=175 REACHABLE=42 UNKNOWN=21; every row sealed; tally line consistent)
check_fuel_forms: OK (88 fuel'd workers: 67 MEASURED (…; 13 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero …
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
libc_prep: OK (libc: pin + regenerated dump == 1b66d2657ba357afeae13f2c63e7d974ce88f1953e43bdc8e0874cce9ab57007, 4153942 bytes)   (M1/M1c; M2: 519d7c92…, 4156776 bytes)
check_libc_float_literals: OK (24 float literals in tests/libc/libc.core = the register exactly; 1 LOSSY-N3)
Ran 26 tests in 2.549s / OK                                  (test_stops.py --lean-bin …/stop-test)
Total: 2 passed, 0 failed                                    (test_unit.sh --core-quote-libc, every leanchecker leg exit 0)
leanchecker exit=0                                           (Driver Driver_auxiliary Driver_lemMeasureProofs CerbCoreShape Unit.FuelExemplar; control exit 1)
Build completed successfully (409 jobs). / (150 jobs) / (412 jobs)   (capped lake build CerberusLean cerberus-lean; speclab; + fuel-exemplar-test)
```

Tier A (orchestrator-run; evidence under `.tmp/release/stdio-fast-*`): on `0d4932940` (M1b, 01:05:25-01:40:28 UTC, start
load 0.61) `fast: failed; 15/20 selected commands completed successfully.` — A1, A3, A10, A14.2, A15 red: two findings
(§0, the revised ruling) and the moved rows; on `531506640` (M1c, 02:07:19-02:51:35 UTC, start load 3.21) `fast: failed;
18/20 selected commands completed successfully.` / `Source unchanged: True. Complete tier selection: True.` — only
A14.2 (`pnvi_lane: FAIL — 9 RED item(s)`) and A15 (the libc rows' hashes) red, the moved rows dispositioned in M2 (§4.3);
on `d4464bade` (M2, 03:52:16-04:13:14 UTC, start load 0.57; evidence `.tmp/release/stdio-fast-m2-20261106T035216Z`)
`fast: failed; 19/20 selected commands completed successfully.` / `Source unchanged: True. Complete tier selection:
True.` / `release rc=1` — only A1 red, on one check of `core-parser-test`: `✗ libc.core 191 procs: got 192` / `Done: 296
passed, 1 failed` / `✗ core-parser-test FAILED` (the parser test pins the libc dump's procedure census; `vprintf` makes it
192 — the pin moved to 192 in M3 with the reason, §6.2); every other row PASSED.

### 6.2 M2: the focused gates again (the 15 of §6.1, all exit 0 on the M2 tree), the witness (§3.4), the lanes (§4.5)

### 6.3 M3: the parser test's census pin (191 → 192: `vprintf`), the register class, the lanes re-run (verbatim)

```text
  ✓ libc.core 192 procs / ✓ libc.core 68 globs / ✓ libc.core 1 tagDef (fl) / Done: 297 passed, 0 failed   (core-parser-test, rebuilt; the pin 191 → 192 with the reason in test/Unit/CoreParserTest.lean)
libc_prep: OK (libc: pin + regenerated dump == 519d7c927cca883da2a004c101e064ffd52c352cb4d037d38ac589a29077f210, 4156776 bytes)
libc_prep: census OK (libc: 192 transported procs/funs; 6 shared bare names in 5 procs = the register; a speedbump on the printed spelling, not transport fidelity)
libc_prep: OK (libc_inner_arg_temps: pin + regenerated dump == dcd0499f5463ea0dd12a10ecb23a889ec9c366ab3133c0928c6d95329fb3481d, 4011125 bytes)
libc_prep: census OK (libc_inner_arg_temps: 192 transported procs/funs; 6 shared bare names in 5 procs = the register; …)
check_fork_drift: OK — layer 1: 95 oracle-surface files = manifest (…); layer 2: 33 differing generated files, all hash-pinned (…)
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; …)
Independent oracle scope: tier-b; 1000 rows in 197.6s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 945, 'reviewed_difference': 23, 'matching_failure': 30, 'interface_agreement': 2}   (test_upstream_oracle.py, the tree held; a first run during the record's edit reported `source unchanged: False` with the same counts and was repeated)
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 52}            (--plant: 51 → 52 with pristine-timeout-under-address-layout)
```

The register's loader gained the class `address-layout` (`CLASSES`; never timeout-admitting) and the plant
`pristine-timeout-under-address-layout` beside the existing `unknown-class` plant; the five layout rows re-classed with
the ruled rationale; the record cited on the seven rows once it existed as a tracked file.

### 6.4 M3b (the pre-merge review's fixes; `docs/2026-11-06_stdio-exit-flush-premerge-review.md` beside this record)

```text
leanchecker exit=0            (lake env leanchecker Driver Driver_auxiliary Driver_lemMeasureProofs CerbCoreShape Unit.FuelExemplar; the exemplar's `process_done` takes `hrouted : dst.exit_routed = false`)
fuel-exemplar-test exit=0
check_fork_drift: OK — layer 1: 95 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 33 differing generated files, all hash-pinned (…)   (+ SELFTEST OK; driver.lem and driver.ml re-pinned)
git apply --check -p1 <upstream.patch> in deps/cerberus-upstream (c3ff8c53f): OK   (7 hunks: driver.lem 4, stdlib.c 1, stdio.c 2 … main.ml 1; the fork-only comment hunk dropped)
check_stdio_exit: selftest plant 'pristine-pair' caught: 13 failing check(s) (= expected 13; incl. the required programs)   (and lean-pristine 7, lean-fixed 8, oracle-rc 15, expect-tamper 3)
check_stdio_exit: OK (46 programs in libc mode: 34 batch lines of both engines = gcc 13's pinned line, exit codes equal — …; 6 pinned to the fork's declared lines …; 1 gap control …; 5 nolibc controls (…); 33 rows moved from pristine c3ff8c53f's lines)
69.33 s wall (real run)                                       (the self-test with its final run: 1 min 50 s)
15 focused gates exit 0 (handwritten-sync 57, exec-purity, exec-totality, lakefile-roots, no-fuel-numerals, sorry-token 0, gen_fuel_parametricity 17 + selftest, check_failure_reach 238 + selftest, check_fuel_forms 88, check_theorem_axioms OK, libc_prep --check, check_libc_float_literals 24, test_stops 26 OK)
SUMMARY: match=42 loc_only=2 diff=0                           (test_libc_exec.sh, A5: 042 and the new 043 LOC_ONLY rows, each with its dispositions.txt line)
BASELINE OK (inner_arg_temps: 188 rows; classes and both distinct-observation/status hashes exact)   (test_inner_arg_temps.sh --gate after --record-baseline: exactly the one new row, libc/043 LOC_ONLY-FIRST with the lane's disposition)
```

The reviewer's three programs under `--nolibc` on both engines (the mainline `fc3961dc5` beside): `void exit(int)` returning →
`Error {msg: "Driver: the C library's \`exit' returned to the startup thread (a program-defined \`exit' with external linkage,
UB C17 7.1.3; \`exit' does not return, 7.22.4.4): refused"}`, rc 1 on both (the mainline `Specified(4)`, `m\n`); `void exit(void)`
and `int exit(int)` → `Defined {value: "Specified(4)", stdout: "m\n", …}` on both = the mainline (not routed: the funinfo shape
test). The five tray reproducers and `034` identical on both engines in libc, inner_arg_temps and nolibc modes on the M3b
build.

### 6.5 M3c (the full battery's two reds on `6992d69d8`: harness and register items)

The full battery (orchestrator-run, evidence `.tmp/release/stdio-full-m3b-20261106T051029Z`, 05:10:29-07:40:14 UTC, start
load 4.06): `full: failed; 43/45 selected commands completed successfully.` / `Source unchanged: True. Complete tier
selection: True.` / `Release certification: incomplete: reporting/adoption/audit exits require separate evidence.` /
`release rc=1` — A1 (1053.6 s) and B10.1 (193.8 s) red, every other row PASSED (B7 1493.2 s, B9 2460.0 s, B13 839.2 s).

- A1: row 1's executables `Total: 21 passed, 0 failed` and every other gate green, then `check_stdio_exit: SELFTEST FAIL —
  plant 'oracle-rc' caught 23 failing check(s), expected exactly 15`, the eight extra being Lean refusals `cerberus-lean
  stop ["1","REFUSAL","library-location","the libc metadata TU …/libcjson/…`. Cause: `test_unit.sh` runs its gates from
  `lean_frontend/` (`cd "$PROJECT_ROOT/lean_frontend"`, :89); `libc_prep.sh --jsons` exports the metadata TUs under the
  canonical RELATIVE runtime `_build/install/default` and the Lean driver resolves such labels with `realPath` from ITS
  cwd (BUG-3's rule), so from `lean_frontend/` every metadata TU resolves outside the run's runtime directories; the
  first three plants stub the Lean side and pass, `oracle-rc` is the first with a real Lean run. Reproduced: the self-test
  from `lean_frontend/` fails the same way; standalone from the root it passed (§6.4). Fix: the witness `cd`s to the
  project root before anything (and re-invokes its plants by absolute path), so the convention holds whatever the
  caller's cwd. Verified from `lean_frontend/` and from the root under the battery-like environment (`CERB_OBSERVATION_DIR`
  under the container's `.tmp`, `CERB_INSTALL_PREFIX` as common.sh exports it, `scripts/ce`):

  ```text
  === from lean_frontend/ (the battery's cwd)
  check_stdio_exit: selftest plant 'pristine-pair' caught: 13 failing check(s) (= expected 13; incl. the required programs)
  check_stdio_exit: selftest plant 'lean-pristine' caught: 7 failing check(s) (= expected 7; incl. the required programs)
  check_stdio_exit: selftest plant 'lean-fixed' caught: 8 failing check(s) (= expected 8; incl. the required programs)
  check_stdio_exit: selftest plant 'oracle-rc' caught: 15 failing check(s) (= expected 15; incl. the required programs)
  check_stdio_exit: selftest plant 'expect-tamper' caught: 3 failing check(s) (= expected 3; incl. the required programs)
  check_stdio_exit: OK (46 programs in libc mode: 34 batch lines of both engines = gcc 13's pinned line, exit codes equal — …)
  === from the root: the same six lines (1 min 52 s and 1 min 51 s)
  ```
- B10.1: `Independent oracle: failed; {'semantic_agreement': 945, 'reviewed_difference': 23, 'matching_failure': 30,
  'difference': 1, 'interface_agreement': 2}` — the one unreviewed difference is `libc_exec/043-printf-format-ub-loc.c`
  (added at M3b without its register row). Registered as `diagnostic-text` (the verdict and the UB id identical on both
  sides; only the location field differs — pristine's `<10:40--10:59>`, the program's printf call, the fork's
  `<717:10--717:40>`, the library's `vfprintf`), signatures from the lane's own `--only` run, the record and the review
  cited. Verbatim (the tree held; a first run during the record's own edit reported `source unchanged: False` with the
  same counts and was repeated):

  ```text
  Independent oracle scope: tier-b; 1001 rows in 190.9s; source unchanged: True
  Independent oracle: passed; {'semantic_agreement': 945, 'reviewed_difference': 24, 'matching_failure': 30, 'interface_agreement': 2}
  Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 52}
  ```

The semantics battery stands on `6992d69d8`: M3c moves no Lem, library or Lean source (the witness script, the register
and documentation only); the orchestrator re-runs exactly A1 and B10.1 on the M3c tip.

## 7. Not done / open

- The pristine-lane register has no "layout" class: the five address rows are registered as `shared-model-fix` with the
  mechanism stated; a class for layout consequences of a shared-model change is a lane-schema question [AGENT 2026-11-06].
- A printf-format UB in libc mode is located inside the library's `vfprintf` on the oracle and `<unknown location>` on the
  Lean engine (N4): a `LOC_ONLY` pair for such programs (none gated today); the Core-text transport's location item
  (TODO) is the remover, as for N4.
- `perror`/`strerror` assert (the audit's K2 rows); `fopen` refused (D2); the libc-mode buffering of stdout after the first
  write is musl's shape without the device test (7.21.3#7) — upstream's library, kept.

## 9. Pre-merge review (2026-11-06, fresh independent reviewer; `docs/2026-11-06_stdio-exit-flush-premerge-review.md`) — dispositions [AGENT 2026-11-06, orchestrator rulings applied by the worker]

| finding | disposition |
|---|---|
| P2-1 — `--nolibc` not "untouched by construction": a TU defining `exit` itself is routed; a returning `exit` re-routed forever (`int exit(int)`), a `Unit` verdict (`void exit(int)`), a wrong-arity error | **FIXED in the Lem** (both engines by generation): `driver_state.exit_routed` (routing once per run), the funinfo shape test (`void (signed int)`, not variadic), a returned routed `exit` is the loud ND kill `Driver: the C library's \`exit' returned to the startup thread … refused` (never a second routing, never a verdict); every "by construction"/"untouched" sentence reworded (driver.lem, CONTRACT D15, VALIDATION, SUPPORTED, TODO, the record, the filing, both consumer notes, the witness header); the reviewer's three programs are pinned nolibc controls (`nolibc_user_exit_returns` the kill's text, `nolibc_user_exit_noarg`/`nolibc_user_int_exit` the mainline's answers); the exemplar proof takes `hrouted`; replayed (§6.4) |
| P2-2 — the filing's patch failed `git apply --check` on pristine (the fork-only comment hunk; the fork's line numbers) | **FIXED**: the four files' hunks replayed onto pristine's text, the comment hunk dropped, `git apply --check -p1`: OK (quoted in the filing and §6.4); "Affected" cites upstream's `:1326` / `:1304` |
| P3-1 — the printf-format UB location consequence unwitnessed in a gate | **FIXED**: `tests/libc_exec/043-printf-format-ub-loc.c` pinned `LOC_ONLY` (A5) with a dated `dispositions.txt` line (pristine's `<10:40--10:59>` quoted), `LOC_ONLY-FIRST` in A15 with the lane's disposition |
| P3-2 — stale `to_pure`/`to_pures` cites in `fuel_hypotheses.txt` | **FIXED**: re-cited (text only) |
| P3-3 — the witness pins no total | **FIXED**: the total (46) and the four class counts (34/6/1/5) are pinned; a dropped row fails |
| P3-4 — withdrawn-M1b wording in two headers; the `quick_exit` header's "nothing is flushed" | **FIXED**: the three headers reworded (the `b` is the fork's write-through printf, not a flush at termination) |
| P3-5 — gcc on a terminal not stated | **ANSWERED**: unmeasurable in the sandbox (no pty: `script: failed to create pseudo-terminal: Permission denied`); by reasoning — glibc line-buffers a tty — `_Exit`/`abort` print `a\n` (= the fork's line) and `quick_exit` `a\n` only (the fork's `a\nbq2q1` is its write-through printf); stated in §3.2 and the `impl_*` headers as reasoned, the operator can measure outside the sandbox |
| P3-6 — "a few bytes" | **FIXED** in both consumer notes: program globals by up to ~1.9 KB (`012`'s `s1` 281474976707472 → 281474976709344), locals by four bytes |
| P3-7 — the record's "exactly the elaborated caller side" | **FIXED**: the arm allocates with the `prepare_main_args` shape and cannot `kill` the object, aligned with the driver comment |
| P3-8 — row-1 cost ≈ 4 min 20 s with the plants | **ANSWERED with the measured cost**: standalone on the M3b tree the run is 69 s and the self-test (five plants on a 9-program subset, the rank script's shape) ≈ 41 s more, ≈ 110 s in all — the first figure was measured beside a concurrent CoreQuote build; the subset is already the minimum that exercises every plant's required programs (three moved rows, two unmoved, the gap and a nolibc control), and the per-program cost is libc mode's (the library load on the Lean engine, `libc_prep --jsons` per invocation), so a further trim would drop required programs; VALIDATION/LADDER state the measured numbers |

## 8. Scratch, deleted at close-out

`.tmp/stdio/` — `run.sh`, `matrix.sh`, `sweep.sh`, `gen_expected.py`, the probe sets, `out/`, `sweep/`, `lanes/`, the logs.
