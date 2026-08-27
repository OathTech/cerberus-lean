/-
  RelSem.Kit.Mem — arc-9 S2 (2026-08-20): L1 kit, the memory-op block
  layer at MemState level (design docs/2026-08-20_arc9-s1-design.md
  §1.2 Kit/Mem; gap G4; brick-B1/B3 shapes).

  Generalized from the T1/T3/T4 fixture lemmas (allocErr_eq /
  storeErr_eq / loadX_eq / createS / storeU / loadV classes): each
  block is COMPUTED-RHS with the brick-B3 named-hypothesis convention
  — every `h*` is a small closed fact the fixture discharges by
  `rfl`/`decide` (or, over recursive iteration families, by the
  fixture's induction lemmas). The success paths only (the slate's
  value routes); the UB paths stay per-fixture (T2 pattern).

  Import discipline (design §6): no Iris, no fixtures.

  House rules: no sorry, no axioms declared here. Pins in Kit/Audit.
-/

import RelSem.Machine
import RelSem.Cerberus
import RelSem.LawRegistry

set_option autoImplicit false

namespace RelSem.Kit

open RelSem

/-- ALLOCATE (create), fresh-object success path: the address is
    computed from the pre-state (hypothesis-pinned so fixtures
    discharge the arithmetic by `decide`); the post-state appends the
    allocation and writes `sz` uninitialized bytes. -/
@[  step_law (kind := memBlock) (side := ground)
  (frontier := "mem/alloc")
  (trace := "{law := mem_alloc_block, joint := mem/alloc, hyps := [hsz : ground, haddr : ground, hnz : ground]}")
  (lineage := "computed-RHS memory-op block (brick-B3 named-hypothesis shape): allocate, success path")]
theorem mem_alloc_block {tid : Nat} {pref : prefix0} {pv : CerbMem.Provenance}
    {alignN : Int} {ty : ctype} {mem : CerbMem.MemState}
    {addrOpt : Option Int} {sz : Nat} {a : Int}
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (mem.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false) :
    app (CerbMem.allocateObject tid pref (.IV pv alignN) ty addrOpt none) mem
      = (NDactive (.PV (.Prov_some mem.nextAllocId) (.PVconcrete none a)),
         CerbMem.writeBytesTo
           { mem with
             nextAllocId := mem.nextAllocId + 1,
             lastAddress := a,
             allocations := mem.allocations.insert mem.nextAllocId
               { base := a, size := sz, ty := some ty, prefix_ := pref } }
           a (List.replicate sz
               { prov := .Prov_none, copyOffset := none, value := none })) := by
  -- arc-9 S4 rebase note (2026-08-21): arc-10 finding-11 gave
  -- allocateObject a real readonly status (impl_mem.ml:1304-1333
  -- mirror). At this block's `initOpt = none` it reduces to
  -- `.IsWritable` = the structure default, so the STATED post-state is
  -- unchanged — the proof just reduces the new call.
  simp only [CerbMem.allocateObject, app, hsz, haddr, hnz,
    CerbMem.readonlyStatusForAlloc_none,
    Bool.false_eq_true, if_false, reduceIte]

/-- STORE, success path (positive/negative alike — the polarity lives
    at the driver layer): non-union concrete pointer, writable
    allocation, compatible value; the post-state is the byte write
    with the funptrmap threaded (integers: unchanged). -/
@[  step_law (kind := memBlock) (side := ground)
  (frontier := "mem/store")
  (trace := "{law := mem_store_block, joint := mem/store, hyps := [hcompat : ground, hget : ground, hbounds : ground, hro : ground, hatomic : ground, hbytes : ground]}")
  (lineage := "computed-RHS memory-op block: store as a folded byte write (writeBytesTo spelling preserved)")]
