/-
  SLUnit.EmitListMain — arc-15 S3: entry point of `speclab-emit-list`
  (the R3 linked-list term-emission instrument; plan + printers in
  SLUnit.EmitCore).

  Usage (from the repo root or the speclab dir):
    speclab-emit-list > SpecLab/ListAppendCore.lean
-/
import SLUnit.EmitCore

def main : IO UInt32 := do
  let (a, b, d, c, lp, ep, bu, std) ← SpecLabEmitCore.readListInputs
  match SpecLabEmitCore.emitListModule a b d c lp ep bu std with
  | .ok out => IO.print out; return 0
  | .error e => IO.eprintln s!"speclab-emit-list: {e}"; return 1
