# SC prototype: execution roadmap

Established September 21; consolidated September 24, 2026 after the user's
critical review and pruning instruction. **This is the single active SC plan,
status and resumption point.** Older charters, component work logs, audit plans
and scratch recipes do not supply additional work or acceptance requirements.

## Objective and authority

[USER] Deliver faithful SC operational semantics through the real C/Core path
in OCaml and Lean, with an inspectable operational API for external reasoning.
“Fidelity is the overriding constraint. We cannot restrict cerberus for
reasoning reasons.” The customer supplies its own logic. This repo supplies the
semantics; a second evaluator or an unconnected proof model is not the product.

[USER, September 24] Cut infrastructure that does not help deliver this feature;
sunk cost is irrelevant. The accepted pruning plan is incorporated below.
Its former scratch location is not needed to execute this roadmap. This ruling
replaces earlier agent-authored per-component campaigns, proof-count targets,
retention requirements and work-package ordering. Preserve actual semantic
checks, complete observations and relevant independent reference comparisons.

Ordinary implementation, deletion within this plan, source investigation,
targeted validation and coherent local commits are authorized. Continue through
the checkpoints without routine permission requests. A checkpoint is a report
of feature progress, not an invitation to invent another infrastructure arc.
No merge, push, customer mutation or shared toolchain/dependency mutation is
implied. Escalate only a concrete unresolved semantic choice or unavailable
capability that prevents the next necessary action; continue independent work.

## Current status and next action

- Branch/worktree: `arc/sc-prototype`,
  `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype`.
- Base: `5407597d9eeba0259d65b728e86a860ad4614ab3`.
  C1 pruning and consolidation commit: `0e6947988`; C2 scalar integration
  checkpoint: `8a350e2a1`; C3 metadata/array/view checkpoints: `0f437971a`,
  `307ac0d3e`. C2 acceptance and C3/C4 remain in progress.
- The actual scheduler, primitive observations, atomic operations, source-order
  evidence and failure-state repairs exist. **Public SC is unfinished:**
  the new `Driver.drive true` completion path constructs and checks a candidate,
  and both CLIs dispatch `--concurrency=sc`. This integration is under validation;
  complete C2 acceptance and C3/C4 coverage remain outstanding. Component tests
  are not proof of delivered SC support.
- The last frozen attribution snapshot passed all 39 full lanes and the 864-case
  three-engine report; source was unchanged and the wrapper exited 0. Its Lean
  report has 822 agreements, 29 differences, 11 both-undecodable and 2 n/a.
  These are sequential/component results, not SC acceptance. Current raw reports
  are `.tmp/sc-prototype/link-attribution-integration-{full,three-way}-20260923/`.
  Do not archive another copy or rerun them for this documentation change.
- **C1 implemented:** removed 25 unused source modules and their registrations,
  moved the equality/FS-instance and byte-key laws, removed the redundant global
  linker entry, and retained the combined attribution path. No customer imports
  of the removed proof modules were found by read-only text search.
- SC fixtures now have two Lean entry points (`sc-machine-test`,
  `sc-adapter-test`) and one native executable (`memory/concrete/sc_controls`).
  The paired suites pass after fresh regeneration/build; the external consumer
  compiles. The litmus runner integration selftest passes. Lake root membership
  and the reviewed fork content/generated pins pass. Fresh failure-owner
  compilation/census passes with the same 205 registered pure failure sites.
- Deleted 22 redundant SC narratives, the 2,103-file repeated evidence tree and
  98 superseded scratch/campaign directories. Minimal boundary, representation
  and runtime inputs are in `tests/sc/`; source conclusions and the filesystem
  coverage map are in the three live specifications. Keep the latest raw full
  and three-engine reports above, and the unresolved G06 experiment only.
- **Next: C2, production interpretation/classification and the public C path.**
  C3/C4 remain open. The new prefix accumulator retains witness IDs in the
  authoritative journal instead of repeated graph snapshots; the superseded
  accumulator/proof modules are removed. Full prefix interpretation still needs
  cost validation. Attribution queries must earn their place in the actual
  G03/G08 producer. Actual loader/linker selection now reaches the driver;
  reached library effects still carry a temporary protection-attribution port
  obligation. Do not restart the removed proof/campaign work.
