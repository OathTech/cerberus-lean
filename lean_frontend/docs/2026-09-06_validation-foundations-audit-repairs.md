# Validation foundations — audit repairs and second-review candidate

2026-09-06 [AGENT]. Work authorized by the user's instruction to repair the
first audit and return a merge candidate for a second review. This record
tracks implementation and validation; no merge or push is authorized.

Starting primary: `b1aa25796bdebdf61c9c1c3523d9dd534e204800` on
`arc/validation-foundations`; private: `eb926f8d37187490c34a74bd4ffe74c80acdc77b`
on `arc/validation-foundations-concurrency`. The
[first audit](2026-09-06_validation-foundations-premerge-audit.md) remains
unaltered historical evidence. Lem remains at `f6542f8`; no Lem semantic
change is needed for these repairs. The legacy csmith run, refined-cerberus
and original concurrency worktree remain untouched.

## Scope and implementation decisions

Repair VF-01–11 on the relevant candidates, with durable positive controls
and the audit adversaries. Also dispose of the ancillary capture,
spec-lab build-status, GCC O2 kill and private contract-document concerns.
Keep raw historical observations and census data; regenerate new measurements
under their own source identities. Do not change model semantics or hide
classification movement by silently rewriting baselines.

Routine decisions [AGENT]: use owned cgroup containment for whole command
lifetimes, including nested timeout/capped work; use the shared codec before
any coarse crash/refusal projection; require all compared UB differences in
default-mode status and denominator; use compiler source ranges for census
dependency assignment. Normalize only recognized diagnostic trace envelopes;
retain failure payload bytes and reject additional fatal/ambiguous records.
Critical semantic-design and feature-domain decisions remain for later
charters and the user discussion.

## Validation schedule

Run targeted durable plants and independent first-audit reproductions,
primary Tier A+B on the corrected functional candidate, private Tier A plus
litmus/reference/refusal plants, affected C1/C4 reporting, and cold provider
checks for the changed orchestration/inventory. Preserve exact heads, hashes,
full logs, failed attempts and new classification accounting. Second review
is a separate pass over the resulting candidate; this repair record does not
claim reviewer approval.

The full A+B schedule includes the already-scoped fixed B7 corpus and B9
actual-entry plants. The previous battery took 3,842 summed lane seconds.
Its aggregate duration above one hour is justified in advance [AGENT] by
these finite differential measurements, not an individual build/proof grind.
Use one heavy job at a time and 32G caps. No individual build/proof step may
cross the one-hour tripwire; stop and report before that limit. Do not run
C2/C3 or touch the legacy run under this authorization.

## Implemented repairs

| Finding | Repair and durable checks |
|---|---|
| VF-01 | Shared positive cap-witness grammar rejects direct or descendant OOM at any parent status. Codec controls include both banner generations; native subprocess probe creates a real 128M-cap child OOM with parent exit 0; all batch lane plants inject the witness. |
| VF-02 | Immaculate validates the shared `immaculate` policy before CRASH projection. Eight reviewed Lean panic origins and observed OCaml trace forms are explicit. Whole-lane plants target the pinned memcmp crash with fuel, garbage stdout and an unreviewed panic; healthy actual captures remain controls. |
| VF-03 | UB_DIFF fails default mode, enters the comparison denominator and fails a new-row baseline check. Actual-entry mixed, all-difference and partial-baseline plants accompany the equal-UB control. Existing explicitly pinned UB_DIFF remains acknowledged baseline debt, not agreement. |
| VF-04 | `ProcessScope` contains complete command lifetimes in owned cgroup v2 subtrees; a pipe guardian cleans after supervisor death. Release and cold-provider commands use it; nested caps cannot fall back outside the scope. Tests cover nested GNU timeout/capped groups, successful leaders leaving children, timeout, SIGTERM and SIGKILL. Logs are finalized only after cleanup; cleanup failure stops dispatch. |
| VF-05 | Mandatory roots/resources are always inventoried; finalization rejects missing and lost entries. Tests delete actual ignored runtime/native fixture files with the real inventory/finalizer and a healthy control. Rebuild-dependent byte changes remain visible, separately from disappearance. |
| VF-06 | Every canonical owner requires compiler-range containment; anonymous names are hints only. Smallest-range, ambiguity and used-def/unused-instance controls prevent borrowed dependency flags. Corrected census keeps 1,644 sites and 1,642 identified owners; pure execution-dependent sites fall 261 → 231. |
| VF-07 | TODO now states modeled IO's byte-carrier representation, existing C3 A9/FF controls, and the separate unknown producer/generic Lem String obligations. No printer or semantic byte conversion was made. |
| VF-08 | README/VALIDATION now date CI counts, distinguish agreement from baseline/exclusions and describe the delivered runner/projections. The matrix separates canonical libc-exec tokens from libxml2 printer spelling. |
| VF-09 | Internal failure decoding retains multiline payloads and only consumes a recognized, validated trace envelope. Differing continuations and additional fatal records reject; equal payloads remain positive controls. |
| VF-10 | Both private reference readers reject identical and contradictory duplicate rows with line diagnostics. The 19-case actual-helper/reference battery includes reordered, wrong, missing and orphan controls. |
| VF-11 | Both private refusal guards require exactly one completed Error per engine with the fixed domain prefix and equal complete messages. Extra identical or different Errors cannot pass via set projection. |

