/-
SLUnit.SeedGateTest (speclab) — arc-15 S5: the CnSeedCore drift +
exec gate (the S1 CoreGateTest pattern).

Checks (all fail-closed, exit 1 on any failure):
  1. DRIFT: re-parse the pinned inputs (tests/speclab/pairswap_*.core),
     re-emit the module, byte-compare with the committed
     SpecLab/CnSeedCore.lean.
  2. PARAM PINS: `swapMainParamDecl` instantiated at the byte vectors
     of ALL FOUR pinned healthy dumps (a, b, d, AND the out-of-trio
     c = (2^64−1, 0)) pp-prints byte-identically to the freshly
     parsed `main` of each dump.
  3. EXEC: `CerbND.runND ∘ drive` on the ASSEMBLED FILE TERMS (the
     pinned Core terms: swapFileOf / pairSwapPlantFile) returns the
     pinned verdicts —
     Specified(0) at the four samples, Specified(9) at the
     lost-update plant.

(The lookup family has no pinned layer — the CoreParser enum-ctype
gap, registered S5 finding; its lanes live in
scripts/test_speclab_seed.sh.)

EPISTEMIC LABEL: this is a TEST (untrusted-evaluator) — a
differential drift/exec gate, never a kernel-checked claim.
-/
import SpecLab
import SLUnit.EmitCore

open SpecLab SpecLab.CnSeed SpecLab.CnSeedCore

set_option autoImplicit false

/-- pp a decl or die. -/
def ppOf (d : generic_fun_map_decl Unit Unit) : Except String String :=
  SpecLabEmitCore.ppFunMapDecl d

/-- Run the assembled file through the production driver entry and
project the single-execution verdict. -/
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
      | Other derr =>
        match derr with
        | DErr_core_run cause =>
          match cause with
          | .Illformed_program s => s!"Killed: Illformed_program: {s}"
          | .Found_empty_stack s => s!"Killed: Found_empty_stack: {s}"
          | .Reached_end_of_proc => "Killed: Reached_end_of_proc"
          | .Unknown_impl => "Killed: Unknown_impl"
          | .Unresolved_symbol _ (Symbol _ n d) =>
            s!"Killed: Unresolved_symbol {n} " ++
              (match d with | SD_Id s => s | _ => "<anon>")
        | DErr_memory merr => s!"Killed: memory error {Lem_Show.show0 merr}"
        | DErr_concurrency s => s!"Killed: concurrency {s}"
        | DErr_other s => s!"Killed: {s}")
  | [] => .inr "no executions"
  | _ => .inr "multiple executions"

/-- The four pinned test points (TEST-LEDGER data, spelled out here —
the ListGateTest/TreeGateTest pattern; formerly `swapSampleSet`,
whose statement-side def was deleted at the 2026-08-27 kill-list
execution — an edit here breaks the gate loudly). -/
def seedTestSet : List PairInput :=
  [⟨578437695752307201, 1157159078456920585⟩,
   ⟨7812454979559974501, 8391176362264587885⟩,
   ⟨15046472263367641801, 15625193646072255185⟩,
   ⟨18446744073709551615, 0⟩]

/-- (label, sample, expected verdict). -/
def execPoints : List (String × PairInput × Int) :=
  (seedTestSet.zip ["a", "b", "d", "c"]).map fun (m, l) => (l, m, 0)

/-- The dumps' byte vectors, computed from the PURE encoder (single
source of truth). -/
def paramBytes (m : PairInput) : List Int :=
  (encodePair m).map DivMod.byteToInt

def applyParams : List Int → Option (generic_fun_map_decl Unit Unit)
  | [b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14,
     b15] =>
    some (swapMainParamDecl b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12
      b13 b14 b15)
  | _ => none

def main : IO UInt32 := do
  let mut failures := 0
  -- 1. drift gate
  let (sa, sb, sd, sc, sp, std) ← SpecLabEmitCore.readSeedInputs
  match SpecLabEmitCore.emitSeedModule sa sb sd sc sp std with
  | .error e =>
    IO.println s!"  FAIL  re-emission errored: {e}"
    failures := failures + 1
  | .ok fresh =>
    let root ← SpecLabEmitCore.findRoot
    let committedPath :=
      if ← System.FilePath.pathExists
          (root ++ "lean_frontend/speclab/SpecLab/CnSeedCore.lean") then
        root ++ "lean_frontend/speclab/SpecLab/CnSeedCore.lean"
      else
        root ++ "SpecLab/CnSeedCore.lean"
    let committed ← IO.FS.readFile committedPath
    if fresh == committed then
      IO.println "  PASS  drift gate: re-emitted module byte-identical"
    else
      IO.println "  FAIL  drift gate: CnSeedCore.lean drifted from pinned inputs"
      failures := failures + 1
  -- 2. param pins (all four dumps; c is out-of-trio)
  let dumps : List (String × String) :=
    [("a", sa), ("b", sb), ("d", sd), ("c", sc)]
  for ((label, text), (m, _)) in
      dumps.zip (seedTestSet.zip ["a", "b", "d", "c"]) do
    let r : Except String Bool := do
      let cf ← CoreParser.parseFile text
      let (_, mainD) ← SpecLabEmitCore.findDecl cf "main"
      let want ← ppOf mainD
      match applyParams (paramBytes m) with
      | none => throw "applyParams: bad vector"
      | some inst => pure ((← ppOf inst) == want)
    match r with
    | .ok true => IO.println s!"  PASS  param pin [{label}]: swapMainParamDecl == parsed main"
    | .ok false =>
      IO.println s!"  FAIL  param pin [{label}]: instantiated main differs from dump"
      failures := failures + 1
    | .error e =>
      IO.println s!"  FAIL  param pin [{label}]: {e}"
      failures := failures + 1
  -- 3. exec checks on the assembled file terms
  for (label, m, want) in execPoints do
    match runFile (swapFileOf m) with
    | .inl n =>
      if n == want then
        IO.println s!"  PASS  exec [swap {label}]: Specified({n})"
      else
        IO.println s!"  FAIL  exec [swap {label}]: Specified({n}) != {want}"
        failures := failures + 1
    | .inr e =>
      IO.println s!"  FAIL  exec [swap {label}]: {e}"
      failures := failures + 1
  match runFile pairSwapPlantFile with
  | .inl 9 => IO.println "  PASS  exec [swap plant]: Specified(9) — the lost-update plant is RED in-logic at post-state cell 1, byte 0"
  | .inl n =>
    IO.println s!"  FAIL  exec [swap plant]: Specified({n}) != 9"
    failures := failures + 1
  | .inr e =>
    IO.println s!"  FAIL  exec [swap plant]: {e}"
    failures := failures + 1
  if failures == 0 then
    IO.println "SeedGateTest: ALL PASSED"
    return 0
  else
    IO.println s!"SeedGateTest: {failures} FAILED"
    return 1
