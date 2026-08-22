#!/bin/bash
# test_speclab_bytearr.sh — arc-15 S2 (R2 array/byte-blaster rung):
# the memcpy/get_from_arr harness-family differential lanes.
#
# Targets: deps/cn/tests/cn/{memcpy.c,get_from_arr.c} (verbatim,
# cited in the harness headers). Model/codec/templates: speclab
# SpecLab/ByteArr*.lean; every harness is rendered by speclab-test
# (mkHarness — the single trust point) with expected[] computed
# PURE-SIDE; this script never computes an expected value itself.
#
# Modes:
#   --sweep         memcpy stream sweep (136 edge streams from the
#                   pure sample set: every length 0..16 × 8 content
#                   patterns incl. 0x00/0xFF/canary): both pipelines
#                   must agree with each other AND the pure prediction
#                   (Specified(0)). Fail-closed, ≥100 samples.
#   --getsweep      getarr sweep (20 ten-byte patterns), same checks.
#   --fuzz N [SEED] N deterministic random VALID streams (length
#                   rand%17 + random content; awk srand(SEED), default
#                   20260822): memcpy harness per stream, both
#                   pipelines, expect Specified(0). On divergence:
#                   shrink (drop-last-content-byte first, then
#                   byte-wise toward 0) to a minimal counterexample
#                   program, recorded loudly.
#   --plant         the plant demonstrations: memcpy OFF-BY-ONE plant
#                   (mismatch index into dst byte 0 → verdict 3) and
#                   getarr WRONG-INDEX plant (verdict 1), healthy
#                   twins green, the DOCUMENTED BLIND-SPOT twins
#                   (n=0 / canary-collision / bs[3]=bs[4]) green with
#                   predicted 0, and the MALFORMED-STREAM twins
#                   (verdict 254) — all differential on both
#                   pipelines against pure-side predictions.
#   --gate          the pinned-term gate (drift + param pins + in-Lean
#                   exec of the assembled statement objects) —
#                   speclab-bytearr-core-test (S2 batch 2).
#
# Exit: 0 = lane green; 1 = any failure. NOTE: no `set -e` — exit
# codes are data here (house pattern).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

TIMEOUT_SECS="${TIMEOUT_SECS:-30}"
RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
SPECLAB_TEST_BIN="$PROJECT_ROOT/lean_frontend/speclab/.lake/build/bin/speclab-test"

fail() { echo "test_speclab_bytearr: FAIL — $*" >&2; exit 1; }

"$SCRIPT_DIR/check_speclab_statements.sh" || fail "statement gate red"

MODE="${1:-}"
[[ -n "$MODE" ]] || fail "usage: test_speclab_bytearr.sh --sweep | --getsweep | --fuzz N [SEED] | --plant | --gate"

if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    [[ -f "$CERBERUS_BIN" ]] || fail "SKIP_BUILD=1 but $CERBERUS_BIN missing"
    [[ -f "$CERBERUS_LEAN_BIN" ]] || fail "SKIP_BUILD=1 but $CERBERUS_LEAN_BIN missing"
else
    build_cerberus
    build_lean
fi
[[ -d "$RUNTIME_DIR" ]] || fail "runtime dir not found: $RUNTIME_DIR"

(cd "$PROJECT_ROOT/lean_frontend/speclab" && \
    "$SCRIPT_DIR/capped" lake build speclab-test >/dev/null 2>&1)
[[ -f "$SPECLAB_TEST_BIN" ]] || fail "speclab-test binary missing after build"

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/speclab_bytearr.XXXXXXXXXX") || fail "mktemp failed"
register_cleanup "$OUTPUT_DIR"

