/-
  Unit.EmitLeanCoreTest — arc-7 S4 (2026-08-20): the T1 program-term
  drift gate + concrete differential.

  Two fail-closed checks (S4 record §6.1):

  1. DRIFT GATE — re-parse the pinned inputs (tests/verify/t1_id.core,
     runtime/libcore/std.core), re-emit the T1Core module with the
     term-emission instrument (Unit.EmitLeanCore), and compare
     BYTE-FOR-BYTE against the committed relsem/RelSem/T1Core.lean.
     Any divergence (pinned dump changed, parser changed, emitter
     changed) fails until the module is deliberately regenerated.

  2. CONCRETE DIFFERENTIAL — run the production runner on the
     ASSEMBLED theorem object (RelSem.T1.t1File) through the same
     `callND` harness the theorem quantifies, at concrete points, and
     check the outcome against the pure spec (id(x) = Specified(x) for
     int-range x). This ties the hand-assembled metadata (funinfo,
     stdlib closure) to real behavior — the sanity net UNDER the
     theorem, never a substitute for it.
-/

import Unit.EmitLeanCore
import RelSem.Call
import RelSem.T1File
import RelSem.SlateFiles
import RelSem.CorpusFiles
import RelSem.CorpusBFiles

set_option autoImplicit false

open RelSem.Cerb RelSem.T1 RelSem.Slate RelSem.Corpus

/-- Run the T1 harness at a concrete argument; project the outcome.
    `.inl n` = the single execution returned Specified(n);
    `.inr s` = anything else (diagnostic). -/
def runT1 (x : Int) : Sum Int String :=
  match CerbND.runND (callND t1File.tagDefs t1File "id"
      [intValue x]) (initial_driver_state t1File CerbFS.fs_initial_state) with
  | [(Active r, _, _)] =>
    match r.dres_core_value with
    | Vloaded (LVspecified (OVinteger (CerbMem.IntegerValue.IV _ n))) => .inl n
    | _ => .inr "single Active execution, non-integer result value"
  | [(Killed _ reason, _, _)] =>
    .inr (match reason with
      | Undef0 _ _ => "Killed: UB"
      | Error0 _ msg => s!"Killed: error {msg}"
      | Other _ => "Killed: driver error")
  | [] => .inr "no executions"
  | _ => .inr "multiple executions"

def concretePoints : List Int :=
  [0, 1, 42, -7, 2147483647, -2147483648]

/-- Run a slate harness at concrete arguments; project the outcome
    (arc-7 S5a: the T2-T5 theorem objects). -/
def runSlate (file1 : file core_run_annotation) (fname : String)
    (args : List Int) : Sum Int String :=
  match CerbND.runND (callND file1.tagDefs file1 fname
      (args.map intValue)) (initial_driver_state file1
        CerbFS.fs_initial_state) with
  | [(Active r, _, _)] =>
    match r.dres_core_value with
    | Vloaded (LVspecified (OVinteger (CerbMem.IntegerValue.IV _ n))) => .inl n
    | _ => .inr "single Active execution, non-integer result value"
  | [(Killed _ reason, _, _)] =>
    .inr (match reason with
      | Undef0 _ _ => "UB"
      | Error0 _ msg => s!"Killed: error {msg}"
      | Other _ => "Killed: driver error")
  | [] => .inr "no executions"
  | _ => .inr "multiple executions"

/-- (fixture label, file, fname, args, expected: .inl n = Specified n,
    .inr () = UB) — the tests/verify/expectations.txt rows on the
    ASSEMBLED THEOREM OBJECTS. -/
