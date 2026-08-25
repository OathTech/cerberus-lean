/-
  RelSem.Threaded — arc-16 S4 (2026-08-24): THE THREADED EFFECT STATE,
  shared layer (charter S4 + the [USER] amendment: the effect-state
  elimination folds into the acceptance test; recipe = the parked
  spike branch effect-spike @ 7f4100a5c, statement shapes reused,
  proofs re-derived through the S1–S3 machinery).

  The fresh-symbol supply seed the boundary axiom `runEffectful` hides
  is modeled INSIDE the machine state: `initial_core_run_state_threaded`
  mirrors the generated initial state with the seed as an EXPLICIT
  parameter (the statement-layer analogue of the f.tagDefs pattern —
  the [USER 2026-08-24] temporal-boundary mover, statement side). The
  threaded harness statement faces (`CallHarnessAdequateThr`,
  `CallHarnessUBFreeThr`) are the committed `CallHarnessAdequate`/
  `CallHarnessUBFree` forms (relsemcore RelSem/Call.lean:322/369)
  word for word, with the ambient initial state replaced by the
  threaded one — ∀-seed statements over them are STRONGER than the
  ambient originals (which are seed-instantiated images, bridge
  lemmas at the bottom). Adequacy bridges (cones EXACTLY the
  classical trio — no `runEffectful`): the heap-route ones (the C2
  one-route migration's) live in RelSem/CerbHeapWalk.lean; the
  transitional OwnP ones in RelSem/PerStepOwnP.lean (C5-bound).

  Statement-TCB: the faces are fuel-opsem-only (production runner +
  threaded initial state; no Iris, no relational layer); Iris appears
  only in discharged hypotheses. The ambient-bridge lemmas at the
  bottom DELIBERATELY carry `runEffectful` (they mention the ambient
  state) — labeled, pinned separately in RelSem/Audit.lean.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.PerStepCall

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI

/-! ## The threaded effect state -/

/-- The initial core-run state with the fresh-symbol supply seed as an
    EXPLICIT parameter. Mirrors generated/Core_run_aux.lean:395
    (`initial_core_run_state`) field-for-field; the single change is
    `sym_supply := seed` in place of the ambient draw
    `runEffectful (fun () => CerberusFresh.freshIntIO ())`. -/
def initial_core_run_state_threaded (seed : Nat)
    (xs : Fmap sym (labeled_continuations core_run_annotation)) :
    core_run_state :=
  { tid_supply := 0, aid_supply := 0, excluded_supply := 0,
    sym_supply := seed, labeled := xs }

/-- The initial driver state over the threaded core-run state. Mirrors
    generated/Driver.lean (`initial_driver_state`) field-for-field;
    the single change is the threaded initial core-run state. -/
def initial_driver_state_threaded (seed : Nat)
    (file1 : file core_run_annotation) (fs_state2 : CerbFS.FsState) :
    driver_state :=
  { core_file := file1,
    core_extern := create_extern_symmap file1,
    core_state0 := initial_core_state,
    core_run_state0 := initial_core_run_state_threaded seed
      (collect_labeled_continuations_NEW file1),
    layout_state := CerbMem.initialMemState,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := fs_state2,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

/-! ## The threaded harness statement faces (fuel opsem only) -/

/-- `CallHarnessAdequate` at the threaded initial state: every outcome
    the production runner enumerates for the harness call FROM THE
    SEED-PARAMETRIC INITIAL STATE is `Active` and satisfies `spec`.
    ∀-seed statements over this face are STRONGER than the ambient
    originals (bridge below). -/
def CallHarnessAdequateThr (seed : Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop) : Prop :=
  ∀ (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (callND tagDefs file1 fname args)
        (initial_driver_state_threaded seed file1 fs) →
    ∃ r : driver_result, out = Active r ∧ spec r

/-- `CallHarnessUBFree` at the threaded initial state. -/
def CallHarnessUBFreeThr (seed : Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState) : Prop :=
  ∀ (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (callND tagDefs file1 fname args)
        (initial_driver_state_threaded seed file1 fs) →
    ∀ (stk : driver_state) (loc : CerbLocation.Loc)
      (ubs : List undefined_behaviour),
      out ≠ Killed stk (Undef0 loc ubs)

/-! ## Statement-facing plumbing (pure). Arc-18 C2: the OwnP adequacy
    bridges (`kCallHarnessAdequateThr_of_wp`/
    `kCallHarnessUBFreeThr_of_wp`) MOVED name-stably to
    RelSem/PerStepOwnP.lean with the rest of the OwnP surface; the
    heap-route bridges (the migration's replacements) live in
    RelSem/CerbHeapWalk.lean. This module keeps only the faces and
    the pure plumbing — it binds no interpretation. -/

/-- The value-shaped threaded headline implies the threaded UB-freedom
    headline. Pure statement-layer plumbing, no Iris. -/
theorem callHarnessUBFreeThr_of_adequateThr {seed : Nat}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {spec : driver_result → Prop}
    (h : CallHarnessAdequateThr seed tagDefs file1 fname args fs spec) :
    CallHarnessUBFreeThr seed tagDefs file1 fname args fs := by
  intro out tr st' hmem stk loc ubs hout
  obtain ⟨r, hr, -⟩ := h out tr st' hmem
  rw [hout] at hr
  cases hr

/-! ## The ambient bridge (DELIBERATELY impure: these mention the
    ambient state, so they — and only they, in this file — wear the
    boundary axiom `runEffectful`; pinned LABELED in Audit.lean).
    They document that the ambient statements are seed-instantiated
    images of the threaded family: nothing is lost. -/

/-- `initial_core_run_state` IS the threaded form at the ambient seed
    draw — definitionally. -/
theorem initial_core_run_state_eq_threaded_ambient
    (xs : Fmap sym (labeled_continuations core_run_annotation)) :
    initial_core_run_state xs
      = initial_core_run_state_threaded
          (runEffectful (fun () => CerberusFresh.freshIntIO ())) xs := rfl

/-- `initial_driver_state` IS the threaded form at the ambient seed
    draw — definitionally. -/
theorem initial_driver_state_eq_threaded_ambient
    (file1 : file core_run_annotation) (fs : CerbFS.FsState) :
    initial_driver_state file1 fs
      = initial_driver_state_threaded
          (runEffectful (fun () => CerberusFresh.freshIntIO ()))
          file1 fs := rfl

/-- The ∀-seed threaded headline face yields the ambient one at the
    ambient draw (the "nothing is lost" direction, generic). -/
theorem callHarnessAdequate_of_thr
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {spec : driver_result → Prop}
    (h : ∀ seed : Nat,
      CallHarnessAdequateThr seed tagDefs file1 fname args fs spec) :
    CallHarnessAdequate tagDefs file1 fname args fs spec := by
  intro out tr st' hmem
  rw [initial_driver_state_eq_threaded_ambient] at hmem
  exact h _ out tr st' hmem

end Cerb
end RelSem
