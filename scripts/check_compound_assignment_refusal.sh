#!/usr/bin/env bash
# check_compound_assignment_refusal.sh — row-1 witnesses for the compound-assignment refusal
# (upstream-uncertainty survey cluster B, tray 61; [USER 2026-10-20] ruled that a compound
# assignment whose left operand has a side effect is REFUSED in the shared Lem and the
# one-binding elaboration proposed upstream, under the standing rule that where upstream left
# a case under its own TODO the fork leaves it or REFUSES LOUDLY and never answers silently
# wrong. Record lean_frontend/docs/2026-10-29_compound-assignment-refusal-record.md).
#
# Upstream's AilEcompoundAssign arm (frontend/model/translation.lem; pristine b9aeedcb4
# :2505-2531, under its own `TODO: this elaboration is wrong because it duplicates any
# side-effect in E1`) rewrites E1 op= E2 to E1 = E1 op E2 and elaborates E1 twice. With an
# increment, a call or a comma inside the lvalue the second copy is a second side effect:
# `a[g()] += 4` calls g twice (24 where gcc gives 14) and `a[i++] += 5` is reported as
# UB035_unsequenced_race (false: C17 6.5.16#3 sequences the update after both value
# computations, 6.5.16.2#3 evaluates the lvalue E1 only once). Now the SHARED elaborator
# REFUSES when a syntactic walk over E1 (compound_assign_lhs_has_side_effect) finds an
# increment/decrement, an assignment, a compound assignment (the prefix ++/-- forms), a comma,
# a call (pure or not), an assert, a va_* builtin, a statement expression or a compound literal
# anywhere inside it. The stop is a pure Lem `error` with ONE text, the location prefix of
# the translation layer's record_error_at rendering (`<file>:<line>:<col>:: `, the cursor at
# the operator) followed by the fixed text (oracle: Cerb_debug.error = `internal error: <text>`
# + uncaught Failure("internal error: <text>"), exit 125; Lean: failwithI, a PANIC line
# carrying <text>, exit 134 under LEAN_ABORT_ON_PANIC=1):
#     <file>:<line>:<col>:: Translation.translate_expression: refused - compound assignment whose left operand contains a side effect (...) - the fork refuses rather than decides (survey cluster B, tray 61, 2026-10-29)
# Every witness pins its WHOLE text, the location included, and the two engines' texts are
# compared byte for byte.
# Witnesses: the survey's side-effecting probes (ca-02/03/04/05/06, cb-02/03/04/08: a
# postfix increment in a subscript, a pointer post-increment, a call as the lvalue, a shifted
# and an or'ed member, a call in a subscript, a pre-decrement, a post-incremented pointer
# member, a comma in a subscript) and this slice's own shapes (a pre-increment, a call two
# levels deep, a comma in a member's subscript, a compound literal lvalue, an assignment in a
# cast's operand, va_arg inside the lvalue, a _Generic controlling expression (walked though C
# does not evaluate it: the over-approximation), the `^=` and `>>=` operators — every op= appears
# at least once).
# Controls (Lean = oracle, exit code and verdict line): the survey's controls (ca-01 a plain
# subscript, cb-01 a side effect in the RIGHT operand only, cb-06 plain `=` with a
# post-increment, cb-07 `++` on the lvalue), `*p += 1`, `s.v |= 4`, `a[f] <<= 2` with f a
# variable, a side effect only in e2, a VOLATILE object (`v += 2`: one load, one store) and a
# volatile read inside the address computation (`a[i] += 2`, i volatile: NOT counted, the
# declared under-approximation), and a sizeof operand (`a[sizeof(i++)] += 1`: the operand does
# not survive typing, no refusal).
# Gap control: the survey's cb-05 (`s[i++].bf += 2` on a bit-field) is the pre-existing
# `feature not yet supported: bit-fields` rejection on both engines, exit 1, unchanged.
# Fail-closed.
#
# Usage: check_compound_assignment_refusal.sh             the witnesses
#        check_compound_assignment_refusal.sh --selftest  plants: the witnesses must FAIL against
#            (a) `answer`: the pre-fix behaviour of BOTH engines — stubs that answer
#                Defined/Specified(24) (cb-02's pre-fix value, g called twice; a value no
#                control expects) on every witness program (controls run the real engines);
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
NAME=check_compound_assignment_refusal
HEAD='Translation.translate_expression: refused - compound assignment whose left operand contains a side effect'
TAIL=" (an increment or decrement, an assignment, a function call, a comma, a va_arg, a statement expression or a compound literal anywhere inside the lvalue; C17 6.5.16#3 sequences the update after both value computations and 6.5.16.2#3 evaluates the lvalue E1 only once); upstream elaborates E1 op= E2 as E1 = E1 op E2 with E1 elaborated twice, under its own 'TODO: this elaboration is wrong because it duplicates any side-effect in E1' (translation.lem b9aeedcb4 :2506), so the lvalue's side effect runs twice (a call in the lvalue is called twice, a wrong value) or a false UB035_unsequenced_race is reported (the ++/--/comma forms) - the fork refuses rather than decides (survey cluster B, tray 61, 2026-10-29)"
# the oracle's Cerb_debug.error prefixes the text (the uncaught exception is Failure("internal error: <text>"))
OPREFIX='internal error: '
GAP_ORACLE='feature not yet supported: bit-fields'
GAP_LEAN='Error {msg: "desugaring failed at '
# the witnesses' locations (the cursor of the compound assignment = its operator), file=line:col
WITNESS_LOCS='w_ca02_idx_postinc.c=1:53 w_ca03_ptr_postinc.c=1:54 w_ca04_call_lvalue.c=2:22 w_ca05_shift_postinc.c=1:54 w_ca06_member_postinc.c=1:81 w_cb02_lhs_call_index.c=2:43 w_cb03_predec.c=1:54 w_cb04_ptr_deref_postinc_struct.c=1:91 w_cb08_comma_lhs.c=1:62 w_preincr_subeq.c=1:53 w_call_two_deep_muleq.c=2:59 w_comma_member_subscript_diveq.c=2:53 w_compound_literal_modeq.c=1:44 w_assign_in_cast_andeq.c=1:60 w_va_arg.c=2:95 w_postincr_xoreq.c=1:49 w_postincr_shreq.c=1:49 w_generic_controlling.c=1:67'
loc_of() {  # <basename> -> line:col from WITNESS_LOCS (empty if unknown)
    local kv
    for kv in $WITNESS_LOCS; do [[ "${kv%%=*}" == "$1" ]] && { printf '%s' "${kv#*=}"; return; }; done
}

