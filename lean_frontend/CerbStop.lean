import Lean.Data.Json.Parser
import Lean.Data.Json.Printer

/-! Operational stop metadata. The fixed-array wire format is specified in
docs/2026-10-20_outcome-protocol-design-v2.md §2. This is diagnostic attribution,
not authentication of the producer or a structural replacement for Error0.
Metadata constraints live in the values, so render cannot emit an invalid tuple.
There is no failure atom here; pure callers retain their visible failwithI head. -/
namespace CerbStop

inductive DecodeError where
  | absent
  | malformed (reason : String)
  deriving Repr, BEq

structure NonemptyText where
  value : String
  nonempty : value.isEmpty = false
  deriving Repr, BEq

def nonempty (s : String) : Except DecodeError NonemptyText :=
  if h : s.isEmpty = false then .ok ⟨s, h⟩
  else .error (.malformed "empty required text")

inductive Boundary where
  | fs | pnvi | switches | concurrency | floatFormat | cli | runtime
  | libraryLocation | cabsJsonUtf8 | batchUbPayload | abortFlag | fuelArg | addressSpaceArg
  deriving Repr, BEq

def Boundary.text : Boundary → String
  | .fs => "fs" | .pnvi => "pnvi" | .switches => "switches"
  | .concurrency => "concurrency" | .floatFormat => "float-format"
  | .cli => "cli" | .runtime => "runtime" | .libraryLocation => "library-location"
  | .cabsJsonUtf8 => "cabs-json-utf8" | .batchUbPayload => "batch-ub-payload"
  | .abortFlag => "abort-flag" | .fuelArg => "fuel-arg" | .addressSpaceArg => "address-space-arg"

def Boundary.parse : String → Except DecodeError Boundary
  | "fs" => .ok .fs | "pnvi" => .ok .pnvi | "switches" => .ok .switches
  | "concurrency" => .ok .concurrency | "float-format" => .ok .floatFormat
  | "cli" => .ok .cli | "runtime" => .ok .runtime | "library-location" => .ok .libraryLocation
  | "cabs-json-utf8" => .ok .cabsJsonUtf8 | "batch-ub-payload" => .ok .batchUbPayload
  | "abort-flag" => .ok .abortFlag | "fuel-arg" => .ok .fuelArg
  | "address-space-arg" => .ok .addressSpaceArg
  | _ => .error (.malformed "unknown boundary")

inductive Repository where
  | cerberus | lem
  deriving Repr, BEq

def revisionValid (s : String) : Bool :=
  s.length == 40 && s.toList.all (fun c => c.isDigit || ('a' ≤ c && c ≤ 'f'))

private def componentValid (p : List Char) : Bool :=
  !p.isEmpty && p != ['.'] && p != ['.', '.']

private def pathCharsValid (part : List Char) : List Char → Bool
  | [] => componentValid part
  | '/' :: rest => componentValid part && pathCharsValid [] rest
  | c :: rest => pathCharsValid (c :: part) rest

def pathValid (s : String) : Bool := pathCharsValid [] s.toList

structure Upstream where
  repository : Repository
  revision : String
  path : String
  first : Nat
  last : Nat
  text : String
  revision_valid : revisionValid revision = true
  path_valid : pathValid path = true
  lines_valid : 0 < first ∧ first ≤ last
  deriving Repr, BEq

/-- Absolute HTTPS issue link: nonempty authority, no whitespace/control or
backslash. No network lookup or assertion of filed status is performed. -/
def httpsValid (s : String) : Bool :=
  let authority := (s.toList.drop 8).takeWhile (fun c => c != '/' && c != '?' && c != '#')
  s.toList.take 8 == ['h', 't', 't', 'p', 's', ':', '/', '/'] &&
  !authority.isEmpty && s.toList.all (fun c => c.toNat > 32 && c.toNat != 127 && c != '\\')

inductive Tray where
  | none
  | pending
  | draft (number : Nat) (positive : 0 < number)
  | filed (url : String) (valid : httpsValid url = true)
  deriving Repr, BEq

structure Refusal where
  boundary : Boundary
  item : Option String := none
  detail : NonemptyText
  mover : NonemptyText
  upstream : Option Upstream := none
  see : Option NonemptyText := none
  deriving Repr, BEq

structure UpstreamCrash where
  site : NonemptyText
  detail : NonemptyText
  upstream : Upstream
  tray : Tray := .none
  see : Option NonemptyText := none
  deriving Repr, BEq

structure Invariant where
  site : NonemptyText
  detail : NonemptyText
  see : NonemptyText
  deriving Repr, BEq

inductive Stop where
  | refusal (metadata : Refusal)
  | upstreamCrash (metadata : UpstreamCrash)
  | invariant (metadata : Invariant)
  deriving Repr, BEq

/-- The typed-kill adapter's domain excludes refusals. -/
inductive Failure where
  | upstreamCrash (metadata : UpstreamCrash)
  | invariant (metadata : Invariant)
  deriving Repr, BEq

def Failure.toStop : Failure → Stop
  | .upstreamCrash m => .upstreamCrash m
  | .invariant m => .invariant m

private def optional {α : Type} (f : α → Lean.Json) : Option α → Lean.Json
  | none => .null
  | some a => f a

private def upstreamJson (u : Upstream) : Lean.Json :=
  .arr #[.str (match u.repository with | .cerberus => "cerberus" | .lem => "lem"),
    .str u.revision, .str u.path, .str (toString u.first), .str (toString u.last), .str u.text]

