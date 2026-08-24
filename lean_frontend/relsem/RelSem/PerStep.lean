/-
  RelSem.PerStep — arc-16 S1 (2026-08-24): THE PER-STEP LANGUAGE.

  Continuation-reified sequencing over the generated ND monad: an
  expression records the program's bind JOINTS, so the step relation
  can stop where `app` (the one-node tree unfolding) computes through.
  This is the language layer of the Iris refounding — it replaces the
  whole-run-atomic granularity of the arc-7 shell (RelSem/IrisLang.lean
  wraps ONE `Machine.Step`, and bind-collapse makes a deterministic run
  ONE node) with genuine per-step structure at the sequencing joints.

  Design record: docs/2026-08-24_arc16-s1-language-instance.md.
  Lineage (canon-first): reified monadic syntax with semantic atoms —
  the free-monad / interaction-tree program-logic pattern; the atoms
  are the GENERATED computations themselves (never re-axiomatized),
  and every step premise is an equation about the generated `app`.

  Layer discipline: NO Iris imports here (mirrors RelSem/Machine.lean);
  the Iris coupling lives in RelSem/PerStepIris.lean.

  Fuel doctrine (measured, recorded in the S1 record §1):
  * fuel'd `nd_bind` is NOT associative as values (wrap-fuel misaligns
    at depth ~10^6), so everything here composes at the app/runner
    OBSERVATION level, where one collapse step is fuel-free
    (`runNDFuel_succ_congr`);
  * bind-fuel and runner-fuel decrement in lockstep (one node level
    each) and `CerbND.ndDefaultFuel = lemDefaultFuel`, so the
    invariance lemma `runNDFuel_bind_fuel_irrel` (F ≤ b) covers the
    production budget exactly.

  House rules: no sorry, no axioms declared. Under the in-build audit.
-/

import Nondeterminism
import CerbND
import RelSem.Machine
import RelSem.RunND

set_option autoImplicit false

namespace RelSem

/-! ## Expressions: reified sequencing with semantic atoms -/

section KExpr
universe u

/-- A per-step expression: a terminal outcome, or a leading ATOM (any
    generated ND computation, at any intermediate result type) followed
    by a continuation. `Type 1` is forced by the `{α : Type}` field;
    probe-verified against the pinned iris-lean (its Language/WP/OwnP
    chain is universe-polymorphic). -/
inductive KExpr (A I E C S : Type) : Type 1 where
  | done : Outcome A E → KExpr A I E C S
  | seq  : {α : Type} → ndM α I E C S → (α → KExpr A I E C S) →
      KExpr A I E C S

variable {A I E C S : Type}

/-- Denotation into the generated monad: the program an expression
    stands for. `seq` denotes the generated `nd_bind` (default fuel) —
    the reification adds joints, never semantics. -/
def KExpr.denote : KExpr A I E C S → ndM A I E C S
  | .done (.value v)  => nd_return v
  | .done (.killed r) => kill r
  | .seq m k => nd_bind m (fun v => (k v).denote)

/-- Value projection (the iris-lean `ToVal.toVal` carrier): exactly the
    `done` expressions are values. As in arc-7, a `killed` outcome (UB
    included) is a VALUE of the machine — specs exclude UB explicitly,
    never via stuckness. -/
def KExpr.toVal : KExpr A I E C S → Option (Outcome A E)
  | .done o => some o
  | .seq _ _ => none

def KExpr.ofVal (o : Outcome A E) : KExpr A I E C S := .done o

theorem KExpr.toVal_ofVal (o : Outcome A E) :
    (KExpr.ofVal o : KExpr A I E C S).toVal = some o := rfl

theorem KExpr.ofVal_toVal {e : KExpr A I E C S} {o : Outcome A E}
    (h : e.toVal = some o) : KExpr.ofVal o = e := by
  cases e with
  | done o' => cases h; rfl
  | seq m k => cases h

/-- Per-step configuration: expression + monad state (the same state
    the fuel opsem steps over). -/
