import Nd_observe
import Nondeterminism

namespace NDObserveProof
variable {α info err cs st st₁ st₂ info₁ info₂ err₁ err₂ : Type}

@[simp] theorem checked_action_none (a : nd_action α info err cs st) :
    checked_action none a = a := by cases a <;> rfl

/-- Exact erasure, at the same caller-selected fuel, for every monadic tree.
    This connects the new lift to the existing shipped operation. -/
theorem disabled (n : Nat) (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (infoMap : info₁ → info₂) (errMap : err₁ → err₂) :
    (∀ m : ndM α info₁ err₁ cs st₁,
      lift_checked_lemFuel n get put infoMap errMap (fun st => (none, st)) m =
        liftND_lemFuel n get put infoMap errMap m) ∧
    (∀ a : nd_action α info₁ err₁ cs st₁,
      lift_checked_action_lemFuel n get put infoMap errMap (fun st => (none, st)) a =
        liftAction_lemFuel n get put infoMap errMap a) := by
  induction n with
  | zero => exact ⟨fun _ => rfl, fun _ => rfl⟩
  | succ n ih =>
    constructor
    · intro m
      cases m with
      | ND f =>
        simp only [lift_checked_lemFuel, liftND_lemFuel]
        congr 1
        funext st
        rcases f (get st) with ⟨a, inner⟩
        simp only [checked_action_none, ih.2]
    · intro a
      cases a <;> simp only [lift_checked_action_lemFuel, liftAction_lemFuel, ih.1] <;> rfl

/-- Checking cannot replace an already reported failure. -/
theorem existing_kill (failure : Option (kill_reason err)) (reason : kill_reason err) :
    checked_action failure (NDkilled reason : nd_action α info err cs st) = NDkilled reason := rfl

/-- A failing check stops a live branching node before any child executes. -/
theorem stops_branch (reason : kill_reason err) (label : info) (constraint : cs)
    (left right : ndM α info err cs st) :
    checked_action (some reason) (NDbranch label constraint left right) = NDkilled reason := rfl

/-- The post-state callback sees failure-time state, including its completed
    prefix, and its updated state survives the original failure. -/
theorem failure_state (n : Nat) (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (infoMap : info₁ → info₂) (errMap : err₁ → err₂)
    (postNode : st₂ → Option (kill_reason err₂) × st₂)
    (f : st₁ → nd_action α info₁ err₁ cs st₁ × st₁)
    (outer after : st₂) (inner : st₁) (error : err₁) (newFault : Option (kill_reason err₂))
    (h : f (get outer) = (NDkilled (Other error), inner))
    (hp : postNode (put outer inner) = (newFault, after)) :
    (match lift_checked_lemFuel (n + 2) get put infoMap errMap postNode (ND f) with
     | ND run => run outer) = (NDkilled (Other (errMap error)), after) := by
  simp only [lift_checked_lemFuel, h, hp, lift_checked_action_lemFuel, checked_action]

end NDObserveProof
