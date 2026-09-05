# Concurrency Phase 0 — S6 record: merge readiness (2026-09-05)

Charter `2026-09-04_concurrency-phase0-sc-charter.md` §6 row S6 / §9
(APPROVED [USER 2026-09-04]); branch brief
`2026-09-04_concurrency-feature-branch-brief.md`. Author [AGENT]. This
record ENDS the slice and the branch's autonomous work: merge, audit
scope and push are the orchestrator's/operator's ([USER] working
practices: ff-only on explicit per-merge sign-off; the pre-merge audit
ASK is unconditional).

## 0. State

> **UPDATED by S7 (2026-09-05, after the pre-merge audit):** the branch is
> now rebased onto mainline `31eba718e` (not `928aa1e76`); the audit's two
> MAJOR findings are fixed (F1 file-scope races, F2 the `.lem` restatement
> reverted to the fuel route) and the corpus is 30 rows; the post-rebase
> FULL gate below is SUPERSEDED by the S7 record §4. §1–§3 remain valid
> with the S7 record's amendments (E1 = 30/30; using_concurrency kept in
> mainline's form; tray drafts 36–38).


- Branch `feature/concurrency`, REBASED onto mainline `928aa1e76`
  (fuel-parameter C3, 2026-09-05) with no conflicts (11 commits replayed;
  the five overlapping files — core_reduction.lem, lakefile.toml,
  handwritten_copy.manifest, TODO.md, VALIDATION.md — auto-merged; both
  sides' content verified present). Both trees regenerated on the new
  base with the installed lem d4ba548 (= the C3 Lake pin); oracle
  rebuilt; fork-drift OK at 24 pinned deltas; full `lake build` rc 0.
- Commits since the merge-base, in order: scoping note; branch brief;
  charter (PROPOSED, APPROVED); S0; S1 review request; S1 review response
  + acceptance; S1+S2; S3; S4; S5; this S6 docs commit.
- Documents for the merge: cumulative change manifest
  `2026-09-05_concurrency-phase0-change-manifest.md`; consumer note
  `2026-09-05_concurrency-phase0-consumer-note.md`; per-slice records
  S0/S1+S2/S3/S4/S5 with verbatim gate tails; per-slice manifests +
  generated diffs; tray drafts 36–38.

## 1. Exit criteria (charter §9), each with its evidence

| # | Criterion | Status | Evidence |
|---|---|---|---|
| E1 | litmus lane three-way at target, refusal rows included | MET (S4) | S4 record §3; re-confirmed S5 and §2 below |
| E2 | bridge check holds on every corpus trace; corrupt-rf plant trips | MET (S3) | S3 record §3; `sc-bridge-test` 5/5 every slice |
| E3 | sequential battery zero movement across all slices | MET | every record's battery table; §2 below after the rebase |
| E4 | totality incl. Cmm at 0 partials; axiom 0; sorry 0; opaque −`using_concurrency`; ND plants | MET (S5) | S5 record §5 (25 modules; 25 opaque rows) |
| E5 | DESIGN/VALIDATION/README model section, F_SC, §4.6 entry, DRF-SC citation; manifest + consumer note; tray draft | MET (S5/S6) | DESIGN §4; VALIDATION §2/§5; README; the two S6 documents; tray 36–38 |
| E6 | no `2>/dev/null`, no partial in the exec cone, no heartbeat/maxRecDepth bumps, no budget numerals, grind tripwire respected | MET | gates; longest pass any slice: the ~24-min gcc lane |

**One accepted obligation OUTSIDE §9 is NOT met:** the `Epar`-free
agreement lemma (consumer review Q4; our acceptance record Part B item 4
"S5 proof"). S5 record §4 (erratum) and the consumer note §3 state its
precise form and why the literal state-equality form became false at S3.
Decision requested from the operator: an S5b slice before merge, or merge
with the lemma carried as owed to the consumer. The branch is otherwise
mergeable; this is the only open item.

## 2. The post-rebase FULL gate

Chain `.tmp/chain10.sh` (serial; every lean run via `scripts/capped`,
`CERB_MEM_MAX=32G`; scratch deleted at slice end — this is its record),
launched 08:10:24 UTC after the rebase, regeneration and oracle rebuild.
Other agents loaded the box heavily during it (load 10 → 58 across Tier
B; 5 at the end).

**Tier A row 1 — `./scripts/test_unit.sh`**, rc 0, verbatim key lines
(the C3 numbers now show: 47 MEASURED / 15 pending, 34 hand-written files,
204 generated files):

```
✓ sc-bridge-test PASSED
Total: 7 passed, 0 failed
check_exec_totality: CLEAN (25 generated modules + hand-written CerbND, 0 allowlisted)
check_fuel_forms: OK (81 fuel'd workers: 47 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 15 reachable-AMBIENT = the 15 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_theorem_axioms: generated-tree census OK (204 files: 0 axioms, boundary-opaque population = the 25 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_sorry_token: OK (281 files scanned comment-stripped — generated 204, hand-written+test 42, LemLib 35; 0 sorry tokens)
check_handwritten_sync: OK (34 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_fork_drift: OK — layer 1: 72 oracle-surface files = manifest; layer 2: 24 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
### LANE A1-test_unit rc=0 | end 08:14:28
```

**Litmus lane**, verbatim:

```
SUMMARY: mode=before programs=24 engine_disagreements=0 baseline_mismatches=0 seq_leg_fail=0 red_classes=none
SUMMARY: mode=check programs=24 engine_disagreements=0 target_mismatches=0 seq_leg_fail=0 red_classes=none
plant (a) corrupted row 'coherence+init+sc_sc.c': mismatches=1 (want >=1)
plant (b) empty corpus: failures=25 (want >=1)
PLANTS TRIPPED (lane is not vacuous)
```

**The sequential battery**, per-lane start / load at start / rc and end:

| lane | start | load | rc / end |
|---|---|---|---|
| A1-test_unit | 08:10:22 | 14.29 | rc=0 08:14:28 |
| A2-exec-minimal | 08:17:33 | 13.50 | rc=0 08:17:47 |
| A3-exec-coverage | 08:17:47 | 13.66 | rc=0 08:18:13 |
| A4-exec-debug | 08:18:13 | 12.77 | rc=0 08:18:25 |
| A4b-exec-float | 08:18:25 | 11.42 | rc=0 08:18:35 |
| A4c-bytes | 08:18:35 | 10.59 | rc=0 08:18:38 |
| A5-libc_exec | 08:18:38 | 10.59 | rc=0 08:19:04 |
| A6-multi_tu | 08:19:04 | 9.74 | rc=0 08:19:06 |
| A7-parse-minimal | 08:19:06 | 9.60 | rc=0 08:19:16 |
| A8-core-minimal | 08:19:16 | 9.78 | rc=0 08:19:26 |
| A9-elab | 08:19:26 | 10.40 | rc=0 08:19:52 |
| A10-libxml2_uri | 08:19:52 | 19.84 | rc=0 08:20:20 |
| A11-cn_coverage | 08:20:20 | 34.55 | rc=0 08:21:39 |
| B1-libxml2 | 08:21:39 | 58.06 | rc=0 08:34:17 |
| B2-parse-ci | 08:34:17 | 34.66 | rc=0 08:35:09 |
| B3-core-ci | 08:35:09 | 50.39 | rc=0 08:35:46 |
| B4-verify | 08:35:46 | 53.38 | rc=0 08:36:52 |
| B5-immaculate | 08:36:52 | 43.05 | rc=0 08:38:33 |
| B6a-speclab-selftest | 08:38:33 | 55.59 | rc=0 08:41:00 |
| B6b-speclab-plant | 08:41:00 | 25.88 | rc=0 08:41:03 |
| B6-speclab-divmod | 08:41:03 | 25.88 | rc=0 08:41:14 |
| B6-speclab-bytearr | 08:41:14 | 21.10 | rc=0 08:41:25 |
| B6-speclab-list | 08:41:25 | 18.47 | rc=0 08:41:36 |
| B6-speclab-tree | 08:41:36 | 16.40 | rc=0 08:41:48 |
| B6-speclab-seed | 08:41:48 | 14.65 | rc=0 08:42:00 |
| B7-gcc_oracle | 08:42:00 | 13.05 | rc=1 09:05:56 |
| B8a-hang_plant | 09:05:56 | 11.13 | rc=0 09:06:09 |
| B8b-kill_plant | 09:06:09 | 10.03 | rc=0 09:09:47 |
| B8c-fuel_plant | 09:09:47 | 5.44 | rc=0 09:09:52 |

Verbatim tails: `SUMMARY: total=106 same=103 diff=3 ocaml_fail=0
lean_fail=0` (A9); `GATE PASS: all lane expectations pinned-green +
baseline unchanged (16/16)` (A10); `SUMMARY: total=4 match=4 fail=0
(points: 1354, 22 observations each)` (B1); `test_verify: 127 passed, 0
failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus
points)` (B4); `test_kill_plant: all plants read as expected …` (B8b);
`test_fuel_plant: ALL PLANTS OK …` (B8c).

**B7 (gcc second oracle) read rc 1 in the chain**, verbatim:

```
REGRESSION: csmith/sia_csmith_477.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-
Baseline check: 1 regression(s), 0 improvement(s)
### LANE B7-gcc_oracle rc=1 | end 09:05:56
```

The only movement is one row INTO `SKIP_LEAN_TIMEOUT` (`TIMEOUT_SECS=30`;
the box load was 13 at the lane's start and had been 43–58 through the
preceding Tier B lanes) — the LADDER row 7 load class ("re-run on a quiet
box before it is read as red; no code change"; the same class as the S3
record and the C3 boundary review). Re-run alone after the chain:

Re-run #1 (09:10–09:34, launched at load 5 — but other agents pushed the
box to 82 during it), verbatim:

