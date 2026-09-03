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
# own class and fatal — never folded into "ok".

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
echo "Lean parse:     $parse_ok ok, $parse_fail failed, $lean_timeout timeout (>${TIMEOUT_SECS}s; fatal)"

if [[ $cerb_ok -gt 0 ]]; then
    rate=$((parse_ok * 100 / cerb_ok))
    echo "Success rate:   ${rate}% (of cerberus successes)"
fi

if [[ -s "$ERROR_LOG" ]]; then
    echo ""
    echo "Top error categories:"
    sed 's/^[^:]*: //' "$ERROR_LOG" | sort | uniq -c | sort -rn | head -10 | while IFS= read -r line; do
        printf "  %s\n" "$line"
    done
fi

echo ""
if [[ $parse_fail -gt 0 || $lean_timeout -gt 0 ]]; then
    echo -e "${RED}FAILED: $parse_fail parse error(s), $lean_timeout timeout(s)${NC}"
    echo "Error log: $ERROR_LOG"
    exit 1
else
    echo -e "${GREEN}ALL PASSED${NC}"
fi