def slatePoints : List (String × file core_run_annotation × String ×
    List Int × Sum Int Unit) :=
  [("t2", t2File, "add", [7, 35], .inl 42),
   ("t2", t2File, "add", [-1, -41], .inl (-42)),
   ("t2", t2File, "add", [0, 0], .inl 0),
   ("t2", t2File, "add", [2147483647, 1], .inr ()),
   ("t2", t2File, "add", [-2147483648, -1], .inr ()),
   ("t3", t3File, "roundtrip", [42], .inl 42),
   ("t3", t3File, "roundtrip", [-2147483648], .inl (-2147483648)),
   ("t4", t4File, "memb", [11], .inl 11),
   ("t4", t4File, "memb", [0], .inl 0),
   ("t4", t4File, "memb", [-123], .inl (-123)),
   ("t5", t5File, "sum", [0], .inl 0),
   ("t5", t5File, "sum", [1], .inl 0),
   ("t5", t5File, "sum", [10], .inl 45),
   ("t5", t5File, "sum", [100], .inl 4950)]
   -- (2026-08-27 kill-list execution: the t6/t7/e*/c*/x*/z* rows —
   -- concrete points serving KILLED theorems — left with their
   -- fixtures' file terms; the T2–T5 rows above are the sanity net
   -- under the KEPT threaded slate.)

