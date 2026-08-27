/-
  RelSem.T3Threaded — arc-16 S4 (2026-08-24): T3 AT THE THREADED
  ∀-SEED STATE (charter S4 + the [USER] effect-state amendment; the
  T1Threaded recipe applied to the alloc/store/load/kill roundtrip
  fixture).

  Statement: for EVERY supply seed and int-range v, outcomes of
  callND(t3_roundtrip, [v]) from the seed-parametric initial state
  = {Specified(v)}, no UB. Cones: EXACTLY the classical trio
  (Audit-pinned).

  Reuse discipline: ALL twenty-four of T3AppEq's rounds are ∀-run-
  state (round21's last pin dissolved by the arc-17 S1 `erun_jump_m`
  construct law) — the chain consumes the committed lemmas AS-IS at
  the threaded run-state ladder; the only threaded text is the prefix
  skeleton (memory stages through the kit at the open state) and the
  composition. Statement-facing discharge: the S1–S3 WP route.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
-- arc-18 R4: the statement-facing discharge runs THROUGH THE SEGMENT
-- LAYER (verify_fn + seg_auto over the registered equation supply)
import RelSem.SegmentFaces
import RelSem.PerStepTactics
import RelSem.CerbHeapWalk
import RelSem.T3Walks

set_option autoImplicit false

namespace RelSem.T3

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (aU intCty loadedV intRange mkByte zeroByte)
open RelSem.T2 (storeArg_bytes_fact)
open RelSem.Kit (stub_defined liftCore_run_defined)
open Iris Iris.ProgramLogic Iris.BI

/-! ## The threaded T3 run states (the five action-id draws) -/

