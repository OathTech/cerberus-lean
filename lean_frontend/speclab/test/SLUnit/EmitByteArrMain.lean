/-
  SLUnit.EmitByteArrMain — arc-15 S2: entry point of
  `speclab-emit-bytearr` (the R2 byte-blaster term-emission
  instrument; plan + printers in SLUnit.EmitCore).

  Usage (from the repo root or the speclab dir):
    speclab-emit-bytearr > SpecLab/ByteArrCore.lean
-/
import SLUnit.EmitCore

def main : IO UInt32 := do
  let (ma, mb, md, mp, ga, gb, gp) ← SpecLabEmitCore.readByteArrInputs
  match SpecLabEmitCore.emitByteArrModule ma mb md mp ga gb gp with
  | .ok out => IO.print out; return 0
  | .error e => IO.eprintln s!"speclab-emit-bytearr: {e}"; return 1
