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
tuple-BINDING helpers `subst_pattern_val` (`core_aux.lem:1123-1145`, tuple arm `:1141-1143`),
`unsafe_subst_pattern` (`:1403`, two tuple arms), `subst_pattern` (`:1484`, two tuple arms) and
`update_env_aux` (`:2443`, tuple arm `:2459-2462`) zip the same way, and — CORRECTED 2026-09-22 after the
fork's pre-merge audit (this draft first said they ran "only after a successful match"; there is also no
`subst_pattern_pexpr`) — they are reached WITHOUT a prior `match_pattern`: `to_pure → subst_pattern`
(`core_aux.lem:1536-1546`), `pure_propagation2 → subst_pattern` (`core_rewrite.lem:1187-1193,
1219-1225`), `subst_pattern`/`unsafe_subst_pattern → subst_pattern_val` on tuple components, and the
`Elet`/`Ewseq`/`Esseq` rules of BOTH engines → `update_env` (`core_run.lem:872-879, 1450, 1494`;
`core_reduction.lem:351-426`). See "The surrounding paths" below.

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
their order unchanged on a fitting match — by `rfl` (`#print axioms` = `[propext]`, inherited from the
model's `lemListZip`; the any-fuel lift `T1_anyFuel` the standard trio), plus the pre-fix negative
control and the typing pin, in `lean_frontend/test/Unit/MatchPatternArityTest.lean` (`match-pattern-arity-test`);
fork-drift manifest rows for `core_aux.lem`/`core_typing.lem` (layer 1) and the generated
`core_aux.ml`/`core_typing.ml` (layer 2). No lane moved (the defect is unobservable on elaborator output),
so no pristine-oracle register row exists; the witness above is carried as TEXT here, not as a fixture.

## The surrounding paths (closure round, 2026-09-22 — the fork's pre-merge audit R1/R2)

The fork's independent pre-merge audit (`lean_frontend/docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit.md`,
evidence `…-audit-evidence/arity/`) found the same truncating-`zip` default in the paths AROUND the two
guards above, on the same `.core` inputs. Both are in upstream `master` @ `b9aeedcb4` unchanged.

**R1 — Core typing DELETES surplus tuple operands.** `typecheck_pexpr`'s tuple-expression arm
(`core_typing.lem:884-887`, `E.mapM … (List.zip bTys pes)`, reached from the `PElet` inference branches
`:772-782`/`:1174-1181` and the `Elet` rule `:1709-1718`), `typecheck_expr`'s `Eunseq` arm (`:1786-1795`)
and its `Epar` arm (`:1853`) zip the expected component types against the operands and REBUILD the
expression from the zip — so a tuple expression of the wrong arity is accepted and its surplus operands
are removed from the typed program. The audit's table, verbatim (`pure-let-mismatch.core`:
`proc main (): eff loaded integer := pure (Specified (let (a: integer, b: integer) = (1, 2, 3) in a + b))`):

| Engine/tree | Default | Add `--typecheck-core` |
|---|---|---|
| Base `5407597d9` | `Specified(3)`, exit 0 | `Specified(3)`, exit 0 |
| Pristine `b9aeedcb4` | `Specified(3)`, exit 0 | `Specified(3)`, exit 0 |
| Arity head `14457f1a0` | `PElet: the pattern didn't match pe1`, exit 1 | `Specified(3)`, exit 0 |

and `--pp=core --typecheck-core` prints the tuple as `(1, 2)` where the default dump keeps `(1, 2, 3)`.
The deletion can SUPPRESS a failure: with the surplus operand written `error(<<<surplus>>>, 3)`
(`pure-let-discarded-error.core`, and the `unseq(pure (1), pure (2), pure (error(<<<surplus>>>, 3)))`
twin), base, pristine and the arity head all give `Error {msg: "surplus"}`, exit 1, by default — and
`Specified(3)`, exit 0, with `--typecheck-core`: typing deleted the erroring operand.

