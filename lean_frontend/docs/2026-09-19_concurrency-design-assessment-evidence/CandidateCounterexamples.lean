import Driver
open Lem_Num Lem_Pervasives Lem_List Lem_Set Lem_Map Lem_Maybe Lem_Function
  Lem_Show Lem_Show_extra Lem_Bool Lem_Basic_classes Lem_Map_extra
  Lem_String_extra Lem_Num_extra Lem_Set_helpers Lem_Either Lem_Assert_extra
  Lem_Set_extra Lem_List_extra Lem_Relation Lem_Tuple Lem_String Lem_Word Mem
set_option autoImplicit false
namespace AuditCandidates
def x : CerbMem.PointerValue := CerbMem.concretePtrval 1 4096
def val (n : Int) : CerbMem.MemValue := CerbMem.integerValueMval (.Signed .Int_) (CerbMem.integerIval n)
def rel (xs : List (action × action)) : Pset (action × action) := setFromListBy setElemCompare xs
def acts (xs : List action) : Pset action := setFromListBy setElemCompare xs
def w : action := .Store 1 0 .NA x (val 1)
def r (n : Int) : action := .Load 2 0 .NA x (val n)
def pre (n : Int) (ordered : Bool) : pre_execution :=
  { actions := acts [w, r n], threads := setFromListBy setElemCompare [0],
    lk := fun _ => .Non_Atomic, sb := rel (if ordered then [(w, r n)] else []),
    asw := rel [], dd := rel [] }
def wit (n : Int) : execution_witness := { empty_witness with rf := rel [(w, r n)] }
def candidate (n : Int) (ordered : Bool) : pre_execution × execution_witness × relation_list :=
  (pre n ordered, wit n, release_acquire_fenced_relations (pre n ordered) (wit n))
-- In both cases T is the strict total order [w, r n].  sb/asw are subsets,
-- rf selects the latest prior same-location write, and mo/sc/lo/tot are empty.
-- Both have zero interthread data races. These are abstract construction
-- counterexamples to L2(i)'s written hypotheses, not actual C executions.
#eval do
  for (label,n,ordered) in [("missing sequenced-before premise",1,false),
                            ("missing value-correspondence premise",2,true),
                            ("positive control",1,true)] do
    let ex := candidate n ordered
    IO.println s!"{label}: data_races_empty={(setToList (data_races ex)).isEmpty}; well_formed_threads={well_formed_threads ex}; failing_leaves={sc_failing_leaves "root" sc_accesses_consistent_execution ex}"
end AuditCandidates
