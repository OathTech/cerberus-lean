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

/-! ## CONSISTENCY — freshness as can't-happen nondeterminism
    (V0, 2026-08-27; the [USER 2026-08-24] model-level end state,
    operator-scheduled at the V0 brief's Q3 amendment: "guards die
    now").

    THE MODEL: the fresh-symbol allocator picks values
    nondeterministically; a CONSISTENCY PREDICATE discards
    inconsistent executions (assume-not-assert) — an execution is
    consistent iff its fresh draws are NON-CAPTURING: pairwise
    distinct and distinct from every symbol number already in
    existence (the program's static vocabulary, itself the image of
    the elaboration-time draws). The counter implementation is a
    REFINEMENT of this model; its metatheorem (monotone ⇒ distinct +
    below-the-vocabulary ⇒ non-capturing, `consistentRun_of_supply_le`
    below) is both the implementation's correctness and the
    anti-vacuity witness schema.

    THE STATEMENT SHAPE this replaces: the ∀-seed + `SeedApart` guard
    (T4SeedApart/T5SeedApart, arc-16 S4 → arc-18 R5 — per-program
    numeric bounds in headline hypotheses, the assessment's C-11
    wart). Statements now quantify over EXECUTIONS and condition on
    consistency of the execution's OWN draw window — the excluded set
    is exactly the capturing runs (the arc-16 S4 P3 falsifier class),
    named for what it is instead of bounded around.

    THE DRAW WINDOW: mid-run draws are state-threaded (arc-13), so a
    terminated execution's draws are exactly the half-open counter
    window from the initial seed to the final state's `sym_supply`.

    `prior` — the program's static symbol-number vocabulary — is
    PINNED FIXTURE DATA (same trust class as the emitted program
    terms themselves: extracted from the same pinned emitted sources,
    validated in-build by the PriorCensus instrument on the test
    ledger). TEMPORAL registration: the agreement "prior ⊇ the file's
    symbol numbers" is instrument-checked, not yet a kernel theorem;
    the registered mover is a total symbol-census function over the
    Core AST (V2-class, with the per-construct rules). -/

/-- The fresh draws of a terminated execution: the half-open counter
    window `[seed, final sym_supply)` (state-threaded supply; empty
    when no draw happened). -/
def freshDrawsOf (seed : Nat) (st' : driver_state) : List Nat :=
  List.range' seed (st'.core_run_state0.sym_supply - seed)

/-- CONSISTENCY (can't-happen ND, assume-not-assert): the execution's
    fresh draws are non-capturing — pairwise distinct AND distinct
    from every prior symbol number (`prior` = the program's static
    vocabulary). The first conjunct is the ND model's own freshness
    face (free for the counter refinement — `freshDrawsOf_nodup`);
    the second is what the arc-16 S4 P3 falsifier violated. -/
def ConsistentRun (prior : List Nat) (seed : Nat)
    (st' : driver_state) : Prop :=
  (freshDrawsOf seed st').Nodup ∧
  ∀ n ∈ freshDrawsOf seed st', n ∉ prior

/-- `CallHarnessAdequate` OVER CONSISTENT EXECUTIONS (the V0 house
    statement face): every consistent outcome the production runner
    enumerates — any counter seed, the execution's own draw window
    non-capturing — is `Active` and satisfies `spec`. Replaces the
    guarded ∀-seed shape (`∀ seed, SeedApart seed → …Thr seed …`);
    quantification honesty: the executions ranged over are the
    counter refinement's (one per seed), the fully ND allocator
    formulation is the chartered cmm-arc form. -/
def CallHarnessAdequateCns (prior : List Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop) : Prop :=
  ∀ (seed : Nat)
    (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (callND tagDefs file1 fname args)
        (initial_driver_state_threaded seed file1 fs) →
    ConsistentRun prior seed st' →
    ∃ r : driver_result, out = Active r ∧ spec r

/-- `CallHarnessUBFree` over consistent executions. -/
def CallHarnessUBFreeCns (prior : List Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState) : Prop :=
  ∀ (seed : Nat)
    (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (callND tagDefs file1 fname args)
        (initial_driver_state_threaded seed file1 fs) →
    ConsistentRun prior seed st' →
    ∀ (stk : driver_state) (loc : CerbLocation.Loc)
      (ubs : List undefined_behaviour),
      out ≠ Killed stk (Undef0 loc ubs)

/-- THE WHOLE-PROGRAM FACE over consistent executions (the
    `HarnessRunsToThr` shape at the consistency quantification — the
    corpus memory-input rows' face). -/
def HarnessRunsToCns (prior : List Nat)
    (f : file core_run_annotation) (verdict : Int) : Prop :=
  ∀ (seed : Nat)
    (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (drive f.tagDefs false f ["cmdname"])
        (initial_driver_state_threaded seed f CerbFS.fs_initial_state) →
    ConsistentRun prior seed st' →
    ∃ r : driver_result, out = Active r ∧
      r.dres_core_value = specifiedInt verdict

/-! ## THE ANTI-VACUITY METATHEOREM (proved once; kernel; the
    plant-test doctrine's schema for the consistency families).

    The counter refinement's correctness: its draw window is
    automatically duplicate-free (monotone ⇒ distinct), and it is
    non-capturing whenever the final supply clears the program's
    static vocabulary — which the ambient counter run does by
    construction (small counter seeds, hash-range static numbers).
    So a quantified consistency family is non-vacuous at any
    terminating counter run whose supply bound is checked — the
    per-program bound check is kernel computation at proof time;
    the schema is proved HERE, once. -/

/-- Monotone ⇒ distinct: the counter window never repeats a draw
    (the ND model's freshness face, held by the refinement). -/
theorem freshDrawsOf_nodup (seed : Nat) (st' : driver_state) :
    (freshDrawsOf seed st').Nodup :=
  List.nodup_range'

/-- THE ANTI-VACUITY METATHEOREM: a counter execution whose final
    supply stays at-or-below every prior symbol number is a
    CONSISTENT execution. (With every static number ≥ the hash floor
    and counter seeds small, this is the "counter run is consistent"
    fact, once — instantiated per program by a kernel bound check.) -/
theorem consistentRun_of_supply_le (prior : List Nat) (seed : Nat)
    (st' : driver_state)
    (h : ∀ m ∈ prior, st'.core_run_state0.sym_supply ≤ m) :
    ConsistentRun prior seed st' := by
  refine ⟨freshDrawsOf_nodup seed st', ?_⟩
  intro n hn hmem
  have hge : seed ≤ n := (List.mem_range'_1.mp hn).1
  have hlt : n < seed + (st'.core_run_state0.sym_supply - seed) :=
    (List.mem_range'_1.mp hn).2
  have hle := h n hmem
  omega

/-! ## Statement-facing plumbing (pure; binds no interpretation) -/

/-- The value-shaped consistency headline implies the consistency
    UB-freedom headline. Pure statement-layer plumbing, no Iris. -/
theorem callHarnessUBFreeCns_of_adequateCns {prior : List Nat}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {spec : driver_result → Prop}
    (h : CallHarnessAdequateCns prior tagDefs file1 fname args fs
      spec) :
    CallHarnessUBFreeCns prior tagDefs file1 fname args fs := by
  intro seed out tr st' hmem hcons stk loc ubs hout
  obtain ⟨r, hr, -⟩ := h seed out tr st' hmem hcons
  rw [hout] at hr
  cases hr

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

/-! (The three ambient-bridge carriers that lived here —
    `initial_core_run_state_eq_threaded_ambient`,
    `initial_driver_state_eq_threaded_ambient`,
    `callHarnessAdequate_of_thr` — were DELETED at the 2026-08-27
    kill-list execution with the ambient theorem family they served;
    they were the file's only `runEffectful` carriers. The threaded
    faces above are the one statement vocabulary.) -/

end Cerb
end RelSem
