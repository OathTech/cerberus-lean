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
#     ordered sequence of per-execution verdict tokens (UB:<whole Undefined
#     line body> for each Undefined line — since Z1; VAL:<whole Defined
#     line body> for each Defined line — value, stdout, stderr AND blocked
#     fields, byte-for-byte, since the P0 instrument repair 2026-09-05
#     (whole-project audit F3: before it only `value: "…"` was kept, so two
#     Defined lines with the same value and different stdout/stderr compared
#     MATCH) — Specified and Unspecified alike) and the sequences are
#     compared in full. Identical
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
#   * FUEL (FUEL arc, 2026-09-03; common.sh/fuel_classify.sh
#     classify_fuel_outcome; design lean_frontend/docs/2026-09-02_fuel-arc-
#     design.md §3): a Lean run whose merged output carries the EXACT
#     fuel-exhaustion message as a whole line — the typed kill
#     `Error {msg: "lem: fuel exhausted"}` (an ND-typed fueled worker or
#     the CerbND runner exhausted; exit 1) or, at exit >= 128, the bare
#     panic line `lem: fuel exhausted` (a pure-return worker) — is FUEL,
#     classified AHEAD of the crash / `Error {` branches (it would
#     otherwise read LEAN_CRASH / FAIL). Fatal in default mode, rank 0 in
#     the baseline, fatal on a new file, never MATCH; the .unsupported.c
#     convention does NOT absorb it (a fuel death is never "expected").
#     The message string is reporting-only (no soundness rests on it).
#   * HANG (mem-scale S0, 2026-09-02; common.sh classify_exit124): a Lean
#     exit 124 whose (User+System)/wall < 0.1 — the process stopped
#     consuming CPU long before the timeout (the >7 M-element front-end
#     recursion parks all threads on a futex after ~3-4 s; charter C9).
#     A DISTINCT status from TIMEOUT: fatal in default mode, rank 0 in the
#     baseline, fatal on a new file; never folded into TIMEOUT or a skip.
#     Both driver runs are wrapped in `/usr/bin/time -v -o <record>` so
#     the CPU figure exists; a missing/unparseable record is a harness
#     error, not a TIMEOUT. The oracle side keeps its CERB_SKIP class on
#     exit 124 (the oracle fails LOUDLY on its own stack ceiling — profile
#     §6.3.2 contrast datum) but the CPU/wall ratio is printed in the
#     skip line so an oracle-side hang would be visible in the log.
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
#     quote-ESCAPED (OCaml String.escaped semantics on both printers:
#     driver_ocaml.ml:99, Main.lean batchEscape) inside the Defined line,
#     where the ^-anchored token patterns cannot match; since the P0
#     repair those escaped bytes are PART of the VAL token and are
#     compared, not skipped (--selftest E5 pins that an embedded
#     "Defined {" text yields no extra token). Recorded, not defended
#     further.
#
# Per-file statuses (baseline taxonomy):
#   MATCH UB_MATCH UB_DIFF MISMATCH DIFF FAIL TIMEOUT HANG LEAN_CRASH
#   LEAN_ERROR CERB_SKIP CERB_INCONSISTENT UNSUPPORTED UNSUPPORTED_PASS
#   CERB_FLOOR FUEL
#
#   CERB_FLOOR (arc-12): the oracle REFUSED the TU via the F-D fail-stop
#   floor (stderr token CERB_FRESH_FLOOR_VIOLATION, exit 70 — the TU's
#   desugar id supply exceeds the ambient symbol-id margin; the un-floored
#   oracle would silently corrupt symbol identity). Checked BEFORE every
#   other oracle-failure classification so a floor hit can never be
#   laundered into CERB_SKIP; a floor hit on a file NOT baselined as
#   CERB_FLOOR is FATAL (fail-closed both directions). No Lean-side run is
#   possible for such files (the cabs-json bridge floors identically).
#   Design: lean_frontend/docs/2026-08-21_arc12-s0-floor-design.md §4.4.
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
  --selftest               Hermetic plants on the verdict extractor (no binaries)
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
require_time_bin   # HANG classification needs GNU time (common.sh; fail-closed)

DEFAULT_BASELINE="$SCRIPT_DIR/exec_baseline.txt"

VERBOSE=false
SELFTEST=false
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
        --selftest) SELFTEST=true; shift ;;
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

