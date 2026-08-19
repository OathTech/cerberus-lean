# Arc 4 / S0 — silent-rc=1 root cause + tests/minimal frontier map

Date: 2026-08-19. Slice S0 of the exec-pipeline arc
(charter: `2026-08-19_arc4-exec-pipeline-charter.md`).

## Root cause of the "silent" rc=1

**The crash was never silent.** The pipeline prints
`INTERNAL PANIC: executed 'sorry'` to **stderr** and exits 1; earlier
probes had merged or dropped stderr. With `LEAN_ABORT_ON_PANIC=1` the
same message appears and the process aborts (rc=134; note stdout is
block-buffered and lost on abort, which is why that mode looks even more
silent on stdout).

**The executed sorry is NOT `easy_update_mem_value_aux`.** The elaborated
Core for `int main(void){return 42;}` contains no memory operation at all
(`--pp core`: `pure`/`save`/`run` only), so the memory-write path is never
reached. The executed sorry is the lem-backend **fallback `BEq core_step2`
instance** (`generated/Core_reduction.lean:248`, `beq _ _ := sorry`,
`priority := low` — emitted because `core_step2` carries `core_runM`
continuations and closures, so equality is not derivable), evaluated from
`driver2`'s blocked-thread filter.

Evidence — native backtrace at the abort (SIGABRT handler shim preloaded,
frames resolved with addr2line against the executable):

```
lean_sorry
CerberusLean_List_filterTR_loop___at___00driver2__lemFuel_spec__0___lam__0
LemLib_Lem__Maybe_maybeEqualBy___redArg
CerberusLean_List_filterTR_loop___at___00driver2__lemFuel_spec__0
CerberusLean_driver2__lemFuel___lam__4
CerberusLean_nd__bind__lemFuel___redArg___lam__1
... (nd_bind chain) ...
CerberusLean_CerbND_runND___redArg
```

That is exactly `frontend/model/driver.lem:1405`:

```lem
let non_blocked =
  List.filter (fun (tid, step_opt) ->
    step_opt <> Just Core_reduction.Step_blocked2
  ) tid_steps in
```

which the Lean backend renders as
`maybeEqualBy (fun x y => x == y) step_opt (some Step_blocked2)`
(`generated/Driver.lean`, inside `driver2_lemFuel`), dispatching to the
sorry'd `BEq core_step2`. In OCaml this line is polymorphic structural
equality, which compares constructor tags first and therefore never
inspects the closures — fine there, unimplementable as a total derived
`BEq` in Lean, hence the backend's sorry fallback firing at runtime.

Notes:

- The sibling filter at `driver.lem:1371` (`step <> Step_blocked2` inside
  `_non_blocked_th_sts`) uses the same instance, but its binder is unused
  and the Lean compiler dead-code-eliminates it (backtrace confirms the
  `maybeEqualBy` filter is the one that fires). A fix must still cover it.
- The **same root cause explains the desugar-stage crashes**: array
  declarators evaluate their size via the constant-expression driver,
  which runs the same code
  (`evaluate_integer_constant_expression → evalIntegerConstantExpression
  → CerbND.runND → driver2 → filter → sorry`; backtrace on
  `023-array-read` confirms, identical inner frames).
- Every execution that reaches the filter with computed steps panics; the
  14 files that *complete* runND are exactly those whose executions are
  all Killed (UB / memory error) before the first filter evaluation —
  zero `Active` results exist today.

Hypothesis discrimination (charter list):

| Hypothesis | Verdict | Discriminator |
|---|---|---|
| (a) runtime sorry | **YES — but `BEq core_step2`, not `easy_update_mem_value_aux`** | backtrace; return-42 Core has no memory ops |
| (b) stack overflow in runND | no | crash is instant with default stack; backtrace is shallow |
| (c) swallowed error in Main.lean | no | Main.lean has no try/catch on the exec path; message was on stderr all along |
| (d) fuel exhaustion | no | panic is `lean_sorry`, not the fuel panic |

**Disposition: PARKED for S1.** Any fix decides how `= / <>` on a
closure-carrying type should behave (options: lem-backend constructor-tag
comparison for such equalities, a hand-written honest `BEq core_step2`
that panics on same-constructor payload comparison, or rewriting the two
filters' equality shape) — that is driver/lem-backend semantics, outside
S0's "small and clearly correct" latitude. S1 fixing this single instance
should unblock 77 of the 105 files' current first crash (68
execute-crash + 9 desugar-crash sorry panics).

## Frontier map — tests/minimal (105 files), per-file deepest stage

