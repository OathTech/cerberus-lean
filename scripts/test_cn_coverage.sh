#!/bin/bash
# test_cn_coverage.sh — differential coverage sweep over the CN repo's own
# test programs (deps/cn/tests/cn, 213 files, BSD-2-Clause — see
# tests/cn_coverage/README.md for the license/provenance statement):
# OCaml cerberus (fork oracle) vs the full Lean pipeline.
#
# Lane design (arc/cn-coverage, 2026-08-22):
#   * Corpus files are consumed include-by-reference: each is passed BY PATH
#     as its own translation unit to both sides; no corpus text is copied
#     into this repo. Files without a main get a fresh driver TU from
#     tests/cn_coverage/drivers/ linked alongside (the test_multi_tu.sh
#     mechanism: oracle links N .c natively; Lean links N cabs-jsons).
#   * Coverage accounting is FAIL-CLOSED: tests/cn_coverage/manifest.txt must
#     biject with `find` over the corpus (corpus drift fails the run), every
#     referenced extra TU must exist, and every file in drivers//support/
#     must be referenced by some manifest row (orphan drivers fail the run).
#   * Comparison semantics are test_exec.sh's S5f full-verdict-sequence form
#     (UB:<code>/VAL:<value> token sequences; exit-code/verdict consistency
#     both sides), plus a REJECT lane this corpus needs: when the oracle's
#     EXEC refuses the program (Error {...}) but the cabs-json bridge accepts
#     it, the Lean side is still run — both-sides-refuse is REJECT_MATCH
#     (agreement), one-sided refusal is REJECT_DIFF (fatal-if-new). When the
#     bridge itself refuses there is no Lean observation: ORACLE_FAIL.
#   * Baseline (tests/cn_coverage/baseline.txt) is EXACT-MATCH, fail-closed
#     in BOTH directions: any status change vs the committed baseline —
#     regression, improvement, add, or drop — fails --check-baseline.
#     Updating the baseline is a deliberate, reviewed act.
#
# Per-file statuses:
#   agreement:  MATCH UB_MATCH UB_DIFF REJECT_MATCH
#   divergence: DIFF (one-sided UB) MISMATCH (value/shape) REJECT_DIFF
#   lean-side:  LEAN_FAIL LEAN_CRASH LEAN_ERROR LEAN_TIMEOUT FUEL
#               (FUEL: fuel exhaustion — the typed kill `Error {msg: "lem:
#               fuel exhausted"}` or the pure-worker panic line at exit >=
#               128, classified AHEAD of LEAN_CRASH / the Error branch on
#               the exact message; FUEL arc 2026-09-03, common.sh/
#               fuel_classify.sh classify_fuel_outcome; never agreement)
#   oracle-side (no comparison possible): ORACLE_FAIL ORACLE_TIMEOUT
#               ORACLE_INCONSISTENT
#
# Default mode: divergence + lean-side statuses and zero comparisons are
# fatal. Oracle-side statuses are non-fatal in default mode but pinned by
# the baseline (a new ORACLE_* is a baseline diff and fails the gate).
#
# NOTE: intentionally no `set -e` — exit codes are data here (test_exec.sh
# house pattern); every failure path is handled explicitly.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

usage() {
    cat <<'EOF'
Differential coverage sweep: CN corpus (deps/cn/tests/cn), oracle vs Lean.

Usage: ./scripts/test_cn_coverage.sh [options]

Options:
  -v, --verbose            Show both sides' outputs for non-agreement rows
  --only PATTERN           Run only corpus files whose relpath matches (grep)
  --write-baseline[=FILE]  Write statuses (default: tests/cn_coverage/baseline.txt)
  --check-baseline[=FILE]  Exact-match compare vs baseline; ANY diff exits 1
  -h, --help               This help

Environment:
  TIMEOUT_SECS    per-side timeout (default: 30)
  CN_CORPUS_DIR   corpus override (default: walk up from repo root to
                  deps/cn/tests/cn — the container-level vendored CN repo)
  SKIP_BUILD      1 = skip the no-op build steps (binaries must exist)
EOF
    exit 0
}

