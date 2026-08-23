#!/bin/bash
# test_speclab_seed.sh — arc-15 S5 (R5, the CN-slate seed rung): the
# swap_pair + lookup_size_shift harness-family differential lanes.
#
# Targets: deps/cn/tests/cn/swap_pair.c (the swap family's substantive
# post-state ensures) and deps/cn/tests/cn/cn_inline.c
# lookup_size_shift (the cn_function-bound scalar). Model/codec/
# templates: speclab SpecLab/CnSeed*.lean; every harness is rendered
# by speclab-test (mkHarness — the single trust point) with expected[]
# computed PURE-SIDE; this script never computes an expected value.
#
# Modes:
#   --sweep            swap edge sweep (100 pairs: 10 edge u64s
#                      crossed, incl. the a = b diagonal) + lookup
#                      sweep (13 szs: all enum arms + default-arm
#                      region + int maxima). Both pipelines must agree
#                      with each other AND the pure prediction.
#   --fuzz N [SEED]    N deterministic random 16-byte swap streams
#                      (awk srand; every 16-byte stream is valid — the
#                      full-domain rung), byte-wise shrinker armed.
#   --plant            the lost-update (swap) and wrong-constant
#                      (lookup) plant demonstrations: plants RED with
#                      pure-side predicted indexes on BOTH pipelines;
#                      blind-spot twins green as predicted (swap
#                      diagonal — the kernel-characterized blind set;
#                      lookup non-medium arms); malformed twins at 254.
#   --gate             the pinned-term gate (drift + param pins +
#                      in-Lean exec on the assembled theorem objects).
#
# Exit: 0 = lane green; 1 = any failure. NOTE: no `set -e` — exit
# codes are data here (house pattern).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

TIMEOUT_SECS="${TIMEOUT_SECS:-30}"
RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
SPECLAB_TEST_BIN="$PROJECT_ROOT/lean_frontend/speclab/.lake/build/bin/speclab-test"

fail() { echo "test_speclab_seed: FAIL — $*" >&2; exit 1; }

"$SCRIPT_DIR/check_speclab_statements.sh" || fail "statement gate red"

MODE="${1:-}"
[[ -n "$MODE" ]] || fail "usage: test_speclab_seed.sh --sweep | --fuzz N [SEED] | --plant | --gate"

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

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/speclab_seed.XXXXXXXXXX") || fail "mktemp failed"
register_cleanup "$OUTPUT_DIR"

# ---- pipeline pair (nolibc lanes) -----------------------------------
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