- C2 checkpoint verification: both generated targets and CLIs build; the two
  Lean suites, native controls and external example pass. The reference closure,
  relation and fence controls pass. Fork pins and root membership pass. The
  failure register now includes 20 pinned-reference partial-pattern sites,
  unreachable in production by the fixed `hb`/`vse` relation-list construction
  (a reviewed source invariant, not a new theorem); all 225 registered sites
  match the fresh census. No full sequential campaign was repeated.
- C3 varargs integration: the production classifier now derives full occurrence
  HB from the actual reference SW and retains abstract cursor conflict IDs in
  the ordinary prefix findings. Same-thread conflicts use source SB. Both public
  SC frontends return 42 for a selected `varargs_vacopy.c` execution; seven new
  classifier controls and the consolidated SC suites pass. This removes the
  blanket metadata port obligation, not the remaining object/runtime work.
- C3 scalar location/value extension: whole nested-array elements now have
  distinct locations. Corresponding signed/unsigned views share RF tokens under
  the concrete integer encoding, preserving rank/provenance and raw captures.
  Both public engines return 42 for the distinct-element C probe, UB005 for
  the same-element race, and 1 for the signed/unsigned view probe. These are
  selected executions, recorded with commands/status/binary hashes in
  `.tmp/sc-prototype/c3-probes.json`; fifteen added classifier controls cover
  these cases and prevent wider overlapping views from certifying separate
  locations. The whole-C provider API below retains the remaining
  interpretation obligations visibly.
  The wider-view guard retains the lowering's unspecified whole-array store
  when it precedes element accesses; unordered controls remain refused and
  no initialized values are inferred from that store.
  Aggregate initialization, structure/union members, partial representation
  accesses, remaining typed views, allocator reuse and runtime guards remain
  unfinished. No full SC acceptance claim follows from this checkpoint.
- **C4 provider API implemented (`fad4c0428`), final acceptance still open:** `sc_program`
  packages the actual whole-program driver continuation with its state;
  `sc_program_entry` is used by both CLIs. `sc_program_start`,
  `sc_program_node` and `sc_program_resume` preserve outer initialization/main/
  finalization work and paused services. `CerbSCOperational.start`, `terminal`
  and `outcomes` expose the same computation, typed results and caller bounds.
  Semantic fuel is captured at construction; the outcome runner has a separate
  explicit exploration-depth budget, chosen equal by the CLI. No successful-at-
  some-fuel semantics or hidden fuel renewal is introduced.
  The rewritten external consumer compiles against this API and proves its
  actual-driver connection, retained fault assertion, selected continuation
  identity and exhaustion case. Whole-program controls distinguish global
  initialization from main completion, retained outside-lifetime UB, blocking
  and exhaustion. Both builds, both SC suites, native controls and the consumer
  pass. Fresh census remains 225 registered sites; reviewed fork pins pass.
  Selected paired global-init/main, varargs, array and signed-view probes pass;
  the global fixture also passes sequentially. Commands, statuses and complete
  observations are in `.tmp/sc-prototype/c4-probes.json`. Final C4 coverage and
  release validation remain outstanding; no full campaign was repeated.
- **Next concrete integration: C3 representation/runtime adapter and remaining
  C2 public cases.** Selected paired SB, publication and all four CAS probes
  give independently allowed full observations. The mixed example gives the
  race alternative natively and the safe alternative in Lean; these different
  selections are not a differential mismatch or complete outcome-set evidence.
  Commands/status/binary hashes are in `.tmp/sc-prototype/c2-selected-probes.json`.
  A native library-backed fence probe exposed prefix-closure cost. A temporary
  five-stage profile measured 2.959 seconds in source-graph closure and 2.764
  in lifted HB over 128 completed calls (debug run stopped at 15 seconds).
  The production closure now indexes incoming edges and per-vertex ancestors;
  the relation and general-graph fallback are unchanged. It agrees with the
  reference on all 512 three-vertex directed graphs and all 64 four-vertex
  forward graphs with sparse IDs. Both builds and SC suites/native controls
  pass. With timing instrumentation removed, the same native fence probe
  reaches explicit aggregate/value/library port obligations in 2.656 seconds;
  it is no longer a timeout and is still not supported. This is an exact
  relation-algorithm change, not dropped prefix checking or reduced exploration.
  Do not grow a separate exploration/checking framework.
