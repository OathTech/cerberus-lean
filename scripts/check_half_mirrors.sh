#!/usr/bin/env bash
# check_half_mirrors.sh — row-1 witnesses for the three oracle "half-mirrors" closed on the OCaml side
# (upstream-tray reports 10, 11 and 13; charter lean_frontend/docs/2026-11-07_worker-charter-half-mirrors-oracle.md;
# record lean_frontend/docs/2026-11-07_half-mirrors-oracle-record.md; contract D18).
#
# Until 2026-11-07 the Lean engine answered these three classes right under the ISO-fix register rows R1/R2/R3
# while the fork's own OCaml oracle still crashed or corrupted (pristine c3ff8c53f does so today): (10) the simple
# escape `\?` (C17 6.4.4.4#1, #4: the value of '?' = 63) had no arm in decode.ml's decoder, so '\?' and "\?" died on
# an uncaught Failure; (11) formatted.lem's store_chars_in_array round-trips every snprintf/sprintf-stored character
# through `decode_character_constant (escaped_char c)`, and decode.ml's escaped_char was OCaml's Char.escaped, whose
# DECIMAL \ddd the decoder read as OCTAL (127 stored as 87, 200 as 128) or refused (19, 199: a crash) — C17
# 7.21.6.1#8; (13) impl_mem.ml's memcmp converted the C-controlled size with Z.to_int before reading a byte, an
# uncaught Z.Overflow on memcmp(a, b, (size_t)-1) where the checked per-byte load's UB_CERB002a_out_of_bound_load
# belongs. Since 2026-11-07 the oracle carries the `\?` arm, an escaped_char mirroring CerbDecode.escaped_char arm
# for arm (every byte 0..255 round-trips), and a memcmp counting on Z; the three register rows are RETIRED.
#
# Witnesses: tests/half_mirrors/*.c, each pinned in tests/half_mirrors/expected.txt to ONE line that both engines'
# --batch output must equal byte for byte, with equal exit codes (so Lean = oracle follows). Classes by name:
#   - rt_*, memcmp_distinct_*, memmove_*, strncmp_*, strncpy_* (libc mode): the tray-11 reproducers, the whole byte
#     range through snprintf's %c and %s stores, a strcpy control, the memop/library size controls — pinned to gcc
#     13's line (tests/half_mirrors/gcc.txt: `Defined {value: "Specified(<$?>)", stdout: "<gcc stdout>", stderr:
#     "<gcc stderr>", blocked: "false"}`, derived 2026-11-07 with `gcc -std=c11 -w -O0`, the streams captured
#     separately; every such program UB-free by construction);
#   - ub_* (libc mode): the tray-13 reproducer and its size/pointer-shape neighbours, UB programs pinned to the
#     fork's own Undefined line (memops: both engines print the same line; gcc's exit status is beside it in
#     gcc.txt), exit 1 on both engines — the FORK-PINNED rows;
#   - nolibc_* (--nolibc on both engines): the tray-10 reproducers (the character constant, the string literal, every
#     simple escape printed, the L and u8 prefixes) and the octal/hexadecimal escape controls, pinned to gcc 13's
#     line; two constraint violations (6.4.4.4#9: '\400', '\x100') pin the wrapped value both engines and gcc -w
#     give (gcc -pedantic-errors rejects them: declared in their headers); nolibc_fork_* is FORK-PINNED: '\0123',
#     a multi-character constant (implementation-defined, 6.4.4.4#10; tray 63's class) both engines read as one
#     four-digit octal escape, gcc's line beside it;
#   - gap_*: both engines still CRASH identically, before and after — universal character names, a multi-character
#     constant, a raw non-ASCII byte (the decoder's catch-all: tray 63's crash-to-refusal item) and the negative
#     wchar_t store (tray 62); the oracle's uncaught Failure/assertion text and the Lean engine's mirrored
#     UPSTREAM_CRASH stop must both carry the pinned text.
# Negative control: tests/half_mirrors/pristine.txt carries pristine c3ff8c53f's lines (`CRASH <text>` where it
# printed no verdict); the `pristine-pair` plant must FAIL exactly the moved rows. A row whose pin equals neither
# gcc's line nor the declared fork-pinned list is a FAIL (a silent re-pin cannot pass). The total, the class counts
# and the moved count are pinned. Fail-closed.
#
# Usage: check_half_mirrors.sh             the witnesses
#        check_half_mirrors.sh --selftest  plants (on the PLANT subset, then the real run):
#            (a) `pristine-pair`: both engines replay pristine's lines
#            (b) `lean-pristine`: the real oracle, the Lean engine replays pristine's lines
#            (c) `lean-fixed`: the Lean engine answers one fixed line on every input
#            (d) `oracle-rc`: the real oracle's output with its exit code forced to 1
#            (e) `expect-tamper`: one pinned line altered by a digit (the expectation side)
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
# Run from the project root whatever the caller's cwd: the libc metadata TUs are exported under the canonical
# RELATIVE runtime `_build/install/default` and the Lean driver resolves those labels from ITS cwd (BUG-3).
cd "$ROOT" || { echo "check_half_mirrors: FAIL — cannot cd to $ROOT"; exit 1; }
REAL_BIN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$REAL_BIN}"
REAL_ORACLE="$ROOT/_build/default/backend/driver/main.exe"
ORACLE="${CERB_ORACLE_BIN_OVERRIDE:-$REAL_ORACLE}"
PREFIX="$ROOT/_build/install/default"
CASES="$ROOT/tests/half_mirrors"
EXPECT="${CERB_HM_EXPECT_OVERRIDE:-$CASES/expected.txt}"
GCC_LINES="$CASES/gcc.txt"
PRISTINE="$CASES/pristine.txt"
ONLY="${CERB_HM_ONLY:-}"
NAME=check_half_mirrors
# the declared fork-pinned rows (their pins are the fork's own lines; gcc's verdict is beside them in gcc.txt)
FORK_PINNED="ub_memcmp_hugesize ub_memcmp_distinct_half ub_memcmp_distinct_p32 ub_memcmp_same_max ub_memcmp_adjacent_max ub_memcmp_neg_int ub_memcmp_oob_8 ub_memcpy_distinct_max nolibc_fork_oct_char_0123"
# the plant subset: moved rows (one per class), unmoved rows (one per class), a gap control, the declared row
PLANT_MOVED="rt_snprintf_c_127 nolibc_esc_char_q ub_memcmp_hugesize"
PLANT_SAME="rt_strcpy_all nolibc_oct_str_1234_boundary ub_memcmp_oob_8"
PLANT_GAP="gap_ucn_char_u00e9"
PLANT_FORK="nolibc_fork_oct_char_0123"
WANT_N=41; WANT_GCC=27; WANT_FORK=9; WANT_GAP=5; WANT_MOVED=18

