/-
  RelSem.SegLoop — V3a (2026-08-28): LOOPS AT THE SEGMENT SEQUENT
  (infrastructure plan component D, on the V1/V2 substrate).

  Two once-proved pieces:

  * ITERATION/WHILE at `SegStep` (the WP-transformer sequent of
    RelSem/SegRun.lean): a VALUE-CARRYING invariant family
    `St : Nat → Ctx` — the declared loop invariant, its data (env
    cell values, byte contents, supplies) as an explicit function of
    the iteration index (the professor's improvement 2: the
    invariant CONSTRAINS the family; never a walk-endpoint readback)
    — whose body segments compose to the whole loop by the
    once-proved sequence rule. Lineage: Floyd-Hoare invariant
    iteration; BRiCk `wp_while_inv` (deps/BRiCk logic/stmt.v,
    IDEAS-ONLY); RefinedC `typed_block` at the loop label
    (deps/refinedc theories/typing/programs.v:68-73, BSD, structural
    mirror); the `Seg.iter`/`Seg.while_inv` shape (RelSem/
    Segment.lean §2) transplanted to the round-exact sequent.

  * THE VARIANT RULE's mathematical core (Dijkstra bound functions /
    total-correctness Hoare while — the documented F2c gap P11
    forces): a loop with NO closed-form trip count gets its ∃-trip
    count DERIVED from a strictly decreasing Nat measure on the
    value family (`first_exit`): well-founded descent yields the
    first guard-false index. The loop then discharges through
    `SegStep.iter` at that index — termination is proved, never
    assumed (the judgment stays total/fuel-bounded, [F7]).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.SegRun

set_option autoImplicit false

namespace RelSem.Seg

open RelSem RelSem.Cerb RelSem.CerbSt
open Iris

variable {GF : BundledGFunctors} [CerbStGS GF]
variable {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
variable {tid : Nat}

/-! ## §1 Iteration at the segment sequent -/

/-- ITERATION (the value-carrying invariant rule): `n` body segments
    over the declared family `St`, each exactly `k` rounds, compose
    to the whole loop — `k·n` rounds from `St 0` to `St n`. -/
@[step_law (kind := loop) (variant := iterCtx) (side := fed)
  (frontier := "loop/iter-ctx")
  (trace := "{law := SegStep.iter, joint := loop/iter, hyps := [hbody : fed(∀-i body segment)]}")
  (lineage := "Floyd-Hoare invariant iteration at the round-exact segment sequent (value-carrying invariant family; budget = per-iteration rounds × trip count)")]
theorem SegStep.iter {St : Nat → Ctx} {k : Nat} (n : Nat)
    (hbody : ∀ i, i < n →
      SegStep (GF := GF) tagDefs tid k (St i) (St (i + 1))) :
    SegStep (GF := GF) tagDefs tid (k * n) (St 0) (St n) := by
  induction n with
  | zero => exact SegStep.refl
  | succ n ih =>
    have h1 : SegStep (GF := GF) tagDefs tid (k * n) (St 0) (St n) :=
      ih (fun i hi => hbody i (Nat.lt_succ_of_lt hi))
    have h2 : SegStep (GF := GF) tagDefs tid k (St n) (St (n + 1)) :=
      hbody n (Nat.lt_succ_self n)
    have h := h1.trans h2
    rwa [← Nat.mul_succ] at h

/-- Iteration from an arbitrary start index (the peeled/offset form —
    loops entered after a peeled first iteration, or resumed at a
    join). -/
theorem SegStep.iter_from {St : Nat → Ctx} {k : Nat} (m n : Nat)
    (hmn : m ≤ n)
    (hbody : ∀ i, m ≤ i → i < n →
      SegStep (GF := GF) tagDefs tid k (St i) (St (i + 1))) :
    SegStep (GF := GF) tagDefs tid (k * (n - m)) (St m) (St n) := by
  have h := SegStep.iter (GF := GF) (St := fun j => St (m + j))
    (k := k) (n - m)
    (fun i hi => by
      have := hbody (m + i) (Nat.le_add_right m i) (by omega)
      simpa [Nat.add_assoc] using this)
  have hEnd : m + (n - m) = n := by omega
  rw [hEnd] at h
  exact h

/-! ## §2 The variant rule's core: first guard-false index from a
    decreasing measure (Dijkstra bound function) -/

/-- THE ∃-TRIP-COUNT DERIVATION: a value family `c` whose Nat
    measure `μ` strictly decreases while the (decidable) guard holds
    reaches a FIRST guard-false index. Total correctness with no
    closed-form trip count — the trip count is an ∃-witness of
    well-founded descent. -/
theorem first_exit {D : Type} (c : Nat → D) (G : D → Prop)
    [DecidablePred G] (μ : D → Nat)
    (hdec : ∀ i, G (c i) → μ (c (i + 1)) < μ (c i)) :
    ∃ n, ¬ G (c n) ∧ ∀ i, i < n → G (c i) := by
  -- strong induction on the measure at the start index
  suffices h : ∀ (fuel start : Nat), μ (c start) < fuel →
      (∀ i, i < start → G (c i)) →
      ∃ n, ¬ G (c n) ∧ ∀ i, i < n → G (c i) by
    exact h (μ (c 0) + 1) 0 (Nat.lt_succ_self _) (fun i hi => by omega)
  intro fuel
  induction fuel with
  | zero => intro start h; omega
  | succ fuel ih =>
    intro start hμ hpre
    by_cases hg : G (c start)
    · refine ih (start + 1) ?_ ?_
      · have := hdec start hg
        omega
      · intro i hi
        rcases Nat.lt_succ_iff_lt_or_eq.mp hi with h | h
        · exact hpre i h
        · subst h; exact hg
    · exact ⟨start, hg, hpre⟩

end RelSem.Seg
