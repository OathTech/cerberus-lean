# SC concurrency plan re-review: proceed with the bounded first slice

Date: 2026-09-25. Reviewed `arc/sc-concurrency` at
`a740c48aea28852d9ed2e334c9bcb49eefaba17b`, including the complete revised
master plan and technical design, against the previous reviewed head
`b34bcd7bd10285ca595f8e601ca2fbf191f75dfe`.

[USER] Re-review the updates, primarily to ensure success and safeguard the
overall project goals given previous failures. The prior instruction to land
the review on a separate branch remains applicable. During this re-review,
the user also asked whether Iris integration could reasonably leave this task
so it delivers just the semantics. This review recommends that scope change;
it does not record the question as a completed change to the governing plan.
This review is on
`review/sc-concurrency-rereview-20260925`; its judgments and recommendations
are [AGENT]. It changes no governing requirements or implementation.

## Verdict

**Proceed with minimal WP0, then the bounded WP1 experiments.** The revision
substantively addresses the first review. Another broad plan rewrite is not
needed before starting that work. This verdict does not establish feasibility
of the entire release, or authorize a mainline merge.

The plan now has a finite foundation exit, actual step/resource experiments,
explicit source-summary and reclamation checks, and a real-C V1 integration
milestone before feature expansion. These changes can expose a failed design
before it becomes another large implementation.

The response uses the alternative explicitly offered in R1: correspondence
is now on the critical path and V1 supplies earlier executable feedback.
Retaining the semantic scope is defensible; I would not block WP0 by insisting
again on a smaller supported C profile. In response to the user's new question,
however, **I recommend a semantics-only delivery, with Iris integration moved
to a separate task.** That removes a consumer integration dependency while
preserving the actual executable transition system and its justification.

This change does not make general correspondence tractable by itself. That
remains the largest delivery uncertainty and must be decided by the WP1/V1
evidence. Two concrete follow-through items are the scope boundary below and
an inherited primitive-state mismatch to use as a distinguishing WP0 failure
test. Neither requires broadening WP0.

## Disposition of the original findings

“Addressed” here means the plan now directs the necessary work. No new SC
runtime implementation or completed proof is present in this revision.

| Original finding | Re-review disposition | Evidence that must still arrive |
|---|---|---|
| R1: release scope and correspondence | **Accept the retained semantic-scope alternative.** Master plan lines 122–154 add V1 and explicit WP-C. The response correctly preserved the then-current contract; the user's new question motivates the Iris deferral recommended below. | Concrete correspondence feasibility at WP1, followed by actual attached proofs. V1 remains an internal capability milestone, not full release completion. |
| R2: causal summaries | **Addressed in the plan.** Technical design lines 449–467 require independently derived source relations, actual continuations, a substantive invariant and retired-coordinate accounting. | The experiment and its general summary/first-race argument. A list of passing source examples alone is insufficient. |
| R3: bounded step | **Addressed in the plan.** Technical design lines 469–501 distinguish singleton-path yielding, generated-call fuel, scheduler budgets, discovery and helper resumption. | Actual step/run/resource witnesses. These remain necessary for semantics-only delivery, without an Iris compatibility gate. |
| R4: finite foundations | **Addressed.** Master plan line 165 explicitly closes WP0 after the paired load/store slice; later receipt families have later consumers. | Direct primitive state and receipt tests, observer erasure, alternatives and bounded storage. Include failure *inside* a primitive, as below. |
| R5: inherited costs | **Addressed.** Technical design lines 319–356 retain whole-run usefulness while separating SC overhead and inherited retained state. | Measured counters and end-to-end controls; an inherited-cost label cannot excuse new SC scans or make an unusable selected run acceptable. |

## RR1 — Recommended scope change: deliver semantics; defer Iris integration

**Locations:** [master plan](../../SC-CONCURRENCY.md) lines 34, 110, 167 and 172;
[technical design](2026-09-24_sc-concurrency-design.md) lines 544–572.

**Yes: the semantics is a useful, independently assessable deliverable.** Iris
is one future client of it. Constructing that client's language instance and
proving client-specific properties need not be part of this concurrency build.
The present S5 external demonstration introduces a second integration project
with its own thread-pool, value/stuckness and observation contracts.

My earlier, uncommitted draft proposed bringing a small Iris witness forward
because the existing release contract required that consumer. Given the user's
scope question, I recommend removing that requirement instead. There should be
no Iris experiment prerequisite for WP1, V1 or public semantics delivery.

