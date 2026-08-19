import CerberusImpl
import CerbMem
import CerbCtypeInstances
import CerbCabsInstances
import CerbInhabitedInstances
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
  let ailnames : Fmap String sym := Lem_Map.fromList stdFile.ailnames
  let funMap : fun_map Unit := Lem_Map.fromList allDecls
  (ailnames, funMap)

/-- Convert impl declarations from a CoreParser.CoreFile into an impl map. -/
def loadCoreImpl (implFile : CoreParser.CoreFile) : impl :=
  implFile.impls.foldl
    (fun acc (name, d) =>
      let ic := CoreParser.pImplConstant name
      fmapAdd ic d acc)
    fmapEmpty

/-! ## Helpers -/

def readInput (args : List String) : IO String := do
  match args with
  | ["--stdin"] => do
    let mut buf := ""
    let mut done_ := false
    while !done_ do
      let line ← (← IO.getStdin).getLine
      if line.isEmpty then done_ := true
      else buf := buf ++ line
    return buf
  | [file] => IO.FS.readFile file
  | _ => throw (IO.Error.userError "usage: cerberus-lean [--batch] [--stdin | FILE.json]")

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
Deviations from OCaml (hand-written latitude, documented):
  - loc strings use CerbLocation.stringFromLocation (harness never compares loc)
  - Unspecified/OtherValue payloads use our placeholder pretty-printers
    (an honest textual mismatch if they ever differ; OCaml uses String_core)
  - non-UB frontend failures emit an `Error {msg: ...}` line on stdout
    (OCaml puts them on stderr only); fail-closed either way
  - runND returning zero executions emits `Error {msg: ...}` + exit 1
    (OCaml prints nothing and exits 0 — we refuse to look like success) -/

/-- OCaml String.escaped (subset: the characters that occur in practice). -/
def batchEscape (s : String) : String :=
  s.foldl (fun acc c =>
    acc ++ (if c == '"' then "\\\""
      else if c == '\\' then "\\\\"
      else if c == '\n' then "\\n"
      else if c == '\t' then "\\t"
      else if c == '\r' then "\\r"
      else String.singleton c)) ""

/-- Batch rendering of the final core value (mirrors OCaml's
    `string_of_batch_exit` for the Specified-integer case, which is the
    only case the harness compares by value). -/
def batchExitValue (v : value) : String :=
  match v with
  | Vloaded (LVspecified (OVinteger ival)) =>
    match eval_integer_value ival with
    | some n => s!"Specified({n})"
    | none => s!"OtherValue(<unevaluatable integer>)"
  | Vloaded (LVunspecified ty) => s!"Unspecified({CerbPP.stringFromCtype ty})"
  | v => s!"OtherValue({CerbPP.stringFromCore_value v})"

/-- Batch rendering of a driver error (info-parity with the human-mode
    printer; the harness never compares these strings textually). -/
def driverErrorBatchMsg : driver_error → String
  | .DErr_core_run cause =>
    match cause with
    | .Illformed_program s => s!"Illformed_program: {s}"
    | .Found_empty_stack s => s!"Found_empty_stack: {s}"
    | .Reached_end_of_proc => "Reached_end_of_proc"
    | .Unknown_impl => "Unknown_impl"
    | .Unresolved_symbol loc (Symbol _ n _) =>
      s!"Unresolved_symbol: Symbol(_, {n}, _) at {CerbLocation.stringFromLocation loc}"
  | .DErr_memory merr =>
    match merr with
    | .MerrInternal s => s!"memory internal: {s}"
    | .MerrOther s => s!"memory other: {s}"
    | .MerrOutsideLifetime s => s!"outside lifetime: {s}"
    | .MerrAccess _ _ => "memory access error"
    | _ => "memory error"
  | .DErr_concurrency s => s!"Concurrency error: {s}"
  | .DErr_other s => s

/-! ## Elaborated-Core signature dump (`--pp-core`, arc-4 S4)

LIMITATION — SIGNATURE-LEVEL ONLY, deliberately. The Lean pipeline has no
real Core pretty-printer (CerbPP is placeholders; the generated Pp.lean is
a stub), and building one is explicitly out of scope for this slice
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
  for (s, (_loc, td)) in coreFile.tagDefs do
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
  for (s, d) in coreFile.funs do
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

/-- Run the pipeline. `batch` selects machine-parseable output (see above);
    `ppCore` stops after translation and dumps the signature-level Core
    summary (see `ppCoreSignature`); the default human-readable mode is
    unchanged (and keeps its historical exit-code behavior: 0 even on
    semantic stage failures). -/
