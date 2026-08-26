/-
  RelSem.Kit.Loop — arc-9 S2 (2026-08-20): L1 kit, the loop rule +
  fuel algebra (design docs/2026-08-20_arc9-s1-design.md §2, gaps
  G1/G2; Q2 answer (a): a PURE composition core, the semantics pushed
  into walker-proved per-fixture `hbody` blocks).

  `iter_compose` is DELIBERATELY UNREGISTERED as a walker law (design
  §1.3): its `St` family is a Lean-level ∀-obligation no goal
  determines — the human names the invariant.

  The `_var` variant (arc-9 work order; built arc-18 R2 [F1]): a loop
  whose BODY BRANCHES has data-dependent per-iteration round counts —
  the uniform-`k` `iter_compose` cannot state it. `iter_compose_var`
  composes with a per-iteration count function `k : Nat → Nat` and a
  recursively summed total (`roundSum`). The segment layer's ∃-round
  judgment (RelSem/Segment.lean, `Seg.iter`) is the packaged form.

  Soundness: pure Nat-induction over equation transitivity — nothing
  about the semantics is assumed; zero axioms (pinned in Kit/Audit).

  House rules: no sorry, no axioms.
-/

import RelSem.Machine
import RelSem.LawRegistry

set_option autoImplicit false

namespace RelSem.Kit

/-- The offset composition core, shifted form (the induction engine
    behind `iter_compose`): from start index `j`, `n` iterations
    compose. -/
-- REGISTRY NOTE: degenerate goal-form key BY DESIGN (the conclusion
-- head is the invariant family C, a wildcard): iter_compose is never
-- goal-form-dispatched — the human names the invariant (module header;
-- design S1.3). The entry exists for the interface census + trace
-- vocabulary; queries cannot select it.
@[step_law (kind := loop) (variant := fromN) (side := fed)
  (frontier := "loop/compose")
  (trace := "{law := iter_compose_from, joint := loop/compose, hyps := [hbody : fed]}")
  (lineage := "Floyd-Hoare invariant composition at the equation calculus, shifted form (pure Nat induction)")]
theorem iter_compose_from {α σ : Type} {C : Nat → σ → α} {St : Nat → σ}
    {k : Nat} (j n : Nat)
    (hbody : ∀ i, j ≤ i → i < j + n → ∀ fuel,
      C (fuel + k) (St i) = C fuel (St (i + 1))) :
    ∀ fuel, C (fuel + k * n) (St j) = C fuel (St (j + n)) := by
  induction n generalizing j with
  | zero => intro fuel; rfl
  | succ n ih =>
    intro fuel
    have h1 : fuel + k * (n + 1) = (fuel + k * n) + k := by
      rw [Nat.mul_succ, ← Nat.add_assoc]
    rw [h1]
    have hstep := hbody j (Nat.le_refl j)
      (Nat.lt_add_of_pos_right (Nat.succ_pos n)) (fuel + k * n)
    rw [hstep]
    have h2 : j + (n + 1) = (j + 1) + n :=
      (Nat.add_succ j n).trans (Nat.succ_add j n).symm
    rw [h2]
    exact ih (j + 1) (fun i hle hlt fuel' =>
      hbody i (Nat.le_of_succ_le hle) (h2 ▸ hlt) fuel') fuel

/-- THE LOOP RULE (G1, design §2 contract verbatim): `St` is the
    invariant (a pure, closed-form state family), `i < n` the guard's
    semantic content, `hbody` body-preserves (one iteration block of
    `k` rounds, ∀-quantified in `i` and `fuel`); conclusion: the
    composed `k·n`-round block equation from `St 0` to `St n` — still
    relative fuel, still an ordinary app equation consumed by the
    UNCHANGED adequacy chain. -/
@[step_law (kind := loop) (variant := from0) (side := fed)
  (frontier := "loop/compose")
  (trace := "{law := iter_compose, joint := loop/compose, hyps := [hbody : fed]}")
  (lineage := "THE loop rule: invariant family St, k-round body block, composed k*n block equation (Floyd-Hoare at the equation calculus)")]
theorem iter_compose {α σ : Type} {C : Nat → σ → α} {St : Nat → σ}
    {k : Nat} {n : Nat}
    (hbody : ∀ i, i < n → ∀ fuel,
      C (fuel + k) (St i) = C fuel (St (i + 1))) :
    ∀ fuel, C (fuel + k * n) (St 0) = C fuel (St n) := by
  have h := iter_compose_from (C := C) (St := St) (k := k) 0 n
    (fun i _ hlt fuel => hbody i (Nat.zero_add n ▸ hlt) fuel)
  intro fuel
  rw [Nat.zero_add n] at h
  exact h fuel

/-! ## The variable-round variant (arc-18 R2 [F1]; the arc-9 `_var`
    work-order item). A branching loop body has DATA-DEPENDENT
    per-iteration round counts; composition sums them. Pure Nat
    induction, exactly as `iter_compose_from`. -/

