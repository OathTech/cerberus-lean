/-
SLUnit.Fuel — the gate executables' fuel argument (fuel-parameter arc,
2026-09-04). The exec legs of the five `*GateTest` binaries run the
production pipeline (`CerbND.runND ∘ drive`) on assembled Core terms; the
pipeline reads the ambient `[LemFuel]` instance, which — by the ruling
that fuel is a caller's parameter and never a hardcoded value
([USER 2026-09-03]; `scripts/check_no_fuel_numerals.sh` scans this
package) — the binary must receive from its caller: `--fuel N`, a
positive decimal, REQUIRED (the lane scripts pass `$CERB_TEST_FUEL`,
scripts/common.sh — the test suite's choice, outside the scanned Lean
text). Absent, zero or non-numeric: refuse loudly (exit 2), never a
default — an in-binary default would be exactly the magic value.
-/

namespace SLUnit

/-- Parse `--fuel N` from the executable's argument list; refuse otherwise. -/
def fuelFromArgs (args : List String) : IO Nat := do
  match args with
  | ["--fuel", s] =>
    match s.toNat? with
    | some n =>
      if n == 0 then
        IO.eprintln s!"gate test: refused — --fuel {s}: the fuel must be a positive integer"
        IO.Process.exit 2
      else pure n
    | none =>
      IO.eprintln s!"gate test: refused — --fuel {s}: not a decimal numeral"
      IO.Process.exit 2
  | _ =>
    IO.eprintln "gate test: refused — usage: <gate-test> --fuel <N> (the run's fuel is the caller's parameter; the lane scripts pass $CERB_TEST_FUEL, scripts/common.sh)"
    IO.Process.exit 2

end SLUnit
