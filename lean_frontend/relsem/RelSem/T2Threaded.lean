/-
  RelSem.T2Threaded — arc-16 S4 (2026-08-24): T2 AT THE THREADED
  ∀-SEED STATE (charter S4 + the [USER] effect-state amendment; the
  T1Threaded recipe applied to the add fixture).

  Statement: for EVERY supply seed and int-range x, y with x+y in
  range, outcomes of callND(t2_add, [x, y]) from the seed-parametric
  initial state = {Specified(x+y)}, no UB. Cones: EXACTLY the
  classical trio (Audit-pinned).

  Reuse discipline: T2AppEq's round lemmas are ∀-run-state EXCEPT
  `round13` (the Erun eval round, which pins the ambient `rsAB` for
  the label resolution) — the chain below consumes the committed
  rounds AS-IS at the threaded run states and twins only round13, the
  prefix skeleton (whose memory stages route through the kit at the
  open state — the recorded spike hazard), and the composition. The
  statement-facing discharge is the S1–S3 WP route (per-step walk
  over `callK`, S3 tactics, threaded adequacy bridges).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.T2

set_option autoImplicit false

namespace RelSem.T2

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (aU intCty loadedV intRange)
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

/-! ## The rounds: only R13 pins the run state (label resolution) —
    twinned; every other round is the committed ∀-rs lemma, consumed
    as-is in the chain -/

/-- R13, threaded (twin of `round13`; identical recipe at the
    seed-parametric state — the rs-generic `fullEval_conv_eq` carries
    the sum's conv evaluation). -/
theorem round13_thr (seed : Nat) (x y : Int)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (fuel : Nat) (mem : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr (th13 x y) mem (rsAB_thr seed) tr n)
      = app (dnms fuel fmapEmpty [0])
        (mkDr (th14 x y) mem (rsAB_thr seed) tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_    -- nd_read (step_ctx)
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_  -- rsk match (RSK_eval)
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hLab).trans        -- runSE label resolution
      case hLab => rfl
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hFold).trans       -- the args foldM
      case hFold =>
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hElem).trans
        case hElem =>
          change stExceptUndef_bind _ _ _ = _
          apply (stub_defined (fullEval_conv_eq x y hs1 hs2 _ _)).trans
          rfl
        rfl
      rfl
    rfl
  rfl

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
  ((round13_thr seed x y hs1 hs2 999986 (memD3 x y) (tr2 x y) 11).trans
  ((round14 x y 999985 (memD3 x y) (rsAB_thr seed) (tr2 x y) 12).trans
  (round15 x y 999983 (memD3 x y) (rsAB_thr seed) (tr2 x y) 13)))))))))))))))

/-- The scheduler sees exactly the done step. -/
theorem ndct_eq_thr (seed : Nat) (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) :
    app (new_drive_core_threads t2File.tagDefs ())
        (mkDr th0 (memD3 x y) (rsD3_thr seed) [] 0)
      = (NDactive [(0, some (Step_done2 (loadedV (x+y))))],
         mkDr (th15 x y) (memD3 x y) (rsAB_thr seed) (tr2 x y) 13) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active
    (dnms_chain_thr seed x y hx1 hx2 hy1 hy2 hs1 hs2)).trans ?_
  rfl

/-- ONE driver2 iteration does the whole run. -/
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
  change app (nd_bind _ _) _ = _
  refine (app_bind_active
    (ndct_eq_thr seed x y hx1 hx2 hy1 hy2 hs1 hs2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- nd_get
  cases hmode : Lem_Maybe.maybeEqualBy (fun x y => x == y)
      (CerbGlobal.current_execution_mode ())
      (some CerbGlobal.ExecutionMode.random) with
  | true =>
    simp only [reduceIte, bindExhaustive]
    apply (app_bind_active ?hpickT).trans
    case hpickT => rfl
    apply (app_bind_active ?hdbgT).trans
    case hdbgT => rfl
    rfl
  | false =>
    apply (app_bind_active ?hgrd).trans
    case hgrd => rfl
    apply (app_bind_active ?hpickF).trans
    case hpickF => rfl
    apply (app_bind_active ?hdbgF).trans
    case hdbgF => rfl
    rfl

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

/-! ## The statement-facing route (S1–S3) -/

/-- T2's WP over the per-step instance at the threaded initial state
    (the `T1_perStep_tac` shape). -/
theorem t2_wpK_thr {GF : BundledGFunctors} [CerbGpreS GF]
    [CerbGS .hasLC GF] (seed : Nat) (x y : Int)
    (hx : intRange x) (hy : intRange y) (hs : intRange (x + y)) :
    (stateIs (GF := GF) (initial_driver_state_threaded seed t2File t2Fs)) ⊢
      WP (callK t2File.tagDefs t2File "add" [intValue x, intValue y])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ t2Spec x y r⌝ }} := by
  iintro Hst
  wp_step (k1_thr seed) Hst
  wp_step (app_nd_get (dG_thr seed)) Hst
  wp_step (k3_thr seed) Hst
  wp_step (k4_thr seed) Hst
  wp_step (k5_thr seed) Hst
  wp_step (k6_thr seed x y) Hst
  wp_step (k7_thr seed x y) Hst
  wp_step (k8_thr seed x y) Hst
  wp_step (k9_thr seed x y _ (by rfl)) Hst
  wp_step (driver2_iter_thr seed x y hx.1 hx.2 hy.1 hy.2 hs.1 hs.2) Hst
  wp_step (app_nd_get (drDone_thr seed x y)) Hst
  wp_done
  ipureintro
  exact ⟨_, rfl, t2_result_eq_thr seed x y⟩

/-! ## THE THREADED STATEMENTS -/

/-- THE T2 THREADED HEADLINE (fuel opsem only, ∀-seed). -/
def T2ThreadedStatement : Prop :=
  ∀ (seed : Nat) (x y : Int),
    intRange x → intRange y → intRange (x + y) →
    CallHarnessAdequateThr seed t2File.tagDefs t2File "add"
      [intValue x, intValue y] t2Fs (t2Spec x y)

/-- **T2 THREADED, UNCONDITIONAL** (S1–S3 WP route; trio cone). -/
theorem T2Threaded : T2ThreadedStatement := by
  intro seed x y hx hy hs
  refine kCallHarnessAdequateThr_of_wp (GF := CerbS) seed
    t2File.tagDefs t2File "add" [intValue x, intValue y] t2Fs
    (t2Spec x y) ?_
  intro η
  exact t2_wpK_thr seed x y hx hy hs

/-- **T2 THREADED UB-freedom**. -/
theorem T2Threaded_ubFree :
    ∀ (seed : Nat) (x y : Int),
      intRange x → intRange y → intRange (x + y) →
      CallHarnessUBFreeThr seed t2File.tagDefs t2File "add"
        [intValue x, intValue y] t2Fs := by
  intro seed x y hx hy hs
  refine kCallHarnessUBFreeThr_of_wp (GF := CerbS) seed
    t2File.tagDefs t2File "add" [intValue x, intValue y] t2Fs
    (t2Spec x y) ?_
  intro η
  exact t2_wpK_thr seed x y hx hy hs

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

/-- SANITY, nothing lost (DELIBERATELY impure — the ambient bridge;
    labeled pin in Audit.lean). -/
theorem T2_of_threaded : T2Statement := fun x y hx hy hs =>
  callHarnessAdequate_of_thr (fun seed => T2Threaded seed x y hx hy hs)

end RelSem.T2
