#!/usr/bin/env bash
# check_anonymous_members_refusal.sh — row-1 witnesses for the anonymous-member refusal
# (upstream-uncertainty survey cluster A, tray 60; [USER 2026-10-20] ruled that anonymous
# struct/union members are REFUSED in the shared Lem and reported upstream, under the
# standing rule that where upstream left a case under its own TODO/doubt the fork leaves
# it or REFUSES LOUDLY and never answers silently wrong. Record
# lean_frontend/docs/2026-10-26_anonymous-members-refusal-record.md).
#
# Upstream's desugar_struct_declaration (frontend/model/cabs_to_ail.lem; pristine
# b9aeedcb4 :2697) handles a struct-declaration with NO declarator whose type specifier
# is a tagless struct/union (C17 6.7.2.1#13, an anonymous member) by returning the
# anonymous member's member list, i.e. splicing its members flat into the containing
# aggregate — `struct S { union { int b; char c; }; int d; }` desugars to
# `struct S { int b; char c; int d; }`. The anonymous member loses its own storage, so
# sizeof/offsets are wrong, an anonymous union's members do not alias, brace-elided
# initializers run one slot late and several valid programs get false UB verdicts (25
# silent-wrong probes under tests/parity-probes/uncertainty/A-anonymous-members/, both
# engines and pristine agreeing; the initializer layer carries upstream's own doubt,
# 'this may be WRONG ==> anonymous Struct/Union'). Now that arm of the SHARED desugarer
# REFUSES, at the member's declaration (whether or not the type is ever used), with ONE
# text whose kind word comes from the member's own type (oracle: Cerb_debug.error =
# `internal error: <text>` + uncaught Failure("internal error: <text>"), exit 125; Lean:
# failwithI, PANIC line carrying <text>, exit 134 under LEAN_ABORT_ON_PANIC=1):
#     Cabs_to_ail.desugar_struct_declaration: refused - anonymous union member (a struct-declaration with no declarator whose type specifier is a tagless union; C17 6.7.2.1#13); upstream splices its members into the containing aggregate's member list (...) - the fork refuses rather than decides (survey cluster A, tray 60, 2026-10-26)
# Every witness pins its WHOLE text (the kind word included: files named w_s_* expect
# `struct`, w_u_* expect `union`; in a nest the innermost anonymous member is desugared
# first and names the kind) and the two engines' texts are compared byte for byte.
# Witnesses: the survey's silent-wrong shapes (brace elision, the anonymous-first and
# array forms, sizeof/offsetof/aliasing/copy, an anonymous struct inside a union, the
# padding shape, false-UB shapes), the shapes that answered RIGHT by name lookup alone
# (designated initializers, an anonymous struct's sizeof, the RETIRED Tier A coverage
# control struct-008's shape, the union-initializer script's RETIRED anonymous control,
# the parity-detective probe's shape), and the bypass probes (nested anonymous members,
# a typedef'd tagless specifier, block scope, a compound literal in the initializer
# position, _Alignas, a type never used, sizeof only).
# Controls (Lean = oracle, exit code and verdict line): the same programs with NAMED
# members — a named union (`union { ... } u;`, braced and elided initializers, sizeof,
# aliasing), a named single-member union, a named struct inside a struct, a union with
# named members only inside a struct, a plain union, a tagless TYPE with a declarator
# (`struct { int x; } named;`), a tagless file-scope union object.
# Gap controls pin already-noisy upstream rejections as unchanged on both engines: a
# TAGGED struct with no declarator (`struct T { int x; };` inside a struct), a typedef'd
# tagged specifier, and `int;` — all `constraint violation: non-anonymous struct/union
# must contain a declarator list` (6.7.2.1#2) on the oracle and `desugaring failed` on
# Lean, exit 1. Fail-closed.
#
# Usage: check_anonymous_members_refusal.sh             the witnesses
#        check_anonymous_members_refusal.sh --selftest  plants: the witnesses must FAIL against
#            (a) `answer`: the pre-fix behaviour of BOTH engines — stubs that answer
#                Defined/Specified(12) (the retired control struct-008's value) on every
#                witness program (controls run the real engines);
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
NAME=check_anonymous_members_refusal
HEAD='Cabs_to_ail.desugar_struct_declaration: refused - anonymous '
TAIL="upstream splices its members into the containing aggregate's member list ('STD 6.7.2.1#13 ... E.return membrs' b9aeedcb4 :2697, under its own 'this may be WRONG ==> anonymous Struct/Union' :144/:166/:194/:3244), which changes layout, aliasing and initialisation (wrong sizeof and offsets, no aliasing between an anonymous union's members, brace-elided initializers one slot late, false UB verdicts) - the fork refuses rather than decides (survey cluster A, tray 60, 2026-10-26)"
# the oracle's Cerb_debug.error prefixes the text (the uncaught exception is Failure("internal error: <text>"))
OPREFIX='internal error: '
GAP_ORACLE='constraint violation: non-anonymous struct/union must contain a declarator list'
GAP_LEAN='Error {msg: "desugaring failed at '
expected_text() {  # <kind>: the whole text after HEAD for a member of that kind
    printf '%s member (a struct-declaration with no declarator whose type specifier is a tagless %s; C17 6.7.2.1#13); %s' "$1" "$1" "$TAIL"
}

