# First execution charter — validation foundations

**Proposed, 2026-09-05; [AGENT] recommendation for operator review.**
This charter implements the first work package in the
[master plan, revision 3](2026-09-05_master-plan.md). Writing it does not
start implementation or authorize landing. The starting evidence is the
[customer-readiness assessment](2026-09-05_customer-readiness-assessment.md).

## 1. Mission and result

Make Cerberus's validation instruments reliable enough to guide the next
semantic changes and to give its customers an inspectable account of what
has actually been checked. Deliver working instruments, fresh evidence and
a concrete next semantic charter on isolated branches.

The current instruments can hide byte differences and, in the concurrency
lane, accept a valid-looking verdict followed by engine failure. The fork
drift gate does not content-pin all hand-written oracle changes. The test
ladder has no executable release runner. Meanwhile, pure-failure behavior
needs a reachability census and a reviewed correspondence design before a
large transformation is safe to specify.

This is a substantial delivery across the main validation lanes, oracle
builds, concurrency harness and release evidence. Its completion establishes
the foundations for semantic repairs; it does not establish that all known
semantic defects are repaired or that concurrency is ready to land.

## 2. Decisions at entry

The proposed scope below is the entry decision. Once adopted, the agent
executes it without intermediate design approvals. These defaults make the
work bounded and leave the larger semantic choices for the final review.

| Question | Proposed decision for this charter |
|---|---|
| Main deliverable | Shared observation contract/codec, migrated lanes, independent oracle lane, stronger fork gate, executable release runner and current evidence. |
| Concurrency scope | Repair and test its observation/status handling in a private copy of the prototype; deliver a portable commit series for the subsequent integration charter. |
| Semantic changes | Instrumentation and diagnostics may change. Shared C/Core semantics, Lean semantic representations and public proof interfaces stay outside implementation scope. Newly exposed defects get minimized evidence and an explicit disposition. |
| Failure work | Census, reproducible counterexamples and a concrete design recommendation. No larger failure transform or monadic semantic repair in this charter. |
| Lem work | Read and reproduce against pinned Lem; no compiler/runtime or pin changes. If a Lem implementation change is needed, prepare it as a next-charter decision with paired worktrees. |
| Customer | Supply a provider-side smoke/proof client and an adoption manifest. refined-cerberus's agent retains its repo, re-pin and proof migration. |
| Reporting campaigns | Re-record affected reporting lanes where authorized and feasible. The active legacy csmith run is excluded; its absence cannot be represented as a passing certification result. |
| Landing | End-of-work discussion of the actual branches, validation and audit scope. No merge or push during execution. |

The agent chooses codec implementation language, internal schemas, script
names, factoring, fixtures, commit boundaries and work order. It may choose
between equivalent implementation techniques and resolve ordinary test or
build defects within this scope. There is no requirement to ask the operator
about each such choice. Existing exception classes and semantic rulings
remain binding; this charter does not silently widen them.

## 3. Worktrees and ownership

At execution start, record current heads and create these private worktrees
under the container's `worktrees/` directory:

1. `arc/validation-foundations`, based on identified
   `mdd/cerberus-lean` plus the adopted planning documents. The assessed
   mainline was `89f7e6885`; use the actual start revision in the manifest.
2. `arc/validation-foundations-concurrency`, based on an identified
   `feature/concurrency` revision, assessed at `086d8762d`. Bring across the
   shared codec and relevant instrument commits, resolving local harness
   differences. Preserve the prototype semantics. A complete feature rebase
   onto mainline belongs to the following concurrency integration charter.

Do not modify either source worktree or another agent's branch. Keep the
mainline fix series independently reviewable; the concurrency series must
identify its shared commits and additional changes. If mainline advances,
update only the owned branch, inspect the delta and revalidate the resulting
candidate. Never substitute results from an older head.

Lem stays at the recorded pin for this charter. Reproducers live in this
charter's evidence/probe corpus and identify the Lem source defect; canonical
Lem regression integration accompanies the eventual Lem fix. Functional
Lem work requires a subsequent same-name Cerberus/Lem branch pair, local
candidate compiler/runtime alignment, and the normal Lem-first landing and
re-pin sequence.

