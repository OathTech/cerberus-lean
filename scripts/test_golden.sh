#!/bin/bash
# Run golden-output tests: execute the Lean pipeline on fixture C files
# and compare the return value against expected.txt.
#
# Usage: ./scripts/test_golden.sh                 # run all fixtures
#        ./scripts/test_golden.sh <fixture-name>  # run one
#        ./scripts/test_golden.sh 001-*           # glob pattern

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail  # not -e: we want to keep running through failures

fixtures_dir="$PROJECT_ROOT/tests/fixtures"

run_one() {
    local name="$1"
    local dir="$fixtures_dir/$name"

    local src="$dir/source.c"
    local expected="$dir/expected.txt"
    local cabs="$dir/cabs.json"

    if [[ ! -f "$expected" ]]; then
        echo "  ${YELLOW}skip $name: no expected.txt${NC}"
        return 2
    fi

    # Generate cabs.json if absent (caller should commit it as golden).
    if [[ ! -f "$cabs" ]]; then
        run_cerberus --cabs-json "$src" > "$cabs"
    fi

    local actual
    actual=$("$CERBERUS_LEAN_BIN" "$cabs" 2>&1 || true)
    local got
    got=$(echo "$actual" | grep -oE "return value: [-0-9]+" | awk '{print $3}' | head -1)
    local want
    want=$(cat "$expected" | tr -d '[:space:]')

    if [[ "$got" == "$want" ]]; then
        echo "  ${GREEN}✓ $name${NC} (got $got)"
        return 0
    else
        # Determine failure mode for reporting
        local fail_reason
        if echo "$actual" | grep -q "desugaring failed"; then
            fail_reason="desugar failed"
        elif echo "$actual" | grep -q "typechecking failed"; then
            fail_reason="typecheck failed"
        elif echo "$actual" | grep -q "PEcase"; then
            fail_reason="Core execution (PEcase)"
        elif echo "$actual" | grep -q "Killed"; then
            fail_reason="execution killed"
        elif [[ -n "$got" ]]; then
            fail_reason="wrong result: got $got, want $want"
        else
            fail_reason="no return value"
        fi
        echo "  ${RED}✗ $name${NC}  ($fail_reason)"
        return 1
    fi
}

# Determine which fixtures to run
if [[ $# -eq 0 ]]; then
    # All fixtures
    fixtures=$(ls -1 "$fixtures_dir" 2>/dev/null)
elif [[ "$1" == *"*"* ]]; then
    # Glob pattern
    fixtures=$(ls -1 "$fixtures_dir" 2>/dev/null | grep -E "^${1//\*/.*}$")
else
    fixtures="$@"
fi

pass=0
fail=0
skip=0

for name in $fixtures; do
    run_one "$name"
    case $? in
        0) pass=$((pass + 1)) ;;
        1) fail=$((fail + 1)) ;;
        2) skip=$((skip + 1)) ;;
    esac
done

echo
echo "=========================================="
echo "Golden tests: $pass passed, $fail failed, $skip skipped"
if [[ $fail -gt 0 ]]; then
    exit 1
fi
