/-
  RelSem.T2Threaded — arc-16 S4 (2026-08-24): T2 AT THE THREADED
  ∀-SEED STATE (charter S4 + the [USER] effect-state amendment; the
  T1Threaded recipe applied to the add fixture).

  Statement: for EVERY supply seed and int-range x, y with x+y in
  range, outcomes of callND(t2_add, [x, y]) from the seed-parametric
  initial state = {Specified(x+y)}, no UB. Cones: EXACTLY the
  classical trio (Audit-pinned).

  Reuse discipline: ALL of T2AppEq's round lemmas are ∀-run-state
  (round13's last pin dissolved by the arc-17 S1 `erun_jump_m`
  construct law) — the chain below consumes the committed rounds
  AS-IS at the threaded run states; the only threaded text is the
  prefix skeleton (whose memory stages route through the kit at the
  open state — the recorded spike hazard) and the composition. The
  statement-facing discharge is the S1–S3 WP route (per-step walk
  over `callK`, S3 tactics, threaded adequacy bridges).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
-- arc-18 R4: the statement-facing discharge runs THROUGH THE SEGMENT
-- LAYER (verify_fn + seg_auto over the registered equation supply)
import RelSem.SegmentFaces
import RelSem.PerStepTactics
import RelSem.CerbHeapWalk
import RelSem.T2Walks

set_option autoImplicit false

namespace RelSem.T2

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (aU intCty loadedV intRange mkByte zeroByte)
open RelSem.Kit (stub_defined liftCore_run_defined)
open Iris Iris.ProgramLogic Iris.BI

/-! ## The threaded T2 run states -/

/-- Post-globals run-state at seed (twin of T2's `rsD3`). -/
def rsD3_thr (seed : Nat) : core_run_state :=
  { initial_core_run_state_threaded seed
      (collect_labeled_continuations_NEW t2File) with tid_supply := 1 }

def rsB_thr (seed : Nat) : core_run_state :=
  { rsD3_thr seed with aid_supply := (rsD3_thr seed).aid_supply + 1 }
def rsAB_thr (seed : Nat) : core_run_state :=
  { rsB_thr seed with aid_supply := (rsB_thr seed).aid_supply + 1 }

/-- The final driver state of the threaded harness run. -/
def drDone_thr (seed : Nat) (x y : Int) : driver_state :=
  mkDr (thDone x y) (memD3 x y) (rsAB_thr seed) (tr2 x y) 13

/-! ## The per-stage equations at the threaded states (WP-walk feed;
    non-memory stages `rfl` at the open state, memory stages through
    the kit — all memory-level equations REUSED from T2AppEq,
    seed-free) -/

/-- The post-globals driver state at seed. -/
def dG_thr (seed : Nat) : driver_state :=
  mkDr thG CerbMem.initialMemState (rsD3_thr seed) [] 0

theorem k1_thr (seed : Nat) :
    app (driver_globals t2File.tagDefs false t2File)
        (initial_driver_state_threaded seed t2File t2Fs)
      = (NDactive 0, dG_thr seed) := rfl

theorem k3_thr (seed : Nat) :
    app (resolveFunSym (dG_thr seed).core_file "add") (dG_thr seed)
      = (NDactive addT2Sym, dG_thr seed) := rfl

theorem k4_thr (seed : Nat) :
    app (lookupFunBody (dG_thr seed).core_file addT2Sym) (dG_thr seed)
      = (NDactive ([(symA, BTy_object OTy_pointer),
                    (symB, BTy_object OTy_pointer)], arena0),
         dG_thr seed) := rfl

theorem k5_thr (seed : Nat) :
    app (lookupParamTys (dG_thr seed).core_file addT2Sym) (dG_thr seed)
      = (NDactive [signed_int, signed_int], dG_thr seed) := rfl

/-- Stage 6: BOTH argument injections through the kit (T2AppEq's
    `prefix_a1` interior, restated at the open state). -/