The existing legacy csmith run and its worktree are hands off until its
owner finishes: no monitoring, interruption, restart, duplicate campaign,
diagnosis, rebaseline or cleanup. Do not inspect it to decide whether to
continue this charter. Continue independent work and record unavailable
reporting evidence at the end. Leave refined-cerberus unchanged.

## 4. Goals and acceptance evidence

### G1. One lossless observation contract across the affected lanes

Specify the full observation before implementing its codec. Preserve the
verdict variant and every relevant field: values, semantic output bytes,
UB code/location, blocked state and process completion. Keep semantic
stdout/stderr distinct from engine diagnostics and retain raw captures.
Represent exhausted or partial exploration explicitly.

For each lane, specify whether ordering and multiplicity matter and which
projection is compared. A litmus reference outcome set may intentionally
discard duplicates; that projection cannot substitute for the full
Lean-versus-OCaml comparison. Existing justified exception handling must be
visible, narrow and tested. Unknown or malformed records fail loudly.

Migrate `test_exec.sh`, `test_gcc_oracle.sh`, `test_ci_sweep.sh`,
`test_cn_coverage.sh`, `test_multi_tu.sh`, `test_verify.sh` and the owned
concurrency lane. Inventory their callers and wrappers so no active path
continues to use an inconsistent legacy extractor. Trace the producers of
`Main.batchEscape` inputs before deciding how its bytes are decoded; do not
fix a Lem byte-representation defect by normalizing away the difference.

**Acceptance:** a contract and lane matrix; one shared implementation for
common verdict decoding; meaningful integration tests in every migrated
lane; and adversarial plants covering at least:

- Equal values with unequal output bytes, including NUL, high bytes,
  non-UTF-8 sequences and escaping.
- Multiple outcomes, duplicates and reordering according to each lane's
  declared comparison rule.
- Empty, unknown, incomplete and truncated observations; valid prefixes
  followed by diagnostic failure or resource exhaustion.
- Valid semantic nonzero exits, signal termination, timeouts and cap kills.
  Capture engine status without shell negation losing it. A C program
  returning 137 must not become an OOM classification; use the actual lane
  protocol and the cap witness where required.

Each plant must fail for the intended reason and leave no mutation behind.
Keep full before/after observations for newly exposed baseline movement.

### G2. A repaired concurrency instrument

Fix CR-1 on the private concurrency branch: capture both original engine
statuses, including the sequential refusal leg, before parsing verdicts.
Keep reference SC outcome checking and full engine observation comparison
as separate checks.

**Acceptance:** the
[four-case assessment probe](2026-09-05_litmus-exit-status-probe.py) rejects
all four invalid engine pairs; integrated plants cover both engines,
sequential refusal, timeout, cap kill, ordinary failure and truncated output;
and the 30 assessed litmus rows are rerun with explicit per-row results.
Preserve S7's initialization edges and measured original `apply_tree` bodies.
If stronger comparison reveals a semantic difference, retain its failing
reproducer and classify it separately from the instrument fix.

Do not describe this goal as a concurrency landing. Mixed-size overlaps,
SeqRMW sequencing, the consumer agreement theorem, shared-model compatibility
and a current-mainline integration audit remain explicit next-charter work.

### G3. An independent oracle lane and content-pinned fork deltas

Add a runnable pristine-upstream-versus-fork-OCaml lane over applicable
Tier A inputs and representative legacy CLI/library interfaces. Keep it
distinct from fork-OCaml-versus-Lean. Use the recorded pristine source
baseline (`b9aeedcb4dd438763b0eef7f95ac19e93875d7de`, unless a reviewed
existing baseline supersedes it), not a moving upstream checkout.

Identify the source, Lem compiler, OCaml toolchain, runtime resources and
actual binary used for every side. Establish an upstream-Lem build of the
pristine side in an owned build directory, using available local sources
and dependencies. A pristine model regenerated only by fork Lem provides
useful evidence but cannot stand in for this independence check. Build
compiler candidates locally; do not repin or reinstall the shared switch.

**Acceptance:** a reproducible independent build/run recipe, actual completed
comparisons with retained raw observations, a reviewed manifest of intentional
fork behavior differences, and plants proving that an unexpected difference
fails the lane. Applicability exclusions must be explicit and justified;
an unexpected baseline result is a finding, not a new automatic exception.
If the independent toolchain cannot be built within the available environment,
G3 remains incomplete; supply the exact missing prerequisite and prepared
recipe at final review. Do not relabel a fork-Lem build as independent.