```
SUMMARY: total=1963 compared=1883 agree=1871 agree_nd=0 triaged=12 disagree=0 o2_agree=189 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=13 skip_ub=47 …
REGRESSION: csmith/sa_csmith_231.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-
REGRESSION: csmith/sia_csmith_1008.c baseline=AGREE/O2_AGREE current=SKIP_LEAN_TIMEOUT/-
Baseline check: 2 regression(s), 0 improvement(s)
```

DIFFERENT rows than the chain's (`sia_csmith_477` was AGREE again; two
others timed out): the moving set is not stable across runs, which is the
signature of wall-clock noise, not of a semantic change. `disagree=0` in
both runs. The three rows by hand through the lane's exact commands
(`--cabs-json` → `cerberus-lean --batch --first`, `timeout 120s`), at load
14–25, verbatim:

```
sia_csmith_477.c   lean rc=0 22.38s  Defined {value: "Specified(132)"
sia_csmith_1008.c  lean rc=0 14.30s  Defined {value: "Specified(180)"
sa_csmith_231.c    lean rc=0 22.36s  Defined {value: "Specified(225)"
```

and against gcc (`-O0 -w`, `setarch -R`, `exec -a cmdname`, the lane's
native protocol):

```
sia_csmith_477 gcc_exit=132  lean=Specified(132)
sia_csmith_1008 gcc_exit=180  lean=Specified(180)
sa_csmith_231 gcc_exit=225  lean=Specified(225)
```

