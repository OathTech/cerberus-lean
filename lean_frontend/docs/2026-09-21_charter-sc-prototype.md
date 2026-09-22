# Charter: faithful SC concurrency prototype

2026-09-21. **Execution charter for the user-approved SC prototype plan.**
The objective and constraints below are [USER]; work packages, implementation
choices and proposed checks are [AGENT] unless marked otherwise. This charter
governs a sustained implementation effort in the dedicated worktree. Completing
a package does not require another approval before starting the next package.

## 0. Objective and authority

Build and validate an SC execution mode over the current Cerberus semantics,
in OCaml and Lean, with faithful memory effects, sequencing, atomic operations,
structured threads, and outcomes. Expose the actual operational definitions and
useful semantic laws so an external customer can reason about those semantics.

[USER] project scope: this repository captures Cerberus's operational semantics
and allows reasoning in the customer. [USER] overriding constraint, verbatim:

> "fidelity is the overriding constraint. We cannot restrict cerberus for reasoning reasons."

[USER] accepted the five-part development plan: fix the SC contract, bring over
useful execution machinery, expose relevant memory effects, implement SC
operations/races, and validate the complete execution path. [USER] requested a
worktree, a charter for the whole effort, and long-cycle work with minimal
interaction. These authorize ordinary implementation, investigation, local
tests, repairs and commits throughout this charter; they do not authorize a
mainline merge, push, or customer modification.

This charter supersedes implementation recommendations in the
[scoped proposal](2026-09-20_concurrency-scoped-proposal.md) wherever they differ.
That proposal and the [research assessment](2026-09-20_concurrency-research-assessment.md)
remain supporting analysis. The
[September 19 landing charter](2026-09-19_charter-concurrency-landing.md) is
withdrawn; do not revive its blanket rebase or its insufficient theorem claims.
The earlier [pause note](2026-09-19_concurrency-pause-note.md) remains history;
the present instruction resumes work through a fresh prototype branch.

## 1. Working tree and references

| Item | Starting identity / role |
|---|---|
| Prototype branch | `arc/sc-prototype` |
| Prototype worktree | `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype` |
| Implementation base | `mdd/cerberus-lean` at `5407597d9eeba0259d65b728e86a860ad4614ab3` |
| Pristine upstream reference | `b9aeedcb4dd438763b0eef7f95ac19e93875d7de` |
| Legacy SC donor | `feature/concurrency`, `086d8762d382eff375c101f5f0c64d3ffe9bccc7` |
| Repaired legacy validation donor | `arc/validation-foundations-concurrency`, `86a2aea547804b78eb7f1eae633bb9c24c713b7f` |
| Research snapshot copied into this branch | Two September 20 documents from `02a6adc9091f72cecac6c5ff15845f93fa81fa84` |
| Lem / LemLib pin at base | `38f87d5fa6b29ec90edfa457faba8a309e32c118` |
| Lean toolchain at base | `leanprover/lean4:v4.32.2` |
| Customer | `/home/dev/projects/cerberus-sl`, strictly read-only |
| Live work record | [SC prototype progress](2026-09-21_sc-prototype-progress.md) |

The worktree was created from the implementation base with the container's
`scripts/new-worktree.sh`. Build/dependency state was primed locally; the
worktree's pristine oracle was built and validated independently. This setup is
not a fresh certification of the prototype or the mainline test suite. S0 records
the actual initial source, tool, artifact, and validation identities.

Keep the primary checkout and parked donor branches unchanged. Worktree-local
builds and evidence belong here. Re-check instructions and worktree status when
resuming; do not overwrite unfamiliar edits. Do not chase moving mainline refs
during ordinary work. If a mainline integration becomes necessary, use the
project's branch workflow, record before/after identities, and revalidate; never
rewrite the parked donor branches.

## 2. Fidelity and scope

### 2.1 What is being captured

The target is a faithful SC operational instance over Cerberus Core and its
object model, using the existing structured parallelism. C input travels through
the real frontend and Core pipeline; hand-constructed graphs are supplemental
tests. This effort includes the relevant current sequential operations and
their interaction with scheduling, not just a newly invented scalar language.