Extend the existing fork gate to content-pin relevant hand-written semantic,
driver and build/runtime deltas, including fresh supply and renumbering.
Preserve generated-delta pins and P0's prerequisite/locale/duplicate checks.
Plant a content change inside an already-listed file and require rejection.
Manifest refreshes must show the reviewed delta; no blanket hash acceptance.

### G4. An executable, fail-closed release runner

Implement one entry point for the existing
[test ladder](../../scripts/LADDER.md), with explicit fast, full and reporting
selection. Keep its documented membership and executable membership in
agreement; do not establish a competing list of gates. This charter adds
the instrument plants and independent oracle checks to the appropriate
documented membership with a stated purpose and runtime cost.

Produce a versioned machine-readable report plus a concise human report.
Record commands, input identities, source revisions and dirtiness, relevant
pins/toolchains, binary/runtime identities, statuses, elapsed time and log
locations. Report pass, fail, incomplete and intentional non-applicability
separately. A missing tool, missing corpus, timed-out gate, stale generated
tree or unrun required lane cannot produce a green certification. Reporting
lanes preserve their existing non-gating semantics and raw classifications.

**Acceptance:** planted failing, missing and prematurely terminated lanes
prevent certification; lane selection matches LADDER; Tier A and Tier B run
on the final mainline candidate; and the concurrency candidate has its own
identified gate/plant report. Existing build-integrity requirements apply,
including cache-disabled regeneration when build rules are affected. A CI
entry invokes the same runner and makes unavailable prerequisites explicit.
Do not claim CI coverage from a wrapper that never executes the gates.

Run affected reporting checks on the owned candidate, including the corrected
CI extractor's evidence. A finite differential measurement may exceed an hour
when justified in advance by corpus size and the published per-row limits;
this does not authorize an extended build/proof grind. The legacy csmith
campaign is excluded. If existing close-out rules still require unavailable
reporting evidence, mark certification incomplete and bring that fact to the
landing discussion. Do not silently waive the rule or wait on/poll its owner.

### G5. A reproducible provider smoke client

Demonstrate generation, build and consumption from a clean owned checkout
without copied generated Lean, native objects or package build products from
the primed working tree. Immutable dependency sources/toolchains may be
reused if their identities and recipe are recorded. The test must expose
an omitted generation step or wrong compiler/runtime pin.

**Acceptance:** another checkout can follow the committed recipe; the
manifest covers all three Cerberus Lake packages and the Lem compiler/runtime;
and a small provider-owned client builds a proof over the genuine semantic
entry plus a delivered map law. Record explicit preconditions. Test the
actual Cerberus toolchain and the applicable standalone Lem runtime checks.
This is provider interface evidence; refined-cerberus adoption remains owned
by its agent and required for the later customer-ready release.

### G6. A failure census and a decision-ready semantic proposal

Trace deliberate pure failures through unused bindings/arguments,
projections, discarded results and callbacks. Include `hack`/`finalize`,
`to_pure(s)` and parser combinators. Connect the census to public entries
and explicit hypotheses; classify C-reachable, Core/API-reachable,
proved-unreachable and unresolved cases without conflating them.

Reproduce the known strictness discrepancy against identified Lem/Lean/OCaml
builds. Inventory the seven hand-written `memM` sites, 59 generated monadic
sites and five monadic sites without the needed location channel, checking
counts at execution start. Explain each group's existing error channel or
missing design obligation. Reconcile with the eight reachable pending fuel
workers; do not claim a simple failure annotation solves pure finalization.

**Acceptance:** a site census with source references and reachability
evidence; minimal runnable probes for every distinct demonstrated failure
mechanism; and a recommended correspondence design with concrete signatures,
one representative worked example and migration/validation obligations.
Separate success preservation, completion and faithful failure behavior.
The one-way statement `f_exc xs = .ok v → f xs = v` is insufficient by
itself: an always-failing implementation satisfies it. Name which directions
can be kernel-checked and which rely on external reference evidence.

Deliver the larger transform as a proposal for the operator's final design
decision, preserving the reference mirror. No broad lifting or representation
change is authorized by the census.

