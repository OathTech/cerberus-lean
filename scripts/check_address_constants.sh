#!/usr/bin/env bash
# check_address_constants.sh — row-1 witnesses for the desugarer's constant-expression predicates
# (upstream-tray reports 09, 28, 29; the true-bug audit's §4 items 7, 16, 17; [USER 2026-11-04] agreed
# the fix pass under the standing bar — a very clear standard, no invented semantics; record
# lean_frontend/docs/2026-11-07_address-constants-record.md).
#
# Upstream's is_arithmetic_constant_expression / is_lvalue_to_static_object / is_address_constant
# (frontend/model/cabs_to_ail.lem; pristine c3ff8c53f :821-957) decide whether a static or thread
# storage-duration initializer is a constant expression (C17 6.7.9#4, the constraint
# `initializer element is not a compile-time constant`). They lacked arms 6.6#3-#9 list — no
# indirection arm (`&g_arr[1].b` is `&(*(g_arr + 1)).b`, tray 09), no conditional operator or
# generic selection (tray 28), no string-literal address constant (`"hello" + 1`, tray 29), no
# `address constant ± integer constant expression` below the top level (`(char *)&g + 4` was a
# UB055 verdict), no decay of a static array lvalue (`gs.arr`, `g2[1]`) — and accepted what 6.6#3
# forbids: the comma operator (`static int a = (1, 2);` ran), and ANY identifier under unary &
# (`&local` in a block-scope static initializer passed the constraint), a value read through `*`
# (`*&g`) and `->` through a pointer variable (`&gsp->b`). is_integer_constant_expression's
# wildcard arm crashed on a generic selection or a compound literal in an enumerator, case label,
# array bound or _Static_assert. Since 2026-11-07 the SHARED predicates accept exactly the listed
# forms and reject the forbidden operators, both engines by generation (the record §2 has the
# clause of every arm).
#
# Witnesses: tests/address_constants/*.c (234 programs, nolibc, each returning a small int), one
# program per form and context: every integer-constant-expression form in a static initializer and
# the slice's forms in the enumerator, case-label, array-bound and _Static_assert contexts; the
# arithmetic forms (floating, _Bool, offsetof); every address-constant chain shape (& of a static
# object, array elements and 2-D elements, members, nested members, member arrays, array-element
# members, decays, string literals, function designators, casts, ?: and _Generic over address
# constants, null pointer constants, integer-to-pointer casts) and the initializer contexts
# (file-scope static and external objects, block-scope statics, struct/array/designated/nested
# initializers); and the non-constant forms the standard rejects (the comma, assignment, increment,
# call, a variable, value reads through *, [] and ->, pointer variables, & of an automatic object or
# a parameter). Pins (tests/address_constants/expected.txt: name, class, the oracle's line, the
# Lean engine's line):
#   gcc    — BOTH engines print gcc 13's batch line byte for byte (tests/address_constants/gcc.txt:
#            `gcc -std=c11 -pedantic-errors -O0`, derived 2026-11-07), exit 0 on both;
#   reject — both engines reject where gcc rejects: the oracle exits 1 and its first error line
#            (file prefix stripped) is the pinned diagnostic; the Lean engine exits 1 with the pinned
#            `Error {msg: "desugaring failed at <name>.c:<loc>"}` line (location included); for a
#            _Static_assert the pin is upstream's UB204_illtyped_Static_assert verdict on both;
#   fork   — the fork's DECLARED verdict where gcc's differs, each named in FORK_PINNED below with
#            its reason in the record: an unevaluated ?: branch or an unselected _Generic association
#            that is not a constant expression is rejected (too strict, never fail-open: the
#            association is selected during the Ail typing, after the predicate); & of a compound
#            literal (6.5.2.5#5 static storage at file scope: a judgement area, upstream's rejection
#            kept); the value of a string literal element `"hello"[1]` and of a `const` object (gcc
#            folds them: 6.6#10 forms, upstream's rejection kept);
#   gap    — the GNU `?:` in a case label still crashes both engines (`PEcase, mismatched`; TODO.md's
#            item, not this mechanism), unchanged.
# Negative control: tests/address_constants/pristine.txt carries pristine c3ff8c53f's lines (the
# three predicates were byte-identical in the fork before the change: the pre-fix answers); the
# `pristine-pair` plant must FAIL exactly the moved rows. The total and the class counts are pinned.
# Fail-closed.
#
# Usage: check_address_constants.sh             the witnesses (≈ 27 s; ≈ 35 s with --selftest)
#        check_address_constants.sh --selftest  plants (on the PLANT subset, then the real run):
#            (a) `pristine-pair`: both engines replay pristine's lines
#            (b) `lean-pristine`: the real oracle, the Lean engine replays pristine's lines
#            (c) `lean-fixed`: the Lean engine answers one fixed line on every input
#            (d) `oracle-rc`: the real oracle's output with its exit code forced to 1
#            (e) `expect-tamper`: one pinned line altered by a digit (the expectation side)
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REAL_BIN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$REAL_BIN}"
REAL_ORACLE="$ROOT/_build/default/backend/driver/main.exe"
ORACLE="${CERB_ORACLE_BIN_OVERRIDE:-$REAL_ORACLE}"
PREFIX="$ROOT/_build/install/default"
CASES="$ROOT/tests/address_constants"
EXPECT="${CERB_AC_EXPECT_OVERRIDE:-$CASES/expected.txt}"
GCC_LINES="$CASES/gcc.txt"
PRISTINE="$CASES/pristine.txt"
ONLY="${CERB_AC_ONLY:-}"
NAME=check_address_constants
# the declared rows (class fork): the fork's verdict differs from gcc's for a stated reason (header, record §3.3)
FORK_PINNED="ac_compound_lit ac_cond_addr_dead_var ac_ctx_static_const_var ac_str_elem_value ice_arr_generic_dead ice_case_generic_dead ice_enum_generic_dead ice_init_cond_call ice_init_cond_var ice_init_generic_dead ice_sassert_generic_dead"
GAP_PINNED="ice_case_cond_gnu"
# the total and the class counts are PINNED: a dropped row cannot pass silently
WANT_N=234; WANT_GCC=182; WANT_REJECT=40; WANT_FORK=11; WANT_GAP=1
# the plant subset: 5 moved gcc rows, 3 unmoved gcc rows, 2 moved and 1 unmoved reject rows, 2 fork rows, the gap row
PLANT_SUBSET="ac_arr_elem_member ac_str_plus ice_init_cond ice_arr_generic ac_cast_char_plus ac_addr ice_init_lit ac_fun_designator ice_init_comma ac_ptr_var_arrow ice_init_var ac_compound_lit ice_init_cond_call ice_case_cond_gnu"

