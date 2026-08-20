#!/bin/bash
# csmith_explore.sh — arc-10 S4 phase-1 instrument: per-configuration
# ORACLE-ONLY yield + construct-coverage measurement for csmith flag sets.
#
# Motivation ([USER], charter ADDENDUM): "the prototype's setup is NOT
# final... try a few different configurations... make csmith cover as
# much as possible." This tool measures, for one csmith configuration
# over a deterministic seed block:
#   (i)  oracle-runnable YIELD — the fraction of generated programs the
#        OCaml oracle can actually execute (same invocation as
#        test_exec.sh's oracle side: --nolibc --exec --batch
#        --mode=exhaustive, TIMEOUT_SECS per file). Only oracle-runnable
#        programs ever reach the Lean side of the differential, so yield
#        bounds differential throughput.
#   (ii) CONSTRUCT COVERAGE reaching the Lean side — source-level feature
#        markers (grep classes, defined in MARKERS below) counted over
#        the oracle-RUNNABLE subset (= exactly the programs the Lean
#        side will consume), plus a Core-level memop/action census from
#        `--pp core` over the runnable subset (which Core memory
#        operations the generated Core actually contains).
# Mismatch/finding rate is NOT measured here (needs the Lean side); the
# phase-1 shortlist gets full test_exec.sh differential runs instead.
#
# Usage:
#   ./scripts/csmith_explore.sh NAME SEED_START N OUTDIR -- <csmith flags...>
#
# Output (all under OUTDIR/NAME/):
#   gen/          the N generated programs (seeds SEED_START+1..+N)
#   status.tsv    per-file: seed <TAB> status <TAB> first-error-line
#   markers.tsv   per-file marker hit profile (runnable subset)
#   coreops.txt   distinct Core memop/create/store/load census (runnable)
#   summary.txt   the EXPLORE SUMMARY line (machine-grepable)
#
# Statuses (oracle side only):
#   OK              verdict token(s) extracted, exit consistent (runnable)
#   OK_INCONS       verdict extracted but exit inconsistent (runnable-ish,
#                   counted separately; test_exec.sh calls it CERB_INCONSISTENT)
#   SKIP_INTERNAL   "internal error" (e.g. AilEinvalid translation abort)
#   SKIP_ERROR      oracle Error{...} verdict
#   SKIP_TIMEOUT    oracle timeout (124)
#   SKIP_CRASH      oracle signal exit (134/137/139)
#   SKIP_OTHER      any other extraction failure
#
# NOTE: no `set -e` — exit codes are data (house rule, cf. test_exec.sh).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

NAME="${1:?usage: csmith_explore.sh NAME SEED_START N OUTDIR -- flags...}"
SEED_START="${2:?SEED_START}"
N="${3:?N}"
OUTDIR="${4:?OUTDIR}"
[[ "${5:-}" == "--" ]] || { echo "Error: expected -- before csmith flags" >&2; exit 1; }
shift 5
CSMITH_FLAGS=("$@")

export TIMEOUT_SECS="${TIMEOUT_SECS:-15}"
CORE_SAMPLE="${CORE_SAMPLE:-30}"   # max runnable files to census at Core level

command -v csmith &>/dev/null || { echo "Error: csmith not found" >&2; exit 1; }
HDR="$PROJECT_ROOT/tests/csmith"
[[ -f "$HDR/csmith_cerberus.h" && -f "$HDR/safe_math.h" ]] || { echo "Error: headers missing" >&2; exit 1; }

build_cerberus
RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
[[ -d "$RUNTIME_DIR" ]] || { echo "Error: runtime dir not found" >&2; exit 1; }

D="$OUTDIR/$NAME"
mkdir -p "$D/gen" || exit 1
cp "$HDR/csmith_cerberus.h" "$HDR/safe_math.h" "$D/gen/"

# --- generation --------------------------------------------------------------
for i in $(seq 1 "$N"); do
    seed=$((SEED_START + i))
    f="$D/gen/cs_${seed}.c"
    [[ -s "$f" ]] && continue   # idempotent re-runs
    csmith --seed "$seed" "${CSMITH_FLAGS[@]}" 2>/dev/null \
      | sed 's|#include "csmith.h"|#define CSMITH_MINIMAL\n#include "csmith_cerberus.h"|' \
      > "$f"
    [[ -s "$f" ]] || { echo "Error: csmith produced no output (seed $seed)" >&2; exit 1; }
done

# --- marker classes (the construct-coverage metric, defined here) ------------
# name:egrep-pattern — counted as "file exercises class" iff pattern matches
# the generated source (header excluded by construction: markers are counted
# on the .c file minus its #include line region — csmith puts all program
# text after the include; the shim header is constant across configs anyway).
MARKER_NAMES=(volatile union struct packed ptr_deref addr_of array2plus array1 goto int64 bitfield div_mod safe_math incdec compound_assn comma_in_expr embedded_assn const inline_fn float_use argc_use func_ptr)
marker_pat() {
    case "$1" in
        volatile)      echo 'volatile' ;;
        union)         echo '\bunion\b' ;;
        struct)        echo '\bstruct\b' ;;
        packed)        echo '#pragma pack' ;;
        ptr_deref)     echo '\*[gl]_[0-9]|\*\*' ;;
        addr_of)       echo '&[gl]_[0-9]' ;;
        array2plus)    echo '\[[0-9]+\]\[[0-9]+\]' ;;
        array1)        echo '\[[0-9]+\]' ;;
        goto)          echo '\bgoto\b' ;;
        int64)         echo 'u?int64_t' ;;
        bitfield)      echo ':[[:space:]]*[0-9]+[[:space:]]*;' ;;
        div_mod)       echo 'safe_(div|mod)|[^/*]/[^/*=]|%' ;;
        safe_math)     echo 'safe_(add|sub|mul|lshift|rshift|unary)' ;;
        incdec)        echo '\+\+|--' ;;
        compound_assn) echo '(\+=|-=|\*=|/=|%=|\&=|\|=|\^=|<<=|>>=)' ;;
        comma_in_expr) echo '\([^;()]*,[^;()]*\)[^;]*;' ;;   # approximate
        embedded_assn) echo '=[^=;]*[^=!<>+*/%&|^-]=[^=]' ;; # approximate
        const)         echo '\bconst\b' ;;
        inline_fn)     echo '\binline\b' ;;
        float_use)     echo '\b(float|double)\b' ;;
        argc_use)      echo '\bargc\b' ;;
        func_ptr)      echo '\(\*[[:space:]]*[gl]_[0-9]+\)[[:space:]]*\(' ;;
    esac
}

