/-
  RelSem.M1Body — V3a continuation (2026-08-29): m1 (sgn) PROVED —
  THE PERF-2 TIGHTENED EXIT (pre-registration: record
  docs/2026-08-29_v3a-loops-mechC.md §2, committed BEFORE the
  construct-set extension at f2d7d42b1).

  THE PROOF SHAPE (professor reading): the callND caller protocol
  (M1Proof's m1_wp — argument injection owns x's bytes), then THE
  BODY: the construct-package walk to the first branch (10 rounds,
  ALL MINTED — zero generated facts), `by_cases hlt : x < 0`; the
  then-arm walks to its terminal (18 rounds, the G1T anchor the only
  registered fact); the else-arm to the second branch (22 rounds,
  G1F), `by_cases hgt : 0 < x`, the two remaining arms to their
  terminals (16/17 rounds, G2T/G2F). Three `seg_done` codas read out
  sgn(x) = −1 / 1 / 0. REGISTERED FACTS CONSUMED: exactly the FIVE
  anchors (4 branch-side guards + 1 value-quantified terminal offer)
  — within the pre-registered ≤ 6 bound (k = 2); every other round
  is an instance of the once-proved construct characterizations.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.M1Guard
import RelSem.SegmentFaces

set_option autoImplicit false
set_option maxHeartbeats 2000000

namespace RelSem.M1

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Kit RelSem.Corpus
  RelSem.Slate RelSem.Seg
open RelSem.T1 (T1P RExpr aU intCty xAddr errAddr xPtr errPtr xPtrV
  loadedV xBytes zeroBytes allocX allocXS allocErrS mr0 mr1 mr2
  meLoad intRange al0 bs0)
open Iris Iris.BI Iris.ProgramLogic

/-! ## The terminal offer (the 5th anchor: cut-point reason =
    TERMINAL, value/trace/counter quantified) -/

