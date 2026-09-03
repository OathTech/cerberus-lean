#!/bin/bash
# Test the Cabs JSON parse pipeline: C → OCaml parser → JSON → Lean deserializer
#
# Usage: ./scripts/test_parse.sh [options] [test_dir_or_file ...]
#
# With no arguments, runs tests/minimal/
#
# Lean side runs `cerberus-lean --pp-core <json>` (FUEL arc budget commit,
# 2026-09-03): deserialize + the whole front end (desugar, typing,
# translation, link) and STOP before execution. Before the budget commit
# this lane ran the default mode — parse AND execute — with no timeout,
# and was bounded only by the 10^6 fuel ceiling acting as an implicit
# timeout (a looping program died of fuel in seconds); at 10^8 an
# executing lane is unbounded (measured: tests/ci/0025-jump3.c, CERB_SKIP
# in the exec lane, ran > 4 min before being stopped). Execution was never
# this lane's purpose; the bar ("no `parse error`") is unchanged. A per-
# file TIMEOUT (default 60 s, TIMEOUT_SECS) is fail-NOISY: counted as its
# own class and fatal — never folded into "ok". Nonzero Lean exits without
# the `parse error` text are classified (second design review 2026-09-03;
# the per-file block below): REJECTED (printed front-end Error, exit 1;
# counted, visible), INTERNAL_ERROR_EXPECTED (failwithI panic on an
# *.error.c input, oracle-mirrored; counted, visible), LEAN_FAILURE (any
# other crash or verdict-less exit; FATAL — plant: test_fuel_plant.sh).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -euo pipefail

usage() {
    cat <<'EOF'
Test the Cabs JSON parse pipeline.

Usage: ./scripts/test_parse.sh [options] [test_dir_or_file ...]

Arguments:
  test_dir_or_file   .c file or directory (default: tests/minimal)

Options:
  --quick            Test first 20 files only
  --max N            Test first N files
  -v, --verbose      Show per-file results
  -h, --help         Show this help
EOF
    exit 0
}

VERBOSE=false
MAX_TESTS=0
TARGETS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        --quick) MAX_TESTS=20; shift ;;
        --max) MAX_TESTS="$2"; shift 2 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        *) TARGETS+=("$1"); shift ;;
    esac
done

