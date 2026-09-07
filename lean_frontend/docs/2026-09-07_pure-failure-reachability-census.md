# Pure-failure reachability census (the 231 pure sites of the execution closure)

**Status: MEASUREMENT RECORD [AGENT auditor, 2026-09-07], read-only.** Branch
`audit/failure-reach` (worktree `worktrees/cerberus-lean-audit/failure-reach`) =
mainline `mdd/cerberus-lean` @ `4d1088004`. Nothing here is a decision; §Q6 is a
labelled [AGENT] judgement the operator asked for ("let's do the reachability census
and try to understand whether this is worthwhile" — "this" = the pure-failure
correspondence design, `docs/pure-failure-design:lean_frontend/docs/2026-09-07_pure-failure-correspondence-design.md`).
No `.lem`, Lean, script, baseline or pin was edited; the new files are this record,
its evidence directory (`2026-09-07_pure-failure-reachability-census-evidence/`,
192 KB) and the witnesses under `tests/failure-probes/reach/` (not wired into any
lane). Every count below is DERIVED from the named instrument or file unless it is
quoted verbatim.

Inputs read: the census (`2026-09-06_failure-census-and-correspondence.md`), the
typed-failure design §1–§2 (`2026-09-05_typed-failure-outcomes-design.md`), the
audit F1 reproducer (`2026-09-05_whole-project-release-gate-audit.md` §3 F1),
`scripts/failure_census.py` / `scripts/run_failure_census.py`,
`tests/failure-probes/FailureReach.lean`, `scripts/observations.py`
(`IMMACULATE_PANICS`), `tests/immaculate/baseline.txt`, the CI-sweep records,
`scripts/fuel_forms_pending.txt`, `generated/Driver.lean` (`hack`, `finalize`),
refined-cerberus (read-only, in place).

The key fact kept straight throughout: at RUNTIME an evaluated `failwithI`/`panic!`
panics (LemLib `implemented_by`, `LEAN_ABORT_ON_PANIC=1` → exit 134), so the mirror
is strict wherever the compiler evaluates the site; only sites whose VALUE is never
evaluated (dead bindings / unused arguments / projected-away components — the F1
class) vanish silently. In the LOGIC every evaluated site is `default` and a theorem
about a run that reaches one is about a contaminated value.

## Q0. Reproduction of the census counts on this tree

Instrument: `tests/failure-probes/FailureReach.lean`'s emission, re-run as a scratch
Lake package requiring `lean_frontend` by path (the `run_failure_census.py` recipe
without the cold provider) from the probe file
`…-evidence/FailureReachProbe.lean` (identical `FAILURE_REACH`/`FAILURE_RANGE`
emission plus one extra `FAILURE_CONS` row family for Q5). The dry run showed all
136 dependency modules up to date; the build elaborated the one probe module in
5.9 s (1.8 GB peak RSS, `scripts/capped` 32G). Verbatim tail:

```
Build completed successfully (138 jobs).
```

`FAILURE_REACH` rows 21,080; `FAILURE_RANGE` rows 11,231 (`…-evidence/instrument_build.txt`;
`reach.log` sha256 `62e61fbb…cc4a`, 4.96 MB, not committed — its rows for the 305
exec-closure owners are `…-evidence/reach_rows_exec_closure_owners.tsv`). Note: the
csmith corpus lane of another worktree was running during the build (pid 482453,
~63 min in, 115 GB free); the build is a single-module elaboration and was not
delayed further.

`scripts/failure_census.py --root . --reach-log reach.log --out census.json`
(unmodified script), verbatim stdout:

```
{
  "generated:monadic_ascribed": 263,
  "generated:pure_or_unresolved": 1253,
  "handwritten:monadic_ascribed": 7,
  "handwritten:pure_or_unresolved": 121
}
```

Derived from `census.json` (`…-evidence/census_counts.json`):

