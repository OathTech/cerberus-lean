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
    desugarer expects: (ailnames, stdlib_fun_map, impl). -/
def loadCoreStdlib (stdFile : CoreParser.CoreFile) :
    Fmap String sym × fun_map Unit :=
  let allDecls := stdFile.funs ++ stdFile.procs ++ stdFile.builtins
  -- CoreParser.mkSym now assigns hash-based IDs per string, so all calls
  -- to the same-named function end up with the same symbol. No renumbering
  -- needed — and indeed renumbering would break call sites inside function
  -- bodies that were parsed with the original hash-based IDs.
  let ailnamesList := allDecls.filterMap (fun (s, _) =>
    match s with
    | Symbol _ _ (SD_Id name) => some (name, s)
    | _ => none)
  let ailnames : Fmap String sym := Lem_Map.fromList ailnamesList
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
  | _ => throw (IO.Error.userError "usage: cerberus-lean [--stdin | FILE.json]")

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

def runPipeline (runtimeDir : String) (tunit : translation_unit) : IO Unit := do
  let (TUnit decls) := tunit
  let (funcs, declCount, other) := countDecls decls
  IO.println s!"cerberus-lean: parsed {List.length decls} external declarations"
  IO.println s!"  functions: {funcs}, declarations: {declCount}, other: {other}"

  -- Load core stdlib
  IO.println "  loading core stdlib..."
  let stdContent ← IO.FS.readFile (runtimeDir ++ "/std.core")
  let stdFile ← match CoreParser.parseFile stdContent with
    | .ok f => pure f
    | .error e => throw (IO.Error.userError s!"failed to parse std.core: {e}")
  let allStdDecls := stdFile.funs ++ stdFile.procs ++ stdFile.builtins
  IO.println s!"    raw: {stdFile.funs.length} fun, {stdFile.procs.length} proc, {stdFile.builtins.length} builtin = {allStdDecls.length} total"
  let allStd := stdFile.funs ++ stdFile.procs ++ stdFile.builtins
  let (ailnames, stdFunMap) := loadCoreStdlib stdFile
  IO.println s!"    ailnames: {List.length ailnames} entries"
  IO.println s!"    stdlib funs: {List.length stdFunMap} entries"

  -- Load implementation file
  IO.println "  loading implementation..."
  let implContent ← IO.FS.readFile (runtimeDir ++ "/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl")
  let implFile ← match CoreParser.parseFile implContent with
    | .ok f => pure f
    | .error e => throw (IO.Error.userError s!"failed to parse impl file: {e}")
  let coreImpl := loadCoreImpl implFile
  IO.println s!"    impl constants: {List.length coreImpl} entries"

  -- Build the implementation
  IO.println "  building implementation..."
  let coreEvalStuff : Fmap String sym × fun_map Unit × impl :=
    (ailnames, stdFunMap, coreImpl)

  -- Desugar Cabs → AIL
  IO.println "  desugaring Cabs → AIL..."
  let cnInit := empty_init
  -- arc-2 S6: desugar is no longer reader-lifted — the constant-expression
  -- driver (its only tagDefs consumer) now seeds itself lexically with the
  -- translated definitions inside Mini_pipeline.run_const_expr_driver, so
  -- the desugar chain takes no reader parameter at all.
  match desugar coreEvalStuff cnInit "main" tunit with
  | .Result (_, (mainSym, ailProg)) =>
    IO.println s!"  desugaring succeeded!"
    IO.println s!"    main symbol: {match mainSym with | some _ => "found" | none => "not found"}"
    IO.println s!"    declarations: {List.length ailProg.declarations}"
    IO.println s!"    function defs: {List.length ailProg.function_definitions}"
    IO.println s!"    tag defs: {List.length ailProg.tag_definitions}"

    -- Step 2: Typecheck AIL (mirrors pipeline.ml:217-219)
    IO.println "  typechecking AIL..."
    let ailInput := (mainSym, ailProg)
    match to_exception (fun (p : CerbLocation.Loc × typing_error) => (p.1, AIL_TYPING p.2))
            (annotate_program ailInput) with
    | .Exception (loc, cause) =>
      IO.println s!"  typechecking failed!"
      IO.println s!"    at: {CerbLocation.stringFromLocation loc}"
    | .Result (typedProg, _annots) =>
      IO.println s!"  typechecking succeeded!"

      -- Step 3: Translate AIL → Core
      IO.println "  translating AIL → Core..."
      let _ := CerbTags.reset_tagDefs ()
      let callconv := Normal_callconv
      let coreFile := translate (ailnames, stdFunMap) callconv coreImpl typedProg
      IO.println s!"  translation succeeded!"
      IO.println s!"    main: {match coreFile.main with | some _ => "found" | none => "not found"}"
      IO.println s!"    funs: {List.length coreFile.funs}"
      IO.println s!"    globs: {List.length coreFile.globs}"

      -- Step 4: Prepare for execution (mirrors driver_ocaml.ml)
      IO.println "  preparing for execution..."
      let runFile := convert_file coreFile
      let _ := CerbTags.set_tagDefs runFile.tagDefs
      let fsState := CerbFS.fs_initial_state
      let drSt := initial_driver_state runFile fsState
      IO.println s!"  executing Core..."
      -- Reader seed: execution-slice entry; tagDefs are fully registered by now
      -- (Main itself set them above via CerbTags.set_tagDefs), so the live
      -- global is the correct value.
      let driverAction := drive (CerbTags.tagDefs ()) false runFile ["cmdname"]
      let execs := CerbND.runND driverAction drSt
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
  | .Exception (loc, cause) =>
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

/-! ## Entry point -/

def main (args : List String) : IO Unit := do
  -- Set debug level for Core evaluation tracing (0=off, 2=basic, 5=verbose)
  let _ := CerbDebug.set_level 2
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

  -- Default: parse Cabs JSON and run pipeline
  let runtimeDir ← findRuntimeDir
  let input ← readInput args
  match CabsImport.parseJson input with
  | .error e =>
    IO.eprintln s!"cerberus-lean: parse error: {e}"
    IO.Process.exit 1
  | .ok tunit =>
    runPipeline runtimeDir tunit
