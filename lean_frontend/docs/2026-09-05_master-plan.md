# Master plan — cerberus-lean and lem-lean

**Revision 10, 2026-09-16 [AGENT orchestrator-directed].** Requested [USER
2026-09-16]: "Great, let's update the master plan based on the audit result and
recent work". Since revision 9 the mainline moved `a3b5d169d` → `15907f32b`
through eleven landings, each ff-only on a per-merge sign-off (§0 lists them),
including the [whole-project semantics audit of 2026-09-11](2026-09-11_whole-project-semantics-audit.md)
and its two repair slices ([record](2026-09-11_semantics-audit-repairs-record.md),
[record](2026-09-11_parser-progress-measure-record.md)), both independently
audited before landing. Changes in this revision: (1) §0 gains every [USER]
ruling of 2026-09-07 → 2026-09-16, verbatim; (2) §1 gains a "state at revision
10" table beside the assessment table; (3) §3 gains a DONE list, a revision-10
status table (the revision-9 table is retained beneath it), two new entries —
the agreed structural-outcome-constructors design (D2) and the open
checked-input-boundary decision (D4) — and a new handoff; (4) §4 gains 4.5, the
audit and its repairs, and addenda to 4.3/4.4; (5) §6 gains the consumer re-pin
note and the tray filing state; (6) §7 gains the sixteen-finding crosswalk; (7)
§8 gains the exit status. Nothing below is deleted. The §3 order is UNCHANGED:
core semantics before scoped SC concurrency ([USER 2026-09-06]).
Landed [USER 2026-09-16]: "Great, land Revision 10, then work on D2's design" —
the pre-merge audit ask was made (a subagent audit waived in favour of the
operator's own read, as proposed); ff-only onto `mdd/cerberus-lean`, no push.

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

**[USER 2026-09-07 → 2026-09-16]** — the rulings of the eleven landings and
the audit follow-through, verbatim (interpretations [AGENT] live in the cited
records):

- 2026-09-07, validation-foundations landing: "(1) codex is working in other
  trees, this is safe, (2) agree, audit done, (3) go ahead and merge". Risk-map
  baseline landing: "Great, merge it". Census + parked correspondence design:
  "merge the two branches". Option C dispatch: "create a branch and send a
  worker to do option C".
- 2026-09-08, fuel-pending close-out: "if it's safe, you can land it".
  Fuel-measure-cost: "add the review to the worktree with any required
  improvements before merging". C-TF1 and (2026-09-09) ND fuel stability: "if
  ready with small fixes, make the fixes and land it".
- 2026-09-10, the `are_compatible_aux` shared lem BODY change (the first
  shared-model change since the split): "Agreed with all of this. It sounds
  like this is actually a more regular design than the current lem? I.e we use
  the same mechanism as elsewhere in the cerberus design? In that case, go
  ahead with the charter, and I'll get codex to work on it". Its landing,
  2026-09-11: "Great, let's land it as is, as you suggest".
- 2026-09-11, on the orchestrator's review of the whole-project semantics audit
  and its four decisions (D1 the shared lem fix of the array-bound typo; D2
  structural outcome constructors replacing the two opaque location atoms; D3
  the route for the last two fuel-pending workers; D4 a checked semantic input
  boundary as the shape of the stable-profile claim): "Let's charter the work
  on next steps 2 and 3 above as one slice of work. D1: approved, D2: agree,
  D3: explain the choice? D4: I don't know what this is asking". After the D3
  explanation (shared lem body restatement over a backend hoist or permanent
  register rows): "D3 agree. Go ahead". On execution: "in this case you should
  launch them as claude fable class subagents. Can you do that? We want to keep
  in control of this bit of the work". On sequencing: "Once this lands, you can
  make a new worktree and charter the parser work".
- 2026-09-15, the row-106 ruling (a hexadecimal literal the OCaml runtime
  rounds twice; C11 §6.4.4.2#3 requires correct rounding): "Great, agree on
  your recommendation. Go ahead with the worker" — ISO-fix register **R5**
  ADMITTED (VALIDATION §2). The repair slice's audit: "Great, launch the audit
  as proposed." Its merge: "merge it".
- 2026-09-16, the parser slice's audit: "Go ahead with the audit as proposed".
  Its merge: "Great, merge it. Then update me on what's next". This revision:
  "Great, let's update the master plan based on the audit result and recent
  work".

Interpretation [AGENT], recorded in the charters and records cited in §3/§4.5:
D1 and D3 are executed and landed; D2 is AGREED and not yet chartered (§3 step
5b); D4 is OPEN (§3 step 7). The execution mode for the audit-repair slices —
a Claude Fable subagent in fresh context reading the charter as the worker,
the orchestrator re-verifying every gate at the boundary, the unconditional
pre-merge audit ask, ff-only merge on per-merge sign-off — is the operator's
choice for "this bit of the work", not a standing rule for all slices.

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

**State at revision 10 (2026-09-16)** — measured on the mainline `15907f32b`
(the assessment table above is retained as the revision-8 baseline):

| Component | State at `15907f32b` | Consequence |
|---|---|---|
| Cerberus mainline | `15907f32b`; primary checkout rebuilt and driver-fresh; no slice in flight | Every worktree primed from here starts current; `scripts/new-worktree.sh` now carries the driver-freshness stamps |
| Lem and Cerberus pins | `f6542f8` = lem mainline `mdd/lean-backend` = opam pin = all Lake pins; no functional lem arc since | The two-repo invariant is closed; the lem L1 declare consolidation (§3 step 3) has not started |
| Fuel contracts | 81 workers: **62 measured (12 under a hypothesis), 13 kill-at-zero, 0 pending, 6 outside the checked entry cone**; `scripts/fuel_forms_pending.txt` header-only | The (A)/(B)/(C) requirement is met for every reachable worker; propagation of exhaustion (lem TODO 13) and whole-driver composition remain distinct obligations |
| Failure semantics | 233 pure `panic!`/`failwithI` sites in the exec closure = the failure-reach register (48 REACHABLE, 17 UNKNOWN, 166 UNREACHABLE-BY-INVARIANT, 2 unresolved-owner; 0 DISCARDABLE); the seven `memM` fail-stops are typed ND kills (C-TF1) | The parked twin's tripwire is live; D2 (structural outcome constructors) is the agreed next design |
| ISO-fix register | R1, R2, R3, **R5** admitted; R4 deferred | The register/marker bijection gate is still owed (R3's marker) |
| Fork drift | layer 1 = 76 oracle-surface files; layer 2 = **24** hash-pinned generated deltas, three of them GENUINE shared-model changes (the `ctype_aux` accumulator 2026-09-10, the `ctype_aux` typo + `core_eval` compatibility consult 2026-09-15, the `monadic_parsing` restatement 2026-09-16), each tray-filed and each with zero movement in every lane | Upstream drafts 37–43 carry the deltas; filing is the operator's |
| Validation | LADDER = 36 commands (Tier A 14 rows incl. 4b/4c/6b, Tier B 22); every landing since revision 9 ran the full battery twice (worker + orchestrator) with zero existing-row movement; corpora: minimal 111, coverage 212, debug 90, float 93, immaculate 34, multi-TU 2 + tray 7, gcc lane 1,997 rows | The 2026-09-11 audit found two C-reachable execution discrepancies (both fixed): the fresh-noodler exit test (§8 exit 5) is NOT met |
| Concurrency prototype | `feature/concurrency` at `086d8762d`, unchanged, below mainline | §5 stands; §3 step 8 |
| First customer | refined-cerberus's pin is still `89f7e6885` (L2, 2026-09-07); no re-pin since | The re-pin to `15907f32b` is owed; §6 lists the signature changes it must absorb |
| Legacy csmith run | the [USER] instruction stands | untouched |

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

**DONE since revision 9 — do not reschedule** (mainline commits; each with its
record, its orchestrator battery and its per-merge sign-off in §0):
step 1 the risk-map BASELINE (`4d1088004`, 2026-09-07, all six surfaces
MOVED-WITH-RULING); step 2 the pure-failure reachability census (DISCARDABLE = 0
→ option C: no twin arc; the correspondence design PARKED with its tripwire
gate) (`94f339eb4`, 2026-09-07); step 3's Cerberus half C-TF1 (seven `memM`
fail-stops → typed ND kills, propagation lemmas) (`a4d5214e5`/`df7ca32fe`,
2026-09-08) — its lem half L1 is NOT done; the fuel-pending close-out
(`hack`/`to_pure`/`to_pures` measured under shape hypotheses; the failure-reach
register gate) (`6ccb607e0`, 2026-09-08); fuel-measure-cost (`get_ctx`'s
measure a named structural definition; +0.8 % CPU) (`69b490565`/`c24e78c66`,
2026-09-08); ND fuel stability (six-worker stability contracts)
(`7c8bbbd3a`/`679181d1b`, 2026-09-09); batch-diagnostic bytes (`86daea264`,
2026-09-10); `are_compatible_aux`'s assumed-compatible accumulator — the first
shared-model change, hypothesis-free measure, tray 37/38 (`e30810be7`,
2026-09-11); the [whole-project semantics audit](2026-09-11_whole-project-semantics-audit.md)
(`54f007187`, 2026-09-11) and its two repair slices — findings 3/4/5 + draft 38
+ R5 (`eaa2066e9`, 2026-09-15) and the `many`/`many1` restatement that emptied
the fuel-pending register (`15907f32b`, 2026-09-16) — see §4.5. Step 5's
fuel-residue rows are therefore ALL closed.

**Revision-10 status of the order** (the revision-9 table is retained below it,
unchanged; owners as there):

| # | Deliverable | Status at revision 10 | What remains / exit |
|---|---|---|---|
| 1 | Risk-map BASELINE | DONE 2026-09-07 | Repeat at step 7 |
| 2 | Pure-failure CORRESPONDENCE design | DONE 2026-09-07 as option C: census, parked twin, tripwire gate (`check_failure_reach.sh`) | The twin flips to live only on a DISCARDABLE-reachable site |
| 3 | lem L1 ∥ C-TF1 | C-TF1 DONE 2026-09-08; **lem L1 declare consolidation NOT started** | L1 moves to the submission track (needs the frozen failure vocabulary = after 5b) |
| 4 | C-Z4 remainder | PARTIAL: Z2-J-02 (bridge bytes) FIXED 2026-09-15; the `batchEscape` question RESOLVED 2026-09-10 (byte carriers stay byte-exact; only diagnostics are UTF-8); OPEN: R3's marker/register bijection gate, the libc-body UB-location mover (Z1-A1), probe integration, `ci_sweep` re-record, `cerb_skip` ceiling, Z2-J-01 (`EDecl_magic` fail-open, an oracle-surface tray item), the refusal census (37 `Illformed_program` sites, no register) | Bundle the open items into one hygiene slice; none blocks step 5 |
| 5 | Bytes (L4) + F7 instances + fuel residue | **Fuel residue DONE** (register empty 2026-09-16); the literal-content byte bridge FIXED 2026-09-15 (`json_of_bytes`, fail-closed importer) — the LemLib string REPRESENTATION (L4, the two parity XFAILs) is still OPEN; **F7 instances OPEN**: enum registry `IO.Ref`, native digest global, placeholder `BEq`/`Ord` instances (audit findings 2/11); TEXT-field non-UTF-8 residual (VALIDATION §3) | The next implementation charter(s): F7 (Cerberus) and L4 (Lem, same-name worktree pair) |
| 5b | **Structural outcome constructors (D2)** — exhaustion / unsupported feature / model failure / UB as constructors, replacing the two opaque location atoms `CerbFuel.fuelExhaustedLoc` / `CerbFail.modelFailStopLoc` | AGREED [USER 2026-09-11]; NOT chartered | A design note reviewed WITH the operator before dispatch (the step-2 rule); consumer-visible — its manifest goes to refined-cerberus; fixes the failure vocabulary that L1 consolidates |
| 6 | Consumer adoption exit | Re-pin OWED to `15907f32b` (signature changes in §6) | Their agent re-pins; provider answers interface questions; F9 is a release exit |
| 7 | Risk map REPEAT → fresh-noodler exit test → stable-profile claim | NOT met: the 2026-09-11 audit acted as a fresh adversarial pass and found two C-reachable execution discrepancies (both fixed) — the exit test reopens after step 5 with a LITERAL-LEVEL adversarial brief (long mantissas, raw high bytes, cross-TU aggregates); **D4 OPEN**: whether "stable profile" = the programs a decidable admissibility checker accepts (acyclic tags, arena shapes, configuration), with preservation lemmas, so consumers receive the measured helpers' hypotheses as evidence | Operator decision on D4 before the step-7 charter |
| 8 | Scoped SC concurrency | Unchanged; last | §5 exit checklist |
| Submission track | Tray: 43 drafts + `ocaml/01`; only draft 01 filed (issues/1009, 2026-08-19); 37–43 + `ocaml/01` carry the three shared-model deltas and R5 | Operator's network window; L1 + the manual after 5b |

**Current handoff (revision 10, 2026-09-16):** mainline `15907f32b`, primary
rebuilt and fresh, no slice in flight. Next, in order: (1) relay the consumer
re-pin note (§6); (2) the D2 design note (step 5b), reviewed with the operator
before any charter; (3) the step-5 charters — F7 instances (Cerberus) and L4
bytes (Lem + Cerberus pair); (4) the D4 decision; (5) the tray filing window.
Execution mode per §0's 2026-09-11 ruling for audit-repair work; other slices
as the operator directs at charter time.

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
| 3 | lem L1 declare consolidation ∥ cerberus C-TF1 monadic seam slice | Lem ∥ Cerberus | C-TF1 complete on `arc/monadic-failstop`: [implementation and 35/35 A+B command coverage](2026-09-08_monadic-failstop-record.md). Lem L1 retains its separate scope. |
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

C-TF1's seven hand-written `memM` failures now use the existing ND kill
channel, with kernel propagation contracts through bind, liftMem and the
runners, and an explicit crash-class observation record. The
[2026-09-08 execution record](2026-09-08_monadic-failstop-record.md) carries
scope, validation and landing status. This is independent of the
[parked pure-failure twin](2026-09-07_pure-failure-correspondence-design.md):
retain the pure sites and their failure-reach register; that larger
transformation still requires its own decision. `panic!` to `failwithI`
is interim hygiene, not pure-failure closure.

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

**4.3 addendum (revision 10).** R5 is admitted: a hexadecimal floating
literal with more than 53 significant bits and a subnormal value, which the
OCaml runtime's `caml_float_of_hex` rounds twice (`runtime/floats.c:355,369`)
where C11 §6.4.4.2#3, quoted verbatim from `tools/n1570.json`, requires
correct rounding; Lean keeps the correctly rounded value (`CerbFloat.lean`,
marker `-- ISO-fix register R5`), pinned Lean-right in the immaculate lane,
tray `ocaml/01` + 40. The failure VOCABULARY question is now D2 (§3 step 5b):
exhaustion, unsupported feature, model failure and UB as structural
constructors, replacing the two opaque `Loc` atoms that C-TF1 and the fuel arc
introduced — agreed [USER 2026-09-11], unchartered.

**4.4 addendum (revision 10).** The "eight reachable pending workers" table
above is CLOSED: the `ctype_aux` trio by the assumed-compatible accumulator
(shared model, 2026-09-10/11, hypothesis-free); `hack`/`to_pure`/`to_pures`
under the arena-shape hypotheses (2026-09-08); `many`/`many1` by the
input-indexed restatement `many_run`/`many1_run` (shared model, 2026-09-16),
measured under `CerbParserProgress.Consumes p`, a hypothesis that is a THEOREM
at all four printf call sites — the register `scripts/fuel_forms_pending.txt`
is header-only. Bytes: the literal-content bridge is fixed (2026-09-15); the
LemLib representation row stays open; a residual row (VALIDATION §3) records
that non-UTF-8 bytes in TEXT fields of the Cabs JSON make the bridge refuse
loudly where the oracle proceeds. "Checked tag environments" is now the D4
question (§3 step 7).

### 4.5 The whole-project semantics audit (2026-09-11) and its repairs

The [audit](2026-09-11_whole-project-semantics-audit.md) (an external agent,
read-only, at `e30810be7`) made sixteen findings; the orchestrator verified
every source claim and REPRODUCED its three concrete bugs before acting
(§7's crosswalk maps all sixteen). Two slices, both executed by Claude Fable
subagents under charters, both re-verified by the orchestrator's own full
battery and both audited by a fresh reviewer before landing:

- **Repairs** ([charter](2026-09-11_codex-charter-semantics-audit-repairs.md),
  [record](2026-09-11_semantics-audit-repairs-record.md),
  [audit](2026-09-15_semantics-audit-repairs-premerge-audit.md), landed
  `eaa2066e9`): (i) `CerbFloat.of_string` converts every C floating literal by
  exact `Nat` rounding to binary64 assembled with `Float.ofBits` — the audit's
  260-zero hexadecimal literal now reads 1 on both engines; a 24-row adversarial
  battery + 42 bit-pattern pins; R5 for the oracle's own subnormal defect. (ii)
  The Cabs bridge carries string-literal and character-constant bytes as one
  code point per byte (`json_of_bytes`), the importer rejects anything above
  255, a bridge probe runs in `test_parse.sh`, and the 106 pre-existing JSON
  outputs are byte-identical. (iii) The shared model: `ctype_aux.lem`'s array
  arm compares both bounds, and `core_eval.lem`'s `PEmemberof(struct)` guard
  consults `Ctype_aux.are_compatible` when tags differ — draft 38's reproducer
  runs to 7 on both fork engines, an incompatible pair is rejected on the
  return path, and seven cross-TU cases are pinned in `tests/multi_tu_tray/`
  (LADDER row 6b, under an opt-in failure-text symbol projection confined to
  that row). Two premises of the charter were WRONG and are errata there: the
  ISO clause (hex constants under a power-of-2 radix are correctly rounded; the
  "either adjacent value" latitude is decimal's) and the by-value ARGUMENT
  path (in the default switch set arguments travel as pointers to caller
  temporaries and no engine consults compatibility there — pinned as an
  observed modelling limit, not a defect). The audit's F2: an incompatible
  struct returned and then STORED is refused at the store-side consult as an
  uncaught failure — intended, pure-failure class, record-only. F3: the
  predicate ignores alignment specifiers (§6.2.7#1 requires them equivalent) —
  a pre-existing upstream gap, TODO + draft 39.
- **Parser progress measure** ([charter](2026-09-11_codex-charter-parser-progress-measure.md),
  [record](2026-09-11_parser-progress-measure-record.md),
  [audit](2026-09-16_parser-progress-measure-premerge-audit.md), landed
  `15907f32b`): described in the 4.4 addendum; the old and new workers are
  related by kernel theorems (hop-for-hop at every fuel under the one
  sentinel-agreement hypothesis the opaque sentinel makes undischargeable;
  unconditionally at fuel ≥ measure); seven `Formatted.*` heads and
  `many`/`many1` lose `[LemFuel]` (§6).

Rules the two slices taught, now binding on charters (recorded in their §7
errata): quote every ISO clause from `tools/n1570.json`, never from memory;
trial every negative or lane-classification expectation on the CURRENT
engines before it enters a charter; a hypothesis seam over a generated type is
imported by the PROOFS module, not named by `extra_import` (cycle); a charter
that empties or moves a register lists the gate SELFTEST plants that name its
rows; an equivalence between fuel'd formulations is stated at sufficient fuel
or under an explicit sentinel hypothesis, never bare `∀ n`; the pristine
lane's reviewed-diagnostic pins hash backtrace line numbers, so a `.lem` body
change can move one — a landing-time re-pin by the orchestrator, not a defect
(TODO asks whether to normalise them).

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

**Consumer re-pin note (revision 10; for the operator to relay).** Target
`15907f32b`. Lean signature changes since refined-cerberus's pin `89f7e6885`:
2026-09-11 — `Ctype_aux.are_compatible_aux`/`are_compatible0` and
`Core_aux.memValueFromValue` lose `[LemFuel]`; theorem
`are_compatible_aux_measure_sufficient`; module `CerbCtypeMeasure`. 2026-09-15
— none consumer-visible (`CerbFloat.of_string` and the bridge keep their
signatures). 2026-09-16 — `Formatted.nonnegativeDecimalInteger`,
`decimalInteger`, `flags0`, `fieldWidth`, `output_precision`,
`conversionSpecification`, `format0`, `Monadic_parsing.many`, `many1` lose
`[LemFuel]`; `many_lemFuel`/`many1_lemFuel` (+ `_zero`) are REMOVED;
`many_run`/`many1_run` (+ `_lemFuel`) are NEW; new modules
`CerbParserProgress`, `Monadic_parsing_lemMeasureProofs`. None is in their
proved fragment's cone (no struct values, no printf). Full manifests: the two
records' consumer-note sections.

**Upstream tray (revision 10).** 43 numbered drafts + `ocaml/01`; only draft 01
is filed (issues/1009, plus 1010 outside the tray, 2026-08-19). Drafts 37–43
carry the three shared-model deltas (37/38 owed since 2026-09-10/11), 40 +
`ocaml/01` carry R5 (an OCaml-runtime target, new directory), 41/42 are
questions (flexible-array vs sized-array compatibility; unary minus on a
floating zero), 43 a proposal. Filing/pushing remain operator actions.

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

**Whole-project semantics audit (2026-09-11) — the sixteen findings**
(status at revision 10; [AGENT] mapping, verified against the tree 2026-09-11):

| Finding | Status | Where |
|---|---|---|
| 1 pure failures as values | Ruled + censused; twin parked with tripwire; the NEW point (structural outcome constructors) = D2, agreed, unchartered | §3 step 5b, §4.3 |
| 2 hidden enum/digest state | OPEN — F7 | §3 step 5 |
| 3 non-UTF-8 Cabs JSON | FIXED 2026-09-15 (literal contents); TEXT-field residual row | §4.5, VALIDATION §3 |
| 4 hex-float overflow | FIXED 2026-09-15; R5 for the oracle's subnormal defect | §4.5, VALIDATION §2 |
| 5 array-bound typo | FIXED 2026-09-15 (shared model); draft 39 | §4.5 |
| 6 cross-TU struct values | FIXED 2026-09-15 (struct; draft 38); union twin OPEN (TODO) | §4.5 |
| 7 union init / bit-fields | Upstream completeness gaps, recorded `CERB_SKIP`; coverage-by-outcome publication is a docs item | §7 |
| 8 upstream ≠ ISO | Ruled F1 kind-1 / F10: the authors' model; belongs in the profile statement; the "three contracts" exist as dated record + register + manifest, not yet as one living front-door document | §2, §4.1 |
| 9 fuel | Pending register EMPTY 2026-09-16; whole-driver composition proofs (the seven absorbing workers) OPEN | §3 step 5 remainder, §4.4 |
| 10 unestablished termination hypotheses | OPEN — D4 (checked input boundary) | §3 step 7 |
| 11 placeholder instances | OPEN — F7 | §3 step 5 |
| 12 Core/libc interchange | DEFERRED (consumer R-4/R-7) | §7 |
| 13 ND runner admissibility / `--first` policy | OPEN, unscheduled (a specification + lemma item) | §7 |
| 14 FS/concurrency boundaries | Refusal census OPEN (step 4); concurrency last, as the audit itself recommends | §3 steps 4, 8 |
| 15 lem-lean bytes/laws/CI | L4 OPEN (step 5); laws per consumer need; dual-toolchain check | §3 step 5, §6 |
| 16 stale claims / evidence categories | Three stale comments FIXED; "zero discrepancy" wording narrowed by the exit-test status; evidence categories = VALIDATION §9 | §8 |

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

**Exit status at revision 10 (2026-09-16) [AGENT].** Exit 1 (profile): the
known port defects the audit found are fixed; inherited upstream defects are
tray-filed drafts; the profile is a dated record, not yet one front-door
document. Exit 2 (validation): trustworthy instruments, every landing on a
full battery, zero movement. Exit 3 (no invented success): the fuel register is
empty; pure failure sites are registered, not yet typed — D2. Exit 4
(consumer): re-pin owed. Exit 5 (adversarial convergence): the 2026-09-11 audit
was such a pass and found two — reopened and closed; the exit is NOT met until
a fresh pass finds zero after step 5.