# ---------------------------------------------------------------------------
# Verdict-sequence extraction + exit-code expectation (S5f hardening)
# ---------------------------------------------------------------------------
# One canonical token per per-execution verdict line, in output order:
#   Undefined {ub: "X", stderr: "S", loc: "L"}                 -> UB:{ub: "X", stderr: "S", loc: "L"}
#   Defined {value: "V", stdout: "O", stderr: "E", blocked: "B"} -> VAL:{value: "V", stdout: "O", stderr: "E", blocked: "B"}
# The UB token is the WHOLE Undefined line since the zero-discrepancy arc
# (2026-09-03, charter lean_frontend/docs/2026-09-03_zero-discrepancy-design.md
# §1.3/§4.1; [USER 2026-09-03] "UB location is behaviour"): the ub code,
# the killed state's stderr AND the loc are compared byte-for-byte —
# Lean renders all three exactly as the oracle (CerbLocation.simpleLocation
# = Cerb_location.simple_location; Main.lean batch printer =
# driver_ocaml.ml:173-181). Until then only the ub code was kept — the
# instrument blind spot behind noodle D1/D2 and the charter's Z-72.
# The VAL token is the WHOLE Defined line since the P0 instrument repair
# (2026-09-05; whole-project audit F3, record
# lean_frontend/docs/2026-09-05_p0-instruments-record.md §F3): value, the
# program's captured stdout and stderr (String.escaped on both printers —
# driver_ocaml.ml:99 / Main.lean batchEscape) and the blocked flag,
# byte-for-byte. Until then only `value: "…"` was kept, so
#   Defined {value: "Specified(0)", stdout: "GOOD", stderr: ""}
#   Defined {value: "Specified(0)", stdout: "BAD", stderr: "WRONG"}
# both mapped to VAL:Specified(0) and compared MATCH (the audit's plant; E1
# below). Both patterns are ^-anchored to the line start, so the
# quote-escaped stdout/stderr fields inside a Defined line cannot yield
# tokens of their own (see the spoofing caveat in the header). grep/sed run
# in the C locale so the escaped (ASCII) bytes are preserved exactly.
# Status-only baselines do not move by this change; ROWS may (a same-value
# stdout/stderr difference is now MISMATCH) — every such movement is a
# finding, never a silent re-record.
extract_verdict_seq() {   # <output>  → token lines on stdout
    printf '%s\n' "$1" \
        | LC_ALL=C grep -oE '^Undefined \{.*\}$|^Defined \{.*\}$' \
        | LC_ALL=C sed -e 's/^Undefined \(.*\)$/UB:\1/' \
                       -e 's/^Defined \(.*\)$/VAL:\1/'
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

# --selftest (P0 2026-09-05): hermetic plants on extract_verdict_seq — no
# binaries, no oracle. Each plant states the exact expected tokens; a plant
# that would also pass under the pre-repair extractor is reproduced against
# that extractor (E0) so the battery cannot be vacuous. Run by test_unit.sh.
selftest_extractor() {
    echo "test_exec: SELFTEST — extract_verdict_seq plants (loud plant banner; no binaries run)"
    local fails=0
    check() {  # <label> <expected-token-lines> <output>
        local got; got=$(extract_verdict_seq "$3")
        if [[ "$got" == "$2" ]]; then
            echo "  PLANT OK   [$1] -> $(join_seq "$got")"
        else
            echo "  PLANT FAIL [$1]:"; echo "      wanted: $(join_seq "$2")"; echo "      got:    $(join_seq "$got")"; fails=$((fails+1))
        fi
    }
    # the audit's exact two lines (evidence verdict-extractor-plant.log)
    local a1='Defined {value: "Specified(0)", stdout: "GOOD", stderr: ""}'
    local a2='Defined {value: "Specified(0)", stdout: "BAD", stderr: "WRONG"}'
    # E0: the PRE-REPAIR extractor (value only, verbatim from the 2026-09-03
    # script) maps the audit pair to identical tokens — the defect reproduced
    old_extract() { printf '%s\n' "$1" | grep -oE '^Undefined \{.*\}$|^Defined \{value: "[^"]*"' | sed -e 's/^Undefined \(.*\)$/UB:\1/' -e 's/^Defined {value: "\(.*\)"$/VAL:\1/'; return 0; }
    if [[ "$(old_extract "$a1")" == "VAL:Specified(0)" && "$(old_extract "$a1")" == "$(old_extract "$a2")" ]]; then
        echo "  PLANT OK   [E0 pre-repair extractor collapses the audit pair to one token: $(old_extract "$a1") == $(old_extract "$a2")]"
    else
        echo "  PLANT FAIL [E0 premise]: the pre-repair extractor did not reproduce the audit's collapse ($(old_extract "$a1") vs $(old_extract "$a2"))"; fails=$((fails+1))
    fi
    # E1: same value, different stdout (+ stderr) — the audit's plant: DIFFERENT tokens, each the whole line body
    check "E1a audit line 1 -> whole-line token" 'VAL:{value: "Specified(0)", stdout: "GOOD", stderr: ""}' "$a1"
    check "E1b audit line 2 -> whole-line token" 'VAL:{value: "Specified(0)", stdout: "BAD", stderr: "WRONG"}' "$a2"
    if [[ "$(extract_verdict_seq "$a1")" != "$(extract_verdict_seq "$a2")" ]]; then
        echo "  PLANT OK   [E1 same-value/different-stdout+stderr lines yield DIFFERENT tokens]"
    else
        echo "  PLANT FAIL [E1 the two audit lines still compare equal]"; fails=$((fails+1))
    fi
    # E2: same value, same stdout, different stderr only (the real 4-field shape)
    local b1='Defined {value: "Specified(3)", stdout: "x", stderr: "", blocked: "false"}'
    local b2='Defined {value: "Specified(3)", stdout: "x", stderr: "warn: y", blocked: "false"}'
    check "E2a" 'VAL:{value: "Specified(3)", stdout: "x", stderr: "", blocked: "false"}' "$b1"
    check "E2b" 'VAL:{value: "Specified(3)", stdout: "x", stderr: "warn: y", blocked: "false"}' "$b2"
    if [[ "$(extract_verdict_seq "$b1")" != "$(extract_verdict_seq "$b2")" ]]; then
        echo "  PLANT OK   [E2 same-value/different-stderr lines yield DIFFERENT tokens]"
    else
        echo "  PLANT FAIL [E2 stderr difference not seen]"; fails=$((fails+1))
    fi
    # E3: escaped payload — escaped quotes, backslashes, \n and \ddd bytes preserved byte-exactly
    local c1='Defined {value: "Specified(1)", stdout: "say \"hi\"\n\\ tab\t \255\000 end", stderr: "", blocked: "false"}'
    check "E3 escaped-quote/backslash/octal payload preserved byte-exactly" 'VAL:{value: "Specified(1)", stdout: "say \"hi\"\n\\ tab\t \255\000 end", stderr: "", blocked: "false"}' "$c1"
    # E4: multi-outcome output (exhaustive mode): tokens in order, one per verdict line
    local m; m=$(printf '%s\n' 'EXECUTION 0 (exit = 0):' 'Defined {value: "Specified(0)", stdout: "a", stderr: "", blocked: "false"}' 'EXECUTION 1:' 'Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<file.c:3:5>"}' 'EXECUTION 2 (exit = 0):' 'Defined {value: "Specified(0)", stdout: "b", stderr: "", blocked: "false"}')
    check "E4 multi-outcome: 3 tokens in order (Defined a / Undefined / Defined b)" "$(printf '%s\n' 'VAL:{value: "Specified(0)", stdout: "a", stderr: "", blocked: "false"}' 'UB:{ub: "UB043_indirection_invalid_value", stderr: "", loc: "<file.c:3:5>"}' 'VAL:{value: "Specified(0)", stdout: "b", stderr: "", blocked: "false"}')" "$m"
    # E5: an embedded (escaped) "Defined {" text inside stdout yields NO extra token (line anchoring)
    local e5='Defined {value: "Specified(0)", stdout: "Defined {value: \"Specified(9)\"}", stderr: "", blocked: "false"}'
    check "E5 embedded escaped Defined text is payload, not a token" 'VAL:{value: "Specified(0)", stdout: "Defined {value: \"Specified(9)\"}", stderr: "", blocked: "false"}' "$e5"
    # E6: Undefined handling unchanged (whole line since Z1)
    check "E6 Undefined whole-line token unchanged" 'UB:{ub: "UB036_exceptional_condition", stderr: "", loc: "<t.c:2:10>"}' 'Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<t.c:2:10>"}'
    # E7: a Defined line with a trailing non-} tail is NOT a token (shape discipline; the printers always end the line with })
    check "E7 no token from a truncated Defined line" '' 'Defined {value: "Specified(0)", stdout: "'
    if (( fails == 0 )); then
        echo "test_exec: SELFTEST OK (E0 pre-repair collapse reproduced; E1-E7: same-value/different-stdout and different-stderr yield distinct whole-line tokens, escaped payload byte-exact, multi-outcome order kept, embedded text is payload, Undefined unchanged, truncated line is no token)"
        return 0
    fi
    echo "test_exec: SELFTEST FAILED ($fails)"; return 1
}
if $SELFTEST; then
    selftest_extractor; exit $?
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
    verify_skip_build_freshness   # C2: stale-driver hazard — stamps must be fresh (fail-closed)
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
# explicitly) so `timeout` wraps the real process. Both driver runs are
# wrapped in `$TIME_BIN -v -o <record>` (mem-scale S0): the rusage record
# feeds the HANG classification; GNU time propagates the exit status
# unchanged (common.sh header) so every classification below is
# untouched.
run_ocaml_exec() {  # <file.c> <time-record>
    "$TIME_BIN" -v -o "$2" timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        --nolibc --exec --batch --mode=exhaustive "$1" 2>&1
}
run_cabs_json() {   # <file.c> <out.json>
    timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        --cabs-json "$1" > "$2" 2>/dev/null
}
run_lean_batch() {  # <file.json> <time-record>
    LEAN_ABORT_ON_PANIC=1 "$TIME_BIN" -v -o "$2" timeout "${TIMEOUT_SECS}s" \
        "$CERBERUS_LEAN_BIN" --batch "$1" 2>&1
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
CERB_FLOOR_COUNT=0
LEAN_OK=0
LEAN_FAIL=0
LEAN_TIMEOUT_COUNT=0
LEAN_HANG_COUNT=0
LEAN_CRASH_COUNT=0
LEAN_FUEL_COUNT=0
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
    cerb_time="$OUTPUT_DIR/$filename.cerb.time"
    cerberus_output=$(run_ocaml_exec "$c_file" "$cerb_time") || cerberus_shell_exit=$?

    if [[ $cerberus_shell_exit -eq 124 ]]; then
        # Class stays CERB_SKIP (header); the CPU/wall ratio is made
        # visible so an oracle-side hang cannot pass unremarked.
        cerb_124=$(classify_exit124 "$cerb_time" "$TIMEOUT_SECS") || exit 1
        CERB_SKIP_COUNT=$((CERB_SKIP_COUNT + 1))
        echo "[$file_num/$total_to_test] CERB_SKIP $filename (Cerberus timeout: $cerb_124)"
        record_status "$base_c" CERB_SKIP
        continue
    fi
    if [[ $cerberus_shell_exit -eq 139 ]] || [[ $cerberus_shell_exit -eq 134 ]] || [[ $cerberus_shell_exit -eq 137 ]]; then
        CERB_SKIP_COUNT=$((CERB_SKIP_COUNT + 1))
        echo "[$file_num/$total_to_test] CERB_SKIP $filename (Cerberus crashed: $cerberus_shell_exit)"
        record_status "$base_c" CERB_SKIP
        continue
    fi

    # arc-13 single-supply backstop (was: the arc-12 F-D floor): the
    # oracle refused the TU — under the renumbered single-supply scheme
    # this NEVER fires on healthy in-tree inputs (the arc-12 margin
    # refusal class is gone); a hit means a re-threaded-supply/counter
    # regression. Distinct bucket, checked before every other
    # oracle-failure path so it can never be laundered into CERB_SKIP;
    # any CERB_FLOOR row is a finding. (The arc-12 warn-only token and
    # the grandfather mode were deleted in arc-13 S1.)
    if [[ "$cerberus_output" == *CERB_FRESH_FLOOR_VIOLATION* ]]; then
        CERB_FLOOR_COUNT=$((CERB_FLOOR_COUNT + 1))
        echo "[$file_num/$total_to_test] CERB_FLOOR $filename (oracle symbol-id floor, exit $cerberus_shell_exit)"
        record_status "$base_c" CERB_FLOOR
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
    lean_time="$OUTPUT_DIR/$filename.lean.time"
    lean_output=$(run_lean_batch "$json_file" "$lean_time") || lean_exit=$?

    if [[ $lean_exit -eq 124 ]]; then
        # HANG vs TIMEOUT (header; common.sh classify_exit124). An
        # unreadable time record is a harness error, never a TIMEOUT.
        lean_124=$(classify_exit124 "$lean_time" "$TIMEOUT_SECS") || exit 1
        if [[ "$lean_124" == HANG* ]]; then
            # A hang is a defect even on an *.unsupported.c file: no
            # output, no exit is never "expected".
            LEAN_HANG_COUNT=$((LEAN_HANG_COUNT + 1))
            echo "[$file_num/$total_to_test] HANG $filename (Lean $lean_124)"
            record_status "$base_c" HANG
        elif $expect_unsupported; then
            UNSUPPORTED_EXPECTED=$((UNSUPPORTED_EXPECTED + 1))
            echo "[$file_num/$total_to_test] UNSUPPORTED $filename (timeout, expected: $lean_124)"
            record_status "$base_c" UNSUPPORTED
        else
            LEAN_TIMEOUT_COUNT=$((LEAN_TIMEOUT_COUNT + 1))
            echo "[$file_num/$total_to_test] TIMEOUT $filename (Lean $lean_124)"
            record_status "$base_c" TIMEOUT
        fi
        continue
    fi

    # FUEL (header; fuel_classify.sh): classified AHEAD of the crash and
    # `Error {` branches, keyed on the exact message. Never absorbed by
    # the .unsupported.c convention.
    fuel_kind=$(classify_fuel_outcome "$lean_exit" "$lean_output")
    if [[ -n "$fuel_kind" ]]; then
        LEAN_FUEL_COUNT=$((LEAN_FUEL_COUNT + 1))
        echo "[$file_num/$total_to_test] FUEL $filename ($fuel_kind, exit $lean_exit): lem: fuel exhausted"
        record_status "$base_c" FUEL
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
if [[ $CERB_FLOOR_COUNT -gt 0 ]]; then
    echo "  Floor:      $CERB_FLOOR_COUNT (oracle symbol-id floor refusals — arc-12 F-D fail-stop; DISJOINT from Skipped)"
fi
if [[ $CERB_INCONSISTENT_COUNT -gt 0 ]]; then
    echo "  Inconsist:  $CERB_INCONSISTENT_COUNT (OCaml-side exit/verdict or cabs-json inconsistency — non-fatal, visible; DISJOINT from Skipped)"
fi
echo ""
echo "Lean pipeline (of Cerberus successes):"
echo "  Compared:   $LEAN_OK"
echo "  Failed:     $LEAN_FAIL"
echo "  Crashed:    $LEAN_CRASH_COUNT"
echo "  Fuel:       $LEAN_FUEL_COUNT (fuel exhaustion — typed kill or pure-worker panic; never agreement)"
echo "  ExitErr:    $LEAN_ERROR_COUNT (exit code inconsistent with parsed verdict)"
echo "  Timeout:    $LEAN_TIMEOUT_COUNT"
echo "  Hang:       $LEAN_HANG_COUNT (exit 124 with CPU/wall < 0.1 — no output, no exit)"
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
echo "SUMMARY: total=$file_num match=$MATCH ub_match=$UB_MATCH ub_diff=$UB_CODE_DIFF mismatch=$MISMATCH fail=$LEAN_FAIL crash=$LEAN_CRASH_COUNT fuel=$LEAN_FUEL_COUNT lean_error=$LEAN_ERROR_COUNT timeout=$LEAN_TIMEOUT_COUNT hang=$LEAN_HANG_COUNT cerb_skip=$CERB_SKIP_COUNT cerb_floor=$CERB_FLOOR_COUNT cerb_inconsistent=$CERB_INCONSISTENT_COUNT"

# ---------------------------------------------------------------------------
# Baseline write / check
# ---------------------------------------------------------------------------
status_rank() {   # rank per status; unknown status = harness error
    case "$1" in
        MATCH|UB_MATCH|UNSUPPORTED_PASS) echo 3 ;;
        UB_DIFF) echo 2 ;;
        MISMATCH|DIFF|UNSUPPORTED) echo 1 ;;
        FAIL|TIMEOUT|HANG|LEAN_CRASH|FUEL|LEAN_ERROR|CERB_SKIP|CERB_INCONSISTENT|CERB_FLOOR) echo 0 ;;
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
                MISMATCH|DIFF|FAIL|LEAN_CRASH|FUEL|LEAN_ERROR|TIMEOUT|HANG|CERB_FLOOR)
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
if [[ $LEAN_FUEL_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${RED}FAILED: $LEAN_FUEL_COUNT Lean fuel exhaustion(s) — the fuel budget is a port artifact; a FUEL row is never agreement${NC}"
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
if [[ $LEAN_HANG_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${RED}FAILED: $LEAN_HANG_COUNT Lean HANG(s) — exit 124 with CPU/wall < 0.1: no output, no exit (charter C9 shape)${NC}"
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
