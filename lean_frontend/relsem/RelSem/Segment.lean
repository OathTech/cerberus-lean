/-
  RelSem.Segment — arc-18 R2 (2026-08-26): THE SEGMENT LAYER.

  A segment/block judgment at Core join points — the reasoning-layer
  charter's central slice (docs/2026-08-26_arc18-segment-ladder-charter.md
  R2; design: container notes/2026-08-26_reasoning-layer-design-pass.md
  §2.2). The machine's argument for a program coincides with the human
  one: assertions at join points (entry, `save`'d labels, call
  boundaries, the terminal), straight-line obligations between them.

  LINEAGE (canon-first, per mechanism):
  * Floyd 1967 — assertions at cut points of the control-flow graph;
    verification conditions on the straight-line paths between them.
    Core's compiled control flow already carries its join points as
    labels (`save`/`run`), so cut-point decomposition applies with no
    source reconstruction.
  * Hoare 1969 — the composition and while rules; the segment judgment
    is a triple at the equation calculus.
  * RefinedC `typed_block`/`typed_stmt`
    (deps/refinedc/theories/typing/programs.v:68-73, BSD, structurally
    mirrored with attribution): invariants declared as a MAP from
    labels (`gmap label`) to assertions; per-segment obligations
    DERIVED from the map, never hand-composed.
  * BRiCk `wp_while_inv` / `Kloop`
    (deps/BRiCk .../logic/stmt.v:467-501, IDEAS-ONLY — no code
    ported): the invariant rule stated at the loop node; exits as
    continuation-indexed postconditions.
  * Dijkstra/Gries bound functions — the judgment carries a ROUND
    BUDGET: [F7] our correctness is TOTAL (fuel-bounded,
    termination-inclusive) where the donors' WP is partial; the budget
    is the termination measure's arithmetic shadow, and it is what
    lets a segment discharge at the executable runner's default fuel.

  THE JUDGMENT IS ∃-ROUND FROM DAY ONE ([F1]): "from any state
  satisfying the pre at this join point, the run reaches the next join
  point in SOME finite round count (within budget)" — internally the
  ∀-fuel relative chain equation (`*_chainrel`, the evaluator's mint —
  R1 contract §6) under an existential round count. A loop whose body
  BRANCHES has data-dependent per-iteration round counts; the uniform-k
  `iter_compose` cannot state it, `Seg.iter` can.

  Framing: segments ride the CerbMemInterp footprint discipline — the
  equation calculus quantifies the heap maps (`setMaps` decomposition,
  reads as footprint facts), and the WP layer (RelSem/CerbHeapWalk.lean
  rules) carries every untouched fragment across a segment implicitly.
  No new assertion DSL: pre/posts are the existing footprint
  vocabulary (points-to + allocation fragments + pure facts + restIs).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.ConstructLaws
import RelSem.CerbHeapWalk
import RelSem.Kit.Loop

set_option autoImplicit false

namespace RelSem.Seg

open RelSem RelSem.Cerb
open Iris Iris.ProgramLogic Iris.BI

/-! ## §1 The judgment (generic over a fuel-indexed computation)

    `C : Nat → σ → α` is any fuel-indexed computation family (the
    driver instantiation is `dnmsC` below). A segment is a RELATIVE
    fuel-consumption fact, so segments compose by Nat arithmetic and
    discharge at any concrete fuel above the budget. -/

/-- THE SEGMENT JUDGMENT (∃-round, budgeted [F1]/[F7]): from `s`, the
    computation reaches `s'` in SOME finite round count `k ≤ B` — the
    ∀-fuel relative chain equation under an existential round count.
    `B` is the round BUDGET (Dijkstra/Gries bound-function lineage):
    total-correctness discharge at the runner's default fuel needs the
    bound, and loop budgets are per-iteration bounds times trip
    counts. -/
