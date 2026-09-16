# Pre-merge audit — `arc/parser-progress-measure` (`eaa2066e9..0b60f9780`)

**Range:** `eaa2066e9..0b60f9780` (10 commits: charter + pre-launch note, D0–D6, the orchestrator's review + §7 errata) · **head:** `0b60f97804ea524e1a5844641a61f9dbc886b3f3` · **worktree:** `worktrees/cerberus-lean-arc/parser-progress-measure` · **date:** 2026-09-16 · **auditor:** an independent Claude Fable 5.1 subagent in fresh context [AGENT auditor] — not the worker, not the orchestrator; adversarial verification by reproduction, read-only on the tree except this file. **Pre-change engines:** the primary checkout `/home/dev/projects/cerberus-lean-proj/cerberus-lean` at `eaa2066e9` (= the range's base; branch `mdd/cerberus-lean`, clean), read-only, binaries run only.

**What I ran** (every quoted output verbatim; derived tallies labelled; my judgments are [AGENT auditor]):

- `bash tools/check_driver_fresh.sh --check` in the worktree and in the primary — both engines fresh on both sides:
  ```
  check_driver_fresh: oracle OK (bin 4ab7f7a59a0b704a5af6b3634cdf14fb494e80c574787dfba857132f8ba5b404, src 98ad48b592a222a21e4619c5ce03652fc6a44c0a67c6b02cb222e1d40b1c701d)
  check_driver_fresh: lean OK (bin 5f6dfacf25852e7eedb386345ee641317eb03448688cd768974332962a2aa2ab, src c468cb46a12e1a438172ea9a51cd9c5f6e5f5f6dce0494bc61bfe76f706b690e)
  ```
  (worktree) and
  ```
  check_driver_fresh: oracle OK (bin 1b7cff622aaff92397f007c2d7d083bcfa5ea2952bd3c4af37a98d8430c5bc73, src 19de18ed9f03a529067ec7103f58917d116933da22bc317546408b2f7d66043e)
  check_driver_fresh: lean OK (bin e36af96d9eed60cfac55414d675d354edff4268b0bdfad6031c121137dc3be84, src a0ed1133a00bda9cc6ab4c84b2d534548f50f1ace248c61654fcd9ac253036bb)
  ```
  (primary).