**Keep in this task:**

- The actual configuration and transition definitions over Core continuations,
  shared memory and saved services, available from Lean. Their visibility is
  part of delivering formal semantics; it does not require a generic adapter
  framework or a particular Iris thread-pool presentation.
- Explicit scheduling/local alternatives, fork/join, source sequencing,
  synchronization and atomic-operation boundaries. A whole-machine relation is
  acceptable if that is the justified execution design. A separate
  selected-thread presentation for Iris can wait.
- The bounded runner and its connection to those same transitions, including
  initialization/finalization, resumed state and resource accounting. Preserve
  completion, UB, unsupported, blocked and exhausted outcomes. State precisely
  how resource bounds affect the semantic claims; do not silently erase them.
- The existing V1 cases using the production API, independent semantic controls,
  scale checks and WP-C obligations. The executor and these checks supply real
  immediate uses of the transition API without requiring an external consumer.

**Move to a separate Iris task:** the Iris `Language` instance, mapping to its
thread pool and observations, consumer-specific scheduling correspondence,
consumer package/pin integration, and the external fork/join or publication
proof. Resource algebras, WP rules, adequacy and application proofs also remain
outside this task, as already intended. No claim of demonstrated Iris
compatibility should accompany the semantics release.

**Concrete plan edits for the executing agent:**

1. In master-plan §1, replace “The same transitions must support the Iris
   consumer” with “Expose the actual transition definitions and observations
   in Lean; integration with reasoning frameworks is separate work.”
2. Replace §2's **Reasoning consumption** row with **Semantic interface**:
   actual configurations/steps and observations, runner correspondence and
   explicit semantic atomicity boundaries, exercised through the production
   examples. Remove the external-client acceptance criterion.
3. Keep S1 and V1. Rename S5 **Public SC semantics delivery** and remove the
   external consumer demonstration from its deliverable and exit gate.
4. Rewrite technical-design §10 as **Semantic transition and runner contract**.
   Keep the actual continuation, state, effects, outcome and resource laws.
   Move the Iris-specific presentation and adoption work to a deferred record;
   remove the final Iris-success clause in §11. Update the status/response
   references when adopting this scope decision, preserving historical reviews.

The tradeoff is explicit: future Iris integration may require an adapter and
additional lemmas, and we will not know its cost from this release. Keeping
the real definitions inspectable and justifying the runner limits that risk
without trying to pre-build the future consumer. This removes integration
work; it does not justify weakening C behavior, race correctness or reference
correspondence. Those remain the hard parts of the semantics project.

## RR2 — P2 for WP0: failing primitives need independent state checks

**Locations:** technical design lines 379–380 and 421–426;
[`CerbMem.lean`](../CerbMem.lean) lines 2426–2454;
[`impl_mem.ml`](../../memory/concrete/impl_mem.ml) lines 1564–1594.

The revised receipt contract correctly requires exact returned failure state.
There is already a concrete source-level discrepancy in the primitives that
the observer will wrap:

1. OCaml `load` updates `last_used := alloc_id_opt` at line 1575, then checks
   for a `_Bool` trap representation and fails at lines 1591–1594. Its state
   monad preserves that updated state on the kill.
2. Lean `loadM` defines `fail_` to return the input state at line 2428. The trap
   branch at line 2448 uses it. Only successful completion at line 2454 updates
   `lastUsed`.

For a valid live allocation A containing a trapping `_Bool` representation,
with incoming `lastUsed = B` and A different from B, the source definitions
therefore give different failure states: A in OCaml, B in Lean. This is an
inherited mainline issue, not introduced by the documentation update. I have
not executed a fresh direct primitive reproducer, and do not claim a
return-value/stdout discrepancy from this metadata difference.

The existing [`MonadicFailstop.lean`](../test/Unit/MonadicFailstop.lean) controls
at lines 34–63 cover a successful byte load followed by a `memcmp` failure and
continuation suppression. That does not exercise a failure *within* `loadM`
after OCaml has updated its state. Testing only “successful operation, then
explicit kill” can validate the observation adapter while missing this case.

**Recommended action inside the existing WP0 validation work:** construct
matching direct primitive states and compare their returned fields before
adding observation. A small recipe is a one-byte live allocation at address
100 with allocation identity 7, byte value 2, `_Bool` load type, and incoming
`lastUsed = 99`, using the existing matched target and sufficient fuel.
Check the exact kill and post-state. Include byte 0/1 positive controls and an
invalid-pointer control that fails before `do_load`. Use actual primitives,
not a transcription of their intended behavior.