theorem mem_store_block {loc : CerbLocation.Loc} {ty : ctype}
    {allocId : Int} {addr : Int} {alloc : CerbMem.Allocation}
    {mem : CerbMem.MemState} {mv : CerbMem.MemValue}
    {fpm : CerbMem.Funptrmap} {bytes : List CerbMem.AbsByte}
    (hcompat : CerbMem.ctypeMemCompatible ty (CerbMem.typeofMval mv) = true)
    (hget : mem.allocations.get? allocId = some alloc)
    (hbounds : CerbMem.isInBounds alloc addr (CerbMem.sizeofCtype ty) = true)
    (hro : alloc.isReadonly = .IsWritable)
    (hatomic : CerbMem.isAtomicMemberAccess alloc ty addr = false)
    (hbytes : CerbMem.memValueToBytes mem.funptrmap mv = (fpm, bytes)) :
    app (CerbMem.storeM loc ty false
          (.PV (.Prov_some allocId) (.PVconcrete none addr)) mv) mem
      = (NDactive (.FP .W addr (CerbMem.sizeofCtype ty)),
         CerbMem.writeBytesTo { mem with funptrmap := fpm } addr bytes) := by
  simp only [CerbMem.storeM, app, hcompat, hget, hbounds, hro, hatomic,
    hbytes, Bool.not_true, Bool.false_eq_true, if_false, if_true,
    reduceIte, Bool.not_false]

/-- The readonly kind a locking store selects from the allocation's
    prefix (CerbMem.storeM's local `selectRoKind`, top-level —
    mirrors impl_mem.ml:1704-1710 select_ro_kind). -/
def selectRoKindK : prefix0 → readonly_kind
  | PrefTemporaryLifetime _ _ => .ReadonlyTemporaryLifetime
  | PrefStringLiteral _ _ => .ReadonlyStringLiteral
  | _ => .ReadonlyConstQualified

/-- STORE_LOCK, success path (arc-18 C4: the block-scope CONST-array
    initialization store — the harness template's choice/expected
    arrays; first demanded by the divmod drive walk, fires for every
    const-array fixture): as `mem_store_block` with `isLocking =
    true`, so the post-state additionally marks the target allocation
    read-only (kind from the allocation's own prefix —
    impl_mem.ml:1776-1787). -/
@[  step_law (kind := memBlock) (side := ground)
  (frontier := "mem/store_lock")
  (trace := "{law := mem_store_lock_block, joint := mem/store_lock, hyps := [hcompat : ground, hget : ground, hbounds : ground, hro : ground, hatomic : ground, hbytes : ground]}")
  (lineage := "computed-RHS memory-op block: locking store as the plain store's byte write + the allocation readonly flip (const-qualified init)")]
