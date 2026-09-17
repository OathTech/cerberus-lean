import CerbMem

/-! # CerbMemAllocatorProofs — the concrete allocator's soundness contract

Hand-written proof seam beside its subject, `CerbMem.allocator` — the mirror of
`memory/concrete/impl_mem.ml:1247-1270` `allocator` after remedy 1 of upstream-tray
draft 44 (`docs/upstream-tray/44-concrete-allocator-euclidean-align-down-overlap-at-
exhaustion.md`; charter `docs/2026-09-16_charter-allocator-soundness-address-bound.md`
§2 C1(c); [USER 2026-09-16] "unambiguously wrong … allowed to fix ahead of upstream").

One GENERAL statement over every state, size and alignment, proved from the Euclidean
`Int` division facts (`Int.emod_nonneg`, `Int.emod_def`) and linear arithmetic —
never an enumeration over literals ([USER 2026-09-08]: nothing new out of policy). The
four draft-44 states are a RUNTIME test, `test/Unit/AllocatorSoundnessTest.lean`, which
imports this module so every `test_unit.sh` run compiles the theorem. Kernel-only
tactics (the D14-banned non-kernel decision procedures are absent — the axiom gate's
grep leg enforces it); no `decide` on literals as a load-bearing step; no option
bumps. Axioms: `propext`, `Classical.choice`, `Quot.sound` (the `omega` steps). -/

namespace CerbMem

/-- Observe the allocator's single monadic node on a state — the shape of
    `CerbFail.step` (CerbFailProofs.lean, which sits above `CerbND`), restated so
    this seam depends on `CerbMem` alone. -/
def allocatorStep (sz align : Int) (st : MemState) :
    nd_action (StorageInstanceId × Address) String mem_error
      (mem_constraint IntegerValue) MemState × MemState :=
  match allocator sz align with | ND f => f st

/-- Remedy 1 itself, in kernel terms: when the cursor is below the request the
    allocator KILLS with the out-of-memory error and leaves the state unchanged —
    the regime where pristine `b9aeedcb4` (impl_mem.ml:1253) could return an
    overlapping, misaligned address (draft 44). -/
theorem allocator_below_request_kills (st : MemState) (sz align : Int)
    (h : st.lastAddress - sz < 0) :
    allocatorStep sz align st =
      (NDkilled (Other (MerrOther "Concrete.allocator: failed (out of memory)")), st) := by
  simp [allocatorStep, allocator, h]

/-- The allocator's contract: an ACTIVE allocation `a` is `align`-aligned, strictly
    positive, its end `a + sz` at or below the cursor (`a + sz ≤ st.lastAddress` —
    disjoint from everything at or above the cursor, for `sz ≥ 0`; the statement
    itself needs no such hypothesis), and the new cursor is `a`.
    No hypothesis on `sz` or `align` is needed: `align = 0` is the refusal arm
    (never active), and for `align ≠ 0` the Euclidean remainder is non-negative, so
    the align-down step only lowers the base — the charter's
    `0 < align → 0 ≤ sz → …` form is this statement weakened. `id`/`a` are the
    `StorageInstanceId`/`Address` components, both abbrevs of `Int`; the relations
    are stated at `Int` (omega reads relations at `Int` only, not at an abbrev). -/
theorem allocator_active_sound (st st' : MemState) (sz align id a : Int)
    (h : allocatorStep sz align st = (NDactive (id, a), st')) :
    align ∣ a ∧ 0 < a ∧ a + sz ≤ (st.lastAddress : Int) ∧ st'.lastAddress = a := by
  simp only [allocatorStep, allocator] at h
  split at h
  · simp at h                       -- z < 0: the out-of-memory kill, never active
  · split at h
    · simp at h                     -- align == 0: the refusal, never active
    · rename_i hz hne
      split at h
      · simp at h                   -- z' ≤ 0: the out-of-memory kill, never active
      · rename_i hz'
        simp only [Prod.mk.injEq, nd_action.NDactive.injEq] at h
        obtain ⟨⟨_, ha⟩, hst⟩ := h
        subst ha
        subst hst
        have hne' : align ≠ 0 := fun heq => by simp [heq] at hne
        have hm := Int.emod_nonneg (st.lastAddress - sz) hne'
        have hdef := Int.emod_def (st.lastAddress - sz) align
        -- `hz'` is stated at the abbrev `Address`; omega reads relations at `Int`
        -- only, so restate it there, then name the two non-linear terms so the
        -- remaining facts are linear in atoms
        have hpos := Int.not_le.mp hz'
        generalize (st.lastAddress - sz) % align = M at hpos hm hdef ⊢
        generalize (st.lastAddress - sz) / align = Q at hdef ⊢
        refine ⟨⟨Q, ?_⟩, ?_, ?_, rfl⟩ <;> omega

end CerbMem
