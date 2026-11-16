# CoreNice exploratory review: legacy alternatives and loop-role limits

Reviewed source: `5cfc65adb` (`corenice/breakpoints`). This review adds only
reproducers and this report. It changes no model, producer or runner.

## R1: marking pure operands adds legacy scheduler alternatives

**Confirmed failure of the no-added-choice/ordered-alternatives requirement
for the legacy evaluator.** The minimal synthetic expression is an `Eunseq`
whose two operands are `Esseq () unit unit`. Original Core has one enabled
`Eunseq pure` transition. Nice with `Continue` tails also has one. Changing only
those tails to distinct `Breakpoint` sites produces two `Eunseq` transitions,
one selecting each operand first.

The [executable probe](../../test/CoreNice/ReviewLegacyChoice.lean) imports both
actual implementations, installs a matching procedure definition in each file,
uses the procedure body as the arena and supplies its legacy call frame. It
checks both transition counts and descriptors. It does not assert a general
reachability theorem for these directly constructed configurations or run the
entire procedure to completion.

The cause is the interaction of two rules:

* [`core_aux.lem:1687`](../../../frontend/corenice/model/core_aux.lem):
  `to_pure` must reject marked sequences to retain their cuts.
* [`core_run.lem:1404–1427`](../../../frontend/corenice/model/core_run.lem):
  legacy `Eunseq` first tries `to_pures`, then offers one alternative for each
  operand that `to_pure` rejects. Marking alone therefore changes its alternatives.

This is a model-level discrepancy within the legacy rule path. It is **not**
evidence of different C return values or effects. Nor does it reproduce a
failure in the currently admitted differential recipe: `ExecutionNice.action`
uses `drive`, which uses `driver2` and `new_drive_core_threads`; those call
`Core_reduction.step_ctx`. The explicit-resume loop also calls `step_ctx`.
There is no call to `core_thread_step2` in the owned driver. The optimized
reducer does not use this `to_pure` test to select unsequenced contexts.

The existing direct legacy breakpoint test exercises a single marked sequence,
so it cannot detect this interaction. Either preserve the original choice
structure for marked legacy execution, or explicitly narrow the no-added-choice
claim to the optimized execution path. No remedy is implemented here.

## R2: a loop-body-done role does not imply source-normal completion

**Confirmed interpretation limit, not an erased-execution mismatch.** The
[ordinary C witness](../../../tests/corenice/review/continue_only.c) has one
loop iteration, which exits through `continue`. The resumed execution reports
one `loop-body-done` encounter. Original Core and resumed Nice still agree on
the complete compared observations.

[`erase_loop_control`](../../../frontend/corenice/model/translation.lem)
replaces the source body by a block containing that body followed by a generated
continue label (lines 3488–3492). The breakpoint at lines 4013–4018 marks
completion of this normalized wrapper. A continue enters its saved suffix and
reaches that cut without normal completion of the original source body.

The [composition mapping](breakpoint-composition.md) already describes the
generated wrapper and continue entry. This witness makes the consequence
explicit: `BP_loop_body_done` alone cannot establish a source-normal body
postcondition. The checkpoint's description of role totals as “normal body
completions” needs that qualification. A future relation must distinguish
normal and continue entries, or deliberately relate their normalized join.

## Reproduction and bounded evidence

From a provisioned checkout containing these review files:

```bash
(cd lean_frontend && ../scripts/lean_probe.sh test/CoreNice/ReviewLegacyChoice.lean)
python3 scripts/corenice-diff.py tests/corenice/review/continue_only.c \
  --corenice-bin lean_frontend/.lake/build/bin/corenice-resume \
  --comparison breakpoints --summary-json
python3 scripts/corenice-diff.py tests/corenice/review/pure_statement_expressions.c \
  --corenice-bin lean_frontend/.lake/build/bin/corenice-resume \
  --comparison breakpoints --summary-json
```

