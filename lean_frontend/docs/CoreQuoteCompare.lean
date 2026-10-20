import Main
import Unit.CoreQuoteTest

/- Loaded by CoreQuoteRoundTrip.py after the independently elaborated literal. -/
namespace CoreQuoteTest
open Lean

/-- Independently rebuild the pre-execution value, using the public pipeline
    stages and the driver's reverse-consed link order. No printer operation
    participates in this computation or the representation comparison. -/
def original (fuel : Nat) (mode : String) (inputs : List String) : IO (file core_run_annotation) :=
  letI : LemFuel := ⟨fuel⟩
  letI : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩
  do
  let runtime := "_build/install/default/lib/cerberus-lib/runtime"
  let stdPath := runtime ++ "/libcore/std.core"
  let library ← unwrap (CoreParser.parseLibraryFile stdPath (← IO.FS.readFile stdPath))
  let (names, stdFuns) := loadCoreStdlib library
  let implPath := runtime ++ "/libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl"
  let implFile ← unwrap (CoreParser.parseLibraryFile implPath (← IO.FS.readFile implPath))
  let impl := loadCoreImpl implFile
  if mode == "libc" then
    let .ok (f, _) ← loadLibc runtime true 0 defaultAddressSpaceTop
        (names, stdFuns, impl) names stdFuns impl "tests/libc/libc.core" inputs
      | throw (IO.userError "Core quote test: loadLibc failed")
    return convert_file f
  require (mode == "tu") s!"unknown pipeline mode {mode}"
  let mut files := []
  let mut supply := 0
  for path in inputs do
    let (digest, tu, paths) ← unwrap (CabsImport.parseJsonWithFiles (← IO.FS.readFile path))
    refuseLibraryLocations runtime path paths
    let _ ← (CerberusFresh.setDigestIO digest : BaseIO Unit)
    let .ok (f, next) ← frontendTU true supply defaultAddressSpaceTop
        (names, stdFuns, impl) names stdFuns impl tu
      | throw (IO.userError s!"Core quote test: frontend failed: {path}")
    files := f :: files
    supply := next
  let .Result linked := link files | throw (IO.userError "Core quote test: link failed")
  return convert_file linked

def check (root mode : String) (fuel : Nat) (inputs : List String)
    (quoted : file core_run_annotation) : IO Unit := do
  IO.Process.setCurrentDir root
  let expected ← original fuel mode inputs
  let shape := view0 expected
  let counts := census shape
  require (counts.getD "NaN" 0 == 0) "required input contains Float.NaN"
  require (sameShape shape (view0 quoted)) "whole-file representation differs"
  require (expected == quoted) "auxiliary generated whole-file BEq failed"
  let quotedCounts := census (view0 quoted)
  require (quotedCounts.getD "absolute-position" 0 == 0) "literal contains an absolute position path"
  IO.println ("CORE_QUOTE_CENSUS " ++ (Json.mkObj
    (counts.toList.map fun (k, n) => (k, toJson n))).compress)

end CoreQuoteTest
