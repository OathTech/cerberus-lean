# Concurrency Phase 0 — slice S7 record: pre-merge audit fixes + rebase (2026-09-05)

Audit: branch `audit/concurrency-premerge`,
`lean_frontend/docs/2026-09-05_concurrency-premerge-audit.md` (verdict
MERGE-WITH-FIXES; F1, F2 MAJOR; M1–M7; N1–N8). Orchestrator relay [USER
2026-09-05], verbatim: "rebase feature/concurrency onto 31eba718e … Two
fixes before it returns through me: the file-scope data-race bug (F1) with
file-scope litmus rows, and reverting the .lem restatement (F2) to the fuel
route, per your ruling that lem edits are against the rules." Also
(earlier relay, same day): the three rebase conflicts "all from their S5
deleting using_concurrency while mainline made it a plain def; keep
mainline's form". Author [AGENT]. Gate: FULL. This record doubles as the
audit RESPONSE (§3).

## 0. Rebase onto `31eba718e`

Two hops (the mainline moved twice while the audit ran): `928aa1e76` →
`eb27fa70f` (cerbglobal-defs), then → `31eba718e` (zero-discrepancy Z3/Z4,
typed-failure R1). Conflicts and their resolution, each per the relay:

| commit replayed | file | resolution |
|---|---|---|
| S5 | `lean_frontend/CerbGlobal.lean` | mainline's (eleven plain `def`s incl. `using_concurrency := conf.concurrency` and `using_concurrency_eq … := rfl`) |
| S5 | `scripts/check_theorem_axioms.sh` | mainline's (`OPAQUE_WANT` has no CerbGlobal rows) |
| S5 | `scripts/unsafebaseio_allowlist.txt` | mainline's (no CerbGlobal pins) |
| S1+S2, S5 | `lean_frontend/VALIDATION.md` | mainline's — Z4 REWROTE the document (§0–§9); the branch's passages are re-fitted to the new structure in this slice (§1.4) |

Consistently with "keep mainline's form", `frontend/model/global.lem` is
mainline's too (the S5 deletion of the `using_concurrency` val is
reverted; the def has no reader on any target and is a one-line follow-up
if wanted; the `lem_global.ml` fork-drift join disappears — 24 → 23 pinned
deltas). Tray drafts renumbered 20–22 → 36–38: the mainline's Z4 landed
drafts 20–35 the same day (INDEX entries and cross-references updated).

## 1. The fixes

### 1.1 F1 — file-scope objects read `UB005` under `CM_sc`

Reproduced first (oracle, the audit's `p8a`/`p8d`/`p8e` shapes as new
corpus rows): every file-scope program was `UB005_data_race` — the
globals-initialisation stores ran on thread 0 in `driver_globals` with
their own arenas and carried no `sb`/`asw` edge to anything, so
`data_races` paired each with every thread's access to that object.

