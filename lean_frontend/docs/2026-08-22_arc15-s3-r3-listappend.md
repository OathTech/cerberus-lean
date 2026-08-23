# Arc 15 / S3 — R3 "the first real builder" on IntList_append (record)

Date: 2026-08-22. Provenance: [AGENT:arc15-laneA-S3] throughout.
Charter slice: S3 (R3 list rung — first non-trivial builder + walker
+ comparator; leak conjunct live; pointer-selection prototype).
Grounding: the template note
(`notes/2026-08-22_harness-statement-template.md`), S0-S2 records.
Registers: S3-E1..E6 (spec) and S3-P5/P1/P2/S3-N (proof) in the twin
registers. Worktree `cerberus-lean-spec-lab`, branch `spec-lab`;
commits `356b3f3fc` (batch 1), `016e0a06d` (batch 2), batch 3 =
proofs + registers + this record.

## Target (real external code, clean-room deps/cn, BSD-2)

`deps/cn/tests/cn/append.c` — `IntList_append`, the charter-named R3
mutator (the same file's `split` and `main` are out of this rung's
scope). CN spec verbatim (also cited, with the full CN
datatype/predicate block, in `SpecLab/ListAppendHarness.lean`):

```c
struct int_list* IntList_append(struct int_list* xs, struct int_list* ys)
/*@ requires take L1 = IntList(xs);
             take L2 = IntList(ys);
    ensures take L3 = IntList(return);
            L3 == append(L1, L2); @*/
```

with `datatype seq { Seq_Nil {}, Seq_Cons {i32 head, datatype seq
tail} }`, `function [rec] append`, `predicate [rec] IntList(pointer p)`.

CORPUS NOTE (selection reasoning, register S3-E4): the corpus's list
family is {append.c, list_rev01.c, reverse.c, mergesort*.c,
split_case.c}; it contains NO read-only list walker with functional
content — the optional read-only-walker slot is filled by the
harness's own serializer/walker (idiom-library C), not a corpus
target.

