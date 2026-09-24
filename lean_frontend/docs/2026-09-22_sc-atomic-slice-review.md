# SC fences, compare-exchange and representation review

**Historical technical record.** Current work order, status and acceptance are
owned solely by the [SC execution roadmap](2026-09-21_charter-sc-prototype.md).
Old next-step, freeze, proof-count and campaign instructions below are retired.
Unique source findings are retained only until their C1 extraction.


[AGENT, 2026-09-22], parent `06681abd3`, under the
[SC charter](2026-09-21_charter-sc-prototype.md). This is an implementation
checkpoint in progress. The public SC entry still reports pending checker
integration; completed recorder results are not defined-program verdicts.

## Semantic changes

`step_action_with` preserves the sequential wrapper and adds owned SC requests
for fences and compare-exchange. Completed fences have source ordering and
occurrence identities without fabricated memory accesses. The named SC request
filter admits NA/SC accesses and SC fences; it explicitly refuses weaker
requested orders before memory effects. These are model-domain refusals, not C UB.

Compare-exchange has separately scheduled expected-read, object operation and
failure write-back phases. Only the object's read/conditional store is
indivisible. All phases use the real typed memory model; receipts retain their
completed footprints and predecessors. Weak equality keeps both success and
spurious failure, in the exhaustive runner's actual occurrence order. Ordering
follows the expected-read/object/write-back edges in upstream BMC's
`intermediate_to_bmc_actions` and `do_po_e`, together with C11/C17 CAS behavior.
The pending-request list belongs to the scheduler, and the exported membership
law now describes pending requests as well as ordinary Core reductions.