theorem k6_thr (seed : Nat) (x y : Int) :
    app (injectArgs t2File.tagDefs 0
          [(symA, BTy_object OTy_pointer), (symB, BTy_object OTy_pointer)]
          [signed_int, signed_int] [intValue x, intValue y])
        (dG_thr seed)
      = (NDactive [(symA, aPtrV), (symB, bPtrV)],
         mkDr thG (memInj x y) (rsD3_thr seed) [] 0) := by
  simp only [injectArgs, injectArg, mvvA_fact]
  apply (app_bind_active (app_liftND_active _ _ _ _ ?hma)).trans
  case hma =>
    refine (app_bind_active allocA_eq).trans ?_
    refine (app_bind_active (storeA_eq x)).trans ?_
    exact app_nd_return (Vobject (OVpointer aPtr)) (memA x)
  apply (app_bind_active ?hinjb).trans
  case hinjb =>
    apply (app_bind_active (app_liftND_active _ _ _ _ ?hmb)).trans
    case hmb =>
      refine (app_bind_active (allocB_eq x)).trans ?_
      refine (app_bind_active (storeB_eq x y)).trans ?_
      exact app_nd_return (Vobject (OVpointer bPtr)) (memInj x y)
    refine (app_bind_active rfl).trans ?_   -- injectArgs []
    rfl
  rfl

theorem k7_thr (seed : Nat) (x y : Int) :
    app get_thread_states (mkDr thG (memInj x y) (rsD3_thr seed) [] 0)
      = (NDactive [(0, (none, thG))],
         mkDr thG (memInj x y) (rsD3_thr seed) [] 0) := rfl

