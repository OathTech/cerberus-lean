import Unit.SCProtocolSupport
import CerbSCAtomicSurface
import Core_typing
import Sc_graph

open SCProtocolControls Lem_Basic_classes Lem_Map Lem_Set

private def gapLoc := CerbLocation.other "SC model-gap control"
private def gapPE (gap : core_model_gap) : pexpr := Pexpr [] () (PEmodel_gap gapLoc gap)
private def gapExpr (gap : core_model_gap) : expr core_run_annotation := Expr [] (Epure (gapPE gap))
private def seq (a b : expr core_run_annotation) : expr core_run_annotation :=
  Expr [] (Esseq (Pattern [] (CaseBase (none, BTy_unit))) a b)
private def signal (order : memory_order) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action gapLoc empty_annotation (SignalFence order))))
private def runBody (fuel : Nat) (body : expr core_run_annotation)
    (prepare : driver_state → driver_state := memorySetup) :=
  letI := LemFuel.mk fuel
  runProgram (program body) prepare
private def isGap (gap : core_model_gap) := fun
    (outcome : nd_status driver_result driver_error driver_state) =>
  match outcome with
  | Killed _ (Other (DErr_core_run (Model_gap location actual))) =>
      location == gapLoc && actual == gap
  | _ => false
private def byteAt (s : driver_state) := (s.layout_state.bytemap.get? 200).bind (·.value)
private def successful := fun (outcome : nd_status driver_result driver_error driver_state) =>
  match outcome with | Active r => !r.dres_blocked | _ => false

