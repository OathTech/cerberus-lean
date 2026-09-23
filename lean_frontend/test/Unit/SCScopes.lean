import CerbSCScopes
import Unit.SCProtocolSupport

open SCProtocolControls CerbSCOperational Lem_Basic_classes

private def scopeSequence (left right : expr core_run_annotation) :=
  Expr [] (Esseq (Pattern [] (CaseBase (none, BTy_unit))) left right)

private def withCallee (body callee : expr core_run_annotation) : file core_run_annotation :=
  let f := program body
  { f with funs := (fmapAddBy (fun (x y : sym) => ordCompare x y) calleeSym
      (Proc CerbLocation.unknown none BTy_unit [] callee) f.funs) }

private def entries (scope : sc_scope_state) := scope.sc_scope_events.reverse.filterMap fun e =>
  match e with | SC_scope_entered entry => some entry | _ => none

private def controls [LemFuel] : List (String × Bool) := Id.run do
  let repeated := runProgram (withCallee (scopeSequence (callExpr false) (callExpr false)) (pureExpr Vunit))
  let parallel := runProgram (withCallee (parExpr [callExpr false, callExpr false])
    (storeExpr 20 200)) memorySetup
  let repeatedOK := !repeated.isEmpty && repeated.all fun (status, _, s) =>
    match status, s.sc_state0 with
    | Active _, some sc =>
      let scope := sc.sc_scopes
      scope.sc_scope_issues.isEmpty && scope.sc_scope_live.all (·.2.isEmpty) &&
      match entries scope with
      | [a,b] => a.sc_scope_id == 0 && b.sc_scope_id == 1 &&
          a.sc_scope_effect_frontier == b.sc_scope_effect_frontier &&
          a.sc_scope_frame.sc_frame_called == b.sc_scope_frame.sc_frame_called &&
          a.sc_scope_frame.sc_frame_arguments.isEmpty && b.sc_scope_frame.sc_frame_arguments.isEmpty
      | _ => false
    | _, _ => false
  let parallelOK := parallel.length > 1 && parallel.all fun (status, _, s) =>
    match status, s.sc_state0 with
    | Active _, some sc =>
      let scope := sc.sc_scopes
      scope.sc_scope_issues.isEmpty && scope.sc_scope_next == 2 &&
      scope.sc_scope_live.all (·.2.isEmpty) && (entries scope).all (·.sc_scope_parent.isNone) &&
      (memoryEffects s).length == 2 && (memoryEffects s).all fun effect =>
        match effect.sc_effect_request.sc_request_scopes with
        | [id] => (entries scope).any fun entry => entry.sc_scope_id == id &&
            entry.sc_scope_thread == effect.sc_effect_request.sc_request_thread
        | _ => false
    | _, _ => false
  return [("effect-free repeated calls keep distinct scopes at the same frontier", repeatedOK),
    ("each alternative keeps both child-call owners and no invented parent call", parallelOK)]

def main (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let rows := @controls ⟨fuel⟩
  for (label, good) in rows do IO.println s!"{label}: {good}"
  return if rows.all (·.2) then 0 else 1
