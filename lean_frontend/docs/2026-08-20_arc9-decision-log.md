# Arc-9 decision log

Provenance-tagged per doctrine: [USER] = operator-decided, [AGENT] =
orchestrator judgment call resolved by project principles.

- **D1 [AGENT] — iris-lean pin BUMPED to head `34390a01339`** (from
  79dab154a), per the S0 survey recommendation (85bc2dfee): same
  toolchain 4.32.2 both revs, none of the five RelSem-imported Iris
  files changed, delta directly on-topic (OwnP #653 = the library
  form of our hand-built Layer-3 state story, ~380-line reuse
  opportunity). Context: the operator updated deps/iris-lean
  2026-08-20 ("they're new") — the bump follows the charter's
  pre-authorized flow (own early commit BEFORE tactic work).
  Orchestrator executed (pin ops are orchestrator-owned) and
  re-gated: capped default-target build green (595 jobs, in-build
  absence gate + sweep green, T1-T4 cones pinned unchanged),
  test_unit 5/5, test_verify 29/29, test_exec zero movement
  (SUMMARY byte-identical). Note: the true head hash was verified
  via rev-parse before pinning (the arc-8 fabricated-hash-tail trap
  hit again on first type-out and was caught the same way).
- **D2 [AGENT] — S2 boundary verified; T5 park accepted; S1 design
  AMENDED on measured evidence.** Orchestrator re-ran gates (unit 6/6
  incl. the new proof-size gate, verify 29/29, exec zero movement,
  RelSem build green); OwnP acceptance held (every T1-T4 Audit pin
  unchanged); calibration accepted with the worker's honest
  accounting (dnms_chain: 5 tactic lines / 2 semantic steps,
  identical statement + cone; T1AppEq 1,038 → 862 with the walker's
  promised kill classes dead in-segment). THE PARK (F-T5-1/2) is the
  stop-extract-redo discipline functioning at design level — the
  worker measured the blessed St sketch false (Neg-action exclusion
  rounds grow the env +2/iteration, period 79 not ~30) and correctly
  refused to improvise a design amendment. RULINGS: (1) design §2 St
  contract v2 — recursive env/rs/trace invariant families with the
  drawn ids as closed functions of i (census-proven 1048576+2i),
  lookup discharge via the lawful-map API route (P2 generalized from
  bytemaps to environments), fresh-draw seeds pinned
  T4-EnvHyp-style; T5Statement itself UNCHANGED (CallHarnessAdequate
  shape — the amendment is proof-internal only). (2) Walker v2:
  type-aware selective state normalization (normalize arena/env
  components; leave the program term) as the design's app_norm
  realization — F-T5-2's measured budget trips are the requirement
  spec, budgets stay at ambient (no heartbeat raises, per doctrine).
  (3) S3 = T5 resumption FIRST under the amended design, then T6-T9
  in design order as capacity honestly reaches; T10 stretch + park
  clauses stand. Amendment lands as a DATED ADDENDUM to the S1
  design doc (never a silent rewrite).
- **D3 [AGENT] — S3 boundary verified; T5 continuation AUTHORIZED
  (per-stage certificate emitter).** Orchestrator re-ran the full
  boundary set at d1a02c473 (capped 40G default-target build 0
  errors, unit 6/6 + proof-size gate OK, verify 29/29, exec zero
  movement). The re-park is accepted as evidence-grade: St-v2 is
  kernel-defeq-VALIDATED at symbolic n (all 21 entry rounds
  mechanical, incl. create/store through the perform layer — the
  F-T5-1 risk is discharged; two family defects found BY the kernel
  diff and fixed), and the sole remaining wall is engine-shaped:
  `(kernel) deep recursion detected` when packaging a whole round's
  certificate as ONE defeq, with a 10-row configuration matrix
  showing every component passes individually. The identified
  completion — a per-stage certificate emitter (mirroring how T4's
  hand proofs pass identical content as many small obligations) — is
  bounded and specified (build record §6 pricing). RULING: one
  continuation session for the emitter + T5 completion; if the
  emitter meets ANOTHER wall class, the arc closes with T5 parked
  and the workbench (calibration + kits + walker + OwnP + iter_
  compose) as the deliverable — no open-ended climbing. Slate T6+
  only after T5 lands, capacity permitting. Doctrine-adjacent items
  flagged by the worker (heartbeat LEDGER — an accounting instrument,
  no ambient raise anywhere; §11.2 file-placement amendment) are
  accepted, audit-visible.
