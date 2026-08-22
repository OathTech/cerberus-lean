/-
  Unit.EmitCoreMain — exe entry for the speclab term-emission
  instrument (Unit.EmitCore; see that file's header). Prints the
  DivModCore module to stdout.
-/

import SLUnit.EmitCore

def main (_ : List String) : IO UInt32 := do
  let (a, b, d, pl, std) ← SpecLabEmitCore.readInputs
  match SpecLabEmitCore.emitDivModModule a b d pl std with
  | .ok text => IO.print text; return 0
  | .error e => IO.eprintln s!"speclab-emit-core: {e}"; return 1
