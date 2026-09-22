# Item 7: second pre-merge audit of the tuple-arity repairs

[AGENT — independent review, 2026-09-22]

Reviewed `df85e95b7b37826dfb3f2ac97a41473580f1e0b9..b85f5bc83ed79554af3bd3bb4f4a16582917ccb5`, the five commits on `fix/match-pattern-arity`, in a separate worktree on `audit/item7-rereview-20260922`. The review covers all 21 changed files, including the eleven non-document files identified in the request. No product code, baseline, feature branch, or mainline was changed.

**Assessment:** the previous audit's R1, R2 and N1 are closed. The tuple repair has a coherent policy, the new failure-leaf classification has a defensible source invariant, and I found no new correctness regression in the reviewed changes. The requested search beyond the worker's fence confirms two P2 residuals: call typing still deletes arguments, and continuation execution itself truncates argument lists. Both are inherited defects, not regressions introduced here. The latter needs a runtime repair as well as a typing repair.

**Landing recommendation [AGENT, incorporating USER steering during this review]:** make one further closure commit for R3/R4 and N3 before landing. The operator said defects that could reasonably be rolled into this work can be proposed as fixes. These argument-list paths share the same truncating-zip failure mechanism and admit bounded checks at the existing typing/binding boundaries; rolling them into item 7 is reasonable. Keep the verified tuple repairs. This is a request to close adjacent inherited defects, not a claim that the tuple changes introduced them, and not operator approval to merge.

Independent verification: **39/39 full-battery commands passed on clean, unchanged `b85f5bc83`**; the separate three-engine report was also completed and reviewed. Focused evidence comprises 459 passing native assertions and 380 valid Core-text invocations on 38 inputs, with the individual successes, intended rejections, internal failures and timeouts retained rather than called 380 passes.

## R3 — P2, inherited: Core call typing deletes surplus arguments, including failures

The surviving unchecked zips are at `frontend/model/core_typing.lem:766` and `:1174` (`PEcall`, inference/checking), `:1696` (`Ememop`), `:1746`/`:1752` (`Eccall`, variadic/fixed branches), `:1780` (`Eproc`), and `:1855` (`Erun`). These rebuild argument lists from `List.zip` without establishing equal lengths. The alternative zip at `:1766` is commented out.

Minimal function witness, retained as `core/fun-error.core`:

```text
fun f(a: integer,b: integer): integer := a+b
proc main (): eff loaded integer :=
  pure(Specified(f(1,2,error(<<<surplus>>>,3))))
```

Recipe, using the freshly built fork and its own runtime:

```sh
_build/default/backend/driver/main.exe --runtime=_build/install/default \
  --nolibc --exec --batch --mode=exhaustive witness.core
# Compare by adding --rewrite, --typecheck-core, or both.
# Inspect the rewritten typed syntax with --typecheck-core --pp=core.
```

Derived observations from the retained subprocess streams, on **both the reviewed fork and independently built pristine Cerberus**:

| Input | Default and `--rewrite` | `--typecheck-core`, with or without `--rewrite` |
|---|---|---|
| `fun-error.core` | `Error {msg: "surplus"}`, exit 1 | `Specified(3)`, exit 0 |
| `proc-error.core`, analogous `pcall` | `Error {msg: "surplus"}`, exit 1 | `Specified(3)`, exit 0 |
| `adjacent-core/memop-error.core`, `PtrEq` with a surplus erroring operand | `Error {msg: "surplus"}`, exit 1 | `Specified(1)`, exit 0 |

Each typed dump removes the erroring argument. These are actual executable failure-to-success changes, not just acceptance of an unused ill-typed declaration. Fitting controls preserve their results. Too few arguments are accepted too: the direct Lean probe gives a one-formal function/procedure/continuation zero actual arguments, and each checker returns a successful result with zero arguments. Its one/two/three-actual controls retain one argument, exposing the truncation in the actual generated Lean typing definitions.

