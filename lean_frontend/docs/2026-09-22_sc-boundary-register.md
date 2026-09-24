# SC semantic boundaries and implementation obligations

Technical register from the now-frozen SC prototype. Start with the
[branch handoff](2026-09-24_sc-branch-inventory.md) for current producer status,
known holes and migration advice. This register retains individual G/P/D cases;
older status text and evidence counts describe dated checks, not completion of
the whole SC feature or the successor's work order.

## Fail-closed policy

[USER, 2026-09-21]:

> "This feels like a case where we should 'fail-closed' and match the Cerberus-upstream situation, until they have resolved this issue."

[USER, 2026-09-22]:

> "Agree, let's fail closed in general when we have such boundary cases, but make sure to document all such cases"

Retain pinned Cerberus/Cmm. Reaching an evidenced unresolved interpretation
produces a distinct unsupported/model-gap outcome, preserving completed effects,
failure-time state, independent faults and other alternatives. Do not invent
padding comparisons, mixed-size or library locking semantics. The C17/DR431
representation-comparison correction is settled; its unspecified-byte composition
with the pinned object model is the initial G01 boundary.

A gap is not C UB, false CAS, normal termination, an impossible transition or an
empty behavior set. Reasoning clients cannot discard those paths and infer
whole-program safety/support. A theorem may establish that a stated input avoids
a gap; its hypotheses must not become executable language restrictions. Preserve
the absence of a supported result, not incidental host assertions or backtraces
as C semantics. A rejected candidate must not erase independently known faults.

Register a stable case ID before treating a refusal as intentional coverage:
precise reached trigger, pinned source/ISO evidence, minimal reproducer and
non-refusal control, retained effects/state, client consequence, actual producer
status and resolution criterion. Revisit with a pinned upstream resolution.
Available-guidance port work, proof difficulty, protocol defects, host failures
and weak orders outside SC are distinct. None licenses blanket refusal of
structs, character accesses, dynamic allocation or library calls. The scalar
checker's smaller domain alone does not justify rejecting ordered byte accesses.

The register covers known cases, not all possible upstream omissions. Proposed
guards are not implemented guards. Original source audit: `3864dbb1f`; reference
base `5407597d9`, pristine `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`.
The selected reference and current development status are in the roadmap.

## Evidenced unresolved semantic boundaries

| ID | Boundary | Current enforcement | Required outcome |
|---|---|---|---|
| SC-G01 | CAS comparison depends on unspecified representation bytes | Implemented in the driver's `CompareExchangeObjectRequest2` arm: `SC_fault_unspecified_representation` | Explicit representation gap, preserving reads/state |
| SC-G02 | Concurrent representation accesses require unresolved location/RF composition | Temporary subobject/value port obligations active; precise G02 composition guard outstanding | Explicit location/composition gap; no race-free or UB verdict inferred from the inadequate projection |
| SC-G03 | Concurrent use of a runtime stream requires missing stream synchronization | Actual loader/call origins connected; temporary protection-attribution port obligation, precise stream guard outstanding | Explicit runtime-model gap; library implementation races must not become ISO caller UB |
| SC-G04 | Executed abstract unspecified atomic memory order | Typed Core producer implemented; paired controls, full Tier A+B and three-engine comparison pass | Preserve completed arguments and independent known-order UB; no chosen order or synthetic conditional UB |
| SC-G05 | Generic atomic pointer fetch add/sub in the contradictory C11/reference domain | Typed update-body producer implemented; paired controls, full Tier A+B and three-engine comparison pass | Preserve checked object read; no pointer arithmetic result or store invented |
| SC-G06 | Consuming lock-free properties without a pinned target configuration | Runtime query producer passes component controls, all 39 full lanes and the unchanged 864-case comparison; numeric `#if` still silently treats absent markers as zero | Explicit configuration gap where a property is required; no invented all-lock-free or never-lock-free policy |
| SC-G07 | Unsequenced C atomic evaluations encounter the pinned Cmm function-call assumption | Whole-scalar projected guard connected; broader composition and production acceptance outstanding | Explicit sequencing/composition gap; preserve independently justified faults and actual source order |
| SC-G08 | Concurrent library operations depend on omitted synchronization of shared internal state | Actual `at_quick_exit` and `atexit` registration traces retained; precise internal-object guard outstanding | Explicit runtime-model gap; omitted implementation protection is not caller UB |

