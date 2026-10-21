/- Focused D1 elaboration probe. This is not the D3 whole-file comparator. -/
import Main
import CerbQuote

namespace CoreQuotePipelineProbe

def unwrap {α : Type} : Except String α → IO α
  | .ok a => pure a
  | .error e => throw (IO.userError e)

def run (fuel : Nat) (top : Int) (mode : String) : IO Unit := do
  IO.Process.setCurrentDir ".."
  let runtime := (← IO.currentDir).toString ++ "/_build/install/default/lib/cerberus-lib/runtime"
  let stdPath := runtime ++ "/libcore/std.core"
  let std ← unwrap (CoreParser.parseLibraryFile stdPath (← IO.FS.readFile stdPath))
  let (names, stdFuns) := loadCoreStdlib std
  let implPath := runtime ++ "/libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl"
  let implFile ← unwrap (CoreParser.parseLibraryFile implPath (← IO.FS.readFile implPath))
  let impl := loadCoreImpl implFile
  let (f, provenance, output) ← match mode with
    | "fixture" => do
      let (digest, tu, _) ← unwrap (CabsImport.parseJsonWithFiles
        (← IO.FS.readFile "tests/fixtures/001-return-literal/cabs.json"))
      let _ ← (CerberusFresh.setDigestIO digest : BaseIO Unit)
      let .ok (f, _) ← @frontendTU ⟨fuel⟩ ⟨[]⟩ true 0 top (names, stdFuns, impl) names stdFuns impl tu
        | throw (IO.userError "frontendTU failed")
      let .Result linked := link [f] | throw (IO.userError "link failed")
      let provenance ← match CerbQuote.linkedProvenance [CerbQuote.translatedProvenance f] linked with
        | .ok p => pure p
        | .error e => throw (IO.userError e.message)
      pure (linked, provenance, "PipelineQuoted.lean")
    | "libc" => do
      let paths := ((← IO.FS.readFile ".tmp/core-quote-d1/libc-json-paths.txt").splitOn "\n").filter (· != "")
      unless paths.length == 12 do throw (IO.userError "expected twelve metadata TUs")
      let .ok (libc, _) ← @loadLibc ⟨fuel⟩ ⟨[]⟩ runtime false 0 top
          (names, stdFuns, impl) names stdFuns impl "tests/libc/libc.core" paths
        | throw (IO.userError "loadLibc failed")
      pure (libc, CerbQuote.libcProvenance libc, "LibcQuoted.lean")
    | _ => throw (IO.userError "CERB_QUOTE_PROBE must be fixture or libc")
  let source ← match CerbQuote.moduleSource [] provenance (convert_file f) with
    | .ok s => pure s
    | .error e => throw (IO.userError e.message)
  IO.FS.writeFile (".tmp/core-quote-d1/" ++ output) source
  IO.println s!"D1 {mode} probe: {source.utf8ByteSize} bytes emitted"

#eval (do
  let some f ← IO.getEnv "CERB_QUOTE_FUEL" | throw (IO.userError "CERB_QUOTE_FUEL required")
  let some fuel := f.toNat? | throw (IO.userError "invalid CERB_QUOTE_FUEL")
  let some a ← IO.getEnv "CERB_QUOTE_TOP" | throw (IO.userError "CERB_QUOTE_TOP required")
  let some top := a.toInt? | throw (IO.userError "invalid CERB_QUOTE_TOP")
  let some mode ← IO.getEnv "CERB_QUOTE_PROBE" | throw (IO.userError "CERB_QUOTE_PROBE required")
  run fuel top mode : IO Unit)

end CoreQuotePipelineProbe
