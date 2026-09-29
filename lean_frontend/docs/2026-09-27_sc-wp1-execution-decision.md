# WP1 execution decision and S1 entry contract

> **Mainline copy — decision record only (landed with the SC plan, L0).**
> [USER 2026-09-29] ruled that WP1's code does not land: this record lands as
> documentation, and S1 starts fresh from mainline with a single stepper in
> Lem. The code, tests, probes and `sc-wp1-evidence/` files this record cites
> are **not on mainline**; they remain at `arc/sc-wp1` `186392a53` (read them
> with `git show 186392a53:<path>`). Superseded by the same rulings: §5 item 1's plan to change the inherited fork-result order and `Stack_cons2` refusal — S1 now mirrors upstream and refuses loudly. The text below is unchanged from
> `arc/sc-wp1` `186392a53` except that links to files not on mainline are shown as plain paths.
> Current state and the 2026-09-29 rulings:
> [SC-CONCURRENCY.md](../../SC-CONCURRENCY.md) and
> [the 2026-09-29 assessment record](2026-09-29_sc-assessment-and-rulings.md).

[USER, 2026-09-27] “Push forward to the end of WP1.” WP0 has landed on
main. [AGENT] This record closes the feasibility investigation with a
specific construction for S1–S4, explicit limits on the experiments, and
proof obligations attached to the changes that must discharge them. It is
not an announcement of SC support or a completed correspondence proof.
Validation status is recorded at the end; independent review and landing
remain distinct from completion of this investigation.

The governing plan is `SC-CONCURRENCY.md` on `arc/sc-concurrency`.
`SC-WP1.md` is this branch's entry point. The earlier September 25/26
records remain historical evidence, including failed approaches.

**September 28 review:** `1c7e52fad` on `review/sc-wp1-20260928` accepts
the decision and accepts the package/plan with fixes. The
[response](2026-09-28_sc-wp1-review-response.md) records those fixes and the
remaining M2 condition before shared-Lem factoring can land.

## 1. The construction we will build

**Use selected, bounded Core reductions over the existing concrete memory
model, with explicit pending primitive operations where a single Core
operation must yield. Track source causality separately from execution
order. Check memory conflicts incrementally, using summaries of retained
causal endpoints. Keep axiomatic graphs in the independent reference lane.**

This is a hybrid of direct request execution and justified resumable
operations. It is not a new evaluator alongside Core. Existing Core
context decomposition, pure evaluation, memory requests, call frames,
program startup and finalization supply the execution. S1 turns the
experimental boundary into an actual internal transition API. An explicit
scheduler budget counts Core/primitive/continuation transitions; generated
Lem call fuel is a separate parameter. Effect discovery is structural.
Nothing evaluates the unchosen alternatives to decide what is runnable.

For each memory access, three contracts remain separate:

* The concrete memory operation produces WP0's receipt, including its
  failure-time state. This is about the operation that actually happened.
* The logical source action supplies location identity, source sequencing,
  atomicity and initialization meaning. A byte interval alone cannot
  supply any of those facts.
* The transition API decides when another thread can run. An ND node is
  not automatically such a boundary, and an arbitrary helper is not
  automatically indivisible.

The scheduler never constructs an accumulated CMM execution or asks an
axiomatic consistency predicate whether it may advance. The reference
lane may enumerate small executions offline. No result of that lane is
an admission condition in the running machine.

### SeqRMW and calls

`SeqRMW` is an ordinary source operation with a load, update and store;
its two accesses are **not concurrency-atomic**. Preserve the identity of
that source operation while the primitive phases yield to other threads.
Own its C thread's continuation until the store/failure finishes. This
preserves the original Core action's indivisibility relative to local
context selection: siblings may be chosen before it or after it, and a
same-thread C call cannot enter between its read and write. Ownership
must not manufacture an `sb` or `hb` edge to an unsequenced sibling.

This choice has a semantic reason beyond avoiding stale callbacks. The
production Core reducer emits one `SeqRMWRequest2`; the sequential handler
executes its load/update/store as one selected source action. The proposed
instance introduces **interthread** suspension inside that action. It
does not introduce new same-thread reductions inside it. The existing
Core call stack similarly makes a selected C call indivisible relative
to its caller's unsequenced alternatives, while other threads can run.
See Memarian's [Cerberus thesis](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-981.pdf),
§§4.3 and 6.2, and `core_reduction.lem`'s `SeqRMW` and `Eccall` cases.

