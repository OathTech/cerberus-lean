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

**Proof layer (arc 7):** `lean_frontend/relsem/RelSem/` — Layer 2
(relational semantics over the fuel opsem: ExecModel, Machine, RunND,
Call harness) + Layer 3 (iris-lean coupling: IrisLang/IrisState/
IrisRules/IrisAdequacy) + the slate theorems T1–T4 (T?.lean, T?AppEq)
and the in-build axiom audit + statement-TCB gate (Audit.lean).
`RelSem` is in `defaultTargets`, so a plain `lake build` elaborates the
audit. Lake deps: `LemLib` (lem-lean pin) + `iris`/`Qq`/`batteries`
(pinned revs, resolved offline via deps/gitconfig redirects). See
`docs/2026-08-20_arc7-results.md`.

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

# Build OCaml driver (for --cabs-json)
opam exec -- dune build backend/driver/main.exe
opam exec -- dune install cerberus-lib  # for runtime files

# Update lem (pinned to GitHub branch)
make rebuild-lem
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
- `effects-proof-test` / `totality-proof-test` — kernel-checked proof exemplars for the effect-erasure and totality machinery
- `core-parser-test` — 280 tests for `CoreParser.lean`
- `fresh-int-test` — verifies `fresh_int`/`Symbol.fresh` generate unique values (+ the native-obj fresh-counter floor probe)
- `emit-lean-core-test` — arc-7: byte drift gate for the emitted slate program terms (`relsem/RelSem/T1Core.lean`, `SlateCore.lean` vs a fresh parse of the pinned oracle Core dumps) + concrete differential points on the assembled theorem objects

`test_unit.sh` also runs the gate scripts: the hand-written↔generated
sync gate, the hand-written-axiom census (exactly 2),
`check_exec_purity.sh`, `check_exec_totality.sh` (16 generated modules
+ CerbND since arc-7 S5a), and `check_theorem_axioms.sh` (theorem-axiom
cones + the D14 non-kernel-proof-method ban). Two further gates are
IN-BUILD (fail the `lake build` itself, arc 7): the RelSem axiom audit
and the slate statement-TCB gate — both in `relsem/RelSem/Audit.lean`
(slate statements must be fuel-opsem-only: no Iris/RelSem-relation
names; negative-tested in-build).

### Verification fixtures (arc 7)

