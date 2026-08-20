/-
  RelSem.T3 — arc-7 S5a (2026-08-20): **T3, UNCONDITIONAL** (through
  the full WP route per D5).

  The slate's alloc/store/load-points-to theorem (charter T3):

    ∀ v : int-range, outcomes of callND(t3_roundtrip, [v])
                       = {Specified(v)}, no UB

  stated as `T3Statement` (statement-TCB: fuel opsem only). The
  Layer-2 residual is the app-equation THEOREM `RelSem.T3.t3_app_eq`
  (RelSem/T3AppEq.lean — prefix + twenty-three driver rounds:
  create/store/load/kill through the memory lens, the value's byte
  roundtrip TWICE, both conv_loaded_int range checks).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.SlateWP
import RelSem.T3AppEq
import RelSem.T1

set_option autoImplicit false

namespace RelSem.T3

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (intRange)

/-- The harness filesystem state (the driver default). -/
def t3Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- T3's pure spec: the result value is the injected integer,
    Specified. -/
def t3Spec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue x

/-- THE T3 HEADLINE STATEMENT (fuel opsem only). -/
def T3Statement : Prop :=
  ∀ x : Int, intRange x →
    CallHarnessAdequate t3File.tagDefs t3File "roundtrip"
      [intValue x] t3Fs (t3Spec x)

/-- **T3, UNCONDITIONAL** (through the full WP route per D5). -/
theorem T3 : T3Statement := by
  intro x hx
  exact callHarnessAdequate_of_app_eq_wp
    (t3_app_eq x hx.1 hx.2) (t3_result_eq x)

/-- T3's direct-route twin (cross-check scaffolding per D5). -/
theorem T3_direct : T3Statement := by
  intro x hx
  exact callHarnessAdequate_of_app_active
    (t3_app_eq x hx.1 hx.2) (t3_result_eq x)

/-- **T3's UB-freedom, UNCONDITIONAL** (WP route). RESTATED
    CerbND-shaped in arc-7 S5c (audit-1 F2): conclusion is
    `CallHarnessUBFree`; the seqModel form is only the route's
    intermediate. -/
theorem T3_ubFree :
    ∀ x : Int, intRange x →
      CallHarnessUBFree t3File.tagDefs t3File "roundtrip"
        [intValue x] t3Fs := by
  intro x hx
  exact callHarnessUBFree_of_ubFree
    (callUBFree_of_app_eq_wp (t3_app_eq x hx.1 hx.2))

/-- T3's outcome-SET companion statement (arc-7 S5c, audit-1 F5). -/
def T3OutcomesStatement : Prop :=
  ∀ x : Int, intRange x →
    CerbND.runND (callND t3File.tagDefs t3File "roundtrip" [intValue x])
        (initial_driver_state t3File t3Fs)
      = [(Active (finalize t3File.tagDefs "callND" (drDone x)), [],
          drDone x)]

/-- **T3's outcome-set singleton, UNCONDITIONAL.** -/
theorem T3Outcomes : T3OutcomesStatement := fun x hx =>
  runND_active (t3_app_eq x hx.1 hx.2)

end RelSem.T3
