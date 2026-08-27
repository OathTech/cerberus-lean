/-
  RelSem.T5Spine — arc-18 R4 (2026-08-27): THE T5 HARNESS SPINE AT
  OPEN MAPS + THE PACK/EXIT/ATOM FEEDS.

  The mechanical layer under RelSem/T5.lean (the gated slate file):

  * the k-stage open-memory harness equations for `t5File` at the
    SYMBOLIC argument n (the T1Threaded/T7W k6_o/k8_o recipe — the
    injection stores `i32 n`; every pure stage is the same `rfl` at
    free maps), registered as segment supply (`@[seg_eq ...]`);
  * `packAt` — the ∀-k closure of the seam demo's `BPack` at the
    harness family (T5Inv's family lemmas, assembled);
  * the exit legs (`segdone_exit`), the composed run's final state
    `t5Fin` + fixed rest `rDone5` (map-independent via
    `stFin_rest_indep`), and the finalize readout;
  * THE DRIVER ATOM `driver2_o` (`@[seg_eq scratch2]`) — the whole
    `driver2` loop from the composed segment through
    `Seg.driver2_of_seg`, consumed by `seg_auto` through the
    once-proved `wpk_seq_scratch2` rule with the final-state facts
    below (`@[seg_fact]`) as its pointwise feed.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.T5Seam
import RelSem.DeriveState
import RelSem.ConstructLaws
import RelSem.CerbHeapWalk
import RelSem.SegmentFaces

set_option autoImplicit false

namespace RelSem.T5

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit RelSem.T5W RelSem.T5S
open Lem_Basic_classes (ordCompare)

/-! ## Statement-adjacent data -/

/-- T5's filesystem state (initial, as every slate fixture). -/
def t5Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- The supply ceiling literal (T5Inv's `supplyCeil`). -/
theorem supplyCeil_eq : supplyCeil = 1152921504606846976 := rfl

/-- errno's allocation record. -/
def allocErr5 : CerbMem.Allocation :=
  { base := errAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "errno" }

/-- The argument byte image at the symbolic argument. -/
abbrev argBytes5 (n : Int) : List CerbMem.AbsByte := i32 n

/-! ## The named-state ladder + rest ladder (T7W recipe at t5File) -/

/-- Stage 1: driver_globals (t5 has none). -/
derive_state_step dG5 (seed : Nat)
  from (driver_globals t5File.tagDefs false t5File)
  at (initial_driver_state_threaded seed t5File t5Fs)

abbrev rInit5 (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed t5File t5Fs)
abbrev rGlob5 (seed : Nat) : driver_state := restOf (dG5 seed)
abbrev rArg5 (seed : Nat) : driver_state :=
  restAllocR (rGlob5 seed) nAddr
abbrev rErr5 (seed : Nat) : driver_state :=
  restAllocR (rArg5 seed) errAddr
/-- The ready rest (the driver loop's start; supplies at the
    canonical harness values — aligns with the T5W builder by
    `mkRdy5_align`). -/
noncomputable abbrev rRdy5 (seed : Nat) : driver_state :=
  restOf (mkRdy Std.TreeMap.empty Std.TreeMap.empty [] 0 0 seed 0)

/-- The ready builder aligns with the harness rest at the canonical
    supplies. -/
theorem mkRdy5_align (seed : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) :
    setMaps (rRdy5 seed) bm am = mkRdy bm am [] 0 0 seed 0 := rfl

/-! ## The open-memory stage equations -/

@[seg_eq rest]
theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals t5File.tagDefs false t5File)
        (setMaps (rInit5 seed) bm am)
      = (NDactive 0, setMaps (rGlob5 seed) bm am) := fun _ _ => rfl

/-- The post-globals canonical representative (`nd_get` joint). -/
@[seg_canon]
theorem t5_canon (seed : Nat) : Seg.CanonAt (rGlob5 seed) (dG5 seed) :=
  rfl

@[seg_eq rest]
theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG5 seed).core_file "sum")
        (setMaps (rGlob5 seed) bm am)
      = (NDactive sumT5Sym, setMaps (rGlob5 seed) bm am) :=
  fun _ _ => rfl

