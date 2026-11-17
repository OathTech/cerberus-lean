# Saturated control boundaries for AIL output

Experimental implementation on `corenice/breakpoint-saturation`, based on
`6e54eadd1`. The existing AIL composition-cut runner remains available; the new
`corenice-saturated` runner executes the linked program after a saturation pass.
Both use the same CoreNice AST, production reducer and resumable driver.
This checkpoint landed locally on `feature/cerberus-nice` on 2026-11-17 at
`e75c895c0`. It has not been pushed or pinned by a consumer.

## The intended calculus boundary

The goal is finite, syntax-directed control-flow fragments between composition
boundaries. Calls and loop/control re-entry end a fragment. Callee execution is
reasoned about separately, and returning exposes the caller's continuation.
This is not a wall-clock bound or a claim that a primitive operation's internal
implementation takes a fixed number of reductions.

For accepted, linked AIL output in the supported sequential recipe, the new
pass establishes these syntactic conditions:

* Every executable procedure, including the loaded Core runtime, begins with
  an explicit entry cut.
* Every saved-label body begins with an entry cut. Thus every syntactic `Erun`
  target has a cut, including generated loop and return labels.
* Every C call and named Core procedure call carries an explicit cut on its
  return continuation. Recursion cannot hide an arbitrarily long return chain
  inside one fragment.

Between these boundaries the remaining effectful control follows finite AST
structure. Pure evaluation, memory requests and `Eproc Impl` primitives are
the summarized instructions at this granularity. Their semantics still matter:
the coverage checker does not prove pure-helper termination, primitive
termination, a uniform bound on their internal work, or a general AIL/CoreNice
equivalence theorem. Such facts cannot be obtained merely by checking the CFG.

This replaces the weaker initial proposal of covering recursive descent with
procedure entries alone. Entry-only coverage would leave long finite unwind
chains and would not expose the intended call/return composition boundary.

## Concrete gaps in the earlier placement

Before this extension, these accepted C inputs could run without reaching any
breakpoint:

```c
int main(void) { again: goto again; }
```

```c
void recur(void) { recur(); }
int main(void) { recur(); }
```

At budget 2,000 the old runner exhausted model fuel with zero pauses on both.
An ordinary empty `while (1)` reached 399 cuts at that budget. These observations
are finite prefixes; the source/control structure explains the uncut cycles.
The fixtures and increasing-budget probes now live in
[`tests/corenice/saturation`](../../../tests/corenice/saturation).

## Syntax and execution

Entries use the existing restricted strong-tail syntax:

```text
Esseq (_ : unit) unit (Breakpoint entrySite, originalBody)
```

The prefix has no binding or effects and consumes no semantic fresh symbol.
The original body and its annotations remain intact. The new entry roles are
`BP_procedure_entry` and `BP_label_entry`; their origin is `NiceInternal`, not a
claim to be a recovered AIL statement or lexical boundary. This is a deliberate
extension beyond marking only pre-existing sequences. Structural comparison
erases exactly this canonical administrative wrapper, in addition to erasing
the existing breakpoint controls. An ordinary source sequence is retained.

The label wrapper is **inside** `Esave`'s body. The actual saved-continuation
collector keeps that body, so an `Erun` reaches the cut. Putting a cut merely
before the `Esave` header would let jumps bypass it.

Calls pair their original annotation with a restricted return control:

```text
Eccall (annotation, Continue | Breakpoint returnSite) ...
Eproc  (annotation, Continue | Breakpoint returnSite) (Sym procedure) ...
```

This is explicit AST syntax in a call-return position. It does not add an
arbitrary breakpoint expression. The selected call stores its return control
in the existing `Stack_cons2` frame. On return the existing transition restores
the caller context, environment and value; the cut is then exposed before the
caller advances further. C-function return observations are retained. Runtime
procedures without C `funinfo` also expose their marked returns.

Call selection is unchanged: a callee-entry cut happens after the original
call has been selected. The marker does not introduce another call choice or
give a deferred call priority over competing work. Return suspension retains
the same driver phase and choice session as other breakpoints.

Primitive `Eproc Impl` calls do not create these procedure-return frames. The
producer leaves them unmarked, and a manually marked primitive is explicitly
rejected as an ill-formed program before either filesystem or ordinary
primitive dispatch. No silent ignored return marker is supported.

## Producer, well-formedness and comesfrom

[`Saturation.insert`](../../differential/Saturation.lean) operates on the linked
program after conservative incoming annotation and structural tightening. It
covers both `stdlib` and `funs`, and call sites in global initializers. Duplicate
definitions retain identical generated cuts. Existing AIL composition sites
remain unchanged; new IDs use a separate diagnostic supply above the existing
IDs and do not alter Cerberus's symbol supply.

`Saturation.check` checks the actual entry shapes and call-return slots, both
before and after runtime conversion. This is a small structural coverage check
over an otherwise admitted program, not a replacement for typing, linkage or
incoming-edge validity. Parallel execution and unsupported saved-label
contexts are explicit refusals in this recipe.

