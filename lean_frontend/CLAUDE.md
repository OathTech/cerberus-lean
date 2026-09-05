# Cerberus Lean Frontend

Lean 4 port of the Cerberus C semantics. Generates Lean code from the same `.lem` files as the OCaml backend, sharing identical semantics.

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
- Lake deps: `LemLib` (lem-lean pin), resolved offline via
  deps/gitconfig redirects.

## Build

```bash
# Prerequisites: Lean 4.32.2 (lean-toolchain; bumped from 4.29.0 in
# arc-7 S0), local opam switch with lem pinned

# Generate Lean from .lem files
make lean-prelude-src

# Build Lean executable — ALWAYS through scripts/capped (cgroup memory
# cap; never run lake/lean uncapped — arc-7 D7 rule after an OOM
# session kill; CERB_MEM_MAX overrides the 64G default)
cd lean_frontend && ../scripts/capped lake build cerberus-lean

# Build the speclab differential-lane package (the lane scripts build
# it themselves; by hand:)
cd lean_frontend/speclab && ../../scripts/capped lake build

# Build OCaml driver (for --cabs-json). cerberus-lib.install must be
# built explicitly: `dune install cerberus-lib` does NOT build it (fails
# after a dune clean), and building it stages
# _build/install/default/lib/cerberus-lib (std.core etc.) which every
# --runtime=_build/install/default invocation needs.
opam exec -- dune build backend/driver/main.exe cerberus-lib.install
opam exec -- dune install cerberus-lib  # for runtime files
# REQUIRED for libc-mode lanes (2026-08-22 hotfix,
# docs/2026-08-22_libc-co-divergence-diagnosis.md): stage the `cerberus`
# PACKAGE's install tree. Libc-mode oracle runs (no --nolibc) load
# _build/install/default/lib/cerberus/runtime/libc/libc.co, which only
# `cerberus`'s install stanzas create (as symlinks into _build/default —
# always in sync once present). cerberus-lib stages headers only; after
# a `dune clean`, omitting this step kills every libc-mode oracle run at
# startup (Failure("file libc.co not found"), exit 125).
# scripts/common.sh build_cerberus and libc_prep.sh --check now enforce it.
# CAVEAT (plant-tested): dune trusts its incremental db over the
# filesystem — deleting/altering anything under _build by hand is NOT
# repaired by this command (or any incremental build); only `dune clean`
# + this recipe recovers a tampered _build.
opam exec -- dune build cerberus.install

# Reinstall lem after moving its pin (the opam pin is the container's
# deps/lem-pinned worktree of lem-lean, branch cerberus-pin):
#   git -C ../deps/lem-pinned reset --hard <lem-lean commit>
make rebuild-lem     # = opam upgrade --switch=. --no-depexts lem
```

## Testing

Tests are organized into three categories:

### Unit tests (fast, hermetic, no OCaml)

Hand-written Lean tests under `lean_frontend/test/Unit/<Name>Test.lean`.
Each is a `[[lean_exe]]` in `lakefile.toml` that exits 0 on pass.

```bash
./scripts/test_unit.sh                  # run all unit tests
./scripts/test_unit.sh fresh-int-test   # run one specific test
```

Current unit tests:
- `effects-proof-test` / `totality-proof-test` — compile-time checks on the exec cone, as it is today: every fuel'd wrapper is FUEL-PARAMETRIC (`@f ⟨n⟩ = f_lemFuel n` for every `n`, by rfl — the fuel-parameter arc; no default constant exists), symbolic equations hold on the total layout/typing defs, and `tagDefs` is an honest reader parameter (no hidden extern read) — i.e. totality + reader lifting, properties of this port checked by the build (not a verification layer; exe names kept for build stability)
- `fuel-exemplar-test` — the consumer-shaped ∀-fuel theorem over the shipped pipeline `@drive ⟨fuel⟩` (test/Unit/FuelExemplar.lean)
- `fuel-forms-tool` (not a pass/fail exe: the INSTRUMENT of `scripts/check_fuel_forms.sh`) — `test/Unit/FuelFormsTool.lean` imports the compiled environment at runtime and classifies every fuel'd worker MEASURED/ABSORBING/AMBIENT with its drive-cone reachability (C2)
- `core-parser-test` — 280 tests for `CoreParser.lean`
- `fresh-int-test` — verifies `fresh_int`/`Symbol.fresh` generate unique values (+ the native-obj fresh-counter floor probe)
- `pp-test` — arc-10 S3: pretty-printer mirrors (ctype/value shapes + float formatting vs an OCaml 5.4.0 reference transcript, in-file)

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
fuel-forms gate — every fuel'd worker measured, absorbing, unreachable
from the drive cone, or a reviewed row of `scripts/fuel_forms_pending.txt`;
C4: a worker measured UNDER A HYPOTHESIS (lem `assuming`, the `lemHyp`
binder) must equal a row of the reviewed register `scripts/fuel_hypotheses.txt`,
both directions; eleven plants incl. three compiled decoy obligations, one
under a contradictory hypothesis caught by the register), the lem-sync content-hash gate,
`check_fork_drift.sh` (arc-10 audit follow-up, [USER] mandate: the
oracle surface must equal the reviewed manifest
`scripts/fork_drift_manifest.txt`, and the generated-OCaml
fork-vs-upstream deltas must match their pinned hashes; loud SKIP
when the upstream remote or a generated tree is absent, fail-closed
otherwise), and `check_fixture_freeze.sh` (the `corpus/`
differential-fixture set must match its hash manifest exactly).

