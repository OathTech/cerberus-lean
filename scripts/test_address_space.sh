#!/bin/bash
# test_address_space.sh — the TINY-ADDRESS-SPACE differential lane (address-space-bound
# slice PART TWO, C3, 2026-09-17; charter
# lean_frontend/docs/2026-09-17_charter-address-space-bound-part-two.md §2 C3; LADDER
# Tier A row 12). Since C2 the top of the address space is a quantified parameter of the
# semantics (mem.lem `initial_mem_state: integer -> mem_state`; DESIGN.md §4), threaded to
# both entry points from one command-line default per engine. This lane instantiates it
# at TINY values on BOTH engines — the fork oracle's FORK-ONLY `--address-space-top N`
# (backend/driver/main.ml; pristine upstream has no such parameter) and cerberus-lean's
# `--address-space-top N` — over the small programs of tests/address_space/ (a few
# objects each), so the allocator's exhausted regime (upstream-tray draft 44; part one's
# `CerbMem.allocator_active_sound`) is reached by ORDINARY programs, and compares the
# COMPLETE observations through the shared codec (scripts/observations.py; policy batch,
# projection full, sequence comparison — no codec change).
#
# Bounds (BOUNDS below): 64 (every program fits), 32 (the larger programs exhaust), 8
# (the driver's errno int — 4 bytes, align 4 — is the first object and fits at 4; each
# program's schedule is in its header — at top 8 every program exhausts before main's last
# object: in the five original programs the SECOND object (z = 4 - size <= 0 is never a
# positive address), in `window-char-int7` the THIRD — `char c` still fits at 3, `int a[7]`
# exhausts; re-review correction 1).
#
# THE DISCRIMINATOR (C4, pre-merge audit F2, 2026-09-18): the corpus contains exactly one case
# on which the PRE-FIX allocator (pristine b9aeedcb4, upstream-tray draft 44) and the FIXED one
# (remedy 1) decide differently — `window-char-int7` at top 32 (errno -> 28, `char c` -> 27,
# `int a[7]`: z = 27 - 28 = -1, inside the defect window -align/2 < z < 0: old ACTIVE at address
# 2, fixed KILL; the program returns the address's low byte, so pre-fix = Specified(2), fixed =
# the out-of-memory Error). What is EXECUTED is the old ALLOCATION SCHEDULE — the pre-fix
# `allocator` (4a23d98aa) applied step by step to the exact states by the Lean probe
# lean_frontend/docs/2026-09-17_address-space-bound-part-two-evidence/c4-old-allocator-probe.lean,
# giving address 2 — NOT a complete pre-fix C run through the frontend and batch printer; the C
# observation Specified(2) is DERIVED from that address and the program's return expression
# (re-review correction 2). On every OTHER case old = fixed
# (the audit's reconstruction, allocator_arithmetic.py): those cases test exhaustion and the
# parameter's threading, not the draft-44 defect.
#
# Two fail-closed legs per case <program, bound>:
#   LEAN≠FORK  the two engines' complete observations differ under the codec — a
#              zero-discrepancy finding (charter stop rule S4); fatal, reported per case.
#   EXPECT     the fork's observation tokens must equal the row pinned in
#              tests/address_space/expectations.txt, and every pinned row must be a case
#              this run produced — fail-closed BOTH directions (a missing/extra/changed
#              row is fatal; a missing or unreadable expectations file is fatal).
#
# Modes:
#   (default)               run both legs against the committed expectations; rc 0 iff green
#   --expectations FILE     check against FILE instead (the selftest's doctored copies)
#   --record-expectations   rewrite tests/address_space/expectations.txt from the fork's
#                           observations — REFUSED unless every LEAN≠FORK leg agreed
#                           (a dedicated instrument commit, justification in the message)
#   --selftest              run the engines once, then PLANT on scratch copies of the
#                           expectations: (P1) the DISCRIMINATOR `window-char-int7` at top 32
#                           rewritten to its VERIFIED PRE-FIX observation Specified(2) (the
#                           probe above) must be REJECTED; (P2) a missing expectations file,
#                           (P3) a truncated one (last row dropped) and (P4) a row for an
#                           absent case must each be REJECTED; (P5-P7, audit F3) a phantom,
#                           a duplicate and a malformed row appended WITHOUT a final newline
#                           must each be REJECTED exactly like terminated ones, and (P8) the
#                           committed file with its final newline removed must be ACCEPTED;
#                           (P9-P11, the DOMAIN) both engines must REFUSE
#                           `--address-space-top 18446744073709551616` (= 2^64) and `0x40`
#                           (not decimal) with the mirrored sentence, and ACCEPT `64`;
#                           (P12-P14, the SHARED GRAMMAR — re-review R1: nonempty ASCII digits,
#                           0 < value < 2^64, identical on both engines) `6_4` and
#                           `1_8446744073709551615` (underscore separators, which
#                           `String.toNat?` alone accepted) REFUSED on both, and
#                           `18446744073709551615` (= 2^64 - 1, the exclusive bound's last
#                           value) ACCEPTED on both with the same observation; then the
#                           committed file must be green (the unplanted control). Loud plant
#                           banner.
#
# Environment: TIMEOUT_SECS (default 30) per engine invocation; SKIP_BUILD=1 as in
# common.sh (fresh binaries required). Exit: 0 iff green; any failure is fatal and named.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TIMEOUT_SECS="${TIMEOUT_SECS:-30}"
command -v timeout &>/dev/null || { echo "Error: 'timeout' not found" >&2; exit 1; }

