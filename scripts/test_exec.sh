#!/bin/bash
# test_exec.sh — differential execution harness: OCaml cerberus vs the full
# Lean pipeline (C → cabs-json → desugar → typecheck → translate → execute).
#
# Ported from cerberus-lean-prototype/scripts/test_interp.sh (arc 4 / S2);
# the comparison semantics (return-value extraction, UB-code comparison,
# one-sided-UB = DIFF, cerberus-failure = CERB_SKIP, *.unsupported.c
# handling) are preserved from the prototype. Adaptations, all deliberate:
#
#   * Lean side is the GENERATED pipeline binary
#     (lean_frontend/.lake/build/bin/cerberus-lean --batch <cabs-json>),
#     not the prototype's Core-JSON interpreter. Input is Cabs JSON from
#     `cerberus --cabs-json` (no --nolibc there — matches the arc-4 S0/S1a
#     frontier sweeps), while the OCaml *execution* side always runs
#     --nolibc (the Lean pipeline links no C library, only the core
#     stdlib — parity choice; .libc.c files are NOT filtered, they just
#     surface as CERB_SKIP/whatever they honestly are).
#   * Flags dropped vs the prototype (kept surface minimal):
#       --nolibc         (always on for the OCaml exec side, see above)
#       --mode=MODE      (both sides are always exhaustive: CerbND.runND is
#                         an exhaustive runner; OCaml gets --mode=exhaustive)
#       --sequentialise  (no sequentialise wiring in the Lean pipeline)
#   * FULL-SEQUENCE comparison (arc-4 S5f audit hardening, replaces the
#     prototype-inherited head -1): BOTH sides' outputs are reduced to the
#     ordered sequence of per-execution verdict tokens (UB:<code> for each
#     Undefined line, VAL:<value> for each Defined line — Specified and
#     Unspecified alike) and the sequences are compared in full. Identical
#     sequences → MATCH (no UB token) / UB_MATCH (any UB token); sequences
#     that differ ONLY in UB codes (same length, same UB positions, equal
#     values) → UB_DIFF; one-sided UB presence → DIFF; anything else
#     (value diff, length diff, shape diff) → MISMATCH.
#   * New status LEAN_CRASH (exit >= 128: SIGABRT under
#     LEAN_ABORT_ON_PANIC=1, SIGSEGV, ...) — the prototype's interpreter
#     did not crash so it had no such class. Counted as a Lean failure.
#   * Exit-code/verdict consistency (arc-4 S5f audit hardening): both
#     binaries follow OCaml main.ml runM's convention — single Defined →
#     exit 0, single Undefined/Error → exit 1, multiple executions →
#     exit 0 — so a bare "any nonzero exit is fatal" rule would flag the
#     entire single-UB corpus. Instead the EXPECTED exit is derived from
#     the parsed output and any deviation is flagged even when the output
#     parses (closes the print-then-crash / laundering hole):
#       Lean side   → LEAN_ERROR  (fatal in default mode)
#       OCaml side  → CERB_INCONSISTENT (non-fatal, counted, visible;
#                     timeouts/signals 124/134/137/139 stay CERB_SKIP)
#   * Lean TIMEOUT, LEAN_CRASH and LEAN_ERROR are fatal in default mode
#     (the prototype only counted timeouts). Fail-closed house rule.
#   * Default mode with ZERO comparisons (all files skipped) is a FAILURE,
#     not a vacuous pass.
#   * Baseline tracking: --write-baseline / --check-baseline against
#     scripts/exec_baseline.txt (test_core.sh-style: regression vs the
#     committed baseline fails the gate even mid-arc; improvements are
#     reported, not fatal). A file NOT in the baseline whose current
#     status is MISMATCH/DIFF/FAIL/LEAN_CRASH/LEAN_ERROR/TIMEOUT is FATAL
#     (a deleted baseline line must not launder a failing file); new
#     files with any other status are reported, non-fatal.
#
# Recorded caveats (audit-2, deliberate residual holes):
#   * Both-sides-timeout invisibility: the OCaml side runs FIRST; if it
#     times out the file is CERB_SKIP and the Lean side is never sampled,
#     so a Lean-side hang on the same file is invisible. A file must be
#     OCaml-terminating for its Lean behavior to be observed.
#   * stdout-text spoofing: verdict tokens are extracted textually from
#     the merged output; a test program that printed a crafted
#     "Undefined {ub: ..." / "Defined {value: ..." line could in
#     principle forge tokens. Unreachable today: the harness links no
#     libc (--nolibc / no Lean-side C library), so test programs cannot
#     write to stdout at all, and captured program stdout is embedded
#     quote-ESCAPED inside the Defined line where the token patterns
#     cannot match. Recorded, not defended further.
#
# Per-file statuses (baseline taxonomy):
#   MATCH UB_MATCH UB_DIFF MISMATCH DIFF FAIL TIMEOUT LEAN_CRASH LEAN_ERROR
#   CERB_SKIP CERB_INCONSISTENT UNSUPPORTED UNSUPPORTED_PASS
#
# NOTE: this script intentionally does NOT use `set -e` — it captures
# non-zero exit codes from both sides for comparison. Every failure path
# must therefore be handled explicitly (fail-closed: any harness-internal
# error exits 1).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail
# NOTE: -e intentionally omitted — exit codes are data here.

