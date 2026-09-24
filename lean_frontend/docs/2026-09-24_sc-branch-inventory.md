# SC prototype: frozen branch inventory and migration handoff

Date: 2026-09-24. Author: implementing agent. This report accompanies the
[independent project-scope review](2026-09-24_sc-independent-scope-review.md),
which is preserved separately and verbatim. This inventory is not an independent
certification, a new execution plan, or a claim that SC is complete.

## User instruction and status

[USER] “When you get the review, land it on the tip of the branch, along with a
detailed report on what's in the branch. We're starting a new branch in a new
agent with a proper plan, with careful migration of the bits that actually work.”

Implementation on this branch is frozen. This handoff adds documentation only;
it does not fix the findings, start a successor branch, migrate code, merge, or
push. The old charter and its autonomous execution queue are superseded. The
successor agent owns the new plan; recommendations below are migration advice,
not user approval of a replacement architecture or milestone.

The overriding goal remains faithful operational Cerberus semantics, respecting
the available ISO C and upstream semantic information. The provider must expose
its actual execution for downstream reasoning; it must not restrict Cerberus to
make Iris reasoning easier. `/home/dev/projects/cerberus-sl` remains strictly
read-only, including its dependencies, build artifacts and caches.

**Assessment:** substantial execution machinery works in focused controls and
selected C runs. Public SC is unfinished. Its universal scalar candidate
admission rule rejects ordinary ordered byte and member accesses, despite their
working in the underlying concrete interpreter. It also suppresses discovery of
independent conflicts after an unrelated interpretation gap. These are central
implementation defects, not merely missing acceptance paperwork.

## Snapshot identity and size

| Item | Identity |
|---|---|
| Branch | `arc/sc-prototype` |
| Worktree | `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype` |
| Reviewed implementation tip | `631382a9d23a709112f38add53357d4cbe6fc108` |
| Implementation base | `5407597d9eeba0259d65b728e86a860ad4614ab3` |
| Pristine Cerberus reference | `b9aeedcb4dd438763b0eef7f95ac19e93875d7de` in `/home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream` |
| Lem / LemLib pin | `38f87d5fa6b29ec90edfa457faba8a309e32c118` |
| Lean | `leanprover/lean4:v4.32.2` |
| History | 29 commits after the implementation base, before this handoff |

The base-to-tip diff has **402 files, 331,885 added lines and 91,077 removed
lines**. `tests/libc/libc.core` alone accounts for 306,974 additions and 88,503
deletions, largely the regenerated Core fixture and location transport. Excluding
that file leaves **401 files, 24,911 additions and 2,574 deletions**. Diff size is
not a measure of semantic coverage or distance to completion.

Most generated Lean and OCaml model trees are ignored build outputs. The
authoritative migration sources are `.lem`, handwritten seams, generation/build
registrations and relevant fixtures. Some native control `.ml` files are tracked
alongside their `.lem` sources. Do not copy a populated generated tree as the
implementation, or cherry-pick all 29 commits on the assumption that each is an
independent feature.

## What execution actually does

The C frontends elaborate through the shared AIL/Core pipeline. Both public
drivers select `Driver.drive true` for `--concurrency=sc`. Core execution still
uses the concrete memory implementation for values, bytes, provenance, lifetime
checks and memory faults. SC scheduling offers thread/interleaving choices at
the implemented Core action and helper-service boundaries. Memory observations
record actual completed primitives; the scheduler is not reconstructing reads
or equal-value writes from differences between stores.

The driver records occurrences, source sequencing, calls, threads and memory
effects. After effects it reconstructs a prefix interpretation, projects actions
and relations into a derived instance of the pinned Cmm reference, and retains
findings. Normal completion classifies the final candidate and produces the
existing result or a typed race, protocol, interpretation, sequencing or
consistency failure. Earlier operational faults retain their failure-time state.

