/-
  CerbMemAccessFacts — the SC WP0 load/store erasure facts as a citable library
  seam (2026-10-08; consumer ask (c), cerberus-sl DECISIONS C3.399; operator
  [USER 2026-10-08] "Yes go ahead"; record
  docs/2026-10-08_memory-access-facts-seam-record.md).

  A THEOREM-ONLY seam a consumer imports beside `CerbMem`, on the
  `CerbMemDefaultFacts` precedent: no definition here; kernel-only tactics, no
  option bumps. The statements are the SC WP0 proofs of
  `test/Unit/MemoryAccessProofs.lean` (records docs/2026-09-25_sc-wp0-passive-access.md,
  docs/2026-09-26_sc-wp0-skeptical-review.md), moved here unchanged in content and
  renamed for citation; the test module restates each one under its old name with
  its old text, proved by the seam theorem (a kernel check that the two statements
  agree up to definitional unfolding — the only change is that `loadM_erasure` /
  `storeM_erasure` spell out the test's `eraseNode` helper, since a seam has no
  `def`s).

  What it says: the observation buffer (`MemState.observations`) is PASSIVE —
  erasing it (`stopObserving`) before a `loadM`/`storeM` step gives the same
  action and the same post-state as erasing it afterwards. A consumer whose heap
  well-formedness carries `σ.observations = none` can therefore treat the
  receipt-recording as the identity (`recordAccess_of_observations_none`) and
  the primitives as unaffected by it.

  Exported names (namespace `CerbMem`):
    loadM_erasure                         erasure commutes with a `loadM` step
    storeM_erasure                        erasure commutes with a `storeM` step
    stopObserving_recordAccess            erasure absorbs `recordAccess`
    recordAccess_stopObserving            `recordAccess` on an erased state is the identity
    recordAccess_of_observations_none     `recordAccess` is the identity when `observations = none`
    stopObserving_lastUsed                erasure commutes with a `lastUsed` update
    stopObserving_observations            the erased buffer is `none`
    stopObserving_deadAllocations         erasure preserves `deadAllocations`
    stopObserving_allocations             erasure preserves `allocations`
    stopObserving_bytemap                 erasure preserves `bytemap`
    stopObserving_lastUsedUnionMembers    erasure preserves `lastUsedUnionMembers`
    stopObserving_funptrmap               erasure preserves `funptrmap`
    findOverlapping_stopObserving         `findOverlapping` ignores the buffer
    stopObserving_exposeOnLoad            erasure commutes with `exposeOnLoad`
    exposeOnLoad_observations             `exposeOnLoad` leaves the buffer unchanged
    resolveIota_stopObserving             `resolveIota` commutes with erasure (buffer-blind precondition)
    liftND_returned_state                 a fuelled `liftND` step returns `put s` of the inner step's state
  Old test names (MemoryAccessProofs.*), in the same order: load_erasure,
  store_erasure, stop_recordAccess, disabled_recordAccess, recordAccess_off,
  stop_lastUsed, stop_obs, stop_dead, stop_allocs, stop_bytemap, stop_union,
  stop_funptr, stop_fo, stop_exposeOnLoad, exposeOnLoad_obs, stop_resolve,
  lift_returned_state.

  Pinned in the axiom census (scripts/check_theorem_axioms.sh, mem-scale leg),
  cones ⊆ [propext, Classical.choice, Quot.sound]; compiled in row 1 because
  test/Unit/MemoryAccessProofs.lean (built by `memory-access-test`) imports it.
  Not in W2's exclusion list: it names no default-pinned wrapper.
-/
import CerbMem
import CerbFailProofs

namespace CerbMem
open CerbFail

set_option autoImplicit true

/-! ## `recordAccess` and erasure -/

theorem stopObserving_recordAccess (l k t p a addr bs v locking s) :
    stopObserving (recordAccess l k t p a addr bs v locking s) = stopObserving s := by
  cases h : s.observations <;> simp [recordAccess, h, stopObserving]

theorem recordAccess_stopObserving (l k t p a addr bs v locking s) :
    recordAccess l k t p a addr bs v locking (stopObserving s) = stopObserving s := rfl

/-! ## Field lemmas (all `rfl`)

PNVI arc S3: the erasure proofs do not unfold `stopObserving` — unfolding it over a
non-variable state copies that state into every field and the goals blow up (whnf
timeout). Instead the erasure is pushed through with these field lemmas and
`resolveIota`'s commuting lemma, whose side condition — the arm's precondition does not
read the observation buffer — is `rfl`. -/

theorem stopObserving_lastUsed (s : MemState) (u) :
    stopObserving { s with lastUsed := u } = { stopObserving s with lastUsed := u } := rfl
theorem stopObserving_observations (s : MemState) : (stopObserving s).observations = none := rfl
theorem stopObserving_deadAllocations (s : MemState) : (stopObserving s).deadAllocations = s.deadAllocations := rfl
theorem stopObserving_allocations (s : MemState) : (stopObserving s).allocations = s.allocations := rfl
theorem stopObserving_bytemap (s : MemState) : (stopObserving s).bytemap = s.bytemap := rfl
theorem stopObserving_lastUsedUnionMembers (s : MemState) : (stopObserving s).lastUsedUnionMembers = s.lastUsedUnionMembers := rfl
theorem stopObserving_funptrmap (s : MemState) : (stopObserving s).funptrmap = s.funptrmap := rfl
theorem findOverlapping_stopObserving [CerbGlobal.Switches] (s : MemState) : findOverlapping (stopObserving s) = findOverlapping s :=
  findOverlapping_congr rfl rfl

