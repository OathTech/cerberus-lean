# Cerberus Lean Frontend

Current build/contract reconciliation: 2026-09-25, Cerberus
`bb487dda7c56981e76d67f53ae16e874cfe5ed61`, Lem
`67ec5de70e02e280bb348a4ba826696b76116732`; measured scope and remaining
public-install checks: [follow-up record](docs/2026-09-25_public-readiness-followup.md).

Lean 4 port of the Cerberus C semantics, generated from the same `.lem` source as the OCaml backend. The intended correspondence and its current failure/runtime limits are described in [VALIDATION.md](VALIDATION.md).

## Architecture

```
cerberus (OCaml)                    cerberus-lean (Lean)
┌──────────────────┐               ┌──────────────────────────┐
│ C parser (menhir)│──Cabs JSON──→│ CabsImport.lean           │
│ cerberus --cabs-json             │ CoreParser.lean (.core)   │
└──────────────────┘               │ Cabs_to_ail (desugar)     │
                                   │ GenTyping (typecheck)      │
                                   │ Translation (elaborate)    │
                                   │ Driver (execute)           │
                                   └──────────────────────────┘
```

**Boundary:** Cabs (parsed C AST). OCaml parses C, serializes to JSON. Lean deserializes and runs the entire semantic pipeline.

**Core text parser:** Lean parses `.core` and `.impl` files directly using `Std.Internal.Parsec`.

**Trust story:** see [VALIDATION.md](VALIDATION.md) (differential
validation + gates) and [DESIGN.md](DESIGN.md) for architecture.
Operational map:

- The root package builds the semantics: generated model + seams +
  the `cerberus-lean` driver exe (incl. `CerbCall.lean`, the driver's
  `--call` engine — a hand-written seam, not a separate lib). There is
  NO second semantics package: the reasoning-era `RelSemCore` lib was
  removed 2026-09-02 (`docs/2026-09-02_relsem-prune-record.md`; park
  tag `park/reasoning-era-20260831`).
- `speclab/` is a second Lake package (requires the semantics by
  path; git deps shared via `packagesDir = "../.lake/packages"`): the
  harness-family models/codecs/renderer and the gate exes the
  `test_speclab*.sh` differential lanes consume (`speclab/README.md`).
- PROBE RECIPE: ad-hoc probes of package files run via
  `scripts/lean_probe.sh` FROM the owning package dir (e.g. from
  `lean_frontend/`: `../scripts/lean_probe.sh MyProbe.lean`) — it
  drives `lake setup-file` (the complete per-module artifact map) +
  `lean --setup` under the memory cap. `lake build <lib>.<Mod>`
  remains correct for lib members. After moving modules between
  packages, delete the orphaned artifacts stranded in the other
  package's `.lake` tree (a stale-shadowed probe is a doctored
  instrument).
- Lake deps: `LemLib` at the immutable lem-lean revision in
  `lakefile.toml` and the three committed Lake manifests. Public clones use
  the GitHub URL; optional local redirects are development infrastructure.

## Build

