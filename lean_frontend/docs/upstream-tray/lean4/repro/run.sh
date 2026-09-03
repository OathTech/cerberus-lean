#!/usr/bin/env bash
# run.sh <timeout-seconds> <command...>
# Runs the command with core dumps disabled; if it is still alive at the
# timeout, prints each thread's CPU time (clock ticks) and kernel wait channel
# from /proc, then kills it.  Exit status: the command's, or 124 on timeout.
# A stack-overflow HANG shows as: exit 124, one thread with a large utime and
# wchan=futex_do_wait, no "Stack overflow detected" line.
set -uo pipefail
T="$1"; shift
ulimit -c 0
"$@" & pid=$!
for ((i = 0; i < T * 10; i++)); do
  if ! kill -0 "$pid" 2>/dev/null; then wait "$pid"; rc=$?; echo "exit=$rc"; exit $rc; fi
  sleep 0.1
done
echo "TIMEOUT after ${T}s; threads of pid $pid:"
for t in /proc/$pid/task/*; do
  echo "  tid=$(basename "$t") state=$(awk '{print $3}' "$t/stat") utime_ticks=$(awk '{print $14}' "$t/stat") stime_ticks=$(awk '{print $15}' "$t/stat") wchan=$(cat "$t/wchan")"
done
grep -E '^(VmRSS|Threads)' "/proc/$pid/status" | sed 's/^/  /'
kill -9 "$pid"; wait "$pid" 2>/dev/null
echo "exit=124"
exit 124
