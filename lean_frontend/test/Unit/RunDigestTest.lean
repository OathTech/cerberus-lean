import CabsImport
import Driver
import Lean.Elab.Command

/-! D-S acceptance: kernel equations on the generated mint and entry, the actual
production digest selector, and the digest carried by a committed cabs-json.
The fixture binding is checked at elaboration and runtime; the shape theorem is
kernel-checked on the pinned value. No native proof procedure or option bumps. -/
namespace RunDigestTest

set_option autoImplicit false

def symDigest : sym → String
  | Symbol d _ _ => d

-- T1: cerberus-sl's definition equation, universally quantified.
theorem mint_eq (d : String) (n : Nat) :
    fresh_given_int d n = Symbol d n SD_None := rfl

-- T2: cerberus-sl's MintDigest shape, universally quantified.
theorem mintDigest (d : String) :
    ∀ m, symDigest (fresh_given_int d m) = d := fun _ => rfl

-- T3: the empty and LAST-unit cases on concrete, distinct digest values.
def firstDigest : String := "900150983cd24fb0d6963f7d28e17f72"
def lastDigest : String := "9e107d9d372bb6826bd81d3542a419d6"

theorem runDigest_empty : runDigest [] = "" := rfl
theorem runDigest_last :
    runDigest [(firstDigest, TUnit []), (lastDigest, TUnit [])] = lastDigest := rfl
theorem runDigest_reversed :
    runDigest [(lastDigest, TUnit []), (firstDigest, TUnit [])] = firstDigest := rfl

-- T4: this existing oracle fixture supplies the entry digest. Include its bytes
-- for the compile-time binding check; main also reads the file afresh to reject
-- a stale executable if the fixture changes without recompilation.
def fixtureJson : String := include_str "../../../tests/fixtures/001-return-literal/cabs.json"
def fixtureDigest : String := "81c0f476cb2abad15583f4fcde44a0ed"

open Lean Elab Command in
#eval show CommandElabM Unit from do
  match CabsImport.parseJson fixtureJson with
  | .error e => throwError "RunDigestTest: committed cabs-json does not parse: {e}"
  | .ok (d, _) =>
      unless d == fixtureDigest do
        throwError "RunDigestTest: fixture digest changed: {d}"

theorem fixture_shape :
    fixtureDigest.length = 32 ∧
    fixtureDigest.toList.all (fun c => c.isDigit || ('a' ≤ c && c ≤ 'f')) = true ∧
    fixtureDigest ≠ "" := by decide

theorem fixture_entry_digest :
    runDigest [(fixtureDigest, TUnit [])] = fixtureDigest := rfl

-- T5: a small Core file literal, both entry variants, both core-state
-- constructors, and the actual run-mint operation (including field preservation).
def emptyFile : file core_run_annotation :=
  { main := none, calling_convention0 := default,
    tagDefs := fmapEmpty, enumDefs := fmapEmpty, stdlib := fmapEmpty,
    impl0 := fmapEmpty, globs := [], funs := fmapEmpty, extern := fmapEmpty,
    funinfo := fmapEmpty, loop_attributes1 := fmapEmpty, visible_objects_env0 := fmapEmpty }

def entry (sup : Nat) (top : Int) (d : String) : driver_state :=
  (initial_driver_state sup top d emptyFile CerbFS.fs_initial_state).1

theorem entry_digest (sup : Nat) (top : Int) (d : String) :
    (entry sup top d).core_run_state0.sym_digest = d := rfl

theorem given_entry_digest (sup : Nat) (top : Int) (d : String) :
    (initial_driver_state_given sup top d emptyFile CerbFS.fs_initial_state).1.core_run_state0.sym_digest = d := rfl

theorem core_given_digest (sup : Nat) (d : String) :
    (initial_core_run_state_given sup d fmapEmpty).sym_digest = d := rfl

theorem core_entry_digest (sup : Nat) (d : String) :
    (initial_core_run_state sup d fmapEmpty).1.sym_digest = d := rfl

theorem entry_mint (sup : Nat) (top : Int) (d : String) :
    (fresh_symbol' (entry sup top d).core_run_state0).1 = Symbol d sup SD_None := rfl

theorem mint_preserves_digest (rs : core_run_state) :
    (fresh_symbol' rs).2.sym_digest = rs.sym_digest := rfl

-- T6: the old arity is rejected, not silently supplied from an ambient read.
/-- error: Application type mismatch: The argument
  n
has type
  Nat
but is expected to have type
  String
in the application
  fresh_given_int n -/
#guard_msgs in
example (n : Nat) : sym := fresh_given_int n

-- Each named acceptance fact has an exact, kernel-only axiom census.
/-- info: 'RunDigestTest.mint_eq' does not depend on any axioms -/
#guard_msgs in
#print axioms mint_eq
/-- info: 'RunDigestTest.mintDigest' does not depend on any axioms -/
#guard_msgs in
#print axioms mintDigest
/-- info: 'RunDigestTest.runDigest_empty' does not depend on any axioms -/
#guard_msgs in
#print axioms runDigest_empty
/-- info: 'RunDigestTest.runDigest_last' does not depend on any axioms -/
#guard_msgs in
#print axioms runDigest_last
/-- info: 'RunDigestTest.runDigest_reversed' does not depend on any axioms -/
#guard_msgs in
#print axioms runDigest_reversed
/-- info: 'RunDigestTest.fixture_shape' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms fixture_shape
/-- info: 'RunDigestTest.fixture_entry_digest' does not depend on any axioms -/
#guard_msgs in
#print axioms fixture_entry_digest
/-- info: 'RunDigestTest.entry_digest' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms entry_digest
/-- info: 'RunDigestTest.given_entry_digest' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms given_entry_digest
/-- info: 'RunDigestTest.core_given_digest' does not depend on any axioms -/
#guard_msgs in
#print axioms core_given_digest
/-- info: 'RunDigestTest.core_entry_digest' does not depend on any axioms -/
#guard_msgs in
#print axioms core_entry_digest
/-- info: 'RunDigestTest.entry_mint' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms entry_mint
/-- info: 'RunDigestTest.mint_preserves_digest' does not depend on any axioms -/
#guard_msgs in
#print axioms mint_preserves_digest

end RunDigestTest

def main : IO UInt32 := do
  let fixture ← IO.FS.readFile "../tests/fixtures/001-return-literal/cabs.json"
  match CabsImport.parseJson fixture with
  | .error e =>
      IO.eprintln s!"RunDigestTest: fixture parse failed: {e}"
      return 1
  | .ok tu =>
      unless runDigest [tu] == RunDigestTest.fixtureDigest do
        IO.eprintln "RunDigestTest: parsed fixture's entry digest differs from the kernel pin"
        return 1
  IO.println "T1 PASS: fresh_given_int d n = Symbol d n SD_None (rfl)"
  IO.println "T2 PASS: forall m, symDigest (fresh_given_int d m) = d (rfl)"
  IO.println "T3 PASS: empty, last-unit and reversed-order digest pins (rfl)"
  IO.println "T4 PASS: committed cabs-json digest is 32 lowercase hex digits and nonempty (decide); parsed entry agrees"
  IO.println "T5 PASS: both entries and constructors seed the digest; run mint uses it and preserves it (rfl)"
  IO.println "T6 PASS: old fresh_given_int arity rejected (#guard_msgs)"
  return 0
