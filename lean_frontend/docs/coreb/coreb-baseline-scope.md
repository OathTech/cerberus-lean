# CoreB baseline: the complete future Nice path

Scope proposal, 2026-11-14. Implementation has not begun. This supersedes the
driver-only twin in the earlier plan. CoreB is the entire AIL-to-execution path
we will subsequently modify into Nice, initially with unchanged semantics.

```text
                       shared prepared typed AIL
                        /                     \
              Core translation         CoreB translation
                     |                         |
                Core program              CoreB program
                     |                         |
              Core interpreter         CoreB interpreter
                        \                     /
                  observations + choice protocol
                                |
                  differential/fuzz/mutation runner
```

CoreB has its own AST, program containers, elaboration, linking/conversion, pure
and effectful evaluation, control state and driver. Both ASTs must coexist in
Lean for later relations/proofs. A second executable over the original AST or
reducer, a type alias, or erasure followed by original execution fails this
milestone. Shared low-level services are explicit. No breakpoint, predecessor,
scope or sequencing changes are included yet.

## Repository and build ownership

**Develop in an independent clone of the existing cerberus-lean fork.**
The development clone is `deps/cerberus-lean` within the cerberus-caesium
workspace, with its own Git object store and build directories. Its origin is
`https://github.com/OathTech/cerberus-lean`, whose mainline is
`mdd/cerberus-lean`. The long-lived `feature/cerberus-nice` integration branch
now contains this proposal. Implement this step on milestone branches/worktrees
against it; `coreb/baseline` is the proposed first milestone branch.
This clone is an explicitly authorized development repository, separate from
the installed provider in `deps/refinedc-lean/.cerberus-ws`.

The original source audit used provider
`03c8b4451ff08830306d687e639f7dc57baf6827` and Lem
`e6d8db5680962f49060257d6c2bcb13c284b910f`. For integration setup, freeze the
examined development mainline `8fa3050bf73fe92803f56c49ca53ed00d76aee88`, with
its Lem pin `2220010bc25f0c5682d8200f016e786ee66d65c6` and Lean 4.35.0.
The intervening commits change reporting, generator warning cleanup/pins and
validation tooling; the Core model and handwritten Lean sources are unchanged.
The new generation baseline still needs its own experiment and measurements.
The reference must not move during a comparison campaign, and consumer pins
remain unchanged.

The fork owns the model sources, handwritten Lean support, runtime text, native
objects, generation recipes and C corpus. Keep the two targets and harness in
one revision there. A parent-owned semantics package would instead make
cerberus-caesium maintain a second Cerberus distribution; refinedc-lean owns the
source logic and is not the right home for this target-semantics experiment.

| Location | Role |
|---|---|
| Owned cerberus-lean clone / milestone worktrees | CoreB source, generation/build, instrumentation, corpus/generator, mutation tests and reproduction instructions. |
| cerberus-caesium | Original proposal/archive and later refinement consumers; no experimental provider override. |
| refinedc-lean | Unchanged during the experiment; adopts a reviewed provider revision through its ordinary pin later. |
| Installed `deps/refinedc-lean/.cerberus-ws` | Read-only dependency, never the development checkout. |
| Lem repository | Unchanged initially; a bounded naming-support change is a separate proposal if needed. |

Use the existing fork's remote for a draft integration PR targeting
`mdd/cerberus-lean`. Publishing the branch for research review does not authorize
a mainline merge or consumer re-pin. Development and validation precede adoption.
The clone/setup change is documentation only; implementation has not begun.

Keep the existing checkout-local `lean_frontend` Lake package, adding a
`CerberusCoreB` library and two differential executables alongside the normal
targets. Give B distinct module and declaration names. Build artifacts belong
to this worktree: no symlink to the parent's dependency build state or another
agent's mutable caches. Provision using the fork's standalone instructions and
project-local tools; the Lem executable and LemLib revision must agree.

Proposed layout, subject to the first generation experiment:

```text
frontend/model/                  original Lem sources, unchanged
frontend/coreb/model/            owned target-dependent Lem source copies
lean_frontend/coreb/             owned handwritten support and entrypoints
lean_frontend/differential/      shared frontend adapter, observations, tapes
lean_frontend/generated/CoreB/   generated B modules
tools/generate_coreb.py          explicit source/module mapping and emission
scripts/coreb-diff.py            comparison/campaign orchestrator
tests/coreb/                     fixtures, C generator, mutation controls
```

