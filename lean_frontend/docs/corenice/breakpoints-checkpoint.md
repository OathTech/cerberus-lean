# CoreNice breakpoints: experimental checkpoint

The `corenice/breakpoints` milestone implements the
[breakpoint charter](breakpoints-charter.md) on top of `11587a90b`. This is a
position-restricted AST feature and an executable resumable machine, supported
by differential tests. It supplies no Core/Nice equivalence, producer-correctness
or Caesium simulation theorem. It has not been merged to the integration branch
or pushed, and consumers remain on their existing dependencies.
The tested source checkpoint is `b33144e13`; the final record changes only
documentation. Test-only refinements were validated with focused reruns while
the compared interpreter binaries stayed unchanged.

## What is implemented

The owned Lem AST represents a strong tail as
`(Continue | Breakpoint site, right_expression)`, exclusively in `Esseq`.
There is no breakpoint constructor at arbitrary expression positions. Each site
stores its procedure, identity, role, producer occurrence key and location.
Its separate fresh namespace leaves Cerberus's semantic supplies unchanged.

Both execution-rule paths recognize successful strong-sequence completion after
pattern validation and binding. The production rule retains dynamic annotations
around the untouched suffix and exposes `TSK_Breakpoint`. Transport covers
substitution, saved continuations, contexts, linking, conversion, typing and the
relevant simplifications. A jump into the right operand bypasses a normal
completion cut; an abruptly exiting left operand does not falsely arrive.

AIL lowering marks existing joins between block statements, successful
condition evaluation and normal loop-body completion. It inserts no new
sequencing to create these sites. Some joins belong to normalized AIL loop-control
wrappers; the [composition mapping](breakpoint-composition.md) identifies those
separately from direct source joins. A provenance tag is not a proof of alignment.

The [driver](breakpoint-driver.md) retains an explicit global/main continuation,
nonmemory worklist and deferred frontier, thread state, configuration and
cumulative budget. Resume continues that phase without repeating startup or
rescheduling a previously selected choice. The existing automatic `drive`
remains available for comparison.

`ChoiceRunner` retains the same tape cursor, random state, observations and
remaining traversal budget across a nonterminal suspension. `corenice-resume`
supports `all`, `none`, `every:N`, `site:N` and `visits:N,M,...` host pause
policies. They select observations without adding semantic choices. An exhausted
model, driver, host or traversal budget remains incomplete execution.

The full state stays in memory. Output contains only compact site/phase
descriptors, choice descriptors and existing semantic observations. The demo
reads a small live heap projection directly; it does not serialize snapshots.

## Comparison and measured evidence

Ordinary Core versus automatically continuing Nice still uses exact comparison.
The explicit `breakpoints` profile additionally admits well-formed pause records
and erases those records plus nonbranching administrative boundaries. It retains
ordered effects in each observation channel between genuine choice barriers,
complete ordered alternatives, consumed tapes, terminal values/output and
failures. It does not assert cross-channel interleaving that the underlying
buffers never recorded. The existing `exact` and `stutter` profiles are not
silently widened to accept pauses.

The following focused runs passed on the implemented machine:

* Sixteen C fixtures with 17 input/choice-policy runs: 86 bidirectional
  comparisons, 344 interpreter executions, 14 defined paths and three UB paths.
  The all-pause recording lane observed 178 pauses: 112 statement joins,
  46 conditions and 20 normal body completions. This includes all four subsets
  of a two-cut execution, repeated/recursive visits, abrupt exits and two
  distinct actual orders of unsequenced helper calls.
* The three-call fixture separately enumerates all six complete choice paths
  and all 16 subsets of its four cuts, plus the automatic/none/every/site
  controls: 126 bidirectional comparisons and 504 interpreter executions.
  Every actual complete tape has exactly arities 3 then 2 and equals its supplied
  prefix; all six distinct expected return values occur. Larger suites sample choices
  and schedules; this exhaustive result applies only to this finite fixture.
* All 111 non-libc minimal inputs, in each of the automatic and resumed lanes:
  90 defined, 19 UB and two exact expected-allocator-OOM controls. There are
  no unexpected failures. The resumed recording lane reaches 403 cuts. OOM
  controls are reported separately and do not count as defined C coverage.
