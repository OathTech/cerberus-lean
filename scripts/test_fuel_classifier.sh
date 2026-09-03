#!/bin/bash
# test_fuel_classifier.sh — selftest of the ONE fuel-exhaustion classifier
# (scripts/fuel_classify.sh classify_fuel_outcome; FUEL arc 2026-09-03,
# design lean_frontend/docs/2026-09-02_fuel-arc-design.md §3.4). A
# scripts/test_unit.sh leg. Fixture captures -> expected class, positives
# AND the three mandated negatives:
#   (n1) a non-reserved `Error {msg: …}`            -> not fuel
#   (n2) a PANIC / crash without the exact marker    -> not fuel
#   (n3) the words "fuel exhausted" inside a program's own stdout,
#        embedded quote-escaped in a Defined line     -> not fuel
# plus near-miss negatives (message with a suffix; the marker not on a
# line of its own; the panic line at exit 1). Vacuity is loud: a fixture
# whose reading is not the expected one fails this script, and the
# classifier function must exist (a missing definition is a FAIL).
# No binaries, no env beyond bash; pure string fixtures.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=fuel_classify.sh
source "$SCRIPT_DIR/fuel_classify.sh" || { echo "FAIL: fuel_classify.sh missing" >&2; exit 1; }
declare -F classify_fuel_outcome >/dev/null || { echo "FAIL: classify_fuel_outcome not defined" >&2; exit 1; }

fail=0; n=0
expect() {   # <label> <expected> <exit> <capture>
    local got; got=$(classify_fuel_outcome "$3" "$4")
    n=$((n + 1))
    if [[ "$got" == "$2" ]]; then
        printf 'ok   [%s]: exit %s -> %s\n' "$1" "$3" "${got:-<not fuel>}"
    else
        printf 'FAIL [%s]: exit %s -> got %s, expected %s\n' "$1" "$3" "${got:-<not fuel>}" "${2:-<not fuel>}" >&2
        fail=1
    fi
}

# --- positives ---------------------------------------------------------------
expect "kill: batch single execution" FUEL:kill 1 \
$'Error {msg: "lem: fuel exhausted"}'
expect "kill: batch multi-execution (one exhausted, exit 0)" FUEL:kill 0 \
$'EXECUTION 0:\nDefined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\nEXECUTION 1:\nError {msg: "lem: fuel exhausted"}'
expect "kill: non-batch human form" FUEL:kill 1 \
$'  executions: 1\n  result: Killed (error: lem: fuel exhausted)\n    at: other(lem: fuel exhausted)'
expect "kill: preceded by stderr chatter" FUEL:kill 1 \
$'(debug 0): something\nError {msg: "lem: fuel exhausted"}'
expect "panic: pure-worker sentinel, exit 134" FUEL:panic 134 \
$'lem: fuel exhausted'
expect "panic: marker among other stderr lines, exit 134" FUEL:panic 134 \
$'(debug 0): constructValue_aux: is WRONG\nlem: fuel exhausted'

# --- the three mandated negatives -------------------------------------------
expect "n1: genuine Error kill (assert)" "" 1 \
$'Error {msg: "assert() failure"}'
expect "n1b: genuine Error kill (unknown procedure)" "" 1 \
$'Error {msg: "unknown procedure: foo"}'
expect "n2: PANIC without the marker, exit 134" "" 134 \
$'PANIC at CerbMem.offsetsof CerbMem:1234:5: unknown tag'
expect "n2b: SIGSEGV, nothing captured" "" 139 ""
expect "n3: program stdout containing the words, inside a Defined line" "" 0 \
$'Defined {value: "Specified(0)", stdout: "lem: fuel exhausted\\n", stderr: "", blocked: "false"}'
expect "n3b: program stdout forging the batch line, quote-escaped" "" 0 \
$'Defined {value: "Specified(0)", stdout: "Error {msg: \\"lem: fuel exhausted\\"}", stderr: "", blocked: "false"}'

# --- near misses --------------------------------------------------------------
expect "near: message with a suffix" "" 1 \
$'Error {msg: "lem: fuel exhausted but not really"}'
expect "near: message with a prefix" "" 1 \
$'Error {msg: "not lem: fuel exhausted"}'
expect "near: panic line at exit 1 (not a crash)" "" 1 \
$'lem: fuel exhausted'
expect "near: panic marker with a prefix at exit 134" "" 134 \
$'PANIC: lem: fuel exhausted'
expect "near: loose words only" "" 134 \
$'fuel exhausted'
expect "near: empty capture, exit 0" "" 0 ""

echo "test_fuel_classifier: $n fixtures, $([[ $fail -eq 0 ]] && echo ALL OK || echo FAILURES)"
exit $fail