Save evaluated operands, the load value, update expression and local
continuation data. Evaluate the update against **current shared memory**.
Do not save the old updater's memory snapshot. Never reinstall an old
thread snapshot after allowing that same thread's siblings to advance.
A child finishing can also rewrite its parent's continuation: defer that
completion transition while the parent is owned. The child need not stop
performing its earlier work. Ownership ends on completion or failure.

The WP1 adapter demonstrates this with the production finish callback under
exclusive ownership. S1 should make the ownership/data boundary explicit
and count what the pending record retains. It must carry primitive ND
alternatives per owner, without preventing other threads from running.
WP1's adapter explicitly refuses those alternatives; it does not claim
that refusal is the final API. Helpers such as copies and filesystem
services get suspension points only with their first justified consumer
and their own effect/failure contract. They are not bundled into a generic
service rewrite in advance.

### Source order and retained state

Maintain **value-completion and all-effects frontiers** at the actual
source continuation. A positive action contributes to the value frontier;
a negative effect may remain pending after its value is available. Weak
sequencing transfers the value frontier. Strong completion transfers the
completed effects, including negative effects. Unsequenced operands share
the incoming frontier, not the preceding scheduler choice. Calls and
fork/join carry their respective local-order and synchronization endpoints.
Maintain source `sb` separately from synchronization `hb`.

The nine earlier all-choice Core experiments matter here: in particular,
`weak(strong(negative a, pure unit), b)` orders `a` before `b`. Filtering
original syntax for positive actions is wrong. The production negative
hoisting/exclusion protocol, not a single per-thread counter, is the
starting point for the S2 source simulation.

For retention, use an abstract interface that creates an endpoint from
explicit predecessor endpoints, copies a snapshot, compares two retained
endpoints, and drops roots. Roots include source frontiers, pending calls
and joins, atomic publications, and per-location access summaries. A
publication is an immutable snapshot: retiring its publisher must not
advance it to the parent's later state. Remove dominated same-location
reads only under the transitivity/first-conflict argument.

WP1 implements an **exact materialized matrix baseline**, storing induced
reachability among current roots. Extending it appends a row/column;
projecting it forgets unreferenced endpoints. It stores no event history,
retired-thread map or function closure representing the old relation.
The kernel proofs show extension/projection preserve comparisons even
through forgotten intermediate events. This establishes feasibility of
bounded retained causal information; it does not endorse a dense matrix
for large programs. With R roots it costs O(R²) Boolean cells and copying
work. S2 must choose and measure a sparse/vector implementation against
this exact interface and baseline, including publication-retirement cases.
Do not replace that requirement with a claim that “vector clocks scale.”

The scalar conflict monitor retains a last-write endpoint and a maximal
read antichain per logical location. If an older same-location read is
ordered before a retained newer read, transitivity proves removing the
older read preserves existence of a future conflict. The general width
bound must include live source alternatives and retained publications,
not just the number of C threads. Repeated source splitting is as relevant
as repeated thread creation. Counter bit widths may grow logarithmically;
fixed coordinate/reference counts are not a constant-total-bytes claim.

## 2. Evidence and what it establishes

The new definitions are isolated in `test/Unit/SCWP1Decision.lean`,
`SCWP1Summary*.lean`, `SCWP1SourceProofs.lean` and `SCWP1Contracts.lean`.
They are instruments, not a public driver or a standing acceptance gate.
The actual shared Core/memory definitions remain underneath the adapter.
The adapter currently uses empty enum/tag readers and deterministic
primitive operations; these are explicit experiment-domain restrictions,
not proposed restrictions on the SC product.

Run `scripts/test_sc_wp1_decision.py` in the scoped environment after the
normal semantics build. It records commands, outputs, source hashes and
loaded module hashes under `.tmp/sc-wp1/decision`. Committed evidence is
under `docs/sc-wp1-evidence/decision-*`. Earlier paired OCaml/Lean stepping,
real C lowering and continuation counterexamples are rerun separately.
The new adapter experiments are Lean-only; they do not add a second claim
of independently implemented dual-engine concurrency.

