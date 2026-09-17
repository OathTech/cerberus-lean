#!/usr/bin/env bash
# Auditor's second sequential chain: waits for chain 1 to end, then --with-lean subset, then row 12.
set -u
W=/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/pristine-oracle-instrument
CE=/home/dev/projects/cerberus-lean-proj/scripts/ce
cd "$W"; L=.tmp/audit
until /usr/bin/grep -q "CHAIN END" $L/chain.log; do sleep 10; done
echo "=== CHAIN2 START $(date -u +%FT%TZ) load: $(cut -d' ' -f1-3 /proc/loadavg)" > $L/chain2.log
run(){ name=$1; shift; echo "=== RUN $name START $(date -u +%FT%TZ) load: $(cut -d' ' -f1-3 /proc/loadavg)" >> $L/chain2.log; "$@" > $L/$name.txt 2>&1; rc=$?; echo "=== RUN $name END rc=$rc $(date -u +%FT%TZ) load: $(cut -d' ' -f1-3 /proc/loadavg)" >> $L/chain2.log; tail -3 $L/$name.txt >> $L/chain2.log; }
run with-lean-subset $CE python3 scripts/test_upstream_oracle.py --with-lean --only '^(minimal/073-exit\.libc\.c|minimal/097-null-ptr-arith\.undef\.c|debug/ub-static-reject\.c|bytes/byte_is_not_char\.c|immaculate/nolibc/g5-decode-question|immaculate/libc/g5-escape-roundtrip|multi_tu_tray/arr-1-2-return|minimal/001-return-literal\.c)$' --out $L/with-lean-subset
run row12-chvalid $CE python3 scripts/test_upstream_oracle.py --corpus libxml2_chvalid --out $L/row12-chvalid
echo "=== CHAIN2 END $(date -u +%FT%TZ)" >> $L/chain2.log
