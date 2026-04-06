/-
  C11 concurrency memory model stubs.
  Corresponds to: frontend/concurrency/cmm_csem.lem

  The OCaml backend implements the full C11 memory model with
  various consistency models (SC, release-acquire, relaxed, etc.).
  For the initial Lean port, we provide minimal implementations
  that return empty/default behaviours. Full concurrency support
  can be added following the OCaml implementation.

  This is a leaf module — no imports from generated code.
  Functions use polymorphic types to avoid import cycles.
-/

namespace CerbConcurrency

-- All concurrency functions are polymorphic to avoid importing
-- the generated types (which would create cycles).

def statically_satisfied {α β γ : Type} (_ : α) (_ : β) (_ : γ) : Bool := true

-- The behaviour functions all return program_behaviours.
-- Since these types are generated, we use polymorphic return.
-- The actual ndM monad wiring will use sorry for the return type.

-- For now, all behaviour functions are sorry because they need
-- the full concurrency model types which are deeply interconnected
-- with the memory model. These are only needed for concurrent
-- C programs.

end CerbConcurrency
