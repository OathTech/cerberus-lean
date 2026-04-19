#!/bin/bash
# Generate golden reference files for pipeline test fixtures using OCaml cerberus.
#
# For each C file in the corpus, produces:
#   cabs.json     — Cabs AST as JSON (--cabs-json)
#   ail.txt       — AIL pretty-printed (--pp=ail, via --pp_ail_out)
#   core.txt      — Core pretty-printed (--pp=core, via --pp_core_out)
#   expected.txt  — Expected return value (from --exec --batch)
#
# Outputs go to tests/fixtures/<name>/ where <name> is the C basename minus .c.
#
# Usage: ./scripts/gen_goldens.sh                    # default corpus
#        ./scripts/gen_goldens.sh tests/minimal/001-return-literal.c  # one file

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -euo pipefail

# Default corpus: a representative subset of tests/minimal/
DEFAULT_CORPUS=(
  tests/minimal/001-return-literal.c
  tests/minimal/003-arith-add.c
  tests/minimal/007-local-var.c
  tests/minimal/011-if-else.c
  tests/minimal/014-while-simple.c
  tests/minimal/016-func-simple.c
  tests/minimal/021-pointer-basic.c
  tests/minimal/023-array-read.c
  tests/minimal/025-struct-basic.c
  tests/minimal/100-int-wrap-unsigned.c
)

if [[ $# -gt 0 ]]; then
    CORPUS=("$@")
else
    CORPUS=("${DEFAULT_CORPUS[@]}")
fi

total=0
pass=0
fail=0

for src_rel in "${CORPUS[@]}"; do
    src="$PROJECT_ROOT/$src_rel"
    if [[ ! -f "$src" ]]; then
        echo "${YELLOW}skip $src_rel (not found)${NC}"
        continue
    fi

    total=$((total + 1))
    name=$(basename "$src" .c)
    dir="$PROJECT_ROOT/tests/fixtures/$name"
    mkdir -p "$dir"

    echo "--- $name ---"
    cp "$src" "$dir/source.c"

    # 1. Cabs JSON
    if run_cerberus --cabs-json "$src" > "$dir/cabs.json" 2>/dev/null; then
        echo "  cabs.json ✓"
    else
        echo "  ${RED}cabs.json FAIL${NC}"
        fail=$((fail + 1))
        continue
    fi

    # 2. AIL pretty-print
    if run_cerberus --pp=ail --pp_ail_out="$dir/ail.txt" "$src" >/dev/null 2>&1; then
        echo "  ail.txt ✓"
    else
        echo "  ${YELLOW}ail.txt skip${NC}"
    fi

    # 3. Core pretty-print
    if run_cerberus --pp=core --pp_core_out="$dir/core.txt" "$src" >/dev/null 2>&1; then
        echo "  core.txt ✓"
    else
        echo "  ${YELLOW}core.txt skip${NC}"
    fi

    # 4. Expected return value from --exec --batch
    # Batch output format: "Defined {value: \"Specified(N)\", ...}"
    result=$(run_cerberus --exec --batch "$src" 2>&1 || true)
    val=$(echo "$result" | grep -oE 'Specified\([-0-9]+\)' | head -1 | sed -E 's/Specified\(([-0-9]+)\)/\1/')
    if [[ -n "$val" ]]; then
        echo "$val" > "$dir/expected.txt"
        echo "  expected.txt ✓ ($val)"
    else
        # Could be UB or other result; record the raw batch output
        echo "$result" | head -1 > "$dir/expected.batch.txt"
        echo "  ${YELLOW}expected.txt skip (non-Defined result saved to expected.batch.txt)${NC}"
    fi

    pass=$((pass + 1))
done

echo
echo "=========================================="
echo "Generated goldens for $pass / $total fixtures"
if [[ $fail -gt 0 ]]; then
    echo "${RED}$fail failed${NC}"
    exit 1
fi
