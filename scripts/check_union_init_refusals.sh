#!/usr/bin/env bash
# check_union_init_refusals.sh — row-1 witnesses for the union-initializer refusal
# (item U, 2026-10-20; [USER 2026-10-20] ruled that where upstream Cerberus left a
# case deliberately to a TODO, the fork either leaves it as-is or REFUSES LOUDLY —
# the run dies with a declared unsupported outcome — and never invents a semantic
# outcome nor answers silently wrong; for union initializers specifically: refuse
# rather than fix. Record lean_frontend/docs/2026-10-20_union-init-refusal-record.md).
#
# Upstream's initializer desugarer (frontend/model/desugaring_init.lem — the LIVE
# one; cabs_to_ail.lem:3527-3528 calls it, and cabs_to_ail.lem's own constructValue
# is dead code) builds EVERY braced union initializer as the FIRST member, whatever
# the designators say: constructValue_aux's Union arm carries upstream's own
# 'TODO: this is only correct if the first member was the one initialised'
# (b9aeedcb4 :576) and a level-0 debug print 'constructValue_aux: is WRONG for
# union ==> always assigning the first member' (:592); the init-map key Elem_union
# has no member identity. So `union U { int i; unsigned char c[4]; } u = { .c =
# {1,2,3,4} }` gave u.c[0]*100 + u.c[3] = 0 on both engines (gcc 104). Now the
# SHARED desugarer REFUSES, in moveTo_aux's Union arm (the one place the designated
# member is decidable), when a member designator names a member other than the
# first — at any depth, any storage class, arrays of unions, nested unions,
# compound literals — with ONE text (oracle: Cerb_debug.error = `internal error:
# <text>` + uncaught Failure("internal error: <text>"), exit 125; Lean: failwithI,
# PANIC line carrying <text>, exit 134 under LEAN_ABORT_ON_PANIC=1):
#     Desugaring_init.moveTo_aux: refused - union initializer designating a member other than the first (union U: designator .c, first member i); C17 6.7.9#17-19 (...); upstream's desugaring_init.lem constructValue_aux builds every braced union initializer as the FIRST member whatever the designators say (...) - the fork refuses rather than decides (item U, 2026-10-20)
# The two engines' texts are compared byte for byte.
# A list that MIXES positional and designated elements is silently wrong only when
# it contains such a designator (the controls `{ 9, .a = 2 }` and `{ .a = 1, .a = 2 }`
# answer 2 on both engines, as gcc does), so the one predicate covers the mixing
# clause of the brief; the record §2 has the argument.
# Controls (Lean = oracle, exit code and verdict line): positional and first-member
# designated initializers (incl. twice-designated, a first member that is an array
# or a partially designated struct, a static first-member designator, an array of
# unions designated at the first member), `{ 0 }` with a smaller first member (reads
# the larger member as Unspecified, both engines — a strict ISO reading, kept), an
# ANONYMOUS union member inside a struct designated by its member name (`.c`
# resolves through the enclosing struct, whose member list the anonymous union's
# members are spliced into — a different desugaring path, unaffected), a union
# inside a struct initialised positionally or with a first-member designator,
# and member ASSIGNMENT after declaration (the refusal is about initializers).
# One GAP control pins an already-noisy upstream behaviour as unchanged on both
# engines: `.t = x` with x a struct variable is a constraint violation on the
# oracle and a typechecking failure on Lean (tray draft 59 §b). Fail-closed.
#
# Usage: check_union_init_refusals.sh             the witnesses
#        check_union_init_refusals.sh --selftest  plants: the witnesses must FAIL against
#            (a) `answer`: the pre-fix behaviour of BOTH engines — stubs that answer
#                Defined/Specified(0) on every witness program (controls run the real engines);
#            (b) `lean-answer`: the real oracle, a Lean stub that answers on every input;
#            (c) `refuse-all`: both engines refuse every input with the text (the controls
#                must catch it);
#            (d) `lean-no-abort`: the real Lean output, but exit 0 — a message without a
#                death is not a refusal;
#            (e) `lean-other-text`: the real Lean, its text altered — the two engines'
#                texts must be identical;
#            then the real run.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REAL_BIN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$REAL_BIN}"
REAL_ORACLE="$ROOT/_build/default/backend/driver/main.exe"
ORACLE="${CERB_ORACLE_BIN_OVERRIDE:-$REAL_ORACLE}"
PREFIX="$ROOT/_build/install/default"
NAME=check_union_init_refusals
HEAD='Desugaring_init.moveTo_aux: refused - union initializer designating a member other than the first ('
TAIL="C17 6.7.9#17-19 (a designator selects the member to initialize, in list order; subobjects not initialized explicitly are initialized implicitly); upstream's desugaring_init.lem constructValue_aux builds every braced union initializer as the FIRST member whatever the designators say ('TODO: this is only correct if the first member was the one initialised' b9aeedcb4 :576; 'constructValue_aux: is WRONG for union ==> always assigning the first member' :592) - the fork refuses rather than decides (item U, 2026-10-20)"
# the oracle's Cerb_debug.error prefixes the text (the uncaught exception is Failure("internal error: <text>"))
OPREFIX='internal error: '
GAP_ORACLE="constraint violation: initializing 'signed int' with an expression with a non arithmetic type 'struct T'"
GAP_LEAN='Error {msg: "typechecking failed at '

