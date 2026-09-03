#!/bin/bash
# test_ci_sweep.sh — full-upstream-CI-sweep scoreboard (ci-sweep stream,
# 2026-08-22). NON-GATING measurement instrument: a differential sweep of
# the big heterogeneous corpora under tests/ (gcc-torture breakdown
# classes, ci, tcc, suite, pnvi_testsuite, hacl-star, freebsd, examples)
# with scoreboard classification and checkpointed per-file TSVs. It
# enforces NO baseline and always exits 0 unless the harness itself
# breaks (fail-closed on harness-internal errors only). Survey basis:
# lean_frontend/docs/2026-08-20_prototype-test-migration-survey.md §3.4/§6 item 4.
#
# Relationship to test_exec.sh (NOT modified — additive-file rule):
# the comparison semantics are REPLICATED from scripts/test_exec.sh with
# citations, extended for libc mode:
#   * verdict-sequence extraction (test_exec.sh:322-334 extract_verdict_seq)
#   * expected-exit derivation    (test_exec.sh:339-347 expected_exit_for)
#   * classification ladder       (test_exec.sh:389-635 main loop)
# Deliberate deltas vs test_exec.sh, all sweep-motivated:
#   1. LIBC MODE (per-suite): the oracle runs WITHOUT --nolibc (loads
#      runtime/libc/libc.co) and the Lean side gets
#      --libc tests/libc/libc.core + 12 --libc-tu metadata jsons via
#      scripts/libc_prep.sh --jsons (the test_libc_exec.sh mechanism,
#      test_libc_exec.sh:66-76). Rationale: gcc-torture/tcc/suite call
#      libc (abort/exit/printf); the --nolibc lane skips ~80% of them
#      (measured on the first 10 breakdown/success files: 8/10
#      CERB_SKIP "calling an unknown procedure").
#   2. STDOUT comparison (libc mode only): value-sequences equal but the
#      full Defined lines (value+stdout+stderr+blocked; loc-free by
#      format) differ => STDOUT_DIFF. The --nolibc harness never needed
#      this (programs cannot write to stdout there, test_exec.sh header
#      "stdout-text spoofing" note); with libc it is a real divergence
#      channel. Undefined lines are still compared by ub code only
#      (loc strings deliberately differ across the two pipelines,
#      Main.lean:344 "harness never compares loc").
#   3. Oracle-failure buckets are SUBDIVIDED (test_exec.sh folds them all
#      into CERB_SKIP): CERB_TIMEOUT / CERB_CRASH / CERB_ERROR (Error{}
#      verdict) / CERB_REJECT (nonzero exit, no verdict = front-end
#      rejection) / CERB_SKIP (exit 0, no verdict). Triage needs the split.
#   4. Per-test memory cap BOTH sides: `scripts/capped` at
#      CERB_TEST_MEM_MAX (default 4G, cgroup RSS) around oracle, cabs-json
#      and Lean runs — mem-scale S2 (2026-09-02, Q2 [USER 2026-09-02])
#      replacing the arc-5 `ulimit -v 4000000` (virtual-address-space cap;
#      common.sh header). A cap breach is exit 137 + capped's OOM-KILLED
#      banner (the cgroup's memory.events oom_kill witness): rows
#      LEAN_KILL / CERB_KILL, distinct from *_CRASH, never agreement,
#      never a skip. A bare 137 (no OOM event) stays *_CRASH as before.
#   5. Checkpointed TSV + --resume: one row appended per file
#      (suite<TAB>relpath<TAB>status<TAB>detail); an interrupted sweep
#      rerun with --resume skips already-recorded files.
#   6. No *.unsupported.c special case (that is a tests/minimal
#      convention; these corpora use upstream suffixes — .undef.c etc.
#      surface honestly as UB_* / DIFF rows).
#   7. Timeout default 15 s per side (sweep discipline; prototype
#      test_interp.sh used 10 s, our gate lanes use 30 s).
#   8. HANG classification (mem-scale S0, 2026-09-02; common.sh
#      classify_exit124, shared with test_exec.sh): an exit 124 whose
#      (User+System)/wall < 0.1 is LEAN_HANG / CERB_HANG, distinct from
#      LEAN_TIMEOUT / CERB_TIMEOUT — the process stopped consuming CPU
#      long before the timeout (no output, no exit; charter C9). Both
#      driver runs are wrapped in `/usr/bin/time -v -o <record>`; an
#      unreadable record is a harness error, never a TIMEOUT. NOTE the
#      rule is timeout-relative: at this lane's 15 s default a hang that
#      burns >1.5 s of CPU before parking still reads TIMEOUT — the
#      classification is exact only for TIMEOUT_SECS >= 10x the CPU a
#      hang burns (>= 60 s for the C9 shape); the note carries both.
#
#   9. LEAN_FUEL (FUEL arc, 2026-09-03; common.sh/fuel_classify.sh
#      classify_fuel_outcome): the typed fuel-exhaustion kill
#      `Error {msg: "lem: fuel exhausted"}` or the pure-worker panic line
#      at exit >= 128, classified AHEAD of LEAN_CRASH / LEAN_FAIL on the
#      exact message; never agreement.
#
# Statuses (superset of the test_exec.sh taxonomy):
#   MATCH UB_MATCH UB_DIFF STDOUT_DIFF DIFF MISMATCH
#   LEAN_FAIL LEAN_CRASH LEAN_KILL LEAN_FUEL LEAN_ERROR LEAN_TIMEOUT LEAN_HANG
#   CERB_REJECT CERB_ERROR CERB_TIMEOUT CERB_HANG CERB_CRASH CERB_KILL CERB_SKIP
#   CERB_FLOOR CERB_INCONSISTENT
#
# Usage:
#   ./scripts/test_ci_sweep.sh --suite torture_success [--suite ci ...]
#       [--max N] [--resume] [--out DIR]
#   ./scripts/test_ci_sweep.sh --list-suites
# Environment:
#   TIMEOUT_SECS    per-side per-test timeout (default 15)
#   CERB_TEST_MEM_MAX per-test resident-memory cap (default 4G; common.sh)
#   SKIP_BUILD=1    skip no-op build steps (binaries must exist)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TIMEOUT_SECS="${TIMEOUT_SECS:-15}"

