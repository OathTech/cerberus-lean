import CerbFS
namespace CerbFS

theorem open_stopped_state (st next : FsState) (path : String) (flags : Int)
    (mode : Option Int) (fault : FsFault)
    (h : fs_open_checked st path flags mode = .stopped next fault) : next = st := by
  cases hp : prepareOpen st path flags mode with
  | error f => simp only [fs_open_checked, hp, FsResult.stopped.injEq] at h; exact h.1.symm
  | ok value => cases value <;> simp [fs_open_checked, hp] at h

theorem open_error_state (st next : FsState) (path : String) (flags : Int)
    (mode : Option Int) (error : FsError)
    (h : fs_open_checked st path flags mode = .returned next (.inl error)) : next = st := by
  cases hp : prepareOpen st path flags mode with
  | error f => simp [fs_open_checked, hp] at h
  | ok value =>
    cases value with
    | inl e => simp only [fs_open_checked, hp, FsResult.returned.injEq] at h; exact h.1.symm
    | inr plan => simp [fs_open_checked, hp] at h

theorem open_compatibility_return (st next : FsState) (path : String) (flags : Int)
    (mode : Option Int) (result : Sum FsError Nat)
    (h : fs_open_checked st path flags mode = .returned next result) :
    fs_open st path flags mode = (next,result) := by
  simp only [fs_open, h]

-- These are laws of the production transition, not a simulation proof of SibylFS.

theorem umask_retains_completed_update (st : FsState) (mask : Int) :
    fs_umask_checked st mask = .stopped
      {st with umask := CerbFS.Checks.word32 mask}
      (.upstreamDecode "return_nat" s!"(RV_file_perm(File_perm {st.umask}))") := rfl

theorem umask_cannot_complete (st next : FsState) (mask : Int) (result : Sum FsError Nat) :
    fs_umask_checked st mask ≠ .returned next result := by
  intro h
  cases h


theorem result_unpack_pack {α : Type} (result : FsResult α) :
    FsResult.unpack result.pack = result := by cases result <;> rfl
theorem result_pack_unpack {α : Type} (pair : FsState × Sum FsFault (Sum FsError α)) :
    (FsResult.unpack pair).pack = pair := by
  rcases pair with ⟨st,result⟩
  cases result <;> rfl
end CerbFS

