# `Core_aux.match_pattern` and `Core_typing.typecheck_pattern` zip tuple patterns with Lem's TRUNCATING `List.zip`: a tuple pattern of the wrong arity MATCHES (binding a prefix) and TYPECHECKS (surplus sub-patterns dropped)

**Affected:** `frontend/model/core_aux.lem:2033-2039` (`match_pattern`, the `(CaseCtor Ctuple pats', Vtuple
cvals')` arm) and `frontend/model/core_typing.lem:182-186` (`typecheck_pattern`, the `(Ctuple, BTy_tuple
bTys, _)` arm). Both fold over `List.zip pats' cvals'` / `List.zip bTys pats`, and Lem's `zip`
(`lem/library/list.lem:987-992`) is documented as truncating: *"If one input list is short, excess
elements of the longer list are discarded"* — `| _ -> []` on unequal tails. Every other arm of
`match_pattern` is exact (`Cspecified`/`Cunspecified` take one sub-pattern, `Ccons` two, `Cnil` none;
the fall-through `| _ -> Nothing` at `:2048-2049`). Upstream ALREADY guards the same shape elsewhere in the
same model: `core_rewrite.lem:1287-1300` `simpl_match_pattern` has `if List.length pats' <> List.length
cvals then Nothing else …` on BOTH of its tuple arms. Checked against `master` @ `b9aeedcb4`: the cited
lines are byte-identical to the merge-base (the fork's `core_typing.lem` was byte-identical to upstream
before this fix; `core_aux.lem` differed only in unrelated fuel declarations).

## Description

```lem
(* core_aux.lem:2019-2050 *)
let rec match_pattern (Pattern _ pat) cval =
  match (pat, cval) with
    …
    | (CaseCtor Ctuple pats', Vtuple cvals') ->                              (* :2033 *)
        List.foldr (fun (pat', cval') acc ->
          Maybe.bind acc (fun xs ->
            Maybe.bind (match_pattern pat' cval') (fun x ->
              Just (x++xs)
            )
          )
        ) (Just []) (List.zip pats' cvals')                                   (* :2039 *)
    …
    | _ -> Nothing
  end
```

```lem
(* core_typing.lem:182-186 *)
        | (Ctuple, BTy_tuple bTys, _) ->
            List.unzip <$> E.mapM (fun (bTy, pat) ->
              typecheck_pattern bTy pat
            ) (List.zip bTys pats) >>= fun (envs, tpats) ->
            E.return (env_unions envs, Pattern annots (CaseCtor Ctuple tpats))
```

With the truncating `zip`:

- **Matcher.** A pattern `(a, b)` against the value `(1, 2, 3)` zips to `[(a,1); (b,2)]` and returns
  `Just [(a,1); (b,2)]` — a MATCH binding the prefix; the third component is silently ignored. A pattern
  `(a, b, c)` against `(1, 2)` likewise returns `Just [(a,1); (b,2)]` — `c` is never bound, so any use of
  it in the arm body is an unbound symbol at run time. `select_case` (`:2053-2064`) therefore commits to
  the mismatching arm instead of "trying the next branch".
- **Typechecker.** `typecheck_pattern (BTy_tuple [bTy1; bTy2; bTy3]) (Ctuple [p1; p2])` zips to two
  pairs and returns a TYPED `Ctuple [p1'; p2']` — accepted. `typecheck_pattern (BTy_tuple [bTy1; bTy2])
  (Ctuple [p1; p2; p3])` returns a typed `Ctuple [p1'; p2']` — accepted AND the third sub-pattern is
  DROPPED from the typed pattern the rest of the pipeline sees. Only `(Ctuple, <non-tuple type>, _)` is
  rejected (`MismatchExpected "Ctuple" expected_bTy "tuple"`, `:187-188`).

`infer_pattern`'s `Ctuple` arm (`:55-59`) infers from the pattern alone (no zip) and needs nothing.

## Reproducer

