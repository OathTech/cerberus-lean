# SC prototype: operational contract and reference obligations

2026-09-21, [AGENT]. Implementation contract under the
[execution charter](2026-09-21_charter-sc-prototype.md). This document separates
construction decisions from correspondence still to establish. It is not a
claim that the initial tree implements SC.

## Reference identity and scope

Core, the object-model interface and Cmm definitions are taken from the current
implementation base `5407597d9eeba0259d65b728e86a860ad4614ab3`, compared with
pristine upstream `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`. The retained scalar
reference is `Cmm_csem.SC_memory_model` with `SC_condition`, not `tot_memory_model`
or a generic modern C++/RC11 model. Its executable boolean predicates are useful
reference instruments; the target-specific `behaviour` wrappers are not Lean
theorems of the adapter.

`SC_condition` admits NA/seq_cst loads/stores and seq_cst RMWs, with an atomic
initialization condition. It excludes fences, Alloc and Dealloc. Its field
`consistent` is `sc_accesses_consistent_execution`, and its relations are
`release_acquire_relations`. This checker domain is smaller than the prototype's
runtime target. The fence-aware upstream definitions to investigate are
`sc_fenced_memory_model`/`release_acquire_fenced_relations`; merely passing
`SC_memory_model` a fence does not establish its intended behavior.

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
equal locations. Those facts are reference limitations, not runtime guards.

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