| Quantity | This tree (4d1088004) | Census record (de9f6d361) |
|---|---:|---:|
| Sites (whole tree) | 1,644 | 1,644 |
| Identified compiler owners / unresolved | 1,642 / 2 (`CoreParser.scanStep`, `Main.loadCoreImpl`) | 1,642 / 2 (same two) |
| Sites in the execution dependency closure | 305 | — |
| Pure, in the closure | **231** (126 generated + 105 hand-written) | 231 (126 + 105) |
| Generated monadic, in the closure | **67** (37 `NDkilled_Error0_loc`, 26 `undefined_Error_loc`, 4 `core_run_cause_needs_failure_constructor`) | 67 (37 / 26 / 4) |
| Hand-written monadic (memM arms), in the closure | **7**: `CerbMem.lean:2093 allocator, :2123 allocateObject, :2216 killM, :2704 effArrayShiftPtrval, :2774 memcmpM.getBytes, :2963 vaList, :2982 callIntrinsic` | 7 (same) |

All counts reproduce. The 231 are listed one per line in
`…-evidence/sites231_classified.tsv` (file, line, kernel owner, token, Q1, message
head, three closure columns, Q3 class, invariant/witness, cite). Per module: CerbMem
44, CerbFS 36, Core_reduction_aux 34, Core_reduction 33, Core_aux 14, Core_eval 9,
Driver 9, CerbStepInstances 8, CerbDecode 7, Formatted 7, Implementation 7,
Core_run_aux 5, CerbUtils 4, Ctype_aux 4, CerberusImpl 3, Utils 2, CerbFloat 1,
CerbFunMapInstances 1, CerbLocation 1, Builtins 1, Translation_aux 1. (Zero
comparison residuals are in the 231; `Core_run.core_thread_step2`'s 46 sites are NOT
in the drive closure — the driver steps through `Core_reduction.step_ctx`.)

## Q1. Position class of each of the 231 (TAIL vs NON-TAIL; used vs discardable)

Method (`…-evidence/classify_position.py`, reusing the census's comment stripper
and tokenizer so offsets agree): the unit starts as the innermost
`(failwithI … : T)` group (or the bare `panic!` token), is CLIMBED through match
arms (to the `match`), `if` branches (to the `if`), let bodies (to the `let`) and
wrapper parentheses to the maximal expression whose value IS the failure whenever
its branch is taken, and the token before that head decides: `:=` of a def/instance/
where-method → TAIL; `:=` of a `let` → LET-BOUND; `=>` of a `fun` → LAMBDA-BODY;
identifier/`)`/`some`/… → ARGUMENT; `match`/`if` → SCRUTINEE; `{ s with f := }` →
STRUCT-FIELD. Every climb step is recorded. Hand-written files are indentation-
scoped, so their nested-match ownership is unreliable at token level: all 57
NON-TAIL candidates and all 33 newline-statement rows were READ; 4 hand-written rows
were corrected from LET-BOUND to TAIL (outer-match arms: `CerbMem.lean:521, :531,
:1128, :1535`) and 33 `let …⏎ if/match … panic!` rows are the let BODY (TAIL).

Derived tallies (231):

| Q1 class | count | generated / hand-written | downstream use (read per site) |
|---|---:|---|---|
| **TAIL** | **178** | 81 / 97 | the failure is the value of its branch |
| NON-TAIL / LAMBDA-BODY | 20 | 20 / 0 | callback bodies (`caseMemValue`/`casePtrval` eliminators, `nd_bind`/`stExceptUndef_return` continuations, `List.map`/`setFilterBy` functions, local helper lambdas): evaluated iff the lambda is APPLIED — in OCaml exactly as in Lean, so a lambda body can never be an F1 discard; one (`Formatted.lean:508` vsnprintf) is the dead `Nothing` callback of `caseIntegerValue` |
| NON-TAIL / ARGUMENT | 14 | 10 / 4 | constructor/`some`/`Expr annot`/`integerIval`/`hack` arguments that are the enclosing definition's result — USED |
| NON-TAIL / LET-BOUND | 13 | 9 / 4 | `let x := match … failwithI …; body` — bound variable USED in the body in all 13 (lem confirmed for `oTy` core_aux.lem:140-148, `iop`/`fop` core_eval.lem:439-456, `current_proc` core_reduction.lem:1415-1427, `prec`/`justified` formatted.lem:447-455/:771; Lean read for `sz`/`membTy`/`size` CerbMem.lean:700-716, :1116-1130, :1413-1422); the two REACHABLE ones (`Formatted.lean:490, :499`) are evaluated at runtime — both engines crash (Q3) |
| NON-TAIL / SCRUTINEE | 4 | 4 / 0 | `match (match … failwithI …) with` — forced (Ctype_aux.lean:99) |
| NON-TAIL / LET-BOUND-FUN | 1 | 1 / 0 | a let-bound local lambda applied below (Core_eval.lean:128 `wrap_list`) |
| NON-TAIL / STRUCT-FIELD | 1 | 1 / 0 | `{ th_st with env := match … failwithI … }`, record used by `full_eval_pexpr` (core_reduction.lem:1248-1256) |
| **NON-TAIL, value USED** | **53** | | |
| **DISCARDABLE** (dead binding / unused argument / projected-away component) | **0** | | |

