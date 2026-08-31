/-
  Minimal filesystem model for Cerberus.
  Corresponds to: sibylfs/src/ via the Sibylfs OCaml wrapper.

  The OCaml backend uses SibylFS, a formal POSIX filesystem model.
  For the Lean port we provide a minimal in-memory implementation
  sufficient for the corpus's file-I/O smoke tests ONLY — NOT a faithful
  fs model. DELIBERATE DIVERGENCE from the OCaml side (SibylFS models
  offsets correctly); this is the sem:S13 residual, half-closed by the
  trust-basket fail-closed pass (2026-08-31; the mover to full parity
  remains real per-fd offset semantics incl. open flags/O_TRUNC —
  priced M, parity-detective report §3 RC-1).

  FAIL-CLOSED REGIME (trust-basket item b + audit-F1 response): the
  model tracks per-fd offsets honestly (reads/writes advance them,
  lseek always did) and open is flag-aware enough to refuse content
  states it cannot track. Precisely:

  SERVED (content-correct):
    - open of a path with no existing file (created empty, offset 0);
    - read-only reopen of an existing file (no write/trunc flag bits);
    - read  at offset 0 (whole-prefix read), or at EOF (empty result);
    - write at offset == file length (pure append; a fresh file starts
      at 0 == 0, so sequential writes on a newly opened file work);
    - pread at offset 0 or EOF; pwrite at offset == file length.

  REFUSED (loud panic, named reason):
    - open of an EXISTING file with write or truncate intent
      (O_WRONLY/O_RDWR/O_TRUNC — the audit-F1 truncate-on-reopen shape
      previously served STALE data with no refused op on the path);
      this includes O_APPEND reopen (refused, not served);
    - every other read/write/pread/pwrite offset combination — the
      cases the old model answered with SILENTLY WRONG DATA
      (fgetc-until-EOF looping forever, seek-then-read returning the
      byte at 0: parity-detective RC-1).

  KNOWN-DIVERGENT AND STILL SERVED (named residuals, part of the same
  registered mover — this list is the honesty bound; the served set
  above is correct only OUTSIDE these):
    - open of a MISSING file without O_CREAT succeeds and creates an
      empty file (POSIX: ENOENT — a missing-file read-open observes
      fopen != NULL and empty-EOF reads);
    - O_EXCL is ignored (no EEXIST);
    - stat/lstat return zeroed fields except size (suite/fs/stat.c
      STDOUT_DIFF).

  Refusal mechanism [deliberate]: `panic!`, not an FsError. An FsError
  is converted by the driver into errno + a -1 return
  (frontend/model/driver.lem store_error/store_buffer, ~:211-247) which
  the C program can absorb (e.g. fgetc mapping the error to EOF) —
  still a wrong answer, just a different one. `panic!` is the house
  fail-stop sentinel (cf. CerbMem/CerbUtils; harnesses run with
  LEAN_ABORT_ON_PANIC=1 via scripts/common.sh run_cerberus_lean), so a
  refusal is a loud LEAN-side failure attributed to this boundary.
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
    default is an enosys error (never observed: under
    LEAN_ABORT_ON_PANIC=1 the panic aborts first). -/
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

-- Helper: lookup file contents
private def lookupFile (st : FsState) (path : String) : Option (List Char) :=
  st.files.lookup path

private def lookupFd (st : FsState) (fd : Nat) : Option FdEntry :=
  st.fds.lookup fd

-- FS operations return (new_state, Either error result)

def fs_open (st : FsState) (path : String) (oflag : Int) (_ : Option Int) : FsState × (Sum FsError Nat) :=
  let mkFd (st : FsState) : FsState × (Sum FsError Nat) :=
    let fd := st.nextFd
    let entry : FdEntry := { path := path }
    ({ st with fds := (fd, entry) :: st.fds, nextFd := fd + 1 }, .inr fd)
  match lookupFile st path with
  | none =>
    -- Created empty regardless of O_CREAT — a named KNOWN-DIVERGENT
    -- residual (header): POSIX gives ENOENT without O_CREAT.
    mkFd { st with files := (path, []) :: st.files }
  | some contents =>
    -- Fail-closed (audit F1): the model ignores open flags' content
    -- effects (O_TRUNC truncation, write positioning/modes), so
    -- reopening an EXISTING file with write or truncate intent leaves
    -- content state the model cannot track — the truncate-on-reopen
    -- shape served STALE data later with no refused op on the path.
    -- Flag encoding is SibylFS fs_spec.lem's (mirrored by
    -- runtime/libc/include/posix/fcntl.h:27-45): O_WRONLY=0o4,
    -- O_RDWR=0o10, O_TRUNC=0o400. Read-only reopen is content-correct
    -- and stays served. Deliberate divergence from the OCaml side
    -- (SibylFS models open flags faithfully); mover: real open-flag
    -- semantics — the same M-priced item as the header's.
    let flags := oflag.toNat
    if flags &&& 0o4 != 0 || flags &&& 0o10 != 0 || flags &&& 0o400 != 0 then
      panic! s!"CerbFS refusal (fail-closed fs-model boundary): open of existing {contents.length}-byte file '{path}' with write/truncate intent (oflag {oflag}) — the minimal fs model cannot track the resulting content state (O_TRUNC/write modes ignored); serving this fd would answer with WRONG data (CerbFS.lean header; mover: real open-flag semantics)"
    else
      mkFd st