if [[ "${1:-}" == --selftest ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    [[ -f "$PRISTINE" ]] || { echo "$NAME: FAIL — $PRISTINE missing"; exit 1; }
    export PLANT_PRISTINE="$PRISTINE"
    # replay stubs: pristine's line for the program named by the last argument (.c or .json), in its
    # encoding — a batch line (exit 0 for Defined, 1 for Undefined), a rejection (the diagnostic on stderr
    # with a file prefix, exit 1; the Lean Error line on stdout, exit 1) or the gap crash text (exit
    # 125 / 134); the oracle stub delegates --cabs-json to the real oracle so the Lean side is exercised
    cat > "$ST/oracle-pristine" <<EOS
#!/usr/bin/env bash
if [[ " \$* " == *" --cabs-json "* ]]; then exec "$REAL_ORACLE" "\$@"; fi
last="\${@: -1}"; b=\$(basename "\${last%.c}")
line=\$(awk -F'\t' -v n="\$b" '\$1==n{print \$2}' "\$PLANT_PRISTINE")
[[ -n "\$line" ]] || { echo "stub: no pristine line for \$b" >&2; exit 99; }
case "\$line" in
  Defined*)   printf '%s\n' "\$line"; exit 0 ;;
  Undefined*) printf '%s\n' "\$line"; exit 1 ;;
  "REJECT(rc=1): "*) printf '%s.c:1:1: %s\n' "\$b" "\${line#REJECT(rc=1): }" >&2; exit 1 ;;
  *) printf 'internal error: %s\n' "\$line" >&2; exit 125 ;;
