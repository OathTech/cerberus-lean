# SC prototype: operational contract and reference obligations

Technical specification supporting the [SC execution roadmap](2026-09-21_charter-sc-prototype.md).
The roadmap owns current work, checkpoints and validation cadence. This file
owns semantic construction and reference obligations; it does not assert that
the public SC path is complete.

## Reference identity and scope

Core, the object-model interface and Cmm definitions are taken from the current
implementation base `5407597d9eeba0259d65b728e86a860ad4614ab3`, compared with
pristine upstream `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`. Final integration
uses the retained `Cmm_csem.sc_fenced_memory_model` and `sc_fenced_condition`, together with the
executor's explicit NA/seq_cst request domain. This is the pinned fence-aware
reference already reviewed for SC fences, not a new modern C++/RC11 model.
The stronger `SC_memory_model`/`SC_condition` remains reference material for
theorems that establish its hypotheses. Neither historical `behaviour` wrappers
nor `statically_satisfied` supply a theorem of today's Core adapter.

[AGENT, September 23] Actual C declaration followed by `atomic_init` records
both the declaration's unspecified NA store and explicit initialization. The
narrower condition rejects multiple NA initialization stores, while the
fence-aware condition admits this ordinary C pattern. Retain both actual
stores and their orders. The follow-up
records four controls, their consistency leaves and independent race witnesses;
it is not a universal equivalence proof. The fence-aware predicate's broader
order domain does not authorize the executor to strengthen or admit weak orders.

Both scalar checkers exclude allocation/deallocation actions. That reference
domain remains smaller than the runtime target; lifetime, metadata and ordered
representation operations require the operational composition described below.
Passing a scalar projection alone is not a public SC verdict.

