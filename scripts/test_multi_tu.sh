#!/bin/bash
# test_multi_tu.sh — differential MULTI-TU execution harness (arc-5 S2):
# OCaml cerberus linking N .c files natively vs the Lean pipeline linking
# N cabs-jsons through the generated Core_linking.link.
#
# Convention: each test is a DIRECTORY under tests/multi_tu/ containing
# two or more .c files (linked in SORTED name order, both sides) and any
# headers they include. There are no per-file expectation files: OCaml is
# the oracle, exactly as in test_exec.sh.
#
# Invocations mirror test_exec.sh precisely (same flags, same
# verdict-sequence comparison — the extraction/comparison logic below is
# lifted from test_exec.sh's S5f full-sequence form, simplified to the
# statuses a directory corpus can produce):
#   OCaml : cerberus --nolibc --exec --batch --mode=exhaustive a.c b.c ...
#           (multi-file linking is native: per-file frontend fold
#            main.ml:153-156, Core_linking.link main.ml:278-281)
#   Lean  : cerberus-lean --batch a.json b.json ...
#           (per-file cabs-json via `cerberus --cabs-json <file>` — one
#            run per file: the OCaml driver prints one json per input)
#
# Comparison scope (arc-5 audit 2, F9): this harness compares VERDICT
# SEQUENCES (the value/ub fields extracted per execution), NOT
# stdout/stderr — the libxml2 gate (test_libxml2.sh) is the stricter one
# (byte-identical batch verdict line incl. stdout/stderr/blocked).
# Rationale: the corpus here runs --mode=exhaustive, where per-execution
# stdout interleaving/ordering is not a stable comparable, while the
# verdict sequence is; deep-observation coverage is delegated to the
# single-trace libxml2 gate.
#
# Fail-closed: any MISMATCH/DIFF/FAIL/CRASH/TIMEOUT/empty-corpus exits 1.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

usage() {
    cat <<'EOF'
Differential multi-TU execution test: OCaml cerberus vs the Lean pipeline.

Usage: ./scripts/test_multi_tu.sh [options] [corpus_dir_or_test_dir]

Arguments:
  corpus_dir_or_test_dir   Directory of test dirs, or a single test dir
                           containing .c files (default: tests/multi_tu)

Options:
  -v, --verbose   Show both sides' outputs on mismatch
  -h, --help      This help

Environment:
  TIMEOUT_SECS    per-side timeout (default: 30)
EOF
    exit 0
}

VERBOSE=false
CORPUS=""
TIMEOUT_SECS="${TIMEOUT_SECS:-30}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) CORPUS="$1"; shift ;;
    esac
done

if ! command -v timeout &>/dev/null; then
    echo "Error: 'timeout' command not found" >&2
    exit 1
fi

[[ -z "$CORPUS" ]] && CORPUS="$PROJECT_ROOT/tests/multi_tu"
if [[ ! -d "$CORPUS" ]]; then
    echo "Error: corpus not found: $CORPUS" >&2
    exit 1
fi
CORPUS=$(cd "$CORPUS" && pwd)

build_cerberus
build_lean

RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
if [[ ! -d "$RUNTIME_DIR" ]]; then
    echo "Error: runtime dir not found: $RUNTIME_DIR (run dune install cerberus-lib)" >&2
    exit 1
fi

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/multi-tu-test.XXXXXXXXXX") || { echo "Error: mktemp failed" >&2; exit 1; }
register_cleanup "$OUTPUT_DIR"

# Lean binary locates runtime/libcore relative to cwd
cd "$PROJECT_ROOT" || { echo "Error: cannot cd to $PROJECT_ROOT" >&2; exit 1; }

# Collect test dirs: either $CORPUS itself holds .c files (single test),
# or each immediate subdirectory with >= 2 .c files is a test.
declare -a TEST_DIRS=()
if compgen -G "$CORPUS/*.c" > /dev/null; then
    TEST_DIRS=("$CORPUS")
else
    while IFS= read -r d; do
        TEST_DIRS+=("$d")
    done < <(find "$CORPUS" -mindepth 1 -maxdepth 1 -type d | sort)
