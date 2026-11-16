import ChoiceRunner
import CerbND

open Lean CoreNiceDiff.Choice

namespace CoreNiceDiff.Choice.Tests

abbrev Machine := ndM Nat String String Bool Nat

def header (origin : String := "core") : Header :=
  { input := "synthetic-input", prepared := "prepared-identity", config := toJson "test-config",
    coreBuild := "core-test-build", coreNiceBuild := "corenice-test-build", origin }

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

def replay (machine : Machine) (tape : Tape) (origin : String := "corenice") : Run Nat String Nat :=
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
  let reverse := record tree #[1] "corenice"
  let reversed := replay tree reverse.tape "core"
  require "B record/A replay" (valueOf reversed == some 21 && reversed.events == reverse.events)
  require "replay retains recorder provenance" (reversed.tape.header.origin == "corenice")
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
  let badHeader := replay tree
    { recorded.tape with header := { recorded.tape.header with coreNiceBuild := "wrong-build" } }
  require "invalid metadata never evaluates a node" (isInputError badHeader && badHeader.visited == 0 && badHeader.finalState == 0)
  let oldProtocol := replay tree
    { recorded.tape with header := { recorded.tape.header with version := 1 } }
  require "old protocol refuses before evaluation"
    (isInputError oldProtocol && oldProtocol.visited == 0 && oldProtocol.finalState == 0)
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
  let observationFailure := run 20 badObserver (.record .first) (header) tree 0
  require "observer errors fail closed" (match observationFailure.outcome with
    | .observationError "bad suffix" => observationFailure.visited == 1 && observationFailure.finalState == 1
    | _ => false)
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
  let observedBranch := [#[0], #[1]].filterMap fun indices => valueOf (record (branchTree false) indices)
  let exhaustiveBranch := (CerbND.runNDFuel 20 (branchTree false) 0).filterMap shippedValue
  require "empty-constraint branch calibration" (observedBranch == exhaustiveBranch)
  IO.println "choice-runner: all focused controls passed"

inductive Point where
  | before
  | after (first : Nat)
  | repeat
  | exhausted
  | error
  deriving BEq, ToJson

abbrev ResumableMachine := ndM (Active Nat Point) String String Bool Nat
abbrev ResumableProgress := Progress (Active Nat Point) Nat Point String String Bool Nat
abbrev ResumableSuspension := Suspension (Active Nat Point) Nat Point String String Bool Nat

private def pauseAt (point : Point) : ResumableMachine :=
  .ND fun state => (.NDactive (.pause point), state + 1)

private def doneAt (value : Nat) : ResumableMachine :=
  .ND fun state => (.NDactive (.done value), state + 1)

private def suffix (first : Nat) : ResumableMachine := .ND fun state =>
  (.NDstep "after" [("left", doneAt (first + 1)), ("right", doneAt (first + 2))], state + 1)

private def prefixMachine : ResumableMachine := .ND fun state =>
  (.NDnd "before" [("left", pauseAt (.after 100)), ("right", pauseAt (.after 200))], state + 1)

private def adapter : Adapter (Active Nat Point) Nat Point String String Bool Nat where
  classify := id
  describe := toJson
  continueFrom point := match point with
    | .before => prefixMachine
    | .after first => suffix first
    | .repeat => pauseAt .repeat
    | .exhausted => .ND fun state => (.NDactive (.incomplete "synthetic model budget"), state + 1)
    | .error => .ND fun state => (.NDkilled (.Other "after-pause failure"), state + 1)

/-- An ordinary runner reference with the same actions/choices. Its singleton
    node represents the administrative boundary without a host suspension. -/
private def uninterrupted : Machine :=
  let suffix first : Machine := .ND fun state =>
    (.NDstep "after" [("left", leaf (first + 1)), ("right", leaf (first + 2))], state + 1)
  let middle first : Machine := .ND fun state =>
    (.NDnd "administrative" [("only", suffix first)], state + 1)
  .ND fun state => (.NDnd "before" [("left", middle 100), ("right", middle 200)], state + 1)

private def expectPause (label : String) : ResumableProgress → IO ResumableSuspension
  | .suspended value => pure value
  | .complete _ => throw (IO.userError s!"choice-runner: FAILED {label}: expected nonterminal suspension")

private def expectComplete (label : String) : ResumableProgress → IO (Run Nat String Nat)
  | .complete value => pure value
  | .suspended _ => throw (IO.userError s!"choice-runner: FAILED {label}: expected completion")

private def deltas (events : Array Json) : Array Json :=
  events.filterMap fun event => (event.getObjVal? "observation").toOption

private def runResumable (fuel : Nat) (mode : Mode) (machine : ResumableMachine := prefixMachine) :
    ResumableProgress :=
  startResumable fuel observer mode header adapter machine 0

private def finishPauses : Nat → ResumableProgress → IO (Run Nat String Nat)
  | 0, _ => throw (IO.userError "choice-runner: FAILED pause loop exceeded test bound")
  | _, .complete value => pure value
  | count + 1, .suspended suspension => finishPauses count (resume suspension)

def resumableTests : IO Unit := do
  let reference := record uninterrupted #[1, 0]
  let middle ← expectPause "prefix with unused choice" (runResumable 20 (.record (.prefix #[1, 0])))
  require "midpoint data after first choice"
    (middle.point == .after 200 && middle.state == 2 && middle.visited == 2 && middle.remainingFuel == 18)
  require "prefix retained without finalizing tape"
    (middle.tape.entries.size == 1 && middle.events.size == 4)
  let pauseEvent ← match middle.events.back? with
    | some event => pure event
    | none => throw (IO.userError "choice-runner: missing pause event")
  require "nonterminal administrative descriptor"
    ((pauseEvent.getObjValAs? String "kind").toOption == some "pause" &&
      (pauseEvent.getObjVal? "parent").toOption == some (toJson (Point.after 200)))
  let finished ← expectComplete "resume after first choice" (resume middle)
  require "resume retains prefix and suffix choice"
    (valueOf finished == valueOf reference && finished.tape == reference.tape)
  require "resume retains state, observations and cumulative visits"
    (finished.finalState == reference.finalState && finished.visited == reference.visited &&
      deltas finished.events == deltas reference.events)
  let replayMiddle ← expectPause "replay has nonempty suffix" (runResumable 20 (.replay reference.tape))
  let replayFinished ← expectComplete "replay resumes" (resume replayMiddle)
  require "record/replay pause trace equality"
    (replayFinished.events == finished.events && replayFinished.tape == finished.tape)
  -- Deliberately restart a previous genuine choice instead of its saved suffix.
  -- The resumed session must reject the repeated descriptor at the next ordinal.
  let repeatsChoice := { adapter with continueFrom := fun _ => prefixMachine }
  let corruptMiddle ← expectPause "repeated-choice mutation checkpoint"
    (startResumable 20 observer (.replay reference.tape) header repeatsChoice prefixMachine 0)
  let corruptEnd ← expectComplete "repeated-choice mutation rejected" (resume corruptMiddle)
  require "resuming cannot consume an earlier genuine choice twice"
    (isMismatch corruptEnd && corruptEnd.tape.entries.size == 1 && corruptEnd.visited == 3)
  let before ← expectPause "pause before any choice"
    (runResumable 20 (.replay reference.tape) (pauseAt .before))
  require "entire tape survives early pause" (before.tape.entries.isEmpty && before.remainingFuel == 19)
  let beforeFinished ← finishPauses 5 (resume before)
  require "early and middle pauses consume choices exactly once"
    (valueOf beforeFinished == valueOf reference && beforeFinished.tape == reference.tape &&
      beforeFinished.visited == reference.visited + 1)
  for seed in [0, 1, 2, 12345] do
    let normal := run 20 observer (.record (.seeded seed)) header uninterrupted 0
    let paused ← finishPauses 5 (runResumable 20 (.record (.seeded seed)))
    require "RNG state survives pause"
      (paused.tape == normal.tape && valueOf paused == valueOf normal)
  let unusedPrefix ← expectPause "unused prefix deferred"
    (runResumable 20 (.record (.prefix #[1, 0, 1])))
  let unusedEnd ← expectComplete "unused prefix at completion" (resume unusedPrefix)
  require "unused prefix fails only at real completion" (isInputError unusedEnd)
  let firstEntry ← match reference.tape.entries[0]? with
    | some entry => pure entry
    | none => throw (IO.userError "choice-runner: missing reference tape entry")
  let extra := { firstEntry with ordinal := reference.tape.entries.size }
  let surplusTape := { reference.tape with entries := reference.tape.entries.push extra }
  let surplusMiddle ← expectPause "surplus tape deferred" (runResumable 20 (.replay surplusTape))
  let surplusEnd ← expectComplete "surplus tape at completion" (resume surplusMiddle)
  require "unused tape fails only at real completion" (isMismatch surplusEnd)
  let bounded ← expectPause "last traversal unit reaches pause"
    (runResumable 2 (.record (.prefix #[1, 0])))
  require "remaining fuel reaches zero" (bounded.remainingFuel == 0 && bounded.visited == 2)
  let exhaustedResume ← expectComplete "resume cannot replenish fuel" (resume bounded)
  require "exhaustion retains partial session without surplus check"
    (isIncomplete exhaustedResume && exhaustedResume.visited == 2 && exhaustedResume.finalState == 2 &&
      exhaustedResume.tape.entries.size == 1)
  let loopEnd ← finishPauses 10 (runResumable 4 (.record .first) (pauseAt .repeat))
  require "repeated pauses remain cumulatively bounded"
    (isIncomplete loopEnd && loopEnd.visited == 4 && loopEnd.finalState == 4 && loopEnd.tape.entries.isEmpty)
  let modelBudget ← expectPause "model budget checkpoint"
    (runResumable 20 (.replay reference.tape) (pauseAt .exhausted))
  let modelEnd ← expectComplete "explicit model budget exhaustion" (resume modelBudget)
  require "model exhaustion is incomplete rather than terminal tape mismatch"
    (isIncomplete modelEnd && modelEnd.visited == 2 && modelEnd.finalState == 2)
  let failurePause ← expectPause "failure checkpoint" (runResumable 20 (.record .first) (pauseAt .error))
  let failureEnd ← expectComplete "failure after resume" (resume failurePause)
  require "semantic failure after resume remains visible" (match failureEnd.outcome with
    | .killed (.Other "after-pause failure") => failureEnd.finalState == 2 && failureEnd.visited == 2
    | _ => false)
  let badHeader := { reference.tape with header := { reference.tape.header with prepared := "wrong" } }
  let invalid ← expectComplete "resumable header validation" (runResumable 20 (.replay badHeader))
  require "invalid metadata never runs resumable action"
    (isInputError invalid && invalid.visited == 0 && invalid.finalState == 0)
  let badObserver := { observer with observeDelta := fun _ _ => .error "pause delta lost" }
  let badDelta ← expectComplete "pause observer failure"
    (startResumable 20 badObserver (.record .first) header adapter (pauseAt .before) 0)
  require "observer failure cannot become successful suspension" (match badDelta.outcome with
    | .observationError "pause delta lost" => badDelta.visited == 1 && badDelta.finalState == 1
    | _ => false)
  IO.println "choice-runner: resumable session controls passed"

end CoreNiceDiff.Choice.Tests

def main : IO Unit := do
  CoreNiceDiff.Choice.Tests.tests
  CoreNiceDiff.Choice.Tests.resumableTests
