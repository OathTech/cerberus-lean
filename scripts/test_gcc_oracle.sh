#!/bin/bash
# test_gcc_oracle.sh — gcc SECOND-ORACLE differential lane (2026-08-30).
#
# The first oracle-INDEPENDENT witness for the semantics: gcc-compiled
# native execution vs the Lean pipeline, on programs whose behaviour is
# fully determined by C11 + implementation-defined choices on which
# Cerberus and gcc agree. Design, comparability criteria, divergence
# taxonomy, and honest scoping:
#   lean_frontend/docs/2026-08-30_gcc-second-oracle-design.md
#
# REPORTING-TIER lane (LADDER.md Tier-C style): NOT wired into
# test_unit.sh or any gating battery — gating status is an operator
# decision at merge.
#
# Mechanism per file (design note §3):
#   * native: gcc -O0 -w, run twice under timeout+ulimit (exit status =
#     the observable; double-run catches ASLR nondeterminism; nonempty
#     stdout is outside the modeled observable -> skip);
#   * Lean: cerberus --cabs-json -> cerberus-lean --batch (exhaustive)
#     or --batch --first (csmith tier; measured necessity, note §5.2),
#     with test_exec.sh's verdict-token extraction + exit/verdict
#     consistency checks;
#   * compare: native exit vs { ((n mod 256)+256) mod 256 :
#     Specified(n) in the verdict set }. Singleton+equal -> AGREE;
#     member of larger set -> AGREE_ND; else DISAGREE (fatal unless
#     carried by the fail-closed triage ledger);
#   * -O2 spot tier: ~1-in-O2_STRIDE of the agreeing files (name-keyed:
#     cksum(row key) mod O2_STRIDE == 0, phase-stable under status flips
#     and corpus insertions) additionally at gcc -O2
#     -fno-strict-aliasing (rationale: note §3.4).
#
# Row keys: corpus files are keyed by their PROJECT_ROOT-relative path
# (basenames collide across corpora — e.g. 013-compare-lt.c in both
# tests/minimal and tests/float); staged csmith files by
# csmith/<sia_|sa_|smx_ prefixed basename> (stable across stagings,
# matching test_csmith_corpus.sh's prefix scheme).
#
# Statuses (col 2; the baseline file is the SKIP LEDGER — every corpus
# file gets exactly one row, silent skips are forbidden):
#   AGREE AGREE_ND                          — compared, agreeing
#   DISAGREE                                — compared, disagreeing (FATAL)
#   TRIAGED_ADDR TRIAGED_FLOAT TRIAGED_UB TRIAGED_ORDER
#     — the file is declared a divergence-class observer by a justified
#       entry in the triage ledger (scripts/gcc_oracle_triage.txt);
#       classes = design note §4. BY-FILE semantics (2026-08-30 audit
#       follow-up + ruling): a listed file is ALWAYS TRIAGED_*, even if
#       its values happen to coincide (layout coincidence is not
#       agreement). Each entry PINS the observed value pair (mandatory
#       'gcc=<exit>' and 'lean={<byte-set>}' fields); on any drift from
#       the pins the row surfaces as an unresolved DISAGREE (fatal, row
#       named) forcing re-triage. Fail-closed both ways: unlisted
#       DISAGREE is fatal; a listed file that no longer reaches the
#       compare stage (stale entry) is fatal.
#   SKIP_UB          — Lean verdict contains UB (UB-in-test: native run
#                      is unconstrained by the standard)
#   SKIP_UNSPEC      — Lean verdict has an Unspecified value
#   SKIP_LEAN_FAIL / SKIP_LEAN_CRASH / SKIP_LEAN_TIMEOUT / SKIP_LEAN_EXIT
#                    — Lean side unavailable (error / crash / timeout /
#                      exit-verdict inconsistency)
#   SKIP_ORACLE      — cabs-json frontend failed (incl. floor refusal)
#   SKIP_GCC_COMPILE / SKIP_GCC_TIMEOUT / SKIP_GCC_STDOUT / SKIP_NATIVE_NONDET
#   SKIP_VALUE_RANGE — Specified payload not a parseable 64-bit integer
# O2 column (col 3): O2_AGREE O2_AGREE_ND O2_DISAGREE(FATAL)
#   O2_SKIP_COMPILE O2_SKIP_TIMEOUT O2_SKIP_STDOUT O2_SKIP_NONDET,
#   or '-' (file not in the -O2 tier / not compared at -O0).
#
# Known sensitivity caveats (deliberate, design note §2):
#   * mod-256 aliasing of the exit-status observable;
#   * exit(124) vs timeout-kill collision, disambiguated by elapsed
#     time (see gcc_run; found live on the csmith corpus);
#   * bash cannot distinguish exit(128+k) from death-by-signal-k: a
#     signal death whose 128+k coincides with the expected byte would
#     count AGREE (rare; recorded, not defended);
#   * the double-run nondet check is one-sided (ASLR-stable
#     address-derived results still reach triage class D2/ADDR).
#
# Usage: ./scripts/test_gcc_oracle.sh [options] [corpus_dir ...]
#   corpus_dir ...           exhaustive-tier corpus dirs (default when no
#                            dirs and --no-csmith not given: tests/minimal
#                            tests/debug tests/float tests/immaculate/nolibc
#                            + the staged csmith tier)
#   --csmith                 include the staged in-tree csmith tier
#                            (sia_/sa_/smx_ prefixes, Lean --first)
#   --no-csmith              default corpus without the csmith tier
#   --max N                  first N files of each tier (smoke)
#   --o2-stride N            -O2 spot tier density: file selected iff
#                            cksum(key) mod N == 0 (default 10; 0 = off)
#   --write-baseline[=FILE]  write scripts/gcc_oracle_baseline.txt
#   --check-baseline[=FILE]  fail-closed compare (full runs only)
#   -h, --help
# Environment:
#   TIMEOUT_SECS       Lean-side + cabs-json timeout (default 30)
#   GCC_RUN_TIMEOUT    native run timeout, seconds (default 5)
#   GCC_BIN            compiler (default /usr/bin/gcc)
#   SKIP_BUILD=1       binaries must already exist (fail-closed)
#
# NOTE: no `set -e` — exit codes are data; every failure path handled
# explicitly (harness-internal errors exit 1, fail-closed).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

