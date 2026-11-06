# Pre-merge review: fix/stdio-exit-flush (455693ec9, six commits over fc3961dc5)

Reviewer: independent agent, [AGENT 2026-11-06, reviewer]. Budget ~1 h. Scope: the six commits, the diff
`fc3961dc5..455693ec9` (driver.lem, stdlib.c, stdio.c, main.ml, Main.lean, CerbCoreShape.lean, FuelExemplar.lean,
fuel_hypotheses.txt, the witness script and corpus, the manifest, the pins, the baselines, the register, CONTRACT D15,
VALIDATION, SUPPORTED, TODO, LADDER, the record, the charter, the merged filing 24 + pointer 25, the INDEX, both
consumer notes), the generated `Driver.lean` helper, and the supporting Lem (`core_reduction.lem` Step_done2 producers
and the PCALL/RETURN arms, `core_linking.lem` `merge_globs`/`topo_order`, `translation.lem`
`translate_function_designator`, `core_aux.lem` `memValueFromValue`, `std.core` proxies). No tracked file edited, no
build, no lane script, no git state change (one `git apply --check` in the pristine checkout: read-only).

## What I ran (verbatim shapes; outputs under `.tmp/review-stdio/out/<probe>/`)

Scratch: `/home/dev/projects/cerberus-lean-proj/.tmp/review-stdio/` — `probes/*.c` (33 programs), `run.sh`, `out/`.
Engines: FO = this tree's oracle, MB = the mainline primary checkout's oracle (`cerberus-lean/` at `fc3961dc5`, the
"before"), PR = pristine `deps/cerberus-upstream` (`c3ff8c53f`), LE = this tree's Lean driver, GP = gcc 13.3.0 with
stdout to a pipe.

```
SKIP_BUILD=1 /home/dev/projects/cerberus-lean-proj/scripts/ce scripts/libc_prep.sh --jsons .tmp/review-stdio/libcjson   # the 12 metadata TUs (rc 0)
scripts/ce <ROOT>/_build/default/backend/driver/main.exe --runtime=<ROOT>/_build/install/default [--nolibc] --exec --batch <probe.c>     # FO / MB / PR
scripts/ce <W>/_build/default/backend/driver/main.exe --runtime=<W>/_build/install/default [--nolibc] --cabs-json <probe.c> > tu.json
cd <W> && LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/cerberus-lean --batch --first --runtime=_build/install/default \
    [--libc tests/libc/libc.core --libc-tu <12 jsons>] [--switches PNVI_ae_udi] [--call f] tu.json                       # LE
gcc -std=c11 -w -O0 <probe.c> -o a.out && ./a.out > gp.out 2> gp.err                                                     # GP
script -qec "./a.out" /dev/null        # pty: FAILS in the sandbox ("script: failed to create pseudo-terminal: Permission denied")
cd deps/cerberus-upstream && git apply --check <filing patch, whole and per file>                                        # read-only
sha256sum frontend/model/driver.lem backend/driver/main.ml runtime/libc/src/stdio.c runtime/libc/src/stdlib.c           # vs the manifest rows
```

### Probe results (libc mode unless marked; FO = LE byte for byte on every row)