The current adapter assigns locations to whole supported accesses and requires
a read to have one matching writer with the same range and compatible logical
value. Array-element, signed/unsigned, enum and whole-aggregate extensions have
made more examples pass. They do not solve reads assembled from several writes,
ordinary aggregate/member overlap, or general representation access. Adding
exceptions to this admission test became the wrong organizing principle.

An operational executor may legitimately use reference predicates. The problem
is not the presence of Cmm checks; it is allowing an inadequate projection to
determine which concrete C programs the implementation supports. The historical
Cerberus operational weak-memory construction and proof are reference material,
not a working drop-in SC backend for today's concrete Core path. The research
assessment and contract identify that distinction; neither establishes adequacy
of this branch's adapter.

## Migration inventory

“Keep” below means a useful candidate for careful migration with its relevant
controls, not a guarantee that it is independently correct or can be copied
without its dependencies. Paths are relative to the repository root.

### 1. Primitive observations and checked lifting — keep

- Shared interface and transport: `frontend/model/mem.lem`, `mem_common.lem`,
  `nd_observe.lem`, `nondeterminism.lem`, and the lifting code in `driver.lem`.
- Actual producers: `memory/concrete/impl_mem.ml` and
  `lean_frontend/CerbMem.lean`; interface mirror in
  `ocaml_frontend/memory_model.ml`.
- Lean propagation/support: `CerbND.lean`, `CerbNDObserveProofs.lean`,
  `CerbMemSuspension.lean`, `CerbSCServices.lean` and updated fuel proofs.

The journal includes reads, same-value stores, allocation/deallocation,
representation bytes/provenance and abstract varargs metadata. Checked lifting
drains completed observations on both success and failure, preserving the last
state. This is essential operational evidence and should remain canonical.
Alternative memory backends have explicit observer/value-key/suspension
unavailability stubs; these changes do **not** implement SC for CHERI, symbolic
or VIP memory.

### 2. Scheduler, sequencing and resumable services — keep

Primary sources are `driver.lem`, `core_run.lem`, `core_run_aux.lem`,
`core_reduction.lem`, `sc_runtime.lem`, `sc_spawn.lem`, `sc_order.lem`,
`sc_graph.lem`, `sc_call_scope.lem`, `sc_call_context.lem` and `sc_scopes.lem`.
Lean support includes `CerbSCAccessGroups.lean`, `CerbStepInstances.lean` and
`Sc_order_lemMeasureProofs.lean`.

Useful behavior includes structured spawn/join; child lexical ownership for
loop-label resolution; distinct occurrences and call scopes; source sequencing
with non-action vertices; and scheduler-visible helper pauses. A resumed memory
service uses the current shared memory after another thread has run. Ordinary
SeqRMW read/write phases can interleave while preserving the modeled same-thread
call exclusions; atomic object phases remain indivisible. Child errno allocation
is implemented, using indeterminate initialization rather than invented zero.

Filesystem service ownership prevents conflicting concurrent FS transactions
while a paused service permits other memory execution. It does not supply ISO
stream locking. The `NDsuspend` constructor affects generic ND bind/lift/runners
and their proofs; it cannot be migrated as a driver-only edit.

### 3. Atomic operations and the C/Core surface — keep with boundary audit

The substantive path spans `atomic_order.lem`, `core.lem`, `translation.lem`,
`builtins.lem`, AIL typing, the driver and both memory implementations. Core
gains atomic-update, signal-fence and typed model-gap forms. `Ememop` gains an
annotation, requiring updates to all Core consumers.

Implemented slices include strong/weak CAS, permitted spurious failure and
expected writeback; exchange and fetch/update bodies; single evaluation of
arguments; operation-specific order checks; fences and signal fences;
non-synchronizing initialization; and callable flag/fence interfaces. Headers
and bodies are in `runtime/libc/include/stdatomic.h`, the new
`__cerb_atomic_flag.h`, and `runtime/libc/src/stdatomic.c`, with dune staging.
These are genuine C-to-Core/runtime changes, not just model-level examples.

