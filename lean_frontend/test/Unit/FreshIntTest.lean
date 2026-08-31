/-
  Test: supply-threaded fresh symbols + the digest boundary.

  Effect-retirement C1 rewrite (charter section 7.1): the old
  runEffectful/freshIntIO distinctness probes died with the mechanism —
  `fresh_int` is a lem SUPPLY on the Lean target, so `Symbol.fresh` is
  the pure lifted `fresh : Nat → Unit → sym × Nat`. The tests now pin
  the THREADING LAWS (monotonicity + distinctness through a lifted
  chain, kernel-visible) and keep the surviving digest-barrier tests
  (the digest global remains; its opaque conversion is C2).
-/

import Symbol
import CerberusFresh
import LemLib

def assertNotEqual {α : Type} [BEq α] [Repr α] (label : String) (a b : α) : IO Bool := do
  if a == b then
    IO.println s!"  ✗ FAIL {label}: both values are {repr a}"
    return false
  else
    return true

def assertEqual {α : Type} [BEq α] [Repr α] (label : String) (got expected : α) : IO Bool := do
  if got == expected then
    return true
  else
    IO.println s!"  ✗ FAIL {label}: got {repr got}, expected {repr expected}"
    return false

/-- Kernel-checked threading laws: the exact draw sequence of a lifted
    chain is a defeq fact (the L1 supply pins' pattern, TestSupplyCheck):
    each draw returns the current supply and advances by one. -/
example : LemLib.supplySplit 100 = (100, 101) := rfl

def symId : sym → Nat := fun | Symbol _ n _ => n

def testSupplyThreading : IO Bool := do
  IO.println "test: Symbol.fresh threads the supply (monotone, distinct, returned)"
  let (s1, sup1) := fresh 500 ()
  let (s2, sup2) := fresh sup1 ()
  let (s3, sup3) := fresh sup2 ()
  IO.println s!"  got ids: {symId s1}, {symId s2}, {symId s3}; final supply {sup3}"
  let okA ← assertEqual "first draw uses the seed" (symId s1) 500
  let okB ← assertEqual "supply advances by one per draw" (sup1, sup2, sup3) (501, 502, 503)
  let ok12 ← assertNotEqual "s1 vs s2" (symId s1) (symId s2)
  let ok23 ← assertNotEqual "s2 vs s3" (symId s2) (symId s3)
  let ok13 ← assertNotEqual "s1 vs s3" (symId s1) (symId s3)
  if okA && okB && ok12 && ok23 && ok13 then
    IO.println "  ✓ PASS"
    return true
  else
    return false

def testSupplyFamily : IO Bool := do
  IO.println "test: the fresh* family draws exactly one id each and composes"
  -- fresh_pretty_with_id bakes the drawn id into the description
  let (sp, supP) := fresh_pretty_with_id 700 (fun n => s!"while_{n}")
  let okP ← assertEqual "fresh_pretty_with_id id" (symId sp) 700
  let okP2 ← assertEqual "fresh_pretty_with_id supply" supP 701
  let okP3 ← assertEqual "fresh_pretty_with_id descr"
    (match sp with | Symbol _ _ (SD_Id s) => s | _ => "<not SD_Id>") "while_700"
  -- fresh_given_int is pure (no draw): the explicit-seed builder
  let sg := fresh_given_int 900
  let okG ← assertEqual "fresh_given_int id" (symId sg) 900
  if okP && okP2 && okP3 && okG then
    IO.println "  ✓ PASS"
    return true
  else
    return false

def testMd5Hex : IO Bool := do
  IO.println "test: CerberusFresh.md5Hex matches OCaml Digest.to_hex (RFC 1321 vectors)"
  -- Expected values are OCaml `Digest.to_hex (Digest.string s)` output,
  -- probed 2026-08-19 on this machine's switch (identical to the RFC 1321
  -- appendix A.5 test-suite values):
  --   ""    -> d41d8cd98f00b204e9800998ecf8427e
  --   "abc" -> 900150983cd24fb0d6963f7d28e17f72
  --   "The quick brown fox jumps over the lazy dog"
  --         -> 9e107d9d372bb6826bd81d3542a419d6
  let ok1 ← assertEqual "md5(\"\")" (CerberusFresh.md5Hex "")
              "d41d8cd98f00b204e9800998ecf8427e"
  let ok2 ← assertEqual "md5(\"abc\")" (CerberusFresh.md5Hex "abc")
              "900150983cd24fb0d6963f7d28e17f72"
  let ok3 ← assertEqual "md5(fox)"
              (CerberusFresh.md5Hex "The quick brown fox jumps over the lazy dog")
              "9e107d9d372bb6826bd81d3542a419d6"
  -- padding/block coverage (comment corrected per arc-5 audit 2, F5):
  --   a-z is 26 bytes — single padded block (tail_len = 64 in
  --     native/md5.c:111);
  --   A-Za-z0-9 is 62 bytes — < 64 so it never enters the main block
  --     loop, but its remainder ≥ 56 forces the TWO-block padding path
  --     (tail_len = 128, md5.c:111/116-117);
  --   the 80-byte digits vector (RFC 1321 A.5) is the only one that
  --     exercises the ≥64-byte MAIN loop (`while (n >= 64)`,
  --     md5.c:102-105) — one full block plus a 16-byte tail.
  -- RFC 1321 A.5: alphabet, A-Za-z0-9, and digits-x8 vectors
  let ok4 ← assertEqual "md5(a-z)" (CerberusFresh.md5Hex "abcdefghijklmnopqrstuvwxyz")
              "c3fcd3d76192e4007dfb496cca67e13b"
  let ok5 ← assertEqual "md5(A-Za-z0-9)"
              (CerberusFresh.md5Hex "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
              "d174ab98d277d9f5a5611c2c9f419d9f"
  let ok6 ← assertEqual "md5(digits x8)"
              (CerberusFresh.md5Hex
                "12345678901234567890123456789012345678901234567890123456789012345678901234567890")
              "57edf4a22be3c955ac49da2e2107b67a"
  if ok1 && ok2 && ok3 && ok4 && ok5 && ok6 then
    IO.println "  ✓ PASS"
    return true
  else
    return false

def testDigestGlobal : IO Bool := do
  IO.println "test: per-TU digest global (set/get + Symbol.fresh pickup + armoring)"
  -- init state mirrors util/cerb_fresh.ml:7-10 (ref "")
  let d0 ← CerberusFresh.digestIO ()
  let ok0 ← assertEqual "initial digest" d0 ""
  -- Symbol.fresh must pick up the CURRENT digest at each draw
  -- (symbol.lem: Symbol (digest()) id SD_None). Two draws under
  -- different set_digest values must carry different digests — this is
  -- exactly the CSE/startup-freeze hazard the never_extract armoring in
  -- CerberusFresh.lean guards against (a frozen `digest ()` returns ""
  -- or the first value for both). The supply argument is now explicit
  -- (C1), but the DIGEST read inside fresh remains ambient — the
  -- barrier discipline is unchanged.
  -- The draws are IO-positioned via CerberusFresh.forceIO — a plain pure
  -- `let s1 := fresh 0 ()` here gets let-SUNK to its first use (below
  -- both sets) and observes dB for both draws (empirically confirmed on
  -- the pre-C1 form of this test). The multi-TU pipeline loop
  -- (Main.lean) uses the same barrier around each per-TU stage.
  let dA := CerberusFresh.md5Hex "tu-A"
  let dB := CerberusFresh.md5Hex "tu-B"
  let _ ← (CerberusFresh.setDigestIO dA : BaseIO Unit)
  let s1 ← (CerberusFresh.forceIO (fun () => (fresh 0 ()).1) : BaseIO sym)
  let _ ← (CerberusFresh.setDigestIO dB : BaseIO Unit)
  let s2 ← (CerberusFresh.forceIO (fun () => (fresh 1 ()).1) : BaseIO sym)
  let ok1 ← assertEqual "digest of fresh under A" (digest_of_sym s1) dA
  let ok2 ← assertEqual "digest of fresh under B" (digest_of_sym s2) dB
  let ok3 ← assertEqual "cross-TU from_same_translation_unit"
              (from_same_translation_unit s1 s2) false
  let s3 ← (CerberusFresh.forceIO (fun () => (fresh 2 ()).1) : BaseIO sym)
  let ok4 ← assertEqual "same-TU from_same_translation_unit"
              (from_same_translation_unit s2 s3) true
  -- restore the pristine "" for any later test
  let _ ← (CerberusFresh.setDigestIO "" : BaseIO Unit)
  if ok0 && ok1 && ok2 && ok3 && ok4 then
    IO.println "  ✓ PASS"
    return true
  else
    return false

def main : IO UInt32 := do
  let mut passed := 0
  let mut failed := 0
  for test in [testSupplyThreading, testSupplyFamily, testMd5Hex, testDigestGlobal] do
    if ← test then
      passed := passed + 1
    else
      failed := failed + 1
  IO.println s!"\n{passed} passed, {failed} failed"
  return if failed == 0 then 0 else 1