Follow [VALIDATION.md](../VALIDATION.md)'s reference doctrine: the logical
semantics is the referent. Preserve the Lem model, Core library behavior, and
specified memory semantics; do not turn OCaml host-runtime accidents into Lean
semantic limits. Preserve the repository's distinction between deliberate model
failures, host-resource failures, and documented upstream defects. Changes to
the shared model require a source/standards rationale and the normal discrepancy
records; OCaml/Lean agreement cannot independently validate such a change.

S0 names the SC predicates, operational construction, threadwise integration,
object model, and relevant ISO clauses/corrections together. The existing
`SC_memory_model` plus `SC_condition` is reference material, not a complete
specification of today's Core adapter. The broken current concurrency driver
is not evidence that every new scheduling decision is authorized. Use upstream
definitions, historical integration and ISO requirements to resolve the gaps;
record the derivation and any remaining uncertainty.

### 2.2 Coverage is not theorem scope

[USER, 2026-09-21 clarification; generalized 2026-09-22] Evidenced unresolved
semantic boundaries fail closed. Retain the pinned Cerberus/Cmm reference and
an explicit unsupported outcome until each gap is resolved; do not invent a
comparison, mixed-size or stream-synchronization semantics. Document every case
in the [boundary register](2026-09-22_sc-boundary-register.md), with evidence,
precise scope, implementation status and resolution criterion. This is an
acknowledged coverage limit, not C undefined behavior or an impossible execution.
The [upstream-gap policy](2026-09-21_sc-upstream-gap-policy.md) records the precise
distinction and reasoning-client obligation. Missing port work with available
semantic guidance remains in scope.

- No new loop-free, scalar-only, lifetime/privacy, expression-shape or similar
  runtime restriction may be introduced to make a proof convenient.
- Proofs and exhaustive experiments may use restricted hypotheses. State them
  as theorem/test domains, separately from the executable language.
- Temporary unimplemented operations must fail explicitly and carry a concrete
  port-gap entry: operation/path, missing semantic mechanism, reproducer,
  expected reference behavior, and removal task. A refusal is not a passing
  implementation of that operation, and a hard proof is not a port gap.
- Intermediate incomplete code may be retained and tested as work in progress.
  It cannot be declared the completed prototype by shrinking the target to its
  already-working cases.
- Weak-order execution is outside this SC development effort. A named SC mode
  must not silently strengthen relaxed/acquire/release operations. Record its
  actual model conditions and distinguish them from unfinished port coverage.
  This milestone does not replace the longer-term upstream concurrency target.

### 2.3 Boundaries of this effort

In scope: structured spawn/join and scheduling; Core sequencing and exclusions;
initialization; loads/stores; ordinary and atomic read/modify/write behavior;
SC atomic operations, including compare-exchange success/failure; representation
accesses; memory-library helpers; relevant lifetime and runtime-helper effects;
faults and incomplete exploration; the operational Lean interface; validation.
Investigate SC fences and other upstream actions against the exact selected
reference rather than inheriting an unexamined exclusion from an old checker.

Adding a new pthreads/ISO thread-library implementation, a weak-memory executor,
an Iris layer, a separation logic, customer proofs, customer pin changes, and
performance/state-space reduction projects are outside this charter. Existing
loops, calls, pointer behavior and memory operations do not become out of scope
merely because their concurrency integration is difficult. Runtime I/O and
helpers must be inventoried wherever reachable; do not silently ignore their
memory accesses.

## 3. Architectural constraints

1. **Reuse current Core execution.** Extend requests/continuations and scheduler
   integration rather than duplicate expression evaluation in an SC backend.
   Keep whole-machine and local-thread responsibilities explicit.
2. **Preserve the concrete object model.** It owns pointer validity, bounds,
   lifetime, byte/provenance representation, metadata, and its failure-time
   state. Typed SC values cannot replace that object semantics.
3. **Expose effects at their actual source.** Reads, equal-value writes,
   initialization and accesses completed before failure must remain visible.
   A final memory diff is insufficient. Account for memops, library paths,
   startup and error handling as well as ordinary action requests.
4. **Separate effects from scheduling points.** A resumable protocol is a
   candidate, not a requirement to yield after every internal byte operation.
   Specify indivisible operations and allowed interruption points from the
   selected reference. Sequential erasure alone does not justify new concurrent
   interleavings. Requests serviced after a yield must use the correct current
   state, not an unjustified cached validity check or read value.