## What must be duplicated

Make a one-time provenance-preserving copy of the target-dependent source
closure. These are owned B sources, consumed by its ordinary build. Do not
overwrite them from current Core on every build: later Nice work edits them.
The initial source mapping must preserve semantic bodies, diagnostics,
evaluation order and fuel behavior; only packaging/name resolution differs.
Before calling the baseline unchanged, compare its owned Lem/handwritten
sources against the pinned originals using the explicit copy map. Lem bodies
should be byte-identical; remove only documented mechanical packaging/import
changes when comparing generated/support bodies. Check the original generated
outputs too. Every residual semantic difference is a failure to explain/fix,
not a new normalization rule. This is a small baseline/source-identity report,
not a recurring whole-repository proof gate.

Source inspection found about 18 main generated modules (roughly 30,650 lines
before auxiliary proofs). This is mostly mechanical duplication, not a proposal
to rewrite or prove all that code. The closure includes hidden support:

| Family | B-owned modules/components |
|---|---|
| Syntax and program data | Full `Core`, including values, pure expressions, patterns, actions, effects and file/declaration types. Avoid a new shared-AST factoring project first. |
| Traversals, typing and linking | `Core_aux`, `Core_linking`, `Core_typing`, `Core_typing_aux`, `Core_typing_effect`. |
| Producer | `Translation`, `Translation_aux`, `Translation_effect`; full typed-AIL lowering with the returned supply. |
| Interpreter | `Core_run_aux`, `Core_eval`, `Core_run`, `Core_reduction`, `Core_reduction_aux`, `Driver`. |
| Less obvious concrete-Core interfaces | `Errors`, `Pp`, `Formatted`. Mixed modules may initially be copied as units. |
| Handwritten execution support | `CerbPP`, `CerbCoreShape`, `CerbCoreMeasure`, `CerbFunMapInstances`, `CerbStepInstances`, `CerbMeasureLemmas`. |
| Required auxiliary/totality support | Corresponding `Core*_lemMeasureProofs`, `Driver_lemMeasureProofs`, `Translation_lemMeasureProofs`, `Formatted_lemMeasureProofs` and generated auxiliary bindings. |
| Runtime input | B `CoreParser` and loader builders for the same standard-library/implementation text. |

Close this inventory through actual signatures, target representations and
elaborated dependencies. Duplicate optional transforms such as `Core_rewrite`,
`Core_indet` or `Core_sequentialise` if a selected execution recipe uses them;
they are not on the ordinary translate/drive route. `CerbCall`/`CerbQuote` also
need B counterparts if exposed, but are not required for the initial direct
driver entry. Missing totality support is a named build problem, never a hidden
axiom or silently dropped proof requirement.

Share typed AIL, C types, symbols/locations, annotations, concrete memory values
and implementation, FS/Cmm services, generic ND/monads and LemLib where their
APIs are target-independent. Core's value constructors wrap memory values, so
the shared memory interface does not require shared Core expression types.
Shared defects, especially in memory, are outside the independence claim.

The shared Cabs-to-typed-AIL frontend itself evaluates integer constant
expressions using original Core through `Mini_pipeline`. The fork point is
**after typed AIL preparation**: we are not validating independent C frontends.
Consequently, banning original Core from B's entire transitive import closure
would be wrong. Inspect the actual dependencies of B lowering/evaluation/control
entrypoints against the explicit shared-service boundary instead.

## Generation feasibility comes first

Prefer a separate invocation of the pinned Lem generator over the B model
sources, retaining their logical basenames, with an explicit owned/shared input
manifest. The original invocation/output remains unchanged. Lem's `-i` supports
input-only dependencies, but every imported module must agree with the variant's
types; determine the actual closure rather than copying only four headline files.

Application declarations are currently emitted at Lean's top level. Renaming
only the output file does not create a different AST. First try a narrow,
deterministic packaging adapter: map owned imports to `CoreB.*` and put their
declaration bodies in `namespace CoreB`; apply the same mapping to owned
handwritten support. Leave shared services outside it. Preserve diagnostic
strings. Do not globally replace the word Core or hand-edit emitted Lean.

