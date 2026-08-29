-- V3a probe (measurement instrument; not registered): the m1 body
-- walk under mint-first — stage 3: all four anchors registered; every
-- path should reach its terminal offer.
import RelSem.M1Guard
set_option autoImplicit false
set_option maxHeartbeats 2000000
set_option trace.RelSem.segRun true
namespace RelSem.M1
open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Seg RelSem.T1 RelSem.Slate
-- spot-audit F3 (2026-08-29): m1File re-homed RelSem.Slate →
-- RelSem.Corpus (statement-side, with the corpus program terms).
open RelSem.Corpus (m1File)
open RelSem.M1
open Iris Iris.BI Iris.ProgramLogic

@[reducible] def m1K : Fmap thread_id (List core_step2) → KDriveExpr :=
  fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
    KExpr.seq (driver2Rest m1File.tagDefs false
        (driver2_lemFuel 999999 m1File.tagDefs) tid_steps)
      (fun _ => KExpr.seq nd_get (fun dr_st' =>
        KExpr.done (Outcome.value
          (finalize m1File.tagDefs "callND" dr_st')))))

theorem m1_walk_probe (x : Int) (seed : Nat) [CerbStGS CerbStS]
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hclose : ∀ (Γ' : Ctx) (F : Nat),
      Ctx.interp (GF := CerbStS) Γ' ⊢
        WP (dnmsK m1File.tagDefs F fmapEmpty 0 [] m1K)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result,
              o = Outcome.value r ∧ sgnSpec x r⌝ }}) :
    (Ctx.interp (GF := CerbStS)
      ⟨m1Ctl0, ⟨1, 0, 0, seed⟩, [(m1xSym, xPtrV)], mr2, al0,
        bs0 x⟩) ⊢
      WP (dnmsK m1File.tagDefs 1000000 fmapEmpty 0 [] m1K)
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ sgnSpec x r⌝ }} := by
  seg_run_c
  by_cases hlt : x < 0
  · seg_run_c
    exact hclose _ _
  · seg_run_c
    by_cases hgt : 0 < x
    · seg_run_c
      exact hclose _ _
    · seg_run_c
      exact hclose _ _

end RelSem.M1
