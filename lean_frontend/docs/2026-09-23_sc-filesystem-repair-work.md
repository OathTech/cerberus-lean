# Filesystem repair for the SC stream adapter: validated component

**Current status:** this component passes all 39 full integration commands and
the mandatory 864-case three-engine report with its one reviewed directory delta. See the final sections for
the thirteen production laws, retained evidence and SC-D13 instrument correction.
The development entries below retain their historical status and failed attempts.
This is not completion of the whole SC prototype.

[AGENT, September 23] Continue from validated prefix commit `d0d41f4b2`.
The [confirmed SC-D07 defects](2026-09-23_sc-filesystem-boundary-review.md)
remain required port work. The goal of this slice is to repair descriptor state,
access rights and the witnessed open/path/permission behavior using the pinned
SibylFS semantics, then validate actual C stream executions. It does not supply
missing stream locks or a completed SC checker.

Reuse the retained descriptor draft and twelve laws, with new evidence under
`.tmp/sc-prototype/sc-filesystem-repair/`. Before changing production open
behavior, derive its combined-error selection through the actual monadic and
OS wrappers. Path resolution must precede lexical simplification, preserve
trailing-slash conditions, and use the actual selected architecture. No blanket
refusal for double slashes, invalid flags before path checks, or arbitrary host
integer limits is authorized. Unimplemented port work stays explicit.

After component controls and actual C checks, run the full 39-suite integration
and mandatory 864-case three-engine report. One heavy worker, 8 GiB outer cap,
standard 4 GiB per-case cap; leaf probes use 512 MiB and twenty-second limits.
The finite corpus may exceed an hour in aggregate because it comprises
separately bounded tests. This is advance justification for that aggregate
measurement duration, not permission for an hour-long individual build/proof.
Keep all failed attempts and observations. Customer sources remain read-only.

## First query evidence

`selection-native-2` compares the full ordered `fsop_open_checks` results with
the actual SibylFS wrapper on thirty cases. The selected last check result
matches every wrapper result; successful checks are distinguished from the
actual returned descriptor. Attempt1 fails to qualify the finset wrapper's
conversion function, and is retained as a compilation failure.

`OpenChecks.lean.txt` is an unadopted query for root cwd, direct-root regular
files and the selected initial root user. It mirrors path traversal and all
ordered parallel checks, including inactive architecture checks that affect
list composition. Existing-file execute permission is an explicit input. It
does not claim a complete filesystem state transition or a universal map from
arbitrary manually constructed filesystem states.

`open-validation-2` exactly matches all thirty resolution/check lists; attempt1
fails to elaborate unavailable Int bitwise-and instances. The corrected query
uses Euclidean bit tests, including negative words, without artificial host
integer bounds. `selection-grid-native-1` and `open-validation-grid-1` match
1,608 further finite combinations of six paths, access/creation flags and mode
arguments, including negative flag words and simultaneous errors. All probes
finish below one second within the unchanged 512 MiB/twenty-second bounds.
Production CerbFS remains unchanged; state mutation and actual C integration
are still outstanding.

## Typed specials and operation draft

The query now preserves the native special kind (Undefined, Unspecified,
Implementation_defined, Impossible or FIXME) separately from errno. Native
selection3/grid2 and Lean validation3/grid2 repeat the30/1,608 comparisons with
those kinds included; all query results match. A POSIX-model special is not
reclassified as an ISO C concurrency UB.

`operations-native-1` records fourteen further actual wrapper executions: root
reads return EISDIR even for zero count; negative directory pread chooses EINVAL;
new root descriptions have offsets independent of the initial dummy; append
uses the current end; truncation through a second descriptor preserves the first
offset; relative/absolute aliases agree across open/truncate/unlink/rename.
These are native reference observations, not paired coverage by themselves.

The combined, unadopted `proposal-1` has41 exact completed comparisons out of46
cases. It includes modes, canonical root file names, independent root directory
descriptions, append behavior, and EOF beyond a shortened file. The other five
cases reach the same named upstream specials (native exit2, Lean abort134);
they are not successful completions. Case20 loses the prior diagnostic line
`create value 3` on the Lean side. `specials-1` repeats the five cases with
explicit diagnostic stdout flushes; the same case still loses its prefix, so
this is a failed full-prefix comparison. Do not normalize it away or claim that
flushing fixed it. This finding motivates explicit fault data and transport
before adopting the draft; the precise compiler scheduling cause is not yet
established. The current opaque failure also lacks a returned filesystem state.

