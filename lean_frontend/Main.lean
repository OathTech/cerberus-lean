import CerberusImpl
import CerbMem

def main : IO Unit := do
  IO.println "cerberus-lean: loaded"
  match CerberusImpl.sizeof_ity (Signed Int_) with
  | some n => IO.println s!"  sizeof(int) = {n}"
  | none => IO.println "  sizeof(int) = unknown"
  let maxInt := CerbMem.maxIval (Signed Int_)
  IO.println s!"  max(signed int) = {maxInt.val}"
  let bytes := CerbMem.intToBytes 42 4
  let byteStrs := bytes.map fun b => match b with
    | some v => toString v.toNat | none => "?"
  IO.println s!"  intToBytes(42, 4) = {byteStrs}"
  IO.println "  ready"
