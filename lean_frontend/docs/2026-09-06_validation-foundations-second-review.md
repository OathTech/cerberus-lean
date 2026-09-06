# Validation foundations — second review

2026-09-06 [AGENT]. Requested by the user after the repair delivery, with
explicit emphasis on avoiding "gate cruft" and building correct semantics.
This is the second pass over the repaired candidate, conducted by the
repairing agent; it is not an independent external audit or merge approval.
The standing requirement for a new reviewer of major core-document revisions
is not discharged by this self-review. A separate, bounded document review
remains necessary unless the user waives that requirement.

Primary subject: `05278ae9537a0212d18a3ca587f79a67e5d9ceaf` on
`arc/validation-foundations`; functional source:
`de9f6d3612232d581622afcdf0b23cdaf31fa09d`. Private instrument companion:
`86a2aea547804b78eb7f1eae633bb9c24c713b7f` on
`arc/validation-foundations-concurrency`. Both were clean at entry.
Mainline remains `89f7e688530c6910884518811d645e4e892e4507`; Lem remains
`f6542f8e6860d12d4655e6648bc4c45dabd1d798`.

## Recommendation

**No new merge-blocking correctness defect found in the repaired scope.**
Accept the eleven instrument/documentation repairs for the landing
discussion. End this validation-only arc and make the next implementation
arc deliver semantic behavior and provider theorems. The maintenance
findings below warrant simplification, not another open-ended adversarial
hardening campaign.

This recommendation concerns the validation-foundations primary. It does
not certify the known failure/byte/state/completion defects as repaired,
approve the larger failure transform, approve the proposed SC theorem's
unsettled hypotheses, or integrate the older private concurrency branch.
C2/C3 remain excluded by ownership and refined-cerberus adoption remains
with its agent. Their disposition and exact landing remain user decisions.
No merge or push was performed.

## Doctrine applied

The container's `/home/dev/projects/cerberus-lean-proj/CLAUDE.md` says:

> The product: the semantics.

and:

> Gates are plant-tested (vacuity must be loud) and reserved for
> load-bearing TRUST properties; discipline points get documentation
> notes and structurally-forcing examples, not gate proliferation.

Its mirror-OCaml, no-internal-trust-gap and no-grind rules also apply.
These are compatible: differential evidence must preserve the observation
actually used to judge semantics, but a test harness is not a hostile-input
security boundary or a replacement for a semantic theorem.

The review therefore checked actual caller behavior, ordinary failed builds
and interrupted jobs, the accuracy of claimed evidence, and whether the
added machinery serves those purposes. It did not search for every possible
forged diagnostic, malicious command, timing interleaving or edited report.
It did not add another gate, mutate semantic inputs, or rebaseline results.

## Repair dispositions

The [first audit](2026-09-06_validation-foundations-premerge-audit.md) and
[repair record](2026-09-06_validation-foundations-audit-repairs.md) remain
the detailed history. Findings below use that audit's VF-01–11 identifiers,
not the supported profile's separate semantic-risk identifiers.

| Finding | Second-pass disposition and reason |
|---|---|
| VF-01, descendant OOM | Closed in scope. Shell/Python share a positive cap witness, independent of the surviving parent's exit status. A fresh native child OOM with parent exit zero was rejected; genuine native exit/signal/output controls also passed. A C return value of 137 remains distinct from a killed semantic engine. |
| VF-02, immaculate CRASH admission | Closed in scope. The codec runs before the coarse legacy CRASH projection, rejecting fuel, mixed/garbage output and unrecognized failures. All 118 retained captures decoded identically, including 21 internal failures. The remaining coarse projection is explicitly regression evidence, not diagnostic or semantic-result agreement. |
| VF-03, UB differences | Closed. UB_DIFF enters the denominator, fails ordinary mode and fails a newly introduced baseline row. Fresh real-entry controls covered equal UB, mixed outcomes, only-difference and partial-baseline cases. Existing explicitly recorded differences remain acknowledged debt. |
| VF-04, command lifetime | Closed for the documented Linux environment. The owned cgroup covers ordinary nested timeout/capped descendants; cleanup completes before logs are finalized. Fresh timeout, background-child, cancellation and supervisor-death tests passed. The additional cleanup-window cancellation repair retains interruption and stops dispatch. |
| VF-05, disappearing inventory entries | Closed for release finalization. Required resources remain represented when absent, and lost entries reject the result. Fresh tests exercise actual inventory deletion and the healthy control. Rebuilt artifact hashes are retained separately from disappearance. |
| VF-06, census ownership | Closed for the demonstrated attribution defect. Compiler source ranges determine the owner, with smallest-range selection and explicit unresolved/ambiguous cases. Lexical names cannot confer dependency flags. The corrected counts remain an inventory/constant-dependency upper bound, not C path-reachability proofs. |
| VF-07, byte-producer account | Closed as a documentation correction. Modeled IO's byte-carrier producers are distinguished from generic Lem String and other printer inputs. Existing byte controls are retained; no normalization was introduced to hide the underlying representation problem. |
| VF-08, current claims | Substantive profile/reporting claims accepted; residual prose corrected during this review (R2-04 below). Current records distinguish agreements, baseline debt, exclusions and release obligations. The changed C4 timeout class is retained rather than called zero movement. Older measurements remain dated. |
| VF-09, multiline internal failure | Closed for the documented protocol. Complete payloads are retained and compared; recognized trace envelopes alone are removed. Different continuations and extra fatal records reject. This textual adapter has the maintenance limit described below. |
| VF-10, duplicate references | Closed. Both private reference readers reject duplicate rows before map construction; reordering valid rows remains accepted. The derivation algorithm and expected outcome sets are unchanged. |
| VF-11, refusal multiplicity | Closed. REFUSE and sequential spawn checks require a singleton completed Error with the fixed domain prefix; full engine comparison checks the complete message. Another Error cannot disappear through set projection. |