usage() {
    cat <<'EOF'
Differential execution test: OCaml cerberus vs the Lean pipeline binary.

Usage: ./scripts/test_exec.sh [options] [test_dir_or_file]

Arguments:
  test_dir_or_file   A .c file or directory (default: tests/minimal)

Options:
  -v, --verbose            Show extra per-file detail
  --max N                  Test first N files only
  --list FILE              Read test paths from FILE (one per line)
  --exclude=PATTERN        Exclude files whose basename matches PATTERN (grep)
  --write-baseline[=FILE]  Write per-file statuses (default: scripts/exec_baseline.txt)
  --check-baseline[=FILE]  Compare against baseline; exit 1 on any regression
  -h, --help               Show this help

Environment:
  TIMEOUT_SECS   per-test timeout for each side (default: 30)
  SKIP_BUILD     1 = skip the (no-op) build steps; binaries must exist
                 (fail-closed). For high-frequency callers (creduce).

Examples:
  ./scripts/test_exec.sh tests/minimal/001-return-literal.c
  ./scripts/test_exec.sh tests/minimal
  ./scripts/test_exec.sh --check-baseline
EOF
    exit 0
}

# Fail-closed guard for required tools
if ! command -v timeout &>/dev/null; then
    echo "Error: 'timeout' command not found" >&2
    exit 1
fi

DEFAULT_BASELINE="$SCRIPT_DIR/exec_baseline.txt"

VERBOSE=false
TEST_PATH=""
LIST_FILE=""
MAX_TESTS=0            # 0 = unlimited
EXCLUDE_PATTERN=""
WRITE_BASELINE=""
CHECK_BASELINE=""
TIMEOUT_SECS="${TIMEOUT_SECS:-30}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -v|--verbose) VERBOSE=true; shift ;;
        --max) MAX_TESTS="$2"; shift 2 ;;
        --list) LIST_FILE="$2"; shift 2 ;;
        --exclude=*) EXCLUDE_PATTERN="${1#--exclude=}"; shift ;;
        --write-baseline) WRITE_BASELINE="$DEFAULT_BASELINE"; shift ;;
        --write-baseline=*) WRITE_BASELINE="${1#--write-baseline=}"; shift ;;
        --check-baseline) CHECK_BASELINE="$DEFAULT_BASELINE"; shift ;;
        --check-baseline=*) CHECK_BASELINE="${1#--check-baseline=}"; shift ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
        *) TEST_PATH="$1"; shift ;;
    esac
done

if [[ -n "$WRITE_BASELINE" && -n "$CHECK_BASELINE" ]]; then
    echo "Error: --write-baseline and --check-baseline are mutually exclusive" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Resolve ALL paths to absolute BEFORE any cd (arc house rule)
# ---------------------------------------------------------------------------
abspath() {
    # file or dir must exist; fail-closed otherwise
    if [[ -d "$1" ]]; then
        (cd "$1" && pwd)
    elif [[ -f "$1" ]]; then
        echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
    else
        return 1
    fi
}

if [[ -n "$LIST_FILE" ]]; then
    LIST_FILE_ABS=$(abspath "$LIST_FILE") || { echo "Error: list file not found: $LIST_FILE" >&2; exit 1; }
    LIST_FILE="$LIST_FILE_ABS"
fi

[[ -z "$TEST_PATH" && -z "$LIST_FILE" ]] && TEST_PATH="$PROJECT_ROOT/tests/minimal"

SINGLE_FILE=false
if [[ -n "$TEST_PATH" ]]; then
    if [[ -f "$TEST_PATH" ]]; then
        SINGLE_FILE=true
        TEST_PATH=$(abspath "$TEST_PATH") || { echo "Error: cannot resolve $TEST_PATH" >&2; exit 1; }
    elif [[ -d "$TEST_PATH" ]]; then
        TEST_PATH=$(abspath "$TEST_PATH") || { echo "Error: cannot resolve $TEST_PATH" >&2; exit 1; }
    else
        echo "Error: test path not found: $TEST_PATH" >&2
        exit 1
    fi
fi

if [[ -n "$CHECK_BASELINE" ]]; then
    CHECK_BASELINE_ABS=$(abspath "$CHECK_BASELINE") || { echo "Error: baseline file not found: $CHECK_BASELINE" >&2; exit 1; }
    CHECK_BASELINE="$CHECK_BASELINE_ABS"