Model: `Input = (xs ys : List Int)`, heads in i32 range (CN's `i32
head` modeled directly), `Wf` adds the 8/8 capacity ceiling (the
closed-program realization bound). `modelFn = xs ++ ys` — the CN
postcondition's functional content is DEFINITIONAL
(`append_is_model = rfl`, the third collapse datapoint, S3-P5).
Codec: u16le-count-prefixed i32le elements, one array per list, in
sequence; observation = the RESULT list re-encoded with the same
codec (`expectedBytes = encodeResult (modelFn m)` — one wire
vocabulary end to end).

## How allocation was closed

append.c's own `main` builds nodes on the STACK; the harness builds
on the HEAP so teardown/leak-freedom are exercised. append.c does not
use `cn_malloc`/`cn_free_sized`, so no support-shim TU was needed:
the harness declares `void *malloc(unsigned long)` / `void
free(void*)` directly — the same closure the cn_coverage support
shims use (tests/cn_coverage/support/cn_alloc_shim_ul.c, attributed):
under `--nolibc` the Core-stdlib allocator proxies claim the C names
via std.core ailnames. In the pinned statement layer this cashes out
as: the oracle's post-linking dump references
`Cfunction(malloc_proxy)` / `Cfunction(free_proxy)` directly, and the
assembled files carry `malloc_proxy`/`free_proxy` (+
`all_values_representable_in`, reached by the pointer-conversion
checks — discovered by the fail-closed unknown-function error) in
their pinned std closure, with hand-pinned funinfo entries validated
behaviorally by the gate + both differential pipelines.

## The R3 idiom trio (the rung's new machinery)

`SpecLab/ListAppendHarness.lean` composes every template from three
reusable C fragments by plain `++` of literals (no substitution):

* **BUILDER** (`buildPhases`): the first real stream-driven heap
  constructor — walks `choices[]` and builds each list node-by-node
  (malloc per node, tail-link pointer threading so nodes land in
  stream order, i32le element codec, two's-complement into `int`
  UB-free).
* **WALKER/SERIALIZER** (`walkSerialize`): cap-guarded walk of the
  post-state list (a list longer than 16 — reachable only via
  broken/cyclic plants — returns the 253 overlong arm, keeping every
  plant variant total), re-encoding with the builder's wire codec.
* **COMPARATOR**: the generic mismatch-index comparator unchanged
  from R1/R2 (S2-E2's one-index-space lesson carried forward).

Verdict space: 0 / 1+i / 252 (allocator refusal, totality arm) / 253
(overlong walk) / 254 (malformed stream) / 255 (length divergence —
where STRUCTURAL breaks land, the S3 signature finding).

Templates: `appendTemplate` (Form 1) + wrong-link and wrong-element
plant twins + `appendForm2Template` (stdout serialization — the
head-to-head, register S3-E1) + `buildOnlyTemplate` (builder
correctness as a program: `expected = choices`) +
`appendAtTemplate` (pointer-selection prototype, register S3-E3).

## The full pipe, per the template

### (a) Differential sweeps — pipeline vs pipeline vs pure model

125 models (lengths {0,1,2,3,8}² × 5 content patterns: zeros, all
−1, ramps both ways, i32-extreme alternation; equal lengths give the
value-aliasing ys = xs shapes — the aliasing-adjacent family the
codec can express; pointer aliasing is NOT expressible by
construction, register S3-E6). Summary lines VERBATIM (per-sample
logs one line per sample, all `OK`, e.g.
`[append] model=[1,2,3|] oracle=Specified(0) lean=Specified(0)
predict=Specified(0) OK`):

```
SWEEP SUMMARY [append]: samples=125 red=0
test_speclab_list: PASS (--sweep)
BUILD SWEEP SUMMARY: samples=25 red=0
test_speclab_list: PASS (--buildsweep)
AT SUMMARY: samples=10 red=0
test_speclab_list: PASS (--at)
```

THE CAPACITY-CORNER CATCH: the FIRST build-only sweep went red at
the (8,8) corner — a real `out[]` overrun in the v1 template (66 <
the build-only observation's 68 bytes); both pipelines refused
identically (empty verdicts). Caught precisely because the sweep
includes the capacity maxima; fixed (`out[68]`), lane re-run green.
Register S3-E5 (the lane working as designed — on our own harness
this time).

### (b) Fuzz + shrink

Deterministic valid-by-construction streams (awk srand, lengths
rand%9 each + random content), Form 1, shrinker armed
(drop-last-element per list, then byte-wise toward 0):

```
FUZZ SUMMARY: requested=150 run=150 invalid_skipped=0 divergences=0 (seed=20260822)
test_speclab_list: PASS (--fuzz)
```

0 divergences — the shrinker never fired (exercised by construction
only; the plant lane is the red-path witness, as at S1/S2).

### (c) Plant tests (wrong-link / wrong-element; blind spots;
malformed)

VERBATIM (`--plant`; predictions are pure-side `linkPlantVerdict` /
`elemPlantVerdict`):

```
[plant:append-healthy] model=[1,2|3] oracle=Specified(0) lean=Specified(0) predict=Specified(0)
[plant:append-healthy-empty] model=[|] oracle=Specified(0) lean=Specified(0) predict=Specified(0)
[plant:append-healthy-bounds] model=[-2147483648,-1|2147483647] oracle=Specified(0) lean=Specified(0) predict=Specified(0)
[plant:append-wronglink] model=[1,2|3] oracle=Specified(255) lean=Specified(255) predict=Specified(255)
[plant:append-wronglink-noys] model=[-2147483648,-1,5|] oracle=Specified(255) lean=Specified(255) predict=Specified(255)
[plant:append-wrongelem] model=[1,2|3] oracle=Specified(3) lean=Specified(3) predict=Specified(3)
[plant:append-wrongelem-neg] model=[-1|2147483647] oracle=Specified(3) lean=Specified(3) predict=Specified(3)
[plant:append-wronglink-emptyxs-blindspot] model=[|7] oracle=Specified(0) lean=Specified(0) predict=Specified(0)
[plant:append-wronglink-singleton-blindspot] model=[5|7] oracle=Specified(0) lean=Specified(0) predict=Specified(0)
[plant:append-wrongelem-emptyxs-blindspot] model=[|7] oracle=Specified(0) lean=Specified(0) predict=Specified(0)
[plant:append-short-first-list] model=[2,0,1] oracle=Specified(254) lean=Specified(254) predict=Specified(254)
[plant:append-over-cap] model=[9,0] oracle=Specified(254) lean=Specified(254) predict=Specified(254)
[plant:append-missing-second-prefix] model=[1,0,1,2,3,4] oracle=Specified(254) lean=Specified(254) predict=Specified(254)
[plant:append-trailing-junk] model=[0,0,0,0,9] oracle=Specified(254) lean=Specified(254) predict=Specified(254)
PLANT SUMMARY: wrong-link plant RED in the 255 length arm (structural-break signature); wrong-element plant RED at predicted index 3; healthy + blind-spot twins green as predicted; malformed twins at 254
```

The wrong-link plant (`xs->tail = ys`) breaks STRUCTURE — its count
diverges before any content index, landing in the 255 length arm
(the S3 signature finding); it also ORPHANS |xs|−1 nodes, arming the
leak red lane below. The wrong-element plant (`xs->head ^= 1`; XOR
so the plant is UB-free at every input) breaks CONTENT — verdict 3 =
element 0's low wire byte. Blind spots documented + demonstrated
green (wrong-link at |xs| ≤ 1 — the singleton case makes the plant
accidentally CORRECT; wrong-element at xs = []). Theorem face:
`SpecLabProofs.appendLinkPlantClaim_refuted_of_run` /
`appendElemPlantClaim_refuted_of_run` (kernel-checked via the
rung-independent `harnessRunsTo_exclusive`); the gate exe checks the
refuting verdicts executably today.

### (d) Form 2 head-to-head (comparator-in-C vs
serialize-then-judge-in-Lean, register S3-E1)

VERBATIM (`--form2`, libc mode, stdout asserted against the pure
`render3` prediction):

```
[form2] model=[1,2|3] OK
[form2] model=[|] OK
[form2] model=[-1|2147483647] OK
[form2] model=[0,0|0] OK
[form2] model=[-2147483648|] OK
[form2] model=[1,2,3,4,5,6,7,8|9,10,11] OK
FORM2 SUMMARY: samples=6 red=0
test_speclab_list: PASS (--form2)
```

Verdict (register S3-E1): Form 1 stays the default; Form 2's
serialize-then-judge form gets simpler harness C (no judgment in the
program) and a genuinely readable witness at list sizes, at the
unchanged costs (libc mode, the S1-E1 newline discipline, string
statement).

### (e) The pinned statement layer + kernel theorems

Pinned fixtures (tests/speclab/):
`applist_{a,b,d,c}.{c,core}` (wire bytes 1..12 / 101..112 / 201..212
/ out-of-trio boundary patterns [0,−1]++[INT_MIN]) +
`applist_{linkplant,elemplant,build}.{c,core}` (instance a). Oracle
exec verdicts VERBATIM at pinning: `Specified(0)` ×4 + build,
`Specified(255)` (link plant), `Specified(3)` (elem plant). Term
layer: `speclab-emit-list` → `SpecLab/ListAppendCore.lean`
(parametric `appendMainParamDecl b0..b11` — 12 params / 24 sites,
expected[] derived; plant + build mains verbatim; the `struct
int_list` TAG DEFINITION — first rung with nonempty tagDefs; the
allocator-proxy std decls). New emitter surfaces, each added loudly
per the fidelity contract: NULL pointer values, PtrEq/PtrNe/
PtrWellAligned memops, the Alloc0 action, tag-def emission.
SYMBOL-NUMBERING-COUPLING finding (register S3-E6): the build-only
TU's different main shifts the (textually identical) target's fresh
numbering — per-TU pinning, not per-decl.

Gate exe VERBATIM (`test_speclab_list.sh --gate`):

```
  PASS  drift gate: re-emitted module byte-identical
  PASS  param pin [a]: appendMainParamDecl == parsed main
  PASS  param pin [b]: appendMainParamDecl == parsed main
  PASS  param pin [d]: appendMainParamDecl == parsed main
  PASS  param pin [c]: appendMainParamDecl == parsed main
  PASS  exec [append a]: Specified(0)
  PASS  leak [append a]: final allocations = 1
  PASS  exec [append b]: Specified(0)
  PASS  leak [append b]: final allocations = 1
  PASS  exec [append d]: Specified(0)
  PASS  leak [append d]: final allocations = 1
  PASS  exec [append c]: Specified(0)
  PASS  leak [append c]: final allocations = 1
  PASS  exec [append link-plant]: Specified(255) — structural break in the length arm; +1 = the orphaned node
  PASS  leak [append link-plant]: final allocations = 2
  PASS  exec [append elem-plant]: Specified(3) — the wrong-element plant is RED in-logic at element 0
  PASS  leak [append elem-plant]: final allocations = 1
  PASS  exec [build-only]: Specified(0) — builder-walker round trip through the heap
  PASS  leak [build-only]: final allocations = 1
ListGateTest: ALL PASSED
```

(The gate needed the ambient CerbTags set/reset — first speclab rung
with structs; Main.lean/relsem-T4 precedent, register S3-E6.)

STATEMENTS (SpecLab lib, statement-TCB-gated; exact quantification):

* `ListAppend.AppendSampleStatement` — ∀ m in the EXPLICIT 4-element
  sample set (the four pinned (2,1)-shape models above), every runND
  outcome of `drive (appendFileOf m) … ["cmdname"]` is Active
  Specified(0). FINITE sample quantification, labeled; the
  fixed-shape family-∀ (256¹² instances via the parametric term) is
  the exec campaign's registered endpoint (S3-N).
* `ListAppend.AppendSampleStreamStatement` — the same over the 4
  encoded STREAMS (full two-list codec) through the stream-indexed
  file.
* `ListAppend.BuildOnlyStatement` — THE BUILDER-CORRECTNESS
  OBLIGATION, stated (the build-only harness runs to 0: the heap
  structure the builder constructs reads back as exactly the encoded
  model; pure mirror = `decodeInput`, the free-generator reading).
  Proof parked with the exec-equation campaign per the S1/S2
  pattern — statement side complete.
* `ListAppend.AppendLinkPlantHealthyClaim` /
  `AppendElemPlantHealthyClaim` — the claims the plants refute.

## The leak conjunct — LIVE (with one honest gap)

Probe result (task item 2): the batch output surface (`Defined
{value, stdout, stderr, blocked}`) does NOT carry allocation state —
but the exec outcome itself does: `CerbND.runND` returns the final
`driver_state`, whose `layout_state : CerbMem.MemState` carries
`allocations : Std.TreeMap Int Allocation` (Kill ERASES). The
template note's sanctioned scalar form is therefore stateable TODAY
with zero semantics-surface changes:

* `ListAppend.HarnessFinalAllocs f n` — every outcome's final
  allocation-map size is n (a single scalar fact about the final
  state; no contents/shape vocabulary).
* `driverBaseline = 1`, DISCOVERED EXECUTABLY and pinned: the
  driver's errno object (never freed by design). The argv
  allocations do NOT appear — `main(void)` has no (argc, argv)
  params, so `prepare_main_args`'s allocation arm never fires. The
  gate re-checks the number on every run (startup-footprint drift
  gate).
* `AppendSampleLeakStatement` / `BuildOnlyLeakStatement` — healthy
  instances end at the baseline: the harness owns no heap after
  teardown (interpreter-only leak-freedom, the ratified conjunct).
* `LinkPlantLeakClaim` — the wrong-link plant ends at baseline + 1
  (the orphaned node), EXACTLY as the pure layer predicts
  (`linkSkip_leaks`: |xs| − 1 = 1 at the pinned instance); measured
  by the gate (leak [append link-plant]: 2). Kernel refutation:
  `SpecLabProofs.finalAllocs_exclusive` +
  `linkPlantLeak_refutes_leakFree` — the leak observable is
  anti-vacuous at the logic level.

THE GAP (parked-with-price, register S3-N item 3): the
ORACLE-DIFFERENTIAL leg. The OCaml driver's batch output prints no
allocation census, so the leak conjunct is Lean-side measured,
pure-predicted, and logic-refutable — but not oracle-compared.
Missing precisely: a `--batch` final-allocation-count line in the
oracle (driver batch printer + concrete memory model's allocation
map size; est. S, fork-side; upstream-tray candidate). Deliberately
NOT built this slice (the semantics/oracle surface is out of this
worker's write scope).

## Kernel theorems at S3 (cones VERBATIM, in-build pins)

38 new pins in `SpecLabAudit.lean` + 5 in `proofs/SpecLabProofs.lean`
(`#guard_msgs`, captured verbatim; doctored-pin plant test run both
directions at S3: doctored `canonical_list` pin → build FAIL; revert
+ rebuild → green). Abridged to the headline theorems:

