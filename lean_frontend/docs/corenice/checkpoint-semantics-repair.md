# CoreNice checkpoint semantics: repair assessment

Work branch: `corenice/checkpoint-semantics-repair`, based on breakpoint
checkpoint `5cfc65adb`. This is research work, not an equivalence theorem or a
mainline landing. The [initial review](noodler-review.md) supplies the first
counterexamples. This assessment records precise phase metadata and removal
of the inherited, inactive CoreNice evaluator.

## Which evaluator comes from upstream

The active engine was inherited, not introduced by this project. The source
call chain is already present in pinned upstream Cerberus
`c3ff8c53f05982745f9b3a10b3d05442e214bcb5` and cerberus-lean mainline
`8fa3050bf73fe92803f56c49ca53ed00d76aee88`:

```text
Driver.drive → driver2 → new_drive_core_threads
             → drive_nonmemory_steps_aux2 → Core_reduction.step_ctx
```

Upstream's OCaml and web entries call `Driver.drive`; its constant-expression
mini-pipeline calls `driver2`. The Lean `Main` calls generated `drive`, and its
`--call` mode calls `driver2` through `CerbCall`. All use the context-based
reducer. A search of all upstream Lem/OCaml sources finds `core_thread_step2`
only in its own declaration, definition and error strings. Mainline adds
direct unit-test calls, but no production caller. This establishes inactivity
in these inspected versions, not a claim about every external consumer.

At the renamed CoreNice baseline `451011583`, its owned `driver.lem` and
`core_reduction.lem` are byte-identical to mainline's originals. Their shared
Git blob IDs are respectively `cd15c9865f50f3ffbc91a7056765aad71c9a3fb7` and
`614f37ee8c87b260931af4975c6f0d9cb81c6d1f`. Later Nice changes add checked jumps,
breakpoints and resumable driver phases around this copied reducer. The
original Core model files remain unchanged from the mainline baseline.
This does not claim that cerberus-lean has no pre-existing differences from
upstream; those are tracked by the fork's own drift manifest.

Reproduce the provenance checks from this clone:

```bash
git grep -n core_thread_step2 c3ff8c53f -- '*.lem' '*.ml' '*.mli'
git show c3ff8c53f:frontend/model/driver.lem
git show 8fa3050bf:lean_frontend/Main.lean
git show 8fa3050bf:lean_frontend/CerbCall.lean
git rev-parse 8fa3050bf:frontend/model/driver.lem \
  451011583:frontend/corenice/model/driver.lem
git rev-parse 8fa3050bf:frontend/model/core_reduction.lem \
  451011583:frontend/corenice/model/core_reduction.lem
git diff 8fa3050bf -- frontend/model/ backend/common/driver_ocaml.ml \
  lean_frontend/Main.lean lean_frontend/CerbCall.lean
```

## Precise phases instead of source-completion claims

The producer now emits distinct roles for normalized-AIL block joins, completed
if/while condition preparation, pending while restart and pending do condition.
The actual strong-sequence locations and the execution rules are unchanged.
The distinction matters operationally:

* Shared Cabs-to-AIL desugaring already handles source `continue` and `for`,
  before the owned `erase_loop_control` adds its wrappers. Moving a cut before
  the latter's continue label would not recover source-normal completion.
* A while restart cut precedes the existing `Erun`. For a source `for` loop,
  the increment and intervening cleanup have already completed there.
* A do condition cut precedes the condition's effects and failure possibilities.
  It does not imply that another iteration will execute.
* Saved-label entry can skip an earlier prefix and still reach a normalized
  join or restart. The role is a static placement description, not dominance,
  lexical scope, or proof that a whole source statement executed normally.

The AST now distinguishes `NiceNormalizedAil occurrence slot` from
`NiceInternal`. This replaces the misleading optional list named
`breakpoint_ail_path`. Occurrence/slot numbers are producer keys, not AST
ancestry paths or source-C provenance. Neither roles nor origins are runtime
certificates; source-level midpoint relations still need a producer theorem
and entry-sensitive invariants. The [composition example](breakpoint-composition.md)
and [charter](breakpoints-charter.md) state these limits.

