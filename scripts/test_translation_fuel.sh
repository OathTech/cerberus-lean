#!/usr/bin/env bash
# Translation must reject exhausted subtrees even in an uncalled function.
set -euo pipefail
ulimit -c 0
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

build_cerberus
build_lean
WORK=$(mktemp -d "$TMP_DIR/translation-fuel.XXXXXXXXXX")
register_cleanup "$WORK"

# Keep the fixtures small in the repository and make their depth explicit.
# The ordinary main is identical in all three files; neither dead function
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
                || ! grep -qE '^PANIC at _private\.LemLib\.[0-9]+\.failwithIImpl LemLib:[0-9]+:[0-9]+: lem: fuel exhausted$' "$WORK/$name.$fuel.err" \
                || grep -q '^Defined ' "$WORK/$name.$fuel.out"; then
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
if [[ "$failed" != 0 ]]; then
    echo 'translation-fuel: FAIL (see rejected witnesses above)' >&2
    exit 1
fi
echo 'translation-fuel: PASS (two dead-code exhaustion witnesses, four successful controls)'
