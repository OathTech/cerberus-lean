# SC prefix integration: validated component, prototype incomplete

**Historical technical record.** Current work order, status and acceptance are
owned solely by the [SC execution roadmap](2026-09-21_charter-sc-prototype.md).
Old next-step, freeze, proof-count and campaign instructions below are retired.
Unique source findings are retained only until their C1 extraction.


This continues the substantial location/value/RF/HB and prefix-observation
slice after the validated atomic-interface commit `3c7173732`. The component
now passes the full integration suite and unchanged three-engine
comparison. It is not a public SC verdict implementation or a new reference
choice. Earlier pending statements below record the development history; the
completed validation is recorded at the end.
The [charter](2026-09-21_charter-sc-prototype.md) and
[boundary register](2026-09-22_sc-boundary-register.md) still govern the work.

## Actual state integration

The shared `Sc_scopes` state now lives in each `Sc_runtime.sc_state`.
`Driver.sc_service_step` observes actual consecutive call/return transitions
before installing the new thread. Each request snapshots its live call scopes;
saved helper requests retain that snapshot while resumption uses the current
branch state. Scope IDs have their own supply, independent of action IDs.
Unknown/legacy transitions retain protocol diagnostics rather than guessing.
No environment or closure equality identifies calls.

The SC wrappers around `prepare_exit` record discarded frames, separately from
normal returns. Global initializers also use this operation, so a discard is
not evidence of outer C program termination. Core faults retain live scopes.

The paired memory interfaces now expose lossless byte keys: provenance,
pointer-copy offset and optional bits. An unavailable adapter is distinct from
an unspecified byte. Other memory instances explicitly lack this adapter.
`Sc_access_group` retains chronological access occurrences, grouping only
adjacent, matching read/write observations from one atomic update/CAS request.
Unpaired reads do not imply request completion. Neither query supplies C memory
locations, logical reads-from, full happens-before, or an SC verdict.

The production Lean laws cover byte-key injectivity, lossless access grouping,
scope transitions and the actual request/restore interfaces. In particular,
passive call observation changes neither object memory nor action IDs.

## Development evidence and limits

Working evidence is retained under `.tmp/sc-prototype/sc-prefix-integration/`;
it will be archived with the completed substantial slice. All attempts retain
commands, raw channels, source identities and resource bounds. No new Tier A+B
or three-engine certification is claimed here.

- `build-1` passes generation and both production builds. `build-2` fails one
  newly added record-preservation proof; `build-3` repairs the case split and
  passes all nine build steps. `build-4` also builds the promoted scope unit
  and updated graph/varargs units. Failed elaborations are not proof evidence.
- `native-3` passes twelve actual executions: eight C inputs and four raw Core
  inputs. Removing only new diagnostic fields recovers the original complete
  observations. Scope events equal the independently instrumented transition
  observer; every request's owner scopes match replay of those transitions.
  This includes exact argument-slot reuse and effect-free calls at the same
  action frontier. It is selected-path evidence, not exhaustive C execution.
- `scope-probe-3` passes actual Lean operational controls for repeated
  effect-free calls and every returned alternative of a two-child call
  example. Each child retains its own call/effect owner. The initial name,
  record-layout and helper-qualification errors remain in attempts 1–2.
- `paired-4` is a **reporting collection with differences**, not a passing
  exact-metadata comparison. Twelve C cases preserve each engine's complete
  previous observations and agree on the full native/Lean outcome. Their
  access groups agree. Five cases agree on the full byte/scope effect prefix;
  only the atomic-pair case also has identical complete scope records.
  Program/formal symbol numbers differ between the frontends. The libc cases
  additionally retain differing function-pointer representation bytes in
  initialized `_IO_FILE` objects and the signal-function array; those bytes
  already differ in the old captures. No byte normalization is adopted, and
  raw value/byte keys are not claimed to be universal cross-engine identities.
- The thirteenth C case, parallel `ftell(stdout)`, reaches the inherited
  `CerbFS` refusal described as SC-D07. Both old and new Lean binaries abort
  at the same refusal; the native recorder completes. No final Lean journal
  is captured for this case. This is incomplete evidence, not agreement.

Earlier instrument failures are explicit: `native-1` compared first-choice
scheduling with random scheduling; `native-2` copied a draft module alias.
The corrected native run uses random seed 23 on both sides. The paired run
uses first-choice scheduling on both sides. `paired-1` used the wrong working
directory for runtime discovery; `paired-2` exposed the metadata differences;
`paired-3` stopped at the missing filesystem-refusal capture. The reporting
collection retains that refusal without inventing a journal. Lean instrument
builds 1–2 failed on a diagnostic tuple annotation and a missing diagnostic
native object; build 3 builds that object explicitly and links successfully.

