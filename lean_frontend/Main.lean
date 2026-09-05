import CerberusImpl
import CerbMem
import CerbCtypeInstances
import CerbCabsInstances
import CabsImport
import CoreParser
import Cabs_to_ail
import Cn_desugaring
import Implementation
import GenTyping
import Translation
import Core_run_aux
import Driver
import CerbND
-- the `--call` mode's entry (CerbCall.driveCall): `drive` started at a
-- designated function with injected arguments — a port-side harness
-- entry over the generated driver (see CerbCall.lean's header)
import CerbCall

set_option autoImplicit true

/-! ## Core stdlib loading -/

/-- Convert a CoreParser.CoreFile from std.core into the tuple the
    desugarer expects: (ailnames, stdlib_fun_map, impl).

    Mirrors `load_core_stdlib` (backend/common/pipeline.ml:32-44) returning
    `Rstd (ailnames, std_funs)` from the StdMode core parser
    (core_parser.mly:1076-1080): the ailnames map is C-name → proxy symbol,
    built EXCLUSIVELY from `[ailname = "..."]` attributes on proc
    declarations (`register_ailname`, core_parser.mly:157-159, invoked only
    at Proc_decl symbolification :1037-1041) — 46 entries for the shipped
    std.core. Declaration names must NOT be keys: translation looks up the
    C identifier (e.g. "malloc", "__builtin_ffs") in this map and
    substitutes the proxy symbol at the call site
    (translation.lem:244-251); keying by declaration name both misses
    every C name AND mis-binds "printf" to the `builtin printf`
    declaration (std.core:283) instead of `printf_proxy` (std.core:289).

    The fun_map keeps ALL declarations (fun + proc + builtin), matching
    symbolify_std (core_parser.mly:1010-1046: Fun/Proc/BuiltinDecl entries).
    CoreParser.mkSym assigns hash-based IDs per string, so all calls to the
    same-named function end up with the same symbol — no renumbering. -/
def loadCoreStdlib (stdFile : CoreParser.CoreFile) :
    Fmap String sym × fun_map Unit :=
  let allDecls := stdFile.funs ++ stdFile.procs ++ stdFile.builtins
  -- Duplicate-key divergence (arc-5 audit 2, F4, documented-deliberate):
  -- Lem_Map.fromList is a foldl of fmapAdd, so on duplicate ailnames the
  -- LAST-in-file entry wins; OCaml's foldrM registration
  -- (core_parser.mly:135-137 + register_ailname :157-159) makes the
  -- FIRST-in-file entry win. std.core is ailname-duplicate-free
  -- (verified), so this is unreachable today — see the capture-site note
  -- in CoreParser.pCoreFileGo.
  let ailnames : Fmap String sym := Lem_Map.fromList stdFile.ailnames
  let funMap : fun_map Unit := Lem_Map.fromList allDecls
  (ailnames, funMap)

/-- Convert impl declarations from a CoreParser.CoreFile into an impl map. -/
def loadCoreImpl (implFile : CoreParser.CoreFile) : impl :=
  implFile.impls.foldl
    (fun acc (name, d) =>
      -- the name was validated against Implementation.impl_map when the
      -- `def <name>` / `fun <name>` declaration was parsed (CoreParser.pDefDecl
      -- and pFunDecl call pImplConstant on the lexeme — the mirror of scan_impl,
      -- which validates every `<…>` lexeme at the lexer; Z2-CP-08, pre-merge
      -- audit F2), so the error arm is unreachable here
      let ic := match CoreParser.pImplConstant name with
        | .ok ic => ic
        | .error e => panic! e
      fmapAddBy implementation_constant_compare ic d acc)
    fmapEmpty

/-! ## C-libc loading (`--libc`, arc-6 S1; the stitch reversed in zero-discrepancy Z3)

The oracle loads `runtime/libc/libc.co` — an OCaml-marshalled `core_dump`
record carrying main / calling_convention / tagDefs / globs / funs /
extern / funinfo (backend/common/pipeline.ml:621-630; reader
`read_core_object` :648-672) — as a LIBRARY, FIRST, before the user TUs
(backend/driver/main.ml:150-156: `core_libraries … @ files`, lib "c"
resolved at :54-77 to plain libc.co, i.e. Normal calling convention).

The Lean pipeline cannot read OCaml Marshal. Its libc artifact is split
in two (decision log D5; scripts/libc_prep.sh):

* BODIES (funs and globs, in file order) come from the PINNED text dump
  `tests/libc/libc.core` — the stock pretty-print of libc.co
  (`cerberus --nolibc --pp=core --pp_core_out=… libc.co`, S0 survey
  §a.1), i.e. the oracle's sequentialised+rewritten libc Core, parsed by
  CoreParser. This is ORACLE-PRODUCED INPUT in the cabs-json trust
  class: pinned and drift-checked fail-closed by libc_prep.sh.

* METADATA (extern, funinfo, tagDefs, calling convention) is NOT in the
  text dump: the stock pp omits extern/funinfo/main entirely
  (pp_extern_symmap and pp_funinfo are unreachable from the CLI,
  pp_core.ml:811-829 + pipeline.ml:536-549) and drops every tagDef whose
  definition site is an #include'd header (pp_cond, pp_core.ml:745-746,
  show_include=false — only `struct fl` survives in the dump). The
  metadata is reconstructed by frontending the SAME 12 libc source TUs
  (runtime/libc/dune:145-146, same order, same include flags) through
  our own desugar/typecheck/translate and linking them with the
  generated Core_linking — the very pipeline that produced libc.co's
  metadata on the OCaml side (extern: `translate_extern_map`,
  translation.lem:4505-4511; funinfo/tagDefs assembly:
  translation.lem:4521-4540; link merge: link_aux/link_extern,
  core_linking.lem:10-46,286-316). `--sequentialise --rewrite` (which
  the oracle's libc.co build additionally applies) are Core-to-Core BODY
  passes; they do not alter extern/funinfo/tagDefs, so the
  reconstruction is exact up to symbol identity.

* SYMBOL IDENTITY IS BEHAVIOUR (zero-discrepancy Z3, census row Z-28,
  detective RC-2): `Core_linking.merge_globs` (core_linking.lem:252-273)
  orders the linked globals by a topological sort whose tie-break is
  `Set_extra.choose` = `Pset.min_elt` (pset.ml:297) under
  `symbol_compare` — digest, then number (symbol.lem:157-160) — and
  `Driver.driver_globals` (driver.lem:1577-1584) allocates them in that
  order, so the (digest, number) of every libc global fixes every later
  address (`(long)&g` is a Defined value under PVI). The oracle's libc.co
  symbols carry the digest of their libc SOURCE file (`Cerb_fresh.set_digest`
  = `Digest.file`, pipeline.ml:181, at the dune build of libc.co) and the
  build's single-supply numbers. The metadata TUs here carry the same
  digests (their cabs-jsons record the oracle's `Digest.file` of the same
  sources — main.ml --cabs-json path) and numbers drawn by the same lem
  elaboration, i.e. order-isomorphic within a TU — so the METADATA
  symbols order exactly as the oracle's. CoreParser's dump symbols do not
  (name-interned: digest "", number = the name's hash — every libc global
  sorted before every program global, in hash order among themselves).

* THE STITCH therefore renames the DUMP onto the METADATA symbols
  (`CoreParser.renameFile`, two namespaces: ordinary identifiers and
  struct/union tags — `struct stat` and the function `stat` coexist):
  - tags by name (the headers' structs recur in every including TU: all
    same-name definitions must agree structurally, fail-closed, and the
    first in symbol order is the rename target — any structurally-equal
    one yields the same layout; every TU's own entry stays in tagDefs, as
    in libc.co);
  - functions by name (the DEFINITION's symbol where a name is declared
    in one TU and defined in another — __strtox/__strtoxd — because that
    is the symbol `link_extern` resolves calls to; checked against
    metaFile.extern's LK_normal/LK_tentative targets, fail-closed);
  - globals by POSITION: metaFile.globs is the metadata's own link order,
    the same `merge_globs` over the same keys and dependency edges as the
    oracle's libc.co link, so it must equal the dump's order (libc.co's
    globs, printed in order by pp_globs, pp_core.ml:832-841). Checked
    entry by entry — kind, ail ctype (tags by name), and name (named
    globals by name; the unnamed string-literal globals print as `a_<n>`
    with the oracle's number and have no name to join on, so position is
    their only join, which is why the whole-list agreement is
    load-bearing and any disagreement refuses the load).
  Unmapped names (locals, labels, std.core procs and proxies such as
  exit_proxy/vprintf_proxy — present in the metadata's funinfo because
  ailname substitution happens at elaboration, translation.lem:244-251)
  keep their CoreParser symbols, which ARE the std.core symbols.
  Same-named static functions in two TUs (`__procfdname`) are one
  name-interned body in the dump; the first metadata symbol in symbol
  order takes it (the other keeps its funinfo entry only).

Assembly mirrors `read_core_object` (pipeline.ml:655-663): stdlib/impl
come from the load context (:657-660), loop_attributes and
visible_objects_env are EMPTY (:661-663; empty visible_objects_env also
preserves safe_map_union's disjointness requirement at link,
core_linking.lem safe_map_union), and main = none — libc.co is a
main-less library; link_main tolerates it (core_linking.lem:50-57).
tagDefs/extern/funinfo are the linked metadata's own maps (the oracle's
libc.co carries exactly these, under exactly these symbols up to the
within-TU numbering offset).

Documented divergences from the oracle's in-memory libc file:
* ProcDecl return base types parse as BTy_unit (not printed by the pp,
  pp_core.ml:783-785) — unread for declaration-only symbols.
* Same-named static functions conflate to one body (name-hash
  interning); fail-closed structural checks make this observable-
  behavior-preserving for the pinned dump.
* Symbol NUMBERS are the Lean supply's, not libc.co's: equal up to a
  per-TU constant offset (the oracle's std.core parse and per-TU
  rewrite passes draw from the same counter), so every `symbol_compare`
  outcome agrees; the absolute number is printed only in `a_<n>` names
  of Illformed_program payloads (Z-04, EXC(a)).
-/

/-- symbolEqual (symbol.lem): digest+number, description ignored. -/
private def libcSymEq : sym → sym → Bool
  | Symbol d1 n1 _, Symbol d2 n2 _ => d1 == d2 && n1 == n2

/-- The name `--pp core` prints for a symbol (Pp_symbol.to_string_pretty,
    pp_symbol.ml:20-24: SD_Id, SD_ObjectAddress, SD_FunArgValue) — the name
    the dump's interning joins on; `none` for unnamed symbols (which print
    as `a_<n>` and are never name-joined). -/