def runPipeline (runtimeDir : String) (batch : Bool) (ppCore : Bool) (tunit : translation_unit) : IO UInt8 := do
  -- Progress chatter: human mode only (batch and pp-core keep stdout clean)
  let quiet := batch || ppCore
  let say (s : String) : IO Unit := unless quiet do IO.println s
  let (TUnit decls) := tunit
  let (funcs, declCount, other) := countDecls decls
  say s!"cerberus-lean: parsed {List.length decls} external declarations"
  say s!"  functions: {funcs}, declarations: {declCount}, other: {other}"

  -- Load core stdlib
  say "  loading core stdlib..."
  let stdContent ← IO.FS.readFile (runtimeDir ++ "/std.core")
  let stdFile ← match CoreParser.parseFile stdContent with
    | .ok f => pure f
    | .error e => throw (IO.Error.userError s!"failed to parse std.core: {e}")
  let allStdDecls := stdFile.funs ++ stdFile.procs ++ stdFile.builtins
  say s!"    raw: {stdFile.funs.length} fun, {stdFile.procs.length} proc, {stdFile.builtins.length} builtin = {allStdDecls.length} total"
  let allStd := stdFile.funs ++ stdFile.procs ++ stdFile.builtins
  let (ailnames, stdFunMap) := loadCoreStdlib stdFile
  say s!"    ailnames: {List.length ailnames} entries"
  say s!"    stdlib funs: {List.length stdFunMap} entries"

  -- Load implementation file
  say "  loading implementation..."
  let implContent ← IO.FS.readFile (runtimeDir ++ "/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl")
  let implFile ← match CoreParser.parseFile implContent with
    | .ok f => pure f
    | .error e => throw (IO.Error.userError s!"failed to parse impl file: {e}")
  let coreImpl := loadCoreImpl implFile
  say s!"    impl constants: {List.length coreImpl} entries"

  -- Build the implementation
  say "  building implementation..."
  let coreEvalStuff : Fmap String sym × fun_map Unit × impl :=
    (ailnames, stdFunMap, coreImpl)

  -- Desugar Cabs → AIL
  say "  desugaring Cabs → AIL..."
  let cnInit := empty_init
  -- arc-2 S6: desugar is no longer reader-lifted — the constant-expression
  -- driver (its only tagDefs consumer) now seeds itself lexically with the
  -- translated definitions inside Mini_pipeline.run_const_expr_driver, so
  -- the desugar chain takes no reader parameter at all.
  match desugar coreEvalStuff cnInit "main" tunit with
  | .Result (_, (mainSym, ailProg)) =>
    say s!"  desugaring succeeded!"
    say s!"    main symbol: {match mainSym with | some _ => "found" | none => "not found"}"
    say s!"    declarations: {List.length ailProg.declarations}"
    say s!"    function defs: {List.length ailProg.function_definitions}"
    say s!"    tag defs: {List.length ailProg.tag_definitions}"

    -- Step 2: Typecheck AIL (mirrors pipeline.ml:217-219)
    say "  typechecking AIL..."
    let ailInput := (mainSym, ailProg)
    match to_exception (fun (p : CerbLocation.Loc × typing_error) => (p.1, AIL_TYPING p.2))
            (annotate_program ailInput) with
    | .Exception (loc, cause) =>
      if quiet then
        -- OCaml parity: typing-level UB gets a batch Undefined line (main.ml runM)
        match cause with
        | .AIL_TYPING (.TError_UndefinedBehaviour ub) =>
          IO.println s!"Undefined \{ub: \"{stringFromUndefined_behaviour ub}\", stderr: \"\", loc: \"{CerbLocation.stringFromLocation loc}\"}"
        | _ =>
          IO.println s!"Error \{msg: \"typechecking failed at {CerbLocation.stringFromLocation loc}\"}"
        return 1
      else
        IO.println s!"  typechecking failed!"
        IO.println s!"    at: {CerbLocation.stringFromLocation loc}"
        return 0
    | .Result (typedProg, _annots) =>
      say s!"  typechecking succeeded!"

      -- Step 3: Translate AIL → Core
      say "  translating AIL → Core..."
      -- NOTE: must use the BaseIO variant here: the pure wrapper's result is
      -- unused, and `let _ := CerbTags.reset_tagDefs ()` gets dead-code
      -- eliminated (found in arc-4 S3b: the sibling set_tagDefs below was
      -- being dropped, leaving the global EMPTY throughout execution).
      let _ ← (CerbTags.resetTagDefsIO () : BaseIO Unit)
      let callconv := Normal_callconv
      let coreFile := translate (ailnames, stdFunMap) callconv coreImpl typedProg
      say s!"  translation succeeded!"
      say s!"    main: {match coreFile.main with | some _ => "found" | none => "not found"}"
      say s!"    funs: {List.length coreFile.funs}"
      say s!"    globs: {List.length coreFile.globs}"

      -- --pp-core: signature-level dump of the translated Core, then stop
      -- (no execution). See the ppCoreSignature module note for the
      -- granularity limitation.
      if ppCore then
        ppCoreSignature coreFile
        return 0

      -- Step 4: Prepare for execution (mirrors driver_ocaml.ml)
      say "  preparing for execution..."
      let runFile := convert_file coreFile
      -- BaseIO variant — a discarded pure `set_tagDefs` call is dead-code
      -- eliminated (see reset above); CerbMem's struct/union layout
      -- (sizeof/alignof/offsetsof) reads this global during execution.
      let _ ← (CerbTags.setTagDefsIO runFile.tagDefs : BaseIO Unit)
      let fsState := CerbFS.fs_initial_state
      let drSt := initial_driver_state runFile fsState
      say s!"  executing Core..."
      -- Reader seed: execution-slice entry; tagDefs are fully registered by now
      -- (Main itself set them above via CerbTags.setTagDefsIO), so the live
      -- global is the correct value.
      let driverAction := drive (CerbTags.tagDefs ()) false runFile ["cmdname"]
      let execs := CerbND.runND driverAction drSt
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
          | .Killed _st reason =>
            match reason with
            | .Undef0 _loc [] =>
              -- OCaml batch_drive parity: empty UB list is an Error
              IO.println "Error {msg: \"[empty UB, probably a cerberus BUG]\"}"
            | .Undef0 loc (ub :: _) =>
              -- OCaml batch_drive parity: first UB only
              IO.println s!"Undefined \{ub: \"{stringFromUndefined_behaviour ub}\", stderr: \"\", loc: \"{CerbLocation.stringFromLocation loc}\"}"
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
  | .Exception (loc, cause) =>
    if quiet then
      -- OCaml parity (main.ml runM): desugar-level UB gets a batch Undefined line
      match cause with
      | .DESUGAR (.Desugar_UndefinedBehaviour ub) =>
        IO.println s!"Undefined \{ub: \"{stringFromUndefined_behaviour ub}\", stderr: \"\", loc: \"{CerbLocation.stringFromLocation loc}\"}"
      | _ =>
        IO.println s!"Error \{msg: \"desugaring failed at {CerbLocation.stringFromLocation loc}\"}"
      return 1
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
      return 0

