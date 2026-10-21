import Main
import Unit.CoreQuoteTest

/- Loaded by CoreQuoteRoundTrip.py after the independently elaborated literal. -/
namespace CoreQuoteTest
open Lean

/-- Independently rebuild the pre-execution value, using the public pipeline
    stages and the driver's reverse-consed link order. No printer operation
    participates in this computation or the representation comparison. -/
def original [LemFuel] [CerbGlobal.Switches] (mode : String) (metadata inputs : List String) :
    IO (file core_run_annotation) := do
  let runtime := "_build/install/default/lib/cerberus-lib/runtime"
  let stdPath := runtime ++ "/libcore/" ++ CerbDriverConfig.stdCoreName
  let library ← unwrap (CoreParser.parseLibraryFile stdPath (← IO.FS.readFile stdPath))
  let (names, stdFuns) := loadCoreStdlib library
  let implPath := runtime ++ "/libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl"
  let implFile ← unwrap (CoreParser.parseLibraryFile implPath (← IO.FS.readFile implPath))
  let impl := loadCoreImpl implFile
  require (mode == "tu" || mode == "libc" || mode == "linked") s!"unknown pipeline mode {mode}"
  let mut files := []
  let mut supply := 0
  if mode == "libc" || mode == "linked" then
    let dump := if CerbGlobal.has_switch .inner_arg_temps then
        "tests/libc/libc_inner_arg_temps.core" else "tests/libc/libc.core"
    let .ok (f, next) ← loadLibc runtime true supply defaultAddressSpaceTop
        (names, stdFuns, impl) names stdFuns impl dump metadata
      | throw (IO.userError "Core quote test: loadLibc failed")
    if mode == "libc" then
      require inputs.isEmpty "standalone libc mode takes no user TUs"
      return convert_file f
    require (!inputs.isEmpty) "linked mode requires a user TU"
    -- Library first, then cons each translated TU: exactly Main.runPipeline's
    -- order and supply threading, including the library's consumed supply.
    files := [f]
    supply := next
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

def check (root mode : String) (switches : List CerbGlobal.CerbSwitch) (fuel : Nat) (metadata inputs : List String)
    (quoted : file core_run_annotation) : IO Unit := do
  IO.Process.setCurrentDir root
  let expected ← @original ⟨fuel⟩ ⟨switches⟩ mode metadata inputs
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
