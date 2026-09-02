#!/bin/bash
# run_all.sh — sweep the MEMORY-SCALE probe corpus through measure.sh and
# write a results TSV. NON-GATING instrument (arc/mem-scale, 2026-09-01).
#
# Usage: run_all.sh [--timeout N] [--engines LIST] [--only GLOB] [--out FILE]
#   Runs classes a/b/c/d in nolibc mode and class e in libc mode; z_base in
#   both. Rows are appended as they complete (partial sweeps stay useful).
#   Needs env loaded (scripts/ce); binaries must be fresh
#   (tools/check_driver_fresh.sh --check-oracle/--check-lean), checked here
#   fail-closed before anything runs.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMEOUT_SECS=600; ENGINES="oracle,lean-first,lean-exh"; ONLY="*"
OUT="$SCRIPT_DIR/results/$(date -u +%F)_sweep.tsv"
while [[ $# -gt 0 ]]; do
    case $1 in
        --timeout) TIMEOUT_SECS=$2; shift 2 ;;
        --engines) ENGINES=$2; shift 2 ;;
        --only) ONLY=$2; shift 2 ;;
        --out) OUT=$2; shift 2 ;;
        *) echo "run_all.sh: unknown option $1" >&2; exit 2 ;;
    esac
done
"$ROOT/tools/check_driver_fresh.sh" --check-oracle >&2 || exit 1
"$ROOT/tools/check_driver_fresh.sh" --check-lean >&2 || exit 1
mkdir -p "$(dirname "$OUT")"
RUNDIR="$ROOT/.tmp/memscale/runs-sweep"
if [[ ! -s "$OUT" ]]; then
    printf '# mem-scale sweep %s host=%s cap=%s timeout=%ss engines=%s\n' \
        "$(date -u +%FT%TZ)" "$(hostname)" "${CERB_MEM_MAX:-32G}" "$TIMEOUT_SECS" "$ENGINES" > "$OUT"
    printf '# oracle=%s\n# lean=%s\n' \
        "$(sha256sum "$ROOT/_build/default/backend/driver/main.exe" | cut -c1-16)" \
        "$(sha256sum "$ROOT/lean_frontend/.lake/build/bin/cerberus-lean" | cut -c1-16)" >> "$OUT"
    printf 'probe\tmode\tengine\texit\twall_s\tmaxrss_kb\tverdict\tnote\n' >> "$OUT"
fi
# size-ascending order within a class so a killed big case comes last
for f in $(ls "$SCRIPT_DIR"/probes/$ONLY.c 2>/dev/null | awk -F_ '{n=$NF; sub(/\.c$/,"",n); print n"\t"$0}' | sort -k1,1n -s | cut -f2); do
    b=$(basename "$f" .c)
    modes=(--nolibc)
    case $b in e_*) modes=(--libc) ;; z_base) modes=(--nolibc --libc) ;; esac
    for m in "${modes[@]}"; do
        echo "[$(date -u +%T)] $b $m" >&2
        "$SCRIPT_DIR/measure.sh" "$m" --timeout "$TIMEOUT_SECS" --engines "$ENGINES" --outdir "$RUNDIR" "$f" \
            | grep -v '^cerberus-lean-proj env' | tee -a "$OUT"
    done
done
echo "results: $OUT" >&2