@[seg_eq rest]
theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG5 seed).core_file sumT5Sym)
        (setMaps (rGlob5 seed) bm am)
      = (NDactive ([(symN, BTy_object OTy_pointer)], sumBody),
         setMaps (rGlob5 seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG5 seed).core_file sumT5Sym)
        (setMaps (rGlob5 seed) bm am)
      = (NDactive [signed_int], setMaps (rGlob5 seed) bm am) :=
  fun _ _ => rfl

/-- The argument-object address arithmetic. -/
@[seg_fact]
theorem nAddr5_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rGlob5 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = nAddr := by
  rw [show (rGlob5 seed).layout_state.lastAddress
    = (281474976710655 : Int) from rfl]
  decide

/-- The memValue the caller protocol computes for the symbolic T5
    argument (state-free; rfl at open n — the T1 recipe). -/
theorem memValueFromValue_t5_eq (n : Int) :
    memValueFromValue t5File.tagDefs signed_int (intValue n)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval n)) := rfl

/-- Stage 6, THE ARGUMENT INJECTION at open maps (symbolic n). -/
@[seg_eq argobj]
theorem k6_o (seed : Nat) (n : Int) : ∀ bm am,
    app (injectArgs t5File.tagDefs 0
          [(symN, BTy_object OTy_pointer)] [signed_int] [intValue n])
        (setMaps (rGlob5 seed) bm am)
      = (NDactive [(symN, Vobject (OVpointer nPtr))],
         allocStoreState (restAllocR (rGlob5 seed) nAddr) bm am nAddr 4
           (argBytes5 n) 0 allocN) := by
  intro bm am
  refine Laws.inject_ptr_arg1 (σ := setMaps (rGlob5 seed) bm am)
    (hmv := memValueFromValue_t5_eq n)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := nAddr)
      (by exact rfl) (nAddr5_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval n))
      (allocId := 0) (addr := nAddr) (alloc := allocN)
      (fpm := []) (bytes := argBytes5 n)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 0 allocN).get? 0 = some allocN
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact rfl))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

@[seg_eq rest]
theorem k7_o (seed : Nat) : ∀ bm am,
    app get_thread_states (setMaps (rArg5 seed) bm am)
      = (NDactive ((dG5 seed).core_state0.thread_states),
         setMaps (rArg5 seed) bm am) :=
  fun _ _ => rfl

/-- The errno address arithmetic. -/
@[seg_fact]
theorem errAddr5_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rArg5 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = errAddr := by
  rw [show (rArg5 seed).layout_state.lastAddress = nAddr from rfl]
  decide

/-- Stage 8, THE ERRNO BLOCK at open maps. -/
@[seg_eq argobj]
theorem k8_o (seed : Nat) : ∀ bm am,
    app (liftMem (nd_bind
        (CerbMem.allocateObject 0 (PrefOther "errno")
          (CerbMem.alignofIval signed_int) signed_int none none)
        (fun (ptr_val : CerbMem.PointerValue) =>
          let zero := CerbMem.integerValueMval (Signed Int_)
            (CerbMem.integerIval (0 : Int))
          nd_bind
            (CerbMem.storeM (CerbLocation.other "errno init")
              signed_int false ptr_val zero)
            (fun (_ : CerbMem.Footprint) => nd_return ptr_val))))
      (setMaps (rArg5 seed) bm am)
      = (NDactive errPtr,
         allocStoreState (restAllocR (rArg5 seed) errAddr) bm am errAddr
           4 (i32 0) 1 allocErr5) := by
  intro bm am
  refine Laws.callND_errno (σ := setMaps (rArg5 seed) bm am)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := errAddr)
      (by exact rfl) (errAddr5_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))
      (allocId := 1) (addr := errAddr) (alloc := allocErr5)
      (fpm := []) (bytes := i32 0)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 1 allocErr5).get? 1 = some allocErr5
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact rfl))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

/-- Stage 9, the thread setup (rest-only). -/
@[seg_eq rest]
theorem k9_o (seed : Nat) (th : thread_state) (hth : th = thRdy) :
    ∀ bm am,
    app (driver_update_thread_state 0 th : driverM Unit)
        (setMaps (rErr5 seed) bm am)
      = (NDactive (), setMaps (rRdy5 seed) bm am) := by
  subst hth; exact fun _ _ => rfl

/-! ## The pack closure at the harness family (T5Inv's families,
    assembled into the seam demo's `BPack`) -/

