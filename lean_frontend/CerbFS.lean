/-
  Minimal filesystem model for Cerberus.
  Corresponds to: sibylfs/src/ via the Sibylfs OCaml wrapper
  (`sibylfs/generated/sibylfs.ml` `run_*` — every op is one SibylFS
  `OS_*` transition of the formal POSIX model, `fs_spec.lem`).

  The OCaml backend uses SibylFS, a formal POSIX filesystem model. The
  Lean port provides a minimal in-memory implementation that answers ONLY
  the operations it can answer exactly as SibylFS does; every other
  operation REFUSES loudly. This is a class-(c) MISSING FEATURE under the
  zero-discrepancy rule (docs/2026-09-03_zero-discrepancy-design.md §1.2,
  [USER 2026-09-03]: "missing features are allowed deviations if they are
  cleanly identified … CerbFS is kind of an obscure feature"): a loud,
  feature-attributed refusal where the oracle answers is allowed; a
  different answer, or a SILENT ABSORPTION (an errno, a default, a zero,
  a success-returning no-op) never is. Charter row Z-27 (the served-but-
  divergent residuals) is closed by the table below: since 2026-09-03
  the served set IS the correct-answer set. Mover (OPTIONAL, [USER
  2026-09-03] Q10): real fs semantics — real per-fd offsets incl. open
  flags/O_TRUNC, directories, stat, links — priced M.

  OP-BY-OP TABLE — all 25 `fs_*` operation entry points of
  frontend/model/fs.lem (+ the 11 stat accessors, fs_string_of_error,
  fs_initial_state, string_of_fs_state, which are pure). "SibylFS" is the
  POSIX model's answer (sibylfs.ml run_<op>); "served" means the Lean
  answer is byte-identical to it; "REFUSED" is a `panic!` naming this
  boundary (below). The driver turns an FsError into errno + −1
  (driver.lem store_error, :211-247) — which the C program can absorb —
  so a refusal is never an FsError.

  | op                                              | SibylFS (POSIX)                          | Lean          |
  |-------------------------------------------------|------------------------------------------|---------------|
  | fs_open  existing file, read-only (no O_WRONLY/  | fd, offset 0                             | SERVED        |
  |          O_RDWR/O_TRUNC/O_APPEND/O_EXCL)         |                                          |               |
  | fs_open  missing file with O_CREAT, no O_EXCL   | created empty, fd                        | SERVED        |
  | fs_open  missing file WITHOUT O_CREAT           | ENOENT (fopen → NULL)                    | REFUSED (was: created empty) |
  | fs_open  any O_EXCL                             | EEXIST if it exists, else create+mode    | REFUSED (was: ignored) |
  | fs_open  existing file with write/trunc/append   | truncation / positioning per flags       | REFUSED       |
  | fs_close fd ≥ 3 open / unknown                  | 0 / EBADF                                | SERVED        |
  | fs_read  offset 0 (prefix) / at EOF             | bytes / 0 bytes                          | SERVED        |
  | fs_read  any other offset                       | bytes from the offset                    | REFUSED       |
  | fs_read  fd 0,1,2                               | EBADF — the std fds are open on a dummy  | SERVED        |
  |                                                 | fid with NO O_RDONLY/O_RDWR flag         |               |
  |                                                 | (fs_spec.lem:4949-4956, :5806-5812)      |               |
  | fs_read  unknown fd                             | EBADF                                    | SERVED        |
  | fs_write fd ≥ 3 at offset == size (append)      | n, offset advances                       | SERVED        |
  | fs_write any other offset                       | overwrite/extend                         | REFUSED       |
  | fs_write unknown fd                             | EBADF                                    | SERVED        |
  | (fs_write on fd 0,1,2 never reaches Fs: driver.lem:352-359 routes 1/2 to the stdout/stderr records and 0 to `error`) |
  | fs_pread offset 0 / at EOF; fs_pwrite at size   | as read/write, fd offset untouched       | SERVED        |
  | fs_pread/fs_pwrite other offsets                |                                          | REFUSED       |
  | fs_pread/fs_pwrite fd 0,1,2                     | EBADF (no read/write flag on the dummy   | SERVED        |
  |                                                 | fid; fs_spec.lem:4949-4956/:5006-5012)   |               |
  | fs_lseek fd ≥ 3, SEEK_SET/CUR/END, result in    | new offset                               | SERVED        |
  |          [0, size]                              |                                          |               |
  | fs_lseek negative result                        | EINVAL                                   | SERVED        |
  | fs_lseek result past EOF / invalid whence       | offset past EOF (later read → 0 or the   | REFUSED (was: accepted / offset kept) |
  |                                                 | hole) / EINVAL                           |               |
  | fs_lseek, fs_close on fd 0,1,2                  | performed on the std fd (open in the     | REFUSED (was: EBADF) |
  |                                                 | initial state, fs_spec.lem:5690-5696)    |               |
  | fs_umask                                        | previous mask; new mask applies to modes | SERVED (the mode it would affect is only observable through stat/open, refused/served as above) |
  | fs_truncate no open fd on the path, len ≤ size  | shrink                                   | SERVED        |
  | fs_truncate open fd on the path, or len > size  | fd offsets keep; zero-extension          | REFUSED (was: List.take) |
  | fs_unlink  no open fd on the path               | removed                                  | SERVED        |
  | fs_unlink  open fd on the path                  | the file persists until the last close   | REFUSED (was: removed) |
  | fs_rename  no open fd on either path            | renamed                                  | SERVED        |
  | fs_rename  open fd on either path               | the fd follows the file                  | REFUSED (was: fd kept the old path) |
  | fs_mkdir, fs_rmdir, fs_chdir, fs_chmod, fs_chown | POSIX directory / permission semantics   | REFUSED (was: success-returning no-ops) |
  | fs_link, fs_readlink, fs_symlink                | POSIX link semantics                     | REFUSED (was: ENOSYS → errno + −1) |
  | fs_stat, fs_lstat                               | the real stat fields                     | REFUSED (was: zeroed fields except size — suite/fs/stat.c STDOUT_DIFF) |
  | fs_opendir, fs_readdir, fs_rewinddir, fs_closedir | directory streams                      | REFUSED (was: fresh fd / always-empty / no-op / close) |

  Refusal mechanism [deliberate]: `panic!`, not an FsError (an FsError
  becomes errno + −1 through driver.lem store_error and the C program can
  absorb it — still a wrong answer, just a different one). `panic!` is the
  house fail-stop sentinel (cf. CerbMem/CerbUtils); the driver REFUSES to
  start without LEAN_ABORT_ON_PANIC (Main.lean, Z2-FL-03), so a refusal
  is a loud LEAN-side failure attributed to this boundary. Every refusal
  message starts with `CerbFS refusal (fail-closed fs-model boundary):`
  and names the operation, the arguments and the mover. Witnesses:
  tests/suite/fs/stat.c (stat → refusal; was STDOUT_DIFF `0 0 420 1 0 0 0
  10` vs the oracle's `2049 1 33261 1 0 0 0 10`), tests/freebsd/cat.c
  (read on fd 0 → refusal; was LEAN_FAIL `assert() failure`),
  tests/tcc/40_stdio.c (mid-file read → refusal, unchanged).
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

/-- The refusal sentinel: one prefix, so every refusal is greppable and
    attributed to this boundary (header). `op` names the operation, `why`
    what SibylFS answers that this model cannot, `mover` the named work. -/
private def refusal (op why mover : String) : String :=
  s!"CerbFS refusal (fail-closed fs-model boundary): {op} — {why}; answering would differ from the oracle's SibylFS (CerbFS.lean header; mover: {mover})"

private def moverOffsets := "real per-fd offset semantics"
private def moverFlags := "real open-flag semantics"
private def moverDirs := "a directory/permission model"
private def moverLinks := "a link model"
private def moverStat := "real stat fields"
private def moverStdFds := "SibylFS's std fds (fs_spec.lem:5690-5696: fds 0,1,2 are open on a root-directory dummy fid)"

-- Helper: lookup file contents
private def lookupFile (st : FsState) (path : String) : Option (List Char) :=
  st.files.lookup path

private def lookupFd (st : FsState) (fd : Nat) : Option FdEntry :=
  st.fds.lookup fd

/-- Any open fd on `path`? (unlink/rename/truncate interact with open fds
    in POSIX — the file persists, the fd follows, offsets keep — none of
    which the table models.) -/
private def anyFdOn (st : FsState) (path : String) : Bool :=
  st.fds.any (fun (_, e) => e.path == path)

/-- fds 0,1,2 are SibylFS's std fds, OPEN in its initial state on a dummy
    fid (fs_spec.lem:5690-5696, :5806-5812): read/pread/pwrite on them are
    EBADF there too (no access flag on the dummy fid) and stay served;
    lseek/close are PERFORMED on the dummy fd there, where this model,
    having no entry, answered EBADF — a different answer, refused. -/
private def isStdFd (fd : Int) : Bool := fd == 0 || fd == 1 || fd == 2

-- FS operations return (new_state, Either error result)

def fs_open (st : FsState) (path : String) (oflag : Int) (_ : Option Int) : FsState × (Sum FsError Nat) :=
  let mkFd (st : FsState) : FsState × (Sum FsError Nat) :=
    let fd := st.nextFd
    let entry : FdEntry := { path := path }
    ({ st with fds := (fd, entry) :: st.fds, nextFd := fd + 1 }, .inr fd)
  -- Flag encoding is SibylFS fs_spec.lem's (mirrored by
  -- runtime/libc/include/posix/fcntl.h:27-45): O_WRONLY=0o4, O_RDWR=0o10,
  -- O_CREAT=0o40, O_EXCL=0o100, O_TRUNC=0o400, O_APPEND=0o1000.
  let flags := oflag.toNat
  if flags &&& 0o100 != 0 then
    panic! (refusal s!"open of '{path}' with O_EXCL (oflag {oflag})"
      "SibylFS answers EEXIST for an existing file and creates with the given mode otherwise; this model ignored the flag" moverFlags)
  else
  match lookupFile st path with
  | none =>
    if flags &&& 0o40 == 0 then
      panic! (refusal s!"open of the MISSING file '{path}' without O_CREAT (oflag {oflag})"
        "SibylFS answers ENOENT (fopen returns NULL); this model used to create the file empty and serve EOF reads" moverFlags)
    else
      -- O_CREAT on a missing file: created empty, offset 0 — as SibylFS
      mkFd { st with files := (path, []) :: st.files }
  | some contents =>
    -- Fail-closed (audit F1): the model ignores open flags' content
    -- effects (O_TRUNC truncation, write positioning/modes), so reopening
    -- an EXISTING file with write, truncate or append intent leaves
    -- content state the model cannot track — the truncate-on-reopen shape
    -- served STALE data later with no refused op on the path. Read-only
    -- reopen is content-correct and stays served.
    if flags &&& 0o4 != 0 || flags &&& 0o10 != 0 || flags &&& 0o400 != 0 || flags &&& 0o1000 != 0 then
      panic! (refusal s!"open of the existing {contents.length}-byte file '{path}' with write/truncate/append intent (oflag {oflag})"
        "the minimal fs model cannot track the resulting content state (O_TRUNC/write modes ignored); serving this fd would answer with WRONG data" moverFlags)
    else
      mkFd st

def fs_close (st : FsState) (fd : Int) : FsState × (Sum FsError Nat) :=
  if isStdFd fd then
    panic! (refusal s!"close of fd {fd}" "fds 0,1,2 are open in SibylFS's initial state; this model has no entry for them and answered EBADF" moverStdFds)
  else
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)   -- EBADF, as SibylFS
  | some _ =>
    let st' := { st with fds := st.fds.filter (fun (n, _) => n != fdN) }
    (st', .inr 0)

-- Helper: replace one fd's entry (identity if the fd is absent)
private def setFd (st : FsState) (fdN : Nat) (entry' : FdEntry) : FsState :=
  { st with fds := st.fds.map (fun (f, e) => if f == fdN then (f, entry') else (f, e)) }

def fs_write (st : FsState) (fd : Int) (data : List Char) (_ : Int) : FsState × (Sum FsError Nat) :=
  -- fds 0,1,2 never reach here: driver.lem:352-359 routes them itself
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)   -- EBADF, as SibylFS
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
      panic! (refusal s!"write on fd {fd} at offset {entry.offset} of the {contents.length}-byte file '{entry.path}'"
        "the minimal fs model can only append at end-of-file; answering would write WRONG data" moverOffsets)

def fs_read (st : FsState) (fd : Int) (count : Int) : FsState × (Sum FsError (List Char)) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none =>
    -- EBADF, as SibylFS — for an unknown fd (fs_spec.lem:4946-4947) AND for
    -- the std fds 0,1,2, whose dummy fid carries no O_RDONLY/O_RDWR flag
    -- (:4949-4956 `can_read`; :5806-5812 `fids_oflags = {}`): this model
    -- has no entry for them, so the same EBADF falls out here
    (st, .inl .ebadf)
  | some entry =>
    match lookupFile st entry.path with
    | none =>
      -- unreachable: unlink/rename refuse while an fd is open (table)
      panic! (refusal s!"read on fd {fd} whose file '{entry.path}' is gone" "the model's file table lost the fd's file" moverOffsets)
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
        panic! (refusal s!"read on fd {fd} at offset {entry.offset} of the {contents.length}-byte file '{entry.path}'"
          "the minimal fs model can only serve whole-prefix (offset 0) or at-EOF reads; answering would return WRONG data" moverOffsets)

def fs_mkdir (st : FsState) (path : String) (mode : Int) : FsState × (Sum FsError Nat) :=
  panic! (refusal s!"mkdir '{path}' (mode {mode})" "SibylFS creates a directory (EEXIST/ENOENT/EACCES per POSIX); this model has no directories and answered a success-returning no-op" moverDirs)

def fs_pwrite (st : FsState) (fd : Int) (data : List Char) (_ offset : Int) : FsState × (Sum FsError Nat) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)   -- EBADF, as SibylFS (unknown fd, or a std fd: no write flag on the dummy fid, fs_spec.lem:5006-5012)
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
      panic! (refusal s!"pwrite on fd {fd} at requested offset {offset} of the {contents.length}-byte file '{entry.path}'"
        "the minimal fs model can only append at end-of-file; answering would write WRONG data" moverOffsets)

def fs_pread (st : FsState) (fd : Int) (count off : Int) : FsState × (Sum FsError (List Char)) :=
  let fdN := fd.toNat
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)   -- EBADF, as SibylFS (unknown fd, or a std fd: no read flag on the dummy fid, fs_spec.lem:4949-4956)
  | some entry =>
    match lookupFile st entry.path with
    | none =>
      panic! (refusal s!"pread on fd {fd} whose file '{entry.path}' is gone" "the model's file table lost the fd's file" moverOffsets)
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
        panic! (refusal s!"pread on fd {fd} at requested offset {off} of the {contents.length}-byte file '{entry.path}'"
          "the minimal fs model can only serve whole-prefix (offset 0) or at-EOF reads; answering would return WRONG data" moverOffsets)

def fs_rename (st : FsState) (oldP newP : String) : FsState × (Sum FsError Nat) :=
  if anyFdOn st oldP || anyFdOn st newP then
    panic! (refusal s!"rename '{oldP}' → '{newP}' while an fd is open on one of them"
      "in POSIX the open fd follows the file; this model's fd entry kept the OLD path (later reads would answer ENOENT)" moverOffsets)
  else
  match lookupFile st oldP with
  | none => (st, .inl .enoent)  -- ENOENT, as SibylFS
  | some contents =>
    let files' := (newP, contents) :: st.files.filter (fun (p, _) => p != oldP && p != newP)
    ({ st with files := files' }, .inr 0)

def fs_umask (st : FsState) (mask : Int) : FsState × (Sum FsError Nat) :=
  -- served: the previous mask is returned exactly; the mode it would
  -- affect is observable only through stat/open (refused/served above)
  let old := st.umask
  ({ st with umask := mask }, .inr old.toNat)

def fs_chmod (st : FsState) (path : String) (mode : Int) : FsState × (Sum FsError Nat) :=
  panic! (refusal s!"chmod '{path}' (mode {mode})" "SibylFS changes the mode (ENOENT/EPERM per POSIX; later stat sees it); this model has no permission state and answered a success-returning no-op" moverDirs)

def fs_chdir (st : FsState) (dir : String) : FsState × (Sum FsError Nat) :=
  panic! (refusal s!"chdir '{dir}'" "SibylFS resolves later relative paths against the new directory (ENOENT/ENOTDIR per POSIX); this model recorded the string and kept resolving paths verbatim" moverDirs)

def fs_chown (st : FsState) (path : String) (uid gid : Int) : FsState × (Sum FsError Nat) :=
  panic! (refusal s!"chown '{path}' ({uid}:{gid})" "SibylFS changes the owner (ENOENT/EPERM per POSIX; later stat sees it); this model has no ownership state and answered a success-returning no-op" moverDirs)

def fs_link (st : FsState) (oldP newP : String) : FsState × (Sum FsError Nat) :=
  panic! (refusal s!"link '{oldP}' → '{newP}'" "SibylFS creates a hard link (EEXIST/ENOENT per POSIX); this model answered ENOSYS, which the driver turns into errno + −1 for the C program to absorb" moverLinks)

def fs_readlink (st : FsState) (path : String) : FsState × (Sum FsError (List Char)) :=
  panic! (refusal s!"readlink '{path}'" "SibylFS reads the link target (EINVAL/ENOENT per POSIX); this model answered ENOSYS (errno + −1)" moverLinks)

def fs_symlink (st : FsState) (target lpath : String) : FsState × (Sum FsError Nat) :=
  panic! (refusal s!"symlink '{target}' ← '{lpath}'" "SibylFS creates a symbolic link (EEXIST/ENOENT per POSIX); this model answered ENOSYS (errno + −1)" moverLinks)

def fs_rmdir (st : FsState) (path : String) : FsState × (Sum FsError Nat) :=
  panic! (refusal s!"rmdir '{path}'" "SibylFS removes a directory (ENOENT/ENOTEMPTY/ENOTDIR per POSIX); this model has no directories and answered a success-returning no-op" moverDirs)

def fs_truncate (st : FsState) (path : String) (len : Int) : FsState × (Sum FsError Nat) :=
  match lookupFile st path with
  | none => (st, .inl .enoent)  -- ENOENT, as SibylFS
  | some contents =>
    if anyFdOn st path then
      panic! (refusal s!"truncate '{path}' to {len} while an fd is open on it"
        "in POSIX the open fds' offsets keep (a later read/write sees the truncated file); this model's append-only fd invariant would break silently" moverOffsets)
    else if len > (contents.length : Int) then
      panic! (refusal s!"truncate '{path}' ({contents.length} bytes) to the LARGER length {len}"
        "POSIX zero-extends the file; this model's List.take left the content unchanged" moverOffsets)
    else
      let files' := (path, contents.take len.toNat) :: st.files.filter (fun (p, _) => p != path)
      ({ st with files := files' }, .inr 0)

def fs_unlink (st : FsState) (path : String) : FsState × (Sum FsError Nat) :=
  if anyFdOn st path then
    panic! (refusal s!"unlink '{path}' while an fd is open on it"
      "in POSIX the file persists until the last close (the open fd keeps reading it); this model removed it (later reads would answer ENOENT)" moverOffsets)
  else
  match lookupFile st path with
  | none => (st, .inl .enoent)  -- ENOENT, as SibylFS (the old model answered 0)
  | some _ =>
    let files' := st.files.filter (fun (p, _) => p != path)
    ({ st with files := files' }, .inr 0)

/-- lseek(fd, offset, whence) — update the fd's offset.
    whence: 0 = SEEK_SET (absolute), 1 = SEEK_CUR (relative), 2 = SEEK_END. -/
def fs_lseek (st : FsState) (fd offset whence : Int) : FsState × (Sum FsError Nat) :=
  if isStdFd fd then
    panic! (refusal s!"lseek on fd {fd}" "fds 0,1,2 are SibylFS's std fds; this model has no entry for them and answered EBADF" moverStdFds)
  else
  match st.fds.find? (fun (f, _) => f == fd.toNat) with
  | none => (st, .inl .ebadf)   -- EBADF, as SibylFS
  | some (_, entry) =>
    match lookupFile st entry.path with
    | none =>
      panic! (refusal s!"lseek on fd {fd} whose file '{entry.path}' is gone" "the model's file table lost the fd's file" moverOffsets)
    | some contents =>
      let size : Int := contents.length
      let newOffset : Option Int := match whence with
        | 0 => some offset
        | 1 => some ((entry.offset : Int) + offset)
        | 2 => some (size + offset)
        | _ => none
      match newOffset with
      | none =>
        panic! (refusal s!"lseek on fd {fd} with whence {whence}" "SibylFS answers EINVAL for an invalid whence; this model silently kept the offset" moverOffsets)
      | some newOffset =>
        if newOffset < 0 then (st, .inl (.other "EINVAL"))   -- EINVAL, as SibylFS
        else if newOffset > size then
          panic! (refusal s!"lseek on fd {fd} to offset {newOffset} past the end of the {size}-byte file '{entry.path}'"
            "POSIX allows it (a later read answers 0 bytes, a later write creates a hole); this model would then refuse or serve EOF inconsistently" moverOffsets)
        else
          let entry' := { entry with offset := newOffset.toNat }
          let fds' := st.fds.map (fun (f, e) =>
            if f == fd.toNat then (f, entry') else (f, e))
          ({ st with fds := fds' }, .inr newOffset.toNat)

def fs_stat (st : FsState) (path : String) : FsState × (Sum FsError FsStat) :=
  panic! (refusal s!"stat '{path}'" "SibylFS answers the real st_dev/st_ino/st_mode/st_nlink/uid/gid/rdev/size fields (tests/suite/fs/stat.c: 2049 1 33261 1 0 0 0 10); this model answered zeroed fields except size (0 0 420 1 0 0 0 10)" moverStat)

def fs_lstat (st : FsState) (path : String) : FsState × (Sum FsError FsStat) :=
  panic! (refusal s!"lstat '{path}'" "SibylFS answers the real stat fields (no symlink following); this model answered zeroed fields except size" moverStat)

def fs_opendir (st : FsState) (path : String) : FsState × (Sum FsError Nat) :=
  panic! (refusal s!"opendir '{path}'" "SibylFS opens a directory stream (ENOENT/ENOTDIR per POSIX); this model has no directories and answered a fresh fd for any path" moverDirs)

def fs_readdir (st : FsState) (dir : Int) : FsState × (Sum FsError (List Char)) :=
  panic! (refusal s!"readdir on {dir}" "SibylFS answers the next entry name; this model answered an always-empty stream" moverDirs)

def fs_rewinddir (st : FsState) (dir : Int) : FsState :=
  panic! (refusal s!"rewinddir on {dir}" "SibylFS rewinds a directory stream; this model has no directories and answered a no-op" moverDirs)

def fs_closedir (st : FsState) (dir : Int) : FsState × (Sum FsError Nat) :=
  panic! (refusal s!"closedir on {dir}" "SibylFS closes a directory stream; this model has no directories" moverDirs)

end CerbFS
