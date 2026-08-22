#!/bin/bash
# Run all Lean unit tests under lean_frontend/test/Unit/.
# Each test is a [[lean_exe]] in lakefile.toml that exits 0 on pass.
#
# Usage: ./scripts/test_unit.sh [test-name]
#   With no args, runs all tests.
#   With a name, runs just that test (e.g. fresh-int-test).

# Resolved before any cd (used by the exec-purity gate at the end).
PURITY_SH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check_exec_purity.sh"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -euo pipefail

# List of unit test executables (must match [[lean_exe]] names in lakefile.toml)
UNIT_TESTS=(
    "effects-proof-test"
    "totality-proof-test"
    "core-parser-test"
    "fresh-int-test"
    # arc-10 S3: pretty-printer mirrors vs recorded oracle outputs
    "pp-test"
    # arc-9 S2: the app_walk walker contract-table exercises.
    "app-walk-test"
    # arc-7 S4: T1 program-term drift gate (emit-lean-core byte-identity
    # against relsem/RelSem/T1Core.lean) + concrete differential of the
    # assembled theorem object (RelSem.T1.t1File) through callND.
    "emit-lean-core-test"
)

# arc-11 S4 (the package rehearsal): tests living in the nested
# `relsem` PACKAGE (lean_frontend/relsem/lakefile.toml) — built and
# run from that package's workspace.
RELSEM_TESTS=(
    "app-walk-test"
    "emit-lean-core-test"
)
is_relsem_test() {
    local t
    for t in "${RELSEM_TESTS[@]}"; do
        [[ "$t" == "$1" ]] && return 0
    done
    return 1
}