/-- Post-globals run-state at seed (twin of T3's `rsD3`). -/
def rsD3_thr (seed : Nat) : core_run_state :=
  { initial_core_run_state_threaded seed
      (collect_labeled_continuations_NEW t3File) with tid_supply := 1 }

def rs1_thr (seed : Nat) : core_run_state :=
  { rsD3_thr seed with aid_supply := (rsD3_thr seed).aid_supply + 1 }
def rs2_thr (seed : Nat) : core_run_state :=
  { rs1_thr seed with aid_supply := (rs1_thr seed).aid_supply + 1 }
def rs3_thr (seed : Nat) : core_run_state :=
  { rs2_thr seed with aid_supply := (rs2_thr seed).aid_supply + 1 }
def rs4_thr (seed : Nat) : core_run_state :=
  { rs3_thr seed with aid_supply := (rs3_thr seed).aid_supply + 1 }
def rs5_thr (seed : Nat) : core_run_state :=
  { rs4_thr seed with aid_supply := (rs4_thr seed).aid_supply + 1 }

/-- The final driver state of the threaded harness run. -/
def drDone_thr (seed : Nat) (x : Int) : driver_state :=
  mkDr (thDone x) (memK x) (rs5_thr seed)
    [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18

/-! ## The per-stage equations at the threaded states -/

/-- The post-globals driver state at seed. -/
def dG_thr (seed : Nat) : driver_state :=
  mkDr thG CerbMem.initialMemState (rsD3_thr seed) [] 0

theorem k1_thr (seed : Nat) :
    app (driver_globals t3File.tagDefs false t3File)
        (initial_driver_state_threaded seed t3File t3Fs)
      = (NDactive 0, dG_thr seed) := rfl

theorem k3_thr (seed : Nat) :
    app (resolveFunSym (dG_thr seed).core_file "roundtrip") (dG_thr seed)
      = (NDactive roundtripT3Sym, dG_thr seed) := rfl

theorem k4_thr (seed : Nat) :
    app (lookupFunBody (dG_thr seed).core_file roundtripT3Sym)
        (dG_thr seed)
      = (NDactive ([(symV, BTy_object OTy_pointer)], arena00),
         dG_thr seed) := rfl

theorem k5_thr (seed : Nat) :
    app (lookupParamTys (dG_thr seed).core_file roundtripT3Sym)
        (dG_thr seed)
      = (NDactive [signed_int], dG_thr seed) := rfl

/-- Stage 6: the argument injection through the kit (T3AppEq's
    `prefix_a1` interior at the open state). -/
theorem k6_thr (seed : Nat) (x : Int) :
    app (injectArgs t3File.tagDefs 0
          [(symV, BTy_object OTy_pointer)] [signed_int] [intValue x])
        (dG_thr seed)
      = (NDactive [(symV, vPtrV)],
         mkDr thG (memV x) (rsD3_thr seed) [] 0) := by
  simp only [injectArgs, injectArg, mvvV_fact]
  apply (app_bind_active (app_liftND_active _ _ _ _ ?hmv)).trans
  case hmv =>
    refine (app_bind_active allocV_eq).trans ?_
    refine (app_bind_active (storeV_eq x)).trans ?_
    exact app_nd_return (Vobject (OVpointer vPtr)) (memV x)
  refine (app_bind_active rfl).trans ?_   -- injectArgs []
  rfl

theorem k7_thr (seed : Nat) (x : Int) :
    app get_thread_states (mkDr thG (memV x) (rsD3_thr seed) [] 0)
      = (NDactive [(0, (none, thG))],
         mkDr thG (memV x) (rsD3_thr seed) [] 0) := rfl

/-- Stage 8: the errno allocate+store through the memory lens
    (T3AppEq's `errAlloc_eq`/`errStore_eq`, seed-free). -/
theorem k8_thr (seed : Nat) (x : Int) :
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
      (mkDr thG (memV x) (rsD3_thr seed) [] 0)
      = (NDactive errPtr,
         mkDr thG (memD3 x) (rsD3_thr seed) [] 0) := by
  have hmem : app (nd_bind
      (CerbMem.allocateObject 0 (PrefOther "errno")
        (CerbMem.alignofIval signed_int) signed_int none none)
      (fun (ptr_val : CerbMem.PointerValue) =>
        let zero := CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval (0 : Int))
        nd_bind
          (CerbMem.storeM (CerbLocation.other "errno init")
            signed_int false ptr_val zero)
          (fun (_ : CerbMem.Footprint) => nd_return ptr_val)))
      (memV x) = (NDactive errPtr, memD3 x) :=
    (app_bind_active (errAlloc_eq x)).trans
      ((app_bind_active (errStore_eq x)).trans
        (app_nd_return errPtr (memD3 x)))
  exact app_liftND_active _ _ _ _ hmem

theorem k9_thr (seed : Nat) (x : Int) (th : thread_state)
    (hth : th = th00) :
    app (driver_update_thread_state 0 th : driverM Unit)
        (mkDr thG (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive (), mkDr th00 (memD3 x) (rsD3_thr seed) [] 0) := by
  subst hth; rfl

/-! ## The rounds: ALL TWENTY-FOUR are the committed ∀-rs lemmas
    (arc-17 S1: R21 — the last rs-pinned round — is ∀-rs through the
    `erun_jump_m` construct law; its `round21_thr` twin is dissolved,
    the chain discharges `hlab` by `rfl` at `rs5_thr seed`). -/

/-! ## Composition -/

/-- The full dnms run at the threaded state: the twenty-four committed
    ∀-rs rounds + terminal, at the threaded run-state ladder. -/
theorem dnms_chain_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnms lemDefaultFuel fmapEmpty [0])
        (mkDr th00 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive (accDone x),
         mkDr (th23 x) (memK x) (rs5_thr seed)
           [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18) :=
  (round0 999999 (memD3 x) (rsD3_thr seed) [] 0).trans
  ((round1 x 999998 (rsD3_thr seed) [] 1).trans
  ((round2 x 999997 (memC x) (rs1_thr seed) [meCreate] 1).trans
  ((round3 999996 (memC x) (rs1_thr seed) [meCreate] 2).trans
  ((round4 999995 (memC x) (rs1_thr seed) [meCreate] 3).trans
  ((round5 999994 (memC x) (rs1_thr seed) [meCreate] 4).trans
  ((round6 x h1 h2 999993 (rs1_thr seed) [meCreate] 5).trans
  ((round7 x 999992 (memC x) (rs2_thr seed) [meLoadV x, meCreate] 5).trans
  ((round8 x 999991 (memC x) (rs2_thr seed) [meLoadV x, meCreate] 6).trans
  ((round9 x h1 h2 999990 (memC x) (rs2_thr seed)
      [meLoadV x, meCreate] 7).trans
  ((round10 x 999989 (rs2_thr seed) [meLoadV x, meCreate] 8).trans
  ((round11 x 999988 (memS x) (rs3_thr seed)
      [meStore x, meLoadV x, meCreate] 8).trans
  ((round12 x 999987 (memS x) (rs3_thr seed)
      [meStore x, meLoadV x, meCreate] 9).trans
  ((round13 x 999986 (memS x) (rs3_thr seed)
      [meStore x, meLoadV x, meCreate] 10).trans
  ((round14 x 999985 (memS x) (rs3_thr seed)
      [meStore x, meLoadV x, meCreate] 11).trans
  ((round15 x h1 h2 999984 (rs3_thr seed)
      [meStore x, meLoadV x, meCreate] 12).trans
  ((round16 x 999983 (memS x) (rs4_thr seed)
      [meLoadX x, meStore x, meLoadV x, meCreate] 12).trans
  ((round17 x 999982 (memS x) (rs4_thr seed)
      [meLoadX x, meStore x, meLoadV x, meCreate] 13).trans
  ((round18 x 999981 (memS x) (rs4_thr seed)
      [meLoadX x, meStore x, meLoadV x, meCreate] 14).trans
  ((round19 x 999980 (rs4_thr seed)
      [meLoadX x, meStore x, meLoadV x, meCreate] 15).trans
  ((round20 x 999979 (memK x) (rs5_thr seed)
      [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 15).trans
  ((round21 x h1 h2 999978 (memK x) (rs5_thr seed) rfl
      [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 16).trans
  ((round22 x 999977 (memK x) (rs5_thr seed)
      [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 17).trans
  (round23 x 999975 (memK x) (rs5_thr seed)
      [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18)))))))))))))))))))))))

/-- The scheduler sees exactly the done step (arc-17 S1: through the
    `ndct_offer1` construct law — the per-fixture scheduler text is
    gone). -/
theorem ndct_eq_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (new_drive_core_threads t3File.tagDefs ())
        (mkDr th00 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive [(0, some (Step_done2 (loadedV x)))],
         mkDr (th23 x) (memK x) (rs5_thr seed)
           [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18) :=
  RelSem.Laws.ndct_offer1 rfl
    ((dnms_chain_thr seed x h1 h2).trans (by rfl))

/-- ONE driver2 iteration does the whole run (arc-17 S1: through the
    `driver2_done` construct law — the per-fixture execution-mode
    `cases` dance is gone). -/
theorem driver2_iter_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (driver2 t3File.tagDefs false)
        (mkDr th00 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive (), drDone_thr seed x) := by
  show app (driver2_lemFuel (999999+1) t3File.tagDefs false)
    (mkDr th00 (memD3 x) (rsD3_thr seed) [] 0)
    = (NDactive (), drDone_thr seed x)
  exact RelSem.Laws.driver2_done
    (ndct_eq_thr seed x h1 h2) (by rfl)

/-- THE THREADED T3 HARNESS APP EQUATION. -/
theorem t3_app_eq_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (callND t3File.tagDefs t3File "roundtrip" [intValue x])
        (initial_driver_state_threaded seed t3File t3Fs)
      = (NDactive (finalize t3File.tagDefs "callND" (drDone_thr seed x)),
         drDone_thr seed x) := by
  refine (app_bind_active (k1_thr seed)).trans ?_
  refine (app_bind_active (app_nd_get (dG_thr seed))).trans ?_
  refine (app_bind_active (k3_thr seed)).trans ?_
  refine (app_bind_active (k4_thr seed)).trans ?_
  refine (app_bind_active (k5_thr seed)).trans ?_
  refine (app_bind_active (k6_thr seed x)).trans ?_
  refine (app_bind_active (k7_thr seed x)).trans ?_
  refine (app_bind_active (k8_thr seed x)).trans ?_
  refine (app_bind_active (k9_thr seed x _ (by rfl))).trans ?_
  refine (app_bind_active (driver2_iter_thr seed x h1 h2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- finTail's nd_get
  rfl                                            -- nd_return finalize

/-- The finalize result carries the injected integer, Specified. -/
theorem t3_result_eq_thr (seed : Nat) (x : Int) :
    (finalize t3File.tagDefs "callND"
        (drDone_thr seed x)).dres_core_value
      = intValue x := rfl

/-! ## The statement-facing route (arc-18 C2, THE ONE ROUTE): the
    per-step WP walk over `CerbMemInterp` at the roundtrip fixture —
    the driver loop CREATES, STORES, LOADS and KILLS a scratch object
    entirely within one step: the scratch allocation fragment is
    minted and consumed inside the rule (net unobservable), its dead
    bytes come out as D2 dead capital, and the errno object rides the
    frame across the whole loop. -/

/-! ### The rest ladder + open-memory layout ladder -/

abbrev rInit3 (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed t3File t3Fs)
abbrev rGlob3 (seed : Nat) : driver_state := restOf (dG_thr seed)
abbrev rV3 (seed : Nat) : driver_state := restAllocR (rGlob3 seed) vAddr
abbrev rErr3 (seed : Nat) : driver_state := restAllocR (rV3 seed) errAddr
/-- The D3 rest-layout (x-free). -/
abbrev memR3 : CerbMem.MemState := memRest (memD3 0)
/-- The post-create rest-layout. -/
abbrev memRC3 : CerbMem.MemState := memRest (memC 0)
/-- The post-kill rest-layout. -/
abbrev memRK3 : CerbMem.MemState := memRest (memK 0)
abbrev rD33 (seed : Nat) : driver_state :=
  mkDr th00 memR3 (rsD3_thr seed) [] 0
abbrev rDone3 (seed : Nat) (x : Int) : driver_state :=
  mkDr (thDone x) memRK3 (rs5_thr seed)
    [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18

/-- The stored byte image of an int value. -/
def argBytes3 (v : Int) : List CerbMem.AbsByte :=
  [mkByte v 0, mkByte v 1, mkByte v 2, mkByte v 3]

/-- The open-memory layouts along the loop (D3 / post-create /
    post-store / post-kill). -/
abbrev moD (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { memR3 with bytemap := bm, allocations := am }
abbrev moC (x : Int) (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { memRC3 with
    bytemap := writeList bm xAddr (List.replicate 4 uninitB),
    allocations := am.insert 2 allocX }
abbrev moS (x : Int) (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { memRC3 with
    bytemap := allocStoreBytes bm xAddr 4 (argBytes3 x),
    allocations := am.insert 2 allocX }
abbrev moK (x : Int) (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { memRK3 with
    bytemap := allocStoreBytes bm xAddr 4 (argBytes3 x),
    allocations := (am.insert 2 allocX).erase 2 }

/-! ### The open-memory stage equations -/

@[seg_eq rest]
theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals t3File.tagDefs false t3File)
        (setMaps (rInit3 seed) bm am)
      = (NDactive 0, setMaps (rGlob3 seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG_thr seed).core_file "roundtrip")
        (setMaps (rGlob3 seed) bm am)
      = (NDactive roundtripT3Sym, setMaps (rGlob3 seed) bm am) :=
  fun _ _ => rfl

@[seg_eq rest]
theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG_thr seed).core_file roundtripT3Sym)
        (setMaps (rGlob3 seed) bm am)
      = (NDactive ([(symV, BTy_object OTy_pointer)], arena00),
         setMaps (rGlob3 seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG_thr seed).core_file roundtripT3Sym)
        (setMaps (rGlob3 seed) bm am)
      = (NDactive [signed_int], setMaps (rGlob3 seed) bm am) :=
  fun _ _ => rfl

@[seg_fact]
theorem argAddrV_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rGlob3 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = vAddr := by
  rw [show (rGlob3 seed).layout_state.lastAddress
    = (281474976710655 : Int) from rfl]
  decide

/-- Stage 6, the argument injection at open maps. -/
@[seg_eq argobj]
theorem k6_o (seed : Nat) (x : Int) : ∀ bm am,
    app (injectArgs t3File.tagDefs 0
          [(symV, BTy_object OTy_pointer)] [signed_int] [intValue x])
        (setMaps (rGlob3 seed) bm am)
      = (NDactive [(symV, vPtrV)],
         allocStoreState (restAllocR (rGlob3 seed) vAddr) bm am vAddr 4
           (argBytes3 x) 0 allocV) := by
  intro bm am
  refine Laws.inject_ptr_arg1 (σ := setMaps (rGlob3 seed) bm am)
    (hmv := mvvV_fact x)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := vAddr)
      (by exact rfl) (argAddrV_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval x))
      (allocId := 0) (addr := vAddr) (alloc := allocV)
      (fpm := []) (bytes := argBytes3 x)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 0 allocV).get? 0 = some allocV
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact storeArg_bytes_fact x))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

@[seg_eq rest]
theorem k7_o (seed : Nat) : ∀ bm am,
    app get_thread_states (setMaps (rV3 seed) bm am)
      = (NDactive [(0, (none, thG))], setMaps (rV3 seed) bm am) :=
  fun _ _ => rfl

@[seg_fact]
theorem errAddr3_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rV3 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = errAddr := by
  rw [show (rV3 seed).layout_state.lastAddress = vAddr from rfl]
  decide

/-- Stage 8, the errno block at open maps. -/
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
      (setMaps (rV3 seed) bm am)
      = (NDactive errPtr,
         allocStoreState (restAllocR (rV3 seed) errAddr) bm am errAddr
           4 [zeroByte, zeroByte, zeroByte, zeroByte] 1 allocErr) := by
  intro bm am
  refine Laws.callND_errno (σ := setMaps (rV3 seed) bm am)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := errAddr)
      (by exact rfl) (errAddr3_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))
      (allocId := 1) (addr := errAddr) (alloc := allocErr)
      (fpm := []) (bytes := [zeroByte, zeroByte, zeroByte, zeroByte])
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 1 allocErr).get? 1 = some allocErr
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact RelSem.T1.errStore_bytes_fact))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

/-- Stage 9, the thread setup (rest-only). -/
@[seg_eq rest]
theorem k9_o (seed : Nat) (th : thread_state) (hth : th = th00) :
    ∀ bm am,
    app (driver_update_thread_state 0 th : driverM Unit)
        (setMaps (rErr3 seed) bm am)
      = (NDactive (), setMaps (rD33 seed) bm am) := by
  subst hth; exact fun _ _ => rfl

/-! ### The scratch object's memory ops at open maps -/

theorem createX_o (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (x : Int) :
    app (CerbMem.allocateObject 0 (PrefOther "Core")
      (CerbMem.IntegerValue.IV .Prov_none 4) intCty none none)
      (moD bm am)
    = (NDactive xPtr, moC x bm am) := by
  have h := Kit.mem_alloc_block (tid := 0) (pref := PrefOther "Core")
    (pv := .Prov_none) (alignN := 4) (ty := intCty)
    (mem := moD bm am) (addrOpt := none) (sz := 4) (a := xAddr)
    (by exact rfl)
    (by rw [show (moD bm am).lastAddress = errAddr from rfl]; decide)
    (by exact rfl)
  refine h.trans ?_
  refine congrArg (Prod.mk _) ?_
  simp only [writeBytesTo_eq]
  rfl

theorem storeX_o (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (x : Int) :
    app (CerbMem.storeM CerbLocation.Loc.unknown intCty false
      xPtr (CerbMem.MemValue.MVinteger (Signed Int_)
        (CerbMem.IntegerValue.IV .Prov_none x))) (moC x bm am)
    = (NDactive (CerbMem.Footprint.FP .W xAddr 4), moS x bm am) := by
  have h := Kit.mem_store_block (loc := CerbLocation.Loc.unknown)
    (ty := intCty) (allocId := 2) (addr := xAddr) (alloc := allocX)
    (mem := moC x bm am)
    (mv := CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none x))
    (fpm := []) (bytes := argBytes3 x)
    (hcompat := by exact rfl)
    (hget := by
      show (am.insert 2 allocX).get? 2 = some allocX
      simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
    (hbounds := by exact rfl) (hro := rfl)
    (hatomic := by exact rfl)
    (hbytes := by exact storeArg_bytes_fact x)
  refine h.trans ?_
  refine congrArg (Prod.mk _) ?_
  simp only [writeBytesTo_eq]
  rfl

theorem loadV_o (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (hgV : am.get? 0 = some allocV)
    (hbV : ∀ i : Nat, (hi : i < (argBytes3 x).length) →
      bm.get? (vAddr + (i : Int)) = some ((argBytes3 x)[i])) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty vPtr)
      (moC x bm am)
    = (NDactive (CerbMem.Footprint.FP .R vAddr 4,
        CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
       moC x bm am) := by
  have hbytes : CerbMem.readBytesFrom (moC x bm am) vAddr
      (CerbMem.sizeofCtype intCty) = argBytes3 x := by
    refine readBytesFrom_of_pointwise (by rfl) ?_
    intro i hi
    show (writeList bm xAddr (List.replicate 4 uninitB)).get?
      (vAddr + (i : Int)) = _
    rw [writeList_get?_notin _ _ _ _ (by
      simp only [List.length_replicate]
      right
      show xAddr + (4 : Int) ≤ vAddr + (i : Int)
      have : (xAddr : Int) = 281474976710640 := rfl
      have : (vAddr : Int) = 281474976710648 := rfl
      omega)]
    exact hbV i hi
  have := Kit.mem_load_block (loc := CerbLocation.Loc.unknown)
    (ty := intCty) (allocId := 0) (addr := vAddr) (um := none)
    (alloc := allocV) (mem := moC x bm am)
    (mv := CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x))
    (hdead := rfl)
    (hget := by
      show (am.insert 2 allocX).get? 0 = some allocV
      rw [tm_get?_insert_ne _ (by omega)]
      exact hgV)
    (hbounds := by exact rfl) (hatomic := by exact rfl)
    (hbytes := hbytes)
    (hrecon := reconV_eq x h1 h2)
    (hnotbool := rfl)
  simpa [vPtr, RelSem.T1.sizeof_intCty_eq] using this

theorem loadX_o (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty xPtr)
      (moS x bm am)
    = (NDactive (CerbMem.Footprint.FP .R xAddr 4,
        CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
       moS x bm am) := by
  have hbytes : CerbMem.readBytesFrom (moS x bm am) xAddr
      (CerbMem.sizeofCtype intCty) = argBytes3 x := by
    refine readBytesFrom_of_pointwise (by rfl) ?_
    intro i hi
    show (allocStoreBytes bm xAddr 4 (argBytes3 x)).get?
      (xAddr + (i : Int)) = _
    unfold allocStoreBytes
    simp only [argBytes3, List.length_cons, List.length_nil] at hi
    rw [writeList_get?_in _ _ _ _ (by omega) (by
      show xAddr + (i : Int) < xAddr + (argBytes3 x).length
      simp only [argBytes3, List.length_cons, List.length_nil]
      omega)]
    have hidx : (xAddr + (i : Int) - xAddr).toNat = i := by omega
    rw [hidx]
    exact (List.getElem?_eq_getElem (by
      simp only [argBytes3, List.length_cons, List.length_nil]
      omega))
  have := Kit.mem_load_block (loc := CerbLocation.Loc.unknown)
    (ty := intCty) (allocId := 2) (addr := xAddr) (um := none)
    (alloc := allocX) (mem := moS x bm am)
    (mv := CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x))
    (hdead := rfl)
    (hget := by
      show (am.insert 2 allocX).get? 2 = some allocX
      simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
    (hbounds := by exact rfl) (hatomic := by exact rfl)
    (hbytes := hbytes)
    (hrecon := reconX_eq x h1 h2)
    (hnotbool := rfl)
  simpa [xPtr, RelSem.T1.sizeof_intCty_eq] using this

theorem killX_o (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (x : Int) :
    app (CerbMem.killM CerbLocation.Loc.unknown false xPtr)
      (moS x bm am)
    = (NDactive (), moK x bm am) := by
  have h := Kit.mem_kill_block (loc := CerbLocation.Loc.unknown)
    (allocId := 2) (addr := xAddr) (um := none) (alloc := allocX)
    (mem := moS x bm am)
    (hdead := rfl)
    (hget := by
      show (am.insert 2 allocX).get? 2 = some allocX
      simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
    (hbase := rfl)
  exact h.trans rfl

/-! ### The five memory rounds at open maps (the other nineteen are
    the committed ∀-mem lemmas, instantiated at the open layouts) -/

theorem round1_o (x : Int) (fuel : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th01 (moD bm am) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th02 (moC x bm am)
          { rs with aid_supply := rs.aid_supply + 1 } (meCreate :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [Kit.perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [Kit.ars_create_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?halloc)).trans
      case halloc => exact createX_o bm am x
      rfl
    rfl
  rfl

theorem round6_o (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (rs : core_run_state) (tr : List trace_event) (n : Nat)
    (hgV : am.get? 0 = some allocV)
    (hbV : ∀ i : Nat, (hi : i < (argBytes3 x).length) →
      bm.get? (vAddr + (i : Int)) = some ((argBytes3 x)[i])) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr th06 (moC x bm am) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th07 x) (moC x bm am)
          { rs with aid_supply := rs.aid_supply + 1 }
          (meLoadV x :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [Kit.perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [Kit.ars_load_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hload)).trans
      case hload => exact loadV_o bm am x h1 h2 hgV hbV
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

theorem round10_o (x : Int) (fuel : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr (th10 x) (moC x bm am) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th11 x) (moS x bm am)
          { rs with aid_supply := rs.aid_supply + 1 }
          (meStore x :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [Kit.perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [Kit.ars_store_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hstore)).trans
      case hstore => exact storeX_o bm am x
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

theorem round15_o (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr (th15 x) (moS x bm am) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th16 x) (moS x bm am)
          { rs with aid_supply := rs.aid_supply + 1 }
          (meLoadX x :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [Kit.perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [Kit.ars_load_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hload)).trans
      case hload => exact loadX_o bm am x h1 h2
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

theorem round19_o (x : Int) (fuel : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr (th19 x) (moS x bm am) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th20 x) (moK x bm am)
          { rs with aid_supply := rs.aid_supply + 1 } (meKill :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [Kit.perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [Kit.ars_kill_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hkill)).trans
      case hkill => exact killX_o bm am x
      rfl
    rfl
  rfl

/-- THE DRIVER LOOP at open maps: characterized by the rest + the
    argument object's footprint; the SCRATCH object's whole lifetime
    (create/store/load/kill) is internal to the equation; the errno
    object is never mentioned. -/
@[seg_eq scratch1]
theorem driver2_o (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) : ∀ bm am,
    am.get? 0 = some allocV →
    (∀ i : Nat, (hi : i < (argBytes3 x).length) →
      bm.get? (vAddr + (i : Int)) = some ((argBytes3 x)[i])) →
    app (driver2 t3File.tagDefs false) (setMaps (rD33 seed) bm am)
      = (NDactive (), setMaps (rDone3 seed x)
          (allocStoreBytes bm xAddr 4 (argBytes3 x))
          ((am.insert 2 allocX).erase 2)) := by
  intro bm am hgV hbV
  have hchain : app (dnms lemDefaultFuel fmapEmpty [0])
      (mkDr th00 (moD bm am) (rsD3_thr seed) [] 0)
      = (NDactive (accDone x),
         mkDr (th23 x) (moK x bm am) (rs5_thr seed)
           [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18) :=
    (round0 999999 (moD bm am) (rsD3_thr seed) [] 0).trans
    ((round1_o x 999998 bm am (rsD3_thr seed) [] 1).trans
    ((round2 x 999997 (moC x bm am) (rs1_thr seed) [meCreate] 1).trans
    ((round3 999996 (moC x bm am) (rs1_thr seed) [meCreate] 2).trans
    ((round4 999995 (moC x bm am) (rs1_thr seed) [meCreate] 3).trans
    ((round5 999994 (moC x bm am) (rs1_thr seed) [meCreate] 4).trans
    ((round6_o x h1 h2 999993 bm am (rs1_thr seed) [meCreate] 5 hgV hbV).trans
    ((round7 x 999992 (moC x bm am) (rs2_thr seed) [meLoadV x, meCreate] 5).trans
    ((round8 x 999991 (moC x bm am) (rs2_thr seed) [meLoadV x, meCreate] 6).trans
    ((round9 x h1 h2 999990 (moC x bm am) (rs2_thr seed)
        [meLoadV x, meCreate] 7).trans
    ((round10_o x 999989 bm am (rs2_thr seed) [meLoadV x, meCreate] 8).trans
    ((round11 x 999988 (moS x bm am) (rs3_thr seed)
        [meStore x, meLoadV x, meCreate] 8).trans
    ((round12 x 999987 (moS x bm am) (rs3_thr seed)
        [meStore x, meLoadV x, meCreate] 9).trans
    ((round13 x 999986 (moS x bm am) (rs3_thr seed)
        [meStore x, meLoadV x, meCreate] 10).trans
    ((round14 x 999985 (moS x bm am) (rs3_thr seed)
        [meStore x, meLoadV x, meCreate] 11).trans
    ((round15_o x h1 h2 999984 bm am (rs3_thr seed)
        [meStore x, meLoadV x, meCreate] 12).trans
    ((round16 x 999983 (moS x bm am) (rs4_thr seed)
        [meLoadX x, meStore x, meLoadV x, meCreate] 12).trans
    ((round17 x 999982 (moS x bm am) (rs4_thr seed)
        [meLoadX x, meStore x, meLoadV x, meCreate] 13).trans
    ((round18 x 999981 (moS x bm am) (rs4_thr seed)
        [meLoadX x, meStore x, meLoadV x, meCreate] 14).trans
    ((round19_o x 999980 bm am (rs4_thr seed)
        [meLoadX x, meStore x, meLoadV x, meCreate] 15).trans
    ((round20 x 999979 (moK x bm am) (rs5_thr seed)
        [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 15).trans
    ((round21 x h1 h2 999978 (moK x bm am) (rs5_thr seed) rfl
        [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 16).trans
    ((round22 x 999977 (moK x bm am) (rs5_thr seed)
        [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 17).trans
    (round23 x 999975 (moK x bm am) (rs5_thr seed)
        [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18)))))))))))))))))))))))
  have hndct : app (new_drive_core_threads t3File.tagDefs ())
      (setMaps (rD33 seed) bm am)
      = (NDactive [(0, some (Step_done2 (loadedV x)))],
         mkDr (th23 x) (moK x bm am) (rs5_thr seed)
           [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18) :=
    RelSem.Laws.ndct_offer1 rfl (hchain.trans (by rfl))
  show app (driver2_lemFuel (999999+1) t3File.tagDefs false)
    (setMaps (rD33 seed) bm am)
    = (NDactive (), setMaps (rDone3 seed x)
        (allocStoreBytes bm xAddr 4 (argBytes3 x))
        ((am.insert 2 allocX).erase 2))
  exact RelSem.Laws.driver2_done hndct (by rfl)


/-- The scratch address arithmetic (the create's ground fact at the
    D3 rest). -/
@[seg_fact]
theorem xAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rD33 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = xAddr := by
  rw [show (rD33 seed).layout_state.lastAddress = errAddr from rfl]
  decide

/-- The post-globals canonical representative (`nd_get` joint). -/
@[seg_canon]
theorem t3_canon (seed : Nat) :
    RelSem.Seg.CanonAt (rGlob3 seed) (dG_thr seed) := rfl

/-- T3's FnSpec ([F9]): `roundtrip(x) = Specified x` for range x
    (REDUCIBLE; ∀-x input family; the scratch object's lifetime is
    internal to the driver atom). -/
abbrev roundtripSpec : RelSem.Seg.FnSpec Int :=
  { fname := "roundtrip", args := fun x => [intValue x],
    pre := intRange, post := t3Spec }

/-! ## THE THREADED STATEMENTS -/

/-- THE T3 THREADED HEADLINE (fuel opsem only, ∀-seed). -/
def T3ThreadedStatement : Prop :=
  ∀ (seed : Nat) (x : Int), intRange x →
    CallHarnessAdequateThr seed t3File.tagDefs t3File "roundtrip"
      [intValue x] t3Fs (t3Spec x)

/-- **T3 THREADED, UNCONDITIONAL** (arc-18 R4: THROUGH THE SEGMENT
    LAYER — statement text byte-stable across the re-housing; trio
    cone). -/
theorem T3Threaded : T3ThreadedStatement := by
  verify_fn roundtripSpec
  seg_auto

/-- **T3 THREADED UB-freedom**. -/
theorem T3Threaded_ubFree :
    ∀ (seed : Nat) (x : Int), intRange x →
      CallHarnessUBFreeThr seed t3File.tagDefs t3File "roundtrip"
        [intValue x] t3Fs := by
  verify_fn roundtripSpec
  seg_auto

/-- T3's threaded outcome-SET companion. -/
def T3ThreadedOutcomesStatement : Prop :=
  ∀ (seed : Nat) (x : Int), intRange x →
    CerbND.runND (callND t3File.tagDefs t3File "roundtrip" [intValue x])
        (initial_driver_state_threaded seed t3File t3Fs)
      = [(Active (finalize t3File.tagDefs "callND" (drDone_thr seed x)),
          [], drDone_thr seed x)]

/-- **T3's threaded outcome-set singleton**. -/
theorem T3ThreadedOutcomes : T3ThreadedOutcomesStatement :=
  fun seed x hx => runND_active (t3_app_eq_thr seed x hx.1 hx.2)

end RelSem.T3