| WP1 obligation | Concrete evidence | Limit / responsible next slice |
|---|---|---|
| Actual bounded Core, passive choice discovery, lifecycle | Earlier shared-Lem stepper, paired Core loops, seven actual C fixtures, exact kernel step/run/budget laws, plus whole-configuration run composition and passive discovery for the pending-operation adapter | S1 supplies the supported internal API, including per-owner ND continuations and total unsupported-case handling. |
| SeqRMW separation/current state/local alternatives | Separate read/update/write; intervening other-thread write; old/new forwarding; sibling exactly once; actual function-pointer metadata publication seen by the update; failed update retains only the completed read | Candidate source operation owns its C continuation. Primitive alternatives, general readers/types and lifetime-failure families belong to S1/S4. Original unsafe callback counterexamples remain reproducible. |
| C calls and fork/join | Complete Core schedules: same-thread call `ab` and sibling `c` give `abc,cab`; separate threads additionally give `acb`. SeqRMW/call gives only `rrab,abrr`. Positional fork results and churn inside a real modern call frame are checked | Candidate repairs inherited reversed IDs and missing modern-stack wait substitution. S1 must implement/audit those fixes in shared Lem and initialize actual child runtime/errno; the candidate still inherits the null errno placeholder. |
| Independent source relations | All-choice enumeration of nine finite positive/negative, weak/strong/unseq Core expressions against independently specified orders; C-call indivisibility checks above | Does not establish every reachable Core annotation's relation to logical C actions. S2 owns that simulation, including joins and atomic-call lowering. |
| First conflict / no scheduler edges | Two same-location writes in actual unseq, in either order: observer finds conflict after the second write, with errno+2 receipts and only 3 paid steps, before choosing the looping operand | This is a source-shaped bounded observer, not the general S2 monitor. The original reducer still delays its check until unseq completion. |
| Publication and read-dependent control | Actual Core par/store/load/conditional gives exactly `d42,p1,a1,c42`, `d42,a0,p1`, `a0,d42,p1`. Independent small reference derives these from `d<p` and the read value. Dropping the acquire edge exposes the first data conflict at `c`; inventing scheduler order incorrectly masks it | Primitive SC load/store execution plus a separate observer; no full atomics implementation or general coverage theorem. |
| Substantive source link | `unseq_pairwise`: for any number of completed Core operands, arbitrary values, footprints and exclusions, the production measured reduction succeeds iff no cross-operand pair conflicts. `hoisting_excludes_prior`: actual `add_exclusion` prevents a hoisted negative action racing with the selected path's prior annotations | General kernel lemmas about production definitions, not single test executions. The relation of all reachable annotations to source `sb` is still S2's obligation. |
| Summary invariant | `extend_correct`, `project_correct`, transitivity preservation and dominated-read conflict preservation; materialized executable named-root adapter | Exact retained-root baseline, not a proof of the complete monitor, source instrumentation, or sparse representation. |
| Repeated split/join and bounded-live-thread churn | 16/1024/8192 actual Core rounds; 8192 rounds produce 16384 accesses. Six roots, 36 matrix cells, six root references, zero environment bindings and three allocations at each measured boundary. Fork case creates 16384 children, peak three live threads, one retained parent | Counts are actual fields, not RSS or a general complexity theorem. Fixture roles identify the two actual source operands. This is not a general automatic source-frontier extractor. |
| Reference/domain nonvacuity | Pinned `cmm_csem` accepts a three-action initialized SC scalar witness; wrong read-from value, reversed SC order and missing same-thread atomic order are rejected; two racing ordinary writes are consistent but reference-undefined | Small finite graph diagnostic. No reliance on the executable program-level `true` stubs or import of `bigthm`; reference-port/instance audit remains required. |

The retention instrument streams diagnostic receipts and ordinary driver
trace output after each step. It does **not** prune semantic environments,
allocations or call frames. Thus it separates new causal overhead from the
inherited trace's intentionally retained output. The September 26 negative
hoisting experiment still shows growth of temporary environment bindings.
A production trace policy and sound reclamation of those bindings are
**mandatory S1 scale work**, before claiming a scalable whole machine.
Use lexical support of the current frame and reachable continuations;
do not erase by a numeric symbol cutoff or assume a loop has no free
variables. Reproduce the negative case, preserve live values across
backedges/calls, and establish environment-agreement lemmas. The WP1
matrix and positive fixtures do not discharge this obligation.
The candidate also retains the inherited null child errno placeholder.
Repeat churn with actual child runtime allocations and their justified
lifetime/reclamation policy in S1; the measured three-allocation fixture
does not establish the cost of those production resources.

