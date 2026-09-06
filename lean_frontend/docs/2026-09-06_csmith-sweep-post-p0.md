# csmith corpus sweep after the P0 instrument change (2026-09-05 → 06)

Orchestrator [AGENT] boundary record. Lane: `scripts/test_csmith_corpus.sh
--check-baseline --shard K/6`, K = 1..6, run serially after the 26-lane
battery in the detached script `.tmp/p0-reverify.sh` (ephemeral, deleted
with this record's commit), on the `arc/p0-instruments` worktree at
`8e5f198c5` — content-identical (patch byte-equal) to the merged
`aa5fc06c4..0a62dd7f7` on `mdd/cerberus-lean`. Operator ruling [USER
2026-09-05]: "let's land it as you propose, and keep the csmith gate
running in the background" — the slice landed on the green battery; this
sweep is the post-merge check the ruling asked for. Every quoted line
below is verbatim from the log; the battery script keeps each lane's last
six lines, so shard 2's SUMMARY line was cut off and is NOT recorded.

## Result

| shard | rc | verdict (verbatim) |
|---|---|---|
| 1/6 | 0 | `SUMMARY: total=279 match=127 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=1 hang=0 cerb_skip=151 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| 2/6 | **1** | `REGRESSION: sa_csmith_369.c baseline=MATCH current=TIMEOUT` / `REGRESSION: sa_csmith_371.c baseline=MATCH current=TIMEOUT` / `Baseline check: 2 regression(s), 0 improvement(s)` / `FAILED: regressions vs baseline` |
| 3/6 | 0 | `SUMMARY: total=279 match=144 … mismatch=0 … timeout=2 hang=0 cerb_skip=133 …` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| 4/6 | 0 | `SUMMARY: total=279 match=234 … mismatch=0 … timeout=0 hang=0 cerb_skip=45 …` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| 5/6 | 0 | `SUMMARY: total=279 match=268 … mismatch=0 … timeout=1 hang=0 cerb_skip=10 …` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| 6/6 | 0 | `SUMMARY: total=274 match=229 … mismatch=0 … timeout=2 hang=0 cerb_skip=43 …` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |

(`…` elides fields that are all `=0` — the full lines are `ub_match=0
ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0` and `cerb_floor=0
cerb_inconsistent=0` in every shard.) Derived: 1,669 files, `mismatch=0`
in all six shards — **the widened whole-line Defined comparison (P0 F3)
exposed NO output discrepancy on the csmith corpus**; the recorded
TIMEOUT/CERB_SKIP rows are unchanged except the two below.

## The two moved rows — class (b), NOT re-recorded

`sa_csmith_369.c` and `sa_csmith_371.c` (both `tests/csmith/small_arrays/`)
moved MATCH → TIMEOUT at the lane's `TIMEOUT_SECS=15`.

Re-run alone (this worktree, env.sh sourced, `SKIP_BUILD=1`, load ≈3.7):

```
[1/2] TIMEOUT sa_csmith_369 (Lean TIMEOUT(cpu 14.99s of 15.00s wall; timeout 15s))
[2/2] TIMEOUT sa_csmith_371 (Lean TIMEOUT(cpu 14.95s of 15.00s wall; timeout 15s))
```

— CPU-bound (the Lean process had the whole 15 s of CPU), so NOT the
load caveat. At `TIMEOUT_SECS=90` both MATCH the oracle on every
execution:

```
[1/2] MATCH sa_csmith_369: VAL:{value: "Specified(57)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(57)", …
[2/2] MATCH sa_csmith_371: VAL:{value: "Specified(165)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(165)", …
SUMMARY: total=2 match=2 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
```

Whole-harness wall (oracle + Lean + harness) at a 60 s limit: 28.84 s and
20.90 s. So: a per-row TIMING regression of the Lean binary against the
15 s budget, not a semantic discrepancy, and not the instrument (a
timeout is classified before any verdict is extracted).

Attribution is OPEN. Facts: (i) the lane's baseline dates from the
2026-08-22 arc-13 re-baseline; the records since show only `--shard 1/6`
spot checks (2026-09-01 s-basket, 2026-09-02 relsem-prune), so shard 2's
rows had not been re-run for two weeks — the slowdown can be anywhere in
that window; (ii) the fuel arc's eager measure computation on the layout
seams (`alignofCtype`/`sizeofCtype` …, C3 record §8.4 "~7% CPU on one
row", C4 record F-C4-4) is the leading hypothesis for `small_arrays`
rows, but the C4 boundary showed the gcc lane's csmith tier (30 s wall)
unmoved; (iii) the master plan's C-P1 ("Tier C timing: whole csmith lane
wall-clock at the merged head vs the pre-fuel head") is exactly the
measurement that settles it and has not been done.

Under VALIDATION.md §1 (zero-discrepancy rule, class (b) resource
direction: Lean failing where the oracle succeeds is never agreement and
never silently re-recorded), these two rows are REGISTERED PENDING with
the mover:

| row | status | mover |
|---|---|---|
| `sa_csmith_369.c` | MATCH@90s, TIMEOUT@15s (cpu-bound) | C-P1 timing: hand-time on the merged head vs a pre-fuel head (`928aa1e76` C3 or `753644005` C1); if the fuel measures are the cause → lem L8 cheaper measures / lazy scheme (trust-surface bar); else bisect the 2026-08-22..09-05 window |
| `sa_csmith_371.c` | same | same |

**Not done:** no baseline edit; no `TODO.md`/`LADDER.md` edit (the
mainline is held by another agent at the time of writing — the holder
should add these two rows to `TODO.md`'s pending list citing this record
when cherry-picking it). The other shards' pre-existing TIMEOUT rows
(1+2+0+1+2 = 6 derived from the SUMMARY lines shown; the baseline has 12
`TIMEOUT` rows in total, shard 2's count not captured) are the standing
class-(b) rows, unchanged.

## Housekeeping

`.tmp/p0-reverify.sh` + `.log` and the other stale `.tmp/*.sh` battery
scripts are deleted with this commit (ephemeral-only rule); the durable
evidence is this record's verbatim quotes. The `arc/p0-instruments`
worktree is removed; the branch stays (its four content commits are
merged as `aa5fc06c4..0a62dd7f7`; this record is the one unmerged commit —
cherry-pick it onto the mainline, then delete the branch).
