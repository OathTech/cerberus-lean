# Which generator fact should CoreNice expose next?

**Try checked object-slot forwarding on generated loop backedges.** It has a
single producer rule, a single transfer step and an existing consumer that
recovers precisely this fact. Checked direct-call targets are the runner-up.
The lifetime protocol would require a separate experiment in representing
several Core operations as one higher-level construct.

This assessment uses `feature/cerberus-nice` at `36e50de3f` and the parent
`cerberus-caesium` proofs at `f12c3f1f6`. The proposals apply the existing
[selection criterion](generation-invariants.md). The new execution evidence
below exercises the integrated machine, including a deliberately corrupted
backedge. Forwarding and direct-call checks are proposed features.

## First experiment — what arrives on a backedge?

The `AilSwhile` generator reads `visible_syms` once. From it, the generator
builds both the saved label’s ordered object binders and the backedge’s ordered
symbol operands. The printed Core of the existing loop fixture has a header
with slots `[count, total]` and a backedge that supplies `[count, total]`.
Both are pointer slots. Swapping them leaves the destination, permitted jump
origin and arity intact. The current transfer rule therefore has no way to
reject that swap *as a slot mismatch*. This is a property of object **names**,
independent of the values the two names happen to hold.
[While lowering](../../../frontend/corenice/model/translation.lem#L4006) ·
[Transfer rule](../../../frontend/corenice/model/core_reduction.lem#L1469) ·
[Loop fixture](../../../tests/corenice/comesfrom-tightening/loop_break_continue.c)

**Why a client would care.** In the parent, `ContinuationConstruction.jump`
opens every positional expression, checks it is a symbol, maps it to a local
declaration and recovers the saved destination. Its companion for `Esave`
examines the actual binders and initializers. In `CompletionArrayReverseTransfers`
the proof extracts declaration indices `[2,3]`, the locals `i` and `j`,
separately at the header and at the backedge. `CompletionScanClassifyGraphCuts` invokes the jump recognizer
13 times across a loop, switch cases, default and break. At the parent revision
there are 27 jump and five save macro invocations in 16 top-level proof modules
combined. These counts show where the operation recurs. Most scanner edges
are outside the proposed first slice. No timing improvement has been measured.

**A transfer that passes today and gives the wrong result.** I ran the
provider corpus function `arr_reverse` with a four-element local array
initialized to `{1,2,3,4}` and a caller returning 0 for `{4,3,2,1}` and
1 otherwise. Unmodified Core and CoreNice agreed in both tape directions.
There were two while-restart visits and no nondeterministic choices. Printed
Core showed `save while_682(i := i, j := j)` and `run while_682(i,j)`
(types omitted). I then changed only the operands of that one jump in the
lowered Nice procedure. On the current reducer the original returned 0 and the
mutant returned 1 normally. Destination, arity, comesfrom metadata, and both
argument expressions were retained. Their order alone changed.
[Corpus function](../../corpus/p06_arr_reverse.c) ·
[Existing file-mutation and fresh-state recipe](../../test/CoreNice/BreakpointDemo.lean#L147)

To reproduce the negative control in that recipe, select `arr_reverse` in the
lowered file’s procedure map, use `Incoming.mapExprM` to rewrite exactly one
node as below, and rebuild the initial driver state with the original translated
supply. Run the resumable driver to completion on each file. The unique match
on this fixture has `i` and `j` as its two object-address symbols.

```text
Erun annotation destination [PEsym i, PEsym j] origin
   → Erun annotation destination [PEsym j, PEsym i] origin
```

**What to change.** For the compiler-emitted `while` backedge, give the jump a
Nice form whose actual operands are ordered object-slot references. Each erases
to the original annotated `PEsym`. At the existing `Erun` step, compare their
symbols with the actual ordered parameter binders in the saved-label entry.
Use Cerberus symbol identity (digest and numeric identifier). The display
description has no role in binder identity. [Symbol comparison](../../../frontend/model/symbol.lem#L137)
On mismatch raise a typed `NiceFault` carrying procedure, jump origin,
destination, and expected and actual symbols. On agreement use the current Core
argument evaluator and update the environment exactly as before. All argument
reads see the incoming environment, even as writes accumulate in the new one.
Use the declaration already carried by the label table. An extra expected list
on the jump could agree with itself while saying nothing about the destination.

The machine then supplies a useful fact at this edge. Each destination object
slot received the value of the correspondingly named incoming operand under
Core lookup. The client still maps those symbols to Caesium declarations,
identifies the destination code and discharges binding and lookup premises.
The existing parent lemmas `ParameterizedJump.symbols_advance` and
`ContinuationArguments.environment_identity` already factor the dynamic part.
The claim applies to executing the marked backedge. Ordinary entry through
`Esave` evaluates its initializers, and other transfers can reach a label.

**What would convince us to keep it.**

1. Generate the marked edge at the `while` rule and carry its operand identity
   through linking, renaming and the active `Ecase` substitution rule. Exercise
   shadowed declarations and nested loops. Preserve partial evaluation and all
   existing failure paths. If retaining a slot requires restricting the accepted
   lowering, identify that shape at generation time. An unchecked symbol tag on
   an arbitrary replacement expression would invalidate the inference.
2. Run independent Core and CoreNice lowering, record and replay tapes in both
   directions, and compare choices, observed effects, cut visits on the Nice
   path, and outcomes using the existing projections. Reach the marked edge
   more than once. Swap two same-typed **source operands** on a Nice edge while
   preserving its label and origin. Require the precise forwarding fault on
   that transfer. Repeat with a different declaration bearing the same printed name
   to distinguish binder identity from display text. Check an unmarked edge with a computed return value as a
   control. Ordinary generation should produce zero new faults.
3. Read the array-reverse loop interface directly from a generated Nice artifact
   and derive its ordered source/destination correspondence without reopening
   each pure-expression tree. List which premises formerly established by
   `continuation_jump%` and `continuation_save%` the interface supplies, and
   which the client still discharges. Recovering only the same list while
   reproving its connection to the destination on every edge would miss the
   purpose. This is a consumer experiment before a general proof.
4. Consider `do` loops, then other generated edges, after the first result.
   Arbitrary gotos need agreement between two traversals that collect visible
   objects. Return edges also carry computed payloads. A claim covering every
   arrival would have to account for fallthrough and all incoming transfers.
   [Visibility prepass and transfer helper](../../../frontend/corenice/model/translation.lem#L3628) ·
   [Save reduction](../../../frontend/corenice/model/core_reduction.lem#L476) ·
   [Symbol evaluation](../../../frontend/corenice/model/core_eval.lem#L570)

## Runner-up — the callee symbol already known at a direct call

For an AIL function identifier the generator constructs a function pointer
to a known symbol, taking the standard-library name mapping into account.
In the `add` fixture this starts as `Cfunction(add)`. By the time `Eccall`
dispatches, the pointer is in temporary `a_511`, carried through a tuple and
unsequenced argument evaluation. The parent theorem
`CanonicalTableCall.Reference.invocationMetadata` recovers the callee pointer
from the bindings. A successful checked call would expose the named callee at
the existing transfer point.
[Designator lowering](../../../frontend/corenice/model/translation.lem#L236) ·
[Generated call](../../../tests/fixtures/016-func-simple/core.txt#L67)

Carry the expected post-designator symbol to a marked `Eccall`. Preserve
normal pointer evaluation, argument sequencing, errors and procedure lookup.
For a successfully resolved call compare the symbol extracted from the actual
callee pointer against the one generated for the direct designator. Record a
typed fault on disagreement. The selected body still follows the existing
stdlib-first and extern-map lookup. Function-pointer calls keep their general
semantics. A first experiment needs a named local callee, a stdlib-mapped or
linked name, an indirect call and a wrong-name mutation. This ranks second
because establishing the correct name through tuple binding and linkage is
more involved than reusing the very same object list at a loop.
[Dispatch](../../../frontend/corenice/model/core_reduction.lem#L1401) ·
[Procedure lookup](../../../frontend/corenice/model/core_run.lem#L34)

## What the current breakpoints already buy at a join

The parent’s checked-join study introduced an extra `identity(y)` call to get
a shared post-call residual for one proof. We exercised the earlier `joined`
control directly. This reduced translation unit preserves the operations in
the original `bump` and `joined` bodies, omits RefinedC attributes and other
procedures, and drives both paths in one run.

```c
int bump(int x) { return x + 1; }
int joined(int choose) {
  int y = 0;
  if (choose) { y = bump(y); }
  else { y = bump(y); y = bump(y); }
  return y;
}
int main(void) {
  int a = joined(0);
  int b = joined(1);
  return 10*a+b;
}
```

Save the translation unit as `join.c`. From a provisioned provider checkout run

```sh
python3 scripts/corenice-diff.py join.c --comparison breakpoints \
  --corenice-bin lean_frontend/.lake/build/bin/corenice-resume --summary-json
```

Both recording directions agreed on a defined execution. The Nice path
visited nine breakpoints across six sites. The tape was empty. In a separate
in-memory inspection of the same input, both calls hit the same
`NiceNormalizedAil 7 1` site in `joined`, before the pending return. The live
four-byte object named `y` read 2 and 1 respectively. The final result was 21.

For the internal observation, use the suspension loop and live-object read
from [BreakpointDemo](../../test/CoreNice/BreakpointDemo.lean#L111), selecting
`joined`, the above site and object `y`. Take `right` from the generated
`Esseq _ _ (Breakpoint site, right)` and select the actual suspended thread
by `suspension_thread`. These were the observed shape and checks on *each*
visit, using the existing context operation:

```lean
let .Expr a (.Esseq pat (.Expr b (.Eannot dyn focus)) following) := thread.arena
  | fail "unexpected paused arena"
require "expected pending suffix" (focus == right)
let ctx : CoreNice.context := .Csseq a pat (.Cannot b dyn .CTX) following
require "exact reconstruction" (CoreNice.apply_ctx ctx right == thread.arena)
```

Both checks passed on both visits. The two full expression arenas compared
unequal. Clearing only the dynamic `Eannot` payloads made them compare equal
in a diagnostic copy. Each exact reconstruction above kept its own payload.
The two visits are different invocations, so the cause of the payload
difference is unisolated. The existing reducer explicitly carries such
annotations through strong sequencing. This gives a real case with one static
suffix and exact pause contexts without the extra call. A general join rule
and an end-to-end Caesium simulation remain open.
[Strong-sequence rule](../../../frontend/corenice/model/core_reduction.lem#L440) ·
[Context reconstruction](../../../frontend/corenice/model/core_reduction.lem#L655)

## What to park

| Candidate | Disposition |
|---|---|
| Lifetime transfers, temporary envelopes, phased assignment | Each would give a sequence of effects a new operational form. Correctness would have to preserve partial progress, original UB and choice points inside it. The valued-return/goto helper emits ordered cleanup, while the void-return rule can emit an unsequenced kill group. These are credible designs for a lower-level AIL dialect. Revisit if a concrete client needs the multi-step protocol. |
| Shared named tails or a new procedure code table | The join above can already identify the pending code and retain the exact dynamic context. The parent also has compositional saved-label lookup. Larger-scale sharing still merits consideration if measurements show residual duplication after using the present cuts. |
| Address and access recipes | Lowering knows a field or index projection. Core already contains the corresponding primitives. A useful new guarantee would have to connect the actual computed address to the source projection across evaluation. No comparably small check or stronger consumer example emerged. |
| Generated-local reference class | There is a credible producer fact for fresh temporary symbols. A local lookup shortcut would additionally need the actual linker and environment-frame discipline. Revisit if that obligation remains a recurring cost after the forwarding experiment. |
| Integer-fit guards, heap typing or disjointness | Each needs a value or memory fact beyond the producer’s syntax. A supplied proof or a different generation policy would be a separate premise. |

The earlier parent proposals are preserved at `4c0616c9b` in
`docs/2026-11-17_CoreNice-proof-burden-proposals.md`. The join rationale is
in the parent’s `docs/2026-11-06_W4-checked-join-fixtures.md`. The experiments exercise the current reducer. Assessing the fault rate
and proof savings of the proposed checks requires an implementation.

[AGENT, 2026-11-18] Prioritize a checked loop backedge, use array reversal to
evaluate its consumer benefit, and park multi-step lifetime protocols.
