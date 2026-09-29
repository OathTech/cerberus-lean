# Prototype quarry: candidate machinery and rejection reasons

Read this under the governing [SC concurrency master plan](../../SC-CONCURRENCY.md)
and its [technical design](2026-09-24_sc-concurrency-design.md). This inventory grants no component
a correctness presumption. “Candidate” means inspect or extract only as part of
the named, independently validated slice. Prefer a smaller rewrite if extraction
would preserve the failed architecture.

Updated 2026-09-25 for the [independent plan review](2026-09-25_sc-concurrency-plan-review.md):
initial WP0 closes at load/store observation; the actual bounded program step
belongs in S1; later receipts and saved services enter with their consumers.
Preserving an ND continuation does not establish a bounded transition.
The [MVP scope decision](2026-09-25_sc-semantics-mvp-scope.md) defers Iris
integration; the transition API's immediate uses are execution and validation.

## Evidence identities and limits

* New base: `e9f9d049ffaaf005c392495b0f6418d21f4df29f`.
* Latest implementation inspected: `631382a9d23a709112f38add53357d4cbe6fc108`
  (`arc/sc-prototype`); all donor paths/line numbers below refer to that tree.
* Earlier failed implementation: `086d8762d382eff375c101f5f0c64d3ffe9bccc7`
  (`feature/concurrency`). Its September 19 audit is an additional source of
  byte/overlap/memop counterexamples, not a recovery charter.
* Common base: `5407597d9eeba0259d65b728e86a860ad4614ab3`.
* Pristine reference: `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`.

The donor review and inventory were first read as working files, then checked
again after the documentation-only handoff landed at
`4860f0ef0d20f2a2a4d8d96e6ecfc7b2c99ceed2`:
`lean_frontend/docs/2026-09-24_sc-independent-scope-review.md` and
`2026-09-24_sc-branch-inventory.md`. They are not part of the pinned implementation commit. Their recommendations
were not adopted as instructions. That
inventory calls several components “keep”; this assessment deliberately grants
only candidate status. This investigation used source inspection, direct donor
probes, separate mainline/pristine controls, and primary literature. It does not
claim a fresh independent-agent audit or full validation of donor components.

## Candidate extraction units

