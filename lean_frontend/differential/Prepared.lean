import CabsImport
import CoreParser
import Cabs_to_ail
import Cn_desugaring
import GenTyping
import CerbDriverConfig

/- Shared Cabs-to-typed-AIL boundary. The phase order, empty tag readers,
   enum reader and fresh-supply threading follow Main.frontendTU/runPipeline
   at the CoreB baseline. Original Core is deliberately used by desugaring's
   constant-expression mini-pipeline, before the two target paths fork. -/

namespace CoreBDiff

open Lean

def fail {α : Type} (message : String) : IO α := throw (IO.Error.userError message)

def pathJoin (dir file : String) : String :=
  if dir.isEmpty || dir.endsWith "/" then dir ++ file else dir ++ "/" ++ file

structure RuntimeText where
  root : String
  stdPath : String
  implPath : String
  stdText : String
  implText : String

structure RuntimeA where
  text : RuntimeText
  ailnames : Fmap String sym
  functions : fun_map Unit
  implementation : impl

def defaultElabConfig : elab_config :=
  letI : CerbGlobal.Switches := ⟨[]⟩
  { calling_convention1 := CerbDriverConfig.callingConvention
    is_PNVI := CerbGlobal.is_PNVI ()
    is_CHERI := CerbGlobal.is_CHERI ()
    is_CN := CerbGlobal.backend_name () == "Cn"
    strict_pointer_arith := CerbGlobal.has_strict_pointer_arith ()
    branching_on_unspec := .Elab_UB }

def loadImplementationA (parsed : CoreParser.CoreFile) : Except String impl := do
  parsed.impls.foldlM (fun acc (name, value) => do
    let key ← CoreParser.pImplConstant name
    pure (fmapAddBy implementation_constant_compare key value acc)) fmapEmpty

def loadRuntimeA (installPrefix : String) : IO RuntimeA := do
  if installPrefix.isEmpty then fail "runtime prefix must be nonempty"
  let root := pathJoin installPrefix "lib/cerberus-lib/runtime"
  let stdPath := pathJoin root "libcore/std.core"
  let implPath := pathJoin root "libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl"
  let stdText ← IO.FS.readFile stdPath
  let implText ← IO.FS.readFile implPath
  let _ ← (CerberusFresh.setDigestIO "" : BaseIO Unit)
  let std ← match CoreParser.parseLibraryFile stdPath stdText with
    | .ok result => pure result
    | .error reason => fail s!"Core runtime parse failed: {reason}"
  let implFile ← match CoreParser.parseLibraryFile implPath implText with
    | .ok result => pure result
    | .error reason => fail s!"Core implementation parse failed: {reason}"
  let implementation ← match loadImplementationA implFile with
    | .ok result => pure result
    | .error reason => fail s!"Core implementation key failed: {reason}"
  return {
    text := ⟨root, stdPath, implPath, stdText, implText⟩
    ailnames := Lem_Map.fromList std.ailnames
    functions := Lem_Map.fromList (std.funs ++ std.procs ++ std.builtins)
    implementation }

/-- Keep the existing runtime-directory admission check, without rewriting
    source or lexing labels. A shared frontend refusal is never a comparison. -/
def checkLibraryLabels (runtime : RuntimeText) (labels : Array String) : IO Unit := do
  let directories ← ["libc/include", "libcore", "libcore/impls"].mapM fun path => do
    return (← IO.FS.realPath (pathJoin runtime.root path)).toString
  for label in labels do
    if CerbLocation.isLibraryPathSuffix label then
      let directory ← IO.FS.realPath (CerbLocation.dirname label)
      unless directories.contains directory.toString do
        fail s!"source library location is outside the selected runtime: {label}"

structure Prepared where
  runtime : RuntimeA
  typed : ail_program genTypeCategory
  enumDefs : Fmap sym integerType
  supply : Nat
  sourceDigest : String
  runDigest : String
  inputDigest : String
  runtimeDigest : String
  addressSpaceTop : Int
  argv : List String

/-- Prepare exactly one translation unit under the initial default-switch,
    no-C-libc recipe. Runtime Core procedures remain present and executable. -/
def prepare [LemFuel] (runtimePrefix input : String) (addressSpaceTop : Int)
    (args : List String) : IO Prepared := do
  unless 0 < addressSpaceTop && addressSpaceTop < 18446744073709551616 do
    fail "address-space top must fit the LP64 pointer domain: 0 < top < 2^64"
  let runtime ← loadRuntimeA runtimePrefix
  let bytes ← IO.FS.readBinFile input
  let some text := String.fromUTF8? bytes
    | fail "Cabs JSON is not valid UTF-8"
  let (digest, tu, labels) ← match CabsImport.parseJsonWithFiles text with
    | .ok result => pure result
    | .error reason => fail s!"Cabs JSON failed: {reason}"
  checkLibraryLabels runtime.text labels
  let _ ← (CerberusFresh.setDigestIO digest : BaseIO Unit)
  let result ← (CerberusFresh.forceIO (fun () =>
    @desugar ‹LemFuel› ⟨[]⟩ fmapEmpty fmapEmpty 0 addressSpaceTop
      { elab_conf := defaultElabConfig }
      (runtime.ailnames, runtime.functions, runtime.implementation)
      empty_init "main" tu) : BaseIO _)
  let (program, supply) ← match result with
    | .Result (_, program, supply) => pure (program, supply)
    | .Exception (loc, _) => fail s!"shared desugaring failed at {CerbLocation.stringFromLocation loc}"
  let enumDefs : Fmap sym integerType := Lem_Map.fromList program.2.enum_definitions
  let typedResult ← (CerberusFresh.forceIO (fun () =>
    to_exception (fun (p : CerbLocation.Loc × typing_error) => (p.1, AIL_TYPING p.2))
      (annotate_program enumDefs fmapEmpty program)) : BaseIO _)
  let typed ← match typedResult with
    | .Result (typed, _) => pure typed
    | .Exception (loc, _) => fail s!"shared AIL typing failed at {CerbLocation.stringFromLocation loc}"
  let inputDigest := CerberusFresh.md5Hex text
  let runtimeDigest := CerberusFresh.md5Hex (Json.arr #[
    toJson runtime.text.stdPath, toJson runtime.text.stdText,
    toJson runtime.text.implPath, toJson runtime.text.implText]).compress
  return {
    runtime := runtime
    typed := typed
    enumDefs := enumDefs
    supply := supply
    sourceDigest := digest
    runDigest := digest
    inputDigest := inputDigest
    runtimeDigest := runtimeDigest
    addressSpaceTop := addressSpaceTop
    argv := "cmdname" :: args }

def Prepared.identity (prepared : Prepared) : Json := Json.mkObj [
  ("input", toJson prepared.inputDigest),
  ("sourceDigest", toJson prepared.sourceDigest),
  ("runDigest", toJson prepared.runDigest),
  ("runtime", toJson prepared.runtimeDigest),
  ("supply", toJson prepared.supply)]

end CoreBDiff