/-- The harness family's parameters at (seed, n, maps). -/
def pOf (seed : Nat) (n : Int)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : Pm :=
  { bm := bm, am := am, tr0 := [], aid0 := 0, exc0 := 0,
    symc0 := seed, ctr0 := 0, n := n }

/-- THE ∀-k PACK (the R4 rung's headline closure): every hypothesis
    of the body walks' 27-hypothesis pack, at the k-th family member,
    for symbolic k and n. -/
theorem packAt (seed : Nat) (n : Int)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 256 < 1152921504606846976)
    (hn0 : 0 ≤ n) (hn1 : n ≤ 100)
    (ham : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < 4) →
      bm.get? (nAddr + (i : Int)) = (i32 n)[i]?)
    (k : Nat) (hk : (k : Int) < n) :
    BPack (envOf (St (pOf seed n bm am) k))
      (St (pOf seed n bm am) k).layout_state
      (St (pOf seed n bm am) k).core_run_state0.excluded_supply
      (St (pOf seed n bm am) k).core_run_state0.sym_supply
      n (triF k) (k : Int) := by
  have hk100 : k ≤ 100 := by omega
  have hsc : (pOf seed n bm am).symc0 + 256 < supplyCeil := hsB
  refine
    { hdig := hdig
      hbuilt := St_built _ k
      hlkN := St_lkN _ hsc k hk100
      hlkS := St_lkS _ hsc k hk100
      hlkI := St_lkI _ hsc k hk100
      hdd0 := St_dd _ k 0
      hdd2 := St_dd _ k 2
      hdd3 := St_dd _ k 3
      halN := St_alN _ ham k
      halS := St_alS _ k
      halI := St_alI _ k
      hfpm := St_fpm _ k
      hlum := St_lum _ k
      hrdN := St_rdN _ hb k
      hrdS := St_rdS _ k
      hrdI := St_rdI _ k
      hrecN := recon_i32 nAddr n (by omega) (by omega)
      hrecS := ?_
      hrecI := ?_
      hi2bS := i2b_i32 _
      hi2bI := i2b_i32 _
      hlt := hk
      hn1 := hn1
      hiv0 := by omega
      hsv0 := triF_nonneg k
      hsv1 := triF_le k hk100
      hscB := ?_
      hexcB := ?_ }
  · exact recon_i32 sAddr (triF k) (by have := triF_nonneg k; omega)
      (by have := triF_le k hk100; omega)
  · exact recon_i32 iAddr (k : Int) (by omega) (by omega)
  · rw [St_symc]
    show seed + 2 * k < 1152921504606846976
    omega
  · rw [St_exc]
    show 0 + 2 * k < 1152921504606846976
    omega

/-! ## The exit legs (the twin terminal chains at the family) -/

/-- The run's terminal value at trip count N. -/
def vD5 (n : Int) : value :=
  Vloaded (LVspecified (OVinteger
    (CerbMem.IntegerValue.IV .Prov_none (triF n.toNat))))

/-- The composed run's done offer. -/
noncomputable def t5Offer (p : Pm) :
    nd_action (Fmap thread_id (List core_step2)) step_kind
      driver_error (mem_constraint CerbMem.IntegerValue) driver_state
      × driver_state :=
  (NDactive (fmapAddBy defaultCompare 0
    [Step_done2 (Vloaded (LVspecified (OVinteger
      (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
        (triF p.n.toNat)))))] fmapEmpty),
   stFin p)

/-- THE EXIT OBLIGATION at the family: the guard-false visit runs to
    the terminal offer — fall-in spelling at n = 0 (`bxzero`), stored
    spelling at n ≥ 1 (`bx`); both discharge against the ONE declared
    invariant through the layer's index routing. -/
