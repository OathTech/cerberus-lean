# Arc 15 / S5 — THE CN-VS-US COMPARISON RECORD

Date: 2026-08-23. Provenance: [AGENT:arc15-laneA-S5]. Charter: S5
("the CN-vs-us comparison record: modular contracts vs closed-program
observation + the shared generators-as-parsers substrate"). Sources:
the per-rung comparison-column entries in the spec register
(S1-E3, S2-E3, S3-E4, S4-E4, S5-E3) + the rung records; CN specs
quoted VERBATIM from deps/cn/tests/cn (BSD-2, clean-room corpus —
the tutorial corpus remains banned). This record is honest in both
directions by construction: each section states what the comparison
costs us as plainly as what it buys.

## 1. The structural distinction (stated per the doctrine)

CN verifies MODULAR, PER-FUNCTION CONTRACTS: a `requires`/`ensures`
pair quantifies over every caller-supplied state satisfying the
precondition's ownership resources, and the verifier discharges each
function against its contract once, composing through callee
contracts and verified loop invariants. Statements live in a
resource logic (separation-logic `take`/ownership vocabulary).

We verify CLOSED-PROGRAM OBSERVATIONS: the harness template
([the design note](../../notes/2026-08-22_harness-statement-template.md))
builds the input state by ordinary C from a compiled-in choice
stream, calls the target, converts the post-state to observables by
ordinary C, and the theorem quantifies over the pure MODEL indexing
the program family — every instance a runnable, oracle-differential,
fuzzable program. Statements never mention memory; resource
vocabulary is banned from statements by a build gate (the escape
hatch is a per-instance operator decision, unexercised through five
rungs).

Consequences, honestly stated:

* CN's ∀ is over CALLER STATES (any heap satisfying the resources);
  ours is over BUILDER-REACHABLE states (any output of the harness's
  constructor on any stream). For byte-buffer contents these
  coincide (the R2 byte-blaster reaches every content — the
  containment note); for structured heaps ours is the strictly
  smaller and PNVI-robust set (no exotic metadata/aliasing corners),
  and specific gaps are registered where they bite (S3-E6:
  pointer-aliased list inputs are outside our quantification, where
  CN's separation discipline makes non-aliasing a stated resource
  fact).
* CN's `requires` can be SMALLER than the true domain because the
  verifier carries UB obligations implicitly; our `Wf` must surface
  the whole realizable domain or the instance is a UB program
  (harnesses-are-programs). See §3.1 — this produced a real finding
  at R1.
* CN's guarantees are per-function and compose; ours are per-program
  and OBSERVED — end-to-end against the C semantics itself, with
  the oracle differentially in the loop for every instance. The
  kernel-checked layer today is the pure models, the model↔stream
  bridges, and the conditional refutation schemas; the exec
  equations that would make the per-program claims unconditional
  kernel theorems are parked-priced with the exec-equation campaign
  [audit-1 MAJOR-1 precision].

Both directions are load-bearing for the north star: at Linux scale
we need CN-style modularity IN THE PROOF LAYER (P2's representation
predicates and callee triples — "Iris party in the back") while the
STATEMENTS stay in the boring observable form the operator can read
at scale. The S4-E1 experiment is the template for that division:
the frame/locus decomposition exists, kernel-checked, in the pure
layer — and stays out of the statement.

## 2. The shared substrate (generators as parsers)

Design lineage (template note §lineage): our `decode : Stream → M`
IS a free generator in the Goldstein-Pierce sense (industrially:
Hypothesis's byte-stream IR), `encode` its printer,
`decode ∘ encode = id` the round-trip law, and the builder-
correctness obligation (`BuildOnlyStatement`, R3/R4) the
kernel-verified analogue of generator soundness. CN's own runtime
test generator (Bennett) takes the same generators-as-parsers
perspective — so the two tools share a substrate at the INPUT layer
even though the verification layers differ structurally. Practical
transfers already banked: Hypothesis-style shrinking (every lane's
fuzz mode carries a byte-wise shrinker producing minimal
counterexample PROGRAMS — armed at all five rungs, never fired), and
the free-generator reading of the R4 tree codec (presence-bit
pre-order code = a recursive generator, fuzz samples its input space
directly).

## 3. The concrete per-example column (five rungs)

### 3.1 R1 division/mod — the implicit-UB-side-condition finding

```c
int division (int x, int y)
/*@ requires y != 0i32;
    ensures return == x/y; @*/
```

CN requires only `y != 0i32`. Our `Wf` must ALSO exclude
`x = INT_MIN ∧ y = -1` (C11 6.5.5p6; the elaborated
`catch_exceptional_condition` guard makes that instance a UB
program). CN discharges the corner through its own UB
side-conditions, NOT the written `requires` — so the written
contract understates the callee's true domain, and the reader must
know CN's implicit obligations to read it correctly. The
closed-program form cannot understate: the domain is in `Wf`, in
the open (`modelDiv_inRange` is its pure mirror). Spec register
S1-E3; the standing shape of this column.

### 3.2 R2 get_from_arr — the ownership-only-ensures finding

```c
char get_from_arr (char *in_arr)
/*@ requires take IA = each (i32 j; 0i32 <= j && j < 10i32)
  {RW<char>(in_arr + j)};
    ensures take IA2 = each (i32 j; 0i32 <= j && j < 10i32)
  {RW<char>(in_arr + j)}; @*/
```

The CN `ensures` is OWNERSHIP-ONLY — it does not constrain the
return value at all (the file tests ownership machinery; CN could
state the value and chose not to). Our statement is strictly
stronger functionally: `ret = arr[4] ∧ array unchanged`, both
checked bytes-for-bytes. First corpus point where the harness spec
EXCEEDS the CN spec's functional content. Honest note: this is a
fact about one test file's intent, not about CN's expressiveness.
(memcpy, same rung: CN's `each (k) {dstEnd[k] == srcStart[k]}` +
`srcEnd == srcStart` is full functional content; our addition there
is only the capacity `Wf` — modular contracts quantify `n` free,
we pay a concrete-N realization ceiling. Register S2-E3.)

### 3.3 R3 IntList_append — the closest mirror + the leak column

```c
struct int_list* IntList_append(struct int_list* xs, struct int_list* ys)
/*@ requires take L1 = IntList(xs);
             take L2 = IntList(ys);
    ensures take L3 = IntList(return);
            L3 == append(L1, L2); @*/
```

The closest correspondence of the arc: CN's `seq` datatype ≅
`List Int`, CN's recursive `append` ≅ `List.append`, and our model
collapse (`append_is_model = rfl`) mirrors the postcondition
directly. Our `Wf` adds the realization bounds (8/8 caps, i32 heads
— the latter CN carries in its datatype). LEAK-FREEDOM: CN gets it
implicitly and MODULARLY from resource accounting (returning exactly
`take L3 = IntList(return)` means exactly the result's cells are
owned); we state it as an outcome-level scalar (final allocation map
at driver baseline) — per-program and observable, with the plant
demonstration below that CN's form doesn't have. Register S3-E4.
The pointer-aliasing honesty note (S3-E6) sits on our side of the
ledger: `ys = xs` VALUE-aliasing is in our sweep; POINTER-aliased
inputs are expressible in neither (CN: excluded by separation;
us: unreachable by the two-builder codec) — but CN states the
exclusion, we register it.

### 3.4 R4 rotate_right — the column inverts

No CN spec exists (the corpus has no rotation; fresh authorship,
struct shape from tree_rev01.c). The harness statement is the ONLY
spec, and everything R1-R3 recorded as "beyond CN" (capacity Wf,
leak conjunct, closed-program observation) is here the whole story.
What a CN treatment would add back: shape-parametric ∀ via the
`Tree` predicate's recursion (exactly our registered parametric
wall) and modular framing — whose pure shadow we DID prove
(`rotateAt_frame`), kept in the proof layer per S4-E1. Register
S4-E4.

### 3.5 R5 swap_pair + lookup_size_shift — the seed pair

swap_pair (spec in §record): CN's ensures IS functional post-state
content (`pairEnd[0] == pairStart[1]; pairEnd[1] == pairStart[0]`)
and our model mirrors it definitionally (`swap_post = ⟨rfl, rfl⟩`).
The interesting asymmetries: (i) our Wf is VACUOUS — u64 pairs are
the full domain, so the model-∀ carries no side conditions at all,
whereas CN still needs the ownership `requires`; (ii) the plant
column — the lost-update bug's blind set is a KERNEL THEOREM on our
side (`swapPlant_blind_iff`: invisible ⟺ a = b), a class of
meta-statement (about the SPEC's discriminating power) that has no
CN analogue; (iii) CN's `/*@ trusted; @*/` main is exactly the
closed-program part CN does NOT check — the part that is our whole
object.

lookup_size_shift: CN's `cn_function` mechanism BINDS the C function
to a spec function derived from the body — the modelFn idea with the
arrow reversed. CN trusts its translation of the body and gains a
pure symbol for contracts downstream (`f`'s `return < 1000i32` is
discharged through it); we AUTHOR `lookupSizeShift` independently
and check it against execution differentially + in-logic (and get
`f_model_lt_1000` by one `decide` in pure land). The two directions
have different trust shapes: cn_function cannot be wrong about the
body but says nothing an execution would check; our model can be
wrong but every disagreement is a red lane. Register S5-E3.

## 4. What each proves that the other doesn't

CN proves, that we don't (today):

* PER-FUNCTION ∀-CALLER CONTRACTS — quantification over all states
  satisfying the resources, composed modularly across call graphs;
  our statements quantify explicit finite sample sets (labeled),
  with family-∀ waiting on the exec-equation campaign and
  shape-parametric ∀ on the registered T5-class walls.
* VERIFIED LOOP INVARIANTS as first-class contract elements (the
  memcpy `inv` clause) — our loops are handled by execution, not
  invariant discharge, until P4/T5 tech runs.
* SEPARATION FACTS AS STATEMENTS (non-aliasing, ownership transfer)
  — deliberately outside our statement vocabulary (governed escape
  hatch, unexercised).

We prove, that CN doesn't:

* KERNEL-CHECKED END-TO-END AGAINST THE C SEMANTICS ITSELF: the
  statement's `drive` is the production interpreter on the elaborated
  Core of the real program text, cones pinned to
  [propext, runEffectful, Classical.choice, Quot.sound]; CN's
  verdict passes through its (unverified) elaboration, solver stack,
  and cn_function translation.
* CONCRETE RUNNABILITY OF EVERY QUANTIFIED INSTANCE + the ORACLE
  DIFFERENTIAL: each statement instance is a closed program run
  bit-for-bit on two independent pipelines (688 differential points
  across the arc's lanes), fuzzable with minimal-counterexample
  shrinking.
* PLANT-DEMONSTRATED ANTI-VACUITY: every rung ships deliberately
  broken targets that go red differentially AND are refutable
  in-logic (`harnessRunsTo_exclusive` family), with blind spots
  documented, demonstrated green, and at R5 kernel-characterized.
  CN has failing-test .error files, but no per-spec demonstration
  that the spec would catch the specific bug class.
* LEAK OBSERVABLES as explicit statements with a two-class plant
  separation (R4: broken-and-leaking vs broken-leak-free are
  distinguished observables; a verdict-only OR resource-implicit
  form shows one bit less).

## 5. Stream-corpus comparability

Because both tools' input layers are generators-as-parsers (§2), a
choice-stream corpus is IN PRINCIPLE portable across them: our
streams decode to models that could instantiate CN test-generator
runs, and CN generator seeds could be re-encoded as our streams —
giving a shared regression corpus for the same target with two
independent verdict channels (their runtime checker, our
differential pair). Not built this arc (no CN toolchain runs in this
repo); recorded as the natural bridge experiment when the corpus
campaign (the renumbering-unblocked differential lane over
deps/cn/tests/cn) is scheduled. The cn_coverage lane (213/213
magic-comment-filtered files through both our pipelines) already
gives the target-side substrate.

## 6. Summary row

Modular contracts state more per function and compose; closed-
program observation trusts less and demonstrates more per claim.
The arc's five rungs found no case where the two forms CONFLICT —
every CN postcondition with functional content collapsed to a
definitional fact about our model (five collapse datapoints), which
is evidence the boring-spec form loses nothing at this scale, and
the two founder-level gaps (parametric ∀, modular framing) are
precisely the priced walls (T5/exec campaign; P2 back-room) rather
than statement-form limitations.