- `scripts/ce ./scripts/test_unit.sh` once (a first attempt without the env fail-closed with `env not loaded: run via scripts/ce or source scripts/env.sh`, rc=2, and ran nothing) → `Total: 10 passed, 0 failed`, rc=0; gate lines in §"Verified clean".
- `./scripts/check_fuel_forms.sh --selftest` (twice; idempotent) → 24/24 `PLANT OK`, rc=0.
- `python3 scripts/gen_fuel_parametricity.py --check` → `gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)`.
- 28 printf programs of my own (§"printf table") on FOUR engines: old oracle (primary), new oracle (head), old Lean (primary), new Lean (head); oracles as the libc lane does (`opam exec --switch=<root> -- <root>/_build/default/backend/driver/main.exe --runtime=<root>/_build/install/default --exec --batch f.c`, libc loaded, no `--nolibc`); Lean as the libc lane does (`LEAN_ABORT_ON_PANIC=1 <root>/lean_frontend/.lake/build/bin/cerberus-lean --batch --first --libc <root>/tests/libc/libc.core --libc-tu <the 12 metadata JSONs from scripts/libc_prep.sh --jsons> f.json`, `f.json` = the head oracle's `--cabs-json`).
- Hand derivation of the old parsers' run functions; `diff -rq` of both generated trees against the primary's; sha256 of the `.lem` vs the manifest row; the whitespace-normalized comparison of the test's `_old` workers with the primary's generated text; the upstream line cites against `deps/cerberus-upstream` @ `b9aeedcb4`; `git diff eaa2066e9..HEAD` on every baseline/register/pinned file.

I did NOT run `release.py` or any Tier B lane (forbidden to me); the 36/36 battery claims of the record §D6 and of the orchestrator's review are therefore NOT independently reproduced here — what I reproduced is Tier A row 1 (the unit battery), the fuel-forms selftest, the parametricity pin, and the 28-program four-engine differential above.

## Findings

### F1 — P2 — `VALIDATION.md` §7 (A) row: the "62" cell's breakdown does not sum to 62 (stale sub-count in a cell this slice rewrote)

**Claim.** `lean_frontend/VALIDATION.md` §7, table row `(A) MEASURED | 62 (12 under a hypothesis) | … cone ⊆ the standard three (48 generated + 9 `CerbMem` seams by hand: …`. 48 + 9 = 57 ≠ 62. The parenthetical was already stale before this slice (it read `48 generated + 9` against `60`), but D5 rewrote this very cell (`60 (10 …)` → `62 (12 …)`, `git diff eaa2066e9..HEAD -- lean_frontend/VALIDATION.md`) and left the breakdown.

**Reproduction.** Count of `^theorem .*_measure_sufficient` per carrier in the head's generated tree and hand-written seams:
```
19 Core_aux_auxiliary.lean
5 Defacto_memory_aux_auxiliary.lean
4 Defacto_memory_auxiliary.lean
4 Core_run_aux_auxiliary.lean
4 Core_reduction_auxiliary.lean
3 Utils_auxiliary.lean
3 Ctype_aux_auxiliary.lean
3 AilTypesAux_auxiliary.lean
2 Monadic_parsing_auxiliary.lean
2 Core_eval_auxiliary.lean
1 Formatted_auxiliary.lean
1 Driver_auxiliary.lean
1 Ctype_auxiliary.lean
1 Core_auxiliary.lean
generated total: 53
hand-written CerbMem seams: 9
```
53 + 9 = 62 = the gate's `62 MEASURED` (derived tally [AGENT auditor]).

**Remedy.** `48 generated` → `53 generated` in that cell (one word). Optional: the register's own history shows why 48 drifted (hack/to_pure/to_pures +3, the ctype_aux trio +3 measured WITHOUT a hypothesis counted here, many_run/many1_run +2 — I did not trace the exact path; the current count is what matters).

### F2 — P3 — Charter §7 errata omit the D1 acceptance-(c) deviation

**Claim.** Charter §2 D1 acceptance (c): "`git diff --stat` shows exactly `frontend/model/monadic_parsing.lem`". The D1 commit `8371d4763` also carries `scripts/fork_drift_manifest.txt` (the D5.1 hunks brought forward, because `check_fork_drift` runs inside Tier A row 1 and D3 requires that row green — record §0 item 3 explains this and the manifest IS in the §3 fence, so no violation). The §7 errata list four charter-vs-tree corrections but not this one.

**Reproduction.** `git show --stat --format= --name-only 8371d4763` → `frontend/model/monadic_parsing.lem`, `lean_frontend/docs/…record.md`, `scripts/fork_drift_manifest.txt`, the evidence files.

**Remedy.** One errata bullet: "D1 acceptance (c): the manifest's two hunks were performed at D1/D2 (gate sequencing, record §0 item 3); D1's `--stat` is the `.lem` + the manifest."

### F3 — P3 — `ManyRestatementTest.lean` header says the old workers are kept "verbatim up to the namespace and the `_old` names"; whitespace was also normalized

**Claim.** `lean_frontend/test/Unit/ManyRestatementTest.lean:5-6`. The generated text has runs of double spaces (`def  many_lemFuel  {a : Type} (lemFuel : Nat)  (p : parserM a)  : …`); the test collapses them.

**Reproduction.** Both blocks with runs of blanks collapsed to one space and `_old_lemFuel` → `_lemFuel`: `diff` empty (rc=0). Semantically identical; the theorems are about the right definitions.

**Remedy.** Wording: "verbatim up to whitespace, the namespace and the `_old` names".

### F4 — P3 — Off-by-one line cites (the cites still land on the right definitions)

**Claim/reproduction.** `formatted.lem` head: `val digit` `:82`, `let digit =` `:83`, body `char #'0' <|> nonzero` `:84`, `:85` blank — cited as `digit formatted.lem:83-85` in `scripts/fuel_hypotheses.txt` (many_run row), `CerbParserProgress.lean:18`, charter §1. `many_run` spans `monadic_parsing.lem:119-123` (`end` at 123) — cited `:119-122` in the `many1_run` row. Every other cite I checked is exact (`:90`, `:97`, `:103`, `:170-171`, `nonzero :66-79`, `conversionSpecification :152-153`, `item :39-43`, `sat/char :65-74`, `many :131`, `many1 :132`; register-header `:119-132`; tray/INDEX upstream `:8/:12/:16-18/:25/:48-52/:93-99` @ `b9aeedcb4`).

**Remedy.** Optional tidy at landing (`:83-84`, `:119-123`); not load-bearing.

### F5 — P3 — `lean_frontend/CLAUDE.md` Key-files table lacks the two new modules (declared; owed at landing)

**Claim.** Charter §7 last bullet and record open question 3 declare the omission as a landing edit outside the fence. `grep -c Monadic_parsing lean_frontend/CLAUDE.md` = 0; no `CerbParserProgress` row. Not a finding against the range; listed so it is not forgotten: add `CerbParserProgress.lean` beside `CerbCoreShape.lean` (`:276`) and `Monadic_parsing_lemMeasureProofs.lean` to the `*_lemMeasureProofs` row (`:275`).

No P1. Specifically: no behavioural difference between the old and new parsers on any input I could construct or derive; no unsound proof step; no policy violation; no moved existing baseline row.

## Verified clean (what I checked and found correct)

**1. The restatement is the same parser.** From the ORIGINAL definitions I derived by hand, unfolding each `inline` exactly once: `parse (many1 p) cs = concatMap (fun (a,cs') -> concatMap (fun (as,cs'') -> [(a::as,cs'')]) (parse (many p) cs')) (parse p cs)` = `concatMap (fun (a,cs') -> map (fun (as,cs'') -> (a::as,cs'')) (parse (many p) cs')) (parse p cs)` (concatMap of singletons = map, for every finite list); `parse (many p) cs = match parse (many1 p) cs ++ [([],cs)] with [] -> [] | x::_ -> [x]`. These are exactly the bodies of `many1_run`/`many_run` (`monadic_parsing.lem:119-127`) with `parse (many p)`/`parse (many1 p)` in place of `many_run p`/`many1_run p`; the new `many p = ParserM (many_run p)` closes the loop. Cases considered: `p` with several results (concatMap ranges over all; `many_run` takes the head of the concatenation — same in both); `p` with none (`many1_run = []`, `many_run = [([], cs)]` — same); a non-consuming `p` that succeeds (`many cs → many1 cs → many cs` repeats: both loop in OCaml; in Lean the old worker exhausts the ambient counter, the new exhausts the measure `2|cs|+2` — both the loud sentinel, class (b)/fuel; no exec-path caller passes such a `p`, theorem `callSites_consume`); results whose rest is not a suffix (no suffix property is used anywhere). Evaluation order is the same (`parse p cs` first, then each result left-to-right) so the same non-termination/exception is reached first. Generated OCaml (`diff -u` primary→head): the diff is the comment + `let rec many_run p cs … and many1_run p cs …` + `let many p = ParserM (many_run p)` / `let many1 …`, in the module's existing idioms (`List.rev_append (List.rev …) …`, `List.concat (map …)`; inner `Lem_list.map` = `count_map`, a pure map); `diff -rq` of the whole generated OCaml tree: only `monadic_parsing.ml`. **Reproduced:** 28 programs, old vs new oracle 28/28 byte-identical stdout and exit code; old Lean vs new Lean 28/28 byte-identical (incl. the three PANIC texts); Lean vs oracle 25/28 exact line match + 3 both-fail pairs (§table).

**2. The measure and the proofs.** `Monadic_parsing_auxiliary.lean:38,43` (generated shell): `theorem many_run_measure_sufficient {a} (p) (cs) (lemHyp : (CerbParserProgress.Consumes p)) (lemFuel : Nat) (lemMeasureLe : (2 * List.length cs + 2) ≤ lemFuel) : many_run_lemFuel lemFuel p cs = many_run p cs := Monadic_parsing_lemMeasureProofs.many_run_measure_sufficient p cs lemHyp lemFuel lemMeasureLe` — `lemHyp` immediately before `lemFuel`, the wrapper on the statement's binders; the twin at `+ 1`. The gate's row verdicts (record D2, and my own run's `62 MEASURED … 12 of them under a hypothesis`) include `args=positional measure=syntactic axioms=ok`. Hop count re-derived: from `many1_run_lemFuel f p cs`, one hop to `many_run_lemFuel (f-1) p cs'` per result (`|cs'| ≤ |cs|-1`), one more to `many1_run_lemFuel (f-2) p cs'`; sufficient iff `f-2 ≥ 2|cs'|+1`, implied by `f ≥ 2|cs|+1`; base `|cs| = 0`: `parse p [] = []` under `Consumes` (no rest is shorter than `[]`), so `f ≥ 1 = 2·0+1` suffices — the bound is tight. `many_run` adds one frame on the same input: `2|cs|+2`. The proof (`Monadic_parsing_lemMeasureProofs.lean`): `many1_run_stable_aux` by induction on a bound `k ≥ |cs|` with both fuels generalized and the hypothesis threaded; `List.map_congr_left` for the traversal; inner `omega` side conditions all discharge from `f ≥ 2|cs|+1`, `|cs'| < |cs|`; `many_run_stable_aux` one unfolding; the two obligations are the stability lemmas at `(lemFuel, measure)`. Tactics: `induction/cases/intro/subst/simp only/congr/apply/obtain/dsimp only/rw/omega/simp` — kernel; no `decide` on any goal, no `native_decide`, no option bumps, no `sorry`. Cones: my `test_unit.sh` run — `check_theorem_axioms: FUEL arc leg OK (63 contract lemmas — generated _zero, runner leaves/parametricity, ∀-fuel exemplar, measured obligations, fail-stop propagation, and six-worker ND stability, every cone ⊆ [propext, Classical.choice, Quot.sound])`, `check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)`, `check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 48 hand-written seam files + LemLibTest.lean)` (the scanned tree is `lean_frontend/test`, so the equivalence test is in scope), `check_sorry_token: OK (314 files scanned comment-stripped — generated 218, hand-written+test 61, LemLib 35; 0 sorry tokens)`; my grep of the four changed Lean files for `native_decide|bv_decide|ofReduce*|decide|sorry|axiom|partial|opaque|implemented_by|unsafe|maxHeartbeats|maxRecDepth`: only `set_option autoImplicit` and comment hits. The record's D4 `#print axioms` lines (evidence `d4-gates-and-probes.txt:11-28`) are consistent with this.