fi
if [[ ${#TEST_DIRS[@]} -eq 0 ]]; then
    echo "Error: no test directories found under $CORPUS (empty corpus is a failure)" >&2
    exit 1
fi

# Verdict-sequence extraction — lifted from test_exec.sh (S5f full-sequence;
# whole Undefined line since the zero-discrepancy arc, charter §4.1)
extract_verdict_seq() {
    printf '%s\n' "$1" \
        | grep -oE '^Undefined \{.*\}$|^Defined \{value: "[^"]*"' \
        | sed -e 's/^Undefined \(.*\)$/UB:\1/' \
              -e 's/^Defined {value: "\(.*\)"$/VAL:\1/'
    return 0
}
expected_exit_for() {
    if [[ "$1" == *'EXECUTION '* ]]; then echo 0
    elif [[ "$1" == *'Undefined {'* || "$1" == *'Error {'* ]]; then echo 1
    else echo 0; fi
}

PASS=0
FAIL=0
num=0
echo ""
echo "Running multi-TU differential comparison (${#TEST_DIRS[@]} tests)..."
echo "=================================================="

for tdir in "${TEST_DIRS[@]}"; do
    num=$((num + 1))
    tname=$(basename "$tdir")
    declare -a C_FILES=()
    while IFS= read -r f; do C_FILES+=("$f"); done < <(find "$tdir" -maxdepth 1 -name "*.c" | sort)
    if [[ ${#C_FILES[@]} -lt 2 ]]; then
        echo "[$num] FAIL $tname: needs >= 2 .c files (found ${#C_FILES[@]})"
        FAIL=$((FAIL + 1))
        continue
    fi

    # --- OCaml: native multi-file link + exec --------------------------
    cerb_exit=0
    cerb_output=$(timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        --nolibc --exec --batch --mode=exhaustive "${C_FILES[@]}" 2>&1) || cerb_exit=$?
    if [[ $cerb_exit -ge 124 ]]; then
        echo "[$num] FAIL $tname: OCaml side timeout/crash (exit $cerb_exit)"
        FAIL=$((FAIL + 1))
        continue
    fi
    cerb_seq=$(extract_verdict_seq "$cerb_output")
    if [[ -z "$cerb_seq" ]]; then
        echo "[$num] FAIL $tname: no OCaml verdicts (exit $cerb_exit): $(echo "$cerb_output" | head -2 | tr '\n' ' ')"
        FAIL=$((FAIL + 1))
        continue
    fi
    cerb_expected=$(expected_exit_for "$cerb_output")
    if [[ $cerb_exit -ne $cerb_expected ]]; then
        echo "[$num] FAIL $tname: OCaml exit $cerb_exit inconsistent with verdicts (expected $cerb_expected)"
        FAIL=$((FAIL + 1))
        continue
    fi

    # --- Cabs JSON per TU ---------------------------------------------
    declare -a JSON_FILES=()
    json_ok=true
    for c in "${C_FILES[@]}"; do
        j="$OUTPUT_DIR/$tname-$(basename "$c" .c).json"
        if ! timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
                --cabs-json "$c" > "$j" 2>/dev/null; then
            echo "[$num] FAIL $tname: cabs-json failed for $(basename "$c")"
            json_ok=false
            break
        fi
        JSON_FILES+=("$j")
    done
    if ! $json_ok; then
        FAIL=$((FAIL + 1))
        JSON_FILES=()
        continue
    fi

    # --- Lean: multi-json link + exec ---------------------------------
    lean_exit=0
    lean_output=$(LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" \
        "$CERBERUS_LEAN_BIN" --batch "${JSON_FILES[@]}" 2>&1) || lean_exit=$?
    JSON_FILES=()
    if [[ $lean_exit -ge 124 ]]; then
        echo "[$num] FAIL $tname: Lean side timeout/crash (exit $lean_exit)"
        FAIL=$((FAIL + 1))
        continue
    fi
    lean_seq=$(extract_verdict_seq "$lean_output")
    if [[ -z "$lean_seq" ]]; then
        echo "[$num] FAIL $tname: no Lean verdicts (exit $lean_exit): $(echo "$lean_output" | head -2 | tr '\n' ' ')"
        FAIL=$((FAIL + 1))
        continue
    fi
    lean_expected=$(expected_exit_for "$lean_output")
    if [[ $lean_exit -ne $lean_expected ]]; then
        echo "[$num] FAIL $tname: Lean exit $lean_exit inconsistent with verdicts (expected $lean_expected)"
        FAIL=$((FAIL + 1))
        continue
    fi

    # --- Full verdict-sequence comparison ------------------------------
    if [[ "$lean_seq" == "$cerb_seq" ]]; then
        n_exec=$(printf '%s\n' "$lean_seq" | wc -l)
        first=$(printf '%s\n' "$lean_seq" | head -1)
        echo "[$num] MATCH $tname: $n_exec execution(s), $first"
        PASS=$((PASS + 1))
    else
        echo "[$num] MISMATCH $tname:"
        echo "    ocaml: $(printf '%s' "$cerb_seq" | tr '\n' '|')"
        echo "    lean:  $(printf '%s' "$lean_seq" | tr '\n' '|')"
        if $VERBOSE; then
            echo "--- OCaml output ---"; printf '%s\n' "$cerb_output"
            echo "--- Lean output ---";  printf '%s\n' "$lean_output"
        fi
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "=================================================="
echo "SUMMARY: total=$((PASS + FAIL)) match=$PASS fail=$FAIL"
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
echo "ALL PASSED"
exit 0
