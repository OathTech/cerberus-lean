-- G6 (semantics register): CoreParser symbol identity is a 64-bit string
-- hash (mkSym name := Symbol "" name.hash.toNat (SD_Id name)) with NO
-- collision tripwire — probabilistic injectivity, not an invariant.
--
-- Lean's String.hash is MurmurHash64A(seed=11); collisions are therefore
-- CONSTRUCTIBLE (not merely probable). The two identifier-charset names
-- below were computed to collide (kernel-checkable: both `.hash` values
-- are equal), and `internSym`/`equal_sym` then treat them as THE SAME
-- symbol — a silent conflation of two distinct Core-text identifiers.
--
-- This probe is run by scripts/test_immaculate.sh. Its HONEST S0 baseline
-- is CONFLATED (the bug is present today): symbols_equal=true on distinct
-- names. The S1 fix (an intern-time duplicate-(digest,num)-with-distinct-
-- name fail-stop, like the CERB_FRESH_BASE floor probe) FLIPS this: after
-- the fix, interning the second colliding name fail-stops loudly instead
-- of silently conflating, so this probe's status moves off CONFLATED and
-- the baseline is deliberately re-recorded.
import CoreParser
import Symbol
open CoreParser

/-- Two distinct identifier-charset names with equal MurmurHash64A(11).
    Generated 2026-08-22 (S0); verified in-Lean that `a.hash == b.hash`. -/
def collideA : String := "a2Y2lRtxcnw7gCu0"
def collideB : String := "nXUI8CT9H1nBRpNL"

def main : IO Unit := do
  let sa := internSym collideA
  let sb := internSym collideB
  let namesDistinct := collideA != collideB
  let hashCollide := collideA.hash == collideB.hash
  let symbolsEqual := equal_sym sa sb
  IO.println s!"names_distinct={namesDistinct} hash_collide={hashCollide}"
  IO.println s!"symbols_equal={symbolsEqual}"
  -- Machine-readable status line for the lane script:
  --   CONFLATED = the bug is live (distinct names, colliding hash, equal symbols)
  --   TRIPWIRE  = a fix is in place (interning would have fail-stopped before here)
  if namesDistinct && hashCollide && symbolsEqual then
    IO.println "G6_STATUS=CONFLATED"
  else if namesDistinct && hashCollide && !symbolsEqual then
    IO.println "G6_STATUS=DISTINGUISHED"
  else
    IO.println "G6_STATUS=UNEXPECTED"
