#!/usr/bin/env bash
# check_printf_refusals.sh — row-1 witnesses for the formatter's declared refusals and fixes
# (upstream-tray reports 26, 16, 68, 69, 70; charter lean_frontend/docs/2026-11-07_worker-charter-printf-refusals.md;
# record lean_frontend/docs/2026-11-07_printf-refusals-record.md; contract D16).
#
# Upstream's formatter (frontend/model/formatted.lem, pristine c3ff8c53f) parsed only %f of the floating
# conversions and no L modifier, so a conforming printf("%e", 3.5) was reported as Invalid_format undefined
# behaviour (a silently wrong verdict); a `*` field width or precision, %n, %ls and %lc died with uncaught
# internal errors on conforming calls; %jd of an intmax_t (and %zd/%td of the corresponding types) was a false
# UB153b, the exact-type test comparing the argument's normalised type with the bare macro-type constructor;
# snprintf returned the truncated length (and 0 without formatting at n = 0) where C17 7.21.6.5#3 requires the
# would-be length, and crashed on a format whose conversion reports UB; the `0` flag padded in front of the
# sign (`%05d` of -5 was `000-5`) and `#` dropped %f's decimal point. Since 2026-11-07 the SHARED formatter
# parses the full 7.21.6.1#7-#8 syntax and REFUSES the unimplemented conversions with one attributed text per
# class (the floating conversions other than %f/%lf, %n, %ls/%lc, a `*` argument without a constant value),
# reads a `*` width/precision from an int argument (7.21.6.1#5), tests the j/z/t modifiers through the alias
# table on both sides, returns snprintf's would-be length, pads after the sign/base and keeps the point —
# both engines by generation (the Core builtin's model; the libc C text is untouched).
#
# Witnesses: tests/printf_refusals/*.c in libc mode (the library's own printf → vfprintf → the builtin; the
# path every linked program takes since contract D15), each pinned in tests/printf_refusals/expected.txt as
# `<name> TAB <class> TAB <pin>`:
#   VALUE    both engines' --batch line must equal the pin byte for byte, with equal exit codes (0): gcc 13's
#            line (tests/printf_refusals/gcc.txt, derived 2026-11-07 with `gcc -std=c11 -w -O0`, the streams
#            captured separately, OCaml String.escaped) — or, for the rows of FORK_PINNED below, the fork's own
#            declared line with gcc's beside it in gcc.txt (implementation-defined %p text, upstream's
#            padded `%5%` under its own TODO and its space flag on an unsigned conversion: filed, not changed);
#   UB       both engines report the pinned `Undefined {ub: "<id>", …}` line (exit 1) — compared with the
#            `loc` field removed: in libc mode the oracle locates a format UB inside the library's vfprintf and
#            the Lean engine at `<unknown location>` (named deviation N4, VALIDATION.md 2b; the LOC_ONLY rule of
#            tests/libc_exec) — the verdict, the UB id and every other field must agree; gcc's line is beside it
#            in gcc.txt (gcc prints something: the strict 7.21.6.1#9 reading is upstream's, tray 27);
#   REFUSAL  the oracle must die with `internal error: <text>` and the uncaught `Failure("internal error:
#            <text>")` (exit 125), the Lean engine must abort (exit 134) with a `PANIC … LemLib…: <text>` line, and
#            the two texts must be byte-identical to the pin (the WHOLE text, the conversion named in it); `%*%`, a %%
#            specification carrying a * width (UB, 7.21.6.1#8), is such a row (the pre-merge review's P2-1);
#   GAP      the oracle answers the pinned line; the Lean engine refuses (`%f` of a NaN, CONTRACT §3: the
#            float-format REFUSAL envelope) — a gap control, not an agreement.
#   nolibc_* rows run under --nolibc on BOTH engines (std.core's printf proxy, the other path to the same
#            formatter), with the same class rules (the symbol-number projection of row 6b is not needed: the
#            rows pin Defined lines or refusal texts).
# Negative control: tests/printf_refusals/pristine.txt carries pristine c3ff8c53f's lines (its crashes as
# `CRASH:<first stderr line>`); the `pristine-pair` plant must FAIL exactly the moved rows. A VALUE pin that is
# neither gcc's line nor declared FORK_PINNED is a FAIL (a silent re-pin cannot pass). The total and the class
# counts are pinned. gcc.txt and pristine.txt are read ONCE into associative arrays (expected.txt is streamed once);
# a gcc line longer than 4096 bytes — a UB program padding by an indeterminate `*` width (`star_missing_width`,
# 725,285,413 bytes; `star_width_uninit`, 32,841 bytes) — is stored CAPPED (`GCC-CAPPED[payload <bytes> bytes,
# sha256 <hex>, first 96 bytes]: <prefix>`): such a row is a UB or REFUSAL row, never a VALUE pin, and the capped
# form can equal no engine line (the 2026-11-07 pre-merge review: the uncapped line was a 691.7 MiB blob scanned
# per row). Fail-closed.
#
# Usage: check_printf_refusals.sh             the witnesses
#        check_printf_refusals.sh --selftest  plants (on the PLANT subset, then the real run):
#            (a) `pristine-pair`: both engines replay pristine's lines (its crashes as upstream's texts)
#            (b) `lean-pristine`: the real oracle, the Lean engine replays pristine's lines
#            (c) `lean-fixed`: the Lean engine answers one fixed Defined line on every input
#            (d) `oracle-rc`: the real oracle's output with its exit code forced to 1
#            (e) `expect-tamper`: one pinned VALUE line and one REFUSAL text altered by a character
#            (f) `lean-other-text`: the Lean engine aborts with another text on every input
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
# Run from the project root whatever the caller's cwd (the libc metadata TUs are exported under the relative
# runtime `_build/install/default`; the Lean driver resolves those labels from ITS cwd — check_stdio_exit.sh).
cd "$ROOT" || { echo "check_printf_refusals: FAIL — cannot cd to $ROOT"; exit 1; }
REAL_BIN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$REAL_BIN}"
REAL_ORACLE="$ROOT/_build/default/backend/driver/main.exe"
ORACLE="${CERB_ORACLE_BIN_OVERRIDE:-$REAL_ORACLE}"
PREFIX="$ROOT/_build/install/default"
CASES="$ROOT/tests/printf_refusals"
EXPECT="${CERB_PR_EXPECT_OVERRIDE:-$CASES/expected.txt}"
GCC_LINES="$CASES/gcc.txt"
PRISTINE="$CASES/pristine.txt"
ONLY="${CERB_PR_ONLY:-}"
NAME=check_printf_refusals
LEAN_PANIC_RE='^PANIC at _private\.LemLib\.0\.failwithIImpl LemLib:[0-9]+:[0-9]+: '
GAP_LEAN_TEXT='"REFUSAL","float-format","%f"'
# the declared fork-pinned VALUE rows (their pins differ from gcc's line; each program's header comment states the reason)
FORK_PINNED="p_null percent_width space_u"
# the plant subset: moved rows of each class, unmoved rows, the gap control, a nolibc control
PLANT_VALUE_MOVED="star_width sn_trunc jd_intmax flags_zero"
PLANT_VALUE_SAME="d_int s_prec"
PLANT_UB_MOVED="sn_ub_insufficient hs_strict"
PLANT_UB_SAME="x_int_tray27"
PLANT_REFUSAL="e_double n_int"
PLANT_GAP="f_nan"
PLANT_NOLIBC="nolibc_star_width nolibc_e_double"
PLANT_SET="$PLANT_VALUE_MOVED $PLANT_VALUE_SAME $PLANT_UB_MOVED $PLANT_UB_SAME $PLANT_REFUSAL $PLANT_GAP $PLANT_NOLIBC"