command -v timeout &>/dev/null || { echo "Error: 'timeout' not found" >&2; exit 1; }
require_time_bin   # HANG classification needs GNU time (common.sh; fail-closed)

# --- suite registry ---------------------------------------------------------
# name => "dir|mode"  (mode: libc | nolibc; dir relative to PROJECT_ROOT)
declare -A SUITE_DIR SUITE_MODE
add_suite() { SUITE_DIR["$1"]="$2"; SUITE_MODE["$1"]="$3"; }
add_suite torture_success           tests/gcc-torture/breakdown/success           libc
add_suite torture_fail              tests/gcc-torture/breakdown/fail              libc
add_suite torture_limbus            tests/gcc-torture/breakdown/limbus            libc
add_suite torture_undefined         tests/gcc-torture/breakdown/undefined         libc
add_suite torture_invalid           tests/gcc-torture/breakdown/invalid           libc
add_suite torture_not_std_compliant tests/gcc-torture/breakdown/not_std_compliant libc
add_suite torture_not_supported     tests/gcc-torture/breakdown/not_supported     libc
add_suite ci                        tests/ci                                      nolibc
add_suite tcc                       tests/tcc                                     libc
add_suite suite                     tests/suite                                   libc
add_suite pnvi                      tests/pnvi_testsuite                          libc
add_suite hacl_star                 tests/hacl-star                               libc
add_suite freebsd                   tests/freebsd                                 libc
add_suite examples                  tests/examples                                libc
add_suite cheri_smoke               tests/cheri-ci                                libc

