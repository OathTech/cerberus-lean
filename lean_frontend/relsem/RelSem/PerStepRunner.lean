/-
  RelSem.PerStepRunner — arc-16 S3 (2026-08-24): THE RUNNER-OBSERVATION
  ALGEBRA — the generic simulation toolkit behind the loop peels.

  Context (S1 record §1/§5): fuel'd `nd_bind` is NOT associative as
  values (wrap-fuel misaligns at depth ~10^6), so no peeled loop can be
  connected to the generated fuel recursion by a denotation equality.
  The connection that IS available — and canonical — lives at the
  RUNNER-OBSERVATION level: two programs are interchangeable when the
  production enumerator `CerbND.runNDFuel` cannot tell them apart at
  any fuel within the envelope. This file proves the three generic
  principles every peel walk consumes:

  * `runNDFuel_bind_congr`  — pointwise-equal CONTINUATIONS are
    runner-equal under a bind, at any wrap fuels ≥ the runner fuel
    (the "descend into an opaque atom" move: all node casing lives
    here, once).
  * `runNDFuel_bind_assoc`  — bind RE-ASSOCIATION is a runner-level
    equality (the value-level failure is quarantined to wrap fuels the
    runner cannot reach).
  * `runNDFuel_bind_active` — a deterministic head under a bind is
    STRIPPED fuel-free (bind-collapse, observed).

  Lineage (canon-first): these are the monad laws of the ND monad,
  recovered as observational equalities relative to the fuel'd runner —
  the standard "syntactic monad, laws up to observation" move of
  interaction-tree/free-monad semantics (ITree `eutt` bind laws); the
  induction template is S1's `runNDFuel_bind_fuel_irrel`. Nothing here
  is new machinery: each lemma is proved once by the same F-induction
  and consumed by every peel.

  House rules: no sorry, no axioms declared. Under the in-build audit.
-/

import Nondeterminism
import CerbND
import RelSem.Machine
import RelSem.RunND
import RelSem.PerStep

set_option autoImplicit false

namespace RelSem

section RunnerAlgebra

variable {A B G I E C S : Type}

/-! ## app-level congruence under a bind wrap -/

/-- Equal one-node observations of the heads give equal one-node
    observations of same-fuel bind wraps: the wrap's action dispatches
    on `app` of the head alone. -/
theorem app_bindFuel_congr (b : Nat) {m m' : ndM A I E C S} {σ σ' : S}
    (h : app m σ = app m' σ') (f : A → ndM B I E C S) :
    app (nd_bind_lemFuel (b + 1) m f) σ
      = app (nd_bind_lemFuel (b + 1) m' f) σ' := by
  cases m with
  | ND g =>
    cases m' with
    | ND g' =>
      have hg : g σ = g' σ' := h
      simp only [nd_bind_lemFuel, app, hg]

/-! ## Deterministic-head stripping (bind-collapse, observed at every
    runner fuel — the collapse consumes NO runner fuel) -/

/-- Active head under a positive-fuel bind wrap: the runner continues
    at the continuation, same fuel. -/
theorem runNDFuel_bindFuel_active (b : Nat) {m : ndM A I E C S}
    {f : A → ndM B I E C S} {σ σ₁ : S} {v : A}
    (h : app m σ = (NDactive v, σ₁)) :
    ∀ F, CerbND.runNDFuel F (nd_bind_lemFuel (b + 1) m f) σ
        = CerbND.runNDFuel F (f v) σ₁
  | 0 => by rw [runNDFuel_zero, runNDFuel_zero]
  | F + 1 => runNDFuel_succ_congr F (app_bindFuel_active b h)

/-- The default-fuel wrapper form (the generated `nd_bind` itself). -/
theorem runNDFuel_bind_active {m : ndM A I E C S}
    {f : A → ndM B I E C S} {σ σ₁ : S} {v : A}
    (h : app m σ = (NDactive v, σ₁)) (F : Nat) :
    CerbND.runNDFuel F (nd_bind m f) σ = CerbND.runNDFuel F (f v) σ₁ :=
  runNDFuel_bindFuel_active 999999 h F

