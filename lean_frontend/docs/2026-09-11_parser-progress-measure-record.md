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
