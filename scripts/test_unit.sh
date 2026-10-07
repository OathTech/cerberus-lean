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
    "monadic-failstop-test"
    # allocator soundness (upstream-tray draft 44, 2026-09-16): the four draft-44
    # states on the actual CerbMem.allocator; its import compiles the kernel theorem
    "allocator-soundness-test"
    # semantics-audit repairs D1 (2026-09-11): CerbFloat.of_string binary64 bit-pattern pins
    "float-literal-test"
    # semantics-audit repairs D3 (2026-09-11): Ctype_aux.are_compatible array-bound arm (finding 5)
    "are-compatible-test"
    # parser-progress-measure D4.2 (2026-09-15): the many/many1 restatement's equivalence theorems
    "many-restatement-test"
    # seam-hygiene H1 (2026-09-18): the seams' failure leaves are opaque — #guard_msgs on the
    # two failing rfl probes + `failwithI` opaque in the environment + default-arm controls
    "opaque-failure-test"
    # program-data parameters E-A (2026-09-20): the enum's compatible type is program data —
    # the design note §4 kernel pins + the retired-name negative controls
    "enum-data-test"
    # D-S: run digest as state, kernel acceptance facts and old-arity rejection.
    "run-digest-test"
    # match-pattern-arity (2026-09-20, cerberus-sl item 7): match_pattern/typecheck_pattern fail
    # closed on tuple-arity mismatch — T1–T3 by rfl, T4 negative control, T5 typing pin (runtime)
    "match-pattern-arity-test"
    # SC WP0 (2026-09-25/26): passive load/store receipts — erasure proofs + the primitive/ND
    # diagnostic; also Tier A row 13's Lean consumer. Args: fuel, iteration count, capture mode.
    "memory-access-test"
    # PNVI arc S2 (2026-10-07): the default-mode wrappers CerbMem.reconstructValue(_lemFuel) equal
    # the pre-S2 text (kernel); the retired C1 reference form; runtime controls of the PNVI helpers
    "reconstruct-legacy-test"
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
    test_args=()
    # The C-TF1 test receives its fuel explicitly: 2 is liftND + liftAction's
    # minimum, and the second run checks a larger caller-selected budget.
    if [[ "$test" == monadic-failstop-test ]]; then test_args=(2 17); fi
    # The item-7 closure round's Elet/PElet runtime routes need an ambient LemFuel; the exe
    # takes it here (no fuel numeral in test/Unit/MatchPatternArityTest.lean).
    if [[ "$test" == match-pattern-arity-test ]]; then test_args=(17); fi
    # WP0 diagnostic: the suite fuel, zero stream iterations, capture on (row 13 runs the full grid).
    if [[ "$test" == memory-access-test ]]; then test_args=(17 0 on); fi
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

# Purity gate for the execution slice (arc 2; ENFORCING since S2).
# Absolute path resolved up front (the test loop cd's around), and the
# hook FAILS CLOSED: a missing or failing script fails the suite. Its
# --selftest (17 plants on scratch copies, incl. the lem-repin-4e70bb5
# pre-merge audit's Q22 split application and Q13/Q14/Q19 unmodelled-lexeme
# refusals; 2026-10-04) runs first so a vacuous gate cannot read CLEAN.
if ! "$PURITY_SH" --selftest; then
    echo "test_unit: exec-purity gate SELFTEST FAILED"
    exit 1
fi
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

# Byte protocol and real subprocess capture plants (validation foundations).
if ! "$(dirname "$PURITY_SH")/test_gcc_capture.sh"; then
    echo "test_unit: native stream capture probes FAILED"
    exit 1
fi
if ! python3 "$(dirname "$PURITY_SH")/test_observations.py"; then
    echo "test_unit: observation codec/capture plants FAILED"
    exit 1
fi
if ! python3 "$(dirname "$PURITY_SH")/test_capture_prerequisites.py"; then
    echo "test_unit: bridge capture / generator build-status plants FAILED"
    exit 1
fi
if ! python3 "$(dirname "$PURITY_SH")/test_release.py"; then
    echo "test_unit: release runner plants FAILED"
    exit 1
fi
if ! python3 "$(dirname "$PURITY_SH")/test_failure_census.py"; then
    echo "test_unit: failure census instrument tests FAILED"
    exit 1
fi
if ! python3 "$(dirname "$PURITY_SH")/test_upstream_oracle_instrument.py"; then
    echo "ERROR: independent oracle instrument plants failed" >&2
    exit 1
fi

