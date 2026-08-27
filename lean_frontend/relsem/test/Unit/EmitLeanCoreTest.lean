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

set_option autoImplicit false

open RelSem.Cerb RelSem.T1 RelSem.Slate

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
   ("t5", t5File, "sum", [100], .inl 4950),
   ("t6", t6File, "pick", [10], .inl 7),
   ("t6", t6File, "pick", [4], .inl 1),
   ("t6", t6File, "pick", [3], .inl 6),
   ("t6", t6File, "pick", [-5], .inl (-2)),
   ("t7", t7File, "flip", [7], .inl 0),
   ("t7", t7File, "flip", [8], .inl 0),
   ("t7", t7File, "flip", [2], .inl (-2)),
   ("t7", t7File, "flip", [0], .inl 0),
   -- arc-18 R6 breadth corpus, batch 1 (EASY tier): the
   -- expectations.txt rows on the assembled theorem objects.
   ("e1", e1File, "clamp0", [-3], .inl 0),
   ("e1", e1File, "clamp0", [5], .inl 5),
   ("e1", e1File, "clamp0", [0], .inl 0),
   ("e1", e1File, "clamp0", [-2147483648], .inl 0),
   ("e2", e2File, "abs3", [-5], .inl 5),
   ("e2", e2File, "abs3", [7], .inl 7),
   ("e2", e2File, "abs3", [0], .inl 0),
   ("e2", e2File, "abs3", [-2147483648], .inr ()),
   ("e3", e3File, "scale", [7], .inl 17),
   ("e3", e3File, "scale", [0], .inl 3),
   ("e3", e3File, "scale", [-5], .inl (-7)),
   ("e3", e3File, "scale", [1073741822], .inl 2147483647),
   ("e3", e3File, "scale", [2147483647], .inr ()),
   ("e4", e4File, "is_digit", [53], .inl 1),
   ("e4", e4File, "is_digit", [47], .inl 0),
   ("e4", e4File, "is_digit", [48], .inl 1),
   ("e4", e4File, "is_digit", [57], .inl 1),
   ("e4", e4File, "is_digit", [58], .inl 0),
   ("e5", e5File, "is_mark", [42], .inl 1),
   ("e5", e5File, "is_mark", [45], .inl 1),
   ("e5", e5File, "is_mark", [41], .inl 1),
   ("e5", e5File, "is_mark", [47], .inl 0),
   ("e5", e5File, "is_mark", [65], .inl 0),
   -- arc-18 R6 breadth corpus, batch 2 (CENSUS tier).
   ("c4", c4File, "hex_val", [102], .inl 15),
   ("c4", c4File, "hex_val", [48], .inl 0),
   ("c4", c4File, "hex_val", [57], .inl 9),
   ("c4", c4File, "hex_val", [70], .inl 15),
   ("c4", c4File, "hex_val", [103], .inl (-1)),
   ("c4", c4File, "hex_val", [47], .inl (-1)),
   ("c5", c5File, "pct_hi", [65], .inl 52),
   ("c5", c5File, "pct_hi", [255], .inl 70),
   ("c5", c5File, "pct_hi", [160], .inl 65),
   ("c5", c5File, "pct_hi", [9], .inl 48),
   ("c3a", c3aFile, "acc10", [21474836, 5], .inl 214748365),
   ("c3a", c3aFile, "acc10", [214748364, 7], .inl 2147483647),
   ("c3a", c3aFile, "acc10", [214748364, 8], .inl (-1)),
   ("c3a", c3aFile, "acc10", [300000000, 0], .inl (-1)),
   ("c3a", c3aFile, "acc10", [-1, 5], .inl (-1)),
   ("c3a", c3aFile, "acc10", [0, 0], .inl 0),
   ("c3b", c3bFile, "lead_digit", [273], .inl 2),
   ("c3b", c3bFile, "lead_digit", [7], .inl 7),
   ("c3b", c3bFile, "lead_digit", [100000], .inl 1),
   ("c3b", c3bFile, "lead_digit", [99], .inl 9),
   -- arc-18 R6 breadth corpus, batch 3 (edge loop rows; c9 is the
   -- PARKED array-lane frontier — its file is assembled and pinned
   -- but carries no slate points until the lane lands).
   ("x7", x7File, "is_pow2", [6], .inl 0),
   ("x7", x7File, "is_pow2", [8], .inl 1),
   ("x7", x7File, "is_pow2", [1], .inl 1),
   ("x7", x7File, "is_pow2", [12], .inl 0),
   ("x7", x7File, "is_pow2", [0], .inl 1),
   ("x2", x2File, "cap10", [273], .inl 27),
   ("x2", x2File, "cap10", [99], .inl 99),
   ("x2", x2File, "cap10", [100000], .inl 10),
   ("x2", x2File, "cap10", [0], .inl 0)]

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
  if failures == 0 then
    IO.println "EmitLeanCoreTest: ALL PASSED"
    return 0
  else
    IO.println s!"EmitLeanCoreTest: {failures} FAILURE(S)"
    return 1
