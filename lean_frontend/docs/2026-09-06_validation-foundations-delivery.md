# Validation foundations — delivery and final review

**Subsequent audit status, 2026-09-06 [AGENT]: HOLD.** The agreed
[fresh pre-merge audit](2026-09-06_validation-foundations-premerge-audit.md)
found four P1 and seven P2 defects. It reopens G1/G2/G4/G6/G7 and supersedes
the readiness/next-step recommendation below. This delivery record retains
the original candidate measurements and proposal; repair and re-audit come
before SC integration or a landing discussion.

2026-09-06 [AGENT]. The authorized G1–G7 implementation and evidence work
is complete. This record is the end-of-charter discussion package; it does
not authorize landing or certify a customer-ready release.

## Result and scope

The adopted [charter](2026-09-05_validation-foundations-charter.md) delivers
trustworthy observation instruments, independent reference evidence, an
executable release ladder, a cold provider proof client, and a measured
failure census with a concrete correspondence proposal. The private
concurrency branch contains a portable instrument repair; it preserves the
prototype semantics. Full concurrency integration is the proposed next arc.

Distinguish charter delivery from customer-ready release certification.
The latter still needs the excluded reporting evidence, customer adoption,
the agreed audit, and semantic repairs or enforced restrictions for its
claimed domain. Neither the fixture theorem nor a green regression baseline
establishes general C conformance or native/logical agreement.

## Source map

| Purpose | Base / head and scope |
|---|---|
| Assessed and unchanged Cerberus mainline | `mdd/cerberus-lean` at `89f7e688530c6910884518811d645e4e892e4507` |
| Adopted planning series | `assessment/customer-readiness` at `6f17c88445123be4bac47397ade9885117695e4a`, descending from that mainline |
| Primary functional candidate | `arc/validation-foundations` at `1066d89eea16f55a0f204f95c351731629df296a`; final evidence/documentation checkpoint follows it |
| Prototype base | `feature/concurrency` at `086d8762d382eff375c101f5f0c64d3ffe9bccc7`, unchanged in its owner's tree |
| Private repaired instrument | `arc/validation-foundations-concurrency` at `eb926f8d37187490c34a74bd4ffe74c80acdc77b`; preceding checkpoint `51b855aeca1ab10a3de8eccb07dc2a02d67300a4` |
| Lem compiler/runtime and all three package pins | `f6542f8e6860d12d4655e6648bc4c45dabd1d798`; no functional Lem branch or shared re-pin |
| Independent reference | Pristine Cerberus `b9aeedcb4dd438763b0eef7f95ac19e93875d7de` and upstream Lem `3802cb04b53d5f1096a464e51ecbfb2a750a7ccd`, independently generated/built in an owned prefix |

The final checkpoint adds only documentation and evidence after the fixed
functional candidate. Its parent pins the exact tested implementation; the
full reports below identify the immutable source used for every measurement.
The commit series and per-file comparison are in the
[branch map](validation-foundations-evidence/final-branch-map.json).
The final checkpoint's required Tier A result is recorded below.

The shared codec, shell adapter, tests and complete `common.sh` helper are
byte-identical across the two candidates. The older feature also needs its
own litmus/status/refusal handling and P0 prerequisite/locale/duplicate port.
Its 72-path/23-generated-delta manifest differs from the primary 76-path/
22-generated-delta manifest. This is deliberately not a current-mainline
semantic rebase: S7 initialization and measured original `apply_tree` bodies
remain intact; the feature retains its own 83-worker fuel inventory.

## Charter acceptance

