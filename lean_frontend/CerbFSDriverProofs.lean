import CerbSCOperational

set_option autoImplicit true

namespace CerbFSDriver
open CerbSCOperational

/-- Normal results preserve the existing callback, including its own failures,
state changes, alternatives and resource use. No filesystem commit is moved. -/
theorem returned_exact {α : Type} (st : CerbFS.FsState)
    (result : Sum CerbFS.FsError α)
    (complete : (CerbFS.FsState × Sum CerbFS.FsError α) → driverM Unit) :
    driver_fs_result (st,.inr result) complete = complete (st,result) := rfl

/-- A terminal leaf retains the entire Driver state except the diagnostic receipt.
The ordinary fs_state, Core arena, counter, outputs and memory journal remain. -/
theorem stopped_exact {α : Type} (st : CerbFS.FsState) (fault : CerbFS.FsFault)
    (complete : (CerbFS.FsState × Sum CerbFS.FsError α) → driverM Unit)
    (current : driver_state) :
    node (driver_fs_result (st,.inl fault) complete) current =
      (NDkilled (Other (DErr_filesystem fault)),
       {current with fs_boundary_failure := some (st,fault)}) := rfl

theorem boundary_not_ub (fault : CerbFS.FsFault) loc ubs :
    (Other (DErr_filesystem fault) : kill_reason driver_error) ≠ Undef0 loc ubs := by
  intro h
  cases h

theorem fault_injective (left right : CerbFS.FsFault) :
    (Other (DErr_filesystem left) : kill_reason driver_error) =
      Other (DErr_filesystem right) ↔ left = right := by
  constructor
  · intro h; cases h; rfl
  · intro h; cases h; rfl

-- The actual filesystem entry performs the receipt transition and kills;
-- it never calls the Core completion callback, even with a nontrivial callback.
theorem umask_entry_exact [LemFuel] tags complete tid thread (current : driver_state) mask :
    node (drive_fs_step_with tags complete tid thread current (FS_UMASK mask)) current =
      (NDkilled (Other (DErr_filesystem
        (.upstreamDecode "return_nat" s!"(RV_file_perm(File_perm {current.fs_state0.umask}))"))),
       {current with fs_boundary_failure := some (
          {current.fs_state0 with umask := CerbFS.Checks.word32 mask},
          .upstreamDecode "return_nat" s!"(RV_file_perm(File_perm {current.fs_state0.umask}))")}) := by
  cases thread.arena
  rfl

end CerbFSDriver


-- SC-D11: generated comparisons must hit the named opaque boundary.
theorem CerbFSDriver.state_ordering_refuses (left right : CerbFS.FsState) : compare left right =
    CerbFS.compareState left right := rfl