If the reproducer confirms the source-derived discrepancy, isolate the small
sequential repair and its regression evidence. Record it separately from
observer erasure, whose baseline must be the corrected primitive. Do not
normalize this field away, drop it from the advertised failure-state contract,
or launch a general memory cleanup to close WP0. Existing permission in the
plan for separately justified sequential repairs is sufficient to organize it.

This example also reinforces why WP0's consumer must inspect the actual
pre/post memory independently of receipts. Faithful transport of an already
wrong post-state is not primitive correctness.

## Keep the remaining proof risk measurable

WP-C is now honestly exposed, and I accept that planning correction. Its WP1
entry is still well-typed statements, nonvacuous examples and a “credible”
decomposition (master plan lines 139–154). That is appropriate initial work;
it is not enough evidence to expand indefinitely through S3/S4.

At the WP1 review, identify the riskiest link from actual Core transitions to
the chosen reference domain and demonstrate at least one substantive general
lemma about that link. A useful candidate connects actual load/store handling
and source sequencing to the trace invariant required by soundness or by the
linearization argument. A theorem that merely assumes the reference predicate
already holds, a concrete closed-program evaluation, or another definitionally
equal wrapper does not test this risk.

Keep the experiment bounded by its declared Core fragment and existing V1
cases. Reuse its accepted production definitions and tests; do not build a
second toy executor whose port to production becomes a new work package.
Report the hardest unresolved proof obligation at the WP1 checkpoint. If the
argument still depends on unstated source assumptions or an unimplemented
general semantics translation, decide the design or release policy there.
Adding atomic families does not reduce that uncertainty.

This is how I would assess the existing feasibility gate, rather than a demand
for the complete correspondence theorem before WP0 or V1. Deferring Iris does
not remove these semantic justification obligations.

## Project safeguards and immediate handoff

The revised plan preserves the goals that matter: existing Core and concrete
memory remain authoritative; runtime outcomes are independent of a scalar
graph adapter; ordered byte/member operations stay required; the paired engines
do not certify their shared semantics merely by agreeing; failures and resource
limits remain visible; and useful independently checked slices can land early.
The initial stop-at-first-UB contract also removes an avoidable diagnostic
continuation obligation without weakening a claim of defined execution.

The implementing agent should now complete the finite load/store slice and
its direct state/erasure controls, incorporating RR2. Then run the revised WP1
experiments with a concrete WP-C proof-risk witness. Adopt RR1's scope boundary
in the governing plan; no Iris implementation is a prerequisite. Keep V1 green
and useful before extending atomic/service families.
Do not treat the number of documents, accepted recommendations or component
tests as evidence that the hard integration has succeeded.

There is no need to settle every later atomic/runtime decision before WP0,
or to hold another plan-only review for wording convergence. Review executable
evidence at the already named boundaries. If the next checkpoint again consists
mostly of more infrastructure and a larger promise of later integration, reopen
the delivery decision then.

## Verification and limits

- The revised branch was clean at the reviewed head. Its update changes seven
  Markdown/JSON files and no production source. I read the full revised master
  plan and technical design, response, quarry guidance and corpus guidance.
- The imported original review and cost evidence are byte-identical to
  `e280ba684e95be1c4e6c38ec8e21fa09316950df`. All 21 donor inputs still match
  both their recorded hashes and the pinned donor source. The targeted
  document check verified 33 local links/anchors; `git diff --check` passed.
- Current primitive/ND source was inspected for RR2. The failure-state finding
  is source-derived and needs the focused reproduction described above.
  No new engine runs, builds, timings or release gates were performed here;
  unchanged old binary measurements remain historical evidence.
- Consumer inspection was read-only. At committed `cerberus-sl` head
  `45cce8735f0a2a240913857358f0c4b66a885d27`, `Lang.lean:1051` uses an
  existential-fuel mirror step and `PStep` at line 1070 returns no forks.
  Its Iris pin is `34390a0133986385c62bf59a6eb01938945b48ec`; that pin's
  `Iris/Iris/ProgramLogic/Language.lean:69,110–113,126–131` specifies primitive
  steps, value stuckness and thread-pool scheduling. This establishes the
  separate integration surface, not its impossibility or a required redesign.
  No consumer adoption or compatibility proof is claimed. The consumer has
  unrelated in-progress edits and was not built or changed.
- This review adds one document on a separate branch. The implementation
  branch, governing plan, mainline and donor remain untouched.
