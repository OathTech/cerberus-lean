# Pre-merge review: `fix/compound-assignment-refusal` (f8892bd31, five commits over `mdd/cerberus-lean` b4a48f635)

Reviewer: fresh independent agent [AGENT 2026-10-29, reviewer]. Budget ~45 min. Worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/compound-assignment-refusal` (Lean 4.35.0, lem e6d8db5),
read-only; no tracked file edited, no build, no lane script, no git state change. Scratch:
`/home/dev/projects/cerberus-lean-proj/.tmp/review-ca/` (this file, `run3.sh`, `probes/`, `probes.log`, `spot_files.txt`,
`spot_results.tsv`) — delete after the orchestrator has read it.

## Verdict

**MERGEABLE.** No P1 or P2 finding. Four P3 items (two documentation precisions, one code-comment vocabulary mismatch,
one hygiene/cost note) and one incidental out-of-scope crash finding; none blocks the merge, the documentation ones fit
the close-out commit.

## 1. Scope and what I read

- Practices: container `CLAUDE.md`, worktree `lean_frontend/CLAUDE.md` (the refusal/crash/fuel bullets).
- The charter `docs/2026-10-29_worker-charter-compound-assignment-refusal.md`, the record
  `docs/2026-10-29_compound-assignment-refusal-record.md` (all of it), the five commit messages, `git diff
  b4a48f635..f8892bd31` in full (translation.lem, the witness script, the manifest, `TotalityProofTest.lean`,
  `gen_fuel_parametricity.py`, `test_unit.sh`, `LADDER.md`, CONTRACT/SUPPORTED/VALIDATION/TODO, the tsv, tray 61 + INDEX,
  the D12 record's §8, the parity-probes README, the consumer note).
- Source context at the new tree: `frontend/model/ail/ailSyntax.lem:79-204` (unary operators, the 37 `expression_`
  constructors), `cabs_to_ail.lem:2400-2445` (prefix `++`/`--` → `AilEcompoundAssign`, `sizeof(expr)` → `AilEsizeof ty`),
  `mini_pipeline.lem:144-160` (plain `runStateM`), `translation_effect.lem:250-262` (`record_error`/`record_error_at`/
  `runStateM_errors`), `translation.lem:1384-1491` (the walker and text), `:2613-2645` (the arm; `loc` is the outer
  expression's, bound at `:1595`), `:2846-2852` (`AilEgeneric` elaborates only the selected association), `:4700-4723` (the
  fuel declares), the generated `Translation.lean:2014-2110, 3668-3684` and `translation.ml:1439-1450, 2635`,
  `scripts/check_fuel_forms.sh:36-56` (class definitions), `scripts/observations.py:50-64`, `scripts/test_ci_sweep.sh:90-93`,
  `scripts/test_upstream_oracle.py:850-866`, the survey record §0/§2.2/§3 slice 2, the 14 probes in
  `tests/parity-probes/uncertainty/B-compound-assignment/`, the worker's sweep evidence still under the worktree's
  `.tmp/sweep/`.

## 2. What I ran (verbatim)

Runner `/home/dev/projects/cerberus-lean-proj/.tmp/review-ca/run3.sh <file.c>` = for one C file: oracle
`scripts/ce $WT/_build/default/backend/driver/main.exe --runtime=$WT/_build/install/default --exec --batch --nolibc f.c`;
`… --cabs-json f.c > f.json`; `LEAN_ABORT_ON_PANIC=1 $WT/lean_frontend/.lake/build/bin/cerberus-lean --batch
--runtime=$WT/_build/install/default f.json`; `gcc -std=c11 -w -o f.gcc f.c && ./f.gcc`. All outputs in `probes.log`.

```
cd .tmp/review-ca/probes && for f in r*.c a*.c h*.c f*.c; do ../run3.sh $PWD/$f; done > ../probes.log   # 58 probes
for f in x*.c; do ../run3.sh $PWD/$f; done                                                              # 13 more
$WT/lean_frontend/.lake/build/bin/cerberus-lean --batch --runtime=$WT/_build/install/default s_ca02.json   # no abort flag
scripts/ce main.exe --runtime=… --nolibc --pp=core s_ca02.c > pp.out 2> pp.err                              # rc 125, pp.out 0 bytes
scripts/ce main.exe --runtime=… --nolibc --pp=core v01_volatile_object.c / v02_volatile_subscript.c | grep -c 'load(\|store('
sha256sum frontend/model/translation.lem; diff -u --label upstream/translation.ml --label fork/translation.ml \
  $CERB_UPSTREAM_TREE/translation.ml ocaml_frontend/generated/translation.ml | sha256sum                   # manifest re-pin
