# Arc 15 — THE PROOF-STYLE REGISTER

Status: OPEN (stub created at S0 scaffold; entries begin at S1).
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