/-- V0 (2026-08-27): concrete sample points on the ASSEMBLED corpus
    batch-A theorem objects (the family→sample honesty link: the
    emitted+assembled file terms the P-statements quantify over
    EXECUTE to their specs' values at the samples). -/
def corpusPoints : List (String × file core_run_annotation × String ×
    List Int × Sum Int Unit) :=
  [("p01", p01File, "clamp0", [-3], .inl 0),
   ("p01", p01File, "clamp0", [5], .inl 5),
   ("p01", p01File, "clamp0", [-2147483648], .inl 0),
   ("p01", p01File, "clamp0", [2147483647], .inl 2147483647),
   ("p02", p02File, "sat_add", [2147483640, 10], .inl 2147483647),
   ("p02", p02File, "sat_add", [-2147483640, -10], .inl (-2147483648)),
   ("p02", p02File, "sat_add", [3, 4], .inl 7),
   ("p03", p03File, "harness", [1, 5, 0], .inl 0),
   ("p03", p03File, "harness", [1, 5, 1], .inl 0),
   ("p03", p03File, "harness", [-7, 42, 0], .inl 0),
   ("p09", p09File, "harness", [20, 21], .inl 43),
   ("p09", p09File, "harness", [0, 0], .inl 2),
   ("p09", p09File, "harness", [2147483645, 0], .inl 2147483647),
   ("p10", p10File, "gcd_rec", [12, 18], .inl 6),
   ("p10", p10File, "gcd_rec", [5, 0], .inl 5),
   ("p10", p10File, "gcd_rec", [1, 2147483647], .inl 1),
   ("p11", p11File, "gcd", [12, 18], .inl 6),
   ("p11", p11File, "gcd", [2147483647, 2], .inl 1),
   ("p11", p11File, "gcd", [100, 75], .inl 25),
   ("p12", p12File, "harness", [0, 2, 4, 6], .inl 0),
   ("p12", p12File, "harness", [-1073741823, 1073741823, 1, 1], .inl 0)]


/-- V0 batch B: run the whole-program DRIVE face on a built family
    instance (the corpus memory-input rows' statement face —
    `HarnessRunsToCns`'s runner shape at the ambient state). -/
def runDrive (file1 : file core_run_annotation) : Sum Int String :=
  -- EVERY enumerated outcome must be Active at ONE integer verdict
  -- (the HarnessRunsToCns ∀-outcome shape; exhaustive mode explores
  -- unsequenced-evaluation orders, so several agreeing executions
  -- are the healthy case).
  match CerbND.runND (drive file1.tagDefs false file1 ["cmdname"])
      (initial_driver_state file1 CerbFS.fs_initial_state) with
  | [] => .inr "no executions"
  | outs =>
    let vals := outs.map (fun (out, _, _) =>
      match out with
      | Active r =>
        match r.dres_core_value with
        | Vloaded (LVspecified (OVinteger (CerbMem.IntegerValue.IV _ n))) =>
          Sum.inl (α := Int) (β := String) n
        | _ => .inr "Active, non-integer result value"
      | Killed _ reason =>
        .inr (match reason with
          | Undef0 _ _ => "UB"
          | Error0 _ msg => s!"Killed: error {msg}"
          | Other _ => "Killed: driver error"))
    match vals with
    | [] => .inr "no executions"
    | v :: rest =>
      if rest.all (· == v) then v
      else .inr s!"outcome set not a singleton ({vals.length} executions)"

/-- V0 batch B: the corpus .c sample splices, driven through the
    PARAMETRIC family builders (the family→sample honesty link for
    the memory-input rows: `pXXFileOf (sample m)` must run to the
    oracle-validated verdict 0). -/
def corpusBPoints : List (String × file core_run_annotation × Int) :=
  [("p04 [3,5,-2,9]", p04FileOf [3, 5, -2, 9], 0),
   ("p05 [7,1,9,3]@9", p05FileOf [7, 1, 9, 3] 9, 0),
   ("p06 [1,2,3,4]", p06FileOf [1, 2, 3, 4], 0),
   ("p14 [2,7,2,2]", p14FileOf [2, 7, 2, 2], 0),
   ("p15 'a7.9'", p15FileOf [97, 55, 46, 57, 0], 0),
   ("p07 heads[4,-1,7] pi[1,2,0]", p07FileOf [4, -1, 7] [1, 2, 0], 0),
   ("p08 heads[1,2,3] pi[2,0,1]", p08FileOf [1, 2, 3] [2, 0, 1], 0)]

def main : IO UInt32 := do
  let mut failures := 0
  -- 1. Drift gate.
  let (t1Text, stdText) ← EmitLeanCore.readInputs
  let root ← EmitLeanCore.findRoot
  match EmitLeanCore.emitModule t1Text stdText with
  | .error e =>
    IO.println s!"FAIL emit: {e}"
    failures := failures + 1
  | .ok emitted =>
    let committed ← IO.FS.readFile
      (root ++ "lean_frontend/relsem/RelSem/T1Core.lean")
    if emitted == committed then
      IO.println "ok   drift gate: emitted T1Core module is byte-identical"
    else
      IO.println "FAIL drift gate: emitted T1Core differs from committed \
        relsem/RelSem/T1Core.lean — regenerate deliberately with \
        .lake/build/bin/emit-lean-core"
      failures := failures + 1
  -- 1b. Slate drift gate (arc-7 S5a).
  let slateTexts ← EmitLeanCore.readSlateInputs
  match EmitLeanCore.emitSlateModule slateTexts with
  | .error e =>
    IO.println s!"FAIL slate emit: {e}"
    failures := failures + 1
  | .ok emitted =>
    let committed ← IO.FS.readFile
      (root ++ "lean_frontend/relsem/RelSem/SlateCore.lean")
    if emitted == committed then
      IO.println "ok   drift gate: emitted SlateCore module is byte-identical"
    else
      IO.println "FAIL drift gate: emitted SlateCore differs from committed \
        relsem/RelSem/SlateCore.lean — regenerate deliberately with \
        .lake/build/bin/emit-lean-core slate"
      failures := failures + 1
  -- 1c. Corpus drift gate (V0 2026-08-27).
  let (corpusTexts, corpusStd) ← EmitLeanCore.readCorpusInputs
  match EmitLeanCore.emitCorpusModule corpusTexts corpusStd with
  | .error e =>
    IO.println s!"FAIL corpus emit: {e}"
    failures := failures + 1
  | .ok emitted =>
    let committed ← IO.FS.readFile
      (root ++ "lean_frontend/relsem/RelSem/CorpusCore.lean")
    if emitted == committed then
      IO.println "ok   drift gate: emitted CorpusCore module is byte-identical"
    else
      IO.println "FAIL drift gate: emitted CorpusCore differs from committed \
        relsem/RelSem/CorpusCore.lean — regenerate deliberately with \
        .lake/build/bin/emit-lean-core corpus"
      failures := failures + 1
  -- 2. Concrete differential on the theorem object.
  for x in concretePoints do
    match runT1 x with
    | .inl n =>
      if n == x then
        IO.println s!"ok   callND t1File id({x}) = Specified({n})"
      else
        IO.println s!"FAIL callND t1File id({x}) = Specified({n}), expected {x}"
        failures := failures + 1
    | .inr msg =>
      IO.println s!"FAIL callND t1File id({x}): {msg}"
      failures := failures + 1
  -- 2b. Slate concrete differential on the theorem objects (T4's
  -- struct layout needs the tag global — exactly the T4EnvHyp state).
  let _ ← (CerbTags.setTagDefsIO t4File.tagDefs : BaseIO Unit)
  for (label, file1, fname, args, expect) in slatePoints do
    match runSlate file1 fname args, expect with
    | .inl n, .inl m =>
      if n == m then
        IO.println s!"ok   callND {label} {fname}{args} = Specified({n})"
      else
        IO.println s!"FAIL callND {label} {fname}{args} = Specified({n}), expected {m}"
        failures := failures + 1
    | .inr "UB", .inr () =>
      IO.println s!"ok   callND {label} {fname}{args} = UB (as recorded)"
    | .inr msg, .inr () =>
      IO.println s!"FAIL callND {label} {fname}{args}: {msg}, expected UB"
      failures := failures + 1
    | .inl n, .inr () =>
      IO.println s!"FAIL callND {label} {fname}{args} = Specified({n}), expected UB"
      failures := failures + 1
    | .inr msg, .inl m =>
      IO.println s!"FAIL callND {label} {fname}{args}: {msg}, expected Specified({m})"
      failures := failures + 1
  -- 2c. Corpus concrete differential on the assembled theorem
  -- objects (V0; p12's struct layout needs the tag global).
  let _ ← (CerbTags.setTagDefsIO p12File.tagDefs : BaseIO Unit)
  for (label, file1, fname, args, expect) in corpusPoints do
    match runSlate file1 fname args, expect with
    | .inl n, .inl m =>
      if n == m then
        IO.println s!"ok   callND {label} {fname}{args} = Specified({n})"
      else
        IO.println s!"FAIL callND {label} {fname}{args} = Specified({n}), expected {m}"
        failures := failures + 1
    | .inr "UB", .inr () =>
      IO.println s!"ok   callND {label} {fname}{args} = UB (as recorded)"
    | .inr msg, .inr () =>
      IO.println s!"FAIL callND {label} {fname}{args}: {msg}, expected UB"
      failures := failures + 1
    | .inl n, .inr () =>
      IO.println s!"FAIL callND {label} {fname}{args} = Specified({n}), expected UB"
      failures := failures + 1
    | .inr msg, .inl m =>
      IO.println s!"FAIL callND {label} {fname}{args}: {msg}, expected Specified({m})"
      failures := failures + 1
  -- 2d. Batch-B family sample drives (V0).
  for (label, file1, expect) in corpusBPoints do
    let _ ← (CerbTags.setTagDefsIO file1.tagDefs : BaseIO Unit)
    match runDrive file1 with
    | .inl n =>
      if n == expect then
        IO.println s!"ok   drive {label} = Specified({n})"
      else
        IO.println s!"FAIL drive {label} = Specified({n}), expected {expect}"
        failures := failures + 1
    | .inr msg =>
      IO.println s!"FAIL drive {label}: {msg}"
      failures := failures + 1
  if failures == 0 then
    IO.println "EmitLeanCoreTest: ALL PASSED"
    return 0
  else
    IO.println s!"EmitLeanCoreTest: {failures} FAILURE(S)"
    return 1