theorem mem_store_lock_block {loc : CerbLocation.Loc} {ty : ctype}
    {allocId : Int} {addr : Int} {alloc : CerbMem.Allocation}
    {mem : CerbMem.MemState} {mv : CerbMem.MemValue}
    {fpm : CerbMem.Funptrmap} {bytes : List CerbMem.AbsByte}
    (hcompat : CerbMem.ctypeMemCompatible ty (CerbMem.typeofMval mv) = true)
    (hget : mem.allocations.get? allocId = some alloc)
    (hbounds : CerbMem.isInBounds alloc addr (CerbMem.sizeofCtype ty) = true)
    (hro : alloc.isReadonly = .IsWritable)
    (hatomic : CerbMem.isAtomicMemberAccess alloc ty addr = false)
    (hbytes : CerbMem.memValueToBytes mem.funptrmap mv = (fpm, bytes))
    -- the readonly flip's ANCHOR-CANONICAL spelling: the store body's
    -- whole-map `.map` equals a single `insert` of the flipped record
    -- (ground states discharge by kernel rfl — an autoParam so the
    -- engine's six-slot mem-block splice serves both store laws; the
    -- insert spelling is what keeps the anchored allocations ladder
    -- read-over-update-navigable instead of accreting `.map` layers,
    -- the measured round-75 whnf cliff)
    (hallocs : mem.allocations.map (fun id a =>
        if id == allocId then
          { a with isReadonly :=
              CerbMem.ReadonlyStatus.IsReadOnly (selectRoKindK alloc.prefix_) }
        else a)
      = mem.allocations.insert allocId
          { alloc with isReadonly :=
              CerbMem.ReadonlyStatus.IsReadOnly (selectRoKindK alloc.prefix_) }
      := by first | exact rfl | decide) :
    app (CerbMem.storeM loc ty true
          (.PV (.Prov_some allocId) (.PVconcrete none addr)) mv) mem
      = (NDactive (.FP .W addr (CerbMem.sizeofCtype ty)),
         { CerbMem.writeBytesTo { mem with funptrmap := fpm } addr bytes with
           allocations := mem.allocations.insert allocId
             { alloc with isReadonly := CerbMem.ReadonlyStatus.IsReadOnly (selectRoKindK alloc.prefix_) } }) := by
  have base : app (CerbMem.storeM loc ty true
        (.PV (.Prov_some allocId) (.PVconcrete none addr)) mv) mem
      = (NDactive (.FP .W addr (CerbMem.sizeofCtype ty)),
         { CerbMem.writeBytesTo { mem with funptrmap := fpm } addr bytes with
           allocations := mem.allocations.map (fun id a =>
             if id == allocId then
               { a with isReadonly := CerbMem.ReadonlyStatus.IsReadOnly (selectRoKindK alloc.prefix_) }
             else a) }) := by
    simp only [CerbMem.storeM, app, hcompat, hget, hbounds, hro, hatomic,
      hbytes, Bool.not_true, Bool.false_eq_true, if_false, if_true,
      reduceIte, Bool.not_false]
    rfl
  rw [base, hallocs]

/-- Is a ctype the `_Bool` type (the load trap-representation
    discriminator)? -/
def isBoolTy : ctype → Bool
  | Ctype _ (Basic (Integer Bool0)) => true
  | _ => false

/-- LOAD, success path: non-Bool type (no trap-representation branch),
    live allocation, in bounds; state unchanged.

    `(fact := hget 3)` — the arc-11 S1 batch-4 context-query EXEMPLAR
    (design §12.3, SOFT mode): the `hget` allocation-lookup premise is
    keyed on the allocations MAP (argument 3 of `Std.TreeMap.get?`);
    a context hypothesis about the same map commits first (the
    Islaris `findM(a)` move — the fact then DETERMINES allocId/alloc),
    and the normal mechanical lanes run unchanged on a miss
    (behavior-compatible: every existing walk discharges hget as
    before). -/
@[  step_law (kind := memBlock) (side := ground)
  (frontier := "mem/load")
  (trace := "{law := mem_load_block, joint := mem/load, hyps := [hdead : ground, hget : ground, hbounds : ground, hatomic : ground, hbytes : ground, hrecon : ground, hnotbool : ground]}")
  (lineage := "computed-RHS memory-op block: load, success path, state unchanged")]
theorem mem_load_block {loc : CerbLocation.Loc} {ty : ctype}
    {allocId : Int} {addr : Int} {um : Option identifier}
    {alloc : CerbMem.Allocation} {mem : CerbMem.MemState}
    {bytes : List CerbMem.AbsByte} {mv : CerbMem.MemValue}
    (hdead : mem.deadAllocations.contains allocId = false)
    (hget : mem.allocations.get? allocId = some alloc)
    (hbounds : CerbMem.isInBounds alloc addr (CerbMem.sizeofCtype ty) = true)
    (hatomic : CerbMem.isAtomicMemberAccess alloc ty addr = false)
    (hbytes : CerbMem.readBytesFrom mem addr (CerbMem.sizeofCtype ty) = bytes)
    (hrecon : CerbMem.reconstructValue mem.lastUsedUnionMembers
        mem.funptrmap addr ty bytes = mv)
    (hnotbool : isBoolTy ty = false) :
    app (CerbMem.loadM loc ty
          (.PV (.Prov_some allocId) (.PVconcrete um addr))) mem
      = (NDactive (.FP .R addr (CerbMem.sizeofCtype ty), mv), mem) := by
  simp only [CerbMem.loadM, app, hdead, hget, hbounds, hatomic, hbytes,
    hrecon, Bool.not_true, Bool.false_eq_true, if_false,
    if_true, reduceIte, Bool.not_false, Bool.false_and]
  exact if_neg (fun hx => Bool.noConfusion
    (hnotbool.symm.trans ((Bool.and_eq_true _ _).mp hx).1))

