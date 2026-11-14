import ObservationA
import ObservationB
import EntryCommon

/- Executable instrument tests: these validate observation discrimination and
   failure classification, and make no theorem claim about either machine. -/

namespace CoreBDiff.ObservationChecks

open Lean

private def check (label : String) (condition : Bool) : IO Unit :=
  unless condition do throw (IO.Error.userError s!"observation check failed: {label}")

private def get {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error reason => throw (IO.Error.userError reason)

private def failed {α : Type} : Except String α → Bool
  | .error _ => true
  | .ok _ => false

private def pointer (allocation address : Int) : CerbMem.PointerValue :=
  .PV (.Prov_some allocation) (.PVconcrete none address)

private def event (allocation address : Int) : trace_event :=
  .ME_kill .unknown false (pointer allocation address)

private def sampleHeader : Choice.Header := {
  input := "input"
  prepared := "prepared"
  config := .null
  coreBuild := "A"
  coreBBuild := "B"
  origin := "Core" }

def tests : IO Unit := do
  let first := event 1 100
  let second := event 2 200
  let third := event 3 300
  let encodedFirst ← get (traceEvent first)
  let encodedSecond ← get (traceEvent second)
  let encodedThird ← get (traceEvent third)
  check "pointer address retained" (encodedFirst != (← get (traceEvent (event 1 101))))
  check "pointer provenance retained" (encodedFirst != (← get (traceEvent (event 2 100))))
  check "integer provenance retained"
    (toJson (CerbMem.IntegerValue.IV (.Prov_some 1) 3) !=
     toJson (CerbMem.IntegerValue.IV (.Prov_some 2) 3))
  check "symbol digest retained"
    (toJson (sym.Symbol "one" 1 (.SD_Id "x")) != toJson (sym.Symbol "two" 1 (.SD_Id "x")))
  check "symbol ordinal retained"
    (toJson (sym.Symbol "one" 1 (.SD_Id "x")) != toJson (sym.Symbol "one" 2 (.SD_Id "x")))
  check "new events emitted in execution order"
    ((← get (traceDelta [first] [third, second, first])) == #[encodedSecond, encodedThird])
  check "old events not re-emitted" ((← get (traceDelta [first] [first])) == #[])
  check "first event not lost" ((← get (traceDelta [] [first])) == #[encodedFirst])
  check "trace shrink refused" (failed (traceDelta [second, first] [first]))
  check "trace replacement refused" (failed (traceDelta [first] [second]))
  check "duplicate labels retained"
    (ObservationA.stepInfo (.SK_misc ["x", "x"]) != ObservationA.stepInfo (.SK_misc ["x"]))
  check "A/B step payload shapes match"
    (ObservationA.stepInfo (.SK_misc ["x", "x"]) == ObservationB.stepInfo (.SK_misc ["x", "x"]))
  let valueA : value := .Vtuple [.Vunit, .Vobject (.OVpointer (pointer 9 32)), .Vtrue]
  let valueB : CoreB.value := .Vtuple [.Vunit, .Vobject (.OVpointer (pointer 9 32)), .Vtrue]
  check "A/B result payload shapes match"
    ((← get (ObservationA.coreValue valueA)) == (← get (ObservationB.coreValue valueB)))
  check "signed zero retained" ((← get (floatPayload 0.0)) != (← get (floatPayload (-0.0))))
  check "unrepresentable NaN payload refused" (failed (floatPayload (0.0 / 0.0)))
  let reasons : List undefined_behaviour := [.UB001, .DUMMY "first", .DUMMY "second"]
  let reason : kill_reason String := .Undef0 .unknown reasons
  let encoded := killPayload toJson reason
  check "all UB reasons retained" ((← get (encoded.getObjVal? "reasons")) == toJson reasons)
  check "UB reason order retained"
    (encoded != killPayload toJson (.Undef0 .unknown reasons.reverse : kill_reason String))
  let run : Choice.Run Unit String (String × String) := {
    outcome := .killed reason
    finalState := ("before UB\n", "diagnostic\n")
    tape := { header := sampleHeader, entries := #[] }
    events := #[]
    visited := 1 }
  let outcome ← get (encodeOutcome (fun _ => .ok .null) toJson id run)
  check "UB preserves stdout" ((← get (outcome.getObjVal? "stdout")) == toJson "before UB\n")
  check "UB preserves stderr" ((← get (outcome.getObjVal? "stderr")) == toJson "diagnostic\n")
  check "nonempty UB classified complete" (completeKind run.outcome == some "undefined")
  check "empty UB is model error"
    (completeKind (Choice.Outcome.killed (.Undef0 .unknown []) : Choice.Outcome Unit String) == some "model-error")
  check "fuel exhaustion incomplete"
    ((completeKind (.incomplete "fuel" : Choice.Outcome Unit String)).isNone)
  check "empty ND incomplete" ((completeKind (.empty : Choice.Outcome Unit String)).isNone)
  let cli := ["--runtime", "runtime", "--input", "input", "--tape", "tape",
    "--mode", "record", "--fuel", "100", "--core-build", "A", "--coreb-build", "B"]
  check "LP64 maximum admitted" (!(failed (parseOptions (cli ++ ["--address-space-top", "18446744073709551615"]))))
  check "LP64 overflow refused" (failed (parseOptions (cli ++ ["--address-space-top", "18446744073709551616"])))
  check "nondecimal top refused" (failed (parseOptions (cli ++ ["--address-space-top", "1_000"])))
  check "zero top refused" (failed (parseOptions (cli ++ ["--address-space-top", "0"])))
  check "unsupported recipe option refused"
    (failed (parseOptions (cli ++ ["--address-space-top", "1000", "--switches", "PNVI"])))
  IO.println "Core/CoreB observation checks passed (28 checks)"

end CoreBDiff.ObservationChecks

def main : IO Unit := CoreBDiff.ObservationChecks.tests
