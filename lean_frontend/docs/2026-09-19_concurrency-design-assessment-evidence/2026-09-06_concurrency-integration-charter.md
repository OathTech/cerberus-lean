# Proposed next charter: scoped SC concurrency integration

2026-09-06 [AGENT]. Proposal for the validation-foundations final discussion;
not authorization to execute or land this work. It preserves the accepted
provider agreement obligation and the user's requirement to discuss landing.

## Outcome and decisions at entry

Produce a current-mainline-based SC concurrency candidate with an enforced,
honest supported domain, a nonvacuous provider agreement theorem, preserved
reference semantics outside reviewed changes, and complete candidate evidence.
The target is a reviewable feature landing. General weak memory, Linux
ordering and the verifier implementation are outside scope.

Adoption should settle these critical boundaries before execution:

- Authorize repair of mixed-size overlap and SeqRMW behavior, with an explicit
  conservative refusal allowed where a complete repair would expand the arc.
  Refusals must be enforced by code at the relevant static/dynamic boundary,
  tested both ways, and described as a narrower supported domain.
- Retain the provider's observer-agreement theorem. Review its precise
  observation, initial-state, fragment and fuel hypotheses before committing
  to implementation. They must admit representative nontrivial programs and
  cannot merely assume the desired agreement. A necessary change to the
  accepted theorem returns to the operator, rather than silently relaxing it.
- Permit ordinary worktree integration, conflict resolution and local
  compiler builds. Shared pins, machine-global state, customer edits and
  other agents' work remain outside authorization. If functional Lem changes
  are required, use a same-name Lem/Cerberus worktree pair and local candidate
  compiler/runtime alignment; preserve the Lem-first landing order.

The agent resolves ordinary implementation and test choices. Record semantic
decisions and deviations in the repo. The other human decisions stay at the
final package: fresh audit scope/scale, adoption of any remaining design
proposal, and exact per-merge readiness. No push is implied.

## Goals and acceptance

| Goal | Acceptance evidence |
|---|---|
| I1 — integrate the actual candidate | New owned worktree based on the actual mainline plus the reviewed validation instruments; preserve prototype S7 initialization edges and measured original `apply_tree` bodies. Review every shared-model conflict, including `mk_conv_int` and atomic qualifiers. Identify base/head and all imported commits. |
| I2 — enforce the claimed SC domain | Failing reproducers for mixed-size overlaps and SeqRMW sequencing; repaired observations or explicit checked refusal. Positive controls exercise accepted atomics, initialization, race detection and sequential programs. Audit the predicate against actual accesses, not only memory-order syntax. |
| I3 — deliver provider agreement | Kernel-checked observer agreement under the reviewed `epar_free`/fragment/state/fuel hypotheses, plus concrete successful instances. Account for event projection, single-thread SC consistency and race checks. Zero new axioms/opaque shortcuts; no native decision procedure. |
| I4 — preserve reference behavior | Original-status litmus checks, full engine observations and independent reference projections; applicable pristine/fork/Lean checks; content-pinned reviewed deltas and unchanged baselines except dedicated justified changes. Every unexpected difference retains its input and raw records. |
| I5 — demonstrate consumption and release evidence | Cold generation/build of all packages and an external provider client using the actual concurrency API/theorem. Full identified Tier A/B, all litmus rows and plants, affected reporting, artifact manifests and explicit unrun exits. Customer adoption remains with its agent. |
| I6 — prepare landing | Clean commit series, updated supported profile, exact open-defect ledger and no unsupported unconditional claim. Fresh audit proposal and ff-only landing discussion against the final heads. |

First establish the exact theorem and domain predicates, then integrate in
small reviewable slices. Use the repaired instruments to minimize differences
before broadening coverage. Keep one heavy job at a time, cap every Lean/Lake
invocation, and honor the existing one-hour build/proof tripwire. Longer
finite differential measurements need written justification before dispatch.

## Dependency and stop conditions

Strict-failure behavior and opaque runtime state remain real provider risks.
If I3 cannot be proved without resolving a particular failure/state path,
identify that path, the missing hypothesis or representation change and its
counterexample. Continue independent integration/evidence work, then bring
the concrete dependency to the operator. An always-refusing domain or a
theorem that assumes agreement does not satisfy I2/I3.

The legacy csmith run remains hands off until its owner finishes. This
charter does not authorize inspection, polling, resumption, rebaselining or a
duplicate campaign. Unavailable reporting remains an explicit release exit.
Do not take over refined-cerberus or transfer the provider theorem to it.

The end package presents all I1–I6 results, failed/unrun checks, exact artifact
identities, the proposed audit and any unresolved semantic choice. Landing
requires the user's discussion and subsequent per-merge sign-off. If mainline
moves, update only the owned candidate, review the delta and re-gate.
