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
# oracle's exact test against the runtime is REFUSED (Main.lean
# refuseLibraryLocations).
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
    printf '#!/usr/bin/env bash\necho "cerberus-lean: refused — runtime: plant" >&2\nexit 2\n' > "$ST/refuse-all"
    chmod +x "$ST/ignore-runtime" "$ST/refuse-all"
    for plant in ignore-runtime refuse-all; do
        if CERB_LEAN_BIN_OVERRIDE="$ST/$plant" "$0" > "$ST/$plant.out" 2>&1; then
            echo "$NAME: SELFTEST FAIL — plant '$plant' PASSED the witnesses (vacuous check)"
            cat "$ST/$plant.out"
            exit 1
        fi
        echo "$NAME: selftest plant '$plant' caught: $(grep -c 'FAIL —' "$ST/$plant.out") failing witness(es)"
    done
    exec "$0"
fi

[[ -x "$BIN" ]] || { echo "$NAME: FAIL — driver not built: $BIN"; exit 1; }
[[ -x "$ORACLE" ]] || { echo "$NAME: FAIL — oracle not built: $ORACLE"; exit 1; }
[[ -f "$RT/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged: $RT/libcore/std.core"; exit 1; }
mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
W=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
trap 'rm -rf "$W"' EXIT

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
# lean <cwd> <env-assignments...> -- <driver args...>  -> sets OUT, RC
lean() {
    local cwd="$1"; shift
    local envs=()
    while [[ "$1" != "--" ]]; do envs+=("$1"); shift; done
    shift
    OUT=$(cd "$cwd" && env -u CERB_INSTALL_PREFIX -u OPAM_SWITCH_PREFIX LEAN_ABORT_ON_PANIC=1 \
        ${envs[@]+"${envs[@]}"} "$BIN" "$@" 2>&1); RC=$?
}
expect_line() {  # <label> <expected-line>
    n=$((n + 1))
    if [[ "$OUT" != "$2" ]]; then fail "$1: expected exactly [$2]; got rc=$RC: ${OUT:0:300}"; fi
}
expect_refusal() {  # <label> <refusal-prefix> <substring>
    n=$((n + 1))
    if [[ $RC -ne 2 || "$OUT" != *"cerberus-lean: refused — $2"* || "$OUT" != *"$3"* ]]; then
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

[[ $fails -eq 0 ]] || { echo "$NAME: $fails of $n witnesses FAILED"; exit 1; }
echo "$NAME: OK ($n witnesses: --runtime/CERB_INSTALL_PREFIX resolution and priority, planted cwd std.core ignored, planted prefix used, 5 runtime refusals, 1 cross-runtime and 3 library-location refusals, 1 control agreeing with the oracle)"
