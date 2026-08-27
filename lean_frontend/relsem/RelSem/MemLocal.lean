/-
  RelSem.MemLocal — arc-16 S2 (2026-08-24): the PHYSICAL locality layer
  under the CerbMem heap RA (design record:
  docs/2026-08-24_arc16-s2-cerbmem-heap-ra.md §2.3 layer 1).

  Everything here is about CerbMem.MemState only — pointwise
  characterizations of the byte-write/read helpers, the memory
  well-formedness invariant `MemInv` the state interpretation carries
  (the Caesium `heap_state_invariant` pattern, subsetted to what the
  four op rules consume), and its preservation across the four
  operation post-states of the arc-9 law table (RelSem.Kit.Mem's
  `mem_alloc_block` / `mem_store_block` / `mem_load_block` /
  `mem_kill_block` — REUSED, not restated).

  Import discipline: no Iris (mirrors RelSem/Machine.lean); the ghost
  coupling lives in RelSem/CerbHeapRA.lean.

  House rules: no sorry, no axioms declared. Under the in-build audit.
-/

import RelSem.Machine
import RelSem.Kit.Mem

set_option autoImplicit false

namespace RelSem
namespace Cerb

open CerbMem (MemState AbsByte Allocation)

/-! ## Sequential byte writes, induction-friendly form -/

/-- `writeBytesTo`'s byte-map effect as list recursion (the foldl in
    the generated-facing def pairs the running address into the
    accumulator; this form exposes the structure the per-byte ghost
    update inducts on). -/
def writeList (t : Std.TreeMap Int AbsByte) (a : Int) :
    List AbsByte → Std.TreeMap Int AbsByte
  | [] => t
  | b :: bs => writeList (t.insert a b) (a + 1) bs

private theorem writeBytesTo_foldl_fst (bs : List AbsByte)
    (t : Std.TreeMap Int AbsByte) (a : Int) :
    (bs.foldl
      (fun (acc : Std.TreeMap Int AbsByte × Int) b =>
        (acc.1.insert acc.2 b, acc.2 + 1)) (t, a)).1
      = writeList t a bs := by
  induction bs generalizing t a with
  | nil => rfl
  | cons b bs ih => exact ih (t.insert a b) (a + 1)

/-- `writeBytesTo` touches ONLY the bytemap, and its effect is
    `writeList`. -/
theorem writeBytesTo_eq (st : MemState) (a : Int) (bs : List AbsByte) :
    CerbMem.writeBytesTo st a bs
      = { st with bytemap := writeList st.bytemap a bs } := by
  simp only [CerbMem.writeBytesTo, writeBytesTo_foldl_fst]

/-- Keys outside the written range are untouched. -/
theorem writeList_get?_notin (bs : List AbsByte)
    (t : Std.TreeMap Int AbsByte) (a k : Int)
    (h : k < a ∨ a + bs.length ≤ k) :
    (writeList t a bs).get? k = t.get? k := by
  induction bs generalizing t a with
  | nil => rfl
  | cons b bs ih =>
    have hrec : (writeList t a (b :: bs)).get? k
        = (t.insert a b).get? k := by
      simp only [List.length_cons] at h
      exact ih (t.insert a b) (a + 1) (by omega)
    rw [hrec]
    simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert]
    rw [if_neg]
    intro hc
    have : a = k := Std.LawfulEqCmp.eq_of_compare hc
    simp only [List.length_cons] at h
    omega

/-- Keys inside the written range read back the written byte. -/
theorem writeList_get?_in (bs : List AbsByte)
    (t : Std.TreeMap Int AbsByte) (a k : Int)
    (h₁ : a ≤ k) (h₂ : k < a + bs.length) :
    (writeList t a bs).get? k = bs[(k - a).toNat]? := by
  induction bs generalizing t a with
  | nil => simp only [List.length_nil] at h₂; omega
  | cons b bs ih =>
    by_cases hk : k = a
    · subst hk
      have hrec : (writeList t k (b :: bs)).get? k
          = (t.insert k b).get? k :=
        writeList_get?_notin bs (t.insert k b) (k + 1) k (.inl (by omega))
      rw [hrec]
      simp
    · have hrec : (writeList t a (b :: bs)).get? k
          = bs[(k - (a + 1)).toNat]? := by
        simp only [List.length_cons] at h₂
        exact ih (t.insert a b) (a + 1) (by omega) (by omega)
      rw [hrec]
      have hidx : (k - a).toNat = ((k - (a + 1)).toNat) + 1 := by omega
      rw [hidx, List.getElem?_cons_succ]