theorem segdone_exit (seed : Nat) (n : Int)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 256 < 1152921504606846976)
    (hn0 : 0 ≤ n) (hn1 : n ≤ 100)
    (ham : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < 4) →
      bm.get? (nAddr + (i : Int)) = (i32 n)[i]?) :
    (t5SeamInv (pOf seed n bm am)).ExitOb C5 46
      n.toNat (t5Offer (pOf seed n bm am)) := by
  show Seg.SegDone _ 46 ((t5SeamInv (pOf seed n bm am)).St n.toNat) _
  have hsc : (pOf seed n bm am).symc0 + 256 < supplyCeil := hsB
  match hN : n.toNat with
  | 0 =>
    have hn0' : n = 0 := by omega
    rw [t5SeamInv_St_eq _ 0]
    refine (Seg.SegDone.of_chain (k := 45) ?_).mono (by omega)
    show ∀ fuel, _
    have hch := bxzero_chainrel (envOf (St (pOf seed n bm am) 0))
      (St (pOf seed n bm am) 0).layout_state
      (St (pOf seed n bm am) 0).trace
      (St (pOf seed n bm am) 0).core_run_state0.aid_supply
      (St (pOf seed n bm am) 0).core_run_state0.excluded_supply
      (St (pOf seed n bm am) 0).core_run_state0.sym_supply
      (St (pOf seed n bm am) 0).dr_step_counter
      n (triF 0) 0
      hdig (St_built _ 0) (St_lkN _ hsc 0 (by omega))
      (St_lkS _ hsc 0 (by omega)) (St_lkI _ hsc 0 (by omega))
      (St_dd _ 0 0) (St_dd _ 0 2) (St_dd _ 0 3)
      (St_alN _ ham 0) (St_alS _ 0) (St_alI _ 0)
      (St_fpm _ 0) (St_lum _ 0)
      (St_rdN _ hb 0) (St_rdS _ 0) (St_rdI _ 0)
      (recon_i32 nAddr n (by omega) (by omega))
      (recon_i32 sAddr (triF 0) (by decide) (by decide))
      (recon_i32 iAddr 0 (by decide) (by decide))
      (by omega) hn0 hn1 (by omega) (by omega)
      (triF_nonneg 0) (triF_le 0 (by omega))
      (by rw [St_symc]; show seed + 2 * 0 < 1152921504606846976; omega)
      (by rw [St_exc]; show 0 + 2 * 0 < 1152921504606846976; omega)
    intro fuel
    rw [show St (pOf seed n bm am) 0
      = mkLH1 (envOf (St (pOf seed n bm am) 0))
          (St (pOf seed n bm am) 0).layout_state
          (St (pOf seed n bm am) 0).trace
          (St (pOf seed n bm am) 0).core_run_state0.aid_supply
          (St (pOf seed n bm am) 0).core_run_state0.excluded_supply
          (St (pOf seed n bm am) 0).core_run_state0.sym_supply
          (St (pOf seed n bm am) 0).dr_step_counter
      from St0_align _]
    rw [show t5Offer (pOf seed n bm am)
      = (NDactive (fmapAddBy defaultCompare 0
          [Step_done2 (Vloaded (LVspecified (OVinteger
            (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
              (triF 0)))))] fmapEmpty),
         exitAt0 (pOf seed n bm am)) from by
        unfold t5Offer stFin
        rw [show (pOf seed n bm am).n = n from rfl, hN]]
    exact hch fuel
  | m + 1 =>
    rw [t5SeamInv_St_eq _ (m + 1), St_align _ m]
    refine Seg.SegDone.of_chain (k := 46) ?_
    have hlt : ((m + 1 : Nat) : Int) ≤ n := by omega
    have hch := bx_chainrel (envOf (St (pOf seed n bm am) (m + 1)))
      (St (pOf seed n bm am) (m + 1)).layout_state
      (St (pOf seed n bm am) (m + 1)).trace
      (St (pOf seed n bm am) (m + 1)).core_run_state0.aid_supply
      (St (pOf seed n bm am) (m + 1)).core_run_state0.excluded_supply
      (St (pOf seed n bm am) (m + 1)).core_run_state0.sym_supply
      (St (pOf seed n bm am) (m + 1)).dr_step_counter
      n (triF (m + 1)) ((m + 1 : Nat) : Int)
      hdig (St_built _ (m + 1)) (St_lkN _ hsc (m + 1) (by omega))
      (St_lkS _ hsc (m + 1) (by omega)) (St_lkI _ hsc (m + 1) (by omega))
      (St_dd _ (m + 1) 0) (St_dd _ (m + 1) 2) (St_dd _ (m + 1) 3)
      (St_alN _ ham (m + 1)) (St_alS _ (m + 1)) (St_alI _ (m + 1))
      (St_fpm _ (m + 1)) (St_lum _ (m + 1))
      (St_rdN _ hb (m + 1)) (St_rdS _ (m + 1)) (St_rdI _ (m + 1))
      (recon_i32 nAddr n (by omega) (by omega))
      (recon_i32 sAddr (triF (m + 1))
        (by have := triF_nonneg (m + 1); omega)
        (by have := triF_le (m + 1) (by omega); omega))
      (recon_i32 iAddr ((m + 1 : Nat) : Int) (by omega) (by omega))
      (by omega) hn0 hn1 (by omega) (by omega)
      (triF_nonneg (m + 1)) (triF_le (m + 1) (by omega))
      (by rw [St_symc]; show seed + 2 * (m + 1) < 1152921504606846976
          omega)
      (by rw [St_exc]; show 0 + 2 * (m + 1) < 1152921504606846976
          omega)
    intro fuel
    rw [show t5Offer (pOf seed n bm am)
      = (NDactive (fmapAddBy defaultCompare 0
          [Step_done2 (Vloaded (LVspecified (OVinteger
            (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
              (triF (m + 1))))))] fmapEmpty),
         exitAt (pOf seed n bm am) (m + 1)) from by
        unfold t5Offer stFin
        rw [show (pOf seed n bm am).n = n from rfl, hN]]
    exact hch fuel

