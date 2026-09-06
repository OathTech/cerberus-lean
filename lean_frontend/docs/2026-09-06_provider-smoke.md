# Clean provider build and consumer proof

2026-09-06 [AGENT], validation-foundations G5. The development rehearsal
completed from Cerberus `5d2f380de` and Lem
`f6542f8e6860d12d4655e6648bc4c45dabd1d798`. Final-candidate evidence remains
part of the charter's close-out. This record does not claim adoption by
refined-cerberus, whose work remains with its agent.

## Reproduction

From a checkout carrying this recipe, in the project's OCaml environment:

```bash
python3 scripts/build_provider_smoke.py \
  --cerberus-rev "$(git rev-parse HEAD)" \
  --lem-repo /home/dev/projects/cerberus-lean-proj/lem-lean \
  --out .validation-foundations/provider-cold
```

Use the container's `scripts/ce` to load its scoped OCaml/Git environment.
The output directory must be new. The repositories supply local Git objects;
their mainline worktrees are not modified. The recipe creates owned detached
worktrees and a fresh dependency clone. It neither runs the worktree-priming
helper nor copies generated Cerberus, native objects, or Lake build products.
Immutable dependency source files and installed toolchains may be reused.

The manifest records source heads/dirtiness, initial absent build directories,
every command/status/time/log hash, locally built Lem compiler and OCaml
runtime, all three Lake package manifests/configurations, generated source
hashes, native and executable artifacts, and the external client source.
The three Cerberus packages use Lean 4.32.2 and the same LemLib commit;
standalone Lem uses its declared Lean 4.28.0. Dependency build directories
belong to this rehearsal, not a shared cache.

Lem's compiler, generic OCaml libraries and OCaml runtime are rebuilt in the
owned Lem tree. Installation uses its `local-install` prefix, including the
runtime makefile's `INSTALLDIR` variable. The recipe verifies actual findlib
resolution before Cerberus generation. It uses `DUNE_CACHE=disabled`, Dune
`--force`, and `scripts/capped` for all Lake/Lean activity. The native-object
make invocation is itself capped because it invokes `lake env` internally.

Before generation, both shipped `check_lem_sync` checks must reject the
empty trees. A wrong compiler and a changed third-package runtime pin must
also be rejected; each mutation is confined to the rehearsal and restored
before the positive build. The first development attempt correctly stopped
on a recipe bug: the compiler version grammar is `Lem f6542f8`, including
the prefix. The corrected new-directory rehearsal completed.

## What the client proves

[ProviderSmoke.lean](../../tests/provider-smoke/ProviderSmoke.lean) imports
the delivered `Unit.FuelExemplar` compositional lemmas and
`LemLibPmapLaws`. The former belongs to the provider's test library and
defines a fixed closed Core program whose `main` returns integer 42.
The client has no replacement semantics.

`ProviderSmoke.completed k` states that the actual `drive`/`CerbND.runND`
entry returns exactly one `Active` result at ambient fuel `k + 2`, and its
Core value is 42. This includes existence and completion, so an always-failing
runner cannot satisfy it. Preconditions are the fixture's closed Core file,
empty tag environment, initial filesystem and `argv = ["cmdname"]`.
It proves nothing about arbitrary C parsing, linking, libc or concurrent C.

`ProviderSmoke.remember_result` instantiates the delivered lookup-after-insert
law for `Nat` keys and actual `driver_result` values. Its precondition is
`Pmap.WF defaultCompare m`; the library supplies the comparator's
strict-weak-order laws through `Pmap.cmpLaws_of_transOrd`. This is a law of
the shipped map implementation, rather than a replacement map abstraction.

Both theorems build in an external Lake package. Their printed axiom cones
contain only `propext`, `Classical.choice`, and `Quot.sound`. No heartbeat,
recursion-depth, fuel-policy, opaque-boundary, or model change was made to
obtain this result. The client intentionally depends on a provider fixture
API; it does not certify stability of every public interface.

## Completed development evidence and limits

The cold rehearsal at `.validation-foundations/provider-cold-dev-v2` passed
all steps: fresh generation, OCaml build, native object, the root semantics
package, spec-lab, the memory micro-benchmark package, the external proof,
standalone Lem's four runtime targets and `tests/comprehensive: make lean`.
Measured package build times were about 170, 91 and 1.4 seconds; the client
about 2.2 seconds; standalone runtime 5.5 seconds; comprehensive suite
402 seconds. These are single-run measurements, not performance promises.

The comprehensive suite retains explicit expected failures. The byte/string
port defects remain failures; the separately ruled host-integer overflow
deviations remain documented exceptions. A green suite does not turn those
cases into unconditional OCaml/Lean parity. No shared opam pin, mainline
branch, customer checkout or legacy csmith activity was changed.

The final provider adoption manifest must identify the actual landing
candidate, compiler/runtime pins, clean recipe report, supported profile,
failure obligations, and consumer-facing theorem boundaries. Customer
re-pin/build evidence and the landing audit remain separate decisions.
