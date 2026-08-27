/-
  RelSem.T5 — V0 (2026-08-27): THE T5 STATEMENT, HONEST-UNPROVED, in
  the consistency-freshness house shape.

  tests/verify/t5_sum.c: `int sum(int n)` — the bounded scalar loop.
  THE CHARTERED THEOREM SHAPE (the fixture header): for all n with
  0 ≤ n ≤ 100, outcomes of callND(sum, [intValue n]) =
  {Specified(n*(n-1)/2)}, no UB — the ∀-n INPUT FAMILY at a symbolic
  trip count.

  THE FRESHNESS FINALIZATION (V0, the Q3 amendment): the former
  `T5SeedApart` guard (seed + 256 < 2⁶⁰, a slack-carrying numeric
  bound) is DELETED; the statement quantifies over CONSISTENT
  EXECUTIONS (relsemcore/RelSem/Threaded.lean §CONSISTENCY) against
  the pinned static vocabulary `t5Prior` — the excluded runs are
  exactly the capturing ones, with no per-program slack arithmetic.

  TOMBSTONE (the V0 kill basket — record
  docs/2026-08-27_v0-statements-and-ban.md): the guarded ∀-seed proof
  (`verify_fn sumSpec; seg_auto` over the T5Inv/T5Seam/T5Spine
  ∀-k pack closure and T5Walks' five builder drives — ~3,300 lines of
  engine room) is DELETED; the statement stands as an HONEST-UNPROVED
  TARGET for the V3a predicate-invariant re-proof (retiring which was
  the engine rooms' registered trigger — executed early, at V0, with
  the whole basket, per the operator-ratified brief).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.T1File
import RelSem.SlateFiles

set_option autoImplicit false

namespace RelSem.T5

open RelSem RelSem.Cerb RelSem.Slate

/-! ## Statement data (fuel-opsem faces; first-order executable) -/

/-- The harness filesystem. RE-HOMED from the deleted
    RelSem/T5Spine.lean at V0 (text unchanged). -/
def t5Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- T5's pure spec on driver results: sum(n) = n·(n−1)/2, Specified.
    (For the C loop `for (i = 0; i < n; i++) s += i`, the sum of
    0..n−1.) -/
def t5Spec (n : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue (n * (n - 1) / 2)

/-- The environment hypothesis (digest pin; T4EnvHypThr lineage;
    UNCHANGED by the freshness finalization). -/
def T5EnvHypThr : Prop := CerberusFresh.digest () = ""

/-- The chartered input range (the fixture header's 0 ≤ n ≤ 100). -/
def t5Range (n : Int) : Prop := 0 ≤ n ∧ n ≤ 100

/-! ## THE STATEMENT (honest-unproved target; consistency-freshness
    house shape) -/

/-- THE T5 HEADLINE (fuel opsem only): under the digest pin, for
    EVERY n with 0 ≤ n ≤ 100, every CONSISTENT outcome of
    `callND(sum, [intValue n])` is `Active (n·(n−1)/2)`, Specified.
    HONESTY LABEL: UNPROVED (V0 target; V3a re-proof through
    predicate invariants + the variant rule). -/
def T5ThreadedStatement : Prop :=
  T5EnvHypThr →
  ∀ (n : Int), t5Range n →
    CallHarnessAdequateCns t5Prior t5File.tagDefs t5File "sum"
      [intValue n] t5Fs (t5Spec n)

/-- The UB-freedom companion. HONESTY LABEL: UNPROVED. -/
def T5ThreadedUBFreeStatement : Prop :=
  T5EnvHypThr →
  ∀ (n : Int), t5Range n →
    CallHarnessUBFreeCns t5Prior t5File.tagDefs t5File "sum"
      [intValue n] t5Fs

end RelSem.T5