git -C /home/dev/projects/cerberus-lean-proj/cerberus-lean rev-parse --short HEAD   # b4a48f635 = mainline oracle, used as the "before" engine
# corpus spot-check (background, nice -n 10, one oracle process per file, --nolibc --pp=core, 30 s timeout):
find tests/minimal tests/coverage tests/debug tests/immaculate tests/ci lean_frontend/corpus tests/libc tests/multi_tu tests/pnvi_refusals -name '*.c'
#  -> files=869; SPOT DONE: 869 files; refused_ca=0; rc=0:728 rc=1:131 rc=125:10
# the two "grep estimate" gcc-torture files and 990222-1.c's execute/ twin on the new oracle (--pp=core):
#  execute/920428-1.c rc=1 "unexpected token"; execute/pr37573.c rc=1 "unexpected token";
#  breakdown/fail/{compound_assigments/920428-1.c,stack-overflow/pr37573.c} rc=1 "fatal error: cerberus.h";
#  execute/990222-1.c rc=1 "use of undeclared identifier 'abort'"
```

## 3. Results against the items of interest

**Predicate soundness/completeness for the class.** The walker covers all 37 `expression_` constructors with no wildcard
(checked against `ailSyntax.lem:152-204`); Ail has exactly two increment constructors (`PostfixIncr`/`PostfixDecr`,
`ailSyntax.lem:85-86`) and the desugarer turns `++e`/`--e` into `AilEcompoundAssign` (`cabs_to_ail.lem:2405-2414`), which
the walker counts; `translate_expression` is the only elaboration site of `AilEcompoundAssign` (grep over
`frontend/model`). My own refusal probes all refused on BOTH engines with the attributed text at the operator's column:
nested lvalues (`s.a[i++].b`, `p->arr[p->n++]`), a side effect in a conditional's condition (`*(i++ ? &a : &b)`,
`(i++ ? p : q)[0]`), through a cast (`*(int*)(void*)(p++)`), function-pointer calls (`*fp()`, `*(*fp)()`), prefix forms
desugaring to compound assignments (`++a[i++]`, `--*p++`), a nested compound assignment (`a[b[0] += 1] += 7`), an
assignment in the index, a comma in a deref, a compound literal in the index, `va_arg` (the witness), a GNU statement
expression `({ i++; a; })[0] += 1`, a post-decrement, the selected `_Generic` association (`_Generic(0, int: i++, …)`), a
`case` label in the mini-run (`case (a[i++] += 1):` with globals: the attributed refusal on both, rc 125/134), and every
operator `+= -= *= /= %= <<= >>= &= ^= |=` with `a[i++]`. A side-effecting compound assignment inside the RIGHT operand
(`x += (a[i++] += 1)`) refuses through the inner arm's own walk — correct.

**No over-refusal of legal side-effect-free lvalues.** 21 + 10 answer-class probes agree Lean = oracle = gcc:
`*(c ? &a : &b)`, `(c ? p : q)[0]`, `*(int*)(void*)p`, `a[_Generic(i, int: 1, …)]`, `s.a[i].b[j]`, `p->next->val`,
`++a[i]`, `*&a[i]`, `*vp` (volatile pointee), a volatile struct member, `_Atomic int`, `_Bool`, `float`, pointer
`+=`/`-=`, `*ps[i]`, `a[1+2]`, `a[sizeof(int)-1]`, `m[i][j] *= 3`, `a[__builtin_expect(1,1)]`, `*(p = &x) = 7` (plain
`=`, unaffected), `x += (i++, 2)` (side effect in e2 only), `*p += 1` with `volatile int * volatile p`. `x += x++` stays
UB035 on both (real UB); `"abc"[0] += 1` is UB033 on both (gcc segfaults).

**Volatile.** Measured on the Core (`--pp=core`): `volatile int v; v += 2` — one `load` of `v`, one `store` (plus the
init store and the return load); `volatile int i; a[i] += 2` — `i` loaded twice (lines 27 and 59), `a[i]` loaded once,
stored once. The record's measurement is exact. The decision is defensible: the model has no volatile semantics, the
duplicated read is a read (never a race) of an unchanged value, so no verdict can move; against C17 5.1.2.3#2 it is an
under-approximation, and CONTRACT D13, SUPPORTED and the consumer note all say so in those words. Honest.

**The `error` choice and the mini-run hole.** Real and correctly described: `record_error_at` only prints `unsupported:`
and pushes onto `st.errors` (`translation_effect.lem:250-257`); the mini-run calls plain `TranslateEff.runStateM`
(`mini_pipeline.lem:157`), so the errors list is dropped. Reproduced: `return x ?: 7` → oracle `unsupported:` +
`internal error: …TODO: elaboration of ?: operator`, rc 125, Lean PANIC with the same text, rc 134; `case (3 ?: 4):` →
`internal error: PEcase, mismatched ==> […]Unit` on both. Logged in TODO.md and tray 61. The pure `error` fires on the
mini-run path (my `r15`). Without `LEAN_ABORT_ON_PANIC` the Lean driver refuses to start (exit 2, `REFUSAL abort-flag`),
so the panic cannot become a default-value verdict. The crash-shaped wire form (uncaught `Failure` 125 / abort 134,
legacy, unattributed) is stated plainly in CONTRACT §3 row + D13, VALIDATION, the tsv and the consumer note.

**Byte identity and exit codes.** The witness script compares 18 whole lines; I compared a non-witnessed shape (the
statement expression `x03`) from the file name to the end of line: IDENTICAL, 844 bytes. Oracle 125 / Lean 134 on every
refusal probe; controls rc 0 with identical verdict lines.

**`--pp=core` / `--cabs-json`.** `--pp=core` on a refusing file: rc 125, stdout empty, the attributed `internal error:`
line on stderr — as the record §3.1 says. `--cabs-json` succeeds on every refusing probe (the runner's Lean leg ran from
it), as the record and the witness script's `cabs_ok` assert.

**Corpus measurement / moved rows.** The worker's sweep evidence is still in the worktree (`.tmp/sweep/sweep.log`:
`files=5591 refused=10`, `files=1669 refused=0`; `exit125_texts.tsv` 65 rows) and matches the record. My independent
spot-check of the baselined corpora (869 files: minimal, coverage, debug, immaculate, ci, lean_frontend/corpus, libc,
multi_tu, pnvi_refusals) through the new oracle's elaboration: 0 compound-assignment refusals; the 10 exit-125 files are
pre-existing crash classes (`tests/ci/0258`, `0270`, eight `tests/immaculate/nolibc/*` uncaught-exception witnesses). The
one scoreboard row is right: `torture_success.tsv:509` = `990222-1.c UB_MATCH UB:UB035_unsequenced_race`, the file's line
9 is `while ((*--ptr += 1) > '9') *ptr = '0';`, the ci-sweep walks `breakdown/success` only (`test_ci_sweep.sh:90`), the
pristine lane lists gcc-torture as not walked (`test_upstream_oracle.py:860-866`), and the `execute/` twin dies at
`abort` undeclared before the arm. The two survey "grep estimate" files fail to parse / lack `cerberus.h`, as the record
says, and are already `CERB_REJECT` (`torture_fail.tsv:2, :21`).

**Manifest.** Exactly the two translation rows moved; recomputed both: `translation.lem` sha256
`366ce0ab…` matches; the label-normalized unified diff of `translation.ml` against `$CERB_UPSTREAM_TREE` hashes to
`aec7ba96…`, matches.

**Fuel form and pin.** The generated worker is `match lemFuel with | 0 => failwithI … | succ => …` with the wrapper
`compound_assign_lhs_has_side_effect [LemFuel] := …_lemFuel LemFuel.fuel` and a `_zero` lemma by `rfl`; the pin
`example {a : Type} (n : Nat) : @compound_assign_lhs_has_side_effect a ⟨n⟩ = @…_lemFuel a n := rfl` is the generator's
own shape. The gate's census row is `AMBIENT no/front` for both the walker and `translate_expression`
(`.tmp/fuel_forms_table.tsv`), which is correct under `check_fuel_forms.sh:39-55`: ABSORBING requires the `_zero` RHS to
be the monad's absorbing element, and a `failwithI` of `Bool` is a value sentinel, hence AMBIENT; unreachable from the
drive cone, so no pending-register row. The record §2.4 says exactly this. (See P3-3 for the code comment.)

**Ride-alongs.** Float profile reproduced on both engines, identical: `sizeof` 8/8/8 (`Specified(888)`; gcc 240 =
4/8/16), `_Alignof` 8/8/8 (gcc 240), `(float)16777217 == 16777216` is 0 (gcc 1: a 53-bit float), `1.0L + 1e-17L == 1.0L`
is 1 (gcc 0: no 64-bit significand), `<float.h>` `FLT_MANT_DIG*10000 + DBL_MANT_DIG*100 + LDBL_MANT_DIG` = 245364 (24/53/64;
gcc 116 = 24/53/64 mod 256), `FLT_EPSILON` undefined (0; gcc 1). `_Bool b = 0.5; c = -0.25` → 11 on both. CONTRACT D6,
SUPPORTED and the record §8.1 state these facts correctly. The D12 record §8 correction reads as a paraphrase with its
tag; fine.

**Record integrity.** Machine outputs quoted verbatim; the derived tallies are labelled; rulings carry [USER]/[AGENT]
tags; the operator is not quoted. The record's own self-correction (the control miscount the plant caught) is recorded,
which is the right practice.

## 4. Findings

No P1. No P2.

**P3-1 — `_Generic`: the unselected associations are walked too, and the public docs say only "controlling expression".**
`frontend/model/translation.lem:1433-1439`: `AilEgeneric e1 _ gas` walks `e1` and EVERY association. Measured:
`a[_Generic(0, long: i++, default: 1)] += 3` (legal, `i++` never evaluated; gcc 13) now refuses on both engines, where
both answered 13 before. CONTRACT D13 / the §3 row, SUPPORTED and the consumer note say "a `_Generic` controlling
expression is walked (over)"; only the record §2.1 says "the controlling expression and every association". Fix (docs,
close-out commit): add "and every association, selected or not" at the three sites. Optional refinement for a later
slice (walker change → regenerate + manifest re-pin + a witness): the arm already has the selected index
(`AilEgeneric _ (Just idx) gas`, `translation.lem:2849`); walk `List.index gas idx`'s expression only and nothing else.
Acceptable as-is under "refuse until it hurts".

**P3-2 — The refusal text's trigger list is shorter than the predicate.** The pinned text names "an increment or
decrement, an assignment, a function call, a comma, a va_arg, a statement expression or a compound literal"; the walker
also fires on `AilEassert`, `va_start`/`va_copy`/`va_end` and (P3-1) `_Generic` operands. CONTRACT D13 lists them all.
Do not change the text now (18 pinned witnesses + a manifest re-pin for a wording nit); note the gap in the record §2.3
in one line so the next text revision (the WP2 envelope migration) folds it in.

**P3-3 — Code comment vocabulary: "ABSORBING" where the gate says AMBIENT.** `frontend/model/translation.lem:4720-4721`
("the same ABSORBING form as its caller translate_expression") and the M1 commit message use the gate's word for a
different class; the gate files the walker (and `translate_expression`) as `AMBIENT no/front`, and the record §2.4 has
to explain the mismatch. Fix (a comment edit → regenerate `Translation.lean`'s comment, `[source-content]` manifest row
re-pin, no semantic change): "the same declared form as its caller translate_expression (`failwithI` at fuel zero; the
fuel-forms gate files both as AMBIENT, unreachable from the drive cone); no measure, no proof". Can ride the close-out or
the next translation.lem touch.

**P3-4 — Row-1 cost and worktree hygiene.** (a) `check_compound_assignment_refusal.sh --selftest` runs the 30-case
battery six times (five plants + the real run; each case = oracle exec + Cabs export + Lean run, ~1.5 s), roughly 4-5 min
added to A1 (960 s at M2), the same shape as D10/D11/D12. Not a defect, but a gate-cruft watch item: a plant that must
fail N named witnesses could run only those. (b) The worktree's `.tmp` is 394 M (`sweep/csmith_stage`, `m1-lean.log`,
probe dirs); the record promises deletion at slice end — do it, naming the paths.

**Incidental, out of scope (pre-existing on the mainline b4a48f635, both engines, not caused or touched by this
slice):** a fully braced initializer of a struct containing an array of structs crashes before elaboration:
`struct T { int b; }; struct S { struct T a[2]; }; struct S s = {{{1},{2}}};` → oracle `internal error: Translation called
on Ail program with an invalid node` (rc 125), Lean the same PANIC (rc 134); gcc 12. Valid C17 (6.7.9#17-20). A crash,
never a wrong answer, so it is tolerated by the standing rule, but "turning a crash into a refusal is always a valid
refinement": worth a TODO/tray line. Probes `r01_struct_chain_postinc.c`, `a04_struct_chain.c` in the review scratch.

## 5. Residual uncertainty

- I did not run the witness script, the lane scripts or `release.py` (constraints); Tier A on M2 (20/20) and the full
  battery on the M3 tip are the orchestrator's evidence. My corpus spot-check covered the baselined directories (869
  files) through the oracle only; csmith, CN, libxml2, pKVM, gcc-torture rest on the worker's sweep logs, which I read
  and which match the record's numbers.
- The volatile decision is unobservable in the default profile; under the WP0 receipt instrument (row 13) the second
  load of a volatile subscript IS visible as an extra receipt on both engines — a known, declared consequence, not a
  discrepancy, since both engines are generated from the one arm.
- The over-approximation on calls refuses `tbl[hash(k)] += 1` and every `*p++ |= x`; the docs say so loudly. Whether
  that reach "hurts" is the operator's call at the consumer's first re-pin, as the consumer note anticipates.
