# Checked incoming jumps: implementation checkpoint

Research milestone `corenice/comesfrom`, based on `5239a3dba` of
`feature/cerberus-nice`. The [design](comesfrom.md) is implemented in the owned
CoreNice pathway. Original Core, the Lem compiler, dependency pins and installed
consumer checkouts are unchanged. This is a differential-testing result, not a
refinement, bisimulation or no-fault theorem.
The tested implementation is `fd0b123ef`; subsequent checkpoint edits are
documentation only.

## What is implemented

`Esave` carries the allowed static incoming origins and declaration location;
`Erun` carries its static origin and location. Both actual jump rules resolve
the existing continuation and check arity, then enforce membership before
argument processing. Successful checks add no driver/ND step. Denial returns
typed `NiceFault (IncomingOriginDenied ...)` with the resolved procedure,
executing jump, queried label and exact incoming metadata. Ordinary `Esave`
entry is unaffected.

The normal Nice pipeline is now:

```text
typed AIL → owned lowering → link → conservative annotation
          → structural tightening → convert → initialize → owned driver
```

The producer allocates procedure-local site IDs without consuming Cerberus's
fresh-symbol supply. It preserves original AST fields and map structure.
Ambiguous bindings, uncollected saved labels, unsupported parallel jump binding
and control nodes outside procedures are explicit production refusals.
Corruption tests modify the finalized artifact and do not rerun the producer.

Tightening starts from each procedure's ordinary entry, treats jumps as
non-fallthrough, and follows the machine's actual collected continuations to a
finite closure. Thus it includes sequence suffixes and labels entered from
otherwise skipped branches. Unknown conditions retain both branches;
unsequenced/nondeterministic alternatives retain their possible jumps. Only
literal Core booleans receive branch pruning. There is no tape-derived allowed
set, dynamic profiling, lexical-scope reconstruction or interprocedural pruning.

The authoritative sources are [owned AST](../../../frontend/corenice/model/core.lem),
[substitution rule](../../../frontend/corenice/model/core_run.lem),
[environment rule](../../../frontend/corenice/model/core_reduction.lem),
[producer](../../differential/Incoming.lean),
[tightening](../../differential/IncomingReachability.lean) and
[pipeline](../../differential/PipelineNice.lean). Generation owns 21 Lem modules
and 15 handwritten support modules, producing 57 Lean modules.

## Evidence

The conservative policy passed the frozen campaign before tightening was enabled:
1,000 distinct defined C programs, 2,000 distinct input/tape pairs and 8,000 fresh
interpreter processes, exact comparison in both directions, zero failures,
578.214 seconds. Its production code is recorded at `6a394515d`; enabling the
tightened policy is `e6cfb5ba4`. Subsequent changes repair test instruments and
documentation, without changing that policy.

The dedicated tightened suite uses 73 distinct bounded inputs from nine control
families: eight authored fixtures plus generated variants, with seven duplicate
candidates removed before execution. Its 81 input/tape comparisons remove 142
of 348 syntactic incoming origins across 88 labels. It witnesses 64 executions
reaching an actually tightened destination. All 435 typed fault controls pass:
clear selected permissions, delete the taken origin, and replace that origin.
Fault payloads and preceding observations/consumed choices are checked against
the actual artifact and uncorrupted execution. These are first-site witnesses
per tested tape, not total dynamic jump counts or every-site coverage.

Additional checks cover:

* Both actual jump implementations: 29 direct transitions and two separate
  original unresolved-label panic controls. Procedure aliases and label symbols
  with equal binding identity but different descriptions are included.
* Eight feature fixtures, nine exact bidirectional comparisons and 27 generated
  fault controls; ordinary label entry, loops, switch, recursion and calls.
* Sixteen complete artifact comparisons under metadata erasure, two artifact
  mutation controls per input, and calibration against the existing first/all
  result runners: 52 paths per target, including all 32 recursion-fixture paths.
* The 111 non-libc minimal inputs: 90 matched defined executions, 19 matched UB
  executions and **two model-error failures**, the existing allocator exhaustion
  cases 112/113. Those two failures are excluded from successful coverage.
* Exact output-order and output-before-UB tests; 39 observation checks, focused
  choice-runner controls, and 41 Python instrument tests.

The parsed runtime has zero syntactic saved-label jump sites. Runtime arithmetic
calls are tested, but this supplies no executed runtime-internal jump coverage.
Shared frontend/memory components remain shared; neither differential pathway
independently validates them. The frozen source-mutation campaign from the
unchanged baseline was not rerun; this milestone adds actual metadata mutations.

## Reproduce