/-- Total round count of iterations `[j, j+n)` under the per-iteration
    count function `k`. -/
def roundSum (k : Nat → Nat) : Nat → Nat → Nat
  | _, 0 => 0
  | j, n + 1 => k j + roundSum k (j + 1) n

/-- Shifted variable-round composition: from start index `j`, `n`
    iterations with per-iteration round counts `k i` compose into a
    `roundSum k j n`-round block. -/
@[step_law (kind := loop) (variant := fromNVar) (side := fed)
  (frontier := "loop/compose")
  (trace := "{law := iter_compose_var_from, joint := loop/compose, hyps := [hbody : fed]}")
  (lineage := "Floyd-Hoare invariant composition, VARIABLE per-iteration round count (branch-in-loop bodies; pure Nat induction)")]
theorem iter_compose_var_from {α σ : Type} {C : Nat → σ → α}
    {St : Nat → σ} {k : Nat → Nat} (j n : Nat)
    (hbody : ∀ i, j ≤ i → i < j + n → ∀ fuel,
      C (fuel + k i) (St i) = C fuel (St (i + 1))) :
    ∀ fuel, C (fuel + roundSum k j n) (St j) = C fuel (St (j + n)) := by
  induction n generalizing j with
  | zero => intro fuel; rfl
  | succ n ih =>
    intro fuel
    have h1 : fuel + roundSum k j (n + 1)
        = (fuel + roundSum k (j + 1) n) + k j := by
      show fuel + (k j + roundSum k (j + 1) n) = _
      omega
    rw [h1]
    rw [hbody j (Nat.le_refl j) (Nat.lt_add_of_pos_right (Nat.succ_pos n))
      (fuel + roundSum k (j + 1) n)]
    have h2 : j + (n + 1) = (j + 1) + n :=
      (Nat.add_succ j n).trans (Nat.succ_add j n).symm
    rw [h2]
    exact ih (j + 1) (fun i hle hlt fuel' =>
      hbody i (Nat.le_of_succ_le hle) (h2 ▸ hlt) fuel') fuel

/-- THE VARIABLE-ROUND LOOP RULE ([F1]): `iter_compose` with a
    per-iteration round-count FUNCTION — a loop whose body branches
    (data-dependent round counts) composes with the summed total. -/
@[step_law (kind := loop) (variant := from0Var) (side := fed)
  (frontier := "loop/compose")
  (trace := "{law := iter_compose_var, joint := loop/compose, hyps := [hbody : fed]}")
  (lineage := "THE variable-round loop rule: invariant family St, per-iteration count k i, composed roundSum block (Floyd-Hoare at the equation calculus)")]
theorem iter_compose_var {α σ : Type} {C : Nat → σ → α} {St : Nat → σ}
    {k : Nat → Nat} {n : Nat}
    (hbody : ∀ i, i < n → ∀ fuel,
      C (fuel + k i) (St i) = C fuel (St (i + 1))) :
    ∀ fuel, C (fuel + roundSum k 0 n) (St 0) = C fuel (St n) := by
  have h := iter_compose_var_from (C := C) (St := St) (k := k) 0 n
    (fun i _ hlt fuel => hbody i (Nat.zero_add n ▸ hlt) fuel)
  intro fuel
  rw [Nat.zero_add n] at h
  exact h fuel

/-! ## Fuel algebra (G2/Q5: the offset algebra suffices) -/

/-- Cast a fuel index across an arithmetic identity, under any
    fuel-indexed computation family (the `congrArg` move; discharge
    `h` by `omega`/`Nat.sub_add_cancel`). -/
theorem app_fuel_cast {A I E C S : Type} (M : Nat → ndM A I E C S)
    {a b : Nat} (h : a = b) (σ : S) :
    app (M a) σ = app (M b) σ := by rw [h]

/-- The default-budget split: peel a consumed-round count `c` off any
    fuel `F` it fits under (instantiated at `lemDefaultFuel` in the
    fixtures; `c ≤ F` discharges by `decide`/`omega` at slate bounds). -/
theorem fuel_split {c F : Nat} (h : c ≤ F) : F = (F - c) + c :=
  (Nat.sub_add_cancel h).symm

end RelSem.Kit
