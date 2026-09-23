# SC semantic boundaries and implementation obligations

2026-09-22. Live register under the
[user's general fail-closed policy](2026-09-21_sc-upstream-gap-policy.md).
The original production audit was at `3864dbb1f438d5efecdd10748c8d3bf1a05c9e9c`.
Subsequent source-graph, [atomic-update](2026-09-22_sc-atomic-update-review.md)
and [atomic-interface validation](2026-09-22_sc-atomic-surface-review.md)
are incorporated below, with the September 23 reference findings. Unimplemented
guards remain labelled as such.
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
| SC-G04 | Executed abstract unspecified atomic memory order | Typed Core producer implemented; paired controls, full Tier A+B and three-engine comparison pass | Preserve completed arguments and independent known-order UB; no chosen order or synthetic conditional UB |
| SC-G05 | Generic atomic pointer fetch add/sub in the contradictory C11/reference domain | Typed update-body producer implemented; paired controls, full Tier A+B and three-engine comparison pass | Preserve checked object read; no pointer arithmetic result or store invented |
| SC-G06 | Consuming lock-free properties without a pinned target configuration | No complete query/constant/preprocessor guard; numeric `#if` still silently treats absent markers as zero | Explicit configuration gap where a property is required; no invented all-lock-free or never-lock-free policy |
| SC-G07 | Unsequenced C atomic evaluations encounter the pinned Cmm function-call assumption | Actual C traces and predicate discrepancy retained; precise composition guard outstanding | Explicit sequencing/composition gap; preserve independently justified faults and actual source order |
| SC-G08 | Concurrent library operations depend on omitted synchronization of shared internal state | Actual `at_quick_exit` registration traces retained; precise internal-object guard outstanding | Explicit runtime-model gap; omitted implementation protection is not caller UB |

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

### SC-G04 — abstract unspecified atomic orders

The [interface review](2026-09-22_sc-atomic-surface-review.md) gives the source,
standards and [pristine reproductions](2026-09-21_sc-prototype-evidence/atomic-surface-reference/README.md).
The current producer is Translation.translate_atomic_explicit through
translate_atomic_order_cases: a reached LVunspecified order emits
Errors.Model_gap with Core.Model_gap_unspecified_atomic_order. This guard is
implemented with paired Core/C, prefix and simplifier-sensitivity controls.
The [retained interface checkpoint](2026-09-21_sc-prototype-evidence/atomic-surface/README.md)
passes all 39 Tier A+B commands and the 864-case three-engine comparison.
Specified runtime orders
remain ordinary port work, not a gap. Invalid specified orders use the proper
library UB after arguments; known invalid CAS counterparts take precedence.
No general rule for every unspecified library argument is introduced.

**Revisit:** a pinned operational rule for consuming abstract unspecified orders,
including its relationship to DR451/library concretization. Required controls
cover discarded results, dead branches, argument effects and prior UB, mixed
known/unspecified CAS orders, exact diagnostic identity and failure-time state.

### SC-G05 — generic pointer fetch

The C11 applicability/address conflict and later resolutions are documented in
the [interface review](2026-09-22_sc-atomic-surface-review.md). The current
Translation.AtomicFetchExplicit pointer arm emits Errors.Model_gap with
Core.Model_gap_pointer_atomic_fetch in the AtomicUpdate body. This is an
implemented guard, exercised by paired Core/C and prefix controls, after argument/order processing and the
checked object read, before a store or result. Its domain is generic pointer
add/sub; ordinary atomic pointer increment/compound assignment are unaffected.
It is not a blanket pointer ban or a claim that the caller has C UB.

**Revisit:** a pinned resolution of the generic pointer-fetch domain and its
operational meaning. Required controls include both generic operations, a
discarded result, dead calls, argument/order faults, retained read/no write and
ordinary pointer-operator controls.

### SC-G06 — missing lock-free target configuration

The ten `ATOMIC_*_LOCK_FREE` markers and generic query lack a pinned target
configuration/provider implementation. The [pristine and fork probes](2026-09-21_sc-prototype-evidence/atomic-surface-reference/README.md)
show ordinary uses failing and numeric `#if` silently consuming the missing
identifier as zero. That is not evidence that the type is never lock-free.
SC request indivisibility does not determine these implementation properties.
The [follow-up review](2026-09-21_sc-prototype-evidence/boundary-followup/lock-free-review.md)
records DR458's preprocessing requirements and DR465's type-consistent/null
query rules, and the rejected or incomplete preprocessing experiments.

**Guard obligation:** identify the interface that actually requires unresolved
configuration. Runtime queries must evaluate arguments once without loading
the object; null pointers are permitted. Constant and preprocessing uses also
need an explicit result, without silently selecting zero. Neither a blanket
header refusal nor a warning that the source can suppress closes this gap.
The candidate division-by-zero marker changes stringification and is unadopted.
`atomic_flag`'s guaranteed flag-operation behavior is distinct from the generic
query's type domain; the current struct representation cannot settle that domain.

**Current behavior:** no dedicated producer or complete preprocessing guard is
installed. The retained `implementation-1` is unbuilt and unadopted. The silent
preprocessing fallback is an open defect, not a supported configuration.

**Revisit:** a pinned target configuration and its operational query semantics,
or precise unsupported diagnostics for every consuming interface. Available
argument/constant-expression rules remain implementation obligations.

### SC-G07 — C atomic sequencing and the pinned Cmm assumption

The [sequencing review](2026-09-21_sc-prototype-evidence/boundary-followup/atomic-sequencing-review.md)
retains five actual C-to-recorder controls. Implicit `_Atomic` reads and
`atomic_load` macro reads in `x + y` have no source-order edge between them.
Comma and ordinary function-wrapper controls have the expected edges.
Separate actual Cmm two-action probes reject the unsequenced SC read pair in
`indeterminate_sequencing` and `well_formed_threads`, with no unsequenced-race
witness. Sequenced SC reads and unsequenced ordinary reads pass. The probes
are not complete consistent candidates: they omit initialization/RF witnesses.

The predicate's source cites the C++ assumption that all atomic/lock accesses
are function calls. N1570 6.5p3, 6.5.2.2p10 and 7.1.4 footnote 186 distinguish
the C implicit-access/macro cases. The pinned unsequenced-race predicate also
excludes atomic locations. Removing one predicate without reviewing the other
would not justify a faithful C composition.

**Guard obligation:** recognize the precise unresolved composition, preserve
the actual pair and source graph, and retain independently established faults.
In particular, independently justified 6.5p2 faults for unsequenced modifications
of one scalar must not disappear behind this gap. The two-read diagnostic
deliberately avoids that case; update/read controls are required before adoption.
Scheduler order must not become an invented source edge, UB or empty behavior.

**Current behavior:** no dedicated guard. Public completion remains
`SC_fault_checker_pending`; the internal recorder cannot certify these traces.

**Revisit:** a pinned resolution of both assumptions in the C operational
composition, with implicit/macro/function and independent-fault controls.

### SC-G08 — synchronization of shared library internals

The [runtime review](2026-09-21_sc-prototype-evidence/boundary-followup/runtime-review.md)
retains an actual parallel `at_quick_exit` registration trace: 141 effects,
five unordered cross-thread overlapping access pairs on internal `count`
(allocation 59, `stdlib.c:217–218`), return zero and empty output. Source-ordered
registrations have 137 effects and no such pair. Neither calls `quick_exit`.
N1570 7.1.4p5 requires protection of shared library internals; 7.22.4.3's
qualification about racing termination does not excuse two registrations.

**Guard obligation:** identify executed, resolved library operations and the
actual affected internal object. Function spellings, filenames or a global
runtime order are insufficient. Missing protection must not become ISO caller
UB or an invented global synchronization edge. Keep explicit library exceptions
such as `rand`/`strtok` separate, and preserve state and independent faults.

**Current behavior:** no dedicated guard. Four open/close probes time out
without completed journals; those are incomplete follow-ups, not evidence of
a reached open-file-list conflict. Same-stream and distinct-stream controls
corroborate SC-G03 with 31 and zero unordered overlap pairs respectively.

**Revisit:** pinned operational protection for the shared internals, with a
faithful adapter and concurrent/ordered controls. Any further internal-object
case must carry its own evidence and precise scope in this register.

## Open work that the policy does not excuse

These entries are mandatory completion/review obligations, not permissions to
turn every listed feature into a semantic-gap refusal.

| ID | Case, evidence and current status | Completion or review obligation |
|---|---|---|
| SC-P01 | `Driver.drive true` ends recorded completion with `SC_fault_checker_pending`; public race/consistency and program-level outcome interface unfinished | Connect prefix fault detection, SC consistency and explicit incomplete outcomes; retain faults before divergence and across rejected candidates. A refusal is not a completed checker. |
| SC-P02 | Exchange/operator lowering, qualifier preservation and aggregate CAS arguments are [validated](2026-09-22_sc-atomic-update-review.md); integer fetch, callable flags/fences, runtime orders, signal fences and non-synchronizing initialization now have a [validated interface slice](2026-09-22_sc-atomic-surface-review.md). Remaining public aliases, `kill_dependency`, query/configuration handling and final interface audit are outstanding | Finish available operation-specific semantics through actual C lowering and journal. `kill_dependency` must preserve evaluation and terminate dependency without strengthening consume; its absence is port work. SC-G06 identifies unresolved configuration, not permission to omit available query rules. Preserve single evaluation, arithmetic and failure prefixes. Legacy conditional `RMW` is not unconditional exchange. |
| SC-P03 | Scalar Cmm RF uses instantiated `MemValue` equality: identical-bit NaNs compare unequal; opposite signed zeros compare equal in the actual four predicate probes | Build a faithful logical-value/representation/provenance adapter. Do not restrict C NaNs or casually change generic memory equality. See [value audit](2026-09-21_sc-prototype-evidence/reference-followup/cmm-float-values-review.md). Predicate rejection alone is not a C fault. |
| SC-P04 | Effect inventory E03–E05/E10: allocation, deallocation, metadata zapping and address reuse; scalar SC checker excludes lifetime actions and its lifetime sketch is commented out | Preserve concrete lifetime transitions and derive composition from C/DR403. Keep dynamic deallocation/reuse distinct from automatic lifetime end; zapping is not an invented source store. No blanket dynamic-allocation refusal. A concrete unresolved case must get its own SC-G entry if found. |
| SC-P05 | E21: abstract varargs ids/cursors are preserved. Four [actual C traces](2026-09-21_sc-prototype-evidence/varargs/README.md) distinguish shared metadata from `va_copy` and join-ordered controls; the source audit finds available semantic guidance | Implement the per-id metadata location/conflict adapter alongside ordinary memory accesses. Pair counts in the selected traces are diagnostics, not SC verdicts. Preserve `va_arg` cursor updates, independent copies and deletion; no invented byte writes or blanket variadic-call refusal. |
| SC-P06 | Helper source order/resumption, child errno, SC fences and CAS were originally open mechanisms; current slices have implemented controls/laws | Retain completed evidence and finish correspondence/interface integration. Do not relabel these as upstream gaps; SC fence runtime coverage uses the reviewed fence-aware reference, not the narrower scalar checker alone. |
| SC-P07 | Resolved in the validated interface slice: Core text transport dropped libc source locations. Explicit expression/action/failure locations restore exact observations for both original flag failures; 322 parser checks and full integration pass | Retain the [before/after evidence](2026-09-21_sc-prototype-evidence/atomic-surface-location-transport/README.md) and regression controls. This was port work, not an upstream semantic gap; no locations were removed from comparison and no unrewritten metadata bodies substituted. The format does not claim lossless transport of every Core metadata field. |

## Other explicit boundaries and fault identities

| ID | Boundary | Required classification and action |
|---|---|---|
| SC-D01 | CAS representation-size disagreement; missing request/phase owner, wrong owner, outside-mode phase, missing unique read, uninitialized state, lost observer state or unowned memory effect/node | Existing typed protocol/representation diagnostics. They are invariant or adapter failures, not proof of ISO UB or a new semantic coverage exclusion. Preserve state; repair reachable defects. |
| SC-D02 | Memory observer or suspension unavailable in another object-model instance | Explicit `SC_fault_observer_unavailable` / `SC_fault_suspension_unavailable`; concrete default is the charter instance. Supporting another instance needs its effect implementation, never an empty journal. |
| SC-D03 | Executed memory order outside the named SC model | `SC_fault_order` with request kind. Preserve exact order; do not silently strengthen it. Separate invalid operation-specific orders from merely out-of-model orders when the final outcome interface is connected. |
| SC-D04 | E23 concrete memory intrinsic is already unsupported; other models have different implementations | Preserve model-specific failure. It is not an effect-free intrinsic or authority to disable another model's operation. |
| SC-D05 | Existing upstream frontend limitations, including bitfields; existing memcpy-overlap UB-check omission; floating unary-minus lowering described below | Preserve and disclose individual upstream behavior/limitations. The policy is not authority to silently change existing sequential semantics or ban every memcpy. Source checklist: [effect inventory](2026-09-21_sc-effect-inventory.md). |
| SC-D06 | Fuel/resource exhaustion, blocked execution, ordinary model errors and C UB | Preserve distinct payloads and states. Exhaustion does not establish safety; blocking is not normal value completion; implementation assertions/backtraces are not C semantics. |

The 21 constructors of `Sc_runtime.sc_fault` at the audited checkpoint are
accounted for by SC-G01, SC-P01 and SC-D01–D03. Their current coarse category
`SC_failure_representation` includes both SC-G01 and size disagreement; consumers
must use the typed identity, not assume that category means upstream ambiguity.
The planned SC-G02/03/06/07/08 outcomes need their own identities and contextual
evidence. SC-G04/05 use separate typed Core `Errors.Model_gap` identities.

**SC-D05 observation, atomic-update validation:** the floating unary-minus arm
in `Translation` lowers `-e` to `0.0 - e`; this arm is byte-identical to the
pinned pristine reference. The actual `exchange-double.c` journal consequently
shows positive zero supplied by the `-0.0` initializer. That case does not test
preservation of negative-zero bits. A separate expression producing negative
zero by underflow, and independent Core representation controls, exercise the
exchange path with the intended input. See the
[atomic-update review](2026-09-22_sc-atomic-update-review.md). This records a
pre-existing sequential lowering behavior; no new SC guard, arithmetic repair
or blanket floating-point refusal is claimed. Any repair must identify its
ISO/reference basis and undergo shared-model validation.

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