def Seg {α σ : Type} (C : Nat → σ → α) (B : Nat) (s s' : σ) : Prop :=
  ∃ k, k ≤ B ∧ ∀ fuel, C (fuel + k) s = C fuel s'

/-- The TERMINAL segment: from `s`, the computation reaches the fixed
    result `r` (fuel-independent — the terminal offer shape the
    evaluator's terminal chains emit) in some `k ≤ B` rounds. -/
def SegDone {α σ : Type} (C : Nat → σ → α) (B : Nat) (s : σ) (r : α) :
    Prop :=
  ∃ k, k ≤ B ∧ ∀ fuel, C (fuel + k) s = r

/-! ## §2 Composition (each proved once; pure Nat reasoning) -/

section Compose
variable {α σ : Type} {C : Nat → σ → α}

/-- Intro from a minted relative chain (the `derive_rounds …
    chain` product, R1 contract §6): a `k`-round ∀-fuel block equation
    IS a segment at budget `k`. -/
theorem Seg.of_chain {k : Nat} {s s' : σ}
    (h : ∀ fuel, C (fuel + k) s = C fuel s') : Seg C k s s' :=
  ⟨k, Nat.le_refl k, h⟩

/-- Intro from a minted TERMINAL relative chain. -/
theorem SegDone.of_chain {k : Nat} {s : σ} {r : α}
    (h : ∀ fuel, C (fuel + k) s = r) : SegDone C k s r :=
  ⟨k, Nat.le_refl k, h⟩

/-- Budgets weaken. -/
theorem Seg.mono {B B' : Nat} {s s' : σ} (h : Seg C B s s')
    (hB : B ≤ B') : Seg C B' s s' :=
  let ⟨k, hk, hc⟩ := h
  ⟨k, Nat.le_trans hk hB, hc⟩

/-- Budgets weaken (terminal). -/
theorem SegDone.mono {B B' : Nat} {s : σ} {r : α} (h : SegDone C B s r)
    (hB : B ≤ B') : SegDone C B' s r :=
  let ⟨k, hk, hc⟩ := h
  ⟨k, Nat.le_trans hk hB, hc⟩

/-- The empty segment. -/
theorem Seg.refl (B : Nat) (s : σ) : Seg C B s s :=
  ⟨0, Nat.zero_le B, fun _ => rfl⟩

/-- SEGMENTS COMPOSE (the Hoare sequence rule at the equation
    calculus; budgets add). -/
theorem Seg.trans {B₁ B₂ : Nat} {s s' s'' : σ}
    (h₁ : Seg C B₁ s s') (h₂ : Seg C B₂ s' s'') :
    Seg C (B₁ + B₂) s s'' := by
  obtain ⟨k₁, hk₁, hc₁⟩ := h₁
  obtain ⟨k₂, hk₂, hc₂⟩ := h₂
  refine ⟨k₁ + k₂, by omega, fun fuel => ?_⟩
  have h : fuel + (k₁ + k₂) = (fuel + k₂) + k₁ := by omega
  rw [h, hc₁ (fuel + k₂), hc₂ fuel]

/-- A segment followed by a terminal segment is terminal. -/
theorem Seg.trans_done {B₁ B₂ : Nat} {s s' : σ} {r : α}
    (h₁ : Seg C B₁ s s') (h₂ : SegDone C B₂ s' r) :
    SegDone C (B₁ + B₂) s r := by
  obtain ⟨k₁, hk₁, hc₁⟩ := h₁
  obtain ⟨k₂, hk₂, hc₂⟩ := h₂
  refine ⟨k₁ + k₂, by omega, fun fuel => ?_⟩
  have h : fuel + (k₁ + k₂) = (fuel + k₂) + k₁ := by omega
  rw [h, hc₁ (fuel + k₂), hc₂ fuel]

/-- DISCHARGE at concrete fuel: a terminal segment within budget `B`
    yields the plain equation at ANY fuel `F ≥ B` (the runner's
    default fuel in practice) — [F7] total correctness meeting the
    executable semantics. -/
theorem SegDone.run {B : Nat} {s : σ} {r : α} (h : SegDone C B s r)
    {F : Nat} (hF : B ≤ F) : C F s = r := by
  obtain ⟨k, hk, hc⟩ := h
  have hE : F = (F - k) + k := by omega
  rw [hE]
  exact hc (F - k)

/-- THE ∃-ROUND ITERATION RULE ([F1] — the rule the fixed-round
    `iter_compose` cannot state): `n` iterations, each some `≤ B`
    rounds (DATA-DEPENDENT per-iteration counts — branch-in-loop
    bodies), compose into a `B·n`-budget segment over the invariant
    family `St`. -/
@[step_law (kind := loop) (variant := iterSeg) (side := fed)
  (frontier := "loop/compose")
  (trace := "{law := Seg.iter, joint := loop/compose, hyps := [hbody : fed(∃-round)]}")
  (lineage := "Floyd-Hoare invariant iteration at the ∃-round segment judgment (variable per-iteration rounds; budget = per-iteration bound × trip count)")]
theorem Seg.iter {St : Nat → σ} {B : Nat} (n : Nat)
    (hbody : ∀ i, i < n → Seg C B (St i) (St (i + 1))) :
    Seg C (B * n) (St 0) (St n) := by
  induction n with
  | zero => exact Seg.refl 0 (St 0)
  | succ n ih =>
    have h1 : Seg C (B * n) (St 0) (St n) :=
      ih (fun i hi => hbody i (Nat.lt_succ_of_lt hi))
    have h2 : Seg C B (St n) (St (n + 1)) :=
      hbody n (Nat.lt_succ_self n)
    have := h1.trans h2
    rwa [← Nat.mul_succ] at this

/-- THE WHILE RULE (the composition theorem, proved once): a loop
    whose head-invariant is preserved by its body segments (`hbody`,
    ∃-round each) and whose guard-false exit is a terminal segment
    (`hexit`) yields the whole-loop terminal judgment. Lineage: Hoare
    while rule; BRiCk `wp_while_inv` (stmt.v:487); RefinedC
    `typed_block` at the loop label. -/
theorem Seg.while_inv {St : Nat → σ} {B Bx : Nat} {r : α} (n : Nat)
    (hbody : ∀ i, i < n → Seg C B (St i) (St (i + 1)))
    (hexit : SegDone C Bx (St n) r) :
    SegDone C (B * n + Bx) (St 0) r :=
  (Seg.iter n hbody).trans_done hexit

end Compose

/-! ## §3 Join points, the invariant map, and spelling normalization

    Join points are Core's own labels (Floyd cut points, compiled).
    Invariants are declared ONCE per label as a MAP entry (RefinedC
    `typed_block (P : iProp) (b : label) … (Q : gmap label stmt)`,
    programs.v:72 — mirrored structurally); every per-segment
    obligation is DERIVED from the map entry.

    [F3] JOIN-POINT SPELLING NORMALIZATION: falling INTO a `save`
    leaves iteration 1's loop head at a DIFFERENT SPELLING from the
    stored continuation later iterations jump to (the C3b measured
    seam — outer-annotation hoist + partial forcing; propositionally
    distinct states). The seam is discharged ENGINE-SIDE: the map
    entry carries the label's SPELLING TABLE (fall-in + stored
    builders), the derived state family `St` routes index 0 through
    the fall-in spelling and indices ≥ 1 through the stored spelling,
    and obligations are stated over `St` — twin-builder vocabulary
    never reaches the user surface. -/

/-- A join point of a compiled Core program (Floyd cut points at
    Core's own labels; call boundaries in the type from day one —
    charter R2). -/
inductive SegPoint where
  /-- Function entry (the harness's thread-ready state). -/
  | entry
  /-- A `save`'d Core label (loop heads; `run l` back-edges). -/
  | label (l : sym)
  /-- A call boundary (consumes a callee `FnSpec` summary — §5). -/
  | call (f : sym)
  /-- The thread's terminal (the done offer). -/
  | terminal

/-- The spelling table of one label ([F3]): how the SAME join point is
    spelled when fallen into (`entry`) vs jumped to through the stored
    continuation (`stored`). Component data `Comp` is the invariant's
    own vocabulary (the human content); the builders are fixture data
    (engine room). -/
structure JoinSpellings (Comp : Type) where
  /-- The fall-in spelling (iteration 1's loop head). -/
  entry : Comp → driver_state
  /-- The stored-continuation spelling (every later iteration). -/
  stored : Comp → driver_state

/-- The invariant at ONE label, as declared: the label, its spelling
    table, and the component family `at_ k` = the invariant's data at
    the k-th visit (the ONE human artifact; e.g. T5's
    `s = k·(k−1)/2 ∧ i = k` as component values). -/
structure SegInv where
  /-- The invariant's component vocabulary. -/
  Comp : Type
  /-- The Core label this invariant attaches to. -/
  label : sym
  /-- The label's spelling table ([F3], engine-side). -/
  spell : JoinSpellings Comp
  /-- The declared invariant: components at the k-th visit. -/
  at_ : Nat → Comp

/-- THE INVARIANT MAP: label ↦ declared invariant (the RefinedC
    `gmap label` shape, programs.v:68/72). Association by label;
    obligations are derived from the found entry, never
    hand-composed. -/
def InvMap : Type 1 := List SegInv

/-- Map lookup (the `Q !! b` of RefinedC's `typed_block`). -/
def InvMap.find? (M : InvMap) (l : sym) : Option SegInv :=
  List.find? (fun I => I.label == l) M

/-- The DERIVED head-state family of a declared invariant ([F3]): the
    k-th visit to the label, at the RIGHT SPELLING — index 0 through
    the fall-in builder, indices ≥ 1 through the stored builder. The
    normalizer owns the twin vocabulary; users state obligations over
    `St`. -/
def SegInv.St (I : SegInv) : Nat → driver_state
  | 0 => I.spell.entry (I.at_ 0)
  | k + 1 => I.spell.stored (I.at_ (k + 1))

section Derived
variable {α : Type} {C : Nat → driver_state → α}

/-- DERIVED body obligation (from the map entry): every visit's
    segment reaches the next visit, ∃-round. The k = 0 instance is
    automatically at the fall-in spelling and k ≥ 1 at the stored
    spelling — the [F3] normalization at work: ONE declared
    invariant, both spellings discharged against it. -/
def SegInv.BodyOb (I : SegInv) (C : Nat → driver_state → α) (B n : Nat) :
    Prop :=
  ∀ k, k < n → Seg C B (I.St k) (I.St (k + 1))

/-- DERIVED exit obligation: the guard-false visit runs to the
    terminal result. -/
def SegInv.ExitOb (I : SegInv) (C : Nat → driver_state → α) (Bx n : Nat)
    (r : α) : Prop :=
  SegDone C Bx (I.St n) r

/-- THE LOOP JUDGMENT FROM THE MAP (proved once): a found map entry
    whose derived body and exit obligations hold yields the whole-loop
    terminal segment from the fall-in state. `hfind` pins the
    obligations to the DECLARED map (RefinedC: `typed_block` resolved
    through `Q`). -/
theorem InvMap.while_inv (M : InvMap) {l : sym} {I : SegInv}
    (_hfind : M.find? l = some I) {B Bx n : Nat} {r : α}
    (hbody : I.BodyOb C B n) (hexit : I.ExitOb C Bx n r) :
    SegDone C (B * n + Bx) (I.St 0) r :=
  Seg.while_inv n hbody hexit

end Derived

/-! ## §4 The driver instantiation

    `dnmsC` is the driver's round computation (the scheduler's
    nonmemory-step drive — every evaluator-minted chain is a block
    equation over it); `driver2_of_seg` is the ONCE-PROVED discharge
    of the whole driver-loop atom from a terminal segment, replacing
    the per-fixture concrete-fuel arithmetic (`fuel := 999947`-style)
    of the pre-layer walks. -/

/-- The driver's fuel-indexed round computation (the segment
    calculus's `C` for driver segments; single-thread harnesses run
    `tid = 0`). -/
def dnmsC (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid : Nat) (fuel : Nat) (σ : driver_state) :=
  app (drive_nonmemory_steps_aux2_lemFuel fuel tagDefs fmapEmpty [tid]) σ

/-- The canonical mid-walk representative at rest `ρ` (the `nd_get`
    continuation state): harness continuations consume the state only
    through rest projections (`wpk_seq_get`'s contract), so any state
    whose rest is `ρ` represents the fiber; fixtures register their
    named representative (`@[seg_canon]`) and `seg_auto` continues
    there — the named-state discipline (S0 giant-terms rule) riding
    the automation. -/
def CanonAt (ρ c : driver_state) : Prop := restOf c = ρ

/-- A driver segment (the judgment at `dnmsC`). -/
abbrev DSeg (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (B : Nat) (σ σ' : driver_state) : Prop :=
  Seg (dnmsC tagDefs 0) B σ σ'

/-- A terminal driver segment offering the done step for `v`. -/
abbrev DSegDone (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (B : Nat) (σ σ' : driver_state) (v : value) : Prop :=
  SegDone (dnmsC tagDefs 0) B σ
    (NDactive (fmapAddBy defaultCompare 0 [Step_done2 v] fmapEmpty), σ')

/-- THE DRIVER-ATOM DISCHARGE (proved once; consumed by every fixture
    through the walk rules' open-memory `h` slot): a terminal driver
    segment within the default fuel budget + the single-thread pool
    fact yields the whole `driver2` atom equation. Composes
    `Laws.ndct_offer1` + `Laws.driver2_done` over `SegDone.run` at
    `lemDefaultFuel` — the ∃-round budget meets the executable
    runner's concrete fuel HERE, once. -/
theorem driver2_of_seg
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {σ σ' : driver_state} {v : value}
    {thi : Option thread_id × thread_state}
    (hths : σ.core_state0.thread_states = [(0, thi)])
    (hseg : DSegDone tagDefs lemDefaultFuel σ σ' v)
    {σ'' : driver_state}
    (hout : { σ' with core_state0 := prepare_exit σ'.core_state0 v }
      = σ'') :
    app (driver2 tagDefs false) σ = (NDactive (), σ'') := by
  have hchain : app (drive_nonmemory_steps_aux2_lemFuel lemDefaultFuel
      tagDefs fmapEmpty [0]) σ
      = (NDactive (fmapAddBy defaultCompare 0 [Step_done2 v] fmapEmpty),
         σ') :=
    hseg.run (Nat.le_refl _)
  show app (driver2_lemFuel (999999+1) tagDefs false) σ
    = (NDactive (), σ'')
  exact RelSem.Laws.driver2_done (RelSem.Laws.ndct_offer1 hths hchain)
    hout

/-! ## §5 FnSpec — ONE contract form, two roles ([F9], GREENFIELD)

    The spec a function is PROVED AGAINST (`Verified`, discharged by
    `verify_fn` through the threaded heap-route adequacy) IS the
    object a caller consumes at a call-boundary segment (`Summary` +
    `Summary.consume` — the Hoare procedure rule + frame rule).
    Lineage: RefinedC `fn_spec`/`typed_function` (typing/programs.v),
    BRiCk `wp_call` (ideas only), SAW overrides as the lineage that
    dissolves into this, kernel-checked.

    [USER 2026-08-26] RATIFIED forward-design constraint (charter
    [F9]): FnSpec is designed PROMOTION-COMPATIBLE — nothing in its
    form assumes it stays proof-layer-only. The fields are executable first-order data
    (name, argument family, pure pre, result post over
    `driver_result`) — exactly the statement layer's vocabulary — so
    a later operator decision to admit API contracts at statement
    level is a PROMOTION, not a rework. It stays proof-layer in this
    slice regardless (statements byte-stable, gate-enforced).

    The parameter `A` is the spec's argument family (`Unit` for
    closed instances like T6; `Int` for T1's ∀-x family) — the
    family-∀ statements quantify it. -/

structure FnSpec (A : Type) where
  /-- The designated function's name (the harness's `--call` face). -/
  fname : String
  /-- The harness arguments at spec parameter `a`. -/
  args : A → List value
  /-- Pure precondition (e.g. `intRange x`; `True` when closed).
      Footprint preconditions enter at the call-boundary role via the
      summary's segment pre — closed harnesses receive their initial
      footprint from adequacy (the HeapLang precedent). -/
  pre : A → Prop := fun _ => True
  /-- Postcondition on the driver result. -/
  post : A → driver_result → Prop

/-- ROLE 1 — the spec a function is proved against: the ∀-seed
    threaded adequacy face at every spec parameter (statements are
    instances of this shape; the fixture statements themselves stay
    byte-stable and are derived by `verify_fn`'s bridge). -/
def FnSpec.Verified {A : Type} (S : FnSpec A)
    (file1 : file core_run_annotation) (fs : CerbFS.FsState) : Prop :=
  ∀ (seed : Nat) (a : A), S.pre a →
    CallHarnessAdequateThr seed file1.tagDefs file1 S.fname (S.args a)
      fs (S.post a)

/-- Role 1's UB-freedom companion (same WP obligation). -/
def FnSpec.VerifiedUB {A : Type} (S : FnSpec A)
    (file1 : file core_run_annotation) (fs : CerbFS.FsState) : Prop :=
  ∀ (seed : Nat) (a : A), S.pre a →
    CallHarnessUBFreeThr seed file1.tagDefs file1 S.fname (S.args a) fs

/-- The WP obligation of a spec (what `verify_fn` leaves; the
    RefinedC `typed_function` shape: one WP goal per spec parameter,
    pre in front, post in the postcondition). -/
def FnSpec.WpOb {A : Type} (S : FnSpec A)
    (file1 : file core_run_annotation) (fs : CerbFS.FsState)
    (GF : BundledGFunctors) [CerbHeapGpreS GF] : Prop :=
  ∀ (seed : Nat) (a : A), S.pre a → ∀ [CerbHeapGS GF],
    (restIs (GF := GF) restHalf
        (restOf (initial_driver_state_threaded seed file1 fs))) ⊢
      WP (callK file1.tagDefs file1 S.fname (S.args a))
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ S.post a r⌝ }}

/-- ROLE 1 DISCHARGE (proved once): the WP obligation yields
    `Verified` through the threaded heap-route adequacy. -/
theorem FnSpec.dischargeThr {A : Type} {S : FnSpec A}
    {file1 : file core_run_annotation} {fs : CerbFS.FsState}
    {GF : BundledGFunctors} [CerbHeapGpreS GF]
    (Hwp : S.WpOb file1 fs GF) : S.Verified file1 fs := by
  intro seed a ha
  refine kCallHarnessAdequateThrHeap_of_wp (GF := GF) seed file1.tagDefs
    file1 S.fname (S.args a) fs (S.post a) ?_
  intro _
  exact Hwp seed a ha

/-- The UB-freedom twin (same `Hwp`). -/
theorem FnSpec.dischargeUBThr {A : Type} {S : FnSpec A}
    {file1 : file core_run_annotation} {fs : CerbFS.FsState}
    {GF : BundledGFunctors} [CerbHeapGpreS GF]
    (Hwp : S.WpOb file1 fs GF) : S.VerifiedUB file1 fs := by
  intro seed a ha
  refine kCallHarnessUBFreeThrHeap_of_wp (GF := GF) seed file1.tagDefs
    file1 S.fname (S.args a) fs (S.post a) ?_
  intro _
  exact Hwp seed a ha

/-! ### Role 2 — the call-boundary segment (the Hoare procedure rule)

    A call boundary (`SegPoint.call f`) consumes the callee's SUMMARY:
    the segment-level export of a verified spec — from any caller
    state at the call join point whose components satisfy the pre,
    some finite rounds reach the return join point with the post's
    components. Consumption is `Seg.trans` twice (call-in, summary,
    return) — the procedure rule — with the FRAME carried by the open
    heap-map binders of the equation calculus and by the WP layer's
    footprint rules (everything the callee's footprint does not
    mention rides across). First worked two-function instance lands
    at R6 (charter); the form and the consumption rule are R2
    deliverables, proved once here. -/

/-- A callee summary at a call boundary: `entry c` is the caller's
    state at the call join point with component data `c`, `exit c`
    the state at the return join point. -/
def Summary {α : Type} (C : Nat → driver_state → α) (B : Nat)
    {Comp : Type} (pre : Comp → Prop)
    (entry exit_ : Comp → driver_state) : Prop :=
  ∀ c, pre c → Seg C B (entry c) (exit_ c)

/-- THE CALL RULE (proved once; Hoare procedure rule + frame at the
    equation calculus): reach the call point, consume the summary,
    continue from the return point. Budgets add. -/
theorem Summary.consume {α : Type} {C : Nat → driver_state → α}
    {B₁ B₂ B₃ : Nat} {Comp : Type} {pre : Comp → Prop}
    {entry exit_ : Comp → driver_state} {s s' : driver_state} {c : Comp}
    (hin : Seg C B₁ s (entry c))
    (hsum : Summary C B₂ pre entry exit_) (hpre : pre c)
    (hout : Seg C B₃ (exit_ c) s') :
    Seg C (B₁ + B₂ + B₃) s s' :=
  ((hin.trans (hsum c hpre)).trans hout)

end RelSem.Seg
