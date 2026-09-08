import CerbND

/-!
Fuel stability of the shipped ND infrastructure. Operands and continuations
are held fixed: these theorems vary worker/runner counters, not ambient fuel
captured inside arbitrary operands. See docs/2026-09-08_nd-fuel-stability-record.md.
-/

namespace CerbND
set_option autoImplicit true

/-- A structural exhaustion observation, independent of diagnostic rendering.
The state inside `Killed` is quantified; the remaining tuple fields do not
decide whether an observation exhausted. No atom-distinctness axiom is used. -/
def IsFuel (o : nd_status a err st × List String × st) : Prop :=
  ∃ s, o.1 = Killed s fuelExhaustedKill

/-- Every enumerated observation is free of the distinguished fuel kill.
For an exhaustive runner this includes every branch, not only a chosen result. -/
def NoFuel (xs : List (nd_status a err st × List String × st)) : Prop :=
  ∀ o ∈ xs, ¬ IsFuel o

namespace FuelProof

/-- Position-by-position relation, retaining list length and multiplicity. -/
inductive ListRel (R : α → β → Prop) : List α → List β → Prop where
  | nil : ListRel R [] []
  | cons {x y xs ys} (head : R x y) (tail : ListRel R xs ys) :
      ListRel R (x :: xs) (y :: ys)

theorem ListRel.length_eq {R : α → β → Prop} {xs ys} (h : ListRel R xs ys) :
    xs.length = ys.length := by
  induction h with
  | nil => rfl
  | cons _ _ ih => simp only [List.length_cons, ih]

theorem listRel_map {R : β → γ → Prop} (f : α → β) (g : α → γ)
    (h : ∀ x, R (f x) (g x)) (xs : List α) : ListRel R (xs.map f) (xs.map g) := by
  induction xs with
  | nil => exact .nil
  | cons x xs ih => exact .cons (h x) ih

/-- Unwrap one state-function node of the shipped monad. -/
def node (m : ndM a info err cs st) (s : st) : nd_action a info err cs st × st :=
  match m with | ND f => f s

/-- One layer of refinement. A fuel kill may expand; every other matched
node keeps its exact payload, state, and ordered children. -/
inductive ActionRefines (R : ndM a info err cs st → ndM a info err cs st → st → Prop) :
    nd_action a info err cs st × st → nd_action a info err cs st × st → Prop where
  | fuel (s : st) (rhs) : ActionRefines R (NDkilled fuelExhaustedKill, s) rhs
  | active (v : a) (s : st) : ActionRefines R (NDactive v, s) (NDactive v, s)
  | killed (r : kill_reason err) (s : st) : ActionRefines R (NDkilled r, s) (NDkilled r, s)
  | nd (i : info) (s : st) {xs ys}
      (h : ListRel (fun x y => x.1 = y.1 ∧ R x.2 y.2 s) xs ys) :
      ActionRefines R (NDnd i xs, s) (NDnd i ys, s)
  | guard (i : info) (c : cs) (s : st) {x y} (h : R x y s) :
      ActionRefines R (NDguard i c x, s) (NDguard i c y, s)
  | branch (i : info) (c : cs) (s : st) {x₁ y₁ x₂ y₂}
      (h₁ : R x₁ y₁ s) (h₂ : R x₂ y₂ s) :
      ActionRefines R (NDbranch i c x₁ x₂, s) (NDbranch i c y₁ y₂, s)
  | step (i : info) (s : st) {xs ys}
      (h : ListRel (fun x y => x.1 = y.1 ∧ R x.2 y.2 s) xs ys) :
      ActionRefines R (NDstep i xs, s) (NDstep i ys, s)

/-- Compare a finite observation depth; this inspects existing definitions
only and introduces no execution or fuel default. -/
def Refines : Nat → ndM a info err cs st → ndM a info err cs st → st → Prop
  | 0, _, _, _ => True
  | n + 1, x, y, s => ActionRefines (Refines n) (node x s) (node y s)

