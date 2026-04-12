#!/bin/bash
# Test the Core text parser: C → OCaml cerberus --pp core → Lean CoreParser
#
# Usage: ./scripts/test_core.sh [options] [test_dir_or_file ...]
#
# With no arguments, runs tests/minimal/

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -euo pipefail

usage() {
    cat <<'EOF'
Test the Core text parser pipeline.

Generates Core IR text from C programs using the OCaml cerberus tool,
then parses the output with the Lean CoreParser.

Usage: ./scripts/test_core.sh [options] [test_dir_or_file ...]

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
cerb_ok=0
cerb_fail=0
parse_ok=0
parse_fail=0

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/core-test.XXXXXXXXXX")
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
    core_file="$OUTPUT_DIR/${name%.c}_${hash}.core"

    # Step 1: OCaml cerberus → Core text
    if ! run_cerberus --nolibc --pp core "$cfile" > "$core_file" 2>/dev/null; then
        cerb_fail=$((cerb_fail + 1))
        if $VERBOSE; then
            echo -e "${YELLOW}SKIP${NC} $name (cerberus --pp core failed)"
        fi
        continue
    fi
    cerb_ok=$((cerb_ok + 1))

    # Step 2: Lean CoreParser
    result=$(run_cerberus_lean --parse-core "$core_file" 2>&1) || true

    if echo "$result" | grep -q "ERROR"; then
        parse_fail=$((parse_fail + 1))
        error_msg=$(echo "$result" | grep "ERROR" | head -1)
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
echo "Cerberus --pp:  $cerb_ok ok, $cerb_fail failed"
echo "Lean parse:     $parse_ok ok, $parse_fail failed"

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
if [[ $parse_fail -gt 0 ]]; then
    echo -e "${RED}FAILED: $parse_fail parse error(s)${NC}"
    echo "Error log: $ERROR_LOG"
    exit 1
else
    echo -e "${GREEN}ALL PASSED${NC}"
fi