### G7. An honest profile and reviewable evidence archive

Write the supported profile and risk map across oracle, execution,
definitions, trust base, gates and consumer interface. Compare with the
2026-08-31 baseline and incorporate the new evidence. State checked
restrictions, theorem hypotheses, inherited defects and open port defects.
Documentation does not enforce a domain restriction; mark known wrong
answers as unsupported claims requiring repair or an actual guard.

Reconcile current overview/TODO claims and repair the assessed audit
archive's missing evidence inventory. Recover originals where available
outside the excluded legacy worktree; otherwise mark them missing and
identify new reproductions as new evidence. Never recreate historical logs
and present them as originals.

**Acceptance:** no current release claim rests on a missing or mismatched
artifact; every open finding has an input or precise source obligation,
impact, owner and next action; and committed evidence has working paths and
checksums. Historical results remain dated. Prepare the full documents for
the required fresh review at the final discussion.

## 5. Execution and decision discipline

Work through these stages, with ordinary progress reports but no routine
approval pauses:

1. Freeze source/build provenance; specify the observation contract and lane
   matrix; inventory known risks and establish the current baseline.
2. Implement the codec and its plants; migrate each mainline lane; port the
   relevant commits to the private concurrency copy and repair CR-1.
3. Build the independent oracle lane and strengthen the existing fork gate.
4. Wire the release runner and CI entry; rehearse the clean provider client.
5. Finish failure probes/design and profile/evidence reconciliation; validate
   final candidates and assemble the end-of-work package.

The agent may reorder independent work. Check meaningful local behavior while
developing, then follow the existing Tier A per-commit and Tier B boundary
rules. Avoid repeated full suites without a new change or unresolved concern.
Use the repo's environment helpers and `scripts/capped` for every Lean
invocation; one heavy job at a time, respecting current resource pressure.
Do not change machine-global state, shared pins, shared caches or another
agent's artifacts. Do not raise heartbeats or arbitrary fuel budgets to make
failures disappear.

When stronger instruments expose a semantic bug, minimize it, retain both
raw observations and process statuses, and identify the affected claim.
Continue independent charter work. Do not repair shared semantics outside
scope, suppress the observation or count the discrepancy as agreement.
Baseline format migrations and justified instrument corrections need
dedicated, explained commits; genuine semantic differences stay findings.

An unavailable external prerequisite, a build/proof pass approaching the
existing one-hour tripwire, or a necessary out-of-scope semantic change stops
the affected activity. Report it promptly and continue other goals. If all
remaining work depends on that issue, deliver a blocked final package with
the concrete decision needed. Elapsed time never supplies approval, and an
unmet goal never becomes complete merely because the branch is reviewable.

## 6. End-of-work package and decisions

Deliver:

- Mainline-based and concurrency-based commit series, exact base/head refs,
  clean status and a map of shared versus branch-specific changes.
- A G1–G7 acceptance table, source/build manifests, complete runner reports,
  raw evidence and a list of every unrun or failed check. Distinguish working
  instruments, green semantic comparisons and complete release certification.
- The supported profile/risk map, failure census/design proposal, clean-client
  recipe and a provider adoption manifest for the customer agent.
- A ranked defect ledger and the proposed next charter. Prefer scoped
  concurrency integration next when the repaired instruments support it;
  identify any concrete blocker that makes bounded failure work urgent first.

Reserve these decisions for that review:

1. Adopt the proposed failure representation/correspondence design, or revise
   it before authorizing its larger Lem/Cerberus implementation.
2. Adopt the next concurrency charter, including mixed-size/SeqRMW domain
   repairs, the provider agreement proof, compatibility audit and full rebase.
   Any relaxation of the already accepted agreement obligation is explicit.
3. Decide the scope/scale of the fresh audit and whether each concrete branch
   is ready to land, including any unavailable reporting evidence. After the
   audit, obtain the required per-merge sign-off; use ff-only and revalidate
   if the base changes. Pushing is a separate decision.

No decision here transfers provider proof obligations to refined-cerberus,
authorizes the full concurrency feature to merge, or takes over the legacy
csmith run. The intended end is a substantial, reviewable engineering result
and informed semantic decisions, with landing discussed against real evidence.
