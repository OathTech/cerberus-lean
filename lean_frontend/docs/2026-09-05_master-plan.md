# Master plan — cerberus-lean and lem-lean

**Revision 9, 2026-09-06 [AGENT orchestrator-directed].** Landing preparation
of the validation-foundations arc
([record](2026-09-06_validation-foundations-landing-prep.md)). Two changes,
both operator-ruled [USER 2026-09-06]: (1) a new §0 "Operator rulings carried
verbatim" collects every [USER] ruling this plan rests on, so that no revision
can drop them again ("Re master plan revisions dropping rulings - yes, this
should be retained"); (2) §3 "Priority order" is REPLACED by the response §4
order — this order IS the response §4 order, reconfirmed [USER 2026-09-06]
("we should stabilize the core semantics before this, so we should revert to our previous ordering") — updated only for what is now done. Revision 8's factual state
sections (§1, §2, §4–§8) are kept as they were; nothing below is deleted; the
concurrency integration charter stays a proposal, sequenced after the
stable-profile claim (§3 step 8).

**Revision 8, 2026-09-06.** Updated by Codex [AGENT] at the operator's
request following the
[customer-readiness assessment](2026-09-05_customer-readiness-assessment.md).
Revision 8 records the [fresh document review and corrections](2026-09-06_validation-foundations-document-review.md).
It found one material fuel-correspondence overclaim and three minor issues,
corrected without implementation or gate changes. The user's conditional
merge authorization required no major findings, so landing awaits a renewed
decision. Revision 7 recorded the [audit repairs and revalidation](2026-09-06_validation-foundations-audit-repairs.md):
all eleven findings have implemented repairs and checks, and the functional
candidate completed its full battery, cold provider/failure work and affected
reporting measurements. Discuss landing before scoped SC integration.
Revision 6 recorded the first audit's hold; revision 5 recorded the original
delivery. Those dated measurements remain preserved.
This revision preserves the adopted decision boundaries. Revisions 3–8 had
superseded revision 2's sequencing (the order in
[the audit response, section 4](2026-09-05_whole-project-audit-response.md));
revision 9 withdraws that: the §3 order IS the response §4 order, reconfirmed
[USER 2026-09-06] ("we should stabilize the core semantics before this, so we should revert to our previous ordering").
Historical evidence and [USER] rulings remain in those records. Agent
recommendations below are not new operator rulings.

**Direction:** retain the shared Lem model and the executable Cerberus
semantics as the product. Prioritize trustworthy observations, explicit
failure behavior, usable proof contracts, and a scoped concurrency landing.
The verification logic stays in refined-cerberus. Improve upstream
reviewability after the relevant semantics and interfaces settle.

The adopted first execution charter is
[Validation foundations](2026-09-05_validation-foundations-charter.md).
Its [original delivery record](2026-09-06_validation-foundations-delivery.md)
supplies the historical acceptance table and measurements. The [scoped concurrency integration charter](2026-09-06_concurrency-integration-charter.md)
remains a PROPOSAL, sequenced at §3 step 8 (after the stable-profile claim)
per [USER 2026-09-06].
The first audit, repairing-agent second pass and fresh document review are
complete. The failure design, next charter and landing remain decisions for
the end-of-charter discussion. The latest conditional landing authorization
and the reason for holding the merge are recorded in the document review.

## 0. Operator rulings carried verbatim