# --- oracle classification ---------------------------------------------------
: > "$D/status.tsv"
{ printf 'seed\tstatus'; for m in "${MARKER_NAMES[@]}"; do printf '\t%s' "$m"; done; printf '\n'; } > "$D/markers.tsv"

declare -A COUNT=()
OK_FILES=()
for i in $(seq 1 "$N"); do
    seed=$((SEED_START + i))
    f="$D/gen/cs_${seed}.c"
    rc=0
    out=$(timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
            --nolibc --exec --batch --mode=exhaustive "$f" 2>&1) || rc=$?
    # diagnostic line: prefer a real error line over debug chatter
    firstline=$(grep -m1 -E 'internal error|error:' <<<"$out" | cut -c1-200)
    [[ -z "$firstline" ]] && firstline=$(head -1 <<<"$out" | cut -c1-200)
    status=""
    if [[ $rc -eq 124 ]]; then status=SKIP_TIMEOUT
    elif [[ $rc -eq 134 || $rc -eq 137 || $rc -eq 139 ]]; then status=SKIP_CRASH
    elif [[ "$out" == *'internal error'* ]]; then status=SKIP_INTERNAL
    elif [[ "$out" == *'Undefined {'* || "$out" == *'value: "Specified'* || "$out" == *'value: "Unspecified'* ]]; then
        # exit-consistency per test_exec.sh expected_exit_for
        if [[ "$out" == *'EXECUTION '* ]]; then exp=0
        elif [[ "$out" == *'Undefined {'* || "$out" == *'Error {'* ]]; then exp=1
        else exp=0; fi
        if [[ $rc -eq $exp ]]; then status=OK; else status=OK_INCONS; fi
    elif [[ "$out" == *'Error {'* ]]; then status=SKIP_ERROR
    else status=SKIP_OTHER
    fi
    COUNT[$status]=$(( ${COUNT[$status]:-0} + 1 ))
    printf '%s\t%s\t%s\n' "$seed" "$status" "$firstline" >> "$D/status.tsv"
    if [[ "$status" == OK ]]; then
        OK_FILES+=("$f")
        # markers are counted on comment-stripped source (the csmith
        # "// Options:" banner would otherwise match flag names)
        stripped=$(grep -vE '^[[:space:]]*(//|/\*|\*)' "$f" | sed 's|/\*.*\*/||g')
        { printf '%s\t%s' "$seed" "$status"
          for m in "${MARKER_NAMES[@]}"; do
              if grep -qE "$(marker_pat "$m")" <<<"$stripped"; then printf '\t1'; else printf '\t0'; fi
          done
          printf '\n'; } >> "$D/markers.tsv"
    fi
done

# --- Core-level census over (a sample of) the runnable subset ---------------
: > "$D/coreops.txt"
sampled=0
for f in ${OK_FILES[@]+"${OK_FILES[@]}"}; do
    [[ $sampled -ge $CORE_SAMPLE ]] && break
    timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" \
        --nolibc --pp=core "$f" 2>/dev/null \
      | grep -oE 'memop\([A-Za-z_]+|\b(create|store|load|kill)[[:space:]]*\(' \
      | sed 's/[[:space:]]*($//;s/($//;s/(//' \
      >> "$D/coreops.txt"
    sampled=$((sampled + 1))
done
CORE_CLASSES=$(sort -u "$D/coreops.txt" | tr '\n' ',' | sed 's/,$//')

# --- marker coverage tally over runnable subset ------------------------------
OKN=${#OK_FILES[@]}
MARKER_COV=""
if [[ $OKN -gt 0 ]]; then
    col=3
    for m in "${MARKER_NAMES[@]}"; do
        hits=$(awk -F'\t' -v c=$col 'NR>1 && $c==1' "$D/markers.tsv" | wc -l)
        MARKER_COV+="$m=$hits "
        col=$((col+1))
    done
fi

SUM="EXPLORE SUMMARY: name=$NAME seeds=$((SEED_START+1))-$((SEED_START+N)) n=$N ok=${COUNT[OK]:-0} ok_incons=${COUNT[OK_INCONS]:-0} skip_internal=${COUNT[SKIP_INTERNAL]:-0} skip_error=${COUNT[SKIP_ERROR]:-0} skip_timeout=${COUNT[SKIP_TIMEOUT]:-0} skip_crash=${COUNT[SKIP_CRASH]:-0} skip_other=${COUNT[SKIP_OTHER]:-0}"
{
    echo "$SUM"
    echo "MARKERS(of ok=$OKN): $MARKER_COV"
    echo "COREOPS(sample=$sampled): $CORE_CLASSES"
    echo "FLAGS: ${CSMITH_FLAGS[*]}"
} | tee "$D/summary.txt"
