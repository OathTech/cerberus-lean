import CerbGlobal
/-! AUDITOR probe: `CerbSwitch` derives `Inhabited`; H2 placed `pointer_arith` FIRST, so the derived
    default moved. At the base the first constructor was `strict_reads`. -/
example : (default : CerbGlobal.CerbSwitch) = .pointer_arith .PERMISSIVE := rfl
example : (default : CerbGlobal.PointerArithMode) = .PERMISSIVE := rfl
-- the pre-H2 default (expected: 1 error at HEAD)
example : (default : CerbGlobal.CerbSwitch) = .strict_reads := rfl
#print CerbGlobal.instInhabitedCerbSwitch
