#!/bin/bash
# test_speclab_divmod.sh — arc-15 S1 (R1 scalar rung): the divmod
# harness-family differential lanes.
#
# Targets: deps/cn/tests/cn/{division.c,mod.c} (verbatim, cited in the
# harness headers). Model/codec/templates: speclab SpecLab/DivMod*.lean;
# every harness is rendered by speclab-test (mkHarness — the single
# trust point) with expected[] computed PURE-SIDE; this script never
# computes an expected value itself.
#
# Modes:
#   --sweep [FORM]     edge-sample sweep (default form1; also form1b,
#                      i8): for every sample the two pipelines must
#                      agree with each other AND with the pure-model
#                      prediction (Specified(0)). Fail-closed.
#   --i8sweep          the kernel-instance template (Form 1u-i8) over
#                      the full Wf cross product of a small i8 edge set.
#   --fuzz N [SEED]    N deterministic random 8-byte streams (awk
#                      srand(SEED), default 20260822): emit Form 1
#                      harness per stream (invalid streams counted +
#                      skipped), both pipelines, expect Specified(0).
#                      On divergence: byte-wise SHRINK to a minimal
#                      counterexample program, recorded loudly.
#   --plant            the wrong-operator plant demonstrations
#                      (template-note §plant-test): healthy vs plant on
#                      the same inputs, all three verdict forms; plant
#                      must go RED (nonzero mismatch index / boolean 1 /
#                      diverging stdout) with the pure-side predicted
#                      index, on BOTH pipelines.
#   --form2 [N]        Form 2 (stdout serialization, LIBC MODE) over
#                      the first N edge samples (default 8): verdict
#                      Specified(0) and stdout == pure-side render3
#                      prediction, both pipelines byte-identical.
#
# Exit: 0 = lane green; 1 = any failure. NOTE: no `set -e` — exit
# codes are data here (house pattern).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

TIMEOUT_SECS="${TIMEOUT_SECS:-30}"
RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
SPECLAB_TEST_BIN="$PROJECT_ROOT/lean_frontend/speclab/.lake/build/bin/speclab-test"

fail() { echo "test_speclab_divmod: FAIL — $*" >&2; exit 1; }

"$SCRIPT_DIR/check_speclab_statements.sh" || fail "statement gate red"

MODE="${1:-}"
[[ -n "$MODE" ]] || fail "usage: test_speclab_divmod.sh --sweep [FORM] | --i8sweep | --fuzz N [SEED] | --plant | --form2 [N]"

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

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/speclab_divmod.XXXXXXXXXX") || fail "mktemp failed"
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

# ---- sweep ----------------------------------------------------------
do_sweep() {
    local form="${1:-form1}"
    local n=0 red=0
    local log="$OUTPUT_DIR/sweep-$form.log"
    : > "$log"
    while read -r x y; do
        [[ -n "$x" ]] || continue
        if [[ "$form" == "i8" ]]; then
            # i8 template only covers the i8 sub-family
            (( x >= -128 && x <= 127 && y >= -128 && y <= 127 )) || continue
        fi
        "$SPECLAB_TEST_BIN" --emit-divmod "$form" "$x" "$y" \
            > "$OUTPUT_DIR/h.c" || fail "emit $form ($x,$y)"
        local predict
        predict=$("$SPECLAB_TEST_BIN" --divmod-predict "$form" "$x" "$y" | head -1)
        run_pair "$OUTPUT_DIR/h.c" "sweep"
        n=$((n+1))
        local status="OK"
        if [[ -z "$ORACLE_VERDICT" || "$ORACLE_VERDICT" != "$LEAN_VERDICT" \
              || "$ORACLE_VERDICT" != "$predict" ]]; then
            status="RED"; red=$((red+1))
        fi
        echo "[$form] x=$x y=$y oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=$predict $status" | tee -a "$log"
    done < <("$SPECLAB_TEST_BIN" --divmod-samples)
    echo "SWEEP SUMMARY [$form]: samples=$n red=$red"
    [[ $red -eq 0 && $n -ge 100 ]] || fail "sweep [$form]: samples=$n red=$red"
}

