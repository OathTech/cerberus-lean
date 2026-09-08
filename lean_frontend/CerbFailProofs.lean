import CerbND
import CerbFail

namespace CerbFail
set_option autoImplicit true

/-- Observe a single monadic node, including the state returned by it. -/
def step (m : ndM a info err cs st) (s : st) : nd_action a info err cs st × st :=
  match m with | ND f => f s

theorem failStopND_step (msg : String) (s : st) :
    step (failStopND msg : ndM a info err cs st) s =
      (NDkilled (failStopKill msg), s) := rfl

theorem failStopND_ne_active (msg : String) (s s' : st) (value : a) :
    step (failStopND msg : ndM a info err cs st) s ≠ (NDactive value, s') := by
  intro h
  cases h

theorem failStopKill_ne_undef (msg : String) (loc : CerbLocation.Loc) (ubs) :
    (failStopKill msg : kill_reason err) ≠ Undef0 loc ubs := by
  intro h; cases h

theorem failStopKill_ne_other (msg : String) (error : err) :
    failStopKill msg ≠ Other error := by
  intro h; cases h

/-- Any kill (including a failure after earlier state updates) absorbs the
    continuation. One bind frame is required by the generated fuel contract. -/
theorem bind_preserves (n : Nat) (m : ndM a info err cs st) (s s' : st)
    (msg : String) (k : a → ndM b info err cs st)
    (h : step m s = (NDkilled (failStopKill msg), s')) :
    step (@nd_bind _ _ _ _ _ _ ⟨n + 1⟩ m k) s =
      (NDkilled (failStopKill msg), s') := by
  cases m with | ND f => simp only [step] at h; simp only [step, nd_bind, nd_bind_lemFuel, h]

/-- liftND spends one frame on liftND and one on liftAction. Its put function
    receives the state at failure, not the input state. -/
theorem lift_preserves (n : Nat) (get : st2 → st1) (put : st2 → st1 → st2)
    (infoMap : info1 → info2) (errMap : err1 → err2)
    (m : ndM a info1 err1 cs st1) (s : st2) (s' : st1) (msg : String)
    (h : step m (get s) = (NDkilled (failStopKill msg), s')) :
    step (@liftND _ _ _ _ _ _ _ _ ⟨n + 2⟩ get put infoMap errMap m) s =
      (NDkilled (failStopKill msg), put s s') := by
  cases m with
  | ND f =>
    simp only [step] at h
    simp only [step, liftND, liftND_lemFuel, h, liftAction_lemFuel, failStopKill]

theorem liftMem_preserves (n : Nat) (m : CerbMem.memM a)
    (s : driver_state) (s' : CerbMem.MemState) (msg : String)
    (h : step m s.layout_state = (NDkilled (failStopKill msg), s')) :
    step (@liftMem a ⟨n + 2⟩ m) s =
      (NDkilled (failStopKill msg), { s with layout_state := s' }) :=
  lift_preserves n _ _ _ _ m s s' msg h

theorem run_preserves (n : Nat) (m : ndM a info err cs st) (s s' : st)
    (msg : String) (h : step m s = (NDkilled (failStopKill msg), s')) :
    CerbND.runNDFuel (n + 1) m s = [(Killed s' (failStopKill msg), [], s')] := by
  cases m with | ND f => simp only [step] at h; simp only [CerbND.runNDFuel, h]

theorem run1_preserves (n : Nat) (m : ndM a info err cs st) (s s' : st)
    (msg : String) (h : step m s = (NDkilled (failStopKill msg), s')) :
    CerbND.runND1Fuel (n + 1) m s = [(Killed s' (failStopKill msg), [], s')] := by
  cases m with | ND f => simp only [step] at h; simp only [CerbND.runND1Fuel, h]

theorem runTrace_preserves (showInfo : info → String) (n : Nat)
    (m : ndM a info err cs st) (s s' : st) (msg : String)
    (h : step m s = (NDkilled (failStopKill msg), s')) :
    CerbND.runND1TraceFuel showInfo (n + 1) m s =
      (["NDkilled"], [(Killed s' (failStopKill msg), [], s')]) := by
  cases m with | ND f => simp only [step] at h; simp only [CerbND.runND1TraceFuel, h]

/-- The shipped wrappers composed: a failed memory operation cannot execute
    its driver continuation; both copies of the final driver state contain
    the memory state at failure. The caller's one fuel is at least two. -/
theorem pipeline_preserves (n : Nat) (m : CerbMem.memM a)
    (s : driver_state) (s' : CerbMem.MemState) (msg : String)
    (k : a → ndM b step_kind driver_error (mem_constraint CerbMem.IntegerValue) driver_state)
    (h : step m s.layout_state = (NDkilled (failStopKill msg), s')) :
    @CerbND.runND _ _ _ _ _ ⟨n + 2⟩
      (@nd_bind _ _ _ _ _ _ ⟨n + 2⟩ (@liftMem a ⟨n + 2⟩ m) k) s =
      [(Killed { s with layout_state := s' } (failStopKill msg), [],
        { s with layout_state := s' })] :=
  run_preserves (n + 1) _ _ _ msg
    (bind_preserves (n + 1) _ _ _ msg k (liftMem_preserves n m s s' msg h))

/-- Fuel exhaustion precedes inspection of a model stop at zero; no theorem
    here asserts distinctness between the two opaque location atoms. -/
theorem zero_precedes (msg : String) (s : st) :
    @CerbND.runND a info err cs st ⟨0⟩ (failStopND msg) s =
      [(Killed s CerbND.fuelExhaustedKill, [], s)] := rfl

end CerbFail