### SC-G01 — unspecified bytes in compare-exchange

The C17 resolution of DR431 specifies representation comparison. The concrete
model can still supply unspecified bytes, for example padding. Comparing
`MemValue`s, choosing fresh padding or nondeterministically declaring equality
would fabricate a result not provided by the pinned composition. Sources and
WG14 links are in the primary-source follow-up;
reproductions are in the CAS decision record
and the atomic slice review.

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

The reference proposal
and mixed-size review
link the pinned source and published alternatives. The retained diagnostic
historical reference evidence
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

**Current behavior:** no complete SC-G02 composition guard exists yet. C2 now
classifies whole scalar/aggregate values and whole scalar array elements.
Corresponding signed/unsigned views, implementation integer aliases and the
registered enum-compatible types are normalized for RF. Remaining subobject,
partial aggregate and typed-view composition produces explicit port obligations, so those traces cannot certify
support. These temporary obligations must be narrowed by C3, not renamed as G02.
All accesses, lifetime vertices, bytes/provenance, state and earlier findings are
retained.

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
source review
and journal review.

`stdio-journal-3` in the historical reference captures executes actual libc:
parallel `fputc('A', stdout)` / `fputc('B', stdout)` records 271 effects and
31 unordered cross-thread overlapping access pairs; sequential calls record
220 effects and none. These selected runs demonstrate missing synchronization,
not exhaustive SC outcomes or caller UB. Buffered stdout is empty in these
captures; no flush result was inferred.

A later bounded diagnostic
retains zero-length paths (`sc-stream-draft/zero-length-1` and its review in the
historical component record). Both ordered and parallel `fread` pairs return zero and
preserve full prior observations after query erasure. Each records ten accesses
to the same FILE storage; the parallel pair has five source-unordered conflicting
pairs, the ordered pair none. Transfer length zero therefore does not by itself
justify skipping stream-access analysis. The pinned `fwrite` path also calls
`__fwritex` at length zero, but both its ordered/parallel instruments timed out
at 20 seconds (exit 124); no complete `fwrite` result is claimed. These are
source/selected-trace facts, not caller UB or a new lock semantics. The review
also records N1570 7.21.8.1p3/7.21.8.2p3's zero-length requirements alongside
7.21.2p7–8; an internal field update alone is not treated as a separate
observable-conformance verdict.

**Guard obligation:** identify executed stream operations and the stream object
whose required synchronization is missing. Inter-thread stream use that depends
on those missing lock effects requires SC-G03; ordinary buffer formatting
(`vsnprintf`), unrelated streams and source-ordered calls must have controls.
Detect the boundary before treating omitted library locking as a C data race.
Do not equate descriptors with streams or introduce a global hb edge.

**Current behavior:** no dedicated guard or complete stream-identity adapter.
FS service ownership protects resumable abstract FS transactions only. It does
not supply C stream synchronization. Precise public G03 classification remains
pending. The temporary library-attribution guard now exempts evidenced private
normal-call argument reads; this does not identify or protect a stream.
Retain actual memory/FS effects, output, state and independent established faults;
do not synthesize lock effects after the fact.

**Revisit:** pinned upstream stream-lock operational semantics plus a faithful
stream-identity/call adapter and concurrent/sequential/distinct-stream controls.

### SC-G04 — abstract unspecified atomic orders

The interface review gives the source,
standards and pristine reproductions.
The current producer is Translation.translate_atomic_explicit through
translate_atomic_order_cases: a reached LVunspecified order emits
Errors.Model_gap with Core.Model_gap_unspecified_atomic_order. This guard is
implemented with paired Core/C, prefix and simplifier-sensitivity controls.
The retained interface checkpoint
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
the interface review. The current
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
configuration/provider implementation. The pristine and fork probes
show ordinary uses failing and numeric `#if` silently consuming the missing
identifier as zero. That is not evidence that the type is never lock-free.
SC request indivisibility does not determine these implementation properties.
The follow-up review
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

**Current behavior:** the atomic completion slice
implements the runtime query's available argument rules and emits the typed
`Model_gap_atomic_lock_free_configuration`. Paired C controls retain completed
argument effects and prior faults; null pointers do not trigger object loads.
Both parsers and the internal constant evaluator transport the identity and
location. Component controls, all 39 full lanes and the unchanged 864-case
comparison pass. The ten constant definitions are unchanged and no complete
preprocessing guard is installed.
The silent preprocessing fallback is an open defect, not a supported configuration.
The earlier draft's unbuilt status is superseded only for the runtime path.

