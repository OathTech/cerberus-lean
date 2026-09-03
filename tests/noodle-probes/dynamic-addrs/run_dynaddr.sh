#!/bin/bash
# run_dynaddr.sh — four-engine runner for the dynamic-addrs probe directory
# (2026-09-03, branch probe/dynamic-addrs; record
# lean_frontend/docs/2026-09-03_dynamic-addrs-investigation.md). ADDITIVE,
# NON-GATING instrument: no baseline, no CI wiring. Same invocations and
# per-test memory cap as tests/parity-probes/run_probe.sh; adds the
# un-forked upstream oracle (deps/cerberus-upstream @ b9aeedcb4) and a
# Core-file mode, because the finding under test is only reachable at the
# Core level (see README.md).
#
# Per input file:
#   *.core   (1) fork oracle   cerberus --nolibc --exec --batch --mode=exhaustive
#            (2) upstream oracle, same flags
#            Lean: n/a — the Lean driver has no .core runner (Main.lean:
#            --parse-core parses only); the Lean-side Core-level instrument
#            is the --inject mode below.
#   *.c      (1) fork oracle, (2) upstream oracle (both --nolibc),
#            (3) Lean --batch and --batch --first via the cabs-json bridge,
#            (4) native gcc -std=c11 -O0 -w (exit status + stdout).
#   --inject X.core : for *.c files, run ONLY the Lean side, in libc mode,
#            with X.core in place of the pinned libc dump (--libc X.core
#            --libc-tu <12 metadata jsons from $PD_LIBCJSON>). A no-argument
#            libc function (rand) gets the Core body in X.core; the oracles
#            cannot link a .c with a .core (verbatim: "undefined startup
#            function"), so the oracle-side row is the *.core probe of the
#            same shape. gcc is skipped (the injected body is not C).
#
# Usage: run_dynaddr.sh [--timeout N] [--inject X.core] file [file ...]
# Needs env loaded (scripts/ce). Fail-closed: a missing binary/runtime/
# jsons dir is an error, never a skip. Every driver run is under
# scripts/capped at CERB_TEST_MEM_MAX (default 4G) and `timeout`.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CERB="$ROOT/_build/default/backend/driver/main.exe"
LEAN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
RUNTIME="$ROOT/_build/install/default"
# deps/cerberus-upstream lives in the container: ../deps from the main
# checkout, ../../deps from a worktrees/<repo>-<branch> checkout.
UPSTREAM="${CERB_UPSTREAM:-}"
if [[ -z "$UPSTREAM" ]]; then
    for c in "$ROOT/../deps/cerberus-upstream" "$ROOT/../../deps/cerberus-upstream" "$ROOT/../../../deps/cerberus-upstream"; do
        [[ -x "$c/_build/default/backend/driver/main.exe" ]] && { UPSTREAM="$(cd "$c" && pwd)"; break; }
    done
fi
UP_CERB="$UPSTREAM/_build/default/backend/driver/main.exe"
UP_RUNTIME="$UPSTREAM/_build/install/default"
TIMEOUT_SECS=60
INJECT=""
FILES=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --timeout) TIMEOUT_SECS=$2; shift 2 ;;
        --inject) INJECT=$2; shift 2 ;;
        *) FILES+=("$1"); shift ;;
    esac