5. **Preserve the ordering relations.** Source `sb`, synchronization, `hb`,
   atomic modification/SC orders and the scheduler's selected order are distinct.
   Do not order unsequenced siblings merely because one executes first. Spawn
   and join establish their specified edges; sibling scheduling order does not.
6. **Preserve location distinctions.** Allocation identity, representation
   range, C memory location and atomic-object identity are not interchangeable.
   Byte reads may reconstruct values from different writes. The existing
   `Mem.overlapping` intentionally excludes read/read pairs and is not a general
   intersection predicate. Establish conflict and reconstruction behavior from
   the reference; do not assume either pointer equality or numeric overlap alone
   solves every case.
7. **Separate races from graph membership.** A concrete racy run's actual reads
   need not form a consistent Cmm candidate. Do not discard such a run or demand
   raw graph equality as a universal fault test. Specify operational fault
   handling and justify any program-undefinedness correspondence separately.
8. **One semantics, usable from Lean.** Export inspectable definitions and
   useful equations/elimination laws. A separate proof-facing relation must be
   defined from execution or have a proved connection covering every executable
   choice. Do not introduce an unconnected mirror or axiomatized scheduler.
9. **Preserve port discipline.** Prefer shared Lem definitions for common
   semantics; mirror hand-written OCaml/Lean seams with source references.
   Keep program data, configuration and resource parameters explicit. Respect
   totality, fuel, purity, axiom and generated-source freshness requirements.

The existing `SeqRMW` is not automatically a C atomic RMW. Its ordinary C
sequencing/exclusion behavior must be retained. Likewise, the false `true`
concurrency stub and unimplemented branches cannot become foundations for a
correctness claim merely because a generated module compiles.

## 4. Continuous work packages

The order below supplies checkpoints, not permission barriers. Refine package
boundaries when evidence warrants it, record the reason, and continue. Do not
fork the effort into several competing production architectures.

### S0 — Reference, baseline, and trustworthy instruments

- Read the legacy audit and retained reproductions. Establish current baseline
  behavior with current artifacts; September 19 measurements are historical.
- Record source/tool/build identities, normal entry parameters, and full
  observation/status handling. Validate the pristine oracle independently.
- Write the operational contract: model identity, runnable-thread choices,
  spawn/join, action boundaries, source ordering, SC operations, initialization,
  lifetime integration, faults, blocking and finite/infinite execution claims.
- Inventory reachable effect paths. Each row names its source, state effects,
  returned value, ordering/atomicity, failure state, instrumentation point,
  reference evidence, implementation status and test.
- Separate runtime coverage, reference-checker coverage, proof coverage and
  exploration bounds. Include current SC reference limitations concerning
  footprint composition and lifetime actions.
- Select and port the concurrency-specific validation repairs onto current
  observation infrastructure before trusting the new litmus lane. Test original
  exit statuses, partial output, duplicates and missing observations.

**Exit evidence:** a reproducible baseline and contract, a complete source-path
inventory with explicit unresolved items, and a non-vacuous comparison harness.
An unresolved item can feed later work; it cannot be hidden by a passing scalar
test or an added source restriction.

### S1 — Current driver, scheduler, and structured threads

- Adapt the useful selector/scheduler/startup work from the legacy branch,
  reviewing changes against current driver signatures and state ownership.
- Connect current Core action requests and continuations, allocate fresh event
  and thread identities, preserve thread-local state, and implement structured
  spawn, waiting, completion and join. Handle nested structure according to
  Cerberus rather than excluding it for the first theorem.
- Preserve sequential entry behavior, initialization, `errno` and other runtime
  state. Exercise return values, blocked states, failure and resource outcomes.
- Enumerate scheduling alternatives honestly in exhaustive mode. An arbitrary
  selected schedule is not the whole program's behavior.

**Exit evidence:** runnable structured-thread examples in both engines, local
and global transition tests, initialization/join controls, and sequential
regression evidence. Any still-missing effect paths are visibly unfinished;
this package alone is not the completed SC prototype.

### S2 — Memory effects, representation, lifetime, and sequencing

- Complete the effect inventory through load/store, allocation/create/kill,
  optional initialization values, `memcpy`, `memcmp`, `realloc`, and reachable
  pointer/helper/runtime paths. Pure operations need a justified classification;
  stateful metadata operations must not disappear.