- `plants-1` passes compiled disconnection controls against a copied actual
  driver: skipping call observation, dropping request scopes and reusing scope
  IDs are each detected while the original observations remain unchanged.
  The effect-free case is a negative control for dropping request scopes.
- `axioms-1` checks all 25 new laws against the compiled production definitions;
  the reported dependencies are only standard Lean axioms (the byte-bit
  projection has none). This is kernel proof evidence, not a runtime test.
- `components-2` passes eleven targeted checks, including the installed Lean
  scope/graph/varargs units, native graph/varargs controls, source manifest,
  handwritten sync and driver freshness. `components-1` failed because its
  manifest refresh retained two metadata sections. The original manifest was
  restored and the recipe fixed; repository refs never moved. Both attempts
  are retained. These targeted checks are not the full slice gate.

## Sequencing evidence and pending obligations

The shared access query now detects a sufficient class of SC-G07 witnesses using
actual request orders, distinct request identities and source `sb` closed through
all vertices. Additional synchronization edges are not substituted for `sb`.
The unchanged reference predicate has a kernel-checked witness characterization.
A second law connects access witnesses to that predicate under explicit action
identity, thread, SC-role, location-kind and source-relation preservation premises.
Those premises are not yet established for every C execution. NA accesses to
atomic locations and the complete fence domain still need the full adapter.

The real driver now retains pending prefix obligations alongside its existing
state. Each records the source graph and new witness pairs at discovery. The
channel only adds evidence and does not kill, replace faults, delete alternatives
or certify a prefix. The public entry remains checker-pending. The source-level
accumulator and actual driver field erasure/restoration laws have passed; the
new operational controls cover all returned alternatives of an unsequenced pair,
a later independent fault, and resumption after another thread adds an obligation.
Installed controls pass as described below; full substantial-slice gates remain outstanding.

Working evidence: `sc-prefix-guards-draft/components-2` passes 18 paired detector
controls; `proof-5` passes the conditional laws. `paired-2` passes 15 selected C
cases with exact old-observation erasure within each engine, matching complete
outcomes and matching witness IDs. Three independent UB035 cases remain visible.
`paired-1` mistakenly omitted libc for the fence case, reaching an unknown
procedure rather than a fence. Its raw unequal error text (symbol IDs) is retained;
no normalization is adopted. The corrected run links libc for that case.
`build-7` and `build-8` pass both production builds; attempts 5–6 fail on Lem
identifier/API spelling and are retained. The production accumulator laws are
from `obligations-4`; actual operational controls pass in `operational-3`.

### SC-D08: inherited Cmm equality target overlap

Source inspection found three overlapping target declarations introduced by
`6e151b259`: executable equality was enabled for `ocaml; lean`, while each
inlined structural fallback excluded only `ocaml`. The generated Lean reference
therefore inlined structural equality instead of the intended action-ID/set
comparisons. This affects both the live Cmm module and its derived SC carrier.

Four direct shared-Lem probes are retained in `sc-reference-equality/components-2`.
Native and Lean agree that distinct action IDs differ. Equal IDs with different
action payloads and equal witness sets with different representatives instead
produce native true / Lean false. Pre-executions with the same sets and differing
location-kind functions produce native true / a Lean comparison refusal (134).
The native definition deliberately ignores `lk`; this repair does not add an
invented comparison of those functions. The first reporting attempt omitted
`LEAN_ABORT_ON_PANIC` and printed a panic followed by a host false/exit zero; that
false is not a semantic result. The strict-policy repeat retains the refusal.

The repair excludes Lean from all three structural fallbacks and regenerates the
derived reference. Predicate bodies remain unchanged. This is a port correction,
not a new semantic boundary policy. Eight paired repair controls now pass, covering both the live Cmm module and
its derived SC carrier. Six instance-selection laws check the actual
Lean definitions. The updated conditional proof and both production builds pass.
The combined production axiom readback (`productionaxioms-1`) checks all 47
public laws: only standard Lean axioms occur. The full substantial-slice gates remain pending. Component attempt 3 finds a
missing native control import; the import is repaired and both native control
executables build. Attempt 4 correctly rejects the now-stale oracle stamp after
that source edit. Build 12 rebuilds both sides; component attempt 5 passes
all nine installed native/Lean controls, then rejects inherited trailing whitespace
on the edited Cmm selector line. That whitespace is removed and the derived
reference resynchronized before build 13, which passes all nine steps. Component attempt 6 passes all
fifteen checks, including the nine installed controls, manifest, freshness, sync
and whitespace checks. The actual production equality
laws depend on standard `propext`; the earlier axiom-free claim from isolated
probe definitions does not apply to the imported production environment.

### Producer validation and closure sharing

`sc-prefix-obligations/paired-2` passes fifteen actual C comparisons: complete
prior observations remain identical within each engine, native/Lean outcomes
agree, and the retained source graphs and witness IDs agree at discovery.
The three independent UB035 cases remain observable. The first collection fails
the libc fence case's unchanged twenty-second limit; it is not agreement.

