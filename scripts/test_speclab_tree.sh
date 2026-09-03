#!/bin/bash
# test_speclab_tree.sh — arc-15 S4 (R4 tree rung, THE REFERENCE
# INSTANCE): the rotate_right harness-family differential lanes.
#
# Target: fresh-authorship rotate_right (the deps/cn corpus has no
# rotation — selection reasoning in SpecLab/TreeRot.lean; struct shape
# per the corpus int-binary-tree reference tree_rev01.c).
# Model/codec/templates: speclab SpecLab/TreeRot*.lean; every harness
# is rendered by speclab-test (mkHarness — the single trust point)
# with expected[] computed PURE-SIDE; this script never computes an
# expected value.
#
# Model CLI syntax: 'TREE|PATH' with TREE ::= L | (val TREE TREE) and
# PATH a string over {l,r} (empty = rotate at the root).
#
# Modes:
#   --sweep         rotate model sweep (145 edge models from the pure
#                   sample set: depths 0-4, degenerate spines both
#                   ways, complete trees incl. the 31-node capacity
#                   corner, zig-zags, the pinned worked-example shape;
#                   paths: root, deep in-shape, OFF-SHAPE): both
#                   pipelines must agree with each other AND the pure
#                   prediction (Specified(0)). Fail-closed, >= 120.
#   --buildsweep    build-only (builder-correctness) sweep over an
#                   every-5th subsample: expected[] = choices[] (the
#                   builder-walker round trip through the heap).
#   --fuzz N [SEED] N deterministic random VALID streams (pre-order
#                   branching-process trees, node budget 12, random
#                   path 0..8 steps incl. off-shape; awk srand(SEED),
#                   default 20260822): rotate harness per stream, both
#                   pipelines, expect Specified(0). On divergence:
#                   shrink (byte-wise toward 0, validity-checked) to a
#                   minimal counterexample program.
#   --plant         the plant demonstrations: WRONG-CHILD-SWAP plant
#                   (content/structure break, NO leak) and
#                   DROPPED-SUBTREE plant (255 length arm + orphaned
#                   nodes = the leak arm's red witness), healthy twins
#                   green, the DOCUMENTED BLIND-SPOT twins (swap:
#                   self-similar locus + off-shape; drop: lr = leaf)
#                   green with predicted 0, and the MALFORMED-STREAM
#                   twins (254) — all differential against pure-side
#                   predictions.
#   --form2 [N]     Form 2 stdout serialization, LIBC MODE, stdout
#                   asserted against the pure render3 prediction
#                   (default 6 samples).
#   --gate          the pinned-term gate (drift + param pins + in-Lean
#                   exec + THE LEAK OBSERVABLE on the assembled
#                   statement objects) — speclab-tree-core-test.
#
# Exit: 0 = lane green; 1 = any failure. NOTE: no `set -e` — exit
# codes are data here (house pattern).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

TIMEOUT_SECS="${TIMEOUT_SECS:-30}"
RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
SPECLAB_TEST_BIN="$PROJECT_ROOT/lean_frontend/speclab/.lake/build/bin/speclab-test"

fail() { echo "test_speclab_tree: FAIL — $*" >&2; exit 1; }

MODE="${1:-}"
[[ -n "$MODE" ]] || fail "usage: test_speclab_tree.sh --sweep | --buildsweep | --fuzz N [SEED] | --plant | --form2 [N] | --gate"

if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    [[ -f "$CERBERUS_BIN" ]] || fail "SKIP_BUILD=1 but $CERBERUS_BIN missing"
    [[ -f "$CERBERUS_LEAN_BIN" ]] || fail "SKIP_BUILD=1 but $CERBERUS_LEAN_BIN missing"
    verify_skip_build_freshness   # C2: stale-driver hazard — stamps must be fresh (fail-closed)
else
    build_cerberus
    build_lean
fi
[[ -d "$RUNTIME_DIR" ]] || fail "runtime dir not found: $RUNTIME_DIR"

(cd "$PROJECT_ROOT/lean_frontend/speclab" && \
    "$SCRIPT_DIR/capped" lake build speclab-test >/dev/null 2>&1)
[[ -f "$SPECLAB_TEST_BIN" ]] || fail "speclab-test binary missing after build"

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/speclab_tree.XXXXXXXXXX") || fail "mktemp failed"
register_cleanup "$OUTPUT_DIR"

