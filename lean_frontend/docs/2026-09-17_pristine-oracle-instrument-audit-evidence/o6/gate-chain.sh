#!/usr/bin/env bash
# Auditor's delta gate chain at 46e5d2f19's tree (one heavy job at a time).
set -u
W=/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/pristine-oracle-instrument
CE=/home/dev/projects/cerberus-lean-proj/scripts/ce
cd "$W"; L=.tmp/audit-o6
echo "=== CHAIN START $(date -u +%FT%TZ) lane-script sha $(sha256sum scripts/test_upstream_oracle.py | cut -c1-16) load: $(cut -d' ' -f1-3 /proc/loadavg)" > $L/chain.log
run(){ name=$1; shift; echo "=== RUN $name START $(date -u +%FT%TZ) load: $(cut -d' ' -f1-3 /proc/loadavg)" >> $L/chain.log; "$@" > $L/$name.txt 2>&1; rc=$?; echo "=== RUN $name END rc=$rc $(date -u +%FT%TZ) load: $(cut -d' ' -f1-3 /proc/loadavg)" >> $L/chain.log; tail -3 $L/$name.txt >> $L/chain.log; }
run row10-full  $CE python3 scripts/test_upstream_oracle.py --out $L/row10-full
run row10-plant $CE python3 scripts/test_upstream_oracle.py --plant --out $L/row10-plant
run corpus-ci   $CE python3 scripts/test_upstream_oracle.py --corpus ci --out $L/corpus-ci
echo "=== CHAIN END $(date -u +%FT%TZ)" >> $L/chain.log