theorem recordAccess_of_observations_none (l k t p a addr bs v locking) (s : MemState) (h : s.observations = none) :
    recordAccess l k t p a addr bs v locking s = s := by simp [recordAccess, h]

theorem stopObserving_exposeOnLoad [CerbGlobal.Switches] (t : ProvTaint) (s : MemState) :
    stopObserving (exposeOnLoad t s) = exposeOnLoad t (stopObserving s) := by
  unfold exposeOnLoad stopObserving; split <;> (try cases t) <;> rfl

theorem exposeOnLoad_observations [CerbGlobal.Switches] (t : ProvTaint) (s : MemState) :
    (exposeOnLoad t s).observations = s.observations := by
  unfold exposeOnLoad; split <;> (try cases t) <;> rfl

/-- `resolveIota` commutes with erasing the observation buffer, for a precondition that
    does not read it. -/
theorem resolveIota_stopObserving (p : IotaPrecondFn) (hp : ∀ z s, p z (stopObserving s) = p z s) (iota : Int)
    (s : MemState) :
    resolveIota p iota (stopObserving s) =
      (match resolveIota p iota s with
       | .error k => .error k
       | .ok r => .ok (r.1, stopObserving r.2)) := by
  have hi : (stopObserving s).iotaMap = s.iotaMap := rfl
  simp only [resolveIota, lookupIota, hp, hi]
  split <;> simp_all <;> rfl

/-! ## The primitives

For arbitrary memory, pointers, type tables, values, caller-selected fuel and (for the
load) an arbitrary switch set; no receipt-derived state model. The left side is the
test module's `eraseNode (step …)` written out: `(r.1, stopObserving r.2)` for
`r := step … s`. -/

/-- Erasing the observation buffer commutes with a `loadM` step: same action, same
    post-state up to erasure. -/
theorem loadM_erasure [LemFuel] [CerbGlobal.Switches] (es ts l t p s) :
    ((step (loadM es ts l t p) s).1, stopObserving (step (loadM es ts l t p) s).2) =
      step (loadM es ts l t p) (stopObserving s) := by
  simp only [CerbFail.step, loadM]
  split
  case h_5 =>
    -- the Prov_symbolic arm
    rw [resolveIota_stopObserving _ (by intros; rfl)]
    split <;> (try simp only [stopObserving_deadAllocations, stopObserving_allocations, stopObserving_bytemap,
      stopObserving_lastUsedUnionMembers, stopObserving_funptrmap, findOverlapping_stopObserving, readBytesFrom])
    all_goals (repeat' first
      | simp_all only [stopObserving_recordAccess, stopObserving_exposeOnLoad, stopObserving_lastUsed,
          stopObserving_observations, exposeOnLoad_observations, recordAccess_of_observations_none,
          stopObserving_deadAllocations, stopObserving_allocations, stopObserving_bytemap,
          stopObserving_lastUsedUnionMembers, stopObserving_funptrmap, findOverlapping_stopObserving]
      | split
      | rfl)
  all_goals (simp only [stopObserving_deadAllocations, stopObserving_allocations, stopObserving_bytemap,
    stopObserving_lastUsedUnionMembers, stopObserving_funptrmap, findOverlapping_stopObserving, readBytesFrom])
  all_goals (repeat' first
    | simp_all only [stopObserving_recordAccess, stopObserving_exposeOnLoad, stopObserving_lastUsed,
        stopObserving_observations, exposeOnLoad_observations, recordAccess_of_observations_none,
        stopObserving_deadAllocations, stopObserving_allocations, stopObserving_bytemap,
        stopObserving_lastUsedUnionMembers, stopObserving_funptrmap, findOverlapping_stopObserving]
    | split
    | rfl)

/-- Erasing the observation buffer commutes with a `storeM` step: same action, same
    post-state up to erasure. -/
theorem storeM_erasure [LemFuel] (es ts l t locking p v s) :
    ((step (storeM es ts l t locking p v) s).1, stopObserving (step (storeM es ts l t locking p v) s).2) =
      step (storeM es ts l t locking p v) (stopObserving s) := by
  simp only [CerbFail.step, storeM]
  split
  · rfl
  · split
    case h_5 =>
      -- the Prov_symbolic arm
      rw [resolveIota_stopObserving _ (by intros; rfl)]
      split <;> (try simp only [stopObserving_allocations])
      all_goals (repeat' first
        | simp_all only [stopObserving_recordAccess, stopObserving_observations, recordAccess_of_observations_none,
            stopObserving_allocations, stopObserving_funptrmap]
        | split
        | rfl)
    all_goals (repeat' first
      | simp_all only [stopObserving_recordAccess, stopObserving_observations, recordAccess_of_observations_none,
          stopObserving_allocations, stopObserving_funptrmap]
      | split
      | rfl)

/-! ## `liftND`

Existing liftND already carries the exact returned state, independently of the action
constructor. At zero fuel it does not evaluate the action; the generated zero equation
is a separate exhaustion contract. -/

theorem liftND_returned_state (n : Nat) (get : st₂ → st₁) (put : st₂ → st₁ → st₂)
    (info : info₁ → info₂) (err : err₁ → err₂)
    (m : ndM α info₁ err₁ cs st₁) (s : st₂) :
    (step (liftND_lemFuel (n + 1) get put info err m) s).2 =
      put s (step m (get s)).2 := by
  cases m with
  | ND f => simp [CerbFail.step, liftND_lemFuel]

end CerbMem
