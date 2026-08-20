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
- **D2 [AGENT] — mid-arc lem consumption mechanism.** S1/S2 cerberus-
  scale validation uses the per-worktree checkout lem (PATH-prepend +
  LEMLIB, the parallel-streams mechanism from the container playbook);
  the opam pin (`deps/lem-pinned` @ bd7e2eb) and cerberus Lake manifest
  stay untouched until the closing pin dance. Rationale: switch-global
  opam pin churn mid-arc risks other sessions' state for zero benefit;
  the checkout mechanism is the documented stream-safe path.
