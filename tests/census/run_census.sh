#!/bin/bash
# run_census.sh — the real-C reach census instrument (next-phase plan P1f-2,
# 2026-10-04). [AGENT] REPORT-ONLY: it never compares more loosely than the
# lanes do, never edits a program, and is NOT a gated lane.
#
# Record: lean_frontend/docs/2026-10-04_real-c-reach-census.md.
#
# A UNIT is one program: an ordered list of TUs + a flag set + a libc mode +
# the stages to run (units.txt). Every unit is taken through the stages
# below IN ORDER; every stage runs on both engines where both have one, so a
# stop is classified, not just located:
#
#  1 oracle-fe   per TU: the oracle's own cpp command (oracle_cpp_cmd), then
#                the bare front end `cerberus --nolibc FLAGS tu.c` (parse, desugar,
#                Ail typing, elaboration to Core; main.ml "Link and execute"
#                arm with exec=false and one file).
#  2 bridge      per TU: `cerberus --cabs-json FLAGS tu.c` (no --nolibc, as
#                every lane does; CERB_WITH_LIB is read by no libc header).
#  3 lean-elab   per TU: `cerberus-lean --pp-core tu.json` (Lean desugar,
#                typing, elaboration; stops before execution).
#  4 link        all TUs: oracle bare front end over all files (+ libc unless
#                --nolibc) vs `cerberus-lean --pp-core [--libc …] *.json`
#                (Core_linking.link, Main.lean runPipeline; stops before exec).
#  5 run         oracle `--exec --batch` (default --mode=random: ONE trace)
#                vs `cerberus-lean --batch --first`; compared with the lanes'
#                codec (observations.py compare, `full` projection). Then
#                exhaustive on both (`--mode=exhaustive` / no --first),
#                compared the same way — `--first` is outside the contract's
#                §1 promise, exhaustive is inside it.
#
# Stages 1-3 are run even after an oracle front-end failure, so "both fail
# alike" is distinguished from "Lean accepts what the oracle rejects".
#
# Every engine invocation: scripts/capped per-test cap (CERB_TEST_MEM_MAX,
# default 4G), `timeout ${TIMEOUT_SECS}` (default 300, the libxml2 lane's),
# GNU time record, stdin </dev/null; NO_COLOR/TERM pinned by common.sh; Lean
# with LEAN_ABORT_ON_PANIC=1. SKIP_BUILD=1 is forced so common.sh verifies both
# drivers' freshness stamps instead of building (fail-closed).
#
# Classification is fail-noisy (pre-merge audit 2026-10-05, L1-L3):
#  - a capture the instrument itself failed to complete (observation_capture's
#    .capture-error marker; its rc 125 collides with the oracle's internal-error
#    rc) is INSTRUMENT-ERROR, and the run exits non-zero;
#  - "refusal" means the engine's attributed refusal form only (lean_refusal);
#  - any one-sided acceptance, including "oracle front end fails on one TU,
#    Lean side fails on a different TU", is a DISAGREEMENT row.
# The run exits 1 if any row is INSTRUMENT-ERROR (rows are still written).
#
# pKVM: census_pool_init is derived at run time from the case study's own
# hyp_pool_init (pkvm/derive_pool_init.py; GPL-2.0-only text never committed)
# into <out-dir>/.pkvm-derived/page_alloc_census.c (units.txt token @G@).
#
# Usage: tests/census/run_census.sh <out-dir> [unit-name-regex]
# Writes <out-dir>/results.tsv (one row per unit) and <out-dir>/<unit>/ raw
# captures (stdout/stderr/status/command/time per invocation).
set -uo pipefail
export SKIP_BUILD=1
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../scripts/common.sh"
require_time_bin

