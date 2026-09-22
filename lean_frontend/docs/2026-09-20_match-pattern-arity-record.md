# Record — `match_pattern` fails closed on tuple-arity mismatch (cerberus-sl hidden-state note item 7) (2026-09-20)

**Status: DELIVERED — one commit on `fix/match-pattern-arity` (`14457f1a0`), then the CLOSURE ROUND (§12, 2026-09-22) as a second commit after the pre-merge audit** (worktree
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

**Scope of what D2 enforces (corrected 2026-09-22, audit R1):** D2 guards the tuple PATTERN rule only. The
typechecker's tuple-EXPRESSION arms (`typecheck_pexpr`'s `PEctor Ctuple`, `typecheck_expr`'s `Eunseq`/`Epar`) kept
zipping — and DELETED surplus operands — until the closure round (§12 R1). After §12, a `.core` input whose
tuple pattern, tuple expression, `unseq` or `par` has an arity different from its (expected) tuple type fails
Core typing on both fork engines when Core typing runs (`--typecheck-core`; OFF by default in the driver).
The remaining truncating zips in `core_typing.lem` are CALL-arity checks (`PEcall`, `Eproc`/`Eccall`/`Erun`
argument lists) — a different class, listed in TODO.md, not enforced by this slice.

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
which reaches `CerberusFresh`) and in `scripts/test_unit.sh`'s `UNIT_TESTS` (13 exes on this branch — the run's `Total: 13 passed, 0 failed`; the charter's "14" counted the enum arc's exe, audit N1). Terms as in
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
rebuild alone. ~~`subst_pattern_val`/`subst_pattern_pexpr` (`core_aux.lem:1123-1145`, tuple arm `:1141-1143`) still zip: they run
only AFTER a successful match, so their zips see equal lengths on every reachable call — stated, not changed
(charter §1, §3).~~ **FALSE (audit R2, 2026-09-22):** there is no `subst_pattern_pexpr`, and `subst_pattern_val`,
`unsafe_subst_pattern`, `subst_pattern`, `update_env_aux` are reached WITHOUT a prior `match_pattern`
(`to_pure`/`pure_propagation2 → subst_pattern`; the let-forms of both engines → `update_env`). The closure round
(§12) guards every one of them; the consumer facts T1–T3 are unchanged by it, and `select_case`'s `none`/
fall-through is exactly as before.

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

## 12. CLOSURE ROUND (2026-09-22) — the pre-merge audit's R1/R2/N1, orchestrator rulings

**Trigger.** Codex audited `5407597d9..14457f1a0` (`docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit.md`,
commit `44e7989af` on `audit/enum-repairs-20260921`, evidence dir `…-audit-evidence/arity/`): the two guards are
correct and both batteries pass, but two P2 findings in the SURROUNDING typing/binding paths (R1, R2) and one P3
on assurance text (N1) must be addressed before landing. Rulings [AGENT orchestrator, 2026-09-22]: ONE closure
commit, fence extended to the sites below, then the frozen full re-gate, then STOP for the delta audit. The
orchestrator reproduced R1 and R2 on this head's fork binary; so did this worker (§12.2).

### 12.1 The findings, verified pre-fix (the model as built at `14457f1a0`)