# ---- i8 sweep (kernel-instance template) ----------------------------
do_i8sweep() {
    local vals=(-128 -127 -10 -5 -2 -1 1 2 3 5 10 126 127)
    local n=0 red=0
    local log="$OUTPUT_DIR/sweep-i8.log"
    : > "$log"
    for x in "${vals[@]}"; do
        for y in "${vals[@]}"; do
            "$SPECLAB_TEST_BIN" --emit-divmod i8 "$x" "$y" \
                > "$OUTPUT_DIR/h.c" || fail "emit i8 ($x,$y)"
            run_pair "$OUTPUT_DIR/h.c" "i8"
            n=$((n+1))
            local status="OK"
            if [[ "$ORACLE_VERDICT" != "Specified(0)" \
                  || "$LEAN_VERDICT" != "Specified(0)" ]]; then
                status="RED"; red=$((red+1))
            fi
            echo "[i8] x=$x y=$y oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=Specified(0) $status" | tee -a "$log"
        done
    done
    echo "SWEEP SUMMARY [i8]: samples=$n red=$red"
    [[ $red -eq 0 ]] || fail "i8 sweep: red=$red"
}

# ---- fuzz + shrink --------------------------------------------------
stream_csv() { # n-th deterministic 8-byte stream (seed, idx)
    awk -v seed="$1" -v idx="$2" 'BEGIN {
        srand(seed);
        for (j = 0; j < idx * 8; j++) x = int(rand() * 256);
        out = "";
        for (j = 0; j < 8; j++) {
            v = int(rand() * 256);
            out = out (j ? "," : "") v;
        }
        print out;
    }'
}

# returns 0 if the stream DIVERGES (used by the shrinker)
diverges() {
    local csv="$1"
    "$SPECLAB_TEST_BIN" --emit-divmod-stream "$csv" > "$OUTPUT_DIR/f.c" 2>/dev/null || return 1
    run_pair "$OUTPUT_DIR/f.c" "fuzz"
    [[ "$ORACLE_VERDICT" != "$LEAN_VERDICT" || "$ORACLE_VERDICT" != "Specified(0)" ]]
}