| Goal | Delivered evidence | Residual claim boundary |
|---|---|---|
| G1 — observations | Shared byte-preserving codec; six required lanes and inventoried callers; 67 actual-entry plants; 13 codec methods and three real native-stderr probes; complete final battery passes. | Printed-observation equality only; native GCC and independent litmus reference projections remain explicitly weaker. |
| G2 — concurrency instrument | 14/14 private Tier A gates; 30 litmus rows plus sequential refusal; 26 integrated plants and the original four-case corruption probe. Shared helper follow-up committed and archived. | CR-2/CR-3 domain defects, CR-4 theorem and full rebase/feature landing remain open. |
| G3 — independent reference | Owned pristine/upstream-Lem build; 723 applicable comparisons plus an unexpected-difference plant; both representative OCaml package clients; 76 exact content pins and 14 content-gate plants, preserving all 22 generated deltas. Both final independent-oracle commands pass. | Explicit applicability exclusions and one reviewed diagnostic difference remain. Matching crashes are not C-result agreement. |
| G4 — release runner | LADDER-derived 32-command A+B membership, actual CI entry, schema-2 provenance and interruption reports, eleven runner tests. Final A+B passes 32/32 on clean 1066d89ee; C1 completes 242 rows without movement. C4 records all 2,186 rows across 15 suites, with findings retained. | Reporting is measurement; C2/C3 are unrun under the ownership restriction, and full certification remains incomplete. |
| G5 — provider consumption | Cold compiler/runtime/generation/build of all three packages; real-entry completion theorem plus shipped map law; missing-generation and wrong-pin plants; standalone Lem runtime/comprehensive. All 20 final cold steps pass; [manifest summary](validation-foundations-evidence/final-provider-summary.json). | Fixed closed Core fixture, explicit map invariant and declared toolchains; customer adoption belongs to its agent. |
| G6 — failure account | 1,644 sites with source hashes and dependency/channel classifications; eight runnable strictness/control probes; eight pending fuel obligations; strict-result proposal with soundness, completeness and both failure directions. | Census/design completed without broad semantic lifting. Most branch-level C reachability remains unresolved rather than assumed absent. |
| G7 — profile and review | Current profile and ranked obligation ledger, comparison with August 31, corrected historical evidence inventory, updated master plan/overviews, adoption manifest and next charter. Current final archives have per-file inventories and checked hashes. | Twelve original historical logs remain missing; new reproductions are independently dated evidence. Fresh review and landing discussion remain operator decisions. |

## Validation, failed attempts and unrun checks

| Measurement on clean `1066d89ee` | Result and scope |
|---|---|
| Complete Tier A+B | 32/32 commands passed, source/external inputs unchanged, no missing artifact inventory. Summed lane time 3,842 seconds; this includes the finite corpus measurements. |
| Fixed GCC B7 | 1,963 rows; 1,873 agreements, 12 reviewed triaged rows, 78 skips; zero value disagreements, regressions or improvements. The 11 Lean timeout rows remain skips. |
| Observation B9 | All 67 actual-entry plants pass; about 791 seconds. |
| Independent oracle B10 | 723 cases: 709 semantic agreements, 2 interface agreements, 11 matching failures, 1 reviewed diagnostic difference. The actual unexpected-difference plant also passes. Representative package clients are retained separately. |
| C1 reporting | All 242 rows recorded: 91 MATCH, 41 UB_MATCH, 110 CERB_SKIP. Zero scoreboard movement; this is 132 compared matches plus 110 oracle-side skips, not 242 successful comparisons. |
| C4 reporting | All 2,186 rows/15 suites recorded: 1,205 MATCH, 154 UB_MATCH, one UB-location difference, three filesystem refusals, two Lean timeouts, 766 oracle rejections, 29 oracle Error outcomes and 26 oracle timeouts. Source/external inputs unchanged; 56 historical status movements. |
| Final cold provider | All 20 steps pass; unchanged tracked sources, locally rebuilt compiler/runtime, all packages and external proof. Both final G6 instruments also complete with unchanged findings/site inventory. |

The [full summary](validation-foundations-evidence/final-full-summary.json),
[reporting comparison](validation-foundations-evidence/final-reporting-summary.json)
and [provider summary](validation-foundations-evidence/final-provider-summary.json)
pin exact report hashes, statuses, source and timing. Full A+B is in
[final-full](validation-foundations-evidence/final-full.tar.gz); C1/C4 in
[final-reporting](validation-foundations-evidence/final-reporting.tar.gz).
The [CI findings record](2026-09-06_ci-reporting-results.md) disposes of all
56 historical movements and the six current Lean non-agreement rows.

Source and external inputs stayed unchanged during the full run. Build
artifacts were not byte-identical before/after: 29 of 1,775 recorded entries
changed through rebuilding commit-version metadata, dependent OCaml
libraries/binaries, staged libc and freshness stamps. Both inventories are
retained; no missing-artifact issue was reported. The cold run separately
reconstructed the actual candidate from absent generated/build trees.

The first complete A+B run passed 28/32 commands with unchanged source.
Its GCC and hang/kill/fuel failures exposed capture-composition defects;
all raw records and the exact pre-repair patch remain archived. The focused
classification retry passed hang/kill but exposed literal fuel text being
misclassified; the repaired focused fuel check passed. The dedicated repair
commit changes no semantic baseline. This history is not hidden behind the
final green results.

Earlier development failures include the cold recipe's wrong version-string
assumption, the failure-probe control name colliding with the source grammar,
and the older concurrency fork-manifest locale defect. Each was an instrument
or recipe defect with a subsequent identified successful run; its retained
records are development evidence. The comprehensive Lem suite keeps two
ruled host-integer-overflow exceptions and two unresolved byte/string XFAILs.

The measured strictness mismatches are semantic findings, not failed gate
machinery: five discard forms fail in OCaml and return success in Lean;
a mapped projection returns a value under kernel reduction but aborts in
native/interpreted execution. Their positive and required-failure controls
prevent a vacuous measurement. No representation change was made here.