# ---- pipeline pair (nolibc lanes) -----------------------------------
# sets: ORACLE_VERDICT LEAN_VERDICT (empty on no Defined line)
run_pair() {
    local src="$1" tag="$2"
    local oout lout
    oout=$(timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" \
        --runtime="$RUNTIME_DIR" --nolibc --exec --batch --mode=exhaustive \
        "$src" 2>&1)
    ORACLE_VERDICT=$(echo "$oout" | grep -oE '^Defined \{value: "[^"]*"|^Undefined \{.*\}$' | head -1 | sed 's/^Defined {value: "//;s/"$//')
    timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        --cabs-json "$src" > "$OUTPUT_DIR/$tag.json" 2>"$OUTPUT_DIR/$tag.cabs.err" \
        || fail "cabs-json refused $tag: $(cat "$OUTPUT_DIR/$tag.cabs.err")"
    lout=$(cd "$PROJECT_ROOT" && LEAN_ABORT_ON_PANIC=1 \
        timeout "${TIMEOUT_SECS}s" "$CERBERUS_LEAN_BIN" --batch \
        "$OUTPUT_DIR/$tag.json" 2>&1)
    LEAN_VERDICT=$(echo "$lout" | grep -oE '^Defined \{value: "[^"]*"|^Undefined \{.*\}$' | head -1 | sed 's/^Defined {value: "//;s/"$//')
}

# ---- sweeps ---------------------------------------------------------
do_sweep() { # rotate model sweep
    local n=0 red=0
    local log="$OUTPUT_DIR/sweep-rotate.log"
    : > "$log"
    while read -r arg; do
        [[ -n "$arg" ]] || continue
        "$SPECLAB_TEST_BIN" --emit-tree rotate "$arg" \
            > "$OUTPUT_DIR/h.c" || fail "emit rotate [$arg]"
        run_pair "$OUTPUT_DIR/h.c" "sweep"
        n=$((n+1))
        local status="OK"
        if [[ -z "$ORACLE_VERDICT" || "$ORACLE_VERDICT" != "$LEAN_VERDICT" \
              || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            status="RED"; red=$((red+1))
        fi
        echo "[rotate] model=[$arg] oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=Specified(0) $status" | tee -a "$log"
    done < <("$SPECLAB_TEST_BIN" --tree-samples)
    echo "SWEEP SUMMARY [rotate]: samples=$n red=$red"
    [[ $red -eq 0 && $n -ge 120 ]] || fail "rotate sweep: samples=$n red=$red"
}

do_buildsweep() { # build-only sweep (every 5th sweep model)
    local n=0 red=0 idx=0
    while read -r arg; do
        [[ -n "$arg" ]] || continue
        idx=$((idx+1))
        (( idx % 5 == 1 )) || continue
        "$SPECLAB_TEST_BIN" --emit-tree build-only "$arg" \
            > "$OUTPUT_DIR/b.c" || fail "emit build-only [$arg]"
        run_pair "$OUTPUT_DIR/b.c" "buildsweep"
        n=$((n+1))
        local status="OK"
        if [[ -z "$ORACLE_VERDICT" || "$ORACLE_VERDICT" != "$LEAN_VERDICT" \
              || "$ORACLE_VERDICT" != "Specified(0)" ]]; then
            status="RED"; red=$((red+1))
        fi
        echo "[build-only] model=[$arg] oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=Specified(0) $status"
    done < <("$SPECLAB_TEST_BIN" --tree-samples)
    echo "BUILD SWEEP SUMMARY: samples=$n red=$red"
    [[ $red -eq 0 && $n -ge 20 ]] || fail "build-only sweep: samples=$n red=$red"
}

# ---- fuzz + shrink --------------------------------------------------
stream_csv() { # n-th deterministic VALID rotate stream (seed, idx)
    awk -v seed="$1" -v idx="$2" 'BEGIN {
        srand(seed);
        # burn deterministically: 400 draws per earlier stream (max
        # draws per stream ~ 12*5 + 13 + 1 + 8 << 400)
        for (j = 0; j < idx * 400; j++) x = rand();
        budget = 12; pending = 1; used = 0; out = ""; sep = "";
        while (pending > 0) {
            if (used < budget && rand() < 0.55) {
                out = out sep "1," int(rand()*256) "," int(rand()*256) "," int(rand()*256) "," int(rand()*256);
                used++; pending++;
            } else {
                out = out sep "0";
                pending--;
            }
            sep = ",";
        }
        plen = int(rand() * 9);
        out = out "," plen;
        for (j = 0; j < plen; j++) out = out "," int(rand()*2);
        print out;
    }'
}

# returns 0 if the stream DIVERGES (used by the shrinker)
diverges() {
    local csv="$1"
    "$SPECLAB_TEST_BIN" --emit-tree rotate-stream "$csv" > "$OUTPUT_DIR/f.c" 2>/dev/null || return 1
    run_pair "$OUTPUT_DIR/f.c" "fuzz"
    [[ "$ORACLE_VERDICT" != "$LEAN_VERDICT" || "$ORACLE_VERDICT" != "Specified(0)" ]]
}

shrink_stream() { # csv -> minimal diverging stream (byte-wise toward
                  # 0; candidates re-validated by the emitter, invalid
                  # candidates skipped — structural shrink parked)
    local cur="$1" changed=1
    while [[ $changed -eq 1 ]]; do
        changed=0
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
        if ! "$SPECLAB_TEST_BIN" --emit-tree rotate-stream "$csv" > "$OUTPUT_DIR/f.c" 2>/dev/null; then
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
            "$SPECLAB_TEST_BIN" --emit-tree rotate-stream "$minimal" \
                > "$OUTPUT_DIR/minimal_counterexample.c" 2>/dev/null
            echo "minimal counterexample program left at $OUTPUT_DIR/minimal_counterexample.c"
        fi
        if (( n % 25 == 0 )); then echo "  ... fuzz progress: $n run, $div divergences"; fi
    done
    echo "FUZZ SUMMARY: requested=$count run=$n invalid_skipped=$invalid divergences=$div (seed=$seed)"
    [[ $div -eq 0 ]] || fail "fuzz: $div divergence(s)"
}

# ---- plant ----------------------------------------------------------
plant_case() { # mode arg kind(healthy|plant|blindspot|malformed) label
    local pmode="$1" arg="$2" kind="$3" label="$4"
    local predict
    predict=$("$SPECLAB_TEST_BIN" --tree-predict "$pmode" "$arg" | head -1) \
        || fail "predict $pmode [$arg]"
    "$SPECLAB_TEST_BIN" --emit-tree "$pmode" "$arg" > "$OUTPUT_DIR/p.c" \
        || fail "emit $pmode [$arg]"
    run_pair "$OUTPUT_DIR/p.c" "plant"
    echo "[plant:$label] model=[$arg] oracle=$ORACLE_VERDICT lean=$LEAN_VERDICT predict=$predict"
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
    local M0='(1 (2 (3 L (4 L L)) (5 L L)) (6 L L))|l'
    # healthy references (worked-example shape, root rotation, bounds)
    plant_case rotate "$M0" healthy "rotate-healthy"
    plant_case rotate '(1 (2 (3 L (4 L L)) (5 L L)) (6 L L))|' healthy "rotate-healthy-root"
    plant_case rotate 'L|' healthy "rotate-healthy-leaf"
    plant_case rotate '(2147483647 (-2147483648 L (2147483646 L L)) L)|' healthy "rotate-healthy-bounds"
    # the wrong-child-swap / dropped-subtree plants
    plant_case rotate-swap-plant "$M0" plant "rotate-childswap"
    plant_case rotate-swap-plant '(1 (2 L (3 L L)) (4 L L))|' plant "rotate-childswap-root"
    plant_case rotate-drop-plant "$M0" plant "rotate-dropsubtree"
    plant_case rotate-drop-plant '(-1 (-2147483648 L (2147483647 (7 L L) (8 L L))) L)|' plant "rotate-dropsubtree-bigorphan"
    # the DOCUMENTED blind spots (plant invisible — green, predicted 0
    # pure-side; register S4)
    plant_case rotate-swap-plant '(7 (7 L L) L)|' blindspot "rotate-childswap-selfsimilar-blindspot"
    plant_case rotate-swap-plant '(5 L (6 L L))|' blindspot "rotate-childswap-offshape-blindspot"
    plant_case rotate-drop-plant '(1 (2 L L) (3 L L))|' blindspot "rotate-dropsubtree-nullmiddle-blindspot"
    plant_case rotate-drop-plant '(1 (2 L L) L)|rr' blindspot "rotate-dropsubtree-offshapepath-blindspot"
    # the malformed-stream twins (the 254 total-harness arm)
    plant_case rotate-raw "1,5,0,0,0" malformed "rotate-truncated-children"
    plant_case rotate-raw "2,0" malformed "rotate-bad-presence-byte"
    plant_case rotate-raw "0" malformed "rotate-missing-path-count"
    plant_case rotate-raw "0,9,1,1,1,1,1,1,1,1,1" malformed "rotate-path-over-cap"
    plant_case rotate-raw "0,1,2" malformed "rotate-bad-path-bit"
    plant_case rotate-raw "0,0,7" malformed "rotate-trailing-junk"
    local overcap
    overcap=$(awk 'BEGIN { s=""; for (i=0;i<32;i++) s=s "1,0,0,0,0,"; for (i=0;i<33;i++) s=s "0,"; print s "0" }')
    plant_case rotate-raw "$overcap" malformed "rotate-32-nodes-over-cap"
    echo "PLANT SUMMARY: wrong-child-swap plant RED at the locus-val byte (content signature, leak-free); dropped-subtree plant RED in the 255 length arm (structural signature, the leak arm's witness); healthy + blind-spot twins green as predicted; malformed twins at 254"
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
    local samples=('(1 (2 (3 L (4 L L)) (5 L L)) (6 L L))|l' 'L|' \
        '(-1 (2147483647 L L) L)|' '(0 (0 L L) (0 L L))|r' \
        '(-2147483648 (-1 (1 L L) (2 L L)) (3 L L))|l' \
        '(1 (2 (4 L L) (5 L L)) (3 (6 L L) (7 L L)))|')
    local n=0 red=0
    for arg in "${samples[@]:0:$count}"; do
        local predict pstdout
        predict=$("$SPECLAB_TEST_BIN" --tree-predict rotate-form2 "$arg" | sed -n 1p)
        pstdout=$("$SPECLAB_TEST_BIN" --tree-predict rotate-form2 "$arg" | sed -n 2p)
        "$SPECLAB_TEST_BIN" --emit-tree rotate-form2 "$arg" > "$OUTPUT_DIR/f2.c" \
            || fail "emit form2 [$arg]"
        local oline lline
        oline=$(timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
            --exec --batch --mode=exhaustive "$OUTPUT_DIR/f2.c" 2>&1 | grep 'Defined' | head -1)
        timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
            --cabs-json "$OUTPUT_DIR/f2.c" > "$OUTPUT_DIR/f2.json" 2>/dev/null \
            || fail "cabs-json refused form2 [$arg]"
        lline=$(cd "$PROJECT_ROOT" && LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" \
            "$CERBERUS_LEAN_BIN" --batch "${LIBC_ARGS[@]}" "$OUTPUT_DIR/f2.json" 2>&1 \
            | grep 'Defined' | head -1)
        n=$((n+1))
        local want="Defined {value: \"$predict\", stdout: \"$pstdout\", stderr: \"\", blocked: \"false\"}"
        if [[ "$oline" == "$want" && "$lline" == "$want" ]]; then
            echo "[form2] model=[$arg] OK"
        else
            red=$((red+1))
            echo "[form2] model=[$arg] RED"
            echo "    O: $oline"
            echo "    L: $lline"
            echo "    P: $want"
        fi
    done
    echo "FORM2 SUMMARY: samples=$n red=$red"
    [[ $red -eq 0 ]] || fail "form2: $red red"
}

# ---- pinned-term gate (drift + param pins + in-Lean exec + leak) ----
do_gate() {
    (cd "$PROJECT_ROOT/lean_frontend/speclab" && \
        "$SCRIPT_DIR/capped" lake build speclab-tree-core-test >/dev/null 2>&1) \
        || fail "speclab-tree-core-test build failed"
    local bin="$PROJECT_ROOT/lean_frontend/speclab/.lake/build/bin/speclab-tree-core-test"
    [[ -f "$bin" ]] || fail "speclab-tree-core-test binary missing"
    (cd "$PROJECT_ROOT" && "$bin") || fail "TreeGateTest red"
}

case "$MODE" in
    --gate)       do_gate ;;
    --sweep)      do_sweep ;;
    --buildsweep) do_buildsweep ;;
    --fuzz)       do_fuzz "${2:?--fuzz needs N}" "${3:-20260822}" ;;
    --plant)      do_plant ;;
    --form2)      do_form2 "${2:-6}" ;;
    *) fail "unknown mode: $MODE" ;;
esac

echo "test_speclab_tree: PASS ($MODE)"
exit 0
