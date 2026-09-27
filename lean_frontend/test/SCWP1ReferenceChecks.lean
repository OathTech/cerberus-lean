import Unit.SCWP1Contracts

namespace SCWP1ReferenceChecks
open SCWP1Contracts SCWP1Stepping Lem_Basic_classes

def check : IO Unit := do
  let x := scalarWitness
  require (well_formed_threads x && atomic_initialisation_before_all x &&
    apply_tree SC_memory_model.consistent x && each_empty SC_memory_model.undefined x)
    "nonempty initialized scalar witness rejected or undefined"
  let acts := setToList x.1.actions
  let some i := acts.find? (fun a => aid_of a == 0) | throw (IO.userError "missing init")
  let some w := acts.find? (fun a => aid_of a == 1) | throw (IO.userError "missing write")
  let some r := acts.find? (fun a => aid_of a == 2) | throw (IO.userError "missing read")
  let witness := { x.2.1 with rf := setFromListBy setElemCompare [(i,r)] }
  let wrongValue := (x.1,witness,SC_memory_model.relation_calculation x.1 witness)
  require (!(apply_tree SC_memory_model.consistent wrongValue)) "reference admitted false read-from value"
  let witness := { x.2.1 with sc := setFromListBy setElemCompare [(r,w)] }
  let backwards := (x.1,witness,SC_memory_model.relation_calculation x.1 witness)
  require (!(apply_tree SC_memory_model.consistent backwards)) "reference admitted SC order opposite source order"
  let pre := { x.1 with sb := setFromListBy setElemCompare [(i,w),(i,r)] }
  require (!(well_formed_threads (pre,x.2.1,x.2.2))) "unordered same-thread atomics satisfy reference domain"
  let a := Store 0 0 NA (CerbMem.PointerValue.PV .Prov_none (.PVconcrete none 4096))
    (CerbMem.MemValue.MVinteger (.Unsigned .Ichar) (.IV .Prov_none 0))
  let b := Store 1 1 NA (CerbMem.PointerValue.PV .Prov_none (.PVconcrete none 4096))
    (CerbMem.MemValue.MVinteger (.Unsigned .Ichar) (.IV .Prov_none 1))
  let pre : pre_execution := {
    actions := setFromListBy setElemCompare [a,b],
    threads := setFromListBy setElemCompare [0,1], lk := fun _ => Non_Atomic,
    sb := setEmpty, asw := setEmpty, dd := setEmpty }
  let racy := (pre,empty_witness,SC_memory_model.relation_calculation pre empty_witness)
  require (apply_tree SC_memory_model.consistent racy &&
    !(each_empty SC_memory_model.undefined racy))
    "reference consistency/undefinedness separation control failed"
  IO.println "pinned cmm_csem finite scalar witness: 3 actions defined; wrong rf value, reversed SC order, missing atomic source order rejected; two racing writes consistent but undefined"
  IO.println "scope: finite graph diagnostic only; no reliance on program-level true stubs or imported bigthm"

#eval check
end SCWP1ReferenceChecks
