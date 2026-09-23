import LemLib
/-
Derived from SibylFS fs_spec.lem and fs_prelude.lem.
Copyright (c) 2013, 2014, 2015, Tom Ridge, David Sheets, Thomas Tuerk,
Andrea Giugliano (as part of the SibylFS project).
Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.
THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
-/
/- Path and open checks for the represented root/regular-file filesystem.
No symlinks/directories are invented. The resolver's domain assumes a root cwd,
canonical direct-root regular-file keys and the pinned initial root user.
The caller supplies existing-file execute permission. This is not a complete
filesystem transition, and its list alone does not prove wrapper correspondence.
Model specials remain distinct from errno; no special becomes C UB or success. -/
namespace CerbFS.Checks
inductive Resolution where
  | directory
  | file (canonical : String)
  | missing (canonical : String)
  | error (name : String)
  deriving BEq, Repr
inductive SpecialKind where
  | impossible | implementationDefined | unspecified | undefined | fixme
  deriving BEq, Ord, Inhabited, Repr

def SpecialKind.text : SpecialKind → String
  | .impossible => "Impossible"
  | .implementationDefined => "Implementation_defined"
  | .unspecified => "Unspecified"
  | .undefined => "Undefined"
  | .fixme => "FIXME"

inductive Outcome where
  | normal
  | error (name : String)
  | special (kind : SpecialKind) (name : String)
  deriving BEq, Repr

def Outcome.text : Outcome → String
  | .normal => "normal"
  | .error name => "error " ++ name
  | .special kind name => "model special " ++ kind.text ++ ": " ++ name

def Resolution.text : Resolution → String
  | .directory => "directory"
  | .file _ => "file"
  | .missing _ => "missing"
  | .error name => "error " ++ name

-- Preserve the optional RN_error.re_rn file when only trailing slashes caused
-- ENOTDIR. Rename's subdirectory check uses this field; file/.. has no such
-- residual. Both projections come from this one traversal.
def resolveComponentsWithExtra (files : List String) : List String → Resolution × Option String
  | [] => (.directory,none)
  | component :: rest =>
    if component == "" || component == "." || component == ".." then
      resolveComponentsWithExtra files rest
    else
      let canonical := "/" ++ component
      if files.contains canonical then
        if rest.isEmpty then (.file canonical,none) else
        (.error "ENOTDIR",if rest.all (· == "") then some canonical else none)
      else
        if rest.all (· == "") then (.missing canonical,none) else (.error "ENOENT",none)

def resolveComponents (files : List String) (components : List String) : Resolution :=
  (resolveComponentsWithExtra files components).1

def resolveWithExtra (files : List String) (path : String) : Resolution × Option String :=
  if path == "" then (.error "ENOENT",none) else resolveComponentsWithExtra files (path.splitOn "/")

def resolve (files : List String) (path : String) : Resolution :=
  (resolveWithExtra files path).1

-- fs_prelude.lem:19–29 preserves first representatives, not sorted errors.
def deduplicate (values : List Outcome) : List Outcome :=
  (values.foldl (fun seen value => if seen.contains value then seen else value :: seen) []).reverse

-- fs_spec.lem:2627 parallel composition, including the ordered finset representation.
def combine (left right : List Outcome) : List Outcome :=
  let failures := deduplicate
    ((left.filter (· != .normal)).reverse ++ right.filter (· != .normal))
  if left.contains .normal && right.contains .normal then .normal :: failures else failures

def condition (test : Bool) (failure : Outcome) : List Outcome :=
  [if test then failure else .normal]

def combineAll (checks : List (List Outcome)) : List Outcome :=
  checks.foldl combine [.normal]

-- Every supplied bit is a positive power of two. Euclidean division also
-- decodes negative flag words without truncating them to zero.
def hasFlag (flags bit : Int) : Bool := (flags / bit) % 2 != 0

