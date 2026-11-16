# CoreNice checkpoint semantics: repair assessment

Work branch: `corenice/checkpoint-semantics-repair`, based on breakpoint
checkpoint `5cfc65adb`. This is research work, not an equivalence theorem or a
mainline landing. The [initial review](noodler-review.md) supplies the first
counterexamples. This assessment separates repairs to the active machine from
an unresolved legacy-evaluator design choice.

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

The original [choice witness](../../test/CoreNice/ReviewLegacyChoice.lean)
shows that preventing `to_pure` from erasing a cut changes the legacy `Eunseq`
alternative list from one to two. A stronger
[executable witness](../../test/CoreNice/ReviewLegacyErasure.lean) constructs:

```text
unseq [ strong_seq (_ : unit) (pure undef) unit, unit ]
```

In original legacy Core, `to_pure` and unused-pattern substitution discard the
undefined prefix and the run completes. Marking that sequence in legacy Nice
forces the prefix and reports UB. Original `rewrite_expr` also discards this
prefix. Optimized Core and optimized marked Nice both report UB, with no
breakpoint encounter. The probe checks all these outcomes against the actual
implementations; a passing probe means the discrepancy was reproduced.

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

**Unresolved decision:** explicitly refuse breakpoint-bearing legacy inputs
and support checkpoints on the optimized path, or expand scope to repair and
reassess the original legacy semantics. The former is recommended. An agreed
refusal needs to happen before offering choices or effects, including cuts
stored in procedures and continuations; rejection at the first encountered
marked sequence would be too late. No such refusal has been implemented yet.

## Focused evidence

The phase repair regenerated all 57 CoreNice modules with pinned Lem compiler
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
supports the phase repair, not the unresolved legacy claim.

The earlier 1,000-program campaign is historical evidence, not a rerun of this
repaired tree. No full shipping or proof gate is claimed.

From a provisioned checkout after the normal pinned regeneration/build recipe:

```bash
python3 scripts/corenice-phase-tests.py
python3 scripts/corenice-breakpoints.py
python3 scripts/corenice-minimal.py \
  --corenice-bin lean_frontend/.lake/build/bin/corenice-resume --comparison breakpoints
python3 scripts/corenice-incoming-tests.py
python3 -m unittest discover -s tests/corenice -p 'test_*.py'
python3 tools/generate_corenice_quote.py --check
(cd lean_frontend && ../scripts/lean_probe.sh test/CoreNice/ReviewLegacyChoice.lean)
(cd lean_frontend && ../scripts/lean_probe.sh test/CoreNice/ReviewLegacyErasure.lean)
python3 scripts/corenice-diff.py tests/corenice/review/pure_prefix_ub.c \
  --corenice-bin lean_frontend/.lake/build/bin/corenice-resume \
  --comparison breakpoints --summary-json
```

Use the host's optional cap wrapper for builds and heavier campaigns, as in the
normal provisioning guide. The harnesses bound subprocesses and remove traces.
