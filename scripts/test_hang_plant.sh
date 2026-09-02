#!/bin/bash
# test_hang_plant.sh — plant test for the HANG classification (mem-scale
# S0, 2026-09-02; charter lean_frontend/docs/2026-09-01_mem-scale-design.md
# §6.1: "a deliberately sleeping stub must ALSO read HANG and a
# deliberately busy-looping stub must read TIMEOUT (both loud)").
#
# Vacuity must be loud: this script substitutes a STUB for the Lean driver
# (common.sh plant hook CERB_LEAN_BIN_OVERRIDE — banner on every use) and
# drives the two gating lanes that carry the classification:
#   scripts/test_exec.sh      (status HANG vs TIMEOUT; both fatal)
#   scripts/test_ci_sweep.sh  (rows LEAN_HANG vs LEAN_TIMEOUT)
# with (a) a stub that sleeps (0 CPU → exit 124 with CPU/wall ≈ 0 → HANG)
# and (b) a stub that busy-loops (CPU ≈ wall → exit 124 → TIMEOUT). Each
# expectation is asserted on the lane's own output; any other reading —
# including a stub that is not reached because the oracle side did not
# complete — fails this script. It also asserts the classifier's
# fail-closed path: a missing time record must be a HARNESS ERROR, not a
# TIMEOUT. Nothing here touches the semantics; the oracle runs unchanged
# on the smallest real inputs (tests/minimal/001-return-literal.c,
# tests/ci/0001-emptymain.c).
#
# Usage: ./scripts/test_hang_plant.sh        (needs env: scripts/ce)
# Exit 0 only if all four lane readings and the fail-closed probe match.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_time_bin

PLANT_TIMEOUT=3   # seconds; any value works — sleep burns ~0 CPU, busy burns ~all
WORK=$(mktemp -d "$TMP_DIR/hang-plant.XXXXXXXXXX") || { echo "Error: mktemp failed" >&2; exit 1; }
register_cleanup "$WORK"

# The stubs: `exec` so `timeout`'s SIGTERM reaches the process that owns
# the CPU/sleep (no orphaned child keeps running past the lane).
cat > "$WORK/stub_sleep" <<'EOF'
#!/bin/sh
exec sleep 1000
EOF
cat > "$WORK/stub_busy" <<'EOF'
#!/bin/sh
while :; do :; done
EOF
chmod +x "$WORK/stub_sleep" "$WORK/stub_busy"

fail=0
check() {   # <label> <expected-regex> <logfile>
    if grep -qE "$2" "$3"; then
        echo "PLANT OK   [$1]: $(grep -m1 -E "$2" "$3")"
    else
        echo "PLANT FAIL [$1]: expected /$2/ in lane output; got:" >&2
        grep -E 'HANG|TIMEOUT|CERB_|HARNESS|Error|FAIL' "$3" | head -10 >&2
        fail=1
    fi
}

# --- test_exec.sh: sleeping stub → HANG; busy stub → TIMEOUT ------------
for kind in sleep busy; do
    log="$WORK/exec_$kind.log"
    SKIP_BUILD=1 CERB_LEAN_BIN_OVERRIDE="$WORK/stub_$kind" TIMEOUT_SECS=$PLANT_TIMEOUT \
        "$SCRIPT_DIR/test_exec.sh" "$PROJECT_ROOT/tests/minimal/001-return-literal.c" \
        > "$log" 2>&1
    rc=$?
    [[ $rc -ne 0 ]] || { echo "PLANT FAIL [exec/$kind]: lane exited 0 on a non-completing Lean run (must be fatal)" >&2; fail=1; }
done
check "exec/sleep → HANG"    '^\[1/1\] HANG 001-return-literal \(Lean HANG\(cpu [0-9.]+s of [0-9.]+s wall; timeout '"$PLANT_TIMEOUT"'s\)\)$' "$WORK/exec_sleep.log"
check "exec/sleep summary"   'FAILED: 1 Lean HANG'                              "$WORK/exec_sleep.log"
check "exec/busy → TIMEOUT"  '^\[1/1\] TIMEOUT 001-return-literal \(Lean TIMEOUT\(cpu [0-9.]+s of [0-9.]+s wall; timeout '"$PLANT_TIMEOUT"'s\)\)$' "$WORK/exec_busy.log"
check "exec/busy summary"    'FAILED: 1 Lean timeout'                           "$WORK/exec_busy.log"

# --- test_ci_sweep.sh: sleeping stub → LEAN_HANG; busy → LEAN_TIMEOUT ----
for kind in sleep busy; do
    log="$WORK/sweep_$kind.log"
    SKIP_BUILD=1 CERB_LEAN_BIN_OVERRIDE="$WORK/stub_$kind" TIMEOUT_SECS=$PLANT_TIMEOUT \
        "$SCRIPT_DIR/test_ci_sweep.sh" --suite ci --max 1 --out "$WORK/sweep_out_$kind" \
        > "$log" 2>&1 || { echo "PLANT FAIL [sweep/$kind]: harness exited nonzero (harness-internal error?)" >&2; fail=1; }
    cat "$WORK/sweep_out_$kind/ci.tsv" >> "$log" 2>/dev/null
done
check "sweep/sleep → LEAN_HANG"   $'^ci\ttests/ci/0001-emptymain.c\tLEAN_HANG\tHANG\\(cpu [0-9.]+s of [0-9.]+s wall; timeout '"$PLANT_TIMEOUT"'s\)$' "$WORK/sweep_sleep.log"
check "sweep/busy → LEAN_TIMEOUT" $'^ci\ttests/ci/0001-emptymain.c\tLEAN_TIMEOUT\tTIMEOUT\\(cpu [0-9.]+s of [0-9.]+s wall; timeout '"$PLANT_TIMEOUT"'s\)$' "$WORK/sweep_busy.log"

# --- fail-closed: an unreadable time record is a harness error ----------
if out=$(classify_exit124 "$WORK/does-not-exist.time" 3 2>&1); then
    echo "PLANT FAIL [classifier fail-closed]: missing record classified as '$out' (must fail)" >&2; fail=1
else
    echo "PLANT OK   [classifier fail-closed]: $out"
fi

if [[ $fail -ne 0 ]]; then
    echo "test_hang_plant: FAILED"; exit 1
fi
echo "test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)"
