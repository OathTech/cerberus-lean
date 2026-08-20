/-
  RelSem.IrisState — arc-9 S2 (2026-08-20): STATE OWNERSHIP, through
  iris-lean's OwnP library (Q1/F1: ADOPT WHOLESALE — the arc-7
  hand-rolled ghost-variable twin is RETIRED; design
  docs/2026-08-20_arc9-s1-design.md §1.1, probe transcript in the S2
  record).

  THE SC INSTANTIATION OF THE PARAMETERIZED SLOT (concurrency
  forward-design constraint 2, spike doc) is now the LIBRARY's:
  `ownPG_irisGS` interprets the state as the ExclAuth authority over
  the full `driver_state`; the proof-side assertion is `ownP σ` (the
  fragment). Signature-by-signature disposition vs arc-7
  (survey §1.3 map):

    CerbGpreS/CerbGS        → abbrevs onto OwnPGpreS/OwnPGS (the names
                              stay so consumers don't churn; deleted at
                              S4 consolidation per the design)
    stateIs                 → abbrev onto ownP (same S4 note)
    instStateInterpDrive,
    instIrisGSDrive         → ownPG_irisGS (library)
    stateInterp_eq          → gone (the interpretation shape is the
                              library's)
    stateIs_agree           → ownP_eq (library)
    stateIs_update          → gone (the ghost update happens inside
                              ownP_lift_step; no rule hand-rolls it)

  The gen_heap-over-heapOf Q4-granularity refinement note from arc-7
  stands unchanged: swapping the interpretation replaces THIS file
  without touching the Language instance (RelSem/IrisLang.lean) or any
  adequacy statement.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.ProgramLogic.OwnP
import RelSem.IrisLang

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic

/-- Functor-inclusion prerequisite (pre-allocation form): iris-lean's
    `OwnPGpreS` at `driver_state`. The NAME is kept from arc-7 so the
    adequacy-facing signatures don't churn (S2 abbrev discipline,
    design §1.1; call sites rename at S4 consolidation). -/
abbrev CerbGpreS (GF : BundledGFunctors) : Type := OwnPGpreS driver_state GF

/-- The allocated form: iris-lean's `OwnPGS` at `driver_state`. The
    `hlc` parameter is vestigial (OwnP is `.hasLC`-only upstream) and
    kept solely so arc-7 call sites `[CerbGS .hasLC GF]` re-elaborate
    unchanged; it is IGNORED. -/
abbrev CerbGS (_hlc : HasLC) (GF : BundledGFunctors) : Type :=
  OwnPGS driver_state GF

variable {GF : BundledGFunctors}

/-- The proof-side state assertion: iris-lean's `ownP` (the ExclAuth
    fragment over the full driver state). Kept under the arc-7 name as
    a reducible alias (S2 abbrev discipline). NOTE: the arc-7 `hlc`
    parameter is GONE (OwnP is `.hasLC`-only upstream); the handful of
    `(hlc := .hasLC)` call sites were renamed in the adoption commit. -/
abbrev stateIs [η : OwnPGS driver_state GF] (σ : driver_state) :
    IProp GF :=
  ownP σ

/-! ## A closed functor bundle carrying `CerbGpreS` (the HeapLangS
    pattern, reworked per design §1.1): indices 0-3 are the
    invariant/credit machinery, index 4 the OwnP ExclAuth cell over
    `driver_state` (was: a GhostVar functor). Downstream theorems
    needing a concrete `GF` (the T1-T5 discharges) instantiate at
    `CerbS`. -/

def CerbS : BundledGFunctors
  | 0 => ⟨InvMapF, by infer_instance⟩
  | 1 => ⟨constOF CoPsetDisjL, by infer_instance⟩
  | 2 => ⟨constOF (DisjointLeibnizSet PosSet), by infer_instance⟩
  | 3 => ⟨Auth.AuthURF (constOF Credit), by infer_instance⟩
  | 4 => ⟨ownPRF driver_state, by infer_instance⟩
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
  inG := ⟨4, rfl⟩

end Cerb
end RelSem
