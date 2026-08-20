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
