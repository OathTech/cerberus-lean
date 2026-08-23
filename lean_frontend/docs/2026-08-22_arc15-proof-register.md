# Arc 15 — THE PROOF-STYLE REGISTER

Status: CLOSED at S5 (2026-08-23) — final-grades summary below; the
speculative Linux-scaling memo is §memo at the end of this file
(compressed copy in `2026-08-23_arc15-results.md`).

## S5 SUMMARY HEAD — the proof-style final grades

Grades are the LATEST grading per style (S4/S5 refresh), rubric
(a)–(f) per the charter, 1-5, SPECULATIVE per the charter's bonus
framing. "—" = not attempted (no grade without evidence).

| Style | (a) lines/LOC | (b) re-pin | (c) mech. | (d) elab. | (e) C-shape | (f) parallel | Status |
|---|---|---|---|---|---|---|---|
| P5 pure-transport | 4 | 5 | 3 | 5 | 5 | 5 | **the arc's workhorse — graded on five rungs of landed theorems** |
| P1 walker/certificate | 2 | 4 | 3 | 4 | 5 | 4 | parked-priced L (the exec-equation campaign, after Lane B/T5); re-priced every rung on measured Core sizes |
| P2 Iris WP + adequacy | — | — | — | — | — | — | assessed 3×, not attempted (consumes P1's equations); natural targets recorded: R3 append (recursion), R4 rotation (representation predicates) |
| P3 trace/replay | — | (5, inherited arc-11) | — | — | — | — | applicable the day P1 runs; what makes its re-pins affordable |
| P4 direct invariant/iter_compose | — | — | — | — | — | — | objects exist since R2 (target loops); gated on T5 tech; the CN `inv` column gives invariant families for free |

THE P5 TREND (marginal per-target pure theorem+proof lines per
target LOC; derived, method in each grading): **7 (R1) → 3 (R2) → 3
(R3) → 8 (R4) → ~5 (R5: 2 targets combined; ~2.7 excluding the
pair-codec algebra, which is library-shaped)**. The R4 bend has a
measured STRUCTURAL reason, not a scaling failure: the first
RECURSIVE model costs a path-generalizing induction per preservation
fact, ×3 locus operations (healthy + two plants) at ≈ 2.5/LOC each —
the per-OPERATION rate stays flat at the R2/R3 level; what grew was
the operation count. R5 confirms from the other side: with the
library mature, two new targets' CN-postcondition content cost ZERO
marginal lines (both collapse to rfl — five collapse datapoints
across the arc), and the residue is codec algebra paid once per
layout. The trend's honest reading: pure-transport marginal cost is
FLAT-PER-OPERATION and dominated by (i) codec algebra per new wire
layout and (ii) induction count per recursive model — both
library-amortizing, neither growing with target LOC.

Original register header follows.
Charter: `2026-08-22_arc15-spec-lab-charter.md`, "Proof-style
exploration" (bonus objective, [USER 2026-08-22]): per rung, where
affordable, discharge the same obligation in contending styles and
grade each — speculatively — against the Linux-scaling rubric. The
register closes with the speculative Linux-scaling memo.

Contending styles (initial slate; workers may add):
  P1 walker/certificate  P2 Iris WP + adequacy  P3 trace/replay-driven
  P4 direct invariant-family/iter_compose  P5 pure-transport division
  of labor

Rubric per graded entry (1-5 + a sentence of evidence each):
  (a) proof-lines per C-line + growth trend
  (b) re-pin robustness (cost when the target C changes)
  (c) mechanization fraction
  (d) elaboration pressure (budget-bump pushers are disqualified —
      heartbeat doctrine; note early)
  (e) C-shape realism (pKVM buddy / WireGuard shapes as mental target)
  (f) parallelizability

## Entries

All S1 grades are SPECULATIVE per the charter ("no rung is obligated
to achieve scale; the deliverable is evidence-graded judgment").
Target C: `division` + `mod` = 8 LOC (bodies + braces, derived);
kernel-instance harness C ≈ 30 LOC.

### S1-P5 — pure-transport division of labor (THE R1 WINNER)

What landed kernel-checked ENTIRELY in pure land: the codec
round-trip + canonicity laws (8 theorems), the model-∀↔stream-∀
bridges (i32 abstract + i8 concrete file-level), the CN
postconditions' pure content (`divmod_reconstruction`,
`modelMod_bound`, `modelDiv_inRange/modelMod_inRange` — the
UB-freedom mirror of the Wf corner), and the verdict-exclusivity /
plant-refutation schemas (`SpecLabProofs.harnessRunsTo_exclusive`,
`plantClaim_refuted_of_run`). ONE bridge obligation remains
per-family (the parked exec equation): everything else about the
property transports through `decode∘encode` and the statement
algebra.

(a) proof-lines/C-line: 3 — ~24 lines of pure theorem+proof per
    target LOC (derived: DivMod.lean 397 + DivModFiles.lean bridge
    section ≈ 70 + SpecLabProofs 101, over 8 target LOC — but the
    codec/bridge layer is REUSABLE library, not per-target; the
    per-target marginal (model + P5 lemmas) is ≈ 60 lines ≈ 7/LOC).
(b) re-pin robustness: 5 — pure lemmas mention no program terms; a
    target C change re-pins NOTHING here (evidence: the block-scope
    template change touched zero pure proofs).
(c) mechanization: 3 — omega/simp discharge nearly everything, but
    lemma STATEMENTS are hand-written.
(d) elaboration pressure: 5 — all proofs at default budgets,
    milliseconds each.
(e) C-shape realism: 3 — scalars trivially pure-transportable; the
    open question (structs/heaps) is exactly what R2-R4 test.
(f) parallelizability: 5 — per-function pure models are independent
    by construction.
Evidence sentence: every S1 kernel theorem except the parked exec
equations was discharged in pure land at default budgets, and the
one impure obligation is a single per-family bridge.

### S1-P1 — walker/certificate (spike run, PARKED-PRICED)

Attempted: relsem require + proofs lib integration (GREEN — the
walker/kits import and build against speclab in one lakefile step);
entry-pattern study on the concrete (7,2) instance. NOT closed: the
exec equation `app (drive (divmodI8FileOf ⟨7,2⟩) …) … = (NDactive r,
st')`. Blocking findings (measured): the walker's entry pattern
(T5Prefix `entry5_walk`) presupposes per-fixture dnms wrappers +
state avatars + segment lemmas (none exist for speclab fixtures);
the i8 instance's Core is 1262 lines vs the T5 fixture's 172 (79
rounds, 45 walker-automatic at k=0 — T5 itself still parked); and
FOUR law surfaces the slate never exercised: main-driven `drive`
prefix, `Eccall` proc-call rounds, block-scope array `store_lock`
init, `Ememop`/PtrValidForDeref. Whole-run `app_defeq`/rfl is banned
(D7). PRICE: L — its own slice, sequenced after T5 lands (Lane B);
the parametric `mainParamDecl` then upgrades sample-∀ to family-∀ in
the same campaign (the symbolic-initializer route, statement side
already built).

(a) proof-lines/C-line: 2 (projected 50-150/LOC at R1 from the T2
    precedent ~700 lines for a 1-LOC target, pre-walker; walker
    amortizes but per-fixture scaffolding dominates at this size).
(b) re-pin robustness: 4 — arc-11 replay is the benchmark; once a
    walk exists, re-pin ≈ 30s class.
(c) mechanization: 3 — 45/79 = 57% auto on the nearest measured
    instance; novel surfaces start at 0% until laws are registered.
(d) elaboration pressure: 4 — ledgered per-candidate budgets, no
    ambient raises (the walker's design honors the doctrine).
(e) C-shape realism: 4 — the walker is the only current route to
    real memory/call shapes at kernel grade.
(f) parallelizability: 4 — per-function walks are independent once
    the law table covers the shared surfaces.
Evidence sentence: integration is green and the campaign is
well-defined, but the measured instance is 7x the largest walked
fixture with four unregistered law surfaces — a slice, not a step.

### S1-P2 — Iris WP + adequacy (assessed, not attempted)

The WP route consumes the SAME app equations the walker produces
(T1-T4: `t?_of_app_eq` = one WP lift + adequacy discharge); with the
equations parked there is nothing for WP to add at R1 — its value
begins where FRAMING/modular callee contracts matter (R3+: the
harness calling two targets through real call machinery is the first
place a callee-spec + frame beats a monolithic walk). Deferred to
the rung where it can differentiate, per charter ("where
affordable"). No grade — no evidence yet.

### S1-P3 — trace/replay-driven (not applicable yet)

Replay accelerates an EXISTING walk (record → fingerprinted
re-check); with no S1 walk there is nothing to record. Noted: the
moment S1-P1's campaign runs, replay is what makes its re-pins
affordable — (b)-grade 5 by arc-11 measurement (~2.6s checked
replays), inherited, not re-measured here.

### S1-P4 — direct invariant/iter_compose (deferred, per scoping)

The TARGETS are loop-free (single-expression bodies) — P4 has no
object at R1, as the S1 scoping anticipated. The HARNESS's loops
(looped i32 template: builder/encoder/comparator loops) are concrete
≤8-iteration loops that the kernel-instance template deliberately
unrolls away; the first real P4 object is R2's byte-blaster loop
(fixed length) and T5-style symbolic length after Lane B lands.

## The Linux-scaling memo

(close-out deliverable — not yet written)

All S2 grades are SPECULATIVE per the charter. Target C: naive_memcpy
= 9 LOC + get_from_arr = 8 LOC (bodies + braces, derived, CN
annotations excluded); harness C ≈ 55 LOC (memcpy) / 35 LOC (getarr).

### S2-P5 — pure-transport at a List-valued model (the R1 winner,
re-graded)

What landed kernel-checked entirely in pure land at R2: the Canonical
codec layer (6 theorems in Codec.lean, 139 lines — parametric in the
element codec, REUSABLE), the memcpy model-∀↔stream-∀ bridge through
the full u16-prefixed codec + the file-level bridge
(`memcpyFileOfStream_encode`, `memcpy_sample_model_iff_stream`), the
getarr identity-codec bridge (zero codec laws consumed — measured
contrast), the comparator's soundness+completeness
(`verdictOf_eq_zero_iff`, ~45 lines, idiom-library law: verdict 0 ⟺
observation equality — every Form 1 statement's anti-vacuity, once),
and THE COLLAPSE FINDING: the CN postconditions' functional content
for a verbatim copy is DEFINITIONAL (`src_unchanged`/`dst_copied` are
`rfl`) — for byte-verbatim properties the entire property weight sits
in the exec bridge, and pure land holds only codec + comparator
algebra.

(a) proof-lines/C-line: 4 — per-target marginal pure content ≈ 25
    lines / 9 LOC ≈ 3/LOC (memcpy) and ≈ 10 lines / 8 LOC (getarr);
    the 180-line codec/comparator layer is library, amortizing
    ACROSS rungs (S1's Canonical recommendation was consumed here
    exactly as priced). Trend across R1→R2: marginal per-target
    pure cost FELL (7/LOC → 3/LOC) as the library thickened.
(b) re-pin robustness: 5 — unchanged (no pure lemma names a program
    term; the R2 template changes during development touched zero
    pure proofs).
(c) mechanization: 3 — unchanged (simp/omega/induction discharge;
    statements hand-written).
(d) elaboration pressure: 5 — all pure proofs at default budgets,
    milliseconds. (The BUDGET EVENT of this rung was in the pinned
    TERMS, not proofs — see S2-P1.)
(e) C-shape realism: 4 (up from 3) — real buffers, interior
    pointers, a mutating loop, and a frame clause all transported;
    the List-valued model cost nothing over scalars. Heap SHAPES
    (list/tree nodes) remain the open R3/R4 question.
(f) parallelizability: 5 — unchanged.
Evidence sentence: every R2 kernel theorem except the parked exec
equations lives in pure land at default budgets, and the rung's new
pure obligations were mostly library (paid once).

### S2-P1 — walker/certificate (re-priced at R2; not attempted —
the wall is parked, per scoping)

Measured grounds refreshing the S1-P1 price: memcpy_a.core = 2,092
lines (naive_memcpy 171 + main 1,920) and getarr_a.core = 1,208 vs
divmod i8 1,262 and the T5 fixture's 172 — the R2 flagship instance
is ~11x the largest walked fixture. NEW law surfaces beyond S1's
four: `SeqRMW` rounds (harness `i++`), CALLEE-side loop save/run
rounds (the target itself loops — S1's loops were harness-only and
unrolled away; R2 is the first rung where the walk REQUIRES T5 loop
tech in the callee), and the multi-buffer Create/store_lock init
family. The statement side is walk-ready (parametric
`memcpyMainParamDecl` = the symbolic-initializer route's input).
Price: unchanged L, sequenced after Lane B/T5; grades unchanged from
S1-P1 except (e) 4→5 (the walker remains the only kernel route to
these shapes).

### S2-P4 — direct invariant/iter_compose (object now exists, still
gated)

The R2 harness loops (builder byte-blast, canary fill, readback,
comparator — concrete ≤16 iterations) and the target's copy loop are
the first real P4 objects, exactly as S1-P4 anticipated. Not
attempted this rung (same T5 gate as P1); noted that the copy loop's
invariant IS the CN loop invariant's functional core (dstInv[j] =
srcStart[j] for j < i) — when P4 runs, the CN inv column gives the
invariant family for free.

### S2-P5b — refutation-layer transfer (small, worth recording)

`SpecLabProofs.harnessRunsTo_exclusive` (R1) is generic in the file:
both R2 plant refutation schemas
(`memcpyPlantClaim_refuted_of_run`, `getarrPlantClaim_refuted_of_run`)
cost 8 lines each with zero new lemmas — the anti-vacuity layer is
RUNG-INDEPENDENT. Cones: [propext, runEffectful, Classical.choice,
Quot.sound], pinned in-build.

### S2-N — THE CONCRETE-N CEILING (registered precisely)

What R2 proves-at-statement-level today: sample-∀ over 4 pinned
3-byte models (+ 2 getarr instances), with the parametric term
`memcpyMainParamDecl c0 c1 c2` making the FIXED-LENGTH family-∀
(all 256³ n=3 instances) the natural endpoint of the S1-P1 exec
campaign — nothing further needed on the statement side.

The statements the rung CANNOT yet make, and what each waits on:
  1. FIXED-n FAMILY-∀ (∀ c0 c1 c2, HarnessRunsTo (memcpyI3File c0
     c1 c2) 0 under byte-range side conditions): waits ONLY on the
     parked exec-equation campaign (S1-P1, price L, after Lane
     B/T5) — statement + parametric term + bridge are all built.
  2. LENGTH-PARAMETRIC ∀ (∀ bs, bs.length ≤ 16 → HarnessRunsTo
     (memcpyFileOfN bs) 0): the Core AST varies with n in ARITY
     (the initializer's unseq/Array width, and the observation
     loop's trip count), not just in literals — this needs T5's
     symbolic-n iter_compose PLUS a symbolic-ARITY generalization
     of the initializer lemma family (the template note's "vector
     of unknowns through the builder-loop invariant"), which no
     current machinery provides. Deliberately NOT attempted (the
     scoping's do-not-attempt rule); registered as the R2 wall.
  3. The TEMPLATE bound itself (cap = 16, u16 prefix admits 65535):
     raising cap is a template re-render + re-pin, mechanical; the
     16 ceiling is a fixture-economy choice, not a technical wall.

All S3 grades are SPECULATIVE per the charter. Target C:
IntList_append = 13 LOC (signature + body + braces, derived; CN
annotations excluded); harness C ≈ 95 LOC (append Form 1) / 100 LOC
(build-only).

### S3-P5 — pure-transport at a HEAP-STRUCTURE model (third grading:
does the ≈3/LOC trend hold?)

What landed kernel-checked entirely in pure land at R3: the
conditional array round trip (Codec.decodeElems_encodeElems_of /
decode_encode_arrayU16_of, ~55 lines — LIBRARY, the range-conditioned
element form any int-element codec will reuse), the two-codec
sequence bridge (decode/encode/canonicity through TWO length-prefixed
lists + `model_forall_iff_stream_forall` — the S1/S2 proof shape
survived composition unchanged), THE COLLAPSE AGAIN
(`append_is_model = rfl`: the CN postcondition's functional content
IS the model — third rung, now for a heap mutator), the plant models'
soundness (`xorOne_inRange`/`xorOne_ne` — the plant's predicted index
is structurally forced), and THE LEAK LAYER'S PURE FACE
(`alloc_free_balance`: allocs = frees for the healthy target by
`length_append`; `linkSkip_leaks`: the wrong-link plant orphans
exactly |xs| − 1 nodes — the gate's measured `baseline + 1` is this
theorem's instance at |xs| = 2).

(a) proof-lines/C-line: 4 — per-target marginal pure content ≈ 34
    theorem+proof lines / 13 LOC ≈ 3/LOC (derived: the 8 P5-section
    theorems' code lines, docstrings excluded). THE TREND HOLDS:
    7/LOC (R1) → 3/LOC (R2) → ~3/LOC (R3) with the library
    thickening (the conditional-round-trip lemmas join Canonical as
    paid-once codec algebra). The List-valued model cost NOTHING
    over byte lists; the heap structure never appears in pure land
    at all — that is the division of labor working.
(b) re-pin robustness: 5 — unchanged; zero pure lemmas name program
    terms (the out[68] template fix touched zero pure proofs).
(c) mechanization: 3 — unchanged (simp/omega/induction; statements
    hand-written).
(d) elaboration pressure: 5 — all pure proofs at default budgets,
    milliseconds.
(e) C-shape realism: 5 (up from 4) — a real recursive heap mutator
    with malloc'd nodes, interior pointers (the at-k prototype),
    struct tag defs, and a leak conjunct all transported; the pure
    layer's ceiling has not been found yet. R4's tree + path
    selection is the next probe.
(f) parallelizability: 5 — unchanged.
Evidence sentence: every R3 kernel theorem except the parked exec
equations lives in pure land at default budgets, the marginal
per-target cost is flat at ~3/LOC across three rungs, and the leak
conjunct's red-lane prediction (`baseline + 1`) fell out of a
2-line list lemma.

### S3-P1 — walker/certificate (re-priced at R3; not attempted —
the wall stays parked, per scoping)

Measured grounds refreshing the price: applist_a.core = 4,424 lines
(main ≈ 4,270 + IntList_append ≈ 140) vs memcpy_a's 2,092 and the T5
fixture's 172 — the R3 flagship is ~26x the largest walked fixture
and 2.1x R2's. NEW law surfaces beyond S2's list: `Alloc0`/Kill-
dynamic rounds (the allocator proxies — the first DYNAMIC allocation
lifecycle in any pinned family), PtrEq/PtrNe/PtrWellAligned memop
rounds, RECURSIVE Eccall (IntList_append calls itself — the first
non-tail recursive callee; the walk needs a call-depth induction the
slate has never exercised), and struct member_shift addressing.
Statement side remains walk-ready (parametric `appendMainParamDecl`
= the symbolic-initializer route's input; 12 params). Price:
unchanged L, sequenced after Lane B/T5; the recursion surface
suggests the walker campaign should START at R1/R2 fixtures and
reach R3 only after a callee-recursion lemma family exists.

### S3-P2 — Iris WP + adequacy (assessed again, still not
attempted; the note sharpens)

R3 is the first rung where the WP route would DIFFERENTIATE: a
modular callee spec for IntList_append (the CN contract, Iris-typed)
+ a representation predicate for IntList (the builder invariant IS
the representation predicate — container doctrine) would discharge
the sample statements without walking the 4,270-line main, and the
recursion is exactly where WP's induction beats the walker's
round-by-round chase. Still deferred (T1-T4's WP machinery consumes
app equations the walker must first produce for THESE fixtures);
recorded as the natural first target when the exec-equation campaign
reaches R3 — with the boring statement in front unchanged.

### S3-N — the R3 statement-shape ledger (registered precisely)

What R3 states today: sample-∀ over 4 pinned (2,1)-shape models +
2 pinned plants + the build-only instance, each with the leak
conjunct stated (and executably checked); the parametric
`appendMainParamDecl b0..b11` makes the FIXED-SHAPE family-∀ (256^12
instances) the exec campaign's natural endpoint — statement side
complete, nothing further needed there.

What R3 cannot yet state, and what each waits on:
  1. FIXED-SHAPE FAMILY-∀: waits only on the parked exec-equation
     campaign (S1-P1/S2-P1/S3-P1, price L, after Lane B/T5).
  2. LENGTH/SHAPE-PARAMETRIC ∀ (∀ xs ys, |xs| ≤ 8 → …): the R2 wall
     unchanged (symbolic-ARITY initializers + T5 symbolic-n), now
     PLUS the recursion-depth dimension (the callee's unfolding
     count varies with |xs|). Deliberately not attempted (parked
     wall stays parked).
  3. THE LEAK CONJUNCT'S ORACLE LEG: the oracle batch surface
     prints no allocation census — the leak observable is in-logic
     + in-Lean-executable but not oracle-differential. Priced: an
     oracle `--batch` final-allocation-count line (driver_ocaml
     batch printer + the concrete memory model's allocation map
     size; est. S, fork-side; candidate for the upstream tray
     alongside the filing drafts). Until then the leak lane's
     epistemic status is: Lean-side measured, pure-predicted,
     logic-refutable — not cross-checked against OCaml.

All S4 grades are SPECULATIVE per the charter. Target C: rotate_right
= 10 LOC (signature + body + braces, derived); harness C ≈ 145 LOC
(the recursive helper trio ≈ 80 + main ≈ 55, comments excluded; the
first speclab harness with helper procedures).

### S4-P5 — pure-transport at a RECURSIVE model (fourth grading: the
trend check)

What landed kernel-checked entirely in pure land at R4: the tree
codec's full law set (fuel-indexed decoder + `decodeTreeF_mono` +
round trip + canonicity + the path codec, ~200 lines — LIBRARY: any
presence-bit-coded structure family reuses the fuel pattern), the
two-codec bridge through a RECURSIVE self-delimiting code
(`model_forall_iff_stream_forall` — the S1-S3 proof shape survived
recursion unchanged), the locus-walk algebra (`applyAt` generic in
the locus operation — healthy target and both plants are
INSTANCES), ALLOCATION NEUTRALITY (`rotateAt_size` — the leak
statement's pure face), the plant accounting (`swapPlant_size`:
leak-free break; `dropPlant_size`: result + orphaned = input — the
gate's baseline+1 is its instance), vals preservation
(`rotateAt_valsOk` — readback exactness), the observation bound
(`expectedBytes_fits` — the out[] capacity as a lemma), and the
S4-E1 decomposition pair (`rotateAt_as_replace` + `rotateAt_frame`,
~63 lines, counted as the experiment).

(a) proof-lines/C-line: 3 — marginal per-target pure content ≈ 80
    theorem+proof code lines / 10 LOC ≈ 8/LOC. THE TREND BENDS at
    the tree rung: 7 (R1) → 3 (R2) → 3 (R3) → 8 (R4). Honest
    decomposition: the model is RECURSIVE for the first time, so
    every preservation fact costs a path-generalizing induction, and
    the rung carries THREE locus operations (healthy + two plants)
    each with size/vals accounting — per-locus-operation cost ≈ 25
    lines ≈ 2.5/LOC, roughly the R2/R3 flat rate; the bend is the
    OPERATION COUNT, not a per-fact blowup. The generic `applyAt`
    lemmas (size/valsOk/frame parametric in f) are paid once and
    amortize over any future locus-operation family.
(b) re-pin robustness: 5 — unchanged; zero pure lemmas name program
    terms (the sequenced-call template fix and the capacity-corner
    fix touched zero pure proofs).
(c) mechanization: 3 — unchanged (split/simp/omega/induction;
    statements hand-written; the fuel-decoder proofs are the rung's
    manual-labor peak at ~30 lines each).
(d) elaboration pressure: 5 — all pure proofs at default budgets,
    milliseconds; no set_option anywhere.
(e) C-shape realism: 5 — a recursive heap structure, path-indexed
    interior pointers, recursive C helpers, allocation-neutral
    mutation, and a two-class plant space all transported; the pure
    layer's ceiling is STILL not found. The open question after four
    rungs is no longer whether pure transport scales over structure
    complexity (it does) but over OPERATION COUNT per structure —
    the buddy allocator's operation family is the real test.
(f) parallelizability: 5 — unchanged.
Evidence sentence: every R4 kernel theorem except the parked exec
equations lives in pure land at default budgets; the marginal cost
bent to 8/LOC for a measured, structural reason (three locus
operations on a recursive model at ~2.5/LOC each), and the leak
lane's two predictions (baseline, baseline+1) each fell out of a
one-induction size lemma.

### S4-P1 — walker/certificate (re-priced at R4; not attempted —
the wall stays parked, per scoping)

Measured grounds refreshing the price: rotate_a.core = 5,638 lines
(main ≈ 2,210 + FIVE further procs) vs applist_a's 4,424 and the T5
fixture's 172 — the R4 flagship is ~33x the largest walked fixture.
NEW law surfaces beyond S3's list: a FIVE-proc call graph (main →
scan/build/serialize/free, each recursive; build_tree is doubly
recursive with depth ≤ 31 — the call-depth induction the S3 register
anticipated now composes across procs), and parent-link
pointer-to-pointer stores (`*link = …` through `struct node **`).
NOTABLE ABSENCE: zero new Core CONSTRUCTS — the R4 emitter needed no
new pp surface at all (first rung with an empty fidelity delta),
i.e. the Core construct vocabulary has SATURATED for this program
class; what grows is round count and call structure, exactly the
walker's amortization axis. Price: unchanged L, after Lane B/T5;
campaign order unchanged (R1/R2 first, tree last).

### S4-P2 — Iris WP + adequacy (the note completes)

R4 is where the WP route's representation predicates become the
natural vocabulary: the builder invariant IS the Tree representation
predicate (container doctrine), `rotateAt_frame` is the frame rule's
pure shadow, and a modular rotate_right triple would discharge all
six healthy instances without walking any 2,210-line main. Still
deferred (consumes the same parked app equations); recorded as the
natural SECOND target (after R3's append) when the exec-equation
campaign lands — with the boring statement in front unchanged.

### S4-N — the R4 statement-shape ledger (registered precisely)

What R4 states today: sample-∀ over 4 pinned-shape models (24-param
parametric term ⇒ the fixed-shape family-∀, 256^24 instances, is the
exec campaign's natural endpoint — statement side complete) + the
pointer-selection path family (2 verbatim path instances + the
in-stream parametric path) + the build-only builder-correctness
instance + the full leak family (healthy/path/build at baseline,
swap plant at baseline, drop plant at baseline+1 — the two-observable
plant separation stated, not just measured).

What R4 cannot yet state, and what each waits on:
  1. FIXED-SHAPE FAMILY-∀: waits only on the parked exec-equation
     campaign (price L, after Lane B/T5).
  2. SHAPE/PATH-PARAMETRIC ∀ (∀ t p, Wf ⟨t,p⟩ → …): the R2/R3 wall
     (symbolic-ARITY initializers + T5 symbolic-n + recursion depth)
     now PLUS the PATH dimension (the walk loop's trip count and the
     locus's position both vary with p — a fourth symbolic axis).
     Deliberately not attempted.
  3. THE LEAK CONJUNCT'S ORACLE LEG: unchanged from S3-N item 3 (an
     oracle --batch allocation-census line, est. S, fork-side,
     upstream-tray candidate). The R4 leak lane doubles the stakes —
     the plant-class separation is only Lean-side observable.

All S5 grades are SPECULATIVE per the charter. Target C: swap_pair =
6 LOC + lookup_size_shift = 14 LOC (bodies + braces, derived; CN
annotations excluded); harness C ≈ 60 LOC each.

### S5-P5 — pure-transport at the mature library (fifth grading: the
amortization check)

What landed kernel-checked entirely in pure land at R5: the codec
CANONICITY COMPLETIONS (`canonical_u32le`/`canonical_u64le` — the
last scalar widths join the S2 `Canonical` layer; LIBRARY), the
Wf-FREE bridge (`CnSeed.model_forall_iff_stream_forall` — the first
bridge with NO side conditions anywhere, the full-domain u64 model),
the CN postconditions' pure content at ZERO marginal cost
(`swap_post = ⟨rfl, rfl⟩`, `lookup_is_model` by decide — collapse
datapoints 4 and 5), the bonus mirrors (`swap_involutive`;
`f_model_lt_1000` — cn_inline's second contract in one decide;
`lookup_bounds`/`lookup_inRange`), and THE BLIND-SET
CHARACTERIZATION (`swapPlant_blind_iff` via the S2 comparator law +
`encodeU64LE_inj` — the plant's discriminating power as a kernel
theorem, 11 lines).

(a) proof-lines/C-line: 4 — marginal per-target pure content ≈ 85
    lines / 6 LOC (swap, of which ~55 is pair-codec algebra —
    library-shaped, reusable for any 2×u64 layout) + ≈ 22 / 14 LOC
    (lookup) ≈ 5/LOC combined, ~2.7/LOC excluding codec algebra
    (derived from the CnSeed.lean sections). Trend: see the summary
    head — flat per operation, library-amortizing.
(b) re-pin robustness: 5 — unchanged (zero pure lemmas name program
    terms; the harness-body iterations during probing touched zero
    pure proofs).
(c) mechanization: 3 — unchanged (simp/omega/decide/two case walks;
    statements hand-written).
(d) elaboration pressure: 5 — all pure proofs at default budgets,
    milliseconds; no set_option anywhere.
(e) C-shape realism: 5 — a pointer-mutating target on caller memory
    (u64 cells) and an enum-switch scalar both transported with the
    existing machinery; NOTHING in the pure layer noticed the new
    shapes. Ceiling still not found.
(f) parallelizability: 5 — unchanged; R5 itself was built alongside
    nothing blocking.
Evidence sentence: at the mature library the pure layer's marginal
cost for two fresh corpus targets was one sitting's work with both
CN postconditions definitionally absorbed, and the only
non-library-shaped new proof (the blind-set characterization) is a
NEW KIND of cheap theorem the earlier rungs didn't think to state.

### S5-P1 — walker/certificate (re-priced at R5; not attempted —
the wall stays parked, per scoping)

Measured grounds refreshing the price: pairswap_a.core = 1,439 lines
(main ≈ 1,180 + swap_pair ≈ 250) — BELOW R2's memcpy flagship
(2,092) with NO new law surfaces beyond R2's list (loops, SeqRMW,
store/load families; callee non-recursive, 3 straight-line stores)
— and the swap family is therefore the exec-equation campaign's
natural SECOND target after divmod-i8 (campaign order refined:
R1 i8 → R5 swap → R2 → R3 → R4, ascending call-graph complexity).
The lookup TU (1,086 lines) cannot enter the campaign until the
CoreParser enum gap closes (S5-E4). Price: unchanged L, after Lane
B/T5.