if ! command -v timeout &>/dev/null; then
    echo "Error: 'timeout' command not found" >&2
    exit 1
fi

COVDIR="$PROJECT_ROOT/tests/cn_coverage"
MANIFEST="$COVDIR/manifest.txt"
DEFAULT_BASELINE="$COVDIR/baseline.txt"

VERBOSE=false
ONLY_PATTERN=""
WRITE_BASELINE=""
CHECK_BASELINE=""
TIMEOUT_SECS="${TIMEOUT_SECS:-30}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -v|--verbose) VERBOSE=true; shift ;;
        --only) ONLY_PATTERN="$2"; shift 2 ;;
        --write-baseline) WRITE_BASELINE="$DEFAULT_BASELINE"; shift ;;
        --write-baseline=*) WRITE_BASELINE="${1#--write-baseline=}"; shift ;;
        --check-baseline) CHECK_BASELINE="$DEFAULT_BASELINE"; shift ;;
        --check-baseline=*) CHECK_BASELINE="${1#--check-baseline=}"; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [[ -n "$WRITE_BASELINE" && -n "$CHECK_BASELINE" ]]; then
    echo "Error: --write-baseline and --check-baseline are mutually exclusive" >&2
    exit 1
fi
if [[ -n "$ONLY_PATTERN" && ( -n "$WRITE_BASELINE" || -n "$CHECK_BASELINE" ) ]]; then
    echo "Error: --only cannot be combined with baseline modes (partial runs must not touch/judge the baseline)" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Locate the corpus (container-level; works from main checkout and worktrees)
# ---------------------------------------------------------------------------
CORPUS=""
if [[ -n "${CN_CORPUS_DIR:-}" ]]; then
    CORPUS="$CN_CORPUS_DIR"
else
    d="$PROJECT_ROOT"
    while [[ "$d" != "/" ]]; do
        if [[ -d "$d/deps/cn/tests/cn" ]]; then
            CORPUS="$d/deps/cn/tests/cn"
            break
        fi
        d=$(dirname "$d")
    done
fi
if [[ -z "$CORPUS" || ! -d "$CORPUS" ]]; then
    echo "Error: CN corpus not found (deps/cn/tests/cn above $PROJECT_ROOT; set CN_CORPUS_DIR)" >&2
    exit 1
fi
CORPUS=$(cd "$CORPUS" && pwd)
if [[ ! -f "$MANIFEST" ]]; then
    echo "Error: manifest not found: $MANIFEST" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Fail-closed coverage accounting
# ---------------------------------------------------------------------------
declare -A ROW_CLASS ROW_EXTRAS
declare -a ROW_ORDER=()
while IFS='|' read -r rel cls extras note; do
    [[ -z "$rel" || "$rel" == \#* ]] && continue
    case "$cls" in
        DIRECT|DRIVEN|ELAB|LINKED) ;;
        *) echo "MANIFEST ERROR: unknown class '$cls' for $rel" >&2; exit 1 ;;
    esac
    if [[ -n "${ROW_CLASS[$rel]+x}" ]]; then
        echo "MANIFEST ERROR: duplicate row for $rel" >&2; exit 1
    fi
    ROW_CLASS["$rel"]="$cls"
    ROW_EXTRAS["$rel"]="$extras"
    ROW_ORDER+=("$rel")
done < "$MANIFEST"

# corpus drift: manifest rows must biject with find over the corpus
CORPUS_LIST=$(cd "$CORPUS" && find . -name '*.c' | sed 's|^\./||' | sort)
MANIFEST_LIST=$(printf '%s\n' "${ROW_ORDER[@]}" | sort)
if [[ "$CORPUS_LIST" != "$MANIFEST_LIST" ]]; then
    echo "COVERAGE ERROR: corpus drift — manifest and corpus disagree:" >&2
    diff <(printf '%s\n' "$CORPUS_LIST") <(printf '%s\n' "$MANIFEST_LIST") >&2
    exit 1
fi

