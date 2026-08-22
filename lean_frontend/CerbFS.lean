/-
  Minimal filesystem model for Cerberus.
  Corresponds to: sibylfs/src/ via the Sibylfs OCaml wrapper.

  The OCaml backend uses SibylFS, a formal POSIX filesystem model.
  For the Lean port we provide a minimal in-memory implementation
  sufficient for the corpus's file-I/O smoke tests ONLY — NOT a faithful
  fs model (re-mark honesty; sem:S13 residual): lseek maintains offsets
  that read/write IGNORE (read from 0, write appends), pread/pwrite
  ignore their offset, open ignores flags (no O_TRUNC) — a
  seek-then-read program gets silently wrong data. The registered mover:
  per-fd offsets or loud enosys + a CerbPP-style divergence table.
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

-- Helper: lookup file contents
private def lookupFile (st : FsState) (path : String) : Option (List Char) :=
  st.files.lookup path

private def lookupFd (st : FsState) (fd : Nat) : Option FdEntry :=
  st.fds.lookup fd

-- FS operations return (new_state, Either error result)

def fs_open (st : FsState) (path : String) (_ : Int) (_ : Option Int) : FsState × (Sum FsError Nat) :=
  let fd := st.nextFd
  let entry : FdEntry := { path := path }
  let st' := { st with fds := (fd, entry) :: st.fds, nextFd := fd + 1 }
  -- Create file if it doesn't exist
  let st' := if (lookupFile st path).isNone
    then { st' with files := (path, []) :: st'.files }
    else st'
  (st', .inr fd)

def fs_close (st : FsState) (fd : Int) : FsState × (Sum FsError Nat) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)
  | some _ =>
    let st' := { st with fds := st.fds.filter (fun (n, _) => n != fdN) }
    (st', .inr 0)

def fs_write (st : FsState) (fd : Int) (data : List Char) (_ : Int) : FsState × (Sum FsError Nat) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)
  | some entry =>
    let newContents := match lookupFile st entry.path with
      | some existing => existing ++ data
      | none => data
    let files' := (entry.path, newContents) :: st.files.filter (fun (p, _) => p != entry.path)
    let st' := { st with files := files' }
    (st', .inr data.length)

def fs_read (st : FsState) (fd : Int) (count : Int) : FsState × (Sum FsError (List Char)) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)
  | some entry =>
    match lookupFile st entry.path with
    | none => (st, .inl .enoent)
    | some contents =>
      let data := contents.take count.toNat
      (st, .inr data)

def fs_mkdir (st : FsState) (_ : String) (_ : Int) : FsState × (Sum FsError Nat) :=
  (st, .inr 0)  -- No-op for directories in our minimal model

def fs_pwrite (st : FsState) (fd : Int) (data : List Char) (_ offset : Int) : FsState × (Sum FsError Nat) :=
  fs_write st fd data offset  -- Simplified: same as write

def fs_pread (st : FsState) (fd : Int) (count _ : Int) : FsState × (Sum FsError (List Char)) :=
  fs_read st fd count  -- Simplified: ignore offset

def fs_rename (st : FsState) (oldP newP : String) : FsState × (Sum FsError Nat) :=
  match lookupFile st oldP with
  | none => (st, .inl .enoent)
  | some contents =>
    let files' := (newP, contents) :: st.files.filter (fun (p, _) => p != oldP && p != newP)
    ({ st with files := files' }, .inr 0)

def fs_umask (st : FsState) (mask : Int) : FsState × (Sum FsError Nat) :=
  let old := st.umask
  ({ st with umask := mask }, .inr old.toNat)

def fs_chmod (st : FsState) (_ : String) (_ : Int) : FsState × (Sum FsError Nat) :=
  (st, .inr 0)

def fs_chdir (st : FsState) (dir : String) : FsState × (Sum FsError Nat) :=
  ({ st with cwd := dir }, .inr 0)

def fs_chown (st : FsState) (_ : String) (_ _ : Int) : FsState × (Sum FsError Nat) :=
  (st, .inr 0)

def fs_link (st : FsState) (_ _ : String) : FsState × (Sum FsError Nat) :=
  (st, .inl .enosys)

def fs_readlink (st : FsState) (_ : String) : FsState × (Sum FsError (List Char)) :=
  (st, .inl .enosys)

def fs_symlink (st : FsState) (_ _ : String) : FsState × (Sum FsError Nat) :=
  (st, .inl .enosys)

def fs_rmdir (st : FsState) (_ : String) : FsState × (Sum FsError Nat) :=
  (st, .inr 0)

def fs_truncate (st : FsState) (path : String) (len : Int) : FsState × (Sum FsError Nat) :=
  match lookupFile st path with
  | none => (st, .inl .enoent)
  | some contents =>
    let files' := (path, contents.take len.toNat) :: st.files.filter (fun (p, _) => p != path)
    ({ st with files := files' }, .inr 0)

def fs_unlink (st : FsState) (path : String) : FsState × (Sum FsError Nat) :=
  let files' := st.files.filter (fun (p, _) => p != path)
  ({ st with files := files' }, .inr 0)

/-- lseek(fd, offset, whence) — update the fd's offset.
    whence: 0 = SEEK_SET (absolute), 1 = SEEK_CUR (relative), 2 = SEEK_END. -/
def fs_lseek (st : FsState) (fd offset whence : Int) : FsState × (Sum FsError Nat) :=
  match st.fds.find? (fun (f, _) => f == fd.toNat) with
  | none => (st, .inl .ebadf)
  | some (_, entry) =>
    let newOffset : Int := match whence with
      | 0 => offset
      | 1 => (entry.offset : Int) + offset
      | 2 =>
        match st.files.find? (fun (p, _) => p == entry.path) with
        | some (_, contents) => (contents.length : Int) + offset
        | none => (entry.offset : Int) + offset
      | _ => entry.offset
    if newOffset < 0 then (st, .inl (.other "EINVAL"))
    else
      let entry' := { entry with offset := newOffset.toNat }
      let fds' := st.fds.map (fun (f, e) =>
        if f == fd.toNat then (f, entry') else (f, e))
      ({ st with fds := fds' }, .inr newOffset.toNat)

def fs_stat (st : FsState) (path : String) : FsState × (Sum FsError FsStat) :=
  match lookupFile st path with
  | none => (st, .inl .enoent)
  | some contents =>
    (st, .inr { size := contents.length })

def fs_lstat (st : FsState) (path : String) : FsState × (Sum FsError FsStat) :=
  fs_stat st path  -- No symlink distinction in our model

def fs_opendir (st : FsState) (_ : String) : FsState × (Sum FsError Nat) :=
  let fd := st.nextFd
  ({ st with nextFd := fd + 1 }, .inr fd)

def fs_readdir (st : FsState) (_ : Int) : FsState × (Sum FsError (List Char)) :=
  (st, .inr [])

def fs_rewinddir (st : FsState) (_ : Int) : FsState := st

def fs_closedir (st : FsState) (fd : Int) : FsState × (Sum FsError Nat) :=
  fs_close st fd

end CerbFS