Method: `./scripts/cerberus --cabs-json` per file, then the pipeline
binary (`lean_frontend/.lake/build/bin/cerberus-lean`) with a 30 s
timeout, stdout/stderr captured separately; stage = deepest stage marker
printed. All 105 files pass cabs-json import, and **no file fails
desugar, typecheck, or translation semantically** — every failure past
translation (and the 10 desugar-stage crashes) is a runtime panic, not a
stage error result.

Histogram (deepest stage / failure class):

| Count | Stage / class |
|---:|---|
| 68 | execute-crash / `executed 'sorry'` panic (BEq core_step2, driver2 filter) |
| 9 | desugar (crash) / same sorry via constant-expression driver (array sizes etc.) |
| 12 | execute-crash / `can_advance: Step_error2 ==> Store|Load|Kill` (4+4+4) — LemLib failwithI panic; step became `Step_error2` via `ACTION_ILLTYPED` (core_reduction.lem:711/740/781 → driver.lem:915): action operands are values but not the expected shapes — S1 material |
| 14 | execute-result / runND completes, all Killed: 7 UB (the .undef tests — plausibly correct), 4 memory access error, 1 memory error, 2 Illformed_program |
| 1 | execute-crash / `CerbMem.arrayShiftPtrval` panic (CerbMem:587 "shift on null pointer is UB" — should be a Killed/UB result, not a panic) |
| 1 | desugar (crash) / `TODO(use the error the monad) illtyped SeqRMW` panic + SIGSEGV (042-nested-loop, rc=139) |

