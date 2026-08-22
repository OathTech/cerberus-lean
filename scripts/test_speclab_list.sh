#!/bin/bash
# test_speclab_list.sh — arc-15 S3 (R3 list rung, the first real
# builder): the IntList_append harness-family differential lanes.
#
# Target: deps/cn/tests/cn/append.c IntList_append (verbatim, cited in
# the harness headers; CN spec quoted there). Model/codec/templates:
# speclab SpecLab/ListAppend*.lean; every harness is rendered by
# speclab-test (mkHarness — the single trust point) with expected[]
# computed PURE-SIDE; this script never computes an expected value.
#
# Modes:
#   --sweep         append model sweep (125 edge models from the pure
#                   sample set: lengths {0,1,2,3,8}^2 x 5 content
#                   patterns incl. i32 extremes and the value-aliasing
#                   ys=xs shapes): both pipelines must agree with each
#                   other AND the pure prediction (Specified(0)).
#                   Fail-closed, >= 100 samples.
#   --buildsweep    build-only (builder-correctness) sweep over a
#                   25-model subsample: expected[] = choices[] (the
#                   builder-walker round trip through the heap).
#   --fuzz N [SEED] N deterministic random VALID streams (lengths
#                   rand%9 each + random content; awk srand(SEED),
#                   default 20260822): append harness per stream, both
#                   pipelines, expect Specified(0). On divergence:
#                   shrink (drop-last-element per list, then byte-wise
#                   toward 0) to a minimal counterexample program.
#   --plant         the plant demonstrations: WRONG-LINK plant
#                   (structural break -> the 255 length arm; orphans
#                   xs.length-1 nodes = the leak red witness) and
#                   WRONG-ELEMENT plant (content break -> verdict 3),
#                   healthy twins green, the DOCUMENTED BLIND-SPOT
#                   twins (link: |xs|<=1; elem: xs=[]) green with
#                   predicted 0, and the MALFORMED-STREAM twins (254)
#                   — all differential against pure-side predictions.
#   --form2 [N]     the comparator-in-C vs serialize-then-judge
#                   head-to-head (register S3): Form 2 stdout
#                   serialization, LIBC MODE, stdout asserted against
#                   the pure render3 prediction (default 6 samples).
#   --at            the pointer-selection prototype lane (interior-
#                   pointer argument; 10 differential samples).
#   --gate          the pinned-term gate (drift + param pins + in-Lean
#                   exec + THE LEAK OBSERVABLE on the assembled
#                   statement objects) — speclab-list-core-test.
#
# Exit: 0 = lane green; 1 = any failure. NOTE: no `set -e` — exit
# codes are data here (house pattern).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

TIMEOUT_SECS="${TIMEOUT_SECS:-30}"
RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
SPECLAB_TEST_BIN="$PROJECT_ROOT/lean_frontend/speclab/.lake/build/bin/speclab-test"

fail() { echo "test_speclab_list: FAIL — $*" >&2; exit 1; }

"$SCRIPT_DIR/check_speclab_statements.sh" || fail "statement gate red"