```bash
./scripts/test_verify.sh   # tests/verify: T1-T5 fixture differentials —
                           # 5/5 main-mode vs the OCaml oracle + 18/18
                           # harness concrete points vs recorded specs
                           # + (arc-7 S5c) 5/5 pin-provenance checks
                           # (oracle --pp=core re-derivation byte-equal
                           # to the pinned .core dumps) + the
                           # t4-env-witness probe (T4EnvHyp conjuncts +
                           # first-in-process fresh-draw ordering)
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
./scripts/test_golden.sh return42   # run the return42 fixture
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

## Key files

### Hand-written Lean (in `lean_frontend/`, copied to `generated/` by Makefile)

| File | Purpose |
|------|---------|
| `CerberusImpl.lean` | LP64 implementation-defined behaviour (sizeof, alignof, etc.) |
| `CerbMem.lean` | Concrete memory model (byte-level load/store, allocation) |
| `CerbTags.lean` | Mutable tag definitions state (struct/union defs) |
| `CerbDebug.lean` | Debug level and output functions |
| `CerbDecode.lean` | Integer/character constant decoding |
| `CerbGlobal.lean` | Runtime config (execution mode, switches) |
| `CerbFloat.lean` | IEEE 754 float operations |
| `CerbUtils.lean` | Timing, logging, GCC builtins |
| `CerbPP.lean` | Pretty-printer placeholders |
| `CerbFS.lean` | In-memory filesystem model |
| `CerbConcurrency.lean` | Concurrency stubs |
| `CerbCtypeInstances.lean` | BEq/Ord for mutual ctype types |
| `CerbCabsInstances.lean` | BEq for Cabs enum types |
| `CabsImport.lean` | JSON → Cabs AST deserializer |
| `CoreParser.lean` | Core text parser (Parsec) |
| `CerbND.lean` | Exhaustive ND runner (+ runND1 single-trace, arc-5 `--first`); fuel-TOTALIZED in arc-7 S2 (runNDFuel + wrappers, loud panic at exhaustion) — no `partial` allowed (totality gate scans it; RelSem/RunND.lean states soundness against it) |
| `CerbFunMapInstances.lean` | Arc-7 S2: real SetType instance for generic_fun_map_decl (evicts the lem backend's sorried fallback from initial_driver_state's cone) |
| `CerbStepInstances.lean` | OCaml-poly-eq-parity instances for core_step2 (arc 4) |
| `CerbLocation.lean` | Source location type |
| `CerberusFresh.lean` | Fresh symbol/digest generation |
| `Main.lean` | Driver: self-test, parse, desugar pipeline |

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
| `scripts/test_libxml2_uri.sh` | Arc-6 GATE (S4, charter success condition 1): 5-TU xmlParseURISafe corpus grown to 16 URIs (RFC 3986 edge classes), 4 lanes (oracle+libc / ocaml-nolibc / lean-nolibc mirrored-failure pair / lean+libc) — pinned per-lane expectations + baseline drift check, fail-closed; 16/16 byte-identical lean+libc vs oracle |
| `scripts/libc_prep.sh` | Arc-6 S1: pins + drift-checks `tests/libc/libc.core` (the oracle's unlinked libc Core text dump) and emits the 12 libc metadata TU cabs-jsons (see Main.loadLibc) |
| `scripts/test_libc_exec.sh` | Arc-6 S1 differential: C-with-libc programs, both sides load the C library (`tests/libc_exec/`, own baseline; NEW mode — standing corpora stay --nolibc) |
| `scripts/test_cabs_json.sh` | Quick smoke test |
| `scripts/test_verify.sh` | Arc-7 S3: verification-fixture differentials (tests/verify T1-T5) — main-mode vs oracle + harness concrete points vs recorded specs (23 checks, fail-closed) |
| `scripts/capped` | Arc-7 D7: run any command under a cgroup memory cap (default 64G; `CERB_MEM_MAX` override, `=none` loud opt-out). ALL lake/lean invocations go through it |

## Lem backend interaction

Lem is pinned to `https://github.com/septract/lem-lean#mdd/lean-backend`.

**Updating lem:** `make rebuild-lem` runs `opam update lem && opam upgrade lem`.

