import ChoiceRunner
import CerbND

open Lean CoreBDiff.Choice

namespace CoreBDiff.Choice.Tests

abbrev Machine := ndM Nat String String Bool Nat

def header (origin : String := "core") : Header :=
  { input := "synthetic-input", prepared := "prepared-identity", config := toJson "test-config",
    coreBuild := "core-test-build", coreBBuild := "coreb-test-build", origin }

def observer : Observer String String Bool Nat where
  encodeInfo label := Json.mkObj [("label", toJson label)]
  observeDelta before after :=
    if after == before + 1 then .ok #[Json.mkObj [("state-counter", toJson after)]]
    else .error "state did not advance exactly once"
  isExhaustion reason := match reason with
    | .Error0 loc msg => loc == CerbFuel.fuelExhaustedLoc && msg == CerbFuel.fuelExhaustedMsg
    | _ => false
  isTrivialConstraint constraint := !constraint

def leaf (value : Nat) : Machine := .ND fun state => (.NDactive value, state + 1)

def nested : Machine := .ND fun state =>
  (.NDstep "nested" [("same", leaf 11), ("same", leaf 12)], state + 1)

def tree : Machine := .ND fun state =>
  (.NDnd "root" [("duplicate", nested), ("duplicate", leaf 21), ("other", leaf 31)], state + 1)

def duplicateTree (swapped : Bool) : Machine := .ND fun state =>
  (.NDnd "duplicates" (if swapped then [("same", leaf 20), ("same", leaf 10)]
    else [("same", leaf 10), ("same", leaf 20)]), state + 1)

def singleton : Machine := .ND fun state => (.NDnd "singleton" [("only", tree)], state + 1)

def guardTree (constraint : Bool) : Machine := .ND fun state =>
  (.NDguard "guard" constraint (leaf 7), state + 1)

def branchTree (constraint : Bool) : Machine := .ND fun state =>
  (.NDbranch "branch" constraint (leaf 8) (leaf 9), state + 1)

def killed : Machine := .ND fun state => (.NDkilled (.Other "model error"), state + 1)

def exhausted : Machine := .ND fun state =>
  (.NDkilled (.Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg), state + 1)

def valueOf (run : Run Nat String Nat) : Option Nat :=
  match run.outcome with
  | .returned value => some value
  | _ => none

def isMismatch (run : Run Nat String Nat) : Bool :=
  match run.outcome with | .replayMismatch _ => true | _ => false

def isInputError (run : Run Nat String Nat) : Bool :=
  match run.outcome with | .inputError _ => true | _ => false

def isIncomplete (run : Run Nat String Nat) : Bool :=
  match run.outcome with | .incomplete _ => true | _ => false

def isRefused (run : Run Nat String Nat) : Bool :=
  match run.outcome with | .refused _ => true | _ => false

def record (machine : Machine) (indices : Array Nat) (origin : String := "core") : Run Nat String Nat :=
  run 20 observer (.record (.prefix indices)) (header origin) machine 0

def replay (machine : Machine) (tape : Tape) (origin : String := "coreb") : Run Nat String Nat :=
  run 20 observer (.replay tape) (header origin) machine 0

def require (label : String) (condition : Bool) : IO Unit :=
  unless condition do throw (IO.userError s!"choice-runner: FAILED {label}")

def shippedValue : nd_status Nat String Nat × List String × Nat → Option Nat
  | (.Active value, _, _) => some value
  | _ => none

