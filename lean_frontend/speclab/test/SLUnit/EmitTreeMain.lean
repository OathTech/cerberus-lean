/-
  SLUnit.EmitTreeMain — arc-15 S4: entry point of `speclab-emit-tree`
  (the R4 tree-rotation term-emission instrument; plan + printers in
  SLUnit.EmitCore).

  Usage (from the repo root or the speclab dir):
    speclab-emit-tree > SpecLab/TreeRotCore.lean
-/
import SLUnit.EmitCore

def main : IO UInt32 := do
  let (a, b, d, c, rt, dp, sp, drp, bu) ← SpecLabEmitCore.readTreeInputs
  match SpecLabEmitCore.emitTreeModule a b d c rt dp sp drp bu with
  | .ok out => IO.print out; return 0
  | .error e => IO.eprintln s!"speclab-emit-tree: {e}"; return 1