Preserve precise checks and completed-effect prefixes. G01/G04/G05 and runtime
G06 have typed producers, but the preprocessing hole remains. Known upstream
atomic initializer conversion and atomic-byte-access behavior must be accounted
for explicitly; passing SC controls does not authorize changing sequential C.

### 4. Lossless values, bytes and source locations — keep

`sc_value.lem`, `sc_byte_key.lem`, `sc_byte_sources.lem`,
`sc_representation.lem`, `CerbSCValues.lean`, `CerbSCByteInstances.lean`,
`CerbFloatValue.lean` and the native/Lean float seams preserve representation
information, including signed zero, NaN bits and pointer provenance. Raw
representation equality and a justified cross-view RF equivalence are different
operations. Keep that distinction and the tests that distinguish them.

Core text/JSON location transport crosses `parsers/core/`, the OCaml printers,
`util/cerb_location_json.ml`, `backend/lean_export/cabs_json.ml`,
`lean_frontend/CoreParser.lean`, `CerbPP.lean` and libc preparation. The large
`tests/libc/libc.core` regeneration belongs to this dependency group. Speclab
embedded Core terms and constructor matches also changed. Migrate syntax and
transport coherently; do not treat those large generated diffs as separate
semantic features.

### 5. Reference predicates and production candidate — split keep from redesign

`sc_reference.lem` and `sc_reference_aux.lem` are mechanically derived by
`scripts/sync_sc_reference.py` from `frontend/concurrency/cmm_csem.lem` and
`cmm_aux.lem`. Predicate bodies are retained; action IDs use the new carrier and
target names are separated. The selected reference is the fence-aware SC model,
not the narrower initialization condition or a newly imported C++ model.
Retain the derivation and reference identity. The Cmm equality target-selector
repair in `cmm_csem.lem` is separately useful: Lean selects the existing
executable action/pre-execution/witness equality rather than conflicting target
declarations.

`sc_candidate.lem` is now on the public execution path. It interprets the
journal, builds actual RF/MO/SC and source/HB relations, invokes reference checks
and returns classifications. Valuable pieces include occurrence identity,
full source graphs, two RMW occurrences associated with one atomic action,
retained finding IDs, and reference-derived interthread HB for varargs conflicts.
Same-thread cursor conflicts use source sequencing.

Do **not** wholesale preserve its universal single-writer/range admission rule,
the global “any issue disables all new races” rule, or broad implementation
refusals as the new language's contract. The independent review explains why
both ordinary object composition and independently justified conflict discovery
need a precise replacement. Merely dropping non-atomic actions or removing the
global guard would not be justified: uncertain synchronization can affect a race.

Prefix checking currently rebuilds and rescans accumulated history after each
effect. The ancestry index in `sc_order.lem` improves one calculation and has
finite reference comparisons, but the total repeated work remains a scalability
concern even for a single selected execution. Any successor optimization should
follow measurements and preserve findings before faults, exhaustion and loops.

### 6. Attribution and alternative interpretation helpers — retain selectively

The 27 shared `sc_*.lem` modules include additional attribution and query paths:
`sc_global_bindings`, `sc_global_origins`, `sc_definition_sources`,
`sc_global_attribution`, `sc_link_attribution`, `sc_parameter_reads`,
`sc_access_group`, `sc_action_identity`, `sc_access_sequencing`,
`sc_atomic_sources`, `sc_happens_before`, `sc_synchronization` and `sc_varargs`.

Actual global initialization and loader/linker/call origins now reach the driver.
That is useful evidence for precise runtime guards. However, the current
production library check mostly attaches a broad protection obligation to
library effects, except evidenced private parameter reads. Precise stream and
shared-library-internal guards remain absent.

The review identifies test-only alternative routes through
`Sc_atomic_sources`, `Sc_synchronization` and `Sc_access_sequencing` that duplicate
production work. Consolidate around the actual chosen interpreter; migrate
attribution only where the concrete runtime producer consumes it. A passing
query suite is not evidence that public execution uses that query.

### 7. Whole-program provider API — keep; narrow the demonstration claims

