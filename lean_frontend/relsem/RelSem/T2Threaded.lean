/-
  RelSem.T2Threaded — V0 (2026-08-27): THE T2 STATEMENT, HONEST-
  UNPROVED, in the consistency-freshness house shape.

  tests/verify/t2_add.c: `int add(int a, int b)` — addition under the
  no-signed-overflow precondition (the arc-7 spec-discovery pattern:
  the range-tripled pre is what excludes UB036).

  TOMBSTONE (the V0 kill basket — record
  docs/2026-08-27_v0-statements-and-ban.md): the guarded ∀-seed proof
  and its T2Walks equation supply are DELETED; the statement stands
  as an HONEST-UNPROVED TARGET. The former
  `T2ThreadedOutcomesStatement` (exact outcome-list pin over the
  internal terminal state) is deleted with the walk vocabulary.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.T1File
import RelSem.SlateFiles

set_option autoImplicit false

namespace RelSem.T2

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (intRange)

/-! ## Statement data (fuel-opsem faces; first-order executable) -/

/-- The harness filesystem. RE-HOMED from the deleted
    RelSem/T2Walks.lean at V0 (text unchanged). -/
def t2Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- T2's pure spec on driver results: add(x, y) = x + y, Specified.
    RE-HOMED from the deleted RelSem/T2Walks.lean at V0 (text
    unchanged). -/
def t2Spec (x y : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue (x + y)

/-! ## THE STATEMENT (honest-unproved target; consistency-freshness
    house shape) -/

/-- THE T2 HEADLINE (fuel opsem only): for every in-range x, y with
    in-range sum, every CONSISTENT outcome of
    `callND(add, [intValue x, intValue y])` is `Active (x + y)`,
    Specified. HONESTY LABEL: PROVED (V2 2026-08-28 —
    RelSem.T2.t2_threaded_proved, RelSem/T2Proof.lean; trio cone,
    pinned in-build). -/
def T2ThreadedStatement : Prop :=
  ∀ (x y : Int),
    intRange x → intRange y → intRange (x + y) →
    CallHarnessAdequateCns t2Prior t2File.tagDefs t2File "add"
      [intValue x, intValue y] t2Fs (t2Spec x y)

/-- The UB-freedom companion. HONESTY LABEL: PROVED (V2 2026-08-28 —
    RelSem.T2.t2_ubfree_proved; trio cone, pinned in-build). -/
def T2ThreadedUBFreeStatement : Prop :=
  ∀ (x y : Int),
    intRange x → intRange y → intRange (x + y) →
    CallHarnessUBFreeCns t2Prior t2File.tagDefs t2File "add"
      [intValue x, intValue y] t2Fs

end RelSem.T2
