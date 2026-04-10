import CerberusImpl
import CerbMem
import CerbCtypeInstances
import CerbInhabitedInstances
import CabsImport

def readInput (args : List String) : IO String := do
  match args with
  | ["--stdin"] => do
    let mut buf := ""
    let mut done_ := false
    while !done_ do
      let line ← (← IO.getStdin).getLine
      if line.isEmpty then done_ := true
      else buf := buf ++ line
    return buf
  | [file] => IO.FS.readFile file
  | _ => throw (IO.Error.userError "usage: cerberus-lean [--stdin | FILE.json]")

def countDecls : List external_declaration → Nat × Nat × Nat
  | [] => (0, 0, 0)
  | d :: ds =>
    let (funcs, decls, other) := countDecls ds
    match d with
    | .EDecl_func _ => (funcs + 1, decls, other)
    | .EDecl_decl _ => (funcs, decls + 1, other)
    | _ => (funcs, decls, other + 1)

def main (args : List String) : IO Unit := do
  -- With no args, run the self-test
  if args.length == 0 then
    IO.println "cerberus-lean: loaded"
    match CerberusImpl.sizeof_ity (Signed Int_) with
    | some n => IO.println s!"  sizeof(int) = {n}"
    | none => IO.println "  sizeof(int) = unknown"
    let maxInt := CerbMem.maxIval (Signed Int_)
    IO.println s!"  max(signed int) = {maxInt.val}"
    let minInt := CerbMem.minIval (Signed Int_)
    IO.println s!"  min(signed int) = {minInt.val}"
    let bytes := CerbMem.intToBytes 42 4
    let byteStrs := bytes.map fun b => match b with
      | some v => toString v.toNat | none => "?"
    IO.println s!"  intToBytes(42, 4) = {byteStrs}"
    IO.println "  ready"
    return

  -- Read and parse Cabs JSON
  let input ← readInput args
  match CabsImport.parseJson input with
  | .error e =>
    IO.eprintln s!"cerberus-lean: parse error: {e}"
    IO.Process.exit 1
  | .ok (TUnit decls) =>
    let (funcs, declCount, other) := countDecls decls
    IO.println s!"cerberus-lean: parsed {List.length decls} external declarations"
    IO.println s!"  functions: {funcs}"
    IO.println s!"  declarations: {declCount}"
    IO.println s!"  other: {other}"