So the F1 discard class has NO member among the 231: every non-lambda NON-TAIL
value (33 = 13 + 1 + 1 + 14 + 4) is consumed on every path of its enclosing
definition, and the 20 lambda bodies are discard-immune by construction.

## Q2. Empirically reached sites (corpus record + re-run)

Every recorded CRASH row was re-run on this tree with the immaculate lane's
two-engine recipe (`scripts/test_immaculate.sh:145-176`; `scripts/test_exec.sh`
alone classifies both-crash files CERB_SKIP and never samples the Lean side); the
driver binaries were freshness-checked (`tools/check_driver_fresh.sh --check`:
`oracle OK`, `lean OK`; stamps copied from the primary, hashes recomputed here).
Verbatim lines + exit codes: `…-evidence/q2_recorded_crash_rows.txt`.

| Program (record) | Site among the 231 | Oracle | Lean | Input class |
|---|---|---|---|---|
| `tests/immaculate/nolibc/g4-bswap64-overflow.c` (baseline `MATCH \| L=CRASH`; `IMMACULATE_PANICS`) | `CerbUtils.lean:172` | 125 `Z.Overflow` | 134 `PANIC at CerbUtils.gcc_builtin_bswap64 CerbUtils:172:4` | legal C; oracle-wrong (tray 12), mirrored |
| `…/g5-decode-multichar.c` | `CerbDecode.lean:151` (reached via the desugarer; the site is in the drive closure via `prepare_main_args`) | 125 `Failure("decode_character_constant: invalid char constant ==> ab")` | 134 `PANIC at …decode_character_constant_aux CerbDecode:151:6` | implementation-defined (multi-char constant, 6.4.4.4p10) |
| `…/offsetof-union-member.c` | `CerbMem.lean:478` | 125 `Failure("Tags definitions must be set by Tags.set_tagDefs before any use")` | 134 `PANIC at CerbMem.sizeofCtype_lemFuel CerbMem:478:15` | well-typed UB-free C — model bug (upstream asymmetry) |
| `…/zd-z2fl03-nan-to-int.c` (also `tests/noodle-probes/float/float_nan_to_int_ub.c`) | `CerbFloat.lean:307` | 125 `Z.Overflow` | 134 `PANIC at CerbFloat.truncToInt CerbFloat:307:4` | UB (6.3.1.4p1) |
| `…/zd-z2m02-device-funptr-call.c` | `CerbMem.lean:1379` | 125 `Failure("case_ptrval")` | 134 `PANIC at CerbMem.casePtrval CerbMem:1379:4` | UB |
| `tests/minimal/097-null-ptr-arith.undef.c` (gcc lane `SKIP_LEAN_CRASH`) | `CerbMem.lean:1726` | 125 `Failure("TODO(pure shift a null pointer should be undefined behaviour), offset:4")` | 134 `PANIC at CerbMem.arrayShiftPtrval CerbMem:1726:6` | UB |
| `tests/immaculate/libc/zd-z2f04-closedir.c` | `CerbFS.lean:510` (Lean) / `Driver.lean:349` (oracle) | 125 `internal error: can_advance: Step_error2 ==> …didn't match the lvalue type: Specified(1)` | 134 `PANIC at CerbFS.fs_opendir CerbFS:510:2` | library/filesystem boundary (legal `opendir`/`closedir`) |
| `tests/tcc/40_stdio.c`, `tests/freebsd/cat.c`, `tests/suite/fs/stat.c` (CI sweep `LEAN_CRASH` ×3) | `CerbFS.lean:338, :260, :504` | **0** (`Defined …`) | 134 `PANIC at CerbFS.fs_read/fs_close/fs_stat` | filesystem boundary, class (c): ONE-SIDED Lean refusals |
| `…/g2-memcmp-uninit.c`, `…/zd-z2m01-aligned-alloc-zero-zero.c` | `CerbMem.lean:2774`, `:2093` — MONADIC memM arms (the 7), not in the 231 | 125 | 134 | UB / kind-2 |
| `csmith/sa_csmith_002/003/005.c` (gcc lane `SKIP_LEAN_CRASH`) | `Translation` (front-end), not in the closure | 125 `Translation called on Ail program with an invalid node` | 134 same text | csmith F-A class |
| historical `pr44468.c` (`CerbMem.offsetsof` unknown tag), `suite/parsing/array.c` (out of memory) | `CerbMem.lean:415` at an earlier tree; not a site | — | — | both rows are MATCH today (`final-reporting-summary.json` movement) |

