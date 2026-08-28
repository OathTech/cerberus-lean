/-
  RelSem.PerStepObs — V2 (2026-08-28): THE OBSERVATION ALGEBRA of the
  fuel'd bind — the two composition principles the loop PEEL
  (RelSem/PerStepPeel.lean) runs on:

  * `runNDFuel_bind_congr` — the runner cannot distinguish binds whose
    continuations enumerate identically (pointwise, at every fuel
    within budget);
  * `runNDFuel_bind_assoc` — bind REASSOCIATION is invisible to the
    runner within the fuel budget. Fuel'd `nd_bind` is NOT associative
    as values (the arc-16 S1 measurement: wrap-fuel misaligns at depth
    ~10^6, PerStep.lean header) — but the runner's observation is
    fuel-robust (`runNDFuel_bind_fuel_irrel`), and at the observation
    level associativity holds. This is the load-bearing fact behind
    reifying the generated tail-recursive loops as per-round `KExpr`
    joints (big-step ↔ small-step simulation; the arc-16 S1 record §5
    design, executed at V2).

  Lineage (canon-first): monadic-bind associativity up to observation —
  the interaction-tree `eutt` congruence/assoc laws are the exact
  analogue (bind-assoc holds up to `eutt`, not up to `Eq`, once fuel/
  tau bookkeeping enters); proof style: the `runNDFuel_bind_fuel_irrel`
  induction (RelSem/PerStep.lean), reused shape for shape.

  House rules: no sorry, no axioms declared. Under the in-build audit.
-/

import RelSem.PerStep

set_option autoImplicit false

namespace RelSem

section ObsAlgebra
variable {A B D I E C S : Type}

