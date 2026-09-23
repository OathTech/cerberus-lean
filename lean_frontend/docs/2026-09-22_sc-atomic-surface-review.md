# SC atomic interfaces and source-location transport — validated slice

2026-09-22. Parent efb39628c3355376826b65539780b7d3eaf4e18e.
Shared Lem generation and native/Lean compilation pass. Eighteen paired Core
control groups and seven kernel laws now pass. The first 134 native C journals
match the independently prepared outcome classes; seven further flag-function
controls also execute with the expected native outcomes. These are selected
recordings, not exhaustive or SC-definedness verdicts. Broader paired C checks,
parser checks, compiled plants and full integration were initially pending.
Subsequent results are recorded below. On September 23, the frozen full run
passed all 39 Tier A+B commands, followed by the 864-case three-engine report;
sources were unchanged throughout each run. The complete per-row projections,
classifications and existing 40 discrepancy/undecodable IDs are unchanged from
the preceding atomic-update checkpoint. [Retained evidence](2026-09-21_sc-prototype-evidence/atomic-surface/README.md)
includes original failed/incomplete attempts and verified raw archives.
This document claims neither completed atomic coverage nor a completed SC mode.

## Implementation

The C interface now implements non-atomic atomic_init, flag
clear/test-and-set, the five integer fetch operations, signal fences, and
runtime-valued memory orders. Generic calls evaluate all arguments once with
their C argument-order alternatives and parameter conversions before selecting
an operation. The existing constant-order service is reused. Invalid orders
produce executed Core UB; an unexecuted invalid call no longer fails at typing.
Valid weak inter-thread orders retain SC_fault_order, without strengthening.

The parameter type matches the pinned target: stdatomic.h's memory_order enum
has six nonnegative values, so DefaultImpl.register_enum selects unsigned int
(ocaml_implementation.ml:129–142, mirrored in CerberusImpl). The old signed-int
builtin TODO is not a justification for the wrong conversion. Public fences use
ordinary C calls to runtime wrappers, preserving indeterminate sequencing with
otherwise unsequenced caller evaluations (6.5.2.2p10). The internal fence
builtins supply their bodies. Direct-name rewriting was removed after an actual
C trace showed that it lost the call's source-order edge to a sibling store.
Direct/indirect thread/signal calls now have that edge; the corresponding
internal primitive controls do not. All six selected cases also have identical
native/Lean value/output/blocking observations.

The four flag functions have public prototypes and callable runtime bodies as
required by 7.17.8 and 7.1.4; their macro implementations remain available.
A private shared header defines the flag representation once. Runtime
definitions use unsigned-int order parameters compatible with the public enum:
serializing bodies with a TU-local enum parameter exposed the native object's
missing enum registration. Keeping the compatible primitive parameter type in
the definitions avoids introducing that dependency into libc.

The new libc body fixture was freshly derived and reviewed. Removing exactly
the six added function bodies and collapsing blank-line runs gives the original
committed fixture unchanged; no existing library body was rebaselined. The
thirteenth metadata TU is included by libc_prep in the native link order.

N1570 7.17.7.5 supplies wrapping signed arithmetic for integer fetch add/sub;
ordinary atomic operators keep their distinct ordinary arithmetic. Atomic_init
uses NA initialization effects, including when another thread can race with it.
Signal fences retain their source occurrence and order; they introduce no
inter-thread synchronization or SC-order position. This adds no asynchronous
signal delivery to the runtime's existing synchronous raise/handler calls.
Primary text: [N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf).

## Precisely named unsupported cases