**Revisit:** a pinned target configuration and its operational query semantics,
or precise unsupported diagnostics for every consuming interface. Available
argument/constant-expression rules remain implementation obligations.

### SC-G07 — C atomic sequencing and the pinned Cmm assumption

The sequencing review
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
deliberately avoids that case. The subsequent
native follow-up
retains eight actual C controls and six separate predicate controls. Mixed
ordinary/atomic unordered pairs also encounter the assumption. Same-atomic,
same-ordinary and macro update/read controls retain UB035 and their completed
effects; comma and function-wrapper controls retain their real ordering.
These do not yet validate a paired production composition guard.
Scheduler order must not become an invented source edge, UB or empty behavior.

**Current behavior:** the public candidate classifier now identifies the pinned
indeterminate-sequencing assumption's unordered action pairs on its whole-scalar
projection and returns a distinct `SC_fault_atomic_sequencing` (G07) refusal.
The prefix accumulator retains witness IDs in the authoritative journal; it no
longer copies the source graph at every discovery. Earlier independent findings
and operational failures remain retained. Complete C location/action composition
and the production acceptance cases remain open; selected C traces and component
controls do not establish complete coverage.

**Revisit:** a pinned resolution of both assumptions in the C operational
composition, with implicit/macro/function and independent-fault controls.

### SC-G08 — synchronization of shared library internals

The runtime review
retains an actual parallel `at_quick_exit` registration trace: 141 effects,
five unordered cross-thread overlapping access pairs on internal `count`
(allocation 59, `stdlib.c:217–218`), return zero and empty output. Source-ordered
registrations have 137 effects and no such pair. Neither calls `quick_exit`.
N1570 7.1.4p5 requires protection of shared library internals; 7.22.4.3's
qualification about racing termination does not excuse two registrations.

