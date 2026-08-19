# Iris concurrency and weak-memory reasoning: survey and Cerberus-Lean options

Date: 2026-08-19

Status: research and design note. This note does not propose that the current
Cerberus concurrency semantics be replaced, and it does not claim that any of
the cited Rocq developments can be imported into Lean directly.

## Executive conclusion

There is now a substantial, mechanized body of weak-memory reasoning built on
Iris. Its central C/C++ lineage is:

1. RSL, GPS, and FSL/FSL++ established separation-logic proof rules directly
   over axiomatic fragments of C11.
2. iGPS (2017) supplied an interleaving operational characterization of C11
   release/acquire plus non-atomics (RA+NA), instantiated Iris with it, and
   derived higher-level logics.
3. iRC11 (2020) moved to repaired C11 (RC11), adding relaxed accesses,
   release/acquire fences, a stronger race detector, and reclaimable resources.
4. Compass (2022), the OMO proof recipe (2024), and 2025 case studies made the
   logic substantially more useful for modular specifications and realistic
   lock-free algorithms.
5. Separately, AxSL (2024) demonstrated that Iris can be connected to an
   axiomatic execution-graph model by a mixed operational/axiomatic ("opax")
   semantics, rather than by replacing that model with a view semantics.

The reusable result for this project is an architecture, not a ready-made
library:

- a proof-facing small-step or opax semantics;
- an Iris state interpretation connecting physical histories/execution graphs
  to authoritative ghost state;
- view-dependent propositions for weak-memory facts;
- objective invariants for facts shared across threads;
- a high-level logic that hides views from data-race-free clients; and
- event-history/logical-atomicity abstractions only after the base rules are
  adequate.

There is **no semantics-preserving drop-in iRC11 backend for Cerberus**. iRC11
targets RC11 and, even in the 2025 development, does not cover SC atomic
accesses or `memory_order_consume`. The Cerberus model in this tree describes
the original, broad C11 model and includes non-atomic, relaxed,
release/acquire, consume, and SC accesses, fences, locks, allocation, and
deallocation. Choosing iRC11 as the physical semantics would therefore be a
language-model change, not merely an Iris retrofit.

The recommended first route is to retain `cmm_csem.lem` as the semantic
authority, restore a small relational concurrency seam in Lean, and evaluate
two proof-facing presentations against the same finite litmus suite:

- the existing Nienhuis/Cerberus commitment-order operational model in
  `cmm_op.lem`; and
- an AxSL-style opax presentation that guesses a valid complete candidate
  execution and checks each thread against it.

Use iGPS/iRC11 as the design source for views, race ownership, points-to
predicates, and surface rules. Do not import ORC11 as the definition of
Cerberus behavior unless a separate, explicit model migration to RC11 is
decided and justified.

The public research pipeline does not reveal a team already building the
missing Cerberus-to-Iris weak-memory bridge. The strongest current signals are
instead complementary: Iris-Lean is progressing rapidly; 2026 Iris work on
completeness and multi-language logics supports checked embeddings of external
reasoning; ArchSem is developing a model-facing concurrency interface; and
VerCors-relaxed is pushing automated view-protocol verification. The mature
KAIST iRC11/OMO repositories look like paper artifacts rather than public
post-2025 development branches. These observations argue for building the
bridge now while reusing and monitoring the generic infrastructure.

On the trusted-computing-base question, the short answer is **yes in
principle, but not merely from OCaml parity**. A faithful Lean formulation of
the Cerberus candidate-execution predicates can be the semantic authority for
an independently invented logic. The logic's proof search, automation, and
even proof producer may be untrusted if they emit a proof or certificate that
Lean checks, and a proved adequacy/reflection theorem turns acceptance into a
fact about Cerberus behavior. This does not require changing the C memory
model. The current Lean export is not yet such a boundary: important behavior
definitions are missing, some target-specific executable definitions are
deliberate approximations, and the Isabelle correspondence results for the
operational model are not Lean theorems.

## 1. What is in this tree today

### 1.1 The semantic source is an axiomatic C11 execution-graph model

[`frontend/concurrency/cmm_csem.lem`](../../frontend/concurrency/cmm_csem.lem)
is the cppmem-era mathematical model. It defines:

- actions for loads, stores, RMWs, fences, locks, unlocks, blocked RMWs,
  allocation, and deallocation;
- memory orders `NA`, `Relaxed`, `Release`, `Acquire`, `Acq_rel`, `Seq_cst`,
  and `Consume`;
- pre-executions containing actions and threadwise relations such as
  sequenced-before (`sb`), additional-synchronizes-with (`asw`), and data
  dependency (`dd`);
- execution witnesses containing reads-from (`rf`), modification order (`mo`),
  SC order, lock order, and related derived relations; and
- model behavior by filtering candidate executions through consistency and
  undefined-behavior predicates.

It contains a family of submodels—single-threaded, lock-only, relaxed-only,
RA, RA+relaxed, fenced, SC, consume, standard, and total—which is useful for a
staged port. The top-level `behaviour` definition classifies a program as
`Undefined` if the global condition fails or a consistent execution contains a
specified fault; otherwise it returns observable executions. This global
classification needs deliberate treatment in an Iris adequacy statement:
ordinary Iris safety is an execution-local property, while C data-race UB is a
whole-program semantic effect.

### 1.2 Cerberus already contains a relevant operationalization

