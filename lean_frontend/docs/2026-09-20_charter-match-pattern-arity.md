# Charter — `match_pattern` fails closed on tuple-arity mismatch (cerberus-sl hidden-state note item 7) (2026-09-20)

**Status:** CHARTER for one Claude Fable subagent worker, written by the orchestrator [AGENT]; branch `fix/match-pattern-arity` in the primed worktree `worktrees/cerberus-lean-fix/match-pattern-arity` (base: mainline `5407597d9`). A small shared-model slice requested by the consumer and endorsed by the operator on the consumer's side ([USER 2026-09-20, cerberus-sl `docs/2026-09-20_run-digest-design-response.md` §4 Q5]: *"we can ask for this immediately"* — "we request that the item 7 work be STARTED NOW, not queued behind this arc"). It runs in parallel with the program-data-parameters arc; the files are disjoint from E-A's.

## 0. Rulings (verbatim), the contract, standing constraints

- The consumer's contract, verbatim (`cerberus-sl/docs/2026-09-18_hidden-state-upstream-note.md` item 7): *"on an arity mismatch `match_pattern` returns NO MATCH (`Nothing`), not an error, so that `select_case` CONTINUES to later arms (a wildcard arm after a mismatching tuple pattern is selected), and a successful match keeps the calculus's bindings and their order. Acceptance criterion: the selector equality `select_case subst_sym_expr v pats = selectCaseE v pats` for every `v` and `pats` (`core_run.lem`), or a primitive matcher equality from which it follows — and the same for the pure evaluator's `select_case subst_sym_pexpr`/`selectCaseP`. A structured-error semantics would NOT discharge the downstream statement."* The selector equality is THEIR theorem against THEIR calculus; what we deliver is the matcher's fail-closed arity behaviour with bindings and order unchanged, stated as kernel-checked facts they can consume (§2 T1–T3).
- The category: a fail-open default in the shared model (Lem's truncating `zip`), unobservable on elaborator output, wrong as such — the same "unambiguously wrong" class the operator ruled fixable ahead of upstream for the allocator ([USER 2026-09-16]: *"I think this is in the 'unambiguously wrong' category where we are allowed to fix ahead of upstream"*), with the same discipline: shared body (both targets compute it), an upstream-tray draft, the pristine-oracle register only if a lane OBSERVES a difference (none should — §1).
- Standing constraints: NEVER modify machine-global state; NO `git push`; never commit on `mdd/cerberus-lean`/`master`; no merge/rebase; fail-closed/fail-noisy (no `2>/dev/null` on a build/gate step); [AGENT]/[USER] provenance; verbatim outputs, derived tallies labelled; every `lake`/`lean` through `scripts/capped`, gate scripts through `scripts/ce`; ONE heavy job (the program-data-parameters worker may be running a Tier B battery in its own worktree — check `ps`/load before your heavy steps and wait if two heavy jobs would overlap); ~45-minute step tripwire (full rebuilds excepted to ~1 h, wall times reported); never end the turn on a wait; a committed record ENDS the slice. [USER 2026-09-08] verbatim: *"we should \*NOT\* be building anything new out-of-policy"* — the kernel facts below are the consumer's named acceptance facts, not new surface.

## 1. Facts (verified by the orchestrator at `5407597d9`; cite, do not re-derive; errata to the record)

- **The matcher** `frontend/model/core_aux.lem:2019-2050` `match_pattern (Pattern _ pat) cval`: the tuple arm `:2033-2039` — `(CaseCtor Ctuple pats', Vtuple cvals') -> List.foldr (…) (Just []) (List.zip pats' cvals')` — zips with Lem's truncating `zip` (`lem-lean/library/list.lem:987-992`: `| _ -> []` on unequal tails), so a pattern of arity 2 matches a value of arity 3 (binding the first two) and a pattern of arity 3 matches a value of arity 2. Every other arm is exact (`Cspecified`/`Cunspecified` one sub-pattern, `Cnil`, `Ccons` two, `CaseBase`). The fall-through `| _ -> Nothing` `:2048-2049`. `match_pattern` is fuel'd and MEASURED (`:2572-2573`: `declare {lean} fuel val match_pattern = \`fuelExhausted none\``, `fuel_measure … = \`lemSize g\``); its sufficiency proof is in `lean_frontend/Core_aux_lemMeasureProofs.lean` (a length guard changes the worker's body — the proof is re-established, statement unchanged).
- **The selector** `core_aux.lem:2053-2064` `select_case subst_sym cval pat_pes`: `Nothing` from the matcher → *"trying the next branch"*; `Just sym_cvals` → `List.foldr (fun (sym, cval') acc -> subst_sym sym cval' acc) pe sym_cvals`. Users: `core_run.lem:820` (`select_case subst_sym_expr cval pat_es`), `core_eval.lem:738,1010` (`Caux.select_case Caux.subst_sym_pexpr …`). Bindings and their ORDER are the matcher's `x++xs` right fold — unchanged by the fix.
- **Upstream's own precedent inside the same model:** `core_rewrite.lem:1287-1300` `simpl_match_pattern` ALREADY guards its two tuple arms — `if List.length pats' <> List.length cvals then Nothing else …` and `if List.length pats' <> List.length pes' then Nothing else …` — the exact shape to mirror in `match_pattern`.
- **Why it is unobservable on elaborator output, and where the typechecker is ALSO fail-open:** the Core typechecker's tuple-pattern rule `core_typing.lem:182-186` — `(Ctuple, BTy_tuple bTys, _) -> … E.mapM (fun (bTy, pat) -> typecheck_pattern bTy pat) (List.zip bTys pats)` — zips TRUNCATINGLY too, so a `.core` input whose `case` pattern has the wrong tuple arity is NOT rejected by typing; only the elaborator's discipline (it builds patterns from the types it just produced) keeps mismatches out of compiled programs. Every lane corpus is elaborator output or upstream-derived Core text of typed programs, so the pristine lane sees no difference — but the claim "well-typed programs never mismatch" rests on the elaborator, not on `typecheck_pattern`. This charter fixes BOTH (§2 D1, D2): the matcher (the consumer's ask) and the typechecker's rule (`MismatchExpected` on unequal lengths — the same fail-closed class; a `.core` input with a mismatched arity then fails typing on both fork engines where pristine accepts it: a `shared-model-fix` register row IF a lane case exists — none does today; a new Core-text fixture is NOT added by this slice, see §3).
- **Post-match substitution** `core_aux.lem:1123-1145` `subst_pattern_val` (tuple arm `:1141-1143` zips) and its pexpr twin run only AFTER a successful match; once the matcher is fail-closed their zip sees equal lengths on every reachable call — state this in the record, do not change them.
- **The consumer's use today:** `SelectAgreesC` (their `INTERFACE.md` disclosure 22), a `sorry` in their `Spikes` (`selectAgrees_pin`), conditions six of their seven ladder rungs; their calculus's selector `selectCaseE`/`selectCaseP` implements exactly the fail-closed arity behaviour. They want ONE re-pin covering E-A, the run-digest slice and this (their §4 Q4).
- **Tray:** next number 45 (`lean_frontend/docs/upstream-tray/INDEX.md`); the allocator draft 44 is the format model.

## 2. Deliverables

**D1 — The matcher, shared body.** `core_aux.lem:2033-2039`: mirror `core_rewrite.lem:1287-1290` — `| (CaseCtor Ctuple pats', Vtuple cvals') -> if List.length pats' <> List.length cvals' then Nothing else List.foldr (…) (Just []) (List.zip pats' cvals')`. Nothing else in the arm; bindings and order untouched. A comment cites item 7, `core_rewrite.lem:1287-1290`, and Lem's `zip`.

**D2 — The typechecker's rule, shared body.** `core_typing.lem:182-186`: `if List.length bTys <> List.length pats then E.fail loc (MismatchExpected "Ctuple" expected_bTy "tuple of matching arity")` (or the existing constructor with a wording that names the arity — keep the error TYPE; the text is the "failure text" discrepancy class) `else` the present body. Check `infer_pattern`'s `Ctuple` arm (`:55-59`) needs nothing (it infers from the pattern alone).

**D3 — Kernel facts for the consumer (a unit test `test/Unit/MatchPatternArityTest.lean`, `[[lean_exe]] match-pattern-arity-test`, listed in `scripts/test_unit.sh`):** T1 `match_pattern (Pattern [] (CaseCtor Ctuple [p1, p2])) (Vtuple [v1, v2, v3]) = none` and the arity-3-pattern/arity-2-value twin, by `rfl`/`decide` on concrete patterns (with the fuel wrapper — cite how the MEASURED wrapper is applied); T2 the selector continues: `select_case subst (Vtuple [v1,v2,v3]) [(tuple-2 pattern, e1), (wildcard, e2)] = some e2` by `rfl`; T3 bindings and order on a successful arity-2 match equal today's (`some [(s1,v1),(s2,v2)]`), by `rfl`; T4 a NEGATIVE control by `#guard_msgs` or a pinned pre-fix evaluation in the record: the pre-fix matcher on T1's inputs returned `some [(s1,v1),(s2,v2)]` (state it as the record's pre-fix quote, not as a compiled decoy). Also a typing pin: `typecheck_pattern` on a mismatched `Ctuple` pattern fails (T5), if it is unit-testable without the monad's environment; else a probe in the record.

**D4 — Proof and gates.** `Core_aux_lemMeasureProofs.lean`: re-establish `match_pattern_measure_sufficient` (statement unchanged; the new guard is a non-recursive branch, the induction is the same); `check_fuel_forms.sh` population unchanged (81/62/13/0/6); `failure_reach_register.txt`: no new failure leaf (both fixes return `Nothing`/`E.fail`, not `failwithI`) — confirm the gate is unchanged; `fork_drift_manifest.txt`: generated `core_aux.ml` and `core_typing.ml` move — layer-2 rows re-pinned as single rows + one dated NOTE (never `--refresh`); if `core_aux.ml`/`core_typing.ml` are today byte-identical to upstream's generated tree, they become NEW `[expected-semantic]` rows. Tier A rows 1–12 incl. 4b/4c/6b: zero movement; Tier B row 10 (pristine): `passed; {'semantic_agreement': 829, 'matching_failure': 28, 'reviewed_difference': 3, 'interface_agreement': 2}` unchanged (829 = 822 + the seven E-A witnesses IF E-A has landed by then; else 822 — state which head you are on) — a `difference` here would mean a corpus case has a mismatched pattern: a FINDING, stop rule S2; also rows 4, 5, 6, 7, 8, 9, 12 of Tier B.

**D5 — The upstream-tray draft 45** `lean_frontend/docs/upstream-tray/45-core-match-pattern-truncating-zip-arity.md` + INDEX row: `match_pattern` and `typecheck_pattern` zip tuple patterns with Lem's truncating `zip` (cites: `core_aux.lem:2033-2039`, `core_typing.lem:182-186`, `list.lem:987-992`; upstream's own `simpl_match_pattern` guards, `core_rewrite.lem:1287-1300`); a `.core` witness text in the draft (a `case` on a triple with a pair pattern followed by a wildcard: pristine selects the pair arm binding a prefix; fixed selects the wildcard — and, with D2, pristine typechecks it while the fixed model rejects it), with the ISO-independence note (this is Core, the elaborator never emits it); the fix as proposed upstream.

**D6 — Record** `lean_frontend/docs/2026-09-20_match-pattern-arity-record.md`: the finding (both fail-open zips), the two fixes, T1–T5 verbatim, the pre-fix quote, the gate tails verbatim, the manifest rows, the consumer note (what `SelectAgreesC`'s discharge can now rest on: the matcher returns `none` on arity mismatch and the selector's fall-through is `:2058-2061`'s unchanged code — their selector equality is theirs to prove; our facts T1–T3 are its matcher-level premises), TODO.md/tray INDEX updates. **Commit ONCE**, quote the head, STOP and report.

## 3. Fence, forbidden, stop rules

**Fence:** `frontend/model/core_aux.lem` (the tuple arm of `match_pattern` only), `frontend/model/core_typing.lem` (the `Ctuple` arm of `typecheck_pattern` only), `lean_frontend/Core_aux_lemMeasureProofs.lean` (the one proof), `lean_frontend/test/Unit/MatchPatternArityTest.lean` (new) + `lakefile.toml` (`[[lean_exe]]`) + `scripts/test_unit.sh` (the list), `scripts/fork_drift_manifest.txt` (single rows + NOTE), the tray draft + INDEX, the record, `lean_frontend/TODO.md`. **Forbidden:** `subst_pattern_val`/`_pexpr` and every other zip site; `core_rewrite.lem` (already fail-closed); the selector `select_case`; any baseline/expectation/fixture (movement is a finding, S2); `scripts/upstream_oracle_differences.json` (no lane observes the fix — if one does, that is S2, not a register row you add); lem-lean; the pin files; `.gitignore`; new Core-text fixtures or lanes (out of policy for this slice — the tray draft carries the witness TEXT); `2>/dev/null` on builds/gates; mainline commits; `git push`; uncapped Lean; two heavy jobs.

**Stop rules:** **S1** the measure proof does not re-establish with the statement unchanged (report the goal); **S2** ANY lane movement or a pristine-lane `difference`; **S3** a step past ~45 minutes (full rebuilds / Tier B excepted to ~1 h, reported); **S4** a rule conflict; **S5** the E-A worker's Tier B is running when you need a heavy step — wait for it, do not overlap (check with `ps -ef | grep -c "lake\|release.py"` and the load; report the wait).

## 4. Gates

`scripts/ce make prelude-src lean-prelude-src` (lem 38f87d5); `build_cerberus` + `build_lean` (every root) + speclab; Tier A rows 1–12 incl. 4b/4c/6b, tails verbatim (`check_fuel_forms: OK (81 …)`, `check_failure_reach: OK (… unchanged …)`, `check_fork_drift: OK … lem-pin 38f87d5 = lem -v`, `Total: 14 passed` with the new exe); Tier B rows 4, 5, 6, 7, 8, 9, 10, 12 (`release.py --mode full` is fine if the box is free; else the rows individually); `match-pattern-arity-test` green; `#print axioms` on T1–T3 = the trio or fewer; `git status` clean after the commit.

## 5. Record and reporting

The report to the orchestrator: the head hash; the two lem hunks verbatim; T1–T5 output verbatim; the pre-fix quote; every Tier A/B tail; the manifest rows; whether `core_aux.ml`/`core_typing.ml` were upstream-identical before; deviations. Then stop.

## Errata (2026-09-22, after the pre-merge audit `2026-09-21_enum-repairs-and-match-pattern-arity-audit.md`; [AGENT orchestrator rulings R1/R2/N1])

- **§1, the post-match premise, FALSE.** "`subst_pattern_val` (tuple arm `:1141-1143`) and its pexpr twin
  run only AFTER a successful match; once the matcher is fail-closed their zip sees equal lengths on
  every reachable call" — wrong on two counts: there is no `subst_pattern_pexpr`, and the helpers are
  reached WITHOUT a prior `match_pattern` (`to_pure → subst_pattern`, `core_aux.lem:1536-1546`;
  `pure_propagation2 → subst_pattern`, `core_rewrite.lem:1187-1193, 1219-1225`; `subst_pattern`/
  `unsafe_subst_pattern → subst_pattern_val`; and `Core_run`/`Core_reduction`'s `Elet`/`Ewseq`/`Esseq` →
  `update_env`, never the matcher). The audit's `ArityAudit.lean` kernel-checked the counterexample.
  Consequence: §3's "Forbidden: `subst_pattern_val`/`_pexpr` and every other zip site" was the wrong
  fence — lifted by the closure-round rulings (R2), which guard every tuple-binding path.
- **§1 "Why it is unobservable … fixes BOTH", INCOMPLETE.** The typechecker's tuple-EXPRESSION arms
  (`core_typing.lem:884-887`, `Eunseq :1786-1795`, `Epar :1853`) also zip truncatingly — and DELETE the
  surplus operands from the typed program (audit R1). D2 covered the pattern rule only; the record's
  claim "a `.core` input with a mismatched arity now fails typing" was over-broad until the closure
  round (R1).
- **§0 "the files are disjoint from E-A's", FALSE.** The audit's `git merge-tree` against
  `arc/program-data-parameters` reports conflicts in `lakefile.toml`, `scripts/test_unit.sh` and
  `scripts/fork_drift_manifest.txt`, and textual overlap in `core_typing.lem` and
  `Core_aux_lemMeasureProofs.lean`. Integration: rebase onto the mainline after the enum arc lands, keep
  both unit registrations, recompute the typing module's content/delta pins from the COMBINED source
  (never pick either branch's hash) — not in this round.
- **§2 D3/§4 "Total: 14 passed"**: 13 on this branch (the 14th exe is the enum arc's).

## Addendum A3 — closure round 3 (2026-09-23): argument-list arity

**Provenance.**
- [USER 2026-09-23], verbatim: *"Yes, we will roll R3 / R4 into this as a closure. The digest fix landed on main"*.
- [USER via auditor, 2026-09-22], verbatim: *"if we find defects which could reasonably get rolled into this, we can propose them as fixes"*.
- [AGENT 2026-09-23, orchestrator]: scope, fence, acceptance and stop conditions below; the second-round audit is
  `docs/2026-09-22_match-pattern-arity-rereview.md` (commit `3e8f7c4bd`, R3/R4/N3).
- The standing ban, verbatim: [USER 2026-09-08] *"we should \*NOT\* be building anything new out-of-policy"* — no new
  gates, no new `lean_exe` (extend `match-pattern-arity-test`), no general type-soundness theorem, no new
  enumeration/literal/semantics-evaluation program proofs; [USER 2026-09-04] *"we don't change the lem structure for
  ocaml"*.

**Scope (verified by the orchestrator from source at `b85f5bc83`).**
- **R3** — the seven unchecked argument-list zips in `frontend/model/core_typing.lem`: `PEcall` inference `:766` and
  checking `:1174`; `Ememop` `:1696`; `Eccall` fixed `:1752` and variadic `:1746`; `Eproc` `:1780`; `Erun` `:1855`. Guard
  the count BEFORE zipping, both directions (shortage AND surplus rejected), through the EXISTING structured failure —
  prefer `MismatchExpected <syntax-info> <expected bTy or the ctor-name convention used at :190> "<found>"` exactly as
  the R1 `Ctuple` guard does; do NOT add a `core_typing_cause` constructor (an OCaml-visible type) — if one seems
  unavoidable, STOP and ask. Fitting inputs must preserve every argument (pin the typed `--typecheck-core --pp=core`
  dump of each fitting control byte-identically to the untyped structure, or an equivalent structural count assertion —
  a test must not be able to pass after silently dropping an operand). Variadic `Eccall` (`:1740-1750`): split the
  trailing variadic bundle first, require exactly |params| fixed actuals in the prefix, zip that prefix, typecheck the
  bundle separately — never a naive length check on the complete list. Name `Ememop` explicitly in the residual
  inventory / record.
- **R4** — `Erun` argument-count guard in BOTH execution engines before evaluation/substitution:
  `frontend/model/core_reduction.lem:1468-1473` (the driver's engine, the `E.foldlM … (List.zip sym_bTys pes)`) and
  `frontend/model/core_run.lem:1563-1565` (the `List.foldl … unsafe_subst_sym_expr … (List.zip sym_bTys pes)`). Report
  through the existing `Illformed_program` channel in exactly the shape of the let-form repair at the same file's sites
  (`core_reduction`: `TAU_WITH_RUNSTATE "Erun" (SEU.runEU (EU.fail (Errors.Illformed_program "Erun: …")))` pattern as at
  `:362`/`:418`; `core_run`: `SEU.runE (Exception.fail (Illformed_program "Erun: …"))` pattern as at `:885`/`:1463`) —
  mirror the existing sites, cite them. Both directions: a surplus that carries `error(...)` must now fail (the surplus is
  never evaluated today), a shortage that would silently keep the old binding must now fail. `one_step` is not a
  fuel-measured worker (only `one_step_unseq_aux`/`get_ctx`/`has_ccall` carry `fuel_measure` declares), so no proof
  statement should move; if any measure-proof STATEMENT changes, STOP and report (body case-splits like round 1 are fine).
- **N3** — record §7 (`2026-09-20_match-pattern-arity-record.md:274-275`: "a `.core` input with a mismatched arity now
  fails Core typing on both fork engines") → replace with the exact enforced set after round 3 (tuple
  patterns/expressions/`Eunseq`/`Epar` + the seven argument-list arms + the two `Erun` runtime guards); correct the stale
  proof comment `Core_aux_lemMeasureProofs.lean:467-471` (`subst_pattern`'s tuple arms now decline via `match_pattern` →
  `Nothing`; the loud leaf is in `subst_pattern_val`/`unsafe_subst_pattern`/`update_env_aux`); convert TODO.md deferral
  (iv) (`:360-372`) into the implemented account incl. R4 (which the deferral did not list).

**Tests** (extend the existing exe, no new exe): (a) `test/Unit/MatchPatternArityTest.lean` — the generated
`Core_typing` arms on 0..3-actual grids for a 1-formal fun/proc/continuation/memop and fixed ccall, plus a variadic ccall
fit control; both engines' `Erun` step on surplus / shortage / fit (fit preserves values, e.g. the audit's `run
loop(1,20)` → 21). (b) the audit's retained Core-text witnesses as CLI regression rows recorded VERBATIM in the record +
evidence dir on the fork build in default, `--rewrite`, `--typecheck-core` and both: `fun-error.core`, `proc-error.core`,
`memop-error.core` (pre-fix: `Error{msg:"surplus"}` exit 1 default vs `Specified(3)`/`Specified(1)` exit 0 typed),
`run-fixed-error.core` (pre-fix `Specified(2)`), `run-short-stale.core` (pre-fix `Specified(11)`), and fitting controls
(`run loop(1,20)` → `Specified(21)` unchanged). Sources: the audit evidence dir (`core/`, `adjacent-core/`). Post-fix
expected: typed modes reject with the structured typing failure; default/`--rewrite` report `Illformed_program` for
run-arity, and the fun/proc/memop surplus-error cases still `Error` (unchanged, since default mode does not typecheck) —
record what is OBSERVED, verbatim.

**Registers/pins.** No new pure failure leaf is expected (`E.fail`/`Exception.fail` are monadic) — confirm with
`check_failure_reach`, do not assume; if a new pure leaf appears necessary, STOP and ask. Fork-drift: single-row re-pins
for `core_typing.lem`, `core_run.lem`, `core_reduction.lem` source-content + their generated deltas, one dated NOTE.
Tray: extend `upstream-tray/45-core-match-pattern-truncating-zip-arity.md` with an "argument lists" section (the seven
typing zips + the `Erun` runtime truncation in both engines, witnesses verbatim, pristine-vs-fork rows) — same class as
the tuple case (pristine differs only on malformed hand-written Core; not reachable from elaborated C).

**File fence.** `frontend/model/{core_typing,core_run,core_reduction}.lem`; `lean_frontend/test/Unit/MatchPatternArityTest.lean`;
`lean_frontend/Core_aux_lemMeasureProofs.lean` (comment only, unless a proof BODY needs a split); the charter, record,
tray 45, TODO.md; `scripts/fork_drift_manifest.txt` (single rows); `scripts/failure_reach_register.txt` only if the gate
demands (then STOP first); the closure-evidence dir; `lakefile.toml`/`test_unit.sh` only for the rebase. Anything else =
stop and ask.

**Gates.** FAST-GATE at each commit: `make prelude-src lean-prelude-src`, `build_cerberus`, `build_lean` (via
`scripts/ce`), `test_unit.sh` (row 1, 15 exes), the Core probes above. Then ONE frozen battery on the final head
(records/evidence first, tree frozen; expected `Source unchanged: True`, pristine 835/28/7/2, gcc-oracle 0 regressions /
0 improvements, 15 unit exes; evidence under `2026-09-22_match-pattern-arity-closure-evidence/round3-34ac493f9/`); any
corpus movement = STOP. Build coordination: no `lake`/`dune`/`make prelude-src`/lane script until the orchestrator's
mainline `34ac493f9` re-verification printed `=== ALL DONE`; one heavy job at a time; ~45 min per pass = stop and report.
