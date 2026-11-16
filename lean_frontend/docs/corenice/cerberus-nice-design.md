# Cerberus-Nice: restart design

Design proposal, 2026-11-14. See [current implementation progress](README.md#current-evidence-and-next-experiment)
for the completed pieces and their limits. Read the [first-project roadmap](cerberus-nice-roadmap.md)
for the implementation order and concrete acceptance examples.
The first step is now specified by the [complete CoreNice scope](corenice-baseline-scope.md),
which replaces the earlier driver-only duplication and parent-owned build.

## What we are trying to build

Cerberus-Nice will be a program language and an operational semantics. Its
purpose is to expose control boundaries that make later refinement proofs
compositional. A Nice program must contain ordinary, inspectable syntax; its
driver must execute that syntax. A driver wrapper, an annotation report, or a
datatype containing arbitrary Lean computations does not deliver this.

The eventual producer has two targets from the same typed AIL input:

```text
C source -> Cabs -> typed AIL + configuration + fresh supply
                         |                       |
                  existing lowering        Nice lowering
                         |                       |
                    Core program             Nice program
                         |                       |
                    Core driver              Nice driver
                         |                       |
                    observed run <--------> observed run
```

The longer-term goal is a refinement/bisimulation for the supported producer
image, including runtime support procedures, with explicitly specified
observables and administrative erasure. The first project tests this conjecture;
it does not prove it. It also does not solve the Caesium correspondence or repair
the known incorrect contract B.

**First, build the complete unchanged CoreNice path that will become Nice.** Give
it distinct syntax, AIL lowering, pure/reduction/control machinery and driver,
plus the generation and differential infrastructure needed for later changes.
CoreNice initially mechanically duplicates Core; shared frontend and low-level
services are explicit. Test both tape-recording directions and source-level
mutants before changing its semantics. Agreement supports the duplicated path
and instrument; it cannot independently validate defects in their common source.

## Baseline and source evidence

Inspected parent: `f12c3f1f64a2ac0249e1440dbf7d2fbab63ec7a2`.
Dependency: refinedc-lean `b6ce9de608e741cd9b8c5c116a5b93200d677554`.
Cerberus provider: `03c8b4451ff08830306d687e639f7dc57baf6827`.
Lem source: `e6d8db5680962f49060257d6c2bcb13c284b910f`; Lean 4.35.0.
These are inspection baselines, not new test results.

These inspection identities and the archive/plan branches below belong to
the cerberus-caesium parent workspace. The chosen cerberus-lean development
base is recorded in the CoreNice scope. Source locations below are relative to
the provider repository root at the inspected revision:

| Finding | Source anchor | Design consequence |
|---|---|---|
| Core already has first-order effect syntax. | `frontend/model/core.lem:319–343` | Copying a driver computation into an AST is unnecessary. |
| Procedures, globals, thread arenas and saved continuations embed Core expressions. | `core.lem:351–357,395–434`; `core_run_aux.lem:28–75` in the same model directory | Nice needs its own program/control containers, not just one additional expression constructor. |
| The active path uses context decomposition and the new driver loop. | `core_reduction.lem:562,644,1126`; `driver.lem:951,1073,1285,1408,1498` | Follow `get_ctx`/`apply_ctx`/`step_ctx` and `driver2`, not only the old `core_thread_step2`. |
| Nondeterminism is exposed as nodes and successor computations. | `nondeterminism.lem:42–57`; `lean_frontend/CerbND.lean:117–295` | A small external traversal can select and record choices without rewriting the reducer. The shipped trace runner is branch-zero-only. |
| Existing driver traces contain memory operations and some returns. | `trace_event.lem`; `driver.lem:694–717,951–975` | Compare these event payloads, not full machine states. A declared event constructor is not evidence that the driver emits it. |
| Concrete memory already has opt-in load/store receipts. | `lean_frontend/CerbMem.lean:220–252,2639,2742`; `CerbMemAccessFacts.lean:120–168` | Byte/provenance observations can be added later using this seam. Existing erasure facts concern particular operations, not arbitrary whole-program instrumentation. |
| AIL translation is concretely Core-producing. | `translation.lem:1496,3832,4763` | Two targets require real elaborator work. Lem's OCaml/Lean backends do not provide two semantic target languages. |
| Pure evaluation consumes metadata from a Core file. | `core_eval.lem:118–162,578,650–653,864–909` | Duplicate the evaluator with B's own file type; sharing the original evaluator would leave the target path incomplete. |
| Runtime support includes effectful Core procedures. | `runtime/libcore/std.core:101`; `lean_frontend/Main.lean:1297–1307` | B needs its own parser/builders and executable support bodies from the same runtime text. |

The next breakpoint milestone is governed by the [breakpoint charter](breakpoints-charter.md),
which specifies source-aligned placement, the intended simulation handoff and
the differential-first work order. It supersedes the earlier combined-demo
ordering below; the baseline pathway and comesfrom feature now exist.

## Representation and source language

Build **parallel owned Lem definitions for CoreNice's whole target path**, then
modify those sources into Nice. Keep handwritten Lean support/proof interfaces
beside generated modules. The generation/co-import experiment comes first:
the [initial AST/linker/support closure](type-separation.md) and subsequent
[full target path](interpreter-runner.md) have been built and tested. Development belongs
on a research branch of the cerberus-lean fork.

The checked-in Lem sources are the executable authority in the provider. The
ordinary Makefile generates from them (`Makefile:146–160,227–233,352–369`). The
historical Ott grammar omits current constructors and fields; regenerating Core
from it would be a separate repair project. Do not make that a prerequisite.

Lem can import existing definitions without regenerating them (`-i`,
`deps/refinedc-lean/.lake/packages/LemLib/src/main.ml:150`). Its Lean name-renaming
declarations are exercised in `tests/comprehensive/test_target_reps.lem:42,50`
in that package. Use distinct Nice names so the two languages coexist in one
Lean development. Generation is neither an equivalence proof nor an independent
semantic oracle. Recursive totality and fuel still need deliberate treatment.

Try deterministic namespace packaging before changing Lem. If it cannot retain
correct resolution for generated and handwritten support, identify the precise
obstruction and cost a small namespace feature. A larger generator project or
a different source language needs an explicit reassessment; it must not quietly
replace the complete CoreNice milestone with a smaller driver wrapper.

### The actual AST

The unchanged CoreNice baseline already provides a distinct recursive effect type
corresponding to `Epure`, `Ememop`, `Eaction`, `Ecase`, `Elet`,
`Eif`, `Eccall`, `Eproc`, `Eunseq`, `Ewseq`, `Esseq`, `Ebound`, `End`, `Esave`,
`Erun`, `Epar`, `Ewait`, `Eannot` and `Eexcluded`. Initially duplicate the whole
Core syntax module, including its pure expressions, patterns and value wrappers;
share target-independent C types, symbols and memory values. Copy the complete
required implementation, while honestly limiting the tested C/configuration
domain. Nice then changes this existing B syntax and its actual producers and
consumers; no second miniature interpreter is built from scratch.

After the unchanged CoreNice milestone, add only two first Nice improvements:

* A `Breakpoint` AST node admitted only in specified syntactic positions.
  Initially that position is the continuation of a strong sequence.
* A checked jump and label declaration: the jump has a stable syntactic origin;
  the destination declares its permitted incoming origins. The executing rule
  obtains the actual origin from the node being executed, not an arbitrary
  caller-supplied value. It checks the active procedure/label binding too.

Use separate syntactic categories to express the restriction. In schematic
notation (not an existing implementation):

```text
NExpr       ::= ... | NStrongSeq pattern NExpr StrongTail
StrongTail  ::= Continue NExpr | Breakpoint id NExpr
```

`NStrongSeq pat effect (Breakpoint id continuation)` is a program AST containing
an explicit pause point. `Breakpoint` is not a general expression constructor:
it cannot be used as an arbitrary operand or unsequenced alternative. Invalid
placement is unrepresentable in this AST and rejected by its input decoder.
This is not a generic checkpoint node followed by a placement validator.
Every recursive effect child is Nice syntax. Procedure bodies and global
initializers use that same type. Exact constructor spelling can change; the
syntactic restriction cannot disappear into an external convention.

Nice contexts/frames describe pending effect control. Internal memory/ND
functions may remain higher-order; eliminating every service callback is not
required for a first-order program AST. However, checkpoints suspend at explicit
Nice control boundaries, with a resumable control state owned by the Nice
machine. A residual closure containing the entire old driver is insufficient.

Start by preserving Core's sequencing/unsequencing rules. Do not flatten
`Eunseq` to a fixed order or turn all continuations into a conventional CFG.
Negative-action and boundary rules are part of the semantics. Saved-label
suffix reconstruction (`core_aux.lem:2278`, `core_reduction.lem:1450–1481`) is a
later candidate for replacing computed continuations by explicit code tables,
after the smaller syntax changes are tested.

### Execution ownership

| Component | First ownership choice |
|---|---|
| C types, symbols, memory/FS primitives, generic ND vocabulary | Share the provider services explicitly. |
| CoreNice/Nice syntax, pure evaluator, procedures/globals, contexts, labels, current control | Own the complete target-dependent path. |
| Nice reduction and driver dispatch | Edit the already tested CoreNice clauses to execute the changed syntax directly. |
| Pure evaluator's file metadata | Read the target's own file, initially copied unchanged with its evaluator. |
| Effectful runtime procedures | Parse the same runtime text through B's parser/builders and execute the resulting target bodies. |
| Linking | Own the B linker; initially test one translation unit and fixed runtime. Copying the linker does not establish general multi-TU validation. |

There must be no path that implements the complete Nice program by erasing it
and calling the original `drive`. Erasure is for specification, diagnostics and
test comparison. Shared primitive evaluation is intentional and visible.

An explicit `RawCore` escape hatch remains a future option for difficult
fragments. It is not the first implementation strategy, and a program executed
entirely by that escape hatch cannot count as a Nice demo.

## Lowering and admission

The complete AIL-to-CoreNice lowering is established during the unchanged baseline,
including the target-dependent elaboration helpers. Later Nice work edits that
producer where it has the needed information. For example, an existing strong
sequence can receive a `Breakpoint` tail without reconstructing AIL structure
after lowering. Keep changes narrow and retain the paired original route.

Do not implement this as AIL-to-Core followed by an imported whole-program
wrapper. A structural B-to-Core map is useful for baseline artifact comparison,
erasure and future statements, but is not the executable target path. Sharing
or factoring duplicated elaboration later is a separately validated change.

A real two-target demo must have a typed AIL input, a Core artifact, a separate
Nice artifact containing the new nodes, and runs of both. Artifact inspection
must show that the Nice driver visits those nodes. More elaborate loops or
lexical regions are not required merely to establish this architecture.

Admit a declared subset. Validate program forms and configuration before running
where possible; dynamically discovered unsupported behavior is an incomplete
comparison, not equivalence or UB. Refusals remain in coverage reports.
For uncertain dummy-type metadata, refusal to produce Nice is a retained option;
no theorem about the rarity or impossibility of refused outputs is needed.
No runtime type checks relying on that unsettled contract are in this project.

## Breakpoints and checked control: local contracts

The `Breakpoint` tail is reached after the strong sequence's left computation
has completed and its original completion rule has succeeded, before the right
continuation executes. Preserve pattern validation/binding, environment updates
and dynamic-annotation propagation, including the `Eannot` completion case
(`core_reduction.lem:437–462`). Failure or UB on the left does not reach it. It
emits a Nice-only observation and can either continue or return an in-memory
suspension containing the same semantic resources, annotated continuation,
context and driver phase. Resume consumes that suspension without repeating
the breakpoint, the completion rule, the preceding effect or an already-consumed
nondeterministic choice. Source-level loops may reach the same breakpoint again;
identify an occurrence by run path plus visit count. There is no disk snapshot,
state serialization, external mutation while paused, or restart-from-C startup.
Erasure maps both `Continue e` and `Breakpoint id e` to `erase e` in the original
strong sequence. Insert only at existing strong-sequence positions initially;
do not strengthen weak or unsequenced operations just to create a pause point.
The syntactic position does not by itself prove suspension is harmless. A
strong sequence can occur inside an unsequenced expression: the breakpoint must
not become an additional runnable alternative. The driver suspends at the
strong-sequence completion phase and resumes that exact phase. If the original
driver would next perform a new scheduling choice, the resumed driver performs
that choice once; it neither repeats an earlier choice nor forces the right
continuation to execute before its siblings. Test this nested case explicitly,
without claiming lexical-scope information.

With the same subsequent choice plan, an uninterrupted Nice run and one paused
and resumed at breakpoints should have identical retained traces and outcomes
after erasing breakpoint/pause/resume observations. Test available
strong-sequence boundaries around effects, in a repeated loop, and around a
helper call; do not promise a breakpoint at every arbitrary source location.
The representation should
also make a small Lean transition lemma expressible directly; a general
pause/resume theorem is later work. Fuel exhaustion is inconclusive, and equal
numerical fuel across changed machines is not an equivalence requirement.

An invalid incoming jump produces a distinct, structured `NiceFault`. Its typed
payload carries the resolved procedure, origin and label, source locations and
the permitted set used by the check, as specified in [comesfrom](comesfrom.md).
It is not erased, converted to a successful stop, or equated with original UB.
Correct translation is expected to produce no such fault on corresponding
executions. This makes incorrectly generated declarations visible to testing.
Eventually equivalence for admitted producer output must establish that checks
never introduce extra faults; adding checks alone proves no preservation.

## What the tests mean

The comparison contract and explicit choices are specified in the roadmap.
Diagnostic traces retain more than final external behavior: memory-operation
arguments/results, available call/return information, branching and outcomes.
That strengthens counterexample finding, but does not settle the final language
semantics' observable projection.

Write `observe(CoreRun(p, choices)) = erase(observe(NiceRun(n, choices)))`
only for complete tested runs with matched configuration and a declared choice
correspondence. Erasure removes only listed Nice administrative events. It must
not discard faults, UB, memory effects, extra branches or unmatched terminations.
All-choice coverage is claimed only for a finite completely explored fixture;
larger tests report their selected paths and omissions. A future bisimulation
also needs coverage of all choices, divergence and progress against infinite
administrative stuttering. Passing sampled traces does not provide that.

## Deferred research

Lexical scope reconstruction, heap/type invariants, structured-loop recovery,
footprint-certified sequentialization, symbolic states, concurrency, broad libc
and general multi-TU linking are deferred. These are substantive semantic
questions. Their apparent syntax or a few fixtures do not establish invariants.
The checkpoint and predecessor experiments should give us a useful machine and
test instrument before committing to any of them.

## Branch and archive decisions

* [USER, 2026-11-14] Restart from main, preserving the previous prototype as an
  archive. Establish unchanged Core-versus-Core testing before Nice changes;
  prepare and critically review the proposal before implementation.
* [AGENT, 2026-11-14] Preserve old combined work at
  `archive/cerberus-nice-driver-prototype-20261114`, commit
  `1b1994876c0eb42a71dea27b16f54bac1f2712a4`. Start this proposal on
  `plan/cerberus-nice-restart` from the inspected main. Only the previously agreed
  development-policy corrections are carried over so far.
* [USER, 2026-11-14] Express permitted pause points using a `Breakpoint` AST node
  restricted to designated syntactic positions, initially strong sequencing.
  The language structure carries placement, rather than an external validator.

The earlier driver-only proposal is superseded by the complete CoreNice scope;
its review remains historical evidence for that narrower proposal, not approval
of the new implementation boundary.

The old `feature/cerberus-nice` and `nice/m*` refs remain historical. They are not
the base or the acceptance evidence for this restart. The roadmap contains the
[salvage assessment](cerberus-nice-roadmap.md#what-to-reuse-from-the-archive).
