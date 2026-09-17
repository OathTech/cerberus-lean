#!/usr/bin/env bash
# Auditor's third chain: after chain 2 ends, re-run release.py --mode fast with NO tree writes during the run.
set -u
W=/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/pristine-oracle-instrument
CE=/home/dev/projects/cerberus-lean-proj/scripts/ce
cd "$W"; L=.tmp/audit
until /usr/bin/grep -q "CHAIN2 END" $L/chain2.log 2>/dev/null; do sleep 10; done
echo "=== CHAIN3 START $(date -u +%FT%TZ) load: $(cut -d' ' -f1-3 /proc/loadavg)" > $L/chain3.log
git status --porcelain >> $L/chain3.log
echo "=== RUN release-fast-2 START $(date -u +%FT%TZ)" >> $L/chain3.log
$CE python3 scripts/release.py --mode fast --out $L/release-fast-2 > $L/release-fast-2.txt 2>&1; rc=$?
echo "=== RUN release-fast-2 END rc=$rc $(date -u +%FT%TZ) load: $(cut -d' ' -f1-3 /proc/loadavg)" >> $L/chain3.log
tail -3 $L/release-fast-2.txt >> $L/chain3.log
echo "=== CHAIN3 END $(date -u +%FT%TZ)" >> $L/chain3.log
