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

## S1 queue implied by this map (in expected unblocking order)

1. `BEq core_step2` sorry (driver2 blocked filter + const-expr driver) —
   first crash for 77 files.
2. `ACTION_ILLTYPED Store/Load/Kill` → `Step_error2` → failwithI panic
   (12 files): action operands are values but not the expected shapes;
   likely a value-representation mismatch on the Lean side. (Behind it,
   any actual store will then need `easy_update_mem_value_aux` — the
   remaining sorry target_rep, still a certain blocker for stores.)
3. Memory access errors on struct/union/char-array tests (6 files,
   currently "completing" with wrong Killed results).
4. `CerbMem.arrayShiftPtrval` panics where OCaml reports UB (097).
5. 042-nested-loop: `illtyped SeqRMW` panic + SIGSEGV during desugar.
