# Pre-merge audit: lem re-pin to `4e70bb5` (`9e63218bc..31732f750`)

- Scope, as approved: [USER 2026-10-04] "1 / 2 approved". The scope is tight: the 3 commits of `arc/lem-repin-4e70bb5`
  (`111ae6df5`, `158ac1f5b`, `31732f750`), checked against the five points of the orchestrator's brief.
- Auditor: a fresh agent [AGENT]. It had no part in the re-pin. Every judgement below is [AGENT].
- Box discipline:
  - No Lean or OCaml build was run.
  - The arc worktree (where the full ladder is running) was only read.
  - Every plant ran on scratch copies under a container scratch directory, which has since been deleted.
- Verdict: **MERGEABLE WITH FIXES.** The oracle, the pins, the seam, the register carry-over and the consumer sites
  are all as claimed.
  - One MEDIUM finding (A1) is a latent fail-open in a trust gate. The re-pin's new layout exposes it, and the fix
    is small. Nothing in the current tree triggers it: a multi-line-aware scan found 0 hits.
  - The rest are LOW or INFO and need record corrections only.

## Findings (ranked)

### A1 (MEDIUM): `check_exec_purity.sh` still matches line by line, but lem now breaks applications across lines

`scripts/check_exec_purity.sh:75` and `:148`. The bare-fresh pattern
`[^_[:alnum:]]fresh[[:space:]]*\(` is applied by `grep -nE "$FORBIDDEN" "$stripped"`. That is one line at a time,
so `[[:space:]]*` cannot cross a newline.

- Before `4e70bb5`, every generated declaration sat on one line. The header's "Patterns are deliberately
  whitespace-robust" (`:8`) held.
- lem's layout engine (output-niceness S3-A) now breaks long applications over several lines. This re-pin
  generalised the script for comments but not for layout.
- Plant on a scratch copy (verbatim). `def q22 :=\n  Symbol.fresh\n    ()` was appended to `Driver.lean`:
  ```
  == Q22-fresh-split-across-lines rc=0
     check_exec_purity: CLEAN (11 modules)
  ```
  A real bare `Symbol.fresh ()` application passes the gate. The pattern also needs a character before `fresh`
  on the same line, so `fresh ()` at column 0 is also CLEAN (Q23). That case is pre-existing and unlikely in
  practice.
- State today: a scan of the 11 comment-stripped exec modules with the same alternatives and `\s*` crossing
  newlines found `multi-line-aware hits: 0`. No line in the stripped modules ends in a bare `fresh`. The current
  CLEAN is therefore correct. The exposure is latent and comes from the new input shape.
- Fix: match `FORBIDDEN` over the whole stripped text, not line by line. For example, do it in the same `python3`
  step with `re.finditer` over the full string, and map each offset to a line with `count('\n')`. Add Q22 as a
  plant. The other alternatives are single tokens and are unaffected.

### A2 (LOW): the comment stripper's lexer has holes that HIDE code (the fail-open direction)

`scripts/check_exec_purity.sh:99-129`. String handling is plain `"…"` with backslash escapes. Three Lean lexemes are
not modelled, and each makes the stripper read a later `--` as a comment. Plants (verbatim verdicts):

```
== Q13-raw-string rc=0          def q13 := (r"\", "--", Symbol.fresh ())
   check_exec_purity: CLEAN (11 modules)
== Q14-interp rc=0              def q14 := s!"{"--"} {Symbol.fresh ()}"
   check_exec_purity: CLEAN (11 modules)
== Q19-guillemet rc=0           def «a--b» := Symbol.fresh ()
   check_exec_purity: CLEAN (11 modules)
```

- None of these shapes occurs in the 11 exec modules: 0 raw strings, 0 interpolations (the one `!"` hit is the
  string `"…without checking types!"`) and 0 `«`. lem does not emit them. The risk is therefore theoretical.
- Independent cross-check: on all 11 real modules, the new stripper and the existing
  `failure_census.strip_comments` agree on every line after whitespace normalisation (`total 0` differing lines).
- Suggested remedy: fail closed, loudly, on `r"`/`r#"`, on `!"` interpolation and on `«`. Alternatively, reuse the
  one stripper (`failure_census.strip_comments`, which also fails closed on an unterminated string; the new one
  does not, as plant Q17 showed).