**3. The hypothesis and its discharge.** `Consumes {a} (p : parserM a) : Prop := ∀ cs r, r ∈ parse p cs → r.2.length < cs.length` — every result's rest strictly shorter, which is exactly what the measure needs (no suffix assumption). `CerbParserProgress.lean` is Props + theorems only (`Consumes`, `NonExpanding` are `Prop`-valued `def`s; no `partial`/`opaque`/`implemented_by`/`unsafe`; no executable content); it is reached only through `Monadic_parsing_lemMeasureProofs` ← `Monadic_parsing_auxiliary`, outside the driver's cone (the record observed the Lean driver binary byte-identical across D2→D4; my freshness check shows the same `bin 5f6dfacf…`). The four call-site theorems name the lem-generated constants: `digit` (`:90/:97` via `nonnegativeDecimalInteger_passes_digit`/`decimalInteger_passes_digit`, both `⟨_, rfl⟩`), `flags0` (`flags` → `flags0`, `:103`, `flags0_passes_consuming`: the alternative captured by unification and proved consuming), `format0` (`format` → `format0`, `:170-171`, `format0_passes_consuming`: left arm `consumes_many1 _ (consumes_sat _)`, right arm `consumes_conversionSpecification` = `char '%'` consuming then `NonExpanding` sub-parsers), inner `:171` `consumes_notPercent`; the generated `Formatted.lean:310-391` heads are these constants. `grep -rnw many|many1` over `frontend/model/*.lem`: exactly `formatted.lem:90,97,103,170,171`; over hand-written Lean/speclab/test: no user. Register rows: `grep -v '^#' scripts/fuel_hypotheses.txt | awk -F'\t' '{print NF}'` → 4 for all 12 rows; both new rows carry `.lem:<line>` cites and a reviewer field ending `[USER] sign-off at merge`; the `hyp` text `CerbParserProgress.Consumes p` matches the gate's `12 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions`.