private def libcSymNameOpt : sym → Option String
  | Symbol _ _ (SD_Id s) | Symbol _ _ (SD_ObjectAddress s) | Symbol _ _ (SD_FunArgValue s) => some s
  | _ => none

private def libcSymName : sym → String
  | Symbol _ n sd =>
    match sd with
    | .SD_Id s | .SD_ObjectAddress s | .SD_FunArgValue s => s
    | .SD_None => s!"<SD_None sym {n}>"
    | _ => s!"<unnamed sym {n}>"

/-- The dump prints an unnamed symbol as `a_<n>` (pp_symbol.ml:33-34). -/
private def libcIsUnnamedName (s : String) : Bool :=
  s.startsWith "a_" && s.length > 2 && (s.drop 2).all Char.isDigit

private def identName : identifier → String
  | Identifier _ s => s

/-- Tag positions rekeyed BY NAME onto CoreParser's interning — the
    comparison frame in which two TUs' copies of one header struct (each
    referencing its own TU's tag symbols) are structurally equal. -/
private def libcByNameCtx : CoreParser.RenameCtx :=
  { onSym := id
    onTag := fun s => match libcSymNameOpt s with
      | some n => CoreParser.internSym n
      | none => s }

/-- Structural agreement for same-name tag definitions from different TUs
    (same headers ⇒ identical layouts). Member names, qualifiers and
    ctypes (tags by name) are compared; attributes/alignment are not
    (no_attributes/none throughout the libc headers). -/
private def libcMemberEq
    (m1 m2 : identifier × (attributes × Option alignment × qualifiers × ctype)) : Bool :=
  identName m1.1 == identName m2.1 &&
  qualifiersEqual m1.2.2.2.1 m2.2.2.2.1 &&
  ctypeEqual (CoreParser.renameCtype libcByNameCtx m1.2.2.2.2)
    (CoreParser.renameCtype libcByNameCtx m2.2.2.2.2)

private def libcTagDefEq : tag_definition → tag_definition → Bool
  | StructDef xs1 f1, StructDef xs2 f2 =>
    xs1.length == xs2.length &&
    (List.zip xs1 xs2).all (fun (a, b) => libcMemberEq a b) &&
    (match f1, f2 with
     | none, none => true
     | some (FlexibleArrayMember _ i1 q1 t1), some (FlexibleArrayMember _ i2 q2 t2) =>
       identName i1 == identName i2 && qualifiersEqual q1 q2 &&
       ctypeEqual (CoreParser.renameCtype libcByNameCtx t1) (CoreParser.renameCtype libcByNameCtx t2)
     | _, _ => false)
  | UnionDef xs1, UnionDef xs2 =>
    xs1.length == xs2.length &&
    (List.zip xs1 xs2).all (fun (a, b) => libcMemberEq a b)
  | _, _ => false

/-- Comparators the generated lem code keys these maps with (arc-6 S3: the
    Fmap representation captures the comparator at build time). sym-keyed
    maps: `symbol_compare` (the Ord0 sym instance every generated
    `Map.lookup`/`insert` on syms inlines). -/
private def libcSymMapCmp : sym → sym → LemOrdering := symbol_compare

/-- `map_from_assoc` mirror — backend/common/pipeline.ml:653-654:
    `List.fold_left (fun acc (k, v) -> Pmap.add k v acc) (Pmap.empty compare)`
    — a LEFT fold of `Pmap.add`, so on a duplicate key the later binding
    wins, as in the OCaml. The one assoc list built below (`funs`) is
    duplicate-free by construction (the find?-dedup), so the fold
    direction is unobservable here and the OCaml direction is mirrored
    regardless. -/
private def libcMapFromAssoc {α β : Type} (cmp : α → α → LemOrdering)
    (l : List (α × β)) : Fmap α β :=
  l.foldl (fun acc (k, v) => fmapAddBy cmp k v acc) fmapEmpty

/-! ## Helpers -/

/-- Read all input files' contents. Multi-TU: one cabs-json per
    translation unit, in command-line order — mirroring the OCaml
    driver's `files` list (backend/driver/main.ml:153-156, the per-file
    frontend fold). `--stdin` remains single-TU. -/
def readInputs (args : List String) : IO (List String) := do
  match args with
  | ["--stdin"] => do
    let mut buf := ""
    let mut done_ := false
    while !done_ do
      let line ← (← IO.getStdin).getLine
      if line.isEmpty then done_ := true
      else buf := buf ++ line
    return [buf]
  | [] => throw (IO.Error.userError "usage: cerberus-lean [--batch] [--stdin | FILE.json ...]")
  | files =>
    if files.contains "--stdin" then
      throw (IO.Error.userError "--stdin cannot be combined with file arguments")
    else
      files.mapM (fun f => IO.FS.readFile ⟨f⟩)

def countDecls : List external_declaration → Nat × Nat × Nat
  | [] => (0, 0, 0)
  | d :: ds =>
    let (funcs, decls, other) := countDecls ds
    match d with
    | .EDecl_func _ => (funcs + 1, decls, other)
    | .EDecl_decl _ => (funcs, decls + 1, other)
    | _ => (funcs, decls, other + 1)

def selfTest : IO Unit := do
  IO.println "cerberus-lean: loaded"
  match CerberusImpl.sizeof_ity (Signed Int_) with
  | some n => IO.println s!"  sizeof(int) = {n}"
  | none => IO.println "  sizeof(int) = unknown"
  let maxInt := CerbMem.maxIval (Signed Int_)
  let (.IV _ maxN) := maxInt
  IO.println s!"  max(signed int) = {maxN}"
  let minInt := CerbMem.minIval (Signed Int_)
  let (.IV _ minN) := minInt
  IO.println s!"  min(signed int) = {minN}"
  let bytes := CerbMem.intToBytes true 42 4
  let byteStrs := bytes.map fun b => match b with
    | some v => toString v.toNat | none => "?"
  IO.println s!"  intToBytes(42, 4) = {byteStrs}"
  IO.println "  ready"

/-! ## Batch output (differential harness support)

Machine-parseable output mode matching the OCaml driver's `--batch` format
(`backend/common/driver_ocaml.ml`, `string_of_batch_output`), which is also
the format the prototype's `test_interp.sh` parses:

  Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
  Undefined {ub: "UB045a_division_by_zero", stderr: "", loc: "..."}
  Error {msg: "..."}

Multiple executions get `EXECUTION i:` header lines, like OCaml.
The `loc:` field is `CerbLocation.simpleLocation` (= `Cerb_location.
simple_location`, driver_ocaml.ml:113/127), the `stderr:` field of an
Undefined line is the KILLED state's accumulated stderr (batch_drive,
driver_ocaml.ml:173-181) and the stdout/stderr fields are `String.escaped`
(batchEscape) — all byte-for-byte with the oracle since the zero-discrepancy
arc (Z-03, Z-72, Z2-P-01; UB location is behaviour [USER 2026-09-03]).
Deviations from OCaml (hand-written latitude, documented):
  - Unspecified/OtherValue payloads print via the arc-10 S3 REAL mirrors of
    String_core.string_of_value (CerbPP.stringFromCore_value; residual
    divergences are enumerated in CerbPP.lean and stay "<...>"-bracketed)
  - the oracle also prints `Time spent: %f seconds` on the TOOL's stderr
    (main.ml:159-160) — not behaviour, not mirrored (zero-discrepancy
    Z2-P-08; every lane filters `^Time spent`)
  - non-UB frontend failures emit an `Error {msg: ...}` line on stdout
    (OCaml puts them on stderr only); fail-closed either way
  - runND returning zero executions emits `Error {msg: "cerberus-lean:
    runND returned no executions"}` + exit 1 where OCaml prints nothing and
    exits 0. DECLARED loud boundary — zero-discrepancy Z-73, RULED
    [USER 2026-09-03] Q8 = A ("Agree re Q2-10"): keep the fail-closed
    refusal (a silent exit 0 with no verdict is the fail-open shape the
    working practices ban); the oracle's silent success is an upstream
    question (tray candidate). The fuel arc's `runNDFuel` exhaustion leaf
    has the same shape and inherits this classification. Also declared in
    VALIDATION.md ("Known, LOUD limits of the Lean driver"). -/

/-- OCaml `String.escaped` = `Bytes.unsafe_escape` (the switch's
    `lib/ocaml/bytes.ml:170-212`), by BYTE class: `"` `\\` `\n` `\t` `\r` `\b`
    → the two-character short form; `' ' .. '~'` (32..126) verbatim; every
    other byte → `\ddd`, three DECIMAL digits (`48 + a/100`, `48 + (a/10)
    mod 10`, `48 + a mod 10`). The driver's io strings hold one Char per
    program BYTE (0..255), so the char code IS the byte; the result is pure
    ASCII, hence no UTF-8 re-encoding of bytes >= 0x80 can occur. Zero-
    discrepancy Z2-P-01: the previous subset passed control bytes raw,
    dropped `\b`, and re-encoded 0xC3 0xA9 as four UTF-8 bytes
    (tests/immaculate/libc/zd-z2p01-{stdout,stderr}_escape.c). -/
def batchEscape (s : String) : String :=
  s.foldl (fun acc c =>
    let a := c.toNat
    acc ++ (if c == '"' || c == '\\' then "\\" ++ String.singleton c
      else if c == '\n' then "\\n"
      else if c == '\t' then "\\t"
      else if c == '\r' then "\\r"
      else if a == 8 then "\\b"
      else if 32 ≤ a && a ≤ 126 then String.singleton c
      else "\\" ++ String.singleton (Char.ofNat (48 + a / 100))
                ++ String.singleton (Char.ofNat (48 + (a / 10) % 10))
                ++ String.singleton (Char.ofNat (48 + a % 10)))) ""