# ---- pipeline pair (nolibc lanes) -----------------------------------
# sets: ORACLE_VERDICT LEAN_VERDICT (empty on no Defined line)
run_pair() {
    local src="$1" tag="$2"
    local oout lout
    oout=$(timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" \
        --runtime="$RUNTIME_DIR" --nolibc --exec --batch --mode=exhaustive \
        "$src" 2>&1)
    ORACLE_VERDICT=$(echo "$oout" | grep -o 'Defined {value: "[^"]*"' | head -1 | sed 's/Defined {value: "//;s/"$//')
    timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        --cabs-json "$src" > "$OUTPUT_DIR/$tag.json" 2>"$OUTPUT_DIR/$tag.cabs.err" \
        || fail "cabs-json refused $tag: $(cat "$OUTPUT_DIR/$tag.cabs.err")"
    lout=$(cd "$PROJECT_ROOT" && LEAN_ABORT_ON_PANIC=1 \
        timeout "${TIMEOUT_SECS}s" "$CERBERUS_LEAN_BIN" --batch \
        "$OUTPUT_DIR/$tag.json" 2>&1)
    LEAN_VERDICT=$(echo "$lout" | grep -o 'Defined {value: "[^"]*"' | head -1 | sed 's/Defined {value: "//;s/"$//')
}

# ---- sweeps ---------------------------------------------------------
do_sweep() { # memcpy stream sweep
    local n=0 red=0
    local log="$OUTPUT_DIR/sweep-memcpy.log"
    : > "$log"
    while read -r csv; do
        [[ -n "$csv" ]] || continue
        "$SPECLAB_TEST_BIN" --emit-bytearr memcpy-stream "$csv" \
            > "$OUTPUT_DIR/h.c" || fail "emit memcpy-stream [$csv]"
        run_pair "$OUTPUT_DIR/h.c" "sweep"
        n=$((n+1))
        local status="OK"
        if [[ -z "$ORACLE_VERDICT" || "$ORACLE_VERDICT" != "$LEAN_VERDICT" \
              || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            status="RED"; red=$((red+1))
        fi
        echo "[memcpy] stream=[$csv] oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=Specified(0) $status" | tee -a "$log"
    done < <("$SPECLAB_TEST_BIN" --bytearr-samples)
    echo "SWEEP SUMMARY [memcpy]: samples=$n red=$red"
    [[ $red -eq 0 && $n -ge 100 ]] || fail "memcpy sweep: samples=$n red=$red"
}

do_getsweep() { # getarr model sweep
    local n=0 red=0
    local log="$OUTPUT_DIR/sweep-getarr.log"
    : > "$log"
    while read -r csv; do
        [[ -n "$csv" ]] || continue
        "$SPECLAB_TEST_BIN" --emit-bytearr getarr "$csv" \
            > "$OUTPUT_DIR/g.c" || fail "emit getarr [$csv]"
        run_pair "$OUTPUT_DIR/g.c" "getsweep"
        n=$((n+1))
        local status="OK"
        if [[ -z "$ORACLE_VERDICT" || "$ORACLE_VERDICT" != "$LEAN_VERDICT" \
              || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            status="RED"; red=$((red+1))
        fi
        echo "[getarr] arr=[$csv] oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=Specified(0) $status" | tee -a "$log"
    done < <("$SPECLAB_TEST_BIN" --getarr-samples)
    echo "SWEEP SUMMARY [getarr]: samples=$n red=$red"
    [[ $red -eq 0 && $n -ge 20 ]] || fail "getarr sweep: samples=$n red=$red"
}

# ---- fuzz + shrink --------------------------------------------------
stream_csv() { # n-th deterministic VALID memcpy stream (seed, idx)
    awk -v seed="$1" -v idx="$2" 'BEGIN {
        srand(seed);
        # burn deterministically: 17 draws per earlier stream
        for (j = 0; j < idx * 17; j++) x = rand();
        n = int(rand() * 17);          # length 0..16
        out = n "," 0;
        for (j = 0; j < n; j++) {
            v = int(rand() * 256);
            out = out "," v;
        }
        # burn the unused draws so indexing stays aligned
        for (j = n; j < 16; j++) x = rand();
        print out;
    }'
}

# returns 0 if the stream DIVERGES (used by the shrinker)
diverges() {
    local csv="$1"
    "$SPECLAB_TEST_BIN" --emit-bytearr memcpy-stream "$csv" > "$OUTPUT_DIR/f.c" 2>/dev/null || return 1
    run_pair "$OUTPUT_DIR/f.c" "fuzz"
    [[ "$ORACLE_VERDICT" != "$LEAN_VERDICT" || "$ORACLE_VERDICT" != "Specified(0)" ]]
}

shrink_stream() { # csv -> minimal diverging stream (prints result)
    local cur="$1" changed=1
    while [[ $changed -eq 1 ]]; do
        changed=0
        # step 1: drop the last content byte (decrement the prefix)
        IFS=',' read -ra B <<< "$cur"
        local n=$(( B[0] + 256 * B[1] ))
        if (( n > 0 )); then
            local shorter="$(( n - 1 )),0"
            for k in $(seq 2 $(( ${#B[@]} - 2 ))); do shorter="$shorter,${B[$k]}"; done
            if diverges "$shorter"; then cur="$shorter"; changed=1; continue; fi
        fi
        # step 2: byte-wise value shrink toward 0
        IFS=',' read -ra B <<< "$cur"
        for k in $(seq 2 $(( ${#B[@]} - 1 ))); do
            local orig="${B[$k]}"
            for cand in 0 1 $((orig / 2)); do
                [[ "$cand" != "$orig" ]] || continue
                B[$k]=$cand
                local trial
                trial=$(IFS=','; echo "${B[*]}")
                if diverges "$trial"; then
                    cur="$trial"; changed=1; break
                else
                    B[$k]=$orig
                fi
            done
        done
    done
    echo "$cur"
}

do_fuzz() {
    local count="${1:?--fuzz needs N}" seed="${2:-20260822}"
    local n=0 invalid=0 div=0
    for ((i = 0; i < count; i++)); do
        local csv
        csv=$(stream_csv "$seed" "$i")
        if ! "$SPECLAB_TEST_BIN" --emit-bytearr memcpy-stream "$csv" > "$OUTPUT_DIR/f.c" 2>/dev/null; then
            invalid=$((invalid+1)); continue
        fi
        run_pair "$OUTPUT_DIR/f.c" "fuzz"
        n=$((n+1))
        if [[ "$ORACLE_VERDICT" != "$LEAN_VERDICT" || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            div=$((div+1))
            echo "FUZZ DIVERGENCE at stream [$csv]: oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT"
            local minimal
            minimal=$(shrink_stream "$csv")
            echo "FUZZ MINIMAL COUNTEREXAMPLE STREAM: [$minimal]"
            "$SPECLAB_TEST_BIN" --emit-bytearr memcpy-stream "$minimal" \
                > "$OUTPUT_DIR/minimal_counterexample.c" 2>/dev/null
            echo "minimal counterexample program left at $OUTPUT_DIR/minimal_counterexample.c"
        fi
        if (( n % 25 == 0 )); then echo "  ... fuzz progress: $n run, $div divergences"; fi
    done
    echo "FUZZ SUMMARY: requested=$count run=$n invalid_skipped=$invalid divergences=$div (seed=$seed)"
    [[ $div -eq 0 ]] || fail "fuzz: $div divergence(s)"
}

# ---- plant ----------------------------------------------------------
plant_case() { # mode csv kind(healthy|plant|blindspot|malformed) label
    local pmode="$1" csv="$2" kind="$3" label="$4"
    local predict
    predict=$("$SPECLAB_TEST_BIN" --bytearr-predict "$pmode" "$csv" | head -1) \
        || fail "predict $pmode [$csv]"
    "$SPECLAB_TEST_BIN" --emit-bytearr "$pmode" "$csv" > "$OUTPUT_DIR/p.c" \
        || fail "emit $pmode [$csv]"
    run_pair "$OUTPUT_DIR/p.c" "plant"
    echo "[plant:$label] stream=[$csv] oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=$predict"
    [[ "$ORACLE_VERDICT" == "$LEAN_VERDICT" ]] \
        || fail "plant $label: pipelines disagree"
    [[ "$ORACLE_VERDICT" == "$predict" ]] \
        || fail "plant $label: verdict != pure-side prediction"
    case "$kind" in
        healthy|blindspot)
            [[ "$ORACLE_VERDICT" == "Specified(0)" ]] \
                || fail "$kind $label expected green" ;;
        plant)
            [[ "$ORACLE_VERDICT" != "Specified(0)" ]] \
                || fail "plant $label came back GREEN — vacuous harness" ;;
        malformed)
            [[ "$ORACLE_VERDICT" == "Specified(254)" ]] \
                || fail "malformed $label expected Specified(254)" ;;
    esac
}

do_plant() {
    local hello="104,101,108,108,111,104,101,108,108,111"
    # healthy references (incl. the LENGTH-0 instance, explicitly)
    plant_case memcpy "1,2,3" healthy "memcpy-healthy"
    plant_case memcpy "" healthy "memcpy-healthy-n0"
    plant_case getarr "$hello" healthy "getarr-healthy"
    # the off-by-one / wrong-index plants (must go red at the
    # predicted mismatch index)
    plant_case memcpy-plant "1,2,3" plant "memcpy-offbyone"
    plant_case memcpy-plant "255,0,7,9" plant "memcpy-offbyone-ff"
    plant_case getarr-plant "$hello" plant "getarr-wrongindex"
    # the DOCUMENTED blind spots (plant invisible — green, predicted
    # 0 pure-side; register S2-E5)
    plant_case memcpy-plant "" blindspot "memcpy-offbyone-n0-blindspot"
    plant_case memcpy-plant "42,9" blindspot "memcpy-offbyone-canary-blindspot"
    plant_case getarr-plant "7,7,7,7,7,7,7,7,7,7" blindspot "getarr-eq34-blindspot"
    # the malformed-stream twins (the 254 total-harness arm,
    # differentially exercised)
    plant_case memcpy-raw "5,0,1" malformed "memcpy-short-body"
    plant_case memcpy-raw "17,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17" malformed "memcpy-over-capacity"
    plant_case memcpy-raw "3" malformed "memcpy-no-prefix"
    plant_case getarr-raw "1,2,3,4,5,6,7,8,9" malformed "getarr-nine-bytes"
    echo "PLANT SUMMARY: plants RED at predicted indexes; healthy + blind-spot twins green as predicted; malformed twins at 254"
}

# ---- pinned-term gate (drift + param pins + in-Lean exec) -----------
do_gate() {
    (cd "$PROJECT_ROOT/lean_frontend/speclab" && \
        "$SCRIPT_DIR/capped" lake build speclab-bytearr-core-test >/dev/null 2>&1) \
        || fail "speclab-bytearr-core-test build failed"
    local bin="$PROJECT_ROOT/lean_frontend/speclab/.lake/build/bin/speclab-bytearr-core-test"
    [[ -f "$bin" ]] || fail "speclab-bytearr-core-test binary missing"
    (cd "$PROJECT_ROOT" && "$bin") || fail "ByteArrGateTest red"
}

case "$MODE" in
    --gate)     do_gate ;;
    --sweep)    do_sweep ;;
    --getsweep) do_getsweep ;;
    --fuzz)     do_fuzz "${2:?--fuzz needs N}" "${3:-20260822}" ;;
    --plant)    do_plant ;;
    *) fail "unknown mode: $MODE" ;;
esac

echo "test_speclab_bytearr: PASS ($MODE)"
exit 0