In `driver.lem`, `sc_program` packages the actual driver state **and saved
continuation**. `sc_program_entry`, `start`, `node` and `resume` retain global
initialization, main, finalization, branch labels/constraints and paused services.
Driver state alone cannot reconstruct a paused program. Internal `SC_halted`
does not imply completion of the outer computation.

[`CerbSCOperational.lean`](../CerbSCOperational.lean) exposes initialization,
terminal inspection and the existing outcome runner. Semantic fuel is captured
at construction; exploration depth is a separate explicit budget. Resume does
not renew fuel. The CLI chooses equal bounds. Continuations have no usable
executable equality; this interface does not justify merging configurations.

[`examples/sc_consumer`](../examples/sc_consumer/README.md) is a separate Lake
package importing the provider by path with the same toolchain/dependency pin.
It compiles and demonstrates definitional connections to the real driver. Its
fault-assertion theorem assumes the assertion on the reported state; it is not
an invariant preservation, adequacy, Iris or fuel-monotonicity theorem.

The retained state carries more information than public batch output. In
particular, `Main.lean` reports the primary fault/exhaustion without the state's
retained SC findings. The reviewer recommends a small observation projection
and a meaningful offered-step example, not a second reasoning framework.

### 8. Filesystem failure preservation and supported subset — useful, separate scope

`ocaml_frontend/fs_checked.ml`, `frontend/model/fs.lem`, driver service code and
`lean_frontend/CerbFS.lean` distinguish actual success, errno, upstream OS
special cases, port coverage gaps and protocol faults. They preserve the last
defined filesystem state at the exact failing phase instead of guessing success
or rolling back completed effects. These repairs should survive migration where
that service path is retained.

The implemented Lean subset includes direct-root ordinary files, descriptor
reuse, access rights, truncate, read/write/pread/pwrite, close/lseek, selected
closed-file unlink/rename, and the modeled standard descriptors 0–2. It does
not complete directories/cwd, permission/owner transitions, links, full stat,
directory streams or open-inode retention across unlink/rename. Unsupported
filesystem state ordering now fails explicitly instead of equating every state.

The independent review recommends separating the inherited full filesystem port
from SC composition. No user decision accepting a new scope is recorded here.
Keep the existing repair and disclosed limits; do not silently make full FS
completion a migration prerequisite or describe ordinary port omissions as ISO
semantic uncertainty.

### 9. Build registrations, fixtures and validation infrastructure — use proportionately

Generation and interface changes cross `Makefile`,
`lean_frontend/handwritten_copy.manifest`, `lakefile.toml`, native dune files,
backend driver/pipeline interfaces, SMT/rewriters and other Core syntax users.
The source shape also touches BMC, absint and the web instance. This is why
copying only files whose names contain `SC` is insufficient.

There are two consolidated Lean entry points, `sc-machine-test` and
`sc-adapter-test`, plus one native executable with 14 fixture groups in
`memory/concrete/sc_controls`. Keep discriminating operational controls with the
code they exercise. `tests/sc/` has 92 tracked files including its README; these
include known failing boundary inputs, not 92 passing acceptance tests.
`tests/litmus/sc_reference.py` is a handwritten finite reference, honestly
separate from the production executor.

`scripts/test_litmus.sh` still hardcodes exhaustive execution and `--nolibc`.
It does not implement the agreed larger-program selected/prefix strategy or
the real library-backed fence recipe. Its 12 runner selftest plants are useful
tool checks, but the final production-classifier disconnection control is still
pending. Adapt the existing runner in the successor; no new explorer or evidence
archive is warranted by this finding.

The branch also updates the existing fork/source/generated manifests, failure
register, unit selection/freshness, upstream oracle differences and explicit
directory-coverage baseline. These are change-sensitive records, not proof of
SC correctness and not baselines to bless blindly in the new branch. The C1
pruning already removed 25 unused Lean modules, 22 redundant narratives, a
2,103-file repeated evidence tree (about 836 MiB), and 98 scratch directories.
Their old history is recoverable at `03f7c5f32`; do not restore their campaigns.