theorem action_refl {R : ndM a info err cs st → ndM a info err cs st → st → Prop}
    (hR : ∀ x s, R x x s) (p : nd_action a info err cs st × st) :
    ActionRefines R p p := by
  rcases p with ⟨act, s⟩
  cases act with
  | NDactive v => exact .active v s
  | NDkilled r => exact .killed r s
  | NDnd i xs =>
    apply ActionRefines.nd
    induction xs with
    | nil => exact .nil
    | cons x xs ih => exact .cons ⟨rfl, hR x.2 s⟩ ih
  | NDguard i c x => exact .guard i c s (hR x s)
  | NDbranch i c x y => exact .branch i c s (hR x s) (hR y s)
  | NDstep i xs =>
    apply ActionRefines.step
    induction xs with
    | nil => exact .nil
    | cons x xs ih => exact .cons ⟨rfl, hR x.2 s⟩ ih

theorem refines_refl (n : Nat) (x : ndM a info err cs st) (s : st) :
    Refines n x x s := by
  induction n generalizing x s with
  | zero => trivial
  | succ n ih => exact action_refl ih (node x s)

/-- Exhausted observations can be replaced by any result block, including
an empty block. Every retained observation stays in its exact list position
relative to the other retained observations. -/
inductive ResultsRefine : List (nd_status a err st × List String × st) →
    List (nd_status a err st × List String × st) → Prop where
  | nil : ResultsRefine [] []
  | keep (o) {xs ys} (h : ResultsRefine xs ys) : ResultsRefine (o :: xs) (o :: ys)
  | fuel (o) (hf : IsFuel o) (block) {xs ys} (h : ResultsRefine xs ys) :
      ResultsRefine (o :: xs) (block ++ ys)

theorem ResultsRefine.refl (xs : List (nd_status a err st × List String × st)) :
    ResultsRefine xs xs := by
  induction xs with
  | nil => exact .nil
  | cons x xs ih => exact .keep x ih

