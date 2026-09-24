import Sc_candidate

namespace SCUnit.SCCandidate
open Lem_Basic_classes

private def set {α : Type} [SetType α] (xs : List α) : Pset α :=
  setFromListBy setElemCompare xs

private def f := SCRef_Fence 0 (.SCRef_Tid_hol 0) .SCRef_Seq_cst
private def f' := SCRef_Fence 1 (.SCRef_Tid_hol 1) .SCRef_Seq_cst
private def w := SCRef_Store 2 (.SCRef_Tid_hol 0) .SCRef_Seq_cst (.SCRef_Loc_hol 0) (.SCRef_Cvalue_hol 0)
private def w' := SCRef_Store 3 (.SCRef_Tid_hol 1) .SCRef_Seq_cst (.SCRef_Loc_hol 0) (.SCRef_Cvalue_hol 1)
private def r := SCRef_Load 4 (.SCRef_Tid_hol 1) .SCRef_Seq_cst (.SCRef_Loc_hol 0) (.SCRef_Cvalue_hol 0)
private def actions := [f,f',w,w',r]

private def candidate (a : List sc_ref_action) (sb rf mo sc : List (sc_ref_action × sc_ref_action)) :
    sc_ref_candidate_execution :=
  let pre : sc_ref_pre_execution :=
    ⟨set a, set [.SCRef_Tid_hol 0,.SCRef_Tid_hol 1], fun _ => .SCRef_Atomic, set sb, set [], set []⟩
  let wit : sc_ref_execution_witness := ⟨set rf, set mo, set sc, set [], set []⟩
  (pre,wit,[])

-- Each forbidden clause, then deletion of each necessary relation edge.
-- These intentionally include malformed candidates: the fence optimization
-- must agree even before other well-formedness predicates are applied.
private def fenceCases : List (List (sc_ref_action × sc_ref_action) ×
    List (sc_ref_action × sc_ref_action) × List (sc_ref_action × sc_ref_action)) := [
  ([(f,r)], [(w,r)], [(w',f)]),
  ([(w',f)], [(w,r)], [(f,r)]),
  ([(w',f),(f',r)], [(w,r)], [(f,f')]),
  ([(w',f),(f',w)], [], [(f,f')]),
  ([(f,w)], [], [(w',f)]),
  ([(w',f)], [], [(f,w)])]

private def agree (ex : sc_ref_candidate_execution) : Bool :=
  sc_candidate_fences_heeded ex == sc_ref_sc_fenced_sc_fences_heeded ex

private def removeEach {α : Type} (xs : List α) : List (List α) :=
  (List.range xs.length).map fun i => xs.take i ++ xs.drop (i+1)

private def checks : List (String × Bool) := Id.run do
  let allEdges := (List.range 3).flatMap fun a => (List.range 3).map fun b => (a,b)
  let closure := (List.range 512).all fun mask =>
    let edges := set ((allEdges.zipIdx).filterMap fun (edge,i) =>
      if mask / 2^i % 2 == 1 then some edge else none)
    setEqualBy setElemCompare (sc_occurrence_closure edges)
      (set_tcByCmp (pairCompare defaultCompare defaultCompare) edges)
  let clauses := fenceCases.all fun (sb,rf,sc) =>
    let ex := candidate actions sb rf [(w,w')] sc
    !sc_candidate_fences_heeded ex && agree ex &&
    (removeEach sb).all (fun edges => agree (candidate actions edges rf [(w,w')] sc)) &&
    (removeEach rf).all (fun edges => agree (candidate actions sb edges [(w,w')] sc)) &&
    (removeEach sc).all (fun edges => agree (candidate actions sb rf [(w,w')] edges)) &&
    agree (candidate actions sb rf [] sc)
  let arbitrary := (List.range 32).all fun seed =>
    let relation := fun salt => actions.flatMap fun a => actions.filterMap fun b =>
      let x := (seed+1)*1103515245 + sc_ref_aid_of a * 12345 + sc_ref_aid_of b * 31 + salt * 97
      if x % 7 < 2 then some (a,b) else none
    let sb := relation 0
    let rf := relation 1
    let mo := relation 2
    let sc := relation 3
    agree (candidate actions sb rf mo sc) &&
    agree (candidate [f,w,r] sb rf mo sc) &&
    agree (candidate [w,w',r] sb rf mo sc) && agree (candidate [] sb rf mo sc)
  let relations := (List.range 32).all fun seed =>
    let (pre,wit,_) := candidate actions
      (if seed % 2 == 0 then [(w,f),(f,r)] else [(f,r),(r,f)])
      (if seed % 3 == 0 then [(w,r)] else [(w',r)])
      [(w,w')] (if seed % 5 == 0 then [(f,f')] else [])
    sc_candidate_relations pre wit == sc_ref_release_acquire_fenced_relations pre wit
  return [
    ("occurrence closure agrees on every three-vertex directed graph", closure),
    ("candidate relation calculation agrees with pinned reference", relations),
    ("all six reference fence restrictions and edge deletion controls", clauses),
    ("fence restriction agrees with pinned predicate on bounded malformed and empty inputs", arbitrary)]

def runTests : IO UInt32 := do
  let mut passed := true
  for (label,ok) in checks do
    IO.println s!"{label}: {ok}"
    passed := passed && ok
  return if passed then 0 else 1

end SCUnit.SCCandidate
