import Undefined
set_option autoImplicit false

theorem existing_default_is_error {α : Type} :
    (default : t0 α) = Error default default := rfl
#print axioms existing_default_is_error
