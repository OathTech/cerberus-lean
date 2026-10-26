#!/usr/bin/env bash
# check_runtime_resolution.sh — row-1 witnesses for the Lean driver's runtime
# resolution and the library-location test (bug hunt 2026-09-29, BUG-2 and
# BUG-3; record lean_frontend/docs/2026-09-29_bug-hunt-fixes-record.md §S2).
#
# The driver resolves std.core and the .impl file like the oracle's
# util/cerb_runtime.ml: `--runtime DIR`, else CERB_INSTALL_PREFIX (runtime =
# DIR/lib/cerberus-lib/runtime); otherwise it REFUSES (exit 2). It never
# searches the working directory and deliberately does not mirror the
# oracle's OPAM_SWITCH_PREFIX fallback (Main.lean resolveRuntime). A Cabs
# location whose directory passes the port's suffix library test but not the
# resolved-directory membership test against the runtime is REFUSED. The
# oracle's literal test can differ on accepted aliases: the fixture-001
# witness below pins that declared divergence (Core quotation D2b/D5).
# A `#line` plant then pins the SERVED consequence: a UB inside a function
# placed at the ./-prefixed runtime header directory is reported at the
# function body by the oracle (`<2:10--2:15>`) and at the call site by the
# port (`<11:10--11:23>`); the unprefixed spelling agrees on the call site.
# The pin goes red if either engine's rule moves. The selftest plants below
# (ignore-runtime, refuse-all) cover it: neither stub prints that line.
#
# Each check runs the REAL oracle (cabs-json export, and the oracle's own
# verdict where the check compares against it) and the Lean driver.
# Fail-closed: a missing binary, a missing runtime, or any unexpected outcome
# fails the script.
#
# Usage: check_runtime_resolution.sh             the witnesses
#        check_runtime_resolution.sh --selftest  plants: the witnesses must FAIL
#            against (a) a stub driver that ignores the runtime and always
#            prints the correct verdict, and (b) a stub that refuses
#            everything; then the witnesses run on the real driver.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REAL_BIN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$REAL_BIN}"
ORACLE="$ROOT/_build/default/backend/driver/main.exe"
PREFIX="$ROOT/_build/install/default"
RT="$PREFIX/lib/cerberus-lib/runtime"
NAME=check_runtime_resolution

