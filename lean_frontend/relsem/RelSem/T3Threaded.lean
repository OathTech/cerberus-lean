/-
  RelSem.T3Threaded — V0 (2026-08-27): THE T3 STATEMENT, HONEST-
  UNPROVED, in the consistency-freshness house shape.

  tests/verify/t3_roundtrip.c: `int roundtrip(int v)` — store to a
  local, load back (the scratch object's whole lifetime internal to
  the run).

  TOMBSTONE (the V0 kill basket — record
  docs/2026-08-27_v0-statements-and-ban.md): the guarded ∀-seed proof
  and its T3Walks equation supply are DELETED; the statement stands
  as an HONEST-UNPROVED TARGET. The former
  `T3ThreadedOutcomesStatement` (exact outcome-list pin over the
  internal terminal state) is deleted with the walk vocabulary.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.T1File
import RelSem.SlateFiles

set_option autoImplicit false

namespace RelSem.T3

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (intRange)

/-! ## Statement data (fuel-opsem faces; first-order executable) -/

/-- The harness filesystem. RE-HOMED from the deleted
    RelSem/T3Walks.lean at V0 (text unchanged). -/
def t3Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- T3's pure spec on driver results: roundtrip(x) = x, Specified.
    RE-HOMED from the deleted RelSem/T3Walks.lean at V0 (text
    unchanged). -/
def t3Spec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue x

/-! ## THE STATEMENT (honest-unproved target; consistency-freshness
    house shape) -/

/-- THE T3 HEADLINE (fuel opsem only): for every int-range x, every
    CONSISTENT outcome of `callND(roundtrip, [intValue x])` is
    `Active x`, Specified. HONESTY LABEL: UNPROVED (V0 target). -/
def T3ThreadedStatement : Prop :=
  ∀ (x : Int), intRange x →
    CallHarnessAdequateCns t3Prior t3File.tagDefs t3File "roundtrip"
      [intValue x] t3Fs (t3Spec x)

/-- The UB-freedom companion. HONESTY LABEL: UNPROVED. -/
def T3ThreadedUBFreeStatement : Prop :=
  ∀ (x : Int), intRange x →
    CallHarnessUBFreeCns t3Prior t3File.tagDefs t3File "roundtrip"
      [intValue x] t3Fs

end RelSem.T3