/-! ## The final state, its fixed rest, and the scratch2 feed -/

/-- THE FINAL STATE of the driver atom (post-`prepare_exit`) — the
    scratch2 rule's fixture function `F`. -/
noncomputable def t5Fin (seed : Nat) (n : Int)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : driver_state :=
  { stFin (pOf seed n bm am) with
    core_state0 := prepare_exit (stFin (pOf seed n bm am)).core_state0
      (vD5 n) }

/-- THE FIXED FINAL REST (the walk's ρ'; canonical at zeroed maps). -/
noncomputable def rDone5 (seed : Nat) (n : Int) : driver_state :=
  restOf (t5Fin seed n Std.TreeMap.empty Std.TreeMap.empty)

/-- restOf commutes with the exit record update (structural). -/
theorem restOf_pex (σ : driver_state) (v : value) :
    restOf { σ with core_state0 := prepare_exit σ.core_state0 v }
      = { restOf σ with
          core_state0 := prepare_exit (restOf σ).core_state0 v } := rfl

/-- The final rest is MAP-INDEPENDENT (the family's rest-independence
    through the exit + prepare_exit layers). -/
@[seg_fact]
theorem t5Fin_rest (seed : Nat) (n : Int) : ∀ bm am,
    restOf (t5Fin seed n bm am) = rDone5 seed n := by
  intro bm am
  show restOf { stFin (pOf seed n bm am) with
      core_state0 := prepare_exit (stFin (pOf seed n bm am)).core_state0
        (vD5 n) } = _
  rw [restOf_pex]
  rw [show restOf (stFin (pOf seed n bm am))
    = restOf (stFin (zeroP (pOf seed n bm am)))
    from stFin_rest_indep (pOf seed n bm am)]
  rfl

/-- The final allocation table (the scratch2 insert-insert-erase-erase
    chain at nidA = 2, nidB = 3). -/
@[seg_fact]
theorem t5Fin_allocs (seed : Nat) (n : Int) : ∀ bm am,
    (t5Fin seed n bm am).layout_state.allocations
      = (((am.insert 2 allocS).insert 3 allocI).erase 3).erase 2 := by
  intro bm am
  show (stFin (pOf seed n bm am)).layout_state.allocations = _
  rw [stFin_layout]
  show (((St (pOf seed n bm am)
    n.toNat).layout_state.allocations.erase 3).erase 2) = _
  rw [St_allocs]
  rfl

/-- Final bytes outside the two scratch ranges read the harness map
    (stated at the rule's length spelling so unification pins the
    final images before the binder domains are compared). -/
@[seg_fact]
theorem t5Fin_out (seed : Nat) (n : Int) : ∀ bm am (a : Int),
    ¬(sAddr ≤ a ∧ a < sAddr + (i32 (triF n.toNat)).length) →
    ¬(iAddr ≤ a ∧ a < iAddr + (i32 n).length) →
    (t5Fin seed n bm am).layout_state.bytemap.get? a = bm.get? a := by
  intro bm am a hs hi
  show (stFin (pOf seed n bm am)).layout_state.bytemap.get? a = _
  rw [stFin_layout]
  exact St_bm_out (pOf seed n bm am) _ a
    (by rw [i32_len] at hs; exact hs) (by rw [i32_len] at hi; exact hi)

