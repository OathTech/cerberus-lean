# Breakpoint landing review

Reviewed on 2026-11-17: `5249f077cb8510cb8060bc320c232a8008b77549`, on
`corenice/checkpoint-semantics-repair`. Target: `feature/cerberus-nice`, currently
`5239a3dba1e30fafd8db45ad180055998ab365dd`. The target is an ancestor, so
integration can fast-forward. Its delta includes the comesfrom prerequisite
as well as breakpoints and the subsequent repairs; it is not a breakpoint-only
merge. No merge, push or consumer re-pin was performed for this review.

**Recommendation: ready for research feature integration, subject to approval.**
Two independent reviewers inspected the execution pathway without restricting
their scope. Neither found a counterexample when the original machine
configuration stays fixed. One produced a concrete configuration-replacement
witness; the other independently assessed it and also recommended correction.
That recommendation assumed a stronger, self-contained API requirement than
the intended semantics needs. After clarification of the valid-state contract,
the configuration finding is answered below and is not a landing blocker.
The production differential runner retains the configuration, and the witness
does not demonstrate failure to decompose an execution of one fixed machine.

## Property examined

In the supported Core pathway, a successfully completed marked strong-sequence
prefix exposes its actual state and pending execution before the suffix begins.
Resuming that suspension must continue the same execution and choices. Under
erasure of administrative pause/resume records, the intended property covers
every execution and every pause schedule that eventually resumes.

This review examined that operational contract, not a relation to symbolic
states or a Caesium proof. Finite execution checks do not establish its
universal quantifier. They provide evidence alongside inspection of the
state, phase and choice handling.

## R1 disposition: parameterized restart does not demonstrate unsoundness

The [model suspension](../../../frontend/corenice/model/driver.lem) retains
file, arguments, concurrency flag, state, phase and budget. The generated
`resume_breakpoint` also accepts independent enum/tag readers and implicit
`CerbGlobal.Switches` and `LemFuel` arguments. They are not all explicit fields
of that suspension.

The [executable witness](../../test/CoreNice/ReviewResumeContext.lean) starts
with an enum whose compatible type is unsigned int, reaches a real breakpoint,
then resumes the suffix `PEconv_int (.Enum0 E) 4294967295`:

| Resume environment | Result |
| --- | --- |
| Original unsigned enum reader | `4294967295` |
| Replaced signed enum reader, same saved file/state/phase | `-1` |
| Production `Choice.resume`, retained adapter | `4294967295` |

The same probe confirms that raw resume restores its supplied suspension's
driver state even when its ND action is run against an unrelated ambient
state. The production host also continues under the original configuration.

**Disposition: answered; no semantic defect established.** Resume is an
operation on valid execution states, not an API restricted to unmodified
machine-issued tokens. The decomposition property concerns restarting the
state reached at a cut under the same machine configuration and choices.
Supplying a different valid state or environment may describe a different
execution; it need not reproduce the previous result. An inconsistent
combination is outside the valid-state premise. Neither case makes the
decomposition property unsound.

The enum probe changes an input that affects language meaning. It does not
show that a valid state resumed under its original configuration behaves
differently from uninterrupted execution. Requiring configuration capture or
restricting constructors would enforce a particular API discipline, not repair
an exhibited semantic error. The proposed wrapper is therefore withdrawn.
Keep the parameterized operation and document its inputs accurately. No
validity theorem for arbitrary constructed states is claimed by this review.

## What scrutiny and execution support

* Both strong-sequence completion rules perform pattern validation, bindings
  and annotation propagation before reporting the cut. Failure does not reach
  it. Saved-label entry preserves the pending cut on the left and bypasses it
  on suffix entry.
* The resumable loop retains the nonmemory accumulator, pending threads,
  current-thread preference, wakeup order and global/main continuation.
  Restart restores saved state and phase rather than restarting initialization
  or a scheduler round. Deferred work is retained, not reconstructed.
* The choice session retains its tape cursor, RNG, observer history and
  remaining traversal budget. Pauses do not select another program choice or
  prematurely perform terminal tape checks.
* Review covered substitution, context reconstruction, negative-action/RMW
  paths and interaction with checked incoming jumps. Direct rule, driver and
  choice tests passed independently. Additional reviewer probes covered
  recursion, pointer mutation, abrupt entry, both sibling-call orders and UB
  before/after cuts without finding a fixed-configuration mismatch.

Fresh focused runs on the reviewed implementation passed:

| Run | Result |
| --- | --- |
| Full breakpoint suite | 17 source fixtures, 23 source/choice runs, 212 bidirectional comparisons, 848 interpreter executions |
| Exhaustive small scheduling controls within that suite | All six genuine three-call orders crossed with all 16 subsets of four cuts |
| All-policy recording lanes | 202 pauses: 136 normalized joins, 46 conditions, 16 while restarts, four do conditions |
| Comesfrom tightening campaign | 73 distinct source inputs, 81 comparisons, 435 injected typed-fault controls |
| Configuration probe | Different enum input changes the result; saved-state and production-host controls passed |

The last row characterizes parameter dependence; it is not a semantic
counterexample or a proof of general preservation. The previous
regeneration and affected build at `5249f077c` are unchanged by this review;
the accompanying changes are documentation and an executable witness. Earlier
1,000-program campaign figures remain historical and are not presented as a
rerun of this tree.

## Limits and reproduction

The tested recipe is bounded, single-translation-unit C with concrete LP64
memory, empty switches and no C libc. The active production reducer is the
one inherited from upstream/mainline. The removed legacy Nice evaluator is
not a supported pathway. The optional simplifier has the previously recorded
undefined-prefix discrepancy and is not invoked by the tested lowerer.

Trace comparison preserves effect order within each channel between genuine
choice barriers, ordered choices/tapes and outcomes. It does not establish
arbitrary cross-channel ordering or equality of every part of every reachable
midpoint state. Selected live state assertions and source inspection supplement
the traces; no full-state serialization was used. Divergence and all C programs
remain outside the demonstrated coverage. No new equivalence theorem or full
shipping/trust-gate result is claimed.

From a normally provisioned and built candidate checkout:

```bash
python3 scripts/corenice-breakpoints.py
python3 scripts/corenice-incoming-tightening.py
lean_frontend/.lake/build/bin/corenice-breakpoint-tests
lean_frontend/.lake/build/bin/corenice-breakpoint-driver-tests
lean_frontend/.lake/build/bin/corenice-choice-tests
(cd lean_frontend && ../scripts/lean_probe.sh test/CoreNice/ReviewResumeContext.lean)
```

Use the host's optional memory cap as in the provisioning guide. Review runs
used 8 GiB caps and existing binaries; no broad proof rebuild was needed.
Raw logs are ephemeral. The small configuration probe remains reproducible
source; it records the behavior that prompted and resolved the review question.

[USER, 2026-11-17] Resume should accept any valid execution state. Assess
semantic soundness and decomposition of an execution, without imposing a
requirement that restart accept only a captured, unmodified suspension.

[AGENT, 2026-11-17] Withdraw the configuration-capture landing blocker recorded
at `964e8a74d`: its probe changes the semantic inputs and does not refute the
intended preservation property. No implementation change is required by R1.