Generator setup1 has a Python quoting error; proposal-check1 has a Lean record
indentation error; proposal-check2 elaborates. All failures are retained. The
transitional canonical-key shim for rename/unlink/truncate is not their complete
path/error port; root/error combinations still require review. Historical source
coverage comments in the copied module are not current coverage claims.

Leaf descriptor1/2 writes must also remain distinct from actual C execution:
the shared Driver routes numeric descriptors1/2 to its output records. Direct
SibylFS leaf controls do not prove that whole-C path. Preserve upstream Driver
behavior and validate the actual C interface separately.

## Checked open result, still unadopted

`checked-laws-1` proves three general laws of the single draft transition:
stopped opens preserve the input state; ordinary-error opens preserve it; and
every returned checked result projects exactly to the temporary compatibility
leaf. The kernel reports only the standard axioms (`propext`, `Classical.choice`,
`Quot.sound`). These are port-side laws, not an external simulation theorem.

`checked-open-2` compares thirty actual wrapper cases with the draft. Values,
errno, special phase/kind/message and preceding diagnostic lines match exactly.
The native observer uses the actual CALL, TAU and RETURN transitions, with the
same first-element selection as `Sibylfs.run`; normal returns and serialized
states also match a separate call to the original wrapper. It inspects
`OS_special` directly, without treating arbitrary host exceptions as model
faults. All observed open specials occur at TAU. Separate runs retain both
engines' state dumps. No whole-state cross-engine equivalence or C/ND failure
transport is claimed yet.

Attempt1 completes both engines but fails exact transcript comparison because
Lean's `#eval` captures the explicitly requested stderr state dumps in stdout.
Attempt2 switches those additional dumps off for the exact transcript run and
collects them separately. Both raw attempts remain retained; no semantic output
is normalized or discarded to obtain agreement.

The state convention matters: upstream `OS_special` supplies **no successor
state**. The native observer preserves the last defined OS state and its phase,
including the pending call. It does not fabricate an intermediate post-failure
heap or claim rollback. For the open validation cases, removing only that call's
run-status change reproduces the serialized input state. The Lean open checks
precede every mutation. Generic filesystem transport must keep this distinction
explicit if other operations fail after internal work.

Next, replace the driver-facing tuple-only seam with a checked result carrying
ordinary errno or a typed model/port/protocol fault. Preserve the exact native
first/last selection (reads use `run_last`), existing numeric stdout/stderr
routing, and the original state before updating the ND failure branch. All
reachable opaque filesystem refusals need the checked path; converting just
open is insufficient. Correct the remaining draft path/error combinations
before promoting its state changes. Existing unported directory/link/stat
operations stay documented implementation obligations, with precise retained
faults. This does not resolve SC-G03's missing stream synchronization.

## Path operations and the umask wrapper boundary

`path-selection-native-1` records 384 combinations of unlink/truncate/rename
arguments, with empty root or two closed files. Native rename selects the first
ordered check, while truncate selects the last; unlink has a single outcome in
this domain. The extra state bind in `fsop_rename` accounts for the difference
from truncate. Do not generalize one operation's selection to every operation.

`path-validation-1` fails on three rename cases: the reduced resolver had lost
`RN_error.re_rn`. Upstream retains a file there when only trailing slashes caused
ENOTDIR; `file/..` does not retain it. The single draft resolver now returns that
extra field as well as its old resolution projection. Attempt2 matches all384
ordered lists, in14.39seconds. Attempt3's more compact fixture fails Bool/Prop
inference. Attempt4 fixes the annotation and matches all384 in1.12seconds under
the same512MiB/twenty-second limits; it iterates one data table instead of
duplicating the query body for each case.

`path-operations-1` then matches all384 returned results and the contents/modes
of all three canonical file names reachable in that fixture. The checked draft
preserves root rename-to-itself, selected path errors, and zero-extension on
truncate without changing existing descriptor offsets. Unlink/rename that need
unported inode retention still stop explicitly after the source checks. Native
observations use actual stat/read operations; Lean observations project draft
state. This is not a port of stat or a full filesystem simulation. The earlier
canonical-key shim is superseded in the draft, not in production. Checked-laws2
fails on the reserved identifier `from`; checked-laws3 elaborates the repair.