**R1 — the typechecker's tuple-EXPRESSION arms delete operands.** `core_typing.lem:884-887` (`typecheck_pexpr`,
`(Ctuple, BTy_tuple bTys, _)`: `E.mapM … (List.zip bTys pes) >>= fun pes' -> E.return (PEctor Ctuple pes')`),
reached from the `PElet` inference branches `:772-782`/`:1174-1181` and the `Elet` rule `:1709-1718`; `Eunseq`
`:1786-1795` and `Epar` `:1853` (same shape — the ruling's "fix if it is the same shape": it is). Pre-fix, the
Lean model (`.tmp/mpa/prefix-r1r2-probe.log`, verbatim):

    pre-fix typecheck_pexpr tys2 tup3 = Result (PEctor Ctuple with 2 operands)
    pre-fix typecheck_pexpr tys3 tup2 = Result (PEctor Ctuple with 2 operands)
    pre-fix typecheck_pexpr tysNested nested = Result (PEctor Ctuple with 2 operands)
    pre-fix typecheck_pexpr tys2 tup2 (fitting) = Result (PEctor Ctuple with 2 operands)
    pre-fix typecheck_expr tys2 (Eunseq [u,u,u]) = Result (Eunseq with 2 operands)
    pre-fix typecheck_expr tys3 (Eunseq [u,u]) = Result (Eunseq with 2 operands)
    pre-fix typecheck_expr tys2 (Epar [u,u,u]) = Result (Epar with 2 operands)
    pre-fix typecheck_expr tys3 (Epar [u,u]) = Result (Epar with 2 operands)

— three operands typed against two types come back as TWO (the third deleted); two against three come back as two
(the third type dropped). The audit's table (its `pure-let-mismatch.core`, quoted verbatim in tray 45 "The
surrounding paths") and its `error(<<<surplus>>>, 3)` witnesses: default `Error {msg: "surplus"}`, with
`--typecheck-core` `Specified(3)` — typing deleted the erroring operand.

**R2 — the other tuple-binding paths bypass the matcher.** `core_run.lem:872-879` (ordinary `Elet` → `update_env`),
`:1450`/`:1494` (`Ewseq`/`Esseq` on an evaluated first operand → `update_env`), `core_aux.lem:2459-2462`
(`update_env_aux`'s zip; and — the driver's actual engine, see §12.3 — `core_reduction.lem:351-426`'s six let-form
sites, all `update_env`), and `subst_pattern_val`/`unsafe_subst_pattern`/`subst_pattern` reached through `to_pure`
(`core_aux.lem:1536-1546`) and `pure_propagation2` (`core_rewrite.lem:1187-1193, 1219-1225`) with NO `match_pattern`
before them. `Core_reduction`'s let-forms (`core_reduction.lem:351-426`) also bind through `update_env` — and that is THE
engine the driver steps with (§12.3). Pre-fix, the Lean model (`.tmp/mpa/prefix-r1r2-probe.log`,
`.tmp/mpa/prefix-r2-env-probe.log`, verbatim; shapes = the audit's `ArityAudit.lean`):

    pre-fix subst_pattern_val (flat 2) (vals 3) body = Epure (PEval Vunit)   [= unitBody: key 0 WAS substituted]
    pre-fix unsafe_subst_pattern (flat 2) (mk_value_pe (vals 3)) body = Epure (PEval Vunit)   [= unitBody: key 0 WAS substituted]
    pre-fix unsafe_subst_pattern (flat 2) (PEctor Ctuple [u,u,u]) body = Epure (PEval Vunit)   [= unitBody: key 0 WAS substituted]
    pre-fix subst_pattern (flat 2) (mk_value_pe (vals 3)) body = some (Epure (PEval Vunit)   [= unitBody: key 0 WAS substituted])
    pre-fix subst_pattern (flat 2) (PEctor Ctuple [u,u,u]) body = some (Epure (PEval Vunit)   [= unitBody: key 0 WAS substituted])
    pre-fix update_env_aux (flat 2) (vals 3) fmapEmpty : bound keys = [0, 1]
    pre-fix update_env_aux (flat 3) (vals 2) fmapEmpty : bound keys = [0, 1]
    pre-fix update_env_aux (flat 2) (vals 2) fmapEmpty (fitting) : bound keys = [0, 1]

### 12.2 The pre-fix ENGINE quotes (the fork binary built at `14457f1a0`, the audit's probes; `.tmp/mpa/prefix-oracle-closure.log`, verbatim, `Time spent` omitted)

    === PRE-FIX fork@14457f1a0 pure-let-mismatch.core ===
    --- default:
    Error {msg: "ill-formed program: `PElet: the pattern didn't match pe1'"}
    --- --typecheck-core:
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
    --- --rewrite:
    Error {msg: "ill-formed program: `PElet: the pattern didn't match pe1'"}
    === PRE-FIX fork@14457f1a0 let-mismatch.core ===
    --- default:
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
    --- --typecheck-core:
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
    --- --rewrite:
    Error {msg: "ill-formed program: `PElet: the pattern didn't match pe1'"}
    === PRE-FIX fork@14457f1a0 let-nested-mismatch.core ===
    --- default:
    Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
    --- --rewrite:
    Error {msg: "ill-formed program: `PElet: the pattern didn't match pe1'"}
    === PRE-FIX fork@14457f1a0 unseq-weak-mismatch.core ===   (unseq-strong-mismatch.core: identical)
    --- default:
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
    --- --typecheck-core:
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
    --- --rewrite:
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
    === PRE-FIX fork@14457f1a0 pure-let-discarded-error.core ===   (unseq-discarded-error.core: identical)
    --- default:
    Error {msg: "surplus"}
    --- --typecheck-core:
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}

(`seq-weak-mismatch.core`/`seq-strong-mismatch.core` — `let weak (a, b) = pure (1, 2, 3)` — do not PARSE on any
engine: `error: unexpected token ','`; the audit's parser-exploration file records the same; the `unseq` twins
are the parsing witnesses of the `Ewseq`/`Esseq` path.) R1 and R2 both hold, exactly as the audit's tables say.

### 12.3 The fixes (shared body; every hunk verbatim in `.tmp/mpa/closure-hunks.diff`, reproduced here)

```diff
--- a/frontend/model/core_aux.lem
+++ b/frontend/model/core_aux.lem
@@ -1122,2 +1122,19 @@ and subst_sym_paction sym cval (Paction p act) =
 
+(* FORK 2026-09-22 (upstream-tray draft 45; R2 of the pre-merge audit
+   lean_frontend/docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit.md):
+   THE ONE loud leaf of the tuple-BINDING helpers below — subst_pattern_val,
+   unsafe_subst_pattern, subst_pattern, update_env_aux — on a tuple-arity
+   mismatch. Each binds a tuple pattern against a tuple by List.zip, which
+   TRUNCATES (library/list.lem:987-992): a pattern of arity 2 against a tuple
+   of arity 3 silently bound the prefix. They are reached WITHOUT a prior
+   match_pattern (to_pure and core_rewrite's pure_propagation2 -> subst_pattern;
+   the Core_run/Core_reduction let-forms -> update_env), so each guards its own
+   arity. A mismatch is a malformed Core program (the Core typechecker is OFF by
+   default) and the outcome is this leaf: OCaml Cerb_debug.error, Lean
+   LemLib.failwithI — one reviewed row of scripts/failure_reach_register.txt. *)
+val tuple_arity_error: forall 'a. string -> nat -> nat -> 'a
+let tuple_arity_error who n_pats n_vals =
+  error ("Core_aux." ^ who ^ ": tuple pattern of arity " ^ show n_pats ^
+         " bound to a tuple of arity " ^ show n_vals ^ " (upstream-tray draft 45)")
+
 val     subst_pattern_val: forall 'a. pattern -> value -> expr 'a -> expr 'a
@@ -1140,2 +1157,6 @@ let rec subst_pattern_val (Pattern _ pat) cval expr =
     | (CaseCtor Ctuple pats', Vtuple cvals) ->
+        (* FORK 2026-09-22: arity guard (see tuple_arity_error above) *)
+        if List.length pats' <> List.length cvals then
+          tuple_arity_error "subst_pattern_val" (List.length pats') (List.length cvals)
+        else
         List.foldr (fun (pat', cval') acc ->
@@ -1424,2 +1445,6 @@ let rec unsafe_subst_pattern (Pattern _ pat) pe' expr =
     | (CaseCtor Ctuple pats', Pexpr _ () (PEval (Vtuple cvals))) ->
+        (* FORK 2026-09-22: arity guards (see tuple_arity_error) *)
+        if List.length pats' <> List.length cvals then
+          tuple_arity_error "unsafe_subst_pattern" (List.length pats') (List.length cvals)
+        else
         List.foldr (fun (pat', cval) acc ->
@@ -1428,2 +1453,5 @@ let rec unsafe_subst_pattern (Pattern _ pat) pe' expr =
     | (CaseCtor Ctuple pats', Pexpr _ _ (PEctor Ctuple pes)) ->
+        if List.length pats' <> List.length pes then
+          tuple_arity_error "unsafe_subst_pattern" (List.length pats') (List.length pes)
+        else
         List.foldr (fun (pat', pe) acc ->
@@ -1507,2 +1535,6 @@ let rec subst_pattern (Pattern _ pat) pe' expr =
     | (CaseCtor Ctuple pats', Pexpr _ () (PEval (Vtuple cvals))) ->
+        (* FORK 2026-09-22: arity guards (see tuple_arity_error) *)
+        if List.length pats' <> List.length cvals then
+          tuple_arity_error "subst_pattern" (List.length pats') (List.length cvals)
+        else
         Just $ List.foldr (fun (pat', cval) acc ->
@@ -1511,2 +1543,5 @@ let rec subst_pattern (Pattern _ pat) pe' expr =
     | (CaseCtor Ctuple pats', Pexpr _ _ (PEctor Ctuple pes)) ->
+        if List.length pats' <> List.length pes then
+          tuple_arity_error "subst_pattern" (List.length pats') (List.length pes)
+        else
         List.foldr (fun (pat', pe) acc ->
@@ -2459,2 +2494,8 @@ let rec update_env_aux (Pattern _ pat) cval env =
     | (CaseCtor Ctuple pats', Vtuple cvals) ->
+        (* FORK 2026-09-22: arity guard (see tuple_arity_error) — Core_run's
+           let-forms check match_pattern first and report Illformed_program;
+           Core_reduction's reach this leaf directly *)
+        if List.length pats' <> List.length cvals then
+          tuple_arity_error "update_env_aux" (List.length pats') (List.length cvals)
+        else
         List.foldr (fun (pat', cval') acc ->
--- a/frontend/model/core_reduction.lem
+++ b/frontend/model/core_reduction.lem
@@ -11,2 +11,3 @@ import Cerb_attributes
 import Core_run
+import Errors (* FORK 2026-09-22 (audit R2): Illformed_program for the let-form fit checks *)
 (* Lean: the executable fuel MEASURE of the get_ctx/get_ctx_unseq_aux block
@@ -350,3 +351,16 @@ let one_step eval_pexpr full_eval_pexpr env (Expr annots expr_ as expr) =
               (* reduction: LET(last step) *)
-              Just (TAU "Elet" (update_env pat cval env) e2)
+              (* FORK 2026-09-22 (upstream-tray draft 45; audit R2): Core_reduction is the
+                 driver's stepping engine (drive_core_thread2 -> core_step2 -> step_ctx -> one_step);
+                 its let-forms bind through update_env, which never consults the matcher. Check
+                 that the pattern FITS first and report a non-fitting one (a tuple-arity mismatch
+                 in particular) as the SAME Illformed_program the PElet route reports
+                 (core_eval.lem select_case), through the same monadic channel — so the default
+                 path and --rewrite (which turns this Elet into that PElet) agree. update_env's own
+                 guard, tuple_arity_error, stays the loud backstop. *)
+              match match_pattern pat cval with
+                | Nothing ->
+                    Just (TAU_WITH_RUNSTATE "Elet" (SEU.runEU (EU.fail (Errors.Illformed_program "Elet: the pattern didn't match pe1"))))
+                | Just _ ->
+                    Just (TAU "Elet" (update_env pat cval env) e2)
+              end
           | Nothing ->
@@ -359,3 +373,7 @@ let one_step eval_pexpr full_eval_pexpr env (Expr annots expr_ as expr) =
                   full_eval_pexpr pe1 >>= fun cval ->
-                  E.return (update_env pat cval env, e2)
+                  (* FORK 2026-09-22 (audit R2): the pattern must fit — see the value case above *)
+                  match match_pattern pat cval with
+                    | Nothing -> SEU.runEU (EU.fail (Errors.Illformed_program "Elet: the pattern didn't match pe1"))
+                    | Just _ -> E.return (update_env pat cval env, e2)
+                  end
                 end
@@ -397,3 +415,7 @@ let one_step eval_pexpr full_eval_pexpr env (Expr annots expr_ as expr) =
               (* reduction: LETW-PURE *)
-              TAU "Ewseq" (update_env pat cval env) e2
+              (* FORK 2026-09-22 (audit R2): the pattern must fit — see Elet above *)
+              match match_pattern pat cval with
+                | Nothing -> TAU_WITH_RUNSTATE "Ewseq" (SEU.runEU (EU.fail (Errors.Illformed_program "Ewseq: the pattern didn't match e1")))
+                | Just _ -> TAU "Ewseq" (update_env pat cval env) e2
+              end
           | Nothing ->
@@ -406,3 +428,7 @@ let one_step eval_pexpr full_eval_pexpr env (Expr annots expr_ as expr) =
               (* reduction: LETW-ANNOT *)
-              TAU "Ewseq Eannot" (update_env pat cval env) (Expr [] (Eannot xs e2))
+              (* FORK 2026-09-22 (audit R2): the pattern must fit — see Elet above *)
+              match match_pattern pat cval with
+                | Nothing -> TAU_WITH_RUNSTATE "Ewseq Eannot" (SEU.runEU (EU.fail (Errors.Illformed_program "Ewseq: the pattern didn't match e1")))
+                | Just _ -> TAU "Ewseq Eannot" (update_env pat cval env) (Expr [] (Eannot xs e2))
+              end
           | Nothing ->
@@ -415,3 +441,7 @@ let one_step eval_pexpr full_eval_pexpr env (Expr annots expr_ as expr) =
               (* reduction: LETS-PURE *)
-              TAU "Esseq" (update_env pat cval env) e2
+              (* FORK 2026-09-22 (audit R2): the pattern must fit — see Elet above *)
+              match match_pattern pat cval with
+                | Nothing -> TAU_WITH_RUNSTATE "Esseq" (SEU.runEU (EU.fail (Errors.Illformed_program "Esseq: the pattern didn't match e1")))
+                | Just _ -> TAU "Esseq" (update_env pat cval env) e2
+              end
           | Nothing ->
@@ -425,3 +455,7 @@ let one_step eval_pexpr full_eval_pexpr env (Expr annots expr_ as expr) =
               (* reduction: LETS-ANNOT *)
-              TAU "Esseq Eannot" (update_env pat cval env) (Expr [] (Eannot xs e2))
+              (* FORK 2026-09-22 (audit R2): the pattern must fit — see Elet above *)
+              match match_pattern pat cval with
+                | Nothing -> TAU_WITH_RUNSTATE "Esseq Eannot" (SEU.runEU (EU.fail (Errors.Illformed_program "Esseq: the pattern didn't match e1")))
+                | Just _ -> TAU "Esseq Eannot" (update_env pat cval env) (Expr [] (Eannot xs e2))
+              end
           | Nothing ->
--- a/frontend/model/core_run.lem
+++ b/frontend/model/core_run.lem
@@ -875,6 +875,18 @@ BEFORE EVAL_PEXPR2
                   | Right cval ->
-                      E.return <| th_st with
-                        arena= e2;
-                        env= update_env pat cval th_st.env
-                      |>
+                      (* FORK 2026-09-22 (upstream-tray draft 45; audit R2): the
+                         ordinary let binds through update_env, which never consults
+                         the matcher — so check that the pattern FITS first, and report
+                         a non-fitting one (a tuple-arity mismatch in particular) as the
+                         SAME Illformed_program the PElet route reports
+                         (core_eval.lem select_case) — core_rewrite turns this Elet
+                         into that PElet, and default = --rewrite must hold. *)
+                      match match_pattern pat cval with
+                        | Nothing ->
+                            SEU.runE (Exception.fail (Illformed_program "Elet: the pattern didn't match pe1"))
+                        | Just _ ->
+                            E.return <| th_st with
+                              arena= e2;
+                              env= update_env pat cval th_st.env
+                            |>
+                      end
                 end
@@ -1447,6 +1459,12 @@ BEFORE EVAL_PEXPR2
                   | Right cval1 ->
-                      E.return <| th_st with
-                        arena= e2;
-                        env= update_env pat cval1 th_st.env
-                      |>
+                      (* FORK 2026-09-22 (audit R2): as Elet — the pattern must fit *)
+                      match match_pattern pat cval1 with
+                        | Nothing ->
+                            SEU.runE (Exception.fail (Illformed_program "Ewseq: the pattern didn't match e1"))
+                        | Just _ ->
+                            E.return <| th_st with
+                              arena= e2;
+                              env= update_env pat cval1 th_st.env
+                            |>
+                      end
                 end
@@ -1491,6 +1509,12 @@ BEFORE EVAL_PEXPR2
                   | Right cval1 ->
-                      E.return <| th_st with
-                        arena= e2;
-                        env= update_env pat cval1 th_st.env
-                      |>
+                      (* FORK 2026-09-22 (audit R2): as Elet — the pattern must fit *)
+                      match match_pattern pat cval1 with
+                        | Nothing ->
+                            SEU.runE (Exception.fail (Illformed_program "Esseq: the pattern didn't match e1"))
+                        | Just _ ->
+                            E.return <| th_st with
+                              arena= e2;
+                              env= update_env pat cval1 th_st.env
+                            |>
+                      end
                 end
--- a/frontend/model/core_typing.lem
+++ b/frontend/model/core_typing.lem
@@ -884,2 +884,9 @@ and typecheck_pexpr tagDefs (env: typing_env) (bTy: core_base_type) (Pexpr annot
           | (Ctuple, BTy_tuple bTys, _) ->
+              (* FORK 2026-09-22 (upstream-tray draft 45; audit R1): fail CLOSED on a
+                 tuple-arity mismatch. List.zip TRUNCATES, so a tuple EXPRESSION of the
+                 wrong arity was accepted and REBUILT with the surplus operands DELETED
+                 (an `error(...)` among them vanished from the typed program). *)
+              if List.length bTys <> List.length pes then
+                E.fail loc (MismatchExpected "Ctuple" bTy "tuple of a different arity")
+              else
               E.mapM (fun (bTy, pe) -> typecheck_pexpr tagDefs env bTy pe)
@@ -1791,2 +1798,7 @@ and typecheck_expr callconv tagDefs (env: typing_env) expected_bTy (Expr annot e
           | BTy_tuple bTys ->
+              (* FORK 2026-09-22 (upstream-tray draft 45; audit R1): arity guard —
+                 List.zip truncated and DELETED the surplus operands *)
+              if List.length bTys <> List.length es then
+                E.fail loc (MismatchExpected "Eunseq" expected_bTy "unseq of a different arity")
+              else
               Eunseq <$> E.mapM (fun (bTy, e) -> typecheck_expr env bTy e)
@@ -1852,2 +1864,7 @@ and typecheck_expr callconv tagDefs (env: typing_env) expected_bTy (Expr annot e
           | BTy_tuple bTys ->
+              (* FORK 2026-09-22 (upstream-tray draft 45; audit R1): the same
+                 arity guard as Eunseq (same truncating shape) *)
+              if List.length bTys <> List.length es then
+                E.fail loc (MismatchExpected "Epar" expected_bTy "par of a different arity")
+              else
               Epar <$> E.mapM (uncurry $ typecheck_expr env) (List.zip bTys es)
```

Design notes [AGENT worker, under the rulings]:
- **R1** uses the EXISTING `MismatchExpected` constructor at all three sites (the ruling: the existing
  `MismatchExpected`, or the site's existing error TYPE — never a new one); found-texts `"tuple of a different
  arity"` / `"unseq of a different arity"` / `"par of a different arity"`. Both length directions; nested tuples
  are covered by the recursion (each nested `PEctor Ctuple` meets the same guard); a fitting input is rebuilt
  from a zip of equal lengths, i.e. operand-for-operand — pinned byte-identically (§12.4).
- **R2, the helpers:** ONE shared loud leaf, `Core_aux.tuple_arity_error who n_pats n_vals` (`Utils.error` →
  OCaml `Cerb_debug.error`, Lean `LemLib.failwithI`; message `Core_aux.<who>: tuple pattern of arity N bound to a
  tuple of arity M (upstream-tray draft 45)`), used by `subst_pattern_val` (1 arm), `unsafe_subst_pattern` (2),
  `subst_pattern` (2), `update_env_aux` (1) — one register row instead of six identical ones. What the OCaml did on
  these paths before: it silently bound the prefix, exactly like Lean (same lem) — so the guard changes OCaml
  behaviour on MALFORMED Core input only, the class of the matcher guard (tray 45).
- **R2, `Core_run`:** the `Elet`, `Ewseq` and `Esseq` arms (the driver's stepping engine) check `match_pattern pat
  cval` BEFORE `update_env` and report `Illformed_program "<form>: the pattern didn't match …"` through
  `SEU.runE (Exception.fail …)` — the SAME outcome class as the `PElet` route (`core_eval.lem:1007-1018`,
  `Illformed_program "PElet: the pattern didn't match pe1"`), so default = `--rewrite` on `let-mismatch.core`'s
  shape (§12.4/§12.5). The check is on the whole pattern shape (as `select_case`'s is), not the tuple arity alone,
  so a non-fitting `Cspecified`/`Ccons` pattern in a let-form now also reports `Illformed_program` in `Core_run`
  instead of reaching `update_env_aux`'s catch-all leaf — fail-closed either way, malformed Core only.
  **`Core_reduction` IS the driver's engine — a finding of this round, and a fence extension [AGENT worker,
  flagged]:** the first post-fix oracle run of the audit's `let-mismatch.core` (default mode) died in the NEW loud
  leaf with the backtrace `Core_aux.update_env ← Core_reduction.one_step (core_reduction.ml:410) ←
  Driver.liftCore_run` — the driver steps with `Core_reduction` (`driver.lem` `drive_core_thread2 →
  Core_reduction.core_step2 → step_ctx → one_step`), NOT with `Core_run.core_thread_step2` (the second engine,
  the one the audit's `core_run.lem:872-879` cite names). With only `core_run.lem` guarded, default gave the
  loud leaf and `--rewrite` `Illformed_program` — still a disagreement, i.e. the ruling's outcome ("default =
  rewrite must vanish") was NOT met by the named site. So `core_reduction.lem`'s six let-form sites (`one_step`:
  `Elet` value/evaluate, `Ewseq`, `Ewseq Eannot`, `Esseq`, `Esseq Eannot`) check `match_pattern` too and route a
  non-fitting pattern through `TAU_WITH_RUNSTATE … (SEU.runEU (EU.fail (Errors.Illformed_program "<form>: the
  pattern didn't match …")))` — the SAME monadic channel the `PElet` route's `EVAL` step uses (its `ILLTYPED`
  constructor was NOT used: it becomes `Step_error2` → a driver `error`, a loud leaf). One header line `import
  Errors` was added to `core_reduction.lem`. `core_reduction.lem` was outside the ruling's listed fence; it is
  in the commit because the ruling's stated outcome requires it — a deviation, reported. `update_env_aux`'s
  leaf remains the backstop for any other caller (e.g. `core_reduction.lem:438`/`:1437`'s `mk_sym_pat`
  bindings, always fitting).
- `select_case` untouched (the consumer's `none`/fall-through).
- **A residual the two policies leave (recorded, not decided here):** on the `Ewseq`/`Esseq` shapes
  (`unseq-weak-mismatch.core`, `unseq-strong-mismatch.core`) the default path now reports `Illformed_program`
  (the let-form fit check) while `--rewrite` reaches `subst_pattern`'s LOUD leaf (`pure_propagation2 → subst_pattern`
  on the mismatched tuple — the ruling's outcome for the helpers). Both fail closed; the outcome KINDS differ. The
  ruling's pin (default = `--rewrite` on `let-mismatch.core`'s shape, the `Elet`) holds: both `Illformed_program`.
  If ONE kind is wanted for the `unseq` shapes too, the `maybe`-typed `subst_pattern` could return `Nothing` on a
  mismatch (deferring to the runtime's `Illformed_program`) — an orchestrator decision; the loud leaf stands as ruled.
- **Tier A rows 1–12 incl. 4b/4c/6b** are lanes A1–A12.2 of the frozen battery (§12.10); row 1's exe suite was
  also run alone after the register re-seal (§12.7).

### 12.4 Runtime witnesses and kernel facts (`test/Unit/MatchPatternArityTest.lean`, closure section)

Kernel (`rfl`; the leaf is `failwithI`, opaque, so `x = tuple_arity_error … n m` states that the result IS the leaf —
never evaluated at runtime): `R2_subst_pattern_val_23/_32`, `R2_unsafe_subst_pattern_val_23`, `R2_unsafe_subst_pattern_pe_23`,
`R2_subst_pattern_val_tuple_23`, `R2_subst_pattern_pe_23`, `R2_update_env_aux_23/_32`; fitting inputs unchanged
(`R2_*_fit`); `R2_matcher_23`. Runtime (the actual generated `partial` typing definitions, and the two evaluation
routes under an argv-supplied ambient fuel — `scripts/test_unit.sh` passes `17`, the `monadic-failstop-test`
idiom; no fuel numeral in the file): R1 on `typecheck_pexpr`/`Eunseq`/`Epar`, both directions + nested, fitting
inputs preserved byte-identically (erase the annotation, `==`); R2 `Core_run.core_thread_step2`'s `Elet` step
payload run on a default run state vs `Core_eval.step_eval_pexpr`'s `PElet` — both `Illformed_program`; fitting
both `Defined`; and on THE driver's engine, `Core_reduction.one_step` (`one_step0` in Lean) with stub evaluators
(never called on a `PEval` operand): `Elet`/`Ewseq`/`Esseq` mismatch → `TAU_WITH_RUNSTATE` whose computation is
`Illformed_program`, fitting `Elet` → `TAU`. Output, verbatim:

    === match-pattern-arity-test ===
    Note: This linter can be disabled with `set_option linter.unusedSimpArgs false`
    Build completed successfully (223 jobs).
    match-pattern-arity-test: match_pattern / typecheck_pattern fail closed on tuple-arity mismatch (cerberus-sl item 7); T1–T4 kernel-checked at compile time; closure round R1/R2 witnesses at fuel 17
    PASS T1a match_pattern tup2 v3: got none; pre-fix: some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)] (the truncating prefix — the defect)
    PASS T1b match_pattern tup3 v2: got none; pre-fix: some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)] (the truncating prefix — the defect)
    PASS T2 select_case v3 [(tup2, pair arm), (wild, wildcard arm)]: got some "wildcard arm"; pre-fix: some "pair arm" (the pair arm selected on a triple)
    PASS T3 match_pattern tup2 v2: got some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)]; pre-fix: some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)] (unchanged)
    PASS T3_select select_case cons v2 [(tup2, []), (wild, [(s3, Vunit)])]: got some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)]; pre-fix: some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)] (unchanged)
    PASS T5a typecheck_pattern (BTy_tuple [unit, boolean, boolean]) tup2: got Exception (CORE_TYPING (MismatchExpected "Ctuple" (BTy_tuple <3 components>) "tuple pattern of a different arity")); pre-fix: Result (typed Ctuple pattern with 2 sub-patterns) (ACCEPTED — the defect)
    PASS T5b typecheck_pattern (BTy_tuple [unit, boolean]) tup3: got Exception (CORE_TYPING (MismatchExpected "Ctuple" (BTy_tuple <2 components>) "tuple pattern of a different arity")); pre-fix: Result (typed Ctuple pattern with 2 sub-patterns) (ACCEPTED, third sub-pattern DROPPED — the defect)
    PASS T5c typecheck_pattern (BTy_tuple [unit, boolean]) tup2 (positive control): got Result (typed Ctuple pattern with 2 sub-patterns); pre-fix: Result (typed Ctuple pattern with 2 sub-patterns) (unchanged)
    PASS R1 typecheck_pexpr (unit, boolean) (unit, true, false): got Exception (MismatchExpected "Ctuple" _ "tuple of a different arity"); pre-fix: Result (PEctor Ctuple with 2 operands) — the third DELETED
    PASS R1 typecheck_pexpr (unit, boolean, boolean) (unit, true): got Exception (MismatchExpected "Ctuple" _ "tuple of a different arity"); pre-fix: Result (PEctor Ctuple with 2 operands) — the third TYPE dropped
    PASS R1 typecheck_pexpr nested (unit, (boolean, boolean)) (unit, (true, false, false)): got Exception (MismatchExpected "Ctuple" _ "tuple of a different arity"); pre-fix: Result (PEctor Ctuple with 2 operands) — the inner surplus DELETED
    PASS R1 typecheck_pexpr fitting (unit, boolean, boolean): operands preserved byte-identical: got Result (PEctor Ctuple with 3 operands); pre-fix: Result (PEctor Ctuple with 3 operands) (unchanged)
    PASS R1 typecheck_pexpr fitting nested: operands preserved byte-identical: got Result (PEctor Ctuple with 2 operands); pre-fix: Result (unchanged)
    PASS R1 typecheck_expr (unit, boolean) unseq(unit, true, false): got Exception (MismatchExpected "Eunseq" _ "unseq of a different arity"); pre-fix: Result (Eunseq with 2 operands) — the third DELETED
    PASS R1 typecheck_expr (unit, boolean, boolean) unseq(unit, true): got Exception (MismatchExpected "Eunseq" _ "unseq of a different arity"); pre-fix: Result (Eunseq with 2 operands)
    PASS R1 typecheck_expr fitting unseq(unit, true, false): operands preserved byte-identical: got Result (Eunseq with 3 operands); pre-fix: Result (Eunseq with 3 operands) (unchanged)
    PASS R1 typecheck_expr (unit, boolean) par(unit, true, false): got Exception (MismatchExpected "Epar" _ "par of a different arity"); pre-fix: Result (Epar with 2 operands) — the third DELETED
    PASS R1 typecheck_expr (unit, boolean, boolean) par(unit, true): got Exception (MismatchExpected "Epar" _ "par of a different arity"); pre-fix: Result (Epar with 2 operands)
    PASS R1 typecheck_expr fitting par(unit, true, false): operands preserved byte-identical: got Result (Epar with 3 operands); pre-fix: Result (Epar with 3 operands) (unchanged)
    PASS R2 Core_run Elet (k0, k1) = (unit, unit, unit): Illformed_program: got MatchPatternArityTest.RouteOutcome.illformed "Elet: the pattern didn't match pe1"; pre-fix: the prefix bound, e2 stepped (oracle: Specified(3) on let-mismatch.core)
    PASS R2 Core_eval PElet (k0, k1) = (unit, unit, unit): Illformed_program: got MatchPatternArityTest.RouteOutcome.illformed "PElet: the pattern didn't match pe1"; pre-fix: Illformed_program "PElet: the pattern didn't match pe1" (already, via select_case)
    PASS R2 default = rewrite: both routes Illformed_program: got Elet MatchPatternArityTest.RouteOutcome.illformed "Elet: the pattern didn't match pe1" / PElet MatchPatternArityTest.RouteOutcome.illformed "PElet: the pattern didn't match pe1"; pre-fix: DISAGREED: Elet bound the prefix, PElet failed
    PASS R2 fitting (k0, k1) = (unit, unit): both routes Defined: got Elet MatchPatternArityTest.RouteOutcome.defined / PElet MatchPatternArityTest.RouteOutcome.defined; pre-fix: both Defined (unchanged)
    PASS R2 Core_reduction one_step Elet (k0, k1) = (unit, unit, unit): Illformed_program (the driver's engine): got MatchPatternArityTest.RouteOutcome.illformed "Elet: the pattern didn't match pe1"; pre-fix: TAU Elet with the prefix bound (oracle default: Specified(3) on let-mismatch.core)
    PASS R2 Core_reduction one_step Ewseq (k0, k1) = pure (unit, unit, unit): Illformed_program: got MatchPatternArityTest.RouteOutcome.illformed "Ewseq: the pattern didn't match e1"; pre-fix: TAU Ewseq with the prefix bound (oracle default: Specified(3) on unseq-weak-mismatch.core)
    PASS R2 Core_reduction one_step Esseq (k0, k1) = pure (unit, unit, unit): Illformed_program: got MatchPatternArityTest.RouteOutcome.illformed "Esseq: the pattern didn't match e1"; pre-fix: TAU Esseq with the prefix bound (oracle default: Specified(3) on unseq-strong-mismatch.core)
    PASS R2 Core_reduction one_step fitting Elet (k0, k1) = (unit, unit): TAU (unchanged): got MatchPatternArityTest.RouteOutcome.defined; pre-fix: TAU Elet (unchanged)
    match-pattern-arity-test: OK (8/8 item-7 witnesses + 19/19 closure-round witnesses; kernel theorems T1a T1b T1_wrapper T1_anyFuel T2 T3 T3_select T4_neg and the R2_* leaf equations compiled; #print axioms pinned by #guard_msgs: [propext] on T1a/T1b/T2/T3/T3_select/T4_neg, the trio on T1_anyFuel)
    ✓ match-pattern-arity-test PASSED
    ==========================================
    Total: 1 passed, 0 failed

### 12.5 The engines after the closure round (the same probes; verbatim)

    === POST-FIX fork pure-let-mismatch.core ===
    --- default:
    Error {msg: "ill-formed program: `PElet: the pattern didn't match pe1'"}
    --- --typecheck-core:
    .tmp/mpa/core-probes/pure-let-mismatch.core:2:51: error: this expression is of type 'tuple of a different arity' but an expression of type '(integer,integer)' was expected
      pure (Specified (let (a: integer, b: integer) = (1, 2, 3) in a + b))
                                                      ^~~~~~~~~ 
    --- --rewrite:
    Error {msg: "ill-formed program: `PElet: the pattern didn't match pe1'"}
    === POST-FIX fork let-mismatch.core ===
    --- default:
    Error {msg: "ill-formed program: `Elet: the pattern didn't match pe1'"}
    --- --typecheck-core:
    .tmp/mpa/core-probes/let-mismatch.core:2:34: error: this expression is of type 'tuple of a different arity' but an expression of type '(integer,integer)' was expected
      let (a: integer, b: integer) = (1, 2, 3) in
                                     ^~~~~~~~~ 
    --- --rewrite:
    Error {msg: "ill-formed program: `PElet: the pattern didn't match pe1'"}
    === POST-FIX fork let-nested-mismatch.core ===
    --- default:
    Error {msg: "ill-formed program: `Elet: the pattern didn't match pe1'"}
    --- --typecheck-core:
    .tmp/mpa/core-probes/let-nested-mismatch.core:2:49: error: this expression is of type 'tuple of a different arity' but an expression of type '(integer,integer)' was expected
      let ((a: integer, b: integer), c: integer) = ((1, 2, 3), 4) in
                                                    ^~~~~~~~~ 
    --- --rewrite:
    Error {msg: "ill-formed program: `PElet: the pattern didn't match pe1'"}
    === POST-FIX fork unseq-weak-mismatch.core ===
    --- default:
    Error {msg: "ill-formed program: `Ewseq: the pattern didn't match e1'"}
    --- --typecheck-core:
    .tmp/mpa/core-probes/unseq-weak-mismatch.core:2:39: error: this expression is of type 'unseq of a different arity' but an expression of type '(integer,integer)' was expected
      let weak (a: integer, b: integer) = unseq(pure (1), pure (2), pure (3)) in
                                          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
    --- --rewrite:
    internal error: Core_aux.subst_pattern: tuple pattern of arity 2 bound to a tuple of arity 3 (upstream-tray draft 45)
    cerberus: internal error, uncaught exception:
              Failure("internal error: Core_aux.subst_pattern: tuple pattern of arity 2 bound to a tuple of arity 3 (upstream-tray draft 45)")
              Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
              Called from Cerb_frontend__Core_rewrite.pure_propagation2 in file "ocaml_frontend/generated/core_rewrite.ml", line 1190, characters 21-45
              Called from Cerb_frontend__Core_rewrite.rewrite_fun_map.(fun) in file "ocaml_frontend/generated/core_rewrite.ml", line 1448, characters 38-54
              Called from Pmap.map in file "pmap.ml", line 139, characters 15-18
              Called from Pmap.map in file "pmap.ml", line 318, characters 26-35
              Called from Cerb_frontend__Core_rewrite.rewrite_file in file "ocaml_frontend/generated/core_rewrite.ml", lines 1465-1467, characters 24-71
              Called from Cerb_backend__Pipeline.core_rewrite in file "backend/common/pipeline.ml", line 322, characters 9-49
              Called from Cerb_backend__Pipeline.core_passes in file "backend/common/pipeline.ml", line 594, characters 6-39
              Called from Dune__exe__Main.cerberus.main.(fun) in file "backend/driver/main.ml", line 158, characters 6-47
              Called from Cerb_frontend__Exception.except_foldlM.(fun) in file "ocaml_frontend/generated/exception.ml", line 69, characters 18-25
              Called from Dune__exe__Main.cerberus.(fun) in file "backend/driver/main.ml", line 318, characters 8-24
              Called from Dune__exe__Main.cerberus in file "backend/driver/main.ml", lines 313-339, characters 8-15
              Called from Cmdliner_term.app.(fun) in file "cmdliner_term.ml", line 22, characters 19-24
              Called from Cmdliner_eval.run_parser in file "cmdliner_eval.ml", line 41, characters 7-16
    === POST-FIX fork unseq-strong-mismatch.core ===
    --- default:
    Error {msg: "ill-formed program: `Esseq: the pattern didn't match e1'"}
    --- --typecheck-core:
    .tmp/mpa/core-probes/unseq-strong-mismatch.core:2:41: error: this expression is of type 'unseq of a different arity' but an expression of type '(integer,integer)' was expected
      let strong (a: integer, b: integer) = unseq(pure (1), pure (2), pure (3)) in
                                            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
    --- --rewrite:
    internal error: Core_aux.subst_pattern: tuple pattern of arity 2 bound to a tuple of arity 3 (upstream-tray draft 45)
    cerberus: internal error, uncaught exception:
              Failure("internal error: Core_aux.subst_pattern: tuple pattern of arity 2 bound to a tuple of arity 3 (upstream-tray draft 45)")
              Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
              Called from Cerb_frontend__Core_rewrite.pure_propagation2 in file "ocaml_frontend/generated/core_rewrite.ml", line 1222, characters 21-45
              Called from Cerb_frontend__Core_rewrite.rewrite_fun_map.(fun) in file "ocaml_frontend/generated/core_rewrite.ml", line 1448, characters 38-54
              Called from Pmap.map in file "pmap.ml", line 139, characters 15-18
              Called from Pmap.map in file "pmap.ml", line 318, characters 26-35
              Called from Cerb_frontend__Core_rewrite.rewrite_file in file "ocaml_frontend/generated/core_rewrite.ml", lines 1465-1467, characters 24-71
              Called from Cerb_backend__Pipeline.core_rewrite in file "backend/common/pipeline.ml", line 322, characters 9-49
              Called from Cerb_backend__Pipeline.core_passes in file "backend/common/pipeline.ml", line 594, characters 6-39
              Called from Dune__exe__Main.cerberus.main.(fun) in file "backend/driver/main.ml", line 158, characters 6-47
              Called from Cerb_frontend__Exception.except_foldlM.(fun) in file "ocaml_frontend/generated/exception.ml", line 69, characters 18-25
              Called from Dune__exe__Main.cerberus.(fun) in file "backend/driver/main.ml", line 318, characters 8-24
              Called from Dune__exe__Main.cerberus in file "backend/driver/main.ml", lines 313-339, characters 8-15
              Called from Cmdliner_term.app.(fun) in file "cmdliner_term.ml", line 22, characters 19-24
              Called from Cmdliner_eval.run_parser in file "cmdliner_eval.ml", line 41, characters 7-16
    === POST-FIX fork pure-let-discarded-error.core ===
    --- default:
    Error {msg: "surplus"}
    --- --typecheck-core:
    .tmp/mpa/core-probes/pure-let-discarded-error.core:2:51: error: this expression is of type 'tuple of a different arity' but an expression of type '(integer,integer)' was expected
      pure (Specified (let (a: integer, b: integer) = (1, 2, error(<<<surplus>>>, 3)) in a + b))
                                                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
    --- --rewrite:
    Error {msg: "surplus"}
    === POST-FIX fork unseq-discarded-error.core ===
    --- default:
    Error {msg: "surplus"}
    --- --typecheck-core:
    .tmp/mpa/core-probes/unseq-discarded-error.core:2:39: error: this expression is of type 'unseq of a different arity' but an expression of type '(integer,integer)' was expected
      let weak (a: integer, b: integer) = unseq(pure (1), pure (2), pure (error(<<<surplus>>>, 3))) in
                                          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
    --- --rewrite:
    Error {msg: "surplus"}
    === POST-FIX fork tray45.core ===
    --- default:
    Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
    --- --typecheck-core:
    .tmp/mpa/core-probes/tray45.core:3:7: error: this expression is of type 'tuple pattern of a different arity' but an expression of type '(integer,integer,integer)' was expected
        | (a: integer, b: integer) => pure (Specified (a + b))
          ^~~~~~~~~~~~~~~~~~~~~~~~ 
    --- --rewrite:
    Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
    === POST-FIX fork fitting.core ===
    --- default:
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
    --- --typecheck-core:
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
    --- --rewrite:
    Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}

### 12.6 The register row, the manifest rows, the measure proofs

The new leaf `Core_aux.tuple_arity_error` is ONE pure failure site in the exec dependency closure: the gate went RED on it (`.tmp/mpa/failure-reach-before.log`), the register was re-emitted from the live census seeded with the reviewed file (`check_failure_reach.py --emit --seed`), the one UNREVIEWED row reviewed — class REACHABLE (Core-text input: `to_pure`/`pure_propagation2 → subst_pattern`, `Core_reduction`'s let-forms → `update_env_aux`; the Core typechecker is OFF by default, `--typecheck-core`) — and re-sealed. The row (`git diff scripts/failure_reach_register.txt`, verbatim):

    -# tally: sites=234 exec=232 unresolved-owner=2 reviewed-TAIL=181 reviewed-NON-TAIL=53 UNREACHABLE-BY-INVARIANT=167 REACHABLE=48 UNKNOWN=19 discardable=0
    +# tally: sites=235 exec=233 unresolved-owner=2 reviewed-TAIL=182 reviewed-NON-TAIL=53 UNREACHABLE-BY-INVARIANT=167 REACHABLE=49 UNKNOWN=19 discardable=0
    +lean_frontend/generated/Core_aux.lean	tuple_arity_error	failwithI	( String.append "Core_aux." (String.append who (String.appen	EXEC	TAIL	TAIL	REACHABLE	Core-text input (malformed Core: a tuple pattern bound to a tuple of another arity; the Core typechecker is OFF by default, --typecheck-core rejects it): core_rewrite pure_propagation2 -> subst_pattern under --rewrite (witness: the audit's unseq-weak-mismatch.core / unseq-strong-mismatch.core, record §12.5 — the fork oracle dies in this leaf), to_pure -> subst_pattern, and update_env_aux from any caller that skips match_pattern (Core_run's and Core_reduction's let-forms check it first and report Illformed_program). Unreachable on elaborator output (the elaborator builds tuple patterns from the types it just produced).	core_aux.lem tuple_arity_error (the ONE leaf of subst_pattern_val / unsafe_subst_pattern x2 / subst_pattern x2 / update_env_aux); upstream-tray draft 45; lean_frontend/docs/2026-09-20_match-pattern-arity-record.md §12	match-pattern-arity closure round 2026-09-22 (pre-merge audit R2): the arity guard's loud leaf — OCaml Cerb_debug.error, Lean failwithI	89fde1fa3e68da7f

The gate after the re-seal, verbatim:

    check_failure_reach: OK (235 pure failure sites = the 235 register rows exactly (233 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=167 REACHABLE=49 UNKNOWN=19; every row sealed; tally line consistent)

Manifest (`scripts/fork_drift_manifest.txt`; six single rows moved + one dated NOTE; the gate re-run before any
build — it needs only the sources and the two generated trees): layer 1 `core_aux.lem 28b4d085… → 314c447f…`,
`core_typing.lem 35c09007… → b2c028a9…`, `core_run.lem 1427069b… → 73ba87a3…`, `core_reduction.lem 7f61895f… →
cf062e7a…`; layer 2 (all four already `[expected-semantic]`) `core_aux.ml c2e521a9… → e20dc5a1…`, `core_typing.ml
b8f9c4bd… → fee46402…`, `core_run.ml 7d4e9c99… → ab8326bb…`, `core_reduction.ml 22b0b094… → 1c95fd93…`. Verbatim: `check_fork_drift: OK — layer 1: 77 oracle-surface files = manifest (set,
C-locale canonical, no duplicates); layer 2: 26 differing generated files, all hash-pinned (merge-base
b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)`.

Measure proofs (`Core_aux_lemMeasureProofs.lean`): `subst_pattern_val`, `unsafe_subst_pattern`, `subst_pattern`,
`update_env_aux` — the D4 shape, one inserted line each (`all_goals (split <;> try rfl)`: the guard is a
non-recursive `if`; the leaf branch is the same term on both sides), statements unchanged.

### 12.7 Gates and the frozen battery

**Box discipline (S5) this round.** At the round's start a `release.py --mode full` ran in `worktrees/cerberus-lean-arc/run-digest`
(01:44→) and a second one in another worktree (02:00→), plus foreign `lake` builds; light work only (reads, probes on
the pre-fix binaries, the lem/proof/test/doc edits, the two regenerations, the manifest rows, the fork-drift gate).
Waited, polling: `waited 561 s; heavy now: 3` then `waited 450 s; heavy now: 0` — 1011 s DERIVED — before the first
build chain (02:30). The second chain (after the `Core_reduction` fix) ran with only a python step driver alive.

Tier A row 1's own gates after the unit run (`.tmp/mpa/unit-closure.log`), verbatim:

    check_exec_purity: CLEAN (11 modules)
    check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
    check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 12 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
    check_theorem_axioms: C2 ratchet OK (399 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 25 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
    check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 49 hand-written seam files + LemLibTest.lean)
    check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free + DAEMON-free (arc-8 S3 bar)
    check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
    check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
    check_theorem_axioms: FUEL arc leg OK (63 contract lemmas — generated _zero, runner leaves/parametricity, ∀-fuel exemplar, measured obligations, fail-stop propagation, and six-worker ND stability, every cone ⊆ [propext, Classical.choice, Quot.sound])
    check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
    check_no_fuel_numerals: OK (326 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
    check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
    check_fuel_forms: forms partition OK (62 MEASURED + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
    check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 12 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
    check_failure_reach: OK (235 pure failure sites = the 235 register rows exactly (233 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=167 REACHABLE=49 UNKNOWN=19; every row sealed; tally line consistent)
    check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
    check_lem_sync: OK (src 5c7e2528597e48042f44891887b3592730a8cf53ddbec6109f86bb9cd1f3c94f, gen a5a6e7f68da99305428210afa7dcf0d7681d6324e8d32db0da3d4228b9f973b3)
    check_lem_sync: lean OK (src 5c7e2528597e48042f44891887b3592730a8cf53ddbec6109f86bb9cd1f3c94f, gen fe93a729c8b8b3e63b482c861c514db7d51363f9f44a5643627fdbd4d00a1701)
    check_fork_drift: OK — layer 1: 77 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 26 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)
    check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)

The FROZEN full battery (`scripts/ce python3 scripts/release.py --mode full --out .tmp/mpa/closure-full`): this record was completed BEFORE its launch; nothing was touched during it; its `report.json` and `summary.txt` are committed under `docs/2026-09-22_match-pattern-arity-closure-evidence/`, and its verbatim lane lines + certification lines are appended in §12.10 after the run, from those files. Expected: 39/39, `Source unchanged: True`, pristine 822/28/7/2 on this base (E-A not on mainline), zero movement (S2).

### 12.8 N1 and the text corrections

Tray 45 `:190` "axiom-free" → `[propext]` / the trio (done, §D5 text); this file's "14 exes" → 13 (§5); the exe's
final message no longer says `[propext]` "on each" — it names `T1_anyFuel`'s trio; §7's post-match premise struck
and corrected; §2's typing claim scoped; the charter carries an Errata section (the false premise, the incomplete
"fixes BOTH", the false "files are disjoint", the "14").

### 12.9 Integration note (from the audit; not done here)

`fix/match-pattern-arity` overlaps `arc/program-data-parameters` in `lakefile.toml`, `scripts/test_unit.sh`,
`scripts/fork_drift_manifest.txt` (conflicts) and `core_typing.lem`, `Core_aux_lemMeasureProofs.lean` (textual):
rebase onto the mainline after the enum arc lands, keep both unit registrations, recompute the typing module's
content/delta pins from the combined source.

### 12.10 The frozen full battery — verbatim (from the committed evidence dir)

launch Tue Sep 22 04:21:05 AM UTC 2026; release.py exit=0 end Tue Sep 22 05:45:22 AM UTC 2026

    PASSED A1 (308.4s)
    PASSED A2 (28.7s)
    PASSED A3 (53.5s)
    PASSED A4 (23.0s)
    PASSED A4b (24.3s)
    PASSED A4c (3.2s)
    PASSED A5 (22.5s)
    PASSED A6 (2.2s)
    PASSED A6b (3.6s)
    PASSED A7 (10.5s)
    PASSED A8 (9.1s)
    PASSED A9 (17.5s)
    PASSED A10 (18.0s)
    PASSED A11 (61.6s)
    PASSED A12.1 (5.2s)
    PASSED A12.2 (4.8s)
    PASSED B1 (638.2s)
    PASSED B2 (23.7s)
    PASSED B3 (15.6s)
    PASSED B4 (47.4s)
    PASSED B5 (70.4s)
    PASSED B6.1 (3.9s)
    PASSED B6.2 (2.4s)
    PASSED B6.3 (10.0s)
    PASSED B6.4 (9.7s)
    PASSED B6.5 (9.8s)
    PASSED B6.6 (10.8s)
    PASSED B6.7 (8.7s)
    PASSED B7 (1406.1s)
    PASSED B8.1 (13.4s)
    PASSED B8.2 (237.5s)
    PASSED B8.3 (6.5s)
    PASSED B8.4 (16.5s)
    PASSED B9 (1361.9s)
    PASSED B10.1 (118.7s)
    PASSED B10.2 (1.8s)
    PASSED B11.1 (15.9s)
    PASSED B11.2 (7.1s)
    PASSED B12 (422.9s)

    Independent oracle scope: tier-b; 859 rows in 118.5s; source unchanged: True
    Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/match-pattern-arity/.tmp/mpa/closure-full/B10.1/independent-oracle/report.json
    Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/match-pattern-arity/.tmp/mpa/closure-full/B10.2/independent-oracle/report.json
    Independent oracle scope: libxml2_chvalid; 4 rows in 422.7s; source unchanged: True
    Independent oracle: passed; {'semantic_agreement': 4}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/match-pattern-arity/.tmp/mpa/closure-full/B12/independent-oracle/report.json

    full: passed; 39/39 selected commands completed successfully.
    Source unchanged: True. Complete tier selection: True.
    Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