## Boundary and incomplete-behavior ledger at the frozen tip

The [boundary register](2026-09-22_sc-boundary-register.md) contains detailed
sources and examples. Its older status paragraphs are not uniformly current.
This table summarizes the implemented producers and remaining holes rather
than treating every named boundary as an implemented guard.

| Case | State at the tip and migration consequence |
|---|---|
| G01: unspecified CAS representation | Typed refusal implemented; performed reads/state retained. Representation comparison itself is settled; do not substitute value equality, false CAS or guessed padding. |
| G02: unresolved concurrent representation composition | Precise guard unfinished. Current broad subobject/value obligations also reject ordinary ordered programs; those rejections are port defects, not evidence of unresolved ISO meaning. |
| G03: missing runtime stream protection | Precise producer unfinished; broad library protection obligation exists. Do not infer stream locks or label missing implementation protection as caller UB. |
| G04: abstract unspecified atomic order | Shared typed Core producer implemented; preserves evaluated arguments and independent earlier faults. Known invalid orders and merely outside-SC orders remain distinct questions. |
| G05: generic pointer atomic fetch domain | Typed update-body guard implemented for the identified C11/reference conflict; preserves the object read. It does not ban ordinary pointer operations. |
| G06: lock-free configuration | Runtime query guard implemented. **Numeric preprocessing can still consume undefined markers as zero**, escaping the runtime guard. Feature remains incomplete and is not uniformly fail-closed. |
| G07: pinned Cmm atomic call/sequencing assumption | Whole-scalar projected guard implemented; general composition pending. Preserve independently justified UB035 instead of erasing it behind a gap. |
| G08: shared internal library protection | Precise producer unfinished; broad library obligation exists. Actual registration/call traces are available. Distinguish specified `rand`/`strtok` exceptions from missing protection. |

Other issues must retain their actual identities: existing concrete memory UB,
unsupported memory-instance observation, invariant/protocol defects, outside-SC
orders, filesystem port coverage, upstream wrapper failures, blocking and fuel
exhaustion. A refused or incomplete path is not an empty behavior set, a proof of
safety, a normal return, or automatically ISO UB.

Allocation/deallocation observations exist and actual lifetime checks execute.
General reuse composition is unfinished, but ordinary positive-size allocations
use a descending cursor and free does not replenish it. Establish which reuse
is reachable in this concrete allocator before building a generic mechanism;
zero-size and requested-address cases need separate examination. DR403 does not
authorize adding allocator choices absent from the selected object model.

The G06 GCC-observer experiment lacked the matching GCC 13.3 plugin SDK. Earlier
sandbox diagnostics also blocked package-metadata inspection. No package,
toolchain, sandbox profile or shared dependency was changed to bypass it. The
scratch experiment is `.tmp/sc-prototype/probe_sc_cpp_plugin.py`, with
`sc-cpp-plugin-1.stdout`/`.stderr`; the original preprocessing probe is
`probe_lock_free_preprocessor.py`. This blocks that chosen experiment, not the
object-composition work, and does not establish that a plugin is the only solution.

## Evidence: what has and has not been demonstrated

This handoff does not rebuild or rerun the implementation. The independent
reviewer ran three bounded probes, with matching recorded binary hashes: native
whole-aggregate copy succeeded, native ordered-byte update refused, and Lean
initialized-member access refused. All other execution evidence below is prior
implementation evidence inspected for this report, not an independent rerun.

### Current-artifact selected C observations

Raw JSON below is under `.tmp/sc-prototype/` in this worktree. It records commands,
exit status, stdout/stderr and artifact hashes. Scratch files are **not committed
by this handoff** and may be lost if the worktree is deleted; the source inputs
and the essential findings are retained in Git. These runs generally use a
15-second process bound. Native random and Lean first selection are different
policies; different permitted observations do not establish a mismatch or
exhaustive agreement.