**4. The gate change.** `git diff eaa2066e9..HEAD -- scripts/check_fuel_forms.sh`: every hunk is at line ≥ 208, inside `if [[ "${1:-}" == "--selftest" ]]; then` (`:202`); `policy()` (`:108-200`) and every non-selftest line unchanged. Retargets: P2 now plants the row `many_run_lemFuel parser planted: measured 2026-09-15, row not removed` into a scratch copy of the pending register against the REAL table (a stale pin on a real MEASURED name; P5 stays the phantom-name twin); P6/P7 compile decoys `zeros_aux_measure_sufficient : True` (`import Core_aux`) and `list_unfoldr_aux_measure_sufficient … : list_unfoldr_aux acc ctor1 b0 = list_unfoldr_aux acc ctor1 b0 := rfl` (`import Utils`) — two AMBIENT workers unreachable from the drive cone with no real obligation to duplicate. My `--selftest` run (verbatim):
```
  PLANT OK   [P2 stale pending pin (many_run_lemFuel is MEASURED, not reachable-ambient)] -> check_fuel_forms: FAIL — pending register row(s) no longer a reachable ambient worker (stale pin; edit the register):
    plant table: FUEL_FORM	list_unfoldr_aux_lemFuel	AMBIENT	no/-	MALFORMED obligation=list_unfoldr_aux_measure_sufficient: left-hand head `list_unfoldr_aux` is not the worker `list_unfoldr_aux_lemFuel`	
    plant table: FUEL_FORM	zeros_aux_lemFuel	AMBIENT	no/-	MALFORMED obligation=zeros_aux_measure_sufficient: conclusion is not an equation	
  PLANT OK   [P6 decoy obligation of type True (zeros_aux)] -> check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (∀ …, μ ≤ lemFuel → worker lemFuel … = wrapper …, argument correspondence
  PLANT OK   [P7 decoy obligation with the wrong worker constant (list_unfoldr_aux)] -> check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (∀ …, μ ≤ lemFuel → worker lemFuel … = wrapper �
```
(the last two lines are cut at 260 chars by my extraction; the plant-table rows show each decoy rejected with its own message). Unplanted: `check_fuel_forms: forms partition OK (62 MEASURED + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)` and `check_fuel_forms: SELFTEST OK (24 plants with the declared label — 6 on the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: …)`, rc=0. `scripts/fuel_forms_pending.txt`: `grep -v '^#' | grep -c .` = 0 (header-only); the gate line `0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly`. Note (pre-existing design, not this slice): the `plant` helper asserts rc≠0 plus the expected SUBSTRING (`stale pin`), not the offending name; P2 and P5 exercise the same rule, P2 on a real measured name.