if [[ "${1:-}" == "--selftest" ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    ANSWER='Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}'
    # (a) answer: on a witness program (w_*.c / w_*.json) under --exec / --batch, answer as
    # both engines did before the fix; everything else (controls, --cabs-json) runs the real engine
    cat > "$ST/oracle-answer" <<EOF
#!/usr/bin/env bash
last="\${@: -1}"
if [[ " \$* " == *" --exec "* && "\$(basename "\$last")" == w_*.c ]]; then echo '$ANSWER'; exit 0; fi
exec "$REAL_ORACLE" "\$@"
EOF
    cat > "$ST/lean-answer-witnesses" <<EOF
#!/usr/bin/env bash
last="\${@: -1}"
if [[ "\$(basename "\$last")" == w_*.json ]]; then echo '$ANSWER'; exit 0; fi
exec "$REAL_BIN" "\$@"
EOF
    # (b) lean-answer: answer on every input
    printf '#!/usr/bin/env bash\necho %q\nexit 0\n' "$ANSWER" > "$ST/lean-answer"
    # (c) refuse-all, in the right shape and words (the fixed text, passed through the
    # environment: it contains quotes), on both sides; the oracle stub still exports
    # Cabs JSON so the Lean stub is exercised
    export PLANT_TEXT="${HEAD}union U: designator .c, first member i); $TAIL"
    cat > "$ST/oracle-refuse-all" <<EOF
#!/usr/bin/env bash
if [[ " \$* " == *" --cabs-json "* ]]; then exec "$REAL_ORACLE" "\$@"; fi
printf 'internal error: %s\n' "\$PLANT_TEXT" >&2
echo 'cerberus: internal error, uncaught exception:' >&2
printf '          Failure("internal error: %s")\n' "\$PLANT_TEXT" >&2
exit 125
EOF
    cat > "$ST/lean-refuse-all" <<EOF
#!/usr/bin/env bash
printf 'PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: %s\n' "\$PLANT_TEXT" >&2
exit 134
EOF
    # (d) lean-no-abort: the real Lean's output, exit 0
    printf '#!/usr/bin/env bash\n"%s" "$@" 2>&1\nexit 0\n' "$REAL_BIN" > "$ST/lean-no-abort"
    # (e) lean-other-text: the real Lean, its refusal text altered, exit code kept
    printf '#!/usr/bin/env bash\nout=$("%s" "$@" 2>&1); rc=$?\nprintf "%%s\\n" "$out" | sed "s/the fork refuses rather than decides/the fork refuses/"\nexit $rc\n' "$REAL_BIN" > "$ST/lean-other-text"
    chmod +x "$ST"/oracle-answer "$ST"/lean-answer-witnesses "$ST"/lean-answer "$ST"/oracle-refuse-all "$ST"/lean-refuse-all "$ST"/lean-no-abort "$ST"/lean-other-text
    run_plant() {  # <label> <oracle> <lean> <expected failure count> [witness label that MUST be among the failures]...
        local label="$1" o="$2" l="$3" want="$4" got req; shift 4
        if CERB_ORACLE_BIN_OVERRIDE="$o" CERB_LEAN_BIN_OVERRIDE="$l" "$0" > "$ST/$label.out" 2>&1; then
            echo "$NAME: SELFTEST FAIL — plant '$label' PASSED the witnesses (vacuous check)"
            cat "$ST/$label.out"
            exit 1
        fi
        got=$(grep -c 'FAIL —' "$ST/$label.out")
        if [[ "$got" != "$want" ]]; then
            echo "$NAME: SELFTEST FAIL — plant '$label' caught $got failing witness(es), expected exactly $want"
            cat "$ST/$label.out"
            exit 1
        fi
        for req in "$@"; do  # the plant must fail THESE witnesses, not merely some (asm precedent, audit LOW-1)
            if ! grep -qF "FAIL — $req:" "$ST/$label.out"; then
                echo "$NAME: SELFTEST FAIL — plant '$label' did not fail the witness '$req' (the plant does not exercise it)"
                cat "$ST/$label.out"
                exit 1
            fi
        done
        echo "$NAME: selftest plant '$label' caught: $got failing witness(es) (= expected $want${*:+; incl. the required witnesses})"
    }
    # expected counts, derived: 14 witnesses, 12 verdict controls (all exit 0), 1 gap control (exit 1 on both).
    #  answer:          each witness fails the oracle check and the Lean check (the text cross-check needs both texts)  = 14 x 2
    #  lean-answer:     each witness fails the Lean check; every control fails (Lean = oracle; the gap control's exit) = 14 + 13
    #  refuse-all:      the witnesses pass (one shape, identical texts); every control fails                             = 13
    #  lean-no-abort:   each witness fails the Lean exit check; the gap control (Lean exit 1) fails                      = 14 + 1
    #  lean-other-text: each witness fails the text cross-check only; the controls pass                                  = 14
    run_plant answer "$ST/oracle-answer" "$ST/lean-answer-witnesses" 28 "designated second member, array (tray-59 witness; gcc 104)" "designated scalar second member (right by representation overlap; gcc 5)" "designated union member inside a struct (pristine: invalid node)"
    run_plant lean-answer "$REAL_ORACLE" "$ST/lean-answer" 27 "designated second member, array (tray-59 witness; gcc 104)" "anonymous union member inside a struct, designated through the struct" "positional initializer" "GAP control (unchanged): struct member initialised from a struct variable"
    run_plant refuse-all "$ST/oracle-refuse-all" "$ST/lean-refuse-all" 13 "anonymous union member inside a struct, designated through the struct" "positional initializer" "{ 0 } with a smaller first member reads the larger member as Unspecified" "GAP control (unchanged): struct member initialised from a struct variable"
    run_plant lean-no-abort "$REAL_ORACLE" "$ST/lean-no-abort" 15 "designated second member, array (tray-59 witness; gcc 104)" "designated scalar second member (right by representation overlap; gcc 5)"
    run_plant lean-other-text "$REAL_ORACLE" "$ST/lean-other-text" 14 "designated second member, array (tray-59 witness; gcc 104)" "designated scalar second member (right by representation overlap; gcc 5)"
    "$0"; exit $?   # not exec: the EXIT trap must remove $ST
fi

[[ -x "$BIN" ]] || { echo "$NAME: FAIL — driver not built: $BIN"; exit 1; }
[[ -x "$ORACLE" ]] || { echo "$NAME: FAIL — oracle not built: $ORACLE"; exit 1; }
[[ -f "$PREFIX/lib/cerberus-lib/runtime/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged under $PREFIX"; exit 1; }
mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
W=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
trap 'rm -rf "$W"' EXIT
cd "$W" || { echo "$NAME: FAIL — cd $W"; exit 1; }
export NO_COLOR=1 TERM=dumb

fails=0; n=0
fail() { echo "$NAME: FAIL — $*"; fails=$((fails + 1)); }

oracle_exec() {  # <c-file> -> OOUT (stdout+stderr), ORC
    OOUT=$("$ORACLE" --runtime="$PREFIX" --exec --batch --nolibc "$1" 2>&1); ORC=$?
}
lean_batch() {  # <json> -> LOUT (stdout+stderr), LRC
    LOUT=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$PREFIX" "$1" 2>&1); LRC=$?
}
cabs_ok() {  # <c-file> <json>: the export must succeed (the refusal is in the desugarer, after Cabs)
    "$ORACLE" --runtime="$PREFIX" --cabs-json "$1" > "$2" 2> "$2.err" && [[ -s "$2" ]]
}
verdict_line() { grep -aE '^(Defined|Undefined|Error) ' | head -1; }
text_from() {  # <head> <output>: the refusal text from its head to the end of its line (the oracle's closing `")` removed)
    local line
    line=$(printf '%s\n' "$2" | grep -aF -m1 "$1") || return 1
    line="$1${line#*"$1"}"
    printf '%s' "${line%\")}"
}

witness() {  # <label> <c-file>: refused on BOTH engines with one text
    local label="$1" c="$2" j="$W/$2.json" omsg= lmsg=
    n=$((n + 1))
    oracle_exec "$c"
    if [[ $ORC -eq 125 && "$OOUT" == *"uncaught exception"* && "$OOUT" == *"Failure(\"$OPREFIX$HEAD"* && "$OOUT" == *"$TAIL\")"* ]]; then
        omsg=$(text_from "$HEAD" "$OOUT")
    else
        fail "$label: oracle: expected exit 125 + uncaught Failure(\"$OPREFIX$HEAD…$TAIL\"); got rc=$ORC: ${OOUT:0:400}"
    fi
    if ! cabs_ok "$c" "$j"; then
        fail "$label: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lean_batch "$j"
    if [[ $LRC -eq 134 && "$LOUT" == *"PANIC"* && "$LOUT" == *"$HEAD"* && "$LOUT" == *"$TAIL"* ]]; then
        lmsg=$(text_from "$HEAD" "$LOUT")
    else
        fail "$label: Lean: expected exit 134 (abort under LEAN_ABORT_ON_PANIC=1) + a PANIC line carrying '$HEAD…$TAIL'; got rc=$LRC: ${LOUT:0:400}"
    fi
    if [[ -n "$omsg" && -n "$lmsg" && "$omsg" != "$lmsg" ]]; then
        fail "$label: the two engines' texts differ: oracle [$omsg] vs Lean [$lmsg]"
    fi
}
control() {  # <label> <c-file> <expected oracle verdict line>: Lean = oracle (exit code and verdict line)
    local label="$1" c="$2" want="$3" j="$W/$2.json" o
    n=$((n + 1))
    oracle_exec "$c"
    o=$(printf '%s\n' "$OOUT" | verdict_line)
    [[ "$o" == "$want" ]] || { fail "$label: oracle: expected [$want]; got rc=$ORC [$o]"; return; }
    cabs_ok "$c" "$j" || { fail "$label: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return; }
    lean_batch "$j"
    [[ $LRC -eq $ORC && "$(printf '%s\n' "$LOUT" | verdict_line)" == "$o" ]] \
        || fail "$label: expected Lean = oracle (rc $ORC, [$o]); got rc=$LRC: ${LOUT:0:300}"
}
gap_control() {  # <label> <c-file> <oracle text> <lean text>: both engines still REJECT as before (exit 1, their own texts)
    local label="$1" c="$2" otext="$3" ltext="$4" j="$W/$2.json"
    n=$((n + 1))
    oracle_exec "$c"
    [[ $ORC -eq 1 && "$OOUT" == *"$otext"* ]] \
        || { fail "$label: oracle: expected the pre-existing rejection (exit 1, '$otext'); got rc=$ORC: ${OOUT:0:300}"; return; }
    cabs_ok "$c" "$j" || { fail "$label: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return; }
    lean_batch "$j"
    [[ $LRC -eq 1 && "$LOUT" == *"$ltext"* ]] \
        || fail "$label: Lean: expected the pre-existing rejection (exit 1, '$ltext'); got rc=$LRC: ${LOUT:0:300}"
}

# --- witnesses: the silent-wrong forms (gcc 13's value in the comment; pristine b9aeedcb4's in the record §1)
printf 'union U { int i; unsigned char c[4]; };\nint main(void) { union U u = { .c = {1,2,3,4} }; return u.c[0]*100 + u.c[3]; }   /* gcc 104; both engines 0 before */\n' > w_c_array.c
printf 'union U { int i; unsigned char c[4]; };\nunion U u = { .c[1] = 7 };   /* static storage */\nint main(void) { return u.c[1]*10 + u.c[0]; }   /* gcc 70 */\n' > w_c_elem_static.c
printf 'union U { int i; unsigned char c[4]; };\nint main(void) { union U u = { .c[3] = 6 }; return u.c[3]*10 + u.c[0]; }   /* automatic storage; gcc 60 */\n' > w_c_elem_auto.c
printf 'union U { int i; struct { int x; int y; } s; };\nint main(void) { union U u = { .s = { .y = 2 } }; return u.s.y*10 + u.s.x; }   /* gcc 20; both engines a UB036 verdict before */\n' > w_struct_member.c
printf 'union U { int a; char c[4]; };\nint main(void) { union U u = { .a = 42, .c[2] = 1 }; return u.c[0]*100 + u.c[1]*10 + u.c[2]; }   /* gcc 1; 4200 before */\n' > w_mixed_a_c.c
printf 'union U { int a; char c[4]; };\nint main(void) { union U u = { .c[2] = 1, .a = 42 }; return u.a; }   /* gcc 42; 42 before, right by luck */\n' > w_mixed_c_a.c
printf 'union U { int a; char c[4]; };\nint main(void) { union U u = { 9, .c[1] = 3 }; return u.c[0]*10 + u.c[1]; }   /* gcc 3; 90 before */\n' > w_positional_then_c.c
printf 'union In { int i; char c[4]; };\nunion Out { long l; union In in; };\nint main(void) { union Out o = { .in = { .c[1] = 5 } }; return o.in.c[1]*10 + o.in.c[0]; }   /* gcc 50; 0 before */\n' > w_nested.c
printf 'union U { int i; char c[4]; };\nint main(void) { union U a[2] = { [1] = { .c[0] = 9 }, [0] = { .i = 1 } }; return a[0].i*10 + a[1].c[0]; }   /* gcc 19; 10 before */\n' > w_array_of_unions.c
printf 'union U { int i; char c[4]; };\nint main(void) { union U u = { .c = "ab" }; return u.c[0] + u.c[2]*10; }   /* gcc 97; 0 before */\n' > w_string.c
printf 'union U { long b; int a; };\nint main(void) { union U u = { .a = 5 }; return u.a; }   /* gcc 5; 5 before, right only by representation overlap */\n' > w_scalar_second.c
printf 'union U { int i; char c; double d; };\nint main(void) {\n    union U u1 = { .i = 100 };\n    if (u1.i != 100) return 1;\n    union U u2 = { .c = 0x41 };   /* the RETIRED coverage control union3-003-union-init.c, its second declaration ([USER 2026-10-20]) */\n    if (u2.c != 0x41) return 2;\n    return 0;\n}\n' > w_coverage_union3_003_shape.c
printf 'union U { int i; char c[4]; };\nint main(void) { return (union U){ .c[2] = 8 }.c[2]*10; }   /* compound literal; gcc 80; 0 before */\n' > w_compound_literal.c
printf 'union U { int i; unsigned char c[4]; };\nstruct S { union U u; int k; };\nint main(void) { struct S s = { .u = { .c = {1,2,3,4} }, .k = 7 }; return s.k*10 + s.u.c[3]; }   /* gcc 74; pristine: internal error (invalid node) */\n' > w_in_struct_designated.c
# --- controls
printf 'union U { int a; char c[4]; };\nint main(void) { union U u = { 9 }; return u.a; }\n' > ctl_positional.c
printf 'union U { int a; char c[4]; };\nint main(void) { union U u = { .a = 1, .a = 2 }; return u.a; }\n' > ctl_first_twice.c
printf 'union U { int a; char c[4]; };\nint main(void) { union U u = { 9, .a = 2 }; return u.a; }   /* mixing positional and a FIRST-member designator: correct */\n' > ctl_positional_then_first.c
printf 'union U { struct { int x; int y; } s; long b; };\nint main(void) { union U u = { .s = { .y = 2 } }; return u.s.y*10 + u.s.x; }\n' > ctl_first_struct_partial.c
printf 'union V { unsigned char c[4]; int i; };\nint main(void) { union V v = { .c = {1,2,3,4} }; return v.c[0]*100 + v.c[3]; }   /* .c IS the first member */\n' > ctl_first_is_array.c
printf 'union U { int i; unsigned char c[4]; };\nunion U u = { .i = 258 };\nint main(void) { return u.i; }\n' > ctl_first_designated_static.c
printf 'union U { int i; char c[4]; };\nint main(void) { union U a[2] = { [1] = { .i = 9 }, [0] = { 1 } }; return a[0].i*10 + a[1].i; }\n' > ctl_array_first.c
printf 'union U { char c; int i; };\nint main(void) { union U u = { 0 }; return u.i; }\n' > ctl_zero_smaller_first.c
printf 'struct S { int k; union { int i; unsigned char c[4]; }; };\nint main(void) { struct S s = { .c = {1,2,3,4}, .k = 7 }; return s.k*10 + s.c[3]; }\n' > ctl_anonymous.c
printf 'union U { int i; unsigned char c[4]; };\nstruct S { union U u; int k; };\nint main(void) { struct S s = { { 1, 2, 3, 4 }, 7 }; return s.k*10 + s.u.i; }\n' > ctl_in_struct_positional.c
printf 'union U { int i; unsigned char c[4]; };\nstruct S { union U u; int k; };\nint main(void) { struct S s = { .u = { .i = 1 }, .k = 7 }; return s.k*10 + s.u.i; }\n' > ctl_in_struct_first.c
printf 'union U { int i; unsigned char c[4]; };\nint main(void) { union U u; u.c[1] = 7; u.c[0] = 0; return u.c[1]*10 + u.c[0]; }\n' > ctl_assign_not_init.c
# --- gap control (tray draft 59 §b: an already-noisy upstream rejection, unchanged by this slice)
printf 'struct T { int t; long l; };\nstruct S { struct T t; };\nint main(void) { struct T x = { 1, 2 }; struct S s = { .t = x, .t.l = 5 }; return (int)s.t.l; }   /* gcc 5 */\n' > gap_struct_from_struct_value.c

witness "designated second member, array (tray-59 witness; gcc 104)" w_c_array.c
witness "designated element of the second member, static storage (gcc 70)" w_c_elem_static.c
witness "designated element of the second member, automatic storage (gcc 60)" w_c_elem_auto.c
witness "designated second member, a struct, partially designated (gcc 20; a UB036 verdict before)" w_struct_member.c
witness "first member then a second-member designator (gcc 1; 4200 before)" w_mixed_a_c.c
witness "second-member designator then the first (gcc 42; right by luck before)" w_mixed_c_a.c
witness "positional then a second-member designator (gcc 3; 90 before)" w_positional_then_c.c
witness "nested union, inner second member designated (gcc 50)" w_nested.c
witness "array of unions, one element designated at the second member (gcc 19)" w_array_of_unions.c
witness "string literal for the second member (gcc 97)" w_string.c
witness "designated scalar second member (right by representation overlap; gcc 5)" w_scalar_second.c
witness "the retired coverage control union3-003's shape ({ .c = 'A' }, c the second member)" w_coverage_union3_003_shape.c
witness "compound literal designating the second member (gcc 80; 0 before)" w_compound_literal.c
witness "designated union member inside a struct (pristine: invalid node)" w_in_struct_designated.c
control "positional initializer" ctl_positional.c 'Defined {value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}'
control "first member designated twice" ctl_first_twice.c 'Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}'
control "positional then a first-member designator (mixing, first member only)" ctl_positional_then_first.c 'Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}'
control "first member a struct, partially designated" ctl_first_struct_partial.c 'Defined {value: "Specified(20)", stdout: "", stderr: "", blocked: "false"}'
control "first member an array, designated" ctl_first_is_array.c 'Defined {value: "Specified(104)", stdout: "", stderr: "", blocked: "false"}'
control "first member designated, static storage" ctl_first_designated_static.c 'Defined {value: "Specified(258)", stdout: "", stderr: "", blocked: "false"}'
control "array of unions, elements designated at the first member or positional" ctl_array_first.c 'Defined {value: "Specified(19)", stdout: "", stderr: "", blocked: "false"}'
control "{ 0 } with a smaller first member reads the larger member as Unspecified" ctl_zero_smaller_first.c "Defined {value: \"Unspecified('signed int')\", stdout: \"\", stderr: \"\", blocked: \"false\"}"
control "anonymous union member inside a struct, designated through the struct" ctl_anonymous.c 'Defined {value: "Specified(74)", stdout: "", stderr: "", blocked: "false"}'
control "union inside a struct, positional" ctl_in_struct_positional.c 'Defined {value: "Specified(71)", stdout: "", stderr: "", blocked: "false"}'
control "union inside a struct, first member designated" ctl_in_struct_first.c 'Defined {value: "Specified(71)", stdout: "", stderr: "", blocked: "false"}'
control "member assignment after declaration (not an initializer)" ctl_assign_not_init.c 'Defined {value: "Specified(70)", stdout: "", stderr: "", blocked: "false"}'
gap_control "GAP control (unchanged): struct member initialised from a struct variable" gap_struct_from_struct_value.c "$GAP_ORACLE" "$GAP_LEAN"

[[ $fails -eq 0 ]] || { echo "$NAME: $fails witness failure(s) over $n cases"; exit 1; }
echo "$NAME: OK ($n cases: 14 union initializers designating a member other than the first (static/automatic storage, a struct member, mixed positional/designated lists, a nested union, an array of unions, a string literal, a scalar second member, the retired coverage control union3-003's shape, a compound literal, a union inside a struct) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts; 12 controls agree with the oracle (positional and first-member designated forms incl. mixing with the first member only, { 0 } read as Unspecified, the anonymous-union-in-struct path, a union inside a struct positional or first-designated, member assignment); the struct-from-struct-variable rejection is unchanged on both)"
