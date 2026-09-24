import Unit.SCProtocolSupport

namespace SCUnit.SCSeqRMW

open SCProtocolControls Lem_Basic_classes Lem_Map

private def bound (e : expr core_run_annotation) := Expr [] (Ebound e)
private def rmw : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC ordinary RMW") empty_annotation
    (SeqRMW false (pe (Vctype unsigned_char)) (pe (Vobject (OVpointer (pointer 20 200))))
      (Symbol "sc-rmw-control" 50 SD_None) (pe (intval 9))))))
private def rmwSequence (strong : Bool) (a b : expr core_run_annotation) :=
  let pat := Pattern [] (CaseBase (none, BTy_loaded OTy_integer))
  Expr [] (if strong then Esseq pat a b else Ewseq pat a b)

private def labels (s : driver_state) : List String :=
  (memoryEffects s).map fun e => match e.sc_effect_request.sc_request_kind0, e.sc_effect_observation with
    | SC_seq_rmw, Observe_access _ LoadAccess _ _ _ _ _ _ _ => "R"
    | SC_seq_rmw, Observe_access _ StoreAccess _ _ _ _ _ _ _ => "W"
    | _, _ => "X"

private def runBody (fuel : Nat) (body : expr core_run_annotation)
    (setup : driver_state → driver_state := memorySetup) :=
  letI := LemFuel.mk fuel
  let f := program body
  let f := { f with funs := (fmapAddBy (fun (a b : sym) => ordCompare a b) calleeSym
    (Proc CerbLocation.unknown none BTy_unit [] (storeExpr 30 300)) f.funs) }
  runProgram f setup

def runTests (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let mut good := true
  let check := fun name pass => do
    IO.println s!"{name}: {pass}"
    return pass
  let solo := runBody fuel (bound rmw)
  good := (← check "ordinary RMW returns old value and orders read before write"
    (!solo.isEmpty && solo.all (fun (outcome, _, s) => match outcome, memoryEffects s with
      | Active result, [r,w] => result.dres_core_value == intval 7 &&
        s.sc_pending.isEmpty && effectBefore r w &&
        r.sc_effect_request.sc_request_id != w.sc_effect_request.sc_request_id &&
        ((s.layout_state.bytemap.get? 200).bind (·.value)) == some 9
      | _, _ => false))) && good
  let parallel := runBody fuel (parExpr [bound rmw, storeExpr 30 300])
  IO.println s!"cross-thread RMW control: {parallel.length} alternatives"
  good := (← check "another thread can run between ordinary read and write"
    (!parallel.isEmpty && parallel.all (fun (outcome, _, s) => match outcome with
       | Active r => !r.dres_blocked && s.sc_pending.isEmpty
       | _ => false) && parallel.any (fun (_, _, s) => labels s == ["R","X","W"]))) && good
  let calls := runBody fuel (bound (Expr [] (Eunseq [rmw, callExpr true])))
  IO.println s!"same-thread C-call control: {calls.length} alternatives"
  good := (← check "same-thread indeterminate call cannot split ordinary RMW"
    (!calls.isEmpty && calls.all (fun (outcome, _, s) => match outcome with
       | Active r => !r.dres_blocked &&
         (labels s == ["X","R","W"] || labels s == ["R","W","X"])
       | _ => false) &&
     calls.any (fun (_, _, s) => labels s == ["X","R","W"]) &&
     calls.any (fun (_, _, s) => labels s == ["R","W","X"]))) && good
  for strong in [false, true] do
    let results := runBody fuel (bound (rmwSequence strong rmw (storeExpr 30 300)))
    good := (← check s!"RMW receipt preserves polarity across strong={strong} continuation"
      (!results.isEmpty && results.all (fun (outcome, _, s) => match outcome, memoryEffects s with
        | Active r, [readEffect,writeEffect,next] => !r.dres_blocked && effectBefore readEffect writeEffect &&
          effectBefore readEffect next && effectBefore writeEffect next == strong
        | _, _ => false))) && good
  let readonlySetup := fun s =>
    let s := memorySetup s
    let allocation : CerbMem.Allocation :=
      { base := 200, size := 1, isReadonly := .IsReadOnly ReadonlyConstQualified }
    let allocations := s.layout_state.allocations.insert 20 allocation
    { s with layout_state := { s.layout_state with allocations := allocations } }
  let refusedStore := runBody fuel (bound rmw) readonlySetup
  good := (← check "ordinary store failure retains its read and original bytes"
    (!refusedStore.isEmpty && refusedStore.all (fun (outcome, _, s) =>
      (memoryEffects s).length == 1 &&
      ((s.layout_state.bytemap.get? 200).bind (·.value)) == some 7 &&
      match outcome with | Killed _ (Undef0 _ [UB064_modifying_const]) => true | _ => false))) && good
  let killExpr := Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC RMW lifetime control")
    empty_annotation (Kill (Static0 unsigned_char) (pe (Vobject (OVpointer (pointer 20 200))))))))
  let lifetime := runBody fuel (parExpr [bound rmw, killExpr])
  IO.println s!"RMW lifetime control: {lifetime.length} alternatives"
  good := (← check "resumed ordinary store checks current lifetime after another thread frees"
    (!lifetime.isEmpty && lifetime.any (fun (outcome, _, s) =>
      (memoryEffects s).length == 1 && s.layout_state.deadAllocations.contains 20 &&
      ((s.layout_state.bytemap.get? 200).bind (·.value)) == some 7 &&
      match outcome with | Killed _ (Undef0 _ _) => true | _ => false))) && good
  return if good then 0 else 1

end SCUnit.SCSeqRMW
