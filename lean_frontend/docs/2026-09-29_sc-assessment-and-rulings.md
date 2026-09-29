# SC concurrency: state assessment and operator rulings (2026-09-29)

[AGENT] Orchestrator record. The operator returned after a break and asked
for "a close look at our current branch and make an assessment of the state
wrt plans, overall credibility, etc." using Opus- and Fable-class reviewer
agents. This record keeps the assessment, the questions put to the operator,
the operator's answers verbatim and what they change. The master plan
[SC-CONCURRENCY.md](../../SC-CONCURRENCY.md) carries the resulting current
state; this record is the dated evidence behind it.

Heads assessed: plan branch `arc/sc-concurrency` `1b15b5b9a`; WP1 branch
`arc/sc-wp1` `186392a53` (base `5ecc0aa33`); WP1 review
`review/sc-wp1-20260928` `1c7e52fad`; mainline `mdd/cerberus-lean`
`d62f52121` at assessment time (`f6fc60d4b` when this record was written).

## 1. Assessment

Two fresh reviewer agents, neither an author of the range: an Opus agent on
plan, process and record integrity (read-only), and a Fable agent on
technical substance (read-only, focused capped re-runs). Their reports were
not committed; the findings below are the orchestrator's summary, labelled
by source. "Measured" means the reviewer or orchestrator checked it against
Git or a run; "inferred" is judgement.

**Verdict [AGENT].** The recovery is honest and well-directed, and it has
avoided the failed prototype's modes (no completion claims, the rejected
graph-admission / single-writer / race-suppression designs stay rejected).
It has not yet produced executable SC: nothing on a production path
schedules threads, and the first transition-API slice (S1) had not started.
The risk has moved from over-claiming to process weight and to evidence that
comes from test-only stand-ins.

Findings, most significant first:

1. **Delivered vs documented (measured, Opus).** WP0 is the only landing:
   about 135 lines of semantics against about 4.6k lines of records and
   evidence. WP1 is about 5.8k lines of documents and evidence, 2.1k of
   tests/probes, and 372 added / 18 removed lines of shared-Lem/OCaml
   changes over four files (253/18 in `driver.lem` and `core_reduction.lem`;
   `git diff --numstat 5ecc0aa33 186392a53`, corrected by the L0 pre-merge
   audit from the reviewer's "about 500"), mostly experimental.
2. **WP1's feature evidence comes from a Lean-only test adapter (measured,
   Fable).** The shared-Lem experimental stepper (`driver.lem`,
   `experiment_*`) refuses SeqRMW, atomic accesses, thread spawn/finish and
   other memory operations. `test/Unit/SCWP1Decision.lean` supplies them
   instead, including Lean-local fork/join handling that upstream refuses
   (`core_run_aux.lem:101-102`). The OCaml oracle has no counterpart. WP1's
   pending-RMW, fork/join and publication results therefore transfer to S1
   as a specification, not as validated code. The direction itself (select
   one Core step at a time over the existing concrete memory; an RMW keeps
   ownership of its thread while other threads run) is the standard shape of
   an SC interleaving semantics and the bounded-stepping feasibility claim is
   supported.
3. **The "substantive link" lemmas are real but local (measured, Fable).**
   `unseq_pairwise` / `hoisting_excludes_prior` are genuine theorems about
   production Core definitions, but they concern Core's intra-thread
   unsequenced-race check, not inter-thread order or the reference model.
   The correspondence items in `SCWP1Contracts.lean` are statement schemas.
   The plan's WP1 exit asked for more; the review response met it by
   rewording. The retention and first-conflict results are hand-built
   fixtures; the one real scale measurement is flat thread/environment/
   allocation state across 8192 actual Core rounds.
4. **Underweighted risk (inferred, Fable).** Core hoists some memory effects
   ahead of their source position, so effect order is not source order.
   Recovering the reference model's sequenced-before relation from Core's
   annotations, and an inter-thread race monitor built on it, have no
   prototype yet. Fable ranks this above read-dependent coverage.
5. **Experiment code in shared production Lem (measured, orchestrator and
   both reviewers).** `step_ctx` is refactored to take a continuation
   (behaviour-preserving; the old list interface is kept as
   `step_contexts`), the driver gains `_with` entry points, `step_kind`
   gains `SK_core_boundary`, and a 206-line `experiment_*` block is compiled
   into both engines but unused by `drive`. Oracle debug output at `-d ≥2`
   changed (68–69 `ENTERING` lines lost). This is the open condition M2.
6. **Records (measured, Opus).** All 17 commit hashes the plan cites exist
   and match their descriptions; no agent decision is presented as the
   operator's. Several `[USER]` tags are unlabelled paraphrases
   (`SC-CONCURRENCY.md` 1b15b5b9a lines 12-16 and 316; `SC-WP1.md` lines 3
   and 6). The plan is dense with house jargon, uses F1–F4 without defining
   them, and its L0 row contradicted its status table.
7. **Review quality (measured, Opus).** The WP1 independent review was
   genuinely independent and skeptical (cache-disabled rebuilds, re-hashed
   evidence, four plants with revert and rebuild, a real unrecorded oracle
   change found). Its response `186392a53` and the plan corrections
   `1b15b5b9a` had not been re-reviewed.
8. **Branch state (measured).** `arc/sc-concurrency` was 45 commits behind
   mainline and conflicted in `lean_frontend/README.md` and `TODO.md`;
   `arc/sc-wp1` was 4 behind and merged cleanly.

