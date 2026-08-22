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

-- TEMPORAL BOUNDARY (comment corrected arc-14 S1 F6, sem:N5 — the old
-- text claimed these functions "use sorry"/"are sorry", which is both
-- stale and forbidden: sorry is banned tree-wide and DAEMON was
-- executed). Reality: `statically_satisfied` is a total stub returning
-- `true`; the concurrency behaviour surface is not modelled — the full
-- concurrency model types are deeply interconnected with the memory
-- model and are only exercised by concurrent C programs, which the
-- pipeline does not run. This is a declared TEMPORAL boundary entry
-- (expected mover: the concurrency arc; forward-design constraint:
-- Layer-2/3 shapes must not bake in single-thread/SC assumptions).

end CerbConcurrency