usage() { sed -n '2,98p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

command -v timeout &>/dev/null || { echo "Error: 'timeout' not found" >&2; exit 1; }
command -v setarch &>/dev/null || { echo "Error: 'setarch' not found (needed for ASLR-off native runs)" >&2; exit 1; }
setarch -R true 2>/dev/null || { echo "Error: 'setarch -R' not permitted here" >&2; exit 1; }
GCC_BIN="${GCC_BIN:-/usr/bin/gcc}"
[[ -x "$GCC_BIN" ]] || { echo "Error: gcc not found/executable at $GCC_BIN" >&2; exit 1; }

DEFAULT_BASELINE="$SCRIPT_DIR/gcc_oracle_baseline.txt"
TRIAGE_FILE="$SCRIPT_DIR/gcc_oracle_triage.txt"

TIMEOUT_SECS="${TIMEOUT_SECS:-30}"
GCC_RUN_TIMEOUT="${GCC_RUN_TIMEOUT:-5}"
GCC_COMPILE_TIMEOUT=30
ULIMIT_KB=4000000

WRITE_BASELINE=""
CHECK_BASELINE=""
MAX_TESTS=0
O2_STRIDE=10
WANT_CSMITH=auto
declare -a CORPUS_DIRS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        --csmith) WANT_CSMITH=yes; shift ;;
        --no-csmith) WANT_CSMITH=no; shift ;;
        --max) MAX_TESTS="$2"; shift 2 ;;
        --o2-stride) O2_STRIDE="$2"; shift 2 ;;
        --write-baseline) WRITE_BASELINE="$DEFAULT_BASELINE"; shift ;;
        --write-baseline=*) WRITE_BASELINE="${1#--write-baseline=}"; shift ;;
        --check-baseline) CHECK_BASELINE="$DEFAULT_BASELINE"; shift ;;
        --check-baseline=*) CHECK_BASELINE="${1#--check-baseline=}"; shift ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) CORPUS_DIRS+=("$1"); shift ;;
    esac
done
[[ -n "$WRITE_BASELINE" && -n "$CHECK_BASELINE" ]] \
    && { echo "Error: --write-baseline and --check-baseline are mutually exclusive" >&2; exit 1; }
