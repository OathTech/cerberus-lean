# Arc-18 C0 — doc truth + the layer contracts (record)

Slice C0 of the coherence arc
(`docs/2026-08-25_arc18-coherence-charter.md`, blessed [USER
2026-08-25]: Q1 DELETE dormant peels/wpk laws, Q2 FULL CerbMemInterp
migration + exit ramp, Q3 one arc). Docs + gate-comments only — zero
proof-code changes, zero deletions (the retirement register is the
written inventory; deletions execute at C2/C5). Worker: [AGENT],
worktree `cerberus-lean-coherence`, branch `coherence`, base
`f776804e3`.

## 1. Staleness fixes (the coherence review's F7 + move 1, complete)

- **TODO.md** — "In flight" no longer headlines the FALSIFIED
  in-chase-sealing/stepper plan: replaced with the arc-18 coherence
  consolidation (charter + layer-contracts pointers; T4/T5 complete
  at C3), with the seal/stepper era explicitly labeled
  falsified/superseded and the stepper design note kept only as
  superseded history. "Next, in sequence" drops "The compositional
  stepper" (superseded) and now reads: family-∀ endpoints (arc-18
  C4) → the libxml2 rung (under `CerbMemInterp`) → arc 19
  goal-directed search. Section header "once the stepper sets the
  proof economics" → "once the automation framework sets the proof
  economics". Effect-axiom item retargeted: ambient family retires at
  the arc-18 C5 purge; spec-lab substrate re-lands threaded at C4.
  Elaboration-in-statement item's "once the sealing/stepper machinery
  lands" → "once the consolidated automation layer (arc 18) is in
  place".
- **PROOF.md §4** — full rewrite. Was: the walker/@[app_eq]/sealing/
  trace-replay workbench presented as the current machinery with the
  refounding as "direction of travel" (contradicting its own §1/§3).
  Now: the actual landed route (per-step KExpr layer + completeness;
  the law-driven evaluator minting named equations, fail-closed
  frontiers; the wp-tactic layer + `iter_compose`, honestly named
  Floyd–Hoare-at-the-equation-calculus; heap RA as the C2-designated
  sole interpretation; pure transport), with the chase workbench
  named as FROZEN LEGACY (freeze gate cited) purge-bound at C5.
  Points to the layer-contracts doc as the normative statement.
- **PROOF.md §1** — "retires at the arc-17 purge" → "arc-18 C5
  purge" (the purge moved arcs when the coherence arc absorbed it).
- **PROOF.md §3** — T4-threaded status updated from "in progress at
  a measured frontier" to the honest arc-17 S3 end state: parked at
  round 22, completes on the consolidated substrate at C3.
  Exec-equation-campaign paragraph updated: arc-17 machinery being
  consolidated by arc-18 (charter cited); family-∀ lands at C4;
  chase route "frozen pending the arc-18 C5 purge" (was "is
  retired" — it is not yet deleted).
- **DESIGN.md §4** — the `runEffectful` sentence aligned with the
  S2b axiom story: a *temporal dependency-side* axiom (this repo
  declares zero), ambient/compiled paths only, threaded family
  avoids it; dead "§trust" section reference fixed to PROOF.md §1.
  (No other DESIGN.md section references retired routes; verified.)
- **scripts/check_chase_freeze.sh** (header comments only) — the
  arc-16-part-2 purge reference updated to the arc-18 C5 extended
  purge with the retirement-register pointer; the FALSE `@[app_eq]`
  claim ("the law table itself SURVIVES the purge — the charter's
  primitive-law layer consumes it") corrected: the LEMMAS survive by
  re-registration in the C1 registry (today's law layer consumes
  them by name), the DiscrTree attribute MECHANISM has no non-walker
  consumer (`appEqMatches` only in `AppWalk.lean`, verified) and is
  the C1 registry's donor, disposition decided at C1.

Self-containment held: all pointers repo-relative; no container-only
paths introduced. `lean_frontend/CLAUDE.md`'s operational map still
describes the walker as present (true until C5); left untouched as
agent-facing operational text, re-checked at C5.

## 2. The layer-contracts doc (the C0 deliverable)

`docs/2026-08-25_reasoning-layer-contracts.md` — NORMATIVE; future
slices cite it. Structure:

- §0 preamble: blessing provenance, the one-sentence trust chain.
- §1–§5 the five layers, each with GUARANTEES / MAY ASSUME / GATES
  (existing gate names throughout): fuel opsem (TCB) → KExpr
  per-step (lockstep invariant, `ksteps_of_runNDFuel`) → THE ONE
  ROUTE (3a interpretation: CerbMemInterp target vs OwnP today,
  stated honestly; 3b evaluator mints, engine-to-law rule; 3c
  wp-tactics consume, registry as the interface) → threaded adequacy
  (trio cones, the four in-build gates) → statement vocabulary
  (target vocabulary in one sentence).
- §6 REGISTER of convention-only contracts, R1–R6, each with the
  closing slice: R1 lockstep coverage → C6; R2 single-interpretation
  discipline → C2; R3 engine-to-law + engine-size down-pressure →
  C1; R4 registry as law interface → C1; R5 statement-gate
  completeness (T4ThreadedStatement) → C3; R6 statement-face homing
  → C4.
- §7 THE RETIREMENT REGISTER (the C-series freeze addendum) — the
  C5 purge's written inventory, grep-verified on this tree: entry 1
  arc-7 route → C5; entry 2 dormant peels + `wpk_round_*` (Q1
  DELETE) → C2; entry 3 chase corpus → C5 (AppEqAttr ruled at C1);
  entry 4 ambient family + bridges + faces → C4/C5; plus explicit
  non-retirements (heap RA, the one-route modules).
- §8 the C5 success bar for slice audits.

## 3. Register findings worth flagging (beyond the review's greps)

Two LIVE dependencies land in the register that the review's
"zero consumers" summary elided — both change purge sequencing, and
both were verified by grep here [AGENT]:

1. `PerStepTactics.lean:37` imports `PerStepLaws` and its `wp_seq`
   macros consume `wpk_seq_active_proj`/`wpk_seq_active_ecast`
   (`PerStepLaws.lean:99`/`:84`) — the Q1-DELETE file contains two
   NON-dormant laws that must be re-homed (natural home
   `PerStepIris.lean`) before C2 deletes it.
2. `T4Threaded.lean:33` (live threaded flagship) imports `T1AppEq`
   (chase corpus) — C3 must leave T4's equation diet fully
   evaluator/registry-minted before C5 deletes the AppEq files.

Plus the structural one: the OwnP interpretation every landed
theorem binds is DEFINED in arc-7's `IrisState.lean`
(`PerStepIris.lean:29` reuses it wholesale) — so the C2 migration,
not just the C5 purge, is what disentangles the live route from the
arc-7 modules.

## 4. Validation (this slice)

Docs + comment-only changes; the full C0 battery run regardless
(discipline): relsem capped build, speclab capped build,
`./scripts/test_unit.sh` (7/7), `./scripts/test_verify.sh` (35/35).
Results recorded in the commit message; transcripts verbatim in the
worker report.