Derived: **10 of the 231 have been reached by a corpus program on record**
(CerbUtils:172, CerbDecode:151, CerbMem:478, :1379, :1726, CerbFloat:307, CerbFS:260,
:338, :504, :510); `Driver.lean:349` is reached on the oracle side by a recorded
program. This census adds 5 more (Q3): Formatted:490, :499, Core_reduction:434
(Fence), CerbMem:1045, CerbDecode:121; with the oracle-side Driver:349 that makes
**16 reached in total on this tree**. `IMMACULATE_PANICS` (8 origins) covers 6 of the 231 plus
the 2 memM arms.

## Q3. Reachability from well-typed, UB-free C in the default configuration

Method: per-site assignment by `…-evidence/q3_assign.py` (rules keyed on module/
owner/message, fail-closed — the script exits if any of the 231 is unassigned),
each rule carrying the invariant or witness and a file:line cite; the witnesses were
run with the two-engine recipe (`…-evidence/q3_witness_outputs.txt` lists every
program tried, positives and negatives; the positives are committed under
`tests/failure-probes/reach/` with a README). Priority was as instructed: the 33
non-lambda NON-TAIL values first (none is discardable, Q1; 2 are REACHABLE and both
engines crash), then TAIL sites on the driver / memory / core-eval path; UNKNOWN
rows say what is missing.

Derived tallies (231): **UNREACHABLE-BY-INVARIANT 166 · REACHABLE 48 · UNKNOWN 17.**

UNREACHABLE by invariant kind (derived from the rule texts): typing 62 (Ail/Core
typing: `genTyping.lem:1512-1516` sizeof completeness, `core_typing.lem:626-659`
PEop signatures, `core_typing.lem:30-75` pattern typing, tag-kind consistency,
builtin signatures) · structural 52 (kernel-provable from the Lean definitions:
`CerberusImpl.sizeof_ity` has no `none` arm after normalisation
(`CerberusImpl.lean:170-183`); `IntegerValue` is single-constructor and
`caseIntegerValue` never invokes its `Nothing` callback (`CerbMem.lean:68-70,
:1620-1622`); `PEconstrained` is only propagated, never introduced
(`core_eval.lem:191-219`); `MVconcurRead` has no construction in `CerbMem.lean`;
`SeqRMW` is emitted with `Paction Pos` (`core_aux.lem:564`); the `==` on
`core_step2` only ever compares against `Step_blocked2` (`Driver.lean:425`)) ·
config 20 (`CerbGlobal` defaults as plain defs: execution mode `none`, `is_CHERI
= false`, concurrency refused at `Driver.lean:320`) · model-shape 14 (driver/memory
invariants with NO theorem: `env = [Map.empty]` `driver.lem:1571`; the arena is
`Epure` of a value at `finalize` because `Step_done` requires it
`core_run.lem:1557-1589`; homogeneous arrays; dispatch order in `step_ctx`) ·
promotion 5 (`formatted.lem:471` applies the printf predicates to
`normalise_ctype arg_ty` after default argument promotion) · dominance 4 (an
earlier evaluation of the same scrutinee fires first — `formatted.lem:447-455` vs
`:614/:673`, witnessed by `%.*f`/`%.*s`; `__builtin_ctz(0)` is `DUMMY(__builtin_ctz)`
UB before the model runs) · pin 4 (libc.core / std.core) · dispatch 3 · other 2.
Rows marked "not kernel-checked"/"not a theorem" in the TSV are exactly the
model-shape and tag-kind ones (the census asked for the invariant's NAME and cite,
not a proof; none of these is "the comment says so" — each names the enforcing
rule or definition).

