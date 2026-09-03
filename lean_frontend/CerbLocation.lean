/-
  Source location tracking.
  Corresponds to: util/cerb_location.ml and util/cerb_position.mli

  This is the Lean equivalent of Cerb_location.t — a real implementation,
  not a unit stub. Tracks file, line, column, and region information.
-/

namespace CerbLocation

/-- Source position (file, line, column). All 1-based.
    Corresponds to: Cerb_position.t -/
structure Pos where
  file : String
  line : Nat
  col : Nat
  deriving BEq, Ord, Inhabited, Repr

/-- Cursor within a location region.
    Corresponds to: Cerb_location.cursor -/
inductive Cursor where
  | noCursor : Cursor
  | pointCursor : Pos → Cursor
  | regionCursor : Pos → Pos → Cursor
  deriving BEq, Ord, Inhabited, Repr

/-- Source location.
    Corresponds to: Cerb_location.t -/
inductive Loc where
  | unknown : Loc
  | other : String → Loc
  | point : Pos → Loc
  | region : Pos → Pos → Cursor → Loc
  | regions : List (Pos × Pos) → Cursor → Loc
  deriving BEq, Inhabited, Repr

-- Ord Loc (needed by generated code — e.g. Undefined.lean uses Loc in
-- sets). Arc-14 S1 F4 (sem:S3): a real structural lexicographic order
-- (by constructor rank, then fields via the existing Ord Pos/Cursor),
-- replacing the previous `compare (repr a).pretty (repr b).pretty` —
-- which was both unlawful as a stable key discipline (lexicographic on
-- pretty-printed Repr text: "line 10" < "line 9") and O(n·|repr|) per
-- comparison. Total, lawful, structural; it does not mirror OCaml's
-- Cerb_location compare (locations are cosmetic on the batch path — no
-- differential output enumerates a Loc-keyed set), a deliberate
-- proof-friendliness divergence, documented. `Ord (List (Pos × Pos))`
-- is not auto-derived, so the region list is compared element-wise here.
private def cmpPosPairList : List (Pos × Pos) → List (Pos × Pos) → Ordering
  | [], [] => .eq
  | [], _ => .lt
  | _, [] => .gt
  | (a1, b1) :: xs, (a2, b2) :: ys =>
    match compare a1 a2 with
    | .eq => match compare b1 b2 with
      | .eq => cmpPosPairList xs ys
      | o => o
    | o => o

private def locRank : Loc → Nat
  | .unknown => 0 | .other _ => 1 | .point _ => 2
  | .region _ _ _ => 3 | .regions _ _ => 4

instance : Ord Loc where
  compare a b := match a, b with
    | .unknown, .unknown => .eq
    | .other s1, .other s2 => compare s1 s2
    | .point p1, .point p2 => compare p1 p2
    | .region a1 b1 c1, .region a2 b2 c2 =>
      match compare a1 a2 with
      | .eq => match compare b1 b2 with | .eq => compare c1 c2 | o => o
      | o => o
    | .regions l1 c1, .regions l2 c2 =>
      match cmpPosPairList l1 l2 with | .eq => compare c1 c2 | o => o
    | _, _ => compare (locRank a) (locRank b)

/-! ## Constructors -/

def unknown : Loc := .unknown

def other (s : String) : Loc := .other s

/-! ## Cursor operations
    Corresponds to: cerb_location.ml:41-54 -/

def withCursor : Loc → Loc
  | .unknown | .other _ => .unknown
  | .regions [] .noCursor => .unknown
  | .point z | .region _ _ (.pointCursor z)
  | .region z _ .noCursor
  | .regions _ (.pointCursor z)
  | .regions ((z, _) :: _) .noCursor => .point z
  | .region _ _ (.regionCursor b e)
  | .regions _ (.regionCursor b e) => .region b e .noCursor

/-- Corresponds to: cerb_location.ml:59-90 -/
def withCursorFrom (loc1 loc2 : Loc) : Loc :=
  let cursor := match loc2 with
    | .unknown | .other _ => Cursor.noCursor
    | .point z => .pointCursor z
    | .region s e .noCursor => .regionCursor s e
    | .region _ _ cur => cur
    | .regions _ z => z
  match loc1 with
  | .unknown => match cursor with
    | .noCursor => .unknown
    | .pointCursor pos => .point pos
    | .regionCursor b e => .region b e .noCursor
  | .other str => .other str
  | .point z => .region z z cursor
  | .region b e _ => .region b e cursor
  | .regions rs _ => .regions rs cursor

/-! ## Bounding box
    Corresponds to: cerb_location.ml:103-149 -/

private def posLt (p1 p2 : Pos) : Bool :=
  if p1.line == p2.line then p1.col < p2.col
  else p1.line < p2.line

private def outerBbox (xs : List (Pos × Pos)) : Pos × Pos :=
  match xs with
  | [] => (default, default)
  | (b0, e0) :: rest =>
    rest.foldl (fun (bAcc, eAcc) (b, e) =>
      ((if posLt b bAcc then b else bAcc), (if posLt e eAcc then eAcc else e))
    ) (b0, e0)

def bboxLocation (xs : List Loc) : Loc :=
  let (defLoc, acc) := xs.foldl (fun (defLoc, acc) loc =>
    match loc with
    | .unknown => (defLoc, acc)
    | .other _ => (loc, acc)
    | .point pos => (defLoc, (pos, pos) :: acc)
    | .region p1 p2 _ => (defLoc, (p1, p2) :: acc)
    | .regions rs _ => (defLoc, rs ++ acc)
  ) (Loc.unknown, [])
  match acc with
  | [] => defLoc
  | _ =>
    let (b, e) := outerBbox acc
    .region b e .noCursor