if [[ "${1:-}" == "--selftest" ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    ANSWER='Defined {value: "Specified(12)", stdout: "", stderr: "", blocked: "false"}'
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
    # (c) refuse-all, in the right shape and words on both sides (the text's kind word read from
    # the file name, as the real engines read it from the member's type; the tail passed
    # through the environment: it contains quotes); the oracle stub still exports Cabs JSON so
    # the Lean stub is exercised
    export PLANT_HEAD="$HEAD" PLANT_TAIL="$TAIL"
    cat > "$ST/oracle-refuse-all" <<EOF
#!/usr/bin/env bash
if [[ " \$* " == *" --cabs-json "* ]]; then exec "$REAL_ORACLE" "\$@"; fi
last="\${@: -1}"; kind=union; [[ "\$(basename "\$last")" == w_s_* ]] && kind=struct
text="\$PLANT_HEAD\$kind member (a struct-declaration with no declarator whose type specifier is a tagless \$kind; C17 6.7.2.1#13); \$PLANT_TAIL"
printf 'internal error: %s\n' "\$text" >&2
echo 'cerberus: internal error, uncaught exception:' >&2
printf '          Failure("internal error: %s")\n' "\$text" >&2
exit 125
EOF
    cat > "$ST/lean-refuse-all" <<EOF
#!/usr/bin/env bash
last="\${@: -1}"; kind=union; [[ "\$(basename "\$last")" == w_s_* ]] && kind=struct
text="\$PLANT_HEAD\$kind member (a struct-declaration with no declarator whose type specifier is a tagless \$kind; C17 6.7.2.1#13); \$PLANT_TAIL"
printf 'PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: %s\n' "\$text" >&2
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
    # expected counts, derived: 29 witnesses, 10 verdict controls (all exit 0), 3 gap controls (exit 1 on both).
    #  answer:          each witness fails the oracle check and the Lean check (the text cross-check needs both texts)  = 29 x 2
    #  lean-answer:     each witness fails the Lean check; every control fails (Lean = oracle; the gap controls' exit)  = 29 + 10 + 3
    #  refuse-all:      the witnesses pass (one shape per kind, identical texts); every control fails                   = 10 + 3
    #  lean-no-abort:   each witness fails the Lean exit check; the gap controls (Lean exit 1) fail                      = 29 + 3
    #  lean-other-text: each witness fails the text cross-check only; the controls pass                                  = 29
    run_plant answer "$ST/oracle-answer" "$ST/lean-answer-witnesses" 58 "an-01: brace-elided initializer around an anonymous union (gcc 321; 21 before)" "ax-01: anonymous struct more aligned than its predecessor, sizeof (gcc 12; 8 before)" "the RETIRED Tier A coverage control struct-008-anon-struct's shape (12 by name lookup before)"
    run_plant lean-answer "$REAL_ORACLE" "$ST/lean-answer" 42 "an-01: brace-elided initializer around an anonymous union (gcc 321; 21 before)" "au-08: anonymous struct inside a union, aliasing (gcc 53; 33 before)" "un-01: NAMED union member, brace-elided initializer (321)" "GAP control (unchanged): a TAGGED struct with no declarator inside a struct"
    run_plant refuse-all "$ST/oracle-refuse-all" "$ST/lean-refuse-all" 13 "un-01: NAMED union member, brace-elided initializer (321)" "au-05: NAMED union member, sizeof (4)" "a tagless struct TYPE with a declarator (named member; 21)" "GAP control (unchanged): a TAGGED struct with no declarator inside a struct"
    run_plant lean-no-abort "$REAL_ORACLE" "$ST/lean-no-abort" 32 "an-01: brace-elided initializer around an anonymous union (gcc 321; 21 before)" "ax-01: anonymous struct more aligned than its predecessor, sizeof (gcc 12; 8 before)" "GAP control (unchanged): int; inside a struct"
    run_plant lean-other-text "$REAL_ORACLE" "$ST/lean-other-text" 29 "an-01: brace-elided initializer around an anonymous union (gcc 321; 21 before)" "ax-01: anonymous struct more aligned than its predecessor, sizeof (gcc 12; 8 before)"
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

witness() {  # <label> <c-file>: refused on BOTH engines with one text; the kind word from the file name (w_s_* struct, w_u_* union)
    local label="$1" c="$2" j="$W/$2.json" omsg= lmsg= kind=union want
    [[ "$c" == w_s_* ]] && kind=struct
    want="$HEAD$(expected_text "$kind")"
    n=$((n + 1))
    oracle_exec "$c"
    if [[ $ORC -eq 125 && "$OOUT" == *"uncaught exception"* && "$OOUT" == *"Failure(\"$OPREFIX$want\")"* ]]; then
        omsg=$(text_from "$HEAD" "$OOUT")
    else
        fail "$label: oracle: expected exit 125 + uncaught Failure(\"$OPREFIX$HEAD$kind member (…)\"); got rc=$ORC: ${OOUT:0:400}"
    fi
    if ! cabs_ok "$c" "$j"; then
        fail "$label: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lean_batch "$j"
    if [[ $LRC -eq 134 && "$LOUT" == *"PANIC"* && "$LOUT" == *"$want"* ]]; then
        lmsg=$(text_from "$HEAD" "$LOUT")
    else
        fail "$label: Lean: expected exit 134 (abort under LEAN_ABORT_ON_PANIC=1) + a PANIC line carrying '$HEAD$kind member (…)'; got rc=$LRC: ${LOUT:0:400}"
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

# --- witnesses: the survey's shapes (tests/parity-probes/uncertainty/A-anonymous-members/; gcc 13's value in the
# comment, the engines' pre-refusal answer after it), the shapes that answered right by name lookup alone, the
# retired controls' shapes, and the bypass probes. w_u_* expect the kind word `union`, w_s_* `struct`.
printf 'struct S { int a; union { int b; char c; }; int d; };\nint main(void){ struct S s = {1, {2}, 3}; return s.a + s.b*10 + s.d*100; }   /* an-01; gcc 321; 21 before (3 went into c, d stayed 0) */\n' > w_u_an01_braced_elision.c
printf 'struct S { int a; union { int b; char c; }; int d; };\nint main(void){ struct S s = {1, 2, 3}; return s.a + s.b*10 + s.d*100; }   /* an-02; gcc 321; 21 before */\n' > w_u_an02_elision.c
printf 'struct S { int a; union { int b; char c; }; int d; };\nint main(void){ struct S s = {.d = 3, .b = 2, .a = 1}; return s.a + s.b*10 + s.d*100; }   /* an-03; gcc 321; 321 before: right by name lookup alone */\n' > w_u_an03_designated.c
printf 'struct T { int a; struct { int b; int c; }; };\nint main(void){ struct T t = {1, 2, 3}; return t.a + t.b*10 + t.c*100; }   /* an-04; gcc 321; 321 before */\n' > w_s_an04_anon_struct_elision.c
printf 'struct T { int a; struct { int b; int c; }; int d; };\nint main(void){ struct T t = {1, {2, 3}, 4}; return t.a + t.b*10 + t.c*100 + t.d; }   /* an-08; gcc 69; a false UB081 verdict before */\n' > w_s_an08_false_ub081.c
printf 'struct S { union { int b; char c; }; int d; };\nint main(void){ struct S s = {2, 3}; return s.b*10 + s.d; }   /* un-06; gcc 23; 20 before */\n' > w_u_un06_anon_first.c
printf 'struct S { int a; union { int b; char c; }; int d; };\nint main(void){ struct S s = {1, 2, 3}; return s.c*10 + s.d; }   /* un-03; gcc 23; 30 before */\n' > w_u_un03_where_did_3_go.c
printf 'struct S { int a; union { int b; char c; }; int d; };\nint main(void){ struct S s[2] = {{1, 2, 3}, {4, 5, 6}}; return s[0].d + s[1].a*10 + s[1].d*100; }   /* un-11; gcc 131; 40 before */\n' > w_u_un11_array.c
printf 'struct S { int a; union { struct { int x; int y; } p; int q; }; int d; };\nint main(void){ struct S s = {1, {{2, 3}}, 4}; return s.a + s.p.x*10 + s.p.y*100 + s.d*1000; }   /* un-12; gcc 225; a false UB081 verdict before */\n' > w_u_un12_union_of_structs.c
printf 'struct S { union { int b; char c; }; }; int main(void){ return (int)sizeof(struct S); }   /* au-01; gcc 4; 8 before */\n' > w_u_au01_sizeof.c
printf 'struct S { union { int b; unsigned char c; }; }; int main(void){ struct S s; s.b = 0x01020304; return s.c; }   /* au-02; gcc 4; Unspecified before */\n' > w_u_au02_alias.c
printf 'struct S { int a; union { int b; char c; }; int d; }; int main(void){ struct S s; return (int)((char*)&s.d - (char*)&s); }   /* au-04; gcc 8; 12 before */\n' > w_u_au04_offsetof.c
printf 'struct T { int a; struct { int b; int c; }; }; int main(void){ return (int)sizeof(struct T); }   /* au-07; gcc 12; 12 before */\n' > w_s_au07_anon_struct_sizeof.c
printf 'union U { int x; struct { short lo; short hi; }; }; int main(void){ union U u; u.x = 0x00050003; return u.lo + u.hi*10; }   /* au-08; gcc 53; 33 before (lo and hi both aliased the low half) */\n' > w_s_au08_anon_struct_in_union.c
printf 'struct S { union { int b; unsigned char c; }; }; int main(void){ struct S s, t; s.b = 0x0102; t = s; return t.c; }   /* au-10; gcc 2; Unspecified before */\n' > w_u_au10_copy.c
printf 'struct S { char a; struct { char b; int c; }; }; int main(void){ return (int)sizeof(struct S); }   /* ax-01; gcc 12; 8 before */\n' > w_s_ax01_anon_struct_padding.c
printf 'struct S { int tag; union { struct { int x, y; }; long l; }; };\nint main(void){ struct S s; s.x = 20; s.y = 22; return (int)(sizeof(struct S)) + (s.l == ((long)22 << 32 | 20)); }   /* ax-03; gcc 17; a false UB036 verdict before */\n' > w_s_ax03_parity_shape_layout.c
printf 'struct S { union { int *ip; void *vp; }; }; int main(void){ struct S s; int x = 7; s.ip = &x; return s.vp == &x; }   /* ax-06; gcc 1; a false unspecified-equality UB verdict before */\n' > w_u_ax06_ptr_alias_false_ub.c
printf 'struct S { int tag; union { unsigned v; unsigned char bytes[4]; }; };\nint main(void){ struct S s = { .tag = 1, .v = 0x01020304 }; return s.bytes[0] + s.tag*10; }   /* ac-01; gcc 14; 10 before */\n' > w_u_ac01_desig_then_alias.c
printf '// the RETIRED Tier A row-3 coverage control tests/coverage/struct/struct-008-anon-struct.c (MATCH 12 by name lookup alone)\nstruct S {\n    struct {\n        int x;\n        int y;\n    };\n    int z;\n};\n\nint main(void) {\n    struct S s;\n    s.x = 3;\n    s.y = 4;\n    s.z = 5;\n\n    int sum = s.x + s.y + s.z;\n    // 3 + 4 + 5 = 12\n    return sum;\n}\n' > w_s_coverage_struct_008_shape.c
printf 'struct S { int k; union { int i; unsigned char c[4]; }; };\nint main(void) { struct S s = { .c = {1,2,3,4}, .k = 7 }; return s.k*10 + s.c[3]; }   /* the union-initializer script'"'"'s RETIRED control ctl_anonymous (74 before; s.i read 0 where gcc reads 1) */\n' > w_u_union_init_ctl_anonymous_shape.c
printf 'struct S {\n  int tag;\n  union {\n    struct { int x, y; };\n    long l;\n  };\n};\nint main(void) {\n  struct S s;\n  s.tag = 1; s.x = 20; s.y = 22;\n  return s.x + s.y;  /* the parity-detective probe tests/parity-probes/probes/anon_struct_union.c: AGREE 42 before, the layout never read */\n}\n' > w_s_parity_probe_shape.c
printf 'struct S { struct { union { int a; char b; }; int c; }; int d; };\nint main(void){ struct S s; s.a = 1; s.d = 2; return s.a + s.d; }   /* nested: the inner anonymous union is desugared first and names the kind */\n' > w_u_nested_anon.c
printf 'typedef struct { int a; int b; } T;\nstruct S { T; int c; };\nint main(void){ struct S s; s.c = 7; return s.c; }   /* a typedef of a TAGLESS struct used as a bare specifier: upstream spliced it too */\n' > w_s_typedef_tagless_specifier.c
printf 'int main(void){ struct S { union { int a; char b; }; int c; } s; s.c = 3; return s.c; }   /* block scope */\n' > w_u_block_scope.c
printf 'int main(void){ return ((struct { union { int a; char b; }; int c; }){ .c = 4 }).c; }   /* compound literal in the initializer position: the stop escapes wip_desugar_initializer_'"'"'s E.catch */\n' > w_u_compound_literal_initializer_position.c
printf 'struct S { _Alignas(16) union { int a; char b; }; int c; };\nint main(void){ struct S s; s.c = 3; return s.c; }\n' > w_u_alignas.c
printf 'struct S { int a; union { int b; char c; } ; };\nint main(void){ return 1; }   /* the type is never used: the refusal fires at the declaration */\n' > w_u_unused_type.c
printf 'struct S { union { int a; char b; }; int c; };\nint main(void){ return (int)sizeof(struct S); }\n' > w_u_sizeof_only.c
# --- controls: the same shapes with NAMED members
printf 'struct S { int a; union U { int b; char c; } u; int d; };\nint main(void){ struct S s = {1, 2, 3}; return s.a + s.u.b*10 + s.d*100; }   /* un-01 */\n' > ctl_un01_named_elision.c
printf 'struct S { int a; union U { int b; char c; } u; int d; };\nint main(void){ struct S s = {1, {2}, 3}; return s.a + s.u.b*10 + s.d*100; }   /* un-02 */\n' > ctl_un02_named_braced.c
printf 'struct S { int a; union { int b; } u; int d; };\nint main(void){ struct S s = {1, 2, 3}; return s.a + s.u.b*10 + s.d*100; }   /* un-08 */\n' > ctl_un08_named_single_member.c
printf 'struct S { union { int b; char c; } u; }; int main(void){ return (int)sizeof(struct S); }   /* au-05 */\n' > ctl_au05_named_union_sizeof.c
printf 'struct S { union { int b; unsigned char c; } u; }; int main(void){ struct S s; s.u.b = 0x01020304; return s.u.c; }   /* au-06 */\n' > ctl_au06_named_union_alias.c
printf 'struct S { int a; struct { int b; int c; } u; int d; };\nint main(void){ struct S s = {1, {2, 3}, 4}; return s.a + s.u.b*10 + s.u.c*100 + s.d*1000; }\n' > ctl_named_struct_inside_struct.c
printf 'union U { int a; char b; };\nstruct S { int x; union U u; };\nint main(void){ struct S s = {1, {2}}; return s.x + s.u.a*10; }\n' > ctl_union_named_members_only_in_struct.c
printf 'union U { int a; char b; };\nint main(void){ union U u = {5}; return u.a; }\n' > ctl_plain_union.c
printf 'struct S { struct { int x; } named; int y; };\nint main(void){ struct S s = {{1}, 2}; return s.named.x + s.y*10; }   /* a tagless TYPE with a declarator is a named member */\n' > ctl_tagless_type_named_declarator.c
printf 'union { int a; char b; } g;   /* a tagless file-scope union OBJECT (tests/ci/0308'"'"'s shape): not a member */\nint main(void){ g.a = 9; return g.a; }\n' > ctl_tagless_file_scope_object.c
# --- gap controls: already-noisy upstream rejections (6.7.2.1#2), unchanged by this slice
printf 'struct S { int a; struct T { int x; }; int d; };\nint main(void){ struct S s; s.a = 1; return s.a; }\n' > gap_tagged_no_declarator.c
printf 'typedef struct TT { int a; int b; } T;\nstruct S { T; int c; };\nint main(void){ struct S s; s.c = 7; return s.c; }\n' > gap_typedef_tagged_specifier.c
printf 'struct T2 { int; };\nint main(void){ return 0; }   /* the second line of tests/suite/desugaring/13-non_anonymous_empty_sdecltors.error.c */\n' > gap_int_no_declarator.c

witness "an-01: brace-elided initializer around an anonymous union (gcc 321; 21 before)" w_u_an01_braced_elision.c
witness "an-02: brace elision through an anonymous union (gcc 321; 21 before)" w_u_an02_elision.c
witness "an-03: designated initializers naming the anonymous union's member (right by name lookup alone before)" w_u_an03_designated.c
witness "an-04: brace elision through an anonymous struct (321 before)" w_s_an04_anon_struct_elision.c
witness "an-08: braced initializer for an anonymous struct member (gcc 69; a false UB081 before)" w_s_an08_false_ub081.c
witness "un-06: anonymous union first, elided (gcc 23; 20 before)" w_u_un06_anon_first.c
witness "un-03: the member after the anonymous union read back (gcc 23; 30 before)" w_u_un03_where_did_3_go.c
witness "un-11: array of structs with an anonymous union (gcc 131; 40 before)" w_u_un11_array.c
witness "un-12: anonymous union of a named struct and a scalar, braced (gcc 225; a false UB081 before)" w_u_un12_union_of_structs.c
witness "au-01: sizeof with an anonymous union (gcc 4; 8 before)" w_u_au01_sizeof.c
witness "au-02: aliasing inside an anonymous union (gcc 4; Unspecified before)" w_u_au02_alias.c
witness "au-04: offset of the member after an anonymous union (gcc 8; 12 before)" w_u_au04_offsetof.c
witness "au-07: sizeof with an anonymous struct (12 before, by luck)" w_s_au07_anon_struct_sizeof.c
witness "au-08: anonymous struct inside a union, aliasing (gcc 53; 33 before)" w_s_au08_anon_struct_in_union.c
witness "au-10: struct copy through an anonymous union (gcc 2; Unspecified before)" w_u_au10_copy.c
witness "ax-01: anonymous struct more aligned than its predecessor, sizeof (gcc 12; 8 before)" w_s_ax01_anon_struct_padding.c
witness "ax-03: the parity-probe shape checked for layout (gcc 17; a false UB036 before)" w_s_ax03_parity_shape_layout.c
witness "ax-06: pointer members of an anonymous union compared (gcc 1; a false UB verdict before)" w_u_ax06_ptr_alias_false_ub.c
witness "ac-01: designated anonymous-union member then its alias read (gcc 14; 10 before)" w_u_ac01_desig_then_alias.c
witness "the RETIRED Tier A coverage control struct-008-anon-struct's shape (12 by name lookup before)" w_s_coverage_struct_008_shape.c
witness "the union-initializer script's RETIRED control: an anonymous union designated through the struct (74 before)" w_u_union_init_ctl_anonymous_shape.c
witness "the parity-detective probe anon_struct_union's shape (AGREE 42 before)" w_s_parity_probe_shape.c
witness "nested anonymous members (the inner union names the kind)" w_u_nested_anon.c
witness "a typedef'd TAGLESS struct as a bare specifier" w_s_typedef_tagless_specifier.c
witness "an anonymous union in a block-scope struct" w_u_block_scope.c
witness "a compound literal of such a struct in the initializer position" w_u_compound_literal_initializer_position.c
witness "_Alignas on an anonymous union member" w_u_alignas.c
witness "an anonymous union in a type that is never used" w_u_unused_type.c
witness "sizeof only" w_u_sizeof_only.c
control "un-01: NAMED union member, brace-elided initializer (321)" ctl_un01_named_elision.c 'Defined {value: "Specified(321)", stdout: "", stderr: "", blocked: "false"}'
control "un-02: NAMED union member, braced initializer (321)" ctl_un02_named_braced.c 'Defined {value: "Specified(321)", stdout: "", stderr: "", blocked: "false"}'
control "un-08: NAMED single-member union (321)" ctl_un08_named_single_member.c 'Defined {value: "Specified(321)", stdout: "", stderr: "", blocked: "false"}'
control "au-05: NAMED union member, sizeof (4)" ctl_au05_named_union_sizeof.c 'Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}'
control "au-06: NAMED union member, aliasing (4)" ctl_au06_named_union_alias.c 'Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}'
control "a NAMED struct inside a struct, braced (4321)" ctl_named_struct_inside_struct.c 'Defined {value: "Specified(4321)", stdout: "", stderr: "", blocked: "false"}'
control "a union with named members only, as a named struct member (21)" ctl_union_named_members_only_in_struct.c 'Defined {value: "Specified(21)", stdout: "", stderr: "", blocked: "false"}'
control "a plain union (5)" ctl_plain_union.c 'Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}'
control "a tagless struct TYPE with a declarator (named member; 21)" ctl_tagless_type_named_declarator.c 'Defined {value: "Specified(21)", stdout: "", stderr: "", blocked: "false"}'
control "a tagless file-scope union object (9)" ctl_tagless_file_scope_object.c 'Defined {value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}'
gap_control "GAP control (unchanged): a TAGGED struct with no declarator inside a struct" gap_tagged_no_declarator.c "$GAP_ORACLE" "$GAP_LEAN"
gap_control "GAP control (unchanged): a typedef'd TAGGED struct as a bare specifier" gap_typedef_tagged_specifier.c "$GAP_ORACLE" "$GAP_LEAN"
gap_control "GAP control (unchanged): int; inside a struct" gap_int_no_declarator.c "$GAP_ORACLE" "$GAP_LEAN"

[[ $fails -eq 0 ]] || { echo "$NAME: $fails witness failure(s) over $n cases"; exit 1; }
echo "$NAME: OK ($n cases: 29 anonymous struct/union members (the survey's brace-elision, anonymous-first, array, sizeof/offsetof/aliasing/copy, anonymous-struct-in-union, padding and false-UB shapes; the designated, anonymous-struct-sizeof, retired coverage control struct-008, retired union-initializer control and parity-probe shapes that answered right by name lookup alone; nested members, a typedef'd tagless specifier, block scope, a compound literal, _Alignas, an unused type, sizeof only) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts naming the member's kind; 10 controls with NAMED members agree with the oracle (a named union elided/braced/sizeof/aliased, a named single-member union, a named struct inside a struct, a union with named members only, a plain union, a tagless type with a declarator, a tagless file-scope object); the tagged-no-declarator, typedef'd-tagged and int; constraint violations are unchanged on both)"