Fix (`driver.lem`, two sites): (i) in `drive`, main's body is tagged
`add_to_sb model {(Pos, (tid0, aid)) | aid ∈ recorded actions}` before it
is installed — every action of main (and, through the spawn node's
`sb_before`, every child's first action via `asw_from_parent`) is
sequenced after every initialisation action; (ii) in `driver_globals`,
each initialiser's arena is tagged the same way with the actions recorded
before it — the initialisers form ONE `sb` chain on thread 0. Site (ii)
was found by the corpus, not the audit: with (i) alone the two ATOMIC
file-scope rows failed the bridge at `well_formed_threads`, verbatim:

```
== SB+sc_sc+sc_sc+globals: 20 Error {msg: "model inconsistent: the SC run's candidate execution fails the SC consistency predicate at leaf well_formed_threads"}
(debug 2): SC-RECORD aid 1 tid 0 sb_before {(0, 0)} asw_before {}
(debug 2): SC-RECORD aid 3 tid 0 sb_before {(0, 2)} asw_before {}
  sb: trancl of {(1, 6); (3, 6); (6, 7); (7, 14); …}
```

— `indeterminate_sequencing` (cmm_csem.lem:1020) requires two same-thread
actions not both at non-atomic locations to be `sb`-related, and the two
initialisation stores of `x` and `y` (aids 1, 3, both thread 0, atomic
locations) were not. C11 6.2.4p3 / 5.1.2p1: static initialisation is
sequenced before program startup; the chain is the model of that. Under
`CM_sequential` both sites are the identity (`add_to_sb`'s first `match
model`; nothing is recorded).

After the fix, oracle (`--concurrency=sc --mode=exhaustive`), verbatim
outcome multiplicities:

```
== SB+sc_sc+sc_sc+globals:   4 Specified(1);  4 Specified(2);  12 Specified(3);   (= the block-scope row SB+sc_sc+sc_sc, identical multiplicities)
== MP+na_sc+sc_na+globals:   1 Specified(1); 14 Specified(2);
== globals+init+Wna_Wna:     2 Specified(3);                                     (the audit's p8a)
== globals+init+Rna_Rna:     6 Specified(10);                                    (the audit's p8d)
== datarace+Wna+Wna+globals: 2 UB005_data_race;
== fence+sc+sc_sc:           1 model refused: fence (Seq_cst) is outside the SC fragment;   (M6)
```

Corpus: six rows added (`tests/litmus/`: `SB+sc_sc+sc_sc+globals.c`,
`MP+na_sc+sc_na+globals.c`, `datarace+Wna+Wna+globals.c`,
`globals+init+Wna_Wna.c`, `globals+init+Rna_Rna.c`, `fence+sc+sc_sc.c`),
their `sc_reference.py` transcripts (the reference model's `vars` initial
values ARE static initialisation; `sc_reference.py --check`: every row
equals its derived set), `expectations.txt` rows, `before_baseline.txt`
re-recorded (a deliberate move: +6 rows, no existing row moves). The
bridge check is NOT a race-freedom oracle (an isolated write is a
consistent execution) — stated now in DESIGN §4 and VALIDATION §9.

### 1.2 F2 — the `.lem` restatement reverted; the fuel route

`apply_tree` / `apply_tree_fp_aux` bodies are upstream's text again
(`List.all (fun (name, branch) -> apply_tree branch X) l`; the OCaml diff
of `cmm_csem.ml` against upstream is back to the S5 comment-only hash
`9510383409f3…`). Totality on the Lean target by the charter §4.7 fuel
route: `declare {lean} fuel val apply_tree = `fuelExhausted false`` +
`declare {lean} fuel_measure val apply_tree = `lemSize pred_tree`` (and the
`_fp` pair), the generated obligations `apply_tree_measure_sufficient` /
`apply_tree_fp_aux_measure_sufficient` proved in the new hand-written
`lean_frontend/Cmm_csem_lemMeasureProofs.lean` (C1/C2 template: strong
induction on the size bound; the recursive call under `List.all` through
the destructuring lambda closed by `lall_congr` + a member bound
`tree_mem_lt`; kernel-only tactics). Cmm modules stay in the totality
slice at 0 partials; `check_fuel_forms` counts two more MEASURED workers
(§4).

### 1.3 The MINOR findings

| # | disposition |
|---|---|
| M1 | consumer note §3, S5 record §4, TODO: the agreement statement carries BOTH premises (`epar_free` AND `sc_fragment_ok`) |
| M2 | cumulative manifest §1: the sentence corrected — `driver2`/`process_core_step2`/`drive_nonmemory_steps_aux2` DO take the model (as the S1 manifest §1 says) |
| M3 | VALIDATION §3 "Still open" carries the mixed-size-overlap quiet answer with owner Phase 1 |
| M4 | NOT done (a `.lem` type change to `model_refusal`/`model_inconsistency` for the compare_exchange non-integer kill; today `DErr_other` strings, unreachable from the corpus) — recorded in TODO for the operator |
| M5 | tray draft 38 names the compare_exchange reduction rules (a sequential-visible oracle change) |
| M6 | corpus row `fence+sc+sc_sc.c` exercises the scan's fence arm alone (target REFUSE) |
| M7 | the three `.lem` comments and the S3 record cite `core_run.lem:272-284` and `:936/:1007` (0df8708ad^) — comment-only; hashes re-pinned |
| N2 | `Cerb_global.concurrency_mode` stays set by `main.ml` (mirror-OCaml; dead reader) — noted in TODO |
| N3 | the zero-discrepancy census (2026-09-03) rows Z-24/Z-25 carry a dated STATUS line ("LANDED") |
| N1, N4–N8 | acknowledged; N7 (`multi_threaded` = threads EXIST) stands as recorded |

### 1.4 Docs re-fitted to the mainline

VALIDATION.md (Z4's structure): §3 (c) *Concurrency* bullet rewritten
(the parameter, the instance, the refusals, the lane), `--concurrency=sc`
in the accepted command line, the boundary sentence, §5 the litmus row
(30/30), §9 claim 5, §3 "Still open" M3. DESIGN §4: `using_concurrency`
sentence, the bridge-not-a-race-oracle note, 30 programs. README, LADDER
row 12: 30. Litmus README: the file-scope convention, the fence row, the
S7 pin move. The S5 record: ERRATUM 2 (§0). Cumulative manifest and
consumer note: the rows above.

## 2. Measurements of the exit criteria after S7

E1: 30/30 rows (six new) three-way. E2: the bridge check holds on every
race-free trace of the 30 rows (the two atomic file-scope rows are its
witnesses that the chain fix is needed AND sufficient). E3: the battery
below. E4: totality at 0 partials incl. Cmm; `check_fuel_forms` +2
MEASURED. E5/E6: as S6, plus the re-fitted docs.

## 3. Audit response, in one paragraph

F1 accepted and fixed at both sites (§1.1) with the corpus rows the audit
asked for; F2 resolved by the operator's ruling — reverted to upstream's
bodies, fuel route (§1.2); M1–M3, M5–M7, N3 done; M4 and N2 recorded, not
done (§1.3); N1 agreed (the charter governs the `.lem` scope). The
auditor's §9 rebase preview was right about the three conflict files; the
resolution follows the orchestrator's later instruction (mainline's form,
`using_concurrency` NOT deleted) rather than the preview's suggestion.

## 4. Gates

Chain `.tmp/chain11.sh` (serial; every lean run via `scripts/capped`,
`CERB_MEM_MAX=32G`; scratch deleted at slice end — this is its record),
launched 15:59:29 UTC on the rebased tree with both fixes, after the
litmus lane had been re-recorded (`--record-before`, 30 rows) and checked.

**Tier A row 1 — `./scripts/test_unit.sh`**: the chain's run read rc 1 —
`fuel-exemplar-test`'s compile was killed by the 32 GiB cap, verbatim:

```
=== fuel-exemplar-test ===
capped: OOM event recorded in cgroup (memory.events oom_kill=1, cap CERB_MEM_MAX=32G) though the command exited rc=1 — a descendant was killed by the cap; NOT a clean pass
```

Cause (a finding of this slice): `drive_after_setup` steps `drive`'s setup
binds one at a time by `rfl`; the F1 site adds a read bind and
`add_to_sb CM_sequential ∅ mainBody` on the CONCRETE exemplar body, and
the `rfl` unfolded the fuel'd walker on it (the S3-era OOM shape, the
file's own rule "symbolic steps only"). Fix: one more `runOne_bind_active
… rfl` step for the read, then `rw [add_to_sb_sequential]` — the identity
lemma, moved from the test into the library module
`Core_run_aux_lemMeasureProofs.lean` so library-side proofs can use it
(the test re-states the six as examples). The exemplar's three theorems
are unchanged in statement. Re-run alone after the chain (16:50:35, load
3.6), rc 0, verbatim key lines:

```
Total: 7 passed, 0 failed
check_exec_totality: CLEAN (25 generated modules + hand-written CerbND, 0 allowlisted)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
check_fork_drift: OK — layer 1: 72 oracle-surface files = manifest; layer 2: 23 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fuel_forms: OK (83 fuel'd workers: 49 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 15 reachable-AMBIENT = the 15 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_handwritten_sync: OK (35 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_sorry_token: OK (283 files scanned comment-stripped — generated 205, hand-written+test 43, LemLib 35; 0 sorry tokens)
check_theorem_axioms: FUEL arc leg OK (34 contract lemmas — 9 generated _zero + the CerbND runner leaves/parametricity pins + the ∀-fuel exemplar and its instances + the 3 fuel_measure sufficiency obligations (generated statement + hand-written proof), every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: generated-tree census OK (205 files: 0 axioms, boundary-opaque population = the 15 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
✓ core-parser-test PASSED
✓ effects-proof-test PASSED
✓ fresh-int-test PASSED
✓ fuel-exemplar-test PASSED
✓ pp-test PASSED
✓ sc-bridge-test PASSED
✓ totality-proof-test PASSED
### A1 re-run rc=0 end 16:52:35
```

(`check_fuel_forms` now counts 49 MEASURED: the two `apply_tree`
obligations of F2 join the 47 of C3; the boundary-opaque population is the
mainline's after cerbglobal-defs (15 rows); 35 hand-written files = 34 + the new
proof module.)

**Litmus lane** (pre-chain re-record + the chain's legs), verbatim:

```
recorded 30 rows to …/tests/litmus/before_baseline.txt
SUMMARY: mode=before programs=30 engine_disagreements=0 baseline_mismatches=0 seq_leg_fail=0 red_classes=none
ALL ROWS AT baseline
SUMMARY: mode=check programs=30 engine_disagreements=0 target_mismatches=0 seq_leg_fail=0 red_classes=none
ALL ROWS AT target
plant (a) corrupted row 'coherence+init+sc_sc.c': mismatches=1 (want >=1)
plant (b) empty corpus: failures=31 (want >=1)
PLANTS TRIPPED (lane is not vacuous)
```

Six [MATCH] lines for the new rows (`--check`, pre-chain run):
`datarace+Wna+Wna+globals.c (SC): {UB005_data_race}`, `fence+sc+sc_sc.c
(NONSC): REFUSE ("model refused: fence (Seq_cst) is outside the SC
fragment")`, `globals+init+Rna_Rna.c (SC): {Specified(10)}`,
`globals+init+Wna_Wna.c (SC): {Specified(3)}`, `MP+na_sc+sc_na+globals.c
(SC): {Specified(1),Specified(2)}`, `SB+sc_sc+sc_sc+globals.c (SC):
{Specified(1),Specified(2),Specified(3)}` — E1 at 30/30 on BOTH engines.

**The sequential battery**, per-lane start / load / rc and end:

| lane | start | load | rc / end |
|---|---|---|---|
| A1-test_unit | 15:59:28 | 2.25 | rc=1 16:02:27 |
| A2-exec-minimal | 16:05:13 | 1.23 | rc=0 16:05:26 |
| A3-exec-coverage | 16:05:26 | 1.32 | rc=0 16:05:50 |
| A4-exec-debug | 16:05:50 | 1.36 | rc=0 16:06:02 |
| A4b-exec-float | 16:06:02 | 1.30 | rc=0 16:06:11 |
| A4c-bytes | 16:06:11 | 1.41 | rc=0 16:06:13 |
| A5-libc_exec | 16:06:13 | 1.41 | rc=0 16:06:35 |
| A6-multi_tu | 16:06:35 | 1.33 | rc=0 16:06:36 |
| A7-parse-minimal | 16:06:36 | 1.33 | rc=0 16:06:46 |
| A8-core-minimal | 16:06:46 | 1.35 | rc=0 16:06:54 |
| A9-elab | 16:06:54 | 1.30 | rc=0 16:07:10 |
| A10-libxml2_uri | 16:07:10 | 1.54 | rc=0 16:07:22 |
| A11-cn_coverage | 16:07:22 | 1.76 | rc=0 16:07:52 |
| B1-libxml2 | 16:07:52 | 2.10 | rc=0 16:18:57 |
| B2-parse-ci | 16:18:57 | 2.56 | rc=0 16:19:20 |
| B3-core-ci | 16:19:20 | 2.36 | rc=0 16:19:35 |
| B4-verify | 16:19:35 | 2.35 | rc=0 16:20:16 |
| B5-immaculate | 16:20:16 | 2.24 | rc=0 16:21:17 |
| B6a-speclab-selftest | 16:21:17 | 1.94 | rc=0 16:22:50 |
| B6b-speclab-plant | 16:22:50 | 2.48 | rc=0 16:22:52 |
| B6-speclab-divmod | 16:22:52 | 2.48 | rc=0 16:23:02 |
| B6-speclab-bytearr | 16:23:02 | 2.33 | rc=0 16:23:12 |
| B6-speclab-list | 16:23:12 | 2.12 | rc=0 16:23:23 |
| B6-speclab-tree | 16:23:23 | 1.95 | rc=0 16:23:34 |
| B6-speclab-seed | 16:23:34 | 1.80 | rc=0 16:23:44 |
| B7-gcc_oracle | 16:23:44 | 1.68 | rc=1 16:46:25 |
| B8a-hang_plant | 16:46:25 | 1.36 | rc=0 16:46:38 |
| B8b-kill_plant | 16:46:38 | 1.66 | rc=0 16:50:21 |
| B8c-fuel_plant | 16:50:21 | 3.64 | rc=0 16:50:27 |

Every lane rc 0 except B7 (gcc second oracle), which read rc 1 under a
load of 47–52 from other agents, verbatim:

```
REGRESSION: csmith/sa_csmith_231.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-
Baseline check: 1 regression(s), 0 improvement(s)
```

— the one row into `SKIP_LEAN_TIMEOUT` is the LADDER row 7 load class
(the same row moved in the S6 record's loaded re-run and agreed with gcc
by hand there: exit 225 = `Specified(225)`). Re-run alone on the quiet box
(16:52:35, load 2.7):

```
### gcc re-run start 16:52:35 load 2.72
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
### gcc re-run rc=0 end 17:13:14 load 5.07
```

The SUMMARY line is identical to the S4/S6 records' (`agree=1873 …
skip_lean_timeout=11`). With the A1 and B7 re-runs, every lane of the FULL
gate is at rc 0 on the rebased tree with both fixes: E3 (zero sequential
movement) holds over the rebase onto `31eba718e` and over F1/F2 — as it
must: both F1 sites are the identity under `CM_sequential`, and F2 is a
Lean-target totalization with upstream's `.lem` text.

## 5. Provenance

[USER 2026-09-05]: the orchestrator relays quoted in the header; "lem edits
are against the rules". [AGENT]: the fixes, the corpus rows, the docs;
quoted outputs verbatim from this worktree.