ISO references are C11 N1570 3.14, 5.1.2.3–4, 6.5, 7.17 and 7.22.3, with relevant
WG14 corrections (including DR401/402/403). Do not import later C++ rules without a
recorded C/upstream rationale. The historical operational integration uses
symbolic reads and a commitment order independently of Core stepping. A concrete
SC interleaving executor is a development instance, not a restored full weak
executor. [Nienhuis et al.](https://www.cl.cam.ac.uk/~pes20/rems/papers/nienhuis-oopsla-2016.pdf)
and [Memarian's thesis, chapter 10](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-981.pdf)
describe that distinction. The latter confirms that the old integration ceased
to run as Cerberus evolved. BMC is a separately implemented bounded reference
where its actual operations are supported, not a full object-model oracle.

## Scalar construction and coverage claim

C2 must implement and explain the following connection on its justified scalar,
NA/seq_cst domain; it is not an already established theorem of the recorder.
An actual read supplies its RF source only after the adapter establishes the
logical location/value interpretation. Writes and RMWs to each atomic object
supply MO in execution order, including initialization as required by the
reference. The selected seq_cst atomic/fence occurrences supply SC order; internal
RMW phases are grouped as one action. Source `sb` and derived synchronization
remain separate from scheduling order.

For supported race-free executions the resulting candidate must meet the pinned
fenced predicates. Conversely, exhaustive concrete execution must retain the
choices needed for the permitted behaviors of this interpreted domain: all
offered thread/service, Core and ND alternatives, not just one successful trace.
Candidate membership alone proves neither that coverage nor recording fidelity.
State the exact interpretation assumptions and bounds when making either claim.

Reuse complete bounded scalar outcome-set comparisons and inspect representative
RF/MO/SC interpretations. The finite scalar enumerator does not cover fences;
fences and repeated initialization require direct controls against the selected
pinned predicates. This is a focused implementation/validation obligation, not
a new universal adequacy theorem or second reference framework. Racy prefixes
have independent fault handling; lifetime, representation and metadata require
the additional composition below. No scalar test restriction narrows C3 scope.

## Machine and choices

1. Reuse the current Core state, thread states/continuations, filesystem state,
   memory model, symbol/event supplies and explicit fuel/address-space inputs.
   Add concurrency information around these definitions, not a second evaluator
   or a replacement value store.
2. SC memory requests stop Core advancement and enter the machine scheduler.
   Exhaustive execution preserves each distinct enabled thread/request choice
   and Core nondeterministic alternative. Do not infer source sequencing from
   the scheduler's selected order. Even one live thread may have multiple
   permitted evaluation alternatives.
3. Pure local reductions may be grouped only where doing so preserves the
   relevant behavior, faults and alternatives. Resource exhaustion remains an
   explicit outcome; equal numeric fuel between different drivers is not an
   assumed contract. The legacy identical-blocked-step collapse needs its own
   justification before adoption because trace multiplicity is observable in
   some existing interfaces even when outcome sets coincide.
4. Structured `Epar` allocates fresh thread identities, retains child-local
   environments/stacks, and places the parent at its actual waits. A child
   completion substitutes that child's value and makes the corresponding parent
   continuation eligible; nested spawn/join is handled by the existing structure.
   Spawn/join ordering follows source annotations and their continuation scope,
   not all earlier actions in whichever thread happened to run.
5. Global/argument/runtime initialization is attributed to the initial thread
   and precedes the appropriate main/child actions. Do not leave initialized
   stores out of the graph or manufacture `sb` among unsequenced initializers.
   Child errno is an explicit integration task: the current Core constructor
   sets it to null with an allocation TODO, rather than creating a usable object.
6. The ordinary sequential entry remains available with its current behavior.
   Fresh baseline probes show that both fork engines and pristine upstream
   produce only `Specified(1)` for the SB seed in default mode. Turning that
   entry into a spawn refusal would be a semantic change, not conservativity.
   The SC entry must instead explore the intended SC choices explicitly.

## Helper scheduling policy

Passive memory observation and SC scheduling are distinct. Observation records
the existing operations without creating pauses. The current SC construction
explicitly enables suspension for `Step_memop_request2` and `Step_fs2` in
`Driver.sc_step_may_suspend`; ordinary sequential mode keeps it disabled.

- The first helper primitive runs immediately. After a completed observed effect,
  `beforePrimitive` can suspend before the next primitive. Its continuation
  executes the original body against the current memory at resumption; do not
  cache its validity checks or result across another thread's step.
- `sc_capture_service` saves the request, accumulated effects and continuation,
  then returns to scheduling. A paused thread resumes that service rather than
  re-evaluating its Core arena. Ordinary ND guards/branches/choices remain offered.
  Primitive failures keep their actual state and already completed effects.
- Ordinary action requests are not enabled for these internal pauses. In
  particular, an atomic-update/CAS object phase remains indivisible; expected-
  object evaluation/writeback and ordinary SeqRMW use their separate explicit
  phases and source rules. A recorded byte is not automatically a yield point.
- A filesystem service retains `sc_filesystem_owner` while suspended, excluding
  competing FS services but permitting other Core/memory work. This preserves
  the existing abstract FS transaction: `drive_fs_step_with` captures FS state,
  performs memory work, then commits its FS result. Dropping ownership can lose
  an intervening FS update. Ownership is neither an ISO stream lock nor a claim
  about a real syscall's granularity; G03/G08 remain separate.

Source basis: `driver.lem`'s `sc_memory_mode`, `sc_capture_service`,
`sc_machine_choices` and `sc_start_machine_choice`; paired
`CerbMem.beforePrimitive` / concrete `Impl_mem.before_primitive`; and the existing
checked primitive order in memcpy/memcmp/realloc and filesystem helpers. These
establish the construction and state-retention rationale, not by themselves a
universal concurrent correspondence. C2 must retain the short source/reference
argument for permitted grouping and a distinguishing helper-interleaving and
partial-failure control when C1 deletes historical service records. Do not
silently revert suspension or infer its justification from sequential erasure.

## Memory and ordering

The [effect inventory](2026-09-21_sc-effect-inventory.md) is the source-path
checklist. At each memory transition preserve pointer validity, bounds,
byte/provenance values, metadata, and failure-time state. Reads, unchanged-value
writes, optional initialization and completed helper prefixes all need
observation at their actual source. Effects inside a memop do not automatically
become scheduling points. Changing request grouping requires a concurrent
argument, separately from sequential erasure.

Keep event identities fresh and source annotations explicit on requests and
continuations. In particular, repair continuation-scoped ordering rather than
porting the donor's whole-arena `SeqRMW`/unsequenced-sibling tagging. Ordinary
`SeqRMW` has ordinary C effects and exclusions; an indivisible implementation
request does not turn it into an atomic Cmm RMW.

Separate actual representation ranges, allocation identities, scalar C memory
locations and atomic-object identities. A typed read can combine bytes from
different writes. `Mem.overlapping` is a conflict helper with a read/read
exception; numeric overlap by itself is not a definition of every C memory
location. The scalar Cmm `rf` needs a matching whole-value writer; it cannot be
applied universally to representation operations. The overlap adapter has
unimplemented footprint/value operations, and its race predicate still uses
equal locations. Those facts are reference limitations, not implemented runtime
guards. The user's 2026-09-22 [general policy](2026-09-22_sc-boundary-register.md#fail-closed-policy)
requires explicit unsupported outcomes when an evidenced unresolved composition
is needed, retaining the pinned reference. The
[boundary register](2026-09-22_sc-boundary-register.md) distinguishes those cases
from adapter work and tracks guard implementation. It does not authorize
refusing every representation operation outside the scalar checker domain.

Dynamic deallocation and subsequent reuse follow the allocation order and
synchronization described by [WG14 DR403](https://www.open-std.org/jtc1/sc22/wg14/www/docs/dr_403.htm),
not the uncorrected wording that connects a deallocation to any allocation of
the region. Automatic-object lifetime end is a distinct event. The concrete
observer design therefore retains the original `is_dynamic` flag and known range;
recording an address without the operation kind would lose information needed
by the adapter. The commented lifetime-model sketch in
`frontend/concurrency/cmm_csem.lem:3065–3106` is not an executable SC reference.

SC atomic operations must use their specified memory orders. Do not strengthen
an executed weak operation to SC. Validate operation-specific orders, including
CAS failure restrictions. Preserve weak-CAS spurious failure, expected-value
updates and object RMW indivisibility. Effects from argument evaluation retain
their ordinary source sequencing. Frontend omissions (exchange, signal-fence
paths, etc.) need individual reproductions and classifications rather than
Core-only tests presented as C support.

## Faults and observations

Maintain the distinction between a recorded concrete schedule, a consistent
Cmm candidate and whole-program behavior. A concrete NA read in a racy schedule
can read a value lacking an hb-visible writer; discarding that schedule for
failing `consistent_non_atomic_rf` could discard the race. Conversely, accepting
a recorder's graph does not show that all Core effects were recorded. Fault
existence and graph membership need separate checks and correspondence claims.

Per-execution outcomes distinguish completion, UB, model failure, blocking,
unsupported model operations, and incomplete exploration/resource failure.
Preserve stdout/stderr bytes, value, blocked state and error/UB payloads in
differentials. One safe execution does not erase another execution's fault.
An exhausted search never establishes definedness. Faults before divergence
must remain reportable without waiting for every thread to terminate.

The current scalar seed enumerator produces per-schedule values plus race
tokens; this does not implement Cmm's whole-program `behaviour` quantification.
The production interface and documentation must state both levels explicitly.
Finite test exploration is not a language bound or an infinite-run theorem.

## Operational interface and completion claims

Expose the actual machine/local states, transitions and outcomes with explicit
parameters. A Lean relation should be defined from execution or connected by
kernel-checked coverage/equivalence laws, not independently restated. Supply
useful step equations and continuation/observation laws. No Iris dependency or
customer edit is required.

Track four different domains: runtime implementation, reference checker,
theorem hypotheses, and experiment bounds. Single-thread/effect-erasure results
must state their actual domains and resource relation; the donor's failed
universal scalar graph theorem is not a foundation. No new runtime restriction
is authorized by difficulty proving a theorem.

Outstanding obligations at S0 are helper grouping, location/byte composition,
lifetime/varargs integration, fence selection, source-order propagation, and
the program-level fault interface. These are implementation/research work for
S1–S4, not additional approval barriers unless the source and standard leave
materially different behaviors unresolved on a concrete example. Completion
still requires the entire charter; a green scalar lane alone is insufficient.

## Source conclusions retained during pruning

- CAS uses representation comparison under [DR431](https://open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0431.html)
  and [N1906](https://open-std.org/jtc1/sc22/wg14/www/docs/n1906.htm). Numerical
  MemValue equality cannot replace it: signed zero, NaNs, padding and provenance
  distinguish the questions. G01 owns the unspecified-byte boundary.
- [N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf) 7.5p3 gives
  other threads indeterminate initial errno; do not initialize child errno to
  zero by applying the general thread-storage rule over that exception.
- Lossless value keys retain types, aggregate tags, provenance and floating bits.
  They are not automatically logical RF equality across typed views. Ordinary C
  numerical equality is unchanged. Other memory models can explicitly lack keys.
- Varargs conflicts concern the same abstract cursor ID: read/read is harmless;
  create/advance/delete modify metadata. Use justified HB, preserving identity
  and multiplicity, without inventing memory writes or synchronization.
- Native object loading and Lean Core-text loading can differ in symbol IDs,
  function-pointer bytes and administrative step counts. In particular the
  printer/parser reconstructs a loaded Specified literal as a constructor.
  Use actual per-engine bindings and retain raw metadata. Equal C outcomes do
  not establish step-level correspondence; counters must not create HB or refusals.

The live [boundary inputs](../../tests/sc/boundaries/README.md) replace archived
campaign copies. Detailed historical records remain in Git at `03f7c5f32`.
