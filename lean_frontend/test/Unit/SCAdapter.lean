import Unit.SCValues
import Unit.SCRepresentation
import Unit.SCVarargs
import Unit.SCGraph
import Unit.SCSpawn
import Unit.SCGlobalBindings
import Unit.SCHappensBefore
import Unit.SCLinkAttribution
import Unit.SCSynchronization
import Unit.SCSequencing
import Unit.SCReferenceEquality

def main (args : List String) : IO UInt32 := do
  let [fuel] := args | return 2
  let mut failed := false
  IO.println "SCValues"
  SCUnit.SCValues.runTests
  IO.println "SCRepresentation"
  let result ← SCUnit.SCRepresentation.runTests
  failed := failed || result != 0
  IO.println "SCVarargs"
  SCUnit.SCVarargs.runTests
  IO.println "SCGraph"
  let result ← SCUnit.SCGraph.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCSpawn"
  SCUnit.SCSpawn.runTests
  IO.println "SCGlobalBindings"
  let result ← SCUnit.SCGlobalBindings.runTests
  failed := failed || result != 0
  IO.println "SCHappensBefore"
  SCUnit.SCHappensBefore.runTests
  IO.println "SCLinkAttribution"
  SCUnit.SCLinkAttribution.runTests
  IO.println "SCSynchronization"
  SCUnit.SCSynchronization.runTests
  IO.println "SCSequencing"
  let result ← SCUnit.SCSequencing.runTests [fuel]
  failed := failed || result != 0
  IO.println "SCReferenceEquality"
  let result ← SCUnit.SCReferenceEquality.runTests
  failed := failed || result != 0
  return if failed then 1 else 0
