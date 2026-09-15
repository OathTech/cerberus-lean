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