/-- Stage 8: the errno allocate+store through the memory lens
    (T2AppEq's `allocErr_eq`/`storeErr_eq`, seed-free). -/
theorem k8_thr (seed : Nat) (x y : Int) :
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
      (mkDr thG (memInj x y) (rsD3_thr seed) [] 0)
      = (NDactive errPtr,
         mkDr thG (memD3 x y) (rsD3_thr seed) [] 0) := by
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
      (memInj x y) = (NDactive errPtr, memD3 x y) :=
    (app_bind_active (allocErr_eq x y)).trans
      ((app_bind_active (storeErr_eq x y)).trans
        (app_nd_return errPtr (memD3 x y)))
  exact app_liftND_active _ _ _ _ hmem

theorem k9_thr (seed : Nat) (x y : Int) (th : thread_state)
    (hth : th = th0) :
    app (driver_update_thread_state 0 th : driverM Unit)
        (mkDr thG (memD3 x y) (rsD3_thr seed) [] 0)
      = (NDactive (), mkDr th0 (memD3 x y) (rsD3_thr seed) [] 0) := by
  subst hth; rfl

/-! ## The rounds: ALL SIXTEEN are the committed ∀-rs lemmas, consumed
    as-is in the chain (arc-17 S1: R13 — the label-resolution eval,
    T2's last rs-pinned round — is ∀-rs through the `erun_jump_m`
    construct law; its `round13_thr` twin is dissolved, the chain
    discharges `hlab` by `rfl` at `rsAB_thr seed`). -/

/-! ## Composition -/

/-- The full dnms run at the threaded state (the committed chain with
    the run-state arguments at their threaded twins; fifteen of the
    sixteen rounds are the committed lemmas unchanged). -/
theorem dnms_chain_thr (seed : Nat) (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) :
    app (dnms lemDefaultFuel fmapEmpty [0])
        (mkDr th0 (memD3 x y) (rsD3_thr seed) [] 0)
      = (NDactive (accDone (x+y)),
         mkDr (th15 x y) (memD3 x y) (rsAB_thr seed) (tr2 x y) 13) :=
  (round0 999999 (memD3 x y) (rsD3_thr seed) [] 0).trans
  ((round1 999998 (memD3 x y) (rsD3_thr seed) [] 1).trans
  ((round2 999997 (memD3 x y) (rsD3_thr seed) [] 2).trans
  ((round3 x y hy1 hy2 999996 (rsD3_thr seed) [] 3).trans
  ((round4 y 999995 (memD3 x y) (rsB_thr seed) (tr1 y) 3).trans
  ((round5 y 999994 (memD3 x y) (rsB_thr seed) (tr1 y) 4).trans
  ((round6 y 999993 (memD3 x y) (rsB_thr seed) (tr1 y) 5).trans
  ((round7 x y hx1 hx2 999992 (rsB_thr seed) (tr1 y) 6).trans
  ((round8 x y 999991 (memD3 x y) (rsAB_thr seed) (tr2 x y) 6).trans
  ((round9 x y 999990 (memD3 x y) (rsAB_thr seed) (tr2 x y) 7).trans
  ((round10 x y hx1 hx2 hy1 hy2 hs1 hs2 999989 (rsAB_thr seed)
      (tr2 x y) 8).trans
  ((round11 x y 999988 (memD3 x y) (rsAB_thr seed) (tr2 x y) 9).trans
  ((round12 x y 999987 (memD3 x y) (rsAB_thr seed) (tr2 x y) 10).trans
  ((round13 x y hs1 hs2 999986 (memD3 x y) (rsAB_thr seed) rfl
      (tr2 x y) 11).trans
  ((round14 x y 999985 (memD3 x y) (rsAB_thr seed) (tr2 x y) 12).trans
  (round15 x y 999983 (memD3 x y) (rsAB_thr seed) (tr2 x y) 13)))))))))))))))

/-- The scheduler sees exactly the done step (arc-17 S1: through the
    `ndct_offer1` construct law — the per-fixture scheduler text is
    gone). -/
theorem ndct_eq_thr (seed : Nat) (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) :
    app (new_drive_core_threads t2File.tagDefs ())
        (mkDr th0 (memD3 x y) (rsD3_thr seed) [] 0)
      = (NDactive [(0, some (Step_done2 (loadedV (x+y))))],
         mkDr (th15 x y) (memD3 x y) (rsAB_thr seed) (tr2 x y) 13) :=
  RelSem.Laws.ndct_offer1 rfl
    ((dnms_chain_thr seed x y hx1 hx2 hy1 hy2 hs1 hs2).trans (by rfl))

/-- ONE driver2 iteration does the whole run (arc-17 S1: through the
    `driver2_done` construct law — the per-fixture execution-mode
    `cases` dance is gone). -/
theorem driver2_iter_thr (seed : Nat) (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) :
    app (driver2 t2File.tagDefs false)
        (mkDr th0 (memD3 x y) (rsD3_thr seed) [] 0)
      = (NDactive (), drDone_thr seed x y) := by
  show app (driver2_lemFuel (999999+1) t2File.tagDefs false)
    (mkDr th0 (memD3 x y) (rsD3_thr seed) [] 0)
    = (NDactive (), drDone_thr seed x y)
  exact RelSem.Laws.driver2_done
    (ndct_eq_thr seed x y hx1 hx2 hy1 hy2 hs1 hs2) (by rfl)

/-- THE THREADED T2 HARNESS APP EQUATION. -/
theorem t2_app_eq_thr (seed : Nat) (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) :
    app (callND t2File.tagDefs t2File "add" [intValue x, intValue y])
        (initial_driver_state_threaded seed t2File t2Fs)
      = (NDactive (finalize t2File.tagDefs "callND" (drDone_thr seed x y)),
         drDone_thr seed x y) := by
  refine (app_bind_active (k1_thr seed)).trans ?_
  refine (app_bind_active (app_nd_get (dG_thr seed))).trans ?_
  refine (app_bind_active (k3_thr seed)).trans ?_
  refine (app_bind_active (k4_thr seed)).trans ?_
  refine (app_bind_active (k5_thr seed)).trans ?_
  refine (app_bind_active (k6_thr seed x y)).trans ?_
  refine (app_bind_active (k7_thr seed x y)).trans ?_
  refine (app_bind_active (k8_thr seed x y)).trans ?_
  refine (app_bind_active (k9_thr seed x y _ (by rfl))).trans ?_
  refine (app_bind_active
    (driver2_iter_thr seed x y hx1 hx2 hy1 hy2 hs1 hs2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- finTail's nd_get
  rfl                                            -- nd_return finalize

/-- The finalize result carries the sum, Specified. -/
theorem t2_result_eq_thr (seed : Nat) (x y : Int) :
    (finalize t2File.tagDefs "callND"
        (drDone_thr seed x y)).dres_core_value
      = intValue (x+y) := rfl

/-! ## The statement-facing route (arc-18 C2, THE ONE ROUTE): the
    per-step WP walk over `CerbMemInterp` — open-memory equation
    supply, footprint resources only (the T1Threaded recipe at the
    two-argument fixture: BOTH argument objects are minted by the
    double-inject compound and consumed read-only by the driver-loop
    step; the errno object rides the frame across the whole loop). -/

/-! ### The rest ladder -/

abbrev rInit2 (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed t2File t2Fs)
abbrev rGlob2 (seed : Nat) : driver_state := restOf (dG_thr seed)
abbrev rInj2 (seed : Nat) : driver_state :=
  restAllocR (restAllocR (rGlob2 seed) aAddr) bAddr
abbrev rErr2 (seed : Nat) : driver_state := restAllocR (rInj2 seed) errAddr
/-- The D3 rest-layout (x-free: the non-map fields of the run's
    fixed memory). -/
abbrev memR2 : CerbMem.MemState := memRest (memD3 0 0)
abbrev rD32 (seed : Nat) : driver_state :=
  mkDr th0 memR2 (rsD3_thr seed) [] 0
abbrev rDone2 (seed : Nat) (x y : Int) : driver_state :=
  mkDr (thDone x y) memR2 (rsAB_thr seed) (tr2 x y) 13

/-- The stored byte image of an injected int argument. -/
def argBytes2 (v : Int) : List CerbMem.AbsByte :=
  [mkByte v 0, mkByte v 1, mkByte v 2, mkByte v 3]

/-! ### The open-memory stage equations -/

@[seg_eq rest]
theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals t2File.tagDefs false t2File)
        (setMaps (rInit2 seed) bm am)
      = (NDactive 0, setMaps (rGlob2 seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG_thr seed).core_file "add")
        (setMaps (rGlob2 seed) bm am)
      = (NDactive addT2Sym, setMaps (rGlob2 seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG_thr seed).core_file addT2Sym)
        (setMaps (rGlob2 seed) bm am)
      = (NDactive ([(symA, BTy_object OTy_pointer),
                    (symB, BTy_object OTy_pointer)], arena0),
         setMaps (rGlob2 seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG_thr seed).core_file addT2Sym)
        (setMaps (rGlob2 seed) bm am)
      = (NDactive [signed_int, signed_int], setMaps (rGlob2 seed) bm am) :=
  fun _ _ => rfl

@[seg_fact]
theorem argAddrA_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rGlob2 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = aAddr := by
  rw [show (rGlob2 seed).layout_state.lastAddress
    = (281474976710655 : Int) from rfl]
  decide

@[seg_fact]
theorem argAddrB_fact :
    ((CerbMem.alignDown ((aAddr : Int) - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = bAddr := by
  decide

/-- Stage 6, BOTH ARGUMENT INJECTIONS at open maps (through the
    `inject_ptr_arg2` construct law + the Kit mem blocks). -/
@[seg_eq argobj2]
theorem k6_o (seed : Nat) (x y : Int) : ∀ bm am,
    app (injectArgs t2File.tagDefs 0
          [(symA, BTy_object OTy_pointer), (symB, BTy_object OTy_pointer)]
          [signed_int, signed_int] [intValue x, intValue y])
        (setMaps (rGlob2 seed) bm am)
      = (NDactive [(symA, aPtrV), (symB, bPtrV)],
         allocStoreState (restAllocR (restAllocR (rGlob2 seed) aAddr) bAddr)
           (allocStoreBytes bm aAddr 4 (argBytes2 x)) (am.insert 0 allocA)
           bAddr 4 (argBytes2 y) 1 allocB) := by
  intro bm am
  refine Laws.inject_ptr_arg2 (σ := setMaps (rGlob2 seed) bm am)
    (hmvA := mvvA_fact x) (hmvB := mvvA_fact y)
    (hallocA := Kit.mem_alloc_block (sz := 4) (a := aAddr)
      (by exact rfl) (argAddrA_fact seed) (by exact rfl))
    (hstoreA := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval x))
      (allocId := 0) (addr := aAddr) (alloc := allocA)
      (fpm := []) (bytes := argBytes2 x)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 0 allocA).get? 0 = some allocA
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact storeArg_bytes_fact x))
    (hallocB := Kit.mem_alloc_block (sz := 4) (a := bAddr)
      (by exact rfl)
      (by
        rw [writeBytesTo_lastAddress, writeBytesTo_lastAddress]
        exact argAddrB_fact)
      (by exact rfl))
    (hstoreB := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval y))
      (allocId := 1) (addr := bAddr) (alloc := allocB)
      (fpm := []) (bytes := argBytes2 y)
      (hcompat := by exact rfl)
      (hget := by
        simp only [Kit.writeBytesTo_allocations]
        show ((am.insert 0 allocA).insert 1 allocB).get? 1 = some allocB
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        simp only [Kit.writeBytesTo_funptrmap]
        exact storeArg_bytes_fact y))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

