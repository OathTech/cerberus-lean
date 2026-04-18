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

def main : IO UInt32 := do
  let mut passed := 0
  let mut failed := 0
  for test in [testFreshInt, testSymbolFresh] do
    if ← test then
      passed := passed + 1
    else
      failed := failed + 1
  IO.println s!"\n{passed} passed, {failed} failed"
  return if failed == 0 then 0 else 1
