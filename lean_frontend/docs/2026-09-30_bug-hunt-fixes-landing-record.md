# Bug-hunt fix range — gate record before landing (2026-09-30)

Range: `mdd/cerberus-lean` `4198f9194` → `arc/bug-hunt-fixes`. Author: the orchestrator [AGENT]. Pre-merge audit:
`docs/2026-09-30_bug-hunt-fixes-pre-merge-audit.md` (MERGEABLE WITH FIXES; all findings fixed in `ac819eea9`).

## Full ladder on `1f72155d2` (the audited head, clean tree), 2026-09-30T01:12:29Z–03:15:23Z — verbatim

```
full: passed; 40/40 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
=== RELEASE EXIT=0 2026-09-30T03:15:23Z load=6.37 6.28 8.23 ===
```

Incident: an SC-track subagent sent SIGTERM (`kill`) to this run's processes (PIDs 1575305/1575307/1575349, the
command writing `.tmp/fixes-full.log`) at about 02:45Z while cleaning up its own processes. Per the SC session's
corrected report, the worker's `ps` 3 s later still showed all three alive; its first report ("terminated", a
different run) was an inference it later withdrew. This run's own evidence shows no interruption: `report.json`
`status = passed`, no `interrupted` marker, 40 PASSED lines, and release.py's per-lane exit-code checks all passed.
[AGENT] judgement: the evidence stands; no re-run.

## Tier A + row 1 on the audit fixes (`ac819eea9`'s tree), 12/12 exit 0 — verbatim excerpts

```
Total: 16 passed, 0 failed
check_cli_refusals: OK (3 refused flags pinned: --concurrency, --switches=PNVI_ae_udi, --switches=strict_pointer_arith; 2 repeated options refused: --runtime, --args; control not refused)
check_libc_float_literals: SELFTEST OK (8 plants: unplanted OK; added, dropped, relabelled-lossy, empty dump, malformed register, second copy on a registered line, duplicated register row all FAIL)
check_libc_float_literals: OK (24 float literals in tests/libc/libc.core = the register exactly; 1 LOSSY-N3)
check_failure_reach: OK (230 pure failure sites = the 230 register rows exactly (228 in the exec dependency closure + 2 unresolved-owner; ...
Baseline check: 0 regression(s), 0 improvement(s)
ALL MATCH RECORDED BASELINE
SUMMARY: total=8 match=8 fail=0
SUMMARY: total=7 match=7 fail=0
PASS memory access: 3 runs; primitive receipts, all ND constructors, erasure, draining; 8 instrument controls
```

Derived: the audited range passed the full ladder; the audit-fix commit (a `Main.lean` argument-parsing change for L3,
a check-script change for L2, docs) passed every Tier A command. [AGENT] choice, stated to the operator in advance:
Tier A rather than a second full ladder for the audit-fix commit.
