#!/bin/bash
# test_elab.sh — elaborated-Core stage differential, REPORTING MODE (arc-4 S4).
#
# For each .c file, compares the elaborated Core produced by OCaml cerberus
# (`--nolibc --pp core`) against the Lean pipeline's translated Core
# (`cerberus-lean --pp-core <cabs-json>`), both reduced to a canonical
# SIGNATURE-level summary and passed through canonicalize_ids.py
# (id-insensitive), then sorted and diffed.
#
# ============================================================================
# GRANULARITY LIMITATION — PROMINENT AND DELIBERATE
#
# The comparison is SIGNATURE-LEVEL ONLY: declaration names, kinds
# (fun/proc/procdecl/builtin/glob/tagdef), arities, and aggregate member
# names. Function/glob BODIES are NOT compared. The Lean pipeline has no
# real Core pretty-printer (CerbPP.lean is placeholders; generated Pp.lean
# is a stub), and building one is explicitly out of scope for this slice
# (charter S4). A body-level Core differential is a recorded next-arc item.
#
# Two further parity filters, both documented in extract_core_sig.py /
# Main.lean ppCoreSignature:
#   * OCaml pp only prints declarations located in the MAIN file
#     (pp_core.ml pp_cond); the Lean side therefore drops its injected
#     GCC-builtin ProcDecls (`procdecl/builtin __builtin_*`) before
#     comparing. Header-defined functions (e.g. csmith corpora) will still
#     show as one-sided DIFFs — known, recorded.
#   * canonicalize_ids.py assigns first-occurrence ordinals; with more
#     than one numbered symbol per file (e.g. several string-literal
#     globs) differing emission ORDER between the two sides can produce a
#     spurious DIFF. tests/minimal has at most one per file.
# ============================================================================
#
# REPORTING MODE: per-file SAME/DIFF/…, summary, and ALWAYS exit 0 — unless
# the harness itself errors (missing tools/corpus, self-test failure,
# unwritable temp: fail-closed, exit 1).
#
# Statuses:
#   SAME        signatures identical after canonicalization
#   DIFF        signatures differ (use -v for the diff)
#   OCAML_FAIL  cerberus --pp core or --cabs-json failed/timed out
#   LEAN_FAIL   cerberus-lean --pp-core failed/crashed/timed out

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail
# NOTE: -e intentionally omitted — exit codes are data here.

usage() {
    cat <<'EOF'
Elaborated-Core stage differential (signature level), reporting mode.

Usage: ./scripts/test_elab.sh [options] [test_dir_or_file]

Arguments:
  test_dir_or_file   A .c file or directory (default: tests/minimal)

Options:
  -v, --verbose   Show the per-file diff for DIFF results
  --max N         Test first N files only
  -h, --help      Show this help

Environment:
  TIMEOUT_SECS    per-side timeout (default: 30)

Always exits 0 (reporting mode) unless the harness itself errors.
EOF
    exit 0
}

VERBOSE=false
TEST_PATH=""
MAX_TESTS=0
TIMEOUT_SECS="${TIMEOUT_SECS:-30}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -v|--verbose) VERBOSE=true; shift ;;
        --max) MAX_TESTS="$2"; shift 2 ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *) TEST_PATH="$1"; shift ;;
    esac
done

# Fail-closed guards (harness-internal errors are fatal)
command -v timeout &>/dev/null || { echo "HARNESS ERROR: 'timeout' not found" >&2; exit 1; }
command -v python3 &>/dev/null || { echo "HARNESS ERROR: 'python3' not found" >&2; exit 1; }
CANON="$SCRIPT_DIR/canonicalize_ids.py"
EXTRACT="$SCRIPT_DIR/extract_core_sig.py"
[[ -f "$CANON" ]] || { echo "HARNESS ERROR: $CANON not found" >&2; exit 1; }
[[ -f "$EXTRACT" ]] || { echo "HARNESS ERROR: $EXTRACT not found" >&2; exit 1; }
python3 "$CANON" --self-test >/dev/null || { echo "HARNESS ERROR: canonicalize_ids self-test failed" >&2; exit 1; }
python3 "$EXTRACT" --self-test >/dev/null || { echo "HARNESS ERROR: extract_core_sig self-test failed" >&2; exit 1; }

# Resolve test path to absolute before any cd (arc house rule)
abspath() {
    if [[ -d "$1" ]]; then (cd "$1" && pwd)
    elif [[ -f "$1" ]]; then echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
    else return 1; fi
}
[[ -z "$TEST_PATH" ]] && TEST_PATH="$PROJECT_ROOT/tests/minimal"
SINGLE_FILE=false
if [[ -f "$TEST_PATH" ]]; then
    SINGLE_FILE=true
    TEST_PATH=$(abspath "$TEST_PATH") || { echo "HARNESS ERROR: cannot resolve $TEST_PATH" >&2; exit 1; }
elif [[ -d "$TEST_PATH" ]]; then
    TEST_PATH=$(abspath "$TEST_PATH") || { echo "HARNESS ERROR: cannot resolve $TEST_PATH" >&2; exit 1; }
else
    echo "HARNESS ERROR: test path not found: $TEST_PATH" >&2
    exit 1
fi

build_cerberus
build_lean

RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
[[ -d "$RUNTIME_DIR" ]] || { echo "HARNESS ERROR: runtime dir not found: $RUNTIME_DIR" >&2; exit 1; }

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/elab-test.XXXXXXXXXX") || { echo "HARNESS ERROR: mktemp failed" >&2; exit 1; }
register_cleanup "$OUTPUT_DIR"

# The Lean binary locates runtime/libcore relative to cwd
cd "$PROJECT_ROOT" || { echo "HARNESS ERROR: cannot cd to $PROJECT_ROOT" >&2; exit 1; }

declare -a TEST_FILES=()
if $SINGLE_FILE; then
    TEST_FILES=("$TEST_PATH")
else
    while IFS= read -r f; do TEST_FILES+=("$f"); done \
        < <(find "$TEST_PATH" -name "*.c" ! -name "*.syntax-only.c" ! -name "*.exhaust.c" | sort)
fi
TOTAL=${#TEST_FILES[@]}
[[ $TOTAL -eq 0 ]] && { echo "HARNESS ERROR: no test files found in $TEST_PATH" >&2; exit 1; }
if [[ $MAX_TESTS -gt 0 ]] && ! $SINGLE_FILE; then
    TEST_FILES=("${TEST_FILES[@]:0:$MAX_TESTS}")
fi

echo "Elaborated-Core signature differential (REPORTING MODE) on ${#TEST_FILES[@]} files"
echo "granularity: names/kinds/arities/member-names only — see header"
echo "============================================"

SAME=0; DIFF=0; OCAML_FAIL=0; LEAN_FAIL=0
n=0
total=${#TEST_FILES[@]}
for c_file in "${TEST_FILES[@]}"; do
    n=$((n + 1))
    name=$(basename "$c_file" .c)

    # --- OCaml side: --pp core → signature extract -------------------------
    ocaml_pp=$(timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        --nolibc --pp core "$c_file" 2>/dev/null)
    rc=$?
    if [[ $rc -ne 0 ]]; then
        OCAML_FAIL=$((OCAML_FAIL + 1))
        echo "[$n/$total] OCAML_FAIL $name (--pp core exit $rc)"
        continue
    fi
    if ! printf '%s\n' "$ocaml_pp" | python3 "$EXTRACT" > "$OUTPUT_DIR/ocaml.sig"; then
        OCAML_FAIL=$((OCAML_FAIL + 1))
        echo "[$n/$total] OCAML_FAIL $name (signature extraction failed)"
        continue
    fi

    # --- Lean side: cabs-json → --pp-core ----------------------------------
    json="$OUTPUT_DIR/$name.json"
    if ! timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
            --cabs-json "$c_file" > "$json" 2>/dev/null; then
        OCAML_FAIL=$((OCAML_FAIL + 1))
        echo "[$n/$total] OCAML_FAIL $name (--cabs-json failed)"
        continue
    fi
    lean_sig=$(LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" \
        "$CERBERUS_LEAN_BIN" --pp-core "$json" 2>/dev/null)
    rc=$?
    if [[ $rc -ne 0 ]]; then
        LEAN_FAIL=$((LEAN_FAIL + 1))
        echo "[$n/$total] LEAN_FAIL $name (--pp-core exit $rc)"
        continue
    fi
    # Parity filter: OCaml pp skips non-main-file decls; drop the Lean
    # pipeline's injected GCC-builtin declarations (see header).
    printf '%s\n' "$lean_sig" | grep -v '^\(procdecl\|builtin\) __builtin_' > "$OUTPUT_DIR/lean.sig"

    # --- Canonicalize (id-insensitive), sort, diff --------------------------
    python3 "$CANON" < "$OUTPUT_DIR/ocaml.sig" | sort > "$OUTPUT_DIR/ocaml.canon" \
        || { echo "HARNESS ERROR: canonicalize failed (ocaml side)" >&2; exit 1; }
    python3 "$CANON" < "$OUTPUT_DIR/lean.sig" | sort > "$OUTPUT_DIR/lean.canon" \
        || { echo "HARNESS ERROR: canonicalize failed (lean side)" >&2; exit 1; }

    if diff -q "$OUTPUT_DIR/ocaml.canon" "$OUTPUT_DIR/lean.canon" >/dev/null; then
        SAME=$((SAME + 1))
        echo "[$n/$total] SAME $name"
    else
        DIFF=$((DIFF + 1))
        echo "[$n/$total] DIFF $name"
        if $VERBOSE; then
            diff --label "ocaml($name)" --label "lean($name)" \
                -u "$OUTPUT_DIR/ocaml.canon" "$OUTPUT_DIR/lean.canon" | sed 's/^/    /'
        fi
    fi
done

echo ""
echo "============================================"
echo "Elaborated-Core signature differential (reporting mode)"
echo "  SAME:       $SAME"
echo "  DIFF:       $DIFF"
echo "  OCAML_FAIL: $OCAML_FAIL"
echo "  LEAN_FAIL:  $LEAN_FAIL"
echo ""
echo "SUMMARY: total=$n same=$SAME diff=$DIFF ocaml_fail=$OCAML_FAIL lean_fail=$LEAN_FAIL"

# Reporting mode: always exit 0 (harness-internal errors exited 1 above)
exit 0