structure KConfig (A I E C S : Type) : Type 1 where
  expr : KExpr A I E C S
  st   : S

/-! ## The step relation — defined from the generated `app` -/

/-- One step: dispatch on the leading atom's ONE `app` unfolding
    (`app` = RelSem/Machine.lean:95, the only way the relational layer
    consumes the generated code). Seven arms, mirror of `Machine.Step`'s
    dispatch re-hosted on expressions with joints; `CsSem`-parametric
    exactly as there (constraint disciplines / future cmm schedule
    disciplines slot in without reshaping the relation). Allocator,
    scheduler and constraint nondeterminism enter at the
    `nd`/`step`/`guard`/`branch` arms — per-step, deterministic per
    resolved choice. -/
inductive KStep (γ : CsSem C S) :
    KConfig A I E C S → KConfig A I E C S → Prop where
  | seq_active {α : Type} {m : ndM α I E C S} {k : α → KExpr A I E C S}
      {st st' : S} {v : α} :
      app m st = (NDactive v, st') →
      KStep γ ⟨.seq m k, st⟩ ⟨k v, st'⟩
  | seq_killed {α : Type} {m : ndM α I E C S} {k : α → KExpr A I E C S}
      {st st' : S} {r : kill_reason E} :
      app m st = (NDkilled r, st') →
      KStep γ ⟨.seq m k, st⟩ ⟨.done (.killed r), st'⟩
  | seq_nd {α : Type} {m : ndM α I E C S} {k : α → KExpr A I E C S}
      {st st' : S} {i j : I} {br : List (I × ndM α I E C S)}
      {m' : ndM α I E C S} :
      app m st = (NDnd i br, st') → (j, m') ∈ br →
      KStep γ ⟨.seq m k, st⟩ ⟨.seq m' k, st'⟩
  | seq_step {α : Type} {m : ndM α I E C S} {k : α → KExpr A I E C S}
      {st st' : S} {i j : I} {br : List (I × ndM α I E C S)}
      {m' : ndM α I E C S} :
      app m st = (NDstep i br, st') → (j, m') ∈ br →
      KStep γ ⟨.seq m k, st⟩ ⟨.seq m' k, st'⟩
  | seq_guard {α : Type} {m : ndM α I E C S} {k : α → KExpr A I E C S}
      {st st' : S} {i : I} {c : C} {mk : ndM α I E C S} :
      app m st = (NDguard i c mk, st') → γ.sat c st' →
      KStep γ ⟨.seq m k, st⟩ ⟨.seq mk k, st'⟩
  | seq_branchL {α : Type} {m : ndM α I E C S} {k : α → KExpr A I E C S}
      {st st' : S} {i : I} {c : C} {l r : ndM α I E C S} :
      app m st = (NDbranch i c l r, st') → γ.sat c st' →
      KStep γ ⟨.seq m k, st⟩ ⟨.seq l k, st'⟩
  | seq_branchR {α : Type} {m : ndM α I E C S} {k : α → KExpr A I E C S}
      {st st' : S} {i : I} {c : C} {l r : ndM α I E C S} :
      app m st = (NDbranch i c l r, st') → γ.nsat c st' →
      KStep γ ⟨.seq m k, st⟩ ⟨.seq r k, st'⟩

/-- Reflexive-transitive closure (mirror of `Machine.Steps`). -/
inductive KSteps (γ : CsSem C S) :
    KConfig A I E C S → KConfig A I E C S → Prop where
  | refl {c : KConfig A I E C S} : KSteps γ c c
  | tail {a b c : KConfig A I E C S} :
      KSteps γ a b → KStep γ b c → KSteps γ a c

theorem KSteps.single {γ : CsSem C S} {a b : KConfig A I E C S}
    (h : KStep γ a b) : KSteps γ a b := .tail .refl h

theorem KSteps.trans {γ : CsSem C S} {a b c : KConfig A I E C S}
    (h₁ : KSteps γ a b) (h₂ : KSteps γ b c) : KSteps γ a c := by
  induction h₂ with
  | refl => exact h₁
  | tail _ hs ih => exact .tail ih hs

theorem KSteps.head {γ : CsSem C S} {a b c : KConfig A I E C S}
    (h : KStep γ a b) (hs : KSteps γ b c) : KSteps γ a c :=
  (KSteps.single h).trans hs

/-! ## Value soundness -/

/-- iris-lean `Language.val_stuck`, locally: only `seq` configurations
    step. -/
theorem kval_stuck {γ : CsSem C S} {c c' : KConfig A I E C S}
    (h : KStep γ c c') : c.expr.toVal = none := by
  cases h <;> rfl

/-- `done` configurations are terminal. -/
theorem kdone_irreducible {γ : CsSem C S} {o : Outcome A E} {st : S}
    {c' : KConfig A I E C S} : ¬ KStep γ ⟨.done o, st⟩ c' := by
  intro h; cases h

/-! ## Terminal-head determinism (the lifting rules' inversion
    premises; mirror of `step_running_active_inv`) -/

/-- Active head ⇒ the only step out of `seq m k` is to `⟨k v, st'⟩`. -/
theorem kstep_seq_active_inv {γ : CsSem C S} {α : Type}
    {m : ndM α I E C S} {k : α → KExpr A I E C S} {st st' : S} {v : α}
    {c' : KConfig A I E C S}
    (h : app m st = (NDactive v, st'))
    (hs : KStep γ ⟨.seq m k, st⟩ c') : c' = ⟨k v, st'⟩ := by
  cases hs with
  | seq_active happ =>
    rw [h] at happ
    injection happ with h1 h2
    injection h1 with h1
    subst h1; subst h2; rfl
  | seq_killed happ => rw [h] at happ; injection happ with h1 _; injection h1
  | seq_nd happ _ => rw [h] at happ; injection happ with h1 _; injection h1
  | seq_step happ _ => rw [h] at happ; injection happ with h1 _; injection h1
  | seq_guard happ _ => rw [h] at happ; injection happ with h1 _; injection h1
  | seq_branchL happ _ =>
    rw [h] at happ; injection happ with h1 _; injection h1
  | seq_branchR happ _ =>
    rw [h] at happ; injection happ with h1 _; injection h1

/-- Killed head ⇒ the only step is to the killed value. -/
theorem kstep_seq_killed_inv {γ : CsSem C S} {α : Type}
    {m : ndM α I E C S} {k : α → KExpr A I E C S} {st st' : S}
    {r : kill_reason E} {c' : KConfig A I E C S}
    (h : app m st = (NDkilled r, st'))
    (hs : KStep γ ⟨.seq m k, st⟩ c') : c' = ⟨.done (.killed r), st'⟩ := by
  cases hs with
  | seq_active happ => rw [h] at happ; injection happ with h1 _; injection h1
  | seq_killed happ =>
    rw [h] at happ
    injection happ with h1 h2
    injection h1 with h1
    subst h1; subst h2; rfl
  | seq_nd happ _ => rw [h] at happ; injection happ with h1 _; injection h1
  | seq_step happ _ => rw [h] at happ; injection happ with h1 _; injection h1
  | seq_guard happ _ => rw [h] at happ; injection happ with h1 _; injection h1
  | seq_branchL happ _ =>
    rw [h] at happ; injection happ with h1 _; injection h1
  | seq_branchR happ _ =>
    rw [h] at happ; injection happ with h1 _; injection h1

end KExpr

/-! ## The app-equation layer, node arms (extends the arc-7 layer:
    `app_bindFuel_active`/`_killed` live in RelSem/Machine.lean; the
    four node arms are stated here because the per-step completeness
    is their first consumer). Each computes `nd_bind`'s wrap of a node
    head — note the branches are re-wrapped at the DECREMENTED bind
    fuel (the source of the invariance obligation below). -/

section AppBindNodes
variable {A B I E C S : Type}

theorem app_bindFuel_nd (fuel : Nat) {m : ndM A I E C S}
    {f : A → ndM B I E C S} {st st' : S} {i : I}
    {br : List (I × ndM A I E C S)}
    (h : app m st = (NDnd i br, st')) :
    app (nd_bind_lemFuel (fuel + 1) m f) st
      = (NDnd i (br.map (fun p => (p.1, nd_bind_lemFuel fuel p.2 f))),
         st') := by
  cases m with
  | ND g =>
    have hg : g st = (NDnd i br, st') := h
    simp only [nd_bind_lemFuel, app, hg]

theorem app_bindFuel_step (fuel : Nat) {m : ndM A I E C S}
    {f : A → ndM B I E C S} {st st' : S} {i : I}
    {br : List (I × ndM A I E C S)}
    (h : app m st = (NDstep i br, st')) :
    app (nd_bind_lemFuel (fuel + 1) m f) st
      = (NDstep i (br.map (fun p => (p.1, nd_bind_lemFuel fuel p.2 f))),
         st') := by
  cases m with
  | ND g =>
    have hg : g st = (NDstep i br, st') := h
    simp only [nd_bind_lemFuel, app, hg]

theorem app_bindFuel_guard (fuel : Nat) {m : ndM A I E C S}
    {f : A → ndM B I E C S} {st st' : S} {i : I} {c : C}
    {mk : ndM A I E C S}
    (h : app m st = (NDguard i c mk, st')) :
    app (nd_bind_lemFuel (fuel + 1) m f) st
      = (NDguard i c (nd_bind_lemFuel fuel mk f), st') := by
  cases m with
  | ND g =>
    have hg : g st = (NDguard i c mk, st') := h
    simp only [nd_bind_lemFuel, app, hg]

theorem app_bindFuel_branch (fuel : Nat) {m : ndM A I E C S}
    {f : A → ndM B I E C S} {st st' : S} {i : I} {c : C}
    {l r : ndM A I E C S}
    (h : app m st = (NDbranch i c l r, st')) :
    app (nd_bind_lemFuel (fuel + 1) m f) st
      = (NDbranch i c (nd_bind_lemFuel fuel l f)
          (nd_bind_lemFuel fuel r f), st') := by
  cases m with
  | ND g =>
    have hg : g st = (NDbranch i c l r, st') := h
    simp only [nd_bind_lemFuel, app, hg]

end AppBindNodes

/-! ## Runner dispatch lemmas (extend RunND.lean's
    `runNDFuel_active`/`_killed` with the congruence and node arms) -/

section RunnerDispatch
variable {A I E C S : Type}

/-- Equal one-node observations give equal enumerations: the runner's
    positive-fuel dispatch is a function of `app`'s result alone. This
    is the composition principle that survives the fuel'd-bind
    associativity failure (S1 record §1). -/
theorem runNDFuel_succ_congr (fuel : Nat) {m m' : ndM A I E C S}
    {st st' : S} (h : app m st = app m' st') :
    CerbND.runNDFuel (fuel + 1) m st = CerbND.runNDFuel (fuel + 1) m' st' := by
  cases m with
  | ND g =>
    cases m' with
    | ND g' =>
      have hg : g st = g' st' := h
      simp only [CerbND.runNDFuel, hg]

theorem runNDFuel_nd (fuel : Nat) {m : ndM A I E C S} {st st' : S}
    {i : I} {br : List (I × ndM A I E C S)}
    (h : app m st = (NDnd i br, st')) :
    CerbND.runNDFuel (fuel + 1) m st
      = br.foldl (fun acc p => CerbND.runNDFuel fuel p.2 st' ++ acc) [] := by
  cases m with
  | ND g =>
    have hg : g st = (NDnd i br, st') := h
    simp only [CerbND.runNDFuel, hg]

theorem runNDFuel_step (fuel : Nat) {m : ndM A I E C S} {st st' : S}
    {i : I} {br : List (I × ndM A I E C S)}
    (h : app m st = (NDstep i br, st')) :
    CerbND.runNDFuel (fuel + 1) m st
      = br.foldl (fun acc p => CerbND.runNDFuel fuel p.2 st' ++ acc) [] := by
  cases m with
  | ND g =>
    have hg : g st = (NDstep i br, st') := h
    simp only [CerbND.runNDFuel, hg]

theorem runNDFuel_guard (fuel : Nat) {m : ndM A I E C S} {st st' : S}
    {i : I} {c : C} {mk : ndM A I E C S}
    (h : app m st = (NDguard i c mk, st')) :
    CerbND.runNDFuel (fuel + 1) m st = CerbND.runNDFuel fuel mk st' := by
  cases m with
  | ND g =>
    have hg : g st = (NDguard i c mk, st') := h
    simp only [CerbND.runNDFuel, hg]

theorem runNDFuel_branch (fuel : Nat) {m : ndM A I E C S} {st st' : S}
    {i : I} {c : C} {l r : ndM A I E C S}
    (h : app m st = (NDbranch i c l r, st')) :
    CerbND.runNDFuel (fuel + 1) m st
      = CerbND.runNDFuel fuel l st' ++ CerbND.runNDFuel fuel r st' := by
  cases m with
  | ND g =>
    have hg : g st = (NDbranch i c l r, st') := h
    simp only [CerbND.runNDFuel, hg]

/-- Prepend-accumulation fold congruence (pointwise-equal branch
    enumerations give equal folds). -/
theorem foldl_prepend_congr {α β : Type} {g g' : β → List α}
    (l : List β) (hp : ∀ b ∈ l, g b = g' b) :
    ∀ acc : List α,
      l.foldl (fun acc b => g b ++ acc) acc
        = l.foldl (fun acc b => g' b ++ acc) acc := by
  induction l with
  | nil => intro acc; rfl
  | cons hd tl ih =>
    intro acc
    rw [List.foldl_cons, List.foldl_cons,
      hp hd (List.mem_cons_self ..),
      ih (fun b hb => hp b (List.mem_cons_of_mem hd hb))]

end RunnerDispatch

/-! ## Bind-fuel invariance: the runner at fuel F cannot observe
    wrap-fuel it cannot reach (F ≤ b). Bind-fuel and runner-fuel
    decrement in lockstep (one node level each), so the hypothesis is
    maintained exactly; at the production budget
    (`ndDefaultFuel = lemDefaultFuel`) the alignment is tight at every
    level. -/

section BindFuelIrrel
variable {A B I E C S : Type}

theorem runNDFuel_bind_fuel_irrel :
    ∀ (F b b' : Nat), F ≤ b → F ≤ b' →
    ∀ (m : ndM A I E C S) (f : A → ndM B I E C S) (σ : S),
      CerbND.runNDFuel F (nd_bind_lemFuel b m f) σ
        = CerbND.runNDFuel F (nd_bind_lemFuel b' m f) σ := by
  intro F
  induction F with
  | zero => intro b b' _ _ m f σ; rfl
  | succ F ih =>
    intro b b' hb hb' m f σ
    cases b with
    | zero => exact absurd hb (by omega)
    | succ b =>
      cases b' with
      | zero => exact absurd hb' (by omega)
      | succ b' =>
        have hFb : F ≤ b := Nat.le_of_succ_le_succ hb
        have hFb' : F ≤ b' := Nat.le_of_succ_le_succ hb'
        cases m with
        | ND g =>
          rcases happ : g σ with ⟨act, st1⟩
          have happ' : app (ND g) σ = (act, st1) := happ
          cases act with
          | NDactive v =>
            exact runNDFuel_succ_congr F
              ((app_bindFuel_active b happ').trans
                (app_bindFuel_active b' happ').symm)
          | NDkilled r =>
            rw [runNDFuel_killed F (app_bindFuel_killed b happ'),
              runNDFuel_killed F (app_bindFuel_killed b' happ')]
          | NDnd i br =>
            rw [runNDFuel_nd F (app_bindFuel_nd b happ'),
              runNDFuel_nd F (app_bindFuel_nd b' happ'),
              List.foldl_map, List.foldl_map]
            exact foldl_prepend_congr br
              (fun p _ => ih b b' hFb hFb' p.2 f st1) []
          | NDstep i br =>
            rw [runNDFuel_step F (app_bindFuel_step b happ'),
              runNDFuel_step F (app_bindFuel_step b' happ'),
              List.foldl_map, List.foldl_map]
            exact foldl_prepend_congr br
              (fun p _ => ih b b' hFb hFb' p.2 f st1) []
          | NDguard i c mk =>
            rw [runNDFuel_guard F (app_bindFuel_guard b happ'),
              runNDFuel_guard F (app_bindFuel_guard b' happ')]
            exact ih b b' hFb hFb' mk f st1
          | NDbranch i c l r =>
            rw [runNDFuel_branch F (app_bindFuel_branch b happ'),
              runNDFuel_branch F (app_bindFuel_branch b' happ')]
            rw [ih b b' hFb hFb' l f st1, ih b b' hFb hFb' r f st1]

end BindFuelIrrel

/-! ## STEPS-OF-FUEL (completeness): within the production budget,
    every triple the fuel-totalized worker enumerates for `denote e`
    is the endpoint of a `KSteps` trace from `⟨e, σ⟩` under the
    exhaustive discipline. This is the adequacy bridge's load-bearing
    leg (consumed by RelSem/PerStepIris.lean); the `F ≤ lemDefaultFuel`
    envelope is exactly the production runner's
    (`CerbND.ndDefaultFuel = lemDefaultFuel`, CerbND.lean:71). -/

section Completeness
variable {A I E C S : Type}

private theorem denote_seq_eq {α : Type} (m : ndM α I E C S)
    (k : α → KExpr A I E C S) :
    (KExpr.seq m k).denote
      = nd_bind_lemFuel lemDefaultFuel m (fun v => (k v).denote) := rfl

theorem ksteps_of_runNDFuel :
    ∀ (F : Nat), F ≤ lemDefaultFuel →
    ∀ (e : KExpr A I E C S) (σ : S) (out : nd_status A E S)
      (tr : List String) (σ' : S),
      (out, tr, σ') ∈ CerbND.runNDFuel F e.denote σ →
      KSteps (CsSem.exhaustive C S) ⟨e, σ⟩
        ⟨.done (Outcome.ofStatus out), σ'⟩ := by
  intro F
  induction F with
  | zero =>
    intro _ e σ out tr σ' h
    rw [runNDFuel_zero] at h
    cases h
  | succ F ihF =>
    intro hle e
    induction e with
    | done o =>
      intro σ out tr σ' h
      cases o with
      | value v =>
        have hd : (KExpr.done (Outcome.value v) :
            KExpr A I E C S).denote = nd_return v := rfl
        rw [hd, runNDFuel_active F (app_nd_return v σ)] at h
        cases h with
        | head => exact KSteps.refl
        | tail _ h' => cases h'
      | killed r =>
        have hd : (KExpr.done (Outcome.killed r) :
            KExpr A I E C S).denote = kill r := rfl
        rw [hd, runNDFuel_killed F (app_kill r σ)] at h
        cases h with
        | head => exact KSteps.refl
        | tail _ h' => cases h'
    | seq m k ihk =>
      intro σ out tr σ' h
      -- `lemDefaultFuel = 999999 + 1` exposes one bind level
      rw [denote_seq_eq, show lemDefaultFuel = 999999 + 1 from rfl] at h
      have hF : F ≤ 999999 := by
        have h1 : F + 1 ≤ 1000000 := hle
        omega
      -- re-wrap a decremented-fuel branch as the denotation of its
      -- successor expression (the invariance move, used by all four
      -- node arms)
      have hrewrap : ∀ (m' : ndM _ I E C S) (st1 : S),
          CerbND.runNDFuel F
              (nd_bind_lemFuel 999999 m' (fun v => (k v).denote)) st1
            = CerbND.runNDFuel F (KExpr.seq m' k).denote st1 := by
        intro m' st1
        rw [denote_seq_eq, show lemDefaultFuel = 999999 + 1 from rfl]
        exact runNDFuel_bind_fuel_irrel F 999999 (999999 + 1) hF
          (by omega) m' _ st1
      have hle' : F ≤ lemDefaultFuel := Nat.le_of_succ_le hle
      cases m with
      | ND g =>
        rcases happ : g σ with ⟨act, st1⟩
        have happ' : app (ND g) σ = (act, st1) := happ
        cases act with
        | NDactive v =>
          rw [runNDFuel_succ_congr F (app_bindFuel_active 999999 happ')] at h
          exact KSteps.head (KStep.seq_active happ')
            (ihk v st1 out tr σ' h)
        | NDkilled r =>
          rw [runNDFuel_killed F (app_bindFuel_killed 999999 happ')] at h
          cases h with
          | head => exact KSteps.single (KStep.seq_killed happ')
          | tail _ h' => cases h'
        | NDnd i br =>
          rw [runNDFuel_nd F (app_bindFuel_nd 999999 happ')] at h
          rcases (mem_foldl_prepend _ _ _ _).mp h with ⟨p, hpmem, hpin⟩ | hacc
          · rcases List.mem_map.mp hpmem with ⟨q, hq, rfl⟩
            dsimp only at hpin
            rw [hrewrap q.2 st1] at hpin
            exact KSteps.head (KStep.seq_nd (j := q.1) happ' hq)
              (ihF hle' (.seq q.2 k) st1 out tr σ' hpin)
          · cases hacc
        | NDstep i br =>
          rw [runNDFuel_step F (app_bindFuel_step 999999 happ')] at h
          rcases (mem_foldl_prepend _ _ _ _).mp h with ⟨p, hpmem, hpin⟩ | hacc
          · rcases List.mem_map.mp hpmem with ⟨q, hq, rfl⟩
            dsimp only at hpin
            rw [hrewrap q.2 st1] at hpin
            exact KSteps.head (KStep.seq_step (j := q.1) happ' hq)
              (ihF hle' (.seq q.2 k) st1 out tr σ' hpin)
          · cases hacc
        | NDguard i c mk =>
          rw [runNDFuel_guard F (app_bindFuel_guard 999999 happ'),
            hrewrap mk st1] at h
          exact KSteps.head (KStep.seq_guard happ' trivial)
            (ihF hle' (.seq mk k) st1 out tr σ' h)
        | NDbranch i c l r =>
          rw [runNDFuel_branch F (app_bindFuel_branch 999999 happ')] at h
          rcases List.mem_append.mp h with hl | hr
          · rw [hrewrap l st1] at hl
            exact KSteps.head (KStep.seq_branchL happ' trivial)
              (ihF hle' (.seq l k) st1 out tr σ' hl)
          · rw [hrewrap r st1] at hr
            exact KSteps.head (KStep.seq_branchR happ' trivial)
              (ihF hle' (.seq r k) st1 out tr σ' hr)

/-- The production-runner form (`CerbND.runND` at its default budget —
    the function every headline statement quantifies): every enumerated
    execution of `denote e` is a per-step trace of `e`. -/
theorem ksteps_of_runND {e : KExpr A I E C S} {σ : S}
    {out : nd_status A E S} {tr : List String} {σ' : S}
    (h : (out, tr, σ') ∈ CerbND.runND e.denote σ) :
    KSteps (CsSem.exhaustive C S) ⟨e, σ⟩
      ⟨.done (Outcome.ofStatus out), σ'⟩ :=
  ksteps_of_runNDFuel CerbND.ndDefaultFuel (Nat.le_refl _) e σ out tr σ' h

end Completeness

end RelSem