The first command prints `COUNTEREXAMPLE: Core=1, Nice/Continue=1,
Nice/Breakpoint=2 enabled legacy transitions`. Its successful exit means that
the discrepancy reproduced, not that correspondence holds.

The continue fixture completes defined in both record/replay directions with
seven pauses: four statement joins, two condition-ready and one loop-body-done.
The GNU statement-expression fixture is admitted by the shared frontend and
completes defined in both directions, with three pauses and zero genuine
choices. This is a useful optimized-path control, not an end-to-end legacy C
counterexample.

Five additional fixtures preserve the exact source text used for the focused
jump/control exploration. Each was compared under `all`, `none` and `every:2`
pause policies. The final two also used both the empty choice prefix (then
always choose zero) and prefix `1` (then always choose zero). All **21
comparisons**, each recording/replaying in both directions (**84 fresh
interpreter executions**), completed defined and agreed. No unexpected
`NiceFault`, mismatch or incomplete execution occurred.

| Fixture | Corner case | Prefixes | All / every:2 pauses per prefix |
| --- | --- | --- | --- |
| [duff.c](../../../tests/corenice/review/duff.c) | Switch entry into a do-loop body and case fallthrough | empty | 13 / 6 |
| [goto_if_loop.c](../../../tests/corenice/review/goto_if_loop.c) | Jump into a constant-dead if branch inside a loop, then continue | empty | 27 / 13 |
| [nested_cases.c](../../../tests/corenice/review/nested_cases.c) | Switch labels inside both branches of a conditional | empty | 4 / 2 |
| [pure_unseq.c](../../../tests/corenice/review/pure_unseq.c) | Both orders of sibling calls with pure statement joins | empty, `1` | 4 / 2 |
| [recursive_goto.c](../../../tests/corenice/review/recursive_goto.c) | Repeated saved-label entry in recursive activations, competing with a pointer-mutating sibling call | empty, `1` | 34 / 17 |

The `none` policy recorded zero host pauses in every case. The first three
fixtures had no genuine choices. The pure-call fixture consumed tapes `[0]`
and `[1]`; the recursive fixture consumed `[0,0,0,0]` and `[1,0,0,0,0]`.
These are sampled complete paths, not enumeration of every path or every pause
schedule. They test conservative/tightened incoming metadata together with
breakpoint transport and resumption; agreement does not prove either producer
sound or distinguish every internal jump transition.

Reproduce the 21 comparisons from this checkout using a provisioned candidate
checkout for binaries and the comparator. Set `candidate` to its repository
root; it may also be this checkout after normal provisioning. The five C
sources come from the current checkout and the candidate remains unchanged:

```bash
candidate=/path/to/provisioned/corenice-checkout
(
  set -e
  cap() { if command -v capped >/dev/null 2>&1; then capped "$@"; else "$@"; fi; }
  for source in duff goto_if_loop nested_cases pure_unseq recursive_goto; do
    prefixes=("")
    case "$source" in pure_unseq|recursive_goto) prefixes+=("1");; esac
    for policy in all none every:2; do
      for prefix in "${prefixes[@]}"; do
        cap python3 "$candidate/scripts/corenice-diff.py" \
          "tests/corenice/review/$source.c" \
          --corenice-bin "$candidate/lean_frontend/.lake/build/bin/corenice-resume" \
          --comparison breakpoints --choices "$prefix" --summary-json \
          --corenice-arg=--pause-policy --corenice-arg="$policy"
      done
    done
  done
)
```

The recorded focused runs used the already built binaries and imported modules
from the reviewed checkout. The review probe can be passed by absolute path
to that checkout's `scripts/lean_probe.sh`, run from its `lean_frontend`
directory; no source copies or rebuilds are required. No full campaign or proof
landing checks were run for this review. Passing bounded cases do not establish
general Core/Nice equivalence or soundness of incoming-origin tightening.