esac
EOS
    cat > "$ST/lean-pristine" <<EOS
#!/usr/bin/env bash
last="\${@: -1}"; b=\$(basename "\${last%.json}"); b=\${b%.c}
line=\$(awk -F'\t' -v n="\$b" '\$1==n{print \$3}' "\$PLANT_PRISTINE")
[[ -n "\$line" ]] || { echo "stub: no pristine line for \$b" >&2; exit 99; }
case "\$line" in
  Defined*)            printf '%s\n' "\$line"; exit 0 ;;
  Undefined*|Error*)   printf '%s\n' "\$line"; exit 1 ;;
  *) printf 'PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: %s\n' "\$line" >&2; exit 134 ;;
esac
EOS
    printf '#!/usr/bin/env bash\necho %q\nexit 0\n' 'Defined {value: "Specified(0)", stdout: "7\n", stderr: "", blocked: "false"}' > "$ST/lean-fixed"
    # (d) oracle-rc: the real oracle's output, its exit code forced to 1 on the execution runs only (the
    # --cabs-json export is delegated untouched)
    printf '#!/usr/bin/env bash\nif [[ " $* " == *" --cabs-json "* ]]; then exec "%s" "$@"; fi\n"%s" "$@"\nexit 1\n' "$REAL_ORACLE" "$REAL_ORACLE" > "$ST/oracle-rc"
    chmod +x "$ST"/oracle-pristine "$ST"/lean-pristine "$ST"/lean-fixed "$ST"/oracle-rc
    # (e) the expectation side: ac_arr_elem_member's value altered in both columns
    awk -F'\t' -v OFS='\t' '$1=="ac_arr_elem_member"{gsub(/Specified\(3\)/, "Specified(1)", $0)} {print}' "$EXPECT" > "$ST/expected-tampered.txt"
    cmp -s "$ST/expected-tampered.txt" "$EXPECT" && { echo "$NAME: SELFTEST FAIL — the tamper plant did not alter the expectation"; exit 1; }
    run_plant() {  # <label> <oracle> <lean> <expect-file> <expected failure count> [required failing program]...
        local label="$1" o="$2" l="$3" e="$4" want="$5" got req; shift 5
        if CERB_ORACLE_BIN_OVERRIDE="$o" CERB_LEAN_BIN_OVERRIDE="$l" CERB_AC_EXPECT_OVERRIDE="$e" \
           CERB_AC_ONLY="$PLANT_SUBSET" "$0" > "$ST/$label.out" 2>&1; then
            echo "$NAME: SELFTEST FAIL — plant '$label' PASSED the witnesses (vacuous check)"; cat "$ST/$label.out"; exit 1
        fi
        got=$(grep -c 'FAIL —' "$ST/$label.out")
        if [[ "$got" != "$want" ]]; then
            echo "$NAME: SELFTEST FAIL — plant '$label' caught $got failing check(s), expected exactly $want"; cat "$ST/$label.out"; exit 1
        fi
        for req in "$@"; do
            grep -qF "FAIL — $req:" "$ST/$label.out" || { echo "$NAME: SELFTEST FAIL — plant '$label' did not fail '$req'"; cat "$ST/$label.out"; exit 1; }
        done
        echo "$NAME: selftest plant '$label' caught: $got failing check(s) (= expected $want${*:+; incl. the required programs})"
    }
    # Expected counts, derived on the plant subset (14 programs: 8 gcc rows of which 5 moved, 3 reject rows of
    # which 2 moved, 2 fork rows (unmoved), the gap row). Every row has ONE oracle check and ONE Lean check
    # (exit code and line together).
    #  pristine-pair: the 7 moved rows fail both checks                                              = 14
    #  lean-pristine: the 7 moved rows fail the Lean check                                           = 7
    #  lean-fixed:    every row fails the Lean check (no pin is the fixed line)                       = 14
    #  oracle-rc:     the 8 gcc rows (rc 0 expected) + the gap row (rc 125 expected) fail the oracle check;
    #                 the reject and fork rows expect rc 1 and pass                                   = 9
    #  expect-tamper: ac_arr_elem_member: the class check (the pin is no longer gcc's line) + the oracle
    #                 check + the Lean check                                                         = 3
    run_plant pristine-pair "$ST/oracle-pristine" "$ST/lean-pristine" "$EXPECT" 14 ac_arr_elem_member ac_str_plus ice_init_cond ice_arr_generic ice_init_comma ac_ptr_var_arrow
    run_plant lean-pristine "$REAL_ORACLE" "$ST/lean-pristine" "$EXPECT" 7 ac_str_plus ice_init_comma ac_cast_char_plus
    run_plant lean-fixed "$REAL_ORACLE" "$ST/lean-fixed" "$EXPECT" 14 ac_addr ac_compound_lit ice_init_var ice_case_cond_gnu
    run_plant oracle-rc "$ST/oracle-rc" "$REAL_BIN" "$EXPECT" 9 ac_addr ice_init_lit ice_case_cond_gnu
    run_plant expect-tamper "$REAL_ORACLE" "$REAL_BIN" "$ST/expected-tampered.txt" 3 ac_arr_elem_member
    "$0"; exit $?