- Preserve byte/provenance reconstruction, checked accesses, helper iteration
  behavior and partial failure state. Avoid reimplementing memory semantics in
  a second event store. Reuse or refactor the authoritative operations.
- Resolve effect grouping versus permitted scheduling interruptions. If an
  adapter changes representation, establish its sequential erasure and the
  separate concurrent correspondence required by its new boundaries.
- Repair event ordering at Core continuations, unsequenced/indeterminately
  sequenced evaluation, calls, exclusions, and ordinary `SeqRMW` paths.
- Capture shared and private lifetime behavior without inventing ownership
  restrictions. Account for identity reuse, stale pointers, startup and
  initialization in the concurrency/object-model composition.

**Exit evidence:** the retained byte/copy/overlap failures are repaired on the
real C-to-Core execution path; equal-value and hidden accesses remain visible;
ordering traces match source rules; partial failures preserve their preceding
effects; local erasure/correspondence laws cover changed adapters. A restricted
Cmm checker stays restricted as a checker, not as the executable language.

### S3 — SC atomic operations, races, and verdicts

- Establish SC loads/stores and their orders, then the supported frontend paths
  for atomic RMW/exchange and compare-exchange. Include weak-CAS spurious
  failure where specified, expected-value updates, successful/failed effects,
  initialization and operation-specific memory-order validation.
- Resolve fences and all remaining actions in the S0 inventory using the named
  reference. Missing frontend lowering is a concrete implementation task or an
  evidenced upstream limit, not an occasion to fabricate a Core-only success.
- Detect conflicting unordered actions using the justified location/effect
  interpretation. Do not let total execution order suppress a race.
- Define how operational faults, valid race witnesses and program-level
  definedness are reported. Preserve every relevant alternative; one apparently
  safe schedule cannot erase a faulting one.
- Cover faults before divergence and exhausted exploration. Do not claim
  complete safety or definedness from terminated runs alone. State clearly
  which prefix/infinite-execution correspondence has been established.

**Exit evidence:** SC SB/MP/IRIW and publication behavior, RMW/CAS success/failure
controls, unsynchronized and mixed-range conflicts, and fault/exhaustion plants
all have justified classifications in both engines. SC membership and fault
correspondence are not conflated. Unsupported weak orders are never executed
under silently strengthened semantics.

### S4 — Operational interface and semantic laws

- Export the actual state, local/machine transitions, outcomes and their
  explicit parameters. Supply practical equations, inversion and composition
  lemmas instead of making the customer reconstruct driver arms.
- Prefer direct definition from the executable transition functions where
  useful. For a separate Lean presentation, establish the coverage direction
  needed to account for every engine choice; prove the other direction when
  claiming equivalence.
- Establish single-thread conservativity and effect-erasure results for the
  justified domains. Account for resource costs: equal numerical fuel is a
  stronger contract than finite-behavior correspondence. Preserve exhaustion
  as an actual outcome and provide a budget relation when costs change.
- Record the exact status of correspondence with the pinned axiomatic SC
  reference, including source sequencing, initialization, values and faults.
  Do not assume a reference theorem whose hypotheses the adapter has not shown.
- Add a small logic-independent external import/lemma example over the
  exported semantics. It has no Iris or customer dependency.

**Exit evidence:** consumers can import and use the operational definitions;
claimed Lean-to-Lean connections are kernel checked without new axioms or
`sorry`; theorem domains and outstanding external-reference claims are explicit.
No customer application proof or full ISO mechanization is a completion gate.

### S5 — Integrated validation and prototype completion

- Review the final source-path inventory and retire implementation gaps in the
  agreed SC target. Upstream omissions, unproved correspondence and tool limits
  retain separate classifications; none may disguise an omitted target feature.
- Run the current required sequential gates and the complete concurrency suite
  with fresh source/build identities and the validated pristine instrument.
- Review reference independence, all effects/scheduler connections, full
  observations, all outcome classes, and absence of reasoning-driven guards.
  Re-run meaningful negative plants at the final production connections.
- Update public usage/support/validation documentation, the difference
  registers where applicable, and the final progress/evidence record. Retain
  minimal reproducers and exact commands for remaining upstream issues.