```
'SpecLab.Codec.decode_encode_arrayU16_of' depends on axioms: [propext, Quot.sound]
'SpecLab.ListAppend.canonical_list' depends on axioms: [propext, Quot.sound]
'SpecLab.ListAppend.model_forall_iff_stream_forall' depends on axioms: [propext, Quot.sound]
'SpecLab.ListAppend.append_is_model' does not depend on any axioms
'SpecLab.ListAppend.alloc_free_balance' depends on axioms: [propext]
'SpecLab.ListAppend.linkSkip_leaks' depends on axioms: [propext, Quot.sound]
'SpecLab.ListAppend.appendFileOfStream_encode' depends on axioms: [propext, Classical.choice, Quot.sound]
'SpecLab.ListAppend.append_sample_model_iff_stream' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'SpecLab.ListAppend.AppendSampleStatement' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'SpecLab.ListAppend.BuildOnlyStatement' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'SpecLab.ListAppend.HarnessFinalAllocs' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'SpecLab.ListAppend.AppendSampleLeakStatement' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'SpecLab.ListAppendCore.appendMainParamDecl' does not depend on any axioms
'SpecLabProofs.appendLinkPlantClaim_refuted_of_run' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'SpecLabProofs.linkPlantLeak_refutes_leakFree' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
```

