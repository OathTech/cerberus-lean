# ND fuel stability — implementation record

[USER 2026-09-08] approved the six-worker slice proposed in the preceding
assessment, requested an explicit goal, and required an adversarial subagent
audit at the merge candidate followed by a pause for external review before
merging. Base: `df7ca32fed45acfacf015c35e016ff7a8c4f775a`; branch:
`arc/nd-fuel-stability`. Implementation and full Tier A+B validation are
complete. The adversarial audit passed, and its one documentation finding is
resolved. The candidate awaits external review; no merge has occurred.

## Scope and acceptance

- Prove stability of `runNDFuel`, `runND1Fuel`, and `runND1TraceFuel` when
  their completed observations contain no fuel-exhaustion outcome.
- Prove observed stability of `nd_bind_lemFuel`, `liftND_lemFuel`, and
  `liftAction_lemFuel`, quantifying worker and observer budgets independently
  and deriving shared-budget wrapper corollaries.
- Operands, continuations, state maps, error/info maps, and initial states
  are fixed. Increasing the ambient fuel captured INSIDE those operands is
  outside this slice: the other seven absorbing workers and the remaining
  pending rows retain their separate obligations.
- Preserve exact result order, multiplicity, failure reasons, returned states,
  and trace labels. Empty branches are legitimate empty result collections;
  one completed branch does not establish exhaustive completion.
- Runtime definitions, generated model bodies, Lem pins, failure atoms, and
  baseline rows are unchanged. Proof cones stay within the standard three.
- Full Tier A+B validation, adversarial audit, and disposition of findings
  precede the external-review handoff. No merge is authorized.

## Proof approach

[AGENT] A finite-depth relation compares ND nodes at the same starting state.
Every ordinary node retains its constructor, payload, post-state and ordered
children; an explicit fuel-kill node may be refined by any later computation.
This is a proof device over the shipped definitions, not a second interpreter.
The runner theorems convert this relation into equality when the earlier
observations contain no fuel kill. Bind/lift budget monotonicity supplies the
relation; wrapper equations connect the resulting contracts to the caller's
single `[LemFuel]` instance with fixed operands.

The completion predicate excludes the structural kill value, not its rendered
message. It does not assume that the opaque fuel location differs from other
locations. Fail-stop atom distinctness remains a separate open decision.

## Validation and audit

### Implemented interface

`CerbNDFuelProofs.lean` imports `CerbND` and is a copied, built library root.
It exports:

- `IsFuel` and `NoFuel`, the structural exhaustion/completion predicates.
- `runNDFuel_stable`, `runND1Fuel_stable`, `runND1TraceFuel_stable` and their
  `runND`/`runND1`/`runND1Trace` wrapper corollaries.
- `ObservationStability n k x y s`, whose `exhaustive`, `first`, and `trace`
  fields carry separate completion premises for the respective earlier runs.
- `nd_bind_lemFuel_stable`, `liftND_lemFuel_stable`, `liftAction_lemFuel_stable`:
  independent observer `n ≤ k` and worker `b ≤ b'` budgets, all three modes.
  `nd_bind_stable`, `liftND_stable`, and `liftAction_stable` specialize both
  budgets to the wrapper's instance. An action is observed in the ND node
  `ND (fun s => (action, s))`; the lift's recursive children retain their
  ordinary state transformations.

`FuelProof` contains the proof machinery. `ResultsRefine` allows each fuel
leaf to be replaced by an arbitrary result block, including an empty block;
every retained observation keeps its relative order and multiplicity.
`run_refines` and `run1_refines` establish this stronger property even on
partially completed observations. `trace_eq_of_refines` retains the exact
node-label list when the selected trace completes. The lift induction follows
the mutual generated worker equations, including its two-frame leaf cost;
it assumes no get/put laws.

Sixteen API/composition theorems are added to the existing axiom-cone gate.
`Unit.NDFuelStabilityTest`, imported by `totality-proof-test`, checks partial
forks, exhaustive reversal, first-trace completion with an unfinished sibling,
trace labels, empty branches, guard/branch states, independent and shared bind
budgets, independent lift/action budgets, failure-time state updates, and
ordinary failures. Its captured-instance counterexample is quantified over
two distinct positive budgets: rebuilding an arbitrary input at the new
instance can change a completed result. That is outside the theorem's scope.
The fuel-numeral gate is unchanged; worker witnesses quantify their counters,
with explicit arithmetic hypotheses where a boundary is tested.

