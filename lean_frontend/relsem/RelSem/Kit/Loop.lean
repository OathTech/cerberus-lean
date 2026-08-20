/-
  RelSem.Kit.Loop — arc-9 S2 (2026-08-20): L1 kit, the loop rule +
  fuel algebra (design docs/2026-08-20_arc9-s1-design.md §2, gaps
  G1/G2; Q2 answer (a): a PURE composition core, the semantics pushed
  into walker-proved per-fixture `hbody` blocks).

  `iter_compose` is DELIBERATELY UNREGISTERED as a walker law (design
  §1.3): its `St` family is a Lean-level ∀-obligation no goal
  determines — the human names the invariant.

  The `_exit`/`_var` variants are S3 (work order); not built here.

  Soundness: pure Nat-induction over equation transitivity — nothing
  about the semantics is assumed; zero axioms (pinned in Kit/Audit).

  House rules: no sorry, no axioms.
-/

import RelSem.Machine

set_option autoImplicit false

namespace RelSem.Kit

/-- The offset composition core, shifted form (the induction engine
    behind `iter_compose`): from start index `j`, `n` iterations
    compose. -/
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