theorem ResultsRefine.append {xs ys xs' ys' : List (nd_status a err st × List String × st)}
    (h : ResultsRefine xs ys) (h' : ResultsRefine xs' ys') :
    ResultsRefine (xs ++ xs') (ys ++ ys') := by
  induction h with
  | nil => exact h'
  | keep o h ih => exact .keep o ih
  | fuel o hf block h ih =>
    simpa only [List.cons_append, List.append_assoc] using ResultsRefine.fuel o hf block ih

theorem ResultsRefine.eq_of_noFuel {xs ys : List (nd_status a err st × List String × st)}
    (h : ResultsRefine xs ys) (hn : NoFuel xs) : ys = xs := by
  induction h with
  | nil => rfl
  | keep o h ih =>
    exact congrArg (o :: ·) (ih (fun x hx => hn x (List.mem_cons_of_mem o hx)))
  | fuel o hf block h ih => exact False.elim (hn o (by simp) hf)

theorem ResultsRefine.exhausted (s : st)
    (ys : List (nd_status a err st × List String × st)) :
    ResultsRefine [(Killed s fuelExhaustedKill, [], s)] ys := by
  simpa only [List.append_nil] using
    ResultsRefine.fuel (Killed s fuelExhaustedKill, [], s) ⟨s, rfl⟩ ys .nil

theorem fold_refines {R : α → β → Prop}
    (f : α → List (nd_status a err st × List String × st))
    (g : β → List (nd_status a err st × List String × st))
    (hf : ∀ x y, R x y → ResultsRefine (f x) (g y))
    {xs ys} (h : ListRel R xs ys) {acc₁ acc₂}
    (ha : ResultsRefine acc₁ acc₂) :
    ResultsRefine (xs.foldl (fun acc x => f x ++ acc) acc₁)
      (ys.foldl (fun acc y => g y ++ acc) acc₂) := by
  induction h generalizing acc₁ acc₂ with
  | nil => exact ha
  | cons hxy h ih => exact ih ((hf _ _ hxy).append ha)

/-- Increasing the exhaustive observer budget preserves completed leaves in
order, and may replace each exhausted leaf with a block of new results. -/
theorem run_refines {n k : Nat} (hn : n ≤ k)
    {x y : ndM a info err cs st} {s : st} (h : Refines n x y s) :
    ResultsRefine (runNDFuel n x s) (runNDFuel k y s) := by
  induction n generalizing k x y s with
  | zero => exact ResultsRefine.exhausted s _
  | succ n ih =>
    cases k with
    | zero => omega
    | succ k =>
      have hnk : n ≤ k := by omega
      cases x with | ND f =>
       cases y with | ND g =>
        change ActionRefines (Refines n) (f s) (g s) at h
        generalize hp : f s = p at h
        generalize hq : g s = q at h
        cases h with
        | fuel u rhs =>
          simp only [runNDFuel, hp]
          exact ResultsRefine.exhausted u _
        | active v u => simp only [runNDFuel, hp, hq]; exact .refl _
        | killed r u => simp only [runNDFuel, hp, hq]; exact .refl _
        | nd i u hb =>
          simp only [runNDFuel, hp, hq]
          exact fold_refines _ _ (fun _ _ h => ih hnk h.2) hb .nil
        | guard i c u hc =>
          simp only [runNDFuel, hp, hq]
          exact ih hnk hc
        | branch i c u hl hr =>
          simp only [runNDFuel, hp, hq]
          exact (ih hnk hl).append (ih hnk hr)
        | step i u hb =>
          simp only [runNDFuel, hp, hq]
          exact fold_refines _ _ (fun _ _ h => ih hnk h.2) hb .nil

theorem run1_refines {n k : Nat} (hn : n ≤ k)
    {x y : ndM a info err cs st} {s : st} (h : Refines n x y s) :
    ResultsRefine (runND1Fuel n x s) (runND1Fuel k y s) := by
  induction n generalizing k x y s with
  | zero => exact ResultsRefine.exhausted s _
  | succ n ih =>
    cases k with
    | zero => omega
    | succ k =>
      have hnk : n ≤ k := by omega
      cases x with | ND f =>
       cases y with | ND g =>
        change ActionRefines (Refines n) (f s) (g s) at h
        generalize hp : f s = p at h
        generalize hq : g s = q at h
        cases h with
        | fuel u rhs =>
          simp only [runND1Fuel, hp]
          exact ResultsRefine.exhausted u _
        | active v u => simp only [runND1Fuel, hp, hq]; exact .refl _
        | killed r u => simp only [runND1Fuel, hp, hq]; exact .refl _
        | nd i u hb =>
          cases hb with
          | nil => simp only [runND1Fuel, hp, hq]; exact .nil
          | cons hxy _ =>
            simp only [runND1Fuel, hp, hq]
            exact ih hnk hxy.2
        | guard i c u hc =>
          simp only [runND1Fuel, hp, hq]
          exact ih hnk hc
        | branch i c u hl hr =>
          simp only [runND1Fuel, hp, hq]
          exact ih hnk hl
        | step i u hb =>
          cases hb with
          | nil => simp only [runND1Fuel, hp, hq]; exact .nil
          | cons hxy _ =>
            simp only [runND1Fuel, hp, hq]
            exact ih hnk hxy.2

theorem trace_eq_of_refines {n k : Nat} (hn : n ≤ k) (showInfo : info → String)
    {x y : ndM a info err cs st} {s : st} (h : Refines n x y s)
    (hc : NoFuel (runND1TraceFuel showInfo n x s).2) :
    runND1TraceFuel showInfo k y s = runND1TraceFuel showInfo n x s := by
  induction n generalizing k x y s with
  | zero =>
    exact False.elim (hc (Killed s fuelExhaustedKill, [], s)
      (by simp [runND1TraceFuel]) ⟨s, rfl⟩)
  | succ n ih =>
    cases k with
    | zero => omega
    | succ k =>
      have hnk : n ≤ k := by omega
      cases x with | ND f =>
       cases y with | ND g =>
        change ActionRefines (Refines n) (f s) (g s) at h
        generalize hp : f s = p at h
        generalize hq : g s = q at h
        cases h with
        | fuel u rhs =>
          exact False.elim (hc (Killed u fuelExhaustedKill, [], u)
            (by simp [runND1TraceFuel, hp]) ⟨u, rfl⟩)
        | active v u => simp only [runND1TraceFuel, hp, hq]
        | killed r u => simp only [runND1TraceFuel, hp, hq]
        | nd i u hb =>
          have hlen := hb.length_eq
          cases hb with
          | nil => simp only [runND1TraceFuel, hp, hq]
          | cons hxy _ =>
            simp only [runND1TraceFuel, hp, hq] at hc ⊢
            rw [ih hnk hxy.2 hc, hlen]
        | guard i c u hx =>
          simp only [runND1TraceFuel, hp, hq] at hc ⊢
          rw [ih hnk hx hc]
        | branch i c u hl hr =>
          simp only [runND1TraceFuel, hp, hq] at hc ⊢
          rw [ih hnk hl hc]
        | step i u hb =>
          have hlen := hb.length_eq
          cases hb with
          | nil => simp only [runND1TraceFuel, hp, hq]
          | cons hxy _ =>
            simp only [runND1TraceFuel, hp, hq] at hc ⊢
            rw [ih hnk hxy.2 hc, hlen]

/-- The bind worker's only varying fuel is its explicit counter. Its
operand and continuation are arbitrary but fixed across the comparison. -/
theorem bind_refines {b b' : Nat} (hb : b ≤ b') (d : Nat)
    (x : ndM a info err cs st) (f : a → ndM a' info err cs st) (s : st) :
    Refines d (nd_bind_lemFuel b x f) (nd_bind_lemFuel b' x f) s := by
  induction b generalizing b' d x s with
  | zero =>
    cases d with
    | zero => trivial
    | succ d => exact ActionRefines.fuel s _
  | succ b ih =>
    cases b' with
    | zero => omega
    | succ b' =>
      have hbb : b ≤ b' := by omega
      cases d with
      | zero => trivial
      | succ d =>
        cases x with | ND g =>
         rcases hp : g s with ⟨act, u⟩
         cases act with
         | NDactive v =>
           cases hfv : f v with | ND next =>
            simp only [Refines, nd_bind_lemFuel, node, hp, hfv]
            exact action_refl (refines_refl d) (next u)
         | NDkilled r =>
           simp only [Refines, nd_bind_lemFuel, node, hp]
           exact .killed r u
         | NDnd i xs =>
           simp only [Refines, nd_bind_lemFuel, node, hp]
           exact .nd i u (listRel_map _ _ (fun p => ⟨rfl, ih hbb d p.2 u⟩) xs)
         | NDguard i c x =>
           simp only [Refines, nd_bind_lemFuel, node, hp]
           exact .guard i c u (ih hbb d x u)
         | NDbranch i c x y =>
           simp only [Refines, nd_bind_lemFuel, node, hp]
           exact .branch i c u (ih hbb d x u) (ih hbb d y u)
         | NDstep i xs =>
           simp only [Refines, nd_bind_lemFuel, node, hp]
           exact .step i u (listRel_map _ _ (fun p => ⟨rfl, ih hbb d p.2 u⟩) xs)

/- The mutual worker spends one fuel frame in liftND and another in
liftAction. The paired induction follows those exact generated equations. -/
theorem lift_refines (b : Nat)
    (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (infoMap : info₁ → info₂) (errMap : err₁ → err₂) :
    ∀ b', b ≤ b' →
      (∀ d (x : ndM a info₁ err₁ cs st₁) s,
        Refines d (liftND_lemFuel b get put infoMap errMap x)
          (liftND_lemFuel b' get put infoMap errMap x) s) ∧
      (∀ d (act : nd_action a info₁ err₁ cs st₁) s,
        ActionRefines (Refines d) (liftAction_lemFuel b get put infoMap errMap act, s)
          (liftAction_lemFuel b' get put infoMap errMap act, s)) := by
  induction b with
  | zero =>
    intro b' hb
    constructor
    · intro d x s
      cases d with
      | zero => trivial
      | succ d => exact .fuel s _
    · intro d act s
      exact .fuel s _
  | succ b ih =>
    intro b' hb
    cases b' with
    | zero => omega
    | succ b' =>
      have hbb : b ≤ b' := by omega
      constructor
      · intro d x s
        cases d with
        | zero => trivial
        | succ d =>
          cases x with | ND f =>
           rcases hp : f (get s) with ⟨act, u⟩
           simp only [Refines, liftND_lemFuel, node, hp]
           exact (ih b' hbb).2 d act (put s u)
      · intro d act s
        cases act with
        | NDactive v =>
          simp only [liftAction_lemFuel]
          exact .active v s
        | NDkilled r =>
          simp only [liftAction_lemFuel]
          exact .killed _ s
        | NDnd i xs =>
          simp only [liftAction_lemFuel]
          exact .nd (infoMap i) s
            (listRel_map _ _ (fun p => ⟨rfl, (ih b' hbb).1 d p.2 s⟩) xs)
        | NDguard i c x =>
          simp only [liftAction_lemFuel]
          exact .guard (infoMap i) c s ((ih b' hbb).1 d x s)
        | NDbranch i c x y =>
          simp only [liftAction_lemFuel]
          exact .branch (infoMap i) c s ((ih b' hbb).1 d x s) ((ih b' hbb).1 d y s)
        | NDstep i xs =>
          simp only [liftAction_lemFuel]
          exact .step (infoMap i) s
            (listRel_map _ _ (fun p => ⟨rfl, (ih b' hbb).1 d p.2 s⟩) xs)

theorem liftND_refines {b b' : Nat} (hb : b ≤ b') (d : Nat)
    (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (infoMap : info₁ → info₂) (errMap : err₁ → err₂)
    (x : ndM a info₁ err₁ cs st₁) (s : st₂) :
    Refines d (liftND_lemFuel b get put infoMap errMap x)
      (liftND_lemFuel b' get put infoMap errMap x) s :=
  (lift_refines b get put infoMap errMap b' hb).1 d x s

theorem liftAction_refines {b b' : Nat} (hb : b ≤ b') (d : Nat)
    (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (infoMap : info₁ → info₂) (errMap : err₁ → err₂)
    (act : nd_action a info₁ err₁ cs st₁) (s : st₂) :
    Refines d (ND (fun s => (liftAction_lemFuel b get put infoMap errMap act, s)))
      (ND (fun s => (liftAction_lemFuel b' get put infoMap errMap act, s))) s := by
  cases d with
  | zero => trivial
  | succ d => exact (lift_refines b get put infoMap errMap b' hb).2 d act s

end FuelProof

/-- Once exhaustive enumeration contains no exhaustion, more runner fuel
preserves the complete ordered list, including every final state. -/
theorem runNDFuel_stable {n k : Nat} (hn : n ≤ k)
    (x : ndM a info err cs st) (s : st) (hc : NoFuel (runNDFuel n x s)) :
    runNDFuel k x s = runNDFuel n x s :=
  (FuelProof.run_refines hn (FuelProof.refines_refl n x s)).eq_of_noFuel hc

/-- The branch-zero runner preserves its completed observation at greater
runner fuel. This premise says nothing about unselected branches. -/
theorem runND1Fuel_stable {n k : Nat} (hn : n ≤ k)
    (x : ndM a info err cs st) (s : st) (hc : NoFuel (runND1Fuel n x s)) :
    runND1Fuel k x s = runND1Fuel n x s :=
  (FuelProof.run1_refines hn (FuelProof.refines_refl n x s)).eq_of_noFuel hc

/-- Both node labels and execution observations of a completed trace are
unchanged at every greater runner budget. -/
theorem runND1TraceFuel_stable {n k : Nat} (hn : n ≤ k) (showInfo : info → String)
    (x : ndM a info err cs st) (s : st)
    (hc : NoFuel (runND1TraceFuel showInfo n x s).2) :
    runND1TraceFuel showInfo k x s = runND1TraceFuel showInfo n x s :=
  FuelProof.trace_eq_of_refines hn showInfo (FuelProof.refines_refl n x s) hc

/-- The same completion contract for all three shipped observation modes.
Each field uses its OWN earlier observation as the completion premise. -/
structure ObservationStability (n k : Nat) (x y : ndM a info err cs st) (s : st) : Prop where
  exhaustive : NoFuel (runNDFuel n x s) → runNDFuel k y s = runNDFuel n x s
  first : NoFuel (runND1Fuel n x s) → runND1Fuel k y s = runND1Fuel n x s
  trace : ∀ showInfo, NoFuel (runND1TraceFuel showInfo n x s).2 →
    runND1TraceFuel showInfo k y s = runND1TraceFuel showInfo n x s

theorem FuelProof.observationStability {n k : Nat} (hn : n ≤ k)
    {x y : ndM a info err cs st} {s : st} (h : FuelProof.Refines n x y s) :
    ObservationStability n k x y s where
  exhaustive hc := (FuelProof.run_refines hn h).eq_of_noFuel hc
  first hc := (FuelProof.run1_refines hn h).eq_of_noFuel hc
  trace showInfo hc := FuelProof.trace_eq_of_refines hn showInfo h hc

/-- Bind stability with independently quantified observer and worker fuel.
The continuation is fixed, including any ambient fuel it already captures. -/
theorem nd_bind_lemFuel_stable {n k b b' : Nat} (hn : n ≤ k) (hb : b ≤ b')
    (x : ndM a info err cs st) (f : a → ndM a' info err cs st) (s : st) :
    ObservationStability n k (nd_bind_lemFuel b x f) (nd_bind_lemFuel b' x f) s :=
  FuelProof.observationStability hn (FuelProof.bind_refines hb n x f s)

/-- Lift stability needs no lens laws: both runs use the same arbitrary
get/put functions, and retain the exact resulting outer state. -/
theorem liftND_lemFuel_stable {n k b b' : Nat} (hn : n ≤ k) (hb : b ≤ b')
    (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (infoMap : info₁ → info₂) (errMap : err₁ → err₂)
    (x : ndM a info₁ err₁ cs st₁) (s : st₂) :
    ObservationStability n k (liftND_lemFuel b get put infoMap errMap x)
      (liftND_lemFuel b' get put infoMap errMap x) s :=
  FuelProof.observationStability hn (FuelProof.liftND_refines hb n get put infoMap errMap x s)

/-- An action is observed by returning it from a state-preserving ND node;
recursive lifted children still perform their own get/put operations. -/
theorem liftAction_lemFuel_stable {n k b b' : Nat} (hn : n ≤ k) (hb : b ≤ b')
    (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (infoMap : info₁ → info₂) (errMap : err₁ → err₂)
    (act : nd_action a info₁ err₁ cs st₁) (s : st₂) :
    ObservationStability n k
      (ND (fun s => (liftAction_lemFuel b get put infoMap errMap act, s)))
      (ND (fun s => (liftAction_lemFuel b' get put infoMap errMap act, s))) s :=
  FuelProof.observationStability hn
    (FuelProof.liftAction_refines hb n get put infoMap errMap act s)

/-! Wrapper corollaries. Each side installs one instance for the infrastructure
being compared. Fixed operands are not reconstructed at that new instance. -/

theorem runND_stable {n k : Nat} (hn : n ≤ k)
    (x : ndM a info err cs st) (s : st) (hc : NoFuel (@runND _ _ _ _ _ ⟨n⟩ x s)) :
    @runND _ _ _ _ _ ⟨k⟩ x s = @runND _ _ _ _ _ ⟨n⟩ x s :=
  runNDFuel_stable hn x s hc

theorem runND1_stable {n k : Nat} (hn : n ≤ k)
    (x : ndM a info err cs st) (s : st) (hc : NoFuel (@runND1 _ _ _ _ _ ⟨n⟩ x s)) :
    @runND1 _ _ _ _ _ ⟨k⟩ x s = @runND1 _ _ _ _ _ ⟨n⟩ x s :=
  runND1Fuel_stable hn x s hc

theorem runND1Trace_stable {n k : Nat} (hn : n ≤ k) (showInfo : info → String)
    (x : ndM a info err cs st) (s : st)
    (hc : NoFuel (@runND1Trace _ _ _ _ _ ⟨n⟩ showInfo x s).2) :
    @runND1Trace _ _ _ _ _ ⟨k⟩ showInfo x s = @runND1Trace _ _ _ _ _ ⟨n⟩ showInfo x s :=
  runND1TraceFuel_stable hn showInfo x s hc

theorem nd_bind_stable {n k : Nat} (hn : n ≤ k)
    (x : ndM a info err cs st) (f : a → ndM a' info err cs st) (s : st) :
    ObservationStability n k (@nd_bind _ _ _ _ _ _ ⟨n⟩ x f)
      (@nd_bind _ _ _ _ _ _ ⟨k⟩ x f) s :=
  nd_bind_lemFuel_stable hn hn x f s

theorem liftND_stable {n k : Nat} (hn : n ≤ k)
    (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (infoMap : info₁ → info₂) (errMap : err₁ → err₂)
    (x : ndM a info₁ err₁ cs st₁) (s : st₂) :
    ObservationStability n k (@liftND _ _ _ _ _ _ _ _ ⟨n⟩ get put infoMap errMap x)
      (@liftND _ _ _ _ _ _ _ _ ⟨k⟩ get put infoMap errMap x) s :=
  liftND_lemFuel_stable hn hn get put infoMap errMap x s

theorem liftAction_stable {n k : Nat} (hn : n ≤ k)
    (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (infoMap : info₁ → info₂) (errMap : err₁ → err₂)
    (act : nd_action a info₁ err₁ cs st₁) (s : st₂) :
    ObservationStability n k
      (ND (fun s => (@liftAction _ _ _ _ _ _ _ _ ⟨n⟩ get put infoMap errMap act, s)))
      (ND (fun s => (@liftAction _ _ _ _ _ _ _ _ ⟨k⟩ get put infoMap errMap act, s))) s :=
  liftAction_lemFuel_stable hn hn get put infoMap errMap act s

end CerbND