Ancillary fixes also serve concrete correctness properties: failed spec-lab
builds cannot execute an existing stale generator; Cabs bridge bytes/status
are retained before publication; native GCC O2 has an explicit killed class.
They do not change C/Core semantics. Small prerequisite tests exercise the
real script entries, so no broad new gate is needed for these fixes.

## Non-blocking maintenance findings

### R2-01 — reduce repeated semantic suites inside instrument tests

`scripts/test_observation_lanes.py:150–158` runs all of verify and immaculate
for each mutation. Most variants change only a small observation property;
the immaculate crash variants target one named case while rerunning the
whole suite. The retained full report measures B9 at **1,097.837 seconds**,
**26.95%** of the complete 4,073.980-second A+B run. The ordinary verify and
immaculate rows already run once, at 46.059 and 70.102 seconds respectively.

The same test also couples its healthy control to incidental presentation:
`scripts/test_observation_lanes.py:188` requires the literal
`127 passed, 0 failed`, and line 190 pins the bytes suite's current counts.
A legitimate added verify test therefore requires editing an unrelated
observation test to keep it green. This is avoidable gate maintenance.

**Recommendation:** preserve thorough byte/status/framing tests in the fast
shared-codec suite. Keep one small positive/negative integration pair for each
distinct caller or projection, with named fixture identity and the expected
classification. Exercise the full semantic corpora in their ordinary lanes.
Add a supported small fixture selection to verify/immaculate if needed;
do not maintain a second copy of their production parser. Remove fixed
whole-suite totals from the instrument controls. There is no reason to
repeat every malformed-stream variant through every semantic corpus.

This is a test-design simplification, not permission to skip the current
required ladder silently. It can be a short maintenance slice; it should
not grow into another validation-foundations charter.

### R2-02 — stop growing the crash-text adapter into a failure semantics

`scripts/observations.py:40–53,156–227` recognizes Lean/OCaml trace syntax
and eight immaculate panic origins, including a compiler-generated private
name. That is understandable compatibility code for existing negative pins,
and the retained real captures pass. It is also coupled to compiler/printer
presentation: a harmless function rename or backtrace-format change can
break a negative regression check without changing C behavior.

**Recommendation:** keep this adapter explicitly bounded to the existing
legacy failure tests. Do not keep expanding origin lists, diagnostic regexes
and synthetic attacker cases as the route to a correct model. New semantic
failure work should deliver typed outcomes and propagation through the
actual entry, with reference evidence at the OCaml boundary. Retire the
corresponding crash adapter cases as those typed paths become available.
Until then, retain raw diagnostics and keep coarse crash regression
separate from semantic agreement. Do not simply accept arbitrary panics.

The failure proposal has the right obligations: success soundness,
completion, faithful failure in both directions, fuel stability and a
conditional connection to value definitions. Adoption should make the
checked semantic entry the authoritative result for its implemented slice;
the old value interface is a related convenience under proved conditions,
not a second independently maintained semantics. No global transform is
needed to accept this instrument repair.

### R2-03 — simplify evidence publication and stop testing metadata as semantics

The repair evidence directory alone is **225,657,975 bytes**. Its six raw
packages contain 198,100 file entries across development, interrupted,
completed, reporting, cold and documentation-checkpoint attempts. Their
uncompressed inventories account for repeated bytes, not distinct inputs.
The final evidence commit adds over one million lines, mostly machine
inventories. This history is legitimate evidence, but it is an expensive
pattern for ordinary future semantic work and upstream review.

The existing Tier A "every commit" rule also makes a documentation/evidence
checkpoint rerun semantic programs. The recorded final fast run took
394.135 seconds and rebuilt version-bearing artifacts for the dirty
documentation state, despite unchanged executable source. Publishing that
run then needs another explanation of what changed after the gate. This is
an administrative cycle, not new semantic confidence.

**Recommendation for the user's working-rule discussion:** validate a
functional source boundary once at the appropriate scope; publish subsequent
documentation/evidence with source-boundary, link and checksum checks.
Retain one authoritative report and raw run per meaningful functional
measurement, plus the concrete failing/positive reproducers. Do not duplicate
whole successful corpora just to certify an index update. Agree a durable
location for large raw bundles before future campaigns; retain small source
fixtures, recipes, classifications and their source identifiers in the repo.
No new archive framework or gate-on-gate mechanism is required.