Use the [ordinary provisioning and generation commands](interpreter-runner.md#run-it).
Do not use `--check-baseline` on this changed semantics. After regeneration:

```bash
(cd lean_frontend && cap lake build CerberusCoreNice CoreNiceSeparationTests \
  CoreNiceDifferential core-diff corenice-diff corenice-pair-check \
  corenice-incoming-tests corenice-incoming-control \
  corenice-choice-tests corenice-observation-test)
python3 tools/generate_corenice_quote.py --check
python3 scripts/corenice-incoming-tests.py
python3 scripts/corenice-incoming-tightening.py
python3 scripts/corenice-smoke.py
python3 scripts/corenice_campaign.py --manifest tests/corenice/campaign.json
python3 -m unittest discover -s tests/corenice -p 'test_*.py'
```

`cap` is the optional memory-cap wrapper defined in those instructions. The
test scripts bound child resources and remove temporary sources, tapes and
traces. The [tightening fixture notes](../../../tests/corenice/comesfrom-tightening/README.md)
give the original lowering shapes and measured reductions. Paired artifact and
old-runner calibration use the command in
[the runner guide](interpreter-runner.md#structural-and-runner-calibration),
with `MAX_PATHS=64`, on `tests/z2-probes/nd/order3.c` and minimal fixtures
003, 007, 011, 015, 017, 022, 024, 025, 027, 041, 045, 056, 059, 061 and 062.
Sample the minimal corpus with `scripts/corenice-diff.py` on each
`tests/minimal/*.c` except `*.libc.c`; retain its failing classification for
112/113 rather than accepting matched errors as successes.

Existing measure proofs compile. Axiom inspection of
`CoreNice.find_labeled_continuation2_aux_measure_sufficient`,
`CoreNice.collect_saves_aux_measure_sufficient` and
`CoreNice.m_collect_saves_aux_measure_sufficient` reports only `propext`,
`Classical.choice`, `Quot.sound`. Reproduce with a Lean probe importing
`CoreNice.Core_aux_auxiliary` and `#print axioms` for those declarations.
No new Nice theorem, proof escape or axiom was introduced. Full shipping gates
and sandboxed `lake check` were not run for this research checkpoint.

## Independent review

An unrestricted reviewer examined both jump rules, metadata transport, producer
bindings, reachability, quotation provenance, error classification and test
instruments. The following findings were corrected and re-reviewed:

| Finding | Disposition |
| --- | --- |
| First-jump controls did not establish that a tightened destination executes. | Added selection of strictly tightened targets and witnessed 64 such executions. |
| The design promised annotated parsing/printing that does not exist. | Documented original text syntax with defaults, required finalization and the absent annotated roundtrip. |
| Fault tests confused a queried label's spelling with its comparator-equivalent declaration key. | Compare against the executing node's target; both actual rules test distinct descriptions of one label identity. |
| Fault tests similarly confused a resolved procedure alias with its definition-map key. | Generic controls compare binding identity with `symbol_compare`; both rules separately assert the precise resolved alias payload. |
| Eighty candidate cases contained seven duplicate source texts. | Deduplicate before execution; report 73 unique inputs and seven skipped candidates. |
| The reproduction recipe regenerated CoreNice twice. | Removed the duplicate generator invocation. |

The reviewer also independently ran full artifact/old-runner calibration for
`jump_into_branch.c` and `sequence_suffix.c`; both passed. No runtime semantic
defect was found in this review. These results do not replace a proof of the
producer's reachability hypothesis.

## What is ready to consider proving

The useful next target is local, with separate obligations:

1. Define a typed AST/state erasure and show metadata survives substitution,
   conversion and saved-continuation collection in the required way. Current
   `ArtifactCompare` is executable quotation comparison, with its existing map
   provenance contract; it is not that formal erasure or a theorem.
2. Prove each actual jump closure agrees with Core under erased state and an
   admitted origin, and exposes the typed denial otherwise. Use an emitted
   label/loop example to test whether the finite predecessor interface reduces
   proof work, keeping ordinary non-jump entry explicit.
3. Separately establish producer no-fault preservation. Conservative annotation
   needs static-site provenance; tightened annotation additionally needs a
   sound reachability/continuation invariant. The runtime membership rule alone
   does not prove either property.

This is a credible proof experiment, with a concrete implementation and tests
that observe wrong declarations. It is not evidence that whole-C refinement now
scales. Tightening currently removes structurally unreachable edges; even C
`if (0)` is usually lowered through temporaries and remains unpruned. The
machine stores no last-origin history, reconstructs no lexical scope and adds
no heap invariant. Raw Core text parsing still supplies metadata defaults;
there is no annotated text roundtrip. These limits should shape the proof scope.