private def trayJson : Tray → Lean.Json
  | .none => .arr #[.str "none"]
  | .pending => .arr #[.str "pending"]
  | .draft n _ => .arr #[.str "draft", .str (toString n)]
  | .filed url _ => .arr #[.str "filed", .str url]

def toJson : Stop → Lean.Json
  | .refusal r => .arr #[.str "1", .str "REFUSAL", .str r.boundary.text,
      optional .str r.item, .str r.detail.value, .str r.mover.value,
      optional upstreamJson r.upstream, optional (fun s => .str s.value) r.see]
  | .upstreamCrash u => .arr #[.str "1", .str "UPSTREAM_CRASH", .str u.site.value,
      .str u.detail.value, upstreamJson u.upstream, trayJson u.tray,
      optional (fun s => .str s.value) u.see]
  | .invariant i => .arr #[.str "1", .str "INVARIANT", .str i.site.value,
      .str i.detail.value, .str i.see.value]

def wirePrefix : String := "cerberus-lean stop "
def reserved : String := "cerberus-lean stop"
def render (stop : Stop) : String := wirePrefix ++ (toJson stop).compress

private def bad {α : Type} (why : String) : Except DecodeError α :=
  .error (.malformed why)

private def text : Lean.Json → Except DecodeError String
  | .str s => .ok s
  | _ => bad "expected string"

private def required (j : Lean.Json) : Except DecodeError NonemptyText := do
  nonempty (← text j)

private def opt {α : Type} (f : Lean.Json → Except DecodeError α) :
    Lean.Json → Except DecodeError (Option α)
  | .null => .ok none
  | j => some <$> f j

private def positive (j : Lean.Json) : Except DecodeError Nat := do
  let s ← text j
  if s.isEmpty || s.startsWith "0" || !s.toList.all Char.isDigit then
    bad "expected canonical positive decimal string"
  else match s.toNat? with
    | some n => pure n
    | none => bad "invalid positive decimal string"

private def parseUpstream : Lean.Json → Except DecodeError Upstream
  | .arr #[repo, rev, path, first, last, source] => do
    let repository ← match ← text repo with
      | "cerberus" => pure Repository.cerberus
      | "lem" => pure Repository.lem
      | _ => bad "unknown upstream repository"
    let revision ← text rev
    let path ← text path
    let first ← positive first
    let last ← positive last
    let source ← text source
    if hr : revisionValid revision = true then
      if hp : pathValid path = true then
        if hl : 0 < first ∧ first ≤ last then
          pure ⟨repository, revision, path, first, last, source, hr, hp, hl⟩
        else bad "invalid source line range"
      else bad "invalid repository-relative path"
    else bad "invalid full revision"
  | _ => bad "expected six-field upstream tuple"

private def parseTray : Lean.Json → Except DecodeError Tray
  | .arr #[.str "none"] => pure .none
  | .arr #[.str "pending"] => pure .pending
  | .arr #[.str "draft", n] => do
    let n ← positive n
    if h : 0 < n then pure (.draft n h) else bad "zero draft number"
  | .arr #[.str "filed", .str url] =>
    if h : httpsValid url = true then pure (.filed url h) else bad "invalid HTTPS issue URL"
  | _ => bad "unknown tray or tuple shape"

private def fromJson : Lean.Json → Except DecodeError Stop
  | .arr #[.str "1", .str "REFUSAL", boundary, item, detail, mover, upstream, see] => do
    pure (.refusal ⟨← Boundary.parse (← text boundary), ← opt text item,
      ← required detail, ← required mover, ← opt parseUpstream upstream, ← opt required see⟩)
  | .arr #[.str "1", .str "UPSTREAM_CRASH", site, detail, upstream, tray, see] => do
    pure (.upstreamCrash ⟨← required site, ← required detail, ← parseUpstream upstream,
      ← parseTray tray, ← opt required see⟩)
  | .arr #[.str "1", .str "INVARIANT", site, detail, see] => do
    pure (.invariant ⟨← required site, ← required detail, ← required see⟩)
  | _ => bad "unknown version, constructor or tuple shape"

/-- Check escape tokens before Json.parse can normalize duplicate keys or
surrogates. A consumed escaped backslash does not introduce a Unicode escape.
Objects are rejected by the exact tuple/field parsers, at every depth. -/
private def escapesValid : List Char → Bool
  | [] => true
  | '\\' :: 'u' :: '0' :: '0' :: hi :: lo :: rest =>
    (hi == '0' || hi == '1') && lo.isHexDigit && escapesValid rest
  | '\\' :: c :: rest =>
    ['"', '\\', '/', 'b', 'f', 'n', 'r', 't'].contains c && escapesValid rest
  | c :: rest => c != '\r' && c != '\n' && escapesValid rest

def parse (input : String) : Except DecodeError Stop := do
  if !input.startsWith reserved then throw .absent
  if !input.startsWith wirePrefix then bad "invalid reserved-prefix suffix" else do
    let body := (input.drop wirePrefix.length).toString
    if !escapesValid body.toList then bad "invalid wire escape or raw line break" else do
      let json ← (Lean.Json.parse body).mapError DecodeError.malformed
      fromJson json

/-- Channel adapters exit once, after every refusal element. Separating the
nonempty head from the tail makes an empty refusal batch unrepresentable. -/
def exitRefusals {α : Type} (first : Refusal) (rest : List Refusal := []) : IO α := do
  let err ← IO.getStderr
  for r in first :: rest do err.putStrLn (render (.refusal r))
  err.flush
  IO.Process.exit 2

def exitInvariant {α : Type} (i : Invariant) : IO α := do
  let err ← IO.getStderr
  err.putStrLn (render (.invariant i))
  err.flush
  IO.Process.exit 2

end CerbStop
