# Record — `match_pattern` fails closed on tuple-arity mismatch (cerberus-sl hidden-state note item 7) (2026-09-20)

**Status: DELIVERED — one commit on `fix/match-pattern-arity`** (worktree
`worktrees/cerberus-lean-fix/match-pattern-arity`, base mainline `5407597d9`, charter `0c15a1c11` =
`docs/2026-09-20_charter-match-pattern-arity.md`). Worker [AGENT Claude Fable]. Requested by the
consumer and endorsed by the operator on the consumer's side ([USER 2026-09-20, cerberus-sl
`docs/2026-09-20_run-digest-design-response.md` §4 Q5], verbatim: *"we can ask for this immediately"*;
the consumer's contract is quoted in the charter §0 and in §7 below). Same category and discipline as the
allocator fix (draft 44): a fail-open default in the shared model, unobservable on elaborator output,
wrong as such; shared body (both targets compute it), upstream-tray draft, no register row because no
lane observes it.

Every quoted block below is verbatim from a log under `.tmp/mpa/` (ephemeral; the lines are copied
here). Derived tallies are labelled DERIVED. Steps with wall times: regen 1:28 (22:01:18→22:02:46);
build chain 2:15 (`build_cerberus` 9 s, `build_lean` every root 28 s, speclab 98 s); the S5 wait for the
program-data-parameters worker's `release.py --mode full` before the build chain: 271 s (see §8).

## 0. The finding — TWO fail-open zips, verified pre-fix on the built model at `0c15a1c11`

The charter's facts (§1) held at the head. Both were exercised on the model AS BUILT before any edit
(probe recipe `scripts/lean_probe.sh`, from `lean_frontend/`; `.tmp/mpa/prefix-matcher-probe.log`,
`.tmp/mpa/prefix-typing-probe.log`), with `s1 s2 s3 := sym.Symbol "d" 1|2|3 SD_None`,
`tup2 := Pattern [] (CaseCtor Ctuple [p1, p2])`, `tup3 := … [p1, p2, p3]` (`pi := CaseBase (some si, _)`),
`wild := Pattern [] (CaseBase (none, BTy_unit))`, `v3 := Vtuple [Vunit, Vtrue, Vfalse]`,
`v2 := Vtuple [Vunit, Vtrue]`:

**The matcher (`core_aux.lem:2033-2039`), pre-fix — THE PRE-FIX QUOTE (T4's negative control):**

    pre-fix match_pattern tup2 v3 = some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)]
    pre-fix match_pattern tup3 v2 = some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)]
    pre-fix match_pattern tup2 v2 = some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)]
    pre-fix select_case (fun s v acc => (s,v) :: acc) v3 [(tup2, [] ), (wild, [(s3, Vunit)])] = some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)]
    pre-fix probe: the two truncating rfl examples elaborated

— a pattern of arity 2 MATCHED a value of arity 3 (binding the prefix), a pattern of arity 3 matched a
value of arity 2 (its third sub-pattern never bound), and `select_case` committed to the mismatching
pair arm ahead of the wildcard. The last line: `example : match_pattern tup2 v3 = some [(s1, Vunit),
(s2, Vtrue)] := by rfl` and its `tup3 v2` twin elaborated — the kernel's word on the pre-fix behaviour.

**The typechecker (`core_typing.lem:182-186`), pre-fix:**

    pre-fix typecheck_pattern (BTy_tuple [unit, boolean, boolean]) tup2 = Result (typed Ctuple pattern with 2 sub-patterns)
    pre-fix typecheck_pattern (BTy_tuple [unit, boolean]) tup3 = Result (typed Ctuple pattern with 2 sub-patterns)
    pre-fix typecheck_pattern (BTy_tuple [unit, boolean]) tup2 = Result (typed Ctuple pattern with 2 sub-patterns)
    pre-fix typecheck_pattern BTy_unit tup2 = Exception (CORE_TYPING other)

— both mismatch directions ACCEPTED; on the second line the typed pattern has TWO sub-patterns where
the input had three: the surplus sub-pattern is silently DROPPED from the pattern the rest of the
pipeline sees (a fact the charter did not list — an addition to its §1). Only the non-tuple expected type
is rejected (the existing `MismatchExpected "Ctuple" … "tuple"` arm).

## 1. D1 — the matcher, shared body (`frontend/model/core_aux.lem`)

The hunk, verbatim (`git diff -U2`):

