import LemLib
/-
  Filesystem model for Cerberus: REFUSED IN FULL (2026-09-28).
  Corresponds to: sibylfs/src/ via the Sibylfs OCaml wrapper (`sibylfs/generated/sibylfs.ml` `run_*`;
  every op is one SibylFS `OS_*` transition of the formal POSIX model, `fs_spec.lem`).

  [USER 2026-09-28], contract decision D2: "refuse FS for now, this seems safer". The earlier minimal
  in-memory model SERVED a subset of operations it believed matched SibylFS; an external report showed
  one such answer was wrong (raw-string path keys: `./secret.txt` and `secret.txt` were different files —
  `docs/2026-09-28_cerbfs-path-hotfix-record.md`). A served subset is only as good as the adversarial
  testing behind it, and the upstream corpora never exercised this surface, so every filesystem
  OPERATION now refuses: a class-(c) missing feature under the zero-discrepancy rule (VALIDATION §1:
  "missing features are allowed deviations if they are cleanly identified" [USER 2026-09-03]). Record:
  `docs/2026-09-28_cerbfs-refuse-all-record.md`; the served implementation is in git history (mainline
  a7dc36e2f and earlier).

  What still runs: the pure parts the driver references (the state type, `fs_initial_state`, the stat
  accessors, `fs_string_of_error`, `string_of_fs_state`). Standard output and error never reach this
  module: `driver.lem` `driver_fs_step` routes `write` on fds 1/2 to the stdout/stderr records and
  `write` on fd 0 to its own error.

  Refusal mechanism [deliberate]: `failwithI` (the house fail-stop leaf), not an FsError — an FsError
  becomes errno + -1 through driver.lem store_error and a C program can absorb it. Every message starts
  with `CerbFS refusal (fail-closed fs-model boundary):` and names the operation and its arguments.
  Witnesses: the immaculate lane's `zd-f1-truncate-negative-length`, `zd-z2f01-lseek-whence`,
  `zd-fs-*` rows (pinned refusals).
  This is a leaf module.
-/

namespace CerbFS

/-- File descriptor state -/
structure FdEntry where
  path : String
  offset : Nat := 0
  deriving Inhabited, BEq, Repr

/-- Filesystem stat information -/
structure FsStat where
  dev : Int := 0
  ino : Int := 0
  mode : Int := 0o644
  nlink : Int := 1
  uid : Int := 0
  gid : Int := 0
  rdev : Int := 0
  size : Int := 0
  atime : Int := 0
  mtime : Int := 0
  ctime : Int := 0
  deriving Inhabited, BEq

/-- Filesystem error -/
inductive FsError where
  | enoent : FsError    -- No such file or directory
  | eacces : FsError    -- Permission denied
  | eexist : FsError    -- File exists
  | ebadf  : FsError    -- Bad file descriptor
  | enosys : FsError    -- Not implemented
  | other : String → FsError
  deriving Inhabited, BEq

/-- `panic!` needs an inhabitant at the refusal sites below; the
    default is an enosys error (never observed: the driver refuses to run
    without LEAN_ABORT_ON_PANIC, so the panic aborts first). -/
instance (α : Type) : Inhabited (Sum FsError α) := ⟨Sum.inl .enosys⟩

/-- In-memory filesystem state -/
structure FsState where
  files : List (String × List Char) := []  -- path → contents
  fds : List (Nat × FdEntry) := []         -- fd → entry
  nextFd : Nat := 3                        -- 0,1,2 reserved for stdin/stdout/stderr
  cwd : String := "/"
  umask : Int := 0o022
  deriving Inhabited, BEq, Repr

instance : Ord FsState where
  compare _ _ := .eq

-- Stat field accessors
def fs_dev  (s : FsStat) : Int := s.dev
def fs_ino  (s : FsStat) : Int := s.ino
def fs_mode (s : FsStat) : Int := s.mode
def fs_nlink (s : FsStat) : Int := s.nlink
def fs_uid  (s : FsStat) : Int := s.uid
def fs_gid  (s : FsStat) : Int := s.gid
def fs_rdev (s : FsStat) : Int := s.rdev
def fs_size (s : FsStat) : Int := s.size
def fs_atime (s : FsStat) : Int := s.atime
def fs_mtime (s : FsStat) : Int := s.mtime
def fs_ctime (s : FsStat) : Int := s.ctime

