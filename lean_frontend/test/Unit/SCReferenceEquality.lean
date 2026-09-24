import Sc_reference
import Sc_reference_aux
import Sc_access_sequencing
import LemLib
import CerbMem
import Cmm_csem
import Ctype
import Mem
import LemLib.Pervasives
import LemLib.Pervasives_extra
import LemLib.Bridges

namespace SCUnit.SCReferenceEquality
open Lem_Num
open Lem_Pervasives
open Lem_List
open Lem_Set
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
open Lem_Relation
open Lem_Set_helpers
open Lem_Show_extra
open Lem_Set_extra
open Lem_String_extra
open Lem_List_extra
open Lem_Assert_extra



def  sc_equality_control   (choice : Nat)  : Bool :=
  let  tid1  := SCRef_Tid_hol (  0);
  let  loc1  := SCRef_Loc_hol (  0);
  let  read  := SCRef_Load (  10)  tid1  SCRef_Seq_cst  loc1  (SCRef_Cvalue_hol (  1));
  let  store  := SCRef_Store (  10)  tid1  SCRef_Seq_cst  loc1  (SCRef_Cvalue_hol (  2));
  let  other  := SCRef_Load (  11)  tid1  SCRef_Seq_cst  loc1  (SCRef_Cvalue_hol (  1));
  let  pre  := (({ sc_ref_actions :=  (setEmpty),sc_ref_threads :=  (setEmpty),sc_ref_lk :=  (fun ( _ : sc_ref_location_impl) =>  SCRef_Non_Atomic),sc_ref_sb :=  (setEmpty),sc_ref_asw :=  (setEmpty),sc_ref_dd :=  (setEmpty)  } : sc_ref_pre_execution));
  let  changed  := {  pre  with sc_ref_lk :=  (fun ( _ : sc_ref_location_impl) =>  SCRef_Atomic)  };
  let  first1  := {  sc_ref_empty_witness  with sc_ref_rf :=  (setFromListBy setElemCompare [(read,read)])  };
  let  second1  := {  sc_ref_empty_witness  with sc_ref_rf :=  (setFromListBy setElemCompare [(store,store)])  };
  match  choice with  |  0 =>  sc_ref_action_equality  read  store |  1 =>  sc_ref_action_equality  read  other |  2 =>  sc_ref_pre_execution_equal  pre  changed |  _ =>  sc_ref_execution_witness_equal  first1  second1


def  sc_live_equality_control   (choice : Nat)  : Bool :=
  let  tid1  :=  0;
  let  loc1  := CerbMem.nullPtrval  signed_int;
  let  read  := Load (  10)  tid1  Seq_cst  loc1  (CerbMem.unspecifiedMval  signed_int);
  let  store  := Store (  10)  tid1  Seq_cst  loc1  (CerbMem.unspecifiedMval  signed_int);
  let  other  := Load (  11)  tid1  Seq_cst  loc1  (CerbMem.unspecifiedMval  signed_int);
  let  pre  := (({ actions :=  (setEmpty),threads :=  (setEmpty),lk :=  (fun ( _ : CerbMem.PointerValue) =>  Non_Atomic),sb :=  (setEmpty),asw :=  (setEmpty),dd :=  (setEmpty)  } : pre_execution));
  let  changed  := {  pre  with lk :=  (fun ( _ : CerbMem.PointerValue) =>  Atomic0)  };
  let  first1  := {  empty_witness  with rf :=  (setFromListBy setElemCompare [(read,read)])  };
  let  second1  := {  empty_witness  with rf :=  (setFromListBy setElemCompare [(store,store)])  };
  match  choice with  |  0 =>  action_equality  read  store |  1 =>  action_equality  read  other |  2 =>  pre_execution_equal  pre  changed |  _ =>  execution_witness_equal  first1  second1

private def checks : List (String × Bool) :=
  [("SC reference",sc_equality_control),("live Cmm",sc_live_equality_control)].flatMap fun (name, query) => [
    (name ++ " action equality uses occurrence IDs", query 0),
    (name ++ " distinct IDs remain unequal", !query 1),
    (name ++ " pre-execution equality retains upstream's lk omission", query 2),
    (name ++ " witness equality compares action-ID sets", query 3)]

def runTests : IO UInt32 := do
  for (label,ok) in checks do IO.println s!"{label}: {ok}"
  return if checks.all (·.2) then 0 else 1

-- Regression: generated comparisons must select the Cmm identity instances.
namespace CerbCmmEquality
open Lem_Basic_classes

theorem reference_action_identity (a b : sc_ref_action) :
    isEqual a b = isEqual (sc_ref_aid_of a) (sc_ref_aid_of b) := rfl

theorem live_action_identity (a b : action) :
    isEqual a b = isEqual (aid_of a) (aid_of b) := rfl

theorem reference_pre_execution_instance (a b : sc_ref_pre_execution) :
    isEqual a b = sc_ref_pre_execution_equal a b := rfl

theorem live_pre_execution_instance (a b : pre_execution) :
    isEqual a b = pre_execution_equal a b := rfl

theorem reference_witness_instance (a b : sc_ref_execution_witness) :
    isEqual a b = sc_ref_execution_witness_equal a b := rfl

theorem live_witness_instance (a b : execution_witness) :
    isEqual a b = execution_witness_equal a b := rfl

end CerbCmmEquality

end SCUnit.SCReferenceEquality