- **D4 [AGENT] — ARC CLOSES per the D3 fallback; T5 completion moves
  to workbench-v2.** Boundary verified at 2b3a686dd (build 0 errors,
  unit 6/6, verify 29/29, exec zero movement, cones unchanged). The
  D3 stop-rule trigger was NOT met — no new wall class; every wall
  fell to the emitter design (the entry theorem kernel-checks in ~5s;
  44/79 census rounds green incl. the mechanized semantic-round
  engine: decide-fact chase-rewrite, Eq.ndrec materialization,
  ledgered budgets, raw-addDecl kernel-only certificates). The
  session ended on CAPACITY: ~35 rounds + body + exit + composition
  remain at a measured ~1 hour/round of worker discovery — which is
  exactly the open-ended climbing D3 bans and exactly the cost the
  workbench-v2 slate items attack (trace/replay collapses repeat
  round classes; context-indexed laws collapse the per-round
  discovery; ONE new Kit law class — the continuation-lambda advance
  — is the named unknown at the park point). RULING: arc 9 closes
  with THE WORKBENCH as its deliverable (OwnP adoption ~380→~150,
  50+ pinned kit lemmas across 7 kits, walker v1-v3 + the per-stage
  emitter, iter_compose axiom-free, the 700→5-line calibration, the
  proof-size gate) and T5 PARKED AT EVIDENCE GRADE with a precise
  resumption point; workbench-v2's charter takes T5 completion as
  its FIRST exit criterion, powered by the survey slate (the
  external Iris survey + the Lithium source review are v2's S0
  inputs, committed at this close). The proof-size gate's T5
  registration stays honestly pending — never gamed. S4
  (rebase-over-arc-10 + close-out + audits) proceeds.
- **C1 [AGENT, 2026-08-21] — CORRECTION line (pre-merge adversarial
  audit; D4's text above is left as written, per record doctrine —
  this line corrects it).** (1) [auditor B F1] D4's "the 700→5-line
  calibration" headline is corrected with the honest split: the
  MECHANICAL dnms content (~200 lines of round lemmas + transcribed
  intermediate configurations + the 9-way `.trans` composition)
  became the 5 walker lines; file-level T1AppEq went 1,038 → 862
  (git numstat −193/+17); the round3/round6 SEMANTIC support is
  retained and consumed by the walker's two `app_walk_step` lines.
  The "≈700" was the design's SEGMENT estimate including semantic
  support — the S2 record §3 always carried this split; the headline
  form propagated to the results doc §1.5, lean_frontend/CLAUDE.md,
  and merge-checklist step 6, all corrected in place. (2) [auditor
  A F2] D4's "OwnP adoption ~380→~150": the "~380" is the S0
  survey's reuse-debt sizing; the "~150" was a D4-text estimate with
  no S2-record source — the MEASURED accounting is IrisState +
  IrisRules + IrisAdequacy 456 → 369 lines (S2 record §1). (3)
  [auditors B F3 / A F3] D4's "50+ pinned kit lemmas across 7 kits"
  vs the results doc's six-kits/54-pins: the precise census at head
  is 7 FILES under `Kit/` (Audit, AppEq, Eval, Loop, Map, Mem,
  Round) = 6 content kits + the pin file `Kit/Audit.lean`, carrying
  exactly 54 `#print axioms` exactness pins; Kit/Mem is 139 lines
  (not the stale 133 — includes the `ad1460f59` rebase-integration
  fix). All tallies in this line are DERIVED (re-counted at head
  2026-08-21), labeled per the verbatim-transcript doctrine. Full
  finding list + dispositions: results doc §8.