| Evidence file | Observation and limit |
|---|---|
| `c3-whole-probes.json` | Whole aggregate copy returns 0 in both engines; enum parameter case returns 4. Actual callable fenced-SB returns native 3 / Lean 2, both in the allowed set {1,2,3}. Successful observations have empty program output/error and are unblocked. Selected executions only. |
| `c3-whole-regressions.json` | Global-init/main, varargs and distinct-array-element cases return 42 in both engines; same-element race reports UB005; signed/unsigned view returns 1. Selected executions only. |
| `c2-prefix-probes.json` | Fault-before-loop reports UB045a in both engines, exit 1, empty program stderr, location `<7:7--7:15>`. Lean race-before-loop at fuel 256 prints fuel exhaustion; the CLI does not expose its retained findings. Component controls inspect retention separately. |
| `c3-ordered-composition-probes.json` | Ordered byte update returns 1 sequentially in pristine native, fork native and Lean, but both SC paths refuse read-source/subobject composition. Initialized members return 42 sequentially in all three, but both SC paths refuse range/subobject composition. These are decisive known failures, not intentionally excluded language features. |

The two distinguishing inputs are committed as
[`ordered-byte-update.c`](../../tests/sc/representation/ordered-byte-update.c)
and [`initialized-members.c`](../../tests/sc/representation/initialized-members.c).

The last source-changing CLI implementation commit is `601b6b9df`; the following
commits add prefix controls and documentation/probes. Recorded artifact SHA256s:

```text
native:   1a8896ddd15a3646b374daa6e248f8611f2575d82ac246a3b94433f55f7e4fc4
Lean:     7dc98b1065f67f4c5464de18e2978e3cd2f2f7cc3f5067a65a8c2ef92cf6ad3f
pristine: aee776eaa5f9bf4ebd172838e613d9344195fafdf0201ef080c7e0994fd87f69
libc.core: d87f028afe120f20d8be7d3ee50b0b2c4c256ba2522828126d28e15bd86409d7
```

`c2-selected-probes.json` uses **older** native/Lean artifacts. It records SB
(3/2), publication (2/1), strong CAS equal (5/5) and unequal (0/0), weak CAS equal
(0/5) and unequal (0/0), and a mixed safe/racy example (native UB005 / Lean 1).
Those were independently allowed selected observations, not paired identical
schedules. Its fence failure used `--nolibc` and was superseded by the actual
library-backed run in `c3-whole-probes.json`.

### Component and bounded-reference evidence

- Fresh generation/builds, both Lean suites, native controls and the external
  consumer passed at the latest implementation checkpoint. Logs include
  `c3-whole-lean.log`, `c3-whole-machine.log`, `c3-whole-adapter.log`,
  `c3-whole-native-controls.log`, `c3-whole-consumer.log` and the later
  `c2-prefix-machine.log`.
- The ancestry calculation agrees with the reference on all 512 directed
  three-vertex graphs and all 64 forward four-vertex graphs, including sparse
  IDs. Focused fence controls exercise valid and malformed relations against
  unchanged reference predicates. These finite checks are not a general proof.
- A very small ordered atomic-read C probe previously enumerated 441 executions,
  all returning 2 with the same full observation. The separate handwritten
  finite Python model checks 19 reference rows; it does not establish coupling
  to the C executor. Paired generated targets also share most of their source.
- Exhaustive scalar-race/SB probes hit 30-second bounds; CAS/unsequenced-read
  probes hit 15-second bounds. Timeouts provide no complete-outcome coverage.
- `c3-whole-failure-reach.log` reports 225 registered pure failure sites, 223 in
  the execution dependency closure plus 2 unresolved-owner sites; classifications
  are 194 unreachable-by-invariant, 12 reachable and 19 unknown. This is an
  integrity census, not evidence that all executions avoid failures.
- Existing fork checks recorded 174 source pins and 39 generated-difference
  pins, with roots and generated freshness checked. Preserve their reviewed
  purpose, but recompute only for actual successor changes; never blindly bless
  a changed native oracle or expected result.

### Older broad regression evidence

The last broad full run predates production candidate integration (`8a350e2a1`).
It is **not** a current-tip release or SC acceptance result:

| Retained scratch report | Recorded result |
|---|---|
| `link-attribution-integration-full-20260923/report.json` | 39/39 lanes, source unchanged, pass. |
| `link-attribution-integration-three-way-20260923/report.json` | 864 cases. Lean: 822 agreements, 29 differences, 11 both undecodable, 2 not applicable. Native: 827 semantic agreements, 14 reviewed differences, 21 matching failures, 2 interface agreements. |

These reports support the earlier sequential/component snapshot. Later local
controls do not automatically renew that full result. A final integrated SC
release run and the production-checker disconnection control remain undone.

## Reproduction notes for a successor

These are existing commands and environment requirements, **not commands run by
this documentary handoff or a mandate to repeat all checks before planning**.
Use the project wrapper `/home/dev/projects/cerberus-lean-proj/scripts/ce`.
Keep Lean/Lake capped, use the owning package's working directory, and use one
heavy worker with `CERB_MEM_MAX=8G` and `LEAN_NUM_THREADS=1`. Running `lake -d`
from the repository root can select the wrong toolchain. Do not alter the shared
opam switch or dependency pins to make a migration build pass.

From the repository root, with that wrapper available as `ce`:

```sh
ce env CERB_MEM_MAX=8G scripts/capped make prelude-src lean-prelude-src
ce env CERB_MEM_MAX=8G scripts/capped dune build --root . backend/driver/main.exe cerberus-lib.install cerberus.install memory/concrete/sc_controls/controls.exe
ce env _build/default/memory/concrete/sc_controls/controls.exe
```

From `lean_frontend/`:

```sh
ce env CERB_MEM_MAX=8G LEAN_NUM_THREADS=1 ../scripts/capped lake build cerberus-lean sc-machine-test sc-adapter-test
```

From the repository root, the focused suite arguments used in this branch are:

```sh
ce env CERB_MEM_MAX=8G scripts/capped lean_frontend/.lake/build/bin/sc-machine-test 17 64 65536
ce env CERB_MEM_MAX=8G scripts/capped lean_frontend/.lake/build/bin/sc-adapter-test 64
```

From `lean_frontend/examples/sc_consumer/`:

```sh
ce env CERB_MEM_MAX=8G LEAN_NUM_THREADS=1 ../../../scripts/capped lake build
```

For selected C probes, the native shape is
`main.exe --runtime=_build/install/default --exec --batch --mode=random --concurrency=sc --nolibc SOURCE.c`.
Produce the corresponding Cabs JSON with the native `--cabs-json` mode and check
its exit status. The Lean shape is
`cerberus-lean --batch --first JSON --concurrency=sc`, through the capped wrapper
with `LEAN_ABORT_ON_PANIC=1`. The position of `--first` matters to this CLI.
Omit `--concurrency=sc` for the corresponding sequential comparison. Record
complete observations and whether the choice policy is selected or exhaustive.

The actual callable-fence probe needs bundled libc: omit native `--nolibc`,
prepare Lean metadata through `ce scripts/libc_prep.sh --jsons OUTPUT_DIR`, and
pass `--libc` with the absolute `tests/libc/libc.core` path plus the actual
`--libc-tu` metadata arguments. The last run used 13 translation units; its
exact command is in `c3-whole-probes.json` and metadata list in
`.tmp/sc-prototype/libc-metadata.paths`. Do not use the old no-libc fence recipe
or imply that `test_litmus.sh` already performs this integration.

## Historical commit map

This is a navigation aid, not a recommended cherry-pick sequence. Many commits
combine source, tests, documentation and changes later superseded or pruned.
Migration should select final source groups and understand their interfaces.

