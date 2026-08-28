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

set_option autoImplicit false
set_option maxHeartbeats 2000000  -- the tree-standing file cap
                                  -- (P02Rounds/P02Guard/T1Rounds)
set_option trace.RelSem.segRun true
set_option profiler true
-- (split per program at V3a: seven giant walk proofs in one file
-- exceeded the 48G cap cumulatively; the probes are per-file now)

namespace RelSem.CStepProbe

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Seg RelSem.T1
open Iris Iris.BI Iris.ProgramLogic

/-- P01 END-TO-END over the mint-first walk: the branch program —
    shared prefix, `by_cases` at the symbolic compare, both arms to
    their terminals (p01_body's exact statement and codas). -/
theorem probe_p01_full_mint (x : Int) (seed : Nat) [CerbStGS CerbStS]
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647) :
    (Ctx.interp (GF := CerbStS)
      ⟨RelSem.P01.p01Ctl0, ⟨1, 0, 0, seed⟩, env0, mr2, al0, bs0 x⟩) ⊢
      WP (dnmsK RelSem.Corpus.p01File.tagDefs 1000000 fmapEmpty 0 []
        (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
          KExpr.seq (driver2Rest RelSem.Corpus.p01File.tagDefs false
              (driver2_lemFuel 999999 RelSem.Corpus.p01File.tagDefs)
              tid_steps)
            (fun _ => KExpr.seq nd_get (fun dr_st' =>
              KExpr.done (Outcome.value
                (finalize RelSem.Corpus.p01File.tagDefs "callND"
                  dr_st')))))))
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ RelSem.Corpus.p01Spec x r⌝ }} := by
  seg_run_c
  by_cases hlt : x < 0
  · seg_run_c
    exact seg_done (f' := 999999) (f := 999972)
      (famI := RelSem.P01.p01fam RelSem.P01.p01arT26 [meLoad x] 25)
      (famO := RelSem.P01.p01fam (mk_value_e (loadedV 0)) [meLoad x] 25)
      (cO := RelSem.P01.p01CtlAt (mk_value_e (loadedV 0)) [meLoad x] 25)
      (rv := loadedV 0)
      (hinv := fun σ h _ => RelSem.P01.p01_inv h)
      (hinvO := fun σ h => RelSem.P01.p01_inv h)
      (hctlI := fun p => rfl)
      (happ := fun p _ => RelSem.P01.p01r26T x p)
      (hIn := RelSem.P01.p01Shape RelSem.P01.p01arT26 [meLoad x] 25)
      (hexit := fun p => rfl) (hctlO := fun p => rfl)
      (hthO := fun p => rfl) (hF := rfl)
      (hpost := by
        exact fun p => ⟨_, rfl, by
          show _ = RelSem.Cerb.intValue (max x 0)
          rw [show max x 0 = 0 from by omega]; rfl⟩)
  · seg_run_c
    exact seg_done (f' := 999999) (f := 999968)
      (famI := RelSem.P01.p01fam (RelSem.P01.p01arF30 x)
        [meLoad x, meLoad x] 28)
      (famO := RelSem.P01.p01fam (mk_value_e (loadedV x))
        [meLoad x, meLoad x] 28)
      (cO := RelSem.P01.p01CtlAt (mk_value_e (loadedV x))
        [meLoad x, meLoad x] 28)
      (rv := loadedV x)
      (hinv := fun σ h _ => RelSem.P01.p01_inv h)
      (hinvO := fun σ h => RelSem.P01.p01_inv h)
      (hctlI := fun p => rfl)
      (happ := fun p _ => RelSem.P01.p01r30F x p)
      (hIn := RelSem.P01.p01Shape (RelSem.P01.p01arF30 x)
        [meLoad x, meLoad x] 28)
      (hexit := fun p => rfl) (hctlO := fun p => rfl)
      (hthO := fun p => rfl) (hF := rfl)
      (hpost := by
        exact fun p => ⟨_, rfl, by
          show _ = RelSem.Cerb.intValue (max x 0)
          rw [show max x 0 = x from by omega]; rfl⟩)


end RelSem.CStepProbe

#print axioms RelSem.CStepProbe.probe_p01_full_mint
