# SC semantic boundaries and implementation obligations

2026-09-22. Live register under the
[user's general fail-closed policy](2026-09-21_sc-upstream-gap-policy.md).
Production status below is audited against `3864dbb1f438d5efecdd10748c8d3bf1a05c9e9c`.
Reference identities remain the charter's base `5407597d9` and pristine
Cerberus `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`; no replacement mixed-size
reference has been adopted. Historical evidence records proposals and earlier
statuses; this register records the subsequent user decision.

The register covers known SC boundary cases from the effect inventory, reference
follow-up and typed-fault audit. It is not a claim that every possible upstream
omission has been discovered. Add new cases before treating their refusal as
intentional coverage. Never describe a proposed guard as implemented.

## Evidenced unresolved semantic boundaries

| ID | Boundary | Current enforcement | Required outcome |
|---|---|---|---|
| SC-G01 | CAS comparison depends on unspecified representation bytes | Implemented in the driver's `CompareExchangeObjectRequest2` arm: `SC_fault_unspecified_representation` | Explicit representation gap, preserving reads/state |
| SC-G02 | Concurrent representation accesses require unresolved location/RF composition | Precise guard and checker integration outstanding | Explicit location/composition gap; no race-free or UB verdict inferred from the inadequate projection |
| SC-G03 | Concurrent use of a runtime stream requires missing stream synchronization | Precise guard and call/stream identification outstanding | Explicit runtime-model gap; library implementation races must not become ISO caller UB |

### SC-G01 — unspecified bytes in compare-exchange

The C17 resolution of DR431 specifies representation comparison. The concrete
model can still supply unspecified bytes, for example padding. Comparing
`MemValue`s, choosing fresh padding or nondeterministically declaring equality
would fabricate a result not provided by the pinned composition. Sources and
WG14 links are in the [primary-source follow-up](2026-09-21_sc-primary-source-followup.md);
reproductions are in the [CAS decision record](2026-09-21_sc-prototype-evidence/cas-representations/decision.md)
and the [atomic slice review](2026-09-22_sc-atomic-slice-review.md).

**Trigger implemented:** `Sc_representation.sc_compare_representation` reports
an unspecified comparison, and the CAS object phase returns
`SC_fault_unspecified_representation`. The expected and object reads already
performed, journal and current state are retained; no expected writeback,
object store, false return or C UB is invented. Definite equality/inequality,
weak spurious failure, pointer representations, signed zeros and NaNs have
separate controls. This is not a blanket aggregate or floating CAS ban.

**Revisit:** a pinned upstream resolution of unspecified-byte representation
comparison, with controls for padding and pointer provenance. The earlier
struct-CAS frontend failure is a distinct implementation path, SC-P02 below.
Representation-size disagreement is a separate invariant fault, SC-D01.

### SC-G02 — representation access, location identity and reads-from

The Core adapter `frontend/model/cmm_aux.lem` leaves footprints/value combination
unfinished. `frontend/concurrency/cmm_csem.lem` uses equal scalar locations in
`data_races` (including its footprint model); the scalar action has no width.
The BMC `same_loc` operation is asymmetric by access kind and assumes a single
writer for reads-from. None supplies a complete adapter from the concrete
representation journal to C memory locations and multi-write read values.

The [reference proposal](2026-09-21_sc-prototype-evidence/reference-followup/location-reference-decision.md)
and [mixed-size review](2026-09-21_sc-prototype-evidence/reference-followup/mixed-size-reference-followup.md)
link the pinned source and published alternatives. The retained diagnostic
archive in the [reference evidence](2026-09-21_sc-prototype-evidence/reference-followup/README.md)
contains `location-journal-6`, six actual C-to-recorder runs. An eight-byte read
of an unsigned long and a write to its second byte are unordered in different
threads: the pointer-only scalar projection misses their overlap. Two writes
to different representation bytes of one scalar also distinguish competing
location interpretations. Distinct character-array elements and distinct
scalar structure members must remain distinguishable; allocation-wide identity
would incorrectly conflate them. Equal-address and join-order controls exercise
positive and negative cases. These are recorded traces and actual predicate
probes, not complete consistent candidates or upstream whole-program verdicts.

**Guard obligation:** identify the actual accessed subobjects, source ordering,
atomicity and contributing writes before deciding whether this unresolved
interpretation is required. The unordered mixed-width and scalar-representation
cases above must stay visibly unsupported while unresolved. A bare difference
in widths, a character type, a shared allocation or failure of the scalar
checker domain is insufficient. Ordered representation operations remain an
implementation obligation. The physical byte-source journal is available; it
does not itself define Cmm RF or settle nonoverlapping bytes within one scalar.

**Current behavior:** no dedicated SC-G02 guard exists yet. Public SC completion
still returns `SC_fault_checker_pending`; internal `drive_recorded` can expose
these traces and must not certify them. Preserve all accesses, lifetime vertices,
bytes/provenance, state and already established faults when the guard is added.

**Revisit:** a pinned upstream composition resolving these cases, or an explicit
future user decision to add a named reference. The 2017 mixed-size model changes
race/RF predicates and leaves general character access to atomic objects outside
its scope. The current user decision retains the pinned reference.

### SC-G03 — missing runtime stream locking

Pinned `runtime/libc/src/stdio.c` has `locking_getc`/`locking_putc` implementations
that simply call the unlocked operations. `vfprintf` supplies a file descriptor
to the Core builtin after `fileno(f)`, losing `FILE *` identity. N1570 7.21.2p7–8
requires a reentrant lock per stream. A descriptor, filesystem transaction owner
or global runtime order cannot silently replace it. See the
[source review](2026-09-21_sc-prototype-evidence/reference-followup/stdio-source-review.md)
and [journal review](2026-09-21_sc-prototype-evidence/reference-followup/stdio-journal-review.md).

`stdio-journal-3` in the retained reference archive executes actual libc:
parallel `fputc('A', stdout)` / `fputc('B', stdout)` records 271 effects and
31 unordered cross-thread overlapping access pairs; sequential calls record
220 effects and none. These selected runs demonstrate missing synchronization,
not exhaustive SC outcomes or caller UB. Buffered stdout is empty in these
captures; no flush result was inferred.

**Guard obligation:** identify executed stream operations and the stream object
whose required synchronization is missing. Inter-thread stream use that depends
on those missing lock effects requires SC-G03; ordinary buffer formatting
(`vsnprintf`), unrelated streams and source-ordered calls must have controls.
Detect the boundary before treating omitted library locking as a C data race.
Do not equate descriptors with streams or introduce a global hb edge.

**Current behavior:** no dedicated guard or complete stream-identity adapter.
FS service ownership protects resumable abstract FS transactions only. It does
not supply C stream synchronization. Public verdict checking remains pending.
Retain actual memory/FS effects, output, state and independent established faults;
do not synthesize lock effects after the fact.

**Revisit:** pinned upstream stream-lock operational semantics plus a faithful
stream-identity/call adapter and concurrent/sequential/distinct-stream controls.

## Open work that the policy does not excuse

These entries are mandatory completion/review obligations, not permissions to
turn every listed feature into a semantic-gap refusal.

| ID | Case, evidence and current status | Completion or review obligation |
|---|---|---|
| SC-P01 | `Driver.drive true` ends recorded completion with `SC_fault_checker_pending`; public race/consistency and program-level outcome interface unfinished | Connect prefix fault detection, SC consistency and explicit incomplete outcomes; retain faults before divergence and across rejected candidates. A refusal is not a completed checker. |
| SC-P02 | Atomic frontend paths: postfix/prefix/compound operations, exchange, fetch/flag functions, signal fence, runtime-valued orders, non-synchronizing atomic initialization, earlier struct-CAS cast defect; `_Atomic int` qualifier syntax drops atomicity in retained S0 probes | Implement available operation-specific semantics through actual C lowering and journal. Preserve single evaluation of operands, arithmetic and failure prefixes. See [remaining atomic audit](2026-09-21_sc-prototype-evidence/reference-followup/remaining-atomic-source-review.md), [S0 evidence](2026-09-21_sc-prototype-evidence/s0), and CAS evidence above. Signal fence must not become inter-thread synchronization. Legacy conditional `RMW` is not unconditional exchange. |
| SC-P03 | Scalar Cmm RF uses instantiated `MemValue` equality: identical-bit NaNs compare unequal; opposite signed zeros compare equal in the actual four predicate probes | Build a faithful logical-value/representation/provenance adapter. Do not restrict C NaNs or casually change generic memory equality. See [value audit](2026-09-21_sc-prototype-evidence/reference-followup/cmm-float-values-review.md). Predicate rejection alone is not a C fault. |
| SC-P04 | Effect inventory E03–E05/E10: allocation, deallocation, metadata zapping and address reuse; scalar SC checker excludes lifetime actions and its lifetime sketch is commented out | Preserve concrete lifetime transitions and derive composition from C/DR403. Keep dynamic deallocation/reuse distinct from automatic lifetime end; zapping is not an invented source store. No blanket dynamic-allocation refusal. A concrete unresolved case must get its own SC-G entry if found. |
| SC-P05 | E21: abstract varargs ids/cursors are preserved. Four [actual C traces](2026-09-21_sc-prototype-evidence/varargs/README.md) distinguish shared metadata from `va_copy` and join-ordered controls; the source audit finds available semantic guidance | Implement the per-id metadata location/conflict adapter alongside ordinary memory accesses. Pair counts in the selected traces are diagnostics, not SC verdicts. Preserve `va_arg` cursor updates, independent copies and deletion; no invented byte writes or blanket variadic-call refusal. |
| SC-P06 | Helper source order/resumption, child errno, SC fences and CAS were originally open mechanisms; current slices have implemented controls/laws | Retain completed evidence and finish correspondence/interface integration. Do not relabel these as upstream gaps; SC fence runtime coverage uses the reviewed fence-aware reference, not the narrower scalar checker alone. |

## Other explicit boundaries and fault identities

| ID | Boundary | Required classification and action |
|---|---|---|
| SC-D01 | CAS representation-size disagreement; missing request/phase owner, wrong owner, outside-mode phase, missing unique read, uninitialized state, lost observer state or unowned memory effect/node | Existing typed protocol/representation diagnostics. They are invariant or adapter failures, not proof of ISO UB or a new semantic coverage exclusion. Preserve state; repair reachable defects. |
| SC-D02 | Memory observer or suspension unavailable in another object-model instance | Explicit `SC_fault_observer_unavailable` / `SC_fault_suspension_unavailable`; concrete default is the charter instance. Supporting another instance needs its effect implementation, never an empty journal. |
| SC-D03 | Executed memory order outside the named SC model | `SC_fault_order` with request kind. Preserve exact order; do not silently strengthen it. Separate invalid operation-specific orders from merely out-of-model orders when the final outcome interface is connected. |
| SC-D04 | E23 concrete memory intrinsic is already unsupported; other models have different implementations | Preserve model-specific failure. It is not an effect-free intrinsic or authority to disable another model's operation. |
| SC-D05 | Existing upstream frontend limitations, including bitfields; existing memcpy-overlap UB-check omission | Preserve and disclose individual upstream behavior/limitations. The policy is not authority to silently change existing sequential semantics or ban every memcpy. Source checklist: [effect inventory](2026-09-21_sc-effect-inventory.md). |
| SC-D06 | Fuel/resource exhaustion, blocked execution, ordinary model errors and C UB | Preserve distinct payloads and states. Exhaustion does not establish safety; blocking is not normal value completion; implementation assertions/backtraces are not C semantics. |

The 21 constructors of `Sc_runtime.sc_fault` at the audited checkpoint are
accounted for by SC-G01, SC-P01 and SC-D01–D03. Their current coarse category
`SC_failure_representation` includes both SC-G01 and size disagreement; consumers
must use the typed identity, not assume that category means upstream ambiguity.
The planned SC-G02/03 outcomes need their own identities and contextual evidence.

The subsequent [source-graph slice](2026-09-22_sc-source-graph-review.md) adds
`sc_graph_issue` diagnostics for duplicate/missing occurrence IDs, erroneous
thread annotations and cycles. These are also SC-D01 protocol findings. The
query retains malformed data and diagnostics; its lack of diagnostics is not
a complete Cmm well-formedness, consistency or SC support verdict.

## Preservation and client contract

Every unsupported outcome names the registered case and retains its triggering
occurrences and full failure-time operational state, including completed effects
and resumable services. If a checker diagnoses the boundary from a retained
prefix, keep that prefix; do not pretend the earlier execution was rolled back.
Do not manufacture success, false CAS, C UB, impossibility or an empty execution
set. Other alternatives and previously established faults remain reportable.

A customer theorem can prove that its inputs avoid a boundary. That hypothesis
does not restrict provider execution. Whole-program support/safety cannot be
certified by discarding unsupported or exhausted paths. Customer source remains
strictly read-only; this register imposes no customer migration or logic change.

For each implemented guard, append the source commit, exact producer and typed
outcome, minimal regression and distinguishing controls, checked state/effect
preservation, paired OCaml/Lean evidence, and applicable integration results.
On resolution, retain the ID and evidence, mark the case resolved with the new
pinned reference and replacement behavior, and keep its regression controls.
