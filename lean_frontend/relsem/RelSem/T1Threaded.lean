/-
  RelSem.T1Threaded — V0 (2026-08-27): THE T1 STATEMENT, HONEST-
  UNPROVED, in the consistency-freshness house shape.

  tests/verify/t1_id.c: `int id(int x)` — the identity function
  through a pointer-passed argument (load). Statement: over consistent
  executions (relsemcore/RelSem/Threaded.lean §CONSISTENCY), every
  outcome of `callND(id, [intValue x])` for int-range x is
  `Active (Specified x)`.

  TOMBSTONE (the V0 kill basket — record
  docs/2026-08-27_v0-statements-and-ban.md): this file previously
  PROVED the guarded ∀-seed T1 through the segment layer over the
  T1Walks + in-file hand-round equation supply (~850 lines: k-stage
  open equations, round chains, driver atoms — whole-run concrete-
  trace machinery, assessment class K-2b-adjacent). The proofs, their
  equation supply, and the walk files are DELETED (operator-ratified);
  the statement stands as an HONEST-UNPROVED TARGET for the V2
  per-construct rules. The former `T1ThreadedOutcomesStatement`
  (exact outcome-list pin quoting the internal terminal driver state
  `drDone_thr`) is DELETED WITH the walk vocabulary: its statement
  text was concrete-trace data, not a specification (catechism §III.7
  judgment, documented in the V0 record).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.T1File

set_option autoImplicit false

namespace RelSem.T1

open RelSem RelSem.Cerb

/-! ## Statement data (fuel-opsem faces; first-order executable) -/

/-- The harness filesystem (the default initial state). RE-HOMED from
    the deleted RelSem/T1Walks.lean at V0 (text unchanged). -/
def t1Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- T1's pure spec on driver results: id(x) = x, Specified. RE-HOMED
    from the deleted RelSem/T1Walks.lean at V0 (text unchanged). -/
def t1Spec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue x

/-! ## THE STATEMENT (honest-unproved target; consistency-freshness
    house shape — quantification over consistent executions replaces
    the ∀-seed form) -/

/-- THE T1 HEADLINE (fuel opsem only): for every int-range x, every
    CONSISTENT outcome of `callND(id, [intValue x])` — any counter
    seed, the execution's own draw window non-capturing against
    `t1Prior` — is `Active r` with `r.dres_core_value = intValue x`.
    HONESTY LABEL: UNPROVED (V0 target; the proof arrives with the
    V1 assertion layer + V2 per-construct rules). -/
def T1ThreadedStatement : Prop :=
  ∀ (x : Int), intRange x →
    CallHarnessAdequateCns t1Prior t1File.tagDefs t1File "id"
      [intValue x] t1Fs (t1Spec x)

/-- The UB-freedom companion. HONESTY LABEL: UNPROVED. -/
def T1ThreadedUBFreeStatement : Prop :=
  ∀ (x : Int), intRange x →
    CallHarnessUBFreeCns t1Prior t1File.tagDefs t1File "id"
      [intValue x] t1Fs

end RelSem.T1
