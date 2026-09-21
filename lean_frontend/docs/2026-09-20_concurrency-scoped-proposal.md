# Concurrency: a scoped implementation proposal

2026-09-20. **[AGENT] proposal for discussion, not an adopted charter.**
The user requested continued investigation until a concrete scoped proposal.
This follows the [research assessment](2026-09-20_concurrency-research-assessment.md)
and the [legacy audit](2026-09-19_concurrency-design-assessment.md).

**Scope clarification [USER, 2026-09-20]:** this repository captures Cerberus's
operational semantics and allows reasoning in the customer. It does not develop
the customer's program logic. This revision removes the proposed Iris/proof
client from provider acceptance and separates implementation coverage from
theorem scope. The architecture and SC staging below remain [AGENT] proposals.

**Overriding constraint [USER, 2026-09-20]:** "fidelity is the overriding
constraint. We cannot restrict cerberus for reasoning reasons."
Consequently the earlier blanket SC exclusion list is withdrawn. Restricted
proof/test domains below do not prescribe a restricted operational language.
An unfinished port must identify missing coverage and its concrete fidelity
problem; a difficult proof is not such a problem.

## Recommendation

First identify the exact upstream operational account being captured, including
its threadwise/concurrency integration and known gaps. Preserve its state,
choices, effects, ordering, and outcomes in Lean. Expose definitions and semantic
laws that let a customer build a logic over those same transitions.

A resumable memory-effect interface is a candidate representation. Its
scheduling boundaries must follow the selected operational account or have a
justified correspondence to it. A scalar SC instance is a possible first
implementation slice, not the intended semantics of all concurrent C and not a
substitute chosen because it makes customer proofs easier.

The first implementation project has three deliverables:

1. **A pinned operational reference and correspondence map**, distinguishing
   upstream definitions, port repairs, and any proposed semantic extensions.
2. **Faithful execution and effect boundaries**, including byte accesses,
   `memcpy`, failure-time state, and honest coverage of the implemented profile.
3. **A logic-independent semantic API**, with explicit state, transition and
   outcome definitions, usable step equations, and correspondence for any
   distinct proof-facing presentation. A small import/lemma example can check
   usability; no Iris dependency or application verification is required.

The scalar SC candidate below is intentionally smaller than general concurrent
object-representation access. That extension has its own reference-model
obligation because of C/Cerberus semantics, independently of the customer's byte
heap. It is not solved by changing pointer equality to interval intersection.

Do this on a new implementation branch from the then-current mainline. Salvage
individual legacy changes. The parked branch is evidence and donor material,
not a merge candidate. Customer adoption is separately coordinated and does not
determine provider semantic correctness or completion.

The provider owns operational definitions and facts about them: access effects,
step decomposition, outcome coverage, fuel behavior, and any claimed reference
correspondence. The customer owns Iris language integration, weakest
preconditions, ownership/ghost resources, invariant rules, program proofs, and
logic adequacy using the provider's facts. The customer's presentability needs
inform the API; its proof fragment must not redefine the operational semantics.

## 1. Reference and initial scope

Use the following explicit baseline for evaluating the first SC slice. P0 must
settle how it relates to the selected upstream operational account before this
becomes an implementation charter. Axiomatic Cmm predicates constrain the
claimed behavior; they do not by themselves specify the entire Core adapter.

| Dimension | Proposed choice |
|---|---|
| Standards orientation | C11 concurrency, using N1570 as the public clause reference, with an explicit accounting of DR401 and DR402. This is not a claim of complete C11 or C23 support. |
| Executable object semantics | Current Cerberus concrete memory semantics and its Lean mirror, with program data, implementation parameters, allocator bounds, and outcomes kept explicit. |
| Declarative concurrency reference | The pinned `SC_memory_model` together with `SC_condition` in `frontend/concurrency/cmm_csem.lem`; include its relation calculation and undefinedness predicates. |
| Thread mechanism | Cerberus structured parallel composition/Core `Epar`, with explicit creation and join edges. No claim to implement ISO `<threads.h>` or pthreads. |
| First proof/test domain | Finite control: loop-free bodies, acyclic direct calls, conditionals, and one non-nested structured parallel region. This bounds the first complete-exploration and correspondence claims; it does not by itself justify rejecting loops or other implemented transitions. |
| First memory proof/test cases | Initialized integer scalar objects, whole-object accesses, non-atomic loads/stores and SC atomic loads/stores. This bounds the first proof examples, not support for pointer-valued objects or other Cerberus accesses. |
| First lifetime proof/test cases | Shared objects remain live through join; child-local objects stay private. These are hypotheses of these examples, not new restrictions on Cerberus allocation, sharing or reclamation. |
| Sequencing | Preserve actual source sequencing and local unsequenced-UB checks. Start the correspondence proof with separately sequenced shared accesses. An adapter that cannot handle other patterns must identify that as an implementation limit, not add source ordering to simplify the proof. Calls and hidden effects count. |
| Fidelity inventory, not blanket exclusions | Account for weak orders, fences, RMW/CAS/exchange, `SeqRMW`, nested/dynamic threading, shared lifetimes, mixed-size/aggregate accesses, volatile/device behavior, casts, externs and I/O against the selected upstream account. Record separately what upstream specifies, what its adapter implements, and what remains unported. |

