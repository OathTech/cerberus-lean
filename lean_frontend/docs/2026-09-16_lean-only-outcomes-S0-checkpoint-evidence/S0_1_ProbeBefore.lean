-- S0.1(a) BEFORE probe: the generated Inhabited defaults of the two PRODUCTION
-- outcome types at the mainline 721b1c2c7 (before any .lem change).
import Nondeterminism
set_option autoImplicit false

theorem before_t0_default_is_error {a : Type} :
    (default : t0 a) = Error default default := rfl

theorem before_kill_reason_default_is_undef0 {err : Type} :
    (default : kill_reason err) = Undef0 default default := rfl

#print axioms before_t0_default_is_error
#print axioms before_kill_reason_default_is_undef0
