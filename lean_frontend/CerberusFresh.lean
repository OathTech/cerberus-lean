/-
  Fresh name generation and digest operations.
  Corresponds to: Cerb_fresh and Digest modules in OCaml.

  This is a leaf module with no imports from generated code,
  avoiding circular dependencies in the build.
-/

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

/-- Fresh integer counter using unsafe mutable state.
    Corresponds to: Cerb_fresh.int (uses a mutable ref cell in OCaml). -/
private unsafe def freshRef : IO.Ref Nat :=
  unsafeBaseIO (IO.mkRef 0)

private unsafe def freshIntUnsafe (_ : Unit) : Nat :=
  unsafeBaseIO do
    let n ← freshRef.get
    freshRef.set (n + 1)
    return n

@[implemented_by freshIntUnsafe]
opaque fresh_int : Unit → Nat

end CerberusFresh