Added in revision 9 so that the rulings this plan rests on travel with it
([USER 2026-09-06]: "Re master plan revisions dropping rulings - yes, this
should be retained"). Quotes are verbatim; interpretations are [AGENT] and
live in the cited records.

**[USER 2026-09-05]** — the whole-project audit rulings, asked as four
decisions plus two yes/no items, quoted from
[the audit response §3](2026-09-05_whole-project-audit-response.md):

> "(1) agree, the aim should be to provide the most faithful C
> semantics, per the intent of the authors, (2) unsure, this feels like
> it does touch the trust surface because it increases the gap between
> 'obviously right' and what Lean does. Is there a route where we prove
> the two are equivalent? (3) agree on the first, and the second depends
> on how the refined-cerberus project evolves, (4) I think you're right,
> the matrix may come later but for now we mostly inherit trust from
> Cerberus-upstream
>
> yes on the two other items"

Interpretation [AGENT], response §3 items 1–5: F1 is read kind-1 (the
authors' intent is the referent); P2 pure-failure lifting is NOT authorized
as proposed — the correspondence route (mirror stays the reference; checked
twin behind a per-function kernel-checked connection theorem) with a design
note before any dispatch; F9 consumer adoption IS a release exit; F10
release-profile statement yes, standards matrix later; land the audit and
run the P0 instrument slice.

**[USER 2026-09-06]** — the validation-foundations landing rulings (evidence
archives, concurrency ordering, retained rulings):

> "Agree on all points, and particularly on cleaning up the evidence archives. These should not be git committed, and will not be pushed. I don't actually hold strong value in such data which could be recreated, so I am fine dropping large files like this. The important thing is that runs can be reconstructed. Re ordering of concurrency, I think we should stabilize the core semantics before this, so we should revert to our previous ordering. Re master plan revisions dropping rulings - yes, this should be retained."

Consequences: the evidence archives are dropped from the repository with
identities retained and runs reconstructible
([landing record](2026-09-06_validation-foundations-landing-prep.md)); §3 is
the response §4 order again; this §0 exists.

**[USER], earlier, already verbatim in this file:** the legacy-run
instruction and the execution instruction (§1); the gcc-oracle gate ruling
[USER 2026-09-02] and the Q1b tolerance [USER 2026-08-31] live in
`scripts/LADDER.md` / `scripts/fork_drift_manifest.txt` respectively.

## 1. Starting point and ownership

| Component | Assessed state | Consequence |
|---|---|---|
| Cerberus mainline | `89f7e6885`; P0 instruments landed; fuel C4 at `56b3c9e90` | Preserve the repaired fuel checker, whole-Defined main extractor, and fork prerequisite checks. |
| Lem and Cerberus pins | `f6542f8`; installed compiler, pinned worktree and all three checked Lake manifests agree | The two-repo invariant is closed; maintain it through functional pin changes. |
| Fuel contracts | 81 workers: 54 measured, 13 kill-at-zero, eight reachable pending, six outside the checked entry cone; seven measured hypotheses | Quantification is delivered. Completion, propagation and sufficiency remain distinct obligations. |
| Runtime maps | Pmap insertion/lookup laws and structurally computing map/set `join` with correspondence proofs delivered | Provide these to the customer; do not schedule their implementation again. |
| Concurrency prototype | `feature/concurrency` at `086d8762d`, through S7; below current mainline | Historical globals-race and `apply_tree` restatement fixes exist. Repair remaining issues and audit the integrated candidate. |
| First customer | refined-cerberus's assessed main semantics pin is `f95ef8d9c` | Its agent owns re-pinning and proof migration. Providers owe interfaces, manifests and reusable semantic lemmas. |
| Legacy csmith run | Another agent's existing run and worktree | Outside our active queue until completion. |

These revisions anchor the assessment, not future implementation branches.
Recheck source heads before beginning a charter. Fresh assessment checks
covered the Cerberus unit suite/minimal baseline, Lem's nine non-Lean
emitters, and the prototype's 30-row litmus lane. The litmus abnormal-exit
hole was also reproduced. None certifies a future integration head.

**Legacy-run instruction [USER], verbatim:**

> "That csmith run is a legacy run in another agent, leave it alone until it completes"

Do not monitor, interrupt, restart, duplicate, diagnose, rebaseline or clean
up that run or its worktree while active. Its agent retains ownership.
After completion, incorporate the owner's final record as historical
evidence. This is not the first task in our queue and does not block
unrelated work. Later candidate measurements are separately scoped jobs.

**Execution instruction [USER]:** charters should be ambitious and run
long-cycle, with critical decisions resolved up front or kept to the end;
agents resolve non-critical choices. Build on worktrees, using paired Lem
worktrees if needed. Landing on main requires discussion with the operator.

## 2. Outcomes and release claims

| Outcome | Required claim | Outside that claim |
|---|---|---|
| Supported sequential release | A stated C/Core profile, trustworthy verdicts/proof definitions, explicit preconditions, reproducible artifacts, and green consumer adoption | General weak memory, optional filesystem support, universal ISO conformance |
| Scoped SC feature landing | Explicit selector; correct behavior or attributed refusal in its domain; repaired instruments; reviewed compatibility and consumer obligations | Arbitrary pthread code, non-SC orders, fences, RC11, Linux memory ordering |
| Upstream submission readiness | Reviewable Cerberus/Lem series, promised legacy compatibility, coherent declarations/manual, reproducible reports | Completion of every optional feature and compiler cleanup |

The release profile distinguishes supported behavior, loud refusals,
inherited upstream defects and open port bugs. A registered bug is not a
supported capability. A narrower profile needs an enforced restriction or
an explicit theorem precondition; a quiet wrong answer cannot be excluded
by a documentation label alone.

Shared source, no added axioms, fork-oracle parity, upstream compatibility,
and a consumer theorem are different assurances. Each needs its own
evidence. Preserve the aims and exception classes in
[VALIDATION.md](../VALIDATION.md).

## 3. Priority order

This order IS the [audit response §4](2026-09-05_whole-project-audit-response.md)
order, reconfirmed [USER 2026-09-06]: "we should stabilize the core semantics before this, so we should revert to our previous ordering". Revisions 3–8 had moved scoped SC
concurrency ahead of the stability work; that reordering is withdrawn.
Dependencies remain the actual blockers; owners name repositories; this
table does not dispatch agents.

**DONE — do not reschedule:** P0 instruments (landed `0a62dd7f7`: F4 locale +
fail-open + order-only manifest re-sort + stale metadata, the F2 checker, the
F3 Defined-line widening). On the validation-foundations landing candidate
(`arc/validation-foundations-land`, [record](2026-09-06_validation-foundations-landing-prep.md)):
the observation codec and complete-capture callers
([contract](2026-09-05_observation-contract.md)), the F5 pristine-oracle lane
(Tier B row 10, [record](2026-09-06_independent-oracle-and-fork-pins.md)),
the fork content pins (`[source-content]`), the release runner
(`scripts/release.py`, membership from `scripts/LADDER.md`), the
[supported profile](2026-09-06_supported-profile.md) and the
[failure census](2026-09-06_failure-census-and-correspondence.md).

| # | Deliverable | Owner | Dependencies and exit |
|---|---|---|---|
| 1 | Risk-map BASELINE by an independent auditor — now | Cerberus (independent auditor, not the implementing agents) | Baseline point 2026-08-31 (the semantics-first split); per trust surface: moved/unmoved · evidence · residual risk · mover. Repeated at step 7. |
| 2 | Pure-failure CORRESPONDENCE design note | Lem + Cerberus | Input: the census's proposal. The mirror stays the reference model; a checked twin sits behind a per-function kernel-checked connection theorem (the fuel-sufficiency pattern). Reviewed WITH the operator before any dispatch. It fixes the failure vocabulary for step 3. |
| 3 | lem L1 declare consolidation ∥ cerberus C-TF1 monadic seam slice | Lem ∥ Cerberus | After the step-2 note fixes the failure vocabulary. |
| 4 | C-Z4 remainder | Cerberus | Probe integration, ci_sweep re-record, cerb_skip ceiling, libc-body UB-loc mover, Z2-J fixes, R3 marker, the owed tray drafts, the batchEscape per-byte fix. |
| 5 | Bytes (L4) + F7 instances + the fuel residue | Lem + Cerberus | F7: hash-minted symbols, enum registry, digest; the eight fuel-residue rows (§1). Submission track in parallel. |
| 6 | Consumer adoption exit | refined-cerberus's agent + providers | refined-cerberus re-pin + proofs through against the current interface (F9 is a release exit, [USER 2026-09-05], §0). |
| 7 | Risk map REPEAT → fresh-noodler exit test → stable-profile claim | Cerberus + Lem | Instruments and semantics settled; §8 exits met. |
| 8 | ONLY THEN: scoped SC concurrency integration | Cerberus | The [charter](2026-09-06_concurrency-integration-charter.md) stays a PROPOSAL until step 7 is met; the merge comes through the orchestrator's pre-merge audit + per-merge sign-off; `arc/validation-foundations-concurrency` is portable commits for this step, not a landing candidate. §5 below is the exit checklist when the step is reached. |
| Submission track (L7) | Declare consolidation, manual and patch series | Lem + Cerberus | In parallel with steps 5–7; failure vocabulary from step 2. |

**Current handoff (revision 9, updated 2026-09-07):** the validation-
foundations candidate LANDED — ff-merge `arc/validation-foundations-land`
→ `mdd/cerberus-lean` `a3b5d169d` on the orchestrator's full battery
([record §11](2026-09-06_validation-foundations-landing-prep.md)) and the
operator's per-merge sign-off ([USER 2026-09-07]: "(1) codex is working in
other trees, this is safe, (2) agree, audit done, (3) go ahead and merge").
Next: step 1 (the risk-map baseline by an independent auditor). Open
housekeeping: the Codex worktree's scratch and nested worktree
registrations, and the fate of the archive-bearing branch
`arc/validation-foundations` (operator's call).

**Current handoff (revision 8, retained as history; its "scoped concurrency
integration remains the recommended next implementation charter" is
withdrawn by revision 9):** decide landing of the corrected validation-foundations
candidate following the fresh document review. Its functional primary is `de9f6d3612232d581622afcdf0b23cdaf31fa09d`; the older feature-base
instrument companion is `86a2aea547804b78eb7f1eae633bb9c24c713b7f`. The
[repair record](2026-09-06_validation-foundations-audit-repairs.md) supplies
current results and evidence, including the intentionally interrupted first
attempt. Priorities 1–2 and the bounded census/provider work are implemented
and measured; the fresh review's documentary findings are corrected, with
the landing decision pending. After that,
scoped concurrency integration remains the recommended next implementation
charter; review the failure design with that entry decision. Its broader
implementation remains separate unless a concrete proof dependency requires
a bounded slice first. Neither milestone declares a stable release.

## 4. Sequential semantics and backend work

### 4.1 Profile, risk map and evidence

Use the assessment as input to the independently reviewed risk map already
requested in the audit response. Compare against 2026-08-31 across oracle,
execution, definitions, trust base, gates and consumer interface. Each row
names the change, its evidence, residual risk and the task that removes it.
Repeat the review after the semantic changes.

The audit archive now has an explicit inventory: ten original files match
their historical hashes; twelve original logs remain missing. Current links
and checksums cover the files actually retained. New reproductions have their
own dates and source identities. Maintain that separation and reconcile
overview/TODO claims at each semantic checkpoint. This never licenses
inspection of the excluded legacy run or its scratch files.

### 4.2 Observations and independent oracles

The validation-foundations instruments deliver this contract. Maintain it
through subsequent semantic changes; the delivery record separates passing
comparisons, expected reference defects and unavailable release exits.

Share a byte-preserving verdict codec across `test_exec.sh`,
`test_gcc_oracle.sh`, `test_ci_sweep.sh`, `test_cn_coverage.sh`,
`test_multi_tu.sh`, `test_verify.sh`, and concurrency. Preserve values,
stdout/stderr, UB code/location, blocked state and exit classification.
Specify sequence, multiplicity or set projection per lane. Litmus reference
outcome sets remain separate from the full Lean-versus-OCaml comparison.

Acceptance includes same-value/different-byte plants, NUL/high bytes,
escaping, multiple outcomes, truncated output, verdict-then-timeout/kill,
and expected semantic nonzero exits. Migrate lane by lane; triage newly
visible differences before baseline updates. Trace producers of
`Main.batchEscape` inputs before changing its encoding assumptions.

Maintain pristine-upstream versus fork-OCaml execution over applicable Tier A
inputs and representative legacy CLI/library interfaces. Keep fork-OCaml
versus Lean separate. Identify both source/compiler/runtime builds and
intentional deltas. Independently establish pristine toolchain provenance:
regenerating both models with fork Lem alone does not prove upstream-Lem
compatibility.

Content-pin hand-written oracle changes, including fresh supply, renumbering,
driver and relevant build/runtime surfaces; plant a change inside an
already-listed file. Preserve P0's locale, duplicate and prerequisite fixes.
Retain reviewed OCaml compensation unless a separate justified change
removes it.

Maintain the delivered executable release runner derived from LADDER,
including per-lane status, source/binary identity, required/reporting status
and explicit incomplete/skip results. Its CI entry runs the same catalogue.
Preserve complete diagnostic evidence; a completion marker is not a passing
gate. Revalidate this instrument when its callers or protocol change.

### 4.3 Failure semantics

The [completed census and probes](2026-09-06_failure-census-and-correspondence.md)
trace unused lets/arguments, projections, ignored results and callbacks, and
connect `hack`/`finalize`, `to_pure(s)` and parser combinators to their remaining
obligations. It distinguishes demonstrated Lem mechanisms, C-triggered
failures, dependency closures and unresolved branch reachability. Use that
record rather than restarting the sampled census or assuming unreachability.

Retain the mirror as reference. For any proposed explicit-failure worker,
require success preservation and a strict failure account in addition to
`f_exc xs = .ok v → f xs = v`: an always-failing worker satisfies that
one-way theorem. Explain which directions are kernel-checked and which
remain differential evidence. The mirror cannot express an exception its
own reduction erases. Review the design with the operator before the larger
transformation, as required by the existing audit-response ruling.

After the failure vocabulary is reviewed, carry the seven hand-written
`memM` failures through its existing result channel with the faithful failure
alternative and establish propagation through the driver. Preserve remaining
pure sites in the census and implement the obligations in the current
[correspondence proposal](2026-09-06_failure-census-and-correspondence.md).
`panic!` to `failwithI` is interim hygiene, not pure-failure closure.

Freeze the failure vocabulary after review, then use it inside Lem's
consolidated declaration machinery. The old 59-plus-five monadic census
was a sample: the [current census](2026-09-06_failure-census-and-correspondence.md)
finds 77 sites in those nine modules and 263 across the whole generated tree,
with dependency and channel classifications kept separate. Eight sites in
those nine modules use non-`t0` `core_run_cause`; frontend `errorM` already
carries a location but needs an appropriate failure alternative. Do not
misclassify missing failure vocabulary as the absence of any location field. Pure `hack`/`finalize` cannot be repaired by
adding a monadic annotation elsewhere.

### 4.4 Bytes, state and fuel

| Work | Scope and acceptance |
|---|---|
| Lem byte strings/chars | Implement the existing byte-representation design; remove the two string bug XFAILs. Cover all char bytes, invalid UTF-8, NUL, indexing, comparison and concatenation; make text conversion explicit; rerun affected Cerberus/consumer checks. |
| Enum, digest and symbols | Carry enum interpretation/TU digest as data; intern Core-text symbols from explicit supply. Provide needed kernel equations and reentrant/reordered/repeated-call tests; remove retired native/opaque machinery. |
| Configuration and remaining interfaces | After concurrency lands, parameterize supported configuration/switch choices. Review single-trace selection, MemValue equality and opaque no-op shims against the actual consumer contract. |
| Checked tag environments | Validator with `check = true → Acyclic`, or proved frontend invariant, including linking/renaming where used. Discharge `AcyclicPair` and formatting's `2 ≤ b` honestly at actual entries. |
| Fuel contracts | Distinguish no invented success, stability of completed observations at greater fuel, and sufficient budgets. Prove required properties per family before generalizing the generator; more fuel may resolve exhausted ND branches. |
| Backend refusal | Refuse explicit `target_rep` spelled `sorry` after removing dead consumer declarations, including concurrency's cleanup. A downstream token gate is not a guarantee for every Lem client. |

The eight reachable pending workers have separate routes:

| Workers | Required route |
|---|---|
| `are_compatible_aux` and two siblings | Prepare an upstream recursive cross-TU compatibility remedy with positive/negative tests. By-value acyclicity does not suffice. A local shared-model fix needs the existing explicit ruling; otherwise preserve the upstream-defect entry without claiming support for those cases. |
| `hack` | Pure evaluation/finalization failure contract; no fabricated successful sentinel. |
| `many`, `many1` | Input progress/bounds or explicit exhaustion distinguished from ordinary parse failure, using the reviewed failure design where needed. |
| `to_pure`, `to_pures` | Resolve failure-dependent recursion arguments with proved preconditions or the reviewed representation, then discharge sufficiency. |

Finish Z4's remaining work: integrate recorded noodle/audit probes, add the
appropriate `PINNED_TRAY_<n>` GCC classification, enforce skip accounting,
preserve libc-body UB locations, close Z2-J bridge issues, and finish R3's
marker/register correspondence. Use the [completed CI re-record](2026-09-06_ci-reporting-results.md) as
current evidence: one libc UB-location difference, three filesystem refusals
and three Lean timeouts remain explicit. Preserve its historical scoreboards
separately and remeasure after relevant semantic changes. Keep Z-40's elaboration filter, per-row timeout evidence and
stale source cites attached to their existing backlog entries.

## 5. Concurrency repair and landing

Phase 0 landing is a near-term deliverable. The S7 fixes and corpus are
valuable but do not replace these exit checks:

1. Prepare an integration copy at an identified current mainline. Preserve
   C4 hypotheses/P0 instruments, S7's initialization ordering and original
   `apply_tree` bodies with measure proofs. Resolve tray draft 36's collision
   and refresh manifests/census claims. Do not overwrite its owner's tree.
2. Preserve the delivered CR-1 repair: capture both original engine statuses,
   including the sequential refusal leg. The private instrument series closes
   the negated-command status loss and ignored oracle status.
   The [assessment probe](2026-09-05_litmus-exit-status-probe.py) must continue
   rejecting all four plants after integration. Preserve the 26 integrated
   plants and full observation parity alongside reference outcome sets.
3. Repair or enforce a narrower checked domain for mixed-size overlapping
   accesses and SeqRMW sequencing. The mixed-size case is a recorded quiet
   wrong answer in the advertised fragment; a Phase-1 TODO does not close it.
   Test dynamic accesses as well as the syntactic memory-order scan.
4. Discharge the accepted consumer agreement obligation: verdict observations
   under `epar_free`, `sc_fragment_ok`, valid initial state, appropriate fuel
   conditions and any necessary domain restrictions. Prove single-thread SC
   consistency and silent race checks. Literal state equality is false; the
   six identity lemmas do not suffice. This is provider work. Any proposed
   experimental landing without that guarantee needs an explicit end-of-work
   decision, not silent transfer of the obligation to refined-cerberus.
5. Audit compatibility and the whole final delta. Default mode now refuses
   parallel spawn; compare-exchange gains sequential behavior. Name and test
   these intentional changes. Shared semantic changes follow the approved
   concurrency charter; Lean-plumbing-only body rewrites remain excluded.
6. Regenerate and validate the exact candidate: cache-disabled rebuilds where
   required, full Tier A+B, litmus checks/plants, applicable candidate reporting
   evidence and consumer-shaped proofs. Bring the candidate, review findings
   and consumer manifest to the operator for the landing discussion; ff-only.

Integration preparation can proceed once the relevant instruments are ready.
Do not make general failure lifting or byte migration dependencies without
concrete evidence. An SC landing does not itself declare the entire product
stable. Weak memory, symbolic reads, RC11 and LKMM remain future scoped work.

## 6. Consumer, performance and upstream work

Use named integration checkpoints rather than asking refined-cerberus to
chase every provider commit. Supply C1–C4/map/config manifests and precise
selector/error/step changes for concurrency. Its agent owns re-pinning,
`[LemFuel]` restatements, environment hypotheses and its full proof gate.
Providers own defects and reusable semantic/map lemmas. Adoption of the final
release candidate is an exit; old green proofs at `f95ef8d9c` do not meet it.
Its E5/E6/E7 implementation and C-example scope are not assigned here.

The [cold provider recipe](2026-09-06_provider-smoke.md) and adoption manifest
now record generation, copy manifests, native objects, all three package pins
and the actual compiler/runtime. Its external client proves completion of a
fixed closed Core fixture and a shipped map law. Repeat this unprimed check
for future semantic candidates; customer adoption and a broader proof profile
remain separate exits. Preserve checks on Cerberus Lean 4.32.2 and standalone
Lem's declared toolchain.

At an agreed candidate checkpoint, measure CPU, wall time, RSS and completion
against the relevant pre-measure baseline. One row's ~7% overhead does not
establish aggregate <10% cost. Prefer cheaper proved-sufficient measures
where evidence warrants them. Run-loop rendering, stack behavior and memory
representation remain real work subject to existing design rulings; avoid
heartbeat increases, arbitrary budgets and unreviewed representation changes.
This future campaign does not take over the legacy run.

After reviewing the failure vocabulary, consolidate Lem's
termination/ambient/consumer/supply/representation forms and rewrite the
manual around them. Preserve non-Lean goldens, mixed-target/reentrancy checks
and consumer-relevant behavior. Enumerate intentional Lean signature/text
changes rather than promising byte identity for a representation change.
Consolidation serves the upstream series; syntax cleanup alone does not earn
a stable semantics claim. Preserve the existing [USER 2026-09-04]
before-stable expectation for declaration consolidation; distinguishing a
scoped customer checkpoint from upstream readiness does not waive it.

Prepare the owed `_Alignas`, recursive `are_compatible` and empty-execution
reports; reconcile concurrency drafts and preserve `mk_conv_int`. Finish
Lean/Lem reproducer preparation and reviewable patch series. Filing/pushing
remain separate operator actions.

## 7. Retained backlog and crosswalk

Keep Pset/remove/bindings laws, qualified constructor rendering, library-name
entanglement, emission-state refactoring, Ott artifacts, remaining kernel
reduction obstacles and small diagnostics/library issues visible. Promote
them when a supported behavior, consumer proof, reproducible build or
upstream submission needs them.

Frontend totality beyond the execution slice, large-memory representation,
real CerbFS and general weak memory need scoped designs. Do not revive parked
reasoning/prototype branches to solve them.

| Earlier IDs | Current location |
|---|---|
| C-RM, audit F10 | Sections 2, 4.1, 8 |
| P0 remainder, C-Z4, audit F3–F5 | Sections 4.1–4.2, end of 4.4; legacy run externally owned |
| C-TF1, L2, audit F1/F8 | Sections 4.3–4.4 |
| Concurrency | Section 5 |
| L4, C-A2, C-B/C-C and remaining reasoning-artifact instances | Section 4.4 |
| L3 and pending fuel | Section 4.4 |
| C-P1, L8, Z-29/Z-30 resources | Section 6; existing design/parking decisions preserved |
| Consumer adoption, audit F9 | Section 6 |
| L1, L7 | Section 6 consolidation/submission |
| L5, L6, other small Lem TODOs | Section 7 |
| C-N2 | Section 8 |

## 8. Release exits and decision boundaries

A supported release requires, on identified revisions:

1. A reviewed profile with evidence for each claim. Known port defects in
   its domain are fixed or excluded by checked restrictions/preconditions;
   inherited upstream defects stay separately identified.
2. Complete required validation with trustworthy instruments, coherent pins,
   fresh artifacts, triaged movement and explicit skip/resource accounting.
   Reporting results do not become exhaustive conformance claims.
3. No reachable invented success on certified entries. Required failure,
   fuel and environment contracts are proved or explicit theorem preconditions.
   Merely listing opaque failure as pending does not satisfy this exit.
4. Clean reproducible consumption and actual refined-cerberus adoption of
   the final candidate with proofs through.
5. Repeated risk review and the already-requested fresh adversarial convergence
   exercise after the instruments and semantics settle. New findings reopen
   their work packages; zero findings remains evidence, not universal proof.

SC additionally meets section 5; upstream submission additionally meets
section 6. Report these as distinct milestones.

Unresolved critical boundaries are the pure-failure design before its larger
transform, any relaxation of the accepted concurrency agreement obligation,
and a local shared-model compatibility repair. Prepare evidence and concrete
proposals before asking for these decisions. Routine implementation choices
stay with the agent. Each charter produces a reviewable branch and final
report; landing on main is discussed with the operator.

This file carries current ordering/ownership; TODOs retain detailed residuals
and dated records retain evidence. Close work packages with exact validation
records. Future readers should not need to combine obsolete work orders.
