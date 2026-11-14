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
# unsigned integer type — here Unsigned Long; Ptrdiff_t Signed Long; Intptr_t/Intmax_t Long; the IntN_t
# families by width; an Enum its compatible type, 6.7.2.2#4; NOT Wchar_t and Wint_t, see CORRECTION below), the table
# carries the two `long long` rows, and the catch-all is a loud `error` — both engines by generation.
#
# Witnesses: tests/macro_type_ranks/*.c, each pinned to gcc 13's line in tests/macro_type_ranks/expected.txt
# (`Defined {value: "Specified(<rc>)", stdout: "<gcc stdout>", stderr: "", blocked: "false"}`, derived
# 2026-11-04 with `gcc -std=c11 -w -O0`; every program UB-free by construction). The oracle's batch line
# and the Lean engine's batch line must BOTH equal the pinned line byte for byte (so Lean = oracle
# follows), and the two exit codes must agree. The set: one DENSE program per (macro type, value
# variant) exercising every standard partner type and both enums in both operand orders through
# `+ - * / % & | ^ == != < <= > >= << >>`, the conditional operator and every `op=` in both directions; two macro-versus-macro matrices (the six header-reachable macro types that carry their rank pairwise, both orders,
# a big and a small operand per type, positive and negative; intptr_t against the signed macro types only: F4 is pinned apart)
# (size_t, ptrdiff_t, intptr_t, uintptr_t, intmax_t, uintmax_t, an enum with and without a
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
#
# CORRECTION 2026-11-14 ([USER 2026-11-14] ruled wchar_t out of the rank normalisation; record
# lean_frontend/docs/2026-11-14_wchar-rank-record.md): `rank_operand` leaves Wchar_t -- and Wint_t, the same
# mechanism, measured by the worker and approved as an extension of the ruling [USER 2026-11-14] -- bare, and the table answers upstream's `false` for them, so every rank
# comparison with a wchar_t or wint_t operand is pristine's again, defects included. The alias table says signed int
# for both while the memory model gives wchar_t the unsigned range and wint_t [0, 2^31-1] (upstream's open
# inconsistency, tray 62); with int's rank `WCHAR_MAX > 0` answered 0 and `WINT_MIN > -1` answered 1 on both engines
# where pristine and gcc answer 1 and 0 (2026-11-04 to 2026-11-14). The KEPT rows (tests/macro_type_ranks/kept.txt:
# <name> TAB gcc 13's line, beside) are pinned to PRISTINE's line: the script requires their pin to equal
# pristine.txt's line, and both engines to print it with the exit code its verdict implies (0 Defined, 1 Undefined).
# They are: the reproducer and its wint_t sibling, the WCHAR_*/WINT_* limit macros (compared with 0, promoted,
# converted, against int/unsigned/long/unsigned long, against every other limit macro), wchar_t objects against
# every standard partner, both enums, the other macro types and themselves, three Undefined rows upstream answers
# (one false, tray 62's), and the wchar_t programs of the 2026-11-04 set (re-pinned from gcc's line to pristine's).
# Negative control for the correction: tests/macro_type_ranks/d14.txt carries the fork's lines of 2026-11-04 to
# 2026-11-14 for the KEPT rows -- the `d14-pair` plant replays them on every KEPT row and must FAIL each. The other limit
# macros of the shipped <limits.h>/<stdint.h> and the direct __cerbvar_* spellings are gcc-pinned rows (limits_*).
# Fail-closed.
#
# Plants (--selftest; on the PLANT subset unless said otherwise, then the real run):
#            (a) `pristine-pair`: both engines replay pristine's pre-fix lines
#            (b) `lean-pristine`: the real oracle, the Lean engine replays pristine's lines
#            (c) `lean-fixed`: the Lean engine answers one fixed line on every input
#            (d) `oracle-rc`: the real oracle's output with its exit code forced to 1
#            (e) `expect-tamper`: one pinned line altered by a digit (the expectation side)
#            (f) `d14-pair`: both engines replay the fork's 2026-11-04..14 lines on EVERY KEPT row of the mode
#            (g) `kept-tamper`: one KEPT row's pin replaced by gcc's line (a KEPT row must carry pristine's)
#
# Two modes (the gate-cruft rule: row 1 is the per-commit tier; pre-merge review F5, ruled [AGENT 2026-11-14,
# orchestrator]; the printf witness's split is the precedent):
#   CORE (default; ladder row 1 via test_unit.sh): 114 programs -- the 2026-11-04 set (its five wchar_t rows KEPT,
#     its positive macro-versus-macro matrix split in two), the five hand-written KEPT programs (the reproducer
#     family) and one generated KEPT matrix per type (kept_limits_wchar, kept_limits_wint).
#   --full (Tier B: slice boundaries, close-out, pre-merge): all 126 -- the core plus the twelve programs of
#     FULL_ONLY: the six gcc-pinned limits_* programs (types the 2026-11-14 correction did not change) and the six
#     bulk KEPT matrices. The same programs, the same pin files (read once), no pin of its own.
# The fourteen generated programs (limits_*, kept_limits_*, kept_wchar_obj_*, kept_wchar_self) are the output of
# tests/macro_type_ranks/generate.py, committed beside them; `generate.py --check` re-measures and compares them
# byte for byte.
# Usage: check_macro_type_ranks.sh [--full]             the witnesses (core, or all)
#        check_macro_type_ranks.sh --selftest [--full]  the plants, then the real run of the mode
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
KEPT="$CASES/kept.txt"
D14="$CASES/d14.txt"
NAME=check_macro_type_ranks
MODE=core; SELFTEST=0
for arg in "$@"; do
    case "$arg" in
        --full) MODE=full ;;
        --selftest) SELFTEST=1 ;;
        *) echo "$NAME: usage: $0 [--selftest] [--full]"; exit 2 ;;
    esac
