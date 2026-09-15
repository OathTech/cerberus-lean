/-
  CerbParserProgress — the PROGRESS hypothesis of the two parser workers measured
  under a hypothesis, `Monadic_parsing.many_run` / `many1_run` (parser-progress-
  measure slice, 2026-09-15; docs/2026-09-11_parser-progress-measure-record.md;
  the mechanism is lem-lean's `declare {lean} fuel_measure val f = `μ` assuming
  `H``, the C4 route, docs/2026-09-05_fuel-parameter-C4-record.md).

  `many`/`many1` (frontend/model/monadic_parsing.lem) are restated as input-
  indexed recursion: `many_run p cs` / `many1_run p cs` descend the input `cs`,
  one result `(a, cs')` of `parse p cs` per two hops (`many_run cs → many1_run cs
  → many_run cs'`). When `p` CONSUMES — every result of `parse p cs` leaves a
  strictly shorter rest — the block's depth from `many_run p cs` is at most
  `2 * cs.length + 2` and from `many1_run p cs` at most `2 * cs.length + 1`: the
  two measures in the .lem declares (sufficiency: Monadic_parsing_lemMeasureProofs).

  THE INVARIANT the register (scripts/fuel_hypotheses.txt) cites: every parser
  passed to `many`/`many1` on the exec path consumes at least one character on
  every success — formatted.lem:90 and :97 `many digit` (`digit` :83-85 =
  `char #'0' <|> nonzero`, `nonzero` :66-79 a `sat`), :103 `many (char #'-' <|>
  char #'+' <|> char #' ' <|> char #'#' <|> char #'0')`, :170-171 `many ((many1
  (sat (fun z -> z <> #'%')) >>= …) <|> (conversionSpecification >>= …))` — the
  left alternative is a `many1` of a consuming `sat`, the right begins with
  `char #'%'` (conversionSpecification :152-153) followed by parsers that never
  lengthen the input. `sat`/`char`/`item` consume exactly one character on
  success (monadic_parsing.lem:39-43, :65-74). The predicates below are the
  hypothesis vocabulary; the theorems discharging them for the call-site parsers
  are in the same file (D4 of the record). A non-consuming `p` is OUTSIDE the
  hypothesis: the measured wrapper then may EXHAUST (the loud sentinel) exactly
  where the OCaml recursion never returns.

  MIRROR-OCAML NOTE: a Lean-target reasoning artifact; no OCaml text corresponds
  (fuel is a Lean-target artifact). Props over the generated parser type, stated
  by result membership (no comparator, no executable content).
-/

import Monadic_parsing

set_option autoImplicit false

namespace CerbParserProgress

/-- `p` consumes: every result `(x, rest)` of `parse p cs` has `rest` strictly
    shorter than `cs`. The hypothesis of the `many_run`/`many1_run` measures. -/
def Consumes {a : Type} (p : parserM a) : Prop :=
  ∀ (cs : List Char) (r : a × List Char), r ∈ parse p cs → r.2.length < cs.length

/-- `p` never lengthens the input: every result's rest is at most as long as the
    input. Closed under every combinator of the module (D4); `Consumes p →
    NonExpanding p`. -/
def NonExpanding {a : Type} (p : parserM a) : Prop :=
  ∀ (cs : List Char) (r : a × List Char), r ∈ parse p cs → r.2.length ≤ cs.length

theorem nonExpanding_of_consumes {a : Type} (p : parserM a) (h : Consumes p) :
    NonExpanding p :=
  fun cs r hr => Nat.le_of_lt (h cs r hr)

end CerbParserProgress
