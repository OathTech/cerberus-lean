import ChoiceRunner
import ObservationShared

namespace CoreBDiff

open Lean

def killPayload {err : Type} (encodeError : err → Json) : kill_reason err → Json
  | .Undef0 loc reasons => Json.mkObj [
      ("kind", toJson "undefined"), ("location", toJson loc), ("reasons", toJson reasons)]
  | .Error0 loc message => Json.mkObj [
      ("kind", toJson "error"), ("location", toJson loc), ("message", toJson message)]
  | .Other error => Json.mkObj [("kind", toJson "other"), ("error", encodeError error)]

/-- Complete UB is a completed observation. Other model kills are separately
    classified failures; they must not contribute defined C coverage. -/
def completeKind {a err : Type} : Choice.Outcome a err → Option String
  | .returned _ => some "defined"
  | .killed (.Undef0 _ (_ :: _)) => some "undefined"
  | .killed _ => some "model-error"
  | .empty | .incomplete _ | .refused _ | .inputError _ | .replayMismatch _ | .observationError _ => none

def encodeOutcome {a err st : Type} (encodeResult : a → Except String Json)
    (encodeError : err → Json) (streams : st → String × String)
    (run : Choice.Run a err st) : Except String Json := do
  let (stdout, stderr) := streams run.finalState
  let failure (kind reason : String) := Json.mkObj [
    ("kind", toJson kind), ("reason", toJson reason),
    ("stdout", toJson stdout), ("stderr", toJson stderr)]
  match run.outcome with
  | .returned value => return Json.mkObj [("kind", toJson "defined"), ("result", ← encodeResult value)]
  | .killed reason => return Json.mkObj [
      ("kind", toJson (completeKind run.outcome)), ("reason", killPayload encodeError reason),
      ("stdout", toJson stdout), ("stderr", toJson stderr)]
  | .empty => return failure "incomplete" "empty nondeterministic frontier"
  | .incomplete reason => return failure "incomplete" reason
  | .refused reason => return failure "refused" reason
  | .inputError reason => return failure "input-error" reason
  | .replayMismatch reason => return failure "replay-mismatch" reason
  | .observationError reason => return failure "observation-error" reason

end CoreBDiff