This adapter is a hypothesis, not a working tool. The first experiment compiles
and co-imports both ASTs, one AST-dependent consumer and a handwritten
shape/measure/instance helper, including the associated auxiliary proof binding.
Inspect resolved names, not just successful parsing. If narrow packaging fails,
identify the concrete capture/import issue and cost a small Lem namespace
option. Do not substitute two isolated builds whose types cannot coexist, or
start a general source-rewriting framework without revisiting the scope.

Two Lean interpreters are the required outputs. An additional OCaml CoreB
executable is not required; the existing OCaml runner can supply optional
calibration. Keeping B's Lem sources preserves the future multi-backend option.

## Common input, independent targets

Both entrypoints use the same frontend adapter and preparation recipe. Preserve
typed AIL, fresh supply, source/run digests, enum/tag metadata, configuration,
address-space top and argv. Test a paired lowering function that supplies one
prepared typed AIL value to both lowerers. Compare artifacts through an explicit
structural name-forgetting map, not string replacement.

Executable comparisons run in fresh processes, checking prepared-input and
configuration identity. Sharing preparation is deliberate; it does not justify
discarding the translator's returned supply or selecting different switches.
Each target parses the same `std.core`/implementation text into its own program
data. The library has effectful procedures; B executes their B bodies. Simple
adapters for target-neutral configuration/name data are explicit.

A B-to-Core structural map may serve artifact comparison or theorem statements.
It must not implement B execution by feeding bodies, pure expressions, saved
continuations or procedures to the original evaluator. Both targets must be
modifiable independently. A small ordinary Lean equation should refer directly
to B syntax and its own evaluator, without a general equivalence theorem.

## Choice tapes: either machine can record

The harness owns the protocol and selection policy. The recording interpreter
offers alternatives; a deterministic policy (first, seeded random or exploration
prefix) selects an index, and the runner records what it encountered and chose.
A tape contains neither expected memory results nor an expected output trace.
Both interpreters compute their observations independently.

Implement record, replay and compare as distinct operations:

1. Core records a tape and its trace; CoreB validates/replays it and emits its
   own trace. Compare their events and outcomes.
2. CoreB records; Core validates/replays. Neither lane is permanently authoritative.
3. Repeated recording on each lane with identical input/policy checks
   reproducibility. Exhaust tiny branching fixtures; sample larger inputs.

A header identifies protocol version, program/prepared input, semantic
configuration and the intended pair of builds, with origin recorded as
provenance. The two binary hashes need not be equal. An entry contains branching
occurrence number, node kind, canonical parent payload, complete ordered
alternative descriptors (duplicates retained), and selected index.

For unchanged CoreB, correspondence is positional: same branching occurrence,
kind, ordered alternatives and index. `ND.pick` may give every alternative the
same label, so labels are not semantic branch IDs. Keep indices and duplicates.
Use the fixed clone-name map only for nominal representation differences; do
not erase arbitrary debug strings, locations, allocation identities or values.
If later Nice work changes choice structure, design that correspondence
explicitly; never search for a branch whose output agrees with the reference.

Traverse the actual ND interface, evaluating `ND f` once per visited node, with
no extra ND binds for logging. Multi-successor `NDnd`/`NDstep` consumes a choice;
singleton nodes remain observations without consuming one. Empty frontiers are
explicit. Initially refuse unsupported constraint-bearing `NDguard`/`NDbranch`
behavior rather than assuming constraints true. Cross-check branch zero against
`runND1` and finite complete outcome multisets against `runND`, accounting for
the latter's enumeration order separately from event order on each path.

Missing/surplus choices, invalid indices, changed descriptors or missing
completion are never a match. A valid tape from one lane that fails replay on
the other is a differential failure. A malformed externally supplied tape is
an input error. Reordering identically labelled children may only be detected
in their resulting traces; the protocol must not claim a stronger branch
identity than it actually carries. Identical repeated tapes add no coverage.

## Observations and failure behavior

Use the same typed schema with JSON-lines transport from both lanes:

* Actual ND boundaries, alternatives and selected choices.
* Existing driver events: allocation, load/store/RMW, lifetime end, pointer
  shifts and returns actually emitted, retaining their payloads and order.
* Terminal value/blocked status and exact stdout/stderr, or full UB/error
  payload and failure-state output, including all UB list entries.
* Explicit completion/end record. EOF is not completion.

