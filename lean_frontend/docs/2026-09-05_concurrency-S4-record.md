# Concurrency Phase 0 — slice S4 record: compare_exchange (2026-09-05)

Charter: `2026-09-04_concurrency-phase0-sc-charter.md` §6 row S4 (APPROVED
[USER 2026-09-04]). Branch `feature/concurrency` on mainline `a910f097c`.
Author [AGENT]. Gate: FULL. Consumer manifest addendum: §5 below (small).

## 0. What landed

`atomic_compare_exchange_{strong,weak}_explicit` execute on BOTH engines and
BOTH models. The C front end already elaborated them to Core
`CompareExchangeStrong/Weak` actions; the reduction refused them with
`error "TODO[Core_reduction]: …"` (upstream never executed them — the BMC
backend handled them symbolically). S4 adds, in the shared `.lem`:

- `core_reduction.lem` — `action_request2.CompareExchangeRequest2 strong
  ty obj expected desired mo_succ mo_fail (list aid → footprint →
  footprint → bool → 'a)`; `step_action` arms for both forms (operand
  evaluation mirrors the Store arm; the result is the C `_Bool` as the
  elaboration expects it, a `loaded integer` 0/1; dyn annotations carry
  both footprints); `wrap_tagged_many`: the continuation is tagged with
  EVERY action id the request produced.
- `driver.lem` — `perform_compare_exchange` (C11 7.17.7.4): ONE request =
  ONE scheduling point, so it is atomic w.r.t. other threads by
  construction: load *expected and *object (the object with its ATOMIC
  type — the elaboration passes the unatomic lvalue type and the memory
  model refuses a non-atomic-typed access to an atomic object, UB042;
  *expected with the plain type), compare (`Mem.eq_ival` — the memory
  model's provenance-insensitive integer equality; a non-integer object is
  a typed refusal `DErr_other`, Phase-0 scope; an unspecified value is
  `UB_unspecified_lvalue`), then store desired into *object (result 1) or
  *object into *expected (result 0). The WEAK form may fail spuriously:
  equal values branch (`ND.msum`) into success and failure — exhaustive
  mode explores both (the recovered upstream expectation `RMW-weak-equal =
  {0; 5}`). `action_request_sequential2` performs and records nothing;
  `action_request_sc2` records: the expected-load as a non-atomic `Load`;
  on success ONE atomic `RMW` (value read, value written) on the object; on
  failure an atomic `Load` (the failure order) then a non-atomic `Store`
  into *expected — sequenced in that order within the thread.
- `core_run_aux.lem` — `add_to_sb_ctx`: unseq siblings are sequenced after
  the action in the order the interpreter took (§1).

## 1. FINDING: `indeterminate_sequencing`, and why execution order is sb

The first CM_sc run of `RMW-strong-equal.c` failed the bridge check at
`well_formed_threads`; the dump showed `return x + 2*y + 4*s` — an ATOMIC
load of `x` unsequenced (Core `unseq`) with two non-atomic loads — with no
sb between them, and the model's conjunct `indeterminate_sequencing`
requires every atomic action to be sb-comparable with every other action
of its thread. That conjunct encodes C11: atomic operations are library
FUNCTION CALLS, and a call is indeterminately sequenced with the other
evaluations of the full expression (6.5.2.2p10) — sequenced in SOME
order, chosen by the execution. Cerberus's exhaustive mode runs every
order of the unseq, so recording the order taken as sb yields exactly the
C11-allowed sequencings. For two NON-atomic unsequenced evaluations this
orders what C11 leaves unsequenced; the only facts that touches are
intra-thread (the unsequenced-race class, which the Core dynamics detect
on their own — UB035 machinery — and which the SC bridge does not use);
hb across threads runs through atomics, which are ordered either way; the
data-race verdict is unaffected. The S3 rule "unseq siblings are NOT
tagged" (mirroring the working-era `add_to_sb_continuation`) was therefore
wrong for atomics — the working era never ran a program of this shape.
The S3 record's §2.3 rejection of the WHOLE-ARENA expression walker stands
(its defect was the weak-seq polarity filter, not sibling tagging); the
rule is now: the context walker, tagging siblings and continuations.

## 2. Measurements (verbatim, oracle; the lane confirms Lean identical)

Sequential model (both forms were internal errors before):

    RMW-strong-equal: {Specified(5)}   RMW-strong-unequal: {Specified(0)}
    RMW-weak-equal:   {Specified(0),Specified(5)}   RMW-weak-unequal: {Specified(0)}