# ---- sweep ----------------------------------------------------------
do_sweep() {
    local n=0 red=0
    local log="$OUTPUT_DIR/sweep.log"
    : > "$log"
    while read -r pair; do
        [[ -n "$pair" ]] || continue
        "$SPECLAB_TEST_BIN" --emit-seed swap "$pair" \
            > "$OUTPUT_DIR/h.c" || fail "emit swap ($pair)"
        run_pair "$OUTPUT_DIR/h.c" "sweep"
        n=$((n+1))
        local status="OK"
        if [[ -z "$ORACLE_VERDICT" || "$ORACLE_VERDICT" != "$LEAN_VERDICT" \
              || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            status="RED"; red=$((red+1))
        fi
        echo "[swap] pair=$pair oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=Specified(0) $status" | tee -a "$log"
    done < <("$SPECLAB_TEST_BIN" --seed-swap-samples)
    echo "SWEEP SUMMARY [swap]: samples=$n red=$red"
    [[ $red -eq 0 && $n -ge 100 ]] || fail "swap sweep: samples=$n red=$red"
    local m=0 lred=0
    while read -r sz; do
        [[ -n "$sz" ]] || continue
        "$SPECLAB_TEST_BIN" --emit-seed lookup "$sz" \
            > "$OUTPUT_DIR/h.c" || fail "emit lookup ($sz)"
        run_pair "$OUTPUT_DIR/h.c" "sweep"
        m=$((m+1))
        local status="OK"
        if [[ -z "$ORACLE_VERDICT" || "$ORACLE_VERDICT" != "$LEAN_VERDICT" \
              || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            status="RED"; lred=$((lred+1))
        fi
        echo "[lookup] sz=$sz oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=Specified(0) $status" | tee -a "$log"
    done < <("$SPECLAB_TEST_BIN" --seed-lookup-samples)
    echo "SWEEP SUMMARY [lookup]: samples=$m red=$lred"
    [[ $lred -eq 0 && $m -ge 12 ]] || fail "lookup sweep: samples=$m red=$lred"
}

# ---- fuzz + shrink --------------------------------------------------
stream_csv() { # n-th deterministic 16-byte stream (seed, idx)
    awk -v seed="$1" -v idx="$2" 'BEGIN {
        srand(seed);
        for (j = 0; j < idx * 16; j++) x = int(rand() * 256);
        out = "";
        for (j = 0; j < 16; j++) {
            v = int(rand() * 256);
            out = out (j ? "," : "") v;
        }
        print out;
    }'
}

diverges() {
    local csv="$1"
    "$SPECLAB_TEST_BIN" --emit-seed swap-stream "$csv" > "$OUTPUT_DIR/f.c" 2>/dev/null || return 1
    run_pair "$OUTPUT_DIR/f.c" "fuzz"
    [[ "$ORACLE_VERDICT" != "$LEAN_VERDICT" || "$ORACLE_VERDICT" != "Specified(0)" ]]
}

do_fuzz() {
    local count="${1:?--fuzz needs N}" seed="${2:-20260823}"
    local n=0 div=0
    for ((i = 0; i < count; i++)); do
        local csv
        csv=$(stream_csv "$seed" "$i")
        "$SPECLAB_TEST_BIN" --emit-seed swap-stream "$csv" > "$OUTPUT_DIR/f.c" 2>/dev/null \
            || fail "fuzz emit refused a 16-byte stream (full-domain rung: impossible)"
        run_pair "$OUTPUT_DIR/f.c" "fuzz"
        n=$((n+1))
        if [[ "$ORACLE_VERDICT" != "$LEAN_VERDICT" || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            div=$((div+1))
            echo "FUZZ DIVERGENCE at stream [$csv]: oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT"
            local cur="$csv" changed=1
            while [[ $changed -eq 1 ]]; do
                changed=0
                IFS=',' read -ra B <<< "$cur"
                for k in "${!B[@]}"; do
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
            echo "FUZZ MINIMAL COUNTEREXAMPLE STREAM: [$cur]"
            cp "$OUTPUT_DIR/f.c" "$OUTPUT_DIR/minimal_counterexample.c"
            echo "minimal counterexample program left at $OUTPUT_DIR/minimal_counterexample.c"
        fi
        if (( n % 25 == 0 )); then echo "  ... fuzz progress: $n run, $div divergences"; fi
    done
    echo "FUZZ SUMMARY: requested=$count run=$n divergences=$div (seed=$seed)"
    [[ $div -eq 0 ]] || fail "fuzz: $div divergence(s)"
}

# ---- plant ----------------------------------------------------------
plant_case() { # mode arg label
    local mode="$1" arg="$2" label="$3"
    local predict
    predict=$("$SPECLAB_TEST_BIN" --seed-predict "$mode" "$arg" | head -1)
    "$SPECLAB_TEST_BIN" --emit-seed "$mode" "$arg" > "$OUTPUT_DIR/p.c" \
        || fail "emit $mode ($arg)"
    run_pair "$OUTPUT_DIR/p.c" "plant"
    echo "[plant:$label] arg=$arg oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=$predict"
    [[ "$ORACLE_VERDICT" == "$LEAN_VERDICT" ]] \
        || fail "plant $label: pipelines disagree"
    [[ "$ORACLE_VERDICT" == "$predict" ]] \
        || fail "plant $label: verdict != pure-side prediction"
    # class belts (beyond prediction equality): healthy + blind-spot
    # twins are green; live plants are RED; malformed twins are 254
    case "$label" in
        *-healthy*|*-blindspot)
            [[ "$ORACLE_VERDICT" == "Specified(0)" ]] \
                || fail "$label: expected green" ;;
        *-stream|*-ceiling)
            [[ "$ORACLE_VERDICT" == "Specified(254)" ]] \
                || fail "$label: expected the 254 totality arm" ;;
        *)
            [[ "$ORACLE_VERDICT" != "Specified(0)" ]] \
                || fail "plant $label came back GREEN — vacuous harness" ;;
    esac
}

do_plant() {
    # healthy references
    plant_case swap "578437695752307201,1157159078456920585" swap-healthy
    plant_case swap "0,0" swap-healthy-diagonal
    plant_case lookup 1 lookup-healthy
    # the plants (must be RED at the predicted index)
    plant_case swap-plant "578437695752307201,1157159078456920585" swap-lostupdate
    plant_case swap-plant "0,18446744073709551615" swap-lostupdate-extremes
    plant_case lookup-plant 1 lookup-wrongconst
    # blind-spot twins (documented negative space: predicted GREEN)
    plant_case swap-plant "5,5" swap-lostupdate-diagonal-blindspot
    plant_case lookup-plant 0 lookup-wrongconst-big-blindspot
    plant_case lookup-plant 77 lookup-wrongconst-default-blindspot
    # malformed twins (the 254 totality arm, both pipelines)
    plant_case swap-raw "1,2,3" swap-short-stream
    plant_case swap-raw "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17" swap-long-stream
    plant_case lookup-raw "1,0" lookup-short-stream
    plant_case lookup-raw "0,0,0,128" lookup-over-int-ceiling
    # verify the actual plant rows were red and blind rows green
    echo "PLANT SUMMARY: lost-update plant RED at byte 8 (verdict 9); wrong-constant plant RED at result byte 0; diagonal/non-medium blind twins green as predicted (swap blind set kernel-characterized: swapPlant_blind_iff); malformed twins at 254"
}

# ---- pinned-term gate (drift + param pins + in-Lean exec) -----------
do_gate() {
    (cd "$PROJECT_ROOT/lean_frontend/speclab" && \
        "$SCRIPT_DIR/capped" lake build speclab-seed-core-test >/dev/null 2>&1) \
        || fail "speclab-seed-core-test build failed"
    local bin="$PROJECT_ROOT/lean_frontend/speclab/.lake/build/bin/speclab-seed-core-test"
    [[ -f "$bin" ]] || fail "speclab-seed-core-test binary missing"
    (cd "$PROJECT_ROOT" && "$bin") || fail "SeedGateTest red"
}

case "$MODE" in
    --gate)    do_gate ;;
    --sweep)   do_sweep ;;
    --fuzz)    do_fuzz "${2:?--fuzz needs N}" "${3:-20260823}" ;;
    --plant)   do_plant ;;
    *) fail "unknown mode: $MODE" ;;
esac

echo "test_speclab_seed: PASS ($MODE)"
exit 0
