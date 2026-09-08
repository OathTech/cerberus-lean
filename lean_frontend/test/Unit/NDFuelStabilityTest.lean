import CerbNDFuelProofs

/-! Kernel-checked boundary witnesses for the public fuel-stability API.
Imported by totality-proof-test. These distinguish completion of the chosen
trace from completion of all branches, and worker fuel from observer fuel. -/

namespace NDFuelStabilityTest
open CerbND

abbrev M := ndM Nat String Unit Unit Nat

def leaf (v delta : Nat) : M := ND (fun s => (NDactive v, s + delta))
def delayed : M := ND (fun s => (NDstep "delay" [("inner", leaf 7 3)], s + 2))
def fork : M := ND (fun s => (NDnd "fork" [("first", leaf 5 1), ("second", delayed)], s + 10))
def empty : M := ND (fun s => (NDnd "empty" [], s + 1))
def guarded : M := ND (fun s => (NDguard "guard" () (leaf 4 2), s + 1))
def branch : M := ND (fun s => (NDbranch "branch" () guarded empty, s + 1))
def next (v : Nat) : M := leaf (v + 100) 20

theorem fork_partial : runNDFuel 2 fork 0 =
    [(Killed 12 fuelExhaustedKill, [], 12), (Active 5, [], 11)] := rfl

theorem fork_complete : runNDFuel 3 fork 0 =
    [(Active 7, [], 15), (Active 5, [], 11)] := rfl

theorem fork_partial_not_complete : ¬ NoFuel (runNDFuel 2 fork 0) := by
  intro h
  exact h (Killed 12 fuelExhaustedKill, [], 12) (by rw [fork_partial]; simp) ⟨12, rfl⟩

theorem fork_budget_matters : runNDFuel 2 fork 0 ≠ runNDFuel 3 fork 0 := by
  rw [fork_partial, fork_complete]
  intro h
  cases h

theorem fork_stable_above (n : Nat) (h : 3 ≤ n) :
    runNDFuel n fork 0 = [(Active 7, [], 15), (Active 5, [], 11)] := by
  rw [runNDFuel_stable h fork 0 (by rw [fork_complete]; simp [NoFuel, IsFuel])]
  exact fork_complete

theorem first_already_complete : NoFuel (runND1Fuel 2 fork 0) := by
  simp [runND1Fuel, fork, leaf, NoFuel, IsFuel]

theorem first_stable_above (n : Nat) (h : 2 ≤ n) :
    runND1Fuel n fork 0 = [(Active 5, [], 11)] :=
  runND1Fuel_stable h fork 0 first_already_complete

theorem trace_stable_above (n : Nat) (h : 2 ≤ n) :
    runND1TraceFuel id n fork 0 =
      (["NDnd[fork] |branches|=2", "NDactive"], [(Active 5, [], 11)]) := by
  exact runND1TraceFuel_stable h id fork 0 (by
    simp [runND1TraceFuel, fork, leaf, NoFuel, IsFuel])

theorem empty_stable_above (n : Nat) (h : 1 ≤ n) : runNDFuel n empty 0 = [] :=
  runNDFuel_stable h empty 0 (by simp [runNDFuel, empty, NoFuel])

theorem branch_order_state : runNDFuel 3 branch 0 = [(Active 4, [], 4)] := rfl

theorem branch_stable_above (n : Nat) (h : 3 ≤ n) :
    runNDFuel n branch 0 = [(Active 4, [], 4)] :=
  runNDFuel_stable h branch 0 (by rw [branch_order_state]; simp [NoFuel, IsFuel])

theorem bind_complete (b : Nat) (hb : b = 3) : runNDFuel 3 (nd_bind_lemFuel b fork next) 0 =
    [(Active 107, [], 35), (Active 105, [], 31)] := by subst b; rfl

theorem bind_independent_budgets (r b : Nat) (hr : 3 ≤ r) (hb : 3 ≤ b) :
    runNDFuel r (nd_bind_lemFuel b fork next) 0 =
      [(Active 107, [], 35), (Active 105, [], 31)] :=
  (nd_bind_lemFuel_stable hr hb fork next 0).exhaustive (by
    rw [bind_complete _ rfl]; simp [NoFuel, IsFuel])