**R2 — the other tuple-BINDING paths bypass the matcher.** `Core_run`'s ordinary `let` (`core_run.lem:872-879`)
binds through `update_env` (`core_aux.lem:2459-2462`, zip, no arity check), as do its `Ewseq`/`Esseq`
(`:1450`, `:1494`) and `Core_reduction`'s let-forms; `core_rewrite`'s ordinary-let rule (`:1122-1130`)
turns an `Elet` into a `PElet`, which `core_eval.lem:1007-1018` evaluates through `select_case` — so once
the matcher is guarded the two mechanisms DISAGREE (`let-mismatch.core`: default `Specified(3)`,
`--rewrite` the `PElet` error). The substitution helpers are reached without the matcher (paths above);
the audit's `ArityAudit.lean` kernel-checks `match_pattern pair triple = none` while `subst_pattern_val
pair triple body`, `subst_pattern` and `unsafe_subst_pattern` substitute the prefix.

**Proposed remedy (the fork's closure-round patch, shared body):** (R1) at each of the three typing
sites, `if List.length bTys <> List.length <operands> then E.fail loc (MismatchExpected "<Ctuple|Eunseq|Epar>"
expected "… of a different arity") else <the present body>`; (R2) the let-forms of BOTH engines — `Core_reduction.one_step`
(`core_reduction.lem:351-426`, the engine the driver steps with) and `Core_run.core_thread_step2` (`core_run.lem:872-879,
1450, 1494`) — check `match_pattern pat cval` before `update_env` and report `Illformed_program "<Elet|Ewseq|Esseq>:
the pattern didn't match …"` through the monadic channel — the same outcome as the `PElet` route, so default =
`--rewrite`; the
`maybe`-returning `subst_pattern` returns `Nothing` on a mismatch (fit-tested by `match_pattern`, so nested
mismatches decline too) and the rewriter/`to_pure` leave the binding to the runtime; and the non-`maybe`
helpers (`subst_pattern_val`, `unsafe_subst_pattern` ×2, `update_env_aux`) guard their arity with ONE shared
loud leaf, `Core_aux.tuple_arity_error` (`Cerb_debug.error` on the OCaml side) — the backstop behind callers
that are all post-match. Fitting inputs are unchanged (the fork pins operand preservation byte-identically).

**The final policy, in one paragraph (closure round 2, 2026-09-22, [AGENT orchestrator] ruling):** a tuple
pattern that does not fit its tuple (arity, at any depth) is a malformed Core program, and every path reports
it through ONE outcome kind. The MATCHER returns `Nothing`, so the SELECTOR falls through to the next arm
(`case`; the consumer's contract, unchanged). TYPING rejects it when Core typing runs (`--typecheck-core`, off
by default): the tuple-pattern rule and the tuple-expression, `unseq` and `par` rules all fail with the existing
`MismatchExpected`. The LET-FORMS of BOTH engines (`Core_reduction.one_step` — the driver's — and
`Core_run.core_thread_step2`: `Elet`/`Ewseq`/`Esseq`) check `match_pattern` before `update_env` and raise
`Illformed_program "<form>: the pattern didn't match …"`, the same channel as the `PElet` route, so the default
run and `--rewrite` agree. The REWRITER declines: the `maybe`-returning `subst_pattern` returns `Nothing` on a
mismatch (its value arms use `match_pattern` as the fit test, so nested mismatches decline too), and
`pure_propagation2`/`to_pure` then leave the binding for the runtime to report. The non-`maybe` HELPERS
(`subst_pattern_val`, `unsafe_subst_pattern`, `update_env_aux`) keep the loud leaf `tuple_arity_error` as the
backstop — every live caller of theirs is now post-match, so the leaf has no executing route (register class
UNREACHABLE-BY-INVARIANT, invariant "fit-check before bind").

**Erratum to the audit's R2 cite (the fork's audit named the second engine):** the audit named
`core_run.lem:872-879` as the ordinary `let`'s binding site; that is `Core_run.core_thread_step2`, the SECOND
engine. The driver steps with `Core_reduction` (`driver.lem` `drive_core_thread2 → Core_reduction.core_step2 →
step_ctx → one_step`), whose six let-form sites (`core_reduction.lem:351-426`) bind through `update_env` just the
same. Evidence: the first post-fix run of the audit's `let-mismatch.core` (default mode), with only `core_run.lem`
guarded, died in the new loud leaf with the backtrace `Failure("internal error: Core_aux.update_env_aux: tuple
pattern of arity 2 bound to a tuple of arity 3 (upstream-tray draft 45)") … Called from
Cerb_frontend__Core_aux.update_env … Called from Cerb_frontend__Core_reduction.one_step.(fun) in file
"ocaml_frontend/generated/core_reduction.ml", line 410 … Called from Cerb_frontend__Driver.liftCore_run.(fun) in
file "ocaml_frontend/generated/driver.ml", line 163`. Both engines are guarded.

**Fork status:** LANDED in the closure rounds of `fix/match-pattern-arity` (record
`lean_frontend/docs/2026-09-20_match-pattern-arity-record.md` §12, with the hunks, the pre-fix engine
quotes on the audit's probes and the runtime witnesses `test/Unit/MatchPatternArityTest.lean`).
