# Whole-project audit evidence — 2026-09-05

Companion to [the release-gate audit](../2026-09-05_whole-project-release-gate-audit.md).
These are audit probes, not approved changes to the model or regression
baselines. The extra fuel workers are intentionally incorrect contracts
and are not reachable from the production driver.

Sources have `.txt` appended so storing a counterexample does not add it
to the project's Lean build or source-scanning gates. Copy them back to
their original filenames in a scratch directory to run them. The full
local build/test logs remain at the container project root under
`.review-evidence/2026-09-05/`; the durable files here retain the focused
counterexamples and summarized checks.

## Results

* [Strict Lem input](review_strict.lem.txt), generated
  [OCaml](review_strict.ml.txt) and [Lean](Review_strict.lean.txt),
  [OCaml main](review_strict_main.ml.txt), and
  [Lean main plus proof](ReviewStrictMain.lean.txt).
  OCaml raises and exits 2; Lean exits 0 and prints 1 even with
  `LEAN_ABORT_ON_PANIC=1`. The proof has no axioms.
  [OCaml run](strict-ocaml-run.log), [Lean interpreted run](strict-lean-run.log),
  [native Lean build](strict-native-build.log), [native Lean run](strict-native-run.log).
* [Fuel decoys](ReviewFuelDecoy.lean.txt),
  [classifier output](fuel-decoy-table.log), and
  [production policy output](fuel-decoy-policy.log).
  The standalone classifier invocation intentionally imports only
  Driver/CerbCall/CerbND/Main plus the decoy; consequently its global
  counts omit many auxiliary proof carriers. **Do not read those global
  counts as the production census.** The policy invocation imports all
  normal carriers plus the decoy and reports 83/55/14/8/6; the normal
  census is 81/54/13/8/6. Both decoys are unreachable in the real driver.
* [Actual extracted shell function, plant inputs and output](verdict-extractor-plant.log).
* [Manifest-order diagnosis](fork-manifest-order.log) and
  [independent generated-tree content comparison](generated-ocaml-independent-check.json).
* [Unit gate tail](cerberus-unit-tail.log),
  [Lem non-Lean regression result](lem-nonlean-after-build.log),
  [Lem comprehensive phase/deviation summary](lem-comprehensive-summary.log),
  [Cerberus lane summaries](cerberus-lanes-summary.log), and
  [additional lane commands and exit codes](additional-checks.json).

Lem's comprehensive suite used its pinned Lean 4.28.0; Cerberus and the
new Lean probes used 4.32.2. The native probe uses the exact Cerberus
LemLib package. Registered expected failures in the comprehensive
summary are not unconditional parity passes.

## Reproducing the strict-failure counterexample

From the container project root, after building Lem and Cerberus using
their documented recipes:

```bash
source scripts/env.sh
mkdir -p .review-evidence/2026-09-05
audit_evidence="$CERB_PROJ/cerberus-lean/lean_frontend/docs/2026-09-05_whole-project-audit-evidence"
audit_scratch="$CERB_PROJ/.review-evidence/2026-09-05"
cp "$audit_evidence/review_strict.lem.txt" "$audit_scratch/review_strict.lem"
cp "$audit_evidence/review_strict_main.ml.txt" "$audit_scratch/review_strict_main.ml"
cp "$audit_evidence/ReviewStrictMain.lean.txt" "$audit_scratch/ReviewStrictMain.lean"
cp "$audit_evidence/strict-lakefile.toml.txt" "$audit_scratch/lakefile.toml"
cp cerberus-lean/lean_frontend/lean-toolchain "$audit_scratch/lean-toolchain"
cd "$audit_scratch"
../../lem-lean/lem -wl ign -i ../../lem-lean/library/pervasives_extra.lem -ocaml -lean review_strict.lem
ocamlfind ocamlopt -package zarith -linkpkg -I ../../lem-lean/ocaml-lib/_build_zarith ../../lem-lean/ocaml-lib/_build_zarith/extract.cmxa review_strict.ml review_strict_main.ml -o review-strict-ocaml
./review-strict-ocaml
# Expected: raises Failure, exit 2. Continue in the shell after observing it.
../../cerberus-lean/scripts/capped lake build
LEAN_ABORT_ON_PANIC=1 .lake/build/bin/review-strict-lean
# Observed: prints 1, exit 0; build reports the axiom-free theorem.
```

The saved Lake file assumes exactly this two-level scratch-directory
location. Its `ReviewInput` library explicitly roots the generated
module. Use the Cerberus toolchain, not the older standalone LemLib
toolchain, when reproducing the native 4.32.2 result.

## Reproducing the classifier defects

From the project root with the same environment and scratch directory:

```bash
cp "$audit_evidence/ReviewFuelDecoy.lean.txt" "$audit_scratch/ReviewFuelDecoy.lean"
cd "$CERB_PROJ/cerberus-lean/lean_frontend"
../scripts/capped lake build fuel-forms-tool
../scripts/capped lake env lean --root="$audit_scratch" -o "$audit_scratch/ReviewFuelDecoy.olean" "$audit_scratch/ReviewFuelDecoy.lean"
cd ..
FUELFORMS_EXTRA_PATH="$audit_scratch" FUELFORMS_EXTRA_MODULES=ReviewFuelDecoy ./scripts/check_fuel_forms.sh
# Observed: exit 0, 55 MEASURED and 14 ABSORBING, with the normal
# 8 reachable-AMBIENT and 6 unreachable-AMBIENT workers unchanged.
```

This uses the instrument's existing extra-module plant hook; no semantic
source or gate source is changed. The direct counterexample statements
are kernel-checked. The defect is which *claim* the instrument infers
from those true statements.

## Verification interpretation

The ordinary unit gate remains **red** because its fork manifest list
ordering differs, even though an independent set comparison finds the
same 71 names. The independent 22-delta hash check is supplementary
evidence, not a production-gate pass. It compares existing generated
trees, not a clean upstream-Lem regeneration.

Full Tier A/B/C, pristine-vs-fork execution, consumer re-pin/build and
the concurrency branch were not certified by this review. The audit
specifies those as future release acceptance requirements.
