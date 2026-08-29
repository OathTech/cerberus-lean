/-
  RelSem.M1Statement — spot-audit F3 fix (2026-08-29): THE m1
  STATEMENT TEXT, homed STATEMENT-SIDE.

  The V3a PERF-2 tightened-exit program's statement (m1_sgn — record
  docs/2026-08-29_v3a-loops-mechC.md §2) previously lived inside the
  proof module RelSem/M1Proof.lean and was ABSENT from the statement
  gate's slate (spot-audit F3). Registration requires the statement's
  vocabulary to be statement-clean, so — following the corpus
  pattern (RelSem/CorpusStatements.lean over RelSem/CorpusFiles.lean,
  exactly how P01Statement references p01File) — the statement text
  (`sgnSpec`, `M1Statement`) moves here and its fixture data
  (`m1File`, `m1Prior`) moves to RelSem/CorpusFiles.lean; all def
  texts byte-preserved modulo the move, names unchanged
  (`RelSem.M1.*`). No Iris/proof-layer imports in this module.
  Registered in the Audit slate (statement-TCB + concrete-input
  gates); no UBFree twin exists for m1 (the Cns adequacy face's
  Active conjunct is the exit instrument's whole demand).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.CorpusStatements

set_option autoImplicit false

namespace RelSem.M1

open RelSem RelSem.Cerb RelSem.Corpus
open RelSem.T1 (intRange)

/-- m1's pure model: sgn(x). -/
def sgnSpec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value
    = intValue (if x < 0 then -1 else if 0 < x then 1 else 0)

/-- **M1 (sgn)** — the canonical property at the house Cns shape:
    ∀ x ∈ intRange, every consistent outcome of callND(sgn, [x]) is
    Specified (sgn x). (The PERF-2 exit's target; a V3a exit
    instrument in the corpus statement SHAPE, not a frozen-corpus
    row.) HONESTY LABEL: PROVED (V3a2 2026-08-29 —
    RelSem.M1.m1_proved, RelSem/M1Body.lean; trio cone, pinned
    in-build). -/
def M1Statement : Prop :=
  CorpusEnvHyp →
  ∀ (x : Int), intRange x →
    CallHarnessAdequateCns m1Prior m1File.tagDefs m1File "sgn"
      [intValue x] corpusFs (sgnSpec x)

end RelSem.M1