# extras must exist; track referenced driver/support files
declare -A REFERENCED
for rel in "${ROW_ORDER[@]}"; do
    extras="${ROW_EXTRAS[$rel]}"
    [[ -z "$extras" ]] && continue
    IFS=',' read -ra exs <<< "$extras"
    for e in "${exs[@]}"; do
        if [[ "$e" == cn:* ]]; then
            cf="${e#cn:}"
            if [[ ! -f "$CORPUS/$cf" ]]; then
                echo "MANIFEST ERROR: $rel references missing corpus TU $cf" >&2; exit 1
            fi
        else
            if [[ ! -f "$COVDIR/$e" ]]; then
                echo "MANIFEST ERROR: $rel references missing TU $e" >&2; exit 1
            fi
            REFERENCED["$e"]=1
        fi
    done
done
# orphan drivers/support files fail the run
orphans=0
for f in "$COVDIR"/drivers/*.c "$COVDIR"/support/*.c; do
    [[ -e "$f" ]] || continue
    b="${f#"$COVDIR"/}"
    if [[ -z "${REFERENCED[$b]+x}" ]]; then
        echo "COVERAGE ERROR: orphan TU not referenced by any manifest row: $b" >&2
        orphans=$((orphans + 1))
    fi
done
[[ $orphans -gt 0 ]] && exit 1

# ---------------------------------------------------------------------------
# Build both sides (fail-closed); SKIP_BUILD as in test_exec.sh
# ---------------------------------------------------------------------------
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

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/cn-coverage.XXXXXXXXXX") || { echo "Error: mktemp failed" >&2; exit 1; }
register_cleanup "$OUTPUT_DIR"
STATUS_FILE="$OUTPUT_DIR/status.txt"
: > "$STATUS_FILE" || { echo "Error: cannot write $STATUS_FILE" >&2; exit 1; }

# Lean binary locates runtime/libcore relative to cwd
cd "$PROJECT_ROOT" || { echo "Error: cannot cd to $PROJECT_ROOT" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Runners + verdict extraction (lifted from test_exec.sh S5f)
# ---------------------------------------------------------------------------
run_ocaml_exec() {  # <incdir> <file...>
    local inc="$1"; shift
    timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        -I "$inc" --nolibc --exec --batch --mode=exhaustive "$@" 2>&1
}
run_cabs_json() {   # <incdir> <file.c> <out.json>
    timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        -I "$1" --cabs-json "$2" > "$3" 2>/dev/null
}
run_lean_batch() {  # <file.json...>
    LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" \
        "$CERBERUS_LEAN_BIN" --batch "$@" 2>&1
}
extract_verdict_seq() {
    printf '%s\n' "$1" \
        | grep -oE 'Undefined \{ub: "[^"]*"|Defined \{value: "[^"]*"' \
        | sed -e 's/^Undefined {ub: "\(.*\)"$/UB:\1/' \
              -e 's/^Defined {value: "\(.*\)"$/VAL:\1/'
    return 0
}
expected_exit_for() {
    if [[ "$1" == *'EXECUTION '* ]]; then echo 0
    elif [[ "$1" == *'Undefined {'* || "$1" == *'Error {'* ]]; then echo 1
    else echo 0
    fi
}
join_seq() { printf '%s' "$1" | tr '\n' '|'; }

# ---------------------------------------------------------------------------
# Sweep
# ---------------------------------------------------------------------------
declare -A COUNT=()
STATUS_LINES=0
record_status() {   # <relpath> <STATUS>
    echo "$1 $2" >> "$STATUS_FILE" || { echo "Error: cannot append to $STATUS_FILE" >&2; exit 1; }
    COUNT["$2"]=$(( ${COUNT["$2"]:-0} + 1 ))
    STATUS_LINES=$((STATUS_LINES + 1))
}

declare -a RUN_ROWS=()
for rel in "${ROW_ORDER[@]}"; do
    if [[ -n "$ONLY_PATTERN" ]] && ! echo "$rel" | grep -q "$ONLY_PATTERN"; then
        continue
    fi
    RUN_ROWS+=("$rel")
done
if [[ ${#RUN_ROWS[@]} -eq 0 ]]; then
    echo "Error: no corpus files selected (empty run is a failure, not a pass)" >&2
    exit 1
fi

echo ""
echo "CN-corpus differential coverage sweep"
echo "corpus:   $CORPUS"
echo "manifest: ${#ROW_ORDER[@]} rows (DIRECT/DRIVEN/ELAB/LINKED accounted, fail-closed)"
echo "running:  ${#RUN_ROWS[@]} rows"
echo "============================================"

file_num=0
total=${#RUN_ROWS[@]}
for rel in "${RUN_ROWS[@]}"; do
    file_num=$((file_num + 1))
    cls="${ROW_CLASS[$rel]}"
    extras="${ROW_EXTRAS[$rel]}"
    corpus_abs="$CORPUS/$rel"
    incdir=$(dirname "$corpus_abs")

    # TU list: corpus file first, then extras in manifest order
    declare -a tus=("$corpus_abs")
    if [[ -n "$extras" ]]; then
        IFS=',' read -ra exs <<< "$extras"
        for e in "${exs[@]}"; do
            if [[ "$e" == cn:* ]]; then tus+=("$CORPUS/${e#cn:}")
            else tus+=("$COVDIR/$e"); fi
        done
    fi

    # --- oracle exec --------------------------------------------------------
    cerb_exit=0
    cerb_out=$(run_ocaml_exec "$incdir" "${tus[@]}") || cerb_exit=$?

    if [[ $cerb_exit -eq 124 ]]; then
        echo "[$file_num/$total] ORACLE_TIMEOUT $rel"
        record_status "$rel" ORACLE_TIMEOUT
        continue
    fi
    if [[ $cerb_exit -ge 128 ]]; then
        echo "[$file_num/$total] ORACLE_FAIL $rel (oracle crashed: $cerb_exit)"
        record_status "$rel" ORACLE_FAIL
        continue
    fi
    if [[ "$cerb_out" == *CERB_FRESH_FLOOR_VIOLATION* ]]; then
        # arc-13 single-supply backstop: never expected here; distinct + loud
        echo "[$file_num/$total] ORACLE_FAIL $rel (SYMBOL-ID FLOOR — investigate)"
        record_status "$rel" ORACLE_FAIL
        continue
    fi

    oracle_rejects=false
    cerb_has_ub=false
    cerb_seq=""
    if [[ "$cerb_out" == *'Undefined {'* ]]; then
        cerb_has_ub=true
        cerb_seq=$(extract_verdict_seq "$cerb_out")
    elif [[ "$cerb_out" == *'value: "Specified'* || "$cerb_out" == *'value: "Unspecified'* ]]; then
        cerb_seq=$(extract_verdict_seq "$cerb_out")
    elif [[ "$cerb_out" == *'Error {'* ]]; then
        oracle_rejects=true
    elif [[ $cerb_exit -ne 0 ]]; then
        emsg=$(printf '%s\n' "$cerb_out" | head -2 | tr '\n' ' ' | cut -c1-140)
        echo "[$file_num/$total] ORACLE_FAIL $rel (exit $cerb_exit: $emsg)"
        record_status "$rel" ORACLE_FAIL
        continue
    else
        echo "[$file_num/$total] ORACLE_FAIL $rel (no verdict extracted)"
        record_status "$rel" ORACLE_FAIL
        continue
    fi

    if ! $oracle_rejects; then
        if [[ -z "$cerb_seq" ]]; then
            echo "HARNESS ERROR: oracle verdict pattern matched but no tokens for $rel" >&2
            exit 1
        fi
        cerb_expected_exit=$(expected_exit_for "$cerb_out")
        if [[ $cerb_exit -ne $cerb_expected_exit ]]; then
            echo "[$file_num/$total] ORACLE_INCONSISTENT $rel (parsed $(join_seq "$cerb_seq") but exit=$cerb_exit, expected $cerb_expected_exit)"
            record_status "$rel" ORACLE_INCONSISTENT
            continue
        fi
    fi

    # --- cabs-json bridge (one json per TU) ---------------------------------
    declare -a jsons=()
    bridge_fail=false
    ti=0
    for tu in "${tus[@]}"; do
        ti=$((ti + 1))
        j="$OUTPUT_DIR/tu_${file_num}_${ti}.json"
        if ! run_cabs_json "$incdir" "$tu" "$j"; then
            bridge_fail=true
            break
        fi
        jsons+=("$j")
    done
    if $bridge_fail; then
        if $oracle_rejects; then
            # exec refused AND the bridge refuses: no Lean observation possible
            emsg=$(printf '%s\n' "$cerb_out" | grep -o 'msg: "[^"]*"' | head -1 | cut -c1-120)
            echo "[$file_num/$total] ORACLE_FAIL $rel (exec rejected + cabs-json refused; $emsg)"
            record_status "$rel" ORACLE_FAIL
        else
            echo "[$file_num/$total] ORACLE_INCONSISTENT $rel (exec succeeded but cabs-json failed on ${tus[$((ti-1))]})"
            record_status "$rel" ORACLE_INCONSISTENT
        fi
        continue
    fi

    # --- Lean pipeline ------------------------------------------------------
    lean_exit=0
    lean_out=$(run_lean_batch "${jsons[@]}") || lean_exit=$?

    if [[ $lean_exit -eq 124 ]]; then
        echo "[$file_num/$total] LEAN_TIMEOUT $rel (>${TIMEOUT_SECS}s)"
        record_status "$rel" LEAN_TIMEOUT
        continue
    fi
    fuel_kind=$(classify_fuel_outcome "$lean_exit" "$lean_out")
    if [[ -n "$fuel_kind" ]]; then
        echo "[$file_num/$total] FUEL $rel ($fuel_kind, exit $lean_exit): lem: fuel exhausted"
        record_status "$rel" FUEL
        continue
    fi
    if [[ $lean_exit -ge 128 ]]; then
        crash_kind=$(echo "$lean_out" | grep -m1 -E 'PANIC|fuel exhausted' | cut -c1-120)
        [[ -z "$crash_kind" ]] && crash_kind="(no PANIC line captured)"
        echo "[$file_num/$total] LEAN_CRASH $rel (exit $lean_exit): $crash_kind"
        record_status "$rel" LEAN_CRASH
        continue
    fi

    lean_rejects=false
    lean_has_ub=false
    lean_seq=""
    if [[ "$lean_out" == *'Undefined {'* ]]; then
        lean_has_ub=true
        lean_seq=$(extract_verdict_seq "$lean_out")
    elif [[ "$lean_out" == *'Defined {'* ]]; then
        lean_seq=$(extract_verdict_seq "$lean_out")
    elif [[ "$lean_out" == *'Error {'* ]]; then
        lean_rejects=true
    else
        echo "[$file_num/$total] LEAN_FAIL $rel (unexpected output: $(echo "$lean_out" | head -2 | tr '\n' ' ' | cut -c1-140))"
        record_status "$rel" LEAN_FAIL
        continue
    fi

    # --- REJECT lane --------------------------------------------------------
    if $oracle_rejects || $lean_rejects; then
        cmsg=$(printf '%s\n' "$cerb_out" | grep -o 'msg: "[^"]*"' | head -1 | cut -c1-100)
        lmsg=$(printf '%s\n' "$lean_out" | grep -o 'msg: "[^"]*"' | head -1 | cut -c1-100)
        if $oracle_rejects && $lean_rejects; then
            echo "[$file_num/$total] REJECT_MATCH $rel (both refuse; oracle: $cmsg)"
            record_status "$rel" REJECT_MATCH
        elif $oracle_rejects; then
            echo "[$file_num/$total] REJECT_DIFF $rel (oracle refuses: $cmsg; Lean runs: $(join_seq "$lean_seq"))"
            record_status "$rel" REJECT_DIFF
        else
            echo "[$file_num/$total] REJECT_DIFF $rel (Lean refuses: $lmsg; oracle runs: $(join_seq "$cerb_seq"))"
            record_status "$rel" REJECT_DIFF
        fi
        if $VERBOSE; then
            echo "  --- oracle output:"; printf '%s\n' "$cerb_out" | head -10 | sed 's/^/  /'
            echo "  --- lean output:";   printf '%s\n' "$lean_out" | head -10 | sed 's/^/  /'
        fi
        continue
    fi

    if [[ -z "$lean_seq" ]]; then
        echo "HARNESS ERROR: Lean verdict pattern matched but no tokens for $rel" >&2
        exit 1
    fi
    lean_expected_exit=$(expected_exit_for "$lean_out")
    if [[ $lean_exit -ne $lean_expected_exit ]]; then
        echo "[$file_num/$total] LEAN_ERROR $rel (parsed $(join_seq "$lean_seq") but exit=$lean_exit, expected $lean_expected_exit)"
        record_status "$rel" LEAN_ERROR
        continue
    fi

    # --- comparison (full verdict sequences) --------------------------------
    lean_disp=$(join_seq "$lean_seq")
    cerb_disp=$(join_seq "$cerb_seq")
    lean_shape=$(printf '%s\n' "$lean_seq" | sed 's/^UB:.*/UB/')
    cerb_shape=$(printf '%s\n' "$cerb_seq" | sed 's/^UB:.*/UB/')

    if [[ "$lean_seq" == "$cerb_seq" ]]; then
        if $lean_has_ub; then
            echo "[$file_num/$total] UB_MATCH $rel: $lean_disp"
            record_status "$rel" UB_MATCH
        else
            echo "[$file_num/$total] MATCH $rel: $lean_disp"
            record_status "$rel" MATCH
        fi
        continue
    fi
    if [[ "$lean_shape" == "$cerb_shape" ]]; then
        echo "[$file_num/$total] UB_DIFF $rel: Lean=$lean_disp Cerberus=$cerb_disp"
        record_status "$rel" UB_DIFF
    elif [[ "$lean_has_ub" != "$cerb_has_ub" ]]; then
        echo "[$file_num/$total] DIFF $rel: Lean=$lean_disp Cerberus=$cerb_disp"
        record_status "$rel" DIFF
    else
        echo "[$file_num/$total] MISMATCH $rel: Lean=$lean_disp Cerberus=$cerb_disp"
        record_status "$rel" MISMATCH
    fi
    if $VERBOSE; then
        echo "  --- oracle output:"; printf '%s\n' "$cerb_out" | head -10 | sed 's/^/  /'
        echo "  --- lean output:";   printf '%s\n' "$lean_out" | head -10 | sed 's/^/  /'
    fi
