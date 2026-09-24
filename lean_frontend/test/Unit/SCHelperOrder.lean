import Unit.SCProtocolSupport
import Sc_runtime

namespace SCUnit.SCHelperOrder
open SCProtocolControls Lem_Basic_classes

private def setup (s : driver_state) : driver_state :=
  { s with layout_state := { s.layout_state with
      allocations := (s.layout_state.allocations.insert 20 {base := 200, size := 4}).insert
        30 {base := 300, size := 4},
      bytemap := ([200,201,202,203,300,301,302,303] : List Int).foldl
        (fun bytes address => bytes.insert address {value := some 7}) s.layout_state.bytemap } }

private def copyExpr (count : Int) : expr core_run_annotation :=
  Expr [] (Ememop empty_annotation Memcpy [pe (Vobject (OVpointer (pointer 30 300))),
    pe (Vobject (OVpointer (pointer 20 200))), pe (Vobject (OVinteger (CerbMem.integerIval count)))])

private def internallyOrdered : List sc_effect → Bool
  | [] => true
  | first :: rest => rest.all (fun second => effectBefore first second && !effectBefore second first) &&
      internallyOrdered rest

private def requestEffects (s : driver_state) : List sc_effect :=
  match s.sc_state0 with
  | none => []
  | some sc => match sc.sc_current_request with
    | none => []
    | some request => sc.sc_effects.reverse.filter fun e =>
        e.sc_effect_request.sc_request_id == request.sc_request_id

private def varargsControls [LemFuel] (enabled : driver_state) : List (String × Bool) := Id.run do
  let started := CerbSCOperational.node (driver_liftMem
    (CerbMem.vaStart [(unsigned_char, pointer 20 200)]))
    (sc_request_state 0 (SC_memop Va_start) empty_annotation enabled)
  let NDactive va := started.1 | return [("varargs setup completed", false)]
  let copied := CerbSCOperational.node (driver_liftMem (CerbMem.vaCopy va))
    (sc_request_state 0 (SC_memop Va_copy) empty_annotation started.2)
  let advanced := CerbSCOperational.node (driver_liftMem (CerbMem.vaArg va unsigned_char))
    (sc_request_state 0 (SC_memop Va_arg) empty_annotation started.2)
  let exhausted := CerbSCOperational.node (driver_liftMem (CerbMem.vaArg va unsigned_char))
    (sc_request_state 0 (SC_memop Va_arg) empty_annotation advanced.2)
  let kinds := fun s => (requestEffects s).filterMap fun e => match e.sc_effect_observation with
    | Observe_varargs kind _ => some kind
    | _ => none
  return [
    ("va_copy retains ordered metadata read and creation", kinds copied.2 == [Varargs_read, Varargs_create] &&
      internallyOrdered (requestEffects copied.2) && match copied.1 with | NDactive _ => true | _ => false),
    ("va_arg retains ordered metadata read and advance", kinds advanced.2 == [Varargs_read, Varargs_advance] &&
      internallyOrdered (requestEffects advanced.2) && match advanced.1 with
      | NDactive p => p == pointer 20 200 | _ => false),
    ("exhausted va_arg retains its read and the prior argument index", kinds exhausted.2 == [Varargs_read] &&
      exhausted.2.layout_state.varargs == advanced.2.layout_state.varargs &&
      match exhausted.1 with | NDkilled _ => true | _ => false),
    ("new helper ownership retains the complete earlier metadata journal", match started.2.sc_state0, copied.2.sc_state0 with
      | some before, some after => after.sc_effects.drop 2 == before.sc_effects
      | _, _ => false)]