| Candidate / donor source | Potential value | Dependency and independent acceptance boundary |
|---|---|---|
| **Checked ND lifting:** `frontend/model/nd_observe.lem`, `CerbNDObserveProofs.lean` | Preserve state/effects when an underlying primitive fails; keep alternatives and constraints visible. | WP0/F1. Requires exhaustive handling of the ND constructors actually on mainline. Do not import `NDsuspend` in WP0; it is a later constructor/granularity decision affecting bind, lift, runners and fuel proofs. Check failure-before/after-observer combinations and explicit resource behavior. A theorem about a supplied post-state is not proof that it is the correct post-state. |
| **Primitive effect capture:** additions to `mem.lem`, `mem_common.lem`, concrete `impl_mem.ml`, `CerbMem.lean` | Observe actual reads, same-value writes, representation bytes, allocation/lifetime and metadata without reconstructing effects from store differences. | Initial WP0/F2 is only paired load/store observation plus its diagnostic consumer. Compare raw memory transitions, returned failure state, alternatives, failure prefixes and disabled-observer erasure. Later allocation/helper/metadata capture enters with its first execution consumer. Receipts are not C actions or scheduler boundaries; no historical snapshot sequence. Do not copy SC interpretation. Other memory models' unavailability stubs are not concurrency support. |
| **Saved service continuations:** `driver.lem:1948–2107`, `CerbMemSuspension.lean`, `CerbSCServices.lean` | Resume memcpy/runtime helpers against current shared state; avoid stale captured snapshots and repeated Core requests. | After WP1, with the first concurrent helper consumer in S1/S4; not a general framework prerequisite for S1. Justify observation/suspension boundaries, then force another thread to change/deallocate memory between phases. Check FS transaction commit and ownership independently. Never call FS ownership a stream lock. |
| **Thread scheduler:** `sc_thread_choices`, `sc_machine_choices`, `sc_step`, Core spawn/wait changes | Enumerate thread/Core alternatives and structured fork/join. | S1 after WP1. Recover the scheduler idea, not all current machinery. It presently depends on journal-scanning `sc_control` and on expanded Core constructors. Hand-enumerated schedules must expose omitted choices and unchosen-thread effects. Child errno allocation exists at `driver.lem:1861`; test its actual allocation, initialization and failure behavior separately from spawn bookkeeping. |
| **Continuation-scoped sequencing:** `sc_order.lem`, `core_reduction.lem`, `core_run_aux.lem` | The donor recognizes positive/negative effects, weak/strong sequencing and call boundaries. | WP1 feasibility experiment, then S2. Derive source relations independently of emitted edges, attach summaries to actual continuations, establish a meaningful invariant and test first conflicts. Count coordinates/retired references under repeated source split/join and fork/join. Do not copy predecessor sets, whole-expression rewrites, `sc_thread_effects` scans or occurrence-closure queries into the fast path. |
| **Atomic order validation:** `atomic_order.lem` (58 lines) | A small table can separate invalid C orders from valid orders outside the SC instance. | F4 normally accompanies S3; a narrow current-use fix may land separately but never holds initial WP0 open. Derive the table from the selected C rules; exhaust combinations and invalid encodings. CAS order strength is not enum ordering. Check arguments are evaluated exactly once and errors do not erase prior effects. |
| **RMW/CAS object phases:** driver request handlers, `core_reduction.lem`, memory seams | Indivisible atomic updates, strong/weak CAS and expected writeback. | S3 after WP1, divided by operation. Check independent complete tiny outcomes, pointer/value/representation behavior and failing phases. Preserve ordinary `SeqRMW` source semantics. Core-only tests do not establish C lowering or callable-library coverage. |
| **Atomic C surface:** typing, `translation.lem`, builtin recognition, `stdatomic.h`, `stdatomic.c` | Real C programs can reach the operations. | S3 after WP1 as several syntax/lowering/runtime changes. These span many Core consumers; regenerate from current sources. Verify declarations, argument effects, function pointers, generic forms and runtime linking. The lock-free `#if` problem remains open; no broad header transplant. |
| **Representation-preserving values:** `sc_value.lem`, `CerbSCValues.lean`, float/value seams | Preserve provenance and floating representation needed for correct CAS/byte observation. | WP0/F3 only for needed representation access; otherwise S3 or independent sequential fixes. Verify against actual byte conversion, NaN/signed-zero cases and pointer provenance. Do not introduce a second universal value encoding unless a landed caller needs it. Source-level value equality and representation equality are different obligations. |
| **Core source-location transport:** parser/printers, `cerb_location_json.ml`, `cabs_json.ml`, `CoreParser.lean` | Useful diagnostics and source attribution. | A separate optional diagnostics slice, not a prerequisite for all SC semantics. Prove/test semantic erasure and round-trip structure with independently expected positions. Check parser failure behavior. Its large regenerated libc fixture must be derived afresh, not copied. |
| **FS failure-state repairs:** `fs_checked.ml`, `fs.lem`, `CerbFS.lean`, driver callback changes | Concrete independent improvement if an existing operation loses effects or fabricates success on failure. | Separate sequential repair per operation. Compare actual native/Lean failure states and negative controls. Do not inherit the full directory/link/permission port as a prerequisite for SC. |
| **Reference derivation:** `sync_sc_reference.py`, `sc_reference{,_aux}.lem`, Cmm equality-target edit | A small, correctly pinned checker can provide bounded external evidence. | Validation-only dependency. Independently verify the transform against pinned upstream definitions, carrier equality and all used predicates; add corruption controls. Do not interpret “independent carrier” as an independent specification. Keep it out of runtime imports/calls added for SC. |
| **Whole-program continuation API:** `driver.lem:2716+`, `CerbSCOperational.lean` | A program configuration includes initialization/main/finalization and suspended services; driver state alone is insufficient. | WP1 bounded-step experiment, S1 actual API, S5 stabilization with production execution examples. `sc_program_node` merely runs stored ND work: it does not guarantee a bounded step. Require singleton-path yield, step-budget exhaustion, pure discovery and step/run state/events/resource agreement. Iris integration is deferred. The donor's `fault_retains_assertion` assumes its post-state assertion and supplies no semantic preservation evidence. |
| **C regression inputs and harness failure controls:** `tests/sc`, `tests/litmus`, runner plants | Preserve specific questions about semantics and test instrument integrity. | Inputs may be copied with provenance, as done here. Derive expected sets anew from independent sources. The donor runner hardcodes exhaustive mode and `--nolibc`; it cannot be the new acceptance policy. Keep mainline's observation codec and correct exit-status handling. |

