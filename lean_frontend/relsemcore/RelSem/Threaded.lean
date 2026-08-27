/-
  RelSem.Threaded — THE THREADED EFFECT STATE + the threaded statement
  faces, SEMANTICS-SIDE HOME (arc-18 C4, register row R6 of
  docs/2026-08-25_reasoning-layer-contracts.md §6).

  PROVENANCE: born arc-16 S4 (2026-08-24) in the PROOF package
  (relsem/RelSem/Threaded.lean); MOVED here — the exec-facing
  RelSemCore lib of the root semantics package — at arc-18 C4
  (2026-08-26). A MOVE, not a mirror (the mirror doctrine forbids a
  duplicated initial-state def): this file is the ONE definition site;
  the proof package and the spec-lab statement surface both import it.
  The homing is what lets speclab statements quote the threaded
  initial state without crossing the one-way semantics→verification
  seam (the arc-17 S2b §6 package-seam prerequisite, closed here).

  The fresh-symbol supply seed the boundary axiom `runEffectful` hides
  is modeled INSIDE the machine state: `initial_core_run_state_threaded`
  mirrors the generated initial state with the seed as an EXPLICIT
  parameter (the statement-layer analogue of the f.tagDefs pattern —
  the [USER 2026-08-24] temporal-boundary mover, statement side). The
  threaded harness statement faces are the target vocabulary of the
  arc-18 contracts doc §5:

  * `CallHarnessAdequateThr`/`CallHarnessUBFreeThr` — the labeled
    function-call slate idiom: the committed `CallHarnessAdequate`/
    `CallHarnessUBFree` forms (RelSem/Call.lean:322/369) word for
    word, with the ambient initial state replaced by the threaded one.
  * `HarnessRunsToThr` — THE WHOLE-PROGRAM PRIMARY FACE (the harness
    doctrine's native form): the spec lab's `HarnessRunsTo` shape
    (born speclab SpecLab/DivModFiles.lean, arc-15 S1) at the
    threaded initial state, homed semantics-side with `specifiedInt`.

  ∀-seed statements over these faces are STRONGER than the ambient
  originals (which are seed-instantiated images — bridge lemmas at the
  bottom). SEED-QUANTIFICATION HONESTY (arc-18 C4 [AGENT], from the
  arc-16 S4 finding): unrestricted ∀-seed claims fail for some
  program shapes (the T4 diagnosis: hash collision kernel-witnessed,
  the falseness reading additionally resting on the capture argument
  — docs/2026-08-24_arc16-s4-acceptance.md), so these faces take the
  seed as a PARAMETER and quantify nothing; each client decides its
  quantification (∀-seed where proved, e.g. T1–T3/T6; guarded where
  apartness is needed, e.g. T4; seed-parametric where unproved, e.g.
  the spec-lab statement families).

  Adequacy bridges (cones EXACTLY the classical trio — no
  `runEffectful`): the heap-route ones (the C2 one-route migration's)
  live in relsem RelSem/CerbHeapWalk.lean; the transitional OwnP ones
  in relsem RelSem/PerStepOwnP.lean (C5-bound).

  Statement-TCB: the faces are fuel-opsem-only (production runner +
  threaded initial state; no Iris, no relational layer). The
  ambient-bridge lemmas at the bottom DELIBERATELY carry
  `runEffectful` (they mention the ambient state) — labeled, pinned
  separately in relsem RelSem/Audit.lean (the no-cone gate's carrier
  registrations).

  House rules: no sorry, no axioms. Under the in-build audit (via the
  proof package's import).
-/

import RelSem.Call

set_option autoImplicit false

namespace RelSem
namespace Cerb

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

/-! ## The whole-program face (the spec-lab shape, homed at C4) -/

/-- A `Specified` integer driver value (the harness verdict spelling —
    generated vocabulary only). MOVED from speclab
    SpecLab/DivModFiles.lean at arc-18 C4 (one definition, one home;
    `SpecLab.DivMod.specifiedInt` is an abbrev to this). -/
def specifiedInt (n : Int) : value :=
  Vloaded (LVspecified (OVinteger (CerbMem.integerIval n)))

/-- THE WHOLE-PROGRAM PRIMARY FACE: every outcome the production
    runner enumerates for the driver run of `f` (the Main.lean entry:
    `drive` with the default `["cmdname"]` args on the default
    filesystem) FROM THE SEED-PARAMETRIC INITIAL STATE is `Active`
    with the given `Specified` verdict.
    DELIBERATE DIVERGENCE from Main.lean (arc-15 audit-1 MINOR-1,
    carried from the speclab original): Main.lean:866 drives with the
    ambient `CerbTags.tagDefs ()` where this statement passes
    `f.tagDefs` — the self-contained form is better statement material
    (no ambient state in the Prop); behaviorally validated at every
    pinned instance by the speclab gate exes against both real
    pipelines. -/
def HarnessRunsToThr (seed : Nat) (f : file core_run_annotation)
    (verdict : Int) : Prop :=
  ∀ (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (drive f.tagDefs false f ["cmdname"])
        (initial_driver_state_threaded seed f CerbFS.fs_initial_state) →
    ∃ r : driver_result, out = Active r ∧
      r.dres_core_value = specifiedInt verdict

/-! ## Statement-facing plumbing (pure; binds no interpretation) -/

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
    boundary axiom `runEffectful`; pinned LABELED in relsem
    RelSem/Audit.lean and registered on its no-cone carrier list).
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
