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

```bash
# Cabs JSON bridge: C → OCaml → JSON → Lean (233 tests, 100%)
./scripts/test_parse.sh              # tests/minimal (105 tests)
./scripts/test_parse.sh tests/ci     # upstream CI (128 tests)

# Core text parser unit tests (68 tests)
cd lean_frontend && lake build core-parser-test && .lake/build/bin/core-parser-test

# Core text parser integration tests: C → cerberus --pp core → Lean CoreParser
./scripts/test_core.sh              # tests/minimal (105 tests)
./scripts/test_core.sh tests/ci     # upstream CI (128 tests)

# Self-test (sizeof, memory model)
cd lean_frontend && .lake/build/bin/cerberus-lean

# End-to-end pipeline test
cerberus --cabs-json test.c > test.json
cd lean_frontend && .lake/build/bin/cerberus-lean ../test.json
```

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
- `defacto_memory.lem`: `easy_update_mem_value_aux`
- `mini_pipeline.lem`: `runND_proxy`

### Pipeline status
- ✅ C → Cabs JSON (OCaml parser, 100%)
- ✅ JSON → Lean Cabs types (CabsImport, 100%)
- ✅ Core text parser (std.core + impl files)
- ✅ Core stdlib loading
- 🔧 Desugarer enters, fails on missing stdlib entries (parser → Fmap conversion issue)
- ⬜ Typecheck (GenTyping.annotate_program)
- ⬜ Translation (Translation.translate)
- ⬜ Execution (Driver.drive)

## Conventions

- Hand-written files in `lean_frontend/`, generated files in `lean_frontend/generated/`
- `set_option autoImplicit true` in hand-written files (project default is false)
- Follow OCaml implementation as reference, with lean-c-semantics as secondary reference
- No sorry in hand-written code — use `fail`, `panic!`, or real implementations
- Bug reports for Lem issues go in `lean_frontend/lembugs/` with date prefix and reproducers
