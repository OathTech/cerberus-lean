import CerbFailProofs
import CerbMemAccessFacts

/-
  SC WP0 erasure pins (records docs/2026-09-25_sc-wp0-passive-access.md,
  docs/2026-09-26_sc-wp0-skeptical-review.md). Since 2026-10-08 the proofs live in
  the theorem-only seam `CerbMemAccessFacts` (consumer ask (c), cerberus-sl
  DECISIONS C3.399; record docs/2026-10-08_memory-access-facts-seam-record.md).
  Each theorem below keeps its pre-move name and its pre-move statement TEXT and is
  proved by the seam theorem — the kernel checks that the two statements agree (up
  to unfolding `eraseNode`, which the seam spells out because it has no `def`s).
-/

namespace MemoryAccessProofs
open CerbMem CerbFail
set_option autoImplicit true

theorem stop_recordAccess (l k t p a addr bs v locking s) :
    stopObserving (recordAccess l k t p a addr bs v locking s) = stopObserving s :=
  CerbMem.stopObserving_recordAccess l k t p a addr bs v locking s

theorem disabled_recordAccess (l k t p a addr bs v locking s) :
    recordAccess l k t p a addr bs v locking (stopObserving s) = stopObserving s :=
  CerbMem.recordAccess_stopObserving l k t p a addr bs v locking s

def eraseNode (r : nd_action α String mem_error (mem_constraint IntegerValue) MemState × MemState) :=
  (r.1, stopObserving r.2)

-- These concern the actual primitives, for arbitrary memory, pointers, type
-- tables, values and caller-selected fuel — and, for the load, an arbitrary switch
-- set (PNVI arc S1: `loadM` reads `[CerbGlobal.Switches]`); no receipt-derived state model.
-- The proof history (PNVI arcs S1–S3) is in the seam's comments.
theorem stop_lastUsed (s : MemState) (u) :
    stopObserving { s with lastUsed := u } = { stopObserving s with lastUsed := u } :=
  CerbMem.stopObserving_lastUsed s u
theorem stop_obs (s : MemState) : (stopObserving s).observations = none :=
  CerbMem.stopObserving_observations s
theorem stop_dead (s : MemState) : (stopObserving s).deadAllocations = s.deadAllocations :=
  CerbMem.stopObserving_deadAllocations s
theorem stop_allocs (s : MemState) : (stopObserving s).allocations = s.allocations :=
  CerbMem.stopObserving_allocations s
theorem stop_bytemap (s : MemState) : (stopObserving s).bytemap = s.bytemap :=
  CerbMem.stopObserving_bytemap s
theorem stop_union (s : MemState) : (stopObserving s).lastUsedUnionMembers = s.lastUsedUnionMembers :=
  CerbMem.stopObserving_lastUsedUnionMembers s
theorem stop_funptr (s : MemState) : (stopObserving s).funptrmap = s.funptrmap :=
  CerbMem.stopObserving_funptrmap s
theorem stop_fo [CerbGlobal.Switches] (s : MemState) : findOverlapping (stopObserving s) = findOverlapping s :=
  CerbMem.findOverlapping_stopObserving s

theorem recordAccess_off (l k t p a addr bs v locking) (s : MemState) (h : s.observations = none) :
    recordAccess l k t p a addr bs v locking s = s :=
  CerbMem.recordAccess_of_observations_none l k t p a addr bs v locking s h

theorem stop_exposeOnLoad [CerbGlobal.Switches] (t : ProvTaint) (s : MemState) :
    stopObserving (exposeOnLoad t s) = exposeOnLoad t (stopObserving s) :=
  CerbMem.stopObserving_exposeOnLoad t s

theorem exposeOnLoad_obs [CerbGlobal.Switches] (t : ProvTaint) (s : MemState) :
    (exposeOnLoad t s).observations = s.observations :=
  CerbMem.exposeOnLoad_observations t s

/-- `resolveIota` commutes with erasing the observation buffer, for a precondition that
    does not read it. -/
theorem stop_resolve (p : IotaPrecondFn) (hp : ∀ z s, p z (stopObserving s) = p z s) (iota : Int)
    (s : MemState) :
    resolveIota p iota (stopObserving s) =
      (match resolveIota p iota s with
       | .error k => .error k
       | .ok r => .ok (r.1, stopObserving r.2)) :=
  CerbMem.resolveIota_stopObserving p hp iota s

theorem load_erasure [LemFuel] [CerbGlobal.Switches] (es ts l t p s) :
    eraseNode (step (loadM es ts l t p) s) =
      step (loadM es ts l t p) (stopObserving s) :=
  CerbMem.loadM_erasure es ts l t p s

theorem store_erasure [LemFuel] (es ts l t locking p v s) :
    eraseNode (step (storeM es ts l t locking p v) s) =
      step (storeM es ts l t locking p v) (stopObserving s) :=
  CerbMem.storeM_erasure es ts l t locking p v s

-- Existing liftND already carries the exact returned state, independently of
-- the action constructor. At zero fuel it does not evaluate the action; the
-- generated zero equation is a separate exhaustion contract.
theorem lift_returned_state (n : Nat) (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (info : info₁ → info₂) (err : err₁ → err₂)
    (m : ndM α info₁ err₁ cs st₁) (s : st₂) :
    (step (liftND_lemFuel (n + 1) get put info err m) s).2 =
      put s (step m (get s)).2 :=
  CerbMem.liftND_returned_state n get put info err m s

#print axioms load_erasure
#print axioms store_erasure
#print axioms lift_returned_state

end MemoryAccessProofs