/-- `readBytesFrom` is determined by pointwise byte-map facts. -/
theorem readBytesFrom_of_pointwise {st : MemState} {a : Int}
    {bs : List AbsByte} {size : Nat}
    (hlen : bs.length = size)
    (h : ∀ i : Nat, (hi : i < bs.length) →
      st.bytemap.get? (a + (i : Int)) = some bs[i]) :
    CerbMem.readBytesFrom st a size = bs := by
  subst hlen
  unfold CerbMem.readBytesFrom
  apply List.ext_getElem
  · simp
  · intro i h₁ h₂
    simp only [List.getElem_map, List.getElem_range]
    rw [h i (by simpa using h₁)]

/-! ## The allocate success-path arithmetic -/

/-- The fresh range `[a, a + sz)` sits at or below the old water mark:
    `alignDown x al ≤ x`, plus the success guard `a ≠ 0` ruling out
    the exhausted case. Consumed by `MemInv.alloc` and by the ghost
    byte-alloc freshness. -/
theorem alloc_range_le {last : Int}
    {sz : Nat} {a : Int} {alignN : Int}
    (haddr : ((CerbMem.alignDown (last - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false) :
    a + sz ≤ last := by
  have hle : CerbMem.alignDown (last - sz).toNat (alignN.toNat.max 1)
      ≤ (last - sz).toNat := by
    unfold CerbMem.alignDown
    exact Nat.div_mul_le_self _ _
  have hnz' : a ≠ 0 := by
    intro h0; rw [h0] at hnz; simp at hnz
  omega


/-! ## The ambient-`==` bridge (measured, this environment)

    Inside the generated import closure the winning `BEq Int` instance
    is the Lem jungle's `Lem_Basic_classes.instBEqOfEq0` whose chain
    bottoms out in `instBEqOfSetType ∘ instSetTypeOfOrd`: the ambient
    `x == y` on `Int` is COMPARE-BASED (`defaultCompare` over the core
    `Ord Int`), not the core `decide`-based beq — and it is NOT
    defeq-bridgeable to the core instance at elaboration transparency.
    CerbMem's own `contains`/`==` sites were elaborated under the same
    jungle, so these two lemmas are the lawfulness bridge every
    resource-rule side condition about them goes through. -/

private def ordEqBool : Ordering → Bool
  | .eq => true
  | _ => false

/-- The ambient `Int` beq computes `compare`-equality. -/
theorem lem_int_beq_unfold (x y : Int) :
    (x == y) = ordEqBool (compare x y) := by
  simp only [BEq.beq, Lem_Basic_classes.isEqual,
    Lem_Basic_classes.setElemCompare, defaultCompare, ordEqBool]
  cases compare x y <;> rfl

theorem lem_int_beq_eq_true_iff (x y : Int) : (x == y) = true ↔ x = y := by
  rw [lem_int_beq_unfold]
  constructor
  · intro h
    cases hc : compare x y with
    | eq => exact Std.LawfulEqCmp.eq_of_compare hc
    | lt => rw [hc] at h; exact Bool.noConfusion h
    | gt => rw [hc] at h; exact Bool.noConfusion h
  · intro h
    subst h
    rw [Std.ReflCmp.compare_self (cmp := (compare : Int → Int → Ordering))
      (a := x)]
    rfl

theorem lem_int_beq_eq_false_iff (x y : Int) : (x == y) = false ↔ x ≠ y := by
  constructor
  · intro h he
    subst he
    rw [lem_int_beq_unfold,
      Std.ReflCmp.compare_self (cmp := (compare : Int → Int → Ordering))
        (a := x)] at h
    exact Bool.noConfusion h
  · intro hne
    cases hb : (x == y) with
    | false => rfl
    | true => exact absurd ((lem_int_beq_eq_true_iff x y).mp hb) hne

/-- `List.contains` under the ambient beq, from non-membership. -/
theorem lem_int_contains_eq_false_of_not_mem {l : List Int} {x : Int}
    (h : x ∉ l) : l.contains x = false := by
  induction l with
  | nil => rfl
  | cons a as ih =>
    have hne : x ≠ a := fun he => h (he ▸ List.mem_cons_self ..)
    have hnm : x ∉ as := fun hm => h (List.mem_cons_of_mem a hm)
    simp only [List.contains_cons]
    rw [(lem_int_beq_eq_false_iff x a).mpr hne, ih hnm]
    rfl

/-! ## The memory invariant (the state interpretation's pure conjunct;
    consumers per conjunct in the design record §2.2) -/

structure MemInv (ms : MemState) : Prop where
  /-- Every live allocation id is below the bump counter (alloc-table
      ghost-insert freshness at allocate). NOTE all comparisons are
      pinned to `Int` explicitly: the `Address`/`StorageInstanceId`
      abbrevs otherwise become the binop type and `omega` (in the
      package build environment) treats them as foreign atoms. -/
  alloc_lt : ∀ (aid : Int) (al : Allocation),
    ms.allocations.get? aid = some al → aid < (ms.nextAllocId : Int)
  /-- Dead ids are not in the allocation table (an `allocIs` fragment
      certifies liveness — the dead-check branches are unreachable). -/
  dead_not_alloc : ∀ (aid : Int), aid ∈ ms.deadAllocations →
    ms.allocations.get? aid = none
  /-- Dead ids are below the bump counter (preserves `dead_not_alloc`
      across allocate). -/
  dead_lt : ∀ (aid : Int), aid ∈ ms.deadAllocations →
    aid < (ms.nextAllocId : Int)
  /-- Every mapped byte address sits at or above the bump allocator's
      water mark (byte ghost-alloc freshness at allocate: new ranges
      are strictly below it). -/
  bytes_above : ∀ (a : Int) (b : AbsByte),
    ms.bytemap.get? a = some b → (ms.lastAddress : Int) ≤ a

namespace MemInv

/-- The next allocation id is fresh in the allocation table. -/
theorem next_fresh {ms : MemState} (h : MemInv ms) :
    ms.allocations.get? ms.nextAllocId = none := by
  cases hg : ms.allocations.get? ms.nextAllocId with
  | none => rfl
  | some al => exact absurd (h.alloc_lt _ _ hg) (by omega)

/-- A live allocation id is not on the dead list (Bool form: the
    `hdead` premise of the load/kill blocks). -/
theorem contains_dead_false {ms : MemState} (h : MemInv ms)
    {aid : Int} {al : Allocation}
    (hget : ms.allocations.get? aid = some al) :
    ms.deadAllocations.contains aid = false := by
  by_cases hmem : aid ∈ ms.deadAllocations
  · rw [h.dead_not_alloc aid hmem] at hget
    cases hget
  · exact lem_int_contains_eq_false_of_not_mem hmem

/-- Fresh-range byte freshness: addresses strictly below the water
    mark are unmapped. -/
theorem bytemap_below_none {ms : MemState} (h : MemInv ms)
    {k : Int} (hk : k < ms.lastAddress) :
    ms.bytemap.get? k = none := by
  cases hg : ms.bytemap.get? k with
  | none => rfl
  | some b =>
    exfalso
    exact absurd (h.bytes_above _ _ hg) (Int.not_le.mpr hk)

/-! ### Preservation across the four op post-states -/

/-- STORE (the `mem_store_block` post-state): writes land on already
    mapped keys (the rule holds full points-to for the old range), so
    the byte key set — and every invariant-relevant component — is
    unchanged. -/
theorem store {ms : MemState} (h : MemInv ms)
    {fpm : CerbMem.Funptrmap} {a : Int} {newBs oldBs : List AbsByte}
    (hlen : newBs.length = oldBs.length)
    (hold : ∀ i : Nat, (hi : i < oldBs.length) →
      ms.bytemap.get? (a + (i : Int)) = some oldBs[i]) :
    MemInv (CerbMem.writeBytesTo { ms with funptrmap := fpm } a newBs) := by
  rw [writeBytesTo_eq]
  refine ⟨h.alloc_lt, h.dead_not_alloc, h.dead_lt, ?_⟩
  intro k b hk
  replace hk : (writeList ms.bytemap a newBs).get? k = some b := hk
  show (ms.lastAddress : Int) ≤ k
  by_cases hin : a ≤ k ∧ k < a + newBs.length
  · -- a written key: it was already mapped, hence already above the mark
    have hi : (k - a).toNat < oldBs.length := by omega
    have hpt := hold (k - a).toNat hi
    have hcast : a + (((k - a).toNat : Nat) : Int) = k := by omega
    rw [hcast] at hpt
    exact h.bytes_above k _ hpt
  · rw [writeList_get?_notin newBs _ a k (by omega)] at hk
    exact h.bytes_above k b hk

/-- ALLOCATE (the `mem_alloc_block` post-state, `initOpt = none`):
    the arithmetic premises are exactly the block's. -/
theorem alloc {ms : MemState} (h : MemInv ms)
    {pref : prefix0} {ty : ctype} {alignN : Int} {sz : Nat} {a : Int}
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (ms.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false) :
    MemInv (CerbMem.writeBytesTo
      { ms with
        nextAllocId := ms.nextAllocId + 1,
        lastAddress := a,
        allocations := ms.allocations.insert ms.nextAllocId
          { base := a, size := sz, ty := some ty, prefix_ := pref } }
      a (List.replicate sz
          { prov := .Prov_none, copyOffset := none, value := none })) := by
  have hrange : a + sz ≤ ms.lastAddress := alloc_range_le haddr hnz
  rw [writeBytesTo_eq]
  constructor
  · intro aid al hget
    replace hget : (ms.allocations.insert ms.nextAllocId
        { base := a, size := sz, ty := some ty,
          prefix_ := pref }).get? aid = some al := hget
    show aid < (ms.nextAllocId : Int) + 1
    simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert] at hget
    split at hget
    · next heq =>
      cases Std.LawfulEqCmp.eq_of_compare heq
      omega
    · have := h.alloc_lt aid al (by
        simpa [Std.TreeMap.get?_eq_getElem?] using hget)
      omega
  · intro aid hmem
    replace hmem : aid ∈ ms.deadAllocations := hmem
    show (ms.allocations.insert ms.nextAllocId
        { base := a, size := sz, ty := some ty,
          prefix_ := pref }).get? aid = none
    have hlt := h.dead_lt aid hmem
    simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert]
    rw [if_neg]
    · have := h.dead_not_alloc aid hmem
      simpa [Std.TreeMap.get?_eq_getElem?] using this
    · intro heq
      cases Std.LawfulEqCmp.eq_of_compare heq
      omega
  · intro aid hmem
    replace hmem : aid ∈ ms.deadAllocations := hmem
    show aid < (ms.nextAllocId : Int) + 1
    have := h.dead_lt aid hmem
    omega
  · intro k b hk
    replace hk : (writeList ms.bytemap a
        (List.replicate sz
          { prov := .Prov_none, copyOffset := none,
            value := none })).get? k = some b := hk
    show (a : Int) ≤ k
    by_cases hin : a ≤ k ∧ k < a + sz
    · omega
    · rw [writeList_get?_notin _ _ a k
        (by simp only [List.length_replicate]; omega)] at hk
      have hlk : @LE.le Int Int.instLEInt ms.lastAddress k :=
        h.bytes_above k b hk
      omega