# Verdict-extractor selftest (P0 instrument repair 2026-09-05, whole-project
# audit F3): test_exec.sh's extract_verdict_seq must keep the WHOLE Defined
# line (value, stdout, stderr, blocked) as the VAL token — hermetic plants
# (no binaries): the audit's same-value/different-stdout pair yields distinct
# tokens (and the pre-repair extractor's collapse is reproduced so the plant
# cannot be vacuous), different-stderr, escaped payload byte-exact,
# multi-outcome order, embedded text is payload, Undefined unchanged.
# Fail-closed.
EXEC_SH="$(dirname "$PURITY_SH")/test_exec.sh"
if ! "$EXEC_SH" --selftest; then
    echo "test_unit: test_exec verdict-extractor SELFTEST FAILED"
    exit 1
fi

# No-fuel-numerals gate (fuel-parameter arc, 2026-09-04): no fuel numeral
# in the Lean text a consumer reasons against (seams, generated, tests,
# speclab) except Main.lean's `--fuel` default, and (W1, PNVI arc S1) no
# `instance` declaration of `CerbGlobal.Switches` — a speedbump against an
# accidental default switch set, not adversarially robust (Main.lean's local
# `letI` wins for every lane). The gate's own plant battery (--selftest:
# F1-F6, A1-A3, W1 planted red, unplanted green) runs first so a silently
# vacuous gate cannot pass. Fail-closed.
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
# guard inside the script). Its --selftest (6 plants, incl. the lem-repin-4e70bb5
# pre-merge audit's G2/G3/G6 wrapper shapes the strict pattern does not read,
# caught by the tolerant `LemFuel.fuel` cross-check; 2026-10-04) runs first.
GENPIN_PY="$(dirname "$PURITY_SH")/gen_fuel_parametricity.py"
if ! python3 "$GENPIN_PY" --selftest; then
    echo "test_unit: fuel-parametricity pin-set SELFTEST FAILED"
    exit 1
fi
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

# Fuel-forms gate (fuel-parameter arc C2, 2026-09-04; P0 audit-F2 repair
# 2026-09-05): the consumer's (A)/(B)/(C) requirement made mechanical — every
# fuel'd worker in the compiled environment is MEASURED (obligation of the
# contract's shape INCLUDING the argument correspondence against the wrapper's
# own body and μ = the wrapper's measure; obligation + proof cones ⊆ the
# standard three), ABSORBING = kill at zero (its _zero lemma states the WORKER
# at literal fuel 0 on its own binders = the monad's absorbing element, cone ⊆
# the standard three; propagation NOT proved — lem TODO 13), or an AMBIENT
# worker that is either unreachable from the drive cone (kernel constant
# closure, mutual blocks included) or a reviewed row of
# scripts/fuel_forms_pending.txt (both directions). Plant-tested by its
# --selftest (25 plants incl. the whole-project audit's two decoys verbatim
# and the F-1 stale-carrier plant P24, 2026-09-20).
# Fail-closed.
FUELFORMS_SH="$(dirname "$PURITY_SH")/check_fuel_forms.sh"
if ! "$FUELFORMS_SH" --selftest; then
    echo "test_unit: fuel-forms gate SELFTEST FAILED"
    exit 1
fi
if ! "$FUELFORMS_SH"; then
    echo "test_unit: fuel-forms gate FAILED"
    exit 1
fi

# Failure-reach register gate (fuel-pending close-out 2026-09-08; option C of the
# pure-failure reachability census — the TRIPWIRE of the parked twin design):
# every PURE failure site (failwithI/panic!) in the execution dependency closure
# = a row of scripts/failure_reach_register.txt with its position class (the
# census's token-level classifier, scripts/failure_position.py) and its reviewed
# reach class (UNREACHABLE-BY-INVARIANT / REACHABLE / UNKNOWN), both directions;
# a NEW site, a stale row, a moved position class, a DISCARDABLE generated
# let-binding (the F1 shape) or an unsealed class edit is RED with the rows named.
# Rebuilds the one-module reach instrument (tests/failure-probes/FailureReach.lean,
# ~6 s, ~1.8 GB under capped) — unit-scale, measured 2026-09-08 — so it rides
# here as well as in LADDER Tier B; --selftest plants first (a new site, a dead
# let, an unsealed class edit, a phantom row, an edited tally). Fail-closed.
REACH_SH="$(dirname "$PURITY_SH")/check_failure_reach.sh"
if ! "$REACH_SH" --selftest; then
    echo "test_unit: failure-reach register gate SELFTEST FAILED"
    exit 1
fi
if ! "$REACH_SH"; then
    echo "test_unit: failure-reach register gate FAILED"
    exit 1
fi

# Totality gate (arc 3): the exec slice is partial-free (empty allowlist).
# ENFORCING and fail-closed like the gates above.
if ! bash "$(dirname "$PURITY_SH")/test_version.sh"; then
    echo "test_unit: version identity tests FAILED"
    exit 1
