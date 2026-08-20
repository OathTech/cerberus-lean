/-
  RelSem.IrisState — arc-7 S4 (2026-08-20): STATE INTERPRETATION.

  THE SC INSTANTIATION OF THE PARAMETERIZED SLOT (concurrency
  forward-design constraint 2, spike doc): `stateInterp σ _ _ _ :=
  ghost_var γstate (½) σ` — a full-`driver_state` ghost cell, half
  owned by the interpretation, half (`stateIs σ`) by the proof.

  DECISION [AGENT:S4] (rationale + probe in
  docs/2026-08-20_arc7-s4-iris-coupling.md §3): NOT gen_heap over the
  bytemap denotation, NOT a custom RA. On the slate corpus every run is
  ONE driver-node step (S3 trace evidence), so (a) the single lifting
  step's postcondition must be derived from `stateInterp σ₁` alone, and
  the app equation is a function of the FULL driver_state (core_file,
  thread arena/env, allocation counters, fs) — byte points-to
  under-determines it; (b) no intermediate configurations exist for
  points-to to frame across. gen_heap-over-heapOf (whose entry points
  are catalogued in the S4 record §0.1) is the designated instantiation
  for the Q4 granularity refinement; swapping it in replaces THIS
  file's interpretation without touching the Language instance
  (RelSem/IrisLang.lean) or any adequacy statement
  (behavior-quantified through ExecModel). T3/T4 points-to facts are
  DERIVED MemState-level predicates (`PointsToByte` + the layout
  oracles) consumed inside app-equation lemmas — deliberately not Iris
  resources this arc (S4 record §0.3 rows R6/R7).

  Packaging mirrors HeapLang (Iris/HeapLang/PrimitiveLaws.lean:28-127):
  `CerbGpreS` (functor inclusion), `CerbGS` (allocated ghost name),
  `CerbS` (a closed BundledGFunctors witness with a `CerbGpreS`
  instance, so downstream theorems can be discharged at a concrete GF).

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.ProgramLogic.WeakestPre
import Iris.Instances.Lib.GhostVar
import RelSem.IrisLang

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic

/-- Functor-inclusion prerequisite: invariants/credits (`InvGpreS`) +
    the driver-state ghost variable. -/
class CerbGpreS (GF : BundledGFunctors) extends InvGpreS GF where
  [state_pre : GhostVarG GF driver_state]

attribute [reducible, instance] CerbGpreS.state_pre

/-- The allocated form: invariant machinery live + the NAME of the
    driver-state ghost cell. THE StateInterp slot instantiation hangs
    off this class; a future model swap replaces this class's
    interpretation, nothing else. -/
class CerbGS (hlc : outParam HasLC) (GF : BundledGFunctors) where
  -- not an instance on purpose to avoid diamonds with IrisGS_gen
  -- (HeapLangGS precedent)
  [invGS : InvGS_gen hlc GF]
  [stateVar : GhostVarG GF driver_state]
  γstate : GName

attribute [reducible, instance] CerbGS.stateVar

variable {hlc : HasLC} {GF : BundledGFunctors}

/-- The proof-side half of the state cell: "the driver state is now
    `σ`". The WP rules (RelSem/IrisRules.lean) consume and return this
    assertion. -/
def stateIs [η : CerbGS hlc GF] (σ : driver_state) : IProp GF :=
  ghost_var η.γstate (.own (1 : Qp).half) σ

/-- The interpretation-side half: the SC instantiation of the slot. -/
instance instStateInterpDrive [η : CerbGS hlc GF] :
    StateInterp driver_state Empty GF where
  stateInterp σ _ _ _ := ghost_var η.γstate (.own (1 : Qp).half) σ

/-- The `IrisGS_gen` instance over the coupled language: no extra
    laters per step, trivial fork postcondition (no forks exist —
    RelSem/IrisLang.lean), monotone state interpretation (trivially:
    the interpretation ignores the step count). -/
instance instIrisGSDrive [η : CerbGS hlc GF] :
    IrisGS_gen hlc DriveExpr GF where
  invGS := CerbGS.invGS
  numLatersPerStep _ := 0
  forkPost _ := iprop(True)
  stateInterp_mono σ ns obs nt := by
    letI := @CerbGS.invGS hlc GF _
    iintro $

/-- The state interpretation, unfolded (the shape the rules and the
    adequacy initialization rewrite through). -/
theorem stateInterp_eq [η : CerbGS hlc GF] (σ : driver_state) (ns : Nat)
    (κs : List Empty) (nt : Nat) :
    (stateInterp σ ns κs nt : IProp GF) ⊣⊢ stateIs σ := .rfl

/-- Agreement: the proof-side half pins the interpretation's state. -/
theorem stateIs_agree [η : CerbGS hlc GF] (σ σ' : driver_state) :
    ⊢ (stateIs (hlc := hlc) (GF := GF) σ) -∗ stateIs σ' -∗ ⌜σ = σ'⌝ :=
  ghost_var_agree _ _ _ _ _

/-- Update: both halves move together. -/
theorem stateIs_update [η : CerbGS hlc GF] (σ'' σ σ' : driver_state) :
    ⊢ (stateIs (hlc := hlc) (GF := GF) σ) -∗ stateIs σ' ==∗
      stateIs σ'' ∗ stateIs σ'' :=
  ghost_var_update_halves _ _ _ _

/-! ## A closed functor bundle carrying `CerbGpreS` (the HeapLangS
    pattern): indices 0-3 are the invariant/credit machinery, index 4
    the driver-state ghost variable. Downstream theorems needing a
    concrete `GF` (the T1 discharge) instantiate at `CerbS`. -/

def CerbS : BundledGFunctors
  | 0 => ⟨InvMapF, by infer_instance⟩
  | 1 => ⟨constOF CoPsetDisjL, by infer_instance⟩
  | 2 => ⟨constOF (DisjointLeibnizSet PosSet), by infer_instance⟩
  | 3 => ⟨Auth.AuthURF (constOF Credit), by infer_instance⟩
  | 4 => ⟨GhostVarF driver_state, by infer_instance⟩
  | _ => ⟨constOF Unit, by infer_instance⟩

instance instCerbGpreS_CerbS : CerbGpreS CerbS where
  toWsatGpreS := by
    constructor
    · exists 0
    · exists 1
    · exists 2
  toLcGpreS := by
    constructor
    · exists 3
  state_pre := @GhostVarG.mk _ _ ⟨4, rfl⟩

end Cerb
end RelSem
