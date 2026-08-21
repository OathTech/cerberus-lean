# Arc-10 decision log

Provenance-tagged per doctrine: [USER] = operator-decided, [AGENT] =
orchestrator judgment call resolved by project principles.

- **D1 [AGENT] — S0 boundary + the six open questions.** Orchestrator
  independently verified: commit a0f3706ab = triage doc + 2 NEW
  scripts only (no forbidden surface, no existing script modified),
  unit gate re-run rc 0. Rulings on the S0 questions:
  (1) Finding 8 (msum-fork trace-count signature, now csmith-forced
  by seed 930005): CerbMem-only attempt PRE-AUTHORIZED in S4; PARK at
  first CerbND contact — the forbidden-surface line is absolute.
  (2) test_exec.sh SKIP_BUILD opt-in env for creduce throughput:
  ALLOWED as an instrument change under the arc-5 discipline — own
  commit, justification, semantics unchanged when unset, zero
  movement evidenced.
  (3) Set-comprehension stub: FOLDED INTO S2 (same fail-closed
  opaque-emission class; coherent with the sweep).
  (4) Column-0 emission: stays PARKED (cosmetic; S2 is already the
  arc's largest slice — no scope creep).
  (5) CerbMem gate-scan extension: PARK CONFIRMED (arc-9
  coordination; post-merge candidate).
  (6) Arc-4 findings 24-30 one-liner extraction: ACCEPTABLE for S4
  classification, provenance labeled DERIVED-from-register (never
  formatted as quotes — the verbatim doctrine).
  Also accepted from S0 evidence: the stack-ceiling register entry is
  STALE (onset now 16384<N<=24576, loud exit-134, not quiet — the
  arc-7 totalization presumably moved it); the S5 results doc carries
  the correction, the item remains FORBIDDEN-surface parked.
- **D2 [AGENT] — S1 boundary verified + coverage-baseline call
  RATIFIED.** Orchestrator re-ran: unit 5/5 (sync gate 21 files),
  minimal zero movement, ci `BASELINE OK` (first re-run attempt used
  the wrong baseline file — --check-baseline defaults to the minimal
  baseline; operator-education note: ci needs
  `--check-baseline=scripts/exec_ci_baseline.txt`). The flagged
  coverage flip (mem3-004-string-write-attempt DIFF → UB_MATCH) is
  RATIFIED as expected-in-class: the file's own header cites
  select_ro_kind impl_mem.ml:1704-1710 — it is a finding-11 test by
  construction; the S0 triage row's pp-class listing was inference,
  now corrected. Scoreboard: ci 111/114 (derived). Finding 11 CLOSED
  (register). Commit 3b82fac70 coherent, no forbidden surfaces.
- **D3 [USER] — scope additions applied at the S2 boundary** (staged
  in notes/2026-08-20_arc10-pending-scope-additions.md while the S2
  worker held the worktree): S3b float+bytes wiring; S4
  csmith-configuration exploration (prototype setup explicitly not
  final); S4 list-lane + seeded reproducer. See the charter ADDENDUM.
- **D4 [AGENT] — S2 boundary verified + a standing gate rule.** Both
  worktrees clean; LEM 98d19fb/a9387fb, CERB 442a52334/eec935634
  (pin-bump own commit per the touch-point discipline). Orchestrator
  re-ran: capped DEFAULT-TARGET build green (593 jobs, RelSem audit
  sweep clean), unit 5/5, exec zero movement, sorry census
  independently confirmed (1 comment hit only). Census accepted:
  1134 → 0 real comparison-sorry sites; 58 types fully derived; 21
  fn-residual types / 210 failwithI sites + 494 tv-fallback sites
  counted and labeled; 4 register items with movers. THE LESSON
  (S2's major finding): S1 shipped a latent RelSem elaboration
  regression (equation-lemma maxRecDepth from an inline nested
  match in allocateObject) that BOTH the S1 worker's gates AND the
  orchestrator's S1 boundary verification missed, because neither
  ran the capped default-target build. STANDING RULE from here:
  every S-boundary verification (worker AND orchestrator) includes
  the capped default-target build — the April cerberus-scale lesson
  generalizes to Layer-2. Fixed in-scope by the named-helper hoist
  (semantics identical, citations preserved); relsem untouched.
- **D5 [AGENT] — S3+S3b boundary verified.** Orchestrator re-ran the
  full D4 set: capped default-target build 0 errors, unit 6/6 (new
  pp-test lane), minimal zero movement, float lane BASELINE OK
  (69/69 MATCH — first sweep needed zero fixes; 0 oracle-indicting:
  the corpus exercises the concrete model's op_fval, not the buggy
  lem-level mul — classification rule banked in the baseline
  header), bytes ALL AT COMMITTED EXPECTEDS (9 exec + 5 neg-pinned),
  ci BASELINE OK. Register row 2 (pp-placeholder text class) CLOSED
  with a 25-item enumerated residual, all honest-bracketed;
  format_string_of_float stub closed (row 11/#29 folded);
  stringFromMemValue partial→total (half of row 21). MILESTONE
  (derived): ci mismatch count is now 0 — 114/114 comparable agree.
  Commits e0d3ad1f7/57fe96ab4/65f77606c coherent, no forbidden
  surfaces (diffstat-checked by worker; lakefile touch = additive
  exe entry only). S4 (csmith campaign) is GO per the amended
  charter: configuration exploration first.
- **D6 [AGENT] — S4 boundary verified; campaign ACCEPTED; F-D
  REATTRIBUTED (the [USER] root-cause directive's payoff).**
  Orchestrator re-ran the full D4 set at ac509e962 — all green, ci +
  coverage BASELINE OK. Campaign: 3169 differential programs (1500
  portfolio-generated + 1669 corpus + 1 seeded), evidence-based
  5-lane portfolio (the dim-3 initializer discovery recovered ~52%
  yield), ZERO Lean-side semantic defects, finding 8 FIXED
  CerbMem-only (the D1 park line never tripped). THE HEADLINE: the
  F-D family (internal errors / spurious UB / silent value
  corruption, declaration-layout-sensitive, 24 witnesses) is NOT
  upstream — un-forked upstream cerberus is correct on every tested
  witness; the defect is a CERBERUS-LEAN FORK REGRESSION, suspect =
  the arc-2 S1 threaded sym_supply (core_run_aux.lem:233-247,287;
  its own comment concedes the undischarged sym non-escape
  obligation) interacting with description-insensitive
  symbolEquality; head-vs-tail declaration predictions TESTED.
  Without the root-cause directive we would have filed OUR bug
  upstream — record-integrity near-miss, banked as a lesson.
  CONSEQUENCES: (1) upstream tray corrected — F-D pulled (WireGuard
  note addendum'd); F-A (initializer desugar, shared-model) + F-B
  (address-constant strictness) confirmed genuinely upstream with
  un-forked repros, tray-ready; F-E dissolved. (2) The F-D REPAIR is
  model-.lem surface (frontend/model — outside arc-10's blessed
  scope and the declares-only doctrine's easy path): PARKED as the
  TOP candidate for the next arc, with the worker's M-priced
  analysis attached; the affected differential class stays
  classified in baselines (Lean+gcc agree; the fork-oracle side is
  the wrong one — baselines already record these as
  ORACLE_DEFECT-class, honest). (3) Perf register: 15 timeout
  entries (2.4-3x, worst 50x) + 2 CEILING_FUEL. S5 (close-out +
  audits) is GO; the queued corpus-lane full baseline pass lands
  there (sharded/foreground per the watchdog constraint).
- **C1 [AGENT, 2026-08-21] — CORRECTION to D6's F-D witness tally
  (audit fix-batch; D6's text above is left as written — corrections
  are appended, never silently rewritten).** D6 says "24 witnesses";
  the audit recount over the campaign record's own per-witness lists
  gives **35**: 11 generated-lane (P1 1000139/1000299; P2
  2000129/2000239/2000287; P3 4000250; P4 5000125; P5
  6000018/6000038/6000098/6000245) + 16 corpus (the 15 DIFF rows +
  sa_csmith_190 under a perf timeout) + 8 B1-exploration
  internal-error seeds (3016022/44/49/51/58/74/82/99). The "24" came
  from the findings-ledger arithmetic, which took only the rounds-2/3
  generated count (dropping round-1's three P5 witnesses), omitted
  sa_csmith_190, and counted the seed block as one. The same labeled
  correction is applied to the results doc (headline + register row)
  and the campaign record (ledger + stopping rationale). The
  reattribution itself and every per-witness claim are unaffected —
  this is a tally correction, not an evidence change.
- **D7 [AGENT] — audits complete, fix-batch verified, ARC READY FOR
  MERGE ASK.** Two adversarial audits (A: semantics fidelity — 24,650
  float comparison points zero-diff, eqPtrval arm-for-arm, OCaml
  ground-truth cross-run on all pins, no constructible wrong-instance
  case, deriving-divergence unreachable; B: baselines/records/
  discipline — all baseline movements justified, D6 head-vs-tail
  prediction reproduced live, zero forbidden-surface touches, all
  checklist git facts true). Findings: A-F1 Type-1 sorry path FIXED
  fail-closed (LEM 11d4b4c, zero tree movement verified); B-F1
  shard-gate direction FIXED (bidirectional count check,
  re-demonstrated); B-F2 checklist conflict list completed
  (test_unit.sh declared + lesson recorded); records corrected as
  labeled corrections (C1: F-D witnesses 24→35; 524; 29; ub010
  qualifier; jitter note); A-F4/F5/F6 recorded/fixed. THE FORK-DRIFT
  GATE landed both legs ([USER] mandate; 52-file manifest + 20
  hash-pinned generated diffs, plant-tested both directions, wired
  Tier A). B's jitter ruling: S5's call RIGHT, ratified.
  Orchestrator final re-verification at CERB 6cec24d21 / LEM
  11d4b4c: build 0 errors, unit 6/6 incl. check_fork_drift OK, exec
  zero movement, LEM linearity confirmed. Merge ask goes to the
  operator with the ORDER A/B serialization decision.
