#!/bin/bash
# test_csmith_corpus.sh — arc-10 S4 deterministic list-lane over the
# in-tree upstream csmith corpus (tests/csmith/small_int_arith 1192 +
# small_arrays 470 + small_mix 7 = 1669 .c files; the [AGENT] S4
# charter-ADDENDUM lane: zero generation variance, same triage
# machinery as the fresh-generation lanes).
#
# Mechanics: the corpus files include `#include "csmith.h"` (upstream
# csmith runtime); this lane materializes PREFIXED copies into a scratch
# dir with the kit's standard substitution (#define CSMITH_MINIMAL +
# csmith_cerberus.h — same shim as scripts/fuzz_csmith.sh) and runs
# scripts/test_exec.sh on it. Prefixing (sia_/sa_/smx_) is required
# because basenames collide across the three sub-corpora and baselines
# are keyed by basename.
#
# Usage: ./scripts/test_csmith_corpus.sh [--write-baseline|--check-baseline] [--max N] [--shard K/M]
#   --shard K/M   run only the K-th of M equal slices (1-based; for
#                 batching a long sweep — deterministic: files sorted)
#   --check-baseline on a partial run (--shard/--max) checks against the
#   committed baseline restricted to the run's files, fail-closed on
#   corpus/baseline drift (arc-10 S5; union of shards 1..M = full check).
#   Both drift directions are fail-closed: run files missing from the
#   baseline (slice count check) AND corpus files vanished since the
#   baseline was written (baseline-entries == corpus-TOTAL check, before
#   slicing — arc-10 audit fix, auditor B F1)
#
# Environment: TIMEOUT_SECS (default 15), SKIP_BUILD passed through.
# Baseline: scripts/exec_csmith_corpus_baseline.txt

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

BASELINE="$SCRIPT_DIR/exec_csmith_corpus_baseline.txt"
MODE=""
MAX=0
SHARD=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --write-baseline) MODE=write; shift ;;
        --check-baseline) MODE=check; shift ;;
        --max) MAX="$2"; shift 2 ;;
        --shard) SHARD="$2"; shift 2 ;;
        -h|--help) sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done
export TIMEOUT_SECS="${TIMEOUT_SECS:-15}"

HDR="$PROJECT_ROOT/tests/csmith"
STAGE=$(mktemp -d "$TMP_DIR/csmith-corpus.XXXXXXXXXX") || exit 1
register_cleanup "$STAGE"
cp "$HDR/csmith_cerberus.h" "$HDR/safe_math.h" "$STAGE/"

materialize() {   # <subdir> <prefix>
    local sub="$1" pfx="$2" f b
    for f in "$HDR/$sub"/*.c; do
        b=$(basename "$f")
        sed 's|#include "csmith.h"|#define CSMITH_MINIMAL\n#include "csmith_cerberus.h"|' \
            "$f" > "$STAGE/${pfx}_${b}"
    done
}
materialize small_int_arith sia
materialize small_arrays    sa
materialize small_mix       smx

# Deterministic file list (sorted), optional shard + max
LIST="$STAGE/list.txt"
find "$STAGE" -name '*.c' | sort > "$LIST"
TOTAL=$(wc -l < "$LIST")

# Fail-closed VANISHED-FILE direction (arc-10 audit fix, auditor B F1):
# a corpus file removed after the baseline was written is absent from
# every shard's run list, so the slice-restricted check below would
# silently drop its baseline line and the union of shards 1..M would no
# longer cover the committed baseline. Require baseline entry count ==
# corpus TOTAL before any slicing (full and partial checks alike).
if [[ "$MODE" == check ]]; then
    entries=$(grep -Evc '^[[:space:]]*(#|$)' "$BASELINE")
    if [[ "$entries" -ne "$TOTAL" ]]; then
        echo "Error: baseline $(basename "$BASELINE") has $entries entries but the corpus has $TOTAL files — corpus/baseline drift (vanished or added corpus files); refusing check" >&2
        exit 1
    fi
fi
if [[ -n "$SHARD" ]]; then
    K="${SHARD%%/*}"; M="${SHARD##*/}"
    [[ "$K" -ge 1 && "$K" -le "$M" ]] || { echo "Error: bad shard $SHARD" >&2; exit 1; }
    per=$(( (TOTAL + M - 1) / M ))
    start=$(( (K - 1) * per + 1 ))
    sed -n "${start},$((start + per - 1))p" "$LIST" > "$LIST.shard"
    LIST="$LIST.shard"
fi
if [[ "$MAX" -gt 0 ]]; then
    head -n "$MAX" "$LIST" > "$LIST.max"
    LIST="$LIST.max"
fi
echo "csmith corpus lane: $(wc -l < "$LIST") of $TOTAL files (shard='${SHARD:-all}')"

# Shard-aware baseline check (arc-10 S5): when checking a PARTIAL run
# (--shard and/or --max), check against the committed baseline
# RESTRICTED to this run's files — test_exec.sh otherwise flags every
# out-of-run baseline line as "in baseline but not tested" (a full-lane
# semantics that is correct for full runs and kept for them).
# Fail-closed integrity: every file in this run MUST have a baseline
# line (count equality), so the union of shards 1..M checks the entire
# committed baseline exactly once iff the corpus is unchanged.
if [[ "$MODE" == check && ( -n "$SHARD" || "$MAX" -gt 0 ) ]]; then
    SLICE="$STAGE/baseline.slice"
    {
        echo "# auto-generated slice (shard='${SHARD:-all}' max=$MAX) of $(basename "$BASELINE") — test_csmith_corpus.sh"
        awk 'NR==FNR { want[$1]=1; next } /^[[:space:]]*(#|$)/ { next } ($1 in want)' \
            <(sed 's|.*/||' "$LIST") "$BASELINE"
    } > "$SLICE"
    want=$(wc -l < "$LIST"); have=$(( $(wc -l < "$SLICE") - 1 ))
    if [[ "$have" -ne "$want" ]]; then
        echo "Error: baseline slice has $have entries for $want run files — corpus/baseline drift; refusing partial check" >&2
        exit 1
    fi
    BASELINE="$SLICE"
fi

ARGS=(--list "$LIST")
case "$MODE" in
    write) ARGS+=("--write-baseline=$BASELINE") ;;
    check) ARGS+=("--check-baseline=$BASELINE") ;;
esac
exec "$SCRIPT_DIR/test_exec.sh" "${ARGS[@]}"
