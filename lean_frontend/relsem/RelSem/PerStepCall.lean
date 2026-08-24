/-
  RelSem.PerStepCall — arc-16 S1 (2026-08-24): THE REIFIED HARNESS +
  the statement-facing adequacy through the per-step instance.

  `callK` re-expresses the symbolic-argument harness `callND`
  (RelSem/Call.lean:220) as a per-step expression: the SAME generated
  stage computations, with the bind joints reified so each stage is a
  language step. `callND` itself is UNTOUCHED (the statement layer is
  frozen this slice); the anchor theorem `callK_denote` pins the
  re-expression to the production harness — any future edit to
  Call.lean's spine breaks it build-fatally (the drift gate for this
  mirror, per the mirror-OCaml doctrine's cite-and-anchor discipline;
  the transcription cites Call.lean line-by-line below).

  Granularity delivered in S1 (record §2.6/§5): per-stage steps for
  the harness (globals / name resolution / argument injection — the
  allocator ND surface — / errno / thread setup / finalize), the
  `driver2` loop segment as ONE atom. Peeling the two loop recursions
  is the record §5 design (the canonical big-step↔small-step
  simulation); S3 attaches there.

  Statement-TCB: the CONCLUSIONS below are the EXISTING
  `CallHarnessAdequate`/`CallHarnessUBFree` forms (fuel opsem only,
  byte-identical defs from RelSem/Call.lean); Iris appears only in
  discharged hypotheses.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.Call
import RelSem.PerStepIris

set_option autoImplicit false

open Lem_Basic_classes (ordCompare)

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI

/-! ## The reified harness -/

/-- `callFinish`'s stage spine as a per-step expression (transcribed
    from RelSem/Call.lean:171-212; the anchor below is the drift
    gate). Atoms: `get_thread_states`, the errno allocate+store through
    the memory lens, `driver_update_thread_state`, the `driver2` loop
    (ONE atom this slice), the final `nd_get`; the `finalize` readout
    is pure and lands in the terminal value. -/