- G06's chosen precise GCC preprocessor-observer experiment lacks the matching
  GCC 13.3 plugin SDK. A capability question is already pending; do not ask it
  again or bypass network controls. This blocks that experiment, not C1/C2.
  Do not guess an ABI or substitute invented lock-free constants.

## Exploration and evidence scope

[USER 2026-09-24] Exhaustive C exploration is a probe for very small examples;
enumerating all outcomes of mid-size and larger programs is not required for
this milestone. Complete outcome-set comparisons remain on the bounded
semantic/reference domain. Larger C cases use explicitly labelled selected
execution/prefix checks, with complete runs where feasible. Retain the actual
checker-disconnection, fault, blocking and exhaustion controls. This replaces
the former C2/C4 demand for complete whole-C outcomes of every named case.

This changes validation scope only. Preserve every operational choice, all
agreed semantic coverage and the fail-closed policy. A selected execution is
never evidence of whole-program safety or coverage. No exploration subsystem
or general optimization framework is required to complete this module.

C2 now has a real public scalar classification path. Both engines accept the
actual C `return 0` and ordered-atomic-read controls; the latter exhaustively
produces 441 executions with the same complete observation, returning 2. The
consolidated machine/adapter/native suites pass. The new closure calculation
matches all 512 three-vertex directed graphs; fence/relation controls compare
against the unchanged pinned definitions. Sampled actual C executions report
UB005 for the scalar race and allowed SC values for store buffering. These
samples are diagnostics, not complete-outcome evidence.

Exhaustive scalar-race and store-buffering C runs exceeded a 30-second bound.
The scalar-race run still exceeds that same bound after the closure repair.
Unsequenced atomic reads and the original strong-CAS seed exceed a 15-second bound. No complete
outcomes or support credit are inferred from those runs. A selected race trace
visits 19 ND choice nodes, and selected store buffering visits 109. The machine
exposes all Core choices; candidate acceptance does not solve enumeration cost.

The original CAS seed additionally reaches G07 in its final expression, which
mixes an atomic load with unsequenced ordinary reads. That expression is retained
as a boundary input. CAS seeds now sequence the final observation separately;
selected strong-equal runs return the independently expected 5. The sequenced
seed also exceeds the same 15-second exhaustive bound on both engines. These
selected runs do not supply complete C outcome-set evidence.

C2 remains incomplete. The scalar adapter's temporary port obligations are not
final exclusions; G06 and the other C3/C4 obligations still apply. SDK capability
remains separately pending: `nono why` confirms package metadata paths are not
OS-granted. No sandbox bypass or shared toolchain mutation was attempted.

## Scope and semantic boundaries

Use current Core execution and the concrete object model. In scope are
structured spawn/join, all current sequencing and helper paths, ordinary and
atomic RMW/CAS, initialization and fences, legal representation accesses,
lifetimes, varargs, reachable library/runtime effects, faults, blocking and
incomplete exploration. A scalar first integration is not the final language.
Weak-memory execution, new pthreads/ISO-thread-library implementations, customer
logic, whole-ISO mechanization and a general optimization framework are outside
this milestone. Fix structural costs that prevent the required examples running.

The reference is pinned Cerberus `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`,
including `Cmm_csem.sc_fenced_memory_model` and `sc_fenced_condition`, with the
executor's explicit NA/seq_cst domain. Preserve initialization and SC fences;
do not silently strengthen weak orders or substitute a different C++/RC11 model.
The scalar predicates do not interpret every lifetime, byte or metadata effect.
Completing that operational composition remains required work.