### S5-N — the R5 statement-shape ledger (registered precisely)

What R5 states today: swap sample-∀ over 4 pinned pairs (16-param
parametric term ⇒ fixed-family-∀, 256^16 instances, the campaign
endpoint — statement side complete) + the stream face via the first
hypothesis-free bridge + the plant claim with its refutation schema
+ the kernel-characterized blind set. No leak family (no
allocation). What R5 cannot yet state, and why:
  1. FIXED-FAMILY-∀: the parked exec-equation campaign (price L).
  2. The LOOKUP statement family (model-indexed lookupFileOf over
     the sz<256 sub-family, 2-param zip): parked on the CoreParser
     enum-ctype gap (S5-E4, price S) — NOT on any statement-side
     wall; the zip plan is drafted in the batch-1 history.
  3. Shape-parametric ∀: not applicable (fixed 16-byte stream is the
     swap family's full domain).

## THE LINUX-SCALING MEMO (close-out deliverable; speculative by
charter design)

Question: which proof styles plausibly scale to the kernel-adjacent
slate (pKVM buddy allocator, WireGuard-class code), what is missing
from each, and where should the next automation investment go?
Grounded in this arc's measured numbers; all forward claims are
speculative and say so.

**1. The scaling architecture the arc's evidence supports is a
two-stage division of labor: P5 in front of everything, P1(+P3) as
the bridge, P2 behind for structure.** Five rungs of evidence that
property content lives almost entirely in pure land (flat
per-operation cost, five definitional collapses of external specs,
zero elaboration pressure, perfect re-pin robustness, embarrassing
parallelism) — and that the ONE impure obligation per family (the
exec equation at the pinned/parametric term) is a single,
well-shaped, walker-class goal. Nothing at buddy-allocator scale
changes this shape: a page-allocator model is a pure map/tree with
an operation family, exactly the R4 "operation count" axis, priced
at ~2.5 lines/LOC per operation on this arc's numbers.