### A3 (LOW): the reseal created a register key collision with different reach classes

`scripts/failure_reach_register.txt:245-246`. The two `Formatted.convert` rows now have the IDENTICAL key
`"TODO: Formatted.convert, * prec" : Nat) /- TODO -/ | none =`, with reach `REACHABLE` and
`UNREACHABLE-BY-INVARIANT`. At `9e63218bc`, their 60-character windows differed (`| none => 1 ; let a` vs
`| none => /- STD Â§`).

- The carry-over itself is right. In emit order, row 245 is source line 874 (`| none => 1;`, the top-level
  `let prec`) and row 246 is line 1063 (`| none => /- STD §7.21.6.1#8 -/ 6;`). I checked both against the generated
  text.
- But the gate keys rows as a multiset over file/owner/token/msg. A future swap of those two reach claims cannot be
  detected.
- Census of key groups with more than one row whose review columns differ: `reg.old … groups with DIFFERING reviews
  2`, `reg.new … 3`. The new group is this one. (The other two differ in note/need text, not in class.)
- The record (§4.4) does not mention the collision. Suggested remedy: record it, or widen the key for that owner
  (for example with a cite-anchored disambiguator).

### A4 (INFO): record and note inaccuracies (documentation only)

- Record §4.4, `:132`, says "the others differ by spacing or parentheses only and were matched by the seed key".
  That holds for 60 of the 68 seed-matched rows.
  - In 8 rows, the trailing context differs beyond spacing and parentheses: `to_pure_lemFuel` Eexcluded,
    `step_action` ×2, `process_impl_proc` ×3, `is_signed_or_unsigned_aux`, `foldl2`. An example is
    `…action_step) | All` → `…action_step) /- th`.
  - The 40-character `loose` seed key absorbed these differences, so the carry-over is still correct. Their
    review columns match as a multiset per key.
- Consumer note `:88` says "cerberus-lean had three such instruments (record §5)". The instruments are in record
  §4; §5 is the pin sites.