| Commit | Work introduced / checkpoint |
|---|---|
| `d8a1284bf` | Charter and long-cycle setup. |
| `4bba2b458` | Passive memory observations and checked ND lifting. |
| `06681abd3` | Scheduling and occurrence-preserving execution protocol. |
| `fb72dd9fb` | CAS phases and floating representations. |
| `7c2887012` | Ordinary SeqRMW phases and physical byte sources. |
| `3864dbb1f` | Resumable helpers and typed failures. |
| `8427b42e7` | Semantic boundaries and complete source-order graphs. |
| `efb39628c` | Indivisible atomic updates and C lowering. |
| `3f9705c9b` | Atomic interfaces and libc source locations. |
| `f93530586` | Lossless values and variadic metadata. |
| `3c7173732` | Atomic arguments and configuration boundaries. |
| `d0d41f4b2` | Call scopes, prefix obligations and Cmm equality repair. |
| `0215b4f74` | Explicit directory coverage-error baseline. |
| `4afc1877b` | Checked filesystem faults and failure-time state. |
| `d3d4825d9` | Spawned lexical owners and action/HB queries. |
| `074c7348a` | Actual successful global-binding observations. |
| `df6659ba8` | Atomic-source and reference-synchronization queries. |
| `b6543c6a6` | Roadmap consolidation. |
| `03f7c5f32` | Scheduling/reference/API clarification; pre-pruning recovery point. |
| `0e6947988` | Removed proof campaigns, consolidated operational tests. |
| `8a350e2a1` | Public production scalar candidate classification. |
| `86f49affa` | Small-only exhaustive C probe policy. |
| `0f437971a` | Cursor conflicts, array elements, signed views. |
| `307ac0d3e` | Ordered unspecified array-initialization handling. |
| `fad4c0428` | Initialized whole-program provider continuations. |
| `e5a6d6be9` | Occurrence ancestry algorithm improvement. |
| `601b6b9df` | Whole values, enum compatibility, private parameter reads. |
| `69dfd52ed` | Prefix finding/fault/loop controls. |
| `631382a9d` | Ordered composition failures and decision record. |

## How to use the remaining documents

- Start with the independent review and this inventory. The
  [former charter](2026-09-21_charter-sc-prototype.md) is a frozen historical
  execution record, including abandoned priorities; do not resume its C2/C3/C4
  queue or pending agent-authored permission framing.
- The [operational contract](2026-09-21_sc-operational-contract.md),
  [boundary register](2026-09-22_sc-boundary-register.md) and
  [effect inventory](2026-09-21_sc-effect-inventory.md) retain useful semantic
  sources and coverage detail. Read them against the reviewed source tip and
  this report. They are not three additional plans.
- Some status text is stale: child errno is implemented; the whole-program API
  now exists; public candidate checking is connected; 205-site failure counts
  predate the current 225-site census; the earlier fence failure recipe is
  superseded. Older “proof” wording around the consumer means the small
  definitional statements described above, not adequacy.
- Earlier concurrency research and archived evidence describe previous designs.
  Their queues, proof targets, gates and preservation requirements are not
  inherited obligations. Preserve factual evidence when it is relevant, not
  the entire historical process.

## Migration judgment and remaining gap

The review recommends keeping the operational backbone, atomic phases, lossless
observations, source ordering, reference definitions and continuation API. It
recommends replacing the universal scalar admission strategy, localizing the
effect of interpretation uncertainty, implementing precise runtime boundaries,
making selected public probes reproducible and addressing measured prefix cost.
The biggest remaining task is the object/atomic composition, not more checking
infrastructure. Full filesystem completion is a separate material scope choice.

Two early discriminators for the new design are especially valuable: the same
ordered byte/member program should work as a single-thread case through SC;
and an unrelated unsupported access followed by an independently justified race
must retain both facts, including before a loop. The first failures are executed
and recorded above. The second combined counterexample is source-inferred by
the reviewer and has **not** been executed. These examples test the architecture;
they do not constitute its full correctness argument.

The process drift was concrete: a partial scalar adapter became the universal
acceptance contract, and successful local checks encouraged extending that
contract rather than testing its fitness against ordinary C object behavior.
Earlier pruning removed much infrastructure but left that premise in place.
The successor should migrate useful code with a precise composition argument
and focused acceptance, rather than inherit the old branch's feature labels or
completion checklist. No further implementation is authorized by this report.