`Eccall` is independently covered by Core text as well. A fixed-arity one-parameter function-pointer type accepts zero parameters; a surplus `error` operand disappears from the typed dump. The chosen function pointer is null, so the typed execution subsequently fails with the existing null-function-pointer internal error, exit 125. This is **not** claimed as another successful execution. Its useful evidence is the acceptance/deletion and the change from the explicit surplus error to the null-pointer failure. The variadic branch is a source finding, not a tested variadic call witness; its repair must account for the extra variadic bundle explicitly.

The branch already records most of this class in `TODO.md:367–370`. This review confirms the defect and supplies concrete error-suppression witnesses; it does not relabel the known deferral as a newly introduced regression. Under the operator's broadened closure scope, I propose repairing these sites in this branch rather than retaining that deferral. `Ememop` should be named explicitly in the residual inventory rather than hidden under function/procedure call terminology.

**Required repair:** check the applicable argument count before zipping in both inference and checking, preserve all arguments on a fitting input, reject shortages as well as surpluses, and cover fixed/variadic calling conventions separately. Merely evaluating discarded arguments would still accept malformed programs. No C-elaborator-produced counterexample is claimed here; the supported Core input boundary is sufficient to reproduce the problem.

## R4 — P2, inherited: continuation execution silently truncates, even without Core typing

The driver's live execution path in `frontend/model/core_reduction.lem:1468–1473` folds over `List.zip sym_bTys pes` and evaluates only the zipped prefix. A surplus operand is never evaluated. The second engine has the same unchecked binding zip at `frontend/model/core_run.lem:1563–1565`, where it constructs substitutions for the continuation body. R3's optional typechecker cannot protect default execution, and is itself permissive.

Surplus witness (`core/run-fixed-error.core`):

```text
proc main (): eff loaded integer :=
  save loop: loaded integer (i: integer := 1) in
    if i < 2 then run loop(2,error(<<<surplus>>>,3))
    else pure(Specified(i))
```

Shortage witness (`adjacent-core/run-short-stale.core`):

```text
proc main (): eff loaded integer :=
  save loop: loaded integer (i: integer := 0, j: integer := 10) in
    if i < 1 then run loop(1) else pure(Specified(i+j))
```

On **both fork and pristine CLI engines**, in default, rewritten, typed and typed-rewritten modes, the surplus witness returns `Specified(2)` and the shortage witness returns `Specified(11)`, exit 0. The surplus error is skipped; the missing `j` argument leaves its old value in the environment. A fitting `run loop(1,20)` control returns `Specified(21)`. The second-engine statement above is established by source inspection, not by claiming these CLI runs select `Core_run`.

This is stronger than the record's current “surplus arguments dropped from the typed program” residual: truncation happens during execution on the default path too. It does **not** disprove the new `tuple_arity_error` reachability classification. `Erun` binds `CaseBase` symbol patterns, so the tuple-pattern failure leaf is not involved even when a parameter's declared value type is a tuple.

**Required repair:** guard continuation argument counts in both execution engines, before evaluation/substitution, and in the typechecker. Include both directions, a failure-bearing surplus argument, a shortage that would otherwise reuse an old binding, and a fitting control. Include these runtime sites in the proposed closure commit; a typing-only repair would leave this defect intact.

## Proposed closure commit and acceptance checks

[AGENT proposal; USER 2026-09-22: “if we find defects which could reasonably get rolled into this, we can propose them as fixes”]

1. Guard both `PEcall` typing arms and the `Eproc`, `Ememop`, `Erun` and fixed-arity `Eccall` arms before their zips. Reuse structured typing failures. For variadic `Eccall`, split the trailing variadic bundle, require exactly the fixed formal count in the prefix, zip that prefix, and typecheck the bundle separately. Do not apply a naive fixed-arity check to the complete variadic list.
2. Guard the `Erun` argument list against the resolved continuation signature in **both** execution engines, before evaluation/substitution. Use the existing monadic ill-formed-program channel, consistently with the let-form repair. Checking only Core typing would not protect ordinary execution.
3. Make the retained error-bearing and shortage witnesses regression cases: both length directions, zero-argument boundaries, fitting arguments preserved, and fixed/variadic controls. Check default, rewrite, typed and typed-rewritten CLI paths where supported; directly exercise the second engine as well as the actual driver engine. Retain typed dumps or structural preservation checks so a test cannot pass after silently dropping operands.
4. Recompute the affected source/generated drift pins from the complete source, recheck proof obligations and the failure census, update the record/tray/backlog to the actual scope, and run the required frozen validation before a delta review. Do not assume these changes need new pure failure leaves or new unit executables.

