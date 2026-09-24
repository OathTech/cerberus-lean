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

private def occurrence (id thread : Nat) (kind : sc_request_kind)
    (observation : CerbMem.MemoryObservation) (sb : List (Nat × Nat) := [])
    (asw : List Nat := []) : sc_effect :=
  ⟨id, ⟨id,thread,⟨set sb,set [],set asw⟩,kind,[]⟩,observation⟩

private def metadata (id thread : Nat) (cursor : Int) (operation : varargs_observation)
    (sb : List (Nat × Nat) := []) (asw : List Nat := []) :=
  occurrence id thread (SC_runtime "varargs") (Observe_varargs operation cursor) sb asw

private def classify (history : List sc_effect) :=
  sc_classify_candidate (sc_interpret_candidate { sc_initial_state with sc_effects := history })

private def metadataChecks : List (String × Bool) := Id.run do
  let created := metadata 1 0 7 Varargs_create
  let read := metadata 4 1 7 Varargs_read
  let racing := classify [read,created]
  let ordered := classify [metadata 4 1 7 Varargs_read [] [1],created]
  let unsequenced := classify [metadata 4 0 7 Varargs_advance,created]
  let scalar := Ctype [] (Basic (Integer (Unsigned Ichar)))
  let atomic := Ctype [] (Atomic scalar)
  let ptr := CerbMem.nullPtrval scalar
  let value := CerbMem.integerValueMval (Unsigned Ichar) (CerbMem.integerIval 7)
  let bytes : List CerbMem.AbsByte := [{value := some 7}]
  let allocated := occurrence 0 0 (SC_lifetime Pos)
    (Observe_allocation ptr 10 100 1 (some atomic) none [])
  let store := occurrence 2 0 (SC_access Seq_cst Pos)
    (Observe_access CerbLocation.unknown StoreAccess atomic ptr (some 10) 100 1 bytes value) [(0,1)]
  let load := occurrence 3 1 (SC_access Seq_cst Pos)
    (Observe_access CerbLocation.unknown LoadAccess atomic ptr (some 10) 100 1 bytes value)
  let acquired := classify [metadata 4 1 7 Varargs_read [(1,3)],load,store,created,allocated]
  let joined := classify [metadata 4 0 7 Varargs_read [] [3],load,store,created,allocated]
  let retained := sc_retain_findings ordered (sc_retain_findings racing sc_no_findings)
  return [
    ("metadata-only ordered execution is classified without invented Cmm actions",
      sc_candidate_accepted ordered &&
      setToList ordered.sc_class_interpretation.sc_candidate_execution.1.sc_ref_actions == []),
    ("shared cursor conflict reaches the production data-race classification",
      setEqualBy setElemCompare racing.sc_class_data_races (set [(1,4)])),
    ("same-thread cursor conflict reaches unsequenced classification",
      setEqualBy setElemCompare unsequenced.sc_class_unsequenced_races (set [(1,4)])),
    ("independent cursors and concurrent read/read are accepted",
      sc_candidate_accepted (classify [metadata 4 1 8 Varargs_advance,created]) &&
      sc_candidate_accepted (classify [read,metadata 1 0 7 Varargs_read])),
    ("atomic publication orders metadata through lifted reference synchronization",
      sc_candidate_accepted acquired && setMemberBy setElemCompare (1,4)
        acquired.sc_class_interpretation.sc_candidate_happens_before.sc_hb_relation),
    ("cross-thread HB does not substitute for same-thread source sequencing",
      setMemberBy setElemCompare (1,4) joined.sc_class_interpretation.sc_candidate_happens_before.sc_hb_relation &&
      setMemberBy setElemCompare (1,4) joined.sc_class_unsequenced_races),
    ("later classifications retain an established metadata conflict",
      setMemberBy setElemCompare (1,4) retained.sc_found_data_races)]

