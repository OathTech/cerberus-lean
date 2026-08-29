#!/bin/bash
# test_speclab.sh — arc-15 S0: the spec-lab plant-test runner
# (skeleton). Runs a harness C file through BOTH pipelines
# (test_exec.sh's invocation pattern: oracle --nolibc --exec --batch;
# Lean via --cabs-json + cerberus-lean --batch) and compares the two
# outputs to each other and to an expected verdict.
#
# NOT WIRED INTO test_unit.sh: this lane is not gating until a rung
# stabilizes (arc-15 charter, "Validation and gates"). Run by hand /
# by rung workers.
#
# Usage:
#   ./scripts/test_speclab.sh <harness.c> <expected-verdict>
#       expected-verdict is the oracle-batch Defined value string,
#       e.g. 'Specified(0)'.
#   ./scripts/test_speclab.sh --selftest
#       S0 end-to-end: render the identity harness (speclab-test
#       --emit-identity), expect Specified(0) on both sides —
#       exercises mkHarness → C → both pipelines → agreement.
#   ./scripts/test_speclab.sh --plant
#       THE PLANT MODE HOOK (template note §plant-test; MANDATORY per
#       harness template from S1 on): render the identity harness with
#       expected[] corrupted at position 1 (speclab-test --emit-plant)
#       and REQUIRE the mismatch-index comparator to report it —
#       verdict Specified(2) = 1 + position — on both sides. A plant
#       that comes back Specified(0) means the harness is vacuous:
#       loud red. Later rungs extend this hook per-template: break the
#       TARGET function (not just expected[]), confirm the
#       differential goes red and the theorem becomes unprovable.
#
# Exit: 0 = agreement + expected verdict (+ gate OK); 1 = any failure.
# NOTE: no `set -e` — exit codes are data here (house pattern).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

TIMEOUT_SECS="${TIMEOUT_SECS:-30}"
RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
SPECLAB_TEST_BIN="$PROJECT_ROOT/lean_frontend/speclab/.lake/build/bin/speclab-test"

fail() { echo "test_speclab: FAIL — $*" >&2; exit 1; }

# ---- resolve mode ---------------------------------------------------
MODE="file"
HARNESS_SRC=""
EXPECTED=""
case "${1:-}" in
    --selftest) MODE="selftest" ;;
    --plant)    MODE="plant" ;;
    -h|--help)  grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    "")         fail "usage: test_speclab.sh <harness.c> <expected-verdict> | --selftest | --plant" ;;
    *)          HARNESS_SRC="$1"; EXPECTED="${2:-}"
                [[ -f "$HARNESS_SRC" ]] || fail "no such file: $HARNESS_SRC"
                [[ -n "$EXPECTED" ]] || fail "missing expected verdict" ;;
esac

# ---- build prerequisites (fail-closed; SKIP_BUILD honored) ----------
if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    [[ -f "$CERBERUS_BIN" ]] || fail "SKIP_BUILD=1 but $CERBERUS_BIN missing"
    [[ -f "$CERBERUS_LEAN_BIN" ]] || fail "SKIP_BUILD=1 but $CERBERUS_LEAN_BIN missing"
else
    build_cerberus
    build_lean
fi
[[ -d "$RUNTIME_DIR" ]] || fail "runtime dir not found: $RUNTIME_DIR (run dune install cerberus-lib)"

if [[ "$MODE" != "file" ]]; then
    (cd "$PROJECT_ROOT/lean_frontend/speclab" && \
        "$SCRIPT_DIR/capped" lake build speclab-test >/dev/null 2>&1)
    [[ -f "$SPECLAB_TEST_BIN" ]] || fail "speclab-test binary missing after build"
fi

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/speclab.XXXXXXXXXX") || fail "mktemp failed"
register_cleanup "$OUTPUT_DIR"

case "$MODE" in
    selftest)
        HARNESS_SRC="$OUTPUT_DIR/identity.c"
        "$SPECLAB_TEST_BIN" --emit-identity 10,20,30,40 > "$HARNESS_SRC" \
            || fail "emit-identity failed"
        EXPECTED="Specified(0)"
        ;;
    plant)
        HARNESS_SRC="$OUTPUT_DIR/plant.c"
        "$SPECLAB_TEST_BIN" --emit-plant 10,20,30,40 1 > "$HARNESS_SRC" \
            || fail "emit-plant failed"
        EXPECTED="Specified(2)"   # 1 + corrupted position 1
        ;;
esac

# ---- both pipelines (test_exec.sh invocation pattern) ---------------
oracle_out=$(timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" \
    --runtime="$RUNTIME_DIR" --nolibc --exec --batch --mode=exhaustive \
    "$HARNESS_SRC" 2>&1)
oracle_exit=$?
oracle_verdict=$(echo "$oracle_out" | grep -o 'Defined {value: "[^"]*"' | head -1 | sed 's/Defined {value: "//;s/"$//')

timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
    --cabs-json "$HARNESS_SRC" > "$OUTPUT_DIR/harness.json" 2>"$OUTPUT_DIR/cabs.err" \
    || fail "cabs-json bridge refused the harness: $(cat "$OUTPUT_DIR/cabs.err")"

lean_out=$(cd "$PROJECT_ROOT" && LEAN_ABORT_ON_PANIC=1 \
    timeout "${TIMEOUT_SECS}s" "$CERBERUS_LEAN_BIN" --batch \
    "$OUTPUT_DIR/harness.json" 2>&1)
lean_exit=$?
lean_verdict=$(echo "$lean_out" | grep -o 'Defined {value: "[^"]*"' | head -1 | sed 's/Defined {value: "//;s/"$//')

echo "test_speclab [$MODE] $HARNESS_SRC"
echo "  oracle: exit=$oracle_exit verdict=${oracle_verdict:-<none>}"
echo "  lean:   exit=$lean_exit verdict=${lean_verdict:-<none>}"
echo "  expect: $EXPECTED"

[[ -n "$oracle_verdict" ]] || fail "oracle produced no Defined verdict: $oracle_out"
[[ -n "$lean_verdict" ]] || fail "lean produced no Defined verdict: $lean_out"
[[ "$oracle_verdict" == "$lean_verdict" ]] \
    || fail "DIFFERENTIAL: oracle='$oracle_verdict' lean='$lean_verdict'"
[[ "$oracle_verdict" == "$EXPECTED" ]] \
    || fail "verdict '$oracle_verdict' != expected '$EXPECTED'"

echo "test_speclab: PASS (both pipelines agree on $EXPECTED)"
exit 0