def fs_string_of_error : FsError → String
  | .enoent => "ENOENT"
  | .eacces => "EACCES"
  | .eexist => "EEXIST"
  | .ebadf  => "EBADF"
  | .enosys => "ENOSYS"
  | .other s => s

def fs_initial_state : FsState := default

def string_of_fs_state (_ : FsState) : String := "<fs_state>"

/-- The one refusal message of this module: `op` and its arguments, attributed to this boundary. -/
private def fsRefusal (op : String) : String :=
  s!"CerbFS refusal (fail-closed fs-model boundary): {op} — the filesystem is not modelled by this port ([USER 2026-09-28] contract D2: refused in full); answering would differ from, or merely guess at, the oracle's SibylFS (CerbFS.lean header; mover: a SibylFS-faithful filesystem model)"

def fs_mkdir (_ : FsState) (path : String) (mode : Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"mkdir '{path}' mode {mode}")
def fs_open (_ : FsState) (path : String) (oflag : Int) (mode : Option Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"open '{path}' oflag {oflag} mode {repr mode}")
def fs_close (_ : FsState) (fd : Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"close fd {fd}")
def fs_write (_ : FsState) (fd : Int) (data : List Char) (count : Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"write fd {fd} count {count} ({data.length}-byte buffer)")
def fs_read (_ : FsState) (fd : Int) (count : Int) : FsState × (Sum FsError (List Char)) :=
  failwithI (fsRefusal s!"read fd {fd} count {count}")
def fs_pwrite (_ : FsState) (fd : Int) (data : List Char) (count offset : Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"pwrite fd {fd} count {count} offset {offset} ({data.length}-byte buffer)")
def fs_pread (_ : FsState) (fd : Int) (count off : Int) : FsState × (Sum FsError (List Char)) :=
  failwithI (fsRefusal s!"pread fd {fd} count {count} offset {off}")
def fs_rename (_ : FsState) (oldP newP : String) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"rename '{oldP}' -> '{newP}'")
def fs_umask (_ : FsState) (mask : Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"umask {mask}")
def fs_chmod (_ : FsState) (path : String) (mode : Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"chmod '{path}' mode {mode}")
def fs_chdir (_ : FsState) (dir : String) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"chdir '{dir}'")
def fs_chown (_ : FsState) (path : String) (uid gid : Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"chown '{path}' uid {uid} gid {gid}")
def fs_link (_ : FsState) (oldP newP : String) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"link '{oldP}' -> '{newP}'")
def fs_readlink (_ : FsState) (path : String) : FsState × (Sum FsError (List Char)) :=
  failwithI (fsRefusal s!"readlink '{path}'")
def fs_symlink (_ : FsState) (target lpath : String) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"symlink '{target}' <- '{lpath}'")
def fs_rmdir (_ : FsState) (path : String) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"rmdir '{path}'")
def fs_truncate (_ : FsState) (path : String) (len : Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"truncate '{path}' to {len}")
def fs_unlink (_ : FsState) (path : String) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"unlink '{path}'")
def fs_lseek (_ : FsState) (fd offset whence : Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"lseek fd {fd} offset {offset} whence {whence}")
def fs_stat (_ : FsState) (path : String) : FsState × (Sum FsError FsStat) :=
  failwithI (fsRefusal s!"stat '{path}'")
def fs_lstat (_ : FsState) (path : String) : FsState × (Sum FsError FsStat) :=
  failwithI (fsRefusal s!"lstat '{path}'")
def fs_opendir (_ : FsState) (path : String) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"opendir '{path}'")
def fs_readdir (_ : FsState) (dir : Int) : FsState × (Sum FsError (List Char)) :=
  failwithI (fsRefusal s!"readdir {dir}")
def fs_rewinddir (_ : FsState) (dir : Int) : FsState :=
  failwithI (fsRefusal s!"rewinddir {dir}")
def fs_closedir (_ : FsState) (dir : Int) : FsState × (Sum FsError Nat) :=
  failwithI (fsRefusal s!"closedir {dir}")

end CerbFS