**September 23 extension:** two selected native `atexit` controls also reach the
actual bound internal `head` allocation (`stdlib.c:149–199`, via `__cxa_atexit`).
The parallel control completes with 158 effects and three unordered cross-thread
overlap pairs; the ordered control completes with 156 effects and no such pair.
Both return `Specified(0)` with empty output. These are source-order diagnostics,
not full HB, paired Lean or exhaustive SC classifications. The
component record and retained captures
keep the actual object binding and complete journals. N1570 7.22.4.2p2's
qualification about a call to `exit` is not a general exception for concurrent
registrations. The existing guard remains outstanding; no blanket refusal of
library calls follows.

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
| SC-P01 | `Driver.drive true` now classifies otherwise completing scalar candidates; both CLIs select SC, prefix findings are retained, and port/protocol/G07/consistency outcomes are distinct. Full C2 acceptance and the whole-C provider interface remain unfinished | Connect prefix fault detection, SC consistency and explicit incomplete outcomes; retain faults before divergence and across rejected candidates. A refusal is not a completed checker. |
| SC-P02 | Exchange/operator lowering, qualifier preservation and aggregate CAS arguments are validated; integer fetch, callable flags/fences, runtime orders, signal fences and non-synchronizing initialization now have a validated interface slice. Public character aliases, `kill_dependency` and the runtime query producer now have passing component controls, with all 39 full lanes and the unchanged 864-case comparison passing; preprocessing configuration and the final interface audit remain outstanding | Finish available operation-specific semantics through actual C lowering and journal. `kill_dependency` must preserve evaluation and terminate dependency without strengthening consume; its absence is port work. SC-G06 identifies unresolved configuration, not permission to omit available query rules. Preserve single evaluation, arithmetic and failure prefixes. Legacy conditional `RMW` is not unconditional exchange. |
| SC-P03 | The legacy raw-`MemValue` Cmm instance conflates signed zeros and rejects identical-bit NaNs. C2 now uses the lossless key/interner/reference carrier for actual scalar RF and reports typed-view disagreement as a port obligation; complete value/representation composition remains pending | Finish the logical-value/representation/provenance adapter. Raw keys preserve typed views; their equality is not automatically cross-view RF equality. Do not restrict C NaNs or change generic memory equality. See value audit. Predicate rejection alone is not a C fault. |
| SC-P04 | Effect inventory E03–E05/E10: allocation, deallocation, lifetime metadata and address reuse; native pointer zapping is behind a switch disabled in the matched profile; scalar SC checker excludes lifetime actions and its lifetime sketch is commented out | Preserve concrete lifetime transitions and derive composition from C/DR403. Keep dynamic deallocation/reuse distinct from automatic lifetime end; zapping is not an invented source store. No blanket dynamic-allocation refusal. A concrete unresolved case must get its own SC-G entry if found. |
| SC-P05 | E21: production classification now uses actual reference-derived full HB for interthread cursor conflicts and source SB for same-thread conflicts. Witness IDs enter the existing retained prefix findings. Candidate controls cover publication, cursor identity, read/read, conflicts and retention; both public SC engines return 42 on a selected actual C `va_copy` execution | Preserve `va_arg` cursor updates, independent copies and deletion; no invented byte writes or blanket variadic-call refusal. Incomplete object/runtime interpretation still prevents an unsupported trace from certifying safety or a missing-HB race. Broader C/runtime composition remains subject to C3 coverage. |
| SC-P06 | Helper source order/resumption, child errno, SC fences and CAS were originally open mechanisms; current slices have implemented controls/laws | Retain completed evidence and finish correspondence/interface integration. Do not relabel these as upstream gaps; SC fence runtime coverage uses the reviewed fence-aware reference, not the narrower scalar checker alone. |
| SC-P07 | Resolved in the validated interface slice: Core text transport dropped libc source locations. Explicit expression/action/failure locations restore exact observations for both original flag failures; 322 parser checks and full integration pass | Retain the before/after evidence and regression controls. This was port work, not an upstream semantic gap; no locations were removed from comparison and no unrewritten metadata bodies substituted. The format does not claim lossless transport of every Core metadata field. |
| SC-P08 | Spawned Epar branches discarded their enclosing procedure identity, preventing direct child loop-label resolution | Shared production repair inherits the lexical owner with an empty child stack. Eleven paired constructor controls, ten kernel laws (including the actual reducer connection), four paired C loop controls, six unchanged C/RMW observations and a lost-owner mutation support the repair. All 39 full lanes and the unchanged 864-case report pass; see the work record. This is repaired structured-thread port work, not a loop exclusion or C UB. Original pristine failures remain in the filesystem evidence. |

## Other explicit boundaries and fault identities

