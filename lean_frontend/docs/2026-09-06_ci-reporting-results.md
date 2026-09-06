# CI reporting on the validation-foundations candidate

2026-09-06 [AGENT]. Both affected reporting measurements completed on the
clean identified candidate. Their classifications are evidence, not a release
certification or permission to change a semantic baseline.

The candidate is `1066d89eea16f55a0f204f95c351731629df296a`. The scripts
retain all raw observations and write proposed scoreboards under their
release-report directories. Committed baselines are unchanged. C1/C4 are
measurements; the full A+B gate result is a separate 32/32 pass.

## Measurements

C1 completed all 242 `tests/ci` rows in about 99 seconds, with clean unchanged
source: 91 MATCH, 41 UB_MATCH, 110 CERB_SKIP, no scoreboard movement. This is 132
compared matches plus 110 oracle-side skips. It is not 242 successful semantic
comparisons. C4 completed all 2,186 inputs across 15 suites in about 2,972 seconds, with
source and external inputs unchanged. The exact row sets and input hashes
match the advance inventory. Its counts are:

| Classification | Rows | Meaning |
|---|---:|---|
| MATCH | 1,205 | Complete printed observation sequences agree |
| UB_MATCH | 154 | Complete printed observation sequences agree in the UB class |
| UB_DIFF | 1 | Same UB code with different location; a difference |
| LEAN_CRASH | 3 | Attributed filesystem-boundary refusals |
| LEAN_TIMEOUT | 2 | No completed Lean observation within 15 seconds |
| CERB_REJECT | 766 | Oracle frontend rejection; Lean comparison not reached |
| CERB_ERROR | 29 | Oracle Error outcome; Lean comparison not reached |
| CERB_TIMEOUT | 26 | Oracle did not complete within 15 seconds |

Thus 1,359 rows have matching observations. No value MISMATCH, one-sided-UB
DIFF, or STDOUT_DIFF was observed; that does not turn the other 827 rows into
agreement. Raw error messages and statuses remain part of the archive.

The old C4 TSVs span earlier source revisions and instruments. A changed row
does not by itself isolate a regression caused by this charter. The current
raw observations establish today's result; causal attribution is supplied
only where the source obligation or a focused reproducer supports it.

## Findings and disposition

| ID | Exact input / observation | Disposition, owner and next action |
|---|---|---|
| CI-LOC | `tests/suite/fs/fprintf_then_fscanf.c`: both engines exit 1 with `UB048_disjoint_array_pointers_subtraction` and empty semantic stderr fields; oracle location `<116:23--116:30>`, Lean `<unknown location>`. Formerly UB_MATCH, now UB_DIFF. | Current reproduction of registered Z1-A1, not agreement. Cerberus provider must retain libc source locations in its consumed pin/reader and verify propagation. The existing short filesystem fixture is the reproducer; `runtime/libc/src/stdio.c:116` is the reference body location. |
| CI-FS | `tests/freebsd/cat.c` reaches `fclose(stdout)` and `CerbFS.fs_close:260`; `tests/suite/fs/stat.c` reaches `CerbFS.fs_stat:504`; `tests/tcc/40_stdio.c` reaches `CerbFS.fs_read:338` at a nonzero, non-EOF offset. All emit attributed filesystem-boundary refusals and exit 134. | Enforced support limits already declared in CerbFS. These are additional current C-triggered failure witnesses, not successful comparisons. Provider owns any future standard-descriptor/stat/mid-file-read model support and faithful typed refusal propagation. Preserve the known refusal until that model exists. |
| CI-TIME | `tests/pnvi_testsuite/pointer_copy_user_ctrlflow_bytewise.c`: the Lean process consumes the 15-second budget, where the historical scoreboard said UB_MATCH. The source contains a 256-arm byte dispatcher inside a pointer-byte copy. `tests/gcc-torture/breakdown/success/pr69320-4.c` also times out; that second row was already LEAN_TIMEOUT historically. Its small nine-iteration source is a separate input, not an asserted common cause. | Completion/performance finding; no completed Lean verdict is available to compare. Provider owns an identified cost/termination investigation under the existing budget. Do not call a timeout agreement, diagnose a value bug from it, or raise fuel/time merely to make the scoreboard green. |

The location defect's source obligation and prior witness are registered in
[the zero-discrepancy design](2026-09-03_zero-discrepancy-design.md), Z1-A1.
The Core-text libc pin omits locations; running libc code overwrites the
current location with unknown. The original fixture already isolates the
stdio operation; this new report supplies current raw verdicts and statuses.

The filesystem witnesses are deliberate runtime refusals. Their presence
does not establish faithful logical failure behavior of pure `panic!` sites;
that is the separate [failure correspondence proposal](2026-09-06_failure-census-and-correspondence.md).

## Historical scoreboard movement

All 2,186 current rows are matched by name against the historical TSVs.
There are 56 changed classifications; the complete per-row inventory is
[the reporting comparison](validation-foundations-evidence/final-reporting-summary.json).
The unchanged second timeout and the unchanged TCC filesystem refusal remain
explicit findings in the current inventory, despite not being movement rows.

| Old → current | Rows |
|---|---:|
| CERB_INCONSISTENT → UB_MATCH | 43 |
| STDOUT_DIFF → MATCH | 6 |
| LEAN_CRASH → MATCH | 2 |
| LEAN_TIMEOUT → MATCH | 1 |
| UB_MATCH → UB_DIFF | 1 |
| UB_MATCH → LEAN_TIMEOUT | 1 |
| STDOUT_DIFF → LEAN_CRASH | 1 |
| LEAN_FAIL → LEAN_CRASH | 1 |

The 52 rows now reaching matching observations incorporate the earlier
provider changes as well as the current instruments. The location-loss row
shows why an old UB-code-only match cannot certify the complete observation.
The stat and stdout-close rows now report their explicit support boundaries.
No historical source version was re-executed by this comparison.

## Reproduction and evidence

The [reporting archive](validation-foundations-evidence/final-reporting.tar.gz)
retains both complete release reports, every raw capture, all proposed TSVs,
the exact input inventory and the comparison script/result. The
[checksum inventory](validation-foundations-evidence/SHA256SUMS) identifies the
artifacts. The original scoreboards in `scripts/exec_ci_baseline.txt` and
`tests/ci_sweep/results/` were not overwritten. These fresh artifacts satisfy
this charter's affected-reporting work; they do not complete C2/C3, customer
adoption, or the fresh audit.