REACHABLE (48) by input class:

| Input class | Sites | Both engines fail? |
|---|---|---|
| filesystem boundary, class (c) refusal (`CerbFS.lean`, 36 sites: 4 witnessed by corpus rows, 32 by construction — each is the unconditional body of its `fs_*` entry or a guard on the syscall shape) | 36 | **NO — one-sided**: the oracle (SibylFS) succeeds (`freebsd/cat.c`, `suite/fs/stat.c`, `tcc/40_stdio.c` exit 0), Lean refuses. Declared boundary (VALIDATION.md). In the LOGIC these are `default` values on the `drive_fs_step` frame |
| well-typed, UB-free C — model refusal or model bug | 4: `Formatted.lean:490` (`printf("%.*d",…)`, witness `printf_star_prec.c`), `:499` (`%*d`, `printf_star_width.c`), `Core_reduction.lean:434` Fence (`atomic_thread_fence`, `atomic_fence.c`, libc mode), `CerbMem.lean:478` (offsetof on a union-bearing struct, the pinned `offsetof-union-member`) | yes (oracle 125 / Lean 134, same message) |
| UB program | 3: `CerbMem.lean:1379`, `:1726`, `CerbFloat.lean:307` | yes |
| implementation-defined (int → function-pointer conversion, no call) | 1: `CerbMem.lean:1045` (`funptr_reload.c`: `Failure("unknown function pointer: 2748")` / `PANIC at CerbMem.reconstructValue_lemFuel CerbMem:1045:18`) | yes |
| legal C, oracle-wrong (tray 12) | 1: `CerbUtils.lean:172` | yes |
| harness `--args` boundary (an argv byte `\`) | 2: `CerbDecode.lean:121` (witness `args_backslash.c`), `:151` (shared arm) | yes |
| filesystem boundary, oracle-side crash (Lean refuses earlier at `CerbFS:510`) | 1: `Driver.lean:349` `can_advance` | class-match only (different sites) |

UNKNOWN (17): `Ctype_aux.lean:99` ×4 (`are_compatible_aux`: cross-TU only, the
same-TU fast path is `tag1 = tag2` at `ctype_aux.lem:115-116`; needs a 2-TU witness
through `scripts/test_multi_tu.sh` with an incomplete struct in one TU) ·
`Core_reduction.lean` ×8 (`step_action` RMW / CompareExchange{Strong,Weak} — the C11
atomics family, `atomic_fetch_add` is rejected by the desugarer on both engines;
`one_step_unseq_aux`, `break_at_sseq Cbound`, `step_ctx` "found a value with ctx <>
CTX", `NO_BOUND (SeqRMW)`, `NO_BOUND (Neg)`, `STUCK` — all need a Core progress /
context-decomposition argument for the sequential fragment; a plain `_Atomic int x;
x += 1` passes) · `CerbMem.lean` ×4 (`:598` intToBytes range and `:1124` union
member record — need a value-representability / memory well-formedness invariant;
`:1727` array shift on a `PVfunction` — the tested route `(char*)main + 1` is
dominated by the typed `Error MerrOther "called isWellAligned_ptrval on function
pointer"` on both engines; `:1750` member shift on a `PVfunction`, untested) ·
`Core_reduction.lean:349`.

Cross-tabulation Q1 × Q3: TAIL — 124 unreachable / 46 reachable / 8 unknown;
NON-TAIL — 42 unreachable / 2 reachable (the two printf LET-BOUND sites, both
evaluated) / 9 unknown. **A DISCARDABLE-and-REACHABLE site does not exist** (there is
no DISCARDABLE site at all).

## Q4. The eight fuel sentinels

| Worker(s) | On EVERY `drive` run's path? | Recursion / depth needed | Exhaustion in practice |
|---|---|---|---|
| `hack` | **yes** — `drive` → `driver2` → `finalize` → `hack` (`driver.lem:1890`, `:1476`; `Driver.lean:468-469`) | one `step_eval_pexpr` per outermost `PEcase`/`PElet`/`PEcall` peel (`core_eval.lem:725-745, :965-1006`: a selected branch / substituted body is returned UNEVALUATED). But `Step_done` is produced only when the arena is already `Epure` of a value (`core_run.lem:1557-1589`) and `Step_done2` leaves the arena untouched (`driver.lem:485-486`), so at `finalize` `valueFromPexpr` succeeds on the FIRST iteration: depth exactly 1 | needs fuel ≥ 1. Fuel is AMBIENT (each worker starts from `LemFuel.fuel`, `Driver.lean:438`), so `hack` exhausts only at fuel 0 — where `driver2_lemFuel 0` has already produced the typed kill before `finalize` runs (`driver.lem:1890` order; `Driver.lean:439-440`). At the CLI default 10^8, never. A one-iteration lemma (`hack_lemFuel (n+1) … (PEval v) = v`) or a measured wrapper with μ = 1 under the `Step_done` shape would close the pending row without any twin |
| `to_pure`, `to_pures` | **yes** — `finalize` and `driver_globals` (`driver.lem:1477, :1614`) | structural on the arena; the arena is `Epure pe` at both call sites (Step_done shape; `driver.lem:1613` "technically the arena should always be a value at this point"), so `to_pure` returns `Just pe` at depth 1 and `to_pures` is not entered | needs fuel ≥ 1; same argument as `hack` |
| `many`, `many1` | no — printf family only (`Formatted.format0/decimalInteger/nonnegativeDecimalInteger/flags0`, `Formatted.lean:312-393`, called from the `printf`/`vprintf`/`vsnprintf` builtins in `Driver`/`Core_reduction`) | one fuel unit per repetition = per consumed character/digit of the format string (`monadic_parsing.lem:100-115`) | exhausts only at fuel < the longest `many` run in a format string (bounded by the string's length); the payload is the empty-result parser (a normal parse failure, indistinguishable — the register's note) |
| `are_compatible_aux`, `are_compatible_params_aux0`, `are_compatible_params0` | no — struct-value stores: `Core_aux.memValueFromValue`'s `Struct` arm (`core_aux.lem:193-198`) | same-TU tags: the `Symbol.from_same_translation_unit` fast path returns `tag1 = tag2` at depth 1 (`ctype_aux.lem:115-116`); cross-TU tags recurse through members, pointers and function types (depth = type nesting; non-terminating on cross-TU self-referential structs — the register's `deep-ref` note, C4 F-C4-1) | single-TU programs: never; multi-TU: fuel < nesting depth; the pathological cross-TU cycle is a NATIVE stack overflow before any fuel is consumed |

