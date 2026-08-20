# Arc-8 decision log

Provenance-tagged per doctrine: [USER] = operator-decided, [AGENT] =
orchestrator judgment call resolved by project principles.

- **D1 [AGENT] — S0 verdict: GO.** Basis: the S0 census
  (`2026-08-20_arc8-s0-probe-census.md`, commit b513d28bc) — leg (c)
  is decisive: Core_rewrite's fully-polymorphic partial defs (the exact
  shape that killed the April attempt on first cerberus contact)
  compiled green with the DAEMON fallbacks deleted and only bounded
  real instances present; the full 55-fallback ablation converged in 5
  rounds via 12 in-module instances with ZERO signature leakage;
  instance-method failwith census = 0. Orchestrator independently
  re-verified (doctrine: worker green never accepted): both S0 commits
  docs-only, worktrees clean, `test_unit.sh` re-run rc 0 all gates OK.
  Conditions carried into S1/S2 (from the census + design note):
  per-constructor bounded derivation (except_foldlM/trysM two-sided
  shape), same-module placement, fail-closed underivable path, S2
  computed binder set must equal census Class T (16 defs) on today's
  corpus, behavior neutrality deferred to the S3 zero-movement
  differential bar.
- **D3 [AGENT] — S1 rule-4 interpretation RATIFIED.** The derivation
  skips self + FORWARD-mutual-sibling constructor references only;
  backward siblings resolve through already-emitted instances (worker
  flag 1). Basis: required for ndM/expression/Core wrapper pairs,
  consistent with the design note's "cross-type dependencies resolve
  through the emitted instances themselves", validated by the green
  cerberus-scale build + orchestrator-re-run zero-movement differential
  (unit rc 0; exec rc 0, SUMMARY verbatim-matched the worker's).
- **D4 [AGENT] — remaining opaque-fallback emission paths fold into
  S2.** S1 surfaced two pre-existing sorry-emission paths (worker flag
  2: non-parameterized opaque types' `default := sorry` instances;
  `default_value` L_undefined tyvar sorry). Charter durability req 2
  bans EVERY opaque inhabitant categorically — 0-in-corpus is not an
  exemption. S2's scope extends to eliminate them (fail-closed
  no-instance + generation-time error on backend-visible demand); after
  S2 the backend must be unable to emit sorry or DAEMON anywhere.
- **R1 [AGENT] — register candidate (S4 close-out):** `deriving BEq,
  Ord` fails on Sum-typed constructor fields (LemLib lacks `Ord (Sum)`)
  — pre-existing, surfaced by S1's ebox test, orthogonal; record in the
  lem register at close. Hand-instance retirement (CerbCoreInstances /
  CerbInhabitedInstances shrink) assigned to S3 alongside the Audit.lean
  pin updates.
- **D5 [AGENT] — S2 whole-invocation analysis prepass RATIFIED.**
  `lean_analysis_prepass_all` (census + threading over every
  typechecked module incl. non-output library modules) is a
  design-note-uncovered mechanism the worker flagged rather than
  improvised silently. Ratified: required because `make lean-libs`
  threads library defs in a separate invocation; it recomputes from
  source (no hardcoded lists), consistent with durability req 1.
  Evidence: design note S2 record + green cerberus-scale validation.
- **D6 [AGENT] — S0 census errata ACCEPTED (pass right, census
  wrong).** S2's computed binder set = all 16 Class-T defs + 6 library
  defs + 13 extra cerberus defs, each with recorded root cause (ndM's
  actual S1 instance is bounded, not leg-(a)'s hand unconditional; the
  witness-based checker argument doesn't apply to term-level synthesis;
  exceptM value-side bounds; depth-2 propagation via fromJust — the
  census's depth≤1 claim was wrong there). All callers concrete; green
  build + zero movement. The design note's S2 record is the corrected
  reference; S3/S4 records cite it, not the census's Class partition.
  Orchestrator independently re-verified at the boundary: unit rc 0
  with **driver2 cone = [propext, Classical.choice, Quot.sound]
  (DAEMON-FREE, pre-deletion)**, exec rc 0 byte-identical summary.
- **D2 [AGENT] — mid-arc lem consumption mechanism.** S1/S2 cerberus-
  scale validation uses the per-worktree checkout lem (PATH-prepend +
  LEMLIB, the parallel-streams mechanism from the container playbook);
  the opam pin (`deps/lem-pinned` @ bd7e2eb) and cerberus Lake manifest
  stay untouched until the closing pin dance. Rationale: switch-global
  opam pin churn mid-arc risks other sessions' state for zero benefit;
  the checkout mechanism is the documented stream-safe path.
- **D7 [AGENT] — S3 boundary verified.** Orchestrator independently
  re-ran: capped default-target build rc 0 (597 jobs) with the in-build
  absence gate + audit sweep green (verbatim outputs in the S3 record);
  test_unit 5/5 with driver2 DAEMON-free under the tightened arc-8 S3
  gate bar; test_verify 29/29; test_exec zero movement byte-identical.
  LemLib DAEMON references = history comment only; lakefile pin =
  9d220e49 (mid-arc, documented in-file, re-pin note for close). Both
  worktrees clean, commits coherent (LEM 9d220e4, CERB f147aad91).