**Exit evidence:** a reproducible, reviewable SC prototype meeting section 7.
This closes development, not a merge or customer migration. If acceptance is
not met, record what remains and continue the work; do not declare completion
because an intermediate scalar prototype works.

## 5. Validation contract

Use [LADDER.md](../../scripts/LADDER.md), [VALIDATION.md](../VALIDATION.md) and
the current shared observation codec. Do not replace them with the legacy
value-only extractor or hard-code stale suite counts from this charter.

| Comparison | What it establishes / does not establish |
|---|---|
| Fork OCaml versus Lean, matched mode | Implementation agreement for the compared full observations. Both can share the same modeling mistake. |
| Pristine upstream / historical operational source | Independent source and execution evidence within their actual implemented domains. Today's pristine concurrency refusal is not an SC oracle. |
| Recorded execution versus named Cmm predicates | Membership on the predicate's domain; not completeness of the executor or fidelity of the C-to-event mapping. Racy traces require their separate argument. |
| Pinned independent litmus checker | An independently implemented model comparison with reviewed inputs, bounds and status. A different memory model is not an interchangeable oracle. |
| Lean semantic laws | Facts checked about the actual Lean definitions or their proved presentation. They do not prove the OCaml compiler/runtime correspondence or customer logic adequacy. |

Required diagnostic families include:

- SC SB/MP/IRIW, conditional publication, creation/join, nested structured
  threads, blocking, and alternatives with different outcomes.
- Whole and byte accesses, differently based overlaps, disjoint accesses,
  equal-value stores, representation/provenance cases and uninitialized values.
- Copy/compare/reallocation, partial failure, allocation/lifetime/reuse, and
  reachable startup/runtime-helper effects.
- Unsequenced expressions and same-object UB controls, call sequencing,
  ordinary `SeqRMW`, and atomic expressions with effectful argument evaluation.
- RMW/exchange and CAS success/failure/spurious-failure cases, initialization,
  fences as resolved by the contract, and rejected weak orders without coercion.
- A faulting alternative beside a safe one, a fault before a loop, insufficient
  ambient/exploration fuel, OOM, malformed output, partial output plus exit
  124/137, duplicate names and missing/extra records.

Retain the legacy litmus corpus and audit counterexamples as seeds. Each test
has an independently stated expected classification; do not bless new output
by rerecording it. Add a plant that disconnects the production driver's event
or checking path: hand-built checker tests alone cannot detect that omission.
Never count unsupported, unrun, timeout, tool failure, or partial exploration as
agreement or full support. Use bounded examples for exhaustive comparisons;
bounded search is not a semantic restriction or an infinite-execution proof.

Use the current release runner: `python3 scripts/release.py --mode fast` for
Tier A and `--mode full` for A+B, under the project environment. Follow the
ladder's per-commit and slice-boundary rules for implementation claims; run
affected targeted tests during development. Changes to sensitive execution or
memory seams trigger the broader checks required there. At final completion,
run A+B plus the concurrency-specific suite and relevant reporting obligations.
Do not launch an unrelated csmith/reporting campaign. Documentation-only setup
is checked as documentation and makes no semantic certification claim.

Retain commands, exit codes, raw full observations, model/version identities,
parameters, bounds, manifests and counterexample inputs. Summaries must label
derived tallies. A source change invalidating a checked artifact requires a
fresh build and relevant rerun. Do not normalize away UB location, output bytes,
distinct failures, or meaningful nondeterministic alternatives.

## 6. Autonomy, records, and escalation

### Continue without routine confirmation

The implementing agent may inspect sources/history and primary literature,
choose faithful internal representations, edit the necessary shared Lem and
paired seams, repair frontend/scheduler/helper integration, add focused tests
and semantic lemmas, regenerate both targets, repair failed checks, and make
coherent local commits. It may adjust work-package ordering based on evidence.
These are authorized implementation choices, not new approval checkpoints.

After a successful checkpoint, update the live progress record and continue
with the next unfinished task. A local commit is not a request to stop. A failed
test normally means investigate and repair. A false theorem means retain the
counterexample and repair the statement or implementation according to fidelity;
it does not authorize narrowing the executor. Do not silently create a park
record or treat context loss as cancellation.