/-- KILL (the `mem_kill_block` post-state): the allocation is erased
    and its id pushed on the dead list; bytes untouched. -/
theorem kill {ms : MemState} (h : MemInv ms)
    {aid : Int} {al : Allocation}
    (hget : ms.allocations.get? aid = some al) :
    MemInv { ms with
      deadAllocations := aid :: ms.deadAllocations,
      allocations := ms.allocations.erase aid } := by
  constructor
  · intro aid' al' hget'
    simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_erase] at hget'
    split at hget'
    · cases hget'
    · exact h.alloc_lt aid' al' (by
        simpa [Std.TreeMap.get?_eq_getElem?] using hget')
  · intro aid' hmem
    simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_erase]
    rcases List.mem_cons.mp hmem with rfl | hmem'
    · rw [if_pos Std.ReflCmp.compare_self]
    · split
      · rfl
      · have := h.dead_not_alloc aid' hmem'
        simpa [Std.TreeMap.get?_eq_getElem?] using this
  · intro aid' hmem
    rcases List.mem_cons.mp hmem with rfl | hmem'
    · exact h.alloc_lt aid' al hget
    · exact h.dead_lt aid' hmem'
  · exact h.bytes_above

end MemInv

/-! ## The two-scratch allocation chain (arc-18 R4, the scratch2 walk
    rule's physical layer): `get?` over the insert-insert-erase-erase
    allocation chain, and `MemInv` for a post-state characterized
    POINTWISE against the pre-state (the C3b scratch2 design note's
    prescription — n-fold write ladders enter as pointwise byte facts,
    never as a canonical term shape). -/