@[seg_eq rest]
theorem k7_o (seed : Nat) : ∀ bm am,
    app get_thread_states (setMaps (rInj2 seed) bm am)
      = (NDactive [(0, (none, thG))], setMaps (rInj2 seed) bm am) :=
  fun _ _ => rfl

@[seg_fact]
theorem errAddr2_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rInj2 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = errAddr := by
  rw [show (rInj2 seed).layout_state.lastAddress = bAddr from rfl]
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
      (setMaps (rInj2 seed) bm am)
      = (NDactive errPtr,
         allocStoreState (restAllocR (rInj2 seed) errAddr) bm am errAddr
           4 [zeroByte, zeroByte, zeroByte, zeroByte] 2 allocErr) := by
  intro bm am
  refine Laws.callND_errno (σ := setMaps (rInj2 seed) bm am)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := errAddr)
      (by exact rfl) (errAddr2_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))
      (allocId := 2) (addr := errAddr) (alloc := allocErr)
      (fpm := []) (bytes := [zeroByte, zeroByte, zeroByte, zeroByte])
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 2 allocErr).get? 2 = some allocErr
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
theorem k9_o (seed : Nat) (th : thread_state) (hth : th = th0) :
    ∀ bm am,
    app (driver_update_thread_state 0 th : driverM Unit)
        (setMaps (rErr2 seed) bm am)
      = (NDactive (), setMaps (rD32 seed) bm am) := by
  subst hth; exact fun _ _ => rfl

