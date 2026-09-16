/-
  Test: the `many`/`many1` restatement is the same parser (parser-progress-measure slice,
  2026-09-15; record docs/2026-09-11_parser-progress-measure-record.md D4.2).

  The OLD generated workers (lean_frontend/generated/Monadic_parsing.lean before D1, verbatim modulo whitespace
  up to the namespace and the `_old` names) are kept here and related to the NEW input-indexed
  workers `many_run_lemFuel`/`many1_run_lemFuel` by two kernel theorems:

  * `restatement_of_sentinel`: for EVERY fuel `n`, parser `p` and input `cs`, under the ONE
    hypothesis that the two sentinels run alike (`parse (fuelExhausted (ParserM fun _ => []))
    cs = fuelExhausted []`) — the only difference between the formulations; LemLib's
    `fuelExhaustedWith` is `opaque`, so this cannot be discharged and is not vacuous — the
    two recursions agree hop for hop.
  * `restatement_under_measure`: under `Consumes p`, at any fuel ≥ the measure (where no
    sentinel is reached), the old worker's parse IS the new worker's result — in particular
    `parse (many_old_lemFuel (2 * cs.length + 2) p) cs = many_run p cs = parse (many p) cs`.

  Compile-time proofs; main reports success at runtime. No program literals; no
  enumeration ([USER 2026-09-08]: nothing new out of policy).
-/
import Monadic_parsing
import CerbParserProgress
import Monadic_parsing_lemMeasureProofs

set_option autoImplicit false

namespace ManyRestatement

/-! ### The OLD workers, verbatim modulo whitespace (D1's before-text; `_old` inserted in the names) -/
mutual
 def many_old_lemFuel {a : Type} (lemFuel : Nat) (p : parserM a) : parserM (List a) := match lemFuel with
  | 0 => (fuelExhausted (ParserM (fun _ => [])))
  | Nat.succ lemFuel => ( ParserM (fun (cs : List (Char)) => match parse (parse_mplus ((many1_old_lemFuel lemFuel) p) (parse_return [])) cs with | [] => [] | ( x :: _) => [x]
  ))
def many1_old_lemFuel {a : Type} (lemFuel : Nat) (p : parserM a) : parserM (List a) := match lemFuel with
  | 0 => (fuelExhausted (ParserM (fun _ => [])))
  | Nat.succ lemFuel => ( parse_bind
  p (fun (a1 : a) => parse_bind
  ((many_old_lemFuel lemFuel) p) (fun (_as : List a) =>
  parse_return (a1 :: _as))))
end

/-- `concatMap (fun x -> [g x]) = map g` — the one list identity of D1's argument
    (`>>= return` is a `map`), on the pair shape the workers use (projection form, as `simp`
    leaves the generated tuple-lambdas). -/
theorem flatten_map_singleton_pairs {a : Type} (a1 : a) (l : List (List a × List Char)) :
    List.flatten (List.map (fun (q : List a × List Char) => [(a1 :: q.1, q.2)]) l)
      = List.map (fun (q : List a × List Char) => (a1 :: q.1, q.2)) l := by
  induction l with
  | nil => rfl
  | cons x xs ih => simp [ih]

/-- Hop-for-hop agreement at EVERY fuel, under the sentinel hypothesis. (The two workers'
    head-or-empty `match`es are different auxiliary matchers over the SAME discriminant once the
    induction hypothesis is rewritten in; `split` generalises that discriminant and both reduce.) -/
theorem restatement_of_sentinel {a : Type}
    (h0 : ∀ cs : List Char, parse (fuelExhausted (ParserM (fun _ => []) : parserM (List a))) cs
            = fuelExhausted ([] : List (List a × List Char))) :
    ∀ (n : Nat) (p : parserM a) (cs : List Char),
      parse (many_old_lemFuel n p) cs = many_run_lemFuel n p cs ∧
      parse (many1_old_lemFuel n p) cs = many1_run_lemFuel n p cs := by
  intro n
  induction n with
  | zero =>
    intro p cs
    exact ⟨h0 cs, h0 cs⟩
  | succ n ih =>
    intro p cs
    constructor
    · have ih1 := (ih p cs).2
      simp only [parse] at ih1
      simp only [many_old_lemFuel, many_run_lemFuel, parse, parse_mplus, parse_return]
      rw [ih1]
      split <;> rename_i heq <;> simp [heq]
    · simp only [many1_old_lemFuel, many1_run_lemFuel, parse_bind, parse, parse_return]
      congr 1
      apply List.map_congr_left
      intro q _
      have ih2 := (ih p q.2).1
      simp only [parse] at ih2
      rw [ih2]
      exact flatten_map_singleton_pairs q.1 _