Core text only — the elaborator builds tuple patterns from the types it has just produced, so no C
program reaches either site; this is why the defect is unobservable on elaborator output and why the
project's differential lanes (all elaborator output or upstream-derived Core text of typed programs)
never saw it. The file, a `case` on a triple whose first arm is a PAIR pattern followed by a wildcard:

```
proc main (): eff loaded integer :=
  case (1, 2, 3) of
    | (a: integer, b: integer) =>
        pure (Specified (a + b))
    | _: (integer, integer, integer) =>
        pure (Specified (0))
  end
```

Run as `cerberus --nolibc --exec --batch --mode=exhaustive witness-arity.core` (2026-09-20, verbatim;
`Time spent` trailer omitted):

```
pristine b9aeedcb4:  Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}   [rc=0]
```

— pristine TYPECHECKS the file (the pair pattern against the triple type) and then SELECTS the pair arm,
binding `a = 1, b = 2` and ignoring the third component: `Specified(3)`. The intended reading of the
program — the pair pattern does not fit a triple, so the wildcard arm is taken — is `Specified(0)`; with
the typing guard proposed below the file is rejected at Core typing instead (the pattern's arity is
wrong for its scrutinee's type), which is the fail-closed answer for a typed `.core` input.

The fork's engines after the fix (both generated from the same lem; see "Fork status"):

```
fork (both guards), default pipeline (Core typing is off unless --typecheck-core):
                     Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}   [rc=0]
```

— the matcher returns `Nothing` on the pair pattern, `select_case` tries the next arm, the wildcard is
taken: `Specified(0)`. With Core typing ON (`--typecheck-core`, the same file; 2026-09-20, verbatim):

```
pristine b9aeedcb4 --typecheck-core:
                     Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}   [rc=0]
fork (both guards) --typecheck-core:
.tmp/mpa/witness-arity.core:5:7: error: this expression is of type 'tuple pattern of a different arity' but an expression of type '(integer,integer,integer)' was expected
    | (a: integer, b: integer) =>
      ^~~~~~~~~~~~~~~~~~~~~~~~ 
```

— pristine's typechecker ACCEPTS the pair pattern against the triple type (the truncating zip) and the
run proceeds to the prefix-binding match; the fork's rejects it at the pattern. The Lean port has no
`.core` execution entry (its driver takes the C front end's Cabs JSON; `--parse-core` only parses), so
its witness is the kernel: the same generated `match_pattern`/`typecheck_pattern` are pinned by
`rfl`/runtime facts in `lean_frontend/test/Unit/MatchPatternArityTest.lean` (T1: `none` on both
mismatch directions; T2: the wildcard arm selected; T3: bindings and order on a fitting match; T5: the
typing rejection).

## Observed vs expected

Observed: a tuple pattern whose arity differs from the value's (matcher) or from the expected tuple
type's (typechecker) is treated as fitting, on the prefix of the shorter list. Expected: the matcher
returns `Nothing` (no match; `select_case` continues to the next arm, exactly as upstream's own
`simpl_match_pattern` does), and the typechecker rejects the pattern with the existing `MismatchExpected`
error rather than dropping sub-patterns.

## Impact

No C program is affected (elaborator discipline). The defect matters (1) for hand-written or
tool-generated `.core` inputs — a mismatched pattern is accepted by typing and then either binds a prefix
or leaves a sub-pattern's symbol unbound; and (2) for any proof about the Core semantics as stated: a
`case` rule that reads "an arm is selected iff its pattern matches" needs "every arm's pattern fits the
value" as an extra premise, which is an engine property leaking into program reasoning — the reason the
fork's verification consumer asked for the fix (cerberus-sl, hidden-state note item 7: *"on an arity
mismatch `match_pattern` returns NO MATCH (`Nothing`), not an error, so that `select_case` CONTINUES to
later arms … and a successful match keeps the calculus's bindings and their order"*). The
post-match substitutions `subst_pattern_val`/`subst_pattern_pexpr` (`core_aux.lem:1123-1145`, tuple arm
`:1141-1143`) zip too, but run only AFTER a successful match, so with the matcher guarded their zips see
equal lengths on every reachable call.

## Proposed remedy

Mirror `simpl_match_pattern`'s guard at both sites (the fork's patch, shared body — both the OCaml and the
Lean targets compute it):

```lem
    | (CaseCtor Ctuple pats', Vtuple cvals') ->
        if List.length pats' <> List.length cvals' then
          Nothing
        else
        List.foldr (fun (pat', cval') acc -> … ) (Just []) (List.zip pats' cvals')
```

```lem
        | (Ctuple, BTy_tuple bTys, _) ->
            if List.length bTys <> List.length pats then
              E.fail loc (MismatchExpected "Ctuple" expected_bTy "tuple pattern of a different arity")
            else
            List.unzip <$> E.mapM (fun (bTy, pat) -> typecheck_pattern bTy pat) (List.zip bTys pats) >>= …
```

Error TYPE unchanged (the existing constructor); only the found-text is new.

## Classification

**TRUE BUG (fail-open default in the Core model; Core-level only, not C-reachable; ISO-independent).**
The matcher's own specification — `Nothing` on every non-fitting shape, as the exact `Cspecified`/
`Ccons`/`Cnil` arms and the fall-through say, and as upstream's `simpl_match_pattern` implements for the
same tuple shape — is violated on tuple arity because of `zip`'s documented truncation. No ISO C clause
applies: this is the intermediate language's pattern matching, and the C elaborator never emits the
mismatch. Ranks with the Core-level soundness gaps (19, 35-37 tier), below the C-reachable bugs.

## Provenance

Found 2026-09-18 by the verification consumer (cerberus-sl, an AI agent — Claude, Anthropic — writing
the `case` rule of its calculus against the pinned Lean port; its note `docs/2026-09-18_hidden-state-
upstream-note.md` item 7), which asked for the fail-closed contract quoted above; the typechecker's twin
zip found 2026-09-20 by the cerberus-lean orchestrator (Claude, Fable 5.1) while chartering the fix.
Reproduced on the pristine `master` @ `b9aeedcb4` binary and drafted by Claude (Fable 5.1) under operator
direction; the filed issue carries an AI-provenance note per the tray's policy.

## Fork status (2026-09-20) — fix LANDED ahead of upstream (shared body)

[USER 2026-09-16] on the allocator (draft 44), the same "unambiguously wrong" category, verbatim: *"I think
this is in the 'unambiguously wrong' category where we are allowed to fix ahead of upstream"*; [USER
2026-09-20, via cerberus-sl `docs/2026-09-20_run-digest-design-response.md` §4 Q5] *"we can ask for this
immediately"*. Landed on branch `fix/match-pattern-arity` (record
`lean_frontend/docs/2026-09-20_match-pattern-arity-record.md`, which carries the two lem hunks = the patch
for upstream): both guards above in `core_aux.lem` and `core_typing.lem` (a fork comment at each site);
the fuel-measure sufficiency proof of `match_pattern` re-established with its statement unchanged
(`lean_frontend/Core_aux_lemMeasureProofs.lean`); the kernel facts the consumer named as its acceptance
premises — `match_pattern (pair) (triple) = none`, `select_case … = some <wildcard arm>`, bindings and
their order unchanged on a fitting match — by `rfl`, axiom-free, plus the pre-fix negative control and
the typing pin, in `lean_frontend/test/Unit/MatchPatternArityTest.lean` (`match-pattern-arity-test`);
fork-drift manifest rows for `core_aux.lem`/`core_typing.lem` (layer 1) and the generated
`core_aux.ml`/`core_typing.ml` (layer 2). No lane moved (the defect is unobservable on elaborator output),
so no pristine-oracle register row exists; the witness above is carried as TEXT here, not as a fixture.