OUT="${1:?usage: run_census.sh <out-dir> [unit-regex]}"
FILTER="${2:-.}"
TIMEOUT_SECS="${TIMEOUT_SECS:-300}"
RT="$PROJECT_ROOT/_build/install/default"
UNITS="$HERE/units.txt"
die() { echo "census: ERROR: $*" >&2; exit 1; }
[[ -x "$CERBERUS_BIN" && -x "$CERBERUS_LEAN_BIN" ]] || die "engines not built"
[[ -f "$UNITS" ]] || die "missing $UNITS"
mkdir -p "$OUT" || die "cannot create $OUT"
OUT="$(cd "$OUT" && pwd)"

# ---- flag sets (each prints cerberus args one per line) -------------------
PROJ_DEPS=""
d="$PROJECT_ROOT"; while [[ "$d" != / ]]; do [[ -d "$d/deps" ]] && { PROJ_DEPS="$d/deps"; break; }; d="$(dirname "$d")"; done
[[ -n "$PROJ_DEPS" ]] || die "deps/ not found above $PROJECT_ROOT"
PKVM="$PROJ_DEPS/CN-pKVM-buddy-allocator-case-study"
LINUX="$PROJ_DEPS/linux"
LIBXML2="$PROJ_DEPS/libxml2"
declare -A FLAGSET
# --nostdinc: the case study is freestanding and ships its own stddef.h/limits.h;
# with the oracle's libc include dirs first, a driver TU would pick up libc's
# <limits.h> and memory.h's USHRT_MAX redefinition fails cpp -Werror.
FLAGSET[pkvm]="$(printf '%s\n' --nostdinc -I "$PKVM" -I "$HERE/pkvm")"
PKVM_DERIVED="$OUT/.pkvm-derived"
rm -rf "$PKVM_DERIVED"
pd=$(python3 "$HERE/pkvm/derive_pool_init.py" "$PKVM" "$PKVM_DERIVED") || die "pKVM census_pool_init derivation failed (see above)"
[[ "$pd" == "$PKVM_DERIVED/page_alloc_census.c" && -s "$pd" ]] || die "derive_pool_init.py printed '$pd', expected $PKVM_DERIVED/page_alloc_census.c"
lx=$("$HERE/linux/prep.sh" "$OUT/.linux-config") || die "linux prep failed"
FLAGSET[linux]="--nostdinc
$lx"
xp=$("$PROJECT_ROOT/scripts/libxml2_prep.sh" chvalid.c) || die "libxml2_prep failed (pin drift?)"
FLAGSET[libxml2]="$(printf '%s\n' "$xp" | sed '$d')"   # drop the TU path (last line)
FLAGSET[none]=""

