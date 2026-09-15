/-
  Monadic_parsing_lemMeasureProofs — the sufficiency proofs of the two `fuel_measure`
  obligations of frontend/model/monadic_parsing.lem (parser-progress-measure slice,
  2026-09-15; docs/2026-09-11_parser-progress-measure-record.md), both HYPOTHESIS-
  CARRYING (lem-lean `assuming`, doc/lean-backend/2026-09-05_measure-hypothesis-record.md):

    many_run    measure `2 * List.length cs + 2`   assuming `CerbParserProgress.Consumes p`
    many1_run   measure `2 * List.length cs + 1`   assuming `CerbParserProgress.Consumes p`

  The block is mutual (one shared counter, measured all-or-none — lem FM-mutual) and
  descends the INPUT `cs`: `many_run (f+1) p cs` calls `many1_run f p cs` on the SAME
  input; `many1_run (f+1) p cs` calls `many_run f p cs'` once per result `(a, cs')` of
  `parse p cs`. Under `Consumes p` every such `cs'` is strictly shorter, so two hops
  consume at least one character and the bounds above suffice — the hypothesis is used
  exactly there (a non-consuming `p` makes the OCaml recursion loop and the Lean counter
  run out: the loud sentinel). Shape = the C4 template (Formatted_lemMeasureProofs):
  stability above the measure by induction on a bound on the input length, the two fuels
  generalized, the hypothesis threaded; the list traversal by the membership-relative
  congruence `List.map_congr_left`; `CerbParserProgress.parse_nil_of_consumes` closes the empty input. Kernel-only tactics; no option bumps; no `sorry`.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text corresponds
  (fuel is a Lean-target artifact).
-/

import Monadic_parsing
import CerbParserProgress

set_option autoImplicit false

namespace Monadic_parsing_lemMeasureProofs

/-- `many1_run`'s worker is fuel-stable above `2 * cs.length + 1` when `p` consumes
    (induction on a bound `k` on the input length; the inner `many_run` call runs at
    a counter ≥ `2 * cs'.length + 2` on a strictly shorter `cs'`). -/
theorem many1_run_stable_aux {a : Type} (k : Nat) :
    ∀ (p : parserM a) (cs : List Char) (f g : Nat), CerbParserProgress.Consumes p →
      cs.length ≤ k → 2 * cs.length + 1 ≤ f → 2 * cs.length + 1 ≤ g →
      many1_run_lemFuel f p cs = many1_run_lemFuel g p cs := by
  induction k with
  | zero =>
    intro p cs f g hp hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        have hcs : cs = [] := List.eq_nil_of_length_eq_zero (by omega)
        subst hcs
        simp only [many1_run_lemFuel, CerbParserProgress.parse_nil_of_consumes p hp, List.map_nil, List.flatten_nil]
  | succ k ih =>
    intro p cs f g hp hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [many1_run_lemFuel]
        congr 1
        apply List.map_congr_left
        intro q hq
        obtain ⟨a1, cs'⟩ := q
        have hlt : cs'.length < cs.length := hp cs (a1, cs') hq
        dsimp only
        cases f with
        | zero => omega
        | succ f =>
          cases g with
          | zero => omega
          | succ g =>
            simp only [many_run_lemFuel]
            rw [ih p cs' f g hp (by omega) (by omega) (by omega)]

/-- `many_run`'s worker is fuel-stable above `2 * cs.length + 2`: one hop to
    `many1_run` on the same input at a counter ≥ `2 * cs.length + 1`. -/
theorem many_run_stable_aux {a : Type} (p : parserM a) (cs : List Char) (f g : Nat)
    (hp : CerbParserProgress.Consumes p) (hf : 2 * cs.length + 2 ≤ f) (hg : 2 * cs.length + 2 ≤ g) :
    many_run_lemFuel f p cs = many_run_lemFuel g p cs := by
  cases f with
  | zero => omega
  | succ f =>
    cases g with
    | zero => omega
    | succ g =>
      simp only [many_run_lemFuel]
      rw [many1_run_stable_aux cs.length p cs f g hp (Nat.le_refl _) (by omega) (by omega)]

/-- THE OBLIGATION, exactly as the generated `Monadic_parsing_auxiliary` shell states
    and delegates it (the `lemHyp` binder in the `assuming` position). -/
theorem many_run_measure_sufficient {a : Type} (p : parserM a) (cs : List Char)
    (lemHyp : CerbParserProgress.Consumes p) (lemFuel : Nat)
    (lemMeasureLe : 2 * List.length cs + 2 ≤ lemFuel) :
    many_run_lemFuel lemFuel p cs = many_run p cs :=
  many_run_stable_aux p cs lemFuel (2 * List.length cs + 2) lemHyp lemMeasureLe (Nat.le_refl _)

/-- THE OBLIGATION for the mutual sibling. -/
theorem many1_run_measure_sufficient {a : Type} (p : parserM a) (cs : List Char)
    (lemHyp : CerbParserProgress.Consumes p) (lemFuel : Nat)
    (lemMeasureLe : 2 * List.length cs + 1 ≤ lemFuel) :
    many1_run_lemFuel lemFuel p cs = many1_run p cs :=
  many1_run_stable_aux cs.length p cs lemFuel (2 * List.length cs + 1) lemHyp (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Monadic_parsing_lemMeasureProofs