/-- Batch rendering of the final core value — mirrors OCaml's exit
    selection in batch_drive (driver_ocaml.ml:162-171) composed with
    string_of_batch_exit (driver_ocaml.ml:42-52), which re-wraps the exit
    and prints it with String_core.string_of_value (= Pp_core.pp_value):
    * Specified-integer: case_integer_value → `Specified n` →
      re-wrapped via Impl_mem.integer_ival n (provenance ERASED) →
      pp "Specified(<n>)" — hence the explicit branch here (a direct
      pp of the original value would leak provenance at debug ≥ 3).
    * everything else round-trips to pp_value of the value itself
      (Unspecified included: "Unspecified('<ctype>')", pp_core.ml:304-308). -/
def batchExitValue (v : value) : String :=
  match v with
  | Vloaded (LVspecified (OVinteger ival)) =>
    match eval_integer_value ival with
    | some n => s!"Specified({n})"
    | none => CerbPP.stringFromCore_value v  -- OtherValue arm (driver_ocaml.ml:167)
  | v => CerbPP.stringFromCore_value v

/-- Batch rendering of a driver error — mirrors driver_ocaml.ml:22-30
    (string_of_driver_error). The DErr_memory arm uses the lem-generated
    Show instance for mem_error (driver_ocaml.ml:25-26 calls
    `Mem_common.instance_Show_Show_Mem_common_mem_error_dict.show_method`;
    `Lem_Show.show0` is the same generated method here) so `Error {msg:}`
    lines agree textually with the oracle (arc-14 S1 F1: the previous
    hand-rolled "memory error" summaries were an undocumented divergence,
    visible on the G1 relational kill-paths).
    The DErr_core_run arm mirrors `Pp_errors.string_of_core_run_cause`
    (pp_errors.ml:499-509) text for text (zero-discrepancy Z2-P-05; the
    previous local `Illformed_program: …` renderings were an EXC(a)
    divergence, closed): the four constant strings, and `Unresolved_symbol`
    as `"unresolved symbol: " ^ Pp_ail.pp_id sym ^ " at " ^
    Cerb_location.location_to_string loc` — `pp_id` is
    `Pp_symbol.to_string_pretty` (pp_ail.ml:96; `CerbMem.ppSymbol` is its
    mirror) and `location_to_string` is `CerbLocation.stringFromLocation`.
    The embedded symbol NUMBER inside an Illformed_program payload differs
    by construction (the two supplies' absolute numbering — Z-04/tray 17,
    EXC(a) text). -/
def driverErrorBatchMsg : driver_error → String
  | .DErr_core_run cause =>
    match cause with
    | .Illformed_program s => s!"ill-formed program: `{s}'"        -- pp_errors.ml:500-501
    | .Found_empty_stack s => s!"found an empty stack: `{s}'"      -- :502-503
    | .Reached_end_of_proc => "reached the end of a procedure"     -- :504-505
    | .Unknown_impl => "unknown implementation constant"           -- :506-507
    | .Unresolved_symbol loc sym =>
      s!"unresolved symbol: {CerbMem.ppSymbol sym} at {CerbLocation.stringFromLocation loc}"  -- :508-509
  | .DErr_memory merr => Lem_Show.show0 merr    -- driver_ocaml.ml:25-26
  | .DErr_concurrency s => s!"Concurrency error: {s}"
  | .DErr_other s => s

/-! ## Elaborated-Core signature dump (`--pp-core`, arc-4 S4)

LIMITATION — SIGNATURE-LEVEL ONLY, deliberately. The Lean pipeline has no
real Core EXPRESSION pretty-printer (arc-10 S3 gave CerbPP real
value/ctype/mem-value printer mirrors, but the expression/statement
printers remain among its 25 enumerated placeholders and the generated
Pp.lean is a stub), and building one is explicitly out of scope for this slice
(charter S4: stage differential at whatever granularity is available
WITHOUT building a printer). So `--pp-core` emits a canonical
SIGNATURE-level dump of the translated Core file:

  tagdef struct <name> members=<m1,m2,...>
  tagdef union <name> members=<...>
  glob <name>                      (GlobalDef only — OCaml pp skips GlobalDecl)
  fun <name> arity=<n>
  proc <name> arity=<n>
  procdecl <name> arity=<n>
  builtin <name> arity=<n>

`scripts/test_elab.sh` extracts the same facts from OCaml
`cerberus --nolibc --pp core` output and diffs the two through
`canonicalize_ids.py`. Function/glob BODIES are NOT compared — a
body-level Core differential needs a Lean Core pretty-printer (recorded
as a next-arc item in the S4b scoreboard doc). -/

/-- Mirror of OCaml `Pp_symbol.to_string_pretty` at debug level ≤ 4
    (ocaml_frontend/pprinters/pp_symbol.ml:12-35), which is what
    `--pp core` uses for every symbol we dump. -/
def ppSymbolPretty : sym → String
  | Symbol _ n sd =>
    match sd with
    | .SD_Id str | .SD_ObjectAddress str | .SD_FunArgValue str => str
    | .SD_unnamed_tag _ => s!"__cerbty_unnamed_tag_{n}"
    | .SD_CN_Id str => str
    | _ => s!"a_{n}"

/-- Signature-level dump of the translated Core file (see module note
    above). Mirrors WHAT OCaml `pp_core.pp_file` prints (incl. appending
    a flexible array member as an ordinary member,
    pp_core.ml:755-760, and skipping GlobalDecl, pp_core.ml:832-841) but
    at declaration granularity only. -/
def ppCoreSignature (coreFile : file Unit) : IO Unit := do
  let identName : identifier → String
    | Identifier _ s => s
  for (s, (_loc, td)) in fmapElements coreFile.tagDefs do
    match td with
    | StructDef membrs flexOpt =>
      let names := membrs.map (fun (i, _) => identName i)
      let names := match flexOpt with
        | some (FlexibleArrayMember _ i _ _) => names ++ [identName i]
        | none => names
      IO.println s!"tagdef struct {ppSymbolPretty s} members={String.intercalate "," names}"
    | UnionDef membrs =>
      let names := membrs.map (fun (i, _) => identName i)
      IO.println s!"tagdef union {ppSymbolPretty s} members={String.intercalate "," names}"
  for (s, g) in coreFile.globs do
    match g with
    | GlobalDef _ _ => IO.println s!"glob {ppSymbolPretty s}"
    | GlobalDecl _ => pure ()   -- OCaml pp_globs prints nothing for these
  for (s, d) in fmapElements coreFile.funs do
    match d with
    | Fun _ params _ => IO.println s!"fun {ppSymbolPretty s} arity={params.length}"
    | Proc _ _ _ params _ => IO.println s!"proc {ppSymbolPretty s} arity={params.length}"
    | ProcDecl _ _ tys => IO.println s!"procdecl {ppSymbolPretty s} arity={tys.length}"
    | BuiltinDecl _ _ tys => IO.println s!"builtin {ppSymbolPretty s} arity={tys.length}"

/-! ## Pipeline -/

def findRuntimeDir : IO String := do
  -- Check common locations
  let candidates := [
    "runtime/libcore",        -- from project root
    "../runtime/libcore",     -- from lean_frontend
    "../../runtime/libcore"   -- from deeper
  ]
  for dir in candidates do
    if ← System.FilePath.pathExists (dir ++ "/std.core") then
      return dir
  throw (IO.Error.userError "cannot find runtime/libcore/std.core — set working directory to project root")

/-- Per-TU frontend: desugar → typecheck → translate, under the TU's own
    digest (set by the caller). Mirror of the OCaml per-file frontend
    (`c_frontend` pipeline.ml:180-247 + `c_frontend_and_elaboration`
    pipeline.ml:249-260), factored out of `runPipeline` for the multi-TU
    loop (arc-5 S2). Returns `.error exitCode` on a stage failure (the
    historical exit-code behavior of each failure branch is preserved:
    batch mode 1, human mode 0).

    EVALUATION ORDER: every pure stage call goes through
    `CerberusFresh.forceIO` — the stages read the per-TU digest global
    internally (Symbol.fresh → `digest ()`), and a plain pure `let` here
    would be let-SUNK past the NEXT TU's `setDigestIO`, stamping this
    TU's symbols with the wrong digest (see CerberusFresh.forceIO and
    test/Unit/FreshIntTest.lean testDigestGlobal). -/
