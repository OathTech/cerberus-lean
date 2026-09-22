import Unit.SCProtocolSupport
import CerbSCByteSources

open SCProtocolControls Lem_Basic_classes

private def loc := CerbLocation.other "SC byte-source control"
private def wordType : ctype := Ctype [] (Basic (Integer (Unsigned Int_)))

private def baseState : driver_state :=
  let f := program (pureExpr Vunit)
  let s := (initial_driver_state 2 0x10000 f CerbFS.fs_initial_state).1
  let s := { s with layout_state := { s.layout_state with
    allocations := (s.layout_state.allocations.insert 20 {base := 200, size := 4}).insert
      30 {base := 300, size := 4} } }
  (CerbSCOperational.node
    (sc_enable : ndM Unit step_kind driver_error (mem_constraint CerbMem.IntegerValue) driver_state) s).2

private def perform [LemFuel] {α : Type} (m : CerbMem.memM α) (s : driver_state) :=
  CerbSCOperational.node (driver_liftMem m)
    (sc_request_state 0 (SC_runtime "byte-source control") empty_annotation s)

private def wordStore [LemFuel] (n : Int) :=
  CerbMem.storeM baseState.core_file.tagDefs loc wordType false (pointer 20 200)
    (CerbMem.integerValueMval (Unsigned Int_) (CerbMem.integerIval n))

private def byteStore [LemFuel] (address n : Int) :=
  CerbMem.storeM baseState.core_file.tagDefs loc unsigned_char false (pointer 20 address)
    (CerbMem.integerValueMval (Unsigned Ichar) (CerbMem.integerIval n))

private def wordLoad [LemFuel] :=
  CerbMem.loadM baseState.core_file.tagDefs loc wordType (pointer 20 200)

private def effects (s : driver_state) := match s.sc_state0 with
  | some sc => sc.sc_effects
  | none => []

private def completed {α : Type} (node : nd_action α step_kind driver_error
    (mem_constraint CerbMem.IntegerValue) driver_state) : Bool :=
  match node with | NDactive _ => true | _ => false

private def checks (fuel : Nat) : List (String × Bool) := Id.run do
  letI := LemFuel.mk fuel
  let whole := perform (wordStore 0x01020304) baseState
  let byte := perform (byteStore 201 0x03) whole.2 -- equal byte, distinct writer
  let loaded := perform wordLoad byte.2
  let mixed := match effects loaded.2, sc_read_byte_history (effects loaded.2) with
    | [r, b, w], [sources] =>
      sources.sc_read_source_id == r.sc_effect_id && sources.sc_read_reported_size == 4 &&
      sources.sc_read_sources == [SC_byte_store w.sc_effect_id 0, SC_byte_store b.sc_effect_id 0,
        SC_byte_store w.sc_effect_id 2, SC_byte_store w.sc_effect_id 3]
    | _, _ => false
  let repeated := perform wordLoad loaded.2
  let readDoesNotWrite := match sc_read_byte_history (effects repeated.2) with
    | [later, earlier] => later.sc_read_source_id != earlier.sc_read_source_id &&
      later.sc_read_sources == earlier.sc_read_sources
    | _ => false
  let overwrite := perform (wordStore 0x01020304) repeated.2
  let afterOverwrite := perform wordLoad overwrite.2
  let wholeWins := match effects afterOverwrite.2, sc_read_byte_history (effects afterOverwrite.2) with
    | _ :: w :: _, current :: _ => current.sc_read_sources ==
      [SC_byte_store w.sc_effect_id 0, SC_byte_store w.sc_effect_id 1,
       SC_byte_store w.sc_effect_id 2, SC_byte_store w.sc_effect_id 3]
    | _, _ => false
  let copied := perform (CerbMem.memcpyM baseState.core_file.tagDefs loc
    (pointer 30 300) (pointer 20 200) (CerbMem.integerIval 4)) byte.2
  let copyLoad := perform (CerbMem.loadM baseState.core_file.tagDefs loc wordType (pointer 30 300)) copied.2
  let copiedSources := match effects copyLoad.2, sc_read_byte_history (effects copyLoad.2) with
    | _ :: w3 :: _ :: w2 :: _ :: w1 :: _ :: w0 :: _ :: _, current :: _ =>
      current.sc_read_sources == [SC_byte_store w0.sc_effect_id 0, SC_byte_store w1.sc_effect_id 0,
        SC_byte_store w2.sc_effect_id 0, SC_byte_store w3.sc_effect_id 0]
    | _, _ => false
  let trap := perform (CerbMem.loadM baseState.core_file.tagDefs loc
    (Ctype [] (Basic (Integer Bool0))) (pointer 20 200)) whole.2
  let failedReadSource := match trap.1, effects trap.2, sc_read_byte_history (effects trap.2) with
    | NDkilled _, [r,w], [current] => current.sc_read_source_id == r.sc_effect_id &&
        current.sc_read_sources == [SC_byte_store w.sc_effect_id 0]
    | _, _, _ => false
  let allocated := perform (CerbMem.allocateObject baseState.core_file.tagDefs 0
    (PrefOther "byte-source allocation") (CerbMem.integerIval 4) wordType none none) baseState
  let lifetime := match allocated.1, effects allocated.2 with
    | NDactive ptr, [allocation] =>
      let initialRead := perform (CerbMem.loadM baseState.core_file.tagDefs loc wordType ptr) allocated.2
      let initialSource := match sc_read_byte_history (effects initialRead.2) with
        | [current] => current.sc_read_sources == [SC_byte_allocation allocation.sc_effect_id 0,
            SC_byte_allocation allocation.sc_effect_id 1, SC_byte_allocation allocation.sc_effect_id 2,
            SC_byte_allocation allocation.sc_effect_id 3]
        | _ => false
      let killed := perform (CerbMem.killM loc false ptr) initialRead.2
      let staleRead := perform (CerbMem.loadM baseState.core_file.tagDefs loc wordType ptr) killed.2
      let ended := match allocation.sc_effect_observation, effects killed.2 with
        | Observe_allocation _ owner base _ _ _ _, death :: _ =>
            sc_byte_source_at owner base (effects killed.2) == SC_byte_after_deallocation death.sc_effect_id
        | _, _ => false
      completed initialRead.1 && completed killed.1 && initialSource && ended &&
        (match staleRead.1 with | NDkilled _ => true | _ => false) &&
        sc_read_byte_history (effects staleRead.2) == sc_read_byte_history (effects killed.2)
    | _, _ => false
  let differentStorage := match effects whole.2 with
    | [w] => sc_byte_source_at 30 200 [w] == SC_byte_no_observed_source
    | _ => false
  return [
    ("all actual memory controls complete", completed whole.1 && completed byte.1 &&
      completed loaded.1 && completed repeated.1 && completed overwrite.1 &&
      completed afterOverwrite.1 && completed copied.1 && completed copyLoad.1),
    ("equal-byte overwrite remains a distinct source inside a word", mixed),
    ("successive reads preserve source identities", readDoesNotWrite),
    ("later whole equal-value store replaces every earlier source", wholeWins),
    ("actual memcpy creates four distinct destination writes", copiedSources),
    ("trap failure retains its completed read and physical source", failedReadSource),
    ("allocation sources and lifetime end remain distinct from stores", lifetime),
    ("the same address in a different storage instance does not inherit a writer", differentStorage)]

def main (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let mut good := true
  for (label, ok) in checks fuel do
    IO.println s!"{label}: {ok}"
    good := good && ok
  return if good then 0 else 1
