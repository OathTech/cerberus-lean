/-
  RelSem.T7 — arc-18 R2 (2026-08-26): THE BRANCH-IN-LOOP FLAGSHIP —
  flip(7) THROUGH THE SEGMENT LAYER.

  tests/verify/t7_flip.c ([F1], the fixed-round breaker): the loop
  body BRANCHES with arms of different statement counts — the even
  iteration runs 72 rounds, the odd 94 — so uniform-k `iter_compose`
  cannot state the loop; the ∃-round `Seg.iter` composes it. This
  file is the fixture's HUMAN CONTENT in the blackboard shape: ONE
  invariant declared at the Core label through the SegInv map,
  obligations DERIVED and discharged by the registered walk chains
  (RelSem/T7Walks.lean — engine room), the driver atom by
  `driver2_of_seg`, statements by `verify_fn` + `seg_auto`.
  Statement shape: the GUARDED ∀-seed house form (T4SeedApart/
  T5EnvHypThr lineage — the loop's save/run draws fresh symbols).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.T7Walks
import RelSem.Segment
import RelSem.SegmentFaces

set_option autoImplicit false

namespace RelSem.T7

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit RelSem.T7W RelSem.Seg

/-! ## Statement data -/

/-- T7's pure spec on driver results: flip(7) = 0, Specified. -/
def t7Spec (r : driver_result) : Prop :=
  r.dres_core_value = intValue 0

/-- The environment hypothesis (digest pin; T4EnvHypThr lineage). -/
def T7EnvHypThr : Prop := CerberusFresh.digest () = ""

/-- Seed apartness: the run's < 16 fresh draws stay below every
    static symbol hash (≥ 2⁶⁰; T4SeedApart lineage). -/
def T7SeedApart (seed : Nat) : Prop :=
  seed + 16 < 1152921504606846976

/-- T7's FnSpec ([F9]): flip(7) = Specified 0 under the guarded
    face (REDUCIBLE — the faces unify against the statement text). -/
abbrev flipSpec : Seg.FnSpec Unit :=
  { fname := "flip", args := fun _ => [intValue 7],
    guard := fun seed => T7EnvHypThr ∧ T7SeedApart seed,
    post := fun _ => t7Spec }

/-- The run's terminal value (Specified 0). -/
def v0 : value :=
  Vloaded (LVspecified (OVinteger
    (CerbMem.IntegerValue.IV .Prov_none 0)))

/-! ## THE INVARIANT (the one human artifact): at the k-th loop-head
    visit, n's object holds the k-th value of the run's decrement
    sequence 4, 3, 0 — declared ONCE through the layer's label map. -/

/-- The label's spelling table ([F3]): t7's join points all sit at
    the STORED spelling (measured), so both slots coincide; the
    two-spelled case is demonstrated on the T5 twins. -/
def spell7 : Seg.JoinSpellings Seg.LoopComps where
  entry c := mkLH c.env c.mem c.tr c.aid c.exc c.symc c.ctr
  stored c := mkLH c.env c.mem c.tr c.aid c.exc c.symc c.ctr

/-- Component projection (the family IS the walks' own step,
    indexed). -/
def compOf (σ : driver_state) : Seg.LoopComps :=
  { env := envOf σ, mem := σ.layout_state, tr := σ.trace,
    aid := σ.core_run_state0.aid_supply,
    exc := σ.core_run_state0.excluded_supply,
    symc := σ.core_run_state0.sym_supply,
    ctr := σ.dr_step_counter }

/-- The components at the k-th visit (n = 4, 3, 0): walk-endpoint
    projections at the canonical harness supplies. -/
noncomputable def at7 (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    Nat → Seg.LoopComps
  | 0 => compOf (h1 bm am seed)
  | 1 => compOf (h2 bm am seed)
  | _ + 2 => compOf (h3 bm am seed)

/-- THE MAP ENTRY: `while_529 ↦` the declared invariant. -/
noncomputable def flipInv (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    Seg.SegInv :=
  { Comp := Seg.LoopComps, label := symWhile, spell := spell7,
    at_ := at7 bm am seed }

/-- The fixture's invariant map (RefinedC `gmap label` shape). -/
noncomputable def invMap7 (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    Seg.InvMap :=
  [flipInv bm am seed]

/-- The driver round computation (the segment calculus's `C`). -/
abbrev C := Seg.dnmsC t7File.tagDefs 0

/-! ## The whole-run segment (composed ONCE-PROVED rules over the
    registered walk chains; every budget a small literal) -/

/-- The done offer the exit segment reaches. -/
noncomputable abbrev t7Offer (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    nd_action (Fmap thread_id (List core_step2)) step_kind
      driver_error (mem_constraint CerbMem.IntegerValue) driver_state
      × driver_state :=
  (NDactive (fmapAddBy defaultCompare 0 [Step_done2 v0] fmapEmpty),
   hFin bm am seed)

/-! The family's members ARE the walk endpoints (named-state
    discipline; term-mode alignment instances). -/

section StAlign
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat)

theorem St0_eq : (flipInv bm am seed).St 0 = h1 bm am seed :=
  (e95_align bm am [] 0 0 seed 0).symm

theorem St1_eq : (flipInv bm am seed).St 1 = h2 bm am seed :=
  (bEven72_align (envOf (h1 bm am seed))
    (h1 bm am seed).layout_state (h1 bm am seed).trace
    (h1 bm am seed).core_run_state0.aid_supply
    (h1 bm am seed).core_run_state0.excluded_supply
    (h1 bm am seed).core_run_state0.sym_supply
    (h1 bm am seed).dr_step_counter).symm

theorem St2_eq : (flipInv bm am seed).St 2 = h3 bm am seed :=
  (bOdd94_align (envOf (h2 bm am seed))
    (h2 bm am seed).layout_state (h2 bm am seed).trace
    (h2 bm am seed).core_run_state0.aid_supply
    (h2 bm am seed).core_run_state0.excluded_supply
    (h2 bm am seed).core_run_state0.sym_supply
    (h2 bm am seed).dr_step_counter).symm

end StAlign

/-- ENTRY + LOOP + EXIT: the run reaches the done offer in ≤ 318
    rounds — entry 95, `Seg.iter` at per-iteration budget 94 (even
    72 / odd 94: THE ∃-ROUND COMPOSITION [F1]), exit 35. -/

theorem t7_run_seg (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat)
    (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    Seg.SegDone C (95 + (94 * 2 + 35))
      (mkRdy bm am [] 0 0 seed 0) (t7Offer bm am seed) := by
  have hentry : Seg.Seg C 95 (mkRdy bm am [] 0 0 seed 0)
      ((flipInv bm am seed).St 0) := by
    rw [St0_eq]
    exact Seg.Seg.of_chain (seg_entry bm am seed hdig hsB halN hb)
  have hbody : (flipInv bm am seed).BodyOb C 94 2 := by
    intro k hk
    match k with
    | 0 =>
      show Seg.Seg C 94 ((flipInv bm am seed).St 0)
        ((flipInv bm am seed).St 1)
      rw [St0_eq, St1_eq]
      exact (Seg.Seg.of_chain (C := C) (k := 72)
        (s := h1 bm am seed) (s' := h2 bm am seed)
        (seg_body0 bm am seed hdig hsB halN hb)).mono (by omega)
    | 1 =>
      show Seg.Seg C 94 ((flipInv bm am seed).St 1)
        ((flipInv bm am seed).St 2)
      rw [St1_eq, St2_eq]
      exact (Seg.Seg.of_chain (C := C) (k := 94)
        (s := h2 bm am seed) (s' := h3 bm am seed)
        (seg_body1 bm am seed hdig hsB halN hb)).mono (by omega)
    | k + 2 => exact absurd hk (by omega)
  have hexit : (flipInv bm am seed).ExitOb C 35 2
      (t7Offer bm am seed) := by
    show Seg.SegDone C 35 ((flipInv bm am seed).St 2) _
    rw [St2_eq]
    exact Seg.SegDone.of_chain (C := C) (k := 35)
      (s := h3 bm am seed) (r := t7Offer bm am seed)
      (seg_exit bm am seed hdig hsB halN hb)
  exact hentry.trans_done
    (Seg.InvMap.while_inv (invMap7 bm am seed) (l := symWhile) rfl
      hbody hexit)

/-! ## The driver atom (the write1 shape: the loop re-writes n's
    range once per iteration store — 5 layers, last image i32 0) -/

/-- The run's write ladder over n's range (chronological). -/
def ws7 : List (List CerbMem.AbsByte) :=
  [i32 6, i32 4, i32 3, i32 2, i32 0]

/-- The final state at ZEROED maps (map-independent by
    construction; the rDone6 discipline), post `prepare_exit`. -/
noncomputable abbrev hFin0 (seed : Nat) : driver_state :=
  { hFin Std.TreeMap.empty Std.TreeMap.empty seed with
    core_state0 := prepare_exit
      (hFin Std.TreeMap.empty Std.TreeMap.empty seed).core_state0 v0 }

/-- The final rest. -/
noncomputable abbrev rDone (seed : Nat) : driver_state :=
  restOf (hFin0 seed)

/-- THE DRIVER LOOP at open maps: rest + n's footprint in, the
    composed segment discharged by `driver2_of_seg` — no per-fixture
    fuel arithmetic. -/
@[seg_eq write1]
theorem driver2_o (seed : Nat) (henv : T7EnvHypThr)
    (hap : T7SeedApart seed) : ∀ bm am,
    am.get? 0 = some allocN →
    (∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) →
    app (driver2 t7File.tagDefs false) (setMaps (rRdy seed) bm am)
      = (NDactive (), setMaps (rDone seed)
          (writeSeq bm nAddr ws7) am) := by
  intro bm am halN hb
  rw [mkRdy_align seed bm am]
  exact Seg.driver2_of_seg rfl
    ((t7_run_seg bm am seed henv hap halN hb).mono (by decide)) rfl

/-! ## THE THREADED STATEMENTS (fuel-opsem faces, guarded ∀-seed) -/

/-- THE T7 HEADLINE (fuel opsem only): under the digest pin + seed
    apartness, every outcome of `callND(flip, [intValue 7])` from
    the threaded initial state is `Active r` with `r = intValue 0`. -/
def T7ThreadedStatement : Prop :=
  T7EnvHypThr →
  ∀ (seed : Nat), T7SeedApart seed →
    CallHarnessAdequateThr seed t7File.tagDefs t7File "flip"
      [intValue 7] t7Fs t7Spec

/-- **T7 THREADED** (cone exactly the classical trio): the
    branch-in-loop flagship THROUGH THE SEGMENT LAYER — one declared
    invariant, derived obligations, a two-line proof. -/
theorem T7Threaded : T7ThreadedStatement := by
  verify_fn flipSpec
  seg_auto

/-- **T7 THREADED UB-freedom** (same route). -/
theorem T7Threaded_ubFree :
    T7EnvHypThr →
    ∀ (seed : Nat), T7SeedApart seed →
      CallHarnessUBFreeThr seed t7File.tagDefs t7File "flip"
        [intValue 7] t7Fs := by
  verify_fn flipSpec
  seg_auto

end RelSem.T7