Existing records were not deleted, moved or rewritten in this review. The
current Tier A per-commit rule remains in force until the user changes it;
the recommendation is not a retrospective waiver or a history rewrite.

### R2-04 — residual current-state prose, corrected in this publication

A full read of `VALIDATION.md` found three residual errors at the reviewed
subject: line 89 calls the initial 67 plants "final"; lines 285–289 still
list Z-28 as unlanded; and lines 433–450 overstate per-test cap coverage and
require exit 137 for an OOM witness. The Z3 fix `2ddc1300c` is an ancestor
of the subject; the current helper source and fresh cap probes establish
the actual status rule.

This publication dates the initial plant count, records the repaired 90-case
run, removes the landed Z3 repair from the open list, and describes the
actual cap scope and any-status witness. Native GCC exclusions remain
distinct from agreement. These are documentation corrections, with no new
test or runtime change. Their discovery does not invalidate the correctly
identified full measurements; it reinforces the need for a concise current
state record instead of repeatedly carrying historical prose forward.

## Evidence and limits of this pass

Fresh checks on the frozen subjects passed:

- 46 Python unittest methods: codec 18, runner/provider 16, census five,
  capture/build prerequisites two and independent-oracle instrument five.
- Four actual native subprocess probes, including the capped child OOM.
- Nine real exec-lane controls/plants, including all four UB cases.
- Nineteen private reference/refusal helper cases.

The private helper is a standalone program. An initial unittest-discovery
invocation rejected discovery arguments before running its cases; the
correct direct invocation subsequently passed all 19. Both attempts are
retained. This was a review-dispatch error, not a candidate regression.

The review separately checked all 31 primary and seven private published
file hashes, archive inventory counts/sizes/unique paths, 68 full/reporting
command-log hashes, all 90 retained actual-entry results, all 20 cold-provider
command results/logs and the 207 Lean/86 OCaml generated-source hashes. It
redecoded all 118 immaculate captures with exact token agreement: 60 Defined,
27 Undefined, ten Error and 21 internal failures. The provider proof source
matches the cold client copy and still states a genuine completed fixture
result and the delivered map law under its actual hypothesis.

The full run remains 32/32 at clean functional `de9f6d361`; C1 remains
242 rows with no movement. C4 remains 2,186 rows, 1,359 agreements and the
single `pr63209.c` CERB_TIMEOUT → LEAN_TIMEOUT movement at the unchanged
15-second budget. No completed Lean result exists for that row. Neither
that timeout nor the six other known Lean-side/UB findings is agreement.

These are fresh targeted tests and checks of retained full/cold measurements,
not a newly executed full A+B or cold build. The final candidate's executable
source is identical to that functional boundary; repeating those large
measurements without a source change or unresolved concern would add cost.
The six existing large archives were checked by their published SHA-256 and
inventories; this pass did not re-expand every archived byte. Critical raw
captures/logs above were checked directly against the retained owned files.

The review record and compact new evidence are published together. Its
documentation checkpoint is identified separately below. No legacy csmith
run, original concurrency worktree or refined-cerberus checkout was operated
on. Existing semantic models, corpus inputs, expected outcome sets, baselines,
historical audit records and package pins remain unchanged.

## Next semantic work

Keep scoped SC integration next: establish the precise observer-agreement
statement and nontrivial admitted domain at entry, then repair mixed-size
overlap and SeqRMW behavior and prove the provider result. Those are product
goals; a growing litmus plant count is not their substitute. Use a bounded
strict-failure slice first only if a concrete theorem dependency requires it.

Retain the shared Lem source and make subsequent Lem/Cerberus changes in
paired worktrees when needed. Do not ask refined-cerberus to compensate for
provider-semantic gaps. The remaining decision package is exact primary
landing, the proposed next charter/theorem/domain, the larger failure design
and the small testing/publication-rule simplifications above. A third generic
instrument-hardening pass is not recommended absent a concrete new defect.
The remaining fresh document review should assess complete current claims,
not expand the set of hypothetical harness adversaries.

## Documentation checkpoint and publication

Tier A passed **13/13** in **412.823 summed seconds**, with source and
external inputs unchanged during the run, no missing/lost required artifact
entries and every owned command scope removed. Twenty-nine version-bearing
OCaml/runtime/freshness entries rebuilt; the report retains both inventories
and does not assume artifact byte identity. The
[checkpoint summary](validation-foundations-second-review-evidence/checkpoint-summary.json)
and [evidence index](validation-foundations-second-review-evidence/README.md)
identify the exact tested documentation snapshot and subsequent publication
changes, including R2-04's prose corrections and this result.

Only documentation/evidence changed after the gate; the executable source,
LADDER membership and semantic baselines remain those of the reviewed
candidate. The compact checkpoint package contains complete command logs,
runner/scope reports and the tested documentation snapshots. Per-program
success captures were not duplicated from the functional evidence archives;
owned scratch captures were retained. The committed record is a review
publication, not a new functional candidate or independent-audit acceptance.
