#!/usr/bin/env bash
# check_asm_refusal.sh — row-1 witnesses for the inline-assembly refusal
# (2026-10-05; [USER 2026-10-05] "Re inline asm, this should be a loud
# refusal"; record lean_frontend/docs/2026-10-05_asm-refusal-record.md).
#
# Upstream Cerberus erases inline assembly: an asm STATEMENT (basic, extended,
# `asm goto`) desugars to a skip (frontend/model/cabs_to_ail.lem, upstream
# "TODO: erasing inline assembly for now"), and an asm LABEL on a declarator
# (`int x asm("sym");`) is dropped by the parser before Cabs exists
# (parsers/c/c_parser.mly asm_register). A program whose meaning lives in its
# asm silently ran as if the asm were absent (real-C census §4.5: both fork
# engines answered Specified(1) where gcc gives 5). Both are now refused:
#   - the statement forms in the SHARED .lem desugarer, so the OCaml oracle and
#     the Lean engine (generated from the same .lem) fail identically:
#     Desugar_NotYetSupported "inline assembly (asm statement) is unsupported";
#     oracle exit 1 with `feature not yet supported: inline assembly (asm
#     statement) is unsupported`; Lean --batch exit 1 with `Error {msg:
#     "desugaring failed at <asm location>"}` and, without --batch, the cause
#     line `cause: DESUGAR NotYetSupported: inline assembly (asm statement) is
#     unsupported`;
#   - the declarator label in the SHARED parser, the only place it exists:
#     `unimplemented keyword 'asm (inline assembly label on a declarator is
#     unsupported)'`, exit 1, for --exec AND for --cabs-json (no Cabs JSON is
#     produced, so the Lean engine, whose only input is that JSON, cannot run it).
# Controls: an asm-free program and a program that merely mentions asm in a
# string and a comment must agree between the oracle and Lean (the refusal is
# not lexical and does not refuse everything). Fail-closed.
#
# Usage: check_asm_refusal.sh             the witnesses
#        check_asm_refusal.sh --selftest  plants: the witnesses must FAIL against
#            (a) `erase`: the pre-fix behaviour of BOTH engines — an oracle stub
#                that strips every asm form from the C file and runs the real
#                oracle on it (so the real Lean engine runs the erased Cabs);
#            (b) `lean-erase`: the real oracle, a Lean stub that answers as if the
#                asm were absent (Defined, Specified(1)) — the Lean side is checked;
#            (c) `refuse-all`: both engines refuse every input with the asm
#                message; then the real run.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$ROOT/lean_frontend/.lake/build/bin/cerberus-lean}"
REAL_ORACLE="$ROOT/_build/default/backend/driver/main.exe"
ORACLE="${CERB_ORACLE_BIN_OVERRIDE:-$REAL_ORACLE}"
PREFIX="$ROOT/_build/install/default"
NAME=check_asm_refusal
STMT_MSG='inline assembly (asm statement) is unsupported'
LABEL_MSG="unimplemented keyword 'asm (inline assembly label on a declarator is unsupported)'"

