/-
  RelSem.CStepProbe — V3a (2026-08-28): THE MECHANISM-C PROBE
  (PERF-2 first exit; measurement instrument, NOT registered in the
  lakefile — run via scripts/lean_probe.sh, results logged at the
  container .v3a-logs/).

  THE PROBE QUESTION (worker brief / plan §5 PERF-2): does a
  program-INDEPENDENT construct lemma replace the per-program
  generated round facts for its construct class — can the stepper
  walk a program using ONLY construct lemmas + program syntax for
  the probed classes? Measured on the T1/P01 body segments the
  supply was generated FROM (the construct lemmas were not).

  The `_walk_` probes measure the WALK alone: the goal is closed by
  an explicit continuation hypothesis (`hclose`), so the theorems
  are measurement instruments (hypothesis-closed, vacuous as
  results — deliberately, and labeled so; no sorry, no axioms).
  `probe_t1_full_mint` is the end-to-end check: t1_body's exact
  statement and coda over the mint-first walk (the spelling-crossing
  test at seg_done).
-/

import RelSem.T1Proof
import RelSem.P01Proof
import RelSem.SegRoundTac

set_option autoImplicit false
set_option maxHeartbeats 2000000  -- the tree-standing file cap
                                  -- (P02Rounds/P02Guard/T1Rounds)
set_option trace.RelSem.segRun true
set_option profiler true

namespace RelSem.CStepProbe

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Seg RelSem.T1
open Iris Iris.BI Iris.ProgramLogic

/-- The T1 harness continuation (t1_body's, verbatim). -/
@[reducible] def t1K : Fmap thread_id (List core_step2) → KDriveExpr :=
  fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
    KExpr.seq (driver2Rest t1File.tagDefs false
        (driver2_lemFuel 999999 t1File.tagDefs) tid_steps)
      (fun _ => KExpr.seq nd_get (fun dr_st' =>
        KExpr.done (Outcome.value
          (finalize t1File.tagDefs "callND" dr_st')))))

/-- MINT-FIRST T1 body walk (construct lemmas + program syntax;
    fallback classes ride the supply). -/
theorem probe_t1_walk_mint (x : Int) (seed : Nat) [CerbStGS CerbStS]
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hclose : ∀ (Γ' : Ctx) (F : Nat),
      Ctx.interp (GF := CerbStS) Γ' ⊢
        WP (dnmsK t1File.tagDefs F fmapEmpty 0 [] t1K)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result,
              o = Outcome.value r ∧ t1Spec x r⌝ }}) :
    (Ctx.interp (GF := CerbStS)
      ⟨t1Ctl0, ⟨1, 0, 0, seed⟩, env0, mr2, al0, bs0 x⟩) ⊢
      WP (dnmsK t1File.tagDefs 1000000 fmapEmpty 0 [] t1K)
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ t1Spec x r⌝ }} := by
  seg_run_c
  exact hclose _ _

/-- SUPPLY-MODE baseline at the identical goal. -/
theorem probe_t1_walk_supply (x : Int) (seed : Nat) [CerbStGS CerbStS]
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hclose : ∀ (Γ' : Ctx) (F : Nat),
      Ctx.interp (GF := CerbStS) Γ' ⊢
        WP (dnmsK t1File.tagDefs F fmapEmpty 0 [] t1K)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result,
              o = Outcome.value r ∧ t1Spec x r⌝ }}) :
    (Ctx.interp (GF := CerbStS)
      ⟨t1Ctl0, ⟨1, 0, 0, seed⟩, env0, mr2, al0, bs0 x⟩) ⊢
      WP (dnmsK t1File.tagDefs 1000000 fmapEmpty 0 [] t1K)
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ t1Spec x r⌝ }} := by
  seg_run
  exact hclose _ _

/-- END-TO-END: t1_body's exact statement and coda over the
    mint-first walk (the spelling-crossing test at seg_done: the
    walk's terminal context is mint-spelled; the coda supplies the
    per-fixture families). -/
theorem probe_t1_full_mint (x : Int) (seed : Nat) [CerbStGS CerbStS]
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647) :
    (Ctx.interp (GF := CerbStS)
      ⟨t1Ctl0, ⟨1, 0, 0, seed⟩, env0, mr2, al0, bs0 x⟩) ⊢
      WP (dnmsK t1File.tagDefs 1000000 fmapEmpty 0 []
        (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
          KExpr.seq (driver2Rest t1File.tagDefs false
              (driver2_lemFuel 999999 t1File.tagDefs) tid_steps)
            (fun _ => KExpr.seq nd_get (fun dr_st' =>
              KExpr.done (Outcome.value
                (finalize t1File.tagDefs "callND" dr_st')))))))
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ t1Spec x r⌝ }} := by
  seg_run_c
  exact seg_done (f' := 999999) (f := 999990)
    (famI := t1fam (arena8 x) [meLoad x] 7)
    (famO := t1fam (mk_value_e (loadedV x)) [meLoad x] 7)
    (cO := t1CtlAt (mk_value_e (loadedV x)) [meLoad x] 7)
    (rv := loadedV x)
    (hinv := fun σ h _ => t1_inv h) (hinvO := fun σ h => t1_inv h)
    (hctlI := fun p => rfl)
    (happ := fun p _ => t1r8 x p)
    (hIn := t1Shape (arena8 x) [meLoad x] 7)
    (hexit := fun p => rfl) (hctlO := fun p => rfl)
    (hthO := fun p => rfl) (hF := rfl)
    (hpost := by exact fun p => ⟨_, rfl, rfl⟩)

end RelSem.CStepProbe

#print axioms RelSem.CStepProbe.probe_t1_full_mint