Model conditions, implementation coverage, and theorem/test restrictions are
separate. For example, `SC_condition` describes a named SC reference fragment;
it does not authorize dropping weak behaviors from the overall Cerberus target.
Byte accesses and memory-library operations exercise the effect interface even
when outside the first SC/reference theorem. Existing sequential behavior must
be preserved.

Where an operation is genuinely unimplemented, report that gap explicitly
rather than execute an incorrect approximation. Tie each such refusal to the
missing operational implementation and track its removal. Do not introduce
type, lifetime, privacy, or control-flow refusals merely to enforce a convenient
theorem hypothesis. Semantic validity checks must implement the reference rules.
Coverage accounts for reachable callees and runtime helpers; checking one
observed path is insufficient. Likewise, the scalar examples cannot justify
an unchecked exemption for startup memory.

This small domain is a deliberate first proof target. It still admits SC SB,
MP, and IRIW examples, unsynchronized races, conditional publication, helper
calls, and fork/join behavior. Do not describe all 30 legacy tests as
supported until each has been classified against it.

The ISO clause table should cover memory locations (3.14), conflicting actions
and happens-before (5.1.2.4), and SC atomics/initialization (7.17). Record where
the upstream definitions implement a correction, where the first fragment
makes a difference irrelevant, and where a discrepancy remains. The project
must not silently modernize C using current C++ rules.
[N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf),
[DR401](https://www.open-std.org/jtc1/sc22/wg14/www/docs/dr_401.htm),
[DR402](https://www.open-std.org/jtc1/sc22/wg14/www/docs/dr_402.htm).

## 2. What the source trace changes about the design

Source coordinates below refer to provider mainline
`5407597d9eeba0259d65b728e86a860ad4614ab3`.

| Path | Actual boundary | Consequence |
|---|---|---|
| `core_reduction.lem:72` | A load request already has a continuation accepting an action ID, footprint, and value. Stores accept an ID and footprint. | Extend an existing request/response boundary; do not rebuild expression evaluation inside a concurrency backend. |
| `driver.lem:671`, `:751` | Sequential requests call `Mem.load/store`; the concurrent action path is a TODO. | The SC interpreter can reuse checked concrete operations, provided recording is connected to their actual outcomes. |
| `CerbMem.lean:2419`, `:2474` | Loads reconstruct values from abstract bytes; stores encode values and update bytes plus metadata. Footprints carry access kind, numeric base, and size. | A typed value alone is insufficient for future representation access. A state diff also misses reads and equal-value writes. |
| `CerbMem.lean:2883` | `memcpyM` loops over checked unsigned-character loads/stores, discarding their footprints. | Expose the primitive accesses, including those completed before a later failure. |
| `CerbMem.lean:2918` | `memcmpM` reads the first byte sequence, then the second, then compares them. | Preserve that upstream access behavior; do not implement an early-exit read loop merely because it computes the same result on ordinary inputs. |
| `CerbMem.lean:2945` | `reallocM` composes allocation, checked copy, and kill. | Capture that allocation/copy/lifetime protocol; do not replace it with a single result-pointer write. Any incomplete concurrent handling is a tracked port gap. |
| `driver.lem:814`, `:819`, `:828` | Memops call opaque `Mem` computations through a different driver arm. | Action-only instrumentation is incomplete. Both arms need an explicit effect classification. |
| `driver.lem:217` | File-operation error handling stores directly to `errno`. | Startup, runtime helpers, and error paths require the same inventory. Excluding user I/O does not justify ignoring startup memory. |
| `core_run_aux.lem:338`, `:393` | Sequencing annotations are propagated through Core structures; memops are currently unchanged and unsequenced continuation siblings are skipped. | Supply semantic predecessor information at the effect boundary. Scheduling order cannot substitute for `sb`. |
| `cmm_csem.lem:2564` | `SC_condition` excludes allocation/deallocation events and fences. | Keep checked lifetime transitions in the object component and prove the restricted projection that omits them. Adding such actions to this graph would violate the chosen reference. |
| `cmm_csem.lem:1210`, `:668` | Non-atomic reads-from must be visible under `hb`; program undefinedness is checked over consistent candidates. | A racy concrete schedule need not itself supply a consistent candidate. Prove program-level fault correspondence separately. |

The initial lifetime projection needs a real lemma: shared storage remains live,
private storage cannot be accessed by other threads, initialization is represented
correctly, and omitting lifetime transitions preserves the observations and
faults being claimed. A successful `Mem.allocate` is not itself a Cmm write;
an initial value supplied to object creation may require an initialization
event in the projection.

Two existing notions must remain distinct. `CerbMem.overlapping` is a conflict
test for current unsequenced-access checking: it deliberately returns false for
two reads. It is not a general storage-intersection relation. Likewise, an
allocation, a byte interval, a C memory location, and an atomic object are not
interchangeable identities. The first scalar fragment has a simple mapping
between them; aggregate and mixed-size extensions need an explicit new mapping.

## 3. Proposed interface, with one owner for each decision

Use a small resumable computation for memory operations. The following is
interface notation, not compiled Lem/Lean or a commitment to these names:

```text
MemoryProgram A =
    Done A
  | Request (op : PrimitiveRequest R) (resume : R -> MemoryProgram A)
  | Stop reason

interpretPrimitive(request, objectState)
  -> existing nondeterministic outcomes
     carrying result/failure, resulting objectState, completed effects

effect =
  identity, thread, source, operation group,
  original pointer, resolved allocation identity, allocation-relative range,
  access type, access kind, memory order,
  typed value and representation evidence as applicable,
  semantic predecessors and initialization/lifetime classification
```

There need not be a large byte vector copied into every event. Representation
evidence can refer to the pre/post-state and encoding/decoding relation. It must
retain `AbsByte` provenance/copy information where relevant, rather than reduce
the future interface to lists of numerical bytes.

Responsibilities:

- **Core reduction** chooses permitted expression reductions, preserves
  unsequenced versus indeterminately sequenced evaluation, and supplies the
  continuation and semantic ordering boundaries.
- **The object component** validates pointers, lifetime, bounds and access
  restrictions; performs representation conversion; preserves its metadata;
  and returns the existing outcome and resulting state.
- **The profile guard** checks the requested operation and resolved access
  against the advertised fragment. Unsupported behavior has a typed result,
  separate from C UB, OOM, exhaustion, and an internal defect.
- **The SC component** chooses a runnable thread, services a primitive access
  using the current concrete state, records events, and maintains the SC
  witness and race information. It does not choose an arbitrary typed value
  and then try to overwrite concrete memory to match it.
- **The proof interface** exposes local thread steps and shared-state
  transitions, then the machine relation composing them. It supplies laws for
  the executable implementation rather than a second handwritten scheduler.

Implement common protocol/control definitions in shared Lem where appropriate,
with corresponding OCaml and Lean object-model entry points. Keep the existing
sequential API as an interpreter that drains the resumable computation without
inter-thread yields. This minimizes client churn while making the erasure law
testable and provable.

Represent the byte load/store sequence of a copy explicitly, but do not infer
new scheduling points from that decomposition. The earlier draft recommended
yielding between these operations; under the clarified scope, P0 must first
justify those boundaries against the selected operational reference. Current
sequential erasure alone cannot justify new concurrent interleavings. Any
additional interleavings are an explicit semantic extension unless a
correspondence establishes that they preserve the required behavior. A primitive
SC atomic load/store remains indivisible under the proposed SC instance.

Requests must not cache validity or a read value across a scheduling yield.
Resolve them against the state at service time. Preserve effects completed
before a compound failure and the actual failure-time state; do not roll the
whole operation back. A failed access is a fault record, not an invented
successful read/write event.

For order, retain three different objects: source `sb`, synchronization
including spawn/join, and the scheduler's selected execution order. Derive
`hb` from the reference relations. Restrict the execution order to SC atomics
to construct their witness order; do not add that total order to `hb`.
For each compound operation, specify internal edges and its incoming/outgoing
event boundaries. Joining composes child completion with parent continuation;
siblings acquire no order merely because one ran first.

The proof-facing atomicity law should concern the primitive access at its
evaluation context, not claim that evaluation of an arbitrary C atomic
expression is one step. Argument computation can itself have effects.

## 4. Worked cases that determine the scope

These are source-derived design obligations, not newly executed C results.

| Case | Required behavior and evidence |
|---|---|
| Initialized integer, byte read | Return the existing sequential byte value and relate it to the object's representation, without demanding equality with the entire integer write. Repair the legacy concurrent recording mismatch; exclusion from the first scalar theorem is not a reason to refuse the access. |
| Byte write, whole integer read | Sequentially, write the selected representation byte and reconstruct the subsequent integer using the existing decoder. Retain provenance/metadata. For the later SC extension, one whole read can depend on several byte writes. |
| `memcpy(dst,src,2)` | Expose `R(src+0); W(dst+0); R(src+1); W(dst+1)`. If the last store fails, the earlier write remains in memory and in the completed effect history. The sequential drain must agree with current `memcpyM`. |
| Store of the value already present | Emit a write even if numerical bytes are unchanged. Such a write still matters for races and ordering. |
| `x++ + y` | Preserve the distinction between the chosen evaluation and source sequencing. Exercise the effect/sequencing diagnostic and account for `SeqRMW` faithfully. Do not reject it solely because the first ordering theorem covers simpler expressions. |
| SC publication | Initialize `data=0` and atomic `flag=0`; writer stores `data=1` then SC `flag=1`; reader SC-loads flag and reads data only if it saw 1. That read must see 1. The writer's data write happens-before the guarded data read through the flag communication. No spin loop is needed. |
| Unsynchronized access | With SC flag accesses replaced by unsynchronized ordinary accesses, a conflicting unordered pair must produce a race witness. A total scheduler order does not eliminate the race. A safe observed branch does not certify the whole program. |
| Atomic store buffering | Each thread SC-stores its own flag then SC-loads the other. Both reads returning 0 is excluded. The relaxed-order version is an explicit unsupported input for this executor and a future model discriminator. |
| Race followed by an infinite loop | Outside the first finite-reference theorem. An implementation supporting the loop can expose its operational prefixes without claiming complete exploration or definedness. Its treatment of faults and infinite executions must follow the selected semantics; the limited theorem domain is not itself a reason for runtime refusal. |

The copy trace specifies the current forward per-byte implementation on
ordinary disjoint buffers. It does not repair upstream's documented missing
overlap-UB check, nor certify arbitrary representation/lifetime behavior.
Keep such discrepancies visible under the object-model baseline.

## 5. The contracts to establish

All statements below are proposed obligations. None is claimed proved here.
They justify different claims: operational port fidelity follows the existing
source/differential trust discipline; a distinct Lean semantic presentation
needs a proved connection to execution; a claim of equivalence to the
axiomatic Cmm reference needs the corresponding semantic theorem. Capturing
upstream code does not automatically supply that last theorem, and completion
of customer program proofs is not a provider gate.
Write their executable counterparts with the current full outcome codec and
retain original process statuses.

**A. Sequential effect erasure.** Draining a supported memory program without
thread switches, then erasing effect metadata, gives the same nondeterministic
results, failure reasons, and resulting memory states as the existing `Mem`
operation. Include metadata and partial failures, not just returned values.
First prove this for load/store and the `memcpy` composition. Inventory and
either cover or explicitly bypass/refuse every other path; do not route an
unproved bulk adapter into the supported concurrent profile.

**B. Single-thread conservativity.** For eligible programs without `Epar`,
related initialization, and the same implementation/program parameters, the
new SC profile and sequential semantics have the same completed observations
and semantic faults. Record any erased internal history explicitly. Prove a
fuel correspondence if new bookkeeping changes cost. Do not claim equality
at equal numerical fuel unless that stronger fact is established.

**C. SC correspondence and coverage.** For the finite scalar domain, show:

```text
every executor transition is covered by the exported operational relation;
every finite operational run is explored at sufficient budgets;
on defined programs, projected completed observations equal the SC reference;
program-level undefinedness agrees, via a separate fault-existence argument.
```

Do not require the engine to enumerate arbitrary behavior after C UB, or every
racy reference graph with the same concrete read values. For example, initialize
ordinary `x=0` before spawning a writer of 1 and an unsynchronized reader.
A concrete schedule can return 1 to the reader. Its actual write-to-read edge
is not `hb`, so it fails `consistent_non_atomic_rf`. A reference candidate in
which the reader takes 0 from initialization can instead be consistent and
still contain the unordered writer/reader race. This source-derived example
requires a first-race/program-undefinedness argument, not raw witness equality.
The current `tot_memory_model` has yet another, adjacency-based race predicate;
do not substitute it without its own bridge and hypotheses.

The reference comparison includes threadwise behavior, initialization,
sequencing, value matching, and undefinedness, not only graph consistency.
Finite-control eligibility bounds the source program, not the exploration
budget chosen by a user. A too-small budget is still incomplete.
Generated wrappers that contain `sorry` are not proof dependencies: use the
actual predicates and kernel-checked definitions for the needed behavior layer.

**D. Fault policy.** Separate a path's result from a whole-program verdict.
A valid race/UB witness defeats a definedness claim; absence of such a witness
in a partial search proves nothing. An unsupported branch prevents a complete
coverage verdict even if all explored supported branches look good. Preserve
OOM and both ambient/exploration exhaustion policies. An unexpected
inconsistency on a covered, nonfaulting execution is a defect, not a silently
filtered execution. Racy executions use the separate fault bridge above.

**E. Reasoning access to the operational semantics.** Export state, local and
machine transitions, and outcomes with explicit parameters and nondeterminism.
Prefer relations defined directly from the actual transition functions where
that gives a useful presentation. Supply unfolding, elimination/inversion, and
composition lemmas so the customer need not copy the driver. If a separate
relational presentation is introduced, prove coverage of every executable
choice; the reverse direction alone is insufficient. Fuel/exploration limits
must remain visible, with stability or correspondence lemmas as applicable.

These are facts about the semantics. The customer derives its own program
logic, fault-avoidance results, and postconditions from them. Its Iris instance
and adequacy theorem are outside this repository's implementation scope.

The read-only customer at inspection, `1f1d23c853adc6dffbe015de0fdd62b7153aa7d5`,
still pins provider `e64819de7e5169ea1ea34b284ad000a13edbcdda`.
`CerberusIris/Lang.lean:921` has no forks in its primitive-step relation;
`Adequacy.lean:395` quantifies over every driver outcome, fuel, and exploration
depth for its sequential instance. Its byte resources are keyed by allocation
identity and offset. These are requirements to accommodate, not evidence that
the current client logic already supports concurrency.

A provider-owned import example may show that an external module can state and
use a transition/effect lemma without depending on driver internals. It needs
no Iris or customer dependency. Publication remains a semantic execution test;
an ownership-transfer proof of that program belongs in the customer and is
separately coordinated. Keep Lean definitions transparent and inspectable where
possible; a stable API need not hide state that customers need to reason about.

## 6. Work packages and acceptance

| Package | Scope | Exit condition |
|---|---|---|
| P0: identify the operational contract | Pin the upstream operational model and adapter or historical artifact; classify missing integration and proposed extensions. Reconcile the ISO/Cmm references, startup, scheduling boundaries and outcomes. Separate implementation coverage from theorem/test scope. Inventory effects and select repaired validation helpers. | A source-to-transition map identifies what will be captured and what would be new semantics. SC staging has an explicit relation to that reference. Every reachable operation has a classification; process-status and missing-branch plants fail loudly. |
| P1: expose effects faithfully | Add the selected request/effect representation and sequential drain without inventing interleavings. Cover access, representation evidence, initialization, copy decomposition and failure state; preserve local exclusion/UB behavior. | Erasure lemmas for changed adapters; sequential byte/copy/partial-failure examples; required sequential gates pass in both targets. New concurrent scheduling boundaries require their separate justification. |
| P2: operational SC slice and semantic API | If confirmed by P0, adapt scheduling/spawn/join, exact ordering, guards, races and outcomes for the explicitly supported SC instance. Export the actual transitions and their usable laws. | SC SB/MP/IRIW and race controls, lifetime/startup checks, a logic-independent import example, full outcome/status checks, and proved correspondence for any separate Lean presentation. State the status/domain of the stronger Cmm equivalence claim explicitly. Run affected gates and required final validation. |

Useful legacy donors: model selection and typed refusals, structured scheduling,
startup repairs, corpus inputs, and status-aware validation fixes. Rework event
identity/location recording and sequencing. Defer CAS/RMW donors until a
source review accounts for their success/failure semantics and frontend path;
this is a review dependency, not an exclusion for reasoning convenience.

Do not estimate this as a short recorder patch. P1 changes a foundational
boundary; P2 must establish the connections required by its exposed API and
claims. Report completion package by package. If a proposed theorem fails,
retain its counterexample and distinguish an implementation defect, a false
correspondence claim, and a narrower theorem domain. Do not silently exclude
otherwise implemented programs to make a proof pass. A faithfully captured
upstream operational slice can be delivered before full Cmm equivalence is
mechanized, provided that unproved stronger claim is not advertised as achieved.

Mixed-size memory, `memcpy`, RMW, loops and shared reclamation remain in the
fidelity inventory. Schedule implementation work according to actual upstream
integration gaps and dependencies. Scalar embedding and prefix-safety theorems
may be proved in stages, independently of the executor's supported language.

## 7. Why this architecture, and the bounded weak-memory follow-up

| Option | Assessment |
|---|---|
| Repair only the legacy post-execution recorder | Can improve diagnostics, but does not by itself expose hidden accesses or justify read reconstruction and sequencing. Batched effect summaries might eventually be an optimization, with a commutation/correspondence proof for their domain. |
| Resumable object effects plus a concrete SC interpreter | Candidate first slice, conditional on the upstream correspondence and scheduling decisions in P0. Reuses object semantics and exposes omitted effects. |
| Restore Nienhuis symbolic execution | Prioritize study as an upstream operational reference. Restoration requires symbolic values/control, commitment and object-model integration; scope separately from a scalar SC slice. |
| Adopt an operational RA/RC11 logic model immediately | Ease of Iris reasoning is insufficient grounds for choosing provider semantics. Use these models as comparison material unless an explicit semantic target or correspondence justifies adoption. |

Nienhuis §7 separates threadwise generation from commitment and continues with
symbolic values when a read is unresolved. The finite concurrency-model
equivalence theorem does not prove the current C integration. Its account also
identifies arrays, mixed-size access, lifetime, and dynamic errors as outstanding
integration work. These are reasons to preserve a reference boundary, not to
promise that the concrete SC value carrier is already a universal weak-memory
interface. [Paper](https://www.cl.cam.ac.uk/~pes20/rems/papers/nienhuis-oopsla-2016.pdf).

The pinned BMC source confirms a different adapter: `bmc_incremental.ml:1539`
creates fresh symbolic load results; `:1776` has `memcmp` as `assert false`,
and `:1816` handles other unsupported memops with failure. BMC is a useful
comparison implementation on a matched fragment, not a ready replacement for
the concrete memory boundary.

Alongside P0/P1, run a bounded research comparison of three precisely identified
weak-memory accounts: prioritize the historical Cerberus/Nienhuis model as the
upstream reference; use versioned RC11 and an Iris-oriented operational account
to study semantic differences and presentation techniques. They are not equal
votes on which behavior this port should implement. This does not add a
weak-memory implementation to the project. Use SC publication,
relaxed SB, dependency cycles, mixed SC/weak accesses, and the RC11 correction
case from the research assessment. Record model identities, translations,
allowed differences, and proof coverage. Pin tools locally if networking
permits; blocked external runs remain unmeasured, never passing checks.

Re-proving abstract client specifications for a new model is customer work.
Any provider claim of a stronger SC-to-target semantic transport theorem must prove target
definedness and inclusion of target observations in the set covered by the SC
proof, on a named fragment. Merely allowing all generated SC executions, or
data-race freedom with arbitrary weak atomics, does not establish that result.

## Evidence and limits of this pass

This proposal adds source tracing of the current memory operations, request
continuations, sequencing helpers, Cmm commitment API, BMC translation, and the
customer's actual step/adequacy boundary. Web access to the cited primary
documents succeeded despite the session's limited networking. No external
checker was installed or run.

The worked traces are derived from source. The retained C counterexamples and
legacy litmus measurements belong to the September 19 audit. This pass adds no
new C executions, Lean proofs, or implementation certification. Only this
proposal and the research assessment are changed. The scope clarification
revision changes responsibilities, acceptance criteria, and the status of the
architecture recommendations; it adds no implementation. The customer
repository was read only; its active local edits were left untouched.