private def arrayChecks : List (String × Bool) := Id.run do
  let scalar := Ctype [] (Basic (Integer (Signed Int_)))
  let row := Ctype [] (Array0 scalar (some 3))
  let matrix := Ctype [] (Array0 row (some 2))
  let ptr := CerbMem.nullPtrval scalar
  let allocated := occurrence 0 0 (SC_lifetime Pos)
    (Observe_allocation ptr 20 100 24 (some matrix) none [])
  let store := fun id thread address => occurrence id thread (SC_access NA Pos)
    (Observe_access CerbLocation.unknown StoreAccess scalar ptr (some 20) address 4
      (List.replicate 4 {value := some 0})
      (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval 0)))
  let disjoint := classify [store 2 1 120,store 1 0 104,allocated]
  let same := classify [store 2 1 104,store 1 0 104,allocated]
  let pair := occurrence 0 0 (SC_lifetime Pos)
    (Observe_allocation ptr 20 100 8 (some (Ctype [] (Array0 scalar (some 2)))) none [])
  let wide := occurrence 2 1 (SC_access NA Pos)
    (Observe_access CerbLocation.unknown StoreAccess
      (Ctype [] (Basic (Integer (Signed LongLong)))) ptr (some 20) 100 8
      (List.replicate 8 {value := some 0})
      (CerbMem.integerValueMval (Signed LongLong) (CerbMem.integerIval 0)))
  let overlapping := classify [wide,store 1 0 104,pair]
  let initialized := occurrence 1 0 (SC_access NA Pos)
    (Observe_access CerbLocation.unknown StoreAccess matrix ptr (some 20) 100 24
      (List.replicate 24 {value := none}) (CerbMem.unspecifiedMval matrix))
  let later := store 2 1 104
  let published := { later with sc_effect_request := { later.sc_effect_request with
    sc_request_annotation := ⟨set [],set [],set [1]⟩ } }
  return [
    ("nested array element stores have distinct scalar locations",
      sc_candidate_accepted disjoint),
    ("two threads storing the same array element still race",
      setEqualBy setElemCompare same.sc_class_data_races (set [(1,2),(2,1)])),
    ("a wider overlapping array view cannot certify separate scalar locations",
      !sc_candidate_supported overlapping &&
      overlapping.sc_class_interpretation.sc_candidate_issues.contains (SC_interpret_object_layout 2)),
    ("unspecified array initialization must precede its subobject accesses",
      sc_candidate_accepted (classify [published,initialized,allocated]) &&
      !sc_candidate_supported (classify [later,initialized,allocated])),
    ("array layout does not justify partial scalar or crossed-element accesses",
      !sc_candidate_array_element matrix 100 24 105 1 &&
      !sc_candidate_array_element matrix 100 24 102 4 &&
      !sc_candidate_array_element matrix 100 24 124 4),
    ("incomplete zero and inconsistent array extents stay unresolved",
      !sc_candidate_array_element (Ctype [] (Array0 scalar none)) 100 24 104 4 &&
      !sc_candidate_array_element (Ctype [] (Array0 scalar (some 0))) 100 24 104 4 &&
      !sc_candidate_array_element matrix 100 23 104 4)]

private def aggregateChecks : List (String × Bool) := Id.run do
  let scalar := Ctype [] (Basic (Integer (Unsigned Ichar)))
  let tag := Symbol "whole-aggregate-control" 90 SD_None
  let x := Identifier CerbLocation.unknown "x"
  let y := Identifier CerbLocation.unknown "y"
  let one := CerbMem.integerValueMval (Unsigned Ichar) (CerbMem.integerIval 1)
  let two := CerbMem.integerValueMval (Unsigned Ichar) (CerbMem.integerIval 2)
  let shapes := [(Ctype [] (Array0 scalar (some 2)), CerbMem.arrayMval [one,two]),
    (Ctype [] (Struct tag), CerbMem.structMval tag [(x,scalar,one),(y,scalar,two)])]
  let ptr := CerbMem.nullPtrval scalar
  let bytes : List CerbMem.AbsByte := [{value := some 1},{value := some 2}]
  let full := shapes.all fun (ty,value) =>
    let allocated := occurrence 0 0 (SC_lifetime Pos)
      (Observe_allocation ptr 20 100 2 (some ty) none [])
    let access := fun id thread kind sb => occurrence id thread (SC_access NA Pos)
      (Observe_access CerbLocation.unknown kind ty ptr (some 20) 100 2 bytes value) sb
    let written := access 1 0 StoreAccess []
    let read := access 2 0 LoadAccess [(0,1)]
    let initialized := occurrence 0 0 (SC_lifetime Pos)
      (Observe_allocation ptr 20 100 2 (some ty) (some value) bytes)
    sc_candidate_accepted (classify [read,written,allocated]) &&
    sc_candidate_accepted (classify [access 2 0 LoadAccess [(0,0)],initialized])
  let conflicts := shapes.all fun (ty,value) =>
    let allocated := occurrence 0 0 (SC_lifetime Pos)
      (Observe_allocation ptr 20 100 2 (some ty) none [])
    let written := fun id thread => occurrence id thread (SC_access NA Pos)
      (Observe_access CerbLocation.unknown StoreAccess ty ptr (some 20) 100 2 bytes value)
    let classified := classify [written 2 1,written 1 0,allocated]
    setEqualBy setElemCompare classified.sc_class_data_races (set [(1,2),(2,1)])
  let partialViews := shapes.all fun (ty,value) =>
    let initialized := occurrence 0 0 (SC_lifetime Pos)
      (Observe_allocation ptr 20 100 2 (some ty) (some value) bytes)
    let narrow := occurrence 1 0 (SC_access NA Pos)
      (Observe_access CerbLocation.unknown StoreAccess scalar ptr (some 20) 101 1
        [{value := some 2}] two) [(0,0)]
    !sc_candidate_supported (classify [narrow,initialized])
  return [
    ("complete aggregate stores and allocation values supply matching whole reads", full),
    ("conflicting whole aggregate stores remain data races", conflicts),
    ("aggregate allocation initialization cannot certify a different overlapping view", partialViews)]

