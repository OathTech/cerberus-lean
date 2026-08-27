/-
  RelSem.T5 — arc-18 R4 (2026-08-27): T5 THROUGH THE SEGMENT LAYER —
  THE INPUT-FAMILY LOOP FLAGSHIP.

  tests/verify/t5_sum.c: `int sum(int n)` — the bounded scalar loop.
  THE CHARTERED THEOREM SHAPE (the fixture header): for all n with
  0 ≤ n ≤ 100, outcomes of callND(sum, [intValue n]) =
  {Specified(n*(n-1)/2)}, no UB — at the guarded ∀-seed house form
  (digest pin + seed apartness; T4SeedApart lineage), ∀-n INPUT
  FAMILY (the trip count is SYMBOLIC: `Seg.while_inv` applies at the
  free variable — the loop induction lives in the once-proved rule,
  never in this file).

  The proof is the blackboard argument: ONE invariant declared at the
  loop head (`T5S.t5SeamInv` — s = k·(k−1)/2 ∧ i = k at the k-th
  visit, both twin spellings routed by the [F3] normalizer), body
  obligations discharged by the registered walk chains over the ∀-k
  pack closure (RelSem/T5Inv + RelSem/T5Spine — engine room), the
  driver atom by `driver2_of_seg` through the once-proved
  `wpk_seq_scratch2`, statements by `verify_fn` + `seg_auto`.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.T5Spine

set_option autoImplicit false

namespace RelSem.T5

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit RelSem.T5W RelSem.T5S

/-! ## Statement data (fuel-opsem faces; first-order executable) -/

/-- T5's pure spec on driver results: sum(n) = n·(n−1)/2, Specified.
    (For the C loop `for (i = 0; i < n; i++) s += i`, the sum of
    0..n−1.) -/
def t5Spec (n : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue (n * (n - 1) / 2)

/-- The environment hypothesis (digest pin; T4EnvHypThr lineage). -/
def T5EnvHypThr : Prop := CerberusFresh.digest () = ""

/-- Seed apartness: the run's fresh draws (2 per iteration, ≤ 100
    iterations, plus slack) stay below every static symbol hash
    (≥ 2⁶⁰; T4SeedApart lineage). -/
def T5SeedApart (seed : Nat) : Prop :=
  seed + 256 < 1152921504606846976

/-- The chartered input range (the fixture header's 0 ≤ n ≤ 100). -/
def t5Range (n : Int) : Prop := 0 ≤ n ∧ n ≤ 100

/-- T5's FnSpec ([F9]): sum(n) = Specified(n·(n−1)/2) for range n,
    under the guarded face (REDUCIBLE — the faces unify against the
    statement text). The ∀-n INPUT FAMILY: `A = Int`. -/
abbrev sumSpec : Seg.FnSpec Int :=
  { fname := "sum", args := fun n => [intValue n],
    pre := t5Range,
    guard := fun seed => T5EnvHypThr ∧ T5SeedApart seed,
    post := t5Spec }

/-! ## The terminal readout (the one registered postcondition fact:
    the run's exit value meets the closed form — `triF_closed`) -/

/-- The harness terminal's readout at the fixed final rest: the
    composed run returns exactly the closed-form sum. -/
@[seg_post]
theorem t5_post_o (seed : Nat) (n : Int) (hn0 : 0 ≤ n)
    (hn1 : n ≤ 100) : ∀ bm am,
    ∃ r : driver_result,
      (Outcome.value (finalize t5File.tagDefs "callND"
          (setMaps (rDone5 seed n) bm am)) : DriveVal)
        = Outcome.value r ∧ t5Spec n r :=
  fun bm am => ⟨_, rfl, by
    show (finalize t5File.tagDefs "callND"
      (setMaps (rDone5 seed n) bm am)).dres_core_value
      = intValue (n * (n - 1) / 2)
    rw [rDone5_readout seed n bm am]
    show intValue (triF n.toNat) = intValue (n * (n - 1) / 2)
    rw [triF_closed n hn0]⟩

/-! ## THE THREADED STATEMENTS (fuel-opsem faces, guarded ∀-seed,
    ∀-n input family) -/

/-- THE T5 HEADLINE (fuel opsem only): under the digest pin + seed
    apartness, for EVERY n with 0 ≤ n ≤ 100, every outcome of
    `callND(sum, [intValue n])` from the threaded initial state is
    `Active r` with `r = intValue (n·(n−1)/2)`. -/
def T5ThreadedStatement : Prop :=
  T5EnvHypThr →
  ∀ (seed : Nat), T5SeedApart seed →
    ∀ (n : Int), t5Range n →
      CallHarnessAdequateThr seed t5File.tagDefs t5File "sum"
        [intValue n] t5Fs (t5Spec n)

/-- **T5 THREADED** (cone exactly the classical trio): the
    input-family loop flagship THROUGH THE SEGMENT LAYER — one
    declared invariant, derived obligations at the symbolic trip
    count, a two-line proof. -/
theorem T5Threaded : T5ThreadedStatement := by
  verify_fn sumSpec
  seg_auto

/-- **T5 THREADED UB-freedom** (same route). -/
theorem T5Threaded_ubFree :
    T5EnvHypThr →
    ∀ (seed : Nat), T5SeedApart seed →
      ∀ (n : Int), t5Range n →
        CallHarnessUBFreeThr seed t5File.tagDefs t5File "sum"
          [intValue n] t5Fs := by
  verify_fn sumSpec
  seg_auto

end RelSem.T5
