import CerbFailProofs

namespace MemoryAccessProofs
open CerbMem CerbFail
set_option autoImplicit true

theorem stop_recordAccess (l k t p a addr bs v locking s) :
    stopObserving (recordAccess l k t p a addr bs v locking s) = stopObserving s := by
  cases h : s.observations <;> simp [recordAccess, h, stopObserving]

theorem disabled_recordAccess (l k t p a addr bs v locking s) :
    recordAccess l k t p a addr bs v locking (stopObserving s) = stopObserving s := rfl

def eraseNode (r : nd_action α String mem_error (mem_constraint IntegerValue) MemState × MemState) :=
  (r.1, stopObserving r.2)

-- These concern the actual primitives, for arbitrary memory, pointers, type
-- tables, values and caller-selected fuel — and, for the load, an arbitrary switch
-- set (PNVI arc S1: `loadM` reads `[CerbGlobal.Switches]`); no receipt-derived state model.
-- PNVI arc S2: `loadM` passes the `find_overlaping` closure `findOverlapping st`, which reads
-- the allocations and the dead list only — not the observation buffer.
-- PNVI arc S3: `loadM`/`storeM` gained the `Prov_symbolic` arms (`resolveIota`, then the
-- access on the post-resolution state) and the load's exposure arm (`exposeOnLoad`). The
-- proofs no longer unfold `stopObserving`: unfolding it over a non-variable state copies
-- that state into every field and the goals blow up (whnf timeout). Instead the erasure
-- is pushed through with the field lemmas below (all `rfl`) and `resolveIota`'s commuting
-- lemma, whose side condition — the arm's precondition does not read the observation
-- buffer — is `rfl`. Statements unchanged; no option bumps.
theorem stop_lastUsed (s : MemState) (u) :
    stopObserving { s with lastUsed := u } = { stopObserving s with lastUsed := u } := rfl
theorem stop_obs (s : MemState) : (stopObserving s).observations = none := rfl
theorem stop_dead (s : MemState) : (stopObserving s).deadAllocations = s.deadAllocations := rfl
theorem stop_allocs (s : MemState) : (stopObserving s).allocations = s.allocations := rfl
theorem stop_bytemap (s : MemState) : (stopObserving s).bytemap = s.bytemap := rfl
theorem stop_union (s : MemState) : (stopObserving s).lastUsedUnionMembers = s.lastUsedUnionMembers := rfl
theorem stop_funptr (s : MemState) : (stopObserving s).funptrmap = s.funptrmap := rfl
theorem stop_fo [CerbGlobal.Switches] (s : MemState) : findOverlapping (stopObserving s) = findOverlapping s :=
  findOverlapping_congr rfl rfl

theorem recordAccess_off (l k t p a addr bs v locking) (s : MemState) (h : s.observations = none) :
    recordAccess l k t p a addr bs v locking s = s := by simp [recordAccess, h]

theorem stop_exposeOnLoad [CerbGlobal.Switches] (t : ProvTaint) (s : MemState) :
    stopObserving (exposeOnLoad t s) = exposeOnLoad t (stopObserving s) := by
  unfold exposeOnLoad stopObserving; split <;> (try cases t) <;> rfl

theorem exposeOnLoad_obs [CerbGlobal.Switches] (t : ProvTaint) (s : MemState) :
    (exposeOnLoad t s).observations = s.observations := by
  unfold exposeOnLoad; split <;> (try cases t) <;> rfl

/-- `resolveIota` commutes with erasing the observation buffer, for a precondition that
    does not read it. -/
theorem stop_resolve (p : IotaPrecondFn) (hp : ∀ z s, p z (stopObserving s) = p z s) (iota : Int)
    (s : MemState) :
    resolveIota p iota (stopObserving s) =
      (match resolveIota p iota s with
       | .error k => .error k
       | .ok r => .ok (r.1, stopObserving r.2)) := by
  have hi : (stopObserving s).iotaMap = s.iotaMap := rfl
  simp only [resolveIota, lookupIota, hp, hi]
  split <;> simp_all <;> rfl

theorem load_erasure [LemFuel] [CerbGlobal.Switches] (es ts l t p s) :
    eraseNode (step (loadM es ts l t p) s) =
      step (loadM es ts l t p) (stopObserving s) := by
  unfold eraseNode
  simp only [CerbFail.step, loadM]
  split
  case h_5 =>
    -- the Prov_symbolic arm
    rw [stop_resolve _ (by intros; rfl)]
    split <;> (try simp only [stop_dead, stop_allocs, stop_bytemap, stop_union, stop_funptr, stop_fo, readBytesFrom])
    all_goals (repeat' first
      | simp_all only [stop_recordAccess, stop_exposeOnLoad, stop_lastUsed, stop_obs, exposeOnLoad_obs,
          recordAccess_off, stop_dead, stop_allocs, stop_bytemap, stop_union, stop_funptr, stop_fo]
      | split
      | rfl)
  all_goals (simp only [stop_dead, stop_allocs, stop_bytemap, stop_union, stop_funptr, stop_fo, readBytesFrom])
  all_goals (repeat' first
    | simp_all only [stop_recordAccess, stop_exposeOnLoad, stop_lastUsed, stop_obs, exposeOnLoad_obs,
        recordAccess_off, stop_dead, stop_allocs, stop_bytemap, stop_union, stop_funptr, stop_fo]
    | split
    | rfl)

theorem store_erasure [LemFuel] (es ts l t locking p v s) :
    eraseNode (step (storeM es ts l t locking p v) s) =
      step (storeM es ts l t locking p v) (stopObserving s) := by
  unfold eraseNode
  simp only [CerbFail.step, storeM]
  split
  · rfl
  · split
    case h_5 =>
      -- the Prov_symbolic arm
      rw [stop_resolve _ (by intros; rfl)]
      split <;> (try simp only [stop_allocs])
      all_goals (repeat' first
        | simp_all only [stop_recordAccess, stop_obs, recordAccess_off, stop_allocs, stop_funptr]
        | split
        | rfl)
    all_goals (repeat' first
      | simp_all only [stop_recordAccess, stop_obs, recordAccess_off, stop_allocs, stop_funptr]
      | split
      | rfl)

-- Existing liftND already carries the exact returned state, independently of
-- the action constructor. At zero fuel it does not evaluate the action; the
-- generated zero equation is a separate exhaustion contract.
theorem lift_returned_state (n : Nat) (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (info : info₁ → info₂) (err : err₁ → err₂)
    (m : ndM α info₁ err₁ cs st₁) (s : st₂) :
    (step (liftND_lemFuel (n + 1) get put info err m) s).2 =
      put s (step m (get s)).2 := by
  cases m with
  | ND f => simp [CerbFail.step, liftND_lemFuel]

#print axioms load_erasure
#print axioms store_erasure
#print axioms lift_returned_state

end MemoryAccessProofs