theorem tm_get?_ii_ee_ne {am : Std.TreeMap Int Allocation}
    {nidA nidB aid : Int} {alA alB : Allocation}
    (h1 : aid ≠ nidA) (h2 : aid ≠ nidB) :
    ((((am.insert nidA alA).insert nidB alB).erase nidB).erase
        nidA).get? aid = am.get? aid := by
  simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_erase,
    Std.TreeMap.getElem?_insert]
  rw [if_neg (fun hc => h1 (Std.LawfulEqCmp.eq_of_compare hc).symm),
    if_neg (fun hc => h2 (Std.LawfulEqCmp.eq_of_compare hc).symm),
    if_neg (fun hc => h2 (Std.LawfulEqCmp.eq_of_compare hc).symm),
    if_neg (fun hc => h1 (Std.LawfulEqCmp.eq_of_compare hc).symm)]

theorem tm_get?_ii_ee_a {am : Std.TreeMap Int Allocation}
    {nidA nidB : Int} {alA alB : Allocation} :
    ((((am.insert nidA alA).insert nidB alB).erase nidB).erase
        nidA).get? nidA = none := by
  simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_erase]
  rw [if_pos Std.ReflCmp.compare_self]

theorem tm_get?_ii_ee_b {am : Std.TreeMap Int Allocation}
    {nidA nidB : Int} {alA alB : Allocation} (hne : nidB ≠ nidA) :
    ((((am.insert nidA alA).insert nidB alB).erase nidB).erase
        nidA).get? nidB = none := by
  simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_erase]
  rw [if_neg (fun hc => hne (Std.LawfulEqCmp.eq_of_compare hc).symm),
    if_pos Std.ReflCmp.compare_self]