* The `composition.c` demo compares the complete erased artifact, asserts the
  live heap values at 15 pauses over eight sites, and finds the exact source
  suffix inside the actual suspended arena at the `x=1` handoff. It observes
  `x=3` before the loop, conditions at 3/4/5/6 and completed bodies at 4/5/6.
  The normal result is 6.
* Real rule tests cover pattern failure, both strong-sequence paths, nonempty
  positive/negative annotations into a suspension, saved-label placement,
  both negative-action reconstruction branches and the actual RMW service
  request/update/completion callback with a supplied memory reply, followed by
  the reconstructed cut.
* Direct driver tests cover initializer-to-initializer/main handoffs, one-time
  startup, retained deferred work under both competing choices, exact residual
  arenas and cumulative-budget exhaustion.
* Mutations repeat the actual left effect, skip the suffix or add a genuine
  choice, and each changes the observed execution. Removing a required site
  preserves C observations but fails the expected-encounter assertion. A
  separate runner mutation repeats a consumed choice and is rejected by replay.
* Existing choice/session controls, 39 observation checks and 44 Python
  instrument tests pass. The quote generator's `--check` passes.
* Complete artifact erasure and old-runner/capture calibration pass on six
  fixtures: composition, do-loop, sibling calls, saved-label sequence suffix,
  three-call ordering and recursive factorial. This covers 81 finite paths
  per target, with two artifact mutation controls per fixture. The sibling-call
  fixture alone has 40 paths; its resumed tests sample two, not all 40.
* Inherited comesfrom controls pass: 29 direct transitions, two original-error
  precedence controls, nine exact bidirectional comparisons and 27 typed faults.
  The tightening suite also passes over 73 distinct inputs/81 comparisons,
  64 executed tightened destinations and 435 injected typed faults.

The complete frozen generated campaign passed: **1,000 distinct defined
programs, 2,000 distinct input/tape pairs and 8,000 fresh interpreter
executions**, in 601.959 seconds. Every program completed two genuinely
different tapes in both recording directions. There were no mismatches,
incomplete runs, UB, model errors, unexpected `NiceFault`, unattempted inputs
or missing campaign targets. The resumed recording lane reached **76,168
breakpoints**: 55,184 statement joins, 13,896 conditions and 7,088 loop-body
completions. This uses the existing frozen generated slice; it is not new
whole-C coverage.

Pause counts above count the Nice recording lane once per stated input/tape;
they are not inflated by replay runs or by unexecuted static annotations.

## Reproduce