Pause descriptors use `corenice-breakpoint-v2`, with an `origin` object carrying
its stage and keys. The comparator rejects old or malformed descriptors. No
persistent trace compatibility is promised for these research artifacts.

[AGENT 2026-11-16] Keep existing cut positions and name their actual normalized
phases. Carry typed origin keys rather than suggesting that lost source
structure has been reconstructed. Exact source-C body endpoints would require
separately transported source provenance and are not supplied by this repair.

## The legacy discrepancy is deeper than extra choices

The choice witness preserved at
`4f667f26b:lean_frontend/test/CoreNice/ReviewLegacyChoice.lean`
shows that preventing `to_pure` from erasing a cut changes the legacy `Eunseq`
alternative list from one to two. A stronger
[executable witness](../../test/CoreNice/ReviewLegacyErasure.lean) constructs:

```text
unseq [ strong_seq (_ : unit) (pure undef) unit, unit ]
```

In original legacy Core, `to_pure` and unused-pattern substitution discard the
undefined prefix and the run completes. At checkpoint `4f667f26b`, marking that
sequence in legacy Nice forced the prefix and reported UB. Original `rewrite_expr` also discards this
prefix. Optimized Core and optimized marked Nice both report UB, with no
breakpoint encounter. The probe checks all these outcomes against the actual
implementations. The current probe retains original legacy completion and
rewrite erasure, plus both active-path UB controls. The old Nice evaluator
and its two-engine choice probe have been removed; the old checkpoint preserves
their full reproduction.

This is a directly constructed Core-state witness, not an established
AIL-reachability theorem or an end-to-end legacy C counterexample. The
[GNU C control](../../../tests/corenice/review/pure_prefix_ub.c) exercises the
current optimized recipe and agrees on UB without reaching a cut.

Simply draining marked pure operands in a fixed order is not a full repair:
it can also move failure relative to effectful siblings or blocked waits, and
does not reproduce the pure evaluator's tuple traversal. Reconstructed
continuations matter as well as syntax. Exact successful-prefix cut semantics
cannot preserve arbitrary executions of a baseline that discards that prefix.

Both normal and resumable C drivers use `Core_reduction.step_ctx`, not the
legacy `Core_run.core_thread_step2`. The current lowerer does not invoke
`rewrite_expr`. The legacy path also has pre-existing unsupported stack and
annotation cases. The active-path differential evidence therefore does not
validate marked legacy execution or the optional simplifier.

**Resolution:** remove the owned `core_thread_step2` implementation entirely,
along with its private `core_action_step`, `core_step` and `action_request`.
There is no compatibility stub or silent fallback to another engine. Keep
`Core_run`'s shared procedure/state helpers, `E` helpers, `fs_oper` and
`core_tau_step_kind`, which the active reducer still uses. Direct jump tests
now exercise the active rule only. Original Core and its tests are unchanged.

[USER 2026-11-17] Subset CoreNice by removing cloned legacy evaluator support
after verifying that upstream and mainline production already use the other
engine. This removes an unnecessary compatibility obligation while preserving
the intended copied production pathway.

## Evidence before removal: phase checkpoint `4f667f26b`

All counts in this section describe `4f667f26b`, before removing the legacy
evaluator and its direct test arms. Current validation follows separately.

The phase-repair checkpoint regenerated all 57 CoreNice modules with pinned Lem compiler
`2220010bc25f0c5682d8200f016e786ee66d65c6`; the affected libraries, interpreters,
runner and test executables build. The existing shared concurrency
non-exhaustiveness warnings remain recorded in the historical checkpoint;
this work introduces no suppression.

The new [phase suite](../../../scripts/corenice-phase-tests.py) passes 14
bidirectional comparisons (56 interpreter executions): eleven defined controls
and three expected UB controls, 36 exact phase/effect-prefix checks and 105
actual pauses. It covers while/do/for normal and continue paths, nested switch
continue, break, return, false guards, goto entry, condition UB and increment
UB. Numbered output markers follow the effects they describe; checks inspect
the actual stdout prefix at each pause, final counters and typed origins.
No full state is serialized.