/-- The terminal arena (the save continuation's evaluated body). -/
def m1termAr (k : Int) : RExpr :=
  Expr aU (Epure (Pexpr [] () (PEval (loadedV k))))

/-- FamShape at any m1 walk-family instance (all rfl). -/
def m1gShape (a : RExpr) (tr : List trace_event) (n : Nat) :
    Seg.FamShape (m1gfam a tr n) :=
  ⟨fun _ => rfl, fun _ => rfl, fun _ => rfl, fun _ => rfl⟩

/-- The value state offers exactly the done step at `k` (quantified
    over the value, the trace, and the counter — one fact for all
    three arms). -/
theorem m1term (k : Int) (tr : List trace_event) (n : Nat) (p : Pack) :
    app (dnmsRoundM m1File.tagDefs 0) (m1gfam (m1termAr k) tr n p)
      = (NDactive (Sum.inr [Step_done2 (loadedV k)]),
         m1gfam (m1termAr k) tr n p) := by
  refine (dnmsRoundM_inr rfl).trans ?_
  rfl

/-! ## THE BODY (the branch tree; the walks are engine room) -/

open RelSem.Seg in
theorem m1_body (x : Int) (seed : Nat) [CerbStGS CerbStS]
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647) :
    (Ctx.interp (GF := CerbStS)
      ⟨m1Ctl0, ⟨1, 0, 0, seed⟩, [(m1xSym, xPtrV)], mr2, al0,
        bs0 x⟩) ⊢
      WP (dnmsK m1File.tagDefs 1000000 fmapEmpty 0 []
        (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
          KExpr.seq (driver2Rest m1File.tagDefs false
              (driver2_lemFuel 999999 m1File.tagDefs) tid_steps)
            (fun _ => KExpr.seq nd_get (fun dr_st' =>
              KExpr.done (Outcome.value
                (finalize m1File.tagDefs "callND" dr_st')))))))
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ sgnSpec x r⌝ }} := by
  seg_run_c
  by_cases hlt : x < 0
  · -- x < 0: sgn x = −1
    seg_run_c
    exact seg_done (f' := 999999) (f := 999970)
      (famI := m1gfam (m1termAr (-1)) [meLoad x] 27)
      (famO := m1gfam (mk_value_e (loadedV (-1))) [meLoad x] 27)
      (cO := m1CtlAt (mk_value_e (loadedV (-1))) [meLoad x] 27)
      (rv := loadedV (-1))
      (hinv := fun σ h _ => m1g_inv h) (hinvO := fun σ h => m1g_inv h)
      (hctlI := fun p => rfl)
      (happ := fun p _ => m1term (-1) [meLoad x] 27 p)
      (hIn := m1gShape (m1termAr (-1)) [meLoad x] 27)
      (hexit := fun p => rfl) (hctlO := fun p => rfl)
      (hthO := fun p => rfl) (hF := rfl)
      (hpost := by
        exact fun p => ⟨_, rfl, by
          show _ = intValue (if x < 0 then -1 else if 0 < x then 1
            else 0)
          rw [if_pos hlt]; rfl⟩)
  · -- x ≥ 0: fall through to the second branch
    seg_run_c
    by_cases hgt : 0 < x
    · -- 0 < x: sgn x = 1
      seg_run_c
      exact seg_done (f' := 999999) (f := 999950)
        (famI := m1gfam (m1termAr 1) [meLoad x, meLoad x] 46)
        (famO := m1gfam (mk_value_e (loadedV 1)) [meLoad x, meLoad x]
          46)
        (cO := m1CtlAt (mk_value_e (loadedV 1)) [meLoad x, meLoad x]
          46)
        (rv := loadedV 1)
        (hinv := fun σ h _ => m1g_inv h)
        (hinvO := fun σ h => m1g_inv h)
        (hctlI := fun p => rfl)
        (happ := fun p _ => m1term 1 [meLoad x, meLoad x] 46 p)
        (hIn := m1gShape (m1termAr 1) [meLoad x, meLoad x] 46)
        (hexit := fun p => rfl) (hctlO := fun p => rfl)
        (hthO := fun p => rfl) (hF := rfl)
        (hpost := by
          exact fun p => ⟨_, rfl, by
            show _ = intValue (if x < 0 then -1 else if 0 < x then 1
              else 0)
            rw [if_neg hlt, if_pos hgt]; rfl⟩)
    · -- x = 0: sgn x = 0
      seg_run_c
      exact seg_done (f' := 999999) (f := 999949)
        (famI := m1gfam (m1termAr 0) [meLoad x, meLoad x] 47)
        (famO := m1gfam (mk_value_e (loadedV 0)) [meLoad x, meLoad x]
          47)
        (cO := m1CtlAt (mk_value_e (loadedV 0)) [meLoad x, meLoad x]
          47)
        (rv := loadedV 0)
        (hinv := fun σ h _ => m1g_inv h)
        (hinvO := fun σ h => m1g_inv h)
        (hctlI := fun p => rfl)
        (happ := fun p _ => m1term 0 [meLoad x, meLoad x] 47 p)
        (hIn := m1gShape (m1termAr 0) [meLoad x, meLoad x] 47)
        (hexit := fun p => rfl) (hctlO := fun p => rfl)
        (hthO := fun p => rfl) (hF := rfl)
        (hpost := by
          exact fun p => ⟨_, rfl, by
            show _ = intValue (if x < 0 then -1 else if 0 < x then 1
              else 0)
            rw [if_neg hlt, if_neg hgt]; rfl⟩)

/-! ## THE M1 THEOREM (the PERF-2 exit at the frozen statement) -/

/-- m1's spec as an `FnSpec`. -/
abbrev m1FnSpec : Seg.FnSpec Int :=
  { fname := "sgn",
    args := fun x => [intValue x],
    pre := fun x => T1.intRange x,
    post := fun x r => sgnSpec x r }

/-- **m1 (sgn) PROVED** — the registered statement, bridged by
    `verify_fn`, the caller protocol by `m1_wp`, the body by the
    construct-package walk (`m1_body`). -/
theorem m1_proved : M1Statement := by
  verify_fn m1FnSpec
  exact m1_wp a ha.1 ha.2 seed
    (hbody := fun [CerbStGS CerbStS] => m1_body a seed ha.1 ha.2)

end RelSem.M1