/-- Corresponds to: cerb_location.ml:152-171 -/
def withRegionsAndCursor (locs : List Loc) (locOpt : Option Loc) : Loc :=
  let cursorOpt := match locOpt with
    | some (.point z) => Cursor.pointCursor z
    | some (.region _ _ z) | some (.regions _ z) => z
    | _ => .noCursor
  let posOfRegion : Loc → Option (Pos × Pos)
    | .point p => some (p, p)
    | .region p1 p2 _ => some (p1, p2)
    | _ => none
  let rec collectAll (acc : List (Pos × Pos)) : List (Option (Pos × Pos)) → Option (List (Pos × Pos))
    | some x :: xs => collectAll (x :: acc) xs
    | [] => some acc
    | none :: _ => none
  match collectAll [] (locs.map posOfRegion) with
  | some regs => .regions regs cursorOpt
  | none => .unknown

/-! ## Queries -/

def getFilename : Loc → Option String
  | .unknown | .regions [] _ => none
  | .other _ => some "<internal>"
  | .point pos | .region pos _ _ | .regions ((pos, _) :: _) _ => some pos.file

/-- OCaml `Filename.dirname` (Unix): strip trailing slashes, then drop the
    last component; a bare name gives "."; a root-level name gives "/". -/
private def dirname (p : String) : String :=
  let trimmed := (p.dropRightWhile (· == '/'))
  if trimmed.isEmpty then (if p.isEmpty then "." else "/")
  else
    let dir := (trimmed.dropRightWhile (· != '/')).dropRightWhile (· == '/')
    if !trimmed.contains '/' then "." else if dir.isEmpty then "/" else dir

/-- The three library directories of `util/cerb_location.ml:512-520`,
    runtime-relative: `Cerb_runtime.in_runtime "libc/include"`, `… "libcore"`,
    `… "libcore/impls"` — the cerberus-lib RUNTIME tree
    (`<prefix>/lib/cerberus-lib/runtime/…`, or `<sourceroot>/runtime/…`). -/
private def libraryDirs : List String :=
  ["runtime/libc/include", "runtime/libcore", "runtime/libcore/impls"]

/-- is_library_location — util/cerb_location.ml:512-520: the location is
    "library" iff `Filename.dirname path` IS one of the three runtime-prefixed
    directories above (an exact string test on the oracle). Behaviour-bearing
    on every UB-location path: `core_eval.lem:602` and `core_run.lem:476`
    substitute the enclosing C location for a library-located UB, and
    `core_run.lem:781` refuses to overwrite a thread's `current_loc` with a
    library location.
    MIRROR WITH ONE DOCUMENTED RESIDUAL (zero-discrepancy Z-67, charter
    §2.7): the Lean process has no `Cerb_runtime` — the runtime ROOT is not
    plumbed — so the directory is tested to END WITH the runtime-relative
    path (or equal it when relative, as for the `runtime/libcore/std.core`
    Main.findRuntimeDir loads). The oracle's own paths always satisfy this
    (the cpp step prefixes header locations with the same runtime tree the
    `--cabs-json` bridge hands us); the residual is a USER file under a
    directory literally named `runtime/libcore` (or the other two), which
    Lean classifies library and the oracle does not. Mover: plumb the
    runtime root from Main (the CerbGlobal parameter-plumbing slice).
    The previous implementation matched ANY path segment equal to
    `libcore`/`include`/`impls` — a user file under any `include/` directory
    was library-classified (wrong), and std.core itself was never classified
    because CoreParser stamped no file at all (Z-01). -/
def isLibraryLocation (loc : Loc) : Bool :=
  match getFilename loc with
  | none => false
  | some path =>
    let dir := dirname path
    libraryDirs.any (fun d => dir == d || dir.endsWith ("/" ++ d))

/-! ## String conversion
    Corresponds to: cerb_location.ml:188-237 (location_to_string) and
    :476-491 (simple_location) -/

/-- simple_location — util/cerb_location.ml:476-491 verbatim: the renderer
    of the batch verdict `loc:` field (driver_ocaml.ml:113/127). Zero-
    discrepancy Z-03 (noodle O1): the batch lines used `stringFromLocation`
    (`file:L:C-C`) — the UB location is behaviour [USER 2026-09-03], so its
    rendering must agree byte-for-byte. An empty `Loc_regions` list makes
    the OCaml `List.hd` raise `Failure "hd"`; mirrored as a fail-stop. -/
def simpleLocation : Loc → String
  | .unknown => "<unknown location>"
  | .other str => s!"<other location: {str}>"
  | .point pos => s!"{pos.line}:{pos.col}"
  | .region s e _ => s!"<{s.line}:{s.col}--{e.line}:{e.col}>"
  | .regions ((s, e) :: _) _ => s!"<{s.line}:{s.col}--{e.line}:{e.col}>"
  | .regions [] _ => panic! "hd"

private def stringOfPos (pos : Pos) : String :=
  s!"{pos.file}:{pos.line}:{pos.col}"

def stringFromLocation : Loc → String
  | .unknown => "unknown location"
  | .other str => s!"other_location({str})"
  | .point pos => s!"{stringOfPos pos}:"
  | .region p1 p2 _ =>
    let fileStr := if p1.file == p2.file then "" else p2.file
    let lineStr := if p1.line == p2.line then "" else s!"{p2.line}:"
    s!"{stringOfPos p1}-{fileStr}{lineStr}{p2.col}"
  | .regions xs _ =>
    let (p1, p2) := outerBbox xs
    let fileStr := if p1.file == p2.file then "" else p2.file
    let lineStr := if p1.line == p2.line then "" else s!"{p2.line}:"
    s!"{stringOfPos p1}-{fileStr}{lineStr}{p2.col}"

end CerbLocation