[USER] Evidenced unresolved semantic boundaries fail closed and every case is
documented. The [boundary register](2026-09-22_sc-boundary-register.md) owns the
policy, exact triggers, source evidence, reproducers and resolution criteria.
Unsupported is not C UB, false CAS, success or an empty behavior set. Preserve
completed effects, failure-time state, independent faults and other alternatives.
Available-guidance port work, checker limitations and difficult proofs do not
become new upstream gaps or broad exclusions of C constructs.

Three supporting specifications remain live; none is another execution plan:

- [Operational contract](2026-09-21_sc-operational-contract.md): reference,
  operation/outcome meanings and correspondence limits.
- [Boundary register](2026-09-22_sc-boundary-register.md): G/P/D cases and policy.
- [Effect inventory](2026-09-21_sc-effect-inventory.md): E01–E25 source/effect
  obligations; historical line numbers require checking against current source.

Historical SC reviews and repeated campaign archives were removed in C1 after
extracting live inputs and source conclusions. Their Git history is not an
execution queue.

## C1 — pruning decisions (implemented; deferred accumulator/query removals noted)

Keep the real Driver/Core scheduler, observations/ND lifting, suspension,
atomic/frontend/runtime surface, exact representation and source-location fixes,
filesystem failure-state repairs, and small executable source/action/HB queries.
Do not delete generated `Sc_*` runtime modules just because similarly named
handwritten `CerbSC*` wrappers are removed. Required measure proofs and executable
instances stay, including `CerbSCByteInstances` (imported by `sc_runtime.lem`),
`Sc_order_lemMeasureProofs` and suspension changes in `CerbNDFuelProofs`.

### Exact proof removals and relocations

All names below are under `lean_frontend/` unless a different path is shown.
Before deleting an exposed name, a read-only customer text search may identify
actual use. Preserve only a genuinely used operational law or a small alias;
this does not justify retaining the whole package or modifying the customer.

| Delete | Surviving payload / edits |
|---|---|
| `CerbSCMapTransport.lean`, `CerbSCLinkAttribution.lean` | No runtime consumer. Delete proof-only map safety/witness definitions and census references. Units/failure probe import the actual generated queries directly. |
| `CerbSCActionIdentity.lean`, `CerbSCHappensBefore.lean` | Delete the unconnected `Relation.TransGen`/prefix presentation and its theorem printouts. Keep executable `Sc_action_identity` and `Sc_happens_before`. |
| `CerbSCAtomicSources.lean`, `CerbSCAtomicSurface.lean`, `CerbSCAtomicUpdate.lean`, `CerbSCByteSources.lean`, `CerbSCFaults.lean`, `CerbSCGlobalAttribution.lean`, `CerbSCGlobalBindings.lean`, `CerbSCGraph.lean`, `CerbSCHelperOrder.lean`, `CerbSCParameterReads.lean`, `CerbSCRepresentation.lean`, `CerbSCScopes.lean`, `CerbSCSpawn.lean`, `CerbSCSynchronization.lean`, `CerbSCVarargs.lean` | Delete projection/constructor/list-law wrappers and printouts; retain the underlying definitions and branch-distinguishing behavior tests. |
| `CerbSCSequencing.lean` and `frontend/model/sc_reference_sequencing.lem` | Delete the separate conditional presentation. Move the six `CerbCmmEquality` instance-selection equations into `test/Unit/SCReferenceEquality.lean`; they cover a real target-selection defect. |
| `CerbFSProofs.lean`, `CerbFSDriverProofs.lean`, `CerbNDSuspension.lean` | Keep FS/suspension code and state-at-failure tests. Move `state_ordering_refuses` into `Unit.FSBoundary`; replace the test-only `node` helper with `CerbSCOperational.node` or a local helper. |
| `CerbSCByteKeys.lean` after consolidation | Move only needed lossless key/roundtrip/injectivity laws into `CerbSCValues`; do not claim these establish logical RF equality across typed views. |
| `CerbSCPrefixObligations.lean` when the final accumulator lands | Keep current runtime retention/tests meanwhile. Retain at most the actual public accumulator-preservation connection with its final API. |

Keep `CerbNDObserveProofs`, `CerbMemSuspension` and narrowly useful
`CerbSCAccessGroups` connections (disabled behavior, checked failure/current-state
retention, exact RMW ungrouping). Reduce `CerbSCOperational`/`CerbSCServices` to
actual offered-choice, history, restoration and projection connections; keep
`projectAction` with `projection_node`. No generic scheduler-proof project.

