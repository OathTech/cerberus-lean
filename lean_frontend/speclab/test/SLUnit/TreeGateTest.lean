/-
SLUnit.TreeGateTest — arc-15 S4: the TreeRotCore drift + adequacy +
LEAK gate (the S3 ListGateTest pattern at the tree rung).

Checks (all fail-closed, exit 1 on any failure):
  1. DRIFT: re-parse the pinned inputs (tests/speclab/rotate_*.core),
     re-emit the module, byte-compare with the committed
     SpecLab/TreeRotCore.lean.
  2. PARAM PINS: `rotateMainParamDecl` instantiated at the wire-byte
     vectors of ALL FOUR pinned healthy dumps (a, b, d, AND the
     out-of-trio c = [0, -1, INT_MIN, INT_MAX, 1, -INT_MAX])
     pp-prints byte-identically to the freshly parsed `main` of each
     dump.
  3. EXEC: `CerbND.runND ∘ drive` on the ASSEMBLED THEOREM OBJECTS
     returns the pinned verdicts — rotate Specified(0) at the four
     samples + the root-path + deep-path instances, Specified(7) at
     the wrong-child-swap plant (the locus val's first wire byte),
     Specified(255) at the dropped-subtree plant (the structural
     length arm), Specified(0) at the build-only instance.
  4. THE LEAK OBSERVABLE: every run's final allocation-map size —
     healthy + path + build-only at the driver baseline (rotation is
     allocation-neutral: `TreeRot.rotateAt_size`), the
     WRONG-CHILD-SWAP plant ALSO at baseline (a broken-but-leak-free
     target — the observable separates the plant classes), the
     DROPPED-SUBTREE plant at baseline + 1 (the orphaned middle
     subtree: `orphanedAt` = 1 at the pinned instance).

EPISTEMIC LABEL: this is a TEST (untrusted-evaluator) — a
differential drift/exec gate, never a kernel-checked claim.
-/
import SpecLab
import SLUnit.EmitCore

open SpecLab SpecLab.TreeRot SpecLab.TreeRotCore

set_option autoImplicit false

/-- pp a decl or die (re-flattens hoisted compositions). -/
def ppOfT (d : generic_fun_map_decl Unit Unit) : Except String String :=
  SpecLabEmitCore.ppFunMapDecl d

/-- Run the assembled file through the production driver entry and
project (verdict, final allocation-map size). Effect-retirement C1:
no ambient CerbTags set/reset — layouts reach CerbMem by value via the
`drive` reader seed; supply-parameterized entry (seed 0). -/
def runFileT (f : file core_run_annotation) : IO (Sum (Int × Nat) String) := do
  return match CerbND.runND (drive f.tagDefs false f ["cmdname"])
      ((initial_driver_state 0 f CerbFS.fs_initial_state).1) with
  | [(Active r, _, st)] =>
    match r.dres_core_value with
    | Vloaded (LVspecified (OVinteger (CerbMem.IntegerValue.IV _ n))) =>
      .inl (n, st.layout_state.allocations.size)
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

/-- (label, model) — the four healthy samples (= TreeRot.sampleSet,
spelled out so a sample-set edit breaks the gate loudly). -/
def rotateExecPoints : List (String × SpecLab.TreeRot.Input) :=
  [("a", ⟨pinnedShape 67305985 134678021 202050057 269422093 336794129
      404166165, pinnedPath⟩),
   ("b", ⟨pinnedShape 1751606885 1818978921 1886350957 1953722993
      2021095029 2088467065, pinnedPath⟩),
   ("d", ⟨pinnedShape (-859059511) (-791687475) (-724315439)
      (-656943403) (-589571367) (-522199331), pinnedPath⟩),
   ("c", ⟨pinnedShape 0 (-1) (-2147483648) 2147483647 1 (-2147483647),
      pinnedPath⟩)]

def applyParams24 : List Int → Option (generic_fun_map_decl Unit Unit)
  | [b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14,
     b15, b16, b17, b18, b19, b20, b21, b22, b23] =>
    some (rotateMainParamDecl b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12
      b13 b14 b15 b16 b17 b18 b19 b20 b21 b22 b23)
  | _ => none

/-- Check one exec point: verdict + leak observable. -/
def checkRunT (label : String) (f : file core_run_annotation)
    (wantVerdict : Int) (wantAllocs : Nat) (note : String) :
    IO Nat := do
  match ← runFileT f with
  | .inl (n, allocs) =>
    let mut failures := 0
    if n == wantVerdict then
      IO.println s!"  PASS  exec [{label}]: Specified({n}){note}"
    else
      IO.println s!"  FAIL  exec [{label}]: Specified({n}) != {wantVerdict}"
      failures := failures + 1
    if allocs == wantAllocs then
      IO.println s!"  PASS  leak [{label}]: final allocations = {allocs}"
    else
      IO.println s!"  FAIL  leak [{label}]: final allocations = {allocs} != {wantAllocs}"
      failures := failures + 1
    return failures
  | .inr e =>
    IO.println s!"  FAIL  exec [{label}]: {e}"
    return 2

def main : IO UInt32 := do
  let mut failures := 0
  -- 1. drift gate
  let (a, b, d, c, rt, dp, sp, drp, bu) ← SpecLabEmitCore.readTreeInputs
  match SpecLabEmitCore.emitTreeModule a b d c rt dp sp drp bu with
  | .error e =>
    IO.println s!"  FAIL  re-emission errored: {e}"
    failures := failures + 1
  | .ok fresh =>
    let root ← SpecLabEmitCore.findRoot
    let committedPath :=
      if ← System.FilePath.pathExists
          (root ++ "lean_frontend/speclab/SpecLab/TreeRotCore.lean") then
        root ++ "lean_frontend/speclab/SpecLab/TreeRotCore.lean"
      else
        root ++ "SpecLab/TreeRotCore.lean"
    let committed ← IO.FS.readFile committedPath
    if fresh == committed then
      IO.println "  PASS  drift gate: re-emitted module byte-identical"
    else
      IO.println "  FAIL  drift gate: TreeRotCore.lean drifted from pinned inputs"
      failures := failures + 1
  -- 2. param pins (all four parametric-family dumps; c is out-of-trio)
  for ((label, m), text) in rotateExecPoints.zip [a, b, d, c] do
    let r : Except String Bool := do
      let cf ← CoreParser.parseFile text
      let (_, mainD) ← SpecLabEmitCore.findDecl cf "main"
      let want ← ppOfT mainD
      match applyParams24 (wireBytes m) with
      | none => throw "applyParams24: bad wire-byte vector"
      | some inst => pure ((← ppOfT inst) == want)
    match r with
    | .ok true => IO.println s!"  PASS  param pin [{label}]: rotateMainParamDecl == parsed main"
    | .ok false =>
      IO.println s!"  FAIL  param pin [{label}]: instantiated main differs from dump"
      failures := failures + 1
    | .error e =>
      IO.println s!"  FAIL  param pin [{label}]: {e}"
      failures := failures + 1
  -- 3+4. exec + leak on the assembled theorem objects
  for (label, m) in rotateExecPoints do
    failures := failures +
      (← checkRunT s!"rotate {label}" (rotateFileOf m) 0
        ListAppend.driverBaseline "")
  failures := failures + (← checkRunT "rotate root-path"
    rotateRootFile 0 ListAppend.driverBaseline
    " — the pointer-selection family at path []")
  failures := failures + (← checkRunT "rotate deep-path"
    rotateDeepFile 0 ListAppend.driverBaseline
    " — the pointer-selection family at path [l,l]")
  failures := failures + (← checkRunT "rotate swap-plant"
    swapPlantFile 7 ListAppend.driverBaseline
    " — content break at the locus val's first wire byte; LEAK-FREE (baseline)")
  failures := failures + (← checkRunT "rotate drop-plant"
    dropPlantFile 255 (ListAppend.driverBaseline + 1)
    " — structural break in the length arm; +1 = the orphaned middle subtree")
  failures := failures + (← checkRunT "build-only"
    rotateBuildFile 0 ListAppend.driverBaseline
    " — builder-walker round trip through the heap")
  if failures == 0 then
    IO.println "TreeGateTest: ALL PASSED"
    return 0
  else
    IO.println s!"TreeGateTest: {failures} FAILED"
    return 1