Use the normal [provisioning/generation recipe](interpreter-runner.md#run-it),
with the pinned Lem/LemLib compiler. After `make corenice-prelude-src`:

```bash
(cd lean_frontend && cap lake build CerberusCoreNice CoreNiceDifferential \
  core-diff corenice-diff corenice-resume corenice-pair-check \
  corenice-breakpoint-tests corenice-breakpoint-driver-tests \
  corenice-breakpoint-demo corenice-choice-tests corenice-observation-test \
  corenice-incoming-tests corenice-incoming-control)
python3 tools/generate_corenice_quote.py --check
python3 -m unittest discover -s tests/corenice -p 'test_*.py'
python3 scripts/corenice-breakpoints.py
python3 scripts/corenice-minimal.py
python3 scripts/corenice-minimal.py \
  --corenice-bin lean_frontend/.lake/build/bin/corenice-resume --comparison breakpoints
python3 scripts/corenice_campaign.py --manifest tests/corenice/campaign.json \
  --corenice-bin lean_frontend/.lake/build/bin/corenice-resume --comparison breakpoints
python3 scripts/corenice-incoming-tests.py
python3 scripts/corenice-incoming-tightening.py
for test in corenice-breakpoint-tests corenice-breakpoint-driver-tests \
  corenice-choice-tests corenice-observation-test; do
  cap env LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/"$test" || exit
done
mkdir -p .tmp/breakpoint-demo
_build/default/backend/driver/main.exe --runtime=_build/install/default \
  --cabs-json tests/corenice/breakpoints/composition.c > .tmp/breakpoint-demo/input.json
cap env LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/corenice-breakpoint-demo \
  _build/install/default .tmp/breakpoint-demo/input.json
rm -r .tmp/breakpoint-demo
```

`cap` is the optional wrapper from the provisioning guide. Python harnesses also
bound each child and remove their temporary Cabs/tapes/traces. The generated
campaign uses its frozen 1,000-program/two-path manifest; it is a research
measurement, not a gate on every edit. The mapping document supplies the separate
read-only Caesium output inspection recipe.
For artifact/old-runner calibration, use the
[pair-check command](interpreter-runner.md#structural-and-runner-calibration)
with fuel 1,000,000 and `MAX_PATHS=64` on the six files listed above.

## Trust and limits

The owned Lem sources were regenerated using pinned compiler
`2220010bc25f0c5682d8200f016e786ee66d65c6`, and the affected model, driver,
runner and executable tests compile. Existing continuation-collection measure
proofs compile; `#print axioms` on
`CoreNice.find_labeled_continuation2_aux_measure_sufficient`,
`CoreNice.collect_saves_aux_measure_sufficient` and
`CoreNice.m_collect_saves_aux_measure_sufficient` reports only `propext`,
`Classical.choice`, `Quot.sound`. The focused change audit found no newly added
proof escapes or axioms. No new equivalence theorem is claimed, and full shipping
gates or sandboxed `lake check` were not run for this draft.

Regeneration still reports existing non-exhaustive matches in shared
`frontend/concurrency/cmm_op.lem` and `cmm_csem.lem`, alongside target-renaming
diagnostics. Those shared concurrency findings are outside this single-threaded
milestone and remain unresolved; this change adds no warning suppression.

The recipe remains bounded, single-translation-unit C with the existing concrete
memory model, empty switches and no C libc. Concurrency, symbolic states,
lexical-scope reconstruction and general checkpoint persistence are outside this
milestone. Shared frontend/memory components are not independently validated by
the two targets. Raw Core text parsing supplies unmarked tails; there is no
annotated CoreNice text roundtrip. The old legacy rule path's unsupported
`Eannot` cases are unchanged; production annotation handling is tested directly.

Suspension validity and reader/configuration consistency remain preconditions
of a future theorem; arbitrary fabricated records are not accepted as evidence.
Heap projection and a matching residual in one example do not establish the
relational invariant needed for a general simulation sequence rule. The next
useful proof experiment would state that relation over the exposed phase/state,
prove local pause/resume erasure, then handle each AIL placement and abrupt entry
case separately.

## Independent review

An unrestricted reviewer examined the model changes, phase continuation,
choice-session protocol and the instruments, and independently ran the direct
rule and driver tests. Review findings have led to concrete additions:

| Finding | Disposition |
| --- | --- |
| Erased traces alone cannot detect a lost cut. | Added required encounters, live midpoint assertions and a lost-site mutation with identical C effects. |
| Sampled pause policies did not enumerate small schedules. | Enumerated all subsets for two-cut and four-cut fixtures, crossed with all six genuine paths of the latter. |
| Empty annotations and a reconstruction helper missed real semantic paths. | Execute nonempty annotation suspension, negative-action rewrites and RMW completion/reconstruction. |
| Heap values alone did not establish the claimed pending source suffix. | Check the actual suspended arena contains the exact emitted right operand. |
| Driver-state comparison omitted residual arenas and merely compared stack-shape booleans. | Compare arenas and assert empty stacks explicitly for these fixtures. |
| Six named prefixes alone did not establish exhaustive choice coverage. | Assert full actual tape arities `[3,2]` and exact equality to each complete supplied prefix. |

Final review on 2026-11-16 found no remaining blocking findings at `b33144e13`
and accepted the checkpoint for research review and further experimentation.
The reviewer independently ran the direct rule/driver tests and breakpoint
projection tests, and inspected the completed frozen campaign report. This
verdict does not establish a semantic equivalence or authorize a mainline merge.