LIBC_ARGS=()
need_libc_prep() {
    [[ ${#LIBC_ARGS[@]} -gt 0 ]] && return 0
    local out
    out=$("$PROJECT_ROOT/scripts/libc_prep.sh" --jsons "$OUT/.libcjson") || die "libc_prep --jsons failed"
    mapfile -t LJ <<< "$out"
    [[ ${#LJ[@]} -eq 12 ]] || die "expected 12 libc metadata jsons, got ${#LJ[@]}"
    LIBC_ARGS=(--libc "$PROJECT_ROOT/tests/libc/libc.core")
    for j in "${LJ[@]}"; do LIBC_ARGS+=(--libc-tu "$j"); done
}

# ---- one capped, timed, captured invocation ------------------------------
# inv <prefix> <cmd…>: rc in $INV_RC, class in $INV_CLASS (OK|FAIL|TIMEOUT|HANG|KILL|INSTRUMENT-ERROR),
# seconds in $INV_WALL.
# INSTRUMENT-ERROR: observation_capture left its .capture-error marker (its
# own rc 125 is indistinguishable from the oracle's internal-error rc 125);
# recorded in UNIT_IERR and turned into a loud row + non-zero exit.
inv() {
    local p="$1"; shift
    INV_RC=0
    observation_capture "$p" "${CAPPED_TEST[@]}" "$TIME_BIN" -v -o "$p.time" \
        timeout "${TIMEOUT_SECS}s" "$@" < /dev/null > /dev/null || INV_RC=$?
    if [[ -e "$p.capture-error" ]]; then
        echo "census: INSTRUMENT-ERROR: capture $p failed: $(cat "$p.capture-error")" >&2
        INV_CLASS=INSTRUMENT-ERROR; INV_WALL=0; UNIT_IERR+="$(basename "$p") "
        return
    fi
    local cw; cw=$(time_record_cpu_wall "$p.time") || die "unreadable time record $p.time"
    INV_WALL="${cw#* }"
    if is_cap_kill "$INV_RC" "$p.stderr"; then INV_CLASS=KILL
    elif [[ $INV_RC -eq 124 ]]; then
        INV_CLASS=$(classify_exit124 "$p.time" "$TIMEOUT_SECS") || die "unclassifiable timeout $p"
        INV_CLASS="${INV_CLASS%%(*}"
    elif [[ $INV_RC -eq 0 ]]; then INV_CLASS=OK
    else INV_CLASS=FAIL; fi
}
# first diagnostic line of a capture (verbatim, one line, tabs flattened)
keymsg() {
    local p="$1" m
    m=$(grep -m1 -E 'error|Error|refused|uncaught|failed|unsupported|Unsupported|panic|PANIC|KILLED|exception' "$p.stdout" "$p.stderr" 2>/dev/null | head -1 | sed 's/^[^:]*\.\(stdout\|stderr\)://')
    [[ -z "$m" ]] && m=$(cat "$p.stderr" "$p.stdout" | grep -v '^\s*$' | head -1)
    printf '%s' "$m" | tr '\t' ' ' | cut -c1-400
}
# The oracle's cpp command, rebuilt exactly as backend/driver/main.ml:38-52
# create_cpp_cmd does for STAGE 1's invocation (default --cpp string
# main.ml:389-391; macros, then -U, then -I with the runtime libc dirs first
# unless --nostdinc, then -include builtins.h before the user's --include
# files). Stage 1 always runs --nolibc, and create_cpp_cmd adds
# -DCERB_WITH_LIB only without --nolibc (main.ml:41), so it is never added
# here, whatever the unit's libc mode (pre-merge audit L5, 2026-10-05). WHY not `cerberus -E`: the
# oracle's -E mode is broken at the pin AND upstream — main.ml:248-253 passes
# the preprocessed TEXT to print_file, which open_in's it as a FILE NAME
# (Sys_error "...: File name too long"); deps/cerberus-upstream main.ml:79/238
# is the same code. Used only to say whether a front-end stop is in cpp.
oracle_cpp_cmd() { # <tu> -> CPP_CMD array (stage 1: --nolibc)
    local tu="$1" a nostd=0 i
    local -a D=() I=() INC=()
    for ((i=0; i<${#FLAGS[@]}; i++)); do
        a="${FLAGS[$i]}"
        case "$a" in
            --nostdinc) nostd=1;;
            -D) i=$((i+1)); D+=("-D${FLAGS[$i]}");;
            -D*) D+=("$a");;
            -I) i=$((i+1)); I+=("-I${FLAGS[$i]}");;
            -I*) I+=("$a");;
            --include=*) INC+=(-include "${a#--include=}");;
            *) die "oracle_cpp_cmd: unhandled flag $a";;
        esac
    done
    local -a LIBC=()
    [[ $nostd == 1 ]] || LIBC=("-I$RT/lib/cerberus-lib/runtime/libc/include" "-I$RT/lib/cerberus-lib/runtime/libc/include/posix")
    CPP_CMD=(cc -std=c11 -E -CC -Werror -Wno-builtin-macro-redefined -nostdinc -undef -D__cerb__
             "${D[@]}" "${LIBC[@]}" "${I[@]}" -include "$RT/lib/cerberus-lib/runtime/libc/include/builtins.h" "${INC[@]}" "$tu")
}
# Signature-level elaboration comparison, REPORTING ONLY — scripts/test_elab.sh's
# instrument verbatim (extract_core_sig.py + canonicalize_ids.py, the Lean
# side's injected __builtin_ procdecls dropped). Its documented limits apply:
# bodies are not compared, the OCaml pp prints only main-file declarations
# (header-defined functions are one-sided), and first-occurrence id
# canonicalization can DIFF on emission order. OK|MISSING|NA.
sig_compare() { # <prefix>
    local p="$1"
    python3 "$PROJECT_ROOT/scripts/extract_core_sig.py" < "$p.fe.stdout" > "$p.sig.ocaml" 2>/dev/null || { echo NA; return; }
    grep -v '^\(procdecl\|builtin\) __builtin_' "$p.elab.stdout" > "$p.sig.lean"
    python3 "$PROJECT_ROOT/scripts/canonicalize_ids.py" < "$p.sig.ocaml" | sort > "$p.canon.ocaml" || { echo NA; return; }
    python3 "$PROJECT_ROOT/scripts/canonicalize_ids.py" < "$p.sig.lean" | sort > "$p.canon.lean" || { echo NA; return; }
    # oracle lines absent on the Lean side = the signal (MISSING); Lean-only
    # lines are the documented header-declaration asymmetry (counted).
    local miss extra
    miss=$(comm -23 "$p.canon.ocaml" "$p.canon.lean" | tee "$p.sig.missing" | grep -c .)
    extra=$(comm -13 "$p.canon.ocaml" "$p.canon.lean" | grep -c .)
    [[ $(grep -c . "$p.canon.ocaml") -gt 0 ]] || { echo "NA(empty oracle signature)"; return; }
    if [[ $miss -eq 0 ]]; then echo "OK(oracle $(grep -c . "$p.canon.ocaml") lines all present; lean-only $extra)"
    else echo "MISSING($miss of $(grep -c . "$p.canon.ocaml"); lean-only $extra)"; fi
}
LEAN=(env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN")   # capped execs its argv: no shell functions
# lean_refusal <prefix>: succeeds (printing the line) iff the capture is one of
# the engine's attributed refusal forms (pre-merge audit L3, 2026-10-05):
#  - driver/CLI refusal: exit 2 and a stderr line starting
#    "cerberus-lean: refused — " (Main.lean refuseFlag/refuseRuntime/…;
#    scripts/check_cli_refusals.sh pins this form);
#  - in-model refusal: exit 134 (LEAN_ABORT_ON_PANIC) and a stderr line
#    starting "PANIC at " that carries ": refused — " (e.g. CerbFloat.formatFixed)
#    or "CerbFS refusal (fail-closed fs-model boundary): " (CerbFS fsRefusal).
# Anything else, including the word "refused" elsewhere, is NOT a refusal.
lean_refusal() {
    local p="$1" rc
    rc=$(cat "$p.status") || die "missing status $p.status"
    if [[ "$rc" == 2 ]]; then
        grep -m1 '^cerberus-lean: refused — ' "$p.stderr"
    elif [[ "$rc" == 134 ]]; then
        grep -m1 -E '^PANIC at .*(: refused — |CerbFS refusal \(fail-closed fs-model boundary\): )' "$p.stderr"
    else
        return 1
    fi
}

printf 'unit\tmode\tfirst_stop\toutcome\tcause\twall_s\tdetail\n' > "$OUT/results.tsv"

run_unit() {
    local name="$1" mode="$2" fset="$3" tus_csv="$4" stages="$5"
    local U="$OUT/$name"; rm -rf "$U"; mkdir -p "$U"
    local -a FLAGS=() TUS=() JSONS=()
    [[ -n "${FLAGSET[$fset]+x}" ]] || die "unknown flag set $fset"
    [[ -n "${FLAGSET[$fset]}" ]] && mapfile -t FLAGS <<< "${FLAGSET[$fset]}"
    IFS=',' read -r -a TUS <<< "$tus_csv"
    local i t
    for i in "${!TUS[@]}"; do
        t="${TUS[$i]}"
        t="${t//@T@/$HERE}"; t="${t//@P@/$PKVM}"; t="${t//@G@/$PKVM_DERIVED}"; t="${t//@L@/$LINUX}"; t="${t//@X@/$LIBXML2}"
        [[ -f "$t" ]] || die "$name: TU not found: $t"
        TUS[$i]="$t"
    done
    local -a OMODE=() LMODE=()
    if [[ "$mode" == nolibc ]]; then OMODE=(--nolibc); else need_libc_prep; LMODE=("${LIBC_ARGS[@]}"); fi
    local t0=$SECONDS stop="" outcome="" cause="" detail="" rl
    UNIT_IERR=""
    local fe_fail="" fe_msg="" fe_sub="" br_fail="" br_msg="" el_fail="" el_msg="" el_cls="" el_pfx=""
    local n=0 b
    # 1-3: per TU
    for t in "${TUS[@]}"; do
        n=$((n+1)); b="$n-$(basename "$t" .c)"
        if [[ -z "$fe_fail" ]]; then
            oracle_cpp_cmd "$t"
            inv "$U/$b.cpp" "${CPP_CMD[@]}"
            if [[ $INV_CLASS != OK ]]; then fe_fail="$t"; fe_sub=cpp; fe_msg="[$INV_CLASS] $(keymsg "$U/$b.cpp")"
            else
                rm -f "$U/$b.cpp.stdout"   # preprocessed text: large, re-derivable
                # always --nolibc here: without it the bare front end also LINKS
                # libc, which is stage 4's question (per-TU Lean elaboration
                # does not link either)
                # --pp core: the elaborated Core on stdout, for the signature
                # sub-signal below (test_elab.sh's instrument)
                inv "$U/$b.fe" "$CERBERUS_BIN" --runtime="$RT" --nolibc --pp core "${FLAGS[@]}" "$t"
                [[ $INV_CLASS != OK ]] && { fe_fail="$t"; fe_sub=front-end; fe_msg="[$INV_CLASS] $(keymsg "$U/$b.fe")"; }
                detail+="fe:$(basename "$t")=${INV_WALL}s "
            fi
        fi
        if [[ -z "$br_fail" ]]; then
            inv "$U/$b.bridge" "$CERBERUS_BIN" --runtime="$RT" --cabs-json "${FLAGS[@]}" "$t"
            if [[ $INV_CLASS != OK || ! -s "$U/$b.bridge.stdout" ]]; then
                br_fail="$t"; br_msg="[$INV_CLASS] $(keymsg "$U/$b.bridge")"
            else
                JSONS+=("$U/$b.bridge.stdout")
                detail+="bridge:$(basename "$t")=${INV_WALL}s "
                if [[ -z "$el_fail" ]]; then
                    inv "$U/$b.elab" "${LEAN[@]}" --pp-core "$U/$b.bridge.stdout"
                    detail+="elab:$(basename "$t")=${INV_WALL}s "
                    if [[ $INV_CLASS != OK ]]; then
                        el_fail="$t"; el_cls="$INV_CLASS"; el_pfx="$b.elab"; el_msg="[$INV_CLASS] $(keymsg "$U/$b.elab")"
                    elif [[ -z "$fe_fail" ]]; then
                        detail+="sig:$(basename "$t")=$(sig_compare "$U/$b") "
                    fi
                fi
            fi
        fi
    done
    local tag
    if [[ -n "$fe_fail" ]]; then
        stop="oracle-fe($fe_sub):$(basename "$fe_fail")"; cause="$fe_msg"
        if [[ "$fe_msg" == "[TIMEOUT]"* || "$fe_msg" == "[KILL]"* || "$fe_msg" == "[HANG]"* ]]; then outcome="resource-limit"
        elif [[ "$fe_sub" == cpp ]]; then outcome="oracle-fe-failure(cpp; Lean side not reached)"
        elif [[ -n "$br_fail" && "$br_fail" == "$fe_fail" ]]; then outcome="both-fail-alike(shared parser: bridge also fails: $br_msg)"
        elif [[ -n "$el_fail" && "$el_fail" == "$fe_fail" ]]; then outcome="both-fail-alike(lean-elab: $el_msg)"
        elif [[ -n "$br_fail" || -n "$el_fail" ]]; then
            # the Lean side failed on a DIFFERENT TU: one engine accepted a TU
            # the other rejected, whichever side is earlier (audit L1)
            outcome="DISAGREEMENT(oracle front end fails on $(basename "$fe_fail"); Lean side fails on a different TU $(basename "${br_fail:-$el_fail}"): ${br_msg}${el_msg})"
        else outcome="DISAGREEMENT(Lean elaborates a TU the oracle front end rejects)"; fi
    elif [[ -n "$br_fail" ]]; then
        stop="bridge:$(basename "$br_fail")"; cause="$br_msg"
        case "$br_msg" in \[TIMEOUT\]*|\[KILL\]*|\[HANG\]*) outcome="resource-limit";; *) outcome="bridge-failure(oracle front end accepts)";; esac
    elif [[ -n "$el_fail" ]]; then
        stop="lean-elab:$(basename "$el_fail")"; cause="$el_msg"
        case "$el_cls" in
            TIMEOUT|KILL|HANG) outcome="resource-limit";;
            *) if rl=$(lean_refusal "$U/$el_pfx"); then outcome="refusal"; cause="$rl"
               else outcome="DISAGREEMENT(Lean elaboration fails where the oracle front end succeeds)"; fi;;
        esac
    fi
    if [[ -z "$stop" && "$stages" == elab ]]; then
        stop="none(stages 1-3 only)"; outcome="agreement(front end + bridge + Lean elaboration)"
    fi
    # 4 link
    if [[ -z "$stop" ]]; then
        inv "$U/link.oracle" "$CERBERUS_BIN" --runtime="$RT" "${OMODE[@]}" "${FLAGS[@]}" "${TUS[@]}"
        local oc=$INV_CLASS om; om="[$INV_CLASS] $(keymsg "$U/link.oracle")"; detail+="link-oracle=${INV_WALL}s "
        inv "$U/link.lean" "${LEAN[@]}" --pp-core "${LMODE[@]}" "${JSONS[@]}"
        local lc=$INV_CLASS lm; lm="[$INV_CLASS] $(keymsg "$U/link.lean")"; detail+="link-lean=${INV_WALL}s "
        if [[ $oc != OK || $lc != OK ]]; then
            stop="link"
            if [[ $oc =~ TIMEOUT|KILL|HANG || $lc =~ TIMEOUT|KILL|HANG ]]; then outcome="resource-limit"; cause="oracle $om | lean $lm"
            elif [[ $oc != OK && $lc != OK ]]; then outcome="both-fail-alike"; cause="oracle $om | lean $lm"
            elif [[ $lc != OK ]] && rl=$(lean_refusal "$U/link.lean"); then outcome="refusal"; cause="$rl"
            else outcome="DISAGREEMENT(link: oracle $oc, lean $lc)"; cause="oracle $om | lean $lm"; fi
        fi
    fi
    # 5 run
    if [[ -z "$stop" ]]; then
        inv "$U/run1.oracle" "$CERBERUS_BIN" --runtime="$RT" "${OMODE[@]}" --exec --batch "${FLAGS[@]}" "${TUS[@]}"
        local o1=$INV_CLASS; detail+="run1-oracle=${INV_WALL}s "
        inv "$U/run1.lean" "${LEAN[@]}" --batch --first "${LMODE[@]}" "${JSONS[@]}"
        local l1=$INV_CLASS; detail+="run1-lean=${INV_WALL}s "
        local c1="" ce=""
        if python3 "$OBSERVATION_CODEC" compare --capture "$U/run1.oracle" --other "$U/run1.lean" > "$U/run1.compare" 2>&1; then c1=MATCH; else c1=DIFF; fi
        inv "$U/runx.oracle" "$CERBERUS_BIN" --runtime="$RT" "${OMODE[@]}" --exec --batch --mode=exhaustive "${FLAGS[@]}" "${TUS[@]}"
        local ox=$INV_CLASS; detail+="runx-oracle=${INV_WALL}s "
        inv "$U/runx.lean" "${LEAN[@]}" --batch "${LMODE[@]}" "${JSONS[@]}"
        local lx=$INV_CLASS; detail+="runx-lean=${INV_WALL}s "
        if [[ $ox =~ TIMEOUT|KILL|HANG || $lx =~ TIMEOUT|KILL|HANG ]]; then ce="NOT-CHEAP(oracle $ox, lean $lx)"
        elif python3 "$OBSERVATION_CODEC" compare --capture "$U/runx.oracle" --other "$U/runx.lean" > "$U/runx.compare" 2>&1; then ce=MATCH; else ce=DIFF; fi
        local v; v=$(head -c 200 "$U/run1.oracle.stdout" | head -1)
        detail+="first=$c1 exhaustive=$ce "
        if [[ $o1 =~ TIMEOUT|KILL|HANG || $l1 =~ TIMEOUT|KILL|HANG ]]; then
            stop="run"; outcome="resource-limit"; cause="oracle $o1 $(keymsg "$U/run1.oracle") | lean $l1 $(keymsg "$U/run1.lean")"
        elif [[ $c1 == MATCH && $ce == MATCH ]]; then
            stop="none(completed run)"; outcome="agreement(--first and exhaustive)"; cause="$v"
        elif [[ $c1 == MATCH ]]; then
            stop="none(completed run)"; outcome="agreement(--first; exhaustive $ce)"; cause="$v"
            [[ $ce == DIFF ]] && { stop="run(exhaustive)"; outcome="DISAGREEMENT(exhaustive)"; }
        elif rl=$(lean_refusal "$U/run1.lean"); then
            stop="run"; outcome="refusal"; cause="$rl"
        elif [[ $ce == MATCH ]]; then
            stop="none(completed run)"; outcome="agreement(exhaustive; --first trace differs, outside contract §1)"; cause="$v"
        else
            stop="run"; outcome="DISAGREEMENT(--first ${c1}; exhaustive ${ce})"; cause="oracle: $v | lean: $(head -c 200 "$U/run1.lean.stdout" | head -1)"
        fi
    fi
    if [[ -n "$UNIT_IERR" ]]; then
        outcome="INSTRUMENT-ERROR(capture failed: ${UNIT_IERR% })"; IERR_ROWS=$((IERR_ROWS + 1))
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$mode" "$stop" "$outcome" "$cause" "$((SECONDS - t0))" "$detail" >> "$OUT/results.tsv"
    printf '[%s] %s | %s | %s (%ss)\n' "$name" "$stop" "$outcome" "$(cut -c1-160 <<< "$cause")" "$((SECONDS - t0))"
}

