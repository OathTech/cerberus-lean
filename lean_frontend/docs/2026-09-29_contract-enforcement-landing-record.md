# Contract enforcement range — gate record before landing (2026-09-29)

Range: `mdd/cerberus-lean` `d62f52121` → `arc/contract-enforcement` (this commit's parent chain). Author: the
orchestrator [AGENT]. Pre-merge audit: `docs/2026-09-28_contract-range-pre-merge-audit.md` (MERGEABLE WITH FIXES;
dispositions in commit `676b866b4`, F2 as named deviation N2 in `2f09633d3`).

## Full ladder on `2f09633d3` (clean tree), 2026-09-29T19:23:05Z–21:16:59Z — verbatim

```
FAILED B7 (1521.6s)
full: failed; 39/40 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
=== RELEASE EXIT=1 2026-09-29T21:16:59Z ===
```

B7's only regression, verbatim: `REGRESSION: csmith/sia_csmith_477.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-`.
Per the lane's LOAD CAVEAT (`scripts/test_gcc_oracle.sh:17-21`: a regression whose only movement is into
SKIP_LEAN_TIMEOUT is re-run before it is read as red): the box load average was 14.35 at the end of the run; hand-timed
right after at load ~11: `wall=21.10 s` and `wall=20.86 s` (budget 30 s), value `Specified(132)` = gcc 132. The only
source change since the previous green B7 run (`676b866b4`) was comments.

## B7 re-run on `0f5df22ff` (the range head before this record; docs-only after `2f09633d3`) — verbatim

```
=== B7 re-run head=0f5df22ff 2026-09-29T21:19:16Z load=9.93 8.93 8.67 ===
[1496/2025] AGREE  csmith/sia_csmith_477.c: gcc=132 lean={132}
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
EXIT=0 2026-09-29T21:43:14Z load=7.03 5.79 6.61
```

Derived: 39/40 on the full ladder plus a green B7 re-run = every ladder row green on this range; `0f5df22ff` and
this record are docs-only on top of the laddered `2f09633d3`.