/-- Agreement under `Consumes p` at every fuel ≥ the measure (no sentinel reached). -/
theorem restatement_under_measure_aux {a : Type} (p : parserM a) (hp : CerbParserProgress.Consumes p) (k : Nat) :
    ∀ (cs : List Char) (n : Nat), cs.length ≤ k → 2 * cs.length + 1 ≤ n →
      parse (many1_old_lemFuel n p) cs = many1_run_lemFuel n p cs := by
  induction k with
  | zero =>
    intro cs n hk hn
    cases n with
    | zero => omega
    | succ n =>
      have hcs : cs = [] := List.eq_nil_of_length_eq_zero (by omega)
      subst hcs
      have hn0 := CerbParserProgress.parse_nil_of_consumes p hp
      simp only [parse] at hn0
      simp only [many1_old_lemFuel, many1_run_lemFuel, parse_bind, parse, hn0, List.map_nil,
        List.flatten_nil]
  | succ k ih =>
    intro cs n hk hn
    cases n with
    | zero => omega
    | succ n =>
      simp only [many1_old_lemFuel, many1_run_lemFuel, parse_bind, parse, parse_return]
      congr 1
      apply List.map_congr_left
      intro q hq
      have hlt : q.2.length < cs.length := hp cs q hq
      cases n with
      | zero => omega
      | succ n =>
        simp only [many_old_lemFuel, many_run_lemFuel, parse, parse_mplus, parse_return]
        have ih2 := ih q.2 n (by omega) (by omega)
        simp only [parse] at ih2
        rw [ih2]
        split <;> rename_i heq <;> simp [heq]

theorem restatement_under_measure_many1 {a : Type} (p : parserM a) (hp : CerbParserProgress.Consumes p)
    (cs : List Char) (n : Nat) (hn : 2 * cs.length + 1 ≤ n) :
    parse (many1_old_lemFuel n p) cs = many1_run_lemFuel n p cs :=
  restatement_under_measure_aux p hp cs.length cs n (Nat.le_refl _) hn

theorem restatement_under_measure_many {a : Type} (p : parserM a) (hp : CerbParserProgress.Consumes p)
    (cs : List Char) (n : Nat) (hn : 2 * cs.length + 2 ≤ n) :
    parse (many_old_lemFuel n p) cs = many_run_lemFuel n p cs := by
  cases n with
  | zero => omega
  | succ n =>
    have h := restatement_under_measure_many1 p hp cs n (by omega)
    simp only [parse] at h
    simp only [many_old_lemFuel, many_run_lemFuel, parse, parse_mplus, parse_return]
    rw [h]
    split <;> rename_i heq <;> simp [heq]

/-- The wrapper-level corollaries: the OLD worker at the NEW measure IS the NEW parser. -/
theorem old_at_measure_is_many {a : Type} (p : parserM a) (hp : CerbParserProgress.Consumes p) (cs : List Char) :
    parse (many_old_lemFuel (2 * cs.length + 2) p) cs = parse (many p) cs :=
  restatement_under_measure_many p hp cs _ (Nat.le_refl _)

theorem old_at_measure_is_many1 {a : Type} (p : parserM a) (hp : CerbParserProgress.Consumes p) (cs : List Char) :
    parse (many1_old_lemFuel (2 * cs.length + 1) p) cs = parse (many1 p) cs :=
  restatement_under_measure_many1 p hp cs _ (Nat.le_refl _)

end ManyRestatement

def main : IO UInt32 := do
  IO.println "many-restatement-test: the old many/many1 workers agree with the input-indexed many_run/many1_run (kernel-checked at compile time: hop-for-hop under the sentinel hypothesis at every fuel; unconditionally under Consumes p at fuel ≥ the measure)"
  return 0