(Full discipline unchanged: classical-trio subsets pure-side;
`runEffectful` — the declared boundary — exactly where a statement
quotes the drive substrate, the leak statements included; AST terms
axiom-free. No sorryAx, no ofReduce* anywhere. Note: four wrapped
4-element cone messages appear in multi-line `#guard_msgs` form in
the audit files; single-line spellings above are the same sets.)

The EXEC EQUATIONS at the concrete streams remain PARKED-PRICED
(S1-P1 refreshed by S3-P1: applist main ≈ 4,270 Core lines, ~26x the
largest walked fixture; new law surfaces incl. the first Alloc/Kill
lifecycle and the first RECURSIVE callee).

## Proof economics (S3-P5 third grading)

Marginal per-target pure content ≈ 34 theorem+proof lines / 13
target LOC ≈ 3/LOC — the trend across rungs: 7/LOC (R1) → 3/LOC
(R2) → ~3/LOC (R3), with the library thickening (conditional array
round trip joins Canonical as paid-once codec algebra). The heap
structure never appears in pure land; the List-valued model cost
nothing over scalars/bytes. Full grading in the proof register.

## Gates (all in-build / fail-closed, this slice)

* Statement gate: grep floor 15 files clean + in-build twin now
  walking 26 statements (wrapper-hole negative test still
  detecting); axiom pins plant-tested both directions.
