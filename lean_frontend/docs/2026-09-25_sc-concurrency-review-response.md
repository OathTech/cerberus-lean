# SC concurrency plan: response to independent review

Date: 2026-09-25. [AGENT] response on `arc/sc-concurrency` to the review at
`e280ba684e95be1c4e6c38ec8e21fa09316950df`, which reviewed master-plan commit
`b34bcd7bd10285ca595f8e601ca2fbf191f75dfe`. [USER] notified this agent that the
review had landed. The [review](2026-09-25_sc-concurrency-plan-review.md) and its
[cost evidence](2026-09-25_sc-plan-review-cost-evidence.json) are copied exactly
from that commit so this branch contains the evidence for the revision.
The review branch and mainline are unchanged.

The [master plan](../../SC-CONCURRENCY.md) remains the only current status and
work-order authority. This response records dispositions, not a second status
ledger. These are planning corrections, not completed runtime obligations or
an independent approval of the revised plan.

## Disposition

| Finding | Decision and change | Evidence still required during implementation |
|---|---|---|
| **R1: release scope and correspondence risk** | Retain the existing full public-release bar. Do not adopt the suggested smaller public profile without a user scope decision. Add V1, an early internal real-C publication/fork/join/object/budget milestone, and WP-C, an explicit correspondence package beginning in WP1. This follows the review's alternative for retaining the release bar. | WP1 must produce well-typed candidate statements, nonvacuous hypothesis examples and a credible decomposition, with initialization/reference assumptions explicit. S1–S4 discharge their attached obligations; general Core coverage cannot be left to final audit. V1 is not public support or a substitute for proofs. |
| **R2: causal summaries** | Accept. Make the actual-continuation summary experiment a prerequisite to broad extraction. Derive reference source relations independently, test missing/invented order and first conflicts, and count retired coordinates/references as well as frontier size. | A substantive summary/first-race invariant and repeated fixed-width source split/join and bounded-live-thread churn. A failing representation must be revised before feature expansion; a narrower accepted source fragment requires an explicit scope decision. |
| **R3: actual bounded step** | Accept. Move the actual initialized transition API, observation projection and resource accounting into S1, preceded by a WP1 experiment. The donor ND wrapper is candidate continuation machinery only. | Deterministic singleton execution yields; tiny step budgets return incomplete promptly; repeated steps match a bounded run on state/effects/resources; choice discovery has no unchosen effects; `SeqRMW` remains non-atomic. Concurrent helpers later require a current-state resumption witness. |
| **R4: finite WP0 and receipt meaning** | Accept. Close WP0 after one paired load/store observation slice and diagnostic consumer, with only necessary state transport/representation access. Later helper/lifetime/metadata receipts accompany their first execution consumer. Separate primitive receipts, logical C actions and scheduler boundaries. | Results, same-value writes, failure state, ND alternatives and completed-prefix controls; disabled-observer erasure and bounded/drainable storage. No default history of whole memory snapshots. End-of-helper receipt replay alone cannot validate internal interleavings or race state. |
| **R5: inherited costs** | Accept. Bound added SC overhead separately and retain end-to-end usefulness measurements. Identify inherited trace/lifetime/output/closure costs rather than promising a whole-machine live-state bound. | Fixed-object, lifetime-churn, source split/join and thread-churn probes, with actual work counters, retained roots, time/RSS and matching sequential controls. Any necessary sequential optimization gets a separately justified slice. |

The smaller-first-public-release option was raised with the user as a
preference question. It is not adopted by this response; the existing contract
remains in force. Keeping it means correspondence is real critical-path work,
not that a proof becomes routine. WP1 must expose a failure of that plan early.
No release restriction or proof obligation is silently changed.

## Source checks supporting the response

I read the complete review and checked its load-bearing implementation claims
against current mainline `e9f9d049f` and the pinned donor implementation
`631382a9d23a709112f38add53357d4cbe6fc108` (the donor's current documentation
tip changes no runtime source).

- Current `nondeterminism.lem:62–76` executes the next continuation immediately
  after `NDactive`; `pick` at `190–200` returns `NDactive` for a singleton.
  Consequently an exposed ND node does not alone bound deterministic work.
- Current `driver.lem:1279–1282` invokes eager advancement during thread
  discovery; `can_advance` and `advance_step` at `914–985` admit/execute memory
  requests. Ordinary `SeqRMW` groups load/update/store at `714–724`. These
  paths need explicit boundary checks before reuse in concurrency.
- Donor `sc_driver_machine` at `2067–2083` recurs through `sc_step`; its
  `sc_program_node` at `2740` invokes the stored computation. Preserving that
  continuation is useful but does not prove step-budget or Iris-step behavior.
- Current `liftMem` at `driver.lem:129–135` uses the existing `ND.liftND`;
  current lifting is defined at `nondeterminism.lem:247–284`. No new transport
  defect has been established. WP0 reuses it wherever sufficient.
- Current concrete footprint at `impl_mem.ml:526–537` has kind, address and
  size. It is not a complete C-location/source-order contract. The existing
  driver trace is retained at `driver.lem:73,697,710`; `is_dead` uses list
  membership at `impl_mem.ml:670`, and `kill` conses a dead identity at `1548`.
  Lean's `CerbMem` likewise stores `deadAllocations` as a list and uses
  `.contains`. These support the inherited-history concern independently of
  timing samples.
- `cmm_csem.lem:1120–1180` has executable `true` stand-ins for source
  receptiveness and well-formed-thread assumptions; `bigthm:2855` targets
  HOL/Isabelle/TeX. Neither establishes Core-to-reference coverage in Lean.

The reviewer ran eight existing-binary sequential cost controls; I inspected
their raw sources/commands/results but did not rerun or rebuild them. This
response adds no runtime execution evidence and claims no asymptotic fit.

## Revised immediate sequence

1. Prepare the minimal paired load/store observation slice with its diagnostic
   consumer and independently derived state/erasure/failure controls. Once
   audited and landed, WP0 is closed.
2. Run the WP1 actual-Core summary, reclamation, bounded-step/resource and
   independent reference experiments, with WP-C's exact domain/statements and
   proof decomposition. Freeze the strategy only on the resulting evidence.
3. Build S1's real transition API and the minimal S2/source and S3/C-surface
   pieces needed for V1. Keep that lane running while audited operation and
   service families land separately.
4. Complete the full semantic, correspondence, scale and consumer obligations
   before public SC enablement. Preserve existing per-landing audit/sign-off
   and pin procedures.

The edits are confined to planning, quarry guidance and test-corpus guidance.
Checks cover document links and whitespace, exact preservation of imported
review artifacts, existing raw diagnostic records and C input provenance.
No production source changed, no runtime gates were rerun, and no mainline
merge or push is implied by this response.