The existing focused breakpoint suite passes 212 bidirectional comparisons
(848 executions), including all six genuine three-call orders crossed with
all 16 subsets of four cuts. The recording lane sees 202 all-policy pauses:
136 normalized joins, 46 conditions, 16 while restarts and four do conditions.
The 44 Python instrument tests and quotation generator check pass. Direct
rule/driver controls and the stronger legacy witness were independently run.

All 111 non-libc minimal inputs pass the resumed comparison: 90 defined,
19 undefined, and two exact expected-allocator-OOM controls, with no unexpected
failures. The comesfrom suite passes nine exact bidirectional comparisons,
29 direct rule transitions, two original-error precedence controls and 27
injected typed faults. The composition demo retains its 15 heap midpoints,
pending-suffix and whole-artifact erasure checks, and detects all four mutations
(repeat-left, skip-suffix, extra-choice and lost-site).

An unrestricted reviewer inspected jump/breakpoint transport through
substitution, conversion, saved continuations and context reconstruction,
checked `Erun`, the retained nonmemory frontier and runner-session state. No
additional confirmed production defect emerged. The reviewer reproduced the
legacy outcome failure and confirmed optimized UB without a cut. That review
supports the phase repair, not a legacy-equivalence claim.

## Validation after removal

Regeneration of all 57 owned modules succeeded with the same pinned Lem.
`CerberusCoreNice`, `CoreNiceSeparationTests`, `CoreNiceDifferential` and the
affected interpreters, runner and test executables build successfully. The
removed definitions and their auxiliary imports are absent from generated Nice
sources. The active reducer and retained shared definitions are unchanged.

The following focused runs passed on the deletion candidate:

* All 14 phase cases: 56 interpreter executions, 36 exact effect-prefix
  assertions and 105 pauses, with the same eleven defined/three UB outcomes.
* Composition, saved-suffix entry and both sampled sibling-call orders under
  automatic and selected pause policies: 20 bidirectional comparisons,
  80 executions and 34 all-policy recording-lane pauses.
* Comesfrom: nine exact bidirectional comparisons, **15 active-rule transitions,
  one original-error precedence control**, and 27 injected typed faults.
  The former 14 legacy-rule transitions and legacy error control were removed.
* Direct breakpoint rule and driver tests, including binding, annotations,
  reconstruction, initializer/main handoffs, retained competing choices and
  cumulative budgets; 44 Python instrument tests and quotation generation check.
* The retained original-Core erasure witness and both active-path UB controls.

The first adapted witness run failed because its original legacy test frame
had accidentally been replaced by an empty stack. Review caught the same
fixture regression. Restoring the original frame made the witness pass;
the optimized controls continue to use their required empty stack.

Independent review confirmed the upstream/mainline call graph and found no
active dependencies among the deleted declarations. Its two findings were
fixed: the witness frame above and separation of historical 29/two counts
from current 15/one counts. No original-Core source or original unit test changed.

The earlier 1,000-program campaign is historical evidence, not a rerun of this
repaired tree. No full shipping or proof gate is claimed.

From a provisioned checkout after the normal pinned regeneration/build recipe:

```bash
python3 scripts/corenice-phase-tests.py
python3 scripts/corenice-breakpoints.py \
  --case composition --case suffix-entry --case sibling-calls
python3 scripts/corenice-incoming-tests.py
python3 -m unittest discover -s tests/corenice -p 'test_*.py'
python3 tools/generate_corenice_quote.py --check
(cd lean_frontend && ../scripts/lean_probe.sh test/CoreNice/ReviewLegacyErasure.lean)
python3 scripts/corenice-diff.py tests/corenice/review/pure_prefix_ub.c \
  --corenice-bin lean_frontend/.lake/build/bin/corenice-resume \
  --comparison breakpoints --summary-json
```

Use the host's optional cap wrapper for builds and heavier campaigns, as in the
normal provisioning guide. The harnesses bound subprocesses and remove traces.