Ancillary dispositions: the exec/CN/multi-TU/GCC/verify Cabs bridges retain
separate raw streams, original status and command outside disposable scratch;
bridge-failure/OOM-success controls check that failed bytes are never published
as usable JSON. Six spec-lab builds now fail immediately on nonzero status and
retain diagnostics; actual entry-point fixture plants place an existing
executable behind a failed build and verify it is never run, with healthy
prerequisite controls. Native GCC O2 has an explicit `O2_SKIP_KILL` class and
rejects unknown native classifications. The private candidate now carries the
shared observation-contract document, with its narrower branch scope stated.

The only changed whole-file oracle-surface pin is `scripts/common.sh`, reviewed
for cap classification and capture plumbing above. The 22 generated-OCaml
delta pins and model sources are unchanged. No baseline values or concurrency
reference sets are edited.

## Validation checkpoints

Targeted/hermetic repairs, the first checkpoint and the intentionally
interrupted attempt remain separate records. The completed clean-candidate
measurements below supersede the interrupted attempt. Second-review acceptance
remains pending; these are the repairing agent's checks.


## Cancellation correction after the first repair checkpoint

The first repair checkpoint is `68de6771c65d06704612c691a9fca7efbff70e3d`.
Its complete pre-commit Tier A passed 13/13, and its committed source was
matched to the tested tracked diff and new-file hashes. The first full run
passed 29 commands, including the unchanged 1,963-row GCC baseline and all
hang/kill/fuel plants, before the agent deliberately interrupted B9 to repair
an additional cancellation window. The incomplete run and its raw outputs
remain separate evidence; it is not a full-gate pass.

The new `ProcessScope.finish` originally ignored SIGINT/SIGTERM during
cleanup. A first signal arriving in that window could be lost, allowing the
next lane to start. A real signal injected during the actual cleanup made
the old runner return success and dispatch its next command; the regression
test failed as expected. Cleanup now temporarily blocks those signals and
restores the previous signal mask after removing the owned subtree. Pending
cancellation is then delivered to the original handler. Release and provider
callers record an incomplete result, the actual available process status and
cleanup state, and stop dispatch. The finalizer restores the mask even if
cleanup itself raises.

A second actual-entry test uses tiny owned Git fixtures to interrupt provider
cleanup after its first checkout: the manifest remains incomplete, the
command cgroup is gone, and the second checkout never starts. The runner
suite now contains 16 methods. Both first/second signal-repair attempts and
the full-run interruption record are retained. A new functional checkpoint
and full candidate measurements supersede the interrupted attempt.

The runner/provider require Linux cgroup v2 delegation with memory enabled
and `cgroup.kill`. Unsupported environments fail before a command launches.
Containment covers the supplied commands and their ordinary descendants,
including nested timeouts/caps; it is not isolation against a command that
deliberately moves itself to a different cgroup.


## Measured candidate for second review

Functional primary: `de9f6d3612232d581622afcdf0b23cdaf31fa09d` on
`arc/validation-foundations`. The final documentation/evidence commit carries
these results and its separate Tier A checkpoint. Private companion:
`86a2aea547804b78eb7f1eae633bb9c24c713b7f` on `arc/validation-foundations-concurrency`,
with functional changes at `2460ef33f897761dc40680437b2c5cd420e22dc6`.
The primary descends from mainline `89f7e688530c6910884518811d645e4e892e4507`.
The private companion remains on the older feature base; integrate its
instrument changes in the future SC charter, rather than landing that older
branch directly. Lem/compiler/pinned checkout and all three package pins
remain `f6542f8e6860d12d4655e6648bc4c45dabd1d798`.