## 3. WP-C: precise reference boundary and proof work

The reference is the pinned `frontend/concurrency/cmm_csem.lem`, not the
failed prototype's verdicts. For the initial scalar theorem:

* finite executions over stable, disjoint scalar logical locations;
* NA and seq_cst loads/stores, and subsequently seq_cst RMW;
* well-formed action identities and location kinds, actual Core `sb`,
  structured fork/join `asw`, and read-from induced by the concrete reads;
* initialization of each atomic location before all its subsequent
  accesses under `sb ∪ asw`, with no racing/repeated initialization;
* same-thread atomic accesses satisfy the reference's
  `indeterminate_sequencing` condition, including their order relative to
  other same-thread evaluations;
* defined object-model execution and a race-free prefix for the defined
  outcome theorem. There is **no single-writer restriction**.

These are initial theorem restrictions, not exclusions from the MVP.
The runtime must also support ordinary objects/lifetimes, full SC atomic
operations, fences and structured concurrency under the master plan.

The exact scalar predicate is `SC_memory_model`: its consistency tree is
`sc_accesses_consistent_execution`, its derived relations are
`release_acquire_relations`, and its undefinedness predicate family is
`locks_only_undefined_behaviour`. Relevant leaves include
`well_formed_threads`, `well_formed_rf`, `consistent_mo`,
`sc_accesses_consistent_sc`, `consistent_hb`, `det_read`,
`consistent_non_atomic_rf`, `consistent_atomic_rf`, `coherent_memory_use`,
`rmw_atomicity` and `sc_accesses_sc_reads_restricted`. The schema module
names these actual trees rather than inventing a weaker “SC” predicate.
Consistency alone is not definedness: `ReferenceDefinedSC` additionally
requires `each_empty SC_memory_model.undefined X`. The two-write racy
control demonstrates this distinction. Complete defined-outcome coverage
uses that stronger predicate; first-conflict prefixes and program-level UB
lifting have separate obligations.

`SC_condition` excludes fences and allocation/deallocation. For fences,
S3 must use the seq_cst-only restriction of `sc_fenced_memory_model`,
including `sc_fenced_sc_fences_heeded` and
`release_acquire_fenced_relations`, and prove its agreement with the
no-fence fragment. Do not claim `SC_condition` already covers them or
assume SC fences can simply be erased. S4 owns the conservative object /
lifetime composition; omitting allocation nodes from the scalar projection
does not remove lifetime conflicts from the runtime.

`tot_memory_model` is a useful intermediate: its total order extends
`sb/asw`, with reads from the latest eligible write. It is not simply the
SC model with a different name. Upstream `bigthm` is a program-level
result under `opsem_assumptions` and `tot_condition`, including
receptiveness and a global bound on executions. The executable versions
of several program-level predicates are stubs. A finite-prefix runner
does not establish those assumptions, and the total model's adjacent-race
undefinedness rule is not automatically an online `hb` race monitor.

`SCWP1Contracts.lean` typechecks the execution-fidelity, scalar-soundness,
coverage and first-race **statement schemas** over the actual candidate
transition function and pinned reference types. Initial-state validity, projection, independent
Core-path feasibility, generated-fuel adequacy, observation equivalence and race interpretation
are explicitly named inputs to those schemas, not supplied implementations
or assumed theorems. Their concrete instantiation is a deliverable below;
an arbitrary/vacuous choice of one is not acceptable evidence. Coverage
requires a completed operational run and source-justified adequacy of the
generated-call fuel, including closures captured at initialization. S1
must establish existence of adequate resources for each supported finite
source path; defining adequacy as runtime success would be circular. The
nonempty graph and actual read-dependent Core witnesses show the proposed
scalar domain has content. The local source lemmas above supply the
substantive production-linked proof at WP1 entry; schemas alone do not.