The stored trace is newest-first: `newTrace = newestDelta ++ oldTrace`.
Validate the retained suffix and emit the reversed new prefix once. Include
failure-state deltas and consecutive multi-event tests. `ME_function_call` has
no active emitter; no complete entry/return log is claimed. Terminal output
strings do not establish their interleaving with every memory event. Report
these observation limits.

Passive memory receipts are an optional extra channel, with observing-on/off
calibration and existing local erasure facts. Separate buffers preserve their
own order; they do not recover an absent inter-stream ordering. No per-step
AST, environment, continuation, full heap or machine-state dump belongs here.

Both child processes require `LEAN_ABORT_ON_PANIC=1`; direct invocation without
it refuses before evaluation. Otherwise a Lean panic can return an inhabited
default. Test real panic, missing setting, truncation, timeout and fuel
exhaustion. These are incomplete/refused, never matches even when both fail.
Complete UB observations can match; matched model errors are matched failures,
not successful C coverage. Transport exit codes are separate from semantics.

## Fuzz a declared, useful C slice

Duplicate the complete implementation path; constrain the **tested domain**,
not the implementation to a newly written mini-C interpreter. Initially select
single-threaded concrete memory, one TU, no C libc and the normal Core runtime.

| Input family | Coverage |
|---|---|
| Pinned minimal/selected coverage cases | Arithmetic, locals/globals, conditionals, loops, calls, memory, and separately classified UB under supported recipes. |
| Small nondeterministic fixtures | Fully explored multiple outcomes, nonzero indices, repeated choices and duplicate labels; include `tests/z2-probes/nd/order3.c`. |
| Bounded generated C | Unsigned arithmetic, branches, bounded loops, direct functions, initialized scalar/fixed-array objects and in-bounds pointer accesses. |
| Evaluation-order cases | Helper calls with observable effects, including disjoint objects; confirm actual multiple-choice nodes in original execution. |
| Negative inputs | UB and model errors, counted separately from defined runs. |

Use a typed bounded grammar, initialization and safe arithmetic/access rules to
avoid incidental UB where possible. This is not a proof of a UB-free generator;
retain and classify unexpected UB. A small controllable generator and existing
corpus seeds suffice; a new Csmith installation is not a prerequisite.

Input fuzzing and choice fuzzing are separate axes. Pilot 100 short programs
with a few tapes each to measure cost and repair recipes. A proposed first
breadth target is 1,000 distinct generated programs with completed defined
comparisons over several fixed seeds, up to four paths per lane/input, plus
selected upstream cases. Before the campaign, freeze a short acceptance manifest
after the pilot: input seeds/configuration, supported recipes, resource limits,
completed-case targets and the generator families below. The proposed minimum
is 50 completed defined inputs in each family (overlap allowed): arithmetic,
conditionals, bounded loops, globals/locals, direct calls, and array/pointer
loads/stores. Feature-directed templates ensure the named operations execute;
source presence in dead branches is insufficient.

Include at least 100 generated inputs that actually reach a multi-successor
choice and complete at least two distinct tapes each, with both recording
directions exercised for those inputs. Report distinct tapes and alternative
indices, not merely RNG seeds. Exhaust tiny cases; do not claim all paths for
the large sample. Both record/replay directions must also be exercised across
the defined campaign, not just on one hand-picked control.

Use per-case and campaign time, memory, fuel and output limits. A smoke command
is separate from the larger campaign. If the target does not fit the budget,
report the completed denominator and limits; it is not automatically a pass.
Missing any frozen completed-case/feature/ND target leaves the milestone
incomplete unless its scope is explicitly revised and reviewed before claiming
completion. Refusals, UB, errors and resource failures do not satisfy these
defined-run targets. The pilot may motivate such a revision; it does not
silently lower the denominator during the campaign.
All completed admitted unmutated comparisons must agree; mismatches remain
failures. Report refusal/frontend failure, UB, model error and incomplete runs
separately; no common frontend failure counts as a target comparison.

Minimize counterexamples as source + configuration + tape. Reducing source can
change the choice structure: generate a valid new tape for the reduced input
and retain it only if the real differential failure persists. A now-invalid old
tape is not a semantic counterexample. Commit small reproductions, generator
and conclusions; raw campaign traces remain ephemeral.

## Injected differences prove this path is editable

Build explicitly named CoreB-only mutants from owned sources. The reference and
unmutated B remain unchanged. Each witness must reach its mutation and make the
difference observable; arbitrary unreachable or observationally neutral mutants
are not required to fail.