done
MODE_FLAG=(); [[ "$MODE" == full ]] && MODE_FLAG=(--full)
ONLY="${CERB_MTR_ONLY:-}"
# the programs that run in --full only (everything else is the row-1 core)
FULL_ONLY="limits_header_1 limits_header_2 limits_header_3 limits_header_4 limits_direct_1 limits_pairs_1 kept_limits_pairs_1 kept_limits_pairs_2 kept_wchar_obj_std_200000005 kept_wchar_obj_std_2147483647 kept_wchar_obj_macro kept_wchar_self"
in_mode() { [[ "$MODE" == full ]] || [[ " $FULL_ONLY " != *" $1 "* ]]; }
GAP_TEXT='bytes_of_int(signed), i= 4294967295, nbits= 32'
GAP_LEAN_SITE='CerbMem.intToBytes'

# the plant subset: PLANT_MOVED (lines differ between pristine.txt and expected.txt) + PLANT_SAME (equal) + the gap control
PLANT_MOVED="dense_size_t_pos dense_ptrdiff_t_pos audit_rank_size_t_compound dense_enumU_pos tray20_int_size_t_uac_rank consumer_w24"
PLANT_SAME="st-03-generic st-09-rank-long-longlong"
PLANT_UB="gap_intptr_t_unsigned_false_ub036"
PLANT_GAP="gap_wchar_t_negative_store"
# KEPT rows in the plant subset: two Defined (the reproducer and its wint_t sibling) and one Undefined
PLANT_KEPT="kept_wchar_max_gt_0 kept_wint_min_gt_m1 kept_ub_wchar_max_plus_1"