@[reducible] def callFinishK (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid0 : Nat) (fsym : sym)
    (expr1 : generic_expr core_run_annotation Unit sym)
    (bound : List (sym × value)) : KDriveExpr :=
  .seq get_thread_states
    (fun (ths : List (Nat × (Option thread_id × thread_state))) =>
    match ths with
    | [(_, (_, th_st))] =>
        let env' : List (Fmap sym value) :=
          match th_st.env with
          | [] => [Lem_Map.fromList bound]
          | xs :: xs' =>
            (List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
              fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2)
                pv.1 pv.2 m) xs bound) :: xs'
        .seq
          (liftMem (nd_bind
            (CerbMem.allocateObject tid0 (PrefOther "errno")
              (CerbMem.alignofIval signed_int) signed_int none none)
            (fun (ptr_val : CerbMem.PointerValue) =>
              let zero := CerbMem.integerValueMval (Signed Int_)
                (CerbMem.integerIval (0 : Int))
              nd_bind
                (CerbMem.storeM (CerbLocation.other "errno init")
                  signed_int false ptr_val zero)
                (fun (_ : CerbMem.Footprint) => nd_return ptr_val))))
          (fun (errno_ptr_val : CerbMem.PointerValue) =>
        .seq (driver_update_thread_state tid0
          ({ arena := expr1,
             stack0 := Stack_empty,
             errno := errno_ptr_val,
             current_loc := CerbLocation.other "RelSem.callND",
             exec_loc := ELoc_normal
               [(fsym, CerbLocation.other "RelSem.callND")],
             env := env',
             current_proc_opt := some fsym } : thread_state))
          (fun (_ : Unit) =>
        .seq (driver2 tagDefs false) (fun (_ : Unit) =>
        .seq nd_get (fun (dr_st' : driver_state) =>
        .done (.value (finalize tagDefs "callND" dr_st'))))))
    | _ => .done (.killed (Other (DErr_other
        "callND: not exactly one thread after globals"))))

/-- THE REIFIED HARNESS: `callND`'s stage spine (RelSem/Call.lean:220-
    234) with the joints reified. Universally-quantified Lean values
    enter as `args`, exactly as at `callConfig`. -/
@[reducible] def callK (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) : KDriveExpr :=
  .seq (driver_globals tagDefs false file1) (fun (tid0 : Nat) =>
  .seq nd_get (fun (post_globals_dr_st : driver_state) =>
  .seq (resolveFunSym post_globals_dr_st.core_file fname)
    (fun (fsym : sym) =>
  .seq (lookupFunBody post_globals_dr_st.core_file fsym)
    (fun (pb : List (sym × core_base_type) ×
          generic_expr core_run_annotation Unit sym) =>
  .seq (lookupParamTys post_globals_dr_st.core_file fsym)
    (fun (ptys : List ctype) =>
  .seq (injectArgs tagDefs tid0 pb.1 ptys args)
    (fun (bound : List (sym × value)) =>
  callFinishK tagDefs tid0 fsym pb.2 bound))))))

/-! ## The anchors (soundness by construction: the reified programs
    DENOTE the production harness) -/

/-- Anchor, finish stage. -/
theorem callFinishK_denote
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid0 : Nat) (fsym : sym)
    (expr1 : generic_expr core_run_annotation Unit sym)
    (bound : List (sym × value)) :
    (callFinishK tagDefs tid0 fsym expr1 bound).denote
      = callFinish tagDefs tid0 fsym expr1 bound := by
  show nd_bind get_thread_states _ = nd_bind get_thread_states _
  refine congrArg _ (funext fun ths => ?_)
  rcases ths with _ | ⟨⟨t1, ot, th_st⟩, _ | ⟨hd, tl⟩⟩ <;> rfl

/-- THE ANCHOR: the reified harness denotes the production harness.
    Drift in Call.lean's spine breaks this `rfl`-grade proof
    build-fatally. -/
theorem callK_denote
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) :
    (callK tagDefs file1 fname args).denote
      = callND tagDefs file1 fname args := by
  show nd_bind (driver_globals tagDefs false file1) _
    = nd_bind (driver_globals tagDefs false file1) _
  refine congrArg _ (funext fun tid0 => ?_)
  show nd_bind nd_get _ = nd_bind nd_get _
  refine congrArg _ (funext fun post_st => ?_)
  show nd_bind _ _ = nd_bind _ _
  refine congrArg _ (funext fun fsym => ?_)
  show nd_bind _ _ = nd_bind _ _
  refine congrArg _ (funext fun pb => ?_)
  show nd_bind _ _ = nd_bind _ _
  refine congrArg _ (funext fun ptys => ?_)
  show nd_bind _ _ = nd_bind _ _
  refine congrArg _ (funext fun bound => ?_)
  exact callFinishK_denote tagDefs tid0 fsym pb.2 bound

/-! ## Statement-facing adequacy through the per-step instance
    (CONCLUSIONS byte-identical to the existing statement forms) -/

/-- WP over the per-step instance at the reified harness ⇒ the
    CerbND-shaped HEADLINE (`CallHarnessAdequate`, unchanged): every
    outcome the production runner enumerates for the harness call is
    `Active` and satisfies `spec`. -/
theorem kCallHarnessAdequate_of_wp {GF : BundledGFunctors} [CerbGpreS GF]
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (GF := GF) (initial_driver_state file1 fs)) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessAdequate tagDefs file1 fname args fs spec := by
  intro out tr st' hmem
  rw [← callK_denote] at hmem
  have hφ := kAdequate_of_wp (GF := GF) (callK tagDefs file1 fname args)
    (initial_driver_state file1 fs)
    (fun o => ∃ r : driver_result, o = Outcome.value r ∧ spec r)
    Hwp out tr st' hmem
  obtain ⟨r, hr, hs⟩ := hφ
  exact ⟨r, ofStatus_value_inv hr, hs⟩

/-- The value-shaped headline implies the UB-freedom headline
    (`CallHarnessUBFree`, unchanged): an outcome that is `Active` is
    no `Undef0` kill. Pure statement-layer plumbing, no Iris. -/
theorem callHarnessUBFree_of_callHarnessAdequate
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {spec : driver_result → Prop}
    (h : CallHarnessAdequate tagDefs file1 fname args fs spec) :
    CallHarnessUBFree tagDefs file1 fname args fs := by
  intro out tr st' hmem stk loc ubs hout
  obtain ⟨r, hr, -⟩ := h out tr st' hmem
  rw [hout] at hr
  cases hr

/-- WP over the per-step instance ⇒ the UB-freedom HEADLINE. -/
theorem kCallHarnessUBFree_of_wp {GF : BundledGFunctors} [CerbGpreS GF]
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (GF := GF) (initial_driver_state file1 fs)) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessUBFree tagDefs file1 fname args fs :=
  callHarnessUBFree_of_callHarnessAdequate
    (kCallHarnessAdequate_of_wp tagDefs file1 fname args fs spec Hwp)

end Cerb
end RelSem
