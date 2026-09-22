import CerbNDFuelProofs
import CerbNDObserveProofs

/-! Carrier laws for typed service suspension. The generic observer resumes
one continuation; these laws choose no C memory interruption policy. -/
namespace CerbNDSuspension
variable {α β info err cs st st₁ st₂ info₁ info₂ err₁ err₂ : Type}

def node (operation : ndM α info err cs st) (state : st) :=
  match operation with | ND run => run state

theorem next (continuation : ndM α info err cs st) (state : st) :
    node (nd_suspend continuation) state = (NDsuspend continuation, state) := rfl

theorem bind_next (fuel : Nat) (continuation : ndM α info err cs st)
    (after : α → ndM β info err cs st) (state : st) :
    node (nd_bind_lemFuel (fuel + 1) (nd_suspend continuation) after) state =
      (NDsuspend (nd_bind_lemFuel fuel continuation after), state) := rfl

theorem lift_next (fuel : Nat) (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (infoMap : info₁ → info₂) (errMap : err₁ → err₂)
    (continuation : ndM α info₁ err₁ cs st₁) (state : st₂) :
    node (liftND_lemFuel (fuel + 2) get put infoMap errMap (nd_suspend continuation)) state =
      (NDsuspend (liftND_lemFuel fuel get put infoMap errMap continuation), put state (get state)) := rfl

theorem failing_check (reason : kill_reason err) (continuation : ndM α info err cs st) :
    checked_action (some reason) (NDsuspend continuation) = NDkilled reason := rfl

theorem exhaustive (fuel : Nat) (continuation : ndM α info err cs st) (state : st) :
    CerbND.runNDFuel (fuel + 1) (nd_suspend continuation) state =
      CerbND.runNDFuel fuel continuation state := rfl

theorem selected (fuel : Nat) (continuation : ndM α info err cs st) (state : st) :
    CerbND.runND1Fuel (fuel + 1) (nd_suspend continuation) state =
      CerbND.runND1Fuel fuel continuation state := rfl

theorem trace (showInfo : info → String) (fuel : Nat)
    (continuation : ndM α info err cs st) (state : st) :
    CerbND.runND1TraceFuel showInfo (fuel + 1) (nd_suspend continuation) state =
      let result := CerbND.runND1TraceFuel showInfo fuel continuation state
      ("NDsuspend" :: result.1, result.2) := rfl

end CerbNDSuspension
