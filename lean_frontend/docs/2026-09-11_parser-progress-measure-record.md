# Record — `many`/`many1` as input-indexed recursion: the shared-body restatement, the progress-hypothesis measure, and the last two rows of the fuel-pending register (charter `2026-09-11_codex-charter-parser-progress-measure.md`; run 2026-09-15)

**Branch:** `arc/parser-progress-measure` (worktree `worktrees/cerberus-lean-arc/parser-progress-measure`), on the mainline `mdd/cerberus-lean` = `eaa2066e9` (the charter's D0 rebase clause was already satisfied at launch: HEAD `5f3a61cfb` = charter + §6 note on top of `eaa2066e9`). **Worker:** a Claude Fable 5.1 subagent in fresh context ([USER 2026-09-11] "launch them as claude fable class subagents"); "Codex"/"the worker" in the charter is this agent. **Provenance:** every quoted output is verbatim; derived tallies are labelled; judgments are [AGENT]; operator words only as the charter §0 quotes them. Evidence directory: `2026-09-11_parser-progress-measure-evidence/` (plain text).

This record is written INCREMENTALLY — each deliverable's evidence is appended as soon as it exists and committed with that deliverable, so a killed session leaves a self-describing branch.

## 0. Reading-list verification — where the tree and the charter differ [AGENT]

Every §1 fact touched was re-read in the tree before use (2026-09-15). Findings that the charter's §6 note does not already cover:

1. **Charter §2 D1, the `val` of `many_run`** reads `parserM 'a -> list char -> list ('a * list char)`; the result type forced by `many p = ParserM (many_run p)` with `many : parserM 'a -> parserM (list 'a)` is `list (list 'a * list char)` (the `'a` in the charter's line is a typo for `list 'a`). Not material: the type is forced by the unchanged `val many`/`val many1`; used as forced.
2. **`scripts/check_fuel_forms.sh --selftest` names `many_lemFuel`/`many1_lemFuel` as its plant targets** (P2 `grep -v $'^FUEL_FORM\tmany_lemFuel\t'` — "stale pending pin"; P6 `theorem many_measure_sufficient : True`; P7 `theorem many1_measure_sufficient … many1 p = many1 p` — the comment `:203-209` says "the targets are the still-AMBIENT pending workers many/many1" and records the two earlier retargetings at C4 and at the 2026-09-08 close-out). The selftest runs INSIDE `scripts/test_unit.sh` (`:219`, Tier A row 1) before the gate proper. Once this slice empties the pending register there is no pending worker to target, so P2/P6/P7 as written fail — the gate, in its self-test mode, does not accept an EMPTY register. [AGENT] This is the charter §1 "empty register" case in its selftest form (the `policy` function's own reads — `grep -v`/`awk`/`comm`/`grep -c` under `set -uo pipefail`, no `-e` — accept an empty data set; observed at D2 below), and the fence's "ONLY the empty-register fix of §1, plant-tested" is read to cover retargeting those three plants so the selftest keeps testing what it claims without a pending worker (see D2; open question 1 for the orchestrator).
3. **Sequencing of the fork-drift manifest edit (charter D5.1).** `check_fork_drift.sh` runs inside `test_unit.sh` (`:297-304`) and pins `frontend/model/monadic_parsing.lem` by content (`[source-content]` row `:337`, sha256 of the bytes via `scripts/check_fork_content.py`) and the generated tree's differing-file SET (a newly differing `monadic_parsing.ml` is "NEW OCaml-token drift", RED). Both move at D1; the charter's D3 requires `test_unit.sh` green. Therefore the two enumerated hunks (and only those) are applied at D1, gate-observed, exactly as the sibling slice did at its D3(f) — recorded under D5.1 below with the cross-reference. No other hunk.
4. **`scripts/failure_reach_register.txt`** keys no `Monadic_parsing` site (grep `many|monadic|fuelExhausted`: 0 rows; the census tokens are `failwithI`/`panic!`/`panic`/`panicCore`), so renaming the fuel'd workers moves no register row.
5. **`scripts/upstream_oracle_differences.json`** has exactly ONE reviewed pin, `minimal/097-null-ptr-arith.undef.c`, whose fork-side backtrace frames are `core_eval.ml`/`lem_list.ml` (its rationale, re-pinned 2026-09-15) and whose source has no `printf`; a `monadic_parsing.ml` line shift is therefore not expected to touch it — to be OBSERVED at D6 (§6 lesson ii), not assumed.
6. **`check_no_fuel_numerals.sh` F3** (`:116`) flags `_lemFuel <digits>` or `_lemFuel (<digits>)`; the measured wrapper form `_lemFuel (2 * List.length cs + 2)` matches neither alternative (the parenthesised alternative requires `)` right after the numeral). Observed on the real gate at D2.

Facts verified as stated: `monadic_parsing.lem` is 115 lines with the block at `:100-106` and the declares at `:114-115`; the generated `Monadic_parsing.lean:125-145` is as §1 describes (lem renders `List.concatMap` as `List.flatten (List.map …)` and a tuple-lambda as `fun (p : …) => match p with | (a1, cs') => …`); `TotalityProofTest.lean:55-71` pins 16 wrappers with `many`/`many1` at `:66-67`; `fuel_forms_pending.txt` has the two data rows `:60-61`; `fuel_hypotheses.txt` has 10 data rows `:60-69`; fork-drift layer 2 = 12 `[expected-semantic]` + 11 `[expected-cosmetic]` = 23; the tray's last draft is 42 (next free = 43); `test_unit.sh` runs 9 exes; the pristine oracle (`.validation-foundations/`) is ABSENT in this worktree and is built at D0; the four call sites `formatted.lem:90,97,103,170-171` and `digit :83-85`, `nonzero :66-79` (a `sat`), `conversionSpecification :152-153` (leading `char #'%'`) read as cited; `grep -rn many frontend/model/*.lem` finds no other user.

## D0 — Snapshot and base — DONE

**Base.** `git log --oneline -3` at launch: `5f3a61cfb` (charter §6 note) → `cd2952045` (charter) → `eaa2066e9` = `git -C …/cerberus-lean rev-parse --short mdd/cerberus-lean`; the D0 rebase clause is already satisfied (the branch was rebased before launch) and the worktree was primed from the primary checkout rebuilt at `eaa2066e9`. Driver stamps before anything ran (verbatim):
```
check_driver_fresh: oracle OK (bin 1b7cff622aaff92397f007c2d7d083bcfa5ea2952bd3c4af37a98d8430c5bc73, src 19de18ed9f03a529067ec7103f58917d116933da22bc317546408b2f7d66043e)
check_driver_fresh: lean OK (bin e36af96d9eed60cfac55414d675d354edff4268b0bdfad6031c121137dc3be84, src a0ed1133a00bda9cc6ab4c84b2d534548f50f1ace248c61654fcd9ac253036bb)
```

**Tier A, the zero-movement baseline.** [AGENT] Run TWICE before any change. Run 1 (`.tmp/d0-fast`) had every lane PASSED but ended `Source unchanged: False` / `rc=1`: I wrote this record's skeleton and the evidence directory into the tree WHILE it ran, and `release.py` hashes untracked non-ignored files at start and end — the sibling slice's D0 lesson, repeated once. Run 1 is discarded as certification. Run 2, tree untouched throughout, is the baseline (verbatim; full key-line extract per lane in `…-evidence/d0-tierA-verdicts.txt`):
```
$ CERB_MEM_MAX=48G python3 scripts/release.py --mode fast --lane-timeout 3300 --out .tmp/d0-fast2      # → 2026-09-15T18:55:18Z
RUN A1: ./scripts/test_unit.sh
PASSED A1 (143.6s)
PASSED A2 (27.4s) · A3 (50.6s) · A4 (22.2s) · A4b (23.7s) · A4c (3.0s) · A5 (21.7s) · A6 (2.1s) · A6b (3.5s) · A7 (10.0s) · A8 (8.6s) · A9 (16.2s) · A10 (16.7s) · A11 (57.1s)
fast: passed; 14/14 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
rc=0
```
(The `·`-joined PASSED durations are the runner's own lines, joined by me; the RUN/PASSED pairs are verbatim in the evidence file.) Named lines:
```
A1  check_handwritten_sync: OK (46 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
    Total: 9 passed, 0 failed
    check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
    check_no_fuel_numerals: OK (316 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
    gen_fuel_parametricity: OK (16 ambient fuel wrappers in the generated tree = the 16 pins of TotalityProofTest.lean Part 1, both directions)
    check_lakefile_roots: OK (215 roots = 215 generated modules + the exe root Main; 85 auxiliary modules all built)
    check_fuel_forms: SELFTEST OK (24 plants with the declared label — 6 on the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: …)
    check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
    check_fuel_forms: OK (81 fuel'd workers: 60 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 10 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (…
    check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent
    check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
    check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 23 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
A2  SUMMARY: total=111 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
A3  SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
A4  SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
A4b SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
A4c SUMMARY: exec_match=9 neg_pinned=5 fail=0
A5  SUMMARY: match=12 diff=0 / ALL MATCH RECORDED BASELINE
A6  SUMMARY: total=2 match=2 fail=0 / ALL PASSED          A6b SUMMARY: total=7 match=7 fail=0 / ALL PASSED
A7  Total: 111 / Success rate: 100% (of cerberus successes) / batch diagnostic producers: 8/8 passed / ALL PASSED
A8  Total: 111 / Success rate: 100% (of cerberus successes) / ALL PASSED
A9  SUMMARY: total=111 same=108 diff=3 ocaml_fail=0 lean_fail=0
A10 [lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus) / GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
A11 SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0 / BASELINE OK (213 entries, exact match)
```
The two lines the charter asks for verbatim, BEFORE any change: `check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)` and `gen_fuel_parametricity: OK (16 ambient fuel wrappers in the generated tree = the 16 pins of TotalityProofTest.lean Part 1, both directions)`.

**Direct `./scripts/test_unit.sh`** (2026-09-15 18:55:39Z → 18:58:28Z; key lines in `…-evidence/d0-unit-and-pristine.txt`): `Total: 9 passed, 0 failed`, the same `gen_fuel_parametricity: OK (16 …)` / `check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)` / `check_fork_drift: OK — … layer 2: 23 …` lines as A1, `rc=0`.

**The pristine upstream oracle** (absent in this worktree; built once, before any change, per `docs/2026-09-06_independent-oracle-and-fork-pins.md:30-42`; verbatim):
```
$ /home/dev/projects/cerberus-lean-proj/scripts/ce python3 scripts/build_independent_oracle.py --lem-repo /home/dev/projects/cerberus-lean-proj/lem-lean --cerberus-repo /home/dev/projects/cerberus-lean-proj/cerberus-lean --out .validation-foundations/independent-oracle-v2
cerberus-lean-proj env: switch=/home/dev/projects/cerberus-lean-proj/cerberus-lean/_opam, git redirects active
lem-compiler: passed (6.634s)
lem-libraries: passed (1.17s)
lem-runtime-build: passed (4.198s)
lem-runtime-install: passed (0.147s)
cerberus-generation: passed (17.878s)
cerberus-build: passed (9.47s)
Independent upstream oracle: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/parser-progress-measure/.validation-foundations/independent-oracle-v2/manifest.json
real 41.37
user 56.44
sys 14.52
rc=0
```
Manifest `status: built`; upstream cerberus `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`, upstream lem `3802cb04b53d5f1096a464e51ecbfb2a750a7ccd` (the builder's pins; `git archive` of both local repos — read-only); manifest sha256 `a5cddc3fed034c0299f51b716814664b40d89aacb2dd214c7fb0746595ad2f5e`; oracle binary sha256 `4068d72fd88ba9d6e543560a5d703c28e40a95e1d791f95134200fa32b088997`. The lane (Tier B row 10) runs at D6.

**D0 acceptance [AGENT, observed]:** Tier A green with the recorded baselines unchanged (every `Baseline check: 0 regression(s), 0 improvement(s)`, `BASELINE OK`, `ALL MATCH RECORDED BASELINE`, `GATE PASS … baseline unchanged`), partition `60 + 13 + 2 + 6 = 81`, parametricity pin set 16 = 16, fork-drift layer 2 = 23, failure-reach 233, pristine oracle built. Committed as D0.

## D1 — The restatement (shared lem body): same parsers, input-indexed recursion — DONE

### The `.lem` diff, verbatim (`git diff frontend/model/monadic_parsing.lem`; `git diff --stat` = `1 file changed, 38 insertions(+), 14 deletions(-)`)

```diff
diff --git a/frontend/model/monadic_parsing.lem b/frontend/model/monadic_parsing.lem
index 32efaa586..c3ef8e86c 100644
--- a/frontend/model/monadic_parsing.lem
+++ b/frontend/model/monadic_parsing.lem
@@ -97,19 +97,43 @@ let rec string cs =
    termination). === *)
 declare {lean} termination_argument string = automatic
 
+(* many/many1 restated as input-indexed recursion (2026-09-15,
+   lean_frontend/docs/2026-09-11_parser-progress-measure-record.md):
+   many_run/many1_run are the two parsers' RUN functions with the input as
+   an explicit parameter - the bodies are exactly the unfoldings of
+   `many p = many1 p <|> return []` (mplus, then head-or-empty) and
+   `many1 p = p >>= fun a -> many p >>= fun _as -> return (a::_as)`
+   (bind = concatMap over p's results; `>>= return` = map), so `many` and
+   `many1` denote the same parsers as before on every input, for every p.
+   The recursion descends the input cs: every hop many_run cs -> many1_run
+   cs -> many_run cs' passes through one result (a, cs') of p on cs. When
+   p CONSUMES (every result of `parse p cs` has a strictly shorter rest -
+   true of every parser passed to many/many1 in formatted.lem), the depth
+   from many_run p cs is at most 2 * length cs + 2 and from many1_run p cs
+   at most 2 * length cs + 1; that bound is the Lean-target fuel measure
+   below (fuel_measure ... assuming CerbParserProgress.Consumes p), so the
+   two workers are MEASURED and fuel-free; a non-consuming p recurses
+   forever in OCaml and exhausts the Lean counter (the loud sentinel). *)
+val     many_run:  forall 'a. parserM 'a -> list char -> list (list 'a * list char)
+val     many1_run: forall 'a. parserM 'a -> list char -> list (list 'a * list char)
+let rec many_run p cs =
+  match many1_run p cs ++ [([], cs)] with
+    | []     -> []
+    | (x::_) -> [x]
+  end
+and     many1_run p cs =
+  List.concatMap (fun (a, cs') ->
+    List.map (fun (_as, cs'') -> (a::_as, cs'')) (many_run p cs')
+  ) (parse p cs)
+
 val     many:  forall 'a. parserM 'a -> parserM (list 'a)
 val     many1: forall 'a. parserM 'a -> parserM (list 'a)
-let rec many p = many1 p <|> return []
-and     many1 p =
-  p      >>= fun a   ->
-  many p >>= fun _as ->
-  return (a::_as)
-
-(* many/many1 are genuinely mutual with NO structural decrease (the
-   grammar-recursion terminates only through input consumption): fuel,
-   all-or-none across the mutual block (backend requirement). The
-   sentinel is the always-failing parser (empty result list) — reached
-   only through the LOUD fuelExhausted panic, never a silent default.
-   lemDefaultFuel dominates any real parse depth. *)
-declare {lean} fuel val many = `fuelExhausted (ParserM (fun _ => []))`
-declare {lean} fuel val many1 = `fuelExhausted (ParserM (fun _ => []))`
+let many p  = ParserM (many_run p)
+let many1 p = ParserM (many1_run p)
+
+(* Lean target: the mutual block is fuel'd all-or-none (backend
+   requirement). The sentinel is the empty result list - the always-
+   failing parser's output - reached only through the LOUD fuelExhausted
+   panic, never a silent default. *)
+declare {lean} fuel val many_run  = `fuelExhausted []`
+declare {lean} fuel val many1_run = `fuelExhausted []`
```
[AGENT] The `val many_run`/`val many1_run` result type is `list (list 'a * list char)` (forced by the unchanged `val many`/`val many1`; the charter's `list ('a * list char)` is a typo — §0 item 1). The comment is ASCII (the model's `.lem` comments are; the tray patch carries this text). Nothing else in the module changed (`string`'s declare `:98` and everything above are untouched).

### The correctness argument — the same parsers, for every `p` and every input [AGENT]

Write `⟦q⟧ cs` for `parse q cs`, the result list of a parser on an input. The four `inline`s
in play are (`monadic_parsing.lem`): `return a = ParserM (fun cs -> [(a, cs)])` (`:12`),
`p >>= f = ParserM (fun cs -> List.concatMap (fun (a, cs') -> parse (f a) cs') (parse p cs))`
(`:16-18`), `mplus p1 p2 = ParserM (fun cs -> parse p1 cs ++ parse p2 cs)` (`:25`), and
`p1 <|> p2 = ParserM (fun cs -> match parse (mplus p1 p2) cs with [] -> [] | x::_ -> [x] end)`
(`:48-52`). `parse (ParserM f) = f` (`:8`). Unfold each exactly once in the OLD block:

* `⟦many1 p⟧ cs` = `⟦p >>= (fun a -> many p >>= fun _as -> return (a::_as))⟧ cs`
  = `List.concatMap (fun (a, cs') -> ⟦many p >>= fun _as -> return (a::_as)⟧ cs') (⟦p⟧ cs)`
  and, for each result `(a, cs')`, `⟦many p >>= fun _as -> return (a::_as)⟧ cs'`
  = `List.concatMap (fun (_as, cs'') -> ⟦return (a::_as)⟧ cs'') (⟦many p⟧ cs')`
  = `List.concatMap (fun (_as, cs'') -> [(a::_as, cs'')]) (⟦many p⟧ cs')`
  = `List.map (fun (_as, cs'') -> (a::_as, cs'')) (⟦many p⟧ cs')`
  — the last step is the list identity `concatMap (fun x -> [g x]) l = map g l` (a singleton
  per element, flattened), which holds for every list in both targets. So
  `⟦many1 p⟧ cs = List.concatMap (fun (a, cs') -> List.map (fun (_as, cs'') -> (a::_as, cs'')) (⟦many p⟧ cs')) (⟦p⟧ cs)`
  — this is `many1_run p cs` with `⟦many p⟧` in place of `many_run p`.
* `⟦many p⟧ cs` = `⟦many1 p <|> return []⟧ cs` = `match ⟦many1 p⟧ cs ++ ⟦return []⟧ cs with [] -> [] | x::_ -> [x] end`
  = `match ⟦many1 p⟧ cs ++ [([], cs)] with [] -> [] | x::_ -> [x] end`
  — this is `many_run p cs` with `⟦many1 p⟧` in place of `many1_run p`.

So the pair `(⟦many p⟧, ⟦many1 p⟧)` satisfies EXACTLY the defining equations of the pair
`(many_run p, many1_run p)`; and the NEW `many p = ParserM (many_run p)`, `many1 p = ParserM
(many1_run p)` give `⟦many p⟧ = many_run p`, `⟦many1 p⟧ = many1_run p`. Both formulations are
the same recursive system of equations on the same unknowns, differing only in WHERE the
input is bound: OLD binds `cs` by the lambda inside the `ParserM` built by `<|>`/`>>=` at each
level; NEW takes it as a parameter. The evaluation of `⟦many p⟧ cs` in OLD and of `many_run p cs`
in NEW performs the same hops in the same order: `many` on `cs` → `many1` on `cs` → for each
`(a, cs')` in `⟦p⟧ cs`, `many` on `cs'` → … — one `p`-result per two hops. Hence:

* on every `p` (deterministic or multi-result, failing or not) and every `cs`, if the OLD
  evaluation terminates (OCaml), the NEW one terminates with the same list, and conversely;
* a non-consuming `p` that succeeds on some `cs` (a result `(a, cs)` with `cs` unchanged)
  makes BOTH formulations recurse forever in OCaml (the hop `many cs → many1 cs → many cs`
  repeats) — unchanged behaviour, deliberately (the charter forbids a guard: it would be a
  semantics change);
* in Lean, at EQUAL fuel the two fuel'd workers make the same hops, so they agree wherever
  neither reaches its sentinel; the sentinels differ in shape (`fuelExhausted (ParserM (fun _
  => []))` OLD vs `fuelExhausted []` NEW — the codomain changed from a parser to a result
  list), and LemLib's `fuelExhaustedWith` is `opaque`, so the two exhausted VALUES are not
  provably related; D4.2 states the kernel theorem accordingly (under the measure, where no
  sentinel is reached; and, for every fuel, under the one hypothesis that the two sentinels run
  alike).

Nothing else in the module changed; `many`/`many1` keep their `val`s (`:100-101` before, now
`:127-128`), so every caller in `formatted.lem` elaborates unchanged. The only OCaml-visible
change is the restatement of two functions by two new functions plus two one-line wrappers —
an extensionally identical restatement of the parsers.

### The generated trees before/after (untracked build outputs; diffs verbatim in `…-evidence/d1-lem-and-ml-diffs.txt` and `…-evidence/d1-lean-diff.txt`)

* `ocaml_frontend/generated/monadic_parsing.ml`: sha256 `ef3a6612c1e380d888dd11bef229b2518c0b31e7c028cfee8e99d9c6a2f34cac` → `13ae02dfd834de19f9671c0219910fbf439c853de22decca3da306b05a161f45`; the diff is the comment block + `let rec many_run p cs … and many1_run p cs …` (lem renders `++` as `List.rev_append (List.rev …) …` and `List.concatMap f l` as `List.concat (map f l)`, its idioms already used by `parse_bind`/`parse_mplus` in this file) + the two one-line `let many p = ParserM (many_run p)` / `let many1 p = ParserM (many1_run p)`. `make prelude-src` regenerated ONLY this file (`diff -rq` of the tree before/after: one file). The oracle rebuilt by `scripts/common.sh build_cerberus` (rc=0): stamp `check_driver_fresh: recorded oracle stamp (bin a765c34586f84487d03422ca8ccb2b5e4e3b4ba15f6373d229bff40beb34656d, src ec61e98ba7b9b6401d9696dc52b8e0eac173f260f846ac52951996d12b102b7c)`.
* `lean_frontend/generated/Monadic_parsing.lean`: sha256 `64f3591c626a1eaf7cf8ab91d5fa0f0ebfae5e6b7611ca81b069e9a894d16386` → `518a4671d6287c421b6677b18670d9e1d7d9d99c1880595630262c511ed6f162`. The mutual block is now
  ```lean
   def  many_run_lemFuel  {a : Type} (lemFuel : Nat)  (p : parserM a) (cs : List (Char))  : List ((List a ×List (Char))) := match lemFuel with
    | 0 => (fuelExhausted [])
    | Nat.succ lemFuel => (
    match (many1_run_lemFuel lemFuel)  p  cs  ++  [([], cs)] with  |  [] =>  [] | ( x :: _) =>  [x]
    )
  def      many1_run_lemFuel  {a : Type} (lemFuel : Nat)  (p : parserM a) (cs : List (Char))  : List ((List a ×List (Char))) := match lemFuel with
    | 0 => (fuelExhausted [])
    | Nat.succ lemFuel => (
    List.flatten  (List.map  (fun (p0 : (a ×List (Char))) =>  match p0 with |  (a1,  cs') =>      List.map  (fun (p : (List a ×List (Char))) =>  match p with |  (_as,  cs'') =>  ((a1 :: _as), cs'') )  ((many_run_lemFuel lemFuel)  p  cs') 
    )  (parse  p  cs)))
  ```
  with ambient wrappers `many_run`/`many1_run` (`[LemFuel] … := many_run_lemFuel LemFuel.fuel`), `_zero` lemmas `many_run_lemFuel 0 p cs = (fuelExhausted [])` by `rfl`, and `def many {a : Type} [LemFuel] (p : parserM a) : parserM (List a) := ParserM (many_run p)` (likewise `many1`). [AGENT] lem's pattern-compilation fresh-name pass avoided the capture I had flagged as a risk: the outer tuple-lambda binder is `p0` because `p` (the parser) is free in its body, the inner one is `p`. The GENERATED binders the D2 measures are spelled over: `p`, `cs`. `Formatted.lean` and `Monadic_parsing_auxiliary.lean` are byte-identical to before at D1 (`many`/`many1` still ambient).
* Lean build (`CERB_MEM_MAX=48G ../scripts/capped lake build CerberusLean cerberus-lean`, 19:06:00Z → 19:06:27Z): `Build completed successfully (392 jobs).` — rebuilt (not replayed): `Monadic_parsing`, `Monadic_parsing_auxiliary`, `Formatted`, `Formatted_auxiliary`, `Driver`, `CerbND`, `Main` (+ their `:c.o`; 14 `Built` lines). Stamps after `--record-lean`: `check_driver_fresh: oracle OK (bin a765c345…, src ec61e98b…)` / `check_driver_fresh: lean OK (bin 11159bb4b7bc9cf5a523ccd83a2095ef21c0de840aa05da920b61a4db7850285, src a5ccb9083a076cf131846452e230cd7e2caaf1492b52a5d76e5a08b39f8d1774)`.

### Fork-drift manifest — the two enumerated hunks, performed HERE (charter D5.1; §0 item 3: the gate is in Tier A row 1) — gate-observed hashes, four runs verbatim in `…-evidence/d1-fork-drift-gate-runs.txt`

1. before any edit: `check_fork_content: FAIL — source-content drift inside reviewed file(s):` / `frontend/model/monadic_parsing.lem: expected ('100644', '194dcdbcb3c6bd9648107ef2f264667ef5ce765e791a1c345462d8cf5bb01136'), actual ('100644', '6244570634264c7b810189bbdf0804ac4f52ace7513c33fee22bca9c845ccc2e')`;
2. after the `[source-content]` row moved: `check_fork_drift: FAIL — generated-tree differing-file set drifted from the manifest.` / `--- differing now but not excused (NEW OCaml-token drift):` / `    monadic_parsing.ml`;
3. with a `0000…` placeholder `[expected-semantic]` row: `check_fork_drift: FAIL — monadic_parsing.ml: excused-diff hash moved (manifest 0000…, live 6cc50123c4727ca848299fc38a7f62c889acd6e5f5c1ce5a5c732b52e9abd05c) — the fork-vs-upstream delta of this generated file CHANGED; re-review the .lem`;
4. final:
```
check_fork_content: OK — 76 source files content/mode-pinned
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 24 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
```
Hunks: `[source-content]` `frontend/model/monadic_parsing.lem` `194dcdbc… → 62445706…`; `[expected-semantic]` NEW `6cc50123… monadic_parsing.ml` (layer 2: 23 → 24); one dated 10-line header note ("GENUINE shared-model change, an EXTENSIONALLY IDENTICAL restatement … the OCaml's results are unchanged on every input for every p"). No other hunk (`git diff --stat scripts/fork_drift_manifest.txt` = `12 insertions(+), 1 deletion(-)`).

### D1 acceptance (b) — Tier A rows 2–11 green with ZERO movement; row 1 red only on the named drift (verbatim; key lines in `…-evidence/d1-tierA-verdicts.txt`)

```
$ CERB_MEM_MAX=48G python3 scripts/release.py --mode fast --lane-timeout 3300 --out .tmp/d1-fast      # 19:08 → 19:14:04Z
RUN A1: ./scripts/test_unit.sh
FAILED A1 (1.5s)
PASSED A2 (27.4s) · A3 (50.5s) · A4 (22.3s) · A4b (23.7s) · A4c (3.0s) · A5 (21.5s) · A6 (2.1s) · A6b (3.5s) · A7 (10.1s) · A8 (8.7s) · A9 (16.2s) · A10 (16.5s) · A11 (57.1s)
fast: failed; 13/14 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
rc=1
```
Every lane's SUMMARY/Baseline line is IDENTICAL to D0's: A2 `total=111 match=90 ub_match=18 … mismatch=0 … cerb_skip=3` / `Baseline check: 0 regression(s), 0 improvement(s)`; A3 `total=212 match=183 ub_match=16 … cerb_skip=13` / 0/0; A4 `total=90 match=66 ub_match=20 … cerb_skip=4` / 0/0; A4b `total=93 match=93` / 0/0; A4c `exec_match=9 neg_pinned=5 fail=0`; A5 (printf-heavy, libc) `match=12 diff=0`; A6 `2/2`; A6b `7/7`; A7/A8 `100%`; A9 `same=108 diff=3`; A10 `GATE PASS … (16/16)`; A11 `total=213 match=207 ub_match=6 … BASELINE OK (213 entries, exact match)`. A1 stopped at the `totality-proof-test` exe build (`test_unit.sh` is `set -e` over `lake build | tail -3`): its Part 1 pins `:66-67` name `many_lemFuel`/`many1_lemFuel`, which no longer exist — the parametricity-set drift the charter names as D1's allowed red (cleared at D3). The gates that `test_unit.sh` never reached were run one by one (next).

### D1 — the gates `test_unit.sh` did not reach, run one by one (19:15:07Z → 19:15:28Z; verbatim in `…-evidence/d1-gates-individually.txt`)

```
=== lake build totality-proof-test ===
error: test/Unit/TotalityProofTest.lean:66:45: Function expected at
error: test/Unit/TotalityProofTest.lean:67:46: Function expected at
=== gen_fuel_parametricity --check ===
gen_fuel_parametricity: FAIL — fuel'd wrapper(s) in the tree with NO parametricity pin in TotalityProofTest.lean: many1_run, many_run
gen_fuel_parametricity: FAIL — pin(s) in TotalityProofTest.lean with no wrapper in the tree: many, many1
=== check_fuel_forms.sh ===
check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: FAIL — fuel'd worker(s) REACHABLE from drive with an opaque (fail-open) exhaustion, not in …/scripts/fuel_forms_pending.txt:
  many1_run_lemFuel
  many_run_lemFuel
check_fuel_forms: FAIL — pending register row(s) no longer a reachable ambient worker (stale pin; edit the register):
  many1_lemFuel
  many_lemFuel
```
— the two reds the charter names for D1 (the partition total is 81 and the two ambient-reachable names are now `many_run_lemFuel`/`many1_run_lemFuel`, i.e. exactly the two renamed workers). Everything else green: `check_exec_purity: CLEAN (11 modules)`; `check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)` (its FUEL leg: 63 contract lemmas, every cone ⊆ the standard three); `check_sorry_token: OK (309 files … 0 sorry tokens)`; `check_no_fuel_numerals: OK (316 files … F1-F6 …)`; `check_lakefile_roots: OK (215 roots = 215 generated modules + the exe root Main; 85 auxiliary modules all built)`; `check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly … UNKNOWN=19; every row sealed; tally line consistent` (the worker rename moved no row — §0 item 4); `check_fixture_freeze: OK (16 fixture files …)`; `test_renumber_plants: OK (12 plants …)`; `check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)`; `check_lem_sync: OK (src 60c14365…, gen bcb2f7d8…)` / `check_lem_sync: lean OK (src 60c14365…, gen 5ed7106f…)`; `check_fork_drift: OK … layer 2: 24 …` (above).

**D1 acceptance [AGENT, observed]:** (a) both generated diffs with sha256 — above and in the evidence; (b) Tier A rows 2–11 green with zero movement, the only reds the two named gates (and the `totality-proof-test` exe build, the same drift); (c) `git diff --stat` = `frontend/model/monadic_parsing.lem` + `scripts/fork_drift_manifest.txt` (the D5.1 hunks brought forward per §0 item 3). Committed as D1.

## D2 — The measure under the progress hypothesis — DONE

### The `.lem` declares (diff since D1, verbatim)

```diff
diff --git a/frontend/model/monadic_parsing.lem b/frontend/model/monadic_parsing.lem
index c3ef8e86c..2d6beecad 100644
--- a/frontend/model/monadic_parsing.lem
+++ b/frontend/model/monadic_parsing.lem
@@ -137,3 +137,15 @@ let many1 p = ParserM (many1_run p)
    panic, never a silent default. *)
 declare {lean} fuel val many_run  = `fuelExhausted []`
 declare {lean} fuel val many1_run = `fuelExhausted []`
+
+(* Lean target: the two workers are MEASURED under the progress hypothesis
+   (record D2): the wrappers are fuel-free and compute the parse at the
+   counter 2 * length cs + 2 (many_run) / 2 * length cs + 1 (many1_run) once
+   the input arrives. The hypothesis vocabulary is
+   lean_frontend/CerbParserProgress.lean (imported by the proofs module
+   lean_frontend/Monadic_parsing_lemMeasureProofs.lean, which the generated
+   obligation shell imports - NOT by `extra_import`, which would make this
+   module import a module that must import it); the invariant every exec-path
+   caller satisfies is cited in scripts/fuel_hypotheses.txt. *)
+declare {lean} fuel_measure val many_run  = `2 * List.length cs + 2` assuming `CerbParserProgress.Consumes p`
+declare {lean} fuel_measure val many1_run = `2 * List.length cs + 1` assuming `CerbParserProgress.Consumes p`
```
The `fuel` sentinel declares stay (`:138-139`); the two `fuel_measure … assuming` declares are spelled over the GENERATED binders `p`, `cs` (D1's Lean text). `make prelude-src` after this edit: `ocaml_frontend/generated/monadic_parsing.ml` byte-IDENTICAL to D1's (`cmp` = IDENTICAL; sha256 `13ae02df…` unchanged) — the declares are Lean-only; the lem-sync stamps re-recorded (`src 0ea744e4…, gen bcb2f7d8…` OCaml / `gen 8a125063…` Lean); `build_cerberus` rc=0, oracle stamp `bin d918cba3…, src 98ad48b5…`.

### The new modules (both in `handwritten_copy.manifest` and as `lakefile.toml` roots; `check_lakefile_roots: OK (217 roots = 217 generated modules + the exe root Main; 85 auxiliary modules all built)`; `check_handwritten_sync: OK (48 hand-written files …)`)

* `lean_frontend/CerbParserProgress.lean` — Props only (`import Monadic_parsing`; no `partial`/`opaque`/`implemented_by`): `def Consumes {a : Type} (p : parserM a) : Prop := ∀ (cs : List Char) (r : a × List Char), r ∈ parse p cs → r.2.length < cs.length`; `NonExpanding` (`≤`); `nonExpanding_of_consumes`. Header = the invariant with the four call-site cites (the `CerbCoreShape` pattern). D4's discharge theorems join it below.
* `lean_frontend/Monadic_parsing_lemMeasureProofs.lean` — `parse_nil_of_consumes`, `many1_run_stable_aux` (induction on a bound `k ≥ |cs|`, both fuels generalized, `List.map_congr_left` for the traversal), `many_run_stable_aux` (one unfolding to the sibling), and THE two obligations `many_run_measure_sufficient` / `many1_run_measure_sufficient` with exactly the shell's binders `p cs lemHyp lemFuel lemMeasureLe`. Tactics: `induction`/`cases`/`intro`/`subst`/`simp only`/`congr`/`apply`/`obtain`/`dsimp only`/`rw`/`omega`/`simp` — kernel-checked, no option bumps, no `sorry`, no `native_decide`/`decide`.

### The measure and why it bounds the depth under the hypothesis [AGENT]

The two workers share one counter (lem FM-mutual: the block is fuel'd all-or-none, every
hop decrements once). Write `|cs|` for `List.length cs`. The hop structure of the generated
workers (D1's Lean text):

* `many_run_lemFuel (f+1) p cs` makes ONE hop, to `many1_run_lemFuel f p cs` on the SAME
  input, then takes the head of `… ++ [([], cs)]` — no further call.
* `many1_run_lemFuel (f+1) p cs` makes, for EACH result `(a, cs')` of `parse p cs`, ONE hop
  to `many_run_lemFuel f p cs'`, all at the same counter `f` (siblings do not share
  consumption: fuel is a depth bound, not a step count) — no further call.

Under `Consumes p` — every `(a, cs')` in `parse p cs` has `|cs'| < |cs|` — each pair of
hops `many_run cs → many1_run cs → many_run cs'` strictly shortens the input. So from
`many1_run p cs` the deepest chain is `many1_run cs → many_run cs' → many1_run cs' → … →
many_run cs⁽ⁱ⁾ → many1_run cs⁽ⁱ⁾` with `|cs| > |cs'| > … ≥ 0`, hence at most `|cs|`
descents, i.e. at most `2·|cs|` hops below `many1_run cs`, and at the exhausted input
`many1_run [] ` makes NO hop (the hypothesis forces `parse p [] = []`: no rest is shorter
than the empty list — `parse_nil_of_consumes`). Counting the entry frame: depth ≤ `2·|cs| + 1`
from `many1_run p cs`, and ≤ `2·|cs| + 2` from `many_run p cs` (one more frame, same input).
These are the two measures. They are FUNCTIONS OF THE INPUT (`cs`, a parameter of the
restated workers) and of nothing else — no budget numeral ([USER 2026-09-03], no magic
values); `2`, `+ 2`, `+ 1` are structural coefficients of the hop pattern, exactly as the
`+ 1` of `to_pures`'s `List.length l + 1`. The wrapper computes its measure ONCE per
application to an input (`many_run p cs = many_run_lemFuel (2 * List.length cs + 2) p cs`,
where `cs` is the remaining printf format string — tens of characters), so the cost is one
`List.length` per `many`/`many1` application, never inside the recursion.

The sufficiency proof (`Monadic_parsing_lemMeasureProofs.lean`) is the C4 template: fuel-
STABILITY of `many1_run_lemFuel` above `2·|cs| + 1` by induction on a bound `k ≥ |cs|`, the
two fuels generalized, the hypothesis threaded — at `k = 0` the input is `[]` and both
sides are `List.flatten (List.map _ [])` after `parse_nil_of_consumes`; at `k + 1` the
`List.map` over `parse p cs` is rewritten member-wise (`List.map_congr_left`), each member
`(a1, cs')` giving `|cs'| < |cs|` by the hypothesis, so the inner `many_run_lemFuel` runs at
a counter `≥ 2·|cs'| + 2` and unfolds to `many1_run_lemFuel` at `≥ 2·|cs'| + 1` on `cs'`
with `|cs'| ≤ k` — the induction hypothesis. `many_run`'s stability is one unfolding to
`many1_run`'s at the same input. The two `_measure_sufficient` theorems are the stability
lemmas at `(lemFuel, measure)`; the generated `Monadic_parsing_auxiliary.lean` obligations
delegate to them by name with the `lemHyp` binder in the `assuming` position.

### Why there is no `declare {lean} extra_import` (a forced deviation from the charter's wording) [AGENT]

The charter names `CerbParserProgress` "by `declare {lean} extra_import`" as the precedents
`CerbCoreShape`/`CerbCoreMeasure` are. Those seams import `Core` and are imported by OTHER
modules (`Core_aux`, `Core_reduction`). Here the hypothesis is a Prop over `parserM`/`parse`,
defined in `Monadic_parsing` ITSELF; `extra_import` lands in the main module (observed:
`generated/Core_aux.lean:13 import CerbCoreShape`), so `Monadic_parsing → CerbParserProgress
→ Monadic_parsing` would be an import cycle. The hypothesis text cannot be inlined either:
the renderer admits only parameters and QUALIFIED globals (lem-lean record §2.2; an
unqualified `parse`, a `∀`, or a bound `r` is FH-free and refused). Resolution: no
`extra_import`; `CerbParserProgress.lean` imports `Monadic_parsing`; the hand-written
`Monadic_parsing_lemMeasureProofs.lean` imports both; the generated obligation shell
`Monadic_parsing_auxiliary.lean` imports the proofs module (as every shell with obligations
does — `Formatted_auxiliary.lean:6`) and so resolves `CerbParserProgress.Consumes`
transitively. The wrapper never mentions the hypothesis (hypothesis-free by design), so the
main module needs no import. Observed to build (below). Open question 2 for the orchestrator:
whether a `CerbCoreShape`-style seam for a SAME-module hypothesis should be a lem-lean item
(an auxiliary-only import declare), or whether this transitive-through-the-proofs-module
placement is the pattern.

### The generated tree after D2 (verbatim excerpts in `…-evidence/d2-generated-tree.txt`)

```lean
def many_run  {a : Type} ( p : parserM a) ( cs : List (Char)) : List ((List a ×List (Char))) := many_run_lemFuel (2 * List.length cs + 2)  p  cs
def many1_run  {a : Type} ( p : parserM a) ( cs : List (Char)) : List ((List a ×List (Char))) := many1_run_lemFuel (2 * List.length cs + 1)  p  cs
def  many  {a : Type}  (p : parserM a)   : parserM (List a) :=  ParserM  (many_run  p)
def  many1  {a : Type}  (p : parserM a)  : parserM (List a) :=  ParserM  (many1_run  p)
```
`Monadic_parsing_auxiliary.lean` now imports `Monadic_parsing_lemMeasureProofs` and states the two obligations, e.g. `theorem many_run_measure_sufficient {a : Type} ( p : parserM a) ( cs : List (Char)) (lemHyp : (CerbParserProgress.Consumes p)) (lemFuel : Nat) (lemMeasureLe : (2 * List.length cs + 2) ≤ lemFuel) : many_run_lemFuel lemFuel p cs = many_run p cs := Monadic_parsing_lemMeasureProofs.many_run_measure_sufficient p cs lemHyp lemFuel lemMeasureLe`. The `_zero` lemmas are unchanged from D1. In `Formatted.lean` exactly seven heads lost `[LemFuel]` (D3's consumer note lists them). Lean build (`capped lake build CerberusLean cerberus-lean`, 19:22:36Z → 19:23:02Z): `Build completed successfully (394 jobs).`, `Built CerbParserProgress (170ms)`, `Built Monadic_parsing_lemMeasureProofs (260ms)`, `Built Monadic_parsing_auxiliary (158ms)`. Stamps: `check_driver_fresh: oracle OK (bin d918cba38d7520a4b3d793d5fee015bed388cb7425f41ddca532228e5e84e758, src 98ad48b592a222a21e4619c5ce03652fc6a44c0a67c6b02cb222e1d40b1c701d)` / `check_driver_fresh: lean OK (bin 5f6dfacf25852e7eedb386345ee641317eb03448688cd768974332962a2aa2ab, src 37ae035c0d262bd8c46e48ebd9aa757e0724ba11299825970f0aa631afcf5680)`.

### The registers

`scripts/fuel_hypotheses.txt` — two rows appended (TAB-separated; verbatim):
```
many_run_lemFuel	CerbParserProgress.Consumes p	every exec-path caller passes a parser that consumes >= 1 character on every success: formatted.lem:90 and :97 `many digit` (digit formatted.lem:83-85 = char #'0' <|> nonzero; nonzero :66-79 is a `sat`), :103 `many (char #'-' <|> char #'+' <|> char #' ' <|> char #'#' <|> char #'0')`, :170-171 `many ((many1 (sat (fun z -> z <> #'%')) >>= fun str -> return (F_text str)) <|> (conversionSpecification >>= fun cs -> return (F_conv cs)))` — the left alternative is many1 of a consuming sat, the right begins with char #'%' (conversionSpecification formatted.lem:152-153) followed by parsers that never lengthen the input; sat/char/item consume exactly one character on success (monadic_parsing.lem:39-43,65-74); `many p = ParserM (many_run p)` (monadic_parsing.lem:131) passes p through unchanged, so the wrapper's p IS the call site's parser; a non-consuming p makes the oracle recurse forever on the same input (record D1)	[AGENT worker 2026-09-15, parser-progress-measure (charter 2026-09-11)]; [USER] sign-off at merge
many1_run_lemFuel	CerbParserProgress.Consumes p	mutual sibling of many_run (one shared counter, measured all-or-none — lem FM-mutual): entered from many_run on the SAME input (monadic_parsing.lem:119-122) and directly through `many1 p = ParserM (many1_run p)` (monadic_parsing.lem:132) at formatted.lem:171 `many1 (sat (fun z -> z <> #'%'))` — a consuming sat (monadic_parsing.lem:65-68); same invariant and cites as the many_run row	[AGENT worker 2026-09-15, parser-progress-measure (charter 2026-09-11)]; [USER] sign-off at merge
```
(The `hyp=` text is exactly what the classifier prints — its `hyp` column below.) `scripts/fuel_forms_pending.txt` — the two data rows deleted; the parser block rewritten as CLOSED with this record cited; the file is HEADER-ONLY (`grep -v '^#' | grep -c .` = 0). Diff in `…-evidence/d2-registers-and-selftest-diffs.txt`.

### The gate accepts the EMPTY register; the selftest retargeted (charter §1's empty-register check; §0 item 2)

`policy`'s reads (`grep -v`/`awk`/`comm`/`grep -c` under `set -uo pipefail`, no `-e`) take an all-comment register as the empty set — observed: the unplanted gate is OK with `0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly`. The SELFTEST, however, named the pending workers: P2 removed `many_lemFuel`'s row from the TABLE (no such row exists now → no stale pin → the plant would fail), P6/P7 compiled decoy obligations `many_measure_sufficient : True` / `many1_measure_sufficient … many1 p = many1 p` (no fuel'd `many`/`many1` exist now → no MALFORMED row → the plants would fail). Retargeted, minimally, in `scripts/check_fuel_forms.sh` (diff in the evidence file): P2 plants a stale row for `many_run_lemFuel` — the worker that became MEASURED today — into a SCRATCH register (same rule, same direction, a REAL measured name; P5 remains the phantom-name twin); P6/P7 target two AMBIENT workers UNREACHABLE from the drive cone, `zeros_aux` (Core_aux) and `list_unfoldr_aux` (Utils), which have no obligation to duplicate (`FuelFormsPlantTrue.lean`: `import Core_aux` / `theorem zeros_aux_measure_sufficient : True := trivial`; `FuelFormsPlantWorker.lean`: `import Utils` / the wrapper-headed equation on `list_unfoldr_aux acc ctor1 b0`); the plant-table grep and labels follow; the comment records the history of retargetings. Nothing else in the gate changed. [AGENT] This is read as the charter's "empty-register fix, plant-tested" (the selftest IS the gate's plant test and runs in Tier A row 1); open question 1 asks the orchestrator to confirm the fence reading.

### D2 acceptance — observed (verbatim; full log `…-evidence/d2-gates.txt`)

```
check_fuel_forms: forms partition OK (62 MEASURED + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 12 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (…), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_fuel_forms: SELFTEST OK (24 plants with the declared label — 6 on the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: …)
  PLANT OK   [P2 stale pending pin (many_run_lemFuel is MEASURED, not reachable-ambient)] -> check_fuel_forms: FAIL — pending register row(s) no longer a reachable ambient worker (stale pin; edit the register):
    plant table: FUEL_FORM	list_unfoldr_aux_lemFuel	AMBIENT	no/-	MALFORMED obligation=list_unfoldr_aux_measure_sufficient: left-hand head `list_unfoldr_aux` is not the worker `list_unfoldr_aux_lemFuel`	
    plant table: FUEL_FORM	zeros_aux_lemFuel	AMBIENT	no/-	MALFORMED obligation=zeros_aux_measure_sufficient: conclusion is not an equation	
  PLANT OK   [P6 decoy obligation of type True (zeros_aux)] -> check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (…) — never MEASURED:
  PLANT OK   [P7 decoy obligation with the wrong worker constant (list_unfoldr_aux)] -> check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (…) — never MEASURED:
FUEL_FORM	many1_run_lemFuel	MEASURED	yes/-	obligation=many1_run_measure_sufficient axioms=ok proof=Monadic_parsing_lemMeasureProofs.many1_run_measure_sufficient:ok args=positional measure=syntactic	CerbParserProgress.Consumes p
FUEL_FORM	many_run_lemFuel	MEASURED	yes/-	obligation=many_run_measure_sufficient axioms=ok proof=Monadic_parsing_lemMeasureProofs.many_run_measure_sufficient:ok args=positional measure=syntactic	CerbParserProgress.Consumes p
FUEL_FORMS_SUMMARY	workers=81	measured=62	measured_under_hyp=12	absorbing=13	ambient_reachable=0	ambient_unreachable=6	closure_size=10499
check_theorem_axioms: FUEL arc leg OK (63 contract lemmas — generated _zero, runner leaves/parametricity, ∀-fuel exemplar, measured obligations, fail-stop propagation, and six-worker ND stability, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_no_fuel_numerals: OK (320 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
gen_fuel_parametricity: FAIL — pin(s) in TotalityProofTest.lean with no wrapper in the tree: many, many1
```
The partition is the charter's expected `62 (12 under a hypothesis) + 13 + 0 + 6 = 81`: the total is 81 with `many_lemFuel`/`many1_lemFuel` (2 ambient-reachable) replaced by `many_run_lemFuel`/`many1_run_lemFuel` (2 MEASURED under a hypothesis) — no other name moved. The two theorems' cones: `axioms=ok` = ⊆ {propext, Classical.choice, Quot.sound} for both the obligation and the proof constant (the gate's `axioms=ok` verdict; `check_theorem_axioms`' FUEL leg counts them among the 63 measured obligations). `check_no_fuel_numerals` F3 accepts the generated `_lemFuel (2 * List.length cs + 2)` (§0 item 6, observed). The parametricity check is red ONLY on the two stale pins (the "missing" direction is gone: `many_run`/`many1_run` are measured, not ambient) — cleared at D3.

### D2 — Tier A (tree frozen; key lines in `…-evidence/d2-tierA-verdicts.txt`)

```
$ CERB_MEM_MAX=48G python3 scripts/release.py --mode fast --lane-timeout 3300 --out .tmp/d2-fast      # → 19:29:43Z
FAILED A1 (…)  — the totality-proof-test exe build (stale pins :66-67), as at D1
PASSED A2 · A3 · A4 · A4b · A4c · A5 · A6 · A6b · A7 · A8 · A9 · A10 · A11
fast: failed; 13/14 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
```
Every lane's `SUMMARY` line is IDENTICAL to D0's (checked mechanically, lane by lane: A2 A3 A4 A4b A4c A5 A6 A6b A9 A11 "identical to D0"; A2/A3/A4/A4b each `Baseline check: 0 regression(s), 0 improvement(s)`; A7/A8 `100%`; A10 `GATE PASS … (16/16)`). This is the first point where the Lean binary's printf parsers changed SHAPE (fuel-free measured wrappers computing the parse at `2·|cs|+2`): the printf-heavy lanes A5 (libc, `match=12 diff=0`) and A10 (16/16 byte-identical) did not move.

### D2 — the fork-drift `[source-content]` row, second and FINAL move (same row, no new hunk)

The D2 declares changed `monadic_parsing.lem` again: `62445706…` (D1) → `da04e3c262a6e776e977bac03e820d17a3c54065009ae7bd255bfadb900b9524`; the row moved to the final value and the header note now reads `194dcdbc… -> da04e3c2… (62445706… at D1, before the D2 Lean-only fuel_measure declares)`. The `.ml` is byte-identical to D1, so the `[expected-semantic]` row is unchanged and layer 2 stays 24. Gate (verbatim): `check_fork_content: OK — 76 source files content/mode-pinned` / `check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 24 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)`.

**D2 acceptance [AGENT, observed]:** partition `62 MEASURED (12 under a hypothesis) + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81`; both `_measure_sufficient` theorems `axioms=ok` (obligation and proof); `check_theorem_axioms: OK`; selftest 24/24 with the empty register; Tier A green except the parametricity pins (D3). Committed as D2.
