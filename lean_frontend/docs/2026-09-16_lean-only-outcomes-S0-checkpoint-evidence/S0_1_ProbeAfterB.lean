-- S0.1(b) CANDIDATE probe: `declare {lean} skip_instances type interp_stop` +
-- hand-written BEq/Ord/SetType/Eq0/Ord0 (CerbStopInstances.lean) and NO
-- `Inhabited interp_stop`. Expected if the candidate works: the two defaults
-- are today's (`Error default default` / `Undef0 default default`), and
-- `Inhabited interp_stop` cannot be synthesized.
import Nondeterminism
set_option autoImplicit false

theorem afterB_t0_default_is_error {a : Type} :
    (default : t0 a) = Error default default := rfl

theorem afterB_kill_reason_default_is_undef0 {err : Type} :
    (default : kill_reason err) = Undef0 default default := rfl

theorem afterB_t0_nat_default_is_defined :
    (default : t0 Nat) = Defined 0 := rfl

-- comparison parity spot checks on the hand-written instances
example : (Exhausted == Exhausted) = true := rfl
example : (Exhausted == FailStop "x") = false := rfl
example : compare Exhausted (FailStop "x") = .lt := rfl
example : compare (FailStop "b") (FailStop "a") = .gt := by decide
example : compare (Unsupported UF_filesystem "a") (Unsupported UF_concurrency "a") = .lt := by decide

#print axioms afterB_t0_default_is_error
#print axioms afterB_kill_reason_default_is_undef0
#print axioms afterB_t0_nat_default_is_defined
