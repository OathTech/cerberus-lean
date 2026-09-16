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
  every success — formatted.lem:90 and :97 `many digit` (`digit` :82-84 =
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
import Formatted

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

/-- Under `Consumes p` the empty input has no result (no rest is shorter than `[]`). -/
theorem parse_nil_of_consumes {a : Type} (p : parserM a) (hp : Consumes p) :
    parse p [] = [] := by
  apply List.eq_nil_iff_forall_not_mem.mpr
  intro r hr
  have := hp [] r hr
  simp at this

/-! ## D4.1 — discharging `Consumes` for the exec-path call sites (kernel-checked)

  Every lemma is a direct unfolding of the generated definition it names. lem emits `<|>`
  INLINE at every site (`ParserM (fun cs => match parse (parse_mplus p1 p2) cs with | [] => []
  | x :: _ => [x])`), and two syntactically identical `match` expressions from different
  declarations are NOT definitionally equal (their auxiliary matchers differ) — so no lemma
  stated with a literal `match` can be applied to a generated site. The site proofs therefore
  use `split at hr` on the site's OWN hypothesis and the results-subset lemmas below; the
  parsers passed to `many`/`many1` inside the generated callers are captured by unification
  (`∃ alt k, flags0 = parse_bind (many alt) k ∧ …`), never restated. -/

theorem mem_parse_bind {a b : Type} (p : parserM a) (f : a → parserM b) (cs : List Char)
    (r : b × List Char) (h : r ∈ parse (parse_bind p f) cs) :
    ∃ q ∈ parse p cs, r ∈ parse (f q.1) q.2 := by
  simp only [parse_bind, parse, List.mem_flatten, List.mem_map] at h
  obtain ⟨l, ⟨q, hq, rfl⟩, hr⟩ := h
  obtain ⟨a1, cs'⟩ := q
  exact ⟨(a1, cs'), hq, hr⟩

/-- Bind of a CONSUMING left with a NON-EXPANDING right consumes (the `:170-171` right
    alternative's shape, `conversionSpecification >>= …`). -/
theorem consumes_bind_left {a b : Type} (p : parserM a) (f : a → parserM b)
    (hp : Consumes p) (hf : ∀ x, NonExpanding (f x)) : Consumes (parse_bind p f) := by
  intro cs r hr
  obtain ⟨q, hq, hr'⟩ := mem_parse_bind p f cs r hr
  have h1 : q.2.length < cs.length := hp cs q hq
  have h2 : r.2.length ≤ q.2.length := hf q.1 q.2 r hr'
  omega

theorem nonExpanding_bind {a b : Type} (p : parserM a) (f : a → parserM b)
    (hp : NonExpanding p) (hf : ∀ x, NonExpanding (f x)) : NonExpanding (parse_bind p f) := by
  intro cs r hr
  obtain ⟨q, hq, hr'⟩ := mem_parse_bind p f cs r hr
  have h1 : q.2.length ≤ cs.length := hp cs q hq
  have h2 : r.2.length ≤ q.2.length := hf q.1 q.2 r hr'
  omega

theorem nonExpanding_return {a : Type} (x : a) : NonExpanding (parse_return x) := by
  intro cs r hr
  simp only [parse_return, parse, List.mem_singleton] at hr
  subst hr
  exact Nat.le_refl _

theorem nonExpanding_mzero {a : Type} : NonExpanding (mzero : parserM a) := by
  intro cs r hr
  simp [mzero, parse] at hr

/-- `item` consumes exactly one character on success (monadic_parsing.lem:39-43). -/
theorem consumes_item : Consumes item := by
  intro cs r hr
  cases cs with
  | nil => simp [item, parse] at hr
  | cons c cs' =>
    simp only [item, parse, List.mem_singleton] at hr
    subst hr
    simp

/-- `sat pred` consumes (monadic_parsing.lem:65-68): `item`, then `return`/`mzero`. -/
theorem consumes_sat (pred : Char → Bool) : Consumes (sat pred) := by
  unfold sat
  apply consumes_bind_left _ _ consumes_item
  intro c
  split
  · exact nonExpanding_return c
  · exact nonExpanding_mzero

theorem consumes_parse_char (c : Char) : Consumes (parse_char c) := by
  unfold parse_char
  exact consumes_sat _

theorem consumes_anyChar : Consumes anyChar := by
  unfold anyChar
  exact consumes_sat _

/-- Results-subset transfer: a parser whose results are among those of a consuming parser
    consumes (the head-or-empty of `mplus` is such a subset at every `<|>` site). -/
theorem consumes_of_sub {a : Type} (q q' : parserM a)
    (hsub : ∀ cs r, r ∈ parse q cs → r ∈ parse q' cs) (h : Consumes q') : Consumes q :=
  fun cs r hr => h cs r (hsub cs r hr)

theorem nonExpanding_of_sub {a : Type} (q q' : parserM a)
    (hsub : ∀ cs r, r ∈ parse q cs → r ∈ parse q' cs) (h : NonExpanding q') : NonExpanding q :=
  fun cs r hr => h cs r (hsub cs r hr)

theorem consumes_mplus {a : Type} (p1 p2 : parserM a) (h1 : Consumes p1) (h2 : Consumes p2) :
    Consumes (parse_mplus p1 p2) := by
  intro cs r hr
  simp only [parse_mplus, parse, List.mem_append] at hr
  rcases hr with h | h
  · exact h1 cs r h
  · exact h2 cs r h

theorem nonExpanding_mplus {a : Type} (p1 p2 : parserM a) (h1 : NonExpanding p1) (h2 : NonExpanding p2) :
    NonExpanding (parse_mplus p1 p2) := by
  intro cs r hr
  simp only [parse_mplus, parse, List.mem_append] at hr
  rcases hr with h | h
  · exact h1 cs r h
  · exact h2 cs r h

/-- One inlined `<|>` level, from the cons arm of `split`: the head is a result of one of the
    two alternatives — `p1`, `p2` are read off the concrete `heq` by unification, so the
    generated alternatives are never restated. -/
theorem consumes_head_step {a : Type} (p1 p2 : parserM a) (h1 : Consumes p1) (h2 : Consumes p2)
    (cs : List Char) (x : a × List Char) (xs : List (a × List Char))
    (heq : parse (parse_mplus p1 p2) cs = x :: xs) : x.2.length < cs.length := by
  have hx : x ∈ parse (parse_mplus p1 p2) cs := heq ▸ List.mem_cons_self
  exact consumes_mplus p1 p2 h1 h2 cs x hx

theorem nonExpanding_head_step {a : Type} (p1 p2 : parserM a) (h1 : NonExpanding p1) (h2 : NonExpanding p2)
    (cs : List Char) (x : a × List Char) (xs : List (a × List Char))
    (heq : parse (parse_mplus p1 p2) cs = x :: xs) : x.2.length ≤ cs.length := by
  have hx : x ∈ parse (parse_mplus p1 p2) cs := heq ▸ List.mem_cons_self
  exact nonExpanding_mplus p1 p2 h1 h2 cs x hx

theorem nonExpanding_liftM0 {a b : Type} (f : a → b) (p : parserM a) (hp : NonExpanding p) :
    NonExpanding (liftM0 f p) := by
  intro cs r hr
  simp only [liftM0, parse, List.mem_map] at hr
  obtain ⟨q, hq, rfl⟩ := hr
  obtain ⟨a1, cs'⟩ := q
  exact hp cs (a1, cs') hq

/-- `option x p = p <|> return x` (monadic_parsing.lem:56): head-or-empty of `mplus`. -/
theorem nonExpanding_parse_option {a : Type} (x : a) (p : parserM a) (hp : NonExpanding p) :
    NonExpanding (parse_option x p) := by
  unfold parse_option
  intro cs r hr
  simp only [parse] at hr
  split at hr
  · simp at hr
  · rename_i y ys heq
    simp only [List.mem_singleton] at hr
    subst hr
    exact nonExpanding_head_step _ _ hp (nonExpanding_return x) _ _ _ heq

theorem nonExpanding_optionMaybe {a : Type} (p : parserM a) (hp : NonExpanding p) :
    NonExpanding (optionMaybe p) := by
  unfold optionMaybe
  exact nonExpanding_parse_option _ _ (nonExpanding_liftM0 _ _ hp)

/-- `string l` never lengthens the input (list-structural: `char` then the tail). -/
theorem nonExpanding_string0 (l : List Char) : NonExpanding (string0 l) := by
  induction l with
  | nil => simp only [string0]; exact nonExpanding_return _
  | cons c cs' ih =>
    simp only [string0]
    apply nonExpanding_bind
    · apply nonExpanding_bind
      · exact nonExpanding_of_consumes _ (consumes_parse_char c)
      · intro _; exact ih
    · intro _; exact nonExpanding_return _

/-! ### `many1`/`many` under `Consumes p`: every result of `many1_run` is strictly shorter,
    every result of `many_run` at most as long — at any counter ≥ the measure (the sentinel is
    never reached), by induction on a bound on the input length. -/

theorem many1_run_lemFuel_lt_aux {a : Type} (k : Nat) :
    ∀ (p : parserM a) (cs : List Char) (f : Nat), Consumes p → cs.length ≤ k →
      2 * cs.length + 1 ≤ f → ∀ r ∈ many1_run_lemFuel f p cs, r.2.length < cs.length := by
  induction k with
  | zero =>
    intro p cs f hp hk hf r hr
    cases f with
    | zero => omega
    | succ f =>
      have hcs : cs = [] := List.eq_nil_of_length_eq_zero (by omega)
      subst hcs
      simp only [many1_run_lemFuel, parse_nil_of_consumes p hp, List.map_nil, List.flatten_nil] at hr
      exact absurd hr List.not_mem_nil
  | succ k ih =>
    intro p cs f hp hk hf r hr
    cases f with
    | zero => omega
    | succ f =>
      simp only [many1_run_lemFuel, List.mem_flatten, List.mem_map] at hr
      obtain ⟨l, ⟨q, hq, rfl⟩, hr⟩ := hr
      obtain ⟨a1, cs'⟩ := q
      have hlt : cs'.length < cs.length := hp cs (a1, cs') hq
      simp only [List.mem_map] at hr
      obtain ⟨q', hq', rfl⟩ := hr
      obtain ⟨_as, cs''⟩ := q'
      show cs''.length < cs.length
      cases f with
      | zero => omega
      | succ f =>
        simp only [many_run_lemFuel] at hq'
        have hmem : (_as, cs'') ∈ many1_run_lemFuel f p cs' ++ [([], cs')] := by
          split at hq'
          · simp at hq'
          · rename_i x xs heq
            simp only [List.mem_singleton] at hq'
            subst hq'
            exact heq ▸ List.mem_cons_self
        rw [List.mem_append, List.mem_singleton] at hmem
        rcases hmem with h | h
        · have h3 : cs''.length < cs'.length := ih p cs' f hp (by omega) (by omega) _ h
          omega
        · have h2 : cs'' = cs' := (Prod.mk.inj h).2
          rw [h2]
          exact hlt

theorem many_run_lemFuel_le_aux {a : Type} (p : parserM a) (cs : List Char) (f : Nat)
    (hp : Consumes p) (hf : 2 * cs.length + 2 ≤ f) :
    ∀ r ∈ many_run_lemFuel f p cs, r.2.length ≤ cs.length := by
  intro r hr
  cases f with
  | zero => omega
  | succ f =>
    simp only [many_run_lemFuel] at hr
    have hmem : r ∈ many1_run_lemFuel f p cs ++ [([], cs)] := by
      split at hr
      · simp at hr
      · rename_i x xs heq
        simp only [List.mem_singleton] at hr
        subst hr
        exact heq ▸ List.mem_cons_self
    rw [List.mem_append, List.mem_singleton] at hmem
    rcases hmem with h | h
    · exact Nat.le_of_lt (many1_run_lemFuel_lt_aux cs.length p cs f hp (Nat.le_refl _) (by omega) r h)
    · subst h; exact Nat.le_refl _

/-- `many1 p` consumes when `p` does (formatted.lem:171 passes `many1 (sat …)` to a `<|>`). -/
theorem consumes_many1 {a : Type} (p : parserM a) (hp : Consumes p) : Consumes (many1 p) := by
  intro cs r hr
  simp only [many1, many1_run, parse] at hr
  exact many1_run_lemFuel_lt_aux cs.length p cs _ hp (Nat.le_refl _) (Nat.le_refl _) r hr

/-- `many p` never lengthens the input when `p` consumes. -/
theorem nonExpanding_many {a : Type} (p : parserM a) (hp : Consumes p) : NonExpanding (many p) := by
  intro cs r hr
  simp only [many, many_run, parse] at hr
  exact many_run_lemFuel_le_aux p cs _ hp (Nat.le_refl _) r hr

/-! ### The four call sites (formatted.lem:90, :97, :103, :170-171).
    A generated caller's structure is pinned by `rfl` with the parser passed to `many`/`many1`
    captured by unification; the captured parser is then proved to consume by peeling its
    inlined `<|>` levels with `split at hr`. -/

theorem consumes_nonzero : Consumes nonzero := by
  unfold nonzero
  exact consumes_sat _

/-- formatted.lem:82-84 `digit = char #'0' <|> nonzero` — the parser of `:90` and `:97`. -/
theorem consumes_digit : Consumes digit := by
  unfold digit
  intro cs r hr
  simp only [parse] at hr
  split at hr
  · simp at hr
  · rename_i x xs heq
    simp only [List.mem_singleton] at hr
    subst hr
    exact consumes_head_step _ _ (consumes_parse_char '0') consumes_nonzero _ _ _ heq

/-- `:90`: `nonnegativeDecimalInteger` is `nonzero >>= fun c -> many digit >>= fun cs -> return …`
    (by `rfl`; the continuation's shape is captured, so its non-expansion is immediate). -/
theorem nonnegativeDecimalInteger_passes_digit :
    ∃ g : Char → List Char → Nat,
      nonnegativeDecimalInteger =
        parse_bind nonzero (fun c => parse_bind (many digit) (fun cs => parse_return (g c cs))) :=
  ⟨_, rfl⟩

/-- `:97`: `decimalInteger` is `many digit >>= fun cs -> return …` (by `rfl`). -/
theorem decimalInteger_passes_digit :
    ∃ g : List Char → Nat, decimalInteger = parse_bind (many digit) (fun cs => parse_return (g cs)) :=
  ⟨_, rfl⟩

/-- `:103`: `flags` is `many ALT >>= fun xs -> return …` for the generated alternative `ALT`
    (captured by unification), and `ALT` consumes — four nested `<|>` levels over `char`s,
    peeled by `split` on each level's own hypothesis. -/
theorem flags0_passes_consuming :
    ∃ (alt : parserM Char) (mk : List Char → flags),
      flags0 = parse_bind (many alt) (fun xs => parse_return (mk xs)) ∧ Consumes alt :=
  ⟨_, _, rfl, by
    repeat' first
      | with_reducible exact consumes_parse_char _
      | (intro cs r hr
         simp only [parse] at hr
         split at hr
         · simp at hr
         rename_i x xs heq
         simp only [List.mem_singleton] at hr
         subst hr
         refine consumes_head_step _ _ ?_ ?_ _ _ _ heq)⟩

theorem nonExpanding_flags0 : NonExpanding flags0 := by
  obtain ⟨alt, mk, heq, halt⟩ := flags0_passes_consuming
  rw [heq]
  exact nonExpanding_bind _ _ (nonExpanding_many _ halt) (fun _ => nonExpanding_return _)

theorem nonExpanding_nonnegativeDecimalInteger : NonExpanding nonnegativeDecimalInteger := by
  obtain ⟨g, heq⟩ := nonnegativeDecimalInteger_passes_digit
  rw [heq]
  exact nonExpanding_bind _ _ (nonExpanding_of_consumes _ consumes_nonzero)
    (fun _ => nonExpanding_bind _ _ (nonExpanding_many _ consumes_digit) (fun _ => nonExpanding_return _))

theorem nonExpanding_decimalInteger : NonExpanding decimalInteger := by
  obtain ⟨g, heq⟩ := decimalInteger_passes_digit
  rw [heq]
  exact nonExpanding_bind _ _ (nonExpanding_many _ consumes_digit) (fun _ => nonExpanding_return _)

/-! The four printf sub-parsers after `char #'%'` never lengthen the input: each is a chain of
    inlined `<|>` over `char`/`string`/`return` binds (and the two decimal parsers). One driver
    peels binds and `<|>` levels (`split` on each level's own hypothesis) and closes the leaves
    syntactically (`with_reducible`: no unfolding of the leaf constants). -/

theorem nonExpanding_fieldWidth : NonExpanding fieldWidth := by
  unfold fieldWidth
  repeat' first
    | with_reducible exact nonExpanding_of_consumes _ (consumes_parse_char _)
    | with_reducible exact nonExpanding_string0 _
    | with_reducible exact nonExpanding_return _
    | with_reducible exact nonExpanding_nonnegativeDecimalInteger
    | with_reducible exact nonExpanding_decimalInteger
    | with_reducible refine nonExpanding_bind _ _ ?_ (fun _ => ?_)
    | (intro cs r hr
       simp only [parse] at hr
       split at hr
       · simp at hr
       rename_i x xs heq
       simp only [List.mem_singleton] at hr
       subst hr
       refine nonExpanding_head_step _ _ ?_ ?_ _ _ _ heq)

theorem nonExpanding_output_precision : NonExpanding output_precision := by
  unfold output_precision
  repeat' first
    | with_reducible exact nonExpanding_of_consumes _ (consumes_parse_char _)
    | with_reducible exact nonExpanding_string0 _
    | with_reducible exact nonExpanding_return _
    | with_reducible exact nonExpanding_nonnegativeDecimalInteger
    | with_reducible exact nonExpanding_decimalInteger
    | with_reducible refine nonExpanding_bind _ _ ?_ (fun _ => ?_)
    | (intro cs r hr
       simp only [parse] at hr
       split at hr
       · simp at hr
       rename_i x xs heq
       simp only [List.mem_singleton] at hr
       subst hr
       refine nonExpanding_head_step _ _ ?_ ?_ _ _ _ heq)

theorem nonExpanding_lengthModifier : NonExpanding lengthModifier := by
  unfold lengthModifier
  repeat' first
    | with_reducible exact nonExpanding_of_consumes _ (consumes_parse_char _)
    | with_reducible exact nonExpanding_string0 _
    | with_reducible exact nonExpanding_return _
    | with_reducible exact nonExpanding_nonnegativeDecimalInteger
    | with_reducible exact nonExpanding_decimalInteger
    | with_reducible refine nonExpanding_bind _ _ ?_ (fun _ => ?_)
    | (intro cs r hr
       simp only [parse] at hr
       split at hr
       · simp at hr
       rename_i x xs heq
       simp only [List.mem_singleton] at hr
       subst hr
       refine nonExpanding_head_step _ _ ?_ ?_ _ _ _ heq)

theorem nonExpanding_conversionSpecifier : NonExpanding conversionSpecifier := by
  unfold conversionSpecifier
  repeat' first
    | with_reducible exact nonExpanding_of_consumes _ (consumes_parse_char _)
    | with_reducible exact nonExpanding_string0 _
    | with_reducible exact nonExpanding_return _
    | with_reducible exact nonExpanding_nonnegativeDecimalInteger
    | with_reducible exact nonExpanding_decimalInteger
    | with_reducible refine nonExpanding_bind _ _ ?_ (fun _ => ?_)
    | (intro cs r hr
       simp only [parse] at hr
       split at hr
       · simp at hr
       rename_i x xs heq
       simp only [List.mem_singleton] at hr
       subst hr
       refine nonExpanding_head_step _ _ ?_ ?_ _ _ _ heq)

/-- formatted.lem:152-165: `char #'%'` first (consuming), then parsers that never lengthen the
    input — the `:170-171` right alternative's parser consumes. -/
theorem consumes_conversionSpecification : Consumes conversionSpecification := by
  unfold conversionSpecification
  apply consumes_bind_left
  · exact consumes_bind_left _ _ (consumes_parse_char '%') (fun _ => nonExpanding_flags0)
  · intro _
    repeat' first
      | with_reducible exact nonExpanding_return _
      | with_reducible exact nonExpanding_conversionSpecifier
      | with_reducible exact nonExpanding_optionMaybe _ nonExpanding_fieldWidth
      | with_reducible exact nonExpanding_optionMaybe _ nonExpanding_output_precision
      | with_reducible exact nonExpanding_optionMaybe _ nonExpanding_lengthModifier
      | with_reducible refine nonExpanding_bind _ _ ?_ (fun _ => ?_)

/-- `:171`: the inner `sat (fun z -> z <> #'%')` consumes. -/
theorem consumes_notPercent : Consumes (sat (fun (z : Char) => not (z == '%'))) := consumes_sat _

/-- `:170-171`: `format` is `many ALT` for the generated alternative (captured by unification),
    and `ALT` consumes: its left arm is `many1 (sat …) >>= return`, its right arm
    `conversionSpecification >>= return`. -/
theorem format0_passes_consuming : ∃ alt : parserM format_, format0 = many alt ∧ Consumes alt :=
  ⟨_, rfl, by
    intro cs r hr
    simp only [parse] at hr
    split at hr
    · simp at hr
    · rename_i x xs heq
      simp only [List.mem_singleton] at hr
      subst hr
      exact consumes_head_step _ _
        (consumes_bind_left _ _ (consumes_many1 _ (consumes_sat _)) (fun _ => nonExpanding_return _))
        (consumes_bind_left _ _ consumes_conversionSpecification (fun _ => nonExpanding_return _))
        _ _ _ heq⟩

/-- The register's invariant as ONE statement: at each of the four call sites, the parser the
    generated caller passes to `many`/`many1` consumes (`digit` at :90/:97 directly; the `:103`
    and `:170-171` alternatives through their captured structure; `sat (· ≠ '%')` at :171). -/
theorem callSites_consume :
    Consumes digit ∧
    (∃ (alt : parserM Char) (mk : List Char → flags),
      flags0 = parse_bind (many alt) (fun xs => parse_return (mk xs)) ∧ Consumes alt) ∧
    Consumes (sat (fun (z : Char) => not (z == '%'))) ∧
    (∃ alt : parserM format_, format0 = many alt ∧ Consumes alt) :=
  ⟨consumes_digit, flags0_passes_consuming, consumes_notPercent, format0_passes_consuming⟩

end CerbParserProgress