| ID | Boundary | Required classification and action |
|---|---|---|
| SC-D01 | CAS representation-size disagreement; missing request/phase owner, wrong owner, outside-mode phase, missing unique read, uninitialized state, lost observer state or unowned memory effect/node | Existing typed protocol/representation diagnostics. They are invariant or adapter failures, not proof of ISO UB or a new semantic coverage exclusion. Preserve state; repair reachable defects. |
| SC-D02 | Memory observer or suspension unavailable in another object-model instance | Explicit `SC_fault_observer_unavailable` / `SC_fault_suspension_unavailable`; concrete default is the charter instance. Supporting another instance needs its effect implementation, never an empty journal. |
| SC-D03 | Executed memory order outside the named SC model | `SC_fault_order` with request kind. Preserve exact order; do not silently strengthen it. Separate invalid operation-specific orders from merely out-of-model orders when the final outcome interface is connected. |
| SC-D04 | E23 concrete memory intrinsic is already unsupported; other models have different implementations | Preserve model-specific failure. It is not an effect-free intrinsic or authority to disable another model's operation. |
| SC-D05 | Existing upstream frontend limitations, including bitfields; existing memcpy-overlap UB-check omission; floating unary-minus and atomic initializer lowering described below | Preserve and disclose individual upstream behavior/limitations. The policy is not authority to silently change existing sequential semantics or ban every memcpy. Source checklist: [effect inventory](2026-09-21_sc-effect-inventory.md). |
| SC-D06 | Fuel/resource exhaustion, blocked execution, ordinary model errors and C UB | Preserve distinct payloads and states. Exhaustion does not establish safety; blocking is not normal value completion; implementation assertions/backtraces are not C semantics. |
| SC-D07 | Inherited Lean filesystem-model coverage, including `lseek`/`close` on standard descriptors 0–2 | The checked port now repairs standard descriptors, open, close, I/O, seeking and selected closed-file path operations. Remaining operations and open-inode retention fail explicitly as missing coverage. Available SibylFS guidance remains required port work, distinct from ISO/Cmm interpretation or SC-G03 stream locks. The repair record gives the precise tested domain. All 39 integration commands pass after the explicit one-row baseline update. The 864-case report retains the reviewed change from a Lean crash to its typed directory coverage error. The operation inventory lists every currently identified filesystem case. |
| SC-D08 | Overlapping Lean/OCaml target declarations for Cmm action, pre-execution and witness equality | Confirmed port defect: two equality discrepancies and one Lean comparison refusal in four paired probes. Repair the selectors to choose the existing OCaml executable definitions; retain predicate bodies. This is required port work, not an unresolved ISO choice or an allowed exclusion. Eight paired repair controls, six instance-selection laws, all 39 integration commands and the unchanged 864-case three-engine comparison pass. |
| SC-D09 | SibylFS `run_umask` decodes `RV_file_perm` with `return_nat`, after the mask update and OS return | Confirmed upstream wrapper failure, not errno or C UB. The validated production checked path replaces the guessed normal return with the updated-state receipt and a typed return-decoder fault. Preserve this refusal until the upstream wrapper contract is resolved; no rollback or successful mask return is authorized by the current policy. |
| SC-D10 | A filesystem write reaches `List_array.list_array_write` with more bytes requested than supplied | Preserve that precise source-level failure, its phase and last defined state. Descriptor rights and negative-offset errors can prevent reaching it; do not refuse early from the argument lengths alone. The checked production path and 528 paired I/O controls retain it distinctly from errno and host failures; actual Driver controls now retain the fault receipt and prefix. |
| SC-D11 | Inherited `Ord CerbFS.FsState` returns `.eq` for every pair | Confirmed API defect: distinct states are silently identified by ordering. The generated Driver comparison requires an instance, so removal failed to compile. The repaired body is a named opaque unsupported-comparison failure; no replacement order is fabricated. Structural representation equality and field inspection remain. The production instance-selection law, runtime refusal control and full integration pass. |
| SC-D12 | Ordinary C `umask(mode_t)` proxy loads a signed int from a 16-bit parameter slot | Pinned header/proxy mismatch: the reached load faults before `FS_UMASK`, on pristine and both fork targets. Preserve that preceding memory fault; do not reinterpret it as the later SC-D09 decoder boundary or bypass it with a guessed C return. |
| SC-D13 | Historical cross-target trace mismatch caused by unmatched selection in the diagnostic instrument | Resolved for the four retained controls: native Random.int was compared with Lean first-selection despite the native filename. Matched first selection on the identical C paths gives exact agreement of the documented effect-metadata projection. Rendered location/type/value are outside that projection; no full-journal or general trace-equivalence claim follows. Original captures and the failed comparison are retained. Public SC checking remains pending under SC-P01. |
| SC-D14 | Existing Z2-F-04 directory-stream C proxy failure | Native `opendir(".")` reaches an internal `store(signed int*)` mismatch with `Specified(1)`. Lean now stops earlier with SC-D07's typed missing-directory-stream coverage result. Keep the full distinct observations; neither is C UB or completed support. Port the available directory semantics and separately review the actual Core/proxy failure before changing its outcome. See the baseline review. |
| SC-D15 | The concrete atomic-allocation check reports UB042 for selected byte accesses to an atomic scalar | Two load/store controls have identical complete decoded UB042 observations on pinned pristine, fork OCaml and Lean. The byte-identical native check applies to atomic allocations generally; the cited ISO member clause addresses atomic structures/unions. Preserve the actual earlier refusal and prefix without asserting that it proves ISO UB or substituting later RF diagnostics. See the scope review; resolution requires review of the concrete check and atomic representation semantics. |
| SC-D16 | Raw binding/journal metadata differs across the native libc object loader and Lean's Core-text/metadata loader | Existing frontend symbol and function-pointer-byte differences remain explicit. New receipts also expose driver-step differences; a loaded-value/constructor example has identical same-Core paired behavior but loses the distinction through the actual printer/parser. Preserve all raw data and per-engine bindings; no step-level correspondence or runtime refusal follows from matching C outcomes. See the comparison and transport review. This is transport/correspondence work, not an ISO semantic gap. |

