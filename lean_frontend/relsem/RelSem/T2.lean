/-
  RelSem.T2 — arc-7 S5a (2026-08-20): **T2, UNCONDITIONAL** (through
  the full WP route per D5).

  The slate's pure-step + bind theorem (charter T2), with the
  NO-SIGNED-OVERFLOW PRECONDITION the UB-freedom obligation forces
  (spec-discovery banked in tests/verify/expectations.txt: the
  overflow rows are UB036):

    ∀ x y : int-range with x+y in range,
      outcomes of callND(t2_add, [x, y]) = {Specified(x+y)}, no UB

  stated as `T2Statement` (statement-TCB: fuel opsem only — the
  production runner on the pinned Core program term,
  RelSem/SlateFiles.lean t2File). The Layer-2 residual is the app
  equation THEOREM `RelSem.T2.t2_app_eq` (RelSem/T2AppEq.lean — the
  compositional chain: prefix + fifteen driver rounds including the
  two byte-roundtrip loads and the catch_add overflow check, where
  every precondition enters). The WP route runs through the
  fixture-generic bridge (RelSem/SlateWP.lean).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.SlateWP
import RelSem.T2AppEq
import RelSem.T1

set_option autoImplicit false

namespace RelSem.T2

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (intRange)

/-- The harness filesystem state (the driver default, as T1). -/
def t2Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- T2's pure spec on driver results: the result value is the sum,
    Specified. -/
def t2Spec (x y : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue (x + y)

/-- THE T2 HEADLINE STATEMENT (fuel opsem only): under the range
    preconditions — each argument fits `signed int` AND the sum does
    (the forced no-signed-overflow precondition) — every outcome the
    production runner enumerates for `callND(add, [x, y])` on the
    pinned T2 program is `Active r` with `r.dres_core_value =
    intValue (x+y)`. -/
def T2Statement : Prop :=
  ∀ x y : Int, intRange x → intRange y → intRange (x + y) →
    CallHarnessAdequate t2File.tagDefs t2File "add"
      [intValue x, intValue y] t2Fs (t2Spec x y)

/-- **T2, UNCONDITIONAL** (through the full WP route per D5). -/
theorem T2 : T2Statement := by
  intro x y hx hy hs
  exact callHarnessAdequate_of_app_eq_wp
    (t2_app_eq x y hx.1 hx.2 hy.1 hy.2 hs.1 hs.2)
    (t2_result_eq x y)

/-- T2's direct-route twin (cross-check scaffolding per D5). -/
theorem T2_direct : T2Statement := by
  intro x y hx hy hs
  exact callHarnessAdequate_of_app_active
    (t2_app_eq x y hx.1 hx.2 hy.1 hy.2 hs.1 hs.2)
    (t2_result_eq x y)

/-- **T2's UB-freedom, UNCONDITIONAL** (WP route): under the
    preconditions the call has no UB outcome. RESTATED CerbND-shaped in
    arc-7 S5c (audit-1 F2): conclusion is `CallHarnessUBFree`; the
    seqModel form is only the route's intermediate. -/
theorem T2_ubFree :
    ∀ x y : Int, intRange x → intRange y → intRange (x + y) →
      CallHarnessUBFree t2File.tagDefs t2File "add"
        [intValue x, intValue y] t2Fs := by
  intro x y hx hy hs
  exact callHarnessUBFree_of_ubFree (callUBFree_of_app_eq_wp
    (t2_app_eq x y hx.1 hx.2 hy.1 hy.2 hs.1 hs.2))

/-- T2's outcome-SET companion statement (arc-7 S5c, audit-1 F5). -/
def T2OutcomesStatement : Prop :=
  ∀ x y : Int, intRange x → intRange y → intRange (x + y) →
    CerbND.runND (callND t2File.tagDefs t2File "add"
        [intValue x, intValue y])
        (initial_driver_state t2File t2Fs)
      = [(Active (finalize t2File.tagDefs "callND" (drDone x y)), [],
          drDone x y)]

/-- **T2's outcome-set singleton, UNCONDITIONAL.** -/
theorem T2Outcomes : T2OutcomesStatement := fun x y hx hy hs =>
  runND_active (t2_app_eq x y hx.1 hx.2 hy.1 hy.2 hs.1 hs.2)

end RelSem.T2
