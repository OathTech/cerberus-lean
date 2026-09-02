#!/bin/bash
# measure.sh — single-file peak-RSS / wall-time measurement for the
# MEMORY-SCALE arc (arc/mem-scale, 2026-09-01). NON-GATING instrument.
#
# Runs ONE .c file through the oracle (--exec --batch --mode=exhaustive)
# and the Lean exec driver (--batch --first, and --batch = exhaustive),
# each under `scripts/capped` (cgroup RSS cap, CERB_MEM_MAX, default 32G)
# and `/usr/bin/time -v`, and emits one TSV row per engine run:
#
#   probe  mode  engine  exit  wall_s  maxrss_kb  verdict  note  cpu_s
#
# exit: the wrapped command's exit (124 = timeout, 137 = cgroup kill —
# capped's OOM-KILLED/KILLED banner is preserved in the .err file), verdict: the
# batch verdict sequence (VAL:/UB: like tests/parity-probes/run_probe.sh),
# note: INTERNAL PANIC / KILLED / TIMEOUT / HANG markers from stderr and
# the time record; cpu_s: User+System seconds from /usr/bin/time -v.
#
# HANG classification (R1 amendment, charter C9 loudness interim — never
# a stack-size knob): exit 124 with cpu_s / wall_s < 0.1 is a HANG, not a
# slow run — the process stopped consuming CPU long before the timeout
# (the >7M-element front-end hang parks all threads on futexes after ~4 s
# of CPU). The rule is timeout-relative: use a timeout of at least 10x the
# CPU a genuine hang burns before parking (>= 60 s here), or a slow-but-
# working run and a hang are indistinguishable by this ratio. Fail-closed:
# a HANG row is never counted as a completed run.
#
# Usage: measure.sh [--nolibc|--libc] [--timeout N] [--engines LIST]
#                   [--outdir DIR] file.c
#   --engines: comma list of oracle,oracle-random,lean-first,lean-exh
#              (default oracle,lean-first,lean-exh; oracle-random = the
#              oracle's --mode=random single trace, the analogue of Lean
#              --first — for like-for-like single-trace comparison)
#   Needs env loaded (scripts/ce). libc mode needs $MS_LIBCJSON (the 12
#   metadata cabs-jsons from scripts/libc_prep.sh --jsons), default
#   .tmp/memscale/libcjson.
# Fail-closed: a missing binary, a failed cabs-json export, or a missing
# /usr/bin/time is an error, never a silent skip.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CERB="$ROOT/_build/default/backend/driver/main.exe"
LEAN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
RUNTIME="$ROOT/_build/install/default"
CAPPED="$ROOT/scripts/capped"
TIME=/usr/bin/time
TIMEOUT_SECS=600
MODE=nolibc
ENGINES="oracle,lean-first,lean-exh"
OUTDIR="$ROOT/.tmp/memscale/runs"
while [[ $# -gt 1 ]]; do
    case $1 in
        --nolibc) MODE=nolibc; shift ;;
        --libc) MODE=libc; shift ;;
        --timeout) TIMEOUT_SECS=$2; shift 2 ;;
        --engines) ENGINES=$2; shift 2 ;;
        --outdir) OUTDIR=$2; shift 2 ;;
        *) echo "measure.sh: unknown option $1" >&2; exit 2 ;;
    esac
done
F="${1:?usage: measure.sh [opts] file.c}"
[[ -f "$F" ]] || { echo "measure.sh: no such file: $F" >&2; exit 2; }
[[ -x "$CERB" ]] || { echo "measure.sh: oracle binary missing: $CERB" >&2; exit 2; }
[[ -x "$LEAN" ]] || { echo "measure.sh: lean binary missing: $LEAN" >&2; exit 2; }
[[ -x "$TIME" ]] || { echo "measure.sh: $TIME missing" >&2; exit 2; }
[[ -n "${GIT_CONFIG_GLOBAL:-}" ]] || { echo "measure.sh: env not loaded (run via scripts/ce)" >&2; exit 2; }
mkdir -p "$OUTDIR"
name="$(basename "$F" .c)"

ORACLE_FLAGS=(--exec --batch --mode=exhaustive)
LEAN_ARGS=()
if [[ "$MODE" == nolibc ]]; then
    ORACLE_FLAGS=(--nolibc "${ORACLE_FLAGS[@]}")
