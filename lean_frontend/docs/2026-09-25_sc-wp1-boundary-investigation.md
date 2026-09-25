# WP1 initial experiment: existing driver observation boundaries

[USER, 2026-09-25] Proceed with WP1 while the overseer lands WP0.
[AGENT] Landing was a work-order convention, not a technical dependency:
`arc/sc-wp1` already contains audited WP0 `e1c1d2c3a`. Investigations can run
here now. Reconcile with the actual mainline/prerequisite before proposing a
WP1 landing, and repeat evidence if relevant inputs change. The governing plan
and `SC-WP1.md` now record this distinction.

## First production-path diagnostic

[SCWP1Boundary.lean](../test/Unit/SCWP1Boundary.lean) calls the existing generated
`step_ctx`, `new_drive_core_threads`, ND combinators and concrete primitives.
It introduces no executor or replacement reduction semantics. At generated-call
fuel 64 and 128 it checks these independently specified expectations:

* A singleton `pick [7]` followed by state update returns `NDactive` with the
  state already changed to 7. The ND node is not a suspension before that
  continuation (`nondeterminism.lem:62–76,190–200`).
* Zero, one and three nested `Ebound` forms each expose exactly one initial
  Core choice. One call to `new_drive_core_threads` executes respectively
  zero, one and three tau reductions and returns the program-done choice.
  The expected count comes from the explicit Core syntax, not a recorded run.
* An actual non-atomic Core store starts with an allocated byte initialized
  to zero. `step_ctx` exposes one action request and `can_advance` accepts it.
  `new_drive_core_threads` executes the store and returns program done;
  readback is 42 and WP0 capture contains the one actual store receipt.

The source explains the observations: `drive_nonmemory_steps_aux2`
(`driver.lem:1066–1095`) repeatedly selects an advanceable step, executes it
and revisits the same thread. `can_advance` admits memory requests under its
single-thread assumption (`driver.lem:911–937`). `advance_step` handles that
request before discovery returns (`driver.lem:944–988`).

[AGENT] This defeats treating the current driver function as pure choice
enumeration or one bounded scheduler step. It is expected sequential-driver
behavior, not a new sequential bug. The next bounded-step experiment must
expose and execute an explicit selected Core transition separately. Its boundary
must also account for non-atomic `SeqRMW`, which the current handler groups
into load/update/store (`driver.lem:714–724`). No suspension constructor has
been chosen, and direct interleaving remains a proposal.

## Reproduction and limits

Regenerated both source trees from the pinned Lem, built `CerberusLean` under
the repository cap, and checked handwritten/Lean generated-source sync. From
`lean_frontend`, under the workspace's scoped environment:

```
../scripts/capped env LEAN_ABORT_ON_PANIC=1 ../scripts/lean_probe.sh test/Unit/SCWP1Boundary.lean
```

The probe passed at both test-selected fuels. Retained
[output](sc-wp1-evidence/boundary.txt) and
[identities](sc-wp1-evidence/boundary-identities.json) identify this run.
Production source is unchanged from WP0. The required fast ladder then passed
**17/17 commands**, source unchanged, with no artifact issues; its
[record](sc-wp1-evidence/initial-fast.json) retains source and log identities.
This standalone experiment is not a new standing gate or a WP1 acceptance/
landing candidate. Full Tier A+B was not rerun for this initial diagnostic.

These are finite Lean production-path witnesses, not a paired native test,
a single-thread infinite-loop step-budget witness, a general theorem or an SC
correctness claim. No scheduler budget is defined here. Pure discovery,
step/run laws, SeqRMW interleavings, source-order summaries/reclamation and
the WP-C general lemma remain the accepted WP1 work. This record establishes
the first boundary to replace; it does not close that work package.