`umask-boundary-1/2` confirm a separate upstream wrapper defect, now SC-D09.
Both relevant SibylFS source files are byte-identical to the pinned pristine
reference. All six calls reach `Failure("return_nat")`: `os_umask` has already
updated the mask, and the wrapper has completed OS_RETURN, but the numeric
decoder does not accept `RV_file_perm`. Captures retain the preceding file
creation, exact raw return and complete serialized native state. The second
attempt additionally prints the raw return constructor/payload.

`umask-checked-1` matches all six diagnostic fault/prefix/state projections.
The new draft `fs_umask_checked` preserves the completed mask update and returns
an upstream decoder fault. It does not invent the successful old-mask result
that production Lean currently returns. The unsupported outcome ends that
execution; inspecting the native transition state is diagnostic, not continuation
of C after the failure. Resolution requires the pinned upstream wrapper contract
to be repaired/reviewed. No ISO UB or ordinary errno is inferred.

Open flags, permission arguments and new masks now pass through LemLib's actual
modular Int32 conversion. `num.lem`'s logical word conversion and the existing
LemLib D4 ruling distinguish it from Zarith's out-of-range exception in the
native executable. This fixes a draft omission for wide integer inputs without
adding a host-range guard. Wide-input controls and the driver connection remain
to be completed; existing finite open matrices used in-range words.

## Complete checked leaf surface; integration next

`checked-interface-1` exercises all25 native checked entries across58 controls.
Every normal return and serialized state equals a separate call to the original
wrapper. Named specials, unexpected return constructors and the exact
`List_array.list_array_write` failure have distinct typed diagnostics. The last
is now SC-D10. Other host exceptions are not caught. `run_rewinddir` deliberately
keeps the original wrapper's discarded ordinary errno and void completion;
model/wrapper faults are retained. The new adapter remains unadopted.

All25 Lean draft entries now have checked definitions. The legacy functions are
projections for comparison only. Known directory/link/stat omissions stop with
state-bearing coverage faults. Reads and writes now follow the original
wrapper's selected full available transfer, with mid-file offsets, extension,
append, zero counts, and negative-offset/error priority. This does not replace
the wrapper with a scheduler over all underlying filesystem choices.

`io-matrix-1` exactly matches528 value/errno/fault observations plus contents and
descriptor offsets. `proposal-3` retains41 exact completing legacy controls and
the five known opaque-failure cases; case20 still loses its preceding diagnostic
on that legacy path. It is not an overall46-case agreement claim. Checked-open3
continues to match all30 complete typed diagnostic transcripts. The updated
1608-case open query (`open-validation-grid-3`),384-case path-operation
projection (`path-operations-2`) and six umask diagnostics (`umask-checked-2`)
all pass. `checked-laws-8` checks seven kernel laws, including exact inverse
representations for the structured result and the shared tuple/sum interface;
the two representation laws have no axioms, the others only standard axioms.

Failed work is retained: checked-laws5 has a generator error that incorporates
the next private declaration into a refusal; proposal2 ran that same invalid
source and is a failed reporting collection. The generator is repaired, and
subsequent collections require successful elaboration before runtime cases.
Checked-laws6 elaborates but fails source identity because another concurrent
probe changes the temporary `.lean_probe.*.json` name; attempt7 passes with
serial probes. Do not label attempt6 a clean source-frozen run. Checked-laws8
adds the interface representation laws and passes serially.

`word-conversion-3` matches twelve logical-word controls, including their created
permission modes. The native comparison invokes actual SibylFS transitions
after the logical modular conversion. Eleven original wrapper calls separately
fail with `Failure("int32_of_big_int")`; these host-range failures remain raw
captures and are not native-wrapper/Lean agreement. Attempt1 stops because the
instrument expected `Z.Overflow` instead of the installed compatibility layer's
precise exception; attempt2 has a Lean fixture parse error; attempt3 passes.
No host range limit is added to the Lean semantics.

### Driver state ordering to preserve

The current `drive_fs_step_with` commits its returned filesystem state in
`update`, after any buffer/errno/stat memory work. Connecting the checked seam
must preserve that normal execution order; moving the filesystem update earlier
would change the pinned Driver's memory-fault state. On an explicit filesystem
boundary, retain **both** the ordinary driver state and a separate receipt of the
last defined filesystem state/fault. For umask the receipt is after OS_RETURN;
for OS_special it is before the failing transition. Keep the normal `fs_state`
field's meaning and use an ND failure with the typed diagnostic. This supplies
inspection evidence without inventing a new C continuation or silently moving
the existing commit point. The ordinary output routing on numeric fd1/2 remains
the upstream Driver's. Actual C/ND controls and integration gates are next.