**5. Pins, counts, manifest.** `TotalityProofTest.lean` Part 1 = 14 `example`s = `gen_fuel_parametricity: OK (14 … both directions)`; header history carries 16 → 14 with "CURRENT count: 14". `scripts/test_unit.sh` `UNIT_TESTS` has 10 entries; `scripts/LADDER.md` row 1 `10/10 exes`; my run `Total: 10 passed, 0 failed` incl. `✓ many-restatement-test PASSED`. `lakefile.toml`: two roots + one `[[lean_exe]] many-restatement-test`; `handwritten_copy.manifest`: the two modules (`check_handwritten_sync: OK (48 hand-written files byte-identical to lean_frontend/generated/; …)`, `check_lakefile_roots: OK (217 roots = 217 generated modules + the exe root Main; 85 auxiliary modules all built)`). `scripts/fork_drift_manifest.txt` diff: exactly the `[source-content]` row `194dcdbc… → da04e3c2…` (`sha256sum frontend/model/monadic_parsing.lem` = `da04e3c262a6e776e977bac03e820d17a3c54065009ae7bd255bfadb900b9524` ✓), the NEW `[expected-semantic]` row `6cc50123… monadic_parsing.ml`, and a dated header note; layer 2 = 13 semantic + 11 cosmetic = 24 (derived count [AGENT auditor]); `check_fork_content: OK — 76 source files content/mode-pinned` / `check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 24 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)`. `git diff --stat eaa2066e9..HEAD -- 'scripts/*baseline*' 'tests/*/baseline.txt' 'tests/*/*baseline*' scripts/failure_reach_register.txt scripts/upstream_oracle_differences.json 'tests/multi_tu*' tests/libc_exec tests/immaculate` → EMPTY; `check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly … UNKNOWN=19; every row sealed; tally line consistent)`. The 19 changed files (`git diff --name-status`, evidence dir aside) are all inside the charter's §3 fence (+ the §6 LADDER count); per-commit file sets are coherent with their D-labels. `check_no_fuel_numerals: OK (321 files scanned comment-stripped; …)` — the wrapper form `_lemFuel (2 * List.length cs + 2)` is not a numeral fuel. `check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)`; `check_lem_sync: OK (src 0ea744e4…, gen bcb2f7d8…)` / `check_lem_sync: lean OK (src 0ea744e4…, gen 8a125063…)`; `check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)`.