Summary: 105/105 cabs-json → 95/105 through desugar+typecheck+translate
into execution (10 crash inside desugar's const-expr driver) → 14/105
complete runND (all Killed, 0 Active). No timeouts (30 s).

Per-file table (stage = deepest reached; `desugar (crash)` = panic while
desugaring, all other desugar/typecheck/translate outcomes succeeded):

| file | stage | detail |
|---|---|---|
| 001-return-literal | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 002-return-zero | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 003-arith-add | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 004-arith-sub | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 005-arith-mul | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 006-arith-div | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 007-local-var | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 008-local-var-arith | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 009-if-true | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 010-if-false | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 011-if-else | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 012-compare-eq | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 013-compare-lt | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 014-while-simple | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Store |
| 015-while-sum | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Store |
| 016-func-simple | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 017-func-recursive | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 018-increment | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 019-decrement | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 020-global-var | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 021-pointer-basic | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 022-pointer-write | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 023-array-read | desugar (crash) | rc=1; INTERNAL PANIC: executed 'sorry' (const-expr driver) |
| 024-array-write | desugar (crash) | rc=1; INTERNAL PANIC: executed 'sorry' (const-expr driver) |
| 025-struct-basic | execute-result | Killed (memory access error) |
| 026-ternary | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 027-for-loop | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Store |
| 028-break | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 029-continue | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Load |
| 030-negative | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 031-bitwise-and | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 032-bitwise-or | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 033-bitwise-xor | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 034-bitwise-not | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 035-shift-left | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 036-shift-right | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 037-logical-and | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 038-logical-or | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 039-compound-assign | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Load |
| 040-do-while | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Load |
| 041-switch | desugar (crash) | rc=1; INTERNAL PANIC: executed 'sorry' (const-expr driver) |
| 042-nested-loop | desugar (crash) | rc=139 SIGSEGV; PANIC LemLib failwithI: TODO(use the error the monad) illtyped SeqRMW |
| 043-comma | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 044-void-func | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 045-ptr-arith | desugar (crash) | rc=1; INTERNAL PANIC: executed 'sorry' (const-expr driver) |
| 046-ptr-ptr | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 047-cast | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 048-pre-post-inc | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Kill |
| 049-scope-shadow | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 050-modulo | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 051-sizeof-type | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 052-sizeof-expr | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 053-static-local | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 054-string-literal | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 055-char-array-init | execute-result | Killed (core_run error: Illformed_program: PEarray_shift: type error ==> <core_pexpr>) |
| 056-func-ptr | execute-result | Killed (core_run error: Illformed_program: null function pointer) |
| 057-void-ptr | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 058-struct-value | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 059-union-basic | execute-result | Killed (memory access error) |
| 060-switch-fallthrough | desugar (crash) | rc=1; INTERNAL PANIC: executed 'sorry' (const-expr driver) |
| 061-goto | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 062-multidim-array | desugar (crash) | rc=1; INTERNAL PANIC: executed 'sorry' (const-expr driver) |
| 063-logical-not | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 064-precedence-ptr | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Load |
| 065-typedef | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 066-cast-float | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 067-if-int | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 068-div-by-zero.undef | execute-result | Killed (undefined behaviour) |
| 069-mod-by-zero.undef | execute-result | Killed (undefined behaviour) |
| 070-signed-overflow.undef | execute-result | Killed (undefined behaviour) |
| 071-null-deref.undef | execute-result | Killed (undefined behaviour) |
| 072-out-of-bounds.undef | desugar (crash) | rc=1; INTERNAL PANIC: executed 'sorry' (const-expr driver) |
| 073-exit.libc | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 074-abort.libc | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 075-main-argc-argv | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 076-main-argv-access | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 077-bool-trap.undef | execute-result | Killed (memory error) |
| 078-float-special | execute-result | Killed (memory access error) |
| 079-unseq-simple | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 080-unseq-reads-only | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 081-unseq-diff-locations | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 082-unseq-race.undef | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 083-unseq-nested-assign.undef | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 084-unseq-two-writes.undef | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 085-unseq-comma-seq | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 086-unseq-comma-writes | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 087-unseq-increment.undef | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 088-unseq-postinc-read.undef | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 089-unseq-func-args.undef | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 090-unseq-func-args-ok | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 091-unseq-nested-complex.undef | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 092-unseq-comma-plus.undef | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 093-nd-choice | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 094-bool-conversion | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Kill |
| 095-unsigned-div-zero.undef | execute-result | Killed (undefined behaviour) |
| 096-unsigned-mod-zero.undef | execute-result | Killed (undefined behaviour) |
| 097-null-ptr-arith.undef | execute-crash | rc=1; PANIC CerbMem.arrayShiftPtrval CerbMem:587: shift on null pointer is UB |
| 098-cross-alloc-ptrdiff.undef | desugar (crash) | rc=1; INTERNAL PANIC: executed 'sorry' (const-expr driver) |
| 099-negative-right-shift | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Kill |
| 100-int-wrap-unsigned | execute-crash | rc=1; INTERNAL PANIC: executed 'sorry' |
| 101-signed-overflow.undef | execute-result | Killed (undefined behaviour) |
| 102-bool-implicit-conv | desugar (crash) | rc=1; INTERNAL PANIC: executed 'sorry' (const-expr driver) |
| 103-union-store-load | execute-result | Killed (memory access error) |
| 104-unsigned-wrap-arith | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Kill |
| 105-bitwise-ops | execute-crash | rc=1; PANIC LemLib failwithI: can_advance: Step_error2 ==> Store |

## Post-S1a frontier (2026-08-19, after eliminating the `BEq core_step2` sorry)

S1a fix: hand-written OCaml-polymorphic-equality-parity instances for
`core_step2` in `lean_frontend/CerbStepInstances.lean`, imported into
`Driver.lean` via `declare {lean} extra_import` in driver.lem (the only
module that uses equality on `core_step2`). The generated sorry fallbacks
remain in `Core_reduction.lean` at `(priority := low)` but are overridden
at every use site. (`declare {lean} skip_instances type core_step2` was
probed and does NOT work: it also suppresses the needed real Inhabited
instance, which Core_reduction.lean itself requires at its
`failwithI : core_step2` sites and which a downstream hand-written file
cannot provide — import cycle. Same mechanism as CerbCtypeInstances.)

Sweep rerun with the S0 methodology (per file: `--cabs-json`, then the
pipeline binary, 30 s timeout, stdout/stderr separate). Histogram:

| Count | Stage / class |
|---:|---|
| 62 | execute-result / **Active with a return value** (was 0 — first Active results ever) |
| 26 | execute-result / Killed: 15 UB (all .undef), 7 memory access/memory error, 4 Illformed_program |
| 15 | execute-crash / `can_advance: Step_error2 ==> Store\|Load\|Kill` (4+5+6) — ACTION_ILLTYPED, S1 queue item 2 |
| 2 | execute-crash / `TODO(use the error the monad) illtyped SeqRMW` (042, 076) |
| 0 | desugar (crash) — const-expr driver fully unblocked |
| 0 | `executed 'sorry'` panics |
| 0 | timeouts |

Summary: 105/105 through desugar+typecheck+translate (was 95), 88/105
complete runND (was 14), 62/105 Active (was 0).

Delta for the 77 previous BEq-sorry crashers:

- 61 → execute-result **Active** (incl. return-42 twin 001 and most of the
  arithmetic/control-flow corpus);
- 12 → execute-result Killed: 8 .undef files now Killed (undefined
  behaviour) — plausibly correct; 058-struct-value + 072-out-of-bounds
  Killed (memory access error); 073/074 (.libc) Killed
  `Illformed_program: calling an unknown procedure exit/abort` — NEW
  finding class (libc procs not linked), S2/S3 material;
- 3 → the pre-existing `can_advance ACTION_ILLTYPED` class (017 Load,
  045 Kill, 102 Kill), growing it 12 → 15;
- 1 → the `illtyped SeqRMW` class (076, joining 042).

Other movements and notes:

- 097-null-ptr-arith.undef: previously `CerbMem.arrayShiftPtrval` panic,
  now completes as **Active rv=0** — OCaml says UB, so this is now a
  *wrong result*, not a crash (differential suspect for S2/S3; the panic
  no longer fires on this input path).
- 098-cross-alloc-ptrdiff.undef: Active rv=1 — likewise a differential
  suspect (.undef completing as Active).
- The `can_advance`/`SeqRMW` failwithI panics now exit rc=139 (SIGSEGV
  shortly after the PANIC message on stderr) instead of rc=1: the panic
  default value now flows further into an execution that no longer stops
  at the BEq sorry. Same first-crash class, louder exit mode; stdout is
  lost (block-buffered), classify by stderr line 1.
- 14 previous execute-result completers: unchanged results.

## S1 queue implied by this map (in expected unblocking order)

1. ~~`BEq core_step2` sorry (driver2 blocked filter + const-expr driver) —
   first crash for 77 files.~~ **DONE (S1a, 2026-08-19)** — see
   "Post-S1a frontier" above.
2. `ACTION_ILLTYPED Store/Load/Kill` → `Step_error2` → failwithI panic
   (12 files): action operands are values but not the expected shapes;
   likely a value-representation mismatch on the Lean side. (Behind it,
   any actual store will then need `easy_update_mem_value_aux` — the
   remaining sorry target_rep, still a certain blocker for stores.)
3. Memory access errors on struct/union/char-array tests (6 files,
   currently "completing" with wrong Killed results).
4. `CerbMem.arrayShiftPtrval` panics where OCaml reports UB (097).
5. 042-nested-loop: `illtyped SeqRMW` panic + SIGSEGV during desugar.

## Post-S3a frontier (2026-08-19, after fixing the ACTION_ILLTYPED crash class)

Root cause (S3a): **one symbol-id collision between two id streams**, not a
value-representation bug per se. Desugar mints symbols from the desugM
threaded counter (`cabs_to_ail_effect.lem` `fresh_sym_supply`, 0-based,
commit 8923d6436); translation mints its `a_NNN` temporaries from the
ambient counter (`Symbol.fresh` → `CerberusFresh.freshIntIO`, native
`lean_frontend/native/fresh_int.c`). In OCaml the ambient counter has been
advanced past every std.core symbol registration by the Core parser
(`parsers/core/core_parser.mly:184` `register_sym`, `:220` `register_label`,
one `Cerb_fresh.int()` each — ~488 for the current std.core) before the .c
unit is processed, so the two streams are disjoint. The Lean CoreParser
interns std.core symbols by name hash (`CoreParser.mkSym`) without touching
the counter, so both streams started at 0 and overlapped. Since
`symbolEqual`/`symbol_compare` (symbol.lem) ignore the description and all
Lean digests are `""`, a translation temp with the same nat as a desugar
object symbol is THE SAME key to `update_env`/`lookup_env` — a later
`Esseq`/`Elet` binding of the temp clobbered the object pointer's env
binding, and the Store/Load/Kill action then saw a loaded int (or even
`Vtrue`, 064) where `Vobject (OVpointer _)` was expected →
`ACTION_ILLTYPED` → `Step_error2` → `can_advance` failwithI panic.
The instrumented operand dump that pinned this:
`Store Vctype | Vloaded(LVspecified(OVinteger)) | ...` on all Store crashers,
plus duplicate nat 21 as both `SD_None` (translation temp) and
`SD_ObjectAddress i` (desugar) in the same arena.

Fix (at the mint, hand-written seam): `lean_frontend/native/fresh_int.c`
starts the ambient counter at `2^20`, reproducing the OCaml invariant
(ambient/translation ids strictly above the per-unit 0-based desugar range)
with a larger margin than OCaml's ~488. No .lem change; no generated-code
change. Note the OCaml invariant itself is fragile for units with more
desugar draws than the std.core offset — in OCaml the margin is ~488, here
2^20; a unit where OCaml itself collides would now show up as a differential
mismatch attributable to the OCaml side.

`./scripts/test_exec.sh` after the fix (vs the S2 baseline
`match=58 ub_match=15 mismatch=3 fail=9 crash=17`):

```
SUMMARY: total=105 match=76 ub_match=15 ub_diff=0 mismatch=3 fail=8 crash=0 timeout=0 cerb_skip=3
```

`--check-baseline` against the OLD baseline: **0 regressions, 18
improvements**; baseline regenerated, `--check-baseline` rc 0 against the
new file.

Per-file delta — the 15 in-scope ACTION_ILLTYPED crashers, all now MATCH
(Lean return value = OCaml, shown):

| file | before | after |
|---|---|---|
| 014-while-simple | LEAN_CRASH (Store) | MATCH 5 |
| 015-while-sum | LEAN_CRASH (Store) | MATCH 15 |
| 017-func-recursive | LEAN_CRASH (Load) | MATCH 120 |
| 027-for-loop | LEAN_CRASH (Store) | MATCH 15 |
| 029-continue | LEAN_CRASH (Load) | MATCH 12 |
| 039-compound-assign | LEAN_CRASH (Load) | MATCH 30 |
| 040-do-while | LEAN_CRASH (Load) | MATCH 5 |
| 045-ptr-arith | LEAN_CRASH (Kill) | MATCH 20 |
| 048-pre-post-inc | LEAN_CRASH (Kill) | MATCH 12 |
| 064-precedence-ptr | LEAN_CRASH (Load) | MATCH 30 |
| 094-bool-conversion | LEAN_CRASH (Kill) | MATCH 4 |
| 099-negative-right-shift | LEAN_CRASH (Kill) | MATCH 6 |
| 102-bool-implicit-conv | LEAN_CRASH (Kill) | MATCH 3 |
| 104-unsigned-wrap-arith | LEAN_CRASH (Kill) | MATCH 259 |
| 105-bitwise-ops | LEAN_CRASH (Store) | MATCH 270 |

Out-of-scope files moved by the same root cause (recorded, not chased):

| file | before | after |
|---|---|---|
| 042-nested-loop | LEAN_CRASH (illtyped SeqRMW + SIGSEGV) | MATCH 6 |
| 076-main-argv-access | LEAN_CRASH (illtyped SeqRMW) | MATCH 17 |
| 055-char-array-init | FAIL (Illformed_program PEarray_shift) | MATCH 90 |

(The "SeqRMW" and 055 Illformed classes were the same env-clobbering with a
different downstream symptom; both classes are now empty.)

Remaining non-MATCH population (unchanged by S3a, next queue): 8 FAIL
(025/056/058/059/072/077/078/103 — memory/func-ptr classes), 3 MISMATCH
(052-sizeof-expr, 066-cast-float, 098-cross-alloc-ptrdiff.undef DIFF),
3 CERB_SKIP (073/074 .libc, 097 OCaml-side), 0 crashes, 0 timeouts.

Latent items recorded for later slices: (a) `CoreParser` struct/union tag
symbols are minted as `Symbol "" 0 (SD_Id tag)` (CoreParser.lean:361/365/
448/452) — nat 0 can collide with desugar sym 0 if those paths are ever hit
on the exec path; (b) hash-based stdlib ids live in the full 64-bit space,
so a hash landing inside [2^20, 2^20 + #ambient draws) is theoretically
possible, exactly as a hash landing in [0, N) was before this fix.

## Post-S3b frontier (2026-08-19, struct/union memory model + ND-order fix)

S3b scope (survey findings 1-4, 17, 22): step-0 ND accumulation-order fix,
then the struct/union concrete-memory port mirroring impl_mem.ml.

**Step 0 — CerbND.runND accumulation order** (finding 22): NDnd/NDstep
results were accumulated `acc ++ branch` (R_1++...++R_n); OCaml's
exhaustive runner folds `return (z @ acc)` (smt2.ml:75-82), i.e.
R_n++...++R_1, NDstep delegating to the NDnd case (smt2.ml:134-138).
Mirrored exactly; NDbranch (`xs1 @ xs2`, smt2.ml:117-132) already
matched. The header's "constraints are trivially SAT" claim was false —
the concrete cs_module (impl_mem.ml:321-361) concretely evaluates
constraints and check_sat can report UNSAT; the missing pruning is now
recorded as an explicit divergence (finding 23), not implemented this
slice. **Baseline delta from step 0 alone: none** (every tests/minimal
program collapses to a single distinct batch verdict, so the order fix
has no observable effect on this corpus; it protects any future
multi-verdict program). Committed separately (26c05aebd).

**Main batch — three root causes fixed together:**

1. **Layout port** (findings 1-4): sizeof/alignof/offsetsof now mirror
   impl_mem.ml:98-273 — struct = offsetsofMembers fold (member padded up
   to its `align_opt`/_Alignas-overridden alignment, impl_mem.ml:112-127)
   plus trailing padding to alignof(struct); union = max member size
   padded to max member alignment; struct alignment seeded with the
   flexible-array-member's array alignment (mirrored literally incl. the
   FAM-appended-as-ordinary-member shape of offsetsof, impl_mem.ml:104-108
   — nothing in tests/minimal exercises FAMs; recorded, not corpus-driven).
   `reconstructValue` (abst, impl_mem.ml:916-1095) gained Struct
   (member-wise at offsetsof offsets, incl. OCaml's advance-addr-by-pad
   quirk) and Union arms (member selected via
   MemState.lastUsedUnionMembers at the address, defaulting to the first
   declared member — impl_mem.ml:1074-1095); it now takes
   (unionmap, addr) like abst's (~addr, unionmap). `memValueToBytes`
   (repr, impl_mem.ml:1139-1220) writes inter-member and trailing struct
   padding as unspecified bytes and pads a union's active member out to
   sizeof(union). storeM's lastUsedUnionMembers update already sat
   exactly where OCaml's do_store puts it (impl_mem.ml:1694-1701); it is
   now actually reachable (see 2/3) and is read by loads. Float sizes:
   CerberusImpl.sizeof_fty/alignof_fty are now 8/8/8, mirroring
   DefaultImpl's TODO:hack (ocaml_implementation.ml:206-212/:247-253);
   CerbMem's duplicate 4/8/16 constants (basicTypeSize + the MVfloating
   local match) are deleted — all leaf sizes route through CerberusImpl.
   isSignedIty dedup (finding 17): CerbMem.isSignedIty deleted; all call
   sites use CerberusImpl.is_signed_ity, which now mirrors
   Common.is_signed_ity (ocaml_implementation.ml:79-107, char_is_signed =
   true per :257) including routing Enum through typeof_enum (still the
   Signed Int_ stub — the registry is finding 18, S3c).