if [[ -n "$CHECK_BASELINE" && ( $MAX_TESTS -gt 0 || ${#CORPUS_DIRS[@]} -gt 0 || "$WANT_CSMITH" == no ) ]]; then
    echo "Error: --check-baseline is defined for the full default corpus only (no --max / dirs / --no-csmith)" >&2
    exit 1
fi

abspath_dir() { (cd "$1" 2>/dev/null && pwd); }

# Default corpus resolution
if [[ ${#CORPUS_DIRS[@]} -eq 0 ]]; then
    CORPUS_DIRS=(tests/minimal tests/debug tests/float tests/immaculate/nolibc)
    [[ "$WANT_CSMITH" == auto ]] && WANT_CSMITH=yes
else
    [[ "$WANT_CSMITH" == auto ]] && WANT_CSMITH=no
fi
resolved=()
for d in "${CORPUS_DIRS[@]}"; do
    ad=$(abspath_dir "$d") || { echo "Error: corpus dir not found: $d" >&2; exit 1; }
    [[ -n "$ad" ]] || { echo "Error: corpus dir not found: $d" >&2; exit 1; }
    resolved+=("$ad")
done
CORPUS_DIRS=("${resolved[@]}")

if [[ -n "$CHECK_BASELINE" ]]; then
    [[ -f "$CHECK_BASELINE" ]] || { echo "Error: baseline not found: $CHECK_BASELINE" >&2; exit 1; }
fi

# Builds (fail-closed; SKIP_BUILD honored per test_exec.sh idiom)
if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    [[ -f "$CERBERUS_BIN" ]] || { echo "Error: SKIP_BUILD=1 but $CERBERUS_BIN missing" >&2; exit 1; }
    [[ -f "$CERBERUS_LEAN_BIN" ]] || { echo "Error: SKIP_BUILD=1 but $CERBERUS_LEAN_BIN missing" >&2; exit 1; }
else
    build_cerberus
    build_lean
fi
RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
[[ -d "$RUNTIME_DIR" ]] || { echo "Error: runtime dir not found: $RUNTIME_DIR" >&2; exit 1; }

WORK=$(mktemp -d "$TMP_DIR/gcc-oracle.XXXXXXXXXX") || { echo "Error: mktemp failed" >&2; exit 1; }
register_cleanup "$WORK"
STATUS_FILE="$WORK/status.txt"
: > "$STATUS_FILE" || { echo "Error: cannot write $STATUS_FILE" >&2; exit 1; }
cd "$PROJECT_ROOT" || { echo "Error: cannot cd $PROJECT_ROOT" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Triage ledger (fail-closed both directions, design note §4)
# ---------------------------------------------------------------------------
declare -A TRIAGE TRIAGE_GCC TRIAGE_LEAN TRIAGE_USED
if [[ -f "$TRIAGE_FILE" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        # Word-split the ledger line WITHOUT pathname expansion
        # (trust-basket item e, audit note): unquoted $line is the
        # intended field splitter, but a glob character in the
        # free-text rationale (e.g. '*' or '?') would silently expand
        # against the cwd and corrupt the parsed fields. set -f scopes
        # globbing off around exactly this split.
        set -f
        set -- $line
        set +f
        # Mandatory pinned-value fields (audit follow-up, design note §4):
        # <key> <CLASS> gcc=<exit> lean={<byte-set>} <rationale...>
        [[ $# -ge 5 ]] || { echo "HARNESS ERROR: triage line needs '<key> <CLASS> gcc=<exit> lean={<set>} <rationale>': $line" >&2; exit 1; }
        case "$2" in
            TRIAGED_ADDR|TRIAGED_FLOAT|TRIAGED_UB|TRIAGED_ORDER) ;;
            *) echo "HARNESS ERROR: unknown triage class '$2' in: $line" >&2; exit 1 ;;
        esac
        [[ "$3" =~ ^gcc=[0-9]{1,3}$ ]] \
            || { echo "HARNESS ERROR: triage field 3 must be gcc=<exit-byte>, got '$3' in: $line" >&2; exit 1; }
        [[ "$4" =~ ^lean=\{[0-9]{1,3}(,[0-9]{1,3})*\}$ ]] \
            || { echo "HARNESS ERROR: triage field 4 must be lean={<byte-set>}, got '$4' in: $line" >&2; exit 1; }
        [[ -n "${TRIAGE[$1]+x}" ]] && { echo "HARNESS ERROR: duplicate triage entry for $1" >&2; exit 1; }
        TRIAGE["$1"]="$2"
        TRIAGE_GCC["$1"]="${3#gcc=}"
        TRIAGE_LEAN["$1"]="${4#lean=}"
    done < "$TRIAGE_FILE"
fi

# ---------------------------------------------------------------------------
# Collect the file list: "<path>\t<mode>\t<key>"  (mode: exh | first;
# key = stable row key, see header)
# ---------------------------------------------------------------------------
LIST="$WORK/files.list"
: > "$LIST"
for d in "${CORPUS_DIRS[@]}"; do
    n_before=$(wc -l < "$LIST")
    while IFS= read -r f; do
        printf '%s\texh\t%s\n' "$f" "${f#"$PROJECT_ROOT"/}" >> "$LIST"
    done < <(find "$d" -maxdepth 1 -name '*.c' \
        ! -name '*.syntax-only.c' ! -name '*.exhaust.c' | sort)
    n_after=$(wc -l < "$LIST")
    [[ $n_after -gt $n_before ]] || { echo "Error: no .c files in corpus dir $d" >&2; exit 1; }
done

if [[ "$WANT_CSMITH" == yes ]]; then
    HDR="$PROJECT_ROOT/tests/csmith"
    [[ -f "$HDR/csmith_cerberus.h" && -f "$HDR/safe_math.h" ]] \
        || { echo "Error: csmith shim headers missing under $HDR" >&2; exit 1; }
    STAGE="$WORK/csmith-stage"
    mkdir -p "$STAGE" || exit 1
    cp "$HDR/csmith_cerberus.h" "$HDR/safe_math.h" "$STAGE/" || exit 1
    # Same materialization + prefixing as test_csmith_corpus.sh (basenames
    # collide across the three sub-corpora; baselines are keyed by basename)
    for sub_pfx in "small_int_arith sia" "small_arrays sa" "small_mix smx"; do
        sub="${sub_pfx% *}"; pfx="${sub_pfx#* }"
        for f in "$HDR/$sub"/*.c; do
            b=$(basename "$f")
            sed 's|#include "csmith.h"|#define CSMITH_MINIMAL\n#include "csmith_cerberus.h"|' \
                "$f" > "$STAGE/${pfx}_${b}" || { echo "Error: staging failed for $f" >&2; exit 1; }
        done
    done
    n_before=$(wc -l < "$LIST")
    while IFS= read -r f; do
        printf '%s\tfirst\tcsmith/%s\n' "$f" "$(basename "$f")" >> "$LIST"
    done < <(find "$STAGE" -name '*.c' | sort)
    n_after=$(wc -l < "$LIST")
    [[ $((n_after - n_before)) -gt 0 ]] || { echo "Error: csmith staging produced no files" >&2; exit 1; }
fi

# Duplicate-key check (baseline rows are keyed by these — fail-closed)
if [[ -n "$(cut -f3 "$LIST" | sort | uniq -d)" ]]; then
    echo "HARNESS ERROR: duplicate row keys across corpora:" >&2
    cut -f3 "$LIST" | sort | uniq -d >&2
    exit 1
fi

if [[ $MAX_TESTS -gt 0 ]]; then
    # --max applies per-tier so a smoke run touches both mechanisms
    awk -F'\t' -v m="$MAX_TESTS" '{ if (++c[$2] <= m) print }' "$LIST" > "$LIST.max"
    mv "$LIST.max" "$LIST"
fi
TOTAL=$(wc -l < "$LIST")
[[ $TOTAL -gt 0 ]] || { echo "Error: empty corpus (a failure, not a pass)" >&2; exit 1; }
echo ""
echo "gcc second-oracle lane: $TOTAL files (gcc $("$GCC_BIN" -dumpfullversion), lean timeout ${TIMEOUT_SECS}s, native timeout ${GCC_RUN_TIMEOUT}s, O2 stride $O2_STRIDE)"
echo "============================================"

# ---------------------------------------------------------------------------
# Helpers (verdict extraction mirrors test_exec.sh:323-341 — cited, not
# modified there)
# ---------------------------------------------------------------------------
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
    else echo 0; fi
}

declare -A COUNT=()
STATUS_LINES=0
record() {   # <key> <status> <o2status> <detail...>
    local b="$1" s="$2" o2="$3"; shift 3
    echo "$b $s $o2" >> "$STATUS_FILE" || { echo "HARNESS ERROR: cannot append status" >&2; exit 1; }
    STATUS_LINES=$((STATUS_LINES + 1))
    COUNT[$s]=$(( ${COUNT[$s]:-0} + 1 ))
    [[ "$o2" != "-" ]] && COUNT[$o2]=$(( ${COUNT[$o2]:-0} + 1 ))
    echo "[$file_num/$TOTAL] $s${o2:+ }${o2/#-/} $b${1:+: }$*"
}

# Compile+double-run one binary. Sets: G_STATUS (ok|compile|timeout|stdout|nondet)
# and G_EXIT. Args: <src> <bin> <flags...>
gcc_run() {
    local src="$1" bin="$2"; shift 2
    G_STATUS=ok; G_EXIT=-1
    if ! timeout "${GCC_COMPILE_TIMEOUT}s" "$GCC_BIN" "$@" -o "$bin" "$src" 2> "$WORK/gcc_err.txt"; then
        G_STATUS=compile; return 0
    fi
    # Native-run alignment with the model (both process-scoped, no
    # global state):
    #  * argv: Cerberus supplies argv = ["cmdname"] (cf.
    #    tests/minimal/076-main-argv-access.c and the oracle's
    #    prepare_main_args); `exec -a cmdname` mirrors it, so
    #    argv[0]-observing programs compare on semantics, not on the
    #    binary's path.
    #  * ASLR disabled via `setarch -R` (ADDR_NO_RANDOMIZE, this
    #    process tree only): address-observing programs are otherwise
    #    only luck-deterministic run-to-run, which would make their
    #    rows oscillate between SKIP_NATIVE_NONDET and the stable
    #    deterministic DISAGREE that the D2/ADDR triage class records.
    #    The double-run check stays as the backstop.
    #  * initial stack fully NORMALIZED, byte-constant (audit follow-up,
    #    design note §2.1): even with ASLR off, the kernel places
    #    environ+argv AND the execve path string (AT_EXECFN) at the top
    #    of the stack, so stack-local address observations are a
    #    function of (a) the invoking process's environment byte-size
    #    (found live when the triage-ledger value pins drifted between
    #    harness invocations differing only in env) and (b) the
    #    binary's path length (bash's `exec` absolutizes the path;
    #    found live when pins captured by hand differed from the
    #    lane's). Recipe: `env -i` + `unset PWD OLDPWD SHLVL _` leaves
    #    exactly ONE environment entry, the byte-constant `SHLVL=0`
    #    (bash re-exports it at exec; value fixed); argv[0] is the
    #    fixed `cmdname`; and the binary is exec'd via the byte-constant
    #    path /proc/self/fd/9 (fexecve idiom — the harness opens the
    #    real binary on fd 9). The binary's initial stack contents are
    #    therefore invocation-, session- AND checkout-path-independent,
    #    which is what makes the ledger's pinned values portable.
    # timeout(1) reports a kill as exit 124, but a program may LEGITIMATELY
    # exit(124) — found live: the csmith checksum byte
    # (0xAE355683 ^ 0xFFFFFFFF) & 0xFF == 124 (sa_csmith_79 et al.), which
    # a naive check misreads as a native timeout. Disambiguate by elapsed
    # time: a kill cannot fire before GCC_RUN_TIMEOUT, so exit 124 well
    # under it is the program's own. Margin 500 ms; the residual edge (a
    # genuine exit-124 slower than that) degrades to a VISIBLE skip, never
    # to a silent wrong comparison (fail-closed direction).
    # `-k 1s` (audit follow-up): a SIGTERM-ignoring program gets SIGKILL 1 s
    # after the deadline instead of hanging the lane; timeout then reports
    # 137 (128+KILL), so the elapsed-time discriminator accepts 137 past the
    # deadline as a timeout too (same-status-early — a fast genuine
    # signal-9/exit-137 death — still flows to comparison as before).
    local e1=0 e2=0 t0 t1 elapsed_ms
    local threshold_ms=$(( GCC_RUN_TIMEOUT * 1000 - 500 ))
    t0=$(date +%s%N)
    ( ulimit -v $ULIMIT_KB; exec timeout -k 1s "${GCC_RUN_TIMEOUT}s" \
        setarch -R /usr/bin/env -i bash -c 'unset PWD OLDPWD SHLVL _; exec -a cmdname /proc/self/fd/9' \
        9< "$bin" > "$WORK/run1.out" 2>/dev/null ) || e1=$?
    t1=$(date +%s%N)
    elapsed_ms=$(( (t1 - t0) / 1000000 ))
    [[ ( $e1 -eq 124 || $e1 -eq 137 ) && $elapsed_ms -ge $threshold_ms ]] && { G_STATUS=timeout; return 0; }
    t0=$(date +%s%N)
    ( ulimit -v $ULIMIT_KB; exec timeout -k 1s "${GCC_RUN_TIMEOUT}s" \
        setarch -R /usr/bin/env -i bash -c 'unset PWD OLDPWD SHLVL _; exec -a cmdname /proc/self/fd/9' \
        9< "$bin" > /dev/null 2>&1 ) || e2=$?
    t1=$(date +%s%N)
    elapsed_ms=$(( (t1 - t0) / 1000000 ))
    [[ ( $e2 -eq 124 || $e2 -eq 137 ) && $elapsed_ms -ge $threshold_ms ]] && { G_STATUS=timeout; return 0; }
    [[ $e1 -ne $e2 ]] && { G_STATUS=nondet; return 0; }
    [[ -s "$WORK/run1.out" ]] && { G_STATUS=stdout; return 0; }
    G_EXIT=$e1
    return 0
}

file_num=0
while IFS=$'\t' read -r c_file mode key; do
    file_num=$((file_num + 1))
    base_c="$key"
    stem="$(basename "$c_file" .c)"

    # ---- Lean side --------------------------------------------------------
    json="$WORK/cur.json"
    oc_err="$WORK/oc_err.txt"
    if ! timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
            --cabs-json "$c_file" > "$json" 2> "$oc_err"; then
        if grep -q CERB_FRESH_FLOOR_VIOLATION "$oc_err"; then
            record "$base_c" SKIP_ORACLE - "(floor refusal)"
        else
            record "$base_c" SKIP_ORACLE - "(cabs-json failed)"
        fi
        continue
    fi

    lean_flags=(--batch)
    [[ "$mode" == first ]] && lean_flags+=(--first)
    lean_exit=0
    lean_output=$(LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" \
        "$CERBERUS_LEAN_BIN" "${lean_flags[@]}" "$json" 2>&1) || lean_exit=$?

    if [[ $lean_exit -eq 124 ]]; then record "$base_c" SKIP_LEAN_TIMEOUT -; continue; fi
    if [[ $lean_exit -ge 128 ]]; then
        crash=$(echo "$lean_output" | grep -m1 -E 'PANIC|fuel exhausted' | cut -c1-100)
        record "$base_c" SKIP_LEAN_CRASH - "(exit $lean_exit) $crash"
        continue
    fi
    if [[ "$lean_output" != *'Undefined {'* && "$lean_output" != *'Defined {'* ]]; then
        msg=$(echo "$lean_output" | grep -o 'msg: "[^"]*"' | head -1)
        record "$base_c" SKIP_LEAN_FAIL - "${msg:-$(echo "$lean_output" | head -1 | cut -c1-80)}"
        continue
    fi
    lean_seq=$(extract_verdict_seq "$lean_output")
    [[ -n "$lean_seq" ]] || { echo "HARNESS ERROR: verdict pattern matched but no tokens for $base_c" >&2; exit 1; }
    lexp=$(expected_exit_for "$lean_output")
    if [[ $lean_exit -ne $lexp ]]; then
        record "$base_c" SKIP_LEAN_EXIT - "(exit $lean_exit, expected $lexp)"
        continue
    fi
    if [[ "$lean_seq" == *UB:* ]]; then
        record "$base_c" SKIP_UB - "($(echo "$lean_seq" | grep -m1 '^UB:'))"
        continue
    fi
    if printf '%s\n' "$lean_seq" | grep -qv '^VAL:Specified('; then
        record "$base_c" SKIP_UNSPEC - "($(printf '%s\n' "$lean_seq" | grep -m1 -v '^VAL:Specified(' | cut -c1-60))"
        continue
    fi
    # Expected byte set from the Specified payloads
    declare -A EXPECT=()
    expect_list=""
    bad_value=""
    while IFS= read -r tok; do
        v="${tok#VAL:Specified(}"; v="${v%)}"
        if ! [[ "$v" =~ ^-?[0-9]{1,19}$ ]]; then bad_value="$v"; break; fi
        b=$(( ((v % 256) + 256) % 256 ))
        [[ -z "${EXPECT[$b]+x}" ]] && { EXPECT[$b]=1; expect_list+="${expect_list:+,}$b"; }
    done <<< "$lean_seq"
    if [[ -n "$bad_value" ]]; then
        record "$base_c" SKIP_VALUE_RANGE - "($(echo "$bad_value" | cut -c1-40))"
        continue
    fi
    [[ ${#EXPECT[@]} -gt 0 ]] || { echo "HARNESS ERROR: empty expected set for $base_c" >&2; exit 1; }

    # ---- native side ------------------------------------------------------
    bin="$WORK/$stem.bin"
    gcc_run "$c_file" "$bin" -O0 -w
    case "$G_STATUS" in
        compile) record "$base_c" SKIP_GCC_COMPILE - "($(head -1 "$WORK/gcc_err.txt" | cut -c1-80))"; continue ;;
        timeout) record "$base_c" SKIP_GCC_TIMEOUT - "(lean=$expect_list)"; continue ;;
        nondet)  record "$base_c" SKIP_NATIVE_NONDET -; continue ;;
        stdout)  record "$base_c" SKIP_GCC_STDOUT - "($(wc -c < "$WORK/run1.out") bytes)"; continue ;;
        ok) ;;
        *) echo "HARNESS ERROR: gcc_run status '$G_STATUS'" >&2; exit 1 ;;
    esac

    # BY-FILE triage semantics (2026-08-30 orchestrator ruling, design
    # note §4): a ledger entry declares the file a divergence-class
    # observer (e.g. address-observing) — checked FIRST, so its status is
    # TRIAGED_* whenever the observed pair equals the pins, EVEN IF the
    # values happen to coincide (a layout coincidence is not agreement:
    # counting it AGREE would inflate the metric and arm a
    # flip-to-DISAGREE trap if either side's layout changes). Pin drift
    # is a loud unresolved DISAGREE (fail-on-drift).
    if [[ -n "${TRIAGE[$base_c]+x}" ]]; then
        TRIAGE_USED["$base_c"]=1
        if [[ "${TRIAGE_GCC[$base_c]}" == "$G_EXIT" \
              && "${TRIAGE_LEAN[$base_c]}" == "{$expect_list}" ]]; then
            status="${TRIAGE[$base_c]}"
            detail="gcc=$G_EXIT lean={$expect_list} (ledger-declared observer)"
        else
            status=DISAGREE
            detail="gcc=$G_EXIT lean={$expect_list} (TRIAGE PIN MISMATCH: ledger pins gcc=${TRIAGE_GCC[$base_c]} lean=${TRIAGE_LEAN[$base_c]} — values drifted, entry does not apply; re-triage required)"
        fi
    elif [[ -n "${EXPECT[$G_EXIT]+x}" ]]; then
        [[ ${#EXPECT[@]} -eq 1 ]] && status=AGREE || status=AGREE_ND
        detail="gcc=$G_EXIT lean={$expect_list}"
    else
        status=DISAGREE
        detail="gcc=$G_EXIT lean={$expect_list}"
    fi

    # ---- -O2 spot tier ----------------------------------------------------
    # Name-keyed selection (2026-08-30 orchestrator ruling): membership in
    # the O2 tier is a pure function of the row key (CRC32 via cksum,
    # mod O2_STRIDE), so a status flip elsewhere or a corpus insertion can
    # never re-phase WHICH files carry the O2 column (the previous
    # compared-index stride re-keyed ~every O2 row on any upstream change).
    o2="-"
    if [[ "$status" == AGREE || "$status" == AGREE_ND ]]; then
        key_crc=$(printf '%s' "$base_c" | cksum)
        key_crc=${key_crc%% *}
        if [[ $O2_STRIDE -gt 0 && $((key_crc % O2_STRIDE)) -eq 0 ]]; then
            gcc_run "$c_file" "$bin.o2" -O2 -fno-strict-aliasing -w
            case "$G_STATUS" in
                compile) o2=O2_SKIP_COMPILE ;;
                timeout) o2=O2_SKIP_TIMEOUT ;;
                nondet)  o2=O2_SKIP_NONDET ;;
                stdout)  o2=O2_SKIP_STDOUT ;;
                ok)
                    if [[ -n "${EXPECT[$G_EXIT]+x}" ]]; then
                        [[ ${#EXPECT[@]} -eq 1 ]] && o2=O2_AGREE || o2=O2_AGREE_ND
                    else
                        o2=O2_DISAGREE
                        detail+=" O2:gcc=$G_EXIT"
                    fi ;;
            esac
        fi
    fi
    rm -f "$bin" "$bin.o2"
    record "$base_c" "$status" "$o2" "$detail"
done < "$LIST"

[[ $STATUS_LINES -eq $file_num && $file_num -eq $TOTAL ]] \
    || { echo "HARNESS ERROR: $TOTAL files, processed $file_num, recorded $STATUS_LINES" >&2; exit 1; }

# Stale triage entries are fatal (a listed file that no longer reaches the
# -O0 compare stage — skipped or absent — forces ledger cleanup)
stale=0
for f in "${!TRIAGE[@]}"; do
    if [[ -z "${TRIAGE_USED[$f]+x}" ]]; then
        echo "STALE TRIAGE ENTRY: $f (${TRIAGE[$f]}) — file did not reach the -O0 compare stage in this run" >&2
        stale=$((stale + 1))
    fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo "gcc second-oracle summary"
echo "============================================"
AGREE_N=${COUNT[AGREE]:-0}; AGREE_ND_N=${COUNT[AGREE_ND]:-0}; DIS_N=${COUNT[DISAGREE]:-0}
TRIAGED_N=$(( ${COUNT[TRIAGED_ADDR]:-0} + ${COUNT[TRIAGED_FLOAT]:-0} + ${COUNT[TRIAGED_UB]:-0} + ${COUNT[TRIAGED_ORDER]:-0} ))
COMPARED=$((AGREE_N + AGREE_ND_N + DIS_N + TRIAGED_N))
SKIPPED=$((TOTAL - COMPARED))
echo "  Total files:  $TOTAL"
echo "  Compared:     $COMPARED  (agree=$AGREE_N agree_nd=$AGREE_ND_N triaged=$TRIAGED_N DISAGREE=$DIS_N)"
echo "  Skipped:      $SKIPPED  (every skip enumerated below and in the baseline rows)"
for s in $(printf '%s\n' "${!COUNT[@]}" | sort); do
    case "$s" in AGREE|AGREE_ND|DISAGREE) continue ;; esac
    echo "    $s: ${COUNT[$s]}"
done
SUMMARY="SUMMARY: total=$TOTAL compared=$COMPARED agree=$AGREE_N agree_nd=$AGREE_ND_N triaged=$TRIAGED_N disagree=$DIS_N"
for s in $(printf '%s\n' "${!COUNT[@]}" | sort); do
    case "$s" in AGREE|AGREE_ND|DISAGREE) continue ;; esac
    SUMMARY+=" ${s,,}=${COUNT[$s]}"
done
echo ""
echo "$SUMMARY"

# ---------------------------------------------------------------------------
# Baseline write / check (test_exec.sh rank discipline)
# ---------------------------------------------------------------------------
status_rank() {
    case "$1" in
        AGREE) echo 3 ;;
        AGREE_ND) echo 2 ;;
        TRIAGED_ADDR|TRIAGED_FLOAT|TRIAGED_UB|TRIAGED_ORDER) echo 1 ;;
        SKIP_*) echo 0 ;;
        DISAGREE) echo -1 ;;
        *) echo "HARNESS ERROR: unknown status '$1'" >&2; exit 1 ;;
    esac
}
o2_rank() {
    case "$1" in
        O2_AGREE|O2_AGREE_ND) echo 1 ;;
        -|O2_SKIP_*) echo 0 ;;
        O2_DISAGREE) echo -1 ;;
        *) echo "HARNESS ERROR: unknown O2 status '$1'" >&2; exit 1 ;;
    esac
}

if [[ -n "$WRITE_BASELINE" ]]; then
    if [[ $DIS_N -gt 0 || ${COUNT[O2_DISAGREE]:-0} -gt 0 ]]; then
        echo ""
        echo "REFUSING to write baseline with unresolved DISAGREE rows (triage first — design note §4)" >&2
        exit 1
    fi
    {
        echo "# gcc second-oracle baseline + SKIP LEDGER — written by test_gcc_oracle.sh --write-baseline"
        echo "# format: <key> <STATUS> <O2STATUS>  (taxonomy: script header;"
        echo "# design + triage classes: lean_frontend/docs/2026-08-30_gcc-second-oracle-design.md)"
        echo "# Every corpus file has exactly one row; every skip carries its reason class."
        echo "# TRIAGED_* rows are justified per-file in scripts/gcc_oracle_triage.txt."
        sort "$STATUS_FILE"
    } > "$WRITE_BASELINE" || { echo "Error: cannot write $WRITE_BASELINE" >&2; exit 1; }
    echo ""
    echo "Baseline written: $WRITE_BASELINE ($STATUS_LINES rows)"
fi

CHECK_RC=0
if [[ -n "$CHECK_BASELINE" ]]; then
    echo ""
    echo "Checking against baseline: $CHECK_BASELINE"
    declare -A B_S B_O2
    bcount=0
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        set -f; set -- $line; set +f   # no glob expansion (item e, see triage parser)
        [[ $# -eq 3 ]] || { echo "HARNESS ERROR: malformed baseline line: '$line'" >&2; exit 1; }
        status_rank "$2" >/dev/null || exit 1
        o2_rank "$3" >/dev/null || exit 1
        B_S["$1"]="$2"; B_O2["$1"]="$3"; bcount=$((bcount + 1))
    done < "$CHECK_BASELINE"
    [[ $bcount -gt 0 ]] || { echo "HARNESS ERROR: baseline has no entries" >&2; exit 1; }

    declare -A C_S C_O2
    while IFS= read -r line; do
        set -f; set -- $line; set +f   # no glob expansion (item e, see triage parser)
        [[ $# -eq 3 ]] || { echo "HARNESS ERROR: malformed status line: '$line'" >&2; exit 1; }
        C_S["$1"]="$2"; C_O2["$1"]="$3"
    done < "$STATUS_FILE"

    regressions=0; improvements=0
    for f in "${!B_S[@]}"; do
        if [[ -z "${C_S[$f]+x}" ]]; then
            echo "REGRESSION: $f in baseline (${B_S[$f]}) but not tested"
            regressions=$((regressions + 1)); continue
        fi
        rb=$(status_rank "${B_S[$f]}") || exit 1
        rc_=$(status_rank "${C_S[$f]}") || exit 1
        ob=$(o2_rank "${B_O2[$f]}") || exit 1
        oc=$(o2_rank "${C_O2[$f]}") || exit 1
        if [[ $rc_ -lt $rb || $oc -lt $ob ]]; then
            echo "REGRESSION: $f baseline=${B_S[$f]}/${B_O2[$f]} current=${C_S[$f]}/${C_O2[$f]}"
            regressions=$((regressions + 1))
        elif [[ $rc_ -gt $rb || $oc -gt $ob ]]; then
            echo "improvement: $f baseline=${B_S[$f]}/${B_O2[$f]} current=${C_S[$f]}/${C_O2[$f]}"
            improvements=$((improvements + 1))
        elif [[ "${B_S[$f]}" != "${C_S[$f]}" || "${B_O2[$f]}" != "${C_O2[$f]}" ]]; then
            echo "changed (same rank): $f baseline=${B_S[$f]}/${B_O2[$f]} current=${C_S[$f]}/${C_O2[$f]}"
        fi
    done
    for f in "${!C_S[@]}"; do
        if [[ -z "${B_S[$f]+x}" ]]; then
            if [[ "${C_S[$f]}" == DISAGREE || "${C_O2[$f]}" == O2_DISAGREE ]]; then
                echo "REGRESSION: new file with disagreeing status: $f ${C_S[$f]}/${C_O2[$f]}"
                regressions=$((regressions + 1))
            else
                echo "new file (not in baseline, not fatal): $f ${C_S[$f]}/${C_O2[$f]}"
            fi
        fi
    done
    echo ""
    echo "Baseline check: $regressions regression(s), $improvements improvement(s)"
    [[ $regressions -gt 0 ]] && CHECK_RC=1
fi

# ---------------------------------------------------------------------------
# Exit discipline (fail-closed)
# ---------------------------------------------------------------------------
FATAL=$CHECK_RC
if [[ $DIS_N -gt 0 ]]; then
    echo -e "${RED}FAILED: $DIS_N unresolved DISAGREE row(s) — triage per the design note before anything else${NC}"
    FATAL=1
fi
if [[ ${COUNT[O2_DISAGREE]:-0} -gt 0 ]]; then
    echo -e "${RED}FAILED: ${COUNT[O2_DISAGREE]} O2_DISAGREE row(s)${NC}"
    FATAL=1
fi
if [[ $stale -gt 0 ]]; then
    echo -e "${RED}FAILED: $stale stale triage-ledger entr(ies)${NC}"
    FATAL=1
fi
if [[ $COMPARED -eq 0 ]]; then
    echo -e "${RED}FAILED: zero comparisons happened — vacuous run${NC}"
    FATAL=1
fi
if [[ $FATAL -eq 0 ]]; then
    echo -e "${GREEN}gcc second-oracle lane OK${NC}"
fi
exit $FATAL