if [[ "${1:-}" == "--selftest" ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    # (a) erase: strip asm labels (string-only parenthesis before = ; or ,) and
    # asm statements (up to their ;), then run the REAL oracle on the result;
    # the ctl*.c controls pass through unstripped (the strip is lexical and would
    # mangle the control that mentions asm in a comment and a string)
    cat > "$ST/oracle-erase" <<EOF
#!/usr/bin/env bash
args=(); d=\$(mktemp -d "$ST/erase.XXXXXX")
for a in "\$@"; do
    if [[ "\$a" == *.c && -f "\$a" && "\$(basename "\$a")" != ctl* ]]; then
        sed -E -e 's/\\b(asm|__asm__)[[:space:]]*\\("[^"]*"\\)[[:space:]]*([=;,])/\\2/g' \\
               -e 's/\\b(asm|__asm__)\\b[^;]*;/;/g' "\$a" > "\$d/\$(basename "\$a")"
        args+=("\$d/\$(basename "\$a")")
    else args+=("\$a"); fi
done
exec "$REAL_ORACLE" "\${args[@]}"
EOF
    # (b) lean-erase: Lean answers as if the asm were not there
    printf '#!/usr/bin/env bash\necho "Defined {value: \\"Specified(1)\\", stdout: \\"\\", stderr: \\"\\", blocked: \\"false\\"}"\nexit 0\n' > "$ST/lean-erase"
    # (c) refuse-all, in the right words, on both sides
    printf '#!/usr/bin/env bash\necho "x.c:1:1: error: feature not yet supported: %s" >&2\necho "x.c:1:1: error: %s" >&2\nexit 1\n' "$STMT_MSG" "$LABEL_MSG" > "$ST/oracle-refuse-all"
    printf '#!/usr/bin/env bash\necho "Error {msg: \\"desugaring failed at x.c:1:1\\"}"\necho "    cause: DESUGAR NotYetSupported: %s"\nexit 1\n' "$STMT_MSG" > "$ST/lean-refuse-all"
    chmod +x "$ST"/oracle-erase "$ST"/lean-erase "$ST"/oracle-refuse-all "$ST"/lean-refuse-all
    run_plant() {  # <label> <oracle> <lean>
        if CERB_ORACLE_BIN_OVERRIDE="$2" CERB_LEAN_BIN_OVERRIDE="$3" "$0" > "$ST/$1.out" 2>&1; then
            echo "$NAME: SELFTEST FAIL — plant '$1' PASSED the witnesses (vacuous check)"
            cat "$ST/$1.out"
            exit 1
        fi
        echo "$NAME: selftest plant '$1' caught: $(grep -c 'FAIL —' "$ST/$1.out") failing witness(es)"
    }
    run_plant erase "$ST/oracle-erase" "$BIN"
    run_plant lean-erase "$REAL_ORACLE" "$ST/lean-erase"
    run_plant refuse-all "$ST/oracle-refuse-all" "$ST/lean-refuse-all"
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
lean_batch() {  # <json> -> LOUT, LRC
    LOUT=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$PREFIX" "$1" 2>&1); LRC=$?
}
lean_verbose() {  # <json> -> VOUT
    VOUT=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --runtime="$PREFIX" "$1" 2>&1)
}
cabs_ok() {  # <c-file> <json>: the export must succeed (statement forms parse)
    "$ORACLE" --runtime="$PREFIX" --cabs-json "$1" > "$2" 2> "$2.err" && [[ -s "$2" ]]
}

stmt_witness() {  # <label> <c-file> <line:col of the asm statement>
    local label="$1" c="$2" pos="$3" j="$W/s$n.json"
    n=$((n + 1))
    oracle_exec "$c"
    if [[ $ORC -ne 1 || "$OOUT" != *"$c:$pos: error: feature not yet supported: $STMT_MSG"* ]]; then
        fail "$label: oracle: expected exit 1 + '$c:$pos: error: feature not yet supported: $STMT_MSG'; got rc=$ORC: ${OOUT:0:300}"
    fi
    if ! cabs_ok "$c" "$j"; then
        fail "$label: oracle --cabs-json failed (the statement forms must parse): $(head -c 300 "$j.err")"; return
    fi
    lean_batch "$j"
    if [[ $LRC -ne 1 || "$LOUT" != "Error {msg: \"desugaring failed at $c:$pos"* ]]; then
        fail "$label: Lean --batch: expected exit 1 + 'Error {msg: \"desugaring failed at $c:$pos…'; got rc=$LRC: ${LOUT:0:300}"
    fi
    lean_verbose "$j"
    if [[ "$VOUT" != *"at: $c:$pos"* || "$VOUT" != *"cause: DESUGAR NotYetSupported: $STMT_MSG"* ]]; then
        fail "$label: Lean: expected the attributed cause 'DESUGAR NotYetSupported: $STMT_MSG' at $c:$pos; got: ${VOUT: -300}"
    fi
}
label_witness() {  # <label> <c-file> <line:col where the parser reports>
    local label="$1" c="$2" pos="$3" j="$W/l$n.json" out rc
    n=$((n + 1))
    oracle_exec "$c"
    if [[ $ORC -ne 1 || "$OOUT" != *"$c:$pos: error: $LABEL_MSG"* ]]; then
        fail "$label: oracle --exec: expected exit 1 + '$c:$pos: error: $LABEL_MSG'; got rc=$ORC: ${OOUT:0:300}"
    fi
    "$ORACLE" --runtime="$PREFIX" --cabs-json "$c" > "$j" 2> "$j.err"; rc=$?
    out=$(cat "$j.err")
    if [[ $rc -ne 1 || -s "$j" || "$out" != *"$c:$pos: error: $LABEL_MSG"* ]]; then
        fail "$label: oracle --cabs-json: expected exit 1, no JSON, + '$LABEL_MSG' (no Cabs reaches the Lean engine); got rc=$rc, json $(wc -c < "$j") bytes: ${out:0:300}"
    fi
}
control() {  # <label> <c-file> <expected oracle verdict line>
    local label="$1" c="$2" want="$3" j="$W/c$n.json" o
    n=$((n + 1))
    o=$("$ORACLE" --runtime="$PREFIX" --exec --batch --nolibc "$c" 2>/dev/null | grep -aE '^(Defined|Undefined|Error) ' | head -1)
    [[ "$o" == "$want" ]] || { fail "$label: oracle: expected [$want]; got [$o]"; return; }
    cabs_ok "$c" "$j" || { fail "$label: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return; }
    lean_batch "$j"
    [[ $LRC -eq 0 && "$LOUT" == "$o" ]] || fail "$label: expected Lean = oracle [$o]; got rc=$LRC: ${LOUT:0:300}"
}

# the census §4.5 witness shape (gcc: 5; pre-fix both engines: Specified(1))
printf 'int main(void) {\n  int x = 1;\n  __asm__ __volatile__ ("addl $4, %%0" : "+r"(x));\n  return x;\n}\n' > ext.c
printf 'int main(void) {\n  int x = 1;\n  asm("nop");\n  return x;\n}\n' > basic.c
printf 'int main(void) {\n  asm goto ("jmp %%l0" : : : : out);\n  return 1;\nout:\n  return 0;\n}\n' > goto.c
printf 'static void never(void) {\n  asm volatile ("" : : : "memory");\n}\nint main(void) { return 0; }\n' > uncalled.c
printf 'int y asm("y_sym") = 3;\nint main(void) { return y; }\n' > lab_obj.c
printf 'int f(void) __asm__("g_sym");\nint main(void) { return 0; }\n' > lab_fun.c
printf 'int main(void) { register int r asm("eax") = 2; return r; }\n' > lab_reg.c
printf 'int main(void) {\n  int x = 1;\n  x += 4;\n  return x;\n}\n' > ctl.c
printf '/* asm("nop"); */\nint main(void) {\n  const char *s = "asm(\\"nop\\")";\n  return s[0] == 0x61 ? 5 : 0;\n}\n' > ctl_text.c

stmt_witness "extended asm statement (__asm__ __volatile__, output operand; census §4.5)" ext.c 3:3
stmt_witness "basic asm statement" basic.c 3:3
stmt_witness "asm goto (extended form with labels)" goto.c 2:3
stmt_witness "asm statement in a never-called function (refusal is not reachability-dependent)" uncalled.c 2:3
label_witness "asm label on a file-scope object declarator" lab_obj.c 1:20
label_witness "__asm__ label on a function declarator" lab_fun.c 1:29
label_witness "asm register label on a block-scope declarator" lab_reg.c 1:44
control "asm-free control" ctl.c 'Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}'
control "asm only in a comment and a string" ctl_text.c 'Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}'

[[ $fails -eq 0 ]] || { echo "$NAME: $fails witness failure(s) over $n cases"; exit 1; }
echo "$NAME: OK ($n cases: 4 asm statements (basic, extended, asm goto, uncalled function) refused by the oracle and the Lean engine with the attributed desugar message; 3 declarator asm labels (object, function, register) refused by the shared parser for --exec and --cabs-json; 2 controls agree with the oracle)"
