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
    # FUEL arc (2026-09-03): the consumer-shaped exemplar theorem over the
    # shipped pipeline (test/Unit/FuelExemplar.lean) — compile-time proof,
    # main reports success; its cone is probed by check_theorem_axioms.sh
    "fuel-exemplar-test"
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

total_pass=0
total_fail=0

for test in "${TESTS[@]}"; do
    echo
    echo "=== $test ==="
    "$SCRIPT_DIR/capped" lake build "$test" 2>&1 | tail -3
    bin="./.lake/build/bin/$test"
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

# `sorry`-token SOURCE census (FUEL arc rider, 2026-09-03; design
# lean_frontend/docs/2026-09-02_fuel-arc-design.md §5): comment-stripped
# scan of generated/ + hand-written + test + the LemLib copy, expected 0
# (the axiom gate probes sorryAx in CONES only; this sees the text).
# Fail-closed: empty scan set = FAIL.
SORRY_SH="$(dirname "$PURITY_SH")/check_sorry_token.sh"
if ! "$SORRY_SH"; then
    echo "test_unit: sorry-token gate FAILED"
    exit 1
fi

# FUEL classifier selftest (FUEL arc, 2026-09-03; design §3.4): the one
# classify_fuel_outcome every classifying lane uses, against fixture
# captures incl. the three mandated negatives. Fail-closed.
FUELCLS_SH="$(dirname "$PURITY_SH")/test_fuel_classifier.sh"
if ! "$FUELCLS_SH"; then
    echo "test_unit: FUEL classifier selftest FAILED"
    exit 1
fi

# No-fuel-numerals gate (fuel-parameter arc, 2026-09-04): no fuel numeral
# in the Lean text a consumer reasons against (seams, generated, tests,
# speclab) except Main.lean's `--fuel` default; the gate's own plant
# battery (--selftest: F1-F6 planted red, unplanted green) runs first so
# a silently vacuous gate cannot pass. Fail-closed.
NOFUEL_SH="$(dirname "$PURITY_SH")/check_no_fuel_numerals.sh"
if ! "$NOFUEL_SH" --selftest; then
    echo "test_unit: no-fuel-numerals gate SELFTEST FAILED"
    exit 1
fi
if ! "$NOFUEL_SH"; then
    echo "test_unit: no-fuel-numerals gate FAILED"
    exit 1
fi

# Fuel-parametricity pin set (fuel-parameter arc, pre-merge audit M1): the
# generated tree's ambient fuel wrappers must equal the set pinned by the
# 64 `∀ n, @f ⟨n⟩ = f_lemFuel n` examples of TotalityProofTest.lean Part 1,
# both directions (a new fuel'd function without a pin is RED; regenerate
# with scripts/gen_fuel_parametricity.py --emit). Fail-closed (vacuity
# guard inside the script).
GENPIN_PY="$(dirname "$PURITY_SH")/gen_fuel_parametricity.py"
if ! python3 "$GENPIN_PY" --check; then
    echo "test_unit: fuel-parametricity pin-set check FAILED"
    exit 1
fi

# Lakefile-roots gate (fuel-parameter arc, 2026-09-04; lem-lean fuel-measure
# record §6.4 item 8): every generated module — the `_auxiliary` obligation
# carriers included — is a Lake root, both directions; plant-tested by its
# --selftest. Fail-closed.
ROOTS_SH="$(dirname "$PURITY_SH")/check_lakefile_roots.sh"
if ! "$ROOTS_SH" --selftest; then
    echo "test_unit: lakefile-roots gate SELFTEST FAILED"
    exit 1
fi
if ! "$ROOTS_SH"; then
    echo "test_unit: lakefile-roots gate FAILED"
    exit 1
fi

# Fuel-forms gate (fuel-parameter arc C2, 2026-09-04): the consumer's
# (A)/(B)/(C) requirement made mechanical — every fuel'd worker in the compiled
# environment is MEASURED (obligation + proof, cones ⊆ the standard three),
# ABSORBING (its _zero lemma is the monad's absorbing element), or an AMBIENT
# worker that is either unreachable from the drive cone (kernel constant
# closure, mutual blocks included) or a reviewed row of
# scripts/fuel_forms_pending.txt (both directions). Plant-tested by its
# --selftest. Fail-closed.
FUELFORMS_SH="$(dirname "$PURITY_SH")/check_fuel_forms.sh"
if ! "$FUELFORMS_SH" --selftest; then
    echo "test_unit: fuel-forms gate SELFTEST FAILED"
    exit 1
