/-
Unit.CoreGateTest (speclab) — arc-15 S1: the DivModCore drift +
exec gate (the parked reasoning-era Unit.EmitLeanCoreTest pattern —
tag park/reasoning-era-20260831 — attributed).

Checks (all fail-closed, exit 1 on any failure):
  1. DRIFT: re-parse the pinned inputs (tests/speclab/*.core +
     runtime/libcore/std.core), re-emit the module, byte-compare with
     the committed SpecLab/DivModCore.lean.
  2. PARAM PINS: `mainParamDecl` instantiated at the byte vectors of
     ALL FOUR pinned healthy dumps (a, b, d, AND the out-of-trio
     c=(-128,-1)) pp-prints byte-identically to the freshly parsed
     `main` of each dump (the parameterization's fidelity, checked at
     a point NOT used to derive it).
  3. EXEC: `CerbND.runND ∘ drive` on the ASSEMBLED FILE TERMS (the
     pinned Core terms: divmodI8FileOf / divmodI8PlantFile) returns the
     pinned verdicts — Specified(0) at the four samples, Specified(1) at
     the plant — i.e. the pinned Core terms agree with what both C
     pipelines produce for the same programs (scripts/test_speclab_divmod.sh).

EPISTEMIC LABEL: this is a TEST (untrusted-evaluator) — a
differential drift/exec gate, never a kernel-checked claim.
-/
import SpecLab
import SLUnit.EmitCore

open SpecLab SpecLab.DivMod SpecLab.DivModCore

set_option autoImplicit false

/-- pp a decl or die. -/
def ppOf (d : generic_fun_map_decl Unit Unit) : Except String String :=
  SpecLabEmitCore.ppFunMapDecl d

/-- Run the assembled file through the production driver entry
(`drive`, `["cmdname"]`, default fs) and project the single-execution
verdict. -/
def runFile (f : file core_run_annotation) : Sum Int String :=
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

/-- (label, sample, expected verdict). -/
def execPoints : List (String × Input × Int) :=
  [("a", ⟨7, 2⟩, 0), ("b", ⟨-5, 3⟩, 0), ("d", ⟨-6, 3⟩, 0),
   ("c", ⟨-128, -1⟩, 0)]

/-- The four dumps' byte vectors (c0 c1 e0 e1 e2 e3), for the param
pins — computed from the PURE model (single source of truth). -/
def paramBytes (m : Input) : List Int :=
  [byteToInt (toByteI8 m.x), byteToInt (toByteI8 m.y),
   byteToInt (i16b0 (modelDiv m)), byteToInt (i16b1 (modelDiv m)),
   byteToInt (i16b0 (modelMod m)), byteToInt (i16b1 (modelMod m))]

def applyParams : List Int → Option (generic_fun_map_decl Unit Unit)
  | [c0, c1, e0, e1, e2, e3] => some (mainParamDecl c0 c1 e0 e1 e2 e3)
  | _ => none

def main : IO UInt32 := do
  let mut failures := 0
  -- 1. drift gate
  let (a, b, d, pl, std) ← SpecLabEmitCore.readInputs
  match SpecLabEmitCore.emitDivModModule a b d pl std with
  | .error e =>
    IO.println s!"  FAIL  re-emission errored: {e}"
    failures := failures + 1
  | .ok fresh =>
    let root ← SpecLabEmitCore.findRoot
    let committedPath :=
      if ← System.FilePath.pathExists
          (root ++ "lean_frontend/speclab/SpecLab/DivModCore.lean") then
        root ++ "lean_frontend/speclab/SpecLab/DivModCore.lean"
      else
        root ++ "SpecLab/DivModCore.lean"
    let committed ← IO.FS.readFile committedPath
    if fresh == committed then
      IO.println "  PASS  drift gate: re-emitted module byte-identical"
    else
      IO.println "  FAIL  drift gate: DivModCore.lean drifted from pinned inputs"
      failures := failures + 1
  -- 2. param pins (all four dumps; c is out-of-trio)
  let dumps : List (String × String) := [("a", a), ("b", b), ("d", d)]
  let dumpC ← do
    let root ← SpecLabEmitCore.findRoot
    IO.FS.readFile (root ++ "tests/speclab/divmod_i8_c.core")
  for (label, text) in dumps ++ [("c", dumpC)] do
    let r : Except String Bool := do
      let cf ← CoreParser.parseFile text
      let (_, mainD) ← SpecLabEmitCore.findDecl cf "main"
      let want ← ppOf mainD
      let m : Input := match label with
        | "a" => ⟨7, 2⟩ | "b" => ⟨-5, 3⟩ | "d" => ⟨-6, 3⟩ | _ => ⟨-128, -1⟩
      match applyParams (paramBytes m) with
      | none => throw "applyParams: bad vector"
      | some inst => pure ((← ppOf inst) == want)
    match r with
    | .ok true => IO.println s!"  PASS  param pin [{label}]: mainParamDecl == parsed main"
    | .ok false =>
      IO.println s!"  FAIL  param pin [{label}]: instantiated main differs from dump"
      failures := failures + 1
    | .error e =>
      IO.println s!"  FAIL  param pin [{label}]: {e}"
      failures := failures + 1
  -- 3. exec checks on the assembled file terms
  for (label, m, want) in execPoints do
    match runFile (divmodI8FileOf m) with
    | .inl n =>
      if n == want then
        IO.println s!"  PASS  exec [{label}] ({m.x},{m.y}): Specified({n})"
      else
        IO.println s!"  FAIL  exec [{label}] ({m.x},{m.y}): Specified({n}) != {want}"
        failures := failures + 1
    | .inr e =>
      IO.println s!"  FAIL  exec [{label}] ({m.x},{m.y}): {e}"
      failures := failures + 1
  match runFile divmodI8PlantFile with
  | .inl 1 => IO.println "  PASS  exec [plant]: Specified(1) — the wrong-operator plant is RED in-logic"
  | .inl n =>
    IO.println s!"  FAIL  exec [plant]: Specified({n}) != 1"
    failures := failures + 1
  | .inr e =>
    IO.println s!"  FAIL  exec [plant]: {e}"
    failures := failures + 1
  if failures == 0 then
    IO.println "CoreGateTest: ALL PASSED"
    return 0
  else
    IO.println s!"CoreGateTest: {failures} FAILED"
    return 1
