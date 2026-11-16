import Incoming
import ObservationNice
import EntryCommon

/- Post-finalization corruptions of the actual generated program. The same
   production driver runs every case; no mock step or additional ND node is
   used. Only compact fault/coverage data leaves this executable. -/
namespace CoreNiceDiff.IncomingControl

open Lean CoreNice.Incoming

private def require (condition : Bool) (message : String) : IO Unit :=
  unless condition do fail message

private def unwrap {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error message => fail message

private abbrev Run := Choice.Run CoreNice.driver_result CoreNice.driver_error CoreNice.driver_state

private structure AnnotationStats where
  syntacticJumps : Nat := 0
  permittedOrigins : Nat := 0
  removedOrigins : Nat := 0
  affectedLabels : Nat := 0
  maxPermittedOrigins : Nat := 0
  zeroIncomingLabels : Nat := 0
  deriving ToJson

/-- Count the actual finalized artifact rather than the producer's summary. -/
private def annotationStats (inventory : List Procedure) : IO AnnotationStats := do
  let mut stats : AnnotationStats := {}
  let mut accounted := 0
  for procedure in inventory do
    stats := { stats with syntacticJumps := stats.syntacticJumps + procedure.jumps.length }
    for label in procedure.labels do
      let syntactic := procedure.jumps.filterMap fun jump =>
        if sameSymbol jump.target label.symbol then some jump.info.nice_jump_origin else none
      let allowed := label.info.nice_label_origins
      require (allowed.all syntactic.contains && allowed.eraseDups.length == allowed.length)
        "finalized incoming set is not a set of syntactic origins for its actual label"
      require (allowed.length <= syntactic.length) "incoming-set reduction count would be negative"
      accounted := accounted + syntactic.length
      stats := { stats with
        permittedOrigins := stats.permittedOrigins + allowed.length
        removedOrigins := stats.removedOrigins + (syntactic.length - allowed.length)
        affectedLabels := stats.affectedLabels + (if allowed.length < syntactic.length then 1 else 0)
        maxPermittedOrigins := max stats.maxPermittedOrigins allowed.length
        zeroIncomingLabels := stats.zeroIncomingLabels + (if allowed.isEmpty then 1 else 0) }
  require (accounted == stats.syntacticJumps) "label inventory does not account for every jump"
  require (stats.permittedOrigins <= stats.syntacticJumps &&
    stats.removedOrigins == stats.syntacticJumps - stats.permittedOrigins)
    "annotation origin totals disagree"
  return stats

private def tightenedTargets (inventory : List Procedure) : List (sym × sym) :=
  inventory.flatMap fun procedure => procedure.labels.filterMap fun label =>
    let syntactic := procedure.jumps.filter (fun jump => sameSymbol jump.target label.symbol)
    if label.info.nice_label_origins.length < syntactic.length
    then some (procedure.symbol, label.symbol) else none

private def run [LemFuel] (fuel : Nat) (expected : Choice.Header) (mode : Choice.Mode)
    (prepared : Prepared) (execution : ExecutionNice) : IO Run := do
  let observed ← unwrap (execution.capture true)
  let result ← (CerberusFresh.forceIO (fun () => Choice.run fuel ObservationNice.observer mode expected
    (observed.action prepared.argv) observed.state) : BaseIO _)
  return result

private def rebuild (prepared : Prepared) (execution : ExecutionNice)
    (file : CoreNice.file CoreNice.core_run_annotation) : ExecutionNice :=
  let (state, initialSupply) := CoreNice.initial_driver_state execution.translatedSupply
    prepared.addressSpaceTop prepared.runDigest file CerbFS.fs_initial_state
  { execution with file, state, initialSupply }

private def fault (result : Run) : IO CoreNice.nice_origin_fault :=
  match result.outcome with
  | .killed (.Other (.DErr_core_run (.NiceFault (.IncomingOriginDenied details)))) => pure details
  | _ => fail "corrupted generated artifact did not produce typed IncomingOriginDenied"

private def sameFault (label : String) (result : Run)
    (expected : CoreNice.nice_origin_fault) : IO Unit := do
  require ((← fault result) == expected) s!"{label}: fault payload differs from actual artifact"

private def observationPrefix (baseline stopped : Run) : IO Unit := do
  let baseDriver ← unwrap (traceDelta [] baseline.finalState.trace)
  let stoppedDriver ← unwrap (traceDelta [] stopped.finalState.trace)
  require (baseDriver.extract 0 stoppedDriver.size == stoppedDriver)
    "fault lost or changed an earlier driver observation"
  let baseMemory ← unwrap (receiptDelta (some []) baseline.finalState.layout_state.observations)
  let stoppedMemory ← unwrap (receiptDelta (some []) stopped.finalState.layout_state.observations)
  require (baseMemory.extract 0 stoppedMemory.size == stoppedMemory)
    "fault lost or changed an earlier memory observation"
  let baseOutput := ObservationNice.streams baseline.finalState
  let stoppedOutput := ObservationNice.streams stopped.finalState
  require (stoppedOutput.1.isPrefixOf baseOutput.1 && stoppedOutput.2.isPrefixOf baseOutput.2)
    "fault output is not a prefix of the original defined execution"
  require (baseline.tape.entries.extract 0 stopped.tape.entries.size == stopped.tape.entries)
    "fault occurred after a different nondeterministic choice prefix"

private def sameBeforeFault (discovery precise : Run) : IO Unit := do
  require (discovery.events == precise.events)
    "precise corruption changed pre-fault observation events or ND boundaries"
  require (discovery.tape.entries == precise.tape.entries)
    "precise corruption changed the used choice tape"
  let discoveryOutput := ObservationNice.streams discovery.finalState
  let preciseOutput := ObservationNice.streams precise.finalState
  require (discoveryOutput == preciseOutput) "precise corruption changed pre-fault output"

def check [LemFuel] (runtime input : String) (fuel top seed : Nat)
    (tightenedOnly : Bool) : IO Unit := do
  let prepared ← prepare runtime input top []
  let execution ← lowerNice prepared
  let inventory := inspectFile execution.file
  let stats ← annotationStats inventory
  let tightened := tightenedTargets inventory
  let selectedTarget := fun procedure label =>
    !tightenedOnly || tightened.any (fun target =>
      sameSymbol target.1 procedure && sameSymbol target.2 label)
  let runtimeJumps := (inventory.filter (·.sourceMap == "stdlib")).foldl
    (fun count procedure => count + procedure.jumps.length) 0
  let allJumps := inventory.foldl (fun count procedure => count + procedure.jumps.length) 0
  let expected : Choice.Header := {
    input := prepared.inputDigest
    prepared := prepared.identity.compress
    config := Json.mkObj [("fuel", toJson fuel), ("top", toJson top)]
    coreBuild := "incoming-control"
    coreNiceBuild := "incoming-control"
    origin := "CoreNice" }
  let mode : Choice.Mode := .record (.seeded seed.toUInt64)
  let baseline ← run fuel expected mode prepared execution
  match baseline.outcome with
  | .returned _ => pure ()
  | _ => fail "uncorrupted generated program did not complete with a defined result"
  let emptied := mapMetadataFile (fun _ _ info => info)
    (fun procedure label info => if selectedTarget procedure label
      then { info with nice_label_origins := [] } else info) execution.file
  let discovery ← run fuel expected mode prepared (rebuild prepared execution emptied)
  match discovery.outcome with
  | .returned value =>
    let .returned original := baseline.outcome | fail "baseline result disappeared"
    require ((← unwrap (ObservationNice.result value)) ==
      (← unwrap (ObservationNice.result original))) "empty incoming sets changed a no-jump outcome"
    require (discovery.events == baseline.events && discovery.tape.entries == baseline.tape.entries)
      "empty incoming sets changed observations without producing a checked-jump fault"
    emit (Json.mkObj [("incoming-control", toJson
      (if tightenedOnly then "no-executed-tightened-label" else "no-checked-jump")),
      ("selection", toJson (if tightenedOnly then "tightened" else "all")),
      ("syntacticJumps", toJson allJumps), ("runtimeSyntacticJumps", toJson runtimeJumps),
      ("annotationStats", toJson stats),
      ("executedFirstSiteWitnesses", toJson (0 : Nat))])
  | _ =>
    let first ← fault discovery
    require (selectedTarget first.fault_procedure first.fault_label)
      "fault destination was not selected for metadata corruption"
    let some procedure := inventory.find? (sameSymbol ·.symbol first.fault_procedure)
      | fail "fault refers to a procedure absent from finalized artifact"
    let some jump := procedure.jumps.find? (fun site =>
      site.info.nice_jump_origin == first.fault_jump.nice_jump_origin &&
      sameSymbol site.target first.fault_label)
      | fail "fault refers to a jump absent from finalized artifact"
    let some label := procedure.labels.find? (sameSymbol ·.symbol first.fault_label)
      | fail "fault refers to a label absent from finalized artifact"
    require (label.info.nice_label_origins.contains jump.info.nice_jump_origin)
      "uncorrupted finalized target does not admit its executed jump"
    let expectedFirst : CoreNice.nice_origin_fault := {
      fault_procedure := procedure.symbol
      fault_jump := jump.info
      fault_label := label.symbol
      fault_incoming := { label.info with nice_label_origins := [] } }
    sameFault "empty-set discovery" discovery expectedFirst
    observationPrefix baseline discovery
    -- The corruptions terminate earlier than the complete baseline; replay the
    -- exact used tape prefix rather than treating an unused suffix as a fault.
    let replay := Choice.Mode.replay discovery.tape
    let reducedInfo := { label.info with nice_label_origins :=
      label.info.nice_label_origins.filter (· != jump.info.nice_jump_origin) }
    let removed := mapMetadataFile (fun _ _ info => info)
      (fun proc target info =>
        if sameSymbol proc procedure.symbol && sameSymbol target label.symbol
        then reducedInfo else info) execution.file
    let denied ← run fuel expected replay prepared (rebuild prepared execution removed)
    sameFault "removed taken origin" denied { expectedFirst with fault_incoming := reducedInfo }
    sameBeforeFault discovery denied
    let fresh := procedure.jumps.foldl (fun n site => max n site.info.nice_jump_origin) 0 + 1
    require (!label.info.nice_label_origins.contains fresh) "fresh origin unexpectedly permitted"
    let changedJump := { jump.info with nice_jump_origin := fresh }
    let changed := mapMetadataFile
      (fun proc target info =>
        if sameSymbol proc procedure.symbol && sameSymbol target label.symbol &&
            info.nice_jump_origin == jump.info.nice_jump_origin
        then changedJump else info)
      (fun _ _ info => info) execution.file
    let wrong ← run fuel expected replay prepared (rebuild prepared execution changed)
    sameFault "fresh wrong origin" wrong { expectedFirst with
      fault_jump := changedJump, fault_incoming := label.info }
    sameBeforeFault discovery wrong
    emit (Json.mkObj [("incoming-control", toJson "passed"),
      ("selection", toJson (if tightenedOnly then "tightened" else "all")),
      ("syntacticJumps", toJson allJumps), ("runtimeSyntacticJumps", toJson runtimeJumps),
      ("annotationStats", toJson stats),
      ("executedFirstSiteWitnesses", toJson (1 : Nat)),
      ("typedFaultControls", toJson (3 : Nat)),
      ("usedChoices", toJson discovery.tape.entries.size),
      ("fault", toJson first)])

end CoreNiceDiff.IncomingControl

def main (args : List String) : IO UInt32 := do
  try
    unless (← IO.getEnv "LEAN_ABORT_ON_PANIC") == some "1" do
      CoreNiceDiff.fail "LEAN_ABORT_ON_PANIC=1 is required"
    let (baseArgs, tightenedOnly) ← match args with
      | [runtime, input, fuelText, topText, seedText] =>
        pure ([runtime, input, fuelText, topText, seedText], false)
      | [runtime, input, fuelText, topText, seedText, "all"] =>
        pure ([runtime, input, fuelText, topText, seedText], false)
      | [runtime, input, fuelText, topText, seedText, "tightened"] =>
        pure ([runtime, input, fuelText, topText, seedText], true)
      | _ => CoreNiceDiff.fail "usage: corenice-incoming-control RUNTIME_PREFIX CABS_JSON FUEL ADDRESS_SPACE_TOP SEED [all|tightened]"
    let [runtime, input, fuelText, topText, seedText] := baseArgs
      | CoreNiceDiff.fail "invalid normalized incoming-control arguments"
    let some fuel := fuelText.toNat? | CoreNiceDiff.fail "FUEL must be natural"
    let some top := topText.toNat? | CoreNiceDiff.fail "ADDRESS_SPACE_TOP must be natural"
    let some seed := seedText.toNat? | CoreNiceDiff.fail "SEED must be natural"
    if seed > 18446744073709551615 then CoreNiceDiff.fail "SEED must fit UInt64"
    @CoreNiceDiff.IncomingControl.check ⟨fuel⟩ runtime input fuel top seed tightenedOnly
    return 0
  catch error =>
    CoreNiceDiff.emit (Lean.Json.mkObj [("incoming-control", Lean.toJson "failed"),
      ("reason", Lean.toJson error.toString)])
    return 2