All three AGREE; their wall time (14–22 s under load, vs. the LADDER's
"slowest rows hand-time ~17 s on a quiet box") sits under the 30 s budget
with the margin the load consumes. Classification [AGENT]: LADDER row 7's
load class, no code change — the same reading the S3 record and the C3
boundary review made. Re-run #2 on the quiet box (launched 09:40:54 at
load 7.9):

```
### gcc re-run #2 start 09:40:54 load 7.90
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
rc=0 end 10:01:27 load 1.79
```

The SUMMARY line is IDENTICAL to the S4 record's (the pre-rebase baseline
state: `agree=1873 … skip_lean_timeout=11`). With it, every lane of the
post-rebase FULL gate is at rc 0: E3 (zero sequential movement) holds
over the rebase as well as over every slice.

## 3. Proposed pre-merge audit scope (the ASK; operator may trim or waive)

Range `928aa1e76..<head>`, 12 commits, every slice FULL-gated. Suggested
scope: (a) the .lem changes as a whole (`driver.lem`, `core_reduction.lem`,
`core_run_aux.lem`, `core_run.lem`, `cmm_csem.lem`, `cmm_op.lem`,
`global.lem`, `mini_pipeline.lem`) for mirror-OCaml discipline — every
divergence is deliberate and cited; (b) the fail-closed surfaces: the
entry scan and refusal set, `MI_spawn_after_scan`, the tail's verdict
order (races then bridge), the `compare_exchange` non-integer refusal;
(c) the S3 sb/asw tagging rules against C11 (unseq siblings, weak-seq
polarity, strong-seq positivization, join asw, procedure-entry) — the
axiomatic model is only as good as the recorded pre-execution; (d) the
fork-drift NOTEs (three re-pins + two joins) hunk-by-hunk; (e) the
scheduler collapse and `can_advance`'s runnable-count condition vs. the
consumer's §7 constraint. Scale: M (the .lem delta is ~1,100 lines
across the arc; the Lean hand-written delta is small: Main/CerbCall/
CerbGlobal/CerbStepInstances/FuelExemplar/SCBridgeTest/measure proofs).

## 4. After the merge (for the orchestrator)

- Announce the merge to refined-cerberus with the consumer note; their
  re-pin is theirs (staged: S1's token first).
- The container memory/pins: no lem-lean change in this arc; the Lake pin
  is C3's d4ba548 unchanged.
- Phase 1 (the C11 operational instance, deferred values) is undesigned
  by ruling; the forward option list is charter §3/§5 and DESIGN §4's
  boundary entry.

## 5. Provenance

[USER 2026-09-04]: the charter and D1–D6; [USER 2026-09-05]: "great,
continue" (S3–S4), "okay, can we go ahead?" (S5–S6). [AGENT]: everything
else; quoted outputs verbatim from this worktree.
