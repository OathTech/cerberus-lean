/-
  CerbCoreInstances — arc-7 S5c (2026-08-20, audit-1 F1 eviction):
  REAL Inhabited instances for the generic Core AST families, evicting
  the lem backend's `(priority := low) … default := DAEMON` fallbacks
  from the slate-theorem axiom cones (the arc-2 CerbInhabitedInstances /
  arc-4 S1a priority-override precedent: a hand-written default-priority
  instance, imported into the use-site modules via
  `declare {lean} extra_import` in the .lem sources, wins resolution
  over the low-priority generated fallback at regen).

  WHY (audit-1 F1): `axiom DAEMON : ∀ {α : Type}, α` is logically
  INCONSISTENT (`DAEMON (α := Empty)` proves `False`), so every
  fallback-instance use is a DAEMON entry vector into theorem cones.
  Each instance below is an HONEST total construction — the default is
  a real value of the type (for the AST families, a `PEundef`-anchored
  "unreachable default" node built from nullary/empty leaves), so
  nothing here can prove anything false. Defaults are only ever consumed
  at unreachable sites (`panic!`/`head!` shapes); differential gates
  verify zero observable movement.

  This module also imports CerbInhabitedInstances, so an extra_import of
  this file brings the monadic real instances (ndM, nd_action, exceptM,
  dlist, …) into scope for the same eviction.

  No OCaml counterpart (OCaml has no Inhabited): divergence is
  deliberate and documented here (mirror-OCaml doctrine, 2026-08-19).

  House rules: no sorry, no axioms, total constructions only.
-/

import Core
import CerbInhabitedInstances

-- Patterns: `CaseBase (none, BTy_unit)` is a real pattern for every
-- symbol type (the `Option sym` slot is `none`, so no `sym` inhabitant
-- is needed).
instance {sym : Type} : Inhabited (generic_pattern_ sym) where
  default := CaseBase (none, BTy_unit)

instance {sym : Type} : Inhabited (generic_pattern sym) where
  default := Pattern [] (CaseBase (none, BTy_unit))

-- Pure expressions: `PEundef` needs only a location and an
-- undefined-behaviour tag — a real node for every (bty, sym); the
-- DUMMY string marks the value as an instance default should it ever
-- surface in diagnostics.
instance {bty : Type} {sym : Type} : Inhabited (generic_pexpr_ bty sym) where
  default := PEundef CerbLocation.Loc.unknown (DUMMY "Inhabited default")

instance {bty : Type} {sym : Type} [Inhabited bty] :
    Inhabited (generic_pexpr bty sym) where
  default := Pexpr [] default
    (PEundef CerbLocation.Loc.unknown (DUMMY "Inhabited default"))

-- Effectful expressions: a pure wrapper around the pexpr default.
instance {a : Type} {bty : Type} {sym : Type} [Inhabited bty] :
    Inhabited (generic_expr_ a bty sym) where
  default := Epure (Pexpr [] default
    (PEundef CerbLocation.Loc.unknown (DUMMY "Inhabited default")))

instance {a : Type} {bty : Type} {sym : Type} [Inhabited bty] :
    Inhabited (generic_expr a bty sym) where
  default := Expr [] (Epure (Pexpr [] default
    (PEundef CerbLocation.Loc.unknown (DUMMY "Inhabited default"))))
