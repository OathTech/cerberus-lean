# Checked incoming jumps in CoreNice

Proposal against checkpoint `451011583`. This is one semantic change to the
existing CoreNice AST and interpreter; no implementation or equivalence result
is claimed. Breakpoints, pause/resume and scope reconstruction remain separate.

## Semantics

Give each jump a static site identity and each saved label a permitted incoming
set. Schematic syntax:

```text
save L comesfrom {j1, j2} (parameters) body
run @j1 L(arguments)
```

These are dedicated fields of CoreNice's `Esave` and `Erun`, not advisory
comments or caller-supplied runtime arguments. Identify sites within the
resolved procedure, using separate numbering from Cerberus's fresh symbols.
Repeated execution, recursion and runtime copying retain the original site
identity; it does not identify a dynamic activation.

An `Erun` uses the existing procedure/label resolution and argument-count
checks, then checks membership before evaluating/substituting arguments or
transferring control. On success, perform the existing transition. On failure,
return a distinct `NiceFault(procedure, site, label)` through the existing error
mechanism. Missing-label and arity failures retain their existing behavior.
Ordinary execution through an `Esave` is unchanged.

The check executes inside the existing jump step. Successful runs should keep
their choices and observed effects exactly; no scheduler, extra ND step or
pause/resume mechanism is needed. Error encoding and AST plumbing do change.
Faults remain visible and must never be equated with C undefined behavior.

## Producer and implementation

Start with a pure finalization pass over the Nice-owned linked procedures,
including parsed runtime procedures, before runtime conversion. Assign site
identities and collect all syntactic jumps resolving to each label. These
conservative sets include unreachable sites; no reachability or lexical-scope
claim is needed. This is part of AIL-to-CoreNice production, with no execution
or translation through the original Core target.

Require unambiguous procedure/label bindings and unique original jump-site
identities within each procedure; refuse unsupported binding forms explicitly.
Do not require distinct identities for runtime copies. Do not add an eager
gate requiring every syntactic edge to be permitted: a well-formed but
incorrect declaration must fault only when its disallowed jump executes.

Update the owned Lem AST and its consumers, without changing the Lem compiler
or shared Core. Preserve the fields through substitution, conversion, parsing,
printing and saved-continuation extraction. The current label table is static
and procedure-indexed; extraction reconstructs sequencing suffixes. Attach the
incoming set to that same resolved continuation, avoiding a second label table.
Both the substitution-based and environment-based jump rules enforce the check.

Source anchors: [AST](../../../frontend/corenice/model/core.lem),
[continuation collection](../../../frontend/corenice/model/core_aux.lem)
(`collect_saves`, `collect_labeled_continuations_NEW`),
[runtime state](../../../frontend/corenice/model/core_run_aux.lem),
[first jump rule](../../../frontend/corenice/model/core_run.lem) and
[optimized jump rule](../../../frontend/corenice/model/core_reduction.lem).

## Differential acceptance

Erase only the new fields when comparing pre-execution ASTs. Keep successful
execution-trace and choice-tape comparison exact in both recording directions;
do not weaken comparison to accommodate unexpected changes. Record fresh tapes.
The unmodified source-identity check will intentionally stop passing once the
owned model changes; it is a baseline check, not a permanent equivalence test.

Exercise forward/backward `goto`, loop-generated jumps, `break`/`continue`,
switch dispatch, normal label entry, calls/recursion and runtime procedures,
then the applicable existing corpus and generated campaign. Require executed
checked jumps, not merely annotated dead code. Delete a taken site's permitted
entry, or replace its identity with a fresh, otherwise well-formed identity
absent from the destination's set, in the actual Nice artifact. The run must
fault at that jump, before its arguments/control transfer, retaining the
matching earlier observations. Restricting an untaken edge must not fault.
Corrupt metadata after finalization so the producer cannot repair it. A parser
rejection, native crash or timeout is not the expected fault. Check both jump
implementations with focused witnesses; the normal campaign does not cover both.

## Does this help reasoning?

**Credibly, but modestly.** A successful checked jump immediately supplies
`site ∈ incoming(procedure, label)` by inversion of its transition rule. A
proof can split on a label's finite permitted sites using one reusable rule,
instead of repeatedly recovering possible origins from program/execution
structure. The check also makes violated predecessor restrictions testable.

There are important limits:

* Core already has explicit jump destinations. With sets derived from all
  syntactic jumps, the information is redundant and the reachable control-flow
  graph is unchanged. A static predecessor lemma for ordinary Core could offer
  similar information. Checks make the interface explicit and enforceable for
  later, narrower declarations; they do not yet improve the abstraction of C.
* Membership identifies a site, not a state invariant. A label invariant still
  needs transfer obligations for each jump **and ordinary non-jump entry**,
  including argument/environment effects. Site provenance must survive
  substitution and saved-continuation reconstruction. After a jump the machine
  does not retain a last-origin field: this fact belongs to the transition,
  not to any arbitrary state whose arena happens to contain the saved body.
* It supplies no structured loops, lexical scope, activation identity, heap
  ownership or execution decomposition. Memory and nondeterminism remain.
* Original-to-Nice correspondence still requires producer correctness:
  generated declarations must never introduce faults. Local checking alone
  neither proves equivalence nor permits discarding newly faulting behavior.

Test the reasoning hypothesis with a small symbolic example: derive the
successful-jump membership rule and use it to organize a label invariant with
two jump predecessors plus normal entry. Compare the supporting lemmas with
the corresponding Core argument, including the provenance obligations. This
is a proposed follow-up, not a prerequisite for the differential prototype or
a whole-machine proof. If it merely adds premises and bookkeeping, record
that outcome; passing runtime tests does not establish a scaling improvement.

The likely first benefit is a stable control-flow proof interface and better
counterexamples. It is a credible first experiment, but there is not yet
evidence that it resolves the project's main refinement-scaling bottleneck.