### Fixture differentials

```bash
./scripts/test_verify.sh   # tests/verify + corpus/ fixture
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
./scripts/test_parse.sh              # tests/minimal (106 tests)
./scripts/test_parse.sh tests/ci     # upstream CI (128 tests)

# Core text parser integration: C → cerberus --pp core → Lean CoreParser
./scripts/test_core.sh              # tests/minimal (106 tests)
./scripts/test_core.sh tests/ci     # upstream CI (128 tests)
```

### Golden tests (full pipeline, per stage)

Golden fixtures live under `tests/fixtures/<name>/`:
- `source.c` — the C input
- `expected.txt` — expected final return value
- (intermediate goldens for each stage as they come online)

```bash
./scripts/test_golden.sh                     # run all fixtures
./scripts/test_golden.sh 001-return-literal  # run one fixture
```

### Self-test

```bash
cd lean_frontend && .lake/build/bin/cerberus-lean  # sizeof, memory model
```

### End-to-end pipeline test

```bash
./scripts/cerberus --cabs-json test.c > test.json
cd lean_frontend && .lake/build/bin/cerberus-lean ../test.json
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
| `CerbMem.lean` | Concrete memory model (byte-level load/store, allocation). Arc-14 F1: the pre-doctrine F-row is re-mirrored — relational ptr kill-paths, checked per-byte memcpy/memcmp, MerrUndefinedRealloc, real update_prefix, byte asserts, sizeof/alignof assert-parity; F4: OCaml-(=)-parity leaf instances + the memory-model instance caveat (relocated here) |
| `CerbTags.lean` | Mutable tag definitions state (struct/union defs) |
| `CerbDebug.lean` | Debug level and output functions |
| `CerbDecode.lean` | Integer/character constant decoding. Arc-14 F2: decode.ml's exhaustive fail-CLOSED table with C11 cites; `\?` -> 63 and hex escaped_char are documented Lean-right divergences (oracle-wrong: upstream tray 10/11) |
| `CerbGlobal.lean` | The DEFAULT configuration and switch set as plain `def`s (execution mode `none`, every flag `false`, switch set `[]`), each with a `rfl` lemma — the values the oracle driver holds in matched mode, cited line by line; no process state since 2026-09-05 (`docs/2026-09-05_cerbglobal-defs-record.md`) |
| `CerbFloat.lean` | IEEE 754 float operations; lawful total Ord Float (NaN reflexive, arc-14 F4) |
| `CerbUtils.lean` | Timing/logging no-op stubs (documented), GCC builtins on Z/two's-complement semantics mirroring ocaml_gcc_builtins.ml per-line (arc-14 F2: ffs(-1)=1, ctz(0)/bswap asserts panic) |
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
| `CerberusFresh.lean` | Fresh symbol/digest generation |
| `Ctype_lemMeasureProofs.lean`, `Core_lemMeasureProofs.lean`, `Defacto_memory_aux_lemMeasureProofs.lean`, `Utils_…`, `Core_run_aux_…`, `Core_reduction_…`, `Defacto_memory_…`, `Core_aux_…`, `Core_eval_lemMeasureProofs.lean` | The `fuel_measure` sufficiency proofs the generated `*_auxiliary.lean` obligation shells import (fuel-parameter arc C1/C2; one module per lem module with measured functions — the build fails without them, by design; 38 generated obligations). Template: the C2 record §4 / `Core_run_aux_lemMeasureProofs.lean` (strong induction on the derived size, `key` + `size_lt`, `split` for multi-discriminant matches, `to_congr` for list traversals); kernel-only tactics, no option bumps |
| `CerbMeasureLemmas.lean` | The shared toolbox of those proofs: membership-relative congruences, the derived list helpers' member bounds, positivity, `unatomic_size_le`, the `size_lt` discharger and the bounded `to_congr` descent (C2) |
| `CerbMem_lemMeasureProofs.lean` | The hand-written MEASURED seams' sufficiency theorems (`CerbMem.typeofMval/unqualifyAndUnatomic/memValueToBytes_measure_sufficient`, same shape and namespace rule as the generated ones — the fuel-forms gate classifies them by the same rule) |
| `Main.lean` | Driver: self-test, parse, desugar pipeline; `--fuel N` (the ONE fuel numeral: `defaultFuel` = 10^8, the harness default; the run's `[LemFuel]` instance is built once here) |

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
| `scripts/common.sh` | Shared helpers (build, run, paths) |
| `scripts/test_parse.sh` | Test Cabs JSON bridge on .c files |
| `scripts/test_core.sh` | Test Core text parser: C → --pp core → Lean |
| `scripts/test_multi_tu.sh` | Differential multi-TU linking: N .c linked by OCaml vs N cabs-jsons linked by the Lean pipeline (corpus: `tests/multi_tu/<name>/`) |
| `scripts/libxml2_prep.sh` | libxml2 no-autogen prep: pinned config (`tests/libxml2/config/`) + cerberus args per TU (probe recipe) |
| `scripts/test_libxml2.sh` | Arc-5 exit-criterion differential: chvalid.c + generated boundary battery (4 slices since arc-6 S3, 1354 points), single-trace both sides (~8 min; Tier B slow ladder since arc-6 S4 — see scripts/LADDER.md) |
| `scripts/test_libxml2_uri.sh` | Arc-6 GATE (S4, charter success condition 1): 5-TU xmlParseURISafe corpus grown to 16 URIs (RFC 3986 edge classes), 4 lanes (oracle+libc / ocaml-nolibc / lean-nolibc mirrored-failure pair / lean+libc) — pinned per-lane expectations + baseline drift check, fail-closed; 16/16 byte-identical lean+libc vs oracle. Arc-12 D2: the two oracle invocations run GRANDFATHERED past the F-D floor (uri.c is beyond-margin, 252 live collisions — loud warning; validated by the 16/16 agreement gate itself; register G3) |
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

Lem is the OCaml tool `lem` from the lem-lean fork
(`https://github.com/OathTech/lem-lean`, mainline `mdd/lean-backend`),
opam-pinned in the LOCAL switch to the container worktree
`deps/lem-pinned` (branch `cerberus-pin`; `opam pin list --switch=.`
shows `git+file:///…/deps/lem-pinned#cerberus-pin`). The Lake dep
`LemLib` is the same repo's `lean-lib/` at the rev in `lakefile.toml`;
an arc closes only when opam pin = Lake pin = the lem-lean branch head
(the two-repo pin dance, container CLAUDE.md).