fi
# WRITE_BASELINE target may not exist yet; resolve its directory
if [[ -n "$WRITE_BASELINE" ]]; then
    wb_dir=$(abspath "$(dirname "$WRITE_BASELINE")") || { echo "Error: baseline directory not found: $(dirname "$WRITE_BASELINE")" >&2; exit 1; }
    WRITE_BASELINE="$wb_dir/$(basename "$WRITE_BASELINE")"
fi

# Build both sides (each exits 1 on failure — fail-closed).
# SKIP_BUILD=1 (arc-10 S4 instrument, D1-authorized): skip the no-op
# build steps for high-frequency callers (creduce interestingness runs
# ~8-12 s of no-op dune/lake per call otherwise; also avoids concurrent
# no-op builds racing in the shared _build/.lake). Semantics unchanged
# when unset. Fail-closed: the binaries must already exist.
if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    [[ -f "$CERBERUS_BIN" ]] || { echo "Error: SKIP_BUILD=1 but $CERBERUS_BIN missing" >&2; exit 1; }
    [[ -f "$CERBERUS_LEAN_BIN" ]] || { echo "Error: SKIP_BUILD=1 but $CERBERUS_LEAN_BIN missing" >&2; exit 1; }
else
    build_cerberus
    build_lean
fi

RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
if [[ ! -d "$RUNTIME_DIR" ]]; then
    echo "Error: runtime dir not found: $RUNTIME_DIR (run dune install cerberus-lib)" >&2
    exit 1
fi
if [[ ! -f "$PROJECT_ROOT/runtime/libcore/std.core" ]]; then
    echo "Error: $PROJECT_ROOT/runtime/libcore/std.core not found (Lean side needs it)" >&2
    exit 1
fi

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/exec-test.XXXXXXXXXX") || { echo "Error: mktemp failed" >&2; exit 1; }
register_cleanup "$OUTPUT_DIR"
STATUS_FILE="$OUTPUT_DIR/status.txt"
: > "$STATUS_FILE" || { echo "Error: cannot write $STATUS_FILE" >&2; exit 1; }