def frontendTU [LemFuel] (quiet : Bool) (supply : Nat)
    (coreEvalStuff : Fmap String sym × fun_map Unit × impl)
    (ailnames : Fmap String sym) (stdFunMap : fun_map Unit) (coreImpl : impl)
    (tunit : translation_unit) : IO (Except UInt8 (file Unit × Nat)) := do
  let say (s : String) : IO Unit := unless quiet do IO.println s
  -- Desugar Cabs → AIL
  say "  desugaring Cabs → AIL..."
  let cnInit := empty_init
  -- Effect-retirement C1: `supply` is the pipeline's SINGLE fresh-symbol
  -- stream (S1 ruling) — threaded through desugar (incl. its const-expr
  -- mini-runs), elaboration, and back out to the caller.
  -- desugar/translate are reader-lifted since C1 (the reader_consumer
  -- mem-ops in their cones, mem.lem): the reader argument is the
  -- PHASE-APPROPRIATE tag table — EMPTY during desugar/typing/
  -- elaboration, mirroring the oracle's empty Tags global there
  -- (pipeline.ml:253 resets before translate; the union-arm asymmetry
  -- mirror, charter section 4.2 — the offsetof-union-member crash pair
  -- pins this). The mini-run's own extent still sees the translated
  -- definitions via the reader_seed run_const_expr_driver.
  let desugRes ← (CerberusFresh.forceIO
    (fun () => desugar fmapEmpty supply coreEvalStuff cnInit "main" tunit) : BaseIO _)
  match desugRes with
  | .Result (_, (mainSym, ailProg), supplyAfterDesugar) =>
    say s!"  desugaring succeeded!"
    say s!"    main symbol: {match mainSym with | some _ => "found" | none => "not found"}"
    say s!"    declarations: {List.length ailProg.declarations}"
    say s!"    function defs: {List.length ailProg.function_definitions}"
    say s!"    tag defs: {List.length ailProg.tag_definitions}"

    -- Step 2: Typecheck AIL (mirrors pipeline.ml:217-219)
    say "  typechecking AIL..."
    let ailInput := (mainSym, ailProg)
    let tyRes ← (CerberusFresh.forceIO (fun () =>
      to_exception (fun (p : CerbLocation.Loc × typing_error) => (p.1, AIL_TYPING p.2))
        (annotate_program ailInput)) : BaseIO _)
    match tyRes with
    | .Exception (loc, cause) =>
      if quiet then
        -- OCaml parity: typing-level UB gets a batch Undefined line (main.ml runM)
        match cause with
        | .AIL_TYPING (.TError_UndefinedBehaviour ub) =>
          -- main.ml:173-177: `Undefined { ub; stderr= ""; loc }` through string_of_batch_output
          IO.println s!"Undefined \{ub: \"{stringFromUndefined_behaviour ub}\", stderr: \"\", loc: \"{CerbLocation.simpleLocation loc}\"}"
        | _ =>
          IO.println s!"Error \{msg: \"typechecking failed at {CerbLocation.stringFromLocation loc}\"}"
        return .error 1
      else
        IO.println s!"  typechecking failed!"
        IO.println s!"    at: {CerbLocation.stringFromLocation loc}"
        return .error 0
    | .Result (typedProg, _annots) =>
      say s!"  typechecking succeeded!"

      -- Step 3: Translate AIL → Core
      say "  translating AIL → Core..."
      -- C1: the per-TU CerbTags reset (pipeline.ml:253 mirror) is GONE —
      -- there is no global to reset; translate's reader argument below is
      -- the empty table, which IS the oracle's reset-then-elaborate state
      -- (documented divergence from the driver-level bookkeeping, mirror
      -- doctrine; the value-passing replaces the write scaffold).
      let callconv := Normal_callconv
      let (coreFile, supplyAfterTranslate) ← (CerberusFresh.forceIO (fun () =>
        translate fmapEmpty supplyAfterDesugar (ailnames, stdFunMap) callconv coreImpl typedProg) : BaseIO _)
      say s!"  translation succeeded!"
      say s!"    main: {match coreFile.main with | some _ => "found" | none => "not found"}"
      say s!"    funs: {List.length (fmapElements coreFile.funs)}"
      say s!"    globs: {List.length coreFile.globs}"
      return .ok (coreFile, supplyAfterTranslate)
  | .Exception (loc, cause) =>
    if quiet then
      -- OCaml parity (main.ml runM): desugar-level UB gets a batch Undefined line
      match cause with
      | .DESUGAR (.Desugar_UndefinedBehaviour ub) =>
        -- main.ml:166-170: `Undefined { ub; stderr= ""; loc }` through string_of_batch_output
        IO.println s!"Undefined \{ub: \"{stringFromUndefined_behaviour ub}\", stderr: \"\", loc: \"{CerbLocation.simpleLocation loc}\"}"
      | _ =>
        IO.println s!"Error \{msg: \"desugaring failed at {CerbLocation.stringFromLocation loc}\"}"
      return .error 1
    else
      IO.println s!"  desugaring failed!"
      IO.println s!"    at: {CerbLocation.stringFromLocation loc}"
      -- Print cause details
      match cause with
      | .DESUGAR (.Desugar_ConstraintViolation v) => IO.println s!"    cause: DESUGAR ConstraintViolation"
      | .DESUGAR (.Desugar_UndefinedBehaviour ub) =>
        IO.println s!"    cause: DESUGAR UndefinedBehaviour: {stringFromUndefined_behaviour ub}"
      | .DESUGAR (.Desugar_MiscViolation _) => IO.println s!"    cause: DESUGAR MiscViolation"
      | .DESUGAR (.Desugar_NotYetSupported s) => IO.println s!"    cause: DESUGAR NotYetSupported: {s}"
      | .DESUGAR (.Desugar_NeverSupported s) => IO.println s!"    cause: DESUGAR NeverSupported: {s}"
      | .DESUGAR (.Desugar_agnosticFailure s) => IO.println s!"    cause: DESUGAR agnosticFailure: {s}"
      | .DESUGAR .Desugar_illtypedIntegerConstant => IO.println s!"    cause: DESUGAR illtypedIntegerConstant"
      | .DESUGAR (.Desugar_TODO s) => IO.println s!"    cause: DESUGAR TODO: {s}"
      | .DESUGAR _ => IO.println s!"    cause: DESUGAR (other)"
      | .AIL_TYPING _ => IO.println s!"    cause: AIL_TYPING"
      | .CPP _ => IO.println s!"    cause: CPP"
      | _ => IO.println s!"    cause: (other)"
      return .error 0

/-- Load and assemble the libc library Core file (see the module note at
    "C-libc loading" above). -/
