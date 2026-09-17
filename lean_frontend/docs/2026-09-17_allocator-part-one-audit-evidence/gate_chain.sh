#!/bin/bash
# AUDITOR gate chain at f5b1578dc: row 10, --plant, --corpus ci, release.py --mode fast — sequential, one heavy job at a time.
set -uo pipefail
cd "$(dirname "$0")/../.."
stamp() { echo "[$(date -u +%FT%TZ) load $(cut -d' ' -f1-3 /proc/loadavg)] $*"; }
stamp "start head $(git rev-parse HEAD) branch $(git branch --show-current)"
stamp "## row 10: python3 scripts/test_upstream_oracle.py --out .tmp/audit/row10"
python3 scripts/test_upstream_oracle.py --out .tmp/audit/row10 > .tmp/audit/row10.log 2>&1; echo "row10 rc=$?"; tail -2 .tmp/audit/row10.log
stamp "## --plant"
python3 scripts/test_upstream_oracle.py --plant --out .tmp/audit/row10-plant > .tmp/audit/row10-plant.log 2>&1; echo "plant rc=$?"; grep -c "^PLANT OK" .tmp/audit/row10-plant.log | sed 's/^/PLANT OK lines: /'; grep "^PLANT FAIL" .tmp/audit/row10-plant.log; grep "projection/header" .tmp/audit/row10-plant.log; tail -2 .tmp/audit/row10-plant.log
stamp "## --corpus ci"
python3 scripts/test_upstream_oracle.py --corpus ci --out .tmp/audit/corpus-ci > .tmp/audit/corpus-ci.log 2>&1; echo "ci rc=$?"; grep "matching_incomplete:" .tmp/audit/corpus-ci.log | head -3; tail -2 .tmp/audit/corpus-ci.log
stamp "## release.py --mode fast"
python3 scripts/release.py --mode fast --out .tmp/audit/release-fast > .tmp/audit/release-fast.log 2>&1; echo "release rc=$?"; grep -E "^(PASSED|FAILED|SKIP)" .tmp/audit/release-fast.log; tail -4 .tmp/audit/release-fast.log
stamp "chain done"