/-- Final s-range bytes: the closed sum's image. -/
@[seg_fact]
theorem t5Fin_s (seed : Nat) (n : Int) :
    ∀ bm am (i : Nat), i < (i32 (triF n.toNat)).length →
    (t5Fin seed n bm am).layout_state.bytemap.get? (sAddr + (i : Int))
      = (i32 (triF n.toNat))[i]? := by
  intro bm am i hi
  rw [i32_len] at hi
  show (stFin (pOf seed n bm am)).layout_state.bytemap.get? _ = _
  rw [stFin_layout]
  rw [show (pOf seed n bm am).n = n from rfl]
  exact St_bm_s (pOf seed n bm am) n.toNat i hi

/-- Final i-range bytes: the trip count's image. -/
@[seg_fact]
theorem t5Fin_i (seed : Nat) (n : Int) (hn0 : 0 ≤ n) :
    ∀ bm am (i : Nat), i < (i32 n).length →
    (t5Fin seed n bm am).layout_state.bytemap.get? (iAddr + (i : Int))
      = (i32 n)[i]? := by
  intro bm am i hi
  rw [i32_len] at hi
  show (stFin (pOf seed n bm am)).layout_state.bytemap.get? _ = _
  rw [stFin_layout]
  rw [show (pOf seed n bm am).n = n from rfl]
  rw [St_bm_i (pOf seed n bm am) n.toNat i hi]
  rw [Int.toNat_of_nonneg hn0]

/-- Geometry: the s image is nonempty. -/
@[seg_fact]
theorem t5_szA1 (n : Int) : 1 ≤ (i32 (triF n.toNat)).length := by
  rw [i32_len]
  omega

/-- Geometry: the s range sits below the ready water mark. -/
@[seg_fact]
theorem t5_rangeA (seed : Nat) (n : Int) :
    sAddr + ((i32 (triF n.toNat)).length : Int)
      ≤ ((rRdy5 seed).layout_state.lastAddress : Int) := by
  rw [i32_len,
    show ((rRdy5 seed).layout_state.lastAddress : Int) = errAddr
      from rfl, sAddr_eq, show errAddr = (281474976710644 : Int)
      from rfl]
  omega

/-- Geometry: the i range sits below the s range. -/
@[seg_fact]
theorem t5_rangeB (n : Int) :
    iAddr + ((i32 n).length : Int) ≤ sAddr := by
  rw [i32_len, sAddr_eq, iAddr_eq]
  omega

/-! ## Family scalar pins consumed at ρ' (map-independent; via the
    fixed rest) -/

theorem St_nid (p : Pm) (k : Nat) :
    (St p k).layout_state.nextAllocId = 4 := by
  induction k with
  | zero => rfl
  | succ k ih =>
    rw [St_mem_step p k]
    show (memStep (St p k).layout_state (triF k) (k : Int)).nextAllocId = 4
    rw [show ∀ mem sv iv, (memStep mem sv iv).nextAllocId
      = mem.nextAllocId from fun _ _ _ => rfl]
    exact ih

theorem St_last (p : Pm) (k : Nat) :
    (St p k).layout_state.lastAddress = iAddr := by
  induction k with
  | zero => rfl
  | succ k ih =>
    rw [St_mem_step p k]
    show (memStep (St p k).layout_state (triF k) (k : Int)).lastAddress
      = iAddr
    rw [show ∀ mem sv iv, (memStep mem sv iv).lastAddress
      = mem.lastAddress from fun _ _ _ => rfl]
    exact ih

/-- ρ' scalar pin: the bump counter moved by the two scratch
    creates. -/
@[seg_fact]
theorem rDone5_nid (seed : Nat) (n : Int) :
    ((rDone5 seed n).layout_state.nextAllocId : Int)
      = ((rRdy5 seed).layout_state.nextAllocId : Int) + 2 := by
  show ((t5Fin seed n Std.TreeMap.empty
    Std.TreeMap.empty).layout_state.nextAllocId : Int) = 2 + 2
  rw [show (t5Fin seed n Std.TreeMap.empty
      Std.TreeMap.empty).layout_state.nextAllocId
    = (stFin (pOf seed n Std.TreeMap.empty
      Std.TreeMap.empty)).layout_state.nextAllocId from rfl]
  rw [stFin_layout]
  show ((St (pOf seed n Std.TreeMap.empty Std.TreeMap.empty)
    n.toNat).layout_state.nextAllocId : Int) = 2 + 2
  rw [St_nid]
  rfl