private def formattingControls [LemFuel] (enabled : driver_state) : List (String × Bool) := Id.run do
  let started := CerbSCOperational.node (driver_liftMem (CerbMem.vaStart []))
    (sc_request_state 0 (SC_memop Va_start) empty_annotation enabled)
  let NDactive (.IV _ vaId) := started.1 | return [("formatting varargs setup completed", false)]
  let thread : thread_state := {
    arena := pureExpr Vunit
    stack0 := Stack_empty
    errno := pointer 20 200
    env := []
    current_proc_opt := none
    exec_loc := ELoc_globals
    current_loc := CerbLocation.other "SC formatting order" }
  let base := { started.2 with core_state0 := { started.2.core_state0 with thread_states := [(0, (none, thread))] } }
  let perform := fun ptr fmt size =>
    let owned := sc_request_state 0 (SC_runtime "Core filesystem/runtime operation") empty_annotation base
    CerbSCOperational.node (drive_fs_step_with base.core_file.tagDefs (fun _ result => result)
      0 thread owned (FS_VSNPRINTF ptr (CerbMem.integerIval size) fmt vaId)) owned
  let formatted := perform (pointer 30 300) ['X'] 4
  let failed := perform (pointer 30 303) ['X', 'Y'] 4
  let zero := perform (pointer 30 300) ['X'] 0
  let shape := fun s => (requestEffects s).map fun e => match e.sc_effect_observation with
    | Observe_varargs Varargs_read _ => "va-read"
    | Observe_access _ StoreAccess _ _ _ _ _ _ _ => "store"
    | _ => "unexpected"
  let byteAt := fun s address => (s.layout_state.bytemap.get? address).bind (·.value)
  return [
    ("runtime vsnprintf orders its metadata read and character stores",
      shape formatted.2 == ["va-read", "store", "store"] && internallyOrdered (requestEffects formatted.2) &&
      byteAt formatted.2 300 == some 88 && byteAt formatted.2 301 == some 0 &&
      formatted.2.fs_state0 == base.fs_state0 && formatted.2.dr_step_counter == base.dr_step_counter + 1 &&
      match formatted.1 with | NDactive () => true | _ => false),
    ("runtime failure keeps the completed write and leaves filesystem and completion unchanged",
      shape failed.2 == ["va-read", "store"] && internallyOrdered (requestEffects failed.2) &&
      byteAt failed.2 303 == some 88 && failed.2.fs_state0 == base.fs_state0 &&
      failed.2.core_state0.thread_states == base.core_state0.thread_states &&
      failed.2.dr_step_counter == base.dr_step_counter && match failed.1 with
      | NDkilled _ => true | _ => false),
    ("zero-sized vsnprintf preserves upstream absence of varargs and byte effects",
      (requestEffects zero.2).isEmpty && zero.2.layout_state.bytemap == base.layout_state.bytemap &&
      zero.2.dr_step_counter == base.dr_step_counter + 1 && match zero.1 with
      | NDactive () => true | _ => false)]

private def controls (fuel : Nat) : List (String × Bool) := Id.run do
  letI := LemFuel.mk fuel
  let f := program (pureExpr Vunit)
  let base := setup (initial_driver_state 2 0x10000 f CerbFS.fs_initial_state).1
  let enabled := (CerbSCOperational.node
    (sc_enable : ndM Unit step_kind driver_error (mem_constraint CerbMem.IntegerValue) driver_state) base).2
  let perform := fun kind count =>
    CerbSCOperational.node (driver_liftMem (CerbMem.memcpyM f.tagDefs
      (CerbLocation.other "helper ordering") (pointer 30 300) (pointer 20 200)
      (CerbMem.integerIval count))) (sc_request_state 0 kind empty_annotation enabled)
  let copied := perform (SC_memop Memcpy) 2
  let runtime := perform (SC_runtime "helper ordering control") 2
  let failed := perform (SC_memop Memcpy) 5
  let accessKind := perform (SC_access NA Pos) 2
  let siblings := runProgram (program (Expr [] (Eunseq [copyExpr 2, storeExpr 30 302]))) setup
  let separate := !siblings.isEmpty && siblings.all fun (outcome, _, s) =>
    match outcome with
    | Active r => !r.dres_blocked && (memoryEffects s).length == 5 &&
        (memoryEffects s).all fun a => (memoryEffects s).all fun b =>
          if a.sc_effect_request.sc_request_id != b.sc_effect_request.sc_request_id then
            !effectBefore a b && !effectBefore b a else true
    | _ => false
  return [
    ("memcpy retains four internally ordered actual accesses", (memoryEffects copied.2).length == 4 &&
      internallyOrdered (memoryEffects copied.2) && match copied.1 with | NDactive _ => true | _ => false),
    ("runtime helper retains the same internal access order", (memoryEffects runtime.2).length == 4 &&
      internallyOrdered (memoryEffects runtime.2) && match runtime.1 with | NDactive _ => true | _ => false),
    ("copy failure keeps its eight completed ordered accesses", (memoryEffects failed.2).length == 8 &&
      internallyOrdered (memoryEffects failed.2) && match failed.1 with | NDkilled _ => true | _ => false),
    ("helper-specific rule does not order arbitrary access request internals",
      match memoryEffects accessKind.2 with | first :: second :: _ => !effectBefore first second | _ => false),
    ("unsequenced sibling request gains no edge from helper execution", separate),
    ("helper receipt retains every internal occurrence", match copied.2.sc_state0 with
      | some sc => match sc_receipt sc with
        | some (_, some receipt) => (memoryEffects copied.2).all fun e =>
            setMemberBy setElemCompare (Pos, (e.sc_effect_request.sc_request_thread, e.sc_effect_id)) receipt
        | _ => false
      | _ => false)] ++ varargsControls enabled ++ formattingControls enabled

def runTests (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let mut good := true
  for (label, pass) in controls fuel do
    IO.println s!"{label}: {pass}"
    good := good && pass
  return if good then 0 else 1

end SCUnit.SCHelperOrder
