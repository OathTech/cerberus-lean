#!/usr/bin/env bash
# check_cabs_json_utf8.sh — row-1 witnesses for the non-UTF-8 Cabs JSON
# refusal (bug hunt 2026-09-29, BUG-6 and K-5; record
# lean_frontend/docs/2026-09-29_bug-hunt-fixes-record.md §S3).
#
# The oracle's --cabs-json exporter writes a byte >= 0x80 of a file name (the
# real path, a #line or an #include name: backend/lean_export/cabs_json.ml:30),
# of a Loc_other string (:44), or of a text field (attribute-argument strings,
# :599/:601; magic comments, :657) into the JSON raw, so the document is not
# UTF-8. The Lean bridge cannot carry such bytes (Lean strings are Unicode
# scalar values); it used to die with an uncaught exception ("Tried to read
# file ... containing non UTF-8 data", rc 1). It now REFUSES: exit 2 and
# `cerberus-lean: refused — non-UTF-8 Cabs JSON: …` naming the feature and the
# boundary (Main.lean readCabsJson). String-literal and character-constant
# bytes are byte-carriers (scripts/test_cabs_bytes_probe.py) and unaffected.
#
# Each witness exports the C file with the REAL oracle and runs the Lean
# driver on the JSON; each control is the same program with ASCII names and
# must agree with the oracle's own verdict. Fail-closed.
#
# Usage: check_cabs_json_utf8.sh             the witnesses
#        check_cabs_json_utf8.sh --selftest  plants: the witnesses must FAIL
#            against (a) a stub reproducing the pre-fix uncaught exception and
#            (b) a stub that refuses everything; then the real run.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$ROOT/lean_frontend/.lake/build/bin/cerberus-lean}"
ORACLE="$ROOT/_build/default/backend/driver/main.exe"
PREFIX="$ROOT/_build/install/default"
NAME=check_cabs_json_utf8