### Development checks

The proof module and boundary witnesses elaborate without option increases.
The first unit run passed all seven executables and printed the new theorem
axiom dependencies, then stopped at the existing `hack_measure_sufficient` probe because
the primed auxiliary artifacts were stale. This matches the previous slice's
recorded priming issue. Both generated trees were subsequently re-derived;
the OCaml driver was built using `DUNE_CACHE=disabled` and `dune build --force`,
and a full capped Lake build completed (386 jobs), rebuilding the auxiliary
roots. All 213 generated Lean source files remained byte-identical through
regeneration. All 63 tracked baseline paths (including baseline directories)
remain byte-identical to the starting snapshot.

### Full boundary battery

[AGENT 2026-09-08] All 35 required Tier A+B commands passed, exit 0, with
`containment_cleaned = true` for every command. The run started at
2026-09-08 22:38:48 UTC and finished at 23:53:56 UTC. It used:

```sh
CERB_MEM_MAX=48G DUNE_CACHE=disabled python3 scripts/release.py \
  --mode full --lane-timeout 3300 --out .tmp/nd-fuel-stability/full
```

The schema-2 report has `status = passed`, `selection_complete = true`,
`source_unchanged = true`, and `artifact_issues = []`. External inputs also
compare equal before/after. Its SHA-256 is
`54303094e4e3840db53c910196459beffcf246737d3427a7181ece00de3bd338`;
LADDER membership SHA-256 is
`30eb37a03d7300dce0761ae24f67c0b7b38135b3edf51ccb820b2f226362b74c`.
The raw evidence remains at `.tmp/nd-fuel-stability/full/` in this worktree.
This is a complete Tier A+B run, not a claim of whole-project release:
consumer adoption, reporting exits, and external review remain separate.

| Command ID | Seconds | Exit / containment |
|---|---:|---|
| A1 | 146.40 | 0 / cleaned |
| A2 | 27.43 | 0 / cleaned |
| A3 | 52.77 | 0 / cleaned |
| A4 | 24.63 | 0 / cleaned |
| A4b | 20.07 | 0 / cleaned |
| A4c | 3.23 | 0 / cleaned |
| A5 | 25.17 | 0 / cleaned |
| A6 | 2.33 | 0 / cleaned |
| A7 | 13.31 | 0 / cleaned |
| A8 | 11.61 | 0 / cleaned |
| A9 | 19.32 | 0 / cleaned |
| A10 | 21.72 | 0 / cleaned |
| A11 | 75.47 | 0 / cleaned |
| B1 | 654.92 | 0 / cleaned |
| B2 | 22.87 | 0 / cleaned |
| B3 | 15.20 | 0 / cleaned |
| B4 | 46.04 | 0 / cleaned |
| B5 | 62.48 | 0 / cleaned |
| B6.1 | 164.81 | 0 / cleaned |
| B6.2 | 2.28 | 0 / cleaned |
| B6.3 | 9.55 | 0 / cleaned |
| B6.4 | 8.94 | 0 / cleaned |
| B6.5 | 9.39 | 0 / cleaned |
| B6.6 | 10.04 | 0 / cleaned |
| B6.7 | 8.84 | 0 / cleaned |
| B7 | 1423.89 | 0 / cleaned |
| B8.1 | 13.51 | 0 / cleaned |
| B8.2 | 217.06 | 0 / cleaned |
| B8.3 | 6.74 | 0 / cleaned |
| B8.4 | 16.20 | 0 / cleaned |
| B9 | 1281.86 | 0 / cleaned |
| B10.1 | 65.67 | 0 / cleaned |
| B10.2 | 1.38 | 0 / cleaned |
| B11.1 | 15.15 | 0 / cleaned |
| B11.2 | 6.94 | 0 / cleaned |

Selected verbatim completion lines:

```text
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
observation lane plants: 93/93 passed
```

The GCC row count is 1,963, with 1,885 compared, 1,873 agreements, 12
reviewed triage rows, and zero disagreements. `sa_csmith_369.c` and
`sa_csmith_371.c` both report `AGREE` in this lane. Their committed exec
baseline rows remain MATCH; this slice makes no new 15-second timing claim.
The independent upstream comparison reports 709 semantic agreements, one
reviewed difference, 11 matching failures, and two interface agreements;
its unexpected-verdict plant was rejected. The failure register remains
233 sites, with zero DISCARDABLE, and the fuel partition remains 57/13/5/6.
No baseline or generated-model row moved. The observed zero improvements
is a result, not an additional acceptance gate.