The donor commit grouping is not this dependency grouping. For example,
`4bba2b458` is a useful search starting point for observation work,
`06681abd3` for scheduling, `3864dbb1f` for resumable services, `fb72dd9fb`
for CAS, and `fad4c0428` for the whole-program API. They are not recommended
cherry-picks. Read the final source and extract the minimum current-base diff.

## Components to replace or leave behind

| Donor component | Disposition and reason |
|---|---|
| `sc_note_prefix`, `sc_interpret_driver`, final candidate admission in `drive` | Remove from the proposed runtime design. Graph reconstruction must not determine values, progress, faults or supported ordered object operations. |
| `sc_candidate.lem` as a universal object interpreter | Do not salvage as production semantics. Single-writer/same-range RF cannot represent ordinary byte composition. Some projection code may be useful in an independently checked offline exporter. |
| Global `interpretable` guard on new races | Reject. Unrelated projection uncertainty must not erase independent runtime findings. Also reject its naive inverse: deleting the guard does not establish absent synchronization. |
| `sc_graph`, occurrence-closure/HB queries, full predecessor journals | At most offline explanation/reference material. Any necessary runtime ordering query must have a summary invariant and scale evidence. |
| Alternative source/HB interpretations in `sc_atomic_sources`, `sc_synchronization`, `sc_access_sequencing` | No automatic migration. Choose one semantics/production interpretation; isolated tests of duplicate routes do not validate it. |
| Broad library-call attribution refusal plus private-slot exceptions | Replace with actual operation/object support conditions. Sequential or private library work is not unsupported simply because it has library provenance. No automatic inference of missing-lock UB for the caller. |
| Universal `sc_*.lem` module family, proof/test campaigns and generated outputs | Do not migrate as a package. A module/test/proof enters only with an immediate purpose in a reviewed slice. Regenerate authoritative sources; do not copy cached Lean/OCaml artifacts. |
| Old status ledgers, gates/baselines and “complete” claims | Historical evidence only. Baseline movement requires its own explanation. A green old lane cannot grandfather a semantic change. |

## Mainline conflicts that extraction must respect

Source intersections include `driver.lem`, `core_reduction.lem`, `core_run.lem`,
`core{,_aux,_typing,_linking}.lem`, `translation.lem`, AIL typing/desugaring,
`mem.lem`, `mini_pipeline.lem`, `CerbMem.lean`, `Main.lean`, driver measure proofs,
Lake roots and multiple validation registers. Current mainline changed these
after the donor base. The run-digest and arity repairs are especially easy to
lose by copying a donor file wholesale.

Generation remains through the existing Makefile/handwritten manifest, and
Lean builds use `scripts/capped`. Run the checks invalidated by each slice;
retain the existing release gates before a public SC landing. Never accept an
output from a stale generated file as validation of a newly extracted source.

## What the initial investigation actually extracted

Only 21 small C files were copied from the pinned implementation, with exact
hashes and source paths in [`provenance.json`](../../tests/sc-recovery/provenance.json).
One new member-access-before-race-loop input records a distinguishing failure
suggested by source inspection. These inputs are proposed tests, not an adopted
oracle or a claim of supported SC execution on this branch.

The two ordered failures were freshly reproduced on the donor's native and Lean
binaries. Separate mainline and pristine native binaries returned the expected
1, 42 and 0 for the byte-update, initialized-members and aggregate-copy controls.
[Sequential controls](sc-recovery-evidence/sequential-controls.json). No runtime
implementation is certified or transplanted by this investigation. The SC build
starts from current mainline and requires evidence per extraction. The master
plan owns current status; this section records only the initial investigation.