if [[ "${1:-}" == --selftest ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    [[ -f "$PRISTINE" ]] || { echo "$NAME: FAIL — $PRISTINE missing"; exit 1; }
    export PLANT_PRISTINE="$PRISTINE"
    # the oracle stubs delegate every invocation that is not an --exec run (the --cabs-json export and libc_prep.sh's
    # --pp=core / --cabs-json, which honour the override too) to the real oracle
    cat > "$ST/oracle-pristine" <<EOS
#!/usr/bin/env bash
if [[ " \$* " != *" --exec "* ]]; then exec "$REAL_ORACLE" "\$@"; fi
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
    printf '#!/usr/bin/env bash\necho %q\nexit 0\n' 'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}' > "$ST/lean-fixed"
    printf '#!/usr/bin/env bash\nif [[ " $* " != *" --exec "* ]]; then exec "%s" "$@"; fi\n"%s" "$@"\nexit 1\n' "$REAL_ORACLE" "$REAL_ORACLE" > "$ST/oracle-rc"
    chmod +x "$ST"/oracle-pristine "$ST"/lean-pristine "$ST"/lean-fixed "$ST"/oracle-rc
    awk -F'\t' -v OFS='\t' '$1=="rt_snprintf_c_127"{sub(/Specified\(127\)/, "Specified(128)", $0)} {print}' "$EXPECT" > "$ST/expected-tampered.txt"
    cmp -s "$ST/expected-tampered.txt" "$EXPECT" && { echo "$NAME: SELFTEST FAIL — the tamper plant did not alter the expectation"; exit 1; }
    run_plant() {  # <label> <oracle> <lean> <expect-file> <expected failure count> [required failing program]...
        local label="$1" o="$2" l="$3" e="$4" want="$5" got req; shift 5
        if CERB_ORACLE_BIN_OVERRIDE="$o" CERB_LEAN_BIN_OVERRIDE="$l" CERB_HM_EXPECT_OVERRIDE="$e" \
           CERB_HM_ONLY="$PLANT_MOVED $PLANT_SAME $PLANT_GAP $PLANT_FORK" "$SELF" > "$ST/$label.out" 2>&1; then
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
    # Expected counts, derived on the plant subset (3 moved: a libc witness, a nolibc row, a ub row; 3 unmoved of the
    # same classes; 1 gap control; 1 declared nolibc row = 8 programs). Checks: a libc witness has C1 oracle rc 0 +
    # line = pin, C2 Lean line = pin, C3 Lean rc = oracle rc; a ub row C1 oracle rc 1 + line = pin, C2 Lean rc 1 +
    # line = pin; a nolibc row C1 oracle rc = the pin's rc + line = pin, C2 Lean rc = the pin's rc + line = pin; the
    # gap control C1 oracle rc 125 + text, C2 Lean rc 134 + UPSTREAM_CRASH + text. The replay stubs answer rc 0 with
    # pristine's line (a `CRASH <text>` line is no verdict).
    #  pristine-pair: the 3 moved rows x (C1 + C2) = 6; the 2 unmoved Defined rows pass; ub_memcmp_oob_8: the stubs'
    #                 rc 0 against the pin's rc 1 -> C1 + C2 = 2; gap: rc 0 on both stubs -> C1 + C2 = 2; the declared
    #                 row passes (83 on pristine too)                                                           = 10
    #  lean-pristine: 3 moved x C2 = 3; ub_memcmp_oob_8 C2 (rc 0) = 1; gap C2 = 1                                = 5
    #  lean-fixed:    every row's C2 fails (no pin equals the fixed line; the ub/gap rows also on rc)             = 8
    #  oracle-rc:     rt_snprintf_c_127 C1 + C3 = 2; nolibc_esc_char_q C1 = 1; ub_memcmp_hugesize passes (rc 1 is
    #                 its pin); rt_strcpy_all C1 + C3 = 2; nolibc_oct_str_1234_boundary C1 = 1; ub_memcmp_oob_8
    #                 passes; gap C1 (rc 1, not 125) = 1; nolibc_fork_oct_char_0123 C1 = 1                        = 8
    #  expect-tamper: rt_snprintf_c_127: the pin classification (neither gcc's line nor declared) + C1 + C2       = 3
    run_plant pristine-pair "$ST/oracle-pristine" "$ST/lean-pristine" "$EXPECT" 10 rt_snprintf_c_127 nolibc_esc_char_q ub_memcmp_hugesize ub_memcmp_oob_8 gap_ucn_char_u00e9
    run_plant lean-pristine "$REAL_ORACLE" "$ST/lean-pristine" "$EXPECT" 5 rt_snprintf_c_127 nolibc_esc_char_q ub_memcmp_hugesize gap_ucn_char_u00e9
    run_plant lean-fixed "$REAL_ORACLE" "$ST/lean-fixed" "$EXPECT" 8 rt_snprintf_c_127 rt_strcpy_all nolibc_fork_oct_char_0123 gap_ucn_char_u00e9
    run_plant oracle-rc "$ST/oracle-rc" "$REAL_BIN" "$EXPECT" 8 rt_snprintf_c_127 nolibc_oct_str_1234_boundary gap_ucn_char_u00e9
    run_plant expect-tamper "$REAL_ORACLE" "$REAL_BIN" "$ST/expected-tampered.txt" 3 rt_snprintf_c_127
    "$SELF"; exit $?
fi

[[ -x "$BIN" ]] || { echo "$NAME: FAIL — driver not built: $BIN"; exit 1; }
[[ -x "$ORACLE" ]] || { echo "$NAME: FAIL — oracle not built: $ORACLE"; exit 1; }
[[ -f "$PREFIX/lib/cerberus-lib/runtime/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged under $PREFIX"; exit 1; }
[[ -d "$CASES" && -f "$EXPECT" && -f "$GCC_LINES" ]] || { echo "$NAME: FAIL — witness programs or expectations missing ($CASES, $EXPECT, $GCC_LINES)"; exit 1; }
mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
WD=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
trap 'rm -rf "$WD"' EXIT
export NO_COLOR=1 TERM=dumb
# the libc transport: the pinned Core text dump + the twelve metadata TUs (libc_prep.sh, fail-closed on pin drift)
libc_jsons=$("$ROOT/scripts/libc_prep.sh" --jsons "$WD/libcjson") || { echo "$NAME: FAIL — libc_prep.sh --jsons failed (pin drift or oracle missing)"; exit 1; }
mapfile -t LIBC_JSONS <<< "$libc_jsons"
[[ ${#LIBC_JSONS[@]} -eq 12 ]] || { echo "$NAME: FAIL — expected 12 libc metadata jsons, got ${#LIBC_JSONS[@]}"; exit 1; }
LIBC_ARGS=(--libc "$ROOT/tests/libc/libc.core"); for j in "${LIBC_JSONS[@]}"; do LIBC_ARGS+=(--libc-tu "$j"); done

fails=0; n=0; ngcc=0; nfork=0; ngap=0; nmoved=0
fail() { echo "$NAME: FAIL — $*"; fails=$((fails + 1)); }
pinned() { awk -F'\t' -v n="$1" '$1==n{print substr($0, length(n)+2)}' "$2"; }
verdict_line() { grep -aE '^(Defined|Undefined|Error|Killed) ' | head -1; }
selected() { [[ -z "$ONLY" ]] || [[ " $ONLY " == *" $1 "* ]]; }
classify() {  # <name> <pin>: the pin is gcc's line or the row is declared fork-pinned; counts the class and the move
    local name="$1" want="$2" g
    g=$(pinned "$name" "$GCC_LINES")
    if [[ " $FORK_PINNED " == *" $name "* ]]; then nfork=$((nfork + 1))
    elif [[ -n "$g" && "$want" == "$g" ]]; then ngcc=$((ngcc + 1))
    else fail "$name: the pin is neither gcc 13's line nor a declared fork-pinned row: [${want:0:160}] vs gcc [${g:0:160}]"; fi
    if [[ -f "$PRISTINE" && "$(pinned "$name" "$PRISTINE")" != "$want" ]]; then nmoved=$((nmoved + 1)); fi
}
export_json() {  # <name> <c> <json> [--nolibc]: the Cabs JSON for the Lean side
    local name="$1" c="$2" j="$3"; shift 3
    if ! "$ORACLE" --runtime="$PREFIX" "$@" --cabs-json "$c" > "$j" 2> "$j.err" || [[ ! -s "$j" ]]; then
        fail "$name: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return 1
    fi
}
witness() {  # <name>: libc mode; both engines' batch lines = the pinned line; exit codes agree
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want oout orc o lout lrc l
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT"); [[ -n "$want" ]] || { fail "$name: no pinned expectation in $EXPECT"; return; }
    [[ -f "$c" ]] || { fail "$name: program missing: $c"; return; }
    n=$((n + 1)); classify "$name" "$want"
    oout=$("$ORACLE" --runtime="$PREFIX" --exec --batch "$c" 2> "$j.oerr"); orc=$?
    o=$(printf '%s\n' "$oout" | verdict_line)
    [[ $orc -eq 0 && "$o" == "$want" ]] || fail "$name: oracle: expected rc 0 [${want:0:200}]; got rc=$orc [${o:0:200}] $(head -c 200 "$j.oerr")"
    export_json "$name" "$c" "$j" || return
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --first --runtime="$PREFIX" "${LIBC_ARGS[@]}" "$j" 2> "$j.lerr"); lrc=$?
    l=$(printf '%s\n' "$lout" | verdict_line)
    [[ "$l" == "$want" ]] || fail "$name: Lean: expected [${want:0:200}]; got rc=$lrc [${l:0:200}] $(head -c 200 "$j.lerr")"
    [[ $lrc -eq $orc ]] || fail "$name: exit codes differ: oracle $orc, Lean $lrc"
}
ub_row() {  # <name>: libc mode; a UB program pinned to the fork's Undefined line on both engines, exit 1 on both
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want oout orc o lout lrc l
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT"); [[ -n "$want" ]] || { fail "$name: no pinned expectation in $EXPECT"; return; }
    [[ -f "$c" ]] || { fail "$name: program missing: $c"; return; }
    n=$((n + 1)); classify "$name" "$want"
    oout=$("$ORACLE" --runtime="$PREFIX" --exec --batch "$c" 2> "$j.oerr"); orc=$?
    o=$(printf '%s\n' "$oout" | verdict_line)
    [[ $orc -eq 1 && "$o" == "$want" ]] || fail "$name: oracle: expected rc 1 [${want:0:200}]; got rc=$orc [${o:0:200}] $(head -c 200 "$j.oerr")"
    export_json "$name" "$c" "$j" || return
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --first --runtime="$PREFIX" "${LIBC_ARGS[@]}" "$j" 2> "$j.lerr"); lrc=$?
    l=$(printf '%s\n' "$lout" | verdict_line)
    [[ $lrc -eq 1 && "$l" == "$want" ]] || fail "$name: Lean: expected rc 1 [${want:0:200}]; got rc=$lrc [${l:0:200}] $(head -c 200 "$j.lerr")"
}
nolibc_row() {  # <name>: --nolibc on both engines; the lines = the pin; exit codes = the pin's (0 for Defined, 1 otherwise)
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want wrc oout orc o lout lrc l
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT"); [[ -n "$want" ]] || { fail "$name: no pinned expectation in $EXPECT"; return; }
    [[ -f "$c" ]] || { fail "$name: program missing: $c"; return; }
    n=$((n + 1)); classify "$name" "$want"
    if [[ "$want" == Defined* ]]; then wrc=0; else wrc=1; fi
    oout=$("$ORACLE" --runtime="$PREFIX" --nolibc --exec --batch "$c" 2> "$j.oerr"); orc=$?
    o=$(printf '%s\n' "$oout" | verdict_line)
    [[ $orc -eq $wrc && "$o" == "$want" ]] || fail "$name: oracle (--nolibc): expected rc $wrc [${want:0:200}]; got rc=$orc [${o:0:200}] $(head -c 200 "$j.oerr")"
    export_json "$name" "$c" "$j" --nolibc || return
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --first --runtime="$PREFIX" "$j" 2> "$j.lerr"); lrc=$?
    l=$(printf '%s\n' "$lout" | verdict_line)
    [[ $lrc -eq $wrc && "$l" == "$want" ]] || fail "$name: Lean (--nolibc): expected rc $wrc [${want:0:200}]; got rc=$lrc [${l:0:200}] $(head -c 200 "$j.lerr")"
}
gap_control() {  # <name>: --nolibc; both engines crash with the pinned text (`CRASH <text>`), unchanged by the fix
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want text oout orc lout lrc
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT"); [[ "$want" == "CRASH "* ]] || { fail "$name: a gap control needs a 'CRASH <text>' pin in $EXPECT; got [${want:0:120}]"; return; }
    text=${want#CRASH }
    [[ -f "$c" ]] || { fail "$name: program missing: $c"; return; }
    n=$((n + 1)); ngap=$((ngap + 1))
    if [[ -f "$PRISTINE" && "$(pinned "$name" "$PRISTINE")" != "$want" ]]; then nmoved=$((nmoved + 1)); fi
    oout=$("$ORACLE" --runtime="$PREFIX" --nolibc --exec --batch "$c" 2>&1); orc=$?
    [[ $orc -eq 125 && "$oout" == *"$text"* ]] || fail "$name: oracle: expected the pre-existing crash (rc 125, '${text:0:80}'); got rc=$orc ${oout:0:300}"
    export_json "$name" "$c" "$j" --nolibc || return
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --first --runtime="$PREFIX" "$j" 2>&1); lrc=$?
    [[ $lrc -eq 134 && "$lout" == *"UPSTREAM_CRASH"* && "$lout" == *"$text"* ]] || fail "$name: Lean: expected the mirrored stop (rc 134, UPSTREAM_CRASH, '${text:0:80}'); got rc=$lrc ${lout:0:300}"
}

while IFS=$'\t' read -r name _; do
    [[ -n "$name" && "$name" != \#* ]] || continue
    case "$name" in
        gap_*)    gap_control "$name" ;;
        ub_*)     ub_row "$name" ;;
        nolibc_*) nolibc_row "$name" ;;
        *)        witness "$name" ;;
    esac
done < "$EXPECT"
for name in $FORK_PINNED; do grep -q "^$name	" "$EXPECT" || fail "$name: declared FORK-PINNED but absent from $EXPECT"; done
if [[ -z "$ONLY" ]]; then  # the whole set: the pinned totals (a subset run is a plant or a focused check, not the gate)
    [[ $n -eq $WANT_N && $ngcc -eq $WANT_GCC && $nfork -eq $WANT_FORK && $ngap -eq $WANT_GAP && $nmoved -eq $WANT_MOVED ]] \
        || fail "the witness set is not the pinned set: $n programs ($ngcc gcc-pinned, $nfork fork-pinned, $ngap gap, $nmoved moved from pristine); expected $WANT_N ($WANT_GCC/$WANT_FORK/$WANT_GAP/$WANT_MOVED)"
fi

[[ $fails -eq 0 ]] || { echo "$NAME: $fails failing check(s) over $n programs"; exit 1; }
echo "$NAME: OK ($n programs: $ngcc batch lines of both engines = gcc 13's pinned line, exit codes equal — the tray-11 reproducers (%c of 127, 19, 200; %s of 0xC7; a mixed sprintf; a \"\\?\" literal through %s), every byte 0..255 through snprintf's %c and %s stores, a strcpy and a %c-of-0 control, the memop/library size controls, the tray-10 reproducers under --nolibc (the character constant, the string literal, every simple escape printed, the L and u8 prefixes) and the octal/hexadecimal escape controls incl. two declared constraint violations; $nfork pinned to the fork's declared lines (the tray-13 reproducer and its size/pointer-shape neighbours as UB_CERB002a on both engines, two UB controls, the four-digit octal multi-character constant of tray 63's class); $ngap gap controls (universal character names, a multi-character constant and a raw non-ASCII byte still crash both engines identically, tray 63; the negative wchar_t store, tray 62); $nmoved rows moved from pristine c3ff8c53f's lines)"