[`frontend/concurrency/cmm_op.lem`](../../frontend/concurrency/cmm_op.lem) is
the implementation associated with Nienhuis, Memarian, and Sewell's
[operational C/C++11 model](https://doi.org/10.1145/2983990.2983997). It does
not simply execute each thread in program order. It incrementally commits
actions in a special commitment order, extends `rf`, `mo`, SC, and lock order,
and checks consistency as it goes. Its comments state that the simplified
axiomatic model is equivalent to the original for finite executions and point
to Isabelle proofs for the operational equivalence conditions.

This is unusually close to what an Iris instantiation needs: a transition
system rather than only a predicate on completed graphs. It is not immediately
usable, however:

- the commitment machine and the Core thread semantics advance independently;
- some reads must initially yield symbolic values and be resolved later;
- the executable monadic layer assumes exhaustive branching/backtracking;
- the source comments are cautious about exactly which submodels satisfy the
  equivalence hypotheses; and
- Chapter 10 of Memarian's
  [Cerberus thesis](https://doi.org/10.48456/tr-981) says that changes elsewhere
  in Cerberus have made the historical integration non-operational in the
  current source.

The theorem-level `incTrace` relation is more relevant to an Iris weakest
precondition than the exhaustive `ndM` runner. Proof adequacy should be stated
against a relation, with execution/enumeration kept as a validation tool.

### 1.3 The Lean port is not concurrency-ready

[`lean_frontend/CerbConcurrency.lean`](../CerbConcurrency.lean) is explicitly a
stub. `statically_satisfied` always returns `true`, and the actual behavior
functions are absent. In the Lem source, `observable_filter`, `behaviour`,
`rf_behaviour`, every named submodel behavior, and the pretty-printer seam in
`cmm_op.lem` are still mapped to Lean `sorry` target representations. Generated
types and many relation calculations exist, but that is not an executable or
proof-sound concurrency semantics.

No Iris implementation is present under `lean_frontend` at the time of this
survey. Consequently there are two independent projects:

1. make the concurrent Cerberus semantics honest and relational in Lean; and
2. instantiate (or build) the Iris proof machinery over that relation.

Conflating them would make it difficult to tell whether a failed proof is a
logic-design issue, a Lean port issue, or a semantic mismatch.

### 1.4 Can a novel logic remain outside the TCB?

Yes, provided "validates inside-Cerberus properties" has a precise meaning.
Under the intended trust policy, the trusted base is the Lean kernel plus the
ported Cerberus model (and any explicitly accepted axioms in that model). The
novel logic need not be trusted merely because it is novel or implemented
outside Lean. Its results must end as proof terms accepted by the kernel.
The desired boundary is:

```text
untrusted agent / proof search / novel logic implementation
                      |
            proof term or certificate
                      |
       verified checker or logic inside Lean
                      |
       proved soundness/reflection theorem
                      |
              Lean kernel checks
                      |
 Cerberus consistency / UB / observable-behavior proposition
```

The external agent may discover invariants, choose interference protocols,
construct execution graphs, or search a proof calculus. It is outside the TCB
only when a bad answer is rejected by code whose connection to the Cerberus
semantics has been proved in Lean and whose resulting proof term is accepted
by the kernel. Tactics, native evaluators, external solvers, and the agent may
accelerate construction, but none may be the final reason the proposition is
accepted. Printing `valid`, passing litmus tests, or agreeing with the OCaml
executable does not by itself establish that connection.

There are two useful certificate shapes:

| Claim | Possible untrusted output | What Lean must establish |
|---|---|---|
| A behavior is allowed | Core trace, pre-execution, witness, and relation data | The trace generates that pre-execution and the Cerberus consistency predicates hold |
| A behavior is impossible | A proof in a checked calculus, or a proof-producing finite solver certificate | No matching consistent candidate execution exists |
| A bounded search is exhaustive | Enumerated candidates plus coverage evidence | Completeness only within the stated bound |
| A program is race-free/safe | Invariants and a logic derivation | Every relevant execution avoids the Cerberus fault/`Undefined` conditions |
| A library refines a specification | An Iris-style derivation and abstract history | Adequacy from the logic judgment to Cerberus observable behaviors |

The asymmetry matters. An allowed finite execution has a natural finite
witness. Universal correctness cannot normally be certified by presenting one
execution, and testing all executions up to a bound proves only a bounded
claim. For unbounded programs, the agent must usually return an inductive
invariant or derivation in a proof system whose soundness has already been
proved. Iris is one way to build that checked proof system; it is not itself a
substitute for the adequacy theorem.

The existing source contains most of the mathematical vocabulary needed for
this architecture: pre-executions, candidate witnesses, derived relations,
model conditions, race/fault classification, and observable behaviors. It
also contains two plausible validation routes:

- directly decide finite instances of the axiomatic predicates and prove a
  Boolean/`Prop` reflection theorem; or
- check a relational `incTrace` certificate and use a proved connection from
  complete commitment traces to the axiomatic model.

The second route already has soundness and completeness results in
[`frontend/concurrency/Cmm_op_proofs.thy`](../../frontend/concurrency/Cmm_op_proofs.thy),
including `incConsistentSoundness`, `incConsistentCompleteness`, and the finite
`incConsistentEquivalence`. They are valuable evidence that no new semantic
primitive is inherently necessary. They are not part of the Lean trust story
until their assumptions and conclusions are restated and proved against the
current Lean definitions.

"Complete the Lean port at parity with OCaml" should therefore mean semantic
parity for a stated fragment, not just generate the same executable code. For
example, [`cmm_csem.lem`](../../frontend/concurrency/cmm_csem.lem) maps
`finite_prefixes` to `true` for OCaml, Rocq, and Lean, and maps
`minimal_elements s r` to `s` for those executable/proof targets, while its
HOL definitions carry the mathematical content. These can be legitimate
finite-execution or search over-approximations in a particular call path, but
they cannot silently stand in for the propositions used by an adequacy proof.
Likewise, differential agreement with OCaml is excellent regression evidence,
not a proof of correspondence.

A minimally trustworthy Lean boundary needs:

1. proposition-level definitions of Core-generated pre-executions, witnesses,
   consistency, faults/races, and observable behavior;
2. decidable checkers for the finite parts, with reflection theorems connecting
   their `true` results to those propositions;
3. verified equality, ordering, finite-set, and relation operations used by
   the checkers;
4. an explicit theorem connecting Core executions to concurrency events;
5. a sound proof-facing step/check relation, and a completeness theorem if the
   intended result depends on exploring all allowed behaviors; and
6. an adequacy theorem from the novel logic's judgment to the chosen Cerberus
   safety or refinement property.

Adding these definitions, checkers, and theorems is substantial model
*formalization*, but need not be a model *change*. A derived operational or
opax relation remains outside the semantic authority when its soundness is
proved against `cmm_csem`. A model change is required only when the desired
rules validate behaviors different from the selected Cerberus contract—for
example, replacing legacy C11 with RC11, omitting consume, or assigning SC
accesses stronger or weaker behavior. Iris does not force any of those
choices.

Put another way: after a faithful port, an external agent could invent a logic
that the project never anticipated. Either it emits direct proofs of
Cerberus-level properties, or the project formalizes that logic's judgment and
proves its adequacy once, after which the agent emits derivations in the logic.
In both cases, a bug in the agent or proof search causes rejection rather than
an unsound Cerberus theorem. This is the positive answer to the central
question of this note.

## 2. Why ordinary Iris concurrency is not enough

Iris is a framework for constructing higher-order concurrent separation
logics. The standard presentation assumes a per-thread small-step semantics,
an Iris proposition type backed by user-chosen resource algebras, and a state
interpretation tying the physical machine state to logical resources. Its
ordinary shared-heap instance is sequentially consistent: threads interleave
over one current heap.

Weak memory breaks the idea that every thread reasons about the same latest
heap. A thread can observe a stale write, different threads can observe writes
in different orders, and synchronization changes what a thread is entitled to
observe. Therefore it is unsound merely to reuse SC points-to predicates and
general invariants over Cerberus's weak-memory transitions.

The recurring Iris solution is:

```text
axiomatic or operational memory semantics
                 |
       proof-facing transition system
                 |
       Iris base logic + state interpretation
                 |
 view-dependent propositions / objective assertions
                 |
 protocols, invariants, logical atomicity, automation
```

This layering is one of the strongest lessons of iGPS, iRC11, and Cosmo. The
base layer exposes histories, timestamps, reads-from choices, and views. The
surface layer recovers conventional points-to and invariant rules where the
memory model permits them.

## 3. Research lineage

### 3.1 Pre-Iris weak-memory separation logics

These works are not Iris instances, but they supplied most of the concepts
later encoded in Iris:

- **RSL** — Vafeiadis and Narayan,
  [Relaxed Separation Logic](https://doi.org/10.1145/2509136.2509532), OOPSLA
  2013. A logic for C11 release/acquire reasoning with ownership transfer.
- **GPS** — Turon, Vafeiadis, and Dreyer,
  [Navigating Weak Memory with Ghosts, Protocols, and Separation](https://doi.org/10.1145/2660193.2660243),
  OOPSLA 2014. Per-location protocols and ghost state made substantially richer
  algorithms verifiable.
- **FSL/FSL++** — Doko and Vafeiadis,
  [A Program Logic for C11 Memory Fences](https://doi.org/10.1007/978-3-662-49498-1_18)
  and
  [Tackling Real-Life Relaxed Concurrency with FSL++](https://doi.org/10.1007/978-3-662-54434-1_17).
  These introduced modalities and rules for relaxed operations, fences, CAS,
  shared non-atomic reads, and ghost state.

They demonstrate that useful weak-memory rules can be proved directly against
an axiomatic semantics, but their soundness arguments are specialized and
global. Iris's attraction is that generic ghost state, invariants, higher-order
assertions, and proof-mode infrastructure can be reused once the physical
semantics is connected to Iris.

### 3.2 iGPS: Iris over C11 RA+NA (2017)

Kaiser, Dang, Dreyer, Lahav, and Vafeiadis,
[Strong Logic for Weak Memory](https://doi.org/10.4230/LIPIcs.ECOOP.2017.17),
is the foundational paper for weak-memory Iris.

Its semantic step is as important as its logic. It gives an interleaving
operational model where:

- each atomic location has a timestamped history of writes;
- each thread has a view recording the newest write it has observed at each
  location;
- release writes attach the writer's view to a message;
- acquire reads join that message view into the reader's view; and
- an operational race detector maps races involving non-atomics to a special
  error state.

The paper establishes correspondence with declarative C11 RA+NA for programs
that do not mix atomic RMWs with non-atomic reads at the same location. It then
instantiates Iris and derives iRSL and iGPS. iGPS adds single-writer protocols,
escrows, fractional protocols, and mechanized case studies.

Fit for Cerberus: this is the clearest small starting fragment and the best
explanation of how views enter Iris. It is not broad enough to be the final
Cerberus logic: it omits relaxed operations, fences, SC, and consume, and its
correspondence has a mixed-access restriction.

### 3.3 iRC11 and RustBelt under relaxed memory (2020)

Dang, Jourdan, Kaiser, and Dreyer,
[RustBelt Meets Relaxed Memory](https://doi.org/10.1145/3371102), introduces
ORC11 and iRC11.

ORC11 is an operational presentation of a large fragment of **repaired C11**.
It adds relaxed accesses and release/acquire fences to RA+NA. Each thread has
current, release, and acquire views; writes publish message views, relaxed
reads affect the acquire view, and fences move information between these
views. Its global state also includes a race-detector view. The paper sketches
a correspondence with RC11 and mechanizes the semantics and logic in Rocq.

iRC11's main logical additions include:

- view-dependent propositions (`vProp`), monotone in the current view;
- atomic points-to assertions that own a location history, rather than just a
  latest value;
- release and acquire modalities for fence reasoning;
- single-location invariants for ownership transfer;
- cancellable invariants, enabling deallocation and memory reclamation; and
- synchronized ghost state, needed so that cancellation tokens themselves
  respect synchronization.

The RustBelt port is evidence that the design supports more than litmus tests:
it re-verifies relaxed implementations of Rust libraries, adapts lifetime
reasoning, and found a real race in `Arc`.

Important scope boundary: the 2020 ORC11/iRC11 language omits SC accesses and
SC fences. The current iRC11 line has since gained SC-fence reasoning, used in
the 2025 RCU work, but explicitly still does not consider SC **accesses**.
There is no support for C11 consume. ORC11 is also RC11, not the legacy C11
model implemented by `cmm_csem.lem`.

### 3.4 Cosmo: a clean two-level weak-memory logic (2020–2021)

Mével, Jourdan, and Pottier,
[Cosmo](https://doi.org/10.1145/3408978), targets the Multicore OCaml memory
model, not C11. It is nevertheless a particularly useful design reference.
`BaseCosmo` exposes histories and views; `Cosmo` builds a usable logic above
it. Its assertions are implicitly view-indexed and can be split into:

- a subjective component saying that the current thread has seen a view; and
- an objective component saying that an assertion holds at a fixed view.

Only objective assertions may inhabit ordinary shared invariants. Runtime
synchronization transports the subjective observation needed to recover the
full assertion. A high-level fragment then looks like traditional CSL for
programs whose ordinary accesses are data-race-free and mediated by verified
locks.

The follow-up
[bounded queue verification](https://doi.org/10.1145/3473571) demonstrates
that view-indexed invariants can specify and verify a realistic queue and its
clients modularly.

Fit for Cerberus: the two-level interface and the
subjective/objective split should be copied conceptually. The physical memory
model should not: unlike C11, Multicore OCaml assigns defined behavior to
nonatomic races and gives its atomics stronger global ordering.

### 3.5 Compass: modular library specifications (2022)

[Compass](https://doi.org/10.1145/3519939.3523451) extends iRC11 with logical
atomicity, objective invariants, explicit-view modalities, and atomic
points-to assertions. It combines logically atomic triples with event graphs
and partial orders inspired by relaxed variants of linearizability.

This matters because an SC linearization order can be too strong or even
meaningless for a relaxed library. Compass specifications can expose only the
causal/visibility order clients need. Its mechanized cases include stacks,
queues, exchangers, an elimination stack, and a Herlihy–Wing queue.

Fit for Cerberus: this is a surface-specification layer, not a starting point.
Its value comes after primitive Cerberus atomic operations and objective
invariants have sound rules.

### 3.6 OMO and proof automation (2024)

Park et al.,
[A Proof Recipe for Linearizability in Relaxed Memory Separation Logic](https://doi.org/10.1145/3656384),
introduces object modification order (OMO): an object-local analogue of C11
per-location modification order. A `commit-with` relation connects
linearization points across layered libraries. The development also adapts
Diaframe automation to iRC11.

The reported case studies include Treiber and elimination stacks, the
Michael–Scott queue, Folly's MPMC queue, spinlocks, and atomic reference
counting. OMO plus Diaframe substantially reduced proof-script size in several
cases, but the reusable library and hints are themselves large Rocq
developments.

Fit for Cerberus: OMO is a strong eventual target for library proofs. It is
premature until the base logic, view rules, and CAS/fence specifications are
stable. Automation should be budgeted as its own project, not assumed to come
with an Iris port.

### 3.7 AxSL: Iris over an axiomatic graph (2024)

Hammond et al.,
[The AxSL Logic](https://doi.org/10.1145/3632863), is about Arm-A rather than
C11, but it changes the architectural design space for this project.

AxSL does not replace the authoritative axiomatic model with a conventional
interleaving view model. Its opax semantics nondeterministically chooses a
complete graph satisfying the axiomatic model, then independently checks each
thread's instructions against the corresponding graph events. A stuck thread
means that the chosen candidate graph does not describe that program; it is
not program UB. AxSL defines a non-standard Iris weakest precondition and
adequacy theorem over this setup.

Benefits for Cerberus:

- the existing execution graph and consistency predicate can remain the
  semantic source of truth;
- correspondence with a separately designed operational memory model need not
  be the first proof obligation; and
- assertions can be tied to events and relations already present in
  `cmm_csem.lem`.

Costs:

- the WP and adequacy proof are substantially non-standard;
- a complete candidate graph is an ambient prophecy-like object;
- the semantics is proof-facing, not executable; and
- AxSL's rules and resource flow are tailored to Arm `ob`, not C11
  happens-before, modification order, SC order, and race UB.

AxSL is therefore a pattern, not a reusable C11 logic. It is the strongest
alternative if restoring the Nienhuis commitment machine proves too coupled
to the historical Core evaluator.

### 3.8 Iris over a real C semantics (2024)

Mansky and Du,
[An Iris Instance for Verifying CompCert C Programs](https://doi.org/10.1145/3632848),
rebuilds VST's Verifiable C logic over Iris and CompCert's existing semantics.
It required a custom resource algebra for CompCert memory permissions and a
custom weakest precondition because ordinary Iris heap resources and WP were
not a direct fit.

This is currently a sequential result, but its engineering lesson is directly
applicable: do not force a full-scale C semantics into the standard Iris heap
instance. Design the physical resource algebra and WP around the semantics'
actual memory permissions, external calls, initialization, and control flow.
For Cerberus that includes provenance, allocation status, byte/object views,
indeterminate values, UB, and the concurrency event graph.

### 3.9 Recent evidence of scale (2025)

Two PLDI 2025 iRC11 developments show where the mature stack has reached:

- Jung et al.,
  [General-Purpose RCU](https://doi.org/10.1145/3729246), verifies modular RCU
  with switchable critical sections and concurrent writers. It adds useful
  SC-fence rules, including an SC-view modality and a history abstraction, and
  verifies Peterson's mutex in relaxed memory.
- Park et al.,
  [Lock-Free Traversals](https://doi.org/10.1145/3729248), verifies a lock-free
  list, skiplist, and skiplist priority queue. Per-key linearizable histories
  avoid globally ordering unrelated keys, and a `shadowed-by` relation handles
  stale edges observed by traversing threads.

These works confirm that view-dependent Iris reasoning can scale to
reclamation and traversal. They also confirm that model-specific proof
infrastructure accumulates over years; the end-state should not be mistaken
for an appropriate first milestone.

## 4. Active groups and public pipeline signals

This section is a dated snapshot, checked on 2026-08-19. Repository activity,
workshop abstracts, and preprints are evidence of public work, not a basis for
claims about private projects. In particular, an artifact repository with a
small commit history should not be described as an active upstream merely
because its paper is recent. The useful confidence classes here are:

- **active public development**: recent commits, releases, or a 2026 paper;
- **announced work in progress**: the researchers themselves describe the
  work as ongoing, but there is not yet a public development to evaluate; and
- **publication artifact**: valuable mechanized code, but no visible evidence
  of a post-paper research branch.

### 4.1 Iris-Lean is the strongest directly reusable current effort

The distributed
[Iris-Lean community](https://github.com/leanprover-community/iris-lean) is the
clearest active dependency for this project. The repository had 492 commits
when inspected, with a dense run of changes on 7--12 August 2026 touching
resource algebras, invariants, later credits, HeapLang, and WP tactics. Its
latest release at the time of inspection was
[v4.32.2](https://github.com/leanprover-community/iris-lean/releases), dated 29
July 2026, and the project deliberately tracks Lean releases. This is active
infrastructure work rather than a static research artifact.

The invited Iris-Lean talk at the
[2026 Iris Workshop](https://iris-project.org/workshop-2026/) described a
coordinated community port and projects already being built above it. The
public [porting dashboard](https://leanprover-community.github.io/iris-lean/)
reported 90.4% of tracked Rocq items as ported or deliberately ignored, with
the remainder stale, and the important `program_logic` area was well
advanced. That percentage is a source-tracking metric, not a semantic
completeness theorem. The talk's remaining-work list included constructions
such as atomic updates/triples and some resource algebras. Those gaps matter
for eventually porting Compass or OMO, but not for beginning a Cerberus state
interpretation and primitive WP experiment.

This changes the engineering recommendation: reuse the maintained Iris-Lean
base rather than independently rebuilding Iris. It does **not** supply a weak
C memory logic. No public repository or workshop announcement found in this
survey connects Iris-Lean to iRC11, AxSL, or Cerberus. The active work lowers
the cost of the generic logic and proof-mode layers; this project still owns
the Cerberus adequacy bridge and weak-memory instance.

The talk also listed proof automation and Lean-AI integration among future
directions. Independently, the 2026 ITP paper
[Lazy Proof Automation for Separation Logic](https://volodeyka.github.io/static/pdf/yolo-itp26.pdf)
instantiates its proof-producing automation for Iris-Lean. These are concrete
signals that the ecosystem is moving toward sophisticated, possibly external
proof search with checked reconstruction. That is a good fit for the intended
outside-TCB agent architecture, although neither system currently produces
Cerberus weak-memory proofs.

### 4.2 The Iris frontier is moving toward semantic bridges and certificate-friendly completeness

Three 2026 Iris-community efforts are unusually relevant even though none is
a Cerberus logic:

1. Hostert, Zhang, Liu, Gregersen, Jung, and Tassarotti's accepted ICFP 2026
   paper,
   [Completeness of Iris-Based Program Logics](https://icfp26.sigplan.org/details/icfp-2026-icfp-papers/10/Completeness-of-Iris-Based-Program-Logics),
   gives language-independent completeness methods and mechanized instances
   for partial, total, quantitative, and relational Iris logics.
2. Zhang, Gregersen, and Tassarotti's July 2026 preprint,
   [Completeness of Logical Atomicity for Linearizability in Concurrent Separation Logic](https://arxiv.org/abs/2607.11435),
   derives logically atomic specifications from linearizability and embeds
   external techniques including forward simulations and meta-configuration
   tracking into Iris.
3. Alexander Loitzl's workshop talk
   [Multi-language Program Logics](https://iris-project.org/workshop-2026/)
   explicitly describes an ongoing framework for reusing specifications
   across languages and for relating languages that differ fundamentally,
   including in their memory models. No public code or preprint was located,
   so this is a high-relevance, low-concreteness watch item.

The completeness results do not make an untrusted tool sound, and ordinary
linearizability is not automatically the right relaxed-memory specification.
Their architectural implication is narrower and useful: an external method
can compute a simulation, history, invariant, or atomicity argument and then
have that argument embedded into a kernel-checked Iris derivation. That is
almost exactly the desired division between an inventive outside agent and a
small trusted acceptance boundary. The missing theorem for this project is
still adequacy from the particular Lean Iris judgment to the particular
Cerberus behavior proposition.

The multi-language work is the public signal closest to a future reusable
semantic-bridge abstraction. Until code and theorems appear, it should be
monitored rather than placed on the critical path.

### 4.3 REMS and ArchSem are the closest active architectural analogue

The Cambridge REMS project and collaborators are actively developing
[ArchSem](https://github.com/rems-project/archsem), a Rocq framework that
connects instruction-set semantics to multiple concurrency models. It already
has a generic interface and candidate-execution type, Arm axiomatic and
promising models, and RISC-V and x86 instantiations. Its stated goals include
Iris-based higher-level logics, compiler correctness, refinement between
models, and litmus execution. Its roadmap proposes importing relaxed-memory
components from Herd or Isla Axiomatic.

This is architectural evidence for keeping a model-facing interface separate
from proof logics, not reusable C11 code. It is also a useful warning. The
repository explicitly calls out incomplete extraction/testing, a very
work-in-progress virtual-memory promising model, and potentially unsound
undefined-behavior handling for partial axiomatic executions. That is the same
fault line Cerberus-Lean must treat carefully: a candidate graph and a checker
are not enough unless partial executions, stuckness, faults, and whole-program
UB are related by proved theorems.

The separate [AxSL repository](https://github.com/logsem/AxSL) contains the
published opax semantics, WP, primitive-rule soundness, and adequacy proof, but
its small 15-commit history and artifact-style layout are not evidence of a
new C11 branch. ArchSem is the stronger current signal to watch for reusable
model-interface ideas.

### 4.4 KAIST has the deepest recent iRC11 application line, but public repositories look like snapshots

The KAIST Concurrency and Parallelism group is the most concentrated recent
source of iRC11 application work: OMO and Diaframe automation in 2024, followed
by several 2025 results on RCU, hazard pointers, and lock-free traversal. Its
[OMO development](https://github.com/kaist-cp/relaxed-memory-separation-logic)
contains `orc11`, `gpfsl`, OMO libraries, Diaframe hints, and substantial case
studies. Its
[safe-memory-reclamation development](https://github.com/kaist-cp/smr-verification)
combines the 2023 SMR framework with 2025 hazard-pointer work.

The public repositories should nevertheless be treated as artifacts, not as
evidence of an unpublished next version: their visible histories contain only
four and five commits respectively, and the SMR README says its Diaframe area
is not maintained. The OMO README also records that its ORC11 semantics was
simplified for proof automation. This makes the code an excellent design and
case-study source but a poor candidate for direct vendoring, even before the
Rocq-to-Lean boundary and the RC11-versus-Cerberus mismatch are considered.

No public post-2025 branch, preprint, or announcement found here claims SC
atomic accesses, consume, or a connection to a full C semantics. Absence of a
public signal is not evidence that nobody is working on these topics; it does
mean the project should not plan around an assumed forthcoming iRC11 solution
to those gaps.

### 4.5 Automated weak-memory verification is active outside Iris

The University of Twente/Eindhoven team released the April 2026 preprint
[Deductive Verification of Weak Memory Programs with View-based Protocols](https://arxiv.org/abs/2604.21084).
`VerCors-relaxed` extends VerCors's atomic support and encodes the relaxed
fragment of SLR with view protocols, automatically discharging examples from
the literature. The main
[VerCors repository](https://github.com/utwente-fmt/vercors) is a large,
actively maintained verifier, not a one-off proof artifact.

This is a strong sign that weak-memory research is moving from bespoke manual
proofs toward automated protocol reasoning. Its algorithms and annotation
design may inform an agent-facing Cerberus logic. VerCors's successful verdict
is not, however, a Lean-kernel proof. Under this project's trust policy, the
reusable pattern is to make an untrusted automation layer return invariants or
derivations that a proved Lean checker accepts.

Two other public lines are useful as validation oracles rather than proof
foundations. Margalit, Kokologiannakis, Itzhaky, and Lahav's
[RSan](https://arxiv.org/abs/2504.15036) dynamically checks robustness against
a C11-style weak model, and the standalone
[RC11-in-Coq repository](https://github.com/qladevez/rc11) formalizes
executions, prefixes, conflicts, and ordering while marking its DRF-SC proof
as work in progress. RSan cannot establish universal program correctness, and
the RC11 repository is a small development with no visible evidence here of a
currently active research program. Both can still suggest litmus tests and
theorem decompositions.

The Cambridge CN/Fulminate/Darcy work presented in the invited
[Gradual Assurance for Systems Software](https://iris-project.org/workshop-2026/)
talk is adjacent in a different way: it combines runtime specification
testing, property-based testing, and eventual proof for C systems code. It is
a useful workflow analogue for combining OCaml differential tests with
kernel-checked Lean proofs. The talk did not announce a concurrency or weak-C
memory logic, so it is not evidence that the model bridge required here is
already being built.

### 4.6 What the public pipeline does and does not change

The public evidence supports four planning conclusions:

- **Do not wait for a public Cerberus/iRC11 integration.** None was found. The
  nearest live efforts solve generic Iris-in-Lean infrastructure,
  cross-language interfaces, architectural semantics, or automated reasoning
  for a different model.
- **Track Iris-Lean closely.** It is advancing quickly enough that locally
  recreating generic resource algebras, invariants, WP, and proof mode would
  likely create avoidable maintenance work. Atomic updates/triples are the
  most relevant visible dependency for later Compass/OMO-style layers.
- **Treat outside automation as a proof producer.** The completeness and
  automation work strengthens the case for external search followed by
  checked reconstruction. It does not relax the requirement for a Lean
  adequacy/reflection theorem ending in Cerberus predicates.
- **The gaps are mainly formalization and logic gaps, not missing semantic
  machinery.** Cerberus already exposes events, candidate witnesses,
  consistency, dependency, races/faults, and observable behaviors. SC and
  consume lack mature Iris rule libraries, but that calls for new derived
  rules and proofs. A model change is needed only if those rules intentionally
  target RC11 or another behavior set instead of the selected Cerberus model.

The most useful groups to monitor are therefore the Iris-Lean maintainers,
the ETH/NYU/CISPA completeness collaboration, the ISTA multi-language effort,
REMS/ArchSem, the KAIST iRC11/OMO line, and the VerCors-relaxed team. Workshop
pages are particularly informative: they expose explicit work-in-progress
claims without requiring speculation from branch names.

## 5. Feature fit against the Cerberus model

| Feature | Cerberus `cmm_csem` | iGPS | iRC11 line | AxSL pattern |
|---|---|---|---|---|
| Non-atomic accesses and race UB | Yes | Yes | Yes | Model-specific |
| Release/acquire accesses | Yes | Yes | Yes | Not C11-specific |
| Relaxed accesses | Yes | No | Yes | Not C11-specific |
| Release/acquire fences | Yes | No | Yes | Not C11-specific |
| SC fences | Yes | No | Added in recent iRC11 | Could encode graph rule |
| SC atomic accesses | Yes | No | No | Could encode graph rule |
| Consume/dependencies | Yes | No | No | Pattern supports graph dependencies |
| RMW/CAS | Yes | RA fragment | Yes | Pattern supports atomic events |
| Locks and thread lifecycle | Yes | Core-calculus primitives only | Core-calculus primitives only | Must be designed |
| Allocation/deallocation | Yes | Limited | Yes; reclamation is central | Must be designed |
| C object/provenance semantics | Cerberus-specific | Abstract locations/values | Abstract locations/values | Must be designed |
| Authoritative model | Legacy C11 axiomatic | Restricted C11 RA+NA | RC11 operational | Arm-A axiomatic |
| Mechanization language | Lem; Isabelle portions; Lean generated | Rocq/Iris | Rocq/Iris | Rocq/Iris |

The table rules out a wholesale adoption strategy. It also suggests a sensible
first slice: RA+NA exercises thread creation, atomic/non-atomic ownership
transfer, histories, views, and race UB without immediately requiring relaxed
fence modalities or SC order.

## 6. Design choices for Cerberus-Lean

### Option A: restore the commitment-order semantics, then instantiate Iris

Use the relational core of `cmm_op.lem` as the physical transition system.
Port or restate its finite-execution equivalence theorem in Lean, initially for
a restricted submodel.

Advantages:

- it was designed specifically for the same C11 candidate-execution model;
- it already accounts for the fact that program order is not a valid global
  construction order;
- it integrates with Cerberus Core actions rather than an abstract lambda
  calculus; and
- it retains an executable counterpart for differential validation.

Risks:

- its historical integration is stale;
- symbolic read values and independent Core/commitment progress complicate
  standard weakest preconditions;
- completeness is stated for finite executions; and
- old Isabelle results may not line up exactly with current Lem source and will
  not automatically transfer to Lean.

### Option B: define an AxSL-style opax semantics over `cmm_csem`

Choose a complete candidate execution satisfying the Cerberus consistency
predicate, then check each Core thread against its events. Build a custom WP
whose state interpretation owns the graph and event-tied resources.

Advantages:

- preserves the axiomatic model directly;
- avoids maintaining a second, independently designed weak-memory semantics;
- makes existing event relations available to assertions; and
- may isolate the proof logic from the executable nondeterminism monad.

Risks:

- requires a bespoke WP and adequacy proof;
- must distinguish a mismatched candidate graph from true C UB;
- control-flow-dependent pre-executions, infinite runs, and allocation are
  harder than AxSL's idealized ISA setting; and
- it gives no executable concurrency implementation by itself.

### Option C: use ORC11/iRC11 as the physical semantics

Port a view-based RC11 machine and reuse the iRC11 proof architecture closely.

Advantages:

- best-developed proof rules and examples;
- direct path to objective invariants, reclamation, Compass, and OMO; and
- an operational shape naturally suited to Iris.

Risks:

- changes the language model from Cerberus's legacy C11 to RC11;
- leaves SC accesses and consume uncovered;
- requires a new connection from full Cerberus Core values, memory, and
  provenance to ORC11's abstract locations and messages; and
- correspondence results in the papers are not a mechanized equivalence to
  this Cerberus model.

This option is appropriate only after an explicit project decision that RC11,
rather than the existing model, is the intended semantic contract.

## 7. Recommended staged plan

### Stage 0: pin the contract

Write down, before implementing the logic:

- whether the target is the existing standard model, a named submodel, or
  RC11;
- whether correctness means safety of all finite executions, partial
  correctness, termination, or refinement of observable behaviors;
- whether data-race UB is represented as reachable fault, universal semantic
  collapse, or a verified race-freedom precondition; and
- which Core/C memory features are initially abstracted (byte overlap,
  provenance, allocation reuse, indeterminate values, mixed-size accesses).

The first target should be the finite RA+NA submodel with disjoint atomic and
non-atomic locations. This matches the clean iGPS correspondence envelope and
is already named in `cmm_csem.lem`.

### Stage 1: make the Lean concurrency seam truthful

Before Iris-specific work:

1. replace the `sorry` target representations for the selected submodel with
   relational definitions in `Prop`;
2. keep finite enumeration (`List`/`Finset` plus `CerbND`) separate from those
   definitions;
3. state observable behavior and race/UB classification explicitly;
4. add tiny litmus tests for SB, LB, MP, IRIW where applicable, RMW atomicity,
   release sequences, a non-atomic race, and allocation/deallocation; and
5. differentially compare Lean, the OCaml model, and the axiomatic predicate.

The goal is not initially to run arbitrary pthread programs. It is to obtain a
small semantic kernel that can support an adequacy theorem.

### Stage 2: run a two-route proof spike

For the same RA+NA litmus language, prototype:

- a minimal relational form of the commitment machine; and
- a minimal opax checker over a complete candidate graph.

For each, require:

- a precise step relation;
- a theorem connecting successful traces/checks to the axiomatic behavior;
- a race correspondence statement; and
- a plausible fork/thread rule and state interpretation.

Select on proof complexity and semantic coverage, not execution speed. The
losing prototype can remain a validation oracle if it is useful.

### Stage 3: build the weak-memory Iris base layer

The initial physical resources should cover:

- authoritative action histories and per-location modification order;
- fragments representing location ownership;
- per-thread observation/commitment state;
- event identities and freshness;
- race-detector ownership for non-atomic accesses; and
- allocation lifetime and deallocation rights.

Prove primitive rules for allocation, non-atomic load/store, release/acquire
load/store, one RMW/CAS form, fork, and join. The first adequacy theorem should
be a safety theorem for the restricted model and should state exactly how a
proved triple rules out Cerberus `Undefined` behavior.

### Stage 4: add a view-indexed surface logic

Borrow the iRC11/Cosmo structure:

- `vProp` as propositions monotone in a thread view (or the corresponding
  abstraction over commitment state);
- a seen-view assertion;
- fixed-view (`view-at`) assertions;
- an `Objective` class/predicate;
- objective invariants;
- non-atomic points-to for exclusive/fractional DRF access; and
- atomic history points-to plus per-location protocols.

Keep a low-level escape hatch. Weak-memory library implementations need to see
histories and views, while clients of verified locks should normally reason in
a memory-model-independent CSL fragment.

### Stage 5: broaden one axis at a time

Suggested order:

1. relaxed accesses;
2. release/acquire fences and their modalities;
3. cancellable invariants and deallocation;
4. locks as verified libraries or primitive events;
5. SC fences;
6. SC accesses and their global order; and
7. consume/dependency reasoning.

Each extension should add litmus tests and a model-correspondence theorem.
SC accesses and consume should not be hidden behind stronger rules: doing so
would silently verify a different language.

### Stage 6: only then add library specifications and automation

Use Compass-style logically atomic triples and OMO after the primitive layer is
stable. A good progression of examples is:

1. message passing;
2. spinlock with a classic CSL specification;
3. Treiber stack;
4. atomic reference counting with reclamation;
5. Michael–Scott queue; and
6. RCU or a lock-free traversal.

Port proof automation only after two or three manual examples reveal recurring
proof obligations. The OMO/Diaframe experience shows that automation can be
highly effective, but also that its hint database is a significant formal
development in its own right.

## 8. Concrete proof obligations that should not be skipped

1. **Semantic correspondence.** Every proof-facing execution must denote an
   allowed Cerberus candidate execution, and the intended completeness
   direction must be explicit.
2. **Race correspondence.** The operational/logical race condition must agree
   with the axiomatic data-race predicate for the selected fragment.
3. **Observational adequacy.** A verified program's return/I/O behavior must be
   related to `program_behaviours`, not only to termination of an internal
   thread machine.
4. **No false strengthening.** Rules must not accidentally assume global SC,
   multi-copy atomicity beyond the model, or that program order is a valid
   commitment order.
5. **Allocation coherence.** Logical ownership, Cerberus provenance, lifetime,
   and event-graph locations must agree across allocation, pointer operations,
   and deallocation.
6. **Finite/infinite boundary.** If adequacy covers only finite executions,
   state that limitation. Safety, divergence, fairness, and liveness are
   different results.
7. **Extraction boundary.** Executable model exploration can use finite data
   structures and decidable checks; foundational definitions and theorems
   should not depend on a fuel-based search being complete.

## 9. Suggested initial exit criterion

An honest first milestone is reached when all of the following hold for a
small RA+NA Core language:

- Lean represents pre-executions, witnesses, consistency, and observable
  behavior without concurrency `sorry` seams;
- at least one proof-facing transition/checking semantics is connected to the
  axiomatic model by a proved soundness theorem;
- data-race reachability/classification is connected to Cerberus UB;
- the Iris layer proves rules for fork, release store, acquire load,
  non-atomic load/store, and message passing;
- an adequacy theorem rules out UB and establishes the message-passing result;
  and
- the same litmus corpus is differentially checked against OCaml Cerberus.

That milestone would establish the difficult semantic bridge. Protocols,
reclamation, logical atomicity, and automation can then be added without
putting the trusted connection to Cerberus at risk.

## 10. Primary sources and artifacts

Core sources:

- Jung et al.,
  [Iris from the Ground Up](https://doi.org/10.1017/S0956796818000151).
- Nienhuis, Memarian, and Sewell,
  [An Operational Semantics for C/C++11 Concurrency](https://doi.org/10.1145/2983990.2983997).
- Kaiser et al.,
  [Strong Logic for Weak Memory](https://doi.org/10.4230/LIPIcs.ECOOP.2017.17)
  and its [project/artifact page](https://plv.mpi-sws.org/igps/).
- Dang et al.,
  [RustBelt Meets Relaxed Memory](https://doi.org/10.1145/3371102).
- Mével, Jourdan, and Pottier,
  [Cosmo](https://doi.org/10.1145/3408978).
- Mével and Jourdan,
  [Formal Verification of a Concurrent Bounded Queue in a Weak Memory Model](https://doi.org/10.1145/3473571).
- Dang et al.,
  [Compass](https://doi.org/10.1145/3519939.3523451) and its
  [artifact page](https://plv.mpi-sws.org/compass/).
- Park et al.,
  [A Proof Recipe for Linearizability in Relaxed Memory Separation Logic](https://doi.org/10.1145/3656384).
- Hammond et al.,
  [The AxSL Logic](https://doi.org/10.1145/3632863).
- Mansky and Du,
  [An Iris Instance for Verifying CompCert C Programs](https://doi.org/10.1145/3632848).
- Jung et al.,
  [Verifying General-Purpose RCU for Reclamation in Relaxed Memory Separation Logic](https://doi.org/10.1145/3729246).
- Park et al.,
  [Verifying Lock-Free Traversals in Relaxed Memory Separation Logic](https://doi.org/10.1145/3729248).

Useful indexes and syntheses:

- [Iris project publication index](https://iris-project.org/).
- Dang,
  [Scaling Up Relaxed Memory Verification with Separation Logics](https://iris-project.org/pdfs/2024-phd-haidang.pdf),
  2024 dissertation.
- Memarian,
  [The Cerberus C Semantics](https://doi.org/10.48456/tr-981), especially
  Chapter 10 on concurrency integration.

Current public pipeline and repositories, inspected 2026-08-19:

- [Iris Workshop 2026 program and slides](https://iris-project.org/workshop-2026/),
  especially Iris-Lean, ArchSem, multi-language program logics, and
  completeness.
- [Iris-Lean repository](https://github.com/leanprover-community/iris-lean)
  and [porting dashboard](https://leanprover-community.github.io/iris-lean/).
- Hostert et al.,
  [Completeness of Iris-Based Program Logics](https://icfp26.sigplan.org/details/icfp-2026-icfp-papers/10/Completeness-of-Iris-Based-Program-Logics),
  ICFP 2026, and Zhang et al.,
  [Completeness of Logical Atomicity for Linearizability](https://arxiv.org/abs/2607.11435),
  2026 preprint.
- [ArchSem](https://github.com/rems-project/archsem) and
  [AxSL](https://github.com/logsem/AxSL) repositories.
- KAIST's
  [OMO/iRC11 development](https://github.com/kaist-cp/relaxed-memory-separation-logic)
  and
  [safe-memory-reclamation development](https://github.com/kaist-cp/smr-verification).
- Şakar et al.,
  [Deductive Verification of Weak Memory Programs with View-based Protocols](https://arxiv.org/abs/2604.21084),
  2026 preprint, and the
  [VerCors repository](https://github.com/utwente-fmt/vercors).
- Margalit et al.,
  [Dynamic Robustness Verification Against Weak Memory](https://arxiv.org/abs/2504.15036),
  and the standalone [RC11 Coq development](https://github.com/qladevez/rc11).

Local reading copies of the core papers may be placed in
`lean_frontend/docs/papers/`. That directory is intentionally gitignored; this
note relies only on the canonical links above.