pinned() { awk -F'\t' -v n="$1" '$1==n{print substr($0, length(n)+2)}' "$2"; }   # the rest of the line after the name (the selftest's small files)
declare -A GCC PRIS   # gcc.txt / pristine.txt, read once: name -> the rest of the line
load_table() {  # <file> <array-name>
    local f="$1" a="$2" name rest
    [[ -f "$f" ]] || return 0
    while IFS=$'\t' read -r name rest; do
        [[ -n "$name" && "$name" != \#* ]] || continue
        printf -v "$a[$name]" '%s' "$rest"
    done < "$f"
}

if [[ "${1:-}" == --selftest ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    [[ -f "$PRISTINE" ]] || { echo "$NAME: FAIL — $PRISTINE missing"; exit 1; }
    export PLANT_PRISTINE="$PRISTINE"
    # the replay stubs: a pristine `Defined/Undefined` line is printed with exit 0/1; a pristine `CRASH:<line>`
    # entry is replayed as upstream's crash (the oracle stub: the `internal error:` line and the Failure on
    # stderr, exit 125; the Lean stub: the PANIC line on stderr, exit 134). The oracle stub delegates every
    # invocation that is not an --exec run (the --cabs-json export, libc_prep.sh's dumps) to the real oracle.
    cat > "$ST/oracle-pristine" <<EOS
#!/usr/bin/env bash
if [[ " \$* " != *" --exec "* ]]; then exec "$REAL_ORACLE" "\$@"; fi
last="\${@: -1}"; b=\$(basename "\${last%.c}")
line=\$(awk -F'\t' -v n="\$b" '\$1==n{print substr(\$0, length(n)+2)}' "\$PLANT_PRISTINE")
[[ -n "\$line" ]] || { echo "stub: no pristine line for \$b" >&2; exit 99; }
if [[ "\$line" == CRASH:* ]]; then t="\${line#CRASH:}"; t="\${t#internal error: }"; printf 'internal error: %s\ncerberus: internal error, uncaught exception:\n          Failure("internal error: %s")\n' "\$t" "\$t" >&2; exit 125; fi
printf '%s\n' "\$line"; [[ "\$line" == Defined* ]] && exit 0; exit 1
EOS
    cat > "$ST/lean-pristine" <<EOS
#!/usr/bin/env bash
last="\${@: -1}"; b=\$(basename "\${last%.json}"); b=\${b%.c}
line=\$(awk -F'\t' -v n="\$b" '\$1==n{print substr(\$0, length(n)+2)}' "\$PLANT_PRISTINE")
[[ -n "\$line" ]] || { echo "stub: no pristine line for \$b" >&2; exit 99; }
if [[ "\$line" == CRASH:* ]]; then t="\${line#CRASH:}"; t="\${t#internal error: }"; printf 'PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: %s\n' "\$t" >&2; exit 134; fi
printf '%s\n' "\$line"; [[ "\$line" == Defined* ]] && exit 0; exit 1
EOS
    printf '#!/usr/bin/env bash\necho %q\nexit 0\n' 'Defined {value: "Specified(0)", stdout: "[5][-7]\n", stderr: "", blocked: "false"}' > "$ST/lean-fixed"
    printf '#!/usr/bin/env bash\nif [[ " $* " != *" --exec "* ]]; then exec "%s" "$@"; fi\n"%s" "$@"\nexit 1\n' "$REAL_ORACLE" "$REAL_ORACLE" > "$ST/oracle-rc"
    printf '#!/usr/bin/env bash\necho "PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: Formatted.convert: refused - another text" >&2\nexit 134\n' > "$ST/lean-other-text"
    chmod +x "$ST"/oracle-pristine "$ST"/lean-pristine "$ST"/lean-fixed "$ST"/oracle-rc "$ST"/lean-other-text
    awk -F'\t' -v OFS='\t' '$1=="star_width"{sub(/\[   9\]/, "[  9]", $0)} $1=="e_double"{sub(/the %e conversion/, "the %E conversion", $0)} {print}' "$EXPECT" > "$ST/expected-tampered.txt"
    cmp -s "$ST/expected-tampered.txt" "$EXPECT" && { echo "$NAME: SELFTEST FAIL — the tamper plant did not alter the expectation"; exit 1; }
    [[ $(diff "$EXPECT" "$ST/expected-tampered.txt" | grep -c '^>') -eq 2 ]] || { echo "$NAME: SELFTEST FAIL — the tamper plant did not alter exactly two rows"; exit 1; }
    run_plant() {  # <label> <oracle> <lean> <expect-file> <expected failure count> [required failing program]...
        local label="$1" o="$2" l="$3" e="$4" want="$5" got req; shift 5
        if CERB_ORACLE_BIN_OVERRIDE="$o" CERB_LEAN_BIN_OVERRIDE="$l" CERB_PR_EXPECT_OVERRIDE="$e" \
           CERB_PR_ONLY="$PLANT_SET" "$SELF" > "$ST/$label.out" 2>&1; then
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
    # Expected counts, derived on the plant subset (15 programs: 4 moved VALUE + 2 same VALUE + 2 moved UB + 1 same
    # UB + 2 REFUSAL + 1 GAP + 2 nolibc (one VALUE, one REFUSAL)). Checks per VALUE/UB row: C1 oracle rc + line =
    # pin, C2 Lean line = pin, C3 Lean rc = oracle rc; per REFUSAL row: R1 oracle rc 125 + text, R2 Lean rc 134 +
    # text, R3 the two texts equal; the GAP row: G1 oracle rc 0 + line = pin, G2 Lean rc 134 + the envelope.
    # The replay stubs print a pristine Defined/Undefined line with exit 0/1 and replay a pristine crash as
    # upstream's crash (exit 125 / 134 with the old text).
    #  pristine-pair:   moved VALUE: star_width (pristine crashed: C1 + C2 + C3, 125 vs 134) = 3, sn_trunc (pristine's
    #                   wrong value: C1 + C2) = 2, jd_intmax (pristine's UB line: C1 + C2) = 2, flags_zero (wrong
    #                   value: C1 + C2) = 2; 2 moved UB (pristine crashed: C1 + C2 + C3) = 6; e_double (pristine's
    #                   UB line: R1 + R2 + R3, both texts empty) = 3, n_int (the old text on both: R1 + R2) = 2;
    #                   GAP: G2 (the stub prints the oracle's line, no refusal) = 1; nolibc_star_width (pristine
    #                   crashed: 3); nolibc_e_double (pristine's UB line: 3); the same rows pass
    #                   (9 + 6 + 5 + 1 + 6; a first derivation mis-added this to 24 and the plant caught it)    = 27
    #  lean-pristine:   star_width C2 + C3 = 2, sn_trunc C2 = 1, jd_intmax C2 + C3 = 2, flags_zero C2 = 1; 2 moved UB:
    #                   C2 + C3 = 4; e_double R2 + R3 = 2, n_int R2 + R3 = 2; GAP: G2 = 1; nolibc_star_width: C2 + C3
    #                   = 2; nolibc_e_double: R2 + R3 = 2                                                          = 19
    #  lean-fixed:      6 VALUE rows: C2 fails on 5 (d_int's pin IS the fixed line) = 5; 3 UB rows: C2 + C3 = 6;
    #                   2 REFUSAL: R2 + R3 = 4; GAP: G2 = 1; nolibc_star_width: C2 = 1; nolibc_e_double: R2 + R3 = 2 = 19
    #  oracle-rc:       6 VALUE rows x (C1 rc 1 + C3 0 != 1) = 12; 3 UB rows pass (rc 1 is their rc); 2 REFUSAL:
    #                   R1 (rc 1, not 125) = 2; GAP: G1 = 1; nolibc_star_width: C1 + C3 = 2; nolibc_e_double: R1 = 1 = 18
    #  expect-tamper:   star_width: the pin classification (neither gcc's line nor declared) + C1 + C2 = 3;
    #                   e_double: R1 + R2 = 2 (R3 passes: the engines agree with each other)                      = 5
    #  lean-other-text: 6 VALUE: C2 + C3 = 12; 3 UB: C2 + C3 = 6; 2 REFUSAL: R2 (text) + R3 (differ) = 4; GAP: G2 = 1;
    #                   nolibc_star_width: C2 + C3 = 2; nolibc_e_double: R2 + R3 = 2                                = 27
    run_plant pristine-pair "$ST/oracle-pristine" "$ST/lean-pristine" "$EXPECT" 27 star_width sn_trunc jd_intmax flags_zero sn_ub_insufficient hs_strict e_double n_int f_nan nolibc_star_width nolibc_e_double
    run_plant lean-pristine "$REAL_ORACLE" "$ST/lean-pristine" "$EXPECT" 19 star_width jd_intmax e_double f_nan nolibc_e_double
    run_plant lean-fixed "$REAL_ORACLE" "$ST/lean-fixed" "$EXPECT" 19 s_prec x_int_tray27 e_double f_nan nolibc_star_width
    run_plant oracle-rc "$ST/oracle-rc" "$REAL_BIN" "$EXPECT" 18 d_int e_double f_nan nolibc_star_width
    run_plant expect-tamper "$REAL_ORACLE" "$REAL_BIN" "$ST/expected-tampered.txt" 5 star_width e_double
    run_plant lean-other-text "$REAL_ORACLE" "$ST/lean-other-text" "$EXPECT" 27 d_int x_int_tray27 e_double n_int f_nan nolibc_e_double
    "$SELF"; exit $?
fi

[[ -x "$BIN" ]] || { echo "$NAME: FAIL — driver not built: $BIN"; exit 1; }
[[ -x "$ORACLE" ]] || { echo "$NAME: FAIL — oracle not built: $ORACLE"; exit 1; }
[[ -f "$PREFIX/lib/cerberus-lib/runtime/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged under $PREFIX"; exit 1; }
[[ -f "$PREFIX/lib/cerberus/runtime/libc/libc.co" ]] || { echo "$NAME: FAIL — the libc object is not staged under $PREFIX (dune build cerberus.install)"; exit 1; }
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

load_table "$GCC_LINES" GCC; load_table "$PRISTINE" PRIS
fails=0; n=0; nmoved=0; nvalue=0; ngcc=0; nfork=0; nub=0; nrefusal=0; ngap=0; nnolibc=0
# the total and the class counts are PINNED: a dropped row cannot pass silently
WANT_N=161; WANT_VALUE=104; WANT_GCC=101; WANT_FORK=3; WANT_UB=38; WANT_REFUSAL=18; WANT_GAP=1; WANT_NOLIBC=4
fail() { echo "$NAME: FAIL — $*"; fails=$((fails + 1)); }
verdict_line() { grep -aE '^(Defined|Undefined|Error|Killed) ' | head -1; }
strip_loc() { sed -E 's/, loc: "[^"]*"//'; }
selected() { [[ -z "$ONLY" ]] || [[ " $ONLY " == *" $1 "* ]]; }
declared_fork_pinned() { [[ " $FORK_PINNED " == *" $1 "* ]]; }
mode_args() { [[ "$1" == nolibc_* ]] && echo "--nolibc"; }
lean_libc_args() { [[ "$1" == nolibc_* ]] || printf '%s\n' "${LIBC_ARGS[@]}"; }

classify_value_pin() {  # <name> <pin>: the pin must be gcc's line or the row must be declared fork-pinned; counts
    local name="$1" want="$2" g; g="${GCC[$name]-}"
    if [[ "$want" == "$g" ]]; then
        declared_fork_pinned "$name" && fail "$name: declared FORK-PINNED but its pin equals gcc's line (retire the declaration)"
        ngcc=$((ngcc + 1))
    else
        declared_fork_pinned "$name" || fail "$name: pinned to a line that is not gcc's (gcc.txt) and not declared FORK-PINNED"
        nfork=$((nfork + 1))
    fi
}
export_json() {  # <name>: the Cabs JSON for the Lean engine (the mode's flag for the cpp invocation)
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json"
    if ! "$ORACLE" --runtime="$PREFIX" $(mode_args "$name") --cabs-json "$c" > "$j" 2> "$j.err" || [[ ! -s "$j" ]]; then
        fail "$name: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return 1
    fi
}
run_oracle() {  # <name>: stdout to $WD/<name>.oout, stderr to .oerr; echoes rc
    local name="$1" c="$CASES/$1.c"
    "$ORACLE" --runtime="$PREFIX" $(mode_args "$name") --exec --batch "$c" > "$WD/$name.oout" 2> "$WD/$name.oerr"; echo $?
}
run_lean() {  # <name>: stdout to $WD/<name>.lout, stderr to .lerr; echoes rc
    local name="$1" j="$WD/$1.json"; local -a largs; mapfile -t largs < <(lean_libc_args "$name")
    env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --first --runtime="$PREFIX" "${largs[@]}" "$j" > "$WD/$name.lout" 2> "$WD/$name.lerr"; echo $?
}
witness_line() {  # <name> <class VALUE|UB> <pin>: both engines' lines = the pin (UB: loc projected); exit codes agree
    local name="$1" class="$2" want="$3" wrc orc lrc o l
    if [[ "$class" == VALUE ]]; then wrc=0; classify_value_pin "$name" "$want"; nvalue=$((nvalue + 1)); else wrc=1; nub=$((nub + 1)); fi
    orc=$(run_oracle "$name"); o=$(verdict_line < "$WD/$name.oout")
    [[ "$class" == UB ]] && o=$(printf '%s\n' "$o" | strip_loc)
    [[ $orc -eq $wrc && "$o" == "$want" ]] || fail "$name: oracle: expected rc $wrc [${want:0:200}]; got rc=$orc [${o:0:200}] $(head -c 200 "$WD/$name.oerr")"
    export_json "$name" || return
    lrc=$(run_lean "$name"); l=$(verdict_line < "$WD/$name.lout")
    [[ "$class" == UB ]] && l=$(printf '%s\n' "$l" | strip_loc)
    [[ "$l" == "$want" ]] || fail "$name: Lean: expected [${want:0:200}]; got rc=$lrc [${l:0:200}] $(head -c 200 "$WD/$name.lerr")"
    [[ $lrc -eq $orc ]] || fail "$name: exit codes differ: oracle $orc, Lean $lrc"
}
witness_refusal() {  # <name> <text>: the oracle dies with the text (125), the Lean engine aborts with it (134), the texts equal
    local name="$1" want="$2" orc lrc ot lt
    nrefusal=$((nrefusal + 1))
    orc=$(run_oracle "$name")
    ot=$(sed -e 's/\x1b\[[0-9;]*m//g' "$WD/$name.oerr" | grep -a -m1 '^internal error: ' | sed 's/^internal error: //')
    if [[ $orc -ne 125 || "$ot" != "$want" ]]; then
        fail "$name: oracle: expected rc 125 with [internal error: ${want:0:120}…]; got rc=$orc [${ot:0:160}] $(verdict_line < "$WD/$name.oout" | cut -c1-120)"
    elif ! grep -aqF "Failure(\"internal error: $want\")" "$WD/$name.oerr"; then
        fail "$name: oracle: the uncaught Failure does not carry the text"
    fi
    export_json "$name" || return
    lrc=$(run_lean "$name")
    lt=$(grep -aE -m1 "$LEAN_PANIC_RE" "$WD/$name.lerr" | sed -E "s/$LEAN_PANIC_RE//")
    [[ $lrc -eq 134 && "$lt" == "$want" ]] || fail "$name: Lean: expected rc 134 with the PANIC text [${want:0:120}…]; got rc=$lrc [${lt:0:160}] $(verdict_line < "$WD/$name.lout" | cut -c1-120)"
    [[ -n "$ot" && -n "$lt" && "$ot" == "$lt" ]] || fail "$name: the two engines' texts differ"
}
witness_gap() {  # <name> <pin>: the oracle answers the pinned line; the Lean engine refuses with the float-format envelope
    local name="$1" want="$2" orc lrc o
    ngap=$((ngap + 1))
    orc=$(run_oracle "$name"); o=$(verdict_line < "$WD/$name.oout")
    [[ $orc -eq 0 && "$o" == "$want" ]] || fail "$name: oracle: expected rc 0 [$want]; got rc=$orc [${o:0:200}]"
    export_json "$name" || return
    lrc=$(run_lean "$name")
    [[ $lrc -eq 134 ]] && grep -aqF "$GAP_LEAN_TEXT" "$WD/$name.lerr" || fail "$name: Lean: expected the float-format refusal (rc 134, $GAP_LEAN_TEXT); got rc=$lrc $(head -c 300 "$WD/$name.lerr")"
}

while IFS=$'\t' read -r name class pin; do
    [[ -n "$name" && "$name" != \#* ]] || continue
    selected "$name" || continue
    [[ -f "$CASES/$name.c" ]] || { fail "$name: program missing: $CASES/$name.c"; continue; }
    [[ -n "$pin" ]] || { fail "$name: no pinned expectation in $EXPECT"; continue; }
    n=$((n + 1)); [[ "$name" == nolibc_* ]] && nnolibc=$((nnolibc + 1))
    if [[ -f "$PRISTINE" && "${PRIS[$name]-}" != "$pin" ]]; then nmoved=$((nmoved + 1)); fi
    case "$class" in
        VALUE|UB) witness_line "$name" "$class" "$pin" ;;
        REFUSAL)  witness_refusal "$name" "$pin" ;;
        GAP)      witness_gap "$name" "$pin" ;;
        *)        fail "$name: unknown class '$class' in $EXPECT" ;;
    esac
done < "$EXPECT"
for name in $FORK_PINNED; do grep -q "^$name	" "$EXPECT" || fail "$name: declared FORK-PINNED but absent from $EXPECT"; done
if [[ -z "$ONLY" ]]; then  # the whole set: the pinned totals (a subset run is a plant or a focused check, not the gate)
    [[ $n -eq $WANT_N && $nvalue -eq $WANT_VALUE && $ngcc -eq $WANT_GCC && $nfork -eq $WANT_FORK && $nub -eq $WANT_UB && $nrefusal -eq $WANT_REFUSAL && $ngap -eq $WANT_GAP && $nnolibc -eq $WANT_NOLIBC ]] \
        || fail "the witness set is not the pinned set: $n programs ($nvalue VALUE = $ngcc gcc-pinned + $nfork fork-pinned, $nub UB, $nrefusal REFUSAL, $ngap GAP; $nnolibc of them nolibc); expected $WANT_N ($WANT_VALUE = $WANT_GCC + $WANT_FORK, $WANT_UB, $WANT_REFUSAL, $WANT_GAP; $WANT_NOLIBC)"
fi

[[ $fails -eq 0 ]] || { echo "$NAME: $fails failing check(s) over $n programs"; exit 1; }
echo "$NAME: OK ($n programs, libc mode but for the $nnolibc nolibc controls: $nvalue VALUE rows with both engines' batch lines equal to the pin and exit codes equal — $ngcc gcc 13's line (the * field width and precision in every form incl. negative, zero, with flags and modifiers, in printf/fprintf/sprintf/snprintf/vprintf; %jd/%ju/%zd/%zu/%td/%tu with the macro types and their corresponding types; snprintf's would-be length on truncation, at n = 0 with a null buffer, at n = 1, at the exact fit and in the sizing idiom; the 0 flag after the sign and the 0x base, the # decimal point of %f, infinities space-padded; every integer, character, string and %f conversion with its flags, widths, precisions and length modifiers as controls) and $nfork the fork's declared lines with gcc's beside them (implementation-defined %p text, upstream's padded %5% under its own TODO, its space flag on an unsigned conversion); $nub UB rows with the pinned verdict on both engines, the location projected (a snprintf format's UB passed through instead of the crash, a non-l modifier with %s as UB158, the strict 7.21.6.1#9 readings of tray 27 kept, the malformed formats as Invalid_format); $nrefusal REFUSAL rows with the oracle's internal error and the Lean engine's PANIC carrying the identical pinned text (every floating conversion other than %f/%lf, the L modifier, %n, %ls, %lc, an unspecified * argument, a %% specification with a * width, in printf and snprintf); $ngap gap control (%f of a NaN refused on the Lean engine); $nmoved rows moved from pristine c3ff8c53f's lines)"