/-- BIND CONGRUENCE AT THE OBSERVATION: continuations that enumerate
    identically (pointwise, at every fuel ≤ the runner's) give
    identical enumerations under bind — at possibly different wrap
    fuels (≥ the runner's). -/
theorem runNDFuel_bind_congr :
    ∀ (F : Nat) {b b' : Nat}, F ≤ b → F ≤ b' →
    ∀ (m : ndM A I E C S) (f g : A → ndM B I E C S) (σ : S),
    (∀ (F' : Nat), F' ≤ F → ∀ (v : A) (σ' : S),
      CerbND.runNDFuel F' (f v) σ' = CerbND.runNDFuel F' (g v) σ') →
    CerbND.runNDFuel F (nd_bind_lemFuel b m f) σ
      = CerbND.runNDFuel F (nd_bind_lemFuel b' m g) σ := by
  intro F
  induction F with
  | zero => intro b b' _ _ m f g σ _; rfl
  | succ F ih =>
    intro b b' hb hb' m f g σ hfg
    cases b with
    | zero => exact absurd hb (by omega)
    | succ b =>
      cases b' with
      | zero => exact absurd hb' (by omega)
      | succ b' =>
        have hFb : F ≤ b := by omega
        have hFb' : F ≤ b' := by omega
        cases m with
        | ND gm =>
          rcases happ : gm σ with ⟨act, σ₁⟩
          have happ' : app (ND gm) σ = (act, σ₁) := happ
          cases act with
          | NDactive v =>
            rw [runNDFuel_succ_congr F (app_bindFuel_active b happ'),
              runNDFuel_succ_congr F (app_bindFuel_active b' happ')]
            exact hfg (F + 1) (Nat.le_refl _) v σ₁
          | NDkilled r =>
            rw [runNDFuel_killed F (app_bindFuel_killed b happ'),
              runNDFuel_killed F (app_bindFuel_killed b' happ')]
          | NDnd i br =>
            rw [runNDFuel_nd F (app_bindFuel_nd b happ'),
              runNDFuel_nd F (app_bindFuel_nd b' happ'),
              List.foldl_map, List.foldl_map]
            exact foldl_prepend_congr br
              (fun p _ => ih hFb hFb' p.2 f g σ₁
                (fun F' hF' v σ' => hfg F' (Nat.le_succ_of_le hF') v σ'))
              []
          | NDstep i br =>
            rw [runNDFuel_step F (app_bindFuel_step b happ'),
              runNDFuel_step F (app_bindFuel_step b' happ'),
              List.foldl_map, List.foldl_map]
            exact foldl_prepend_congr br
              (fun p _ => ih hFb hFb' p.2 f g σ₁
                (fun F' hF' v σ' => hfg F' (Nat.le_succ_of_le hF') v σ'))
              []
          | NDguard i c mk =>
            rw [runNDFuel_guard F (app_bindFuel_guard b happ'),
              runNDFuel_guard F (app_bindFuel_guard b' happ')]
            exact ih hFb hFb' mk f g σ₁
              (fun F' hF' v σ' => hfg F' (Nat.le_succ_of_le hF') v σ')
          | NDbranch i c l r =>
            rw [runNDFuel_branch F (app_bindFuel_branch b happ'),
              runNDFuel_branch F (app_bindFuel_branch b' happ'),
              ih hFb hFb' l f g σ₁
                (fun F' hF' v σ' => hfg F' (Nat.le_succ_of_le hF') v σ'),
              ih hFb hFb' r f g σ₁
                (fun F' hF' v σ' => hfg F' (Nat.le_succ_of_le hF') v σ')]

/-- BIND ASSOCIATIVITY AT THE OBSERVATION: within the fuel budget the
    runner cannot see reassociation (all four wrap fuels independent,
    each ≥ the runner's). -/
theorem runNDFuel_bind_assoc :
    ∀ (F : Nat) {b₁ b₂ b₃ b₄ : Nat},
    F ≤ b₁ → F ≤ b₂ → F ≤ b₃ → F ≤ b₄ →
    ∀ (m : ndM A I E C S) (f : A → ndM B I E C S)
      (g : B → ndM D I E C S) (σ : S),
    CerbND.runNDFuel F
        (nd_bind_lemFuel b₁ (nd_bind_lemFuel b₂ m f) g) σ
      = CerbND.runNDFuel F
          (nd_bind_lemFuel b₃ m (fun x => nd_bind_lemFuel b₄ (f x) g))
          σ := by
  intro F
  induction F with
  | zero => intro b₁ b₂ b₃ b₄ _ _ _ _ m f g σ; rfl
  | succ F ih =>
    intro b₁ b₂ b₃ b₄ hb₁ hb₂ hb₃ hb₄ m f g σ
    cases b₁ with
    | zero => exact absurd hb₁ (by omega)
    | succ b₁ =>
    cases b₂ with
    | zero => exact absurd hb₂ (by omega)
    | succ b₂ =>
    cases b₃ with
    | zero => exact absurd hb₃ (by omega)
    | succ b₃ =>
      cases m with
      | ND gm =>
        rcases happ : gm σ with ⟨act, σ₁⟩
        have happ' : app (ND gm) σ = (act, σ₁) := happ
        cases act with
        | NDactive v =>
          -- both sides collapse into `f v` at σ₁; then dispatch on ITS
          -- head observation
          have hL : app (nd_bind_lemFuel (b₂ + 1) (ND gm) f) σ
              = app (f v) σ₁ := app_bindFuel_active b₂ happ'
          have hR : app (nd_bind_lemFuel (b₃ + 1) (ND gm)
                (fun x => nd_bind_lemFuel b₄ (f x) g)) σ
              = app (nd_bind_lemFuel b₄ (f v) g) σ₁ :=
            app_bindFuel_active b₃ happ'
          rcases happf : app (f v) σ₁ with ⟨actf, σ₂⟩
          cases b₄ with
          | zero => exact absurd hb₄ (by omega)
          | succ b₄ =>
            cases actf with
            | NDactive w =>
              rw [runNDFuel_succ_congr F
                  (app_bindFuel_active b₁ (hL.trans happf)),
                runNDFuel_succ_congr F
                  (hR.trans (app_bindFuel_active b₄ happf))]
            | NDkilled r =>
              rw [runNDFuel_killed F
                  (app_bindFuel_killed b₁ (hL.trans happf)),
                runNDFuel_killed F
                  (hR.trans (app_bindFuel_killed b₄ happf))]
            | NDnd i br =>
              rw [runNDFuel_nd F
                  (app_bindFuel_nd b₁ (hL.trans happf)),
                runNDFuel_nd F (hR.trans (app_bindFuel_nd b₄ happf)),
                List.foldl_map, List.foldl_map]
              exact foldl_prepend_congr br
                (fun p _ => runNDFuel_bind_fuel_irrel F b₁ b₄
                  (by omega) (by omega) p.2 g σ₂) []
            | NDstep i br =>
              rw [runNDFuel_step F
                  (app_bindFuel_step b₁ (hL.trans happf)),
                runNDFuel_step F (hR.trans (app_bindFuel_step b₄ happf)),
                List.foldl_map, List.foldl_map]
              exact foldl_prepend_congr br
                (fun p _ => runNDFuel_bind_fuel_irrel F b₁ b₄
                  (by omega) (by omega) p.2 g σ₂) []
            | NDguard i c mk =>
              rw [runNDFuel_guard F
                  (app_bindFuel_guard b₁ (hL.trans happf)),
                runNDFuel_guard F
                  (hR.trans (app_bindFuel_guard b₄ happf))]
              exact runNDFuel_bind_fuel_irrel F b₁ b₄
                (by omega) (by omega) mk g σ₂
            | NDbranch i c l r =>
              rw [runNDFuel_branch F
                  (app_bindFuel_branch b₁ (hL.trans happf)),
                runNDFuel_branch F
                  (hR.trans (app_bindFuel_branch b₄ happf)),
                runNDFuel_bind_fuel_irrel F b₁ b₄
                  (by omega) (by omega) l g σ₂,
                runNDFuel_bind_fuel_irrel F b₁ b₄
                  (by omega) (by omega) r g σ₂]
        | NDkilled r =>
          rw [runNDFuel_killed F
              (app_bindFuel_killed b₁ (app_bindFuel_killed b₂ happ')),
            runNDFuel_killed F (app_bindFuel_killed b₃ happ')]
        | NDnd i br =>
          rw [runNDFuel_nd F
              (app_bindFuel_nd b₁ (app_bindFuel_nd b₂ happ')),
            runNDFuel_nd F (app_bindFuel_nd b₃ happ'),
            List.foldl_map, List.foldl_map, List.foldl_map]
          refine foldl_prepend_congr br (fun p _ => ?_) []
          exact ih (by omega) (by omega) (by omega) (by omega) p.2 f g σ₁
        | NDstep i br =>
          rw [runNDFuel_step F
              (app_bindFuel_step b₁ (app_bindFuel_step b₂ happ')),
            runNDFuel_step F (app_bindFuel_step b₃ happ'),
            List.foldl_map, List.foldl_map, List.foldl_map]
          refine foldl_prepend_congr br (fun p _ => ?_) []
          exact ih (by omega) (by omega) (by omega) (by omega) p.2 f g σ₁
        | NDguard i c mk =>
          rw [runNDFuel_guard F
              (app_bindFuel_guard b₁ (app_bindFuel_guard b₂ happ')),
            runNDFuel_guard F (app_bindFuel_guard b₃ happ')]
          exact ih (by omega) (by omega) (by omega) (by omega) mk f g σ₁
        | NDbranch i c l r =>
          rw [runNDFuel_branch F
              (app_bindFuel_branch b₁ (app_bindFuel_branch b₂ happ')),
            runNDFuel_branch F (app_bindFuel_branch b₃ happ'),
            ih (b₁ := b₁) (b₂ := b₂) (b₃ := b₃) (b₄ := b₄)
              (by omega) (by omega) (by omega) (by omega) l f g σ₁,
            ih (b₁ := b₁) (b₂ := b₂) (b₃ := b₃) (b₄ := b₄)
              (by omega) (by omega) (by omega) (by omega) r f g σ₁]

end ObsAlgebra

end RelSem
