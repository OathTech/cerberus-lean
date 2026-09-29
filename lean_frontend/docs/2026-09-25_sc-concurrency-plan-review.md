# SC concurrency plan review: make the next build finish

Date: 2026-09-25. Review of `arc/sc-concurrency` at
`b34bcd7bd10285ca595f8e601ca2fbf191f75dfe`, against mainline
`e9f9d049ffaaf005c392495b0f6418d21f4df29f`.

[USER] Review the renewed concurrency effort critically and recommend changes
to its plan or scope that make this build succeed. Subsequently: put the review
on a separate branch for the implementing agent. This record is on
`review/sc-concurrency-plan-20260925`. Its recommendations are [AGENT] review
judgments, **not adopted scope changes or permission to merge**. The governing
[master plan](../../SC-CONCURRENCY.md) remains unchanged by this review.

## Verdict

**Revise the delivery plan before broad implementation.** The architectural
direction is substantially better than the failed prototype, but the first
usable release still depends on several unresolved research and integration
tasks. Smaller commits will help auditing; they will not by themselves make
that release finish.

Keep concrete memory authoritative, remove graph admission from execution,
preserve ordinary byte/member behavior, validate independently of the paired
backends, and measure selected execution early. Do not revive the donor's
universal scalar projection. These are the right corrections.

The main remaining risk is building another large executor before establishing
that its source-order summaries, actual step boundary, and promised reference
claims compose. I recommend a closed WP0, an executable feasibility gate, and
a separately named first supported profile before the full §2 completion
claim. The priorities below concern delivery and semantic risk; this branch
does not introduce an executable concurrency regression because it changes no
production implementation.

## R1 — P1: distinguish a first supported release from full research completion