**6. The equivalence test.** `_old` text = the primary's generated `many_lemFuel`/`many1_lemFuel` modulo whitespace and `_old` (F3). `restatement_of_sentinel`'s hypothesis `h0 : ∀ cs, parse (fuelExhausted (ParserM (fun _ => []) : parserM (List a))) cs = fuelExhausted ([] : List (List a × List Char))` is exactly the one place the two formulations differ (the sentinels), and it is consistent: LemLib `lean-lib/LemLib.lean:191` `opaque fuelExhaustedWith {α} (msg : String) (witness : α) : α := witness` (`fuelExhausted w = fuelExhaustedWith "lem: fuel exhausted" w`, `:217-218`) — under the declared body both sides are `[]`; being `opaque` it is undischargeable inside Lean, so the bare `∀ n` statement is indeed not provable and the record/errata say so. `restatement_under_measure_{many1,many}` are unconditional under `Consumes p` at fuel ≥ measure (the same `k`-induction as the sufficiency proof; I re-read every `omega` side condition); `old_at_measure_is_many : parse (many_old_lemFuel (2 * cs.length + 2) p) cs = parse (many p) cs`. Compile-time theorems about the semantics' own combinators; `main` prints one line, rc=0 — no program literal, no enumeration ([USER 2026-09-08] as quoted in the charter §0).

**7. Consumer manifest and documents.** `diff -rq` primary→head generated Lean tree: `Formatted.lean`, `Monadic_parsing.lean`, `Monadic_parsing_auxiliary.lean` differ; `CerbParserProgress.lean`, `Monadic_parsing_lemMeasureProofs.lean` new (the hand-written copies) — exactly as record §D3. `Formatted.lean` `^def .*[LemFuel]` heads: primary 13, head 6; the seven that lost the binder are `nonnegativeDecimalInteger`, `decimalInteger`, `flags0`, `fieldWidth`, `output_precision`, `conversionSpecification`, `format0`; `load_character_array_aux`, `load_character_array`, `convert`, `vsnprintf`, `printf`, `vprintf` keep it, and so do `printf_aux` (`:498`) and `store_chars_in_array` (`:503`) as the record says; `many`/`many1` lost theirs; `many_lemFuel`/`many1_lemFuel`(+`_zero`) gone, `many_run_lemFuel`/`many1_run_lemFuel`(+`_zero`, wrappers, obligations) new — nine heads lost `[LemFuel]` as record §"State at hand-over" (4) says. Tray draft 43: upstream cites exact (`deps/cerberus-upstream` @ `b9aeedcb4`, `monadic_parsing.lem:8,12,16-18,25,48-52,93-99`), classification PROPOSAL, the `.lem` text matches the head's, the theorem names exist with the stated statements; INDEX diff is the single row 43 (no other hunk). `TODO.md`: the `many`/`many1` PENDING item → RESOLVED with the record; "Stale counts" item → DONE, both true against the tree. `VALIDATION.md` §7: PENDING `0`, history sentence extended, (A) `62 (12 under a hypothesis)` — true except F1's sub-count. Charter §7 errata: the four bullets are correct (the `val` type `list (list 'a * list char)` is what the tree has; no `extra_import` in the `.lem`, the shell imports the proofs module; `policy()` untouched; the `∀ n` theorem is stated under `h0`); completeness: F2. Provenance: the operator quotes (`"D3 agree. Go ahead"`, `"launch them as claude fable class subagents"`, the 2026-09-03/-05/-08/-10 rulings) are attributed `[USER <date>]` identically in charter §0/§6, record, TODO and pending-register header; they are chat rulings I cannot check against the tree, and I found no inconsistency between their occurrences.

**Evidence directory:** 232K (≤ 1 MB); its D1 `.ml` diff lines equal my own `diff -u` of the primary's and the head's `monadic_parsing.ml`.

## printf-program table (28 programs; scratch under `.tmp/audit-scratch/`, deleted at the end)

Engines: **old-or** = primary oracle @ `eaa2066e9`; **new-or** = head oracle; **oldL** = primary Lean; **newL** = head Lean (libc loaded on both Lean sides). "rc" = exit status; SAME = byte-identical stdout AND equal rc. Outcome = the head oracle's batch line, first ~70 chars (the Lean line is byte-identical wherever marked SAME).