fi

[[ -x "$BIN" ]] || { echo "$NAME: FAIL — driver not built: $BIN"; exit 1; }
[[ -x "$ORACLE" ]] || { echo "$NAME: FAIL — oracle not built: $ORACLE"; exit 1; }
[[ -f "$PREFIX/lib/cerberus-lib/runtime/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged under $PREFIX"; exit 1; }
[[ -d "$CASES" && -f "$EXPECT" && -f "$GCC_LINES" ]] || { echo "$NAME: FAIL — witness programs or pins missing ($CASES, $EXPECT, $GCC_LINES)"; exit 1; }
mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
WD=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
trap 'rm -rf "$WD"' EXIT
cd "$WD" || { echo "$NAME: FAIL — cd $WD"; exit 1; }   # the programs are copied here under their bare names: the Lean Error line carries <name>.c:<loc>
export NO_COLOR=1 TERM=dumb

fails=0; n=0; nmoved=0; ngcc=0; nreject=0; nfork=0; ngap=0
fail() { echo "$NAME: FAIL — $*"; fails=$((fails + 1)); }
col() { awk -F'\t' -v n="$1" -v c="$2" '$1==n{print $c}' "$3"; }   # <name> <column> <file>
verdict_line() { grep -aE '^(Defined|Undefined|Error|Killed) ' | head -1; }
first_error() { grep -a -m1 'error' "$1" | sed -E 's/^[^ ]*\.c:[0-9]+:[0-9]+: //'; }
selected() { [[ -z "$ONLY" ]] || [[ " $ONLY " == *" $1 "* ]]; }
listed() { [[ " $2 " == *" $1 "* ]]; }

classify() {  # <name> <class> <oracle pin> <lean pin>: the class's relation to gcc.txt and the declared lists; counts
    local name="$1" cls="$2" po="$3" pl="$4" g; g=$(col "$name" 2 "$GCC_LINES")
    [[ -n "$g" ]] || { fail "$name: no gcc line in $GCC_LINES"; return; }
    case "$cls" in
        gcc)    [[ "$po" == "$g" && "$pl" == "$g" && "$g" == Defined* ]] || fail "$name: class gcc but the pins are not gcc's Defined line"
                listed "$name" "$FORK_PINNED" && fail "$name: declared FORK-PINNED but its pins equal gcc's line (retire the declaration)"
                ngcc=$((ngcc + 1)) ;;
        reject) [[ "$g" == GCC-REJECT* && "$po" != Defined* && "$pl" != Defined* ]] || fail "$name: class reject but gcc accepts or a pin is a Defined line"
                listed "$name" "$FORK_PINNED" && fail "$name: declared FORK-PINNED but classed reject"
                nreject=$((nreject + 1)) ;;
        fork)   listed "$name" "$FORK_PINNED" || fail "$name: class fork (the pin is not gcc's verdict) but not declared in FORK_PINNED"
                [[ "$po" != "$g" ]] || fail "$name: declared FORK-PINNED but its oracle pin equals gcc's line"
                nfork=$((nfork + 1)) ;;
        gap)    listed "$name" "$GAP_PINNED" || fail "$name: class gap but not declared in GAP_PINNED"
                ngap=$((ngap + 1)) ;;
        *)      fail "$name: unknown class '$cls'" ;;
    esac
}
oracle_check() {  # <name> <pin>: the oracle's exit code and line per the pin's encoding
    local name="$1" pin="$2" oout orc v e
    oout=$("$ORACLE" --runtime="$PREFIX" --nolibc --exec --batch "$name.c" 2> "$name.oerr"); orc=$?
    case "$pin" in
        Defined*)   v=$(printf '%s\n' "$oout" | verdict_line); [[ $orc -eq 0 && "$v" == "$pin" ]] || fail "$name: oracle: expected rc 0 [${pin:0:160}]; got rc=$orc [${v:0:160}] $(head -c 160 "$name.oerr")" ;;
        Undefined*) v=$(printf '%s\n' "$oout" | verdict_line); [[ $orc -eq 1 && "$v" == "$pin" ]] || fail "$name: oracle: expected rc 1 [${pin:0:160}]; got rc=$orc [${v:0:160}]" ;;
        "REJECT(rc=1): "*) e=$(first_error "$name.oerr"); [[ $orc -eq 1 && "$e" == "${pin#REJECT(rc=1): }" ]] || fail "$name: oracle: expected rc 1 + [${pin#REJECT(rc=1): }]; got rc=$orc [${e:0:160}] $(printf '%s' "$oout" | head -c 120)" ;;
        *)          [[ $orc -eq 125 && "$(cat "$name.oerr")" == *"$pin"* ]] || fail "$name: oracle: expected the pre-existing crash (rc 125, '$pin'); got rc=$orc $(head -c 200 "$name.oerr")" ;;
    esac
}
lean_check() {  # <name> <pin>: the Cabs export by the real oracle, then the Lean engine's exit code and line per the pin's encoding
    local name="$1" pin="$2" lout lrc v
    if ! "$ORACLE" --runtime="$PREFIX" --nolibc --cabs-json "$name.c" > "$name.json" 2> "$name.cjerr" || [[ ! -s "$name.json" ]]; then
        fail "$name: oracle --cabs-json failed: $(head -c 300 "$name.cjerr")"; return
    fi
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$PREFIX" "$name.json" 2> "$name.lerr"); lrc=$?
    case "$pin" in
        Defined*)          v=$(printf '%s\n' "$lout" | verdict_line); [[ $lrc -eq 0 && "$v" == "$pin" ]] || fail "$name: Lean: expected rc 0 [${pin:0:160}]; got rc=$lrc [${v:0:160}] $(head -c 160 "$name.lerr")" ;;
        Undefined*|Error*) v=$(printf '%s\n' "$lout" | verdict_line); [[ $lrc -eq 1 && "$v" == "$pin" ]] || fail "$name: Lean: expected rc 1 [${pin:0:160}]; got rc=$lrc [${v:0:160}]" ;;
        *)                 [[ $lrc -eq 134 && "$(cat "$name.lerr")$lout" == *"$pin"* ]] || fail "$name: Lean: expected the mirrored stop (rc 134, '$pin'); got rc=$lrc $(head -c 200 "$name.lerr")" ;;
    esac
}
witness() {  # <name>: classify, run both engines against the pins, count the move from pristine
    local name="$1" cls po pl
    selected "$name" || return
    cls=$(col "$name" 2 "$EXPECT"); po=$(col "$name" 3 "$EXPECT"); pl=$(col "$name" 4 "$EXPECT")
    [[ -n "$cls" && -n "$po" && -n "$pl" ]] || { fail "$name: incomplete pin row in $EXPECT"; return; }
    [[ -f "$CASES/$name.c" ]] || { fail "$name: program missing: $CASES/$name.c"; return; }
    cp "$CASES/$name.c" "$WD/$name.c"
    n=$((n + 1)); classify "$name" "$cls" "$po" "$pl"
    if [[ -f "$PRISTINE" && "$cls" != gap && ( "$(col "$name" 2 "$PRISTINE")" != "$po" || "$(col "$name" 3 "$PRISTINE")" != "$pl" ) ]]; then nmoved=$((nmoved + 1)); fi
    oracle_check "$name" "$po"
    lean_check "$name" "$pl"
}

