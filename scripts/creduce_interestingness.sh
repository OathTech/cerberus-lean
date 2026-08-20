#!/bin/bash
# creduce_interestingness.sh — interestingness predicate for creduce
# against the differential harness (arc-10 S0).
#
# Provenance: the arc-4 prototype-kit disposition
# (lean_frontend/docs/2026-08-19_arc4-prototype-kit-disposition.md)
# DEFERRED porting the prototype's creduce_interestingness.sh until the
# creduce binary existed in the sandbox ("trivially re-created against
# test_exec.sh once creduce is installable"). creduce is installed as of
# arc-10 S0 (/usr/bin/creduce, 2026-08-20); this is that re-creation.
# Unlike the prototype script (hardcoded to one bug signature), this one
# is parameterized by the harness status token so any classified csmith
# find can be reduced.
#
# creduce convention: the script is run in a scratch cwd containing the
# candidate file; exit 0 = still interesting, nonzero = not.
#
# Usage:
#   CSMITH_TEST_FILE=cs_930005.c \
#   INTERESTING_REGEX='MISMATCH' \
#     creduce /abs/path/to/scripts/creduce_interestingness.sh cs_930005.c
#
# Environment:
#   CSMITH_TEST_FILE   candidate filename in cwd (default: sole *.c here)
#   INTERESTING_REGEX  egrep pattern the harness status must match
#                      (default: 'MISMATCH|DIFF'; other useful values:
#                      'LEAN_CRASH', 'FAIL', 'LEAN_ERROR')
#   EXPECT_SNIPPET     optional: additionally require this fixed string
#                      in the harness per-file line (pins a specific
#                      divergence so creduce doesn't wander to another)
#   TIMEOUT_SECS       per-side timeout passed to test_exec.sh
#                      (default 15 — creduce mutants love infinite loops)
#   CERB_MEM_MAX       memory cap for the capped run (default 8G)
#
# NOTE: intentionally no `set -e` — nonzero exits are the signal.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEST_FILE="${CSMITH_TEST_FILE:-}"
if [[ -z "$TEST_FILE" ]]; then
    # Default: the single .c file creduce placed in this scratch dir.
    set -- *.c
    [[ $# -eq 1 && -f "$1" ]] || exit 1
    TEST_FILE="$1"
fi
[[ -f "$TEST_FILE" ]] || exit 1

INTERESTING_REGEX="${INTERESTING_REGEX:-MISMATCH|DIFF}"
export TIMEOUT_SECS="${TIMEOUT_SECS:-15}"
export CERB_MEM_MAX="${CERB_MEM_MAX:-8G}"

# csmith candidates include csmith_cerberus.h/safe_math.h relative to
# the file; creduce scratch dirs start with only the candidate.
if grep -q 'csmith_cerberus\.h' "$TEST_FILE" 2>/dev/null; then
    for h in csmith_cerberus.h safe_math.h; do
        [[ -f "$h" ]] || cp "$PROJECT_ROOT/tests/csmith/$h" . 2>/dev/null || exit 1
    done
fi

# Run the differential on the candidate alone, memory-capped (both
# sides live inside the cgroup). test_exec.sh prints one status line
# per file: "[1/1] STATUS name..." — that token is the verdict.
OUT=$("$SCRIPT_DIR/capped" "$SCRIPT_DIR/test_exec.sh" "$(pwd)/$TEST_FILE" 2>&1)
LINE=$(grep -E '^\[1/1\] ' <<<"$OUT" | head -1)
[[ -n "$LINE" ]] || exit 1

STATUS=$(awk '{print $2}' <<<"$LINE")
grep -qE "^(${INTERESTING_REGEX})$" <<<"$STATUS" || exit 1

if [[ -n "${EXPECT_SNIPPET:-}" ]]; then
    grep -qF "$EXPECT_SNIPPET" <<<"$LINE" || exit 1
fi

exit 0