| Measurement | Completed result |
|---|---|
| Primary Tier A+B | 32/32 commands; 4073.980 summed seconds; clean unchanged functional source and external inputs |
| Real observation entry-point plants | 90/90 across 16 lane families, including all new audit adversaries |
| Hermetic checks | 18 codec, two prerequisite, five census, 16 release/provider and five oracle-instrument methods |
| Fixed GCC corpus | 1,963 rows; 1,873 agreements, 12 triaged comparisons, existing skips; zero regressions and zero improvements; 190 O2 agreements |
| Pristine oracle | 723 rows: 709 semantic agreements, 11 matching failures, one reviewed difference, two interface agreements; separate library check and unexpected-verdict plant pass |
| Private companion | Final Tier A 14/14 (351.161 summed seconds), all 30 actual litmus rows; 26 observation plants and 19 reference/refusal adversaries |
| Cold provider | 20/20 commands; all 1,769 present artifact hashes checked; 207 Lean and 86 OCaml generated files match the original candidate |
| Failure evidence | All eight observations reproduced; compiler-range census reproduced all 1,644 sites, 1,642 identified owners, two unresolved; 231 pure execution-dependent sites and 305 execution-dependent sites overall |
| C1 | All 242 rows; 91 MATCH, 41 UB_MATCH, 110 CERB_SKIP; no movement from the original candidate |
| C4 | All 2,186 rows across 15 suites; exact input set/hashes checked; one classification movement from the original candidate; detailed counts below |

C4 records 1,205 MATCH and 154 UB_MATCH (1,359 agreements), one UB_DIFF,
three filesystem refusals, three Lean timeouts and 820 oracle-side
non-comparisons (766 rejects, 29 errors, 25 timeouts). The single movement is
`pr63209.c`: the oracle now completes just below the unchanged 15-second
budget, then Lean times out with no output. The
[timing record](validation-foundations-repair-evidence/c4-timing-movement-v2.json)
retains both runs; no completed Lean result is available to compare.
Reporting results are measurements. The historical scoreboards and every
semantic baseline remain unchanged; skips, timeouts, attributed refusals,
triaged rows and the UB-location difference are not observation agreement.
The eight strictness observations reproduce known failures and limits; they
do not establish general failure correspondence or customer adoption.

The full run has 1,778 artifact entries before and after, with no missing or
lost entry. It records 29 changed hashes: version-bearing OCaml libraries and
binary, serialized runtimes and freshness stamps rebuilt from the previous
dirty checkpoint at the committed candidate. Both recorded source fingerprints
and the Lean executable hash are unchanged. The exact before/after identities
and serialized runtime headers are retained; no rebuilt-binary identity is
assumed. The cold rehearsal independently reconstructs the new candidate.

The [evidence index](validation-foundations-repair-evidence/README.md) retains
all new owned raw attempts, command/status/log hashes, per-file archive
inventories, source-to-commit checks and source/model/reference preservation.
The original first-audit report and evidence are unchanged. Additional
ancillary prerequisite controls exercise six actual script entries behind
failed builds, with healthy controls; no stale executable is run. All raw
Cabs captures are retained by the repaired paths before publication as JSON.

The next step is a fresh second review of this candidate and the updated core
documents. Critical design/SC-domain and landing decisions remain for the
user discussion; no second-review acceptance, merge, push or adoption is
claimed. The original concurrency worktree and the legacy run remain outside
these operations.

The final documentation checkpoint passed Tier A **13/13**, in 394.135
summed seconds, with its source snapshot and external inputs unchanged,
no missing/lost required artifacts and every owned process scope removed.
Its 29 changed artifact hashes record the version-bearing OCaml/runtime
rebuild for the documented dirty checkpoint; both source fingerprints and
the Lean executable hash stayed unchanged. The
[checkpoint summary](validation-foundations-repair-evidence/final-checkpoint-summary.json)
retains the exact tested diff, untracked-file hashes, metadata snapshots and
before/after artifact identities. Subsequent changes publish this result,
the TODO's current C4 entry and the evidence index/inventories. These are
documentation/evidence changes; executable source and all 36 ladder command
entries remain those of `de9f6d361`. The commit carrying this record is the
candidate's final documentation/evidence checkpoint.