SC model, the whole corpus (verdict SETS; `REFUSE` = the typed entry refusal):

    coherence+init+sc_sc.c: {Specified(1)}          coherence+sc_sc_sc.c: {Specified(1)}
    datarace+Rna+Rna.c: {Specified(0)}               datarace+Rna+Rna_Wna.c: {UB005_data_race}
    datarace+Rna+Wna.c: {UB005_data_race}            datarace+Wna_sc+sc_Rna.c: {Specified(1),UB005_data_race}
    datarace+Wna+Wna.c: {UB005_data_race}            fence+sc_sc.c: {REFUSE}
    hb-mo-cycle+…: {Specified(1),Specified(2),Specified(3)}
    IRIW+rel+…: {REFUSE}                             IRIW+sc+…: {0..15} \ {5}
    LB+acq_rel+…: {REFUSE}  LB+rlx_rlx+…: {REFUSE}   LB+sc_sc+sc_sc.c: {Specified(0),Specified(1),Specified(2)}
    MP+na+na.c: {UB005_data_race}                    MP+na_rel+acq_na.c: {REFUSE}
    MP+na_sc+sc_na.c: {Specified(1),Specified(2)}
    RMW-strong-equal.c: {Specified(5)}  RMW-strong-unequal.c: {Specified(0)}
    RMW-weak-equal.c: {Specified(0),Specified(5)}  RMW-weak-unequal.c: {Specified(0)}
    SB+rel_acq+…: {REFUSE}                           SB+sc_sc+sc_sc.c: {Specified(1),Specified(2),Specified(3)}
    WRC+sc+sc_sc+sc_sc.c: {Specified(0),Specified(1),Specified(4),Specified(5),Specified(7)}

Every row equals its `expectations.txt` target: charter exit criterion E1
on the oracle side; the litmus lane (§3) is the three-way statement.

## 3. Gates

The chain (`.tmp/chain8.sh`, serial, `CERB_MEM_MAX=32G`, every lean run
via `scripts/capped`; the scratch dir is deleted at slice end, this
section is its record): full `lake build` first (rc 0; the S4-touched
modules Core_run_aux → Core_run → Core_reduction → Driver → Main and the
executable rebuilt, 04:51:31–04:52:23), then:

**Tier A row 1 — `./scripts/test_unit.sh`**, rc 0, verbatim key lines:

```
check_fuel_forms: OK (81 fuel'd workers: 41 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 21 reachable-AMBIENT = the 21 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 510e1b1cd2e3f75c71550a634e66e3c81e02c7137c76c8b253c528db8662d90b, gen 498dfec0a6342252510ccb9507e20c92fffc3011b9118229d39381b94a8ed3a5)
check_lem_sync: lean OK (src 510e1b1cd2e3f75c71550a634e66e3c81e02c7137c76c8b253c528db8662d90b, gen f47d0fc72c5015912dbbebea7a8a025959ea9a5034e6f219582abdf453655c1b)
check_fork_drift: OK — layer 1: 72 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
### LANE A1-test_unit rc=0 | end 04:54:33
```

(The chain kept the last 40 lines of the row; the 7 per-exe PASSED lines
sit above the cut and rc=0 covers them. `sc-bridge-test` re-run alone,
verbatim: `5 passed, 0 failed`.) `perform_compare_exchange`,
`cmpxchg_values_equal`, `compare_exchange_action`, `wrap_tagged_many` are
plain `def`s: totality CLEAN at the same 22 modules, 0 `partial`.
Fork-drift: the three moved hashes re-pinned by hand with the S4 NOTE.

**Litmus lane**, verbatim:

```
### litmus --record-before (deliberate re-pin, S4)
recorded 24 rows to …/tests/litmus/before_baseline.txt
### litmus --check-before
SUMMARY: mode=before programs=24 engine_disagreements=0 baseline_mismatches=0 seq_leg_fail=0 red_classes=none
ALL ROWS AT baseline
rc=0
### litmus --check (target: E1)
[MATCH] SB+sc_sc+sc_sc.c (SC): {Specified(1),Specified(2),Specified(3)}
[MATCH] WRC+sc+sc_sc+sc_sc.c (SC): {Specified(0),Specified(1),Specified(4),Specified(5),Specified(7)}
SUMMARY: mode=check programs=24 engine_disagreements=0 target_mismatches=0 seq_leg_fail=0 red_classes=none
ALL ROWS AT target
rc=0
### litmus --plant
plant (a) corrupted row 'coherence+init+sc_sc.c': mismatches=1 (want >=1)
plant (b) empty corpus: failures=25 (want >=1)
PLANTS TRIPPED (lane is not vacuous)
rc=0
```

**Charter exit criterion E1 holds**: 24 of 24 rows at the Phase-0 target
on BOTH engines (oracle == Lean == `expectations.txt`), the SEQ leg
included; the pin `before_baseline.txt` moved on exactly the four `RMW-*`
rows and now equals the target. LADDER row 12 runs `--check`.

