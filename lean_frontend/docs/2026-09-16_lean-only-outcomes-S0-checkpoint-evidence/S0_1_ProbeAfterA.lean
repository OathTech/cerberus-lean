-- S0.1(a) AFTER-EXTENSION probe: the generated Inhabited defaults of the two
-- PRODUCTION outcome types once `Stopped of Interp_stop.interp_stop` is appended
-- to both, with the backend's derived instances for interp_stop in force
-- (no skip_instances yet). Expected (the review's hazard, production types):
-- the unconstrained t0 default becomes `Stopped Exhausted`; kill_reason's
-- primary `Undef0 default default` instance still wins (record §0 item 1).
import Nondeterminism
set_option autoImplicit false

theorem afterA_t0_default_is_stopped_exhausted {a : Type} :
    (default : t0 a) = Stopped Exhausted := rfl

theorem afterA_kill_reason_default_is_undef0 {err : Type} :
    (default : kill_reason err) = Undef0 default default := rfl

-- a concrete inhabited payload keeps the primary instance
theorem afterA_t0_nat_default_is_defined :
    (default : t0 Nat) = Defined 0 := rfl

-- the derived default of the vocabulary type itself
theorem afterA_interp_stop_default :
    (default : interp_stop) = Exhausted := rfl

#print axioms afterA_t0_default_is_stopped_exhausted
#print axioms afterA_kill_reason_default_is_undef0
#print axioms afterA_t0_nat_default_is_defined
#print axioms afterA_interp_stop_default