if [[ "${1:-}" == "--selftest" ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    # (a) ignores the runtime: always the correct verdict of the control program
    printf '#!/usr/bin/env bash\necho %q\nexit 1\n' \
        'Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<3:11--3:17>"}' > "$ST/ignore-runtime"
    # (b) refuses everything
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" %q >&2\nexit 2\n' \
        'cerberus-lean stop ["1","REFUSAL","runtime",null,"plant","plant mover",null,"plant"]' > "$ST/refuse-all"
    chmod +x "$ST/ignore-runtime" "$ST/refuse-all"
    for plant in ignore-runtime refuse-all; do
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
[[ -f "$RT/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged: $RT/libcore/std.core"; exit 1; }
mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
W=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
trap 'rm -rf "$W"' EXIT

check_refusal() {  # boundary, JSON item list (or null), required and forbidden detail
    python3 - "$SCRIPT_DIR" "$W/stdout" "$W/stderr" "$RC" "$@" <<'PY'
import json, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from test_stops import assert_cli_refusals
assert_cli_refusals(Path(sys.argv[2]).read_bytes(), Path(sys.argv[3]).read_bytes(),
                    int(sys.argv[4]), sys.argv[5] or None, json.loads(sys.argv[6]),
                    sys.argv[7], sys.argv[8] if len(sys.argv) > 8 else '')
PY
}
fails=0; n=0
fail() { echo "$NAME: FAIL — $*"; fails=$((fails + 1)); }

# oracle helpers (explicit --runtime, as every harness passes it)
cabs() {  # <prefix> <c-file> <json-out> [cwd]
    ( cd "${4:-$W}" && env -u CERB_INSTALL_PREFIX "$ORACLE" --runtime="$1" --cabs-json "$2" > "$3" 2> "$3.err" ) \
        && [[ -s "$3" ]] || { echo "$NAME: FAIL — oracle --cabs-json failed for $2: $(head -c 300 "$3.err")"; exit 1; }
}
oracle_line() {  # <prefix> <c-file> [cwd] -> first verdict line
    ( cd "${3:-$W}" && env -u CERB_INSTALL_PREFIX "$ORACLE" --runtime="$1" --exec --batch --nolibc "$2" 2>/dev/null ) \
        | grep -E '^(Defined|Undefined|Error) ' | head -1
}
# lean <cwd> <env-assignments...> -- <driver args...> -> sets OUT, ERR, RC
lean() {
    local cwd="$1"; shift
    local envs=()
    while [[ "$1" != "--" ]]; do envs+=("$1"); shift; done
    shift
    (cd "$cwd" && env -u CERB_INSTALL_PREFIX -u OPAM_SWITCH_PREFIX LEAN_ABORT_ON_PANIC=1 \
        ${envs[@]+"${envs[@]}"} "$BIN" "$@") > "$W/stdout" 2> "$W/stderr"; RC=$?
    OUT=$(<"$W/stdout"); ERR=$(<"$W/stderr")
}
expect_line() {  # <label> <expected-line>
    n=$((n + 1))
    if [[ "$OUT" != "$2" ]]; then fail "$1: expected exactly [$2]; got rc=$RC: ${OUT:0:300}"; fi
    if [[ "$ERR" != 'cerberus-lean switches: []' ]]; then fail "$1: expected the default switch report on stderr; got: ${ERR:0:300}"; fi
}
expect_refusal() {  # <label> <refusal-prefix> <substring>
    n=$((n + 1))
    local boundary=runtime
    [[ "$2" == "library-location classification:" ]] && boundary=library-location
    if ! check_refusal "$boundary" null "$3"; then
        fail "$1: expected exit 2 + 'refused — $2' naming '$3'; got rc=$RC: ${OUT:0:300}"
    fi
}

# --- inputs -----------------------------------------------------------------
printf 'int main(void) {\n  double d = 1e30;\n  int x = (int)d;\n  return x;\n}\n' > "$W/ub2.c"
cabs "$PREFIX" "$W/ub2.c" "$W/ub2.json"
UB2=$(oracle_line "$PREFIX" "$W/ub2.c")
[[ "$UB2" == 'Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<3:11--3:17>"}' ]] \
    || { echo "$NAME: FAIL — oracle control verdict changed: [$UB2]"; exit 1; }
# A planted working directory: runtime/libcore/{std.core,impls} with std.core's
# UB017 arm replaced by Specified(7) (the bug hunt's BUG-2 witness).
mkdir -p "$W/cwd/runtime/libcore"
cp -r "$ROOT/runtime/libcore/impls" "$W/cwd/runtime/libcore/"
sed 's/undef(<<UB017_out_of_range_floating_integer_conversion>>)/Specified(7)/' \
    "$RT/libcore/std.core" > "$W/cwd/runtime/libcore/std.core"
cmp -s "$RT/libcore/std.core" "$W/cwd/runtime/libcore/std.core" \
    && { echo "$NAME: FAIL — std.core plant did not change the file (the UB017 arm moved?)"; exit 1; }
# A planted PREFIX with the same std.core: both engines must use it.
PP="$W/pfx"; PRT="$PP/lib/cerberus-lib/runtime"
mkdir -p "$PRT/libc"
cp -r "$W/cwd/runtime/libcore" "$PRT/"
cp -rL "$RT/libc/include" "$PRT/libc/"
cabs "$PP" "$W/ub2.c" "$W/ub2p.json"
UB2P=$(oracle_line "$PP" "$W/ub2.c")
[[ "$UB2P" == 'Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}' ]] \
    || { echo "$NAME: FAIL — oracle does not use the planted prefix: [$UB2P]"; exit 1; }

# --- BUG-2: runtime resolution ----------------------------------------------
lean "$W" -- --batch --runtime="$PREFIX" "$W/ub2.json";              expect_line "--runtime=DIR" "$UB2"
lean "$W" -- --batch --runtime "$PREFIX" "$W/ub2.json";              expect_line "--runtime DIR" "$UB2"
lean "$W" CERB_INSTALL_PREFIX="$PREFIX" -- --batch "$W/ub2.json";    expect_line "CERB_INSTALL_PREFIX" "$UB2"
lean "$W/cwd" -- --batch --runtime="$PREFIX" "$W/ub2.json";          expect_line "planted cwd std.core ignored (--runtime)" "$UB2"
lean "$W/cwd" CERB_INSTALL_PREFIX="$PREFIX" -- --batch "$W/ub2.json"; expect_line "planted cwd std.core ignored (env)" "$UB2"
lean "$W" CERB_INSTALL_PREFIX=/nonexistent -- --batch --runtime="$PREFIX" "$W/ub2.json"
expect_line "--runtime has priority over CERB_INSTALL_PREFIX (cerb_runtime.ml:50-52)" "$UB2"
lean "$W" -- --batch --runtime="$PP" "$W/ub2p.json";                 expect_line "planted prefix is used (agrees with the oracle on it)" "$UB2P"
lean "$W/cwd" -- --batch "$W/ub2.json"
expect_refusal "no runtime, from the planted cwd" "runtime:" "no runtime given"
lean "$W/cwd" OPAM_SWITCH_PREFIX="$PREFIX" -- --batch "$W/ub2.json"
expect_refusal "OPAM_SWITCH_PREFIX is not a fallback" "runtime:" "OPAM_SWITCH_PREFIX fallback is deliberately NOT mirrored"
lean "$W" -- --batch --runtime=/nonexistent "$W/ub2.json"
expect_refusal "missing runtime" "runtime:" "couldn't find the Core standard library file (looked at: \`/nonexistent/lib/cerberus-lib/runtime/libcore/std.core')"
lean "$W" CERB_INSTALL_PREFIX= -- --batch "$W/ub2.json"
expect_refusal "empty CERB_INSTALL_PREFIX" "runtime:" "CERB_INSTALL_PREFIX is set but empty"
lean "$W" -- --batch --runtime= "$W/ub2.json"
expect_refusal "empty --runtime" "runtime:" "--runtime was given an empty directory"
lean "$W" -- --batch --runtime="$PP" "$W/ub2.json"
expect_refusal "cabs-json made under another runtime" "library-location classification:" "$RT/libc/include/builtins.h"

# --- BUG-3: suffix-library but not exact-library locations refuse -------------
mkdir -p "$W/user/runtime/libcore" "$W/user/other" "$W/hdr/runtime/libc/include"
printf 'int f(int x) {\n  return x + 1;\n}\nint main(void) {\n  return f(2147483647);\n}\n' > "$W/user/runtime/libcore/liblocub.c"
cp "$W/user/runtime/libcore/liblocub.c" "$W/user/other/liblocub.c"
printf '#line 1 "lib/runtime/libcore/gen.c"\nint main(void) {\n  int x = 2147483647;\n  return x + 1;\n}\n' > "$W/ln03.c"
printf 'static int add1(int x) { return x + 1; }\n' > "$W/hdr/runtime/libc/include/myhelp.h"
printf '#include "runtime/libc/include/myhelp.h"\nint main(void) {\n  return add1(2147483647);\n}\n' > "$W/hdr/f06.c"
cabs "$PREFIX" user/runtime/libcore/liblocub.c "$W/l1.json"
cabs "$PREFIX" "$W/ln03.c" "$W/l2.json"
cabs "$PREFIX" f06.c "$W/l3.json" "$W/hdr"
cabs "$PREFIX" user/other/liblocub.c "$W/l4.json"
lean "$W" -- --batch --runtime="$PREFIX" "$W/l1.json"
expect_refusal "user file under …/runtime/libcore" "library-location classification:" "user/runtime/libcore/liblocub.c"
lean "$W" -- --batch --runtime="$PREFIX" "$W/l2.json"
expect_refusal "#line naming …/runtime/libcore" "library-location classification:" "lib/runtime/libcore/gen.c"
lean "$W" -- --batch --runtime="$PREFIX" "$W/l3.json"
expect_refusal "user header under …/runtime/libc/include" "library-location classification:" "runtime/libc/include/myhelp.h"
L4=$(oracle_line "$PREFIX" user/other/liblocub.c)
[[ "$L4" == Undefined* ]] || { echo "$NAME: FAIL — oracle control verdict for liblocub.c: [$L4]"; exit 1; }
lean "$W" -- --batch --runtime="$PREFIX" "$W/l4.json";               expect_line "control: the same file elsewhere agrees with the oracle" "$L4"

# --- Accepted relative spelling: actual oracle/port classifiers disagree -----
# The committed fixture has cpp's ./ prefix; the oracle's runtime key does not
# (util/cerb_location.ml:512-523). Do not normalize the witness's stored label.
HEADER=$(python3 - "$ROOT/tests/fixtures/001-return-literal/cabs.json" <<'PYLOC'
import json, sys
paths = []
def visit(x):
    if isinstance(x, dict):
        if {"file", "line", "col"} <= x.keys() and x["file"].endswith("/builtins.h"):
            paths.append(x["file"])
        for v in x.values(): visit(v)
    elif isinstance(x, list):
        for v in x: visit(v)
visit(json.load(open(sys.argv[1])))
expected = "./_build/install/default/lib/cerberus-lib/runtime/libc/include/builtins.h"
if len(paths) != 154 or set(paths) != {expected}:
    raise SystemExit("fixture-001 library-location witness drift: expected 154 ./-prefixed positions")
print(expected)
PYLOC
) || { echo "$NAME: FAIL — fixture-001 location inventory"; exit 1; }
cat > "$W/location.ml" <<'OCAML'
let () =
  Cerb_runtime.specified_runtime := Some Sys.argv.(1);
  let pos = Cerb_position.from_lexing { Lexing.dummy_pos with pos_fname = Sys.argv.(2) } in
  Printf.printf "%b\n" (Cerb_location.is_library_location (Cerb_location.point pos))
OCAML
if ! ocamlfind ocamlopt -package unix,str,lem,pprint,yojson -linkpkg \
    -I "$ROOT/_build/default/util/.cerb_util.objs/byte" \
    -I "$ROOT/_build/default/util/.cerb_util.objs/native" -I "$ROOT/_build/default/util" \
    "$ROOT/_build/default/util/cerb_util.cmxa" "$W/location.ml" -o "$W/location"; then
    echo "$NAME: FAIL — cannot build actual oracle library-location probe"; exit 1
fi
cat > "$W/Location.lean" <<'LEAN'
import CerbLocation
def main (args : List String) : IO Unit := do
  match args with
  | [path] => IO.println (CerbLocation.isLibraryPathSuffix path)
  | _ => throw (IO.userError "library-location probe requires one path")
LEAN
OCLASS=$(cd "$ROOT" && "$W/location" _build/install/default "$HEADER") \
    || { echo "$NAME: FAIL — oracle library-location probe"; exit 1; }
OCONTROL=$(cd "$ROOT" && "$W/location" _build/install/default "${HEADER#./}") \
    || { echo "$NAME: FAIL — oracle library-location control"; exit 1; }
LCLASS=$(cd "$ROOT/lean_frontend" && "$SCRIPT_DIR/capped" lake env lean --run "$W/Location.lean" "$HEADER") \
    || { echo "$NAME: FAIL — port library-location probe"; exit 1; }
n=$((n + 1))
if [[ "$OCLASS" != false || "$LCLASS" != true || "$OCONTROL" != true ]]; then
    fail "fixture-001 classification drift: oracle=$OCLASS port=$LCLASS oracle-no-dot-control=$OCONTROL"
fi
echo "$NAME: fixture-001 --runtime=_build/install/default: 154 ./-prefixed header positions; oracle library=$OCLASS; port library=$LCLASS; oracle without ./=$OCONTROL (declared divergence)"
F001=$(oracle_line _build/install/default tests/fixtures/001-return-literal/source.c "$ROOT") \
    || { echo "$NAME: FAIL — fixture-001 oracle execution failed"; exit 1; }
[[ "$F001" == 'Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}' ]] \
    || { echo "$NAME: FAIL — fixture-001 oracle execution verdict: [$F001]"; exit 1; }
lean "$ROOT" -- --batch --runtime=_build/install/default tests/fixtures/001-return-literal/cabs.json
expect_line "relative fixture-001 is served; execution agrees despite classification divergence" "$F001"
[[ $RC -eq 0 ]] || fail "relative fixture-001 exit $RC, expected 0"
echo "$NAME: fixture-001 execution: oracle=[$F001]; port=[$OUT]"

# --- Served divergence pin: a #line plant at the ./-prefixed runtime header --
# dot: the spelling cpp emits under --runtime=_build/install/default; the
# oracle says not-library and reports the UB inside the function, the port
# says library and substitutes the call site (core_eval.lem:602). nodot: the
# oracle's literal key; both substitute the call site. Both engines run from
# the repository root at the relative runtime, as the fixture-001 case above.
plant() {  # <name> <library-directory-spelling>
    printf '#line 1 "%s/plant.h"\nint f(int x) {\n  return x + 1;\n}\n#line 10 "%s.c"\nint main(void) {\n  return f(2147483647);\n}\n' "$2" "$1" > "$W/$1.c"
    cabs _build/install/default "$W/$1.c" "$W/$1.json" "$ROOT"
}
plant dot   ./_build/install/default/lib/cerberus-lib/runtime/libc/include
plant nodot _build/install/default/lib/cerberus-lib/runtime/libc/include
BODY='Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<2:10--2:15>"}'
SITE='Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}'
ODOT=$(oracle_line _build/install/default "$W/dot.c" "$ROOT")
ONODOT=$(oracle_line _build/install/default "$W/nodot.c" "$ROOT")
n=$((n + 1))
[[ "$ODOT" == "$BODY" ]] || fail "served-divergence pin: oracle verdict for the ./ plant moved: expected exactly [$BODY]; got [$ODOT]"
n=$((n + 1))
[[ "$ONODOT" == "$SITE" ]] || fail "served-divergence pin control: oracle verdict for the unprefixed plant moved: expected exactly [$SITE]; got [$ONODOT]"
lean "$ROOT" -- --batch --runtime=_build/install/default "$W/dot.json"
expect_line "served-divergence pin: ./ plant is served; the port reports the call site where the oracle reports the body" "$SITE"
[[ $RC -eq 1 ]] || fail "served-divergence pin: ./ plant exit $RC, expected 1"
PDOT=$OUT
lean "$ROOT" -- --batch --runtime=_build/install/default "$W/nodot.json"
expect_line "served-divergence pin control: unprefixed plant agrees with the oracle" "$SITE"
[[ $RC -eq 1 ]] || fail "served-divergence pin control: unprefixed plant exit $RC, expected 1"
echo "$NAME: served-divergence pin: ./ plant oracle=[$ODOT] port=[$PDOT]; unprefixed plant oracle=[$ONODOT] port=[$OUT]"

[[ $fails -eq 0 ]] || { echo "$NAME: $fails of $n witnesses FAILED"; exit 1; }
echo "$NAME: OK ($n witnesses: --runtime/CERB_INSTALL_PREFIX resolution and priority, planted cwd std.core ignored, planted prefix used, 5 runtime refusals, 1 cross-runtime and 3 library-location refusals, 1 control agreeing with the oracle, relative fixture-001 classification divergence and execution control, served UB-location divergence pin with its unprefixed control)"
