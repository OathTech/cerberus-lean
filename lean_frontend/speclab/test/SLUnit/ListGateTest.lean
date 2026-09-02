/-
SLUnit.ListGateTest — arc-15 S3: the ListAppendCore drift + exec
+ LEAK gate (the S1/S2 gate pattern, extended by the leak
observable).

Checks (all fail-closed, exit 1 on any failure):
  1. DRIFT: re-parse the pinned inputs (tests/speclab/applist_*.core
     + runtime/libcore/std.core), re-emit the module, byte-compare
     with the committed SpecLab/ListAppendCore.lean.
  2. PARAM PINS: `appendMainParamDecl` instantiated at the wire-byte
     vectors of ALL FOUR pinned healthy dumps (a, b, d, AND the
     out-of-trio c = [0,-1]++[INT_MIN]) pp-prints byte-identically to
     the freshly parsed `main` of each dump.
  3. EXEC: `CerbND.runND ∘ drive` on the ASSEMBLED FILE TERMS (the
     pinned Core terms) returns the pinned verdicts — append Specified(0) at the four
     samples, Specified(255) at the wrong-link plant, Specified(3) at
     the wrong-element plant, Specified(0) at the build-only
     instance.
  4. THE LEAK OBSERVABLE (live this rung): every run's final
     allocation-map size is checked — healthy + build-only at the
     driver baseline (`ListAppend.driverBaseline` = 1, the errno
     object; this check IS the baseline's pin — drift here means the
     driver's startup footprint changed), the wrong-link plant at
     baseline + 1 (the orphaned xs tail node), the wrong-element
     plant at baseline (it corrupts content, not structure — teardown
     still reaches every node).

EPISTEMIC LABEL: this is a TEST (untrusted-evaluator) — a
differential drift/exec gate, never a kernel-checked claim.
-/
import SpecLab
import SLUnit.EmitCore

open SpecLab SpecLab.ListAppend SpecLab.ListAppendCore

set_option autoImplicit false

/-- pp a decl or die (re-flattens hoisted compositions). -/
def ppOfL (d : generic_fun_map_decl Unit Unit) : Except String String :=
  SpecLabEmitCore.ppFunMapDecl d

/-- Run the assembled file through the production driver entry and
project (verdict, final allocation-map size). Effect-retirement C1:
the CerbTags global is GONE — struct layouts reach CerbMem by VALUE
(reader_consumer), so `f.tagDefs` in the drive seed below is the whole
story; the entry is supply-parameterized (seed 0 — authored-Core ids
are name-hash interned, not drawn). -/
def runFileL (f : file core_run_annotation) : IO (Sum (Int × Nat) String) := do
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

/-- (label, model) — the four healthy samples (= ListAppend.sampleSet,
spelled out so a sample-set edit breaks the gate loudly). -/
def appendExecPoints : List (String × SpecLab.ListAppend.Input) :=
  [("a", ⟨[67305985, 134678021], [202050057]⟩),
   ("b", ⟨[1751606885, 1818978921], [1886350957]⟩),
   ("d", ⟨[-859059511, -791687475], [-724315439]⟩),
   ("c", ⟨[0, -1], [-2147483648]⟩)]

def applyParams12 : List Int → Option (generic_fun_map_decl Unit Unit)
  | [b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11] =>
    some (appendMainParamDecl b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11)
  | _ => none

/-- Check one exec point: verdict + leak observable. -/
def checkRun (label : String) (f : file core_run_annotation)
    (wantVerdict : Int) (wantAllocs : Nat) (note : String) :
    IO Nat := do
  match ← runFileL f with
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
  let (a, b, d, c, lp, ep, bu, std) ← SpecLabEmitCore.readListInputs
  match SpecLabEmitCore.emitListModule a b d c lp ep bu std with
  | .error e =>
    IO.println s!"  FAIL  re-emission errored: {e}"
    failures := failures + 1
  | .ok fresh =>
    let root ← SpecLabEmitCore.findRoot
    let committedPath :=
      if ← System.FilePath.pathExists
          (root ++ "lean_frontend/speclab/SpecLab/ListAppendCore.lean") then
        root ++ "lean_frontend/speclab/SpecLab/ListAppendCore.lean"
      else
        root ++ "SpecLab/ListAppendCore.lean"
    let committed ← IO.FS.readFile committedPath
    if fresh == committed then
      IO.println "  PASS  drift gate: re-emitted module byte-identical"
    else
      IO.println "  FAIL  drift gate: ListAppendCore.lean drifted from pinned inputs"
      failures := failures + 1
  -- 2. param pins (all four append dumps; c is out-of-trio)
  for ((label, m), text) in appendExecPoints.zip [a, b, d, c] do
    let r : Except String Bool := do
      let cf ← CoreParser.parseFile text
      let (_, mainD) ← SpecLabEmitCore.findDecl cf "main"
      let want ← ppOfL mainD
      match applyParams12 (wireBytes m) with
      | none => throw "applyParams12: bad wire-byte vector"
      | some inst => pure ((← ppOfL inst) == want)
    match r with
    | .ok true => IO.println s!"  PASS  param pin [{label}]: appendMainParamDecl == parsed main"
    | .ok false =>
      IO.println s!"  FAIL  param pin [{label}]: instantiated main differs from dump"
      failures := failures + 1
    | .error e =>
      IO.println s!"  FAIL  param pin [{label}]: {e}"
      failures := failures + 1
  -- 3+4. exec + leak on the assembled file terms
  for (label, m) in appendExecPoints do
    failures := failures +
      (← checkRun s!"append {label}" (appendFileOf m) 0 driverBaseline "")
  failures := failures + (← checkRun "append link-plant"
    appendLinkPlantFile 255 (driverBaseline + 1)
    " — structural break in the length arm; +1 = the orphaned node")
  failures := failures + (← checkRun "append elem-plant"
    appendElemPlantFile 3 driverBaseline
    " — the wrong-element plant is RED in-logic at element 0")
  failures := failures + (← checkRun "build-only"
    appendBuildFile 0 driverBaseline
    " — builder-walker round trip through the heap")
  if failures == 0 then
    IO.println "ListGateTest: ALL PASSED"
    return 0
  else
    IO.println s!"ListGateTest: {failures} FAILED"
    return 1
