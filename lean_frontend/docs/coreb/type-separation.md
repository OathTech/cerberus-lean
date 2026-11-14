# First experiment: Core / CoreB type separation

This implements work package 1 of the [baseline scope](coreb-baseline-scope.md).
It establishes independently generated, nominally distinct syntax and a small
real consumer/support closure. The full B translator, evaluator, driver and
differential harness remain work packages 2–4.

## What is present

`frontend/coreb/sources.json` identifies the original revision and every owned
source. The three Lem copies are `core.lem`, `errors.lem` and `core_linking.lem`.
This is the complete Core syntax, including program containers, not a selected
expression subset. Errors must be copied because they embed Core types.
The linker is a real consumer of B programs and expressions.

The handwritten copies are `Core_lemMeasureProofs.lean` and
`CerbCoreShape.lean` in `lean_frontend/coreb/`. These exercise a real measure
proof and predicates over the new syntax. Shared dependencies include C types,
AIL/Cabs, locations/symbols, memory/concurrency data, exception and utility
services, and LemLib.

`tools/generate_coreb.py` invokes the pinned Lem separately, using the original
ordered input list from `make lean-source-list`. Owned inputs replace their
original paths; all remaining inputs use Lem's input-only `-i` option. Keeping
the input environment preserves the generator's existing name disambiguation.
The ordinary generator never copies A sources over B's owned sources.

The packaging step maps only actual header imports of owned modules to
`CoreB.*`, then encloses the unchanged declaration body in `namespace CoreB`.
The same operation handles handwritten support. It leaves comments, diagnostic
strings, terms and proof bodies unchanged. Generated files live under
`lean_frontend/generated/CoreB/` and are not committed. Lem itself is unchanged.

The Lake targets are `CerberusCoreB` (all eight generated/support modules) and
`CoreBSeparationTests`. They are explicit research targets; the ordinary default
targets remain unchanged.

## Reproduce

Install the pinned Lean toolchain and the pinned Lem into a project-local opam
switch using the [provider setup instructions](../../README.md#build-and-run-one-differential-test).
This experiment needs generation and Lean compilation; an OCaml Cerberus
executable or native runtime object is not needed for these targets.

From the repository root, in Bash:

```bash
cap() { if command -v capped >/dev/null 2>&1; then capped "$@"; else "$@"; fi; }
export CAPPED_MEM_MAX=32G

cap opam exec --switch=. -- make lean-prelude-src coreb-prelude-src
cap opam exec --switch=. -- python3 tools/generate_coreb.py --check-baseline
python3 tests/coreb/test_packaging.py
(cd lean_frontend && cap lake build CerberusCoreB CoreBSeparationTests)
```

The initial source-identity report checks the owned and original files against
the recorded Git baseline, plus raw generated bodies against fresh Core output.
Only the generated first-line source-path comment differs. This comparison is
specific to the unchanged baseline; it is not an equivalence check and will
deliberately fail after intentional Nice source changes. Normal generation
does not run the identity check or overwrite the owned sources.

The local experiment bootstrapped Lem at the same pinned revision from an
independent local source clone in `.lake/packages/LemLib`, using an existing
OCaml 5.4.0 toolchain without installing into or changing its switch. Compiler
output, generated modules and Lake artifacts belong to this worktree. The
portable commands above use the ordinary project-local Lem installation.

## Checks and limits

The co-import test checks that B expression, type and program declarations are
distinct inductive/structure declarations, rejects passing A expressions/files
to B consumers, and pins the linker's elaborated B file/error signature.
It constructs both ASTs, uses the copied shape predicate, and checks local
equations over the copied type equality and linker entry helper. It also
inspects the generated auxiliary theorem's actual reference to the B-owned
handwritten measure proof. `#print axioms` covers the named B witnesses.

The Python tests exercise the adapter's import boundary, nested/header/body
comments, diagnostic-string preservation and malformed-header refusal.
Generation refuses missing owned sources, unexpected output files, and stale
generated B modules outside the manifest. These are focused checks on the
generation mechanism, not a new whole-repository gate.

Important limitations retained from the baseline:

* Four linker traversals are existing `partial def`s: `symbols_in_pattern`,
  `free_pexpr`, `free_expr`, and `topo_order`. They are copied unchanged and are
  not claimed to reduce in kernel proofs. The local linker equation uses the
  reducible `link_main` entry helper; it proves no general linker correctness.
* Building the pinned Lem compiler emitted existing OCaml warnings, including
  partial matches, unused bindings and deprecated automatic `str` inclusion.
  Lem generation also reports the same name-renaming warnings as the original
  path. They have not been suppressed or repaired in this experiment. Lem
  changes require discussion before implementation. Lean targets retain
  `warningAsError=true`.
* Shared frontend, memory and utility services are deliberate dependencies.
  Separation does not independently validate them or establish equivalence.
* The full whitespace report flags inherited trailing whitespace/EOF spacing
  in the three Lem copies. They deliberately remain byte-identical to the
  pinned originals; newly authored files pass the whitespace check.
* This slice contains no B interpreter, choice replay, C differential results
  or Nice semantic additions. It is a generation/type-separation result only.

## Decisions

* [USER, 2026-11-14] Proceed with the reviewed experiment; discuss a concrete
  Lem change before implementing one if the experiment exposes that need.
* [AGENT, 2026-11-14] Use the complete AST, errors and linker with the existing
  shape and Core measure-proof helpers for the first closure. This exercises
  syntax, a real consumer and auxiliary binding without prematurely pulling
  in the entire interpreter.
