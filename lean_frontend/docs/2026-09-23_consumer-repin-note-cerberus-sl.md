# Consumer re-pin note for cerberus-sl — the ONE re-pin (E-A + run-digest + item 7), 2026-09-23

Author: the orchestrator [AGENT]. Addressed to cerberus-sl (`scripts/semantics-pin.env`, `docs/DECISIONS.md`
C3.64 "the FINAL pin moves to its merge commit before the S3.5 landing (S3.5.1b)"). This is the note your
`2026-09-20_run-digest-design-response.md` §4 Q4 asked for: one re-pin after the complete set landed.

## 1. The pin

    CERBERUS_LEAN_COMMIT="2b51d2a57179d890a51dda404aedf59d80196926"   # mdd/cerberus-lean, 2026-09-23

Landed on `mdd/cerberus-lean` by ff-only merges, each on the operator's explicit per-merge sign-off:

| slice | mainline head | landed | your status |
|---|---|---|---|
| E-A — the enum map as program data (`Implementation.enum_definitions` reader; `A.sigma.enum_definitions`, Core `file.enumDefs`) | `df85e95b7` | 2026-09-22 | in your interim pin |
| D-S — the run's minting digest as run-state data (`initial_driver_state top digest file fs`, `core_run_state.sym_digest`, `runDigest`) | `34ac493f9` | 2026-09-22/23 | = your interim pin (S3.5, C3.64) |
| item 7 — `match_pattern` and every tuple-binding helper fail CLOSED on arity mismatch; Core typing and both engines' `Erun` guard argument-list arity; the shipped stdlib's `pread`/`pwrite` declarations fixed | `2b51d2a57` | 2026-09-23, [USER 2026-09-23] "Go ahead with the merge" | THIS re-pin (your "matcher discharge + `SelectAgreesC`'s deletion", C3.64) |

LemLib is UNCHANGED: lem-lean `mdd/lean-backend` `38f87d5fa6b29ec90edfa457faba8a309e32c118` (= `deps/lem-pinned` = opam
`lem -v` = `lean_frontend/lakefile.toml` rev = all four package manifests = `scripts/fork_drift_manifest.txt`
`[meta] lem-pin`). The delta from your interim pin is item 7 alone: `git log --oneline 34ac493f9..2b51d2a57` = 14 commits.

## 2. What changes for you between `34ac493f9` and `2b51d2a57` — exactly

Non-documentation footprint (`git diff --stat 34ac493f9 2b51d2a57 -- . ':!lean_frontend/docs'`, 13 files):
`frontend/model/{core_aux,core_reduction,core_run,core_typing}.lem`; `lean_frontend/Core_aux_lemMeasureProofs.lean`
(proof-BODY case splits for the new non-recursive guard branches + one comment; no theorem statement changed);
`lean_frontend/lakefile.toml` (+ one `lean_exe` `match-pattern-arity-test`; `run-digest-test` unchanged from your pin,
incl. its `moreLinkArgs`); `scripts/test_unit.sh`; `scripts/failure_reach_register.txt` (+1 row: the shared loud leaf
`Core_aux.tuple_arity_error`, class UNREACHABLE-BY-INVARIANT "fit-check before bind"); `scripts/fork_drift_manifest.txt`;
`runtime/libcore/std.core` + `std_inner_arg_temps.core` (see 2.6); `lean_frontend/test/Unit/MatchPatternArityTest.lean`.

**No signature changes.** Every fix is inside an existing body: `match_pattern`, `subst_pattern`, `subst_pattern_val`,
`unsafe_subst_pattern`, `update_env_aux`, the `Core_typing` arms, `Core_reduction.one_step` / `Core_run.step`'s
`Erun` arms. `initial_driver_state`, `drive`, `select_case`, `runDigest`, the readers — all as at your interim pin. Your
re-pin cost is the semantics rebuild (regenerate `lean_frontend/generated/` at the pin, `lake build`) plus whatever of
your 49 hand-written seams read the changed bodies.

Semantics you consume, by definition:

