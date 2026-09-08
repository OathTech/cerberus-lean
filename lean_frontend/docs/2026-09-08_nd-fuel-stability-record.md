# ND fuel stability — implementation record

[USER 2026-09-08] approved the six-worker slice proposed in the preceding
assessment, requested an explicit goal, and required an adversarial subagent
audit at the merge candidate followed by a pause for external review before
merging. Base: `df7ca32fed45acfacf015c35e016ff7a8c4f775a`; branch:
`arc/nd-fuel-stability`. Implementation and full Tier A+B validation are complete. The candidate
awaits its adversarial audit and external review; no merge has occurred.

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

Only this record's validation receipt and the TODO status are updated after
that fixed-source run; the implementation, tests, and gate code are unchanged.
The sixteen new contract/composition cones are included in the existing
strict axiom audit. No new axioms, failure atoms, instances, or fuel defaults
were introduced.

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

Pending. The user requires the adversarial audit at this candidate and a
pause for external review before merging. Mainline remains unchanged.
