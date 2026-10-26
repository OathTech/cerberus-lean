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
# resolved-directory membership test against the runtime is REFUSED. Since
# quotation hygiene Q1 (2026-10-26; [USER 2026-10-21] ruling B of the D5
# re-review) the FORK ORACLE classifies by the same rule — suffix AND resolved
# membership (util/cerb_location.ml is_library_location, a fork-ahead delta
# over pristine's literal key comparison; upstream-tray draft 58) — so the two
# engines classify every served input identically. The fixture-001 witness
# below pins both actual classifiers AGREEING on cpp's ./-prefixed header
# label, and the `#line` plants pin the SERVED agreement: a UB inside a
# function placed at the runtime header directory spelled `./`-prefixed,
# unprefixed, absolute, or at `libcore`, is reported at the call site
# (`<11:10--11:23>`) by BOTH engines (core_eval.lem:602's library-location
# substitution). A plant whose engines disagree is RED; so is any engine
# moving its rule. The selftest plants below (ignore-runtime, refuse-all)
# cover it: neither stub prints that line.
# Quotation hygiene Q2 (2026-10-26; [USER 2026-10-21] ruling C): with
# --quote-core/--quote-libc the driver REFUSES (boundary runtime, item
# --runtime, exit 2, no module) a runtime not given as the canonical relative
# spelling `--runtime=_build/install/default` (an absolute spelling; the
# runtime from CERB_INSTALL_PREFIX alone) and an input carrying a non-portable
# (absolute) label, naming the offending spelling or label; the canonical case
# is the control (exit 0, silent, module written).
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
expect_refusal() {  # <label> <refusal-prefix> <substring> [items-json]
    n=$((n + 1))
    local boundary=runtime
    [[ "$2" == "library-location classification:" ]] && boundary=library-location
    if ! check_refusal "$boundary" "${4:-null}" "$3"; then
        fail "$1: expected exit 2 + 'refused — $2' naming '$3'${4:+ with items $4}; got rc=$RC: ${OUT:0:300} ${ERR:0:300}"
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

# --- Accepted relative spelling: actual oracle/port classifiers AGREE --------
# The committed fixture has cpp's ./ prefix; pristine's literal runtime key does
# not, the fork's resolved rule does (util/cerb_location.ml is_library_location,
# Q1 2026-10-26). Do not normalize the witness's stored label.
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
OFOREIGN=$(cd "$W" && "$W/location" "$ROOT/_build/install/default" "$W/user/runtime/libcore/liblocub.c") \
    || { echo "$NAME: FAIL — oracle library-location foreign-directory probe"; exit 1; }
n=$((n + 1))
if [[ "$OCLASS" != true || "$LCLASS" != true || "$OCONTROL" != true || "$OFOREIGN" != false ]]; then
    fail "fixture-001 classification drift: oracle=$OCLASS port=$LCLASS oracle-no-dot-control=$OCONTROL oracle-foreign-runtime/libcore=$OFOREIGN (expected true true true false: both engines classify by suffix AND resolved membership)"
fi
echo "$NAME: fixture-001 --runtime=_build/install/default: 154 ./-prefixed header positions; oracle library=$OCLASS; port library=$LCLASS; oracle without ./=$OCONTROL; oracle on a foreign runtime/libcore directory=$OFOREIGN (both engines agree: suffix AND resolved membership)"
F001=$(oracle_line _build/install/default tests/fixtures/001-return-literal/source.c "$ROOT") \
    || { echo "$NAME: FAIL — fixture-001 oracle execution failed"; exit 1; }
[[ "$F001" == 'Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}' ]] \
    || { echo "$NAME: FAIL — fixture-001 oracle execution verdict: [$F001]"; exit 1; }
lean "$ROOT" -- --batch --runtime=_build/install/default tests/fixtures/001-return-literal/cabs.json
expect_line "relative fixture-001 is served; execution agrees" "$F001"
[[ $RC -eq 0 ]] || fail "relative fixture-001 exit $RC, expected 0"
echo "$NAME: fixture-001 execution: oracle=[$F001]; port=[$OUT]"

# --- Served agreement pins: #line plants at the runtime library directories --
# dot: the spelling cpp emits under --runtime=_build/install/default (before Q1
# the oracle said not-library and reported the UB inside the function,
# `<2:10--2:15>`, while the port substituted the call site); nodot: pristine's
# literal key; abs: an absolute spelling under the relative runtime; core: the
# libcore directory. Both engines now classify all four as library and
# substitute the call site (core_eval.lem:602): one verdict, on both. Both
# engines run from the repository root at the relative runtime, as the
# fixture-001 case above. A plant whose engines disagree is RED.
plant() {  # <name> <library-directory-spelling>
    printf '#line 1 "%s/plant.h"\nint f(int x) {\n  return x + 1;\n}\n#line 10 "%s.c"\nint main(void) {\n  return f(2147483647);\n}\n' "$2" "$1" > "$W/$1.c"
    cabs _build/install/default "$W/$1.c" "$W/$1.json" "$ROOT"
}
plant dot   ./_build/install/default/lib/cerberus-lib/runtime/libc/include
plant nodot _build/install/default/lib/cerberus-lib/runtime/libc/include
plant abs   "$RT/libc/include"
plant core  ./_build/install/default/lib/cerberus-lib/runtime/libcore
SITE='Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}'
for name in dot nodot abs core; do
    O=$(oracle_line _build/install/default "$W/$name.c" "$ROOT")
    n=$((n + 1))
    [[ "$O" == "$SITE" ]] || fail "served agreement pin ($name): oracle verdict moved: expected exactly [$SITE] (the call site, a library-located UB); got [$O]"
    lean "$ROOT" -- --batch --runtime=_build/install/default "$W/$name.json"
    expect_line "served agreement pin ($name): the port reports the call site, as the oracle does" "$SITE"
    [[ $RC -eq 1 ]] || fail "served agreement pin ($name): exit $RC, expected 1"
    echo "$NAME: served agreement pin ($name): oracle=[$O] port=[$OUT]"
done

# --- Quotation hygiene Q2: non-canonical quotation invocations refuse ---------
Q="$W/quote"; mkdir -p "$Q"
lean "$ROOT" -- --quote-core "$Q/AbsRuntime.lean" --runtime="$PREFIX" tests/fixtures/001-return-literal/cabs.json
expect_refusal "quotation under an absolute --runtime" "runtime:" "the given spelling is \`$PREFIX\`" '["--runtime"]'
[[ ! -e "$Q/AbsRuntime.lean" ]] || fail "quotation under an absolute --runtime wrote a module"
lean "$ROOT" CERB_INSTALL_PREFIX="$PREFIX" -- --quote-core "$Q/EnvRuntime.lean" tests/fixtures/001-return-literal/cabs.json
expect_refusal "quotation with the runtime from CERB_INSTALL_PREFIX only" "runtime:" "the runtime came from CERB_INSTALL_PREFIX=\`$PREFIX\`, not from --runtime" '["--runtime"]'
[[ ! -e "$Q/EnvRuntime.lean" ]] || fail "quotation under CERB_INSTALL_PREFIX wrote a module"
# ub2.json was exported under the absolute prefix from an absolute source path: its
# labels are absolute; the sorted label list names the source file first
lean "$ROOT" -- --quote-core "$Q/AbsLabel.lean" --runtime=_build/install/default "$W/ub2.json"
expect_refusal "quotation of an input carrying an absolute label" "runtime:" "carries the label \`$W/ub2.c\` (an absolute path)" '["--runtime"]'
[[ ! -e "$Q/AbsLabel.lean" ]] || fail "quotation of an absolute-label input wrote a module"
lean "$ROOT" -- --quote-core "$Q/Canonical.lean" --runtime=_build/install/default tests/fixtures/001-return-literal/cabs.json
n=$((n + 1))
if [[ $RC -ne 0 || -n "$OUT" || -n "$ERR" || ! -s "$Q/Canonical.lean" || "$(head -1 "$Q/Canonical.lean")" != "import Core_run_aux" ]]; then
    fail "canonical quotation control: expected exit 0, silent, a module starting with 'import Core_run_aux'; got rc=$RC: ${OUT:0:200} ${ERR:0:300}"
fi
echo "$NAME: quotation hygiene: absolute --runtime, CERB_INSTALL_PREFIX-only and absolute-label quotations refused (runtime/--runtime); canonical control written ($(wc -c < "$Q/Canonical.lean" 2>/dev/null || echo 0) bytes)"

[[ $fails -eq 0 ]] || { echo "$NAME: $fails of $n witnesses FAILED"; exit 1; }
echo "$NAME: OK ($n witnesses: --runtime/CERB_INSTALL_PREFIX resolution and priority, planted cwd std.core ignored, planted prefix used, 5 runtime refusals, 1 cross-runtime and 3 library-location refusals, 1 control agreeing with the oracle, relative fixture-001 classifier agreement (both engines: suffix AND resolved membership) and execution control, 4 served UB-location agreement pins (./, unprefixed, absolute, libcore), 3 quotation-convention refusals (absolute --runtime, CERB_INSTALL_PREFIX only, absolute label) and the canonical quotation control)"
