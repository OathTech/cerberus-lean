import CerbMem

/-! AUDITOR probe (item 2): is test/Unit/OpaqueFailureTest.lean's `#guard_msgs`-on-failing-`rfl`
    NON-VACUOUS? Demonstration without recompiling CerbMem: the PRE-H1 text of `CerbMem.combineProv`
    (git show 0457732e1:lean_frontend/CerbMem.lean:268-282 — byte-identical body, `panic!` leaves) is
    copied here as `combineProvOld`, and the test's exact `#guard_msgs` block is pointed at it. If the
    guard is non-vacuous, `rfl` SUCCEEDS on the transparent leaf, the expected error is missing, and
    `#guard_msgs` itself reports an error (RED). The HEAD function beside it must stay GREEN. -/

namespace AuditVacuity
-- (no `open CerbMem`: the guard docstrings below pretty-print fully-qualified names, as the committed test does)

def combineProvOld : CerbMem.Provenance → CerbMem.Provenance → CerbMem.Provenance
  | .Prov_none, .Prov_none => .Prov_none
  | .Prov_none, .Prov_some id => .Prov_some id
  | .Prov_none, .Prov_device => .Prov_device
  | .Prov_some id, .Prov_none => .Prov_some id
  | .Prov_some id1, .Prov_some id2 =>
    if id1 == id2 then .Prov_some id1 else .Prov_none
  | .Prov_some _, .Prov_device => .Prov_device
  | .Prov_device, .Prov_none => .Prov_device
  | .Prov_device, .Prov_some _ => .Prov_device
  | .Prov_device, .Prov_device => .Prov_device
  -- PNVI-ae-udi only; concrete model doesn't use Prov_symbolic (impl_mem.ml:390-394)
  | .Prov_symbolic _, _ => panic! "Concrete.combine_prov: found a Prov_symbolic"
  | _, .Prov_symbolic _ => panic! "Concrete.combine_prov: found a Prov_symbolic"

-- (A) the PRE-H1 leaf: expected RED (the guard's docstring expects an rfl failure that does not happen)
/-- error: Tactic `rfl` failed: The left-hand side
  AuditVacuity.combineProvOld (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none
is not definitionally equal to the right-hand side
  CerbMem.Provenance.Prov_none

⊢ AuditVacuity.combineProvOld (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none = CerbMem.Provenance.Prov_none
-/
#guard_msgs in
example : combineProvOld (.Prov_symbolic 0) .Prov_none = .Prov_none := by rfl

-- (B) the HEAD leaf (the committed test's first block, verbatim): expected GREEN
/-- error: Tactic `rfl` failed: The left-hand side
  CerbMem.combineProv (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none
is not definitionally equal to the right-hand side
  CerbMem.Provenance.Prov_none

⊢ CerbMem.combineProv (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none = CerbMem.Provenance.Prov_none
-/
#guard_msgs in
example : CerbMem.combineProv (.Prov_symbolic 0) .Prov_none = .Prov_none := by rfl

-- (C) and the transparent leaf really does reduce to `default` at the kernel: the pre-H1 defect, shown
example : combineProvOld (.Prov_symbolic 0) .Prov_none = .Prov_none := rfl

end AuditVacuity
