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

**Proof layer (arc 7; workbench arc 9):** `lean_frontend/relsem/RelSem/`
— Layer 2 (relational semantics over the fuel opsem: ExecModel,
Machine, RunND, Call harness) + Layer 3 (iris-lean coupling:
IrisLang/IrisState/IrisRules/IrisAdequacy — since arc 9 on upstream
`OwnP`, hand-rolled state-ghost twin retired) + the slate theorems
T1–T4 (T?.lean, T?AppEq) and the in-build axiom audit + statement-TCB
gate (Audit.lean). THE WORKBENCH (arc 9): `Kit/` — six lemma kits
(AppEq law registrations, Eval, Loop with the axiom-free
`iter_compose`, Map lawful-map layer, Mem computed-RHS blocks, Round
dnms/perform layer; 54 `#print axioms` exactness pins in `Kit/Audit.lean`,
in-build) + `Tactics/AppEqAttr.lean`/`Tactics/AppWalk.lean` (the
`@[app_eq]` law table + the `app_walk` walker v1-v3 with the
per-stage certificate emitter: kernel-whnf discovery, decide-facts
chase-rewrite, ledgered heartbeat budgets — no ambient raise
anywhere) + the proof-size gate (`scripts/check_proof_size.sh`,
250-line/40-step bars, Tier A). T5 (bounded loop) is parked at
evidence grade with fixture/prefix/St-family banked (T5Fixture,
T5Prefix, the t5-probe census exe) — see
`docs/2026-08-21_arc9-results.md`.
`RelSem` is in `defaultTargets`, so a plain `lake build` elaborates the
audit. Lake deps: `LemLib` (lem-lean pin) + `iris`/`Qq`/`batteries`
(pinned revs, resolved offline via deps/gitconfig redirects; iris at
head `34390a0133…` since arc-9 D1). See
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
- `pp-test` — arc-10 S3: pretty-printer mirrors (ctype/value shapes + float formatting vs an OCaml 5.4.0 reference transcript, in-file)
- `app-walk-test` — arc-9 S2: the `app_walk` walker contract-table exercises (E1-E6, kernel-checked)

(`t5-probe` is a further `[[lean_exe]]` — the arc-9 round-census
instrument, run on demand, not part of the unit suite.)