The checker does not use permitted-origin sets to delete edges. It covers
**all** syntactic saved-label targets. An incorrect comesfrom annotation must
not make coverage appear faithful merely by turning a Core cycle into
`NiceFault`. The same finite comparisons and looping probes therefore require
the ordinary outcomes or continuing progress without unexpected faults.

Comesfrom can support a later, less conservative placement: construct the
original syntactic transfer graph, check incoming-edge declarations against
that graph, and ensure every cycle crosses a cut. The current pass chooses the
simple sufficient placement instead of trying to minimize cutpoints. Immediate
incoming origins describe edges; they do not certify complete path feasibility.

## Validation and commands

The owned Lem sources regenerated all 57 modules with the pinned compiler;
the model, comparison instruments, runners and direct tests compile. No Lem
compiler change or original Core semantics edit was needed. The earlier
shared concurrency-generation warnings remain outside this sequential recipe;
no new Lean build warnings or warning suppressions were introduced.

Focused evidence:

* 45 complete bidirectional comparisons / 180 interpreter executions, with
  630 pauses. These cover deep returns, indirect recursion with a finite base
  case, runtime string-helper recursion, saved-label entry, abrupt failure and
  all six orders of three competing calls, under all/none/every-second pause
  policies. All ordinary cases require a defined outcome; only the two
  deliberate UB fixtures require an undefined outcome. Matching model errors
  are failures. Marked C returns retain their function-return observations.
* Twelve incomplete progress probes: self/mutual goto, goto inside a structured
  loop, and direct/mutual/indirect recursion at budgets 1,000 and 2,000. Each
  reaches repeated cuts, and the larger budget reaches more. Resource exhaustion
  is reported as incomplete, never as equivalence or a divergence theorem.
* Direct tests check missing-cut rejection, duplicate-definition identities,
  the actual collected label target, runtime procedure entry, restoration of
  the exact caller environment/residual, and runtime primitive-marker refusal.
* Four paired artifact/calibration cases erase to the original complete Core
  artifact and preserve symbol supplies. Their ordinary executions agree with
  the existing runner and passive-observation-disabled execution: one path each
  for composition, deep return and runtime strings, and all six call-order paths.
* Existing breakpoint-rule/driver tests and 44 Python instrument tests pass;
  the generated quotation instrument is current.
* The unchanged AIL-composition policy passes 20 further bidirectional
  comparisons / 80 executions for composition, saved-suffix entry and both
  sibling-call schedules. The final comment-only regeneration and incremental
  build passed. The saturation campaign was then rerun after the expected-
  outcome check described below; only documentation changed afterward.

From a provisioned checkout, using the normal optional memory-cap wrapper:

```bash
make corenice-prelude-src
(cd lean_frontend && lake build CerberusCoreNice CoreNiceDifferential \
  corenice-saturated corenice-saturation-tests corenice-pair-check)
LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/corenice-saturation-tests
python3 scripts/corenice-saturation.py
python3 scripts/corenice-breakpoints.py \
  --case composition --case suffix-entry --case sibling-calls
python3 scripts/corenice-diff.py tests/corenice/saturation/deep_return.c \
  --corenice-bin lean_frontend/.lake/build/bin/corenice-saturated \
  --comparison breakpoints --summary-json
```

The standard pair-check command accepts a final `saturated` argument to use
this producer and check complete artifact erasure plus existing-runner
calibration. See the [runner instructions](interpreter-runner.md) for its normal
runtime/Cabs/fuel/address-space/path-bound arguments.

Independent unrestricted review found no remaining concrete semantic
counterexample in the admitted saturated pathway. It identified the marked
primitive boundary, now rejected and directly tested, and requested C-return
observation and caller-restoration controls, now included. This remains a
validated experimental design with explicit coverage limits, not a proof of
universal saturation or correspondence. A final review found that the campaign
could accept matching model errors as finite successes. It now checks each
fixture's declared outcome before reporting success; all 45 comparisons were
rerun successfully. Ad hoc injected model-error and unexpected-UB comparator
results both fail the campaign. No full shipping gate is claimed.

## Direction

* [USER, 2026-11-17] Cover control-flow gaps where a principled semantic change
  is available. Target AIL-produced programs and finite syntax fragments between
  call/loop composition points; investigate incoming-origin information as
  part of syntactic well-formedness.
* [AGENT, 2026-11-17] Keep AIL composition cuts and add a saturation pass over
  the linked runtime/program: procedure entry, saved-label entry and explicit
  call-return cuts. Use conservative structural coverage independent of
  incoming-set pruning; validate the variant through a separate runner.
* [USER, 2026-11-17] Accept effectful control fragments as the current boundary:
  pure evaluation and primitive operations retain their existing semantics
  without internal cuts. Differential testing should validate trace
  correspondence and pause/resume at that boundary; internal termination and
  universal coverage remain separate obligations.
