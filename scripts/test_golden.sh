#!/bin/bash
# Run a golden-output test: execute the Lean pipeline on a fixture C file
# and compare output against expected.txt.
#
# Usage: ./scripts/test_golden.sh <fixture-name>
#   e.g. ./scripts/test_golden.sh return42
#
# Looks for tests/fixtures/<name>/source.c and tests/fixtures/<name>/expected.txt.
# If cabs.json doesn't exist, generates it via `cerberus --cabs-json`.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <fixture-name>" >&2
    exit 1
fi

name="$1"
dir="$PROJECT_ROOT/tests/fixtures/$name"

if [[ ! -d "$dir" ]]; then
    echo "Error: fixture not found: $dir" >&2
    exit 1
fi

src="$dir/source.c"
expected="$dir/expected.txt"
cabs="$dir/cabs.json"

if [[ ! -f "$src" ]]; then
    echo "Error: missing source: $src" >&2
    exit 1
fi
if [[ ! -f "$expected" ]]; then
    echo "Error: missing expected: $expected" >&2
    exit 1
fi

# Generate cabs.json if absent (caller can commit it as golden).
if [[ ! -f "$cabs" ]]; then
    echo "  generating $cabs..."
    run_cerberus --cabs-json "$src" > "$cabs"
fi

echo "  running lean pipeline on $name..."
actual=$("$CERBERUS_LEAN_BIN" "$cabs" 2>&1 || true)

# Extract the final return value line (currently the Lean pipeline prints
# "  return value: N" on success). As stages get wired up this extraction
# may need to change.
got=$(echo "$actual" | grep -oE "return value: [-0-9]+" | awk '{print $3}' || true)
want=$(cat "$expected" | tr -d '[:space:]')

if [[ "$got" == "$want" ]]; then
    echo "  ${GREEN}✓ $name PASSED${NC} (got $got)"
    exit 0
else
    echo "  ${RED}✗ $name FAILED${NC}"
    echo "    expected: $want"
    echo "    got:      ${got:-<no return value in output>}"
    echo "    full output:"
    echo "$actual" | sed 's/^/      /'
    exit 1
fi