The 21 constructors of `Sc_runtime.sc_fault` at the audited checkpoint are
accounted for by SC-G01, SC-P01 and SC-D01–D03. Their current coarse category
`SC_failure_representation` includes both SC-G01 and size disagreement; consumers
must use the typed identity, not assume that category means upstream ambiguity.
The planned SC-G02/03/07/08 outcomes need their own identities and contextual
evidence. SC-G04/05 and the runtime SC-G06 producer use separate typed Core
`Errors.Model_gap` identities; SC-G06 preprocessing remains unguarded.

**SC-D05 observation, atomic-update validation:** the floating unary-minus arm
in `Translation` lowers `-e` to `0.0 - e`; this arm is byte-identical to the
pinned pristine reference. The actual `exchange-double.c` journal consequently
shows positive zero supplied by the `-0.0` initializer. That case does not test
preservation of negative-zero bits. A separate expression producing negative
zero by underflow, and independent Core representation controls, exercise the
exchange path with the intended input. See the
atomic-update review. This records a
pre-existing sequential lowering behavior; no new SC guard, arithmetic repair
or blanket floating-point refusal is claimed. Any repair must identify its
ISO/reference basis and undergo shared-model validation.

**SC-D05 observation, atomic completion:** the unchanged declaration lowering
misses conversions for `_Atomic(int*) x=0`, `_Atomic(unsigned char) x=257`
and `_Atomic(int) x=3.9`. Pristine and fork ordinary drivers fail in all three;
four conversion controls complete identically. The SC query control preserves
the prior pointer-initializer type error and prefix rather than replacing it
with a configuration gap. The [local upstream draft](upstream-tray/45-atomic-declaration-initializer-conversions.md)
records the exact source basis and prospective repair. No repair is adopted.
Two query static-assert controls, including a short-circuited call, are rejected
by the existing syntactic integer-constant-expression classifier before the
internal evaluator is reached. Separate compiled Ail controls exercise that
evaluator's typed-gap transport; they do not establish C acceptance. These
individual existing limitations do not justify blanket atomic or constant-
expression refusals.

The subsequent source-graph slice adds
`sc_graph_issue` diagnostics for duplicate/missing occurrence IDs, erroneous
thread annotations and cycles. The passive call-scope tracker likewise retains
missing-thread, unknown-depth and legacy-transition diagnostics rather than
guessing a caller. These are also SC-D01 protocol findings. The
query retains malformed data and diagnostics; its lack of diagnostics is not
a complete Cmm well-formedness, consistency or SC support verdict.

**SC-D07 historical observation, prefix integration before repair:** actual parallel `ftell(stdout)`
calls reach `CerbFS.fs_lseek` on descriptor 1. The unchanged pre-slice and new
Lean instruments both stop at the existing opaque refusal, while the native
recorder completes. SibylFS starts descriptors 0–2 on a root-directory dummy
file (`fs_spec.lem:5690–5696`); the Lean model lacks that object. Its refusal
prevents an invented EBADF result. This diagnostic currently escapes the
ordinary ND result and yields no final Lean journal; do not claim failure-state
or scope-capture validation for this path. The
work record records the exact
comparison and limits. Resolve this case by porting the corresponding SibylFS
state/operation and preserving failure transport, with standard-descriptor,
ordinary-file and unknown-descriptor controls. Do not broadly refuse stdio or
classify the missing implementation as caller UB.

**SC-D07 follow-up:** 32 paired leaf cases confirm wrong descriptor reuse,
missing access checks, open/path/permission fail-open cases and incorrect
combined-error selection. Each trigger, reference result, current status and
removal task is in the filesystem boundary review.
The isolated descriptor repair passes 24 cases and twelve draft laws; it is not
production coverage. The 30-case native open matrix also prevents an invented
double-slash refusal or unconditional flag-first policy.

The ongoing repair adopts the
checked transitions and connects all25 filesystem entries to Driver. Ordinary
errno, upstream special kind/phase, missing port coverage and protocol failure
remain distinct. Thirteen production laws,16 Lean and14 native Driver controls,
and the paired leaf matrices pass. The earlier opaque-abort case that loses a
preceding diagnostic is retained as a historical failure. Smaller actual C
recordings validate fault/output transport; the larger parallel ftell recording
is still incomplete at its resource bound. Full 39-command integration and the
mandatory 864-case report pass with exactly the reviewed directory-boundary change.
Upstream `OS_special` supplies no successor state: retain the last defined OS
state and failure phase, and never invent a post-failure state. This is an
explicit limit of that upstream result, not permission to erase prior effects.