# The Lean binary locates runtime/libcore relative to cwd: run from project
# root. All other paths are already absolute.
cd "$PROJECT_ROOT" || { echo "Error: cannot cd to $PROJECT_ROOT" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Collect test files
# ---------------------------------------------------------------------------
echo ""
declare -a TEST_FILES=()

if [[ -n "$LIST_FILE" ]]; then
    echo "Testing files from list: $LIST_FILE"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        if [[ ! -f "$line" ]]; then
            echo "Error: listed file not found: $line" >&2
            exit 1
        fi
        TEST_FILES+=("$line")
    done < "$LIST_FILE"
elif $SINGLE_FILE; then
    echo "Testing single file: $TEST_PATH"
    TEST_FILES=("$TEST_PATH")
else
    echo "Testing all .c files in $TEST_PATH..."
    while IFS= read -r f; do
        TEST_FILES+=("$f")
    done < <(find "$TEST_PATH" -name "*.c" \
        ! -name "*.syntax-only.c" \
        ! -name "*.exhaust.c" \
        | sort)
fi

if [[ -n "$EXCLUDE_PATTERN" ]]; then
    filtered=()
    for f in ${TEST_FILES[@]+"${TEST_FILES[@]}"}; do
        bname=$(basename "$f")
        if ! echo "$bname" | grep -q "$EXCLUDE_PATTERN"; then
            filtered+=("$f")
        fi
    done
    TEST_FILES=(${filtered[@]+"${filtered[@]}"})
fi

TOTAL_FILES=${#TEST_FILES[@]}
if [[ $TOTAL_FILES -eq 0 ]]; then
    echo "Error: no test files found (empty corpus is a failure, not a pass)" >&2
    exit 1
fi
echo "Found $TOTAL_FILES test files"

if [[ $MAX_TESTS -gt 0 ]] && ! $SINGLE_FILE; then
    echo "Testing first $MAX_TESTS files"
    TEST_FILES=("${TEST_FILES[@]:0:$MAX_TESTS}")
fi

# ---------------------------------------------------------------------------
# Runners
# ---------------------------------------------------------------------------
# Direct binary invocation (opam exec not needed: --runtime is passed
# explicitly) so `timeout` wraps the real process.
run_ocaml_exec() {  # <file.c>
    timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        --nolibc --exec --batch --mode=exhaustive "$1" 2>&1
}
run_cabs_json() {   # <file.c> <out.json>
    timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        --cabs-json "$1" > "$2" 2>/dev/null
}
run_lean_batch() {  # <file.json>
    LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" \
        "$CERBERUS_LEAN_BIN" --batch "$1" 2>&1
}

# ---------------------------------------------------------------------------
# Verdict-sequence extraction + exit-code expectation (S5f hardening)
# ---------------------------------------------------------------------------
# One canonical token per per-execution verdict line, in output order:
#   Undefined {ub: "X", ...}   -> UB:X
#   Defined {value: "V", ...}  -> VAL:V   (V = Specified(n)/Unspecified(t)/...)
# Anchored on the line-leading 'Undefined {'/'Defined {' markers, so the
# quote-escaped stdout/stderr fields inside a Defined line cannot yield
# tokens (see the spoofing caveat in the header).
extract_verdict_seq() {   # <output>  → token lines on stdout
    printf '%s\n' "$1" \
        | grep -oE 'Undefined \{ub: "[^"]*"|Defined \{value: "[^"]*"' \
        | sed -e 's/^Undefined {ub: "\(.*\)"$/UB:\1/' \
              -e 's/^Defined {value: "\(.*\)"$/VAL:\1/'
    return 0
}

# Expected exit code per OCaml main.ml runM (mirrored by Main.lean):
# multiple executions → 0; single Undefined/Error → 1; single Defined → 0.
expected_exit_for() {   # <output>  → echoes 0 or 1
    if [[ "$1" == *'EXECUTION '* ]]; then
        echo 0
    elif [[ "$1" == *'Undefined {'* || "$1" == *'Error {'* ]]; then
        echo 1
    else
        echo 0
    fi
}

join_seq() {   # <token-lines>  → single line joined with '|'
    printf '%s' "$1" | tr '\n' '|'
}

# ---------------------------------------------------------------------------
# Counters (prototype set) + new crash counter
#
# DISJOINT (arc-6 S5f audit fix): every processed file increments exactly
# one status counter; in particular CERB_SKIP_COUNT counts only files
# recorded CERB_SKIP, and CERB_INCONSISTENT_COUNT only files recorded
# CERB_INCONSISTENT (pre-fix, CERB_INCONSISTENT files were double-counted
# into the skip counter, so SUMMARY cerb_skip overstated by
# cerb_inconsistent). The SUMMARY fields therefore sum to total.
# ---------------------------------------------------------------------------
CERBERUS_OK=0
CERB_SKIP_COUNT=0
LEAN_OK=0
LEAN_FAIL=0
LEAN_TIMEOUT_COUNT=0
LEAN_CRASH_COUNT=0
LEAN_ERROR_COUNT=0
CERB_INCONSISTENT_COUNT=0
MATCH=0
MISMATCH=0
UB_MATCH=0
UB_CODE_DIFF=0
UNSUPPORTED_EXPECTED=0
UNSUPPORTED_UNEXPECTED=0
STATUS_LINES=0

record_status() {   # <basename.c> <STATUS>
    echo "$1 $2" >> "$STATUS_FILE" || { echo "Error: cannot append to $STATUS_FILE" >&2; exit 1; }
    STATUS_LINES=$((STATUS_LINES + 1))
}

echo ""
echo "Running differential execution comparison..."
echo "============================================"

file_num=0
total_to_test=${#TEST_FILES[@]}

for c_file in "${TEST_FILES[@]}"; do
    filename=$(basename "$c_file" .c)
    base_c=$(basename "$c_file")
    file_num=$((file_num + 1))

    expect_unsupported=false
    [[ "$c_file" == *.unsupported.c ]] && expect_unsupported=true

    # --- OCaml cerberus: --exec --batch (exhaustive, nolibc) ---------------
    cerberus_shell_exit=0
    cerberus_output=$(run_ocaml_exec "$c_file") || cerberus_shell_exit=$?

    if [[ $cerberus_shell_exit -eq 124 ]]; then
        CERB_SKIP_COUNT=$((CERB_SKIP_COUNT + 1))
        echo "[$file_num/$total_to_test] CERB_SKIP $filename (Cerberus timeout)"
        record_status "$base_c" CERB_SKIP
        continue
    fi
    if [[ $cerberus_shell_exit -eq 139 ]] || [[ $cerberus_shell_exit -eq 134 ]] || [[ $cerberus_shell_exit -eq 137 ]]; then
        CERB_SKIP_COUNT=$((CERB_SKIP_COUNT + 1))
        echo "[$file_num/$total_to_test] CERB_SKIP $filename (Cerberus crashed: $cerberus_shell_exit)"
        record_status "$base_c" CERB_SKIP
        continue
    fi

    # Extract cerberus verdict from batch output.
    # NOTE (from prototype): use [[ == *pattern* ]] for boolean checks, not
    # echo | grep -q — large outputs + pipefail turn early-exit SIGPIPEs
    # into spurious non-zero results.
    cerberus_has_ub=false
    cerb_seq=""
    if [[ "$cerberus_output" == *'Undefined {'* ]]; then
        cerberus_has_ub=true
        cerb_seq=$(extract_verdict_seq "$cerberus_output")
    elif [[ "$cerberus_output" == *'value: "Specified'* ]] \
      || [[ "$cerberus_output" == *'value: "Unspecified'* ]]; then
        cerb_seq=$(extract_verdict_seq "$cerberus_output")
    elif [[ "$cerberus_output" == *'Error {'* ]]; then
        CERB_SKIP_COUNT=$((CERB_SKIP_COUNT + 1))
        error_msg=$(echo "$cerberus_output" | grep -o 'msg: "[^"]*"' | head -1 | sed 's/msg: "\([^"]*\)"/\1/')
        echo "[$file_num/$total_to_test] CERB_SKIP $filename (error: $error_msg)"
        record_status "$base_c" CERB_SKIP
        continue
    elif [[ $cerberus_shell_exit -ne 0 ]]; then
        CERB_SKIP_COUNT=$((CERB_SKIP_COUNT + 1))
        echo "[$file_num/$total_to_test] CERB_SKIP $filename (exit $cerberus_shell_exit)"
        record_status "$base_c" CERB_SKIP
        continue
    else
        CERB_SKIP_COUNT=$((CERB_SKIP_COUNT + 1))
        echo "[$file_num/$total_to_test] CERB_SKIP $filename (could not extract return value)"
        record_status "$base_c" CERB_SKIP
        continue
    fi
    if [[ -z "$cerb_seq" ]]; then
        echo "HARNESS ERROR: cerberus verdict pattern matched but no tokens extracted for $filename" >&2
        exit 1
    fi

    # S5f H2: exit-code/verdict consistency (see header). Any deviation
    # from the runM-convention expected exit — even with parseable output —
    # is CERB_INCONSISTENT (non-fatal, counted, visible).
    cerb_expected_exit=$(expected_exit_for "$cerberus_output")
    if [[ $cerberus_shell_exit -ne $cerb_expected_exit ]]; then
        CERB_INCONSISTENT_COUNT=$((CERB_INCONSISTENT_COUNT + 1))
        echo "[$file_num/$total_to_test] CERB_INCONSISTENT $filename: output parsed ($(join_seq "$cerb_seq")) but exit=$cerberus_shell_exit (expected $cerb_expected_exit)"
        record_status "$base_c" CERB_INCONSISTENT
        continue
    fi
    CERBERUS_OK=$((CERBERUS_OK + 1))

    # --- Cabs JSON for the Lean pipeline -----------------------------------
    json_file="$OUTPUT_DIR/$filename.json"
    if ! run_cabs_json "$c_file" "$json_file"; then
        CERB_INCONSISTENT_COUNT=$((CERB_INCONSISTENT_COUNT + 1))
        echo "[$file_num/$total_to_test] CERB_INCONSISTENT $filename: exec succeeded but cabs-json failed"
        record_status "$base_c" CERB_INCONSISTENT
        continue
    fi

    # --- Lean pipeline: --batch --------------------------------------------
    lean_exit=0
    lean_output=$(run_lean_batch "$json_file") || lean_exit=$?

    if [[ $lean_exit -eq 124 ]]; then
        if $expect_unsupported; then
            UNSUPPORTED_EXPECTED=$((UNSUPPORTED_EXPECTED + 1))
            echo "[$file_num/$total_to_test] UNSUPPORTED $filename (timeout, expected)"
            record_status "$base_c" UNSUPPORTED
        else
            LEAN_TIMEOUT_COUNT=$((LEAN_TIMEOUT_COUNT + 1))
            echo "[$file_num/$total_to_test] TIMEOUT $filename (Lean >${TIMEOUT_SECS}s)"
            record_status "$base_c" TIMEOUT
        fi
        continue
    fi

    # New vs prototype: crash detection (SIGABRT under LEAN_ABORT_ON_PANIC=1,
    # SIGSEGV, ...). Classify by signal + first PANIC line on stderr.
    if [[ $lean_exit -ge 128 ]]; then
        # arc-10 S4: also capture the loud fuel-exhaustion marker (the
        # arc-3/7 fuel totalization aborts with "lem: fuel exhausted",
        # not a PANIC line — previously showed as "no PANIC line captured")
        crash_kind=$(echo "$lean_output" | grep -m1 -E 'PANIC|fuel exhausted' | cut -c1-120)
        [[ -z "$crash_kind" ]] && crash_kind="(no PANIC line captured)"
        if $expect_unsupported; then
            UNSUPPORTED_EXPECTED=$((UNSUPPORTED_EXPECTED + 1))
            echo "[$file_num/$total_to_test] UNSUPPORTED $filename (crash $lean_exit, expected): $crash_kind"
            record_status "$base_c" UNSUPPORTED
        else
            LEAN_CRASH_COUNT=$((LEAN_CRASH_COUNT + 1))
            echo "[$file_num/$total_to_test] LEAN_CRASH $filename (exit $lean_exit): $crash_kind"
            record_status "$base_c" LEAN_CRASH
        fi
        continue
    fi

    # Extract Lean verdict sequence (S5f H1: full sequence, not head -1).
    lean_has_ub=false
    lean_seq=""
    if [[ "$lean_output" == *'Undefined {'* ]]; then
        lean_has_ub=true
        lean_seq=$(extract_verdict_seq "$lean_output")
    elif [[ "$lean_output" == *'Defined {'* ]]; then
        lean_seq=$(extract_verdict_seq "$lean_output")
    elif [[ "$lean_output" == *'Error {'* ]]; then
        error_msg=$(echo "$lean_output" | grep -o 'msg: "[^"]*"' | head -1 | sed 's/msg: "\([^"]*\)"/\1/')
        if $expect_unsupported; then
            UNSUPPORTED_EXPECTED=$((UNSUPPORTED_EXPECTED + 1))
            echo "[$file_num/$total_to_test] UNSUPPORTED $filename: $error_msg"
            record_status "$base_c" UNSUPPORTED
        else
            LEAN_FAIL=$((LEAN_FAIL + 1))
            echo "[$file_num/$total_to_test] FAIL $filename: $error_msg"
            record_status "$base_c" FAIL
        fi
        continue
    else
        if $expect_unsupported; then
            UNSUPPORTED_EXPECTED=$((UNSUPPORTED_EXPECTED + 1))
            echo "[$file_num/$total_to_test] UNSUPPORTED $filename: unexpected output"
            record_status "$base_c" UNSUPPORTED
        else
            LEAN_FAIL=$((LEAN_FAIL + 1))
            echo "[$file_num/$total_to_test] FAIL $filename: unexpected output: $(echo "$lean_output" | head -3 | tr '\n' ' ')"
            record_status "$base_c" FAIL
        fi
        continue
    fi

    if [[ -z "$lean_seq" ]]; then
        echo "HARNESS ERROR: Lean verdict pattern matched but no tokens extracted for $filename" >&2
        exit 1
    fi

    # S5f H2: exit-code/verdict consistency, Lean side (see header). A
    # nonzero-vs-expected exit is fatal in default mode even though the
    # output parsed (print-then-crash / laundering hole).
    lean_expected_exit=$(expected_exit_for "$lean_output")
    if [[ $lean_exit -ne $lean_expected_exit ]]; then
        if $expect_unsupported; then
            UNSUPPORTED_EXPECTED=$((UNSUPPORTED_EXPECTED + 1))
            echo "[$file_num/$total_to_test] UNSUPPORTED $filename (exit $lean_exit vs expected $lean_expected_exit, expected-unsupported)"
            record_status "$base_c" UNSUPPORTED
        else
            LEAN_ERROR_COUNT=$((LEAN_ERROR_COUNT + 1))
            echo "[$file_num/$total_to_test] LEAN_ERROR $filename: output parsed ($(join_seq "$lean_seq")) but exit=$lean_exit (expected $lean_expected_exit)"
            record_status "$base_c" LEAN_ERROR
        fi
        continue
    fi

    # --- Comparison (S5f H1: full verdict sequences, both sides) -----------
    # Display strings: full joined sequences (single-verdict files look as
    # they always did modulo the token prefix).
    lean_disp=$(join_seq "$lean_seq")
    cerb_disp=$(join_seq "$cerb_seq")
    # Shape = the sequence with UB codes erased (UB positions + all values).
    lean_shape=$(printf '%s\n' "$lean_seq" | sed 's/^UB:.*/UB/')
    cerb_shape=$(printf '%s\n' "$cerb_seq" | sed 's/^UB:.*/UB/')

    if [[ "$lean_seq" == "$cerb_seq" ]]; then
        LEAN_OK=$((LEAN_OK + 1))
        if $lean_has_ub; then
            if $expect_unsupported; then
                UNSUPPORTED_EXPECTED=$((UNSUPPORTED_EXPECTED + 1))
                echo "[$file_num/$total_to_test] UNSUPPORTED $filename: $lean_disp (UB both sides)"
                record_status "$base_c" UNSUPPORTED
            else
                UB_MATCH=$((UB_MATCH + 1))
                echo "[$file_num/$total_to_test] UB_MATCH $filename: $lean_disp"
                record_status "$base_c" UB_MATCH
            fi
        else
            if $expect_unsupported; then
                UNSUPPORTED_UNEXPECTED=$((UNSUPPORTED_UNEXPECTED + 1))
                echo "[$file_num/$total_to_test] UNSUPPORTED_PASS $filename: $lean_disp (expected failure but passed!)"
                record_status "$base_c" UNSUPPORTED_PASS
            else
                MATCH=$((MATCH + 1))
                echo "[$file_num/$total_to_test] MATCH $filename: $lean_disp"
                record_status "$base_c" MATCH
            fi
        fi
        continue
    fi

    # Sequences differ. Expected-unsupported files: any difference is the
    # expected failure.
    if $expect_unsupported; then
        UNSUPPORTED_EXPECTED=$((UNSUPPORTED_EXPECTED + 1))
        echo "[$file_num/$total_to_test] UNSUPPORTED $filename: Lean=$lean_disp Cerberus=$cerb_disp"
        record_status "$base_c" UNSUPPORTED
        continue
    fi

    LEAN_OK=$((LEAN_OK + 1))
    if [[ "$lean_shape" == "$cerb_shape" ]]; then
        # Same length, same UB positions, identical values — only UB codes
        # differ (both detected UB at the same points).
        UB_CODE_DIFF=$((UB_CODE_DIFF + 1))
        echo "[$file_num/$total_to_test] UB_DIFF $filename: Lean=$lean_disp Cerberus=$cerb_disp"
        record_status "$base_c" UB_DIFF
    elif [[ "$lean_has_ub" != "$cerberus_has_ub" ]]; then
        # One-sided UB (prototype DIFF class, now at sequence granularity)
        MISMATCH=$((MISMATCH + 1))
        echo "[$file_num/$total_to_test] DIFF $filename: Lean=$lean_disp Cerberus=$cerb_disp"
        record_status "$base_c" DIFF
    else
        MISMATCH=$((MISMATCH + 1))
        echo "[$file_num/$total_to_test] MISMATCH $filename: Lean=$lean_disp Cerberus=$cerb_disp"
        record_status "$base_c" MISMATCH
    fi
done

# Fail-closed sanity: every processed file must have exactly one status line
if [[ $STATUS_LINES -ne $file_num ]]; then
    echo "" >&2
    echo "HARNESS ERROR: processed $file_num files but recorded $STATUS_LINES statuses" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo "Results Summary"
echo "============================================"
echo ""
echo "Cerberus execution:"
echo "  Success:    $CERBERUS_OK"
echo "  Skipped:    $CERB_SKIP_COUNT"
if [[ $CERB_INCONSISTENT_COUNT -gt 0 ]]; then
    echo "  Inconsist:  $CERB_INCONSISTENT_COUNT (OCaml-side exit/verdict or cabs-json inconsistency — non-fatal, visible; DISJOINT from Skipped)"
fi
echo ""
echo "Lean pipeline (of Cerberus successes):"
echo "  Compared:   $LEAN_OK"
echo "  Failed:     $LEAN_FAIL"
echo "  Crashed:    $LEAN_CRASH_COUNT"
echo "  ExitErr:    $LEAN_ERROR_COUNT (exit code inconsistent with parsed verdict)"
echo "  Timeout:    $LEAN_TIMEOUT_COUNT"
echo ""
echo "Comparison (of both successes):"
echo "  Match:      $MATCH"
echo "  UB Match:   $UB_MATCH (both detected same UB)"
if [[ $UB_CODE_DIFF -gt 0 ]]; then
    echo "  UB Diff:    $UB_CODE_DIFF (both detected UB, different codes)"
fi
echo "  Mismatch:   $MISMATCH (includes one-sided-UB DIFFs)"
echo ""

if [[ $UNSUPPORTED_EXPECTED -gt 0 ]] || [[ $UNSUPPORTED_UNEXPECTED -gt 0 ]]; then
    echo "Unsupported (*.unsupported.c):"
    echo "  Expected:   $UNSUPPORTED_EXPECTED (failed as expected)"
    if [[ $UNSUPPORTED_UNEXPECTED -gt 0 ]]; then
        echo "  Unexpected: $UNSUPPORTED_UNEXPECTED (passed — consider removing .unsupported suffix)"
    fi
    echo ""
fi

TOTAL_MATCH=$((MATCH + UB_MATCH + UB_CODE_DIFF))
TOTAL_COMPARE=$((TOTAL_MATCH + MISMATCH))
if [[ $TOTAL_COMPARE -gt 0 ]]; then
    MATCH_RATE=$((TOTAL_MATCH * 100 / TOTAL_COMPARE))
    echo "Match rate:   ${MATCH_RATE}% (of comparable; UB_DIFF counts as match, per prototype)"
fi

# One-line machine-grepable summary
echo ""
echo "SUMMARY: total=$file_num match=$MATCH ub_match=$UB_MATCH ub_diff=$UB_CODE_DIFF mismatch=$MISMATCH fail=$LEAN_FAIL crash=$LEAN_CRASH_COUNT lean_error=$LEAN_ERROR_COUNT timeout=$LEAN_TIMEOUT_COUNT cerb_skip=$CERB_SKIP_COUNT cerb_inconsistent=$CERB_INCONSISTENT_COUNT"

# ---------------------------------------------------------------------------
# Baseline write / check
# ---------------------------------------------------------------------------
status_rank() {   # rank per status; unknown status = harness error
    case "$1" in
        MATCH|UB_MATCH|UNSUPPORTED_PASS) echo 3 ;;
        UB_DIFF) echo 2 ;;
        MISMATCH|DIFF|UNSUPPORTED) echo 1 ;;
        FAIL|TIMEOUT|LEAN_CRASH|LEAN_ERROR|CERB_SKIP|CERB_INCONSISTENT) echo 0 ;;
        *) echo "HARNESS ERROR: unknown status '$1'" >&2; exit 1 ;;
    esac
}