do_fuzz() {
    local count="${1:?--fuzz needs N}" seed="${2:-20260822}"
    local n=0 invalid=0 div=0
    for ((i = 0; i < count; i++)); do
        local csv
        csv=$(stream_csv "$seed" "$i")
        if ! "$SPECLAB_TEST_BIN" --emit-divmod-stream "$csv" > "$OUTPUT_DIR/f.c" 2>/dev/null; then
            invalid=$((invalid+1)); continue
        fi
        run_pair "$OUTPUT_DIR/f.c" "fuzz"
        n=$((n+1))
        if [[ "$ORACLE_VERDICT" != "$LEAN_VERDICT" || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            div=$((div+1))
            echo "FUZZ DIVERGENCE at stream [$csv]: oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT"
            # ---- byte-wise shrink: minimize toward 0 preserving divergence
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
    echo "FUZZ SUMMARY: requested=$count run=$n invalid_skipped=$invalid divergences=$div (seed=$seed)"
    [[ $div -eq 0 ]] || fail "fuzz: $div divergence(s)"
}

# ---- plant ----------------------------------------------------------
plant_case() { # form x y
    local form="$1" x="$2" y="$3"
    local predict
    predict=$("$SPECLAB_TEST_BIN" --divmod-predict "$form" "$x" "$y" | head -1)
    "$SPECLAB_TEST_BIN" --emit-divmod "$form" "$x" "$y" > "$OUTPUT_DIR/p.c" \
        || fail "emit $form ($x,$y)"
    run_pair "$OUTPUT_DIR/p.c" "plant"
    echo "[plant:$form] x=$x y=$y oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=$predict"
    [[ "$ORACLE_VERDICT" == "$LEAN_VERDICT" ]] \
        || fail "plant $form: pipelines disagree"
    [[ "$ORACLE_VERDICT" == "$predict" ]] \
        || fail "plant $form: verdict != pure-side prediction"
    if [[ "$form" == *plant* ]]; then
        [[ "$ORACLE_VERDICT" != "Specified(0)" ]] \
            || fail "plant $form came back GREEN — vacuous harness"
    else
        [[ "$ORACLE_VERDICT" == "Specified(0)" ]] \
            || fail "healthy $form not green at ($x,$y)"
    fi
}

do_plant() {
    # healthy references first, then the wrong-operator plants
    plant_case form1 7 2
    plant_case form1-plant 7 2
    plant_case form1-plant -7 3
    plant_case form1b 7 2
    plant_case form1b-plant 7 2
    plant_case i8 7 2
    plant_case i8-plant 7 2
    plant_case i8-plant -5 3
    echo "PLANT SUMMARY: all wrong-operator plants RED with predicted indexes; healthy twins green"
}

# ---- form2 (libc mode) ----------------------------------------------
do_form2() {
    local count="${1:-8}"
    libc_jsons_out=$("$PROJECT_ROOT/scripts/libc_prep.sh" --jsons "$OUTPUT_DIR/libcjson") \
        || fail "libc_prep.sh --jsons failed"
    mapfile -t LIBC_JSONS <<< "$libc_jsons_out"
    [[ ${#LIBC_JSONS[@]} -eq 12 ]] || fail "expected 12 libc jsons, got ${#LIBC_JSONS[@]}"
    LIBC_ARGS=(--libc "$PROJECT_ROOT/tests/libc/libc.core")
    for j in "${LIBC_JSONS[@]}"; do LIBC_ARGS+=(--libc-tu "$j"); done
    local n=0 red=0
    while read -r x y; do
        [[ -n "$x" ]] || continue
        n=$((n+1))
        (( n <= count )) || break
        "$SPECLAB_TEST_BIN" --emit-divmod form2 "$x" "$y" > "$OUTPUT_DIR/f2.c" \
            || fail "emit form2 ($x,$y)"
        local predict_stdout
        predict_stdout=$("$SPECLAB_TEST_BIN" --divmod-predict form2 "$x" "$y" | sed -n 2p)
        local oline lline
        oline=$(timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" \
            --runtime="$RUNTIME_DIR" --exec --batch "$OUTPUT_DIR/f2.c" 2>&1 | head -1)
        timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
            --cabs-json "$OUTPUT_DIR/f2.c" > "$OUTPUT_DIR/f2.json" 2>/dev/null \
            || fail "cabs-json failed for form2 ($x,$y)"
        lline=$(cd "$PROJECT_ROOT" && LEAN_ABORT_ON_PANIC=1 \
            timeout "${TIMEOUT_SECS}s" "$CERBERUS_LEAN_BIN" --batch --first \
            "${LIBC_ARGS[@]}" "$OUTPUT_DIR/f2.json" 2>&1 | head -1)
        local status="OK"
        # both sides byte-identical AND stdout carries the predicted render
        if [[ "$oline" != "$lline" || "$oline" != *"stdout: \"$predict_stdout\""* \
              || "$oline" != *'value: "Specified(0)"'* ]]; then
            status="RED"; red=$((red+1))
        fi
        echo "[form2] x=$x y=$y $status"
        echo "    O: $oline"
        echo "    L: $lline"
        echo "    P: stdout=\"$predict_stdout\" value=Specified(0)"
    done < <("$SPECLAB_TEST_BIN" --divmod-samples)
    echo "FORM2 SUMMARY: samples=$((n > count ? count : n)) red=$red"
    [[ $red -eq 0 ]] || fail "form2: red=$red"
}

case "$MODE" in
    --sweep)   do_sweep "${2:-form1}" ;;
    --i8sweep) do_i8sweep ;;
    --fuzz)    do_fuzz "${2:?--fuzz needs N}" "${3:-20260822}" ;;
    --plant)   do_plant ;;
    --form2)   do_form2 "${2:-8}" ;;
    *) fail "unknown mode: $MODE" ;;
esac

echo "test_speclab_divmod: PASS ($MODE)"
exit 0