/-- PtrValidForDeref (the pointer-validity read), Prov_some concrete
    path: STATE-PRESERVING — liveness by a component fact, alignment
    by ground arithmetic (arc-18 R6 batch 3: the array lane's memop
    at OPEN memory; the divmod-era whole-state kernel-rfl route stays
    first in the feeder and still fires at ground memory). -/
@[  step_law (kind := memBlock) (side := ground)
  (frontier := "mem/pvfd")
  (trace := "{law := mem_pvfd_block, joint := mem/pvfd, hyps := [hdead : ground, hwa : ground]}")
  (lineage := "computed-RHS memory-op block: validity read, state-preserving")]
theorem mem_pvfd_block {ty : ctype} {allocId : Int} {addr : Int}
    {um : Option identifier} {mem : CerbMem.MemState} {b : Bool}
    (hdead : mem.deadAllocations.contains allocId = false)
    (hwa : CerbMem.isWellAlignedPtrval ty
        (.PV (.Prov_some allocId) (.PVconcrete um addr))
      = CerbMem.memReturn b) :
    app (CerbMem.validForDerefPtrval ty
          (.PV (.Prov_some allocId) (.PVconcrete um addr))) mem
      = (NDactive b, mem) := by
  simp only [CerbMem.validForDerefPtrval, app, hdead,
    Bool.false_eq_true, if_false, reduceIte, hwa, CerbMem.memReturn,
    nd_return]

