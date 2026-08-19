/-
  Test: Symbol.fresh and CerberusFresh.fresh_int generate unique values.

  Lean 4.29 CSEs pure opaque functions. This test verifies the fix using
  Lem's `effectful` annotation + `runEffectful (fun () => ...)` — each
  call should return a different value.
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

def testFreshInt : IO Bool := do
  IO.println "test: CerberusFresh.fresh_int generates unique values"
  -- fresh_int has target_rep `fresh_int u = CerberusFresh.freshIntIO u`
  -- with `effectful` annotation, generated code wraps in runEffectful thunks
  let n1 := runEffectful (fun () => CerberusFresh.freshIntIO ())
  let n2 := runEffectful (fun () => CerberusFresh.freshIntIO ())
  let n3 := runEffectful (fun () => CerberusFresh.freshIntIO ())
  IO.println s!"  got: {n1}, {n2}, {n3}"
  let ok12 ← assertNotEqual "n1 vs n2" n1 n2
  let ok23 ← assertNotEqual "n2 vs n3" n2 n3
  let ok13 ← assertNotEqual "n1 vs n3" n1 n3
  if ok12 && ok23 && ok13 then
    IO.println "  ✓ PASS"
    return true
  else
    return false

def testSymbolFresh : IO Bool := do
  IO.println "test: Symbol.fresh generates unique symbols"
  -- Symbol.fresh is generated from symbol.lem and internally calls
  -- fresh_int via runEffectful. Three calls should give three different IDs.
  let s1 := fresh ()
  let s2 := fresh ()
  let s3 := fresh ()
  let id : sym → Nat := fun | Symbol _ n _ => n
  let n1 := id s1
  let n2 := id s2
  let n3 := id s3
  IO.println s!"  got: Symbol(_, {n1}, _), Symbol(_, {n2}, _), Symbol(_, {n3}, _)"
  let ok12 ← assertNotEqual "s1 vs s2" n1 n2
  let ok23 ← assertNotEqual "s2 vs s3" n2 n3
  let ok13 ← assertNotEqual "s1 vs s3" n1 n3
  if ok12 && ok23 && ok13 then
    IO.println "  ✓ PASS"
    return true
  else
    return false

def assertEqual {α : Type} [BEq α] [Repr α] (label : String) (got expected : α) : IO Bool := do
  if got == expected then
    return true
  else
    IO.println s!"  ✗ FAIL {label}: got {repr got}, expected {repr expected}"
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
  -- multi-block coverage: 56-byte and >64-byte inputs exercise the
  -- two-block padding path (tail_len = 128 in native/md5.c);
  -- RFC 1321 A.5: alphabet and A-Za-z0-9 vectors
  let ok4 ← assertEqual "md5(a-z)" (CerberusFresh.md5Hex "abcdefghijklmnopqrstuvwxyz")
              "c3fcd3d76192e4007dfb496cca67e13b"
  let ok5 ← assertEqual "md5(A-Za-z0-9)"
              (CerberusFresh.md5Hex "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
              "d174ab98d277d9f5a5611c2c9f419d9f"
  if ok1 && ok2 && ok3 && ok4 && ok5 then
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
  -- (symbol.lem:238: Symbol (digest()) (fresh_int()) SD_None). Two draws
  -- under different set_digest values must carry different digests — this
  -- is exactly the CSE/startup-freeze hazard the never_extract armoring
  -- in CerberusFresh.lean guards against (a frozen `digest ()` returns ""
  -- or the first value for both).
  -- The draws are IO-positioned via CerberusFresh.forceIO — a plain pure
  -- `let s1 := fresh ()` here gets let-SUNK to its first use (below both
  -- sets) and observes dB for both draws (empirically confirmed: the
  -- first build of this test, without forceIO, failed exactly that way).
  -- The multi-TU pipeline loop (Main.lean) uses the same barrier around
  -- each per-TU stage.
  let dA := CerberusFresh.md5Hex "tu-A"
  let dB := CerberusFresh.md5Hex "tu-B"
  let _ ← (CerberusFresh.setDigestIO dA : BaseIO Unit)
  let s1 ← (CerberusFresh.forceIO (fun () => fresh ()) : BaseIO sym)
  let _ ← (CerberusFresh.setDigestIO dB : BaseIO Unit)
  let s2 ← (CerberusFresh.forceIO (fun () => fresh ()) : BaseIO sym)
  let ok1 ← assertEqual "digest of fresh under A" (digest_of_sym s1) dA
  let ok2 ← assertEqual "digest of fresh under B" (digest_of_sym s2) dB
  let ok3 ← assertEqual "cross-TU from_same_translation_unit"
              (from_same_translation_unit s1 s2) false
  let s3 ← (CerberusFresh.forceIO (fun () => fresh ()) : BaseIO sym)
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
  for test in [testFreshInt, testSymbolFresh, testMd5Hex, testDigestGlobal] do
    if ← test then
      passed := passed + 1
    else
      failed := failed + 1
  IO.println s!"\n{passed} passed, {failed} failed"
  return if failed == 0 then 0 else 1
