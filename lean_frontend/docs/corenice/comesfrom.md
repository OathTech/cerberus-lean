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
return the structured fault below through the existing error mechanism.
Missing-label and arity failures retain their existing behavior. Ordinary
execution through an `Esave` is unchanged.

The check executes inside the existing jump step. Successful runs should keep
their choices and observed effects exactly; no scheduler, extra ND step or
pause/resume mechanism is needed. Error encoding and AST plumbing do change.
Faults remain visible and must never be equated with C undefined behavior.

`NiceFault` is a typed variant with a check-specific payload, initially:

```text
IncomingOriginDenied {
  procedure, jumpSite, destinationLabel,
  jumpLocation, labelDeclarationLocation,
  permittedOrigins
}
```

Use resolved semantic identities, the location datatype (preserving unknown or
generated locations honestly), and the exact permitted set used by the check.
Retain declaration locations when extracting saved continuations. Human-readable
messages and JSON diagnostics are derived from this data, not used as its
representation. Future fault kinds get their own typed payloads.

This gives an eventual proof a constructor to invert and concrete operands for
the failed membership condition. The transition relation supplies the faulting
pre-state; the payload need not duplicate a machine state or execution history.
Construct the payload from the executing node and resolved label entry so it
describes the actual failed check.

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

## Work order

1. **Build the feature.** Implement the AST fields, annotation producer and
   checks in both jump rules. Start with the conservative incoming sets above.
2. **Establish a clean differential baseline.** Run the targeted cases and
   existing campaigns against original Core. Normal generated programs must
   agree without `NiceFault`; deliberate corruptions must produce the expected
   faults. Preserve other original outcomes, including C undefined behavior.
3. **Tighten aggressively and retest.** Develop progressively smaller incoming
   sets, then repeat differential testing against original Core, including new
   generated inputs and alternative choice tapes. Produce annotations before
   choosing a tape; observed origins from one run are not the permitted set.
   Report how much sets shrink and which tightened checks actually execute.
   Any unexpected `NiceFault` on normal generation is a failed candidate to
   diagnose and fix, never an accepted difference or an injected-fault success.
   Do not hide it by weakening trace comparison or silently excluding programs.

With static jump-site identities, the initial sets already contain every
syntactic jump to each label. Further removal requires a hypothesis that the
removed origin cannot execute that jump in the admitted program; small sets
cannot be forced by excluding possible original behavior. Use differential
counterexamples to refine those hypotheses. If a set cannot usefully shrink,
report that limit. Successful campaigns provide evidence over their tested
inputs and choices, not a universal no-fault theorem.

Only after the implemented, tightened producer works cleanly should we consider
proof: assess the concrete machine and restrictions that survived testing.
No membership lemma or comparative invariant proof is an earlier milestone.

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
Negative controls also check the fault constructor, identities, locations and
permitted set against the faulting artifact, rather than matching an error string.

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

After the build/test/tightening sequence, a possible proof experiment is to
derive the successful-jump membership rule and organize a label invariant using
the actual tightened sets, retaining normal entry. Compare the supporting
lemmas with Core's, including provenance obligations. If this merely adds
premises and bookkeeping, record that outcome; runtime tests alone do not
establish a scaling improvement.

The likely first benefit is a stable control-flow proof interface and better
counterexamples. It is a credible first experiment, but there is not yet
evidence that it resolves the project's main refinement-scaling bottleneck.