if [[ "${1:-}" == "--selftest" ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    # (a) the pre-fix behaviour: uncaught exception, rc 1, on every input
    printf '#!/usr/bin/env bash\necho "uncaught exception: Tried to read file (plant) containing non UTF-8 data." >&2\nexit 1\n' > "$ST/uncaught"
    # (b) refuses everything, in the right words
    printf '#!/usr/bin/env bash\necho "cerberus-lean: refused — non-UTF-8 Cabs JSON: plant" >&2\nexit 2\n' > "$ST/refuse-all"
    chmod +x "$ST/uncaught" "$ST/refuse-all"
    for plant in uncaught refuse-all; do
        if CERB_LEAN_BIN_OVERRIDE="$ST/$plant" "$0" > "$ST/$plant.out" 2>&1; then
            echo "$NAME: SELFTEST FAIL — plant '$plant' PASSED the witnesses (vacuous check)"
            cat "$ST/$plant.out"
            exit 1
        fi
        echo "$NAME: selftest plant '$plant' caught: $(grep -c 'FAIL —' "$ST/$plant.out") failing witness(es)"
    done
    "$0"; exit $?   # not exec: the EXIT trap must remove $ST
fi

[[ -x "$BIN" ]] || { echo "$NAME: FAIL — driver not built: $BIN"; exit 1; }
[[ -x "$ORACLE" ]] || { echo "$NAME: FAIL — oracle not built: $ORACLE"; exit 1; }
[[ -f "$PREFIX/lib/cerberus-lib/runtime/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged under $PREFIX"; exit 1; }
mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
W=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
trap 'rm -rf "$W"' EXIT
cd "$W" || { echo "$NAME: FAIL — cd $W"; exit 1; }

fails=0; n=0
fail() { echo "$NAME: FAIL — $*"; fails=$((fails + 1)); }
E=$'\xe9'   # the raw byte 0xE9 (Latin-1 e-acute), never valid UTF-8 on its own

cabs() {  # <c-file> <json-out>; the export itself must succeed
    "$ORACLE" --runtime="$PREFIX" --cabs-json "$1" > "$2" 2> "$2.err" && [[ -s "$2" ]] \
        || { echo "$NAME: FAIL — oracle --cabs-json failed for $(printf %q "$1"): $(head -c 300 "$2.err")"; exit 1; }
}
oracle_line() {  # <c-file> -> first verdict line
    "$ORACLE" --runtime="$PREFIX" --exec --batch --nolibc "$1" 2>/dev/null | grep -aE '^(Defined|Undefined|Error) ' | head -1
}
lean() {  # <json> -> OUT, RC
    OUT=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$PREFIX" "$1" 2>&1); RC=$?
}
witness() {  # <label> <c-file>: the JSON must be non-UTF-8, the oracle must answer, Lean must refuse
    local label="$1" c="$2" j="$W/w$n.json" o
    n=$((n + 1))
    cabs "$c" "$j"
    if python3 -c 'import sys; open(sys.argv[1],"rb").read().decode("utf-8")' "$j" 2>/dev/null; then
        fail "$label: the oracle's JSON is valid UTF-8 — the witness does not reach the boundary"; return
    fi
    o=$(oracle_line "$c")
    [[ "$o" == Defined* || "$o" == Undefined* ]] || { fail "$label: the oracle gives no verdict ([$o]); not a witness"; return; }
    lean "$j"
    if [[ $RC -ne 2 || "$OUT" != *"cerberus-lean: refused — non-UTF-8 Cabs JSON:"* || "$OUT" != *"Unicode scalar values"* ]]; then
        fail "$label: expected exit 2 + the attributed non-UTF-8 refusal; got rc=$RC: ${OUT:0:300}"
    fi
}
control() {  # <label> <c-file>: valid UTF-8 JSON, Lean agrees with the oracle's line
    local label="$1" c="$2" j="$W/c$n.json" o
    n=$((n + 1))
    cabs "$c" "$j"
    o=$(oracle_line "$c")
    lean "$j"
    [[ -n "$o" && "$OUT" == "$o" ]] || fail "$label: expected Lean = oracle [$o]; got rc=$RC: ${OUT:0:300}"
}

# BUG-6 (file names) and K-5 (attribute strings), each with an ASCII control
printf '#line 1 "caf%s.c"\nint main(void) { return 3; }\n' "$E" > ln01.c
printf '#line 1 "cafe.c"\nint main(void) { return 3; }\n' > ln01c.c
printf '#line 1 "caf\\351.c"\nint main(void) {\n  int x = 2147483647; return x + 1;\n}\n' > s15.c
printf 'int main(void) { return 4; }\n' > "caf${E}.c"
printf 'int main(void) { return 4; }\n' > cafe.c
mkdir -p inc
printf 'static int five(void) { return 5; }\n' > "inc/h${E}.h"
printf 'static int five(void) { return 5; }\n' > inc/he.h
printf '#include "inc/h%s.h"\nint main(void) { return five(); }\n' "$E" > incl.c
printf '#include "inc/he.h"\nint main(void) { return five(); }\n' > inclc.c
printf '[[gnu::deprecated("caf%s")]] int f(void) { return 1; }\nint main(void) { return 5; }\n' "$E" > at01.c
printf '[[gnu::deprecated("cafe")]] int f(void) { return 1; }\nint main(void) { return 5; }\n' > at01c.c

witness "#line with a raw 0xE9 byte" ln01.c
control "#line ASCII control" ln01c.c
witness "#line with the octal escape \\351 (cpp decodes it to the byte)" s15.c
witness "a real file name with a raw 0xE9 byte" "caf${E}.c"
control "real file name ASCII control" cafe.c
witness "#include of a header whose name has a raw 0xE9 byte" incl.c
control "#include ASCII control" inclc.c
witness "attribute-argument string with a raw 0xE9 byte (K-5)" at01.c
control "attribute-argument ASCII control" at01c.c

[[ $fails -eq 0 ]] || { echo "$NAME: $fails of $n witnesses FAILED"; exit 1; }
echo "$NAME: OK ($n witnesses: 5 non-UTF-8 Cabs JSONs refused with the attributed message (#line raw byte, #line octal escape, real file name, #include name, attribute string); 4 ASCII controls agree with the oracle)"