* Drift: emitter re-emission byte-identical; append param pins ×4
  (incl. out-of-trio); in-Lean exec ×7 + leak ×7.
* Validation battery at each commit: speclab plain `lake build`
  (capped) green; speclab-test 37/37; `test_speclab.sh`
  --selftest/--plant PASS; `test_speclab_divmod.sh` --plant/--gate
  PASS; `test_speclab_bytearr.sh` --plant/--gate PASS (no S1/S2
  regression); `test_speclab_list.sh` all seven lanes PASS;
  `test_unit.sh` `Total: 7 passed, 0 failed`.

## Parked / follow-ons (priced)

* The exec-equation campaign: unchanged (L, after Lane B/T5); R3
  adds the fixed-shape family-∀ (256¹² via `appendMainParamDecl`)
  as a third natural endpoint, and the recursion surface suggests
  the campaign reaches R3 last (S3-P1).
* Shape-parametric ∀: the R2 wall + the recursion-depth dimension
  (S3-N item 2) — deliberately not attempted.
* The leak conjunct's oracle leg: an oracle `--batch`
  allocation-census line, est. S, fork-side, upstream-tray
  candidate (S3-N item 3).
* Pointer-selection statement family: deferred to R4 (where path
  selection is the point).
* `.s3-probes/` scratch deleted before the batch-3 commit (S0
  convention).