Fable's re-runs (verbatim result lines): `SCWP1RacePrefixChecks.lean` rc=0,
diff against the committed transcript `IDENTICAL`; the four
`SCWP1SourceProofs` axiom lines each `depends on axioms: [propext,
Classical.choice, Quot.sound]`; no `native_decide`, `bv_decide`, `ofReduce`,
`sorry`, `admit` or `axiom` in the SCWP1 files. The 40/40 ladder and the
three-engine report were not re-run; they remain author-recorded.

## 2. Questions and rulings

The orchestrator's six questions, as put (quoted from the assessment):

1. "M2 (shared-Lem experiment code). My recommendation: don't land WP1's
   code — land WP1 as a decision record only and start S1 fresh from
   mainline with a single stepper in Lem."
2. "M1 (inherited upstream behaviour). Do we diverge from upstream on
   fork-result order and upstream's explicit `Stack_cons2` refusal (reached
   only via Cerberus's non-ISO par-block extension), or mirror upstream and
   refuse loudly in S1?"
3. "Coordination: accept, amend or reject the [AGENT] counterproposal to
   the next-phase track."
4. "L0: rebase and land `SC-CONCURRENCY.md` on mainline, or keep it
   branch-only."
5. "Re-review: commission a re-review of `186392a53` and `1b15b5b9a`, or
   waive."
6. "Process weight: optionally direct lighter per-slice records and a
   plain-language summary at the top of the plan."

[USER 2026-09-29], first answer, verbatim:

> (1) agree, (2) agree, mirror and refuse seems safest (3) what's the
> question here? (4) land on mainline seems reasonable, (5) what do you
> recommend? (6) agree

[AGENT] follow-up, as put: on (3), accept the counterproposal with one
amendment — its "first S1 work" paragraph assumed a divergence from
upstream on fork/wait that ruling (2) removes. On (5), no separate
re-review of `186392a53` (its code no longer lands); fold one fresh full
review of the revised plan plus the WP1 decision record into the pre-merge
audit of the L0 landing, since rulings (1), (2) and (6) require a real plan
revision anyway.

[USER 2026-09-29], second answer, verbatim:

> yeah, agree on (3) although we're doing some bug hunting first on the
> main-line agent. (5) agree. Go ahead

## 3. What the rulings change

The rulings are the operator's; the consequence column is [AGENT]
implementation of them. In particular, the sequencing reading of (3) and
the record-weight details of (6) are the orchestrator's interpretation and
are open to correction.

| # | Ruling | Consequence |
|---|---|---|
| 1 | WP1 lands as a decision record only | The WP1 execution decision, its independent review and the review response land with L0 as documents, each with a banner. WP1's shared-Lem factoring, experiment block, tests, probes and evidence directory stay on `arc/sc-wp1` as a record. M2 is closed by not landing the code. S1 starts from then-current mainline and builds one stepper in shared Lem, reviewed on its own contract. |
| 2 | Mirror upstream and refuse loudly | S1 keeps upstream's positional fork-result order and upstream's `subst_wait_stack ==> Stack_cons2` refusal. Where SC execution reaches that refusal it is a loud, classified "unsupported" outcome, never a silent result. No tray draft, `shared-model-fix` row or divergence is prepared. M1 is closed. The WP1 adapter's Lean-local fork/join repairs are not carried forward. |
| 3 | Coordination counterproposal accepted, amended | The counterproposal's rules stand, minus its paragraph assuming S1 starts with a fork/wait divergence. Sequencing: the main-line track's bug hunt goes first; S1 implementation that touches shared surfaces waits for it to finish or for an announced, non-overlapping claim. |
| 4 | L0 lands on mainline | `SC-CONCURRENCY.md` and its supporting records land (subject to the pre-merge audit and a per-merge sign-off). |
| 5 | One fresh review, inside the pre-merge audit | No separate re-review of `186392a53`. The L0 pre-merge audit includes a fresh full review of the revised plan and the landed WP1 decision record by a reviewer who authored none of it. |
| 6 | Lighter records, plain summary | The plan opens with a plain-language summary; house jargon is replaced or defined. Per-slice records are one short acceptance record per landing (the plan's §4 item 2 list), not record/response/re-response chains; evidence dumps stay on the slice branch unless a gate reads them. |

## 4. Follow-up ruling: scope of the 2026-09-04 brief constraint

The L0 pre-merge audit (S3) noted that S1 must add shared-`.lem` code while
the [USER 2026-09-04] brief constraint "we don't change the lem structure
for ocaml" (typed-failure outcomes design §0) was the condition behind M2.
[AGENT] asked whether that constraint was scoped to features upstream
already supports. [USER 2026-09-29], verbatim:

> yes, this is specifically about features that the ocaml upstream
> currently supports, i.e we don't bend the existing trust story. But for SC
> we have to change things because there's no upstream support

Consequence [AGENT]: new SC semantics may live in shared `.lem`; behaviour
of features upstream supports must not change, and refactors of existing
definitions must be behaviour-preserving and shown to be (the existing
differential lanes are the evidence). Recorded in SC-CONCURRENCY.md
constraint 1.

L0 landed on mainline at `d47e8f282` and the audit record at `5ce3d589b`
([USER 2026-09-29] sign-off: "1: yes, 2: yes land it"). Nothing is pushed
by this record.
