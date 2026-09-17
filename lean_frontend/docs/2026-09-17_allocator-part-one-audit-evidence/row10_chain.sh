#!/bin/bash
set -uo pipefail
cd "$(dirname "$0")/../.."
stamp() { echo "[$(date -u +%FT%TZ) load $(cut -d' ' -f1-3 /proc/loadavg)] $*"; }
rm -rf .tmp/audit/row10 .tmp/audit/row10-plant .tmp/audit/corpus-ci
stamp "start head $(git rev-parse HEAD)"
stamp "## row 10"
python3 scripts/test_upstream_oracle.py --out .tmp/audit/row10 > .tmp/audit/row10.log 2>&1; echo "row10 rc=$?"; tail -2 .tmp/audit/row10.log
stamp "## --plant"
python3 scripts/test_upstream_oracle.py --plant --out .tmp/audit/row10-plant > .tmp/audit/row10-plant.log 2>&1; echo "plant rc=$?"; echo "PLANT OK lines: $(grep -c '^PLANT OK' .tmp/audit/row10-plant.log)  PLANT FAIL lines: $(grep -c '^PLANT FAIL' .tmp/audit/row10-plant.log)"; grep "projection/header" .tmp/audit/row10-plant.log; tail -2 .tmp/audit/row10-plant.log
stamp "## --corpus ci"
python3 scripts/test_upstream_oracle.py --corpus ci --out .tmp/audit/corpus-ci > .tmp/audit/corpus-ci.log 2>&1; echo "ci rc=$?"; grep "matching_incomplete:" .tmp/audit/corpus-ci.log | head -3; tail -2 .tmp/audit/corpus-ci.log
stamp "chain done"