## Production connection in progress

[AGENT] The checked surface is now adopted in `CerbFS`, `Fs_checked`, the shared
`Fs` interface and all25 Driver filesystem entries (plus vprintf's file-write
path). Build1 passes generation, native build/install, Lean build and freshness.
Ordinary callbacks and their commit points are unchanged. Boundary failures
retain a separate `fs_boundary_failure` receipt and use `DErr_filesystem`; every
existing exhaustive renderer is extended. Actual C and ND checks remain pending.

The first connection uses update/bind/kill. Review identifies an unnecessary
Lean bind-fuel dependency on this new terminal leaf; the revised definition
constructs the same killed ND node and receipt directly, at every fuel. This
mirrors the existing driver state-bearing fault nodes and changes no success
callback. The two builds are retained separately.

SC-D11 is an inherited API defect found during adoption: `Ord FsState` returned
`.eq` for every pair, including states with different masks or file contents.
No shared execution definition orders filesystem states. Remove that fabricated
ordering rather than export a new order without a correspondence argument.
Structural equality of the Lean representation and field inspection remain
available; this is not a claim of full-state native comparison equivalence.
Compilation and a negative instance-resolution control must check the removal.
The existing `<fs_state>` pretty-printer remains only an incomplete display;
receipt inspections use the actual fields, never that placeholder as identity.

Build2 passes the native target but fails Lean: the generated Driver record
comparison requires `Ord FsState`, despite no identified execution call ordering
whole filesystem states. Retain this failed removal. The corrected instance
uses the named opaque `failwithI` boundary, instead of `.eq` or an invented
structural order on the reduced state. Its runtime failure and exact opaque
body are the revised controls; full comparison coverage remains a port task.

## Production controls and C observations

Build3 passes after the explicit comparison boundary replaces the erroneous
`.eq` instance. The direct terminal ND definition has no bind-fuel parameter.
Seven leaf laws and five Driver laws pass over imported production definitions;
`returned_exact` preserves arbitrary callbacks, `stopped_exact` preserves the
whole driver state except the receipt, and the umask law covers the actual
filesystem entry with an arbitrary Core completion callback. Only standard
axioms occur; fault injection/disjointness and the two result inverses are
axiom-free. DriverLaws1 is a record-layout parse failure (Lean reports its
error-recovery placeholder); corrected attempt2 passes. No admitted proof is
adopted. These twelve laws are promoted with the runtime controls.

Production leaf controls repeat528 I/O,30 open,384 path,6 umask and12 logical
word cases successfully. They import `CerbFS`; applicable native adapters are
copied from the adopted source. The prior wide-word host failures remain
separate. Some retained recipe docstrings still say unadopted; their command
captures and source artifacts identify these new production runs explicitly.

DriverControls6 passes16 Lean controls: state receipts, prior actual memory
store/effects/output, no Core completion on faults, successful completion,
partial buffer store before failure, errno-store failure, unchanged successful
FS commit order, numeric stdout routing, exhaustive success/fault alternatives
(including duplicate faults and native ordering), and explicit exhaustion.
Attempts1/2 fail do-block syntax;3 fails names/types;4/5 expose incorrect test
expectations. The actual memory failures are `Undef0`, not `DErr_memory`, and
Dlist output chunks are prefix then new output. Preserve those attempts; the
production semantics was not changed to fit the tests. Native driver-controls3
passes14 corresponding controls through actual Driver and Smt2 exhaustive
execution. Native-driver1 compiled but lacked the required Tags initialization;
corrected driver-controls2 passed12 before the success/alternatives additions.

C-pipeline1 is a failed collection: all14 Lean executions were OOM-killed under
an incorrectly selected512MiB outer leaf-probe cap (positive cgroup witness).
No agreement claim is made. Attempt2 uses the normative4GiB per-C-test cap and
8GiB outer cap. Three original fixtures lacked declarations because the pinned
unistd header comments out pread/truncate declarations; explicit declarations
from that same header are supplied. An invalid-open control must first create
the file: otherwise ENOENT masks the invalid flag special, faithfully.

