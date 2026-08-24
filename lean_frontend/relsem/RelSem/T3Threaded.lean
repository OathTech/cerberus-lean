/-
  RelSem.T3Threaded — arc-16 S4 (2026-08-24): T3 AT THE THREADED
  ∀-SEED STATE (charter S4 + the [USER] effect-state amendment; the
  T1Threaded recipe applied to the alloc/store/load/kill roundtrip
  fixture).

  Statement: for EVERY supply seed and int-range v, outcomes of
  callND(t3_roundtrip, [v]) from the seed-parametric initial state
  = {Specified(v)}, no UB. Cones: EXACTLY the classical trio
  (Audit-pinned).

  Reuse discipline: of T3AppEq's twenty-four rounds only `round21`
  (the second conv/save eval round) pins the ambient run state — the
  chain consumes the other twenty-three committed ∀-rs lemmas AS-IS
  at the threaded run-state ladder and twins round21, the prefix
  skeleton (memory stages through the kit at the open state), and the
  composition. Statement-facing discharge: the S1–S3 WP route.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.T3

set_option autoImplicit false

namespace RelSem.T3

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (aU intCty loadedV intRange)
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

/-! ## The rounds: only R21 pins the run state — twinned; the other
    twenty-three are the committed ∀-rs lemmas -/

/-- R21, threaded (twin of `round21`; identical recipe — the
    rs-generic `fullEvalConvRun` carries conv chain #2 + the save
    jump's label resolution at the open state). -/
theorem round21_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (mem : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr (th21 x) mem (rs5_thr seed) tr n)
      = app (dnms fuel fmapEmpty [0])
        (mkDr (th22 x) mem (rs5_thr seed) tr (n+1)) := by
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
          apply (stub_defined (fullEvalConvRun x h1 h2 _ _)).trans
          rfl
        rfl
      rfl
    rfl
  rfl

/-! ## Composition -/

/-- The full dnms run at the threaded state: twenty-three committed
    ∀-rs rounds + the twinned R21 + terminal, at the threaded
    run-state ladder. -/
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
  ((round21_thr seed x h1 h2 999978 (memK x)
      [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 16).trans
  ((round22 x 999977 (memK x) (rs5_thr seed)
      [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 17).trans
  (round23 x 999975 (memK x) (rs5_thr seed)
      [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18)))))))))))))))))))))))

/-- The scheduler sees exactly the done step. -/
theorem ndct_eq_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (new_drive_core_threads t3File.tagDefs ())
        (mkDr th00 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive [(0, some (Step_done2 (loadedV x)))],
         mkDr (th23 x) (memK x) (rs5_thr seed)
           [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active (dnms_chain_thr seed x h1 h2)).trans ?_
  rfl

/-- ONE driver2 iteration does the whole run. -/
theorem driver2_iter_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (driver2 t3File.tagDefs false)
        (mkDr th00 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive (), drDone_thr seed x) := by
  show app (driver2_lemFuel (999999+1) t3File.tagDefs false)
    (mkDr th00 (memD3 x) (rsD3_thr seed) [] 0)
    = (NDactive (), drDone_thr seed x)
  change app (nd_bind _ _) _ = _
  refine (app_bind_active (ndct_eq_thr seed x h1 h2)).trans ?_
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

/-! ## The statement-facing route (S1–S3) -/

/-- T3's WP over the per-step instance at the threaded initial state. -/
theorem t3_wpK_thr {GF : BundledGFunctors} [CerbGpreS GF]
    [CerbGS .hasLC GF] (seed : Nat) (x : Int) (hx : intRange x) :
    (stateIs (GF := GF) (initial_driver_state_threaded seed t3File t3Fs)) ⊢
      WP (callK t3File.tagDefs t3File "roundtrip" [intValue x])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ t3Spec x r⌝ }} := by
  iintro Hst
  wp_step (k1_thr seed) Hst
  wp_step (app_nd_get (dG_thr seed)) Hst
  wp_step (k3_thr seed) Hst
  wp_step (k4_thr seed) Hst
  wp_step (k5_thr seed) Hst
  wp_step (k6_thr seed x) Hst
  wp_step (k7_thr seed x) Hst
  wp_step (k8_thr seed x) Hst
  wp_step (k9_thr seed x _ (by rfl)) Hst
  wp_step (driver2_iter_thr seed x hx.1 hx.2) Hst
  wp_step (app_nd_get (drDone_thr seed x)) Hst
  wp_done
  ipureintro
  exact ⟨_, rfl, t3_result_eq_thr seed x⟩

/-! ## THE THREADED STATEMENTS -/

/-- THE T3 THREADED HEADLINE (fuel opsem only, ∀-seed). -/
def T3ThreadedStatement : Prop :=
  ∀ (seed : Nat) (x : Int), intRange x →
    CallHarnessAdequateThr seed t3File.tagDefs t3File "roundtrip"
      [intValue x] t3Fs (t3Spec x)

/-- **T3 THREADED, UNCONDITIONAL** (S1–S3 WP route; trio cone). -/
theorem T3Threaded : T3ThreadedStatement := by
  intro seed x hx
  refine kCallHarnessAdequateThr_of_wp (GF := CerbS) seed
    t3File.tagDefs t3File "roundtrip" [intValue x] t3Fs (t3Spec x) ?_
  intro η
  exact t3_wpK_thr seed x hx

/-- **T3 THREADED UB-freedom**. -/
theorem T3Threaded_ubFree :
    ∀ (seed : Nat) (x : Int), intRange x →
      CallHarnessUBFreeThr seed t3File.tagDefs t3File "roundtrip"
        [intValue x] t3Fs := by
  intro seed x hx
  refine kCallHarnessUBFreeThr_of_wp (GF := CerbS) seed
    t3File.tagDefs t3File "roundtrip" [intValue x] t3Fs (t3Spec x) ?_
  intro η
  exact t3_wpK_thr seed x hx

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

/-- SANITY, nothing lost (DELIBERATELY impure — the ambient bridge;
    labeled pin in Audit.lean). -/
theorem T3_of_threaded : T3Statement := fun x hx =>
  callHarnessAdequate_of_thr (fun seed => T3Threaded seed x hx)

end RelSem.T3
