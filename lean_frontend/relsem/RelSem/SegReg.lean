/-
  RelSem.SegReg — V2b (2026-08-28): registration attributes for the
  cut-point stepper's supply (RelSem/SegStepper.lean).

  * `@[seg_round]` — register a fixture ROUND EQUATION
    (`app (dnmsRoundM td tid) (fam … p) = (NDactive v, fam' … p')`,
    hypotheses = the round's cell/footprint/path facts) under kind
    `roundEq` in THE ONE REGISTRY (RelSem/LawRegistry.lean). The
    stepper dispatches by goal form (DiscrTree over the equation LHS
    — the R4 contract: never a hardcoded name table).
  * `@[seg_inv]` — register a fixture CONTROL-FAMILY INVERSION
    (`ctlOf σ = C → ∃ p, σ = fam p`) under kind `famInv`.

  Supply entries, not laws: the engine-side minter that replaces the
  per-fixture text is the registered arc-19 frontier (the SegmentFaces
  `@[seg_eq]` note applies verbatim).

  House rules: no sorry, no axioms; meta code only.
-/

import RelSem.LawRegistry

set_option autoImplicit false

open Lean Meta

namespace RelSem.Seg

private def addSupplyEntry (declName : Name) (kind : Name)
    (attrKind : AttributeKind) : AttrM Unit := do
  let keys ← MetaM.run' (LawRegistry.goalFormKeys declName)
  ScopedEnvExtension.add LawRegistry.stepLawExt
    { name := declName, keys, kind, variant := .anonymous,
      side := `fed, frontier := s!"seg/{kind}",
      trace := s!"\{law := {declName}, joint := seg/{kind}}",
      lineage := "fixture segment-stepper supply (V2b; engine-side \
        minting is the registered arc-19 frontier)",
      prio := keys.size } attrKind

/-- `@[seg_round]`: register a round equation as stepper supply
    (kind `roundEq`). -/
syntax (name := seg_round) "seg_round" : attr

initialize registerBuiltinAttribute {
  name := `seg_round
  descr := "segment-stepper round-equation supply (kind roundEq in \
    THE ONE registry)"
  add := fun declName _ kind => addSupplyEntry declName `roundEq kind
}

/-- `@[seg_inv]`: register a control-family inversion as stepper
    supply (kind `famInv`). -/
syntax (name := seg_inv) "seg_inv" : attr

initialize registerBuiltinAttribute {
  name := `seg_inv
  descr := "segment-stepper family-inversion supply (kind famInv in \
    THE ONE registry)"
  add := fun declName _ kind => addSupplyEntry declName `famInv kind
}

/-- `@[seg_block]` — PERF-1 (2026-08-28), mechanism B: register a
    fixture BLOCK FACT (`SegStep td tid K Γᵢ Γₒ` over a quantified
    context — one lemma per maximal straight-line pure-control run
    between cut points, proved by the once-proved sequence
    composition `SegStep.trans` over `link_ctl`; classical: Floyd
    1967 cut points + the Hoare 1969 sequence rule applied at
    generation time) under kind `segBlock`. The stepper consumes
    blocks FIRST (committed choice); per-round facts remain the
    anchor unit at cut points and stay derivable by hand (the
    escalation ladder). -/
syntax (name := seg_block) "seg_block" : attr

initialize registerBuiltinAttribute {
  name := `seg_block
  descr := "segment-stepper block-fact supply (kind segBlock in THE \
    ONE registry; PERF-1 mechanism B, block-granular default)"
  add := fun declName _ kind => addSupplyEntry declName `segBlock kind
}

end RelSem.Seg