/-- Killed head under a positive-fuel bind wrap: the enumeration is the
    kill singleton at every positive runner fuel. -/
theorem runNDFuel_bindFuel_killed (b : Nat) {m : ndM A I E C S}
    {f : A → ndM B I E C S} {σ σ₁ : S} {r : kill_reason E}
    (h : app m σ = (NDkilled r, σ₁)) (F : Nat) :
    CerbND.runNDFuel (F + 1) (nd_bind_lemFuel (b + 1) m f) σ
      = [(Killed σ₁ r, [], σ₁)] :=
  runNDFuel_killed F (app_bindFuel_killed b h)

/-! ## Continuation congruence (the descend-into-an-atom move).

    All node casing of the peel walks is concentrated HERE: at an
    opaque atom `m`, two binds with pointwise runner-equal
    continuations are runner-equal, whatever `m` does (activate, kill,
    branch, offer, guard). The pointwise hypothesis is available at
    every fuel ≤ the outer fuel because node descent decrements the
    runner fuel. Induction template: `runNDFuel_bind_fuel_irrel`. -/

theorem runNDFuel_bind_congr :
    ∀ (F b b' : Nat), F ≤ b → F ≤ b' →
    ∀ {m : ndM A I E C S} {f g : A → ndM B I E C S},
      (∀ (v : A) (σ₁ : S) (F' : Nat), F' ≤ F →
        CerbND.runNDFuel F' (f v) σ₁ = CerbND.runNDFuel F' (g v) σ₁) →
      ∀ σ : S,
        CerbND.runNDFuel F (nd_bind_lemFuel b m f) σ
          = CerbND.runNDFuel F (nd_bind_lemFuel b' m g) σ := by
  intro F
  induction F with
  | zero => intro b b' _ _ m f g _ σ; rw [runNDFuel_zero, runNDFuel_zero]
  | succ F ih =>
    intro b b' hb hb' m f g hcont σ
    cases b with
    | zero => exact absurd hb (by omega)
    | succ b =>
      cases b' with
      | zero => exact absurd hb' (by omega)
      | succ b' =>
        have hFb : F ≤ b := Nat.le_of_succ_le_succ hb
        have hFb' : F ≤ b' := Nat.le_of_succ_le_succ hb'
        have hcont' : ∀ (v : A) (σ₁ : S) (F' : Nat), F' ≤ F →
            CerbND.runNDFuel F' (f v) σ₁ = CerbND.runNDFuel F' (g v) σ₁ :=
          fun v σ₁ F' hF' => hcont v σ₁ F' (Nat.le_succ_of_le hF')
        cases m with
        | ND gm =>
          rcases happ : gm σ with ⟨act, st1⟩
          have happ' : app (ND gm) σ = (act, st1) := happ
          cases act with
          | NDactive v =>
            rw [runNDFuel_bindFuel_active b happ',
              runNDFuel_bindFuel_active b' happ']
            exact hcont v st1 (F + 1) (Nat.le_refl _)
          | NDkilled r =>
            rw [runNDFuel_killed F (app_bindFuel_killed b happ'),
              runNDFuel_killed F (app_bindFuel_killed b' happ')]
          | NDnd i br =>
            rw [runNDFuel_nd F (app_bindFuel_nd b happ'),
              runNDFuel_nd F (app_bindFuel_nd b' happ'),
              List.foldl_map, List.foldl_map]
            exact foldl_prepend_congr br
              (fun p _ => ih b b' hFb hFb' hcont' st1) []
          | NDstep i br =>
            rw [runNDFuel_step F (app_bindFuel_step b happ'),
              runNDFuel_step F (app_bindFuel_step b' happ'),
              List.foldl_map, List.foldl_map]
            exact foldl_prepend_congr br
              (fun p _ => ih b b' hFb hFb' hcont' st1) []
          | NDguard i c mk =>
            rw [runNDFuel_guard F (app_bindFuel_guard b happ'),
              runNDFuel_guard F (app_bindFuel_guard b' happ')]
            exact ih b b' hFb hFb' hcont' st1
          | NDbranch i c l r =>
            rw [runNDFuel_branch F (app_bindFuel_branch b happ'),
              runNDFuel_branch F (app_bindFuel_branch b' happ')]
            rw [ih b b' hFb hFb' hcont' st1, ih b b' hFb hFb' hcont' st1]

/-! ## Runner-level bind re-association.

    `nd_bind (nd_bind m f) g` and `nd_bind m (fun x => nd_bind (f x) g)`
    differ as VALUES (node branches re-wrap at different residual
    fuels) but are indistinguishable to the runner within the fuel
    envelope: deterministic prefixes collapse identically, and node
    descent decrements both sides in lockstep. -/

theorem runNDFuel_bind_assoc :
    ∀ (F : Nat) (b₁ b₂ b₃ b₄ : Nat),
      F ≤ b₁ → F ≤ b₂ → F ≤ b₃ → F ≤ b₄ →
    ∀ (m : ndM A I E C S) (f : A → ndM B I E C S)
      (g : B → ndM G I E C S) (σ : S),
      CerbND.runNDFuel F (nd_bind_lemFuel b₁ (nd_bind_lemFuel b₂ m f) g) σ
        = CerbND.runNDFuel F
            (nd_bind_lemFuel b₃ m (fun x => nd_bind_lemFuel b₄ (f x) g)) σ := by
  intro F
  induction F with
  | zero =>
    intro b₁ b₂ b₃ b₄ _ _ _ _ m f g σ
    rw [runNDFuel_zero, runNDFuel_zero]
  | succ F ih =>
    intro b₁ b₂ b₃ b₄ h₁ h₂ h₃ h₄ m f g σ
    cases b₁ with
    | zero => exact absurd h₁ (by omega)
    | succ b₁ =>
      cases b₂ with
      | zero => exact absurd h₂ (by omega)
      | succ b₂ =>
        cases b₃ with
        | zero => exact absurd h₃ (by omega)
        | succ b₃ =>
          have hF₁ : F ≤ b₁ := Nat.le_of_succ_le_succ h₁
          have hF₂ : F ≤ b₂ := Nat.le_of_succ_le_succ h₂
          have hF₃ : F ≤ b₃ := Nat.le_of_succ_le_succ h₃
          have hF₄ : F ≤ b₄ := Nat.le_trans (Nat.le_succ F) h₄
          cases m with
          | ND gm =>
            rcases happ : gm σ with ⟨act, st1⟩
            have happ' : app (ND gm) σ = (act, st1) := happ
            cases act with
            | NDactive v =>
              -- collapse both sides onto `bind (f v) g` at st1 (wrap
              -- fuels differ; bridged by the invariance lemma)
              have hL : CerbND.runNDFuel (F + 1)
                    (nd_bind_lemFuel (b₁ + 1)
                      (nd_bind_lemFuel (b₂ + 1) (ND gm) f) g) σ
                  = CerbND.runNDFuel (F + 1)
                      (nd_bind_lemFuel (b₁ + 1) (f v) g) st1 :=
                runNDFuel_succ_congr F
                  (app_bindFuel_congr b₁ (app_bindFuel_active b₂ happ') g)
              have hR : CerbND.runNDFuel (F + 1)
                    (nd_bind_lemFuel (b₃ + 1) (ND gm)
                      (fun x => nd_bind_lemFuel b₄ (f x) g)) σ
                  = CerbND.runNDFuel (F + 1)
                      (nd_bind_lemFuel b₄ (f v) g) st1 :=
                runNDFuel_bindFuel_active b₃ happ' (F + 1)
              rw [hL, hR]
              exact runNDFuel_bind_fuel_irrel (F + 1) (b₁ + 1) b₄
                h₁ h₄ (f v) g st1
            | NDkilled r =>
              rw [runNDFuel_killed F
                  (app_bindFuel_killed b₁ (app_bindFuel_killed b₂ happ')),
                runNDFuel_killed F (app_bindFuel_killed b₃ happ')]
            | NDnd i br =>
              rw [runNDFuel_nd F
                  (app_bindFuel_nd b₁ (app_bindFuel_nd b₂ happ')),
                runNDFuel_nd F (app_bindFuel_nd b₃ happ'),
                List.foldl_map, List.foldl_map, List.foldl_map]
              exact foldl_prepend_congr br
                (fun p _ => ih b₁ b₂ b₃ b₄ hF₁ hF₂ hF₃ hF₄ p.2 f g st1) []
            | NDstep i br =>
              rw [runNDFuel_step F
                  (app_bindFuel_step b₁ (app_bindFuel_step b₂ happ')),
                runNDFuel_step F (app_bindFuel_step b₃ happ'),
                List.foldl_map, List.foldl_map, List.foldl_map]
              exact foldl_prepend_congr br
                (fun p _ => ih b₁ b₂ b₃ b₄ hF₁ hF₂ hF₃ hF₄ p.2 f g st1) []
            | NDguard i c mk =>
              rw [runNDFuel_guard F
                  (app_bindFuel_guard b₁ (app_bindFuel_guard b₂ happ')),
                runNDFuel_guard F (app_bindFuel_guard b₃ happ')]
              exact ih b₁ b₂ b₃ b₄ hF₁ hF₂ hF₃ hF₄ mk f g st1
            | NDbranch i c l r =>
              rw [runNDFuel_branch F
                  (app_bindFuel_branch b₁ (app_bindFuel_branch b₂ happ')),
                runNDFuel_branch F (app_bindFuel_branch b₃ happ')]
              rw [ih b₁ b₂ b₃ b₄ hF₁ hF₂ hF₃ hF₄ l f g st1,
                ih b₁ b₂ b₃ b₄ hF₁ hF₂ hF₃ hF₄ r f g st1]

/-! ## Default-fuel spellings (what the peel walks actually write:
    every bind in the generated code and in `KExpr.denote` is the
    default-fuel `nd_bind`) -/

/-- The default budget in successor form (kernel literal arithmetic;
    the arc-3 wrapper-defeq move). -/
theorem lemDefaultFuel_succ : lemDefaultFuel = 999999 + 1 := rfl

/-- Re-association at the generated `nd_bind`. -/
theorem runNDFuel_bind_assoc' {F : Nat} (hF : F ≤ lemDefaultFuel)
    (m : ndM A I E C S) (f : A → ndM B I E C S) (g : B → ndM G I E C S)
    (σ : S) :
    CerbND.runNDFuel F (nd_bind (nd_bind m f) g) σ
      = CerbND.runNDFuel F (nd_bind m (fun x => nd_bind (f x) g)) σ :=
  runNDFuel_bind_assoc F lemDefaultFuel lemDefaultFuel lemDefaultFuel
    lemDefaultFuel hF hF hF hF m f g σ

/-- Continuation congruence at the generated `nd_bind`. -/
theorem runNDFuel_bind_congr' {F : Nat} (hF : F ≤ lemDefaultFuel)
    {m : ndM A I E C S} {f g : A → ndM B I E C S}
    (hcont : ∀ (v : A) (σ₁ : S) (F' : Nat), F' ≤ F →
      CerbND.runNDFuel F' (f v) σ₁ = CerbND.runNDFuel F' (g v) σ₁)
    (σ : S) :
    CerbND.runNDFuel F (nd_bind m f) σ
      = CerbND.runNDFuel F (nd_bind m g) σ :=
  runNDFuel_bind_congr F lemDefaultFuel lemDefaultFuel hF hF hcont σ

end RunnerAlgebra

end RelSem
