/-
  RelSem.Kit.AppEq — arc-9 S2 (2026-08-20): L1 kit, the monadic spine
  (design docs/2026-08-20_arc9-s1-design.md §1.2, [IN-HOUSE re-export
  surface]).

  The spine equations are PROVED in RelSem/Machine.lean (audited
  there); this file only registers them as `@[app_eq]` walker laws.
  Contract (all): closed `app`-computation equations; the bind/lift
  laws chain (their RHS is another `app`), the leaf laws are terminal.

  Import discipline (design §6): no Iris, no fixtures.

  House rules: no sorry, no axioms declared here.
-/

import RelSem.Machine
import RelSem.Tactics.AppEqAttr

set_option autoImplicit false

namespace RelSem.Kit

-- The chaining laws: sequential composition and the state lens
-- (active path — the slate's value routes).
attribute [app_eq] RelSem.app_bind_active
attribute [app_eq] RelSem.app_liftND_active

-- Terminal leaf laws (each one `app` node, `rfl`-grade).
attribute [app_eq] RelSem.app_nd_return
attribute [app_eq] RelSem.app_kill
attribute [app_eq] RelSem.app_nd_get
attribute [app_eq] RelSem.app_nd_put
attribute [app_eq] RelSem.app_nd_update
attribute [app_eq] RelSem.app_nd_read
attribute [app_eq] RelSem.app_print_debug
attribute [app_eq] RelSem.app_nd_guard_true
attribute [app_eq] RelSem.app_pick_singleton
attribute [app_eq] RelSem.app_ifM
attribute [app_eq] RelSem.app_addConstraints

end RelSem.Kit