def tests : IO Unit := do
  let recorded := record tree #[0, 1]
  require "nonzero nested index" (valueOf recorded == some 12)
  require "two choices, no duplicate label collapse" (recorded.tape.entries.size == 2)
  let first ← match recorded.tape.entries[0]? with
    | some entry => pure entry
    | none => throw (IO.userError "choice-runner: missing first recorded entry")
  require "ordered duplicate descriptors retained"
    (first.alternatives.size == 3 && first.alternatives[0]? == first.alternatives[1]?)
  require "state and visited nodes" (recorded.finalState == 3 && recorded.visited == 3)
  require "delta and node events" (recorded.events.size == 6)
  let replayed := replay tree recorded.tape
  require "A record/B replay" (valueOf replayed == some 12 && replayed.events == recorded.events)
  let reverse := record tree #[1] "coreb"
  let reversed := replay tree reverse.tape "core"
  require "B record/A replay" (valueOf reversed == some 21 && reversed.events == reverse.events)
  require "replay retains recorder provenance" (reversed.tape.header.origin == "coreb")
  let once := record singleton #[1]
  require "singleton does not consume a choice" (valueOf once == some 21 && once.tape.entries.size == 1)
  require "missing replay choice" (isMismatch (replay tree { recorded.tape with entries := #[] }))
  let extra := { first with ordinal := reverse.tape.entries.size }
  require "surplus replay choice" (isMismatch (replay tree
    { reverse.tape with entries := reverse.tape.entries.push extra }))
  let malformed := { first with index := first.alternatives.size }
  require "invalid index is malformed input" (isInputError (replay tree
    { recorded.tape with entries := recorded.tape.entries.set! 0 malformed }))
  require "wrong ordinal is malformed input" (isInputError (replay tree
    { recorded.tape with entries := recorded.tape.entries.set! 0 { first with ordinal := 7 } }))
  require "header mismatch before evaluation" (isInputError (replay tree
    { recorded.tape with header := { recorded.tape.header with prepared := "wrong-input" } }))
  for changed in [
      { first with parent := toJson "different-parent" },
      { first with kind := .step },
      { first with alternatives := first.alternatives.reverse },
      { first with alternatives := first.alternatives.push (toJson "additional") }] do
    require "descriptor/kind/order/arity mutation" (isMismatch (replay tree
      { recorded.tape with entries := recorded.tape.entries.set! 0 changed }))
  let duplicates := record (duplicateTree false) #[1]
  let swapped := replay (duplicateTree true) duplicates.tape
  require "duplicate-label reordering is observable in outcome"
    (valueOf duplicates == some 20 && valueOf swapped == some 10)
  require "out-of-range recording prefix" (isInputError (record tree #[3]))
  require "unused recording prefix" (isInputError (record tree #[1, 0]))
  require "runner fuel exhaustion" (isIncomplete (run 1 observer (.record .first) (header) tree 0))
  require "model fuel exhaustion" (isIncomplete (record exhausted #[]))
  require "nontrivial guard refusal" (isRefused (record (guardTree true) #[]))
  require "nontrivial branch refusal" (isRefused (record (branchTree true) #[]))
  require "empty guard continuation" (valueOf (record (guardTree false) #[]) == some 7)
  let branch := record (branchTree false) #[1]
  require "empty-constraint branch alternatives" (valueOf branch == some 9 && branch.tape.entries.size == 1)
  require "branch replay" (valueOf (replay (branchTree false) branch.tape) == some 9)
  require "failure state retained" (match (record killed #[]).outcome with
    | .killed (.Other "model error") => (record killed #[]).finalState == 1
    | _ => false)
  let noBranches : Machine := .ND fun state => (.NDnd "empty" [], state + 1)
  require "empty frontier explicit" (match (record noBranches #[]).outcome with | .empty => true | _ => false)
  let badObserver := { observer with observeDelta := fun _ _ => .error "bad suffix" }
  require "observer errors fail closed" (match (run 20 badObserver (.record .first) (header) tree 0).outcome with
    | .observationError "bad suffix" => true | _ => false)
  let seeded := run 20 observer (.record (.seeded 12345)) (header) tree 0
  let repeated := run 20 observer (.record (.seeded 12345)) (header) tree 0
  require "seeded recording reproducible" (seeded.tape == repeated.tape && seeded.events == repeated.events)
  require "seeded replay" (valueOf (replay tree seeded.tape) == valueOf seeded)
  match (fromJson? (toJson recorded.tape) : Except String Tape) with
  | .error message => throw (IO.userError s!"choice-runner tape JSON roundtrip: {message}")
  | .ok decoded => require "tape JSON roundtrip" (decoded == recorded.tape)
  let firstValue := (CerbND.runND1Fuel 20 tree 0).head?.bind shippedValue
  require "branch-zero calibration against production runND1" (valueOf (record tree #[]) == firstValue)
  let observed := [#[0, 0], #[0, 1], #[1], #[2]].filterMap fun indices => valueOf (record tree indices)
  let exhaustive := (CerbND.runNDFuel 20 tree 0).filterMap shippedValue
  require "finite complete outcome multiset calibration"
    (observed.mergeSort (· ≤ ·) == exhaustive.mergeSort (· ≤ ·))
  IO.println "choice-runner: all focused controls passed"

end CoreBDiff.Choice.Tests

def main : IO Unit := CoreBDiff.Choice.Tests.tests