def fs_close (st : FsState) (fd : Int) : FsState × (Sum FsError Nat) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)
  | some _ =>
    let st' := { st with fds := st.fds.filter (fun (n, _) => n != fdN) }
    (st', .inr 0)

-- Helper: replace one fd's entry (identity if the fd is absent)
private def setFd (st : FsState) (fdN : Nat) (entry' : FdEntry) : FsState :=
  { st with fds := st.fds.map (fun (f, e) => if f == fdN then (f, entry') else (f, e)) }

def fs_write (st : FsState) (fd : Int) (data : List Char) (_ : Int) : FsState × (Sum FsError Nat) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)
  | some entry =>
    let contents := (lookupFile st entry.path).getD []
    -- Fail-closed (header): the model can only APPEND. That is correct
    -- exactly when the fd's offset sits at the current end of file
    -- (fresh file: 0 == 0; sequential writes maintain the invariant).
    -- Anywhere else (seek-then-write, reopened non-empty file where
    -- POSIX open flags would decide truncate/append) the old model
    -- silently appended wrong data — refuse instead.
    if entry.offset == contents.length then
      let newContents := contents ++ data
      let files' := (entry.path, newContents) :: st.files.filter (fun (p, _) => p != entry.path)
      let st' := setFd { st with files := files' } fdN { entry with offset := newContents.length }
      (st', .inr data.length)
    else
      panic! s!"CerbFS refusal (fail-closed fs-model boundary): write on fd {fd} at offset {entry.offset} of {contents.length}-byte file '{entry.path}' — the minimal fs model can only append at end-of-file; answering would write WRONG data (CerbFS.lean header; mover: real per-fd offset semantics)"

def fs_read (st : FsState) (fd : Int) (count : Int) : FsState × (Sum FsError (List Char)) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)
  | some entry =>
    match lookupFile st entry.path with
    | none => (st, .inl .enoent)
    | some contents =>
      -- Fail-closed (header): serve only the two patterns the model
      -- answers correctly — a read at offset 0 (prefix of the file,
      -- advancing the offset so a later mid-file read cannot lie) and
      -- a read at EOF (zero bytes). Everything else is the RC-1
      -- wrong-answer channel (fgetc-until-EOF, seek-then-read) — refuse.
      if entry.offset == contents.length then
        (st, .inr [])  -- at EOF: correct empty read, no state change
      else if entry.offset == 0 then
        let data := contents.take count.toNat
        (setFd st fdN { entry with offset := data.length }, .inr data)
      else
        panic! s!"CerbFS refusal (fail-closed fs-model boundary): read on fd {fd} at offset {entry.offset} of {contents.length}-byte file '{entry.path}' — the minimal fs model can only serve whole-prefix (offset 0) or at-EOF reads; answering would return WRONG data (CerbFS.lean header; mover: real per-fd offset semantics)"

def fs_mkdir (st : FsState) (_ : String) (_ : Int) : FsState × (Sum FsError Nat) :=
  (st, .inr 0)  -- No-op for directories in our minimal model

def fs_pwrite (st : FsState) (fd : Int) (data : List Char) (_ offset : Int) : FsState × (Sum FsError Nat) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)
  | some entry =>
    let contents := (lookupFile st entry.path).getD []
    -- Fail-closed (header): pwrite is correct here only as an append at
    -- the exact end of file; POSIX pwrite does NOT move the fd offset,
    -- so the entry is left untouched. Any other offset — refuse (the
    -- old model appended regardless of the requested offset).
    if offset == (contents.length : Int) then
      let newContents := contents ++ data
      let files' := (entry.path, newContents) :: st.files.filter (fun (p, _) => p != entry.path)
      ({ st with files := files' }, .inr data.length)
    else
      panic! s!"CerbFS refusal (fail-closed fs-model boundary): pwrite on fd {fd} at requested offset {offset} of {contents.length}-byte file '{entry.path}' — the minimal fs model can only append at end-of-file; answering would write WRONG data (CerbFS.lean header; mover: real per-fd offset semantics)"

def fs_pread (st : FsState) (fd : Int) (count off : Int) : FsState × (Sum FsError (List Char)) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)
  | some entry =>
    match lookupFile st entry.path with
    | none => (st, .inl .enoent)
    | some contents =>
      -- Fail-closed (header): pread at offset 0 (prefix) or at EOF
      -- (empty) are the two patterns the model answers correctly; POSIX
      -- pread never moves the fd offset, so no state change. Any other
      -- offset — refuse (the old model read from 0 regardless).
      if off == (contents.length : Int) then
        (st, .inr [])
      else if off == 0 then
        (st, .inr (contents.take count.toNat))
      else
        panic! s!"CerbFS refusal (fail-closed fs-model boundary): pread on fd {fd} at requested offset {off} of {contents.length}-byte file '{entry.path}' — the minimal fs model can only serve whole-prefix (offset 0) or at-EOF reads; answering would return WRONG data (CerbFS.lean header; mover: real per-fd offset semantics)"

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
