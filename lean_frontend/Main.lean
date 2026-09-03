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
      let ic := CoreParser.pImplConstant name
      fmapAddBy implementation_constant_compare ic d acc)
    fmapEmpty

/-! ## C-libc loading (`--libc`, arc-6 S1)

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
  (runtime/libc/dune:132-141, same order, same include flags) through
  our own desugar/typecheck/translate and linking them with the
  generated Core_linking — the very pipeline that produced libc.co's
  metadata on the OCaml side (extern: `translate_extern_map`,
  translation.lem:4505-4511; funinfo/tagDefs assembly:
  translation.lem:4521-4540; link merge: link_aux/link_extern,
  core_linking.lem:10-46,286-316). `--sequentialise --rewrite` (which
  the oracle's libc.co build additionally applies) are Core-to-Core BODY
  passes; they do not alter extern/funinfo/tagDefs, so the
  reconstruction is exact up to symbol identity.

* THE STITCH: metadata symbols (per-TU-digested frontend syms) are
  rekeyed BY NAME onto CoreParser's name-hash interned symbols — the
  symbols the parsed dump bodies reference (CoreParser.internSym).
  std.core proxy symbols (exit_proxy, vprintf_proxy, … — present in
  funinfo because ailname substitution happens at elaboration,
  translation.lem:244-251) are already CoreParser-interned, so rekeying
  is the identity on them. Name collisions (the static `__procfdname`,
  defined in two libc TUs; our interning conflates the two
  alpha-equivalent definitions) are checked for structural agreement and
  fail closed otherwise.

Assembly mirrors `read_core_object` (pipeline.ml:655-663): stdlib/impl
come from the load context (:657-660), loop_attributes and
visible_objects_env are EMPTY (:661-663; empty visible_objects_env also
preserves safe_map_union's disjointness requirement at link,
core_linking.lem safe_map_union), and main = none — libc.co is a
main-less library; link_main tolerates it (core_linking.lem:50-57).

Documented divergences from the oracle's in-memory libc file:
* funinfo parameter-name symbols are dropped (kept as `none`): the
  runtime reads only the parameter CTYPES (Eccall conversion
  core_run.lem:952-967 uses `List.map snd`; cfunction core_eval.lem
  returns `snd`), and the oracle's name syms are unreconstructable
  digested frontend symbols.
* ProcDecl return base types parse as BTy_unit (not printed by the pp,
  pp_core.ml:783-785) — unread for declaration-only symbols.
* Same-named static functions conflate to one symbol (name-hash
  interning); fail-closed structural checks make this observable-
  behavior-preserving for the pinned dump.
-/

/-- symbolEqual (symbol.lem): digest+number, description ignored. -/
private def libcSymEq : sym → sym → Bool
  | Symbol d1 n1 _, Symbol d2 n2 _ => d1 == d2 && n1 == n2

private def libcSymName : sym → String
  | Symbol _ n sd =>
    match sd with
    | .SD_Id s | .SD_ObjectAddress s | .SD_FunArgValue s => s
    | .SD_None => s!"<SD_None sym {n}>"
    | _ => s!"<unnamed sym {n}>"

/-- Rekey a metadata symbol by name onto the CoreParser-interned symbol.
    Accepts exactly the descriptions `--pp core` prints as a plain name
    (Pp_symbol.to_string_pretty, pp_symbol.ml:20-24: SD_Id,
    SD_ObjectAddress, SD_FunArgValue) — the parsed dump interns those
    names, so the name-join is faithful to the pp. -/
private def libcRekeySym : sym → Except String sym
  | Symbol _ _ (SD_Id name)
  | Symbol _ _ (SD_ObjectAddress name)
  | Symbol _ _ (SD_FunArgValue name) => .ok (CoreParser.internSym name)
  | s => .error s!"libc metadata symbol without a printable name: {libcSymName s} (cannot name-join)"

/-- Rekey every struct/union tag symbol inside a ctype. -/
private partial def libcRekeyCtype : ctype → Except String ctype
  | Ctype annots ty => do
    let ty' ← match ty with
      | Void0 => pure Void0
      | Basic b => pure (Basic b)
      | Byte => pure Byte
      | Array0 t n => do pure (Array0 (← libcRekeyCtype t) n)
      | Function (qs, ret) params var => do
        let ret' ← libcRekeyCtype ret
        let params' ← params.mapM (fun (q, t, b) => do pure (q, ← libcRekeyCtype t, b))
        pure (Function (qs, ret') params' var)
      | FunctionNoParams (qs, ret) => do
        pure (FunctionNoParams (qs, ← libcRekeyCtype ret))
      | Pointer qs t => do pure (Pointer qs (← libcRekeyCtype t))
      | Atomic t => do pure (Atomic (← libcRekeyCtype t))
      | Struct s => do pure (Struct (← libcRekeySym s))
      | Union0 s => do pure (Union0 (← libcRekeySym s))
    pure (Ctype annots ty')

private def libcRekeyMember :
    identifier × (attributes × Option alignment × qualifiers × ctype) →
    Except String (identifier × (attributes × Option alignment × qualifiers × ctype))
  | (i, (attrs, al, qs, ty)) => do
    let al' ← match al with
      | some (AlignType t) => do pure (some (AlignType (← libcRekeyCtype t)))
      | x => pure x
    pure (i, (attrs, al', qs, ← libcRekeyCtype ty))

private def libcRekeyTagDef : tag_definition → Except String tag_definition
  | StructDef membrs flexOpt => do
    let membrs' ← membrs.mapM libcRekeyMember
    let flexOpt' ← match flexOpt with
      | some (FlexibleArrayMember a i q t) => do
        pure (some (FlexibleArrayMember a i q (← libcRekeyCtype t)))
      | none => pure none
    pure (StructDef membrs' flexOpt')
  | UnionDef membrs => do pure (UnionDef (← membrs.mapM libcRekeyMember))

private def identName : identifier → String
  | Identifier _ s => s

/-- Structural agreement for deduplicating same-name tag definitions
    from different TUs (same headers ⇒ identical layouts). Member names,
    qualifiers and ctypes are compared; attributes/alignment are not
    (no_attributes/none throughout the libc headers). -/
private def libcMemberEq
    (m1 m2 : identifier × (attributes × Option alignment × qualifiers × ctype)) : Bool :=
  identName m1.1 == identName m2.1 &&
  qualifiersEqual m1.2.2.2.1 m2.2.2.2.1 &&
  ctypeEqual m1.2.2.2.2 m2.2.2.2.2

private def libcTagDefEq : tag_definition → tag_definition → Bool
  | StructDef xs1 f1, StructDef xs2 f2 =>
    xs1.length == xs2.length &&
    (List.zip xs1 xs2).all (fun (a, b) => libcMemberEq a b) &&
    (match f1, f2 with
     | none, none => true
     | some (FlexibleArrayMember _ i1 q1 t1), some (FlexibleArrayMember _ i2 q2 t2) =>
       identName i1 == identName i2 && qualifiersEqual q1 q2 && ctypeEqual t1 t2
     | _, _ => false)
  | UnionDef xs1, UnionDef xs2 =>
    xs1.length == xs2.length &&
    (List.zip xs1 xs2).all (fun (a, b) => libcMemberEq a b)
  | _, _ => false

/-- Minimal diagnostic ctype printer (loader error messages only). -/
private partial def libcShowCtype : ctype → String
  | Ctype _ ty =>
    match ty with
    | Void0 => "void"
    | Basic (Integer _) => "<int-ty>"
    | Basic (Floating _) => "<float-ty>"
    | Byte => "byte"
    | Array0 t n => s!"{libcShowCtype t}[{n.getD (-1)}]"
    | Function (_, ret) params var =>
      s!"{libcShowCtype ret} ({String.intercalate ", " (params.map (fun p => libcShowCtype p.2.1))}{if var then ", ..." else ""})"
    | FunctionNoParams (_, ret) => s!"{libcShowCtype ret} <noproto>()"
    | Pointer _ t => s!"{libcShowCtype t}*"
    | Atomic t => s!"_Atomic({libcShowCtype t})"
    | Struct s => s!"struct {libcSymName s}"
    | Union0 s => s!"union {libcSymName s}"

/-- Funinfo agreement modulo location/attributes/param names — and
    modulo has_proto: the per-TU entries for a name declared in one TU
    and defined in another can disagree on has_proto (observed:
    __strtox/__strtoxd, declaration-TU true vs definition-TU false); in
    the oracle both entries coexist under distinct symbols, but our
    name-join must pick one. has_proto is verified UNREAD by the pinned
    libc bodies (all 339 cfunction 4-tuple binders bind it to a variable
    that never occurs again — checked mechanically over
    tests/libc/libc.core; the count was originally misstated as 221, a
    whitespace-brittle grep — corrected per audit-2's whitespace-tolerant
    recount, arc-6 S5f; all 339 dead, conclusion unchanged), so the
    first-inserted value stands. -/
private def libcFuninfoEq
    (f1 f2 : CerbLocation.Loc × attributes × ctype × List (Option sym × ctype) × Bool × Bool) : Bool :=
  let (_, _, ret1, ps1, v1, _) := f1
  let (_, _, ret2, ps2, v2, _) := f2
  ctypeEqual ret1 ret2 && ps1.length == ps2.length &&
  (List.zip ps1 ps2).all (fun (a, b) => ctypeEqual a.2 b.2) &&
  v1 == v2

/-- Checked insert into an assoc list (converted to an Fmap once assembly is
    complete — arc-6 S3: Fmap is no longer the raw list): duplicate keys must
    agree structurally (fail-closed name-join). -/
private def libcInsertChecked {β : Type} (what : String) (eqv : β → β → Bool)
    (m : List (sym × β)) (k : sym) (v : β)
    (dbg : β → β → String := fun _ _ => "") : Except String (List (sym × β)) :=
  match m.find? (fun kv => libcSymEq kv.1 k) with
  | none => .ok (m ++ [(k, v)])
  | some (_, v') =>
    if eqv v' v then .ok m
    else .error s!"libc metadata name-join collision with disagreeing content: {what} '{libcSymName k}'{dbg v' v}"

/-- Comparators the generated lem code keys these maps with (arc-6 S3: the
    Fmap representation captures the comparator at build time). sym-keyed
    maps: `symbol_compare` (the Ord0 sym instance every generated
    `Map.lookup`/`insert` on syms inlines); identifier-keyed maps: the
    string-only SetType identifier instance (exactly Core_linking's
    comparator). -/
private def libcSymMapCmp : sym → sym → LemOrdering := symbol_compare
private def libcIdentMapCmp : identifier → identifier → LemOrdering := fun i1 i2 =>
  match i1, i2 with
  | Identifier _ s1, Identifier _ s2 => defaultCompare s1 s2

/-- `map_from_assoc` mirror — backend/common/pipeline.ml:653-654:
    `List.fold_left (fun acc (k, v) -> Pmap.add k v acc) (Pmap.empty compare)`
    — a LEFT fold of `Pmap.add`, so on a duplicate key the later binding
    wins, as in the OCaml. Pin-bump 2026-09-03 (LemLib 3c88f0d): LemLib's
    `fmapOfSpine` (a foldr — first key won) was removed with the list-
    backed Fmap; the four assoc lists it built below are duplicate-free
    by construction (`libcInsertChecked`, the `funs` find?-dedup, the
    `fmapElements` walk of a map), so the fold direction is unobservable
    here and the OCaml direction is mirrored regardless. -/
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
  let bytes := CerbMem.intToBytes 42 4
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
  - non-UB frontend failures emit an `Error {msg: ...}` line on stdout
    (OCaml puts them on stderr only); fail-closed either way
  - runND returning zero executions emits `Error {msg: ...}` + exit 1
    (OCaml prints nothing and exits 0 — we refuse to look like success) -/

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
    DELIBERATE divergence, documented: the DErr_core_run arm keeps a local
    rendering (upstream routes through Pp_errors.string_of_core_run_cause,
    pp_errors.ml, which pretty-prints via the Pp machinery not ported to
    the batch path); no standing harness compares these strings. -/
def driverErrorBatchMsg : driver_error → String
  | .DErr_core_run cause =>
    match cause with
    | .Illformed_program s => s!"Illformed_program: {s}"
    | .Found_empty_stack s => s!"Found_empty_stack: {s}"
    | .Reached_end_of_proc => "Reached_end_of_proc"
    | .Unknown_impl => "Unknown_impl"
    | .Unresolved_symbol loc (Symbol _ n _) =>
      s!"Unresolved_symbol: Symbol(_, {n}, _) at {CerbLocation.stringFromLocation loc}"
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
def frontendTU (quiet : Bool) (supply : Nat)
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
def loadLibc (quiet : Bool) (supply0 : Nat)
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
  --    driver fold, main.ml:153-156) and link them.
  say s!"  loading libc metadata from {libcTuJsons.length} TUs..."
  let mut metaFiles : List (file Unit) := []
  let mut supply := supply0
  for j in libcTuJsons do
    let content ← IO.FS.readFile ⟨j⟩
    let tunit ← match CabsImport.parseJson content with
      | .ok t => pure t
      | .error e => return (← bail s!"cabs-json parse error in {j}: {e}")
    let _ ← (CerberusFresh.setDigestIO (CerberusFresh.md5Hex content) : BaseIO Unit)
    match ← frontendTU true supply coreEvalStuff ailnames stdFunMap coreImpl tunit with
    | .error _ => return (← bail s!"frontend failed for libc metadata TU {j}")
    | .ok (f, supply') => metaFiles := f :: metaFiles; supply := supply'
  let metaFile ← match link metaFiles with
    | .Result f => pure f
    | .Exception (_, _) => return (← bail "linking the libc metadata TUs failed")
  -- 3. Rekey the metadata by name (fail-closed).
  let rekeyed : Except String (List (sym × (CerbLocation.Loc × tag_definition)) ×
      List (identifier × (List sym × linking_kind)) ×
      List (sym × (CerbLocation.Loc × attributes × ctype × List (Option sym × ctype) × Bool × Bool))) := do
    let mut tagDefs : List (sym × (CerbLocation.Loc × tag_definition)) := []
    for (s, (loc, td)) in fmapElements metaFile.tagDefs do
      let k ← libcRekeySym s
      let td' ← libcRekeyTagDef td
      tagDefs ← libcInsertChecked "tagDef" (fun a b => libcTagDefEq a.2 b.2) tagDefs k (loc, td')
    let mut ext : List (identifier × (List sym × linking_kind)) := []
    for (ident, (ds, lk)) in fmapElements metaFile.extern do
      let ds' ← ds.mapM libcRekeySym
      let ds'' := ds'.foldl (fun acc s => if acc.any (libcSymEq s) then acc else acc ++ [s]) []
      let lk' ← match lk with
        | LK_none => pure LK_none
        | LK_tentative s => do pure (LK_tentative (← libcRekeySym s))
        | LK_normal s => do pure (LK_normal (← libcRekeySym s))
      ext := ext ++ [(ident, (ds'', lk'))]
    let mut funinfo : List (sym × (CerbLocation.Loc × attributes × ctype × List (Option sym × ctype) × Bool × Bool)) := []
    for (s, (loc, attrs, ret, params, var, proto)) in fmapElements metaFile.funinfo do
      let k ← libcRekeySym s
      let ret' ← libcRekeyCtype ret
      let params' ← params.mapM (fun (_, t) => do
        pure ((none : Option sym), ← libcRekeyCtype t))
      funinfo ← libcInsertChecked "funinfo" libcFuninfoEq funinfo k (loc, attrs, ret', params', var, proto)
        (fun a b =>
          let show1 := fun (fi : CerbLocation.Loc × attributes × ctype × List (Option sym × ctype) × Bool × Bool) =>
            let (_, _, ret, ps, v, p) := fi
            s!"(ret={libcShowCtype ret}, params=[{String.intercalate ", " (ps.map (fun (q : Option sym × ctype) => libcShowCtype q.2))}], variadic={v}, proto={p})"
          s!"\n  existing: {show1 a}\n  new:      {show1 b}")
    -- the dump's surviving tagDefs (struct fl) must agree with the
    -- metadata's — fail-closed consistency check between the two halves
    for (s, (_, td)) in parsed.tagDefs do
      match tagDefs.find? (fun kv => libcSymEq kv.1 s) with
      | none => throw s!"dump tagDef '{libcSymName s}' missing from metadata"
      | some (_, (_, td')) =>
        unless libcTagDefEq td td' do
          throw s!"dump tagDef '{libcSymName s}' disagrees with metadata"
    pure (tagDefs, ext, funinfo)
  let (tagDefs, ext, funinfo) ← match rekeyed with
    | .ok x => pure x
    | .error e => return (← bail e)
  -- 4. Fun map from the parsed dump. Proc definitions win over ProcDecl
  --    entries for the same symbol (the pp emits both for names declared
  --    in one TU and defined in another — __strtox/__strtoxd; only a
  --    Proc body satisfies call_proc, core_run.lem:46-51). Duplicate
  --    Proc definitions (static __procfdname in two TUs) keep the first.
  let mut funs : List (sym × generic_fun_map_decl Unit Unit) := []
  for (s, d) in parsed.funs ++ parsed.procs ++ parsed.builtins do
    match funs.find? (fun kv => libcSymEq kv.1 s) with
    | none => funs := funs ++ [(s, d)]
    | some (_, existing) =>
      match existing, d with
      | ProcDecl _ _ _, Proc _ _ _ _ _ =>
        funs := funs.map (fun kv => if libcSymEq kv.1 s then (kv.1, d) else kv)
      | _, _ => pure ()
  say s!"    metadata: {tagDefs.length} tagDefs, {ext.length} extern, {funinfo.length} funinfo"
  -- 5. Assemble (read_core_object mirror, pipeline.ml:655-663).
  return .ok ({
    main := none
    calling_convention0 := metaFile.calling_convention0
    tagDefs := libcMapFromAssoc libcSymMapCmp tagDefs
    stdlib := stdFunMap
    impl0 := coreImpl
    globs := parsed.globs
    funs := libcMapFromAssoc libcSymMapCmp funs
    extern := libcMapFromAssoc libcIdentMapCmp ext
    funinfo := libcMapFromAssoc libcSymMapCmp funinfo
    loop_attributes1 := fmapEmpty
    visible_objects_env0 := fmapEmpty
  }, supply)



/-- Run the pipeline over one or more translation units (multi-TU, arc-5
    S2). `tunits` carries (cabs-json content, parsed Cabs) per TU in
    command-line order. Per TU: set the TU digest, then
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
def runPipeline (runtimeDir : String) (batch : Bool) (ppCore : Bool)
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
  for (content, tunit) in tunits do
    -- Per-TU digest, before the TU's frontend stages — mirror of
    -- `Cerb_fresh.set_digest filename` at the top of the OCaml c_frontend
    -- (backend/common/pipeline.ml:181; ref cell util/cerb_fresh.ml:7-10).
    -- We digest the cabs-json content we were handed (the Lean pipeline
    -- never sees the .c file — divergence recorded in CerberusFresh.lean).
    -- Placement note: OCaml sets the digest before its C PARSE; our Cabs
    -- deserialization already happened in main — harmless, Cabs carries
    -- no Symbol.sym, so no symbol is created before the set.
    -- BaseIO variant: a discarded pure call is dead-code-eliminated
    -- (CerbTags set/reset pattern, arc-4 S3b).
    let _ ← (CerberusFresh.setDigestIO (CerberusFresh.md5Hex content) : BaseIO Unit)
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

def main (args : List String) : IO Unit := do
  -- CLI ORDER CONTRACT (sem:N7, documented arc-14 S1 F6): this is a
  -- POSITIONAL flag parser (not cmdliner like the oracle). The contract:
  -- `--batch` or `--pp-core` must be argv[0]; `--first` must immediately
  -- follow it; `--parse-core` is matched against the raw args head. A
  -- misordered flag is silently treated as a filename. This is
  -- acceptable for a test-harness binary (the harnesses always pass the
  -- canonical order); a real CLI would use a proper parser.
  -- --batch: machine-parseable output for the differential harness
  -- --pp-core: signature-level elaborated-Core dump (test_elab.sh)
  let batchMode := args.head? == some "--batch"
  let ppCoreMode := args.head? == some "--pp-core"
  let rest0 := if batchMode || ppCoreMode then args.drop 1 else args
  -- --first (optional, after --batch/--pp-core): single-trace execution —
  -- the Lean-side analogue of OCaml `--mode=random` (one trace instead of
  -- the exhaustive set). See CerbND.runND1 (arc-5 S3 seam).
  let firstTrace := rest0.head? == some "--first"
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
  let mut restArgs : List String := []
  let mut pending := rest1
  while true do
    match pending with
    | [] => break
    | "--libc" :: v :: rest => libcCore := some v; pending := rest
    | "--libc-tu" :: v :: rest => libcTus := libcTus ++ [v]; pending := rest
    | "--call" :: v :: rest => callName := some v; pending := rest
    | "--call-args" :: v :: rest => callArgsStr := some v; pending := rest
    | "--args" :: v :: rest => progArgsStr := some v; pending := rest
    | "--trace-nodes" :: rest => traceNodes := true; pending := rest
    | ["--libc"] | ["--libc-tu"] | ["--call"] | ["--call-args"]
    | ["--args"] =>
      IO.eprintln "cerberus-lean: --libc/--libc-tu/--call/--call-args/\
        --args require an argument"
      IO.Process.exit 1
    | a :: rest => restArgs := restArgs ++ [a]; pending := rest
  -- --args "ARG1 ARG2 ..." — the oracle's flag of the same name
  -- (backend/driver/main.ml:512-514): one string, split on whitespace
  -- runs (main.ml:111-113, Str.split "[ \t]+" — empty pieces dropped,
  -- leading/trailing whitespace ignored). Extra argv entries for the
  -- executed program's main; "cmdname" is always prepended at the
  -- drive call (pipeline.ml:598,602 mirror in runPipeline).
  let progArgs : List String := match progArgsStr with
    | none => []
    | some s => ((s.replace "\t" " ").splitOn " ").filter (· ≠ "")
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
    | .ok tunit => tunits := tunits ++ [(content, tunit)]
  let code ← runPipeline runtimeDir batchMode ppCoreMode firstTrace
    callFn traceNodes libc progArgs tunits
  if code != 0 then
    IO.Process.exit code
