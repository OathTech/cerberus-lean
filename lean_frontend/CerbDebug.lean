/-
  Debug output and debug level.
  Corresponds to: util/cerb_debug.ml
  Reference: lean-c-semantics doesn't have an equivalent (no debug output).
-/

import CerbLocation

set_option autoImplicit true

namespace CerbDebug

private unsafe def debugLevelRef : IO.Ref Nat :=
  unsafeBaseIO (IO.mkRef 0)

private unsafe def getLevel_impl (_ : Unit) : Nat :=
  unsafeBaseIO debugLevelRef.get

private unsafe def setLevel_impl (n : Nat) : Unit :=
  unsafeBaseIO (debugLevelRef.set n)

@[implemented_by getLevel_impl]
opaque get_level : Unit → Nat

@[implemented_by setLevel_impl]
opaque set_level : Nat → Unit

def output_string (_ : String) : Unit := ()

def print_debug (_ : Nat) (_ : List d) (_ : Unit → String) : Unit := ()

def print_debug_located (_ : Nat) (_ : List d) (_ : CerbLocation.Loc) (_ : Unit → String) : Unit := ()

def print_unsupported (_ : String) : Unit := ()

def warn (_ : List d) (_ : Unit → String) : Unit := ()

end CerbDebug