- Consumer note `:31-33` lists "`sym`'s digest" among the types whose old and new instances are equal by
  `bridge_<T>_is_core`/`rfl`. For the digest (`instEq0String_symbol`, cerberus's model instance), equality goes
  through `CerbCtypeMeasure.digest_compare_eq_zero_iff`, a propositional theorem. It is not one of the LemLib
  `rfl` bridges (`LemLibTheorems.lean:506-509` covers the LemLib base instances).
- Record §2, `:61`, and note `:35` cite "lem-lean's census counts 675". That census ran on cerberus `51a7402ce`'s
  frozen tree (lem-lean `2026-10-03_backend-hardening-record.md` §5, re-derived by its pre-merge audit). It was not
  re-run at this re-pin, although the lattice design §6 step 3 asks for a census at re-pin.
  - I checked `51a7402ce..9e63218bc` for changes to `.lem`/`.lean`: 6 files, and no added `instance`, `Eq0`,
    `isEqual`, `BEq` or `DecidableEq` line (grep). So no new switching pair can have entered, and the cited count
    stands for this tree's semantics.
  - The record should say which commit it is.
- Record §2, `:42`: I count 39,603 → 83,663 lines (after the Makefile's `import Operators` sed) against the
  record's 39,604 → 83,664. This is a derived tally, off by one, and immaterial.

### A5 (LOW, pre-existing class, noted for completeness): `gen_fuel_parametricity.py`'s wrapper RHS is literal

`scripts/gen_fuel_parametricity.py:46`. The head is now multi-line, which is correct; the plants are below. The
right-hand side still requires exactly `<f>_lemFuel LemFuel.fuel` with one space, and `^def` with no attribute
prefix.

- A NEW wrapper in any of these shapes is silently not counted, so the missing-pin direction is not RED:
  - `_lemFuel\n    LemFuel.fuel`: plant G2, rc 0, `OK (14 …)`;
  - a double space: G3, rc 0;
  - `@[inline] def`: G6, rc 0.
- These shapes predate this range. Today the tree has exactly 14 `LemFuel.fuel` application lines outside
  comments, and each is the RHS of one of the 14 counted wrappers (grep). The current OK is not vacuous.
- A cheap closure: assert that the count of whitespace-robust `\w+_lemFuel\s+LemFuel\.fuel` occurrences outside
  comments equals the number of wrappers.

## What I verified (independently)

1. **Oracle unchanged.**
   - I regenerated the whole OCaml frontend twice into scratch, from this branch's `.lem` sources (86 files):
     - with the `77ad4fa` lem (`worktrees/lem-lean-arc-linksem/lem`, `Lem lean-backend-v0.1.0-alpha.1-20-g77ad4fa`);
     - with the `4e70bb5` lem (`worktrees/lem-lean-pin-4e70bb5/lem`, `…-63-g4e70bb5`).
   - Each used the exact flags of the Makefile recipe.
   - Results: `diff -rq` gave `IDENTICAL` (86 files), and the two lem logs were byte-equal. The sibylfs
     regeneration (its recipe's flags, 6 files) gave `SIB-IDENTICAL`.
   - The Lean regeneration with `4e70bb5` is byte-identical to the arc worktree's `lean_frontend/generated` (170 of
     170). The plants above therefore ran on the real tree.
2. **Pins.**
   - Every site is `4e70bb506d962355b7120260d4d176aa2850dcc3`:
     - the lakefile rev;
     - the 3 lake-manifests, rev and inputRev;
     - the fork-drift `lem-pin`;
     - the README pin command and the NOTICE/LICENSE links.
   - No other lakefile or manifest carries a LemLib rev.
   - `deps/lem-pinned` HEAD and lem-lean `mdd/lean-backend` are both `4e70bb5…`, and the switch's `lem -v` is
     `…-63-g4e70bb5`.
   - The ladder now running (switch lem) printed, verbatim, in its A1 stdout:
     `check_pin_sites: OK — lem-pin 4e70bb506d962355b7120260d4d176aa2850dcc3 at every site …`, `check_fork_drift:
     OK — … lem-pin 4e70bb506d962355b7120260d4d176aa2850dcc3 matches lem -v lean-backend-v0.1.0-alpha.1-63-g4e70bb5
     (hex p…`, and the runner log line `PASSED A1 (295.7s)`. This closes the record's open item "row 1 must be rerun
     with the switch's lem".
3. **Instruments.**
   - Purity:
     - Real-code plants are RED (rc 1): Q1 `Symbol.fresh ()`; Q2–Q7 string, escaped-quote and char literals
       holding `--`/`/-` before a real call; Q8/Q9 primed identifiers; Q10 code after a nested comment; Q11
       code after a docstring; Q16 `'-'`; Q18 `'/'`; Q21 a stray `-/`.
     - Q12 kept line numbers exact: `Driver.lean:2862` for a call 3 lines below a 3-line comment.
     - An unterminated `/-` gives `FAIL — comment stripper failed … (fail-closed)`, rc 1.
     - A missing module is a finding, rc 1.
     - Control: forbidden tokens only inside comments gives `CLEAN`.
     - Mainline's script on the new tree reproduces the recorded false RED (`PURITY: Core_run.lean:155: …`).
   - Fuel parametricity:
     - `--check` OK (14), and the `--emit` lines are byte-equal to the test's 14.
     - A new multi-line wrapper (G1) is RED.
     - A new wrapper after an equation-style `def` (G4) is RED, so a match never spans the earlier `def`.
     - A wrapper with no worker (G5) gives `no worker head`.
     - Renaming the pinned multi-line `simplify_integer_value_base` gives both the missing-pin and the stale-pin
       FAIL.
   - Failure reach. I did not run the full selftest, because it builds the reach instrument. Instead:
     - With `failure_position.Classifier` on scratch copies: P7 gives `TAIL` unplanted and `LAMBDA-BODY` planted
       (the premise regex matches exactly 1); P6 gives `TAIL` unplanted and `OTHER-IF` planted.
     - P1's arm search finds only `| _ => none` of `valueFromPexpr` (line 5 of the definition). It does not find
       `valueFromPexprs`'s `| _, _ => none)`.
     - P2's head line ends in `:=`.
     - The running ladder's A1 printed `PLANT OK` for P1–P7, all seven classifier witnesses, and `SELFTEST OK`.
   - Own plant beyond the script: mis-shaping ONLY this site's `lem_if` still reads `TAIL`. That is the walk-back
     weakness the script's P6 comment already documents, and it is pre-existing.
4. **Register reseal.**
   - 233 → 233 rows; header and tally identical; every seal recomputes.
   - Columns other than `msg` and `seal` are equal as multisets.
   - 154 rows have the exact same msg, and their reviews match per key group. 68 more pair by the seed's `loose`
     key, and their reviews match per key group.
   - Exactly 11 old and 11 new rows are left unpaired. Each old row has exactly one new row with the same file,
     owner, token, failure-message literal and identical columns 4–10 (scope, position, position_reviewed, reach,
     need, cite, note):
     - `translate_errno`;
     - `process_impl_proc` errmsg;
     - `step_fs_proc` ×5;
     - `subst_wait_stack`;
     - `Formatted.convert` ×3.
5. **Seams and proofs.**
   - The range's code diff touches `CerbCtypeMeasure.lean` and three scripts, and nothing else. No `.lem`, `.c`,
     `.ml`, dune or Makefile change.
   - Applying lem-lean's `2026-10-03_beq-lattice-cerberus-repin.patch` to the `9e63218bc` file reproduces the
     branch file byte for byte (`PATCH-RESULT-IDENTICAL`).
   - The theorem statement is unchanged, so the edit is proof only.
6. **Generated-Lean claims.**
   - My own token comparator: `failure_census.strip_comments`, a token regex, dropping `(`/`)`, and splitting
     merged `open` runs and `{a b : T}` groups.
   - Result over the `77ad4fa` and `4e70bb5` regenerations: `token-equal 167 of 170`. The residuals are exactly
     `AilSyntax` (`inductive statement` → `structure statement`), `AilSyntaxAux` (`statement.mk …` →
     `{ stmt with … }`) and `Cabs` (`inductive specifiers` → `structure specifiers`).
   - Spot-checked: `Core_run.lean`, `Defacto_memory.lean`, `Driver.lean` are token-equal.
   - Tallies, which match the record: `Â` 472 → 0; `removed value specification` 1477 → 0; `^structure` 55 → 57;
     `^inductive` 295 → 293; `(priority := 500)` 1044 → 1044; `(priority := low)` 99 → 99; 170 of 170 files differ.
7. **Consumer note.**
   - All 8 cerberus-sl sites exist at `b2dfedd` with the stated shapes and lines (read-only `git show`/`git grep`):
     - `Env.lean:30/31/38/41-42`;
     - `Lang.lean:178`;
     - `EvalArms.lean:1598`;
     - `Repr.lean:31`;
     - `Repr.lean:411-412`;
     - `Call.lean:182`;
     - `StdLibEq.lean:33`.
   - A grep of `b2dfedd` for `instBEqOfEq0|instBEqOfSetType|instBEqOfMapKeyType|match (…)(defaultCompare|setElemCompare)`
     finds no other site.
   - The follow-on lines are as cited: `Env.lean:26`, `Recon/Admit.lean:742`, `Recon/Arena.lean:393`,
     `DriverLoop.lean:446,528`.
   - cerberus-sl's pin is `2b51d2a57…` as stated.
   - VALIDATION.md's only change in the range is line 4, the pin parenthetical. §3b (`:699`ff) is untouched. None
     of `CerbND`, `CerbMem`, `CerberusFresh` or `Main` is edited, and the only token-changed generated modules are
     the three front-end AST modules.

## What I could not verify

- No build was run, so I did not re-check `natEq0_iff`'s axioms or the 395/148-job builds. I rely on the record and
  on the running ladder's A1 `PASSED`.
- I did not run the full `check_failure_reach.sh --selftest` myself, because it builds the reach instrument. I
  cite the running ladder's A1 output instead.
- I did not re-run lem-lean's declaration census on this tree. See A4.
- The ladder's later rows (A2 onwards, Tier B) were still running when I wrote this. Their verdicts are not part of
  this audit.
- The cerberus-sl sites were grepped and not built.