The proposed scope is argument-list arity in these existing Core operations. It does not require a new type system, a general type-soundness theorem, or changes to selector fall-through.

## N3 — P3: one unqualified typing assurance survived the corrections

The record's §2 correctly limits the result to tuple patterns/expressions and tuple-producing `unseq`/`par`. But the consumer note in §7, `2026-09-20_match-pattern-arity-record.md:274–275`, still says that “a `.core` input with a mismatched arity now fails Core typing on both fork engines.” R3 supplies direct counterexamples. Replace that sentence with an exact account of the enforced tuple and argument-list checks after the closure; update the old deferral to reflect the final implementation, including R4.

One small stale proof comment remains at `Core_aux_lemMeasureProofs.lean:467–471`: it describes `subst_pattern`'s mismatch branches as `tuple_arity_error` after round 2 changed them to `Nothing`/a failed fit check. Correct the comment when updating the assurance text. The proof compiles with its original statement; this is not a proof defect.

## Closure of the previous findings and design assessment

The previous audit is `docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit.md`. Its enum findings are outside this delta review except where the rebase could disturb their integration.

| Previous finding | Independent result at the reviewed head |
|---|---|
| R1: tuple-expression typing drops operands | **Closed.** The tuple-pattern, tuple-expression, `Eunseq` and `Epar` checks guard both arity directions before rebuilding. Nested mismatches reject; fitting controls preserve operands. The old pure-let and weak/strong unsequenced reproducers reject under Core typing, including error-bearing variants. |
| R2: runtime/rewrite binding disagreement and unguarded helpers | **Closed.** Both engines' let forms fit-check before environment updates. `subst_pattern` declines on a mismatch, including nested tuples inside lists, leaving the runtime binding to report `Illformed_program`. The other tuple-binding helpers guard their zips and retain the loud backstop. |
| N1: incorrect axiom sets and executable count | **Closed.** The facts' printed axiom sets agree with the pins: `propext` for T1a/T1b/T2/T3/T3_select/T4_neg; the standard trio for T1_anyFuel. The final message and tray now distinguish them. After the enum rebase, fourteen executables are actually registered and run. |
| Wrong engine citation in the previous audit | **Erratum accepted.** `drive_core_thread2` steps through `Core_reduction.core_step2 → step_ctx → one_step`. My earlier `Core_run` citation identified the second engine, not the CLI's actual path. The repair covers both. |

The interfaces appropriately express different decisions: the matcher returns no match and `select_case` tries the next arm; static typing rejects an incompatible tuple; the expression rewriter declines a substitution it cannot perform; an executing let-binding reports an ill-formed program. These are compatible parts of one binding policy. Making the selector itself report a runtime error would break its intended fall-through semantics.

The repair preserves equal-length traversal and binding order. A nested mismatch cannot leak a partially successful matcher result. The six `Core_reduction.one_step` let routes are all covered: value/non-value `Elet`, plain/annotated `Ewseq`, and plain/annotated `Esseq`. The audit's native test exercises all six with both mismatch directions and a fitting control, including a stub evaluator that actually returns the value on the non-value `Elet` path. The branch's own unit suite also executes the actual `Core_run` Elet and `Core_eval` PElet routes.

“Default equals rewrite” is an **outcome-kind claim**, not byte identity of all diagnostics. For example, ordinary `Elet` and rewritten `PElet` name their respective forms in the ill-formed-program message. Both reject with exit 1; the failure-versus-success discrepancy from the first audit is gone. The weak/strong counterexamples also agree on the intended error kind after round 2.

The five affected measure-proof statements are unchanged. Their added case splits discharge the new nonrecursive guard branches and retain the previous recursive traversal proofs. The new unit facts are concrete kernel-checked equations/negative controls; the typing tests execute generated `partial` definitions. Neither constitutes a general type-soundness theorem, nor a proof of the failure register's call-path invariant.

