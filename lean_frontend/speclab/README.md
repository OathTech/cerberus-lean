# speclab — harness-family differential test lanes

A Lake package of pure-Lean reference models, byte codecs, and a C
harness renderer (`mkHarness`), feeding the
`scripts/test_speclab*.sh` differential lanes: each lane renders
closed, deterministic C harness programs from a compiled-in choice
stream, runs them through BOTH pipelines (OCaml oracle and the Lean
semantics), and requires bit-for-bit verdict agreement — with the
pure model's prediction as a third triangulation point. Every
template ships a plant test (a deliberately broken target must go
red on both pipelines — vacuity must be loud).

The five harness families (born arc-15, 2026-08-22/23, as a spec-lab
ladder; retained as differential validation lanes): scalar divmod →
byte arrays → linked lists → tree rotation → a CN-seed program.
Together the lanes have run ~2,000 differential executions, all
agreeing.

## The standing invariant

**Every harness instance stays concretely runnable and
oracle-differentiable.** Harnesses are programs: all variation enters
through channels the semantics defines for programs; each resolved
instance is a closed, deterministic C program both pipelines run
bit-for-bit.

## Package layout

| Path | What |
|------|------|
| `SpecLab/Codec.lean` | Self-delimiting byte codecs (LE scalars, length-prefixed arrays) with `decode∘encode = id` round-trip lemmas |
| `SpecLab/MkHarness.lean` | `mkHarness` v1 — the choice-stream C source splicer, THE single trust point: three literal template parts + rendered `choices[]`/`expected[]` byte arrays, four-way concatenation, nothing else |
| `SpecLab/DivMod.lean` etc. | Per-family reference models (`DivMod`, `ByteArr`, `ListAppend`, `TreeRot`, `CnSeed`) — pure functions predicting the harness verdicts, plus edge sample sets |
| `SpecLab/*Harness.lean` | Per-family harness templates (mismatch-index / boolean / stdout forms) + plant twins |
| `SpecLab/*Core.lean` | GENERATED (speclab-emit-\*; drift-gated): parsed Core AST terms for the pinned harness instances |
| `test/Unit/SpecLabTest.lean` | `speclab-test`: executable sanity layer (codec spot checks, renderer parse-back round trip) + the emitters the lane scripts consume |
| `test/SLUnit/` | The emit instruments (`speclab-emit-*`) and per-family drift/param/exec gate exes (`speclab-*core-test`, run by each lane's `--gate` mode against the pinned `tests/speclab/*.core` dumps) |
| `../../scripts/test_speclab.sh` | Plant-test runner: harness → both pipelines → agreement + expected verdict (`--selftest`, `--plant`) |
| `../../scripts/test_speclab_{divmod,bytearr,list,tree,seed}.sh` | The five family lanes: `--sweep`, `--fuzz N [SEED]` (byte-wise shrinker), `--plant`, `--gate`, per-family extras |
| `../../tests/speclab/` | Pinned harness fixtures (`*.c` + oracle `*.core` dumps) |

Dependency direction: speclab requires the semantics (`CerberusLean`,
by path); nothing under the semantics may reference speclab.

## Attribution — the golean idiom lineage

The harness idiom is adopted from golean (`deps/golean`,
design-donor attribution):

- The three-phase harness shape: setup (build all memory the test
  needs) → the call under test → test phase folding memory analysis
  into RETURNED VALUES; the program converts memory to observables.
- The copy-relational check (a history ghost materialized as real
  program code) as the honest way to check relations without
  re-deriving setup algebra.
- The CBMC parallel: a closed test program exercised over its inputs.

Where we deliberately differ: the choice stream is compiled INTO the
program (`choices[]`), so all variation is resolved before the
program exists — every instance is closed and deterministic and the
oracle runs it natively (full differential/replay); the default
comparator returns a mismatch INDEX (`0` agreement / `1+i` first
divergence / `255` length divergence) rather than a boolean.

## Building / running

```bash
# package build — capped, always
cd lean_frontend/speclab && ../../scripts/capped lake build

# executable sanity layer + emitters
../../scripts/capped lake build speclab-test && ./.lake/build/bin/speclab-test

# end-to-end (both pipelines, from repo root; scripts/ce for env)
./scripts/test_speclab.sh --selftest   # identity harness, expect Specified(0)
./scripts/test_speclab.sh --plant      # corrupted expected[], expect Specified(2)
./scripts/test_speclab.sh <harness.c> 'Specified(0)'
```