Update `handwritten_copy.manifest`, Lake roots/executables, Makefile source
lists, test/example imports, `tests/failure-probes/FailureReach.lean`, named
axiom-census entries and drift registrations. Remove only orphaned generated
copies/build artifacts. Search target `extra_import`/`target_rep`, not just Lean
imports. Regenerate both targets after shared source-list changes.

### Consolidate tests, gates, attribution and records

- Consolidate SC units into machine/memory and adapter suites, and native
  `memory/concrete/sc_*_controls` into one paired executable with useful fixture
  groups. Delete trivial field/self-equality tests and unused fixture copies.
  Keep distinct stale-state, partial-failure, alias, RMW and equality regressions.
  Inspect FS/float branch coverage before dropping individual control rows.
- Keep `tests/litmus` and `scripts/test_litmus.sh`; connect them in C2. Replace
  `test_litmus_observations.py` and `test_litmus_references.py` with one small
  runner integration selftest, then delete the old files. Reuse the shared codec;
  test actual runner commands rather than source slices. Retain membership,
  pending/wrong-result and failing/truncated-bridge controls.
- A selected `test_unit.sh` invocation must run its selected tests and necessary
  freshness precondition, not every global selftest. Batch builds; run each
  integrity check once at release level. Remove duplicate failure-reach dispatch
  and repeated Lem/Dune checks. Tool selftests run when that tool changes or at
  final acceptance. Remove per-law printouts, helper mutation/positive-clone
  campaigns and theorem-count milestones. Keep small no-axiom/sorry, purity,
  totality, explicit-fuel, source/freshness and fork/reference integrity checks.
- Keep the small reference derivation check (`sync_sc_reference.py`) and
  generated-addition support (`check_fork_generated.py`); avoid duplicate calls.
  Simplify fork-manifest chronology and redundant plants, retaining reviewed
  pins and actual membership/content checks. Do not refresh baselines blindly.
- Retain only attribution code consumed by the real G03/G08 producer in C3.
  Remove redundant `sc_link_global_step`/`sc_link_with_global_origins` paths now;
  `sc_link_attributed` already carries globals. Parameter-slot reads are not
  call-entry values: delete their query if the eventual guard does not use it.
  No new runtime-catalogue/authentication framework.
- Extract minimal live G01–G08 and distinct D09/D10/D12/D14/D15/D16 reproducers
  not already in tests, with source/pin and expected-class notes. Put inputs in
  the test hierarchy. Preserve unique location/value/lifetime/runtime source
  conclusions in the three specifications above, including the FS coverage map.
  Then delete `docs/2026-09-21_sc-prototype-evidence/**` and redundant SC component,
  research and work narratives. Keep concrete upstream-tray discrepancies.
  History remains in Git; no archive replacement or history rewrite.
- Delete obsolete `.tmp/sc-prototype` proof/query/census/mutation drafts and old
  campaigns after that bounded extraction. In particular, do not promote the
  runtime-catalogue, map/lifetime proof towers or `candidate_query.ml`. Retain
  necessary stream/internal-state/cross-view reproducers and the current raw
  run until superseded. Preserve a new unexplained mismatch until resolved.

**Acceptance:** useful runtime behavior unchanged; required instance/import
connections survive regeneration and affected compilation/tests; live boundary
reproducers and obligations are retained. No whole corpus rerun for proof/doc
removal. No claim that C1 itself delivers SC.

## C2 — connect actual public C-to-SC outcomes

1. Define the public outcome over the actual machine: completion/value,
   faults with state/effects, retained findings, unsupported reasons, blocking
   and incomplete exploration. One category must not erase another.
