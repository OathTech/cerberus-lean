import Driver
import Sc_candidate
import LemLib
import CerbLocation
import CerbMem
import Sc_access_sequencing
import Sc_graph
import Sc_runtime
import Mem_common
import Mem
import Core
import Core_run_aux
import Cmm_csem
import Ctype
import LemLib.Pervasives
import LemLib.Pervasives_extra
import LemLib.Bridges
import Sc_reference
import Sc_reference_aux
import Unit.SCProtocolSupport

namespace SCUnit.SCSequencing
open Lem_Num
open Lem_Pervasives
open Lem_List
open Lem_Set
open Lem_Relation
open Lem_Maybe
open Lem_Basic_classes
open Lem_Bool
open Lem_Tuple
open Lem_Either
open Lem_Function
open Lem_Map
open Lem_String
open Lem_Word
open Lem_Show
open Lem_Sorting
open Lem_Set_helpers
open Lem_Show_extra
open Lem_Set_extra
open Lem_String_extra
open Lem_List_extra
open Lem_Assert_extra
open Lem_Map_extra



def  sc_sequence_fixture  (id1 : Nat) (request : Nat) (thread : Nat) (kind : sc_request_kind) (access : access_kind) (annotation : core_run_annotation)  : sc_effect :=  (({ sc_effect_id :=  id1,sc_effect_request :=  (({ sc_request_id :=  request,sc_request_thread :=  thread,sc_request_kind0 :=  kind,sc_request_scopes :=  [],sc_request_annotation :=  annotation  } : sc_request)),sc_effect_observation :=  (Observe_access  CerbLocation.unknown  access      signed_int  (CerbMem.nullPtrval  signed_int)  (some (( 7 :  Int))) (( 100 :  Int)) (( 4 :  Int))  []      (CerbMem.unspecifiedMval  signed_int))
 } : sc_effect))
def  sc_sequence_ids  (graph : sc_source_graph) (history : List (sc_effect))  : List ((Nat ×Nat)) :=  List.map  (fun (w : sc_access_sequence_witness) =>
  (w.sc_sequence_left.sc_effect_id,
   w.sc_sequence_right.sc_effect_id))
  (sc_access_sequence_witnesses  graph  history)
def  sc_sequence_graph  (effects : List (sc_effect))  : sc_source_graph :=  sc_build_source_graph
  (List.map  sc_effect_node  effects)