**Plan locations:** master plan lines 79–109 and 118–126; technical design
[§6](2026-09-24_sc-concurrency-design.md#6-correspondence-what-must-actually-be-established).

The completion bar combines full SC atomic coverage, concrete-object and
helper composition, an exact partial-source-order monitor, actual Core scalar
soundness **and coverage**, first-race/program-UB correspondence, and an external
reasoning example. Public enablement waits for all of them at S5. The plan
allows earlier internal landings, which is useful, but contains no earlier
supported product contract. An unchecked scheduler is not that contract.

In particular, scalar coverage is a substantial semantics proof, not the
reverse direction of a recorder-erasure lemma. It must establish that the
actual Core computation can realize reference executions, including their
read-dependent control flow. Upstream `cmm_csem.lem:1120–1180` makes
`receptiveness` and `produce_well_formed_threads` executable constants returning
true; `bigthm` at line 2855 is a HOL/Isabelle/TeX theorem declaration, not a
Lean proof about this driver. The technical design correctly warns about this,
but gives the whole obligation one row of delivery planning.

Initialization also constrains which equivalence claim is even true. The
counterexample and restricted theorem in [Batty et al., §4](https://www.cl.cam.ac.uk/~pes20/cppppc/popl079-batty.pdf)
show why NA/SC orders alone do not justify transferring every race-freedom
claim from interleaving execution to C/C++ axiomatic execution. This is an
early model-domain decision. It cannot be discharged just by implementing
`atomic_init` later in S3.

**Recommended change:** retain full §2 completion as the eventual target, and
add an explicitly smaller first release. A concrete proposal is:

| First supported profile | Later named extensions |
|---|---|
| Real C through initialization, structured fork/join, main and finalization; actual selected-thread steps and observations | Pthreads and other previously excluded features remain separate |
| NA operations on existing concrete objects, including ordered bytes, members, aggregate copies and distinct scalar locations | More difficult overlapping/unordered representation cases require their own explicit boundary and evidence |
| SC integer loads/stores and publication; atomics initialized before concurrent use, with the supported initialization forms checked | RMW families, strong/weak CAS, fences, broader atomic representations and initialization forms |
| Exact sequencing/race checking on an explicitly defined accepted Core fragment; source membership must be checkable without assuming the program race-free | Extend the fragment only with an ordering argument; ordinary read-only expressions such as `x+y` must already work |
| Selected execution, deterministic replay and tiny complete enumeration; canonical termination at first UB or unsupported operation | Post-UB diagnostic continuation, general search improvements and more extensive runtime services |
| Existing ordered helper behavior before fork and after join; initially reject helper/service calls while multiple threads are live | Admit concurrent helper/service families individually after suspension and synchronization are justified |

This proposal deliberately reduces concurrent operation coverage, not the
underlying object memory to scalars. A deferred operation must produce an
explicit unsupported observation through its actual entry path; it must not
fall through to sequential handling, silently gain atomicity, or become C UB.
Preprocessing restrictions need enforcement before preprocessing loses the
information. A test-only Core operation is not C surface support.

A conservative candidate source profile permits sequential composition, loops,
conditionals, structured fork/join and unsequenced read-only subexpressions,
but initially rejects unsequenced groups containing writes, synchronization
or effectful calls. WP1 must express this over the real Core constructors and
validate its C lowering; this paragraph is not a proved grammar. If the general
summary experiment succeeds, retain the wider source fragment instead. Either
way, choose the fragment before expanding the implementation, and preserve
read-only member expressions such as `p.a + p.b`.

Specify the proof deliverables for that release individually: actual
step/runner correspondence, observer erasure, monitor invariant and first-race
preservation, a small substantive consumer property, and a precise account of
which reference claims have proofs versus bounded evidence. General Core-to-
axiomatic completeness can be a separate milestone only with an explicit
revision of the current release policy. Do not relabel finite comparison as
equivalence or claim that the original full completion bar has passed.

If the user keeps the entire existing §2 bar as the first public release,
budget and track the correspondence work as its own critical work package.
Obtain a checked theorem statement and a credible decomposition during WP1;
do not let unproved source hypotheses disappear into a final audit checklist.

## R2 — P1: make the causal-summary design a go/no-go experiment

**Plan locations:** master plan lines 121–123; technical design lines 205–227
and 283–303.

The plan recognizes that one clock per C thread is insufficient, but the
replacement remains a proposal: clocks for semantic strands and split/join
frontiers. This is the central unresolved algorithm, not routine S2 work.
Source sequencing, interthread synchronization, and reclamation must agree.
Fresh coordinates for every dynamic unsequenced branch can retain history even
with a fixed thread count and fixed active expression width.

[FastTrack §2.1](https://users.soe.ucsc.edu/~cormac/papers/pldi09.pdf) orders
same-thread operations by their order in the trace. Its proof therefore does
not establish this Core adaptation. The paper also relies on race-free
prefixes for important summarization arguments. Keeping a post-UB diagnostic
executor would need a distinct guarantee; choose stop-at-first-UB for the
first release.

The master plan already asks for a minimal experiment and independent relation
comparison. Make its required artifact and stopping rule concrete:

1. Define the source relation independently for a bounded Core fragment with
   `Eunseq`, `Ewseq`, `Esseq`, calls, SC publication and fork/join. Attach the
   candidate summaries to actual Core continuations. A second monitor fed the
   same possibly wrong source edges is not an independent check of those edges.
2. Compare reference relations and first-conflict observations for nested
   examples, including a read/side-effect distinction, two indeterminately
   sequenced calls, and publication from one unsequenced branch while a sibling
   remains pending. Check both missing-order and invented-order faults.
3. State and establish a nontrivial summary invariant: which past effects the
   frontier represents, what may be discarded, and why the next first-race
   decision is preserved. Pin the connection to the actual transition code.
4. Repeat a fixed-width unsequenced expression in a loop. Also repeat
   fork/join with a bounded simultaneous thread count. Count retained clock
   coordinates and retired-strand references, not only current frontier nodes.
   Either demonstrate reclamation or state the retained-history dimension and
   reduce the proposed bound. The existing caveat about thread reclamation
   should become an explicit acceptance case.

Do this after the minimal WP0 landing and before broad S1/S3 extraction. If it
fails, revise the representation or propose a narrower, precisely recognized
source fragment. Do not import a per-thread-clock shortcut or add features
while the basic monitor contract remains unresolved. No conclusion here says
the proposed frontier scheme is impossible; the missing evidence is exactly
what the experiment must supply.

## R3 — P1: implement an actual bounded step before wrapping the runner

**Plan locations:** master plan lines 122 and 126; technical design lines
404–429; quarry table's whole-program continuation API row.

An ND-node observation is not automatically one operational thread step.
On current mainline, `nondeterminism.lem:62–76` immediately evaluates the bound
continuation when the first computation returns `NDactive`. At lines 190–200,
`ND.pick [x]` returns `NDactive x`, without a scheduling node. Thus a chain of
singleton choices and successful binds can run arbitrarily many deterministic
operations before the next ND node is exposed. Generated Lean fuel can stop
that computation, but that is not the same as a caller's step budget.

The donor repeats this trap: at its pinned implementation,
`driver.lem:2067–2083` loops from `sc_step` back into `sc_driver_machine`, and
`sc_program_node` at line 2740 merely invokes the stored ND computation. It
preserves an outer continuation, which is valuable, but this observation alone
does not make a bounded scheduler or an Iris thread step. A wrapped whole-
program ND tree can look useful in branch-heavy tests while its deterministic
path runs until termination or semantic fuel exhaustion.

Current request discovery is also not reusable as a passive enumeration:
`driver.lem:1279–1282` calls `drive_nonmemory_steps_aux2`, while
`can_advance` at lines 914–943 and `advance_step` at lines 980–985 allow actual
memory operations during that advance. The plan forbids unchosen-thread
effects; the implementation gate needs to demonstrate it.

**Recommended change:** put the real transition API, resource accounting and
observation projection in the first executable S1 slice. Keep S5 for public
stabilization and the final consumer demonstration. Choose an explicit small
step or an explicit yield after each declared boundary, including the case of
one enabled thread. Do not prescribe a new ND constructor until WP1 establishes
that it is necessary. Preserve initialization/finalization and saved services
in the same machine used by execution.

Required early witnesses:

- One thread with a deterministic loop and one enabled choice returns control
  at the declared boundary. A tiny exploration budget produces an incomplete
  observation promptly, rather than relying on a subprocess timeout.
- Repeated stepping and one bounded run agree on events, state, remaining
  resources and terminal observations. Resuming cannot replenish semantic
  fuel. Distinguish fuel internal to generated functions from scheduler steps.
- Enumerating alternatives changes no memory, output, supplies or services;
  an unchosen thread's effect/fault is not executed during discovery.
- Ordinary `SeqRMW` does not accidentally become an atomic update. Mainline currently
  performs its load and store inside one handler (`driver.lem:714–724`).
- The same entry path reports completion, UB, unsupported behavior, blocked
  execution and resource exhaustion. Returning an empty list is not a
  substitute for any of them.

Before admitting the first concurrent helper, extend this gate with a paused
helper that resumes against another thread's changed/deallocated shared state.
If such helpers are deferred under R1, do not make a general saved-service
framework a prerequisite for the first executable slice.

## R4 — P1: give WP0 a finite exit and keep receipts below semantic actions

**Plan locations:** master plan lines 120 and 220; technical design lines
319–359.

WP0 correctly makes F3/F4 conditional and acknowledges that `liftMem` already
preserves returned memory state. However, WP1 depends on completion of WP0,
whose exit includes the undefined phrase “agreed necessary primitive coverage.”
F2 spans loads/stores, allocation/deallocation, helpers and metadata. This can
become another effect-inventory project before the important execution
decisions are tested. A small landing does not close that dependency unless
the plan says so.

There is also an interface trap. The current concrete `footprint` is just
access kind, address and size (`memory/concrete/impl_mem.ml:526–537`). It cannot
by itself establish C memory-location identity or source sequencing. A physical
memory receipt can also be part of a larger logical operation. It must not
quietly become one C action, one scheduler step, or one atomic event.

**Recommended change:** close initial WP0 after one load/store observation
slice with its actual diagnostic consumer. Preserve load results, same-value
writes, returned failure state, ND alternatives, and a completed-operation
prefix followed by failure. Reuse existing `ND.liftND` wherever sufficient.
Require observation-disabled erasure and bounded/drainable storage. Identify
which returned node/state each receipt describes; do not retain a sequence of
whole historical memory snapshots as the default representation.

Then proceed to WP1. Schedule helper/lifetime/metadata receipt extensions with
the first execution feature that consumes them. List them as later coverage,
not uncompleted prerequisites to the strategy decision. This preserves the
user's foundations-before-strategy order.

Write down three separate contracts: primitive receipts, logical C actions,
and scheduler boundaries. In particular, receipts drained after an entire
helper finishes do not retrospectively provide interleavings or the state at
the first internal race. The helper composition slice must connect observation
and suspension points before it claims those properties. Reject that claim
if it is supported only by a final-state receipt-replay test.

## R5 — P2: separate concurrency overhead from inherited history costs

**Plan locations:** master plan line 97; technical design lines 283–303.

The plan's selected-run scale criterion is valuable. As written, its broad
bound over actual memory/driver work can accidentally make a sequential
memory optimization project a prerequisite for SC:

- `driver_state.trace` exists already (`driver.lem:73`), and sequential
  handlers unconditionally prepend events, for example lines 697 and 710.
  Disabling a new SC journal would not disable this history if those handlers
  are reused. Avoid calling that configuration fully tracing-off without
  inspecting all retained roots.
- Concrete memory stores `dead_allocations` as a list. `kill` appends a dead
  identity at `impl_mem.ml:1548`, and `is_dead` performs `List.mem` at line 670.
  Load/lifetime paths use this check. The Lean seam has the same list and
  membership operations. Repeated creation and destruction therefore retains
  history with a bounded number of simultaneously live objects. This is source
  evidence of a cost dimension, not a new SC regression.

I ran the existing mainline native binary on selected sequential loops that
reuse one local object versus recreate one per iteration. Both returned 1 for
all four sizes. The [raw diagnostic record](2026-09-25_sc-plan-review-cost-evidence.json)
contains source, commands, output, status, limits and binary hash. These are
single samples of an existing binary, not fresh-build certification or an
asymptotic fit; source inspection establishes the history-retention concern.

| Iterations | Reuse one local, seconds | Recreate a local, seconds |
|---|---:|---:|
| 1,000 | 0.1259 | 0.1292 |
| 2,000 | 0.2169 | 0.2541 |
| 4,000 | 0.4229 | 0.5767 |
| 8,000 | 0.7877 | 1.5390 |

**Recommended change:** require the SC scheduler/monitor/receipt overhead to
be independent of discarded execution history at fixed relevant dimensions.
Also report actual end-to-end time and RSS, against the sequential control,
with a separate accounting of inherited trace, memory lifetime state, output,
live closures and monitor summaries. Make any necessary sequential repair an
explicit, separately validated dependency. Do not silently abandon the
selected-run performance requirement, or promise whole-machine live-state
bounds that the reused memory does not satisfy.

Use fixed-object loops, object-lifetime churn, repeated unsequenced split/join,
and repeated thread creation as separate probes. Fixed-object loops alone
cannot reveal the other retained-history dimensions.

## Proposed work order for the implementing agent

This is a recommendation for a visible plan revision, not a replacement plan
installed by this review. Retain the existing audit/merge and two-repo pin
rules. Do not convert these rows into another status ledger.

| Order | Concrete output | Stop or revise when |
|---|---|---|
| 1. Close the planning decisions | Record responses to R1–R5 in the master plan; name the first supported profile, exact WP0 exit and proof claims | The first useful release still requires unspecified general proofs or runtime coverage |
| 2. Minimal WP0 / L1 | Paired passive load/store receipts plus only necessary transport, with erasure, failure and same-value controls | The slice grows a scheduler, full helper inventory or generic representation model |
| 3. WP1 feasibility experiment | Actual Core sequencing cases, compact-summary invariant, explicit step/yield and resource experiment, small independent reference comparison | The monitor needs all past predecessors, deterministic stepping does not yield, or the chosen reference claim fails |
| 4. First vertical implementation | Real C publication and fork/join through the actual program API, monitor and observation codec on both engines; ordered-byte/member controls in the same lane | Only synthetic events work, initialization is bypassed, or unchosen threads cause effects |
| 5. First supported profile | Complete tiny outcome sets, reproducible selected/prefix checks, relevant production mutations, source/API laws and selected-run scale; applicable release gates | Refusal or timeout is being counted as a valid result; restrictions cannot be enforced |
| 6. Extensions and full completion | Independently accepted atomic families, helper/services, lifetime extensions and the remaining exact correspondence claims | Feature expansion outruns the established operation/monitor contract |

Choose one end-to-end acceptance lane in order 4 and keep it running through
every extension. Use the existing observation codec, but add SC fields when
needed rather than dropping findings or incomplete status to fit a sequential
tuple. Record the selected schedule and local choices for reproducibility;
Lean's first-choice runner and native random selection need not choose the
same execution.

The immediate acceptance examples should include publication and its missing-
synchronization control; disjoint members and a same-location race; an ordered
byte update followed by an independent race; initialization/main/finalization;
and a deterministic loop under a small step budget. Every example needs an
explicit expected observation and completeness classification. The recovered
C file comments are not those specifications. Keep the diagnostic
post-UB continuation out of the initial lane; stop-at-first-UB already gives
a useful finite witness for the race-before-loop case.

## Evidence and limits of this review

- The reviewed branch was clean and consisted of two commits over mainline:
  39 changed files, with no production source changes. I independently checked
  all 21 provenance hashes and byte identity against the pinned donor; there
  are 22 C inputs in total. `git diff --check` passed on the reviewed delta.
- I read the governing plan, technical design, quarry assessment, recorded
  diagnostics and seeds; inspected current ND/driver/Core/memory/atomic seams;
  and compared the donor's frozen API/driver and handoff records. Donor line
  references use `631382a9d23a709112f38add53357d4cbe6fc108`, not an implied
  current-mainline implementation.
- I checked the relevant primary FastTrack and Batty paper sections linked
  above, and the historical operationalization's scope. The latter explicitly
  describes an inefficient integration with non-scalar objects out of scope
  ([Nienhuis et al., introduction](https://www.cl.cam.ac.uk/~pes20/rems/papers/nienhuis-oopsla-2016.pdf)).
  It does not supply an efficient concrete-object implementation to transplant.
- The only new executions were the eight bounded sequential native cost
  controls recorded alongside this review. No new SC implementation exists
  here to execute. I did not rebuild either engine, rerun the donor's full
  suites, certify their binaries against source, or run the release battery.
  This is a plan/source review with limited identified-binary diagnostics.
- This branch adds only this review and its diagnostic record. It does not
  modify the governing plan, the execution branch, mainline, the donor, or the
  external Iris consumer. Scope recommendations require an explicit plan
  decision before the implementing agent treats them as accepted requirements.