done

if [[ $STATUS_LINES -ne $file_num ]]; then
    echo "HARNESS ERROR: processed $file_num rows but recorded $STATUS_LINES statuses" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Summary + agreement headline
# ---------------------------------------------------------------------------
g() { echo "${COUNT[$1]:-0}"; }
AGREE=$(( $(g MATCH) + $(g UB_MATCH) + $(g UB_DIFF) + $(g REJECT_MATCH) ))
DIVERGE=$(( $(g DIFF) + $(g MISMATCH) + $(g REJECT_DIFF) ))
LEAN_SIDE=$(( $(g LEAN_FAIL) + $(g LEAN_CRASH) + $(g FUEL) + $(g LEAN_ERROR) + $(g LEAN_TIMEOUT) ))
ORACLE_SIDE=$(( $(g ORACLE_FAIL) + $(g ORACLE_TIMEOUT) + $(g ORACLE_INCONSISTENT) ))
COMPARED=$(( AGREE + DIVERGE ))

echo ""
echo "============================================"
echo "Results Summary"
echo "============================================"
echo "Agreement:"
echo "  MATCH:         $(g MATCH)"
echo "  UB_MATCH:      $(g UB_MATCH)"
echo "  UB_DIFF:       $(g UB_DIFF) (same UB positions/values, different codes)"
echo "  REJECT_MATCH:  $(g REJECT_MATCH) (both sides refuse the program)"
echo "Divergence:"
echo "  DIFF:          $(g DIFF) (one-sided UB)"
echo "  MISMATCH:      $(g MISMATCH)"
echo "  REJECT_DIFF:   $(g REJECT_DIFF) (one side refuses, other runs)"
echo "Lean-side failures:"
echo "  LEAN_FAIL:     $(g LEAN_FAIL)  LEAN_CRASH: $(g LEAN_CRASH)  FUEL: $(g FUEL)  LEAN_ERROR: $(g LEAN_ERROR)  LEAN_TIMEOUT: $(g LEAN_TIMEOUT)"
echo "Oracle-side (no comparison possible):"
echo "  ORACLE_FAIL:   $(g ORACLE_FAIL)  ORACLE_TIMEOUT: $(g ORACLE_TIMEOUT)  ORACLE_INCONSISTENT: $(g ORACLE_INCONSISTENT)"
echo ""
echo "Agreement tally: $AGREE/$COMPARED compared ($file_num run, $ORACLE_SIDE oracle-side unobservable)"
echo ""
echo "SUMMARY: total=$file_num match=$(g MATCH) ub_match=$(g UB_MATCH) ub_diff=$(g UB_DIFF) reject_match=$(g REJECT_MATCH) diff=$(g DIFF) mismatch=$(g MISMATCH) reject_diff=$(g REJECT_DIFF) lean_fail=$(g LEAN_FAIL) lean_crash=$(g LEAN_CRASH) fuel=$(g FUEL) lean_error=$(g LEAN_ERROR) lean_timeout=$(g LEAN_TIMEOUT) oracle_fail=$(g ORACLE_FAIL) oracle_timeout=$(g ORACLE_TIMEOUT) oracle_inconsistent=$(g ORACLE_INCONSISTENT)"

