import Unit.SCProtocolSupport

open Lem_Basic_classes Lem_Set SCProtocolControls

def fenceExpr (order : memory_order) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC fence control")
    empty_annotation (Fence0 order))))
def seqExpr (a b : expr core_run_annotation) : expr core_run_annotation :=
  Expr [] (Esseq (Pattern [] (CaseBase (none, BTy_unit))) a b)

def checkFences (fuel : Nat) (name : String) (body : expr core_run_annotation)
    (test : driver_state → Bool) : IO Bool :=
  letI := LemFuel.mk fuel
  let results := runProgram (program body) memorySetup
  let passed := !results.isEmpty && results.all (fun (outcome, _, s) =>
    match outcome with | Active r => !r.dres_blocked && test s | _ => false)
  IO.println (name ++ ": " ++ toString results.length ++ " alternatives; pass=" ++ toString passed) >>= fun _ => pure passed

def checkWeakOrder (fuel : Nat) (order : memory_order) (make : memory_order → expr core_run_annotation) : Bool :=
  letI := LemFuel.mk fuel
  let results := runProgram (program (make order)) memorySetup
  !results.isEmpty && results.all (fun (outcome, _, s) =>
    (memoryEffects s).isEmpty && match outcome with
    | Killed _ (Other (DErr_concurrency msg)) => msg == "SC model excludes the requested memory order"
    | _ => false)

def main (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let mut good := true
  good := (← checkFences fuel "fence has no fabricated memory access" (fenceExpr Seq_cst) (fun s =>
    (memoryEffects s).isEmpty && match s.sc_state0 with
    | some sc => sc.sc_fences.length == 1
    | none => false)) && good
  good := (← checkFences fuel "fence propagates both sequencing boundaries"
    (seqExpr (storeExpr 20 200) (seqExpr (fenceExpr Seq_cst) (storeExpr 30 300))) (fun s =>
      match s.sc_state0, memoryEffects s with
      | some sc, [first, last] => match sc.sc_fences with
        | [fence] => setMemberBy setElemCompare (first.sc_effect_request.sc_request_thread,first.sc_effect_id)
            fence.sc_request_annotation.sb_before &&
          setMemberBy setElemCompare (fence.sc_request_thread,fence.sc_request_id)
            last.sc_effect_request.sc_request_annotation.sb_before
        | _ => false
      | _, _ => false)) && good
  good := (← checkFences fuel "unsequenced fences retain both orders"
    (Expr [] (Eunseq [fenceExpr Seq_cst, fenceExpr Seq_cst])) (fun s =>
      match s.sc_state0 with
      | some sc => match sc.sc_fences with
        | [later, earlier] =>
          !setMemberBy setElemCompare (earlier.sc_request_thread,earlier.sc_request_id) later.sc_request_annotation.sb_before &&
          !setMemberBy setElemCompare (later.sc_request_thread,later.sc_request_id) earlier.sc_request_annotation.sb_before
        | _ => false
      | none => false)) && good
  good := (← checkFences fuel "join retains child fence"
    (seqExpr (parExpr [fenceExpr Seq_cst]) (storeExpr 30 300)) (fun s =>
      match s.sc_state0, memoryEffects s with
      | some sc, [access] => match sc.sc_fences with
        | [fence] => fence.sc_request_thread != access.sc_effect_request.sc_request_thread &&
          setMemberBy setElemCompare fence.sc_request_id access.sc_effect_request.sc_request_annotation.asw_before
        | _ => false
      | _, _ => false)) && good
  let weak := [Relaxed, Consume, Acquire, Release, Acq_rel]
  let load := fun order => Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC weak load") empty_annotation
    (Load0 (pe (Vctype unsigned_char)) (pe (Vobject (OVpointer (pointer 20 200)))) order))))
  let store := fun order => Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC weak store") empty_annotation
    (Store0 false (pe (Vctype unsigned_char)) (pe (Vobject (OVpointer (pointer 20 200)))) (pe (intval 7)) order))))
  for (name, make) in [("load",load),("store",store),("fence",fenceExpr)] do
    let passed := weak.all (fun order => checkWeakOrder fuel order make)
    IO.println ("five weak orders refused before " ++ name ++ " effects: pass=" ++ toString passed)
    good := passed && good
  return if good then 0 else 1
