/-
  CerbCoreInstances — RETIRED to an instance-free shell (arc-8 S3).

  History (arc-7 S5c, audit-1 F1 eviction): this file carried REAL
  Inhabited instances for the generic Core AST families
  (generic_pattern_/generic_pattern, generic_pexpr_/generic_pexpr,
  generic_expr_/generic_expr), extra_import'd into 7 generated modules
  to evict the lem backend's low-priority fallback instances whose
  default was the logically INCONSISTENT DAEMON axiom
  (lembugs/2026-08-20_daemon-inconsistent-axiom.md).

  Since arc-8 S1/S2 the backend DERIVES real bounded Inhabited instances
  for these families in generated/Core.lean itself (tier-2
  per-constructor derivation; DAEMON deleted from LemLib at arc-8 S3),
  so the eviction mechanism is obsolete and every instance formerly here
  is retired. NOTHING here needed retention: an uncovered demand
  surfaces as a loud Lean "failed to synthesize" error, never a hidden
  fallback. Derived defaults occupy only unreachable/panic positions —
  enforced by the arc-8 S3 zero-movement differential bar.

  The module is kept (empty) only as the anchor for the
  `declare {lean} extra_import CerbCoreInstances` declares in
  frontend/model/*.lem; removing that plumbing is an arc-8 S4 cleanup
  candidate. It still imports CerbInhabitedInstances to preserve the
  arc-7 import shape for those declares.
-/

import CerbInhabitedInstances