C-pipeline2 obtains13 exact paired observations among14 controls. The remaining
mkdir case is explicitly unported in Lean (typed coverage fault), while both
native engines complete. One of the13 is an erroneous format-argument fixture
that reports UB153b on all engines; it is not normal truncation coverage. The
corrected C-pipeline3 truncate-only control completes identically on all three
engines with return2 and stdout `2 0\n`. Together there are nine completing
normal controls, two typed open specials, the existing partial-buffer store
fault, the newly documented SC-D12 proxy fault, and one missing-port control.
The two specials are preserved typed fork failures versus pristine host
exceptions, not three-engine semantic completion. Batch error text alone does
not serialize the retained output prefix; Driver controls inspect its state.
Full integration, boundary plants and evidence retention remain pending.

Build4 fails on native warning23-as-error: the control's core-state record
listed all fields while retaining a redundant `with`. Remove that clause; do
not relax dune's warnings. The semantics and control expectations are unchanged.

Build5 and the installed16/14 controls pass. Three separately compiled copies
of the actual generated native Driver are rejected by those same controls:
omitting the receipt, committing filesystem state before buffer memory work,
and bypassing checked open through the old aborting leaf. Every planted copy
compiles; expected runtime failures identify the lost property. The positive
copy exactly reproduces the installed native controls. Production sources remain
unchanged through this plant collection (`driver-plants-1`).

The first fresh failure census correctly rejects the stale CerbFS opaque-failure
rows: Driver now calls checked definitions, so the legacy projections leave its
execution closure. It also finds an anonymous theorem's `failwithI` mention with
unresolved owner. Name that already-proved comparison-body law so the census can
resolve its non-executable proof owner; do not allowlist an unresolved owner.
The errno reach justification must be updated from its obsolete EINVAL-only
claim to the actual finite emitted set, all present in `translate_errno`.

Build6 passes, but components2 confirms that naming the theorem alone does not
resolve the census: FailureReach intentionally emits definition/opaque ranges,
not theorem ranges. The production comparison body now has its own named
`CerbFS.compareState` definition; the instance and its selection law refer to
that one body. The opaque failure remains at the actual executable definition,
not copied literally into a proposition that the census cannot own. No census
rule or allowlist is weakened.

The first SC-service C replay is incomplete at its unchanged20-second bound.
`parallel-stream-position` completes natively (1300 driver steps,239 recorded
effects, return1), while the Lean recording times out without a final journal.
The next replay's larger invalid-open-prefix C program times out natively before
a paired run. These do not establish either agreement or semantic mismatch;
retain both and make no claim that the earlier SC ftell refusal is now fully
validated end to end. Smaller C programs without C-libc startup will separately
check the transport. This is a fixture domain, not an executor restriction or a
resolution of the larger prefix's resource limit.

Build7 passes with the named comparison function. Components3 has no new or
unreviewed pure sites; exactly36 legacy CerbFS opaque sites leave the execution
closure, taking the register from241 to205. The comparison function itself is
outside that closure. Register review retains existing non-FS classifications
and corrects their obsolete filesystem justifications.

The smaller SC-service C replay (`recorded-c-4`) passes four exact
fault/output-prefix/counter comparisons; both targets record38,52,60 and24
effects. Parallel descriptor-position returns1; open-special retains stdout
`prefix\n` and the precise typed receipt; the partial-buffer and umask-proxy
faults retain their independent UB constructors and no filesystem receipt.
They use actual C/Core and the existing SC service machinery without C-libc
startup; the public checker remains bypassed for instrumentation. Attempt3
fails because the fixture omitted stdio's SEEK_CUR declaration;4 includes it.

Whole journals do NOT agree. The three sequential controls differ only in4,7
and3 deallocation storage/range entries; the parallel control differs in
detailed schedule/effect fields. SC-D13 tracks the observation and the required
Core-environment/retirement-order investigation. Do not infer a trace quotient
or SC correctness from equal counts. The two larger timed-out recordings remain
open; the smaller fixture does not resolve their resource limit.

## Final component review before integration

The fresh205-row failure register passes its census gate; exactly36 legacy
CerbFS projection sites leave the execution closure. All other reach classes
are unchanged. Four justifications now reflect the checked-error domain and
existing structure/can-advance invariants. The fork manifest is refreshed and
reviewed; neither behavioral baselines nor observation projections change.

