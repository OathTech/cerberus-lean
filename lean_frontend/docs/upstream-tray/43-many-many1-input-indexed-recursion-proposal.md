# Proposal: `many`/`many1` as input-indexed recursion — a termination-checkable formulation of the two parser combinators, extensionally identical to the current one

**Affected (for orientation):** `frontend/model/monadic_parsing.lem:93-99` (`master` @
`b9aeedcb4`): `let rec many p = many1 p <|> return []` / `and many1 p = p >>= fun a -> many p
>>= fun _as -> return (a::_as)`, over the module's `parse` (`:8`), `return` (`:12`), `>>=`
(`parse_bind`, `:16-18`), `mplus` (`:25`) and the inlined `<|>` (`:48-52`). Callers: the printf
format parser, `frontend/model/formatted.lem` (`many digit` twice, `many` of a flag
alternative, `many`/`many1` in `format`).

This is a proposal, not a defect claim: the interpreter's results are unchanged on every input.

## Observation

`many`/`many1` are mutually recursive with no structural decrease in their only parameter `p`
(a parser, i.e. a function): the recursion is well-founded only because each round trip
consumes input, and the input is not a parameter of either function — it is bound by the lambda
inside the `ParserM` built by `<|>` and `>>=` at every level. In OCaml this is unremarkable. In a
total target language (we generate Lean 4 from the same `.lem`), a recursion whose measure is
not a function of its parameters cannot be given a termination argument at all: the two
functions have to be compiled with an artificial fuel counter fixed BEFORE the input arrives,
which no expression over `p` can bound (the depth on an input is the number of characters `p`
consumes on that input).

## Proposal

Restate the pair as two mutually recursive RUN functions that take the input as an explicit
parameter — their bodies are exactly the unfoldings of the current definitions through the four
`inline`s — and define `many`/`many1` as the corresponding parsers:

```lem
val     many_run:  forall 'a. parserM 'a -> list char -> list (list 'a * list char)
val     many1_run: forall 'a. parserM 'a -> list char -> list (list 'a * list char)
let rec many_run p cs =
  match many1_run p cs ++ [([], cs)] with
    | []     -> []
    | (x::_) -> [x]
  end
and     many1_run p cs =
  List.concatMap (fun (a, cs') ->
    List.map (fun (_as, cs'') -> (a::_as, cs'')) (many_run p cs')
  ) (parse p cs)

val     many:  forall 'a. parserM 'a -> parserM (list 'a)
val     many1: forall 'a. parserM 'a -> parserM (list 'a)
let many p  = ParserM (many_run p)
let many1 p = ParserM (many1_run p)
```

(The fork's patch also carries Lean-only `declare {lean} …` lines and a comment block, omitted
here; the `val`s of `many`/`many1` are unchanged, so no caller changes.)

## Why the parsers are the same, on every input

Writing `⟦q⟧ cs` for `parse q cs`: unfolding `>>=` and `return` once, `⟦many1 p⟧ cs =
List.concatMap (fun (a, cs') -> List.concatMap (fun (_as, cs'') -> [(a::_as, cs'')]) (⟦many p⟧
cs')) (⟦p⟧ cs)`, and `concatMap (fun x -> [g x]) = map g`; unfolding `<|>` and `mplus` once,
`⟦many p⟧ cs = match ⟦many1 p⟧ cs ++ [([], cs)] with [] -> [] | x::_ -> [x] end`. So the pair
`(⟦many p⟧, ⟦many1 p⟧)` satisfies exactly the defining equations of `(many_run p, many1_run p)`;
the two formulations are the same recursive system, differing only in WHERE the input is bound.
Evaluation performs the same hops in the same order (`many` on `cs` → `many1` on `cs` → for each
result `(a, cs')` of `p`, `many` on `cs'` → …), so for every `p` — deterministic or multi-result,
failing or not — and every `cs`, the old evaluation terminates iff the new one does, with the same
list; a non-consuming `p` that succeeds makes both loop, as today. Generated OCaml: the diff is the
restatement plus two one-line wrappers; our differential test corpora (Tier A/B, printf-heavy lanes
included) moved nowhere.

## What the restatement buys

With the input a parameter, the recursion has a measure: under the hypothesis that `p` consumes
(every result of `parse p cs` leaves a strictly shorter rest — true of every parser
`formatted.lem` passes), the depth from `many_run p cs` is at most `2 * length cs + 2`, from
`many1_run p cs` at most `2 * length cs + 1`. Our Lean port declares those measures under that
hypothesis, proves them sufficient, and discharges the hypothesis as a theorem at every printf
call site; the fuel counter is gone from the printf parser family. Any other total-language
port of the model (Coq/Rocq, Isabelle via Lem) gets the same benefit, and the OCaml is unaffected.

## Classification

**PROPOSAL** (a termination-checkable formulation; not a bug — no observable behaviour changes,
no ISO question). Upstream's call whether the more regular statement is wanted in the shared
model; the patch is small and mechanical.

## Provenance

Found while closing the last two fuel'd workers of our Lean port (fuel-pending register,
`lean_frontend/docs/2026-09-08_fuel-pending-closeout-record.md` D2: "the recursion argument is
not a parameter"); the restatement, the sufficiency proofs and the call-site theorems are in
`lean_frontend/docs/2026-09-11_parser-progress-measure-record.md` (D1/D2/D4). Localisation and
this draft by Claude (Fable 5.1) under operator direction; the filed issue carries an
AI-provenance note per the tray's policy.

## Fork status (2026-09-15) — LANDED on the fork's branch `arc/parser-progress-measure`; the patch is the `.lem` diff

[AGENT 2026-09-15] `frontend/model/monadic_parsing.lem` restated as above (record D1); the two
workers `many_run`/`many1_run` are MEASURED under `CerbParserProgress.Consumes p` (record D2); the
hypothesis is a theorem at every call site (record D4.1); and the relation between the OLD and
NEW workers is kernel-checked (record D4.2): for every fuel, parser and input, the old worker's
parse equals the new worker's result under the one hypothesis that the two exhaustion sentinels
run alike — the only difference between the formulations (`ManyRestatement.restatement_of_sentinel`
in `lean_frontend/test/Unit/ManyRestatementTest.lean`) — and unconditionally, for a consuming
`p`, at every fuel at or above the measure (`…restatement_under_measure_many`/`_many1`;
`old_at_measure_is_many : parse (many_old_lemFuel (2 * cs.length + 2) p) cs = parse (many p) cs`).
Generated OCaml `monadic_parsing.ml`: fork-drift `[expected-semantic]` row added (layer 2: 23 → 24);
every Tier A/B baseline row unchanged (record D6).