while IFS=$'\t' read -r name _; do
    [[ -n "$name" && "$name" != \#* ]] || continue
    witness "$name"
done < "$EXPECT"
for name in $FORK_PINNED $GAP_PINNED; do grep -q "^$name	" "$EXPECT" || fail "$name: declared FORK/GAP-PINNED but absent from $EXPECT"; done
if [[ -z "$ONLY" ]]; then  # the whole set: the pinned totals (a subset run is a plant or a focused check, not the gate)
    [[ $n -eq $WANT_N && $ngcc -eq $WANT_GCC && $nreject -eq $WANT_REJECT && $nfork -eq $WANT_FORK && $ngap -eq $WANT_GAP ]] \
        || fail "the witness set is not the pinned set: $n programs ($ngcc gcc-pinned, $nreject rejected, $nfork fork-pinned, $ngap gap); expected $WANT_N ($WANT_GCC/$WANT_REJECT/$WANT_FORK/$WANT_GAP)"
fi

[[ $fails -eq 0 ]] || { echo "$NAME: $fails failing check(s) over $n programs"; exit 1; }
echo "$NAME: OK ($n programs, nolibc: $ngcc batch lines of both engines = gcc 13's pinned line, exit 0 on both — every integer-constant-expression form (literals, character and enumeration constants, sizeof and _Alignof, cast floating constants, every operator, ?: incl. dead branches with a division by zero, a negative shift or an overflow, _Generic incl. a variable or a call as the unevaluated controlling expression) in a static initializer and the slice's forms in enumerators, case labels, array bounds and _Static_assert; the arithmetic forms; every address-constant shape (& of static objects, array and 2-D elements, members, nested and array-element members, member arrays and their decay, &*&g, string literals plus an offset and their elements, function designators under &, * and casts, pointer casts and chains, ?: and _Generic over address constants, null pointer constants, integer-to-pointer casts) in file-scope, external, block-scope, struct, array, designated and nested initializers; $nreject rejected by both engines with the pinned diagnostic where gcc rejects too (the comma, assignment, increment and call operators, a variable, value reads through *, [] and ->, pointer variables, & of an automatic object or a parameter, (int *)g, (long)g, & of a _Thread_local, a compound literal or a non-constant in the integer-constant contexts); $nfork pinned to the fork's declared verdict with gcc's beside it in gcc.txt (an unevaluated ?: branch or an unselected _Generic association that is not constant, & of a compound literal, the value of a string literal element or of a const object); $ngap gap control: the GNU ?: in a case label still crashes both engines (TODO); $nmoved rows moved from pristine c3ff8c53f's lines)"