SUITES=()
MAX_TESTS=0
RESUME=false
OUT_DIR="$PROJECT_ROOT/tests/ci_sweep/results"
while [[ $# -gt 0 ]]; do
    case $1 in
        --suite) SUITES+=("$2"); shift 2 ;;
        --max) MAX_TESTS="$2"; shift 2 ;;
        --resume) RESUME=true; shift ;;
        --out) OUT_DIR="$2"; shift 2 ;;
        --list-suites)
            for s in "${!SUITE_DIR[@]}"; do echo "$s ${SUITE_DIR[$s]} ${SUITE_MODE[$s]}"; done | sort
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done
[[ ${#SUITES[@]} -gt 0 ]] || { echo "Error: at least one --suite required (--list-suites)" >&2; exit 1; }
for s in "${SUITES[@]}"; do
    [[ -n "${SUITE_DIR[$s]+x}" ]] || { echo "Error: unknown suite '$s'" >&2; exit 1; }
done

if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    [[ -f "$CERBERUS_BIN" ]] || { echo "Error: SKIP_BUILD=1 but $CERBERUS_BIN missing" >&2; exit 1; }
    [[ -f "$CERBERUS_LEAN_BIN" ]] || { echo "Error: SKIP_BUILD=1 but $CERBERUS_LEAN_BIN missing" >&2; exit 1; }
    verify_skip_build_freshness   # C2: stale-driver hazard — stamps must be fresh (fail-closed)
else
    build_cerberus
    build_lean
fi

RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
[[ -d "$RUNTIME_DIR" ]] || { echo "Error: runtime dir not found: $RUNTIME_DIR" >&2; exit 1; }
[[ -f "$PROJECT_ROOT/runtime/libcore/std.core" ]] || { echo "Error: std.core not found" >&2; exit 1; }

mkdir -p "$OUT_DIR" || { echo "Error: cannot create $OUT_DIR" >&2; exit 1; }
WORK_DIR=$(mktemp -d "$TMP_DIR/ci-sweep.XXXXXXXXXX") || { echo "Error: mktemp failed" >&2; exit 1; }
register_cleanup "$WORK_DIR"

# --- libc prep (once; only if some selected suite is libc-mode) ------------
LIBC_ARGS=()
need_libc=false
for s in "${SUITES[@]}"; do [[ "${SUITE_MODE[$s]}" == libc ]] && need_libc=true; done
if $need_libc; then
    libc_jsons_out=$("$PROJECT_ROOT/scripts/libc_prep.sh" --jsons "$WORK_DIR/libcjson") \
        || { echo "Error: libc_prep.sh --jsons failed (pin drift or oracle missing)" >&2; exit 1; }
    [[ -n "$libc_jsons_out" ]] || { echo "Error: libc_prep.sh --jsons emitted no paths" >&2; exit 1; }
    mapfile -t LIBC_JSONS <<< "$libc_jsons_out"
    [[ ${#LIBC_JSONS[@]} -eq 12 ]] || { echo "Error: expected 12 libc metadata jsons, got ${#LIBC_JSONS[@]}" >&2; exit 1; }
    LIBC_ARGS=(--libc "$PROJECT_ROOT/tests/libc/libc.core")
    for j in "${LIBC_JSONS[@]}"; do LIBC_ARGS+=(--libc-tu "$j"); done
    echo "[prep] libc pin verified; 12 metadata TUs"
fi

cd "$PROJECT_ROOT" || { echo "Error: cannot cd to $PROJECT_ROOT" >&2; exit 1; }

# --- replicated helpers (citations in header) ------------------------------
extract_verdict_seq() {   # test_exec.sh:322-334, verbatim semantics
    printf '%s\n' "$1" \
        | grep -oE 'Undefined \{ub: "[^"]*"|Defined \{value: "[^"]*"' \
        | sed -e 's/^Undefined {ub: "\(.*\)"$/UB:\1/' \
              -e 's/^Defined {value: "\(.*\)"$/VAL:\1/'
    return 0
}
extract_defined_lines() { # libc-mode STDOUT_DIFF channel (delta 2)
    printf '%s\n' "$1" | grep -E '^Defined \{'
    return 0
}
expected_exit_for() {     # test_exec.sh:339-347, verbatim semantics
    if [[ "$1" == *'EXECUTION '* ]]; then echo 0
    elif [[ "$1" == *'Undefined {'* || "$1" == *'Error {'* ]]; then echo 1
    else echo 0; fi
}
join_seq() { printf '%s' "$1" | tr '\n' '|'; }
sanitize() {  # TSV detail field: no tabs/newlines, capped length
    printf '%s' "$1" | tr '\t\n' '  ' | cut -c1-300
}

# --- per-suite sweep -------------------------------------------------------
overall_rc=0
for suite in "${SUITES[@]}"; do
    dir="$PROJECT_ROOT/${SUITE_DIR[$suite]}"
    mode="${SUITE_MODE[$suite]}"
    [[ -d "$dir" ]] || { echo "Error: suite dir not found: $dir" >&2; exit 1; }
    tsv="$OUT_DIR/$suite.tsv"

    declare -A done_map=()
    if $RESUME && [[ -f "$tsv" ]]; then
        while IFS=$'\t' read -r _s rel _st _d; do
            [[ -n "${rel:-}" ]] && done_map["$rel"]=1
        done < "$tsv"
        echo "[$suite] resume: ${#done_map[@]} rows already recorded"
    else
        : > "$tsv" || { echo "Error: cannot write $tsv" >&2; exit 1; }
    fi

    mapfile -t files < <(find "$dir" -name '*.c' \
        ! -name '*.syntax-only.c' ! -name '*.exhaust.c' | sort)
    total=${#files[@]}
    [[ $total -gt 0 ]] || { echo "Error: empty suite $suite (empty corpus is a failure)" >&2; exit 1; }
    if [[ $MAX_TESTS -gt 0 ]]; then files=("${files[@]:0:$MAX_TESTS}"); fi
    echo ""
    echo "=== SWEEP suite=$suite mode=$mode files=${#files[@]} (of $total) timeout=${TIMEOUT_SECS}s cap=${TEST_MEM_MAX} (cgroup RSS, per test) ==="

    # counters
    declare -A C=()
    for k in MATCH UB_MATCH UB_DIFF STDOUT_DIFF DIFF MISMATCH LEAN_FAIL LEAN_CRASH \
             LEAN_KILL LEAN_ERROR LEAN_TIMEOUT LEAN_HANG CERB_REJECT CERB_ERROR CERB_TIMEOUT \
             CERB_HANG CERB_CRASH CERB_KILL CERB_SKIP CERB_FLOOR CERB_INCONSISTENT; do C[$k]=0; done
    n=0; nfiles=${#files[@]}

    ORACLE_FLAGS=(--exec --batch --mode=exhaustive)
    LEAN_MODE_ARGS=()
    if [[ "$mode" == nolibc ]]; then
        ORACLE_FLAGS=(--nolibc "${ORACLE_FLAGS[@]}")
    else
        LEAN_MODE_ARGS=(${LIBC_ARGS[@]+"${LIBC_ARGS[@]}"})
    fi

    for f in "${files[@]}"; do
        rel="${f#$PROJECT_ROOT/}"
        n=$((n + 1))
        if [[ -n "${done_map[$rel]+x}" ]]; then continue; fi
        row() {   # <STATUS> <detail>
            C[$1]=$((C[$1] + 1))
            printf '%s\t%s\t%s\t%s\n' "$suite" "$rel" "$1" "$(sanitize "${2:-}")" >> "$tsv" \
                || { echo "Error: cannot append to $tsv" >&2; exit 1; }
            echo "[$n/$nfiles] $1 $(basename "$f"): $(sanitize "${2:-}" | cut -c1-160)"
        }

        # --- oracle ---------------------------------------------------------
        cerb_exit=0
        cerb_time="$WORK_DIR/cerb.time"
        cerb_out=$( "${CAPPED_TEST[@]}" "$TIME_BIN" -v -o "$cerb_time" timeout "${TIMEOUT_SECS}s" \
            "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" "${ORACLE_FLAGS[@]}" "$f" 2>&1 ) \
            || cerb_exit=$?
        if [[ $cerb_exit -eq 124 ]]; then
            cerb_124=$(classify_exit124 "$cerb_time" "$TIMEOUT_SECS") || exit 1
            if [[ "$cerb_124" == HANG* ]]; then row CERB_HANG "$cerb_124"; else row CERB_TIMEOUT "$cerb_124"; fi
            continue
        fi
        if [[ $cerb_exit -eq 137 && "$cerb_out" == *"capped: OOM-KILLED"* ]]; then
            row CERB_KILL "exit 137, capped OOM-KILLED (memory cap $TEST_MEM_MAX breached)"; continue; fi
        if [[ $cerb_exit -eq 134 || $cerb_exit -eq 137 || $cerb_exit -eq 139 ]]; then
            row CERB_CRASH "signal exit $cerb_exit"; continue; fi
        if [[ "$cerb_out" == *CERB_FRESH_FLOOR_VIOLATION* ]]; then
            row CERB_FLOOR "exit $cerb_exit"; continue; fi
        cerb_has_ub=false; cerb_seq=""
        if [[ "$cerb_out" == *'Undefined {'* ]]; then
            cerb_has_ub=true; cerb_seq=$(extract_verdict_seq "$cerb_out")
        elif [[ "$cerb_out" == *'value: "Specified'* || "$cerb_out" == *'value: "Unspecified'* ]]; then
            cerb_seq=$(extract_verdict_seq "$cerb_out")
        elif [[ "$cerb_out" == *'Error {'* ]]; then
            msg=$(echo "$cerb_out" | grep -o 'msg: "[^"]*"' | head -1)
            row CERB_ERROR "$msg"; continue
        elif [[ $cerb_exit -ne 0 ]]; then
            first=$(printf '%s\n' "$cerb_out" | grep -vE '^\s*$' | head -1)
            row CERB_REJECT "exit $cerb_exit: $first"; continue
        else
            row CERB_SKIP "exit 0, no verdict extracted"; continue
        fi
        if [[ -z "$cerb_seq" ]]; then
            echo "HARNESS ERROR: oracle verdict matched but no tokens for $rel" >&2; exit 1; fi
        cerb_expected=$(expected_exit_for "$cerb_out")
        if [[ $cerb_exit -ne $cerb_expected ]]; then
            row CERB_INCONSISTENT "parsed $(join_seq "$cerb_seq") but exit=$cerb_exit (expected $cerb_expected)"; continue; fi

        # --- cabs-json ------------------------------------------------------
        json="$WORK_DIR/tu.json"
        json_rc=0
        "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
                "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --cabs-json "$f" > "$json" 2> "$WORK_DIR/json.err" || json_rc=$?
        if is_cap_kill $json_rc "$WORK_DIR/json.err"; then row CERB_KILL "cabs-json $(kill_label 137 "$WORK_DIR/json.err")"; continue; fi
        if [[ $json_rc -ne 0 ]]; then
            row CERB_INCONSISTENT "exec succeeded but cabs-json failed (exit $json_rc)"; continue; fi

        # --- Lean pipeline --------------------------------------------------
        lean_exit=0
        lean_time="$WORK_DIR/lean.time"
        lean_out=$( "${CAPPED_TEST[@]}" env LEAN_ABORT_ON_PANIC=1 \
            "$TIME_BIN" -v -o "$lean_time" timeout "${TIMEOUT_SECS}s" "$CERBERUS_LEAN_BIN" --batch \
            ${LEAN_MODE_ARGS[@]+"${LEAN_MODE_ARGS[@]}"} "$json" 2>&1 ) || lean_exit=$?
        if [[ $lean_exit -eq 124 ]]; then
            lean_124=$(classify_exit124 "$lean_time" "$TIMEOUT_SECS") || exit 1
            if [[ "$lean_124" == HANG* ]]; then row LEAN_HANG "$lean_124"; else row LEAN_TIMEOUT "$lean_124"; fi
            continue
        fi
        if [[ $lean_exit -eq 137 && "$lean_out" == *"capped: OOM-KILLED"* ]]; then
            row LEAN_KILL "exit 137, capped OOM-KILLED (memory cap $TEST_MEM_MAX breached)"; continue; fi
        fuel_kind=$(classify_fuel_outcome "$lean_exit" "$lean_out")
        if [[ -n "$fuel_kind" ]]; then
            row LEAN_FUEL "$fuel_kind, exit $lean_exit: lem: fuel exhausted"; continue; fi
        if [[ $lean_exit -ge 128 ]]; then
            kind=$(echo "$lean_out" | grep -m1 -E 'PANIC|fuel exhausted' | cut -c1-120)
            [[ -z "$kind" ]] && kind="(no PANIC line captured)"
            row LEAN_CRASH "exit $lean_exit: $kind"; continue; fi
        lean_has_ub=false; lean_seq=""
        if [[ "$lean_out" == *'Undefined {'* ]]; then
            lean_has_ub=true; lean_seq=$(extract_verdict_seq "$lean_out")
        elif [[ "$lean_out" == *'Defined {'* ]]; then
            lean_seq=$(extract_verdict_seq "$lean_out")
        elif [[ "$lean_out" == *'Error {'* ]]; then
            msg=$(echo "$lean_out" | grep -o 'msg: "[^"]*"' | head -1)
            row LEAN_FAIL "$msg"; continue
        else
            row LEAN_FAIL "unexpected output: $(echo "$lean_out" | head -2 | tr '\n' ' ')"; continue
        fi
        if [[ -z "$lean_seq" ]]; then
            echo "HARNESS ERROR: Lean verdict matched but no tokens for $rel" >&2; exit 1; fi
        lean_expected=$(expected_exit_for "$lean_out")
        if [[ $lean_exit -ne $lean_expected ]]; then
            row LEAN_ERROR "parsed $(join_seq "$lean_seq") but exit=$lean_exit (expected $lean_expected)"; continue; fi

        # --- comparison (test_exec.sh:576-635 semantics + STDOUT_DIFF) -----
        lean_shape=$(printf '%s\n' "$lean_seq" | sed 's/^UB:.*/UB/')
        cerb_shape=$(printf '%s\n' "$cerb_seq" | sed 's/^UB:.*/UB/')
        if [[ "$lean_seq" == "$cerb_seq" ]]; then
            if [[ "$mode" == libc ]] && ! $lean_has_ub; then
                dl_lean=$(extract_defined_lines "$lean_out")
                dl_cerb=$(extract_defined_lines "$cerb_out")
                if [[ "$dl_lean" != "$dl_cerb" ]]; then
                    row STDOUT_DIFF "values equal; Lean=$(echo "$dl_lean" | head -1) Cerberus=$(echo "$dl_cerb" | head -1)"
                    continue
                fi
            fi
            if $lean_has_ub; then row UB_MATCH "$(join_seq "$lean_seq")"
            else row MATCH "$(join_seq "$lean_seq")"; fi
        elif [[ "$lean_shape" == "$cerb_shape" ]]; then
            row UB_DIFF "Lean=$(join_seq "$lean_seq") Cerberus=$(join_seq "$cerb_seq")"
        elif [[ "$lean_has_ub" != "$cerb_has_ub" ]]; then
            row DIFF "Lean=$(join_seq "$lean_seq") Cerberus=$(join_seq "$cerb_seq")"
        else
            row MISMATCH "Lean=$(join_seq "$lean_seq") Cerberus=$(join_seq "$cerb_seq")"
        fi
    done

    # per-suite machine-grepable summary, recomputed FROM THE TSV so it is
    # correct across --resume (in-memory counters only see this run's rows)
    declare -A T=()
    tsv_rows=0
    while IFS=$'\t' read -r _s _rel st _d; do
        [[ -z "${st:-}" || "$_s" == \#* ]] && continue
        T[$st]=$(( ${T[$st]:-0} + 1 )); tsv_rows=$((tsv_rows + 1))
    done < "$tsv"
    summary="SWEEP SUMMARY suite=$suite mode=$mode total=$tsv_rows"
    for k in MATCH UB_MATCH UB_DIFF STDOUT_DIFF DIFF MISMATCH LEAN_FAIL LEAN_CRASH \
             LEAN_KILL LEAN_ERROR LEAN_TIMEOUT LEAN_HANG CERB_REJECT CERB_ERROR CERB_TIMEOUT \
             CERB_HANG CERB_CRASH CERB_KILL CERB_SKIP CERB_FLOOR CERB_INCONSISTENT; do
        summary+=" ${k,,}=${T[$k]:-0}"
    done
    echo ""
    echo "$summary"
    echo "# $summary" >> "$tsv"
    unset T
done

exit $overall_rc
