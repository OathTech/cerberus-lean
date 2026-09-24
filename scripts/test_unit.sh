#!/bin/bash
# Run all Lean unit tests under lean_frontend/test/Unit/.
# Each test is a [[lean_exe]] in lakefile.toml that exits 0 on pass.
#
# Usage: ./scripts/test_unit.sh [test-name]
#   With no args, runs all tests.
#   With a name, runs just that test (e.g. fresh-int-test).

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
    # FUEL arc (2026-09-03): the consumer-shaped exemplar theorem over the
    # shipped pipeline (test/Unit/FuelExemplar.lean) — compile-time proof,
    # main reports success; its cone is probed by check_theorem_axioms.sh
    "fuel-exemplar-test"
    "monadic-failstop-test"
    "sc-machine-test"
    "sc-adapter-test"
    # allocator soundness (upstream-tray draft 44, 2026-09-16): the four draft-44
    # states on the actual CerbMem.allocator; its import compiles the kernel theorem
    "allocator-soundness-test"
    # semantics-audit repairs D1 (2026-09-11): CerbFloat.of_string binary64 bit-pattern pins
    "float-literal-test"
    "float-representation-test"
    # semantics-audit repairs D3 (2026-09-11): Ctype_aux.are_compatible array-bound arm (finding 5)
    "are-compatible-test"
    # parser-progress-measure D4.2 (2026-09-15): the many/many1 restatement's equivalence theorems
    "many-restatement-test"
    # seam-hygiene H1 (2026-09-18): the seams' failure leaves are opaque — #guard_msgs on the
    # two failing rfl probes + `failwithI` opaque in the environment + default-arm controls
    "opaque-failure-test"
)

# ---------------------------------------------------------------------------
# Sync gate (arc-4 S5f, audit G2). Lake compiles from lean_frontend/generated/
# (srcDir), NOT from lean_frontend/ — a stale generated/ copy of a
# hand-written file silently launders edits out of the binary (observed:
# generated/Main.lean lacked the S1r floor probe; 2026-09-02: a merged
# CerbMem.lean change never reached the binary while the driver-freshness
# stamp read green). Since hotfix fix/freshness-copy-gap the gate is
# tools/check_handwritten_sync.sh — the copy set is enumerated from
# lean_frontend/handwritten_copy.manifest, the SAME file the Makefile
# recipe copies from (the inline awk parse of the Makefile that lived
# here was a second, drift-prone reader). Fail-closed: missing/empty
# manifest, a missing file on either side, any byte drift, or an
# unlisted lean_frontend/*.lean fails the suite. The same tool gates
# check_driver_fresh --record-lean/--check and common.sh build_lean.
# ---------------------------------------------------------------------------
if ! "$PROJECT_ROOT/tools/check_handwritten_sync.sh"; then
    echo "${RED}test_unit: sync gate FAILED — hand-written/generated drift; the built binary does not correspond to the sources${NC}"
    exit 1
fi

cd "$PROJECT_ROOT/lean_frontend"

if [[ $# -gt 0 ]]; then
    TESTS=("$@")
else
    TESTS=("${UNIT_TESTS[@]}")
fi

# Freshness is a precondition, including for a selected run.
"$PROJECT_ROOT/tools/check_lem_sync.sh" --check-lean
"$SCRIPT_DIR/capped" lake build "${TESTS[@]}"

# Build each requested native counterpart once. These are behavioral checks,
# not global validation campaigns attached to every selected test.
native_targets=()
sc_groups=()
for test in "${TESTS[@]}"; do
    case "$test" in
        sc-machine-test) sc_groups+=(machine) ;;
        sc-adapter-test) sc_groups+=(adapter) ;;
        core-parser-test) native_targets+=(parsers/core/location_controls/controls.exe) ;;
    esac
done
if [[ ${#sc_groups[@]} -gt 0 ]]; then
    native_targets+=(memory/concrete/sc_controls/controls.exe)
fi
if [[ ${#native_targets[@]} -gt 0 ]]; then
    "$PROJECT_ROOT/tools/check_lem_sync.sh" --check
    DUNE_CACHE=disabled "$SCRIPT_DIR/capped" dune build --root "$PROJECT_ROOT" -j 1 "${native_targets[@]}"
    for target in "${native_targets[@]}"; do
        if [[ "$target" == memory/concrete/sc_controls/controls.exe ]]; then
            for group in "${sc_groups[@]}"; do
                timeout 30 "$PROJECT_ROOT/_build/default/$target" "$group"
            done
        else
            timeout 30 "$PROJECT_ROOT/_build/default/$target"
        fi
    done
fi

total_pass=0
total_fail=0

for test in "${TESTS[@]}"; do
    echo
    echo "=== $test ==="
    bin="./.lake/build/bin/$test"
    test_args=()
    # The C-TF1 test receives its fuel explicitly: 2 is liftND + liftAction's
    # minimum, and the second run checks a larger caller-selected budget.
    if [[ "$test" == monadic-failstop-test ]]; then test_args=(2 17); fi
    if [[ "$test" == sc-machine-test ]]; then test_args=(17 64 65536); fi
    if [[ "$test" == sc-adapter-test ]]; then test_args=(64); fi
    if "$bin" "${test_args[@]}"; then
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

# Global integrity and tool selftests belong to the full/release run. A named
# unit run stops here after its selected tests and freshness checks.
if [[ $# -gt 0 ]]; then exit 0; fi

# Release-level integrity checks. Failure reach has its own Tier B lane.
for check in check_exec_purity.sh check_theorem_axioms.sh check_sorry_token.sh \
    check_no_fuel_numerals.sh check_lakefile_roots.sh check_fuel_forms.sh \
    check_fixture_freeze.sh; do
    "$SCRIPT_DIR/$check"
done
ENFORCE=1 "$SCRIPT_DIR/check_exec_totality.sh"
env -u CERB_FORK_DRIFT_DEV_SKIP "$SCRIPT_DIR/check_fork_drift.sh"
python3 "$SCRIPT_DIR/gen_fuel_parametricity.py" --check

# Tool selftests run once here in the full suite, or directly when a tool changes.
for test in test_fuel_classifier.sh test_gcc_capture.sh test_renumber_plants.sh; do
    "$SCRIPT_DIR/$test"
done
for test in test_observations.py test_capture_prerequisites.py test_release.py \
    test_failure_census.py test_upstream_oracle_instrument.py; do
    python3 "$SCRIPT_DIR/$test"
done
for test in test_exec.sh test_litmus.sh check_no_fuel_numerals.sh \
    check_lakefile_roots.sh check_fuel_forms.sh; do
    "$SCRIPT_DIR/$test" --selftest
done
env -u CERB_FORK_DRIFT_DEV_SKIP "$SCRIPT_DIR/check_fork_drift.sh" --selftest