def main (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let mut good := true
  let check := fun label pass => do
    IO.println s!"{label}: {pass}"
    return pass
  for gap in [Model_gap_unspecified_atomic_order, Model_gap_pointer_atomic_fetch,
      Model_gap_atomic_lock_free_configuration] do
    let name := core_model_gap_name gap
    let rows := runBody fuel (gapExpr gap)
    good := (← check s!"{name}: direct typed refusal"
      (!rows.isEmpty && rows.all (fun (outcome,_,s) =>
        isGap gap outcome && (memoryEffects s).isEmpty && byteAt s == some 7))) && good
    let unused := Expr [] (Elet (Pattern [] (CaseBase (none, BTy_unit)))
      (gapPE gap) (pureExpr Vunit))
    let rows := runBody fuel (seq (storeExpr 20 200) unused)
    good := (← check s!"{name}: unused result retains prior equal-value write"
      (!rows.isEmpty && rows.all (fun (outcome,_,s) =>
        isGap gap outcome && (memoryEffects s).length == 1 && byteAt s == some 7))) && good
    let nested := Expr [] (Epure (Pexpr [] () (PEctor Ctuple [pe Vunit, gapPE gap])))
    let rows := runBody fuel nested
    good := (← check s!"{name}: constructor traversal preserves refusal"
      (!rows.isEmpty && rows.all (fun (outcome,_,_) => isGap gap outcome))) && good
    let dead := Expr [] (Eif (pe Vfalse) (gapExpr gap) (pureExpr (intval 3)))
    let rows := runBody fuel dead
    good := (← check s!"{name}: unselected branch remains executable"
      (!rows.isEmpty && rows.all (fun (outcome,_,s) => (memoryEffects s).isEmpty &&
        match outcome with | Active r => r.dres_core_value == intval 3 | _ => false))) && good
    let rows := runBody fuel (Expr [] (Eunseq [gapExpr gap, storeExpr 20 200]))
    good := (← check s!"{name}: unsequenced alternatives retain their own prefixes"
      (!rows.isEmpty && rows.all (fun (outcome,_,s) => isGap gap outcome && byteAt s == some 7) &&
        rows.any (fun (_,_,s) => (memoryEffects s).isEmpty) &&
        rows.any (fun (_,_,s) => (memoryEffects s).length == 1))) && good
    let updateSym := Symbol "surface-control" 70 SD_None
    let update := Expr [] (Eaction (Paction Pos (Action gapLoc empty_annotation
      (AtomicUpdate false (pe (Vctype unsigned_char))
        (pe (Vobject (OVpointer (pointer 20 200)))) updateSym (gapPE gap) Seq_cst))))
    let prepare := fun s =>
      let s := memorySetup s
      let allocation : CerbMem.Allocation :=
        {base := 200, size := 1, ty := some (Ctype [] (Atomic unsigned_char))}
      let memory := {s.layout_state with allocations := s.layout_state.allocations.insert 20 allocation}
      {s with layout_state := memory}
    let rows := runBody fuel update prepare
    good := (← check s!"{name}: failed atomic update retains read without store"
      (!rows.isEmpty && rows.all (fun (outcome,_,s) => isGap gap outcome && byteAt s == some 7 &&
        match memoryEffects s with
        | [effect] => match effect.sc_effect_observation with
          | Observe_access _ LoadAccess _ _ _ _ _ _ _ => true
          | _ => false
        | _ => false))) && good
    let rows := runBody fuel (seq (Expr [] (Epure (Pexpr [] () (PEundef gapLoc UB045a_division_by_zero)))) (gapExpr gap))
    good := (← check s!"{name}: prior C fault remains C fault"
      (!rows.isEmpty && rows.all (fun (outcome,_,_) =>
        match outcome with | Killed _ (Undef0 _ [UB045a_division_by_zero]) => true | _ => false))) && good
  let orders := [Relaxed, Consume, Acquire, Release, Acq_rel, Seq_cst]
  good := (← check "all six signal orders retain exact occurrences without memory effects"
    (orders.all fun order =>
      let rows := runBody fuel (signal order)
      !rows.isEmpty && rows.all (fun (outcome,_,s) => successful outcome && (memoryEffects s).isEmpty &&
        match s.sc_state0 with
        | some sc => match sc.sc_fences with
          | [request] => request.sc_request_kind0 == SC_signal_fence order
          | _ => false
        | none => false))) && good
  let rows := runBody fuel (seq (storeExpr 20 200) (seq (signal Seq_cst) (storeExpr 30 300)))
  good := (← check "signal occurrence transmits source order between actual accesses"
    (!rows.isEmpty && rows.all (fun (outcome,_,s) => successful outcome &&
      match s.sc_state0, memoryEffects s with
      | some sc, [first,last] => match sc.sc_fences with
        | [fence] => effectBefore first last &&
            setMemberBy setElemCompare (first.sc_effect_request.sc_request_thread, first.sc_effect_id)
              fence.sc_request_annotation.sb_before &&
            setMemberBy setElemCompare (fence.sc_request_thread, fence.sc_request_id)
              last.sc_effect_request.sc_request_annotation.sb_before
        | _ => false
      | _, _ => false))) && good
  let rows := runBody fuel (parExpr [signal Relaxed, signal Seq_cst])
  good := (← check "parallel signal fences do not acquire source synchronization"
    (!rows.isEmpty && rows.all (fun (outcome,_,s) => successful outcome &&
      match s.sc_state0 with
      | some sc =>
          let graph := sc_prefix_graph sc
          graph.sc_graph_nodes.length == sc.sc_effects.length + sc.sc_fences.length &&
            graph.sc_graph_issues.isEmpty &&
            match sc.sc_fences with
            | [a,b] => a.sc_request_thread != b.sc_request_thread &&
                !setMemberBy setElemCompare a.sc_request_id b.sc_request_annotation.asw_before &&
                !setMemberBy setElemCompare b.sc_request_id a.sc_request_annotation.asw_before
            | _ => false
      | none => false))) && good
  let expectedFailures := [[Relaxed], [Relaxed,Consume], [Relaxed,Consume,Acquire],
    [Relaxed], [Relaxed,Consume,Acquire], [Relaxed,Consume,Acquire,Seq_cst]]
  good := (← check "all 36 CAS order pairs match the independent strength table"
    ((orders.zip expectedFailures).all fun (success,allowed) => orders.all fun failure =>
      atomic_compare_orders_error success failure ==
        (if allowed.contains failure then none else some UB207_atomic_compare_exchange_memorder))) && good
  return if good then 0 else 1
