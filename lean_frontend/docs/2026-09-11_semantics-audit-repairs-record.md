# Semantics-audit repairs — record (2026-09-11)

Charter: [2026-09-11_codex-charter-semantics-audit-repairs.md](2026-09-11_codex-charter-semantics-audit-repairs.md).
Worktree: `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/semantics-audit-repairs`,
branch `arc/semantics-audit-repairs`, starting HEAD `40bb7fe7767f46ac9dc9cb6ea7f330b3eb9aa159`
(the charter commit, on mainline `54f007187`), `git status --porcelain` empty at start.
Worker: Claude (Fable 5.1) [AGENT]; the operator cannot be asked during the run — anything
unresolved is written here as an open question. Every command ran from the worktree with
`source /home/dev/projects/cerberus-lean-proj/scripts/env.sh`; every lake/lean invocation
went through `scripts/capped` with `CERB_MEM_MAX=48G`; `DUNE_CACHE=disabled` for the
gate runs; one heavy job at a time. Quoted outputs are verbatim; derived tallies are
labelled derived; judgments are [AGENT].

Evidence directory: `2026-09-11_semantics-audit-repairs-evidence/` (plain text).

## 0. Reading-list verification — where the tree and the charter differ

[AGENT] Every §1 fact touched was re-read in the tree before use. Two immaterial
differences (recorded, not stop events — neither changes a deliverable's meaning):

1. **Failure-reach register.** Charter §1 says `CerbFloat.truncToInt` AND
   `CerbFloat.of_string`'s malformed-input `panic!` have rows in
   `scripts/failure_reach_register.txt`. The tree has ONE `CerbFloat` row (`:71`,
   `CerbFloat.truncToInt`); `of_string`'s `panic!` has no row (the census's exec
   closure evidently does not reach it — `of_string` is reached from
   `CerbMem.strFval` ← `Mem.str_fval` ← `translation.lem:209`, front-end side, and
   from `CoreParser.lexNumLit`). Consequence: D1's rewrite is gated by
   `check_failure_reach.sh` as the charter says; whether a row appears is what the
   gate reports, not a prediction.
2. **Exec-path mirror target for finding 4.** Charter §1 names `Cerb_floating.of_string`
   (`util/cerb_floating.ml:8-16`, strips one trailing `f`, then `float_of_string`).
   The tree: the CONCRETE model's `str_fval` — the exec-path target, `mem.lem:361-367`
   `declare ocaml target_rep function str_fval = \`Impl_mem.str_fval\`` /
   `declare lean target_rep function str_fval = \`CerbMem.strFval\`` — is
   `memory/concrete/impl_mem.ml:2523-2524` `let str_fval str = float_of_string str`
   (no suffix strip). `Cerb_floating.of_string` is the target of the lem-level
   `Float.of_string` (`frontend/model/float.lem:82`), used by the defacto model
   (`defacto_memory.lem:1268-1269`), outside the concrete exec cone. Both reach the same
   C routine `caml_float_of_string` (`runtime/floats.c`); the only difference is the
   suffix strip, and the C lexer separates the suffix into `suffix_opt`
   (`cabs_json.ml:93-94` `json_of_cabs_floating_constant (s, suffix_opt)`), so no
   suffix reaches either. The D1 goal's "with or without one trailing f/F/l/L" is kept
   as the charter fixes it.
3. **`caml_float_of_hex` rounding.** Charter §1 describes it as "a 64-bit accumulator with
   round-to-odd on excess digits followed by one conversion, i.e. a correctly rounded
   result". The tree (`_opam/.opam-switch/sources/ocaml-compiler.5.4.0/runtime/floats.c:355`
   and `:369`) is `f = (double) (int64_t) m;` followed by `if (exp != 0) f = ldexp(f, exp);`
   — TWO roundings when the result is subnormal (the int64→double conversion rounds the
   ≤60-bit mantissa to 53 bits; `ldexp` then rounds again to the subnormal's shorter
   precision). For NORMAL results `ldexp` is exact and the result is correctly rounded.
   [AGENT] This is a prediction from source reading; the charter's D1 stop rule ("the fork
   oracle disagrees with correct rounding on a D1 battery row") is the mechanism that
   observes it. D1's battery includes the subnormal shapes the charter lists; a long-mantissa
   subnormal (the double-rounding shape) is included as an adversarial row so the question
   is OBSERVED, not left as a reading (see §2).