Derived: of the 8 pending rows, 3 are on every run's path and are exhaustible only
at fuel 0, which the typed `driver2` kill dominates; 5 are input-dependent with a
concrete data measure available (format-string length; type nesting).

## Q5. Consumer exposure (refined-cerberus, read-only)

refined-cerberus pins cerberus-lean `89f7e6885` (`scripts/semantics-pin.env`), not
this tree; its Lean sources that import cerberus-lean modules are
`cerberus-heaplang/CerberusHeapLang/{Step,DriverCollapse,Soundness}.lean`
(`import Core_aux, Core_run_aux, Core_reduction, CerbMem, Driver, CerbND,
Core_eval_lemMeasureProofs, …`). The constants they reference directly (grep,
comments included — an over-approximation): `drive`, `driver2`, `step_ctx`,
`step_action`, `step_eval_pexpr`, `full_eval_pexpr`, `eval_pexpr_aux2`,
`E.eval_pexpr20`, `memValueFromValue`, `valueFromPexpr`, `to_pure`, `hack`,
`finalize`, `process_core_step2`, `new_drive_core_threads`,
`drive_nonmemory_steps_aux2`, `liftMem`, `liftCore_run`, `CerbND.runND(Fuel)`, and
`CerbMem.{storeM, loadM, killM, allocateObject, allocateRegion, opIval, eqPtrval,
ltIval, leIval, eqIval, minIval, maxIval, sizeofIval, alignofIval, arrayShiftPtrval}`.
The probe computed three kernel closures on THIS tree (`FAILURE_CONS` columns):

