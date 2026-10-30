/-
  CerbCoreShape — SHAPE predicates on Core terms: the HYPOTHESIS vocabulary of
  the three measured-under-hypothesis rows that closed the always-on-path fuel
  sentinels `Driver.hack`, `Core_aux.to_pure` and `Core_aux.to_pures`
  (fuel-pending close-out 2026-09-08 — option C of the pure-failure
  reachability census, docs/2026-09-07_pure-failure-reachability-census.md Q4/Q6,
  [USER 2026-09-07] dispatched option C to a worker on its own branch; the
  mechanism is lem-lean's `declare {lean} fuel_measure val f = `μ` assuming `H``,
  the C4 route, docs/2026-09-05_fuel-parameter-C4-record.md).

  THE INVARIANT these rest on (the register scripts/fuel_hypotheses.txt cites
  it per row): `driver2` (frontend/model/driver.lem:1374) returns ONLY through
  the two terminal arms of `process_core_step2` — `Step_done2`
  (driver.lem:1336-1343) and `Step_fs2`/`FS_done` (:1357-1361); every other arm
  re-enters `driver2` or is an `error`, and `new_drive_core_threads`
  (:1280-1301) never yields a `Nothing` step for the `(_, Nothing)` arm. Both
  terminal arms rewrite the core state by `prepare_exit` (driver.lem:1314-1321):
  the initial thread's arena becomes `Core_aux.mk_value_e cval` =
  `Expr [] (Epure (Pexpr [] () (PEval cval)))` (core_aux.lem:454-455
  `mk_value_pe`, :2077-2082 `mk_pure_e`/`mk_value_e`) and its stack
  `Stack_empty`. So at both exec-path call sites of `to_pure` on an arena —
  `finalize` (driver.lem:1478-1482) and `driver_globals` (:1618-1623), each
  immediately after a `driver2` — the arena is `IsPureExpr`: `to_pure` returns
  its pexpr at depth 1 without entering `to_pures`; and that pexpr, `hack`'s
  argument at `finalize`, is `IsValuePexpr`: `step_eval_pexpr` returns it
  unchanged (core_eval.lem:583-584, the `PEval` arm) and `valueFromPexpr`
  accepts it (core_aux.lem:862-868) — exactly one iteration of `hack`.
  The census (Q4) reached the same conclusion from the `Step_done` PRODUCTION
  shape (core_run.lem:1557-1589, core_reduction.lem:1101-1113); the operative
  mechanism on the drive path is `prepare_exit` — the census's
  `driver.lem:490-491` cite sits inside the commented-out `drive_core_thread2`
  (:457-515), recorded as an erratum in the close-out record.

  A hand-authored call of `to_pure`/`to_pures`/`hack` on another shape is
  outside the hypothesis: the fuel-free measured wrapper then may EXHAUST
  (the loud sentinel), exactly as for the C4 layout rows on a cyclic table.

  MIRROR-OCAML NOTE: a Lean-target reasoning artifact; no OCaml text
  corresponds (fuel is a Lean-target artifact). The predicates are Props over
  the generated Core types, stated by constructor shape (no comparator, no
  executable content).
-/

import Core

set_option autoImplicit false

namespace CerbCoreShape

/-- The pexpr is a Core VALUE: `Pexpr _ () (PEval cval)` — the shape
    `Core_aux.valueFromPexpr` accepts (core_aux.lem:862-868) and the arena's
    pexpr after `prepare_exit` (driver.lem:1314-1321; `mk_value_pe`,
    core_aux.lem:454-455). The hypothesis of `Driver.hack`'s measure. -/
def IsValuePexpr (pe : pexpr) : Prop :=
  ∃ annots cval, pe = generic_pexpr.Pexpr annots () (generic_pexpr_.PEval cval)

/-- The expr is `Epure` of a pexpr: the arena's shape after `prepare_exit`
    (`mk_pure_e`, core_aux.lem:2077-2078). The hypothesis of `to_pure`'s
    measure. -/
def IsPureExpr {a : Type} (e : expr a) : Prop :=
  ∃ annots pe, e = generic_expr.Expr annots (generic_expr_.Epure pe)

/-- Every element is `Epure` of a pexpr: the hypothesis of `to_pures`'s
    measure (the mutual sibling of `to_pure`; a truly mutual fuel'd block is
    measured all-or-none — lem FM-mutual). Never entered on the exec path. -/
def AllPureExprs {a : Type} (l : List (expr a)) : Prop :=
  ∀ e ∈ l, IsPureExpr e

end CerbCoreShape