**Key Lem mechanisms:**
- `declare lean target_rep function f = \`Lean.Name\`` — maps lem function to Lean
- `declare lean target_rep type t = \`Lean.Type\`` — maps lem type to Lean
- `declare {lean} skip_instances type t` — suppresses all instance generation
- `declare {lean} rename module = Name` — renames generated module
- Inhabited handling (arc-8; replaces the old DAEMON axiom fallback,
  which was logically inconsistent and is DELETED —
  lembugs/2026-08-20_daemon-inconsistent-axiom.md, RESOLVED): the
  backend DERIVES real bounded `Inhabited` instances per generated type
  (tier-1 nullary + tier-2 per-constructor with `[Inhabited tv]` bounds,
  in the type's own module); every failure site emits axiom-free
  `LemLib.failwithI`, with `[Inhabited tv]` binders threaded through
  exactly the enclosing defs whose failure sites sit at bare-tyvar
  positions (fixpoint over the call graph, zero call-site edits).
  FAIL-CLOSED: an underivable type gets NO instance — a demand on it is
  a generation-time error naming the type and the escape hatches
  (`skip_instances` + hand target_rep). Reintroduction is
  build-fatal: the in-build RelSem absence gate (Audit.lean) bans any
  constant named DAEMON/DAEMON1, and check_theorem_axioms.sh treats
  DAEMON as unconditionally fatal in every probed cone
- Simple enums in mutual blocks get `deriving BEq, Ord` (not sorry)

**Bug reports:** `lean_frontend/lembugs/` — dated markdown files with reproducers.

## Remaining work

### Sorry target_reps (non-concurrency)
- NONE (arc 4: `easy_update_mem_value_aux` un-sorried via a fuel declare;
  `runND_proxy` is implemented — hand-written `CerbND.runND`).
  Concurrency stubs remain the declared boundary.

### Pipeline status (updated 2026-08-20, post arc-8 — see the arc results docs)
- ✅ C → Cabs JSON → Cabs types (100%)
- ✅ Core text parser + stdlib loading (incl. ailname attribute capture, arc 5)
- ✅ Desugar / Typecheck / Translation (all 106/106 tests/minimal)
- ✅ Execution, differentially validated vs OCaml: tests/minimal 103/106
  (3 oracle-side skips), coverage 183/199 comparable (since arc-6 S2),
  debug corpus green
- ✅ libc/builtin procedure linking (arc 5: 20/20 coverage FAILs closed)
- ✅ Multi-TU: real Core_linking + per-TU MD5 digests (arc 5)
- ✅ libxml2 chvalid through the full pipeline: 100% differential
  (4 slices, 1354 boundary points — `test_libxml2.sh`; consolidated from
  28 by the arc-6 S3 map-representation speedups)
- ✅ C-libc loading (arc-6 S1): pinned libc Core dump (`tests/libc/`)
  parsed by CoreParser + metadata (extern/funinfo/tagDefs) from our own
  elaboration of the 12 libc TUs, linked via Core_linking
  (`--libc`/`--libc-tu`, Main.loadLibc). uri corpus 16/16 vs oracle, GATING (arc-6 S4);
  test_core known-red 078-float-special FIXED (bodyless ProcDecl form)
  — tests/minimal test_core now 106/106.
- ✅ Varargs execution (arc-6 S2, register 15 FIXED): CerbMem
  vaStart/vaCopy/vaArg/vaEnd/vaList mirror impl_mem.ml:2698-2764
  (prototype port Step.lean:1441-1513 attributed) — 5 coverage varargs
  DIFFs → MATCH, debug varargs-01 → MATCH, libc_exec 006 snprintf →
  MATCH, new 007 va_*×Formatted interplay MATCH
- ✅ Perf (arc-6 S3): LemLib Fmap -> comparator-keyed Std.TreeMap indexes
  (lem-lean arc/libc-load, proved/tested equivalence in LemLibTest.lean) +
  CerbMem bytemap/allocations -> Std.TreeMap Int; chvalid battery now 4
  slices (339 pts ~100 s Lean vs old 50-pt ~35 s each). Known residual:
  step-runner stack ceiling (S0 register; onset ~1.5k plain loop
  iterations, bimodal quiet-death/hang — not corpus-binding)
- ✅ VERIFICATION (arc-7, "the bridge"): first theorems — T1-T4
  ∀-quantified interpreter-only statements about pinned compiled Core
  programs (T4 = struct member write/read, the exit criterion), proved
  through the iris-lean WP route + the in-repo adequacy theorem;
  toolchain 4.32.2; CerbND + CerbMem exec-path + 5 more generated
  modules totalized; in-build axiom audit + statement-TCB gate.
  T5 (bounded loop) parked with pricing. See
  `docs/2026-08-20_arc7-results.md`.
- ✅ DAEMON ELIMINATED (arc-8, "the consistent boundary"): lem's
  logically inconsistent `axiom DAEMON`/`DAEMON1` DELETED from LemLib
  and every generated cone — replaced by backend-derived real bounded
  Inhabited instances (S1) + failwithI with `[Inhabited tv]` signature
  threading (S2), fail-closed (underivable types are loud
  generation-time errors, never opaque fallbacks). T1-T4 cones are now
  exactly [propext, runEffectful, Classical.choice, Quot.sound] —
  UNCONDITIONAL kernel certificates, no meta-assumption. Absence gates
  enforce non-reintroduction (in-build Audit.lean + arc-8 S3
  check_theorem_axioms.sh bar); zero differential movement across the
  full surface. See `docs/2026-08-20_arc8-results.md` and
  lembugs/2026-08-20_daemon-inconsistent-axiom.md (RESOLVED).

## Conventions

- Hand-written files in `lean_frontend/`, generated files in `lean_frontend/generated/`
- `set_option autoImplicit true` in hand-written files (project default is false)
- Follow OCaml implementation as reference, with lean-c-semantics as secondary reference
- No sorry in hand-written code — use `fail`, `panic!`, or real implementations
- Bug reports for Lem issues go in `lean_frontend/lembugs/` with date prefix and reproducers