MODE="${1:-}"
[[ -n "$MODE" ]] || fail "usage: test_speclab_list.sh --sweep | --buildsweep | --fuzz N [SEED] | --plant | --form2 [N] | --at | --gate"

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

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/speclab_list.XXXXXXXXXX") || fail "mktemp failed"
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
do_sweep() { # append model sweep
    local n=0 red=0
    local log="$OUTPUT_DIR/sweep-append.log"
    : > "$log"
    while read -r csv; do
        [[ -n "$csv" ]] || continue
        "$SPECLAB_TEST_BIN" --emit-list append "$csv" \
            > "$OUTPUT_DIR/h.c" || fail "emit append [$csv]"
        run_pair "$OUTPUT_DIR/h.c" "sweep"
        n=$((n+1))
        local status="OK"
        if [[ -z "$ORACLE_VERDICT" || "$ORACLE_VERDICT" != "$LEAN_VERDICT" \
              || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            status="RED"; red=$((red+1))
        fi
        echo "[append] model=[$csv] oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=Specified(0) $status" | tee -a "$log"
    done < <("$SPECLAB_TEST_BIN" --list-samples)
    echo "SWEEP SUMMARY [append]: samples=$n red=$red"
    [[ $red -eq 0 && $n -ge 100 ]] || fail "append sweep: samples=$n red=$red"
}

do_buildsweep() { # build-only sweep (every 5th sweep model)
    local n=0 red=0 idx=0
    while read -r csv; do
        [[ -n "$csv" ]] || continue
        idx=$((idx+1))
        (( idx % 5 == 1 )) || continue
        "$SPECLAB_TEST_BIN" --emit-list build-only "$csv" \
            > "$OUTPUT_DIR/b.c" || fail "emit build-only [$csv]"
        run_pair "$OUTPUT_DIR/b.c" "buildsweep"
        n=$((n+1))
        local status="OK"
        if [[ -z "$ORACLE_VERDICT" || "$ORACLE_VERDICT" != "$LEAN_VERDICT" \
              || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            status="RED"; red=$((red+1))
        fi
        echo "[build-only] model=[$csv] oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=Specified(0) $status"
    done < <("$SPECLAB_TEST_BIN" --list-samples)
    echo "BUILD SWEEP SUMMARY: samples=$n red=$red"
    [[ $red -eq 0 && $n -ge 20 ]] || fail "build-only sweep: samples=$n red=$red"
}

# ---- fuzz + shrink --------------------------------------------------
stream_csv() { # n-th deterministic VALID append stream (seed, idx)
    awk -v seed="$1" -v idx="$2" 'BEGIN {
        srand(seed);
        # burn deterministically: 66 draws per earlier stream
        for (j = 0; j < idx * 66; j++) x = rand();
        n1 = int(rand() * 9);          # length 0..8
        n2 = int(rand() * 9);
        out = n1 "," 0;
        for (j = 0; j < 4 * n1; j++) out = out "," int(rand() * 256);
        out = out "," n2 "," 0;
        for (j = 0; j < 4 * n2; j++) out = out "," int(rand() * 256);
        # burn the unused draws so indexing stays aligned
        for (j = 4 * n1 + 4 * n2; j < 64; j++) x = rand();
        print out;
    }'
}

# returns 0 if the stream DIVERGES (used by the shrinker)
diverges() {
    local csv="$1"
    "$SPECLAB_TEST_BIN" --emit-list append-stream "$csv" > "$OUTPUT_DIR/f.c" 2>/dev/null || return 1
    run_pair "$OUTPUT_DIR/f.c" "fuzz"
    [[ "$ORACLE_VERDICT" != "$LEAN_VERDICT" || "$ORACLE_VERDICT" != "Specified(0)" ]]
}

drop_last_elem() { # csv which(1|2) -> csv with last element of that list dropped ("" if empty)
    awk -v which="$2" -F, -v OFS=, "$(cat <<'AWK'
{
    n1 = $1 + 256 * $2;
    n2 = $(3 + 4 * n1) + 256 * $(4 + 4 * n1);
    if (which == 1) { if (n1 == 0) { print ""; exit }
        printf "%d,%d", n1 - 1, 0;
        for (j = 3; j < 3 + 4 * (n1 - 1); j++) printf ",%s", $j;
        printf ",%d,%d", n2, 0;
        for (j = 5 + 4 * n1; j <= NF; j++) printf ",%s", $j;
        printf "\n";
    } else { if (n2 == 0) { print ""; exit }
        printf "%d,%d", n1, 0;
        for (j = 3; j < 3 + 4 * n1; j++) printf ",%s", $j;
        printf ",%d,%d", n2 - 1, 0;
        for (j = 5 + 4 * n1; j <= NF - 4; j++) printf ",%s", $j;
        printf "\n";
    }
}
AWK
)" <<< "$1"
}

shrink_stream() { # csv -> minimal diverging stream (prints result)
    local cur="$1" changed=1
    while [[ $changed -eq 1 ]]; do
        changed=0
        local cand
        for which in 2 1; do
            cand=$(drop_last_elem "$cur" $which)
            if [[ -n "$cand" ]] && diverges "$cand"; then
                cur="$cand"; changed=1; continue 2
            fi
        done
        IFS=',' read -ra B <<< "$cur"
        for k in $(seq 0 $(( ${#B[@]} - 1 ))); do
            local orig="${B[$k]}"
            for c in 0 1 $((orig / 2)); do
                [[ "$c" != "$orig" ]] || continue
                B[$k]=$c
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
        if ! "$SPECLAB_TEST_BIN" --emit-list append-stream "$csv" > "$OUTPUT_DIR/f.c" 2>/dev/null; then
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
            "$SPECLAB_TEST_BIN" --emit-list append-stream "$minimal" \
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
    predict=$("$SPECLAB_TEST_BIN" --list-predict "$pmode" "$csv" | head -1) \
        || fail "predict $pmode [$csv]"
    "$SPECLAB_TEST_BIN" --emit-list "$pmode" "$csv" > "$OUTPUT_DIR/p.c" \
        || fail "emit $pmode [$csv]"
    run_pair "$OUTPUT_DIR/p.c" "plant"
    echo "[plant:$label] model=[$csv] oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=$predict"
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
    # healthy references (incl. both-empty and boundary heads)
    plant_case append "1,2|3" healthy "append-healthy"
    plant_case append "|" healthy "append-healthy-empty"
    plant_case append "-2147483648,-1|2147483647" healthy "append-healthy-bounds"
    # the wrong-link / wrong-element plants
    plant_case append-link-plant "1,2|3" plant "append-wronglink"
    plant_case append-link-plant "-2147483648,-1,5|" plant "append-wronglink-noys"
    plant_case append-elem-plant "1,2|3" plant "append-wrongelem"
    plant_case append-elem-plant "-1|2147483647" plant "append-wrongelem-neg"
    # the DOCUMENTED blind spots (plant invisible — green, predicted 0
    # pure-side; register S3)
    plant_case append-link-plant "|7" blindspot "append-wronglink-emptyxs-blindspot"
    plant_case append-link-plant "5|7" blindspot "append-wronglink-singleton-blindspot"
    plant_case append-elem-plant "|7" blindspot "append-wrongelem-emptyxs-blindspot"
    # the malformed-stream twins (the 254 total-harness arm)
    plant_case append-raw "2,0,1" malformed "append-short-first-list"
    plant_case append-raw "9,0" malformed "append-over-cap"
    plant_case append-raw "1,0,1,2,3,4" malformed "append-missing-second-prefix"
    plant_case append-raw "0,0,0,0,9" malformed "append-trailing-junk"
    echo "PLANT SUMMARY: wrong-link plant RED in the 255 length arm (structural-break signature); wrong-element plant RED at predicted index 3; healthy + blind-spot twins green as predicted; malformed twins at 254"
}

# ---- form2 (libc mode) ----------------------------------------------
do_form2() {
    local count="${1:-6}"
    local libc_jsons_out
    libc_jsons_out=$("$PROJECT_ROOT/scripts/libc_prep.sh" --jsons "$OUTPUT_DIR/libcjson") \
        || fail "libc_prep.sh --jsons failed"
    mapfile -t LIBC_JSONS <<< "$libc_jsons_out"
    [[ ${#LIBC_JSONS[@]} -eq 12 ]] || fail "expected 12 libc jsons, got ${#LIBC_JSONS[@]}"
    LIBC_ARGS=(--libc "$PROJECT_ROOT/tests/libc/libc.core")
    for j in "${LIBC_JSONS[@]}"; do LIBC_ARGS+=(--libc-tu "$j"); done
    local samples=("1,2|3" "|" "-1|2147483647" "0,0|0" "-2147483648|" "1,2,3,4,5,6,7,8|9,10,11")
    local n=0 red=0
    for csv in "${samples[@]:0:$count}"; do
        local predict pstdout
        predict=$("$SPECLAB_TEST_BIN" --list-predict append-form2 "$csv" | sed -n 1p)
        pstdout=$("$SPECLAB_TEST_BIN" --list-predict append-form2 "$csv" | sed -n 2p)
        "$SPECLAB_TEST_BIN" --emit-list append-form2 "$csv" > "$OUTPUT_DIR/f2.c" \
            || fail "emit form2 [$csv]"
        local oline lline
        oline=$(timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
            --exec --batch --mode=exhaustive "$OUTPUT_DIR/f2.c" 2>&1 | grep 'Defined' | head -1)
        timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
            --cabs-json "$OUTPUT_DIR/f2.c" > "$OUTPUT_DIR/f2.json" 2>/dev/null \
            || fail "cabs-json refused form2 [$csv]"
        lline=$(cd "$PROJECT_ROOT" && LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" \
            "$CERBERUS_LEAN_BIN" --batch "${LIBC_ARGS[@]}" "$OUTPUT_DIR/f2.json" 2>&1 \
            | grep 'Defined' | head -1)
        n=$((n+1))
        local want="Defined {value: \"$predict\", stdout: \"$pstdout\", stderr: \"\", blocked: \"false\"}"
        if [[ "$oline" == "$want" && "$lline" == "$want" ]]; then
            echo "[form2] model=[$csv] OK"
        else
            red=$((red+1))
            echo "[form2] model=[$csv] RED"
            echo "    O: $oline"
            echo "    L: $lline"
            echo "    P: $want"
        fi
    done
    echo "FORM2 SUMMARY: samples=$n red=$red"
    [[ $red -eq 0 ]] || fail "form2: $red red"
}

# ---- pointer-selection prototype ------------------------------------
do_at() {
    local n=0 red=0
    while read -r csv; do
        [[ -n "$csv" ]] || continue
        "$SPECLAB_TEST_BIN" --emit-list append-at "$csv" \
            > "$OUTPUT_DIR/at.c" || fail "emit append-at [$csv]"
        run_pair "$OUTPUT_DIR/at.c" "at"
        n=$((n+1))
        local status="OK"
        if [[ -z "$ORACLE_VERDICT" || "$ORACLE_VERDICT" != "$LEAN_VERDICT" \
              || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            status="RED"; red=$((red+1))
        fi
        echo "[append-at] model=[$csv] oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=Specified(0) $status"
    done < <("$SPECLAB_TEST_BIN" --list-at-samples)
    echo "AT SUMMARY: samples=$n red=$red"
    [[ $red -eq 0 && $n -ge 10 ]] || fail "append-at lane: samples=$n red=$red"
}

# ---- pinned-term gate (drift + param pins + in-Lean exec + leak) ----
do_gate() {
    (cd "$PROJECT_ROOT/lean_frontend/speclab" && \
        "$SCRIPT_DIR/capped" lake build speclab-list-core-test >/dev/null 2>&1) \
        || fail "speclab-list-core-test build failed"
    local bin="$PROJECT_ROOT/lean_frontend/speclab/.lake/build/bin/speclab-list-core-test"
    [[ -f "$bin" ]] || fail "speclab-list-core-test binary missing"
    (cd "$PROJECT_ROOT" && "$bin") || fail "ListGateTest red"
}

case "$MODE" in
    --gate)       do_gate ;;
    --sweep)      do_sweep ;;
    --buildsweep) do_buildsweep ;;
    --fuzz)       do_fuzz "${2:?--fuzz needs N}" "${3:-20260822}" ;;
    --plant)      do_plant ;;
    --form2)      do_form2 "${2:-6}" ;;
    --at)         do_at ;;
    *) fail "unknown mode: $MODE" ;;
esac

echo "test_speclab_list: PASS ($MODE)"
exit 0