4. **`CabsImport.lean` already contains `partial def`s** (`jsonToExpression` etc., pre-existing,
   `:286-`). Charter §3 forbids `partial def` "in changed modules"; reading [AGENT]: the
   rule forbids INTRODUCING them (the same sentence treats the pre-existing `Float` externs
   as "the boundary, not a licence for new ones"). D2 adds none.
5. **Lean name of the compatibility entry.** lem emits the reader-lifted wrapper as
   `Ctype_aux.are_compatible0` (`generated/Ctype_aux.lean:119`; the `0` suffix is the
   backend's disambiguation), not `are_compatible`. D3(a)'s unit test names it so.

## D0 — Snapshot

[AGENT] Tier A was run TWICE before any change. The first run (`.tmp/d0-fast`, started
2026-09-11T23:32:38Z) had every lane PASSED but ended `Source unchanged: False` /
`rc=1`: I had written this record's skeleton and the evidence directory into the tree
WHILE it ran, and the runner counts that as a changed source. My error, not the tree's;
the run is discarded as a certification. The second run, with the tree untouched
throughout, is the baseline:

```
$ CERB_MEM_MAX=48G DUNE_CACHE=disabled python3 scripts/release.py --mode fast --lane-timeout 3300 --out .tmp/d0-fast2
Release evidence: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/semantics-audit-repairs/.tmp/d0-fast2
RUN A1: ./scripts/test_unit.sh
PASSED A1 (147.7s)
RUN A2: ./scripts/test_exec.sh --check-baseline
PASSED A2 (27.6s)
RUN A3: ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
PASSED A3 (52.1s)
RUN A4: ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
PASSED A4 (23.0s)
RUN A4b: ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
PASSED A4b (18.4s)
RUN A4c: ./scripts/test_bytes.sh
PASSED A4c (3.1s)
RUN A5: ./scripts/test_libc_exec.sh
PASSED A5 (23.2s)
RUN A6: ./scripts/test_multi_tu.sh
PASSED A6 (2.2s)
RUN A7: ./scripts/test_parse.sh
PASSED A7 (9.6s)
RUN A8: ./scripts/test_core.sh
PASSED A8 (8.3s)
RUN A9: ./scripts/test_elab.sh
PASSED A9 (16.1s)
RUN A10: ./scripts/test_libxml2_uri.sh
PASSED A10 (17.0s)
RUN A11: ./scripts/test_cn_coverage.sh --check-baseline
PASSED A11 (57.9s)
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
rc=0
```

A1's gate lines and every lane's verdict line: `2026-09-11_semantics-audit-repairs-evidence/d0-tierA-verdicts.txt`. The
lines this slice must hold fixed (verbatim, from that run):

```
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
gen_fuel_parametricity: OK (16 ambient fuel wrappers in the generated tree = the 16 pins of TotalityProofTest.lean Part 1, both directions)
Total: 7 passed, 0 failed
A2: Baseline check: 0 regression(s), 0 improvement(s)
A3: Baseline check: 0 regression(s), 0 improvement(s)
A4: Baseline check: 0 regression(s), 0 improvement(s)
A4b: Baseline check: 0 regression(s), 0 improvement(s)
A5: SUMMARY: match=12 diff=0
A6: SUMMARY: total=2 match=2 fail=0
A7: batch diagnostic producers: 8/8 passed
A11: BASELINE OK (213 entries, exact match)…
```

Direct `./scripts/test_unit.sh`: `rc=0`, `Total: 7 passed, 0 failed`; its gate lines are in
`2026-09-11_semantics-audit-repairs-evidence/d0-test-unit-verdicts.txt` (same partition / fork-drift / failure-reach lines
as above).

Pristine upstream oracle, built once from the worktree root with the charter's command
(`scripts/ce python3 scripts/build_independent_oracle.py --lem-repo …/lem-lean
--cerberus-repo …/cerberus-lean --out .validation-foundations/independent-oracle-v2`):
`cerberus-generation: passed (19.368s)`, `cerberus-build: passed (12.602s)`, `rc=0`;
manifest `sources.cerberus.commit = b9aeedcb4dd438763b0eef7f95ac19e93875d7de`;
`artifacts.oracle.path = .validation-foundations/independent-oracle-v2/cerberus/_build/default/backend/driver/main.exe`,
`artifacts.runtime.root = …/independent-oracle-v2/cerberus/_build/install/default`
(the "pristine" engine in every three-engine table below).

D2's regression reference: `2026-09-11_semantics-audit-repairs-evidence/cabs-json-before.sha256` — the sha256 of the
`--cabs-json` stdout of every `tests/minimal/*.c` present at D0 (106 rows; none is the
empty-output hash).
