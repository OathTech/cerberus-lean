#!/usr/bin/env bash
# run_c.sh — run one C program through both engines and show what each says.
#
#   scripts/run_c.sh [--libc] [--impl-profile NAME] [--timeout SECS] FILE.c
#
# The front door for a person: the OCaml oracle executes FILE.c, exports its parsed form
# (Cabs JSON), and the Lean port executes that. Both run exhaustively (every allowed
# execution), without the C library unless --libc is given. The script prints each engine's
# output and exit status, then says whether the two outputs are byte-identical.
#
#   --libc               link the C library on both sides (printf, malloc, string.h, ...)
#   --impl-profile NAME  default (signed plain char) or hafnium (unsigned), on both engines
#   --timeout SECS       per-engine limit (default 60)
#
# Exit status: 0 both engines printed the same non-empty output and exited alike (0, or 1 for a
# reported undefined behaviour); 1 anything else (they differ, or one failed, timed out or was
# killed); 2 the request could not be run (usage, missing build, stale generated trees).
#
# THIS IS A CONVENIENCE, NOT A GATE. "Identical" here is a byte comparison of two stdouts. The
# classified comparison the project's trust rests on (verdict sequences, UB locations, refusal
# and timeout classes, baselines) is the lanes': scripts/test_exec.sh FILE.c for the default
# mode, scripts/test_libc_exec.sh for libc mode; see scripts/LADDER.md. Nothing is built here.
# A missing build, generated trees that are stale against the sources, binaries that are not the
# ones scripts/bootstrap.sh build recorded for these sources (tools/check_driver_fresh.sh), a
# staged Core runtime that differs from its source, and the harnesses' override variables are
# each refused. The compiled C library's freshness is not checked.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIBC=0; PROFILE=""; TIMEOUT=60; FILE=""
usage() { awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"; }
die() { echo "run_c: $*" >&2; exit 2; }
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --libc) LIBC=1; shift ;;
        --impl-profile) [[ $# -ge 2 ]] || die "--impl-profile needs a name"; PROFILE="$2"; shift 2 ;;
        --impl-profile=*) PROFILE="${1#--impl-profile=}"; shift ;;
        --timeout) [[ $# -ge 2 ]] || die "--timeout needs a number of seconds"; TIMEOUT="$2"; shift 2 ;;
        --timeout=*) TIMEOUT="${1#--timeout=}"; shift ;;
        -*) die "unknown option '$1' (see --help)" ;;
        *) [[ -z "$FILE" ]] || die "one C file at a time (got '$FILE' and '$1')"; FILE="$1"; shift ;;
    esac
done
[[ -n "$FILE" ]] || { usage >&2; exit 2; }
[[ -f "$FILE" ]] || die "no such file: $FILE"
[[ "$TIMEOUT" =~ ^[1-9][0-9]*$ ]] || die "--timeout must be a positive number of seconds, got '$TIMEOUT'"
FILE="$(cd "$(dirname "$FILE")" && pwd)/$(basename "$FILE")"

ORACLE="$ROOT/_build/default/backend/driver/main.exe"
LEAN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
RUNTIME="$ROOT/_build/install/default"
[[ -d "$ROOT/_opam" ]] || die "no opam switch at $ROOT/_opam — run: scripts/bootstrap.sh switch"
[[ -x "$ORACLE" && -e "$RUNTIME/lib/cerberus-lib/runtime/libcore/std.core" ]] || die "the OCaml oracle or its runtime is not built — run: scripts/bootstrap.sh build"
[[ -x "$LEAN" ]] || die "the Lean driver is not built — run: scripts/bootstrap.sh build"
# Every engine and library path below is resolved from the repository root, as the lanes do
# (the libc metadata carries root-relative labels). FILE is absolute already.
cd "$ROOT" || die "cannot cd to $ROOT"
# Never show results from stale or substituted engines. Refused: an override variable of the
# harnesses (they replace an engine or silence the freshness check; this script has no use for
# them); generated trees that do not match the sources; a binary that is not the one recorded
# for the current sources; a staged Core runtime that differs from runtime/libcore. NOT checked:
# the compiled C library (libc.co) against runtime/libc, which only a build can establish.
for v in CERB_DRIVER_FRESH_OVERRIDE CERB_ORACLE_BIN_OVERRIDE CERB_LEAN_BIN_OVERRIDE; do
    [[ -z "${!v:-}" ]] || die "$v is set: this script does not run with the harnesses' override variables (unset it)"
done
( tools/check_lem_sync.sh --check > /dev/null 2>&1 && tools/check_lem_sync.sh --check-lean > /dev/null 2>&1 \
    && tools/check_handwritten_sync.sh > /dev/null 2>&1 ) \
    || die "the generated trees are missing or stale against the sources — run: scripts/bootstrap.sh build"
fresh=$(tools/check_driver_fresh.sh --check 2>&1) \
    || { printf '%s\n' "$fresh" | tail -6 >&2; die "a driver binary is not the one built from the current sources — run: scripts/bootstrap.sh build"; }
diff -rq runtime/libcore "$RUNTIME/lib/cerberus-lib/runtime/libcore" > "$ROOT/.tmp/run_c.runtime.$$" 2>&1 \
    || { head -5 "$ROOT/.tmp/run_c.runtime.$$" >&2; rm -f "$ROOT/.tmp/run_c.runtime.$$"; die "the staged Core runtime differs from runtime/libcore — run: scripts/bootstrap.sh build"; }
