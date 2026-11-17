# Charter: CoreNice breakpoint semantics

Status: experimental milestone followed by repairs on
`corenice/checkpoint-semantics-repair`; see the
[repair assessment](checkpoint-semantics-repair.md) and historical
[checkpoint](breakpoints-checkpoint.md). Baseline: reviewed
`corenice/comesfrom` checkpoint `11587a90b`. This charter governs the next
breakpoint milestone and supersedes the earlier combined-demo work order where
they differ. The [machine design](cerberus-nice-design.md) and
[comesfrom checkpoint](comesfrom-checkpoint.md) remain its foundations.

## Purpose and deliverable

Expose intermediate CoreNice execution states at explicit AST boundaries.
Execution can stop at a reached breakpoint and restart with the same state,
pending execution and choices. Prioritize boundaries corresponding to **AIL
composition** because these are useful endpoints for later refinement work.
The present deliverable is executable syntax and semantics; it does not
introduce a symbolic midpoint relation or require a new simulation proof.

Deliver a position-restricted breakpoint AST, an explicit resumable driver,
an AIL-origin placement policy and a reviewed differential demonstration.
A general Core/CoreNice equivalence theorem, a verified producer and a
Caesium lifting theorem remain later work.

## Operational decomposition contract

For the supported Core execution pathway, inserting breakpoint tails must
preserve executions under erasure of the administrative pause/resume events.
At each reached cut:

* The original strong-sequence prefix has completed, including its binding
  and annotation work; the suffix has not started.
* Suspension retains the actual residual execution, call/control context,
  environment, memory, fresh supply, pending siblings and driver phase.
  These are the existing runtime values, not an abstraction reconstructed
  from a printed site or a relation to another state.
* Restart uses those saved values and the same immutable semantic
  configuration, without replaying the prefix, recomputing the frontier,
  selecting a pending choice again or resetting cumulative budgets.
* The choice runner retains its tape cursor, RNG and observation history.
  Selecting a host pause adds no language-level choice or effect.

The intended property quantifies over executions and eventually resumed pause
schedules. Finite differential checks exercise this contract but do not prove
its universal quantifier or preservation of divergence. Resource exhaustion
is incomplete evidence, not a corresponding semantic termination.

Return, goto, break, continue, UB and modeled errors retain their original
control behavior. A normalized wrapper can complete after a source
`continue`; this is a valid machine breakpoint arrival, not a certificate of
source-normal completion. A jump can bypass a boundary or enter its suffix.
Neither a breakpoint role nor a comesfrom set establishes dominance or lexical
scope. Later AIL/Caesium reasoning may use the exposed endpoints, but that
reasoning is separate from this runtime contract.

Resume accepts any valid execution state; it need not require a state minted
by an earlier driver call. The generated operation takes semantic parameters
as well as the suspension record. Same-execution decomposition preserves those
inputs, while other valid inputs can describe other executions. The
[landing review](breakpoints-landing-review.md) records this distinction.

## AST and exact pause semantics

Retain the existing proposal, schematically:

```text
Expr       ::= ... | StrongSeq pattern Expr StrongTail
StrongTail ::= Continue Expr | Breakpoint Site Expr
```

`Breakpoint` is syntax in the strong-sequence continuation category. It is not
an arbitrary expression admitted by a later placement validator. A strong
sequence containing a breakpoint may itself occur under unsequencing or other
existing contexts. Do not add strong sequencing merely to manufacture a site.

The pause occurs **after** successful completion of the left operand, pattern
validation, binding/substitution and propagation of pending `Eannot` data,
and **before** executing the right operand. Preserve both existing strong-
sequence completion rules. A failed match or left-side UB does not reach the
breakpoint. Resumption continues from this already-completed boundary, without
repeating the binding, emitting the same encounter again or running the suffix
with priority that the original driver phase would not grant. Preserve the
original sibling/choice order, including any existing preference for advancing
the current thread. A later loop visit may reach the same static site again and
is a new encounter.

Erasing a breakpoint replaces its tail by `Continue` and preserves the original
strong-sequence node and payloads. Carry the new category through all owned
AST consumers, the active context-based reducer, substitutions, conversion,
boundary/negative-action reconstruction and saved-continuation collection.
Labels in a sequence's left operand retain the pending breakpoint in their
reconstructed suffix; a jump directly into the right operand bypasses it.

CoreNice follows upstream and cerberus-lean's production context-based reducer.
Its inherited inactive `core_thread_step2` and private support were removed
after the [provenance and discrepancy assessment](checkpoint-semantics-repair.md).
The original both-engines ambition is retired; the normal and resumable drivers
share the active reducer.

Existing raw Core text can parse into `Continue` tails. A new annotated text
roundtrip is not a prerequisite: typed construction and generated AIL output
must exercise the feature. Any decoder that does accept breakpoint syntax must
enforce the same category restriction.

## Placement: precise normalized-AIL phases

Select sites in the owned AIL-to-CoreNice lowering, after shared Cabs-to-AIL
desugaring and owned loop-control normalization. Their roles name the actual
normalized-AIL phase; neither source lines nor producer keys recover lost
source-C structure. The implemented roles in `Translation.translate_stmt` are:

| Boundary role | Existing lowering site | Intended handoff and limit |
| --- | --- | --- |
| `BP_normalized_ail_join` | `AilSblock`, the existing strong-sequence fold over `core_ss` | A normalized-AIL join with the remaining statement list pending. Includes generated control wrappers and for-loop increment structure; no source-normal completion claim. Saved-continuation entry can skip an earlier prefix. |
| Condition ready for control selection | `AilSif` and `AilSwhile`, tail after the boolean conversion | Condition effects and conversion are complete; the branch/body has not executed. Identify the actual Caesium condition/control phase before claiming an aligned midpoint. |
| `BP_while_restart_pending` | `AilSwhile` body-to-backedge sequence | The existing `Erun` restart is pending. `continue` may reach this cut. A source `for` loop has already executed its increment and intervening cleanup. |
| `BP_do_condition_pending` | `AilSdo` body-to-test site | The condition has not yet executed and may be false or fail. This is not a pending backedge; `continue` may reach it. |
| Internal expression/helper completion | For example the inner `AilSexpr` discard-to-unit sequence | Useful for testing machinery, but not automatically an AIL statement boundary. Record as an internal site, with a separate coverage count. |

The source anchors are [translation](../../../frontend/corenice/model/translation.lem)
(`AilSblock`, `AilSif`, `AilSwhile`, `AilSdo`, `AilSlabel`, returns),
[sequence/continuation builders](../../../frontend/corenice/model/core_aux.lem)
(`mk_unit_sseq`, `collect_saves_aux`), and
[completion rules](../../../frontend/corenice/model/core_reduction.lem)
(`one_step`, `Esseq` cases). Inspect normalized AIL: source `for`/continue syntax
may already have become loops and introduced labels.

A `Site` carries a static identity, placement role, typed origin and source
location. `NiceNormalizedAil occurrence slot` is a producer key in the normalized
input, not an ancestry path or source-C certificate; `NiceInternal` makes no
AIL-origin claim. Preserve provenance through
copies and saved-continuation reconstruction. IDs use their own namespace and
do not consume Cerberus's fresh-symbol supply. Repeated/recursive activations
share a static site; diagnostic encounter numbering is not activation identity.
Synthetic/internal sites must not masquerade as AIL-aligned evidence.

An AIL-origin tag records producer intent, not semantic certification. For the
demonstration, inspect the actual AIL and both generated outputs and publish a
small mapping from each selected source boundary to its Nice site and Caesium
residual/control phase. AIL-to-Caesium currently flattens block lists and uses
continuation blocks for branches/loops; do not expect identical AST nesting or
matching generated label numbers. Allow explicitly described administrative
alignment and stuttering; do not assume a bijection of steps or sites.

Companion inspection anchors, not new build dependencies: in `refinedc-lean`,
`AilToCaesium/AilToCaesium/AilToCoq.lean`, `translateBlock`; in
`cerberus-caesium`, `CoreCaesium/CoreCaesium/RecursiveBodyComposition.lean`,
`sequence`, and `RecursiveCompatibleContext.lean`. These motivate the interface;
they do not establish a theorem for the new machine. Do not edit installed
dependencies or make a new Caesium semantics part of this milestone.

## Driver and inspection interface

Provide a typed run/advance result distinguishing suspension, completion and
existing failure outcomes, plus a resume operation over a well-formed
suspension in its original program/configuration. Preserve immutable program
data and the complete operational state in memory. Expose named control/phase
data and pure accessors suitable for later predicates; an opaque closure of
the entire old driver is insufficient. Shared primitive callbacks may remain.

The suspension must retain the driver work in progress: nonmemory advancement,
pending worklists/frontier, and any already selected choice. In particular,
`drive_nonmemory_steps_aux2` repeatedly advances work inside a driver phase.
Restarting `drive` or merely scheduling the suspended thread again can change
behavior. Factor the owned driver at the actual boundary and resume that phase.

The [differential runner](../../differential/ChoiceRunner.lean) also needs a
nonterminal suspension result. Retain its session: tape cursor,
random-generator state, observation accumulator and cumulative budgets.
Do not route a pause through terminal handling that checks
for unused replay/prefix entries, and do not start a fresh runner on resume.
Finalize the tape only at the underlying run's genuine completion or failure.
Test pauses on both sides of a recorded choice and with a nonempty replay
suffix, so premature finalization or restarted selection is observable.

Pausing is administrative, with no added C-level choice, scheduler alternative
or effect. Host pause selection may inspect a site/visit and choose to stop or
continue, but cannot mutate semantic state or choose a different program on
resume. Correspondence compares schedules that eventually resume; an external
client abandoning a suspension is not evidence of semantic divergence.

Keep full state in memory; emit compact boundary/phase descriptors, choice
positions and selected observations. Testing may inspect pure midpoint
projections or assertions without modifying execution. No full-state dumps,
serialization/checkpoint files or interactive debugger are required.

## Evidence and observation contract