| program (format under test) | old-or rc | new-or rc | newL rc | oldL rc | old-or=new-or | newL=new-or | newL=oldL | outcome |
|---|---|---|---|---|---|---|---|---|
| p01 `[%-+ #0d]` (flags run) | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "UB157", …}` |
| p02 `%+-#0 5d\|%00000000000000000000012d` | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "UB157", …}` |
| p03 `%123d` (long width) | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … stdout: "[ … 5]\n"` |
| p04 `%.00000000000000000005d` (precision, leading zeros) | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … stdout: "[00012]\n"` |
| p05 `%.30d` | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … "[-000…3]\n"` |
| p06 `%%%%%%\|%%\|a%%b` | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … stdout: "%%%\|%\|a%b\n"` |
| p07 96-char literal run, no `%` | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … "the quick brown fox …"` |
| p08 `""` (empty format) | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … stdout: ""` |
| p09 `abc%` (ends in `%`) | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "Invalid_format[abc%]", …}` |
| p10 `%` only | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "Invalid_format[%]", …}` |
| p11 `x%qy` (malformed conversion) | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "Invalid_format[x%qy]", …}` |
| p12 `x%-+ #0` (flags then end) | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "Invalid_format[x%-+ #0]", …}` |
| p13 `%.d\|%.s\|%.0d` | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … stdout: "[\|\|]\n"` |
| p14 `%*d\|%.*d\|%-*.*d` | 125 | 125 | 134 | 134 | SAME | DIFF (a) | SAME | both fail: `Failure("internal error: TODO: formatted.lem 6")` / `PANIC … TODO: formatted.lem 6` |
| p15 `%hhd %hd %ld %lld %jd %zd %td %zu` | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "UB153b_illtyped_argument_for_format", …}` |
| p16 `a%db%dc%%d%s\|%c\|%x\|%X\|%o\|%u` | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "UB153b_illtyped_argument_for_format", …}` |
| p17 `%5.3s\|%-10s\|%10s\|%.0s\|%s` | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … "[  abc\|hi        \|        hi\|\|]\n"` |
| p18 400 × `a` then `%d` | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … "aaaa…1\n"` |
| p19 60 × `%d` | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … "0123456789…"` |
| p20 `sprintf`/`snprintf` | 125 | 125 | 134 | 134 | SAME | DIFF (a) | SAME | both fail: `Failure("internal error: TODO: snprintf()")` / `PANIC … TODO: snprintf()` |
| p21 `%00d\|%0d\|%-0d\|%0-d\|%0…(340 zeros)…5d` | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … "[1\|2\|3\|4\|00005]\n"` |
| p22 `[%.]` | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "Invalid_format[[%.]]", …}` |
| p23 `[%5%]` | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … "[    %]\n"` |
| p24 `[%h]` | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "Invalid_format[[%h]]", …}` |
| p25 `[%ll]` | 1 | 1 | 1 | 1 | SAME | SAME | SAME | `Undefined {ub: "Invalid_format[[%ll]]", …}` |
| p26 `%.2c\|%5c\|%-5c` | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … "[A\|    B\|C    ]\n"` |
| p27 four printfs incl. `%s%s` of empties | 0 | 0 | 0 | 0 | SAME | SAME | SAME | `Defined … stdout: "1\n2\n"` |
| p28 `abc%n` | 125 | 125 | 134 | 134 | SAME | DIFF (a) | SAME | both fail: `Failure("internal error: WIP: Formatted.convert, CS_n")` / `PANIC … WIP: Formatted.convert, CS_n` |

Counts (derived [AGENT auditor]): 28 programs; old-vs-new oracle disagreements **0/28**; old-vs-new Lean disagreements **0/28** (stdout, rc, and the three PANIC texts identical); Lean-vs-oracle: **25/28 byte-identical batch lines**, **3/28 both-fail pairs** (oracle uncaught `Failure` exit 125 / Lean `PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: <the same OCaml text>` exit 134 — VALIDATION §1 class (a), the model's own `failwith` TODO/WIP sites reached AFTER the format string parsed to `FW_asterisk`/`CS_n`, i.e. `many`/`many1` ran identically; pre-existing on both sides). **0 execution discrepancies attributable to the slice.**

## VERDICT

**MERGE-READY AFTER P2 FIXES** — one P2 (F1: the `48 generated` sub-count in `VALIDATION.md` §7's (A) cell → `53 generated`); F2–F5 are P3 notes (F5 already declared as the orchestrator's landing edit). No P1.