## The new failure-leaf invariant

`scripts/failure_reach_register.txt:149` classifies the one shared leaf as `UNREACHABLE-BY-INVARIANT`, under “fit-check before bind.” The register explicitly allows a named, cited, reviewed source invariant; its reach classes are not kernel theorems. I checked the live callers and the recursive transitions, not merely the new row's text:

| Helper / caller | Why this tuple-arity leaf is excluded |
|---|---|
| `subst_pattern → subst_pattern_val`, tuple/list value arms | The whole value and pattern pass recursive `match_pattern` first. Success establishes equal tuple lengths at every nested component. |
| `subst_pattern`, tuple expression arm | Checks length, then combines recursive optional substitutions; any nested mismatch returns `Nothing`. It does not use the loud tuple leaf. |
| `subst_pattern → subst_pattern_val`, specified/unspecified value arms | Passes `Vobject`/`Vctype`, which cannot select the tuple-value branch. This is a shape argument, not a preceding match. |
| `unsafe_subst_pattern` and its recursive/value-helper calls | Its only uncommented external callers in `remove_skips` pass `mk_unit_pe`. A unit operand cannot reach a tuple-value/tuple-expression arm. Moreover, `remove_skips` is absent from the current live `rewrite_expr` pipeline (`flatten_seqs` followed by `pure_propagation2`; `utils.lem:4` defines the composition order). |
| `update_env_aux ← update_env`, let forms | Three sites in `Core_run` and six in `Core_reduction` now fit-check the complete pattern first. |
| `update_env`, save/run symbol binding | Uses `mk_sym_pat`, hence `CaseBase`, never a tuple pattern. R4 remains a defect in the argument-list zip, but not a route to this leaf. |

The excluded `unsafe_subst_pattern` calls at `core_rewrite.lem:1173` and `:1205` really are in comments. The current substitutions beside them call `subst_pattern`. Recursive descent preserves the relevant shape/fit facts. Direct public helper calls on malformed tuples can reach the backstop—as the unit equations deliberately show—but that does not contradict a classification about the reviewed executable entry paths.

Other nearby zips were not treated as defects merely for being zips. `to_pure`'s `Ecase` recombines patterns with a length-preserving traversal of expressions unzipped from the same pairs; `Esave`'s value list is obtained from the same initializer list. The `equalInferred` tuple zip in `core_typing_aux.lem` was inspected, but this review establishes no live counterexample through it and reports no additional finding on that basis.

## Rebase and evidence integrity

The reviewed five commits are `373a057ea`, `60e1d192f`, `6f02b42de`, `8d4901c65`, and `b85f5bc83`. Against the post-enum base, the failure register adds exactly the tuple leaf (238 → 239); old data rows are preserved. The unit list and Lake file contain both `enum-data-test` and `match-pattern-arity-test`. The enum reader arguments are present in the new runtime unit calls.

Independent regeneration and rebuilding used the combined sources, not either side's cached hashes. The fork-drift gate validates 82 surface files and 29 pinned deltas, including the combined `core_typing` source and generated delta. Lem remains at `38f87d5`. The record is accurate that the matcher source was not changed by the enum arc, whereas the typing delta had to be recomputed from both changes.

The record reports an aborted first replay caused by placing a manifest row inside a header comment, then a replay with anchored placement and gates. That explanation is plausible and is presented as worker-reported history; this audit certifies the final manifest against freshly generated artifacts, not the worker's discarded replay.

The committed worker report at `2026-09-22_match-pattern-arity-closure-evidence/rebased-df85e95b7/report.json` has 39 successful lanes and identical source, external-input and recorded-artifact identities before/after. Its frozen source was **not a clean `b85f5bc83` checkout**: it records head `8d4901c65` with the new unit's enum-reader arguments and documentation changes still uncommitted. That is consistent with the final record-update commit. “Frozen” is accurate; “clean head” would not be. The independent run below starts from clean `b85f5bc83`, removing this ambiguity for the reviewed head.

## Independent validation and retained evidence