/-! ## Entry point -/

def main (args : List String) : IO Unit := do
  -- --batch: machine-parseable output for the differential harness
  -- --pp-core: signature-level elaborated-Core dump (test_elab.sh)
  let batchMode := args.head? == some "--batch"
  let ppCoreMode := args.head? == some "--pp-core"
  let restArgs := if batchMode || ppCoreMode then args.drop 1 else args
  -- Set debug level for Core evaluation tracing (0=off, 2=basic, 5=verbose).
  -- Batch/pp-core modes match the OCaml driver default (0): keeps stderr
  -- clean for the harness's crash classification.
  let _ := CerbDebug.set_level (if batchMode || ppCoreMode then 0 else 2)
  -- Sym non-escape floor assertion (arc-2 Phase-2 obligation, closed arc-4
  -- S5; invariant record: docs/2026-08-19_arc4-s0-frontier.md addendum).
  -- CURRENT invariant (post arc-4 S3a): desugar-threaded ids < 2^20 ≤
  -- ambient (translation/exec) ids; std.core symbols are interned by name
  -- hash (CoreParser.mkSym), not drawn from the counter. This probe draws
  -- ONE ambient id and fail-stops if the floor regressed (e.g. a stale
  -- native/fresh_int.o with a different CERB_FRESH_BASE). Downstream id
  -- streams are insensitive to the one consumed id (id-canonicalized
  -- differentials; ids are compared only for equality within a run).
  let floorProbe ← CerberusFresh.freshIntIO ()
  if floorProbe < (1 <<< 20) then
    throw (IO.userError s!"FATAL: ambient fresh-id floor violated: first draw {floorProbe} < 2^20; desugar/ambient sym streams may collide (native/fresh_int.c CERB_FRESH_BASE, arc-4 S3a invariant)")
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
    IO.eprintln "usage: cerberus-lean [--batch|--pp-core] FILE.json"
    IO.Process.exit 1

  -- Default: parse Cabs JSON and run pipeline
  let runtimeDir ← findRuntimeDir
  let input ← readInput restArgs
  match CabsImport.parseJson input with
  | .error e =>
    if batchMode then
      IO.println s!"Error \{msg: \"cabs-json parse error: {batchEscape e}\"}"
    IO.eprintln s!"cerberus-lean: parse error: {e}"
    IO.Process.exit 1
  | .ok tunit =>
    let code ← runPipeline runtimeDir batchMode ppCoreMode tunit
    if code != 0 then
      IO.Process.exit code
