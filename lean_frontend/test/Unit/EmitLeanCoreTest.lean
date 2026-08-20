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

set_option autoImplicit false

open RelSem.Cerb RelSem.T1

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
  if failures == 0 then
    IO.println "EmitLeanCoreTest: ALL PASSED"
    return 0
  else
    IO.println s!"EmitLeanCoreTest: {failures} FAILURE(S)"
    return 1