/-! ### The driver loop at open maps: T2AppEq's rounds are already
    ∀-mem except the two loads (3/7) and the add-eval (10) — those
    three get open twins here. -/

/-- The T2 D3-shaped memory with open maps. -/
abbrev memOpen2 (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { memR2 with bytemap := bm, allocations := am }

/-- R3, the load of b at open maps. -/
theorem round3_o (x y : Int)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647) (fuel : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (rs : core_run_state) (tr : List trace_event) (n : Nat)
    (hget : am.get? 1 = some allocB)
    (hb : ∀ i : Nat, (hi : i < (argBytes2 y).length) →
      bm.get? (bAddr + (i : Int)) = some ((argBytes2 y)[i])) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th3 (memOpen2 bm am) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th4 y) (memOpen2 bm am)
          { rs with aid_supply := rs.aid_supply + 1 }
          (meLoadB y :: tr) n) := by
  have hload : app (CerbMem.loadM CerbLocation.Loc.unknown intCty bPtr)
      (memOpen2 bm am)
      = (NDactive (CerbMem.Footprint.FP .R bAddr 4,
          CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none y)),
         memOpen2 bm am) := by
    have hbytes : CerbMem.readBytesFrom (memOpen2 bm am) bAddr
        (CerbMem.sizeofCtype intCty) = argBytes2 y := by
      refine readBytesFrom_of_pointwise (by rfl) ?_
      intro i hi
      show bm.get? (bAddr + (i : Int)) = _
      exact hb i hi
    have := Kit.mem_load_block (loc := CerbLocation.Loc.unknown)
      (ty := intCty) (allocId := 1) (addr := bAddr) (um := none)
      (alloc := allocB) (mem := memOpen2 bm am)
      (mv := CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none y))
      (hdead := rfl) (hget := hget)
      (hbounds := by exact rfl) (hatomic := by exact rfl)
      (hbytes := hbytes)
      (hrecon := reconB_eq x y hy1 hy2)
      (hnotbool := rfl)
    simpa [bPtr, RelSem.T1.sizeof_intCty_eq] using this
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
      case hload => exact hload
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