-- Sibylfs.run_open converts flags/modes to the logical int32 word type.
-- Lem's prover-side conversion is modular. Zarith overflow in the OCaml
-- wrapper is an execution artifact (LemLib's existing D4 ruling), not a new
-- Lean limit. Preserve the word conversion without imposing that host bound.
def word32 (value : Int) : Int := lemInt32ToInt (lemInt32OfInt value)

def openChecks (resolved : Resolution) (trailingSlash : Bool) (flags : Int)
    (mode : Option Int) (fileExecutable : Bool) : List Outcome :=
  let flags := word32 flags
  let mode := mode.map word32
  let exec := hasFlag flags 1
  let read := hasFlag flags 2 || flags % 32 == 0
  let write := hasFlag flags 4
  let readWrite := hasFlag flags 8
  let search := hasFlag flags 16
  let create := hasFlag flags 32
  let excl := hasFlag flags 64
  let trunc := hasFlag flags 256
  let directory := hasFlag flags 16384
  let isDir := match resolved with | .directory => true | _ => false
  let isFile := match resolved with | .file _ => true | _ => false
  let isMissing := match resolved with | .missing _ => true | _ => false
  let isError := match resolved with | .error _ => true | _ => false
  -- Every source check remains in the list, including architecture-disabled
  -- checks: composition order changes the selected representative.
  let paths := (combineAll [
    [match resolved with | .error name => .error name | _ => .normal],
    condition (isMissing && !create) (.error "ENOENT"),
    condition (isDir && (write || readWrite)) (.error "EISDIR"),
    condition (isDir && trunc) (.special .implementationDefined "open: O_TRUNC, directory, posix/open.md O_TRUNC:3"),
    condition (isDir && exec) (.special .unspecified "open: O_EXEC on directory"),
    condition (isFile && directory) (.error "ENOTDIR"),
    condition (isFile && search) (.special .unspecified "open: O_SEARCH on non-directory"),
    condition false (.error "ELOOP"), -- no symlinks in this represented domain
    condition false (.error "EMLINK"), -- FreeBSD
    condition (excl && create && (isDir || isFile)) (.error "EEXIST"),
    condition (create && trailingSlash) (.error "ENOTDIR"),
    condition false (.error "ENOTDIR"), -- FreeBSD O_DIRECTORY creation
    condition false (.error "EISDIR"), -- Linux creation on directory
    condition (create && trailingSlash && (isMissing || isError)) (.error "ENOENT"),
    condition false (.special .fixme "open with create-flag but without mode argument")
      -- Sibylfs.run_open supplies 0777 when the outer mode argument is absent.
  ]).reverse -- fsm_get_state bind
  let modes := [exec, read, write, readWrite, search].count true
  let flagChecks := combineAll [
    condition (excl && !create) (.special .undefined "open: O_EXCL, no O_CREAT, posix/open.md D:1"),
    condition (trunc && !(write || readWrite)) (.special .undefined "open: O_TRUNC, no O_RDWR or O_WRONLY, posix/open.md O_TRUNC:4"),
    condition (modes != 1) (.special .undefined "open: not exactly one file access mode"),
    condition false (.error "EINVAL") -- macOS
  ]
  let permissionChecks := (combine
    (condition (isFile && exec && !fileExecutable) (.error "EACCES"))
    (if isMissing && create then
      combine
        (condition (mode.getD 511 < 0 || mode.getD 511 > 4095)
          (.special .undefined "open: extra permissions bit for newly created file"))
        (condition false (.error "EACCES")) -- initial root user may write root
     else [.normal])).reverse -- fsm_get_state bind
  combine (combine paths flagChecks) permissionChecks

end CerbFS.Checks

namespace CerbFS.Checks

def isDir : Resolution → Bool | .directory => true | _ => false
def isFile : Resolution → Bool | .file _ => true | _ => false
def isMissing : Resolution → Bool | .missing _ => true | _ => false
def isError : Resolution → Bool | .error _ => true | _ => false
def resolutionCheck : Resolution → Outcome | .error e => .error e | _ => .normal

def truncateChecks (resolved : Resolution) (length : Int) : List Outcome :=
  combine (combine (condition (length < 0) (.error "EINVAL"))
    [match resolved with
      | .error e => .error e | .missing _ => .error "ENOENT"
      | .directory => .error "EISDIR" | .file _ => .normal]) [.normal]

def unlinkChecks (resolved : Resolution) : List Outcome :=
  combine ([match resolved with
    | .error e => .error e | .missing _ => .error "ENOENT"
    | .directory => .error "EPERM" | .file _ => .normal]).reverse [.normal]

-- Domain: root cwd, root user, direct-root regular files, ARCH_POSIX.
-- Includes disabled architecture checks because ordered combination matters.
def renameChecks (source target : Resolution) (targetSlash rootNonempty targetErrorFile : Bool) : List Outcome :=
  if isDir source && isDir target then [.normal] else
  let pathChecks := (combineAll [
    condition (isMissing source) (.error "ENOENT"),
    [resolutionCheck source], [resolutionCheck target],
    condition (isFile source && isDir target) (.error "EISDIR"),
    condition (isFile source && isMissing target && targetSlash) (.error "ENOTDIR"),
    condition false (.error "ENOENT"), -- macOS/FreeBSD
    condition false (.error "ENOTDIR"), -- Linux trailing slash
    condition (isDir source && (isFile target || isError target)) (.error "ENOTDIR"),
    condition false (.error "ENOTDIR"), -- Linux symlink source
    condition false (.error "ENOTDIR"), -- Linux symlink target
    if isDir target && rootNonempty then [.error "ENOTEMPTY",.error "EEXIST"] else [.normal]
  ]).reverse
  let rootChecks := [.normal] -- POSIX disables both architecture-specific errors
  -- RN_error.re_rn is supplied by the same resolver; ENOTDIR by itself does
  -- not establish that an otherwise valid file has only trailing slashes.
  let properSubdir := match target with
    | .file _ | .missing _ => true | .error _ => targetErrorFile | _ => false
  let subdirChecks := condition (isDir source && properSubdir) (.error "EINVAL")
  let parentChecks := (combine
    (condition (isDir source) (.error "EINVAL"))
    (if isDir target && isDir source then [.error "ENOTEMPTY",.error "EEXIST"] else [.normal])).reverse
  let permissionChecks := [.normal] -- initial root permission policy
  (combine (combine (combine (combine pathChecks rootChecks) subdirChecks) parentChecks) permissionChecks).reverse

end CerbFS.Checks

/-
Filesystem port of the pinned SibylFS wrapper (sibylfs/src/sibylfs.lem).
The checked interface retains ordinary errno, model specials, upstream decoder
and leaf failures, missing coverage, and protocol faults as distinct data.
Driver consumes the checked interface; legacy tuple projections are retained
for compatibility and abort on faults, without a returned failure state.

The represented domain starts with root cwd/root user and the three aliases of
the initial root-directory description. It includes independent open descriptions,
regular-file contents/modes, the wrapper's selected transfers, offsets, append,
truncation, path checks and closed-file unlink/rename. Directory creation, links,
permissions/ownership changes, stat and directory streams still require a port;
so does inode retention across unlink/rename of open files. They fail explicitly.
These are implementation obligations, not restrictions for reasoning.

An upstream special has no successor state: its receipt retains the last defined
state and phase. The umask decoder fails after OS_RETURN and the mask update.
Neither fault is ordinary errno or an ISO C concurrency UB.
See docs/2026-09-22_sc-boundary-register.md (SC-D07/D09/D10) and
docs/2026-09-23_sc-filesystem-repair-work.md for evidence and remaining limits.
Finite differential controls are not a general SibylFS simulation theorem.
-/

namespace CerbFS

/-- File descriptor state -/
structure FdEntry where
  path : String
  offset : Nat := 0
  canRead : Bool := false
  canWrite : Bool := false
  dummyRoot : Bool := false
  isDirectory : Bool := false
  appendMode : Bool := false
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

/-- Inhabitant for opaque legacy failure leaves; no semantic default return. -/
instance (α : Type) : Inhabited (Sum FsError α) := ⟨Sum.inl .enosys⟩

-- fs_spec.lem default_pps_fd_table/os_init_state: three aliases of FID0.
private def initialFdEntries : List (Nat × FdEntry) :=
  [0,1,2].map fun fd => (fd, {path := "/", dummyRoot := true, isDirectory := true})

/-- In-memory filesystem state -/
structure FsState where
  files : List (String × List Char) := []  -- canonical path → contents
  fileModes : List (String × Int) := []
  fds : List (Nat × FdEntry) := initialFdEntries -- current fd → entry
  cwd : String := "/"
  umask : Int := 0o022
  deriving Inhabited, BEq, Repr

-- Generated Driver record comparisons require this instance. The inherited
-- always-equal body silently identified distinct states (SC-D11). Refuse this
-- unported comparison; do not fabricate an order on the reduced representation.
-- Field inspection and structural representation equality remain available.
def compareState (_ _ : FsState) : Ordering :=
  failwithI "CerbFS missing coverage: filesystem state ordering has no reviewed SibylFS correspondence"

instance : Ord FsState where
  compare := compareState

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

private def moverDirs := "a directory/permission model"
private def moverLinks := "a link model"
private def moverStat := "real stat fields"

-- Helper: lookup file contents
private def lookupFile (st : FsState) (path : String) : Option (List Char) :=
  st.files.lookup path

private def lookupFd (st : FsState) (fd : Nat) : Option FdEntry :=
  st.fds.lookup fd

/-- Open descriptions requiring inode retention across unlink/rename. -/
private def anyFdOn (st : FsState) (path : String) : Bool :=
  st.fds.any (fun (_, e) => e.path == path)

/-- SibylFS's fd argument conversion: `fd_of_int n = FD (abs n)`
    (sibylfs/generated/sibylfs.ml:169-170) — a negative fd denotes |fd|.
    Mirrored everywhere an fd is looked up (audit-response: `.toNat` mapped
    every negative fd to 0). -/
private def fdOf (fd : Int) : Nat := fd.natAbs

/-- `abs (Nat_big_num.to_int size)` — SibylFS's count conversion
    (sibylfs.ml run_read/run_pread/run_write/run_pwrite). -/
private def countOf (n : Int) : Nat := n.natAbs

-- Sorted scan of current descriptor IDs, including duplicates defensively.
-- This is the smallest free FD, unlike SibylFS's max+1 FID supply.
private def smallestFreeFd (st : FsState) : Nat :=
  ((st.fds.map Prod.fst).mergeSort (fun a b => a ≤ b)).foldl
    (fun candidate fd => if candidate == fd then candidate + 1 else candidate) 0

-- Checked operations expose state and a typed result.

instance : Inhabited CerbFS.Checks.Resolution := ⟨.error "uninitialized path"⟩

private def fileError (name : String) : FsError :=
  match name with
  | "ENOENT" => .enoent | "EACCES" => .eacces | "EEXIST" => .eexist
  | "EBADF" => .ebadf | "ENOSYS" => .enosys | name => .other name

-- The source permits only these twelve mode bits; this is a logical mode
-- rule, not an OCaml integer-width bound. Unsupported extra bits are checked
-- by openChecks before creation. Mask only permissions actually present.
private def createdMode (mode mask : Int) : Int :=
  (List.range 12).foldl (fun result index =>
    let bit : Int := (2 : Nat)^index
    if CerbFS.Checks.hasFlag mode bit && !CerbFS.Checks.hasFlag mask bit then
      result+bit else result) 0

inductive FsPhase where
  | call | tau | return_
  deriving BEq, Ord, Inhabited, Repr

def FsPhase.text : FsPhase → String
  | .call => "call" | .tau => "tau" | .return_ => "return"

inductive FsFault where
  | upstreamSpecial (phase : FsPhase) (kind : CerbFS.Checks.SpecialKind) (reason : String)
  | upstreamDecode (decoder : String) (returnedValue : String)
  | upstreamLeaf (phase : FsPhase) (reason : String)
  | missingCoverage (reason : String)
  | protocol (reason : String)
  deriving BEq, Ord, Inhabited, Repr

inductive FsResult (α : Type) where
  | returned (state : FsState) (result : Sum FsError α)
  | stopped (state : FsState) (fault : FsFault)

def FsResult.pack {α : Type} : FsResult α → FsState × Sum FsFault (Sum FsError α)
  | .returned st result => (st,.inr result)
  | .stopped st fault => (st,.inl fault)

def FsResult.unpack {α : Type} : FsState × Sum FsFault (Sum FsError α) → FsResult α
  | (st,.inr result) => .returned st result
  | (st,.inl fault) => .stopped st fault

def FsFault.text : FsFault → String
  | .upstreamSpecial _ kind reason =>
      "CerbFS upstream model special (" ++ kind.text ++ "): " ++ reason
  | .upstreamDecode decoder value =>
      "CerbFS upstream return conversion failure: " ++ decoder ++ " received " ++ value
  | .upstreamLeaf _ reason => "CerbFS upstream leaf failure: " ++ reason
  | .missingCoverage reason => "CerbFS missing coverage: " ++ reason
  | .protocol reason => "CerbFS protocol failure: " ++ reason

structure OpenPlan where
  canonical : String
  isDirectory : Bool
  create : Bool

-- The sole preflight for both checked execution and the compatibility leaf.
-- No mutation occurs in open checks (fsop_open = checks >>= core).
def prepareOpen (st : FsState) (path : String) (oflag : Int) (mode : Option Int) :
    Except FsFault (Sum FsError OpenPlan) := do
  if st.cwd != "/" then
    throw (.missingCoverage s!"open '{path}' with non-root cwd '{st.cwd}': directory transitions are not ported")
  let resolved := CerbFS.Checks.resolve (st.files.map Prod.fst) path
  let executable ← match resolved with
    | .file canonical =>
      if !CerbFS.Checks.hasFlag oflag 1 then pure false else
      match st.fileModes.lookup canonical with
      | none => throw (.protocol s!"open '{path}' for execution: file has no recorded permission mode")
      | some mode => pure ([1,8,64].any (CerbFS.Checks.hasFlag mode))
    | _ => pure false
  let checks := CerbFS.Checks.openChecks resolved (path.endsWith "/") oflag mode executable
  match checks.getLast? with
  | none => throw (.protocol "open checks returned no outcome")
  | some (.error name) => pure (.inl (fileError name))
  | some (.special kind reason) => throw (.upstreamSpecial .tau kind reason)
  | some .normal =>
    match resolved with
    | .directory => pure (.inr ⟨"/",true,false⟩)
    | .file key => pure (.inr ⟨key,false,false⟩)
    | .missing key => pure (.inr ⟨key,false,true⟩)
    | .error _ => throw (.protocol "successful open has an unresolved path")

def commitOpen (st : FsState) (oflag : Int) (mode : Option Int) (plan : OpenPlan) : FsState × Nat :=
    let canonical := plan.canonical
    let isDirectory := plan.isDirectory
    let st := if plan.create then
      {st with
        files := (canonical,[]) :: st.files
        fileModes := (canonical,createdMode (mode.getD 511) st.umask) :: st.fileModes}
      else st
    let st := if !isDirectory && CerbFS.Checks.hasFlag oflag 256 then
      {st with files := st.files.map fun (key,data) =>
        (key,if key == canonical then [] else data)} else st
    let entry : FdEntry := {
      path := canonical
      canRead := CerbFS.Checks.hasFlag oflag 2 || CerbFS.Checks.hasFlag oflag 8 || oflag % 32 == 0
      canWrite := CerbFS.Checks.hasFlag oflag 4 || CerbFS.Checks.hasFlag oflag 8
      isDirectory := isDirectory
      appendMode := CerbFS.Checks.hasFlag oflag 512 }
    let fd := smallestFreeFd st
    ({st with fds := (fd,entry) :: st.fds}, fd)

def fs_open_checked (st : FsState) (path : String) (oflag : Int) (mode : Option Int) : FsResult Nat :=
  match prepareOpen st path oflag mode with
  | .error fault => .stopped st fault
  | .ok (.inl error) => .returned st (.inl error)
  | .ok (.inr plan) =>
    let (next,fd) := commitOpen st oflag mode plan
    .returned next (.inr fd)

-- Legacy compatibility only; Driver consumes the checked result. An opaque abort cannot retain the enclosing ND state.
def fs_open (st : FsState) (path : String) (oflag : Int) (mode : Option Int) : FsState × (Sum FsError Nat) :=
  match fs_open_checked st path oflag mode with
  | .returned next result => (next,result)
  | .stopped _ fault => failwithI fault.text

def fs_close (st : FsState) (fd : Int) : FsState × (Sum FsError Nat) :=
  let fdN := fdOf fd
  match lookupFd st fdN with
  | none => (st, .inl .ebadf)   -- EBADF, as SibylFS
  | some _ =>
    let st' := { st with fds := st.fds.filter (fun (n, _) => n != fdN) }
    (st', .inr 0)

-- Helper: replace one fd's entry (identity if the fd is absent)
private def setFd (st : FsState) (fdN : Nat) (entry' : FdEntry) : FsState :=
  match lookupFd st fdN with
  | none => st
  | some old =>
    { st with fds := st.fds.map fun (f,e) =>
      if old.dummyRoot && e.dummyRoot then (f, {e with offset := entry'.offset})
      else if f == fdN then (f,entry') else (f,e) }

-- Same selected read/write lengths as Sibylfs.run_last/run. The underlying
-- fsop has short-transfer alternatives; the existing wrapper chooses the full
-- available transfer. Preserve that wrapper selection.
private def readAt (st : FsState) (fd count : Int) (explicitOffset : Option Int) : FsResult (List Char) :=
  match lookupFd st (fdOf fd) with
  | none => .returned st (.inl .ebadf)
  | some entry =>
    if !entry.canRead then .returned st (.inl .ebadf) else
    let offset := explicitOffset.getD (Int.ofNat entry.offset)
    if offset < 0 then .returned st (.inl (.other "EINVAL")) else
    if entry.isDirectory then .returned st (.inl (.other "EISDIR")) else
    match lookupFile st entry.path with
    | none => .stopped st (.protocol s!"read on fd {fd}: resolved file '{entry.path}' has no contents")
    | some contents =>
      let data := (contents.drop offset.toNat).take (countOf count)
      let after := if explicitOffset.isSome then st else
        setFd st (fdOf fd) {entry with offset := entry.offset + data.length}
      .returned after (.inr data)

private def writeAt (st : FsState) (fd : Int) (data : List Char) (count : Int)
    (explicitOffset : Option Int) : FsResult Nat :=
  match lookupFd st (fdOf fd) with
  | none => .returned st (.inl .ebadf)
  | some entry =>
    if !entry.canWrite then .returned st (.inl .ebadf) else
    -- os_write rejects negative pwrite offsets even with O_APPEND. All valid
    -- regular-file negative offsets precede list_array_write's buffer check.
    if (explicitOffset.getD 0) < 0 then .returned st (.inl (.other "EINVAL")) else
    if entry.isDirectory then .returned st (.inl (.other "EISDIR")) else
    match lookupFile st entry.path with
    | none => .stopped st (.protocol s!"write on fd {fd}: resolved file '{entry.path}' has no contents")
    | some contents =>
      let count := countOf count
      let offset := if entry.appendMode then contents.length else
        (explicitOffset.getD (Int.ofNat entry.offset)).toNat
      if count > data.length then
        .stopped st (.upstreamLeaf .tau "t.ml/write: offset + length greater than length of string")
      else
        -- fsop_pwrite_core does not extend the contents for a zero write;
        -- os_write still updates an ordinary write's offset (including append).
        let after := if count == 0 then st else
          let bytes := contents.take offset ++ List.replicate (offset - contents.length) '\x00' ++
            data.take count ++ contents.drop (offset + count)
          {st with files := (entry.path,bytes) :: st.files.filter (fun (p,_) => p != entry.path)}
        let after := if explicitOffset.isSome then after else
          setFd after (fdOf fd) {entry with offset := offset + count}
        .returned after (.inr count)

def fs_read_checked (st : FsState) (fd count : Int) : FsResult (List Char) := readAt st fd count none
def fs_pread_checked (st : FsState) (fd count offset : Int) : FsResult (List Char) := readAt st fd count (some offset)
def fs_write_checked (st : FsState) (fd : Int) (data : List Char) (count : Int) : FsResult Nat := writeAt st fd data count none
def fs_pwrite_checked (st : FsState) (fd : Int) (data : List Char) (count offset : Int) : FsResult Nat := writeAt st fd data count (some offset)

private def FsResult.legacy {α : Type} (result : FsResult α) : FsState × Sum FsError α :=
  match result with
  | .returned next value => (next,value)
  | .stopped _ fault => failwithI fault.text

def fs_read (st : FsState) (fd count : Int) : FsState × Sum FsError (List Char) := (fs_read_checked st fd count).legacy
def fs_pread (st : FsState) (fd count offset : Int) : FsState × Sum FsError (List Char) := (fs_pread_checked st fd count offset).legacy
def fs_write (st : FsState) (fd : Int) (data : List Char) (count : Int) : FsState × Sum FsError Nat := (fs_write_checked st fd data count).legacy
def fs_pwrite (st : FsState) (fd : Int) (data : List Char) (count offset : Int) : FsState × Sum FsError Nat := (fs_pwrite_checked st fd data count offset).legacy

-- Close has no unsupported path and remains the one existing definition.
def fs_close_checked (st : FsState) (fd : Int) : FsResult Nat :=
  let (next,result) := fs_close st fd
  .returned next result

def fs_lseek_checked (st : FsState) (fd offset whence : Int) : FsResult Nat :=
  if whence != 0 && whence != 1 && whence != 2 then .returned st (.inl (.other "EINVAL")) else
  match lookupFd st (fdOf fd) with
  | none => .returned st (.inl .ebadf)
  | some entry =>
    if entry.isDirectory && whence == 2 then .returned st (.inl (.other "EOVERFLOW")) else
    let base : Except FsFault Int :=
      if whence == 0 then .ok 0 else
      if whence == 1 then .ok (Int.ofNat entry.offset) else
      match lookupFile st entry.path with
      | none => .error (.protocol s!"lseek on fd {fd}: resolved file '{entry.path}' has no contents")
      | some contents => .ok (Int.ofNat contents.length)
    match base with
    | .error fault => .stopped st fault
    | .ok base =>
      let next := base + offset
      if next < 0 then .returned st (.inl (.other "EINVAL")) else
      .returned (setFd st (fdOf fd) {entry with offset := next.toNat}) (.inr next.toNat)

def fs_lseek (st : FsState) (fd offset whence : Int) : FsState × Sum FsError Nat :=
  (fs_lseek_checked st fd offset whence).legacy


def fs_mkdir_checked (st : FsState) (path : String) (mode : Int) : FsResult Nat :=
  .stopped st (.missingCoverage (refusal s!"mkdir '{path}' (mode {mode})" "SibylFS creates a directory (EEXIST/ENOENT/EACCES per POSIX); this model has no directories and answered a success-returning no-op" moverDirs))

def fs_mkdir (st : FsState) (path : String) (mode : Int) : FsState × (Sum FsError Nat) :=
  (fs_mkdir_checked st path mode).legacy



-- Path operations. The query and operation use one resolver.
-- Upstream rename has an extra state bind, so its selected check is first;
-- truncate/unlink select last. See fsop_rename/fsop_truncate/fsop_unlink and
-- the retained native ordered-list/wrapper controls. Root cwd/root user remain
-- the reachable represented domain; directories/links need their actual port.

private def selectPathCheck (st : FsState) (operation : String)
    (selected : Option CerbFS.Checks.Outcome) (success : Unit → FsResult Nat) : FsResult Nat :=
  match selected with
  | none => .stopped st (.protocol (operation ++ " checks returned no outcome"))
  | some (.error name) => .returned st (.inl (fileError name))
  | some (.special kind reason) => .stopped st (.upstreamSpecial .tau kind reason)
  | some .normal => success ()

private def checkedPath (st : FsState) (operation path : String)
    (next : CerbFS.Checks.Resolution → Option String → FsResult Nat) : FsResult Nat :=
  if st.cwd != "/" then
    .stopped st (.missingCoverage s!"{operation} '{path}' with non-root cwd '{st.cwd}': directory transitions are not ported")
  else
    let (resolved,extra) := CerbFS.Checks.resolveWithExtra (st.files.map Prod.fst) path
    next resolved extra

def fs_truncate_checked (st : FsState) (path : String) (length : Int) : FsResult Nat :=
  checkedPath st "truncate" path fun resolved _ =>
  selectPathCheck st "truncate" (CerbFS.Checks.truncateChecks resolved length).getLast? fun _ =>
  match resolved with
  | .file key =>
    match lookupFile st key with
    | none => .stopped st (.protocol "truncate resolved file has no contents")
    | some contents =>
      let size := length.toNat
      let resized := contents.take size ++ List.replicate (size - contents.length) '\x00'
      .returned {st with files := (key,resized) :: st.files.filter (fun (p,_) => p != key)} (.inr 0)
  | _ => .stopped st (.protocol "successful truncate did not resolve a file")

def fs_unlink_checked (st : FsState) (path : String) : FsResult Nat :=
  checkedPath st "unlink" path fun resolved _ =>
  selectPathCheck st "unlink" (CerbFS.Checks.unlinkChecks resolved).getLast? fun _ =>
  match resolved with
  | .file key =>
    if anyFdOn st key then
      .stopped st (.missingCoverage s!"unlink '{path}' with an open descriptor: inode retention after unlink is not ported")
    else .returned {st with
      files := st.files.filter (fun (p,_) => p != key)
      fileModes := st.fileModes.filter (fun (p,_) => p != key)} (.inr 0)
  | _ => .stopped st (.protocol "successful unlink did not resolve a file")

def fs_rename_checked (st : FsState) (source target : String) : FsResult Nat :=
  checkedPath st "rename source" source fun sourceResolved _ =>
  checkedPath st "rename target" target fun targetResolved targetExtra =>
  let checks := CerbFS.Checks.renameChecks sourceResolved targetResolved
    (target.endsWith "/") (!st.files.isEmpty) targetExtra.isSome
  selectPathCheck st "rename" checks.head? fun _ =>
  match sourceResolved,targetResolved with
  | .directory,.directory => .returned st (.inr 0)
  | .file sourceKey,.file dest | .file sourceKey,.missing dest =>
    if sourceKey == dest then .returned st (.inr 0) else
    if anyFdOn st sourceKey || anyFdOn st dest then
      .stopped st (.missingCoverage s!"rename '{source}' to '{target}' with an open descriptor: inode identity across rename/replacement is not ported")
    else
      match lookupFile st sourceKey,st.fileModes.lookup sourceKey with
      | some contents,some mode => .returned {st with
          files := (dest,contents) :: st.files.filter (fun (p,_) => p != sourceKey && p != dest)
          fileModes := (dest,mode) :: st.fileModes.filter (fun (p,_) => p != sourceKey && p != dest)} (.inr 0)
      | _,_ => .stopped st (.protocol "rename resolved file lacks contents or permissions")
  | _,_ => .stopped st (.protocol "successful rename has incompatible resolved paths")

def fs_truncate (st : FsState) (path : String) (length : Int) : FsState × Sum FsError Nat :=
  match fs_truncate_checked st path length with
  | .returned next result => (next,result)
  | .stopped _ fault => failwithI fault.text

def fs_unlink (st : FsState) (path : String) : FsState × Sum FsError Nat :=
  match fs_unlink_checked st path with
  | .returned next result => (next,result)
  | .stopped _ fault => failwithI fault.text

def fs_rename (st : FsState) (source target : String) : FsState × Sum FsError Nat :=
  match fs_rename_checked st source target with
  | .returned next result => (next,result)
  | .stopped _ fault => failwithI fault.text


-- The pinned OS operation updates the mask and returns RV_file_perm. Its
-- run_umask wrapper passes that to return_nat, which rejects it. Retain the
-- state AFTER OS_RETURN, plus the exact decoder/value witness. Do not invent
-- the old mask as a successful return (the previous Lean implementation did).
def fs_umask_checked (st : FsState) (mask : Int) : FsResult Nat :=
  .stopped {st with umask := CerbFS.Checks.word32 mask}
    (.upstreamDecode "return_nat" s!"(RV_file_perm(File_perm {st.umask}))")

def fs_umask (st : FsState) (mask : Int) : FsState × Sum FsError Nat :=
  match fs_umask_checked st mask with
  | .returned next result => (next,result)
  | .stopped _ fault => failwithI fault.text


def fs_chmod_checked (st : FsState) (path : String) (mode : Int) : FsResult Nat :=
  .stopped st (.missingCoverage (refusal s!"chmod '{path}' (mode {mode})" "SibylFS changes the mode (ENOENT/EPERM per POSIX; later stat sees it); this model has no permission state and answered a success-returning no-op" moverDirs))

def fs_chmod (st : FsState) (path : String) (mode : Int) : FsState × (Sum FsError Nat) :=
  (fs_chmod_checked st path mode).legacy



def fs_chdir_checked (st : FsState) (dir : String) : FsResult Nat :=
  .stopped st (.missingCoverage (refusal s!"chdir '{dir}'" "SibylFS resolves later relative paths against the new directory (ENOENT/ENOTDIR per POSIX); this model recorded the string and kept resolving paths verbatim" moverDirs))

def fs_chdir (st : FsState) (dir : String) : FsState × (Sum FsError Nat) :=
  (fs_chdir_checked st dir).legacy



def fs_chown_checked (st : FsState) (path : String) (uid gid : Int) : FsResult Nat :=
  .stopped st (.missingCoverage (refusal s!"chown '{path}' ({uid}:{gid})" "SibylFS changes the owner (ENOENT/EPERM per POSIX; later stat sees it); this model has no ownership state and answered a success-returning no-op" moverDirs))

def fs_chown (st : FsState) (path : String) (uid gid : Int) : FsState × (Sum FsError Nat) :=
  (fs_chown_checked st path uid gid).legacy



def fs_link_checked (st : FsState) (oldP newP : String) : FsResult Nat :=
  .stopped st (.missingCoverage (refusal s!"link '{oldP}' → '{newP}'" "SibylFS creates a hard link (EEXIST/ENOENT per POSIX); this model answered ENOSYS, which the driver turns into errno + −1 for the C program to absorb" moverLinks))

def fs_link (st : FsState) (oldP newP : String) : FsState × (Sum FsError Nat) :=
  (fs_link_checked st oldP newP).legacy



def fs_readlink_checked (st : FsState) (path : String) : FsResult (List Char) :=
  .stopped st (.missingCoverage (refusal s!"readlink '{path}'" "SibylFS reads the link target (EINVAL/ENOENT per POSIX); this model answered ENOSYS (errno + −1)" moverLinks))

def fs_readlink (st : FsState) (path : String) : FsState × (Sum FsError (List Char)) :=
  (fs_readlink_checked st path).legacy



def fs_symlink_checked (st : FsState) (target lpath : String) : FsResult Nat :=
  .stopped st (.missingCoverage (refusal s!"symlink '{target}' ← '{lpath}'" "SibylFS creates a symbolic link (EEXIST/ENOENT per POSIX); this model answered ENOSYS (errno + −1)" moverLinks))

def fs_symlink (st : FsState) (target lpath : String) : FsState × (Sum FsError Nat) :=
  (fs_symlink_checked st target lpath).legacy



def fs_rmdir_checked (st : FsState) (path : String) : FsResult Nat :=
  .stopped st (.missingCoverage (refusal s!"rmdir '{path}'" "SibylFS removes a directory (ENOENT/ENOTEMPTY/ENOTDIR per POSIX); this model has no directories and answered a success-returning no-op" moverDirs))

def fs_rmdir (st : FsState) (path : String) : FsState × (Sum FsError Nat) :=
  (fs_rmdir_checked st path).legacy



def fs_stat_checked (st : FsState) (path : String) : FsResult FsStat :=
  .stopped st (.missingCoverage (refusal s!"stat '{path}'" "SibylFS answers the real st_dev/st_ino/st_mode/st_nlink/uid/gid/rdev/size fields (tests/suite/fs/stat.c: 2049 1 33261 1 0 0 0 10); this model answered zeroed fields except size (0 0 420 1 0 0 0 10)" moverStat))

def fs_stat (st : FsState) (path : String) : FsState × (Sum FsError FsStat) :=
  (fs_stat_checked st path).legacy



def fs_lstat_checked (st : FsState) (path : String) : FsResult FsStat :=
  .stopped st (.missingCoverage (refusal s!"lstat '{path}'" "SibylFS answers the real stat fields (no symlink following); this model answered zeroed fields except size" moverStat))

def fs_lstat (st : FsState) (path : String) : FsState × (Sum FsError FsStat) :=
  (fs_lstat_checked st path).legacy



def fs_opendir_checked (st : FsState) (path : String) : FsResult Nat :=
  .stopped st (.missingCoverage (refusal s!"opendir '{path}'" "SibylFS opens a directory stream (ENOENT/ENOTDIR per POSIX); this model has no directories and answered a fresh fd for any path" moverDirs))

def fs_opendir (st : FsState) (path : String) : FsState × (Sum FsError Nat) :=
  (fs_opendir_checked st path).legacy



def fs_readdir_checked (st : FsState) (dir : Int) : FsResult (List Char) :=
  .stopped st (.missingCoverage (refusal s!"readdir on {dir}" "SibylFS answers the next entry name; this model answered an always-empty stream" moverDirs))

def fs_readdir (st : FsState) (dir : Int) : FsState × (Sum FsError (List Char)) :=
  (fs_readdir_checked st dir).legacy



def fs_rewinddir_checked (st : FsState) (dir : Int) : FsResult Unit :=
  .stopped st (.missingCoverage (refusal s!"rewinddir on {dir}" "SibylFS rewinds a directory stream; this model has no directories and answered a no-op" moverDirs))

def fs_rewinddir (st : FsState) (dir : Int) : FsState :=
  match fs_rewinddir_checked st dir with
  | .returned next _ => next
  | .stopped _ fault => failwithI fault.text



def fs_closedir_checked (st : FsState) (dir : Int) : FsResult Nat :=
  .stopped st (.missingCoverage (refusal s!"closedir on {dir}" "SibylFS closes a directory stream; this model has no directories" moverDirs))

def fs_closedir (st : FsState) (dir : Int) : FsState × (Sum FsError Nat) :=
  (fs_closedir_checked st dir).legacy



-- Shared Lem interface, without duplicating transitions.
def fs_open_result (st : FsState) (path : String) (oflag : Int) (mode : Option Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_open_checked st path oflag mode).pack

def fs_read_result (st : FsState) (fd count : Int) : FsState × Sum FsFault (Sum FsError (List Char)) :=
  (fs_read_checked st fd count).pack

def fs_pread_result (st : FsState) (fd count offset : Int) : FsState × Sum FsFault (Sum FsError (List Char)) :=
  (fs_pread_checked st fd count offset).pack

def fs_write_result (st : FsState) (fd : Int) (data : List Char) (count : Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_write_checked st fd data count).pack

def fs_pwrite_result (st : FsState) (fd : Int) (data : List Char) (count offset : Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_pwrite_checked st fd data count offset).pack

def fs_close_result (st : FsState) (fd : Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_close_checked st fd).pack

def fs_lseek_result (st : FsState) (fd offset whence : Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_lseek_checked st fd offset whence).pack

def fs_mkdir_result (st : FsState) (path : String) (mode : Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_mkdir_checked st path mode).pack

def fs_truncate_result (st : FsState) (path : String) (length : Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_truncate_checked st path length).pack

def fs_unlink_result (st : FsState) (path : String) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_unlink_checked st path).pack

def fs_rename_result (st : FsState) (source target : String) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_rename_checked st source target).pack

def fs_umask_result (st : FsState) (mask : Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_umask_checked st mask).pack

def fs_chmod_result (st : FsState) (path : String) (mode : Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_chmod_checked st path mode).pack

def fs_chdir_result (st : FsState) (dir : String) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_chdir_checked st dir).pack

def fs_chown_result (st : FsState) (path : String) (uid gid : Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_chown_checked st path uid gid).pack

def fs_link_result (st : FsState) (oldP newP : String) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_link_checked st oldP newP).pack

def fs_readlink_result (st : FsState) (path : String) : FsState × Sum FsFault (Sum FsError (List Char)) :=
  (fs_readlink_checked st path).pack

def fs_symlink_result (st : FsState) (target lpath : String) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_symlink_checked st target lpath).pack

def fs_rmdir_result (st : FsState) (path : String) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_rmdir_checked st path).pack

def fs_stat_result (st : FsState) (path : String) : FsState × Sum FsFault (Sum FsError FsStat) :=
  (fs_stat_checked st path).pack

def fs_lstat_result (st : FsState) (path : String) : FsState × Sum FsFault (Sum FsError FsStat) :=
  (fs_lstat_checked st path).pack

def fs_opendir_result (st : FsState) (path : String) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_opendir_checked st path).pack

def fs_readdir_result (st : FsState) (dir : Int) : FsState × Sum FsFault (Sum FsError (List Char)) :=
  (fs_readdir_checked st dir).pack

def fs_rewinddir_result (st : FsState) (dir : Int) : FsState × Sum FsFault (Sum FsError Unit) :=
  (fs_rewinddir_checked st dir).pack

def fs_closedir_result (st : FsState) (dir : Int) : FsState × Sum FsFault (Sum FsError Nat) :=
  (fs_closedir_checked st dir).pack

end CerbFS
