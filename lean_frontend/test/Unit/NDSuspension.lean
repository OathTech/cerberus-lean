import CerbNDSuspension
import Unit.NDFuelStabilityTest

open CerbND
private abbrev M := ndM Nat String Unit Unit Nat

private def resumed : M := ND fun state => (NDactive state, state + 10)
private def suspended : M := ND fun state => (NDsuspend resumed, state + 1)
private def failed : M := ND fun state =>
  (NDsuspend (ND fun later => (NDkilled (Other ()), later + 10)), state + 1)

private def controls (fuel : Nat) : List (String × Bool) := Id.run do
  letI := LemFuel.mk fuel
  let first := CerbNDSuspension.node suspended 0
  let usesCurrentState := match first.1 with
    | NDsuspend continuation => first.2 == 1 && match CerbNDSuspension.node continuation 100 with
      | (NDactive value, after) => value == 100 && after == 110
      | _ => false
    | _ => false
  let bound := CerbNDSuspension.node (nd_bind suspended (fun value =>
    ND fun state => (NDactive (value + 7), state + 20))) 0
  let bindPauses := match bound.1 with
    | NDsuspend continuation => bound.2 == 1 &&
        runNDFuel fuel continuation 100 == [(Active 107, [], 130)]
    | _ => false
  let lift := fun m => lift_checked_lemFuel fuel Prod.snd
    (fun (outer : Nat × Nat) inner => (outer.1, inner)) id id
    (fun (state : Nat × Nat) => (none, (state.1 + 1, state.2))) m
  let checked := lift suspended
  let checkedFailure := lift failed
  let reject := lift_checked_lemFuel fuel Prod.snd
    (fun (outer : Nat × Nat) inner => (outer.1, inner)) id id
    (fun (state : Nat × Nat) => (some (Other ()), (state.1 + 1, state.2))) suspended
  let duplicate : M := ND fun state => (NDnd "two" [("one", suspended), ("two", suspended)], state)
  return [
    ("typed suspension resumes against the supplied current state", usesCurrentState),
    ("bind retains the pause and composes only its continuation", bindPauses),
    ("generic exhaustive and selected runners resume the actual continuation",
      runNDFuel fuel suspended 0 == [(Active 1, [], 11)] && runND1Fuel fuel suspended 0 == [(Active 1, [], 11)]),
    ("checked lifting observes both the suspended prefix and resumed node",
      runNDFuel fuel checked (0, 0) == [(Active 1, [], (2, 11))]),
    ("resumed failure keeps both post-state observations and failure-time state",
      runNDFuel fuel checkedFailure (0, 0) == [(Killed (2, 11) (Other ()), [], (2, 11))]),
    ("a failed post-check prevents the suspended continuation from running",
      runNDFuel fuel reject (0, 0) == [(Killed (1, 1) (Other ()), [], (1, 1))]),
    ("suspension does not deduplicate equal branch outcomes",
      runNDFuel fuel duplicate 0 == [(Active 1, [], 11), (Active 1, [], 11)]),
    ("trace runner names the typed suspension and preserves the result",
      runND1TraceFuel id fuel suspended 0 == (["NDsuspend", "NDactive"], [(Active 1, [], 11)]))]

def main (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let mut good := true
  for (label, pass) in controls fuel do
    IO.println s!"{label}: {pass}"
    good := good && pass
  return if good then 0 else 1