| Root set | 231 sites whose owner is in the closure | of which REACHABLE / UNKNOWN |
|---|---:|---|
| `closure(drive)` | **230** (all but `CerbFunMapInstances.lean:84`, reached only via `initial_driver_state`) | 48 / 17 |
| all consumer roots above | 230 | 48 / 17 |
| step-level roots only (the above minus `drive`, `driver2`, `hack`, `finalize`, `process_core_step2`, `new_drive_core_threads`, `drive_nonmemory_steps_aux2`, the runners and lifts — what `Step.lean`/`Soundness.lean`'s per-step theorems are about) | **148** (CerbMem 44, Core_reduction_aux 34, Core_reduction 33, Core_aux 14, Core_eval 9, CerbUtils 4, Ctype_aux 4, CerberusImpl 3, CerbFloat 1, CerbLocation 1, Utils 1) | **7** / 17 — the 7: `CerbFloat.lean:307`, `CerbMem.lean:478, :1045, :1379, :1726`, `CerbUtils.lean:172`, `Core_reduction.lean:434` (Fence) |

So "how many of their theorems could be about a contaminated value today": every
theorem stated over `drive`/`driver2` (`DriverCollapse.lean`) sees all 230; a
per-step theorem sees 148 sites, of which 7 are reachable from C — 3 by UB
programs, 1 implementation-defined, 1 legal-C-oracle-wrong, 2 well-typed UB-free
(offsetof-union, `atomic_thread_fence`); the 36 filesystem refusals and the 2
printf sites lie OUTSIDE the step-level closure (they are `Driver`/`Formatted`
frames). Caveat: constant-dependency membership is an upper bound on use, not a
path.

## Q6. Assessment — [AGENT] judgement, clearly labelled

**(i) Is there ANY execution discrepancy today?** No, on the measured axis. The F1
class needs a failure whose VALUE the Lean compiler never evaluates; among the 231
pure exec-closure sites there is no such value: 178 are TAIL, 20 are lambda bodies
(evaluated on application in both semantics), and each of the remaining 33
let-bound / argument / scrutinee / field values is consumed on every path of its
definition (Q1, read site by site, lem-confirmed where the Lean text was
ambiguous). The two reachable let-bound sites (`printf("%.*d")`, `printf("%*d")`)
are the F1 SHAPE and they crash both engines at runtime with the same text — the
strict evaluation the design worries about is what actually happens. The 12
both-crash reachable sites all have the oracle failing too, in the same class; the
36 one-sided rows are the declared filesystem boundary, and `Driver.lean:349` is an
oracle-side crash Lean pre-empts with a refusal.

**(ii) How large is the reasoning exposure?** Bounded and mostly documented. In the
LOGIC, a theorem over `drive` on one of the 16 reached programs is about a
`default`. Of the 148 sites a per-step consumer theorem can see, 7 are reachable
(4 of them only by UB or implementation-defined programs); the 8 exhaustion
sentinels are not the exposure the design describes: the 3 on every run's path
(`hack`, `to_pure`, `to_pures`) need exactly one iteration at `finalize` and exhaust
only at fuel 0, where `driver2`'s typed kill already fires — a one-line measured
wrapper (μ = 1 under the `Step_done` shape) closes them, and the other 5 have
concrete data measures (format-string length, type nesting) suited to the existing
C4 `fuel_measure … assuming` route. The genuinely open residue is the 17 UNKNOWN
rows (cross-TU compatibility ×4, sequential-fragment progress ×8, memory
well-formedness ×4, one Eunseq shape) and the 4 well-typed-UB-free reachable
refusals, none of which a twin would make disappear — it would type them.

**(iii) Which option do the numbers support?**

| Option | What it buys against the measured facts | Cost | Verdict [AGENT] |
|---|---|---|---|
| A — full twin arc (design note) | typed `.failed` for 231 + 67 sites; `_sound` per function; `drive_chk_mono` | duplicates the fallible cone in the backend; new `_sound`/`_mono` obligations; printer/codec/baseline movement; consumer re-pin | not supported by TODAY's numbers: the property it exists to restore (a discarded failure OCaml raises) has zero instances in the execution closure, and the reachable set it would type is 12 both-crash + 36 declared refusals |
| B — mini-twin for the 8 sentinels up to `drive` | `.exhausted` for `hack`/`to_pure(s)`/`many(1)`/`are_compatible*` | a backend mode still, for 8 workers | weakly motivated: the 3 always-on-path rows are provably one-iteration (a measured wrapper, no twin); the 5 input-dependent rows have data measures (C4 route) |
| C — status quo + register | none | zero | **supported**: register the 48 REACHABLE rows (36 declared, 12 both-crash) and the 17 UNKNOWN rows with their needs; close the 3 always-on-path sentinels by the one-iteration lemma; keep the F1 probe suite as a tripwire |

Numbers that would change the answer: **any DISCARDABLE site** (today 0; a single
one that is REACHABLE makes A immediate — the lem probe suite `discarded_failures.lem`
is the tripwire, and a NEW generated `let _ = failwith …`/unused-argument shape in
the exec closure would show up as a NON-TAIL row of this census's classifier);
**a REACHABLE site in the step-level closure where the oracle SUCCEEDS** (today 0 —
the 36 one-sided refusals are all `CerbFS`, outside it; if the consumer's step
theorems ever cover `drive_fs_step`, the CerbFS class becomes their problem and a
typed refusal — not a twin — is the fix); **growth of the well-typed-UB-free
reachable set beyond 4** or a **kind-1 both-crash site that a `∀ fuel` theorem must
quantify over** (today none: every reachable site fails at every fuel). If the
operator's goal is the LOGICAL property "no theorem about a contaminated value" for
its own sake rather than oracle conformance, then A is the only option that
delivers it, and this census says the price buys 12 + 36 sites of exposure, 4 of
them on well-typed UB-free inputs.

## What I could not do / caveats

- No multi-TU witness (the 4 `are_compatible_aux` rows stay UNKNOWN); the other 13
  UNKNOWN rows need progress/well-formedness arguments beyond a bounded census.
- `reach.log` (4.96 MB) is not committed; its sha256 and the 305 owners' rows are.
- The consumer pin is `89f7e6885`, this tree is `4d1088004`; Q5 used THIS tree's
  closures against the consumer's referenced constant NAMES.
- The instrument build ran while another worktree's csmith lane was running (a
  one-module, 6-second elaboration; recorded in `instrument_build.txt`).
- The Q1 classifier is token-level; its hand-written-file weaknesses were closed by
  reading all 57 NON-TAIL candidates and 33 newline rows (4 corrections, listed).
- `test_exec.sh <file>` cannot show both-crash pairs (CERB_SKIP); the two-engine
  recipe in `tests/failure-probes/reach/README.md` is what was run.

## Files

- `lean_frontend/docs/2026-09-07_pure-failure-reachability-census.md` (this record)
- `lean_frontend/docs/2026-09-07_pure-failure-reachability-census-evidence/`:
  `FailureReachProbe.lean` (instrument), `instrument_build.txt`, `census_counts.json`,
  `reach_rows_exec_closure_owners.tsv`, `classify_position.py` (Q1), `q3_assign.py`
  (Q3, fail-closed), `sites231_classified.tsv` (THE 231, all columns),
  `q2_recorded_crash_rows.txt`, `q3_witness_outputs.txt`
- `tests/failure-probes/reach/` — 9 witness programs + README (not wired)

```
$ git status --porcelain
 ?? lean_frontend/docs/2026-09-07_pure-failure-reachability-census-evidence/
 ?? lean_frontend/docs/2026-09-07_pure-failure-reachability-census.md
 ?? tests/failure-probes/reach/
```
