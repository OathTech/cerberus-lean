/-
  Fresh name generation and digest operations.
  Corresponds to: Cerb_fresh and Digest modules in OCaml.

  This is a leaf module with no imports from generated code,
  avoiding circular dependencies in the build.
-/

set_option autoImplicit true

namespace CerberusFresh

/-- Compare two digests (strings). Returns negative, zero, or positive.
    Corresponds to: Digest.compare -/
def digest_compare (x y : String) : Int :=
  if x < y then -1 else if x == y then 0 else 1

/-- Convert digest to hex string.
    Corresponds to: Digest.to_hex -/
def string_of_digest (x : String) : String := x

/-- Create a fresh digest.
    Corresponds to: Cerb_fresh.digest -/
def digest (_ : Unit) : String := ""

/-- Fresh integer counter.
    Corresponds to: Cerb_fresh.int (uses a mutable ref cell in OCaml).
    Returns BaseIO Nat (effectful). The Lem `effectful` annotation wraps
    each call site in `runEffectful(...)` to prevent Lean's CSE. -/
@[extern "cerb_fresh_int_io"]
opaque freshIntIO : @& Unit → BaseIO Nat

end CerberusFresh