**The sequential battery (FULL gate):** Tier A rows 2–11 + Tier B rows
1–8, serial, 2026-09-05 04:54–05:40 UTC (box load 2–3 throughout — a
quiet box), verbatim per-lane return codes (the chain's per-lane header
line with the start time was consumed by the lane's own tail filter, so
the table carries end times):

| row | lane | end | rc |
|---|---|---|---|
| A2 | `test_exec minimal` | 04:59:51 | rc=0 |
| A3 | `test_exec coverage` | 05:00:17 | rc=0 |
| A4 | `test_exec debug` | 05:00:28 | rc=0 |
| A4b | `test_exec float` | 05:00:37 | rc=0 |
| A4c | `test_bytes` | 05:00:40 | rc=0 |
| A5 | `test_libc_exec` | 05:01:00 | rc=0 |
| A6 | `test_multi_tu` | 05:01:02 | rc=0 |
| A7 | `test_parse minimal` | 05:01:11 | rc=0 |
| A8 | `test_core minimal` | 05:01:20 | rc=0 |
| A9 | `test_elab` | 05:01:36 | rc=0 |
| A10 | `test_libxml2_uri` | 05:01:46 | rc=0 |
| A11 | `test_cn_coverage` | 05:02:15 | rc=0 |
| B1 | `test_libxml2` | 05:13:02 | rc=0 |
| B2 | `test_parse ci` | 05:13:25 | rc=0 |
| B3 | `test_core ci` | 05:13:40 | rc=0 |
| B4 | `test_verify` | 05:14:21 | rc=0 |
| B5 | `test_immaculate` | 05:15:14 | rc=0 |
| B6a | `speclab selftest` | 05:15:19 | rc=0 |
| B6b | `speclab plant` | 05:15:21 | rc=0 |
| B6 | `speclab divmod` | 05:15:32 | rc=0 |
| B6 | `speclab bytearr` | 05:15:43 | rc=0 |
| B6 | `speclab list` | 05:15:54 | rc=0 |
| B6 | `speclab tree` | 05:16:06 | rc=0 |
| B6 | `speclab seed` | 05:16:17 | rc=0 |
| B7 | `test_gcc_oracle` | 05:36:17 | rc=0 |
| B8a | `hang plant` | 05:36:31 | rc=0 |
| B8b | `kill plant` | 05:40:27 | rc=0 |
| B8c | `fuel plant` | 05:40:32 | rc=0 |

Every lane at rc 0 on the FIRST pass. Verbatim tails kept by the chain:

```
Baseline check: 0 regression(s), 0 improvement(s)          (A2, A3, A4, A4b — each followed by BASELINE OK)
SUMMARY: exec_match=9 neg_pinned=5 fail=0                   (A4c)
SUMMARY: match=11 diff=0                                    (A5)
SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0 (A9)
GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)   (A10)
SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)         (B1)
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)   (B4)
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK                                   (B7; its SUMMARY line sits one above the chain's 4-line cut)
```

ZERO movement on every sequential lane (charter E3 for this slice): no
sequential-lane program calls `atomic_compare_exchange_*` (such a row
would have been a matched internal-error verdict before S4), and the
walker change is the identity under `CM_sequential`.

## 4. Decisions in this slice ([AGENT], within the charter)

- Integer objects only for compare_exchange (typed refusal otherwise):
  C11's comparison is a representation comparison; for integers the
  memory model's `eq_ival` is that comparison; pointers/structs need the
  byte-representation route — Phase-0 scope, recorded in TODO.md.
- Fetch-style Core `RMW` actions stay refused: the C elaboration never
  emits them (translation.lem:674 "TODO: use atomic RMW if the type is
  atomic"); `Fence` stays refused (outside `SC_condition`; the sequential
  model's `TODO` is upstream's).
- The weak form's spurious failure is explored on BOTH models (C11 allows
  it regardless of concurrency; the sequential expectation is the upstream
  set `{0; 5}`).
- LADDER row 12 flips to `--check` (the target) now that every row meets
  it; `--check-before` stays available as the pin.

## 5. Consumer manifest addendum

`action_request2` gains the constructor `CompareExchangeRequest2` (8
components, the last a `List aid → footprint → footprint → Bool → α`
callback); no other generated signature changes. `add_to_sb_ctx`'s
`Cunseq` arm tags siblings (behaviour under `CM_sequential`: identity, as
before). New generated definitions in Driver.lean: `cmpxchg_values_equal`,
`perform_compare_exchange`. Sequential statements: unchanged (the exemplar
compiled with no edit).

## 6. Provenance

[USER 2026-09-04]: the charter; "great, continue" (2026-09-05). [AGENT]:
everything else; quoted blocks verbatim from this worktree.
