/-
  SLUnit.EmitSeedMain — exe entry for the R5 CN-seed term-emission
  instrument (SLUnit.EmitCore; see the seed plan there). Prints the
  CnSeedCore module to stdout.
-/

import SLUnit.EmitCore

def main (_ : List String) : IO UInt32 := do
  let (sa, sb, sd, sc, sp, std) ← SpecLabEmitCore.readSeedInputs
  match SpecLabEmitCore.emitSeedModule sa sb sd sc sp std with
  | .ok text => IO.print text; return 0
  | .error e => IO.eprintln s!"speclab-emit-seed: {e}"; return 1