/-- MemInv for a TWO-SCRATCH post-state characterized pointwise: two
    fresh allocations created and killed inside one atom (allocation
    chain insert-insert-erase-erase; dead list gains both ids; the
    bump counters move; bytes change only inside the two fresh
    ranges). Order-independent in the interleaving of the atom's
    internal writes — exactly why the interface is pointwise. -/
theorem MemInv.scratch2_pointwise {msOld msNew : MemState}
    (hinv : MemInv msOld)
    {nidA nidB aA aB : Int} {szA szB : Nat}
    {alA alB : Allocation}
    (hszA1 : 1 ≤ szA)
    (hrangeA : aA + szA ≤ (msOld.lastAddress : Int))
    (hrangeB : aB + szB ≤ aA)
    (hnidA : nidA = (msOld.nextAllocId : Int))
    (hnidB : nidB = (msOld.nextAllocId : Int) + 1)
    (halloc : msNew.allocations
      = (((msOld.allocations.insert nidA alA).insert nidB alB).erase
          nidB).erase nidA)
    (hdead : msNew.deadAllocations
      = nidA :: nidB :: msOld.deadAllocations)
    (hnext : (msNew.nextAllocId : Int) = (msOld.nextAllocId : Int) + 2)
    (hlast : (msNew.lastAddress : Int) = aB)
    (hbout : ∀ a : Int, ¬(aA ≤ a ∧ a < aA + szA) →
      ¬(aB ≤ a ∧ a < aB + szB) →
      msNew.bytemap.get? a = msOld.bytemap.get? a) :
    MemInv msNew := by
  have hAlt : aA < (msOld.lastAddress : Int) := by omega
  constructor
  · intro aid al hget
    rw [halloc] at hget
    by_cases hA : aid = nidA
    · rw [hA, tm_get?_ii_ee_a] at hget; cases hget
    by_cases hB : aid = nidB
    · rw [hB, tm_get?_ii_ee_b (by omega)] at hget; cases hget
    rw [tm_get?_ii_ee_ne hA hB] at hget
    have h9 := hinv.alloc_lt aid al hget
    rw [hnext]
    omega
  · intro aid hmem
    rw [hdead] at hmem
    rw [halloc]
    rcases List.mem_cons.mp hmem with rfl | hmem'
    · exact tm_get?_ii_ee_a
    rcases List.mem_cons.mp hmem' with rfl | hmem''
    · exact tm_get?_ii_ee_b (by omega)
    have hlt := hinv.dead_lt aid hmem''
    rw [tm_get?_ii_ee_ne (by omega) (by omega)]
    exact hinv.dead_not_alloc aid hmem''
  · intro aid hmem
    rw [hdead] at hmem
    rw [hnext]
    rcases List.mem_cons.mp hmem with rfl | hmem'
    · omega
    rcases List.mem_cons.mp hmem' with rfl | hmem''
    · omega
    have := hinv.dead_lt aid hmem''
    omega
  · intro a b hget
    -- re-type the field's `≤` off the Address abbrev (the MemInv
    -- note's omega-foreign-atom trap; explicit-instance `show`)
    show @LE.le Int Int.instLEInt msNew.lastAddress a
    rw [show ((msNew.lastAddress : Int)) = aB from hlast]
    by_cases hA : aA ≤ a ∧ a < aA + szA
    · omega
    by_cases hB : aB ≤ a ∧ a < aB + szB
    · omega
    rw [hbout a hA hB] at hget
    have h2 : @LE.le Int Int.instLEInt msOld.lastAddress a :=
      hinv.bytes_above a b hget
    omega