```diff
@@ -2031,4 +2031,15 @@ let rec match_pattern (Pattern _ pat) cval =
 (*      | Vlist of core_base_type * list (generic_value 'sym) *)
     | (CaseCtor Ctuple pats', Vtuple cvals') -> 
+        (* FORK 2026-09-20 (cerberus-sl hidden-state note item 7; upstream-tray
+           draft 45): fail CLOSED on a tuple-arity mismatch. Lem's List.zip
+           TRUNCATES (library/list.lem:987-992, `| _ -> []` on unequal tails), so
+           without this guard a pattern of arity 2 MATCHED a value of arity 3
+           (binding the prefix) and a pattern of arity 3 matched a value of
+           arity 2. Mirrors upstream's own guard in simpl_match_pattern
+           (core_rewrite.lem:1287-1290). Nothing = NO MATCH, so select_case
+           tries the next arm; the bindings and their order are unchanged. *)
+        if List.length pats' <> List.length cvals' then
+          Nothing
+        else
         List.foldr (fun (pat', cval') acc ->
           Maybe.bind acc (fun xs ->
```

Nothing else in the arm; the fold, `x++xs` and `(Just [])` are untouched, so the bindings and their
order on a fitting match are today's. Generated (Lem 38f87d5): OCaml `if not ((List.length pats') =
(List.length cvals')) then None else List.fold_right …` (`ocaml_frontend/generated/core_aux.ml`), Lean
`if not ((List.length pats') == (List.length cvals')) then none else lemListFoldr …`
(`lean_frontend/generated/Core_aux.lean`).

## 2. D2 — the typechecker's rule, shared body (`frontend/model/core_typing.lem`)

```diff
@@ -181,4 +181,13 @@ and typecheck_pattern expected_bTy (Pattern annots pat) =
 
         | (Ctuple, BTy_tuple bTys, _) ->
+            (* FORK 2026-09-20 (upstream-tray draft 45): fail CLOSED on a
+               tuple-arity mismatch. Lem's List.zip TRUNCATES
+               (library/list.lem:987-992), so a Ctuple pattern whose arity differs
+               from the expected tuple type was ACCEPTED, the surplus sub-patterns
+               or component types silently dropped from the typed pattern. Same
+               error TYPE as the shape mismatch below; only the found-text differs. *)
+            if List.length bTys <> List.length pats then
+              E.fail loc (MismatchExpected "Ctuple" expected_bTy "tuple pattern of a different arity")
+            else
             List.unzip <$> E.mapM (fun (bTy, pat) ->
               typecheck_pattern bTy pat
```

Error TYPE kept (`MismatchExpected`, `errors.lem:29`); the found-text is STATIC — [AGENT] naming both
arities would need `show` on `nat` in `core_typing.lem`, whose availability there was not established
and whose import would sit outside the fence (the charter's own suggestion, `"tuple of matching
arity"`, reads oddly in the found slot given `pp_errors.ml:461-464`'s rendering *"this expression is of
type '<found>' but an expression of type '<expected>' was expected"*). `infer_pattern`'s `Ctuple` arm
(`:55-59`) infers from the pattern alone — nothing needed, as the charter said.

Rendered by the fixed fork oracle on the tray witness (§6), verbatim: `error: this expression is of type
'tuple pattern of a different arity' but an expression of type '(integer,integer,integer)' was expected`.

## 3. Regeneration and the build

`scripts/ce make prelude-src lean-prelude-src` (Lem 38f87d5; `.tmp/mpa/regen.log`), tail:

    [COPY] 49 hand-written Lean files (lean_frontend/handwritten_copy.manifest) into [lean_frontend/generated]
    check_handwritten_sync: OK (49 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
    [STAMP] recording Lean lem-sync content stamp
    check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 8c6c998668dcf84e3c07001145d92cf00723b78af8002e2a75408b0d5f2fc12c, gen ffca606c216b29167bce4e7ddfdb4a0ec23cfe9c47708afb353b4db24db54363)
    /home/dev/projects/cerberus-lean-proj/scripts/ce make prelude-src   82.37s user 1.34s system 94% cpu 1:28.14 total

Both generated trees compared against the primary checkout at mainline `5407597d9` (`diff -rq`): ONLY
`Core_aux.lean`, `Core_typing.lean` / `core_aux.ml`, `core_typing.ml` differ.

Build chain (`.tmp/mpa/build-all.log`; `scripts/common.sh` `build_cerberus` then `build_lean` — every Lake
root + the exe — then speclab), tails:

    === build_cerberus rc=0 end Sun Sep 20 10:12:11 PM UTC 2026 wall=9s
    ✔ [395/395] Built «cerberus-lean»:exe (544ms)
    Build completed successfully (395 jobs).
    check_driver_fresh: recorded lean stamp (bin 4a46813306ed37475d544a8352c92c375485f63be4c424168958b1bdb64d75fc, src 6e5ec9931b55850652e57b2b1185273836433a4a00fe2e29ef2e800585273057)
    === build_lean rc=0 end Sun Sep 20 10:12:39 PM UTC 2026 wall=28s
    Build completed successfully (148 jobs).
    === speclab rc=0 end Sun Sep 20 10:14:17 PM UTC 2026 wall=98s

The 28 s was checked, not accepted: the artifact timestamps (`ls --time-style=full-iso`) show
`Core_aux.olean` 22:12:13, `Core_typing.olean` 22:12:16, `Core_aux_lemMeasureProofs.olean` 22:12:18,
`Driver.olean` 22:12:24, the exe 22:12:39 — all AFTER the regenerated `generated/Core_aux.lean`
(22:02:44); the cone was rebuilt, in parallel, on the 32-core box. `tools/check_driver_fresh.sh --check`:
`oracle OK (bin a255e925…, src e45f2f58…)` / `lean OK (bin 4a468133…, src 6e5ec993…)`.

## 4. D4 — the measure proof re-established, statement unchanged

`lean_frontend/Core_aux_lemMeasureProofs.lean`, `match_pattern_stable_aux` (the induction behind
`match_pattern_measure_sufficient`, whose statement is byte-identical to before and to the generated
`Core_aux_auxiliary.lean:112-113` obligation). The generated tuple arm is now `if not (|pats'| == |cvals'|)
then none else lemListFoldr …`: after the existing `split <;> (try simp (disch := size_lt) only [key])`
the tuple-arm goal is an `ite` on both sides that `key` cannot rewrite under the fold's binder, so ONE
line was added before the unchanged `lemListFoldr_congr` block — the whole change (`git diff -U1`):

```
+        -- The tuple arm is `if not (|pats'| == |cvals'|) then none else lemListFoldr …` since the
+        -- fail-closed arity guard (match-pattern-arity slice, 2026-09-20; core_aux.lem match_pattern,
+        -- mirroring core_rewrite.lem:1287-1290): a NON-recursive branch. Split the `if`; the
+        -- mismatch branch is `none = none`; the other is the list traversal exactly as before.
+        all_goals (split <;> try rfl)
```

The `none = none` branch closes by `rfl`; the else-branch is exactly the previous goal. Kernel-only
tactics, no option bumps; compiled first time in the build chain (§3; `Core_aux_lemMeasureProofs.olean`
22:12:18). The only other measured worker whose body changed is none: `typecheck_pattern` is a
`partial def` in Lean (not fuel'd, not in the exec cone).

## 5. D3 — the kernel facts (`lean_frontend/test/Unit/MatchPatternArityTest.lean`, `match-pattern-arity-test`)

Registered in `lakefile.toml` (`[[lean_exe]]`, `moreLinkArgs = ["native/md5.o"]` — it imports `Core_aux`,
which reaches `CerberusFresh`) and in `scripts/test_unit.sh`'s `UNIT_TESTS` (14 exes now). Terms as in
§0. Facts (all compile-time; term-mode `rfl` = `Eq.refl`):

- **T1** `T1a : match_pattern tup2 v3 = none`, `T1b : match_pattern tup3 v2 = none`. The fuel wrapper:
  `T1_wrapper : match_pattern tup2 v3 = match_pattern_lemFuel (generic_pattern.lemSize tup2) tup2 v3 :=
  rfl` — the MEASURED wrapper is the worker at the pattern's own derived size (`declare {lean}
  fuel_measure val match_pattern = \`lemSize g\``, `core_aux.lem:2573`); `T1_anyFuel (n) (h : lemSize tup2
  ≤ n) : match_pattern_lemFuel n tup2 v3 = none` by `rw [Core_aux_lemMeasureProofs.
  match_pattern_measure_sufficient tup2 v3 n h]; exact T1a` — every fuel at or above the measure.
- **T2** `select_case (fun _ _ acc => acc) v3 [(tup2, "pair arm"), (wild, "wildcard arm")] = some
  "wildcard arm"` — the selector continues past the mismatching pair arm to the wildcard (`:2058-2061`'s
  unchanged "trying the next branch"); the substitution is a stand-in for `subst_sym_expr`/`_pexpr`
  (`select_case` is polymorphic in it).
- **T3** `match_pattern tup2 v2 = some [(s1, Vunit), (s2, Vtrue)]` (= the pre-fix answer on the fitting
  pair — §0's third line) and `T3_select : select_case (fun s v acc => (s, v) :: acc) v2 [(tup2, []),
  (wild, [(s3, Vunit)])] = some [(s1, Vunit), (s2, Vtrue)]` — bindings and their ORDER through the
  selector's right fold.
- **T4** the negative control: `T4_neg : match_pattern tup2 v3 ≠ some [(s1, Vunit), (s2, Vtrue)] := fun h
  => nomatch (T1a.symm.trans h)` — the pre-fix answer (§0's quote, also printed by `main`) is provably
  not returned; not a compiled decoy (the old matcher is not re-implemented). [AGENT] chosen over a
  `#guard_msgs` on the failing `rfl` because the theorem is stronger and does not pin an error text.
- **T5** the typing pin, RUNTIME (the generated `typecheck_pattern` is a `partial def` — no kernel
  equations — in the pure `exceptM (typing_env × pattern) (Loc × cause)` monad, no environment): `t5a
  := typecheck_pattern (BTy_tuple [BTy_unit, BTy_boolean, BTy_boolean]) tup2` and `t5b := typecheck_pattern
  (BTy_tuple [BTy_unit, BTy_boolean]) tup3` must be `Exception (_, CORE_TYPING (MismatchExpected "Ctuple"
  (BTy_tuple _) "tuple pattern of a different arity"))`; `t5c` (pair against pair) the positive control,
  `Result` with two sub-patterns.
- **Axiom pins** (`#guard_msgs in #print axioms`): `match_pattern`, T1a, T1b, T2, T3, T3_select, T4_neg
  each `depends on axioms: [propext]` — the trio or fewer; the proofs are `Eq.refl`/`nomatch`, and
  `propext` enters through the model's definitions: probe `.tmp/mpa/AxiomProbe.lean`, verbatim:

      'match_pattern' depends on axioms: [propext]
      'match_pattern_lemFuel' depends on axioms: [propext]
      'generic_pattern.lemSize' does not depend on any axioms
      'lemListZip' depends on axioms: [propext]
      'lemListFoldr' does not depend on any axioms
      'Lem_Maybe.bind0' does not depend on any axioms
      'value' does not depend on any axioms
      'generic_pattern' does not depend on any axioms
      'sym' does not depend on any axioms
      'select_case' depends on axioms: [propext]

  `T1_anyFuel depends on axioms: [propext, Classical.choice, Quot.sound]` (the sufficiency theorem's).
  Two iterations were needed to pin these: the first draft guessed "does not depend on any axioms"
  and used the `rfl` TACTIC; the build's diagnostics gave the true census, which is what is pinned.

**T1–T5 output, verbatim** (`scripts/ce scripts/test_unit.sh match-pattern-arity-test`, `.tmp/mpa/unit-mpa.log`; exit 0, wall 266 s including the suite's follow-on gates, §8):

    === match-pattern-arity-test ===
    ✔ [188/189] Built Unit.MatchPatternArityTest:c.o (345ms)
    ✔ [189/189] Built «match-pattern-arity-test»:exe (397ms)
    Build completed successfully (189 jobs).
    match-pattern-arity-test: match_pattern / typecheck_pattern fail closed on tuple-arity mismatch (cerberus-sl item 7); T1–T4 kernel-checked at compile time
    PASS T1a match_pattern tup2 v3: got none; pre-fix: some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)] (the truncating prefix — the defect)
    PASS T1b match_pattern tup3 v2: got none; pre-fix: some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)] (the truncating prefix — the defect)
    PASS T2 select_case v3 [(tup2, pair arm), (wild, wildcard arm)]: got some "wildcard arm"; pre-fix: some "pair arm" (the pair arm selected on a triple)
    PASS T3 match_pattern tup2 v2: got some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)]; pre-fix: some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)] (unchanged)
    PASS T3_select select_case cons v2 [(tup2, []), (wild, [(s3, Vunit)])]: got some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)]; pre-fix: some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)] (unchanged)
    PASS T5a typecheck_pattern (BTy_tuple [unit, boolean, boolean]) tup2: got Exception (CORE_TYPING (MismatchExpected "Ctuple" (BTy_tuple <3 components>) "tuple pattern of a different arity")); pre-fix: Result (typed Ctuple pattern with 2 sub-patterns) (ACCEPTED — the defect)
    PASS T5b typecheck_pattern (BTy_tuple [unit, boolean]) tup3: got Exception (CORE_TYPING (MismatchExpected "Ctuple" (BTy_tuple <2 components>) "tuple pattern of a different arity")); pre-fix: Result (typed Ctuple pattern with 2 sub-patterns) (ACCEPTED, third sub-pattern DROPPED — the defect)
    PASS T5c typecheck_pattern (BTy_tuple [unit, boolean]) tup2 (positive control): got Result (typed Ctuple pattern with 2 sub-patterns); pre-fix: Result (typed Ctuple pattern with 2 sub-patterns) (unchanged)
    match-pattern-arity-test: OK (8/8 runtime witnesses; kernel theorems T1a T1b T1_wrapper T1_anyFuel T2 T3 T3_select T4_neg compiled; #print axioms = [propext] on each, pinned by #guard_msgs)
    ✓ match-pattern-arity-test PASSED
    ==========================================
    Total: 1 passed, 0 failed


## 6. D5 — upstream-tray draft 45 and the witness

`lean_frontend/docs/upstream-tray/45-core-match-pattern-truncating-zip-arity.md` + INDEX row 45 (slotted
with the Core-level soundness gaps, behind the C-reachable true bugs). The witness is TEXT in the draft
(no fixture, no lane — charter §3), a `case` on a triple with a pair arm then a wildcard
(`.tmp/mpa/witness-arity.core`), run on the three engines 2026-09-20, verbatim (`Time spent` omitted):

    === PRISTINE b9aeedcb4 on witness-arity.core ===
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
    === FORK oracle (fixed) on witness-arity.core ===
    Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
    === PRISTINE --typecheck-core ===
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
    === FORK (fixed) --typecheck-core ===
    .tmp/mpa/witness-arity.core:5:7: error: this expression is of type 'tuple pattern of a different arity' but an expression of type '(integer,integer,integer)' was expected
        | (a: integer, b: integer) =>
          ^~~~~~~~~~~~~~~~~~~~~~~~ 

Pristine selects the pair arm binding the prefix (`1 + 2`); the fixed fork selects the wildcard (`0`);
with Core typing ON (`--typecheck-core`, default OFF in the driver — which is why the default-pipeline
fork line shows the MATCHER fix, not the typing rejection) pristine still accepts and the fork rejects at
the pattern. The Lean driver has no `.core` execution entry (`--parse-core` parses only), so its witness
is the kernel test (§5).

## 7. Consumer note (cerberus-sl)

What `SelectAgreesC`'s discharge can now rest on: the matcher returns `none` on any tuple-arity
mismatch (T1, and `T1_anyFuel` for every sufficient fuel), and the selector's fall-through is
`core_aux.lem:2058-2061`'s UNCHANGED code (`Nothing -> select_case subst_sym cval pat_pes'`), so a
wildcard arm after a mismatching tuple pattern is selected (T2); on a fitting match the bindings and
their order are exactly today's `x++xs` right fold (T3, T3_select). The selector equality
`select_case subst_sym_expr v pats = selectCaseE v pats` (and the `subst_sym_pexpr`/`selectCaseP` twin)
is THEIR theorem against THEIR calculus; T1–T3 are its matcher-level premises on concrete terms — the
general statement is the definition's now-guarded tuple arm plus the unchanged others. The typing guard
(D2) is additional: a `.core` input with a mismatched arity now fails Core typing on both fork engines.
Bundling: the consumer wants ONE re-pin covering E-A, the run-digest slice and this (their §4 Q4) — this
slice changes no signature (both fixes are inside existing bodies), so the re-pin cost is the semantics
rebuild alone. `subst_pattern_val`/`subst_pattern_pexpr` (`core_aux.lem:1123-1145`, tuple arm
`:1141-1143`) still zip: they run only AFTER a successful match, so their zips see equal lengths on
every reachable call — stated, not changed (charter §1, §3).

## 8. Gates

**Box discipline (S5).** At the slice's start the program-data-parameters worker's `release.py --mode
full --out .tmp/eada/regate-full` was running (its lanes B9→B12 during my light work; load average up to
55 on 32 cores at 22:01). Light work only until it ended: reads, the pre-fix probes, the two lem edits,
the test file, the regeneration (one lem process), the manifest rows, the tray draft. Waited for it,
polling every 30 s: `waited 271 s; release.py processes now: 0` (22:07:09→22:11:40); then the build
chain (§3), the unit test, and the battery below — one heavy job at a time. Four other `lean`/`bash`
processes on the box belonged to another project (`golean`), not to this container.

**Tier A row 1's own gates, verbatim** (the `test_unit.sh match-pattern-arity-test` run, `.tmp/mpa/unit-mpa.log`;
the suite runs every gate after the selected exe; exit 0):

    check_exec_purity: CLEAN (11 modules)
    check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
    check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 12 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
    check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 49 hand-written seam files + LemLibTest.lean)
    'match_pattern' depends on axioms: [propext]
    check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
    check_no_fuel_numerals: OK (326 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
    check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
    check_fuel_forms: forms partition OK (62 MEASURED + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
    check_failure_reach: OK (234 pure failure sites = the 234 register rows exactly (232 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=167 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
    check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
    check_lem_sync: OK (src 8c6c998668dcf84e3c07001145d92cf00723b78af8002e2a75408b0d5f2fc12c, gen f209620843823c5fafc6f45dfd64db7f7dcb4a7e80b42fdfca854f5e04112d8a)
    check_lem_sync: lean OK (src 8c6c998668dcf84e3c07001145d92cf00723b78af8002e2a75408b0d5f2fc12c, gen ffca606c216b29167bce4e7ddfdb4a0ec23cfe9c47708afb353b4db24db54363)
    check_fork_drift: OK — layer 1: 77 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 26 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)
    check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)

The fuel-forms population is the charter's 81/62/13/0/6, unchanged (`match_pattern` still MEASURED: its
obligation compiles against the new body, §4). The failure-reach register is unchanged at 234 rows — no
new leaf. DERIVED: fork-drift layer 2 reads 26 differing generated files where the S1.5 NOTE recorded 25
(+ `core_typing.ml`), layer 1 reads 77 (+ `core_typing.lem`); both are the §9 rows, accepted by the gate
with the hashes as pinned.

**The full battery, FIRST run** (`scripts/ce python3 scripts/release.py --mode full --out .tmp/mpa/release-full`,
launched 22:22:46 after an S5 check (`S5 wait before launch: 0 s`), ended 23:48:03 — wall 85 min; `.tmp/mpa/release-full.log`).
Every lane PASSED, verbatim:

    PASSED A1 (234.6s)
    PASSED A2 (28.6s)
    PASSED A3 (51.7s)
    PASSED A4 (22.9s)
    PASSED A4b (24.5s)
    PASSED A4c (3.1s)
    PASSED A5 (23.0s)
    PASSED A6 (2.2s)
    PASSED A6b (3.6s)
    PASSED A7 (10.4s)
    PASSED A8 (9.0s)
    PASSED A9 (17.2s)
    PASSED A10 (17.5s)
    PASSED A11 (59.2s)
    PASSED A12.1 (4.9s)
    PASSED A12.2 (4.5s)
    PASSED B1 (632.7s)
    PASSED B2 (22.9s)
    PASSED B3 (15.0s)
    PASSED B4 (45.1s)
    PASSED B5 (70.3s)
    PASSED B6.1 (76.1s)
    PASSED B6.2 (2.3s)
    PASSED B6.3 (9.6s)
    PASSED B6.4 (8.8s)
    PASSED B6.5 (9.3s)
    PASSED B6.6 (10.0s)
    PASSED B6.7 (8.7s)
    PASSED B7 (1315.1s)
    PASSED B8.1 (13.5s)
    PASSED B8.2 (224.7s)
    PASSED B8.3 (6.3s)
    PASSED B8.4 (16.0s)
    PASSED B9 (1320.6s)
    PASSED B10.1 (118.3s)
    PASSED B10.2 (1.8s)
    PASSED B11.1 (15.5s)
    PASSED B11.2 (7.0s)
    PASSED B12 (431.6s)

The pristine-oracle gate (B10.1/B10.2) and the chvalid row (B12), verbatim:

    Independent oracle scope: tier-b; 859 rows in 118.0s; source unchanged: True
    Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/match-pattern-arity/.tmp/mpa/release-full/B10.1/independent-oracle/report.json
    Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/match-pattern-arity/.tmp/mpa/release-full/B10.2/independent-oracle/report.json
    Independent oracle scope: libxml2_chvalid; 4 rows in 431.4s; source unchanged: True
    Independent oracle: passed; {'semantic_agreement': 4}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/match-pattern-arity/.tmp/mpa/release-full/B12/independent-oracle/report.json

The certification lines, verbatim:

    full: incomplete; 39/39 selected commands completed successfully.
    Source unchanged: False. Complete tier selection: True.
    Release certification: incomplete: reporting/adoption/audit exits require separate evidence.

**`Source unchanged: False` is THIS WORKER's defect, not the tree's:** the report's `source_before`/`source_after`
identities have the same `head` (`0c15a1c1…`), the same `status` and the same tracked-file `diff_sha256`
(`5b1f4859…`); they differ ONLY in `untracked_sha256` for 1 file(s): `lean_frontend/docs/2026-09-20_match-pattern-arity-record.md`
— I inserted §8's Tier A row-1 gate text into this record at 22:27, while the battery was running. No source
under test moved (the code, test, manifest and generated trees are identical before and after), and every
one of the 39 lanes passed — but the instrument is fail-closed on the whole working tree and the verdict is
`incomplete` as such, so it is NOT quoted as a green certification.

**Written justification, in advance, for a SECOND full battery (the ~1 h exception is exceeded: the first
took 85 min; grind-ban tripwire, container CLAUDE.md):** the standard gate, re-run unchanged on an UNTOUCHED
tree (no edit of any kind until it ends; `.tmp/` is gitignored and outside the identity), so that the slice
carries a clean `full: passed … Source unchanged: True` instead of a worker-explained `incomplete`. It is a
measurement sweep over the differential corpora — the class the tripwire names as qualifying — not a
brute-force build or proof pass; nothing in it is iterated or tuned.

**The full battery, SECOND run — the certification** (same command, `--out .tmp/mpa/release-full`; the tree
untouched from launch to end; `.tmp/mpa/release-full-run2.log`). ; .
Every lane, verbatim:

    PASSED A1 (230.6s)
    PASSED A2 (50.0s)
    PASSED A3 (54.3s)
    PASSED A4 (22.9s)
    PASSED A4b (24.7s)
    PASSED A4c (3.2s)
    PASSED A5 (22.7s)
    PASSED A6 (2.2s)
    PASSED A6b (3.7s)
    PASSED A7 (11.3s)
    PASSED A8 (9.5s)
    PASSED A9 (17.8s)
    PASSED A10 (17.3s)
    PASSED A11 (59.3s)
    PASSED A12.1 (4.9s)
    PASSED A12.2 (4.5s)
    PASSED B1 (633.2s)
    PASSED B2 (23.6s)
    PASSED B3 (15.7s)
    PASSED B4 (46.8s)
    PASSED B5 (68.4s)
    PASSED B6.1 (2.3s)
    PASSED B6.2 (2.3s)
    PASSED B6.3 (2.6s)
    PASSED B6.4 (2.9s)
    PASSED B6.5 (3.3s)
    PASSED B6.6 (3.9s)
    PASSED B6.7 (2.8s)
    PASSED B7 (1322.1s)
    PASSED B8.1 (13.3s)
    PASSED B8.2 (249.8s)
    PASSED B8.3 (6.4s)
    PASSED B8.4 (16.2s)
    PASSED B9 (1334.6s)
    PASSED B10.1 (117.1s)
    PASSED B10.2 (1.8s)
    PASSED B11.1 (15.0s)
    PASSED B11.2 (6.8s)
    PASSED B12 (415.9s)

B10.1/B10.2/B12, verbatim:

    Independent oracle scope: tier-b; 859 rows in 116.9s; source unchanged: True
    Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/match-pattern-arity/.tmp/mpa/release-full/B10.1/independent-oracle/report.json
    Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/match-pattern-arity/.tmp/mpa/release-full/B10.2/independent-oracle/report.json
    Independent oracle scope: libxml2_chvalid; 4 rows in 415.7s; source unchanged: True
    Independent oracle: passed; {'semantic_agreement': 4}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/match-pattern-arity/.tmp/mpa/release-full/B12/independent-oracle/report.json

The certification lines, verbatim:

    full: passed; 39/39 selected commands completed successfully.
    Source unchanged: True. Complete tier selection: True.
    Release certification: incomplete: reporting/adoption/audit exits require separate evidence.

ZERO movement on every lane: each is a `--check-baseline`/pinned-expectation gate that fails on any change,
and every one PASSED; the pristine-oracle counts equal mainline's at `5407597d9` (822/28/7/2 — the 822
head: E-A's seven witnesses have not landed on mainline, so the charter's 829 does not apply) — no
`difference` anywhere, stop rule S2 not triggered. Tier A rows 1–12 incl. 4b/4c/6b and Tier B rows
4, 5, 6, 7, 8, 9, 10, 12 are all inside this run (as are B1–B3 and B11).

## 9. Manifest rows (`scripts/fork_drift_manifest.txt`; single rows + one dated NOTE at the top of the header, no `--refresh`)

Were `core_aux.ml` / `core_typing.ml` upstream-identical before? **`core_typing.ml`: YES** — absent from
both layer-2 sections (byte-identical to `deps/cerberus-upstream/ocaml_frontend/generated`), and
`core_typing.lem` absent from `[files]` (byte-identical to upstream's source). **`core_aux.ml`: NO** — it
sat in `[expected-cosmetic]` (`c0546a67…`), its delta being the trailing-newline echo only; `core_aux.lem`
was already a `[source-content]` pin (`547a673e…`, the fuel declarations). Row changes (`git diff`, the
non-comment lines):

    +frontend/model/core_typing.lem
    -100644 547a673e1005de22b202460107a8c14f2e3c5cd40c697a213432fe4956d28514 frontend/model/core_aux.lem
    +100644 28b4d0858adcab19914ca8d71c9a98254edefca78e48b0bd4f3e6ae47244f622 frontend/model/core_aux.lem
    +100644 35c090070962daa56c87ceb9cbc6c83030e7113de304d70a738a35bc7d829b51 frontend/model/core_typing.lem
    +c2e521a92e83a56a8dab06139196f33e96bd3854300896f5725ef56f8b04fe1d core_aux.ml
    +b8f9c4bd7a5fd9a495d2901a37b2659c5a073a6a593aff9c5869a76d8c5d3c5e core_typing.ml
    -c0546a677a6bcdd16cc1630ad2360179ef2b74406520e27ec4d7378c6155a8f6 core_aux.ml

i.e. layer 1: `core_aux.lem` re-pinned, `core_typing.lem` NEW to `[files]` + its content pin; layer 2:
`core_aux.ml` MOVED from `[expected-cosmetic]` to `[expected-semantic]` with the new diff hash (the guard
+ the same newline echo — the unified diff against upstream is in `.tmp/mpa`'s session log and reproduced
in the tray draft's Description), `core_typing.ml` a NEW `[expected-semantic]` row. Hashes computed by the
gate's own recipes (`sha256` of the file; `sha256` of the label-normalised `diff -u`), then verified by the
gate itself (§8). `scripts/failure_reach_register.txt`: unchanged — neither fix adds a `failwithI`/`panic!`
leaf (`Nothing`/`E.fail`); `scripts/upstream_oracle_differences.json`: untouched (no lane observes the
fix).

## 10. Deviations from the charter, and notes

- The typing found-text is `"tuple pattern of a different arity"` (static), not the charter's example
  wording — §2 has the reason. Error TYPE as chartered.
- T4 as a theorem (`≠`), not a `#guard_msgs` on a failing `rfl` — §5.
- The axiom pins say `[propext]`, not "axiom-free": the charter's bar was "the trio or fewer", which
  holds; the first draft's "axiom-free" guess was corrected from the build's own census (§5).
- The charter's §1 did not list that the pre-fix typechecker DROPS surplus sub-patterns from the typed
  pattern (§0) — recorded here and in the draft; no scope change.
- `lean_frontend/VALIDATION.md` and `scripts/LADDER.md` (row 1's exe count) are outside the fence and
  were not touched; the orchestrator may want a §3 "Fork ≠ pristine" line for the typing guard
  (observable only on `.core` input under `--typecheck-core`, a mode no lane runs) and the LADDER count.
- No stop rule fired: S1 (the proof re-established), S2 (no lane moved — §8), S3 (no step near 45 min),
  S4 (no rule conflict), S5 (waited, §8).

## 11. Updated files

`frontend/model/core_aux.lem`, `frontend/model/core_typing.lem`, `lean_frontend/Core_aux_lemMeasureProofs.lean`,
`lean_frontend/test/Unit/MatchPatternArityTest.lean` (new), `lean_frontend/lakefile.toml`,
`scripts/test_unit.sh`, `scripts/fork_drift_manifest.txt`,
`lean_frontend/docs/upstream-tray/45-core-match-pattern-truncating-zip-arity.md` (new),
`lean_frontend/docs/upstream-tray/INDEX.md`, `lean_frontend/TODO.md`, this record.
