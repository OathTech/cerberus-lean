#!/bin/bash
# perf_timing_lane.sh — PERF-0 (2026-08-28): THE TIMING LANE.
#
# Tier-C REPORTING INSTRUMENT (scripts/LADDER.md sense): prints
# per-module build wall-times and the P02 SUPPLY-CLOSURE time under
# PINNED CONDITIONS. It is NOT a gate — it never fails on a slow
# number; regressions are data (donor lineage: RefinedC's coq-speed
# regression dashboard, lithium/interpreter.v:183 link; plan §3.F).
#
# THE PINNED CONDITIONS (review amendment A5 — the ≤5-min PERF-1 exit
# is DEFINED as this lane's closure number, nothing else):
#   * COLD:   the closure modules' artifacts are deleted first
#             (dependencies BELOW the closure stay warm — the metric
#             is the supply closure, not the whole tree);
#   * SERIAL: one module per lake invocation, dependency order,
#             LAKE_JOBS=1;
#   * CAPPED: scripts/capped at CERB_MEM_MAX (default 48G here).
#
# Closure list (A5): P02Rounds (base) + P02Guard + all present
# P02Rounds{A,B,C,D} chunks. Context modules are timed as reported
# extras (warm unless changed).
#
# Usage: from repo root or anywhere:
#   scripts/perf_timing_lane.sh            # the pinned closure run
#   scripts/perf_timing_lane.sh --no-cold  # warm re-run (labeled)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RELSEM="$REPO_ROOT/lean_frontend/relsem"
export CERB_MEM_MAX="${CERB_MEM_MAX:-48G}"

COLD=1
[[ "${1:-}" == "--no-cold" ]] && COLD=0

# The closure (dependency order). Chunks B/C/D join automatically
# when registered in the lakefile roots.
CLOSURE=(P02Rounds P02Guard P02RoundsA)
for c in B C D; do
    if grep -q "RelSem.P02Rounds$c" "$RELSEM/lakefile.toml"; then
        CLOSURE+=("P02Rounds$c")
    fi
done
# Reported extras (context; not part of the closure metric)
EXTRAS=(SegRun SegRoundTac SegStepper)

cd "$RELSEM" || exit 1

echo "== perf timing lane (Tier C, reporting only) =="
echo "date:        $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "HEAD:        $(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo n/a)"
echo "lean:        $(lean --version 2>/dev/null | head -1)"
echo "mem cap:     $CERB_MEM_MAX (via scripts/capped)"
echo "mode:        $([[ $COLD == 1 ]] && echo 'COLD closure (pinned conditions)' || echo 'WARM (NOT the pinned metric)')"
echo "closure:     ${CLOSURE[*]}"

# Budget census (the SLOW register's mechanical shadow): per-decl
# maxHeartbeats occurrences in the supply closure sources.
echo "-- budget census (set_option maxHeartbeats in closure sources) --"
for m in "${CLOSURE[@]}"; do
    f="RelSem/$m.lean"
    [[ -f "$f" ]] || continue
    n=$(grep -c "set_option maxHeartbeats 16000000" "$f" || true)
    echo "   $m: ${n} x 16M"
done

if [[ $COLD == 1 ]]; then
    for m in "${CLOSURE[@]}"; do
        rm -f ".lake/build/lib/lean/RelSem/$m."{olean,olean.hash,ilean,ilean.hash,trace} 2>/dev/null
    done
fi

echo "-- per-module wall times (serial, capped) --"
total=0
fail=0
for m in "${CLOSURE[@]}" "${EXTRAS[@]}"; do
    t0=$(date +%s.%N)
    if ! "$SCRIPT_DIR/capped" env LAKE_JOBS=1 lake build "RelSem.$m" \
            > /tmp/perf_lane_$$.log 2>&1; then
        echo "   RelSem.$m: BUILD FAILED (see /tmp/perf_lane_$$.log)"
        fail=1
        continue
    fi
    t1=$(date +%s.%N)
    dt=$(echo "$t1 $t0" | awk '{printf "%.1f", $1-$2}')
    incl=""
    for c in "${CLOSURE[@]}"; do [[ "$c" == "$m" ]] && incl="[closure]"; done
    echo "   RelSem.$m: ${dt}s $incl"
    if [[ -n "$incl" ]]; then
        total=$(echo "$total $dt" | awk '{printf "%.1f", $1+$2}')
    fi
done
rm -f /tmp/perf_lane_$$.log

echo "-- summary --"
if [[ $COLD == 1 ]]; then
    echo "   P02 SUPPLY CLOSURE (cold/serial/capped): ${total}s"
else
    echo "   P02 supply closure (WARM — not the pinned metric): ${total}s"
fi
[[ $fail == 1 ]] && echo "   NOTE: failures above — closure number is PARTIAL"
echo "   (PERF-1 exit target: <= ~300s at the pinned conditions;"
echo "    report the honest number either way — plan §5, A5)"
exit 0
