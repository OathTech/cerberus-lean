/-
  RelSem.IrisState — arc-9 S2 (2026-08-20), REDUCED TO A SHELL at
  arc-18 C2 (2026-08-25): the OwnP state-interpretation definitions
  this module used to hold (`CerbGpreS`/`CerbGS`/`stateIs`/`CerbS` —
  the iris-lean OwnP adoption, arc-9 Q1/F1) MOVED name-stably to
  RelSem/PerStepOwnP.lean as part of the C2 disentanglement: the live
  per-step route must not depend on the arc-7 shell, so the
  interpretation now lives with the transitional OwnP surface and the
  arc-7 route (this module's importers: IrisRules/IrisAdequacy/
  SlateWP + the ambient family) resolves the same names THROUGH this
  import. The whole shell — this file included — deletes at C5 with
  the ambient family (retirement register entry 1).

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.IrisLang
import RelSem.PerStepOwnP
