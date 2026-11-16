# CoreNice baseline tool review

Independent reviewer: `corenice_interpreter_review`, 2026-11-14. The review was
unrestricted and covered ownership, resolved dependencies, preparation,
observations, choice traversal, subprocesses, artifacts, campaigns and source
controls. The final code candidate before this record is `b34346531`.
Final verdict: no unresolved blocker; the baseline is adequate to begin actual
Nice AST and interpreter experiments within the limits below.

## Findings and dispositions

| Finding | Disposition |
|---|---|
| Separate executable entries alone did not satisfy the paired-artifact requirement. | One prepared typed AIL value now feeds both lowerers. Complete linked/converted artifacts and supplies are compared structurally, with explicit nominal erasure and the existing comparator-provenance limitation. |
| Synthetic ND tests did not calibrate actual C execution. | Literal, all six three-call order paths and 15 further fixtures pass first-path/all-results comparison with the existing runner. The recursive fixture includes 32 paths. |
| The original driver trace omitted direct memory accesses and intermediate output. | Existing passive byte receipts and output deltas were added at real ND boundaries. Separate channel order is retained without inventing interleaving. Capture-enabled execution is calibrated against ordinary execution. |
| A child retaining pipes could survive an exited subprocess leader; cancellation exposed a second instance in mutation builds. | Owned process groups are checked and stopped before reaping. Focused timeout, SIGINT and SIGTERM regressions exercise the exited-leader case. |
| Successful subprocess diagnostics were discarded. | Producer/build diagnostics are surfaced with explicit bounded truncation. Native failure excerpts retain both cause and tail. |
| Additional mutation producer/artifact runs lacked the ordinary resource bounds. | They now use the same bounded child runner. Build/setup/resource failures cannot count as detected mutations. |
| Fail-fast comparison alone did not test negative controls in the reverse direction. | Each nonpanic mutant's independently recorded tapes are replayed on its peer and checked under both profiles in both directions. Panic has no reverse recording and is explicitly marked inapplicable. |
| Nondefined campaign inputs lacked reproduction recipes, and failure categories were collapsed. | Compact seed/index/prefix/outcome recipes and typed frontend/refusal/resource/protocol/process categories are retained. They never contribute to the defined denominator. |
| Global per-channel flattening would lose effect ordering around real choices. | The optional stutter projection retains genuine choice barriers and aggregates only within those intervals. A cross-barrier effect move is a negative test. |
| Erased metadata and schema versions were insufficiently constrained. | Projection requires `boundary-channels-v1` and known string/list-of-string step metadata. Unknown channels, fields and control payloads refuse. |
| A native panic marker was hidden by tail-only diagnostics. | Cause/tail excerpts were fixed. The control independently checks bounded native stderr, SIGABRT and absent completion; an unrelated process failure cannot satisfy it. |
| `opam exec` selected an older installed Lem during the first mutation attempt. | Isolated builds now prefer the private copied compiler from the pinned candidate. The failed attempt produced no accepted mutation result. No switch or compiler source was changed. |

The reviewer re-examined behavioral fixes. The source-control campaign also
checks witness reachability: the arithmetic change must alter actual stores
while leaving the complete defined outcome unchanged; choice reversal must
reach duplicate-labelled choices; the singleton control must add exactly one
real ND node without changing effects, branch choices or outcome.

## Evidence used

* Complete B closure builds, nominal co-import tests, resolved execution-name
  audit, and a local equation over B's actual evaluator with standard-only axioms.
* 40 final Python controls, including five packaging controls, across protocol,
  resources, campaign bookkeeping, mutations and projection; 39 Lean observation
  checks and the focused Lean choice-runner controls.
* Structural/runner/capture calibration and real output/failure-state controls,
  described in [the interpreter record](interpreter-runner.md).
* The frozen [exact campaign](campaign.md): 1,000 defined programs, 2,000 distinct
  input/tape pairs, 8,000 fresh interpreter processes, all feature/ND targets met,
  zero mismatches or incomplete runs. The separately sampled minimal corpus has
  90 matching defined runs, 19 matching UB runs and two deliberate model-error
  failures, which are not counted as successful coverage.
* All six [built source controls](source-mutations.md) pass. Four real defects
  remain rejected under both profiles/directions. Exact rejects the extra
  singleton; stutter accepts it. Native panic remains incomplete.

The frozen campaign used harness `f2afeae59` and the binary identities recorded
there. Source controls used semantic candidate `f34570718` and controller
`7fbf93303`. Later schema-admission and diagnostic changes have focused tests;
they do not change successful native execution or the exact campaign relation.
No unchanged full campaign was repeated merely for a reporting edit.

No full consumer proof campaign, general equivalence theorem or shipping trust
gate is claimed. This is local research integration. The source closure still
shares the declared frontend/memory services and inherited runtime trust seams.

## Readiness boundary

The reviewed tool supports starting Nice AST/interpreter experiments that
preserve genuine branching choices and allocation/symbol identities. It has
independently editable syntax and execution, exact and explicitly projected
trace comparison, actual choice replay, bounded campaigns and demonstrated
sensitivity to real semantic defects.

New checkpoint/control nodes must be real AST syntax with execution behavior.
Any new observation channel needs an explicit admission/erasure rule; the
current tool refuses unknown channels. It does not recover lexical scope,
establish a complete fine-grained call/jump trace, or automatically minimize
counterexamples. Those are stated limits rather than implied guarantees.