[AGENT] Advance justification for the approximately 85–90-minute full sweep was written before launch: it is the repository-required differential corpus and harness failure-injection battery, not proof-search grind. The review waited for the other heavy battery to finish before rebuilding/launching; regeneration and the build used `scripts/ce`, `DUNE_CACHE=disabled`, a forced Dune build and `scripts/capped` with a 32 GiB limit. Focused Lean builds used 8 GiB. Pristine Cerberus was independently built in the audit worktree from `b9aeedcb4` using upstream Lem `3802cb0`.

The full run completed from 20:36:14 to 22:05:17 UTC (derived wall time: **89.0 minutes**). Its summary, verbatim:

```text
full: passed; 39/39 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Source identity is equal before/after, with clean status and the reviewed head. External-input inventories and all **1,778 recorded artifact entries** are also equal before/after. Derived highlights from the retained receipts:

| Check | Independent result |
|---|---|
| Unit executables | 14 passed, zero failed; both enum and arity executables present |
| Fuel forms | 81 workers: 62 measured, 13 absorbing, zero reachable ambient, six ambient outside the drive cone |
| Failure reach | 239 rows: 170 unreachable by reviewed invariant, 48 reachable, 21 unknown; zero discardable |
| Fork drift | 82 surface files, 29 pinned generated deltas; Lem pin `38f87d5` matches |
| GCC oracle | 2,014 programs: 1,917 agreements, 12 triaged, 85 skipped; zero regressions and zero improvements against its baseline |
| Observation harness | 93/93 plants passed |
| Pristine corpus | 835 semantic agreements, 28 matching failures, seven reviewed differences, two interface agreements |
| Pristine plant lane | 51 plant-ok, one plant-rejected, one semantic agreement |
| Pristine libxml2 chvalid | Four semantic agreements |

All 39 lane processes exited 0; this does not mean that every individual corpus input is a successful C execution. The recorded classifications above preserve that distinction.

The separate C5 three-engine report covers 872 rows. The fork/pristine counts remain 835/28/7/2. Its **non-gating Lean column** has 830 agreements, 28 differences, 12 both-undecodable rows and two not-applicable rows. The same 40 nonmatching IDs have the same classes as the previously committed independent run-digest audit (`97c98bcce`, reviewed head `24f19d6f5`); the reference identity and comparison are retained. This is a historical cross-feature comparison, not a new A/B run on the exact item-7 base, and is not a claim that all three engines agree. C5 records clean `b85f5bc83` and unchanged source.

The focused native package imports the actual rebuilt generated modules and contains four extra kernel facts for a tuple nested in a list, nested substitution refusal, and actual `select_case subst_sym_expr` fall-through. Their printed sets are `propext` for the matcher fact and the standard trio for the other three. Native assertions cover the 0–6 arity grid (matcher, tuple pattern/expression/value typing, unsequenced/parallel typing, value/expression/nested substitution) and all six reduction routes. The call-count diagnostics are recorded as defect observations, not successful correctness assertions.

The Core collector retains 380 valid executions, **not 380 passing tests**: derived statuses are 221 exit-0, 111 exit-1, 40 exit-125, and eight bounded timeouts. These include expected rejection/internal-error controls and the newly demonstrated inherited defects. Four initial continuation inputs used invalid reviewer syntax (`==`); their 40 parser-error invocations are preserved but excluded from the 380. The corrected inputs use `<`. Early Lean-probe compile errors and an initially wrong expectation for empty `unseq` are also retained; the corrected final probe built and its 459 assertions passed. None of these instrument-authoring corrections altered the product.

The committed evidence directory is `2026-09-22_match-pattern-arity-rereview-evidence/`. Its README gives reproduction and extraction instructions. It contains the release report and raw lane receipts, pristine/three-engine reports and raw captures, focused source/commands/streams, source hashes, worker-report analysis, and a standalone integrity verifier. All tallies in this audit that summarize captures are derived; quoted runner lines are kept verbatim. The full runner's `release_certification` field remains `incomplete: reporting/adoption/audit exits require separate evidence`; a green 39-lane run alone is not permission to merge or completion of consumer adoption.
