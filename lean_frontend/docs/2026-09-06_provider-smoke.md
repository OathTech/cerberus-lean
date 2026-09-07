# Clean provider build and consumer proof

2026-09-06 [AGENT], validation-foundations G5. The repaired candidate at
`de9f6d3612232d581622afcdf0b23cdaf31fa09d` completed a new 20-command cold
rehearsal. The [repair evidence](validation-foundations-repair-evidence/provider-summary.json)
identifies its fresh compiler/runtime, unchanged generated sources, proof and
failure measurements. Second-review acceptance and customer adoption remain
pending. The earlier rehearsals below are preserved history.

The original delivery's final cold rehearsal
completed all 20 steps from Cerberus
`1066d89eea16f55a0f204f95c351731629df296a` and Lem
`f6542f8e6860d12d4655e6648bc4c45dabd1d798`.
The [final manifest summary](validation-foundations-evidence/final-provider-summary.json)
and raw build/proof archive (`final-provider-failures.tar.gz`, dropped at landing [USER 2026-09-06]; identity in [SHA256SUMS.dropped](validation-foundations-evidence/SHA256SUMS.dropped)); inventory [final-provider-failures.json](validation-foundations-evidence/final-provider-failures.json))
identify every command, source and artifact. This record does not claim
adoption by refined-cerberus, whose work remains with its agent.

## Reproduction

From a checkout carrying this recipe, in the project's OCaml environment:

```bash
python3 scripts/build_provider_smoke.py \
  --cerberus-rev "$(git rev-parse HEAD)" \
  --lem-repo /home/dev/projects/cerberus-lean-proj/lem-lean \
  --out .validation-foundations/provider-cold
```

Use the container's `scripts/ce` to load its scoped OCaml/Git environment.
The output directory must be new. The release/provider supervisor also
requires Linux cgroup v2 delegation with memory enabled and `cgroup.kill`.
It contains the supplied commands in owned subtrees, defers cancellation
during cleanup, and stops subsequent dispatch after delivering it; a pipe
guardian cleans after supervisor death. This is a command-lifetime mechanism,
not isolation from code that deliberately migrates between cgroups. See the
[audit repair record](2026-09-06_validation-foundations-audit-repairs.md).
The repositories supply local Git objects;
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

## Completed candidate evidence and limits

The final rehearsal used `.validation-foundations/provider-cold-final-1066d89`.
All 20 steps passed, with unchanged tracked sources in both detached trees.
The owned Lem install prefix and three install helpers remain untracked build
products. Root/spec-lab/micro package builds took 171.1/91.5/1.3 seconds; the
external proof 2.1 seconds; standalone runtime 5.4 seconds; comprehensive
407.3 seconds. These are single-run observations. Compiler/runtime and
generated/artifact hashes are in the archived manifest; all 207 Lean and
86 OCaml generated files match the earlier rehearsal. Both G6 instruments
were run directly with this final provider build.

The development history remains separately identified below.

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

The [provider adoption manifest](validation-foundations-evidence/provider-adoption.json)
identifies the functional candidate, all package/compiler/runtime pins,
interface migration records, cold evidence, failure obligations and theorem
boundaries. Customer re-pin/build evidence and the landing audit remain
separate decisions. This is a proposed provider checkpoint, not a release
certification or an instruction sent to the customer's agent.