theorem bind_shared_budget (n : Nat) (h : 3 ≤ n) :
    @runND _ _ _ _ _ ⟨n⟩ (@nd_bind _ _ _ _ _ _ ⟨n⟩ fork next) 0 =
      [(Active 107, [], 35), (Active 105, [], 31)] :=
  (nd_bind_stable h fork next 0).exhaustive (by
    simp only [nd_bind]
    rw [bind_complete _ rfl]; simp [NoFuel, IsFuel])

def get (s : Nat × Nat) : Nat := s.2
def put (s : Nat × Nat) (u : Nat) : Nat × Nat := (s.1 + 1, u)
def lifted (b : Nat) : ndM Nat String Unit Unit (Nat × Nat) :=
  liftND_lemFuel b get put id id fork

theorem lift_one_is_exhausted_after_update : runNDFuel 1 (lifted 1) (0, 0) =
    [(Killed (1, 10) fuelExhaustedKill, [], (1, 10))] := rfl

theorem lift_complete : runNDFuel 3 (lifted 6) (0, 0) =
    [(Active 7, [], (3, 15)), (Active 5, [], (2, 11))] := rfl

theorem lift_independent_budgets (r b : Nat) (hr : 3 ≤ r) (hb : 6 ≤ b) :
    runNDFuel r (lifted b) (0, 0) =
      [(Active 7, [], (3, 15)), (Active 5, [], (2, 11))] :=
  (liftND_lemFuel_stable hr hb get put id id fork (0, 0)).exhaustive (by
    change NoFuel (runNDFuel 3 (lifted 6) (0, 0))
    rw [lift_complete]; simp [NoFuel, IsFuel])

def action : nd_action Nat String Unit Unit Nat :=
  NDbranch "lift action" () (leaf 8 1) (leaf 8 2)
def liftedAction (b : Nat) : ndM Nat String Unit Unit (Nat × Nat) :=
  ND (fun s => (liftAction_lemFuel b get put id id action, s))

theorem liftAction_complete : runNDFuel 2 (liftedAction 3) (0, 0) =
    [(Active 8, [], (1, 1)), (Active 8, [], (1, 2))] := rfl

theorem liftAction_independent_budgets (r b : Nat) (hr : 2 ≤ r) (hb : 3 ≤ b) :
    runNDFuel r (liftedAction b) (0, 0) =
      [(Active 8, [], (1, 1)), (Active 8, [], (1, 2))] :=
  (liftAction_lemFuel_stable hr hb get put id id action (0, 0)).exhaustive (by
    change NoFuel (runNDFuel 2 (liftedAction 3) (0, 0))
    rw [liftAction_complete]; simp [NoFuel, IsFuel])

def failure (r : kill_reason Unit) : M := ND (fun s => (NDkilled r, s + 9))

theorem typed_failure_stable (n : Nat) (h : 1 ≤ n) :
    runNDFuel n (failure (Other ())) 0 = [(Killed 9 (Other ()), [], 9)] :=
  runNDFuel_stable h _ 0 (by simp [runNDFuel, failure, NoFuel, IsFuel, fuelExhaustedKill])

/-- A distinct message suffices here; the location atom is deliberately
the SAME opaque fuel atom. The premise never guesses atom inequality. -/
theorem ordinary_error_stable (n : Nat) (h : 1 ≤ n) :
    runNDFuel n (failure (Error0 fuelExhaustedLoc "ordinary")) 0 =
      [(Killed 9 (Error0 fuelExhaustedLoc "ordinary"), [], 9)] :=
  runNDFuel_stable h _ 0 (by
    simp [runNDFuel, failure, NoFuel, IsFuel, fuelExhaustedKill, fuelExhaustedMsg])

/-- Rebuilding an arbitrary operand with a different captured instance is
outside the fixed-operand theorem, even when both observations complete. -/
def captured [LemFuel] : M := leaf LemFuel.fuel 0

theorem captured_inputs_can_change (n k : Nat) (hn : 0 < n) (hk : 0 < k) (hne : n ≠ k) :
    @runND _ _ _ _ _ ⟨n⟩ (@captured ⟨n⟩) 0 ≠
      @runND _ _ _ _ _ ⟨k⟩ (@captured ⟨k⟩) 0 := by
  cases n <;> cases k <;> simp_all [runND, runNDFuel, captured, leaf]

end NDFuelStabilityTest