Use [README.md](README.md#build-and-run-one-differential-test) for the complete first-build recipe and
local switch installation. Commands below run from the repository root,
after that installation. Lean is pinned by `lean_frontend/lean-toolchain`
(4.32.2); the opam Lem revision must match Lake's LemLib revision.

```bash
opam exec --switch=. -- make prelude-src lean-prelude-src
opam exec --switch=. -- dune build backend/driver/main.exe cerberus-lib.install
# Install worktree-locally, including when _opam is a shared symlink.
opam exec --switch=. -- dune install --prefix "$PWD/_build/local-install" cerberus-lib
# Stage the libc package used by libc-mode oracle lanes.
opam exec --switch=. -- dune build cerberus.install
CERB_MEM_MAX=32G opam exec --switch=. -- ./scripts/capped make lean-native-obj
(cd lean_frontend && CERB_MEM_MAX=32G ../scripts/capped lake build CerberusLean cerberus-lean)
# Separate package; the speclab lanes also build it themselves.
(cd lean_frontend/speclab && CERB_MEM_MAX=32G ../../scripts/capped lake build)
```

Every Lake/Lean invocation goes through `scripts/capped`; cap prerequisites
and the loud uncapped fallback are described in the README. An owned
switch is distinct from a development worktree whose `_opam` points to a
shared switch: installing into the latter changes other checkouts' tools.
Use the local install prefix above for the runtime; engine invocations use
`--runtime=_build/install/default`, staged by the two Dune build commands.
After a `dune clean`, rebuild both install targets. Manually tampering with
`_build` can defeat Dune's incremental database; clean and rebuild a damaged
owned build tree instead of trusting a cached executable.

Lem updates use an owned switch and immutable public revision as described
under [Lem backend interaction](#lem-backend-interaction). A container
`deps/lem-pinned` checkout is not part of the public build procedure.

## Testing

Tests are organized into three categories:

### Unit executables and row-1 gates

Hand-written Lean tests under `lean_frontend/test/Unit/<Name>Test.lean`.
Each is a `[[lean_exe]]` in `lakefile.toml` that exits 0 on pass. The complete
`test_unit.sh` also builds/checks the OCaml oracle and needs the explicit
fork-drift prerequisites in [VALIDATION.md](VALIDATION.md#provisioning-the-fork-drift-oracle).

```bash
opam exec --switch=. -- ./scripts/test_unit.sh
opam exec --switch=. -- ./scripts/test_unit.sh fresh-int-test
```

Current unit tests:
- `effects-proof-test` / `totality-proof-test` — compile-time checks on the exec cone, as it is today: every fuel'd wrapper is FUEL-PARAMETRIC (`@f ⟨n⟩ = f_lemFuel n` for every `n`, by rfl — the fuel-parameter arc; no default constant exists), symbolic equations hold on the total layout/typing defs, and `tagDefs` is an honest reader parameter (no hidden extern read) — i.e. totality + reader lifting, properties of this port checked by the build (not a verification layer; exe names kept for build stability)
- `monadic-failstop-test` — C-TF1 seven-arm runtime witnesses, positive controls, and failure-time state checks; `CerbFailProofs` carries the kernel propagation contracts.
- `allocator-soundness-test` — the four upstream-tray-draft-44 states evaluated on the ACTUAL `CerbMem.allocator` after remedy 1 (cursor 3/(4,4), 7/(8,8), 2/(4,4) killed out-of-memory; 8/(4,4) active at 4) with the pre-fix values quoted as the negative control; imports `CerbMemAllocatorProofs`, so the GENERAL kernel theorem `allocator_active_sound` is compiled on every run (2026-09-16).
- `Unit.NDFuelStabilityTest` (imported by `totality-proof-test`) — kernel witnesses for ND completion, ordering, state, tracing, and independent budgets; `CerbNDFuelProofs` exports the six-worker stability contracts.
- `fuel-exemplar-test` — the consumer-shaped ∀-fuel, ∀-address-space-top, ∀-digest theorem over the shipped pipeline `@drive ⟨fuel⟩` from `initial_driver_state _ top digest` (`exemplar_certified_shipped_forall (fuel) (top) (digest) (h : 8 ≤ top)`; the errno allocation + store discharged symbolically by `errnoAction_active` — address-space-bound part two C4, 2026-09-18) (test/Unit/FuelExemplar.lean)
- `fuel-forms-tool` (not a pass/fail exe: the INSTRUMENT of `scripts/check_fuel_forms.sh`) — `test/Unit/FuelFormsTool.lean` imports the compiled environment at runtime and classifies every fuel'd worker MEASURED/ABSORBING/AMBIENT with its drive-cone reachability (C2; P0 2026-09-05: MEASURED checks the argument correspondence against the wrapper's own body in MetaM, ABSORBING = "kill at zero" checks the `_zero` lemma's left-hand side and cone); the gate `lake build`s the exec entries and every carrier module and compiles its scratch decoys from source BEFORE the tool imports anything (hotfix `fix/fuel-forms-carriers` 2026-09-20, F-1: a carrier's stale `.olean` had been imported as found), and its `--selftest` P24 plants a stale-valid `.olean` over an uncompilable source
- `core-parser-test` — 292 checks for `CoreParser.lean` in the follow-up run (derived from its output)
- `opaque-failure-test` — seam hygiene (2026-09-19): `#guard_msgs` on the two FAILING `rfl` probes of the seam failure leaves (a transparent leaf would turn the build RED), `failwithI` opaque in the environment, default arms reduce; every `CerbGlobal.has_switch … = false` by `rfl` and an arm reduces to its default; `oomKill`/`STD_`/timing identities by `rfl`; the structural `BEq MemValue` agrees with the retired impl on 23 pinned pairs (exit 1 on disagreement)
- `run-digest-test` — D-S kernel acceptance equations for explicit minting, last-unit/empty rules, committed cabs-json digest shape, both entry constructors and mint preservation; old arity rejected by `#guard_msgs`.
- `fresh-int-test` — verifies `fresh_int`/`Symbol.fresh` generate unique values (+ the native-obj fresh-counter floor probe)
- `pp-test` — pretty-printer mirrors (ctype/value shapes + float formatting), plus byte/text batch escaping against an OCaml 5.4.0 all-byte transcript (`Unit.BatchEscapeTest`).

`test_unit.sh` also runs the gate scripts: the hand-written↔generated
sync gate, `check_exec_purity.sh`, `check_theorem_axioms.sh`
(hand-written axiom census — exactly 0 — + generated-tree census +
exemplar/driver2 axiom cones + the D14 non-kernel-proof-method ban),
`check_exec_totality.sh` (22 generated modules + CerbND, empty
allowlist), `check_no_fuel_numerals.sh` (fuel-parameter arc: no fuel
numeral in seams/generated/test/speclab except Main.lean's `--fuel`
default; F1–F6 plant-tested by its --selftest), `check_lakefile_roots.sh`
(every generated module, `_auxiliary` obligation carriers included, is a
Lake root; plant-tested), `check_fuel_forms.sh` (C2: the (A)/(B)/(C)
fuel-forms gate — every fuel'd worker measured, absorbing (= kill at zero;
propagation not proved, lem TODO 13), unreachable from the drive cone, or a
reviewed row of `scripts/fuel_forms_pending.txt`; C4: a worker measured
UNDER A HYPOTHESIS (lem `assuming`, the `lemHyp` binder) must equal a row of
the reviewed register `scripts/fuel_hypotheses.txt`, both directions; P0
2026-09-05 (whole-project audit F2): a MEASURED obligation must pass the
worker to the wrapper's own inputs — the wrapper's body is unfolded and its
worker call compared argument by argument, with the hypothesis' μ at the
fuel position — and an ABSORBING `_zero` lemma must state THE worker at
literal 0 on its own binders; 25 plants incl. 15 compiled decoys and the F-1 stale-carrier plant P24 (2026-09-20) — the
audit's two verbatim, wrong fuel position, swapped arguments, changed
measure, wrapper calling another worker, hidden premise, contradictory
hypothesis caught by the register, extra Prop binder, three `_zero`
decoys), the lem-sync content-hash gate,
`check_failure_reach.sh` (the failure-reach register gate, 2026-09-08: every pure
`failwithI`/`panic!` site of the exec dependency closure = a sealed, reviewed row of
`scripts/failure_reach_register.txt`, position and reach classes both directions,
DISCARDABLE generated let-bindings RED; rebuilds the one-module reach instrument,
~6 s; 5 plants), `check_fork_drift.sh` (arc-10 audit follow-up, [USER] mandate: the
oracle surface must equal the reviewed manifest
`scripts/fork_drift_manifest.txt`, and the generated-OCaml
fork-vs-upstream deltas must match their pinned hashes; loud SKIP
when the upstream remote or a generated tree is absent, fail-closed
otherwise), and `check_fixture_freeze.sh` (the `corpus/`
differential-fixture set must match its hash manifest exactly), and
`test_exec.sh --selftest` (P0 2026-09-05, audit F3: hermetic plants on the
main lane's verdict extractor — the VAL token is the WHOLE `Defined` line,
value + stdout + stderr + blocked; the pre-repair value-only collapse of the
audit's same-value/different-stdout pair is reproduced in-plant so the
battery cannot be vacuous).

### Fixture differentials

```bash
opam exec --switch=. -- ./scripts/test_verify.sh   # tests/verify + corpus/ fixture
                           # differentials: pin provenance (oracle
                           # --pp=core re-derivation byte-equal /
                           # content-hash vs the pinned dumps) +
                           # main-mode differentials + call-point
                           # differentials (Lean --call vs oracle
                           # wrapper TU vs recorded pin) — 117 checks
```

### Integration tests (C → JSON → Lean, per parser)

```bash
# Cabs JSON bridge: C → OCaml → JSON → Lean (234 tests, 100%)
opam exec --switch=. -- ./scripts/test_parse.sh              # tests/minimal (106 tests)
opam exec --switch=. -- ./scripts/test_parse.sh tests/ci     # upstream CI (128 tests)

# Core text parser integration: C → cerberus --pp core → Lean CoreParser
opam exec --switch=. -- ./scripts/test_core.sh              # tests/minimal (106 tests)
opam exec --switch=. -- ./scripts/test_core.sh tests/ci     # upstream CI (128 tests)
```

### Golden tests (full pipeline, per stage)

Golden fixtures live under `tests/fixtures/<name>/`:
- `source.c` — the C input
- `expected.txt` — expected final return value
- (intermediate goldens for each stage as they come online)

```bash
opam exec --switch=. -- ./scripts/test_golden.sh                     # run all fixtures
opam exec --switch=. -- ./scripts/test_golden.sh 001-return-literal  # run one fixture
```

### Self-test

```bash
(cd lean_frontend && .lake/build/bin/cerberus-lean)  # sizeof, memory model
```

### End-to-end pipeline test

```bash
opam exec --switch=. -- ./scripts/cerberus --cabs-json test.c > test.json
(cd lean_frontend && .lake/build/bin/cerberus-lean ../test.json)
```

## IMPORTANT: Hand-written files must be copied to `generated/`

Lake compiles from `generated/` (set via `srcDir = "generated"` in `lakefile.toml`), NOT from `lean_frontend/` directly. Hand-written files live in `lean_frontend/` and are copied into `generated/` by the Makefile.

**After editing any hand-written file, you MUST copy it:**
```bash
cp CoreParser.lean generated/CoreParser.lean   # or whichever file you changed
```

Or copy all hand-written files at once:
```bash
make lean-prelude-src   # from project root
```

If you skip this step, Lake will compile the stale `generated/` copy and your changes will have no effect. Do NOT use symlinks — they break `lake update`.

**Since 2026-09-02 this is GATED, not just documented** (hotfix
`fix/freshness-copy-gap`, `docs/2026-09-02_freshness-copy-gap.md`): the
copy set is `lean_frontend/handwritten_copy.manifest` — the one list the
Makefile copies from — and `tools/check_handwritten_sync.sh` requires
every listed file to be byte-identical to its `generated/` copy (and
every `lean_frontend/*.lean` to be listed; empty manifest = FAIL). It
runs as a precondition of `scripts/common.sh build_lean` (refuses to
build), inside `tools/check_driver_fresh.sh --record-lean/--check` (no
freshness stamp over a stale copy), and as `test_unit.sh`'s sync gate.
Adding a hand-written file = add it to the manifest, or the gate names
it. The gap it closed: a merge changed `CerbMem.lean`, `build_lean` ran
without `make lean-prelude-src`, and the freshness stamp read green over
a binary built from the old copy.

## Key files

### Hand-written Lean (in `lean_frontend/`, copied to `generated/` by Makefile)

| File | Purpose |
|------|---------|
| `CerberusImpl.lean` | LP64 implementation-defined behaviour (sizeof, alignof, etc.) |
| `CerbMem.lean` | Concrete memory model (byte-level load/store, allocation). Address-space-bound slice (2026-09-17): the address-space top is a PARAMETER — `initialMemState (addressSpaceTop : Int)`, `MemState.lastAddress` has NO default (a `{ … : MemState }` literal must give it; tests choose named values) — threaded from `initial_driver_state sup top …` and the desugar state; the one Lean numeral is Main.lean's `defaultAddressSpaceTop`. Arc-14 F1: the pre-doctrine F-row is re-mirrored — relational ptr kill-paths, checked per-byte memcpy/memcmp, MerrUndefinedRealloc, real update_prefix, byte asserts, sizeof/alignof assert-parity; F4: OCaml-(=)-parity leaf instances + the memory-model instance caveat (relocated here). Seam hygiene (2026-09-19, `docs/2026-09-18_seam-hygiene-record.md`): every failure leaf is LemLib's opaque `failwithI` (no kernel equation); the switch-conditioned arms are explicit `if has_switch … then <loud kill> else <default>`; `oomKill` names the allocator's kill; `BEq MemValue` is the structural `beqMemValue` |
| `CerbMemAllocatorProofs.lean` | The concrete allocator's soundness contract (allocator-soundness slice, 2026-09-16; upstream-tray draft 44): `allocator_active_sound` — an ACTIVE allocation is `align`-aligned, positive, its end at or below the cursor (disjoint from everything at or above it, for `sz ≥ 0`), and becomes the cursor — and `allocator_below_request_kills` (remedy 1 in kernel terms), one GENERAL statement each from `Int.emod_nonneg`/`Int.emod_def` + `omega`; `allocatorStep` observes the one monadic node (the `CerbFail.step` shape, restated so the seam depends on `CerbMem` alone). Imported by the runtime witness `test/Unit/AllocatorSoundnessTest.lean` |
| `CerbTags.lean` | Mutable tag definitions state (struct/union defs) |
| `CerbDebug.lean` | Debug level and output functions |
| `CerbDecode.lean` | Integer/character constant decoding. Arc-14 F2: decode.ml's exhaustive fail-CLOSED table with C11 cites; `\?` -> 63 and hex escaped_char are documented Lean-right divergences (oracle-wrong: upstream tray 10/11) |
| `CerbGlobal.lean` | The DEFAULT configuration and switch set as plain `def`s (execution mode `none`, every flag `false`, switch set `[]`), each with a `rfl` lemma — the values the oracle driver holds in matched mode, cited line by line; no process state since 2026-09-05 (`docs/2026-09-05_cerbglobal-defs-record.md`); `CerbSwitch` = the lem subset + the four switches impl_mem.ml's switch-conditioned arms test (seam-hygiene H2, 2026-09-19), each `has_switch_*_eq : … = false := rfl`, so `CerbMem` writes those arms as `if has_switch … then <loud kill> else <default>` |
| `CerbFloat.lean` | IEEE 754 float operations; lawful total Ord Float (NaN reflexive, arc-14 F4) |
| `CerbUtils.lean` | Timing/logging VALUE IDENTITIES (plain `def`s since seam-hygiene H3, 2026-09-19; no opaque, no `IO.Ref`), GCC builtins on Z/two's-complement semantics mirroring ocaml_gcc_builtins.ml per-line (arc-14 F2: ffs(-1)=1, ctz(0)/bswap asserts panic) |
| `CerbPP.lean` | Pretty-printer placeholders |
| `CerbFS.lean` | In-memory filesystem model |
| `CerbConcurrency.lean` | Concurrency stubs |
| `CerbCtypeInstances.lean` | BEq (annotation-insensitive ctypeEqual) + lawful derived Ord for mutual ctype types (arc-14 F4; the old unlawful eq-else-lt order is gone) |
| `CerbCabsInstances.lean` | BEq for Cabs enum types |
| `CabsImport.lean` | JSON → Cabs AST deserializer |
| `CoreParser.lean` | Core text parser (Parsec). Arc-14 F3: pre-parse symbol-hash collision TRIPWIRE (String.hash is MurmurHash64A(11) — collisions constructible; parseFile fail-stops, tests/immaculate/g6 pins it) |
| `CerbND.lean` | Exhaustive ND runner (+ runND1 single-trace, arc-5 `--first`); fuel-TOTALIZED in arc-7 S2 (runNDFuel + wrappers at the ambient `[LemFuel]` fuel since the fuel-parameter arc; the distinguished kill at exhaustion) — no `partial` allowed (totality gate scans it); the FUEL contract: runner leaves + fuel-parametricity pins |
| `CerbCall.lean` | The `--call <f> [--call-args <ints>]` entry (`CerbCall.driveCall`): `drive` with the startup symbol resolved by name + the elaborated-call-site caller protocol for the parameters. Port-side harness entry (the OCaml driver has no such mode; test_verify.sh checks it against an oracle-run wrapper TU). Relocated 2026-09-02 from the removed `relsemcore/` |
| `CerbFunMapInstances.lean` | Arc-7 S2: real SetType instance for generic_fun_map_decl (evicts the lem backend's sorried fallback from initial_driver_state's cone) |
| `CerbStepInstances.lean` | OCaml-poly-eq-parity instances for core_step2 (arc 4) |
| `CerbLocation.lean` | Source location type; structural lawful Ord (arc-14 F4; was repr-string compare) |
| `CerberusFresh.lean` | FRONTEND digest reads, installation and MD5 conversion; runtime minting receives `core_run_state.sym_digest` as data (D-S, 2026-09-22) |
| `Ctype_lemMeasureProofs.lean`, `Core_lemMeasureProofs.lean`, `Defacto_memory_aux_lemMeasureProofs.lean`, `Utils_…`, `Core_run_aux_…`, `Core_reduction_…`, `Defacto_memory_…`, `Core_aux_…`, `Core_eval_lemMeasureProofs.lean`, `AilTypesAux_…`, `Formatted_…`, `Monadic_parsing_lemMeasureProofs.lean` (the two parser workers under `CerbParserProgress.Consumes`), `Driver_lemMeasureProofs.lean` | The `fuel_measure` sufficiency proofs the generated `*_auxiliary.lean` obligation shells import (fuel-parameter arc C1/C2; one module per lem module with measured functions — the build fails without them, by design; 38 generated obligations). Template: the C2 record §4 / `Core_run_aux_lemMeasureProofs.lean` (strong induction on the derived size, `key` + `size_lt`, `split` for multi-discriminant matches, `to_congr` for list traversals); kernel-only tactics, no option bumps |
| `CerbParserProgress.lean` | Props-only seam for the printf parser combinators (parser-progress-measure slice, 2026-09-15): `Consumes p` (every result strictly shortens the input) and `NonExpanding p`, the hypothesis of the MEASURED `many_run`/`many1_run` (`monadic_parsing.lem`, `2 * List.length cs + 2` / `+ 1`); closure lemmas over every combinator and the four printf call-site theorems (`callSites_consume`). Imported by `Monadic_parsing_lemMeasureProofs`, not by `extra_import` (it states Props over `Monadic_parsing.parserM`, so the generated module cannot import it) |
| `CerbCoreShape.lean` | SHAPE predicates on Core terms (`IsValuePexpr`, `IsPureExpr`, `AllPureExprs`): the hypothesis vocabulary of the measured-under-hypothesis `hack`/`to_pure`/`to_pures` (fuel-pending close-out 2026-09-08); the invariant they rest on — `prepare_exit` (driver.lem:1309-1316), the only exit of `driver2` — is cited in its header and in `scripts/fuel_hypotheses.txt` |
| `CerbCoreMeasure.lean` | The executable fuel MEASURE of the `get_ctx`/`get_ctx_unseq_aux` context-search block (`getCtxBound`: the block's call DEPTH, a structural definition over the Core AST — one unit per worker frame, the maximum over the possible children; fuel-measure-cost arc, landed 2026-09-08) with its `getCtxNext` specification and the `getCtxBound_pos`/`getCtxBound_child_lt` lemmas; imported by the generated `Core_reduction` via `declare {lean} extra_import` — the qualified-helper form lem's FM-free measure validator accepts (no macro, no `WellFounded.fix`) |
| `CerbMeasureLemmas.lean` | The shared toolbox of those proofs: membership-relative congruences, the derived list helpers' member bounds, positivity, `unatomic_size_le`, the `size_lt` discharger and the bounded `to_congr` descent (C2) |
| `CerbMem_lemMeasureProofs.lean` | The hand-written MEASURED seams' sufficiency theorems: `CerbMem.typeofMval/unqualifyAndUnatomic/memValueToBytes_measure_sufficient` and the six layout/reconstruct obligations under `CerbTagsWf.Acyclic`/`AcyclicPair` (rows 1–6 of `scripts/fuel_hypotheses.txt`), same shape and namespace rule as the generated ones — the fuel-forms gate classifies them by the same rule. A Lake root NOTHING imports: built by `build_lean` (every root, 2026-09-20) and by the fuel-forms gate itself (H1, every carrier it imports) — it did not compile from seam-hygiene H1 to 2026-09-20 while its stale `.olean` was imported (hotfix `fix/fuel-forms-carriers`, `docs/2026-09-20_fuel-forms-carriers-hotfix-record.md`). The reconstruct proof needs no equation about the opaque failure leaves: `reconstructValue_lemFuel`'s struct/union arms guard the tag lookup / select the union member BEFORE recursing (option (d)), so every leaf is a whole, fuel-independent result |
| `Main.lean` | Driver: self-test, parse, desugar pipeline; `--fuel N` (the ONE fuel numeral: `defaultFuel` = 10^8, the harness default; the run's `[LemFuel]` instance is built once here); `--address-space-top N` (the ONE address-space numeral: `defaultAddressSpaceTop` = upstream's `0xFFFFFFFFFFFF`, passed to BOTH entry points — `desugar` for the const-expr mini-run and `initial_driver_state` for the run; address-space-bound slice 2026-09-17); D-S (2026-09-22): `runDigest tunits` (pure selector in `CabsImport.lean`) chooses the last program TU, empty without one; forwarded to `initial_driver_state sup top digest file fs` (digest is the second explicit parameter after top) and `CerbCall.driveCall` |

### Lem modifications (in `frontend/model/`)

`declare lean target_rep` maps Lem functions to hand-written Lean:
- `ctype_aux.lem` — tagDefs → CerbTags
- `debug.lem` — get_level, print_debug → CerbDebug
- `decode.lem` — decode_integer_constant → CerbDecode
- `implementation.lem` — alignof_ty → CerberusImpl
- `std.lem` — module renamed to Lem_Std (avoids shadowing Lean's Std)

`declare {lean} skip_instances type T` suppresses auto-generated instances:
- `ctype.lem` — ctype_/ctype (we provide real BEq/Ord)

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/LADDER.md` | THE test-ladder tiers (arc-6 S4): Tier A fast ladder (every commit), Tier B slow ladder (slice boundaries / close-out / pre-merge), Tier C reporting instruments — the normative meaning of "fast/slow ladder" |
| `scripts/common.sh` | Shared helpers (build, run, paths). `build_lean` builds EVERY Lake root + the exe (`lake build CerberusLean cerberus-lean`, hotfix 2026-09-20 on the audit's M2: a root nothing imports — `CerbMem_lemMeasureProofs`, `CerbConcurrency`, `Cabs_to_ail_auxiliary` — can no longer go stale unnoticed; measured 17 s first pass / 1 s steady on a warm tree; its content is pinned in `scripts/fork_drift_manifest.txt`, re-pinned with a dated NOTE) |
| `scripts/test_parse.sh` | Test Cabs JSON bridge on .c files |
| `scripts/test_core.sh` | Test Core text parser: C → --pp core → Lean |
| `scripts/test_multi_tu.sh` | Differential multi-TU linking: N .c linked by OCaml vs N cabs-jsons linked by the Lean pipeline (corpus: `tests/multi_tu/<name>/`) |
| `scripts/libxml2_prep.sh` | libxml2 no-autogen prep: pinned config (`tests/libxml2/config/`) + cerberus args per TU (probe recipe) |
| `scripts/test_libxml2.sh` | Arc-5 exit-criterion differential: chvalid.c + generated boundary battery (4 slices since arc-6 S3, 1354 points), single-trace both sides (~8 min; Tier B slow ladder since arc-6 S4 — see scripts/LADDER.md) |
| `scripts/test_libxml2_uri.sh` | Arc-6 GATE (S4, charter success condition 1): 5-TU xmlParseURISafe corpus grown to 16 URIs (RFC 3986 edge classes), 4 lanes (oracle+libc / ocaml-nolibc / lean-nolibc mirrored-failure pair / lean+libc) — pinned per-lane expectations + baseline drift check, fail-closed; 16/16 byte-identical lean+libc vs oracle. Oracle invocations use the ordinary single-supply renumbering path; arc-13 removed the arc-12 grandfather exception. |
| `scripts/libc_prep.sh` | Arc-6 S1: pins + drift-checks `tests/libc/libc.core` (the oracle's unlinked libc Core text dump) and emits the 12 libc metadata TU cabs-jsons (see Main.loadLibc). Arc-13 audit fix (B-F5): the pin's identity is a CONTENT HASH (`tests/libc/libc.core.sha256`, sha256 of the dump text, rebuild-independent — a clean rebuild re-deriving the same text passes with no re-pin); the libc.co version header is logged informationally only (the old `.co.version` version-string pin is deleted) |
| `scripts/test_libc_exec.sh` | Arc-6 S1 differential: C-with-libc programs, both sides load the C library (`tests/libc_exec/`, own baseline; NEW mode — standing corpora stay --nolibc) |
| `scripts/test_cabs_json.sh` | Quick smoke test |
| `scripts/test_bytes.sh` | Arc-10 S3b: oracle-INDEPENDENT tests/bytes micro-lane — 9 exec files byte-compared to the committed upstream `.exec` records (+ 5 front-end-reject negative pins), fail-closed both directions (Tier A row 4c). tests/float is a plain test_exec.sh lane (`--check-baseline=scripts/exec_float_baseline.txt tests/float`, Tier A row 4b) |
| `scripts/test_csmith_corpus.sh` | Arc-10 S4: deterministic differential lane over the 1669 in-tree upstream csmith programs (prefixed materialization + kit header shim); committed classified baseline `scripts/exec_csmith_corpus_baseline.txt` (re-baselined arc-12 S1 under the F-D floor: 516 CERB_FLOOR rows, movement table in its header); `--shard K/M` with shard-aware fail-closed baseline check (S5) |
| (oracle single-supply backstop, arc-13; was the arc-12 F-D floor) | `util/cerb_fresh.ml` `check_ail_window` + `backend/common/ail_sym_hwm.ml` (digest-filtered (min,max) symbol-window fold) + `pipeline.ml` hook: under the arc-13 renumbering (single ambient supply, D1 scheme R-B) every current-digest Ail symbol must lie in `[tu_first..last_issued]` — a re-threaded supply (the F-D-era scheme) REFUSES loudly (`CERB_FRESH_FLOOR_VIOLATION`, exit 70; plant-tested). test_exec.sh classifies `CERB_FLOOR` (SUMMARY `cerb_floor=`); the backstop NEVER fires on healthy inputs — any floor row is a finding. The arc-12 warn-only modes + grandfather flag are DELETED. Records: `docs/2026-08-22_arc13-s0-scheme-decision.md`, `docs/2026-08-22_arc13-s1-build.md` |
| `scripts/fuzz_csmith.sh` | csmith differential fuzz kit (arc-4 port; csmith + creduce are INSTALLED locally — gen + test_exec.sh differential; deterministic via `CSMITH_SEED_START`). Arc-10 S4 lane portfolio + seed ranges: `docs/2026-08-20_arc10-s4-csmith-campaign.md` |
| `scripts/csmith_explore.sh` | Arc-10 S4: oracle-only per-configuration yield + construct-coverage measurement (the exploration instrument behind the lane portfolio) |
| `scripts/creduce` + `scripts/creduce_interestingness.sh` | Arc-10 S0: creduce wrapper (project-local clang-format shim, no global state) + generic interestingness predicate against test_exec.sh single-file mode (`INTERESTING_REGEX` + `EXPECT_SNIPPET` signature pinning) |
| `scripts/test_verify.sh` | Fixture differentials (tests/verify + corpus/): main-mode vs oracle, plus call-point rows checked three ways — Lean `--call` == an oracle-run wrapper TU == the recorded pin (117 checks, fail-closed, vacuous-pass guarded) |
| `scripts/capped` | Arc-7 D7: run any command under a cgroup memory cap (default 64G; `CERB_MEM_MAX` override, `=none` loud opt-out). ALL lake/lean invocations go through it |

## Lem backend interaction

Lem is the OCaml tool from the lem-lean fork. The public installation
recipe is [README.md](README.md), including an explicit local opam switch
and the revision shared with Lake's LemLib. No parent `scripts/env.sh`,
private Git redirects or container `deps/` worktree is a prerequisite.
Checked 2026-09-25 against `bb487dda7c56981e76d67f53ae16e874cfe5ed61`; cleanup measurements:
[follow-up record](docs/2026-09-25_public-readiness-followup.md).

When updating Lem, install the chosen immutable revision into an owned
local switch, update the Lake revision/manifests and fork-drift metadata,
regenerate both trees (`make prelude-src lean-prelude-src`), and run the
required ladder gates. Do not install into a shared switch from a worktree.
The `lem-sync` stamps hash sources and outputs, not the Lem version.

**Key Lem mechanisms:**
- `declare lean target_rep function f = \`Lean.Name\`` — maps lem function to Lean
- `declare lean target_rep type t = \`Lean.Type\`` — maps lem type to Lean
- `declare {lean} skip_instances type t` — suppresses all instance generation
- `declare {lean} rename module = Name` — renames generated module
- Inhabited handling (arc-8; replaces the old DAEMON axiom fallback,
  which was logically inconsistent and is DELETED —
  docs/2026-08-20_daemon-inconsistent-axiom.md, RESOLVED): the
  backend DERIVES real bounded `Inhabited` instances per generated type
  (tier-1 nullary + tier-2 per-constructor with `[Inhabited tv]` bounds,
  in the type's own module); every failure site emits axiom-free
  `LemLib.failwithI`, with `[Inhabited tv]` binders threaded through
  exactly the enclosing defs whose failure sites sit at bare-tyvar
  positions (fixpoint over the call graph, zero call-site edits).
  FAIL-CLOSED: an underivable type gets NO instance — a demand on it is
  a generation-time error naming the type and the escape hatches
  (`skip_instances` + hand target_rep). Reintroduction is
  build-fatal: check_theorem_axioms.sh treats DAEMON as
  unconditionally fatal in every probed cone
- Comparison instances (arc-10 S2b; replaces the old sorried
  BEq/Ord/SetType/Eq0/Ord0 bodies — 1134 sites → 0): the backend
  derives total structural `beq_derived`/`compare_derived` per mutual
  block with OCaml-polymorphic-compare parity (nullary constructors
  rank below non-nullary, declaration order within each class, fields
  left-to-right; `[BEq tv]`/`[Ord tv]` bounds for parameterized
  types). FAIL-CLOSED: fn-carrying types (OCaml compare raises there
  too) and their referencers get loud greppable failwithI residual
  bodies, never sorry; surviving set comprehensions are a loud
  generation-time error
- The instance-priority LATTICE (arc-14 B4; be:G1/sem:S2): every
  generated/library instance priority is assigned from ONE normative
  table (lem-lean doc/notes/2026-08-22_arc14-instance-priority-
  lattice.md): model/override + derived BEq/Ord at default (1000), the
  auto SetType/Eq0/Ord0 trio at 500, generic defaults/residuals at low
  (100), open-tyvar fallbacks at 50 — so a model's own instance beats
  the auto trio BY PRIORITY, not declaration order. Build-failing
  resolution probe: lem tests/comprehensive test_instance_priority.lem
  + TestInstancePriorityCheck.lean (plant-tested)
- Set-layer comparator coherence (arc-14 B3; be:G4): lem sets are
  comparator-keyed end to end (Pset parity) — `insert` and set literals
  splice `setElemCompare` (`setAddBy`/`setFromListBy`); the BEq-keyed
  setAdd/setFromList are DELETED from LemLib (a finer BEq can no longer
  smuggle comparator-EQ duplicates past setEqualBy). Adversarial-key
  property tests: LemLibTest SetCoherence section
- Most Lean rendering state lives in `lean_backend.ml`'s `St`, with
  [file]/[invocation]/[render] lifetimes and reset hooks. Backend-common
  callbacks and the current-module side channel remain outside `St`;
  effect-free emission is still open. See Lem's pinned DESIGN.md.

**Bug reports:** lem-backend defects are reported in the lem-lean repo
(`doc/lean-backend/` dated records + `tests/comprehensive` reproducers);
upstream-facing reports (Cerberus, Lem, Lean) go in
`lean_frontend/docs/upstream-tray/<target>/` (see its INDEX.md).

## Status

The current public scope is [SUPPORTED.md](SUPPORTED.md). Dated records
retain historical measurements; they are not all current status. Start points:

- Latest records: `docs/` (dated `*-record.md` / `*-results.md`). The
  arc index that lived in the container's `ROADMAP.md` is archived at
  `docs/2026-08-31_container-roadmap-archive.md`; forward options:
  `docs/2026-08-31_semantics-forward-assessment.md`; backlog: [TODO.md](TODO.md).
- Trust story + gate list: [VALIDATION.md](VALIDATION.md).
- Declared boundary: concurrency stubs (the failed SC prototype and feature
  branches are parked; no announcement dependency), CerbFS and the CerbDebug no-op stubs,
  and the axiom story is CLOSED (effect-retirement arc, 2026-09-01):
  ZERO axiom declarations anywhere — this repo AND LemLib,
  recursively, gate-enforced; `runEffectful` is deleted and lem
  refuses `declare {lean} effectful`; the surviving runtime seams are
  kernel-checked opaques machine-pinned in
  `scripts/unsafebaseio_allowlist.txt` (Q4 classes). Bare `sorry`
  target representations are refused by the backend, including in the
  excluded CMM surface, which uses unsupported markers.
- Known operational residuals (step-runner stack ceiling, oracle
  allocation-census gap, etc.): registered with prices in the latest
  results docs.

## Conventions

- Hand-written files in `lean_frontend/`, generated files in `lean_frontend/generated/`
- `set_option autoImplicit true` in hand-written files (project default is false)
- Follow OCaml implementation as reference, with lean-c-semantics as secondary reference
- No sorry in hand-written code — use `fail`, `failwithI` (LemLib's opaque failure leaf — never `panic!`, which is transparent and reduces to `default` in the kernel; seam-hygiene 2026-09-19, `docs/2026-09-18_seam-hygiene-record.md`), or real implementations
- Bug reports: lem-backend defects → the lem-lean repo (`doc/lean-backend/` records, `tests/comprehensive` reproducers); upstream-facing reports → `lean_frontend/docs/upstream-tray/<target>/`