After that fixed-source run, changes are confined to this record, the TODO
status, and the adversarial audit report; the implementation, tests, gate
code, and build wiring are unchanged.
The sixteen new contract/composition cones are included in the existing
strict axiom audit. No new axioms, failure atoms, instance declarations, or
fuel defaults were introduced.

### Consumer use and remaining scope

Import `CerbNDFuelProofs`. For example, given `observerLe : n ≤ k`,
`workerLe : b ≤ b'`, and a proof `completed` of the earlier exhaustive
observation's `NoFuel` predicate, use:

```lean
(CerbND.nd_bind_lemFuel_stable observerLe workerLe m continuation s).exhaustive completed
```

The `.first` and `.trace showInfo` fields use their own earlier observations.
For the production wrappers, `nd_bind_stable` and the two lift corollaries
choose worker and observer budgets together. Arguments, continuations, state
maps, and printers remain fixed. The contract is equality at the given
initial state, not equality of arbitrary state functions after observing
one state. The other seven absorbing rows, whole-interpreter ambient-fuel
stability, and the five reachable pending workers remain open. The existing
fuel-forms classifier continues to certify only the zero-arm property.

### Adversarial audit and external review

[AGENT 2026-09-09] Implementation candidate `7c8bbbd3a` received an independent
adversarial **PASS** for the six-worker, fixed-operand slice. The
[audit report](2026-09-09_nd-fuel-stability-adversarial-audit.md), committed
separately as `c0a0acfb6`, records no blocking, high, medium, or kernel-proof
finding. Its independent full unit suite, fresh elaboration of both new
Lean modules, and targeted adversarial probes all passed. Fourteen additional
probe cones remain within the standard three.

[AGENT, orchestrator disposition] F1, the sole low documentation finding, is
resolved by removing the blank line inside the 35-command table. No receipt
value or Lean source changed. The orchestrator reviewed the audit report,
probe source and outputs, and unit gate completion; rechecked the report and
candidate source hashes, all 63 baseline paths and all 213 generated source
paths; and confirmed that the auditor committed only its report. The original
full battery was run by the orchestrator and was not repeated for these
documentation-only changes.

The branch is ready for external review. The user's requested pause remains
in force: no merge or push has occurred, and mainline remains at
`df7ca32fed45acfacf015c35e016ff7a8c4f775a`. The implementation record and audit
report form the review handoff; the remaining seven absorbing workers and
whole-interpreter fuel composition are not closed by this slice.

## External review (orchestrator, 2026-09-09) — verdict, findings, boundary battery

[AGENT orchestrator], the external reviewer the operator's pause called for;
a separate author from the executing agent and from its adversarial auditor.

### Verdict

**Accepted and landed with one documentation fix.** The slice is the
six-worker, fixed-operand scope the operator approved [USER 2026-09-08]:
completed-observation STABILITY for the three CerbND runners and for
`nd_bind`/`liftND`/`liftAction`, with worker and observer budgets quantified
independently and the wrapper corollaries at the caller's single `[LemFuel]`
instance. It is proof-only: one new library root (`CerbNDFuelProofs.lean`,
499 lines), one unit witness module imported by `totality-proof-test`, 16
theorems added to the axiom gate's FUEL leg, the manifest/lakefile rows, and
the records. No runtime definition, generated body, `.lem`, pin, baseline or
register changed. No `sorry`, `axiom`, `native_decide`, `bv_decide`,
`ofReduce*`, heartbeat or recursion-depth option, `unsafe`, `opaque` or
`partial` in either new module (the two grep hits are the word "axiom" in
comments stating that no atom-distinctness axiom is used).

What the theorems say, checked against the source: `IsFuel o := ∃ s, o.1 =
Killed s fuelExhaustedKill` (structural, rendering-independent), `NoFuel xs
:= ∀ o ∈ xs, ¬ IsFuel o`; `runNDFuel_stable (hn : n ≤ k) m s : NoFuel
(runNDFuel n m s) → runNDFuel k m s = runNDFuel n m s`, likewise for the
first-trace and traced runners; for the workers, `ObservationStability n k x
y s` with separate `exhaustive`/`first`/`trace` premises, derived from a
finite-depth refinement relation in which only an explicit fuel-kill node may
be refined. The unit witnesses are the right adversaries: `fork` shows the
budget matters (2 vs 3), that first-trace completion does not imply
exhaustive completion, and that stability holds only above the completing
budget. Because the theorems are kernel-checked, the only residual question
is usefulness, not soundness: `NoFuel` is dischargeable for a concrete run
whenever every outcome differs structurally from the fuel kill — a fail-stop
kill differs by its message, so the open atom-distinctness question
(`modelFailStopLoc` vs `fuelExhaustedLoc`, TODO) does not block it.