# ---------------------------------------------------------------------------
# Baseline write / exact-match check
# ---------------------------------------------------------------------------
if [[ -n "$WRITE_BASELINE" ]]; then
    {
        echo "# cn_coverage differential baseline — written by test_cn_coverage.sh --write-baseline"
        echo "# format: <corpus relpath> <STATUS>  (exact-match checked: ANY diff fails)"
        sort "$STATUS_FILE"
    } > "$WRITE_BASELINE" || { echo "Error: cannot write $WRITE_BASELINE" >&2; exit 1; }
    echo ""
    echo "Baseline written: $WRITE_BASELINE ($STATUS_LINES entries)"
fi

if [[ -n "$CHECK_BASELINE" ]]; then
    if [[ ! -f "$CHECK_BASELINE" ]]; then
        echo "Error: baseline file not found: $CHECK_BASELINE" >&2
        exit 1
    fi
    echo ""
    echo "Checking against baseline (exact match, fail-closed both directions): $CHECK_BASELINE"
    base_body=$(grep -v '^#' "$CHECK_BASELINE" | grep -v '^$' | sort)
    cur_body=$(sort "$STATUS_FILE")
    if [[ -z "$base_body" ]]; then
        echo "HARNESS ERROR: baseline contains no entries" >&2
        exit 1
    fi
    if [[ "$base_body" == "$cur_body" ]]; then
        echo -e "${GREEN}BASELINE OK${NC} ($STATUS_LINES entries, exact match)"
        exit 0
    fi
    echo "BASELINE DIVERGENCE (any change — regression, improvement, add, drop — is fatal):"
    diff <(printf '%s\n' "$base_body") <(printf '%s\n' "$cur_body") | sed 's/^/  /'
    echo -e "${RED}FAILED: statuses differ from committed baseline${NC}"
    exit 1
fi

# ---------------------------------------------------------------------------
# Default-mode exit
# ---------------------------------------------------------------------------
FATAL=0
if [[ $DIVERGE -gt 0 ]]; then
    echo -e "${RED}FAILED: $DIVERGE divergence(s) (DIFF/MISMATCH/REJECT_DIFF)${NC}"
    FATAL=1
fi
if [[ $LEAN_SIDE -gt 0 ]]; then
    echo -e "${RED}FAILED: $LEAN_SIDE Lean-side failure(s)${NC}"
    FATAL=1
fi
if [[ $COMPARED -eq 0 ]]; then
    echo -e "${RED}FAILED: zero comparisons happened — vacuous run${NC}"
    FATAL=1
fi
exit $FATAL
