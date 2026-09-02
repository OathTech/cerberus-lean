/-
SLUnit.ByteArrGateTest — arc-15 S2: the ByteArrCore drift + exec
gate (the S1 CoreGateTest pattern, attributed).

Checks (all fail-closed, exit 1 on any failure):
  1. DRIFT: re-parse the pinned inputs (tests/speclab/memcpy_*.core +
     getarr_*.core), re-emit the module, byte-compare with the
     committed SpecLab/ByteArrCore.lean (hoisted helpers included —
     the hoist pass is part of the pinned emission).
  2. PARAM PINS: `memcpyMainParamDecl` instantiated at the byte
     vectors of ALL FOUR pinned healthy memcpy dumps (a, b, d, AND
     the out-of-trio c=[0,255,42]) pp-prints byte-identically to the
     freshly parsed `main` of each dump (the parameterization's
     fidelity, checked at a point NOT used to derive it; the pp of
     the instantiated value also re-flattens the hoisted helpers —
     the composition's fidelity).
  3. EXEC: `CerbND.runND ∘ drive` on the ASSEMBLED FILE TERMS (the
     pinned Core terms) returns the pinned verdicts — memcpy Specified(0) at the four
     samples, Specified(3) at the off-by-one plant; getarr
     Specified(0) at both pinned instances, Specified(1) at the
     wrong-index plant.

EPISTEMIC LABEL: this is a TEST (untrusted-evaluator) — a
differential drift/exec gate, never a kernel-checked claim.
-/
import SpecLab
import SLUnit.EmitCore

open SpecLab SpecLab.ByteArr SpecLab.ByteArrCore

set_option autoImplicit false

/-- pp a decl or die (re-flattens hoisted compositions). -/
def ppOfB (d : generic_fun_map_decl Unit Unit) : Except String String :=
  SpecLabEmitCore.ppFunMapDecl d

/-- Run the assembled file through the production driver entry
(`drive`, `["cmdname"]`, default fs) and project the single-execution
verdict. -/
def runFileB (f : file core_run_annotation) : Sum Int String :=
  match CerbND.runND (drive f.tagDefs false f ["cmdname"])
      ((initial_driver_state 0 f CerbFS.fs_initial_state).1) with
  | [(Active r, _, _)] =>
    match r.dres_core_value with
    | Vloaded (LVspecified (OVinteger (CerbMem.IntegerValue.IV _ n))) =>
      .inl n
    | _ => .inr "single Active execution, non-integer result value"
  | [(Killed _ reason, _, _)] =>
    .inr (match reason with
      | Undef0 _ _ => "Killed: UB"
      | Error0 _ msg => s!"Killed: error {msg}"
      | Other _ => "Killed: driver error")
  | [] => .inr "no executions"
  | _ => .inr "multiple executions"

/-- (label, model, expected verdict) — memcpy healthy samples. -/
def memcpyExecPoints : List (String × List UInt8 × Int) :=
  [("a", [1, 2, 3], 0), ("b", [250, 251, 252], 0),
   ("d", [9, 8, 7], 0), ("c", [0, 255, 42], 0)]

def applyParams3 : List Int → Option (generic_fun_map_decl Unit Unit)
  | [c0, c1, c2] => some (memcpyMainParamDecl c0 c1 c2)
  | _ => none

def main : IO UInt32 := do
  let mut failures := 0
  -- 1. drift gate
  let (ma, mb, md, mp, ga, gb, gp) ← SpecLabEmitCore.readByteArrInputs
  match SpecLabEmitCore.emitByteArrModule ma mb md mp ga gb gp with
  | .error e =>
    IO.println s!"  FAIL  re-emission errored: {e}"
    failures := failures + 1
  | .ok fresh =>
    let root ← SpecLabEmitCore.findRoot
    let committedPath :=
      if ← System.FilePath.pathExists
          (root ++ "lean_frontend/speclab/SpecLab/ByteArrCore.lean") then
        root ++ "lean_frontend/speclab/SpecLab/ByteArrCore.lean"
      else
        root ++ "SpecLab/ByteArrCore.lean"
    let committed ← IO.FS.readFile committedPath
    if fresh == committed then
      IO.println "  PASS  drift gate: re-emitted module byte-identical"
    else
      IO.println "  FAIL  drift gate: ByteArrCore.lean drifted from pinned inputs"
      failures := failures + 1
  -- 2. param pins (all four memcpy dumps; c is out-of-trio)
  for (label, text) in [("a", ma), ("b", mb), ("d", md)] ++
      [("c", ← do
        let root ← SpecLabEmitCore.findRoot
        IO.FS.readFile (root ++ "tests/speclab/memcpy_c.core"))] do
    let r : Except String Bool := do
      let cf ← CoreParser.parseFile text
      let (_, mainD) ← SpecLabEmitCore.findDecl cf "main"
      let want ← ppOfB mainD
      let bs : List UInt8 := match label with
        | "a" => [1, 2, 3] | "b" => [250, 251, 252]
        | "d" => [9, 8, 7] | _ => [0, 255, 42]
      match applyParams3 (bs.map ByteArr.byteToInt) with
      | none => throw "applyParams3: bad vector"
      | some inst => pure ((← ppOfB inst) == want)
    match r with
    | .ok true => IO.println s!"  PASS  param pin [{label}]: memcpyMainParamDecl == parsed main"
    | .ok false =>
      IO.println s!"  FAIL  param pin [{label}]: instantiated main differs from dump"
      failures := failures + 1
    | .error e =>
      IO.println s!"  FAIL  param pin [{label}]: {e}"
      failures := failures + 1
  -- 3. exec checks on the assembled file terms
  for (label, bs, want) in memcpyExecPoints do
    match runFileB (memcpyFileOf bs) with
    | .inl n =>
      if n == want then
        IO.println s!"  PASS  exec [memcpy {label}]: Specified({n})"
      else
        IO.println s!"  FAIL  exec [memcpy {label}]: Specified({n}) != {want}"
        failures := failures + 1
    | .inr e =>
      IO.println s!"  FAIL  exec [memcpy {label}]: {e}"
      failures := failures + 1
  match runFileB memcpyPlantFile with
  | .inl 3 => IO.println "  PASS  exec [memcpy plant]: Specified(3) — the off-by-one plant is RED in-logic at dst byte 0"
  | .inl n =>
    IO.println s!"  FAIL  exec [memcpy plant]: Specified({n}) != 3"
    failures := failures + 1
  | .inr e =>
    IO.println s!"  FAIL  exec [memcpy plant]: {e}"
    failures := failures + 1
  for (label, f) in [("A", getarrFileA), ("B", getarrFileB)] do
    match runFileB f with
    | .inl 0 => IO.println s!"  PASS  exec [getarr {label}]: Specified(0)"
    | .inl n =>
      IO.println s!"  FAIL  exec [getarr {label}]: Specified({n}) != 0"
      failures := failures + 1
    | .inr e =>
      IO.println s!"  FAIL  exec [getarr {label}]: {e}"
      failures := failures + 1
  match runFileB getarrPlantFile with
  | .inl 1 => IO.println "  PASS  exec [getarr plant]: Specified(1) — the wrong-index plant is RED in-logic"
  | .inl n =>
    IO.println s!"  FAIL  exec [getarr plant]: Specified({n}) != 1"
    failures := failures + 1
  | .inr e =>
    IO.println s!"  FAIL  exec [getarr plant]: {e}"
    failures := failures + 1
  if failures == 0 then
    IO.println "ByteArrGateTest: ALL PASSED"
    return 0
  else
    IO.println s!"ByteArrGateTest: {failures} FAILED"
    return 1
