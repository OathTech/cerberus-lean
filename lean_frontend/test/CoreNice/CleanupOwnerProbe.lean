import BreakpointMain

/-! Inspect the live arena at the ordinary offered-schedule refusal for the
two-parameter cleanup witness. No host trace is used to reconstruct a focus. -/
namespace CoreNiceDiff.CleanupOwnerProbe
open CoreNiceDiff

private structure Owner where
  operand : Nat
  cleanup : Option (Nat × sym) := none
  deriving BEq

private def cleanupScope : CoreNice.context → Option (Nat × sym)
  | .Cannot _ _ c => cleanupScope c
  | .Csseq _ (.Pattern _ (.CaseBase (none, .BTy_tuple [.BTy_unit, .BTy_unit])))
      (.Cunseq _ before .CTX after) (_, .Expr _ (.Epure (.Pexpr _ _ (.PEsym binder)))) =>
    if before.length + after.length == 1 then some (before.length, binder) else none
  | _ => none

private def owner : CoreNice.context → Option Owner
  | .Cwseq ann _ (.Cunseq _ before focus after) _ =>
    if ann.contains (.Astd "§6.5.8") && before.length + after.length == 1 then
      some ⟨before.length, cleanupScope focus⟩
    else owner focus
  | .Cunseq _ _ c _ | .Cwseq _ _ c _ | .Csseq _ _ c _ | .Cannot _ _ c | .Cbound _ c => owner c
  | .CTX => none

private structure Param where
  id : Int
  index : Int
  site : CerbLocation.Loc
  returnBinder : sym

private def liveStatic (m : CerbMem.MemState) (ctx : CoreNice.context)
    (expr : CoreNice.expr CoreNice.core_run_annotation) : Except String Param := do
  let some ⟨0, some (slot, binder)⟩ := owner ctx | throw "missing left operand's cleanup scope"
  let .Expr _ (.Eaction (.Paction _ (.Action loc _ (.Kill (.Static0 _)
      (.Pexpr _ _ (.PEval (.Vobject (.OVpointer (.PV (.Prov_some id) (.PVconcrete _ address)))))))))) := expr
    | throw "expected a concrete static kill"
  let some a := m.allocations.get? id | throw "missing live allocation"
  if a.base != address || m.deadAllocations.contains id then throw "not a live base pointer"
  let .PrefFunArg site _ index := a.prefix_ | throw "expected an argument allocation"
  if loc != site || slot != index then throw "allocation site/index disagrees with the cleanup focus"
  return ⟨id, index, site, binder⟩

private def check (m : CerbMem.MemState)
    (foci : List (CoreNice.context × CoreNice.expr CoreNice.core_run_annotation)) : Except String Unit := do
  let [(userCtx, .Expr _ (.Eccall ..)), (c1, e1), (c0, e0)] := foci | throw "wrong three-way frontier"
  if owner userCtx != some ⟨1, none⟩ then throw "user call is outside the right operand"
  let b ← liveStatic m c1 e1
  let a ← liveStatic m c0 e0
  if a.id == b.id || a.index != 0 || b.index != 1 then throw "wrong parameter identities"
  if a.site != b.site || a.returnBinder != b.returnBinder then throw "distinct sites or return continuations"

def run (runtime input : String) : IO Unit := do
  let fuel : LemFuel := ⟨1000000⟩
  let switches : CerbGlobal.Switches := ⟨[]⟩
  let pre ← @prepare fuel runtime input 0xFFFFFFFFFFFF []
  let e ← @lowerSaturatedNice fuel pre
  let .ok e := e.capture true | throw (IO.userError "capture failed")
  let opts : Options := ⟨runtime,input,"","record",1000000,0xFFFFFFFFFFFF,"probe","probe",none,none,[]⟩
  let h := header "CoreNice" opts pre e.translatedSupply e.initialSupply
  let action := @CoreNice.drive_until_breakpoint fuel switches e.file.enumDefs e.file.tagDefs false e.file pre.argv opts.fuel
  let obs := {ObservationNice.observer with sourceOrder := some OfferedOrder.select}
  let result ← (CerberusFresh.forceIO (fun () => Choice.run opts.fuel obs (.record .first) h
    (@Breakpoints.advance fuel switches .none opts.fuel 0 action) e.state) : BaseIO _)
  let .refused _ := result.outcome | throw (IO.userError "expected the offered policy refusal")
  let [(_, _, thread)] := result.finalState.core_state0.thread_states | throw (IO.userError "expected one thread")
  match check result.finalState.layout_state (CoreNice.get_ctx thread.arena) with
  | .error message => throw (IO.userError message)
  | .ok () => IO.println "Matched left cleanup slots 0 and 1, live distinct parameter objects, same return binder, and right user call."

end CoreNiceDiff.CleanupOwnerProbe

def main (args : List String) : IO Unit := do
  let [runtime, input] := args | throw (IO.userError "expected runtime and Cabs JSON")
  CoreNiceDiff.CleanupOwnerProbe.run runtime input