`sc_compare_representation` compares the actual completed loads' byte bits.
The projection inspects the existing representation byte without changing its
provenance or copy metadata. The other memory adapters return unavailable.
Unspecified bytes on either side produce an explicit unsupported result even
if another pair of bytes differs; length mismatch is also explicit. Both reads
and their failure-time state remain recorded. This implements the user's
[upstream-gap policy](2026-09-22_sc-boundary-register.md#fail-closed-policy), not undefined behavior,
CAS false, or silent removal of an alternative. Five kernel laws characterize
the shared comparison's specified/unspecified cases.

A separate inherited Lean defect would have destroyed NaN payloads on typed
write-back. The [floating-point repair record](2026-09-22_sc-float-representation-repair.md)
contains the pristine/fork/Lean counterexamples and source rationale. Both
Lem float values and concrete floating values now carry their bits explicitly;
parsing, formatting and memory reconstruction use that carrier consistently.
Two kernel laws establish representation round-trips. Concrete arithmetic
preserves the pinned OCaml target's NaN behavior; finite arithmetic retains the
existing primitives and the separately authorized literal-rounding correction.

## Oracle-surface and failure-register review

The fork manifest adds `frontend/model/sc_representation.lem`, updates eleven
existing source pins, updates the generated `core_reduction.ml`, `driver.ml`
and `mem.ml` semantic diffs, and pins the new representation module plus the
updated `sc_runtime.ml`. The shared memory interface adds a pure byte-bit
projection, implemented for concrete memory and explicitly unavailable for the
three other adapters. Makefile changes include the shared module. The
`float.lem` edit changes only its Lean target representation. No new floating
arithmetic semantics are introduced into the OCaml oracle by this repair.
Historical review comments, `renumber=arc13`, upstream merge-base and Lem pin
are preserved. Refreshing hashes is not itself a semantic validation claim.

The fresh failure census has 240 sites: 173 invariant-unreachable, 48 reachable,
19 unknown; 238 have execution-closure owners and two have unresolved owners.
All ten original `step_action` failures retain their reviewed positions and
reach classes under `step_action_with`. CAS/fence refusal remains reachable in
the sequential wrapper where it was previously unimplemented.

Two new pure failures reject an internal object/write-back phase returned from
a Core action. Constructor/dispatch inspection establishes the intended
invariant: `step_action_with` creates only the initial CAS request. The driver
places the internal phases directly in its pending-request list, and services
them through `sc_service_step`, outside the Core action-to-context mapping.
These two sites are reviewed as unreachable on the public drive path. This is
a source-invariant review, not a universal theorem about arbitrary constructed
states. No unknown site is reclassified; there are zero discardable failures.

## Evidence and remaining work

Both production targets regenerate with shared source identity
`13779c42350bedae8a5485b5ad7ce2aad31b42992fbb8ec01b73f8091a48aaeb`.
All 55 handwritten copies match. Both production builds pass; Lean builds all
415 jobs, including every library root. The seven native component executables
pass: 18 protocol groups, seven fence/order groups, 11 representation controls,
12 CAS groups, the 784-row native-OCaml float table, 42 literal pins, and the
pretty-printer/batch-escaping tests. CAS interleaving witnesses retain 175 and
210 alternatives. These counts describe their test domains, not completeness.

A fresh isolated native frontend matches pristine and fork on five complete C
regressions, including all NaN kind/sign/payload combinations in the copy test,
NaN arithmetic and negative-NaN output. Those inputs are now ordinary float-lane
fixtures 106–110, with five new MATCH baseline entries; existing entries are
unchanged. The previous PP unit assumption that invalid arithmetic printed an
unsigned NaN is corrected using the actual native arithmetic matrix and the
three-engine formatting reproduction, with explicit tests for both signs.

The production native CAS run includes the repaired unequal-NaN write-back.
At that stage, full C-to-CAS recording controls, integration and the mandatory
three-engine report were still pending. Their completed results appear below.
Current journals retain complete CAS memory effects.
The SC race/consistency checker, remaining atomic forms and shipped C entry
remain unfinished. No complete SC implementation or ISO correspondence theorem
is claimed by this slice.

The first fast-run launch omitted `scripts/ce`; all 16 lanes refused immediately
with the environment guard, and that failed report is retained. The correctly
launched run then found an F5 fuel-notation false positive in
`CerbFloatValue.binary`: the anonymous record constructor containing a numeric
NaN bit pattern also matches the repository's fuel-literal ban. The wrapper now
uses its existing named `ofBits` constructor, a definitionally identical value.
The guard itself is unchanged and passes directly after this repair. The run
was stopped through the runner's normal SIGTERM cleanup before editing sources;
its failed/incomplete lanes and unchanged-source result remain retained.
A fresh production build and new integration run are required.


Fresh native C-to-Core recording instruments now agree on seven exhaustive
controls: integer strong success/failure, weak equal/different, an SC fence,
and double strong success/failure. Full token sequences, including duplicate
records and their order, are compared; expected result sets are checked in
addition. Three representation-sensitive C programs also agree in separate
single-trace diagnostics (OCaml random mode, Lean first trace): equal/different
NaN payloads and signed-zero failure. These establish selected traces only,
not exhaustive coverage. All use unchecked recording, not SC verdicts.

The original larger integer result expression timed out in both exhaustive
engines at the unchanged 12-second limit. One selected Lean trace returned the
expected 197 immediately. Smaller control programs reduce the experiment's
exploration cost; no executor choice is removed. Original captures remain under
`cas-c-pipeline/controls-1`; the passing exhaustive captures are `controls-4`,
and selected representation traces are `representation-single-trace-2`.

These experiments also expose an upstream frontend gap: `_Atomic double`
loses its atomic property and CAS typechecking rejects its address. Pristine
upstream, fork and Lean all reject that fixture. Using the accepted
`_Atomic(double)` type-specifier form reaches the operation. The original
rejection and pristine reproduction are retained; changing the test spelling
does not repair or conceal that separate upstream limitation.

The F5 notation repair rebuild passes all 415 jobs and produces the exact same
native driver hash as before (`c42d49b21aedca34b79e2d122967a9a651615ac3189a04387d4b1a5f3bc68157`).
Fresh integration gates are next; the prior failed/interrupted reports remain.

Tier A subsequently passes all 16 lanes. The first full run passes 28 lanes
before exposing a GCC disagreement in the new NaN arithmetic fixture. The
[float repair record](2026-09-22_sc-float-representation-repair.md) documents its
native `-O0`/`-O2` operand-selection diagnosis and non-vacuous fixture refinement.
The interrupted full report remains incomplete and unchanged-source. The
implementation and expected result are unchanged; fresh validation follows.

## Validated local checkpoint

Fresh Tier A+B passes all 39 commands, unchanged-source with no artifact issues.
The GCC lane passes 2,006 cases with no baseline regression and the observation
mutation battery passes 93/93. The mandatory three-engine report covers 864
cases and retains exactly the same 40 Lean discrepancy IDs as the protocol
checkpoint. Seven native component executables and six fresh production
controls/mutations pass. Complete counts, original failed attempts and raw
captures are retained in the [atomic evidence index](2026-09-21_sc-prototype-evidence/atomic/README.md).

Two additional selected C traces pass pointer CAS success and failure; failure
writes back a pointer which is subsequently dereferenced successfully. The
original exhaustive attempt timed out and remains incomplete. The separate
legacy trace review establishes that `Driver.trace` was already a lossy
OCaml-only diagnostic summary; it omits helpers/startup and has a documented
pointer-prefix port limitation. The SC occurrence journal, including fences,
is the complete source for the checker and reasoning API. Additional legacy
CAS display entries would be a diagnostic enhancement.

The shared atomic-recording and float representation slice is validated. The
ordinary RMW, byte-source and helper drafts remain separate work in progress;
the race/consistency checker and public SC entry are still unfinished. No SC
whole-program definedness or complete ISO correspondence claim follows from
this checkpoint.