| probe | FO = LE (this tree) | MB = PR (before / pristine) | gcc (pipe) |
|---|---|---|---|
| t01 `fputs("out"); return 0` | `Specified(0)`, `out` | `""` | `out`, 0 |
| t02 `atexit(h); fputs("end");` falling off `}` | `endh\n` | `""` | `endh\n`, 0 |
| t03 `atexit(h); fputs("x"); exit(2)` | `Specified(2)`, `xH` | `""` | `xH`, 2 |
| t04 `exit(3)` from a nested call, handler | `gh\n` | `gh\n` | `gh\n`, 3 |
| t05 `puts("a"); fputs("b"); _Exit(5)` | `Specified(5)`, `a\n` | `a\n` | `""`, 5 |
| t06 `… abort()` | `Specified(127)`, `a\n`, stderr `SIGABRT\n` | same | `""`, 134 |
| t07 `at_quick_exit` ×2, `quick_exit(6)` | `a\nbq2q1` | `a\nq2q1` | `""`, 6 |
| t08 handlers in main + callee, three, writers printf/fputs/putchar, `return 7` | `Specified(7)`, `m321` | `""` | `m321`, 7 |
| t09 handler calls `exit(9)` (UB 7.22.4.4#3) | `Specified(9)`, `m321` | `Specified(4)`, `m` | `m321`, 9 |
| t10 `return -1` | `Specified(-1)`, `r` | `""` | `r`, 255 |
| t11 status from a global (`static int g = 7`) | `Specified(7)`, `g` | `""` | `g`, 7 |
| t12 `int x; return x;` | `Unspecified('signed int')`, `u` | `Unspecified…`, `""` | `u`, 252 |
| t13 `return f()`; Lean `--call f` | `Specified(3)`, `fh\n`; `--call f` the same | `""` | `fh\n`, 3 |
| t15 recursive `main` (inner return not routed) | `Specified(2)`, `rr` | `""` | `rr`, 2 |
| t17 user-defined `printf` | link error `duplicate external symbol: printf` (all four engines) | same | `x` |
| t18 user prototype of `printf`, no `<stdio.h>` | `x\n` | `x\n` | `x\n` |
| t20 `printf("%d\n", 1.5)` after `fputs("a")` | `UB153b` at `<717:10--717:40>` (FO) / `<unknown location>` (LE) | `UB153b` at `<2:40--2:59>` | garbage (UB) |
| t21 `printf` undeclared | desugaring failed (constraint violation), all engines | same | — |
| t22 `int g = puts("init")` | desugaring failed, all engines; gcc rejects | same | — |
| t28 stdout/stderr interleave | `o1o2o3\n` / `e1e2\n` | `o2o1o3\n` / `e1e2\n` | `o1o2o3\n` / `e1e2\n` |
| t29 `setvbuf(_IOLBF)`, `fflush` mid-way, printf | `abc\nd` | `abc\n` | `abc\nd` |
| t31 `int (*p)(…) = printf; p(…)` | `bc1\n` | `c1\n` | `bc1\n` |
| t32 `atexit; puts; puts; return 5` (+ `--switches PNVI_ae_udi` both engines) | `a\nb\nh\n` | `a\n` | `a\nb\nh\n`, 5 |
| t33 `fopen` unclosed + `fputs("o", stdout)` | FO `o`; LE D2 refusal rc 134 | `""` | `o` |
| t34 `vprintf` via a varargs wrapper, return value | `bc1\n3\n` | `calling an unknown procedure … vprintf` | `bc1\n3\n` |
| nolibc t25 `exit(3)` | unknown procedure `exit` (all) | same | — |
| nolibc t26 arithmetic + two printf, `return 10` (exported with and without `--nolibc`) | `s=10\nx\n`, `Specified(10)` | same | same |
| nolibc t27 `return 300` | `Specified(300)` | same | 44 |
| nolibc t01/t02/t09 | `unresolved symbol: __stdout` / unknown procedure `atexit` (all) | same | — |
| nolibc t23s `static void exit(int)` (internal linkage) | `Specified(4)`, `m\n` | same | `m\n`, 4 |
| **nolibc t23 `void exit(int)` with external linkage (UB 7.1.3)** | **`Defined {value: "Unit", stdout: "m\nmyexit 4\n"}`** | `Specified(4)`, `m\n` | `m\n`, 4 |
| **nolibc t24 `void exit(void)` (UB 7.1.3)** | **`Error … calling procedure exit with the wrong number of args`** | `Specified(4)`, `m\n` | `m\n`, 4 |
| **nolibc t36 `int exit(int)` returning its argument (UB 7.1.3)** | **NON-TERMINATION: oracle `timeout 20` rc 124, Lean `timeout 60` rc 124** | `Specified(4)`, `m\n` | — |

Derived tally: 28 libc-mode probes, every one FO = LE; every conforming row = gcc's pipe line except the declared
implementation-defined ones (t05/t06/t07 after buffered output, t10/t27 status outside 0..255) and the UB t20 (format
mismatch). Pristine and the mainline "before" agree with each other everywhere (the negative control holds).

## Findings

### P1 — none.

### P2-1  `--nolibc` is not untouched "by construction": a TU that defines `exit` itself is routed, and the routed call can return or loop

- Claim: driver.lem:1333-1335 (helper comment: "a `--nolibc` run only declares it, `LK_none`, and keeps upstream's direct
  termination"), CONTRACT.md:375 ("every `--nolibc` run keep[s] upstream's direct termination, by construction and by
  measurement"), the record §2.1 and §4.4:241 ("unchanged by construction"), VALIDATION §3(c) bullet, the filing :93
  ("`--nolibc` is untouched"), both consumer notes, `check_stdio_exit.sh` header.
- Evidence: the predicate in `startup_exit_call_opt` (driver.lem:1348-1368) is "the linked Core file's extern map has
  `exit` as `LK_normal`", which a `--nolibc` TU satisfies by defining `exit` with external linkage. Three probes above:
  t23 → both engines answer `Defined {value: "Unit", …}` (the final value of a C program is `Unit`: the user's `exit`
  returns, the startup thread's arena is `Vunit`, `memValueFromValue` refuses it, `prepare_exit` takes `Vunit`); t24 →
  an ill-formed-program error (wrong arity) where the mainline terminated normally; t36 → non-termination on BOTH
  engines (the returned `Specified(4)` is routed again, forever; the "never killed" status object is allocated each
  round). Mainline `fc3961dc5` and pristine answer `Specified(4)`, `m\n` on all three. A `static` definition
  (internal linkage, t23s) is not in the extern map and is unaffected, so conforming programs are not reachable
  (defining `exit` with external linkage is UB, 7.1.3); the 787-program nolibc sweep is right, the "by construction"
  wording is not, and a hang on any input is a crash-class regression the fork's own rule treats as a defect to
  refuse loudly, not a note.
- Fix (small, in the Lem, both engines by generation): (a) tighten the predicate — look the `exit` target up in
  `core_file.funinfo` (`map sym (loc * attrs * ret_ctype * list (maybe sym * ctype) * bool * bool)`, driver.lem:431)
  and route only a `void` function with exactly one `signed int` parameter; (b) make a returned `exit` LOUD: a startup
  thread `Step_done2` after routing (simplest: a `Vunit` value from a thread with `current_proc_opt = Just _` and an
  empty stack while `exit` is defined — `void main` is UB004a-rejected so no conforming program produces that shape;
  or a boolean field in `driver_state` set at routing) is an ND kill `DErr_other "the C library's exit returned"`,
  never a re-route and never a `Unit` verdict; (c) reword every "by construction"/"untouched" site to "unchanged for
  every program that does not itself define `exit` with external linkage (UB 7.1.3), which is refused"; (d) add t23/t24/t36
  as `nolibc_*` controls in `tests/stdio_exit/` pinned to the refusal (fuel-bounded on Lean), so the class is gated.

### P2-2  The merged filing's patch does not apply to upstream `c3ff8c53f`

- Claim: `docs/upstream-tray/24-stdio-buffer-not-flushed-at-exit.md` ("The patch below is against `rems-project/cerberus`
  at `c3ff8c53f`; upstream's tip carries the same text in every cited region"; INDEX "the report carries the patch").
- Evidence: `cd deps/cerberus-upstream && git apply --check <the fenced diff>` → `error: patch failed:
  frontend/model/driver.lem:1921 / error: frontend/model/driver.lem: patch does not apply`. Per file: main.ml, stdio.c,
  stdlib.c and driver.lem hunks 1-2 APPLY; the third driver.lem hunk (`@@ -1921,10 +2002,14 @@`, the fork-only `hack`
  fuel-measure comment, `declare {lean} fuel val hack`) has no counterpart upstream. The blob ids in the headers
  (`index e226d0d5b..7b6822fed`, `1754247dd..28af395e9`) are the fork's, not upstream's. The "Affected" cites give the
  fork's pre-fix line numbers (`Step_done2` arm `:1336-1343`, `prepare_exit :1314-1322`) where upstream's are `:1326`
  and `:1304` (checked with `grep -n` in the pristine checkout); the stdlib.c/stdio.c/stdio.h cites (`:223-227`,
  `:238`, `:658`, `:708`, `include/stdio.h:84`) are right.
- Fix: regenerate the patch from the pristine tree (apply the four changes there, drop the hack-comment hunk, which is
  fork-only), run `git apply --check` in `deps/cerberus-upstream` and quote the result in the record; cite upstream's
  line numbers in "Affected".

### P3-1  The declared location consequence is acceptable but unwitnessed in a gate

- Claim: record §4.3 (`tcc/17_enum`), §7, CONTRACT D15, VALIDATION N4, SUPPORTED, TODO: a libc-mode printf-format UB is
  now raised inside the library's `vfprintf` (`stdio.c:717`) on the oracle and at `<unknown location>` on Lean.
- Evidence: t20 above — MB/PR `<2:40--2:59>` (the program's call), FO `<717:10--717:40>`, LE `<unknown location>`;
  verdict and UB id identical on all four. Judgement [AGENT 2026-11-06, reviewer]: not blocking — no wrong answer, the
  class (N4) and the remover are declared in five places, and `fprintf`'s location always was the library's; but it
  is a diagnostic regression on BOTH engines for every libc-mode `printf` format UB, and "none in a gated libc-mode
  baseline today" means the declared pair is a note, not a gate.
- Fix: add `tests/libc_exec/043-printf-format-ub-loc.c` (t20's shape) pinned `LOC_ONLY` in A5 (the class exists:
  042 is one), so a change on either side shows; keep the transport's location item as the remover.

### P3-2  Stale cites in `scripts/fuel_hypotheses.txt:82`

- The `to_pure_lemFuel` / `to_pures_lemFuel` rows still cite `finalize (driver.lem:1478-1482)` and `driver_globals
  (driver.lem:1618-1623)`; the `hack` row (and CerbCoreShape.lean) were re-cited to `:1559-1563` / `:1699-1704` in M1.
  Fix: re-cite the two rows (text only; the hypotheses are unchanged).

### P3-3  The witness pins no total: a dropped row passes silently

- `scripts/check_stdio_exit.sh:174-233`: `n`, `ngcc`, `nfork`, `nmoved` are derived from `expected.txt`; only the six
  `FORK_PINNED` names are required to exist; the OK line hard-codes "1 gap control" and "2 nolibc controls". Deleting
  any gcc-pinned row (or a control) from `expected.txt` still prints OK. Fix: assert `n == 43` with the four class
  counts (34/6/1/2) and fail otherwise (one line; the plants already cover the other directions).

### P3-4  Corpus headers carry withdrawn-M1b wording and one inaccurate claim

- `tests/stdio_exit/order_printf_return_value.c` ("printf through the macro keeps its return value") and
  `order_fputs_then_printf.c` ("M1b, the libc-mode printf macro") describe the withdrawn header macro;
  `impl_quick_exit_after_buffered.c` says "nothing is flushed" while its pinned line `a\nbq2q1` contains the `b` that
  the handler's `printf` pushed out (vfprintf's flush of the pending buffer) — say so, it is the fork's write-through
  printf, not a flush at termination.

### P3-5  gcc on a terminal is not stated

- Record §3.2, D15 and the `impl_*` headers state gcc's PIPE line only ("gcc with a pipe prints nothing"). On a tty
  glibc line-buffers stdout, so `_Exit`/`abort` after `puts("a"); fputs("b")` print `a\n` (= the fork's line) and
  `quick_exit` prints `a\n` (not the fork's `a\nbq2q1`). I could not measure it: the sandbox has no pty (`script:
  failed to create pseudo-terminal: Permission denied`). Fix: the user measures the three programs outside the sandbox
  with stdout on a terminal and the record states both of gcc's lines beside the fork's.

### P3-6  Consumer-note wording: "shifted by a few bytes"

- Both consumer notes: "every address a libc-mode program prints … shifted by a few bytes". The register rows show
  program globals moving by 1872 bytes (`012-global-alloc-order`: `s1=…707472` → `…709344`) and locals by four. Say
  "every libc-mode address moved (globals by up to ~2 KB, locals by four bytes), values identical".

### P3-7  Minor wording in the record §2.1

- "exactly the elaborated caller side of `_Exit` … `create(Ivalignof('signed int'), 'signed int'); store(…)`": the arm
  uses `Mem.allocate_object` with `PrefOther "exit status"` (the `prepare_main_args` shape) and, unlike an elaborated
  caller, cannot `kill` the object (fine while `exit` never returns; it leaks in the P2-1 case). The driver comment
  itself is accurate; align the record with it.

### P3-8  Row-1 cost

- The witness with its five plants adds ≈ 4 min 20 s to every `test_unit.sh` run (record §3.4; `test_unit.sh:596`
  runs `--selftest` unconditionally). Consider running the plants at claim points only (the practice treats a long
  check run as a smell); optional.

## Checks that passed (so they are not findings)

- The driver arm is the standard's equivalence on every conforming shape I probed: return with buffered output,
  falling off `}` (= `return 0`), `exit` from `main` and from a nested call, `_Exit`/`abort`/`quick_exit` unrouted,
  handlers registered in `main` and in a callee, three in reverse, writers of every kind, a handler calling `exit`
  (musl's text = glibc), statuses 0/7/-1/300/256, a status read from a global, an indeterminate status (unchanged
  shape), a recursive `main` (only the initial return is routed), `--call` of an int function in libc mode (routed,
  = the oracle's wrapper `main`), PNVI switch, stdout/stderr interleaving, `setvbuf`/`fflush` mid-way, `(printf)`,
  `&printf`, a user prototype of `printf`, `vprintf` with its return value.
- The thread-state test: the only value-arena producer of `Step_done2` is `step_ctx`'s `Stack_empty` + parent-`Nothing`
  arm (core_reduction.lem:1142-1152); the builtin `exit` (:1029-1035) is reached only through `exit_proxy` → PCALL
  frames (:1434-1437), so its stack is non-empty; the globals phase has `current_proc_opt = Nothing` (driver.lem:1664,
  :1692) and RETURN restores the parent's (`:1178`); `drive` installs `Just main_sym` (:1971), `CerbCall` the same
  (:291). `exit` from a global initialiser is a constraint violation (t22 rejected on all engines).
- `--nolibc` conforming programs: fork = mainline = pristine, Lean = oracle, on the eight nolibc probes; the Cabs JSON
  is mode-independent (t26 exported with and without `--nolibc` gives the same Lean line).
- The mirrored prelude rule: main.ml:166-171 `Pmap.remove "printf"` under `not nolibc` after the impl load; Main.lean
  :1318-1320 `fmapDeleteBy defaultCompare "printf"` under `libc.isSome`, applied to the program's TUs only
  (`frontendTU … userAilnames`, :1391) while `loadLibc` keeps `ailnames` (:1365) as the oracle builds libc.co under
  `--nolibc`; `translate_function_designator` (translation.lem:243-251) substitutes by the identifier's string, so
  every form of the identifier (`(printf)`, `&printf`, a pointer initialised from `printf`) resolves alike (probed).
- The libc changes are minimal: `exit` = handlers, `fflush(NULL)` (the shipped walk over stdout, stderr, `ofl_head`,
  stdio.c:513-522), `_Exit`; `vfprintf`'s flush is the one adaptation the builtin write-through needs (musl's own
  vfprintf writes through the FILE buffer, so musl needs none); `vprintf` is the standard's one line. 7.22.4.4#4's
  "all open streams are closed" is not mirrored — unobservable here (fopen refused on Lean, in-memory on the oracle).
- The address-layout mechanism is as described: `merge_globs` orders by `topo_order` over `Set_extra.choose` of symbol
  sets (core_linking.lem:243-251), i.e. (digest, number); editing the two TUs changed their digests. Values identical
  on every moved row (register rationales quote both sides); the new `address-layout` class is justified (both engines
  right) and never timeout-admitting, with a plant.
- The manifest's four `[source-content]` rows equal `sha256sum` of the files in the tree; `[files]` gained stdio.c and
  stdlib.c; no `--refresh`.
- `FuelExemplar.lean` `process_done`/`driver2_done` take `hexit : startup_exit_call_opt eds tds dst v = none` (true on
  the exemplar file, `extern = fmapEmpty`, by `rfl`); the hypothesis text in CerbCoreShape.lean / fuel_hypotheses.txt
  `hack` row states the same fact as the driver (the `Just` branch re-enters `driver2`; the routed call ends in the
  builtin's `Step_done2` with a non-empty stack, the `Nothing` branch) — with the P2-1 caveat that a user `exit` that
  returns also ends in the `Nothing` branch (Vunit) or never ends (int): the invariant "the arena is a value at
  `finalize`" still holds whenever `driver2` returns. The line cites `:1390-1394`, `:1395-1424`, `:1436-1441`,
  `:1559-1563`, `:1699-1704`, `:1455` are exact. Kernel replay is quoted in the record (§2.3, §6.1: `leanchecker exit=0`
  over `Driver Driver_auxiliary Driver_lemMeasureProofs CerbCoreShape Unit.FuelExemplar`, with a missing-module control
  exit 1); I did not re-run it (no lake allowed in this review).
- The impl-defined pins are honestly declared (fork line + gcc's pipe line in `gcc.txt`, the reason per header; a pin
  that is neither is a FAIL in the script); the handler-calls-exit row is UB-declared and equals glibc.
- CONTRACT D15 / VALIDATION / SUPPORTED / consumer notes: no overclaim found beyond P2-1's "by construction" and P3-6.

## Verdict

**MERGEABLE WITH FIXES.** The fix is right where it matters: on every conforming libc-mode shape probed, both engines
print gcc's line byte for byte, the negative controls hold, and the Lem change is confined to the startup return. Two
P2s before the ff-merge: (1) tighten the routing predicate / make a returned `exit` a loud refusal and reword the
"`--nolibc` untouched by construction" claims (a UB program under `--nolibc` now hangs both engines where the mainline
terminated); (2) regenerate the upstream filing's patch against pristine's files so `git apply --check` passes there.
The P3s are cheap and can ride along.

## Residual uncertainty

- No pty in the sandbox: gcc's terminal lines are reasoned from glibc's line-buffering, not measured.
- I did not run the inner_arg_temps Lean path (A15's lane covers 034/041 under it; its baseline moved consistently on
  both engines) nor the kernel replay, the lanes or `release.py` (forbidden here; the battery is running).
- The 447/787 sweeps are the worker's; my probes are 33 programs chosen for the arm's edges, not a corpus.
