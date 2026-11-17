# Breakpoint landing review

Reviewed on 2026-11-17: `5249f077cb8510cb8060bc320c232a8008b77549`, on
`corenice/checkpoint-semantics-repair`. Target: `feature/cerberus-nice`, currently
`5239a3dba1e30fafd8db45ad180055998ab365dd`. The target is an ancestor, so
integration can fast-forward. Its delta includes the comesfrom prerequisite
as well as breakpoints and the subsequent repairs; it is not a breakpoint-only
merge. No merge, push or consumer re-pin was performed for this review.

**Recommendation: correct R1 before landing the standalone restart API.**
Two independent reviewers inspected the execution pathway without restricting
their scope. Neither found a counterexample when the original machine
configuration stays fixed. One produced a concrete configuration-replacement
witness; the other independently assessed it and also recommended correction.
The production differential runner retains the configuration and is unaffected
by that witness. This is an API gap, not a demonstrated failure to decompose
an execution of one fixed machine.

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

## Open finding R1: raw restart does not own its complete configuration

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

The same probe confirms that raw resume restores its saved driver state even
when its ND action is run against an unrelated supplied state. State restoration
works; configuration retention is the missing standalone API property.

The existing same-reader precondition is a valid conditional contract. The
counterexample violates it, so it does not refute fixed-environment
correspondence or invalidate the host's differential results. However, a
machine-produced suspension alone does not determine the raw restart, despite
the interface's description of saved configuration owning it. The host's
protection currently resides partly in its retained adapter.

**Disposition: open; recommended pre-landing correction.** Add a small supported
start/resume interface that retains the immutable semantic environment as
explicit data alongside the existing model suspension. Either capture the
actual entry readers or enforce that both entry and resume obtain them from
the retained program. Retain switches and the configured Lem fuel too; preserve
the existing separate cumulative budgets. Public resume should accept only the
saved execution, with no replacement environment. Keep the generated workers
as documented parameterized primitives and route the host through the supported
interface. A resume-only wrapper is insufficient if entry can already disagree
with its stored file. Add positive retention tests derived from this witness.
This needs no simulation relation, opaque whole-driver continuation or Lem
compiler change.

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
| Raw configuration witness | Confirmed R1; saved-state and production-host controls passed |

The last row is a reproduced finding, not an acceptance pass. The previous
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
Raw logs are ephemeral. The small finding witness is source, intended to be
replaced or extended by the eventual API regression test when R1 is fixed.

[AGENT, 2026-11-17] Recommend closing the standalone resume configuration gap
before feature integration, while preserving the distinction between that API
finding and the positive fixed-configuration differential evidence.
