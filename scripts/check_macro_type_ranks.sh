#!/usr/bin/env bash
# check_macro_type_ranks.sh — row-1 witnesses for the macro integer types' conversion rank
# (upstream-tray report 20; cerberus-caesium filing 05; [USER 2026-11-04] approved the fork fix
# of an upstream mistake, a fork-ahead delta of the first kind; record
# lean_frontend/docs/2026-11-04_macro-type-ranks-record.md).
#
# Upstream's AilTypesAux.lt_integer_rank / eq_integer_rank (frontend/model/ail/ailTypesAux.lem;
# pristine c3ff8c53f :457-543) compare the BARE integerType constructors, so a macro-typed operand
# (Size_t, Ptrdiff_t, Wchar_t, the Intptr_t/Intmax_t families, an Enum) matches no rank arm and the
# ISO table's catch-all answers `false` under its own `TODO: this is probably wrong for macro types`.
# In the Core translation's usual arithmetic conversions (translation.lem usual_arithmetic_conversion_aux)
# the pair (size_t, int) then fails every rank bullet and reaches the last resort, which converts
# both operands to unsigned int: size_t arithmetic and comparisons against the int family computed
# at 32 bits (`(size_t)1 << 32 == 0` was 1; `n + 1` for n = 5000000000 was 705032705), the same for
# ptrdiff_t (`i + n` truncated, `n + i` not), wchar_t (`w + l` truncated a long), enum operands
# (`e + ul` truncated an unsigned long), compound assignments with a macro-typed left operand, `%`,
# `|`, `^`, `?:`, and the comparisons that made control flow diverge from every conforming compiler.
# Since 2026-11-04 the SHARED rank functions normalise both operands through the implementation's
# alias table outside CHERI (C17 6.3.1.1#1: a typedef has the rank of its type; 7.19#2: size_t is an
# unsigned integer type — here Unsigned Long; Ptrdiff_t Signed Long; Wchar_t Signed Int_; Intptr_t/
# Intmax_t Long; the IntN_t families by width; an Enum its compatible type, 6.7.2.2#4), the table
# carries the two `long long` rows, and the catch-all is a loud `error` — both engines by generation.
#
# Witnesses: tests/macro_type_ranks/*.c, each pinned to gcc 13's line in tests/macro_type_ranks/expected.txt
# (`Defined {value: "Specified(<rc>)", stdout: "<gcc stdout>", stderr: "", blocked: "false"}`, derived
# 2026-11-04 with `gcc -std=c11 -w -O0`; every program UB-free by construction). The oracle's batch line
# and the Lean engine's batch line must BOTH equal the pinned line byte for byte (so Lean = oracle
# follows), and the two exit codes must agree. The set: one DENSE program per (macro type, value
# variant) exercising every standard partner type and both enums in both operand orders through
# `+ - * / % & | ^ == != < <= > >= << >>`, the conditional operator and every `op=` in both directions; two macro-versus-macro matrices (the seven header-reachable macro types pairwise, both orders,
# a big and a small operand per type, positive and negative; intptr_t against the signed macro types only: F4 is pinned apart)
# (size_t, ptrdiff_t, wchar_t, intptr_t, uintptr_t, intmax_t, uintmax_t, an enum with and without a
# negative enumerator; positive values at 2^32+5 or 2^31-safe, a negative partner, a negative macro
# operand), the integer-promotion probes (`+x -x ~x`, shifts, sizeof), the direct `__cerbty_*` spellings
# (the IntN_t / Int_leastN_t / Int_fastN_t families, unreachable through the shipped <stdint.h>, which
# defines FIXED_STDINT), tray 20's reproducer tests/noodle-probes/int/int_size_t_uac_rank.c, the
# consumer's three programs, the true-bug audit's 30 Set A probes (2026-11-04) and the four siblings
# measured before the fix. Controls: the survey's cluster K probes (compatibility and _Generic, which
# must keep their answers). Negative control: tests/macro_type_ranks/pristine.txt carries pristine
# c3ff8c53f's lines (the pre-fix answers, also the fork's before the change) — the `pristine-pair` plant
# must FAIL exactly the programs that moved. Gap control: a negative value stored into a wchar_t object
# still crashes both engines (`bytes_of_int(signed)`; upstream-tray report 62, the queued refusal; NOT
# this mechanism). Declared residual: `size_t`/`intptr_t` against `long long` are TYPED by upstream's
# NON-STD `usual_arithmetic_integer` arms as size_t / intptr_t where gcc says unsigned long long — the
# values agree; one control pins the fork's typing codes (the record names it).
# Fail-closed.
#
# Usage: check_macro_type_ranks.sh             the witnesses
#        check_macro_type_ranks.sh --selftest  plants (on the PLANT subset, then the real run):
#            (a) `pristine-pair`: both engines replay pristine's pre-fix lines
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
CASES="$ROOT/tests/macro_type_ranks"
EXPECT="${CERB_MTR_EXPECT_OVERRIDE:-$CASES/expected.txt}"
PRISTINE="$CASES/pristine.txt"
ONLY="${CERB_MTR_ONLY:-}"
NAME=check_macro_type_ranks
GAP_TEXT='bytes_of_int(signed), i= 4294967295, nbits= 32'
GAP_LEAN_SITE='CerbMem.intToBytes'