Keep the progress file current enough for a new session to resume without
reconstructing chat. For each checkpoint record: package/task, source revision,
what changed and why, [AGENT]/[USER] decisions, commands/results/evidence paths,
remaining gaps, and the next concrete action. Keep the charter stable except
for clarified scope or materially revised implementation commitments. Report
meaningful findings and blockers concisely; avoid repetitive permission requests.

### Ask only when a real boundary is reached

- If source, standard and historical evidence leave materially different
  semantic behaviors unresolved, first produce the concrete example, options,
  consequences and recommendation. Ask for that decision while continuing
  independent work. A lack of proof convenience is not semantic ambiguity.
- Ask before a mainline merge/push, customer write or repin, machine-global
  mutation, or other action outside this authorization. Prepare the concrete
  result first. This charter requests none of those actions automatically.
- For a sandbox/network/tool boundary, use permitted local alternatives where
  possible, report the actual missing capability, and never weaken a validation
  result to pass. Limited networking is not by itself a reason to stop source
  work. Do not publish or message external parties.
- Apply the repository's long-build/proof-grind stop rule. Preserve evidence,
  diagnose structure/resource use, and pursue independent work; do not respond
  to an hour-long proof grind by increasing limits without the required review.

If a real unresolved boundary prevents all meaningful progress, leave a precise
resumption record and ask the smallest necessary question. Do not invent a
substitute semantics to avoid interaction, and do not end at a mere plan while
authorized implementation work remains.

### Workspace and resource discipline

- The customer is strictly read-only: no files, builds, caches, pins or branches
  there are changed. Prefer `GIT_OPTIONAL_LOCKS=0` for customer Git inspection.
- Keep all implementation and scratch artifacts in owned worktrees. Promote
  useful evidence into repository records; do not leave durable container notes.
- The worktree's `_opam` is shared. No package installation/removal, shared pin
  reset, shell-profile change or global toolchain mutation is authorized.
  Isolate a necessary dependency fix and identify its integration boundary.
- Load the container project environment through `scripts/ce`. Every Lean/Lake
  invocation uses the repository's `scripts/capped` from the owning package
  directory, so its `lean-toolchain` is selected; one heavy job at a time.
  Use lower memory caps under pressure, and bounded per-case test timeouts.
- Regenerate after shared-source changes. Hand-written Lean seams are copied
  according to `handwritten_copy.manifest`; never trust stale generated files,
  copied `.olean` files or driver binaries. Follow the project's probe recipe
  and regeneration/cache-disabled requirements for certification and plants.
- Keep existing purity/totality/axiom checks. Do not add axioms, `sorry`, fake
  success defaults, unchecked runtime equality for closures, or prohibited
  non-kernel proof shortcuts to make the prototype or its proofs pass.

## 7. Definition of done

The prototype is complete only when all of the following are reviewable:

1. A named SC operational contract, an upstream/ISO source map, and explicit
   distinctions between reference behavior, implementation coverage and proofs.
2. A working OCaml/Lean SC execution path through the current C/Core pipeline,
   including the agreed scheduling, effects, atomic operations and fault policy.
3. No unresolved implementation gap in that agreed target is concealed by a
   narrowed language, weakened comparison, default value or vacuous check.
   Evidenced upstream limitations remain identified as such.
4. Current sequential behavior is preserved under the repository's validation
   contract. Full SC observations agree between the paired implementations, and
   independent reference checks are used within their justified domains.
5. The operational interface is usable externally; any separate Lean
   presentation has its claimed correspondence proved. All stronger unproved
   reference/ISO claims and theorem-domain limits are plainly stated.
6. Required final gates and production-connection plants pass with fresh
   identities, and the committed usage, support, progress and evidence records
   are sufficient to reproduce the result.

Full weak-memory support, whole-ISO mechanization, a customer adequacy theorem,
and a mainline merge are not implied by prototype completion. Conversely, a
small proof or a green litmus subset does not establish this completion.

## 8. Resuming this charter

Read this charter, the live progress file, current
[repository](../../CLAUDE.md) and [Lean](../CLAUDE.md) working practices, and
`git status`. Confirm branch and source/tool identities, inspect unfinished
edits and the last validation evidence, then continue the next recorded task.
Do not rerun historical research or already-valid expensive checks without a
reason. The initial next implementation task is S0: establish the actual
baseline and operational/effect inventory, then repair/select the litmus
instrument before bringing over scheduler code.