IERR_ROWS=0
# units are read on fd 3, so no command in a unit can consume units.txt
# (every engine invocation also gets </dev/null in inv; audit L5)
while IFS='|' read -r -u 3 name mode fset tus stages; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    [[ "$name" =~ $FILTER ]] || continue
    run_unit "$name" "$mode" "$fset" "$tus" "$stages"
done 3< "$UNITS"
echo "census: results in $OUT/results.tsv"
# tally by outcome class (the text before the first "("), derived from results.tsv
awk -F'\t' 'NR > 1 { c = $4; sub(/\(.*/, "", c); n[c]++; t++ }
    END { printf "census: tally: %d programs; agreement %d; both-fail-alike %d; DISAGREEMENT %d; refusal %d; resource-limit %d; INSTRUMENT-ERROR %d; other %d\n",
          t, n["agreement"], n["both-fail-alike"], n["DISAGREEMENT"], n["refusal"], n["resource-limit"], n["INSTRUMENT-ERROR"],
          t - n["agreement"] - n["both-fail-alike"] - n["DISAGREEMENT"] - n["refusal"] - n["resource-limit"] - n["INSTRUMENT-ERROR"] }' \
    "$OUT/results.tsv" || die "tally failed"
if [[ $IERR_ROWS -gt 0 ]]; then
    echo "census: ERROR: $IERR_ROWS row(s) are INSTRUMENT-ERROR — the run is NOT a census result" >&2
    exit 1
fi
