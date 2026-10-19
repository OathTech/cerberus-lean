#!/usr/bin/env bash
# Translation must refuse exhaustion in dead code and constant expressions.
set -euo pipefail
ulimit -c 0
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

build_cerberus
build_lean
WORK=$(mktemp -d "$TMP_DIR/translation-fuel.XXXXXXXXXX")
register_cleanup "$WORK"

# Keep the fixtures small in the repository and make their depth explicit.
# The ordinary main is identical in the first three files; neither dead function
# is called. Each witness isolates one of the two ambient translation workers.
python3 - "$WORK" <<'PY'
from pathlib import Path
import sys

out = Path(sys.argv[1])
main = 'int main(void) { return 0; }\n'
depth = 192
(out / 'control.c').write_text(main)
(out / 'expression.c').write_text(
    'int unused(void) { return ' + '1 + (' * depth + '0' + ')' * depth + '; }\n' + main)
(out / 'statement.c').write_text(
    'int unused(void) {' + '{' * depth + 'return 0;' + '}' * depth + '}\n' + main)
(out / 'constant-expression.c').write_text(
    'enum { X = ' + '1 + (' * depth + '0' + ')' * depth + ' };\n'
    'int main(void) { return X; }\n')
PY

failed=0
for name in control expression statement; do
    "${CAPPED_TEST[@]}" timeout 30 "$CERBERUS_BIN" --runtime="$CERB_INSTALL_PREFIX" \
        --cabs-json "$WORK/$name.c" > "$WORK/$name.json"
    for fuel in 128 100000; do
        rc=0
        LEAN_ABORT_ON_PANIC=1 "${CAPPED_TEST[@]}" timeout 30 "$CERBERUS_LEAN_BIN" \
            --batch --first --runtime="$CERB_INSTALL_PREFIX" --fuel "$fuel" \
            "$WORK/$name.json" > "$WORK/$name.$fuel.out" 2> "$WORK/$name.$fuel.err" || rc=$?
        capture=$(cat "$WORK/$name.$fuel.out" "$WORK/$name.$fuel.err")
        if [[ "$name" != control && "$fuel" == 128 ]]; then
            classification=$(classify_fuel_outcome "$rc" "$capture")
            if [[ "$rc" != 134 || "$classification" != FUEL:panic ]] \
                || ! grep -qE "$FUEL_ELAB_PANIC_LINE_RE" "$WORK/$name.$fuel.err" \
                || [[ -s "$WORK/$name.$fuel.out" ]]; then
                echo "translation-fuel: FAIL $name fuel=$fuel exit=$rc class=$classification" >&2
                echo "$capture" >&2
                failed=1
                continue
            fi
            echo "translation-fuel: $name fuel=$fuel exit=$rc class=$classification (translation boundary)"
            grep -E '^PANIC at .*: lem: fuel exhausted$' "$WORK/$name.$fuel.err"
        else
            if [[ "$rc" != 0 ]] || [[ -s "$WORK/$name.$fuel.err" ]] \
                || ! grep -qxF 'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}' "$WORK/$name.$fuel.out"; then
                echo "translation-fuel: FAIL $name fuel=$fuel exit=$rc (expected successful control)" >&2
                echo "$capture" >&2
                failed=1
                continue
            fi
            echo "translation-fuel: $name fuel=$fuel exit=0 Defined Specified(0)"
        fi
    done
done

# Mini_pipeline runs constant-expression translation under plain runStateM;
# recording an error there previously let the placeholder become a UB verdict.
"${CAPPED_TEST[@]}" timeout 30 "$CERBERUS_BIN" --runtime="$CERB_INSTALL_PREFIX" \
    --cabs-json "$WORK/constant-expression.c" > "$WORK/constant-expression.json"
for mode in --batch --pp-core; do
    log="$WORK/constant-expression.$mode"
    rc=0
    LEAN_ABORT_ON_PANIC=1 "${CAPPED_TEST[@]}" timeout 30 "$CERBERUS_LEAN_BIN" \
        "$mode" --runtime="$CERB_INSTALL_PREFIX" --fuel 128 \
        "$WORK/constant-expression.json" > "$log.out" 2> "$log.err" || rc=$?
    capture=$(cat "$log.out" "$log.err")
    classification=$(classify_fuel_outcome "$rc" "$capture")
    if [[ "$rc" != 134 || "$classification" != FUEL:panic ]] \
        || ! grep -qE "$FUEL_ELAB_PANIC_LINE_RE" "$log.err" \
        || [[ -s "$log.out" ]]; then
        echo "translation-fuel: FAIL constant-expression mode=$mode fuel=128 exit=$rc class=$classification" >&2
        echo "$capture" >&2
        failed=1
    else
        echo "translation-fuel: constant-expression mode=$mode fuel=128 exit=$rc class=$classification"
        grep -E "$FUEL_ELAB_PANIC_LINE_RE" "$log.err"
    fi
done

# Use the driver's default fuel and compare with the oracle's actual result.
log="$WORK/constant-expression.default.log"
rc=0
SKIP_BUILD=1 "$SCRIPT_DIR/test_exec.sh" "$WORK/constant-expression.c" > "$log" 2>&1 || rc=$?
if [[ "$rc" != 0 ]] || ! grep -qxF '[1/1] MATCH constant-expression: VAL:{value: "Specified(192)", stdout: "", stderr: "", blocked: "false"}' "$log"; then
    echo "translation-fuel: FAIL constant-expression at default fuel (exec lane exit=$rc)" >&2
    cat "$log" >&2
    failed=1
else
    grep '^\[1/1\] MATCH constant-expression:' "$log"
fi
if [[ "$failed" != 0 ]]; then
    echo 'translation-fuel: FAIL (see rejected witnesses above)' >&2
    exit 1
fi
echo 'translation-fuel: PASS (two dead-code witnesses, constant-expression refusal in batch and pp-core, five successful controls)'
