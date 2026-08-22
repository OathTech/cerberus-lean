-- G6 (semantics register): CoreParser symbol identity is a 64-bit string
-- hash (mkSym name := Symbol "" name.hash.toNat (SD_Id name)) —
-- probabilistic injectivity, not an invariant.
--
-- Lean's String.hash is MurmurHash64A(seed=11); collisions are therefore
-- CONSTRUCTIBLE (not merely probable). The two identifier-charset names
-- below were computed to collide (kernel-checkable: both `.hash` values
-- are equal); `internSym` maps them to THE SAME symbol (the raw
-- mechanism — still true by construction, asserted below as the
-- documented residual).
--
-- THE TRIPWIRE (arc-14 S1 F3 flip): CoreParser.parseFile now FAIL-STOPS
-- on any input containing two distinct hash-colliding identifiers
-- (the scanHashCollisions pre-parse scan, CERB_FRESH_BASE floor-probe
-- pattern), so the conflation can never silently enter a parsed
-- CoreFile. This probe:
--   1. verifies the collision pair is real (names distinct, hashes equal);
--   2. verifies parseFile REFUSES an input containing both names
--      (status TRIPWIRE) — before F3 it parsed and conflated (CONFLATED);
--   3. negative control: a collision-free input still parses.
import CoreParser
import Symbol
open CoreParser

/-- Two distinct identifier-charset names with equal MurmurHash64A(11).
    Generated 2026-08-22 (S0); verified in-Lean that `a.hash == b.hash`. -/
def collideA : String := "a2Y2lRtxcnw7gCu0"
def collideB : String := "nXUI8CT9H1nBRpNL"

def main : IO Unit := do
  let namesDistinct := collideA != collideB
  let hashCollide := collideA.hash == collideB.hash
  IO.println s!"names_distinct={namesDistinct} hash_collide={hashCollide}"
  -- The raw mkSym mechanism still conflates (documented residual: the
  -- tripwire guards every parseFile entry, which is where Core-text
  -- symbols are minted).
  let rawConflates := equal_sym (internSym collideA) (internSym collideB)
  IO.println s!"raw_intern_conflates={rawConflates}"
  -- Tripwire leg: an input containing both names must be REFUSED.
  let poisoned := s!"fun {collideA} (): integer := 1 fun {collideB} (): integer := 2"
  let tripwired := match parseFile poisoned with
    | .error e => e.startsWith "SYMBOL-HASH COLLISION"
    | .ok _ => false
  -- Negative control: a collision-free file still parses.
  let controlOk := match parseFile "fun foo (): integer := 1" with
    | .ok cf => cf.funs.length == 1
    | .error _ => false
  IO.println s!"tripwired={tripwired} control_ok={controlOk}"
  if !namesDistinct || !hashCollide then
    IO.println "G6_STATUS=UNEXPECTED"        -- the witness itself broke
  else if !controlOk then
    IO.println "G6_STATUS=FALSE_POSITIVE"    -- tripwire fires on clean input
  else if tripwired then
    IO.println "G6_STATUS=TRIPWIRE"          -- post-F3: fail-stop, no silent conflation
  else if rawConflates then
    IO.println "G6_STATUS=CONFLATED"         -- pre-F3 state: silent conflation
  else
    IO.println "G6_STATUS=UNEXPECTED"