# the plant subset: PLANT_MOVED (lines differ between pristine.txt and expected.txt) + PLANT_SAME (equal) + the gap control
PLANT_MOVED="dense_size_t_pos dense_ptrdiff_t_pos dense_wchar_t_pos dense_enumU_pos tray20_int_size_t_uac_rank consumer_w24"
PLANT_SAME="st-03-generic st-09-rank-long-longlong"
PLANT_UB="gap_intptr_t_unsigned_false_ub036"
PLANT_GAP="gap_wchar_t_negative_store"

if [[ "${1:-}" == --selftest ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    [[ -f "$PRISTINE" ]] || { echo "$NAME: FAIL — $PRISTINE missing"; exit 1; }
    export PLANT_PRISTINE="$PRISTINE"
    # replay stubs: the pinned pristine line for the program named by the last argument (.c or .json);
    # the oracle stub delegates --cabs-json to the real oracle so the Lean side is exercised
    cat > "$ST/oracle-pristine" <<EOS
#!/usr/bin/env bash
if [[ " \$* " == *" --cabs-json "* ]]; then exec "$REAL_ORACLE" "\$@"; fi
last="\${@: -1}"; b=\$(basename "\${last%.c}")
line=\$(awk -F'\t' -v n="\$b" '\$1==n{print substr(\$0, length(n)+2)}' "\$PLANT_PRISTINE")
[[ -n "\$line" ]] || { echo "stub: no pristine line for \$b" >&2; exit 99; }
printf '%s\n' "\$line"; exit 0
EOS
    cat > "$ST/lean-pristine" <<EOS
#!/usr/bin/env bash
last="\${@: -1}"; b=\$(basename "\${last%.json}"); b=\${b%.c}
line=\$(awk -F'\t' -v n="\$b" '\$1==n{print substr(\$0, length(n)+2)}' "\$PLANT_PRISTINE")
[[ -n "\$line" ]] || { echo "stub: no pristine line for \$b" >&2; exit 99; }
printf '%s\n' "\$line"; exit 0
EOS
    printf '#!/usr/bin/env bash\necho %q\nexit 0\n' 'Defined {value: "Specified(0)", stdout: "705032705\n", stderr: "", blocked: "false"}' > "$ST/lean-fixed"
    # (d) oracle-rc: the real oracle's output, its exit code forced to 1 on the execution runs only (the
    # --cabs-json export is delegated untouched, as the refusal scripts' stubs do)
    printf '#!/usr/bin/env bash\nif [[ " $* " == *" --cabs-json "* ]]; then exec "%s" "$@"; fi\n"%s" "$@"\nexit 1\n' "$REAL_ORACLE" "$REAL_ORACLE" > "$ST/oracle-rc"
    chmod +x "$ST"/oracle-pristine "$ST"/lean-pristine "$ST"/lean-fixed "$ST"/oracle-rc
    # (e) the expectation side: dense_size_t_pos's line with its first digit run altered
    awk -F'\t' -v OFS='\t' '$1=="dense_size_t_pos"{sub(/stdout: "[0-9]+/, "stdout: \"1", $0)} {print}' "$EXPECT" > "$ST/expected-tampered.txt"
    cmp -s "$ST/expected-tampered.txt" "$EXPECT" && { echo "$NAME: SELFTEST FAIL — the tamper plant did not alter the expectation"; exit 1; }
    run_plant() {  # <label> <oracle> <lean> <expect-file> <expected failure count> [required failing program]...
        local label="$1" o="$2" l="$3" e="$4" want="$5" got req; shift 5
        if CERB_ORACLE_BIN_OVERRIDE="$o" CERB_LEAN_BIN_OVERRIDE="$l" CERB_MTR_EXPECT_OVERRIDE="$e" \
           CERB_MTR_ONLY="$PLANT_MOVED $PLANT_SAME $PLANT_UB $PLANT_GAP" "$0" > "$ST/$label.out" 2>&1; then
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
    # Expected counts, derived on the plant subset (6 moved + 2 same Defined rows, 1 UB control, 1 gap control = 10
    # programs). Checks: a Defined row has C1 oracle rc 0 + line = pin, C2 Lean line = pin, C3 Lean rc = oracle rc;
    # the UB control has C1 oracle rc 1 + line = pin, C2 Lean rc 1 + line = pin; the gap control has C1 oracle
    # rc 125 + text, C2 Lean rc 134 + site + text. The replay stubs answer with rc 0; a program without a pristine
    # line makes a stub exit 99 with no verdict line.
    #  pristine-pair: 6 moved x (C1 + C2) = 12; the 2 same pass; UB control: both stubs rc 0 -> C1 + C2 = 2;
    #                 gap: no pristine line, stubs exit 99 -> C1 + C2 = 2                                   = 16
    #  lean-pristine: 6 moved x C2 = 6; UB control: Lean stub rc 0 -> C2 = 1; gap: Lean stub exit 99 -> C2  = 8
    #  lean-fixed:    8 Defined rows x C2 = 8; UB control C2 = 1; gap C2 = 1                                 = 10
    #  oracle-rc:     8 Defined rows x (C1 rc 1 + C3 0 != 1) = 16; UB control passes (rc 1 is its pin); gap C1 = 1 = 17
    #  expect-tamper: dense_size_t_pos: C1 + C2                                                              = 2
    run_plant pristine-pair "$ST/oracle-pristine" "$ST/lean-pristine" "$EXPECT" 16 dense_size_t_pos dense_ptrdiff_t_pos dense_wchar_t_pos dense_enumU_pos tray20_int_size_t_uac_rank consumer_w24 gap_intptr_t_unsigned_false_ub036
    run_plant lean-pristine "$REAL_ORACLE" "$ST/lean-pristine" "$EXPECT" 8 dense_size_t_pos consumer_w24
    run_plant lean-fixed "$REAL_ORACLE" "$ST/lean-fixed" "$EXPECT" 10 dense_size_t_pos st-03-generic gap_intptr_t_unsigned_false_ub036 gap_wchar_t_negative_store
    run_plant oracle-rc "$ST/oracle-rc" "$REAL_BIN" "$EXPECT" 17 dense_size_t_pos st-09-rank-long-longlong gap_wchar_t_negative_store
    run_plant expect-tamper "$REAL_ORACLE" "$REAL_BIN" "$ST/expected-tampered.txt" 2 dense_size_t_pos
    "$0"; exit $?
fi

[[ -x "$BIN" ]] || { echo "$NAME: FAIL — driver not built: $BIN"; exit 1; }
[[ -x "$ORACLE" ]] || { echo "$NAME: FAIL — oracle not built: $ORACLE"; exit 1; }
[[ -f "$PREFIX/lib/cerberus-lib/runtime/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged under $PREFIX"; exit 1; }
[[ -d "$CASES" && -f "$EXPECT" ]] || { echo "$NAME: FAIL — witness programs or expectations missing ($CASES, $EXPECT)"; exit 1; }
mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
WD=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
trap 'rm -rf "$WD"' EXIT
export NO_COLOR=1 TERM=dumb

fails=0; n=0; nmoved=0
fail() { echo "$NAME: FAIL — $*"; fails=$((fails + 1)); }
pinned() { awk -F'\t' -v n="$1" '$1==n{print substr($0, length(n)+2)}' "$2"; }
verdict_line() { grep -aE '^(Defined|Undefined|Error|Killed) ' | head -1; }
selected() { [[ -z "$ONLY" ]] || [[ " $ONLY " == *" $1 "* ]]; }

witness() {  # <name>: both engines' batch lines = the pinned gcc line; exit codes agree
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want oout orc o lout lrc l
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT")
    [[ -n "$want" ]] || { fail "$name: no pinned expectation in $EXPECT"; return; }
    [[ -f "$c" ]] || { fail "$name: program missing: $c"; return; }
    n=$((n + 1))
    if [[ -f "$PRISTINE" && "$(pinned "$name" "$PRISTINE")" != "$want" ]]; then nmoved=$((nmoved + 1)); fi
    oout=$("$ORACLE" --runtime="$PREFIX" --exec --batch --nolibc "$c" 2> "$j.oerr"); orc=$?
    o=$(printf '%s\n' "$oout" | verdict_line)
    [[ $orc -eq 0 && "$o" == "$want" ]] || fail "$name: oracle: expected rc 0 [${want:0:200}]; got rc=$orc [${o:0:200}] $(head -c 200 "$j.oerr")"
    if ! "$ORACLE" --runtime="$PREFIX" --cabs-json "$c" > "$j" 2> "$j.err" || [[ ! -s "$j" ]]; then
        fail "$name: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$PREFIX" "$j" 2> "$j.lerr"); lrc=$?
    l=$(printf '%s\n' "$lout" | verdict_line)
    [[ "$l" == "$want" ]] || fail "$name: Lean: expected [${want:0:200}]; got rc=$lrc [${l:0:200}] $(head -c 200 "$j.lerr")"
    [[ $lrc -eq $orc ]] || fail "$name: exit codes differ: oracle $orc, Lean $lrc"
}
gap_control() {  # <name>: both engines still crash at the wchar_t store (tray 62), unchanged
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" oout orc lout lrc
    selected "$name" || return
    n=$((n + 1))
    oout=$("$ORACLE" --runtime="$PREFIX" --exec --batch --nolibc "$c" 2>&1); orc=$?
    [[ $orc -eq 125 && "$oout" == *"$GAP_TEXT"* ]] || fail "$name: oracle: expected the pre-existing crash (rc 125, '$GAP_TEXT'; tray 62); got rc=$orc ${oout:0:300}"
    if ! "$ORACLE" --runtime="$PREFIX" --cabs-json "$c" > "$j" 2> "$j.err" || [[ ! -s "$j" ]]; then
        fail "$name: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$PREFIX" "$j" 2>&1); lrc=$?
    [[ $lrc -eq 134 && "$lout" == *"$GAP_LEAN_SITE"* && "$lout" == *"$GAP_TEXT"* ]] || fail "$name: Lean: expected the mirrored stop (rc 134, '$GAP_LEAN_SITE', '$GAP_TEXT'); got rc=$lrc ${lout:0:300}"
}

ub_control() {  # <name>: a pinned UNDEFINED line on both engines (exit 1 on both), unchanged by the fix (declared, filed)
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want oout orc o lout lrc l
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT")
    [[ -n "$want" ]] || { fail "$name: no pinned expectation in $EXPECT"; return; }
    n=$((n + 1))
    oout=$("$ORACLE" --runtime="$PREFIX" --exec --batch --nolibc "$c" 2> "$j.oerr"); orc=$?
    o=$(printf '%s\n' "$oout" | verdict_line)
    [[ $orc -eq 1 && "$o" == "$want" ]] || fail "$name: oracle: expected rc 1 [$want]; got rc=$orc [${o:0:300}]"
    if ! "$ORACLE" --runtime="$PREFIX" --cabs-json "$c" > "$j" 2> "$j.err" || [[ ! -s "$j" ]]; then
        fail "$name: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$PREFIX" "$j" 2> "$j.lerr"); lrc=$?
    l=$(printf '%s\n' "$lout" | verdict_line)
    [[ $lrc -eq 1 && "$l" == "$want" ]] || fail "$name: Lean: expected rc 1 [$want]; got rc=$lrc [${l:0:300}]"
}

while IFS=$'\t' read -r name _; do
    [[ -n "$name" && "$name" != \#* ]] || continue
    if [[ "$name" == "$PLANT_UB" ]]; then ub_control "$name"; else witness "$name"; fi
done < "$EXPECT"
gap_control "$PLANT_GAP"

[[ $fails -eq 0 ]] || { echo "$NAME: $fails failing check(s) over $n programs"; exit 1; }
echo "$NAME: OK ($n programs: $((n - 3)) batch lines of both engines = gcc 13's pinned line, exit codes equal — the dense per-type matrices (every standard partner and both enums, both operand orders, every operator and op=, positive and negative values) for size_t, ptrdiff_t, wchar_t, intptr_t, uintptr_t, intmax_t, uintmax_t and the two enums, the two macro-versus-macro matrices, the promotion probes, the direct __cerbty_* families, tray 20's reproducer, the consumer's three programs, the audit's Set A probes, the four measured siblings and the cluster K controls, $nmoved of them moved from pristine's pre-fix lines; 2 lines pinned to the fork's declared residuals (the intptr_t-against-unsigned false UB036 from the upstream NON-STD typing arm, filed; the size_t/intptr_t-against-long-long typing codes); 1 gap control: the negative wchar_t store still crashes both engines (tray 62, unchanged))"