/-- ρ' scalar pin: the water mark at the second scratch. -/
@[seg_fact]
theorem rDone5_last (seed : Nat) (n : Int) :
    ((rDone5 seed n).layout_state.lastAddress : Int) = iAddr := by
  show ((t5Fin seed n Std.TreeMap.empty
    Std.TreeMap.empty).layout_state.lastAddress : Int) = iAddr
  rw [show (t5Fin seed n Std.TreeMap.empty
      Std.TreeMap.empty).layout_state.lastAddress
    = (stFin (pOf seed n Std.TreeMap.empty
      Std.TreeMap.empty)).layout_state.lastAddress from rfl]
  rw [stFin_layout]
  show ((St (pOf seed n Std.TreeMap.empty Std.TreeMap.empty)
    n.toNat).layout_state.lastAddress : Int) = iAddr
  rw [St_last]

/-- ρ' scalar pin: both scratch ids on the dead list. -/
@[seg_fact]
theorem rDone5_dead (seed : Nat) (n : Int) :
    (rDone5 seed n).layout_state.deadAllocations
      = 2 :: 3 :: (rRdy5 seed).layout_state.deadAllocations := by
  show (t5Fin seed n Std.TreeMap.empty
    Std.TreeMap.empty).layout_state.deadAllocations = 2 :: 3 :: []
  rw [show (t5Fin seed n Std.TreeMap.empty
      Std.TreeMap.empty).layout_state.deadAllocations
    = (stFin (pOf seed n Std.TreeMap.empty
      Std.TreeMap.empty)).layout_state.deadAllocations from rfl]
  rw [stFin_layout]
  show 2 :: 3 :: (St (pOf seed n Std.TreeMap.empty Std.TreeMap.empty)
    n.toNat).layout_state.deadAllocations = 2 :: 3 :: []
  rw [St_dead]

/-! ## THE DRIVER ATOM (the composed segment through
    `driver2_of_seg`; the layer's loop judgment inside) -/

/-- The composed whole-run terminal segment: entry chain + the seam's
    body obligations (∀-k pack) + the twin exit — `InvMap.while_inv`
    at the ONE declared invariant. -/
theorem t5_run_seg (seed : Nat) (n : Int)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 256 < 1152921504606846976)
    (hn0 : 0 ≤ n) (hn1 : n ≤ 100)
    (ham : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < 4) →
      bm.get? (nAddr + (i : Int)) = (i32 n)[i]?) :
    Seg.SegDone C5 (22 + (79 * n.toNat + 46))
      (mkRdy bm am [] 0 0 seed 0) (t5Offer (pOf seed n bm am)) := by
  have hentry : Seg.Seg C5 22
      (mkRdy bm am [] 0 0 seed 0)
      ((t5SeamInv (pOf seed n bm am)).St 0) := by
    rw [t5SeamInv_St_eq _ 0]
    exact Seg.Seg.of_chain
      (e_chainrel bm am [] 0 0 seed 0 hdig (by omega) (by omega))
  have hbody : (t5SeamInv (pOf seed n bm am)).BodyOb
      C5 79 n.toNat := by
    intro k hk
    have hkn : (k : Int) < n := by omega
    match k, hk with
    | 0, hk =>
      exact (t5_seam_body0 (pOf seed n bm am)
        (packAt seed n bm am hdig hsB hn0 hn1 ham hb 0 hkn)).mono
        (by omega)
    | (k + 1), hk =>
      exact t5_seam_bodyS (pOf seed n bm am) k
        (packAt seed n bm am hdig hsB hn0 hn1 ham hb (k + 1) hkn)
  have hexit := segdone_exit seed n bm am hdig hsB hn0 hn1 ham hb
  exact hentry.trans_done
    (Seg.InvMap.while_inv [t5SeamInv (pOf seed n bm am)]
      (l := symWhile) rfl hbody hexit)