else
    LIBCJSON="${MS_LIBCJSON:-$ROOT/.tmp/memscale/libcjson}"
    [[ -d "$LIBCJSON" ]] || { echo "measure.sh: libc jsons missing at $LIBCJSON (scripts/libc_prep.sh --jsons)" >&2; exit 2; }
    LEAN_ARGS=(--libc "$ROOT/tests/libc/libc.core")
    for j in "$LIBCJSON"/*.json; do LEAN_ARGS+=(--libc-tu "$j"); done
fi

verdict_of() {  # batch output -> run-length-summarised verdict multiset,
                 # e.g. VAL:Specified(0)x4620 (exhaustive fan-outs repeat one verdict)
    grep -oE 'Undefined \{ub: "[^"]*"|Defined \{value: "[^"]*"|Error \{msg: "[^"]*"' "$1" \
      | sed -e 's/^Undefined {ub: "\(.*\)"$/UB:\1/' -e 's/^Defined {value: "\(.*\)"$/VAL:\1/' \
            -e 's/^Error {msg: "\(.*\)"$/ERR:\1/' \
      | sort | uniq -c | awk '{c=$1; $1=""; sub(/^ /,""); printf "%s%s|", $0, (c>1? "x" c : "")}' \
      | sed 's/|$//'; return 0; }

# run_one <engine> <cmd...>: runs under capped + time -v + timeout; prints TSV row
run_one() {
    local eng="$1"; shift
    local base="$OUTDIR/$name.$MODE.$eng"
    local tf="$base.time" out="$base.out" err="$base.err"
    local rc=0
    CERB_MEM_MAX="${CERB_MEM_MAX:-32G}" "$CAPPED" "$TIME" -v -o "$tf" \
        timeout "${TIMEOUT_SECS}s" "$@" > "$out" 2> "$err" || rc=$?
    local rss="" wall="" cpu=""
    if [[ -f "$tf" ]]; then
        rss=$(sed -n 's/.*Maximum resident set size (kbytes): //p' "$tf")
        local ut st_; ut=$(sed -n 's/.*User time (seconds): //p' "$tf"); st_=$(sed -n 's/.*System time (seconds): //p' "$tf")
        [[ -n "$ut" && -n "$st_" ]] && cpu=$(awk -v u="$ut" -v s="$st_" 'BEGIN{printf "%.2f", u+s}')
        local w; w=$(sed -n 's/.*Elapsed (wall clock) time (h:mm:ss or m:ss): //p' "$tf")
        # h:mm:ss.ss or m:ss.ss -> seconds
        wall=$(awk -F: -v w="$w" 'BEGIN{n=split(w,a,":"); s=0; for(i=1;i<=n;i++) s=s*60+a[i]; printf "%.2f", s}')
    fi
    local note=""
    # capped's banners: "capped: OOM-KILLED" (cap breach, the witness) or
    # "capped: KILLED" (signal death / witness unavailable) — both count
    grep -qE "capped: (OOM-)?KILLED" "$err" && note="${note}KILLED;"
    grep -q "INTERNAL PANIC" "$err" && note="${note}PANIC:$(grep -m1 -oE 'INTERNAL PANIC[^\n]*' "$err" | cut -c1-60 | tr '\t' ' ');"
    if [[ $rc -eq 124 ]]; then
        if [[ -n "$cpu" && -n "$wall" ]] && awk -v c="$cpu" -v w="$wall" 'BEGIN{exit !(w > 0 && c / w < 0.1)}'; then
            note="${note}HANG(cpu ${cpu}s of ${wall}s wall; timeout ${TIMEOUT_SECS}s);"
        else
            note="${note}TIMEOUT(${TIMEOUT_SECS}s);"
        fi
    fi
    grep -q "Out of memory\|Fatal error" "$err" "$out" 2>/dev/null && note="${note}OCAML-FATAL:$(grep -m1 -hoE '(Out of memory|Fatal error[^\n]*)' "$err" "$out" | head -1 | cut -c1-60);"
    local v; v=$(verdict_of "$out")
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$MODE" "$eng" "$rc" "${wall:-NA}" "${rss:-NA}" "${v:-NONE}" "${note:--}" "${cpu:-NA}"
}

IFS=, read -ra ENG <<< "$ENGINES"
want() { local e; for e in "${ENG[@]}"; do [[ "$e" == "$1" ]] && return 0; done; return 1; }

want oracle && run_one oracle "$CERB" --runtime="$RUNTIME" "${ORACLE_FLAGS[@]}" "$F"
want oracle-random && run_one oracle-random "$CERB" --runtime="$RUNTIME" "${ORACLE_FLAGS[@]/--mode=exhaustive/--mode=random}" "$F"

if want lean-first || want lean-exh; then
    json="$OUTDIR/$name.json"
    if ! "$CERB" --runtime="$RUNTIME" --cabs-json "$F" > "$json" 2> "$json.err"; then
        echo "measure.sh: cabs-json export FAILED for $F (see $json.err)" >&2
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$MODE" "cabs-json" "98" "NA" "NA" "NONE" "CABS-JSON-FAILED"
        exit 3
    fi
    want lean-first && run_one lean-first env LEAN_ABORT_ON_PANIC=1 "$LEAN" --batch --first ${LEAN_ARGS[@]+"${LEAN_ARGS[@]}"} "$json"
    want lean-exh   && run_one lean-exh   env LEAN_ABORT_ON_PANIC=1 "$LEAN" --batch ${LEAN_ARGS[@]+"${LEAN_ARGS[@]}"} "$json"
fi
exit 0   # the last `want … &&` must not set a spurious exit 1 when that engine is not requested
