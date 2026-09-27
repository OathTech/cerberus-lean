# SC concurrency WP1: execution feasibility and decision

[USER, 2026-09-25] The overseer will handle WP0 landing; prepare a new branch
for the next work package. [AGENT] `arc/sc-wp1` starts at the audited WP0
candidate `e1c1d2c3ae12385fc15590a1e9600c4fb6638808`. This entry note prepares
the branch. [USER, later 2026-09-25] Proceed with WP1 while WP0 landing is
handled separately. [AGENT] WP1 investigation starts on the audited candidate;
the merge is not a technical prerequisite for this work.

The governing master plan remains `SC-CONCURRENCY.md` on
`arc/sc-concurrency`; its snapshot when this branch was cut is
`979ae9b80cf239c1e8f4ba710abc04ce828d9f80`. This note is an entry point, not a
replacement plan or a new design decision. Read that plan and technical
design sections 6, 7 and 9 before work:

```
git show arc/sc-concurrency:SC-CONCURRENCY.md
git show arc/sc-concurrency:lean_frontend/docs/2026-09-24_sc-concurrency-design.md
```

## WP1 entry contract (September 25)

[AGENT] The entry contract tests whether the proposed operational construction
is viable before broad scheduler or atomic-operation implementation. Its
acceptance obligations are:

1. **Bounded stepping through actual Core.** A deterministic single-thread
   loop must yield promptly under an explicit step budget. Discovering choices
   must execute no effects or unchosen fault. Repeated steps and the runner
   must agree on memory, observations and resources; ordinary `SeqRMW` remains
   a non-atomic load/update/store. Keep initialization and finalization in the
   real program continuation. An ND node alone is not a scheduling boundary.
2. **Correct source order with scalable retained state.** Exercise actual Core
   unsequenced, weak/strong sequencing, calls, publication and fork/join forms.
   Independently derive their relations and first conflicts. Establish what
   the summaries retain and when history can be discarded; measure repeated
   source split/join and bounded-live-thread creation, including retained
   coordinates and references. Include missing/invented-order controls.
3. **A credible connection to the SC reference.** State the initial domain,
   source relations, initialization assumptions and proof decomposition for
   execution fidelity, soundness, coverage, UB/prefixes and object composition.
   Demonstrate a substantive general lemma about the riskiest link using the
   experiment's actual transition definitions. Report remaining obligations;
   bounded agreement and proposition statements are not general proofs.

The entry contract compares direct Core-request interleaving, justified
resumable helper services and the historical commitment approach. Direct
interleaving was the leading proposal; the September 27 decision below
resolves the choice after the required evidence. The failed prototype remains a quarry. Iris integration is outside
the MVP. Useful independently auditable results may be proposed for early
landing under the master plan's existing policy.

## Current decision and evidence

[USER, 2026-09-27] Push through the end of WP1; WP0 has landed on main.
[AGENT] WP1 is rebased onto the actual WP0 landing `5ecc0aa33`; the old
bounded-stepping commit `171e06df5` is now `b52f9e660`. Historical evidence
keeps its original identities.

The [execution decision and S1 entry contract](lean_frontend/docs/2026-09-27_sc-wp1-execution-decision.md)
closes WP1 as a decision/evidence package, ready for independent review.
It chooses selected bounded Core
reductions over concrete memory, with owned pending primitives where a
Core action must yield, source frontiers distinct from scheduler order,
and incremental causal/access summaries. Axiomatic checking remains in
the independent reference lane. The old branch remains a quarry; no Iris
integration is part of the MVP.

The earlier [boundary investigation](lean_frontend/docs/2026-09-25_sc-wp1-boundary-investigation.md),
[bounded stepping](lean_frontend/docs/2026-09-26_sc-wp1-bounded-stepping.md)
and [follow-up measurements](lean_frontend/docs/2026-09-26_sc-wp1-followup-measurements.md)
remain evidence, including their failed alternatives. New checks cover
pending SeqRMW, actual C-call intervals, fork/join inside modern call
frames, read-dependent publication, the first race before a looping
operand, and repeated source/thread churn. General kernel lemmas relate
the actual unseq reduction and negative-hoisting exclusion operation to
local relational contracts, and prove exact live-endpoint extension and
retirement. The candidate adapter also has whole-state run-composition
and structural-discovery laws.

The decision record distinguishes measured/proved facts from S1–S4's
remaining implementation and correspondence obligations. In particular:

- The dense causal matrix is an exact bounded-retention baseline, not the
  selected representation for large programs. S2 must justify and measure
  its efficient implementation against that interface.
- Production trace streaming and sound lexical environment reclamation
  are mandatory S1 scale work. The inherited negative-hoisting leak is
  not fixed or hidden by the positive/churn measurements.
- S1 must repair inherited positional fork-result reversal and missing
  modern-stack wait substitution in shared Lem. The candidate adapters
  demonstrate the intended behavior without changing the default driver.
- WP-C's hardest open link is actual Core source/control-flow replay and
  coverage, not merely total-ordering a supplied graph. The typed schemas
  are statements, not proved end-to-end correspondence.

Reproduce the decision experiments with `scripts/test_sc_wp1_decision.py`;
rerun the earlier paired and C-source instruments with
`scripts/test_sc_wp1.py` and `scripts/test_sc_wp1_source.py`. Follow the
normal scoped environment, memory caps and panic-abort requirements.
None of these standalone instruments is a new standing ladder gate.

Validation passed: 40/40 full A+B commands, the focused experiments and
local proof checks, and the 872-case three-engine report with its historical
report-only differences preserved. Exact source identities and limits are
in the decision record. No public SC
mode, mainline merge or push is implied. The next work package is S1's
actual internal transition API and the independently auditable fixes it
requires; its source/projection and scale obligations accompany the code.