**2. The binding constraint is NOT statement supply — it is the
exec-equation campaign (P1), and its cost structure is now
understood.** The statement side is COMPLETE five rungs deep
(parametric terms make family-∀ free at the statement level). The
walker re-pricing across rungs measured the real growth axis: Core
size grows with CALL STRUCTURE, not construct vocabulary — the pp/
law surface SATURATED at R3 (R4 and R5 added zero new Core
constructs; R5's flagship is smaller than R2's). Speculatively: a
walker campaign that (i) starts at the smallest fixtures (i8, swap),
(ii) registers the four known-missing law surfaces (main-driven
drive prefix, Eccall rounds, block-scope store_lock init, Ememop),
and (iii) leans on arc-11 replay for re-pins, amortizes over EVERY
harness-family theorem at once — the highest-leverage automation
investment on the board, and it is already priced (L) and
sequenced (after T5).

**3. What each style is missing, concretely.** P1: T5's symbolic-n
(the loop tech) + the four law surfaces + a callee-recursion lemma
family (R3's finding); nothing conceptual. P4: is not really a
separate style at scale — it is P1's loop layer; the CN `inv` column
supplies invariant candidates for free where corpus targets carry
them. P2: consumes P1's equations; its scale value is MODULARITY
(callee triples + representation predicates = prove each kernel
function once, not per harness family) — the R3/R4 registers name
the first two targets; the S4-E1 frame lemmas are its pure shadows
already in place. P3: engineering, not research — inherited arc-11
measurements make P1 re-pins ~seconds; must be wired into the
campaign from day one, not retrofitted. P5: nothing is missing; its
ceiling was probed at recursive-heap-shape complexity and not found.

**4. The parametric walls are the honest long pole for
kernel-shaped ∀.** Fixed-shape family-∀ is reachable by the
campaign; LENGTH/SHAPE/PATH-parametric ∀ (the R2→R4 walls:
symbolic-arity initializers × recursion depth × path position) is
where "vast and unprecedented" lives. Speculation: the buddy
allocator's statements can start honest at fixed shapes (the
S2-E4/S5 zip machinery reaches 256^k families today), with the
symbolic axes landed one at a time on T5's iter_compose foundation —
and the template's per-shape scoping amendment keeps every
intermediate claim honestly labeled.

**5. Recommended next automation investment, ranked.** (1) THE
EXEC-EQUATION CAMPAIGN with replay wired in (unlocks: proved
sample-∀ + fixed-family-∀ for all five rungs' statements +
unconditional plant refutations; every future target inherits). (2)
T5 landing (Lane B — prerequisite for campaign's loop rungs and all
symbolic axes). (3) The CoreParser enum arm + the oracle
allocation-census line (S-priced instrument gaps that widen the
corpus and close the leak conjunct's differential leg). (4) P2
modular layer AFTER the campaign produces equations (its inputs).
This ordering front-loads the investments that amortize over every
target; it is the memo's only non-speculative claim — it follows
from which artifacts consume which.

**6. What this arc does NOT yet know.** Whether the walker's
round-count growth stays tractable at five-proc call graphs
(R4's 33x is measured but unwalked); whether exhaustive-mode ND
economies (the sequenced-call rule's 3^sites) stay controllable in
kernel-shaped code with real unsequenced idioms (the rule keeps
HARNESSES clean; targets arrive as they are); and whether the
concurrency axis (cmm schedules as streams — the forward design)
composes with the harness template at all. All three are named,
none is evidence-graded here.
