import Unit.SCProtocolSupport
import CerbFSProofs
import CerbFSDriverProofs

open SCProtocolControls CerbSCOperational

private def thread : thread_state := {
  arena := pureExpr (intval 17), stack0 := Stack_empty
  errno := pointer 40 400, env := [], current_proc_opt := none
  current_loc := CerbLocation.other "filesystem control", exec_loc := ELoc_globals }

private def fsSetup : IO CerbFS.FsState := do
  let .returned st (.inr fd) := CerbFS.fs_open_checked CerbFS.fs_initial_state "/file" 40 (some 420)
    | throw (IO.userError "open setup failed")
  let .returned st (.inr _) := CerbFS.fs_write_checked st (Int.ofNat fd) ['A','B'] 2
    | throw (IO.userError "write setup failed")
  let .returned st (.inr _) := CerbFS.fs_lseek_checked st (Int.ofNat fd) 0 0
    | throw (IO.userError "seek setup failed")
  return st

private def completion (_ : driver_state) (th : thread_state) :=
  {th with arena := pureExpr (intval 99)}
private def operation [LemFuel] (state : driver_state) (op : fs_oper) :=
  drive_fs_step_with state.core_file.tagDefs completion 0 thread state op
private def byte (s : driver_state) (address : Int) :=
  (s.layout_state.bytemap.get? address).bind (·.value)
private def fsKilled (node : nd_action Unit step_kind driver_error
    (mem_constraint CerbMem.IntegerValue) driver_state) : Bool :=
  match node with | NDkilled (Other (DErr_filesystem _)) => true | _ => false
private def memoryKilled (node : nd_action Unit step_kind driver_error
    (mem_constraint CerbMem.IntegerValue) driver_state) : Bool :=
  match node with | NDkilled (Undef0 _ _) => true | _ => false