/-- R7, the load of a at open maps. -/
theorem round7_o (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647) (fuel : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (rs : core_run_state) (tr : List trace_event) (n : Nat)
    (hget : am.get? 0 = some allocA)
    (hb : ∀ i : Nat, (hi : i < (argBytes2 x).length) →
      bm.get? (aAddr + (i : Int)) = some ((argBytes2 x)[i])) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr (th7 y) (memOpen2 bm am) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th8 x y) (memOpen2 bm am)
          { rs with aid_supply := rs.aid_supply + 1 }
          (meLoadA x :: tr) n) := by
  have hload : app (CerbMem.loadM CerbLocation.Loc.unknown intCty aPtr)
      (memOpen2 bm am)
      = (NDactive (CerbMem.Footprint.FP .R aAddr 4,
          CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
         memOpen2 bm am) := by
    have hbytes : CerbMem.readBytesFrom (memOpen2 bm am) aAddr
        (CerbMem.sizeofCtype intCty) = argBytes2 x := by
      refine readBytesFrom_of_pointwise (by rfl) ?_
      intro i hi
      show bm.get? (aAddr + (i : Int)) = _
      exact hb i hi
    have := Kit.mem_load_block (loc := CerbLocation.Loc.unknown)
      (ty := intCty) (allocId := 0) (addr := aAddr) (um := none)
      (alloc := allocA) (mem := memOpen2 bm am)
      (mv := CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x))
      (hdead := rfl) (hget := hget)
      (hbounds := by exact rfl) (hatomic := by exact rfl)
      (hbytes := hbytes)
      (hrecon := reconA_eq x y hx1 hx2)
      (hnotbool := rfl)
    simpa [aPtr, RelSem.T1.sizeof_intCty_eq] using this
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
      case hload => exact hload
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

/-- R10, the add evaluation at open memory (pure — the committed
    proof verbatim at a free memory state). -/
theorem round10_o (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (fuel : Nat) (ms : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th10 x y) ms rs tr n)
      = app (dnms fuel fmapEmpty [0])
          (mkDr (th11 x y) ms rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hEv).trans
      case hEv =>
        change stExceptUndef_bind _ _ _ = _
        refine (stub_defined
          (fullEvalCase_eq x y hx1 hx2 hy1 hy2 hs1 hs2 _ _)).trans ?_
        rfl
      rfl
    rfl
  rfl

/-- THE DRIVER LOOP at open maps: characterized by the rest + BOTH
    argument objects' footprints; the errno object is never
    mentioned — it rides the frame across the entire loop. -/
@[seg_eq read2]
theorem driver2_o (seed : Nat) (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) : ∀ bm am,
    am.get? 0 = some allocA → am.get? 1 = some allocB →
    (∀ i : Nat, (hi : i < (argBytes2 x).length) →
      bm.get? (aAddr + (i : Int)) = some ((argBytes2 x)[i])) →
    (∀ i : Nat, (hi : i < (argBytes2 y).length) →
      bm.get? (bAddr + (i : Int)) = some ((argBytes2 y)[i])) →
    app (driver2 t2File.tagDefs false) (setMaps (rD32 seed) bm am)
      = (NDactive (), setMaps (rDone2 seed x y) bm am) := by
  intro bm am hgA hgB hbA hbB
  have hchain : app (dnms lemDefaultFuel fmapEmpty [0])
      (mkDr th0 (memOpen2 bm am) (rsD3_thr seed) [] 0)
      = (NDactive (accDone (x+y)),
         mkDr (th15 x y) (memOpen2 bm am) (rsAB_thr seed) (tr2 x y) 13) :=
    (round0 999999 (memOpen2 bm am) (rsD3_thr seed) [] 0).trans
    ((round1 999998 (memOpen2 bm am) (rsD3_thr seed) [] 1).trans
    ((round2 999997 (memOpen2 bm am) (rsD3_thr seed) [] 2).trans
    ((round3_o x y hy1 hy2 999996 bm am (rsD3_thr seed) [] 3 hgB hbB).trans
    ((round4 y 999995 (memOpen2 bm am) (rsB_thr seed) (tr1 y) 3).trans
    ((round5 y 999994 (memOpen2 bm am) (rsB_thr seed) (tr1 y) 4).trans
    ((round6 y 999993 (memOpen2 bm am) (rsB_thr seed) (tr1 y) 5).trans
    ((round7_o x y hx1 hx2 999992 bm am (rsB_thr seed) (tr1 y) 6 hgA hbA).trans
    ((round8 x y 999991 (memOpen2 bm am) (rsAB_thr seed) (tr2 x y) 6).trans
    ((round9 x y 999990 (memOpen2 bm am) (rsAB_thr seed) (tr2 x y) 7).trans
    ((round10_o x y hx1 hx2 hy1 hy2 hs1 hs2 999989 (memOpen2 bm am)
        (rsAB_thr seed) (tr2 x y) 8).trans
    ((round11 x y 999988 (memOpen2 bm am) (rsAB_thr seed) (tr2 x y) 9).trans
    ((round12 x y 999987 (memOpen2 bm am) (rsAB_thr seed) (tr2 x y) 10).trans
    ((round13 x y hs1 hs2 999986 (memOpen2 bm am) (rsAB_thr seed) rfl
        (tr2 x y) 11).trans
    ((round14 x y 999985 (memOpen2 bm am) (rsAB_thr seed) (tr2 x y) 12).trans
    (round15 x y 999983 (memOpen2 bm am) (rsAB_thr seed) (tr2 x y) 13)))))))))))))))
  have hndct : app (new_drive_core_threads t2File.tagDefs ())
      (setMaps (rD32 seed) bm am)
      = (NDactive [(0, some (Step_done2 (loadedV (x+y))))],
         mkDr (th15 x y) (memOpen2 bm am) (rsAB_thr seed) (tr2 x y) 13) :=
    RelSem.Laws.ndct_offer1 rfl (hchain.trans (by rfl))
  show app (driver2_lemFuel (999999+1) t2File.tagDefs false)
    (setMaps (rD32 seed) bm am)
    = (NDactive (), setMaps (rDone2 seed x y) bm am)
  exact RelSem.Laws.driver2_done hndct (by rfl)