def  sc_sequence_checks  (_ : Unit)  : List ((String ×Bool)) :=
  let  annotation0  := empty_annotation;
  let  order  := SC_access  Seq_cst  Pos;
  let  ordinary  := SC_access  NA  Pos;
  let  read1  := sc_sequence_fixture (  1) (  10) (  0)  order  LoadAccess  annotation0;
  let  second1  := sc_sequence_fixture (  3) (  11) (  0)  order  LoadAccess  annotation0;
  let  modify2  := (fun (annotation : core_run_annotation) (e : sc_effect) =>  {  e  with sc_effect_request :=      {  e.sc_effect_request  with sc_request_annotation :=  annotation  }  });
  let  before  := (fun (id1 : Nat) =>  {  annotation0  with sb_before :=  (setFromListBy setElemCompare [(  0,id1)])  });
  let  history  := [read1, second1];
  let  query  := (fun (h : List (sc_effect)) =>  sc_sequence_ids  (sc_sequence_graph  h)  h);
  let  nread  := sc_sequence_fixture (  1) (  10) (  0)  ordinary  LoadAccess  annotation0;
  let  nsecond  := sc_sequence_fixture (  3) (  11) (  0)  ordinary  LoadAccess  annotation0;
  let  middle  := {  {  read1  with sc_effect_observation :=  Observe_varargs  Varargs_read (( 9 :  Int))  }  with sc_effect_id :=   2  };
  let  update1  := sc_sequence_fixture (  1) (  10) (  0)  (SC_atomic_update  Seq_cst)      LoadAccess  annotation0;
  let  write  := {  {  update1  with sc_effect_observation :=  Observe_access  CerbLocation.unknown  StoreAccess        signed_int  (CerbMem.nullPtrval  signed_int)  (some (( 7 :  Int))) (( 100 :  Int)) (( 4 :  Int))  []        (CerbMem.unspecifiedMval  signed_int)  }  with sc_effect_id :=   2  };
  let  other  := sc_sequence_fixture (  3) (  11) (  1)  order  LoadAccess  annotation0;
  let  bridged  := [read1,     sc_sequence_fixture (  2) (  12) (  1)  ordinary  LoadAccess        {  annotation0  with asw_before :=  (setFromListBy setElemCompare [  1])  },     modify2  {  annotation0  with asw_before :=  (setFromListBy setElemCompare [  2])  }  second1];
  let  graph  := sc_sequence_graph  bridged;
  let  broken  := [read1, modify2  (before (  99))  second1];
  [
    ("unordered SC pair retains one orientation", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  history)  [(  1,  3)])),
    ("journal reversal does not invent ordering", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  (List.reverse  history))  [(  1,  3)])),
    ("ordinary pair is outside this sufficient query", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [nread,nsecond])  [])),
    ("mixed unordered pair is retained", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [nread,second1])  [(  1,  3)])),
    ("forward source edge removes witness", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [read1,modify2  (before (  1))  second1])  [])),
    ("reverse source edge removes witness", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [modify2  (before (  3))  read1,second1])  [])),
    ("source closure passes through metadata", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [read1,modify2  (before (  1))  middle,
      modify2  (before (  2))  second1])  [])),
    ("additional-sw closure is not substituted for source order", ((setMemberBy  (pairCompare  defaultCompare  defaultCompare)
      (  1,  3)  graph.sc_graph_sbasw)  &&  (listEqualBy  (@pairEqual (Nat) (Nat) _ _)
      (sc_sequence_ids  graph  bridged)  [(  1,  3)]))),
    ("data dependency is not source order", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [read1,
      modify2  {  annotation0  with dd_before :=  (setFromListBy setElemCompare [  1])  }  second1])  [(  1,  3)])),
    ("same atomic compound is not two actions", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [update1,write])  [])),
    ("compound occurrences retain external witnesses", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [update1,write,second1])  [(  1,  3),(  2,  3)])),
    ("cross-thread pair is outside sequencing assumption", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [read1,other])  [])),
    ("metadata does not inherit an access role", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [middle,second1])  [])),
    ("weak access order remains unavailable", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [read1,
      sc_sequence_fixture (  3) (  11) (  0)  (SC_access  Relaxed  Pos)
        LoadAccess  annotation0])  [])),
    ("out-of-model CAS expected phase remains unavailable", (maybeEqualBy  (fun x y => x == y)
      (sc_access_request_order
        (SC_cas_expected  Seq_cst  Relaxed  Pos))  none)),
    ("NA expected load retains its actual role", (maybeEqualBy  (fun x y => x == y)
      (sc_access_request_order
        (SC_cas_expected  Seq_cst  Seq_cst  Pos))  (some  NA))),
    ("failed CAS object read retains SC role", (listEqualBy  (@pairEqual (Nat) (Nat) _ _)  (query  [
      sc_sequence_fixture (  1) (  10) (  0)  (SC_cas_object  Pos)  LoadAccess  annotation0,
      nsecond])  [(  1,  3)])),
    ("protocol issues remain distinct from sequence witnesses",
      (not  (List.isEmpty  (sc_sequence_graph  broken).sc_graph_issues)  &&  (listEqualBy  (@pairEqual (Nat) (Nat) _ _)
      (query  broken)  [(  1,  3)])))]


open SCProtocolControls CerbSCOperational Lem_Basic_classes
namespace SCPrefixOperationalControls
private def seqExpr (first second : expr core_run_annotation) :=
  Expr [] (Esseq (Pattern [] (CaseBase (none, BTy_unit))) first second)
private def loadExpr (id address : Int) :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC prefix control") empty_annotation
    (Load0 (pe (Vctype unsigned_char)) (pe (Vobject (OVpointer (pointer id address)))) Seq_cst))))
private def allWitnesses (state : driver_state) :=
  setToList state.sc_findings.sc_found_atomic_sequencing
private def prefixValid (state : driver_state) := match state.sc_candidate with
  | none => false
  | some result =>
      let graph := result.sc_class_interpretation.sc_candidate_graph
      graph.sc_graph_issues.isEmpty && (allWitnesses state).all fun (a,b) =>
        graph.sc_graph_nodes.any (fun n => n.sc_node_id == a) &&
        graph.sc_graph_nodes.any (fun n => n.sc_node_id == b)

private def controls [LemFuel] : List (String × Bool) := Id.run do
  let two := Expr [] (Eunseq [loadExpr 20 200, loadExpr 30 300])
  let unsequenced := runProgram (program two) memorySetup
  let ordered := runProgram (program (seqExpr (loadExpr 20 200) (loadExpr 30 300))) memorySetup
  let laterFault := runProgram (program (seqExpr two
    (seqExpr (storeExpr 30 300) (storeExpr 20 201)))) memorySetup
  let faults := laterFault.filterMap fun (status, _, state) => match status with
    | Killed _ reason => some (reason,state)
    | _ => none
  let faultIndependent := faults.all fun (reason,_) => match reason with
    | Other (DErr_concurrency _) => false
    | _ => true
  return [
    ("every unsequenced alternative retains actual pair evidence",
      unsequenced.length > 1 && unsequenced.all fun (status,_,state) => match status with
        | Active _ => (memoryEffects state).length == 2 &&
            (allWitnesses state).length == 1 && prefixValid state
        | _ => false),
    ("source ordered alternatives acquire no sequencing obligation",
      !ordered.isEmpty && ordered.all fun (status,_,state) => match status with
        | Active _ => (memoryEffects state).length == 2 && (allWitnesses state).isEmpty
        | _ => false),
    ("later independent faults retain evidence and the intervening effect",
      laterFault.length > 1 && faults.length == laterFault.length && faultIndependent &&
      faults.all fun (_,state) =>
        (memoryEffects state).length == 3 &&
        (allWitnesses state).length == 1 && prefixValid state &&
        match state.sc_state0 with
        | some sc => match sc.sc_effects with
          | newest :: _ => (allWitnesses state).all fun (a,b) => a < newest.sc_effect_id && b < newest.sc_effect_id
          | [] => false
        | none => false)]