**Updating lem:** move the pin, then reinstall — `git -C
../deps/lem-pinned reset --hard <lem-lean commit>`, then `make
rebuild-lem` (= `opam upgrade --switch=. --no-depexts lem`; the path
form because the switch is local, `--no-depexts` because system-package
detection fails in the sandbox). Then regenerate both trees (`make
prelude-src lean-prelude-src`): the lem-sync stamps hash sources and
outputs, not the lem version.

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
- The backend's mutable state lives in ONE module (arc-14 B1; be:G3):
  lean_backend.ml `St` — per-field lifetime classes ([file]/
  [invocation]/[render]), St.reset_per_file, St.reset_invocation (the
  reentrancy hook). Effect-free emission is the registered L-priced
  residual

**Bug reports:** lem-backend defects are reported in the lem-lean repo
(`doc/lean-backend/` dated records + `tests/comprehensive` reproducers);
upstream-facing reports (Cerberus, Lem, Lean) go in
`lean_frontend/docs/upstream-tray/<target>/` (see its INDEX.md).

## Status

Current state, boundary list, and per-capability status live in the
dated records — do not maintain status lists here. Start points:

- Latest records: `docs/` (dated `*-record.md` / `*-results.md`). The
  arc index that lived in the container's `ROADMAP.md` is archived at
  `docs/2026-08-31_container-roadmap-archive.md`; forward options:
  `docs/2026-08-31_semantics-forward-assessment.md`; backlog: [TODO.md](TODO.md).
- Trust story + gate list: [VALIDATION.md](VALIDATION.md).
- Declared boundary: concurrency stubs (temporal, the cmm
  instantiation is the mover) + CerbFS + the CerbDebug no-op stubs,
  and the axiom story is CLOSED (effect-retirement arc, 2026-09-01):
  ZERO axiom declarations anywhere — this repo AND LemLib,
  recursively, gate-enforced; `runEffectful` is deleted and lem
  refuses `declare {lean} effectful`; the surviving runtime seams are
  kernel-checked opaques machine-pinned in
  `scripts/unsafebaseio_allowlist.txt` (Q4 classes). No sorried
  target_reps outside that boundary; any new one is a finding.
- Known operational residuals (step-runner stack ceiling, oracle
  allocation-census gap, etc.): registered with prices in the latest
  results docs.

## Conventions

- Hand-written files in `lean_frontend/`, generated files in `lean_frontend/generated/`
- `set_option autoImplicit true` in hand-written files (project default is false)
- Follow OCaml implementation as reference, with lean-c-semantics as secondary reference
- No sorry in hand-written code — use `fail`, `panic!`, or real implementations
- Bug reports: lem-backend defects → the lem-lean repo (`doc/lean-backend/` records, `tests/comprehensive` reproducers); upstream-facing reports → `lean_frontend/docs/upstream-tray/<target>/`