private def typedViewChecks : List (String × Bool) := Id.run do
  let unsigned := Ctype [] (Basic (Integer (Unsigned Ichar)))
  let signed := Ctype [] (Basic (Integer (Signed Ichar)))
  let ptr := CerbMem.nullPtrval unsigned
  let allocated := occurrence 0 0 (SC_lifetime Pos)
    (Observe_allocation ptr 20 100 1 (some unsigned) none [])
  let access := fun id kind ty ity n prov => occurrence id 0 (SC_access NA Pos)
    (Observe_access CerbLocation.unknown kind ty ptr (some 20) 100 1 [{value := some 255}]
      (CerbMem.integerValueMval ity (.IV prov n)))
    (if id == 2 then [(0,1)] else [])
  let write := access 1 StoreAccess unsigned (Unsigned Ichar) 255 .Prov_none
  let read := access 2 LoadAccess signed (Signed Ichar) (-1) .Prov_none
  let reverseWrite := access 1 StoreAccess signed (Signed Ichar) (-1) .Prov_none
  let reverseRead := access 2 LoadAccess unsigned (Unsigned Ichar) 255 .Prov_none
  let changed := access 2 LoadAccess signed (Signed Ichar) (-1) (.Prov_some 99)
  return [
    ("corresponding signed and unsigned views use the same RF value in both directions",
      sc_candidate_accepted (classify [read,write,allocated]) &&
      sc_candidate_accepted (classify [reverseRead,reverseWrite,allocated])),
    ("implementation integer aliases share tokens without collapsing different ranks",
      sc_candidate_logical_key 8 (SC_integer_value Size_t SC_no_provenance 7) ==
        sc_candidate_logical_key 8 (SC_integer_value (Unsigned Long) SC_no_provenance 7) &&
      sc_candidate_logical_key 8 (SC_integer_value Ptrdiff_t SC_no_provenance (-1)) ==
        sc_candidate_logical_key 8 (SC_integer_value (Signed Long) SC_no_provenance (-1)) &&
      sc_candidate_logical_key 8 (SC_integer_value (Signed LongLong) SC_no_provenance 7) !=
        sc_candidate_logical_key 8 (SC_integer_value (Signed Long) SC_no_provenance 7)),
    ("typed-view normalization preserves provenance distinctions",
      !sc_candidate_accepted (classify [changed,write,allocated]) &&
      (classify [changed,write,allocated]).sc_class_interpretation.sc_candidate_issues ==
        [SC_interpret_source_value 1 2])]

private def checks : List (String × Bool) := Id.run do
  let allEdges := (List.range 3).flatMap fun a => (List.range 3).map fun b => (a,b)
  let closure := (List.range 512).all fun mask =>
    let edges := set ((allEdges.zipIdx).filterMap fun (edge,i) =>
      if mask / 2^i % 2 == 1 then some edge else none)
    setEqualBy setElemCompare (sc_occurrence_closure edges)
      (set_tcByCmp (pairCompare defaultCompare defaultCompare) edges)
  let vertices := [0,10,17,100]
  let forward := vertices.flatMap fun a => vertices.filterMap fun b =>
    if a < b then some (a,b) else none
  let sparseClosure := (List.range 64).all fun mask =>
    let edges := set ((forward.zipIdx).filterMap fun (edge,i) =>
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
    ("indexed closure agrees on every four-vertex forward graph with sparse IDs", sparseClosure),
    ("candidate relation calculation agrees with pinned reference", relations),
    ("all six reference fence restrictions and edge deletion controls", clauses),
    ("fence restriction agrees with pinned predicate on bounded malformed and empty inputs", arbitrary)]

def runTests : IO UInt32 := do
  let mut passed := true
  for (label,ok) in checks ++ metadataChecks ++ arrayChecks ++ aggregateChecks ++ typedViewChecks do
    IO.println s!"{label}: {ok}"
    passed := passed && ok
  return if passed then 0 else 1

end SCUnit.SCCandidate