if [[ "${1:-}" == "--selftest" ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    ANSWER='Defined {value: "Specified(24)", stdout: "", stderr: "", blocked: "false"}'
    # (a) answer: on a witness program (w_*.c / w_*.json) under --exec / --batch, answer as
    # both engines did before the fix; everything else (controls, --cabs-json) runs the real engine
    cat > "$ST/oracle-answer" <<EOS
#!/usr/bin/env bash
last="\${@: -1}"
if [[ " \$* " == *" --exec "* && "\$(basename "\$last")" == w_*.c ]]; then echo '$ANSWER'; exit 0; fi
exec "$REAL_ORACLE" "\$@"
EOS
    cat > "$ST/lean-answer-witnesses" <<EOS
#!/usr/bin/env bash
last="\${@: -1}"
if [[ "\$(basename "\$last")" == w_*.json ]]; then echo '$ANSWER'; exit 0; fi
exec "$REAL_BIN" "\$@"
EOS
    # (b) lean-answer: answer on every input
    printf '#!/usr/bin/env bash\necho %q\nexit 0\n' "$ANSWER" > "$ST/lean-answer"
    # (c) refuse-all, in the right shape and words on both sides (the location looked up from the
    # file name as the real engines read it from the Ail; a control gets 1:1 and fails anyway; the
    # text passed through the environment: it contains quotes); the oracle stub still exports
    # Cabs JSON so the Lean stub is exercised
    export PLANT_HEAD="$HEAD" PLANT_TAIL="$TAIL" PLANT_LOCS="$WITNESS_LOCS"
    cat > "$ST/oracle-refuse-all" <<EOS
#!/usr/bin/env bash
if [[ " \$* " == *" --cabs-json "* ]]; then exec "$REAL_ORACLE" "\$@"; fi
last="\${@: -1}"; b=\$(basename "\$last"); loc=1:1
for kv in \$PLANT_LOCS; do [[ "\${kv%%=*}" == "\$b" ]] && loc="\${kv#*=}"; done
text="\$b:\$loc:: \$PLANT_HEAD\$PLANT_TAIL"
printf 'internal error: %s\n' "\$text" >&2
echo 'cerberus: internal error, uncaught exception:' >&2
printf '          Failure("internal error: %s")\n' "\$text" >&2
exit 125
EOS
    cat > "$ST/lean-refuse-all" <<EOS
#!/usr/bin/env bash
last="\${@: -1}"; b=\$(basename "\${last%.json}"); loc=1:1
for kv in \$PLANT_LOCS; do [[ "\${kv%%=*}" == "\$b" ]] && loc="\${kv#*=}"; done
text="\$b:\$loc:: \$PLANT_HEAD\$PLANT_TAIL"
printf 'PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: %s\n' "\$text" >&2
exit 134
EOS
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
    # expected counts, derived: 18 witnesses, 11 verdict controls (all exit 0), 1 gap control (exit 1 on both).
    #  answer:          each witness fails the oracle check and the Lean check (the text cross-check needs both texts)  = 18 x 2
    #  lean-answer:     each witness fails the Lean check; every control fails (Lean = oracle; the gap control's exit)   = 18 + 11 + 1
    #  refuse-all:      the witnesses pass (the stubs know their locations, identical texts); every control fails         = 11 + 1
    #  lean-no-abort:   each witness fails the Lean exit check; the gap control (Lean exit 1) fails                       = 18 + 1
    #  lean-other-text: each witness fails the text cross-check only; the controls pass                                   = 18
    run_plant answer "$ST/oracle-answer" "$ST/lean-answer-witnesses" 36 "ca-02: a postfix increment in the subscript (gcc 15; a false UB035 before)" "cb-02: a call in the subscript (gcc 14; 24 before, g called twice)" "a va_arg inside the lvalue"
    run_plant lean-answer "$REAL_ORACLE" "$ST/lean-answer" 30 "ca-02: a postfix increment in the subscript (gcc 15; a false UB035 before)" "ca-04: a call as the lvalue (gcc 13; 23 before, g called twice)" "ca-01: a plain subscript (5)" "GAP control (unchanged): cb-05, a post-increment on a bit-field member"
    run_plant refuse-all "$ST/oracle-refuse-all" "$ST/lean-refuse-all" 12 "ca-01: a plain subscript (5)" "cb-01: a side effect in the RIGHT operand only (11)" "a volatile read inside the address computation is NOT counted (2)" "GAP control (unchanged): cb-05, a post-increment on a bit-field member"
    run_plant lean-no-abort "$REAL_ORACLE" "$ST/lean-no-abort" 19 "ca-02: a postfix increment in the subscript (gcc 15; a false UB035 before)" "cb-08: a comma in the subscript (gcc 13; a false UB035 before)" "GAP control (unchanged): cb-05, a post-increment on a bit-field member"
    run_plant lean-other-text "$REAL_ORACLE" "$ST/lean-other-text" 18 "ca-02: a postfix increment in the subscript (gcc 15; a false UB035 before)" "a compound literal lvalue (%=)"
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
cabs_ok() {  # <c-file> <json>: the export must succeed (the refusal is in the elaborator, after Cabs)
    "$ORACLE" --runtime="$PREFIX" --cabs-json "$1" > "$2" 2> "$2.err" && [[ -s "$2" ]]
}
verdict_line() { grep -aE '^(Defined|Undefined|Error) ' | head -1; }
text_from() {  # <head> <output>: the refusal text from its head to the end of its line (the oracle's closing `")` removed)
    local line
    line=$(printf '%s\n' "$2" | grep -aF -m1 "$1") || return 1
    line="$1${line#*"$1"}"
    printf '%s' "${line%\")}"
}

witness() {  # <label> <c-file>: refused on BOTH engines with one text, the location from WITNESS_LOCS
    local label="$1" c="$2" j="$W/$2.json" omsg= lmsg= loc want
    loc=$(loc_of "$c")
    [[ -n "$loc" ]] || { fail "$label: no pinned location for $c (WITNESS_LOCS)"; return; }
    want="$c:$loc:: $HEAD$TAIL"
    n=$((n + 1))
    oracle_exec "$c"
    if [[ $ORC -eq 125 && "$OOUT" == *"uncaught exception"* && "$OOUT" == *"Failure(\"$OPREFIX$want\")"* ]]; then
        omsg=$(text_from "$c:$loc:: " "$OOUT")
    else
        fail "$label: oracle: expected exit 125 + uncaught Failure(\"$OPREFIX$c:$loc:: $HEAD (…)\"); got rc=$ORC: ${OOUT:0:400}"
    fi
    if ! cabs_ok "$c" "$j"; then
        fail "$label: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lean_batch "$j"
    if [[ $LRC -eq 134 && "$LOUT" == *"PANIC"* && "$LOUT" == *"$want"* ]]; then
        lmsg=$(text_from "$c:$loc:: " "$LOUT")
    else
        fail "$label: Lean: expected exit 134 (abort under LEAN_ABORT_ON_PANIC=1) + a PANIC line carrying '$c:$loc:: $HEAD (…)'; got rc=$LRC: ${LOUT:0:400}"
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

# --- witnesses: the survey's side-effecting probes (tests/parity-probes/uncertainty/B-compound-assignment/, their
# texts verbatim; gcc 13's value and the engines' pre-refusal answer in the label) and this slice's own shapes.
printf 'int main(void){ int a[4]={0,0,0,0}; int i=0; a[i++] += 5; return i*10 + a[0]; }\n' > w_ca02_idx_postinc.c
printf 'int main(void){ int a[4]={0,0,0,0}; int *p = a; *p++ += 7; return (int)(p - a)*10 + a[0]; }\n' > w_ca03_ptr_postinc.c
printf 'static int n; static int a[2]; static int *g(void){ n++; return &a[0]; }\nint main(void){ *g() += 3; return n*10 + a[0]; }\n' > w_ca04_call_lvalue.c
printf 'int main(void){ unsigned u[2]={1,1}; int i=0; u[i++] <<= 2; return i*10 + (int)u[0]; }\n' > w_ca05_shift_postinc.c
printf 'struct S { int v; }; int main(void){ struct S s[2]={{1},{1}}; int i=0; s[i++].v |= 4; return i*10 + s[0].v; }\n' > w_ca06_member_postinc.c
printf 'static int n; static int g(void){ n++; return 0; }\nint main(void){ int a[2] = {0, 0}; a[g()] += 4; return n*10 + a[0]; }\n' > w_cb02_lhs_call_index.c
printf 'int main(void){ int a[2] = {0, 0}; int i = 1; a[--i] += 6; return i*10 + a[0]; }\n' > w_cb03_predec.c
printf 'struct S { int v; }; int main(void){ struct S s[2] = {{1},{2}}; struct S *p = s; (p++)->v += 5; return (int)(p - s)*10 + s[0].v; }\n' > w_cb04_ptr_deref_postinc_struct.c
printf 'static int n; int main(void){ int a[2] = {0, 0}; a[(n++, 0)] += 3; return n*10 + a[0]; }\n' > w_cb08_comma_lhs.c
printf 'int main(void){ int a[4]={0,0,0,0}; int i=0; a[++i] -= 5; return i*10 + a[1]; }   /* pre-increment (AilEcompoundAssign in the subscript) */\n' > w_preincr_subeq.c
printf 'static int n; static int g(void){ n++; return 0; }\nint main(void){ int a[2]={1,1}; int b[2]={0,0}; a[b[g()]] *= 3; return n*10 + a[0]; }   /* a call nested two levels deep */\n' > w_call_two_deep_muleq.c
printf 'struct S { int a[2]; }; static int n;\nint main(void){ struct S s = {{8,8}}; s.a[(n++, 0)] /= 2; return n*10 + s.a[0]; }   /* a comma in a member'"'"'s subscript */\n' > w_comma_member_subscript_diveq.c
printf 'int main(void){ return ((int[2]){7, 1})[0] %%= 4; }   /* a compound literal lvalue */\n' > w_compound_literal_modeq.c
printf 'int main(void){ int x = 7, *p = 0, *q = &x; *(int*)(p = q) &= 3; return x + (p == q); }   /* an assignment in a cast'"'"'s operand */\n' > w_assign_in_cast_andeq.c
printf '#include <stdarg.h>\nstatic int f(int n, ...){ va_list ap; va_start(ap, n); *va_arg(ap, int*) += 1; va_end(ap); return 0; }\nint main(void){ int x = 1; f(1, &x); return x; }   /* va_arg inside the lvalue */\n' > w_va_arg.c
printf 'int main(void){ int a[2]={5,5}; int i=0; a[i++] ^= 3; return i*10 + a[0]; }\n' > w_postincr_xoreq.c
printf 'int main(void){ int a[2]={8,8}; int i=0; a[i++] >>= 1; return i*10 + a[0]; }\n' > w_postincr_shreq.c
printf 'int main(void){ int a[2]={0,0}; int i=0; a[_Generic(i++, int: 0)] += 1; return i*10 + a[0]; }   /* the _Generic controlling expression is walked though C does not evaluate it: the over-approximation */\n' > w_generic_controlling.c
# --- controls: no side effect inside the lvalue
printf 'int main(void){ int a[4]={0,0,0,0}; int i=0; a[i] += 5; return i*10 + a[0]; }\n' > ctl_ca01_plain_subscript.c
printf 'static int n; static int g(void){ return ++n; }\nint main(void){ int x = 0; x += g(); return n*10 + x; }\n' > ctl_cb01_rhs_call_once.c
printf 'int main(void){ int a[2] = {0, 0}; int i = 0; a[i++] = 5; return i*10 + a[0]; }\n' > ctl_cb06_plain_eq_postinc.c
printf 'int main(void){ int a[2] = {0, 0}; int i = 0; a[i++]++; return i*10 + a[0]; }\n' > ctl_cb07_postinc_on_lvalue.c
printf 'int main(void){ int x = 1; int *p = &x; *p += 1; return x; }\n' > ctl_deref.c
printf 'struct S { int v; }; int main(void){ struct S s = {1}; s.v |= 4; return s.v; }\n' > ctl_member.c
printf 'int main(void){ int a[4]={1,1,1,1}; int f = 2; a[f] <<= 2; return a[2]; }\n' > ctl_subscript_variable.c
printf 'static int n; static int g(void){ n++; return 2; }\nint main(void){ int a[2]={0,0}; int i=0; a[i] += g(); return n*10 + a[0]; }   /* a side effect only in e2 */\n' > ctl_rhs_side_effect.c
printf 'int main(void){ volatile int v = 1; v += 2; return v; }   /* the volatile object itself: one load (the rvalue copy), one store */\n' > ctl_volatile_object.c
printf 'int main(void){ int a[2]={0,0}; volatile int i = 1; a[i] += 2; return a[1]; }   /* a volatile read in the address computation is NOT counted (i loaded twice) */\n' > ctl_volatile_subscript.c
printf 'int main(void){ int a[8]={0,0,0,0,0,0,0,0}; int i=0; a[sizeof(i++)] += 1; return i*10 + a[4]; }   /* the sizeof operand does not survive typing: no refusal */\n' > ctl_sizeof_operand.c
# --- gap control: the survey's cb-05, a pre-existing rejection unchanged by this slice
printf 'struct S { unsigned bf : 3; }; int main(void){ struct S s[2] = {{1},{1}}; int i = 0; s[i++].bf += 2; return i*10 + s[0].bf; }\n' > gap_cb05_bitfield_postinc.c

witness "ca-02: a postfix increment in the subscript (gcc 15; a false UB035 before)" w_ca02_idx_postinc.c
witness "ca-03: a pointer post-increment as the lvalue (gcc 17; a false UB035 before)" w_ca03_ptr_postinc.c
witness "ca-04: a call as the lvalue (gcc 13; 23 before, g called twice)" w_ca04_call_lvalue.c
witness "ca-05: a postfix increment in the subscript, <<= (gcc 14; a false UB035 before)" w_ca05_shift_postinc.c
witness "ca-06: a post-incremented subscript of a struct member, |= (gcc 15; a false UB035 before)" w_ca06_member_postinc.c
witness "cb-02: a call in the subscript (gcc 14; 24 before, g called twice)" w_cb02_lhs_call_index.c
witness "cb-03: a pre-decrement in the subscript (gcc 6; a false UB035 before)" w_cb03_predec.c
witness "cb-04: a post-incremented pointer's member (gcc 16; a false UB035 before)" w_cb04_ptr_deref_postinc_struct.c
witness "cb-08: a comma in the subscript (gcc 13; a false UB035 before)" w_cb08_comma_lhs.c
witness "a pre-increment in the subscript (-=)" w_preincr_subeq.c
witness "a call two levels deep (*=)" w_call_two_deep_muleq.c
witness "a comma in a member's subscript (/=)" w_comma_member_subscript_diveq.c
witness "a compound literal lvalue (%=)" w_compound_literal_modeq.c
witness "an assignment in a cast's operand (&=)" w_assign_in_cast_andeq.c
witness "a va_arg inside the lvalue" w_va_arg.c
witness "a postfix increment in the subscript (^=)" w_postincr_xoreq.c
witness "a postfix increment in the subscript (>>=)" w_postincr_shreq.c
witness "a _Generic controlling expression (walked; the over-approximation)" w_generic_controlling.c
control "ca-01: a plain subscript (5)" ctl_ca01_plain_subscript.c 'Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}'
control "cb-01: a side effect in the RIGHT operand only (11)" ctl_cb01_rhs_call_once.c 'Defined {value: "Specified(11)", stdout: "", stderr: "", blocked: "false"}'
control "cb-06: plain = with a post-incremented subscript (15)" ctl_cb06_plain_eq_postinc.c 'Defined {value: "Specified(15)", stdout: "", stderr: "", blocked: "false"}'
control "cb-07: ++ on the lvalue itself (11)" ctl_cb07_postinc_on_lvalue.c 'Defined {value: "Specified(11)", stdout: "", stderr: "", blocked: "false"}'
control "*p += 1 (2)" ctl_deref.c 'Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}'
control "s.v |= 4 (5)" ctl_member.c 'Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}'
control "a[f] <<= 2 with f a variable (4)" ctl_subscript_variable.c 'Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}'
control "a side effect only in e2 (12)" ctl_rhs_side_effect.c 'Defined {value: "Specified(12)", stdout: "", stderr: "", blocked: "false"}'
control "a volatile object as the lvalue (3)" ctl_volatile_object.c 'Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}'
control "a volatile read inside the address computation is NOT counted (2)" ctl_volatile_subscript.c 'Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}'
control "a sizeof operand does not survive typing (1)" ctl_sizeof_operand.c 'Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}'
gap_control "GAP control (unchanged): cb-05, a post-increment on a bit-field member" gap_cb05_bitfield_postinc.c "$GAP_ORACLE" "$GAP_LEAN"

[[ $fails -eq 0 ]] || { echo "$NAME: $fails witness failure(s) over $n cases"; exit 1; }
echo "$NAME: OK ($n cases: 18 compound assignments whose left operand contains a side effect (the survey's post-increment, pointer post-increment, call-as-lvalue, shifted and or'ed member, call-in-subscript, pre-decrement, post-incremented pointer member and comma-in-subscript shapes; a pre-increment, a call two levels deep, a comma in a member's subscript, a compound literal lvalue, an assignment in a cast's operand, va_arg, a _Generic controlling expression, and the ^= and >>= operators — every op= at least once) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts pinned whole, location included; 11 controls agree with the oracle (a plain subscript, a side effect in the right operand only, plain = and ++ with a post-incremented subscript, *p += 1, s.v |= 4, a[f] <<= 2, a side effect only in e2, a volatile object, a volatile read in the address computation (not counted), a sizeof operand); the bit-field rejection cb-05 is unchanged on both)"