`test_unit.sh` also runs the gate scripts: the hand-written↔generated
sync gate, the hand-written-axiom census (exactly 2),
`check_exec_purity.sh`, `check_exec_totality.sh` (16 generated modules
+ CerbND since arc-7 S5a), `check_theorem_axioms.sh` (theorem-axiom
cones + the D14 non-kernel-proof-method ban), and
`check_fork_drift.sh` (arc-10 audit follow-up, [USER] mandate: the
oracle surface must equal the reviewed manifest
`scripts/fork_drift_manifest.txt`, and the generated-OCaml
fork-vs-upstream deltas must match their pinned hashes — spec:
`notes/2026-08-21_fork-drift-review.md` §6; loud SKIP when the
upstream remote or a generated tree is absent, fail-closed otherwise),
and `check_proof_size.sh` (arc-9 S2: slate proof files within the
250-line/40-manual-step bar, Kit files fixture-free — the mega-lemma
counter, debug-only walker surfaces banned in committed (git-tracked)
proofs: `app_walk?`/`app_walk_norm?` + `app_defeq_diag`/`dnms_kwalk`/
`app_walk_norm!` since the arc-9 pre-merge audit (A-F5);
registered slate files listed in the script). Two further gates are
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
| `scripts/test_libxml2_uri.sh` | Arc-6 GATE (S4, charter success condition 1): 5-TU xmlParseURISafe corpus grown to 16 URIs (RFC 3986 edge classes), 4 lanes (oracle+libc / ocaml-nolibc / lean-nolibc mirrored-failure pair / lean+libc) — pinned per-lane expectations + baseline drift check, fail-closed; 16/16 byte-identical lean+libc vs oracle. Arc-12 D2: the two oracle invocations run GRANDFATHERED past the F-D floor (uri.c is beyond-margin, 252 live collisions — loud warning; validated by the 16/16 agreement gate itself; register G3) |
| `scripts/libc_prep.sh` | Arc-6 S1: pins + drift-checks `tests/libc/libc.core` (the oracle's unlinked libc Core text dump) and emits the 12 libc metadata TU cabs-jsons (see Main.loadLibc) |
| `scripts/test_libc_exec.sh` | Arc-6 S1 differential: C-with-libc programs, both sides load the C library (`tests/libc_exec/`, own baseline; NEW mode — standing corpora stay --nolibc) |
| `scripts/test_cabs_json.sh` | Quick smoke test |
| `scripts/test_bytes.sh` | Arc-10 S3b: oracle-INDEPENDENT tests/bytes micro-lane — 9 exec files byte-compared to the committed upstream `.exec` records (+ 5 front-end-reject negative pins), fail-closed both directions (Tier A row 4c). tests/float is a plain test_exec.sh lane (`--check-baseline=scripts/exec_float_baseline.txt tests/float`, Tier A row 4b) |
| `scripts/test_csmith_corpus.sh` | Arc-10 S4: deterministic differential lane over the 1669 in-tree upstream csmith programs (prefixed materialization + kit header shim); committed classified baseline `scripts/exec_csmith_corpus_baseline.txt` (re-baselined arc-12 S1 under the F-D floor: 516 CERB_FLOOR rows, movement table in its header); `--shard K/M` with shard-aware fail-closed baseline check (S5) |
| (oracle F-D floor, arc-12) | `util/cerb_fresh.ml` two-check per-TU fail-stop floor + `backend/common/ail_sym_hwm.ml` (desugar hwm fold) + `pipeline.ml` hook: any TU whose desugar-threaded symbol ids can overlap ambient ids REFUSES loudly (`CERB_FRESH_FLOOR_VIOLATION`, exit 70) instead of silently corrupting (finding F-D). test_exec.sh classifies these as `CERB_FLOOR` (SUMMARY `cerb_floor=`; unbaselined floor rows FATAL). Two narrow warn-only modes (D2, never silent): cabs-json EXPORT (verified sound — the JSON is pre-desugar Cabs) and `CERB_FRESH_FLOOR_GRANDFATHER=1` (ONLY the two documented test_libxml2_uri.sh invocations). Records: `docs/2026-08-21_arc12-*.md`; renumbering (removing the refusal class) = post-arc-13 agenda |
| `scripts/fuzz_csmith.sh` | csmith differential fuzz kit (arc-4 port; csmith + creduce are INSTALLED locally — gen + test_exec.sh differential; deterministic via `CSMITH_SEED_START`). Arc-10 S4 lane portfolio + seed ranges: `docs/2026-08-20_arc10-s4-csmith-campaign.md` |
| `scripts/csmith_explore.sh` | Arc-10 S4: oracle-only per-configuration yield + construct-coverage measurement (the exploration instrument behind the lane portfolio) |
| `scripts/creduce` + `scripts/creduce_interestingness.sh` | Arc-10 S0: creduce wrapper (project-local clang-format shim, no global state) + generic interestingness predicate against test_exec.sh single-file mode (`INTERESTING_REGEX` + `EXPECT_SNIPPET` signature pinning) |
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

**Bug reports:** `lean_frontend/lembugs/` — dated markdown files with reproducers.

## Remaining work

### Sorry target_reps (non-concurrency)
- NONE (arc 4: `easy_update_mem_value_aux` un-sorried via a fuel declare;
  `runND_proxy` is implemented — hand-written `CerbND.runND`).
  Concurrency stubs remain the declared boundary.

### Pipeline status (updated 2026-08-21, post arc-9 — see the arc results docs)
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
- ✅ THE ORACLE IS HONEST (arc-12): the F-D symbol-collision family is
  CLOSED-BY-FLOOR — the fork oracle fail-stops (CERB_FLOOR) on any TU
  beyond its ~483-id desugar margin instead of silently corrupting;
  all 35 witnesses loud; numbering of in-margin programs bit-for-bit
  unchanged (pin-provenance + generated-tree gates); corpus
  re-baselined (mismatch=0, comparisons 1070→1038); libc/uri pinned
  artifacts D2-grandfathered (validated-by-agreement, register G1-G4);
  attribution corrected (April desugar threading 8923d6436, arc-2 run
  supply exonerated); F-A/F-B upstream filing drafts ready
  (notes/upstream/08+09). Records: docs/2026-08-21_arc12-*.md
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
- ✅ ROBUSTNESS (arc-10): comparison instances are REAL — the lem
  backend derives structural BEq/Ord/SetType/Eq0/Ord0 with
  OCaml-poly-compare parity (generated-tree comparison-sorry census
  1134 → 0; fn-carrying types get loud failwithI residuals,
  fail-closed). tests/ci exec mismatches at ZERO (114/114 comparable
  agree: finding 11 read-only allocations + the pp-placeholder ctype
  text class closed by real OCaml mirrors); coverage 186/186
  comparable agree (finding 8 eqPtrval msum fork fixed). New lanes:
  tests/float (69/69 MATCH), tests/bytes (oracle-independent, 9 exec
  + 5 neg pins), csmith corpus (1669 files, classified baseline) + a
  5-lane csmith generation portfolio — 3169 differential programs,
  ZERO Lean-side semantic defects; the F-D oracle-corruption family
  root-caused to a CERBERUS-LEAN FORK regression (arc-2 threaded
  sym_supply suspect; repair = top next-arc candidate). See
  `docs/2026-08-21_arc10-results.md`.
- ✅ THE WORKBENCH (arc-9, "WP tactic library + complex-reasoning
  slate"): proof machinery built deliberately — OwnP adoption
  (iris-lean reuse, hand-rolled ghost twin retired, Iris layer
  456→369 lines), six lemma kits with 54 in-build exactness pins
  (incl. the AXIOM-FREE `iter_compose` loop rule), the `@[app_eq]`
  law table + `app_walk` walker v1-v3 + the per-stage certificate
  emitter (kernel-whnf discovery, decide-facts chase-rewrite,
  ledgered budgets — every certificate an ordinary kernel-checked
  declaration, zero TCB surface), the proof-size gate (Tier A,
  fail-closed, T5 row honestly PENDING). THE CALIBRATION: the
  mechanical dnms content (~200 lines of rounds + transcriptions +
  `.trans` composition) → 5 walker lines; file-level T1AppEq 1,038 →
  862 (the round3/round6 semantic support retained and consumed by
  the walker); identical statement + cone. T5 (bounded loop) PARKED
  AT EVIDENCE GRADE: St-v2 family
  kernel-validated at symbolic n, entry theorem green in ~5 s, probe
  clears 44/79 iteration rounds; named resumption point =
  the continuation-lambda advance law (+ trace/replay +
  context-indexed laws — the v2 slate). T1-T4 re-validated on the
  arc-10 rebased base (cones exactly [propext, runEffectful,
  Classical.choice, Quot.sound]). See
  `docs/2026-08-21_arc9-results.md` + the committed v2 survey
  inputs (`2026-08-21_iris-rules-automation-survey.md` + Lithium
  review + litreview brief).

## Conventions

- Hand-written files in `lean_frontend/`, generated files in `lean_frontend/generated/`
- `set_option autoImplicit true` in hand-written files (project default is false)
- Follow OCaml implementation as reference, with lean-c-semantics as secondary reference
- No sorry in hand-written code — use `fail`, `panic!`, or real implementations
- Bug reports for Lem issues go in `lean_frontend/lembugs/` with date prefix and reproducers