def loadLibc [LemFuel] (quiet : Bool) (supply0 : Nat)
    (coreEvalStuff : Fmap String sym × fun_map Unit × impl)
    (ailnames : Fmap String sym) (stdFunMap : fun_map Unit) (coreImpl : impl)
    (libcCorePath : String) (libcTuJsons : List String) :
    IO (Except UInt8 (file Unit × Nat)) := do
  let say (s : String) : IO Unit := unless quiet do IO.println s
  let bail (msg : String) : IO (Except UInt8 (file Unit × Nat)) := do
    if quiet then IO.println s!"Error \{msg: \"libc load failed: {batchEscape msg}\"}"
    else IO.println s!"  libc load failed: {msg}"
    return .error 1
  -- 1. Parse the pinned dump (bodies). The TU digest is the real MD5 of
  --    the pinned file (arc-5 per-TU digest machinery; CoreParser's
  --    interning is digest-independent, so this is provenance-recording).
  say s!"  loading libc bodies from {libcCorePath}..."
  let dumpContent ← IO.FS.readFile ⟨libcCorePath⟩
  let _ ← (CerberusFresh.setDigestIO (CerberusFresh.md5Hex dumpContent) : BaseIO Unit)
  let parsed ← match CoreParser.parseFile dumpContent with
    | .ok f => pure f
    | .error e => return (← bail s!"parsing {libcCorePath}: {e}")
  say s!"    {parsed.procs.length} proc, {parsed.funs.length} fun, {parsed.globs.length} glob"
  -- 2. Frontend the 12 metadata TUs (same order as runtime/libc/dune's
  --    libc.co link; reverse-consed accumulator exactly as the OCaml
  --    driver fold, main.ml:153-156) and link them. Zero-discrepancy Z3
  --    (Z-28): each TU runs under the digest its cabs-json carries — the
  --    oracle's `Digest.file` of the libc SOURCE (main.ml --cabs-json path
  --    = pipeline.ml:181 c_frontend), i.e. the digest the same source's
  --    symbols carry inside libc.co (runtime/libc/dune:145-146 builds it
  --    from these sources through the same c_frontend).
  say s!"  loading libc metadata from {libcTuJsons.length} TUs..."
  let mut metaFiles : List (file Unit) := []
  let mut supply := supply0
  for j in libcTuJsons do
    let content ← IO.FS.readFile ⟨j⟩
    let (digest, tunit) ← match CabsImport.parseJson content with
      | .ok t => pure t
      | .error e => return (← bail s!"cabs-json parse error in {j}: {e}")
    let _ ← (CerberusFresh.setDigestIO digest : BaseIO Unit)
    match ← frontendTU true supply coreEvalStuff ailnames stdFunMap coreImpl tunit with
    | .error _ => return (← bail s!"frontend failed for libc metadata TU {j}")
    | .ok (f, supply') => metaFiles := f :: metaFiles; supply := supply'
  let metaFile ← match link metaFiles with
    | .Result f => pure f
    | .Exception (_, _) => return (← bail "linking the libc metadata TUs failed")
  -- 3. THE STITCH (module note): rename the dump onto the metadata
  --    symbols — tags by name, functions by name, globals by position —
  --    every join fail-closed.
  let stitched : Except String (CoreParser.CoreFile × List (sym × generic_globs Unit Unit)
      × Fmap sym (CerbLocation.Loc × tag_definition)
      × Fmap sym (CerbLocation.Loc × attributes × ctype × List (Option sym × ctype) × Bool × Bool)) := do
    -- (a) tags
    let mut tagMap : Std.HashMap String sym := {}
    let mut tagDefByName : Std.HashMap String tag_definition := {}
    for (s, (_, td)) in fmapElements metaFile.tagDefs do
      let name ← match libcSymNameOpt s with
        | some n => pure n
        | none => throw s!"libc metadata tag symbol without a printable name: {libcSymName s} (cannot name-join)"
      match tagDefByName[name]? with
      | none =>
        tagMap := tagMap.insert name s
        tagDefByName := tagDefByName.insert name td
      | some td' =>
        unless libcTagDefEq td' td do
          throw s!"libc metadata name-join collision with disagreeing content: tagDef '{name}'"
    -- (a') ONE tag symbol per name, on BOTH halves. The run-time
    --     compatibility check (`AilTypesAux.are_compatible`,
    --     ailTypesAux.lem:830-837, reached from every elaborated call through
    --     `PEare_compatible`, core_eval.lem:1090-1099) requires struct/union
    --     tag SYMBOLS to be equal; the oracle satisfies it because a call
    --     site is checked against the CALLER TU's own declaration entry of the
    --     callee (`cfunction` reads funinfo on the pointer's symbol,
    --     core_eval.lem:906, before the extern remap) — both sides carry that
    --     TU's tags. The dump's bodies cannot say which TU they came from, so
    --     their tag references join onto one representative per name; the
    --     metadata's funinfo ctypes, tagDefs (keys and members) and decl-globs
    --     ctypes are moved onto the SAME representative here, so the frame is
    --     consistent — the one-tag-per-name frame of the pre-Z3 loader, now
    --     under a real (digest, number) symbol. Same-name definitions were
    --     checked structurally equal in (a), so every collapsed tagDef is the
    --     same layout. Program↔libc calls are unaffected (the program's own
    --     declaration entry carries its own tags on both sides).
    let metaTagCtx : CoreParser.RenameCtx :=
      { onSym := id
        onTag := fun s => match libcSymNameOpt s with
          | some n => (tagMap[n]?).getD s
          | none => s }
    let mut tagDefs : List (sym × (CerbLocation.Loc × tag_definition)) := []
    for (s, (loc, td)) in fmapElements metaFile.tagDefs do
      let k := metaTagCtx.onTag s
      unless tagDefs.any (fun kv => libcSymEq kv.1 k) do
        tagDefs := tagDefs ++ [(k, (loc, CoreParser.renameTagDef metaTagCtx td))]
    let funinfo := (fmapElements metaFile.funinfo).map fun (s, (loc, attrs, ret, params, v, pr)) =>
      (s, (loc, attrs, CoreParser.renameCtype metaTagCtx ret,
        params.map (fun (n, t) => (n, CoreParser.renameCtype metaTagCtx t)), v, pr))
    -- (b) functions: the definition's symbol wins over declaration-only
    --     entries; among definitions the first in symbol order
    let mut funMap : Std.HashMap String (sym × Bool) := {}
    for (s, d) in fmapElements metaFile.funs do
      let name ← match libcSymNameOpt s with
        | some n => pure n
        | none => throw s!"libc metadata function symbol without a printable name: {libcSymName s} (cannot name-join)"
      let isDef := match d with
        | Proc _ _ _ _ _ | Fun _ _ _ => true
        | ProcDecl _ _ _ | BuiltinDecl _ _ _ => false
      match funMap[name]? with
      | none => funMap := funMap.insert name (s, isDef)
      | some (_, true) => pure ()
      | some (_, false) => if isDef then funMap := funMap.insert name (s, true)
    -- (c) globals, by position over the DEFINITIONS: the dump prints only
    --     GlobalDef entries (pp_globs skips GlobalDecl, pp_core.ml:840-841)
    --     while libc.co — and the linked metadata — also carry the
    --     declaration-only globals, which the driver skips at allocation
    --     (driver.lem:1581) but merge_globs still sorts. The metadata's list
    --     is therefore the libc file's globs (decls included, as in libc.co)
    --     and its GlobalDef subsequence must equal the dump's list.
    let metaDefs := metaFile.globs.filter fun (_, g) => match g with
      | GlobalDef _ _ => true
      | GlobalDecl _ => false
    unless parsed.globs.length == metaDefs.length do
      throw s!"libc stitch: the dump has {parsed.globs.length} global definitions but the linked metadata has {metaDefs.length} (of {metaFile.globs.length} entries) — the two link orders cannot be joined"
    let mut globMap : Std.HashMap String sym := {}
    for (ms, _) in metaFile.globs.filter (fun (_, g) => match g with | GlobalDecl _ => true | _ => false) do
      -- declaration-only entries: one per TU that declares a header
      -- extern (`extern FILE *const __stdout;` in every stdio.h includer),
      -- never in the dump. Bodies that mention the name join onto the
      -- DEFINITION's symbol when libc defines it (below, the definition
      -- overwrites); a name libc only declares joins onto the first
      -- declaration in symbol order — the oracle resolves it through the
      -- extern map to the same target either way.
      match libcSymNameOpt ms with
      | some n => unless globMap.contains n do globMap := globMap.insert n ms
      | none => throw s!"libc stitch: unnamed declaration-only global {libcSymName ms}"
    let mut defNames : Std.HashMap String Unit := {}
    let mut i := 0
    for ((ds, dg), (ms, mg)) in List.zip parsed.globs metaDefs do
      let dname := libcSymName ds
      let dcty := match dg with
        | GlobalDef (_, ct) _ => some ct
        | GlobalDecl _ => none
      let mcty := match mg with
        | GlobalDef (_, ct) _ => some ct
        | GlobalDecl _ => none
      match dcty, mcty with
      | some dct, some mct =>
        unless ctypeEqual (CoreParser.renameCtype libcByNameCtx dct)
            (CoreParser.renameCtype libcByNameCtx mct) do
          throw s!"libc stitch: global definition #{i} '{dname}': the dump's ail ctype differs from the metadata's"
      | _, _ => throw s!"libc stitch: global #{i} '{dname}' is a declaration in the dump (the pp never prints one)"
      match ms with
      | Symbol _ _ (SD_ObjectAddress n) | Symbol _ _ (SD_Id n) =>
        unless n == dname do
          throw s!"libc stitch: global definition #{i} is '{dname}' in the dump but '{n}' in the metadata — the two link orders disagree (the metadata's merge_globs order must equal libc.co's)"
      | Symbol _ n SD_None =>
        unless libcIsUnnamedName dname do
          throw s!"libc stitch: global definition #{i} is '{dname}' in the dump but the unnamed a_{n} in the metadata — the two link orders disagree"
      | _ => throw s!"libc stitch: global definition #{i} '{dname}': unexpected metadata symbol description {libcSymName ms}"
      if defNames.contains dname then
        throw s!"libc stitch: global '{dname}' is defined twice (a static in two TUs) — name-interning cannot keep the two apart"
      defNames := defNames.insert dname ()
      globMap := globMap.insert dname ms   -- a definition wins over its declarations
      i := i + 1
    -- (d) the linker's own resolution must agree with the joins
    for (ident, (_, lk)) in fmapElements metaFile.extern do
      let target := match lk with
        | LK_normal d | LK_tentative d => some d
        | LK_none => none
      match target with
      | none => pure ()
      | some d =>
        let name ← match libcSymNameOpt d with
          | some n => pure n
          | none => throw s!"libc stitch: extern '{identName ident}' resolves to an unnamed symbol"
        let joined := match globMap[name]? with
          | some s => some s
          | none => funMap[name]?.map Prod.fst
        match joined with
        | some s =>
          unless libcSymEq s d do
            throw s!"libc stitch: extern '{identName ident}' resolves to a symbol other than the stitched '{name}'"
        | none =>
          throw s!"libc stitch: extern '{identName ident}' resolves to '{name}', which the dump does not define"
    -- (e) rename
    let ctx : CoreParser.RenameCtx :=
      { onSym := fun s => match libcSymNameOpt s with
          | some n => match globMap[n]? with
            | some s' => s'
            | none => match funMap[n]? with
              | some (s', _) => s'
              | none => s
          | none => s
        onTag := fun s => match libcSymNameOpt s with
          | some n => (tagMap[n]?).getD s
          | none => s }
    let renamed := CoreParser.renameFile ctx parsed
    -- (f) the dump's surviving tagDefs (struct fl) must agree with the
    --     metadata's — fail-closed consistency between the two halves
    for (s, (_, td)) in renamed.tagDefs do
      match tagDefs.find? (fun kv => libcSymEq kv.1 s) with
      | none => throw s!"dump tagDef '{libcSymName s}' missing from metadata"
      | some (_, (_, td')) =>
        unless libcTagDefEq td td' do
          throw s!"dump tagDef '{libcSymName s}' disagrees with metadata"
    -- (g) the libc globs: the metadata's list (libc.co's order, decls
    --     included), each definition's body taken from the renamed dump
    --     under the now-shared symbol
    let mut globs : List (sym × generic_globs Unit Unit) := []
    for (ms, mg) in metaFile.globs do
      match mg with
      | GlobalDecl (bty, ct) => globs := globs ++ [(ms, GlobalDecl (bty, CoreParser.renameCtype metaTagCtx ct))]
      | GlobalDef _ _ =>
        match renamed.globs.find? (fun kv => libcSymEq kv.1 ms) with
        | some (_, g) => globs := globs ++ [(ms, g)]
        | none => throw s!"libc stitch: no dump body for global definition '{libcSymName ms}' after renaming"
    pure (renamed, globs, libcMapFromAssoc libcSymMapCmp tagDefs, libcMapFromAssoc libcSymMapCmp funinfo)
  let (renamed, globs, tagDefs, funinfo) ← match stitched with
    | .ok f => pure f
    | .error e => return (← bail e)
  -- 4. Fun map from the renamed dump. Proc definitions win over ProcDecl
  --    entries for the same symbol (the pp emits both for names declared
  --    in one TU and defined in another — __strtox/__strtoxd; only a
  --    Proc body satisfies call_proc, core_run.lem:46-51). Duplicate
  --    Proc definitions (static __procfdname in two TUs) keep the first.
  let mut funs : List (sym × generic_fun_map_decl Unit Unit) := []
  for (s, d) in renamed.funs ++ renamed.procs ++ renamed.builtins do
    match funs.find? (fun kv => libcSymEq kv.1 s) with
    | none => funs := funs ++ [(s, d)]
    | some (_, existing) =>
      match existing, d with
      | ProcDecl _ _ _, Proc _ _ _ _ _ =>
        funs := funs.map (fun kv => if libcSymEq kv.1 s then (kv.1, d) else kv)
      | _, _ => pure ()
  say s!"    metadata: {(fmapElements tagDefs).length} tagDefs, {(fmapElements metaFile.extern).length} extern, {(fmapElements funinfo).length} funinfo"
  -- 5. Assemble (read_core_object mirror, pipeline.ml:655-663).
  return .ok ({
    main := none
    calling_convention0 := metaFile.calling_convention0
    tagDefs := tagDefs
    stdlib := stdFunMap
    impl0 := coreImpl
    globs := globs
    funs := libcMapFromAssoc libcSymMapCmp funs
    extern := metaFile.extern
    funinfo := funinfo
    loop_attributes1 := fmapEmpty
    visible_objects_env0 := fmapEmpty
  }, supply)


/-- Run the pipeline over one or more translation units (multi-TU, arc-5
    S2). `tunits` carries (source digest, parsed Cabs) per TU in
    command-line order — the digest is the oracle's `Digest.file` the
    cabs-json carries (CabsImport.parseJson; zero-discrepancy Z3). Per TU: set the TU digest, then
    desugar→typecheck→translate (`frontendTU`); the resulting Core files
    are linked with the generated `Core_linking.link` exactly as the
    OCaml driver does (backend/driver/main.ml:278-281), tag definitions
    are taken from the LINKED file (main.ml:284-285), and execution
    proceeds as before. Single-TU behavior is byte-identical: the chatter
    order is preserved and `link [f]` folds over the empty tail,
    returning `f` unchanged (core_linking.lem:309-316).

    `batch` selects machine-parseable output (see above); `ppCore` stops
    after linking and dumps the signature-level Core summary (see
    `ppCoreSignature`); the default human-readable mode is unchanged (and
    keeps its historical exit-code behavior: 0 even on semantic stage
    failures). -/
def runPipeline [LemFuel] (runtimeDir : String) (batch : Bool) (ppCore : Bool)
    (firstTrace : Bool)
    (callFn : Option (String × List Int)) (traceNodes : Bool)
    (libc : Option (String × List String))
    (progArgs : List String)
    (tunits : List (String × translation_unit)) : IO UInt8 := do
  -- Progress chatter: human mode only (batch and pp-core keep stdout clean)
  let quiet := batch || ppCore
  let say (s : String) : IO Unit := unless quiet do IO.println s
  -- Per-TU parse summary — kept ABOVE the stdlib load so single-TU chatter
  -- stays byte-identical to the pre-multi-TU driver
  for (_, tunit) in tunits do
    let (TUnit decls) := tunit
    let (funcs, declCount, other) := countDecls decls
    say s!"cerberus-lean: parsed {List.length decls} external declarations"
    say s!"  functions: {funcs}, declarations: {declCount}, other: {other}"

  -- Load core stdlib (once, before any TU digest is set — std.core symbols
  -- are interned with digest "" by CoreParser.mkSym, matching OCaml where
  -- the prelude parse happens before any Cerb_fresh.set_digest)
  say "  loading core stdlib..."
  -- Z-01: the library file is stamped with its path so that
  -- CerbLocation.isLibraryLocation holds for its nodes (pipeline.ml:29-34
  -- loads `in_runtime "libcore" / std.core`; core_parser.mly:1571 regions)
  let stdCorePath := runtimeDir ++ "/std.core"
  let stdContent ← IO.FS.readFile stdCorePath
  let stdFile ← match CoreParser.parseLibraryFile stdCorePath stdContent with
    | .ok f => pure f
    | .error e => throw (IO.Error.userError s!"failed to parse std.core: {e}")
  let allStdDecls := stdFile.funs ++ stdFile.procs ++ stdFile.builtins
  say s!"    raw: {stdFile.funs.length} fun, {stdFile.procs.length} proc, {stdFile.builtins.length} builtin = {allStdDecls.length} total"
  let allStd := stdFile.funs ++ stdFile.procs ++ stdFile.builtins
  let (ailnames, stdFunMap) := loadCoreStdlib stdFile
  say s!"    ailnames: {List.length (fmapElements ailnames)} entries"
  say s!"    stdlib funs: {List.length (fmapElements stdFunMap)} entries"

  -- Load implementation file
  say "  loading implementation..."
  -- pipeline.ml:47 `impls/<impl>.impl` under the same runtime tree (Z-01)
  let implPath := runtimeDir ++ "/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl"
  let implContent ← IO.FS.readFile implPath
  let implFile ← match CoreParser.parseLibraryFile implPath implContent with
    | .ok f => pure f
    | .error e => throw (IO.Error.userError s!"failed to parse impl file: {e}")
  let coreImpl := loadCoreImpl implFile
  say s!"    impl constants: {List.length (fmapElements coreImpl)} entries"

  -- Build the implementation
  say "  building implementation..."
  let coreEvalStuff : Fmap String sym × fun_map Unit × impl :=
    (ailnames, stdFunMap, coreImpl)

  -- Per-TU frontend fold — mirror of backend/driver/main.ml:153-156:
  --   except_foldlM (fun core_files (is_lib, file) ->
  --     frontend ... file core_std >>= fun core_file ->
  --     return (core_file::core_files)) [] ... files
  -- The accumulator is REVERSE-consed (first file ends up LAST) and is
  -- handed to Core_linking.link as-is — mirrored exactly here. Failures
  -- short-circuit in file order, like except_foldlM.
  --
  -- --libc: the libc library file is processed FIRST, before the user
  -- TUs, exactly as the OCaml driver folds `core_libraries … @ files`
  -- (main.ml:150-156) — so it ends up LAST in the reverse-consed list
  -- handed to Core_linking.link, mirroring the oracle's link order.
  let mut coreFiles : List (file Unit) := []
  -- Effect-retirement C1 (S1 ruling [USER 2026-08-31]): the ONE
  -- fresh-symbol stream, seeded here and threaded through every phase
  -- (per-TU desugar + const-expr mini-runs + elaboration) and into the
  -- run-init seed below — collisions impossible by construction; the
  -- former 2^20 desugar/ambient stratification is gone.
  let mut supply : Nat := 0
  match libc with
  | some (libcCore, libcTus) =>
    match ← loadLibc quiet supply coreEvalStuff ailnames stdFunMap coreImpl libcCore libcTus with
    | .error code => return code
    | .ok (libcFile, supply') => coreFiles := [libcFile]; supply := supply'
  | none => pure ()
  for (digest, tunit) in tunits do
    -- Per-TU digest, before the TU's frontend stages — mirror of
    -- `Cerb_fresh.set_digest filename` at the top of the OCaml c_frontend
    -- (backend/common/pipeline.ml:181; ref cell util/cerb_fresh.ml:7-10).
    -- The digest is the ORACLE'S: `Digest.file` of the C source, carried
    -- by the cabs-json (main.ml --cabs-json path; CabsImport.parseJson,
    -- fail-closed) — zero-discrepancy Z3 (Z-28): symbol digests order the
    -- linked globals (merge_globs), so the value itself is behaviour in
    -- libc mode. (Until Z3 this hashed the cabs-json text, a different
    -- value under which every program global sorted after the libc's.)
    -- Placement note: OCaml sets the digest before its C PARSE; our Cabs
    -- deserialization already happened in main — harmless, Cabs carries
    -- no Symbol.sym, so no symbol is created before the set.
    -- BaseIO variant: a discarded pure call is dead-code-eliminated
    -- (CerbTags set/reset pattern, arc-4 S3b).
    let _ ← (CerberusFresh.setDigestIO digest : BaseIO Unit)
    match ← frontendTU quiet supply coreEvalStuff ailnames stdFunMap coreImpl tunit with
    | .error code => return code
    | .ok (coreFile, supply') => coreFiles := coreFile :: coreFiles; supply := supply'

  -- Link the translated Core files — main.ml:278-281:
  --   prelude >>= main >>= begin function
  --     | [] -> assert false | f::fs -> Core_linking.link (f::fs) end
  -- link = List.foldl (link_aux) over the reverse-consed list
  -- (core_linking.lem:309-316; extern-map merge by identifier with
  -- tentative-definition resolution, link_extern core_linking.lem:10-46).
  -- The run-time cross-TU call remap `core_extern =
  -- Core_linking.create_extern_symmap file` (core_linking.lem:319-328) is
  -- already live in the generated driver (driver.lem:1512).
  match link coreFiles with
  | .Exception (loc, cause) =>
    let msg := match cause with
      | CORE_LINKING (DuplicateExternalName (Identifier _ str)) =>
        s!"linking failed: duplicate external name: {str}"
      | CORE_LINKING DuplicateMain => "linking failed: duplicate main"
      | CORE_LINKING IncompatibleCallingConvention =>
        "linking failed: incompatible calling convention"
      | _ => "linking failed"
    if quiet then
      -- deviation note (as for other frontend failures): OCaml prints
      -- linking errors via Pp_errors on stderr only (main.ml runM
      -- Exception branch); we emit a batch Error line on stdout —
      -- fail-closed either way, exit 1 both sides
      IO.println s!"Error \{msg: \"{msg} at {CerbLocation.stringFromLocation loc}\"}"
      return 1
    else
      IO.println s!"  linking failed!"
      IO.println s!"    at: {CerbLocation.stringFromLocation loc}"
      IO.println s!"    cause: {msg}"
      return 0
  | .Result coreFile =>
    -- chatter only for a real multi-TU link: single-file human-mode
    -- output stays byte-identical to the pre-multi-TU driver
    if tunits.length != 1 then
      say s!"  linking succeeded! ({tunits.length} translation units)"
    -- C1: the driver-level tag bookkeeping (main.ml:284-285
    -- reset+set from the LINKED file) is GONE — the load→seed loop is
    -- closed: the value in hand (runFile.tagDefs below) seeds the
    -- execution directly (documented divergence from the OCaml driver's
    -- global writes, mirror doctrine).

    -- --pp-core: signature-level dump of the (linked) Core, then stop
    -- (no execution). See the ppCoreSignature module note for the
    -- granularity limitation.
    if ppCore then
      ppCoreSignature coreFile
      return 0

    -- Step 4: Prepare for execution (mirrors driver_ocaml.ml)
    say "  preparing for execution..."
    let runFile := convert_file coreFile
    -- C1: CerbMem's struct/union layout reads receive runFile.tagDefs by
    -- VALUE (reader_consumer, mem.lem) — no global set is needed or
    -- possible.
    let fsState := CerbFS.fs_initial_state
    -- Entry shape (b), charter section 1.3: the supply-parameterized
    -- pure constructor — one draw (the run-init seed) from the stream.
    let (drSt, _supplyFinal) := initial_driver_state supply runFile fsState
    say s!"  executing Core..."
    -- Reader seed: execution-slice entry — the linked table, passed as
    -- the value in hand (the load→seed loop is closed).
    -- --call: run the designated function on the injected argument
    -- values via CerbCall.driveCall (drive with the startup symbol
    -- resolved by name + the caller protocol for the parameters)
    -- instead of drive's main-startup path.
    -- argv — pipeline.ml:598,602: ("cmdname" :: args) both batch and
    -- non-batch; progArgs is the parsed --args list (empty without the
    -- flag, so the historical ["cmdname"] argv is byte-unchanged).
    let driverAction := match callFn with
      | none => drive runFile.tagDefs false runFile ("cmdname" :: progArgs)
      | some (fname, argInts) =>
        CerbCall.driveCall runFile.tagDefs runFile fname
          (argInts.map CerbCall.intValue)
    -- --first (arc-5 S3): single-trace runner for programs whose exhaustive
    -- trace set is combinatorially large (libxml2-scale differentials);
    -- see CerbND.runND1 for the OCaml counterpart + divergence record.
    -- --trace-nodes (arc-7 S3): branch-0 single trace + ND-node labels on
    -- stdout (Step-coverage evidence instrument; see CerbND.runND1Trace).
    let (nodeLabels, execs) :=
      if traceNodes then
        CerbND.runND1Trace (fun (k : step_kind) => Lem_Show.show0 k)
          driverAction drSt
      else
        ([], if firstTrace then CerbND.runND1 driverAction drSt
             else CerbND.runND driverAction drSt)
    for l in nodeLabels do
      IO.println s!"NODE {l}"
    if batch then
      if execs.length == 0 then
        IO.println "Error {msg: \"cerberus-lean: runND returned no executions\"}"
        return 1
      let multiple := execs.length > 1
      let mut idx := 0
      for (status, _trace, _finalSt) in execs do
        if multiple then IO.println s!"EXECUTION {idx}:"
        match status with
        | .Active result =>
          IO.println s!"Defined \{value: \"{batchExitValue result.dres_core_value}\", stdout: \"{batchEscape result.dres_stdout}\", stderr: \"{batchEscape result.dres_stderr}\", blocked: \"{if result.dres_blocked then "true" else "false"}\"}"
        | .Killed st reason =>
          -- batch_drive (driver_ocaml.ml:173-181): every Killed arm carries
          -- `String.concat "" (Dlist.toList dr_st.core_state.io.stderr)` —
          -- the KILLED state's accumulated stderr; the plain batch printer
          -- renders it on the Undefined line only (:127 `String.escaped
          -- stderr`; the Error line :138 prints msg alone). Zero-discrepancy
          -- Z-72: this printed `stderr: ""` literally.
          let killedStderr := batchEscape
            (lemListFoldr String.append "" (toList st.core_state0.io.stderr))
          match reason with
          | .Undef0 _loc [] =>
            -- OCaml batch_drive parity: empty UB list is an Error
            IO.println "Error {msg: \"[empty UB, probably a cerberus BUG]\"}"
          | .Undef0 loc (ub :: _) =>
            -- OCaml batch_drive parity: first UB only; loc via simple_location (Z-03)
            IO.println s!"Undefined \{ub: \"{stringFromUndefined_behaviour ub}\", stderr: \"{killedStderr}\", loc: \"{CerbLocation.simpleLocation loc}\"}"
          | .Error0 _loc msg =>
            IO.println s!"Error \{msg: \"{msg}\"}"
          | .Other err =>
            IO.println s!"Error \{msg: \"{driverErrorBatchMsg err}\"}"
        idx := idx + 1
      -- Exit code per OCaml main.ml runM: single Defined → 0,
      -- single Undefined/Error → 1, multiple executions → 0.
      match execs with
      | [(.Active _, _, _)] => return 0
      | [(.Killed _ _, _, _)] => return 1
      | _ => return 0
    else
      IO.println s!"  executions: {execs.length}"
      for (status, _trace, _finalSt) in execs do
        match status with
        | .Active result =>
          IO.println s!"  result: Active"
          match result.dres_core_value with
          | Vloaded (LVspecified (OVinteger ival)) =>
            match eval_integer_value ival with
            | some n => IO.println s!"  return value: {n}"
            | none => IO.println s!"  return value: (could not evaluate)"
          | v => IO.println s!"  return value: (non-integer)"
        | .Killed _st reason =>
          match reason with
          | .Undef0 loc ubs =>
            IO.println s!"  result: Killed (undefined behaviour)"
            IO.println s!"    at: {CerbLocation.stringFromLocation loc}"
            for ub in ubs do
              IO.println s!"    ub: {stringFromUndefined_behaviour ub}"
          | .Error0 loc msg =>
            IO.println s!"  result: Killed (error: {msg})"
            IO.println s!"    at: {CerbLocation.stringFromLocation loc}"
          | .Other err =>
            match err with
            | .DErr_core_run cause =>
              let causeStr := match cause with
                | .Illformed_program s => s!"Illformed_program: {s}"
                | .Found_empty_stack s => s!"Found_empty_stack: {s}"
                | .Reached_end_of_proc => "Reached_end_of_proc"
                | .Unknown_impl => "Unknown_impl"
                | .Unresolved_symbol loc (Symbol _ n _) =>
                  s!"Unresolved_symbol: Symbol(_, {n}, _) at {CerbLocation.stringFromLocation loc}"
              IO.println s!"  result: Killed (core_run error: {causeStr})"
            | .DErr_memory merr =>
              match merr with
              | .MerrInternal s => IO.println s!"  result: Killed (memory internal: {s})"
              | .MerrOther s => IO.println s!"  result: Killed (memory other: {s})"
              | .MerrOutsideLifetime s => IO.println s!"  result: Killed (outside lifetime: {s})"
              | .MerrAccess _ _ => IO.println s!"  result: Killed (memory access error)"
              | _ => IO.println s!"  result: Killed (memory error)"
            | .DErr_concurrency s => IO.println s!"  result: Killed (concurrency: {s})"
            | .DErr_other s => IO.println s!"  result: Killed (other: {s})"
      return 0

/-! ## Entry point -/

/-- THE HARNESS DEFAULT FUEL (`--fuel N`, fuel-parameter arc 2026-09-04).
    Fuel is a PARAMETER of the semantics — the LemLib `[LemFuel]` instance
    every fuel'd function reads — instantiated exactly once, here, at the
    executable's entry ([USER 2026-09-03]: fuel "is an execution parameter
    that 'doesn't matter' … a parameter which can be chosen as 10^8 or any
    other value when calling the interpreter"; "Defaults that are chosen
    eg. in test suites are fine"). This is THE ONLY PLACE a fuel numeral
    may live in this repository: no generated module, seam, test or
    speclab file may carry one (`scripts/check_no_fuel_numerals.sh`, which
    allowlists exactly the definition line below and the `letI` that
    builds the instance in `main`). 10^8 is the former budget of the
    driver family (docs/2026-09-02_fuel-arc-design.md §4 sizing: past
    every gate lane's timeout, reachable only by measure.sh-scale probes);
    it is a harness choice, overridable per run, and no theorem depends
    on it. -/
def defaultFuel : Nat := 100000000  -- FUEL-DEFAULT (the one allowed fuel numeral)

/-- Zero-discrepancy Z-24/Z-25 (charter §2.3; [USER 2026-09-03] Q7: REFUSE,
    do not plumb): every `--`-prefixed token the positional parser does not
    accept is REFUSED — loud (exit 2) and feature-ATTRIBUTED (exception class
    (c): "a LOUD, feature-attributed refusal where the oracle answers is
    allowed; a different answer, or a silent absorption, never is"). It used
    to become a FILE NAME (`uncaught exception: no such file or directory …
    file: --switches=PNVI`, rc 1 — loud but not attributed; the same for
    `--concurrency` and for a KNOWN flag out of its canonical position,
    e.g. `--batch x.json --first`). -/
def refuseFlag (flag : String) : IO Unit := do
  let feature :=
    if flag.startsWith "--switches" then
      "semantics switches (PVI/PNVI/strict_pointer_arith/CHERI/…) are not supported by this port — matched (default-switch) mode is the harness contract and CerbGlobal's switch set is permanently empty; the oracle's `--switches=…` changes the answer (e.g. PNVI turns an integer→pointer UB043 into a value)"
    else if flag == "--concurrency" then
      "concurrency is not supported by this port (the oracle's own --concurrency mode is non-functional at b9aeedcb4: `internal error: CONCURRENCY IS BROKEN`); matched mode runs atomics sequentially on both engines"
    else if flag == "--batch" || flag == "--pp-core" || flag == "--parse-core" || flag == "--first" then
      "known flag out of its canonical position (`--batch`, `--pp-core` or `--parse-core` must be argv[0]; `--first` must immediately follow `--batch`/`--pp-core`)"
    else
      "unknown flag; this port accepts only --batch | --pp-core | --parse-core (argv[0]), --first, --stdin, --libc <core> --libc-tu <json>, --call <f> [--call-args <ints>], --args <str>, --trace-nodes, --fuel <N>"
  IO.eprintln s!"cerberus-lean: refused — {flag}: {feature} (see VALIDATION.md, zero-discrepancy Z-24)"
  IO.Process.exit 2

def main (args : List String) : IO Unit := do
  -- Zero-discrepancy Z2-FL-03 (Z2 audit @ 9e86fe67c; fail-closed hygiene):
  -- a Lean `panic!` — this port's fail-stop mirror of every OCaml
  -- failwith/assert/uncaught exception (CerbFloat.truncToInt, CerbMem.killM
  -- and casePtrval, CerbUtils builtins, CerbDecode, LemLib.failwithI) —
  -- PRINTS and CONTINUES with `default` unless the runtime aborts: without
  -- LEAN_ABORT_ON_PANIC, `(int)NaN` printed `Defined {value: "Specified(0)",
  -- …}` exit 0 where the oracle is an uncaught Z.Overflow, exit 125 — a
  -- crash-to-VALUE conversion, the banned fail-open shape. The runtime tests
  -- PRESENCE of the variable (measured: "1", "0" and "" all abort; unset
  -- continues). Every harness sets it (scripts/common.sh run_cerberus_lean;
  -- LEAN_ABORT_ON_PANIC=1 at each direct invocation) — refuse otherwise.
  match ← IO.getEnv "LEAN_ABORT_ON_PANIC" with
  | some _ => pure ()
  | none =>
    IO.eprintln "cerberus-lean: refused — LEAN_ABORT_ON_PANIC is not set: a Lean panic! (this port's fail-stop mirror of every OCaml failwith/assert/uncaught exception) would print and then CONTINUE with a default value, converting a crash into a verdict; set LEAN_ABORT_ON_PANIC=1 (every harness does: scripts/common.sh run_cerberus_lean; see VALIDATION.md, zero-discrepancy Z2-FL-03)"
    IO.Process.exit 2
  -- CLI ORDER CONTRACT (sem:N7, arc-14 S1 F6; zero-discrepancy Z-24): this
  -- is a POSITIONAL flag parser (not cmdliner like the oracle). The
  -- contract: `--batch` or `--pp-core` must be argv[0]; `--first` must
  -- immediately follow it; `--parse-core` is matched against the raw args
  -- head. Any other `--`-prefixed token — an unknown flag, an oracle flag
  -- this port does not support, or a KNOWN flag out of position — is
  -- REFUSED by `refuseFlag` (loud, attributed, exit 2); it used to be
  -- silently treated as a filename. `--stdin` is the one `--` positional.
  -- --batch: machine-parseable output for the differential harness
  -- --pp-core: signature-level elaborated-Core dump (test_elab.sh)
  let batchMode := args.head? == some "--batch"
  let ppCoreMode := args.head? == some "--pp-core"
  let parseCoreMode := args.head? == some "--parse-core"
  let rest0 := if batchMode || ppCoreMode then args.drop 1 else args
  -- --first (optional, after --batch/--pp-core): single-trace execution —
  -- the Lean-side analogue of OCaml `--mode=random` (one trace instead of
  -- the exhaustive set). See CerbND.runND1 (arc-5 S3 seam).
  -- audit F3: a bare leading `--first` (no `--batch`/`--pp-core`) is NOT
  -- the single-trace switch — it stays in the scan and is refused
  let firstTrace := (batchMode || ppCoreMode) && rest0.head? == some "--first"
  let rest1 := if firstTrace then rest0.drop 1 else rest0
  -- --libc <pinned.core> --libc-tu <json> … (arc-6 S1): additive libc
  -- mode — load the pinned libc Core text dump plus the 12 metadata TU
  -- cabs-jsons (scripts/libc_prep.sh --jsons) and link the resulting
  -- library file BEFORE the user TUs (see loadLibc / runPipeline).
  -- [AGENT:S1] explicit flags (not an auto-load convention): libc-enabled
  -- runs are NEW harness modes per the arc-6 charter; standing corpora
  -- must be byte-for-byte unaffected, which an auto-load could silently
  -- break.
  -- --call <fname> [--call-args <int,int,…>]: the function-call harness
  -- mode — execute the designated function on the given integer
  -- arguments (injected as Core values via CerbCall.driveCall) instead
  -- of drive's main-startup path. --trace-nodes additionally
  -- prints the branch-0 ND-node labels (Step-coverage evidence; works in
  -- the main-startup mode too).
  let mut libcCore : Option String := none
  let mut libcTus : List String := []
  let mut callName : Option String := none
  let mut callArgsStr : Option String := none
  let mut progArgsStr : Option String := none
  let mut traceNodes : Bool := false
  -- --fuel <N> (fuel-parameter arc): the run's fuel, a positive integer;
  -- absent = `defaultFuel`. Accepted anywhere after the mode flag (the
  -- same canonical position as --libc/--call/--args); zero or a
  -- non-numeral is REFUSED (exit 2): a run at fuel 0 kills at the first
  -- bind — never a verdict — and a silent fallback to the default would
  -- be the fail-open shape the working practices ban.
  let mut fuelStr : Option String := none
  let mut restArgs : List String := []
  -- --parse-core consumes its file list itself (below); nothing to scan
  let mut pending := if parseCoreMode then [] else rest1
  while true do
    match pending with
    | [] => break
    | "--libc" :: v :: rest => libcCore := some v; pending := rest
    | "--libc-tu" :: v :: rest => libcTus := libcTus ++ [v]; pending := rest
    | "--call" :: v :: rest => callName := some v; pending := rest
    | "--call-args" :: v :: rest => callArgsStr := some v; pending := rest
    | "--args" :: v :: rest => progArgsStr := some v; pending := rest
    | "--trace-nodes" :: rest => traceNodes := true; pending := rest
    | "--fuel" :: v :: rest => fuelStr := some v; pending := rest
    | ["--libc"] | ["--libc-tu"] | ["--call"] | ["--call-args"]
    | ["--args"] | ["--fuel"] =>
      IO.eprintln "cerberus-lean: --libc/--libc-tu/--call/--call-args/\
        --args/--fuel require an argument"
      IO.Process.exit 1
    | a :: rest =>
      -- Z-24: a `--` token here is not a file name (except `--stdin`)
      if a.startsWith "--" && a != "--stdin" then refuseFlag a
      restArgs := restArgs ++ [a]; pending := rest
  -- --args "ARG1 ARG2 ..." — the oracle's flag of the same name
  -- (backend/driver/main.ml:512-514): one string, split on whitespace
  -- runs (main.ml:111-113, Str.split "[ \t]+" — empty pieces dropped,
  -- leading/trailing whitespace ignored). Extra argv entries for the
  -- executed program's main; "cmdname" is always prepended at the
  -- drive call (pipeline.ml:598,602 mirror in runPipeline).
  let progArgs : List String := match progArgsStr with
    | none => []
    | some s => ((s.replace "\t" " ").splitOn " ").filter (· ≠ "")
  let fuel : Nat ← match fuelStr with
    | none => pure defaultFuel
    | some s => match s.toNat? with
      | some n =>
        if n == 0 then do
          IO.eprintln s!"cerberus-lean: refused — --fuel {s}: the fuel must be a positive integer (fuel 0 kills at the first bind: never a verdict; see VALIDATION.md, fuel)"
          IO.Process.exit 2
        else pure n
      | none => do
        IO.eprintln s!"cerberus-lean: refused — --fuel {s}: not a decimal numeral (the fuel is a positive integer; default {defaultFuel}; see VALIDATION.md, fuel)"
        IO.Process.exit 2
  let callFn : Option (String × List Int) ← match callName, callArgsStr with
    | none, none => pure none
    | none, some _ => do
      IO.eprintln "cerberus-lean: --call-args without --call"
      IO.Process.exit 1
    | some n, argStr => do
      let parts := match argStr with
        | none => []
        | some "" => []
        | some s => s.splitOn ","
      let mut vals : List Int := []
      for p in parts do
        match p.trim.toInt? with
        | some v => vals := vals ++ [v]
        | none => do
          IO.eprintln s!"cerberus-lean: --call-args: not an integer: {p}"
          IO.Process.exit 1
      pure (some (n, vals))
  let libc : Option (String × List String) ← match libcCore, libcTus with
    | some c, tus =>
      if tus.isEmpty then do
        IO.eprintln "cerberus-lean: --libc requires at least one --libc-tu (metadata TU cabs-json)"
        IO.Process.exit 1
      else pure (some (c, tus))
    | none, [] => pure none
    | none, _ :: _ => do
      IO.eprintln "cerberus-lean: --libc-tu without --libc"
      IO.Process.exit 1
  -- Effect-retirement C1 (charter section 5): the debug-level global is
  -- DELETED — the model returns values, the driver prints; the former
  -- human-mode level-2 write here was already vestigial (its only
  -- reader, the dbg_trace print_debug, was referenced by nothing).
  -- Also gone (charter sections 3.4/7.1): the ambient fresh counter and
  -- its 2^20 floor probe — the fresh-symbol supply is a SINGLE stream
  -- threaded explicitly from runPipeline (S1 ruling); collisions are
  -- impossible by construction, so there is no stratification invariant
  -- left to probe.
  if args.length == 0 then
    selfTest
    return

  -- --parse-core: test the Core text parser
  if args.head? == some "--parse-core" then
    let files := args.drop 1
    -- audit F2 (Z-24 contract): this branch consumed every token as a file
    -- name; a `--` token here is refused like everywhere else
    for a in files do
      if a.startsWith "--" && a != "--stdin" then refuseFlag a
    let mut failures := 0
    for file in files do
      let input ← if file == "--stdin" then do
          let mut buf := ""
          let mut done_ := false
          while !done_ do
            let line ← (← IO.getStdin).getLine
            if line.isEmpty then done_ := true
            else buf := buf ++ line
          pure buf
        else IO.FS.readFile file
      let label := if file == "--stdin" then "<stdin>" else file
      match CoreParser.parseFile input with
      | .ok cf =>
        let total := cf.funs.length + cf.procs.length + cf.impls.length +
                     cf.tagDefs.length + cf.globs.length + cf.builtins.length
        if total == 0 && input.trim.length > 0 then
          IO.eprintln s!"{label}: ERROR: parser returned .ok but 0 declarations from {input.trim.length} non-whitespace chars"
          IO.eprintln s!"{label}: first 120 chars of input: {input.take 120}"
          failures := failures + 1
        else
          IO.println s!"{label}: Core file: {cf.funs.length} fun, {cf.procs.length} proc, {cf.impls.length} def/impl, {cf.tagDefs.length} struct/union, {cf.globs.length} glob, {cf.builtins.length} builtin"
      | .error e =>
        IO.eprintln s!"{label}: ERROR: {e}"
        failures := failures + 1
    if failures > 0 then
      IO.Process.exit 1
    return

  if (batchMode || ppCoreMode) && restArgs.isEmpty then
    IO.eprintln "usage: cerberus-lean [--batch|--pp-core] [--first] FILE.json [FILE2.json ...]"
    IO.Process.exit 1

  -- Default: parse Cabs JSON (one per translation unit) and run pipeline.
  -- All cabs-jsons are deserialized up front (fail-fast on any parse
  -- error); the OCaml driver's per-file C PARSE is interleaved with its
  -- frontend fold (main.ml:153-156), but our deserialization is the
  -- Lean-side half of the --cabs-json bridge, not the C parse — its
  -- placement is an artifact of the split and carries no symbol state
  -- (Cabs has no Symbol.sym). Per-TU digests are set inside
  -- runPipeline's frontend loop (pipeline.ml:181 mirror).
  let runtimeDir ← findRuntimeDir
  let contents ← readInputs restArgs
  let mut tunits : List (String × translation_unit) := []
  for content in contents do
    match CabsImport.parseJson content with
    | .error e =>
      if batchMode then
        IO.println s!"Error \{msg: \"cabs-json parse error: {batchEscape e}\"}"
      IO.eprintln s!"cerberus-lean: parse error: {e}"
      IO.Process.exit 1
    | .ok (digest, tunit) => tunits := tunits ++ [(digest, tunit)]
  -- The ONE instantiation of the ambient fuel (fuel-parameter arc): every
  -- fuel'd function below `runPipeline` reads this instance; nothing else
  -- in the repository builds one (`scripts/check_no_fuel_numerals.sh`).
  let code ← (letI : LemFuel := ⟨fuel⟩; runPipeline runtimeDir batchMode ppCoreMode firstTrace
    callFn traceNodes libc progArgs tunits)
  if code != 0 then
    IO.Process.exit code