/-- THE DRIVER LOOP at open maps ([`@seg_eq scratch2`]): the whole
    `driver2` atom characterized by the ready rest + n's footprint;
    both scratch lifetimes (s and i: create, n-fold interleaved
    stores, kill) are internal to the equation; the errno object
    rides the frame. -/
@[seg_eq scratch2]
theorem driver2_o (seed : Nat) (n : Int)
    (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 256 < 1152921504606846976)
    (hn0 : 0 ≤ n) (hn1 : n ≤ 100) : ∀ bm am,
    am.get? 0 = some allocN →
    (∀ i : Nat, (hi : i < (argBytes5 n).length) →
      bm.get? (nAddr + (i : Int)) = some ((argBytes5 n)[i])) →
    app (driver2 t5File.tagDefs false) (setMaps (rRdy5 seed) bm am)
      = (NDactive (), t5Fin seed n bm am) := by
  intro bm am ham hb
  rw [mkRdy5_align seed bm am]
  have hb' : ∀ i : Nat, (hi : i < 4) →
      bm.get? (nAddr + (i : Int)) = (i32 n)[i]? := by
    intro i hi
    rw [hb i (by rw [i32_len]; omega)]
    exact (i32_get n i hi).symm
  have hN : n.toNat ≤ 100 := by omega
  refine Seg.driver2_of_seg rfl
    (((t5_run_seg seed n bm am hdig hsB hn0 hn1 ham hb').mono
      ?_ : Seg.SegDone _ lemDefaultFuel _ _)) rfl
  show 22 + (79 * n.toNat + 46) ≤ lemDefaultFuel
  rw [show lemDefaultFuel = 999999 + 1 from rfl]
  omega

/-! ## The terminal readout (the harness's `nd_get` + finalize) -/

theorem fin_bx (env : Fmap sym value) (mem : CerbMem.MemState)
    (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)
    (v : value) (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) :
    (finalize t5File.tagDefs "callND"
      (setMaps (restOf { bx44 env mem tr aid exc symc ctr n sv iv with
        core_state0 := prepare_exit
          (bx44 env mem tr aid exc symc ctr n sv iv).core_state0 v })
        bm am)).dres_core_value
    = v := rfl

theorem fin_bxz (env : Fmap sym value) (mem : CerbMem.MemState)
    (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)
    (v : value) (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) :
    (finalize t5File.tagDefs "callND"
      (setMaps (restOf { bxzero43 env mem tr aid exc symc ctr n sv iv with
        core_state0 := prepare_exit
          (bxzero43 env mem tr aid exc symc ctr n sv iv).core_state0 v })
        bm am)).dres_core_value
    = v := rfl

/-- The finalize readout at the fixed final rest: the exit value. -/
theorem rDone5_readout (seed : Nat) (n : Int)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) :
    (finalize t5File.tagDefs "callND"
      (setMaps (rDone5 seed n) bm am)).dres_core_value = vD5 n := by
  show (finalize t5File.tagDefs "callND"
    (setMaps (restOf { stFin (pOf seed n Std.TreeMap.empty
        Std.TreeMap.empty) with
      core_state0 := prepare_exit (stFin (pOf seed n Std.TreeMap.empty
        Std.TreeMap.empty)).core_state0 (vD5 n) })
      bm am)).dres_core_value = vD5 n
  unfold stFin
  rw [show (pOf seed n Std.TreeMap.empty Std.TreeMap.empty).n = n
    from rfl]
  cases hN : n.toNat with
  | zero =>
    show (finalize t5File.tagDefs "callND"
      (setMaps (restOf { exitAt0 (pOf seed n Std.TreeMap.empty
          Std.TreeMap.empty) with
        core_state0 := prepare_exit (exitAt0 (pOf seed n
          Std.TreeMap.empty Std.TreeMap.empty)).core_state0 (vD5 n) })
        bm am)).dres_core_value = vD5 n
    exact fin_bxz ..
  | succ m =>
    show (finalize t5File.tagDefs "callND"
      (setMaps (restOf { exitAt (pOf seed n Std.TreeMap.empty
          Std.TreeMap.empty) (m + 1) with
        core_state0 := prepare_exit (exitAt (pOf seed n
          Std.TreeMap.empty Std.TreeMap.empty)
          (m + 1)).core_state0 (vD5 n) })
        bm am)).dres_core_value = vD5 n
    exact fin_bx ..

end RelSem.T5