Use three executions: Core, breakpoint-bearing Nice with automatic continuation,
and the same Nice program with explicit suspensions/resumptions. Keep the
unmarked comesfrom checkpoint available as an additional regression reference.

Specify erasure before accepting comparisons. Remove only breakpoint/host
administrative records; preserve original effects, values, stdout/stderr,
failures, genuine choice alternatives/order, choice consumption and the unused
tape suffix.
If driver factoring changes low-level nonbranching boundaries, state that
projection explicitly and retain the existing choice barriers. Step/fuel counts
need not be equal. Budget exhaustion is incomplete coverage, never agreement;
do not reset a run's accounting on every resume to hide a runaway execution.

Record/replay choices in both directions. Compare no host pauses, every reached
site, individual selected sites and deterministic subsets of repeated visits.
For small finite fixtures enumerate pause choices and genuine alternatives;
for larger campaigns report sampled schedules and distinct actual tapes.

Required tests include:

* A generated block with two effectful statements: the first effect is present
  at the midpoint, the suffix effect absent, and final observations agree.
* A loop with repeated condition/body boundaries and a pointer-mutating helper;
  calls/recursion distinguish repeated encounters without inventing static sites.
* Normal and abrupt exits, jump entry into either sequence operand, ordinary
  label entry, saved-continuation suffixes, and inherited comesfrom controls.
* A valid nested breakpoint under unsequencing, using calls with distinguishable
  effects on disjoint objects. First establish a genuine competing choice in
  Core, then preserve its alternatives/order and already-consumed prefix after
  resume. Do not demand a choice that greedy advancement does not expose.
* Pattern failure, `Eannot`, UB/error before and after the cut, and a synthetic
  boundary/negative-action reconstruction case where supported by the recipe.
* Injected implementations that repeat a left effect, skip a suffix effect,
  consume a choice twice, or lose a reconstructed breakpoint. Require the
  appropriate comparison to detect each defect.

Artifact checks must show that removing breakpoints gives the expected existing
program, not a new sequencing arrangement. Run the existing generated/minimal
campaigns with executed breakpoint coverage and targeted additions. Unreached
annotations do not count as pause coverage. Known allocator-exhaustion fixtures
are expected-OOM controls only when their precise outcome matches; unexpected
model errors and unexpected `NiceFault` remain failures. Report outcomes and
coverage honestly without silently dropping normal inputs that disagree.

## Milestones and exit

1. **Placement and handoff design.** Work through one block and one loop from
   actual AIL to both generated targets. Specify selected roles, residuals and
   the actual retained bindings, temporary lifetime state and ambient control.
   Identify the driver phase and runner session to suspend.
   If an intended AIL join has no suitable existing position, report the gap;
   do not silently replace it with an unrelated internal cut.
2. **AST and resumable execution.** Implement the owned syntax, transport,
   the active reduction rules and nonterminal runner protocol; regenerate and compile.
   Demonstrate a real suspension and correct resume, then nested/unsequenced
   and saved-continuation cases. Keep focused checks during construction; no
   broad proof project is a prerequisite.
3. **AIL placement and useful midpoint demo.** Generate the selected block and
   loop sites directly from lowering. Show actual in-memory midpoint assertions
   and the concrete AIL/Nice/Caesium mapping. Explain abrupt and multiple
   entries operationally. The mapping is motivation for later proof work,
   not a simulation theorem or a required symbolic midpoint relation.
4. **Differential validation and review.** Complete positive, adversarial and
   campaign runs; report observed sites/roles, distinct tapes and pause schedules,
   results and limitations. Obtain independent unrestricted review and resolve
   each finding. Exit with a reproducible runnable checkpoint and a concrete
   assessment of whether its endpoints are useful for a later sequence proof.

Work in milestone branches/worktrees of the owned cerberus-lean clone, based on
the reviewed comesfrom commit and intended for the research integration branch.
Preserve a reviewable checkpoint before implementation. Mainline adoption,
consumer re-pinning and pushing are separate approval points. Discuss any Lem
compiler change before making it; ordinary owned-model changes are in scope.
Documentation-only work needs no proof rebuild. During implementation prioritize
compilation, regeneration and meaningful behavior/trust checks; full relevant
trust gates apply to later landed/shipped proof claims, not every draft iteration.

No lexical-scope reconstruction, heap-typing system, new memory model, changed
unsequencing policy or general proof-automation framework belongs to this first
breakpoint milestone. If preserving the phase or obtaining a useful source
boundary fails, return the concrete counterexample and revise the design.

## Direction and provenance

* [USER, 2026-11-16] Prioritize a differentially validated breakpoint design;
  defer the broad correspondence proof. Choose exposed states with simulation
  sequencing and eventual AIL-to-Caesium alignment in mind.
* [AGENT, 2026-11-16] Use existing strong-sequence tails, preserve source-origin
  roles during lowering, and require block/loop handoff demonstrations. Keep
  machine-internal cuts and source-aligned evidence distinct.

* [USER, 2026-11-17] Keep this milestone focused on explicit AST features and
  executable semantics. Expose the actual intermediate states and pending
  execution; defer additional proof relations.