fi
TOTALITY_SH="$(dirname "$PURITY_SH")/check_exec_totality.sh"
if ! python3 "$(dirname "$PURITY_SH")/test_exec_totality.py"; then
    echo "test_unit: exec-totality admission tests FAILED"
    exit 1
fi
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

# Pin-site agreement leg (public-readiness M9 fresh-clone test, 2026-09-25):
# the lem-lean pin must be ONE value at every site that names it — the
# fork-drift manifest's lem-pin, the Lake rev, the three lake-manifests and
# the README's newcomer pin command (the sweep had moved every machine-read
# site but not the README line; a literal newcomer then failed row 1).
# Plant-tested (--selftest), fail-closed.
PIN_SITES_SH="$(dirname "$PURITY_SH")/check_pin_sites.sh"
if ! "$PIN_SITES_SH" --selftest; then
    echo "test_unit: pin-site leg SELFTEST FAILED"
    exit 1
fi
if ! "$PIN_SITES_SH"; then
    echo "test_unit: pin-site agreement FAILED"
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

# CLI refusal witnesses (contract enforcement, CONTRACT.md §4.1, 2026-09-28):
# every CLI-refused area (--concurrency, --switches=…) must exit 2 with its
# named refusal; a control run without the flag must not be refused. Plants:
# a broken driver and a refuse-everything driver both fail it (record
# docs/2026-09-28_test-depth-actions-record.md).
CLI_REFUSALS_SH="$(dirname "$PURITY_SH")/check_cli_refusals.sh"
if ! "$CLI_REFUSALS_SH"; then
    echo "test_unit: CLI refusal witnesses FAILED"
    exit 1
fi

# Runtime resolution + library-location witnesses (bug hunt 2026-09-29, BUG-2
# and BUG-3; record docs/2026-09-29_bug-hunt-fixes-record.md §S2): the driver
# loads std.core/.impl only from `--runtime DIR` or CERB_INSTALL_PREFIX (the
# oracle's arms), never from the working directory; refuses otherwise; and
# refuses a Cabs location whose directory is suffix-library but not
# exact-library. --selftest first runs the witnesses against two plant
# drivers (one ignores the runtime, one refuses everything); both must fail.
RUNTIME_RES_SH="$(dirname "$PURITY_SH")/check_runtime_resolution.sh"
if ! "$RUNTIME_RES_SH" --selftest; then
    echo "test_unit: runtime-resolution witnesses FAILED"
    exit 1
fi

# Non-UTF-8 Cabs JSON refusal witnesses (bug hunt 2026-09-29, BUG-6 and K-5;
# record docs/2026-09-29_bug-hunt-fixes-record.md §S3): a raw byte >= 0x80 in
# a file name (#line, real path, #include) or an attribute string makes the
# oracle's cabs-json invalid UTF-8; the driver refuses (exit 2, attributed)
# instead of dying with an uncaught exception; ASCII controls agree with the
# oracle. --selftest: a pre-fix (uncaught exception) stub and a
# refuse-everything stub must both fail.
CABS_UTF8_SH="$(dirname "$PURITY_SH")/check_cabs_json_utf8.sh"
if ! "$CABS_UTF8_SH" --selftest; then
    echo "test_unit: non-UTF-8 Cabs JSON witnesses FAILED"
    exit 1
fi

# Inline-assembly refusal witnesses (2026-10-05, [USER 2026-10-05] "Re inline
# asm, this should be a loud refusal"; record
# docs/2026-10-05_asm-refusal-record.md): asm statements (basic, extended,
# asm goto) are refused by the shared desugarer in BOTH engines with the
# attributed message; asm labels on declarators are refused by the shared
# parser (no Cabs JSON). Controls agree with the oracle. --selftest: a pre-fix
# erasing stub (both engines), a Lean-only erasing stub and a
# refuse-everything stub must all fail.
ASM_REFUSAL_SH="$(dirname "$PURITY_SH")/check_asm_refusal.sh"
if ! "$ASM_REFUSAL_SH" --selftest; then
    echo "test_unit: inline-assembly refusal witnesses FAILED"
    exit 1
fi

# libc dump float-literal inventory (named deviation N3, VALIDATION.md §2b;
# bug hunt BUG-5, [USER 2026-09-30] option (3)): the pinned libc.core's float
# literals (printed with %.12g by the oracle's Core printer) must equal the
# reviewed register scripts/libc_float_literals.txt, both directions; a
# 12-significant-digit literal may not be registered EXACT-BY-SOURCE.
# --selftest: eight plants.
LIBC_FLOAT_PY="$(dirname "$PURITY_SH")/check_libc_float_literals.py"
if ! python3 "$LIBC_FLOAT_PY" --selftest || ! python3 "$LIBC_FLOAT_PY"; then
    echo "test_unit: libc dump float-literal inventory FAILED"
    exit 1
fi