private def serviceThread (tid : Nat) : thread_state := {
  arena := pureExpr (intval (Int.ofNat tid)), stack0 := Stack_empty,
  errno := pointer 20 200, env := [], current_proc_opt := none,
  exec_loc := ELoc_globals, current_loc := CerbLocation.other "SC prefix service" }
private def serviceSetup (state : driver_state) := { memorySetup state with
  core_state0 := { state.core_state0 with
    thread_states := [(0,(none,serviceThread 0)),(1,(some 0,serviceThread 1))] } }
private def loadStep (tid : Nat) (order : memory_order) (id address : Int) :=
  Step_action_request2 empty_annotation Pos "prefix load" CerbLocation.unknown tid false
    (stExceptUndef_return (LoadRequest2 order unsigned_char (pointer id address)
      (fun _ _ _ => serviceThread tid)))
private def copyStep := Step_memop_request2 empty_annotation CerbLocation.unknown Memcpy
  [Vobject (OVpointer (pointer 30 300)), Vobject (OVpointer (pointer 20 200)),
   Vobject (OVinteger (CerbMem.integerIval 1))] 0 false
  (fun _ _ => serviceThread 0)
private def progressState (result : nd_action sc_step_progress step_kind driver_error
    (mem_constraint CerbMem.IntegerValue) sc_machine_state × sc_machine_state) :=
  match result.1 with | NDactive SC_continue => some result.2 | _ => none
private def service [LemFuel] (tid : Nat) (step : core_step2) (state : sc_machine_state) :=
  progressState (node (sc_start_machine_choice state.sc_driver_state.core_file.tagDefs
    (SC_start_service tid step)) state)
private def resume [LemFuel] (state : sc_machine_state) := do
  let saved ← state.sc_service_state.sc_suspended_services.find? fun saved => sc_saved_thread saved == 0
  progressState (node (sc_start_machine_choice state.sc_driver_state.core_file.tagDefs
    (SC_resume_service saved)) state)

private def suspensionControls [LemFuel] : List (String × Bool) := Id.run do
  let base := serviceSetup (initial_driver_state 2 0x10000 (program (pureExpr Vunit)) CerbFS.fs_initial_state).1
  let initial := sc_machine_initial (node (sc_enable : driverM Unit) base).2
  let some first := service 0 (loadStep 0 Seq_cst 20 200) initial
    | return [("initial SC access completes",false)]
  let some second := service 0 (loadStep 0 NA 30 300) first
    | return [("initial ordinary access completes",false)]
  let some paused := service 0 copyStep second
    | return [("helper captures a suspended continuation",false)]
  let some interposed := service 1 (loadStep 1 Seq_cst 20 200) paused
    | return [("other thread's SC access completes",false)]
  let some interposed := service 1 (loadStep 1 NA 30 300) interposed
    | return [("other thread adds its own sequence obligation",false)]
  let some finished := resume interposed
    | return [("captured helper resumes",false)]
  let prior := allWitnesses second.sc_driver_state
  let current := allWitnesses interposed.sc_driver_state
  let final := allWitnesses finished.sc_driver_state
  return [
    ("suspension retains the original discovered prefix",
      !prior.isEmpty && !paused.sc_service_state.sc_suspended_services.isEmpty &&
      prior.all (allWitnesses paused.sc_driver_state).contains),
    ("resumption preserves obligations added by another thread",
      current.length > (allWitnesses paused.sc_driver_state).length &&
      current.all final.contains && finished.sc_service_state.sc_suspended_services.isEmpty &&
      prefixValid finished.sc_driver_state)]

end SCPrefixOperationalControls
def runTests (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let rows := sc_sequence_checks () ++ @SCPrefixOperationalControls.controls ⟨fuel⟩ ++
    @SCPrefixOperationalControls.suspensionControls ⟨fuel⟩
  for (label,ok) in rows do IO.println s!"{label}: {ok}"
  return if rows.all (·.2) then 0 else 1

end SCUnit.SCSequencing