private def controls [LemFuel] : IO (List (String × Bool)) := do
  let filesystem ← fsSetup
  let file := program (pureExpr Vunit)
  let initial := memorySetup (initial_driver_state 2 0x10000 file filesystem).1
  let base := {initial with dr_step_counter := 7, core_state0 := {initial.core_state0 with
    thread_states := [(0,(none,thread))], io := {initial.core_state0.io with
      stdout := singleton "prefix"}}}
  let enabled := (node (sc_enable : driverM Unit) base).2
  let ready := sc_request_state 0 (SC_runtime "filesystem control") empty_annotation enabled
  let prior := node (driver_liftMem (CerbMem.storeM file.tagDefs
    (CerbLocation.other "prior store") unsigned_char false (pointer 20 200)
    (CerbMem.integerValueMval (Unsigned Ichar) (CerbMem.integerIval 9)))) ready
  let state := prior.2
  let umask := node (operation state (FS_UMASK 63)) state
  let special := node (operation state (FS_OPEN "/file" 64 none)) state
  let short := node (operation state (FS_WRITE 3 ['x'] 2)) state
  let missing := node (operation state (FS_MKDIR "dir" 511)) state
  let faultStates := [umask.2,special.2,short.2,missing.2]
  let buffer := node (operation state (FS_READ 3 (pointer 30 300) 2)) state
  let errno := node (operation state (FS_CLOSE 77)) state
  let good := node (operation state (FS_LSEEK 3 1 0)) state
  let output := node (operation state (FS_WRITE 1 ['o','k'] 2)) state
  let alternatives : driverM Unit := ND fun st =>
    (NDnd (SK_misc ["filesystem alternatives"]) [(SK_done,operation st (FS_UMASK 63)),
      (SK_done,operation st (FS_READ 3 (pointer 30 300) 2)),
      (SK_done,operation st (FS_LSEEK 3 1 0)),
      (SK_done,operation st (FS_UMASK 63))],st)
  let all := CerbND.runND alternatives state
  let kinds := all.map fun (status,_,_) => match status with
    | Active _ => "active"
    | Killed _ (Other (DErr_filesystem _)) => "filesystem"
    | Killed _ (Undef0 _ _) => "memory"
    | Killed _ _ => "other"
  let statusText := fun action => match action with
    | NDactive () => "active"
    | NDkilled (Undef0 _ _) => "UB"
    | NDkilled (Error0 _ msg) => "error " ++ msg
    | NDkilled (Other (DErr_filesystem fault)) => "filesystem " ++ fault.text
    | NDkilled (Other (DErr_memory _)) => "memory"
    | NDkilled _ => "killed other"
    | _ => "nonterminal"
  IO.println s!"read status={statusText buffer.1} byte={repr (byte buffer.2 300)} effects={(memoryEffects buffer.2).length}"
  IO.println s!"errno status={statusText errno.1}"
  IO.println s!"stdout status={statusText output.1} chunks={repr (toList output.2.core_state0.io.stdout)}"
  IO.println s!"alternatives={repr kinds}"
  return [
    ("prior memory store is recorded", byte state 200 == some 9 && (memoryEffects state).length == 1),
    ("umask fails with completed leaf state", fsKilled umask.1 &&
      match umask.2.fs_boundary_failure with
      | some (receipt,.upstreamDecode "return_nat" "(RV_file_perm(File_perm 18))") => receipt.umask == 63
      | _ => false),
    ("open special remains distinct", match special.1 with
      | NDkilled (Other (DErr_filesystem (.upstreamSpecial .tau .undefined _))) => true | _ => false),
    ("short-buffer leaf remains distinct", match short.1 with
      | NDkilled (Other (DErr_filesystem (.upstreamLeaf .tau _))) => true | _ => false),
    ("missing port remains distinct", match missing.1 with
      | NDkilled (Other (DErr_filesystem (.missingCoverage _))) => true | _ => false),
    ("faults retain committed filesystem", faultStates.all fun s => s.fs_state0 == state.fs_state0),
    ("faults retain prior memory and effects", faultStates.all fun s =>
      byte s 200 == some 9 && memoryEffects s == memoryEffects state),
    ("faults retain output prefix", faultStates.all fun s => toList s.core_state0.io.stdout == ["prefix"]),
    ("faults do not complete Core or increment counter", faultStates.all fun s =>
      s.core_state0.thread_states == state.core_state0.thread_states && s.dr_step_counter == 7),
    ("read buffer fault retains completed first store", memoryKilled buffer.1 && byte buffer.2 300 == some 65 &&
      (memoryEffects buffer.2).length == 2),
    ("read buffer fault retains old filesystem commit", buffer.2.fs_state0 == state.fs_state0 &&
      buffer.2.fs_boundary_failure == none && buffer.2.dr_step_counter == 7),
    ("errno store fault is not a filesystem boundary", memoryKilled errno.1 && errno.2.fs_boundary_failure == none &&
      errno.2.fs_state0 == state.fs_state0 && errno.2.dr_step_counter == 7),
    ("successful seek commits and invokes completion", match good.1 with
      | NDactive () => good.2.dr_step_counter == 8 &&
        (good.2.fs_state0.fds.lookup 3).map (·.offset) == some 1 &&
        (good.2.core_state0.thread_states.lookup 0).map (·.2.arena) == some (pureExpr (intval 99))
      | _ => false),
    ("numeric stdout routing stays in Driver", match output.1 with
      | NDactive () => toList output.2.core_state0.io.stdout == ["prefix","ok"] &&
        output.2.fs_state0 == state.fs_state0 && output.2.fs_boundary_failure == none
      | _ => false),
    ("exhaustive runner preserves faults success duplicates and order", kinds == ["filesystem","active","memory","filesystem"]),
    ("exhaustion stays an explicit outcome", match CerbND.runNDFuel 0 alternatives state with
      | [(Killed _ reason,_,_)] => reason == CerbND.fuelExhaustedKill | _ => false)]

def main (args : List String) : IO UInt32 := do
  let [argument] := args | return 2
  let some fuel := argument.toNat? | return 2
  let rows ← @controls ⟨fuel⟩
  for (label,passed) in rows do
    IO.println (label ++ ": " ++ toString passed)
  return if rows.all (·.2) then 0 else 1
