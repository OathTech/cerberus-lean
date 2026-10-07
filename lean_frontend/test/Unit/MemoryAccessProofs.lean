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
theorem findOverlapping_observations [CerbGlobal.Switches] (s : MemState) (o : Option (List AccessReceipt)) :
    findOverlapping { s with observations := o } = findOverlapping s := rfl

theorem load_erasure [LemFuel] [CerbGlobal.Switches] (es ts l t p s) :
    eraseNode (step (loadM es ts l t p) s) =
      step (loadM es ts l t p) (stopObserving s) := by
  simp only [eraseNode, CerbFail.step, loadM, stopObserving, readBytesFrom, findOverlapping_observations]
  repeat' first | simp_all only [recordAccess] | split

theorem store_erasure [LemFuel] (es ts l t locking p v s) :
    eraseNode (step (storeM es ts l t locking p v) s) =
      step (storeM es ts l t locking p v) (stopObserving s) := by
  simp only [eraseNode, CerbFail.step, storeM, stopObserving, writeBytesTo]
  repeat' first | simp_all only [recordAccess] | split

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
