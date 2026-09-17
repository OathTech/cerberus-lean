#!/bin/bash
# AUDITOR delta gate chain on the c58b7d70e tree (files of b7fec4d63 + c58b7d70e checked out into the audit worktree)
set -uo pipefail
cd "$(dirname "$0")/../.."
stamp() { echo "[$(date -u +%FT%TZ) load $(cut -d' ' -f1-3 /proc/loadavg)] $*"; }
rm -rf .tmp/audit/d-row10 .tmp/audit/d-plant .tmp/audit/d-with-lean .tmp/audit/d-release
stamp "start; tree = c58b7d70e for the range files (git diff --stat c58b7d70e outside audit paths: $(git diff --stat c58b7d70e -- . ':(exclude)lean_frontend/docs/2026-09-17_allocator-part-one-audit-premerge.md' ':(exclude)lean_frontend/docs/2026-09-17_allocator-part-one-audit-evidence' | wc -l) lines)"
stamp "## row 10"
python3 scripts/test_upstream_oracle.py --out .tmp/audit/d-row10 > .tmp/audit/d-row10.log 2>&1; echo "row10 rc=$?"; grep -E "minimal/11[23]-" .tmp/audit/d-row10.log; tail -2 .tmp/audit/d-row10.log
stamp "## --plant"
python3 scripts/test_upstream_oracle.py --plant --out .tmp/audit/d-plant > .tmp/audit/d-plant.log 2>&1; echo "plant rc=$?"; echo "PLANT OK lines: $(grep -c '^PLANT OK' .tmp/audit/d-plant.log)  PLANT FAIL lines: $(grep -c '^PLANT FAIL' .tmp/audit/d-plant.log)"; grep "register/committed-loads" .tmp/audit/d-plant.log; tail -1 .tmp/audit/d-plant.log
stamp "## --with-lean --only the two witnesses (three-engine)"
python3 scripts/test_upstream_oracle.py --with-lean --only '^minimal/11[23]-allocator' --out .tmp/audit/d-with-lean > .tmp/audit/d-with-lean.log 2>&1; echo "with-lean rc=$?"; grep -E "minimal/11[23]-|Three-engine|Independent oracle:" .tmp/audit/d-with-lean.log
stamp "## release.py --mode fast"
python3 scripts/release.py --mode fast --out .tmp/audit/d-release > .tmp/audit/d-release.log 2>&1; echo "release rc=$?"; grep -E "^(PASSED|FAILED|SKIP)" .tmp/audit/d-release.log | tr '\n' ' '; echo; tail -3 .tmp/audit/d-release.log
echo "--- A2 rows for the witnesses + summary ---"; grep -E "11[23]-allocator|^SUMMARY|^Baseline check" .tmp/audit/d-release/A2/stdout
echo "--- A9 rows for the witnesses + summary ---"; grep -E "11[23]-allocator|^SUMMARY|DIFF:" .tmp/audit/d-release/A9/stdout
echo "--- A1 lines of interest ---"; grep -E "allocator-soundness-test: OK|Total:|check_fork_drift: OK|D14 grep-ban OK" .tmp/audit/d-release/A1/stdout | cut -c1-160
stamp "chain done"