# ---------------------------------------------------------------------------
# Sync gate (arc-4 S5f, audit G2). Lake compiles from lean_frontend/generated/
# (srcDir), NOT from lean_frontend/ — a stale generated/ copy of a
# hand-written file silently launders edits out of the binary (observed:
# generated/Main.lean lacked the S1r floor probe). Every file in the
# Makefile's LEAN_HANDWRITTEN list (which includes Main.lean) must be
# byte-identical to its generated/ copy. Fail-closed: an unparseable
# Makefile list, a missing file on either side, or any byte drift fails
# the suite. Absolute paths throughout.
# ---------------------------------------------------------------------------
SYNC_MAKEFILE="$PROJECT_ROOT/Makefile"
SYNC_SRC_DIR="$PROJECT_ROOT/lean_frontend"
SYNC_GEN_DIR="$PROJECT_ROOT/lean_frontend/generated"
sync_list=$(awk '
    /^LEAN_HANDWRITTEN[[:space:]]*=/ { inlist=1 }
    inlist {
        line=$0
        sub(/^LEAN_HANDWRITTEN[[:space:]]*=/, "", line)
        cont = (line ~ /\\[[:space:]]*$/)
        gsub(/\\[[:space:]]*$/, "", line)
        printf "%s ", line
        if (!cont) exit
    }' "$SYNC_MAKEFILE")
# shellcheck disable=SC2206
sync_files=($sync_list)
if [[ ${#sync_files[@]} -eq 0 ]]; then
    echo "${RED}test_unit: sync gate FAILED — could not parse LEAN_HANDWRITTEN from $SYNC_MAKEFILE (fail-closed)${NC}"
    exit 1
fi
# Main.lean is in LEAN_HANDWRITTEN since S5f; keep the belt-and-braces
# append in case the Makefile list regresses to not covering it.
case " ${sync_files[*]} " in
    *" Main.lean "*) ;;
    *) sync_files+=("Main.lean") ;;
esac
sync_drift=0
for f in "${sync_files[@]}"; do
    src="$SYNC_SRC_DIR/$f"
    gen="$SYNC_GEN_DIR/$f"
    if [[ ! -f "$src" ]]; then
        echo "  SYNC: hand-written file missing: $src"
        sync_drift=$((sync_drift + 1))
    elif [[ ! -f "$gen" ]]; then
        echo "  SYNC: generated copy missing: $gen (run 'make lean-prelude-src')"
        sync_drift=$((sync_drift + 1))
    elif ! cmp -s "$src" "$gen"; then
        echo "  SYNC: DRIFT between $src and $gen (run 'make lean-prelude-src')"
        sync_drift=$((sync_drift + 1))
    fi
done
if [[ $sync_drift -gt 0 ]]; then
    echo "${RED}test_unit: sync gate FAILED — $sync_drift hand-written/generated drift(s); the built binary does not correspond to the sources${NC}"
    exit 1
fi
echo "test_unit: sync gate OK (${#sync_files[@]} hand-written files byte-identical to generated/)"

cd "$PROJECT_ROOT/lean_frontend"

if [[ $# -gt 0 ]]; then
    TESTS=("$@")
else
    TESTS=("${UNIT_TESTS[@]}")
fi

total_pass=0
total_fail=0

# arc-11 S4: THE RE-HOMED IN-BUILD AUDIT GATE — a plain `lake build`
# of the nested relsem package elaborates RelSem/Audit.lean +
# Kit/Audit (fail-closed); run before the test loop so the gate fires
# even under a filtered test selection.
echo
echo "=== relsem package build (in-build audits) ==="
if ! (cd relsem && "$SCRIPT_DIR/capped" lake build 2>&1 | tail -3); then
    echo "${RED}test_unit: relsem package build FAILED (in-build audit gate)${NC}"
    exit 1
fi

for test in "${TESTS[@]}"; do
    echo
    echo "=== $test ==="
    if is_relsem_test "$test"; then
        (cd relsem && "$SCRIPT_DIR/capped" lake build "$test" 2>&1 | tail -3)
        bin="./relsem/.lake/build/bin/$test"
    else
        "$SCRIPT_DIR/capped" lake build "$test" 2>&1 | tail -3
        bin="./.lake/build/bin/$test"
    fi
    if "$bin"; then
        echo "${GREEN}✓ $test PASSED${NC}"
        total_pass=$((total_pass + 1))
    else
        echo "${RED}✗ $test FAILED${NC}"
        total_fail=$((total_fail + 1))
    fi
done

echo
echo "=========================================="
echo "Total: $total_pass passed, $total_fail failed"
if [[ $total_fail -gt 0 ]]; then
    exit 1
fi

# Purity gate for the execution slice (arc 2; ENFORCING since S2).
# Absolute path resolved up front (the test loop cd's around), and the
# hook FAILS CLOSED: a missing or failing script fails the suite.
if ! "$PURITY_SH"; then
    echo "test_unit: exec-purity gate FAILED"
    exit 1
fi

# Axiom-cone gate (arc 2 S5a): fails closed like the purity gate.
AXIOM_SH="$(dirname "$PURITY_SH")/check_theorem_axioms.sh"
if ! "$AXIOM_SH"; then
    echo "test_unit: axiom-cone gate FAILED"
    exit 1
fi

# Totality gate (arc 3): the exec slice is partial-free (empty allowlist).
# ENFORCING and fail-closed like the gates above.
TOTALITY_SH="$(dirname "$PURITY_SH")/check_exec_totality.sh"
if ! ENFORCE=1 "$TOTALITY_SH"; then
    echo "test_unit: exec-totality gate FAILED"
    exit 1
fi

# Fork-drift gate (arc-10 audit follow-up, [USER] mandate): the oracle
# surface (frontend model, ocaml_frontend, memory, util, parsers,
# backend/{common,driver,lean_export}, runtime, opam files) must equal
# the reviewed manifest scripts/fork_drift_manifest.txt, and the
# generated-OCaml fork-vs-upstream deltas must match their pinned
# hashes (spec: notes/2026-08-21_fork-drift-review.md §6). Fail-closed
# like the gates above (a missing script/manifest fails the suite; the
# gate itself only SKIPs — loudly, rc 0 — when the upstream remote or
# a generated tree is absent).
DRIFT_SH="$(dirname "$PURITY_SH")/check_fork_drift.sh"
if ! "$DRIFT_SH"; then
    echo "test_unit: fork-drift gate FAILED"
    exit 1
fi

# Proof-size gate (arc-9 S2, design §4): slate proof files within the
# 250-line/40-step bar; Kit files fixture-free; app_walk? banned.
# ENFORCING and fail-closed like the gates above.
PROOFSIZE_SH="$(dirname "$PURITY_SH")/check_proof_size.sh"
if ! "$PROOFSIZE_SH"; then
    echo "test_unit: proof-size gate FAILED"
    exit 1
fi