Scope honestly not covered (record §"Consumer use and remaining scope"): the
seven driver-level absorbing workers and whole-interpreter stability under a
larger AMBIENT fuel captured inside operands. That is the next slice.

### Findings

| # | Finding | Disposition |
|---|---|---|
| E1 | `VALIDATION.md` §7 and §9 still said "Fuel monotonicity for the driver workers is NOT provided" / "stability remain[s] obligations" with no mention of what this slice delivers. | Fixed here: §7 states the six-worker stability contracts and their exact limits; §9 claim 5 names them. |
| E2 | The adversarial audit's sole finding (a blank line breaking the 35-command Markdown table) was already resolved by the executing agent. | Verified. |

### Boundary battery on `2c568de01` (independent of the agent's runs)

Cache-disabled rebuild in this worktree, then the LADDER Tier A + Tier B
battery, the fail-stop and fuel plants, the failure-reach gate, the
pristine-oracle lanes (prepared manifest) and the gcc lane. Every lane rc=0:

```
=== bash tools/check_driver_fresh.sh --check  rc=0
=== ./scripts/test_unit.sh  rc=0
=== ./scripts/test_exec.sh --check-baseline  rc=0
=== ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage  rc=0
=== ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug  rc=0
=== ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float  rc=0
=== ./scripts/test_bytes.sh  rc=0
=== ./scripts/test_libc_exec.sh  rc=0
=== ./scripts/test_multi_tu.sh  rc=0
=== ./scripts/test_parse.sh  rc=0
=== ./scripts/test_core.sh  rc=0
=== ./scripts/test_elab.sh  rc=0
=== ./scripts/test_libxml2_uri.sh  rc=0
=== ./scripts/test_cn_coverage.sh --check-baseline  rc=0
=== ./scripts/test_parse.sh tests/ci  rc=0
=== ./scripts/test_core.sh tests/ci  rc=0
=== ./scripts/test_verify.sh  rc=0
=== ./scripts/test_immaculate.sh  rc=0
=== ./scripts/test_speclab.sh --selftest  rc=0
=== ./scripts/test_speclab.sh --plant  rc=0
=== ./scripts/test_hang_plant.sh  rc=0
=== ./scripts/test_kill_plant.sh  rc=0
=== ./scripts/test_fuel_plant.sh  rc=0
=== ./scripts/test_failstop_plant.sh  rc=0
=== ./scripts/test_libxml2.sh  rc=0
=== python3 scripts/test_observation_lanes.py  rc=0
=== ./scripts/check_failure_reach.sh --selftest  rc=0
=== ./scripts/check_failure_reach.sh  rc=0
=== python3 scripts/test_upstream_oracle.py  rc=0
=== python3 scripts/test_upstream_oracle.py --plant  rc=0
=== ./scripts/test_gcc_oracle.sh --check-baseline  rc=0
```

Verdict lines, verbatim:

```
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: exec_match=9 neg_pinned=5 fail=0
SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
SUMMARY: total=2 match=2 fail=0
Total:          106
Total:          106
SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0
SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0
BASELINE OK (213 entries, exact match)
Total:          250
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)
SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)
observation lane plants: 93/93 passed
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
Independent oracle: passed; {'semantic_agreement': 709, 'reviewed_difference': 1, 'matching_failure': 11, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/nd-fuel-stability/.tmp/upstream-oracle-237eyot7/report.json
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/nd-fuel-stability/.tmp/upstream-oracle-zrz043bq/report.json
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
```

Derived: zero baseline movement in every baseline lane; the axiom gate's
FUEL leg now counts the 16 new contract lemmas with cones in the standard
three; fuel census unchanged 57/13/5/6; fork-drift layer 2 = 22; gcc
`agree=1873 disagree=0`; pristine oracle 709 / 1 / 11 / 2 + plant rejected.