| Obligation | Responsible definitions/slice | Required result |
|---|---|---|
| Execution fidelity / projection | S1 selected Core step, pending requests, receipts and lifecycle; S2 logical action/source instrumentation | Every logical event corresponds to an actual completed primitive/atomic action or explicit synchronization event; exact prefix and state transport; projection does not discard inconvenient events. |
| Source simulation | S2 Core contexts, negative hoisting, weak/strong completion, call frames, fork/join frontiers | `sb/asw` agree with the Core source relation in both directions. No scheduler-order edge; no lost strong completion or old publication. Extend the established local unseq/exclusion lemmas to a reachable-state invariant. |
| Summary / first race | S2 root summaries, per-location antichains, conflict classes | Comparisons equal the source/synchronization closure; sound retirement and antichain deletion; report exactly the first conflicting completed access. Source-shaped observers are replaced by a general actual consumer. |
| Scalar soundness | S1/S2 current-memory reads, S3 indivisible atomic families | Build rf/mo/sc witnesses from execution, prove the actual named consistency leaves for defined scalar runs. Atomic initialization and indeterminate sequencing are proved by lowering/lifecycle, not merely left as assumed runtime facts. |
| Coverage and receptiveness | S1 actual read/update/branch transitions plus S2 source choices | From a complete, reference-defined feasible Core path with source-justified adequate resources, obtain a completed operational schedule with the same observations/rf (up to fresh-name/administrative equivalence), including changed read values changing control flow. Establish the needed path-replay/receptiveness property directly; do not instantiate a `true` stub. |
| Prefixes / UB | S1 distinct outcomes, S2 first conflict, S4 memory failures | Prefix preservation; no exhausted/unsupported execution masquerades as defined; program-level UB lifting agrees with the chosen reference definition, including other possible schedules. |
| Object conservativity | S4 concrete locations, bytes, provenance/lifetime, helpers and shared services | Scalar projection composes with ordinary object behavior; partial helper effects and memory faults retain their exact state/receipts. Byte overlap alone is insufficient. |

**Hardest remaining obligation:** coverage through actual read-dependent
Core control flow, including source-choice/call intervals and the full
source-summary simulation. An SC-consistent fixed graph having a total
extension is insufficient. The publication fixture exercises this issue
but does not prove receptiveness. If the S1/S2 replay construction fails,
reopen the design before expanding S3's atomic families. S5 cannot waive
this proof debt.

## 4. Alternatives and why this decision differs from the failed effort

| Alternative | Assessment |
|---|---|
| Unchanged eager driver / existing ND boundaries | Rejected: deterministic singleton Core loops consume arbitrarily much work without yielding; eagerly interpreting alternatives executes unchosen effects/faults. |
| Save current request callbacks and resume anywhere | Rejected by actual sibling-resurrection and stale-memory counterexamples. |
| Bare positive-load/negative-store Core expansion | Useful comparison, but it changes local scheduling and needs a C-call indivisibility mechanism. WP1's tested byte expansion did not supply that mechanism. Do not adopt it as a general lowering. |
| Selected Core requests plus owned pending primitive | Chosen: preserves existing local Core action/call structure, allows interthread primitive suspension, retains lifecycle and concrete memory, and has explicit ownership/current-state obligations. |
| General resumable helper framework first | Defer: build the smallest operation-specific suspension with a real consumer, then generalize only if the contracts justify it. |
| Historical commitments / symbolic whole-execution construction | Retain as a reference/literature comparison. Not needed for current-memory SC execution; brings speculative values, constraint solving and coverage obligations we should not import for this MVP. |
| Accumulated graph checks in the running scheduler | Rejected. No event-history consistency search on the operational path. |

No donor scheduler, monitor, single-writer restriction, race suppression,
or prior branch's assertion of completion has been adopted. The new
candidate/proofs are written against the current production definitions.
The old branch remains a quarry for independently justified later pieces.

## 5. Next landing boundaries and anti-drift rules

WP1 is a decision/evidence package. Its default-driver factoring and
diagnostic seeds need independent landing review, including M2's ruling
reconciliation or experimental-module isolation; this branch does not
enable a user-facing concurrency mode. Before treating its experiments as
production, cut S1 from the current mainline with only necessary accepted
prerequisites. Prefer these early auditable slices:

1. Investigate positional fork-result order and upstream's explicit
   `subst_wait_stack ==> Stack_cons2` refusal. Both are inherited behaviors,
   reachable through the non-ISO C par-block extension. Before changing the
   shared model, prepare positional/nested/call-frame and C-par-block
   observability evidence, a tray draft and proposed `shared-model-fix`
   register row, then obtain explicit [USER] adjudication of the deviation.
   The WP1 Lean adapters are experiments, not a ruling or a reason to ship
   a permanent Lean-only semantics difference.
2. The actual selected-step/lifecycle API, with per-owner pending SeqRMW,
   explicit ND handling, actual child runtime/errno initialization,
   unsupported/failure outcomes, and step/run/resource laws. Include structural discovery and the first concrete consumer.