The isolated actual-driver profile (`profile-1`) attributes about 8.4 of 11.7
native seconds to computing source closures twice at each relevant prefix.
The production query now reuses the graph's existing closure when `asw` is empty;
otherwise it computes `sb` alone. Two kernel laws prove this equals the original
query on every constructed graph, without requiring valid graph annotations.
Attempts 1–2 of the proof probe fail on a setup path and API spelling; attempt 3
passes. Both production builds pass in `build-11`. No bounds were increased.
The repaired Lean fence collection completes at 19.6 seconds, which remains close
to its limit. The final diagnostic query now uses that same proven reuse function;
`paired-3` repeats all fifteen comparisons with identical complete observations
and finishes the fence case in 16.8 seconds. Attempts 3–4 of the instrument build
respectively fail for omitted Lake environment paths and succeed after restoring
the documented `lake env` invocation; attempt 5 builds the shared diagnostic.
This fixes the observed timeout without claiming large-prefix scalability.

`sc-prefix-obligations/plants-1` passes compiled mutations of isolated copies of
the actual driver. Skipping the producer and resetting its history lose evidence
while preserving prior behavior. An immediate kill after discovering an obligation
hides the independently reached UB035; that mutation is detected. The ordered
case remains an unchanged negative control. Positive-control observations equal
the actual production recorder's complete retained JSON.

## Integration plan and resource bounds

[AGENT] The whole shared-source prefix/equality slice requires the current full
Tier A+B suite and mandatory three-engine report before a local checkpoint.
Run one worker with an 8 GiB outer cap and the standard 4 GiB per-case cap.
The finite suite may exceed one hour in aggregate: it is a collection of separately
bounded regression/plant processes, not an unbounded build or kernel proof pass.
This is the advance justification for that aggregate measurement duration.
Any individual build/proof approaching one hour still triggers the stop rule.
Retain failed runs, exact observations and source/artifact identities. Compare
all 864 three-engine records with the committed atomic-interface checkpoint;
no baseline or projection change is authorized by this validation plan.

## Next work

Continue the actual location/value/RF/HB composition and
separate prefix-obligation interface. Bind library roles to the loaded libc
artifact before linking, then use real call scopes and parameter reads for
stream/internal-object guards. Do not install an immediate G07 kill that hides
a subsequent independent Core fault. G02/G03/G07/G08 and G06 preprocessing
remain outstanding; the public checker remains pending.

## Completed component validation

[AGENT, September 23] All 39 full Tier A+B commands pass on the frozen source.
The mandatory 864-case three-engine collection preserves every prior decoded
observation and classification, with zero deltas from the atomic-interface
checkpoint. Pristine/fork: 827 semantic agreements, 14 reviewed differences, 21
matching failures, 2 interface agreements. Lean: 822 agreements, 28 differences,
12 both-undecodable cases, 2 not applicable; the same 40 difference/undecodable
IDs remain. Those unresolved cases are not semantic agreements.

[Retained evidence](2026-09-21_sc-prototype-evidence/prefix-integration/README.md)
includes the source identities, artifact checks, exact channels, component
controls, failed attempts, producer plants, 47 production laws, and comparison
with the previous checkpoint. Successful reconstructed Cabs input files alone
may be omitted from the integration archives, with their hashes retained. An
independent reader verifies every archive member and index, all 39 passing gates,
all 864 observations/classifications and the implementation hashes. No baseline,
comparison or resource bound was weakened.

The source freeze also allowed isolated leaf investigations without production
or artifact changes. They remain **unadopted**:

- The [filesystem review](2026-09-23_sc-filesystem-boundary-review.md) records 32
  paired cases, including eleven wrong answers/fail-open cases, and 30 native
  reference observations. A descriptor-only repair matches 24 cases and has 12
  draft laws. Open/path/permission repairs remain required.
- [Definition-source evidence](2026-09-21_sc-prototype-evidence/prefix-integration/followup/definition-sources.md)
  covers twelve paired controls, four actual native C executions and eleven
  draft laws, including actual linker field equations. Complete ownership
  correspondence still needs the map invariants or matching metadata propagation.
- [Parameter-read evidence](2026-09-21_sc-prototype-evidence/prefix-integration/followup/parameter-reads.md)
  covers twelve paired controls, five actual native C executions and seven
  draft laws. A callee can overwrite its FILE parameter before the first read;
  a matching completed read is evidence of its value there, not at call entry.

The 47 production laws exclude these draft laws. There is no full C
location/RF/HB interpretation or G02/G03/G07/G08 verdict producer yet. Public
`Driver.drive true` still refuses immediately as checker-pending; internal
recorded execution remains explicitly unchecked. Continue the charter through filesystem
repair, library/resource attribution, remaining boundary producers and full
operational/C integration; this component checkpoint does not finish the work.
