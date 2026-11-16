# First experiment: Core / CoreB type separation

This historical record describes work package 1 at `cf939a4c432b9d1eb257daad93da04e6da686e99`.
Its inventory, commands and results below refer to that first checkpoint,
including its historical CoreB names. The pathway is now called CoreNice;
use the current guide for the renamed commands.
The expanded execution path and current build are described in
[the interpreter and runner](interpreter-runner.md).

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

## Validation and review

Implementation candidate: `cf939a4c432b9d1eb257daad93da04e6da686e99`.
The source-identity report, three Python packaging tests, and the focused
`lake build CerberusCoreB CoreBSeparationTests` passed. The named type-equality
and measure-binding witnesses report only `propext`, `Classical.choice` and
`Quot.sound`; the shape and linker-entry witnesses report no axioms. Expected
rejection diagnostics from `#check_failure` are negative tests, not admitted
declarations. The original generation-sync, handwritten-sync and Lake-root
checks also passed. No full repository campaign or kernel replay was run for
this draft experiment.

An independent unrestricted review (`coreb_type_review`, 2026-11-14) found the
first work package ready for research integration, with no blocking technical
finding. The reviewer independently compared all five owned inputs and eight
emitted/support outputs, inspected the B compilation import maps and test
bindings, and ran the Python tests. It inspected the successful Lean build
output without repeating the build or replay.

The P3 finding was stale feasibility wording in the scope document. It is
corrected to distinguish the tested first closure from the still-unbuilt full
execution path. The record/status correction changes no compiled source and
reuses the candidate's focused checks.

## Decisions

* [USER, 2026-11-14] Proceed with the reviewed experiment; discuss a concrete
  Lem change before implementing one if the experiment exposes that need.
* [AGENT, 2026-11-14] Use the complete AST, errors and linker with the existing
  shape and Core measure-proof helpers for the first closure. This exercises
  syntax, a real consumer and auxiliary binding without prematurely pulling
  in the entire interpreter.
