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