**SC-D08 validation:** the equality-target correction now passes all 39
integration commands and the unchanged 864-case three-engine comparison. Eight
paired equality controls and six actual production instance-selection laws
cover the repair. This fixes the selector overlap; it does not claim arbitrary
structural comparison of functions. Full component record.

**SC-D09 trigger and evidence:** every reached `run_umask` call that completes
its OS transitions supplies `RV_file_perm` to the numeric return decoder. In
the pinned, unchanged `sibylfs/src/sibylfs.lem`, `run_umask` calls `run` with
`return_nat`; the latter accepts only `RV_none` and `RV_num`. The actual
`os_umask` in `sibylfs/src/fs_spec.lem` updates the process mask and sets a
pending `RV_file_perm` result. The wrapper subsequently completes `OS_RETURN`
before failing with `return_nat`. Six native reproductions, including negative
and extra-bit masks, retain the preceding successful file creation, the exact
raw return and the post-return OS state. Six paired draft controls match those
fault/prefix/state projections. Repair record.
This is not an `OS_special`, and the state differs from the operation input.

**SC-D09 resolution criterion:** a pinned upstream resolution of the wrapper's
permission-valued result and a reviewed port of that contract, with updated-
state and return-value controls. Until then, expose the decoder refusal and its
last defined state. Driver integration now has exact entry/receipt laws and
paired prefix/state controls. Ordinary whole-C umask reaches SC-D12 first, so
those controls do not establish whole-C reachability of this decoder. OCaml integer conversion overflow is
separate: Lem's logical 32-bit conversion remains modular under the existing
LemLib D4 ruling, without an invented host-range restriction.

**SC-D10 evidence and removal task:** `sibylfs/src/list_array.lem` explicitly
fails with `t.ml/write: offset + length greater than length of string` when
the requested source slice is too short. The checked native adapter recognizes
only that exact failure from the actual transition, preserving its TAU phase;
it does not catch arbitrary `Failure`, allocation failure or numeric conversion
exceptions as model gaps. The 58 native interface controls include the reached
failure after file creation and a negative-offset pwrite that instead returns
EINVAL. The 528 paired I/O controls cover rights, offsets, append, zero counts
and signed counts, with exact result/fault, content and offset observations.
This is an internal filesystem-request boundary; it does not establish ISO C
UB or permit dropping preceding memory faults. The checked Driver connection
and paired failure-state witnesses pass together with full integration. Revisit the result only if the
pinned upstream leaf changes; this case has available source semantics.

**SC-G03/G08 adapter findings:** actual linking can replace a body at a colliding
symbol, and the Core stdlib source is separate from the C-library input's origin.
A function can overwrite a FILE parameter before its first read. The retained
linker
and parameter
evidence documents these adapter obligations and the current draft limits.
Neither names nor a first parameter read establish a stream identity or lock.
These are implementation obligations, not newly unsupported C constructs.

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


## September 23 integration findings

The atomic-interface checkpoint
validates the runtime G06 producer; numeric preprocessing remains unguarded.
No G02/G03/G07/G08 producer is claimed by that checkpoint.

- **SC-P04 / SC-P03:** paired actual memory-body controls preserve stored pointer
  representations across target lifetime end in the current profile while
  marking/removing the target allocation. `SW_zap_dead_pointers` is disabled;
  its native alternative is not a default SC effect or a newly authorized
  switch port. Actual memcpy preserves pointer value/bits/provenance while
  losing byte-copy indices. Thus lossless byte-key equality alone is not RF
  value equality. Evidence and corrected expectation.
- **SC-G07 / SC-P01:** the actual service observer finds the unresolved sequencing
  witness before a later UB035 transition. Immediate refusal there would hide
  an independent Core fault. Keep interpretation obligations alongside actual
  continuations and faults, forbidding a supported certificate while unresolved.
  Missing-result primitives still stop their actual path. Timing evidence.
