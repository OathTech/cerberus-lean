# SC concurrency WP1: execution feasibility and decision

[USER, 2026-09-25] The overseer will handle WP0 landing; prepare a new branch
for the next work package. [AGENT] `arc/sc-wp1` starts at the audited WP0
candidate `e1c1d2c3ae12385fc15590a1e9600c4fb6638808`. This entry note prepares
the branch; no WP1 experiment or implementation has been performed.

The governing master plan remains `SC-CONCURRENCY.md` on
`arc/sc-concurrency`; its snapshot when this branch was cut is
`979ae9b80cf239c1e8f4ba710abc04ce828d9f80`. This note is an entry point, not a
replacement plan or a new design decision. Read that plan and technical
design sections 6, 7 and 9 before work:

```
git show arc/sc-concurrency:SC-CONCURRENCY.md
git show arc/sc-concurrency:lean_frontend/docs/2026-09-24_sc-concurrency-design.md
```

## Next package

[AGENT] WP1 tests whether the proposed operational construction is viable
before broad scheduler or atomic-operation implementation. Its existing
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

Compare direct Core-request interleaving, justified resumable helper services
and the historical commitment approach. Direct interleaving is the leading
proposal, not an accepted strategy. Freeze the decision only after the above
evidence. The failed prototype remains a quarry. Iris integration is outside
the MVP. Useful independently auditable results may be proposed for early
landing under the master plan's existing policy.

## Starting state

WP0 landing remains with the overseer. Before implementation, verify its actual
mainline landing and rebase this short branch onto the resulting current tip
if needed. Do not infer a landing from this branch's existence or merge/push
on the overseer's behalf. The two reviewed runtime commits remain unchanged.

The standard worktree helper primed build artifacts from the primary checkout,
which still preceded WP0 at branch creation. Those copies are not validation
evidence for this branch: regenerate and rebuild before probes. Independent
oracle provisioning was explicitly skipped for this branch-only setup; provision
and validate it before any lane that requires it. Use the scoped workspace
environment and repository memory caps; do not change the shared switch.