`final-proofs-1` checks all13 imported production laws and prints only standard
axioms (several have none). The named comparison-selection law also passes.
The actual `compare FsState` runtime control exits134 at the exact SC-D11
unsupported message; positive field and structural-equality controls complete.
This establishes refusal, not a filesystem ordering implementation.

The next full39 and mandatory864 runs freeze this source state. Their results
will distinguish unchanged corpus behavior from newly typed boundary output.
Any changed behavioral baseline needs explicit evidence and a separate
instrument commit; it will not be silently regenerated.

## First full run: failed baseline, retained evidence

`fs-integration-full-20260923` completed all39 lanes on unchanged source:
37passed, B5 and B9failed, no artifact issues. The mandatory864 runner did not
start because full validation was red. B5 rejects the changed
`zd-z2f04-closedir` observation; B9 correctly rejects three positive-control
variants on that same stale pin, with90of93plants passing. No plant bug or
second execution discrepancy has been established. Earlier commentary confused
completed and passed counts; it was explicitly corrected before any checkpoint.

The [one-row review](2026-09-23_sc-filesystem-baseline-review.md) documents the
change from a Lean host abort to a precise missing-port error, alongside the
unchanged native Core proxy failure. SC-D14 records that distinct native
boundary. The whole payload remains pinned; missing directory semantics remain
required port work. The baseline update will be a separate instrument commit.

The standing unit dispatch also omitted the already passing filesystem tests.
Add `fs-boundary-test` with its explicit fuel argument and the14-control native
counterpart to `test_unit.sh`; this ensures future full runs exercise both.
Run the focused unit lane and re-record review, then repeat all39 and864 on a
fresh frozen source. Retain the failed first run without overwriting it. The
advance aggregate-duration justification and unchanged resource bounds above
apply to this retry too; no individual proof/build receives a larger budget.

The re-record completes all68 immaculate rows. Review2 confirms exactly the
single expected directory-row change; all other identifiers/payloads remain
identical. Review1 falsely rejected the same result because it parsed explanatory
stderr after the unique DEVIATION line. Its failed report and the actual engine
captures are retained; review2 corrects only that parser and reuses those
captures. The adopted file also preserves the prior row order and R5/Finding-3
header history which the existing generator omitted; the generator now retains
that history too. No semantic comparison rule changes.


## Frozen integration and retained evidence

`fs-integration-full-r2-20260923` passes all 39 required commands with unchanged
source and no artifact issues. `fs-integration-three-way-r2-20260923` passes all 864
cases. The exact prior-row review finds the single documented directory change:
Lean now supplies its full typed missing-coverage error; fork/pristine keep their
existing undecodable native failure. The other 863 projected observations and
classifications are unchanged. Lean counts are 822 agreement, 29 difference,
11 both-undecodable and 2 not-applicable, with the same 40 discrepancy IDs. The first
full run is retained as failed (37 passed; B5/B9 failed on the stale directory pin). A passing mandatory
report does not relabel its known differences, host failures or undecodable
cases as semantic agreement. The separate baseline instrument update pins the exact new directory error; no comparison projection was weakened.

The [evidence archive](2026-09-21_sc-prototype-evidence/filesystem-repair/README.md)
retains source/build identities, commands, channels, all failed component
attempts, the three compiled production mutants and positive controls, the
thirteen final imported laws, native 14/Lean 16 Driver controls, leaf matrices and
actual C probes. Each archive is read back against its per-member hash manifest.
Rebuildable objects are separately hash-listed; successful reconstructed Cabs
inputs may be omitted from process archives with their hashes retained.

The three mutants remove the fault receipt, commit filesystem state before a
memory failure, or bypass the checked open wrapper. Their designated controls
reject all three while the production control passes. The 13 final production
laws print only standard axioms, with several depending on none. State ordering
refuses through the actual Ord instance; field/structural-equality controls work.

## SC-D13 corrected diagnostic selection

The historical trace mismatch above compared Random.int in the native recorder
with Lean first-selection. The filename `first_smt2.ml` was misleading.
`recorded-c-5` fixes exactly that selector; `selection-review-2` reruns the fixed
binary on the original `recorded-c-4` C paths. All four metadata projections
match, with no event normalization. Full native-to-native captures locate the
original 4/7/3 cleanup differences and 28 parallel differences in the selection
change. This resolves that observed instrument discrepancy without a semantics
change. It does not establish a universal retirement or trace-equivalence law.