/-- The post-globals canonical representative (`nd_get` joint). -/
@[seg_canon]
theorem t2_canon (seed : Nat) :
    RelSem.Seg.CanonAt (rGlob2 seed) (dG_thr seed) := rfl

/-- T2's FnSpec ([F9]): `add(x, y) = Specified (x + y)` over the
    range-tripled input pair (REDUCIBLE; two-parameter family). -/
abbrev addSpec : RelSem.Seg.FnSpec (Int × Int) :=
  { fname := "add", args := fun p => [intValue p.1, intValue p.2],
    pre := fun p => intRange p.1 ∧ intRange p.2 ∧ intRange (p.1 + p.2),
    post := fun p => t2Spec p.1 p.2 }

/-! ## THE THREADED STATEMENTS -/

/-- THE T2 THREADED HEADLINE (fuel opsem only, ∀-seed). -/
def T2ThreadedStatement : Prop :=
  ∀ (seed : Nat) (x y : Int),
    intRange x → intRange y → intRange (x + y) →
    CallHarnessAdequateThr seed t2File.tagDefs t2File "add"
      [intValue x, intValue y] t2Fs (t2Spec x y)

/-- **T2 THREADED, UNCONDITIONAL** (arc-18 R4: THROUGH THE SEGMENT
    LAYER — statement text byte-stable across the re-housing; trio
    cone). -/
theorem T2Threaded : T2ThreadedStatement := by
  verify_fn addSpec
  seg_auto

/-- **T2 THREADED UB-freedom** (same route). -/
theorem T2Threaded_ubFree :
    ∀ (seed : Nat) (x y : Int),
      intRange x → intRange y → intRange (x + y) →
      CallHarnessUBFreeThr seed t2File.tagDefs t2File "add"
        [intValue x, intValue y] t2Fs := by
  verify_fn addSpec
  seg_auto

/-- T2's threaded outcome-SET companion. -/
def T2ThreadedOutcomesStatement : Prop :=
  ∀ (seed : Nat) (x y : Int),
    intRange x → intRange y → intRange (x + y) →
    CerbND.runND (callND t2File.tagDefs t2File "add"
        [intValue x, intValue y])
        (initial_driver_state_threaded seed t2File t2Fs)
      = [(Active (finalize t2File.tagDefs "callND" (drDone_thr seed x y)),
          [], drDone_thr seed x y)]

/-- **T2's threaded outcome-set singleton**. -/
theorem T2ThreadedOutcomes : T2ThreadedOutcomesStatement :=
  fun seed x y hx hy hs =>
    runND_active (t2_app_eq_thr seed x y hx.1 hx.2 hy.1 hy.2 hs.1 hs.2)

end RelSem.T2