[AGENT, applying USER policy] SC-G04 covers an executed abstract unspecified
memory order. The pinned translator cannot consume runtime orders at all; the
specified-order failure is missing implementation and is repaired here.
Unspecified orders need a rule that is absent from that composition. DR451's
library-indeterminate response and Cerberus authors' later concretization
proposal do not identify the same operational step for abstract unspecified
values. Dispatch therefore emits a typed model gap instead of choosing an order
or deriving conditional UB from a synthetic if. Known invalid CAS order values
are checked before an unspecified counterpart can hide their independent UB.
See [DR451](https://www9.open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0451.html)
and the authors' [uninitialized-value notes, Q49/4.2.7](https://www.cl.cam.ac.uk/~pes20/cerberus/notes98-2018-04-21-uninit-v4.html).

[AGENT, applying USER policy] SC-G05 covers generic atomic pointer fetch add/sub.
C11's integer-only applicability conflicts with its pointer synopsis/address
wording. DR486 was closed without a C17 resolution; the later N3788 removes the
pointer wording. It is not a replacement for our pin. The implementation converts the
offset to ptrdiff_t and retains the checked atomic object read before reporting
the gap, with no store/result. Ordinary atomic pointer operators remain covered
by their existing rules. See [DR486](https://www9.open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0486.html)
and [N3788](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3788.htm).

Core PEmodel_gap / Errors.Model_gap retain typed identities and source locations.
They are distinct from C UB. Substitution, visitors, printers and parsers retain
them; copy propagation cannot erase a reached gap because its result is unused.
Paired Core controls cover retained equal-value writes, reads without writes,
discarded and nested gaps, unsequenced alternatives, dead branches and prior
UB. Subsequent compiled mutation controls detect erased refusals and missing
or altered signal-fence records. Fifteen native C prefix assertions check the
new gaps, including checked reads without writes and argument evaluation once.
[Pristine probes](2026-09-21_sc-prototype-evidence/atomic-surface-reference/README.md)
are retained separately from the new-implementation evidence.

## Component validation and remaining scope

There are now 141 combined C inputs, 21 original init/flag inputs and 22
original integer-fetch inputs, including negative and reference-review cases.
The first 134 native combined journals and seven flag-function journals pass
their expected outcome classifications. Paired C runs cover all 141 combined,
21 init/flag and 22 fetch inputs. Forty combined and 33 init/fetch positive
value controls pass. Negative front-end controls that lack decodable native
observations remain separately classified; two refusing processes alone do
not establish observation agreement. Lock-free remains unresolved below.

Selected conversion-error locations differed because of evaluation choices.
Completed bounded exhaustive comparisons retain exact matching observations,
including duplicates: overflow order 21, negative order 126, initialization
conversion 10 and fetch conversion 511. Both engine exits are zero in each run.
Native parser controls (11), native-print-to-Lean roundtrips (8), and the
complete runtime Core parser unit suite (308) pass. The latter includes a
repaired missing backtracking case for the pointer model-gap name and the
reviewed libc function census change from 191 to 197.

The callable flag invalid-order and unspecified-order controls expose a
separate real defect: the native object retains the original C locations,
while the Lean libc text body loses them. The underlying UB205 / SC-G04
identities agree, but their complete observations do not. SC-P07 records the
required source-location transport repair; this is not a new semantic gap.
Raw paired results are in `paired-surface-2`, with fresh native-2 / Lean-3
recording binaries. Component paths in this section are retained in the
checkpoint's `component-evidence.tar.gz`, rooted at `sc-atomic-surface-draft/`.

SC-P07 is subsequently repaired: the opt-in native `--pp_flags=source` format
transports each expression's location list and direct action/UB/model-gap
location, using the existing Cabs source-position/cursor schema. Both parsers
restore those locations. Explicit unknowns remain unknown even in library
parsing. Source-bearing lists retain each node, and unit sequencing uses the
explicit binding syntax, avoiding the ordinary printer's layout ambiguity.
The ordinary dump remains byte-identical; its existing empty-list type spelling
is left unchanged while the new format emits the list type the native grammar
requires. This does not claim general lossless serialization of all Core metadata.

The two original C failures now match exact full observations. Native roundtrips
cover six structural cases and seven refusals; the complete Lean parser suite
passes 322 checks. The complete 48,326,282-byte source-bearing libc parses in the
compiled suite (whole suite 1.97 seconds in this run). The original 4,204,722-byte
ordinary dump was checked byte-for-byte before fixture replacement. Raw failures,
repaired controls, hashes and the fixture review are retained in the
[location-transport evidence](2026-09-21_sc-prototype-evidence/atomic-surface-location-transport/README.md).
The first generation/build/control attempts exposed syntax, namespace,
naming-constraint and control-setup mistakes. Their raw captures are retained
in the checkpoint, including the incorrect test expectation
that omitted startup allocations from a parallel signal-fence graph.

Lock-free query/configuration is still unresolved work. In particular, an
indivisible abstract request does not itself determine ATOMIC_*_LOCK_FREE.
The old preprocessing fallback to zero needs an explicit remedy; no new
lock-free policy or boundary guard is implemented by this slice yet.
Location/value/lifetime composition, stream guards, prefix races, public
outcomes and operational correspondence remain required charter work.
The [boundary register](2026-09-22_sc-boundary-register.md) now additionally
records SC-G06/07/08 from the [retained follow-up](2026-09-21_sc-prototype-evidence/boundary-followup/README.md).
These are evidenced unresolved cases with no dedicated guards yet, not new
implemented support claims. The public checker remains pending.

## Integration validation plan and resource justification

[AGENT, before dispatch] Freeze this interface/transport slice for the complete
39-command Tier A+B ladder, then the mandatory three-engine report. The prior
atomic-update ladder took about 83 minutes; this campaign is authorized by the
charter and the project's slice-boundary gates. The expected duration comes
from bounded corpus measurements and fault/driver integration lanes, not a long
kernel proof or unbounded build. This records the advance justification for a
campaign exceeding one hour. Use one 8 GiB worker, existing per-command limits,
cache-disabled native builds, current generated trees and owning Lean packages.
No heartbeat, recursion, proof-fuel or runtime-fuel limit is raised. Keep raw
failures and re-run only the affected scope when a defect requires a repair;
a successful subset will not be labelled the completed ladder.

Lock-free query/configuration stays a required next slice, with the DR458/465
follow-up recorded in progress; the present checkpoint does not silently claim
those interfaces work. The full SC charter continues after this checkpoint.

The first full run stopped after A1 found two stale failure-register keys.
A2–A4 had passed; A4b was interrupted by the owned runner's normal cancellation
path. The report correctly records incomplete validation and unchanged source.
The generated `translate_errno` and legacy `RMW` failure bodies are unchanged;
the sixty-character keys include the new adjacent comment and signal-fence arm.
Both keys were reviewed and resealed. All 241 site classifications, including
19 UNKNOWN sites, remain unchanged; the new integer-fetch path does not use the
legacy `RMW` arm, and its register note now says so. The exact-site census passes.
This is a reviewed register update, not removal or relaxation of a failure gate.
A fresh full run will certify the repaired register with the slice.

### Integration metadata cardinality repair

[AGENT] The second frozen full run passed A1 after the failure-register repair.
A5 and A10 then refused the 13 emitted libc metadata TUs because their consumers
still pinned 12. The run was stopped gracefully during B1; its complete raw
captures remain an incomplete failed attempt, not certification. The source
identity stayed unchanged during that run. The new stdatomic.c is the thirteenth
TU already present in the reviewed native libc build and metadata producer.

Updated the exact cardinality checks in libc-exec, URI, immaculate, CI sweep,
the three libc-using spec-lab scripts and the three-engine runner, plus current
explanatory comments. The checks still reject missing/extra metadata; no corpus,
observation projection or semantic baseline was changed. A focused A5/A10 run
precedes the next complete frozen integration campaign.

The focused A5/A10 rerun passed both lanes with unchanged sources (39.6 s and
18.6 s). This is a two-lane subset, not Tier A certification. Both targets were
regenerated; build 17 and the unchanged fork-drift manifest passed. Production
and documentation are frozen again for the third full integration attempt and
the mandatory three-engine report.

### Completed integration checkpoint

The third full run passes all 39 selected commands with unchanged source and
no artifact issues. The derived sum of lane times is 5,497 seconds; the advance
resource justification above applies. The three-engine run also passes with
unchanged source: pristine/fork counts are 827 semantic agreements, 14 reviewed
differences, 21 matching failures and two interface agreements. Lean reports
822 agreements, 28 differences, 12 both-undecodable cases and two inapplicable
rows. Every case ID, classification and three-engine observation projection is
exactly unchanged from the previous checkpoint. The 40 existing discrepancy
identities remain limitations; failed processes are not relabelled agreements.

The [evidence index](2026-09-21_sc-prototype-evidence/atomic-surface/README.md)
retains full and incomplete reports, raw channels, component controls, mutation
results, generation/build failures, source identities and implementation hashes.
Archive members were reread and verified by size and SHA-256. Only successful
Cabs bridge stdout is inventoried as reconstructible input; failed bridge and
execution channels remain raw, including public-library client probes.
Subsequent changes for this checkpoint are documentation/evidence only.
The whole SC charter continues; this checkpoint is not release certification.