| Mutation | Expected detection |
|---|---|
| Change a constant/operator in B lowering | Artifact comparison and executed value/effect differ. |
| Change B reduction, a store payload or taken branch | Independently produced semantic trace/outcome differs. |
| Remove/add/reorder a genuine B choice | Replay incompatibility or changed observed behavior; include duplicate labels. |
| Suppress a B observation event | Trace mismatch even if return values agree. |
| Real panic or missing completion | Failure/incomplete, never agreement. |

Test both recording directions where applicable. Fabricating a changed log
tests only the comparator; it cannot replace the lowering/reducer mutants.
No selector uses the other interpreter's expected output to choose a branch.

## Work packages and completion

1. **Generation/type separation:** source map; co-import and compile both ASTs,
   an AST-dependent consumer and handwritten support/auxiliary binding. Inspect
   resolved identities. This is the first concrete feasibility experiment.
2. **Complete B route:** close the source/support inventory; run its AIL lowering,
   linker, runtime library and interpreter. Check artifact isomorphism and the
   actual lowering/evaluator/reducer/call/label/driver dependencies. Show a local
   Lean equation over B syntax. No Nice semantics yet.
3. **Instrumentation:** shared observations and bidirectional record/replay,
   failure classification and shipped-runner calibration. Test real effects
   and a completely explored ND fixture before fuzzing.
4. **Fuzz and mutation campaign:** pilot then bounded breadth; detect the named
   source-level and observer mutants with the same harness. Preserve genuine
   unmutated counterexamples as failures to resolve.
5. **Review/handoff:** inspect the real B execution path and reproducible build,
   document one smoke command and the campaign command, then freeze the tested
   baseline commit before Nice changes begin in those same owned sources.

Completion means independently modifiable AST/producer/interpreter sources,
reproducible generation/build, explicit shared inputs/services, bidirectional
tape/trace comparison, a reported fuzz slice and detected source-level mutants.
A reported slice satisfies completion only when it meets the frozen acceptance
manifest, including completed defined cases, feature families, actual branching
and both recording directions.
A driver-only twin remains a failed milestone even if all its tests are green.

Estimate roughly 2–4 focused days for generation/closure discovery, 3–6 for the
complete path/runtime integration, and 3–5 for tape/fuzz/mutation infrastructure:
about two to three engineering weeks, partly overlapping after interfaces settle.
This is not measured throughput. A namespace obstruction or unexpectedly large
dependency closure requires an immediate revised estimate.

Use focused builds and behavior/instrument tests while developing. Do not run
the consumer's entire proof campaign for this provider experiment. Full relevant
trust checks apply at actual theorem/landing/shipping claim points. This step
provides testing evidence and a research platform, not general equivalence.

## Source basis and decisions

Source-audit anchors refer to the original provider/Lem revisions above;
the chosen development revision is separately named and is not yet built for
this experiment: `Makefile:146–160,315–369`;
`lean_frontend/lakefile.toml:100` onward; `handwritten_copy.manifest`;
`core.lem:176,228,319,417`; `errors.lem:27–44`; `pp.lem:57`;
`formatted.lem:3`; `mini_pipeline.lem:79–117`; `cabs_to_ail.lem:1465–1484`;
`Main.lean:861–874,1297–1331,1779–1793`; `nondeterminism.lem:190–206`.
Lem's flat application declarations are explicit in
`src/lean_backend.ml:10455–10458,10569–10574` and
`doc/lean-backend/DESIGN.md:24–35` at the pinned Lem revision.

* [USER, 2026-11-14] Establish the complete, initially unchanged CoreB target
  path and the infrastructure later Nice work will use, including choice replay
  and injected-difference testing.
* [AGENT, 2026-11-14] Recommend the existing cerberus-lean fork/research branch,
  owned worktree, common bidirectional tape protocol and an early namespace
  generation experiment. Installed consumer dependencies remain unchanged.
* [USER, 2026-11-14] Use an integration branch and PR for research review;
  do not land this work on cerberus-lean mainline.
* [AGENT, 2026-11-14] Base the integration branch on examined development
  mainline `8fa3050bf`, using its matching Lem pin, rather than downgrading the
  development workspace to the consumer's older generator. This changes no
  installed consumer pin and carries no new execution-validation claim.
