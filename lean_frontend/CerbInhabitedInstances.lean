/-
  CerbInhabitedInstances — RETIRED to an instance-free shell (arc-8 S3).

  History: this file carried hand-written computable Inhabited instances
  (bimap, t2/Multiset, dlist, parserM, kill_reason, exceptM, errorM, t0,
  nd_status, nd_action, ndM, sigma) that overrode the lem backend's
  low-priority axiom-valued fallback instances (the retired inconsistent
  DAEMON axiom — see lembugs/2026-08-20_daemon-inconsistent-axiom.md).

  Since arc-8 S1/S2 the backend DERIVES real bounded Inhabited instances
  in each type's own generated module (tier-1 nullary + tier-2
  per-constructor with [Inhabited tv] bounds; fail-closed — underivable
  types get NO instance), so every instance formerly here is now
  generated at the definition site and the hand copies are retired.
  NOTHING here needed retention: any generated or hand-written demand a
  derived instance fails to cover surfaces as a loud Lean
  "failed to synthesize" error, never a hidden fallback.

  The module is kept (empty) only as the import anchor for Main.lean and
  the `declare {lean} extra_import` plumbing in frontend/model/*.lem;
  removing that plumbing is an arc-8 S4 cleanup candidate.
-/
