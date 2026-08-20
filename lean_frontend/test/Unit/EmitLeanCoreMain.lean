/-
  Unit.EmitLeanCoreMain — exe entry for the term-emission instrument
  (Unit.EmitLeanCore; see that file's header). Prints the T1Core module
  to stdout.
-/

import Unit.EmitLeanCore

def main (_ : List String) : IO UInt32 := do
  let (t1, std) ← EmitLeanCore.readInputs
  match EmitLeanCore.emitModule t1 std with
  | .ok s => IO.print s; return 0
  | .error e => IO.eprintln s!"emit-lean-core: {e}"; return 1