The old `raw_journal_equal` field was overstated: the comparator omits rendered
location/type/value, which the Lean diagnostic does not output. The corrected
review preserves identities, source annotations, ranges, representation bits,
provenance and copy offsets and names the projection accurately. Attempt1's
failed projection assertion is retained. Larger parallel-ftell/open-prefix
recordings still time out under their original 20 second bound.

## Boundary inventory and ongoing SC work

The [operation-level inventory](2026-09-23_sc-filesystem-boundary-inventory.md)
records all seven selected open specials, downstream umask decoder and short-
source failures, the earlier proxy-width fault and the separate directory-proxy failure, fourteen unported operations,
open-inode/non-root-cwd gaps, unsupported state ordering and protocol faults.
Each remains distinct from C UB, ordinary errno, host-resource failure or a
completed supported execution. Missing available-guidance port work remains work.

Unadopted follow-ups remain separate: action identity has 15 paired controls and
30 local/conditional kernel laws; four native C identity controls and six native
RMW/HB controls exercise actual requests. Expansion through every alias has
exact action-endpoint HB on those six selected reference diagnostics, while
ordinary publication retains its unordered metadata witnesses. The shared
all-vertex HB query passes 17 paired controls and eight kernel laws; it agrees
on the complete relations in all six actual-C diagnostics, retaining exact
instrument erasure. The conditional path-law premises hold in those six
controls. Four additional kernel laws state the edge-extension obligations for
prefix stability; 785 observed native ND nodes supply 103 distinct snapshots
and 97 consecutive-prefix checks with exact final instrument erasure. Universal reachable-input hypotheses, executable-closure correctness,
RF/location composition and a paired final checker remain outstanding.
Four allocator laws distinguish positive-size cursor decrease from zero-size
address reuse with fresh storage identity; they impose no allocation restriction.
Global-origin metadata has ten paired raw-Core linking controls and six
kernel laws preserving the exact linker result. Three native C controls bind
actual library/caller global storage distinctly, retaining a #line decoy and exact
instrument erasure. A separate native Driver diagnostic additionally retains initialization-time
bindings across two actual C fault prefixes, with exact erasure of its added
receipt field in four controls. Shared production retention and artifact
authentication remain open. The numeric lock-free guard has only
compiler-source research, not a working preprocessing observer. Its exact GCC
plugin SDK is absent locally. A bounded request to the official Ubuntu archive
was rejected by the network allowlist with HTTP 403; no package was downloaded
or installed and no ABI layout was guessed. The failed request and official
source links are retained. No dependency or new semantic reference was adopted.

Six further native C value-view controls show identical captured bytes with
different typed value keys (signed/unsigned, union floating and pointer views),
and two same-key NaN reads with false native value equality. The final double
read after ordered memcpy has eight distinct observed store sources. Exact
instrument erasure holds throughout. These are additional SC-P03 port evidence,
not a selected RF equality or permission to refuse ordered representation work.

An additional direct-child-loop probe exposed lost lexical procedure identity
at Epar spawn (SC-P08). The isolated native repair retains the parent procedure
identifier with an empty child stack: direct while/for and nested child loops
complete, the ordinary helper-call control is unchanged, and all six retained
C/RMW observations remain exact. Pristine reproduces the direct-loop internal
error; its helper-call control reaches the separate old Step_blocked2 defect.
The proposed shared constructor also passes 11 paired controls and seven
kernel laws preserving lexical ownership and an empty stack, without introducing
a call transition. No production fix or paired whole-C completion is claimed. The source rationale and
all failures are retained; shared repair and validation are the next action.

A native before-divergence diagnostic records at the existing memory-effect
producer: ordinary publication retains a reference race witness before an
infinite called-function tail; atomic publication supplies the negative control.
Both remain explicit 20 second timeouts, not completed executions. Six finite
controls preserve exact complete JSON after erasing the added observations.
The earlier returned-ND-node callback missed deterministic work before divergence;
that failed instrument attempt remains retained. This is evidence for the
required prefix interface, not a completed public checker.

Continue the whole charter: actual location/value/RF/HB interpretation, precise
G02/G03/G06/G07/G08 handling, lifetime/library composition, all alternatives and
public C/operational outcomes. `Driver.drive true` still returns checker-pending
before execution. Customer sources remain read-only; no merge or push occurs.