2. **Dead-code-eliminated global set (NEW ROOT CAUSE, found by the layout
   work):** Main.lean's `let _ := CerbTags.set_tagDefs runFile.tagDefs`
   (and the sibling reset) discarded the result of a PURE opaque call, so
   the Lean compiler eliminated it — the CerbTags global was EMPTY for
   the whole execution phase. Nothing noticed before S3b because the
   generated exec path threads tagDefs as a lem reader and the only
   global readers (memberShiftPtrval/offsetofIval) silently fell back to
   offset 0. Fixed by calling the BaseIO variants
   (`CerbTags.setTagDefsIO`/`resetTagDefsIO`) from Main's IO context.
   Same hazard class as the arc-1 effectful/CSE gotchas (container
   CLAUDE.md "Effectful/extern gotchas"): a discarded pure-wrapper call
   IS dead code to the compiler — mutate globals from IO via the BaseIO
   externs.

3. **Description-sensitive tag lookups:** CerbMem's tag lookups used the
   derived `BEq sym` (compares the symbol description too); OCaml keys
   Pmap on symbol_compare (digest+nat only). All CerbMem tag lookups now
   use `symbolEquality`; member-identifier lookups use `idEqual`
   (name-only, OCaml's Eq Symbol.identifier) instead of the
   location-sensitive derived BEq — offsetofIval's silent
   `integerIval 0` fallbacks are gone (OCaml failwith ⇒ panic).

`./scripts/test_exec.sh` vs the post-S3a baseline
(match=76 ub_match=15 mismatch=3 fail=8 crash=0 cerb_skip=3):

```
SUMMARY: total=105 match=82 ub_match=15 ub_diff=0 mismatch=2 fail=3 crash=0 timeout=0 cerb_skip=3
```

`--check-baseline` vs the OLD baseline: **0 regressions, 6
improvements**; baseline regenerated, rc 0 against the new file.

Per-file delta:

| file | before | after |
|---|---|---|
| 025-struct-basic | FAIL (memory access error) | MATCH |
| 052-sizeof-expr | MISMATCH | MATCH |
| 058-struct-value | FAIL (memory access error) | MATCH |
| 059-union-basic | FAIL (memory access error) | MATCH |
| 078-float-special | FAIL (memory access error) | MATCH |
| 103-union-store-load | FAIL (memory access error) | MATCH |

Remaining non-MATCH population (all pre-existing, none moved by S3b),
classified:

- 056-func-ptr FAIL (`Illformed_program: null function pointer`) —
  function-pointer byte reconstruction not ported (funptrmap; survey
  finding 20, backlog/S3c).
- 072-out-of-bounds.undef FAIL (Lean `Error: memory access error`,
  OCaml `UB_CERB002a_out_of_bound_load`) and 077-bool-trap.undef FAIL
  (Lean `Error: memory error`, OCaml `UB012_lvalue_read_trap_
  representation`) — the mem_error → UndefinedBehaviour mapping on the
  driver/batch reporting path is missing (MerrAccess/
  MerrTrapRepresentation surface as generic errors instead of UB);
  S3c material, same neighborhood as finding 12.
- 066-cast-float MISMATCH (Lean=0, OCaml=3) — CerbFloat.of_string
  (finding 5, S3c).
- 098-cross-alloc-ptrdiff.undef DIFF (Lean=1, OCaml UB048) — diffPtrval
  same-allocation checks (finding 10, S3c/backlog).
- 073/074 (.libc) + 097 CERB_SKIP — OCaml-side skips, unchanged.

Gates at S3b close: lake build green; test_unit.sh all green (purity
CLEAN, cones OK, totality CLEAN); test_parse.sh ALL; test_core.sh
104/105 (known 078 Core-text-parser red only — its EXEC differential now
MATCHes); test_exec.sh baseline OK (0 regressions).

## Post-S3c frontier (2026-08-19, seam-survey cheap batch + remaining fixables)

S3c scope (survey findings 5-7, 10, 12, 18, 20, 26, 28 + closure of 066/
098/072/077/056; decision log D9). Every fix mirrors its OCaml source with
file:line citations in-code; deliberate divergences are documented at the
divergence site.

**Fixes, by root cause:**

1. **Float parsing + truncation (findings 5-6 → 066).**
   `CerbFloat.of_string` now actually parses C floating literals
   (decimal + exponent and hex-float forms, sign, one trailing
   f/F/l/L suffix), mirroring Cerb_floating.of_string
   (util/cerb_floating.ml:8-16) → float_of_string; the old
   `toNat?.getD 0` path turned every real literal into 0.0. New
   `CerbFloat.truncToInt` mirrors zarith's `Z.of_float` bit-exactly from
   the IEEE 754 representation — truncation toward ZERO with sign
   (verified: `Z.of_float (-2.9) = -2`); `ivfromfloat`
   (impl_mem.ml:2553-2554) and `to_int` now use it (the old
   `Float.toUInt64` clamped all negatives to 0). NaN/inf panic, mirroring
   zarith's uncaught Z.Overflow. Precision limits documented in-file.

2. **Integer division/remainder (finding 7).** `opIval`
   (impl_mem.ml:2464-2490) now uses TRUNCATING division and the two
   distinct remainders, with the zarith semantics established
   empirically and cited in-code (impl_mem.ml:7-13):
   `integerDiv_t` = Z.div = Int.tdiv; `integerRem_t` = Z.rem = Int.tmod
   (sign of dividend); `integerRem_f` = Big_int_Z.mod_big_int = Int.emod
   (EUCLIDEAN — always non-negative, NOT flooring:
   `mod_big_int (-7) (-2) = 1`). Previously all three were Lean's
   ediv/emod (`-7/2`: OCaml -3, old Lean -4). Also mirrored: IntSub's
   provenance special case (impl_mem.ml:2469-2475) and IntExp's
   Prov_none (impl_mem.ml:2485-2490).

3. **max_ival/min_ival (finding 18a).** Rewritten against
   impl_mem.ml:2367-2434: Bool max = 255 (OCaml's own TODO behavior),
   Enum normalized through typeof_enum first, Char via
   is_signed_ity, the Wint_t signed-max/unsigned-min asymmetry
   mirrored as-is. **Finding 18b (enum registry) stays a stub** —
   `CerberusImpl.typeof_enum` returns Signed Int_; nothing in
   tests/minimal declares an enum with a different underlying type;
   divergence note at the stub.

4. **diff_ptrval (finding 10 → 098).** Real port of
   impl_mem.ml:1954-1984: same-Prov_some-allocation-id requirement, both
   addresses within [base, base+size] (precond), one Array layer
   stripped off diff_ty, truncating division; everything else
   MerrPtrdiff → UB048_disjoint_array_pointers_subtraction. The
   PERMISSIVE-switch branch and the Prov_symbolic iota arms are
   documented non-ports (unreachable in this pipeline).

5. **mem_error → UB fail mapping (072/077 + the whole class).** The
   concrete model's `fail` (impl_mem.ml:540-546) routes every mem_error
   through `undefinedFromMem_error` (mem_common.lem:248+, lem-shared):
   UB-classed errors kill with `Undef0 (loc, [ub])`, others with
   `Other err`. CerbMem previously built `Other` directly everywhere, so
   UB-classed memory errors surfaced as generic batch Errors. New
   `failReason`/`memFail` implement the mapping; all CerbMem fail sites
   (load/store/kill/realloc/diff/intfromptr) route through it. 072 now
   reports UB_CERB002a_out_of_bound_load, 077
   UB012_lvalue_read_trap_representation — byte-identical UB codes to
   OCaml --batch.

6. **Load/store provenance split (finding 12).** loadM/storeM
   restructured to OCaml's match shape (impl_mem.ml:1605-1666 /
   1710-1789): Prov_none → OutOfBoundPtr (the model never emits
   NoProvPtr — that constructor is gone from CerbMem); load checks
   is_dead FIRST (DeadPtr) then bounds; store has NO dead check — a
   dead/missing allocation fails via get_allocation's
   MerrOutsideLifetime (impl_mem.ml:669-675), and bounds are checked
   BEFORE readonly. is_atomic_member_access (impl_mem.ml:689-706)
   ported, including OCaml's LoadAccess-on-the-store-path quirk
   (impl_mem.ml:1777-1779, mirrored with a note). is_locking now
   selects the readonly kind from the allocation prefix
   (select_ro_kind, impl_mem.ml:1712-1718).

7. **Function pointers (finding 20 → 056).** `memValueToBytes` is now
   repr-shaped (impl_mem.ml:1139-1220): it threads the funptrmap;
   storing `PVfunction (Symbol dig n (SD_Id name))` registers
   n ↦ (dig, name) and writes the symbol's nat as the pointer bytes
   (previously 0). `reconstructValue` takes the funptrmap and rebuilds
   `PVfunction` for pointer-to-Function loads (impl_mem.ml:996-1016);
   unknown address panics like OCaml's failwith. allocateObject/storeM
   thread the map into MemState (impl_mem.ml:1336-1344, 1685-1692).
   MemState.funptrmap already existed (caseFunsymOpt read it); it is now
   actually populated.

8. **Character constants (findings 26/28).**
   `CerbDecode.decode_character_constant` applies the final wrapI into
   signed char's [-128, 127] (decode.ml:201-219; euclidean rem — so
   '\xFF' → -1). `CerbUtils.encode_character_constant` takes the low 8
   bits (`land 0xff` = euclidean mod 256, decode.ml:223-225) instead of
   the old `% 128` clamp.