3. Production streaming trace policy plus lexical temporary-environment
   reclamation, with the negative-hoisting leak as a failing control and
   proof of preservation of live bindings. This must accompany S1's scale
   acceptance; it is not a hidden later performance cleanup.
4. S2 source-frontier/first-race consumer and exact retirement contracts,
   followed by the V1 real-C publication/fork/join/bytes/budget lane. Keep
   reference/projection and coverage work beside these changes.

Combine items only if their smallest useful contracts cannot be audited
separately. No broad S3 extraction before S1/S2 and V1 demonstrate the
chosen execution/source construction. No public SC switch before S5.
No Iris integration in this MVP. No merge or push is performed by this
record; the repository's exact-head audit/landing policy still applies.

Reopen the design if owning a pending operation removes a required defined
source behavior, a helper needs hidden whole-memory snapshots, a source
summary adds scheduler order, a publication advances during retirement,
the reference comparison relies on a stub, or projection/coverage cannot
be stated independently of the runtime verdict. Do not “fix” such a failure
by filtering the domain after the fact or raising fuel.

## 6. Base and validation

WP0 landed on `mdd/cerberus-lean` at `5ecc0aa33`. WP1's three prior commits
were rebased onto that actual landing without conflicts:

| Historical WP1 commit | Rebased identity |
|---|---|
| `0748b0a3b` | `73c1419ae` |
| `88904d8cf` | `5470b9c75` |
| `171e06df5` | `b52f9e660` |

The landing delta includes the WP0 consumer/review documentation, stronger
receipt-test process caps and row-1 coverage, public-readiness/pin checks,
and a memory-store comment. It does not change the prior Core experiment's
runtime. Both generated trees were re-derived on this base. Historical
September 26 reports keep their original identities; they are not relabelled
as validation of this rebased candidate.

Self-review separated consistency from reference-definedness in the coverage
schema and made initialization, fuel adequacy and completed execution
explicit. The first full run was deliberately interrupted before changing
the schemas; its incomplete report is retained, not counted as a pass.
The corrected reference probe includes consistent-but-racy ordinary writes.

**WP1 is complete as a decision/evidence package, ready for independent
review.** The production SC implementation and general correspondence
obligations above remain S1–S4 work. The validation record is
`decision-validation.json` (on `arc/sc-wp1`);
focused commands, transcripts and hashes are the adjacent `decision-*` files.

| Check | Result and limit |
|---|---|
| Decision experiments | Passed: pending operations/calls, actual read-dependent publication, first-conflict prefix, nine finite source-order sets, split/join and thread churn, finite reference controls. |
| Kernel local laws | Ten printed axiom cones contain only standard Lean axioms; two are axiom-free. These are the stated local laws, not general SC correspondence. |
| Earlier paired and C-source probes | Both scripts passed again on the landed-WP0 base: paired OCaml/Lean stepping and counterexamples, and seven actual C fixtures. Their exact commands/resources are in `decision-paired.json` and `decision-source.json`. |
| Full A+B ladder | **40/40 commands passed**, complete selection, source unchanged, no artifact issues. Both generated trees were re-derived; the run used `DUNE_CACHE=disabled`, panic-aborting Lean and a 32G build cap. |
| Three-engine report | 872 cases, gating pristine/fork result passed: 835 semantic agreements, 28 matching failures, 7 reviewed differences, 2 interface agreements. Lean is a separate report-only column: 830 agreements, 28 differences, 12 both-undecodable, 2 not applicable. The 40 Lean/fork difference IDs match the historical record exactly; they are not counted as agreement. |
| Identity checks | All full-lane log hashes verified. All focused source hashes and the 12 recorded loaded-module hashes still match after the full run. The full and three-engine runs have identical before/after source identities. |

The frozen validation identity is parent `b52f9e6602e0d20fb2f0f3d522aa24e662bc290b`
plus staged diff SHA-256
`84586e21968dbeb9d50283c4eacbae147dde1c110681fa8a72cc42625cbd9fc1`.
The completion edits after that freeze are documentation and evidence only.
Runtime, test, proof and active manifest hashes in the record identify the
validated code in the completion commit. No baseline, normalization rule or
release gate was weakened. This evidence protects the existing semantics and
supports the bounded experiments; it does not enable public SC support.