Unrun: C2 fuzz campaign and C3 csmith reporting corpus; customer re-pin/build;
fresh independent audit; complete concurrency integration/theorem/landing;
broad failure/byte/state/fuel repairs. The first two are excluded by the
legacy ownership instruction; the remaining items belong to the reserved
review or later semantic charters. No legacy worktree/log was inspected during execution of this charter.

## Evidence and adoption

The [evidence index](validation-foundations-evidence/README.md) distinguishes
development, failed attempts and final evidence. Its
[SHA256SUMS](validation-foundations-evidence/SHA256SUMS) and per-archive file
inventories identify retained bytes. The
[provider adoption manifest](validation-foundations-evidence/provider-adoption.json)
links package pins, migration records, proof hypotheses and remaining exits.
The [final provider/failure archive](validation-foundations-evidence/final-provider-failures.tar.gz)
contains cold logs, compiler/runtime identities, the external client and
directly rerun failure probes/census. The earlier developer evidence remains
separate; no old compiler binary was assumed equal to the new build.
Archives preserve original relative paths; extracting them into an owned
checkout restores reports/raw captures at their recorded paths. Absolute
paths in command provenance identify where the measurement ran; source and
artifact hashes identify what ran. Compiled products are rebuildable from
pinned sources and are not a substitute for the cold recipe.

The provider manifest is for the customer's agent to assess. No message,
customer edit or re-pin was sent/performed as part of this work.

## Recommended next charter and decisions

Prefer [scoped SC integration](2026-09-06_concurrency-integration-charter.md)
next. The repaired instruments now support assessing it. Require a checked
access domain, mixed-size/SeqRMW repair or attributed refusal, the accepted
nonvacuous observer-agreement theorem, preserved S7 behavior and full
current-mainline rebase. If a concrete strict-failure/state path blocks that
theorem, authorize a bounded failure slice first; do not weaken the theorem
or substitute an always-refusing fragment.

For the failure design, recommend a typed strict-result translation before
erasure, first over the demonstrated discard mechanisms and one real
memory/driver path. Retain the shared Lem/OCaml reference. Require successful
witnesses, sufficient-fuel completion and faithful failure in both directions,
with the OCaml compiler/runtime boundary stated separately. Adopt or revise
this design before implementation of the larger transform.

Propose a fresh independent reviewer for the full implementation and core
documents, plus selected independent reproductions. The functional primary
delta from the assessed mainline spans 86 paths; the private instrument
delta spans 18. Review these six areas:

1. Observation byte-source tracing, status capture, sequence/set projections,
   framing and resource/refusal policy; inspect all 67 primary and 26 private
   plants and independently replay representative adversaries.
2. Independent oracle/compiler/runtime provenance, applicability exclusions,
   the one diagnostic difference, 76 whole-file pins and 22 generated deltas.
3. LADDER/CI membership, interruption and missing-input behavior, source and
   artifact identity, reporting classification and excluded evidence.
4. Unprimed provider consumption, actual completion/map-law hypotheses,
   three package pins and declared logical/native boundaries.
5. Private concurrency P0 port, 72-path/23-delta manifest, all 30 litmus
   outcomes and sequential refusal; preservation of S7 and measured original
   `apply_tree`. Full feature integration remains the next proposed charter.
6. Full fresh review of master plan, supported profile, failure design/census,
   execution/delivery records and next charter against their actual evidence.

This is an audit proposal, not an audit performed by this author. The final
documentation/evidence delta is included in the proposed full review.

At the final discussion: decide the failure design, the next concurrency
charter, and audit scope/scale including unavailable reporting/adoption.
After the agreed audit, decide readiness and obtain separate per-merge
ff-only sign-off for the exact branch. Revalidate if mainline moves. The
private feature instrument is preparation for integration, not an authorized
merge of the prototype. Pushing requires a separate decision.

## Final documentation checkpoint

The required final Tier A check completed all 13 commands with unchanged
source and no missing artifact inventory (summed lane time 422.6
seconds). Its [source/result record](validation-foundations-evidence/final-checkpoint-source.json)
and [raw archive](validation-foundations-evidence/final-checkpoint-fast.tar.gz)
retain the exact tested documentation/evidence hashes and original source
fingerprint. The first launcher attempt omitted the documented `bash` prefix
and exited 126 before any lane; that log is retained separately.

After the pass, this checkpoint adds the result/archive records and small
master-plan/DESIGN wording corrections. It changes no functional source,
package pin or semantic baseline from `1066d89ee`. Complete A+B, reporting
and cold evidence therefore remain attached to that immutable functional
candidate. All current evidence checksums and links were checked before
commit; the twelve missing historical links remain only in the preserved
historical README.
