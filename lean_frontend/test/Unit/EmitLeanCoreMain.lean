/-
  Unit.EmitLeanCoreMain — exe entry for the term-emission instrument
  (Unit.EmitLeanCore; see that file's header). Prints the T1Core module
  to stdout; with argument `slate`, prints the SlateCore module
  (T2–T5, arc-7 S5a) instead.
-/

import Unit.EmitLeanCore

def main (args : List String) : IO UInt32 := do
  match args with
  | ["slate"] =>
    let texts ← EmitLeanCore.readSlateInputs
    match EmitLeanCore.emitSlateModule texts with
    | .ok s => IO.print s; return 0
    | .error e => IO.eprintln s!"emit-lean-core slate: {e}"; return 1
  | ["corpus"] =>
    let (texts, std) ← EmitLeanCore.readCorpusInputs
    match EmitLeanCore.emitCorpusModule texts std with
    | .ok s => IO.print s; return 0
    | .error e => IO.eprintln s!"emit-lean-core corpus: {e}"; return 1
  | ["corpusb"] =>
    let texts ← EmitLeanCore.readCorpusBInputs
    match EmitLeanCore.emitCorpusBModule texts with
    | .ok s => IO.print s; return 0
    | .error e => IO.eprintln s!"emit-lean-core corpusb: {e}"; return 1
  | [] =>
    let (t1, std) ← EmitLeanCore.readInputs
    match EmitLeanCore.emitModule t1 std with
    | .ok s => IO.print s; return 0
    | .error e => IO.eprintln s!"emit-lean-core: {e}"; return 1
  | _ => IO.eprintln "usage: emit-lean-core [slate|corpus]"; return 2