CORPUS="$PROJECT_ROOT/tests/address_space"
DEFAULT_EXPECT="$CORPUS/expectations.txt"
BOUNDS=(64 32 8)
SEP=' ;; '   # joins one case's verdict tokens (exhaustive mode may yield several); a token containing it is refused

EXPECT_FILE="$DEFAULT_EXPECT"; RECORD=false; SELFTEST=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --expectations) EXPECT_FILE="$2"; shift 2 ;;
        --record-expectations) RECORD=true; shift ;;
        --selftest) SELFTEST=true; shift ;;
        -h|--help) sed -n '2,45p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Error: unknown option $1 (see --help)" >&2; exit 1 ;;
    esac
done
fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -d "$CORPUS" ]] || fail "corpus not found: $CORPUS"
mapfile -t PROGRAMS < <(cd "$CORPUS" && ls *.c 2>/dev/null | LC_ALL=C sort)
[[ ${#PROGRAMS[@]} -ge 3 ]] || fail "vacuous corpus: ${#PROGRAMS[@]} program(s) in $CORPUS (expected several)"

build_cerberus
build_lean
RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
[[ -d "$RUNTIME_DIR" ]] || fail "runtime dir not found: $RUNTIME_DIR"
mkdir -p "$OBSERVATION_RUN_DIR" || fail "cannot create raw evidence directory"
RUN=$(mktemp -d "$OBSERVATION_RUN_DIR/address_space.XXXXXXXXXX") || fail "mktemp failed"
cd "$PROJECT_ROOT" || fail "cannot cd to $PROJECT_ROOT"

echo ""
echo "tiny-address-space differential lane (address-space-bound part two, C3)"
echo "========================================================================"
echo "corpus: ${#PROGRAMS[@]} programs x bounds ${BOUNDS[*]} = $(( ${#PROGRAMS[@]} * ${#BOUNDS[@]} )) cases; both engines --address-space-top N"

# ---- run both engines once; OBSERVED holds "<name>\t<bound>\t<fork tokens>" per case ----
OBSERVED="$RUN/observed.tsv"; : > "$OBSERVED"
lean_ne_fork=0
for prog in "${PROGRAMS[@]}"; do
    name="${prog%.c}"; c="$CORPUS/$prog"; json="$RUN/$name.json"
    ( timeout "${TIMEOUT_SECS}s" opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --cabs-json "$c" > "$json" 2>"$json.err" ) \
        || fail "cabs-json failed for $prog: $(head -c 300 "$json.err")"
    [[ -s "$json" ]] || fail "empty cabs-json for $prog"
    for b in "${BOUNDS[@]}"; do
        oc="$RUN/$name.$b.fork"; lc="$RUN/$name.$b.lean"
        observation_capture "$oc" timeout "${TIMEOUT_SECS}s" opam exec --switch="$PROJECT_ROOT" -- \
            "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --nolibc --exec --batch --mode=exhaustive \
            --address-space-top "$b" "$c" > /dev/null 2>&1 || true
        observation_capture "$lc" timeout "${TIMEOUT_SECS}s" env LEAN_ABORT_ON_PANIC=1 \
            "$CERBERUS_LEAN_BIN" --batch --address-space-top "$b" "$json" > /dev/null 2>&1 || true
        for side in "$oc" "$lc"; do
            [[ -f "$side.status" ]] || fail "capture incomplete: $side (see $side.capture-error)"
            st=$(cat "$side.status")
            [[ "$st" == 124 || "$st" == 137 ]] && fail "$name top=$b: engine timed out / was killed ($side status $st) — not a comparison"
        done
        # LEAN≠FORK leg: complete observations through the shared codec
        if ! python3 "$OBSERVATION_CODEC" compare --capture "$oc" --other "$lc" \
                --policy batch --projection full --comparison sequence 2>"$RUN/$name.$b.compare.err"; then
            echo "  LEAN≠FORK      $name top=$b  (S4: zero-discrepancy finding) fork[$(cat "$oc.stdout" | head -c 200 | tr '\n' ' ')] lean[$(cat "$lc.stdout" | head -c 200 | tr '\n' ' ')] codec: $(head -c 300 "$RUN/$name.$b.compare.err" | tr '\n' ' ')"
            lean_ne_fork=$((lean_ne_fork + 1))
            continue
        fi
        toks=$(observation_tokens "$oc" --policy batch) || fail "$name top=$b: codec could not tokenise the fork capture $oc"
        [[ -n "$toks" ]] || fail "$name top=$b: no verdict token in the fork capture (status $(cat "$oc.status"); stdout: $(head -c 200 "$oc.stdout"))"
        grep -qF "$SEP" <<<"$toks" && fail "$name top=$b: a verdict token contains the row separator '$SEP'"
        joined=$(paste -sd $'\x1f' <<<"$toks" | sed "s/\x1f/$SEP/g")
        printf '%s\t%s\t%s\n' "$name" "$b" "$joined" >> "$OBSERVED"
        printf '  %-10s %-24s top=%-3s %s\n' "AGREE" "$name" "$b" "$joined"
    done
done
[[ $lean_ne_fork -eq 0 ]] || fail "$lean_ne_fork case(s) LEAN≠FORK (charter stop rule S4) — no expectations check, no record"
n_obs=$(grep -c . "$OBSERVED")
[[ $n_obs -eq $(( ${#PROGRAMS[@]} * ${#BOUNDS[@]} )) ]] || fail "observed $n_obs cases, expected $(( ${#PROGRAMS[@]} * ${#BOUNDS[@]} ))"

# ---- the EXPECT leg: a pure function of (expectations file, observed table) ----
check_expectations() {  # <expectations-file> <observed-tsv> ; prints verdict lines; rc 0 iff green
    local ef="$1" ob="$2" bad=0 n=0
    [[ -f "$ef" ]] || { echo "  EXPECT FAIL  expectations file not found: $ef"; return 1; }
    declare -A EXP=()
    # pre-merge audit F3 (2026-09-18): `|| [[ -n "$en" ]]` processes a NONEMPTY final record that EOF
    # cut before its newline — without it a phantom/duplicate/malformed last row silently vanished
    # (fail-open); the observed-table loop below is written the same way for consistency.
    while IFS=$'\t' read -r en eb et || [[ -n "$en" ]]; do
        [[ -z "$en" || "$en" == \#* ]] && continue
        [[ -n "$eb" && -n "$et" ]] || { echo "  EXPECT FAIL  malformed expectations row: '$en	$eb	$et'"; return 1; }
        [[ -n "${EXP["$en/$eb"]+x}" ]] && { echo "  EXPECT FAIL  duplicate expectations row for $en top=$eb"; return 1; }
        EXP["$en/$eb"]="$et"; n=$((n + 1))
    done < "$ef"
    [[ $n -gt 0 ]] || { echo "  EXPECT FAIL  expectations file has no rows: $ef"; return 1; }
    declare -A SEEN=()
    while IFS=$'\t' read -r on ob_ ot || [[ -n "$on" ]]; do
        [[ -z "$on" ]] && continue
        SEEN["$on/$ob_"]=1
        if [[ -z "${EXP["$on/$ob_"]+x}" ]]; then
            echo "  EXPECT FAIL  $on top=$ob_: observed but NOT in the expectations file (observed: $ot)"; bad=$((bad + 1))
        elif [[ "${EXP["$on/$ob_"]}" != "$ot" ]]; then
            echo "  EXPECT FAIL  $on top=$ob_: expected [${EXP["$on/$ob_"]}] observed [$ot]"; bad=$((bad + 1))
        fi
    done < "$ob"
    for k in "${!EXP[@]}"; do
        [[ -n "${SEEN[$k]+x}" ]] || { echo "  EXPECT FAIL  ${k%/*} top=${k##*/}: pinned in the expectations file but NOT a case of this run"; bad=$((bad + 1)); }
    done
    [[ $bad -eq 0 ]] && echo "  EXPECT OK    $n pinned rows = $(grep -c . "$ob") observed cases, every token identical" && return 0
    return 1
}

if $RECORD; then
    {
        echo "# tests/address_space/expectations.txt — the FORK oracle's complete observation tokens per <program, top>"
        echo "# (scripts/observations.py tokens, policy batch, projection full; several verdicts joined by '$SEP'), written by"
        echo "# scripts/test_address_space.sh --record-expectations ONLY after every case read LEAN = FORK through the codec"
        echo "# (the lane's LEAN≠FORK leg). Fail-closed both directions: every row must be reproduced, every case must have a"
        echo "# row. Re-record = a dedicated instrument commit with its justification (address-space-bound part two, C3,"
        echo "# 2026-09-17; the discriminator window-char-int7@32 is the one case old != fixed — its VERIFIED pre-fix"
        echo "# observation Specified(2) is what the --selftest plant P1 forges; C4 2026-09-18)."
        echo "# format: <program>\t<top>\t<tokens>"
        cat "$OBSERVED"
    } > "$DEFAULT_EXPECT" || fail "cannot write $DEFAULT_EXPECT"
    echo "EXPECTATIONS RECORDED: $DEFAULT_EXPECT ($n_obs rows)"
    exit 0
fi

if $SELFTEST; then
    echo ""
    echo "test_address_space: SELFTEST — planting on scratch copies of the expectations (loud plant banner; the committed file is untouched)"
    W=$(mktemp -d "$RUN/plants.XXXXXX") || fail "mktemp failed"
    fails=0
    expect_red() {  # <label> <expectations-file>
        local out; out=$(check_expectations "$2" "$OBSERVED"); local rc=$?
        if [[ $rc -ne 0 ]]; then echo "  PLANT OK   [$1] -> $(grep -m1 'EXPECT FAIL' <<<"$out")"
        else echo "  PLANT FAIL [$1]: the doctored expectations were ACCEPTED"; fails=$((fails + 1)); fi
    }
    # P1: THE DISCRIMINATOR forged to its VERIFIED pre-fix observation (audit F2): window-char-int7@32 —
    # old allocator ACTIVE at address 2 (executed: c4-old-allocator-probe), the program returns the
    # address's low byte -> Specified(2); the fixed engines kill (the pinned row).
    grep -qP '^window-char-int7\t32\tERR:' "$DEFAULT_EXPECT" \
        || fail "selftest premise: the committed row 'window-char-int7 top=32' is not the out-of-memory kill (the P1 plant needs the discriminator's fixed outcome)"
    python3 - "$DEFAULT_EXPECT" "$W/p1.txt" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
forged = 'VAL:{value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}'
out = []
for line in open(src):
    if line.startswith('window-char-int7\t32\t'):
        line = 'window-char-int7\t32\t' + forged + '\n'
    out.append(line)
open(dst, 'w').write(''.join(out))
PY
    expect_red "P1 the discriminator window-char-int7@32 forged to its DERIVED pre-fix observation (Specified(2) — the executed old allocation at address 2 + the program's return expression — where the kill is pinned)" "$W/p1.txt"
    expect_red "P2 missing expectations file" "$W/does-not-exist.txt"
    grep -v '^#' "$DEFAULT_EXPECT" | head -n -1 > "$W/p3.txt"
    expect_red "P3 truncated expectations (last row dropped)" "$W/p3.txt"
    { cat "$DEFAULT_EXPECT"; printf 'absent-program\t64\tVAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n'; } > "$W/p4.txt"
    expect_red "P4 a row for a case this run never produced" "$W/p4.txt"
    # audit F3 (2026-09-18): the same doctored rows WITHOUT a trailing newline — the pre-fix reader dropped
    # an unterminated final record silently (fail-open); each must be rejected exactly like P4/duplicate/malformed
    { cat "$DEFAULT_EXPECT"; printf 'absent-program\t64\tVAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}'; } > "$W/p5.txt"
    expect_red "P5 phantom row WITHOUT a final newline" "$W/p5.txt"
    { cat "$DEFAULT_EXPECT"; grep -v '^#' "$DEFAULT_EXPECT" | head -n 1 | tr -d '\n'; } > "$W/p6.txt"
    expect_red "P6 duplicate row WITHOUT a final newline" "$W/p6.txt"
    { cat "$DEFAULT_EXPECT"; printf 'two-ints\t64'; } > "$W/p7.txt"
    expect_red "P7 malformed row WITHOUT a final newline" "$W/p7.txt"
    head -c -1 "$DEFAULT_EXPECT" > "$W/p8.txt"
    [[ "$(tail -c 1 "$W/p8.txt")" != "" ]] || fail "selftest premise: p8 still ends with a newline"
    if check_expectations "$W/p8.txt" "$OBSERVED" > "$W/p8.out"; then echo "  PLANT OK   [P8 the committed file with its final newline removed is ACCEPTED (the last row is read)] -> $(grep -m1 'EXPECT OK' "$W/p8.out")"
    else echo "  PLANT FAIL [P8]: a valid file without a final newline was REJECTED: $(grep -m1 'EXPECT FAIL' "$W/p8.out")"; fails=$((fails + 1)); fi
    # the DOMAIN (C4, the consumer's review): 0 < top < 2^64, DECIMAL only, the SAME refusal sentence on both
    # engines (mirror doctrine; the exit codes are the CLI libraries': cmdliner 124, cerberus-lean 2)
    dprog="$CORPUS/window-char-int7.c"; djson="$RUN/window-char-int7.json"
    [[ -s "$djson" ]] || fail "selftest premise: $djson missing"
    cli_case() {  # <label> <value> <expect: refuse-domain|refuse-decimal|accept> [<accepted verdict value>]
        local label="$1" v="$2" want="$3" val="${4:-}" orc=0 lrc=0 oerr lerr oout lout ok=1
        oout=$(timeout "${TIMEOUT_SECS}s" opam exec --switch="$PROJECT_ROOT" -- "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
            --nolibc --exec --batch --mode=exhaustive --address-space-top "$v" "$dprog" 2>"$W/cli.oerr") || orc=$?
        lout=$(timeout "${TIMEOUT_SECS}s" env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch --address-space-top "$v" "$djson" 2>"$W/cli.lerr") || lrc=$?
        # cmdliner wraps and indents its error text: strip ANSI, join lines, collapse whitespace runs
        oerr=$(sed 's/\x1b\[[0-9;]*m//g' "$W/cli.oerr" | tr '\n' ' ' | tr -s ' '); lerr=$(tr '\n' ' ' < "$W/cli.lerr" | tr -s ' ')
        case "$want" in
            refuse-domain)
                [[ $orc -ne 0 && $lrc -ne 0 && "$oerr" == *"the address-space top must fit an LP64 pointer: 0 < top < 2^64"* \
                    && "$lerr" == *"the address-space top must fit an LP64 pointer: 0 < top < 2^64"* ]] || ok=0 ;;
            refuse-decimal)
                [[ $orc -ne 0 && $lrc -ne 0 && "$oerr" == *"not a decimal numeral"* && "$lerr" == *"not a decimal numeral"* ]] || ok=0 ;;
            accept)
                [[ -n "$val" ]] || fail "cli_case accept needs the expected verdict value"
                [[ $orc -eq 0 && $lrc -eq 0 && "$oout" == *"Defined {value: \"$val\""* && "$lout" == *"Defined {value: \"$val\""* ]] || ok=0 ;;
        esac
        if [[ $ok -eq 1 ]]; then echo "  PLANT OK   [$label] -> fork rc=$orc lean rc=$lrc"
        else echo "  PLANT FAIL [$label]: fork rc=$orc [$oout | $oerr] lean rc=$lrc [$lout | $lerr]"; fails=$((fails + 1)); fi
    }
    cli_case "P9 --address-space-top 18446744073709551616 (= 2^64) REFUSED on both engines with the mirrored domain sentence" 18446744073709551616 refuse-domain
    cli_case "P10 --address-space-top 0x40 (not decimal) REFUSED on both engines" 0x40 refuse-decimal
    cli_case "P11 --address-space-top 64 ACCEPTED on both engines (window-char-int7 -> Specified(28))" 64 accept 'Specified(28)'
    # the SHARED GRAMMAR (C5, re-review R1): underscore separators refused on both; 2^64 - 1 accepted on both
    cli_case "P12 --address-space-top 6_4 (an underscore separator) REFUSED on both engines" 6_4 refuse-decimal
    cli_case "P13 --address-space-top 1_8446744073709551615 (a separator inside 2^64 - 1) REFUSED on both engines" 1_8446744073709551615 refuse-decimal
    cli_case "P14 --address-space-top 18446744073709551615 (= 2^64 - 1, the last value of the exclusive bound) ACCEPTED on both engines (window-char-int7 -> Specified(216))" 18446744073709551615 accept 'Specified(216)'
    echo "  REVERTED (the committed expectations):"
    if check_expectations "$DEFAULT_EXPECT" "$OBSERVED"; then :; else echo "  PLANT FAIL [control]: the committed expectations are not green" >&2; fails=$((fails + 1)); fi
    if [[ $fails -eq 0 ]]; then echo "test_address_space: SELFTEST OK (14 plants — P1 the discriminator's derived pre-fix observation, P2 missing file, P3 truncated, P4 phantom row, P5-P7 phantom/duplicate/malformed rows without a final newline all REJECTED; P8 the valid file without a final newline ACCEPTED; P9/P10 the out-of-domain and non-decimal tops REFUSED on both engines, P11 a decimal top accepted; P12/P13 underscore-separated spellings REFUSED on both, P14 2^64 - 1 ACCEPTED on both; the committed file green)"; exit 0; fi
    echo "test_address_space: SELFTEST FAILED ($fails)" >&2; exit 1
fi

echo ""
if check_expectations "$EXPECT_FILE" "$OBSERVED"; then
    echo "test_address_space: OK ($n_obs cases: LEAN = FORK through the shared codec at tops ${BOUNDS[*]}; every fork observation = its pinned row in $(basename "$EXPECT_FILE"))"
    exit 0
fi
fail "expectations check failed against $EXPECT_FILE"
