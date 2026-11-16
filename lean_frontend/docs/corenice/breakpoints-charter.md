# Charter: CoreNice breakpoints for compositional simulation

Status: design charter; implementation has not begun. Baseline: reviewed
`corenice/comesfrom` checkpoint `11587a90b`. This charter governs the next
breakpoint milestone and supersedes the earlier combined-demo work order where
they differ. The [machine design](cerberus-nice-design.md) and
[comesfrom checkpoint](comesfrom-checkpoint.md) remain its foundations.

## Purpose and deliverable

Expose intermediate CoreNice execution states at explicit AST boundaries so a
future simulation proof can compose a prefix and suffix through a shared
midpoint relation. Prioritize boundaries corresponding to **AIL composition**:
we ultimately want to relate these states to the corresponding Caesium residual
program and state, and reuse source-side reasoning there.

Deliver a genuine position-restricted breakpoint AST, an explicit resumable
driver, an AIL-origin placement policy and a reviewed differential demonstration.
The result is a design supported by measured execution evidence. A general
Core/CoreNice equivalence theorem, a verified producer and a Caesium lifting
theorem are later work. Small proof-interface examples may inform the design;
none is a prerequisite for the first experimental implementation.

## The intended sequence rule shapes the boundary

For a normally completing source prefix `S1` and suffix `S2`, the eventual rule
should compose a simulation from `R` to a midpoint relation `Q`, with a
simulation from **every midpoint satisfying Q** to the desired suffix result.
`Q` relates a source/Caesium configuration to a CoreNice suspension; it is not
just a predicate on the last value or a selected successful trace.

```text
R(source start, Nice start)
         prefix simulation, including its observable trace
Q(source residual S2, Nice boundary after S1)
         suffix simulation for each related midpoint
postcondition / corresponding exit
```

This is a specification sketch, not a proved inference rule. A later theorem
must specify its refinement direction, nondeterministic quantifiers, progress
and trace concatenation. The breakpoint supplies an endpoint to relate; it
does not establish `Q`, heap ownership or source/target correspondence.

The handoff must retain the residual continuation, call/control context,
environment and memory, fresh supply, pending siblings and driver phase. These
facts are available in the actual in-memory suspension, not inferred from a
printed breakpoint ID. Existing parent sequence proofs already carry memory
history, supply and stack facts across their midpoint; the new interface must
allow such predicates rather than prescribing a smaller state projection.

Ordinary composition applies to normal completion. Return, goto, break,
continue, UB, modeled errors and divergence require their own exit cases;
they must not be turned into normal breakpoint arrivals. A jump can bypass a
boundary or enter its suffix. A multi-entry region needs an entry-sensitive
contract, or a justified restriction on entries. Neither breakpoint placement
nor an existing comesfrom set establishes dominance or lexical scope.

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
AST consumers, both reduction engines, contexts, substitutions, conversion,
boundary/negative-action reconstruction and saved-continuation collection.
Labels in a sequence's left operand retain the pending breakpoint in their
reconstructed suffix; a jump directly into the right operand bypasses it.

Existing raw Core text can parse into `Continue` tails. A new annotated text
roundtrip is not a prerequisite: typed construction and generated AIL output
must exercise the feature. Any decoder that does accept breakpoint syntax must
enforce the same category restriction.

## Placement: source composition before convenient machine steps

Select sites while the owned AIL-to-CoreNice lowering still knows their source
role. Do not reconstruct AIL boundaries from source lines or a flattened Core
trace. First priorities, inspected in `Translation.translate_stmt`, are:

| Boundary role | Existing lowering site | Intended handoff and limit |
| --- | --- | --- |
| Between adjacent AIL block statements | `AilSblock`, the strong-sequence fold over `core_ss` | Normal completion of statement i to the residual statement list. Retain block allocation/cleanup context; do not classify later cleanup sequences as source-statement joins. |
| Condition ready for control selection | `AilSif` and `AilSwhile`, tail after the boolean conversion | Condition effects and conversion are complete; the branch/body has not executed. Identify the actual Caesium condition/control phase before claiming an aligned midpoint. |
| Normal loop-body completion | `AilSwhile` body-to-backedge sequence; corresponding `AilSdo` body-to-test site | Expose the body postcondition before the existing transfer/test. Abrupt exits need separate cases; a continue route is not assumed to pass this site. |
| Internal expression/helper completion | For example the inner `AilSexpr` discard-to-unit sequence | Useful for testing machinery, but not automatically an AIL statement boundary. Record as an internal site, with a separate coverage count. |

The source anchors are [translation](../../../frontend/corenice/model/translation.lem)
(`AilSblock`, `AilSif`, `AilSwhile`, `AilSdo`, `AilSlabel`, returns),
[sequence/continuation builders](../../../frontend/corenice/model/core_aux.lem)
(`mk_unit_sseq`, `collect_saves_aux`), and
[completion rules](../../../frontend/corenice/model/core_reduction.lem)
(`one_step`, `Esseq` cases). Inspect normalized AIL: source `for`/continue syntax
may already have become loops and introduced labels.

A `Site` carries a static identity, placement role, optional AIL-origin key and
source location. Identify an AIL occurrence by procedure and deterministic
occurrence path/producer key, not location alone. Preserve provenance through
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
   candidate midpoint predicates, including bindings/temporary lifetime state
   and ambient control. Identify the driver phase and runner session to suspend.
   If an intended AIL join has no suitable existing position, report the gap;
   do not silently replace it with an unrelated internal cut.
2. **AST and resumable execution.** Implement the owned syntax, transport,
   both rule paths and nonterminal runner protocol; regenerate and compile.
   Demonstrate a real suspension and correct resume, then nested/unsequenced
   and saved-continuation cases. Keep focused checks during construction; no
   broad proof project is a prerequisite.
3. **AIL placement and useful midpoint demo.** Generate the selected block and
   loop sites directly from lowering. Show actual in-memory midpoint assertions
   and the concrete AIL/Nice/Caesium mapping. State the proposed sequence-rule
   premises for this demo, including abrupt/multiple entries. No Caesium
   simulation theorem is claimed by that mapping or by a few projections.
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