1. **`match_pattern`** (`core_aux.lem`): a `CaseCtor Ctuple pats` against `Vtuple vals` with `|pats| ≠ |vals|` returns
   `none` (both directions) INSTEAD of binding the truncated-zip prefix; on equal arity it binds every component in
   order, exactly as before. `select_case` is UNCHANGED code: `none` falls through to the next arm. Kernel facts, all
   by `rfl` on concrete terms, in `lean_frontend/test/Unit/MatchPatternArityTest.lean:76-111`: `T1a`/`T1b`
   (mismatch → `none`), `T1_wrapper` + `T1_anyFuel` (fuel-parametric: any fuel ≥ the pattern's `lemSize`), `T2`
   (`select_case` continues to the wildcard arm), `T3`/`T3_select` (equal arity: bindings and order = the `x++xs`
   right fold), `T4_neg` (negative control). Printed axiom sets: `[propext]` for the `rfl` facts (through the model's
   definitions), the standard trio for `T1_anyFuel`. These are the premises your `SelectAgreesC` route needed; the
   general statement is the definition's now-guarded tuple arm plus the unchanged others.
2. **`subst_pattern`** (the `--rewrite` substitution, `maybe`-returning): DECLINES (`none`) on a tuple-arity mismatch,
   fit-tested by `match_pattern`, nested tuples included — `R2_subst_pattern_val_tuple_23/32` (`:247-248`). The
   non-`maybe` helpers `subst_pattern_val` / `unsafe_subst_pattern` / `update_env_aux` keep ONE loud leaf
   `Core_aux.tuple_arity_error` as the backstop; every live caller is post-match (register row, cited invariant).
3. **Both engines' let-forms** (`Elet`, `Ewseq`, `Esseq`, plain and annotated — six `Core_reduction.one_step` sites,
   three `Core_run` sites): fit-check the whole pattern before any environment update; a mismatch is
   `Errors.Illformed_program "<form>: the pattern didn't match …"` through the monad — the same outcome kind as the
   rewritten `PElet` route, so default and `--rewrite` agree.
4. **Core typing** (`Core_typing`, reached under `--typecheck-core`/`--sequentialise`, and by any consumer that calls
   `typecheck_program` itself): rejects arity mismatches instead of deleting operands — tuple patterns/expressions,
   `Eunseq`, `Epar` (rounds 1–2), and (round 3) the argument lists of `PEcall` (inference + checking), `Ememop`,
   `Eproc`, `Erun`, `Eccall` fixed-arity and the FIXED prefix of a variadic call (the variadic bundle is split first
   and typechecked separately). Failure: the existing `MismatchExpected <site> (BTy_tuple bTys) "argument list of a
   different arity"` (the two `Eccall` arms use their existing `CoreTyping_TODO` string). Fitting inputs are rebuilt
   unchanged (typed `--pp=core` dumps byte-identical to the untyped structure, pinned).
5. **`Erun` at run time, both engines** (`Core_reduction.one_step`, `Core_run.step`): the argument list must fit the
   resolved continuation's parameter list BEFORE any evaluation/substitution; otherwise
   `Illformed_program "Erun: the argument list does not fit the continuation's parameters"`. Pre-fix, a surplus
   argument was never evaluated (a surplus `error(...)` vanished) and a shortage kept the OLD binding — a zero-actual
   `run loop()` did not terminate.
6. **The shipped Core stdlib** you load through the pin's `runtime/libcore/std.core` (and `std_inner_arg_temps.core`):
   `builtin pwrite`/`builtin pread` now declare FOUR formals (the offset), matching the same file's call sites and both
   engines' runtime arms. Upstream declares three; its truncating typing deleted the offset, so the shipped `pread`/
   `pwrite` could never run. Filed upstream in tray draft 45. No C or Core caller in the corpora; your builds that
   typecheck the stdlib now pass where they would have been rejected by (4).

Unaffected: the C elaborator always emits matching arities, so elaborated programs are untouched — the pristine
corpus lanes are unmoved (835 semantic agreements / 28 matching failures / 7 reviewed differences / 2 interface
agreements, chvalid 4, gcc-oracle 0 regressions / 0 improvements, frozen battery `Source unchanged: True`, 39/39).

## 3. Evidence you can check at the pin

- Records: `lean_frontend/docs/2026-09-20_match-pattern-arity-record.md` (§7 consumer note, §12–§15 the three closure
  rounds, §16 the landing with the orchestrator's verbatim gate tails), the charter + Addendum A3
  (`2026-09-20_charter-match-pattern-arity.md`), the two independent audits
  (`2026-09-22_match-pattern-arity-rereview.md`, `2026-09-23_match-pattern-arity-round3-delta-review.md` — final
  verdict "Merge-ready as is at `e5532b346`"), the upstream report `upstream-tray/45-core-match-pattern-truncating-zip-arity.md`.
- Gates at the pin (row 1 of `scripts/LADDER.md`): `scripts/test_unit.sh` → `Total: 15 passed, 0 failed`;
  `check_failure_reach: OK (239 …)`; `check_fork_drift: OK — layer 1: 84 … layer 2: 29 …`; `libc_prep: OK (content
  hash verified …)`; the six differential lanes green (record §16).
- Your §5 acceptance: `corpus-check` on your eight quoted modules against the re-pinned frontend; the `digest` field
  and `initial_driver_state`'s arity are exactly as at your interim pin (nothing in item 7 touches them).

## 4. Open on our side, for your information

None of these blocks the re-pin. lem-lean DESIGN.md follow-up sentences (the `reader_seed` extent rule); the
`check_lakefile_roots.sh` locale note; retiring the finished worktrees. Questions to the orchestrator via the operator,
as before.
