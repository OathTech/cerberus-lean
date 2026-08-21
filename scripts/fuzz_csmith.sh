#!/bin/bash
# fuzz_csmith.sh — csmith differential fuzzing, minimal port (arc-4 S4b).
#
# Ported from cerberus-lean-prototype/scripts/fuzz_csmith.sh +
# gen_csmith.sh, retargeted at scripts/test_exec.sh (OCaml cerberus vs the
# full Lean pipeline). Kept from the prototype: the csmith flag set
# (--no-argc --no-bitfields + small size caps — the --no-* flags avoid
# known-unsupported features: argc/argv handling and bitfields), the
# csmith.h → csmith_cerberus.h substitution, and the bug-saving loop.
# Adaptations:
#   * comparison loop IS test_exec.sh (one directory run), so all its
#     statuses/semantics apply; LEAN_CRASH is saved as a bug class too.
#   * tests/csmith/csmith_cerberus.h here differs from the prototype's in
#     exactly one way (documented in the header): platform_main_end is a
#     macro returning the checksum from main instead of calling exit()
#     — neither side of this differential links a C library.
#   * CSMITH_SEED_START env: if set, seeds are sequential from there
#     (reproducible smoke runs); default is random seeds like the
#     prototype.
#
# Scale fuzzing is explicitly NEXT-arc (charter S4b); default N is a
# smoke-sized 25.
#
# Usage: ./scripts/fuzz_csmith.sh [options] [num_tests] [output_dir]
#   num_tests    default 25
#   output_dir   where the log + saved bug reproducers go
#                (default: <project>/.tmp/csmith_fuzz — NOT committed)
# Options:
#   -v, --verbose   pass --verbose to test_exec.sh
#   -h, --help      this help
# Environment:
#   TIMEOUT_SECS       per-side per-test timeout (default here: 15)
#   CSMITH_SEED_START  deterministic sequential seeds from this value
#   CSMITH_FLAGS       (arc-10 S4) space-separated csmith flag override —
#                      REPLACES the default kit flag set below (the
#                      phase-1 lane portfolio passes per-lane flags);
#                      unset = the historical kit flags, unchanged
#
# Exit: 1 if any bug (FAIL/MISMATCH/DIFF/LEAN_CRASH) was found, else 0.
# Harness-internal errors also exit 1 (fail-closed).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

usage() { sed -n '2,36p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

NUM_TESTS=""
OUTPUT_DIR=""
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *)
            if [[ -z "$NUM_TESTS" ]]; then NUM_TESTS="$1"
            elif [[ -z "$OUTPUT_DIR" ]]; then OUTPUT_DIR="$1"
            else echo "Error: too many arguments" >&2; exit 1; fi
            shift ;;
    esac
done
NUM_TESTS="${NUM_TESTS:-25}"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/.tmp/csmith_fuzz}"
export TIMEOUT_SECS="${TIMEOUT_SECS:-15}"

command -v csmith &>/dev/null || { echo "Error: csmith not found" >&2; exit 1; }
CSMITH_HDR_DIR="$PROJECT_ROOT/tests/csmith"
[[ -f "$CSMITH_HDR_DIR/csmith_cerberus.h" && -f "$CSMITH_HDR_DIR/safe_math.h" ]] \
    || { echo "Error: $CSMITH_HDR_DIR/{csmith_cerberus.h,safe_math.h} missing" >&2; exit 1; }

mkdir -p "$OUTPUT_DIR/bugs" "$OUTPUT_DIR/timeouts" || { echo "Error: cannot create $OUTPUT_DIR" >&2; exit 1; }
GEN_DIR=$(mktemp -d "$TMP_DIR/csmith-gen.XXXXXXXXXX") || { echo "Error: mktemp failed" >&2; exit 1; }
register_cleanup "$GEN_DIR"

echo "Generating $NUM_TESTS csmith tests in $GEN_DIR (timeout ${TIMEOUT_SECS}s/side)..."
for i in $(seq 1 "$NUM_TESTS"); do
    if [[ -n "${CSMITH_SEED_START:-}" ]]; then
        seed=$((CSMITH_SEED_START + i))
    else
        seed=$RANDOM$RANDOM
    fi
    if [[ -n "${CSMITH_FLAGS:-}" ]]; then
        # shellcheck disable=SC2086 — word-splitting is the interface
        csmith --seed "$seed" ${CSMITH_FLAGS} 2>/dev/null
    else
        csmith \
            --no-argc \
            --no-bitfields \
            --seed "$seed" \
            --max-funcs 3 \
            --max-block-depth 3 \
            --max-block-size 4 \
            --max-expr-complexity 3 \
            2>/dev/null
    fi \
      | sed 's|#include "csmith.h"|#define CSMITH_MINIMAL\n#include "csmith_cerberus.h"|' \
      > "$GEN_DIR/csmith_${seed}.c"
    [[ -s "$GEN_DIR/csmith_${seed}.c" ]] || { echo "Error: csmith produced no output (seed $seed)" >&2; exit 1; }
done
cp "$CSMITH_HDR_DIR/csmith_cerberus.h" "$CSMITH_HDR_DIR/safe_math.h" "$GEN_DIR/"

echo "Running differential comparison (test_exec.sh)..."
VERBOSE_FLAGS=()
$VERBOSE && VERBOSE_FLAGS=("--verbose")
LOG="$OUTPUT_DIR/fuzz_log.txt"
# test_exec.sh exits 1 on mismatches in default mode — that IS the signal
# we harvest below, so don't die on it.
"$SCRIPT_DIR/test_exec.sh" ${VERBOSE_FLAGS[@]+"${VERBOSE_FLAGS[@]}"} "$GEN_DIR" 2>&1 | tee "$LOG"
harness_rc=${PIPESTATUS[0]}

BUGS_SAVED=0
TIMEOUTS_SAVED=0
while IFS= read -r line; do
    if [[ "$line" =~ \[.*\]\ (FAIL|MISMATCH|DIFF|LEAN_CRASH)\ ([^: ]+) ]]; then
        testname="${BASH_REMATCH[2]}"
        if [[ -f "$GEN_DIR/${testname}.c" ]]; then
            cp "$GEN_DIR/${testname}.c" "$OUTPUT_DIR/bugs/"
            echo "BUG FOUND: $OUTPUT_DIR/bugs/${testname}.c"
            echo "  $line"
            BUGS_SAVED=$((BUGS_SAVED + 1))
        fi
    elif [[ "$line" =~ \[.*\]\ TIMEOUT\ ([^: ]+) ]]; then
        testname="${BASH_REMATCH[1]}"
        if [[ -f "$GEN_DIR/${testname}.c" ]]; then
            cp "$GEN_DIR/${testname}.c" "$OUTPUT_DIR/timeouts/"
            echo "Timeout: $OUTPUT_DIR/timeouts/${testname}.c"
            TIMEOUTS_SAVED=$((TIMEOUTS_SAVED + 1))
        fi
    fi
done < "$LOG"

echo ""
echo "================================="
echo "Csmith fuzz summary (N=$NUM_TESTS)"
echo "================================="
echo "  Bugs (FAIL/MISMATCH/DIFF/LEAN_CRASH): $BUGS_SAVED  -> $OUTPUT_DIR/bugs/"
echo "  Timeouts:                             $TIMEOUTS_SAVED  -> $OUTPUT_DIR/timeouts/"
echo "  Log: $LOG"

if [[ $BUGS_SAVED -gt 0 ]]; then
    echo ""
    echo "*** BUGS FOUND — reproducers saved ***"
    exit 1
fi
exit 0