fi
if ! "$FUELFORMS_SH"; then
    echo "test_unit: fuel-forms gate FAILED"
    exit 1
fi

# Totality gate (arc 3): the exec slice is partial-free (empty allowlist).
# ENFORCING and fail-closed like the gates above.
TOTALITY_SH="$(dirname "$PURITY_SH")/check_exec_totality.sh"
if ! ENFORCE=1 "$TOTALITY_SH"; then
    echo "test_unit: exec-totality gate FAILED"
    exit 1
fi

# Lem-sync gate (hotfix arc/hotfix-libc-floor, 2026-08-22):
# ocaml_frontend/generated (gitignored `make prelude-src` output) must
# be content-in-sync with the frontend .lem sources — a stale tree
# builds a wrong oracle that the arc-13 single-supply backstop floors
# wholesale (the post-merge libc.co certification failure). Stamp
# written only by the generation recipe; checker also wired into the
# dune graph (ocaml_frontend/dune lem_sync_checked -> runtime/libc .co
# rules). Self-contained and fail-closed — unlike fork-drift layer 2
# below, it never skips. Record:
# lean_frontend/docs/2026-08-22_arc13-hotfix-libc-floor.md.
LEMSYNC_SH="$PROJECT_ROOT/tools/check_lem_sync.sh"
if ! bash "$LEMSYNC_SH" --check; then
    echo "test_unit: lem-sync gate FAILED"
    exit 1
fi
# Lean-side lem-sync stamp (S-basket item 6, 2026-09-01): the same
# staleness class for lean_frontend/generated — the semantics-first
# split's finding 6 (a stale primed tree masked a real debug-lane
# movement). Recorded by `make lean-prelude-src`; fail-closed here.
if ! bash "$LEMSYNC_SH" --check-lean; then
    echo "test_unit: Lean lem-sync gate FAILED"
    exit 1
fi

# Fork-drift gate (arc-10 audit follow-up, [USER] mandate): the oracle
# surface (frontend model, ocaml_frontend, memory, util, parsers,
# backend/{common,driver,lean_export}, runtime, opam files) must equal
# the reviewed manifest scripts/fork_drift_manifest.txt (as a SET,
# C-locale canonical, duplicates fatal), and the generated-OCaml
# fork-vs-upstream deltas must match their pinned hashes (spec:
# lean_frontend/docs/2026-08-21_fork-drift-review.md §6). Fail-closed like
# the gates above — INCLUDING its prerequisites since the P0 instrument
# repair (2026-09-05, whole-project audit F4): a missing upstream remote or
# generated tree is rc 1, no longer a loud rc-0 SKIP this caller read as
# success. The development opt-in CERB_FORK_DRIFT_DEV_SKIP is explicitly
# UNSET here (env -u) so it cannot reach the gate from the ambient
# environment. Plant-tested by its --selftest (locale/order/name-drift/
# duplicate/missing-ref/missing-tree/opt-in/lem-pin plants) first.
DRIFT_SH="$(dirname "$PURITY_SH")/check_fork_drift.sh"
if ! env -u CERB_FORK_DRIFT_DEV_SKIP "$DRIFT_SH" --selftest; then
    echo "test_unit: fork-drift gate SELFTEST FAILED"
    exit 1
fi
if ! env -u CERB_FORK_DRIFT_DEV_SKIP "$DRIFT_SH"; then
    echo "test_unit: fork-drift gate FAILED"
    exit 1
fi

# Fixture-freeze gate (2026-08-31 semantics-first split; the manifest is
# scripts/fixture_corpus.sha256): the lean_frontend/corpus
# differential-fixture set must match its pinned manifest exactly.
# ENFORCING and fail-closed like the gates above.
FREEZE_SH="$(dirname "$PURITY_SH")/check_fixture_freeze.sh"
if ! "$FREEZE_SH"; then
    echo "test_unit: fixture-freeze gate FAILED"
    exit 1
fi

# Renumber-instrument plant battery (effect-retirement C2 step 3):
# check_renumber_only.py adjudicates rebaseline admissions, so its
# refusal legs are TRUST properties — the committed adversarial pairs
# (string/comment holes s5/l1/l3/l4 + the C1-era plants) must refuse
# and the positive controls must admit, forever.
RENUM_PLANTS_SH="$(dirname "$PURITY_SH")/test_renumber_plants.sh"
if ! "$RENUM_PLANTS_SH"; then
    echo "test_unit: renumber-instrument plant battery FAILED"
    exit 1
fi
