import CerbStop
import CerbFailProofs

/-! Runtime wire and adapter checks, not a theorem about Json.parse or the
unsafe runtime abort. The Python conformance suite drives the explicit tool
modes below over real subprocess captures before any production caller moves. -/
namespace StopTest
open CerbStop

def citation : Upstream := {
  repository := .cerberus
  revision := "b9aeedcb4dd438763b0eef7f95ac19e93875d7de"
  path := "memory/concrete/impl_mem.ml"
  first := 2658
  last := 2659
  text := "assert false"
  revision_valid := by decide
  path_valid := by decide
  lines_valid := by decide
}

def refusal : Refusal := {
  boundary := .fs, item := some ""
  detail := ⟨"cannot open a\nb", by decide⟩
  mover := ⟨"a filesystem model", by decide⟩
  see := some ⟨"CONTRACT.md §3", by decide⟩
}

def crash : UpstreamCrash := {
  site := ⟨"CerbMem.memcmp", by decide⟩
  detail := ⟨"non-integer byte", by decide⟩
  upstream := citation
}

def invariant : Invariant := {
  site := ⟨"Main.judgeSwitches", by decide⟩
  detail := ⟨"refusal returned", by decide⟩
  see := ⟨"Main.refuseSwitches must terminate", by decide⟩
}

def controls : String := String.ofList ((List.range 32).map Char.ofNat)

def samples : List Stop := [
  .refusal refusal,
  .upstreamCrash crash,
  .invariant invariant,
  .refusal { refusal with
    item := some "a / : \"\\ud800"
    detail := ⟨"☃😀�" ++ controls ++ "\ncerberus-lean stop [\"1\"]", by decide⟩
    upstream := some { citation with repository := .lem, text := controls }
    see := none },
  .upstreamCrash { crash with tray := .pending },
  .upstreamCrash { crash with tray := .draft 12 (by decide) },
  .upstreamCrash { crash with
    tray := .filed "https://github.com/rems-project/cerberus/issues/1" (by decide)
    see := some ⟨"source review", by decide⟩ }
]

def typedRecord (failure : Failure) : IO String := do
  let result := CerbFail.step (CerbMem.stopMem (a := Unit) failure)
    (CerbMem.initialMemState 65536)
  match result.1 with
  | .NDkilled (.Error0 loc msg) =>
    if loc == CerbFail.modelFailStopLoc then pure (CerbFail.batchRecord msg)
    else throw (IO.userError "typed adapter changed the sentinel")
  | _ => throw (IO.userError "typed adapter did not kill")

def run : IO UInt32 := do
  for stop in samples do
    match parse (render stop) with
    | .ok parsed =>
      unless parsed == stop do throw (IO.userError "stop round-trip changed fields")
    | .error e => throw (IO.userError s!"stop round-trip rejected: {repr e}")
    if (render stop).contains '\n' || (render stop).contains '\r' then
      throw (IO.userError "physical newline in embedded envelope")
  match parse "ordinary failure" with
  | .error .absent => pure ()
  | _ => throw (IO.userError "absence was not distinguished")
  for malformed in ["cerberus-lean stop", "cerberus-lean stop{}",
      "cerberus-lean stop [\"2\",\"INVARIANT\",\"s\",\"d\",\"r\"]",
      "cerberus-lean stop [\"1\",\"INVARIANT\",\"s\",\"\\ud800\",\"r\"]"] do
    match parse malformed with
    | .error (.malformed _) => pure ()
    | _ => throw (IO.userError "reserved malformed envelope was admitted/absent")
  let r ← typedRecord (.upstreamCrash crash)
  unless r == CerbFail.batchRecord (render (.upstreamCrash crash)) do
    throw (IO.userError "typed adapter lost the outer escaping")
  let r ← typedRecord (.invariant invariant)
  unless r == CerbFail.batchRecord (render (.invariant invariant)) do
    throw (IO.userError "typed invariant lost metadata")
  IO.println "stop-test: round-trips, absence/malformed and typed adapters passed"
  pure 0

end StopTest

def main (args : List String) : IO UInt32 := do
  match args with
  | [] => StopTest.run
  | ["render"] =>
    for stop in StopTest.samples do IO.println (CerbStop.render stop)
    pure 0
  | ["decode"] =>
    -- Each input line is a JSON string carrying one complete test input,
    -- including embedded raw CR/LF. This is a test transport, not a new API.
    let input ← (← IO.getStdin).readToEnd
    for line in input.splitOn "\n" do
      if !line.isEmpty then
        match Lean.Json.parse line with
        | .ok (.str payload) =>
          match CerbStop.parse payload with
          | .ok stop => IO.println (CerbStop.render stop)
          | .error .absent => IO.println "ABSENT"
          | .error (.malformed _) => IO.println "MALFORMED"
        | _ => throw (IO.userError "bad test transport")
    pure 0
  | ["refuse"] => CerbStop.exitRefusals StopTest.refusal [StopTest.refusal]
  | ["invariant-cli"] => CerbStop.exitInvariant StopTest.invariant
  | ["typed"] =>
    IO.println (← StopTest.typedRecord (.upstreamCrash StopTest.crash))
    pure 1
  | ["pure"] =>
    IO.println (failwithI (CerbStop.render (.upstreamCrash StopTest.crash)) : String)
    pure 1
  | ["refuse-m"] =>
    match (CerbFail.step (CerbMem.refuseM (a := Unit) StopTest.refusal)
        (CerbMem.initialMemState 65536)).1 with
    | .NDkilled _ =>
      IO.println "monadic refusal returned a kill"
      pure 1
    | _ => throw (IO.userError "monadic refusal returned without a kill")
  | _ => throw (IO.userError "unknown stop-test mode")