# Default to tests/minimal
if [[ ${#TARGETS[@]} -eq 0 ]]; then
    TARGETS=("$PROJECT_ROOT/tests/minimal")
fi

# Build both sides
build_cerberus
build_lean

echo ""

# Collect test files
test_files=()
for target in "${TARGETS[@]}"; do
    if [[ -f "$target" ]]; then
        test_files+=("$target")
    elif [[ -d "$target" ]]; then
        while IFS= read -r f; do
            test_files+=("$f")
        done < <(find "$target" -name "*.c" | sort)
    else
        echo "Warning: $target not found" >&2
    fi
done

total_available=${#test_files[@]}
echo "Found $total_available test files"
if [[ $MAX_TESTS -gt 0 ]]; then
    echo "Testing first $MAX_TESTS"
fi
echo ""

# Counters
total=0
lean_timeout=0
lean_failure=0
lean_rejected=0
lean_internal_expected=0
TIMEOUT_SECS="${TIMEOUT_SECS:-60}"   # per-file Lean-side cap (header); fail-noisy
cerb_ok=0
cerb_fail=0
parse_ok=0
parse_fail=0

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/parse-test.XXXXXXXXXX")
register_cleanup "$OUTPUT_DIR"
ERROR_LOG="$OUTPUT_DIR/errors.log"
> "$ERROR_LOG"

start_time=$(date +%s)

for cfile in "${test_files[@]}"; do
    if [[ $MAX_TESTS -gt 0 && $total -ge $MAX_TESTS ]]; then
        break
    fi
    total=$((total + 1))

    name=$(basename "$cfile")
    hash=$(portable_hash "$cfile")
    json_file="$OUTPUT_DIR/${name%.c}_${hash}.json"

    # Step 1: OCaml parse → JSON
    if ! run_cerberus --cabs-json "$cfile" > "$json_file" 2>/dev/null; then
        cerb_fail=$((cerb_fail + 1))
        if $VERBOSE; then
            echo -e "${YELLOW}SKIP${NC} $name (cerberus parse failed)"
        fi
        continue
    fi
    cerb_ok=$((cerb_ok + 1))

    # Step 2: Lean deserialize JSON (+ front end, no execution — header)
    lean_rc=0
    result=$(timeout "${TIMEOUT_SECS}s" env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --pp-core "$json_file" 2>&1) || lean_rc=$?

    if [[ $lean_rc -eq 124 ]]; then
        lean_timeout=$((lean_timeout + 1))
        echo "$name: TIMEOUT (>${TIMEOUT_SECS}s, --pp-core)" >> "$ERROR_LOG"
        if $VERBOSE; then
            echo -e "${RED}TIMEOUT${NC} $name (>${TIMEOUT_SECS}s)"
        fi
    elif echo "$result" | grep -q "parse error"; then
        parse_fail=$((parse_fail + 1))
        error_msg=$(echo "$result" | grep "parse error" | head -1)
        echo "$name: $error_msg" >> "$ERROR_LOG"
        if $VERBOSE; then
            echo -e "${RED}FAIL${NC} $name: $error_msg"
        fi
    elif [[ $lean_rc -ne 0 ]]; then
        # Nonzero Lean exit WITHOUT the `parse error` text (second design
        # review 2026-09-03: this was counted parse_ok — fail-open). Three
        # classes, every one VISIBLE in the summary + the error log:
        #   REJECTED        exit 1..127 + a printed front-end VERDICT line
        #                   (`Error {msg: …}` — desugaring/typing refusal —
        #                   or `Undefined {ub: …}` — front-end UB detection):
        #                   the front end refused the program after a
        #                   successful parse (--pp-core exits 1 on it;
        #                   tests/ci carries 117 such rows, mostly *.error.c
        #                   / *.undef.c intended ones). Not a parse failure;
        #                   counted, non-fatal.
        #   INTERNAL_ERROR  exit >= 128 with LemLib's `failwithIImpl` PANIC
        #   _EXPECTED       line on a *.error.c input — the model's own
        #                   fail-closed internal error on an intended-error
        #                   program, MIRRORED by the oracle (tests/ci 0258/
        #                   0270: oracle `exit 125: internal error: …`, the
        #                   same message). Counted, non-fatal, listed.
        #   LEAN_FAILURE    anything else — a crash (SIGABRT/SIGSEGV/stack
        #                   overflow, a failwithI panic on a non-error
        #                   input) or a nonzero exit with no printed
        #                   verdict. FATAL. Plant: scripts/test_fuel_plant.sh
        #                   (a stub exiting 134 -> red).
        first_line=$(echo "$result" | grep -m1 -E 'PANIC|Stack overflow|Error \{|Undefined \{|error' | cut -c1-120 || true)   # set -e/pipefail: a no-match grep must not abort the lane
        if [[ $lean_rc -lt 128 ]] && echo "$result" | grep -qE '^(Error \{msg: |Undefined \{ub: )'; then
            lean_rejected=$((lean_rejected + 1))
            echo "$name: REJECTED (exit $lean_rc): $first_line" >> "$ERROR_LOG"
            if $VERBOSE; then
                echo -e "${YELLOW}REJECTED${NC} $name (exit $lean_rc): $first_line"
            fi
        elif [[ $lean_rc -ge 128 && "$name" == *.error.c ]] && echo "$result" | grep -q 'PANIC at .*failwithIImpl'; then
            lean_internal_expected=$((lean_internal_expected + 1))
            echo "$name: INTERNAL_ERROR_EXPECTED (exit $lean_rc, failwithI on an intended-error input): $first_line" >> "$ERROR_LOG"
            if $VERBOSE; then
                echo -e "${YELLOW}INTERNAL_ERROR_EXPECTED${NC} $name (exit $lean_rc): $first_line"
            fi
        else
            lean_failure=$((lean_failure + 1))
            echo "$name: LEAN_FAILURE (exit $lean_rc, no 'parse error' text): $first_line" >> "$ERROR_LOG"
            if $VERBOSE; then
                echo -e "${RED}LEAN_FAILURE${NC} $name (exit $lean_rc): $first_line"
            fi
        fi
    else
        parse_ok=$((parse_ok + 1))
        if $VERBOSE; then
            echo -e "${GREEN}OK${NC}   $name"
        fi
    fi

    # Progress (every 50 files)
    if ! $VERBOSE && [[ $((total % 50)) -eq 0 ]]; then
        echo "  [$total/$total_available] cerberus: $cerb_ok ok, $cerb_fail skip | parse: $parse_ok ok, $parse_fail fail"
    fi
done

end_time=$(date +%s)
elapsed=$((end_time - start_time))

echo ""
echo "================================"
echo "Results ($elapsed seconds)"
echo "================================"
echo "Total:          $total"
echo "Cerberus parse: $cerb_ok ok, $cerb_fail failed"
echo "Lean parse:     $parse_ok ok, $parse_fail failed, $lean_timeout timeout (>${TIMEOUT_SECS}s; fatal), $lean_failure lean failure(s) (crash / nonzero exit without a printed verdict; fatal)"
echo "Lean front end: $lean_rejected rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), $lean_internal_expected internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)"

if [[ $cerb_ok -gt 0 ]]; then
    rate=$((parse_ok * 100 / cerb_ok))
    echo "Success rate:   ${rate}% (of cerberus successes)"
fi

if [[ -s "$ERROR_LOG" ]]; then
    echo ""
    echo "Top error categories:"
    # Materialised first: under `set -o pipefail`, `head -10` closing the
    # pipe early gave `sort` SIGPIPE (rc 141) and `set -e` killed the lane
    # before its verdict whenever the log had > 10 lines — a latent bug,
    # first hit when tests/ci's 117 REJECTED rows became logged
    # (second design review close-out, 2026-09-03).
    TOP_CATS=$(sed 's/^[^:]*: //' "$ERROR_LOG" | sort | uniq -c | sort -rn || true)
    printf '%s\n' "$TOP_CATS" | head -10 | while IFS= read -r line; do
        printf "  %s\n" "$line"
    done
fi

echo ""
if [[ $parse_fail -gt 0 || $lean_timeout -gt 0 || $lean_failure -gt 0 ]]; then
    echo -e "${RED}FAILED: $parse_fail parse error(s), $lean_timeout timeout(s), $lean_failure lean failure(s)${NC}"
    echo "Error log: $ERROR_LOG"
    exit 1
else
    echo -e "${GREEN}ALL PASSED${NC}"
fi
