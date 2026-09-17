#!/usr/bin/env bash
# Auditor's sequential gate chain at 586b550b8 (one heavy job at a time).
set -u
W=/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/pristine-oracle-instrument
CE=/home/dev/projects/cerberus-lean-proj/scripts/ce
cd "$W"
L=.tmp/audit
echo "=== CHAIN START $(date -u +%FT%TZ) head $(git rev-parse --short HEAD) $(uptime)" > $L/chain.log
run(){ name=$1; shift; echo "=== RUN $name START $(date -u +%FT%TZ) load: $(cut -d' ' -f1-3 /proc/loadavg)" >> $L/chain.log; "$@" > $L/$name.txt 2>&1; rc=$?; echo "=== RUN $name END rc=$rc $(date -u +%FT%TZ) load: $(cut -d' ' -f1-3 /proc/loadavg)" >> $L/chain.log; tail -3 $L/$name.txt >> $L/chain.log; }
run row10-full   $CE python3 scripts/test_upstream_oracle.py --out $L/row10-full
run row10-plant  $CE python3 scripts/test_upstream_oracle.py --plant --out $L/row10-plant
run corpus-ci    $CE python3 scripts/test_upstream_oracle.py --corpus ci --out $L/corpus-ci
run release-fast $CE python3 scripts/release.py --mode fast --out $L/release-fast
echo "=== CHAIN END $(date -u +%FT%TZ)" >> $L/chain.log