/-- Pointer prefix (a placeholder in the concrete model: always
    `none`; the trace events' pref field). -/
@[  step_law (kind := memBlock) (side := rfl)
  (frontier := "mem/prefix")
  (trace := "{law := mem_prefix_block, joint := mem/prefix, hyps := []}")
  (lineage := "concrete-model pointer prefix: always none, rfl")]
theorem mem_prefix_block {ptr : CerbMem.PointerValue}
    {mem : CerbMem.MemState} :
    app (CerbMem.prefixOfPointer ptr) mem = (NDactive none, mem) := rfl

/-- KILL (object deallocation), success path: live allocation, at the
    base address, non-dynamic. -/
@[  step_law (kind := memBlock) (side := ground)
  (frontier := "mem/kill")
  (trace := "{law := mem_kill_block, joint := mem/kill, hyps := [hdead : ground, hget : ground, hbase : ground]}")
  (lineage := "computed-RHS memory-op block: kill, success path")]
theorem mem_kill_block {loc : CerbLocation.Loc}
    {allocId : Int} {addr : Int} {um : Option identifier}
    {alloc : CerbMem.Allocation} {mem : CerbMem.MemState}
    (hdead : mem.deadAllocations.contains allocId = false)
    (hget : mem.allocations.get? allocId = some alloc)
    (hbase : (addr != alloc.base) = false) :
    app (CerbMem.killM loc false
          (.PV (.Prov_some allocId) (.PVconcrete um addr))) mem
      = (NDactive (),
         { mem with
           deadAllocations := allocId :: mem.deadAllocations,
           allocations := mem.allocations.erase allocId }) := by
  simp only [CerbMem.killM, app, hdead, hget, hbase, Bool.not_true,
    Bool.false_eq_true, if_false, if_true, reduceIte, Bool.not_false,
    Bool.false_and, Bool.and_false]

/-! ### Read-over-write (arc-17 S3): the separation-logic footprint
    primitives at bytemap level — `writeBytesTo` touches ONLY the
    bytemap (projection laws), a disjoint read passes through
    (frame), the exact-footprint read reads back the written bytes.
    These are the laws the builder walk's fenced-store discipline
    consumes (store rounds keep `writeBytesTo` folded; later loads
    mint through these instead of materializing the byte tree). -/

@[step_law (kind := memRW) (variant := projAllocations) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_allocations, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_allocations {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).allocations = m.allocations := rfl

@[step_law (kind := memRW) (variant := projDeadAllocations) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_deadAllocations, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_deadAllocations {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).deadAllocations
      = m.deadAllocations := rfl

@[step_law (kind := memRW) (variant := projFunptrmap) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_funptrmap, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_funptrmap {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).funptrmap = m.funptrmap := rfl

@[step_law (kind := memRW) (variant := projLastUsedUnionMembers) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_lastUsedUnionMembers, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_lastUsedUnionMembers {m : CerbMem.MemState}
    {a : Int} {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).lastUsedUnionMembers
      = m.lastUsedUnionMembers := rfl

/-- The byte-write fold's pointwise character: key `k` reads the
    written byte when `a ≤ k < a + bs.length`, the base map
    otherwise. -/
private theorem writeFold_get? (bs : List CerbMem.AbsByte)
    (bm : Std.TreeMap Int CerbMem.AbsByte) (a k : Int) :
    ((bs.foldl (fun (acc : Std.TreeMap Int CerbMem.AbsByte × Int) b =>
        (acc.1.insert acc.2 b, acc.2 + 1)) (bm, a)).1.get? k
      = if h : a ≤ k ∧ k < a + bs.length
        then some (bs[(k - a).toNat]'(by omega))
        else bm.get? k) := by
  induction bs generalizing bm a with
  | nil =>
    have h : ¬ (a ≤ k ∧ k < a + ([] : List CerbMem.AbsByte).length) := by
      simp
    simp only [List.foldl_nil, dif_neg h]
  | cons b bs ih =>
    show ((bs.foldl _ (bm.insert a b, a + 1)).1.get? k = _)
    rw [ih]
    rcases Decidable.em (a = k) with heq | hne
    · subst heq
      have h1 : ¬ (a + 1 ≤ a ∧ a < a + 1 + bs.length) := by omega
      have h2 : a ≤ a ∧ a < a + (b :: bs).length := by
        simp; omega
      simp only [dif_neg h1, dif_pos h2,
        Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert]
      have : compare a a = Ordering.eq := by
        simp [Int.compare_eq_eq]
      simp [this]
    · rcases Decidable.em (a + 1 ≤ k ∧ k < a + 1 + bs.length)
        with hin | hout
      · have h2 : a ≤ k ∧ k < a + (b :: bs).length := by
          simp; omega
        rw [dif_pos hin, dif_pos h2]
        congr 1
        have hk : (k - (a + 1)).toNat + 1 = (k - a).toNat := by omega
        rw [List.getElem_cons]
        split
        · omega
        · congr 1; omega
      · have h2 : ¬ (a ≤ k ∧ k < a + (b :: bs).length) := by
          simp; simp at hout; omega
        rw [dif_neg hout, dif_neg h2,
          Std.TreeMap.get?_eq_getElem?, Std.TreeMap.get?_eq_getElem?,
          Std.TreeMap.getElem?_insert]
        have : compare a k ≠ Ordering.eq := by
          simp [Int.compare_eq_eq]; omega
        simp [this]

/-- `writeBytesTo`'s bytemap, pointwise. -/
private theorem writeBytesTo_bytemap_get? {m : CerbMem.MemState}
    {a k : Int} {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).bytemap.get? k
      = if h : a ≤ k ∧ k < a + bs.length
        then some (bs[(k - a).toNat]'(by omega))
        else m.bytemap.get? k :=
  writeFold_get? bs m.bytemap a k

/-- A byte read depends only on the bytemap (the record-respelling
    bridge: an anchored `MemState.mk` record whose bytemap field is a
    projection of the base state reads identically to the base). -/
@[step_law (kind := memRW) (variant := congr) (side := rfl)
  (frontier := "mem/rw-congr")
  (trace := "{law := readBytesFrom_congr_bytemap, joint := mem/rw, hyps := [h : rfl]}")
  (lineage := "reads depend only on the bytemap (the record-respelling bridge)")]
theorem readBytesFrom_congr_bytemap {m1 m2 : CerbMem.MemState}
    {a : Int} {n : Nat} (h : m1.bytemap = m2.bytemap) :
    CerbMem.readBytesFrom m1 a n = CerbMem.readBytesFrom m2 a n := by
  unfold CerbMem.readBytesFrom
  rw [h]

@[step_law (kind := memRW) (variant := projLastAddress) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_lastAddress, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_lastAddress {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).lastAddress = m.lastAddress := rfl

@[step_law (kind := memRW) (variant := projNextAllocId) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_nextAllocId, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_nextAllocId {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).nextAllocId = m.nextAllocId := rfl

/-! The remaining pass-through projections (arc-18 R1, the
    open-memory minting mode): the T6 open drive's Erun round rebuilds
    the memory record FIELD-BY-FIELD from the folded write ladder, so
    EVERY non-bytemap field needs its registered pass-through law
    (measured: round 50 fixpointed un-normalized on exactly the seven
    missing fields). Same law shape as the four above — the byte
    write touches only the bytemap. -/

@[step_law (kind := memRW) (variant := projNextIota) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_nextIota, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_nextIota {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).nextIota = m.nextIota := rfl

@[step_law (kind := memRW) (variant := projIotaMap) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_iotaMap, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_iotaMap {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).iotaMap = m.iotaMap := rfl

@[step_law (kind := memRW) (variant := projVarargs) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_varargs, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_varargs {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).varargs = m.varargs := rfl

@[step_law (kind := memRW) (variant := projNextVarargsId) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_nextVarargsId, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_nextVarargsId {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).nextVarargsId = m.nextVarargsId := rfl

@[step_law (kind := memRW) (variant := projDynamicAddrs) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_dynamicAddrs, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_dynamicAddrs {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).dynamicAddrs = m.dynamicAddrs := rfl

@[step_law (kind := memRW) (variant := projLastUsed) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_lastUsed, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_lastUsed {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).lastUsed = m.lastUsed := rfl

@[step_law (kind := memRW) (variant := projRequested) (side := rfl)
  (frontier := "mem/rw-proj")
  (trace := "{law := writeBytesTo_requested, joint := mem/rw-proj, hyps := []}")
  (lineage := "SL footprint projection law: the byte write touches only the bytemap")]
theorem writeBytesTo_requested {m : CerbMem.MemState} {a : Int}
    {bs : List CerbMem.AbsByte} :
    (CerbMem.writeBytesTo m a bs).requested = m.requested := rfl

/-- `get?` through an `insert` at the SAME key (arc-18 C3b: the
    entry walk's post-create allocation-table reads at open maps —
    the store's `hget` reads back the just-inserted record). -/
@[step_law (kind := memRW) (variant := insertEq) (side := ground)
  (frontier := "mem/rw-insert")
  (trace := "{law := tm_get?_insert_eq, joint := mem/rw, hyps := []}")
  (lineage := "read-over-update readback at the allocation table (Burstall/Bornat independent cells, insert-hit face)")]
theorem tm_get?_insert_eq {V : Type} (t : Std.TreeMap Int V)
    (k : Int) (v : V) :
    (t.insert k v).get? k = some v := by
  simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert]
  have : compare k k = Ordering.eq := by
    simp [Int.compare_eq_eq]
  simp [this]

/-- `get?` through an `insert` at a DIFFERENT key (the skip face; the
    registered twin of CerbHeapWalk's fixture-facing
    `tm_get?_insert_ne`). -/
@[step_law (kind := memRW) (variant := insertNe) (side := ground)
  (frontier := "mem/rw-insert")
  (trace := "{law := tm_get?_insert_skip, joint := mem/rw, hyps := [h : ground]}")
  (lineage := "read-over-update pass-through at the allocation table (insert-skip face)")]
theorem tm_get?_insert_skip {V : Type} (t : Std.TreeMap Int V)
    {k k' : Int} (h : k ≠ k') (v : V) :
    (t.insert k v).get? k' = t.get? k' := by
  simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert]
  rw [if_neg]
  intro hc
  exact h (Std.LawfulEqCmp.eq_of_compare hc)

/-- `get?` through an `erase` at a DIFFERENT key (arc-18 C3b: the
    kill rounds' allocation-table reads — a later load's `hget` must
    cross the kill's `allocations.erase`). -/
@[step_law (kind := memRW) (variant := eraseNe) (side := ground)
  (frontier := "mem/rw-erase")
  (trace := "{law := tm_get?_erase_ne, joint := mem/rw, hyps := [h : ground]}")
  (lineage := "read-over-update pass-through at the allocation table (Burstall/Bornat independent cells, delete face)")]
theorem tm_get?_erase_ne {V : Type} (t : Std.TreeMap Int V)
    {k k' : Int} (h : k ≠ k') :
    (t.erase k).get? k' = t.get? k' := by
  simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_erase]
  rw [if_neg]
  intro hc
  exact h (Std.LawfulEqCmp.eq_of_compare hc)

/-- `contains` through a cons at a DIFFERENT element (arc-18 C3b: the
    kill rounds' dead-list reads — a later load's `hdead` must cross
    the kill's `deadAllocations` cons). -/
@[step_law (kind := memRW) (variant := containsConsNe) (side := ground)
  (frontier := "mem/rw-dead")
  (trace := "{law := list_contains_cons_ne, joint := mem/rw, hyps := [h : ground]}")
  (lineage := "read-over-update pass-through at the dead list (cons skip at a decided-apart head)")]
theorem list_contains_cons_ne {a x : Int} (l : List Int)
    (h : (x == a) = false) :
    (a :: l).contains x = l.contains x := by
  simp only [List.contains_cons, h, Bool.false_or]

/-- Disjoint read passes through the write (the FRAME law). -/
@[step_law (kind := memRW) (variant := frame) (side := ground)
  (frontier := "mem/rw-frame")
  (trace := "{law := readBytesFrom_writeBytesTo_disjoint, joint := mem/rw, hyps := [hdisj : ground]}")
  (lineage := "the SL FRAME law at bytemap level: a disjoint read passes through the write (Burstall/Bornat independent cells)")]
theorem readBytesFrom_writeBytesTo_disjoint {m : CerbMem.MemState}
    {a a' : Int} {bs : List CerbMem.AbsByte} {n : Nat}
    (hdisj : a + bs.length ≤ a' ∨ a' + n ≤ a) :
    CerbMem.readBytesFrom (CerbMem.writeBytesTo m a bs) a' n
      = CerbMem.readBytesFrom m a' n := by
  unfold CerbMem.readBytesFrom
  apply List.map_congr_left
  intro i hi
  have hi' : i < n := List.mem_range.mp hi
  rw [writeBytesTo_bytemap_get?]
  have : ¬ (a ≤ a' + (i : Int) ∧ a' + (i : Int) < a + bs.length) := by
    omega
  rw [dif_neg this]

/-- Exact-footprint readback: reading `bs.length` bytes at the write
    address returns the written bytes. -/
@[step_law (kind := memRW) (variant := hit) (side := ground)
  (frontier := "mem/rw-hit")
  (trace := "{law := readBytesFrom_writeBytesTo_hit, joint := mem/rw, hyps := [hn : ground]}")
  (lineage := "exact-footprint readback: load-over-store at the written cells (Burstall/Bornat)")]
theorem readBytesFrom_writeBytesTo_hit {m : CerbMem.MemState}
    {a : Int} {bs : List CerbMem.AbsByte} {n : Nat}
    (hn : n = bs.length) :
    CerbMem.readBytesFrom (CerbMem.writeBytesTo m a bs) a n = bs := by
  subst hn
  unfold CerbMem.readBytesFrom
  apply List.ext_getElem
  · simp
  · intro i h1 h2
    simp only [List.getElem_map, List.getElem_range]
    rw [writeBytesTo_bytemap_get?]
    have hin : a ≤ a + (i : Int) ∧ a + (i : Int) < a + bs.length := by
      simp at h1; omega
    rw [dif_pos hin]
    simp only [show a + (i : Int) - a = (i : Int) from by omega,
      Int.toNat_natCast]

/-- THE ARRAY CARVE-OUT (arc-18 R6b, the array-vocabulary slice):
    a SUB-RANGE read of a written block returns the block's slice —
    the element-points-to face of the iterated-points-to array view.
    An element load over a whole-array store (an initializer image,
    an unspecified fill) is this law at the element's offset; `hit`
    is the degenerate whole-range case.

    *Lineage (canon-first, mirror-donor)*: RefinedC's array type
    OWNS its cells as iterated element points-to
    (`array ly tys` ty_own `= [∗ list] i ↦ ty ∈ tys,
    (l offset{ly}ₗ i) ◁ₗ ty` — deps/refinedc/theories/typing/
    array.v:9-16), and its deref/ref obligations split the byte
    block with take/drop through `heap_mapsto_app`
    (`l ↦ (v1 ++ v2) ⊣⊢ l ↦ v1 ∗ (l +ₗ length v1) ↦ v2` —
    deps/refinedc/theories/caesium/ghost_state.v:506). This law is
    that split's equation-calculus face at our bytemap: the slice
    IS the carved element's points-to image. -/
@[step_law (kind := memRW) (variant := within) (side := ground)
  (frontier := "mem/rw-within")
  (trace := "{law := readBytesFrom_writeBytesTo_within, joint := mem/rw, hyps := [hlo : ground, hhi : ground]}")
  (lineage := "the array CARVE-OUT at bytemap level: sub-range read of a written block = the block's slice (RefinedC array.v big_sepL element points-to + caesium heap_mapsto_app; Burstall/Bornat cells)")]
theorem readBytesFrom_writeBytesTo_within {m : CerbMem.MemState}
    {a a' : Int} {bs : List CerbMem.AbsByte} {n : Nat}
    (hlo : a ≤ a') (hhi : a' + n ≤ a + bs.length) :
    CerbMem.readBytesFrom (CerbMem.writeBytesTo m a bs) a' n
      = (bs.drop (a' - a).toNat).take n := by
  unfold CerbMem.readBytesFrom
  apply List.ext_getElem
  · simp; omega
  · intro i h1 h2
    simp only [List.getElem_map, List.getElem_range]
    rw [writeBytesTo_bytemap_get?]
    have hn1 : i < n := by
      simpa using h1
    have hin : a ≤ a' + (i : Int) ∧ a' + (i : Int) < a + bs.length := by
      omega
    rw [dif_pos hin]
    -- the match-on-`some` scrutinee iota-reduces; restate at the
    -- bare getElem so congr exposes the index arithmetic
    show bs[(a' + (i : Int) - a).toNat]'(by omega)
      = ((bs.drop (a' - a).toNat).take n)[i]'(by
          simp only [List.length_take, List.length_drop]; omega)
    rw [List.getElem_take, List.getElem_drop]
    congr 1
    omega

end RelSem.Kit