`./scripts/test_exec.sh` vs the post-S3b baseline
(match=82 ub_match=15 mismatch=2 fail=3 crash=0 cerb_skip=3):

```
SUMMARY: total=105 match=84 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 timeout=0 cerb_skip=3
```

`--check-baseline` vs the OLD baseline: **0 regressions, 5
improvements**; baseline regenerated, rc 0 against the new file.

Per-file delta:

| file | before | after |
|---|---|---|
| 056-func-ptr | FAIL (Illformed: null function pointer) | MATCH 30 |
| 066-cast-float | MISMATCH (Lean=0, OCaml=3) | MATCH 3 |
| 072-out-of-bounds.undef | FAIL (generic memory access error) | UB_MATCH UB_CERB002a |
| 077-bool-trap.undef | FAIL (generic memory error) | UB_MATCH UB012 |
| 098-cross-alloc-ptrdiff.undef | DIFF (Lean=1, OCaml UB048) | UB_MATCH UB048 |

Remaining non-MATCH population: **only the 3 CERB_SKIPs** (073/074 .libc,
097 OCaml-side skip) — every Lean-side fixable on tests/minimal is closed.
Match rate 102/105 (84 value + 18 UB), 100% of comparable.

Defect-register status (survey findings): 5, 6, 7, 10, 12, 18a, 20, 26,
28 **FIXED** (with citations); 18b documented-deliberate stub (enum
registry — not corpus-forced); still OPEN (backlog, next arc): 8, 9
(eqPtrval msum / lt-le UB), 11 (read-only prefixes), 13-16 (store-order /
memcpy checks / varargs / eff arrayShift), 19, 21, 23 (constraint
pruning), 24-25, 27, 29-30.

Gates at S3c close: lake build green; test_unit.sh 4/4 (purity CLEAN,
cones OK, totality CLEAN); test_parse.sh ALL; test_core.sh 104/105
(known 078 Core-text red only); test_exec.sh baseline OK (0 regressions).
