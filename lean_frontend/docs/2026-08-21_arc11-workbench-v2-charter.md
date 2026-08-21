# Arc 11 charter: workbench v2 — trace/replay, context laws, T5 ("the finisher")

Date: 2026-08-21. Mode: long-cycle autonomous under the orchestrator/
worker doctrine, PARALLEL STREAM alongside arc 12 (the honest oracle).
BLESSED by operator via launch, 2026-08-21. Branch: `arc/workbench-v2`
(cerberus-lean only; lem untouched — any lem change = full pin dance
+ replan).

## Objective

Finish what arc 9 built: **T5 proved** (exit criterion 1) and the
graded slate advanced, by importing the survey slate's top items —
discovery-trace + checked replay, the loop-rule family, and
context-indexed law applicability — plus the two-part-design
rehearsal. Inputs (all committed arc-9 records):
`2026-08-21_iris-rules-automation-survey.md` (the ranked slate + per-
item acceptance gates), `2026-08-21_lithium-source-review.md`
(footprint-shaped premises push; the naming/per-stage disciplines),
`2026-08-21_arc9-results.md` (the 44/79 resumption point: the
continuation-lambda advance law; the v2 cleanup slate from audit
findings A-F4/F5/F6).

## Parallel-stream discipline (binding)

Write surface: `lean_frontend/relsem/**`, `tests/verify/` (additive
fixtures), `scripts/check_proof_size.sh` + `scripts/test_unit.sh`
(DECLARED to this stream; arc 12 must not touch them),
`lean_frontend/lakefile.toml`/`lake-manifest.json` (the package
rehearsal — declared touch-point), `test/Unit/`, docs. FORBIDDEN:
lem-lean, `frontend/model/`, oracle OCaml (`util/`, `backend/` minus
lean_export), `CerbMem.lean`/`CerbND.lean`/hand seams, ALL exec
baselines, the fork-drift manifest/hashes, `tests/csmith*`. Arc 12
owns the oracle side; merges serialize (second closes = rebase +
re-gate + re-ask). The two-part-design constraint (container
CLAUDE.md) binds: no new semantics→relsem coupling; the interface
stays enumerable.

## Slices

**S0 — resumption + trace IR design (short).** Re-validate the arc-9
resumption evidence in this worktree (t5-probe, the banked prefix/
St-family); design the TRACE IR from the emitter's actual event
stream per survey rank-1 (normalization decisions, law selections,
instantiations, residuals, sealing boundaries) + the replay contract
(preview mode NEVER closes anything CI-accepted; checked replay
emits ordinary kernel terms through the existing per-stage emitter);
design the context-query extension to `@[app_eq]` metadata (survey
rank-3: required-fact key, deterministic hypothesis query, typed
residual classes) and the footprint-premise refactor direction
(Lithium review). Yolo is PAPER-ONLY evidence (no license — zero
code; the S4 audit checks this boundary). Design addendum to the
arc-9 S1 design doc, dated.

**S1 — engine: trace/replay + context queries.** Implement per S0.
Regression bar: the arc-9 walker tests + T1 calibration + all 54 kit
pins unchanged-green; the audit A-F4 cleanup slate (dead lanes,
WIP-stale docstrings, normCompute params) executed here as the
refactor rides along.

**S2 — T5 COMPLETE (exit criterion 1).** The continuation-lambda
advance law (the named resumption point) + finish the 79-round climb
via the trace/replay engine; `iter_compose_var`/`_exit` land when
the proof shape demands them (survey rank-2). T5Statement in the
CallHarnessAdequate form, statement gate accepting, cone exactly
[propext, runEffectful, Classical.choice, Quot.sound]; the
proof-size gate's T5 registration flips to ENFORCING and the bar is
met (≤250 lines/≤40 manual steps — stop-extract-redo, never a bar
change). This is the arc's hard core; the D3-class stop rule applies:
a NEW wall class (not solved by trace/replay + the named law) =
park with evidence + immediate operator report.

**S3 — the slate, capacity-honest.** T6 (nested loops) then T7
(arrays — the collection-view item, survey rank-6, lands here
demand-driven) then T8 (early exit) then T9 (calls — the
callee-block interface, survey rank-5); each per the arc-9 fixture
recipe, each within the bar, whole-slate re-prove on every kit
change. Park clauses per example; a completed T5+T6 with clean
records beats a rushed T9.

**S4 — the package rehearsal ([USER] two-part design).** relsem
becomes its OWN Lake package inside the repo (own lakefile,
requiring the semantics package by path); the in-build gates
(Audit, Kit/Audit, statement gate) demonstrably re-homed and still
build-failing; `lake build` from the root still elaborates
everything (the plain-build property preserved). This is the
rehearsal ONLY — no repo split.

**S5 — close-out.** Results (proof-size tallies verbatim per slate
theorem; trace/replay metrics: discovery vs elaboration vs kernel
time separated per the survey's acceptance gate), decision log,
docs de-stale, 2-agent adversarial audit — mandatory scopes:
(a) trace/replay trust boundary (preview provably cannot close
CI-accepted theorems; replay terms ordinary); (b) reuse honesty
(context-query vs iris-lean, Yolo zero-code boundary); (c) grind/bar
honesty (T5's gate flip real; tallies recompute); (d) package
rehearsal soundness (gates re-homed, still fail-closed,
plant-tested). Fix-or-record; merge checklist (serialize with arc
12). Stop. Do not merge.

## Success conditions (machine-checkable)

1. T5 proved, gate-enforcing, within the bar; cone the clean quartet;
   fixture differential green.
2. Trace/replay landed with the survey's acceptance gates (preview
   non-authoritative — negative-tested; metrics separated).
3. ≥T6 additionally proved within the bar (T7-T9 capacity-honest,
   parked-with-pricing beyond).
4. Context-query extension landed, deterministic, trace-recorded
   candidates; no backtracking/silent search (audit-checked).
5. The package rehearsal: relsem builds as its own Lake package,
   all in-build gates re-homed + plant-tested, plain root build
   preserved.
6. Zero movement: minimal exec, verify, all standing gates; zero
   forbidden-surface touches (diffstat-audited); zero lem changes.
7. Records complete; branch gate-green; merge checklist ready.

## Risks / tripwires

- S2 wall class beyond the named law → park + report (the workbench
  itself already merged; v2's floor is engine+rehearsal).
- Package rehearsal breaking the in-build gate property → revert the
  rehearsal, record, retry post-slate (it must not eat the arc).
- Any need to touch generated code, baselines, or the oracle →
  that's arc-12's lane or a design error — STOP.
- Heartbeat doctrine, capped builds (40G while both lanes live),
  verbatim records, park-don't-improvise — all standing.