done
die() { echo "run_dynaddr.sh: $*" >&2; exit 2; }
[[ -x "$CERB" ]] || die "fork oracle missing: $CERB (build_cerberus)"
[[ -d "$RUNTIME" ]] || die "fork runtime missing: $RUNTIME"
[[ -x "$LEAN" ]] || die "Lean driver missing: $LEAN (build_lean)"
[[ -x "$UP_CERB" ]] || die "upstream oracle missing (set CERB_UPSTREAM): $UP_CERB"
[[ -e "$UP_RUNTIME/lib/cerberus/runtime/libc/libc.co" ]] || die "upstream runtime not staged: $UP_RUNTIME (dune build cerberus.install there)"
[[ ${#FILES[@]} -gt 0 ]] || die "no input files"
[[ -z "$INJECT" || -f "$INJECT" ]] || die "inject file missing: $INJECT"
command -v gcc >/dev/null || die "gcc not found"
CAPPED=(env "CERB_MEM_MAX=${CERB_TEST_MEM_MAX:-4G}" "$ROOT/scripts/capped")
mkdir -p "$ROOT/.tmp/pd" || die "cannot create $ROOT/.tmp/pd"
strip() { grep -v '^Time spent' | grep -v 'cerberus-lean-proj env:'; return 0; }
ORACLE_FLAGS=(--nolibc --exec --batch --mode=exhaustive)
LEAN_LIBC=()
if [[ -n "$INJECT" ]]; then
    LIBCJSON="${PD_LIBCJSON:-$ROOT/.tmp/pd/libcjson}"
    [[ -d "$LIBCJSON" ]] || die "libc jsons missing: $LIBCJSON (scripts/ce scripts/libc_prep.sh --jsons $LIBCJSON)"
    LEAN_LIBC=(--libc "$INJECT")
    n=0
    for j in "$LIBCJSON"/*.json; do LEAN_LIBC+=(--libc-tu "$j"); n=$((n+1)); done
    [[ $n -eq 12 ]] || die "expected 12 libc metadata jsons in $LIBCJSON, found $n"
fi
echo "# run_dynaddr.sh: fork=$("$CERB" --version 2>/dev/null | head -1) upstream=$("$UP_CERB" --version 2>/dev/null | head -1) gcc=$(gcc --version | head -1) timeout=${TIMEOUT_SECS}s cap=${CERB_TEST_MEM_MAX:-4G}${INJECT:+ inject=$(basename "$INJECT")}"
for F in "${FILES[@]}"; do
    [[ -f "$F" ]] || { echo "no such file: $F" >&2; exit 2; }
    base=$(basename "$F")
    echo "##### $base${INJECT:+ (Lean --libc $(basename "$INJECT"))}"
    if [[ -z "$INJECT" ]]; then
        rc=0; out=$( "${CAPPED[@]}" timeout "${TIMEOUT_SECS}s" "$CERB" --runtime="$RUNTIME" "${ORACLE_FLAGS[@]}" "$F" 2>&1 ) || rc=$?
        echo "--- FORK ORACLE exit=$rc"; printf '%s\n' "$out" | strip | head -6
        rc=0; out=$( "${CAPPED[@]}" timeout "${TIMEOUT_SECS}s" "$UP_CERB" --runtime="$UP_RUNTIME" "${ORACLE_FLAGS[@]}" "$F" 2>&1 ) || rc=$?
        echo "--- UPSTREAM ORACLE exit=$rc"; printf '%s\n' "$out" | strip | head -6
    fi
    case "$F" in
    *.core)
        echo "--- LEAN n/a (no .core runner; see --inject)"
        ;;
    *.c)
        json=$(mktemp "$ROOT/.tmp/pd/dynaddr.XXXXXX.json")
        if "${CAPPED[@]}" timeout "${TIMEOUT_SECS}s" "$CERB" --runtime="$RUNTIME" --cabs-json "$F" > "$json" 2>"$json.err"; then
            for mode in "" "--first"; do
                rc=0; out=$( "${CAPPED[@]}" env LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" "$LEAN" --batch $mode ${LEAN_LIBC[@]+"${LEAN_LIBC[@]}"} "$json" 2>&1 ) || rc=$?
                echo "--- LEAN --batch${mode:+ $mode} exit=$rc"; printf '%s\n' "$out" | strip | head -6
            done
        else
            echo "--- LEAN cabs-json FAILED: $(head -c 200 "$json.err" | tr '\n' ' ')"
        fi
        rm -f "$json" "$json.err"
        if [[ -z "$INJECT" ]]; then
            bin=$(mktemp "$ROOT/.tmp/pd/dynaddr.XXXXXX.bin")
            if gcc -std=c11 -O0 -w -o "$bin" "$F" 2>"$bin.err"; then
                g_out=$(timeout 10s "$bin" 2>&1); g_exit=$?
                echo "--- GCC exit=$g_exit stdout+stderr=$(printf '%s' "$g_out" | head -c 200 | tr '\n' ' ')"
            else
                echo "--- GCC compile-failed: $(head -1 "$bin.err")"
            fi
            rm -f "$bin" "$bin.err"
        fi
        ;;
    esac
done