- **SC-G03 / SC-G08:** artifact-bound definitions, actual call boundaries and
  existing parameter reads now have isolated diagnostics and shared-query laws.
  They distinguish slots from FILE values, repeated calls, recursion and
  same-name source decoys. They remain drafts; full HB/resource-scope and fault
  causality are required before a guard. Scope evidence.
- **SC-P01:** global initialization also runs the internal machine to
  `SC_halted`/`prepare_exit`. Those events alone are not whole-C-program
  completion. The public interface must preserve the actual outer
  initialization/main/finalization protocol. This is available-guidance port
  work, not an upstream ambiguity or a new runtime exclusion.

**SC-D11 scope and removal task:** the inherited `Ord FsState` body was
`compare _ _ := .eq`. Different file contents or masks were therefore collapsed
by this comparison API. The production instance-selection law selects the named opaque
failure, and a runtime comparison exits134 with that exact unsupported message.
Positive field inspection and structural equality controls still complete. A future order requires a reviewed correspondence with the native
full filesystem state (including its environment); sorting the reduced record
would not establish it. This is missing comparison port coverage, not an ISO
concurrency decision. The existing `<fs_state>` display is also incomplete;
state receipts must be inspected through their fields, never identified by that
placeholder. Generated record comparison needs the instance even where the
execution path has no identified whole-filesystem ordering call.

**SC-D12 evidence and resolution:** `runtime/libc/include/posix/sys/types.h`
defines `mode_t` as `uint16_t`, while `runtime/libcore/std.core`'s ordinary
`umask_proxy` loads `signed int` from that parameter pointer. The actual C
control in `c-pipeline-2` stops with `UB_CERB002a_out_of_bound_load` in all three
engines before reaching the filesystem wrapper. This is an observed model
fault caused by the proxy mismatch, not a new ISO UB classification for calling
`umask`. The separate `std_inner_arg_temps.core` proxy takes a value; this control
does not establish its whole-C behavior. Resolve the pinned proxy/header
contract before claiming ordinary C reachability of the SC-D09 decoder test.
Driver-level `FS_UMASK` controls still witness that downstream decoder boundary.

**SC-D13 instrument resolution:** the original four controls compare different
selection policies. The native file named `first_smt2.ml` still calls Random.int;
Lean selects the first alternative. `selection-review-2` replaces exactly that
native choice and reruns the identical original C paths. All four effect-metadata
projections then match. Full native-to-native captures identify 4, 7 and 3 cleanup
storage/range differences and 28 parallel entries attributable to that selection.
No executable semantics, journal field or observation baseline is normalized.

The historical `raw_journal_equal` field compares a projection which omits
rendered location/type/value. The corrected review names that limit explicitly;
occurrence/request/thread/scope identities, annotations, ranges, bytes,
provenance and copy offsets remain compared. The earlier failed review and all
raw captures are retained. These finite controls resolve the reported instrument
mismatch, not general trace correspondence. The two larger C-libc recordings
still time out at their original 20 second bound.

The filesystem inventory gives
the seven selected open specials, all fourteen unported operations, open-inode
and non-root-cwd gaps, unsupported state ordering, and protocol-fault classes.
Available-guidance gaps remain required port work. The public SC entry still
fails closed immediately with checker-pending; no completed SC mode is claimed.

## Retained inputs and preprocessing constraints

[Minimal regression inputs](../../tests/sc/boundaries/README.md) retain G01–G08
and the distinct C/Core D cases. Direct D09/D10 filesystem controls remain in
the paired suites; D14 remains in the immaculate corpus. Historical captures
and source excerpts are recoverable from Git at `03f7c5f32`; repeated archives
are intentionally absent. Current filesystem coverage is maintained in the
[effect inventory](2026-09-21_sc-effect-inventory.md#filesystem-coverage-and-reached-failures).

For G06, [DR458](https://www9.open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0458.html)
requires preprocessing usability; [DR465](https://www9.open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0465.html)
clarifies type-consistent queries and null arguments. A GCC `-Wundef` detector
can be suppressed by source pragmas. `-dU` does not report undefined identifiers
consumed numerically in `#if`. A division-by-zero marker changes stringification.
None is a complete replacement for a precise preprocessing observer. Header
inclusion and stringification alone require no numeric configuration. The
matching GCC plugin SDK experiment remains unavailable as recorded in the roadmap.
The pinned struct representation of atomic_flag does not settle the generic
query's atomic-type domain; later C23 discussion is not a new reference ruling.
