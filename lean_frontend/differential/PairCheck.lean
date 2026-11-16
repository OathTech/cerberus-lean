import ArtifactCompare
import ObservationA
import ObservationNice
import EntryCommon
import CerbND

/- Focused acceptance helper. One Prepared value feeds both lowerers. It checks
   complete pre-execution artifact correspondence, then calibrates actual C
   executions with capture enabled against existing first-path and exhaustive
   CerbND runners with capture disabled. The comparison projection erases only
   diagnostic capture data. Exhaustive mode is intentionally for small finite fixtures: MAX_PATHS bounds
   our replay enumeration, while the caller must cap/time-limit the process. -/

namespace CoreNiceDiff.PairCheck
open Lean

private def unwrap {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error reason => fail reason

private def require (condition : Bool) (reason : String) : IO Unit :=
  unless condition do fail reason

/-- Projection shared with the existing runner: complete outcome/streams and
    original Driver.trace. Diagnostic instrumentation fields are erased. -/
private def project {a err st : Type} (encodeResult : a → Except String Json)
    (encodeError : err → Json) (streams : st → String × String)
    (trace : st → List trace_event) (run : Choice.Run a err st) : Except String Json := do
  unless (completeKind run.outcome).isSome do throw "calibration execution is incomplete/refused"
  if completeKind run.outcome == some "model-error" then
    throw "calibration encountered a model error"
  return Json.mkObj [("outcome", ← encodeOutcome encodeResult encodeError streams run),
    ("trace", toJson (← traceDelta [] (trace run.finalState)))]

private def fromOld {a err st : Type} (expected : Choice.Header)
    (row : nd_status a err st × List String × st) : Except String (Choice.Run a err st) := do
  let (status, _, state) := row
  let (outcome, finalState) ← match status with
    | .Active value => pure (Choice.Outcome.returned value, state)
    | .Killed killedState reason =>
      if exhausted reason then throw "existing CerbND exhausted its budget"
      else pure (.killed reason, killedState)
  return {
    outcome := outcome
    finalState := finalState
    tape := { header := expected, entries := #[] }
    events := #[]
    visited := 0 }

private def removeFirst (value : Json) : List Json → Option (List Json)
  | [] => none
  | x :: xs => if x == value then some xs else (removeFirst value xs).map (x :: ·)

private def sameMultiset : List Json → List Json → Bool
  | [], ys => ys.isEmpty
  | x :: xs, ys => match removeFirst x ys with
    | none => false
    | some rest => sameMultiset xs rest

/-- Every discovered branching suffix is explored. Forced prefix choices are
    not re-enqueued; duplicate-labelled alternatives remain distinct paths. -/
private def enumerate {a info err cs st : Type} (fuel maxPaths : Nat)
    (observer : Choice.Observer info err cs st) (expected : Choice.Header)
    (machine : ndM a info err cs st) (state : st)
    (projection : Choice.Run a err st → Except String Json) : IO (List Json) := do
  let mut pending : List (Array Nat) := [#[]]
  let mut outputs : List Json := []
  for _ in [:maxPaths] do
    match pending with
    | [] => pure ()
    | forced :: rest =>
      pending := rest
      let run ← (CerberusFresh.forceIO (fun () =>
        Choice.run fuel observer (.record (.prefix forced)) expected machine state) : BaseIO _)
      outputs := (← unwrap (projection run)) :: outputs
      let actual := run.tape.entries.map (·.index)
      for entry in run.tape.entries do
        if entry.ordinal >= forced.size then
          for index in [1:entry.alternatives.size] do
            pending := (actual.extract 0 entry.ordinal |>.push index) :: pending
  unless pending.isEmpty do fail s!"calibration exceeds MAX_PATHS={maxPaths}"
  return outputs.reverse

private def calibrate {a info err cs st : Type} (fuel maxPaths : Nat)
    (observer : Choice.Observer info err cs st) (expected : Choice.Header)
    (machine : ndM a info err cs st) (state : st)
    (referenceMachine : ndM a info err cs st) (referenceState : st)
    (projection : Choice.Run a err st → Except String Json) : IO (List Json) := do
  let first ← (CerberusFresh.forceIO (fun () =>
    Choice.run fuel observer (.record .first) expected machine state) : BaseIO _)
  let firstProjection ← unwrap (projection first)
  let oldFirst ← (CerberusFresh.forceIO (fun () => CerbND.runND1Fuel fuel referenceMachine referenceState) : BaseIO _)
  let [row] := oldFirst | fail "existing first-path runner returned other than one complete result"
  let expectedFirst ← unwrap ((fromOld expected row).bind projection)
  require (firstProjection == expectedFirst) "choice runner disagrees with CerbND branch zero"
  let results ← enumerate fuel maxPaths observer expected machine state projection
  let oldResults ← (CerberusFresh.forceIO (fun () => CerbND.runNDFuel fuel referenceMachine referenceState) : BaseIO _)
  require (!oldResults.isEmpty) "existing exhaustive runner returned no executions"
  require (oldResults.length <= maxPaths) "existing exhaustive runner exceeds MAX_PATHS"
  let oldProjected ← unwrap (oldResults.mapM fun row => (fromOld expected row).bind projection)
  -- CerbND enumerates NDnd/NDstep in reverse branch order and NDbranch in
  -- forward order. This helper promises a complete multiset, not that order.
  require (sameMultiset results oldProjected) "choice enumeration differs from all CerbND results"
  return results

def check (runtime input : String) (fuel top maxPaths : Nat) : IO Unit := do
  require (maxPaths > 0) "MAX_PATHS must be positive"
  let prepared ← @prepare ⟨fuel⟩ runtime input top []
  let a ← @lowerA ⟨fuel⟩ prepared
  let b ← @lowerNice ⟨fuel⟩ prepared
  unwrap (ArtifactCompare.compare a b)
  require a.file.main.isSome "paired execution calibration requires a main entry"
  let changedMain := { b with file := { b.file with main := none } }
  let .error _ := ArtifactCompare.compare a changedMain
    | fail "artifact comparator accepted the injected main-entry difference"
  let changedSupply := { b with translatedSupply := b.translatedSupply + 1 }
  let .error _ := ArtifactCompare.compare a changedSupply
    | fail "artifact comparator accepted the injected fresh-supply difference"
  let observedA ← unwrap (a.capture true)
  let observedB ← unwrap (b.capture true)
  let referenceA ← unwrap (a.capture false)
  let referenceB ← unwrap (b.capture false)
  let expected : Choice.Header := {
    input := prepared.inputDigest
    prepared := prepared.identity.compress
    config := Json.mkObj [("fuel", toJson fuel), ("top", toJson top)]
    coreBuild := "in-process-paired-check"
    coreNiceBuild := "in-process-paired-check"
    origin := "paired" }
  let resultsA ← calibrate fuel maxPaths ObservationA.observer expected
    (@ExecutionA.action ⟨fuel⟩ observedA prepared.argv) observedA.state
    (@ExecutionA.action ⟨fuel⟩ referenceA prepared.argv) referenceA.state
    (project ObservationA.result toJson ObservationA.streams (·.trace))
  let resultsB ← calibrate fuel maxPaths ObservationNice.observer expected
    (@ExecutionNice.action ⟨fuel⟩ observedB prepared.argv) observedB.state
    (@ExecutionNice.action ⟨fuel⟩ referenceB prepared.argv) referenceB.state
    (project ObservationNice.result toJson ObservationNice.streams (·.trace))
  require (sameMultiset resultsA resultsB) "Core/CoreNice exhaustive observation multisets differ"
  emit (Json.mkObj [("paired-artifact", toJson "equal"),
    ("artifact-negative-controls", toJson (2 : Nat)),
    ("branch-zero-calibration", toJson "equal"), ("all-results-calibration", toJson "equal"),
    ("capture-erasure-calibration", toJson "equal"),
    ("pathsA", toJson resultsA.length), ("pathsB", toJson resultsB.length),
    ("translationSupply", toJson a.translatedSupply), ("initialSupply", toJson a.initialSupply)])

end CoreNiceDiff.PairCheck

def main (args : List String) : IO UInt32 := do
  try
    unless (← IO.getEnv "LEAN_ABORT_ON_PANIC") == some "1" do
      CoreNiceDiff.fail "LEAN_ABORT_ON_PANIC=1 is required"
    let [runtime, input, fuelText, topText, pathsText] := args
      | CoreNiceDiff.fail "usage: corenice-pair-check RUNTIME_PREFIX CABS_JSON FUEL ADDRESS_SPACE_TOP MAX_PATHS"
    let some fuel := fuelText.toNat? | CoreNiceDiff.fail "FUEL must be a natural number"
    let some top := topText.toNat? | CoreNiceDiff.fail "ADDRESS_SPACE_TOP must be a natural number"
    let some paths := pathsText.toNat? | CoreNiceDiff.fail "MAX_PATHS must be a natural number"
    CoreNiceDiff.PairCheck.check runtime input fuel top paths
    return 0
  catch error =>
    CoreNiceDiff.emit (Lean.Json.mkObj [("paired-check", Lean.toJson "failed"),
      ("reason", Lean.toJson error.toString)])
    return 2