if [[ $SELFTEST -eq 1 ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    [[ -f "$PRISTINE" ]] || { echo "$NAME: FAIL — $PRISTINE missing"; exit 1; }
    [[ -f "$D14" && -f "$KEPT" ]] || { echo "$NAME: FAIL — $D14 or $KEPT missing"; exit 1; }
    export PLANT_PRISTINE="$PRISTINE" PLANT_D14="$D14"
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
    # (f) the D14 replay stubs: the fork's 2026-11-04..14 line for a program that has one in d14.txt (the KEPT
    # rows), exit 0; every other program is delegated to the real engine untouched. The plant runs on the KEPT rows
    # only and its Lean side is a stub too, so the Cabs export is answered with a placeholder, not by the real oracle
    cat > "$ST/oracle-d14" <<EOS
#!/usr/bin/env bash
if [[ " \$* " == *" --cabs-json "* ]]; then echo '{"d14-plant": "the Lean stub does not read this"}'; exit 0; fi
last="\${@: -1}"; b=\$(basename "\${last%.c}")
line=\$(awk -F'\t' -v n="\$b" '\$1==n{print substr(\$0, length(n)+2)}' "\$PLANT_D14")
[[ -n "\$line" ]] || exec "$REAL_ORACLE" "\$@"
printf '%s\n' "\$line"; exit 0
EOS
    cat > "$ST/lean-d14" <<EOS
#!/usr/bin/env bash
last="\${@: -1}"; b=\$(basename "\${last%.json}"); b=\${b%.c}
line=\$(awk -F'\t' -v n="\$b" '\$1==n{print substr(\$0, length(n)+2)}' "\$PLANT_D14")
[[ -n "\$line" ]] || exec "$REAL_BIN" "\$@"
printf '%s\n' "\$line"; exit 0
EOS
    # (d) oracle-rc: the real oracle's output, its exit code forced to 1 on the execution runs only (the
    # --cabs-json export is delegated untouched, as the refusal scripts' stubs do)
    printf '#!/usr/bin/env bash\nif [[ " $* " == *" --cabs-json "* ]]; then exec "%s" "$@"; fi\n"%s" "$@"\nexit 1\n' "$REAL_ORACLE" "$REAL_ORACLE" > "$ST/oracle-rc"
    chmod +x "$ST"/oracle-pristine "$ST"/lean-pristine "$ST"/lean-fixed "$ST"/oracle-rc "$ST"/oracle-d14 "$ST"/lean-d14
    # (f) reads EVERY KEPT row of the mode: each must have a D14 line that differs from its pin, or the plant is vacuous there
    KEPT_ROWS=""
    while IFS=$'\t' read -r k _; do
        [[ -n "$k" && "$k" != \#* ]] || continue
        in_mode "$k" || continue
        dl=$(awk -F'\t' -v n="$k" '$1==n{print substr($0, length(n)+2)}' "$D14"); el=$(awk -F'\t' -v n="$k" '$1==n{print substr($0, length(n)+2)}' "$EXPECT")
        [[ -n "$dl" && -n "$el" && "$dl" != "$el" ]] || { echo "$NAME: SELFTEST FAIL — KEPT row '$k' has no D14 line differing from its pin"; exit 1; }
        KEPT_ROWS="$KEPT_ROWS $k"
    done < "$KEPT"
    KEPT_ROWS="${KEPT_ROWS# }"; NKEPT_ROWS=$(wc -w <<<"$KEPT_ROWS")
    if [[ "$MODE" == full ]]; then WANT_KEPT_ROWS=19; else WANT_KEPT_ROWS=13; fi
    [[ $NKEPT_ROWS -eq $WANT_KEPT_ROWS ]] || { echo "$NAME: SELFTEST FAIL — $NKEPT_ROWS KEPT rows in the $MODE mode, expected $WANT_KEPT_ROWS"; exit 1; }
    # (g) the expectation side of a KEPT row: the reproducer's pin replaced by gcc's line (kept.txt) -- here gcc's
    # line and pristine's are the same text for the reproducer, so the WCHAR_* matrix is the row tampered
    gl=$(awk -F'\t' -v n="kept_limits_wchar" '$1==n{print substr($0, length(n)+2)}' "$KEPT")
    awk -F'\t' -v OFS='\t' -v g="$gl" '$1=="kept_limits_wchar"{print $1, g; next} {print}' "$EXPECT" > "$ST/expected-kept-tampered.txt"
    cmp -s "$ST/expected-kept-tampered.txt" "$EXPECT" && { echo "$NAME: SELFTEST FAIL — the KEPT tamper plant did not alter the expectation"; exit 1; }
    # (e) the expectation side: dense_size_t_pos's line with its first digit run altered
    awk -F'\t' -v OFS='\t' '$1=="dense_size_t_pos"{sub(/stdout: "[0-9]+/, "stdout: \"1", $0)} {print}' "$EXPECT" > "$ST/expected-tampered.txt"
    cmp -s "$ST/expected-tampered.txt" "$EXPECT" && { echo "$NAME: SELFTEST FAIL — the tamper plant did not alter the expectation"; exit 1; }
    PLANT_SUBSET="$PLANT_MOVED $PLANT_SAME $PLANT_UB $PLANT_GAP $PLANT_KEPT"
    run_plant() {  # <label> <oracle> <lean> <expect-file> <expected failure count> [required failing program]... (programs: $PLANT_ONLY, default the subset)
        local label="$1" o="$2" l="$3" e="$4" want="$5" got req; shift 5
        if CERB_ORACLE_BIN_OVERRIDE="$o" CERB_LEAN_BIN_OVERRIDE="$l" CERB_MTR_EXPECT_OVERRIDE="$e" \
           CERB_MTR_ONLY="${PLANT_ONLY:-$PLANT_SUBSET}" "$0" "${MODE_FLAG[@]}" > "$ST/$label.out" 2>&1; then
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
    # Expected counts, derived on the plant subset (6 moved + 2 same Defined rows, 1 UB control, 1 gap control, 3 KEPT
    # rows -- 2 Defined, 1 Undefined -- = 13 programs, all in the core). Checks: a Defined row has C1 oracle rc 0 +
    # line = pin, C2 Lean line = pin, C3 Lean rc = oracle rc; the UB control has C1 oracle rc 1 + line = pin, C2 Lean
    # rc 1 + line = pin; the gap control has C1 oracle rc 125 + text, C2 Lean rc 134 + site + text; a KEPT row has K0
    # pin = pristine.txt's line (a failure stops the row), then C1 oracle rc + line = pin, C2 Lean rc + line = pin, the
    # rc being 0 for a Defined pin and 1 for an Undefined one. The replay stubs answer with rc 0; a program without a
    # pristine line makes a pristine stub exit 99 with no verdict line.
    #  pristine-pair: 6 moved x (C1 + C2) = 12; the 2 same pass; UB control: both stubs rc 0 -> C1 + C2 = 2;
    #                 gap: no pristine line, stubs exit 99 -> C1 + C2 = 2; KEPT: the 2 Defined rows PASS (their pin
    #                 IS pristine's line: the plant shows it), the Undefined row: stubs rc 0 -> C1 + C2 = 2       = 18
    #  lean-pristine: 6 moved x C2 = 6; UB control C2 = 1; gap C2 = 1; KEPT Undefined row: Lean stub rc 0 -> C2 = 1  = 9
    #  lean-fixed:    8 Defined rows x C2 = 8; UB control C2 = 1; gap C2 = 1; 3 KEPT rows x C2 = 3                   = 13
    #  oracle-rc:     8 Defined rows x (C1 rc 1 + C3 0 != 1) = 16; UB control passes (rc 1 is its pin); gap C1 = 1;
    #                 2 Defined KEPT rows x C1 = 2; the Undefined KEPT row passes (rc 1 is its pin)                  = 19
    #  expect-tamper: run on the tampered row alone (no other row reads the altered line): C1 + C2                   = 2
    #  d14-pair:      run on EVERY KEPT row of the mode and on nothing else (13 in the core, 19 in --full): each row's
    #                 D14 line differs from its pin (checked above) and the stubs answer rc 0 -> C1 + C2 per row
    #                                                                                         = 26 (core) / 38 (--full)
    #  kept-tamper:   run on the tampered KEPT row alone: K0                                                         = 1
    # (`lean-d14`, a Lean-only D14 stub, was dropped on the pre-merge review's F6: on the same rows `lean-fixed` already
    # shows that a wrong Lean line on a KEPT row fails; `d14-pair` is the plant that feeds a wrong LINE with exit 0 to
    # the ORACLE side of a KEPT row.)
    run_plant pristine-pair "$ST/oracle-pristine" "$ST/lean-pristine" "$EXPECT" 18 dense_size_t_pos dense_ptrdiff_t_pos audit_rank_size_t_compound dense_enumU_pos tray20_int_size_t_uac_rank consumer_w24 gap_intptr_t_unsigned_false_ub036 kept_ub_wchar_max_plus_1
    for k in kept_wchar_max_gt_0 kept_wint_min_gt_m1; do
        grep -qF "FAIL — $k:" "$ST/pristine-pair.out" && { echo "$NAME: SELFTEST FAIL — plant 'pristine-pair' failed the Defined KEPT row '$k', whose pin is pristine's line"; exit 1; }
    done
    run_plant lean-pristine "$REAL_ORACLE" "$ST/lean-pristine" "$EXPECT" 9 dense_size_t_pos consumer_w24 kept_ub_wchar_max_plus_1
    run_plant lean-fixed "$REAL_ORACLE" "$ST/lean-fixed" "$EXPECT" 13 dense_size_t_pos st-03-generic gap_intptr_t_unsigned_false_ub036 gap_wchar_t_negative_store kept_wchar_max_gt_0 kept_wint_min_gt_m1 kept_ub_wchar_max_plus_1
    run_plant oracle-rc "$ST/oracle-rc" "$REAL_BIN" "$EXPECT" 19 dense_size_t_pos st-09-rank-long-longlong gap_wchar_t_negative_store kept_wchar_max_gt_0 kept_wint_min_gt_m1
    PLANT_ONLY="dense_size_t_pos" run_plant expect-tamper "$REAL_ORACLE" "$REAL_BIN" "$ST/expected-tampered.txt" 2 dense_size_t_pos
    # shellcheck disable=SC2086
    PLANT_ONLY="$KEPT_ROWS" run_plant d14-pair "$ST/oracle-d14" "$ST/lean-d14" "$EXPECT" $((2 * NKEPT_ROWS)) $KEPT_ROWS
    PLANT_ONLY="kept_limits_wchar" run_plant kept-tamper "$REAL_ORACLE" "$REAL_BIN" "$ST/expected-kept-tampered.txt" 1 kept_limits_wchar
    "$0" "${MODE_FLAG[@]}"; exit $?
fi

[[ -x "$BIN" ]] || { echo "$NAME: FAIL — driver not built: $BIN"; exit 1; }
[[ -x "$ORACLE" ]] || { echo "$NAME: FAIL — oracle not built: $ORACLE"; exit 1; }
[[ -f "$PREFIX/lib/cerberus-lib/runtime/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged under $PREFIX"; exit 1; }
[[ -d "$CASES" && -f "$EXPECT" && -f "$PRISTINE" && -f "$KEPT" ]] || { echo "$NAME: FAIL — witness programs, expectations, pristine lines or the KEPT register missing ($CASES, $EXPECT, $PRISTINE, $KEPT)"; exit 1; }
mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
WD=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
trap 'rm -rf "$WD"' EXIT
export NO_COLOR=1 TERM=dumb

fails=0; n=0; nmoved=0; ngcc=0; nkept=0; nkeptub=0; nkeptgcc=0; nresid=0; ngap=0
# the total and the class counts are PINNED: a dropped or reclassified row cannot pass silently (checked on a full run)
if [[ "$MODE" == full ]]; then WANT_N=126; WANT_GCC=104; WANT_KEPT=19; else WANT_N=114; WANT_GCC=98; WANT_KEPT=13; fi
WANT_RESID=2; WANT_GAP=1
RESIDUAL_FORK_PINNED="residual_size_t_llong_typing"
fail() { echo "$NAME: FAIL — $*"; fails=$((fails + 1)); }
pinned() { awk -F'\t' -v n="$1" '$1==n{print substr($0, length(n)+2)}' "$2"; }
verdict_line() { grep -aE '^(Defined|Undefined|Error|Killed) ' | head -1; }
selected() { if [[ -n "$ONLY" ]]; then [[ " $ONLY " == *" $1 "* ]]; else in_mode "$1"; fi; }
# every FULL_ONLY name must be a pinned program: a renamed or dropped one would silently join or leave the core
for f in $FULL_ONLY; do [[ -n "$(pinned "$f" "$EXPECT")" && -f "$CASES/$f.c" ]] || fail "$f: named in FULL_ONLY but not a pinned program"; done
is_kept() { awk -F'\t' -v n="$1" '$1==n{f=1} END{exit !f}' "$KEPT"; }

witness() {  # <name>: both engines' batch lines = the pinned gcc line; exit codes agree
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want oout orc o lout lrc l
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT")
    [[ -n "$want" ]] || { fail "$name: no pinned expectation in $EXPECT"; return; }
    [[ -f "$c" ]] || { fail "$name: program missing: $c"; return; }
    n=$((n + 1))
    if [[ "$name" == "$RESIDUAL_FORK_PINNED" ]]; then nresid=$((nresid + 1)); else ngcc=$((ngcc + 1)); fi
    if [[ "$(pinned "$name" "$PRISTINE")" != "$want" ]]; then nmoved=$((nmoved + 1)); fi
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
kept_row() {  # <name>: a KEPT row -- upstream's behaviour for wchar_t / wint_t: the pin must BE pristine's line, both engines print it
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want p g wantrc=0 oout orc o lout lrc l
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT"); p=$(pinned "$name" "$PRISTINE"); g=$(pinned "$name" "$KEPT")
    [[ -n "$want" ]] || { fail "$name: no pinned expectation in $EXPECT"; return; }
    [[ -f "$c" ]] || { fail "$name: program missing: $c"; return; }
    n=$((n + 1)); nkept=$((nkept + 1))
    [[ -n "$p" && "$want" == "$p" ]] || { fail "$name: declared KEPT (kept.txt) but its pin is not pristine's line (pristine.txt) [${want:0:120}] vs [${p:0:120}]"; return; }
    [[ -n "$g" ]] || { fail "$name: KEPT row without gcc's line beside it in $KEPT"; return; }
    if [[ "$want" == Undefined* ]]; then wantrc=1; nkeptub=$((nkeptub + 1)); fi
    if [[ "$g" == "$want" ]]; then nkeptgcc=$((nkeptgcc + 1)); fi
    oout=$("$ORACLE" --runtime="$PREFIX" --exec --batch --nolibc "$c" 2> "$j.oerr"); orc=$?
    o=$(printf '%s\n' "$oout" | verdict_line)
    [[ $orc -eq $wantrc && "$o" == "$want" ]] || fail "$name: oracle: expected rc $wantrc [${want:0:200}]; got rc=$orc [${o:0:200}] $(head -c 200 "$j.oerr")"
    if ! "$ORACLE" --runtime="$PREFIX" --cabs-json "$c" > "$j" 2> "$j.err" || [[ ! -s "$j" ]]; then
        fail "$name: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$PREFIX" "$j" 2> "$j.lerr"); lrc=$?
    l=$(printf '%s\n' "$lout" | verdict_line)
    [[ $lrc -eq $wantrc && "$l" == "$want" ]] || fail "$name: Lean: expected rc $wantrc [${want:0:200}]; got rc=$lrc [${l:0:200}] $(head -c 200 "$j.lerr")"
}
gap_control() {  # <name>: both engines still crash at the wchar_t store (tray 62), unchanged
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" oout orc lout lrc
    selected "$name" || return
    n=$((n + 1)); ngap=$((ngap + 1))
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
    n=$((n + 1)); nresid=$((nresid + 1))
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
    if [[ "$name" == "$PLANT_UB" ]]; then ub_control "$name"; elif is_kept "$name"; then kept_row "$name"; else witness "$name"; fi
done < "$EXPECT"
gap_control "$PLANT_GAP"
# every KEPT register row must be a pinned program (a register row without a pin would be a silent drop)
while IFS=$'\t' read -r name _; do
    [[ -n "$name" && "$name" != \#* ]] || continue
    [[ -n "$(pinned "$name" "$EXPECT")" ]] || fail "$name: in the KEPT register ($KEPT) but not pinned in $EXPECT"
done < "$KEPT"
if [[ -z "$ONLY" ]]; then
    [[ $n -eq $WANT_N && $ngcc -eq $WANT_GCC && $nkept -eq $WANT_KEPT && $nresid -eq $WANT_RESID && $ngap -eq $WANT_GAP ]] \
        || fail "the witness set is not the pinned set: $n programs ($ngcc gcc-pinned, $nkept KEPT, $nresid residual, $ngap gap); expected $WANT_N ($WANT_GCC/$WANT_KEPT/$WANT_RESID/$WANT_GAP)"
fi

[[ $fails -eq 0 ]] || { echo "$NAME: $fails failing check(s) over $n programs"; exit 1; }
if [[ -n "$ONLY" ]]; then MODE_TEXT="subset"; elif [[ "$MODE" == full ]]; then MODE_TEXT="--full, Tier B: every program"; else MODE_TEXT="core, row 1; the six limits_* programs and the six bulk KEPT matrices run in --full"; fi
echo "$NAME: OK ($MODE_TEXT: $n programs: $ngcc batch lines of both engines = gcc 13's pinned line, exit codes equal — the dense per-type matrices (every standard partner and both enums, both operand orders, every operator and op=, positive and negative values) for size_t, ptrdiff_t, intptr_t, uintptr_t, intmax_t, uintmax_t and the two enums, the two macro-versus-macro matrices, the promotion probes, the direct __cerbty_* families, the limit macros of the shipped headers other than WCHAR_*/WINT_* and the direct __cerbvar_* limit spellings, tray 20's reproducer, the consumer's three programs, the audit's Set A probes, the measured siblings and the cluster K controls, $nmoved of them moved from pristine's pre-fix lines; $nkept KEPT rows = pristine's line on both engines, upstream's behaviour for wchar_t and wint_t kept ($nkeptub of them Undefined, exit 1; $nkeptgcc equal to gcc's line beside, $((nkept - nkeptgcc)) not): the reproducer WCHAR_MAX > 0 and its wint_t sibling, the WCHAR_*/WINT_* limit macros, wchar_t objects against every standard partner, the enums, the other macro types and themselves; $nresid lines pinned to the fork's declared residuals (the intptr_t-against-unsigned false UB036 from the upstream NON-STD typing arm, filed; the size_t/intptr_t-against-long-long typing codes); $ngap gap control: the negative wchar_t store still crashes both engines (tray 62, unchanged))"
