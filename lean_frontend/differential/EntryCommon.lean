import Prepared
import RunOutput

namespace CoreBDiff

open Lean

structure Options where
  runtime : String
  input : String
  tape : String
  mode : String
  fuel : Nat
  addressSpaceTop : Int
  coreBuild : String
  coreBBuild : String
  seed : Option Nat
  choicePrefix : Option (Array Nat)
  args : List String

private def parsePairs : List String → List (String × String) → Except String (List (String × String))
  | [], acc => .ok acc.reverse
  | flag :: value :: rest, acc => do
    unless ["--runtime", "--input", "--tape", "--mode", "--fuel", "--address-space-top",
        "--core-build", "--coreb-build", "--seed", "--choices", "--arg"].contains flag do
      throw s!"unsupported option: {flag}"
    if flag != "--arg" && acc.any (fun entry => entry.1 == flag) then
      throw s!"duplicate option: {flag}"
    parsePairs rest ((flag, value) :: acc)
  | [_], _ => .error "every option requires a value"

def parseOptions (args : List String) : Except String Options := do
  let pairs ← parsePairs args []
  let get (flag : String) : Option String := (pairs.find? (·.1 == flag)).map Prod.snd
  let required (flag : String) : Except String String := do
    let some value := get flag | throw s!"missing required option: {flag}"
    if value.isEmpty then throw s!"empty required option: {flag}"
    return value
  let runtime ← required "--runtime"
  let input ← required "--input"
  let tape ← required "--tape"
  let mode ← required "--mode"
  unless mode == "record" || mode == "replay" do throw "--mode must be record or replay"
  let fuelText ← required "--fuel"
  let some fuel := fuelText.toNat? | throw "--fuel must be a natural number"
  let topText ← required "--address-space-top"
  unless !topText.isEmpty && topText.all Char.isDigit do
    throw "--address-space-top must contain decimal digits only"
  let some top := topText.toNat? | throw "--address-space-top must be a decimal integer"
  unless 0 < top && top < 18446744073709551616 do
    throw "--address-space-top must fit the LP64 pointer domain: 0 < top < 2^64"
  let addressSpaceTop : Int := top
  let coreBuild ← required "--core-build"
  let coreBBuild ← required "--coreb-build"
  let seed ← match get "--seed" with
    | none => pure none
    | some value =>
      match value.toNat? with
      | some seed =>
        if seed > 18446744073709551615 then throw "--seed exceeds UInt64"
        else pure (some seed)
      | none => throw "--seed must be a natural number"
  let choicePrefix ← match get "--choices" with
    | none => pure none
    | some value =>
      if value.isEmpty then pure (some #[])
      else
        let choices ← (value.splitOn ",").mapM fun choice =>
          match choice.toNat? with
          | some index => pure index
          | none => throw "--choices must be comma-separated natural numbers"
        pure (some choices.toArray)
  if seed.isSome && choicePrefix.isSome then throw "--seed and --choices are mutually exclusive"
  if mode == "replay" && (seed.isSome || choicePrefix.isSome) then
    throw "recording choice options are invalid in replay mode"
  return {
    runtime := runtime
    input := input
    tape := tape
    mode := mode
    fuel := fuel
    addressSpaceTop := addressSpaceTop
    coreBuild := coreBuild
    coreBBuild := coreBBuild
    seed := seed
    choicePrefix := choicePrefix
    args := pairs.filterMap (fun (key, value) => if key == "--arg" then some value else none) }

def Options.choiceMode (options : Options) : IO Choice.Mode := do
  if options.mode == "replay" then
    let text ← IO.FS.readFile options.tape
    let json ← match Json.parse text with
      | .ok value => pure value
      | .error error => fail s!"invalid tape JSON: {error}"
    match fromJson? json with
    | .ok tape => return .replay tape
    | .error error => fail s!"invalid choice tape: {error}"
  else if options.mode == "record" then
    match options.choicePrefix, options.seed with
    | some choicePrefix, none => return .record (.prefix choicePrefix)
    | none, some seed => return .record (.seeded seed.toUInt64)
    | none, none => return .record .first
    | some _, some _ => fail "--seed and --choices are mutually exclusive"
  else fail "--mode must be record or replay"

def header (origin : String) (options : Options) (prepared : Prepared)
    (translatedSupply initialSupply : Nat) : Choice.Header := {
  input := prepared.inputDigest
  prepared := prepared.identity.compress
  config := Json.mkObj [
    ("fuel", toJson options.fuel), ("addressSpaceTop", toJson prepared.addressSpaceTop),
    ("argv", toJson prepared.argv), ("switches", toJson ([] : List String)),
    ("libc", toJson false), ("observationSchema", toJson "boundary-channels-v1"),
    ("accessReceipts", toJson true), ("translationSupply", toJson translatedSupply),
    ("initialSupply", toJson initialSupply)]
  coreBuild := options.coreBuild
  coreBBuild := options.coreBBuild
  origin }

def emit (value : Json) : IO Unit := IO.println value.compress

/-- JSON-lines output has an explicit final record. EOF or process death is
    never completion. A valid matched model error remains a failed execution. -/
def finish {a err st : Type} (options : Options) (expected : Choice.Header)
    (encodeResult : a → Except String Json) (encodeError : err → Json)
    (streams : st → String × String) (run : Choice.Run a err st) : IO UInt32 := do
  emit (Json.mkObj [("record", toJson "header"), ("header", toJson expected)])
  for event in run.events do
    emit (Json.mkObj [("record", toJson "event"), ("event", event)])
  for choice in run.tape.entries do
    emit (Json.mkObj [("record", toJson "choice"), ("choice", toJson choice)])
  match encodeOutcome encodeResult encodeError streams run with
  | .error reason =>
    emit (Json.mkObj [("record", toJson "outcome"), ("outcome", Json.mkObj [
      ("kind", toJson "observation-error"), ("reason", toJson reason)])])
    emit (Json.mkObj [("record", toJson "end"), ("complete", toJson false),
      ("kind", Json.null), ("visited", toJson run.visited),
      ("choices", toJson run.tape.entries.size)])
    return 2
  | .ok outcome =>
    emit (Json.mkObj [("record", toJson "outcome"), ("outcome", outcome)])
    if options.mode == "record" then IO.FS.writeFile options.tape (toJson run.tape).compress
    let kind := completeKind run.outcome
    emit (Json.mkObj [("record", toJson "end"), ("complete", toJson kind.isSome),
      ("kind", toJson kind), ("visited", toJson run.visited),
      ("choices", toJson run.tape.entries.size)])
    return if kind.isSome then 0 else 2

def withOptions (args : List String) (run : Options → IO UInt32) : IO UInt32 := do
  try
    unless (← IO.getEnv "LEAN_ABORT_ON_PANIC") == some "1" do
      fail "LEAN_ABORT_ON_PANIC=1 is required before any frontend or interpreter execution"
    let options ← match parseOptions args with
      | .ok options => pure options
      | .error error => fail error
    run options
  catch error =>
    emit (Json.mkObj [("record", toJson "failure"), ("kind", toJson "input-or-frontend-error"),
      ("reason", toJson error.toString)])
    return 2

end CoreBDiff
