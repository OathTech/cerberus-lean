-- Ill-typed-store kill probe (2026-09-01 S-basket item 5, in-Lean leg).
--
-- CerbMem.storeM mirrors impl_mem.ml:1673-1681: a store whose memory
-- value's type is not mem-compatible with the store's ctype is KILLED
-- (MerrOther "store with an ill-typed memory value", a non-UB Other
-- kill), and the guard is checked BEFORE the provenance/pointer-kind
-- match — so it wins over NullPtr etc. (mirroring the OCaml check
-- order).
--
-- WHY IN-LEAN, NOT DIFFERENTIAL: the guard is an internal-invariant
-- kill. The C front end + elaborator always store a value converted to
-- the store's ctype, so no C-source program reaches it through either
-- pipeline (the OCaml site even carries development printf
-- diagnostics). The read-only/locking observables that ARE reachable
-- from C are pinned by the immaculate lane's C rows
-- (lock-string-literal / lock-const-global). This probe pins the two
-- properties a differential cannot: the kill fires with the exact
-- mirrored message, and it fires before the pointer-kind match.
--
-- Legs:
--   1. mismatch at a NULL pointer -> MerrOther ill-typed kill (NOT the
--      null-access UB): proves both the guard and its ordering.
--   2. negative control: same call, type-correct value -> the null
--      -access UB (Undef0 UB019): proves leg 1's kill came from the
--      type mismatch, not from the pointer.
import CerbMem
open CerbMem

def intTy : ctype := Ctype [] (.Basic (.Integer (.Signed .Int_)))

-- fuel-parameter arc (2026-09-04): storeM reads the ambient fuel
-- (`[LemFuel]` — it reaches the fuel'd layout/serialisation workers);
-- the probe takes it from its command line (`--fuel N`, passed by
-- test_immaculate.sh as $CERB_TEST_FUEL — a test-suite choice, never a
-- numeral in the Lean text; scripts/check_no_fuel_numerals.sh).
def runStore [LemFuel] (mv : MemValue) :
    nd_action Footprint String mem_error
      (mem_constraint IntegerValue) MemState :=
  -- effect-retirement C1: storeM takes the tag table by value
  -- (reader_consumer); this probe stores a scalar with no tag in
  -- scope — the empty map is the pre-C1 (unset-global) state.
  match storeM fmapEmpty (CerbLocation.other "illtyped-store probe") intTy false
      (nullPtrval intTy) mv with
  | ND f => (f initialMemState).1

def mainAt [LemFuel] : IO Unit := do
  -- Leg 1: _Bool-typed value stored at signed-int type (mem-incompatible).
  let leg1 := match runStore (integerValueMval .Bool0 (integerIval 1)) with
    | .NDkilled (.Other (MerrOther msg)) =>
      msg == "store with an ill-typed memory value"
    | _ => false
  -- Leg 2 (negative control): int-typed value — guard passes, the null
  -- pointer kills with UB019 (undefinedFromMem_error: MerrAccess _ NullPtr).
  let leg2 := match runStore (integerValueMval (.Signed .Int_) (integerIval 1)) with
    | .NDkilled (.Undef0 _ [.UB019_lvalue_not_an_object]) => true
    | _ => false
  IO.println s!"illtyped_kill={leg1} control_null_ub={leg2}"
  if leg1 && leg2 then
    IO.println "ILLTYPED_STATUS=KILL"
  else
    IO.println "ILLTYPED_STATUS=UNEXPECTED"

def main (args : List String) : IO Unit := do
  match args with
  | ["--fuel", s] =>
    match s.toNat? with
    | some n =>
      if n == 0 then
        IO.eprintln "illtyped-store probe: refused — --fuel 0 (the fuel must be a positive integer)"
        IO.Process.exit 2
      else @mainAt ⟨n⟩
    | none =>
      IO.eprintln s!"illtyped-store probe: refused — --fuel {s}: not a decimal numeral"
      IO.Process.exit 2
  | _ =>
    IO.eprintln "illtyped-store probe: refused — usage: --fuel <N> (test_immaculate.sh passes $CERB_TEST_FUEL)"
    IO.Process.exit 2
