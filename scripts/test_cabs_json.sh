#!/bin/bash
# Test the Cabs JSON bridge: OCaml serializer → Lean deserializer
#
# Usage: ./scripts/test_cabs_json.sh [options] [FILE.c ...]
#
# With no files, runs a built-in smoke test.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -euo pipefail

VERBOSE=false
FILES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help)
            echo "Usage: $0 [options] [FILE.c ...]"
            echo "  -v, --verbose  Show JSON output"
            echo "  -h, --help     Show this help"
            exit 0
            ;;
        *) FILES+=("$1"); shift ;;
    esac
done

# Build both sides
build_cerberus
build_lean

echo ""

# If no files given, create a smoke test
if [[ ${#FILES[@]} -eq 0 ]]; then
    SMOKE="$TMP_DIR/smoke_test.c"
    cat > "$SMOKE" << 'EOF'
int main(void) {
    int x = 42;
    if (x > 0) {
        x = x + 1;
    }
    return x;
}
EOF
    FILES=("$SMOKE")
    echo "Running smoke test..."
fi

pass=0
fail=0

for cfile in "${FILES[@]}"; do
    name=$(basename "$cfile")
    json_file="$TMP_DIR/${name%.c}.json"

    # Step 1: OCaml parses C → JSON
    if ! run_cerberus --cabs-json "$cfile" > "$json_file" 2>/dev/null; then
        echo -e "${RED}FAIL${NC} $name: cerberus parse error"
        fail=$((fail + 1))
        continue
    fi

    if $VERBOSE; then
        echo "--- JSON ($name) ---"
        head -20 "$json_file"
        echo "..."
        echo "---"
    fi

    # Step 2: Lean reads JSON → Cabs
    result=$(run_cerberus_lean "$json_file" 2>&1) || true

    if echo "$result" | grep -q "parse error"; then
        echo -e "${RED}FAIL${NC} $name: lean parse error"
        echo "  $result"
        fail=$((fail + 1))
    else
        echo -e "${GREEN}OK${NC}   $name"
        if $VERBOSE; then
            echo "  $result"
        fi
        pass=$((pass + 1))
    fi
done

echo ""
echo "Results: $pass passed, $fail failed"

if [[ $fail -gt 0 ]]; then
    exit 1
fi