2. Connect recorded occurrences to C locations/atomic objects, logical values,
   initialization, reads-from (RF), modification order (MO), SC order and
   synchronization/HB. Use the retained small executable queries. Scheduler
   order is not source `sb`; one RMW's phases are not two atomic actions.
   State the supported scalar construction and coverage claim in the operational
   contract: actual reads supply RF, writes to each atomic object supply MO, and
   the selected seq_cst atomic/fence occurrences supply SC order. Checking each recorded candidate establishes
   membership, not coverage of every permitted execution. Preserve every offered
   scheduler/Core/ND choice; test complete bounded outcome sets on the independent
   scalar domain and use direct pinned-predicate controls for fences and repeated
   initialization. No new general adequacy theorem or gate hierarchy is required.
3. Preserve race and other established findings on prefixes, before loops and
   failed candidates. Candidate consistency rejection must not erase faults.
   Replace repeated whole-graph snapshots/closure scans with a justified shared
   or incremental computation where required. Use the existing query as a
   bounded reference; do not drop prefix checking or simply raise limits.
4. Wire `--concurrency=sc` and the reusable API through both actual frontends.
   Remove the unconditional completion-time `checker_pending` only when the
   classifier runs. Explicit temporary port failures remain visible.

**Acceptance:** real paired C SB/publication, CAS and fences plus a mixed
safe/racy alternative, fault before a loop, blocking and fuel exhaustion traverse
this API with independently justified observations. Exhaustive C probes are
limited to very small examples; larger cases use labelled selected/prefix
checks. Complete outcome sets remain required on the bounded semantic/reference
domain. Disconnecting the
production checker makes the C suite fail. Retain one existing helper-interleaving
and partial-failure control, with the permitted interruption/atomic-exclusion/FS
ownership rule and its source rationale in the operational contract. Passive
observation alone is not authority to add a scheduling point. This is an
intermediate milestone;
a scalar-only success cannot become the definition of done. No further passive
helper checkpoints before this connection exists.

## C3 — finish the agreed coverage and precise guards

| Obligation / actual consumer | Remaining work and distinguishing acceptance cases |
|---|---|
| Location/value/RF/MO/SC adapter | Legal array/member/aggregate and signed/unsigned views; initialization; aliases and differently based overlap; equal-valued stores as distinct sources; representation/provenance and NaN/signed-zero CAS. Raw pointer/range keys are not logical value equality. |
| Lifetime and metadata in the same findings policy | Allocation/create/free/reuse, zero size, DR403 ordering, partial helper failures, ordered char copy/compare/realloc, varargs copies/publication against actual HB. Do not silently discard effects outside the scalar reference. |
| Atomic/source/thread behavior | Exchange/fetch, strong/weak CAS and expected writeback, operand single evaluation, ordinary SeqRMW exclusions, nested spawn/join and child loop ownership, fences, invalid and out-of-model orders. |
| G02/G07 interpretation boundaries | Precise reached unresolved composition/atomic-sequencing witnesses, preserving independently justified UB and ordered/legal controls. Do not blanket-refuse representation operations. |
| G03/G08 library boundaries | Connect actual loader/link selection, calls and resource/global-storage evidence directly. Handle replacements/unknown origins, zero-length actual accesses, shared stream vs shared descriptor, implicit streams and shared internals. Missing library protection is not caller UB; ordinary buffers and disjoint/ordered accesses need controls. |
| G06 configuration consumption | Runtime and constant/preprocessor consumption fail explicitly when configuration is missing; ordinary inclusion/stringification must not change meaning. A plugin load marker is not an implemented guard. Bound the SDK-dependent callback experiment; do independent integration meanwhile. |
| Existing G/P/D and E01–E25 rows | Every in-scope path reaches supported behavior or an evidenced precise upstream boundary. Finish available port work; document transport correspondence honestly. Do not claim raw journal equality where C loaders differ or chase unrelated corpus bugs. |

**Acceptance:** every obligation above and each live effect row is accounted
for in production and a distinguishing test. No `checker_pending`, available-
guidance port gap or blanket language refusal counts as completion. Supported
cases preserve all required outcomes, including safe/faulting alternatives.
Required graph/runtime examples run at justified bounds; timeout/OOM remains
incomplete, not agreement or a semantic exclusion.

## C4 — provider interface and final acceptance

Expose the actual machine/outcome definitions with explicit fuel and address-
space parameters. Minimum provider interface for downstream Iris reasoning:

- An initialized whole-C configuration retaining the actual outer initialization,
  main and finalization continuation/phase, plus saved services. `driver_state`
  alone loses paused work; internal `SC_halted` during initialization is not
  whole-program completion.
- An executable step view or relation derived from the actual machine, covering
  every offered scheduler, Core and ND alternative and exposing resulting state
  and observations. A whole-machine presentation is sufficient; no separate
  Iris thread-language, logic or separation rules are required here.
- Distinct completion, fault, blocking, unsupported and exhaustion observations,
  retaining interpretation obligations. A supported/safe conclusion cannot result
  from omitting unsupported or unfinished alternatives.
- Explicit fuel meaning. If a successful-at-some-fuel relation is exposed, state
  its connection to execution and the stability needed for the claimed interface;
  hiding fuel existentially alone does not discharge that connection.

Finish only the internal correspondence/erasure claims made by that API; do not
introduce a second semantics or require whole-ISO adequacy. Rewrite
`examples/sc_consumer` to invoke this initialized whole-C API and demonstrate
an actual step/outcome preservation property, including finality or a retained
fault/gap. No customer build, logic, re-pin or mutation is part of this work.

Validate all SC case families above under the exploration scope above, actual production connection,
independent reference domain, and unchanged intended sequential behavior. Finish
one short usage/support record and update this status. Completion requires the
real C path and full agreed coverage with explicit evidenced boundaries, not
just passing component or inherited sequential tests. Mainline merge/push is a
separate action.

## Validation cadence and working rules

Use existing runners/codecs. These are acceptance properties, not new gates:

- Documentation edits: links/status/whitespace checks only. Proof/registration
  pruning: dependency inspection, fresh affected compilation and affected units.
- Semantic edits: affected SC units plus public C cases and sequential tests for
  the changed seam. Compare complete observations, states/prefixes where claimed,
  original statuses, output bytes and meaningful alternatives. Never weaken
  comparison or rerecord a baseline to conceal a mismatch.
- Instrument edits: focused selftest and a real lane control. One final mutation
  of the actual observer/checker connection; add another only for a demonstrated
  independent wiring blind spot. No recursive plants or per-helper campaigns.
- Final C4: existing full A+B release once on the candidate, actual SC production
  suite, mandatory three-engine report once, independent pinned predicates and
  finite scalar litmus checks on their justified domain, and the external example.
  Pristine's broken SC mode is not an SC oracle. No unrelated csmith/CI campaign.
  Later changes rerun invalidated obligations, not all historical campaigns.
- Keep source/build identity, command/bounds, status and raw observations once
  per relevant run. Reuse unchanged evidence. Delete duplicated archives and
  compiler-attempt chronicles; retain live minimal failure reproducers.

This cadence governs SC over older per-helper/per-slice instructions in
`LADDER.md`, `VALIDATION.md` and component notes. The inherited integrity,
no-axiom/sorry and full-observation rules remain. Change runner dispatch as C1
requires; a documentation update alone does not change the scripts' behavior.

Use the owning worktree through `/home/dev/projects/cerberus-lean-proj/scripts/ce`;
Lean/Lake always run capped from their owning package, with fresh generated and
handwritten copies. One heavy worker; bounded cases; no limit increase to hide
structural problems. Follow the hour-long build/proof stop rule. Customer
`/home/dev/projects/cerberus-sl` is strictly read-only. Do not mutate shared
`_opam`, dependencies, other branches or the primary checkout.

Report at each checkpoint, significant blocker, or half-day of active work:
which public acceptance case advanced and the next concrete missing behavior.
If no case advances, re-evaluate the dependency chain before adding a mechanism.
No new standalone helper without an immediate production consumer; no generic
proof, catalogue, authentication, archive or gate-management project. Record
current status here, technical meaning in the contract, and cases in the
boundary/effect maps. Do not create a competing roadmap or progress file.

To resume: read this file, the applicable `CLAUDE.md`, and `git status`; inspect
the current checkpoint's actual implementation and results, then execute its
next action. Scratch audits and historical work records are supporting material
only. Do not restart research, resurrect discarded plans, or infer completion
from old green reports.