if [[ -n "$WRITE_BASELINE" ]]; then
    {
        echo "# exec differential baseline — written by test_exec.sh --write-baseline"
        echo "# format: <file.c> <STATUS>   (see test_exec.sh header for the taxonomy)"
        sort "$STATUS_FILE"
    } > "$WRITE_BASELINE" || { echo "Error: cannot write $WRITE_BASELINE" >&2; exit 1; }
    echo ""
    echo "Baseline written: $WRITE_BASELINE ($STATUS_LINES entries)"
fi

if [[ -n "$CHECK_BASELINE" ]]; then
    echo ""
    echo "Checking against baseline: $CHECK_BASELINE"
    declare -A base_map
    base_count=0
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        set -- $line
        if [[ $# -ne 2 ]]; then
            echo "HARNESS ERROR: malformed baseline line: '$line'" >&2
            exit 1
        fi
        status_rank "$2" >/dev/null || exit 1   # validate status name
        base_map["$1"]="$2"
        base_count=$((base_count + 1))
    done < "$CHECK_BASELINE"
    if [[ $base_count -eq 0 ]]; then
        echo "HARNESS ERROR: baseline $CHECK_BASELINE contains no entries" >&2
        exit 1
    fi

    declare -A cur_map
    while IFS= read -r line; do
        set -- $line
        if [[ $# -ne 2 ]]; then
            echo "HARNESS ERROR: malformed status line: '$line'" >&2
            exit 1
        fi
        cur_map["$1"]="$2"
    done < "$STATUS_FILE"

    regressions=0
    improvements=0
    for f in "${!base_map[@]}"; do
        b="${base_map[$f]}"
        if [[ -z "${cur_map[$f]+x}" ]]; then
            echo "REGRESSION: $f in baseline ($b) but not tested in this run"
            regressions=$((regressions + 1))
            continue
        fi
        c="${cur_map[$f]}"
        rb=$(status_rank "$b") || exit 1
        rc=$(status_rank "$c") || exit 1
        if [[ $rc -lt $rb ]]; then
            echo "REGRESSION: $f baseline=$b current=$c"
            regressions=$((regressions + 1))
        elif [[ $rc -gt $rb ]]; then
            echo "improvement: $f baseline=$b current=$c"
            improvements=$((improvements + 1))
        elif [[ "$b" != "$c" ]]; then
            echo "changed (same rank, non-regressing): $f baseline=$b current=$c"
        fi
    done
    # S5f H3: a file ABSENT from the baseline must not launder a failing
    # status (deleting a baseline line would otherwise hide a regression).
    # Failing statuses on new files are FATAL; anything else is reported.
    for f in "${!cur_map[@]}"; do
        if [[ -z "${base_map[$f]+x}" ]]; then
            case "${cur_map[$f]}" in
                MISMATCH|DIFF|FAIL|LEAN_CRASH|LEAN_ERROR|TIMEOUT)
                    echo "REGRESSION: new file (not in baseline) with failing status: $f ${cur_map[$f]}"
                    regressions=$((regressions + 1))
                    ;;
                *)
                    echo "new file (not in baseline, not fatal): $f ${cur_map[$f]}"
                    ;;
            esac
        fi
    done

    echo ""
    echo "Baseline check: $regressions regression(s), $improvements improvement(s)"
    if [[ $regressions -gt 0 ]]; then
        echo -e "${RED}FAILED: regressions vs baseline${NC}"
        exit 1
    fi
    echo -e "${GREEN}BASELINE OK${NC}"
    exit 0
fi

# ---------------------------------------------------------------------------
# Default-mode exit (prototype semantics + fail-closed crash/timeout)
# ---------------------------------------------------------------------------
FATAL=0
if [[ $LEAN_FAIL -gt 0 ]]; then
    echo ""
    echo -e "${RED}FAILED: $LEAN_FAIL Lean pipeline error(s)${NC}"
    FATAL=1
fi
if [[ $LEAN_CRASH_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${RED}FAILED: $LEAN_CRASH_COUNT Lean crash(es)${NC}"
    FATAL=1
fi
if [[ $LEAN_ERROR_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${RED}FAILED: $LEAN_ERROR_COUNT Lean exit/verdict inconsistenc(ies)${NC}"
    FATAL=1
fi
if [[ $LEAN_TIMEOUT_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${RED}FAILED: $LEAN_TIMEOUT_COUNT Lean timeout(s)${NC}"
    FATAL=1
fi
if [[ $MISMATCH -gt 0 ]]; then
    echo ""
    echo -e "${RED}FAILED: $MISMATCH mismatch(es) with Cerberus${NC}"
    FATAL=1
fi
# S5f H4: zero comparisons (every file skipped) is a failure, not a
# vacuous pass.
if [[ $TOTAL_COMPARE -eq 0 ]]; then
    echo ""
    echo -e "${RED}FAILED: zero comparisons happened (all files skipped) — vacuous run${NC}"
    FATAL=1
fi
exit $FATAL
