import Unit.SCPrototype
import Unit.SCProtocol
import Unit.SCFences
import Unit.SCCAS
import Unit.SCSeqRMW
import Unit.SCAtomicUpdate
import Unit.SCAtomicSurface
import Unit.SCByteSources
import Unit.SCFaults
import Unit.SCServices
import Unit.SCHelperOrder
import Unit.FSBoundary
import Unit.NDSuspension
import Unit.MemSuspension
import Unit.SCScopes

def main (args : List String) : IO UInt32 := do
  let [small, fuel, top] := args | return 2
  let mut failed := false
  IO.println "SCPrototype"
  let result ← SCUnit.SCPrototype.runTests [small, fuel]
  failed := failed || result != 0
  IO.println "SCProtocol"
  let result ← SCUnit.SCProtocol.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCFences"
  let result ← SCUnit.SCFences.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCCAS"
  let result ← SCUnit.SCCAS.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCSeqRMW"
  let result ← SCUnit.SCSeqRMW.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCAtomicUpdate"
  let result ← SCUnit.SCAtomicUpdate.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCAtomicSurface"
  let result ← SCUnit.SCAtomicSurface.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCByteSources"
  let result ← SCUnit.SCByteSources.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCFaults"
  let result ← SCUnit.SCFaults.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCServices"
  let result ← SCUnit.SCServices.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCHelperOrder"
  let result ← SCUnit.SCHelperOrder.runTests [fuel]
  failed := failed || result != 0
  IO.println "FSBoundary"
  let result ← SCUnit.FSBoundary.runTests [fuel]
  failed := failed || result != 0
  IO.println "NDSuspension"
  let result ← SCUnit.NDSuspension.runTests [fuel]
  failed := failed || result != 0
  IO.println "MemSuspension"
  let result ← SCUnit.MemSuspension.runTests [fuel, top]
  failed := failed || result != 0
  IO.println "SCScopes"
  let result ← SCUnit.SCScopes.runTests [fuel]
  failed := failed || result != 0
  return if failed then 1 else 0