/-- SEQUENTIAL RANGE OVERWRITES (arc-18 R2, the write1 walk rule's
    physical shape): a loop's driver atom re-writes the SAME byte
    range once per iteration — the final bytemap is a `writeList`
    ladder at one address. The C3b scratch2 design note prescribed
    POINTWISE vocabulary for n-fold ladders; `writeSeq` is that
    ladder reified, with the ghost/invariant moves by fold. -/
def writeSeq (t : Std.TreeMap Int AbsByte) (a : Int) :
    List (List AbsByte) → Std.TreeMap Int AbsByte
  | [] => t
  | w :: ws => writeSeq (writeList t a w) a ws

/-- STORE-SEQUENCE preservation: `MemInv.store` folded over a write
    ladder (each layer lands on the previous layer's — initially the
    hypothesis's — mapped range). -/
theorem MemInv.writeSeq_pres {ms : MemState} (h : MemInv ms)
    {a : Int} {old : List AbsByte}
    (hold : ∀ i : Nat, (hi : i < old.length) →
      ms.bytemap.get? (a + (i : Int)) = some old[i])
    (ws : List (List AbsByte))
    (hlens : ∀ w ∈ ws, w.length = old.length) :
    MemInv { ms with bytemap := writeSeq ms.bytemap a ws } := by
  induction ws generalizing ms old with
  | nil => exact h
  | cons w ws ih =>
    have hlw : w.length = old.length := hlens w (List.mem_cons_self ..)
    have h1 : MemInv (CerbMem.writeBytesTo
        { ms with funptrmap := ms.funptrmap } a w) :=
      h.store hlw hold
    rw [writeBytesTo_eq] at h1
    have hold' : ∀ i : Nat, (hi : i < w.length) →
        (writeList ms.bytemap a w).get? (a + (i : Int)) = some w[i] := by
      intro i hi
      rw [writeList_get?_in _ _ _ _ (by omega) (by omega)]
      have hidx : ((a + (i : Int)) - a).toNat = i := by omega
      rw [hidx, List.getElem?_eq_getElem hi]
    have := ih (ms := { ms with bytemap := writeList ms.bytemap a w })
      (old := w) h1 hold'
      (fun w' hw' => (hlens w' (List.mem_cons_of_mem _ hw')).trans
        hlw.symm)
    exact this

end Cerb
end RelSem