rm -f "$ROOT/.tmp/run_c.runtime.$$"

mkdir -p "$ROOT/.tmp" || die "cannot create $ROOT/.tmp"
W=$(mktemp -d "$ROOT/.tmp/run_c.XXXXXXXX") || die "mktemp failed"
trap 'rm -rf "$W"' EXIT
export CERB_MEM_MAX="${CERB_MEM_MAX:-8G}" NO_COLOR=1 TERM=dumb   # plain diagnostics, as the lanes set
oracle() { "$ROOT/scripts/capped" timeout "${TIMEOUT}s" opam exec --switch="$ROOT" -- "$ORACLE" --runtime="$RUNTIME" "$@"; }
PROFILE_ARG=(); [[ -z "$PROFILE" ]] || PROFILE_ARG=("--impl-profile=$PROFILE")
MODE_ARG=(--nolibc); LEAN_LIBC=()
if [[ $LIBC -eq 1 ]]; then
    MODE_ARG=()
    jsons=$(opam exec --switch="$ROOT" -- scripts/libc_prep.sh --jsons "$W/libcjson" 2> "$W/libc_prep.err") \
        || { cat "$W/libc_prep.err" >&2; die "scripts/libc_prep.sh --jsons failed (the pinned libc dump does not match this build)"; }
    LEAN_LIBC=(--libc "$ROOT/tests/libc/libc.core")
    while IFS= read -r j; do [[ -n "$j" ]] && LEAN_LIBC+=(--libc-tu "$j"); done <<<"$jsons"
    [[ ${#LEAN_LIBC[@]} -gt 2 ]] || die "scripts/libc_prep.sh --jsons printed no metadata files"
fi

show() {  # <title> <stdout file> <stderr file> <exit status>
    echo "== $1 (exit $4)"
    if [[ -s "$2" ]]; then sed 's/^/   /' "$2"; else echo "   (no output)"; fi
    # stderr is shown, minus the two informational lines every run prints (the oracle's timing
    # line, the Lean driver's switch report).
    if grep -v -E '^(Time spent: [0-9.]+ seconds|cerberus-lean switches: \[[a-z_, ]*\])$' "$3" > "$W/stderr.show" && [[ -s "$W/stderr.show" ]]; then
        echo "   -- stderr:"; sed 's/^/   | /' "$W/stderr.show" | head -40
        [[ $(wc -l < "$W/stderr.show") -le 40 ]] || echo "   | ... ($(( $(wc -l < "$W/stderr.show") - 40 )) more lines not shown)"
    fi
    case "$4" in
        124) echo "   -- timed out after ${TIMEOUT}s (raise with --timeout)" ;;
        137) echo "   -- killed (memory cap CERB_MEM_MAX=$CERB_MEM_MAX, or a signal)" ;;
    esac
}

echo "run_c: $FILE  [$([[ $LIBC -eq 1 ]] && echo libc || echo nolibc), exhaustive${PROFILE:+, profile $PROFILE}]"
oracle "${MODE_ARG[@]}" "${PROFILE_ARG[@]}" --exec --batch --mode=exhaustive "$FILE" > "$W/oracle.out" 2> "$W/oracle.err"; orc=$?
show "OCaml oracle" "$W/oracle.out" "$W/oracle.err" "$orc"

oracle --cabs-json "$FILE" > "$W/prog.json" 2> "$W/json.err"; jrc=$?
if [[ $jrc -ne 0 || ! -s "$W/prog.json" ]]; then
    echo "== Lean port: not run — the oracle could not export the parsed program (exit $jrc)"
    sed 's/^/   | /' "$W/json.err" | head -20
    echo "run_c: NO COMPARISON (the program did not get past the C front end)"; exit 1
fi
CERB_INSTALL_PREFIX="$RUNTIME" LEAN_ABORT_ON_PANIC=1 "$ROOT/scripts/capped" timeout "${TIMEOUT}s" \
    "$LEAN" --batch "${PROFILE_ARG[@]}" "${LEAN_LIBC[@]}" "$W/prog.json" > "$W/lean.out" 2> "$W/lean.err"; lrc=$?
show "Lean port" "$W/lean.out" "$W/lean.err" "$lrc"

echo
# Agreement = the same non-empty bytes on stdout and the same exit status, that status being 0
# (defined results) or 1 (the engines' status for a reported undefined behaviour or error
# verdict). Two timeouts, two kills or two empty outputs are not agreement.
if cmp -s "$W/oracle.out" "$W/lean.out" && [[ -s "$W/oracle.out" && $orc -eq $lrc && ( $orc -eq 0 || $orc -eq 1 ) ]]; then
    echo "run_c: IDENTICAL output from both engines, both exit $orc (a byte comparison, not the lanes' classified verdict)"
    exit 0
fi
echo "run_c: NO AGREEMENT SHOWN (oracle exit $orc, Lean exit $lrc; outputs $(cmp -s "$W/oracle.out" "$W/lean.out" && echo identical || echo differ))."
echo "       This script only compares bytes. For the classified result run: scripts/test_$([[ $LIBC -eq 1 ]] && echo libc_exec || echo exec).sh"
exit 1
