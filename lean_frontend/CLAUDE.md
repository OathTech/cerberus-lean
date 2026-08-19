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

## Build

```bash
# Prerequisites: Lean 4.29.0 (lean-toolchain), local opam switch with lem pinned

# Generate Lean from .lem files
make lean-prelude-src

# Build Lean executable
cd lean_frontend && lake build cerberus-lean

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
- `core-parser-test` — 240 tests for `CoreParser.lean`
- `fresh-int-test` — verifies `fresh_int`/`Symbol.fresh` generate unique values

### Integration tests (C → JSON → Lean, per parser)

```bash
# Cabs JSON bridge: C → OCaml → JSON → Lean (233 tests, 100%)
./scripts/test_parse.sh              # tests/minimal (105 tests)
./scripts/test_parse.sh tests/ci     # upstream CI (128 tests)

# Core text parser integration: C → cerberus --pp core → Lean CoreParser
./scripts/test_core.sh              # tests/minimal (105 tests)
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
| `CerbStepInstances.lean` | OCaml-parity BEq/Ord for core_step2 (closure-carrying) |
| `CerbCabsInstances.lean` | BEq for Cabs enum types |
| `CerbInhabitedInstances.lean` | Computable Inhabited for monadic types |
| `CabsImport.lean` | JSON → Cabs AST deserializer |
| `CoreParser.lean` | Core text parser (Parsec) |
| `CoreParserTest.lean` | Core parser unit tests |
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
| `scripts/common.sh` | Shared helpers (build, run, paths) |
| `scripts/test_parse.sh` | Test Cabs JSON bridge on .c files |
| `scripts/test_core.sh` | Test Core text parser: C → --pp core → Lean |
| `scripts/test_multi_tu.sh` | Differential multi-TU linking: N .c linked by OCaml vs N cabs-jsons linked by the Lean pipeline (corpus: `tests/multi_tu/<name>/`) |
| `scripts/libxml2_prep.sh` | libxml2 no-autogen prep: pinned config (`tests/libxml2/config/`) + cerberus args per TU (probe recipe) |
| `scripts/test_libxml2.sh` | Arc-5 exit-criterion differential: chvalid.c + generated boundary battery (28 slices, 1354 points), single-trace both sides (~35 min; not in the fast ladder) |
| `scripts/test_libxml2_uri.sh` | Arc-6 REPORTING baseline: 5-TU xmlParseURISafe corpus (oracle+libc vs --nolibc vs Lean) |
| `scripts/test_cabs_json.sh` | Quick smoke test |

## Lem backend interaction

Lem is pinned to `https://github.com/septract/lem-lean#mdd/lean-backend`.

**Updating lem:** `make rebuild-lem` runs `opam update lem && opam upgrade lem`.

**Key Lem mechanisms:**
- `declare lean target_rep function f = \`Lean.Name\`` — maps lem function to Lean
- `declare lean target_rep type t = \`Lean.Type\`` — maps lem type to Lean
- `declare {lean} skip_instances type t` — suppresses all instance generation
- `declare {lean} rename module = Name` — renames generated module
- Inhabited fallback: DAEMON (axiom + @[implemented_by], computable, priority := low)
- Simple enums in mutual blocks get `deriving BEq, Ord` (not sorry)

**Bug reports:** `lean_frontend/lembugs/` — dated markdown files with reproducers.

## Remaining work

### Sorry target_reps (non-concurrency)
- NONE (arc 4: `easy_update_mem_value_aux` un-sorried via a fuel declare;
  `runND_proxy` is implemented — hand-written `CerbND.runND`).
  Concurrency stubs remain the declared boundary.

### Pipeline status (2026-08-19, arc-4 post-S1a — see
`docs/2026-08-19_arc4-s0-frontier.md`, "Post-S1a frontier")
- ✅ C → Cabs JSON (OCaml parser, 100%)
- ✅ JSON → Lean Cabs types (CabsImport, 100%)
- ✅ Core text parser (std.core + impl files)
- ✅ Core stdlib loading
- ✅ Desugar (105/105 tests/minimal — const-expr driver unblocked by S1a)
- ✅ Typecheck (GenTyping.annotate_program — 105/105)
- ✅ Translation (Translation.translate — 105/105)
- 🔧 Execution (Driver.drive): the sorry'd `BEq core_step2` is fixed
  (S1a: `CerbStepInstances.lean`, OCaml-parity, imported via driver.lem);
  88/105 complete runND (62 Active with return values, 26 Killed);
  remaining 17 crash on `can_advance ACTION_ILLTYPED` (15) and
  `illtyped SeqRMW` (2) — S1 queue items 2/5

## Conventions

- Hand-written files in `lean_frontend/`, generated files in `lean_frontend/generated/`
- `set_option autoImplicit true` in hand-written files (project default is false)
- Follow OCaml implementation as reference, with lean-c-semantics as secondary reference
- No sorry in hand-written code — use `fail`, `panic!`, or real implementations
- Bug reports for Lem issues go in `lean_frontend/lembugs/` with date prefix and reproducers
